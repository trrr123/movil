import 'package:flutter/material.dart';

import '../core/tema_modernista.dart';
import '../datos/inscripcion_repositorio.dart';
import '../estado/app_estado.dart';
import '../modelos/escuela.dart';
import '../modelos/jugador.dart';
import '../widgets/comunes.dart';
import '../widgets/plataforma.dart';

/// DT: pedidos de cupo de familias para su escuela. Aceptar crea la ficha
/// en el plantel (o enlaza una existente si el niño ya entrena ahí), y desde
/// ese momento el acudiente ve sus estadísticas.
class InscripcionesPantalla extends StatefulWidget {
  const InscripcionesPantalla({super.key});

  @override
  State<InscripcionesPantalla> createState() => _InscripcionesPantallaState();
}

class _InscripcionesPantallaState extends State<InscripcionesPantalla> {
  Future<List<Inscripcion>>? _lista;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _lista ??= AlcanceApp.de(context).inscripcionesPendientes();
  }

  void _cargar() => setState(() => _lista = AlcanceApp.de(context).inscripcionesPendientes());

  Future<void> _rechazar(Inscripcion i) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text('RECHAZAR', style: TemaModernista.titulo(18)),
        content: Text('¿Rechazar la solicitud de ${i.nombreJugador}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Rechazar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await AlcanceApp.de(context).rechazarInscripcion(i);
    _cargar();
  }

  Future<void> _aceptar(Inscripcion i) async {
    final hecho = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (_) => _AceptarInscripcion(inscripcion: i),
    );
    if (hecho == true) _cargar();
  }

  @override
  Widget build(BuildContext context) => MarcoPlataforma(
        titulo: 'Inscripciones',
        subtitulo: 'Pedidos de cupo de familias',
        volver: () => Navigator.pop(context),
        child: RefreshIndicator(
          color: TemaModernista.acento,
          onRefresh: () async => _cargar(),
          child: FutureBuilder<List<Inscripcion>>(
            future: _lista,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator(color: TemaModernista.acento));
              }
              final lista = snap.data ?? const [];
              return ListView(
                padding: const EdgeInsets.all(TemaModernista.esp5),
                children: [
                  if (snap.hasError)
                    const Vacio(titulo: 'Error', texto: 'No se pudieron cargar. Desliza para reintentar.')
                  else if (lista.isEmpty)
                    const Vacio(titulo: 'Sin solicitudes', texto: 'Cuando una familia pida cupo, aparecerá aquí.')
                  else
                    for (final i in lista) ...[
                      _TarjetaInscripcion(
                        inscripcion: i,
                        onAceptar: () => _aceptar(i),
                        onRechazar: () => _rechazar(i),
                      ),
                      const SizedBox(height: TemaModernista.esp4),
                    ],
                ],
              );
            },
          ),
        ),
      );
}

class _TarjetaInscripcion extends StatelessWidget {
  const _TarjetaInscripcion({required this.inscripcion, required this.onAceptar, required this.onRechazar});
  final Inscripcion inscripcion;
  final VoidCallback onAceptar;
  final VoidCallback onRechazar;

