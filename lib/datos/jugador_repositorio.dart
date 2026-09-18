import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelos/jugador.dart';

/// Fuente de datos del plantel. Separado del resto de entidades del club
/// para que agregar persistencia o cambiar el mapeo de un jugador no
/// obligue a tocar partidos, sesiones, caja o alineaciones.
abstract class JugadorRepositorio {
  Future<List<Jugador>> cargarPlantel();
}

class JugadorRepositorioDemo implements JugadorRepositorio {
  @override
  Future<List<Jugador>> cargarPlantel() async => [
        _j(1, 1, 'A. Barrios', Posicion.portero, 'Portero', 19, 'Derecho', 1260, 0, 0),
        _j(2, 3, 'J. Mendoza', Posicion.defensa, 'Lateral izq.', 18, 'Izquierdo', 1104, 1, 3),
        _j(3, 4, 'S. Cotes', Posicion.defensa, 'Central', 19, 'Derecho', 1190, 2, 0),
        _j(4, 2, 'K. Epieyú', Posicion.defensa, 'Central', 18, 'Derecho', 980, 1, 1),
        _j(5, 13, 'D. Solano', Posicion.defensa, 'Lateral der.', 17, 'Derecho', 845, 0, 4),
        _j(6, 6, 'M. Brito', Posicion.mediocampo, 'Volante mixto', 19, 'Derecho', 1210, 1, 2),
        _j(7, 8, 'R. Daza', Posicion.mediocampo, 'Volante central', 18, 'Izquierdo', 1015, 3, 5),
        _j(8, 10, 'L. Zúñiga', Posicion.mediocampo, 'Enganche', 19, 'Izquierdo', 986, 7, 4,
            atributos: const {'Ritmo': 69, 'Definición': 64, 'Pase': 88, 'Regate': 91, 'Defensa': 52, 'Físico': 61}),
        _j(9, 11, 'E. Redondo', Posicion.delantero, 'Extremo izq.', 17, 'Derecho', 720, 5, 3),
        _j(10, 9, 'Y. Pushaina', Posicion.delantero, 'Delantero', 18, 'Derecho', 1120, 11, 2),
        _j(11, 7, 'C. Uriana', Posicion.delantero, 'Extremo der.', 17, 'Izquierdo', 690, 4, 6),
        _j(12, 12, 'H. Pimienta', Posicion.portero, 'Portero', 17, 'Derecho', 180, 0, 0),
        _j(13, 5, 'N. Iguarán', Posicion.defensa, 'Central', 18, 'Derecho', 610, 0, 0,
            estado: EstadoFisico.lesionado),
        _j(14, 14, 'B. Ramírez', Posicion.mediocampo, 'Volante central', 17, 'Derecho', 540, 1, 1),
        _j(15, 15, 'T. Gámez', Posicion.defensa, 'Central', 19, 'Izquierdo', 470, 0, 0),
        _j(16, 16, 'W. Curvelo', Posicion.mediocampo, 'Volante izq.', 18, 'Izquierdo', 430, 2, 2,
            estado: EstadoFisico.cargaAlta),
        _j(17, 17, 'F. Ipuana', Posicion.delantero, 'Delantero', 17, 'Derecho', 380, 3, 0),
        _j(18, 18, 'G. Fonseca', Posicion.defensa, 'Lateral der.', 17, 'Derecho', 295, 0, 1),
        _j(19, 19, 'P. Villazón', Posicion.delantero, 'Extremo der.', 16, 'Derecho', 210, 1, 1,
            estado: EstadoFisico.cargaAlta),
        _j(20, 20, 'O. Deluque', Posicion.mediocampo, 'Volante def.', 18, 'Derecho', 640, 0, 2,
            estado: EstadoFisico.lesionado),
      ];

  static Jugador _j(
    int id,
    int dorsal,
    String nombre,
    Posicion pos,
    String detalle,
    int edad,
    String pie,
    int minutos,
    int goles,
    int asis, {
    EstadoFisico estado = EstadoFisico.apto,
    Map<String, int> atributos = const {},
  }) =>
      Jugador(
        id: id,
        dorsal: dorsal,
        nombre: nombre,
        posicion: pos,
        detallePosicion: detalle,
        edad: edad,
        pieHabil: pie,
        estado: estado,
        atributos: atributos,
        estadisticas: Estadisticas(
          partidos: (minutos / 78).round(),
          minutos: minutos,
          goles: goles,
          asistencias: asis,
        ),
      );
}

/// Lee el plantel real de Firestore (colección `jugadores`, la que escribe
/// `tool/seed_firestore.mjs`).
class JugadorRepositorioFirestore implements JugadorRepositorio {
  JugadorRepositorioFirestore({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<List<Jugador>> cargarPlantel() async {
    final snap = await _db.collection('jugadores').orderBy('id').get();
    return snap.docs.map(_jugadorDesde).toList();
  }

  Jugador _jugadorDesde(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final est = (d['estadisticas'] as Map<String, dynamic>?) ?? const {};
    final atributos = (d['atributos'] as Map<String, dynamic>?) ?? const {};
    return Jugador(
      id: d['id'] as int,
      dorsal: d['dorsal'] as int,
      nombre: d['nombre'] as String,
      posicion: Posicion.values.byName(d['posicion'] as String),
      detallePosicion: d['detallePosicion'] as String,
      edad: d['edad'] as int,
      pieHabil: d['pieHabil'] as String,
      estado: EstadoFisico.values.byName(d['estado'] as String? ?? 'apto'),
      atributos: atributos.map((k, v) => MapEntry(k, v as int)),
      estadisticas: Estadisticas(
        partidos: est['partidos'] as int? ?? 0,
        minutos: est['minutos'] as int? ?? 0,
        goles: est['goles'] as int? ?? 0,
        asistencias: est['asistencias'] as int? ?? 0,
        amarillas: est['amarillas'] as int? ?? 0,
      ),
    );
  }
}
