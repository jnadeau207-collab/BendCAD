const CREASE = Math.cos(38 * Math.PI / 180);
const EDGE = Math.cos(24 * Math.PI / 180);
const SOFT = Math.cos(70 * Math.PI / 180);
const TANGENT = Math.cos(3 * Math.PI / 180);

function parse(txt) {
  let nv = 0, nf = 0;
  for (let i = 0; i < txt.length;) {
    const j = txt.indexOf('\n', i);
    const e = j < 0 ? txt.length : j;
    if (txt.charCodeAt(i) === 118 && txt.charCodeAt(i + 1) === 32) nv++;
    else if (txt.charCodeAt(i) === 102 && txt.charCodeAt(i + 1) === 32) nf++;
    i = e + 1;
  }
  const v = new Float64Array(nv * 3), f = new Uint32Array(nf * 3), tf = new Int32Array(nf).fill(-1), kinds = [], lines = [];
  let iv = 0, iff = 0, cur = -1, gtag = 'f';
  for (let i = 0; i < txt.length;) {
    const j = txt.indexOf('\n', i);
    const e = j < 0 ? txt.length : j;
    const c0 = txt.charCodeAt(i);
    if (txt.charCodeAt(i + 1) === 32) {
      if (c0 === 118) { const a = txt.slice(i + 2, e).trim().split(/\s+/); v[iv++] = +a[0] + 0; v[iv++] = +a[1] + 0; v[iv++] = +a[2] + 0; }
      else if (c0 === 101) lines.push(Float64Array.from(txt.slice(i + 2, e).trim().split(/\s+/), x => +x + 0));
      else if (c0 === 102) { const a = txt.slice(i + 2, e).trim().split(/\s+/); tf[iff / 3] = cur; for (let k = 0; k < 3; k++) f[iff++] = parseInt(a[k], 10) - 1; }
      else if (c0 === 103) { const a = txt.slice(i + 2, e).trim().split(/\s+/); gtag = a[0][0]; cur = parseInt(a[0].slice(1), 10); kinds[cur] = a[1] || 'other'; }
    }
    i = e + 1;
  }
  return { v, f, tf, kinds, gtag, lines };
}

function weld(v) {
  const n = v.length / 3, size = 1 << Math.ceil(Math.log2(n * 2 + 2)), w = new Uint32Array(v.buffer);
  const table = new Int32Array(size).fill(-1), map = new Uint32Array(n), out = [];
  const hash = (a, b, c, d, e, g) => (Math.imul(a ^ b, 73856093) ^ Math.imul(c ^ d, 19349663) ^ Math.imul(e ^ g, 83492791)) & (size - 1);
  let m = 0;
  for (let i = 0; i < n; i++) {
    let h = hash(w[6 * i], w[6 * i + 1], w[6 * i + 2], w[6 * i + 3], w[6 * i + 4], w[6 * i + 5]);
    for (;;) {
      const s = table[h];
      if (s < 0) { table[h] = m; map[i] = m; out.push(v[3 * i], v[3 * i + 1], v[3 * i + 2]); m++; break; }
      if (out[3 * s] === v[3 * i] && out[3 * s + 1] === v[3 * i + 1] && out[3 * s + 2] === v[3 * i + 2]) { map[i] = s; break; }
      h = (h + 1) & (size - 1);
    }
  }
  const probe = new Float64Array(3), pw = new Uint32Array(probe.buffer);
  const find = (x, y, z) => {
    probe[0] = x; probe[1] = y; probe[2] = z;
    for (let h = hash(pw[0], pw[1], pw[2], pw[3], pw[4], pw[5]); ; h = (h + 1) & (size - 1)) {
      const s = table[h];
      if (s < 0) return -1;
      if (out[3 * s] === x && out[3 * s + 1] === y && out[3 * s + 2] === z) return s;
    }
  };
  return { w: Float64Array.from(out), map, find };
}

