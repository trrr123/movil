import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelos/partido.dart';
import 'escuela_activa.dart';

/// Fuente de datos de entrenamientos y charlas (comparten la agenda con los
/// partidos, pero se guardan y persisten aparte).
abstract class SesionRepositorio {
  Future<List<SesionEntrenamiento>> cargarSesiones();
  Future<void> crear(SesionEntrenamiento sesion);

  /// Guarda la planilla completa de asistencia de la sesión.
  Future<void> guardarAsistencia(SesionEntrenamiento sesion);
}

class SesionRepositorioDemo implements SesionRepositorio {
  @override
  Future<void> crear(SesionEntrenamiento sesion) async {}

  @override
  Future<void> guardarAsistencia(SesionEntrenamiento sesion) async {}

  @override
  Future<List<SesionEntrenamiento>> cargarSesiones() async => [
        SesionEntrenamiento(
            id: 1, titulo: 'Fuerza y transiciones', fecha: DateTime(2026, 9, 17, 16), lugar: 'Sede · cancha 2'),
        SesionEntrenamiento(
            id: 2,
            titulo: 'Charla táctica rival',
            fecha: DateTime(2026, 9, 18, 18),
            lugar: 'Salón sede',
            tipo: TipoSesion.video),
        SesionEntrenamiento(
            id: 3,
            titulo: 'Recuperación + balón parado',
            fecha: DateTime(2026, 9, 22, 16),
            lugar: 'Sede · cancha 1'),
      ];
}

class SesionRepositorioFirestore implements SesionRepositorio {
  SesionRepositorioFirestore(this._escuela);

  final EscuelaActiva _escuela;

  @override
  Future<List<SesionEntrenamiento>> cargarSesiones() async {
    final snap = await _escuela.coleccion('sesiones').orderBy('fecha').get();
    return snap.docs.map((doc) {
      final d = doc.data();
      final sesion = SesionEntrenamiento(
        id: d['id'] as int,
        titulo: d['titulo'] as String,
        fecha: (d['fecha'] as Timestamp).toDate(),
        lugar: d['lugar'] as String,
        tipo: TipoSesion.values.byName(d['tipo'] as String? ?? 'entrenamiento'),
      );
      final asistencia = (d['asistencia'] as Map<String, dynamic>?) ?? const {};
      for (final e in asistencia.entries) {
        sesion.marcar(int.parse(e.key), e.value as bool);
      }
      return sesion;
    }).toList();
  }

  @override
  Future<void> crear(SesionEntrenamiento s) => _escuela.coleccion('sesiones').doc('${s.id}').set({
        'id': s.id,
        'titulo': s.titulo,
        'fecha': Timestamp.fromDate(s.fecha),
        'lugar': s.lugar,
        'tipo': s.tipo.name,
        'asistencia': <String, bool>{},
      });

  @override
  Future<void> guardarAsistencia(SesionEntrenamiento s) => _escuela.coleccion('sesiones').doc('${s.id}').update({
        'asistencia': {for (final e in s.asistencia.entries) '${e.key}': e.value},
      });
}
