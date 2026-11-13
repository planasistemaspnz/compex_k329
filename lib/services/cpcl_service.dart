import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import '../constants/printer_constants.dart';
import '../models/gondola_label_model.dart';
import 'label_renderer_service.dart';

class CpclService {
  /// Gera o payload completo CPCL pronto para enviar via Bluetooth à K329
  static Future<Uint8List> generatePrintPayload(GondolaLabelModel model) async {
    // 1. Renderiza a imagem para impressão (fundo branco, preto térmico)
    final ui.Image labelImage = await LabelRendererService.renderLabelImage(model, isPreview: false);

    final int width = labelImage.width;
    final int height = labelImage.height;

    // Obtém os pixels em formato RGBA
    final ByteData? byteData = await labelImage.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) {
      throw Exception('Falha ao extrair mapa de pixels da etiqueta');
    }
    final Uint8List rgbaBytes = byteData.buffer.asUint8List();

    // 2. Converte para formato monocromático 1-bit agrupado em bytes
    final int bytesPerLine = (width + 7) ~/ 8;
    final Uint8List monoBytes = _toMonochromeBytes(rgbaBytes, width, height, bytesPerLine);

    // 3. Converte para representação hexadecimal para o comando CPCL EG
    final String hex = _toHex(monoBytes);

    // 4. Monta o script CPCL da K329
    return _buildCpclScript(
      width: width,
      height: height,
      bytesPerLine: bytesPerLine,
      hex: hex,
      offsetDots: model.printheadOffsetDots,
      copies: model.copies,
    );
  }

  /// Converte pixels RGBA em bits monocromáticos (1 = preto), agrupados em bytes
  static Uint8List _toMonochromeBytes(Uint8List rgbaBytes, int width, int height, int bytesPerLine) {
    final Uint8List monoBytes = Uint8List(bytesPerLine * height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int pixelIndex = (y * width + x) * 4;
        final int r = rgbaBytes[pixelIndex];
        final int g = rgbaBytes[pixelIndex + 1];
        final int b = rgbaBytes[pixelIndex + 2];
        final int a = rgbaBytes[pixelIndex + 3];

        // Se transparente ou claro -> branco; se escuro -> preto
        final int luminance = (PrinterConstants.luminanceWeightR * r +
                PrinterConstants.luminanceWeightG * g +
                PrinterConstants.luminanceWeightB * b)
            .round();
        final bool isBlack = (a > PrinterConstants.monochromeAlphaThreshold) &&
            (luminance < PrinterConstants.monochromeLuminanceThreshold);

        if (isBlack) {
          final int byteIndex = y * bytesPerLine + (x ~/ 8);
          final int bitPosition = 7 - (x % 8);
          monoBytes[byteIndex] |= (1 << bitPosition);
        }
      }
    }

    return monoBytes;
  }

  /// Converte bytes brutos em uma string hexadecimal maiúscula (para o comando CPCL EG)
  static String _toHex(Uint8List bytes) {
    final StringBuffer hexBuffer = StringBuffer();
    const hexChars = '0123456789ABCDEF';
    for (final int b in bytes) {
      hexBuffer.write(hexChars[(b >> 4) & 0x0F]);
      hexBuffer.write(hexChars[b & 0x0F]);
    }
    return hexBuffer.toString();
  }

  /// Monta o script CPCL final (comandos de página, imagem e impressão) como bytes latin1
  static Uint8List _buildCpclScript({
    required int width,
    required int height,
    required int bytesPerLine,
    required String hex,
    required int offsetDots,
    required int copies,
  }) {
    final StringBuffer cpcl = StringBuffer();
    cpcl.write('! $offsetDots ${PrinterConstants.defaultDpi} ${PrinterConstants.defaultDpi} $height $copies\r\n');
    cpcl.write('PAGE-WIDTH $width\r\n');
    cpcl.write('EG $bytesPerLine $height 0 0 $hex\r\n');
    cpcl.write('FORM\r\n');
    cpcl.write('PRINT\r\n');

    return Uint8List.fromList(latin1.encode(cpcl.toString()));
  }
}
