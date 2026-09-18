import 'package:flutter/material.dart';

import '../core/tema_modernista.dart';
import '../estado/app_estado.dart';
import '../modelos/usuario.dart';
import '../widgets/comunes.dart';
import 'agenda_pantalla.dart';
import 'club_pantalla.dart';
import 'ficha_pantalla.dart';
import 'inicio_pantalla.dart';
import 'pizarra_pantalla.dart';
import 'plantel_pantalla.dart';

/// Descripción de una pestaña: la construye el rol, no la pantalla.
class Destino {
  const Destino(
      {required this.etiqueta, required this.icono, required this.constructor});
  final String etiqueta;
  final IconData icono;
  final WidgetBuilder constructor;
}

/// Carcasa de la app: barra superior, contenido y navegación por rol.
/// El DT y el jugador reciben listas de destinos distintas.
class ShellPantalla extends StatefulWidget {
  const ShellPantalla({super.key});

  @override
  State<ShellPantalla> createState() => _ShellPantallaState();
}

class _ShellPantallaState extends State<ShellPantalla> {
  int _indice = 0;

  List<Destino> _destinos(AppEstado estado) {
    if (estado.puede(Permiso.editarAlineacion)) {
      return [
        Destino(
            etiqueta: 'Inicio',
            icono: Icons.home_outlined,
            constructor: (_) => const InicioPantalla()),
        Destino(
            etiqueta: 'Plantel',
            icono: Icons.groups_outlined,
            constructor: (_) => const PlantelPantalla()),
        Destino(
            etiqueta: 'Táctica',
            icono: Icons.grid_on_outlined,
            constructor: (_) => const PizarraPantalla()),
        Destino(
            etiqueta: 'Agenda',
            icono: Icons.calendar_today_outlined,
            constructor: (_) => const AgendaPantalla()),
        Destino(
            etiqueta: 'Club',
            icono: Icons.account_balance_wallet_outlined,
            constructor: (_) => const ClubPantalla()),
      ];
    }
    return [
      Destino(
          etiqueta: 'Inicio',
          icono: Icons.home_outlined,
          constructor: (_) => const InicioPantalla()),
      Destino(
          etiqueta: 'Equipo',
          icono: Icons.groups_outlined,
          constructor: (_) => const PlantelPantalla()),
      Destino(
          etiqueta: 'Alineación',
          icono: Icons.grid_on_outlined,
          constructor: (_) => const PizarraPantalla()),
      Destino(
          etiqueta: 'Agenda',
          icono: Icons.calendar_today_outlined,
          constructor: (_) => const AgendaPantalla()),
      Destino(
          etiqueta: 'Yo',
          icono: Icons.person_outline,
          constructor: (_) => const FichaPantalla.propia()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final estado = AlcanceApp.de(context);
    final destinos = _destinos(estado);
    final indice = _indice.clamp(0, destinos.length - 1);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _BarraSuperior(estado: estado),
            Expanded(
                child: ContenidoResponsivo(
                    child: destinos[indice].constructor(context))),
            if (estado.aviso != null) _Aviso(texto: estado.aviso!),
            const Regla(),
            _NavInferior(
              destinos: destinos,
              indice: indice,
              onCambiar: (i) => setState(() => _indice = i),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarraSuperior extends StatelessWidget {
  const _BarraSuperior({required this.estado});
  final AppEstado estado;

  @override
  Widget build(BuildContext context) {
    final u = estado.usuario!;
    return Container(
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color: TemaModernista.divisor,
                width: TemaModernista.reglaFuerte)),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: TemaModernista.esp4, vertical: TemaModernista.esp3),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            color: TemaModernista.acento,
            alignment: Alignment.center,
            child: Text('M',
                style: TemaModernista.titulo(16).copyWith(color: Colors.white)),
          ),
          const SizedBox(width: TemaModernista.esp3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(estado.nombreClub.toUpperCase(),
                    style: TemaModernista.titulo(15)),
                Text(estado.categoria.toUpperCase(),
                    style: TemaModernista.etiqueta(
                        color: TemaModernista.neutral800, tam: 9)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: estado.salir,
            style: OutlinedButton.styleFrom(
              shape:
                  const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              side: const BorderSide(color: TemaModernista.neutral400),
              padding: const EdgeInsets.symmetric(
                  horizontal: TemaModernista.esp2, vertical: 4),
              minimumSize: Size.zero,
            ),
            child: Text('${u.rolCorto} · SALIR',
                style: TemaModernista.etiqueta(tam: 9)),
          ),
        ],
      ),
    );
  }
}

class _NavInferior extends StatelessWidget {
  const _NavInferior(
      {required this.destinos, required this.indice, required this.onCambiar});
  final List<Destino> destinos;
  final int indice;
  final ValueChanged<int> onCambiar;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          for (var i = 0; i < destinos.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => onCambiar(i),
                child: Stack(
                  children: [
                    if (i == indice)
                      Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                              height: 3, color: TemaModernista.acento)),
                    Padding(
                      padding: const EdgeInsets.only(top: 9, bottom: 11),
                      child: Column(
                        children: [
                          Icon(destinos[i].icono,
                              size: 21,
                              color: i == indice
                                  ? TemaModernista.acento
                                  : TemaModernista.neutral400),
                          const SizedBox(height: 4),
                          Text(
                            destinos[i].etiqueta.toUpperCase(),
                            style: TemaModernista.etiqueta(
                              color: i == indice
                                  ? TemaModernista.acento
                                  : TemaModernista.neutral400,
                              tam: 8.5,
                            ),
                          ),
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

class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto});
  final String texto;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: TemaModernista.tinta,
        padding: const EdgeInsets.symmetric(
            horizontal: TemaModernista.esp3, vertical: 11),
        child: Row(
          children: [
            Container(width: 8, height: 8, color: TemaModernista.acento),
            const SizedBox(width: TemaModernista.esp3),
            Expanded(
                child: Text(texto,
                    style: TemaModernista.cuerpo(
                        tam: 12.5, color: TemaModernista.fondo))),
          ],
        ),
      );
}
