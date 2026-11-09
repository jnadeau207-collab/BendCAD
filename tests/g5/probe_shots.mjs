import { spawnSync } from 'node:child_process';
import { createRequire } from 'node:module';
import fs from 'node:fs';
import path from 'node:path';

const require = createRequire(import.meta.url);
const { chromium } = require(process.env.PLAYWRIGHT_CORE || 'C:/dev/Aethalgard_CAD/node_modules/.pnpm/playwright-core@1.62.1/node_modules/playwright-core');
const PORT = +(process.env.G5_VIEW_PORT || 8791);
const OUT = path.resolve(process.argv[2]);
const SHOTS = JSON.parse(fs.readFileSync(process.argv[3], 'utf8'));
fs.mkdirSync(OUT, { recursive: true });
const browser = await chromium.launch({ executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe', headless: true, args: ['--enable-gpu', '--ignore-gpu-blocklist', '--use-angle=d3d11'] });
const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } });
await page.goto(`http://127.0.0.1:${PORT}/?scene=g5/scene.json`);
await page.waitForFunction(() => document.body.dataset.ready === '1', null, { timeout: 600000 });
await page.waitForTimeout(1500);
for (const s of SHOTS) {
  await page.evaluate(s.js);
  await page.waitForTimeout(s.wait || 1200);
  await page.screenshot({ path: path.join(OUT, s.name + '.png') });
  console.log('shot', s.name);
}
await browser.close();
