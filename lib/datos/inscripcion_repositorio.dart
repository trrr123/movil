import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelos/escuela.dart';
import '../modelos/jugador.dart';

/// Datos que el DT completa al aceptar una inscripción con ficha nueva.
class FichaNueva {
  const FichaNueva({
    required this.id,
    required this.dorsal,
    required this.posicion,
    required this.detallePosicion,
    required this.pieHabil,
  });

  final int id;
  final int dorsal;
  final Posicion posicion;
  final String detallePosicion;
  final String pieHabil;
}

/// Pedidos de cupo de familias a escuelas. Al aprobarse quedan enlazados a una
/// ficha del plantel, y el solicitante pasa a ser miembro de la escuela
/// (`escuelas/{id}/miembros/{uid}`), que es lo que le da lectura a sus datos.
abstract class InscripcionRepositorio {
  Future<void> solicitar(Inscripcion inscripcion);
  Future<List<Inscripcion>> deSolicitante(String uid);
  Future<List<Inscripcion>> pendientesDeEscuela(String escuelaId);

  /// Acepta con ficha nueva ([nueva]) o enlazando una existente ([existente]).
  /// Devuelve el id de la ficha enlazada.
  Future<int> aprobar(Inscripcion inscripcion, {FichaNueva? nueva, Jugador? existente});
  Future<void> rechazar(Inscripcion inscripcion);
}

class InscripcionRepositorioDemo implements InscripcionRepositorio {
  final Map<String, Inscripcion> _todas = {};

  @override
  Future<void> solicitar(Inscripcion i) async => _todas[i.id] = i;

  @override
  Future<List<Inscripcion>> deSolicitante(String uid) async =>
      _todas.values.where((i) => i.solicitanteUid == uid).toList();

  @override
  Future<List<Inscripcion>> pendientesDeEscuela(String escuelaId) async => _todas.values
      .where((i) => i.escuelaId == escuelaId && i.estado == EstadoInscripcion.pendiente)
      .toList();

  @override
  Future<int> aprobar(Inscripcion i, {FichaNueva? nueva, Jugador? existente}) async {
    final jugadorId = existente?.id ?? nueva!.id;
    _todas[i.id] = _con(i, EstadoInscripcion.aprobada, jugadorId);
    return jugadorId;
  }

  @override
  Future<void> rechazar(Inscripcion i) async => _todas[i.id] = _con(i, EstadoInscripcion.rechazada, null);

  Inscripcion _con(Inscripcion i, EstadoInscripcion estado, int? jugadorId) => Inscripcion(
        id: i.id,
        escuelaId: i.escuelaId,
        nombreEscuela: i.nombreEscuela,
        solicitanteUid: i.solicitanteUid,
        nombreSolicitante: i.nombreSolicitante,
        correoSolicitante: i.correoSolicitante,
        nombreJugador: i.nombreJugador,
        edad: i.edad,
        paraSiMismo: i.paraSiMismo,
        telefono: i.telefono,
        nota: i.nota,
        estado: estado,
        jugadorId: jugadorId,
        creada: i.creada,
      );
}

class InscripcionRepositorioFirestore implements InscripcionRepositorio {
  InscripcionRepositorioFirestore({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _inscripciones => _db.collection('inscripciones');

  @override
  Future<void> solicitar(Inscripcion i) => _inscripciones.doc(i.id).set({
        'escuelaId': i.escuelaId,
        'nombreEscuela': i.nombreEscuela,
        'solicitanteUid': i.solicitanteUid,
        'nombreSolicitante': i.nombreSolicitante,
        'correoSolicitante': i.correoSolicitante,
        'nombreJugador': i.nombreJugador,
        'edad': i.edad,
        'paraSiMismo': i.paraSiMismo,
        'telefono': i.telefono,
        'nota': i.nota,
        'estado': EstadoInscripcion.pendiente.name,
        'jugadorId': null,
        'creada': FieldValue.serverTimestamp(),
      });

  @override
  Future<List<Inscripcion>> deSolicitante(String uid) async {
    final snap = await _inscripciones.where('solicitanteUid', isEqualTo: uid).get();
    return snap.docs.map(_desde).toList()..sort((a, b) => b.creada.compareTo(a.creada));
  }

  @override
  Future<List<Inscripcion>> pendientesDeEscuela(String escuelaId) async {
    final snap = await _inscripciones
        .where('escuelaId', isEqualTo: escuelaId)
        .where('estado', isEqualTo: EstadoInscripcion.pendiente.name)
        .get();
    return snap.docs.map(_desde).toList()..sort((a, b) => a.creada.compareTo(b.creada));
  }

  @override
  Future<int> aprobar(Inscripcion i, {FichaNueva? nueva, Jugador? existente}) async {
    final escuela = _db.collection('escuelas').doc(i.escuelaId);
    final jugadorId = existente?.id ?? nueva!.id;
    final lote = _db.batch();
    if (nueva != null) {
      lote.set(escuela.collection('jugadores').doc('${nueva.id}'), {
        'id': nueva.id,
        'dorsal': nueva.dorsal,
        'nombre': i.nombreJugador,
        'posicion': nueva.posicion.name,
        'detallePosicion': nueva.detallePosicion,
        'edad': i.edad,
        'pieHabil': nueva.pieHabil,
        'estado': EstadoFisico.apto.name,
        'atributos': <String, int>{},
        'estadisticas': {'partidos': 0, 'minutos': 0, 'goles': 0, 'asistencias': 0, 'amarillas': 0},
      });
    }
    lote
      ..set(
        escuela.collection('miembros').doc(i.solicitanteUid),
        {
          'uid': i.solicitanteUid,
          'jugadorIds': FieldValue.arrayUnion(['$jugadorId']),
        },
        SetOptions(merge: true),
      )
      ..update(_inscripciones.doc(i.id), {'estado': EstadoInscripcion.aprobada.name, 'jugadorId': jugadorId});
    await lote.commit();
    return jugadorId;
  }

  @override
  Future<void> rechazar(Inscripcion i) =>
      _inscripciones.doc(i.id).update({'estado': EstadoInscripcion.rechazada.name});

  Inscripcion _desde(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return Inscripcion(
      id: doc.id,
      escuelaId: d['escuelaId'] as String,
      nombreEscuela: d['nombreEscuela'] as String? ?? '',
      solicitanteUid: d['solicitanteUid'] as String,
      nombreSolicitante: d['nombreSolicitante'] as String? ?? '',
      correoSolicitante: d['correoSolicitante'] as String? ?? '',
      nombreJugador: d['nombreJugador'] as String? ?? '',
      edad: d['edad'] as int? ?? 0,
      paraSiMismo: d['paraSiMismo'] as bool? ?? false,
      telefono: d['telefono'] as String? ?? '',
      nota: d['nota'] as String? ?? '',
      estado: EstadoInscripcion.values.asNameMap()[d['estado']] ?? EstadoInscripcion.pendiente,
      jugadorId: d['jugadorId'] as int?,
      creada: (d['creada'] as Timestamp?)?.toDate(),
    );
  }
}
