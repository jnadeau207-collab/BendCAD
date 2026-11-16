import * as THREE from 'three';
import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/addons/postprocessing/RenderPass.js';
import { GTAOPass } from 'three/addons/postprocessing/GTAOPass.js';
import { OutlinePass } from 'three/addons/postprocessing/OutlinePass.js';
import { OutputPass } from 'three/addons/postprocessing/OutputPass.js';
import { Reflector } from 'three/addons/objects/Reflector.js';
import { SCHEMES, FINISHES, environment, background, partMaterial, grid, ContactShadow, hatchTexture, mirrorFloor } from './studio.js';
import { layout, offsetAt, leader } from './explode.js';

const $ = id => document.getElementById(id);
const cv = $('gl');
const Z = new THREE.Vector3(0, 0, 1);

const renderer = new THREE.WebGLRenderer({ canvas: cv, antialias: false, stencil: true, powerPreference: 'high-performance', preserveDrawingBuffer: true });
renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
renderer.toneMapping = THREE.NeutralToneMapping;
renderer.toneMappingExposure = 1.0;
renderer.localClippingEnabled = true;

const scene = new THREE.Scene();
const persp = new THREE.PerspectiveCamera(28, 1, 1, 20000);
const ortho = new THREE.OrthographicCamera(-1, 1, 1, -1, -20000, 20000);
persp.up.copy(Z); ortho.up.copy(Z);
let camera = persp;

const st = {
  scheme: 'night', mode: 'edges', selMode: 'part', face: null, hface: null, meas: null, parts: [], sel: new Set(), hov: null, target: new THREE.Vector3(),
  exp: 0, expT: 0, run: false, rps: 3, ang: 0, sec: false, secAx: 'y', secFlip: false, secT: 0.5, caps: true, labels: true,
  dirty: true, shadowDirty: true, iso: null, box: new THREE.Box3(), anim: null, last: 0
};

const clipPlane = new THREE.Plane(new THREE.Vector3(0, -1, 0), 0);
const planes = [];
const hatch = hatchTexture();

function makeComposer(w, h) {
  const rt = new THREE.WebGLRenderTarget(w, h, { type: THREE.HalfFloatType, samples: 4, stencilBuffer: true });
  const c = new EffectComposer(renderer, rt);
  return c;
}
let composer = makeComposer(2, 2);
const renderPass = new RenderPass(scene, camera);
const gtao = new GTAOPass(scene, camera, 2, 2);
gtao.output = GTAOPass.OUTPUT.Default;
gtao.blendIntensity = 0.82;
const gtaoRender = gtao.render.bind(gtao);
gtao.render = (...a) => {
  const hidden = [];
  scene.traverse(o => {
    if (o.visible && (o.userData.helper || o.userData.stencil || o.userData.cap || o.isLineSegments || (o.isMesh && o.material.transparent))) { hidden.push(o); o.visible = false; }
  });
  gtao.normalMaterial.clippingPlanes = planes;
  const bg = scene.background; scene.background = null;
  gtaoRender(...a);
  scene.background = bg;
  hidden.forEach(o => { o.visible = true; });
};
const outHov = new OutlinePass(new THREE.Vector2(2, 2), scene, camera);
const outSel = new OutlinePass(new THREE.Vector2(2, 2), scene, camera);
for (const [o, k] of [[outHov, 0.55], [outSel, 1]]) {
  o.edgeStrength = 3.2 * k; o.edgeGlow = 0; o.edgeThickness = 1; o.pulsePeriod = 0;
}
const outRender = o => {
  const r = o.render.bind(o);
  o.render = (...a) => {
    if (!o.selectedObjects.length) { o.enabled = true; return r(...a); }
    const hidden = [];
    scene.traverse(x => { if (x.visible && (x.userData.helper || x.userData.stencil || x.userData.cap || x.isLineSegments)) { hidden.push(x); x.visible = false; } });
    const bg = scene.background; scene.background = null;
    r(...a);
    scene.background = bg;
    hidden.forEach(x => { x.visible = true; });
  };
};
outRender(outHov); outRender(outSel);
const output = new OutputPass();
function assemble() {
  composer.addPass(renderPass); composer.addPass(gtao); composer.addPass(outHov); composer.addPass(outSel); composer.addPass(output);
}
assemble();

const shadow = new ContactShadow(renderer, 1024);
scene.add(shadow.plane);
let gridMesh = grid(st.scheme);
scene.add(gridMesh);
const floor = mirrorFloor(renderer, scene, Reflector);
scene.add(floor);

const pickRT = new THREE.WebGLRenderTarget(1, 1, { type: THREE.FloatType });
const pickBuf = new Float32Array(4);
function pickMaterial(id) {
  return new THREE.ShaderMaterial({
    uniforms: { pid: { value: id } }, side: THREE.DoubleSide, clipping: true,
    vertexShader: `#include <clipping_planes_pars_vertex>
      attribute float fid; varying vec3 wp; varying float vf;
      void main() { vf = fid; vec4 w = modelMatrix * vec4(position, 1.0); wp = w.xyz; vec4 mvPosition = viewMatrix * w; gl_Position = projectionMatrix * mvPosition;
      #include <clipping_planes_vertex>
      }`,
    fragmentShader: `#include <clipping_planes_pars_fragment>
      uniform float pid; varying vec3 wp; varying float vf;
      void main() {
      #include <clipping_planes_fragment>
      gl_FragColor = vec4(pid * 65536.0 + vf + 1.0, wp); }`
  });
}

function setScheme(s) {
  st.scheme = s;
  document.body.dataset.theme = s;
  const S = SCHEMES[s];
  if (scene.environment) scene.environment.dispose();
  scene.environment = environment(renderer, s);
  if (scene.background) scene.background.dispose();
  scene.background = background(s);
  scene.remove(gridMesh); gridMesh = grid(s); scene.add(gridMesh); placeGrid();
  const acc = new THREE.Color(s === 'night' ? '#6EE7FF' : '#0E7490');
  outSel.visibleEdgeColor.copy(acc); outSel.hiddenEdgeColor.copy(acc).multiplyScalar(0.35);
  outHov.visibleEdgeColor.set(s === 'night' ? '#C9F6FF' : '#22A3C4'); outHov.hiddenEdgeColor.set(0x000000);
  for (const p of st.parts) {
    p.edges.material.color.set(S.edge);
    p.edges.material.opacity = s === 'night' ? 0.62 : 0.5;
    p.leader.material.color.set(s === 'night' ? '#8FA6C4' : '#5E6B7D');
  }
  if (typeof cube !== 'undefined') cube.paint();
  st.shadowDirty = true; dirty();
}

function dirty() { st.dirty = true; }

function resize() {
  const w = cv.clientWidth, h = cv.clientHeight, pr = renderer.getPixelRatio();
  renderer.setSize(w, h, false);
  composer.setSize(w, h);
  composer.setPixelRatio(pr);
  gtao.setSize(w * pr, h * pr);
  persp.aspect = w / h; persp.updateProjectionMatrix();
  updateOrtho();
  dirty();
}

function viewDist() { return camera.position.distanceTo(st.target); }
function updateOrtho() {
  const d = persp.position.distanceTo(st.target), hh = d * Math.tan(THREE.MathUtils.degToRad(persp.fov / 2)), a = cv.clientWidth / Math.max(1, cv.clientHeight);
  ortho.left = -hh * a; ortho.right = hh * a; ortho.top = hh; ortho.bottom = -hh;
  ortho.position.copy(persp.position); ortho.quaternion.copy(persp.quaternion);
  ortho.updateProjectionMatrix(); ortho.updateMatrixWorld();
}
function syncCam() {
  persp.lookAt(st.target); persp.updateMatrixWorld();
  const r = st.radius || 300, d = viewDist();
  persp.near = Math.max(0.5, d - r * 4); persp.far = d + r * 6; persp.updateProjectionMatrix();
  updateOrtho();
  dirty();
}
function useCamera(c) {
  camera = c;
  renderPass.camera = c; gtao.camera = c; outHov.renderCamera = c; outSel.renderCamera = c;
  $('t-proj').textContent = c === persp ? 'Persp' : 'Ortho';
  $('b-proj').classList.toggle('on', c === ortho);
  syncCam();
}

function ndc(x, y) {
  const r = cv.getBoundingClientRect();
  return new THREE.Vector2(((x - r.left) / r.width) * 2 - 1, -((y - r.top) / r.height) * 2 + 1);
}

