import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelos/usuario.dart';

/// Escuela cuyos datos se están leyendo. Todos los repositorios Firestore del
/// club la comparten: [AppEstado] la fija al iniciar sesión (la del DT o la
/// del jugador) y cada colección (`jugadores`, `partidos`, `caja`…) se resuelve
/// debajo de `escuelas/{id}` — así dos escuelas nunca ven datos de la otra.
class EscuelaActiva {
  EscuelaActiva({FirebaseFirestore? db}) : _db = db;

  final FirebaseFirestore? _db;
  String id = escuelaPorDefecto;

  FirebaseFirestore get db => _db ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get documento => db.collection('escuelas').doc(id);

  CollectionReference<Map<String, dynamic>> coleccion(String nombre) => documento.collection(nombre);
}
