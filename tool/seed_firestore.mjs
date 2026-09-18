// Sube los datos demo (los mismos de EquipoRepositorioDemo) a Firestore.
// Uso: node tool/seed_firestore.mjs
// Necesita las variables de entorno PROJECT_ID, DT_UID, DT_ID_TOKEN, JUGADOR_UID
// (ver README de este script en el mensaje de quien lo corrió).

const PROJECT_ID = process.env.PROJECT_ID;
const DT_UID = process.env.DT_UID;
const DT_ID_TOKEN = process.env.DT_ID_TOKEN;
const JUGADOR_UID = process.env.JUGADOR_UID;

if (!PROJECT_ID || !DT_UID || !DT_ID_TOKEN || !JUGADOR_UID) {
  console.error('Faltan variables de entorno: PROJECT_ID, DT_UID, DT_ID_TOKEN, JUGADOR_UID');
  process.exit(1);
}

const BASE = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

// ---- Helpers para el formato tipado de Firestore REST ----
const sv = (s) => ({ stringValue: String(s) });
const iv = (n) => ({ integerValue: String(n) });
const dv = (n) => ({ doubleValue: n });
const bv = (b) => ({ booleanValue: !!b });
const tv = (iso) => ({ timestampValue: iso });
const mv = (fields) => ({ mapValue: { fields } });
const av = (values) => ({ arrayValue: { values } });

// :batchWrite no respeta bien el contexto de auth de usuario final (probado
// contra un PATCH directo, que sí funciona) — así que escribimos documento
// por documento con PATCH, que es lo mismo que hacen los SDK cliente.
async function putDoc(path, fields) {
  const res = await fetch(`${BASE}/${path}`, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${DT_ID_TOKEN}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ fields }),
  });
  const json = await res.json();
  if (!res.ok) {
    console.error(`ERROR en ${path}:`, res.status, JSON.stringify(json, null, 2));
    process.exit(1);
  }
  return json;
}

async function writeAll(writes) {
  for (const w of writes) {
    await putDoc(w.path, w.fields);
  }
}

function doc(path, fields) {
  return { path, fields };
}

// ---- Datos demo (espejo de EquipoRepositorioDemo) ----
const jugadoresRaw = [
  [1, 1, 'A. Barrios', 'portero', 'Portero', 19, 'Derecho', 1260, 0, 0],
  [2, 3, 'J. Mendoza', 'defensa', 'Lateral izq.', 18, 'Izquierdo', 1104, 1, 3],
  [3, 4, 'S. Cotes', 'defensa', 'Central', 19, 'Derecho', 1190, 2, 0],
  [4, 2, 'K. Epieyú', 'defensa', 'Central', 18, 'Derecho', 980, 1, 1],
  [5, 13, 'D. Solano', 'defensa', 'Lateral der.', 17, 'Derecho', 845, 0, 4],
  [6, 6, 'M. Brito', 'mediocampo', 'Volante mixto', 19, 'Derecho', 1210, 1, 2],
  [7, 8, 'R. Daza', 'mediocampo', 'Volante central', 18, 'Izquierdo', 1015, 3, 5],
  [8, 10, 'L. Zúñiga', 'mediocampo', 'Enganche', 19, 'Izquierdo', 986, 7, 4],
  [9, 11, 'E. Redondo', 'delantero', 'Extremo izq.', 17, 'Derecho', 720, 5, 3],
  [10, 9, 'Y. Pushaina', 'delantero', 'Delantero', 18, 'Derecho', 1120, 11, 2],
  [11, 7, 'C. Uriana', 'delantero', 'Extremo der.', 17, 'Izquierdo', 690, 4, 6],
  [12, 12, 'H. Pimienta', 'portero', 'Portero', 17, 'Derecho', 180, 0, 0],
  [13, 5, 'N. Iguarán', 'defensa', 'Central', 18, 'Derecho', 610, 0, 0, 'lesionado'],
  [14, 14, 'B. Ramírez', 'mediocampo', 'Volante central', 17, 'Derecho', 540, 1, 1],
  [15, 15, 'T. Gámez', 'defensa', 'Central', 19, 'Izquierdo', 470, 0, 0],
  [16, 16, 'W. Curvelo', 'mediocampo', 'Volante izq.', 18, 'Izquierdo', 430, 2, 2, 'cargaAlta'],
  [17, 17, 'F. Ipuana', 'delantero', 'Delantero', 17, 'Derecho', 380, 3, 0],
  [18, 18, 'G. Fonseca', 'defensa', 'Lateral der.', 17, 'Derecho', 295, 0, 1],
  [19, 19, 'P. Villazón', 'delantero', 'Extremo der.', 16, 'Derecho', 210, 1, 1, 'cargaAlta'],
  [20, 20, 'O. Deluque', 'mediocampo', 'Volante def.', 18, 'Derecho', 640, 0, 2, 'lesionado'],
];

const writesJugadores = jugadoresRaw.map(
  ([id, dorsal, nombre, posicion, detalle, edad, pie, minutos, goles, asis, estado = 'apto']) =>
    doc(`jugadores/${id}`, {
      id: iv(id),
      dorsal: iv(dorsal),
      nombre: sv(nombre),
      posicion: sv(posicion),
      detallePosicion: sv(detalle),
      edad: iv(edad),
      pieHabil: sv(pie),
      estado: sv(estado),
      atributos:
        id === 8
          ? mv({
              Ritmo: iv(69),
              Definición: iv(64),
              Pase: iv(88),
              Regate: iv(91),
              Defensa: iv(52),
              Físico: iv(61),
            })
          : mv({}),
      estadisticas: mv({
        partidos: iv(Math.round(minutos / 78)),
        minutos: iv(minutos),
        goles: iv(goles),
        asistencias: iv(asis),
        amarillas: iv(0),
      }),
    })
);

