import { spawn, spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { mkdirSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..', '..');
const [bin, design, outDir, port] = process.argv.slice(2);
if (!outDir) {
  process.stderr.write('usage: node serve_e2e.mjs WSL_BIN WSL_DESIGN OUT_DIR [PORT]\n');
  process.exit(2);
}
const wsl = cmd => spawnSync('wsl.exe', ['-e', 'bash', '-c', cmd], { encoding: 'utf8' }).stdout;
const last = wsl(`grep -o '^(node [0-9]*' ${design} | tail -1 | cut -d' ' -f2`).trim();
const steps = [
  ['evaluate', {}],
  ['measure', { node: Number(last) }],
  ['faces', { node: Number(last) }],
  ['diagnose', {}],
  ['apply', { edits: [`(node 9001 (move ${last} 0 0 0 4) (intent same any any any any))`] }],
  ['measure', { node: 9001 }],
  ['evaluate', {}],
];

function session(env, path) {
  const mcp = spawn(process.execPath, [join(root, 'tools/mcp/bendcad-mcp.mjs')], { stdio: ['pipe', 'pipe', 'inherit'], env: { ...process.env, ...env } });
  const waits = new Map();
  let buf = '';
  let id = 0;
  mcp.stdout.on('data', d => {
    buf += d;
    let i;
    while ((i = buf.indexOf('\n')) >= 0) {
      const m = JSON.parse(buf.slice(0, i));
      buf = buf.slice(i + 1);
      waits.get(m.id)?.(m);
    }
  });
  const rpc = (method, params) => new Promise(res => {
    waits.set(++id, res);
    mcp.stdin.write(JSON.stringify({ jsonrpc: '2.0', id, method, params }) + '\n');
  });
  return {
    init: () => rpc('initialize', { protocolVersion: '2024-11-05', capabilities: {}, clientInfo: { name: 'serve_e2e', version: '1' } }),
    call: async (name, args) => {
      const t = process.hrtime.bigint();
      const m = await rpc('tools/call', { name, arguments: { design: path, ...args } });
      return { ms: Number(process.hrtime.bigint() - t) / 1e6, text: m.result.content[0].text.split(path).join('DESIGN'), err: m.result.isError };
    },
    end: () => new Promise(res => { mcp.on('exit', res); mcp.stdin.end(); }),
  };
}

async function run(env, path) {
  wsl(`cp ${design} ${path}`);
  const s = session({ BENDCAD_BIN: bin, ...env }, path);
  await s.init();
  const out = [];
  for (const [name, args] of steps) {
    const r = await s.call(name, args);
    out.push(r);
    writeFileSync(join(outDir, `${out.length}-${name}.${env.BENDCAD_PORT ? 'serve' : 'cli'}.txt`), r.text + '\n');
    process.stdout.write(`${env.BENDCAD_PORT ? 'serve' : 'cli  '} ${name.padEnd(9)} ${r.ms.toFixed(0).padStart(9)} ms\n`);
  }
  await s.end();
  return { out, file: wsl(`sha256sum < ${path} | cut -d' ' -f1`).trim() };
}

const p = port || '47311';
mkdirSync(outDir, { recursive: true });
const cli = await run({}, `${design}.e2e-cli.bcd`);
const srv = await run({ BENDCAD_PORT: p }, `${design}.e2e-srv.bcd`);
const sha = t => createHash('sha256').update(t).digest('hex');
const rows = steps.map(([name, args], i) => ({
  step: i + 1, tool: name, args, cli_ms: cli.out[i].ms, serve_ms: srv.out[i].ms,
  speedup: cli.out[i].ms / srv.out[i].ms, identical: cli.out[i].text === srv.out[i].text,
  error: cli.out[i].err, sha256: sha(cli.out[i].text), serve_sha256: sha(srv.out[i].text),
}));
const tot = k => rows.reduce((a, r) => a + r[k], 0);
const receipt = {
  binary: bin, binary_sha256: wsl(`sha256sum ${bin} | cut -d' ' -f1`).trim(), design, design_sha256: wsl(`sha256sum < ${design} | cut -d' ' -f1`).trim(),
  labels: 'MEASURED wall-clock through the MCP server, one session per mode',
  steps: rows, cli_total_ms: tot('cli_ms'), serve_total_ms: tot('serve_ms'), warm_speedup: tot('cli_ms') / tot('serve_ms'),
  final_design_identical: cli.file === srv.file, all_identical: rows.every(r => r.identical) && cli.file === srv.file,
};
writeFileSync(join(outDir, 'serve_e2e.json'), JSON.stringify(receipt, null, 2) + '\n');
process.stdout.write(`identical ${receipt.all_identical} cli ${receipt.cli_total_ms.toFixed(0)} ms serve ${receipt.serve_total_ms.toFixed(0)} ms x${receipt.warm_speedup.toFixed(1)}\n`);
process.exit(receipt.all_identical ? 0 : 1);
