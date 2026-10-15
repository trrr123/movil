import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/tema_modernista.dart';
import '../estado/app_estado.dart';
import '../modelos/escuela.dart';
import '../widgets/comunes.dart';
import '../widgets/plataforma.dart';

/// Profesor sin escuela aprobada: si no ha enviado nada, ve el formulario; si
/// ya envió, ve el estado de su solicitud con el código y el WhatsApp.
class ProfesorPantalla extends StatefulWidget {
  const ProfesorPantalla({super.key});

  @override
  State<ProfesorPantalla> createState() => _ProfesorPantallaState();
}

class _ProfesorPantallaState extends State<ProfesorPantalla> {
  Future<Escuela?>? _solicitud;
  bool _editando = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _solicitud ??= AlcanceApp.de(context).miSolicitudEscuela();
  }

  void _recargar() => setState(() {
        _editando = false;
        _solicitud = AlcanceApp.de(context).miSolicitudEscuela();
      });

  @override
  Widget build(BuildContext context) => MarcoPlataforma(
        child: FutureBuilder<Escuela?>(
          future: _solicitud,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator(color: TemaModernista.acento));
            }
            if (snap.hasError) {
              return _Reintentar(onTap: _recargar);
            }
            final escuela = snap.data;
            if (escuela == null || _editando) {
              return _FormularioEscuela(anterior: escuela, onEnviada: (_) => _recargar());
            }
            return _EstadoSolicitud(
              escuela: escuela,
              onActualizar: _recargar,
              onCorregir: () => setState(() => _editando = true),
            );
          },
        ),
      );
}

class _Reintentar extends StatelessWidget {
  const _Reintentar({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(TemaModernista.esp5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Vacio(titulo: 'Sin conexión', texto: 'No pudimos cargar tu solicitud.', icono: Icons.wifi_off),
            const SizedBox(height: TemaModernista.esp4),
            BotonModernista('Reintentar', onTap: onTap),
          ],
        ),
      );
}

// ── Formulario ───────────────────────────────────────────────────────────────

class _FormularioEscuela extends StatefulWidget {
  const _FormularioEscuela({required this.onEnviada, this.anterior});
  final ValueChanged<Escuela> onEnviada;

  /// Solicitud rechazada que se corrige: precarga los campos y las fotos.
  final Escuela? anterior;

  @override
  State<_FormularioEscuela> createState() => _FormularioEscuelaState();
}

