import 'package:flutter/material.dart';

import '../core/tema_modernista.dart';
import '../estado/app_estado.dart';
import '../modelos/partido.dart';
import '../modelos/usuario.dart';
import '../widgets/comunes.dart';
import 'convocatoria_pantalla.dart';
import 'en_vivo_pantalla.dart';

/// Agenda compartida por los dos roles: partidos y sesiones en una sola línea
/// de tiempo. Al DT los ítems le abren herramientas; al jugador, información.
class AgendaPantalla extends StatelessWidget {
  const AgendaPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = AlcanceApp.de(context);
    final esDT = estado.puede(Permiso.registrarAsistencia);

    final items = <_ItemAgenda>[
      for (final s in estado.sesiones)
        _ItemAgenda(
          fecha: s.fecha,
          tipo: s.tipo == TipoSesion.video ? 'Video' : 'Entreno',
          titulo: s.titulo,
          lugar: s.lugar,
          destacado: false,
          onTap: esDT
              ? () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => ConvocatoriaPantalla(sesion: s)))
              : null,
        ),
      for (final p in estado.partidos)
        _ItemAgenda(
          fecha: p.fecha,
          tipo: 'Partido',
          titulo: 'Makuira vs. ${p.rival}',
          lugar: p.sede,
          destacado: true,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EnVivoPantalla())),
        ),
    ]..sort((a, b) => a.fecha.compareTo(b.fecha));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
      children: [
        Text('AGENDA', style: TemaModernista.titulo(28)),
        const SizedBox(height: TemaModernista.esp4),
        const Regla(),
        for (final i in items)
          InkWell(
            onTap: i.onTap,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: TemaModernista.neutral300)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 52,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${i.fecha.day}', style: TemaModernista.titulo(20)),
                        Text(_dow(i.fecha).toUpperCase(),
                            style: TemaModernista.etiqueta(color: TemaModernista.neutral400, tam: 9)),
                      ],
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 52,
                    color: i.destacado ? TemaModernista.acento : TemaModernista.tinta,
                  ),
                  const SizedBox(width: TemaModernista.esp3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Etiqueta(
                              i.tipo,
                              fondo: i.destacado ? TemaModernista.acento : TemaModernista.neutral200,
                              tinta: i.destacado ? Colors.white : TemaModernista.neutral800,
                            ),
                            const SizedBox(width: TemaModernista.esp2),
                            Text('${i.fecha.hour}:${i.fecha.minute.toString().padLeft(2, '0')}',
                                style: TemaModernista.cuerpo(tam: 11, color: TemaModernista.neutral400)),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(i.titulo, style: TemaModernista.cuerpo(tam: 14, peso: FontWeight.w600)),
                        Text(i.lugar, style: TemaModernista.cuerpo(tam: 11, color: TemaModernista.neutral400)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  static String _dow(DateTime d) => const ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'][d.weekday - 1];
}

class _ItemAgenda {
  _ItemAgenda({
    required this.fecha,
    required this.tipo,
    required this.titulo,
    required this.lugar,
    required this.destacado,
    this.onTap,
  });

  final DateTime fecha;
  final String tipo;
  final String titulo;
  final String lugar;
  final bool destacado;
  final VoidCallback? onTap;
}
