import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { startLive, browser, ready, settle, coverage, inspect } from '../../tools/viewer/inspect.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const BIN = process.env.BENDCAD_BIN || '/home/jesse/bc/bendcad';
const PORT = +(process.env.BCL_PORT || 8796);
const OUT = path.resolve(process.env.LIVE_OUT || path.join(ROOT, 'docs', 'receipts', 'viewer'));
const DESIGN = '/var/tmp/viewer-e2e/fit.bcd';
const EDITS = ['(param D 10 10 10.015)', '(param C 0.1)', '(node 1 (box 40 30 8) (intent create any 0 1 0))',
  '(node 2 (holes 1 (face 1 0 top) through (hole 20 15 (/ D 2))) (intent remove any any 1 1))',
  '(node 3 (cylinder (- (/ D 2) C) 20) (intent create any 0 1 0))', '(node 4 (move 3 20 15 -6 0) (intent same any any 1 0))',
  '(node 5 (box 10 10 8) (intent create any 0 1 0))', '(node 6 (move 5 60 0 0 0) (intent same any any 1 0))',
  '(material 2 6061-T6 2700 23.6e-6 68900 0.33)'];
const nearOf = (L, id) => L.near && L.near.rows.find(r => r.node === id);
const waitNear = (page, node) => page.waitForFunction(n => { const l = window.bcv.live(); return l.near && l.near.node === n && !l.nearing && !l.busy; }, node, { timeout: 120000 });
const PLATE = d => 9600 - Math.PI * d * d / 4 * 8;

const wsl = (...a) => spawnSync('wsl.exe', ['-e', ...a], { encoding: 'utf8' });
fs.mkdirSync(OUT, { recursive: true });
const rep = { binary: BIN, sha256: wsl('sha256sum', BIN).stdout.split(' ')[0], design: EDITS, checks: [], shots: [], timings: {} };
const chk = (name, ok, extra = {}) => { rep.checks.push({ name, ok: !!ok, ...extra }); console.log(`${ok ? 'PASS' : 'FAIL'} ${name}`, Object.keys(extra).length ? JSON.stringify(extra) : ''); };
const near = (a, b, t = 1e-3) => Math.abs(a - b) <= t;
const size = p => p.hi.map((h, i) => h - p.lo[i]);

wsl('bash', '-c', `mkdir -p /var/tmp/viewer-e2e && rm -f ${DESIGN}`);
wsl(BIN, DESIGN, 'new');
const ap = wsl(BIN, DESIGN, 'apply', ...EDITS);
chk('fixture design committed', /^committed/m.test(ap.stdout), { out: ap.stdout.trim().slice(-200) });

