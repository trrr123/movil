import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelos/finanzas.dart';
import '../modelos/jugador.dart';
import '../modelos/partido.dart';
import 'escuela_activa.dart';

/// Fuente de datos de la agenda de partidos y sus convocatorias.
abstract class PartidoRepositorio {
  /// [plantel] permite retomar un partido que quedó en curso (su acta guarda
  /// ids de jugadores).
  Future<List<Partido>> cargarPartidos(List<Jugador> plantel);
  Future<void> crear(Partido partido);

  /// Guarda un partido en curso (acta, minuto, quién está en cancha).
  Future<void> guardarEnVivo(Partido partido);

  /// Guarda el estado y el marcador final, y el acta legible (para consulta).
  Future<void> guardarResultado(Partido partido);

  /// Convocatoria guardada de un partido; null si el DT aún no la armó.
  Future<Convocatoria?> cargarConvocatoria(int partidoId);
  Future<void> guardarConvocatoria(Convocatoria convocatoria);
}

class PartidoRepositorioDemo implements PartidoRepositorio {
  @override
  Future<List<Partido>> cargarPartidos(List<Jugador> plantel) async => [
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

  @override
  Future<void> crear(Partido partido) async {}

  @override
  Future<void> guardarEnVivo(Partido partido) async {}

  @override
  Future<void> guardarResultado(Partido partido) async {}

  @override
  Future<Convocatoria?> cargarConvocatoria(int partidoId) async => null;

  @override
  Future<void> guardarConvocatoria(Convocatoria convocatoria) async {}
}

class PartidoRepositorioFirestore implements PartidoRepositorio {
  PartidoRepositorioFirestore(this._escuela);

  final EscuelaActiva _escuela;

  CollectionReference<Map<String, dynamic>> get _partidos => _escuela.coleccion('partidos');

  @override
  Future<List<Partido>> cargarPartidos(List<Jugador> plantel) async {
    final snap = await _partidos.orderBy('fecha').get();
    return snap.docs.map((doc) {
      final d = doc.data();
      final estado = EstadoPartido.values.asNameMap()[d['estado']] ?? EstadoPartido.programado;
      final finalizado = estado == EstadoPartido.finalizado;
      final p = Partido(
        id: d['id'] as int,
        rival: d['rival'] as String,
        fecha: (d['fecha'] as Timestamp).toDate(),
        sede: d['sede'] as String,
        competencia: d['competencia'] as String,
        local: d['local'] as bool? ?? true,
        estado: finalizado ? EstadoPartido.finalizado : EstadoPartido.programado,
        minuto: d['minuto'] as int? ?? 0,
        // El marcador guardado solo se usa en partidos terminados; uno en
        // curso lo recalcula desde su acta al retomarse.
        golesPropiosGuardados: finalizado ? d['golesPropios'] as int? ?? 0 : 0,
        golesRivalGuardados: finalizado ? d['golesRival'] as int? ?? 0 : 0,
      );
      final enVivo = d['enVivo'] as Map<String, dynamic>?;
      if (!finalizado && estado != EstadoPartido.programado && enVivo != null) {
        p.restaurarEnVivo(enVivo, minuto: d['minuto'] as int? ?? 0, plantel: plantel);
      }
      return p;
    }).toList();
  }

  @override
  Future<void> crear(Partido p) => _partidos.doc('${p.id}').set({
        'id': p.id,
        'rival': p.rival,
        'fecha': Timestamp.fromDate(p.fecha),
        'sede': p.sede,
        'competencia': p.competencia,
        'local': p.local,
        'estado': EstadoPartido.programado.name,
      });

  @override
  Future<void> guardarEnVivo(Partido p) => _partidos.doc('${p.id}').update({
        'estado': p.estado.name,
        'minuto': p.minuto,
        'golesPropios': p.golesPropios,
        'golesRival': p.golesRival,
        'enVivo': p.aMapaEnVivo(),
      });

  @override
  Future<void> guardarResultado(Partido p) => _partidos.doc('${p.id}').update({
        'estado': p.estado.name,
        'minuto': p.minuto,
        'golesPropios': p.golesPropios,
        'golesRival': p.golesRival,
        'enVivo': FieldValue.delete(),
        'acta': [
          for (final e in p.eventos.reversed) {'minuto': e.minuto, 'tipo': e.tipo, 'detalle': e.descripcion},
        ],
      });

  @override
  Future<Convocatoria?> cargarConvocatoria(int partidoId) async {
    final d = (await _escuela.coleccion('convocatorias').doc('$partidoId').get()).data();
    if (d == null) return null;
    return Convocatoria(
      partidoId: partidoId,
      llamados: (d['llamados'] as List<dynamic>? ?? const []).cast<int>(),
      enviada: d['enviada'] as bool? ?? false,
    );
  }

  @override
  Future<void> guardarConvocatoria(Convocatoria c) => _escuela.coleccion('convocatorias').doc('${c.partidoId}').set({
        'partidoId': c.partidoId,
        'llamados': c.llamados.toList()..sort(),
        'enviada': c.enviada,
      });
}
