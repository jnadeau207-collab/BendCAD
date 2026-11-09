import { spawnSync } from 'node:child_process';
import { createRequire } from 'node:module';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const PW = process.env.PLAYWRIGHT_CORE || 'C:/dev/Aethalgard_CAD/node_modules/.pnpm/playwright-core@1.62.1/node_modules/playwright-core';
const { chromium } = require(PW);
const BIN = process.env.G5_BIN || '/home/jesse/bc/bendcad';
const PORT = +(process.env.G5_VIEW_PORT || 8792);
const SCENE = process.argv[2] || 'g5/scene.json';
const FACES = process.argv[3] || '';
const OUT = path.resolve(process.argv[4] || path.join(ROOT, 'docs/receipts/g5/viewer'));
const CHROME = process.env.CHROME || 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const WROOT = '/mnt/' + ROOT[0].toLowerCase() + ROOT.slice(2).replace(/\\/g, '/');

const wsl = cmd => spawnSync('wsl.exe', ['-e', 'bash', '-lc', cmd], { encoding: 'utf8' });
fs.mkdirSync(OUT, { recursive: true });
const rep = { scene: SCENE, faces_scene: FACES, binary: BIN, sha256: wsl(`sha256sum ${BIN}`).stdout.split(' ')[0], checks: [], shots: [] };
const chk = (name, ok, extra = {}) => { rep.checks.push({ name, ok: !!ok, ...extra }); console.log(`${ok ? 'PASS' : 'FAIL'} ${name}`, Object.keys(extra).length ? JSON.stringify(extra) : ''); };

wsl(`cd /var/tmp && setsid ${BIN} view ${PORT} ${WROOT}/viewer < /dev/null > /var/tmp/e2e_viewer.log 2>&1 & sleep 1`);
const pid = wsl(`pgrep -f '^${BIN} view ${PORT}'`).stdout.trim().split(/\s+/)[0];

