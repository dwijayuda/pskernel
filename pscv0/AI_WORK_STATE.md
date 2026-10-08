# PSCV0 V6 Work State

**State:** V6 source-workspace organization only (2026-10-08). `THE_PSCV_COMPILER_REFERENCE_VERSION_6.md` is the proposed successor architecture; adoption/implementation completion and release conformance **are not claimed**.

## Snapshot and provenance

- Copied from `psc15selfhost/` in branch `research/pscv-compiler-v6-standalone-npm-lean` at commit `d41845a1f7c31879659eef3ad58ab8a493453456`; V6's underlying execution-source snapshot derives from `pscv/v3-execution` commit `93add6da4e501c57f9016c7c3666ea52c87a66e7`.
- Historical compiler execution log and V5.1 checkpoints: [legacy/AI_WORK_STATE.md](legacy/AI_WORK_STATE.md).
- Original V5.1 architecture: [legacy/THE_PSCV_COMPILER_REFERENCE_VERSION_5.1.md](legacy/THE_PSCV_COMPILER_REFERENCE_VERSION_5.1.md).
- Current specification authority: [PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md](PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md).
- Layout commit archives historical documentation and the unreferenced `pskernel-core.old2` snapshot. It deliberately retains operational compiler/packages/host/scripts/test closures and all four backends, so a new V6 implementation can be staged without destroying the existing baseline.

## Pending implementation tasks

1. Verify unchanged functional baseline and clean-machine native `psc` closure.
2. Port production checked-session/certificate capabilities into the native composition root before advertising checked/verified `psc` operations.
3. Add separate ProofScript proof discovery, immutable obligation binding and certification.
4. Implement optional official Lean proof sidecar and checked cross-language proposition/subject bridge.
5. Specify and implement npm package resolution, separate PSCV semantic lock, and isolated E0–E5 extension execution.
6. Maintain TS/JS/Wasm/Rust backends, typed artifacts, native release validation and negative tests.
7. Complete additional assurance; self-host/diverse bootstrap evidence is separately scheduled and **not** required to start native distribution.

## Boundary and evidence policy

No V6 native release, proof interoperability, npm publication, complete compiler preservation or certification evidence is newly established by the layout change. Do not edit kernel/provider internals in this workstream; consume only their interfaces and independent results.