function solve(M, r, n) {
  const a = M.slice(), b = r.slice();
  for (let c = 0; c < n; c++) {
    let p = c;
    for (let i = c + 1; i < n; i++) if (Math.abs(a[i * n + c]) > Math.abs(a[p * n + c])) p = i;
    if (Math.abs(a[p * n + c]) < 1e-12) return null;
    if (p !== c) { for (let j = 0; j < n; j++) { const t = a[c * n + j]; a[c * n + j] = a[p * n + j]; a[p * n + j] = t; } const t = b[c]; b[c] = b[p]; b[p] = t; }
    for (let i = c + 1; i < n; i++) {
      const m = a[i * n + c] / a[c * n + c];
      for (let j = c; j < n; j++) a[i * n + j] -= m * a[c * n + j];
      b[i] -= m * b[c];
    }
  }
  const x = new Float64Array(n);
  for (let i = n - 1; i >= 0; i--) { let t = b[i]; for (let j = i + 1; j < n; j++) t -= a[i * n + j] * x[j]; x[i] = t / a[i * n + i]; }
  return x;
}

function fitNormal(v, k, nb, n0) {
  const px = v[3 * k], py = v[3 * k + 1], pz = v[3 * k + 2];
  const hx = Math.abs(n0[0]) < 0.9 ? 1 : 0, hy = hx ? 0 : 1;
  let t1x = n0[1] * 0 - n0[2] * hy, t1y = n0[2] * hx - n0[0] * 0, t1z = n0[0] * hy - n0[1] * hx;
  const tl = Math.hypot(t1x, t1y, t1z); t1x /= tl; t1y /= tl; t1z /= tl;
  const t2x = n0[1] * t1z - n0[2] * t1y, t2y = n0[2] * t1x - n0[0] * t1z, t2z = n0[0] * t1y - n0[1] * t1x;
  let sc = 0;
  for (const q of nb) sc = Math.max(sc, Math.hypot(v[3 * q] - px, v[3 * q + 1] - py, v[3 * q + 2] - pz));
  if (!(sc > 0)) return n0;
  const M5 = new Float64Array(25), r5 = new Float64Array(5), M2 = new Float64Array(4), r2 = new Float64Array(2);
  for (const q of nb) {
    const dx = (v[3 * q] - px) / sc, dy = (v[3 * q + 1] - py) / sc, dz = (v[3 * q + 2] - pz) / sc;
    const x = dx * t1x + dy * t1y + dz * t1z, y = dx * t2x + dy * t2y + dz * t2z, h = dx * n0[0] + dy * n0[1] + dz * n0[2];
    const w = 1 / (x * x + y * y + 1e-6), row = [x * x, x * y, y * y, x, y];
    for (let i = 0; i < 5; i++) { r5[i] += w * row[i] * h; for (let j = 0; j < 5; j++) M5[i * 5 + j] += w * row[i] * row[j]; }
    M2[0] += w * x * x; M2[1] += w * x * y; M2[2] += w * x * y; M2[3] += w * y * y; r2[0] += w * x * h; r2[1] += w * y * h;
  }
  const q5 = nb.length >= 5 ? solve(M5, r5, 5) : null;
  const de = q5 ? [q5[3], q5[4]] : solve(M2, r2, 2);
  if (!de) return n0;
  const nx = n0[0] - de[0] * t1x - de[1] * t2x, ny = n0[1] - de[0] * t1y - de[1] * t2y, nz = n0[2] - de[0] * t1z - de[1] * t2z;
  const l = Math.hypot(nx, ny, nz);
  return [nx / l, ny / l, nz / l];
}

