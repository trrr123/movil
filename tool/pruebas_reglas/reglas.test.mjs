// Pruebas de firestore.rules: qué puede y qué NO puede hacer cada rol.
// Corren contra el emulador local de Firestore (base de datos temporal):
//
//   cd tool/pruebas_reglas && npm install
//   firebase emulators:exec --only firestore --project demo-makuira "npm test"
//
// El proyecto "demo-*" hace que el emulador nunca hable con Firebase real.

import { after, before, beforeEach, describe, test } from 'node:test';
import { readFileSync } from 'node:fs';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import {
  arrayUnion,
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';

const E1 = 'MK-AAAAAA'; // escuela aprobada (DT: dtA)
const E2 = 'MK-BBBBBB'; // escuela pendiente (dueño: profeB)
const E3 = 'MK-CCCCCC'; // otra escuela aprobada (DT: dtOtro)

let env;

// Contexto de cada persona (uid + correo en el token, como Firebase Auth).
const como = (uid) => env.authenticatedContext(uid, { email: `${uid}@prueba.co` }).firestore();
const anonimo = () => env.unauthenticatedContext().firestore();

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-makuira',
    firestore: { rules: readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8') },
  });
});

after(async () => {
  await env?.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const u = (uid, datos) => setDoc(doc(db, 'usuarios', uid), { nombre: uid, correo: `${uid}@prueba.co`, ...datos });
    await u('admin', { rol: 'admin' });
    await u('dtA', { rol: 'dt', escuelaId: E1 });
    await u('dtOtro', { rol: 'dt', escuelaId: E3 });
    await u('profeB', { rol: 'profesor' });
    await u('padre', { rol: 'acudiente' });
    await u('estudiante', { rol: 'estudiante' });
    await u('intruso', { rol: 'acudiente' });
    await u('viejo', { rol: 'jugador', jugadorId: '1', escuelaId: E1 });

    const escuela = (id, dueno, estado) =>
      setDoc(doc(db, 'escuelas', id), {
        id,
        nombre: `Escuela ${id}`,
        direccion: 'Calle 1 # 2-3',
        profesores: ['Profe'],
        duenoUid: dueno,
        fotoProfesorId: 'foto1',
        estado,
        motivoRechazo: '',
      });
    await escuela(E1, 'dtA', 'aprobada');
    await escuela(E2, 'profeB', 'pendiente');
    await escuela(E3, 'dtOtro', 'aprobada');

    await setDoc(doc(db, `escuelas/${E1}/jugadores/1`), { id: 1, nombre: 'Hijo del padre', estadisticas: {} });
    await setDoc(doc(db, `escuelas/${E1}/jugadores/2`), { id: 2, nombre: 'Otro niño', estadisticas: {} });
    await setDoc(doc(db, `escuelas/${E1}/miembros/padre`), { uid: 'padre', jugadorIds: ['1'] });
    await setDoc(doc(db, `escuelas/${E1}/caja/2026-10`), { periodo: 'Octubre 2026' });
    for (const id of ['1', '2']) {
      await setDoc(doc(db, `escuelas/${E1}/caja/2026-10/cuotas/${id}`), {
        jugadorId: Number(id),
        periodo: 'Octubre 2026',
        monto: 60000,
        estado: 'pendiente',
      });
    }
    await setDoc(doc(db, 'inscripciones', 'pendiente1'), {
      escuelaId: E1,
      solicitanteUid: 'intruso',
      nombreJugador: 'Nuevo',
      edad: 10,
      paraSiMismo: false,
      estado: 'pendiente',
      jugadorId: null,
    });
  });
});

