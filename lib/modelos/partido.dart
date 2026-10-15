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

  /// Forma guardable del evento (ids de jugadores, no objetos).
  Map<String, Object?> aMapa();

  /// Reconstruye un evento guardado; null si sus jugadores ya no están.
  static EventoPartido? desdeMapa(Map<String, dynamic> d, Map<int, Jugador> porId) {
    final minuto = d['m'] as int? ?? 0;
    Jugador? j(String campo) => d[campo] == null ? null : porId[d[campo] as int];
    return switch (d['t']) {
      'golRival' => Gol.rival(minuto: minuto),
      'gol' when j('autor') != null => Gol(minuto: minuto, autor: j('autor'), asistente: j('asistente')),
      'tarjeta' when j('jugador') != null => Tarjeta(
          minuto: minuto,
          jugador: j('jugador')!,
          color: d['color'] == ColorTarjeta.roja.name ? ColorTarjeta.roja : ColorTarjeta.amarilla,
        ),
      'cambio' when j('sale') != null && j('entra') != null =>
        Cambio(minuto: minuto, sale: j('sale')!, entra: j('entra')!),
      _ => null,
    };
  }
}

class Gol extends EventoPartido {
  Gol({required super.minuto, required this.autor, this.asistente}) : rival = false;

  /// Gol del equipo contrario: no tiene autor ni asistente de este plantel.
  Gol.rival({required super.minuto})
      : autor = null,
        asistente = null,
        rival = true;

  final Jugador? autor;
  final Jugador? asistente;
  final bool rival;

  @override
  String get tipo => 'Gol';

  @override
  bool get esDestacado => true;

  @override
  String get descripcion => rival
      ? 'Gol del rival'
      : '${autor!.dorsal} ${autor!.apellido}'
          '${asistente != null ? ' — asistencia de ${asistente!.dorsal} ${asistente!.apellido}' : ''}';

  @override
  Map<String, Object?> aMapa() =>
      rival ? {'t': 'golRival', 'm': minuto} : {'t': 'gol', 'm': minuto, 'autor': autor!.id, 'asistente': asistente?.id};
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

  @override
  Map<String, Object?> aMapa() => {'t': 'tarjeta', 'm': minuto, 'jugador': jugador.id, 'color': color.name};
}

class Cambio extends EventoPartido {
  Cambio({required super.minuto, required this.sale, required this.entra});

  final Jugador sale;
  final Jugador entra;

  @override
  String get tipo => 'Cambio';

  @override
  String get descripcion => 'Entra ${entra.dorsal} ${entra.apellido} · sale ${sale.dorsal} ${sale.apellido}';

  @override
  Map<String, Object?> aMapa() => {'t': 'cambio', 'm': minuto, 'sale': sale.id, 'entra': entra.id};
}

enum EstadoPartido { programado, enCurso, entretiempo, finalizado }

/// Partido con reloj y acta. Solo el DT lo manipula; el jugador lo lee.
///
/// Mientras se juega, nada toca las estadísticas de los jugadores: todo queda
/// en el acta (eventos + minuto en que entró cada uno). Al [finalizar] se
/// calculan goles, asistencias, amarillas y minutos desde el acta. Así, si
/// la app se cierra a mitad del partido, se puede retomar desde lo guardado
/// ([aMapaEnVivo] / [restaurarEnVivo]) sin perder ni duplicar nada.
class Partido implements Exportable {
  Partido({
    required this.id,
    required this.rival,
    required this.fecha,
    required this.sede,
    required this.competencia,
    this.local = true,
    EstadoPartido estado = EstadoPartido.programado,
    int minuto = 0,
    int golesPropiosGuardados = 0,
    int golesRivalGuardados = 0,
  })  : _estado = estado,
        _minuto = minuto,
        _golesPropiosGuardados = golesPropiosGuardados,
        _golesRivalGuardados = golesRivalGuardados;

  static const minutoMaximo = 130;

  final int id;
  final String rival;
  final DateTime fecha;
  final String sede;
  final String competencia;
  final bool local;

  final List<EventoPartido> _eventos = [];
  EstadoPartido _estado;
  int _minuto;

  /// Resultado de un partido ya jugado que se cargó de la base de datos: sus
  /// eventos no se reconstruyen, solo el marcador final.
  final int _golesPropiosGuardados;
  final int _golesRivalGuardados;

  /// Minuto en que entró cada jugador que está en cancha, y minutos ya
  /// cerrados de los que salieron: con eso se calculan los minutos jugados.
  final Map<Jugador, int> _entrada = {};
  final Map<Jugador, int> _minutosJugados = {};

