import { createHash } from "node:crypto";
import { writeFileSync } from "node:fs";

const [mod, report, shard] = process.argv.slice(2);
const [si, sn] = (shard ?? "0/1").split("/").map(Number);
const M = (await import(mod)).default;

function same(a, b) {
  if (typeof a !== typeof b) return false;
  if (typeof a !== "object" || a === null || b === null) return Object.is(a, b);
  const ka = Object.keys(a), kb = Object.keys(b);
  if (ka.length !== kb.length) return false;
  return ka.every((k) => Object.hasOwn(b, k) && same(a[k], b[k]));
}

function show(v) {
  return JSON.stringify(v, (_, x) => (typeof x === "bigint" ? x.toString() + "n" : x)).slice(0, 400);
}

const names = Object.keys(M).filter((k) => k.endsWith("__got")).map((k) => k.slice(0, -5)).sort()
  .filter((_, i) => i % sn === si);
const rows = [];
let fails = 0;
for (const n of names) {
  const t = performance.now();
  let ok, detail;
  try {
    const got = M[n + "__got"](), want = M[n + "__want"]();
    ok = same(got, want);
    if (!ok) detail = { got: show(got), want: show(want) };
  } catch (e) {
    ok = false;
    detail = { error: String(e).slice(0, 400) };
  }
  if (!ok) fails++;
  rows.push({ name: n, ok, ...(detail ? { detail } : {}) });
  console.log((ok ? "PASS " : "FAIL ") + n + " " + (performance.now() - t).toFixed(0) + "ms" + (ok ? "" : " " + JSON.stringify(detail)));
}
const blob = JSON.stringify(rows, null, 1);
if (report) writeFileSync(report, blob + "\n");
console.log(`${rows.length - fails}/${rows.length} pins hold; sha256 ${createHash("sha256").update(blob).digest("hex")}`);
process.exit(fails ? 1 : 0);
