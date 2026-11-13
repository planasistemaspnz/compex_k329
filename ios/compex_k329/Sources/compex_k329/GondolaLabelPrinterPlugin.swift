import Flutter
import UIKit

public class GondolaLabelPrinterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.gondolaprinter.channel/printer",
      binaryMessenger: registrar.messenger()
    )
    let instance = GondolaLabelPrinterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPairedDevices", "connect", "disconnect", "isConnected", "isBluetoothEnabled", "sendBytes":
      result(FlutterError(
        code: "UNSUPPORTED_PLATFORM",
        message: "Impressão via Bluetooth clássico (RFCOMM/SPP) não é suportada no iOS. Disponível apenas no Android.",
        details: nil
      ))
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
