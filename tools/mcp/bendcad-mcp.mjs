import { spawnSync } from 'node:child_process';
import { readFileSync, appendFileSync } from 'node:fs';
import { createInterface } from 'node:readline';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const BIN = process.env.BENDCAD_BIN || '/home/jesse/bc/bendcad';
const LOG = process.env.BENDCAD_LOG || '';
const TIMEOUT = Number(process.env.BENDCAD_TIMEOUT_MS) || 600000;
const MAXN = process.env.BENDCAD_MAX_NODES || '';
const REF = readFileSync(join(here, 'language.md'), 'utf8');
const CODES = {'invalid-input':1,'unsupported-op':2,'numerical-uncertainty':3,'nonconvergence':4,'cancelled':5,'resource-exhausted':6};

function withCap(args) {
  if (MAXN === '' || args[0] === 'geom') return args;
  return [args[0], '--max-nodes', MAXN, ...args.slice(1)];
}

function endState(r) {
  if (r.error && (r.error.code === 'ETIMEDOUT' || /timed?out/i.test(r.error.message || ''))) return 'timeout';
  if (r.status === null && r.signalCode) return 'signal';
  return 'exit';
}

function parseErr(text) {
  const diags = [];
  for (const ln0 of String(text).split('\n')) {
    let m;
    const pm = /^node (\d+): (.*)$/.exec(ln0);
    const ln = pm ? pm[2] : ln0;
    const pnode = pm ? Number(pm[1]) : null;
    if (ln.startsWith('{"node"')) {
      try {
        const o = JSON.parse(ln);
        if (o && o.ok === false) diags.push({node: o.node ?? null, ok: false, code: o.code ?? null, kind: o.kind ?? null, what: o.what ?? null, loc: o.loc ?? null, why: o.why ?? null, fix: o.fix ?? null});
      } catch {}
      continue;
    }
    if ((m = /^error (\S+) \| (.*?) @ (.*?) \| why: (.*?) \| fix: (.*)$/.exec(ln))) {
      diags.push({node: pnode, ok: false, code: CODES[m[1]] ?? null, kind: m[1], what: m[2], loc: m[3], why: m[4], fix: m[5]});
      continue;
    }
    if ((m = /^error (\S+) \| (.*?) \| why: (.*?) \| fix: (.*)$/.exec(ln))) {
      diags.push({node: pnode, ok: false, code: CODES[m[1]] ?? null, kind: m[1], what: m[2], loc: null, why: m[3], fix: m[4]});
      continue;
    }
    if ((m = /^refused (\S+) \| (.*)$/.exec(ln))) { diags.push({ok: false, code: null, kind: 'refused', why: m[1], raw: m[2]}); continue; }
    if ((m = /^error unknown command (.*)$/.exec(ln))) { diags.push({ok: false, code: null, kind: 'unknown-command', raw: m[1]}); continue; }
    if ((m = /^error: (.*)$/.exec(ln))) { diags.push({ok: false, code: null, kind: 'legacy', raw: m[1]}); continue; }
    if ((m = /^rejected: (.*)$/.exec(ln))) { diags.push({ok: false, code: null, kind: 'rejected', raw: m[1]}); continue; }
    if (ln0 === 'node failed') { diags.push({ok: false, code: null, kind: 'legacy', raw: ln0}); continue; }
  }
  return diags;
}

