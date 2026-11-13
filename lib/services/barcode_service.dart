import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:barcode/barcode.dart' hide BarcodeType;
import '../models/barcode_type.dart';

class BarcodeService {
  // Espelham intencionalmente os defaults de GondolaLabelModel (description,
  // barcode) — mantidos aqui, nomeados, para que a duplicação seja explícita
  // em vez de strings soltas repetidas silenciosamente nos dois arquivos.
  static const String _fallbackEan13Code = '7896543215789';
  static const String _fallbackCode128Code = 'PROD-12345';

  /// Formata o número EAN-13 com espaçamento característico: "7  896543  215789"
  static String formatEan13Text(String raw) {
    final clean = raw.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 13) {
      return '${clean[0]}  ${clean.substring(1, 7)}  ${clean.substring(7, 13)}';
    }
    return raw;
  }

  /// Desenha o código de barras (EAN-13 ou CODE-128) no Canvas com margem zero
  static void drawBarcode(
    Canvas canvas,
    String barcodeText,
    Rect bounds, {
    BarcodeType barcodeType = BarcodeType.ean13,
    Color color = Colors.black,
    bool drawDigits = true,
  }) {
    final bool isCode128 = barcodeType.isCode128;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const double barcodeHeightRatio = 0.72; // Altura das barras vs texto
    final double barHeight = drawDigits ? bounds.height * barcodeHeightRatio : bounds.height;

    String textToDraw = barcodeText.trim();
    if (textToDraw.isEmpty) {
      textToDraw = isCode128 ? _fallbackCode128Code : _fallbackEan13Code;
    }

    try {
      final Barcode bc = isCode128 ? Barcode.code128() : Barcode.ean13();

      final String effectiveCode;
      if (isCode128) {
        effectiveCode = textToDraw;
      } else {
        final clean = textToDraw.replaceAll(RegExp(r'\D'), '');
        effectiveCode = clean.length == 13 ? clean : _fallbackEan13Code;
      }

      final elements = bc.make(
        effectiveCode,
        width: bounds.width,
        height: barHeight,
        drawText: false,
      );

      for (final el in elements) {
        if (el is BarcodeBar && el.black) {
          canvas.drawRect(
            Rect.fromLTWH(
              bounds.left + el.left,
              bounds.top + el.top,
              el.width,
              el.height,
            ),
            paint,
          );
        }
      }

      if (drawDigits) {
        final String displayText = isCode128 ? effectiveCode : formatEan13Text(effectiveCode);
        final textSpan = TextSpan(
          text: displayText,
          style: TextStyle(
            color: color,
            fontSize: (bounds.height * 0.22).clamp(10.0, 17.0),
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
            letterSpacing: isCode128 ? 1.0 : 1.5,
          ),
        );

        final textPainter = TextPainter(
          text: textSpan,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: bounds.width);

        final double textX = bounds.left + (bounds.width - textPainter.width) / 2;
        final double textY = bounds.top + barHeight + 2;
        textPainter.paint(canvas, Offset(textX, textY));
      }
    } on BarcodeException catch (e) {
      // Entrada malformada (código de barras inválido para o tipo escolhido) é
      // um caso esperado — a preview não deve quebrar enquanto o usuário digita.
      if (kDebugMode) {
        debugPrint('Código de barras inválido, desenhando fallback: $e');
      }
      canvas.drawRect(
        Rect.fromLTWH(bounds.left, bounds.top, bounds.width, barHeight),
        paint,
      );
    }
  }
}
