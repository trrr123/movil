import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelos/alineacion.dart';
import '../modelos/finanzas.dart';
import '../modelos/jugador.dart';
import '../modelos/partido.dart';

/// Fuente de datos del club. La app depende de esta abstracción,
/// así el backend real entra después sin tocar UI ni estado.
///
/// Todo es asíncrono porque la implementación real ([EquipoRepositorioFirestore])
/// viaja por red; [EquipoRepositorioDemo] solo envuelve datos en memoria en un
/// `Future` ya resuelto.
abstract class EquipoRepositorio {
  Future<({String nombreClub, String categoria})> cargarClub();
  Future<List<Jugador>> cargarPlantel();
  Future<List<Partido>> cargarPartidos();
  Future<List<SesionEntrenamiento>> cargarSesiones();
  Future<CajaMensual> cargarCaja(List<Jugador> plantel);
  Future<List<Alineacion>> cargarAlineaciones(List<Jugador> plantel);
}

class EquipoRepositorioDemo implements EquipoRepositorio {
  @override
  Future<({String nombreClub, String categoria})> cargarClub() async =>
      (nombreClub: 'Club Makuira', categoria: 'Sub-20 · Temporada 26');

  @override
  Future<List<Jugador>> cargarPlantel() async => [
        _j(1, 1, 'A. Barrios', Posicion.portero, 'Portero', 19, 'Derecho', 1260, 0, 0),
        _j(2, 3, 'J. Mendoza', Posicion.defensa, 'Lateral izq.', 18, 'Izquierdo', 1104, 1, 3),
        _j(3, 4, 'S. Cotes', Posicion.defensa, 'Central', 19, 'Derecho', 1190, 2, 0),
        _j(4, 2, 'K. Epieyú', Posicion.defensa, 'Central', 18, 'Derecho', 980, 1, 1),
        _j(5, 13, 'D. Solano', Posicion.defensa, 'Lateral der.', 17, 'Derecho', 845, 0, 4),
        _j(6, 6, 'M. Brito', Posicion.mediocampo, 'Volante mixto', 19, 'Derecho', 1210, 1, 2),
        _j(7, 8, 'R. Daza', Posicion.mediocampo, 'Volante central', 18, 'Izquierdo', 1015, 3, 5),
        _j(8, 10, 'L. Zúñiga', Posicion.mediocampo, 'Enganche', 19, 'Izquierdo', 986, 7, 4,
            atributos: const {'Ritmo': 69, 'Definición': 64, 'Pase': 88, 'Regate': 91, 'Defensa': 52, 'Físico': 61}),
        _j(9, 11, 'E. Redondo', Posicion.delantero, 'Extremo izq.', 17, 'Derecho', 720, 5, 3),
        _j(10, 9, 'Y. Pushaina', Posicion.delantero, 'Delantero', 18, 'Derecho', 1120, 11, 2),
        _j(11, 7, 'C. Uriana', Posicion.delantero, 'Extremo der.', 17, 'Izquierdo', 690, 4, 6),
        _j(12, 12, 'H. Pimienta', Posicion.portero, 'Portero', 17, 'Derecho', 180, 0, 0),
        _j(13, 5, 'N. Iguarán', Posicion.defensa, 'Central', 18, 'Derecho', 610, 0, 0,
            estado: EstadoFisico.lesionado),
        _j(14, 14, 'B. Ramírez', Posicion.mediocampo, 'Volante central', 17, 'Derecho', 540, 1, 1),
        _j(15, 15, 'T. Gámez', Posicion.defensa, 'Central', 19, 'Izquierdo', 470, 0, 0),
        _j(16, 16, 'W. Curvelo', Posicion.mediocampo, 'Volante izq.', 18, 'Izquierdo', 430, 2, 2,
            estado: EstadoFisico.cargaAlta),
        _j(17, 17, 'F. Ipuana', Posicion.delantero, 'Delantero', 17, 'Derecho', 380, 3, 0),
        _j(18, 18, 'G. Fonseca', Posicion.defensa, 'Lateral der.', 17, 'Derecho', 295, 0, 1),
        _j(19, 19, 'P. Villazón', Posicion.delantero, 'Extremo der.', 16, 'Derecho', 210, 1, 1,
            estado: EstadoFisico.cargaAlta),
        _j(20, 20, 'O. Deluque', Posicion.mediocampo, 'Volante def.', 18, 'Derecho', 640, 0, 2,
            estado: EstadoFisico.lesionado),
      ];