function pick(x, y) {
  const r = cv.getBoundingClientRect(), px = x - r.left, py = y - r.top;
  if (px < 0 || py < 0 || px >= r.width || py >= r.height) return null;
  const swaps = [], hidden = [];
  scene.traverse(o => {
    if (!o.visible) return;
    if (o.userData.part) { swaps.push([o, o.material]); o.material = o.userData.pickMat; }
    else if (o.isMesh || o.isLine) { hidden.push(o); o.visible = false; }
  });
  const bg = scene.background; scene.background = null;
  const prevT = renderer.getRenderTarget(), prevA = renderer.getClearAlpha(), prevC = renderer.getClearColor(new THREE.Color());
  const tm = renderer.toneMapping; renderer.toneMapping = THREE.NoToneMapping;
  camera.setViewOffset(r.width, r.height, px, py, 1, 1);
  renderer.setRenderTarget(pickRT); renderer.setClearColor(0x000000, 0); renderer.clear(); renderer.render(scene, camera);
  renderer.readRenderTargetPixels(pickRT, 0, 0, 1, 1, pickBuf);
  camera.clearViewOffset();
  renderer.setRenderTarget(prevT); renderer.setClearColor(prevC, prevA); renderer.toneMapping = tm;
  scene.background = bg;
  swaps.forEach(([o, m]) => { o.material = m; });
  hidden.forEach(o => { o.visible = true; });
  const code = Math.round(pickBuf[0]), id = Math.floor(code / 65536) - 1, face = (code % 65536) - 1;
  if (id < 0 || !st.parts[id]) return null;
  return { part: st.parts[id], face, point: new THREE.Vector3(pickBuf[1], pickBuf[2], pickBuf[3]) };
}

function orbit(dx, dy, pivot) {
  const fwd = st.target.clone().sub(persp.position).normalize();
  const right = fwd.clone().cross(Z).normalize();
  const qy = new THREE.Quaternion().setFromAxisAngle(Z, -dx * 0.006);
  const qp = new THREE.Quaternion().setFromAxisAngle(right, -dy * 0.006);
  const turn = q => {
    const off = persp.position.clone().sub(pivot).applyQuaternion(q), tOff = st.target.clone().sub(pivot).applyQuaternion(q);
    return [pivot.clone().add(off), pivot.clone().add(tOff)];
  };
  let [p1, t1] = turn(qy.clone().multiply(qp));
  if (Math.abs(t1.clone().sub(p1).normalize().z) > 0.998) [p1, t1] = turn(qy);
  persp.position.copy(p1); st.target.copy(t1);
  syncCam();
}
function pan(dx, dy) {
  const h = cv.clientHeight, d = viewDist(), wpp = 2 * d * Math.tan(THREE.MathUtils.degToRad(persp.fov / 2)) / h;
  const fwd = st.target.clone().sub(persp.position).normalize(), right = fwd.clone().cross(Z).normalize(), up = right.clone().cross(fwd).normalize();
  const m = right.multiplyScalar(-dx * wpp).add(up.multiplyScalar(dy * wpp));
  persp.position.add(m); st.target.add(m);
  syncCam();
}
function zoomAt(f, point) {
  const p = point || st.target;
  const nd = viewDist() * f;
  if (nd < 2 || nd > 8000) return;
  persp.position.sub(p).multiplyScalar(f).add(p);
  st.target.sub(p).multiplyScalar(f).add(p);
  syncCam();
}

function animateTo(pos, tgt, ms = 450) {
  st.anim = { p0: persp.position.clone(), t0: st.target.clone(), p1: pos, t1: tgt, s: performance.now(), ms };
  dirty();
}

function visibleBox(only) {
  const b = new THREE.Box3();
  for (const p of st.parts) {
    if (only && !only.includes(p)) continue;
    if (!p.root.visible) continue;
    p.mesh.geometry.computeBoundingBox();
    b.union(p.mesh.geometry.boundingBox.clone().applyMatrix4(p.mesh.matrixWorld));
  }
  return b;
}
function fit(only, dir) {
  scene.updateMatrixWorld();
  const b = visibleBox(only);
  if (b.isEmpty()) return;
  const c = b.getCenter(new THREE.Vector3()), r = b.getSize(new THREE.Vector3()).length() / 2;
  const d = r / Math.sin(THREE.MathUtils.degToRad(persp.fov / 2)) * 1.08;
  const v = dir ? dir.clone().normalize() : persp.position.clone().sub(st.target).normalize();
  animateTo(c.clone().add(v.multiplyScalar(d)), c);
}
const VIEWS = {
  iso: [1, -1.1, 0.75], front: [0, -1, 0.0001], back: [0, 1, 0.0001], left: [-1, 0, 0.0001], right: [1, 0, 0.0001], top: [0.0001, -0.0001, 1], bottom: [0.0001, -0.0001, -1]
};
function view(name) { fit(null, new THREE.Vector3(...VIEWS[name])); }

function setMode(m) {
  st.mode = m;
  document.querySelectorAll('#modes button').forEach(b => b.classList.toggle('on', b.dataset.mode === m));
  applyLook();
}
function applyLook() {
  const S = SCHEMES[st.scheme], acc = new THREE.Color(st.scheme === 'night' ? '#6EE7FF' : '#0E7490'), red = new THREE.Color('#FF3B3B');
  const clash = live.on && live.near ? new Set(live.near.rows.filter(r => r.kind === 'interference' || r.kind === 'inside').map(r => r.node)) : new Set();
  for (const p of st.parts) {
    const m = p.mat, sel = st.sel.has(p), hov = st.hov === p, fm = st.selMode === 'face';
    const ghost = st.mode === 'xray' && !sel;
    if (m.transparent !== ghost) { m.transparent = ghost; m.depthWrite = !ghost; m.needsUpdate = true; }
    m.opacity = ghost ? 0.3 : 1;
    if (clash.has(p.node) && !sel) m.emissive.copy(red).multiplyScalar(hov ? 0.5 : 0.38);
    else m.emissive.copy(acc).multiplyScalar(fm ? 0 : sel ? 0.18 : hov ? 0.08 : 0);
    m.userData.u.facc.value.copy(acc);
    m.userData.u.sf.value = st.face && st.face.part === p ? st.face.face : -9;
    m.userData.u.hf.value = fm && st.hface && st.hface.part === p ? st.hface.face : -9;
    p.edges.visible = st.mode !== 'shaded' || sel;
    p.edges.material.opacity = ghost ? 0.4 : (st.scheme === 'night' ? 0.62 : 0.5);
    p.edges.material.color.copy(sel ? acc : new THREE.Color(S.edge));
  }
  outSel.selectedObjects = [...st.sel].filter(p => p.root.visible).map(p => p.mesh);
  outHov.selectedObjects = st.selMode === 'part' && st.hov && !st.sel.has(st.hov) && st.hov.root.visible ? [st.hov.mesh] : [];
  dirty();
}

function setSelMode(m) {
  st.selMode = m;
  document.querySelectorAll('[data-sm]').forEach(b => b.classList.toggle('on', b.dataset.sm === m));
  st.face = null; st.hface = null;
  props(); applyLook();
}
function select(p, add, face) {
  st.face = st.selMode === 'face' && p && face >= 0 ? { part: p, face } : null;
  if (!add || st.face) st.sel.clear();
  if (p) { if (add && st.sel.has(p)) st.sel.delete(p); else st.sel.add(p); }
  document.querySelectorAll('#tree .row').forEach(r => r.classList.toggle('sel', st.sel.has(st.parts[+r.dataset.i])));
  props();
  applyLook();
  const one = st.sel.size === 1 ? [...st.sel][0] : null;
  if (live.on && one && one.node !== live.node) liveChecks(one.node);
}
function hover(p, face) {
  const hf = p && face >= 0 ? { part: p, face } : null;
  if (st.hov === p && (st.hface && st.hface.face) === (hf && hf.face)) return;
  st.hov = p; st.hface = hf;
  const tip = $('tip');
  tip.hidden = !p;
  if (p) tip.innerHTML = hf && st.selMode === 'face' ? `${p.label}<span>${p.info.gtag}${hf.face} · ${p.info.kinds[hf.face] || 'untagged'}</span>` : `${p.label}<span>${p.grade || ''}</span>`;
  document.body.classList.toggle('point', !!p);
  document.querySelectorAll('#tree .row').forEach(r => r.classList.toggle('hov', st.parts[+r.dataset.i] === p));
  applyLook();
}

function setVisible(p, v) {
  p.root.visible = v; p.leader.visible = v;
  const row = document.querySelector(`#tree .row[data-i="${p.i}"]`);
  if (row) row.classList.toggle('off', !v);
  if (!v) st.sel.delete(p);
  st.shadowDirty = true; applyLook(); props();
}
function isolate(ps) {
  st.iso = ps;
  for (const p of st.parts) setVisible(p, !ps || ps.includes(p));
  fit(ps || null);
}

