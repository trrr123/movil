import '../modelos/finanzas.dart';
import '../modelos/jugador.dart';
import 'escuela_activa.dart';

/// Fuente de datos de la caja del club (cuotas mensuales por jugador).
abstract class CajaRepositorio {
  Future<CajaMensual> cargarCaja(List<Jugador> plantel);

  /// Crea (o completa) las cuotas de [mes] para [jugadores], todas pendientes.
  Future<void> crearCuotas(MesCobro mes, {required int monto, required List<Jugador> jugadores});

  /// Guarda el estado de una cuota (pagada, reportada) del mes [cajaId].
  Future<void> guardarEstado(String cajaId, Cuota cuota);
}

class CajaRepositorioDemo implements CajaRepositorio {
  CajaMensual? _creada;

  @override
  Future<CajaMensual> cargarCaja(List<Jugador> plantel) async =>
      _creada ??
      CajaMensual(
        id: '2026-09',
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
  Future<void> crearCuotas(MesCobro mes, {required int monto, required List<Jugador> jugadores}) async {
    final previas = _creada?.id == mes.id ? _creada!.cuotas : const <Cuota>[];
    _creada = CajaMensual(id: mes.id, periodo: mes.nombre, cuotas: [
      ...previas,
      for (final j in jugadores) Cuota(jugadorId: j.id, periodo: mes.nombre, monto: monto),
    ]);
  }

  @override
  Future<void> guardarEstado(String cajaId, Cuota cuota) async {}
}

class CajaRepositorioFirestore implements CajaRepositorio {
  CajaRepositorioFirestore(this._escuela);

  final EscuelaActiva _escuela;

  @override
  Future<CajaMensual> cargarCaja(List<Jugador> plantel) async {
    // Se traen todos los períodos (son pocos, uno por mes) y se elige el más
    // reciente ordenando el id en el cliente — así no hace falta declarar un
    // índice compuesto en Firestore solo para esto.
    final periodos = await _escuela.coleccion('caja').get();
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
    return CajaMensual(
      id: periodoDoc.id,
      periodo: (periodoDoc.data())['periodo'] as String? ?? periodoDoc.id,
      cuotas: cuotas,
    );
  }

  @override
  Future<void> crearCuotas(MesCobro mes, {required int monto, required List<Jugador> jugadores}) async {
    final caja = _escuela.coleccion('caja').doc(mes.id);
    final lote = _escuela.db.batch()..set(caja, {'periodo': mes.nombre});
    for (final j in jugadores) {
      lote.set(caja.collection('cuotas').doc('${j.id}'), {
        'jugadorId': j.id,
        'periodo': mes.nombre,
        'monto': monto,
        'estado': EstadoCuota.pendiente.name,
      });
    }
    await lote.commit();
  }

  /// Solo toca el campo `estado`: las reglas dejan que el jugador (o su
  /// acudiente) cambie únicamente eso, de pendiente a reportada.
  @override
  Future<void> guardarEstado(String cajaId, Cuota cuota) => _escuela
      .coleccion('caja')
      .doc(cajaId)
      .collection('cuotas')
      .doc('${cuota.jugadorId}')
      .update({'estado': cuota.estado.name});
}
