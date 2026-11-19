// Enlaza una cuenta ya registrada (padre/acudiente o estudiante) con un
// jugador del plantel de una escuela, como si el DT hubiera aceptado su
// inscripción: crea la inscripción aprobada y el registro de miembro.
// Uso: node tool/vincular.mjs correo@ejemplo.com MK-XXXXXX <idJugador>
//
// La cuenta tiene que existir y haber elegido su rol en la app. Usa la sesión
// del Firebase CLI (`firebase login`).

import { createRequire } from 'node:module';
import path from 'node:path';

const PROYECTO = 'movil-95965';
const [correoArg, escuelaId, idArg] = process.argv.slice(2);
const correo = (correoArg ?? '').trim().toLowerCase();
const jugadorId = Number(idArg);
if (!correo.includes('@') || !escuelaId || !Number.isInteger(jugadorId)) {
  console.error('Uso: node tool/vincular.mjs correo@ejemplo.com MK-XXXXXX <idJugador>');
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
const api = `https://firestore.googleapis.com/v1/${raiz}`;
const cabeceras = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };
const leer = async (ruta) => (await fetch(`${api}/${ruta}`, { headers: cabeceras })).json();

// Perfil de la cuenta.
const filas = await (
  await fetch(`${api}:runQuery`, {
    method: 'POST',
    headers: cabeceras,
    body: JSON.stringify({
      structuredQuery: {
        from: [{ collectionId: 'usuarios' }],
        where: { fieldFilter: { field: { fieldPath: 'correo' }, op: 'EQUAL', value: { stringValue: correo } } },
        limit: 1,
      },
    }),
  })
).json();
const perfil = filas.find((f) => f.document)?.document;
if (!perfil) {
  console.error(`No hay ningún perfil con ${correo}. Regístrate en la app y elige "padre" o "estudiante".`);
  process.exit(1);
}
const uid = perfil.name.split('/').pop();
const rol = perfil.fields.rol?.stringValue;
if (rol !== 'acudiente' && rol !== 'estudiante') {
  console.error(`${correo} es '${rol}'. Solo se vinculan cuentas de padre (acudiente) o estudiante.`);
  process.exit(1);
}

const escuela = await leer(`escuelas/${escuelaId}`);
const jugador = await leer(`escuelas/${escuelaId}/jugadores/${jugadorId}`);
if (!escuela.fields || !jugador.fields) {
  console.error(`No existe la escuela ${escuelaId} o el jugador ${jugadorId} en ella.`);
  process.exit(1);
}

const s = (v) => ({ stringValue: String(v) });
const i = (v) => ({ integerValue: String(v) });
const ahora = { timestampValue: new Date().toISOString() };
const r = await fetch(`${api}:commit`, {
  method: 'POST',
  headers: cabeceras,
  body: JSON.stringify({
    writes: [
      {
        update: {
          name: `${raiz}/inscripciones/${uid}-${escuelaId}-${jugadorId}`,
          fields: {
            escuelaId: s(escuelaId),
            nombreEscuela: s(escuela.fields.nombre.stringValue),
            solicitanteUid: s(uid),
            nombreSolicitante: s(perfil.fields.nombre?.stringValue ?? ''),
            correoSolicitante: s(correo),
            nombreJugador: s(jugador.fields.nombre.stringValue),
            edad: i(jugador.fields.edad.integerValue),
            paraSiMismo: { booleanValue: rol === 'estudiante' },
            telefono: s(''),
            nota: s('Vinculado por el administrador.'),
            estado: s('aprobada'),
            jugadorId: i(jugadorId),
            creada: ahora,
          },
        },
      },
      {
        update: { name: `${raiz}/escuelas/${escuelaId}/miembros/${uid}`, fields: { uid: s(uid) } },
        updateMask: { fieldPaths: ['uid'] },
      },
      {
        transform: {
          document: `${raiz}/escuelas/${escuelaId}/miembros/${uid}`,
          fieldTransforms: [{ fieldPath: 'jugadorIds', appendMissingElements: { values: [s(jugadorId)] } }],
        },
      },
    ],
  }),
});
if (!r.ok) {
  console.error('Error:', r.status, await r.text());
  process.exit(1);
}
const quien = rol === 'estudiante' ? 'El estudiante' : 'El padre';
console.log(`Listo: ${quien} ${correo} quedó vinculado a ${jugador.fields.nombre.stringValue} (#${jugadorId}).`);
console.log('Cierra sesión en la app y vuelve a entrar para verlo.');
