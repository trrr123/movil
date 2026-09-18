import 'package:flutter/foundation.dart';

import '../datos/caja_repositorio.dart';
import '../modelos/finanzas.dart';
import '../modelos/jugador.dart';

/// Estado de la caja del club (cuotas mensuales). El filtro de "el jugador
/// solo ve la suya" es responsabilidad de la fachada, que sabe quién está
/// mirando; este control solo conoce la caja completa.
class FinanzasControlador extends ChangeNotifier {
  FinanzasControlador(this._repo);

  final CajaRepositorio _repo;
  late CajaMensual _caja;

  CajaMensual get caja => _caja;

  Future<void> cargar(List<Jugador> plantel) async {
    _caja = await _repo.cargarCaja(plantel);
    notifyListeners();
  }

  void confirmarPago(Cuota c) {
    c.confirmarPago();
    notifyListeners();
  }

  void reportarPago(Cuota c) {
    c.reportarPago();
    notifyListeners();
  }
}
