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

Cuentas de la demo (clave `1234` en las dos):

| Correo | Rol |
| --- | --- |
| `dt@makuira.co` | Director técnico — ve y edita todo |
| `zuniga@makuira.co` | Jugador — solo lo suyo |

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
