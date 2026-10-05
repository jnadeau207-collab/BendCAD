import os, subprocess, sys

here = os.path.dirname(os.path.abspath(__file__))
gen = os.path.join(here, "gen")
os.makedirs(gen, exist_ok=True)


def wsl_path(p):
    d, rest = os.path.splitdrive(os.path.abspath(p))
    return "/mnt/" + d[0].lower() + rest.replace("\\", "/")


def bend_run(src, out):
    exe = "/tmp/bendcad-c05-" + os.path.basename(src)[:-5]
    cmd = f'export PATH=$HOME/.bend/bin:$HOME/.bun/bin:$PATH; bend "{src}" -o {exe} && {exe}'
    if os.name == "nt":
        r = subprocess.run(["wsl.exe", "-e", "bash", "-lc", cmd.replace(src, wsl_path(src))], capture_output=True, text=True)
    else:
        r = subprocess.run(["bash", "-lc", cmd], capture_output=True, text=True)
    if r.returncode:
        sys.exit(f"bend failed on {src}:\n{r.stdout}{r.stderr}")
    open(out, "w", newline="\n").write(r.stdout)


def py(*args):
    r = subprocess.run([sys.executable, *args], capture_output=True, text=True)
    if r.returncode:
        sys.exit(r.stdout + r.stderr)
    return r.stdout.strip()


runs = [("ex_oracle.py", [])]
runs += [("arr_oracle.py", [str(s), "300"]) for s in (7, 11, 12, 13)]
runs += [("arr_oracle.py", [str(s), "150", "nest"]) for s in (1, 2, 3, 4)]
runs += [("sol_oracle.py", [str(s), "150"]) for s in (1, 2, 3, 4)]
only = sys.argv[1:]
lines = []
for script, extra in runs:
    if only and not any(script.startswith(o) for o in only):
        continue
    tag = script[:-3] + "".join("_" + e for e in extra[2:]) + ("_" + extra[0] if extra else "")
    src = os.path.join(gen, tag + ".bend")
    out = os.path.join(gen, tag + ".out")
    py(os.path.join(here, script), "gen", src, *extra)
    bend_run(src, out)
    lines.append(f"{tag}: " + " | ".join(l for l in py(os.path.join(here, script), "check", out, *extra).splitlines() if "cases" in l or "filtered" in l))
print("\n".join(lines))
