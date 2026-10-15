import 'dart:async';

import 'package:flutter/foundation.dart';

import '../modelos/jugador.dart';
import '../modelos/partido.dart';

/// Reloj y eventos de un partido en curso. Deliberadamente no guarda una
/// referencia propia al partido "actual": opera sobre el [Partido] que le
/// pasa la fachada cada vez, así que no duplica el estado que ya vive en
/// [AgendaControlador].
///
/// Cada cambio (jugada, pausa, minuto que pasa) se avisa por [alCambiar]
/// para que la fachada lo guarde: si la app se cierra, el partido se retoma.
class PartidoEnVivoControlador extends ChangeNotifier {
  Timer? _reloj;

  void Function(Partido partido)? alCambiar;

  void _cambio(Partido partido) {
    notifyListeners();
    alCambiar?.call(partido);
  }

  /// Reloj real: un minuto de partido por minuto; no avanza en la pausa.
  void _asegurarReloj(Partido partido) {
    if (_reloj?.isActive ?? false) return;
    _reloj = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!partido.enJuego) return;
      partido.avanzarMinuto();
      _cambio(partido);
    });
  }

  void iniciar(Partido partido, Iterable<Jugador> titulares) {
    partido
      ..iniciar()
      ..registrarEnCampo(titulares);
    _reloj?.cancel();
    _asegurarReloj(partido);
    _cambio(partido);
  }

  void alternarReloj(Partido partido) {
    partido.alternarReloj();
    // Un partido retomado tras cerrar la app vuelve sin reloj: se crea aquí.
    if (partido.enJuego) _asegurarReloj(partido);
    _cambio(partido);
  }

  void corregirMinuto(Partido partido, int delta) {
    partido.corregirMinuto(delta);
    _cambio(partido);
  }

  /// Las estadísticas (goles, asistencias…) se suman al finalizar, desde el
  /// acta; aquí solo se anota la jugada.
  void anotarGol(Partido partido, {Jugador? goleador, Jugador? asistente, bool rival = false}) {
    partido.anotar(rival
        ? Gol.rival(minuto: partido.minuto)
        : Gol(minuto: partido.minuto, autor: goleador, asistente: asistente));
    _cambio(partido);
  }

  void anotarTarjeta(Partido partido, Jugador j, {ColorTarjeta color = ColorTarjeta.amarilla}) {
    partido.anotar(Tarjeta(minuto: partido.minuto, jugador: j, color: color));
    _cambio(partido);
  }

  void registrarCambio(Partido partido, {required Jugador sale, required Jugador entra}) {
    partido.anotar(Cambio(minuto: partido.minuto, sale: sale, entra: entra));
    _cambio(partido);
  }

  /// Devuelve los jugadores cuyas estadísticas cambiaron (para guardarlas).
  Set<Jugador> finalizar(Partido partido) {
    _reloj?.cancel();
    final tocados = partido.finalizar();
    notifyListeners();
    return tocados;
  }

  /// Corta el reloj sin tocar el estado del partido — se usa al cerrar
  /// sesión en medio de un partido en vivo.
  void detenerReloj() => _reloj?.cancel();

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }
}