const fmt = (x, d = 1) => x.toLocaleString(undefined, { minimumFractionDigits: d, maximumFractionDigits: d });
function props() {
  const el = $('props');
  const ps = [...st.sel];
  if (!ps.length) { el.hidden = true; return; }
  el.hidden = false;
  if (ps.length > 1) {
    const v = ps.reduce((s, p) => s + p.info.volume, 0), m = ps.reduce((s, p) => s + p.info.volume * (p.density || 0), 0);
    el.innerHTML = `<h3>${ps.length} parts</h3><div class="sub">${ps.map(p => p.label).join(', ')}</div>
      <dl><dt>Volume</dt><dd>${fmt(v / 1000, 2)} cm³</dd><dt>Mass</dt><dd>${fmt(m * 1e-6, 1)} g</dd></dl>
      <div class="acts"><button data-pa="iso">Isolate</button><button data-pa="hide">Hide</button><button data-pa="focus">Focus</button></div>`;
    return;
  }
  if (live.on && ps[0].node != null) return liveProps(el, ps[0]);
  const p = ps[0], i = p.info, f = FINISHES[p.finish] || FINISHES.part;
  const s = [i.hi[0] - i.lo[0], i.hi[1] - i.lo[1], i.hi[2] - i.lo[2]];
  el.innerHTML = `<h3>${p.label}</h3><div class="sub">${p.group ? p.group[0].toUpperCase() + p.group.slice(1) + ' · ' : ''}kernel node ${p.node}</div>
    <dl>
      <dt>Material</dt><dd>${p.grade || '—'}</dd>
      <dt>Finish</dt><dd class="fin"><i style="background:${f.color}"></i>${f.label}</dd>
      ${p.density ? `<dt>Density</dt><dd>${fmt(p.density, 0)} kg/m³</dd>` : ''}
      <dt>Volume</dt><dd>${fmt(i.volume / 1000, 3)} cm³</dd>
      ${p.density ? `<dt>Mass</dt><dd>${fmt(i.volume * p.density * 1e-6, 2)} g</dd>` : ''}
      <dt>Surface</dt><dd>${fmt(i.area / 100, 2)} cm²</dd>
      <dt>Size X·Y·Z</dt><dd>${s.map(x => fmt(x, 1)).join(' · ')} mm</dd>
      <dt>Centroid</dt><dd>${i.centroid.map(x => fmt(x, 1)).join(', ')}</dd>
      <dt>Triangles</dt><dd>${i.tris.toLocaleString()}</dd>
      ${p.rotor ? `<dt>Spin ratio</dt><dd>${fmt(+p.rotor, 4)}</dd>` : ''}
      <dt>${i.gtag === 'p' ? 'Revolved pieces' : 'B-rep faces'}</dt><dd>${i.kinds.length ? i.kinds.filter(k => k !== 'axis').length : 'not tagged'}</dd>
    </dl>
    ${st.face && st.face.part === p ? `<div class="face"><h4>${i.gtag === 'p' ? 'Revolved piece p' : 'B-rep face f'}${st.face.face}</h4><dl>
      <dt>Surface</dt><dd>${i.kinds[st.face.face] || 'other'}</dd>
      <dt>Area</dt><dd>${fmt(i.farea[st.face.face] || 0, 2)} mm²</dd>
      <dt>Same-type faces</dt><dd>${i.kinds.filter(k => k === i.kinds[st.face.face]).length}</dd></dl></div>` : ''}
    <div class="acts"><button data-pa="iso">Isolate</button><button data-pa="hide">Hide</button><button data-pa="focus">Focus</button></div>`;
}
const mid = v => (v[0] + v[1]) / 2;
const pv = t => `<em class="pv ${t}">${t}</em>`;
function liveProps(el, p) {
  const n = live.doc.nodes.find(x => x.id === p.node) || {}, k = live.checks && live.checks.node === p.node ? live.checks.mass : null, i = p.info;
  const b = n.bbox, mat = k && k.material, wait = '<dd class="dim">…</dd><dd></dd>';
  const row = (t, v, tag) => `<dt>${t}</dt><dd>${v}</dd><dd>${tag ? pv(tag) : ''}</dd>`;
  el.innerHTML = `<h3>${esc(p.label)}</h3><div class="sub">kernel node ${p.node} · ${esc(n.op || '')}</div>
    <dl class="lv">
      ${k ? row('Material', mat ? esc(mat.grade) : `none on node ${p.node}`, mat ? 'declared' : '') : `<dt>Material</dt>${wait}`}
      ${mat ? row('Density', `${fmt(mat.density, 0)} kg/m³`, 'declared') : ''}
      ${n.volume ? row('Volume', `${fmt(mid(n.volume) / 1000, 3)} cm³`, 'certified') : row('Volume', `${fmt(i.volume / 1000, 3)} cm³`, 'mesh')}
      ${mat ? row('Mass', `${fmt(mid(mat.mass) * 1000, 2)} g`, mat.status) : ''}
      ${n.area ? row('Surface', `${fmt(mid(n.area) / 100, 2)} cm²`, 'certified') : ''}
      ${b ? row('Size', `${[b[1] - b[0], b[3] - b[2], b[5] - b[4]].map(x => fmt(x, 2)).join(' × ')} mm`, 'enclosing') : ''}
      ${k ? k.centroid ? row('Centroid', k.centroid.map(c => fmt(mid(c), 2)).join(', '), k.cstatus) : row('Centroid', 'not analyzed', '') : `<dt>Centroid</dt>${wait}`}
      ${row('Mesh', `${i.tris.toLocaleString()} tris · ${i.kinds.filter(x => x !== 'axis').length} faces`, 'display')}
    </dl>
    <div class="acts"><button data-pa="iso">Isolate</button><button data-pa="hide">Hide</button><button data-pa="focus">Focus</button></div>`;
}
$('props').onclick = e => {
  const a = e.target.closest('button')?.dataset.pa, ps = [...st.sel];
  if (!a) return;
  if (a === 'iso') isolate(st.iso && st.iso.length === ps.length && ps.every(p => st.iso.includes(p)) ? null : ps);
  if (a === 'hide') ps.forEach(p => setVisible(p, false));
  if (a === 'focus') fit(ps);
};

function faceCut() {
  const ax = { x: 0, y: 1, z: 2 }[st.secAx];
  st.secFlip = persp.position.getComponent(ax) < st.box.getCenter(new THREE.Vector3()).getComponent(ax);
  $('b-flip').classList.toggle('on', st.secFlip);
}
function setSection(on) {
  st.sec = on;
  if (on) faceCut();
  planes.length = 0;
  if (on) planes.push(clipPlane);
  $('b-sec').classList.toggle('on', on);
  $('c-sec').hidden = !on;
  updateSection();
}
function updateSection() {
  const ax = { x: 0, y: 1, z: 2 }[st.secAx];
  const lo = st.box.min.getComponent(ax), hi = st.box.max.getComponent(ax), v = lo + (hi - lo) * st.secT;
  const n = new THREE.Vector3().setComponent(ax, st.secFlip ? 1 : -1);
  clipPlane.normal.copy(n); clipPlane.constant = st.secFlip ? -v : v;
  $('o-sec').textContent = `${st.secAx.toUpperCase()} ${fmt(v, 1)} mm`;
  const show = st.sec && st.caps;
  const q = new THREE.Quaternion().setFromUnitVectors(Z, n.clone().negate());
  const c = st.box.getCenter(new THREE.Vector3()).setComponent(ax, v);
  for (const p of st.parts) {
    p.stB.visible = p.stF.visible = show;
    p.cap.visible = show && p.root.visible;
    p.cap.position.copy(c); p.cap.quaternion.copy(q);
  }
  for (const p of st.parts) for (const m of [p.mat, p.edges.material, p.stB.material, p.stF.material, p.mesh.userData.pickMat]) {
    m.clippingPlanes = planes; m.needsUpdate = true;
  }
  dirty();
}

function setExplode(t) {
  st.expT = t;
  $('s-exp').value = t;
  dirty();
}
const tmp = new THREE.Vector3();
function applyExplode() {
  for (const p of st.parts) {
    offsetAt(p.ex, st.exp, tmp);
    p.root.position.copy(tmp);
    p.leader.material.opacity = Math.min(1, Math.max(0, (st.exp - 0.15) * 1.6)) * 0.85;
    p.leader.visible = p.root.visible && st.exp > 0.15;
  }
  $('o-exp').textContent = `${Math.round(st.exp * 100)}%`;
  st.shadowDirty = true;
}

