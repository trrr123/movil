import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../modelos/usuario.dart';

/// Error de dominio: la UI lo muestra tal cual, sin inventar textos.
class ErrorAutenticacion implements Exception {
  const ErrorAutenticacion(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Contrato de autenticación: hoy en memoria, mañana Firebase o API propia.
abstract class AuthServicio {
  Usuario? get usuarioActual;
  Future<Usuario> ingresar({required String correo, required String clave});
  void salir();
}

class AuthEnMemoria implements AuthServicio {
  AuthEnMemoria({List<Usuario>? usuarios}) : _usuarios = usuarios ?? cuentasDemo();

  final List<Usuario> _usuarios;
  Usuario? _actual;

  @override
  Usuario? get usuarioActual => _actual;

  List<Usuario> get usuarios => List.unmodifiable(_usuarios);

  @override
  Future<Usuario> ingresar({required String correo, required String clave}) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final u = _usuarios.where((x) => x.correo == correo.toLowerCase().trim()).firstOrNull;
    if (u == null) throw const ErrorAutenticacion('No encontramos ese correo en el club.');
    if (!u.verificarClave(clave)) throw const ErrorAutenticacion('Contraseña incorrecta.');
    _actual = u;
    return u;
  }

  @override
  void salir() => _actual = null;

  static List<Usuario> cuentasDemo() => [
        DirectorTecnico(correo: 'dt@makuira.co', clave: '1234', nombre: 'Prof. Carrillo'),
        JugadorUsuario(
          correo: 'zuniga@makuira.co',
          clave: '1234',
          nombre: 'L. Zúñiga',
          jugadorId: 8,
          dorsal: 10,
          puesto: 'Enganche',
        ),
      ];
}

/// Autenticación real con Firebase Auth. La clave la valida Firebase, no
/// [Usuario.verificarClave] (por eso se construye con `clave: ''`: ese campo
/// queda vestigial acá, solo lo usa [AuthEnMemoria]).
///
/// El rol y los datos de perfil (jugadorId, dorsal, puesto, etc.) viven en
/// Firestore, en `usuarios/{uid}` — los escribe `tool/seed_firestore.mjs`
/// para las cuentas demo, o se crean a mano para cuentas nuevas.
class AuthFirebase implements AuthServicio {
  AuthFirebase({fb.FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  Usuario? _actual;

  @override
  Usuario? get usuarioActual => _actual;

  @override
  Future<Usuario> ingresar({required String correo, required String clave}) async {
    final fb.UserCredential cred;
    try {
      cred = await _auth.signInWithEmailAndPassword(email: correo.trim(), password: clave.trim());
    } on fb.FirebaseAuthException catch (e) {
      throw ErrorAutenticacion(_mensaje(e));
    }

    final uid = cred.user!.uid;
    final doc = await _firestore.collection('usuarios').doc(uid).get();
    final datos = doc.data();
    if (datos == null) {
      await _auth.signOut();
      throw const ErrorAutenticacion('Tu cuenta no tiene un perfil configurado en el club.');
    }

    _actual = _usuarioDesde(correo: correo, datos: datos);
    return _actual!;
  }

  Usuario _usuarioDesde({required String correo, required Map<String, dynamic> datos}) {
    final rol = datos['rol'] as String;
    if (rol == 'dt') {
      return DirectorTecnico(
        correo: correo,
        clave: '',
        nombre: datos['nombre'] as String,
        categoria: datos['categoria'] as String? ?? 'Sub-20',
      );
    }
    return JugadorUsuario(
      correo: correo,
      clave: '',
      nombre: datos['nombre'] as String,
      jugadorId: int.parse(datos['jugadorId'] as String),
      dorsal: datos['dorsal'] as int,
      puesto: datos['puesto'] as String,
    );
  }

  @override
  void salir() {
    _actual = null;
    _auth.signOut();
  }

  String _mensaje(fb.FirebaseAuthException e) => switch (e.code) {
        'user-not-found' || 'invalid-email' => 'No encontramos ese correo en el club.',
        'wrong-password' || 'invalid-credential' => 'Contraseña incorrecta.',
        'too-many-requests' => 'Demasiados intentos. Probá de nuevo en un rato.',
        _ => e.message ?? 'No se pudo iniciar sesión.',
      };
}