describe('perfiles (usuarios)', () => {
  test('una cuenta nueva crea su perfil como padre, profesor o estudiante', async () => {
    for (const rol of ['acudiente', 'profesor', 'estudiante']) {
      await assertSucceeds(
        setDoc(doc(como(`nuevo-${rol}`), 'usuarios', `nuevo-${rol}`), {
          rol,
          nombre: 'Ana Pérez',
          correo: `nuevo-${rol}@prueba.co`,
          creado: serverTimestamp(),
        }),
      );
    }
  });

  test('NADIE puede darse admin o dt al registrarse', async () => {
    for (const rol of ['admin', 'dt', 'jugador']) {
      await assertFails(
        setDoc(doc(como('nuevo'), 'usuarios', 'nuevo'), { rol, nombre: 'Ana', correo: 'nuevo@prueba.co' }),
      );
    }
  });

  test('no se puede colar una escuela ni un correo ajeno en el perfil', async () => {
    const db = como('nuevo');
    await assertFails(
      setDoc(doc(db, 'usuarios', 'nuevo'), { rol: 'acudiente', nombre: 'Ana', correo: 'nuevo@prueba.co', escuelaId: E1 }),
    );
    await assertFails(setDoc(doc(db, 'usuarios', 'nuevo'), { rol: 'acudiente', nombre: 'Ana', correo: 'otro@prueba.co' }));
    await assertFails(setDoc(doc(db, 'usuarios', 'otro'), { rol: 'acudiente', nombre: 'Ana', correo: 'nuevo@prueba.co' }));
  });

  test('un usuario puede cambiar su nombre pero NO su rol ni su escuela', async () => {
    await assertSucceeds(updateDoc(doc(como('padre'), 'usuarios', 'padre'), { nombre: 'Papá' }));
    await assertFails(updateDoc(doc(como('padre'), 'usuarios', 'padre'), { rol: 'admin' }));
    await assertFails(updateDoc(doc(como('profeB'), 'usuarios', 'profeB'), { rol: 'dt', escuelaId: E2 }));
    await assertFails(updateDoc(doc(como('dtA'), 'usuarios', 'dtA'), { escuelaId: E3 }));
  });

  test('nadie lee perfiles ajenos, salvo el admin', async () => {
    await assertFails(getDoc(doc(como('padre'), 'usuarios', 'dtA')));
    await assertSucceeds(getDoc(doc(como('padre'), 'usuarios', 'padre')));
    await assertSucceeds(getDoc(doc(como('admin'), 'usuarios', 'padre')));
    await assertFails(getDoc(doc(anonimo(), 'usuarios', 'padre')));
  });
});

