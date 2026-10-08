# PSCV0 V6 Work State

**State:** V6 source-workspace organization only (2026-10-08). `THE_PSCV_COMPILER_REFERENCE_VERSION_6.md` is the proposed successor architecture; adoption/implementation completion and release conformance **are not claimed**.

## Snapshot and provenance

- Copied from `psc15selfhost/` in branch `research/pscv-compiler-v6-standalone-npm-lean` at commit `d41845a1f7c31879659eef3ad58ab8a493453456`; V6's underlying execution-source snapshot derives from `pscv/v3-execution` commit `93add6da4e501c57f9016c7c3666ea52c87a66e7`.
- Historical compiler execution log and V5.1 checkpoints: [legacy/AI_WORK_STATE.md](legacy/AI_WORK_STATE.md).
- Original V5.1 architecture: [legacy/THE_PSCV_COMPILER_REFERENCE_VERSION_5.1.md](legacy/THE_PSCV_COMPILER_REFERENCE_VERSION_5.1.md).
- Current specification authority: [PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md](PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md).
- Layout commit archives historical documentation and the unreferenced `pskernel-core.old2` snapshot. It deliberately retains operational compiler/packages/host/scripts/test closures and all four backends, so a new V6 implementation can be staged without destroying the existing baseline.

## 2026-10-08 V6 kernel-first npm core checkpoint

Implementation branch: [pscv/v6-minimal-npm-core](https://github.com/dwijayuda/pskernel/tree/pscv/v6-minimal-npm-core/pscv0/v6), draft [PR #83](https://github.com/dwijayuda/pskernel/pull/83).

- **Clean V6 source:** four small npm packages (pscv-core, pscv-kernel, pscv-extensions, pscv-cli) under v6/. They have no source imports from prior PSC2/PSC1/self-host compiler or backend implementation. No compatibility preservation is required when implementing the new compiler.
- **Live official-provider integration:** pskernel-lean 4.34 native and pskernel-lean-wasm 4.34 through public npm exports, exact provider identities, bounded v2 admission envelopes, native override and checkout fallback disabled, Wasm bundled verification retained.
- **Negative authority tests:** E5/E6/U3, unknown extension fields, unsafe paths, closed PSCV/Standard E1 syntax, false verified-build claims and provider envelope errors fail closed.
- **Cloud evidence:** PSCV V6 minimal npm core run [37755747470](https://github.com/dwijayuda/pskernel/actions/runs/37755747470) passed both jobs. Real native/Wasm provider job tested 10 cases, all passed: valid fully closed theorem, bogus proof body of the same proposition, invalid theorem, unsupported declaration and empty admissions for both transports. Unit job and package tarball dry-run passed independently.
- **Not implementation complete:** this P0 does not parse/elaborate .ps, issue PSCV-CERT, compile TS/JS/Wasm/Rust, prove source/Lean correspondence, sandbox running plugin code, or publish npm packages. build/verify deliberately reject. Normative PSCV pin is Lean 4.35-rc3; provider 4.34 cannot be silently treated as verified-profile compatible.

Next work: build the real small PSCV frontend and checked Core from the normative grammar (not port old source), introduce a native checked-session issuer, then exact-proof obligations and .proof.lean bridge. Keep compiler source/interface clean and archive/delete superseded implementation only when replacement functionality and regression evidence exist. Do not modify kernel internals; separate workstream owns soundness and promotion.

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
