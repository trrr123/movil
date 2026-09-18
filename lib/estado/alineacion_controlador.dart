import 'package:flutter/foundation.dart';

import '../datos/alineacion_repositorio.dart';
import '../modelos/alineacion.dart';
import '../modelos/jugador.dart';

/// Estado de la pizarra táctica: formación, posiciones y alineaciones
/// guardadas. No conoce el partido en vivo — cruzar alineación con partido
/// (ej. anotar un cambio) es coordinación de la fachada, no de este control.
class AlineacionControlador extends ChangeNotifier {
  AlineacionControlador(this._repo);

  final AlineacionRepositorio _repo;
  List<Alineacion> _guardadas = const [];
  late Alineacion _activa;

  List<Alineacion> get guardadas => List.unmodifiable(_guardadas);
  Alineacion get activa => _activa;

  Future<void> cargar(List<Jugador> plantel) async {
    _guardadas = await _repo.cargarAlineaciones(plantel);
    _activa = _guardadas.first;
    notifyListeners();
  }

  void aplicarFormacion(Formacion f) {
    _activa.aplicarFormacion(f);
    notifyListeners();
  }

  void moverFicha(int jugadorId, PuntoCampo destino) {
    _activa.moverFicha(jugadorId, destino);
    notifyListeners();
  }

  void sustituir({required int saleId, required Jugador entra}) {
    _activa.sustituir(saleId: saleId, entra: entra);
    notifyListeners();
  }

  void guardar() {
    final copia = _activa.duplicar(
      nuevoId: DateTime.now().millisecondsSinceEpoch,
      nuevoNombre: 'Alineación ${_activa.formacion.nombre}',
    );
    _guardadas = [copia, ..._guardadas];
    notifyListeners();
  }

  void cargarGuardada(Alineacion a) {
    _activa = a;
    notifyListeners();
  }
}
