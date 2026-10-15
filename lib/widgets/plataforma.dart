import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/tema_modernista.dart';
import '../estado/app_estado.dart';
import '../modelos/escuela.dart';
import 'comunes.dart';

/// Número al que los profesores escriben para agilizar su verificación.
const whatsAppAdmin = '3229070945';

/// Carcasa de las pantallas fuera del club (admin, profesor, familia, rol):
/// el mismo header oscuro del shell, sin barra de pestañas.
class MarcoPlataforma extends StatelessWidget {
  const MarcoPlataforma({super.key, required this.child, this.titulo = 'MAKUIRA', this.subtitulo, this.volver});

  final Widget child;
  final String titulo;
  final String? subtitulo;

  /// Si se pasa, muestra una flecha para volver en vez del botón de salir.
  final VoidCallback? volver;

  @override
  Widget build(BuildContext context) {
    final estado = AlcanceApp.de(context);
    final u = estado.usuario;
    return Scaffold(
      backgroundColor: TemaModernista.fondo,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: TemaModernista.fondoOscuro,
              padding: const EdgeInsets.symmetric(horizontal: TemaModernista.esp4, vertical: TemaModernista.esp3),
              child: Row(
                children: [
                  if (volver != null)
                    InkWell(
                      onTap: volver,
                      child: const Padding(
                        padding: EdgeInsets.only(right: TemaModernista.esp3),
                        child: Icon(Icons.arrow_back, color: Colors.white, size: 22),
                      ),
                    )
                  else ...[
                    const LogoMakuira(tam: 28),
                    const SizedBox(width: TemaModernista.esp3),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titulo.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TemaModernista.titulo(15, color: Colors.white)),
                        Text((subtitulo ?? u?.cargo ?? '').toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TemaModernista.etiqueta(color: TemaModernista.neutral400, tam: 9)),
                      ],
                    ),
                  ),
                  if (volver == null && u != null)
                    OutlinedButton(
                      onPressed: estado.salir,
                      style: OutlinedButton.styleFrom(
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        side: const BorderSide(color: TemaModernista.neutral400),
                        padding: const EdgeInsets.symmetric(horizontal: TemaModernista.esp2, vertical: 4),
                        minimumSize: Size.zero,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('${u.rolCorto} · SALIR', style: TemaModernista.etiqueta(color: Colors.white, tam: 9)),
                    ),
                ],
              ),
            ),
            Expanded(child: ContenidoResponsivo(child: child)),
          ],
        ),
      ),
    );
  }
}

class LogoMakuira extends StatelessWidget {
  const LogoMakuira({super.key, this.tam = 36});
  final double tam;

  @override
  Widget build(BuildContext context) => Container(
        width: tam,
        height: tam,
        color: TemaModernista.acento,
        alignment: Alignment.center,
        child: Text('M', style: TemaModernista.titulo(tam * 0.56, color: Colors.white)),
      );
}

/// Error en línea con filete rojo a la izquierda.
class MensajeError extends StatelessWidget {
  const MensajeError(this.texto, {super.key});
  final String texto;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.only(left: 9),
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: TemaModernista.acento, width: 3)),
        ),
        child: Text(texto, style: TemaModernista.cuerpo(tam: 12, color: TemaModernista.acento700)),
      );
}

/// Botón "Continuar con Google" en el lenguaje del sistema (sin radio).
class BotonGoogle extends StatelessWidget {
  const BotonGoogle({super.key, required this.onTap, this.cargando = false});
  final VoidCallback? onTap;
  final bool cargando;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: cargando ? null : onTap,
          style: OutlinedButton.styleFrom(
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            side: const BorderSide(color: TemaModernista.divisor),
            padding: const EdgeInsets.symmetric(horizontal: TemaModernista.esp4, vertical: 14),
            foregroundColor: TemaModernista.tinta,
            alignment: Alignment.centerLeft,
          ),
          child: Row(
            children: [
              Text('G', style: TemaModernista.titulo(17, color: TemaModernista.acento)),
              const SizedBox(width: TemaModernista.esp3),
              Text(cargando ? 'Conectando con Google…' : 'Continuar con Google',
                  style: TemaModernista.cuerpo(tam: 14, peso: FontWeight.w600)),
            ],
          ),
        ),
      );
}

