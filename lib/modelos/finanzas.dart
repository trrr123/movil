import 'jugador.dart';

enum EstadoCuota { alDia, pendiente, reportada }

/// Cuota mensual de un jugador. El jugador solo ve la suya.
class Cuota {
  Cuota({
    required this.jugadorId,
    required this.periodo,
    required this.monto,
    EstadoCuota estado = EstadoCuota.pendiente,
  }) : _estado = estado;

  final int jugadorId;
  final String periodo;
  final int monto;
  EstadoCuota _estado;

  EstadoCuota get estado => _estado;
  bool get alDia => _estado == EstadoCuota.alDia;

  String get etiqueta => switch (_estado) {
        EstadoCuota.alDia => 'Al día',
        EstadoCuota.reportada => 'En revisión',
        EstadoCuota.pendiente => 'Pendiente',
      };

  /// El jugador reporta; el club confirma. Dos acciones distintas, dos permisos.
  void reportarPago() {
    if (_estado == EstadoCuota.pendiente) _estado = EstadoCuota.reportada;
  }

  void confirmarPago() => _estado = EstadoCuota.alDia;
}

/// Caja del mes: agrega cuotas y calcula el recaudo (composición).
class CajaMensual {
  CajaMensual({required this.periodo, required List<Cuota> cuotas}) : _cuotas = cuotas;

  final String periodo;
  final List<Cuota> _cuotas;

  List<Cuota> get cuotas => List.unmodifiable(_cuotas);
  int get meta => _cuotas.fold(0, (a, c) => a + c.monto);
  int get recaudado => _cuotas.where((c) => c.alDia).fold(0, (a, c) => a + c.monto);
  int get pendientes => _cuotas.where((c) => !c.alDia).length;
  double get avance => meta == 0 ? 0 : recaudado / meta;

  Cuota deJugador(int jugadorId) => _cuotas.firstWhere((c) => c.jugadorId == jugadorId);

  String get recaudadoFormateado => formatearPesos(recaudado);
  String get metaFormateada => formatearPesos(meta);

  static String formatearPesos(int valor) {
    final s = valor.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return '\$$b';
  }
}

/// Convocatoria de un partido: lista cerrada con tope reglamentario.
class Convocatoria {
  Convocatoria({required this.partidoId, this.tope = 18});

  final int partidoId;
  final int tope;
  final Set<int> _llamados = {};
  bool _enviada = false;

  Set<int> get llamados => Set.unmodifiable(_llamados);
  int get total => _llamados.length;
  bool get enviada => _enviada;
  bool get completa => total >= tope;
  bool incluye(int jugadorId) => _llamados.contains(jugadorId);

  /// Devuelve false cuando la regla de negocio impide el cambio.
  bool alternar(Jugador jugador) {
    if (_llamados.contains(jugador.id)) {
      _llamados.remove(jugador.id);
      return true;
    }
    if (!jugador.disponible || completa) return false;
    _llamados.add(jugador.id);
    return true;
  }

  void enviar() => _enviada = true;
}