describe('escuelas', () => {
  const nueva = (dueno, extra = {}) => ({
    id: 'MK-ZZZZZZ',
    nombre: 'Escuela Nueva',
    direccion: 'Calle 9 # 9-9',
    profesores: ['Profe B'],
    duenoUid: dueno,
    fotoProfesorId: 'foto9',
    estado: 'pendiente',
    motivoRechazo: '',
    ...extra,
  });

  test('un profesor envía su escuela a revisión', async () => {
    await assertSucceeds(setDoc(doc(como('profeB'), 'escuelas', 'MK-ZZZZZZ'), nueva('profeB')));
  });

  test('un profesor NO puede enviarla ya aprobada, a nombre de otro, ni sin foto', async () => {
    const db = como('profeB');
    await assertFails(setDoc(doc(db, 'escuelas', 'MK-ZZZZZZ'), nueva('profeB', { estado: 'aprobada' })));
    await assertFails(setDoc(doc(db, 'escuelas', 'MK-ZZZZZZ'), nueva('dtA')));
    await assertFails(setDoc(doc(db, 'escuelas', 'MK-ZZZZZZ'), nueva('profeB', { fotoProfesorId: '' })));
    await assertFails(setDoc(doc(db, 'escuelas', 'hackeada'), { ...nueva('profeB'), id: 'hackeada' }));
  });

  test('un padre o estudiante NO puede registrar escuelas', async () => {
    await assertFails(setDoc(doc(como('padre'), 'escuelas', 'MK-ZZZZZZ'), nueva('padre')));
  });

  test('el profesor NO puede aprobarse a sí mismo', async () => {
    await assertFails(updateDoc(doc(como('profeB'), 'escuelas', E2), { estado: 'aprobada' }));
  });

  test('el admin aprueba: la escuela pasa a aprobada y el profe a DT, en un solo paso', async () => {
    const db = como('admin');
    const lote = writeBatch(db);
    lote.update(doc(db, 'escuelas', E2), { estado: 'aprobada', motivoRechazo: '' });
    lote.update(doc(db, 'usuarios', 'profeB'), { rol: 'dt', escuelaId: E2, categoria: 'Escuela' });
    await assertSucceeds(lote.commit());
  });

  test('cualquiera con sesión ve las aprobadas; las pendientes solo su dueño y el admin', async () => {
    await assertSucceeds(getDocs(query(collection(como('intruso'), 'escuelas'), where('estado', '==', 'aprobada'))));
    await assertFails(getDoc(doc(como('intruso'), 'escuelas', E2)));
    await assertSucceeds(getDoc(doc(como('profeB'), 'escuelas', E2)));
    await assertSucceeds(getDocs(query(collection(como('profeB'), 'escuelas'), where('duenoUid', '==', 'profeB'))));
    await assertSucceeds(getDocs(query(collection(como('admin'), 'escuelas'), where('estado', '==', 'pendiente'))));
    await assertFails(getDocs(query(collection(como('intruso'), 'escuelas'), where('estado', '==', 'pendiente'))));
    await assertFails(getDocs(query(collection(anonimo(), 'escuelas'), where('estado', '==', 'aprobada'))));
  });

  test('el DT edita los datos de SU escuela, pero no el estado; y no toca escuelas ajenas', async () => {
    await assertSucceeds(updateDoc(doc(como('dtA'), 'escuelas', E1), { nombre: 'Club Renovado' }));
    await assertFails(updateDoc(doc(como('dtA'), 'escuelas', E1), { estado: 'pendiente' }));
    await assertFails(updateDoc(doc(como('dtA'), 'escuelas', E1), { duenoUid: 'intruso' }));
    await assertFails(updateDoc(doc(como('dtOtro'), 'escuelas', E1), { nombre: 'Robada' }));
  });
});

describe('datos de la escuela (plantel, partidos, asistencia, alineación)', () => {
  test('el padre miembro y el jugador viejo leen; un intruso y el DT de otra escuela NO', async () => {
    await assertSucceeds(getDocs(collection(como('padre'), `escuelas/${E1}/jugadores`)));
    await assertSucceeds(getDocs(collection(como('viejo'), `escuelas/${E1}/jugadores`)));
    await assertSucceeds(getDoc(doc(como('viejo'), 'escuelas', E1)));
    await assertFails(getDocs(collection(como('intruso'), `escuelas/${E1}/jugadores`)));
    await assertFails(getDocs(collection(como('dtOtro'), `escuelas/${E1}/jugadores`)));
    await assertFails(getDocs(collection(anonimo(), `escuelas/${E1}/jugadores`)));
  });

  test('el DT guarda partidos, entrenos, asistencia, alineación, convocatoria y estadísticas', async () => {
    const db = como('dtA');
    const e = `escuelas/${E1}`;
    await assertSucceeds(setDoc(doc(db, `${e}/partidos/1`), { id: 1, rival: 'X', estado: 'programado' }));
    await assertSucceeds(updateDoc(doc(db, `${e}/partidos/1`), { estado: 'enCurso', minuto: 30, enVivo: { eventos: [] } }));
    await assertSucceeds(setDoc(doc(db, `${e}/sesiones/1`), { id: 1, titulo: 'Entreno', asistencia: {} }));
    await assertSucceeds(updateDoc(doc(db, `${e}/sesiones/1`), { asistencia: { 1: true, 2: false } }));
    await assertSucceeds(setDoc(doc(db, `${e}/alineaciones/actual`), { formacion: '4-3-3', titulares: [] }));
    await assertSucceeds(setDoc(doc(db, `${e}/convocatorias/1`), { llamados: [1, 2], enviada: true }));
    await assertSucceeds(updateDoc(doc(db, `${e}/jugadores/1`), { 'estadisticas.goles': 3, estado: 'lesionado' }));
  });

  test('padres, jugadores, intrusos y DT ajenos NO escriben nada de la escuela', async () => {
    const e = `escuelas/${E1}`;
    for (const uid of ['padre', 'viejo', 'intruso', 'dtOtro', 'estudiante']) {
      const db = como(uid);
      await assertFails(updateDoc(doc(db, `${e}/jugadores/1`), { 'estadisticas.goles': 99 }));
      await assertFails(setDoc(doc(db, `${e}/partidos/9`), { id: 9 }));
      await assertFails(setDoc(doc(db, `${e}/alineaciones/actual`), { titulares: [] }));
      await assertFails(setDoc(doc(db, `${e}/convocatorias/1`), { llamados: [1], enviada: true }));
      await assertFails(setDoc(doc(db, `${e}/sesiones/9`), { asistencia: {} }));
    }
  });

  test('NADIE se puede meter solo como miembro de una escuela', async () => {
    await assertFails(setDoc(doc(como('intruso'), `escuelas/${E1}/miembros/intruso`), { uid: 'intruso', jugadorIds: ['2'] }));
    await assertFails(
      updateDoc(doc(como('padre'), `escuelas/${E1}/miembros/padre`), { jugadorIds: arrayUnion('2') }),
    );
    await assertFails(getDoc(doc(como('padre'), `escuelas/${E1}/miembros/intruso`)));
    await assertSucceeds(getDoc(doc(como('padre'), `escuelas/${E1}/miembros/padre`)));
  });
});