  @override
  Widget build(BuildContext context) {
    final i = inscripcion;
    return Container(
      padding: const EdgeInsets.all(TemaModernista.esp4),
      decoration: BoxDecoration(border: Border.all(color: TemaModernista.divisor, width: 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(i.nombreJugador.toUpperCase(), style: TemaModernista.titulo(20)),
          Text('${i.edad} años', style: TemaModernista.etiqueta(color: TemaModernista.acento)),
          const SizedBox(height: TemaModernista.esp3),
          Text(i.paraSiMismo ? 'Lo pide el estudiante' : 'Lo pide: ${i.nombreSolicitante} (acudiente)',
              style: TemaModernista.cuerpo(tam: 13)),
          Text('${i.correoSolicitante} · ${i.telefono}',
              style: TemaModernista.cuerpo(tam: 12, color: TemaModernista.neutral800)),
          if (i.nota.isNotEmpty) ...[
            const SizedBox(height: TemaModernista.esp2),
            Text('“${i.nota}”', style: TemaModernista.cuerpo(tam: 13)),
          ],
          const SizedBox(height: TemaModernista.esp4),
          Row(
            children: [
              Expanded(child: BotonModernista('Aceptar', onTap: onAceptar)),
              const SizedBox(width: TemaModernista.esp3),
              Expanded(child: BotonModernista('Rechazar', variante: VarianteBoton.secundario, onTap: onRechazar)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AceptarInscripcion extends StatefulWidget {
  const _AceptarInscripcion({required this.inscripcion});
  final Inscripcion inscripcion;

  @override
  State<_AceptarInscripcion> createState() => _AceptarInscripcionState();
}

class _AceptarInscripcionState extends State<_AceptarInscripcion> {
  bool _fichaNueva = true;
  Jugador? _existente;
  Posicion _posicion = Posicion.mediocampo;
  String _pie = 'Derecho';
  final _dorsal = TextEditingController();
  final _detalle = TextEditingController();
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _dorsal.dispose();
    _detalle.dispose();
    super.dispose();
  }

  Future<void> _guardar(AppEstado estado) async {
    FichaNueva? nueva;
    if (_fichaNueva) {
      final dorsal = int.tryParse(_dorsal.text.trim());
      if (dorsal == null || dorsal < 1 || dorsal > 99) return setState(() => _error = 'Escribe un dorsal entre 1 y 99.');
      nueva = FichaNueva(
        id: estado.siguienteIdJugador,
        dorsal: dorsal,
        posicion: _posicion,
        detallePosicion: _detalle.text.trim().isEmpty ? _posicion.largo : _detalle.text.trim(),
        pieHabil: _pie,
      );
    } else if (_existente == null) {
      return setState(() => _error = 'Elige la ficha del jugador.');
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await estado.aprobarInscripcion(widget.inscripcion, nueva: nueva, existente: _fichaNueva ? null : _existente);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error aprobando inscripción: $e');
      if (mounted) setState(() => _error = 'No se pudo guardar. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = AlcanceApp.de(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TemaModernista.esp5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ACEPTAR A ${widget.inscripcion.nombreJugador.toUpperCase()}', style: TemaModernista.titulo(20)),
            const SizedBox(height: TemaModernista.esp3),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Ficha nueva')),
                ButtonSegment(value: false, label: Text('Ya está en el plantel')),
              ],
              selected: {_fichaNueva},
              onSelectionChanged: (s) => setState(() => _fichaNueva = s.first),
              style: const ButtonStyle(
                shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
              ),
            ),
            const SizedBox(height: TemaModernista.esp4),
            if (_fichaNueva) ...[
              TextField(
                controller: _dorsal,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'DORSAL'),
              ),
              const SizedBox(height: TemaModernista.esp3),
              DropdownButtonFormField<Posicion>(
                initialValue: _posicion,
                decoration: const InputDecoration(labelText: 'POSICIÓN'),
                items: [for (final p in Posicion.values) DropdownMenuItem(value: p, child: Text(p.largo))],
                onChanged: (p) => setState(() => _posicion = p ?? _posicion),
              ),
              const SizedBox(height: TemaModernista.esp3),
              TextField(
                controller: _detalle,
                decoration: const InputDecoration(labelText: 'DETALLE (OPCIONAL)', hintText: 'Ej: Lateral izq.'),
              ),
              const SizedBox(height: TemaModernista.esp3),
              DropdownButtonFormField<String>(
                initialValue: _pie,
                decoration: const InputDecoration(labelText: 'PIE HÁBIL'),
                items: const [
                  DropdownMenuItem(value: 'Derecho', child: Text('Derecho')),
                  DropdownMenuItem(value: 'Izquierdo', child: Text('Izquierdo')),
                  DropdownMenuItem(value: 'Ambos', child: Text('Ambos')),
                ],
                onChanged: (p) => setState(() => _pie = p ?? _pie),
              ),
            ] else
              DropdownButtonFormField<Jugador>(
                initialValue: _existente,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'FICHA DEL JUGADOR'),
                items: [
                  for (final j in estado.plantel)
                    DropdownMenuItem(value: j, child: Text('${j.dorsal} · ${j.nombre}', overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (j) => setState(() => _existente = j),
              ),
            const SizedBox(height: TemaModernista.esp4),
            if (_error != null) ...[
              MensajeError(_error!),
              const SizedBox(height: TemaModernista.esp3),
            ],
            BotonModernista(_guardando ? 'Guardando…' : 'Confirmar', onTap: _guardando ? null : () => _guardar(estado)),
          ],
        ),
      ),
    );
  }
}
