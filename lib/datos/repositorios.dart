import 'alineacion_repositorio.dart';
import 'caja_repositorio.dart';
import 'club_repositorio.dart';
import 'jugador_repositorio.dart';
import 'partido_repositorio.dart';
import 'sesion_repositorio.dart';

/// Agrupa los repositorios del club en un solo objeto para no alargar el
/// constructor de [AppEstado] ni el de la app: agregar una entidad nueva es
/// agregar un campo acá, sin tocar quien la inyecta.
class Repositorios {
  const Repositorios({
    required this.club,
    required this.jugadores,
    required this.partidos,
    required this.sesiones,
    required this.caja,
    required this.alineaciones,
  });

  factory Repositorios.demo() => Repositorios(
        club: ClubRepositorioDemo(),
        jugadores: JugadorRepositorioDemo(),
        partidos: PartidoRepositorioDemo(),
        sesiones: SesionRepositorioDemo(),
        caja: CajaRepositorioDemo(),
        alineaciones: AlineacionRepositorioDemo(),
      );

  factory Repositorios.firestore() => Repositorios(
        club: ClubRepositorioFirestore(),
        jugadores: JugadorRepositorioFirestore(),
        partidos: PartidoRepositorioFirestore(),
        sesiones: SesionRepositorioFirestore(),
        caja: CajaRepositorioFirestore(),
        alineaciones: AlineacionRepositorioFirestore(),
      );

  final ClubRepositorio club;
  final JugadorRepositorio jugadores;
  final PartidoRepositorio partidos;
  final SesionRepositorio sesiones;
  final CajaRepositorio caja;
  final AlineacionRepositorio alineaciones;
}
