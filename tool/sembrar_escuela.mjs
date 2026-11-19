// Renombra una escuela y le carga un plantel de ejemplo (30 jugadores de
// distintas edades, con dorsal, posición y pie hábil, estadísticas en cero).
// Uso: node tool/sembrar_escuela.mjs MK-XXXXXX "Nombre de la escuela"
//
// Usa la sesión del Firebase CLI (`firebase login`). Escribe con `set`, así
// que correrlo dos veces deja el mismo resultado (no duplica jugadores).

import { createRequire } from 'node:module';
import path from 'node:path';

const PROYECTO = 'movil-95965';
const [escuelaId, nombre] = process.argv.slice(2);
if (!escuelaId || !nombre) {
  console.error('Uso: node tool/sembrar_escuela.mjs MK-XXXXXX "Nombre de la escuela"');
  process.exit(1);
}

const require = createRequire(import.meta.url);
const ft = path.join(process.env.APPDATA ?? '', 'npm', 'node_modules', 'firebase-tools', 'lib');
const auth = require(path.join(ft, 'auth.js'));
const scopes = require(path.join(ft, 'scopes.js'));
const { access_token: token } = await auth.getAccessToken(auth.getGlobalDefaultAccount().tokens.refresh_token, [
  scopes.CLOUD_PLATFORM,
]);
const raiz = `projects/${PROYECTO}/databases/(default)/documents`;
const cabeceras = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };

const s = (v) => ({ stringValue: String(v) });
const i = (v) => ({ integerValue: String(v) });
const m = (campos) => ({ mapValue: { fields: campos } });

// [nombre, edad, posición, detalle, pie]
const plantel = [
  ['Santiago Epieyú', 9, 'portero', 'Portero', 'Derecho'],
  ['Mateo Pushaina', 10, 'defensa', 'Central', 'Derecho'],
  ['Samuel Uriana', 11, 'defensa', 'Lateral der.', 'Derecho'],
  ['Juan José Ipuana', 12, 'mediocampo', 'Volante central', 'Izquierdo'],
  ['Emiliano Gouriyú', 13, 'delantero', 'Delantero', 'Derecho'],
  ['Thiago Iguarán', 14, 'delantero', 'Extremo izq.', 'Izquierdo'],
  ['Sebastián Brito', 15, 'mediocampo', 'Enganche', 'Derecho'],
  ['Matías Deluque', 16, 'defensa', 'Lateral izq.', 'Izquierdo'],
  ['Nicolás Fonseca', 17, 'portero', 'Portero', 'Derecho'],
  ['Alejandro Redondo', 9, 'mediocampo', 'Volante mixto', 'Derecho'],
  ['Daniel Curvelo', 10, 'delantero', 'Extremo der.', 'Derecho'],
  ['David Mendoza', 11, 'defensa', 'Central', 'Derecho'],
  ['Jerónimo Solano', 12, 'mediocampo', 'Volante def.', 'Derecho'],
  ['Martín Cotes', 13, 'defensa', 'Central', 'Izquierdo'],
  ['Gabriel Daza', 14, 'mediocampo', 'Volante central', 'Derecho'],
  ['Lucas Zúñiga', 15, 'delantero', 'Delantero', 'Ambos'],
  ['Simón Pimienta', 16, 'mediocampo', 'Volante izq.', 'Izquierdo'],
  ['Felipe Villazón', 17, 'delantero', 'Extremo izq.', 'Derecho'],
  ['Tomás Ramírez', 9, 'defensa', 'Lateral der.', 'Derecho'],
  ['Andrés Gámez', 10, 'portero', 'Portero', 'Derecho'],
  ['Joaquín Epinayú', 11, 'mediocampo', 'Enganche', 'Izquierdo'],
  ['Maximiliano Barrios', 12, 'defensa', 'Lateral izq.', 'Izquierdo'],
  ['Isaac Jayariyú', 13, 'delantero', 'Extremo der.', 'Derecho'],
  ['Benjamín Arpushana', 14, 'defensa', 'Central', 'Derecho'],
  ['Juan Pablo Toro', 15, 'mediocampo', 'Volante mixto', 'Derecho'],
  ['Emmanuel Sapuana', 16, 'delantero', 'Delantero', 'Derecho'],
  ['Agustín Bonivento', 17, 'mediocampo', 'Volante central', 'Izquierdo'],
  ['Dylan Ballesteros', 11, 'defensa', 'Central', 'Derecho'],
  ['Kevin Cuello', 13, 'mediocampo', 'Volante izq.', 'Izquierdo'],
  ['Valentino Sierra', 15, 'delantero', 'Extremo izq.', 'Derecho'],
];

const escrituras = [
  {
    update: { name: `${raiz}/escuelas/${escuelaId}`, fields: { nombre: s(nombre) } },
    updateMask: { fieldPaths: ['nombre'] },
    currentDocument: { exists: true },
  },
  ...plantel.map(([nom, edad, pos, detalle, pie], k) => ({
    update: {
      name: `${raiz}/escuelas/${escuelaId}/jugadores/${k + 1}`,
      fields: {
        id: i(k + 1),
        dorsal: i(k + 1),
        nombre: s(nom),
        posicion: s(pos),
        detallePosicion: s(detalle),
        edad: i(edad),
        pieHabil: s(pie),
        estado: s('apto'),
        atributos: m({}),
        estadisticas: m({ partidos: i(0), minutos: i(0), goles: i(0), asistencias: i(0), amarillas: i(0) }),
      },
    },
  })),
];

const r = await fetch(`https://firestore.googleapis.com/v1/${raiz}:commit`, {
  method: 'POST',
  headers: cabeceras,
  body: JSON.stringify({ writes: escrituras }),
});
if (!r.ok) {
  console.error('Error:', r.status, await r.text());
  process.exit(1);
}
console.log(`Listo: "${nombre}" (${escuelaId}) con ${plantel.length} jugadores.`);
