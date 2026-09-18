#pragma once

#include <cstdint>
#include <string>
#include <vector>

#include <nlohmann/json.hpp>

// Content hash of a CAD operation — the C++ side of the shared contract that
// lets the kernel and the @aeth/geometry-contracts document layer agree
// byte-for-byte on what an operation "is", so the replay cache can be
// content-addressed without the two sides ever disagreeing on a hit. Spec:
// docs/design/2026-07-17-op-hash-contract.md. Twin of
// packages/geometry-contracts/src/operation-hash.ts, pinned bit-for-bit by
// fixtures/golden/operation-hash-v1.json (aeth-canonical-hash-test).
namespace aeth {

// The version tag mixed into the cache-line root — a format bump invalidates
// every line. Must equal the TS `operationHashVersion`.
inline constexpr const char* kOperationHashVersion = "aeth-op-hash-v1";

// ECMAScript Number::toString(x, 10) — the shortest round-trip decimal
// (RFC 8785 §3.2.2.3). Reproduces V8's `String(x)` for finite doubles; throws on
// NaN/Infinity (fail closed). The TS twin is `jcsNumber`.
std::string EcmaNumberToString(double value);

// RFC 8785 (JSON Canonicalization Scheme) serialization of a JSON value: sorted
// object keys, no whitespace, ECMAScript string escaping, EcmaNumberToString
// numbers. The TS twin is `canonicalJson`.
std::string CanonicalJson(const nlohmann::json& value);

// UTF-8 bytes of an operation's hashable projection — its type/schemaVersion/
// identity/parameters, with name, metadata, and ref anchors stripped — as
// RFC 8785 JCS. The per-operation contribution to the cumulative cache key. The
// TS twin is `canonicalOperationBytes`.
std::vector<std::uint8_t> CanonicalOperationBytes(const nlohmann::json& operation);

// Every cumulative prefix hash [H(-1), H(0), …, H(n-1)] (lowercase hex,
// length n+1):
//   H(-1) = SHA-256(JCS({ v, documentId, kernelGeomVersion }))
//   H(i)  = SHA-256(H(i-1) [32 bytes] ‖ canonicalOperationBytes(op[i]))
// The L1 replay-cache key at each prefix boundary. The TS twin is
// `cumulativeOperationHashes`.
std::vector<std::string> CumulativeOperationHashes(const std::string& documentId,
                                                   const std::string& kernelGeomVersion,
                                                   const nlohmann::json& operations);

// The terminal cumulative hash H(n-1). The TS twin is `cumulativeOperationHash`.
std::string CumulativeOperationHash(const std::string& documentId,
                                    const std::string& kernelGeomVersion,
                                    const nlohmann::json& operations);

} // namespace aeth
