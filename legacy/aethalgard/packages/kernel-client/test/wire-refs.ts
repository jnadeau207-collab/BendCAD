/**
 * Minimal kernel-wire ref-slot AST builders (`operationRefWireSchema` `{ast}`),
 * shared by the catalog-wave1 transport + native staging-pin suites.
 *
 * N6 slice C lowers a persisted `{query}` to this wire form at the doc→kernel
 * boundary (`lowerOperationsForKernel`, @aeth/document-model), and the kernel
 * request schema now REQUIRES it — a raw `{query}` reaching the wire is refused
 * fail-closed. So these pins submit exactly what production ships. kernel-client
 * does NOT depend on @aeth/document-model, so the parser/lowering are out of
 * reach; these builders emit the same `selectorQuerySchema` shape by hand.
 *
 * Each staged op is refused by the kernel BEFORE it resolves the ref
 * (registry-required / dispatch-else), so only the AST's structural validity is
 * load-bearing here; the shapes still mirror the original queries so a future
 * registry-threaded upgrade to real coverage starts from the right selector.
 */

/** `<kind>(op(<opId>)).<filters…>` */
export function opQuery(
  kind: string,
  opId: string,
  filters: unknown[] = [],
): unknown {
  return { kind, scope: [{ source: "op", opId }], filters };
}

/** `<kind>(world(<world>))` */
export function worldQuery(kind: string, world: string): unknown {
  return { kind, scope: [{ source: "world", world }], filters: [] };
}

/** `faces(op(<opId>)).normal(+z)` — the shell/openFaces staging selector. */
export function opFacesNormalZ(opId: string): unknown {
  return {
    kind: "faces",
    scope: [{ source: "op", opId }],
    filters: [
      {
        name: "normal",
        args: [
          { arg: "direction", value: { form: "axis", sign: 1, axis: "z" } },
        ],
      },
    ],
  };
}
