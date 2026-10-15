import 'package:flutter/material.dart';

import '../core/tema_modernista.dart';
import '../estado/app_estado.dart';
import '../modelos/jugador.dart';
import '../modelos/partido.dart';
import '../modelos/usuario.dart';
import '../widgets/comunes.dart';

/// Partido en vivo (o su acta, si ya terminó). El DT tiene la consola: gol
/// con goleador y asistente, cambio, tarjeta, reloj y finalizar. Los demás
/// ven la misma pantalla en modo lectura.
class EnVivoPantalla extends StatelessWidget {
  const EnVivoPantalla({super.key, required this.partido});
  final Partido partido;

  @override
  Widget build(BuildContext context) {
    final estado = AlcanceApp.de(context);
    final p = partido;
    final dirige = estado.puede(Permiso.dirigirPartido) && !p.finalizado;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Tablero(partido: p, nombreClub: estado.nombreClub, volver: () => Navigator.pop(context)),
            if (dirige && p.programado)
              Padding(
                padding: const EdgeInsets.all(TemaModernista.esp4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      estado.puedeJugarPartido
                          ? 'Cuando el árbitro pite, inicia el reloj. Los titulares son los 11 de la pizarra.'
                          : 'Arma los 11 titulares en la pestaña Táctica antes de iniciar.',
                      style: TemaModernista.cuerpo(tam: 12, color: TemaModernista.neutral800),
                    ),
                    const SizedBox(height: TemaModernista.esp3),
                    BotonModernista('Iniciar partido',
                        onTap: estado.puedeJugarPartido ? () => estado.iniciarPartido(p) : null),
                  ],
                ),
              )
            else if (dirige)
              Container(
                color: TemaModernista.neutral300,
                child: Row(
                  children: [
                    _accion('Gol', () => _hojaGol(context, estado)),
                    const SizedBox(width: 1),
                    _accion('Cambio', () => _hojaCambio(context, estado)),
                    const SizedBox(width: 1),
                    _accion('Tarjeta', () => _hojaTarjeta(context, estado)),
                    const SizedBox(width: 1),
                    _accion(p.enJuego ? 'Pausa' : 'Seguir', () => estado.alternarReloj(p)),
                  ],
                ),
              ),
            if (dirige && p.enProgreso)
              Container(
                color: TemaModernista.neutral200,
                padding: const EdgeInsets.symmetric(horizontal: TemaModernista.esp4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        p.enJuego ? 'Corregir minuto' : 'En pausa · toca “Seguir” para reanudar el reloj',
                        style: TemaModernista.cuerpo(tam: 11, color: TemaModernista.neutral800),
                      ),
                    ),
                    TextButton(onPressed: () => estado.corregirMinuto(p, -1), child: const Text("−1'")),
                    TextButton(onPressed: () => estado.corregirMinuto(p, 1), child: const Text("+1'")),
                  ],
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
                children: [
                  const Kicker('Minuto a minuto'),
                  const Regla(),
                  if (p.eventos.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: TemaModernista.esp4),
                      child: Text(
                        p.finalizado
                            ? 'Partido finalizado. Marcador final: ${p.marcador}.'
                            : 'Aún no hay jugadas registradas.',
                        style: TemaModernista.cuerpo(tam: 12, color: TemaModernista.neutral800),
                      ),
                    ),
                  for (final e in p.eventos)
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: TemaModernista.neutral300)),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 34,
                            child: Text("${e.minuto}'",
                                style: TemaModernista.titulo(14).copyWith(color: TemaModernista.acento)),
                          ),
                          Etiqueta(
                            e.tipo,
                            fondo: e.esDestacado ? TemaModernista.acento : TemaModernista.neutral200,
                            tinta: e.esDestacado ? Colors.white : TemaModernista.neutral800,
                          ),
                          const SizedBox(width: TemaModernista.esp3),
                          Expanded(child: Text(e.descripcion, style: TemaModernista.cuerpo())),
                        ],
                      ),
                    ),
                  if (estado.puede(Permiso.dirigirPartido) && !p.programado) ...[
                    const SizedBox(height: TemaModernista.esp4),
                    Row(
                      children: [
                        Expanded(
                          child: BotonModernista('Descargar acta',
                              variante: VarianteBoton.secundario,
                              onTap: () => estado.descargar(p, estado.formatosActa.first)),
                        ),
                        if (dirige) ...[
                          const SizedBox(width: TemaModernista.esp2),
                          Expanded(child: BotonModernista('Finalizar', onTap: () => _confirmarFinal(context, estado))),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accion(String texto, VoidCallback onTap) => Expanded(
        child: InkWell(
          onTap: onTap,
          child: Container(
            color: TemaModernista.fondo,
            padding: const EdgeInsets.symmetric(vertical: 14),
            alignment: Alignment.center,
            child: Text(texto.toUpperCase(), style: TemaModernista.etiqueta(tam: 11)),
          ),
        ),
      );

  Future<void> _confirmarFinal(BuildContext context, AppEstado estado) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text('FINALIZAR PARTIDO', style: TemaModernista.titulo(18)),
        content: Text('Marcador ${partido.marcador}. Se guardan los minutos, goles, asistencias y tarjetas '
            'de cada jugador. No se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogo, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(dialogo, true), child: const Text('Finalizar')),
        ],
      ),
    );
    if (ok == true) estado.finalizarPartido(partido);
  }

  /// Hoja para elegir un jugador de una lista. [opcionNula] agrega una fila
  /// extra ("Sin asistencia", "Gol del rival") que devuelve [_ninguno].
  Future<Jugador?> _elegir(BuildContext context, String titulo, List<Jugador> jugadores, {String? opcionNula}) =>
      showModalBottomSheet<Jugador?>(
        context: context,
        isScrollControlled: true,
        backgroundColor: TemaModernista.fondo,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        builder: (hoja) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(hoja).height * 0.75),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(padding: const EdgeInsets.all(16), child: Text(titulo, style: TemaModernista.titulo(20))),
                const Regla(),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      if (opcionNula != null)
                        ListTile(
                          title: Text(opcionNula, style: TemaModernista.cuerpo(peso: FontWeight.w600)),
                          onTap: () => Navigator.pop(hoja, _ninguno),
                        ),
                      for (final j in jugadores)
                        ListTile(
                          leading: Text('${j.dorsal}', style: TemaModernista.titulo(16)),
                          title: Text(j.nombre, style: TemaModernista.cuerpo()),
                          onTap: () => Navigator.pop(hoja, j),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  /// Marcador interno de [_elegir] para la opción sin jugador.
  static final _ninguno = Jugador(
      id: -1, dorsal: 0, nombre: '', posicion: Posicion.delantero, detallePosicion: '', edad: 0, pieHabil: '');

  Future<void> _hojaGol(BuildContext context, AppEstado estado) async {
    final autor = await _elegir(context, "Gol al minuto ${partido.minuto}'", estado.enCancha,
        opcionNula: 'Gol del rival (${partido.rival})');
    if (autor == null || !context.mounted) return;
    if (identical(autor, _ninguno)) {
      estado.anotarGol(partido, rival: true);
      return;
    }
    final asistente = await _elegir(
        context, '¿Quién dio la asistencia?', estado.enCancha.where((j) => j.id != autor.id).toList(),
        opcionNula: 'Sin asistencia');
    if (asistente == null) return; // cerró la hoja: no se anota nada
    estado.anotarGol(partido, autor: autor, asistente: identical(asistente, _ninguno) ? null : asistente);
  }

  Future<void> _hojaTarjeta(BuildContext context, AppEstado estado) async {
    final j = await _elegir(context, 'Tarjeta para…', estado.enCancha);
    if (j == null || !context.mounted) return;
    final color = await showModalBottomSheet<ColorTarjeta>(
      context: context,
      backgroundColor: TemaModernista.fondo,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (hoja) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(width: 16, height: 22, color: const Color(0xFFF5C518)),
              title: Text('Amarilla a ${j.nombre}', style: TemaModernista.cuerpo()),
              onTap: () => Navigator.pop(hoja, ColorTarjeta.amarilla),
            ),
            ListTile(
              leading: Container(width: 16, height: 22, color: TemaModernista.acento),
              title: Text('Roja a ${j.nombre}', style: TemaModernista.cuerpo()),
              onTap: () => Navigator.pop(hoja, ColorTarjeta.roja),
            ),
          ],
        ),
      ),
    );
    if (color != null) estado.anotarTarjeta(partido, j, color: color);
  }

  Future<void> _hojaCambio(BuildContext context, AppEstado estado) async {
    final entra = await _elegir(context, 'Entra…', estado.banca.where((j) => j.disponible).toList());
    if (entra == null || !context.mounted) return;
    final sale = await _elegir(context, 'Sale… (entra ${entra.apellido})', estado.enCancha);
    if (sale == null) return;
    estado.sustituir(saleId: sale.id, entra: entra);
  }
}

