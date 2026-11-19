// La alineación en uso se guarda sola tras los cambios del DT, una sola vez
// aunque se arrastre mucho, y al volver a entrar queda igual que se dejó.

import 'package:flutter_test/flutter_test.dart';

import 'package:makuira_gestion/datos/alineacion_repositorio.dart';
import 'package:makuira_gestion/datos/jugador_repositorio.dart';
import 'package:makuira_gestion/estado/alineacion_controlador.dart';
import 'package:makuira_gestion/modelos/alineacion.dart';
import 'package:makuira_gestion/modelos/jugador.dart';

/// Guarda en memoria como lo haría Firestore (copia al escribir).
class _RepoEnMemoria extends AlineacionRepositorioDemo {
  Alineacion? actual;
  int escrituras = 0;

  @override
  Future<Alineacion?> cargarActual(List<Jugador> plantel) async => actual;

  @override
  Future<void> guardarActual(Alineacion a) async {
    escrituras++;
    actual = a.duplicar(nuevoId: 0, nuevoNombre: a.nombre);
  }
}

void main() {
  test('los cambios de la pizarra se guardan y se recuperan al volver a entrar', () async {
    final plantel = await JugadorRepositorioDemo().cargarPlantel();
    final repo = _RepoEnMemoria();

    final pizarra = AlineacionControlador(repo);
    await pizarra.cargar(plantel);
    final suplente = plantel.firstWhere((j) => !pizarra.activa.contiene(j.id));
    final sale = pizarra.activa.titulares.first;

    pizarra.aplicarFormacion(Formacion.f442);
    for (var i = 0; i < 20; i++) {
      pizarra.moverFicha(sale.id, PuntoCampo(0.3 + i * 0.01, 0.5));
    }
    pizarra.sustituir(saleId: sale.id, entra: suplente);
    expect(repo.escrituras, 0, reason: 'espera a que el DT termine de mover');

    await Future<void>.delayed(const Duration(milliseconds: 900));
    expect(repo.escrituras, 1);

    // "Volver a entrar": un controlador nuevo lee lo guardado.
    final otraVez = AlineacionControlador(repo);
    await otraVez.cargar(plantel);
    expect(otraVez.activa.formacion.nombre, Formacion.f442.nombre);
    expect(otraVez.activa.contiene(suplente.id), isTrue);
    expect(otraVez.activa.contiene(sale.id), isFalse);
    final ficha = otraVez.activa.fichas.firstWhere((f) => f.jugador.id == suplente.id);
    expect(ficha.punto.x, closeTo(0.49, 0.001));

    pizarra.dispose();
    otraVez.dispose();
  });
}
