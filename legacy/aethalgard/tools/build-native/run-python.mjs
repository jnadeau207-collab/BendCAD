import { spawnSync } from "node:child_process";
import process from "node:process";

const candidates =
  process.platform === "win32"
    ? [["py", "-3"], ["python"]]
    : [["python3"], ["python"]];

for (const [executable, ...prefix] of candidates) {
  const result = spawnSync(executable, [...prefix, ...process.argv.slice(2)], {
    stdio: "inherit",
  });
  if (!result.error) process.exit(result.status ?? 1);
  if (result.error.code !== "ENOENT") throw result.error;
}

throw new Error(
  "Python 3 is required. Install it and make py/python available on PATH.",
);
