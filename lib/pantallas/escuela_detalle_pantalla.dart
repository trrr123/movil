import 'package:flutter/material.dart';

import '../core/tema_modernista.dart';
import '../modelos/escuela.dart';
import '../widgets/comunes.dart';
import '../widgets/plataforma.dart';

/// Todo lo que se sabe de una escuela: fotos, profesores, descripción y la
/// cancha en el mapa. La ven las familias (para elegir) y el administrador
/// (para aprobar); cada uno pone sus botones en [acciones].
class EscuelaDetallePantalla extends StatelessWidget {
  const EscuelaDetallePantalla({super.key, required this.escuela, this.acciones = const []});

  final Escuela escuela;
  final List<Widget> acciones;

  @override
  Widget build(BuildContext context) {
    final e = escuela;
    return MarcoPlataforma(
      titulo: e.nombre,
      subtitulo: e.categoria.isEmpty ? 'Escuela de fútbol' : e.categoria,
      volver: () => Navigator.pop(context),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          FotoRemota(id: e.fotoEscuelaId, alto: 200, icono: Icons.stadium_outlined),
          Padding(
            padding: const EdgeInsets.all(TemaModernista.esp5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.nombre.toUpperCase(), style: TemaModernista.titulo(26)),
                if (e.categoria.isNotEmpty) ...[
                  const SizedBox(height: TemaModernista.esp1),
                  Text(e.categoria, style: TemaModernista.etiqueta(color: TemaModernista.acento)),
                ],
                if (e.descripcion.isNotEmpty) ...[
                  const SizedBox(height: TemaModernista.esp3),
                  Text(e.descripcion, style: TemaModernista.cuerpo(tam: 14)),
                ],
                const SizedBox(height: TemaModernista.esp5),
                const Kicker('Profesores'),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FotoRemota(id: e.fotoProfesorId, alto: 84, ancho: 84, icono: Icons.person_outline),
                    const SizedBox(width: TemaModernista.esp4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final p in e.profesores)
                            Padding(
                              padding: const EdgeInsets.only(bottom: TemaModernista.esp2),
                              child: Row(
                                children: [
                                  Container(width: 6, height: 6, color: TemaModernista.acento),
                                  const SizedBox(width: TemaModernista.esp2),
                                  Expanded(child: Text(p, style: TemaModernista.cuerpo(tam: 14, peso: FontWeight.w600))),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TemaModernista.esp5),
                const Kicker('Dónde entrenan'),
                Text(e.direccion, style: TemaModernista.cuerpo(tam: 14)),
                const SizedBox(height: TemaModernista.esp3),
                MapaUbicacion(ubicacion: e.ubicacion),
                if (acciones.isNotEmpty) ...[
                  const SizedBox(height: TemaModernista.esp4),
                  const Regla(),
                  const SizedBox(height: TemaModernista.esp4),
                  for (final a in acciones) ...[a, const SizedBox(height: TemaModernista.esp3)],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de una escuela en una lista: foto, nombre, dirección.
class FilaEscuela extends StatelessWidget {
  const FilaEscuela({super.key, required this.escuela, required this.onTap, this.detalle});
  final Escuela escuela;
  final VoidCallback onTap;

  /// Línea extra (ej. el código y el correo, en el panel del admin).
  final String? detalle;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: TemaModernista.neutral300)),
          child: Row(
            children: [
              FotoRemota(
                id: escuela.fotoEscuelaId ?? escuela.fotoProfesorId,
                alto: 92,
                ancho: 92,
                icono: Icons.stadium_outlined,
              ),
              const SizedBox(width: TemaModernista.esp3),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: TemaModernista.esp2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(escuela.nombre.toUpperCase(),
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: TemaModernista.titulo(16)),
                      const SizedBox(height: 2),
                      Text(escuela.direccion,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TemaModernista.cuerpo(tam: 12, color: TemaModernista.neutral800)),
                      Text(escuela.profesores.join(' · '),
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: TemaModernista.cuerpo(tam: 12)),
                      if (detalle != null)
                        Text(detalle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TemaModernista.etiqueta(color: TemaModernista.acento, tam: 9)),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: TemaModernista.esp3),
                child: Icon(Icons.chevron_right, color: TemaModernista.neutral400),
              ),
            ],
          ),
        ),
      );
}
