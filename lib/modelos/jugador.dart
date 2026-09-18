enum Posicion {
  portero('POR', 'Portero'),
  defensa('DEF', 'Defensa'),
  mediocampo('MED', 'Mediocampo'),
  delantero('DEL', 'Delantero');

  const Posicion(this.sigla, this.largo);
  final String sigla;
  final String largo;
}

enum EstadoFisico {
  apto('Apto'),
  cargaAlta('Carga'),
  lesionado('Lesión');

  const EstadoFisico(this.etiqueta);
  final String etiqueta;

  bool get convocable => this != EstadoFisico.lesionado;
}

/// Métricas acumuladas de la temporada. Objeto de valor inmutable:
/// se reemplaza, no se muta (composición dentro de [Jugador]).
class Estadisticas {
  const Estadisticas({
    this.partidos = 0,
    this.minutos = 0,
    this.goles = 0,
    this.asistencias = 0,
    this.amarillas = 0,
  });

  final int partidos;
  final int minutos;
  final int goles;
  final int asistencias;
  final int amarillas;

  double get minutosPorPartido => partidos == 0 ? 0 : minutos / partidos;
  double get golesPorPartido => partidos == 0 ? 0 : goles / partidos;

  Estadisticas sumar({int minutos = 0, int goles = 0, int asistencias = 0, int amarillas = 0, bool jugo = false}) =>
      Estadisticas(
        partidos: partidos + (jugo ? 1 : 0),
        minutos: this.minutos + minutos,
        goles: this.goles + goles,
        asistencias: this.asistencias + asistencias,
        amarillas: this.amarillas + amarillas,
      );
}

/// Ficha del plantel. Los campos que cambian por decisión del cuerpo técnico
/// son privados y se modifican por métodos con intención de negocio.
class Jugador {
  Jugador({
    required this.id,
    required this.dorsal,
    required this.nombre,
    required this.posicion,
    required this.detallePosicion,
    required this.edad,
    required this.pieHabil,
    Estadisticas estadisticas = const Estadisticas(),
    EstadoFisico estado = EstadoFisico.apto,
    Map<String, int> atributos = const {},
  })  : _estadisticas = estadisticas,
        _estado = estado,
        _atributos = Map.unmodifiable(atributos);

  final int id;
  final int dorsal;
  final String nombre;
  final Posicion posicion;
  final String detallePosicion;
  final int edad;
  final String pieHabil;

  Estadisticas _estadisticas;
  EstadoFisico _estado;
  final Map<String, int> _atributos;

  Estadisticas get estadisticas => _estadisticas;
  EstadoFisico get estado => _estado;
  Map<String, int> get atributos => _atributos;

  String get apellido => nombre.trim().split(' ').last;
  bool get disponible => _estado.convocable;

  void cambiarEstado(EstadoFisico nuevo) => _estado = nuevo;

  void registrarPartido({int minutos = 0, int goles = 0, int asistencias = 0, int amarillas = 0}) {
    _estadisticas = _estadisticas.sumar(
      minutos: minutos,
      goles: goles,
      asistencias: asistencias,
      amarillas: amarillas,
      jugo: minutos > 0,
    );
  }

  /// Vista reducida que se entrega a un jugador cuando consulta a un compañero:
  /// identidad y puesto, sin métricas ni estado médico.
  Map<String, Object> resumenPublico() => {
        'dorsal': dorsal,
        'nombre': nombre,
        'posicion': detallePosicion,
        'edad': edad,
      };
}
