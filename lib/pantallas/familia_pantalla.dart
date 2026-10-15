import 'package:flutter/material.dart';

import '../core/tema_modernista.dart';
import '../estado/app_estado.dart';
import '../modelos/escuela.dart';
import '../modelos/finanzas.dart';
import '../modelos/resumen_jugador.dart';
import '../modelos/usuario.dart';
import '../widgets/comunes.dart';
import '../widgets/plataforma.dart';
import 'escuela_detalle_pantalla.dart';

/// Inicio del acudiente (o del estudiante sin ficha): sus hijos inscritos con
/// goles, asistencias, entrenos y deuda; sus solicitudes en curso; y el
/// catálogo de escuelas para pedir cupo.
class FamiliaPantalla extends StatefulWidget {
  const FamiliaPantalla({super.key});

  @override
  State<FamiliaPantalla> createState() => _FamiliaPantallaState();
}

class _FamiliaPantallaState extends State<FamiliaPantalla> {
  Future<List<Inscripcion>>? _inscripciones;
  Future<List<Escuela>>? _escuelas;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inscripciones == null) _cargar();
  }

  void _cargar() {
    final estado = AlcanceApp.de(context);
    setState(() {
      _inscripciones = estado.misInscripciones();
      _escuelas = estado.escuelasAprobadas();
    });
  }

  Future<void> _abrirEscuela(Escuela e) async {
    final usuario = AlcanceApp.de(context).usuario as Familia;
    await Navigator.of(context).push<void>(MaterialPageRoute(
      builder: (_) => EscuelaDetallePantalla(
        escuela: e,
        acciones: [
          BotonModernista(
            usuario.esEstudiante ? 'Quiero inscribirme aquí' : 'Inscribir a mi hijo aquí',
            onTap: () => _FormularioInscripcion.abrir(context, e),
          ),
        ],
      ),
    ));
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final estado = AlcanceApp.de(context);
    final usuario = estado.usuario as Familia;
    return MarcoPlataforma(
      child: RefreshIndicator(
        color: TemaModernista.acento,
        onRefresh: () async => _cargar(),
        child: FutureBuilder<List<Inscripcion>>(
          future: _inscripciones,
          builder: (context, snap) {
            final todas = snap.data ?? const <Inscripcion>[];
            final aprobadas = todas.where((i) => i.aprobada).toList();
            final enCurso = todas.where((i) => !i.aprobada).toList();
            return ListView(
              padding: const EdgeInsets.all(TemaModernista.esp5),
              children: [
                Text('HOLA, ${usuario.nombre.split(' ').first.toUpperCase()}', style: TemaModernista.titulo(26)),
                const SizedBox(height: TemaModernista.esp4),
                if (snap.connectionState != ConnectionState.done)
                  const Center(child: CircularProgressIndicator(color: TemaModernista.acento))
                else if (snap.hasError)
                  const Vacio(titulo: 'Sin conexión', texto: 'Desliza hacia abajo para reintentar.', icono: Icons.wifi_off)
                else ...[
                  if (usuario.esEstudiante && aprobadas.any((i) => i.paraSiMismo))
                    _YaTienesFicha(onEntrar: estado.recargarPerfil)
                  else if (aprobadas.isNotEmpty) ...[
                    const Kicker('Mis hijos'),
                    for (final i in aprobadas) ...[
                      _TarjetaHijo(inscripcion: i),
                      const SizedBox(height: TemaModernista.esp4),
                    ],
                  ] else
                    _SinHijos(esEstudiante: usuario.esEstudiante),
                  if (enCurso.isNotEmpty) ...[
                    const SizedBox(height: TemaModernista.esp4),
                    const Kicker('Mis solicitudes'),
                    for (final i in enCurso) _FilaSolicitud(inscripcion: i),
                  ],
                ],
                const SizedBox(height: TemaModernista.esp5),
                Kicker(aprobadas.isEmpty ? 'Escuelas disponibles' : 'Inscribir en otra escuela'),
                FutureBuilder<List<Escuela>>(
                  future: _escuelas,
                  builder: (context, snapE) {
                    if (snapE.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.all(TemaModernista.esp4),
                        child: Center(child: CircularProgressIndicator(color: TemaModernista.acento)),
                      );
                    }
                    final escuelas = snapE.data ?? const [];
                    if (escuelas.isEmpty) {
                      return const Vacio(
                        titulo: 'Aún no hay escuelas',
                        texto: 'Pronto aparecerán aquí las escuelas registradas. Vuelve a revisar más tarde.',
                        icono: Icons.stadium_outlined,
                      );
                    }
                    return Column(
                      children: [
                        for (final e in escuelas) ...[
                          FilaEscuela(escuela: e, onTap: () => _abrirEscuela(e)),
                          const SizedBox(height: TemaModernista.esp3),
                        ],
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SinHijos extends StatelessWidget {
  const _SinHijos({required this.esEstudiante});
  final bool esEstudiante;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: TemaModernista.fondoOscuro,
        padding: const EdgeInsets.all(TemaModernista.esp4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(esEstudiante ? 'AÚN NO ESTÁS EN UNA ESCUELA' : 'AÚN NO TIENES HIJOS REGISTRADOS',
                style: TemaModernista.titulo(18, color: Colors.white)),
            const SizedBox(height: TemaModernista.esp2),
            Text(
              esEstudiante
                  ? 'Elige una escuela de la lista y pide tu cupo. Si ya entrenas en una, elígela igual: el profesor te vinculará a tu ficha.'
                  : 'Elige la escuela que más te guste y pide el cupo para tu hijo. Si ya entrena en una, elígela igual: el profesor lo vinculará a su ficha.',
              style: TemaModernista.cuerpo(tam: 12, color: TemaModernista.neutral400),
            ),
          ],
        ),
      );
}

class _YaTienesFicha extends StatelessWidget {
  const _YaTienesFicha({required this.onEntrar});
  final Future<void> Function() onEntrar;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: TemaModernista.fondoOscuro,
        padding: const EdgeInsets.all(TemaModernista.esp4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¡YA ERES PARTE DEL PLANTEL!', style: TemaModernista.titulo(18, color: Colors.white)),
            const SizedBox(height: TemaModernista.esp3),
            BotonModernista('Entrar a mi escuela', onTap: onEntrar),
          ],
        ),
      );
}

class _FilaSolicitud extends StatelessWidget {
  const _FilaSolicitud({required this.inscripcion});
  final Inscripcion inscripcion;

  @override
  Widget build(BuildContext context) {
    final i = inscripcion;
    final rechazada = i.estado == EstadoInscripcion.rechazada;
    return Container(
      margin: const EdgeInsets.only(bottom: TemaModernista.esp2),
      padding: const EdgeInsets.all(TemaModernista.esp3),
      decoration: BoxDecoration(border: Border.all(color: TemaModernista.neutral300)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(i.nombreJugador, style: TemaModernista.cuerpo(tam: 14, peso: FontWeight.w600)),
                Text(i.nombreEscuela, style: TemaModernista.cuerpo(tam: 12, color: TemaModernista.neutral800)),
              ],
            ),
          ),
          Etiqueta(i.estado.etiqueta, fondo: rechazada ? TemaModernista.acento100 : TemaModernista.neutral200),
        ],
      ),
    );
  }
}

/// Tarjeta de un hijo: carga su resumen de la escuela donde está inscrito.
class _TarjetaHijo extends StatefulWidget {
  const _TarjetaHijo({required this.inscripcion});
  final Inscripcion inscripcion;

  @override
  State<_TarjetaHijo> createState() => _TarjetaHijoState();
}

class _TarjetaHijoState extends State<_TarjetaHijo> {
  Future<ResumenJugador?>? _resumen;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resumen ??= AlcanceApp.de(context).resumenDe(widget.inscripcion);
  }

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(border: Border.all(color: TemaModernista.divisor, width: 2)),
        child: FutureBuilder<ResumenJugador?>(
          future: _resumen,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(TemaModernista.esp5),
                child: Center(child: CircularProgressIndicator(color: TemaModernista.acento)),
              );
            }
            final r = snap.data;
            if (r == null) {
              return Padding(
                padding: const EdgeInsets.all(TemaModernista.esp4),
                child: Text('No pudimos cargar los datos de ${widget.inscripcion.nombreJugador}.',
                    style: TemaModernista.cuerpo()),
              );
            }
            final j = r.jugador;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: TemaModernista.fondoOscuro,
                  padding: const EdgeInsets.all(TemaModernista.esp4),
                  child: Row(
                    children: [
                      Text('${j.dorsal}', style: TemaModernista.titulo(40, color: TemaModernista.acento)),
                      const SizedBox(width: TemaModernista.esp4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(j.nombre.toUpperCase(), style: TemaModernista.titulo(18, color: Colors.white)),
                            Text('${j.detallePosicion} · ${r.nombreEscuela}'.toUpperCase(),
                                style: TemaModernista.etiqueta(color: TemaModernista.neutral400, tam: 9)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                GrillaCifras(celdas: [
                  CeldaCifra(valor: '${j.estadisticas.goles}', rotulo: 'Goles', color: TemaModernista.acento),
                  CeldaCifra(valor: '${j.estadisticas.asistencias}', rotulo: 'Asistencias'),
                  CeldaCifra(valor: '${j.estadisticas.partidos}', rotulo: 'Partidos'),
                ]),
                Padding(
                  padding: const EdgeInsets.all(TemaModernista.esp4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Kicker('Asistencia a entrenos'),
                      Row(
                        children: [
                          Text('${r.entrenosAsistidos}/${r.entrenosRegistrados}', style: TemaModernista.titulo(22)),
                          const SizedBox(width: TemaModernista.esp3),
                          Expanded(child: BarraValor(porcentaje: r.porcentajeAsistencia)),
                        ],
                      ),
                      if (r.entrenosRegistrados == 0)
                        Text('El profesor aún no ha tomado lista.',
                            style: TemaModernista.cuerpo(tam: 11, color: TemaModernista.neutral800)),
                      const SizedBox(height: TemaModernista.esp4),
                      const Kicker('Cuotas'),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              r.alDia ? 'Al día' : 'Debe ${CajaMensual.formatearPesos(r.deuda)}',
                              style: TemaModernista.titulo(22,
                                  color: r.alDia ? TemaModernista.tinta : TemaModernista.acento),
                            ),
                          ),
                          if (!r.alDia)
                            Etiqueta('${r.cuotasPendientes.length} pendiente${r.cuotasPendientes.length == 1 ? '' : 's'}',
                                fondo: TemaModernista.acento100, tinta: TemaModernista.acento700),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
}

/// Pedido de cupo: nombre del hijo (o el propio), edad, teléfono y nota.
class _FormularioInscripcion extends StatefulWidget {
  const _FormularioInscripcion({required this.escuela});
  final Escuela escuela;

  static Future<void> abrir(BuildContext context, Escuela escuela) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        builder: (_) => _FormularioInscripcion(escuela: escuela),
      );

  @override
  State<_FormularioInscripcion> createState() => _FormularioInscripcionState();
}

class _FormularioInscripcionState extends State<_FormularioInscripcion> {
  final _nombre = TextEditingController();
  final _edad = TextEditingController();
  final _telefono = TextEditingController();
  final _nota = TextEditingController();
  bool _yaEntrena = false;
  bool _enviando = false;
  String? _error;
  bool _iniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    final u = AlcanceApp.de(context).usuario;
    if (u is Familia && u.esEstudiante) _nombre.text = u.nombre;
  }

  @override
  void dispose() {
    for (final c in [_nombre, _edad, _telefono, _nota]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _enviar(AppEstado estado) async {
    final edad = int.tryParse(_edad.text.trim());
    if (_nombre.text.trim().length < 3) return setState(() => _error = 'Escribe el nombre completo.');
    if (edad == null || edad < 3 || edad > 25) return setState(() => _error = 'Escribe una edad válida.');
    if (_telefono.text.trim().length < 7) return setState(() => _error = 'Escribe un teléfono de contacto.');
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      final nota = [
        if (_yaEntrena) 'Ya entrena en esta escuela.',
        if (_nota.text.trim().isNotEmpty) _nota.text.trim(),
      ].join(' ');
      await estado.inscribir(widget.escuela,
          nombreJugador: _nombre.text, edad: edad, telefono: _telefono.text, nota: nota);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Solicitud enviada a ${widget.escuela.nombre}. El profesor te responderá pronto.')),
      );
    } catch (e) {
      debugPrint('Error enviando inscripción: $e');
      if (mounted) setState(() => _error = 'No se pudo enviar. Revisa tu conexión e intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = AlcanceApp.de(context);
    final esEstudiante = (estado.usuario as Familia).esEstudiante;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TemaModernista.esp5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('PEDIR CUPO', style: TemaModernista.titulo(22)),
            Text(widget.escuela.nombre, style: TemaModernista.cuerpo(tam: 12, color: TemaModernista.neutral800)),
            const SizedBox(height: TemaModernista.esp4),
            TextField(
              controller: _nombre,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: esEstudiante ? 'TU NOMBRE COMPLETO' : 'NOMBRE DE TU HIJO'),
            ),
            const SizedBox(height: TemaModernista.esp3),
            TextField(
              controller: _edad,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'EDAD'),
            ),
            const SizedBox(height: TemaModernista.esp3),
            TextField(
              controller: _telefono,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'TELÉFONO DE CONTACTO'),
            ),
            const SizedBox(height: TemaModernista.esp3),
            TextField(
              controller: _nota,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'NOTA PARA EL PROFESOR (OPCIONAL)'),
            ),
            CheckboxListTile(
              value: _yaEntrena,
              onChanged: (v) => setState(() => _yaEntrena = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: TemaModernista.acento,
              title: Text(esEstudiante ? 'Ya entreno en esta escuela' : 'Ya entrena en esta escuela',
                  style: TemaModernista.cuerpo(tam: 13)),
            ),
            if (_error != null) ...[
              MensajeError(_error!),
              const SizedBox(height: TemaModernista.esp3),
            ],
            BotonModernista(_enviando ? 'Enviando…' : 'Enviar solicitud', onTap: _enviando ? null : () => _enviar(estado)),
          ],
        ),
      ),
    );
  }
}
