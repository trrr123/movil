// Flujo de registro: crear cuenta → elegir rol → pantalla según el rol.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:makuira_gestion/datos/repositorios.dart';
import 'package:makuira_gestion/main.dart';
import 'package:makuira_gestion/servicios/auth_servicio.dart';

Widget _appDemo() => AppMakuira(auth: AuthEnMemoria(), repositorios: Repositorios.demo());

Future<void> _crearCuenta(WidgetTester tester) async {
  await tester.pumpWidget(_appDemo());
  await tester.pumpAndSettle(const Duration(milliseconds: 6300));

  await tester.ensureVisible(find.text('Crear cuenta'));
  await tester.tap(find.text('Crear cuenta'));
  await tester.pumpAndSettle();

  final campos = find.byType(TextField);
  await tester.enterText(campos.at(0), 'Ana Pushaina');
  await tester.enterText(campos.at(1), 'ana@correo.co');
  await tester.enterText(campos.at(2), 'secreta1');
  await tester.enterText(campos.at(3), 'secreta1');
  await tester.ensureVisible(find.text('Crear cuenta').last);
  await tester.tap(find.text('Crear cuenta').last);
  await tester.pumpAndSettle();
}

Future<void> _elegir(WidgetTester tester, String opcion) async {
  await tester.ensureVisible(find.text(opcion));
  await tester.tap(find.text(opcion));
  await tester.ensureVisible(find.text('Continuar'));
  await tester.tap(find.text('Continuar'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('una cuenta nueva tiene que elegir rol', (tester) async {
    await _crearCuenta(tester);
    expect(find.text('¿QUIÉN ERES?'), findsOneWidget);
    expect(find.text('Ana Pushaina'), findsOneWidget); // nombre precargado
  });

  testWidgets('el profesor ve el formulario para registrar su escuela', (tester) async {
    await _crearCuenta(tester);
    await _elegir(tester, 'SOY PROFESOR');
    expect(find.text('REGISTRA TU ESCUELA'), findsOneWidget);

    // Sin foto del entrenador ni mapa, no deja enviar.
    await tester.enterText(find.byType(TextField).first, 'Escuela Los Wayuu');
    // El formulario es una lista perezosa: hay que desplazarse hasta el botón.
    await tester.scrollUntilVisible(find.text('Enviar solicitud'), 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Enviar solicitud'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe la dirección de la cancha.'), findsOneWidget);
  });

  testWidgets('el acudiente sin hijos ve el aviso y la lista de escuelas', (tester) async {
    await _crearCuenta(tester);
    await _elegir(tester, 'SOY PADRE O ACUDIENTE');
    expect(find.text('AÚN NO TIENES HIJOS REGISTRADOS'), findsOneWidget);
    expect(find.text('AÚN NO HAY ESCUELAS'), findsOneWidget);
  });
}
