import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../constants/label_style_constants.dart';
import '../models/barcode_type.dart';
import '../models/gondola_label_model.dart';
import 'barcode_service.dart';

/// Transformação (translação + rotação) aplicada ao canvas rotacionado para
/// cada ângulo suportado, tomando como entrada as dimensões já rotacionadas.
class _RotationTransform {
  final double Function(int rotWidth, int rotHeight) translateX;
  final double Function(int rotWidth, int rotHeight) translateY;
  final double radians;

  const _RotationTransform({
    required this.translateX,
    required this.translateY,
    required this.radians,
  });
}

final Map<int, _RotationTransform> _rotationTransforms = {
  90: _RotationTransform(
    translateX: (w, h) => w.toDouble(),
    translateY: (w, h) => 0,
    radians: 90 * math.pi / 180,
  ),
  180: _RotationTransform(
    translateX: (w, h) => w.toDouble(),
    translateY: (w, h) => h.toDouble(),
    radians: 180 * math.pi / 180,
  ),
  270: _RotationTransform(
    translateX: (w, h) => 0,
    translateY: (w, h) => h.toDouble(),
    radians: 270 * math.pi / 180,
  ),
};

class LabelRendererService {
  /// Renderiza o Canvas horizontal de gôndola e aplica a rotação escolhida
  static Future<ui.Image> renderLabelImage(
    GondolaLabelModel model, {
    bool isPreview = false,
  }) async {
    final int layoutWidth = model.lengthDots;
    final int layoutHeight = model.shelfHeightDots;

    // 1. Grava o desenho horizontal no Canvas
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, layoutWidth.toDouble(), layoutHeight.toDouble()));

    _drawHorizontalLayout(canvas, model, layoutWidth, layoutHeight, isPreview: isPreview);

    final picture = recorder.endRecording();
    final unrotatedImage = await picture.toImage(layoutWidth, layoutHeight);

    // 2. Aplica a rotação (0, 90, 270, 360)
    final int rot = model.rotationAngle % 360;
    if (rot == 0) {
      return unrotatedImage;
    }

    final int rotWidth = (rot == 90 || rot == 270) ? layoutHeight : layoutWidth;
    final int rotHeight = (rot == 90 || rot == 270) ? layoutWidth : layoutHeight;

    final rotRecorder = ui.PictureRecorder();
    final rotCanvas = Canvas(rotRecorder, Rect.fromLTWH(0, 0, rotWidth.toDouble(), rotHeight.toDouble()));

    if (isPreview) {
      rotCanvas.drawColor(LabelStyleConstants.previewBackgroundColor, BlendMode.src);
    } else {
      rotCanvas.drawColor(Colors.white, BlendMode.src);
    }

    rotCanvas.save();
    final transform = _rotationTransforms[rot];
    if (transform != null) {
      rotCanvas.translate(transform.translateX(rotWidth, rotHeight), transform.translateY(rotWidth, rotHeight));
      rotCanvas.rotate(transform.radians);
    }

    rotCanvas.drawImage(unrotatedImage, Offset.zero, Paint());
    rotCanvas.restore();

    final rotPicture = rotRecorder.endRecording();
    return await rotPicture.toImage(rotWidth, rotHeight);
  }

  /// Desenha todos os elementos do modelo de gôndola no Canvas
  static void _drawHorizontalLayout(
    Canvas canvas,
    GondolaLabelModel model,
    int width,
    int height, {
    bool isPreview = false,
  }) {
    // Fundo
    final bgPaint = Paint()
      ..color = isPreview ? LabelStyleConstants.previewBackgroundColor : Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), bgPaint);

    final double feedOffset = model.feedMarginDots.toDouble();

    // 1. Descrição do Produto no Topo (1 linha contínua)
    _drawDescription(canvas, model.description, feedOffset, width.toDouble());

    // 2. Código de Barras (EAN-13 ou CODE-128)
    _drawBarcodeSection(canvas, model.barcode, model.barcodeType, feedOffset, height.toDouble());

    // 3. Preço Gigante e Unidade + Caixa Fracionada (se houver)
    final priceGroupGeometry = _drawPriceGroup(canvas, model, feedOffset, width.toDouble());
    _drawFractionalBox(canvas, model, priceGroupGeometry, height.toDouble(), isPreview: isPreview);

    // 4. Data no Canto Inferior Direito
    _drawDateSection(canvas, model.dateText, width.toDouble(), height.toDouble());
  }

  static void _drawDescription(Canvas canvas, String text, double feedOffset, double totalWidth) {
    if (text.trim().isEmpty) return;

    // Começa no tamanho máximo e reduz até caber na largura disponível, sem
    // passar do mínimo ainda legível na resolução de impressão da K329.
    double fontSize = LabelStyleConstants.descriptionMaxFontSize;
    final double maxTextWidth = totalWidth - feedOffset - 24;

    TextPainter tp;
    while (true) {
      final span = TextSpan(
        text: text.toUpperCase(),
        style: TextStyle(
          color: Colors.black,
          fontSize: fontSize,
          fontWeight: FontWeight.normal,
          fontFamily: 'sans-serif',
          letterSpacing: 0.3,
        ),
      );
      tp = TextPainter(
        text: span,
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();

      if (tp.width <= maxTextWidth || fontSize <= LabelStyleConstants.descriptionMinFontSize) {
        break;
      }
      fontSize -= 1.0;
    }

    final double x = feedOffset + 12;
    const double y = 5; // Posicionamento limpo no topo
    tp.paint(canvas, Offset(x, y));
  }

  static void _drawBarcodeSection(
    Canvas canvas,
    String code,
    BarcodeType type,
    double feedOffset,
    double totalHeight,
  ) {
    const double barcodeWidth = 260.0;
    const double barcodeHeight = 126.0;
    final double x = feedOffset + 12;
    final double y = totalHeight - barcodeHeight - 14;

    BarcodeService.drawBarcode(
      canvas,
      code,
      Rect.fromLTWH(x, y, barcodeWidth, barcodeHeight),
      barcodeType: type,
      color: Colors.black,
      drawDigits: true,
    );
  }

  /// Desenha o grupo "R$ `preço` `unidade`" e retorna a geometria calculada
  /// (posição inicial e métricas do preço) para que [_drawFractionalBox]
  /// possa posicionar a caixa fracionada sob o valor numérico.
  static ({double startX, double rPainterWidth, double baselinePriceY, double priceHeight}) _drawPriceGroup(
    Canvas canvas,
    GondolaLabelModel model,
    double feedOffset,
    double totalWidth,
  ) {
    // "R$"
    final rSpan = TextSpan(
      text: 'R\$ ',
      style: TextStyle(
        color: Colors.black,
        fontSize: LabelStyleConstants.currencyPrefixFontSize,
        fontWeight: FontWeight.w900,
        fontFamily: 'sans-serif',
      ),
    );
    final rPainter = TextPainter(text: rSpan, textDirection: TextDirection.ltr)..layout();

    // Valor do preço ("28,90")
    final priceSpan = TextSpan(
      text: model.price,
      style: TextStyle(
        color: Colors.black,
        fontSize: LabelStyleConstants.priceFontSize,
        fontWeight: FontWeight.w900,
        fontFamily: 'sans-serif',
        letterSpacing: -2.0,
      ),
    );
    final pricePainter = TextPainter(text: priceSpan, textDirection: TextDirection.ltr)..layout();

    // Unidade ("UN")
    final unitSpan = TextSpan(
      text: ' ${model.unit.toUpperCase()}',
      style: TextStyle(
        color: Colors.black,
        fontSize: LabelStyleConstants.unitFontSize,
        fontWeight: FontWeight.w900,
        fontFamily: 'sans-serif',
      ),
    );
    final unitPainter = TextPainter(text: unitSpan, textDirection: TextDirection.ltr)..layout();

    final double groupWidth = rPainter.width + pricePainter.width + unitPainter.width;
    final double rightEdge = totalWidth - 20.0;
    final double startX = math.max(feedOffset + 290.0, rightEdge - groupWidth);
    const double baselinePriceY = 40.0;

    // Desenha R$
    rPainter.paint(canvas, Offset(startX, baselinePriceY + 54));
    // Desenha Preço Gigante
    pricePainter.paint(canvas, Offset(startX + rPainter.width, baselinePriceY));
    // Desenha Unidade
    final double unX = startX + rPainter.width + pricePainter.width;
    unitPainter.paint(canvas, Offset(unX, baselinePriceY + 56));

    return (
      startX: startX,
      rPainterWidth: rPainter.width,
      baselinePriceY: baselinePriceY,
      priceHeight: pricePainter.height,
    );
  }

  /// Desenha a caixa de preço fracionado (ex.: "R$ 57,80 por LITRO"), se houver
  /// texto, posicionada sob o valor numérico desenhado por [_drawPriceGroup].
  static void _drawFractionalBox(
    Canvas canvas,
    GondolaLabelModel model,
    ({double startX, double rPainterWidth, double baselinePriceY, double priceHeight}) priceGroupGeometry,
    double totalHeight, {
    bool isPreview = false,
  }) {
    final String fracText = model.fractionalPrice.trim();
    if (fracText.isEmpty) return;

    final fracSpan = TextSpan(
      text: fracText,
      style: TextStyle(
        color: Colors.black,
        fontSize: LabelStyleConstants.fractionalPriceFontSize,
        fontWeight: FontWeight.w900,
        fontFamily: 'sans-serif',
      ),
    );
    final fracPainter = TextPainter(text: fracSpan, textDirection: TextDirection.ltr)..layout();

    const double boxHeight = 28.0;
    final double boxWidth = fracPainter.width + 16.0;
    // Posiciona a caixa sob o valor numérico do preço, terminando antes da área da data
    final double boxLeft = priceGroupGeometry.startX + priceGroupGeometry.rPainterWidth;
    final double boxTop = math.min(
      totalHeight - boxHeight - 18.0,
      priceGroupGeometry.baselinePriceY + priceGroupGeometry.priceHeight + 2,
    );

    // 1. Desenha contorno fino (Vermelho no preview / Preto na impressão, vazado)
    final borderPaint = Paint()
      ..color = isPreview ? LabelStyleConstants.previewFractionalBoxBorderColor : Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(Rect.fromLTWH(boxLeft, boxTop, boxWidth, boxHeight), borderPaint);

    // 2. Texto preto centralizado dentro da caixa
    final double textX = boxLeft + (boxWidth - fracPainter.width) / 2;
    final double textY = boxTop + (boxHeight - fracPainter.height) / 2;
    fracPainter.paint(canvas, Offset(textX, textY));
  }

  static void _drawDateSection(Canvas canvas, String dateStr, double totalWidth, double totalHeight) {
    final span = TextSpan(
      text: dateStr,
      style: TextStyle(
        color: Colors.black,
        fontSize: LabelStyleConstants.dateFontSize,
        fontWeight: FontWeight.w700,
        fontFamily: 'sans-serif',
      ),
    );
    final tp = TextPainter(text: span, textDirection: TextDirection.ltr)..layout();

    // Data no rodapé bem à direita
    final double x = totalWidth - tp.width - 16.0;
    final double y = totalHeight - tp.height - 10.0;
    tp.paint(canvas, Offset(x, y));
  }
}
