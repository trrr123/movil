import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelos/finanzas.dart';
import '../modelos/jugador.dart';

/// Fuente de datos de la caja del club (cuotas mensuales por jugador).
abstract class CajaRepositorio {
  Future<CajaMensual> cargarCaja(List<Jugador> plantel);
}

class CajaRepositorioDemo implements CajaRepositorio {
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
}

class CajaRepositorioFirestore implements CajaRepositorio {
  CajaRepositorioFirestore({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

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
}
