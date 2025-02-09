import 'dart:math';

import 'package:flutter/material.dart';

class AppSizes {
  // FONT SIZES
  static const double fontSmall = 10.0;
  static const double fontMedium = 12.0;
  static const double fontLarge = 18.0;
  static const double fontHyperLarge = 28.0;

  // PADDING
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 20.0;
  
  // ICON SIZE
  static const double iconSmall = 12.0;
  static const double iconMedium = 16.0;
  static const double iconLarge = 24.0;
  static const double iconHyperLarge = 30.0;

  // Méthode pour rendre les valeurs responsives
  static double responsiveValue(BuildContext context, double baseValue) {
    return MediaQuery.of(context).size.width * (baseValue / 360);
  }
}
