import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/printer_constants.dart';

class BluetoothPrinterDevice {
  final String name;
  final String address;

  BluetoothPrinterDevice({required this.name, required this.address});
}

/// Gerencia a conexão e transmissão Bluetooth com a impressora K329.
/// Persistência de preferências é responsabilidade de [PrinterPreferencesService].
class BluetoothPrinterService {
  static final BluetoothPrinterService _instance = BluetoothPrinterService._internal();
  factory BluetoothPrinterService() => _instance;
  BluetoothPrinterService._internal();

  static const MethodChannel _channel = MethodChannel(PrinterConstants.methodChannelName);

  bool _isConnected = false;
  String _connectedDeviceName = '';
  String _connectedDeviceMac = '';

  bool get isConnected => _isConnected;
  String get connectedDeviceName => _connectedDeviceName;
  String get connectedDeviceMac => _connectedDeviceMac;

  void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }

  // ===========================================================================
  // Gerenciamento e Ciclo de Vida Bluetooth
  // ===========================================================================

  /// Solicita permissões de Bluetooth para Android 12+ e iOS
  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  /// Obtém a lista de dispositivos pareados
  Future<List<BluetoothPrinterDevice>> getDevices() async {
    await requestPermissions();
    try {
      final List? rawList = await _channel.invokeMethod<List>('getPairedDevices');
      if (rawList == null) return [];

      return rawList.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return BluetoothPrinterDevice(
          name: map['name']?.toString() ?? 'Desconhecido',
          address: map['address']?.toString() ?? '',
        );
      }).toList();
    } catch (e) {
      _log('Erro ao obter dispositivos pareados: $e');
      return [];
    }
  }

  /// Checa se o Bluetooth do aparelho está ativado no hardware
  Future<bool> isBluetoothEnabled() async {
    try {
      final bool? enabled = await _channel.invokeMethod<bool>('isBluetoothEnabled');
      return enabled ?? false;
    } catch (e) {
      _log('Erro ao verificar status do Bluetooth: $e');
      return false;
    }
  }

  /// Conecta a uma impressora
  Future<bool> connect(String mac, String name) async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('connect', {'address': mac});
      final ok = result ?? false;
      _isConnected = ok;
      if (ok) {
        _connectedDeviceName = name;
        _connectedDeviceMac = mac;
      }
      return ok;
    } catch (e) {
      _log('Erro ao conectar via Bluetooth nativo: $e');
      _isConnected = false;
      return false;
    }
  }

  /// Desconecta a impressora
  Future<bool> disconnect() async {
    try {
      await _channel.invokeMethod('disconnect');
      _isConnected = false;
      _connectedDeviceName = '';
      _connectedDeviceMac = '';
      return true;
    } catch (e) {
      _log('Erro ao desconectar Bluetooth: $e');
      return false;
    }
  }

  /// Verifica o status da conexão atual sem ping destrutivo
  Future<bool> checkConnection() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('isConnected');
      _isConnected = result ?? false;
      return _isConnected;
    } catch (e) {
      _log('Erro ao checar status da conexão: $e');
      _isConnected = false;
      return false;
    }
  }

  /// Envia os bytes CPCL puros para impressão com confirmação ativa
  Future<bool> sendBytes(Uint8List bytes) async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('sendBytes', {'bytes': bytes});
      return result ?? false;
    } on PlatformException catch (pe) {
      _log('Erro nativo ao enviar bytes CPCL: ${pe.message}');
      throw Exception(pe.message ?? 'Falha na comunicação com a impressora.');
    } catch (e) {
      _log('Erro ao enviar bytes CPCL para impressora: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // Operação Atômica On-Demand (Conectar -> Imprimir -> Desconectar)
  // ===========================================================================

  /// Executa o ciclo completo de impressão com callbacks de progresso e resguardo de buffer
  Future<void> printLabelAtomic(
    BluetoothPrinterDevice device,
    Uint8List payload, {
    bool disconnectAfter = true,
    void Function(String status)? onProgress,
  }) async {
    bool shouldDisconnect = disconnectAfter;

    try {
      // 1. Conexão (apenas se ainda não estiver conectado à mesma impressora)
      final bool alreadyConnected = _isConnected && _connectedDeviceMac == device.address;
      if (!alreadyConnected) {
        onProgress?.call('Conectando a ${device.name}...');
        final connected = await connect(device.address, device.name);
        if (!connected) {
          throw Exception('Não foi possível conectar à impressora ${device.name}. Verifique se ela está ligada e próxima.');
        }
      }

      // 2. Transmissão com Confirmação Ativa via Hardware (InputStream)
      final kbSize = (payload.length / 1024).toStringAsFixed(1);
      onProgress?.call('Transmitindo e aguardando confirmação ($kbSize KB)...');
      final sent = await sendBytes(payload);
      if (!sent) {
        throw Exception('Falha na transmissão dos dados para a impressora.');
      }

      // 3. A K329 já respondeu o ACK físico no InputStream
      onProgress?.call('Impressão confirmada pela K329!');
      await Future.delayed(const Duration(milliseconds: PrinterConstants.atomicPrintSettleDelayMs));

      if (shouldDisconnect) {
        onProgress?.call('Finalizando e liberando impressora...');
      }
    } catch (e) {
      // Em caso de falha, sempre libera a conexão — mesmo se o chamador pediu
      // para mantê-la aberta (disconnectAfter: false) — para evitar deixar a
      // impressora em um estado travado/bloqueado para a próxima tentativa.
      shouldDisconnect = true;
      rethrow;
    } finally {
      if (shouldDisconnect) {
        await disconnect();
      }
    }
  }
}