function surfaceNormals(v, f, tf, kinds, fn, ca, start, inc, pos, nor, fid, idx, kStart) {
  const nf = kinds.length, pn = new Float64Array(nf * 3);
  for (let t = 0; t < tf.length; t++) {
    const g = tf[t]; if (g < 0 || kinds[g] !== 'plane') continue;
    const a = f[3 * t], b = f[3 * t + 1], c = f[3 * t + 2];
    const ux = v[3 * b] - v[3 * a], uy = v[3 * b + 1] - v[3 * a + 1], uz = v[3 * b + 2] - v[3 * a + 2];
    const wx = v[3 * c] - v[3 * a], wy = v[3 * c + 1] - v[3 * a + 1], wz = v[3 * c + 2] - v[3 * a + 2];
    pn[3 * g] += uy * wz - uz * wy; pn[3 * g + 1] += uz * wx - ux * wz; pn[3 * g + 2] += ux * wy - uy * wx;
  }
  for (let g = 0; g < nf; g++) { const l = Math.hypot(pn[3 * g], pn[3 * g + 1], pn[3 * g + 2]) || 1; pn[3 * g] /= l; pn[3 * g + 1] /= l; pn[3 * g + 2] /= l; }
  const nv = start.length - 1;
  const ring = (k, g, out) => {
    for (let s = start[k]; s < start[k + 1]; s++) {
      const t = (inc[s] / 3) | 0;
      if (tf[t] !== g) continue;
      for (let e = 0; e < 3; e++) { const q = f[3 * t + e]; if (q !== k) out.add(q); }
    }
  };
  for (let k = 0; k < nv; k++) {
    kStart[k] = pos.length / 3;
    const faces = new Map();
    for (let s = start[k]; s < start[k + 1]; s++) {
      const corner = inc[s], t = (corner / 3) | 0, g = tf[t];
      if (!faces.has(g)) faces.set(g, { n: [0, 0, 0], corners: [] });
      const e = faces.get(g), w = ca[corner];
      e.n[0] += w * fn[3 * t]; e.n[1] += w * fn[3 * t + 1]; e.n[2] += w * fn[3 * t + 2];
      e.corners.push(corner);
    }
    for (const [g, e] of faces) {
      const l = Math.hypot(e.n[0], e.n[1], e.n[2]) || 1;
      let n = [e.n[0] / l, e.n[1] / l, e.n[2] / l];
      if (g >= 0 && kinds[g] === 'plane') {
        const sg = Math.sign(pn[3 * g] * n[0] + pn[3 * g + 1] * n[1] + pn[3 * g + 2] * n[2]) || 1;
        n = [sg * pn[3 * g], sg * pn[3 * g + 1], sg * pn[3 * g + 2]];
      } else {
        const nb = new Set();
        ring(k, g, nb);
        if (nb.size < 8) for (const q of [...nb]) ring(q, g, nb);
        nb.delete(k);
        n = fitNormal(v, k, [...nb], n);
      }
      const id = pos.length / 3;
      pos.push(v[3 * k], v[3 * k + 1], v[3 * k + 2]); nor.push(n[0], n[1], n[2]); fid.push(g);
      for (const c of e.corners) idx[c] = id;
    }
  }
  kStart[nv] = pos.length / 3;
}

