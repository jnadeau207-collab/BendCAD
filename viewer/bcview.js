'use strict';
const cv = document.getElementById('gl');
const gl = cv.getContext('webgl2', { antialias: true, preserveDrawingBuffer: true });
const $ = id => document.getElementById(id);
const st = { exp: 0, expT: 0, sec: false, run: false, rps: 3, ang: 0, yaw: -0.9, pitch: 0.35, dist: 400, tgt: [0, 0, 100], parts: [], last: 0 };

const VS = `#version 300 es
in vec3 p; in vec3 n;
uniform mat4 M, VP; uniform mat3 N;
out vec3 wp; out vec3 wn;
void main() { vec4 w = M * vec4(p, 1.0); wp = w.xyz; wn = N * n; gl_Position = VP * w; }`;
const FS = `#version 300 es
precision highp float;
in vec3 wp; in vec3 wn;
uniform vec3 col, eye; uniform vec4 clip; uniform int cap;
out vec4 o;
void main() {
  if (dot(vec4(wp, 1.0), clip) > 0.0) discard;
  if (!gl_FrontFacing) { if (cap == 1) { o = vec4(col * 0.55 + vec3(0.18, 0.05, 0.02), 1.0); return; } }
  vec3 nn = normalize(gl_FrontFacing ? wn : -wn);
  vec3 v = normalize(eye - wp);
  vec3 l1 = normalize(v + vec3(0.3, 0.5, 0.4));
  float d = max(dot(nn, l1), 0.0), s = pow(max(dot(nn, normalize(l1 + v)), 0.0), 48.0);
  float r = pow(1.0 - max(dot(nn, v), 0.0), 3.0);
  o = vec4(col * (0.22 + 0.78 * d) + vec3(0.35) * s + vec3(0.08, 0.1, 0.13) * r, 1.0);
}`;

function sh(t, s) { const x = gl.createShader(t); gl.shaderSource(x, s); gl.compileShader(x); if (!gl.getShaderParameter(x, gl.COMPILE_STATUS)) throw gl.getShaderInfoLog(x); return x; }
const pr = gl.createProgram();
gl.attachShader(pr, sh(gl.VERTEX_SHADER, VS)); gl.attachShader(pr, sh(gl.FRAGMENT_SHADER, FS)); gl.linkProgram(pr);
const U = n => gl.getUniformLocation(pr, n);
const loc = { M: U('M'), VP: U('VP'), N: U('N'), col: U('col'), eye: U('eye'), clip: U('clip'), cap: U('cap') };

function parseObj(txt) {
  const v = [], f = [];
  for (const ln of txt.split('\n')) {
    if (ln[0] === 'v' && ln[1] === ' ') { const a = ln.split(' '); v.push(+a[1], +a[2], +a[3]); }
    else if (ln[0] === 'f') { const a = ln.split(' '); f.push(+a[1] - 1, +a[2] - 1, +a[3] - 1); }
  }
  const vn = new Float32Array(v.length);
  for (let i = 0; i < f.length; i += 3) {
    const a = f[i] * 3, b = f[i + 1] * 3, c = f[i + 2] * 3;
    const ux = v[b] - v[a], uy = v[b + 1] - v[a + 1], uz = v[b + 2] - v[a + 2];
    const wx = v[c] - v[a], wy = v[c + 1] - v[a + 1], wz = v[c + 2] - v[a + 2];
    const nx = uy * wz - uz * wy, ny = uz * wx - ux * wz, nz = ux * wy - uy * wx;
    for (const k of [a, b, c]) { vn[k] += nx; vn[k + 1] += ny; vn[k + 2] += nz; }
  }
  const pos = new Float32Array(f.length * 3), nor = new Float32Array(f.length * 3);
  for (let i = 0; i < f.length; i += 3) {
    const a = f[i] * 3, b = f[i + 1] * 3, c = f[i + 2] * 3;
    const ux = v[b] - v[a], uy = v[b + 1] - v[a + 1], uz = v[b + 2] - v[a + 2];
    const wx = v[c] - v[a], wy = v[c + 1] - v[a + 1], wz = v[c + 2] - v[a + 2];
    let nx = uy * wz - uz * wy, ny = uz * wx - ux * wz, nz = ux * wy - uy * wx;
    const l = Math.hypot(nx, ny, nz) || 1; nx /= l; ny /= l; nz /= l;
    for (let j = 0; j < 3; j++) {
      const k = f[i + j] * 3;
      pos.set([v[k], v[k + 1], v[k + 2]], (i + j) * 3);
      let sx = vn[k], sy = vn[k + 1], sz = vn[k + 2]; const sl = Math.hypot(sx, sy, sz) || 1; sx /= sl; sy /= sl; sz /= sl;
      const sm = sx * nx + sy * ny + sz * nz > 0.82;
      nor.set(sm ? [sx, sy, sz] : [nx, ny, nz], (i + j) * 3);
    }
  }
  return { pos, nor, n: f.length };
}

