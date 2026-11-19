// Una escuela recién aprobada no tiene partidos, entrenos, alineaciones ni
// cuotas: la app tiene que abrir igual (antes fallaba en `.first`).

import 'package:flutter_test/flutter_test.dart';

import 'package:makuira_gestion/datos/alineacion_repositorio.dart';
import 'package:makuira_gestion/datos/caja_repositorio.dart';
import 'package:makuira_gestion/datos/club_repositorio.dart';
import 'package:makuira_gestion/datos/escuela_activa.dart';
import 'package:makuira_gestion/datos/escuela_repositorio.dart';
import 'package:makuira_gestion/datos/foto_repositorio.dart';
import 'package:makuira_gestion/datos/inscripcion_repositorio.dart';
import 'package:makuira_gestion/datos/jugador_repositorio.dart';
import 'package:makuira_gestion/datos/partido_repositorio.dart';
import 'package:makuira_gestion/datos/repositorios.dart';
import 'package:makuira_gestion/datos/sesion_repositorio.dart';
import 'package:makuira_gestion/main.dart';
import 'package:makuira_gestion/modelos/alineacion.dart';
import 'package:makuira_gestion/modelos/finanzas.dart';
import 'package:makuira_gestion/modelos/jugador.dart';
import 'package:makuira_gestion/modelos/partido.dart';
import 'package:makuira_gestion/servicios/auth_servicio.dart';

// Escuela vacía: los repositorios demo (que no escriben nada) pero sin datos.
class _SinPartidos extends PartidoRepositorioDemo {
  @override
  Future<List<Partido>> cargarPartidos(List<Jugador> plantel) async => [];
}

class _SinSesiones extends SesionRepositorioDemo {
  @override
  Future<List<SesionEntrenamiento>> cargarSesiones() async => [];
}

class _SinAlineaciones extends AlineacionRepositorioDemo {
  @override
  Future<List<Alineacion>> cargarAlineaciones(List<Jugador> plantel) async => [];
}

class _SinCuotas extends CajaRepositorioDemo {
  @override
  Future<CajaMensual> cargarCaja(List<Jugador> plantel) async => CajaMensual(periodo: '', cuotas: const []);
}

class _SinJugadores extends JugadorRepositorioDemo {
  @override
  Future<List<Jugador>> cargarPlantel() async => [];
}

/// Escuela nueva. Con [conPlantel] tiene jugadores (para que el jugador demo
/// tenga ficha) pero sigue sin partidos, entrenos, alineaciones ni cuotas.
Repositorios _escuelaNueva({bool conPlantel = false}) => Repositorios(
      escuela: EscuelaActiva(),
      club: ClubRepositorioDemo(),
      jugadores: conPlantel ? JugadorRepositorioDemo() : _SinJugadores(),
      partidos: _SinPartidos(),
      sesiones: _SinSesiones(),
      caja: _SinCuotas(),
      alineaciones: _SinAlineaciones(),
      escuelas: EscuelaRepositorioDemo(),
      inscripciones: InscripcionRepositorioDemo(),
      fotos: FotoRepositorioDemo(),
    );

Future<void> _entrarComo(WidgetTester tester, String correo, Repositorios repos) async {
  await tester.pumpWidget(AppMakuira(auth: AuthEnMemoria(), repositorios: repos));
  await tester.pumpAndSettle(const Duration(milliseconds: 6300));
  await tester.ensureVisible(find.text(correo));
  await tester.tap(find.text(correo));
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 2500));
}

Future<void> _recorrerPestanas(WidgetTester tester, List<String> pestanas) async {
  for (final p in pestanas) {
    await tester.tap(find.text(p));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'falló la pestaña $p');
  }
}

void main() {
  testWidgets('el DT de una escuela vacía entra y recorre todas las pestañas', (tester) async {
    await _entrarComo(tester, 'dt@makuira.co', _escuelaNueva());

    expect(find.text('SIN PARTIDOS PROGRAMADOS'), findsOneWidget);
    await _recorrerPestanas(tester, ['PLANTEL', 'TÁCTICA', 'AGENDA', 'CLUB', 'INICIO']);
  });

  testWidgets('un jugador sin cuota ni partidos entra y ve su ficha', (tester) async {
    await _entrarComo(tester, 'zuniga@makuira.co', _escuelaNueva(conPlantel: true));

    expect(find.text('SIN PARTIDO PROGRAMADO'), findsOneWidget);
    await _recorrerPestanas(tester, ['EQUIPO', 'ALINEACIÓN', 'AGENDA', 'YO', 'INICIO']);
  });
}