function build(txt) {
  const { v: raw, f: rf, tf, kinds, gtag, lines } = parse(txt);
  const grouped = kinds.length > 0;
  const { w: v, map, find } = weld(raw);
  const nt = rf.length / 3, nv = v.length / 3;
  const f = new Uint32Array(rf.length);
  for (let i = 0; i < rf.length; i++) f[i] = map[rf[i]];
  const fn = new Float32Array(nt * 3), ca = new Float32Array(nt * 3), ta = new Float64Array(nt);
  const farea = new Float64Array(Math.max(1, kinds.length));
  let vol = 0, area = 0, cx = 0, cy = 0, cz = 0;
  const lo = [Infinity, Infinity, Infinity], hi = [-Infinity, -Infinity, -Infinity];
  for (let i = 0; i < nv; i++) for (let k = 0; k < 3; k++) { const c = v[3 * i + k]; if (c < lo[k]) lo[k] = c; if (c > hi[k]) hi[k] = c; }
  const ang = (ax, ay, az, bx, by, bz) => {
    const d = ax * bx + ay * by + az * bz, l = Math.hypot(ax, ay, az) * Math.hypot(bx, by, bz) || 1;
    return Math.acos(Math.max(-1, Math.min(1, d / l)));
  };
  for (let t = 0; t < nt; t++) {
    const a = f[3 * t], b = f[3 * t + 1], c = f[3 * t + 2];
    const ax = v[3 * a], ay = v[3 * a + 1], az = v[3 * a + 2];
    const bx = v[3 * b], by = v[3 * b + 1], bz = v[3 * b + 2];
    const qx = v[3 * c], qy = v[3 * c + 1], qz = v[3 * c + 2];
    const ux = bx - ax, uy = by - ay, uz = bz - az, wx = qx - ax, wy = qy - ay, wz = qz - az;
    const nx = uy * wz - uz * wy, ny = uz * wx - ux * wz, nz = ux * wy - uy * wx;
    const l = Math.hypot(nx, ny, nz);
    area += l / 2; ta[t] = l / 2; if (grouped && tf[t] >= 0) farea[tf[t]] += l / 2;
    const dv = (ax * (by * qz - bz * qy) - ay * (bx * qz - bz * qx) + az * (bx * qy - by * qx)) / 6;
    vol += dv; cx += dv * (ax + bx + qx) / 4; cy += dv * (ay + by + qy) / 4; cz += dv * (az + bz + qz) / 4;
    if (l > 0) { fn[3 * t] = nx / l; fn[3 * t + 1] = ny / l; fn[3 * t + 2] = nz / l; }
    ca[3 * t] = ang(ux, uy, uz, wx, wy, wz);
    ca[3 * t + 1] = ang(qx - bx, qy - by, qz - bz, ax - bx, ay - by, az - bz);
    ca[3 * t + 2] = ang(ax - qx, ay - qy, az - qz, bx - qx, by - qy, bz - qz);
  }
  const start = new Uint32Array(nv + 1);
  for (let i = 0; i < f.length; i++) start[f[i] + 1]++;
  for (let i = 0; i < nv; i++) start[i + 1] += start[i];
  const fill = start.slice(0, nv), inc = new Uint32Array(f.length);
  for (let i = 0; i < f.length; i++) inc[fill[f[i]]++] = i;
  const pos = [], nor = [], fid = [], idx = new Uint32Array(f.length);
  const kStart = new Uint32Array(nv + 1);
  if (grouped) surfaceNormals(v, f, tf, kinds, fn, ca, start, inc, pos, nor, fid, idx, kStart);
  for (let k = 0; k < (grouped ? 0 : nv); k++) {
    const s0 = start[k], s1 = start[k + 1];
    const cl = [];
    for (let s = s0; s < s1; s++) {
      const corner = inc[s], t = (corner / 3) | 0;
      let sx = 0, sy = 0, sz = 0;
      for (let r = s0; r < s1; r++) {
        const q = (inc[r] / 3) | 0;
        if (grouped && tf[q] !== tf[t]) continue;
        if (fn[3 * q] * fn[3 * t] + fn[3 * q + 1] * fn[3 * t + 1] + fn[3 * q + 2] * fn[3 * t + 2] < (grouped ? SOFT : CREASE)) continue;
        const wg = grouped ? ta[q] : ca[inc[r]];
        sx += wg * fn[3 * q]; sy += wg * fn[3 * q + 1]; sz += wg * fn[3 * q + 2];
      }
      const l = Math.hypot(sx, sy, sz) || 1;
      sx /= l; sy /= l; sz /= l;
      let hit = -1;
      for (let j = 0; j < cl.length; j++) {
        const o = cl[j];
        if (fid[o] === tf[t] && nor[3 * o] * sx + nor[3 * o + 1] * sy + nor[3 * o + 2] * sz > 0.99995) { hit = o; break; }
      }
      if (hit < 0) {
        hit = pos.length / 3;
        pos.push(v[3 * k], v[3 * k + 1], v[3 * k + 2]); nor.push(sx, sy, sz); fid.push(tf[t]); cl.push(hit);
      }
      idx[corner] = hit;
    }
  }
  const corner = (t, k) => (f[3 * t] === k ? 3 * t : f[3 * t + 1] === k ? 3 * t + 1 : 3 * t + 2);
  const smooth = (t, o, k) => {
    const i = idx[corner(t, k)], j = idx[corner(o, k)];
    return nor[3 * i] * nor[3 * j] + nor[3 * i + 1] * nor[3 * j + 1] + nor[3 * i + 2] * nor[3 * j + 2] > TANGENT;
  };
  const edges = [];
  const ents = k => { const m = new Map(); if (k >= 0) for (let i = kStart[k]; i < kStart[k + 1]; i++) m.set(fid[i], i); return m; };
  const bend = (m, g, h) => { const i = m.get(g), j = m.get(h); return nor[3 * i] * nor[3 * j] + nor[3 * i + 1] * nor[3 * j + 1] + nor[3 * i + 2] * nor[3 * j + 2] < TANGENT; };
  for (const L of grouped ? lines : []) {
    const n = L.length / 3, E = [];
    for (let i = 0; i < n; i++) E.push(ents(find(L[3 * i], L[3 * i + 1], L[3 * i + 2])));
    for (let i = 0; i + 1 < n; i++) {
      const common = [...E[i].keys()].filter(g => E[i + 1].has(g));
      let draw = common.length < 2;
      for (let x = 0; x < common.length && !draw; x++) for (let y = x + 1; y < common.length && !draw; y++)
        draw = bend(E[i], common[x], common[y]) || bend(E[i + 1], common[x], common[y]);
      if (draw) edges.push(L[3 * i], L[3 * i + 1], L[3 * i + 2], L[3 * i + 3], L[3 * i + 4], L[3 * i + 5]);
    }
  }
  for (let t = 0; t < (grouped && lines.length ? 0 : nt); t++) {
    for (let e = 0; e < 3; e++) {
      const a = f[3 * t + e], b = f[3 * t + (e + 1) % 3];
      let other = -1, count = 0;
      for (let s = start[a]; s < start[a + 1]; s++) {
        const q = (inc[s] / 3) | 0;
        if (q === t) continue;
        if (f[3 * q] === b || f[3 * q + 1] === b || f[3 * q + 2] === b) { other = q; count++; }
      }
      if (count === 1 && other < t) continue;
      if (count === 1 && grouped && tf[t] === tf[other]) continue;
      if (count === 1 && grouped && smooth(t, other, a) && smooth(t, other, b)) continue;
      if (count === 1 && !grouped && (ta[t] < 1e-9 || ta[other] < 1e-9 || fn[3 * t] * fn[3 * other] + fn[3 * t + 1] * fn[3 * other + 1] + fn[3 * t + 2] * fn[3 * other + 2] > EDGE)) continue;
      if (count > 1 && a > b) continue;
      edges.push(v[3 * a], v[3 * a + 1], v[3 * a + 2], v[3 * b], v[3 * b + 1], v[3 * b + 2]);
    }
  }
  return {
    pos: Float32Array.from(pos), nor: Float32Array.from(nor), fid: Float32Array.from(fid), idx, edges: Float32Array.from(edges),
    kinds, gtag, farea: Array.from(farea),
    tris: nt, volume: vol, area, centroid: vol ? [cx / vol, cy / vol, cz / vol] : [0, 0, 0], lo, hi
  };
}

export { build };

if (typeof self !== 'undefined') self.onmessage = async e => {
  const { id, url } = e.data;
  try {
    const r = await fetch(url);
    if (!r.ok) throw new Error(url + ' ' + r.status);
    const m = build(await r.text());
    self.postMessage({ id, m }, [m.pos.buffer, m.nor.buffer, m.fid.buffer, m.idx.buffer, m.edges.buffer]);
  } catch (err) {
    self.postMessage({ id, error: String(err) });
  }
};
