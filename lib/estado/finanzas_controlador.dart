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

  Future<void> confirmarPago(Cuota c) async {
    c.confirmarPago();
    notifyListeners();
    await _repo.guardarEstado(_caja.id, c);
  }

  Future<void> reportarPago(Cuota c) async {
    c.reportarPago();
    notifyListeners();
    await _repo.guardarEstado(_caja.id, c);
  }

  /// Cobro del mes [mes] para [jugadores] (los que aún no tienen cuota).
  Future<void> crearCuotas(MesCobro mes,
      {required int monto, required List<Jugador> jugadores, required List<Jugador> plantel}) async {
    await _repo.crearCuotas(mes, monto: monto, jugadores: jugadores);
    await cargar(plantel);
  }
}