/// Cuadro con el número de WhatsApp y un botón para copiarlo.
class CuadroWhatsApp extends StatelessWidget {
  const CuadroWhatsApp({super.key, this.numero = whatsAppAdmin});
  final String numero;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(border: Border.all(color: TemaModernista.divisor, width: 2)),
            padding: const EdgeInsets.fromLTRB(TemaModernista.esp4, TemaModernista.esp2, TemaModernista.esp1, TemaModernista.esp2),
            child: Row(
              children: [
                const Icon(Icons.chat_outlined, size: 20, color: Color(0xFF25D366)),
                const SizedBox(width: TemaModernista.esp3),
                Expanded(
                  child: SelectableText(numero, style: TemaModernista.titulo(24)),
                ),
                IconButton(
                  tooltip: 'Copiar número',
                  icon: const Icon(Icons.copy_rounded, color: TemaModernista.tinta),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: numero));
                    HapticFeedback.lightImpact();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Número copiado')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: TemaModernista.esp2),
          Text(
            'Para mayor información sobre su verificación, escríbanos por WhatsApp.',
            style: TemaModernista.cuerpo(tam: 12, color: TemaModernista.neutral800),
          ),
        ],
      );
}

/// Foto guardada en la app (por id). Mientras carga muestra un bloque gris.
class FotoRemota extends StatefulWidget {
  const FotoRemota({super.key, required this.id, this.alto = 180, this.ancho = double.infinity, this.icono = Icons.image_outlined});
  final String? id;
  final double alto;
  final double ancho;
  final IconData icono;

  @override
  State<FotoRemota> createState() => _FotoRemotaState();
}

class _FotoRemotaState extends State<FotoRemota> {
  Future<Uint8List?>? _carga;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = widget.id;
    _carga ??= (id == null || id.isEmpty) ? Future.value(null) : AlcanceApp.de(context).foto(id);
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: widget.ancho,
        height: widget.alto,
        child: FutureBuilder<Uint8List?>(
          future: _carga,
          builder: (_, snap) {
            final bytes = snap.data;
            if (bytes != null) return Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true);
            return Container(
              color: TemaModernista.neutral200,
              alignment: Alignment.center,
              child: snap.connectionState == ConnectionState.waiting
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: TemaModernista.acento))
                  : Icon(widget.icono, color: TemaModernista.neutral400),
            );
          },
        ),
      );
}

/// Elige una foto de la galería o la cámara, comprimida para guardarla.
class SelectorFoto extends StatelessWidget {
  const SelectorFoto({
    super.key,
    required this.rotulo,
    required this.bytes,
    required this.onElegida,
    this.obligatoria = false,
    this.icono = Icons.add_a_photo_outlined,
  });

  final String rotulo;
  final Uint8List? bytes;
  final ValueChanged<Uint8List> onElegida;
  final bool obligatoria;
  final IconData icono;

  Future<void> _elegir(BuildContext context) async {
    final origen = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (origen == null) return;
    final archivo = await ImagePicker().pickImage(source: origen, maxWidth: 900, maxHeight: 900, imageQuality: 70);
    if (archivo == null) return;
    onElegida(await archivo.readAsBytes());
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Kicker(obligatoria ? '$rotulo · obligatoria' : '$rotulo · opcional'),
          InkWell(
            onTap: () => _elegir(context),
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: TemaModernista.neutral200,
                border: Border.all(color: TemaModernista.neutral300),
              ),
              child: bytes == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icono, color: TemaModernista.neutral800),
                        const SizedBox(height: TemaModernista.esp2),
                        Text('Toca para subir', style: TemaModernista.cuerpo(tam: 12, color: TemaModernista.neutral800)),
                      ],
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(bytes!, fit: BoxFit.cover),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            color: TemaModernista.fondoOscuro,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Text('CAMBIAR', style: TemaModernista.etiqueta(color: Colors.white, tam: 9)),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      );
}

// ── Mapas (OpenStreetMap) ────────────────────────────────────────────────────

LatLng _aLatLng(Ubicacion u) => LatLng(u.latitud, u.longitud);