function upload(m) {
  const vao = gl.createVertexArray(); gl.bindVertexArray(vao);
  for (const [nm, data] of [['p', m.pos], ['n', m.nor]]) {
    const b = gl.createBuffer(); gl.bindBuffer(gl.ARRAY_BUFFER, b); gl.bufferData(gl.ARRAY_BUFFER, data, gl.STATIC_DRAW);
    const a = gl.getAttribLocation(pr, nm); gl.enableVertexAttribArray(a); gl.vertexAttribPointer(a, 3, gl.FLOAT, false, 0, 0);
  }
  return { vao, n: m.n };
}

const mul = (a, b) => { const o = new Float32Array(16); for (let i = 0; i < 4; i++) for (let j = 0; j < 4; j++) { let s = 0; for (let k = 0; k < 4; k++) s += a[k * 4 + j] * b[i * 4 + k]; o[i * 4 + j] = s; } return o; };
const persp = (f, a, n, fa) => { const t = 1 / Math.tan(f / 2); return new Float32Array([t / a, 0, 0, 0, 0, t, 0, 0, 0, 0, (fa + n) / (n - fa), -1, 0, 0, 2 * fa * n / (n - fa), 0]); };
function look(e, c) {
  let zx = e[0] - c[0], zy = e[1] - c[1], zz = e[2] - c[2]; let l = Math.hypot(zx, zy, zz); zx /= l; zy /= l; zz /= l;
  let xx = -zy, xy = zx, xz = 0; l = Math.hypot(xx, xy) || 1; xx /= l; xy /= l;
  const yx = zy * xz - zz * xy, yy = zz * xx - zx * xz, yz = zx * xy - zy * xx;
  return new Float32Array([xx, yx, zx, 0, xy, yy, zy, 0, xz, yz, zz, 0, -(xx * e[0] + xy * e[1] + xz * e[2]), -(yx * e[0] + yy * e[1] + yz * e[2]), -(zx * e[0] + zy * e[1] + zz * e[2]), 1]);
}
function model(p, t) {
  const r = (p.rotor === true ? 1 : +p.rotor || 0) * t, c = Math.cos(r), s = Math.sin(r);
  const [tx, ty, tz] = p.at || [0, 0, 0], [ex, ey, ez] = p.explode || [0, 0, 0], k = st.exp;
  return new Float32Array([c, s, 0, 0, -s, c, 0, 0, 0, 0, 1, 0, tx + ex * k, ty + ey * k, tz + ez * k, 1]);
}

function draw(now) {
  const dt = Math.min(0.05, (now - st.last) / 1000 || 0); st.last = now;
  st.exp += (st.expT - st.exp) * Math.min(1, dt * 4);
  if (st.run) st.ang += dt * st.rps * 2 * Math.PI;
  const w = cv.clientWidth * devicePixelRatio | 0, h = cv.clientHeight * devicePixelRatio | 0;
  if (cv.width !== w || cv.height !== h) { cv.width = w; cv.height = h; }
  gl.viewport(0, 0, w, h); gl.clearColor(0.06, 0.07, 0.085, 1); gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
  gl.enable(gl.DEPTH_TEST); gl.useProgram(pr);
  const eye = [st.tgt[0] + st.dist * Math.cos(st.pitch) * Math.cos(st.yaw), st.tgt[1] + st.dist * Math.cos(st.pitch) * Math.sin(st.yaw), st.tgt[2] + st.dist * Math.sin(st.pitch)];
  gl.uniformMatrix4fv(loc.VP, false, mul(persp(0.6, w / h, 1, 5000), look(eye, st.tgt)));
  gl.uniform3fv(loc.eye, eye);
  gl.uniform4fv(loc.clip, st.sec ? [0, -1, 0, 0] : [0, 0, 0, -1]);
  gl.uniform1i(loc.cap, st.sec ? 1 : 0);
  for (const p of st.parts) {
    if (!p.show || !p.gpu) continue;
    const M = model(p, st.ang);
    gl.uniformMatrix4fv(loc.M, false, M);
    gl.uniformMatrix3fv(loc.N, false, new Float32Array([M[0], M[1], M[2], M[4], M[5], M[6], M[8], M[9], M[10]]));
    gl.uniform3fv(loc.col, p.color);
    gl.bindVertexArray(p.gpu.vao); gl.drawArrays(gl.TRIANGLES, 0, p.gpu.n);
  }
  requestAnimationFrame(draw);
}

