import 'package:flutter_test/flutter_test.dart';
import 'package:barcode/barcode.dart';

void main() {
  test('Barcode EAN13 generation', () {
    final bc = Barcode.ean13();
    final elements = bc.make('7896543215789', width: 220, height: 70, drawText: false);
    expect(elements, isNotEmpty);

    int blackBars = 0;
    for (final el in elements) {
      if (el is BarcodeBar && el.black) {
        blackBars++;
      }
    }
    expect(blackBars, greaterThan(0));
  });

  test('Barcode Code 128 generation', () {
    final bc = Barcode.code128();
    final elements = bc.make('PAR-14X2', width: 220, height: 70, drawText: false);
    expect(elements, isNotEmpty);

    int blackBars = 0;
    for (final el in elements) {
      if (el is BarcodeBar && el.black) {
        blackBars++;
      }
    }
    expect(blackBars, greaterThan(0));
  });
}
