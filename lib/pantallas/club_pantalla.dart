import 'package:flutter/material.dart';

import '../core/tema_modernista.dart';
import '../estado/app_estado.dart';
import '../modelos/finanzas.dart';
import '../modelos/usuario.dart';
import '../widgets/comunes.dart';
import 'inscripciones_pantalla.dart';

/// Caja del club: solo con [Permiso.verFinanzasClub]. El jugador jamás llega
/// acá — su pestaña "Yo" muestra únicamente su propia cuota.
class ClubPantalla extends StatelessWidget {
  const ClubPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = AlcanceApp.de(context);
    if (!estado.puede(Permiso.verFinanzasClub)) {
      return Center(child: Text('Sin acceso a las finanzas del club', style: TemaModernista.cuerpo()));
    }

    final caja = estado.caja;
    final u = estado.usuario!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
      children: [
        Text('CLUB', style: TemaModernista.titulo(28)),
        const SizedBox(height: TemaModernista.esp3),
        if (estado.puede(Permiso.gestionarInscripciones)) ...[
          const _AccesoInscripciones(),
          const SizedBox(height: TemaModernista.esp4),
        ],
        if (estado.plantel.isNotEmpty && estado.sinCuotaEsteMes.isNotEmpty) ...[
          const _CrearCuotas(),
          const SizedBox(height: TemaModernista.esp4),
        ],
        Container(
          decoration: const BoxDecoration(
            border: Border.fromBorderSide(BorderSide(color: TemaModernista.divisor, width: 2)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Kicker('Cuotas de ${caja.periodo}'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(caja.recaudadoFormateado, style: TemaModernista.titulo(34)),
                  const SizedBox(width: TemaModernista.esp2),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text('de ${caja.metaFormateada}',
                        style: TemaModernista.cuerpo(tam: 12, color: TemaModernista.neutral800)),
                  ),
                ],
              ),
              const SizedBox(height: TemaModernista.esp3),
              BarraValor(porcentaje: caja.avance, alto: 10),
              const SizedBox(height: TemaModernista.esp3),
              BotonModernista('Enviar recordatorio a ${caja.pendientes} acudientes',
                  onTap: estado.enviarRecordatorio),
            ],
          ),
        ),
        const SizedBox(height: TemaModernista.esp5),
        const Kicker('Estado por jugador'),
        const Regla(),
        for (final c in caja.cuotas)
          Builder(builder: (context) {
            // Una cuota puede quedar de un jugador que ya no está en el plantel.
            final j = estado.plantel.where((x) => x.id == c.jugadorId).firstOrNull;
            if (j == null) return const SizedBox.shrink();
            return InkWell(
              onTap: () => estado.confirmarPago(c),
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: TemaModernista.neutral300)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Row(
                  children: [
                    SizedBox(
                      width: 26,
                      child: Text('${j.dorsal}',
                          textAlign: TextAlign.right,
                          style: TemaModernista.titulo(15).copyWith(color: TemaModernista.neutral800)),
                    ),
                    const SizedBox(width: TemaModernista.esp3),
                    Expanded(child: Text(j.nombre, style: TemaModernista.cuerpo())),
                    Text(CajaMensual.formatearPesos(c.monto),
                        style: TemaModernista.cuerpo(tam: 12, color: TemaModernista.neutral800)),
                    const SizedBox(width: TemaModernista.esp2),
                    Etiqueta(
                      c.etiqueta,
                      fondo: c.alDia ? TemaModernista.neutral200 : TemaModernista.acento,
                      tinta: c.alDia ? TemaModernista.neutral800 : Colors.white,
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: TemaModernista.esp5),
        const Kicker('Sesión'),
        Container(
          decoration: const BoxDecoration(
            border: Border.fromBorderSide(BorderSide(color: TemaModernista.neutral400)),
          ),
          padding: const EdgeInsets.all(TemaModernista.esp3),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                color: TemaModernista.tinta,
                alignment: Alignment.center,
                child: Text(u.inicial, style: TemaModernista.titulo(12).copyWith(color: TemaModernista.fondo)),
              ),
              const SizedBox(width: TemaModernista.esp3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.nombre, style: TemaModernista.cuerpo(peso: FontWeight.w600)),
                    Text(u.correo, style: TemaModernista.cuerpo(tam: 11, color: TemaModernista.neutral400)),
                  ],
                ),
              ),
              BotonModernista('Salir', variante: VarianteBoton.fantasma, expandido: false, onTap: estado.salir),
            ],
          ),
        ),
      ],
    );
  }
}