function cli(args) {
  const [cmd, pre] = process.platform === 'win32' ? ['wsl.exe', ['-e', BIN]] : [BIN, []];
  const full = [...pre, ...withCap(args)];
  const r = spawnSync(cmd, full, { encoding: 'utf8', timeout: TIMEOUT });
  const st = endState(r);
  let out = (r.stdout || '') + (r.stderr || '');
  if (st === 'timeout') out += (out === '' || out.endsWith('\n') ? '' : '\n') + `error cancelled | mcp-timeout @ bendcad-mcp | why: cli-exceeded-timeout | fix: retry with a larger BENDCAD_TIMEOUT_MS (current ${TIMEOUT})\n`;
  if (st === 'signal') out += (out === '' || out.endsWith('\n') ? '' : '\n') + `error cancelled | mcp-signal @ bendcad-mcp | why: cli-killed-by-signal-${r.signalCode} | fix: retry the request\n`;
  if (LOG) {
    const rec = JSON.stringify({ t: new Date().toISOString(), args: full, status: r.status, out }) + '\n';
    try { appendFileSync(LOG, rec); } catch {}
  }
  const ok = r.status === 0 && st === 'exit' && !/^error|^node \d+: error|^node failed|rejected/m.test(out) && !/"ok":false/.test(out);
  return { ok, text: out.trim() || `exit ${r.status}`, diags: parseErr(out) };
}

const design = { type: 'string', description: 'Design file path inside WSL, e.g. /home/jesse/work/bracket.bcd' };
const node = { type: 'integer', description: 'Node id' };

