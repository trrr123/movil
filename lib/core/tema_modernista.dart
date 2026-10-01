import 'package:flutter/material.dart';

/// Tokens del design system Modernist: rojo único sobre fondo blanco,
/// chrome oscuro para header/nav, radio cero, reglas de 2px y tipografía Archivo.
class TemaModernista {
  TemaModernista._();

  // ── Superficies ────────────────────────────────────────────────────────────
  static const Color fondo      = Color(0xFFFFFFFF); // blanco puro
  static const Color fondoOscuro = Color(0xFF0D0D0D); // casi negro — header, nav, cards hero

  // ── Tinta y acento ────────────────────────────────────────────────────────
  static const Color tinta      = Color(0xFF201E1D);
  static const Color acento     = Color(0xFFEC3013);
  static const Color acento100  = Color(0xFFFBE0DB);
  static const Color acento200  = Color(0xFFF7C2B8);
  static const Color acento700  = Color(0xFFA8200C);

  // ── Neutros ───────────────────────────────────────────────────────────────
  static const Color neutral200 = Color(0xFFE8E6E5);
  static const Color neutral300 = Color(0xFFD0CECD);
  static const Color neutral400 = Color(0xFFB0AEAC);
  static const Color neutral800 = Color(0xFF3B3937);
  static const Color divisor    = Color(0xFF201E1D);

  // ── Bordes ────────────────────────────────────────────────────────────────
  static const double reglaFuerte = 2;
  static const double reglaFina   = 1;
  static const double radio       = 0;

  // ── Espaciado ─────────────────────────────────────────────────────────────
  static const double esp1 =  4;
  static const double esp2 =  8;
  static const double esp3 = 12;
  static const double esp4 = 16;
  static const double esp5 = 24;
  static const double esp6 = 32;
  static const double esp7 = 56;
  static const double esp8 = 80;

  /// A partir de este ancho de ventana (tablet/desktop) se centra el
  /// contenido en vez de estirarlo de punta a punta.
  static const double breakpointAncho      = 700;
  static const double contenidoAnchoMaximo = 720;

  // ── Tipografía ────────────────────────────────────────────────────────────

  static TextStyle titulo(double tam, {Color color = tinta}) => TextStyle(
        fontFamily: 'Archivo',
        fontWeight: FontWeight.w800,
        fontSize: tam,
        height: 1.0,
        letterSpacing: -tam * 0.02,
        color: color,
      );

  static TextStyle etiqueta({Color color = tinta, double tam = 10}) =>
      TextStyle(
        fontFamily: 'Archivo',
        fontWeight: FontWeight.w800,
        fontSize: tam,
        letterSpacing: tam * 0.14,
        color: color,
      );

  static TextStyle cuerpo({
    double tam = 13,
    Color color = tinta,
    FontWeight peso = FontWeight.w400,
  }) =>
      TextStyle(
          fontFamily: 'Archivo',
          fontSize: tam,
          height: 1.35,
          fontWeight: peso,
          color: color);

  // ── Tema Material ─────────────────────────────────────────────────────────

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
