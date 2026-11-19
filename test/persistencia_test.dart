// Casos límite de lo que el DT guarda: partido retomado tras cerrar la app,
// convocatoria (solo cita a quien el DT envió) y estado físico.

import 'package:flutter_test/flutter_test.dart';

import 'package:makuira_gestion/datos/jugador_repositorio.dart';
import 'package:makuira_gestion/datos/partido_repositorio.dart';
import 'package:makuira_gestion/datos/repositorios.dart';
import 'package:makuira_gestion/estado/app_estado.dart';
import 'package:makuira_gestion/modelos/finanzas.dart';
import 'package:makuira_gestion/modelos/jugador.dart';
import 'package:makuira_gestion/modelos/partido.dart';
import 'package:makuira_gestion/servicios/auth_servicio.dart';

/// Simula Firestore: guarda lo que la app escribe y lo devuelve al recargar.
class _PartidosPersistentes extends PartidoRepositorioDemo {
  final Map<int, Map<String, Object?>> enVivo = {};
  final Map<int, int> minutos = {};
  final Map<int, Convocatoria> convocatorias = {};
  final resultados = <int>[];

  @override
  Future<List<Partido>> cargarPartidos(List<Jugador> plantel) async {
    final lista = await super.cargarPartidos(plantel);
    for (final p in lista) {
      final d = enVivo[p.id];
      if (d != null) p.restaurarEnVivo(Map<String, dynamic>.from(d), minuto: minutos[p.id]!, plantel: plantel);
    }
    return lista;
  }

  @override
  Future<void> guardarEnVivo(Partido p) async {
    // Como Firestore: lo guardado es una copia, no el objeto vivo.
    enVivo[p.id] = _copiaProfunda(p.aMapaEnVivo());
    minutos[p.id] = p.minuto;
  }

  @override
  Future<void> guardarResultado(Partido p) async {
    enVivo.remove(p.id);
    resultados.add(p.id);
  }

  @override
  Future<Convocatoria?> cargarConvocatoria(int partidoId) async => convocatorias[partidoId];

  @override
  Future<void> guardarConvocatoria(Convocatoria c) async => convocatorias[c.partidoId] =
      Convocatoria(partidoId: c.partidoId, llamados: c.llamados, enviada: c.enviada);

  static Map<String, Object?> _copiaProfunda(Map<String, Object?> m) => {
        for (final e in m.entries)
          e.key: switch (e.value) {
            final List<Object?> l => [for (final x in l) x is Map ? Map<String, Object?>.from(x) : x],
            final Map<Object?, Object?> mm => Map<String, Object?>.from(mm),
            final v => v,
          },
      };
}

/// El plantel se "guarda" en memoria: la misma lista sobrevive a recargas,
/// como los documentos de Firestore (con estadísticas y estado físico).
class _JugadoresPersistentes extends JugadorRepositorioDemo {
  List<Jugador>? _guardado;
  final estadisticasGuardadas = <int>{};
  final estadosGuardados = <int, EstadoFisico>{};

  @override
  Future<List<Jugador>> cargarPlantel() async {
    final base = await super.cargarPlantel();
    // Reconstruye cada jugador desde lo "guardado" (copia, no el mismo objeto).
    return [
      for (final j in base)
        Jugador(
          id: j.id,
          dorsal: j.dorsal,
          nombre: j.nombre,
          posicion: j.posicion,
          detallePosicion: j.detallePosicion,
          edad: j.edad,
          pieHabil: j.pieHabil,
          estado: estadosGuardados[j.id] ?? j.estado,
          estadisticas: _guardado?.firstWhere((g) => g.id == j.id).estadisticas ?? j.estadisticas,
        ),
    ];
  }

  @override
  Future<void> guardarEstadisticas(Iterable<Jugador> jugadores) async {
    _guardado ??= await super.cargarPlantel();
    for (final j in jugadores) {
      estadisticasGuardadas.add(j.id);
      final i = _guardado!.indexWhere((g) => g.id == j.id);
      _guardado![i] = j;
    }
  }

  @override
  Future<void> guardarEstadoFisico(Jugador j) async => estadosGuardados[j.id] = j.estado;
}

Future<AppEstado> _entrar(String correo, _PartidosPersistentes partidos, _JugadoresPersistentes jugadores,
    {AuthEnMemoria? auth}) async {
  final demo = Repositorios.demo();
  final estado = AppEstado(
    auth: auth ?? AuthEnMemoria(),
    repositorios: Repositorios(
      escuela: demo.escuela,
      club: demo.club,
      jugadores: jugadores,
      partidos: partidos,
      sesiones: demo.sesiones,
      caja: demo.caja,
      alineaciones: demo.alineaciones,
      escuelas: demo.escuelas,
      inscripciones: demo.inscripciones,
      fotos: demo.fotos,
    ),
  );
  await estado.ingresar(correo, '1234');
  return estado;
}

Future<void> _esperarGuardados() => Future<void>.delayed(Duration.zero);

