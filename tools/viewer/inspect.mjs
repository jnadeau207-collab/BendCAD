import { spawn } from 'node:child_process';
import { createRequire } from 'node:module';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const PW = process.env.PLAYWRIGHT_CORE || 'C:/dev/Aethalgard_CAD/node_modules/.pnpm/playwright-core@1.62.1/node_modules/playwright-core';
const CHROME = process.env.CHROME || 'C:/Program Files/Google/Chrome/Application/chrome.exe';

export async function startLive(design, bin, port, proc = 'mill') {
  const srv = spawn(process.execPath, [path.join(ROOT, 'viewer', 'live.mjs'), design, '--bin', bin, '--port', String(port), '--proc', proc], { stdio: ['ignore', 'pipe', 'pipe'] });
  let log = '';
  srv.stdout.on('data', d => { log += d; }); srv.stderr.on('data', d => { log += d; });
  for (let k = 0; k < 100 && !/BendCAD live:/.test(log); k++) await new Promise(r => setTimeout(r, 100));
  if (!/BendCAD live:/.test(log)) { srv.kill(); throw new Error('live server did not start: ' + log); }
  return { srv, url: `http://127.0.0.1:${port}/?live=1&proc=${proc}`, log: () => log };
}

export async function browser() {
  const { chromium } = require(PW);
  return chromium.launch({ executablePath: CHROME, headless: true, args: ['--enable-gpu', '--ignore-gpu-blocklist', '--use-angle=d3d11'] });
}

export async function ready(page, url) {
  await page.goto(url);
  await page.waitForFunction(() => document.body.dataset.ready === '1' && window.bcv && !window.bcv.live().busy, null, { timeout: 120000 });
}

export async function settle(page, ms = 700) {
  await page.waitForTimeout(ms);
  await page.evaluate(() => new Promise(r => requestAnimationFrame(() => requestAnimationFrame(r))));
}

export async function coverage(page) {
  return page.evaluate(() => {
    const c = document.getElementById('gl'), w = 160, h = 90, k = document.createElement('canvas');
    k.width = w; k.height = h;
    const g = k.getContext('2d'); g.drawImage(c, 0, 0, w, h);
    const d = g.getImageData(0, 0, w, h).data, bg = [d[0], d[1], d[2]];
    let n = 0;
    for (let i = 0; i < d.length; i += 4) if (Math.abs(d[i] - bg[0]) + Math.abs(d[i + 1] - bg[1]) + Math.abs(d[i + 2] - bg[2]) > 40) n++;
    return n / (w * h);
  });
}

export const VIEWS = ['iso', 'front', 'top', 'right'];

export async function inspect(page, out, tag, views = VIEWS, size = [1600, 1000]) {
  fs.mkdirSync(out, { recursive: true });
  const keep = await page.evaluate(() => { const b = window.bcv, s = { ortho: b.camera().ortho, sel: [...b.st.sel].map(p => p.node) }; b.select(null, false); b.useCamera(b.ortho); return s; });
  const files = [];
  for (const v of views) {
    await page.evaluate(x => window.bcv.view(x), v);
    await settle(page, 900);
    const r = await page.evaluate(async ([w, h]) => {
      const o = window.bcv.ortho, scale = (o.top - o.bottom) / o.zoom / h;
      const blob = await window.bcv.snapshot(w, h), bm = await createImageBitmap(blob), k = document.createElement('canvas');
      k.width = w; k.height = h;
      const g = k.getContext('2d'); g.drawImage(bm, 0, 0);
      const fg = (d, i, j) => Math.abs(d[i] - d[j]) + Math.abs(d[i + 1] - d[j + 1]) + Math.abs(d[i + 2] - d[j + 2]) > 40;
      const row = g.getImageData(0, h >> 1, w, 1).data;
      let x0 = -1, x1 = -1;
      for (let x = 0; x < w; x++) if (fg(row, 4 * x, 0)) { if (x0 < 0) x0 = x; x1 = x; }
      g.drawImage(bm, 0, 0, 160, 100);
      const d = g.getImageData(0, 0, 160, 100).data;
      let n = 0;
      for (let i = 0; i < d.length; i += 4) if (fg(d, i, 0)) n++;
      const b64 = await new Promise(res => { const fr = new FileReader(); fr.onload = () => res(fr.result.split(',')[1]); fr.readAsDataURL(blob); });
      return { b64, coverage: n / (160 * 100), scale, mid_row: [x0, x1] };
    }, size);
    const f = path.join(out, `${tag ? tag + '-' : ''}${v}.png`);
    fs.writeFileSync(f, Buffer.from(r.b64, 'base64'));
    files.push({ view: v, file: f, coverage: r.coverage, size, mm_per_px: r.scale, mid_row: r.mid_row });
  }
  await page.evaluate(s => { const b = window.bcv; b.useCamera(s.ortho ? b.ortho : b.persp); for (const p of b.st.parts) if (s.sel.includes(p.node)) b.select(p, true); }, keep);
  return files;
}

async function main() {
  const [design, out, ...rest] = process.argv.slice(2);
  if (!design || !out) { console.error('usage: node tools/viewer/inspect.mjs DESIGN.bcd OUTDIR [view...]   (BENDCAD_BIN, BCL_PORT)'); process.exit(2); }
  const live = await startLive(design, process.env.BENDCAD_BIN || '/home/jesse/bc/bendcad', +(process.env.BCL_PORT || 8794), process.env.BCL_PROC || 'mill');
  const b = await browser();
  try {
    const page = await b.newPage({ viewport: { width: 1600, height: 1000 } });
    await ready(page, live.url);
    const files = await inspect(page, out, null, rest.length ? rest : VIEWS);
    const doc = await page.evaluate(() => window.bcv.live());
    fs.writeFileSync(path.join(out, 'inspect.json'), JSON.stringify({ design, rev: doc.doc.rev, parts: doc.doc.parts, views: files.map(f => ({ view: f.view, file: path.basename(f.file), size: f.size, projection: 'orthographic', mm_per_px: f.mm_per_px, coverage: f.coverage })) }, null, 1));
    for (const f of files) console.log(`wrote ${f.file} coverage=${f.coverage.toFixed(3)}`);
  } finally { await b.close(); live.srv.kill(); }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) main().catch(e => { console.error(e); process.exit(1); });
