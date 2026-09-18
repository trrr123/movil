// Tests de flujo básico de Makuira · Gestión: splash → login → shell por rol.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:makuira_gestion/datos/repositorios.dart';
import 'package:makuira_gestion/main.dart';
import 'package:makuira_gestion/servicios/auth_servicio.dart';

/// Los tests usan los servicios demo (en memoria) en vez de Firebase: no hay
/// forma de inicializar los plugins nativos en un `flutter test` sin
/// dispositivo, y no es lo que estos tests están verificando.
Widget _appDemo() => AppMakuira(auth: AuthEnMemoria(), repositorios: Repositorios.demo());

void main() {
  testWidgets('la app arranca con el splash y pasa al login', (WidgetTester tester) async {
    await tester.pumpWidget(_appDemo());

    // El splash dibuja la marca mientras corre la animación de entrada.
    expect(find.text('MAKUIRA'), findsOneWidget);
    expect(find.text('INGRESAR'), findsNothing);

    // La animación dura 6000ms; tras ese lapso el splash cede el paso al login.
    await tester.pumpAndSettle(const Duration(milliseconds: 6300));

    expect(find.text('INGRESAR'), findsOneWidget);
  });

  testWidgets('tocar la cuenta demo del DT entra a la app y muestra sus pestañas', (WidgetTester tester) async {
    await tester.pumpWidget(_appDemo());
    await tester.pumpAndSettle(const Duration(milliseconds: 6300));

    await tester.ensureVisible(find.text('dt@makuira.co'));
    await tester.tap(find.text('dt@makuira.co'));
    await tester.pumpAndSettle();
    // El aviso de "sesión iniciada" se borra solo tras 2.4s; hay que dejarlo
    // terminar para que no queden timers pendientes al cerrar el test.
    await tester.pump(const Duration(milliseconds: 2500));

    // Solo el DT ve la pestaña "Club" (finanzas del equipo); las etiquetas se
    // renderizan en mayúsculas.
    expect(find.text('CLUB'), findsOneWidget);
    expect(find.text('TÁCTICA'), findsOneWidget);
  });

  testWidgets('tocar la cuenta demo del jugador entra con pestañas limitadas', (WidgetTester tester) async {
    await tester.pumpWidget(_appDemo());
    await tester.pumpAndSettle(const Duration(milliseconds: 6300));

    await tester.ensureVisible(find.text('zuniga@makuira.co'));
    await tester.tap(find.text('zuniga@makuira.co'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 2500));

    // El jugador no ve "Club" ni "Táctica"; ve su propia ficha en "Yo".
    expect(find.text('CLUB'), findsNothing);
    expect(find.text('YO'), findsOneWidget);
  });
}
