import os, subprocess, sys

here = os.path.dirname(os.path.abspath(__file__))
gen = os.path.join(here, "gen")
os.makedirs(gen, exist_ok=True)


def wsl_path(p):
    d, rest = os.path.splitdrive(os.path.abspath(p))
    return "/mnt/" + d[0].lower() + rest.replace("\\", "/")


def bend_run(src, out):
    exe = "/tmp/bendcad-c05-" + os.path.basename(src)[:-6]
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



lines = []
for seed in (2, 3):
    src = os.path.join(gen, f"pred_oracle_{seed}.bend")
    out = os.path.join(gen, f"pred_oracle_{seed}.out")
    py(os.path.join(here, "pred_oracle.py"), "gen", src, str(seed))
    bend_run(src, out)
    lines.append(f"pred_oracle_{seed}: " + py(os.path.join(here, "pred_oracle.py"), "check", out, str(seed)))
print("\n".join(lines))
