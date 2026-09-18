/// Contrato que cumple todo lo descargable (alineación, acta, ficha).
abstract interface class Exportable {
  String get nombreArchivo;
  Map<String, Object> aDatosExportables();
}

/// Resultado de una descarga: lo que la UI muestra en el toast.
class ArchivoGenerado {
  const ArchivoGenerado({required this.nombre, required this.pesoKb});
  final String nombre;
  final int pesoKb;

  @override
  String toString() => '$nombre · $pesoKb KB';
}

/// Estrategia de exportación. Añadir un formato = añadir una subclase,
/// sin tocar modelos ni pantallas (principio abierto/cerrado).
abstract class Exportador {
  const Exportador();

  String get extension;
  String get descripcion;

  ArchivoGenerado exportar(Exportable fuente);
}

class ExportadorPng extends Exportador {
  const ExportadorPng({this.soloDorsales = false});
  final bool soloDorsales;

  @override
  String get extension => 'png';

  @override
  String get descripcion => soloDorsales ? 'Solo dorsales · fondo blanco' : 'Pizarra con nombres';

  @override
  ArchivoGenerado exportar(Exportable fuente) =>
      ArchivoGenerado(nombre: '${fuente.nombreArchivo}.png', pesoKb: soloDorsales ? 410 : 820);
}

class ExportadorPdf extends Exportador {
  const ExportadorPdf({this.tamano = 'A4'});
  final String tamano;

  @override
  String get extension => 'pdf';

  @override
  String get descripcion => 'Hoja de alineación $tamano';

  @override
  ArchivoGenerado exportar(Exportable fuente) =>
      ArchivoGenerado(nombre: '${fuente.nombreArchivo}.pdf', pesoKb: 240);
}

class ExportadorEnlace extends Exportador {
  const ExportadorEnlace();

  @override
  String get extension => 'link';

  @override
  String get descripcion => 'Enviar al grupo del equipo';

  @override
  ArchivoGenerado exportar(Exportable fuente) =>
      ArchivoGenerado(nombre: 'makuira.co/a/${fuente.nombreArchivo}', pesoKb: 0);
}

/// Fachada: la pantalla pide "descargá esto en PDF" y no sabe nada más.
class ServicioExportacion {
  const ServicioExportacion();

  static const List<Exportador> formatosAlineacion = [
    ExportadorPng(),
    ExportadorPdf(),
    ExportadorPng(soloDorsales: true),
    ExportadorEnlace(),
  ];

  static const List<Exportador> formatosActa = [ExportadorPdf(tamano: 'Carta'), ExportadorPng()];

  ArchivoGenerado descargar(Exportable fuente, Exportador formato) => formato.exportar(fuente);
}
