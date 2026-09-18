import 'dart:async';

import 'package:flutter/widgets.dart';

import '../datos/repositorios.dart';
import '../modelos/alineacion.dart';
import '../modelos/finanzas.dart';
import '../modelos/jugador.dart';
import '../modelos/partido.dart';
import '../modelos/usuario.dart';
import '../servicios/auth_servicio.dart';
import '../servicios/exportable.dart';
import 'agenda_controlador.dart';
import 'alineacion_controlador.dart';
import 'finanzas_controlador.dart';
import 'partido_en_vivo_controlador.dart';
import 'plantel_controlador.dart';

/// Fachada del estado de la app: orquesta un controlador por función
/// (plantel, alineación, agenda, partido en vivo, finanzas) y aplica los
/// permisos antes de delegarles cualquier acción — la UI solo habla con
/// esta clase, nunca con los controladores directamente. Expone sólo lo
/// que el rol puede ver: los getters filtran por [Permiso] antes de
/// devolver datos.
///
/// Los casos que cruzan dos controladores (ej. [sustituir], que también
/// anota un cambio en el partido si está en vivo) se coordinan acá: es el
/// único lugar que conoce a todos.
class AppEstado extends ChangeNotifier {
  AppEstado({required AuthServicio auth, required Repositorios repositorios})
      : _auth = auth,
        _repositorios = repositorios,
        _plantel = PlantelControlador(repositorios.jugadores),
        _alineacion = AlineacionControlador(repositorios.alineaciones),
        _agenda = AgendaControlador(repositorios.partidos, repositorios.sesiones),
        _partidoEnVivo = PartidoEnVivoControlador(),
        _finanzas = FinanzasControlador(repositorios.caja) {
    for (final c in _controladores) {
      c.addListener(notifyListeners);
    }
  }

  final AuthServicio _auth;
  final Repositorios _repositorios;
  final ServicioExportacion _exportacion = const ServicioExportacion();

  final PlantelControlador _plantel;
  final AlineacionControlador _alineacion;
  final AgendaControlador _agenda;
  final PartidoEnVivoControlador _partidoEnVivo;
  final FinanzasControlador _finanzas;

  List<ChangeNotifier> get _controladores => [_plantel, _alineacion, _agenda, _partidoEnVivo, _finanzas];

  String _nombreClub = '';
  String _categoria = '';

  bool _cargandoClub = true;
  bool _cargandoDatos = false;

  String? _aviso;

  /// Nombre y categoría del club: es lo único legible sin sesión (para que
  /// la pantalla de login lo muestre), así que se carga apenas arranca la
  /// app, antes de cualquier login.
  Future<void> cargarClub() async {
    final club = await _repositorios.club.cargar();
    _nombreClub = club.nombreClub;
    _categoria = club.categoria;
    _cargandoClub = false;
    notifyListeners();
  }

  /// Plantel, partidos, agenda, caja y alineaciones: todo lo demás vive
  /// detrás de las reglas de Firestore que exigen sesión iniciada, así que
  /// se trae recién después de un login exitoso (ver [ingresar]).
  Future<void> _cargarDatosDelClub() async {
    await _plantel.cargar();
    final plantel = _plantel.plantel;
    await _agenda.cargar(plantel);
    await _finanzas.cargar(plantel);
    await _alineacion.cargar(plantel);
  }

  // ── Sesión ───────────────────────────────────────────────────────────
  bool get cargandoClub => _cargandoClub;
  bool get cargandoDatos => _cargandoDatos;

  /// La pantalla de login usa esto para saber qué clave mandar con los
  /// accesos rápidos de demostración: en memoria usan '1234'; contra
  /// Firebase real hace falta una clave de al menos 6 caracteres.
  bool get esAuthEnMemoria => _auth is AuthEnMemoria;
  Usuario? get usuario => _auth.usuarioActual;
  bool get autenticado => usuario != null;
  bool puede(Permiso p) => usuario?.puede(p) ?? false;

  String get nombreClub => _nombreClub;
  String get categoria => _categoria;
  String? get aviso => _aviso;

