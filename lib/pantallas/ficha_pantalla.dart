import 'package:flutter/material.dart';

import '../core/tema_modernista.dart';
import '../estado/app_estado.dart';
import '../modelos/finanzas.dart';
import '../modelos/jugador.dart';
import '../modelos/usuario.dart';
import '../widgets/comunes.dart';

/// Ficha de jugador. Con [FichaPantalla.propia] es la pestaña "Yo" del
/// jugador: su rendimiento, su asistencia y su cuota — nada del resto.
class FichaPantalla extends StatelessWidget {
  const FichaPantalla({super.key, required this.jugadorId}) : propia = false;
  const FichaPantalla.propia({super.key}) : jugadorId = null, propia = true;

  final int? jugadorId;
  final bool propia;

  @override
  Widget build(BuildContext context) {
    final estado = AlcanceApp.de(context);
    final j = propia ? estado.miFicha! : estado.plantel.firstWhere((x) => x.id == jugadorId);

    // Defensa en profundidad: aunque alguien navegue a mano, sin permiso no hay ficha.
    if (!estado.puedeAbrirFicha(j)) {
      return Center(child: Text('Sin acceso a esta ficha', style: TemaModernista.cuerpo()));
    }

    final esDT = estado.puede(Permiso.verFichaAjena);
    final cuota = propia ? estado.miCuota : null;
    final contenido = ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 26),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 92,
              height: 112,
              color: TemaModernista.neutral300,
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.all(6),
              child: Text('FOTO', style: TemaModernista.etiqueta(color: TemaModernista.neutral800, tam: 9)),
            ),
            const SizedBox(width: TemaModernista.esp3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${j.dorsal}', style: TemaModernista.titulo(44).copyWith(color: TemaModernista.acento)),
                  const SizedBox(height: 4),
                  Text(j.nombre, style: TemaModernista.titulo(19)),
                  const SizedBox(height: 6),
                  Text('${j.detallePosicion.toUpperCase()} · ${j.pieHabil.toUpperCase()} · ${j.edad} AÑOS',
                      style: TemaModernista.etiqueta(color: TemaModernista.neutral800, tam: 9)),
                  const SizedBox(height: TemaModernista.esp2),
                  Etiqueta(
                    j.estado.etiqueta,
                    fondo: j.estado == EstadoFisico.lesionado ? TemaModernista.acento : TemaModernista.neutral200,
                    tinta: j.estado == EstadoFisico.lesionado ? Colors.white : TemaModernista.neutral800,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: TemaModernista.esp4),
        const Regla(),
        const SizedBox(height: TemaModernista.esp4),
        GrillaCifras(celdas: [
          CeldaCifra(valor: '${j.estadisticas.partidos}', rotulo: 'PJ'),
          CeldaCifra(valor: '${j.estadisticas.goles}', rotulo: 'Goles'),
          CeldaCifra(valor: '${j.estadisticas.asistencias}', rotulo: 'Asist.'),
          CeldaCifra(valor: '${j.estadisticas.minutos}', rotulo: 'Min'),
        ]),
        const SizedBox(height: TemaModernista.esp5),
        const Kicker('Perfil'),
        for (final a in j.atributos.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Row(
              children: [
                SizedBox(
                  width: 82,
                  child: Text(a.key.toUpperCase(),
                      style: TemaModernista.etiqueta(color: TemaModernista.neutral800, tam: 10)),
                ),
                Expanded(child: BarraValor(porcentaje: a.value / 100)),
                const SizedBox(width: TemaModernista.esp2),
                SizedBox(width: 24, child: Text('${a.value}', style: TemaModernista.titulo(12))),
              ],
            ),
          ),
        if (propia && cuota != null) ...[
          const SizedBox(height: TemaModernista.esp5),
          const Kicker('Mi cuota'),
          Container(
            decoration: const BoxDecoration(
              border: Border.fromBorderSide(BorderSide(color: TemaModernista.divisor, width: 2)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(CajaMensual.formatearPesos(cuota.monto), style: TemaModernista.titulo(19)),
                      Text('${cuota.periodo} · vence el 30',
                          style: TemaModernista.cuerpo(tam: 11, color: TemaModernista.neutral400)),
                    ],
                  ),
                ),
                Etiqueta(
                  cuota.etiqueta,
                  fondo: cuota.alDia ? TemaModernista.neutral200 : TemaModernista.acento,
                  tinta: cuota.alDia ? TemaModernista.neutral800 : Colors.white,
                ),
              ],
            ),
          ),
          const SizedBox(height: TemaModernista.esp2),
          BotonModernista(
            cuota.alDia ? 'Descargar recibo' : 'Reportar pago',
            onTap: estado.reportarMiPago,
          ),
          const SizedBox(height: TemaModernista.esp2),
          BotonModernista('Cerrar sesión', variante: VarianteBoton.secundario, onTap: estado.salir),
        ],
        if (esDT) ...[
          const SizedBox(height: TemaModernista.esp5),
          Row(
            children: [
              Expanded(
                child: BotonModernista('Convocar', onTap: () => estado.alternarConvocado(j)),
              ),
              const SizedBox(width: TemaModernista.esp2),
              Expanded(
                child: BotonModernista('Cambiar estado',
                    variante: VarianteBoton.secundario,
                    onTap: () {
                      final siguiente = EstadoFisico
                          .values[(EstadoFisico.values.indexOf(j.estado) + 1) % EstadoFisico.values.length];
                      j.cambiarEstado(siguiente);
                      estado.avisar('${j.apellido}: ${siguiente.etiqueta}');
                    }),
              ),
            ],
          ),
        ],
      ],
    );

    // Como pestaña vive dentro del shell; como ficha ajena abre con su propio Scaffold.
    return propia ? contenido : Scaffold(appBar: AppBar(title: Text(j.nombre)), body: contenido);
  }
}