  @override
  Future<List<Partido>> cargarPartidos() async => [
        Partido(
          id: 15,
          rival: 'Dep. Uribia',
          fecha: DateTime(2026, 9, 19, 15, 30),
          sede: 'Cancha La Serranía',
          competencia: 'Liga juvenil',
        ),
        Partido(
          id: 16,
          rival: 'Academia Riohacha',
          fecha: DateTime(2026, 9, 26, 10, 0),
          sede: 'Visitante',
          competencia: 'Liga juvenil',
          local: false,
        ),
      ];

  @override
  Future<List<SesionEntrenamiento>> cargarSesiones() async => [
        SesionEntrenamiento(
            id: 1, titulo: 'Fuerza y transiciones', fecha: DateTime(2026, 9, 17, 16), lugar: 'Sede · cancha 2'),
        SesionEntrenamiento(
            id: 2,
            titulo: 'Charla táctica rival',
            fecha: DateTime(2026, 9, 18, 18),
            lugar: 'Salón sede',
            tipo: TipoSesion.video),
        SesionEntrenamiento(
            id: 3,
            titulo: 'Recuperación + balón parado',
            fecha: DateTime(2026, 9, 22, 16),
            lugar: 'Sede · cancha 1'),
      ];

  @override
  Future<CajaMensual> cargarCaja(List<Jugador> plantel) async => CajaMensual(
        periodo: 'Septiembre 2026',
        cuotas: [
          for (var i = 0; i < plantel.length; i++)
            Cuota(
              jugadorId: plantel[i].id,
              periodo: 'Septiembre 2026',
              monto: 60000,
              estado: i % 6 == 2 ? EstadoCuota.pendiente : EstadoCuota.alDia,
            )
        ],
      );

  @override
  Future<List<Alineacion>> cargarAlineaciones(List<Jugador> plantel) async => [
        Alineacion(
          id: 1,
          nombre: 'Presión alta — titular',
          formacion: Formacion.f433,
          once: plantel.take(11).toList(),
          creada: DateTime(2026, 9, 5, 9, 12),
          publicada: true,
        ),
        Alineacion(
          id: 2,
          nombre: 'Bloque bajo vs. Uribia',
          formacion: Formacion.f442,
          once: plantel.take(11).toList(),
          creada: DateTime(2026, 9, 12, 18, 40),
        ),
      ];

  static Jugador _j(
    int id,
    int dorsal,
    String nombre,
    Posicion pos,
    String detalle,
    int edad,
    String pie,
    int minutos,
    int goles,
    int asis, {
    EstadoFisico estado = EstadoFisico.apto,
    Map<String, int> atributos = const {},
  }) =>
      Jugador(
        id: id,
        dorsal: dorsal,
        nombre: nombre,
        posicion: pos,
        detallePosicion: detalle,
        edad: edad,
        pieHabil: pie,
        estado: estado,
        atributos: atributos,
        estadisticas: Estadisticas(
          partidos: (minutos / 78).round(),
          minutos: minutos,
          goles: goles,
          asistencias: asis,
        ),
      );
}