  Future<void> ingresar(String correo, String clave) async {
    await _auth.ingresar(correo: correo, clave: clave);
    _cargandoDatos = true;
    notifyListeners();
    try {
      await _cargarDatosDelClub();
    } catch (e, st) {
      // Si falla la carga posterior al login, no dejamos a la persona
      // trabada en la pantalla de carga: se cierra la sesión y se avisa.
      debugPrint('Error cargando datos del club tras login: $e\n$st');
      _auth.salir();
      _cargandoDatos = false;
      notifyListeners();
      throw const ErrorAutenticacion('No se pudieron cargar los datos del club. Probá de nuevo.');
    }
    _cargandoDatos = false;
    avisar('Sesión iniciada como ${usuario!.cargo}');
  }

  void salir() {
    _partidoEnVivo.detenerReloj();
    _auth.salir();
    notifyListeners();
  }

  void avisar(String mensaje) {
    _aviso = mensaje;
    notifyListeners();
    Timer(const Duration(milliseconds: 2400), () {
      _aviso = null;
      notifyListeners();
    });
  }

  /// Ficha del jugador logueado (null para el DT).
  Jugador? get miFicha {
    final u = usuario;
    if (u is! JugadorUsuario) return null;
    return _plantel.plantel.firstWhere((j) => j.id == u.jugadorId);
  }

  // ── Plantel ──────────────────────────────────────────────────────────
  List<Jugador> get plantel => _plantel.plantel;
  int get lesionados => _plantel.lesionados;

  List<Jugador> buscar(String texto, Posicion? filtro) => _plantel.buscar(texto, filtro);

  /// Regla central de privacidad: sólo el DT abre fichas ajenas.
  bool puedeAbrirFicha(Jugador j) =>
      puede(Permiso.verFichaAjena) || (usuario is JugadorUsuario && (usuario as JugadorUsuario).jugadorId == j.id);

  // ── Alineación ───────────────────────────────────────────────────────
  Alineacion get alineacion => _alineacion.activa;
  List<Alineacion> get alineacionesGuardadas => _alineacion.guardadas;
  List<Jugador> get banca => _plantel.plantel.where((j) => !_alineacion.activa.contiene(j.id)).toList();

  void aplicarFormacion(Formacion f) {
    if (!puede(Permiso.editarAlineacion)) return;
    _alineacion.aplicarFormacion(f);
  }

  void moverFicha(int jugadorId, PuntoCampo destino) {
    if (!puede(Permiso.editarAlineacion)) return;
    _alineacion.moverFicha(jugadorId, destino);
  }

  void sustituir({required int saleId, required Jugador entra}) {
    if (!puede(Permiso.editarAlineacion)) return;
    final sale = _plantel.plantel.firstWhere((j) => j.id == saleId);
    _alineacion.sustituir(saleId: saleId, entra: entra);
    if (partidoActual.enJuego) {
      _partidoEnVivo.registrarCambio(partidoActual, sale: sale, entra: entra);
    }
    avisar('Entra ${entra.apellido} por ${sale.apellido}');
  }

  void guardarAlineacion() {
    if (!puede(Permiso.editarAlineacion)) return;
    _alineacion.guardar();
    avisar('Alineación guardada en el club');
  }

  void cargarAlineacion(Alineacion a) {
    _alineacion.cargarGuardada(a);
    avisar('Cargada: ${a.nombre}');
  }

  List<Exportador> get formatosAlineacion => ServicioExportacion.formatosAlineacion;
  List<Exportador> get formatosActa => ServicioExportacion.formatosActa;

  void descargar(Exportable fuente, Exportador formato) {
    if (!puede(Permiso.exportarAlineacion) && fuente is Alineacion) return;
    avisar('Descargado: ${_exportacion.descargar(fuente, formato)}');
  }

  // ── Agenda, convocatoria y asistencia ────────────────────────────────
  List<Partido> get partidos => _agenda.partidos;
  Partido get partidoActual => _agenda.actual;
  List<SesionEntrenamiento> get sesiones => _agenda.sesiones;
  Convocatoria get convocatoria => _agenda.convocatoria;

