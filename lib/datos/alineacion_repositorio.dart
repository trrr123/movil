import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelos/alineacion.dart';
import '../modelos/jugador.dart';
import 'escuela_activa.dart';

/// Fuente de datos de las alineaciones del cuerpo técnico: la que está en
/// la pizarra ahora ("actual", la que ven los jugadores) y las guardadas.
abstract class AlineacionRepositorio {
  /// Alineaciones guardadas con nombre, de la más nueva a la más vieja.
  Future<List<Alineacion>> cargarAlineaciones(List<Jugador> plantel);

  /// La alineación en uso; null si el DT todavía no tocó la pizarra.
  Future<Alineacion?> cargarActual(List<Jugador> plantel);
  Future<void> guardarActual(Alineacion alineacion);
  Future<void> guardar(Alineacion alineacion);
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

  @override
  Future<Alineacion?> cargarActual(List<Jugador> plantel) async => null;

  @override
  Future<void> guardarActual(Alineacion alineacion) async {}

  @override
  Future<void> guardar(Alineacion alineacion) async {}
}

class AlineacionRepositorioFirestore implements AlineacionRepositorio {
  AlineacionRepositorioFirestore(this._escuela);

  final EscuelaActiva _escuela;

  /// Documento fijo de la alineación en uso; las guardadas usan su id numérico.
  static const _actual = 'actual';

  CollectionReference<Map<String, dynamic>> get _coleccion => _escuela.coleccion('alineaciones');

  @override
  Future<List<Alineacion>> cargarAlineaciones(List<Jugador> plantel) async {
    final snap = await _coleccion.orderBy('creada', descending: true).get();
    return snap.docs.where((d) => d.id != _actual).map((d) => _desde(d.data(), plantel)).toList();
  }

  @override
  Future<Alineacion?> cargarActual(List<Jugador> plantel) async {
    final d = (await _coleccion.doc(_actual).get()).data();
    return d == null ? null : _desde(d, plantel);
  }

  @override
  Future<void> guardarActual(Alineacion a) => _coleccion.doc(_actual).set(_datos(a));

  @override
  Future<void> guardar(Alineacion a) => _coleccion.doc('${a.id}').set(_datos(a));

  Map<String, Object> _datos(Alineacion a) => {
        'id': a.id,
        'nombre': a.nombre,
        'formacion': a.formacion.nombre,
        'creada': Timestamp.fromDate(a.creada),
        'publicada': a.publicada,
        'titulares': [
          for (final f in a.fichas) {'jugadorId': f.jugador.id, 'x': f.punto.x, 'y': f.punto.y},
        ],
      };

  /// Los titulares que ya no están en el plantel se omiten (se fueron).
  Alineacion _desde(Map<String, dynamic> d, List<Jugador> plantel) {
    final porId = {for (final j in plantel) j.id: j};
    final formacion = Formacion.presets.firstWhere(
      (f) => f.nombre == d['formacion'],
      orElse: () => Formacion.presets.first,
    );
    final once = <Jugador>[];
    final puntos = <PuntoCampo>[];
    for (final t in (d['titulares'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>()) {
      final j = porId[t['jugadorId'] as int];
      if (j == null) continue;
      once.add(j);
      final x = (t['x'] as num?)?.toDouble();
      final y = (t['y'] as num?)?.toDouble();
      puntos.add(x != null && y != null ? PuntoCampo(x, y) : formacion.puntos[puntos.length]);
    }
    return Alineacion(
      id: d['id'] as int? ?? 0,
      nombre: d['nombre'] as String? ?? 'Alineación',
      formacion: formacion,
      once: once,
      puntos: puntos,
      creada: (d['creada'] as Timestamp?)?.toDate() ?? DateTime.now(),
      publicada: d['publicada'] as bool? ?? false,
    );
  }
}
