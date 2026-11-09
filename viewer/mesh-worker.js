const CREASE = Math.cos(38 * Math.PI / 180);
const EDGE = Math.cos(24 * Math.PI / 180);
const SOFT = Math.cos(70 * Math.PI / 180);

function parse(txt) {
  let nv = 0, nf = 0;
  for (let i = 0; i < txt.length;) {
    const j = txt.indexOf('\n', i);
    const e = j < 0 ? txt.length : j;
    if (txt.charCodeAt(i) === 118 && txt.charCodeAt(i + 1) === 32) nv++;
    else if (txt.charCodeAt(i) === 102 && txt.charCodeAt(i + 1) === 32) nf++;
    i = e + 1;
  }
  const v = new Float64Array(nv * 3), f = new Uint32Array(nf * 3), tf = new Int32Array(nf).fill(-1), kinds = [];
  let iv = 0, iff = 0, cur = -1;
  for (let i = 0; i < txt.length;) {
    const j = txt.indexOf('\n', i);
    const e = j < 0 ? txt.length : j;
    const c0 = txt.charCodeAt(i);
    if (txt.charCodeAt(i + 1) === 32) {
      if (c0 === 118) { const a = txt.slice(i + 2, e).trim().split(/\s+/); v[iv++] = +a[0]; v[iv++] = +a[1]; v[iv++] = +a[2]; }
      else if (c0 === 102) { const a = txt.slice(i + 2, e).trim().split(/\s+/); tf[iff / 3] = cur; for (let k = 0; k < 3; k++) f[iff++] = parseInt(a[k], 10) - 1; }
      else if (c0 === 103) { const a = txt.slice(i + 2, e).trim().split(/\s+/); cur = parseInt(a[0].slice(1), 10); kinds[cur] = a[1] || 'other'; }
    }
    i = e + 1;
  }
  return { v, f, tf, kinds };
}

function weld(v) {
  const n = v.length / 3, size = 1 << Math.ceil(Math.log2(n * 2 + 2));
  const table = new Int32Array(size).fill(-1), map = new Uint32Array(n), out = [];
  const q = 1e5;
  let m = 0;
  for (let i = 0; i < n; i++) {
    const x = Math.round(v[3 * i] * q), y = Math.round(v[3 * i + 1] * q), z = Math.round(v[3 * i + 2] * q);
    let h = (Math.imul(x, 73856093) ^ Math.imul(y, 19349663) ^ Math.imul(z, 83492791)) & (size - 1);
    for (;;) {
      const s = table[h];
      if (s < 0) { table[h] = m; map[i] = m; out.push(v[3 * i], v[3 * i + 1], v[3 * i + 2]); m++; break; }
      if (Math.round(out[3 * s] * q) === x && Math.round(out[3 * s + 1] * q) === y && Math.round(out[3 * s + 2] * q) === z) { map[i] = s; break; }
      h = (h + 1) & (size - 1);
    }
  }
  return { w: Float64Array.from(out), map };
}

function build(txt) {
  const { v: raw, f: rf, tf, kinds } = parse(txt);
  const grouped = kinds.length > 0;
  const { w: v, map } = weld(raw);
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
  for (let k = 0; k < nv; k++) {
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
  const edges = [];
  for (let t = 0; t < nt; t++) {
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
      if (count === 1 && !grouped && (ta[t] < 1e-9 || ta[other] < 1e-9 || fn[3 * t] * fn[3 * other] + fn[3 * t + 1] * fn[3 * other + 1] + fn[3 * t + 2] * fn[3 * other + 2] > EDGE)) continue;
      if (count > 1 && a > b) continue;
      edges.push(v[3 * a], v[3 * a + 1], v[3 * a + 2], v[3 * b], v[3 * b + 1], v[3 * b + 2]);
    }
  }
  return {
    pos: Float32Array.from(pos), nor: Float32Array.from(nor), fid: Float32Array.from(fid), idx, edges: Float32Array.from(edges),
    kinds, farea: Array.from(farea),
    tris: nt, volume: vol, area, centroid: vol ? [cx / vol, cy / vol, cz / vol] : [0, 0, 0], lo, hi
  };
}

self.onmessage = async e => {
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
