import sys
import numpy as np
import scipy.sparse as sp
import scipy.sparse.linalg as sla


def gauss3():
    a = np.sqrt(0.6)
    return np.array([-a, 0.0, a]), np.array([5 / 9, 8 / 9, 5 / 9])


def q9(xi, eta):
    def l(s):
        return np.array([s * (s - 1) / 2, 1 - s * s, s * (s + 1) / 2])

    def dl(s):
        return np.array([s - 0.5, -2 * s, s + 0.5])

    lx, ly, dx, dy = l(xi), l(eta), dl(xi), dl(eta)
    return np.outer(lx, ly).ravel(), np.outer(dx, ly).ravel(), np.outer(lx, dy).ravel()


def assemble(b, t, n, nr, nz, E, nu, rho):
    lam = E * nu / ((1 + nu) * (1 - 2 * nu))
    mu = E / (2 * (1 + nu))
    rs = np.linspace(0.0, b, 2 * nr + 1)
    zs = np.linspace(-t / 2, t / 2, 2 * nz + 1)
    nzn = len(zs)
    nid = lambda i, j: i * nzn + j
    nn = len(rs) * nzn
    g, w = gauss3()
    rows, cols, kv, mv = [], [], [], []
    comps = 2 if n == 0 else 3
    for ei in range(nr):
        for ej in range(nz):
            ids = [nid(2 * ei + a, 2 * ej + c) for a in range(3) for c in range(3)]
            r0, r1 = rs[2 * ei], rs[2 * ei + 2]
            z0, z1 = zs[2 * ej], zs[2 * ej + 2]
            hr, hz = (r1 - r0) / 2, (z1 - z0) / 2
            ke = np.zeros((9 * comps, 9 * comps))
            me = np.zeros((9 * comps, 9 * comps))
            for gi, wi in zip(g, w):
                for gj, wj in zip(g, w):
                    N, Nr, Nz = q9(gi, gj)
                    Nr, Nz = Nr / hr, Nz / hz
                    r = r0 + (gi + 1) * hr
                    dv = wi * wj * hr * hz * r
                    Z = np.zeros(9)
                    if n == 0:
                        ur, uz = slice(0, 9), slice(9, 18)
                        B = np.array([np.concatenate([Nr, Z]), np.concatenate([N / r, Z]), np.concatenate([Z, Nz]), np.concatenate([Nz, Nr])])
                        D = np.array([[lam + 2 * mu, lam, lam, 0], [lam, lam + 2 * mu, lam, 0], [lam, lam, lam + 2 * mu, 0], [0, 0, 0, mu]])
                        ke += 2 * np.pi * B.T @ D @ B * dv
                        Mb = np.vstack([np.concatenate([N, Z]), np.concatenate([Z, N])])
                        me += 2 * np.pi * rho * Mb.T @ Mb * dv
                    else:
                        B = np.array([np.concatenate([Nr, Z, Z]), np.concatenate([N / r, n * N / r, Z]), np.concatenate([Z, Z, Nz]),
                                      np.concatenate([Nz, Z, Nr]), np.concatenate([-n * N / r, Nr - N / r, Z]), np.concatenate([Z, Nz, -n * N / r])])
                        D = np.diag([0.0, 0, 0, mu, mu, mu])
                        D[:3, :3] = lam
                        D[0, 0] = D[1, 1] = D[2, 2] = lam + 2 * mu
                        ke += np.pi * B.T @ D @ B * dv
                        Mb = np.vstack([np.concatenate([N, Z, Z]), np.concatenate([Z, N, Z]), np.concatenate([Z, Z, N])])
                        me += np.pi * rho * Mb.T @ Mb * dv
            dofs = [c * nn + i for c in range(comps) for i in ids]
            rr, cc = np.meshgrid(dofs, dofs, indexing='ij')
            rows.append(rr.ravel())
            cols.append(cc.ravel())
            kv.append(ke.ravel())
            mv.append(me.ravel())
    rows, cols = np.concatenate(rows), np.concatenate(cols)
    nd = comps * nn
    K = sp.csr_matrix((np.concatenate(kv), (rows, cols)), shape=(nd, nd))
    M = sp.csr_matrix((np.concatenate(mv), (rows, cols)), shape=(nd, nd))
    axis = [nid(0, j) for j in range(nzn)]
    if n == 0:
        fixed = axis
    elif n == 1:
        fixed = [2 * nn + i for i in axis]
    else:
        fixed = [c * nn + i for c in range(3) for i in axis]
    keep = np.setdiff1d(np.arange(nd), fixed)
    K = K[keep][:, keep]
    M = M[keep][:, keep]
    if n == 1:
        pass
    return K, M


def freqs(b, t, n, nr, nz, E, nu, rho, k):
    K, M = assemble(b, t, n, nr, nz, E, nu, rho)
    sigma = -1.0e3
    vals = sla.eigsh(K, k=k + 3, M=M, sigma=sigma, which='LM', return_eigenvectors=False)
    vals = np.sort(vals)
    hz = np.sqrt(np.clip(vals, 0, None)) / (2 * np.pi)
    return [h for h in hz if h > 1.0][:k]


if __name__ == '__main__':
    b, t = float(sys.argv[1]), float(sys.argv[2])
    E, nu, rho = 200000.0, 0.3, 7.85e-9
    for n in (2, 0, 3):
        rows = []
        for nr, nz in ((40, 4), (80, 8), (160, 16)):
            rows.append(freqs(b, t, n, nr, nz, E, nu, rho, 2))
        print(n, [[round(x, 6) for x in r] for r in rows])
