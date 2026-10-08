# PSCV V6 Lean-native compiler: source-reuse research and implementation decision

**Status:** source-backed implementation research. The native scaffold is implemented on a review branch; the complete PSCV frontend, proofs and backends are not yet built.
**Date:** 2026-10-08.
**Repository:** dwijayuda/pskernel, main/pscv0 source snapshot with candidate work in pscv/v6-minimal-npm-core.
**Normative PSCV grammar/meaning:** ../PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md, ps-0.9-r3, verified profile pscv-v1, PSCV-VERIFY-v1 and PSCV-CERT-v1.
**Lean build and semantic pin:** Lean 4.35.0-rc3 at 470d5ce1400764999581fd26d5d72b00d990b0f4.
**Independent existing provider pins:** pskernel-lean and pskernel-lean-wasm version 4.34.0 at 293d5d0c0c3f3dded4688b3ccd6a33939ac5102b.

## 1. Architecture decisions

All compiler implementation packages, extension algorithms, verification passes and backend code are written as Lean 4 source modules, using the PSCV language reference for the target behavior of .ps rather than pretending that .ps and .lean have identical syntax. The initial development/release compiler is a native executable built with the official Lean 4 compiler through Lake. When PSCV's four first-class backend packages mature, they can compile selected .ps sources independently; self-hosting is not an initial requirement.

npm is a transport and distribution mechanism. It may contain Lean source, prebuilt native executables, later Wasm components, ProofScript libraries, proof files and SDK metadata. The npm registry itself does not grant proof authority or define PSCV semantics. Node-based npm launchers and integration tests are allowed, but no handwritten JavaScript implements PSCV core, elaborator, source semantics, kernel acceptance policy or compiler passes.

Do not preserve old code or bootstrap profile for its own sake. Extract useful algorithms and tests from the previous Lean implementation; simplify or replace its interfaces freely when correctness and functionality are covered. Old history is retained in Git, not as a mandatory runtime dependency or API-compatibility burden.

## 2. Primary upstream research

Lean's Lake lean_lib targets group importable Lean modules. Its lean_exe target builds a native executable rooted at a Lean main function. A native Lean program needs the linked/bundled Lean runtime and ABI-compatible native libraries, but not the Lean development toolchain on the user's machine. Build time, runtime, and optional Lean source elaboration are distinct dependencies.

Official references:
- https://lean-lang.org/doc/reference/latest/Build-Tools-and-Distribution/Lake/
- https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Expr.lean
- https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Declaration.lean
- https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Environment.lean
- https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF.lean
- https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/LeanExport.lean
- https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/LeanChecker.lean
- https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/lake/Lake/Check/Compare.lean
- https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/lake/Lake/Check/Axioms.lean
- https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Std/WP.lean
- https://docs.npmjs.com/cli/v11/configuring-npm/package-json

Lean's core facilities are good *kernel term representations*, but Lean's full Meta and Elab modules introduce a larger import/runtime closure. Use upstream APIs where they remove duplicated semantics, then measure binary size, build time and trusted functionality. Do not assume importing full Lean automatically yields a small compiler.

## 3. Audited old code inventory and reuse choices

The copied PSCV0 codebase already contains more than 100 Lean source modules for compiler and target backends. Counts below are inspected tracked .lean files, not maturity scores.

| Old package | .lean files | Reuse decision |
|---|---:|---|
| foundation | 5 | Adapt source spans, diagnostics, text invariants; drop custom List/Name helpers where Lean stdlib suffices |
| syntax | 12 | Reuse lexer/token source algorithms and fixtures; reconsider hard-coded parser architecture |
| core | 8 | Do not adopt a second foundational Expr unchecked; prefer pinned Lean.Expr/Lean.Declaration |
| environment | 7 | Extract general name-resolution patterns; do not retain PSC1 self-host prelude as PSCV standard environment |
| meta | 6 | Use tests and mathematical edge cases; prefer official Lean typing, reduction and metavariable machinery |
| elab | 4 | Extract semantic algorithms and error taxonomies, then bind to new typed Core |
| compiler | 7 | Reuse pipeline/claim boundary concepts, not old bootstrap composition |
| bridge | 4 | High value: canonical admissions codec and exact provider protocol; validate from the reference |
| compiler-ir | 16 | High value: typed RuntimeIR models, validators, specialization and public interfaces |
| erasure | 6 | Medium–high: adapt to new Core and independently validate proof/ghost erasure |
| backend-ts | 3 | High value after stable IR; later npm package |
| backend-js | 6 | High value: separate JsIR, validator, lowering, printer |
| backend-wasm | 21 | High value: WasmIR, binary encoding, target validation, ABI/runtime lowering |
| backend-rust | 9 | High value: capture/closure, source lowering and runtime ABI |
| project | 4 | High value: QueryGraphV2, dependency and structural/behavioral interfaces |
| interface-ir | 6 | High value: InterfaceIR, WIT, Canonical ABI and validators |
| theory-bridge | 3 | Use checked syntax correspondence as an initial test; semantic preservation explicitly unproved |
| bootstrap + driver-* | 19 | No mandatory reuse: old self-host source closure no longer dictates V6 |
| pskernel-core | 79 | Separate kernel workstream; consume interface/evidence but do not fork implementation |

