// Verifica el margen de error al arrastrar una ficha en la pizarra: tocar
// cerca del borde del área (no solo la camiseta o el nombre pintados) debe
// arrancar el movimiento igual.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:makuira_gestion/modelos/alineacion.dart';
import 'package:makuira_gestion/modelos/jugador.dart';
import 'package:makuira_gestion/pantallas/pizarra_pantalla.dart';

void main() {
  testWidgets('arrastrar cerca del borde del área táctil también mueve la ficha', (tester) async {
    final jugador = Jugador(
      id: 1,
      dorsal: 10,
      nombre: 'Jugador Prueba',
      posicion: Posicion.delantero,
      detallePosicion: 'Delantero',
      edad: 20,
      pieHabil: 'Derecho',
    );
    final alineacion = Alineacion(
      id: 1,
      nombre: 'Prueba',
      formacion: Formacion.f433,
      once: [jugador],
      creada: DateTime(2026),
    );

    int? jugadorMovido;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 300,
          height: 400,
          child: CanchaWidget(
            alineacion: alineacion,
            editable: true,
            onMover: (id, destino) => jugadorMovido = id,
          ),
        ),
      ),
    ));

    final punto = alineacion.fichas.first.punto;
    final centro = Offset(punto.x * 300, punto.y * 400);
    // Esquina del área táctil (48×60 alrededor del centro): fuera de la
    // camiseta (32×32) y de la etiqueta con el nombre, dentro del margen de
    // error que se agregó.
    final bordeAreaToque = centro + const Offset(-22, -27);

    await tester.dragFrom(bordeAreaToque, const Offset(5, 5));
    await tester.pump();

    expect(jugadorMovido, jugador.id);
  });
}