function placeGrid() {
  if (st.box.isEmpty()) return;
  scene.updateMatrixWorld();
  const b = visibleBox();
  const box = b.isEmpty() ? st.box : b;
  const c = box.getCenter(new THREE.Vector3()), s = box.getSize(new THREE.Vector3());
  const R = Math.max(s.x, s.y, s.z) * 3 + 400;
  gridMesh.position.set(c.x, c.y, box.min.z - 0.6);
  gridMesh.scale.set(R * 2, R * 2, 1);
  gridMesh.material.uniforms.fade.value = R;
  gridMesh.material.uniforms.ctr.value.copy(c);
  floor.position.copy(gridMesh.position).setZ(box.min.z - 0.3);
  floor.scale.copy(gridMesh.scale);
  floor.material.uniforms.fade.value = Math.max(s.x, s.y, s.z) * 1.6;
  floor.material.uniforms.ctr.value.copy(c);
  floor.material.uniforms.strength.value = st.scheme === 'night' ? 0.34 : 0.22;
  const span = Math.max(s.x, s.y, s.z);
  gridMesh.material.uniforms.cell.value = span > 600 ? 10 : span > 60 ? 5 : 1;
  shadow.update(scene, box, Math.max(40, s.z * 0.35), SCHEMES[st.scheme].shadow);
}

function labels() {
  const host = $('labels');
  const show = st.labels && st.exp > 0.6;
  host.style.opacity = show ? Math.min(1, (st.exp - 0.6) * 4) : 0;
  if (!show) return;
  const w = cv.clientWidth, h = cv.clientHeight, v = new THREE.Vector3(), cols = new Map();
  for (const p of st.parts) {
    if (!p.root.visible) { p.labelEl.style.display = 'none'; continue; }
    let x0 = Infinity, x1 = -Infinity, y0 = Infinity, y1 = -Infinity, behind = false;
    for (let k = 0; k < 8; k++) {
      v.set(k & 1 ? p.info.hi[0] : p.info.lo[0], k & 2 ? p.info.hi[1] : p.info.lo[1], k & 4 ? p.info.hi[2] : p.info.lo[2]).add(p.root.position).project(camera);
      if (v.z > 1) behind = true;
      const x = (v.x * 0.5 + 0.5) * w, y = (-v.y * 0.5 + 0.5) * h;
      x0 = Math.min(x0, x); x1 = Math.max(x1, x); y0 = Math.min(y0, y); y1 = Math.max(y1, y);
    }
    if (behind) { p.labelEl.style.display = 'none'; continue; }
    v.set((p.info.lo[0] + p.info.hi[0]) / 2, (p.info.lo[1] + p.info.hi[1]) / 2, (p.info.lo[2] + p.info.hi[2]) / 2).add(p.root.position).project(camera);
    const it = { p, x0, x1, ay: (-v.y * 0.5 + 0.5) * h, mx: (v.x * 0.5 + 0.5) * w };
    const g = p.group || '';
    if (!cols.has(g)) cols.set(g, []);
    cols.get(g).push(it);
  }
  let svg = '';
  const all = [...cols.values()], mid = all.flat().reduce((a, i) => a + i.mx, 0) / Math.max(1, all.flat().length);
  for (const items of all) {
    const left = all.length > 1 && items.reduce((a, i) => a + i.mx, 0) / items.length < mid;
    const cx = left ? Math.min(...items.map(i => i.x0)) - 36 : Math.max(...items.map(i => i.x1)) + 36;
    for (const i of items) i.ax = left ? i.x0 + Math.min(10, (i.x1 - i.x0) * 0.2) : i.x1 - Math.min(10, (i.x1 - i.x0) * 0.2);
    items.sort((a, b) => a.ay - b.ay);
    let prev = -Infinity;
    for (const i of items) { i.y = Math.max(i.ay, prev + 22); prev = i.y; }
    const over = items.length ? items[items.length - 1].y - Math.max(items[items.length - 1].ay, h - 30) : 0;
    if (over > 0) { let nxt = Infinity; for (let k = items.length - 1; k >= 0; k--) { items[k].y = Math.min(items[k].y - over, nxt - 22); nxt = items[k].y; } }
    for (const i of items) {
      const el = i.p.labelEl;
      el.style.display = '';
      el.style.left = `${cx}px`; el.style.top = `${i.y}px`;
      el.classList.toggle('sel', st.sel.has(i.p));
      el.classList.toggle('left', left);
      const k = left ? 1 : -1;
      svg += `<polyline points="${i.ax.toFixed(1)},${i.ay.toFixed(1)} ${(cx + 14 * k).toFixed(1)},${i.y.toFixed(1)} ${(cx + 2 * k).toFixed(1)},${i.y.toFixed(1)}"/><circle cx="${i.ax.toFixed(1)}" cy="${i.ay.toFixed(1)}" r="2"/>`;
    }
  }
  $('leaders').innerHTML = svg;
}

function setMeasure(on) {
  st.meas = on ? [] : null;
  $('b-meas').classList.toggle('on', on);
  if (!on) $('meas').innerHTML = '';
  dirty();
}
function measureClick(h) {
  if (!h) return;
  const p = h.point.clone().sub(h.part.root.position);
  if (st.meas.length >= 2) st.meas = [];
  st.meas.push({ part: h.part, p });
  dirty();
}
function drawMeasure() {
  if (!st.meas) return;
  const w = cv.clientWidth, h = cv.clientHeight;
  const sp = st.meas.map(m => {
    const v = m.p.clone().add(m.part.root.position), q = v.clone().project(camera);
    return { v, x: (q.x * 0.5 + 0.5) * w, y: (-q.y * 0.5 + 0.5) * h };
  });
  let svg = sp.map(a => `<circle cx="${a.x.toFixed(1)}" cy="${a.y.toFixed(1)}" r="4.5"/>`).join('');
  if (sp.length === 2) {
    const d = sp[1].v.clone().sub(sp[0].v), mx = (sp[0].x + sp[1].x) / 2, my = (sp[0].y + sp[1].y) / 2;
    svg = `<line x1="${sp[0].x.toFixed(1)}" y1="${sp[0].y.toFixed(1)}" x2="${sp[1].x.toFixed(1)}" y2="${sp[1].y.toFixed(1)}"/>` + svg +
      `<foreignObject x="${(mx + 12).toFixed(1)}" y="${(my - 34).toFixed(1)}" width="260" height="80"><div class="mlab"><b>${fmt(d.length(), 3)} mm</b>
      <span>ΔX ${fmt(d.x, 3)} · ΔY ${fmt(d.y, 3)} · ΔZ ${fmt(d.z, 3)}</span><i>mesh measure, not certified</i></div></foreignObject>`;
  }
  $('meas').innerHTML = svg;
}

const cube = (() => {
  const c = $('cube'), r = new THREE.WebGLRenderer({ canvas: c, antialias: true, alpha: true });
  r.setPixelRatio(2);
  r.setSize(120, 120, false);
  const s = new THREE.Scene(), cam = new THREE.OrthographicCamera(-1.6, 1.6, 1.6, -1.6, 0.1, 10);
  cam.up.copy(Z);
  const names = [['RIGHT', 'right'], ['LEFT', 'left'], ['BACK', 'back'], ['FRONT', 'front'], ['TOP', 'top'], ['BOTTOM', 'bottom']];
  const mats = names.map(([t]) => {
    const k = document.createElement('canvas'); k.width = k.height = 128;
    const tex = new THREE.CanvasTexture(k); tex.colorSpace = THREE.SRGBColorSpace; tex.anisotropy = 4;
    return { k, tex, t, m: new THREE.MeshBasicMaterial({ map: tex }) };
  });
  const paint = (hi) => {
    const night = st.scheme === 'night';
    mats.forEach((f, i) => {
      const g = f.k.getContext('2d');
      g.fillStyle = i === hi ? (night ? '#1E4C5A' : '#BFE6EF') : (night ? '#1A2130' : '#F3F1EE'); g.fillRect(0, 0, 128, 128);
      g.strokeStyle = night ? '#3B4658' : '#B8BEC9'; g.lineWidth = 6; g.strokeRect(3, 3, 122, 122);
      g.fillStyle = i === hi ? (night ? '#6EE7FF' : '#0E7490') : (night ? '#C9D2DF' : '#3A4250');
      g.font = '600 22px Inter, system-ui, sans-serif'; g.textAlign = 'center'; g.textBaseline = 'middle';
      g.fillText(f.t, 64, 66);
      f.tex.needsUpdate = true;
    });
  };
  const box = new THREE.Mesh(new THREE.BoxGeometry(1.6, 1.6, 1.6), mats.map(f => f.m));
  mats[2].tex.rotation = 0;
  s.add(box);
  const ax = new THREE.Group();
  [[1, 0, 0, '#D14B4B'], [0, 1, 0, '#3E9B4F'], [0, 0, 1, '#3E6DD8']].forEach(([x, y, z, col]) => {
    const g = new THREE.BufferGeometry().setFromPoints([new THREE.Vector3(-0.8, -0.8, -0.8), new THREE.Vector3(-0.8 + x * 1.9, -0.8 + y * 1.9, -0.8 + z * 1.9)]);
    ax.add(new THREE.Line(g, new THREE.LineBasicMaterial({ color: col })));
  });
  s.add(ax);
  const ray = new THREE.Raycaster();
  let hi = -1;
  const faceAt = e => {
    const b = c.getBoundingClientRect();
    ray.setFromCamera(new THREE.Vector2(((e.clientX - b.left) / b.width) * 2 - 1, -((e.clientY - b.top) / b.height) * 2 + 1), cam);
    const h = ray.intersectObject(box)[0];
    return h ? h.face.materialIndex : -1;
  };
  c.onpointermove = e => { const f = faceAt(e); if (f !== hi) { hi = f; paint(hi); draw(); } };
  c.onpointerleave = () => { hi = -1; paint(hi); draw(); };
  c.onclick = e => { const f = faceAt(e); if (f >= 0) view(names[f][1]); };
  const draw = () => {
    const d = persp.position.clone().sub(st.target).normalize().multiplyScalar(5);
    cam.position.copy(d); cam.lookAt(0, 0, 0);
    r.render(s, cam);
  };
  paint(-1);
  return { draw, paint: () => paint(hi) };
})();

