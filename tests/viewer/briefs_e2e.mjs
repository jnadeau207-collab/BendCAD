import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { startLive, browser, ready, inspect } from '../../tools/viewer/inspect.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const BIN = process.env.BENDCAD_BIN || '/home/jesse/bc/bendcad';
const PORT = +(process.env.BCL_PORT || 8797);
const SRC = process.env.BRIEF_WORK || '/var/tmp/briefs';
const WORK = '/var/tmp/viewer-briefs';
const OUT = path.resolve(process.env.LIVE_OUT || path.join(ROOT, 'docs', 'receipts', 'viewer'));
const IDS = process.argv.slice(2).length ? process.argv.slice(2) : Array.from({ length: 14 }, (_, i) => `B${i + 1}`);

const wsl = (...a) => spawnSync('wsl.exe', ['-e', ...a], { encoding: 'utf8' });
fs.mkdirSync(path.join(OUT, 'briefs'), { recursive: true });
wsl('bash', '-c', `rm -rf ${WORK} && mkdir -p ${WORK}`);
const rep = { binary: BIN, sha256: wsl('sha256sum', BIN).stdout.split(' ')[0], source: SRC, briefs: [] };
const b = await browser();
let port = PORT;
for (const id of IDS) {
  const design = `${WORK}/${id}.bcd`;
  wsl('cp', `${SRC}/${id}/design.bcd`, design);
  const row = { brief: id, checks: [] };
  const chk = (name, ok, extra = {}) => { row.checks.push({ name, ok: !!ok, ...extra }); };
  const live = await startLive(design, BIN, port++, 'mill');
  const page = await b.newPage({ viewport: { width: 1600, height: 1000 } });
  const errors = [];
  page.on('pageerror', e => errors.push(String(e)));
  page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
  try {
    const t0 = Date.now();
    await ready(page, live.url);
    row.open_ms = Date.now() - t0;
    await page.waitForFunction(() => { const l = window.bcv.live(); return l.near && !l.nearing; }, null, { timeout: 600000 });
    row.open_to_neighbours_ms = Date.now() - t0;
    const L = await page.evaluate(() => window.bcv.live());
    const parts = await page.evaluate(() => window.bcv.parts());
    row.params = L.doc.params.map(p => `${p.name}=${p.value}`);
    row.nodes = L.doc.nodes.length;
    row.parts = L.doc.parts;
    row.unmeshed = L.failed;
    chk('every part the kernel evaluates is meshed and shown', parts.length === L.doc.parts.length && L.failed.length === 0, { shown: parts.length, parts: L.doc.parts.length, failed: L.failed });
    chk('every node status comes from the kernel', L.doc.nodes.every(n => n.status && n.status !== 'unknown'), { bad: L.doc.nodes.filter(n => n.status !== 'ok').map(n => [n.id, n.status, n.why]) });
    const c = L.checks;
    row.selected = c && c.node;
    row.check = c && c.check.status;
    row.make = c && `${c.make.verdict} ${c.make.summary.replace(/^make node \d+: /, '')}`;
    row.mass = c && c.mass && { material: c.mass.material && c.mass.material.grade, centroid: c.mass.cstatus };
    row.checks_ms = c && c.ms;
    row.eval_mesh_ms = L.doc.eval_ms;
    chk('the first part is checked: check, std, make and mass answer', c && c.check.text && c.make.verdict && c.mass, {});
    row.neighbours = L.near.rows.map(r => ({ node: r.node, kind: r.kind, status: r.status, lo: r.lo, hi: r.hi, ms: r.ms, text: r.kind === 'timeout' || r.kind === 'error' ? r.text : undefined }));
    chk('every other part has a neighbour verdict', L.near.rows.length === L.doc.parts.length - 1, { rows: L.near.rows.length });
    const files = await inspect(page, path.join(OUT, 'briefs'), id, ['iso'], [800, 500]);
    row.render = path.relative(ROOT, files[0].file).replace(/\\/g, '/');
    chk('the iso inspection render shows the parts', files[0].coverage > 0.01, { coverage: files[0].coverage });
  } catch (e) {
    chk('the viewer opened the brief', false, { error: String(e).slice(0, 400) });
  } finally {
    chk('no page errors', errors.length === 0, { errors: errors.slice(0, 5) });
    await page.close();
    live.srv.kill();
  }
  row.ok = row.checks.every(x => x.ok);
  rep.briefs.push(row);
  const nb = (row.neighbours || []).map(n => `${n.node}:${n.kind}${n.ms ? '/' + (n.ms / 1000).toFixed(1) + 's' : ''}`).join(' ');
  console.log(`${row.ok ? 'PASS' : 'FAIL'} ${id} parts=${(row.parts || []).join(',')} open=${row.open_ms}ms all=${row.open_to_neighbours_ms}ms make=${row.make} near=[${nb}]${row.ok ? '' : ' ' + JSON.stringify(row.checks.filter(x => !x.ok))}`);
}
await b.close();
wsl('rm', '-rf', WORK);
rep.passed = rep.briefs.filter(r => r.ok).length;
rep.total = rep.briefs.length;
fs.writeFileSync(path.join(OUT, 'briefs.json'), JSON.stringify(rep, null, 1));
console.log(`${rep.passed}/${rep.total} briefs open live -> ${path.join(OUT, 'briefs.json')}`);
process.exit(rep.passed === rep.total ? 0 : 1);
