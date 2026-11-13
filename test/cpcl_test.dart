import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:compex_k329/models/gondola_label_model.dart';
import 'package:compex_k329/services/cpcl_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('CPCL generation produces valid CPCL command structure', () async {
    final model = GondolaLabelModel(
      description: 'AZEITE DE OLIVA EXTRA VIRGEM 500ML',
      price: '28,90',
      unit: 'UN',
      fractionalPrice: 'R\$ 57,80 por LITRO',
      barcode: '7896543215789',
      lengthMm: 100,
      shelfHeightMm: 26,
      printheadOffsetMm: 0,
      feedMarginMm: 0,
      rotationAngle: 90,
      copies: 1,
    );

    final payload = await CpclService.generatePrintPayload(model);
    expect(payload, isNotEmpty);

    final String text = latin1.decode(payload);

    // Verifica comandos essenciais do protocolo CPCL da K329
    expect(text.contains('! 0 200 200 800 1'), isTrue);
    expect(text.contains('PAGE-WIDTH 208'), isTrue);
    expect(text.contains('EG 26 800 0 0 '), isTrue);
    expect(text.contains('FORM'), isTrue);
    expect(text.contains('PRINT'), isTrue);
  });

  test('CPCL generation with custom offset and rotation 0', () async {
    final model = GondolaLabelModel(
      description: 'PRODUTO TESTE',
      price: '9,99',
      fractionalPrice: '', // Omitido
      printheadOffsetMm: 2, // 16 dots
      rotationAngle: 0,
    );

    final payload = await CpclService.generatePrintPayload(model);
    final String text = latin1.decode(payload);

    expect(text.contains('! 16 200 200 208 1'), isTrue);
    expect(text.contains('PAGE-WIDTH 800'), isTrue);
    expect(text.contains('EG 100 208 0 0 '), isTrue);
  });
}
