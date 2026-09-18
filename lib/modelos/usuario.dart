/// Permisos atómicos de la app. La UI nunca pregunta "¿es DT?",
/// pregunta "¿puede(Permiso.x)?" — así los roles crecen sin tocar pantallas.
enum Permiso {
  verPlantelCompleto,
  verFichaAjena,
  editarAlineacion,
  exportarAlineacion,
  gestionarConvocatoria,
  registrarAsistencia,
  dirigirPartido,
  verFinanzasClub,
  verFinanzasPropias,
  verAlineacionPublicada,
  verAgenda,
  verFichaPropia,
}

/// Clase base abstracta: encapsula credenciales y expone el contrato de rol.
/// [DirectorTecnico] y [JugadorUsuario] la especializan (herencia + polimorfismo).
abstract class Usuario {
  Usuario({
    required String correo,
    required String clave,
    required this.nombre,
  })  : _correo = correo.toLowerCase().trim(),
        _clave = clave;

  final String _correo;
  final String _clave;
  final String nombre;

  String get correo => _correo;
  String get inicial => nombre.isEmpty ? '?' : nombre.substring(0, 1).toUpperCase();
  String get apellido => nombre.trim().split(' ').last;

  /// Etiqueta corta para la barra superior.
  String get rolCorto;

  /// Cargo legible para mensajes ("Director técnico", "Enganche · 10").
  String get cargo;

  /// Permisos que el rol concede. Cada subclase declara los suyos.
  Set<Permiso> get permisos;

  bool puede(Permiso p) => permisos.contains(p);

  /// La clave nunca sale del objeto: solo se compara dentro.
  bool verificarClave(String intento) => _clave == intento.trim();

  @override
  String toString() => '$rolCorto($_correo)';
}

class DirectorTecnico extends Usuario {
  DirectorTecnico({
    required super.correo,
    required super.clave,
    required super.nombre,
    this.categoria = 'Sub-20',
  });

  final String categoria;

  @override
  String get rolCorto => 'DT';

  @override
  String get cargo => 'Director técnico · $categoria';

  @override
  Set<Permiso> get permisos => Permiso.values.toSet();
}

class JugadorUsuario extends Usuario {
  JugadorUsuario({
    required super.correo,
    required super.clave,
    required super.nombre,
    required this.jugadorId,
    required this.dorsal,
    required this.puesto,
  });

  /// Vínculo con la ficha del plantel: es la única ficha que puede abrir.
  final int jugadorId;
  final int dorsal;
  final String puesto;

  @override
  String get rolCorto => 'JUGADOR';

  @override
  String get cargo => '$puesto · $dorsal';

  @override
  Set<Permiso> get permisos => const {
        Permiso.verFichaPropia,
        Permiso.verFinanzasPropias,
        Permiso.verAlineacionPublicada,
        Permiso.verAgenda,
        Permiso.verPlantelCompleto, // lista de compañeros, sin métricas ajenas
      };
}
