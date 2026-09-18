import 'package:flutter/foundation.dart';

import '../datos/partido_repositorio.dart';
import '../datos/sesion_repositorio.dart';
import '../modelos/finanzas.dart';
import '../modelos/jugador.dart';
import '../modelos/partido.dart';

/// Estado de la agenda: partidos, sesiones, convocatoria y asistencia.
class AgendaControlador extends ChangeNotifier {
  AgendaControlador(this._partidoRepo, this._sesionRepo);

  final PartidoRepositorio _partidoRepo;
  final SesionRepositorio _sesionRepo;

  List<Partido> _partidos = const [];
  List<SesionEntrenamiento> _sesiones = const [];
  late Convocatoria _convocatoria;

  List<Partido> get partidos => List.unmodifiable(_partidos);
  Partido get actual => _partidos.first;
  List<SesionEntrenamiento> get sesiones => List.unmodifiable(_sesiones);
  Convocatoria get convocatoria => _convocatoria;

  /// Arma la convocatoria inicial con los primeros disponibles del plantel,
  /// igual que hacía antes `AppEstado._cargarDatosDelClub`.
  Future<void> cargar(List<Jugador> plantel) async {
    _partidos = await _partidoRepo.cargarPartidos();
    _sesiones = await _sesionRepo.cargarSesiones();
    _convocatoria = Convocatoria(partidoId: _partidos.first.id);
    for (final j in plantel.where((j) => j.disponible).take(16)) {
      _convocatoria.alternar(j);
    }
    notifyListeners();
  }

  /// Devuelve false cuando la regla de negocio impide el cambio (tope
  /// reglamentario o jugador lesionado); la fachada decide qué avisar.
  bool alternarConvocado(Jugador j) {
    final ok = _convocatoria.alternar(j);
    if (ok) notifyListeners();
    return ok;
  }

  void enviarConvocatoria() {
    _convocatoria.enviar();
    notifyListeners();
  }

  void marcarAsistencia(SesionEntrenamiento s, Jugador j, bool presente) {
    s.marcar(j.id, presente);
    notifyListeners();
  }
}
