import 'package:flutter/material.dart';

import '../core/tema_modernista.dart';

/// Regla fuerte de 2px: el separador estructural del sistema.
class Regla extends StatelessWidget {
  const Regla(
      {super.key,
      this.grosor = TemaModernista.reglaFuerte,
      this.color = TemaModernista.divisor});
  final double grosor;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(height: grosor, color: color);
}

/// Encabezado de bloque en versalitas, siempre al ras izquierdo.
class Kicker extends StatelessWidget {
  const Kicker(this.texto, {super.key, this.color = TemaModernista.neutral800});
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: TemaModernista.esp2),
        child: Text(texto.toUpperCase(),
            style: TemaModernista.etiqueta(color: color)),
      );
}

enum VarianteBoton { primario, secundario, fantasma }

/// Botón del sistema: sin radio, etiqueta al ras izquierdo.
class BotonModernista extends StatelessWidget {
  const BotonModernista(
    this.texto, {
    super.key,
    required this.onTap,
    this.variante = VarianteBoton.primario,
    this.expandido = true,
  });

  final String texto;
  final VoidCallback? onTap;
  final VarianteBoton variante;
  final bool expandido;

  @override
  Widget build(BuildContext context) {
    final esPrimario = variante == VarianteBoton.primario;
    final fondo = esPrimario ? TemaModernista.acento : Colors.transparent;
    final borde = variante == VarianteBoton.fantasma
        ? Colors.transparent
        : TemaModernista.divisor;
    final tinta = esPrimario ? Colors.white : TemaModernista.tinta;

    final boton = Material(
      color: fondo,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(
            color: borde, width: esPrimario ? 0 : TemaModernista.reglaFina),
      ),
      child: InkWell(
        onTap: onTap,
        hoverColor:
            esPrimario ? TemaModernista.acento700 : TemaModernista.acento100,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: TemaModernista.esp4, vertical: TemaModernista.esp3),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(texto,
                style: TemaModernista.cuerpo(
                    tam: 14, color: tinta, peso: FontWeight.w600)),
          ),
        ),
      ),
    );
    return expandido ? SizedBox(width: double.infinity, child: boton) : boton;
  }
}

/// Etiqueta tonal (estado físico, tipo de evento, estado de cuota).
class Etiqueta extends StatelessWidget {
  const Etiqueta(this.texto,
      {super.key,
      this.fondo = TemaModernista.neutral200,
      this.tinta = TemaModernista.neutral800});
  final String texto;
  final Color fondo;
  final Color tinta;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: TemaModernista.esp2, vertical: 3),
        color: fondo,
        child: Text(texto.toUpperCase(),
            style: TemaModernista.etiqueta(color: tinta, tam: 9)),
      );
}

/// Celda de la grilla de cifras (28 puntos / 14 jugados / +12).
class CeldaCifra extends StatelessWidget {
  const CeldaCifra(
      {super.key,
      required this.valor,
      required this.rotulo,
      this.color = TemaModernista.tinta});
  final String valor;
  final String rotulo;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        color: TemaModernista.fondo,
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: TemaModernista.esp3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(valor,
                style: TemaModernista.titulo(24).copyWith(color: color)),
            const SizedBox(height: TemaModernista.esp1),
            Text(rotulo.toUpperCase(),
                style: TemaModernista.etiqueta(
                    color: TemaModernista.neutral800, tam: 9)),
          ],
        ),
      );
}

/// Grilla de celdas separada por líneas de 1px (la rejilla visible del sistema).
class GrillaCifras extends StatelessWidget {
  const GrillaCifras({super.key, required this.celdas});
  final List<CeldaCifra> celdas;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          border: Border.fromBorderSide(
              BorderSide(color: TemaModernista.neutral300)),
          color: TemaModernista.neutral300,
        ),
        child: Row(
          children: [
            for (var i = 0; i < celdas.length; i++) ...[
              if (i > 0) const SizedBox(width: 1),
              Expanded(child: celdas[i]),
            ]
          ],
        ),
      );
}

/// Centra y limita el ancho del contenido en tablet/desktop; en celular
/// (ancho por debajo de [TemaModernista.breakpointAncho]) no cambia nada.
class ContenidoResponsivo extends StatelessWidget {
  const ContenidoResponsivo({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    if (ancho < TemaModernista.breakpointAncho) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: TemaModernista.contenidoAnchoMaximo),
        child: child,
      ),
    );
  }
}

/// Barra de progreso rectangular (perfil del jugador, recaudo de cuotas).
class BarraValor extends StatelessWidget {
  const BarraValor({super.key, required this.porcentaje, this.alto = 8});
  final double porcentaje;
  final double alto;

  @override
  Widget build(BuildContext context) => Container(
        height: alto,
        color: TemaModernista.neutral200,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: porcentaje.clamp(0, 1),
          child: Container(color: TemaModernista.acento),
        ),
      );
}
