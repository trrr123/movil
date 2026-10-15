import 'dart:math';

enum EstadoEscuela {
  pendiente('En revisión'),
  aprobada('Aprobada'),
  rechazada('Rechazada');

  const EstadoEscuela(this.etiqueta);
  final String etiqueta;
}

/// Punto del mapa (cancha). Objeto de valor: sin dependencia del paquete de
/// mapas, para que el dominio no sepa qué librería pinta el mapa.
class Ubicacion {
  const Ubicacion(this.latitud, this.longitud);
  final double latitud;
  final double longitud;

  /// Riohacha, La Guajira: centro inicial del mapa antes de que el profe marque.
  static const riohacha = Ubicacion(11.5444, -72.9072);
}

/// Escuela de fútbol registrada por un profesor. Nace [EstadoEscuela.pendiente]
/// y solo el administrador la aprueba o la rechaza. El [id] es también el
/// código de solicitud que el profesor manda por WhatsApp.
class Escuela {
  Escuela({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.ubicacion,
    required this.profesores,
    required this.duenoUid,
    required this.correoDueno,
    required this.fotoProfesorId,
    this.fotoEscuelaId,
    this.descripcion = '',
    this.categoria = '',
    this.estado = EstadoEscuela.pendiente,
    this.motivoRechazo = '',
    DateTime? creada,
  }) : creada = creada ?? DateTime.now();

  final String id;
  final String nombre;
  final String direccion;
  final Ubicacion ubicacion;
  final List<String> profesores;
  final String duenoUid;
  final String correoDueno;
  final String fotoProfesorId;
  final String? fotoEscuelaId;
  final String descripcion;
  final String categoria;
  final EstadoEscuela estado;
  final String motivoRechazo;
  final DateTime creada;

  bool get aprobada => estado == EstadoEscuela.aprobada;

  /// "MK-4F7K2Q": legible, sin letras que se confundan (O/0, I/1).
  static String nuevoCodigo([Random? azar]) {
    const alfabeto = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = azar ?? Random.secure();
    return 'MK-${List.generate(6, (_) => alfabeto[r.nextInt(alfabeto.length)]).join()}';
  }
}

enum EstadoInscripcion {
  pendiente('En revisión'),
  aprobada('Aprobada'),
  rechazada('Rechazada');

  const EstadoInscripcion(this.etiqueta);
  final String etiqueta;
}

/// Pedido de cupo de un acudiente (para su hijo) o de un estudiante (para sí
/// mismo) en una escuela. El DT de esa escuela la aprueba: crea la ficha en
/// el plantel (o la enlaza a una existente) y deja anotado [jugadorId].
class Inscripcion {
  Inscripcion({
    required this.id,
    required this.escuelaId,
    required this.nombreEscuela,
    required this.solicitanteUid,
    required this.nombreSolicitante,
    required this.correoSolicitante,
    required this.nombreJugador,
    required this.edad,
    required this.paraSiMismo,
    this.telefono = '',
    this.nota = '',
    this.estado = EstadoInscripcion.pendiente,
    this.jugadorId,
    DateTime? creada,
  }) : creada = creada ?? DateTime.now();

  final String id;
  final String escuelaId;
  final String nombreEscuela;
  final String solicitanteUid;
  final String nombreSolicitante;
  final String correoSolicitante;
  final String nombreJugador;
  final int edad;

  /// true: la pidió el propio estudiante; false: un acudiente para su hijo.
  final bool paraSiMismo;
  final String telefono;
  final String nota;
  final EstadoInscripcion estado;
  final int? jugadorId;
  final DateTime creada;

  bool get aprobada => estado == EstadoInscripcion.aprobada && jugadorId != null;
}
