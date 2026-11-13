import 'package:shared_preferences/shared_preferences.dart';
import '../constants/printer_constants.dart';
import 'bluetooth_printer_service.dart';

/// Serviço responsável exclusivamente pela persistência e leitura das preferências de impressão
class PrinterPreferencesService {
  /// Salva a impressora selecionada como padrão
  static Future<void> saveDefaultPrinter(String name, String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrinterConstants.prefPrinterName, name);
    await prefs.setString(PrinterConstants.prefPrinterAddress, address);
  }

  /// Recupera a impressora padrão salva (se houver)
  static Future<BluetoothPrinterDevice?> getSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(PrinterConstants.prefPrinterName);
    final address = prefs.getString(PrinterConstants.prefPrinterAddress);

    if (name != null && address != null && address.isNotEmpty) {
      return BluetoothPrinterDevice(name: name, address: address);
    }
    return null;
  }

  /// Remove a impressora padrão salva
  static Future<void> clearSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(PrinterConstants.prefPrinterName);
    await prefs.remove(PrinterConstants.prefPrinterAddress);
  }

  /// Salva a preferência de desconexão automática após imprimir (On-Demand)
  static Future<void> saveAutoDisconnect(bool autoDisconnect) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrinterConstants.prefAutoDisconnect, autoDisconnect);
  }

  /// Recupera se deve desconectar automaticamente após imprimir (padrão: true)
  static Future<bool> getAutoDisconnect() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PrinterConstants.prefAutoDisconnect) ?? true;
  }
}
