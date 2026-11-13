import 'package:intl/intl.dart';
import '../constants/printer_constants.dart';
import 'barcode_type.dart';

class GondolaLabelModel {
  String description;
  String price;
  String unit;
  String fractionalPrice;
  String barcode;
  BarcodeType barcodeType;
  String dateText;

  int lengthMm;
  int shelfHeightMm;
  int printheadOffsetMm;
  int feedMarginMm;
  int rotationAngle; // 0, 90, 270, 360
  int copies;

  static const double dotsPerMm = PrinterConstants.dotsPerMm * 1.0;

  GondolaLabelModel({
    this.description = 'AZEITE DE OLIVA EXTRA VIRGEM 500ML',
    this.price = '28,90',
    this.unit = 'UN',
    this.fractionalPrice = 'R\$ 57,80 por LITRO',
    this.barcode = '7896543215789',
    this.barcodeType = BarcodeType.ean13,
    String? dateText,
    this.lengthMm = PrinterConstants.defaultLengthMm,
    this.shelfHeightMm = PrinterConstants.defaultShelfHeightMm,
    this.printheadOffsetMm = 0,
    this.feedMarginMm = 0,
    this.rotationAngle = PrinterConstants.defaultRotationAngle,
    this.copies = 1,
  }) : dateText = dateText ?? DateFormat('dd/MM/yyyy').format(DateTime.now());

  int get lengthDots => (lengthMm * dotsPerMm).round();
  int get shelfHeightDots => (shelfHeightMm * dotsPerMm).round();
  int get printheadOffsetDots => (printheadOffsetMm * dotsPerMm).round();
  int get feedMarginDots => (feedMarginMm * dotsPerMm).round();

  GondolaLabelModel copyWith({
    String? description,
    String? price,
    String? unit,
    String? fractionalPrice,
    String? barcode,
    BarcodeType? barcodeType,
    String? dateText,
    int? lengthMm,
    int? shelfHeightMm,
    int? printheadOffsetMm,
    int? feedMarginMm,
    int? rotationAngle,
    int? copies,
  }) {
    return GondolaLabelModel(
      description: description ?? this.description,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      fractionalPrice: fractionalPrice ?? this.fractionalPrice,
      barcode: barcode ?? this.barcode,
      barcodeType: barcodeType ?? this.barcodeType,
      dateText: dateText ?? this.dateText,
      lengthMm: lengthMm ?? this.lengthMm,
      shelfHeightMm: shelfHeightMm ?? this.shelfHeightMm,
      printheadOffsetMm: printheadOffsetMm ?? this.printheadOffsetMm,
      feedMarginMm: feedMarginMm ?? this.feedMarginMm,
      rotationAngle: rotationAngle ?? this.rotationAngle,
      copies: copies ?? this.copies,
    );
  }
}
