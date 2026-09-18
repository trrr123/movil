import 'package:flutter/material.dart';

import '../core/tema_modernista.dart';

/// Animación de entrada: la cancha se dibuja trazo a trazo, entra la marca
/// y el plano hace zoom hasta la app. Un solo controlador con intervalos.
class SplashPantalla extends StatefulWidget {
  const SplashPantalla({super.key, required this.onTerminar});
  final VoidCallback onTerminar;

  @override
  State<SplashPantalla> createState() => _SplashPantallaState();
}

class _SplashPantallaState extends State<SplashPantalla> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6000),
  );

  @override
  void initState() {
    super.initState();
    // Arranca recién cuando el primer frame ya se pintó: si se dispara antes
    // (p. ej. en el arranque en frío de un emulador), el reloj de la
    // animación corre igual mientras el motor todavía carga, y el usuario
    // se pierde buena parte del dibujo de la cancha.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Pausa breve para que no se sienta como un salto brusco justo después
      // del ícono nativo de Android.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (mounted) _c.forward().whenComplete(widget.onTerminar);
    });
  }

  late final Animation<double> _trazo =
      CurvedAnimation(parent: _c, curve: const Interval(0.08, 0.55, curve: Curves.easeOut));
  late final Animation<double> _marca =
      CurvedAnimation(parent: _c, curve: const Interval(0.5, 0.68, curve: Curves.easeOutCubic));
  late final Animation<double> _zoom =
      CurvedAnimation(parent: _c, curve: const Interval(0.72, 1, curve: Curves.easeInCubic));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaModernista.fondo,
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Opacity(
            opacity: 1 - _zoom.value,
            child: Transform.scale(
              scale: 1 + _zoom.value * 4.5,
              alignment: const Alignment(0, -0.1),
              child: Stack(
                children: [
                  Positioned(top: 0, left: 0, right: 0, child: Container(height: 10, color: TemaModernista.acento)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 44, 28, 34),
                    child: CustomPaint(
                      painter: _CanchaPainter(_trazo.value),
                      child: Center(
                        child: Opacity(
                          opacity: _marca.value,
                          child: Transform.translate(
                            offset: Offset(0, 14 * (1 - _marca.value)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  color: TemaModernista.acento,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  child: Text('MAKUIRA',
                                      style: TemaModernista.titulo(40).copyWith(color: Colors.white)),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  color: TemaModernista.fondo,
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  child: Text('GESTIÓN · SUB-20',
                                      style: TemaModernista.etiqueta(tam: 10)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 28,
                    bottom: 34,
                    child: Opacity(
                      opacity: _marca.value,
                      child: Text('CARGANDO PLANTEL',
                          style: TemaModernista.etiqueta(color: TemaModernista.neutral400, tam: 9)),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(height: 10, width: MediaQuery.of(context).size.width * _c.value, color: TemaModernista.tinta),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Dibuja las líneas de la cancha en orden, según el avance 0..1.
class _CanchaPainter extends CustomPainter {
  _CanchaPainter(this.avance);
  final double avance;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = TemaModernista.tinta
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    double t(double desde, double hasta) => ((avance - desde) / (hasta - desde)).clamp(0, 1);

    // Perímetro
    final k = t(0, .45);
    final r = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawPath(_rectParcial(r, k), p);

    // Áreas
    final a = t(.35, .6);
    if (a > 0) {
      final w = size.width * .44, h = size.height * .15;
      canvas.drawRect(Rect.fromLTWH((size.width - w) / 2, 0, w, h * a), p);
      canvas.drawRect(Rect.fromLTWH((size.width - w) / 2, size.height - h * a, w, h * a), p);
    }

    // Línea media y círculo central
    final m = t(.55, .8);
    if (m > 0) {
      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width * m, size.height / 2), p);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: size.width * .17),
        -1.57,
        6.28 * m,
        false,
        p,
      );
    }

    // Punto central en acento
    if (avance > .85) {
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        5,
        Paint()..color = TemaModernista.acento,
      );
    }
  }

  Path _rectParcial(Rect r, double k) {
    final path = Path();
    final total = (r.width + r.height) * 2;
    var restante = total * k;
    void seg(Offset a, Offset b) {
      if (restante <= 0) return;
      final largo = (b - a).distance;
      final fin = restante >= largo ? b : a + (b - a) * (restante / largo);
      path.moveTo(a.dx, a.dy);
      path.lineTo(fin.dx, fin.dy);
      restante -= largo;
    }

    seg(r.topLeft, r.topRight);
    seg(r.topRight, r.bottomRight);
    seg(r.bottomRight, r.bottomLeft);
    seg(r.bottomLeft, r.topLeft);
    return path;
  }

  @override
  bool shouldRepaint(_CanchaPainter old) => old.avance != avance;
}
