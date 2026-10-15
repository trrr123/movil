import 'dart:async';

import 'package:flutter/foundation.dart';

import '../datos/alineacion_repositorio.dart';
import '../modelos/alineacion.dart';
import '../modelos/jugador.dart';

/// Estado de la pizarra táctica: formación, posiciones y alineaciones
/// guardadas. No conoce el partido en vivo — cruzar alineación con partido
/// (ej. anotar un cambio) es coordinación de la fachada, no de este control.
///
/// La alineación en uso se guarda sola en la base de datos poco después de
/// cada cambio (arrastrar una ficha dispara muchos cambios seguidos: se
/// espera a que pare para escribir una sola vez).
class AlineacionControlador extends ChangeNotifier {
  AlineacionControlador(this._repo);

  final AlineacionRepositorio _repo;
  List<Alineacion> _guardadas = const [];
  late Alineacion _activa;
  Timer? _pendiente;

  /// La fachada lo usa para avisar si un guardado falla.
  void Function(Object error)? alFallarGuardado;

  static const _espera = Duration(milliseconds: 800);

  List<Alineacion> get guardadas => List.unmodifiable(_guardadas);
  Alineacion get activa => _activa;

  /// Hay un cambio esperando a escribirse (ej. justo antes de cerrar sesión).
  bool get guardadoPendiente => _pendiente?.isActive ?? false;

  Future<void> cargar(List<Jugador> plantel) async {
    _pendiente?.cancel();
    _guardadas = await _repo.cargarAlineaciones(plantel);
    // La que quedó en la pizarra la última vez; si no hay, una copia de la
    // última guardada; y si la escuela es nueva, un 4-3-3 con los primeros
    // del plantel (o vacío, si todavía no hay jugadores).
    _activa = await _repo.cargarActual(plantel) ??
        _guardadas.firstOrNull?.duplicar(nuevoId: 0, nuevoNombre: 'Alineación actual') ??
        Alineacion(
          id: 0,
          nombre: 'Alineación actual',
          formacion: Formacion.f433,
          once: plantel.take(11).toList(),
          creada: DateTime.now(),
        );
    notifyListeners();
  }

  void _cambio() {
    notifyListeners();
    _pendiente?.cancel();
    _pendiente = Timer(_espera, guardarAhora);
  }

  /// Escribe ya la alineación en uso (y cancela el guardado programado).
  Future<void> guardarAhora() async {
    _pendiente?.cancel();
    _pendiente = null;
    try {
      await _repo.guardarActual(_activa);
    } catch (e) {
      alFallarGuardado?.call(e);
    }
  }

  void aplicarFormacion(Formacion f) {
    _activa.aplicarFormacion(f);
    _cambio();
  }

  void moverFicha(int jugadorId, PuntoCampo destino) {
    _activa.moverFicha(jugadorId, destino);
    _cambio();
  }

  void sustituir({required int saleId, required Jugador entra}) {
    _activa.sustituir(saleId: saleId, entra: entra);
    _cambio();
  }

  /// Guarda una copia con nombre de la alineación en uso.
  Future<void> guardar() async {
    final copia = _activa.duplicar(
      nuevoId: DateTime.now().millisecondsSinceEpoch,
      nuevoNombre: 'Alineación ${_activa.formacion.nombre}',
    );
    _guardadas = [copia, ..._guardadas];
    notifyListeners();
    await _repo.guardar(copia);
  }

  /// Pone en la pizarra una copia de una guardada (editarla no la modifica).
  void cargarGuardada(Alineacion a) {
    _activa = a.duplicar(nuevoId: 0, nuevoNombre: 'Alineación actual');
    _cambio();
  }

  @override
  void dispose() {
    // Si quedó un cambio sin escribir (ej. se cierra sesión), se escribe ya.
    if (_pendiente?.isActive ?? false) guardarAhora();
    _pendiente?.cancel();
    super.dispose();
  }
}