function ui() {
  const set = (id, on) => $(id).classList.toggle('on', on);
  $('b-asm').onclick = () => { st.expT = 0; $('s-exp').value = 0; set('b-asm', true); set('b-exp', false); };
  $('b-exp').onclick = () => { st.expT = 1; $('s-exp').value = 1; set('b-asm', false); set('b-exp', true); };
  $('b-sec').onclick = () => { st.sec = !st.sec; set('b-sec', st.sec); };
  $('b-run').onclick = () => { st.run = !st.run; set('b-run', st.run); };
  $('s-exp').oninput = e => { st.expT = +e.target.value; };
  $('s-rpm').oninput = e => { st.rps = +e.target.value; $('v-rpm').textContent = st.rps.toFixed(1); };
  $('v-rpm').textContent = st.rps.toFixed(1);
  $('b-shot').onclick = () => cv.toBlob(b => save(b, (st.scene.name || 'bendcad') + '.png'));
  $('b-rec').onclick = () => {
    const rec = new MediaRecorder(cv.captureStream(60), { mimeType: 'video/webm;codecs=vp9' }), ch = [];
    rec.ondataavailable = e => ch.push(e.data);
    rec.onstop = () => save(new Blob(ch, { type: 'video/webm' }), (st.scene.name || 'bendcad') + '-run.webm');
    if (!st.run) $('b-run').onclick();
    rec.start(); $('status').textContent = 'recording'; setTimeout(() => { rec.stop(); $('status').textContent = 'saved'; }, 6000);
  };
  let drag = null;
  cv.onpointerdown = e => { drag = [e.clientX, e.clientY, e.button]; cv.setPointerCapture(e.pointerId); };
  cv.onpointerup = () => { drag = null; };
  cv.onpointermove = e => {
    if (!drag) return;
    const dx = e.clientX - drag[0], dy = e.clientY - drag[1]; drag[0] = e.clientX; drag[1] = e.clientY;
    if (drag[2] === 0 && !e.shiftKey) { st.yaw -= dx * 0.008; st.pitch = Math.max(-1.5, Math.min(1.5, st.pitch + dy * 0.008)); }
    else { const k = st.dist * 0.0015; st.tgt[2] += dy * k; st.tgt[0] -= dx * k * Math.sin(st.yaw); st.tgt[1] += dx * k * Math.cos(st.yaw); }
  };
  cv.onwheel = e => { e.preventDefault(); st.dist *= Math.exp(e.deltaY * 0.001); };
}

function save(b, n) { const a = document.createElement('a'); a.href = URL.createObjectURL(b); a.download = n; a.click(); }

async function main() {
  ui();
  const q = new URLSearchParams(location.search), src = q.get('scene') || 'scene.json';
  const scene = await (await fetch(src)).json(); st.scene = scene;
  $('name').textContent = scene.name || 'BendCAD Viewer';
  $('title').textContent = scene.subtitle || '';
  Object.assign(st, scene.view || {});
  if (q.get('mode') === 'exploded') { st.exp = st.expT = 1; }
  if (q.get('section') === '1') st.sec = true;
  if (q.get('run') === '1') st.run = true;
  const base = src.slice(0, src.lastIndexOf('/') + 1);
  st.parts = scene.parts.map(p => Object.assign({ show: true, color: [0.7, 0.72, 0.75] }, p));
  const list = $('parts');
  for (const p of st.parts) {
    const d = document.createElement('div'), cb = document.createElement('input'), sw = document.createElement('span');
    cb.type = 'checkbox'; cb.checked = true; cb.onchange = () => { p.show = cb.checked; };
    sw.className = 'sw'; sw.style.background = `rgb(${p.color.map(c => c * 255 | 0)})`;
    d.append(cb, sw, document.createTextNode(p.name)); list.append(d);
  }
  let done = 0;
  await Promise.all(st.parts.map(async p => {
    p.gpu = upload(parseObj(await (await fetch(base + p.mesh)).text()));
    done++; $('status').textContent = `${done}/${st.parts.length} parts`;
  }));
  $('status').textContent = `${st.parts.length} parts | ${st.parts.reduce((s, p) => s + p.gpu.n / 3, 0)} triangles`;
  document.body.dataset.ready = '1';
  requestAnimationFrame(draw);
}
main().catch(e => { $('status').textContent = 'error: ' + e; });