const writesPartidos = [
  doc('partidos/15', {
    id: iv(15),
    rival: sv('Dep. Uribia'),
    fecha: tv('2026-09-19T15:30:00-05:00'),
    sede: sv('Cancha La Serranía'),
    competencia: sv('Liga juvenil'),
    local: bv(true),
    estado: sv('programado'),
    minuto: iv(0),
  }),
  doc('partidos/16', {
    id: iv(16),
    rival: sv('Academia Riohacha'),
    fecha: tv('2026-09-26T10:00:00-05:00'),
    sede: sv('Visitante'),
    competencia: sv('Liga juvenil'),
    local: bv(false),
    estado: sv('programado'),
    minuto: iv(0),
  }),
];

const writesSesiones = [
  doc('sesiones/1', {
    id: iv(1),
    titulo: sv('Fuerza y transiciones'),
    fecha: tv('2026-09-17T16:00:00-05:00'),
    lugar: sv('Sede · cancha 2'),
    tipo: sv('entrenamiento'),
    asistencia: mv({}),
  }),
  doc('sesiones/2', {
    id: iv(2),
    titulo: sv('Charla táctica rival'),
    fecha: tv('2026-09-18T18:00:00-05:00'),
    lugar: sv('Salón sede'),
    tipo: sv('video'),
    asistencia: mv({}),
  }),
  doc('sesiones/3', {
    id: iv(3),
    titulo: sv('Recuperación + balón parado'),
    fecha: tv('2026-09-22T16:00:00-05:00'),
    lugar: sv('Sede · cancha 1'),
    tipo: sv('entrenamiento'),
    asistencia: mv({}),
  }),
];

const writesCuotas = jugadoresRaw.map(([id], i) =>
  doc(`caja/2026-09/cuotas/${id}`, {
    jugadorId: iv(id),
    periodo: sv('Septiembre 2026'),
    monto: iv(60000),
    estado: sv(i % 6 === 2 ? 'pendiente' : 'alDia'),
  })
);

const writesCaja = [doc('caja/2026-09', { periodo: sv('Septiembre 2026') })];

const titularesIds = jugadoresRaw.slice(0, 11).map(([id]) => id);
const f433Puntos = [
  [0.5, 0.92], [0.14, 0.73], [0.37, 0.77], [0.63, 0.77], [0.86, 0.73],
  [0.27, 0.52], [0.5, 0.57], [0.73, 0.52], [0.17, 0.26], [0.5, 0.2], [0.83, 0.26],
];
const f442Puntos = [
  [0.5, 0.92], [0.14, 0.74], [0.37, 0.78], [0.63, 0.78], [0.86, 0.74],
  [0.14, 0.52], [0.38, 0.55], [0.62, 0.55], [0.86, 0.52], [0.38, 0.24], [0.62, 0.24],
];

const fichasDe = (puntos) =>
  av(
    titularesIds.map((jid, i) =>
      mv({ jugadorId: iv(jid), x: dv(puntos[i][0]), y: dv(puntos[i][1]) })
    )
  );

const writesAlineaciones = [
  doc('alineaciones/1', {
    id: iv(1),
    nombre: sv('Presión alta — titular'),
    formacion: sv('4-3-3'),
    creada: tv('2026-09-05T09:12:00-05:00'),
    publicada: bv(true),
    titulares: fichasDe(f433Puntos),
  }),
  doc('alineaciones/2', {
    id: iv(2),
    nombre: sv('Bloque bajo vs. Uribia'),
    formacion: sv('4-4-2'),
    creada: tv('2026-09-12T18:40:00-05:00'),
    publicada: bv(false),
    titulares: fichasDe(f442Puntos),
  }),
];

const writeClub = [
  doc('club/config', {
    nombreClub: sv('Club Makuira'),
    categoria: sv('Sub-20 · Temporada 26'),
  }),
];

const writeUsuarioDT = [
  doc(`usuarios/${DT_UID}`, {
    rol: sv('dt'),
    nombre: sv('Prof. Carrillo'),
    correo: sv('dt@makuira.co'),
    categoria: sv('Sub-20'),
  }),
];

const writeUsuarioJugador = [
  doc(`usuarios/${JUGADOR_UID}`, {
    rol: sv('jugador'),
    nombre: sv('L. Zúñiga'),
    correo: sv('zuniga@makuira.co'),
    jugadorId: sv('8'),
    dorsal: iv(10),
    puesto: sv('Enganche'),
  }),
];

async function main() {
  console.log('1/3 — creando usuarios/{dtUid} (self-write)...');
  await writeAll(writeUsuarioDT);

  console.log('2/3 — creando el resto de las colecciones (autenticado como DT)...');
  await writeAll([
    ...writeUsuarioJugador,
    ...writeClub,
    ...writesJugadores,
    ...writesPartidos,
    ...writesSesiones,
    ...writesCaja,
    ...writesCuotas,
    ...writesAlineaciones,
  ]);

  console.log('3/3 — listo. Documentos creados:');
  console.log(`  usuarios: 2, club: 1, jugadores: ${writesJugadores.length}, partidos: ${writesPartidos.length},`);
  console.log(`  sesiones: ${writesSesiones.length}, caja: 1, cuotas: ${writesCuotas.length}, alineaciones: ${writesAlineaciones.length}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
