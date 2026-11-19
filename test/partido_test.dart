// Partido completo desde la fachada: gol con asistencia, tarjeta, cambio y
// final. Verifica que las estadísticas se sumen y que se manden a guardar.

import 'package:flutter_test/flutter_test.dart';

import 'package:makuira_gestion/datos/jugador_repositorio.dart';
import 'package:makuira_gestion/datos/partido_repositorio.dart';
import 'package:makuira_gestion/datos/repositorios.dart';
import 'package:makuira_gestion/estado/app_estado.dart';
import 'package:makuira_gestion/modelos/jugador.dart';
import 'package:makuira_gestion/modelos/partido.dart';
import 'package:makuira_gestion/servicios/auth_servicio.dart';

class _JugadoresGuardados extends JugadorRepositorioDemo {
  final guardados = <Jugador>{};

  @override
  Future<void> guardarEstadisticas(Iterable<Jugador> jugadores) async => guardados.addAll(jugadores);
}

class _PartidosGuardados extends PartidoRepositorioDemo {
  final resultados = <Partido>[];
  final creados = <Partido>[];

  @override
  Future<void> guardarResultado(Partido partido) async => resultados.add(partido);

  @override
  Future<void> crear(Partido partido) async => creados.add(partido);
}

Future<(AppEstado, _JugadoresGuardados, _PartidosGuardados)> _dtConectado() async {
  final jugadores = _JugadoresGuardados();
  final partidos = _PartidosGuardados();
  final demo = Repositorios.demo();
  final estado = AppEstado(
    auth: AuthEnMemoria(),
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
  await estado.ingresar('dt@makuira.co', '1234');
  return (estado, jugadores, partidos);
}

void main() {
  test('jugar y finalizar un partido suma y guarda las estadísticas', () async {
    final (estado, jugadores, partidos) = await _dtConectado();
    final p = estado.partidoActual!;
    final goleador = estado.enCancha[9];
    final asistente = estado.enCancha[8];
    final amonestado = estado.enCancha[3];
    final golesAntes = goleador.estadisticas.goles;
    final asistAntes = asistente.estadisticas.asistencias;
    final amarillasAntes = amonestado.estadisticas.amarillas;
    final partidosAntes = goleador.estadisticas.partidos;

    estado.iniciarPartido(p);
    expect(p.enJuego, isTrue);

    estado.anotarGol(p, autor: goleador, asistente: asistente);
    estado.anotarGol(p, rival: true);
    estado.anotarTarjeta(p, amonestado);
    final suplente = estado.banca.firstWhere((j) => j.disponible);
    final sale = estado.enCancha.first;
    estado.sustituir(saleId: sale.id, entra: suplente);

    expect(p.marcador, '1 — 1');
    estado.finalizarPartido(p);
    await Future<void>.delayed(Duration.zero);

    expect(p.finalizado, isTrue);
    expect(goleador.estadisticas.goles, golesAntes + 1);
    expect(asistente.estadisticas.asistencias, asistAntes + 1);
    expect(amonestado.estadisticas.amarillas, amarillasAntes + 1);
    expect(goleador.estadisticas.partidos, partidosAntes + 1);
    expect(suplente.estadisticas.partidos, greaterThan(0));

    expect(partidos.resultados, [p]);
    expect(jugadores.guardados, containsAll([goleador, asistente, amonestado, sale, suplente]));

    // La agenda pasa al siguiente partido.
    expect(estado.partidoActual?.id, isNot(p.id));
    estado.dispose();
  });

  test('el DT programa un partido y queda en la agenda', () async {
    final (estado, _, partidos) = await _dtConectado();
    await estado.programarPartido(
      rival: 'Real Maicao',
      fecha: DateTime(2026, 9, 1, 15),
      sede: 'Cancha Makuira',
      competencia: '',
      local: true,
    );
    expect(partidos.creados.single.rival, 'Real Maicao');
    expect(partidos.creados.single.competencia, 'Amistoso');
    // Es el más próximo de la agenda demo, así que pasa a ser el actual.
    expect(estado.partidoActual?.rival, 'Real Maicao');
    estado.dispose();
  });
}
