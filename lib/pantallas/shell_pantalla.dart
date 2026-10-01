import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

/// Carcasa de la app: chrome oscuro (header + nav), contenido sobre blanco.
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

  void _cambiarTab(int i) {
    if (i == _indice) return;
    HapticFeedback.selectionClick();
    setState(() => _indice = i);
  }

  @override
  Widget build(BuildContext context) {
    final estado   = AlcanceApp.de(context);
    final destinos = _destinos(estado);
    final indice   = _indice.clamp(0, destinos.length - 1);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header oscuro ───────────────────────────────────────────────
            _BarraSuperior(estado: estado),

            // ── Contenido (fondo blanco) ───────────────────────────────────
            Expanded(
                child: ContenidoResponsivo(
                    child: destinos[indice].constructor(context))),

            // ── Aviso (animado) ────────────────────────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: estado.aviso != null
                  ? _Aviso(texto: estado.aviso!)
                  : const SizedBox(width: double.infinity),
            ),

            // ── Línea roja divisora ────────────────────────────────────────
            const Regla(color: TemaModernista.acento),

            // ── Nav inferior oscura ────────────────────────────────────────
            _NavInferior(
              destinos: destinos,
              indice: indice,
              onCambiar: _cambiarTab,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _BarraSuperior extends StatelessWidget {
  const _BarraSuperior({required this.estado});
  final AppEstado estado;

  @override
  Widget build(BuildContext context) {
    final u = estado.usuario!;
    return Container(
      color: TemaModernista.fondoOscuro,
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
                style: TemaModernista.titulo(16, color: Colors.white)),
          ),
          const SizedBox(width: TemaModernista.esp3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(estado.nombreClub.toUpperCase(),
                    style:
                        TemaModernista.titulo(15, color: Colors.white)),
                Text(estado.categoria.toUpperCase(),
                    style: TemaModernista.etiqueta(
                        color: TemaModernista.neutral400, tam: 9)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: estado.salir,
            style: OutlinedButton.styleFrom(
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero),
              side: const BorderSide(color: TemaModernista.neutral400),
              padding: const EdgeInsets.symmetric(
                  horizontal: TemaModernista.esp2, vertical: 4),
              minimumSize: Size.zero,
              foregroundColor: Colors.white,
            ),
            child: Text('${u.rolCorto} · SALIR',
                style:
                    TemaModernista.etiqueta(color: Colors.white, tam: 9)),
          ),
        ],
      ),
    );
  }
}

// ── Nav inferior ─────────────────────────────────────────────────────────────

/// Ítem individual con transiciones de color fluidas sobre fondo oscuro.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destino,
    required this.seleccionado,
    required this.onTap,
  });
  final Destino destino;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: TemaModernista.acento.withOpacity(0.15),
        highlightColor: TemaModernista.acento.withOpacity(0.08),
        child: Stack(
          children: [
            // Indicador rojo superior — aparece animado
            Positioned(
              top: 0, left: 0, right: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                height: 3,
                color: seleccionado
                    ? TemaModernista.acento
                    : Colors.transparent,
              ),
            ),
            // Ícono + etiqueta
            Padding(
              padding: const EdgeInsets.only(top: 9, bottom: 11),
              child: Column(
                children: [
                  TweenAnimationBuilder<Color?>(
                    tween: ColorTween(
                      end: seleccionado
                          ? TemaModernista.acento
                          : TemaModernista.neutral400,
                    ),
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    builder: (_, color, __) => Icon(
                      destino.icono,
                      size: 21,
                      color: color ??
                          (seleccionado
                              ? TemaModernista.acento
                              : TemaModernista.neutral400),
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    style: TemaModernista.etiqueta(
                      color: seleccionado
                          ? TemaModernista.acento
                          : TemaModernista.neutral400,
                      tam: 8.5,
                    ),
                    child: Text(destino.etiqueta.toUpperCase()),
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

class _NavInferior extends StatelessWidget {
  const _NavInferior(
      {required this.destinos, required this.indice, required this.onCambiar});
  final List<Destino> destinos;
  final int indice;
  final ValueChanged<int> onCambiar;

  @override
  Widget build(BuildContext context) => Container(
        color: TemaModernista.fondoOscuro,
        child: Row(
          children: [
            for (var i = 0; i < destinos.length; i++)
              _NavItem(
                destino: destinos[i],
                seleccionado: i == indice,
                onTap: () => onCambiar(i),
              ),
          ],
        ),
      );
}

// ── Aviso ────────────────────────────────────────────────────────────────────

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