const browser = await chromium.launch({ executablePath: CHROME, headless: true, args: ['--enable-gpu', '--ignore-gpu-blocklist', '--use-angle=d3d11', '--enable-unsafe-swiftshader=false'] });
try {
  const page = await browser.newPage({ viewport: { width: 1920, height: 1080 }, deviceScaleFactor: 1 });
  const errors = [];
  page.on('pageerror', e => errors.push(String(e)));
  page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
  const shot = async (name, note) => {
    await page.evaluate(() => new Promise(r => requestAnimationFrame(() => requestAnimationFrame(r))));
    const f = path.join(OUT, name + '.png');
    await page.screenshot({ path: f });
    rep.shots.push({ file: path.relative(ROOT, f).replace(/\\/g, '/'), note });
  };
  const ev = (f, a) => page.evaluate(f, a);
  const settle = ms => page.waitForTimeout(ms);

  const t0 = Date.now();
  await page.goto(`http://127.0.0.1:${PORT}/?scene=${SCENE}`);
  await page.waitForFunction(() => document.body.dataset.ready === '1', null, { timeout: 600000 });
  const info = await ev(() => ({ n: bcv.st.parts.length, tris: bcv.st.parts.reduce((s, p) => s + p.info.tris, 0), loadMs: bcv.st.loadMs, gpu: bcv.gpu(), faces: bcv.st.parts.reduce((s, p) => s + p.info.kinds.length, 0) }));
  chk('all parts load and mesh', info.n > 0, { parts: info.n, tris: info.tris, load_ms: info.loadMs, wall_ms: Date.now() - t0 });
  chk('hardware WebGL renderer', !/swiftshader|llvmpipe|software/i.test(info.gpu), { gpu: info.gpu });
  await settle(1500);
  const ms = await ev(() => bcv.bench(20));
  chk('full studio frame (MSAA + GTAO + outlines) under 50 ms at 1080p', ms < 50, { frame_ms: +ms.toFixed(2) });
  await shot('01-assembled-iso', 'Assembled, isometric, studio lighting, B-rep edges');

  const c = { x: 960, y: 540 };
  const hit = await ev(([x, y]) => { const h = bcv.pick(x, y); return h && { name: h.part.name, face: h.face }; }, [c.x, c.y]);
  chk('GPU pick at screen centre hits a part', !!hit, hit || {});
  await page.mouse.move(c.x, c.y); await settle(300);
  const hov = await ev(() => bcv.st.hov && bcv.st.hov.name);
  chk('hover highlights the part under the cursor', hov === (hit && hit.name), { hovered: hov });
  await page.mouse.click(c.x, c.y); await settle(400);
  const sel = await ev(() => ({ sel: [...bcv.st.sel].map(p => p.name), props: !document.getElementById('props').hidden, title: document.querySelector('#props h3')?.textContent }));
  chk('click selects the part and opens its properties', sel.sel.length === 1 && sel.props && sel.title, sel);
  await shot('02-selected', `Selected ${sel.title}: outline, accent edges, properties`);
  await page.keyboard.press('Escape'); await settle(200);

  const cam0 = await ev(() => bcv.camera());
  const piv = await ev(([x, y]) => { const h = bcv.pick(x, y); return h ? h.point.toArray() : bcv.st.target.toArray(); }, [c.x, c.y]);
  await page.mouse.move(c.x, c.y); await page.mouse.down(); await page.mouse.move(c.x + 220, c.y - 60, { steps: 12 }); await page.mouse.up(); await settle(200);
  const cam1 = await ev(() => bcv.camera());
  const d = (a, b) => Math.hypot(a[0] - b[0], a[1] - b[1], a[2] - b[2]);
  chk('left drag orbits about the picked point', d(cam0.pos, cam1.pos) > 10 && Math.abs(d(cam0.pos, piv) - d(cam1.pos, piv)) < 1e-6 * d(cam0.pos, piv) + 1e-3,
    { moved_mm: +d(cam0.pos, cam1.pos).toFixed(2), pivot_dist_before: +d(cam0.pos, piv).toFixed(4), pivot_dist_after: +d(cam1.pos, piv).toFixed(4) });
  await page.mouse.move(c.x, c.y); await page.mouse.down({ button: 'right' }); await page.mouse.move(c.x - 150, c.y + 40, { steps: 8 }); await page.mouse.up({ button: 'right' }); await settle(200);
  const cam2 = await ev(() => bcv.camera());
  chk('right drag pans view and target together', d(cam1.tgt, cam2.tgt) > 1 && Math.abs(d(cam1.pos, cam1.tgt) - d(cam2.pos, cam2.tgt)) < 1e-6 * d(cam1.pos, cam1.tgt) + 1e-6,
    { target_moved_mm: +d(cam1.tgt, cam2.tgt).toFixed(2) });
  await page.mouse.move(c.x, c.y);
  for (let k = 0; k < 4; k++) { await page.mouse.wheel(0, -240); await settle(60); }
  const cam3 = await ev(() => bcv.camera());
  chk('wheel zooms toward the cursor', d(cam3.pos, cam3.tgt) < d(cam2.pos, cam2.tgt) * 0.6, { dist_before: +d(cam2.pos, cam2.tgt).toFixed(1), dist_after: +d(cam3.pos, cam3.tgt).toFixed(1) });
  await page.keyboard.press('f'); await settle(800);
  const proj = await ev(() => bcv.projectedBounds());
  chk('F fits the whole assembly inside the viewport', proj.minx >= 0 && proj.miny >= 0 && proj.maxx <= 1920 && proj.maxy <= 1080, proj);

  await ev(() => bcv.view('front')); await settle(800);
  const cf = await ev(() => bcv.camera());
  const dir = [cf.pos[0] - cf.tgt[0], cf.pos[1] - cf.tgt[1], cf.pos[2] - cf.tgt[2]], dl = Math.hypot(...dir);
  chk('Front standard view looks along +Y', dir[1] / dl < -0.999, { dir: dir.map(v => +(v / dl).toFixed(4)) });
  await ev(() => bcv.view('iso')); await settle(800);
  await page.click('#cube', { position: { x: 60, y: 60 } }); await settle(800);
  const cc = await ev(() => bcv.camera());
  const cd = [cc.pos[0] - cc.tgt[0], cc.pos[1] - cc.tgt[1], cc.pos[2] - cc.tgt[2]], cl = Math.hypot(...cd);
  chk('view cube click snaps to an axis-aligned view', Math.max(...cd.map(v => Math.abs(v / cl))) > 0.999, { dir: cd.map(v => +(v / cl).toFixed(4)) });
  await ev(() => bcv.view('front')); await settle(800);
  await page.keyboard.press('p'); await settle(300);
  const orth = await ev(() => bcv.camera().ortho);
  await shot('03-ortho-front', 'Orthographic projection, front view');
  await page.keyboard.press('p'); await settle(200);
  chk('P toggles orthographic projection', orth === true);

  await ev(() => bcv.view('iso')); await settle(700);
  await page.click('#b-sec'); await settle(800);
  const sec = await ev(() => ({ on: bcv.st.sec, caps: bcv.st.parts.filter(p => p.cap.visible).length, flip: bcv.st.secFlip }));
  chk('section cuts with capped faces', sec.on && sec.caps === info.n, sec);
  await shot('04-section', 'Half section through the axis, hatched caps per part');
  await ev(() => { document.querySelector('[data-ax="x"]').click(); }); await settle(400);
  await shot('05-section-x', 'Section on X');
  await page.click('#b-sec'); await settle(300);

  await ev(() => { bcv.view('front'); }); await settle(800);
  await page.keyboard.press('p'); await settle(300);
  await ev(() => bcv.fit()); await settle(800);
  const cb = await ev(() => { const b = bcv.boxes().find(x => x.name === 'casing'); return bcv.screenOf([[b.lo[0], b.lo[1], (b.lo[2] + b.hi[2]) / 2], [b.hi[0], b.lo[1], (b.lo[2] + b.hi[2]) / 2]]); });
  await page.keyboard.press('m');
  const my = Math.round(cb[0][1]), mxa = Math.round(cb[0][0] + (cb[1][0] - cb[0][0]) * 0.2), mxb = Math.round(cb[0][0] + (cb[1][0] - cb[0][0]) * 0.8);
  await page.mouse.click(mxa, my); await settle(150); await page.mouse.click(mxb, my); await settle(400);
  const me = await ev(() => bcv.st.meas && bcv.st.meas.map(m => ({ part: m.part.name, r: Math.hypot(m.p.x, m.p.y), p: m.p.toArray() })));
  const lab = await ev(() => { const e = document.querySelector('#meas .mlab'); if (!e) return null; for (let n = e; n && n.nodeType === 1; n = n.parentElement) if (+getComputedStyle(n).opacity === 0 || getComputedStyle(n).display === 'none') return null; const r = e.getBoundingClientRect(); return r.width > 0 ? e.querySelector('b').textContent : null; });
  chk('measure: two picks on the casing land on the kernel 54 mm outer radius', me && me.length === 2 && me.every(m => m.part === 'casing' && Math.abs(m.r - 54) < 0.3) && lab,
    { radii: me && me.map(m => +m.r.toFixed(3)), label: lab });
  await shot('05b-measure', 'Measure tool, front orthographic');
  await page.keyboard.press('Escape'); await page.keyboard.press('p'); await settle(300);
  await ev(() => bcv.view('iso')); await settle(800);
  await page.click('#b-exp'); await settle(4000);
  const bx = await ev(() => bcv.boxes());
  const ov = [];
  for (let i = 0; i < bx.length; i++) for (let j = i + 1; j < bx.length; j++) {
    const a = bx[i], b = bx[j];
    if ([0, 1, 2].every(k => a.lo[k] < b.hi[k] - 0.01 && b.lo[k] < a.hi[k] - 0.01)) ov.push([a.name, b.name]);
  }
  chk('exploded view: no two part envelopes overlap', ov.length === 0, { overlapping_pairs: ov.length, pairs: ov.slice(0, 8) });
  await shot('06-exploded', 'Exploded: two lanes, axial stacking, leader lines, labels');
  await ev(() => bcv.view('front')); await settle(900);
  await shot('07-exploded-front', 'Exploded, front view');
  await page.click('#b-exp'); await settle(3500);

  await ev(() => bcv.setMode('xray')); await settle(300);
  await ev(([x, y]) => { const h = bcv.pick(x, y); if (h) bcv.select(h.part); }, [960, 540]);
  await shot('08-xray', 'X-ray with one part selected');
  await ev(() => { bcv.setMode('edges'); bcv.select(null); });

  await ev(() => bcv.setScheme('day')); await settle(600);
  await ev(() => bcv.view('iso')); await settle(700);
  await shot('09-day', 'Day studio');
  await ev(() => bcv.setScheme('night')); await settle(400);

  const snap = await ev(async () => { const b = await bcv.snapshot(); const im = await createImageBitmap(b); return { bytes: b.size, w: im.width, h: im.height }; });
  chk('4K snapshot renders 3840x2160', snap.w === 3840 && snap.h === 2160 && snap.bytes > 100000, snap);

  if (FACES) {
    await page.goto(`http://127.0.0.1:${PORT}/?scene=${FACES}`);
    await page.waitForFunction(() => document.body.dataset.ready === '1', null, { timeout: 600000 });
    await settle(1000);
    const fi = await ev(() => ({ tagged: bcv.st.parts.filter(p => p.info.kinds.length > 0).length, n: bcv.st.parts.length, faces: bcv.st.parts.reduce((s, p) => s + p.info.kinds.length, 0) }));
    chk('every part carries kernel B-rep face tags', fi.tagged === fi.n, fi);
    await ev(() => bcv.setSelMode('face'));
    await page.mouse.click(960, 540); await settle(400);
    const fs_ = await ev(() => bcv.st.face && { part: bcv.st.face.part.name, face: bcv.st.face.face, kind: bcv.st.face.part.info.kinds[bcv.st.face.face], area: bcv.st.face.part.info.farea[bcv.st.face.face] });
    chk('face mode selects a single B-rep face with its surface type', fs_ && fs_.face >= 0 && fs_.kind, fs_ || {});
    await shot('10-face-select', `Face ${fs_ && fs_.face} (${fs_ && fs_.kind}) selected`);
  }
  chk('no page errors', errors.length === 0, { errors: errors.slice(0, 5) });
} finally {
  await browser.close();
  if (pid) wsl(`kill ${pid}`);
}
rep.pass = rep.checks.every(c => c.ok);
fs.writeFileSync(path.join(OUT, 'e2e_viewer.json'), JSON.stringify(rep, null, 1));
console.log(rep.pass ? 'PASS' : 'FAIL', rep.checks.filter(c => c.ok).length, '/', rep.checks.length);
process.exit(rep.pass ? 0 : 1);
