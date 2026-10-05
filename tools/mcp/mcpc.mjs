import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const [tool, raw] = process.argv.slice(2);
if (!tool) {
  process.stderr.write('usage: node mcpc.mjs TOOL [JSON-ARGUMENTS] | node mcpc.mjs --list\n');
  process.exit(2);
}
const srv = spawn(process.execPath, [join(here, 'bendcad-mcp.mjs')], { stdio: ['pipe', 'pipe', 'inherit'] });
const send = m => srv.stdin.write(JSON.stringify({ jsonrpc: '2.0', ...m }) + '\n');
let buf = '';
srv.stdout.on('data', d => {
  buf += d;
  let i;
  while ((i = buf.indexOf('\n')) >= 0) {
    const line = buf.slice(0, i);
    buf = buf.slice(i + 1);
    const m = JSON.parse(line);
    if (m.id === 1) {
      send({ method: 'notifications/initialized' });
      if (tool === '--list') send({ id: 2, method: 'tools/list' });
      else send({ id: 2, method: 'tools/call', params: { name: tool, arguments: raw ? JSON.parse(raw) : {} } });
    } else if (m.id === 2) {
      let code = 0;
      if (m.error) { process.stdout.write(`error ${m.error.code}: ${m.error.message}\n`); code = 1; }
      else if (tool === '--list') process.stdout.write(m.result.tools.map(t => `${t.name}(${Object.keys(t.inputSchema.properties).join(', ')}): ${t.description}`).join('\n') + '\n');
      else { process.stdout.write(m.result.content.map(c => c.text).join('\n') + '\n'); code = m.result.isError ? 1 : 0; }
      srv.stdin.end();
      srv.on('exit', () => process.exit(code));
    }
  }
});
send({ id: 1, method: 'initialize', params: { protocolVersion: '2024-11-05', capabilities: {}, clientInfo: { name: 'mcpc', version: '1' } } });
