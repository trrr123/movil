import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

import '../modelos/usuario.dart';

/// Error de dominio: la UI lo muestra tal cual, sin inventar textos.
class ErrorAutenticacion implements Exception {
  const ErrorAutenticacion(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Contrato de autenticación: en memoria para los tests, Firebase en la app.
///
/// Toda operación que deja a alguien con sesión devuelve el [Usuario] ya
/// resuelto por rol; una cuenta que todavía no eligió rol vuelve como
/// [UsuarioNuevo] y la UI le pide que lo elija con [elegirRol].
abstract class AuthServicio {
  Usuario? get usuarioActual;

  /// Sesión que quedó abierta de una ejecución anterior, si hay.
  Future<Usuario?> restaurar();
  Future<Usuario> ingresar({required String correo, required String clave});
  Future<Usuario> registrar({required String nombre, required String correo, required String clave});
  Future<Usuario> ingresarConGoogle();
  Future<Usuario> elegirRol(RolRegistro rol, {required String nombre});

  /// Vuelve a leer el perfil (ej. después de que aprobaron su escuela).
  Future<Usuario> recargar();
  Future<void> restablecerClave(String correo);
  bool get soportaGoogle;
  void salir();
}

class AuthEnMemoria implements AuthServicio {
  AuthEnMemoria({List<Usuario>? usuarios}) : _usuarios = usuarios ?? cuentasDemo();

  final List<Usuario> _usuarios;
  final Map<String, String> _claves = {};
  Usuario? _actual;

  @override
  Usuario? get usuarioActual => _actual;

  List<Usuario> get usuarios => List.unmodifiable(_usuarios);

  @override
  Future<Usuario?> restaurar() async => _actual;

  @override
  Future<Usuario> ingresar({required String correo, required String clave}) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final u = _buscar(correo);
    if (u == null) throw const ErrorAutenticacion('No encontramos ese correo.');
    final claveNueva = _claves[u.correo];
    if (claveNueva != null ? claveNueva != clave.trim() : !u.verificarClave(clave)) {
      throw const ErrorAutenticacion('Contraseña incorrecta.');
    }
    return _actual = u;
  }

  @override
  Future<Usuario> registrar({required String nombre, required String correo, required String clave}) async {
    if (_buscar(correo) != null) throw const ErrorAutenticacion('Ya existe una cuenta con ese correo.');
    final u = UsuarioNuevo(correo: correo, nombre: nombre, uid: 'mem-${_usuarios.length + 1}');
    _usuarios.add(u);
    _claves[u.correo] = clave.trim();
    return _actual = u;
  }

  @override
  bool get soportaGoogle => false;

  @override
  Future<Usuario> ingresarConGoogle() async =>
      throw const ErrorAutenticacion('Google no está disponible en el modo demo.');

  @override
  Future<Usuario> elegirRol(RolRegistro rol, {required String nombre}) async {
    final u = _actual!;
    final nuevo = switch (rol) {
      RolRegistro.profesor => ProfesorSolicitante(correo: u.correo, nombre: nombre, uid: u.uid),
      RolRegistro.acudiente => Familia(correo: u.correo, nombre: nombre, tipo: TipoFamilia.acudiente, uid: u.uid),
      RolRegistro.estudiante => Familia(correo: u.correo, nombre: nombre, tipo: TipoFamilia.estudiante, uid: u.uid),
    };
    _usuarios[_usuarios.indexOf(u)] = nuevo;
    return _actual = nuevo;
  }

  @override
  Future<Usuario> recargar() async => _actual!;

  @override
  Future<void> restablecerClave(String correo) async {}

  @override
  void salir() => _actual = null;

  Usuario? _buscar(String correo) => _usuarios.where((x) => x.correo == correo.toLowerCase().trim()).firstOrNull;

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

/// Autenticación real con Firebase Auth (correo/contraseña y Google).
///
/// Firebase solo dice *quién* es; el rol y los datos de perfil viven en
/// Firestore, en `usuarios/{uid}`. Sin ese documento la cuenta es un
/// [UsuarioNuevo]. La [Usuario.verificarClave] queda vestigial acá (se
/// construye con `clave: ''`), solo la usa [AuthEnMemoria].
class AuthFirebase implements AuthServicio {
  AuthFirebase({fb.FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  Usuario? _actual;
  bool _googleIniciado = false;

  @override
  Usuario? get usuarioActual => _actual;

  CollectionReference<Map<String, dynamic>> get _usuarios => _firestore.collection('usuarios');

  @override
  Future<Usuario?> restaurar() async {
    final user = await _auth.authStateChanges().first;
    if (user == null) return null;
    try {
      return _actual = await _perfil(user);
    } catch (_) {
      // Sin red o perfil ilegible: mejor pedir login que quedar trabado.
      await _auth.signOut();
      return null;
    }
  }

  @override
  Future<Usuario> ingresar({required String correo, required String clave}) => _conFirebase(() async {
        final cred = await _auth.signInWithEmailAndPassword(email: correo.trim(), password: clave.trim());
        return cred.user!;
      });

  @override
  Future<Usuario> registrar({required String nombre, required String correo, required String clave}) =>
      _conFirebase(() async {
        final cred = await _auth.createUserWithEmailAndPassword(email: correo.trim(), password: clave.trim());
        await cred.user!.updateDisplayName(nombre.trim());
        return cred.user!;
      });

  @override
  bool get soportaGoogle => GoogleSignIn.instance.supportsAuthenticate();

  @override
  Future<Usuario> ingresarConGoogle() => _conFirebase(() async {
        final google = GoogleSignIn.instance;
        try {
          if (!_googleIniciado) {
            await google.initialize();
            _googleIniciado = true;
          }
          final cuenta = await google.authenticate();
          final credencial = fb.GoogleAuthProvider.credential(idToken: cuenta.authentication.idToken);
          final res = await _auth.signInWithCredential(credencial);
          return res.user!;
        } on GoogleSignInException catch (e) {
          if (e.code == GoogleSignInExceptionCode.canceled) {
            throw const ErrorAutenticacion('Cancelaste el ingreso con Google.');
          }
          throw ErrorAutenticacion('No se pudo ingresar con Google: ${e.description ?? e.code.name}.');
        }
      });

  @override
  Future<Usuario> elegirRol(RolRegistro rol, {required String nombre}) async {
    final user = _auth.currentUser;
    if (user == null) throw const ErrorAutenticacion('Tu sesión se cerró. Ingresa de nuevo.');
    await _usuarios.doc(user.uid).set({
      'rol': rol.clave,
      'nombre': nombre.trim(),
      'correo': user.email ?? '',
      'creado': FieldValue.serverTimestamp(),
    });
    return _actual = await _perfil(user);
  }

  @override
  Future<Usuario> recargar() async {
    final user = _auth.currentUser;
    if (user == null) throw const ErrorAutenticacion('Tu sesión se cerró. Ingresa de nuevo.');
    return _actual = await _perfil(user);
  }

  @override
  Future<void> restablecerClave(String correo) async {
    try {
      await _auth.sendPasswordResetEmail(email: correo.trim());
    } on fb.FirebaseAuthException catch (e) {
      throw ErrorAutenticacion(_mensaje(e));
    }
  }

  @override
  void salir() {
    _actual = null;
    _auth.signOut();
    if (_googleIniciado) GoogleSignIn.instance.signOut();
  }

  /// Corre el paso de Firebase Auth, traduce sus errores y resuelve el perfil.
  Future<Usuario> _conFirebase(Future<fb.User> Function() paso) async {
    final fb.User user;
    try {
      user = await paso();
    } on fb.FirebaseAuthException catch (e) {
      throw ErrorAutenticacion(_mensaje(e));
    }
    try {
      return _actual = await _perfil(user);
    } on FirebaseException {
      await _auth.signOut();
      throw const ErrorAutenticacion('No pudimos leer tu perfil. Revisa tu conexión e intenta de nuevo.');
    }
  }

  Future<Usuario> _perfil(fb.User user) async {
    final correo = user.email ?? '';
    final d = (await _usuarios.doc(user.uid).get()).data();
    final nombreCuenta = user.displayName ?? correo.split('@').first;
    if (d == null) return UsuarioNuevo(correo: correo, nombre: nombreCuenta, uid: user.uid);

    final nombre = d['nombre'] as String? ?? nombreCuenta;
    final uid = user.uid;
    return switch (d['rol']) {
      'admin' => Administrador(correo: correo, nombre: nombre, uid: uid),
      'dt' => DirectorTecnico(
          correo: correo,
          clave: '',
          nombre: nombre,
          uid: uid,
          categoria: d['categoria'] as String? ?? 'Sub-20',
          escuelaId: d['escuelaId'] as String? ?? escuelaPorDefecto,
        ),
      'profesor' => ProfesorSolicitante(correo: correo, nombre: nombre, uid: uid),
      'acudiente' => Familia(correo: correo, nombre: nombre, tipo: TipoFamilia.acudiente, uid: uid),
      'estudiante' => await _estudiante(correo: correo, nombre: nombre, uid: uid),
      // Cuentas creadas por el seed antes del registro (rol fijo + ficha).
      'jugador' => JugadorUsuario(
          correo: correo,
          clave: '',
          nombre: nombre,
          uid: uid,
          jugadorId: int.parse('${d['jugadorId']}'),
          dorsal: d['dorsal'] as int? ?? 0,
          puesto: d['puesto'] as String? ?? '',
          escuelaId: d['escuelaId'] as String? ?? escuelaPorDefecto,
        ),
      _ => UsuarioNuevo(correo: correo, nombre: nombre, uid: uid),
    };
  }

  /// Un estudiante con una inscripción propia aprobada ya tiene ficha: entra
  /// como [JugadorUsuario] de esa escuela. Si no, sigue buscando escuela.
  Future<Usuario> _estudiante({required String correo, required String nombre, required String uid}) async {
    final sinFicha = Familia(correo: correo, nombre: nombre, tipo: TipoFamilia.estudiante, uid: uid);
    final snap = await _firestore
        .collection('inscripciones')
        .where('solicitanteUid', isEqualTo: uid)
        .where('estado', isEqualTo: 'aprobada')
        .get();
    final propia = snap.docs.map((d) => d.data()).where((d) => d['paraSiMismo'] == true).firstOrNull;
    if (propia == null) return sinFicha;

    final escuelaId = propia['escuelaId'] as String;
    final jugadorId = propia['jugadorId'] as int;
    final ficha =
        (await _firestore.collection('escuelas').doc(escuelaId).collection('jugadores').doc('$jugadorId').get())
            .data();
    if (ficha == null) return sinFicha;
    return JugadorUsuario(
      correo: correo,
      clave: '',
      nombre: nombre,
      uid: uid,
      jugadorId: jugadorId,
      dorsal: ficha['dorsal'] as int? ?? 0,
      puesto: ficha['detallePosicion'] as String? ?? '',
      escuelaId: escuelaId,
    );
  }

  String _mensaje(fb.FirebaseAuthException e) => switch (e.code) {
        'user-not-found' => 'No encontramos ese correo.',
        'invalid-email' => 'Ese correo no es válido.',
        'wrong-password' || 'invalid-credential' => 'Correo o contraseña incorrectos.',
        'email-already-in-use' => 'Ya existe una cuenta con ese correo. Ingresa con él.',
        'weak-password' => 'La contraseña debe tener al menos 6 caracteres.',
        'account-exists-with-different-credential' =>
          'Ese correo ya está registrado con contraseña. Ingresa con correo y contraseña.',
        'too-many-requests' => 'Demasiados intentos. Prueba de nuevo en un rato.',
        'network-request-failed' => 'Sin conexión. Revisa tu internet.',
        _ => e.message ?? 'No se pudo completar el ingreso.',
      };
}
