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
  Convocatoria? _convocatoria;

  List<Partido> get partidos => List.unmodifiable(_partidos);

  /// Próximo partido sin terminar (el que está en curso, o el primero por
  /// fecha que no se finalizó); null si no hay ninguno.
  Partido? get actual =>
      _partidos.where((p) => p.enProgreso).firstOrNull ?? _partidos.where((p) => !p.finalizado).firstOrNull;
  List<SesionEntrenamiento> get sesiones => List.unmodifiable(_sesiones);

  /// Convocatoria del próximo partido (null si no hay partido).
  Convocatoria? get convocatoria => _convocatoria;

  Future<void> cargar(List<Jugador> plantel) async {
    _partidos = await _partidoRepo.cargarPartidos(plantel);
    _sesiones = await _sesionRepo.cargarSesiones();
    _convocatoria = null;
    await _armarConvocatoria(plantel);
    notifyListeners();
  }

  /// La convocatoria guardada del próximo partido; si el DT aún no la armó,
  /// una propuesta (sin enviar) con los primeros 16 disponibles.
  Future<void> _armarConvocatoria(List<Jugador> plantel) async {
    final proximo = actual;
    if (proximo == null) {
      _convocatoria = null;
      return;
    }
    if (_convocatoria?.partidoId == proximo.id) return;
    _convocatoria = await _partidoRepo.cargarConvocatoria(proximo.id) ??
        Convocatoria(
          partidoId: proximo.id,
          llamados: plantel.where((j) => j.disponible).take(16).map((j) => j.id),
        );
  }

  int get siguienteIdPartido => _partidos.fold(0, (m, p) => p.id > m ? p.id : m) + 1;
  int get siguienteIdSesion => _sesiones.fold(0, (m, s) => s.id > m ? s.id : m) + 1;

  Future<void> programarPartido(Partido p, List<Jugador> plantel) async {
    await _partidoRepo.crear(p);
    _partidos = [..._partidos, p]..sort((a, b) => a.fecha.compareTo(b.fecha));
    await _armarConvocatoria(plantel);
    notifyListeners();
  }

  Future<void> programarSesion(SesionEntrenamiento s) async {
    await _sesionRepo.crear(s);
    _sesiones = [..._sesiones, s]..sort((a, b) => a.fecha.compareTo(b.fecha));
    notifyListeners();
  }

  Future<void> guardarEnVivo(Partido p) => _partidoRepo.guardarEnVivo(p);

  /// Tras finalizar un partido: guarda el resultado y pasa la convocatoria
  /// al siguiente partido de la agenda.
  Future<void> cerrarPartido(Partido p, List<Jugador> plantel) async {
    final guardado = _partidoRepo.guardarResultado(p);
    await _armarConvocatoria(plantel);
    notifyListeners();
    await guardado;
  }

  /// Cambia a un jugador en la convocatoria y la guarda. Devuelve false
  /// (sin guardar nada) cuando la regla de negocio lo impide (tope
  /// reglamentario o jugador lesionado); la fachada decide qué avisar.
  bool alternarConvocado(Jugador j, {required void Function(Future<void>) guardar}) {
    final c = _convocatoria;
    if (c == null || !c.alternar(j)) return false;
    notifyListeners();
    guardar(_partidoRepo.guardarConvocatoria(c));
    return true;
  }

  Future<void> enviarConvocatoria() async {
    final c = _convocatoria;
    if (c == null) return;
    c.enviar();
    notifyListeners();
    await _partidoRepo.guardarConvocatoria(c);
  }

  Future<void> marcarAsistencia(SesionEntrenamiento s, Jugador j, bool presente) async {
    s.marcar(j.id, presente);
    notifyListeners();
    await _sesionRepo.guardarAsistencia(s);
  }
}