describe('cuotas', () => {
  const cuota = (uid, id) => doc(como(uid), `escuelas/${E1}/caja/2026-10/cuotas/${id}`);

  test('el padre reporta el pago de SU hijo (pendiente → reportada)', async () => {
    await assertSucceeds(updateDoc(cuota('padre', '1'), { estado: 'reportada' }));
  });

  test('el padre NO puede marcarse al día, bajar el monto ni tocar la cuota de otro niño', async () => {
    await assertFails(updateDoc(cuota('padre', '1'), { estado: 'alDia' }));
    await assertFails(updateDoc(cuota('padre', '1'), { estado: 'reportada', monto: 1 }));
    await assertFails(updateDoc(cuota('padre', '2'), { estado: 'reportada' }));
    await assertFails(updateDoc(cuota('intruso', '1'), { estado: 'reportada' }));
  });

  test('el jugador viejo reporta la suya; el DT confirma y crea cuotas', async () => {
    await assertSucceeds(updateDoc(cuota('viejo', '1'), { estado: 'reportada' }));
    await assertSucceeds(updateDoc(cuota('dtA', '1'), { estado: 'alDia' }));
    await assertSucceeds(
      setDoc(doc(como('dtA'), `escuelas/${E1}/caja/2026-11/cuotas/1`), { jugadorId: 1, monto: 60000, estado: 'pendiente' }),
    );
    await assertFails(
      setDoc(doc(como('padre'), `escuelas/${E1}/caja/2026-11/cuotas/1`), { jugadorId: 1, monto: 0, estado: 'alDia' }),
    );
  });
});

