import os, re, subprocess, sys

here = os.path.dirname(os.path.abspath(__file__))
src = os.path.join(here, "..", "..", "..", "src", "c04")
ops = open(os.path.join(src, "ops.bend"), encoding="utf-8").read()
seed, count = sys.argv[1], sys.argv[2]
for name in sys.argv[3:]:
    m = re.search(r"(?m)^def " + name + r"\(.*?-> Bool:\n", ops, re.S)
    if not m:
        sys.exit("no predicate " + name)
    end = ops.find("\ndef ", m.end())
    planted = ops[:m.end()] + "  True{}\n" + ops[end:]
    f = "ops_plant_" + name + ".bend"
    path = os.path.join(src, f)
    open(path, "w", encoding="utf-8", newline="\n").write(planted)
    try:
        r = subprocess.run([sys.executable, os.path.join(here, "diff_oracle.py"), seed, count],
                           env=dict(os.environ, C04_OPS=f), capture_output=True, text=True)
    finally:
        os.remove(path)
    tail = (r.stdout + r.stderr).strip().splitlines()
    print(name + ": " + (tail[-1] if tail else "no output"), flush=True)