  bool estoyConvocado() {
    final f = miFicha;
    return f != null && _agenda.convocatoria.incluye(f.id);
  }

  bool soyTitular() {
    final f = miFicha;
    return f != null && _alineacion.activa.contiene(f.id);
  }

  void alternarConvocado(Jugador j) {
    if (!puede(Permiso.gestionarConvocatoria)) return;
    if (!_agenda.alternarConvocado(j)) {
      avisar(j.disponible ? 'Tope de ${_agenda.convocatoria.tope} convocados' : '${j.apellido} está lesionado');
    }
  }

  void enviarConvocatoria() {
    if (!puede(Permiso.gestionarConvocatoria)) return;
    _agenda.enviarConvocatoria();
    avisar('Citación enviada a ${_agenda.convocatoria.total} jugadores');
  }

  void marcarAsistencia(SesionEntrenamiento s, Jugador j, bool presente) {
    if (!puede(Permiso.registrarAsistencia)) return;
    _agenda.marcarAsistencia(s, j, presente);
  }

  // ── Partido en vivo ──────────────────────────────────────────────────
  void iniciarPartido() {
    if (!puede(Permiso.dirigirPartido)) return;
    _partidoEnVivo.iniciar(partidoActual, _alineacion.activa.titulares);
  }

  void alternarReloj() {
    if (!puede(Permiso.dirigirPartido)) return;
    _partidoEnVivo.alternarReloj(partidoActual);
  }

  void anotarGol({Jugador? autor, Jugador? asistente, bool rival = false}) {
    if (!puede(Permiso.dirigirPartido)) return;
    final goleador = autor ?? _alineacion.activa.titulares.last;
    _partidoEnVivo.anotarGol(partidoActual, goleador: goleador, asistente: asistente, rival: rival);
    avisar(rival ? 'Gol del rival' : '¡Gol de ${goleador.apellido}!');
  }

  void anotarTarjeta(Jugador j, {ColorTarjeta color = ColorTarjeta.amarilla}) {
    if (!puede(Permiso.dirigirPartido)) return;
    _partidoEnVivo.anotarTarjeta(partidoActual, j, color: color);
  }

  void finalizarPartido() {
    if (!puede(Permiso.dirigirPartido)) return;
    _partidoEnVivo.finalizar(partidoActual);
    avisar('Partido cerrado · estadísticas guardadas');
  }

  // ── Dinero ───────────────────────────────────────────────────────────
  CajaMensual get caja => _finanzas.caja;

  /// El DT ve la caja completa; el jugador sólo su cuota.
  List<Cuota> get cuotasVisibles {
    if (puede(Permiso.verFinanzasClub)) return _finanzas.caja.cuotas;
    final f = miFicha;
    return f == null ? const [] : [_finanzas.caja.deJugador(f.id)];
  }

  Cuota? get miCuota {
    final f = miFicha;
    return f == null ? null : _finanzas.caja.deJugador(f.id);
  }

  void reportarMiPago() {
    final c = miCuota;
    if (c == null || !puede(Permiso.verFinanzasPropias)) return;
    _finanzas.reportarPago(c);
    avisar('Pago reportado · pendiente de confirmación');
  }

  void confirmarPago(Cuota c) {
    if (!puede(Permiso.verFinanzasClub)) return;
    _finanzas.confirmarPago(c);
  }

  void enviarRecordatorio() {
    if (!puede(Permiso.verFinanzasClub)) return;
    avisar('Recordatorio enviado a ${_finanzas.caja.pendientes} acudientes');
  }

  @override
  void dispose() {
    for (final c in _controladores) {
      c.dispose();
    }
    super.dispose();
  }
}

/// Inyección del estado en el árbol de widgets sin dependencias externas.
class AlcanceApp extends InheritedNotifier<AppEstado> {
  const AlcanceApp({super.key, required AppEstado estado, required super.child}) : super(notifier: estado);

  static AppEstado de(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AlcanceApp>()!.notifier!;
}
