# Makuira · Gestión (Flutter / Dart)

App de gestión para un equipo de fútbol juvenil, escrita en Flutter con
programación orientada a objetos y **sin dependencias externas**. Es la
traducción a código del prototipo `Gestion Equipo.dc.html` de este proyecto.

## Correr

```bash
cd flutter
flutter pub get
flutter run
```

La fuente Archivo (variable, cubre los pesos 400/600/800) ya está incluida en
`assets/fonts/` y declarada en `pubspec.yaml`.

Cuentas de la demo, solo en los tests (`AuthEnMemoria`, clave `1234`):

| Correo | Rol |
| --- | --- |
| `dt@makuira.co` | Director técnico — ve y edita todo |
| `zuniga@makuira.co` | Jugador — solo lo suyo |

## Registro y roles

La app es multi-escuela: cada escuela guarda sus datos en `escuelas/{id}/…`.

| Rol (`usuarios/{uid}.rol`) | Cómo se llega | Qué ve |
| --- | --- | --- |
| `profesor` | Se registra y elige "Soy profesor" | Formulario de su escuela → código `MK-XXXXXX` + WhatsApp |
| `dt` | El admin aprueba su escuela | La app del club (plantel, táctica, agenda, caja, inscripciones) |
| `acudiente` | Se registra y elige "Soy padre" | Sus hijos (goles, asistencias, entrenos, deuda) o el catálogo de escuelas |
| `estudiante` | Se registra y elige "Soy estudiante" | Catálogo de escuelas; al ser aceptado, entra como jugador |
| `admin` | **A mano** en la consola de Firebase | Solicitudes de escuelas para aprobar/rechazar |

Las reglas (`firestore.rules`) impiden que una cuenta se dé `dt` o `admin` sola.

### Lo que el DT guarda en la base de datos

| Acción | Dónde | Lo ven |
| --- | --- | --- |
| Programar partido / entreno (Agenda → *+ Programar*) | `partidos`, `sesiones` | Todos |
| Marcar asistencia de un entreno | `sesiones/{id}.asistencia` | Acudiente (asistencia a entrenos) |
| Finalizar partido (goles con asistente, tarjetas, cambios) | `partidos/{id}` + `jugadores/{id}.estadisticas` | Jugador y acudiente |
| Crear cuotas del mes (Club) y confirmar pagos | `caja/{AAAA-MM}/cuotas` | Acudiente (lo que debe) |

El reloj del partido corre en tiempo real (1 minuto por minuto) y se pausa en el entretiempo.
Cada jugada se guarda al momento: si la app se cierra a mitad del partido, al volver queda en
pausa con su acta y su minuto (corregible con −1′ / +1′). Las estadísticas se suman al finalizar.

### Pruebas

```bash
flutter test
```

Las reglas de seguridad se prueban contra el emulador local de Firestore (base temporal, no toca
la real). Necesita Java (sirve el de Android Studio, en `JAVA_HOME`):

```bash
cd tool/pruebas_reglas && npm install
firebase emulators:exec --only firestore --project demo-makuira --config ../../firebase.json "npm test"
```

### Configuración pendiente en Firebase

1. **Admin:** regístrate en la app con la cuenta que será admin (elige cualquier rol) y corre
   `node tool/hacer_admin.mjs tu@correo.com`. Cierra sesión y vuelve a entrar. Usa una cuenta
   distinta a la de cualquier profesor: al aprobar una escuela, su dueño pasa a ser `dt`.
2. **Google Sign-In:** *Authentication → Sign-in method → Google → Habilitar*. Luego en
   *Configuración del proyecto → Tu app Android → Agregar huella digital* pega el SHA-1 de debug
   (`keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android`)
   y vuelve a descargar `google-services.json` a `android/app/`.
3. **Reglas:** `firebase deploy --only firestore:rules`.
4. **Correo de bienvenida** (gratis, EmailJS): al terminar el registro la app manda un solo
   correo, igual para todos. La plantilla está en `tool/correo_bienvenida.html` (variables
   `{{nombre}}`, `{{correo}}`, `{{rol}}`) y los ids van en `lib/core/config_correo.dart`.
   En EmailJS hay que activar *Account → Security → Allow EmailJS API for non-browser applications*.

Las fotos se guardan comprimidas en Firestore (`fotos/{id}`) para no depender de Storage; el mapa
es OpenStreetMap (`flutter_map`), sin clave de API.

