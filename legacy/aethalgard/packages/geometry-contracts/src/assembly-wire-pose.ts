/**
 * Explicit name for the matrix pose that crosses the assembly-host boundary.
 *
 * The original recovered protocol exported this as `RigidPose`, colliding with
 * the persisted quaternion pose in `@aeth/document-model`. Keep the old export
 * for forensic/source compatibility, but new code must import this name so a
 * transport matrix can never be mistaken for document state.
 */
export { rigidPoseSchema as assemblyWirePoseSchema } from "./assembly-protocol.js";
export type { RigidPose as AssemblyWirePose } from "./assembly-protocol.js";
