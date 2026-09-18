import 'jugador.dart';
import '../servicios/exportable.dart';

/// Coordenada relativa dentro de la cancha (0..1) para que la pizarra
/// funcione en cualquier tamaño de pantalla.
class PuntoCampo {
  const PuntoCampo(this.x, this.y);
  final double x;
  final double y;

  PuntoCampo desplazado(double dx, double dy) =>
      PuntoCampo((x + dx).clamp(0.05, 0.95), (y + dy).clamp(0.04, 0.96));

  PuntoCampo copiarCon({double? x, double? y}) => PuntoCampo(x ?? this.x, y ?? this.y);
}

/// Sistema táctico: nombre + once posiciones base.
class Formacion {
  const Formacion(this.nombre, this.puntos);
  final String nombre;
  final List<PuntoCampo> puntos;

  static const Formacion f433 = Formacion('4-3-3', [
    PuntoCampo(.50, .92), PuntoCampo(.14, .73), PuntoCampo(.37, .77), PuntoCampo(.63, .77),
    PuntoCampo(.86, .73), PuntoCampo(.27, .52), PuntoCampo(.50, .57), PuntoCampo(.73, .52),
    PuntoCampo(.17, .26), PuntoCampo(.50, .20), PuntoCampo(.83, .26),
  ]);

  static const Formacion f442 = Formacion('4-4-2', [
    PuntoCampo(.50, .92), PuntoCampo(.14, .74), PuntoCampo(.37, .78), PuntoCampo(.63, .78),
    PuntoCampo(.86, .74), PuntoCampo(.14, .52), PuntoCampo(.38, .55), PuntoCampo(.62, .55),
    PuntoCampo(.86, .52), PuntoCampo(.38, .24), PuntoCampo(.62, .24),
  ]);

  static const Formacion f4231 = Formacion('4-2-3-1', [
    PuntoCampo(.50, .92), PuntoCampo(.14, .74), PuntoCampo(.37, .78), PuntoCampo(.63, .78),
    PuntoCampo(.86, .74), PuntoCampo(.36, .62), PuntoCampo(.64, .62), PuntoCampo(.16, .40),
    PuntoCampo(.50, .43), PuntoCampo(.84, .40), PuntoCampo(.50, .18),
  ]);

  static const Formacion f352 = Formacion('3-5-2', [
    PuntoCampo(.50, .92), PuntoCampo(.27, .78), PuntoCampo(.50, .81), PuntoCampo(.73, .78),
    PuntoCampo(.10, .57), PuntoCampo(.34, .56), PuntoCampo(.50, .61), PuntoCampo(.66, .56),
    PuntoCampo(.90, .57), PuntoCampo(.38, .24), PuntoCampo(.62, .24),
  ]);

  static const Formacion f532 = Formacion('5-3-2', [
    PuntoCampo(.50, .92), PuntoCampo(.10, .71), PuntoCampo(.30, .79), PuntoCampo(.50, .82),
    PuntoCampo(.70, .79), PuntoCampo(.90, .71), PuntoCampo(.28, .54), PuntoCampo(.50, .57),
    PuntoCampo(.72, .54), PuntoCampo(.38, .26), PuntoCampo(.62, .26),
  ]);

  static const List<Formacion> presets = [f433, f442, f4231, f352, f532];
}

/// Ficha colocada en el campo: jugador + posición editable.
class FichaCampo {
  FichaCampo({required this.jugador, required PuntoCampo punto}) : _punto = punto;

  final Jugador jugador;
  PuntoCampo _punto;

  PuntoCampo get punto => _punto;
  void mover(PuntoCampo destino) => _punto = destino;
}

/// Alineación guardada. Implementa [Exportable]: sabe describirse para
/// que cualquier exportador (PNG, PDF, enlace) la procese sin conocerla.
class Alineacion implements Exportable {
  Alineacion({
    required this.id,
    required this.nombre,
    required Formacion formacion,
    required List<Jugador> once,
    required this.creada,
    this.publicada = false,
  })  : _formacion = formacion,
        _fichas = List.generate(
          once.length,
          (i) => FichaCampo(jugador: once[i], punto: formacion.puntos[i]),
        );

  final int id;
  String nombre;
  final DateTime creada;
  bool publicada;

  Formacion _formacion;
  final List<FichaCampo> _fichas;

  Formacion get formacion => _formacion;
  List<FichaCampo> get fichas => List.unmodifiable(_fichas);
  List<Jugador> get titulares => _fichas.map((f) => f.jugador).toList();

  bool contiene(int jugadorId) => _fichas.any((f) => f.jugador.id == jugadorId);

  /// Cambia el sistema y reacomoda a los once en las posiciones base.
  void aplicarFormacion(Formacion nueva) {
    _formacion = nueva;
    for (var i = 0; i < _fichas.length && i < nueva.puntos.length; i++) {
      _fichas[i].mover(nueva.puntos[i]);
    }
  }

  void moverFicha(int jugadorId, PuntoCampo destino) {
    _fichas.firstWhere((f) => f.jugador.id == jugadorId).mover(destino);
  }

  /// Sustituye un titular por un suplente conservando su posición en el campo.
  void sustituir({required int saleId, required Jugador entra}) {
    final i = _fichas.indexWhere((f) => f.jugador.id == saleId);
    if (i < 0) return;
    final punto = _fichas[i].punto;
    _fichas[i] = FichaCampo(jugador: entra, punto: punto);
  }

  Alineacion duplicar({required int nuevoId, required String nuevoNombre}) => Alineacion(
        id: nuevoId,
        nombre: nuevoNombre,
        formacion: _formacion,
        once: titulares,
        creada: DateTime.now(),
      );

  @override
  String get nombreArchivo => 'alineacion-${_formacion.nombre}';

  @override
  Map<String, Object> aDatosExportables() => {
        'formacion': _formacion.nombre,
        'nombre': nombre,
        'creada': creada.toIso8601String(),
        'titulares': _fichas
            .map((f) => {
                  'dorsal': f.jugador.dorsal,
                  'nombre': f.jugador.nombre,
                  'x': f.punto.x,
                  'y': f.punto.y,
                })
            .toList(),
      };
}