function buildTree() {
  const el = $('tree');
  el.innerHTML = '';
  const groups = [...new Set(st.parts.map(p => p.group || 'Parts'))];
  for (const g of groups) {
    const h = document.createElement('h4'); h.textContent = g; el.append(h);
    for (const p of st.parts.filter(q => (q.group || 'Parts') === g)) {
      const r = document.createElement('div');
      r.className = 'row'; r.dataset.i = p.i;
      const f = FINISHES[p.finish] || FINISHES.part;
      r.innerHTML = `<span class="sw" style="background:${f.color}"></span><span class="nm">${p.label}</span>
        <span class="iso" title="Isolate"><svg viewBox="0 0 20 20"><circle cx="10" cy="10" r="3"/><path d="M3 10h2M15 10h2M10 3v2M10 15v2"/></svg></span>
        <span class="eye" title="Show / hide"><svg viewBox="0 0 20 20"><path d="M2 10s3-5 8-5 8 5 8 5-3 5-8 5-8-5-8-5z"/><circle cx="10" cy="10" r="2.2"/></svg></span>`;
      r.querySelector('.eye').onclick = e => { e.stopPropagation(); setVisible(p, !p.root.visible); };
      r.querySelector('.iso').onclick = e => { e.stopPropagation(); isolate(st.iso && st.iso.length === 1 && st.iso[0] === p ? null : [p]); };
      r.onclick = e => select(p, e.ctrlKey || e.metaKey || e.shiftKey);
      r.ondblclick = () => fit([p]);
      r.onpointerenter = () => hover(p);
      r.onpointerleave = () => hover(null);
      el.append(r);
    }
  }
}

function controls() {
  let drag = null, hoverQ = null;
  cv.addEventListener('contextmenu', e => e.preventDefault());
  cv.addEventListener('pointerdown', e => {
    cv.setPointerCapture(e.pointerId);
    const pan_ = e.button === 1 || e.button === 2 || (e.button === 0 && e.shiftKey);
    const hit = pan_ ? null : pick(e.clientX, e.clientY);
    drag = { x: e.clientX, y: e.clientY, x0: e.clientX, y0: e.clientY, pan: pan_, pivot: hit ? hit.point : st.target.clone(), moved: false, btn: e.button, hit };
  });
  cv.addEventListener('pointermove', e => {
    if (drag) {
      const dx = e.clientX - drag.x, dy = e.clientY - drag.y;
      drag.x = e.clientX; drag.y = e.clientY;
      if (Math.hypot(e.clientX - drag.x0, e.clientY - drag.y0) > 3) { drag.moved = true; document.body.classList.add('grab'); }
      if (!drag.moved) return;
      if (drag.pan) pan(dx, dy); else orbit(dx, dy, drag.pivot);
      return;
    }
    hoverQ = [e.clientX, e.clientY];
    const tip = $('tip'); tip.style.left = `${e.clientX + 16}px`; tip.style.top = `${e.clientY + 18}px`;
  });
  cv.addEventListener('pointerup', e => {
    document.body.classList.remove('grab');
    if (drag && !drag.moved && drag.btn === 0 && st.meas) measureClick(drag.hit);
    else if (drag && !drag.moved && drag.btn === 0) select(drag.hit ? drag.hit.part : null, e.ctrlKey || e.metaKey, drag.hit ? drag.hit.face : -1);
    drag = null;
  });
  cv.addEventListener('pointerleave', () => { hoverQ = null; if (!drag) hover(null); $('tip').hidden = true; });
  cv.addEventListener('dblclick', e => { const h = pick(e.clientX, e.clientY); if (h) fit([h.part]); else fit(); });
  cv.addEventListener('wheel', e => {
    e.preventDefault();
    const h = pick(e.clientX, e.clientY);
    let p = h ? h.point : null;
    if (!p) {
      const ray = new THREE.Raycaster(); ray.setFromCamera(ndc(e.clientX, e.clientY), camera);
      const pl = new THREE.Plane().setFromNormalAndCoplanarPoint(st.target.clone().sub(persp.position).normalize(), st.target);
      p = ray.ray.intersectPlane(pl, new THREE.Vector3());
    }
    zoomAt(Math.exp(e.deltaY * 0.0012), p);
  }, { passive: false });
  setInterval(() => {
    if (!hoverQ || drag || st.anim) return;
    const h = pick(hoverQ[0], hoverQ[1]);
    hoverQ = null;
    hover(h ? h.part : null, h ? h.face : -1);
  }, 45);
  addEventListener('keydown', e => {
    if (e.target.tagName === 'INPUT') return;
    const k = e.key.toLowerCase();
    if (k === 'f') fit(st.sel.size ? [...st.sel] : null);
    else if (k === 'escape') { select(null); if (st.iso) isolate(null); if (st.meas) setMeasure(false); }
    else if (k === 'e') toggleExplode();
    else if (k === 's') setSection(!st.sec);
    else if (k === 'r') toggleRun();
    else if (k === 'p') useCamera(camera === persp ? ortho : persp);
    else if (k === 'm') setMeasure(!st.meas);
    else if (k === 'g') setSelMode(st.selMode === 'part' ? 'face' : 'part');
    else if (k === 'h' && st.sel.size) [...st.sel].forEach(p => setVisible(p, false));
    else if (k === 'u') st.parts.forEach(p => setVisible(p, true));
    else if ('0123456'.includes(k)) view(['iso', 'front', 'back', 'left', 'right', 'top', 'bottom'][+k]);
  });
}

function toggleExplode() {
  const on = st.expT < 0.5;
  setExplode(on ? 1 : 0);
  $('b-exp').classList.toggle('on', on);
  $('c-exp').hidden = !on;
  setTimeout(() => fit(), on ? 900 : 0);
}
function toggleRun() {
  st.run = !st.run;
  $('b-run').classList.toggle('on', st.run);
  $('c-run').hidden = !st.run;
  dirty();
}

function save(b, n) { const a = document.createElement('a'); a.href = URL.createObjectURL(b); a.download = n; a.click(); }
function snapshot(w = 3840, h = 2160) {
  const pr = renderer.getPixelRatio(), cw = cv.clientWidth, ch = cv.clientHeight;
  renderer.setPixelRatio(1);
  renderer.setSize(w, h, false); composer.setPixelRatio(1); composer.setSize(w, h); gtao.setSize(w, h);
  persp.aspect = w / h; persp.updateProjectionMatrix();
  const a0 = cw / ch, hh = (ortho.top - ortho.bottom) / 2;
  ortho.left = -hh * w / h; ortho.right = hh * w / h; ortho.updateProjectionMatrix();
  composer.render();
  return new Promise(res => cv.toBlob(b => {
    renderer.setPixelRatio(pr);
    resize();
    ortho.left = -hh * a0; ortho.right = hh * a0; ortho.updateProjectionMatrix();
    res(b);
  }, 'image/png'));
}

