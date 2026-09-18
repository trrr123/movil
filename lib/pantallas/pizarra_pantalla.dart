import 'package:flutter/material.dart';

import '../core/tema_modernista.dart';
import '../estado/app_estado.dart';
import '../modelos/alineacion.dart';
import '../modelos/jugador.dart';
import '../modelos/usuario.dart';
import '../widgets/comunes.dart';

/// Pizarra táctica. El DT arrastra fichas, cambia sistema, guarda y descarga;
/// el jugador ve la alineación publicada con su posición marcada en rojo.
class PizarraPantalla extends StatelessWidget {
  const PizarraPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = AlcanceApp.de(context);
    final editable = estado.puede(Permiso.editarAlineacion);
    final a = estado.alineacion;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 26),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: Text(editable ? 'PIZARRA' : 'ALINEACIÓN', style: TemaModernista.titulo(28))),
            Text(a.formacion.nombre, style: TemaModernista.titulo(15).copyWith(color: TemaModernista.acento)),
          ],
        ),
        const SizedBox(height: TemaModernista.esp3),
        if (!editable)
          Container(
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: TemaModernista.acento, width: 3)),
            ),
            padding: const EdgeInsets.fromLTRB(10, 8, 0, 8),
            child: Text('Alineación publicada por el cuerpo técnico. Tu posición está marcada en rojo.',
                style: TemaModernista.cuerpo(tam: 12, color: TemaModernista.neutral800)),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final f in Formacion.presets)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => estado.aplicarFormacion(f),
                      child: Container(
                        decoration: BoxDecoration(
                          color: f.nombre == a.formacion.nombre ? TemaModernista.tinta : Colors.transparent,
                          border: const Border.fromBorderSide(BorderSide(color: TemaModernista.neutral400)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        child: Text(f.nombre,
                            style: TemaModernista.titulo(12).copyWith(
                              color: f.nombre == a.formacion.nombre ? TemaModernista.fondo : TemaModernista.tinta,
                            )),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: TemaModernista.esp3),
        AspectRatio(
          aspectRatio: 68 / 88,
          child: CanchaWidget(
            alineacion: a,
            editable: editable,
            destacado: estado.miFicha?.id,
            onMover: estado.moverFicha,
          ),
        ),
        const SizedBox(height: TemaModernista.esp3),
        if (editable) ...[
          Row(
            children: [
              Expanded(
                child: BotonModernista('Guardar',
                    variante: VarianteBoton.secundario, onTap: estado.guardarAlineacion),
              ),
              const SizedBox(width: TemaModernista.esp2),
              Expanded(
                child: BotonModernista('Descargar', onTap: () => _hojaDescarga(context, estado)),
              ),
            ],
          ),
          const SizedBox(height: TemaModernista.esp5),
          const Kicker('Banca · toca para intercambiar'),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final j in estado.banca)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => _elegirSalida(context, estado, j),
                      child: Container(
                        width: 56,
                        decoration: BoxDecoration(
                          color: j.disponible ? TemaModernista.fondo : TemaModernista.acento100,
                          border: const Border.fromBorderSide(BorderSide(color: TemaModernista.neutral400)),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          children: [
                            Text('${j.dorsal}',
                                style: TemaModernista.titulo(15).copyWith(
                                  color: j.disponible ? TemaModernista.tinta : TemaModernista.acento700,
                                )),
                            Text(j.apellido,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TemaModernista.cuerpo(tam: 8.5, color: TemaModernista.neutral800)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: TemaModernista.esp5),
          const Kicker('Alineaciones guardadas'),
          for (final g in estado.alineacionesGuardadas)
            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: TemaModernista.neutral300)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  SizedBox(width: 48, child: Text(g.formacion.nombre, style: TemaModernista.titulo(13))),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g.nombre, style: TemaModernista.cuerpo()),
                        Text('${g.creada.day}/${g.creada.month} · ${g.creada.hour}:${g.creada.minute.toString().padLeft(2, '0')}',
                            style: TemaModernista.cuerpo(tam: 10, color: TemaModernista.neutral400)),
                      ],
                    ),
                  ),
                  BotonModernista('Cargar',
                      variante: VarianteBoton.fantasma, expandido: false, onTap: () => estado.cargarAlineacion(g)),
                ],
              ),
            ),
        ],
      ],
    );
  }

  void _elegirSalida(BuildContext context, AppEstado estado, Jugador entra) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: TemaModernista.fondo,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('¿Quién sale por ${entra.apellido}?', style: TemaModernista.titulo(20)),
            ),
            const Regla(),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final f in estado.alineacion.fichas)
                    ListTile(
                      title: Text('${f.jugador.dorsal} · ${f.jugador.nombre}', style: TemaModernista.cuerpo()),
                      onTap: () {
                        estado.sustituir(saleId: f.jugador.id, entra: entra);
                        Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _hojaDescarga(BuildContext context, AppEstado estado) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: TemaModernista.fondo,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Kicker('Descargar', color: TemaModernista.acento),
                  Text('Alineación ${estado.alineacion.formacion.nombre}', style: TemaModernista.titulo(20)),
                ],
              ),
            ),
            for (final f in estado.formatosAlineacion)
              ListTile(
                leading: SizedBox(
                  width: 46,
                  child: Text(f.extension.toUpperCase(),
                      style: TemaModernista.etiqueta(color: TemaModernista.acento, tam: 11)),
                ),
                title: Text(f.descripcion, style: TemaModernista.cuerpo()),
                onTap: () {
                  estado.descargar(estado.alineacion, f);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Cancha pintada + fichas arrastrables. Traduce píxeles a coordenadas 0..1
/// para que la alineación sea independiente del tamaño de pantalla.
class CanchaWidget extends StatelessWidget {
  const CanchaWidget({
    super.key,
    required this.alineacion,
    required this.editable,
    required this.onMover,
    this.destacado,
  });

  final Alineacion alineacion;
  final bool editable;
  final int? destacado;
  final void Function(int jugadorId, PuntoCampo destino) onMover;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final ancho = c.maxWidth, alto = c.maxHeight;
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFEDECEB),
            border: Border.fromBorderSide(BorderSide(color: TemaModernista.divisor, width: 2)),
          ),
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _LineasCancha())),
              for (final f in alineacion.fichas)
                Positioned(
                  left: f.punto.x * ancho - 19,
                  top: f.punto.y * alto - 21,
                  child: GestureDetector(
                    onPanUpdate: editable
                        ? (d) => onMover(
                              f.jugador.id,
                              f.punto.desplazado(d.delta.dx / ancho, d.delta.dy / alto),
                            )
                        : null,
                    child: _Ficha(
                      dorsal: f.jugador.dorsal,
                      apellido: f.jugador.apellido,
                      color: editable
                          ? (f.jugador.posicion == Posicion.portero ? TemaModernista.tinta : TemaModernista.acento)
                          : (f.jugador.id == destacado ? TemaModernista.acento : TemaModernista.tinta),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Ficha extends StatelessWidget {
  const _Ficha({required this.dorsal, required this.apellido, required this.color});
  final int dorsal;
  final String apellido;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              border: const Border.fromBorderSide(BorderSide(color: TemaModernista.divisor, width: 2)),
            ),
            alignment: Alignment.center,
            child: Text('$dorsal', style: TemaModernista.titulo(13).copyWith(color: Colors.white)),
          ),
          const SizedBox(height: 2),
          Container(
            color: TemaModernista.tinta,
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            child: Text(apellido,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TemaModernista.cuerpo(tam: 8.5, color: TemaModernista.fondo)),
          ),
        ],
      );
}

class _LineasCancha extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = const Color(0x47201E1D)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, s.height / 2), Offset(s.width, s.height / 2), p);
    canvas.drawCircle(Offset(s.width / 2, s.height / 2), s.width * .13, p);
    final areaW = s.width * .56, areaH = s.height * .15;
    canvas.drawRect(Rect.fromLTWH((s.width - areaW) / 2, 0, areaW, areaH), p);
    canvas.drawRect(Rect.fromLTWH((s.width - areaW) / 2, s.height - areaH, areaW, areaH), p);
    final chicaW = s.width * .28, chicaH = s.height * .06;
    canvas.drawRect(Rect.fromLTWH((s.width - chicaW) / 2, 0, chicaW, chicaH), p);
    canvas.drawRect(Rect.fromLTWH((s.width - chicaW) / 2, s.height - chicaH, chicaW, chicaH), p);
  }

  @override
  bool shouldRepaint(CustomPainter old) => false;
}
