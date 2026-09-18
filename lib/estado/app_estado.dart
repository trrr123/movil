import 'dart:async';

import 'package:flutter/widgets.dart';

import '../modelos/alineacion.dart';
import '../modelos/finanzas.dart';
import '../modelos/jugador.dart';
import '../modelos/partido.dart';
import '../modelos/usuario.dart';
import '../servicios/auth_servicio.dart';
import '../servicios/equipo_repositorio.dart';
import '../servicios/exportable.dart';

/// Único dueño del estado de la app. Expone sólo lo que el rol puede ver:
/// los getters filtran por [Permiso] antes de devolver datos.
class AppEstado extends ChangeNotifier {
  AppEstado({required AuthServicio auth, required EquipoRepositorio repo})
      : _auth = auth,
        _repo = repo;

  final AuthServicio _auth;
  final EquipoRepositorio _repo;
  final ServicioExportacion _exportacion = const ServicioExportacion();

  late List<Jugador> _plantel;
  late List<Partido> _partidos;
  late List<SesionEntrenamiento> _sesiones;
  late CajaMensual _caja;
  late List<Alineacion> _alineaciones;
  late Alineacion _alineacionActiva;
  late Convocatoria _convocatoria;
  String _nombreClub = '';
  String _categoria = '';

  bool _cargandoClub = true;
  bool _cargandoDatos = false;

  String? _aviso;
  Timer? _reloj;

  /// Nombre y categoría del club: es lo único legible sin sesión (para que
  /// la pantalla de login lo muestre), así que se carga apenas arranca la
  /// app, antes de cualquier login.
  Future<void> cargarClub() async {
    final club = await _repo.cargarClub();
    _nombreClub = club.nombreClub;
    _categoria = club.categoria;
    _cargandoClub = false;
    notifyListeners();
  }

  /// Plantel, partidos, agenda, caja y alineaciones: todo lo demás vive
  /// detrás de las reglas de Firestore que exigen sesión iniciada, así que
  /// se trae recién después de un login exitoso (ver [ingresar]).
  Future<void> _cargarDatosDelClub() async {
    _plantel = await _repo.cargarPlantel();
    _partidos = await _repo.cargarPartidos();
    _sesiones = await _repo.cargarSesiones();
    _caja = await _repo.cargarCaja(_plantel);
    _alineaciones = await _repo.cargarAlineaciones(_plantel);
    _alineacionActiva = _alineaciones.first;
    _convocatoria = Convocatoria(partidoId: _partidos.first.id)
      ..let((c) {
        for (final j in _plantel.where((j) => j.disponible).take(16)) {
          c.alternar(j);
        }
      });
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
    _reloj?.cancel();
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
    return _plantel.firstWhere((j) => j.id == u.jugadorId);
  }

  // ── Plantel ──────────────────────────────────────────────────────────
  List<Jugador> get plantel => List.unmodifiable(_plantel);
  int get lesionados => _plantel.where((j) => !j.disponible).length;

  List<Jugador> buscar(String texto, Posicion? filtro) => _plantel.where((j) {
        final q = texto.trim().toLowerCase();
        final coincide = q.isEmpty || j.nombre.toLowerCase().contains(q) || j.dorsal.toString() == q;
        return coincide && (filtro == null || j.posicion == filtro);
      }).toList();

  /// Regla central de privacidad: sólo el DT abre fichas ajenas.
  bool puedeAbrirFicha(Jugador j) =>
      puede(Permiso.verFichaAjena) || (usuario is JugadorUsuario && (usuario as JugadorUsuario).jugadorId == j.id);

  // ── Alineación ───────────────────────────────────────────────────────
  Alineacion get alineacion => _alineacionActiva;
  List<Alineacion> get alineacionesGuardadas => List.unmodifiable(_alineaciones);
  List<Jugador> get banca => _plantel.where((j) => !_alineacionActiva.contiene(j.id)).toList();

  void aplicarFormacion(Formacion f) {
    if (!puede(Permiso.editarAlineacion)) return;
    _alineacionActiva.aplicarFormacion(f);
    notifyListeners();
  }

  void moverFicha(int jugadorId, PuntoCampo destino) {
    if (!puede(Permiso.editarAlineacion)) return;
    _alineacionActiva.moverFicha(jugadorId, destino);
    notifyListeners();
  }

  void sustituir({required int saleId, required Jugador entra}) {
    if (!puede(Permiso.editarAlineacion)) return;
    final sale = _plantel.firstWhere((j) => j.id == saleId);
    _alineacionActiva.sustituir(saleId: saleId, entra: entra);
    if (partidoActual.enJuego) {
      partidoActual.anotar(Cambio(minuto: partidoActual.minuto, sale: sale, entra: entra));
    }
    avisar('Entra ${entra.apellido} por ${sale.apellido}');
  }

  void guardarAlineacion() {
    if (!puede(Permiso.editarAlineacion)) return;
    final copia = _alineacionActiva.duplicar(
      nuevoId: DateTime.now().millisecondsSinceEpoch,
      nuevoNombre: 'Alineación ${_alineacionActiva.formacion.nombre}',
    );
    _alineaciones.insert(0, copia);
    avisar('Alineación guardada en el club');
  }