class _FormularioEscuelaState extends State<_FormularioEscuela> {
  final _nombre = TextEditingController();
  final _categoria = TextEditingController();
  final _direccion = TextEditingController();
  final _descripcion = TextEditingController();
  final List<TextEditingController> _profesores = [];
  Ubicacion? _ubicacion;
  Uint8List? _fotoEscuela;
  Uint8List? _fotoProfesor;
  String? _error;
  bool _enviando = false;
  bool _iniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    final a = widget.anterior;
    if (a != null) {
      _nombre.text = a.nombre;
      _categoria.text = a.categoria;
      _direccion.text = a.direccion;
      _descripcion.text = a.descripcion;
      _ubicacion = a.ubicacion;
      _profesores.addAll(a.profesores.map((p) => TextEditingController(text: p)));
    } else {
      _profesores.add(TextEditingController(text: AlcanceApp.de(context).usuario?.nombre ?? ''));
    }
  }

  @override
  void dispose() {
    for (final c in [_nombre, _categoria, _direccion, _descripcion, ..._profesores]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _tieneFotoProfesor => _fotoProfesor != null || (widget.anterior?.fotoProfesorId.isNotEmpty ?? false);

  String? _validar() {
    if (_nombre.text.trim().length < 3) return 'Escribe el nombre de la escuela.';
    if (_direccion.text.trim().length < 5) return 'Escribe la dirección de la cancha.';
    if (_ubicacion == null) return 'Marca la cancha en el mapa.';
    if (_profesores.every((c) => c.text.trim().isEmpty)) return 'Escribe al menos un profesor.';
    if (!_tieneFotoProfesor) return 'Sube una foto tuya (del entrenador). Es obligatoria.';
    return null;
  }

  Future<void> _elegirUbicacion() async {
    final u = await Navigator.of(context).push<Ubicacion>(
      MaterialPageRoute(builder: (_) => SelectorUbicacionPantalla(inicial: _ubicacion)),
    );
    if (u != null) setState(() => _ubicacion = u);
  }

  Future<void> _enviar(AppEstado estado) async {
    final error = _validar();
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      final fotoProfesorId =
          _fotoProfesor != null ? await estado.subirFoto(_fotoProfesor!) : widget.anterior!.fotoProfesorId;
      final fotoEscuelaId =
          _fotoEscuela != null ? await estado.subirFoto(_fotoEscuela!) : widget.anterior?.fotoEscuelaId;
      final escuela = await estado.enviarSolicitudEscuela(
        nombre: _nombre.text,
        direccion: _direccion.text,
        ubicacion: _ubicacion!,
        profesores: [for (final c in _profesores) if (c.text.trim().isNotEmpty) c.text.trim()],
        descripcion: _descripcion.text,
        categoria: _categoria.text,
        fotoProfesorId: fotoProfesorId,
        fotoEscuelaId: fotoEscuelaId,
      );
      widget.onEnviada(escuela);
    } catch (e) {
      debugPrint('Error enviando solicitud de escuela: $e');
      if (mounted) setState(() => _error = 'No se pudo enviar la solicitud. Revisa tu conexión e intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = AlcanceApp.de(context);
    return ListView(
      padding: const EdgeInsets.all(TemaModernista.esp5),
      children: [
        Text('REGISTRA TU ESCUELA', style: TemaModernista.titulo(26)),
        const SizedBox(height: TemaModernista.esp2),
        Text(
          'Enviamos tu solicitud al administrador de Makuira. Cuando la aprobemos, se activa tu panel de entrenador.',
          style: TemaModernista.cuerpo(tam: 12, color: TemaModernista.neutral800),
        ),
        if (widget.anterior?.estado == EstadoEscuela.rechazada) ...[
          const SizedBox(height: TemaModernista.esp3),
          MensajeError('Tu solicitud anterior fue rechazada'
              '${widget.anterior!.motivoRechazo.isEmpty ? '.' : ': ${widget.anterior!.motivoRechazo}'}'),
        ],
        const SizedBox(height: TemaModernista.esp5),
        const Kicker('La escuela'),
        TextField(
          controller: _nombre,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'NOMBRE DE LA ESCUELA'),
        ),
        const SizedBox(height: TemaModernista.esp3),
        TextField(
          controller: _categoria,
          decoration: const InputDecoration(labelText: 'CATEGORÍAS (OPCIONAL)', hintText: 'Ej: Sub-10 a Sub-17'),
        ),
        const SizedBox(height: TemaModernista.esp3),
        TextField(
          controller: _descripcion,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'DESCRIPCIÓN (OPCIONAL)',
            hintText: 'Horarios, edades, qué los hace diferentes…',
          ),
        ),
        const SizedBox(height: TemaModernista.esp5),
        const Kicker('Dónde entrenan'),
        TextField(
          controller: _direccion,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'DIRECCIÓN DE LA CANCHA', hintText: 'Barrio, calle, referencia'),
        ),
        const SizedBox(height: TemaModernista.esp3),
        if (_ubicacion != null) ...[
          MapaUbicacion(ubicacion: _ubicacion!, alto: 160),
          BotonModernista('Cambiar ubicación en el mapa', variante: VarianteBoton.secundario, onTap: _elegirUbicacion),
        ] else
          BotonModernista('Marcar la cancha en el mapa', variante: VarianteBoton.secundario, onTap: _elegirUbicacion),
        const SizedBox(height: TemaModernista.esp5),
        const Kicker('Profesores'),
        for (var i = 0; i < _profesores.length; i++) ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _profesores[i],
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: 'PROFESOR ${i + 1}'),
                ),
              ),
              if (_profesores.length > 1)
                IconButton(
                  tooltip: 'Quitar',
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _profesores.removeAt(i).dispose()),
                ),
            ],
          ),
          const SizedBox(height: TemaModernista.esp2),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _profesores.add(TextEditingController())),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Agregar otro profesor'),
            style: TextButton.styleFrom(foregroundColor: TemaModernista.acento),
          ),
        ),
        const SizedBox(height: TemaModernista.esp4),
        SelectorFoto(
          rotulo: 'Foto del entrenador',
          obligatoria: true,
          icono: Icons.person_outline,
          bytes: _fotoProfesor,
          onElegida: (b) => setState(() => _fotoProfesor = b),
        ),
        if (_fotoProfesor == null && _tieneFotoProfesor)
          Padding(
            padding: const EdgeInsets.only(top: TemaModernista.esp1),
            child: Text('Se usará la foto que enviaste antes.', style: TemaModernista.cuerpo(tam: 11)),
          ),
        const SizedBox(height: TemaModernista.esp4),
        SelectorFoto(
          rotulo: 'Foto de la escuela',
          icono: Icons.stadium_outlined,
          bytes: _fotoEscuela,
          onElegida: (b) => setState(() => _fotoEscuela = b),
        ),
        const SizedBox(height: TemaModernista.esp5),
        if (_error != null) ...[
          MensajeError(_error!),
          const SizedBox(height: TemaModernista.esp3),
        ],
        BotonModernista(_enviando ? 'Enviando…' : 'Enviar solicitud', onTap: _enviando ? null : () => _enviar(estado)),
        const SizedBox(height: TemaModernista.esp5),
      ],
    );
  }
}