/// Atajo a los pedidos de cupo de las familias, con cuántos hay esperando.
class _AccesoInscripciones extends StatefulWidget {
  const _AccesoInscripciones();

  @override
  State<_AccesoInscripciones> createState() => _AccesoInscripcionesState();
}

class _AccesoInscripcionesState extends State<_AccesoInscripciones> {
  Future<int>? _pendientes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pendientes ??= _contar();
  }

  Future<int> _contar() async {
    try {
      return (await AlcanceApp.de(context).inscripcionesPendientes()).length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _abrir() async {
    await Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => const InscripcionesPantalla()));
    if (mounted) setState(() => _pendientes = _contar());
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<int>(
        future: _pendientes,
        builder: (context, snap) {
          final n = snap.data ?? 0;
          return InkWell(
            onTap: _abrir,
            child: Container(
              color: TemaModernista.fondoOscuro,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Text('$n', style: TemaModernista.titulo(30, color: n > 0 ? TemaModernista.acento : Colors.white)),
                  const SizedBox(width: TemaModernista.esp3),
                  Expanded(
                    child: Text(
                      n == 1 ? 'SOLICITUD DE INSCRIPCIÓN' : 'SOLICITUDES DE INSCRIPCIÓN',
                      style: TemaModernista.etiqueta(color: Colors.white),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: TemaModernista.neutral400),
                ],
              ),
            ),
          );
        },
      );
}

/// Cobro del mes: crea la cuota de cada jugador que aún no la tiene.
class _CrearCuotas extends StatefulWidget {
  const _CrearCuotas();

  @override
  State<_CrearCuotas> createState() => _CrearCuotasState();
}

class _CrearCuotasState extends State<_CrearCuotas> {
  final _monto = TextEditingController(text: '60000');
  bool _creando = false;

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  Future<void> _crear(AppEstado estado) async {
    final monto = int.tryParse(_monto.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (monto == null || monto <= 0) {
      estado.avisar('Escribe el valor de la cuota');
      return;
    }
    setState(() => _creando = true);
    try {
      await estado.crearCuotasDelMes(monto);
    } catch (e) {
      estado.avisar('No se pudieron crear las cuotas. Revisa tu conexión.');
    } finally {
      if (mounted) setState(() => _creando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = AlcanceApp.de(context);
    final faltan = estado.sinCuotaEsteMes.length;
    return Container(
      decoration: const BoxDecoration(
        border: Border.fromBorderSide(BorderSide(color: TemaModernista.acento, width: 2)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Kicker('Cuotas de ${estado.mesActual.nombre}', color: TemaModernista.acento),
          Text(
            faltan == estado.plantel.length
                ? 'Aún no has cobrado este mes. Crea la cuota de los $faltan jugadores.'
                : '$faltan jugador${faltan == 1 ? '' : 'es'} sin cuota este mes (recién inscritos).',
            style: TemaModernista.cuerpo(tam: 12),
          ),
          const SizedBox(height: TemaModernista.esp3),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _monto,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'VALOR (PESOS)'),
                ),
              ),
              const SizedBox(width: TemaModernista.esp3),
              BotonModernista(_creando ? 'Creando…' : 'Crear cuotas',
                  expandido: false, onTap: _creando ? null : () => _crear(estado)),
            ],
          ),
        ],
      ),
    );
  }
}
