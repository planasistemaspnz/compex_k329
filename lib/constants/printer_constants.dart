/// Constantes de domínio para a impressora K329 e renderização de etiquetas
abstract class PrinterConstants {
  /// Densidade de pontos da K329 (203 DPI = ~8 dots por mm)
  static const int dotsPerMm = 8;

  /// Dimensões padrão da fita e etiqueta de gôndola
  static const int defaultShelfHeightMm = 26;
  static const int defaultLengthMm = 100;
  static const int defaultTapeWidthMm = 31;

  /// Limiar de binarização monocromática (50% cinza térmico)
  static const int monochromeLuminanceThreshold = 128;

  /// Limiar de alpha abaixo do qual um pixel é tratado como transparente/branco
  static const int monochromeAlphaThreshold = 64;

  /// Pesos de luminância relativa (ITU-R BT.601) usados na conversão para monocromático
  static const double luminanceWeightR = 0.299;
  static const double luminanceWeightG = 0.587;
  static const double luminanceWeightB = 0.114;

  /// Resolução de impressão enviada no comando CPCL (DPI-X e DPI-Y da K329)
  static const int defaultDpi = 200;

  /// Ângulo padrão de rotação no cabeçote térmico (90° para fita contínua horizontal)
  static const int defaultRotationAngle = 90;

  /// Tempo de assentamento do ACK físico da K329 antes de liberar a conexão
  static const int atomicPrintSettleDelayMs = 300;

  /// Chaves de persistência local
  static const String prefPrinterName = 'k329_default_printer_name';
  static const String prefPrinterAddress = 'k329_default_printer_address';
  static const String prefAutoDisconnect = 'k329_auto_disconnect';

  /// Nome do canal de comunicação nativo
  static const String methodChannelName = 'com.gondolaprinter.channel/printer';
}
