import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../datos/inscripcion_repositorio.dart';
import '../datos/repositorios.dart';
import '../modelos/alineacion.dart';
import '../modelos/escuela.dart';
import '../modelos/finanzas.dart';
import '../modelos/jugador.dart';
import '../modelos/partido.dart';
import '../modelos/resumen_jugador.dart';
import '../modelos/usuario.dart';
import '../servicios/auth_servicio.dart';
import '../servicios/correo_servicio.dart';
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
  AppEstado({
    required AuthServicio auth,
    required Repositorios repositorios,
    CorreoServicio correo = const CorreoNulo(),
  })  : _auth = auth,
        _correo = correo,
        _repositorios = repositorios,
        _plantel = PlantelControlador(repositorios.jugadores),
        _alineacion = AlineacionControlador(repositorios.alineaciones),
        _agenda = AgendaControlador(repositorios.partidos, repositorios.sesiones),
        _partidoEnVivo = PartidoEnVivoControlador(),
        _finanzas = FinanzasControlador(repositorios.caja) {
    for (final c in _controladores) {
      c.addListener(notifyListeners);
    }
    _alineacion.alFallarGuardado = (e) {
      debugPrint('Error guardando la alineación: $e');
      avisar('No se pudo guardar la alineación. Revisa tu conexión.');
    };
    // Cada jugada, pausa o minuto del partido en vivo se guarda: si la app
    // se cierra, el partido se retoma donde iba.
    _partidoEnVivo.alCambiar = (p) => _guardar(_agenda.guardarEnVivo(p), 'el partido');
  }

  final AuthServicio _auth;
  final CorreoServicio _correo;
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

  bool _iniciando = true;
  bool _cargandoDatos = false;

  String? _aviso;

  /// Al abrir la app: si quedó una sesión abierta, entra directo sin login.
  Future<void> iniciar() async {
    try {
      final u = await _auth.restaurar();
      if (u != null) await _alEntrar(u, saludar: false);
    } catch (e, st) {
      debugPrint('No se pudo restaurar la sesión: $e\n$st');
    }
    _iniciando = false;
    notifyListeners();
  }

  /// Nombre de la escuela, plantel, partidos, agenda, caja y alineaciones:
  /// viven detrás de las reglas de Firestore que exigen sesión y pertenecer
  /// a la escuela, así que se traen recién después de entrar.
  Future<void> _cargarDatosDelClub() async {
    final club = await _repositorios.club.cargar();
    _nombreClub = club.nombreClub;
    _categoria = club.categoria;
    await _plantel.cargar();
    final plantel = _plantel.plantel;
    await _agenda.cargar(plantel);
    await _finanzas.cargar(plantel);
    await _alineacion.cargar(plantel);
  }

  // ── Sesión ───────────────────────────────────────────────────────────
  bool get iniciando => _iniciando;
  bool get cargandoDatos => _cargandoDatos;

  /// La pantalla de login usa esto para saber qué clave mandar con los
  /// accesos rápidos de demostración: en memoria usan '1234'; contra
  /// Firebase real hace falta una clave de al menos 6 caracteres.
  bool get esAuthEnMemoria => _auth is AuthEnMemoria;
  bool get soportaGoogle => _auth.soportaGoogle;
  Usuario? get usuario => _auth.usuarioActual;
  bool get autenticado => usuario != null;
  bool puede(Permiso p) => usuario?.puede(p) ?? false;

  /// DT y jugador usan la app del club (shell con pestañas); los demás roles
  /// tienen su propia pantalla (admin, solicitud de escuela, familia, rol).
  bool get usaAppDelClub => usuario is DirectorTecnico || usuario is JugadorUsuario;

  String get nombreClub => _nombreClub;
  String get categoria => _categoria;
  String? get aviso => _aviso;

  Future<void> ingresar(String correo, String clave) async =>
      _alEntrar(await _auth.ingresar(correo: correo, clave: clave));

  Future<void> registrar({required String nombre, required String correo, required String clave}) async =>
      _alEntrar(await _auth.registrar(nombre: nombre, correo: correo, clave: clave));

  Future<void> ingresarConGoogle() async => _alEntrar(await _auth.ingresarConGoogle());

  /// Último paso del registro: guarda el rol y manda el correo de bienvenida.
  /// Si el correo falla (sin red, cuota), el registro igual queda hecho.
  Future<void> elegirRol(RolRegistro rol, String nombre) async {
    final u = await _auth.elegirRol(rol, nombre: nombre);
    // Sin await: el correo no debe demorar ni frenar la entrada a la app.
    _correo
        .enviarBienvenida(nombre: u.nombre, correo: u.correo, rol: u.cargo)
        .catchError((Object e) => debugPrint('No se envió la bienvenida: $e'));
    await _alEntrar(u, saludar: false);
  }

  /// Vuelve a leer el perfil: un profesor cuya escuela se aprobó pasa a DT,
  /// un estudiante con inscripción aprobada pasa a jugador.
  Future<void> recargarPerfil() async => _alEntrar(await _auth.recargar(), saludar: false);

  Future<void> restablecerClave(String correo) => _auth.restablecerClave(correo);

  /// Punto único tras cualquier forma de entrar: si el rol usa la app del
  /// club, fija la escuela activa y trae sus datos.
  Future<void> _alEntrar(Usuario u, {bool saludar = true}) async {
    final escuelaId = switch (u) {
      DirectorTecnico(:final escuelaId) || JugadorUsuario(:final escuelaId) => escuelaId,
      _ => null,
    };
    if (escuelaId == null) {
      notifyListeners();
      return;
    }
    _repositorios.escuela.id = escuelaId;
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
      throw const ErrorAutenticacion('No se pudieron cargar los datos de la escuela. Prueba de nuevo.');
    }
    _cargandoDatos = false;
    if (saludar) {
      avisar('Sesión iniciada como ${u.cargo}');
    } else {
      notifyListeners();
    }
  }

  Future<void> salir() async {
    _partidoEnVivo.detenerReloj();
    // Lo último que movió el DT en la pizarra se escribe antes de cerrar la
    // sesión (después, las reglas ya no lo dejarían escribir).
    if (_alineacion.guardadoPendiente) await _alineacion.guardarAhora();
    _auth.salir();
    notifyListeners();
  }

  // ── Plataforma: escuelas, inscripciones y fotos ──────────────────────
  Future<String> subirFoto(Uint8List bytes) => _repositorios.fotos.subir(bytes, duenoUid: usuario!.uid);
  Future<Uint8List?> foto(String id) => _repositorios.fotos.cargar(id);

  /// Profesor: manda su escuela a revisión. Devuelve el código de solicitud.
  Future<Escuela> enviarSolicitudEscuela({
    required String nombre,
    required String direccion,
    required Ubicacion ubicacion,
    required List<String> profesores,
    required String descripcion,
    required String categoria,
    required String fotoProfesorId,
    String? fotoEscuelaId,
  }) async {
    final u = usuario;
    if (u is! ProfesorSolicitante) throw StateError('Solo un profesor registra escuelas.');
    final escuela = Escuela(
      id: Escuela.nuevoCodigo(),
      nombre: nombre.trim(),
      direccion: direccion.trim(),
      ubicacion: ubicacion,
      profesores: profesores,
      duenoUid: u.uid,
      correoDueno: u.correo,
      fotoProfesorId: fotoProfesorId,
      fotoEscuelaId: fotoEscuelaId,
      descripcion: descripcion.trim(),
      categoria: categoria.trim(),
    );
    await _repositorios.escuelas.enviarSolicitud(escuela);
    return escuela;
  }

  Future<Escuela?> miSolicitudEscuela() => _repositorios.escuelas.deDueno(usuario!.uid);
  Future<List<Escuela>> escuelasAprobadas() => _repositorios.escuelas.porEstado(EstadoEscuela.aprobada);

  Future<List<Escuela>> escuelasPorEstado(EstadoEscuela estado) {
    if (!puede(Permiso.administrarEscuelas)) return Future.value(const []);
    return _repositorios.escuelas.porEstado(estado);
  }

  Future<void> aprobarEscuela(Escuela e) async {
    if (!puede(Permiso.administrarEscuelas)) return;
    await _repositorios.escuelas.aprobar(e);
  }

  Future<void> rechazarEscuela(Escuela e, String motivo) async {
    if (!puede(Permiso.administrarEscuelas)) return;
    await _repositorios.escuelas.rechazar(e, motivo);
  }

  /// Acudiente o estudiante: pide cupo en una escuela.
  Future<void> inscribir(
    Escuela escuela, {
    required String nombreJugador,
    required int edad,
    required String telefono,
    required String nota,
  }) async {
    final u = usuario;
    if (u is! Familia) return;
    await _repositorios.inscripciones.solicitar(Inscripcion(
      id: '${u.uid}-${escuela.id}-${DateTime.now().millisecondsSinceEpoch}',
      escuelaId: escuela.id,
      nombreEscuela: escuela.nombre,
      solicitanteUid: u.uid,
      nombreSolicitante: u.nombre,
      correoSolicitante: u.correo,
      nombreJugador: nombreJugador.trim(),
      edad: edad,
      paraSiMismo: u.esEstudiante,
      telefono: telefono.trim(),
      nota: nota.trim(),
    ));
  }

  Future<List<Inscripcion>> misInscripciones() => _repositorios.inscripciones.deSolicitante(usuario!.uid);

  /// Resumen de un hijo para el panel del acudiente: lee la escuela del hijo
  /// con un juego de repositorios aparte, sin tocar la escuela activa.
  Future<ResumenJugador?> resumenDe(Inscripcion i) async {
    if (!i.aprobada) return null;
    final repos = _repositorios.paraEscuela(i.escuelaId);
    final plantel = await repos.jugadores.cargarPlantel();
    final jugador = plantel.where((j) => j.id == i.jugadorId).firstOrNull;
    if (jugador == null) return null;
    final sesiones = await repos.sesiones.cargarSesiones();
    final caja = await repos.caja.cargarCaja(plantel);
    return ResumenJugador.calcular(
      jugador: jugador,
      nombreEscuela: i.nombreEscuela,
      sesiones: sesiones,
      cuotas: caja.cuotas,
    );
  }

  /// DT: inscripciones esperando respuesta en su escuela.
  Future<List<Inscripcion>> inscripcionesPendientes() async {
    final u = usuario;
    if (u is! DirectorTecnico || !puede(Permiso.gestionarInscripciones)) return const [];
    return _repositorios.inscripciones.pendientesDeEscuela(u.escuelaId);
  }

  /// Próximo id libre del plantel, para una ficha nueva.
  int get siguienteIdJugador => plantel.fold(0, (m, j) => j.id > m ? j.id : m) + 1;

  Future<void> aprobarInscripcion(Inscripcion i, {FichaNueva? nueva, Jugador? existente}) async {
    if (!puede(Permiso.gestionarInscripciones)) return;
    await _repositorios.inscripciones.aprobar(i, nueva: nueva, existente: existente);
    if (nueva != null) await _plantel.cargar();
    avisar('${i.nombreJugador} ya es parte del plantel');
  }

  Future<void> rechazarInscripcion(Inscripcion i) async {
    if (!puede(Permiso.gestionarInscripciones)) return;
    await _repositorios.inscripciones.rechazar(i);
  }

  Timer? _borrarAviso;

  /// Muestra un aviso que se borra solo. Un aviso nuevo reemplaza al anterior
  /// (y reinicia la cuenta, para que no lo borre el temporizador del viejo).
  void avisar(String mensaje) {
    _aviso = mensaje;
    notifyListeners();
    _borrarAviso?.cancel();
    _borrarAviso = Timer(const Duration(milliseconds: 2400), () {
      _aviso = null;
      notifyListeners();
    });
  }

  /// Ficha del jugador logueado (null para el DT).
  Jugador? get miFicha {
    final u = usuario;
    if (u is! JugadorUsuario) return null;
    return _plantel.plantel.where((j) => j.id == u.jugadorId).firstOrNull;
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
    final enJuego = _agenda.partidos.where((p) => p.enJuego).firstOrNull;
    if (enJuego != null) {
      _partidoEnVivo.registrarCambio(enJuego, sale: sale, entra: entra);
    }
    avisar('Entra ${entra.apellido} por ${sale.apellido}');
  }

  void guardarAlineacion() {
    if (!puede(Permiso.editarAlineacion)) return;
    _guardar(_alineacion.guardar(), 'la alineación');
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

  /// Corre una escritura en la base de datos sin frenar la UI: si falla
  /// (sin red, permisos), se avisa en vez de perder el error en silencio.
  void _guardar(Future<void> escritura, String queFallo) {
    escritura.catchError((Object e, StackTrace st) {
      debugPrint('Error guardando ($queFallo): $e\n$st');
      avisar('No se pudo guardar $queFallo. Revisa tu conexión.');
    });
  }

  // ── Agenda, convocatoria y asistencia ────────────────────────────────
  List<Partido> get partidos => _agenda.partidos;

  /// Próximo partido sin jugar; null si la escuela no tiene ninguno pendiente.
  Partido? get partidoActual => _agenda.actual;
  List<SesionEntrenamiento> get sesiones => _agenda.sesiones;
  Convocatoria? get convocatoria => _agenda.convocatoria;

  /// El partido en vivo necesita un partido programado y once titulares.
  bool get puedeJugarPartido => partidoActual != null && _alineacion.activa.titulares.length >= 11;

  bool estoyConvocado() {
    final f = miFicha;
    final c = _agenda.convocatoria;
    // Solo cuenta lo que el DT ya envió: la propuesta en borrador no cita a nadie.
    return f != null && c != null && c.enviada && c.incluye(f.id);
  }

  bool soyTitular() {
    final f = miFicha;
    return f != null && _alineacion.activa.contiene(f.id);
  }

  void alternarConvocado(Jugador j) {
    if (!puede(Permiso.gestionarConvocatoria)) return;
    if (!_agenda.alternarConvocado(j, guardar: (f) => _guardar(f, 'la convocatoria'))) {
      avisar(j.disponible ? 'Tope de ${_agenda.convocatoria?.tope ?? 0} convocados' : '${j.apellido} está lesionado');
    }
  }

  void enviarConvocatoria() {
    if (!puede(Permiso.gestionarConvocatoria)) return;
    _guardar(_agenda.enviarConvocatoria(), 'la convocatoria');
    avisar('Citación enviada a ${_agenda.convocatoria?.total ?? 0} jugadores');
  }

  /// Cada marca se guarda al instante: es lo que el acudiente ve como
  /// "asistencia a entrenos".
  void marcarAsistencia(SesionEntrenamiento s, Jugador j, bool presente) {
    if (!puede(Permiso.registrarAsistencia)) return;
    _guardar(_agenda.marcarAsistencia(s, j, presente), 'la asistencia');
  }

  /// DT: agenda un partido nuevo. Si es el más próximo, pasa a ser el actual.
  Future<void> programarPartido({
    required String rival,
    required DateTime fecha,
    required String sede,
    required String competencia,
    required bool local,
  }) async {
    if (!puede(Permiso.dirigirPartido)) return;
    final p = Partido(
      id: _agenda.siguienteIdPartido,
      rival: rival.trim(),
      fecha: fecha,
      sede: sede.trim(),
      competencia: competencia.trim().isEmpty ? 'Amistoso' : competencia.trim(),
      local: local,
    );
    await _agenda.programarPartido(p, plantel);
    avisar('Partido vs. ${p.rival} programado');
  }

  /// DT: agenda un entreno (o charla/gimnasio).
  Future<void> programarSesion({
    required String titulo,
    required DateTime fecha,
    required String lugar,
    required TipoSesion tipo,
  }) async {
    if (!puede(Permiso.registrarAsistencia)) return;
    final s = SesionEntrenamiento(
      id: _agenda.siguienteIdSesion,
      titulo: titulo.trim(),
      fecha: fecha,
      lugar: lugar.trim(),
      tipo: tipo,
    );
    await _agenda.programarSesion(s);
    avisar('${s.titulo} agendado');
  }

  // ── Partido en vivo ──────────────────────────────────────────────────
  /// Arranca el reloj de [p]. Si ya estaba en curso (se volvió a abrir la
  /// pantalla), no lo reinicia.
  void iniciarPartido(Partido p) {
    if (!puede(Permiso.dirigirPartido) || !p.programado || !puedeJugarPartido) return;
    _partidoEnVivo.iniciar(p, _alineacion.activa.titulares);
  }

  void alternarReloj(Partido p) {
    if (!puede(Permiso.dirigirPartido) || !p.enProgreso) return;
    _partidoEnVivo.alternarReloj(p);
  }

  /// Ajuste manual del minuto (+1 / −1) por si el reloj quedó desfasado.
  void corregirMinuto(Partido p, int delta) {
    if (!puede(Permiso.dirigirPartido) || !p.enProgreso) return;
    _partidoEnVivo.corregirMinuto(p, delta);
  }

  /// Jugadores que están ahora en la cancha (para elegir goleador, tarjeta…).
  List<Jugador> get enCancha => _alineacion.activa.titulares;

  void anotarGol(Partido p, {Jugador? autor, Jugador? asistente, bool rival = false}) {
    if (!puede(Permiso.dirigirPartido) || !p.enProgreso) return;
    if (rival) {
      _partidoEnVivo.anotarGol(p, rival: true);
      avisar('Gol del rival');
      return;
    }
    if (autor == null) return;
    _partidoEnVivo.anotarGol(p, goleador: autor, asistente: asistente);
    avisar('¡Gol de ${autor.apellido}!');
  }

  void anotarTarjeta(Partido p, Jugador j, {ColorTarjeta color = ColorTarjeta.amarilla}) {
    if (!puede(Permiso.dirigirPartido) || !p.enProgreso) return;
    _partidoEnVivo.anotarTarjeta(p, j, color: color);
  }

  /// Cierra el partido: suma minutos y partidos jugados, y guarda en la base
  /// de datos el resultado y las estadísticas de cada jugador que participó
  /// (es lo que ven los jugadores y sus acudientes).
  void finalizarPartido(Partido p) {
    if (!puede(Permiso.dirigirPartido) || !p.enProgreso) return;
    final tocados = _partidoEnVivo.finalizar(p);
    _guardar(
      Future.wait([
        _agenda.cerrarPartido(p, plantel),
        if (tocados.isNotEmpty) _repositorios.jugadores.guardarEstadisticas(tocados),
      ]),
      'el resultado del partido',
    );
    avisar('Partido cerrado · estadísticas guardadas');
  }

  /// DT: pasa al jugador al siguiente estado físico (apto → carga → lesión)
  /// y lo guarda. Un lesionado sale de la convocatoria.
  void cambiarEstadoFisico(Jugador j) {
    if (!puede(Permiso.verFichaAjena)) return;
    final siguiente = EstadoFisico.values[(EstadoFisico.values.indexOf(j.estado) + 1) % EstadoFisico.values.length];
    j.cambiarEstado(siguiente);
    final c = _agenda.convocatoria;
    if (!j.disponible && c != null && c.incluye(j.id)) {
      _agenda.alternarConvocado(j, guardar: (f) => _guardar(f, 'la convocatoria'));
    }
    _guardar(_repositorios.jugadores.guardarEstadoFisico(j), 'el estado físico');
    avisar('${j.apellido}: ${siguiente.etiqueta}');
  }

  // ── Dinero ───────────────────────────────────────────────────────────
  CajaMensual get caja => _finanzas.caja;

  /// El DT ve la caja completa; el jugador sólo su cuota.
  List<Cuota> get cuotasVisibles {
    if (puede(Permiso.verFinanzasClub)) return _finanzas.caja.cuotas;
    final c = miCuota;
    return c == null ? const [] : [c];
  }

  Cuota? get miCuota {
    final f = miFicha;
    return f == null ? null : _finanzas.caja.deJugador(f.id);
  }

  /// Mes en curso, para el cobro de cuotas.
  MesCobro get mesActual => MesCobro.de(DateTime.now());

  /// Jugadores del plantel sin cuota en el mes en curso (todos, si la caja
  /// cargada es de un mes anterior).
  List<Jugador> get sinCuotaEsteMes {
    if (_finanzas.caja.id != mesActual.id) return plantel;
    return plantel.where((j) => _finanzas.caja.deJugador(j.id) == null).toList();
  }

  /// DT: crea las cuotas del mes en curso para quienes aún no la tienen.
  Future<void> crearCuotasDelMes(int monto) async {
    if (!puede(Permiso.verFinanzasClub)) return;
    final faltan = sinCuotaEsteMes;
    if (faltan.isEmpty) return;
    await _finanzas.crearCuotas(mesActual, monto: monto, jugadores: faltan, plantel: plantel);
    avisar('${faltan.length} cuotas de ${mesActual.nombre} creadas');
  }

  void reportarMiPago() {
    final c = miCuota;
    if (c == null || !puede(Permiso.verFinanzasPropias)) return;
    _guardar(_finanzas.reportarPago(c), 'el reporte de pago');
    avisar('Pago reportado · pendiente de confirmación');
  }

  void confirmarPago(Cuota c) {
    if (!puede(Permiso.verFinanzasClub)) return;
    _guardar(_finanzas.confirmarPago(c), 'el pago');
  }

  void enviarRecordatorio() {
    if (!puede(Permiso.verFinanzasClub)) return;
    avisar('Recordatorio enviado a ${_finanzas.caja.pendientes} acudientes');
  }

  @override
  void dispose() {
    _borrarAviso?.cancel();
    for (final c in _controladores) {
      c.dispose();
    }
    super.dispose();
  }
}

/// Inyección del estado en el árbol de widgets sin dependencias externas.
class AlcanceApp extends InheritedNotifier<AppEstado> {
  const AlcanceApp({super.key, required AppEstado estado, required super.child}) : super(notifier: estado);

  static AppEstado de(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AlcanceApp>()!.notifier!;
}
