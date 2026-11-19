// Convierte una cuenta ya registrada en la app en administrador.
// Uso: node tool/hacer_admin.mjs correo@ejemplo.com
//
// La persona primero se registra normalmente en la app (correo o Google) y
// elige cualquier rol; este script le cambia el rol a 'admin'. Las reglas de
// Firestore impiden que alguien se haga admin solo, por eso se hace desde
// aquí, con la sesión del Firebase CLI (`firebase login`) del dueño.

import { createRequire } from 'node:module';
import path from 'node:path';

const PROYECTO = 'movil-95965';
const correo = (process.argv[2] ?? '').trim().toLowerCase();
if (!correo.includes('@')) {
  console.error('Uso: node tool/hacer_admin.mjs correo@ejemplo.com');
  process.exit(1);
}

const require = createRequire(import.meta.url);
const ft = path.join(process.env.APPDATA ?? '', 'npm', 'node_modules', 'firebase-tools', 'lib');
const auth = require(path.join(ft, 'auth.js'));
const scopes = require(path.join(ft, 'scopes.js'));
const cuenta = auth.getGlobalDefaultAccount();
if (!cuenta) {
  console.error('Primero inicia sesión: firebase login');
  process.exit(1);
}
const { access_token: token } = await auth.getAccessToken(cuenta.tokens.refresh_token, [scopes.CLOUD_PLATFORM]);
const cabeceras = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };
const base = `https://firestore.googleapis.com/v1/projects/${PROYECTO}/databases/(default)/documents`;

// Busca el perfil por correo.
const consulta = await fetch(`${base}:runQuery`, {
  method: 'POST',
  headers: cabeceras,
  body: JSON.stringify({
    structuredQuery: {
      from: [{ collectionId: 'usuarios' }],
      where: { fieldFilter: { field: { fieldPath: 'correo' }, op: 'EQUAL', value: { stringValue: correo } } },
      limit: 1,
    },
  }),
});
const filas = (await consulta.json()).filter((f) => f.document);
if (filas.length === 0) {
  console.error(`No hay ningún perfil con ${correo}. Regístrate primero en la app y elige un rol.`);
  process.exit(1);
}
const doc = filas[0].document;
const rolActual = doc.fields?.rol?.stringValue;
if (rolActual === 'admin') {
  console.log(`${correo} ya es admin.`);
  process.exit(0);
}

const r = await fetch(`https://firestore.googleapis.com/v1/${doc.name}?updateMask.fieldPaths=rol`, {
  method: 'PATCH',
  headers: cabeceras,
  body: JSON.stringify({ fields: { rol: { stringValue: 'admin' } } }),
});
if (!r.ok) {
  console.error('No se pudo actualizar:', r.status, await r.text());
  process.exit(1);
}
console.log(`Listo: ${correo} pasó de '${rolActual}' a 'admin'. Cierra sesión en la app y vuelve a entrar.`);
