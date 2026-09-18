import 'package:flutter/material.dart';

/// Tokens del design system Modernist: rojo único sobre fondo claro,
/// radio cero, reglas de 2px y tipografía Archivo.
class TemaModernista {
  TemaModernista._();

  static const Color fondo = Color(0xFFF3F2F2);
  static const Color tinta = Color(0xFF201E1D);
  static const Color acento = Color(0xFFEC3013);
  static const Color acento100 = Color(0xFFFBE0DB);
  static const Color acento200 = Color(0xFFF7C2B8);
  static const Color acento700 = Color(0xFFA8200C);
  static const Color neutral200 = Color(0xFFDEDCDB);
  static const Color neutral300 = Color(0xFFCBC9C8);
  static const Color neutral400 = Color(0xFFB0AEAC);
  static const Color neutral800 = Color(0xFF3B3937);
  static const Color divisor = Color(0xFF201E1D);

  static const double reglaFuerte = 2;
  static const double reglaFina = 1;
  static const double radio = 0;

  /// Escala de espaciado del sistema (densidad 1.0).
  static const double esp1 = 4;
  static const double esp2 = 8;
  static const double esp3 = 12;
  static const double esp4 = 16;
  static const double esp5 = 24;
  static const double esp6 = 32;

  /// A partir de este ancho de ventana (tablet/desktop) se centra el
  /// contenido en vez de estirarlo de punta a punta.
  static const double breakpointAncho = 700;

  /// Ancho máximo del contenido cuando la ventana supera [breakpointAncho].
  static const double contenidoAnchoMaximo = 720;

  static TextStyle titulo(double tam) => TextStyle(
        fontFamily: 'Archivo',
        fontWeight: FontWeight.w800,
        fontSize: tam,
        height: 1.05,
        letterSpacing: -tam * 0.02,
        color: tinta,
      );

  static TextStyle etiqueta({Color color = tinta, double tam = 10}) =>
      TextStyle(
        fontFamily: 'Archivo',
        fontWeight: FontWeight.w800,
        fontSize: tam,
        letterSpacing: tam * 0.14,
        color: color,
      );

  static TextStyle cuerpo(
          {double tam = 13,
          Color color = tinta,
          FontWeight peso = FontWeight.w400}) =>
      TextStyle(
          fontFamily: 'Archivo',
          fontSize: tam,
          height: 1.35,
          fontWeight: peso,
          color: color);

  static ThemeData construir() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: fondo,
      colorScheme: base.colorScheme.copyWith(
        primary: acento,
        onPrimary: Colors.white,
        surface: fondo,
        onSurface: tinta,
      ),
      textTheme: base.textTheme
          .apply(fontFamily: 'Archivo', bodyColor: tinta, displayColor: tinta),
      dividerTheme: const DividerThemeData(
          color: divisor, thickness: reglaFina, space: 0),
      splashFactory: InkRipple.splashFactory,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fondo,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: esp3, vertical: esp3),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: neutral400, width: reglaFina),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: neutral400, width: reglaFina),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: acento, width: reglaFuerte),
        ),
        labelStyle: etiqueta(color: neutral800, tam: 11),
      ),
    );
  }
}
