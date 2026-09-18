import 'package:flutter/material.dart';

import '../core/tema_modernista.dart';
import '../estado/app_estado.dart';
import '../modelos/partido.dart';
import '../modelos/usuario.dart';
import '../widgets/comunes.dart';

/// Convocatoria de partido o planilla de asistencia de un entreno.
/// Pantalla exclusiva del cuerpo técnico: exige permiso al construirse.
class ConvocatoriaPantalla extends StatefulWidget {
  const ConvocatoriaPantalla({super.key, this.sesion});
  final SesionEntrenamiento? sesion;

  @override
  State<ConvocatoriaPantalla> createState() => _ConvocatoriaPantallaState();
}

class _ConvocatoriaPantallaState extends State<ConvocatoriaPantalla> {
  late bool _modoAsistencia = widget.sesion != null;

  @override
  Widget build(BuildContext context) {
    final estado = AlcanceApp.de(context);
    if (!estado.puede(Permiso.gestionarConvocatoria)) {
      return Scaffold(
        body: Center(child: Text('Solo el cuerpo técnico', style: TemaModernista.cuerpo())),
      );
    }

    final sesion = widget.sesion ?? estado.sesiones.first;
    final conv = estado.convocatoria;
    final total = _modoAsistencia ? sesion.presentes : conv.total;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: TemaModernista.fondo,
        title: Text(_modoAsistencia ? 'ASISTENCIA' : 'CONVOCATORIA', style: TemaModernista.titulo(20)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 26),
        children: [
          Text(
            _modoAsistencia
                ? '${sesion.titulo} · ${sesion.fecha.day}/${sesion.fecha.month}'
                : 'Sáb 19 sep · vs. ${estado.partidoActual.rival}',
            style: TemaModernista.cuerpo(tam: 11, color: TemaModernista.neutral400),
          ),
          const SizedBox(height: TemaModernista.esp3),
          Container(
            decoration: const BoxDecoration(
              border: Border.fromBorderSide(BorderSide(color: TemaModernista.neutral400)),
            ),
            child: Row(
              children: [
                _tab('Convocatoria', !_modoAsistencia, () => setState(() => _modoAsistencia = false)),
                _tab('Asistencia', _modoAsistencia, () => setState(() => _modoAsistencia = true)),
              ],
            ),
          ),
          const SizedBox(height: TemaModernista.esp3),
          const Regla(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Text('$total', style: TemaModernista.titulo(24).copyWith(color: TemaModernista.acento)),
                const SizedBox(width: TemaModernista.esp3),
                Expanded(
                  child: Text(
                    _modoAsistencia
                        ? 'presentes de ${estado.plantel.length} en el entreno'
                        : 'convocados de ${estado.plantel.length} · máximo ${conv.tope}',
                    style: TemaModernista.cuerpo(tam: 11, color: TemaModernista.neutral800),
                  ),
                ),
                BotonModernista(
                  _modoAsistencia ? 'Cerrar' : 'Enviar',
                  expandido: false,
                  onTap: () {
                    if (_modoAsistencia) {
                      estado.avisar('Asistencia registrada');
                    } else {
                      estado.enviarConvocatoria();
                    }
                  },
                ),
              ],
            ),
          ),
          const Regla(),
          for (final j in estado.plantel)
            InkWell(
              onTap: () => setState(() {
                if (_modoAsistencia) {
                  estado.marcarAsistencia(sesion, j, !sesion.asistio(j.id));
                } else {
                  estado.alternarConvocado(j);
                }
              }),
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: TemaModernista.neutral300)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: (_modoAsistencia ? sesion.asistio(j.id) : conv.incluye(j.id))
                            ? TemaModernista.acento
                            : Colors.transparent,
                        border: const Border.fromBorderSide(BorderSide(color: TemaModernista.divisor, width: 2)),
                      ),
                      alignment: Alignment.center,
                      child: (_modoAsistencia ? sesion.asistio(j.id) : conv.incluye(j.id))
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: TemaModernista.esp3),
                    SizedBox(
                      width: 26,
                      child: Text('${j.dorsal}',
                          textAlign: TextAlign.right,
                          style: TemaModernista.titulo(15).copyWith(color: TemaModernista.neutral800)),
                    ),
                    const SizedBox(width: TemaModernista.esp2),
                    Expanded(child: Text(j.nombre, style: TemaModernista.cuerpo())),
                    Text(j.posicion.sigla,
                        style: TemaModernista.etiqueta(color: TemaModernista.neutral400, tam: 9)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tab(String texto, bool activo, VoidCallback onTap) => Expanded(
        child: InkWell(
          onTap: onTap,
          child: Container(
            color: activo ? TemaModernista.acento : Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 9),
            alignment: Alignment.center,
            child: Text(texto.toUpperCase(),
                style: TemaModernista.etiqueta(color: activo ? Colors.white : TemaModernista.tinta, tam: 11)),
          ),
        ),
      );
}
