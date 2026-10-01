import 'package:flutter/material.dart';

import '../core/tema_modernista.dart';
import '../estado/app_estado.dart';
import '../modelos/usuario.dart';
import '../widgets/comunes.dart';
import 'convocatoria_pantalla.dart';
import 'en_vivo_pantalla.dart';

const _diasLargos  = ['LUNES', 'MARTES', 'MIÉRCOLES', 'JUEVES', 'VIERNES', 'SÁBADO', 'DOMINGO'];
const _diasCortos  = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
const _mesesLargos = [
  'ENERO', 'FEBRERO', 'MARZO', 'ABRIL', 'MAYO', 'JUNIO',
  'JULIO', 'AGOSTO', 'SEPTIEMBRE', 'OCTUBRE', 'NOVIEMBRE', 'DICIEMBRE',
];
const _mesesCortos = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

String _encabezadoFecha(DateTime f) =>
    '${_diasLargos[f.weekday - 1]} ${f.day} · ${_mesesLargos[f.month - 1]}';

String _fechaHoraPartido(DateTime f) {
  final hora12  = f.hour % 12 == 0 ? 12 : f.hour % 12;
  final ampm    = f.hour < 12 ? 'am' : 'pm';
  final minuto  = f.minute.toString().padLeft(2, '0');
  return '${_diasCortos[f.weekday - 1]} ${f.day} ${_mesesCortos[f.month - 1]}  ·  $hora12:$minuto $ampm';
}