## 4. The most important elimination: duplicate Core models

Old packages/core/src/Ps/Core/Expr.lean defines PsExpr, PsLevel, PsName and PsDeclaration; packages/meta then reimplement infer/reduction/unification. Lean 4 already has Lean.Name, Lean.Level, Lean.Expr, Lean.Declaration and checked Environment. Maintaining two logically active Core representations adds a difficult fidelity relation and potential false-acceptance surface.

**Decision:** new V6 logical candidate declarations use the pinned upstream Lean Core representation. Keep a separate ProofScript source AST and explicit versioned elaboration contract, but do not extend the kernel theory with arbitrary plugin-produced primitive expressions. Where historical erasure/backends expect PsExpr, use a dedicated typed adapter and check/validate its relation before treating outputs as semantically authoritative. A temporary adapter is acceptable during an actual staged migration; maintaining both forever merely for compatibility is not.

Old parser sample packages/syntax/src/Ps/Syntax/ParseProofScript.lean has reusable call/lexical algorithms, but profile rules and structure are hard coded. Source feature extensions should instead use a separately versioned extensible grammar profile; closed pscv-v1 uses a fully specified deterministic grammar. E1 expansions are candidates and must be reparsed/re-elaborated against owned rules.

Old packages/environment/src/Ps/Environment/SelfHostProd.lean hand-builds a PSC1 bootstrap prelude; this is *not* the normative Lean 4.35 PSCV Standard environment. Reconstruct the exact manifest and ordered instances/notation/coercions/verification registries; the digest is still PENDING in the normative PSCV reference.

## 5. Initial native package topology

Root native build graph using one pinned Lake workspace:

- @proofscript/pscv-core — Lean implementation of Core candidate/typed semantic interfaces; no authority from plain data
- @proofscript/pscv-extensions — Lean implementation of extension-class policies and descriptors; no in-process execution of arbitrary npm code
- @proofscript/pscv-kernel — Lean native checker bridge and eventually session-bound checked Core; compare with 4.34 provider packages only for supported regression cases
- @proofscript/pscv-cli — Lean main function and native executable, with explicit unsupported errors for incomplete compiler functions

Development CLI: pscv_v6_dev, not production psc until source checking/certification/conformance gates are satisfied.

Future packages, only as needed: @proofscript/pscv-syntax, @proofscript/pscv-elab, @proofscript/pscv-verified-ir, @proofscript/pscv-backend-js, -ts, -wasm, -rust, @proofscript/pscv-proofs, @proofscript/pscv-lean-proof, @proofscript/pscv-extension-host, and native platform packages.

A source npm package does not automatically become an importable Lean package. Lake's module roots and dependency locks are owned by the build graph. Published binaries are compiled and packaged per actual OS/CPU/libc/ABI target, with hashes, runtime dependencies and license notices. Do not require users to compile Lean at npm install time or run arbitrary postinstall scripts.

## 6. Where the current 4.34 kernel npm packages fit

@proofscript/pskernel-lean and -wasm expose the canonical proofscript-checked-admissions/2 provider interface and verify pinned metadata/prebuilt binaries. They are useful independent oracles and portability references. Their semantic pin is Lean 4.34.0.

Lean-native V6 should compile at the normative 4.35.0-rc3 pin, and can use its directly linked official Lean kernel for candidate checking. The 4.34 native/Wasm npm packages must not silently replace a 4.35 checker, and an oracle decision cannot mint a PSCV-CERT. Develop or obtain a matching 4.35 provider package, or separately establish a formally checked compatibility relation for required declarations before verified-profile release. Keep all checker/provider choices and assumptions in an audit manifest.

## 7. Dynamic features authored in Lean — soundness firewall

npm extension may contain .lean source, but installing it must not load its compiled code into the compiler authority process. Build and publish platform-specific native workers in the extension's own trusted build pipeline, then run such workers only behind restricted capability-limited host protocols. Alternatively use a supported isolated Wasm component when a version-pinned Lean-to-Wasm build exists.

