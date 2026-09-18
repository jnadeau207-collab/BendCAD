#pragma once

#include <string>

#include <nlohmann/json.hpp>

namespace aeth {

/// Prints a canonical AQL AST (the wire `{kind, scope, filters}` form, plan 05
/// §3) back to its canonical string form — the C++ half of the cross-language
/// `printSelector` ≡ `PrintSelector` contract (op-hash-contract §"⚠ pre-N6";
/// docs/design/2026-07-23-phase4-native-geometry.md §5). The op-hash projects
/// every ref slot over this string so the persisted `query` (printed by TS
/// `printSelector(parse(query))`) and the wire `ast` (printed here) canonicalize
/// to IDENTICAL bytes across the query→ast transport.
///
/// Byte-for-byte identical to @aeth/document-model `print.ts printSelector`:
/// no whitespace; numbers via ECMAScript `Number.prototype.toString`
/// (`EcmaNumberToString`, shared with the op-hash JCS printer); default-valued
/// trailing optional filter arguments omitted using the §3.2 catalog defaults
/// replicated here; strings in minimal `\`/`"` double-quote escaping. Pinned by
/// `fixtures/golden/selector-print-v1.json`, asserted from both languages.
///
/// Throws `std::runtime_error`/`std::invalid_argument` on a malformed AST (a
/// missing discriminant, an unknown source/arg tag, a non-finite number) — the
/// caller has already parsed + validated the AST doc-side, so a throw here is a
/// contract violation, never user input.
std::string PrintSelector(const nlohmann::json& ast);

} // namespace aeth
