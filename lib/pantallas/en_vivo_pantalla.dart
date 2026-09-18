import 'package:flutter/material.dart';

import '../core/tema_modernista.dart';
import '../estado/app_estado.dart';
import '../modelos/partido.dart';
import '../modelos/usuario.dart';
import '../widgets/comunes.dart';

/// Partido en vivo. El DT tiene la consola (gol, cambio, tarjeta, reloj);
/// el jugador recibe la misma pantalla en modo lectura.
class EnVivoPantalla extends StatelessWidget {
  const EnVivoPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = AlcanceApp.de(context);
    final dirige = estado.puede(Permiso.dirigirPartido);
    final p = estado.partidoActual;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Tablero(partido: p),
            if (dirige)
              Container(
                color: TemaModernista.neutral300,
                child: Row(
                  children: [
                    _accion('Gol', () => estado.anotarGol()),
                    const SizedBox(width: 1),
                    _accion('Cambio', () => _hojaCambio(context, estado)),
                    const SizedBox(width: 1),
                    _accion('Tarjeta', () => estado.anotarTarjeta(estado.alineacion.titulares[5])),
                    const SizedBox(width: 1),
                    _accion(p.enJuego ? 'Pausa' : 'Seguir', estado.alternarReloj),
                  ],
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
                children: [
                  const Kicker('Minuto a minuto'),
                  const Regla(),
                  for (final e in p.eventos)
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: TemaModernista.neutral300)),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 34,
                            child: Text("${e.minuto}'",
                                style: TemaModernista.titulo(14).copyWith(color: TemaModernista.acento)),
                          ),
                          Etiqueta(
                            e.tipo,
                            fondo: e.esDestacado ? TemaModernista.acento : TemaModernista.neutral200,
                            tinta: e.esDestacado ? Colors.white : TemaModernista.neutral800,
                          ),
                          const SizedBox(width: TemaModernista.esp3),
                          Expanded(child: Text(e.descripcion, style: TemaModernista.cuerpo())),
                        ],
                      ),
                    ),
                  if (dirige) ...[
                    const SizedBox(height: TemaModernista.esp4),
                    Row(
                      children: [
                        Expanded(
                          child: BotonModernista('Descargar acta',
                              variante: VarianteBoton.secundario,
                              onTap: () => estado.descargar(p, estado.formatosActa.first)),
                        ),
                        const SizedBox(width: TemaModernista.esp2),
                        Expanded(child: BotonModernista('Finalizar', onTap: estado.finalizarPartido)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accion(String texto, VoidCallback onTap) => Expanded(
        child: InkWell(
          onTap: onTap,
          child: Container(
            color: TemaModernista.fondo,
            padding: const EdgeInsets.symmetric(vertical: 14),
            alignment: Alignment.center,
            child: Text(texto.toUpperCase(), style: TemaModernista.etiqueta(tam: 11)),
          ),
        ),
      );

  void _hojaCambio(BuildContext context, AppEstado estado) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: TemaModernista.fondo,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text("Cambio al minuto ${estado.partidoActual.minuto}'", style: TemaModernista.titulo(20)),
            ),
            const Regla(),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final j in estado.banca.where((j) => j.disponible))
                    ListTile(
                      title: Text('Entra ${j.dorsal} · ${j.nombre}', style: TemaModernista.cuerpo()),
                      subtitle: Text('Toca para elegir quién sale',
                          style: TemaModernista.cuerpo(tam: 11, color: TemaModernista.neutral400)),
                      onTap: () {
                        Navigator.of(context).pop();
                        showModalBottomSheet<void>(
                          context: context,
                          backgroundColor: TemaModernista.fondo,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          builder: (_) => SafeArea(
                            child: ListView(
                              shrinkWrap: true,
                              children: [
                                for (final f in estado.alineacion.fichas)
                                  ListTile(
                                    title: Text('Sale ${f.jugador.dorsal} · ${f.jugador.nombre}',
                                        style: TemaModernista.cuerpo()),
                                    onTap: () {
                                      estado.sustituir(saleId: f.jugador.id, entra: j);
                                      Navigator.of(context).pop();
                                    },
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tablero extends StatelessWidget {
  const _Tablero({required this.partido});
  final Partido partido;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: TemaModernista.acento,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 8, height: 8, color: Colors.white),
                const SizedBox(width: TemaModernista.esp2),
                Text(
                  partido.estado == EstadoPartido.finalizado ? 'FINALIZADO' : 'EN VIVO',
                  style: TemaModernista.etiqueta(color: Colors.white, tam: 10),
                ),
                const Spacer(),
                Text("${partido.minuto}'", style: TemaModernista.titulo(15).copyWith(color: Colors.white)),
              ],
            ),
            const SizedBox(height: TemaModernista.esp3),
            Row(
              children: [
                Expanded(
                  child: Text('MAKUIRA', style: TemaModernista.titulo(17).copyWith(color: Colors.white)),
                ),
                Text(partido.marcador, style: TemaModernista.titulo(42).copyWith(color: Colors.white)),
                Expanded(
                  child: Text(partido.rival.toUpperCase(),
                      textAlign: TextAlign.right,
                      style: TemaModernista.titulo(17).copyWith(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      );
}
