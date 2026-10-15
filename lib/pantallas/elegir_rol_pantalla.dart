import 'package:flutter/material.dart';

import '../core/tema_modernista.dart';
import '../estado/app_estado.dart';
import '../modelos/usuario.dart';
import '../widgets/comunes.dart';
import '../widgets/plataforma.dart';

/// Paso 2 del registro (también para quien entra por primera vez con
/// Google): la cuenta elige qué es. El rol queda en `usuarios/{uid}` y las
/// reglas de Firestore solo aceptan estos tres — nunca 'dt' ni 'admin'.
class ElegirRolPantalla extends StatefulWidget {
  const ElegirRolPantalla({super.key});

  @override
  State<ElegirRolPantalla> createState() => _ElegirRolPantallaState();
}

class _ElegirRolPantallaState extends State<ElegirRolPantalla> {
  late final TextEditingController _nombre;
  RolRegistro? _rol;
  String? _error;
  bool _cargando = false;

  static const _opciones = [
    (
      rol: RolRegistro.profesor,
      titulo: 'Soy profesor',
      texto: 'Registra tu escuela de fútbol. La revisamos y te activamos el panel de entrenador.',
      icono: Icons.sports_outlined,
    ),
    (
      rol: RolRegistro.acudiente,
      titulo: 'Soy padre o acudiente',
      texto: 'Sigue los goles, la asistencia y las cuotas de tu hijo, o inscríbelo en una escuela.',
      icono: Icons.family_restroom_outlined,
    ),
    (
      rol: RolRegistro.estudiante,
      titulo: 'Soy estudiante',
      texto: 'Busca una escuela, pide tu cupo y sigue tus estadísticas.',
      icono: Icons.directions_run_outlined,
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _nombreInicial();
  }

  bool _iniciado = false;
  void _nombreInicial() {
    if (_iniciado) return;
    _iniciado = true;
    _nombre = TextEditingController(text: AlcanceApp.de(context).usuario?.nombre ?? '');
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _continuar(AppEstado estado) async {
    if (_rol == null) {
      setState(() => _error = 'Elige una opción.');
      return;
    }
    if (_nombre.text.trim().length < 3) {
      setState(() => _error = 'Escribe tu nombre completo.');
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await estado.elegirRol(_rol!, _nombre.text);
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo guardar. Revisa tu conexión e intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = AlcanceApp.de(context);
    return MarcoPlataforma(
      subtitulo: 'Paso 2 de 2 · ¿quién eres?',
      child: ListView(
        padding: const EdgeInsets.all(TemaModernista.esp5),
        children: [
          Text('¿QUIÉN ERES?', style: TemaModernista.titulo(26)),
          const SizedBox(height: TemaModernista.esp4),
          TextField(
            controller: _nombre,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'TU NOMBRE COMPLETO'),
          ),
          const SizedBox(height: TemaModernista.esp5),
          for (final o in _opciones) ...[
            _TarjetaRol(
              titulo: o.titulo,
              texto: o.texto,
              icono: o.icono,
              elegida: _rol == o.rol,
              onTap: () => setState(() => _rol = o.rol),
            ),
            const SizedBox(height: TemaModernista.esp3),
          ],
          const SizedBox(height: TemaModernista.esp2),
          if (_error != null) ...[
            MensajeError(_error!),
            const SizedBox(height: TemaModernista.esp3),
          ],
          BotonModernista(_cargando ? 'Guardando…' : 'Continuar', onTap: _cargando ? null : () => _continuar(estado)),
        ],
      ),
    );
  }
}

class _TarjetaRol extends StatelessWidget {
  const _TarjetaRol({
    required this.titulo,
    required this.texto,
    required this.icono,
    required this.elegida,
    required this.onTap,
  });

  final String titulo;
  final String texto;
  final IconData icono;
  final bool elegida;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(TemaModernista.esp4),
          decoration: BoxDecoration(
            color: elegida ? TemaModernista.acento100 : TemaModernista.fondo,
            border: Border.all(
              color: elegida ? TemaModernista.acento : TemaModernista.neutral300,
              width: elegida ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icono, color: elegida ? TemaModernista.acento : TemaModernista.tinta),
              const SizedBox(width: TemaModernista.esp3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo.toUpperCase(), style: TemaModernista.titulo(16)),
                    const SizedBox(height: TemaModernista.esp1),
                    Text(texto, style: TemaModernista.cuerpo(tam: 12, color: TemaModernista.neutral800)),
                  ],
                ),
              ),
              Icon(elegida ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: elegida ? TemaModernista.acento : TemaModernista.neutral400, size: 20),
            ],
          ),
        ),
      );
}