## POO: cómo está organizado

```
lib/
├── main.dart                  Arranque + puerta: splash → login → shell por rol
├── core/tema_modernista.dart  Tokens del design system (color, tipo, espaciado)
├── modelos/                   Dominio puro, sin Flutter
│   ├── usuario.dart           abstract Usuario → DirectorTecnico | JugadorUsuario
│   ├── jugador.dart           Jugador + Estadisticas + enums Posicion/EstadoFisico
│   ├── alineacion.dart        Formacion, PuntoCampo, FichaCampo, Alineacion
│   ├── partido.dart           abstract EventoPartido → Gol | Tarjeta | Cambio
│   └── finanzas.dart          Cuota, CajaMensual, Convocatoria
├── servicios/
│   ├── auth_servicio.dart     abstract AuthServicio → AuthEnMemoria
│   ├── equipo_repositorio.dart abstract EquipoRepositorio → ...Demo
│   └── exportable.dart        interface Exportable + Exportador (PNG/PDF/enlace)
├── estado/app_estado.dart     ChangeNotifier: única fuente de verdad
├── widgets/comunes.dart       Regla, Kicker, BotonModernista, GrillaCifras…
└── pantallas/                 Una pantalla por archivo
```

Los cuatro pilares, concretos:

- **Encapsulación** — `Jugador._estadisticas`, `Partido._eventos`, `Usuario._clave`
  son privados; se tocan por métodos con intención (`registrarPartido`,
  `anotar`, `verificarClave`). Las listas salen como `List.unmodifiable`.
- **Herencia** — `Usuario` es abstracta y sus dos subclases definen `permisos`,
  `rolCorto` y `cargo`. Igual con `EventoPartido` → `Gol`, `Tarjeta`, `Cambio`.
- **Polimorfismo** — el acta del partido recorre una sola lista de eventos y
  pide `e.descripcion`: cada subclase se describe sola, sin `switch` por tipo.
- **Abstracción** — la UI depende de `AuthServicio`, `EquipoRepositorio` y
  `Exportable`, no de implementaciones. Cambiar a una API real es escribir
  `AuthApi` / `EquipoApiRepositorio` sin tocar pantallas.

Extra: `Exportador` es una estrategia — agregar un formato de descarga es
agregar una subclase (abierto/cerrado), y `ServicioExportacion` la fachada.

## Permisos: qué ve el jugador

La UI nunca pregunta "¿es DT?", pregunta `estado.puede(Permiso.x)`. El enum
`Permiso` vive en `modelos/usuario.dart` y cada rol declara su conjunto.

El jugador (`JugadorUsuario`) solo tiene:

- `verFichaPropia` — su rendimiento, atributos y asistencia.
- `verFinanzasPropias` — su cuota, con botón para reportar el pago.
- `verAlineacionPublicada` — la pizarra en modo lectura, su posición en rojo.
- `verAgenda` — partidos y entrenos, sin planillas.
- `verPlantelCompleto` — la lista de compañeros **sin** minutos, goles ni
  estado médico (`Jugador.resumenPublico()`), y sin poder abrir sus fichas.

Las barreras están en tres capas, no solo en la navegación:

1. `ShellPantalla` arma pestañas distintas por rol (el jugador no ve Club ni
   Convocatoria).
2. `AppEstado` filtra los datos antes de devolverlos (`cuotasVisibles`,
   `puedeAbrirFicha`) y rechaza las mutaciones sin permiso.
3. Cada pantalla sensible revalida al construirse (`ClubPantalla`,
   `ConvocatoriaPantalla`, `FichaPantalla`).

## Animación de entrada

`pantallas/splash_pantalla.dart`: un `AnimationController` con intervalos —
la cancha se dibuja trazo a trazo en un `CustomPainter`, entra el bloque rojo
de la marca y el plano hace zoom hasta desaparecer, cediendo el paso al login.

## Qué falta para producción

- Backend real detrás de `AuthServicio` y `EquipoRepositorio` (+ tokens y
  refresh); hoy los datos son de `EquipoRepositorioDemo`.
- Exportación real a PNG/PDF (`RepaintBoundary` + `printing`) en lugar de los
  `ArchivoGenerado` simulados.
- Pruebas: los modelos son puros y se testean sin Flutter.
