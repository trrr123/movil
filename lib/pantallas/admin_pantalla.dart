import 'package:flutter/material.dart';

import '../core/tema_modernista.dart';
import '../estado/app_estado.dart';
import '../modelos/escuela.dart';
import '../widgets/comunes.dart';
import '../widgets/plataforma.dart';
import 'escuela_detalle_pantalla.dart';

/// Panel del administrador: solicitudes de escuelas por estado. Aprobar
/// convierte al profesor en DT de su escuela; rechazar le deja un motivo.
class AdminPantalla extends StatefulWidget {
  const AdminPantalla({super.key});

  @override
  State<AdminPantalla> createState() => _AdminPantallaState();
}

class _AdminPantallaState extends State<AdminPantalla> {
  EstadoEscuela _filtro = EstadoEscuela.pendiente;
  Future<List<Escuela>>? _lista;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _lista ??= AlcanceApp.de(context).escuelasPorEstado(_filtro);
  }

  void _cargar([EstadoEscuela? filtro]) => setState(() {
        _filtro = filtro ?? _filtro;
        _lista = AlcanceApp.de(context).escuelasPorEstado(_filtro);
      });

  Future<void> _abrir(Escuela e) async {
    final cambio = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => _RevisionEscuela(escuela: e)),
    );
    if (cambio == true) _cargar();
  }

  @override
  Widget build(BuildContext context) => MarcoPlataforma(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  TemaModernista.esp5, TemaModernista.esp5, TemaModernista.esp5, TemaModernista.esp3),
              child: Text('SOLICITUDES', style: TemaModernista.titulo(28)),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: TemaModernista.esp5),
              child: Row(
                children: [
                  for (final f in EstadoEscuela.values)
                    Padding(
                      padding: const EdgeInsets.only(right: TemaModernista.esp2),
                      child: ChoiceChip(
                        label: Text(f.etiqueta.toUpperCase()),
                        selected: _filtro == f,
                        onSelected: (_) => _cargar(f),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        selectedColor: TemaModernista.acento,
                        labelStyle: TemaModernista.etiqueta(
                            color: _filtro == f ? Colors.white : TemaModernista.tinta, tam: 10),
                        showCheckmark: false,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: TemaModernista.esp3),
            Expanded(
              child: RefreshIndicator(
                color: TemaModernista.acento,
                onRefresh: () async => _cargar(),
                child: FutureBuilder<List<Escuela>>(
                  future: _lista,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator(color: TemaModernista.acento));
                    }
                    final escuelas = snap.data ?? const [];
                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: TemaModernista.esp5),
                      children: [
                        if (snap.hasError)
                          const Vacio(titulo: 'Error', texto: 'No se pudieron cargar. Desliza hacia abajo para reintentar.')
                        else if (escuelas.isEmpty)
                          Vacio(
                            titulo: 'Nada por aquí',
                            texto: _filtro == EstadoEscuela.pendiente
                                ? 'No hay solicitudes esperando revisión.'
                                : 'No hay escuelas ${_filtro.etiqueta.toLowerCase()}s.',
                          )
                        else
                          for (final e in escuelas) ...[
                            FilaEscuela(
                              escuela: e,
                              detalle: '${e.id} · ${e.correoDueno}',
                              onTap: () => _abrir(e),
                            ),
                            const SizedBox(height: TemaModernista.esp3),
                          ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
}

class _RevisionEscuela extends StatefulWidget {
  const _RevisionEscuela({required this.escuela});
  final Escuela escuela;

  @override
  State<_RevisionEscuela> createState() => _RevisionEscuelaState();
}

class _RevisionEscuelaState extends State<_RevisionEscuela> {
  bool _ocupado = false;

  Future<void> _ejecutar(Future<void> Function() accion, String hecho) async {
    setState(() => _ocupado = true);
    try {
      await accion();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(hecho)));
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error revisando escuela: $e');
      if (mounted) {
        setState(() => _ocupado = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo guardar. Intenta de nuevo.')));
      }
    }
  }

  Future<void> _rechazar(AppEstado estado) async {
    final motivo = TextEditingController();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text('RECHAZAR SOLICITUD', style: TemaModernista.titulo(18)),
        content: TextField(
          controller: motivo,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'MOTIVO (LO VERÁ EL PROFESOR)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Rechazar')),
        ],
      ),
    );
    if (confirmar != true) return;
    await _ejecutar(() => estado.rechazarEscuela(widget.escuela, motivo.text.trim()), 'Solicitud rechazada');
  }

  @override
  Widget build(BuildContext context) {
    final estado = AlcanceApp.de(context);
    final e = widget.escuela;
    return EscuelaDetallePantalla(
      escuela: e,
      acciones: [
        const Kicker('Solicitud'),
        Text('Código: ${e.id}', style: TemaModernista.cuerpo(tam: 14, peso: FontWeight.w600)),
        Text('Correo del profesor: ${e.correoDueno}', style: TemaModernista.cuerpo(tam: 13)),
        Text('Estado: ${e.estado.etiqueta}', style: TemaModernista.cuerpo(tam: 13)),
        if (e.estado != EstadoEscuela.aprobada)
          BotonModernista(_ocupado ? 'Guardando…' : 'Aprobar escuela',
              onTap: _ocupado ? null : () => _ejecutar(() => estado.aprobarEscuela(e), '${e.nombre} aprobada')),
        if (e.estado == EstadoEscuela.pendiente)
          BotonModernista('Rechazar', variante: VarianteBoton.secundario, onTap: _ocupado ? null : () => _rechazar(estado)),
      ],
    );
  }
}
