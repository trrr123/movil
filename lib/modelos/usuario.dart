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
  gestionarInscripciones,
  administrarEscuelas,
}

/// Escuela de las cuentas creadas antes de que la app fuera multi-escuela.
const escuelaPorDefecto = 'makuira';

/// Clase base abstracta: encapsula credenciales y expone el contrato de rol.
/// Cada subclase es un rol: [DirectorTecnico], [JugadorUsuario],
/// [Administrador], [ProfesorSolicitante], [Familia] y [UsuarioNuevo]
/// (herencia + polimorfismo: la puerta de la app decide la pantalla por tipo).
abstract class Usuario {
  Usuario({
    required String correo,
    required String clave,
    required this.nombre,
    this.uid = '',
  })  : _correo = correo.toLowerCase().trim(),
        _clave = clave;

  final String _correo;
  final String _clave;
  final String nombre;

  /// Id de la cuenta en Firebase Auth (vacío en las cuentas en memoria).
  final String uid;

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
    super.uid,
    this.categoria = 'Sub-20',
    this.escuelaId = escuelaPorDefecto,
  });

  final String categoria;

  /// Escuela que dirige: todo lo que lee y escribe cuelga de `escuelas/{escuelaId}`.
  final String escuelaId;

  @override
  String get rolCorto => 'DT';

  @override
  String get cargo => 'Director técnico · $categoria';

  @override
  Set<Permiso> get permisos => Permiso.values.toSet()..remove(Permiso.administrarEscuelas);
}

class JugadorUsuario extends Usuario {
  JugadorUsuario({
    required super.correo,
    required super.clave,
    required super.nombre,
    super.uid,
    required this.jugadorId,
    required this.dorsal,
    required this.puesto,
    this.escuelaId = escuelaPorDefecto,
  });

  /// Vínculo con la ficha del plantel: es la única ficha que puede abrir.
  final int jugadorId;
  final int dorsal;
  final String puesto;
  final String escuelaId;

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

/// Dueño de la app: revisa y aprueba las solicitudes de escuelas nuevas.
/// No dirige ninguna escuela, así que no tiene permisos de club.
class Administrador extends Usuario {
  Administrador({required super.correo, required super.nombre, super.uid}) : super(clave: '');

  @override
  String get rolCorto => 'ADMIN';

  @override
  String get cargo => 'Administrador de la app';

  @override
  Set<Permiso> get permisos => const {Permiso.administrarEscuelas};
}

/// Profesor que se registró pero cuya escuela todavía no fue aprobada por el
/// [Administrador]. Solo ve su solicitud; al aprobarse pasa a [DirectorTecnico].
class ProfesorSolicitante extends Usuario {
  ProfesorSolicitante({required super.correo, required super.nombre, super.uid}) : super(clave: '');

  @override
  String get rolCorto => 'PROFESOR';

  @override
  String get cargo => 'Profesor · solicitud en revisión';

  @override
  Set<Permiso> get permisos => const {};
}

enum TipoFamilia {
  acudiente('Padre o acudiente'),
  estudiante('Estudiante');

  const TipoFamilia(this.etiqueta);
  final String etiqueta;
}

/// Padre/acudiente, o estudiante que todavía no tiene ficha en ninguna
/// escuela. Ve a sus hijos inscritos y, si no tiene ninguno, explora las
/// escuelas para pedir cupo.
class Familia extends Usuario {
  Familia({required super.correo, required super.nombre, required this.tipo, super.uid}) : super(clave: '');

  final TipoFamilia tipo;
  bool get esEstudiante => tipo == TipoFamilia.estudiante;

  @override
  String get rolCorto => esEstudiante ? 'ESTUDIANTE' : 'ACUDIENTE';

  @override
  String get cargo => tipo.etiqueta;

  @override
  Set<Permiso> get permisos => const {};
}

/// Cuenta que ya pasó por Firebase Auth (correo o Google) pero aún no eligió
/// rol: la app le pide que lo haga antes de cualquier otra cosa.
class UsuarioNuevo extends Usuario {
  UsuarioNuevo({required super.correo, required super.nombre, super.uid}) : super(clave: '');

  @override
  String get rolCorto => 'NUEVO';

  @override
  String get cargo => 'Cuenta nueva';

  @override
  Set<Permiso> get permisos => const {};
}

/// Rol que elige una cuenta nueva en el registro.
enum RolRegistro {
  profesor('profesor'),
  acudiente('acudiente'),
  estudiante('estudiante');

  const RolRegistro(this.clave);

  /// Valor que se guarda en `usuarios/{uid}.rol` (y que validan las reglas).
  final String clave;
}
