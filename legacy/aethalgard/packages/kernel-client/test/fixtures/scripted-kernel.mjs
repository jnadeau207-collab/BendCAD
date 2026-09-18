// Deterministic fake kernel host for transport and queue tests. Speaks the
// 4-byte little-endian length-prefixed JSON control protocol on stdin/stdout;
// fd 3 is the binary mesh pipe. Never links real OCCT.
//
// Behaviors (AETH_SCRIPTED_KERNEL_BEHAVIOR):
//   "garbage"                    — writes a corrupt control frame at startup.
//   "timeout"                    — accepts requests and never responds.
//   "corrupt-control-after:N"    — answers the first N evaluate_document
//                                  requests normally, then poisons the
//                                  control stream on the next one.
//   "corrupt-binary-on-evaluate" — writes a corrupt binary mesh frame instead
//                                  of answering the first evaluate_document.
//   "stuck-evaluate-bad-cancel:<mode>"
//                                — accepts evaluate_document and NEVER answers
//                                  it (forcing a transport timeout with the
//                                  worker still "in flight"), then answers the
//                                  queue's idleness cancel with a reply that is
//                                  NOT proof of idleness: mode "error" sends an
//                                  ok:false error; mode "mismatch" sends a
//                                  well-formed ok cancellation naming a
//                                  DIFFERENT target. Health is answered so the
//                                  supervisor handshake still succeeds.
//   "restart-then-unhealthy"     — a two-spawn crash-recovery script driven by
//                                  a spawn-counter file (AETH_SCRIPTED_KERNEL_
//                                  SPAWN_COUNTER, required). Each spawn reads
//                                  and increments the counter to learn its
//                                  ordinal. Spawn #1 answers health, then exits
//                                  code 1 on the first `cancel` (a shutdown-like
//                                  request), simulating a post-ready crash.
//                                  Spawn #2 answers health with ok:false, so the
//                                  supervisor's restart handshake fails — the
//                                  fix must land the supervisor on "dead".
//   "feasibility-error"          — returns a structured GEOMETRY_FAILED repair payload.\n//   "respond" (default)          — full scripted protocol emulation.
//
// In respond mode, evaluate_document answers after a delay encoded in the
// first operation's name ("sleep:<ms>", default 0) with an empty body list
// echoing the request revision. Protocol cancel is honored out of band, like
// the real host: a pending evaluate answers CANCELLED and the cancel request
// gets a cancellation acknowledgement.
//
// When AETH_SCRIPTED_KERNEL_REQUEST_LOG is set, every decoded request is
// appended to that file as one JSON line, so tests can assert exactly which
// requests produced host traffic.
import { Buffer } from "node:buffer";
import {
  appendFileSync,
  readFileSync,
  writeFileSync,
  writeSync,
} from "node:fs";
import process from "node:process";
import { clearTimeout, setTimeout } from "node:timers";

const behavior = process.env.AETH_SCRIPTED_KERNEL_BEHAVIOR ?? "respond";
const requestLogPath = process.env.AETH_SCRIPTED_KERNEL_REQUEST_LOG;
const corruptControlAfter = /^corrupt-control-after:(\d+)$/.exec(behavior);
const stuckEvaluateBadCancel =
  /^stuck-evaluate-bad-cancel:(error|mismatch)$/.exec(behavior);
const restartThenUnhealthy = behavior === "restart-then-unhealthy";

// Which spawn are we? Only meaningful for restart-then-unhealthy, which uses
// the ordinal to script spawn #1 (crash on cancel) versus spawn #2 (unhealthy
// handshake). Spawns are strictly sequential here, so a read-modify-write of a
// plain counter file is race-free.
const spawnCounterPath = process.env.AETH_SCRIPTED_KERNEL_SPAWN_COUNTER;
let spawnOrdinal = 0;
if (spawnCounterPath) {
  let previous;
  try {
    previous = Number.parseInt(readFileSync(spawnCounterPath, "utf8"), 10) || 0;
  } catch {
    previous = 0;
  }
  spawnOrdinal = previous + 1;
  writeFileSync(spawnCounterPath, String(spawnOrdinal));
}
// A fixed, valid UUID distinct from any real request id, used by the
// "mismatch" mode to emit a syntactically valid cancellation ack that names
// the WRONG target — the queue must reject it as non-proof of idleness.
const wrongCancelTarget = "11111111-1111-4111-8111-111111111111";

const build = {
  kernelProtocolVersion: 3,
  kernelHostVersion: "scripted-kernel",
  occtTag: "V8_0_0_p1",
  occtCommit: "4f95ecaa3b690e34988d42e2ca7fe882e7a8bc7d",
  occtManifestSha256: "0".repeat(64),
  compiler: "scripted",
  buildType: "Scripted",
};

/** Pending evaluate_document timers by requestId, for protocol cancel. */
const pendingEvaluations = new Map();
let answeredEvaluations = 0;

function encodeFrame(value) {
  const payload = Buffer.from(JSON.stringify(value), "utf8");
  const frame = Buffer.alloc(4 + payload.byteLength);
  frame.writeUInt32LE(payload.byteLength, 0);
  payload.copy(frame, 4);
  return frame;
}

function respondOk(requestId, result) {
  process.stdout.write(
    encodeFrame({ protocolVersion: 3, requestId, ok: true, result }),
  );
}

function respondError(requestId, code, message, attributes = {}) {
  process.stdout.write(
    encodeFrame({
      protocolVersion: 3,
      requestId,
      ok: false,
      error: { code, message, ...attributes },
    }),
  );
}