void main() {
  test('si la app se cierra a mitad del partido, se retoma sin perder ni duplicar nada', () async {
    final partidos = _PartidosPersistentes();
    final jugadores = _JugadoresPersistentes();

    // Primera sesión: arranca el partido, gol con asistencia, amarilla, cambio.
    final antes = await _entrar('dt@makuira.co', partidos, jugadores);
    final p1 = antes.partidoActual!;
    final goleador = antes.enCancha[9];
    final asistente = antes.enCancha[8];
    final amonestado = antes.enCancha[3];
    final sale = antes.enCancha[0];
    final entra = antes.banca.firstWhere((j) => j.disponible);
    final golesAntes = goleador.estadisticas.goles;
    final asistAntes = asistente.estadisticas.asistencias;
    final amarillasAntes = amonestado.estadisticas.amarillas;

    antes.iniciarPartido(p1);
    antes.corregirMinuto(p1, 30);
    antes.anotarGol(p1, autor: goleador, asistente: asistente);
    antes.anotarTarjeta(p1, amonestado);
    antes.corregirMinuto(p1, 10);
    antes.sustituir(saleId: sale.id, entra: entra);
    antes.anotarGol(p1, rival: true);
    await _esperarGuardados();
    // Las estadísticas no se tocan durante el partido (se suman al final).
    expect(goleador.estadisticas.goles, golesAntes);
    antes.dispose(); // la app se cierra sin finalizar

    // Segunda sesión: el partido vuelve en pausa, con su acta y su minuto.
    final despues = await _entrar('dt@makuira.co', partidos, jugadores);
    final p2 = despues.partidoActual!;
    expect(p2.id, p1.id);
    expect(p2.estado, EstadoPartido.entretiempo);
    expect(p2.minuto, 40);
    expect(p2.marcador, '1 — 1');
    expect(p2.eventos, hasLength(4));

    despues.alternarReloj(p2); // "Seguir"
    expect(p2.enJuego, isTrue);
    despues.corregirMinuto(p2, 50); // minuto 90
    despues.finalizarPartido(p2);
    await _esperarGuardados();

    final porId = {for (final j in despues.plantel) j.id: j};
    expect(porId[goleador.id]!.estadisticas.goles, golesAntes + 1);
    expect(porId[asistente.id]!.estadisticas.asistencias, asistAntes + 1);
    expect(porId[amonestado.id]!.estadisticas.amarillas, amarillasAntes + 1);
    // El que salió jugó 40', el que entró 50'.
    expect(porId[sale.id]!.estadisticas.minutos - sale.estadisticas.minutos, 40);
    expect(porId[entra.id]!.estadisticas.minutos - entra.estadisticas.minutos, 50);
    expect(partidos.resultados, [p1.id]);
    expect(partidos.enVivo, isEmpty);
    // Finalizar dos veces no suma dos veces.
    despues.finalizarPartido(p2);
    expect(porId[goleador.id]!.estadisticas.goles, golesAntes + 1);
    despues.dispose();
  });

  test('el jugador solo se ve convocado cuando el DT envía, y queda guardado', () async {
    final partidos = _PartidosPersistentes();
    final jugadores = _JugadoresPersistentes();
    final auth = AuthEnMemoria();

    final dt = await _entrar('dt@makuira.co', partidos, jugadores, auth: auth);
    final zuniga = dt.plantel.firstWhere((j) => j.id == 8);
    // La propuesta inicial lo incluye, pero aún no está enviada.
    expect(dt.convocatoria!.incluye(zuniga.id), isTrue);
    expect(dt.convocatoria!.enviada, isFalse);
    dt.alternarConvocado(zuniga); // lo saca
    dt.alternarConvocado(zuniga); // lo vuelve a meter
    dt.enviarConvocatoria();
    await _esperarGuardados();
    final guardada = partidos.convocatorias[dt.partidoActual!.id]!;
    expect(guardada.enviada, isTrue);
    expect(guardada.incluye(zuniga.id), isTrue);
    dt.dispose();

    final jugador = await _entrar('zuniga@makuira.co', partidos, jugadores);
    expect(jugador.estoyConvocado(), isTrue);
    jugador.dispose();

    // Si el DT lo saca después de enviar, el jugador deja de verse convocado.
    final dt2 = await _entrar('dt@makuira.co', partidos, jugadores);
    dt2.alternarConvocado(dt2.plantel.firstWhere((j) => j.id == 8));
    await _esperarGuardados();
    dt2.dispose();
    final jugador2 = await _entrar('zuniga@makuira.co', partidos, jugadores);
    expect(jugador2.estoyConvocado(), isFalse);
    jugador2.dispose();
  });

  test('el estado físico se guarda, y un lesionado sale de la convocatoria', () async {
    final partidos = _PartidosPersistentes();
    final jugadores = _JugadoresPersistentes();

    final dt = await _entrar('dt@makuira.co', partidos, jugadores);
    final j = dt.plantel.firstWhere((x) => x.estado == EstadoFisico.apto && dt.convocatoria!.incluye(x.id));
    dt.cambiarEstadoFisico(j); // apto → carga
    dt.cambiarEstadoFisico(j); // carga → lesión
    await _esperarGuardados();
    expect(jugadores.estadosGuardados[j.id], EstadoFisico.lesionado);
    expect(dt.convocatoria!.incluye(j.id), isFalse);
    dt.dispose();

    final otraVez = await _entrar('dt@makuira.co', partidos, jugadores);
    expect(otraVez.plantel.firstWhere((x) => x.id == j.id).estado, EstadoFisico.lesionado);
    otraVez.dispose();
  });

  test('un jugador no puede tocar partido, convocatoria ni estado físico', () async {
    final partidos = _PartidosPersistentes();
    final jugadores = _JugadoresPersistentes();
    final jugador = await _entrar('zuniga@makuira.co', partidos, jugadores);
    final p = jugador.partidoActual!;
    final alguien = jugador.plantel.first;

    jugador.iniciarPartido(p);
    jugador.alternarConvocado(alguien);
    jugador.enviarConvocatoria();
    jugador.cambiarEstadoFisico(alguien);
    await jugador.programarPartido(
        rival: 'X', fecha: DateTime(2026), sede: 'X', competencia: '', local: true);
    await _esperarGuardados();

    expect(p.programado, isTrue);
    expect(partidos.enVivo, isEmpty);
    expect(partidos.convocatorias, isEmpty);
    expect(jugadores.estadosGuardados, isEmpty);
    expect(jugador.partidos, hasLength(2));
    jugador.dispose();
  });
}