  void cargarAlineacion(Alineacion a) {
    _alineacionActiva = a;
    avisar('Cargada: ${a.nombre}');
  }

  List<Exportador> get formatosAlineacion => ServicioExportacion.formatosAlineacion;
  List<Exportador> get formatosActa => ServicioExportacion.formatosActa;

  void descargar(Exportable fuente, Exportador formato) {
    if (!puede(Permiso.exportarAlineacion) && fuente is Alineacion) return;
    avisar('Descargado: ${_exportacion.descargar(fuente, formato)}');
  }

  // ── Agenda, convocatoria y asistencia ────────────────────────────────
  List<Partido> get partidos => List.unmodifiable(_partidos);
  Partido get partidoActual => _partidos.first;
  List<SesionEntrenamiento> get sesiones => List.unmodifiable(_sesiones);
  Convocatoria get convocatoria => _convocatoria;

  bool estoyConvocado() {
    final f = miFicha;
    return f != null && _convocatoria.incluye(f.id);
  }

  bool soyTitular() {
    final f = miFicha;
    return f != null && _alineacionActiva.contiene(f.id);
  }

  void alternarConvocado(Jugador j) {
    if (!puede(Permiso.gestionarConvocatoria)) return;
    if (!_convocatoria.alternar(j)) {
      avisar(j.disponible ? 'Tope de ${_convocatoria.tope} convocados' : '${j.apellido} está lesionado');
      return;
    }
    notifyListeners();
  }

  void enviarConvocatoria() {
    if (!puede(Permiso.gestionarConvocatoria)) return;
    _convocatoria.enviar();
    avisar('Citación enviada a ${_convocatoria.total} jugadores');
  }

  void marcarAsistencia(SesionEntrenamiento s, Jugador j, bool presente) {
    if (!puede(Permiso.registrarAsistencia)) return;
    s.marcar(j.id, presente);
    notifyListeners();
  }

  // ── Partido en vivo ──────────────────────────────────────────────────
  void iniciarPartido() {
    if (!puede(Permiso.dirigirPartido)) return;
    partidoActual
      ..iniciar()
      ..registrarEnCampo(_alineacionActiva.titulares);
    _reloj?.cancel();
    _reloj = Timer.periodic(const Duration(seconds: 4), (_) {
      partidoActual.avanzarMinuto();
      notifyListeners();
    });
    notifyListeners();
  }

  void alternarReloj() {
    if (!puede(Permiso.dirigirPartido)) return;
    partidoActual.alternarReloj();
    notifyListeners();
  }

  void anotarGol({Jugador? autor, Jugador? asistente, bool rival = false}) {
    if (!puede(Permiso.dirigirPartido)) return;
    final goleador = autor ?? _alineacionActiva.titulares.last;
    partidoActual.anotar(Gol(minuto: partidoActual.minuto, autor: goleador, asistente: asistente, rival: rival));
    goleador.registrarPartido(goles: rival ? 0 : 1);
    avisar(rival ? 'Gol del rival' : '¡Gol de ${goleador.apellido}!');
  }

  void anotarTarjeta(Jugador j, {ColorTarjeta color = ColorTarjeta.amarilla}) {
    if (!puede(Permiso.dirigirPartido)) return;
    partidoActual.anotar(Tarjeta(minuto: partidoActual.minuto, jugador: j, color: color));
    notifyListeners();
  }

  void finalizarPartido() {
    if (!puede(Permiso.dirigirPartido)) return;
    _reloj?.cancel();
    partidoActual.finalizar();
    avisar('Partido cerrado · estadísticas guardadas');
  }

  // ── Dinero ───────────────────────────────────────────────────────────
  CajaMensual get caja => _caja;

  /// El DT ve la caja completa; el jugador sólo su cuota.
  List<Cuota> get cuotasVisibles {
    if (puede(Permiso.verFinanzasClub)) return _caja.cuotas;
    final f = miFicha;
    return f == null ? const [] : [_caja.deJugador(f.id)];
  }

  Cuota? get miCuota {
    final f = miFicha;
    return f == null ? null : _caja.deJugador(f.id);
  }

  void reportarMiPago() {
    final c = miCuota;
    if (c == null || !puede(Permiso.verFinanzasPropias)) return;
    c.reportarPago();
    avisar('Pago reportado · pendiente de confirmación');
  }

  void confirmarPago(Cuota c) {
    if (!puede(Permiso.verFinanzasClub)) return;
    c.confirmarPago();
    notifyListeners();
  }

  void enviarRecordatorio() {
    if (!puede(Permiso.verFinanzasClub)) return;
    avisar('Recordatorio enviado a ${_caja.pendientes} acudientes');
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }
}

extension _Let<T> on T {
  void let(void Function(T) fn) => fn(this);
}

/// Inyección del estado en el árbol de widgets sin dependencias externas.
class AlcanceApp extends InheritedNotifier<AppEstado> {
  const AlcanceApp({super.key, required AppEstado estado, required super.child}) : super(notifier: estado);

  static AppEstado de(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AlcanceApp>()!.notifier!;
}
