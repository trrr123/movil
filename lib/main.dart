import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/tema_modernista.dart';
import 'datos/repositorios.dart';
import 'estado/app_estado.dart';
import 'firebase_options.dart';
import 'pantallas/login_pantalla.dart';
import 'pantallas/shell_pantalla.dart';
import 'pantallas/splash_pantalla.dart';
import 'servicios/auth_servicio.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AppMakuira());
}

class AppMakuira extends StatefulWidget {
  const AppMakuira({super.key, this.auth, this.repositorios});

  /// Permite inyectar servicios demo en los tests, sin pasar por Firebase.
  final AuthServicio? auth;
  final Repositorios? repositorios;

  @override
  State<AppMakuira> createState() => _AppMakuiraState();
}

class _AppMakuiraState extends State<AppMakuira> {
  late final AppEstado _estado = AppEstado(
    auth: widget.auth ?? AuthFirebase(),
    repositorios: widget.repositorios ?? Repositorios.firestore(),
  );

  @override
  void initState() {
    super.initState();
    _estado.cargarClub();
  }

  @override
  void dispose() {
    _estado.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlcanceApp(
      estado: _estado,
      child: MaterialApp(
        title: 'Makuira · Gestión',
        debugShowCheckedModeBanner: false,
        theme: TemaModernista.construir(),
        home: const _Puerta(),
      ),
    );
  }
}

/// Decide qué ve el usuario: animación de entrada → login → app por rol.
class _Puerta extends StatefulWidget {
  const _Puerta();

  @override
  State<_Puerta> createState() => _PuertaState();
}

class _PuertaState extends State<_Puerta> {
  bool _intro = true;

  @override
  Widget build(BuildContext context) {
    if (_intro) {
      return SplashPantalla(onTerminar: () => setState(() => _intro = false));
    }
    final estado = AlcanceApp.de(context);
    if (estado.cargandoClub) return const _CargandoPantalla();
    if (!estado.autenticado) return const LoginPantalla();
    if (estado.cargandoDatos) return const _CargandoPantalla();
    return const ShellPantalla();
  }
}

/// Se ve mientras se trae el club (antes de login) o el resto de los datos
/// (justo después de un login exitoso) — en la práctica, un instante.
class _CargandoPantalla extends StatelessWidget {
  const _CargandoPantalla();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: TemaModernista.fondo,
        body: const Center(
          child: CircularProgressIndicator(color: TemaModernista.acento),
        ),
      );
}
