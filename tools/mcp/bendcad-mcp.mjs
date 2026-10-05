import { spawnSync } from 'node:child_process';
import { readFileSync, appendFileSync } from 'node:fs';
import { createInterface } from 'node:readline';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const BIN = process.env.BENDCAD_BIN || '/home/jesse/bc/bendcad';
const LOG = process.env.BENDCAD_LOG || '';
const REF = readFileSync(join(here, 'language.md'), 'utf8');

function cli(args) {
  const r = spawnSync('wsl.exe', ['-e', BIN, ...args], { encoding: 'utf8', timeout: 600000 });
  const out = (r.stdout || '') + (r.stderr || '');
  if (LOG) {
    const rec = JSON.stringify({ t: new Date().toISOString(), args, status: r.status, out }) + '\n';
    try { appendFileSync(LOG, rec); } catch {}
  }
  return { ok: r.status === 0 && !/^error|rejected/m.test(out), text: out.trim() || `exit ${r.status}` };
}

const design = { type: 'string', description: 'Design file path inside WSL, e.g. /home/jesse/work/bracket.bcd' };
const node = { type: 'integer', description: 'Node id' };

const tools = [
  { name: 'reference', description: 'The BendCAD design language: parameters, profiles, operations, faces, intents. Read this first.',
    inputSchema: { type: 'object', properties: {} }, run: () => ({ ok: true, text: REF }) },
  { name: 'new_design', description: 'Create an empty design file.',
    inputSchema: { type: 'object', properties: { design }, required: ['design'] }, run: a => cli([a.design, 'new']) },
  { name: 'apply', description: 'Apply edits atomically. Each edit is (param NAME NOM [LO HI]), (node ID OP INTENT) or (delete ID). The change is committed only if every node builds and meets its declared intent; otherwise nothing changes and each failure is diagnosed.',
    inputSchema: { type: 'object', properties: { design, edits: { type: 'array', items: { type: 'string' } } }, required: ['design', 'edits'] },
    run: a => cli([a.design, 'apply', ...a.edits]) },
  { name: 'show', description: 'Print the design (parameters and nodes) as stored.',
    inputSchema: { type: 'object', properties: { design }, required: ['design'] }, run: a => cli([a.design, 'show']) },
  { name: 'evaluate', description: 'Evaluate every node: measured effect, certified volume and area intervals, bounding box, entity counts, genus.',
    inputSchema: { type: 'object', properties: { design }, required: ['design'] }, run: a => cli([a.design, 'eval']) },
  { name: 'measure', description: 'Measures of one node\'s solid.',
    inputSchema: { type: 'object', properties: { design, node }, required: ['design', 'node'] }, run: a => cli([a.design, 'measure', String(a.node)]) },
  { name: 'faces', description: 'Faces of one node\'s solid by durable lineage name (nN.cK.top|bottom|wall.I.J), surface type and loop count. Use these names to select faces for features.',
    inputSchema: { type: 'object', properties: { design, node }, required: ['design', 'node'] }, run: a => cli([a.design, 'faces', String(a.node)]) },
  { name: 'sensitivity', description: 'Estimated derivatives of volume, area and bounding box of a node with respect to a parameter, or the reason none exists (topology change, failure).',
    inputSchema: { type: 'object', properties: { design, param: { type: 'string' }, node }, required: ['design', 'param', 'node'] },
    run: a => cli([a.design, 'sens', a.param, String(a.node)]) },
  { name: 'tessellate', description: 'Write a watertight triangle mesh (OBJ) of a node\'s solid to a WSL path.',
    inputSchema: { type: 'object', properties: { design, node, out: { type: 'string' } }, required: ['design', 'node', 'out'] },
    run: a => cli([a.design, 'tess', String(a.node), a.out]) },
];

function send(msg) { process.stdout.write(JSON.stringify(msg) + '\n'); }

const rl = createInterface({ input: process.stdin });
rl.on('line', line => {
  let m;
  try { m = JSON.parse(line); } catch { return; }
  if (m.method === 'initialize') {
    send({ jsonrpc: '2.0', id: m.id, result: { protocolVersion: m.params?.protocolVersion || '2024-11-05',
      capabilities: { tools: {} }, serverInfo: { name: 'bendcad', version: '0.6.0' } } });
  } else if (m.method === 'tools/list') {
    send({ jsonrpc: '2.0', id: m.id, result: { tools: tools.map(({ name, description, inputSchema }) => ({ name, description, inputSchema })) } });
  } else if (m.method === 'tools/call') {
    const t = tools.find(x => x.name === m.params?.name);
    if (!t) { send({ jsonrpc: '2.0', id: m.id, error: { code: -32602, message: 'unknown tool' } }); return; }
    const r = t.run(m.params.arguments || {});
    send({ jsonrpc: '2.0', id: m.id, result: { content: [{ type: 'text', text: r.text }], isError: !r.ok } });
  } else if (m.method === 'ping') {
    send({ jsonrpc: '2.0', id: m.id, result: {} });
  } else if (m.id !== undefined) {
    send({ jsonrpc: '2.0', id: m.id, error: { code: -32601, message: 'method not found' } });
  }
});
