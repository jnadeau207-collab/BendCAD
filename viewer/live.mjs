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
let chain = Promise.resolve();
const queue = f => (chain = chain.then(f, f));
const kernel = (...a) => queue(async () => { const t0 = Date.now(); const r = await run([BIN, DESIGN, ...a]); r.ms = Date.now() - t0; return r; });

function parseShow(txt) {
  const params = [], nodes = [];
  for (const ln of txt.split('\n')) {
    let m = ln.match(/^\(param (\d+) (\S+) (\S+) (\S+) (\S+)\)$/);
    if (m) { params.push({ id: +m[1], name: m[2], value: m[3], lo: m[4], hi: m[5] }); continue; }
    m = ln.match(/^\(node (\d+) \((\S+)(.*)\)$/);
    if (m) nodes.push({ id: +m[1], op: m[2], text: ln });
  }
  const ids = new Set(nodes.map(n => n.id)), used = new Set();
  for (const n of nodes) {
    if (PRIM.has(n.op)) continue;
    const body = n.text.slice(n.text.indexOf('(' + n.op) + n.op.length + 1);
    const nums = [...body.matchAll(/(?:^|[\s(])(\d+)(?=[\s)])/g)].map(x => +x[1]).filter(x => ids.has(x) && x < n.id);
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
let doc = null;
async function loadDoc() {
  const s = await kernel('show'), e = await kernel('eval');
  const d = parseShow(s.out), ev = parseEval(e.out);
  d.rev = crypto.createHash('sha1').update(s.out).digest('hex').slice(0, 12);
  d.file = DESIGN; d.name = path.basename(DESIGN, '.bcd'); d.proc = PROC; d.eval_ms = e.ms;
  for (const n of d.nodes) Object.assign(n, ev[n.id] || { status: 'unknown' });
  doc = d;
  return d;
}
const meshes = new Map();
async function mesh(node, rev) {
  const k = rev + ':' + node;
  if (!meshes.has(k)) meshes.set(k, (async () => {
    await run(['mkdir', '-p', CACHE]);
    const f = `${CACHE}/${k.replace(':', '-')}.obj`;
    const t = await kernel('tess', String(node), f);
    if (!/^wrote /.test(t.out)) return { ok: false, out: t.out };
    const c = await run(['cat', f]);
    return { ok: true, obj: c.out, out: t.out.trim(), ms: t.ms };
  })());
  return meshes.get(k);
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
  const k = await kernel('mass', String(node), '0');
  const c = await kernel('check', String(node)), s = await kernel('std', String(node)), m = await kernel('make', String(node), proc);
  const ok = /^ok:/.test(c.out.trim());
  const std = s.out.split('\n').filter(l => /^std (hole|groove|key|thread)/.test(l) || /status=/.test(l)).map(l => ({ text: l.trim(), status: (l.match(/status=(\S+)/) || [])[1] }));
  const mk = m.out.split('\n').filter(l => /^make (face|corner)/.test(l)).map(l => ({ text: l.trim(), status: statusOf(l.trim()) }));
  const verdict = (m.out.match(/^verdict (\S+)/m) || [])[1] || 'refused';
  return { node, proc, mass: Object.assign(parseMass(k.out), { ms: k.ms }), check: { status: ok ? 'pass' : 'fail', text: c.out.trim().split('\n')[0], ms: c.ms }, std: { lines: std, summary: (s.out.match(/^std node .*$/m) || [''])[0], ms: s.ms },
    make: { verdict, lines: mk, summary: (m.out.match(/^make node \d+: .*$/m) || [''])[0], head: mk.length ? '' : m.out.trim().slice(0, 300), ms: m.ms } };
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
    const rel = decodeURIComponent(u.pathname === '/' ? '/index.html' : u.pathname);
    const f = path.normalize(path.join(HERE, rel));
    if (!f.startsWith(HERE) || !fs.existsSync(f) || fs.statSync(f).isDirectory()) return send(res, 404, 'not found', 'text/plain');
    return send(res, 200, fs.readFileSync(f), TYPES[path.extname(f)] || 'application/octet-stream');
  } catch (e) { send(res, 500, { ok: false, out: String(e && e.stack || e) }); }
}).listen(PORT, '127.0.0.1', () => console.log(`BendCAD live: http://127.0.0.1:${PORT}/?live=1  design ${DESIGN}  kernel ${BIN}`));
