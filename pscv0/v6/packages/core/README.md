# @proofscript/pscv-core

New, small composition skeleton. It has no old compiler dependencies.

createCompilerCore returns a profile-scoped plan, inspectSource returns source identity only, and checkCanonicalAdmissions delegates to an exact pinned native or Wasm Lean kernel package. build and verify reject because PSCV parsing, elaboration, proof closure, erasure, target IR validation and backend emission are not yet implemented here.

The final native compiler will be built with Lean and distributed without a mandatory Lean development toolchain or Node runtime. This npm JavaScript API is a preliminary orchestration and contract verification slice only; it is not an implementation of all PSCV language features.
