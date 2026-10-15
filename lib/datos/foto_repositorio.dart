import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Fotos de escuelas y profesores. Hoy se guardan comprimidas (JPEG ~800px)
/// como base64 en `fotos/{id}`, para no depender de Cloud Storage (que exige
/// el plan Blaze). Pasar a Storage es escribir otra implementación.
abstract class FotoRepositorio {
  /// Tamaño máximo aceptado (las reglas de Firestore validan lo mismo).
  static const bytesMaximos = 700 * 1024;

  Future<String> subir(Uint8List bytes, {required String duenoUid});
  Future<Uint8List?> cargar(String id);
}

class FotoRepositorioDemo implements FotoRepositorio {
  final Map<String, Uint8List> _fotos = {};

  @override
  Future<String> subir(Uint8List bytes, {required String duenoUid}) async {
    final id = 'foto-${_fotos.length + 1}';
    _fotos[id] = bytes;
    return id;
  }

  @override
  Future<Uint8List?> cargar(String id) async => _fotos[id];
}

class FotoRepositorioFirestore implements FotoRepositorio {
  FotoRepositorioFirestore({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Las listas de escuelas piden la misma foto varias veces: se recuerdan.
  final Map<String, Uint8List> _cache = {};

  @override
  Future<String> subir(Uint8List bytes, {required String duenoUid}) async {
    if (bytes.length > FotoRepositorio.bytesMaximos) {
      throw StateError('La foto es demasiado pesada. Elige otra.');
    }
    final ref = _db.collection('fotos').doc();
    await ref.set({
      'duenoUid': duenoUid,
      'datos': base64Encode(bytes),
      'creada': FieldValue.serverTimestamp(),
    });
    _cache[ref.id] = bytes;
    return ref.id;
  }

  @override
  Future<Uint8List?> cargar(String id) async {
    if (_cache.containsKey(id)) return _cache[id];
    final doc = await _db.collection('fotos').doc(id).get();
    final datos = doc.data()?['datos'] as String?;
    if (datos == null) return null;
    return _cache[id] = base64Decode(datos);
  }
}