- E0: source libraries / checked interfaces; no compiler execution authority
- E1: syntax sugar; only in named extensible profile, versioned canonical rewrite and checked source/Core relation; not unrestricted pscv-v1
- E2: Lean/native proof-producing tactics; proposed proof terms independently kernel checked, audited axiom closure
- E3: optimization: pass candidate must satisfy typed IR validation plus preservation/translation validation or explicit remaining TCB
- E4: backend: target artifact candidate, independent target validators and ABI preservation disposition
- E5: arbitrary semantic elaborator not an untrusted third-party feature in closed verified profile
- E6: foundational/kernel theory change is an audited versioned release, not ordinary npm plugin

The manifest is not a sandbox. Actual isolation must restrict process, filesystem/network, CPU/memory and supplied APIs; an extension returning a JSON field named accepted or certified has no authority. Keep checked-session and source identity bound to immutable bytes and designated checker.

## 8. .proof.lean reuse route

Write program semantics in .ps; elaborate to actual checked Lean-compatible Core. Generate an exact canonical Lean module and obligation set bound to source/spec/environment identities. Optional full Lean frontend (including Mathlib and Lean tactics) elaborates .proof.lean in a separately pinned, sandboxed toolchain. Export elaborated term with LeanExport, replay through LeanChecker/independent selected kernel, compare the theorem against the exact approved challenge and reject undeclared axioms/sorry. Lake.Compare can intentionally fill definition holes, so **program implementation definitions must be frozen** and only designated proof obligations fillable.

A Lean proof of some similar-looking program is not enough. Need checked meaning-preserving PSCV Core→Lean translation and separately validated runtime erasure/effects to discharge a PSCV obligation and produce certified executable artifacts. Full Lean proof syntax compatibility does not imply arbitrary Lean code translates to the four PSCV backends. Keep .proof.ps supported independently of full Lean frontend.

## 9. Criteria and stage gates

| Criterion | Design requirement | Evidence needed |
|---|---|---|
| Soundness/fidelity | Native source→Core→kernel→cert→IR layers with proof/erasure invariants | Differential source/meaning and independent semantics checks |
| TCB transparency | Small trusted checker, exact host source closure, pinned Lean/runtime/extension identities | Byte/source inventory and native linkage |
| Adversarial robustness | Bounded untrusted inputs and no unchecked fallback | Malformed/false proof and backend mutation tests |
| Small compiler/extensibility | Minimal native executable with optional separate extension workers | Actual size/RSS/startup and feature addition experiments |
| Architecture | Clear typed stable stage contracts and one source of logical authority | Dependency graph and integration test cases |
| Performance | Compile with native Lean, retain portable IR specialization | Benchmarks for representative small/large programs |
| Longevity | Semantic/profile/protocol version locks and minimal public APIs | Multi-version compatibility and migration rehearsal |
| Interoperability | npm/Lean proofs/Mathlib/WIT/TS/JS/Wasm/Rust | Semantic and ABI round-trip fixtures |
| Future self-host | No initial source restrictions; optional later bootstrap | Independent self-application evidence when desired |
| Auditability | Exact source/subject/package/proof/binary identities | Offline independent checking and provenance |
| Security | No implicit package or in-process extension execution | Host sandbox and supply-chain negative tests |
| Soundness security | No false proof/certificate from extension or poisoned source mapping | Proof-subject mismatch, kernel rejection, changed Core rejection |

No unmeasured 97/99% implementation score.

## 10. Delivery sequence

N0: Lean-written npm source packages; Lake builds pscv_v6_dev and validates real good/bad Lean Core theorem. Existing 4.34 native/Wasm npm providers remain independently tested. This establishes native build feasibility and trusted boundary basics only.

N1: migrate just lexer/source positions and normative .ps grammar to new Pscv.Syntax. Design extensibility without importing unchecked syntax into closed profiles.

N2: Pscv.Elab elaborates the supported .ps fragment to official Lean Core. Native checker issues session-scoped checked handle from exact immutable source/decl/environment identities. Prevent false source→Core and incomplete checking claims.

N3: extract old compiler-ir validators and erasure algorithms as new Lean packages, with adapted canonical typed Core translation and explicit preservation evidence. First target backend can emit plain JS or TS without self-host; verified emission stays gated.

N4: extract/refactor all four backend packages, retaining real JS/Wasm typed validation and target ABI contracts.

N5: implement mixed proof roots .proof.ps and .proof.lean, approved specifications, axiom restrictions, exact bridge and PSCV certification.

N6: npm source/library/extension distribution, isolated Lean-native extension executables, per-platform native releases, independent provider checks and proof/certificate replay.

N7: benchmark footprint/performance and pursue formal soundness/assurance. Self-host remains optional, not a blocking release gate.

**Current stage honesty:** the first Lean-native P0 scaffold has candidate Core, extension policy and genuine native kernel checking. It does not yet parse .ps, compile PSCV programs, distribute production native binaries, establish semantic preservation or certify proofs. Do not market it as a finished PSCV compiler.