TileLayer _capaOsm() => TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.example.makuira_gestion',
    );

Marker _pin(LatLng punto) => Marker(
      point: punto,
      width: 44,
      height: 44,
      alignment: Alignment.topCenter,
      child: const Icon(Icons.location_on, color: TemaModernista.acento, size: 44),
    );

const _atribucion = SimpleAttributionWidget(source: Text('OpenStreetMap'));

/// Mapa fijo con el pin de la cancha y un botón para abrirla en Google Maps.
class MapaUbicacion extends StatelessWidget {
  const MapaUbicacion({super.key, required this.ubicacion, this.alto = 200});
  final Ubicacion ubicacion;
  final double alto;

  Future<void> _abrirEnMaps() async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${ubicacion.latitud},${ubicacion.longitud}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final punto = _aLatLng(ubicacion);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: alto,
          decoration: BoxDecoration(border: Border.all(color: TemaModernista.divisor, width: 2)),
          child: FlutterMap(
            options: MapOptions(
              initialCenter: punto,
              initialZoom: 16,
              // Dentro de una lista, el mapa no debe robarse el scroll.
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
              onTap: (_, __) => _abrirEnMaps(),
            ),
            children: [_capaOsm(), MarkerLayer(markers: [_pin(punto)]), _atribucion],
          ),
        ),
        TextButton.icon(
          onPressed: _abrirEnMaps,
          icon: const Icon(Icons.directions_outlined, size: 18),
          label: const Text('Cómo llegar (Google Maps)'),
          style: TextButton.styleFrom(foregroundColor: TemaModernista.acento, alignment: Alignment.centerLeft),
        ),
      ],
    );
  }
}

/// Pantalla completa para que el profesor marque la cancha tocando el mapa.
class SelectorUbicacionPantalla extends StatefulWidget {
  const SelectorUbicacionPantalla({super.key, this.inicial});
  final Ubicacion? inicial;

  @override
  State<SelectorUbicacionPantalla> createState() => _SelectorUbicacionPantallaState();
}

class _SelectorUbicacionPantallaState extends State<SelectorUbicacionPantalla> {
  LatLng? _punto;

  @override
  void initState() {
    super.initState();
    if (widget.inicial != null) _punto = _aLatLng(widget.inicial!);
  }

  @override
  Widget build(BuildContext context) => MarcoPlataforma(
        titulo: 'Ubicación de la cancha',
        subtitulo: 'Toca el mapa donde queda',
        volver: () => Navigator.pop(context),
        child: Column(
          children: [
            Expanded(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _punto ?? _aLatLng(Ubicacion.riohacha),
                  initialZoom: _punto == null ? 13 : 16,
                  onTap: (_, p) => setState(() => _punto = p),
                ),
                children: [
                  _capaOsm(),
                  if (_punto != null) MarkerLayer(markers: [_pin(_punto!)]),
                  _atribucion,
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(TemaModernista.esp4),
              child: BotonModernista(
                _punto == null ? 'Toca el mapa para marcar' : 'Usar esta ubicación',
                onTap: _punto == null
                    ? null
                    : () => Navigator.pop(context, Ubicacion(_punto!.latitude, _punto!.longitude)),
              ),
            ),
          ],
        ),
      );
}

/// Estado vacío/espera centrado, para listas que todavía no tienen nada.
class Vacio extends StatelessWidget {
  const Vacio({super.key, required this.titulo, required this.texto, this.icono = Icons.inbox_outlined});
  final String titulo;
  final String texto;
  final IconData icono;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(TemaModernista.esp5),
        decoration: BoxDecoration(border: Border.all(color: TemaModernista.neutral300)),
        child: Column(
          children: [
            Icon(icono, color: TemaModernista.neutral400, size: 32),
            const SizedBox(height: TemaModernista.esp3),
            Text(titulo.toUpperCase(), style: TemaModernista.etiqueta()),
            const SizedBox(height: TemaModernista.esp2),
            Text(texto,
                textAlign: TextAlign.center,
                style: TemaModernista.cuerpo(tam: 12, color: TemaModernista.neutral800)),
          ],
        ),
      );
}
