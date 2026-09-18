import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelos/partido.dart';

/// Fuente de datos de la agenda de partidos.
abstract class PartidoRepositorio {
  Future<List<Partido>> cargarPartidos();
}

class PartidoRepositorioDemo implements PartidoRepositorio {
  @override
  Future<List<Partido>> cargarPartidos() async => [
        Partido(
          id: 15,
          rival: 'Dep. Uribia',
          fecha: DateTime(2026, 9, 19, 15, 30),
          sede: 'Cancha La Serranía',
          competencia: 'Liga juvenil',
        ),
        Partido(
          id: 16,
          rival: 'Academia Riohacha',
          fecha: DateTime(2026, 9, 26, 10, 0),
          sede: 'Visitante',
          competencia: 'Liga juvenil',
          local: false,
        ),
      ];
}

class PartidoRepositorioFirestore implements PartidoRepositorio {
  PartidoRepositorioFirestore({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<List<Partido>> cargarPartidos() async {
    final snap = await _db.collection('partidos').orderBy('fecha').get();
    return snap.docs.map((doc) {
      final d = doc.data();
      return Partido(
        id: d['id'] as int,
        rival: d['rival'] as String,
        fecha: (d['fecha'] as Timestamp).toDate(),
        sede: d['sede'] as String,
        competencia: d['competencia'] as String,
        local: d['local'] as bool? ?? true,
      );
    }).toList();
  }
}
