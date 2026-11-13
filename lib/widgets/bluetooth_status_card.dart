import 'package:flutter/material.dart';
import '../constants/label_style_constants.dart';
import '../services/bluetooth_printer_service.dart';

/// Card de exibição do status do Bluetooth, impressora padrão e opção On-Demand
class BluetoothStatusCard extends StatelessWidget {
  final BluetoothPrinterDevice? savedPrinter;
  final bool isConnected;
  final bool isLoadingDevices;
  final bool autoDisconnect;
  final VoidCallback onOpenPicker;
  final VoidCallback onDisconnect;
  final ValueChanged<bool> onToggleAutoDisconnect;

  const BluetoothStatusCard({
    super.key,
    required this.savedPrinter,
    required this.isConnected,
    required this.isLoadingDevices,
    required this.autoDisconnect,
    required this.onOpenPicker,
    required this.onDisconnect,
    required this.onToggleAutoDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final hasPrinter = savedPrinter != null;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isConnected
                        ? Colors.green.withAlpha(35)
                        : (hasPrinter ? Colors.blue.withAlpha(35) : Colors.orange.withAlpha(35)),
                  ),
                  child: Icon(
                    isConnected ? Icons.bluetooth_connected : (hasPrinter ? Icons.print : Icons.print_disabled),
                    color: isConnected
                        ? Colors.green[800]
                        : (hasPrinter ? Colors.blue[800] : Colors.orange[800]),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasPrinter ? savedPrinter!.name : 'Nenhuma impressora selecionada',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasPrinter
                            ? (isConnected
                                ? '${savedPrinter!.address} • Conectado'
                                : '${savedPrinter!.address} • Pronto (${autoDisconnect ? "On-Demand" : "Manual"})')
                            : 'Toque em Selecionar para vincular',
                        style: TextStyle(
                          color: isConnected ? Colors.green[700] : Colors.grey[600],
                          fontSize: 11,
                          fontWeight: isConnected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasPrinter && isConnected) ...[
                  TextButton.icon(
                    onPressed: onDisconnect,
                    icon: const Icon(Icons.link_off, size: 16, color: Colors.red),
                    label: const Text('Desconectar', style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                ] else ...[
                  TextButton.icon(
                    onPressed: isLoadingDevices ? null : onOpenPicker,
                    icon: isLoadingDevices
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(hasPrinter ? Icons.sync_alt : Icons.bluetooth_searching, size: 18),
                    label: Text(hasPrinter ? 'Alterar' : 'Selecionar'),
                  ),
                ],
              ],
            ),
            if (hasPrinter) ...[
              const Divider(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          autoDisconnect ? Icons.power_settings_new : Icons.all_inclusive,
                          size: 16,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'On-Demand',
                            style: TextStyle(fontSize: 12, color: Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: autoDisconnect,
                      activeThumbColor: LabelStyleConstants.primaryBrandColor,
                      onChanged: onToggleAutoDisconnect,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
