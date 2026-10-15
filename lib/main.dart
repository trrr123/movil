import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/tema_modernista.dart';
import 'datos/repositorios.dart';
import 'estado/app_estado.dart';
import 'firebase_options.dart';
import 'modelos/usuario.dart';
import 'pantallas/admin_pantalla.dart';
import 'pantallas/elegir_rol_pantalla.dart';
import 'pantallas/familia_pantalla.dart';
import 'pantallas/login_pantalla.dart';
import 'pantallas/profesor_pantalla.dart';
import 'pantallas/shell_pantalla.dart';
import 'pantallas/splash_pantalla.dart';
import 'servicios/auth_servicio.dart';
import 'servicios/correo_servicio.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AppMakuira());
}

class AppMakuira extends StatefulWidget {
  const AppMakuira({super.key, this.auth, this.repositorios, this.correo});

  /// Permite inyectar servicios demo en los tests, sin pasar por Firebase.
  final AuthServicio? auth;
  final Repositorios? repositorios;
  final CorreoServicio? correo;

  @override
  State<AppMakuira> createState() => _AppMakuiraState();
}

class _AppMakuiraState extends State<AppMakuira> {
  late final AppEstado _estado = AppEstado(
    auth: widget.auth ?? AuthFirebase(),
    repositorios: widget.repositorios ?? Repositorios.firestore(),
    // Con servicios inyectados (tests) no se manda correo real.
    correo: widget.correo ?? (widget.auth == null ? const CorreoEmailJs() : const CorreoNulo()),
  );

  @override
  void initState() {
    super.initState();
    _estado.iniciar();
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

/// Decide qué ve el usuario: animación de entrada → login → pantalla del rol.
/// Cada subclase de [Usuario] tiene su destino (polimorfismo en la puerta).
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
    if (estado.iniciando) return const _CargandoPantalla();
    if (estado.cargandoDatos) return const _CargandoPantalla();
    return switch (estado.usuario) {
      null => const LoginPantalla(),
      UsuarioNuevo() => const ElegirRolPantalla(),
      Administrador() => const AdminPantalla(),
      ProfesorSolicitante() => const ProfesorPantalla(),
      Familia() => const FamiliaPantalla(),
      _ => const ShellPantalla(),
    };
  }
}

/// Se ve mientras se restaura la sesión o se traen los datos de la escuela
/// (justo después de entrar) — en la práctica, un instante.
class _CargandoPantalla extends StatelessWidget {
  const _CargandoPantalla();

  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: TemaModernista.fondo,
        body: Center(
          child: CircularProgressIndicator(color: TemaModernista.acento),
        ),
      );
}