function ui() {
  document.querySelectorAll('[data-act]').forEach(b => b.onclick = async e => {
    const a = b.dataset.act;
    if (a === 'fit') fit();
    if (a === 'views') { b.parentElement.classList.toggle('open'); e.stopPropagation(); }
    if (a === 'proj') useCamera(camera === persp ? ortho : persp);
    if (a === 'section') setSection(!st.sec);
    if (a === 'measure') setMeasure(!st.meas);
    if (a === 'explode') toggleExplode();
    if (a === 'run') toggleRun();
    if (a === 'theme') setScheme(st.scheme === 'night' ? 'day' : 'night');
    if (a === 'shot') save(await snapshot(), `${st.scene.name || 'bendcad'}-4k.png`);
    if (a === 'rec') {
      const rec = new MediaRecorder(cv.captureStream(60), { mimeType: 'video/webm;codecs=vp9', videoBitsPerSecond: 24e6 }), ch = [];
      rec.ondataavailable = ev => ch.push(ev.data);
      rec.onstop = () => { save(new Blob(ch, { type: 'video/webm' }), `${st.scene.name || 'bendcad'}-run.webm`); $('b-rec').classList.remove('on'); };
      if (!st.run) toggleRun();
      $('b-rec').classList.add('on');
      rec.start(); setTimeout(() => rec.stop(), 6000);
    }
  });
  addEventListener('click', () => document.querySelectorAll('.menu.open').forEach(m => m.classList.remove('open')));
  document.querySelectorAll('[data-view]').forEach(b => b.onclick = () => view(b.dataset.view));
  document.querySelectorAll('[data-mode]').forEach(b => b.onclick = () => setMode(b.dataset.mode));
  document.querySelectorAll('[data-sm]').forEach(b => b.onclick = () => setSelMode(b.dataset.sm));
  $('s-exp').oninput = e => { st.expT = +e.target.value; dirty(); };
  $('b-labels').onclick = () => { st.labels = !st.labels; $('b-labels').classList.toggle('on', st.labels); dirty(); };
  $('s-rpm').oninput = e => { st.rps = +e.target.value; $('o-rpm').textContent = `${st.rps.toFixed(1)} rev/s`; };
  $('o-rpm').textContent = `${st.rps.toFixed(1)} rev/s`;
  document.querySelectorAll('[data-ax]').forEach(b => b.onclick = () => {
    st.secAx = b.dataset.ax; document.querySelectorAll('[data-ax]').forEach(x => x.classList.toggle('on', x === b)); faceCut(); updateSection();
  });
  $('b-flip').onclick = () => { st.secFlip = !st.secFlip; $('b-flip').classList.toggle('on', st.secFlip); updateSection(); };
  $('s-sec').oninput = e => { st.secT = +e.target.value; updateSection(); };
  $('b-caps').onclick = () => { st.caps = !st.caps; $('b-caps').classList.toggle('on', st.caps); updateSection(); };
  addEventListener('resize', resize);
}

function frame(now) {
  requestAnimationFrame(frame);
  const dt = Math.min(0.05, (now - st.last) / 1000 || 0); st.last = now;
  let moving = false;
  if (st.anim) {
    const a = st.anim, t = Math.min(1, (now - a.s) / a.ms), k = 1 - Math.pow(1 - t, 3);
    persp.position.lerpVectors(a.p0, a.p1, k); st.target.lerpVectors(a.t0, a.t1, k);
    syncCam();
    if (t >= 1) st.anim = null;
    moving = true;
  }
  if (Math.abs(st.expT - st.exp) > 1e-4) {
    st.exp += (st.expT - st.exp) * Math.min(1, dt * 2.6);
    if (Math.abs(st.expT - st.exp) < 1e-3) st.exp = st.expT;
    applyExplode(); moving = true;
  }
  if (st.run) {
    st.ang += dt * st.rps * 2 * Math.PI;
    for (const p of st.parts) { p.spin.rotation.z = st.ang * (+p.rotor || 0); if (p.self) p.self.rotation.z = st.ang * (+p.selfspin || 0); }
    moving = true;
  }
  if (!moving && st.shadowDirty) { placeGrid(); st.shadowDirty = false; st.dirty = true; }
  if (!st.dirty && !moving) return;
  st.dirty = false;
  composer.render();
  cube.draw();
  labels();
  drawMeasure();
  status();
}
function status() {
  const tris = st.parts.reduce((s, p) => s + (p.root.visible ? p.info.tris : 0), 0);
  $('status').textContent = `${st.parts.filter(p => p.root.visible).length}/${st.parts.length} parts · ${tris >= 1e5 ? `${(tris / 1e6).toFixed(2)} M` : tris.toLocaleString()} tris · ${camera === persp ? 'perspective' : 'orthographic'}${st.selMode === 'face' ? ' · face select' : ''}`;
}

function pool(n) {
  const ws = Array.from({ length: n }, () => new Worker(new URL('./mesh-worker.js', import.meta.url), { type: 'module' }));
  let next = 0, seq = 0;
  const wait = new Map();
  ws.forEach(w => w.onmessage = e => { const f = wait.get(e.data.id); wait.delete(e.data.id); e.data.error ? f[1](new Error(e.data.error)) : f[0](e.data.m); });
  return url => new Promise((res, rej) => { const id = seq++; wait.set(id, [res, rej]); ws[next++ % n].postMessage({ id, url }); });
}

function partObject(p, m, i) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.BufferAttribute(m.pos, 3));
  g.setAttribute('normal', new THREE.BufferAttribute(m.nor, 3));
  g.setAttribute('fid', new THREE.BufferAttribute(m.fid, 1));
  g.setIndex(new THREE.BufferAttribute(m.idx, 1));
  g.computeBoundingSphere();
  p.mat = partMaterial(p.finish, m.lo, m.hi);
  const mesh = new THREE.Mesh(g, p.mat);
  mesh.userData.part = true;
  mesh.userData.pickMat = pickMaterial(i + 1);
  const eg = new THREE.BufferGeometry();
  eg.setAttribute('position', new THREE.BufferAttribute(m.edges, 3));
  const edges = new THREE.LineSegments(eg, new THREE.LineBasicMaterial({ color: SCHEMES[st.scheme].edge, transparent: true, opacity: 0.62, depthWrite: false }));
  const stencil = (side, op) => {
    const sm = new THREE.MeshBasicMaterial({
      side, colorWrite: false, depthWrite: false, depthTest: false,
      stencilWrite: true, stencilFunc: THREE.AlwaysStencilFunc, stencilFail: op, stencilZFail: op, stencilZPass: op
    });
    const o = new THREE.Mesh(g, sm);
    o.renderOrder = 10 + i * 3; o.visible = false; o.userData.stencil = true;
    return o;
  };
  const stB = stencil(THREE.BackSide, THREE.IncrementWrapStencilOp), stF = stencil(THREE.FrontSide, THREE.DecrementWrapStencilOp);
  stF.renderOrder += 1;
  const f = FINISHES[p.finish] || FINISHES.part;
  const capCol = new THREE.Color(f.color).lerp(new THREE.Color('#ffffff'), 0.25);
  const cap = new THREE.Mesh(new THREE.PlaneGeometry(1, 1), new THREE.MeshStandardMaterial({
    color: capCol, metalness: 0.15, roughness: 0.62, map: hatch, side: THREE.DoubleSide,
    stencilWrite: true, stencilRef: 0, stencilFunc: THREE.NotEqualStencilFunc,
    stencilFail: THREE.ReplaceStencilOp, stencilZFail: THREE.ReplaceStencilOp, stencilZPass: THREE.ReplaceStencilOp
  }));
  cap.renderOrder = 10 + i * 3 + 2; cap.visible = false; cap.userData.cap = true;
  cap.onAfterRender = r => r.clearStencil();
  const spin = new THREE.Group(), root = new THREE.Group();
  let info = m;
  if (p.xf) {
    const place = new THREE.Group();
    place.matrixAutoUpdate = false;
    place.matrix.fromArray(p.xf);
    const self = new THREE.Group();
    self.add(mesh, edges, stB, stF);
    place.add(self);
    spin.add(place);
    p.self = self;
    const b = new THREE.Box3(new THREE.Vector3(...m.lo), new THREE.Vector3(...m.hi)).applyMatrix4(place.matrix);
    info = Object.assign({}, m, { lo: b.min.toArray(), hi: b.max.toArray() });
  } else spin.add(mesh, edges, stB, stF);
  root.add(spin);
  Object.assign(p, { i, info, mesh, edges, stB, stF, cap, spin, root });
  scene.add(root, cap);
}

const pretty = s => s.replace(/_/g, ' ').replace(/^\w/, c => c.toUpperCase());

let fetchMesh = null;
function clearParts() {
  for (const p of st.parts) {
    scene.remove(p.root); scene.remove(p.cap); if (p.leader) scene.remove(p.leader);
    p.mesh.geometry.dispose(); p.edges.geometry.dispose(); p.mat.dispose(); p.cap.material.dispose();
    if (p.labelEl) p.labelEl.remove();
  }
  st.parts = []; st.sel.clear(); st.hov = null; st.face = null; st.hface = null;
}

