export * from "./binary-frame.js";
export * from "./definition-evaluation-cache.js";
export * from "./exact-interference.js";
export * from "./isolated-kernel-session.js";
export * from "./mate-frame-resolution.js";
export * from "./mutation-session.js";
// NativeKernelClient.request stays exported for the supervisor handshake,
// protocol cancel frames, and tests. Product code submits work through
// KernelRequestQueue, which serializes requests toward the single-threaded
// host with deadlines, cancellation, bounded depth, and epoch awareness.
export * from "./native-kernel-client.js";
export * from "./request-queue.js";
export * from "./supervisor.js";
