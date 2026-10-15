import 'dart:convert';
import 'dart:io';

import '../core/config_correo.dart';

/// Envío de correos de la app. Hoy solo la bienvenida al terminar el registro;
/// la UI y el estado no saben qué proveedor lo manda.
abstract class CorreoServicio {
  Future<void> enviarBienvenida({required String nombre, required String correo, required String rol});
}

/// No envía nada (tests y modo demo).
class CorreoNulo implements CorreoServicio {
  const CorreoNulo();

  @override
  Future<void> enviarBienvenida({required String nombre, required String correo, required String rol}) async {}
}

/// Envía con EmailJS (gratis hasta 200 correos/mes, sin servidor propio).
/// La plantilla vive en EmailJS; su diseño está en `tool/correo_bienvenida.html`
/// y usa las variables `{{nombre}}`, `{{correo}}` y `{{rol}}`.
class CorreoEmailJs implements CorreoServicio {
  const CorreoEmailJs();

  static final _url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

  @override
  Future<void> enviarBienvenida({required String nombre, required String correo, required String rol}) async {
    if (!ConfigCorreo.configurado || correo.isEmpty) return;
    final cliente = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final peticion = await cliente.postUrl(_url);
      peticion.headers.contentType = ContentType.json;
      peticion.write(jsonEncode({
        'service_id': ConfigCorreo.servicioId,
        'template_id': ConfigCorreo.plantillaId,
        'user_id': ConfigCorreo.clavePublica,
        'template_params': {
          'nombre': nombre.trim().split(' ').first,
          'correo': correo,
          'rol': rol,
          // Nombres por defecto de EmailJS para el campo "To Email": así
          // la plantilla funciona aunque ese campo no use {{correo}}.
          'to_email': correo,
          'email': correo,
          'to_name': nombre,
        },
      }));
      final respuesta = await peticion.close();
      final cuerpo = await respuesta.transform(utf8.decoder).join();
      if (respuesta.statusCode != 200) {
        throw HttpException('EmailJS respondió ${respuesta.statusCode}: $cuerpo');
      }
    } finally {
      cliente.close();
    }
  }
}