async function loadParts(sc, base, first) {
  st.scene = sc;
  document.title = `${sc.name} · BendCAD`;
  $('name').textContent = sc.name || 'BendCAD Viewer';
  const keep = new Set([...st.sel].map(p => p.node));
  const ps = sc.parts.map(p => Object.assign({ label: p.label || pretty(p.name) }, p));
  if (!fetchMesh) fetchMesh = pool(Math.max(2, Math.min(8, (navigator.hardwareConcurrency || 4) - 2)));
  const totalTris = ps.reduce((s, p) => s + (p.tris || 1), 0);
  let doneTris = 0, done = 0;
  const t0 = performance.now();
  const failed = [], cache = new Map(), got = new Map();
  const load = u => { if (!cache.has(u)) cache.set(u, fetchMesh(u)); return cache.get(u); };
  await Promise.all(ps.map(async p => {
    try { got.set(p, await load(base + p.mesh)); } catch (e) { failed.push(p); return; }
    doneTris += p.tris || 1; done++;
    $('load-t').textContent = `Meshing ${done} / ${ps.length} parts`;
    $('load-b').style.width = `${(100 * doneTris / totalTris).toFixed(1)}%`;
  }));
  clearParts();
  st.parts = ps.filter(p => got.has(p));
  st.parts.forEach((p, i) => partObject(p, got.get(p), i));
  st.loadMs = Math.round(performance.now() - t0);
  st.parts.forEach((p, i) => { p.i = i; p.mesh.userData.pickMat.uniforms.pid.value = i + 1; });
  st.box = new THREE.Box3();
  for (const p of st.parts) st.box.union(new THREE.Box3(new THREE.Vector3(...p.info.lo), new THREE.Vector3(...p.info.hi)));
  st.radius = st.box.getSize(new THREE.Vector3()).length() / 2;
  const S = st.box.getSize(new THREE.Vector3());
  const capSize = Math.max(S.x, S.y, S.z) * 8;
  for (const p of st.parts) { p.cap.scale.set(capSize, capSize, 1); }
  hatch.repeat.set(capSize / 7, capSize / 7);
  const ex = layout(st.parts.map(p => Object.assign(p, { lo: p.info.lo, hi: p.info.hi })));
  for (const p of st.parts) {
    p.ex = ex.get(p);
    p.leader = leader(p.info, p.ex, '#8FA6C4');
    p.leader.visible = false;
    scene.add(p.leader);
    const l = document.createElement('div'); l.textContent = p.label; $('labels').append(l); p.labelEl = l;
  }
  gtao.updateGtaoMaterial({ radius: st.radius * 0.07, distanceExponent: 1.2, thickness: st.radius * 0.02, scale: 1.0, samples: 16 });
  gtao.updatePdMaterial({ lumaPhi: 10, depthPhi: 2, normalPhi: 3, radius: 6, rings: 2, samples: 16 });
  buildTree();
  setScheme(st.scheme);
  applyExplode();
  setSection(st.sec);
  setMode(st.mode);
  for (const p of st.parts) if (keep.has(p.node)) st.sel.add(p);
  document.querySelectorAll('#tree .row').forEach(r => r.classList.toggle('sel', st.sel.has(st.parts[+r.dataset.i])));
  props(); applyLook();
  if (first) {
    const v = new THREE.Vector3(...VIEWS.iso).normalize();
    const c = st.box.getCenter(new THREE.Vector3());
    st.target.copy(c);
    persp.position.copy(c).add(v.multiplyScalar(st.radius / Math.sin(THREE.MathUtils.degToRad(persp.fov / 2)) * 1.08));
    syncCam();
  }
  st.shadowDirty = true;
  status();
  dirty();
  return failed;
}

const live = { on: false, doc: null, proc: 'mill', busy: '', last: null, checks: null, node: null, failed: [], near: null, nearing: false };
const esc = t => String(t).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const chip = s => `<b class="st ${s || 'na'}">${s === 'pass' ? 'pass' : s === 'fail' ? 'fail' : s === 'ok' ? 'ok' : s === 'not-analyzed' ? 'n/a' : esc(s || '?')}</b>`;
const PLACE = new Set(['move', 'rotate']);
function featOp(d, id) {
  const n = d.nodes.find(x => x.id === id);
  return n && PLACE.has(n.op) && n.base && n.base.length ? featOp(d, n.base[0]) : n ? n.op : '?';
}
function liveScene(d) {
  return { name: d.name, parts: d.parts.map(id => {
    const op = featOp(d, id);
    return { name: `${op}_${id}`, label: `${op[0].toUpperCase() + op.slice(1)} · node ${id}`, node: id, mesh: `/api/mesh/${id}.obj?rev=${d.rev}`, finish: 'part' };
  }) };
}
const whyHtml = ws => ws.map(l => {
  const m = l.match(/^node (\d+): \S+ \S+ \| (.*?) \| why: (.*?) \| fix: (.*)$/);
  return m ? `<li><b>node ${m[1]} · ${esc(m[2])}</b><span>${esc(m[3])}</span><i>fix: ${esc(m[4])}</i></li>` : `<li><span>${esc(l)}</span></li>`;
}).join('');
const decs = s => (String(s).split('.')[1] || '').length;
function paramEdit(p, v) {
  if (p.cls && /^-?\d+(\.\d+)?$/.test(v)) return `(param ${p.name} ${v} ${p.cls})`;
  if (p.lo === p.hi || !/^-?\d+(\.\d+)?$/.test(v)) return `(param ${p.name} ${v})`;
  const k = Math.max(decs(p.value), decs(p.lo), decs(p.hi), decs(v)), f = x => (+x).toFixed(k).replace(/(\.\d*?)0+$/, '$1').replace(/\.$/, '');
  return `(param ${p.name} ${v} ${f(+v + (+p.lo - +p.value))} ${f(+v + (+p.hi - +p.value))})`;
}
function liveRender() {
  const d = live.doc, el = $('live');
  if (!d) return;
  el.hidden = false;
  const prm = d.params.map(p => `<label class="prm"><span>${esc(p.name)}</span><input data-p="${esc(p.name)}" value="${esc(p.value)}" spellcheck="false"${live.busy ? ' disabled' : ''}>
    ${p.lo !== p.hi ? `<i>${p.cls ? `${esc(p.cls)} (ISO 286) ` : ''}zone ${esc(p.lo)} – ${esc(p.hi)}</i>` : ''}</label>`).join('');
  const nodes = d.nodes.map(n => `<div class="feat${d.parts.includes(n.id) ? ' part' : ''}${n.status !== 'ok' ? ' bad' : ''}" data-n="${n.id}" title="${esc(n.text)}">
    <span class="id">${n.id}</span><span class="op">${esc(n.op)}</span>${n.base && n.base.length ? `<span class="on">← ${n.base.join(', ')}</span>` : ''}${chip(n.status === 'ok' ? 'ok' : 'fail')}</div>`).join('');
  const last = live.last ? `<div class="kmsg ${live.last.ok ? 'ok' : 'bad'}">${live.last.ok ? 'committed' : 'refused'} · ${(live.last.ms / 1000).toFixed(2)} s${live.last.ok ? '' : `<ul>${whyHtml(live.last.why && live.last.why.length ? live.last.why : [live.last.out])}</ul>`}</div>` : '';
  el.innerHTML = `<h4>Parameters</h4>${prm || '<div class="none">No parameters in this design</div>'}${last}<h4>Features</h4>${nodes}`;
  el.querySelectorAll('input[data-p]').forEach(inp => {
    const go = () => { const p = d.params.find(x => x.name === inp.dataset.p), v = inp.value.trim(); if (p && v !== p.value) liveApply(paramEdit(p, v)); };
    inp.onkeydown = e => { if (e.key === 'Enter') { e.preventDefault(); go(); } if (e.key === 'Escape') { inp.value = d.params.find(x => x.name === inp.dataset.p).value; inp.blur(); } };
    inp.onchange = go;
  });
  el.querySelectorAll('.feat.part').forEach(r => r.onclick = () => { const p = st.parts.find(q => q.node === +r.dataset.n); if (p) select(p, false); });
  $('kstat').textContent = live.busy || (live.last ? `${live.last.ok ? 'updated' : 'refused'} · edit ${(live.last.ms / 1000).toFixed(2)} s · rebuild ${((live.last.rebuild || 0) / 1000).toFixed(2)} s` : `evaluated and meshed in ${(d.eval_ms / 1000).toFixed(2)} s`);
  $('kstat').classList.toggle('busy', !!live.busy);
}
function checksRender() {
  const el = $('checks'), c = live.checks;
  el.hidden = !live.on;
  if (!live.on) return;
  const procs = ['mill', 'lathe', 'fdm', 'sla'].map(x => `<button data-proc="${x}" class="${live.proc === x ? 'on' : ''}">${x}</button>`).join('');
  if (!c) { el.innerHTML = `<h3>Checks</h3><div class="sub">${live.busy ? esc(live.busy) : 'Select a part'}</div>`; return; }
  const bad = c.make.lines.filter(l => l.status !== 'pass');
  el.innerHTML = `<h3>Checks · node ${c.node}</h3>
    <div class="ck">${chip(c.check.status)}<span>${esc(c.check.text)}</span></div>
    <div class="ck">${chip(/0 fail, 0 not-analyzed/.test(c.std.summary) ? 'pass' : c.std.summary ? 'fail' : 'na')}<span>${esc(c.std.summary || 'no standard features')}</span></div>
    ${c.std.lines.filter(l => l.status && l.status !== 'pass').map(l => `<div class="ck sub2">${chip(l.status)}<span>${esc(l.text)}</span></div>`).join('')}
    <div class="seg procs">${procs}</div>
    <div class="ck">${chip(c.make.verdict === 'makeable' ? 'pass' : c.make.verdict === 'not-makeable' ? 'fail' : 'not-analyzed')}<span>${esc(c.make.verdict)} · ${esc(c.make.summary.replace(/^make node \d+: /, ''))}${esc(c.make.head || '')}</span></div>
    ${bad.slice(0, 12).map(l => `<div class="ck sub2">${chip(l.status)}<span>${esc(l.text.replace(/^make (face|corner) /, ''))}</span></div>`).join('')}
    ${bad.length > 12 ? `<div class="sub">${bad.length - 12} more</div>` : ''}
    ${nearHtml(c.node)}`;
  el.querySelectorAll('[data-proc]').forEach(b => b.onclick = () => { live.proc = b.dataset.proc; liveChecks(c.node); });
}
const mm = x => x.toFixed(4);
const nearSt = r => r.kind === 'clearance' || r.kind === 'apart' ? 'pass' : r.kind === 'interference' || r.kind === 'inside' ? 'fail' : 'not-analyzed';
const nearTxt = r => r.kind === 'apart' ? `at least ${mm(r.lo)} mm (enclosing boxes)`
  : r.kind === 'clearance' ? `${r.hi - r.lo > 1e-4 ? `${mm(r.lo)} to ${mm(r.hi)}` : mm((r.lo + r.hi) / 2)} mm, ${r.status}`
  : r.kind === 'interference' ? `interference, ${r.status}` : r.kind === 'inside' ? `inside its material, ${r.status}` : r.text;
