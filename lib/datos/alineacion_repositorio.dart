import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelos/alineacion.dart';
import '../modelos/jugador.dart';

/// Fuente de datos de las alineaciones guardadas por el cuerpo técnico.
abstract class AlineacionRepositorio {
  Future<List<Alineacion>> cargarAlineaciones(List<Jugador> plantel);
}

class AlineacionRepositorioDemo implements AlineacionRepositorio {
  @override
  Future<List<Alineacion>> cargarAlineaciones(List<Jugador> plantel) async => [
        Alineacion(
          id: 1,
          nombre: 'Presión alta — titular',
          formacion: Formacion.f433,
          once: plantel.take(11).toList(),
          creada: DateTime(2026, 9, 5, 9, 12),
          publicada: true,
        ),
        Alineacion(
          id: 2,
          nombre: 'Bloque bajo vs. Uribia',
          formacion: Formacion.f442,
          once: plantel.take(11).toList(),
          creada: DateTime(2026, 9, 12, 18, 40),
        ),
      ];
}

class AlineacionRepositorioFirestore implements AlineacionRepositorio {
  AlineacionRepositorioFirestore({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<List<Alineacion>> cargarAlineaciones(List<Jugador> plantel) async {
    final snap = await _db.collection('alineaciones').orderBy('creada', descending: true).get();
    final porId = {for (final j in plantel) j.id: j};
    return snap.docs.map((doc) {
      final d = doc.data();
      final formacion = Formacion.presets.firstWhere(
        (f) => f.nombre == d['formacion'],
        orElse: () => Formacion.presets.first,
      );
      final titulares = (d['titulares'] as List<dynamic>? ?? const [])
          .map((t) => porId[(t as Map<String, dynamic>)['jugadorId'] as int])
          .whereType<Jugador>()
          .toList();
      return Alineacion(
        id: d['id'] as int,
        nombre: d['nombre'] as String,
        formacion: formacion,
        once: titulares,
        creada: (d['creada'] as Timestamp).toDate(),
        publicada: d['publicada'] as bool? ?? false,
      );
    }).toList();
  }
}
