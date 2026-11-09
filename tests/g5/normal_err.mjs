import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const { build } = await import(pathToFileURL(path.join(ROOT, 'viewer/mesh-worker.js')).href);
const [obj, axisX = '0', axisY = '0'] = process.argv.slice(2);
const t0 = Date.now();
const m = build(fs.readFileSync(obj, 'utf8'));
const ms = Date.now() - t0;
const rr = {};
for (let i = 0; i < m.fid.length; i++) { const g = m.fid[i], r = Math.hypot(m.pos[3 * i] - +axisX, m.pos[3 * i + 1] - +axisY); const o = (rr[g] ||= [Infinity, -Infinity]); o[0] = Math.min(o[0], r); o[1] = Math.max(o[1], r); }
const coax = g => rr[g][1] - rr[g][0] < 1e-6 * Math.max(1, rr[g][1]);
const by = {};
for (let i = 0; i < m.fid.length; i++) {
  const g = m.fid[i], k = m.kinds[g];
  if (k !== 'cylinder' || !coax(g)) continue;
  const x = m.pos[3 * i] - +axisX, y = m.pos[3 * i + 1] - +axisY, nx = m.nor[3 * i], ny = m.nor[3 * i + 1], nz = m.nor[3 * i + 2];
  let e;
  if (k === 'cylinder') { const r = Math.hypot(x, y); e = Math.acos(Math.min(1, Math.abs((x * nx + y * ny) / r))); }
  else if (k === 'plane') e = null;
  else continue;
  if (e === null) continue;
  (by[k] ||= []).push(e * 180 / Math.PI);
}
const q = (a, p) => a.slice().sort((u, w) => u - w)[Math.min(a.length - 1, Math.floor(p * a.length))];
for (const [k, a] of Object.entries(by)) console.log(k, 'n', a.length, 'median', q(a, 0.5).toFixed(4), 'p99', q(a, 0.99).toFixed(4), 'max', Math.max(...a).toFixed(4), 'deg');
console.log('build ms', ms, 'verts', m.pos.length / 3);
