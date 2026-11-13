/// Tipos de código de barras suportados pela etiqueta de gôndola K329
enum BarcodeType {
  ean13('EAN-13'),
  code128('CODE-128');

  final String code;
  const BarcodeType(this.code);

  bool get isCode128 => this == BarcodeType.code128;
  bool get isEan13 => this == BarcodeType.ean13;
}