describe('inscripciones', () => {
  const pedido = (uid, extra = {}) => ({
    escuelaId: E1,
    nombreEscuela: 'Escuela',
    solicitanteUid: uid,
    nombreSolicitante: uid,
    correoSolicitante: `${uid}@prueba.co`,
    nombreJugador: 'Hijo Nuevo',
    edad: 10,
    paraSiMismo: false,
    telefono: '3000000000',
    nota: '',
    estado: 'pendiente',
    jugadorId: null,
    creada: serverTimestamp(),
    ...extra,
  });

  test('un padre pide cupo en una escuela aprobada', async () => {
    await assertSucceeds(setDoc(doc(como('padre'), 'inscripciones', 'p1'), pedido('padre')));
    await assertSucceeds(
      setDoc(doc(como('estudiante'), 'inscripciones', 'e1'), pedido('estudiante', { paraSiMismo: true })),
    );
  });

  test('NO se puede pedir cupo ya aprobado, en escuela pendiente, ni a nombre de otro', async () => {
    const db = como('padre');
    await assertFails(setDoc(doc(db, 'inscripciones', 'p1'), pedido('padre', { estado: 'aprobada', jugadorId: 2 })));
    await assertFails(setDoc(doc(db, 'inscripciones', 'p1'), pedido('padre', { escuelaId: E2 })));
    await assertFails(setDoc(doc(db, 'inscripciones', 'p1'), pedido('intruso')));
    await assertFails(setDoc(doc(db, 'inscripciones', 'p1'), pedido('padre', { paraSiMismo: true })));
    await assertFails(setDoc(doc(como('profeB'), 'inscripciones', 'p1'), pedido('profeB')));
  });

  test('el padre NO se puede aprobar a sí mismo', async () => {
    await assertFails(updateDoc(doc(como('intruso'), 'inscripciones', 'pendiente1'), { estado: 'aprobada', jugadorId: 2 }));
  });

  test('el DT de la escuela acepta: ficha nueva + miembro + inscripción, en un solo paso', async () => {
    const db = como('dtA');
    const lote = writeBatch(db);
    lote.set(doc(db, `escuelas/${E1}/jugadores/3`), { id: 3, nombre: 'Nuevo', estadisticas: {} });
    lote.set(doc(db, `escuelas/${E1}/miembros/intruso`), { uid: 'intruso', jugadorIds: arrayUnion('3') }, { merge: true });
    lote.update(doc(db, 'inscripciones', 'pendiente1'), { estado: 'aprobada', jugadorId: 3 });
    await assertSucceeds(lote.commit());
    // Desde ahí, el padre lee los datos de la escuela.
    await assertSucceeds(getDocs(collection(como('intruso'), `escuelas/${E1}/jugadores`)));
  });

  test('el DT de OTRA escuela no puede aceptar ni ver pedidos ajenos', async () => {
    await assertFails(updateDoc(doc(como('dtOtro'), 'inscripciones', 'pendiente1'), { estado: 'aprobada', jugadorId: 1 }));
    await assertFails(getDocs(query(collection(como('dtOtro'), 'inscripciones'), where('escuelaId', '==', E1))));
    await assertFails(updateDoc(doc(como('dtA'), 'inscripciones', 'pendiente1'), { escuelaId: E3 }));
  });

  test('cada uno ve solo sus pedidos; el DT ve los pendientes de su escuela', async () => {
    await assertSucceeds(
      getDocs(query(collection(como('intruso'), 'inscripciones'), where('solicitanteUid', '==', 'intruso'))),
    );
    await assertFails(getDoc(doc(como('padre'), 'inscripciones', 'pendiente1')));
    await assertSucceeds(
      getDocs(
        query(collection(como('dtA'), 'inscripciones'), where('escuelaId', '==', E1), where('estado', '==', 'pendiente')),
      ),
    );
  });
});

describe('fotos', () => {
  test('se sube una foto propia; no una gigante ni a nombre de otro', async () => {
    const db = como('profeB');
    await assertSucceeds(setDoc(doc(db, 'fotos', 'f1'), { duenoUid: 'profeB', datos: 'x'.repeat(1000) }));
    await assertFails(setDoc(doc(db, 'fotos', 'f2'), { duenoUid: 'profeB', datos: 'x'.repeat(960000) }));
    await assertFails(setDoc(doc(db, 'fotos', 'f3'), { duenoUid: 'padre', datos: 'x' }));
    await assertFails(setDoc(doc(anonimo(), 'fotos', 'f4'), { duenoUid: 'nadie', datos: 'x' }));
  });
});