const tools = [
  { name: 'reference', description: 'The BendCAD design language: parameters, profiles, operations, faces, intents. Read this first.',
    inputSchema: { type: 'object', properties: {} }, run: () => ({ ok: true, text: REF, diags: [] }) },
  { name: 'new_design', description: 'Create an empty design file.',
    inputSchema: { type: 'object', properties: { design }, required: ['design'] }, run: a => cli([a.design, 'new']) },
  { name: 'apply', description: 'Apply edits atomically. Each edit is (param NAME NOM [LO HI]), (node ID OP INTENT) or (delete ID). The change is committed only if every node builds and meets its declared intent; otherwise nothing changes and each failure is diagnosed.',
    inputSchema: { type: 'object', properties: { design, edits: { type: 'array', items: { type: 'string' }, description: 'One edit per string; a single string holding several edits is also accepted' } }, required: ['design', 'edits'] },
    run: a => cli([a.design, 'apply', ...(typeof a.edits === 'string' ? [a.edits] : Array.isArray(a.edits) ? a.edits.map(String) : [])]) },
  { name: 'show', description: 'Print the design (parameters and nodes) as stored.',
    inputSchema: { type: 'object', properties: { design }, required: ['design'] }, run: a => cli([a.design, 'show']) },
  { name: 'evaluate', description: 'Evaluate every node: measured effect, certified volume and area intervals, bounding box, entity counts, genus.',
    inputSchema: { type: 'object', properties: { design }, required: ['design'] }, run: a => cli([a.design, 'eval']) },
  { name: 'diagnose', description: 'Structured failures of the design as JSON lines: one {"node","ok"} object per evaluated node; failures carry code, kind, what, loc, why and fix.',
    inputSchema: { type: 'object', properties: { design }, required: ['design'] }, run: a => cli([a.design, 'diag']) },
  { name: 'measure', description: 'Measures of one node\'s solid.',
    inputSchema: { type: 'object', properties: { design, node }, required: ['design', 'node'] }, run: a => cli([a.design, 'measure', String(a.node)]) },
  { name: 'faces', description: 'Faces of one node\'s solid by durable lineage name (nN.cK.top|bottom|wall.I.J), surface type and loop count. Use these names to select faces for features.',
    inputSchema: { type: 'object', properties: { design, node }, required: ['design', 'node'] }, run: a => cli([a.design, 'faces', String(a.node)]) },
  { name: 'sensitivity', description: 'Estimated derivatives of volume, area and bounding box of a node with respect to a parameter, or the reason none exists (topology change, failure).',
    inputSchema: { type: 'object', properties: { design, param: { type: 'string' }, node }, required: ['design', 'param', 'node'] },
    run: a => cli([a.design, 'sens', a.param, String(a.node)]) },
  { name: 'zone', description: 'Volume and area of a node certified over the whole tolerance envelope (every parameter anywhere in its [lo, hi] zone), for every operation once the kernel certifies the topology cannot change in the zone; otherwise topology-not-certified-over-zone.',
    inputSchema: { type: 'object', properties: { design, node }, required: ['design', 'node'] }, run: a => cli([a.design, 'zone', String(a.node)]) },
  { name: 'classify', description: 'Is a world point inside, outside or on the boundary of the solid of a node (certified ray casting)?',
    inputSchema: { type: 'object', properties: { design, node, x: { type: 'number' }, y: { type: 'number' }, z: { type: 'number' } }, required: ['design', 'node', 'x', 'y', 'z'] },
    run: a => cli([a.design, 'classify', String(a.node), String(a.x), String(a.y), String(a.z)]) },
  { name: 'check', description: 'Certify that the solid of a node is embedded (no crossing edges, piercing edges, penetrating or overlapping faces), that shells face outward and that cavities are nested correctly. Prints ok or one finding per line.',
    inputSchema: { type: 'object', properties: { design, node }, required: ['design', 'node'] }, run: a => cli([a.design, 'check', String(a.node)]) },
  { name: 'intersect', description: 'Intersect two curves, a curve and a surface, or two surfaces (see reference: Geometry queries). Returns certified points, overlaps, traced curves and explicit unresolved boxes.',
    inputSchema: { type: 'object', properties: { a: { type: 'string', description: 'First geometry, e.g. (line 0 0 0 1 0 0 -5 5)' }, b: { type: 'string', description: 'Second geometry' }, box: { type: 'string', description: 'Optional (box X0 X1 Y0 Y1 Z0 Z1); required for surface/surface' } }, required: ['a', 'b'] },
    run: a => cli(['geom', 'intersect', a.a, a.b, ...(a.box ? [a.box] : [])]) },
  { name: 'distance', description: 'Closest point and distance from a world point to the solid of a node: 0 certified when inside or on the boundary, otherwise a [lo, hi] interval with a certified lower bound, the nearest sample, and estimated status.',
    inputSchema: { type: 'object', properties: { design, node, x: { type: 'number' }, y: { type: 'number' }, z: { type: 'number' } }, required: ['design', 'node', 'x', 'y', 'z'] },
    run: a => cli([a.design, 'dist', String(a.node), String(a.x), String(a.y), String(a.z)]) },
  { name: 'extrema', description: 'Certified world-coordinate bounds of the solid of a node, with the nearest vertex witness per bound (sampled).',
    inputSchema: { type: 'object', properties: { design, node }, required: ['design', 'node'] },
    run: a => cli([a.design, 'extrema', String(a.node)]) },
  { name: 'mass', description: 'Mass properties of a node\'s solid at unit density: certified volume and area, centroid interval and centroidal inertia tensor from bounded octree integration (depth 0-6, default 4), with cell counts.',
    inputSchema: { type: 'object', properties: { design, node, depth: { type: 'integer', description: 'Octree depth 0-6 (default 4)' } }, required: ['design', 'node'] },
    run: a => cli([a.design, 'mass', String(a.node), a.depth ?? ''].map(String)) },
  { name: 'section', description: 'Section of a node\'s solid by the world plane ax+by+cz=d: per-face intersection curves with sample points, unresolved boxes, coincident faces, and summary counts with certified or estimated status.',
    inputSchema: { type: 'object', properties: { design, node, a: { type: 'number' }, b: { type: 'number' }, c: { type: 'number' }, d: { type: 'number' } }, required: ['design', 'node', 'a', 'b', 'c', 'd'] },
    run: a => cli([a.design, 'section', String(a.node), String(a.a), String(a.b), String(a.c), String(a.d)]) },
  { name: 'interference', description: 'Exact relation between the solids of two nodes: disjoint, inside (a-in-b, b-in-a) or interference, each certified, else uncertain with sample counts. Also reports exact per-solid cavity inside/disjoint verdicts. AABB overlap alone is never reported as interference.',
    inputSchema: { type: 'object', properties: { design, a: { ...node, description: 'First node id' }, b: { ...node, description: 'Second node id' } }, required: ['design', 'a', 'b'] },
    run: a => cli([a.design, 'interf', String(a.a), String(a.b)]) },
  { name: 'clearance', description: 'Clearance between the solids of two nodes: 0 certified on proven interference, otherwise a [lo, hi] interval with a certified lower bound and estimated status.',
    inputSchema: { type: 'object', properties: { design, a: { ...node, description: 'First node id' }, b: { ...node, description: 'Second node id' } }, required: ['design', 'a', 'b'] },
    run: a => cli([a.design, 'clearance', String(a.a), String(a.b)]) },
  { name: 'min_wall', description: 'Minimum wall thickness of a node\'s solid by the qualified exhaustive method: every non-adjacent face pair bounds the minimum from below (certified lo) with sample upper bounds (estimated). Adjacent faces share a vertex and are excluded.',
    inputSchema: { type: 'object', properties: { design, node }, required: ['design', 'node'] },
    run: a => cli([a.design, 'wall', String(a.node)]) },
  { name: 'tessellate', description: 'Write a watertight triangle mesh (OBJ) of a node\'s solid to a WSL path, with stated chord/angle quality, a triangle budget, and sampled (not certified) measurements. Refuses as tess-budget-exceeded when the estimate tops the budget.',
    inputSchema: { type: 'object', properties: { design, node, out: { type: 'string' },
        preset: { type: 'integer', description: '0 draft, 1 default, 2 fine, 3 manufacturing (default 1)' },
        chord: { type: 'number', description: 'Chord tolerance in mm (preset default)' },
        angle: { type: 'number', description: 'Angle tolerance in radians (preset default)' },
        maxTris: { type: 'integer', description: 'Triangle budget (preset default)' },
        profile: { type: 'string', description: 'display or manufacturing (preset default)' } },
      required: ['design', 'node', 'out'] },
    run: a => cli([a.design, 'tess', String(a.node), a.out, a.preset ?? '', a.chord ?? '', a.angle ?? '',
      a.maxTris ?? '', a.profile ?? ''].map(String)) },
  { name: 'step_export', description: 'Write a STEP file (declared B-rep profile: analytic curves, trim-seg coedges, plane/sphere/cylinder/torus/bezier-patch faces, mm units) of a node\'s solid to a WSL path. Refuses with a named reason outside the profile.',
    inputSchema: { type: 'object', properties: { design, node, out: { type: 'string' } }, required: ['design', 'node', 'out'] },
    run: a => cli([a.design, 'step', String(a.node), a.out]) },
  { name: 'step_import', description: 'Import a STEP file: validates the declared profile (mm units, no open shells, no NURBS/spline geometry outside bezier form) and reports measures. Optionally writes a BCAD2 archive of the imported solid.',
    inputSchema: { type: 'object', properties: { file: { type: 'string', description: 'STEP file path inside WSL' }, out: { type: 'string', description: 'Optional archive path' } }, required: ['file'] },
    run: a => cli(['geom', 'step_import', a.file, ...(a.out ? [a.out] : [])]) },
  { name: 'archive', description: 'Write a versioned BCAD2 B-rep archive (topology plus analytic geometry, never a display mesh) of a node\'s solid to a WSL path, with optional lineage text.',
    inputSchema: { type: 'object', properties: { design, node, out: { type: 'string' }, lineage: { type: 'string' } }, required: ['design', 'node', 'out'] },
    run: a => cli([a.design, 'archive', String(a.node), a.out, a.lineage ?? ''].map(String)) },
  { name: 'reopen', description: 'Reopen a BCAD2 archive: validates version, units and the full B-rep, and reports measures, units and lineage. Verbose mode lists faces with analytic surface types.',
    inputSchema: { type: 'object', properties: { file: { type: 'string', description: 'Archive path inside WSL' }, verbose: { type: 'boolean' } }, required: ['file'] },
    run: a => cli(['geom', 'reopen', a.file, ...(a.verbose ? ['-v'] : [])]) },
  { name: 'step_of', description: 'Export a BCAD2 archive to a STEP file (same declared profile as step_export).',
    inputSchema: { type: 'object', properties: { file: { type: 'string', description: 'Archive path inside WSL' }, out: { type: 'string' } }, required: ['file', 'out'] },
    run: a => cli(['geom', 'step_of', a.file, a.out]) },
  { name: 'stl_export', description: 'Write an ASCII STL mesh of a node\'s solid to a WSL path, with stated chord/angle quality, a triangle budget, and sampled (not certified) measurements.',
    inputSchema: { type: 'object', properties: { design, node, out: { type: 'string' },
        preset: { type: 'integer', description: '0 draft, 1 default, 2 fine, 3 manufacturing (default 1)' },
        chord: { type: 'number' }, angle: { type: 'number' }, maxTris: { type: 'integer' },
        profile: { type: 'string', description: 'display or manufacturing (preset default)' } },
      required: ['design', 'node', 'out'] },
    run: a => cli([a.design, 'stl', String(a.node), a.out, a.preset ?? '', a.chord ?? '', a.angle ?? '',
      a.maxTris ?? '', a.profile ?? ''].map(String)) },
  { name: 'stl_of', description: 'Write an ASCII STL mesh of a BCAD2 archive\'s solid to a WSL path (same quality arguments as stl_export).',
    inputSchema: { type: 'object', properties: { file: { type: 'string', description: 'Archive path inside WSL' }, out: { type: 'string' },
        preset: { type: 'integer' }, chord: { type: 'number' }, angle: { type: 'number' }, maxTris: { type: 'integer' },
        profile: { type: 'string' } }, required: ['file', 'out'] },
    run: a => cli(['geom', 'stl_of', a.file, a.out, a.preset ?? '', a.chord ?? '', a.angle ?? '',
      a.maxTris ?? '', a.profile ?? ''].map(String)) },
  { name: 'threemf_export', description: 'Write a 3MF package (store-mode OPC zip with model XML, millimetre units) of a node\'s solid to a WSL path, with stated chord/angle quality and sampled (not certified) measurements.',
    inputSchema: { type: 'object', properties: { design, node, out: { type: 'string' },
        preset: { type: 'integer', description: '0 draft, 1 default, 2 fine, 3 manufacturing (default 1)' },
        chord: { type: 'number' }, angle: { type: 'number' }, maxTris: { type: 'integer' },
        profile: { type: 'string', description: 'display or manufacturing (preset default)' } },
      required: ['design', 'node', 'out'] },
    run: a => cli([a.design, '3mf', String(a.node), a.out, a.preset ?? '', a.chord ?? '', a.angle ?? '',
      a.maxTris ?? '', a.profile ?? ''].map(String)) },
  { name: 'threemf_of', description: 'Write a 3MF package of a BCAD2 archive\'s solid to a WSL path (same quality arguments as threemf_export).',
    inputSchema: { type: 'object', properties: { file: { type: 'string', description: 'Archive path inside WSL' }, out: { type: 'string' },
        preset: { type: 'integer' }, chord: { type: 'number' }, angle: { type: 'number' }, maxTris: { type: 'integer' },
        profile: { type: 'string' } }, required: ['file', 'out'] },
    run: a => cli(['geom', '3mf_of', a.file, a.out, a.preset ?? '', a.chord ?? '', a.angle ?? '',
      a.maxTris ?? '', a.profile ?? ''].map(String)) },
  { name: 'assembly', description: 'Solve an assembly of design-node instances with mates (see reference: Assemblies). Actions: solve (placements, dof, redundant mates, lineage), interf/clear (pairwise certified interference/clearance over solved placements), explode (exploded placements along dx,dy,dz with gap), faces (assembly-qualified face names of one instance).',
    inputSchema: { type: 'object', properties: { design, action: { type: 'string', description: 'solve, interf, clear, explode or faces' },
        assembly: { type: 'string', description: 'One (assembly ...) form' }, inst: { type: 'string', description: 'Instance name (faces only)' },
        dx: { type: 'number' }, dy: { type: 'number' }, dz: { type: 'number' }, gap: { type: 'number' } },
      required: ['design', 'action', 'assembly'] },
    run: a => a.action === 'explode'
      ? cli([a.design, 'asm', 'explode', a.dx ?? '', a.dy ?? '', a.dz ?? '', a.gap ?? '', a.assembly].map(String))
      : a.action === 'faces' ? cli([a.design, 'asm', 'faces', a.inst ?? '', a.assembly])
      : cli([a.design, 'asm', String(a.action), a.assembly]) },
  { name: 'pmi', description: 'Semantic PMI and GD&T (see reference: Semantic PMI). Actions: check (validate and evaluate), stack (worst-case stack-ups over envelope and states), toler (per-state interference/clearance plus envelope), step42 (STEP AP242 export with PMI).',
    inputSchema: { type: 'object', properties: { design, action: { type: 'string', description: 'check, stack, toler or step42' },
        pmi: { type: 'string', description: 'One (pmi ...) form' }, out: { type: 'string', description: 'Output file (step42 only)' } },
      required: ['design', 'action', 'pmi'] },
    run: a => a.action === 'step42' ? cli([a.design, 'pmi', 'step42', a.out ?? '', a.pmi])
      : cli([a.design, 'pmi', String(a.action), a.pmi]) },
  { name: 'surface', description: 'Boundary report of an open-shell node (see reference: Surface modeling). Per-edge durable names with certified or estimated lengths, area, boundary length and bounding box for a loft-open, sweep-open or patch node.',
    inputSchema: { type: 'object', properties: { design, node: { type: 'number', description: 'Open-shell node id' } },
      required: ['design', 'node'] },
    run: a => cli([a.design, 'surf', String(a.node)]) },
  { name: 'blade', description: 'Blade section report of a blade node (see reference: Blade sections). Per-section certified area, centroid, max thickness and max camber intervals, chord, stacking height, stacking-axis deviation and the twist schedule for a blade node.',
    inputSchema: { type: 'object', properties: { design, node: { type: 'number', description: 'Blade node id' } },
      required: ['design', 'node'] },
    run: a => cli([a.design, 'blade', String(a.node)]) },
  { name: 'flat_pattern', description: 'Sheet-metal flat pattern (see reference: Sheet metal). Certified bend allowances over a K-factor zone, developed runs, developed length interval and blank box for a flat, bend or hem node.',
    inputSchema: { type: 'object', properties: { design, node: { type: 'number', description: 'Sheet node id' },
        klo: { type: 'number', description: 'K-factor zone low end, 0 < KLO' },
        khi: { type: 'number', description: 'K-factor zone high end, KHI < 1' } },
      required: ['design', 'node', 'klo', 'khi'] },
    run: a => cli([a.design, 'flat', String(a.node), String(a.klo), String(a.khi)]) },
];

