import 'package:flutter/material.dart';

import '../core/tema_modernista.dart';
import '../estado/app_estado.dart';
import '../servicios/auth_servicio.dart';
import '../widgets/comunes.dart';
import '../widgets/plataforma.dart';
import 'registro_pantalla.dart';

/// Puerta de entrada: hero oscuro + formulario limpio. Correo/contraseña o
/// Google; quien no tiene cuenta pasa a [RegistroPantalla].
class LoginPantalla extends StatefulWidget {
  const LoginPantalla({super.key});

  @override
  State<LoginPantalla> createState() => _LoginPantallaState();
}

class _LoginPantallaState extends State<LoginPantalla> {
  final _correo = TextEditingController();
  final _clave  = TextEditingController();
  String? _error;
  bool    _cargando = false;
  bool    _cargandoGoogle = false;

  @override
  void dispose() {
    _correo.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<void> _entrar(AppEstado estado, {String? correo, String? clave}) async {
    final c = correo ?? _correo.text;
    final k = clave ?? _clave.text;
    if (c.trim().isEmpty || k.trim().isEmpty) {
      setState(() => _error = 'Escribe tu correo y tu contraseña.');
      return;
    }
    setState(() {
      _cargando = true;
      _error    = null;
    });
    try {
      await estado.ingresar(c, k);
    } on ErrorAutenticacion catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _entrarConGoogle(AppEstado estado) async {
    setState(() {
      _cargandoGoogle = true;
      _error = null;
    });
    try {
      await estado.ingresarConGoogle();
    } on ErrorAutenticacion catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargandoGoogle = false);
    }
  }

  Future<void> _olvideClave(AppEstado estado) async {
    final correo = _correo.text.trim();
    if (correo.isEmpty) {
      setState(() => _error = 'Escribe tu correo arriba y vuelve a tocar “Olvidé mi contraseña”.');
      return;
    }
    try {
      await estado.restablecerClave(correo);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Te enviamos un enlace a $correo para crear una contraseña nueva.')),
      );
    } on ErrorAutenticacion catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = AlcanceApp.de(context);
    final ocupado = _cargando || _cargandoGoogle;

    return Scaffold(
      backgroundColor: TemaModernista.fondo,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Hero oscuro ──────────────────────────────────────────────
              Container(
                color: TemaModernista.fondoOscuro,
                padding: const EdgeInsets.fromLTRB(
                    TemaModernista.esp5, TemaModernista.esp5, TemaModernista.esp5, TemaModernista.esp6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const LogoMakuira(),
                        const SizedBox(width: TemaModernista.esp3),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('MAKUIRA', style: TemaModernista.titulo(15, color: Colors.white)),
                            Text('ESCUELAS DE FÚTBOL',
                                style: TemaModernista.etiqueta(color: TemaModernista.neutral400, tam: 9)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: TemaModernista.esp6),
                    Text('GESTIONA.', style: TemaModernista.titulo(44, color: Colors.white)),
                    Text('DIRIGE.', style: TemaModernista.titulo(44, color: Colors.white)),
                    Text('GANA.', style: TemaModernista.titulo(44, color: TemaModernista.acento)),
                  ],
                ),
              ),
              // ── Formulario ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(TemaModernista.esp5),
                child: ContenidoResponsivo(
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('INGRESAR', style: TemaModernista.titulo(26)),
                        const SizedBox(height: TemaModernista.esp4),
                        TextField(
                          controller: _correo,
                          decoration: const InputDecoration(labelText: 'CORREO', hintText: 'tucorreo@gmail.com'),
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: TemaModernista.esp3),
                        TextField(
                          controller: _clave,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'CONTRASEÑA'),
                          autofillHints: const [AutofillHints.password],
                          onSubmitted: (_) => _entrar(estado),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: ocupado ? null : () => _olvideClave(estado),
                            style: TextButton.styleFrom(foregroundColor: TemaModernista.neutral800),
                            child: Text('Olvidé mi contraseña', style: TemaModernista.cuerpo(tam: 12)),
                          ),
                        ),
                        if (_error != null) ...[
                          MensajeError(_error!),
                          const SizedBox(height: TemaModernista.esp3),
                        ],
                        BotonModernista(
                          _cargando ? 'Entrando…' : 'Entrar',
                          onTap: ocupado ? null : () => _entrar(estado),
                        ),
                        if (estado.soportaGoogle) ...[
                          const SizedBox(height: TemaModernista.esp3),
                          BotonGoogle(cargando: _cargandoGoogle, onTap: ocupado ? null : () => _entrarConGoogle(estado)),
                        ],
                        const SizedBox(height: TemaModernista.esp5),
                        const Regla(),
                        const SizedBox(height: TemaModernista.esp4),
                        const Kicker('¿Primera vez?'),
                        Text('Crea tu cuenta como profesor, padre de familia o estudiante.',
                            style: TemaModernista.cuerpo(tam: 12, color: TemaModernista.neutral800)),
                        const SizedBox(height: TemaModernista.esp3),
                        BotonModernista(
                          'Crear cuenta',
                          variante: VarianteBoton.secundario,
                          onTap: ocupado
                              ? null
                              : () => Navigator.of(context)
                                  .push(MaterialPageRoute<void>(builder: (_) => const RegistroPantalla())),
                        ),
                        if (estado.esAuthEnMemoria) ...[
                          const SizedBox(height: TemaModernista.esp5),
                          _AccesoDemo(onElegir: (correo) => _entrar(estado, correo: correo, clave: '1234')),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cuentas de prueba: solo aparecen con la autenticación en memoria (tests).
class _AccesoDemo extends StatelessWidget {
  const _AccesoDemo({required this.onElegir});
  final ValueChanged<String> onElegir;

  @override
  Widget build(BuildContext context) {
    final demo = AuthEnMemoria.cuentasDemo();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Kicker('Acceso de demostración'),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: TemaModernista.neutral300, width: TemaModernista.reglaFina),
          ),
          child: Column(
            children: [
              for (final u in demo) ...[
                InkWell(
                  onTap: () => onElegir(u.correo),
                  child: Padding(
                    padding: const EdgeInsets.all(TemaModernista.esp3),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 62,
                          child: Text(u.rolCorto, style: TemaModernista.etiqueta(color: TemaModernista.acento)),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u.nombre, style: TemaModernista.cuerpo()),
                              Text(u.correo,
                                  style: TemaModernista.cuerpo(tam: 11, color: TemaModernista.neutral400)),
                            ],
                          ),
                        ),
                        Text('→', style: TemaModernista.cuerpo(color: TemaModernista.neutral400)),
                      ],
                    ),
                  ),
                ),
                if (u != demo.last) const Regla(grosor: TemaModernista.reglaFina, color: TemaModernista.neutral300),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
