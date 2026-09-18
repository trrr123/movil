// Verifica el estado vacío nuevo del Plantel: si la búsqueda no encuentra a
// nadie, se muestra un mensaje en vez de dejar la lista en blanco.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:makuira_gestion/datos/repositorios.dart';
import 'package:makuira_gestion/main.dart';
import 'package:makuira_gestion/servicios/auth_servicio.dart';

Widget _appDemo() => AppMakuira(auth: AuthEnMemoria(), repositorios: Repositorios.demo());

void main() {
  testWidgets('buscar un jugador que no existe muestra el estado vacío', (tester) async {
    await tester.pumpWidget(_appDemo());
    await tester.pumpAndSettle(const Duration(milliseconds: 6300));

    await tester.ensureVisible(find.text('dt@makuira.co'));
    await tester.tap(find.text('dt@makuira.co'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 2500));

    await tester.tap(find.text('PLANTEL'));
    await tester.pumpAndSettle();

    expect(find.text('SIN RESULTADOS'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzzzz-nadie-se-llama-asi');
    await tester.pumpAndSettle();

    expect(find.text('SIN RESULTADOS'), findsOneWidget);
  });
}