// ── Estado de la solicitud ───────────────────────────────────────────────────

class _EstadoSolicitud extends StatefulWidget {
  const _EstadoSolicitud({required this.escuela, required this.onActualizar, required this.onCorregir});
  final Escuela escuela;
  final VoidCallback onActualizar;
  final VoidCallback onCorregir;

  @override
  State<_EstadoSolicitud> createState() => _EstadoSolicitudState();
}

class _EstadoSolicitudState extends State<_EstadoSolicitud> {
  bool _entrando = false;

  Future<void> _entrarAMiEscuela(AppEstado estado) async {
    setState(() => _entrando = true);
    try {
      await estado.recargarPerfil();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('No se pudo abrir tu escuela. Intenta de nuevo.')));
      }
    } finally {
      if (mounted) setState(() => _entrando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = AlcanceApp.de(context);
    final e = widget.escuela;
    return RefreshIndicator(
      color: TemaModernista.acento,
      onRefresh: () async => widget.onActualizar(),
      child: ListView(
        padding: const EdgeInsets.all(TemaModernista.esp5),
        children: [
          Etiqueta(
            e.estado.etiqueta,
            fondo: switch (e.estado) {
              EstadoEscuela.aprobada => const Color(0xFFD9F2E1),
              EstadoEscuela.rechazada => TemaModernista.acento100,
              EstadoEscuela.pendiente => TemaModernista.neutral200,
            },
          ),
          const SizedBox(height: TemaModernista.esp3),
          Text(
            switch (e.estado) {
              EstadoEscuela.pendiente => 'SOLICITUD ENVIADA',
              EstadoEscuela.aprobada => '¡ESCUELA APROBADA!',
              EstadoEscuela.rechazada => 'SOLICITUD RECHAZADA',
            },
            style: TemaModernista.titulo(28),
          ),
          const SizedBox(height: TemaModernista.esp2),
          Text(
            switch (e.estado) {
              EstadoEscuela.pendiente =>
                'Estamos revisando “${e.nombre}”. Agréganos en WhatsApp y envíanos tu código de solicitud para agilizar la verificación.',
              EstadoEscuela.aprobada => 'Ya puedes administrar “${e.nombre}”: plantel, partidos, agenda y cuotas.',
              EstadoEscuela.rechazada => e.motivoRechazo.isEmpty
                  ? 'No pudimos aprobar “${e.nombre}”. Escríbenos por WhatsApp o corrige los datos y vuelve a enviarla.'
                  : 'Motivo: ${e.motivoRechazo}',
            },
            style: TemaModernista.cuerpo(tam: 13, color: TemaModernista.neutral800),
          ),
          const SizedBox(height: TemaModernista.esp5),
          const Kicker('Código de solicitud'),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: e.id));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código copiado')));
            },
            child: Container(
              width: double.infinity,
              color: TemaModernista.fondoOscuro,
              padding: const EdgeInsets.all(TemaModernista.esp4),
              child: Row(
                children: [
                  Expanded(child: Text(e.id, style: TemaModernista.titulo(30, color: Colors.white))),
                  const Icon(Icons.copy_rounded, color: TemaModernista.neutral400, size: 20),
                ],
              ),
            ),
          ),
          if (e.estado != EstadoEscuela.aprobada) ...[
            const SizedBox(height: TemaModernista.esp5),
            const Kicker('Agréganos y escríbenos por WhatsApp'),
            const CuadroWhatsApp(),
          ],
          const SizedBox(height: TemaModernista.esp5),
          if (e.estado == EstadoEscuela.aprobada)
            BotonModernista(_entrando ? 'Abriendo…' : 'Entrar a mi escuela',
                onTap: _entrando ? null : () => _entrarAMiEscuela(estado))
          else ...[
            BotonModernista('Actualizar estado', variante: VarianteBoton.secundario, onTap: widget.onActualizar),
            if (e.estado == EstadoEscuela.rechazada) ...[
              const SizedBox(height: TemaModernista.esp3),
              BotonModernista('Corregir y reenviar', onTap: widget.onCorregir),
            ],
          ],
          const SizedBox(height: TemaModernista.esp5),
          const Regla(grosor: 1, color: TemaModernista.neutral300),
          const SizedBox(height: TemaModernista.esp4),
          const Kicker('Lo que enviaste'),
          Text(e.nombre, style: TemaModernista.titulo(18)),
          const SizedBox(height: TemaModernista.esp1),
          Text(e.direccion, style: TemaModernista.cuerpo(tam: 12, color: TemaModernista.neutral800)),
          Text('Profesores: ${e.profesores.join(', ')}', style: TemaModernista.cuerpo(tam: 12)),
        ],
      ),
    );
  }
}
