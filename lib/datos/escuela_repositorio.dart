import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelos/escuela.dart';

/// Escuelas de la plataforma: solicitudes de profesores, aprobación del
/// administrador y catálogo público (solo las aprobadas) para las familias.
abstract class EscuelaRepositorio {
  Future<void> enviarSolicitud(Escuela escuela);

  /// La escuela que registró este profesor (la más reciente), si hay.
  Future<Escuela?> deDueno(String uid);
  Future<Escuela?> porId(String id);
  Future<List<Escuela>> porEstado(EstadoEscuela estado);

  /// Marca la escuela como aprobada y convierte a su dueño en DT de ella.
  Future<void> aprobar(Escuela escuela);
  Future<void> rechazar(Escuela escuela, String motivo);
}

class EscuelaRepositorioDemo implements EscuelaRepositorio {
  final Map<String, Escuela> _escuelas = {};

  @override
  Future<void> enviarSolicitud(Escuela escuela) async => _escuelas[escuela.id] = escuela;

  @override
  Future<Escuela?> deDueno(String uid) async => _escuelas.values.where((e) => e.duenoUid == uid).lastOrNull;

  @override
  Future<Escuela?> porId(String id) async => _escuelas[id];

  @override
  Future<List<Escuela>> porEstado(EstadoEscuela estado) async =>
      _escuelas.values.where((e) => e.estado == estado).toList();

  @override
  Future<void> aprobar(Escuela escuela) async => _escuelas[escuela.id] = _conEstado(escuela, EstadoEscuela.aprobada);

  @override
  Future<void> rechazar(Escuela escuela, String motivo) async =>
      _escuelas[escuela.id] = _conEstado(escuela, EstadoEscuela.rechazada, motivo: motivo);

  Escuela _conEstado(Escuela e, EstadoEscuela estado, {String motivo = ''}) => Escuela(
        id: e.id,
        nombre: e.nombre,
        direccion: e.direccion,
        ubicacion: e.ubicacion,
        profesores: e.profesores,
        duenoUid: e.duenoUid,
        correoDueno: e.correoDueno,
        fotoProfesorId: e.fotoProfesorId,
        fotoEscuelaId: e.fotoEscuelaId,
        descripcion: e.descripcion,
        categoria: e.categoria,
        estado: estado,
        motivoRechazo: motivo,
        creada: e.creada,
      );
}

class EscuelaRepositorioFirestore implements EscuelaRepositorio {
  EscuelaRepositorioFirestore({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _escuelas => _db.collection('escuelas');

  @override
  Future<void> enviarSolicitud(Escuela e) => _escuelas.doc(e.id).set({
        'id': e.id,
        'nombre': e.nombre,
        'direccion': e.direccion,
        'latitud': e.ubicacion.latitud,
        'longitud': e.ubicacion.longitud,
        'profesores': e.profesores,
        'duenoUid': e.duenoUid,
        'correoDueno': e.correoDueno,
        'fotoProfesorId': e.fotoProfesorId,
        'fotoEscuelaId': e.fotoEscuelaId,
        'descripcion': e.descripcion,
        'categoria': e.categoria,
        'estado': EstadoEscuela.pendiente.name,
        'motivoRechazo': '',
        'creada': FieldValue.serverTimestamp(),
      });

  @override
  Future<Escuela?> deDueno(String uid) async {
    final snap = await _escuelas.where('duenoUid', isEqualTo: uid).get();
    final lista = snap.docs.map(_desde).toList()..sort((a, b) => a.creada.compareTo(b.creada));
    return lista.lastOrNull;
  }

  @override
  Future<Escuela?> porId(String id) async {
    final doc = await _escuelas.doc(id).get();
    return doc.exists ? _desde(doc) : null;
  }

  @override
  Future<List<Escuela>> porEstado(EstadoEscuela estado) async {
    final snap = await _escuelas.where('estado', isEqualTo: estado.name).get();
    return snap.docs.map(_desde).toList()..sort((a, b) => b.creada.compareTo(a.creada));
  }

  @override
  Future<void> aprobar(Escuela e) async {
    final lote = _db.batch()
      ..update(_escuelas.doc(e.id), {'estado': EstadoEscuela.aprobada.name, 'motivoRechazo': ''})
      ..update(_db.collection('usuarios').doc(e.duenoUid), {
        'rol': 'dt',
        'escuelaId': e.id,
        'categoria': e.categoria.isEmpty ? 'Escuela' : e.categoria,
      });
    await lote.commit();
  }

  @override
  Future<void> rechazar(Escuela e, String motivo) =>
      _escuelas.doc(e.id).update({'estado': EstadoEscuela.rechazada.name, 'motivoRechazo': motivo});

  Escuela _desde(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Escuela(
      id: doc.id,
      nombre: d['nombre'] as String? ?? '',
      direccion: d['direccion'] as String? ?? '',
      ubicacion: Ubicacion(
        (d['latitud'] as num?)?.toDouble() ?? Ubicacion.riohacha.latitud,
        (d['longitud'] as num?)?.toDouble() ?? Ubicacion.riohacha.longitud,
      ),
      profesores: (d['profesores'] as List<dynamic>? ?? const []).cast<String>(),
      duenoUid: d['duenoUid'] as String? ?? '',
      correoDueno: d['correoDueno'] as String? ?? '',
      fotoProfesorId: d['fotoProfesorId'] as String? ?? '',
      fotoEscuelaId: d['fotoEscuelaId'] as String?,
      descripcion: d['descripcion'] as String? ?? '',
      categoria: d['categoria'] as String? ?? '',
      estado: EstadoEscuela.values.asNameMap()[d['estado']] ?? EstadoEscuela.pendiente,
      motivoRechazo: d['motivoRechazo'] as String? ?? '',
      // Recién escrita, `creada` puede venir null hasta que el servidor la llene.
      creada: (d['creada'] as Timestamp?)?.toDate(),
    );
  }
}
