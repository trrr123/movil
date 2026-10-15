import 'finanzas.dart';
import 'jugador.dart';
import 'partido.dart';

/// Lo que un acudiente ve de su hijo: rendimiento, asistencia y deuda.
/// Se arma con datos que la escuela ya lleva; no se guarda aparte.
class ResumenJugador {
  const ResumenJugador({
    required this.jugador,
    required this.nombreEscuela,
    required this.entrenosAsistidos,
    required this.entrenosRegistrados,
    required this.cuotasPendientes,
  });

  factory ResumenJugador.calcular({
    required Jugador jugador,
    required String nombreEscuela,
    required List<SesionEntrenamiento> sesiones,
    required List<Cuota> cuotas,
  }) {
    // Solo cuentan las sesiones en que el DT tomó lista para este jugador.
    final conLista = sesiones.where((s) => s.asistencia.containsKey(jugador.id));
    return ResumenJugador(
      jugador: jugador,
      nombreEscuela: nombreEscuela,
      entrenosAsistidos: conLista.where((s) => s.asistio(jugador.id)).length,
      entrenosRegistrados: conLista.length,
      cuotasPendientes: cuotas.where((c) => c.jugadorId == jugador.id && !c.alDia).toList(),
    );
  }

  final Jugador jugador;
  final String nombreEscuela;
  final int entrenosAsistidos;
  final int entrenosRegistrados;
  final List<Cuota> cuotasPendientes;

  int get deuda => cuotasPendientes.fold(0, (a, c) => a + c.monto);
  bool get alDia => cuotasPendientes.isEmpty;
  double get porcentajeAsistencia => entrenosRegistrados == 0 ? 0 : entrenosAsistidos / entrenosRegistrados;
}