/** A declared-empty frame whose payload fails JSON parsing on the client. */
function poisonControlStream() {
  process.stdout.write(Buffer.alloc(4));
}

function poisonBinaryStream() {
  writeSync(3, Buffer.alloc(12, 0xff));
}

function logRequest(request) {
  if (!requestLogPath) return;
  appendFileSync(
    requestLogPath,
    JSON.stringify({
      pid: process.pid,
      method: request.method,
      requestId: request.requestId,
      targetRequestId: request.targetRequestId,
    }) + "\n",
  );
}

function sleepMillisecondsFor(request) {
  const name = request.operations?.[0]?.name ?? "";
  const match = /^sleep:(\d+)$/.exec(name);
  return match ? Number(match[1]) : 0;
}

function handleEvaluate(request) {
  if (behavior === "feasibility-error") {
    const operationId = request.operations?.[0]?.id;
    respondError(
      request.requestId,
      "GEOMETRY_FAILED",
      "fillet construction failed",
      {
        operationId,
        details: {
          requestedRadius: 20,
          maxFeasibleRadius: 4.98,
          feasibilityProbe: {
            parameter: "radius",
            requested: 20,
            maxFeasible: 4.98,
            bound: "tested-lower-bound",
            attempts: 12,
          },
        },
      },
    );
    return;
  }
  if (behavior === "corrupt-binary-on-evaluate") {
    poisonBinaryStream();
    return;
  }
  if (stuckEvaluateBadCancel) {
    // Accept the work but never answer it: the queue's transport deadline
    // elapses with the request still notionally in flight, so it must prove
    // the host is idle via a protocol cancel before dispatching anything else.
    return;
  }
  if (corruptControlAfter) {
    const answerLimit = Number(corruptControlAfter[1]);
    if (answeredEvaluations >= answerLimit) {
      poisonControlStream();
      return;
    }
  }
  const timer = setTimeout(() => {
    pendingEvaluations.delete(request.requestId);
    answeredEvaluations += 1;
    respondOk(request.requestId, {
      type: "evaluation",
      revision: request.revision,
      epoch: 1,
      bodies: [],
    });
  }, sleepMillisecondsFor(request));
  pendingEvaluations.set(request.requestId, timer);
}

function handleCancel(request) {
  if (stuckEvaluateBadCancel) {
    // Reply in a way that does NOT prove the target worker stopped.
    if (stuckEvaluateBadCancel[1] === "error") {
      respondError(
        request.requestId,
        "INTERNAL_ERROR",
        "cancel could not stop the worker",
      );
    } else {
      respondOk(request.requestId, {
        type: "cancellation",
        targetRequestId: wrongCancelTarget,
      });
    }
    return;
  }
  const pending = pendingEvaluations.get(request.targetRequestId);
  if (pending) {
    clearTimeout(pending);
    pendingEvaluations.delete(request.targetRequestId);
    respondError(request.targetRequestId, "CANCELLED", "cancelled by request");
  }
  respondOk(request.requestId, {
    type: "cancellation",
    targetRequestId: request.targetRequestId,
  });
}

/**
 * The two-spawn crash-recovery script. Spawn #1 is a healthy host that dies
 * (exit code 1) on the first shutdown-like `cancel`; spawn #2 answers the
 * supervisor's restart handshake with ok:false so the restart fails.
 */
function handleRestartThenUnhealthy(request) {
  if (request.method !== "health") {
    if (spawnOrdinal <= 1 && request.method === "cancel") {
      // A post-ready crash: die without answering, exactly like a host that
      // fell over mid-request. The client sees the exit and the supervisor
      // enters crash recovery.
      process.exit(1);
    }
    respondError(
      request.requestId,
      "UNSUPPORTED_OPERATION",
      `scripted kernel does not implement ${request.method}`,
    );
    return;
  }
  if (spawnOrdinal >= 2) {
    // The replacement is unhealthy: a well-formed ok:false handshake reply.
    // The supervisor must reject it and land on a terminal "dead" state.
    respondError(
      request.requestId,
      "INTERNAL_ERROR",
      "replacement kernel is unhealthy",
    );
    return;
  }
  respondOk(request.requestId, { type: "health", build });
}

function handleRequest(request) {
  logRequest(request);
  if (behavior === "timeout" || behavior === "garbage") return;
  if (restartThenUnhealthy) {
    handleRestartThenUnhealthy(request);
    return;
  }
  switch (request.method) {
    case "health":
      respondOk(request.requestId, { type: "health", build });
      return;
    case "evaluate_document":
      handleEvaluate(request);
      return;
    case "cancel":
      handleCancel(request);
      return;
    default:
      respondError(
        request.requestId,
        "UNSUPPORTED_OPERATION",
        `scripted kernel does not implement ${request.method}`,
      );
  }
}

let inbox = Buffer.alloc(0);
process.stdin.on("data", (chunk) => {
  inbox = Buffer.concat([inbox, chunk]);
  while (inbox.byteLength >= 4) {
    const size = inbox.readUInt32LE(0);
    if (inbox.byteLength < 4 + size) break;
    const payload = inbox.subarray(4, 4 + size);
    inbox = inbox.subarray(4 + size);
    handleRequest(JSON.parse(payload.toString("utf8")));
  }
});
process.stdin.on("end", () => process.exit(0));
process.stdin.resume();

if (behavior === "garbage") {
  process.stdout.write(Buffer.alloc(12));
}

process.on("SIGTERM", () => process.exit(0));
