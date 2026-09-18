import type {
  SelectorArg,
  SelectorFilter,
  SelectorQuery,
  SelectorSource,
} from "./selector-ast.js";
import { filterCatalog } from "./selector-catalog.js";

/**
 * Canonical AQL printing (plan 05 §3.4): no whitespace, numbers via ES6
 * `Number.prototype.toString`, default-valued optional arguments omitted,
 * sources in lexicographic order (the parser guarantees that on the AST),
 * strings in minimal double-quote escaping. The canonical string feeds
 * subgraph hashing (plan 01 §10.1) AND the op-hash ref-slot projection (N6 A′),
 * so any change here is a document-identity change.
 *
 * Home: `@aeth/geometry-contracts` (beside the AST types + catalog), so the
 * op-hash can project a ref slot over its printed canonical selector without
 * inverting the package layering. The C++ twin is
 * `native/kernel-host/src/selector_print.cpp` (`PrintSelector`), pinned
 * byte-for-byte by `fixtures/golden/selector-print-v1.json`.
 * `@aeth/document-model` re-exports this for its own consumers.
 */

function printString(value: string): string {
  return `"${value.replace(/\\/g, "\\\\").replace(/"/g, '\\"')}"`;
}

export function printSource(source: SelectorSource): string {
  switch (source.source) {
    case "op":
    case "body":
    case "sketch":
      return `${source.source}(${source.opId})`;
    case "tag":
      return `tag(${printString(source.tag)})`;
    case "token":
      return `token(${printString(source.token)})`;
    case "world":
      return `world(${source.world})`;
    case "all":
      return "all";
  }
}

function printArg(arg: SelectorArg): string {
  switch (arg.arg) {
    case "number":
      return String(arg.value);
    case "string":
      return printString(arg.value);
    case "ident":
    case "axis":
      return arg.value;
    case "direction":
      return arg.value.form === "axis"
        ? `${arg.value.sign === 1 ? "+" : "-"}${arg.value.axis}`
        : `[${arg.value.vector.map(String).join(",")}]`;
    case "point":
      return `[${arg.value.map(String).join(",")}]`;
    case "query":
      return printSelector(arg.value);
  }
}

function printFilter(filter: SelectorFilter): string {
  const spec = filterCatalog.get(filter.name);
  const args = [...filter.args];
  // Omit trailing optional arguments that exactly equal their defaults.
  if (spec) {
    for (let index = args.length - 1; index >= 0; index -= 1) {
      const param = spec.params[index];
      const arg = args[index];
      if (
        param?.optional &&
        param.defaultValue !== undefined &&
        arg?.arg === "number" &&
        Object.is(arg.value, param.defaultValue)
      ) {
        args.pop();
        continue;
      }
      break;
    }
  }
  return `${filter.name}(${args.map(printArg).join(",")})`;
}

/** Prints a canonical AST back to its canonical string form. */
export function printSelector(query: SelectorQuery): string {
  const scope = query.scope.map(printSource).join(",");
  const filters = query.filters
    .map((filter) => `.${printFilter(filter)}`)
    .join("");
  return `${query.kind}(${scope})${filters}`;
}
