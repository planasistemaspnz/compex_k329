package com.gondolaprinter.gondola_label_printer

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.lang.reflect.Method
import java.util.UUID
import java.util.concurrent.Executors

class GondolaLabelPrinterPlugin : FlutterPlugin, MethodCallHandler {
    private val CHANNEL = "com.gondolaprinter.channel/printer"
    private val SPP_UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    private val TAG = "K329PrinterNative"

    private var channel: MethodChannel? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private val bluetoothAdapter: BluetoothAdapter? by lazy { BluetoothAdapter.getDefaultAdapter() }
    private var currentSocket: BluetoothSocket? = null
    private var outputStream: OutputStream? = null
    private var inputStream: InputStream? = null
    private var connectedDevice: BluetoothDevice? = null
    private val executor = Executors.newSingleThreadExecutor()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel?.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        disconnectInternal()
        executor.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPairedDevices" -> {
                try {
                    result.success(getPairedDevicesList())
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }
            "connect" -> {
                val address = call.argument<String>("address")
                if (address.isNullOrEmpty()) {
                    result.error("INVALID_ARG", "Endereço MAC vazio", null)
                    return
                }
                connectToDevice(address, result)
            }
            "disconnect" -> disconnect(result)
            "isConnected" -> result.success(isConnected())
            "isBluetoothEnabled" -> result.success(bluetoothAdapter?.isEnabled == true)
            "sendBytes" -> {
                val bytes = call.argument<ByteArray>("bytes")
                if (bytes == null || bytes.isEmpty()) {
                    result.error("INVALID_ARG", "Array de bytes vazio", null)
                    return
                }
                sendBytesDirect(bytes, result)
            }
            else -> result.notImplemented()
        }
    }

    @SuppressLint("MissingPermission")
    private fun getPairedDevicesList(): List<Map<String, String>> {
        val list = mutableListOf<Map<String, String>>()
        val adapter = bluetoothAdapter ?: return list
        if (!adapter.isEnabled) return list
        val bonded = adapter.bondedDevices ?: return list
        for (dev in bonded) {
            list.add(mapOf("name" to (dev.name ?: "Desconhecido"), "address" to (dev.address ?: "")))
        }
        return list
    }

    private fun isConnected(): Boolean =
        currentSocket != null && currentSocket!!.isConnected && outputStream != null

    private fun disconnectInternal() {
        try { outputStream?.flush() } catch (_: Exception) {}
        try { outputStream?.close() } catch (_: Exception) {}
        try { inputStream?.close() } catch (_: Exception) {}
        try { currentSocket?.close() } catch (_: Exception) {}
        outputStream = null
        inputStream = null
        currentSocket = null
        connectedDevice = null
    }

    private fun disconnect(result: Result? = null) {
        executor.execute {
            disconnectInternal()
            Log.d(TAG, "Socket desconectado e recursos liberados.")
            if (result != null) mainHandler.post { result.success(true) }
        }
    }

    @SuppressLint("MissingPermission")
    private fun connectToDevice(address: String, result: Result) {
        val adapter = bluetoothAdapter
        if (adapter == null || !adapter.isEnabled) {
            result.error("BT_DISABLED", "Bluetooth desativado", null)
            return
        }
        executor.execute {
            disconnectInternal()
            try {
                if (adapter.isDiscovering) adapter.cancelDiscovery()
                val device = adapter.getRemoteDevice(address)
                var socket: BluetoothSocket? = null

                // Tentativa 1: Socket Inseguro RFCOMM (Obrigatório para K329/POS)
                try {
                    Log.d(TAG, "Tentando conexão RFCOMM Insegura na K329...")
                    socket = device.createInsecureRfcommSocketToServiceRecord(SPP_UUID)
                    socket.connect()
                } catch (e1: IOException) {
                    Log.w(TAG, "Tentativa insegura falhou, tentando canal seguro padrão...", e1)
                    try {
                        socket = device.createRfcommSocketToServiceRecord(SPP_UUID)
                        socket.connect()
                    } catch (e2: IOException) {
                        Log.w(TAG, "Tentativa segura falhou, tentando reflexão porta 1...", e2)
                        try {
                            val m: Method = device.javaClass.getMethod("createRfcommSocket", Int::class.javaPrimitiveType)
                            socket = m.invoke(device, 1) as BluetoothSocket
                            socket.connect()
                        } catch (e3: Exception) {
                            Log.e(TAG, "Todas as tentativas de conexão falharam", e3)
                            throw IOException("Falha de conexão com a impressora: ${e3.message}")
                        }
                    }
                }

                if (socket != null && socket.isConnected) {
                    currentSocket = socket
                    outputStream = socket.outputStream
                    inputStream = socket.inputStream
                    connectedDevice = device
                    Log.i(TAG, "Conectado com sucesso a ${device.name} ($address)!")
                    mainHandler.post { result.success(true) }
                } else {
                    mainHandler.post { result.error("CONNECT_FAIL", "Socket não conectado", null) }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Erro fatal ao conectar: ${e.message}", e)
                disconnectInternal()
                mainHandler.post { result.error("CONNECT_ERROR", e.message, null) }
            }
        }
    }

    private fun sendBytesDirect(bytes: ByteArray, result: Result) {
        val stream = outputStream
        val inStream = inputStream
        if (!isConnected() || stream == null) {
            result.error("NOT_CONNECTED", "Impressora não conectada", null)
            return
        }

        executor.execute {
            try {
                Log.i(TAG, "Enviando ${bytes.size} bytes diretos via CPCL...")

                // 1. Limpa bytes residuais do buffer de entrada
                try {
                    while (inStream != null && inStream.available() > 0) {
                        inStream.read()
                    }
                } catch (_: Exception) {}

                // 2. Transmite os bytes da etiqueta CPCL em blocos
                val chunkSize = 1024
                var offset = 0
                while (offset < bytes.size) {
                    val count = Math.min(chunkSize, bytes.size - offset)
                    stream.write(bytes, offset, count)
                    offset += count
                }
                stream.flush()

                // 3. Envia o comando de consulta de status CPCL em tempo real (ESC h -> 0x1B, 0x68)
                // Como o buffer da impressora é FIFO, ela só responde após processar toda a fila anterior
                val queryStatusCmd = byteArrayOf(0x1B.toByte(), 0x68.toByte())
                stream.write(queryStatusCmd)
                stream.flush()
                Log.i(TAG, "Consulta ESC h (0x1B 0x68) enviada. Aguardando confirmação física da K329...")

                // 4. Aguarda a confirmação (ACK) da K329 no inputStream
                var ackReceived = false
                var statusByte = 0
                val deadline = System.currentTimeMillis() + 3500 // até 3.5s de timeout

                while (System.currentTimeMillis() < deadline) {
                    if (inStream != null && inStream.available() > 0) {
                        statusByte = inStream.read()
                        ackReceived = true
                        Log.i(TAG, "Confirmação física recebida da K329! Status byte: 0x%02X".format(statusByte))
                        break
                    }
                    Thread.sleep(50)
                }

                if (!ackReceived) {
                    Log.e(TAG, "Timeout aguardando ACK da K329. Impressora desligada ou fora de alcance.")
                    throw IOException("A impressora não respondeu à confirmação. Verifique se ela está ligada e com papel.")
                }

                // Breve folga de 300ms para permitir o início da tração mecânica do papel
                Thread.sleep(300)

                mainHandler.post { result.success(true) }
            } catch (e: Exception) {
                Log.e(TAG, "Erro ao enviar bytes: ${e.message}", e)
                disconnectInternal()
                mainHandler.post { result.error("SEND_ERROR", e.message, null) }
            }
        }
    }
}
