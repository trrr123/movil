import 'package:cloud_firestore/cloud_firestore.dart';

/// Datos públicos del club (nombre, categoría): los únicos legibles sin
/// sesión, para que la pantalla de login los muestre antes de cualquier login.
abstract class ClubRepositorio {
  Future<({String nombreClub, String categoria})> cargar();
}

class ClubRepositorioDemo implements ClubRepositorio {
  @override
  Future<({String nombreClub, String categoria})> cargar() async =>
      (nombreClub: 'Club Makuira', categoria: 'Sub-20 · Temporada 26');
}

class ClubRepositorioFirestore implements ClubRepositorio {
  ClubRepositorioFirestore({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<({String nombreClub, String categoria})> cargar() async {
    final doc = await _db.collection('club').doc('config').get();
    final d = doc.data() ?? const <String, dynamic>{};
    return (
      nombreClub: d['nombreClub'] as String? ?? 'Club',
      categoria: d['categoria'] as String? ?? '',
    );
  }
}
