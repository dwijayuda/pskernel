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
- **Independent CI scope:** root repository TypeScript kernel CI run [37755850485](https://github.com/dwijayuda/pskernel/actions/runs/37755850485) failed at the pre-existing package-map policy mismatch: packages/compiler/package.json marks sourceLanguage as typescript+lean+proofscript-bootstrap but scripts/package-map-check.mjs insists on typescript. The compiler manifest is identical on main and this branch. Do not disguise the mismatch by changing unrelated source policy just to green the V6 PR.
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

## 2026-10-08 Lean-native source reuse and binary-size checkpoint

- Replaced initial JS-authored V6 core/extension/checker/CLI implementation with pinned Lean 4.35.0-rc3 `.lean` source packages built natively. Development npm manifests contain Lean source; no finished compiler or PSCV certification claimed.
- Confirmed a native Lean compiler P0 and kernel checker plus npm Linux x64 tarballs in cloud CI. Independent existing Lean 4.34 native/Wasm provider oracle tests still run through npm facade exports; no cross-version equivalence claim.
- Research-only old Foundation, RuntimeIR, InterfaceIR, WIT validation and ProofScript parser source/import roots compile under Lean 4.35rc3; a targeted old IR/WIT behavior probe passed. Historical self-host restrictions are not requirements for new V6.
- Measured minimal Lean executable 4,401,136 bytes unstripped and 2,800,952 bytes after full stripping, against old V6 CLI 118,477,856 bytes unstripped. The oversized CLI imported Lean.Declaration transitively. Commit 516585c9a7daa2357cbc1ff3981457aa01eb4ea2 separates lightweight Init-only Core contracts from Lean.Declaration-bound kernel package; fresh core size pending.
- Proof safety: Lean's kernel intentionally supports axioms, so the P0 checker additionally rejects arbitrary unapproved axiom, unsafe and partial declaration candidates in the closed-policy path. This is not complete PSCV specification, assumption or effect checking.
- Upstream official Lean 4.35 has a special minimal initializer for checker-only binaries; its preconditions must be audited before use. No assumption of immediate binary shrink without fresh CI evidence.
- No implementation claim for `.ps` grammar, source→Core correctness, `.proof.lean`, PSCV-CERT, four backend output, plugin isolation or native package release.

## 2026-10-08 copied Lean 4.34 kernel npm packages into V6

- Copied the entire tracked Git trees of `pscv0/packages/pskernel-lean/` and `pscv0/packages/pskernel-lean-wasm/` to `pscv0/v6/packages/`, without changing original upstream/provider sources, 4.34 pins, release bundles or manifest digests. This is intentional functional reuse; provider source refactoring is deferred.
- The V6 npm workspace now resolves copied native/Wasm provider packages by their original public `@proofscript/*` npm identities. Existing prebuilt integrity verification and real accepted/rejected canonical-admission tests continue as V6 package conformance evidence.
- Added Lean-written provider metadata catalog for native/Wasm selection without loading the large Lean.Environment checker into the minimal CLI. This is configuration data, not kernel or certification authority.
- **Version gate unchanged:** V6 normative semantics are pinned to 4.35.0-rc3; both copied provider packages are 4.34.0. Their results do not automatically satisfy `pscv-v1`, source-fidelity, specification-coverage, `.proof.lean` bridge or `PSCV-CERT-v1`.
- The old compiler's `.lean` files may be directly reused where needed, but older self-host architecture, PSC1 profile restrictions and bootstrap import closure are not binding on V6. The V6 reference remains authoritative.
- Native provider-session integration and real `.ps` end-to-end compilation remain not implemented; no verified executable claim is added by these copies.
