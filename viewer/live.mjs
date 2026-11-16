import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const args = process.argv.slice(2);
const opt = (k, d) => { const i = args.indexOf(k); return i >= 0 ? args.splice(i, 2)[1] : d; };
const PORT = +opt('--port', process.env.BCL_PORT || 8790);
const BIN = opt('--bin', process.env.BENDCAD_BIN || '/home/jesse/bc/bendcad');
const PROC = opt('--proc', 'mill');
const toWsl = p => /^[A-Za-z]:[\\/]/.test(p) ? '/mnt/' + p[0].toLowerCase() + p.slice(2).replace(/\\/g, '/') : p.replace(/\\/g, '/');
const DESIGN = toWsl(args[0] || '');
if (!DESIGN) { console.error('usage: node viewer/live.mjs DESIGN.bcd [--port N] [--bin KERNEL] [--proc mill|lathe|fdm|sla]'); process.exit(2); }
const CACHE = '/var/tmp/bcl-live-' + crypto.createHash('sha1').update(DESIGN + PORT).digest('hex').slice(0, 10);
const onWin = process.platform === 'win32';
const PRIM = new Set(['prism', 'box', 'cylinder', 'revolve', 'cone', 'sphere', 'torus', 'import', 'flat', 'naca4', 'blade', 'loft', 'loft-open', 'sweep', 'sweep-open', 'patch']);
const BOOL = new Set(['union', 'difference', 'intersection']);
const TYPES = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.css': 'text/css', '.svg': 'image/svg+xml', '.png': 'image/png', '.json': 'application/json' };

function run(argv, stdin) {
  return new Promise(res => {
    const cmd = onWin ? 'wsl.exe' : argv[0], a = onWin ? ['-e', ...argv] : argv.slice(1);
    const p = spawn(cmd, a, { stdio: ['pipe', 'pipe', 'pipe'] });
    const out = [], err = [];
    p.stdout.on('data', d => out.push(d)); p.stderr.on('data', d => err.push(d));
    p.on('close', code => res({ code, out: Buffer.concat(out).toString('utf8') + Buffer.concat(err).toString('utf8') }));
    if (stdin) p.stdin.end(stdin); else p.stdin.end();
  });
}
let chain = Promise.resolve(), gen = 0;
const queue = f => (chain = chain.then(f, f));
const kernel = (...a) => queue(async () => { const t0 = Date.now(); const r = await run([BIN, DESIGN, ...a]); r.ms = Date.now() - t0; return r; });
const NEAR = 1, CAP = 20;
const kernelIf = (g, ...a) => queue(async () => {
  if (g !== gen) return { skipped: true, out: '', ms: 0 };
  const t0 = Date.now(); const r = await run(['timeout', String(CAP), BIN, DESIGN, ...a]); r.ms = Date.now() - t0; return r;
});

