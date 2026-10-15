import 'escuela_activa.dart';

/// Nombre y categoría de la escuela activa, para la barra superior.
abstract class ClubRepositorio {
  Future<({String nombreClub, String categoria})> cargar();
}

class ClubRepositorioDemo implements ClubRepositorio {
  @override
  Future<({String nombreClub, String categoria})> cargar() async =>
      (nombreClub: 'Club Makuira', categoria: 'Sub-20 · Temporada 26');
}

class ClubRepositorioFirestore implements ClubRepositorio {
  ClubRepositorioFirestore(this._escuela);

  final EscuelaActiva _escuela;

  @override
  Future<({String nombreClub, String categoria})> cargar() async {
    final doc = await _escuela.documento.get();
    final d = doc.data() ?? const <String, dynamic>{};
    return (
      nombreClub: d['nombre'] as String? ?? 'Escuela',
      categoria: d['categoria'] as String? ?? '',
    );
  }
}
