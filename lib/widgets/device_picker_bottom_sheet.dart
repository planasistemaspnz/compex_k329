import 'package:flutter/material.dart';
import '../services/bluetooth_printer_service.dart';

/// BottomSheet para seleção da impressora Bluetooth pareada
class DevicePickerBottomSheet extends StatelessWidget {
  /// Trechos do nome do dispositivo que indicam ser uma impressora K329 (ou compatível)
  static const List<String> _recommendedNameHints = ['K329', 'PRINTER', 'GP-'];

  final List<BluetoothPrinterDevice> devices;
  final BluetoothPrinterDevice? currentSelected;
  final ValueChanged<BluetoothPrinterDevice> onSelect;

  const DevicePickerBottomSheet({
    super.key,
    required this.devices,
    required this.currentSelected,
    required this.onSelect,
  });

  static Future<BluetoothPrinterDevice?> show(
    BuildContext context, {
    required List<BluetoothPrinterDevice> devices,
    required BluetoothPrinterDevice? currentSelected,
  }) {
    return showModalBottomSheet<BluetoothPrinterDevice>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DevicePickerBottomSheet(
          devices: devices,
          currentSelected: currentSelected,
          onSelect: (dev) => Navigator.pop(ctx, dev),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Selecione a Impressora K329',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final dev = devices[index];
                final String upperName = dev.name.toUpperCase();
                final bool isK329 = _recommendedNameHints.any(upperName.contains);
                final bool isSelected = currentSelected?.address == dev.address;

                return ListTile(
                  leading: Icon(
                    Icons.print,
                    color: isSelected
                        ? Colors.green[700]
                        : (isK329 ? Colors.indigo : Colors.grey),
                  ),
                  title: Text(
                    dev.name,
                    style: TextStyle(
                      fontWeight: isK329 || isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.green[800] : null,
                    ),
                  ),
                  subtitle: Text(dev.address),
                  trailing: isSelected
                      ? const Chip(
                          label: Text('Padrão', style: TextStyle(fontSize: 10, color: Colors.white)),
                          backgroundColor: Colors.green,
                        )
                      : (isK329 ? const Chip(label: Text('Recomendado', style: TextStyle(fontSize: 10))) : null),
                  onTap: () => onSelect(dev),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
