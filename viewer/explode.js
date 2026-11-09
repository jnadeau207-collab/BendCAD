import * as THREE from 'three';

export function layout(parts, opts = {}) {
  const lanes = new Map();
  for (const p of parts) {
    const g = p.group || 'assembly';
    if (!lanes.has(g)) lanes.set(g, []);
    lanes.get(g).push(p);
  }
  const radius = p => Math.max(Math.abs(p.lo[0]), Math.abs(p.hi[0]), Math.abs(p.lo[1]), Math.abs(p.hi[1]));
  const len = p => p.hi[2] - p.lo[2];
  const span = Math.max(...parts.map(p => p.hi[2])) - Math.min(...parts.map(p => p.lo[2]));
  const gap = opts.gap ?? Math.max(6, 0.06 * span);
  const order = [...lanes.entries()].map(([name, ps]) => ({ name, ps, r: Math.max(...ps.map(radius)) }))
    .sort((a, b) => b.r - a.r);
  const out = new Map();
  let side = 0, prevR = 0;
  order.forEach((lane, k) => {
    const shift = k === 0 ? 0 : side + prevR + lane.r + gap * 3;
    if (k > 0) side = shift;
    prevR = lane.r;
    const anchor = lane.ps.reduce((a, b) => (len(b) > len(a) ? b : a));
    const ac = (anchor.lo[2] + anchor.hi[2]) / 2;
    out.set(anchor, { lateral: [shift, 0, 0], axial: 0, rank: 0 });
    const rest = lane.ps.filter(p => p !== anchor).map(p => ({ p, d: (p.lo[2] + p.hi[2]) / 2 - ac }));
    const front = rest.filter(x => x.d < 0).sort((a, b) => b.d - a.d);
    const rear = rest.filter(x => x.d >= 0).sort((a, b) => a.d - b.d);
    let cur = anchor.lo[2];
    front.forEach((x, i) => {
      const off = Math.min(0, cur - gap - x.p.hi[2]);
      out.set(x.p, { lateral: [shift, 0, 0], axial: off, rank: i + 1 });
      cur = x.p.lo[2] + off;
    });
    cur = anchor.hi[2];
    rear.forEach((x, i) => {
      const off = Math.max(0, cur + gap - x.p.lo[2]);
      out.set(x.p, { lateral: [shift, 0, 0], axial: off, rank: i + 1 });
      cur = x.p.hi[2] + off;
    });
  });
  const maxRank = Math.max(1, ...[...out.values()].map(v => v.rank));
  for (const v of out.values()) v.rank /= maxRank;
  return out;
}

const ease = t => (t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2);

export function offsetAt(e, t, target) {
  const s = 0.55;
  const lt = ease(Math.min(1, Math.max(0, (t * (1 + s) - s * (1 - e.rank)) / 1)));
  const lat = ease(Math.min(1, t * 2.2));
  return target.set(e.lateral[0] * lat, e.lateral[1] * lat, e.axial * lt);
}

export function leader(p, e, color) {
  const c = [(p.lo[0] + p.hi[0]) / 2, (p.lo[1] + p.hi[1]) / 2, (p.lo[2] + p.hi[2]) / 2];
  const b = new THREE.Vector3(...c).add(new THREE.Vector3(...e.lateral)), d = b.clone().setZ(b.z + e.axial);
  const pts = [b, d];
  const g = new THREE.BufferGeometry().setFromPoints(pts);
  const m = new THREE.LineDashedMaterial({ color, dashSize: 3, gapSize: 2.5, transparent: true, opacity: 0, depthWrite: false });
  const l = new THREE.LineSegments(g, m);
  l.computeLineDistances();
  l.userData.helper = true;
  l.userData.leader = true;
  return l;
}
