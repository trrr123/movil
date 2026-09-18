import 'package:flutter/material.dart';

import '../core/tema_modernista.dart';
import '../estado/app_estado.dart';
import '../modelos/jugador.dart';
import '../modelos/usuario.dart';
import '../widgets/comunes.dart';
import 'ficha_pantalla.dart';

/// Plantel para el DT; "Equipo" en modo consulta para el jugador:
/// mismos nombres, sin minutos, goles ni estado médico ajenos.
class PlantelPantalla extends StatefulWidget {
  const PlantelPantalla({super.key});

  @override
  State<PlantelPantalla> createState() => _PlantelPantallaState();
}

class _PlantelPantallaState extends State<PlantelPantalla> {
  String _busqueda = '';
  Posicion? _filtro;

  @override
  Widget build(BuildContext context) {
    final estado = AlcanceApp.de(context);
    final verMetricas = estado.puede(Permiso.verFichaAjena);
    final lista = estado.buscar(_busqueda, _filtro);
    final mio = estado.miFicha?.id;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
      children: [
        Text(verMetricas ? 'PLANTEL' : 'EQUIPO', style: TemaModernista.titulo(28)),
        const SizedBox(height: 4),
        Text(
          verMetricas
              ? '${estado.plantel.length} jugadores registrados · ${estado.lesionados} en recuperación'
              : 'Tus compañeros de plantel · solo consulta',
          style: TemaModernista.cuerpo(tam: 11, color: TemaModernista.neutral400),
        ),
        const SizedBox(height: TemaModernista.esp3),
        TextField(
          decoration: InputDecoration(hintText: verMetricas ? 'Buscar jugador' : 'Buscar compañero'),
          onChanged: (v) => setState(() => _busqueda = v),
        ),
        const SizedBox(height: TemaModernista.esp3),
        Container(
          decoration: const BoxDecoration(
            border: Border.fromBorderSide(BorderSide(color: TemaModernista.neutral400)),
          ),
          child: Row(
            children: [
              _chip('Todos', null),
              for (final p in Posicion.values) _chip(p.sigla, p),
            ],
          ),
        ),
        const SizedBox(height: TemaModernista.esp3),
        const Regla(),
        if (lista.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: TemaModernista.esp5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Kicker('Sin resultados'),
                Text('Nadie coincide con esa búsqueda.',
                    style: TemaModernista.cuerpo(tam: 12, color: TemaModernista.neutral400)),
              ],
            ),
          ),
        for (final j in lista)
          InkWell(
            onTap: () {
              if (estado.puedeAbrirFicha(j)) {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => FichaPantalla(jugadorId: j.id)));
              } else {
                estado.avisar('Solo el cuerpo técnico ve las fichas de los demás');
              }
            },
            child: Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: TemaModernista.neutral300)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text('${j.dorsal}',
                        textAlign: TextAlign.right,
                        style: TemaModernista.titulo(19).copyWith(
                          color: estado.alineacion.contiene(j.id) ? TemaModernista.acento : TemaModernista.neutral400,
                        )),
                  ),
                  const SizedBox(width: TemaModernista.esp3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(j.nombre, style: TemaModernista.cuerpo(tam: 14, peso: FontWeight.w600)),
                        Text('${j.detallePosicion.toUpperCase()} · ${j.edad} AÑOS',
                            style: TemaModernista.etiqueta(color: TemaModernista.neutral400, tam: 9)),
                      ],
                    ),
                  ),
                  if (verMetricas) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("${j.estadisticas.minutos}'",
                            style: TemaModernista.cuerpo(tam: 12, peso: FontWeight.w600)),
                        Text('${j.estadisticas.goles} G · ${j.estadisticas.asistencias} A',
                            style: TemaModernista.cuerpo(tam: 10, color: TemaModernista.neutral400)),
                      ],
                    ),
                    const SizedBox(width: TemaModernista.esp2),
                    Etiqueta(
                      j.estado.etiqueta,
                      fondo: j.estado == EstadoFisico.lesionado
                          ? TemaModernista.acento
                          : j.estado == EstadoFisico.cargaAlta
                              ? TemaModernista.acento200
                              : TemaModernista.neutral200,
                      tinta: j.estado == EstadoFisico.lesionado ? Colors.white : TemaModernista.neutral800,
                    ),
                  ] else
                    Text(
                      j.id == mio ? 'TÚ' : (estado.alineacion.contiene(j.id) ? 'TITULAR' : ''),
                      style: TemaModernista.etiqueta(
                        color: j.id == mio ? TemaModernista.acento : TemaModernista.neutral400,
                        tam: 9,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _chip(String texto, Posicion? valor) => Expanded(
        child: InkWell(
          onTap: () => setState(() => _filtro = valor),
          child: Container(
            color: _filtro == valor ? TemaModernista.acento : Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: TemaModernista.esp2),
            alignment: Alignment.center,
            child: Text(texto.toUpperCase(),
                style: TemaModernista.etiqueta(
                    color: _filtro == valor ? Colors.white : TemaModernista.tinta, tam: 10)),
          ),
        ),
      );
}