class _Tablero extends StatelessWidget {
  const _Tablero({required this.partido, required this.nombreClub, required this.volver});
  final Partido partido;
  final String nombreClub;
  final VoidCallback volver;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: partido.programado ? TemaModernista.fondoOscuro : TemaModernista.acento,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InkWell(onTap: volver, child: const Icon(Icons.arrow_back, color: Colors.white, size: 20)),
                const SizedBox(width: TemaModernista.esp3),
                Container(width: 8, height: 8, color: Colors.white),
                const SizedBox(width: TemaModernista.esp2),
                Text(
                  switch (partido.estado) {
                    EstadoPartido.finalizado => 'FINALIZADO',
                    EstadoPartido.programado => 'POR JUGAR',
                    EstadoPartido.entretiempo => 'PAUSA',
                    EstadoPartido.enCurso => 'EN VIVO',
                  },
                  style: TemaModernista.etiqueta(color: Colors.white, tam: 10),
                ),
                const Spacer(),
                Text("${partido.minuto}'", style: TemaModernista.titulo(15).copyWith(color: Colors.white)),
              ],
            ),
            const SizedBox(height: TemaModernista.esp3),
            Row(
              children: [
                Expanded(
                  child: Text(nombreClub.toUpperCase(),
                      style: TemaModernista.titulo(17).copyWith(color: Colors.white)),
                ),
                Text(partido.marcador, style: TemaModernista.titulo(42).copyWith(color: Colors.white)),
                Expanded(
                  child: Text(partido.rival.toUpperCase(),
                      textAlign: TextAlign.right,
                      style: TemaModernista.titulo(17).copyWith(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      );
}
