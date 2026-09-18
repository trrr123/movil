import 'package:flutter/foundation.dart';

import '../datos/jugador_repositorio.dart';
import '../modelos/jugador.dart';

/// Estado del plantel: lista y búsqueda. No sabe nada de permisos ni de
/// quién está viendo la app — eso lo decide la fachada ([AppEstado]).
class PlantelControlador extends ChangeNotifier {
  PlantelControlador(this._repo);

  final JugadorRepositorio _repo;
  List<Jugador> _plantel = const [];

  List<Jugador> get plantel => List.unmodifiable(_plantel);
  int get lesionados => _plantel.where((j) => !j.disponible).length;

  Future<void> cargar() async {
    _plantel = await _repo.cargarPlantel();
    notifyListeners();
  }

  List<Jugador> buscar(String texto, Posicion? filtro) => _plantel.where((j) {
        final q = texto.trim().toLowerCase();
        final coincide = q.isEmpty || j.nombre.toLowerCase().contains(q) || j.dorsal.toString() == q;
        return coincide && (filtro == null || j.posicion == filtro);
      }).toList();
}