function parseShow(txt) {
  const params = [], nodes = [];
  for (const ln of txt.split('\n')) {
    let m = ln.match(/^\(param (\d+) (\S+) (\S+) (\S+) (\S+)(?: (\S+))?\)$/);
    if (m) { params.push({ id: +m[1], name: m[2], value: m[3], lo: m[4], hi: m[5], cls: m[6] || null }); continue; }
    m = ln.match(/^\(node (\d+) \((\S+)(.*)\)$/);
    if (m) nodes.push({ id: +m[1], op: m[2], text: ln });
  }
  const pos = new Map(nodes.map((n, i) => [n.id, i])), used = new Set();
  for (const n of nodes) {
    if (PRIM.has(n.op)) continue;
    const body = n.text.slice(n.text.indexOf('(' + n.op) + n.op.length + 1);
    const nums = [...body.matchAll(/(?:^|[\s(])(\d+)(?=[\s)])/g)].map(x => +x[1]).filter(x => pos.has(x) && pos.get(x) < pos.get(n.id));
    nums.slice(0, BOOL.has(n.op) ? 2 : 1).forEach(x => used.add(x));
    n.base = nums.slice(0, BOOL.has(n.op) ? 2 : 1);
  }
  return { params, nodes, parts: nodes.filter(n => !used.has(n.id)).map(n => n.id) };
}
function parseEval(txt) {
  const r = {};
  for (const ln of txt.split('\n')) {
    const m = ln.match(/^node (\d+): (\S+)(.*)$/);
    if (!m) continue;
    const e = { status: m[2], line: ln.trim() };
    const v = ln.match(/volume=\[(\S+), (\S+)\]/), b = ln.match(/bbox=\[(\S+), (\S+)\]x\[(\S+), (\S+)\]x\[(\S+), (\S+)\]/);
    const a = ln.match(/ area=\[(\S+), (\S+)\]/);
    if (v) e.volume = [+v[1], +v[2]];
    if (a) e.area = [+a[1], +a[2]];
    if (b) e.bbox = b.slice(1).map(Number);
    const w = ln.match(/why: ([^|]*)/); if (w) e.why = w[1].trim();
    r[+m[1]] = e;
  }
  return r;
}
const segs = out => {
  const p = out.split(/^== (.*)$/m), r = [];
  for (let i = 1; i < p.length; i += 2) r.push(p[i + 1].replace(/^batch done\s*$/m, '').trim());
  return r;
};
const batch = (...vs) => kernel('batch', ...vs.flatMap((v, i) => i ? ['::', ...v] : v));
let doc = null;
const meshes = new Map();
const objOf = (f, t) => {
  let p = null;
  return () => p || (p = /^wrote /.test(t) ? run(['cat', f]).then(c => ({ ok: true, obj: c.out, out: t })) : Promise.resolve({ ok: false, out: t }));
};
async function loadDoc() {
  const s = await kernel('show');
  const rev = crypto.createHash('sha1').update(s.out).digest('hex').slice(0, 12);
  if (doc && doc.rev === rev) return doc;
  const d = parseShow(s.out);
  d.rev = rev; d.file = DESIGN; d.name = path.basename(DESIGN, '.bcd'); d.proc = PROC;
  await run(['mkdir', '-p', CACHE]);
  const files = d.parts.map(id => `${CACHE}/${rev}-${id}.obj`);
  const b = await batch(['eval'], ...d.parts.map((id, i) => ['tess', String(id), files[i]]));
  const sg = segs(b.out), ev = parseEval(sg[0] || '');
  d.eval_ms = b.ms;
  for (const n of d.nodes) Object.assign(n, ev[n.id] || { status: 'unknown' });
  d.parts.forEach((id, i) => meshes.set(rev + ':' + id, objOf(files[i], sg[i + 1] || b.out.trim())));
  doc = d;
  return d;
}
async function mesh(node, rev) {
  const k = rev + ':' + node;
  if (!meshes.has(k)) {
    const f = `${CACHE}/${rev}-${node}.obj`;
    await run(['mkdir', '-p', CACHE]);
    const t = await kernel('tess', String(node), f);
    meshes.set(k, objOf(f, t.out.trim()));
  }
  return meshes.get(k)();
}
const statusOf = ln => (ln.match(/status=(pass|fail|not-analyzed)$/) || [])[1];
const ivs = t => [...t.matchAll(/\[(\S+), (\S+)\]/g)].map(x => [+x[1], +x[2]]);
function parseMass(txt) {
  const mo = txt.match(/^moments (.*) status=(\S+) method=(\S+)$/m), ma = txt.match(/^material (\S+) density=(\S+) cte=(\S+) mass=\[(\S+), (\S+)\] kg status=(\S+)$/m);
  const c = mo ? ivs(mo[1].slice(mo[1].indexOf('centroid'), mo[1].indexOf('inertia-centroid'))) : [];
  return { centroid: c.length === 3 ? c : null, cstatus: mo ? mo[2] : 'not-analyzed', method: mo ? mo[3] : '',
    material: ma ? { grade: ma[1], density: +ma[2], cte: +ma[3], mass: [+ma[4], +ma[5]], status: ma[6] } : null };
}
async function checks(node, proc) {
  const n = String(node), b = await batch(['mass', n, '0'], ['check', n], ['std', n], ['make', n, proc]);
  const sg = segs(b.out), [k, c, s, m] = [0, 1, 2, 3].map(i => sg[i] === undefined ? b.out.trim() : sg[i]);
  const ok = /^ok:/.test(c);
  const std = s.split('\n').filter(l => /^std (hole|groove|key|thread)/.test(l) || /status=/.test(l)).map(l => ({ text: l.trim(), status: (l.match(/status=(\S+)/) || [])[1] }));
  const mk = m.split('\n').filter(l => /^make (face|corner)/.test(l)).map(l => ({ text: l.trim(), status: statusOf(l.trim()) }));
  const verdict = (m.match(/^verdict (\S+)/m) || [])[1] || 'refused';
  return { node, proc, ms: b.ms, mass: parseMass(k), check: { status: ok ? 'pass' : 'fail', text: c.split('\n')[0] },
    std: { lines: std, summary: (s.match(/^std node .*$/m) || [''])[0] },
    make: { verdict, lines: mk, summary: (m.match(/^make node \d+: .*$/m) || [''])[0], head: mk.length ? '' : m.slice(0, 300) } };
}
const boxGap = (a, b) => Math.max(0, b[0] - a[1], a[0] - b[1], b[2] - a[3], a[2] - b[3], b[4] - a[5], a[4] - b[5]);
function parseClear(out, code) {
  const m = out.match(/^clearance \[(\S+), (\S+)\] (\S+)(.*)$/m);
  if (m) return { kind: /state=inside/.test(m[4]) ? 'inside' : 'clearance', lo: +m[1], hi: +m[2], status: m[3], text: m[0] };
  const z = out.match(/^clearance 0 status=(\S+) state=(\S+)$/m);
  if (z) return { kind: z[2], lo: 0, hi: 0, status: z[1], text: z[0] };
  if (code === 124) return { kind: 'timeout', status: 'not-analyzed', text: `no answer in ${CAP} s` };
  return { kind: 'error', status: 'not-analyzed', text: out.trim().split('\n').pop() };
}
async function near(node) {
  const d = doc, g = gen, me = d.nodes.find(n => n.id === node);
  const rows = [];
  for (const id of d.parts.filter(p => p !== node)) {
    const o = d.nodes.find(n => n.id === id), gap = me && me.bbox && o.bbox ? boxGap(me.bbox, o.bbox) : 0;
    if (gap > NEAR) { rows.push({ node: id, op: o.op, kind: 'apart', lo: gap, status: 'certified', text: `enclosing boxes ${gap.toFixed(3)} mm apart`, ms: 0 }); continue; }
    const r = await kernelIf(g, 'clearance', String(node), String(id));
    if (r.skipped) return { node, rev: d.rev, stale: true, rows };
    rows.push(Object.assign({ node: id, op: o.op, ms: r.ms }, parseClear(r.out, r.code)));
  }
  return { node, rev: d.rev, stale: false, rows };
}
const send = (res, code, body, type = 'application/json') => { res.writeHead(code, { 'content-type': type, 'cache-control': 'no-store' }); res.end(typeof body === 'string' || Buffer.isBuffer(body) ? body : JSON.stringify(body)); };
const body = req => new Promise(r => { const b = []; req.on('data', d => b.push(d)); req.on('end', () => r(Buffer.concat(b).toString('utf8'))); });

http.createServer(async (req, res) => {
  try {
    const u = new URL(req.url, 'http://x');
    if (u.pathname === '/api/doc') return send(res, 200, await loadDoc());
    if (u.pathname === '/api/edit' && req.method === 'POST') {
      const { edit } = JSON.parse(await body(req));
      if (typeof edit !== 'string' || !edit.startsWith('(')) return send(res, 400, { ok: false, out: 'edit must be one s-expression' });
      gen++;
      const r = await kernel('apply', edit);
      const ok = /^committed/m.test(r.out);
      const why = r.out.split('\n').map(l => l.trim()).filter(l => /^node \d+: (error|refused)/.test(l) || /^(rejected|refused|error)\b/.test(l));
      const d = await loadDoc();
      return send(res, 200, { ok, out: r.out.trim(), why: ok ? [] : why.length ? why : [r.out.trim().split('\n').pop()], ms: r.ms, doc: d });
    }
    let m = u.pathname.match(/^\/api\/mesh\/(\d+)\.obj$/);
    if (m) {
      const r = await mesh(+m[1], u.searchParams.get('rev') || (doc && doc.rev) || '0');
      return r.ok ? send(res, 200, r.obj, 'text/plain') : send(res, 422, r.out, 'text/plain');
    }
    m = u.pathname.match(/^\/api\/checks\/(\d+)$/);
    if (m) return send(res, 200, await checks(+m[1], u.searchParams.get('proc') || PROC));
    m = u.pathname.match(/^\/api\/near\/(\d+)$/);
    if (m) { if (!doc) await loadDoc(); return send(res, 200, await near(+m[1])); }
    const rel = decodeURIComponent(u.pathname === '/' ? '/index.html' : u.pathname);
    const f = path.normalize(path.join(HERE, rel));
    if (!f.startsWith(HERE) || !fs.existsSync(f) || fs.statSync(f).isDirectory()) return send(res, 404, 'not found', 'text/plain');
    return send(res, 200, fs.readFileSync(f), TYPES[path.extname(f)] || 'application/octet-stream');
  } catch (e) { send(res, 500, { ok: false, out: String(e && e.stack || e) }); }
}).listen(PORT, '127.0.0.1', () => console.log(`BendCAD live: http://127.0.0.1:${PORT}/?live=1  design ${DESIGN}  kernel ${BIN}`));
