import 'package:flutter/material.dart';
import '../models/barcode_type.dart';

/// Modelo de dados para preset de amostra
class SamplePreset {
  final String label;
  final String description;
  final String price;
  final String unit;
  final String fractionalPrice;
  final String barcode;
  final BarcodeType barcodeType;
  final int lengthMm;
  final int shelfHeightMm;

  const SamplePreset({
    required this.label,
    required this.description,
    required this.price,
    required this.unit,
    required this.fractionalPrice,
    required this.barcode,
    this.barcodeType = BarcodeType.ean13,
    this.lengthMm = 100,
    this.shelfHeightMm = 26,
  });
}

/// Barra horizontal de amostras rápidas para teste
class SamplePresetsBar extends StatelessWidget {
  final ValueChanged<SamplePreset> onSelectPreset;

  const SamplePresetsBar({
    super.key,
    required this.onSelectPreset,
  });

  static const List<SamplePreset> defaultPresets = [
    SamplePreset(
      label: 'Azeite',
      description: 'AZEITE DE OLIVA EXTRA VIRGEM 500ML',
      price: '28,90',
      unit: 'UN',
      fractionalPrice: 'R\$ 57,80 por LITRO',
      barcode: '7896543215789',
    ),
    SamplePreset(
      label: 'Café',
      description: 'CAFÉ PILÃO TRADICIONAL 500G',
      price: '18,90',
      unit: 'UN',
      fractionalPrice: 'R\$ 37,80 por KG',
      barcode: '7891095000103',
    ),
    SamplePreset(
      label: 'Detergente',
      description: 'DETERGENTE LÍQUIDO YPÊ 500ML',
      price: '2,49',
      unit: 'UN',
      fractionalPrice: '', // Vazio para testar omissão
      barcode: '7891022100012',
    ),
    SamplePreset(
      label: 'Code 128',
      description: 'PARAFUSO SEXTAVADO INOX 1/4 X 2 POL',
      price: '0,45',
      unit: 'PC',
      fractionalPrice: 'R\$ 45,00 por CENTO',
      barcode: 'PAR-14X2',
      barcodeType: BarcodeType.code128,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: defaultPresets.map((preset) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onPressed: () => onSelectPreset(preset),
              child: Text(preset.label, style: const TextStyle(fontSize: 12)),
            ),
          );
        }).toList(),
      ),
    );
  }
}