/// Lee el club real de Firestore. Las colecciones y campos son los que
/// escribe `tool/seed_firestore.mjs`.
///
/// Alcance de esta primera versión: trae todo desde Firestore, pero las
/// acciones en vivo (goles, tarjetas, cambios de un partido; marcar
/// asistencia; guardar una alineación nueva; enviar convocatoria) todavía
/// solo modifican el estado en memoria, igual que en la demo — persistirlas
/// de vuelta a Firestore es un paso aparte, no incluido acá.
class EquipoRepositorioFirestore implements EquipoRepositorio {
  EquipoRepositorioFirestore({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<({String nombreClub, String categoria})> cargarClub() async {
    final doc = await _db.collection('club').doc('config').get();
    final d = doc.data() ?? const <String, dynamic>{};
    return (
      nombreClub: d['nombreClub'] as String? ?? 'Club',
      categoria: d['categoria'] as String? ?? '',
    );
  }

  @override
  Future<List<Jugador>> cargarPlantel() async {
    final snap = await _db.collection('jugadores').orderBy('id').get();
    return snap.docs.map(_jugadorDesde).toList();
  }

  Jugador _jugadorDesde(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final est = (d['estadisticas'] as Map<String, dynamic>?) ?? const {};
    final atributos = (d['atributos'] as Map<String, dynamic>?) ?? const {};
    return Jugador(
      id: d['id'] as int,
      dorsal: d['dorsal'] as int,
      nombre: d['nombre'] as String,
      posicion: Posicion.values.byName(d['posicion'] as String),
      detallePosicion: d['detallePosicion'] as String,
      edad: d['edad'] as int,
      pieHabil: d['pieHabil'] as String,
      estado: EstadoFisico.values.byName(d['estado'] as String? ?? 'apto'),
      atributos: atributos.map((k, v) => MapEntry(k, v as int)),
      estadisticas: Estadisticas(
        partidos: est['partidos'] as int? ?? 0,
        minutos: est['minutos'] as int? ?? 0,
        goles: est['goles'] as int? ?? 0,
        asistencias: est['asistencias'] as int? ?? 0,
        amarillas: est['amarillas'] as int? ?? 0,
      ),
    );
  }

  @override
  Future<List<Partido>> cargarPartidos() async {
    final snap = await _db.collection('partidos').orderBy('fecha').get();
    return snap.docs.map((doc) {
      final d = doc.data();
      return Partido(
        id: d['id'] as int,
        rival: d['rival'] as String,
        fecha: (d['fecha'] as Timestamp).toDate(),
        sede: d['sede'] as String,
        competencia: d['competencia'] as String,
        local: d['local'] as bool? ?? true,
      );
    }).toList();
  }

  @override
  Future<List<SesionEntrenamiento>> cargarSesiones() async {
    final snap = await _db.collection('sesiones').orderBy('fecha').get();
    return snap.docs.map((doc) {
      final d = doc.data();
      final sesion = SesionEntrenamiento(
        id: d['id'] as int,
        titulo: d['titulo'] as String,
        fecha: (d['fecha'] as Timestamp).toDate(),
        lugar: d['lugar'] as String,
        tipo: TipoSesion.values.byName(d['tipo'] as String? ?? 'entrenamiento'),
      );
      final asistencia = (d['asistencia'] as Map<String, dynamic>?) ?? const {};
      for (final e in asistencia.entries) {
        sesion.marcar(int.parse(e.key), e.value as bool);
      }
      return sesion;
    }).toList();
  }

  @override
  Future<CajaMensual> cargarCaja(List<Jugador> plantel) async {
    // Se traen todos los períodos (son pocos, uno por mes) y se elige el más
    // reciente ordenando el id en el cliente — así no hace falta declarar un
    // índice compuesto en Firestore solo para esto.
    final periodos = await _db.collection('caja').get();
    if (periodos.docs.isEmpty) return CajaMensual(periodo: '', cuotas: const []);
    var periodoDoc = periodos.docs.first;
    for (final d in periodos.docs.skip(1)) {
      if (d.id.compareTo(periodoDoc.id) > 0) periodoDoc = d;
    }
    final cuotasSnap = await periodoDoc.reference.collection('cuotas').get();
    final cuotas = cuotasSnap.docs.map((doc) {
      final d = doc.data();
      return Cuota(
        jugadorId: d['jugadorId'] as int,
        periodo: d['periodo'] as String,
        monto: d['monto'] as int,
        estado: EstadoCuota.values.byName(d['estado'] as String),
      );
    }).toList();
    return CajaMensual(periodo: (periodoDoc.data())['periodo'] as String? ?? periodoDoc.id, cuotas: cuotas);
  }

  @override
  Future<List<Alineacion>> cargarAlineaciones(List<Jugador> plantel) async {
    final snap = await _db.collection('alineaciones').orderBy('creada', descending: true).get();
    final porId = {for (final j in plantel) j.id: j};
    return snap.docs.map((doc) {
      final d = doc.data();
      final formacion = Formacion.presets.firstWhere(
        (f) => f.nombre == d['formacion'],
        orElse: () => Formacion.presets.first,
      );
      final titulares = (d['titulares'] as List<dynamic>? ?? const [])
          .map((t) => porId[(t as Map<String, dynamic>)['jugadorId'] as int])
          .whereType<Jugador>()
          .toList();
      return Alineacion(
        id: d['id'] as int,
        nombre: d['nombre'] as String,
        formacion: formacion,
        once: titulares,
        creada: (d['creada'] as Timestamp).toDate(),
        publicada: d['publicada'] as bool? ?? false,
      );
    }).toList();
  }
}
