import 'package:flutter/material.dart';

/// Constantes visuais (cores e tamanhos de fonte) usadas na renderização da etiqueta.
abstract class LabelStyleConstants {
  /// Fundo amarelo usado apenas na pré-visualização (nunca na impressão real)
  static const Color previewBackgroundColor = Color(0xFFFFE500);

  /// Borda vermelha da caixa de preço fracionado, usada apenas na pré-visualização
  static const Color previewFractionalBoxBorderColor = Color(0xFFCC0000);

  /// Cor primária da identidade visual do app
  static const Color primaryBrandColor = Color(0xFF1565C0);

  /// Cor de sucesso (confirmações, ações concluídas)
  static const Color successColor = Color(0xFF2E7D32);

  /// Tamanho inicial/máximo da descrição do produto antes do autoajuste
  static const double descriptionMaxFontSize = 36.0;

  /// Tamanho mínimo legível da descrição no DPI de impressão da K329
  static const double descriptionMinFontSize = 15.0;

  static const double priceFontSize = 98.0;
  static const double currencyPrefixFontSize = 32.0;
  static const double unitFontSize = 30.0;
  static const double fractionalPriceFontSize = 19.0;
  static const double dateFontSize = 13.0;
}