function send(msg) { process.stdout.write(JSON.stringify(msg) + '\n'); }

const rl = createInterface({ input: process.stdin });
rl.on('line', line => {
  let m;
  try { m = JSON.parse(line); } catch { return; }
  if (m.method === 'initialize') {
    send({ jsonrpc: '2.0', id: m.id, result: { protocolVersion: m.params?.protocolVersion || '2024-11-05',
      capabilities: { tools: {} }, serverInfo: { name: 'bendcad', version: '0.7.0' } } });
  } else if (m.method === 'tools/list') {
    send({ jsonrpc: '2.0', id: m.id, result: { tools: tools.map(({ name, description, inputSchema }) => ({ name, description, inputSchema })) } });
  } else if (m.method === 'tools/call') {
    const t = tools.find(x => x.name === m.params?.name);
    if (!t) { send({ jsonrpc: '2.0', id: m.id, error: { code: -32602, message: 'unknown tool' } }); return; }
    const r = t.run(m.params.arguments || {});
    send({ jsonrpc: '2.0', id: m.id, result: { content: [{ type: 'text', text: r.text }], isError: !r.ok, diagnostics: r.diags || [] } });
  } else if (m.method === 'ping') {
    send({ jsonrpc: '2.0', id: m.id, result: {} });
  } else if (m.id !== undefined) {
    send({ jsonrpc: '2.0', id: m.id, error: { code: -32601, message: 'method not found' } });
  }
});
