import 'package:flutter/material.dart';

import '../core/tema_modernista.dart';
import '../estado/app_estado.dart';
import '../servicios/auth_servicio.dart';
import '../widgets/comunes.dart';

/// Puerta de entrada: hero oscuro + formulario limpio.
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

  @override
  void dispose() {
    _correo.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<void> _entrar(AppEstado estado,
      {String? correo, String? clave}) async {
    setState(() {
      _cargando = true;
      _error    = null;
    });
    try {
      await estado.ingresar(correo ?? _correo.text, clave ?? _clave.text);
    } on ErrorAutenticacion catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = AlcanceApp.de(context);
    final demo   = AuthEnMemoria.cuentasDemo();

    return Scaffold(
      backgroundColor: TemaModernista.fondo,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hero oscuro ────────────────────────────────────────────────
            Container(
              color: TemaModernista.fondoOscuro,
              padding: const EdgeInsets.fromLTRB(
                  TemaModernista.esp5, TemaModernista.esp5,
                  TemaModernista.esp5, TemaModernista.esp7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo + nombre
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        color: TemaModernista.acento,
                        alignment: Alignment.center,
                        child: Text('M',
                            style: TemaModernista.titulo(20,
                                color: Colors.white)),
                      ),
                      const SizedBox(width: TemaModernista.esp3),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(estado.nombreClub.toUpperCase(),
                              style: TemaModernista.titulo(15,
                                  color: Colors.white)),
                          Text(estado.categoria.toUpperCase(),
                              style: TemaModernista.etiqueta(
                                  color: TemaModernista.neutral400, tam: 9)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: TemaModernista.esp7),
                  // Frase hero
                  Text('GESTIONA.',
                      style: TemaModernista.titulo(48, color: Colors.white)),
                  Text('DIRIGE.',
                      style: TemaModernista.titulo(48, color: Colors.white)),
                  Text('GANA.',
                      style: TemaModernista.titulo(48,
                          color: TemaModernista.acento)),
                ],
              ),
            ),
            // ── Formulario ────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    TemaModernista.esp5, TemaModernista.esp5,
                    TemaModernista.esp5, TemaModernista.esp5),
                child: ContenidoResponsivo(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('INGRESAR', style: TemaModernista.titulo(26)),
                      const SizedBox(height: TemaModernista.esp4),
                      TextField(
                        controller: _correo,
                        decoration: const InputDecoration(
                            labelText: 'CORREO',
                            hintText: 'nombre@makuira.co'),
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.username],
                      ),
                      const SizedBox(height: TemaModernista.esp3),
                      TextField(
                        controller: _clave,
                        obscureText: true,
                        decoration:
                            const InputDecoration(labelText: 'CONTRASEÑA'),
                        autofillHints: const [AutofillHints.password],
                        onSubmitted: (_) => _entrar(estado),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: TemaModernista.esp3),
                        Container(
                          padding: const EdgeInsets.only(left: 9),
                          decoration: const BoxDecoration(
                            border: Border(
                                left: BorderSide(
                                    color: TemaModernista.acento, width: 3)),
                          ),
                          child: Text(_error!,
                              style: TemaModernista.cuerpo(
                                  tam: 12,
                                  color: TemaModernista.acento700)),
                        ),
                      ],
                      const SizedBox(height: TemaModernista.esp4),
                      BotonModernista(
                        _cargando ? 'Entrando…' : 'Entrar',
                        onTap: _cargando ? null : () => _entrar(estado),
                      ),
                      const SizedBox(height: TemaModernista.esp5),
                      const Regla(),
                      const SizedBox(height: TemaModernista.esp4),
                      const Kicker('Acceso de demostración'),
                      // Lista de demo
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: TemaModernista.neutral300,
                              width: TemaModernista.reglaFina),
                        ),
                        child: Column(
                          children: [
                            for (final u in demo) ...[
                              InkWell(
                                onTap: () => _entrar(estado,
                                    correo: u.correo,
                                    clave: estado.esAuthEnMemoria
                                        ? '1234'
                                        : 'makuira2026'),
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                      TemaModernista.esp3),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 62,
                                        child: Text(u.rolCorto,
                                            style: TemaModernista.etiqueta(
                                                color: TemaModernista.acento,
                                                tam: 10)),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(u.nombre,
                                                style:
                                                    TemaModernista.cuerpo()),
                                            Text(u.correo,
                                                style: TemaModernista.cuerpo(
                                                    tam: 11,
                                                    color: TemaModernista
                                                        .neutral400)),
                                          ],
                                        ),
                                      ),
                                      Text('→',
                                          style: TemaModernista.cuerpo(
                                              color:
                                                  TemaModernista.neutral400)),
                                    ],
                                  ),
                                ),
                              ),
                              if (u != demo.last)
                                const Regla(
                                    grosor: TemaModernista.reglaFina,
                                    color: TemaModernista.neutral300),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: TemaModernista.esp4),
                      Text(
                        'El jugador solo ve su ficha, su cuota y lo que publica el cuerpo técnico.',
                        style: TemaModernista.cuerpo(
                            tam: 11, color: TemaModernista.neutral400),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