class InicioPantalla extends StatelessWidget {
  const InicioPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = AlcanceApp.de(context);
    final esDT   = estado.puede(Permiso.dirigirPartido);
    final p      = estado.partidoActual;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
      children: [
        // ── Saludo ─────────────────────────────────────────────────────────
        Text(esDT ? _encabezadoFecha(DateTime.now()) : 'TU SEMANA',
            style: TemaModernista.etiqueta(color: TemaModernista.acento)),
        const SizedBox(height: 6),
        Text(
          esDT
              ? 'BUENOS DÍAS, PROFE'
              : 'HOLA, ${estado.usuario!.apellido.toUpperCase()}',
          style: TemaModernista.titulo(36),
        ),
        const SizedBox(height: TemaModernista.esp4),
        const Regla(),
        const SizedBox(height: TemaModernista.esp4),

        // ── Tarjeta del próximo partido (oscura) ───────────────────────────
        Container(
          color: TemaModernista.fondoOscuro,
          padding: const EdgeInsets.all(TemaModernista.esp4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Kicker('Próximo partido',
                      color: TemaModernista.neutral400),
                  Etiqueta('Fecha ${p.id}',
                      fondo: TemaModernista.acento,
                      tinta: Colors.white),
                ],
              ),
              const SizedBox(height: TemaModernista.esp2),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MAKUIRA',
                            style:
                                TemaModernista.titulo(20, color: Colors.white)),
                        Text(p.local ? 'LOCAL' : 'VISITANTE',
                            style: TemaModernista.etiqueta(
                                color: TemaModernista.neutral400, tam: 9)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: TemaModernista.esp3),
                    child: Text('VS',
                        style: TemaModernista.titulo(14,
                            color: TemaModernista.acento)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(p.rival.toUpperCase(),
                            style:
                                TemaModernista.titulo(20, color: Colors.white),
                            textAlign: TextAlign.right),
                        Text(p.local ? 'VISITANTE' : 'LOCAL',
                            style: TemaModernista.etiqueta(
                                color: TemaModernista.neutral400, tam: 9)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TemaModernista.esp3),
              Text(
                '${_fechaHoraPartido(p.fecha)}  ·  ${p.sede}',
                style: TemaModernista.cuerpo(
                    tam: 12, color: TemaModernista.neutral400),
              ),
            ],
          ),
        ),

        // ── Botones del partido (sobre fondo blanco) ───────────────────────
        if (esDT) ...[
          const SizedBox(height: TemaModernista.esp3),
          Row(
            children: [
              Expanded(
                child: BotonModernista('Convocatoria',
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ConvocatoriaPantalla()))),
              ),
              const SizedBox(width: TemaModernista.esp2),
              Expanded(
                child: BotonModernista('En vivo',
                    variante: VarianteBoton.secundario,
                    onTap: () {
                      estado.iniciarPartido();
                      Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const EnVivoPantalla()));
                    }),
              ),
            ],
          ),
        ],

        const SizedBox(height: TemaModernista.esp5),

        // ── Estadísticas / Citación propia ─────────────────────────────────
        if (esDT)
          GrillaCifras(celdas: const [
            CeldaCifra(valor: '28', rotulo: 'Puntos'),
            CeldaCifra(valor: '14', rotulo: 'Jugados'),
            CeldaCifra(valor: '+12', rotulo: 'Diferencia',
                color: TemaModernista.acento),
          ])
        else
          _CitacionPropia(estado: estado),

        const SizedBox(height: TemaModernista.esp5),

        // ── Esta semana ────────────────────────────────────────────────────
        const Kicker('Esta semana'),
        for (final s in estado.sesiones)
          Container(
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: TemaModernista.neutral300)),
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
                      Text('${s.fecha.day}',
                          style: TemaModernista.titulo(17)),
                      Text(_mesesCortos[s.fecha.month - 1].toUpperCase(),
                          style: TemaModernista.etiqueta(
                              color: TemaModernista.neutral400, tam: 9)),
                    ],
                  ),
                ),
                Container(
                    width: 2, height: 34, color: TemaModernista.acento),
                const SizedBox(width: TemaModernista.esp3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.titulo,
                          style: TemaModernista.cuerpo(
                              peso: FontWeight.w600)),
                      Text(s.lugar,
                          style: TemaModernista.cuerpo(
                              tam: 11,
                              color: TemaModernista.neutral400)),
                    ],
                  ),
                ),
                Text('${s.fecha.hour}:00',
                    style: TemaModernista.cuerpo(
                        tam: 11, color: TemaModernista.neutral400)),
              ],
            ),
          ),

        // ── Cuotas pendientes (solo DT) ────────────────────────────────────
        if (esDT) ...[
          const SizedBox(height: TemaModernista.esp4),
          Container(
            color: TemaModernista.fondoOscuro,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Text('${estado.caja.pendientes}',
                    style: TemaModernista.titulo(28,
                        color: TemaModernista.acento)),
                const SizedBox(width: TemaModernista.esp3),
                Expanded(
                    child: Text('cuotas del mes sin pagar',
                        style: TemaModernista.cuerpo(
                            tam: 12, color: Colors.white))),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Bloque exclusivo del jugador: su citación en tarjeta oscura.
class _CitacionPropia extends StatelessWidget {
  const _CitacionPropia({required this.estado});
  final AppEstado estado;

  @override
  Widget build(BuildContext context) {
    final convocado = estado.estoyConvocado();
    final titular   = estado.soyTitular();
    final f         = estado.miFicha!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: TemaModernista.fondoOscuro,
          padding: const EdgeInsets.all(TemaModernista.esp4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Kicker('Tu citación', color: TemaModernista.neutral400),
              Text(
                convocado
                    ? (titular ? 'CONVOCADO — TITULAR' : 'CONVOCADO — BANCA')
                    : 'NO CONVOCADO',
                style: TemaModernista.titulo(22, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                convocado
                    ? 'Presentarse 1:45 pm en la sede. Uniforme rojo.'
                    : 'Esta fecha descansás. Entrenos siguen normales.',
                style: TemaModernista.cuerpo(
                    tam: 12, color: TemaModernista.neutral400),
              ),
            ],
          ),
        ),
        const SizedBox(height: TemaModernista.esp3),
        GrillaCifras(celdas: [
          CeldaCifra(valor: '${f.estadisticas.partidos}', rotulo: 'PJ'),
          CeldaCifra(valor: '${f.estadisticas.goles}',   rotulo: 'Goles'),
          CeldaCifra(valor: '${f.estadisticas.asistencias}', rotulo: 'Asist.'),
          CeldaCifra(valor: '${f.estadisticas.minutos}', rotulo: 'Min'),
        ]),
      ],
    );
  }
}