const live = await startLive(DESIGN, BIN, PORT, 'mill');
const b = await browser();
try {
  const page = await b.newPage({ viewport: { width: 1600, height: 1000 } });
  const errors = [];
  page.on('pageerror', e => errors.push(String(e)));
  page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
  const shot = async (name, note) => { await settle(page); const f = path.join(OUT, name + '.png'); await page.screenshot({ path: f }); rep.shots.push({ file: path.relative(ROOT, f).replace(/\\/g, '/'), note }); };
  const t0 = Date.now();
  await ready(page, live.url);
  rep.timings.open_ms = Date.now() - t0;
  let L = await page.evaluate(() => window.bcv.live());
  let parts = await page.evaluate(() => window.bcv.parts());
  chk('the viewer opens the design file itself: parameters, features and parts come from the kernel', L.doc.params.map(p => p.name).join() === 'D,C' && L.doc.nodes.length === 6 && L.doc.parts.join() === '2,4,6',
    { params: L.doc.params, parts: L.doc.parts });
  chk('every part is shown', parts.length === 3 && parts.every(p => p.tris > 0), { parts: parts.map(p => p.node) });
  const labels = await page.evaluate(() => window.bcv.st.parts.map(p => p.label));
  chk('a placed part is named by the feature it places, not by the move', labels.join('|') === 'Holes · node 2|Cylinder · node 4|Box · node 6', { labels });
  const pin0 = parts.find(p => p.node === 4), plate0 = parts.find(p => p.node === 2);
  chk('pin diameter is D - 0.2 = 9.8 from its mesh box', near(size(pin0)[0], 9.8, 0.06), { size: size(pin0) });
  chk('the feature tree lists every node with its op and status', await page.locator('#live .feat').count() === 6 && await page.locator('#live .feat.part').count() === 3);
  await waitNear(page, 2);
  L = await page.evaluate(() => window.bcv.live());
  const n4 = nearOf(L, 4), n6 = nearOf(L, 6);
  chk('neighbours: the pin in the hole has a certified 0.1 mm clearance', n4 && n4.kind === 'clearance' && n4.status === 'certified' && n4.lo <= 0.1 + 1e-9 && n4.hi >= 0.1 - 1e-9 && n4.hi - n4.lo < 1e-6, { pin: n4 });
  chk('neighbours: the far block is bounded by its enclosing boxes without a kernel query', n6 && n6.kind === 'apart' && Math.abs(n6.lo - 20) < 1e-6 && n6.ms === 0, { block: n6 });
  chk('checks run for the selected part: check, std and make with the declared process', L.checks && L.checks.node === 2 && L.checks.check.status === 'pass' && L.checks.make.verdict === 'makeable',
    { check: L.checks && L.checks.check.text, make: L.checks && L.checks.make.summary });
  chk('the hole is checked as a drilled 10 mm hole', L.checks && L.checks.make.lines.some(l => /cylinder hole d=10 .* tool="drill 10 jobber/.test(l.text) && l.status === 'pass'));
  const vol0 = L.doc.nodes.find(n => n.id === 2).volume, m0 = L.checks.mass;
  chk('the plate volume is the kernel certified interval and holds the exact 9600 - 200 pi', vol0[0] <= PLATE(10) + 1e-6 && PLATE(10) - 1e-6 <= vol0[1] && vol0[1] - vol0[0] < 1e-6, { volume: vol0, exact: PLATE(10) });
  chk('the plate mass comes from its declared 6061-T6 (2700 kg/m3), certified', m0.material && m0.material.grade === '6061-T6' && m0.material.status === 'certified' && Math.abs((m0.material.mass[0] + m0.material.mass[1]) / 2 - PLATE(10) * 2.7e-6) < 1e-9 && m0.cstatus === 'certified',
    { material: m0.material, centroid: m0.centroid });
  const pr0 = await page.locator('#props').innerText();
  chk('the properties panel shows kernel values with their provenance, not mesh guesses', /6061-T6/.test(pr0) && /Volume\s+8[,.]?972 cm³\s+certified/i.test(pr0) && /Mass\s+24\.22 g\s+certified/i.test(pr0) && /Centroid\s+20\.00, 15\.00, 4\.00\s+certified/i.test(pr0) && !/titanium/i.test(pr0),
    { panel: pr0.replace(/\s+/g, ' ').slice(0, 400) });
  await shot('live-open', 'design opened in the viewer: parameters, feature tree, parts and checks');
  rep.coverage_open = await coverage(page);
  chk('the part is drawn (canvas coverage)', rep.coverage_open > 0.02, { coverage: rep.coverage_open });

  const rev0 = L.doc.rev, t1 = Date.now();
  await page.fill('#live input[data-p="D"]', '12');
  await page.press('#live input[data-p="D"]', 'Enter');
  await page.waitForFunction(r => document.body.dataset.rev !== r && !window.bcv.live().busy, rev0, { timeout: 120000 });
  rep.timings.edit_to_checked_ms = Date.now() - t1;
  L = await page.evaluate(() => window.bcv.live());
  parts = await page.evaluate(() => window.bcv.parts());
  const pin1 = parts.find(p => p.node === 4), plate1 = parts.find(p => p.node === 2);
  chk('a person changes a dimension in the viewer and the kernel commits it', L.last && L.last.ok && L.doc.params[0].value === '12', { out: L.last && L.last.out.slice(0, 160) });
  chk('the edit keeps the tolerance zone (10 +0.015/0 becomes 12 +0.015/0)', L.doc.params[0].lo === '12' && L.doc.params[0].hi === '12.015', { param: L.doc.params[0] });
  chk('the neighbour updates: the pin grows to 11.8', near(size(pin1)[0], 11.8, 0.06), { size: size(pin1) });
  const vol1 = L.doc.nodes.find(n => n.id === 2).volume;
  chk('the part updates: the certified plate volume drops by exactly the 10-to-12 mm ring, 88 pi = 276.46 mm3',
    near((vol0[0] + vol0[1]) / 2 - (vol1[0] + vol1[1]) / 2, Math.PI * 8 * (36 - 25), 1e-6), { dv: (vol0[0] + vol0[1]) / 2 - (vol1[0] + vol1[1]) / 2, exact: Math.PI * 88 });
  chk('the display mesh follows within 1%', near(plate0.volume - plate1.volume, Math.PI * 88, 2.8), { dv_mesh: plate0.volume - plate1.volume });
  chk('the mass follows the edit', L.checks.mass.material && Math.abs((L.checks.mass.material.mass[0] + L.checks.mass.material.mass[1]) / 2 - PLATE(12) * 2.7e-6) < 1e-9, { mass: L.checks.mass.material && L.checks.mass.material.mass });
  chk('the checks re-run on the new design', L.checks && L.checks.make.lines.some(l => /cylinder hole d=12 .* tool="drill 12 jobber/.test(l.text) && l.status === 'pass'));
  chk('edit to re-checked view within the 5 s budget', rep.timings.edit_to_checked_ms <= 5000, { ms: rep.timings.edit_to_checked_ms });
  await shot('live-edited', 'after D 10 -> 12: hole, pin and checks updated');
  await waitNear(page, 2);
  L = await page.evaluate(() => window.bcv.live());
  const n4b = nearOf(L, 4);
  chk('the neighbour check re-runs: the pin follows D and keeps its certified 0.1 mm clearance', n4b && n4b.kind === 'clearance' && n4b.lo <= 0.1 + 1e-9 && n4b.hi >= 0.1 - 1e-9 && n4b.hi - n4b.lo < 1e-6, { pin: n4b });

  const commit = async (fn, arg) => { const r = (await page.evaluate(() => window.bcv.live())).doc.rev; await page.evaluate(fn, arg); await page.waitForFunction(x => document.body.dataset.rev !== x && !window.bcv.live().busy, r, { timeout: 120000 }); return page.evaluate(() => window.bcv.live()); };
  L = await commit(e => window.bcv.liveApply(e), '(param D 12 H7)');
  const liveText = async () => (await page.locator('#live').innerText()).replace(/\s+/g, ' ');
  chk('an agent gives D the ISO 286 class H7: the kernel sets the zone for 12 mm (10 to 18 band, IT7 = 18 um) and the viewer shows the class', L.doc.params[0].cls === 'H7' && L.doc.params[0].lo === '12' && L.doc.params[0].hi === '12.018' && /H7 \(ISO 286\) zone 12 – 12\.018/.test(await liveText()), { param: L.doc.params[0] });
  const r20 = L.doc.rev;
  await page.fill('#live input[data-p="D"]', '20');
  await page.press('#live input[data-p="D"]', 'Enter');
  await page.waitForFunction(x => document.body.dataset.rev !== x && !window.bcv.live().busy, r20, { timeout: 120000 });
  L = await page.evaluate(() => window.bcv.live());
  chk('a person changes the classed dimension and the kernel recomputes the zone for the new size band (18 to 30, IT7 = 21 um) instead of shifting the old one', L.last && L.last.ok && L.doc.params[0].cls === 'H7' && L.doc.params[0].value === '20' && L.doc.params[0].lo === '20' && L.doc.params[0].hi === '20.021', { param: L.doc.params[0] });
  L = await commit(e => window.bcv.liveApply(e), '(param D 12 12 12.015)');
  chk('the typed zone replaces the class', L.doc.params[0].cls === null && L.doc.params[0].hi === '12.015', { param: L.doc.params[0] });
  await waitNear(page, 2);

  const rc = L.doc.rev, t3 = Date.now();
  await page.fill('#live input[data-p="C"]', '-0.05');
  await page.press('#live input[data-p="C"]', 'Enter');
  await page.waitForFunction(r => document.body.dataset.rev !== r, rc, { timeout: 120000 });
  await waitNear(page, 2);
  rep.timings.edit_to_neighbours_ms = Date.now() - t3;
  L = await page.evaluate(() => window.bcv.live());
  const n4c = nearOf(L, 4);
  chk('making the pin 0.05 mm oversize shows a certified interference with the plate', n4c && n4c.kind === 'interference' && n4c.status === 'certified' && await page.locator('#checks .ck.nb[data-nb="4"] .st.fail').count() === 1, { pin: n4c });
  const glow = await page.evaluate(() => window.bcv.st.parts.map(p => ({ node: p.node, e: p.mat.emissive.toArray() })));
  const g4 = glow.find(x => x.node === 4).e, g6 = glow.find(x => x.node === 6).e;
  chk('the clashing pin is marked red in the 3D view, the clear block is not', g4[0] > 0.2 && g4[1] < 0.1 && g6.every(v => v === 0), { glow });
  chk('edit to neighbour verdict within the 5 s budget', rep.timings.edit_to_neighbours_ms <= 5000, { ms: rep.timings.edit_to_neighbours_ms, clearance_ms: n4c && n4c.ms });
  await shot('live-interference', 'C = -0.05: the pin is 0.05 mm oversize and the neighbour check certifies the interference');
  const rc2 = L.doc.rev;
  await page.fill('#live input[data-p="C"]', '0.1');
  await page.press('#live input[data-p="C"]', 'Enter');
  await page.waitForFunction(r => document.body.dataset.rev !== r, rc2, { timeout: 120000 });
  await waitNear(page, 2);
  L = await page.evaluate(() => window.bcv.live());
  chk('setting C back restores the design and its 0.1 mm clearance', L.doc.rev === rc && nearOf(L, 4).kind === 'clearance');

  const rev1 = L.doc.rev;
  await page.fill('#live input[data-p="D"]', '-4');
  await page.press('#live input[data-p="D"]', 'Enter');
  await page.waitForFunction(() => window.bcv.live().last && window.bcv.live().last.ok === false && !window.bcv.live().busy, null, { timeout: 120000 });
  L = await page.evaluate(() => window.bcv.live());
  const kmsg = await page.locator('#live .kmsg.bad ul').innerText().catch(() => '');
  chk('a refused edit shows the kernel reason and fix and leaves the design as it was', L.doc.rev === rev1 && /node 2 · holes footprint @ loop 0 segment 0\s+nonpositive-radius\s+fix: use a positive radius/.test(kmsg) && /rejected: the design was not changed/.test(kmsg) && !/volume=/.test(kmsg),
    { why: L.last.why, shown: kmsg });
  chk('the input shows the committed value again', await page.inputValue('#live input[data-p="D"]') === '12');
  await shot('live-refused', 'D = -4 refused by the kernel; the design is unchanged');

  const [[px, py]] = await page.evaluate(() => window.bcv.screenOf([[20, 15, 13.5]]));
  await page.mouse.click(px, py);
  await page.waitForFunction(() => window.bcv.live().checks && window.bcv.live().checks.node === 4 && !window.bcv.live().busy, null, { timeout: 120000 });
  L = await page.evaluate(() => window.bcv.live());
  chk('clicking the pin in the 3D view selects it and the checks follow', L.checks.node === 4 && L.checks.check.status === 'pass' && (await page.evaluate(() => [...window.bcv.st.sel].map(p => p.node))).join() === '4');
  chk('a part with no declared material says so instead of guessing one', L.checks.mass.material === null && /none on node 4/.test(await page.locator('#props').innerText()));
  await page.click('#checks [data-proc="lathe"]');
  await page.waitForFunction(() => window.bcv.live().checks && window.bcv.live().checks.proc === 'lathe', null, { timeout: 120000 });
  L = await page.evaluate(() => window.bcv.live());
  chk('the process can be switched in the viewer (the pin turns on a lathe)', L.checks.make.verdict === 'makeable', { make: L.checks.make.summary });
  await shot('live-pin-lathe', 'pin selected, checked as lathe work');

  await page.keyboard.press('s');
  await settle(page, 900);
  await shot('live-section', 'section through the plate and pin');
  chk('the section view renders', await coverage(page) > 0.02);
  await page.keyboard.press('s');

  const t2 = Date.now();
  const files = await inspect(page, path.join(OUT, 'inspect'), 'fit');
  rep.timings.inspect_ms = Date.now() - t2;
  rep.inspect = files.map(f => ({ view: f.view, file: path.relative(ROOT, f.file).replace(/\\/g, '/'), mm_per_px: f.mm_per_px, mid_row: f.mid_row, coverage: f.coverage }));
  const fr = files.find(f => f.view === 'front'), wmm = fr && (fr.mid_row[1] - fr.mid_row[0] + 1) * fr.mm_per_px;
  chk('the front inspection view is a true orthographic projection: plate to far block measures 70 mm in the image', fr && Math.abs(wmm - 70) <= 2 * fr.mm_per_px, { measured_mm: wmm, mm_per_px: fr && fr.mm_per_px });
  const dims = f => { const b = fs.readFileSync(f); return [b.readUInt32BE(16), b.readUInt32BE(20)]; };
  chk('inspection views render to fixed-size image files for the agent, scene only', files.length === 4 && files.every(f => fs.statSync(f.file).size > 20000 && f.coverage > 0.01 && dims(f.file).join() === '1600,1000'), { views: rep.inspect });
  chk('inspection restores the person\'s camera and selection', await page.evaluate(() => !window.bcv.camera().ortho && [...window.bcv.st.sel].map(p => p.node).join() === '4'));
  chk('no page errors', errors.length === 0, { errors: errors.slice(0, 5) });
} finally {
  await b.close();
  live.srv.kill();
}
rep.passed = rep.checks.filter(c => c.ok).length;
rep.total = rep.checks.length;
fs.writeFileSync(path.join(OUT, 'live.json'), JSON.stringify(rep, null, 1));
console.log(`${rep.passed}/${rep.total} pass -> ${path.join(OUT, 'live.json')}`);
process.exit(rep.passed === rep.total ? 0 : 1);
