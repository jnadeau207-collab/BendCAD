import sys
import numpy as np
import scipy.sparse.linalg as sla
from disc_modes import assemble


def spin(b, t, nr, nz, E, nu, rho, rpm):
    K, M = assemble(b, t, 0, nr, nz, E, nu, rho)
    rs = np.linspace(0.0, b, 2 * nr + 1)
    nzn = 2 * nz + 1
    nn = len(rs) * nzn
    w = rpm * 2 * np.pi / 60
    full = np.zeros(2 * nn)
    full[:nn] = np.repeat(rs, nzn) * w * w
    keep = np.setdiff1d(np.arange(2 * nn), np.arange(nzn))
    f = M @ full[keep]
    fix = len(keep) - 1
    free = np.arange(len(keep)) != fix
    u = np.zeros(len(keep))
    u[free] = sla.spsolve(K[free][:, free].tocsc(), f[free])
    ur = np.zeros(2 * nn)
    ur[keep] = u
    tip = ur[:nn].reshape(len(rs), nzn)[-1]
    return float(f @ u), float(tip.min()), float(tip.max())


if __name__ == '__main__':
    b, t, rpm = float(sys.argv[1]), float(sys.argv[2]), float(sys.argv[3])
    for nr, nz in ((40, 4), (80, 8), (160, 16)):
        print(nr, nz, spin(b, t, nr, nz, 200000.0, 0.3, 7.85e-9, rpm))
