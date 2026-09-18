import 'package:flutter/material.dart';

import '../core/tema_modernista.dart';
import '../estado/app_estado.dart';
import '../modelos/usuario.dart';
import '../widgets/comunes.dart';
import 'convocatoria_pantalla.dart';
import 'en_vivo_pantalla.dart';

/// Inicio: el mismo esqueleto, distinto contenido según permisos.
class InicioPantalla extends StatelessWidget {
  const InicioPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = AlcanceApp.de(context);
    final esDT = estado.puede(Permiso.dirigirPartido);
    final p = estado.partidoActual;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 26),
      children: [
        Text(esDT ? 'MIÉRCOLES 16 · SEPTIEMBRE' : 'TU SEMANA',
            style: TemaModernista.etiqueta(color: TemaModernista.acento)),
        const SizedBox(height: 6),
        Text(esDT ? 'BUENOS DÍAS, PROFE' : 'HOLA, ${estado.usuario!.apellido.toUpperCase()}',
            style: TemaModernista.titulo(30)),
        const SizedBox(height: TemaModernista.esp4),
        const Regla(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: TemaModernista.esp4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Kicker('Próximo partido'),
                  Etiqueta('Fecha ${p.id}', fondo: TemaModernista.acento100, tinta: TemaModernista.acento700),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MAKUIRA', style: TemaModernista.titulo(19)),
                        Text(p.local ? 'LOCAL' : 'VISITANTE',
                            style: TemaModernista.etiqueta(color: TemaModernista.neutral400, tam: 9)),
                      ],
                    ),
                  ),
                  Text('VS', style: TemaModernista.titulo(13).copyWith(color: TemaModernista.acento)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(p.rival.toUpperCase(), style: TemaModernista.titulo(19), textAlign: TextAlign.right),
                        Text(p.local ? 'VISITANTE' : 'LOCAL',
                            style: TemaModernista.etiqueta(color: TemaModernista.neutral400, tam: 9)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TemaModernista.esp3),
              Text('Sáb 19 sep  ·  3:30 pm  ·  ${p.sede}',
                  style: TemaModernista.cuerpo(tam: 12, color: TemaModernista.neutral800)),
              const SizedBox(height: TemaModernista.esp3),
              if (esDT)
                Row(
                  children: [
                    Expanded(
                      child: BotonModernista('Convocatoria',
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ConvocatoriaPantalla()))),
                    ),
                    const SizedBox(width: TemaModernista.esp2),
                    Expanded(
                      child: BotonModernista('En vivo',
                          variante: VarianteBoton.secundario,
                          onTap: () {
                            estado.iniciarPartido();
                            Navigator.of(context)
                                .push(MaterialPageRoute(builder: (_) => const EnVivoPantalla()));
                          }),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const Regla(),
        const SizedBox(height: TemaModernista.esp4),
        if (esDT)
          GrillaCifras(celdas: const [
            CeldaCifra(valor: '28', rotulo: 'Puntos'),
            CeldaCifra(valor: '14', rotulo: 'Jugados'),
            CeldaCifra(valor: '+12', rotulo: 'Diferencia', color: TemaModernista.acento),
          ])
        else
          _CitacionPropia(estado: estado),
        const SizedBox(height: TemaModernista.esp5),
        const Kicker('Esta semana'),
        for (final s in estado.sesiones)
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: TemaModernista.neutral300)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 34,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${s.fecha.day}', style: TemaModernista.titulo(17)),
                      Text('SEP', style: TemaModernista.etiqueta(color: TemaModernista.neutral400, tam: 9)),
                    ],
                  ),
                ),
                Container(width: 2, height: 34, color: TemaModernista.tinta),
                const SizedBox(width: TemaModernista.esp3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.titulo, style: TemaModernista.cuerpo(peso: FontWeight.w600)),
                      Text(s.lugar, style: TemaModernista.cuerpo(tam: 11, color: TemaModernista.neutral400)),
                    ],
                  ),
                ),
                Text('${s.fecha.hour}:00', style: TemaModernista.cuerpo(tam: 11, color: TemaModernista.neutral400)),
              ],
            ),
          ),
        if (esDT) ...[
          const SizedBox(height: TemaModernista.esp4),
          Container(
            decoration: const BoxDecoration(
              border: Border.fromBorderSide(BorderSide(color: TemaModernista.acento, width: 2)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Text('${estado.caja.pendientes}',
                    style: TemaModernista.titulo(26).copyWith(color: TemaModernista.acento)),
                const SizedBox(width: TemaModernista.esp3),
                Expanded(child: Text('cuotas del mes sin pagar', style: TemaModernista.cuerpo(tam: 12))),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Bloque exclusivo del jugador: su citación, nada del resto del plantel.
class _CitacionPropia extends StatelessWidget {
  const _CitacionPropia({required this.estado});
  final AppEstado estado;

  @override
  Widget build(BuildContext context) {
    final convocado = estado.estoyConvocado();
    final titular = estado.soyTitular();
    final f = estado.miFicha!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border.fromBorderSide(BorderSide(color: TemaModernista.acento, width: 2)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Kicker('Tu citación', color: TemaModernista.acento),
              Text(
                convocado ? (titular ? 'CONVOCADO — TITULAR' : 'CONVOCADO — BANCA') : 'NO CONVOCADO',
                style: TemaModernista.titulo(22),
              ),
              const SizedBox(height: 6),
              Text(
                convocado
                    ? 'Presentarse 1:45 pm en la sede. Uniforme rojo.'
                    : 'Esta fecha descansás. Entrenos siguen normales.',
                style: TemaModernista.cuerpo(tam: 12, color: TemaModernista.neutral800),
              ),
            ],
          ),
        ),
        const SizedBox(height: TemaModernista.esp3),
        GrillaCifras(celdas: [
          CeldaCifra(valor: '${f.estadisticas.partidos}', rotulo: 'PJ'),
          CeldaCifra(valor: '${f.estadisticas.goles}', rotulo: 'Goles'),
          CeldaCifra(valor: '${f.estadisticas.asistencias}', rotulo: 'Asist.'),
          CeldaCifra(valor: '${f.estadisticas.minutos}', rotulo: 'Min'),
        ]),
      ],
    );
  }
}
