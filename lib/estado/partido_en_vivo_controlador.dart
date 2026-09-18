import 'dart:async';

import 'package:flutter/foundation.dart';

import '../modelos/jugador.dart';
import '../modelos/partido.dart';

/// Reloj y eventos de un partido en curso. Deliberadamente no guarda una
/// referencia propia al partido "actual": opera sobre el [Partido] que le
/// pasa la fachada cada vez, así que no duplica el estado que ya vive en
/// [AgendaControlador].
class PartidoEnVivoControlador extends ChangeNotifier {
  Timer? _reloj;

  void iniciar(Partido partido, Iterable<Jugador> titulares) {
    partido
      ..iniciar()
      ..registrarEnCampo(titulares);
    _reloj?.cancel();
    _reloj = Timer.periodic(const Duration(seconds: 4), (_) {
      partido.avanzarMinuto();
      notifyListeners();
    });
    notifyListeners();
  }

  void alternarReloj(Partido partido) {
    partido.alternarReloj();
    notifyListeners();
  }

  void anotarGol(Partido partido, {required Jugador goleador, Jugador? asistente, bool rival = false}) {
    partido.anotar(Gol(minuto: partido.minuto, autor: goleador, asistente: asistente, rival: rival));
    goleador.registrarPartido(goles: rival ? 0 : 1);
    notifyListeners();
  }

  void anotarTarjeta(Partido partido, Jugador j, {ColorTarjeta color = ColorTarjeta.amarilla}) {
    partido.anotar(Tarjeta(minuto: partido.minuto, jugador: j, color: color));
    notifyListeners();
  }

  void registrarCambio(Partido partido, {required Jugador sale, required Jugador entra}) {
    partido.anotar(Cambio(minuto: partido.minuto, sale: sale, entra: entra));
    notifyListeners();
  }

  void finalizar(Partido partido) {
    _reloj?.cancel();
    partido.finalizar();
    notifyListeners();
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
