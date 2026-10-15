import 'package:flutter/material.dart';

import '../core/tema_modernista.dart';
import '../estado/app_estado.dart';
import '../servicios/auth_servicio.dart';
import '../widgets/comunes.dart';
import '../widgets/plataforma.dart';

/// Crear cuenta con correo y contraseña (o con Google). El rol se elige en
/// el paso siguiente ([ElegirRolPantalla]), igual para los dos caminos.
class RegistroPantalla extends StatefulWidget {
  const RegistroPantalla({super.key});

  @override
  State<RegistroPantalla> createState() => _RegistroPantallaState();
}

class _RegistroPantallaState extends State<RegistroPantalla> {
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  final _confirmar = TextEditingController();
  String? _error;
  bool _cargando = false;

  @override
  void dispose() {
    for (final c in [_nombre, _correo, _clave, _confirmar]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validar() {
    if (_nombre.text.trim().length < 3) return 'Escribe tu nombre completo.';
    if (!_correo.text.contains('@')) return 'Escribe un correo válido.';
    if (_clave.text.trim().length < 6) return 'La contraseña debe tener al menos 6 caracteres.';
    if (_clave.text != _confirmar.text) return 'Las contraseñas no coinciden.';
    return null;
  }

  Future<void> _ejecutar(Future<void> Function() paso) async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await paso();
      // Ya hay sesión: la puerta de la app decide la pantalla siguiente.
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on ErrorAutenticacion catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _crear(AppEstado estado) {
    final error = _validar();
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    _ejecutar(() => estado.registrar(nombre: _nombre.text, correo: _correo.text, clave: _clave.text));
  }

  @override
  Widget build(BuildContext context) {
    final estado = AlcanceApp.de(context);
    return MarcoPlataforma(
      titulo: 'Crear cuenta',
      subtitulo: 'Paso 1 de 2 · tus datos',
      volver: () => Navigator.pop(context),
      child: ListView(
        padding: const EdgeInsets.all(TemaModernista.esp5),
        children: [
          Text('CREA TU CUENTA', style: TemaModernista.titulo(26)),
          const SizedBox(height: TemaModernista.esp2),
          Text('Después eliges si eres profesor, padre de familia o estudiante.',
              style: TemaModernista.cuerpo(tam: 12, color: TemaModernista.neutral800)),
          const SizedBox(height: TemaModernista.esp4),
          if (estado.soportaGoogle) ...[
            BotonGoogle(
              cargando: _cargando,
              onTap: () => _ejecutar(estado.ingresarConGoogle),
            ),
            const SizedBox(height: TemaModernista.esp4),
            Row(
              children: [
                const Expanded(child: Regla(grosor: 1, color: TemaModernista.neutral300)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: TemaModernista.esp3),
                  child: Text('O CON TU CORREO', style: TemaModernista.etiqueta(color: TemaModernista.neutral400, tam: 9)),
                ),
                const Expanded(child: Regla(grosor: 1, color: TemaModernista.neutral300)),
              ],
            ),
            const SizedBox(height: TemaModernista.esp4),
          ],
          TextField(
            controller: _nombre,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'NOMBRE COMPLETO'),
            autofillHints: const [AutofillHints.name],
          ),
          const SizedBox(height: TemaModernista.esp3),
          TextField(
            controller: _correo,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'CORREO'),
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: TemaModernista.esp3),
          TextField(
            controller: _clave,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'CONTRASEÑA', helperText: 'Mínimo 6 caracteres'),
            autofillHints: const [AutofillHints.newPassword],
          ),
          const SizedBox(height: TemaModernista.esp3),
          TextField(
            controller: _confirmar,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'REPITE LA CONTRASEÑA'),
            onSubmitted: (_) => _crear(estado),
          ),
          const SizedBox(height: TemaModernista.esp4),
          if (_error != null) ...[
            MensajeError(_error!),
            const SizedBox(height: TemaModernista.esp3),
          ],
          BotonModernista(_cargando ? 'Creando cuenta…' : 'Crear cuenta', onTap: _cargando ? null : () => _crear(estado)),
        ],
      ),
    );
  }
}
