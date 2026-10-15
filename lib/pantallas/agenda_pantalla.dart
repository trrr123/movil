import 'package:flutter/material.dart';

import '../core/tema_modernista.dart';
import '../estado/app_estado.dart';
import '../modelos/partido.dart';
import '../modelos/usuario.dart';
import '../widgets/comunes.dart';
import '../widgets/plataforma.dart';
import 'convocatoria_pantalla.dart';
import 'en_vivo_pantalla.dart';

/// Agenda compartida por los dos roles: partidos y sesiones en una sola línea
/// de tiempo. Al DT los ítems le abren herramientas y puede programar nuevos;
/// al jugador, información.
class AgendaPantalla extends StatelessWidget {
  const AgendaPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = AlcanceApp.de(context);
    final esDT = estado.puede(Permiso.registrarAsistencia);

    final items = <_ItemAgenda>[
      for (final s in estado.sesiones)
        _ItemAgenda(
          fecha: s.fecha,
          tipo: switch (s.tipo) {
            TipoSesion.video => 'Video',
            TipoSesion.gimnasio => 'Gimnasio',
            TipoSesion.entrenamiento => 'Entreno',
          },
          titulo: s.titulo,
          lugar: esDT && s.asistencia.isNotEmpty ? '${s.lugar} · ${s.presentes} presentes' : s.lugar,
          destacado: false,
          onTap: esDT
              ? () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => ConvocatoriaPantalla(sesion: s)))
              : null,
        ),
      for (final p in estado.partidos)
        _ItemAgenda(
          fecha: p.fecha,
          tipo: p.finalizado ? 'Final ${p.golesPropios}-${p.golesRival}' : 'Partido',
          titulo: '${estado.nombreClub} vs. ${p.rival}',
          lugar: '${p.sede} · ${p.competencia}',
          destacado: !p.finalizado,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EnVivoPantalla(partido: p))),
        ),
    ]..sort((a, b) => a.fecha.compareTo(b.fecha));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
      children: [
        Row(
          children: [
            Expanded(child: Text('AGENDA', style: TemaModernista.titulo(28))),
            if (esDT)
              BotonModernista('+ Programar', expandido: false, onTap: () => _FormularioProgramar.abrir(context)),
          ],
        ),
        const SizedBox(height: TemaModernista.esp4),
        const Regla(),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: TemaModernista.esp4),
            child: Vacio(
              titulo: 'Agenda vacía',
              texto: esDT
                  ? 'Toca “+ Programar” para agendar el primer partido o entreno.'
                  : 'El profe todavía no ha programado partidos ni entrenos.',
              icono: Icons.calendar_today_outlined,
            ),
          ),
        for (final i in items)
          InkWell(
            onTap: i.onTap,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: TemaModernista.neutral300)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 52,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${i.fecha.day}', style: TemaModernista.titulo(20)),
                        Text('${_dow(i.fecha)} ${_mes(i.fecha)}'.toUpperCase(),
                            style: TemaModernista.etiqueta(color: TemaModernista.neutral400, tam: 9)),
                      ],
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 52,
                    color: i.destacado ? TemaModernista.acento : TemaModernista.tinta,
                  ),
                  const SizedBox(width: TemaModernista.esp3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Etiqueta(
                              i.tipo,
                              fondo: i.destacado ? TemaModernista.acento : TemaModernista.neutral200,
                              tinta: i.destacado ? Colors.white : TemaModernista.neutral800,
                            ),
                            const SizedBox(width: TemaModernista.esp2),
                            Text('${i.fecha.hour}:${i.fecha.minute.toString().padLeft(2, '0')}',
                                style: TemaModernista.cuerpo(tam: 11, color: TemaModernista.neutral400)),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(i.titulo, style: TemaModernista.cuerpo(tam: 14, peso: FontWeight.w600)),
                        Text(i.lugar, style: TemaModernista.cuerpo(tam: 11, color: TemaModernista.neutral400)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  static String _dow(DateTime d) => const ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'][d.weekday - 1];
  static String _mes(DateTime d) =>
      const ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'][d.month - 1];
}

class _ItemAgenda {
  _ItemAgenda({
    required this.fecha,
    required this.tipo,
    required this.titulo,
    required this.lugar,
    required this.destacado,
    this.onTap,
  });

  final DateTime fecha;
  final String tipo;
  final String titulo;
  final String lugar;
  final bool destacado;
  final VoidCallback? onTap;
}

/// DT: programar un partido o un entreno (fecha, hora y lugar).
class _FormularioProgramar extends StatefulWidget {
  const _FormularioProgramar();

  static Future<void> abrir(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        builder: (_) => const _FormularioProgramar(),
      );

  @override
  State<_FormularioProgramar> createState() => _FormularioProgramarState();
}

class _FormularioProgramarState extends State<_FormularioProgramar> {
  bool _esPartido = true;
  final _rivalOTitulo = TextEditingController();
  final _lugar = TextEditingController();
  final _competencia = TextEditingController();
  bool _local = true;
  TipoSesion _tipo = TipoSesion.entrenamiento;
  DateTime? _dia;
  TimeOfDay? _hora;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_rivalOTitulo, _lugar, _competencia]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _elegirDia() async {
    final hoy = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _dia ?? hoy,
      firstDate: hoy.subtract(const Duration(days: 30)),
      lastDate: hoy.add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _dia = d);
  }

  Future<void> _elegirHora() async {
    final h = await showTimePicker(context: context, initialTime: _hora ?? const TimeOfDay(hour: 16, minute: 0));
    if (h != null) setState(() => _hora = h);
  }

  Future<void> _guardar(AppEstado estado) async {
    final texto = _rivalOTitulo.text.trim();
    if (texto.length < 2) {
      return setState(() => _error = _esPartido ? 'Escribe el rival.' : 'Escribe qué se va a entrenar.');
    }
    if (_dia == null || _hora == null) return setState(() => _error = 'Elige el día y la hora.');
    if (_lugar.text.trim().length < 2) return setState(() => _error = 'Escribe el lugar.');
    final fecha = DateTime(_dia!.year, _dia!.month, _dia!.day, _hora!.hour, _hora!.minute);
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      if (_esPartido) {
        await estado.programarPartido(
          rival: texto,
          fecha: fecha,
          sede: _lugar.text,
          competencia: _competencia.text,
          local: _local,
        );
      } else {
        await estado.programarSesion(titulo: texto, fecha: fecha, lugar: _lugar.text, tipo: _tipo);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Error programando: $e');
      if (mounted) setState(() => _error = 'No se pudo guardar. Revisa tu conexión.');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = AlcanceApp.de(context);
    final dia = _dia;
    final hora = _hora;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TemaModernista.esp5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('PROGRAMAR', style: TemaModernista.titulo(22)),
            const SizedBox(height: TemaModernista.esp3),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Partido')),
                ButtonSegment(value: false, label: Text('Entreno')),
              ],
              selected: {_esPartido},
              onSelectionChanged: (s) => setState(() => _esPartido = s.first),
              style: const ButtonStyle(
                shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
              ),
            ),
            const SizedBox(height: TemaModernista.esp4),
            TextField(
              controller: _rivalOTitulo,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: _esPartido ? 'RIVAL' : 'QUÉ SE ENTRENA',
                hintText: _esPartido ? 'Ej: Academia Riohacha' : 'Ej: Definición y balón parado',
              ),
            ),
            const SizedBox(height: TemaModernista.esp3),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _elegirDia,
                    icon: const Icon(Icons.event, size: 18),
                    label: Text(dia == null ? 'Día' : '${dia.day}/${dia.month}/${dia.year}'),
                    style: OutlinedButton.styleFrom(
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      foregroundColor: TemaModernista.tinta,
                    ),
                  ),
                ),
                const SizedBox(width: TemaModernista.esp2),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _elegirHora,
                    icon: const Icon(Icons.schedule, size: 18),
                    label: Text(hora == null ? 'Hora' : hora.format(context)),
                    style: OutlinedButton.styleFrom(
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      foregroundColor: TemaModernista.tinta,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TemaModernista.esp3),
            TextField(
              controller: _lugar,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: _esPartido ? 'SEDE / CANCHA' : 'LUGAR'),
            ),
            const SizedBox(height: TemaModernista.esp3),
            if (_esPartido) ...[
              TextField(
                controller: _competencia,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'COMPETENCIA (OPCIONAL)', hintText: 'Ej: Liga juvenil'),
              ),
              SwitchListTile(
                value: _local,
                onChanged: (v) => setState(() => _local = v),
                contentPadding: EdgeInsets.zero,
                activeThumbColor: TemaModernista.acento,
                title: Text(_local ? 'Jugamos de local' : 'Jugamos de visitante', style: TemaModernista.cuerpo()),
              ),
            ] else
              DropdownButtonFormField<TipoSesion>(
                initialValue: _tipo,
                decoration: const InputDecoration(labelText: 'TIPO'),
                items: const [
                  DropdownMenuItem(value: TipoSesion.entrenamiento, child: Text('Entrenamiento en cancha')),
                  DropdownMenuItem(value: TipoSesion.gimnasio, child: Text('Gimnasio / físico')),
                  DropdownMenuItem(value: TipoSesion.video, child: Text('Charla / video')),
                ],
                onChanged: (t) => setState(() => _tipo = t ?? _tipo),
              ),
            const SizedBox(height: TemaModernista.esp4),
            if (_error != null) ...[
              MensajeError(_error!),
              const SizedBox(height: TemaModernista.esp3),
            ],
            BotonModernista(_guardando ? 'Guardando…' : 'Guardar', onTap: _guardando ? null : () => _guardar(estado)),
          ],
        ),
      ),
    );
  }
}
