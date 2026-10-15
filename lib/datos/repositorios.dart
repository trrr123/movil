import 'alineacion_repositorio.dart';
import 'caja_repositorio.dart';
import 'club_repositorio.dart';
import 'escuela_activa.dart';
import 'escuela_repositorio.dart';
import 'foto_repositorio.dart';
import 'inscripcion_repositorio.dart';
import 'jugador_repositorio.dart';
import 'partido_repositorio.dart';
import 'sesion_repositorio.dart';

/// Agrupa los repositorios en un solo objeto para no alargar el constructor
/// de [AppEstado] ni el de la app: agregar una entidad nueva es agregar un
/// campo acá, sin tocar quien la inyecta.
///
/// Los del club (plantel, partidos, caja…) leen de la [escuela] activa; los
/// de la plataforma (escuelas, inscripciones, fotos) son globales.
class Repositorios {
  const Repositorios({
    required this.escuela,
    required this.club,
    required this.jugadores,
    required this.partidos,
    required this.sesiones,
    required this.caja,
    required this.alineaciones,
    required this.escuelas,
    required this.inscripciones,
    required this.fotos,
  });

  factory Repositorios.demo() => Repositorios(
        escuela: EscuelaActiva(),
        club: ClubRepositorioDemo(),
        jugadores: JugadorRepositorioDemo(),
        partidos: PartidoRepositorioDemo(),
        sesiones: SesionRepositorioDemo(),
        caja: CajaRepositorioDemo(),
        alineaciones: AlineacionRepositorioDemo(),
        escuelas: EscuelaRepositorioDemo(),
        inscripciones: InscripcionRepositorioDemo(),
        fotos: FotoRepositorioDemo(),
      );

  /// [escuela] permite armar un juego de repositorios que lea otra escuela
  /// (el panel del acudiente lo usa para cada hijo) sin tocar la activa.
  factory Repositorios.firestore({EscuelaActiva? escuela}) {
    final activa = escuela ?? EscuelaActiva();
    return Repositorios(
      escuela: activa,
      club: ClubRepositorioFirestore(activa),
      jugadores: JugadorRepositorioFirestore(activa),
      partidos: PartidoRepositorioFirestore(activa),
      sesiones: SesionRepositorioFirestore(activa),
      caja: CajaRepositorioFirestore(activa),
      alineaciones: AlineacionRepositorioFirestore(activa),
      escuelas: EscuelaRepositorioFirestore(),
      inscripciones: InscripcionRepositorioFirestore(),
      fotos: FotoRepositorioFirestore(),
    );
  }

  final EscuelaActiva escuela;
  final ClubRepositorio club;
  final JugadorRepositorio jugadores;
  final PartidoRepositorio partidos;
  final SesionRepositorio sesiones;
  final CajaRepositorio caja;
  final AlineacionRepositorio alineaciones;
  final EscuelaRepositorio escuelas;
  final InscripcionRepositorio inscripciones;
  final FotoRepositorio fotos;

  /// Mismo tipo de repositorios (demo o Firestore) pero apuntando a otra escuela.
  Repositorios paraEscuela(String escuelaId) {
    if (club is ClubRepositorioDemo) return this;
    return Repositorios.firestore(escuela: EscuelaActiva()..id = escuelaId);
  }
}
