import 'package:flutter/material.dart';

import '../core/tema_modernista.dart';
import '../estado/app_estado.dart';
import '../modelos/finanzas.dart';
import '../modelos/usuario.dart';
import '../widgets/comunes.dart';

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
            final j = estado.plantel.firstWhere((x) => x.id == c.jugadorId);
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
