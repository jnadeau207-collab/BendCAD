#!/bin/bash
set -u
export PATH=$HOME/.bend/bin:$HOME/.bun/bin:$PATH
export BEND_NO_TELEMETRY=1
cd "$(dirname "$0")/../.."
jobs=${PINS_JOBS:-8}
st=0
for f in "$@"; do
  d=$(dirname "$f"); b=$(basename "$f" .bend)
  tag=$(echo "$f" | tr / _)
  out=/tmp/bendcad-pins-$tag.mjs
  if ! bend "$f" -o "$out" > "/tmp/bendcad-pins-$tag.build.log" 2>&1; then
    echo "BUILD FAIL $f"; grep -v "bend update" "/tmp/bendcad-pins-$tag.build.log" | head -20; st=1; continue
  fi
  echo "== $f"
  for i in $(seq 0 $((jobs - 1))); do
    bun tools/pins/run.mjs "$out" "/tmp/bendcad-pins-$tag.$i.json" "$i/$jobs" > "/tmp/bendcad-pins-$tag.$i.log" 2>&1 &
  done
  wait
  bun -e '
    const fs = require("node:fs"), crypto = require("node:crypto");
    const [tag, n, dst] = process.argv.slice(1);
    let rows = [];
    for (let i = 0; i < +n; i++) rows = rows.concat(JSON.parse(fs.readFileSync(`/tmp/bendcad-pins-${tag}.${i}.json`, "utf8")));
    rows.sort((a, b) => (a.name < b.name ? -1 : a.name > b.name ? 1 : 0));
    const blob = JSON.stringify(rows, null, 1);
    fs.writeFileSync(dst, blob + "\n");
    const bad = rows.filter((r) => !r.ok);
    for (const r of bad) console.log("FAIL " + r.name + " " + JSON.stringify(r.detail));
    console.log(`${rows.length - bad.length}/${rows.length} pins hold; sha256 ${crypto.createHash("sha256").update(blob).digest("hex")}`);
    process.exit(bad.length ? 1 : 0);
  ' "$tag" "$jobs" "$d/$b-report.json" || st=1
done
exit $st