function nearHtml(node) {
  const r = live.near && live.near.node === node ? live.near : null;
  const lb = x => (st.parts.find(p => p.node === x.node) || { label: `node ${x.node}` }).label;
  return `<h4>Neighbours</h4>${r ? r.rows.length ? r.rows.map(x => `<div class="ck nb" data-nb="${x.node}">${chip(nearSt(x))}<span>${esc(lb(x))}: ${esc(nearTxt(x))}</span></div>`).join('')
    : '<div class="sub">no other parts</div>' : `<div class="sub">${live.nearing ? 'measuring clearances' : ''}</div>`}`;
}
async function liveNear(node) {
  const rev = live.doc.rev;
  live.near = null; live.nearing = true; checksRender(); applyLook();
  const r = await (await fetch(`/api/near/${node}`)).json();
  if (live.node !== node || live.doc.rev !== rev || r.stale) return;
  live.near = r; live.nearing = false; checksRender(); applyLook();
}
async function liveChecks(node) {
  live.node = node;
  live.checks = null; live.busy = `checking node ${node} (${live.proc})`; liveRender(); checksRender();
  const r = await (await fetch(`/api/checks/${node}?proc=${live.proc}`)).json();
  if (live.node !== node) return;
  live.checks = r; live.busy = ''; liveRender(); checksRender(); props();
  liveNear(node);
}
async function liveApply(edit) {
  live.busy = `applying ${edit}`; liveRender();
  const r = await (await fetch('/api/edit', { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ edit }) })).json();
  live.last = r;
  if (r.ok) {
    live.doc = r.doc;
    live.busy = 'rebuilding parts'; liveRender();
    const t0 = performance.now();
    live.failed = await loadParts(liveScene(r.doc), '', false);
    r.rebuild = performance.now() - t0;
  } else live.doc = r.doc;
  live.busy = '';
  liveRender();
  if (live.node != null) await liveChecks(live.node);
  document.body.dataset.rev = live.doc.rev;
}

async function main() {
  ui();
  setScheme('night');
  resize();
  controls();
  useCamera(persp);
  const q = new URLSearchParams(location.search), src = q.get('scene') || 'scene.json';
  live.on = q.get('live') === '1';
  if (live.on) live.proc = q.get('proc') || live.proc;
  let sc, base = '';
  if (live.on) { live.doc = await (await fetch('/api/doc')).json(); sc = liveScene(live.doc); document.body.classList.add('live'); }
  else { sc = await (await fetch(src)).json(); base = src.slice(0, src.lastIndexOf('/') + 1); }
  live.failed = await loadParts(sc, base, true);
  if (q.get('mode') === 'exploded') { st.exp = 1; setExplode(1); applyExplode(); $('b-exp').classList.add('on'); $('c-exp').hidden = false; fit(); }
  if (q.get('section') === '1') setSection(true);
  if (q.get('run') === '1') toggleRun();
  if (q.get('theme') === 'day') setScheme('day');
  if (q.get('view')) view(q.get('view'));
  if (live.on) {
    liveRender(); checksRender();
    document.body.dataset.rev = live.doc.rev;
    if (st.parts.length) select(st.parts[0], false);
  }
  document.body.classList.add('ready');
  document.body.dataset.ready = '1';
  requestAnimationFrame(frame);
}

function bench(n = 20) {
  const g = renderer.getContext(), px = new Uint8Array(4);
  composer.render(); g.readPixels(0, 0, 1, 1, g.RGBA, g.UNSIGNED_BYTE, px);
  const t0 = performance.now();
  for (let k = 0; k < n; k++) { dirty(); composer.render(); }
  g.readPixels(0, 0, 1, 1, g.RGBA, g.UNSIGNED_BYTE, px);
  return (performance.now() - t0) / n;
}
function boxes() {
  scene.updateMatrixWorld();
  return st.parts.filter(p => p.root.visible).map(p => {
    const b = new THREE.Box3(new THREE.Vector3(...p.info.lo), new THREE.Vector3(...p.info.hi)).translate(p.root.position);
    return { name: p.name, lo: b.min.toArray(), hi: b.max.toArray() };
  });
}
function gpu() {
  const g = renderer.getContext(), e = g.getExtension('WEBGL_debug_renderer_info');
  return e ? g.getParameter(e.UNMASKED_RENDERER_WEBGL) : 'unknown';
}
function projectedBounds() {
  scene.updateMatrixWorld();
  const r = cv.getBoundingClientRect(), o = { minx: Infinity, miny: Infinity, maxx: -Infinity, maxy: -Infinity }, v = new THREE.Vector3();
  for (const b of boxes()) for (let k = 0; k < 8; k++) {
    v.set(k & 1 ? b.hi[0] : b.lo[0], k & 2 ? b.hi[1] : b.lo[1], k & 4 ? b.hi[2] : b.lo[2]).project(camera);
    const x = (v.x * 0.5 + 0.5) * r.width, y = (-v.y * 0.5 + 0.5) * r.height;
    o.minx = Math.min(o.minx, x); o.maxx = Math.max(o.maxx, x); o.miny = Math.min(o.miny, y); o.maxy = Math.max(o.maxy, y);
  }
  for (const k in o) o[k] = Math.round(o[k]);
  return o;
}
function screenOf(pts) {
  const r = cv.getBoundingClientRect();
  return pts.map(a => { const v = new THREE.Vector3(...a).project(camera); return [r.left + (v.x * 0.5 + 0.5) * r.width, r.top + (-v.y * 0.5 + 0.5) * r.height]; });
}
window.bcv = { live: () => ({ doc: live.doc, checks: live.checks, last: live.last, busy: live.busy, near: live.near, nearing: live.nearing, failed: live.failed.map(p => p.node) }), liveApply, liveChecks, parts: () => st.parts.map(p => ({ node: p.node, lo: p.info.lo, hi: p.info.hi, volume: p.info.volume, tris: p.info.tris })), view, screenOf, setMeasure, measureClick, projectedBounds, bench, boxes, gpu, camera: () => ({ pos: persp.position.toArray(), tgt: st.target.toArray(), ortho: camera === ortho }), setSelMode, st, fit, view, select, setSection, setExplode, setMode, isolate, setScheme, snapshot, pick, useCamera, persp, ortho, toggleRun, updateSection };
main().catch(e => { $('load-t').textContent = 'Error: ' + e.message; console.error(e); });
