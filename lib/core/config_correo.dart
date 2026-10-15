/// Datos de la cuenta de EmailJS (emailjs.com) que envía la bienvenida.
///
/// No son secretos: EmailJS los diseñó para ir dentro de apps y páginas
/// (la "Public Key" es pública). Mientras estén vacíos, la app no envía nada.
class ConfigCorreo {
  ConfigCorreo._();

  /// Email Services → el servicio conectado a Gmail (ej. `service_ab12cd3`).
  static const servicioId = 'service_ulal2gp';

  /// Email Templates → la plantilla de bienvenida (ej. `template_x9y8z7`).
  static const plantillaId = 'template_mss9ylb';

  /// Account → General → Public Key.
  static const clavePublica = '_ONilCISYEerWAI9D';

  static bool get configurado => servicioId.isNotEmpty && plantillaId.isNotEmpty && clavePublica.isNotEmpty;
}
