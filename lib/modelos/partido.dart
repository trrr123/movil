import 'jugador.dart';
import '../servicios/exportable.dart';

/// Jerarquía de eventos: una sola lista los guarda y cada subclase
/// sabe describirse (polimorfismo) — la UI no hace switch por tipo.
abstract class EventoPartido {
  EventoPartido({required this.minuto});
  final int minuto;

  String get tipo;
  String get descripcion;
  bool get esDestacado => false;
}

class Gol extends EventoPartido {
  Gol({required super.minuto, required this.autor, this.asistente, this.rival = false});

  final Jugador autor;
  final Jugador? asistente;
  final bool rival;

  @override
  String get tipo => 'Gol';

  @override
  bool get esDestacado => true;

  @override
  String get descripcion => rival
      ? 'Gol del rival'
      : '${autor.dorsal} ${autor.apellido}'
          '${asistente != null ? ' — asistencia de ${asistente!.dorsal} ${asistente!.apellido}' : ''}';
}

enum ColorTarjeta { amarilla, roja }

class Tarjeta extends EventoPartido {
  Tarjeta({required super.minuto, required this.jugador, this.color = ColorTarjeta.amarilla});

  final Jugador jugador;
  final ColorTarjeta color;

  @override
  String get tipo => 'Tarjeta';

  @override
  String get descripcion =>
      '${color == ColorTarjeta.amarilla ? 'Amarilla' : 'Roja'} a ${jugador.dorsal} ${jugador.apellido}';
}

class Cambio extends EventoPartido {
  Cambio({required super.minuto, required this.sale, required this.entra});

  final Jugador sale;
  final Jugador entra;

  @override
  String get tipo => 'Cambio';

  @override
  String get descripcion => 'Entra ${entra.dorsal} ${entra.apellido} · sale ${sale.dorsal} ${sale.apellido}';
}

enum EstadoPartido { programado, enCurso, entretiempo, finalizado }

/// Partido con reloj y acta. Solo el DT lo manipula; el jugador lo lee.
class Partido implements Exportable {
  Partido({
    required this.id,
    required this.rival,
    required this.fecha,
    required this.sede,
    required this.competencia,
    this.local = true,
  });

  final int id;
  final String rival;
  final DateTime fecha;
  final String sede;
  final String competencia;
  final bool local;

  final List<EventoPartido> _eventos = [];
  EstadoPartido _estado = EstadoPartido.programado;
  int _minuto = 0;

  List<EventoPartido> get eventos => List.unmodifiable(_eventos.reversed);
  EstadoPartido get estado => _estado;
  int get minuto => _minuto;
  bool get enJuego => _estado == EstadoPartido.enCurso;

  int get golesPropios => _eventos.whereType<Gol>().where((g) => !g.rival).length;
  int get golesRival => _eventos.whereType<Gol>().where((g) => g.rival).length;
  String get marcador => '$golesPropios — $golesRival';

  void iniciar() {
    _estado = EstadoPartido.enCurso;
    _minuto = 0;
  }

  void alternarReloj() {
    _estado = enJuego ? EstadoPartido.entretiempo : EstadoPartido.enCurso;
  }

  void avanzarMinuto([int minutos = 1]) {
    if (!enJuego) return;
    _minuto = (_minuto + minutos).clamp(0, 95);
  }

  void anotar(EventoPartido evento) => _eventos.add(evento);

  void finalizar() {
    _estado = EstadoPartido.finalizado;
    for (final j in _titularesQueJugaron) {
      j.registrarPartido(minutos: _minuto);
    }
  }

  final Set<Jugador> _titularesQueJugaron = {};
  void registrarEnCampo(Iterable<Jugador> jugadores) => _titularesQueJugaron.addAll(jugadores);

  @override
  String get nombreArchivo => 'acta-${competencia.toLowerCase().replaceAll(' ', '-')}-$id';

  @override
  Map<String, Object> aDatosExportables() => {
        'rival': rival,
        'fecha': fecha.toIso8601String(),
        'marcador': marcador,
        'eventos': _eventos.map((e) => {'minuto': e.minuto, 'tipo': e.tipo, 'detalle': e.descripcion}).toList(),
      };
}

/// Entrenamiento o charla: comparte la agenda con los partidos.
enum TipoSesion { entrenamiento, video, gimnasio }

class SesionEntrenamiento {
  SesionEntrenamiento({
    required this.id,
    required this.titulo,
    required this.fecha,
    required this.lugar,
    this.tipo = TipoSesion.entrenamiento,
  });

  final int id;
  final String titulo;
  final DateTime fecha;
  final String lugar;
  final TipoSesion tipo;

  final Map<int, bool> _asistencia = {};

  Map<int, bool> get asistencia => Map.unmodifiable(_asistencia);
  int get presentes => _asistencia.values.where((v) => v).length;

  void marcar(int jugadorId, bool presente) => _asistencia[jugadorId] = presente;
  bool asistio(int jugadorId) => _asistencia[jugadorId] ?? false;
}