  List<EventoPartido> get eventos => List.unmodifiable(_eventos.reversed);
  EstadoPartido get estado => _estado;
  int get minuto => _minuto;
  bool get enJuego => _estado == EstadoPartido.enCurso;
  bool get finalizado => _estado == EstadoPartido.finalizado;
  bool get programado => _estado == EstadoPartido.programado;

  /// Empezó y no terminó (en curso o en pausa).
  bool get enProgreso => !programado && !finalizado;

  int get golesPropios => _golesPropiosGuardados + _eventos.whereType<Gol>().where((g) => !g.rival).length;
  int get golesRival => _golesRivalGuardados + _eventos.whereType<Gol>().where((g) => g.rival).length;
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
    _minuto = (_minuto + minutos).clamp(0, minutoMaximo);
  }

  /// Corrección manual del DT (el reloj se atrasó, la app estuvo cerrada…).
  void corregirMinuto(int delta) {
    if (!enProgreso) return;
    _minuto = (_minuto + delta).clamp(0, minutoMaximo);
  }

  void anotar(EventoPartido evento) {
    _eventos.add(evento);
    if (evento is Cambio) {
      _cerrarMinutos(evento.sale);
      _entrada[evento.entra] = _minuto;
    }
  }

  void _cerrarMinutos(Jugador j) {
    final desde = _entrada.remove(j);
    if (desde != null) _minutosJugados[j] = (_minutosJugados[j] ?? 0) + (_minuto - desde).clamp(0, minutoMaximo);
  }

  /// Cierra el partido y suma a cada jugador lo que hizo según el acta:
  /// partido jugado y minutos (si pisó la cancha), goles, asistencias y
  /// amarillas. Devuelve a quienes les cambiaron las estadísticas.
  Set<Jugador> finalizar() {
    if (finalizado) return const {};
    _estado = EstadoPartido.finalizado;
    for (final j in _entrada.keys.toList()) {
      _cerrarMinutos(j);
    }
    for (final e in _minutosJugados.entries) {
      e.key.registrarPartido(minutos: e.value, jugo: true);
    }
    for (final e in _eventos) {
      switch (e) {
        case Gol(rival: false, :final autor, :final asistente):
          autor?.registrarPartido(goles: 1, jugo: false);
          asistente?.registrarPartido(asistencias: 1, jugo: false);
        case Tarjeta(color: ColorTarjeta.amarilla, :final jugador):
          jugador.registrarPartido(amarillas: 1, jugo: false);
        default:
      }
    }
    return {...participantes};
  }

  void registrarEnCampo(Iterable<Jugador> jugadores) {
    for (final j in jugadores) {
      _entrada.putIfAbsent(j, () => _minuto);
    }
  }

  /// Quien jugó o aparece en el acta (goles, asistencias, tarjetas, cambios).
  Set<Jugador> get participantes => {
        ..._entrada.keys,
        ..._minutosJugados.keys,
        for (final e in _eventos)
          ...switch (e) {
            Gol(rival: false, :final autor, :final asistente) => [if (autor != null) autor, if (asistente != null) asistente],
            Tarjeta(:final jugador) => [jugador],
            Cambio(:final sale, :final entra) => [sale, entra],
            _ => const <Jugador>[],
          },
      };

  /// Estado de un partido en curso, para guardarlo y poder retomarlo.
  Map<String, Object?> aMapaEnVivo() => {
        'eventos': [for (final e in _eventos) e.aMapa()],
        'entrada': {for (final e in _entrada.entries) '${e.key.id}': e.value},
        'jugados': {for (final e in _minutosJugados.entries) '${e.key.id}': e.value},
      };

  /// Retoma un partido que quedó en curso (la app se cerró a mitad). Queda en
  /// pausa: el DT lo reanuda con "Seguir" y puede corregir el minuto.
  void restaurarEnVivo(Map<String, dynamic> d, {required int minuto, required List<Jugador> plantel}) {
    final porId = {for (final j in plantel) j.id: j};
    _estado = EstadoPartido.entretiempo;
    _minuto = minuto;
    _eventos
      ..clear()
      ..addAll((d['eventos'] as List<dynamic>? ?? const [])
          .map((e) => EventoPartido.desdeMapa(e as Map<String, dynamic>, porId))
          .whereType<EventoPartido>());
    void llenar(Map<Jugador, int> destino, Object? origen) {
      destino.clear();
      for (final e in (origen as Map<String, dynamic>? ?? const {}).entries) {
        final j = porId[int.tryParse(e.key)];
        if (j != null) destino[j] = e.value as int;
      }
    }

    llenar(_entrada, d['entrada']);
    llenar(_minutosJugados, d['jugados']);
  }

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
