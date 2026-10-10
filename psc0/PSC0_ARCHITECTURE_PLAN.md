# PSC0 Architecture Plan

**Status:** accepted architectural direction; the first protected-host and npm-preview implementation milestone is recorded in [PLATFORM_IMPLEMENTATION.md](PLATFORM_IMPLEMENTATION.md). The full package, extension, module, and formal-assurance migration remains incremental.

**Decision update:** 10 October 2026, Asia/Jakarta.

**Repository evidence cut:** 9 October 2026, approximately 17:57 UTC. Source and CI claims below are pinned to that audit; they are not assertions about unseen later branch state. Re-fetch live heads and lane handoffs before implementation.

**Proof-organization follow-up:** the proof layout, imports, and runner were inspected at `pscv/prove-pskernel-core-v1` commit `85ccb4e1103d77ed77c09c5795fc48ae4ea8ea62`. This supplements the dated audit with organizational evidence; it does not requalify the newer branch's theorem set or CI.

**Distribution/user-experience follow-up:** 10 October 2026, Asia/Jakarta. The npm product name comes from the user; scoped names and CLI examples are proposed. Package-manager observations use the cited npm v12 documentation, not a newly executed installation.

**Incremental-tooling follow-up:** 10 October 2026, Asia/Jakarta. The TS emitter, runtime identities, erased type representations, preparation state, and IR module shape were inspected at `3fbf7f778ab20aaeaafe87ae07b04c00ab2d29f7`. At that evidence cut, the default-package, neighboring-TS, watch, and editor workflows below were proposals. The later T1 follow-up records the separately qualified bounded implementation; full watch and editor integration remain future work.

**Implementation follow-up:** 10 October 2026, Asia/Jakarta. [Draft PR90](https://github.com/dwijayuda/pskernel/pull/90) implements the initial protected compilation/publication route and an installable Linux/Windows x64 preview. The preview1 correction at `3fd25db1bbd8d508252682fd0efe5a948a5ea5fd` passed [all six qualification jobs](https://github.com/dwijayuda/pskernel/actions/runs/37993872945), including fresh Windows installation with Node26.7.0/npm12.0.2. One tarball contains the unchanged F compiler and separately authenticated native providers. Consumer Node22/26 support leaves the Node22/Lean4.34/TS7 bootstrap recipe and selected seed unchanged. The research observations below retain their original evidence cuts; [PLATFORM_IMPLEMENTATION.md](PLATFORM_IMPLEMENTATION.md) records the exact new package, platform/test limits and remaining proposals. No plugin execution or full compiler proof is inferred from this portability correction.

**Onboarding and command-extension follow-up:** 10 October 2026, Asia/Jakarta. The next bounded milestone adds `psc init`, project entry/output defaults, shipped source/TypeScript/refusal examples, and a separately installed `psdev` command demo. Its initial operation is `psc dev --once`; full watch still follows T1 module/export and ABI work. The command guest uses a deliberately restricted V8 WebAssembly profile and the same checked host/publication path. Source e5c4a561 passed [all six jobs in run 37998655835](https://github.com/dwijayuda/pskernel/actions/runs/37998655835), including both independent command-package identities and the user's Windows/Node26 environment. Exact qualification is recorded in [PLATFORM_IMPLEMENTATION.md](PLATFORM_IMPLEMENTATION.md); the dated research and full roadmap below are not retroactively claimed complete.

**T1 checked-library follow-up:** 10 October 2026, Asia/Jakarta. The implementation on `psc0/platform-t1-v1` adds explicit source-owned project exports, one checked bundle, neighboring TypeScript facades and the bounded `psc-ts-library/1` ABI. It reuses the protected admission/session/publication route and existing TS backend. The portable compiler closure now has 62 modules. [SH1 run 38013991001, attempt2](https://github.com/dwijayuda/pskernel/actions/runs/38013991001) passed at compiler source `5fe0045dcb0bf30e1d2519f900458d1407822eed`: C2/C3 artifact equality, all 11 exact-C3 T1 conformance observations and separate acceptance of four exact compiler/capability/generic admission streams by the unchanged native provider. [Platform run 38019471955](https://github.com/dwijayuda/pskernel/actions/runs/38019471955) passed all six jobs at release source `b01281b46aa62cbb09ed47a24ebad08b72c6265f`, including real T1 library admission and four fresh Linux/Windows installations with Node22.23.3 and Node26.7.0. Preview3 packages the exact qualified compiler while preserving the selected authoring seed and native Core. [PLATFORM_IMPLEMENTATION.md](PLATFORM_IMPLEMENTATION.md) and its [machine-readable record](docs/platform/t1-checked-library-preview-qualification-2026-10-10.json) retain actual counts, skipped fixture scope, hashes, user examples and limitations. The work is in [draft PR91](https://github.com/dwijayuda/pskernel/pull/91); it is not merged to main or published to npm. Full watch remains T2, general plugin/package migration stays incremental, and mathematical/compiler-refinement proofs remain later outside-bootstrap gates. This follow-up preserves the dated research baseline below.

**Wasm Core follow-up:** 10 October 2026, Asia/Jakarta. The requested direction is a qualified `pskernel-core-wasm` default with an explicit optional `pskernel-core-native` runtime, sharing one semantic Core. [The dedicated Wasm provider plan](docs/platform/wasm-core-provider-plan.md) records the inspected source seam, reusable build work, isolation limits, packaging, proof obligations and W0–W3 promotion gates. This is a researched recommendation; preview2 still uses its qualified native artifacts. The existing Lean-C++ Wasm checker and the tiny command guests are different implementations/profiles.

**JavaScript Core follow-up:** 10 October 2026, Asia/Jakarta. The user prefers investigating same-source Core → TS7 → JS before implementing Wasm. [KERNEL_JS_PLAN.md](KERNEL_JS_PLAN.md) records the bounded probe, its specific standard-environment blocker and the gates before selecting a JS provider. Current native admission remains selected. This updates the execution order in the earlier Wasm follow-up, without changing the protected-kernel or proof boundaries.

**T2 checked-watch follow-up (implemented):** 10 October 2026. The supervisor-owned development watch on **psc0/platform-t2-watch-v1** / [draft PR92](https://github.com/dwijayuda/pskernel/pull/92) now supports explicit **dev --watch** and optional downstream **--tsc** through the existing checked/isolated command pipeline. Source/ref **130e9501ccb39b11fe20bfe762718c9df896ebdd** passed [all six qualification jobs, run 38026670864](https://github.com/dwijayuda/pskernel/actions/runs/38026670864), including fresh Linux and Windows installed candidate preview4 with Node22/26, imported module changes, failure preservation, recovery and tampered-extension refusal. Linux uses event-driven watching, Windows uses bounded content polling due an observed native libuv watcher assertion in the pinned runtimes. This supplies host-coordinated TypeScript project checking, not atomic visibility to arbitrary external watchers, formal semantic preservation, general plugin APIs or LSP. The unchanged 62-module T1 compiler fixed point and native Core remain selected. Details, hashes and acceptance limits are in [PLATFORM_IMPLEMENTATION.md](PLATFORM_IMPLEMENTATION.md) and [the T2 qualification record](docs/platform/t2-watch-qualification-2026-10-10.json). Full mathematical/compositional assurance remains the later proof gate.

**T3 editor-query and diagnostic LSP follow-up:** 10 October 2026. The separately qualified `psc-source-query/1` interface checks unsaved `.ps` document text in memory through the release-pinned compiler and PSKernel Core without emitting executable artifacts or receipts. Optional private `pslsp` speaks LSP 3.17 stdio with full-document synchronization and versioned diagnostics; correct semantic hover/definition, completion, and VS Code client remain future work. Source `fe62c189aac09cdfe1c156864a329b4db5a0a9e5` passed [all six Windows/Linux Node22/26 jobs in run 38031535192](https://github.com/dwijayuda/pskernel/actions/runs/38031535192), including real unsaved-buffer admission, rejection and recovery, with no TS publication. T3 also replaces recursive Linux fs.watch with the bounded content-polling scheduler shared with Windows after reproducing the publisher temporary-lock directory race. The qualified T1 compiler closure and native Core remain unchanged. The work is in [draft PR94](https://github.com/dwijayuda/pskernel/pull/94), stacked on T2. See [implementation evidence](PLATFORM_IMPLEMENTATION.md), [the query/LSP contract](docs/platform/editor-query-and-lsp.md), and [T3 machine-readable qualification](docs/platform/t3-editor-query-qualification-2026-10-10.json). This is operationally qualified tooling, not a new logical kernel, PSCV verification, or compiler correctness theorem.

**PSCV modular-ownership P0 decision (10 October 2026):** retain the existing source directories (`core/`, `syntax/`, `elab/`, `compiler-ir/`, `erasure/`, `backend-ts/`, etc.) and the qualified compiler self-host closure. Names `pscore`, `psfrontend`, `psbackend-ts` and `psc` describe logical boundaries, not mandatory rename operations. Add a reusable, explicitly non-authoritative `packages/verification/` proof-proposal preflight and a private, data-only `packages/pscv/` profile candidate. Keep general tactics/prover, verified effects and approved-spec tooling in their reusable modules only when implementation needs arise; `@proofscript/pscv` eventually assembles the *closed PSCV versioned profile*, not a second monolithic kernel/compiler. The release-owned supervisor exclusively retains `PSCV-CERT-v1` validation and `VerifiedExecutableModule` authorization. **P0 has no certified emission path** and the current checked product still refuses PSCV builds. The full ownership matrix, versioned boundary proposals, trusted gate, rc3/rc4 pin divergence, precise omissions and staged acceptance criteria live in [PSCV_PROFILE_AND_PACKAGE_BOUNDARIES.md](docs/platform/PSCV_PROFILE_AND_PACKAGE_BOUNDARIES.md). The source data contracts are experimental, not PSCV language/profile implementation completion; all CI evidence must be recorded before qualification claims.

**PSCV modular-ownership P0 qualification (10 October 2026):** new code and unchanged compiler/kernel baselines at commit `c6e65c7b2333cb1ff634bdcf2f867a1c62510832` passed [all four GitHub Actions jobs, run 38036616386](https://github.com/dwijayuda/pskernel/actions/runs/38036616386). Linux22, Linux26 and Windows26 each passed 10 bounded, fail-closed proof-proposal/host-gate tests and inspected a private data-only PSCV package. An independent Lean4.35rc3 PSCVL prototype check accepted one actual contract as UNCERTIFIED, rejected an invalid postcondition with unproved verification conditions and sorryAx, and accepted a bounded strict grammar example as UNCERTIFIED. No PSCV certificate, authoritative proof closure, verified executable or npm publication was generated. [Precise P0 evidence](docs/platform/pscv-p0-qualification-2026-10-10.json). **P1/P2 remain necessary** for exact verification manifests, required-obligation completeness and kernel-replayed approved evidence before certified output.

**PSCV P1-A pinned RC3 source provenance and non-activating profile inspection (10 October 2026):** the exact Appendix K.1/K.2 Lean 4.35.0-rc3 source blueprint was audited against all 40 immutable upstream Git blob identities, not treated as a frozen Standard registry. [Run 38049559622](https://github.com/dwijayuda/pskernel/actions/runs/38049559622) passed five jobs at implementation commit `829a1945a78965ed87ae3835a48642b6dcff013b`, including 48 Node unit tests on Linux/Windows, a real upstream source checkout and pinned Lean contract preflight. Private profile inspection rejects changed environment pins, false registry digests and fabricated activation while the supervisor gate still issues no PSCV certificate/executable. The existing compiler/bootstrap and native PSKernel remain untouched. P1-B must generate/freeze actual ordered registries and WP/environment metadata in a subsequent normative revision; P2 needs independent mandatory VC coverage, kernel-checked approved specs and a protected verified-executable handoff. See [P1 source and profile design](docs/platform/PSCV_P1_SEMANTIC_PIN_AND_PROVENANCE.md) and [machine-readable qualification](docs/platform/pscv-p1a-qualification-2026-10-10.json). The separate PSKernel RC4 refinement is not silently selected for the normative PSCV RC3 semantics.

**PSCV P1-B registry-observation follow-up (10 October 2026):** in [draft PR97](https://github.com/dwijayuda/pskernel/pull/97), qualifying source `1cb7d874c37bd30d69f2482981a31e940ed581ed` passed [all six GitHub Actions jobs](https://github.com/dwijayuda/pskernel/actions/runs/38050837575). An actual Lean 4.35.0-rc3 environment probe observed 9,742 imported instances, 20,786 simp origins, 390 built-in simprocs and other entries; these remain **ambient Lean**, not allowed PSCV Standard. An independent SHA-pinned normative §24.3 extraction generated 230 type/operator/literal requirements and 194 distinct snapshot IDs, all explicitly unresolved against an approved ordered registry. The tool outputs only non-authoritative data, preserving the existing checked compiler and native PSKernel. Missing full instance/coercion/simp/simproc/ext/grind ordering, source-line locators, class modes, verified-effect WP registry, released manifest digest and conformance remain release blockers; P2 real PSCV-CERT-v1 emission has not begun. [P1-B technical inventory](docs/platform/PSCV_P1B_REGISTRY_INVENTORY.md) and [exact CI evidence](docs/platform/pscv-p1b-qualification-2026-10-10.json).

**PSCV P1-C direct Boolean source-mapping qualification (10 October 2026):** [PR98](https://github.com/dwijayuda/pskernel/pull/98) qualified Lean4.35rc3 source/declaration evidence for 3 of the 194 required Standard snapshot IDs, using pinned `src/Init/Prelude.lean` Git blob/lines, actual `PSCVL.Policy` imported declarations, separate `Bool.Internal.*` definitions and equality (`@[csimp]`) theorem names. The public Boolean declarations are marked **noncomputable**; source equality alone is not backend/runtime preservation or independent PSKernel replay. The other **191 IDs remain unresolved**. [Run 38052355776](https://github.com/dwijayuda/pskernel/actions/runs/38052355776) passed six jobs (78 Node tests across Linux22/26 and Windows26, real Lean imported-env and positive/negative contracts, immutable source audit) at source commit `3153fe5732794f2e96cde994085b9a2ec28acfa9`. Full closed Standard registry ordering, class modes, effects, complete source locator mapping, approved digest and PSCV-CERT-v1 are still unavailable, so profile activation and certified emission remain blocked. [P1-C implementation and source lines](docs/platform/PSCV_P1C_DIRECT_BOOL_MAPPING.md) · [qualification record](docs/platform/pscv-p1c-qualification-2026-10-10.json). The existing self-host compiler, selected native PSKernel Core and public checked build remain unchanged.

**PSCV P1-D imported typeclass candidate index (10 October 2026):** [draft PR99](https://github.com/dwijayuda/pskernel/pull/99) adds actual Lean4.35.0-rc3 typeclass result-head/synth-order/import metadata from the pinned `PSCVL.Policy` environment and a bounded review-only index. [GitHub Actions run 38053043569](https://github.com/dwijayuda/pskernel/actions/runs/38053043569) passed all six jobs at source commit `80570393844e08876c3356c553845b6f89846b88`: 9,742 imported instances grouped under **411** distinct syntactic result-class heads, zero missing heads, 87 Node unit passes on Linux22/26 and Windows26, actual Lean proof/source checks. This index is **NOT** selected Standard instance registration/search order, source-to-operator mapping or verified executable authority; 191 normative snapshot IDs remain unresolved. [P1-D implementation and next exact mapping requirements](docs/platform/PSCV_P1D_IMPORTED_CLASS_INDEX.md) and [machine evidence](docs/platform/pscv-p1d-qualification-2026-10-10.json). The ordinary self-host compiler, TS7 target, native PSKernel and protected build remain unchanged while rc4 Core work proceeds separately.

**Canonical plan format:** this Markdown file. It supersedes the earlier PDF draft for future plan revisions.

## Decisions confirmed by the user

- Use ps-prefixed internal module/package basenames: `pscore`, `psfrontend`, `psc`, `psbackend-ts`, with `pskernel-core` retained for the kernel.
- Use the user-owned npm package name `proofscript` for the installable compiler product and expose the executable as `psc`. Additional official scoped package names remain conditional on control of the chosen npm scope.
- Keep `psbackend-ts` in the required compiler distribution and self-host source closure. Use the pinned TypeScript 7 toolchain to produce executable JavaScript.
- Keep compiler implementation in the supported `.lean`/`.ps` source profile. Keep `pscore` backend-neutral and the logical kernel independent of backend code.
- Make `psbackend-js`, `psbackend-wasm`, `psbackend-rust`, and other backends optional extensions. Replacing the required TS backend is not a goal of this plan.
- One `proofscript` installation should provide all five required compiler components. Develop watch and language-server functionality incrementally as separate ps-prefixed tooling packages that can become release defaults without entering the compiler's self-host source closure.
- Support gradual adoption in existing TypeScript projects: users write `.ps` beside handwritten `.ts`, and the compiler publishes owned neighboring `.ts` outputs only after the checks required by the selected profile succeed. VS Code integration can follow separately.
- Allow mature extension functionality to be adopted through explicit bundling, implementation-integration, or semantic-change decisions. Adoption never automatically waives kernel checks, required preservation evidence, isolation, or disclosure.
- Preserve the selected seed and demonstrated compiler fixed point. A joint generated compiler/kernel closure remains a separate acceptance milestone.
- Investigate same-source `pskernel-core-js` through the required TS backend before implementing the Wasm provider. Keep current native admission until generation, canonical admission parity, workload budgets and installed artifact gates qualify an alternative.
- Put compiler assurance companions in a separate `psc0/proofs/` tree, using `.proof.lean` filenames and ordinary `.lean` modules for reusable models and lemmas. Reuse the existing kernel proof approach without duplicating its proof library.
- Allow full Lean and its tactics/libraries for proof development now, and full PSCV proof authoring when that capability is implemented. Assurance proofs and their development dependencies stay outside the ordinary runtime and self-host closure.
- Complete architectural implementation, npm packaging, and the declared self-host milestone without waiting for the full compiler/architecture proof program. Formal assurance is a later, separately scoped gate for stronger claims. Required runtime kernel admission, validation, isolation, disclosure, and selected-profile PSCV checks remain mandatory.

This document records research and planning. It does not implement package renames, change kernel semantics, promote a seed, or qualify a new compiler. Existing workstream ownership and execution handoffs continue to apply.

## Contents

- [1. Recommendation and scope](#1-recommendation-and-scope)
- [2. Exact repository and evidence baseline](#2-exact-repository-and-evidence-baseline)
- [3. Size and observed performance](#3-size-and-observed-performance)
- [4. Critical architectural findings](#4-critical-architectural-findings)
- [5. Semantic and extensibility faults](#5-semantic-and-extensibility-faults)
- [6. What the formal work establishes](#6-what-the-formal-work-establishes)
- [7. Logical consistency is a different proof](#7-logical-consistency-is-a-different-proof)
- [8. Lessons from reference systems](#8-lessons-from-reference-systems)
- [9. Honest architecture comparison](#9-honest-architecture-comparison)
- [10. Proposed modules and npm packages](#10-proposed-modules-and-npm-packages)
- [11. Trust belongs to claims, not package names](#11-trust-belongs-to-claims-not-package-names)
- [12. A narrow extension API](#12-a-narrow-extension-api)
- [13. Isolation and non-overridable disclosure](#13-isolation-and-non-overridable-disclosure)
- [14. One admission-to-artifact transaction](#14-one-admission-to-artifact-transaction)
- [15. Compositional compiler correctness](#15-compositional-compiler-correctness)
- [16. Validators, PSCV, and proof maintenance](#16-validators-pscv-and-proof-maintenance)
- [17. Self-hosting and bootstrap strategy](#17-self-hosting-and-bootstrap-strategy)
- [18. Migration plan and estimated changes](#18-migration-plan-and-estimated-changes)
- [19. Acceptance criteria](#19-acceptance-criteria)
- [20. Risks and decisions to keep explicit](#20-risks-and-decisions-to-keep-explicit)
- [Appendix A. Reproducibility identities](#appendix-a-reproducibility-identities)
- [Source register](#source-register)

## 1. Recommendation and scope

**Accepted design update - 10 October 2026, Asia/Jakarta:** use ps-prefixed package basenames such as pscore, psfrontend, psc, and psbackend-ts. Keep TypeScript as the required reference backend for the core distribution and self-hosting, using the pinned TS7 toolchain. Direct JS and other backends are optional extensions; replacing TS7 is no longer a goal of this plan. Mature extension functionality may be adopted later through the promotion policy in section 12. The repository evidence retains its original 09 October review cut.

**Adopt a fixed semantic backbone with isolated extension producers and one explicitly trusted admission supervisor.** Keep the existing small composition root and most compiler algorithms. Consolidate the maintained kernel, close publication bypasses, specify runtime meaning, and expose narrow data interfaces. This is a structural refactor, followed by targeted proof work, rather than a new compiler framework.

The desired platform has three different kinds of smallness. The logical kernel should be small enough to specify and audit. The compiler’s self-host closure should include only one reference compilation path. The installed product should exclude unselected optional backends and full-Lean development dependencies, and load tool/extension execution machinery lazily. A small, deliberately chosen set of development tools may ship as release defaults without joining the compiler source closure. Installed size, startup cost, host TCB, and self-host closure must be measured separately.

Most extensions need no universal proof of their implementation. A tactic can propose a term that the kernel checks. A restricted optimizer can propose a transformation certificate that a smaller validator checks. This does not make an arbitrary well-typed optimization or backend correct: preserving types and preserving program behavior are different properties.

The immediate architecture should protect admission and accurately report the evidence available today. Its long-term semantic guarantee must be earned through source-to-Core correspondence, sound admission, erasure and pass refinement, a backend/runtime theorem, and explicit artifact binding. The current repository does not yet demonstrate that complete chain.

### What is deliberately preserved

- The qualified R seed and F compiler qualification, including exact identities and cold recovery.
- TS7 as the current bootstrap toolchain; no TS5/TS6 fallback is proposed.
- Existing parser, elaborator, environment, bridge, erasure, and backend algorithms where their behavior is useful.
- PSKernel Core and its companion/metatheory proofs, reconciled into one authoritative implementation.
- The recent IR checker, owned preparation sessions, strict source/target checks, finite conformance tests, and honest open-obligation ledger.

### What must change

- One public production transaction must own checking and publication; “prepare” cannot masquerade as “check.”
- A kernel selector must identify the actual source, artifact, runtime, logical profile, and assumptions it invokes.
- Primitive semantics must be attached to admitted identities and explicit contracts, rather than source spelling.
- Extensions must run through a real isolation boundary; package manifests and JavaScript object discipline are insufficient.
- Correctness claims must be separate fields backed by completed gates, rather than one “verified” label.

### Review method and limitations

The review used read-only GitHub access to inspect the live branches, source closures, relevant package trees, selected complete source files, formal theorem statements, receipts, and workflow logs. The compiler audit traversed the actual imported closure; the proof audit scanned all 197 assurance Lean files. No source was checked out, compiled, executed, patched, or submitted to CI during this review. Numerical results below are repository observations, not newly reproduced experiments.

External comparisons use Lean, CakeML, CompCert, Candle, MLIR, Wasmtime, Node/npm, MetaRocq, and formal VCG research. Their results inform the design; they do not transfer a correctness theorem to PSC0.


## 2. Exact repository and evidence baseline

### Inspected revisions

| Workstream | Revision | Interpretation |
| --- | --- | --- |
| main / active PSC0 | ed5d00aca074 | TS7 migration and F compiler work merged; current baseline |
| psc0/strict-sh1-v1 | d6b7044258ef | Four commits ahead; latest candidate is not qualified |
| psc2/selfhost-lean-kernel | cae6b6d5fb3d | Integration architecture, optional backends, kernel copy |
| pscv/prove-pskernel-core-v1 | 64499d5db307 | Latest proof frontier; workflow #840 failed |
| Last fully green proof checkpoint | 11005632c149 | Workflow #836 passed; same production kernel tree as proof HEAD |
| Native provider used by F | 963030dc2d15 | Distinct pinned kernel source; neither local PSC0 copy nor latest proof source |
| F executable source | fcd875c8f38d | Successfully qualified compiler source |
| Selected R seed source | fe2560aba0f3 | Retained recovery/selection baseline |

Main, strict, and proof branch heads were re-fetched at the end of source inspection and remained at these revisions. Full hashes are included later in the evidence appendix. Historical work-state statements must be read against their dates: older “main untouched” instructions do not override the observed later merge. [R01] [R19]

### Demonstrated results and their limits

| Evidence | Demonstrated | Not demonstrated by that evidence |
| --- | --- | --- |
| F run 37947341800 | R → C1 → C2 → C3; C2/C3 equality for canonical PS, admissions, TS, JS; complete original IR checked in that harness | General semantic preservation; strict SH/1; a universally checked default build path |
| F provider job | Four distinct exact admission streams accepted, covering eight C2/C3 roles | Emission gating: checking happened after emission |
| Cold R recovery 37947341899 | Four products reproduced from declared native Lean + TS7 path without generated-parent/cache recovery | Provider verification by that recovery or a seed-correctness theorem |
| Strict run 37967710379 | Native source, IR, and target policies accepted; bounded positive/refusal suites progressed | TS fixture conformance completion; C1/C2/C3 fixed point; provider qualification |
| Proof #836 / #840 | Substantial concrete refinement theorems; green prior checkpoint with identical production tree | Complete admission closure, declarative foundation soundness, relative consistency |

The checked-in F receipts explicitly distinguish runtime IR checking, provider checking, and qualification. The compiler receipt does not claim strict runtime IR qualification, and the provider receipt says emission was not gated by that check. These are valuable accurate boundaries, not reasons to erase the successful fixed-point result. [R02] [R03] [R04] [C01] [C02]

The latest strict failure is TS2367 on literal equality comparisons in generated runtime conformance fixtures. It occurs after native policy checks and pinned Lean observations, before C1/C2/C3. Earlier parser and expected-type failures have been superseded. [R19] [C03]


## 3. Size and observed performance

The imported Ps.Bootstrap.SelfHost compiler closure has **61 handwritten Lean files, 1,112,320 bytes, and 28,821 physical source lines** across 12 package groups. This excludes the kernel, proofs, generated outputs, optional backends, and documentation. The successful F log independently records the file count and byte total. [C01]

| Current package group | Files | Source lines |
| --- | --- | --- |
| syntax | 12 | 8,393 |
| elab | 5 | 5,615 |
| erasure | 6 | 3,726 |
| environment | 7 | 2,069 |
| compiler-ir | 5 | 2,069 |
| bridge | 2 | 2,023 |
| meta | 6 | 1,967 |
| backend-ts | 5 | 1,590 |
| core | 8 | 899 |
| compiler | 1 | 280 |
| foundation | 3 | 185 |
| bootstrap | 1 | 5 |

The five-line bootstrap composition and 280-line compiler facade are already small. Most handwritten volume sits in parsing/elaboration and erasure. Large files include Term (3,043 lines), ParseLean (2,807), ParsePS (1,830), ErasureExpr (1,821), and Declaration (1,483). This supports selective modularization around stable semantic operations, not replacing everything with a framework.

The current scripts directory contains 199 executable-source files, approximately 1.0 MB, including tests. Of these, 84 source-syntax guards occupy approximately 253 KB. The npm workspace exposes 117 scripts. These counts describe development machinery; they are not installed production code. Current workspace/compiler manifests are private development packages. [R21] [R34]

### Where a measured generation spends time

| F generation C2 stage | Seconds | Approximate share |
| --- | --- | --- |
| Load and prepare | 431.713 | 57.0% |
| Admissions encoding | 68.786 | 9.1% |
| Canonical source | 30.986 | 4.1% |
| Erasure / ABI observation / IR check / emit scope | 224.087 | 29.6% |
| TypeScript compilation and writes | 2.249 | 0.3% |
| Total | 757.822 | 100% after rounding |

These are single-run stage scopes, not independent microbenchmarks. C1 took 764.736 seconds and C3 787.604 seconds. Removing tsc alone cannot materially improve this workload: it accounts for about three tenths of one percent of C2. This supports keeping TS7 as the required baseline. A direct-JS backend may offer optional deployment benefits, but it is not needed to make the compiler self-hostable. [C01]

First retain one immutable prepared environment and admissions encoding across checking and emission, reduce repeated traversals and environment reconstruction, and profile the remaining stages. Preserve the existing bounded parsed-source cache and prefix checkpoints until measurements justify finer-grained incremental dependency analysis. Its entry/source-byte bounds do not establish a total-heap bound. [R05] [R20]


## 4. Critical architectural findings

### 4.1 The strongest checking path is not the default authority

On main, psCompilerCheckElaborated and psCompilerCheckSource are aliases of preparation. Preparation produces canonical admission-ready declarations; it does not perform kernel admission. The backend adapter obtains a runtime IR and calls the raw TypeScript emitter. The ordinary CLI build driver uses this prepare/emission route. A stronger qualification harness exists, but callers do not uniformly pass through it. [R05] [R06] [R08] [R09]

This is a structural defect: correctness depends on which entry point happens to be called. Adding one more “checked” wrapper would perpetuate that defect. Move final artifact authority into one transaction, make weaker operations honestly named internal construction APIs, and require every public production path to use the transaction.

### 4.2 Constructible records do not carry trusted evidence

The existing VerifiedIr name refers to ordinary constructible IR data. New erased/validated wrappers in integration improve staging, but a public record containing raw IR is not a capability. A runtime type check is useful, yet does not establish source correspondence or behavior preservation. Two functions Nat → Nat can both type-check while one returns its argument and the other always returns zero. [R13]

Rename construction data RuntimeIR or CandidateIR. Reserve admitted/validated status for supervisor-owned state produced by an actual check. Serialization must never import authority from a checked:true field. Keep the real recent IR validator and prove its particular soundness property; do not discard it because the surrounding name is overstrong.

### 4.3 Ownership checks are valuable but are not a hostile-plugin sandbox

The checked session freezes plain graphs, rejects unsupported object shapes, associates handles through a WeakMap, and compares exact admission encodings before use. These mechanisms help prevent accidental mutation and mismatch. Its own comments correctly state that hostile compiler/host JavaScript is outside that protection. Loading arbitrary npm code into the same Node process would undermine the boundary. [R07]

Retain these ownership techniques inside the supervisor. Place external code outside its address space and host capabilities. The distinction matters: immutable data structures can be part of a secure design without being its execution isolation mechanism.

### 4.4 Kernel identities and maintained copies have drifted

Main, strict, and integration share one 79-file kernel src/Ps tree. Seventeen files differ from current proof source. The native provider used by F is another revision: thirteen files differ from the local PSC0 copy, and seven from the latest proof source. Newer work includes scope-local cache restoration, symmetric eta dispatch, level normalization changes, and specified-string/name work. [R30] [R31] [R32]

The default checked provider and the pskernel-core selector are also distinct. The latter currently resolves to an older experimental generated checker whose BUILD metadata includes canCheckProofs:false. It is not the latest native metatheory-backed provider. Historical toolchain metadata in that legacy artifact must remain historical; it does not authorize a TS5 fallback. [R10] [R11]

Establish one maintained kernel source with explicitly identified built artifacts. Preserve historical copies as evidence outside active selection. Reconcile proof and implementation changes deliberately; their branches have diverged too far for a blind whole-branch overwrite.


## 5. Semantic and extensibility faults

### 5.1 Primitive spelling can substitute a different program meaning

Main erasure recognizes primitive operations and some types by fixed source names. The strict audit identifies 43 operation spellings: 38 were prelude-installed and protected by duplicate checks, while Bool.and, Bool.or, Bool.not, Array.getInternal, and Array.set were absent. An author could supply unrelated definitions under those spellings. String.Pos.Raw was separately absent as a type while erasure treated its name as Nat. [R14] [R15] [R16]

A source-path illustration is an authored Bool.and that always returns true, followed by its application to false and false. Name-driven erasure can select the ordinary Boolean conjunction operation, whose result is false. This is a statically reviewed correspondence counterexample, not a newly executed test and not a claim that the logical kernel accepted a false theorem.

Retain strict’s reservation of the affected names as an immediate guard. The durable solution is an explicit finite primitive contract: primitive ID, admitted declaration identity, type/body or definitional contract, representation, evaluation demand, failure behavior, and backend implementation. Generate repetitive inventories and signatures from that contract where practical. Third-party packages must not register new trusted reductions merely by choosing a name.

Type signatures alone do not settle the semantics. Boolean short-circuiting, argument evaluation, proof erasure, repeated evaluation of match majors, array bounds, Unicode scalars versus UTF-16, and byte-position adapters need explicit treatment. Current strict work is moving in this direction; its 33-rule ledger remains entirely open for general preservation. [R18]

### 5.2 Package directories are not an extension architecture

The inspected bootstrap closure has a closed syntax AST with 13 term and five declaration constructors, hardcoded source-kind selection, and no general macro/elaborator/tactic registry. CLI and provider selection are similarly fixed. This is reasonable for bootstrapping, but does not yet satisfy the requested npm extension platform. [R05] [R12] [R34]

Keep kernel Core and RuntimeIR closed and versioned. Add extensible syntax nodes and dispatch outside those semantics, with expansions and elaborations lowering to existing Core. New notation should not require a new trusted kernel constructor. A genuinely new logical rule, primitive effect, or runtime instruction is a reviewed core-version change, rather than an ordinary plugin hook.

Distinguish extending .ps/.lean syntax from writing the extension implementation in .ps/.lean. A Wasm guest authored in another language can implement syntax extension before PSC0 itself has a suitable Wasm compiler. Full Lean metaprogram compatibility needs an optional qualified Lean worker or adapter; it should not force the minimal bootstrap to contain a second full Lean implementation.

### 5.3 Some current guard and backend boundaries are too implementation-specific

Many source guards recognize exact function spellings, multiline fragments, and worker layouts. They preserved constrained-source discipline during bootstrapping, but impose refactor costs unrelated to the intended semantic invariant. Replace them gradually with one source-profile AST checker, import-boundary checks, typed API conformance, and behavior/property tests. Delete a guard only after replacing the requirement it protected. [R21]

The integration branch’s backend separation is useful. Its Wasm lowering file is nevertheless approximately 6,315 lines and performs common IR specialization internally before target lowering. Make that semantic transformation an explicit internal pass with its own invariant and relation, then reuse it across backends. This calls for a few explicit pass functions, not a general pass-manager framework. [R22]

### 5.4 The strict branch should be completed, not restarted

The candidate’s atomic source-to-emission route checks source policy, IR, target policy, and emits that same IR. It explicitly returns false for strict qualification, semantic-contract qualification, and provider checking. The latest run accepted 64 source modules, 60,937 IR expressions and 777,667 IR steps, then failed later in TS7 fixture compilation. Preserve that work and finish its qualification before promotion. Do not claim its bounded conformance or target checks discharge the general preservation ledger. [R17] [R18] [C03]


## 6. What the formal work establishes

### Substantial implementation refinement already exists

The proof branch contains 84 companion proof files and 113 metatheory modules: 197 assurance Lean files, approximately 80,870 lines and 3.16 MB. A source scan found no explicit sorry, admit, new axiom, or native_decide tokens in those files. This is an observation about the inspected source; it neither proves all imports are axiom-free nor establishes that the latest red revision fully elaborates.

The concrete checker composition theorem instantiates the actual recursive checker wiring. It combines checked inference, infer-only configuration preservation, weak-head normalization, and positive definitional-equality refinement. Abstract recursive callbacks have been discharged in that composition. Two named external semantic laws remain: native-reduction soundness and positive string-comparison soundness. The optimized beta-spine law is internally proved. [R23] [R27]

The ordinary inductive transaction theorem includes substantive constructor/header, uniform-occurrence, recursor, generated-universe, policy, lookup, and index properties. It discharges comparator reflexivity internally. It is still not the final theorem that every successful declaration admission preserves complete semantic environment well-formedness. [R24]

Mutual admission has proved meaningful intermediate invariants and recursor publication results. The final transaction still needs to extract and discharge successful construction, validation, and final-result equalities. Nested flattening/rebasing/restoration, full admission closure, public composition, and final assumption audit remain open. The most recent proof run fails in mutual-continuation elaboration; its production kernel source tree is identical to the last fully green checkpoint. [R25] [R31] [C04] [C05]

### Assumptions must be counted at the theorem statement

Selected green-run theorem reports name propext, Classical.choice, and Quot.sound. Such reports do not erase explicitly quantified native/string laws or environment invariants. A theorem can have no new axioms and still require a strong semantic premise. The current runner’s compilation exit-status check is not a whole-theorem assumption allowlist. [R23] [R27] [R33] [C05]

The string work has advanced beyond older audit paragraphs: reflexivity and generated-name properties are now proved under the remaining positive comparison law. The audit should track the current header and concrete theorems, rather than treating old prose as authoritative forever. [R32]

For the protected default, disable optional native evaluation and prove that the disabled mode cannot publish a native reduction. Any future accelerated native evaluator needs a separate refinement theorem or checkable reduction evidence. A plugin cannot introduce that law by returning a capability record.

### Compatibility evidence is bounded and native

Arena logs show 141/141 tutorial cases, 17 correct historical cases plus one declined case, and timeouts near 500 seconds for full Init and 590 seconds for full Std. Full Mathlib is explicitly not started. These jobs execute the Lean-native checker. They do not establish generated-JavaScript kernel correctness or completed full-corpus compatibility. [R35] [C07] [C08] [C09]


## 7. Logical consistency is a different proof

The existing independent judgments specify algorithmic typing, conversion, reductions, caches, and environment histories. That is the implementation-to-operational-specification half of a soundness argument. A mathematical model or sound interpretation of the logical foundation is a separate half.

For example, the algorithmic DefEq judgment is deliberately not a general declarative equivalence relation. The recursorKConversion rule records operational control and metadata conditions, with a later checked-soundness layer intended to justify the corresponding logical principle. A constant lookup also relies on the environment being authoritative and well formed. These are explicit points where admission closure and a logical bridge matter. [R26]

The proof architecture should therefore separate:

- **Implementation refinement:** successful checker/admission execution implies the appropriate operational judgment and preserves configuration invariants.
- **Declarative soundness:** those judgments, under admitted well-formed environments, imply typing/conversion in a reviewed logical specification.
- **Model or interpretation soundness:** that logical specification is valid in a stated mathematical model or sound translation to a modeled theory.
- **Relative consistency:** if the stated metatheoretic assumptions hold, an admitted empty-context proof of the chosen false proposition cannot exist under the approved foundation.

Do not strengthen a specification merely to mirror every implementation shortcut and then call the resulting refinement “consistency.” Conversely, do not discard the operational proofs because the declarative bridge is unfinished. They are reusable components of the eventual composition.

The logical target should be a precisely versioned profile of the rules PSC0 actually accepts: universes, conversion, proof irrelevance, inductive admission, recursors/elimination, quotient support, and allowed axioms. Do not inherit a consistency theorem simply by calling that profile Lean-compatible. Harrison’s HOL model work illustrates the need for explicit stronger metatheoretic assumptions; it does not supply a model for PSC0’s exact foundation. MetaRocq illustrates separable verified checker/erasure boundaries, but its theory is not automatically PSC0’s theory. [E13] [E14]

### Keep assumptions explicit and transitive

Axioms are supported declarations in the current API. Type-checking an axiom’s type does not show that the axiom is consistent. The supervisor must apply a foundation policy, record additional assumptions, and compute transitive assumption dependencies for the delivered theorem or program. A library cannot silently introduce an inconsistent axiom while retaining an assumption-free label. [R28]

Unsafe/extern/native behavior must likewise have an explicit executable contract. An opaque definition with a checked body is different from an unproved external implementation. A proof of a source function is not a proof that an arbitrary foreign runtime routine implements it.

The practical minimum is not to redesign the calculus during the platform refactor. Retain the selected kernel profile and current proofs, narrow acceptance where necessary, close admission/model obligations in a dedicated workstream, and version genuine logical changes explicitly. Replacing it immediately with a tiny new calculus would reduce some kernel mechanisms but lose Lean compatibility and much existing assurance.


## 8. Lessons from reference systems

| Reference | Lesson to adopt | Limit or cost for PSC0 |
| --- | --- | --- |
| Lean 4 | Rich elaboration can produce terms for a small kernel; statement interpretation and arbitrary elaborator execution remain separate concerns | Kernel acceptance alone does not prove source intent or sandbox plugins |
| CakeML | Stable semantics, explicit semantic passes, verified compilation and bootstrap; make resource behavior part of the theorem | A large end-to-end verification program cannot be obtained from fixed-point hashes |
| CompCert | Per-pass refinement plus composition; let expensive heuristics propose outputs for a dedicated validator | Validator proofs apply to their defined relation, not arbitrary optimizer equivalence |
| Candle | Couple trusted checking with a controlled result/output channel | Logical checking can be undermined at the user-facing boundary if output authority is not protected |
| MLIR | Explicit legality and conversion stages make contracts inspectable | Full legality is not semantic preservation; a general dialect framework is excessive here |
| Wasmtime | Memory isolation and explicit host imports provide a credible executable-extension boundary | The engine, host bindings, resource policy, and installation still belong to the security assumptions |

Lean’s official validation workflow distinguishes checking a proof term from validating what proposition the user meant. It recommends sandboxing elaboration, validating exported material, and rechecking against a separately trusted challenge. The default frontend remains a source-fidelity assumption until that interpretation is proved or independently checked. [E01]

CakeML used validation during bootstrap to avoid expensive in-logic execution of an already verified register allocator. CompCert validates an external allocation oracle. These illustrate distinct benefits of narrow validators: reducing proof-evaluation cost or avoiding reliance on an unverified search implementation. Neither is a universal equivalence checker. [E04] [E05] [E06]

Candle’s kernel-controlled output channel is especially relevant to non-overridable extension reporting. PSC0 should give the supervisor exclusive ownership of official status and receipts. Wasmtime’s guidance also requires treating terminal output from guests as untrusted data. [E07] [E08]

MLIR’s full conversion insists that output operations are legal for the target. That is an instructive structural validation boundary, but it does not prove that the result computes the same function. Preserve that distinction in PSC0’s IR and target-policy checks. [E12]

For PSCV, a recent verified Dafny-subset project proves a VCG and compiler against shared operational semantics before connecting to CakeML. Its scope is a subset, not all Dafny. The relevant architectural lesson is to share the executable semantics between verification conditions and compilation, rather than maintain two disconnected notions of program behavior. [E15]


## 9. Honest architecture comparison

Ratings below are design judgments for PSC0’s requirements, not benchmark measurements. “Good” correctness potential means the architecture can support the guarantee with stated proof work; it does not assert that proof already exists.

| Option | Soundness / executable correctness | Security / disclosure | Main cost |
| --- | --- | --- | --- |
| Same-process npm hooks | Kernel can check terms, but hooks can interfere with host authority | Fails hostile-plugin requirement | Lowest initial integration cost; hidden trust expansion |
| Lean as the whole platform | Mature elaboration and compatible source meaning; execution correctness still separate | Requires an additional sandbox and trusted exporter/recheck path | Large mandatory dependency and difficult minimal independent bootstrap |
| General multi-IR framework | Many pass interfaces; proof obligations spread across dialects | Isolation still has to be added | Framework, registration, compatibility, and proof-maintenance surface |
| Entire compiler and every plugin verified | Strong theoretical path | Proofs alone do not remove runtime/IO isolation needs | Very high extension cost and broad reproof burden |
| OS-sandboxed native workers | Reuse Lean/JS tools and kernel checking | Credible where a real OS sandbox is implemented | Platform-specific policy and packaging; subprocess alone is insufficient |
| Fixed Core/RuntimeIR + Wasm producers | Stable proof boundaries; checked terms and restricted certificates | Strong fit with explicit imports and supervisor disclosure | Narrow ABI and engine dependency; not immediate arbitrary-JS compatibility |

### Operational comparison

| Option | Simplicity / AI iteration | Performance / portability | Self-hosting / longevity |
| --- | --- | --- | --- |
| Same-process hooks | Easy first plugin, difficult reasoning about global effects | Low call overhead; npm-portable | Small at first, brittle trust and dependency growth |
| Whole Lean platform | Excellent existing ecosystem; substantial version-sensitive internals | Mature native tools; larger install | Useful optional adapter; poor fit for minimal independent closure |
| General multi-IR framework | More concepts and files per change | Useful at multi-target scale; extra infrastructure | Longevity if scale warrants it; premature cost for current scope |
| All plugins verified | Stable formal discipline, slow exploratory development | Runtime can be efficient | Proof ecosystem becomes a prerequisite to extension |
| Native isolated workers | Familiar language/tool choices | IPC plus platform sandbox costs | Good compatibility lane where qualified; portable parity is expensive |
| Recommended fixed semantics | Small SDK and local obligations; closed core stays inspectable | Batch IPC; Wasm engine cost; broad portability on supported engine targets | One bootstrap target; extensions evolve without kernel rewrites |

**Recommendation:** use the last option as the destination, with a minimal first release that preserves the pinned first-party compiler and admits only constrained external execution. Add native compatibility only for explicitly qualified platforms. There must be no automatic fallback from a failed sandbox to ordinary JS or Lean execution.

This design adds some host code and an optional execution runtime. It does not promise the smallest total installed byte count. It makes authority and correctness contracts smaller and more stable, which is the better optimization for the user’s combined goals.

There is a still smaller intermediate milestone: a protected compiler release with data-only extensions and no general third-party execution. It can unify admission and packaging first, but it does not yet fulfill the full plugin vision. Shipping unsafe JS hooks to claim earlier extensibility is not a defensible compromise.


## 10. Proposed modules and npm packages

Names below follow the user's selected ps-prefixed basename convention. The user reports owning the unscoped npm package `proofscript`; use it for the compiler product. Additional npm names and scope control remain publishing checks. Use one coordinated release train initially. A logical boundary does not automatically deserve an independent npm package.

| Module / proposed package | Owns | Dependency rule |
| --- | --- | --- |
| pskernel-core | Kernel terms and declarations, admission, conversion, authoritative environments, kernel proof sources | No frontend, plugin loader, CLI, backend, or PSCV dependency |
| pskernel-core-js | Proposed same-source Core → PSC → TS7 → JS execution artifact and canonical provider adapter | Release-authenticated trusted provider; possible interim default only after separate qualification; no arbitrary JS plugin authority |
| pskernel-core-wasm | Proposed Wasm execution artifact and minimal adapter for the same selected Core | Release-authenticated provider; qualified runtime option; no ordinary plugin authority |
| pskernel-core-native | Proposed optional native execution artifact for the same source/profile/capabilities | Explicit runtime selection; no semantic fallback or automatic native evaluator |
| pscore | Canonical data contracts and bridge, fixed RuntimeIR, invariants, erasure, explicit semantic pass contracts | Pure internal modules; no host IO or backend imports |
| psfrontend | Default bounded .ps/.lean parsing, names, macros, elaboration, meta state | Produces Core proposals through public data contracts |
| psc, distributed through proofscript | Trusted supervisor, CLI, policy, kernel service, resolver, extension runner, receipts, publication | Owns capabilities and decisions; does not import external package code |
| psbackend-ts | Required reference backend for the core distribution and self-hosting; TS7 runtime adapters | Consumes pipeline data; cannot publish; target-specific code stays outside pscore |
| pscv | Optional approved VCG/coverage implementation and obligation schema | Activation and final coverage decision stay in supervisor |
| psdev | Watch scheduling and development-command policy | Uses supervisor snapshots/build requests; cannot admit, publish, or start arbitrary processes |
| pslsp | ProofScript language-server computations | Reuses compiler analysis/query results; unsaved analysis cannot publish build artifacts |
| psvscode, proposed editor-client basename | Thin VS Code integration and server selection | Separate Marketplace/VSIX distribution; no compiler/kernel implementation |
| Optional psbackend-js, psbackend-wasm, psbackend-rust, Lean adapter | Target-specific or compatibility functionality | Outside the required compiler/self-host closure; individually qualified |
| proofscript/sdk or development-only SDK package | Typed clients, schemas, fixture runner, examples | Convenience only; no authority or general service registry |

Here, core distribution means the required compiler product: psc, pscore, psfrontend, pskernel-core, and psbackend-ts with their declared runtime/toolchain dependencies. Thus `npm install -g proofscript` should provide all five components without five manual installs. They can be bundled modules or actual required npm dependencies; this plan does not assume ownership or separate publication of every unscoped name. It does not mean putting TypeScript lowering or TypeScript-specific concepts inside pscore or the logical kernel. The source compiler remains written in its supported .lean/.ps profile.

Publish the supervisor and kernel at clear consumer boundaries. The compiler-core, frontend, and TS backend can initially be subpackages or subpaths under a shared version if separate publication would add only coordination work. Proof sources, docs, archives, and historical seeds remain in the repository without automatically entering release tarballs.

### Portable Core providers: JavaScript before Wasm

Retain `pskernel-core` as one logical/source component. The user's latest preference is to investigate an executable JavaScript artifact before the Wasm implementation. The order is the current qualified native provider, then a separately qualified `pskernel-core-js`, followed by a qualified `pskernel-core-wasm` option. Keep `pskernel-core-native` available as an explicit approved runtime. A default change is a release decision after its own qualification.

Generate JS through the required PSC TypeScript backend and pinned TypeScript 7. These execution artifacts share the selected Core source/profile; they do not introduce separate handwritten checker implementations. Bundling versus separate npm publication can remain incremental. A JS provider can remove per-OS kernel binaries from its default payload, but does not automatically qualify other Node versions, macOS, ARM, browsers or arbitrary npm JavaScript.

The proposed `--kernel-runtime js|wasm|native` selects a release-approved artifact before admission. It never enables the acceptance-affecting native-reduction capability, falls back after rejection/timeout, or accepts an arbitrary third-party checker. The supervisor owns identity reporting and exact request/artifact binding. Use a release-owned provider process. JS execution trusts approved generated code and its runtime; a subprocess supplies lifecycle separation rather than a sandbox for arbitrary JavaScript. Wasm additionally needs a qualified minimal import/adapter boundary; a generic Emscripten launcher or Node WASI is insufficient evidence.

The bounded J0 probe has not produced current Core JS: the qualified F compiler refuses `psKernelCheckerStateExitLocalScope` at the selected Core revision because its standard environment lacks `Nat.max`. Preserve that kernel refinement. Resolve source resolution, admitted standard definitions, runtime meaning and pinned native-prelude agreement before another unchanged-Core probe. Historical successful TS7/Core JS generation demonstrates feasibility only at its own source.

Source-level kernel proofs can be shared when their assumptions match. JS adds PSC/erasure/IR/TS7/runtime refinement obligations; Wasm adds the selected compiler/runtime-to-Wasm obligations. Runtime validation and differential tests do not discharge semantic preservation or logical consistency. Formal assurance remains a later gate; mandatory admission and artifact validation apply immediately. See [KERNEL_JS_PLAN.md](KERNEL_JS_PLAN.md) for J0/J1 evidence and gates and [wasm-core-provider-plan.md](docs/platform/wasm-core-provider-plan.md) for W0–W3. Current native receipts and fixed-point evidence remain accurately labeled.

Use one development-only compiler assurance workspace at `psc0/proofs/`, organized by package. This is a source/build boundary, not another mandatory npm package or compiler plugin framework. Its pinned Lean toolchain and optional proof libraries are installed by the assurance workflow only. Keep the kernel's canonical assurance library under its existing ownership and reuse its results at an explicit source/profile boundary; do not create a second kernel proof copy. Section 16 specifies the layout.


### The installed product: proofscript provides psc

The target quick-start is `npm install -g proofscript`, followed by the `psc` command. npm supports this through a package `bin` mapping; the package and command names need not match. `psc` can remain the internal supervisor module name without requiring another public CLI wrapper package. [E16]

`proofscript` should provide the supported default language profile, protected admission/checking, the required TS backend and declared TS7 toolchain path, ordinary project/library resolution, and the extension host. Distribute ready-to-run artifacts for qualified platforms. Ordinary compiler use should not require a Lean development installation, compiler metaproofs, or building PSC from its repository. State supported platforms and any required host runtime precisely.

| Consumer-facing name | Purpose |
| --- | --- |
| `proofscript` | Main compiler distribution; installs `psc` and can expose `proofscript/sdk` as an API subpath |
| `pskernel-core`, `pscore`, `psfrontend`, `psbackend-ts` | Source/module boundaries; publish separately only where independent consumption helps |
| `@proofscript/psbackend-rust` | Proposed optional official Rust extension, if the project controls `@proofscript` |
| `@someone/psbackend-rust` | Illustrative third-party backend using the same extension contract |
| `@someone/psmath` | Illustrative ordinary ProofScript library |

The npm scoped spelling is `@proofscript/psbackend-rust`. npm scopes belong to users or organizations; owning the unscoped package `proofscript` does not establish ownership of `@proofscript`. Use a controlled scope, and identify the actual resolved package origin. A name inside a package's manifest or an npm alias does not establish official provenance. [E17]

Non-default extensions are independently installed project dependencies. Do not list every optional backend in the main product's default dependency closure. Most users should install one compiler product, then only the additional packages their project needs. Third-party publishers may use their own scoped or unscoped names; the `ps...` convention is useful naming guidance, not an authorization rule.

### Adding standard features through later releases

Use the existing extension loader and one small release-owned defaults table. Each entry records the exact shipped component identity, supported operation, activation trigger, and bounded grants. This is internal release metadata using the same operation/identity contracts as project extensions, not another user configuration system or plugin framework.

To include a ready `psdev` or `pslsp` in a future `proofscript` release, include its prepared payload in the release bundle or its required runtime dependency closure, then add the corresponding default entry. A dependency needed by installed users cannot exist only in the product's development dependencies. A feature promised in every supported installation should not rely on an optional dependency whose absence is silently tolerated. Qualify the assembled installation. npm provides dependency and bundling mechanisms; PSC supplies the activation policy. [E16]

| Component | Available after installing a release that includes it | When work starts |
| --- | --- | --- |
| Required compiler components | `psc check` and `psc build`, supported default language and TS backend | The requested compiler operation |
| Default psdev | Proposed `psc dev --watch` | Only when that command is invoked |
| Default pslsp | Proposed `psc lsp --stdio` | Only when an editor or user requests a server session |
| Non-default backend or third-party extension | After project installation and explicit operation activation | When the enabled operation is requested |

Installing or running `psc --version` must not start a watcher, language server, prover, or background update service. Distinguish shipped, enabled, loaded, and executed components in status/provenance. Default extensions still use the qualified isolation boundary and mandatory actual-load reporting; official status is not a same-process exception.

The project may disable an optional default in its existing root configuration, and host restrictions may further reduce grants. It cannot disable kernel admission, required validation, disclosure, or obligations of its selected profile. Project packages cannot override a release default merely by sharing its name; replacements require an explicit compatible selection with no ambiguous registration. Resolve shipped defaults from the compiler's release-controlled installation and project additions from the selected project's graph.

Users receive newly included defaults when they intentionally install/update that `proofscript` release. A globally updated compiler does not change a project's pinned local compiler. Builds never fetch a newly discovered default or activate arbitrary installed dependencies. This preserves incremental product development and reproducible project behavior.

### User journey: global convenience and reproducible projects

All `psc` commands and configuration examples in this subsection describe the proposed product experience. They are not claims that the current published npm package already implements them.

For a quick trial:

```sh
npm install -g proofscript
psc --version
psc check main.ps
psc build main.ps
```

The ordinary default build uses the supported bounded language and the required TS-to-JS route. A successful check reports the admission/checking scope actually performed; it does not imply full PSCV verification or unrestricted Lean support.

For a project, install an exact local compiler version and commit the npm lockfile. A thin proposed `psc init my-app` can create a source file, project configuration, and build script, after which the user runs `npm install --ignore-scripts` and `npm run build`. This scaffold needs no template/plugin framework.

The project build script should invoke its installed `proofscript` launcher by its documented package path. A proposed generated script is `node ./node_modules/proofscript/bin/psc.mjs build`; the launcher path becomes a supported product contract. The public `psc` bin remains available for direct use. This avoids selecting a compiler through a conflicting third-party `psc` bin link. Do not automatically require/import a project-local compiler from the global supervisor or silently change compiler identity.

TypeScript likewise recommends per-project installation for reproducibility while supporting a global command for convenience. npm scripts normally expose local dependency executables through `node_modules/.bin`; the explicit launcher path avoids a conflicting `psc` link, but `node` inside an npm script still resolves through that modified PATH. Keep `npm run build` as the development convenience. Controlled CI uses `npm ci --ignore-scripts`, then invokes the documented launcher with the CI-provisioned pinned absolute Node executable and sanitized execution environment. It must not resolve either executable through third-party dependency bins. A workspace with a different package layout configures its exact launcher location. [E18] [E19] [E20]

Resolve enabled extensions from the selected project root and its installed dependency graph, including declared npm workspaces/hoisting, even when the user intentionally invokes a compatible global compiler. Report the actual compiler identity and check compatibility. Do not search arbitrary ancestor/global plugin directories, auto-download packages during a build, or silently select a second compiler to satisfy an extension.

A project's lockfile and the published global product are different boundaries. npm excludes `package-lock.json` from package tarballs; the inspected npm v12 documentation also says dependency shrinkwrap files are ignored. Assemble a minimal release-controlled runtime closure, using bundling where needed to prevent floating shipped dependencies. Keep exact component/toolchain identities in the release receipt and qualify the advertised installation path on supported platforms. [E16] [E21]

### User journey: add an optional backend

Assuming control of the illustrated official scope, install the extension in the project:

```sh
npm install --save-dev --save-exact --ignore-scripts @proofscript/psbackend-rust
```

Then enable its particular operation in the root project's `package.json`. The proposed data-only configuration is:

```json
{
  "proofscript": {
    "extensions": [
      {
        "package": "@proofscript/psbackend-rust",
        "enable": ["backend:rust"]
      }
    ]
  }
}
```

This is an addition to the existing `package.json`, not a replacement for its dependencies or scripts. One root `proofscript.extensions` configuration is sufficient initially; do not introduce several competing configuration files or a second package lockfile.

With the generated project build script:

```sh
npm run build -- --target rust
```

The compiler resolves the locked package, reads its descriptor as data, checks its protocol and selected operation, records its actual artifact identity, and executes it through the qualified isolated runner when the operation is used. Only the supervisor validates and publishes the result. Uninstalling an enabled package or selecting an unavailable/incompatible target gives an actionable error; the compiler does not fetch or substitute another backend.

For this story, the initial Rust operation emits Rust source. Building a native executable additionally requires the declared Rust toolchain and runtime dependencies; that should be an explicit later tool-service integration. Installing an emitter does not grant it arbitrary process execution or make `rustc` part of the mandatory TS self-host closure. Any later tool service must itself preserve isolation and protected publication; Cargo build scripts, procedural macros, and additional foreign dependencies cannot enter as undeclared host execution.

A build using an optional backend records its preservation evidence or explicitly allowed backend/runtime assumptions. An ordinary profile can allow a selected backend as trusted implementation; a profile requiring verified execution must refuse missing preservation evidence. Official ownership, isolation, and successful target typechecking do not establish source-to-target semantic preservation.

A proposed `psc extensions` command lists configured entries and compatibility from data without executing their code. Each actual build reports the extensions used, including externally loaded official packages. For example, it can show `Extensions used: @proofscript/psbackend-rust@<locked-version> (backend:rust)`, while the receipt retains full digests and assurance details. A TS-only build should not instantiate an unused Rust backend merely because it is installed.

### User journey: third-party extensions and libraries

A third-party extension uses the same installation and activation workflow, for example `@someone/pstactic-arithmetic` with an explicitly enabled tactic operation. There is no requirement to apply for inclusion in a global list before a conforming isolated extension can be used. Names shown here are illustrative, not verified npm package recommendations.

An ordinary library is simpler:

```sh
npm install --save-exact --ignore-scripts @someone/psmath
```

Its supported source modules or accepted data artifacts are then available through the language's normal import mechanism. Use declared source/module exports and language-profile compatibility, not executable npm `main` hooks. A pure library does not need an extension activation entry. Its declarations, proofs, assumptions, and dependencies still pass the applicable compiler/kernel/artifact checks.

A package may provide both library exports and executable compiler operations. Importing its ordinary library exports does not activate its optional tactics, native initializers, or backend. If an imported module requires a missing extension, report which package/operation is needed and require project configuration to enable it. Section 12 defines this behavior independently of filenames or publisher labels.

### Dependency direction

The supervisor orchestrates the frontend, kernel, and reference backend. Frontends and extensions depend on data contracts, never on supervisor internals. The kernel is independently buildable. Compiler semantic modules are pure and reusable. Backends consume explicit IR stages; they do not own common transformations secretly.

Keep one canonical Core wire schema. The elaborator may retain metavariables and convenient internal structures that are absent from admitted kernel terms. Avoid forcing an expensive total representation rewrite. Instead, prove that remaining conversion bridges preserve binders, universes, names/references, primitive identity, and the meaning of declarations.

The canonical schema must remain a data contract rather than a second semantic kernel. Do not duplicate admission rules in a “trusted bridge” and slowly create two checkers. Cheap structural validation belongs at decoding; logical admission belongs in PSKernel.

### First-release trust transition

The current generated JS compiler may remain a pinned first-party implementation while external packages use strict Wasm confinement. That protects against external extension execution but does not automatically remove all first-party compiler/runtime code from the admission TCB. Record that broader initial assumption explicitly.

The destination is to run candidate-producing frontend work through a qualified confined runner as well, then let the authority validate exact returned data. Moving the default JS frontend into an ordinary subprocess is useful organization but is not, by itself, a malicious-code security boundary. A qualified Wasm or OS-sandboxed route is required to make that stronger claim.


### User journey: adopt ProofScript inside an existing TypeScript project

The intended workflow is a local, pinned `proofscript` development dependency, one root project configuration, and the existing TypeScript application's normal build. A release containing default `psdev` needs no separate watch-package installation. The proposed command is `psc dev --watch`, or the project script invoking the documented local launcher with those arguments. Adjacent TypeScript emission is the selected output mode for this project; it need not also emit JavaScript into `src`.

| File | Role |
| --- | --- |
| `src/app.ts` | Existing handwritten TypeScript |
| `src/domain/quantity.ps` | New ProofScript implementation and contracts |
| `src/domain/quantity.ts` | PSC-owned generated module entry beside its source |
| Configured generated directory within the TS source root | Shared project bundle/runtime and maps where the chosen output mode requires them |

An existing TS module imports the generated entry through its ordinary supported module-resolution configuration. Users can migrate a pure function or library at a time. This does not mean arbitrary TypeScript becomes supported ProofScript by renaming its extension, nor that the surrounding application automatically becomes verified.

Save a `.ps` file; PSC checks a complete immutable project snapshot, discharges the selected contract obligations, validates the target, then publishes the accepted output generation. A failed or unavailable required check blocks publication. Section 14 defines ownership, pending/error behavior, and how a downstream build obtains a coherent generation.

Use two accurate assurance descriptions. An ordinary checked build reports admission and the validations it performed. A contract-checked profile additionally requires the selected PSCV obligations and coverage, with explicit assumptions. That can ship before the compiler's full formal proof program, while identifying the compiler/runtime relations still trusted. A stronger profile promising verified executable semantics additionally requires the corresponding preservation evidence. Neither successful typechecking nor a proof of a weak/incomplete specification means arbitrary application correctness. TypeScript's `noEmitOnError` concerns TypeScript diagnostics; it does not enforce PSC admission or contract obligations. [E27]

### Neighboring output: fix module semantics before promising separate compilation

The targeted implementation review found a whole-IR emitter: `psTsEmitModule` emits all supplied layouts/declarations and embeds runtime support. The same implementation creates private symbol identities and a local generator-function registry. [R41] Preparation accumulates declarations without retaining their source-module partition in its admission-ready result. [R42] The IR module has imports/layouts/declarations, but no source ownership/export graph. [R43]

Consequently, independently emitting each file's complete closure would duplicate runtime/type identities. This is an architectural inference from those representations, not an observed integration-test failure. Watch mode is not just a filesystem wrapper around the current emitter.

The smallest useful first stage is **one qualified ProofScript project bundle plus mechanically thin neighboring re-export modules**. Preserve an explicit source-to-public-export map; each neighbor exports its declarations from that bundle. Derive the types from accepted export information. Do not infer ownership from mangled names, duplicate initialization/runtime state, or add another type checker. This is an output layout with a bounded public ABI, not a second module system.

The long-term module-output design preserves declaration ownership, generated-name ownership, imports/exports, and initialization meaning through preparation and lowering. Each runtime type has one canonical owning module; other modules import its identities. Shared calling support has a versioned ABI. Start with pure libraries, a qualified acyclic module graph, and supported TS module/target settings; arbitrary cross-language initialization cycles and independently loaded duplicate runtimes need explicit later semantics. Do not turn temporary bundle layout into a permanent compatibility constraint or split emitted strings to simulate linking.

Keep the first interop boundary small. Current erasure maps `Nat`/`Int` to `bigint`, `Char`/`String` to `string`, and `Unit` to `undefined`; these target types do not express every source invariant. [R44] Calls from handwritten TS/JS need the supported runtime boundary checks and a representation/ownership policy, including mutable aliases. For example, a `Nat` boundary must not accept an arbitrary negative `bigint`. TS `readonly` or a cast does not enforce runtime immutability.

Calls from ProofScript into TS need an explicit FFI contract and checked implementation evidence, supported runtime enforcement for the particular decidable property, or a profile-approved disclosed assumption. A `.d.ts` signature or implementation hash proves neither postconditions nor termination/effects. Initial TS-to-pure-PS exports offer useful incremental adoption before broad FFI support.

### Language-server and VS Code delivery

Develop `pslsp` after the compiler exposes small snapshot/query services. Start with versioned diagnostics, hover, and definition lookup; add completion, rename, and richer actions when their source/origin mappings are adequate. Reuse parser, elaborator, environment queries, and admission status. Recovery analysis may describe incomplete code, but cannot manufacture a publishable accepted result.

The LSP architecture supports a server shared by editor clients; a thin VS Code extension starts/selects it. npm can distribute the server. Install the VS Code client through its normal Marketplace or VSIX route, separately from `npm install -g proofscript`; do not modify the editor through npm lifecycle scripts. [E26] [E28]

Select the compatible pinned local compiler in a trusted workspace, or an explicitly selected installation. Display the selected compiler and server identities; do not silently substitute/download another version. Honor editor Workspace Trust before executing workspace-selected components. It does not replace PSC's own extension boundary. [E29]

Keep unsaved-buffer analysis in memory and label results with document version and dependency snapshot; saved build outputs have a different identity. Do not publish neighboring TS from unsaved analysis. Route full-Lean `proofs/**/*.proof.lean` companions to their normal Lean tooling unless the user explicitly selects another supported route. A ProofScript editor extension must not claim all `.lean` files merely because the compiler supports a bounded Lean source profile.

Ordinary TS source maps relate emitted JavaScript to TypeScript. PSC additionally needs its own generated-TS-to-PS origins and qualified map composition for debugging through both stages; emitting a `.ts.map` alone does not guarantee consumer support. Diagnostics and refactoring need compiler source mappings too. [E25]

The pinned TS7.0 line does not expose the old programmatic compiler API: Microsoft's documentation marks the older examples as TS6-and-earlier, and the TS7 release describes the missing/new API boundary. Use the pinned CLI and supported protocols initially; do not base `psdev` on old `createWatchCompilerHost` examples or introduce TS5/TS6 as a hidden fallback. Rich virtual-file integrations can follow a separately qualified supported API. [E23] [E24]

## 11. Trust belongs to claims, not package names

| Claimed property | Trusted implementation or assumptions until proved / independently checked |
| --- | --- |
| Logical admission | Exact decoder/bridge, approved environment construction, kernel, axiom policy; executable checker runtime and its compilation chain |
| Source fidelity | Selected parser, name/notation interpretation and elaboration, or a checked source-to-Core relation |
| Executable preservation | Erasure, every selected semantic pass, backend, runtime representations, permitted FFI |
| PSCV coverage | VCG semantics, executable dependency coverage, obligation association, discharge and publication gates |
| Extension isolation/disclosure | Supervisor and loaded first-party code, runner/engine, host bindings, package ingestion, official output channel |
| Reproducible bootstrap | Source/seed/toolchain identity, deterministic process, exact comparisons; stronger correctness needs compilation refinement |

The OS, hardware, and runtime remain environmental assumptions unless separately covered by a stronger verified stack. A kernel written in Lean does not by itself prove the generated native or JS binary faithful to that source. Lean’s FAQ explicitly distinguishes the executable trusted base from the core proof checker. [E02]

### What absolutely stays protected

- Kernel environment construction and mutation, logical rule selection, inductive/Quot admission, and trusted reductions.
- Assumption policy and transitive dependency accounting.
- Admission/validation evidence state and the exact association between checked inputs and outputs.
- PSCV activation, required coverage, and final authorization when that profile is selected.
- Extension capability grants, actual-load records, authoritative diagnostics, and final artifact publication.

The supervisor is initially a small explicitly trusted implementation. Its state machine deserves a specification and targeted refinement work because a wrong gate or mismatched object can invalidate the delivered guarantee. Routine command help, formatting, package search UX, and editor UI do not all need mechanized proofs.

### What can be extensible without logical authority

Syntax, notation, desugaring, elaboration search, macros, tactics, proof search, diagnostics, formatting, optimizer search, target emission proposals, CLI subcommands, editor services, and project tooling can all operate outside authority. Their freedom ends at fixed accepted data and evidence contracts.

An extension may request a theorem check or read a bounded environment view. It cannot add an unchecked environment entry, change the expected theorem after seeing a failed proof, install a native evaluator, weaken the current profile, or mint a valid receipt. Custom logical foundations require an explicit alternate core/profile release, not an invisible extension toggle.

### Source intent requires a credible anchor

A proof can be valid for the wrong proposition. If the same untrusted frontend creates both the purported “expected” goal and the proposed proof, comparing them does not establish the user’s intended source meaning. The immediately feasible guarantee is correspondence to the recorded canonical contract. Fidelity to the user’s text additionally needs the trusted default interpretation, a verified frontend relation, or an independently supplied/reviewed challenge. [E01]

Do not solve this by building a second full frontend just to label it trusted. Keep the default interpretation an explicit assumption until its small accepted profile can be specified and refined. New syntax packages should disclose their expansion semantics and exact identities.


## 12. A narrow extension API

The API should exchange immutable serialized data, not callbacks into kernel objects. The supervisor fixes the run, environment, profile, input identities, and required relation before invoking an extension. Results are proposals; all authoritative decisions occur after validation.

| Operation | Extension may return | Protected decision |
| --- | --- | --- |
| expand | Syntax expansion, origin map, namespaced metadata | Grammar policy, binding/shape validation, selected interpretation |
| elaborate | Core declarations/terms, constraints, diagnostics | Expected goal, resolved environment, canonical decoding, kernel admission |
| prove | A term for the requested goal | Kernel checks the exact requested proposition |
| transform | Candidate RuntimeIR plus restricted rewrite/refinement certificate | Validator checks the fixed input/output relation and invariants |
| emit | Target representation/bytes and supported evidence | Approved backend relation, runtime contract, exact final bytes |
| command | Diagnostics and requests for declared tool services | Capability policy and any resulting build/publication transaction |

These are the eventual operation families, not six independent frameworks to implement immediately. The first slice needs one producer protocol with a syntax example, a proof-term example, and a small read-only command example.

### Illustrative transport shape

```text
Request {
  protocol, operation, runId, requestId,
  sourceProfile, coreSchema, runtimeAbi,
  inputDigest, environmentDigest, policyDigest,
  expectedGoalOrRelationId,
  payload, limits
}

Response {
  requestId, candidate, certificate?, origins?, diagnostics
}
```

No response field grants authority. Digests are transport bindings under a stated hash assumption; they are not semantic proofs. The expectedGoalOrRelationId is supplied by the supervisor, not chosen by the extension after producing its output.

Start with a bounded length-prefixed encoding using the existing canonical codecs where possible. Enforce complete decoding, integer/string bounds, no duplicate or unknown authority fields, and canonical names/references. Keep the runner ABI small, for example guest memory plus a bounded request/response entry point and explicit read-only host queries. A full component-model framework or general RPC stack is unnecessary for the initial interface.

### Registration and compatibility

Descriptors are data-only and identify operation handlers, explicit syntax namespaces/entry points, protocol versions, and requested capabilities. The host determines actual package/module identity and grants. Reject ambiguous registrations and hidden overrides; define deterministic import/priority rules and hygienic naming behavior. Include the selected grammar and extension identities in cache keys.

Freeze builtin syntax and primitive identities within a profile. New syntax may expand to fixed Core; a new semantic instruction or trusted reduction requires a reviewed profile version. Do not add an open extension payload to kernel expressions or RuntimeIR that bypasses semantic interpretation.

Offer a narrow SDK with schemas, a fixture runner, canonical test inputs, and three complete example packages. A new macro or tactic should not require editing the kernel, a generic registry framework, and several regex guards. Compatibility is a small explicit protocol/profile matrix, not a growing web of per-package implicit assumptions.


### Ecosystem policy: open participation with project-controlled execution

Recommend an open third-party ecosystem with a small supported official distribution and an optional curated compatibility catalog. The release defaults and the project's explicit enabled-extension list authorize the selected operations, subject to project/host restrictions. A project or organization may deliberately restrict that list to official or approved versions, but a central catalog is not required for every user or every build.

| Policy | Benefit | Cost or limit | Recommendation |
| --- | --- | --- | --- |
| Official organization only | Small initial support matrix and clear ownership | Restricts community/company-specific extensions; ownership still does not prove soundness or isolation | Reasonable initial support scope, not a permanent protocol restriction |
| Central approval list for all extensions | Centralized review and discoverability | Review bottleneck, catalog maintenance and availability dependency; approved versions still need confinement/checks | Optional curated catalog or organization policy |
| Open extensions with explicit project activation | Broad ecosystem and local experimentation while preserving fixed boundaries | Requires a documented SDK, compatibility checks, and a qualified runner | Recommended architecture |

A curated entry may identify maintainer, tested compiler/protocol versions, support status, and demonstrated evidence. Those are separate fields: `official` must not imply `verified`, and `community` must not imply `unchecked`. Derive any official badge from authenticated resolved origin and a release-controlled identity record; do not accept a package's self-description or apparent install path.

The first release can ship and support a few official examples while making the interface available to compatible third-party packages. Do not build an online plugin marketplace, package manager, publisher-approval service, or auto-updating catalog dependency into the trusted compiler. ESLint provides a useful precedent for explicit configured plugins, including local unpublished ones; PSC should use data-only configuration and isolated execution for its stronger boundary. [E22]

### Library content and compiler execution are different capabilities

Classify behavior, not extensions such as `.ps`, `.lean`, or a manifest's claim to be a library.

| Package content | Admission/use path | Execution authority |
| --- | --- | --- |
| Functions, types, theorem statements, proof terms, supported source modules | Normal imports and checked declaration/artifact pipeline | No automatic compiler extension grant |
| Supported declarative notation or checked rewrite data | Fixed frontend/checker machinery; selected language environment recorded | No arbitrary callbacks; validate and bound the data |
| Executable parser, macro, elaborator, tactic, optimizer, command, or backend | Explicit enabled operation through the isolated extension protocol | Only the fixed operation and explicitly granted host services |
| Foreign JS/native/Wasm runtime dependency | Explicit runtime/FFI dependency path | Program runtime behavior; separate from compiler authority |
| Kernel provider, native evaluator, axiom policy, final receipt/publication operation | Protected distribution/profile selection | Never an ordinary extension grant |

An ordinary library may still introduce logical assumptions, effects, or foreign calls. Apply the selected assumption and PSCV coverage policy to the imported closure. Typechecking ordinary library code does not establish arbitrary application contracts. Do not require every ordinary library to carry complete functional-correctness proofs for ordinary compilation; require the proofs/evidence promised by the selected profile.

A supported Lean source import is not permission to load an arbitrary native Lean module, initializer, or `.olean` environment into the supervisor. Imported artifacts are untrusted data until admitted by the specified acceptance route. Heavy Lean tactics remain possible through the separately qualified authoring/compatibility route; being first-party does not create a same-process exception.

Ordinary source/runtime dependencies belong in build provenance. The mandatory extension summary identifies executable compiler extensions actually used; it must not mislabel pure imported libraries as privileged plugins or omit executable hooks merely because their package calls itself a library.

### Activation, dependency closure, and compatibility

Installing an arbitrary package alone does not authorize compiler execution. The effective activation set comes from release-owned defaults plus explicit project entries, reduced by configured restrictions and explicit disabling of optional defaults. Use the root project's data-only configuration, npm's existing lockfile, and the fixed operation contracts. Resolve shipped defaults from the release-controlled product and project entries from the selected installed dependency graph, without evaluating package entry modules. Do not discover plugins by package-name prefixes, by scanning all of `node_modules`, or by executing imported configuration.

The illustrative `enable: ["backend:rust"]` grant permits that operation only. It does not authorize new tactic/command handlers, filesystem/network/process services, kernel mutation, or reporting changes. Record grants in the project configuration; changed or additional grants require an explicit configuration change. Repeated builds use those grants without interactive permission prompts. Lockfile updates change artifact identities and must be reflected in receipts and any affected assurance claims.

If organization/host restrictions are configured, effective grants are the intersection of those restrictions, the selected release/project activation grants, and the fixed protocol. Packages cannot widen them. Ordinary users do not need a separate organization policy layer.

A bundled helper remains inside its parent's isolated artifact and capability limits. A separately executing extension dependency must be explicitly present in the resolved release/project activation set; a parent or library dependency declaration is not authorization. Dynamic resource access goes through bounded host services with actual resource identities recorded. Guests cannot independently load another host-side plugin, fetch new code, or start a process.

Treat compatibility as explicit protocol, Core schema, runtime ABI, source-profile, and operation support. Reject unsupported combinations and ambiguous registrations. A new package may extend documented syntax/operations; it cannot shadow protected CLI commands, replace the kernel, reinterpret a fixed primitive, or add an unvalidated trusted IR instruction.

Extension packages should carry their prepared isolated payload and data descriptor. Their implementation may use any toolchain producing the supported payload; they need not all be formally verified or self-hosted. A plain npm JavaScript callback does not meet the strict isolation contract. Additional native/full-Lean compatibility modes need their own qualified boundary rather than an automatic fallback.

### Development services reuse the same authority boundary

Keep filesystem notifications, immutable snapshot capture, authoritative cancellation/status, process launching, LSP framing, and publication in small release-controlled host adapters. These adapters are part of the relevant host TCB, outside the logical kernel and compiler source closure. Optional tool algorithms can run as isolated producers receiving events/data and requesting the same checked-build or read-only query operations.

For `psdev`, the guest may request another build or present bounded diagnostics; only the supervisor validates inputs, establishes a generation, and publishes outputs. A downstream command runs only through an explicit user-configured host tool service, never through an extension's arbitrary process request. For `pslsp`, the host owns protocol transport and authoritative status, while analysis reuses compiler services.

Do not describe ordinary Node filesystem/LSP adapter code as sandboxed extension logic. Conversely, shipping an official npm package does not authorize importing its JavaScript entry point into the authority process. A release decision to incorporate host implementation is recorded as trusted host adoption under the following policy. No second admission service, general daemon framework, or independent watch dependency engine is needed.

### Adopting mature extension functionality

Yes: extensions are a useful place to develop and evaluate functionality before deciding whether it belongs in the standard product. Keep three kinds of adoption distinct.

| Adoption | Meaning | Required boundary |
| --- | --- | --- |
| Default distribution | Ship or enable an extension by default | It can remain isolated and separately packaged; external runtime loads still appear in disclosure |
| Built-in implementation | Maintain a stable capability inside psfrontend, pscore, a backend, or another appropriate internal module | Preserve candidate/evidence validation; avoid duplicate implementations; record changed execution and bootstrap dependencies |
| Trusted semantic change | Add a runtime primitive, logical rule, or stronger admission capability | Explicit specification/profile revision and corresponding proof, validator, and compatibility obligations |

Prefer default bundling or a standard-library home when that provides the value without growing the semantic core. A proof-search tactic still returns a kernel-checked term after adoption. An optimizer still needs its required preservation evidence. Moving code into the authority process would enlarge the trusted implementation and requires a separate decision; source ownership alone is not justification.

Use a short promotion record: concrete benefit; correct module; dependency/TCB changes; preserved or updated evidence; and bootstrap impact. If compiler source starts depending on the feature, first build a successor that supports it using the predecessor's accepted source profile, then qualify the changed closure and preserve the last accepted seed.

An implementation written in another language does not become self-hosted merely by moving into a core directory. Essential compiler implementation must be expressible in the selected self-host source profile, or remain an explicitly identified external dependency under a narrower claim.

Only the supervisor's controlled release configuration can identify a component as built-in. A statically adopted feature is covered by the core release's reproducible component manifest and provenance. A separately loaded external component remains in mandatory extension reporting even when official or bundled by default. An extension cannot promote itself or suppress its own disclosure.


## 13. Isolation and non-overridable disclosure

**Every external extension instantiated by PSC0 must be recorded by the supervisor before execution, and that record must appear in the official result and artifact receipt.** This is the enforceable promise under the declared launcher/runtime/OS assumptions.

Use constrained Wasm guests in a pinned engine such as Wasmtime, preferably in a dedicated runner process. Grant no ambient filesystem, network, process spawning, native libraries, terminal, or broad WASI by default. Bound memory, execution fuel/time, message size, recursion in decoders, and output volume. Batch environment queries to control IPC overhead. An engine is a dependency and part of the security TCB; it is not a theorem of perfect isolation. [E08]

Budgets must also cover work induced in the host: queries, admission, kernel conversion, certificate validation, and approved services. Guest fuel alone does not bound those costs. Checking jobs that cannot be interrupted safely in-process should run in bounded workers; timeout or termination yields no acceptance result.

**Narrow first command profile.** The initial `psc-command/1` slice uses V8 WebAssembly already included with the supported Node runtime, with a fixed trusted worker adapter. It admits one bounded `(i32) -> i32` function, no imports, memory, tables, globals, starts or calls, and accepts only a request for one host-selected checked build. It introduces no additional npm engine dependency. This is a smaller first profile than the general Wasmtime-based guest destination; a richer payload/data ABI still requires a separate engine/resource-policy decision and qualification. The WebAssembly JavaScript interface grants access through explicit imports, which this profile excludes. [E30]

The worker provides termination on a parent wall deadline; it is not an OS sandbox or deterministic fuel meter. Node's worker heap limits do not bound all external allocations and cannot guarantee process-wide availability. The profile therefore excludes guest heap allocation and bounds its bytes, locals and control nesting as well. Node/V8, the small decoder and trusted adapter remain security assumptions; this does not constitute a mechanized isolation proof. [E31] [E32]

The guest cannot provide source/output paths, admissions, certificates or receipt fields. An opaque host-owned completed request supplies the actual extension record; the ordinary checked build establishes every existing admission, IR, target and publication condition. Rechecking the captured project/lock/package/descriptor/module identity before publication binds provenance without making every command guest part of the compiler proof. Installation and explicit activation remain distinct, and an independently named npm package uses the same boundary. Read [the command SDK](docs/platform/command-extension-sdk.md) for the implemented shape and its limits.

Node vm explicitly is not a security mechanism; Node’s permission model does not promise confinement against malicious code. Worker threads, Object.freeze, package manifests, and ordinary subprocesses therefore cannot satisfy this requirement alone. Do not ship an automatic unsandboxed fallback. [E09] [E10]

### Official output is a supervisor capability

- Compute identity from the actual bytes instantiated: package/version if known, resolved origin, content digest, entry module, protocol, and granted imports/capabilities.
- Record attempted and executed loads, including failures, and retain the extension dependency identities that influenced cache hits.
- Do not accept “built-in,” “trusted,” or “verified” status from a package’s own manifest.
- Capture guest messages as tagged, escaped diagnostics. Guests never share the official terminal/status stream or write final receipts.
- Include the list in machine-readable results and a concise mandatory CLI summary. Quiet/formatting options cannot remove the record; report an empty set explicitly when appropriate.
- Protect final output paths and the admission service from guest access. A killed or exhausted guest cannot turn its partial output into a successful build.

For `psc lsp --stdio`, keep stdout valid protocol traffic. Carry compulsory disclosure through supervisor-owned framed status/notifications and durable receipts, with stderr for suitable human logs; never insert a raw CLI banner into protocol stdout. Client presentation remains outside the compiler's control.

The host can attest which modules it loaded. It cannot infer every source library compiled inside an opaque binary, prove the truth of its publisher metadata from a name alone, or ensure a human reads output after external redirection. Record bundled dependency declarations separately from byte identities. Do not promise resistance to an attacker who replaces the launcher, engine, OS, or entire installation.

### Installation is part of the boundary

npm distributes packages; it does not make their code trustworthy. Controlled ingestion must use a lockfile/integrity identities and an explicit no-lifecycle-script policy for extension packages. Keep extensions out of the supervisor’s JS module-resolution graph and sanitize inherited execution hooks. Package provenance can establish an origin claim, not safety or semantic correctness.

Use the documented no-script install path for extensions and ordinary third-party dependencies. npm lifecycle execution precedes the PSC sandbox; compiler isolation cannot retroactively protect arbitrary installation-time code. The inspected npm configuration documents that `ignore-scripts` also disables root npm extensions, while an explicitly requested `npm run` command still executes its intended script. Pin supported npm behavior instead of relying on changing defaults. Prebuilt extension/runner artifacts should not require executing an extension's install script. This needs a narrow resolver and controlled runner, not a new package manager. [E11]

Disabling lifecycle scripts does not authenticate a launcher or eliminate executable-name collisions. The supported controlled CI build invokes the known `proofscript` launcher path with a pinned absolute Node executable and verifies release/component identities, rather than trusting `psc` or `node` entries found through dependency bin links. Keep the supervisor's own implementation dependencies release-controlled and outside project-selected extension resolution. The guarantee still assumes the authentic launcher, package manager, runtime, and OS; arbitrary replacement of that installation lies outside extension confinement.

For native Lean/JS compatibility, add an explicitly selected qualified OS-sandbox mode later. State supported platforms precisely; Linux-only support is preferable to a claim of untested cross-platform parity. Failure to establish the requested isolation mode must stop that extension.


## 14. One admission-to-artifact transaction

Use one ownership path, reused by the CLI and library API:

1. The supervisor captures source bytes, toolchain, language/runtime profiles, dependency identities, assumptions, capabilities, and requested assurance policy.
2. Producers elaborate immutable candidates. The authority decodes them and binds expected contracts to the selected interpretation.
3. The kernel admits exact declarations into an authoritative environment. Rejection or resource exhaustion never produces an admitted handle.
4. Erasure consumes the exact admitted Core. RuntimeIR validation checks complete traversal, scopes, references, arity, representation and effect invariants.
5. Enabled transformations and backends meet the requested assurance policy. Required relation evidence, target checks, and PSCV obligations complete; ordinary compilation records any unproved semantic relations explicitly.
6. The supervisor binds emitted bytes, runtime dependencies, evidence, assumptions, and extension records into one result and publishes that exact transaction.

Staging executable candidates before every check is allowed internally. Successful production publication is not. Reuse the existing owned-session and same-object ideas to avoid checking one object and emitting a different one. Rename weaker construction APIs instead of granting them production artifact authority.

### Publication and caches

Own immutable byte buffers or content-addressed objects across checking and finalization; do not re-open a mutable path and assume it contains the checked bytes. Publish a completed directory/manifest pointer atomically where the platform permits it. Independently renaming several output files does not make a multi-artifact transaction atomic.

Cache identity must include source and imported environments, the canonical schema, logical foundation, assumption policy, primitive/runtime ABI, pass/backend identities, toolchain, extension digests, and granted capabilities. Prefix checkpoints are a good initial performance mechanism. Avoid a global incremental framework until invalidation costs are measured.

Every compilation-affecting host query reads the transaction’s immutable input/environment snapshot. Any additional file, service response, or tool result becomes an exact recorded dependency; otherwise its output is not eligible for reusable acceptance caching. The simplest first release should prohibit such extra compilation-time reads and keep read-only tool commands separate from cached transformations.

External cache entries carrying accepted:true are proposals. Recheck proof/certificate evidence, or rely only on an explicitly authenticated own-cache policy whose trust assumptions are disclosed. A receipt is an audit record; it does not become a portable kernel certificate just because it is serialized or signed.

### Watch generations and neighboring-file publication

Watch mode is a repeated use of this transaction, not a weaker checker or a second authoritative environment. Start with one ProofScript project as the publication unit. Reuse qualified prefix work conservatively; a sound fine-grained dependency engine is not a prerequisite.

Capture saved source/dependency bytes, contract/proof inputs, profile, compiler/backend/runtime identities, enabled extensions, and any admitted resource dependencies in an immutable snapshot. Give each attempt a generation identity and stage output privately. Failed/cancelled generations must not mutate accepted state. Delayed tasks retain their original identity, and cannot publish or clear a newer error after being superseded.

Recheck generation and relevant input identities before committing, and serialize publication with observed invalidations. Watch events schedule work; they are not evidence of input equality. Rescan after watcher errors and reconcile outputs at startup. A watcher cannot detect every filesystem edit instantaneously: promise exact validity for the recorded snapshot and rejection of work known to be superseded, not permanent simultaneity with a changing disk.

Invalidate on changed source bodies, imported definitions, contracts, proof dependencies, foreign bindings, profiles, extension identities/resources, or relevant runtime configuration. An unchanged TS signature does not justify reuse of proofs that depended on a transparent definition's body. Conservative whole-project invalidation is acceptable initially.

For a strict contract-checked watch session, an observed saved-input invalidation marks the current generation pending and withdraws affected owned neighboring outputs. Failed checks keep them withdrawn. Retain the last successful generation privately if useful; an already running application may continue only as visibly belonging to that older generation. Withdrawing source output does not retract previously emitted JS or stop a running server. A last-successful convenience mode may retain visible old files, but must label them stale and cannot claim the strict freshness behavior.

Keep one output-ownership record containing canonical source/target, accepted content digest, and generation, plus a single-writer lease for each output root. Refuse handwritten targets and user-modified generated files. Reconcile renames/deletions only for still-owned bytes; check symlink/case/path collisions; exclude outputs from input watching. A comment saying “generated” is informative, not deletion authority. Avoid rewriting equal bytes while still updating snapshot/evidence identities.

Per-file atomic replacement does not provide whole-project atomicity. Independently running `tsc` or a bundler can observe mixed generations; a final manifest or debounce cannot fix a consumer that ignores the generation. Support these modes explicitly:

| Consumption mode | Guarantee |
| --- | --- |
| One-shot PSC build, then downstream build | Downstream starts after completed publication; controlled builds must also keep selected inputs stable |
| Watch with a coordinated downstream build | Start it only after complete publication, keep generated inputs stable while it reads, and do not promote an application build for a superseded generation |
| Independent existing TS/bundler watcher | Convenient neighboring updates, with possible intermediate mixed generations; no graph-atomicity claim |
| Later consumer integration pinned to an immutable generation | Coherent graph when the consumer pins that generation for its entire read/build |

On partial publication or a crash, block coordinated consumption until recovery completes. A mutable “current” directory pointer is insufficient if a consumer resolves it repeatedly while it changes. Do not advertise arbitrary live-server integrations as verified merely because PSC emitted checked files.

The minimal dev integration owns sequencing, not another build system. The existing application's build may remain responsible for TS/bundling, but a strict successful build/reload is conditional on the matching PSC generation. Developer examples and CI must run the PSC gate before consuming generated outputs, or explicitly validate a matching completed generation.

### Evidence fields, not a universal verified flag

Separate kernel admission, complete IR validation, target-policy acceptance, finite conformance, semantic-preservation evidence, PSCV coverage/discharge, and bootstrap reproduction. Each field names the scope, subject digest, checker/theorem/version, and assumptions that justify it.

Until end-to-end semantic preservation is established, ordinary compilation may remain available with accurate narrower claims. If the user selected a profile requiring semantic preservation or PSCV, absent evidence blocks publication of that promised result. A plugin cannot silently downgrade the requested profile.

The current strict ledger is a useful starting inventory: nine erasure, four normalization, eleven expression, and nine target/runtime obligations. Preserve its explicit unproved status until each rule has its required evidence. [R18]


## 15. Compositional compiler correctness

Define stable source/Core/RuntimeIR/target semantics and prove pass interfaces once. The relevant shape is:

```text
Inv_i(p) and Check_i(p, q, certificate) = accept
    implies
Inv_j(q) and Refines_i(q, p)
```

Here Check_i has a proved soundness theorem for a specific relation. For a directly verified deterministic pass, its implementation theorem can supply the same implication without a certificate. A composition theorem then connects the sequence of relations under their stated invariants.

An optimizer can change search strategy without changing the checker theorem. A tactic can change proof search without changing kernel admission. A backend change still needs a valid backend relation; simply parsing or type-checking its output cannot establish executable correspondence.

### Semantic boundaries worth specifying

| Boundary | Required obligation |
| --- | --- |
| Source → Core | Selected syntax/name/notation semantics, binding, elaboration correspondence, intended contracts |
| Core codec / kernel bridge | Round-trip/canonical decoding, names, binders, universes, references, exact admitted object |
| Admission | Well-formed environment preservation and accepted-term soundness under allowed assumptions |
| Core → RuntimeIR | Proof/type erasure, dependent representations, primitive identity, closure/environment relation |
| RuntimeIR → RuntimeIR | Explicit simulation or observational refinement; preservation of invariant and effects |
| RuntimeIR → target | Lowering and runtime representation correspondence for exact output |
| Artifact transaction | Only evidence-associated bytes and dependencies can obtain successful publication |

Begin with one fixed RuntimeIR and one reference backend. Introduce another internal IR only when it removes a concrete semantic ambiguity or repeated reasoning, such as explicit closure conversion or specialization. Do not turn every implementation step into a separately versioned public dialect.

### The runtime model must be concrete

Specify values, calls/closures, evaluation order and demand, arrays/mutation/aliasing, exceptions or errors, strings and indexing units, integer behavior, effects, foreign calls, and observable results. Erasure must preserve what remains observable, including where an argument is evaluated or discarded.

Resource behavior needs a stated theorem. Permitting a target to return the wrong normal value is never acceptable. Allowing an explicit out-of-memory/stack/fuel outcome can be reasonable, but a theorem that permits every compilation to fail would be too weak to deliver the intended compiler. Distinguish partial-correctness-on-success from progress or termination preservation under stated resource conditions. CakeML provides a useful precedent for explicit resource-aware observations. [E04]

Make primitive IDs and runtime semantics a finite shared specification. Generate repetitive implementation tables when useful, but do not treat a generated table as proof that every backend realizes the specified behavior. The generator and each semantic implementation still need appropriate justification.


## 16. Validators, PSCV, and proof maintenance

### Where small validators work

Use proof terms for tactics; approved rewrite-rule instantiations and occurrence/binding checks for simple optimizer certificates; typed mappings plus a specific relation for representation passes. Reject unsupported evidence rather than adding an unrestricted “trust this plugin” escape hatch.

A sound validator for arbitrary program equivalence is not a realistic universal gate. Restricted algorithms and certificates are the practical choice. CompCert’s allocation validator succeeds because it checks the particular relation needed for allocation; it is not a general compiler-equivalence solver. [E05]

For an external backend, offer two honest paths: supply evidence for an implemented accepted relation, or be explicitly identified as an additional trusted backend in a profile that allows it. A profile promising verified executable behavior must refuse a backend whose correctness has not been established. Backend plugins cannot weaken that profile themselves.

### PSCV shares executable semantics

The supervisor owns whether PSCV is required and what coverage means. An optional package may supply an approved VCG, but it cannot declare itself optional after activation, choose an empty obligation set, or mark its own coverage complete.

The intended soundness theorem is:

```text
VCG is sound for the specified program semantics
and Coverage(program, contracts, effects) = complete
and every generated obligation is kernel-checked
    implies
the modeled program satisfies the stated contracts
```

That implication requires a proved VCG or a checked derivation of its conditions against the same program semantics used for compilation. To transfer it to emitted execution additionally requires compiler refinement, the runtime/FFI contract, and preservation of the claimed property under that refinement. Kernel checking alone proves neither VCG correctness nor executable preservation.

Coverage must include the executable dependency closure, generated code, effects, exceptions, and foreign interfaces covered by the selected policy. Bind every obligation to the exact program/contract/environment identity. Proof search and SMT-style discovery can be untrusted if their results are reconstructed as acceptable proof evidence. The trusted gate must not accept a solver’s unsupported success flag.

Distinguish partial correctness, safety, and total correctness in the PSCV profile. Total correctness additionally needs termination obligations and a suitable resource-qualified execution guarantee. Source-contract interpretation remains its own fidelity assumption.

### Prove stable contracts; test ordinary product behavior

Mechanize the logical foundation, checker/admission refinement, codec/bridge, runtime semantics, erasure, selected pass validators, reference backend, VCG, and small publication/isolation state-machine properties. Use integration/property/fuzz tests for protocol robustness, resource accounting, diagnostics, UX, and packaging.

Proofs about the supervisor should initially establish state transitions and exclusive authority. Refinement to its Node or later self-hosted implementation is a separate step. A state-machine proof does not prove Wasmtime or the OS secure. Keep those implementation/environment assumptions explicit.

Maintain one small machine-readable claim ledger linking each public theorem to its exact source/artifact/profile, exported axiom dependencies, quantified semantic assumptions, proof checkpoint, and test evidence. Do not report “percentage verified” from file counts. Schedule three bounded proof pilots—primitive identity/erasure, bridge correspondence, and one pass validator—at the later assurance milestone to measure proof effort and refactor sensitivity before projecting the full program. Earlier proof work is useful when it clarifies a contract, but completing those pilots is not an exit condition for architectural implementation.


### Proof layout: companion files outside the runtime closure

The inspected kernel already separates production `src/`, companion `proof/.../*.proof.lean`, and importable `metatheory/.../*.lean` sources. Its npm proof command builds `PsKernelCore` and `PsKernelCoreMetatheory`, then invokes a small runner that directly checks every companion with `lake env lean <file>`. Changed companions run first, followed by the rest; this is not changed-files-only validation. [R36] [R37] [R38]

Companions import actual production definitions. For example, `API/Kernel.proof.lean` imports `Ps.KernelCore.API.Kernel` and its judgments, and explicitly limits its local claims to API orchestration rather than all underlying checker semantics. That distinction should be preserved for the compiler. [R39]

Use the requested plural `proofs/` for the new compiler workspace. The following paths are proposed, not existing implementation:

| Purpose | Proposed path or mapping |
| --- | --- |
| Production module | `psc0/packages/<package>/src/<module>.lean` |
| Companion for that module | `psc0/proofs/<package>/<module>.proof.lean` |
| Example erasure implementation | `psc0/packages/pscore/src/Ps/Core/Erasure.lean` |
| Example erasure companion | `psc0/proofs/pscore/Ps/Core/Erasure.proof.lean` |
| Shared semantic models | `psc0/proofs/lib/Ps/CompilerProof/Semantics/*.lean` |
| Reusable refinement/composition lemmas | `psc0/proofs/lib/Ps/CompilerProof/Refinement/*.lean` |
| Cross-package transaction/isolation claims | `psc0/proofs/architecture/*.proof.lean` |
| Compiler-chain and bootstrap claims | `psc0/proofs/bootstrap/*.proof.lean` |
| Proof-only Lake project and dependency pins | `psc0/proofs/lakefile.lean`, `lean-toolchain`, and `lake-manifest.json` |
| Claim, theorem, and source mapping | `psc0/proofs/CLAIMS.json` |

Apply the companion mapping to `psfrontend`, `pscore`, `psbackend-ts`, and relevant `pscv` implementation modules. For the `psc` supervisor, proofs about Lean definitions may import those definitions; a Lean model of handwritten TypeScript or host IO still needs a separate implementation-refinement argument. A source path or a matching function name is not that argument.

Start with the existing direct-file runner pattern adapted to `proofs/`. Keep shared results in ordinary importable `.lean` modules under the distinct `Ps.CompilerProof` namespace. The `.proof.lean` suffix is a discovery convention; it does not automatically establish reusable module artifacts or independent proof replay. If later assurance requires compiled/exported companions, qualify their filename/module/output mapping and retain the exact proof artifacts. Do not introduce a new proof build framework merely to change filenames.

Each substantive theorem has one owner. A companion may reuse a shared theorem without copying its body. The ledger records intended semantic claims and named results; it does not require empty companions for every file or treat a wrapper lemma as full module correctness. Kernel assurance stays in its canonical source tree; integrating or renaming its existing singular `proof/` directory is a separate deliberate maintenance decision.

### Full Lean now; full PSCV as an optional proof-authoring route

Use the pinned host Lean toolchain to author and check compiler assurance proofs. Full Lean syntax, induction, tactics, metaprogramming, and useful proof libraries are permitted in this workspace. Mathlib may be added when it materially helps a proof; it is not a mandatory compiler dependency. This work does not wait for PSC0 to implement unrestricted Lean syntax or for full PSCV to exist.

When a full PSCV proof language is available, it may provide another authoring route to the same reviewed theorem statements and acceptable proof evidence. Its lowering/elaboration, proof terms, dependencies, checker, and assumption policy must be recorded. A future PSCV-to-Lean route is an option, not an already implemented capability or a required new translator now.

Keep authoring freedom separate from accepted evidence. The checking profile must audit the final theorem's transitive axioms and semantic premises. Incomplete proofs, arbitrary axioms, or native-evaluation assumptions cannot silently become unconditional assurance. Lean's validation guidance supports axiom inspection, replay, and stronger separation of proof construction from a trusted expected statement. The current companion runner's exit status alone is insufficient for this stronger claim. [E01] [R38]

Run proof construction outside the protected compiler supervisor and its publication capabilities. For untrusted contributions, isolate proof-authoring execution from the trusted rechecker and expected claims. Heavy tactics may search freely within that environment; acceptance still concerns the exact elaborated statement and evidence.

Initially, compiler assurance may be Lean-checked. Rechecking the same exported proof/dependency closure with PSKernel is a later corroboration milestone where the chosen kernel/profile supports it. A full Lean authoring environment does not guarantee full PSKernel compatibility. Do not require PSKernel to certify all compiler metaproofs before the architecture can be completed, and do not discard independent Lean checking when PSKernel rechecking becomes available.

### Keep assurance independent of self-hosting

The dependency direction is one-way: assurance modules import production modules and proof support; runtime production modules do not import the assurance tree or its tactic libraries. Bind imports to the exact source revision under examination, rebuilding those imports rather than accidentally using stale installed `Ps.*` artifacts. The current kernel's portable manifest names only `src` as its source root; the compiler should enforce its declared closure as well. [R40]

The ordinary compiler build, npm install, and C1/C2/C3 loop must not run compiler metaproofs or fetch proof-only dependencies. Proof-only changes must leave the production source-closure digest and emitted TS/JS unchanged for identical declared production inputs. Proof receipts and repository provenance may change independently. Publishing proof sources or checkable proof artifacts separately is optional.

This separation applies to external assurance theorems. A proof term or termination argument required to elaborate an implementation definition remains a real source dependency even if later erased. Keep such requirements within the accepted implementation profile or account for them in the closure; do not replace them with assumed lemmas to manufacture a smaller bootstrap.

The same distinction applies at runtime: a compilation may still need to check a user's proof, a PSCV obligation, or a transformation certificate. Those checks are part of the selected production policy. They are different from rebuilding the metatheory proving that PSC0's implementation is correct.

### Proof endpoints and remaining assumptions

Organize the later proof program by semantic boundary, using section 15's composition theorem. Its statements should reference the real implementation when possible and independently specified semantics when needed.

| Assurance result | Remaining boundary to state explicitly |
| --- | --- |
| Mathematical model and relative consistency of the logical foundation | Strength/consistency assumptions of the surrounding metatheory; this is separate from compiler correctness |
| PSKernel checker/admission refinement | Exact logical profile, environment invariant, permitted axioms/reductions, checker execution chain |
| Source-to-Core correspondence | Precisely supported language/extension semantics and source-contract interpretation |
| Erasure and RuntimeIR transformations | Observable effects, representations, evaluation/resource policy, and supported certificate relation |
| TS backend refinement | Specified TS output fragment/options, runtime/FFI contract, and execution through TS7/JS |
| PSCV VCG/coverage soundness | The same executable semantics, correct obligation association, and preservation of the claimed property |
| Supervisor transaction/isolation model | Refinement to the actual supervisor/codec/output operations; runner, OS, and host-binding assumptions |
| Whole compiler and bootstrap composition | Each instantiated pass relation, exact source/seed/artifact identities, and the remaining toolchain/runtime assumptions |

A theorem about a model needs a model-to-implementation relation. A theorem about imported Lean definitions still needs their execution through PSC0, `psbackend-ts`, TS7, and the JS runtime justified to certify the delivered executable. Target a narrow emitted TS fragment and explicit toolchain options; retaining TS7 as a stated external assumption is acceptable for an intermediate assurance result. Proving the entire TypeScript toolchain is not an architectural implementation prerequisite. [E02]

Implement directly provable small validators where practical and reuse their soundness theorems across changing untrusted search strategies. For partial, external, or effectful operations, state the behavior/termination assumptions or prove an appropriate operational refinement; importing a definition does not by itself expose every runtime behavior to Lean's logic. Do not maintain a second easier compiler and quietly transfer its theorem to the production compiler.

### Separate implementation completion from assurance qualification

**Architectural implementation is complete when phases 0–4 meet their functional, trust-boundary, packaging, and declared self-host requirements. Completing the compiler/architecture proof program is a later assurance gate.** Establish clear contracts, source/proof separation, and an honest obligation inventory during implementation; allow unfinished future proofs to remain planned.

| Gate | What must hold |
| --- | --- |
| Architectural implementation and ordinary release | Required admission/validation, isolation/disclosure, artifact binding, tests, packaging, and self-host qualification work; implementation assumptions are explicit |
| Later assurance qualification | The selected model/refinement/composition theorems check for the exact claimed revision/profile, with reviewed statement meanings and recorded assumptions |
| A build requesting a verified PSCV/executable profile | Every obligation promised by that profile is satisfied before successful publication; the request cannot silently downgrade because compiler assurance is unfinished |

Small validators may initially remain explicitly trusted implementations backed by meaningful tests. Their later soundness proofs reduce that assumption. The validator and its required checks still exist and run from the first implementation milestone; deferring the proof does not authorize accepting unsupported evidence.

Use `CLAIMS.json` for statuses such as `planned`, `in-progress`, `checked-under-assumptions`, and `stale`, with source modules/declarations, theorem names, scope, and dependencies. Generate or attach the exact source/proof/toolchain identities in checking receipts. A code change invalidates affected assurance claims until checked again; retain old evidence for its old revision. A broader ordinary release can proceed with explicit unproved assumptions, but a requested stronger verified profile must still refuse missing assurance. This policy changes the future milestone structure, not existing runtime gates or recorded historical qualifications.


## 17. Self-hosting and bootstrap strategy

Keep separate inventories for the compiler source closure, kernel source closure, supervisor, optional extensions, and external runtimes. Self-hosting the compiler does not require reimplementing Node, the OS, npm, Wasmtime, or every third-party package.

The existing successful fixed point is compiler-only, using TS7 to obtain executable JS. Preserve the selected R seed, F evidence, exact toolchain, and cold recovery while restructuring interfaces. Changing package layout must not silently promote F or discard the last reproducible seed. [R02] [R03] [R04]

Use a two-step language expansion when bootstrapping: an older accepted compiler first builds a successor that understands a new construct; only then may compiler source start using that construct. Keep the active .ps profile and .lean subset explicit. Do not assume full Lean syntax/metaprogram support because the compiler is authored in Lean.

### TypeScript is the required self-host backend

Keep psbackend-ts in the required compiler distribution and declared self-host source closure. Keep pscore backend-neutral and pskernel-core independent of target lowering. This separation allows a small semantic core while preserving a complete required compilation path.

Compiler implementation remains in the accepted .lean/.ps source profile. The compiler emits TypeScript; the pinned TS7 toolchain produces the executable JavaScript stages. TypeScript is an external target toolchain dependency, not a replacement implementation language or a new logical rule.

```text
C0(compiler source) -> compiler1.ts -> TS7 -> C1.js
C1(compiler source) -> compiler2.ts -> TS7 -> C2.js
C2(compiler source) -> compiler3.ts -> TS7 -> C3.js
```

Qualify the exact declared products, including the canonical source/admissions and C2/C3 TypeScript/JavaScript equality, and preserve declared-seed cold recovery. Keeping an external TypeScript compiler is compatible with compiler self-hosting; independence from that toolchain and executable correctness are separate guarantees.

The existing demonstrated closure is compiler-only. A joint compiler-plus-kernel source closure remains a separate milestone, now explicitly using the same required TS7 path. The plan must not imply that the native kernel provider used in current evidence already demonstrates generated-kernel self-hosting. Proof sources and the supervisor/runtime also have separately declared scopes.

### Tool delivery does not determine the compiler source closure

The npm installation graph and self-host import graph are different. `proofscript` may ship `psdev` and `pslsp` without compiler/kernel source importing them. Keep Node/OS/editor adapters, watch policy, LSP sessions, and the VS Code client outside the minimal compiler manifest. Tooling consumes compiler/supervisor services; the compiler has no reverse dependency on tooling.

A tooling-only change with unchanged compiler inputs/closure needs its affected integration checks and a closure-identity check, not an automatic complete C1/C2/C3 run. Build/reproduce the minimal compiler with tool packages omitted from the bootstrap inputs to demonstrate this separation.

This is not a promise that module-output work cannot affect self-hosting. Adding export ownership, shared-runtime linking, an ABI, or compiler query APIs can change the compiler itself. Develop those changes within the accepted source profile and requalify the changed closure at a coherent checkpoint, preserving the selected seed. Only subsequent independent tooling changes inherit the unchanged compiler baseline.

Full compiler/architecture proofs in `psc0/proofs/` remain a later assurance gate. Required proof/contract evidence for a user's selected program build is a separate runtime acceptance requirement; excluding metatheory from bootstrap never authorizes bypassing it.

### Direct JS and other backends remain optional

Reuse the integration branch's JS/Wasm/Rust work where useful as psbackend-js, psbackend-wasm, and psbackend-rust extensions. Each backend needs its own target contract and evidence appropriate to the requested assurance profile. It must not add dependencies or qualification work to the required TS self-host path.

There is no planned retirement of TS7 in favor of direct JS. A direct-JS self-host experiment may be qualified independently if useful, without replacing or weakening the selected TS baseline.

Stage-two/stage-three equality proves a reproducibility property of those runs, not semantic correctness or absence of a compromised seed. A stronger bootstrap theorem connects each compilation stage with the language semantics; diverse independent validation can improve seed confidence without replacing that theorem. CakeML’s verified bootstrap is the relevant long-term model. [E03]

### Fast development without weakening final gates

Do not run the entire multi-generation qualification after every small edit. Use source-profile/import checks, affected-unit behavior tests, and certificate validation during development. Recompile affected existing proofs in the separate assurance job when relevant; missing future compiler/architecture proofs do not block ordinary implementation progress. Run complete fixed-point, provider, cold-recovery, and publication gates at a coherent promotion checkpoint.

Measure preparation, encoding, erasure, validation, emission, runtime compilation, peak memory, and warm edit latency independently. Prioritize repeated preparation and encoding before adopting a new caching framework or promising a large speedup from direct JS.

For AI-assisted work, optimize for local interfaces, explicit invariants, and a compact source map. Evaluate representative tasks—a new macro, tactic, certified rewrite, primitive/backend extension, and structural refactor—by files touched, context required, time to first passing check, and proofs invalidated. Improved AI efficiency is a design hypothesis to measure, not an already demonstrated numerical benefit.


## 18. Migration plan and estimated changes

These are planning envelopes, not measured implementation requirements or delivery commitments. Preserve ongoing strict/proof work and integrate it rather than counting it as a new rewrite.

| Phase | Concrete work | Exit condition |
| --- | --- | --- |
| 0. Freeze and reconcile | Record R/F/main identities; resolve provider naming; select canonical kernel source and proof checkpoint; repair current qualification blockers | One unambiguous source/artifact/profile mapping; preserved recovery baseline |
| 1. Own the transaction | Unify default build, kernel admission, IR/target checks, owned preparation, exact output publication; rename weak APIs | Every production entry has the same non-bypassable gate |
| 2. One isolated extension slice | Data-only descriptors and root project activation, constrained Wasm runner, limits, actual-load reporting, three complete examples | Official and independently named extensions use the same boundary; external code cannot obtain admission, provider, reporting, or final-output authority |
| 3. Stabilize contracts | Primitive identities, canonical bridge, narrow SDK, deterministic syntax dispatch; only supported rewrite certificates | Supported extension changes require no trusted-core source changes |
| 4. Package and requalify | proofscript package and psc bin, minimal release-controlled tarball, project-local workflow, library imports, clean-install tests, cold recovery and complete new C1/C2/C3 checkpoint | Global quick-start and locked project builds work; isolated examples and ordinary libraries are usable without a repository checkout |
| 5. Later formal assurance | Reuse kernel admission/model work; develop bridge/erasure/pass pilots, architecture refinement, PSCV and reference-backend proofs | Independently scoped claims promoted only when their exact obligations are discharged; not required to close phases 0–4 |
| 6. Optional backend ecosystem | Reuse/evaluate direct JS, Wasm, Rust and other backends through extension contracts | Individually qualified optional targets; TS7 remains the required reference/self-host path |

Phases 0–4 are the minimum protected platform and define completion of the architecture implementation. Set up the separate proof workspace, semantic contracts, and obligation inventory while stabilizing those interfaces; unfinished compiler/architecture proofs are not their closing gate. Phase 5 is a later formal-assurance program with its own budget and scoped checkpoints. Nonblocking research may run earlier, but completing the full formal program is not a prerequisite for npm packaging or the ordinary self-host release.

Keep the existing canonical kernel proof work and its exact claims; avoid unrelated proof-tree churn during compiler restructuring. Joint compiler/kernel qualification through TS7 is a separate explicit closure milestone. Phase 6 is optional, independently costed, and not a prerequisite for the core release or self-hosting.

### Engineering envelope for phases 0–4

| Component | New production lines, estimate |
| --- | --- |
| Kernel/toolchain identity and baseline | 200–500 |
| Supervisor transaction and publication | 900–1,800 |
| Constrained extension runner/protocol | 1,200–2,500 |
| Contracts, primitive identity, narrow SDK | 800–1,700 |
| Packaging and qualification integration | 500–1,000 |
| Approximate total | 3,600–7,500; budget 4–8k |

The minimum platform also entails roughly 3–7k existing lines edited or moved and 2–4k focused regression/CI lines. These categories must not be added together as if moves were new implementation. Confidence is low to medium until one complete extension transaction has been built and measured.

Broader extension ergonomics and capability coverage could reach 9–18k total new production lines, 10–20k existing lines touched/moved, and 4–10k regression/CI lines. Those are broader totals, not additions to the minimum. Do not approve that larger scope automatically.

Potential deletion of 2–5k current lines is plausible but not a commitment. Historical receipts, source restrictions, and recovery evidence should usually remain in Git even when absent from release packages. The credible first objective is fewer maintained authority paths and less shipped duplication.

These estimates exclude complete mechanized proofs, a new Wasm compiler, full Lean compatibility, a portable native-worker sandbox, the neighboring-module/interop and development-tooling workstream below, an online plugin marketplace/approval service, and external runtime binary/dependency size. The approximately 80.9k existing assurance lines already demonstrate why proof work deserves its own budget.


### Independent incremental-adoption workstream

This can proceed after the corresponding phase-1/phase-3 interfaces stabilize and does not depend on completing phase 5. It is additional product scope, not a new closing gate for the minimal architecture release.

| Milestone | Smallest useful change | Qualification boundary |
| --- | --- | --- |
| T1. TS library adoption | Accepted export map, one project bundle, thin neighboring modules, narrow checked ABI, one-shot build ordering | Cross-file datatype identity, initialization and calling behavior; qualified TS settings; changed compiler closure |
| T2. psdev | Repeated checked transaction, ownership/generation state, conservative invalidation, explicit downstream sequencing | Failed/stale/cancelled work cannot become current; crash and collision cases; no new kernel path |
| T3. pslsp and editor client | Saved/unsaved snapshot separation, diagnostics/hover/definition, mappings, thin VS Code client | Protocol-safe reporting, local compiler identity, incomplete-code analysis cannot publish |
| T4. True module emission and richer tooling | Ownership/import/export preservation, shared versioned runtime, additional ABI/FFI and editor features where useful | Explicit linking/initialization semantics and assurance scope; deliberate compiler requalification |

Develop these as independently releasable tooling/source modules. Add a finished optional tool to the product's required payload/dependency closure and release defaults only after its integration gate passes. A default `psdev` release need not include a language server or optional backend. Measure installed bytes, cold startup, warm-edit latency, affected source files, and proof maintenance before expanding the default set.

### T1 proof obligations retained for later assurance

The implemented boundary profile is deliberately smaller than the source language. It admits selected pure functions and monomorphic opaque datatypes, checks original RuntimeIR, and refuses unsupported public signatures. Its runtime guards establish a bounded foreign-value representation boundary; they do not prove the source specification, total correctness, semantic preservation of the generated implementation, or correctness of a downstream TypeScript project.

Keep the first assurance units aligned with the production seams rather than creating a parallel compiler in the proof tree:

| Obligation | Production seam and intended claim | Suggested companion location |
| --- | --- | --- |
| Declaration ownership and public selection | Project preparation retains source ownership through elaboration; selected exports denote exactly the authored declarations owned by that source. Compiler-generated workers cannot enter the public interface merely by name. | `proofs/psfrontend/ProjectOwnership.proof.lean` |
| Checked emission correspondence | The public descriptor and emitted implementation refer to the same prepared declaration graph, checked original IR and erasure name map. Checked admission cannot be substituted by a caller-created flag or unrelated payload. Model the JS supervisor separately where the implementation is not importable Lean. | `proofs/architecture/CheckedProject.proof.lean` |
| Runtime name hygiene | The project source namespace remains disjoint from backend helper names and injected intrinsic references; construction, projection and matching use the same field/constructor mapping. The legacy empty-prefix route needs its own scope and is not automatically covered. | `proofs/pscore/RuntimeNames.proof.lean` |
| Public ABI refinement | For every supported type, accepted foreign values decode to the intended source representation and successful results encode back correctly. Nat is nonnegative bigint; String excludes isolated UTF-16 surrogates; Unit is undefined; opaque handles retain identity within their one bundle and reject foreign/forged handles. State assumptions about standard JS intrinsics and module evaluation. | `proofs/psbackend-ts/PublicABI.proof.lean` |
| Bundle and facade correspondence | Every facade refers to the selected binding in the same bundle, with no duplicated runtime datatype identity. Static Core/IR signature agreement and exact authored arity justify the accepted wrapper shape. | `proofs/psbackend-ts/ProjectEmission.proof.lean` |
| Completed-generation ownership | Under the stated filesystem/concurrency model, a completion receipt identifies the exact source/configuration and every published artifact; failed or stale work cannot acquire that receipt, and rollback only changes still-owned bytes. Multi-file visibility is not atomic, and arbitrary same-user filesystem interference is outside the current guarantee. | `proofs/architecture/Publication.proof.lean` |
| Executable and bootstrap refinement | Connect source semantics to erasure, RuntimeIR, emitted TS, TS7-produced JS and the chosen runtime. A reproduced C2/C3 fixed point is evidence about those exact artifacts, not this refinement theorem or a logical-consistency proof. | `proofs/bootstrap/CompilerChain.proof.lean` |

These are proposed theorem scopes, not new checked results or newly created proof files. Reuse ordinary model/lemma modules and the existing direct-file companion runner. Full Lean tactics and later full PSCV proof authoring stay outside the compiler's bootstrap closure. Formal assurance remains a later gate for stronger claims; admission, supported-profile validation, exact artifact selection and truthful reporting remain immediate implementation gates.

Do the T1 ownership/ABI pilot before estimating T2–T4 line counts or promising support for arbitrary TS frameworks. Reuse the existing transaction and compiler services; budget no separate parser, kernel, proof database, generic service registry, or package manager. Broad FFI, arbitrary module cycles, and universal bundler/debugger compatibility are independently scoped future work.

## 19. Acceptance criteria

Apply the implementation gates to the protected platform and the selected build policy. The formal-assurance gate applies when promoting the corresponding proof claim; unfinished future theorems do not block completion of phases 0–4. A profile promising verified execution remains accountable for its full advertised scope.

| Gate | Measurable requirement |
| --- | --- |
| Kernel identity | Every accepted result identifies exact source, proof checkpoint, artifact digest, runtime, logical profile and assumptions; legacy selectors cannot silently replace it |
| Admission ownership | Forged checked flags, caller-built environments, provider records, unauthorized axioms and native evaluators cannot enter authoritative state |
| Production publication | Every public build route checks exact admissions and full original IR; failure/cancellation at any required stage produces no newly successful published result |
| Primitive correspondence | The current name-shadowing cases are refused or bound to the correct admitted primitive identity; runtime conformance covers demand, bounds and string representations |
| Transformation claims | A well-typed behavior-changing rewrite such as identity-to-zero cannot pass a preservation gate merely through IR typing |
| Extension confinement | Adversarial fixtures cannot access denied files/network/process APIs, other guest memory, checker state, final paths or the official output stream; resource limits preserve the supervisor |
| Disclosure | Every attempted/executed extension is recorded before execution; crashes and cache reuse retain relevant identities; guest output cannot suppress or impersonate the official report |
| Artifact/cache binding | Swapped target bytes, changed environments/profiles, incomplete decodes and forged cache acceptance are rejected or revalidated |
| PSCV | Missing required VCs, wrong goal associations, incomplete dependency/effect coverage and unavailable required VCG block the promised verified executable |
| Self-hosting | Preserve selected R; qualify exact source closure and C2/C3 equality for the declared products; cold recovery uses only declared inputs/toolchains |
| Proof/runtime separation | Runtime imports and self-host inventories exclude compiler assurance modules and proof-only dependencies; a proof-only edit preserves production closure/output identities for fixed production inputs |
| Formal claims — later assurance gate | The promised theorem set checks at the referenced source; exported axiom dependencies and quantified semantic assumptions are audited; no claim is promoted by test coverage or companion-file counts alone |
| npm product and project workflow | On qualified platforms, global installation of proofscript exposes psc; exact local installation plus committed lockfile reproduces the selected compiler/extension versions; controlled CI requires no extension lifecycle execution and cannot be redirected by dependency bins named psc or node |
| Open extension activation | An independently named conforming extension works without a central allowlist; an installed but disabled extension never executes; new transitive operations/grants and conflicting registrations are refused |
| Release defaults | A qualified product install provides all required components and chosen default tools; version/check operations do not start watch/LSP work; project dependencies cannot impersonate defaults; optional disabling and mandatory disclosure work |
| Ordinary libraries | A supported third-party source/proof library imports without plugin approval; its assumptions are checked, and embedded executable hooks cannot activate through a normal import |
| Backend claim scope | Installing/selecting Rust adds only its permitted target operation; unsupported toolchains fail clearly and missing preservation evidence cannot satisfy a stronger verified profile |
| Cost and usability | Clean npm install runs checked builds and examples; no optional backend enters the mandatory closure; compare latency, memory, tarball size and dependencies to a measured baseline |

Run failure-injection tests at each transaction boundary, including backend crash, receipt write failure, malformed guest responses, timeout, and a changed byte buffer after validation. Test actual denied operations; a manifest saying “sandboxed” is not a test.

For performance, use repeated measurements on the same runner and workload. A provisional no-more-than-20% median regression budget without an accepted explanation is a reviewable planning gate, not a current performance result. Record warm edits and peak memory as well as full generations.

For extension ergonomics, require the example macro, tactic, and command to be implemented through the documented SDK only. Kernel and supervisor source should not need per-extension changes. Later optimizer/backend examples must demonstrate the exact evidence they support rather than an unsupported generic verified label.

### Additional gates when incremental TS/tooling features ship

| Gate | Measurable requirement |
| --- | --- |
| Neighboring TS interoperability | An existing TS application imports two generated neighbors; a shared PS datatype crosses their boundary with one type/runtime identity and qualified calling/initialization behavior |
| Contract profile | Missing, rejected, timed-out, or incomplete required obligations block the matching publication; foreign assumptions and unproved compiler relations remain explicit |
| Watch identity and races | Delay older prover/backend tasks and edit during checking/staging/publication; superseded results cannot publish as current or clear newer diagnostics |
| Semantic invalidation | Imported body/contract/assumption/extension changes invalidate dependent acceptance even when the exported TS type is unchanged |
| Stale output and consumption | Strict invalidation withdraws owned outputs; failed checks block coordinated builds; a downstream consumer sees a completed generation; independent-watch limits are documented |
| File ownership and recovery | Handwritten/modified TS survives; rename/delete, case/symlink collisions, competing writers, interrupted publication, and watcher rescan behave predictably |
| ABI | Invalid incoming values and mutable-alias cases obey the supported boundary policy; unsupported foreign contracts cannot silently acquire proof status |
| Editor isolation | Unsaved diagnostics carry versions and cannot emit files; LSP stdout remains valid protocol; disclosure survives errors; full-Lean proof companions retain their chosen editor route |
| Tooling/bootstrap independence | The minimal compiler reproduces without psdev/pslsp/editor inputs; tooling-only edits preserve its closure identity; compiler module/ABI changes receive appropriate requalification |

### Definition of the first successful release

A clean npm installation of `proofscript` exposes `psc`, builds the declared bounded language through one checked publication transaction, selects an unambiguous kernel artifact, reports actual extension identities, imports supported ordinary libraries, runs explicitly activated official and third-party examples without privileged access, and reproduces its selected compiler closure. It states the remaining source-fidelity, semantic-preservation, model, runtime, and bootstrap assumptions precisely.

This is a complete architectural implementation milestone even while the later proof program remains unfinished. The obligation inventory can contain planned or in-progress proofs, and ordinary npm/self-host qualification does not need to execute that proof program. It must not be marketed as a fully verified compiler simply because its kernel accepts proof terms or its compiler reaches a fixed point.


## 20. Risks and decisions to keep explicit

### Highest risks

**Proof scope mismatch.** An operational theorem may be mistaken for foundation soundness, a typed IR for preservation, or a receipt for a certificate. Mitigation: a claim ledger with exact subjects, assumptions, and theorem meanings.

**Kernel reconciliation drift.** Multiple source copies, active branches, provider artifacts, and proof checkpoints can continue evolving independently. Mitigation: one maintained source, deliberate integration ownership, immutable artifact provenance, and exact cross-lane comparison before promotion.

**Supervisor growth.** Policy, caching, package loading, CLI commands, and compatibility runners could become a second large compiler. Mitigation: bounded data operations, one transaction, internal modules instead of a service bus, and defer capabilities without a concrete consumer.

**Isolation compatibility pressure.** Users will want arbitrary npm JS and native Lean macros. Mitigation: supported modes with no silent downgrade; strict Wasm first, platform-qualified native compatibility later.

**Overpromising validators.** Semantic equivalence is harder than IR well-formedness. Mitigation: a proved/reference path and restricted certificate families; refused evidence stays refused.

**Bootstrap disruption.** Introducing unsupported source constructs or promoting a new backend too early can lose reproducibility. Mitigation: preserve R, stage language changes, keep one mandatory target, and separate compiler-only from joint-kernel claims.

**Incremental-adoption overclaim.** Neighboring files can hide stale or mixed generations, duplicated runtime identities, or unchecked TS callers. Mitigation: accepted export ownership, one qualified runtime identity, a bounded ABI, snapshot receipts and coordinated consumption; qualify real module emission separately.

**Resource and runtime mismatch.** Demand, string positions, arrays, exceptions, and stack behavior can invalidate proofs about source programs. Mitigation: a finite runtime specification, primitive identities, conformance, and refinement obligations grounded in that specification.

### Deliberate architectural decisions

- No whole-compiler rewrite as the default migration strategy.
- No arbitrary same-process third-party JavaScript execution.
- Open third-party participation through documented isolated interfaces; an official catalog is optional and never replaces kernel/validator checks.
- One user-facing `proofscript` product and `psc` command, with release-owned lazy defaults, explicit project additions, and ordinary library imports.
- Incremental TS adoption through owned neighboring outputs and a bounded ABI; watch and editor tools remain outside compiler bootstrap dependencies.
- No general compiler framework, extensible trusted IR, or universal equivalence validator.
- No mandatory full-Lean frontend or four-backend bootstrap.
- No verification claim inferred from a filename, type wrapper, manifest, hash fixed point, or finite suite.
- No forced mathematical model for routine UI, package UX, or every plugin search algorithm.
- No full compiler/architecture proof requirement for closing architectural implementation; stronger assurance has separate, explicit gates.
- No proof-library dependency silently added to the runtime/self-host closure, and no stale proof result silently applied to changed code.

The architecture should make each future change answer a small set of questions: what data does it consume, what data/evidence does it produce, which semantics or invariant does it preserve, which capabilities does it need, and which existing theorem/checker establishes acceptance? When a feature needs a new trusted rule, that should be obvious and rare.

The recommended next implementation unit is phase 0 plus one end-to-end phase-1 transaction. It will make the current checking work authoritative, expose the real size of the host boundary, and create a stable place to attach the first isolated extension. It preserves valuable work while correcting the architecture’s root problem.


## Appendix A. Reproducibility identities

| Identity | Full value |
| --- | --- |
| main | ed5d00aca0743bde583b45fe7756dd494ac3960f |
| strict SH/1 | d6b7044258efaa272dcf396ce08b0c10496edcd2 |
| integration | cae6b6d5fb3d50138889e1aeb74436e7b5ea5316 |
| proof HEAD | 64499d5db307a4d5548bc70c6b46fc32cc0cda94 |
| last green proof | 11005632c14932f08b01a7b388a3999d181f683b |
| F source | fcd875c8f38db4b0524090bd10c7c2fd5024053d |
| selected R source | fe2560aba0f347b1caf8d000d371464642d44f23 |
| F native provider source | 963030dc2d154008fccc82e7c8ed29331f138799 |
| main/strict/integration kernel src/Ps tree | ef1f8b757b1a22c3dfde3313ca3069cf96821d00 |
| proof HEAD / green checkpoint kernel src/Ps tree | e5ce6c7d055ecbbea5b05b70df2f5ea4b7925ae5 |
| F source closure SHA-256 | 6306cdac131f849a9a96de3dc4d628a48b953072b45fc6cc829075bd90b67ac7 |
| F final JavaScript SHA-256 | 5eeecb1bfa00f11f1691f5ee4b437ecebe5c9a45b4e4256ab1bde23b0771df15 |
| F native provider binary SHA-256 | 88f2d20ea733742d48724ecbdc903271e18bcfcccc8682be596a676aef68e3ec |

The compiler source count excludes the kernel. The common src/Ps tree comparison excludes separately evolving proofs and packaging. Identical production Git trees do not imply identical full branch content, successful current proof elaboration, or identical runtime binaries. The native provider identity comes from the F evidence, not from the similarly named default CLI selector. [R02] [R03] [C01] [C05]

The integration cloud failure observed at the reviewed HEAD is a Node file-URL/path invocation problem before later semantic jobs. Portable/provider lanes passed separately. The proof HEAD failure is a mutual-continuation elaboration problem with unchanged production source. These are actionable gate failures, but neither supports a claim that skipped compiler tests semantically failed. [C04] [C05] [C06]

## Source register

Repository sources are pinned to the inspected commits. Workflow links identify specific runs. External sources are primary documentation or research. R36–R40 are the later proof-organization inspection at `85ccb4e1103d77ed77c09c5795fc48ae4ea8ea62`. R41–R44 are the targeted neighboring-output/interop inspection at `3fbf7f778ab20aaeaafe87ae07b04c00ab2d29f7`. Neither follow-up updates the original audit's CI/theorem-completion claims.

### Repository sources

- **[R01] - Main PSC0 work state.** Main snapshot; read historical entries in chronological context.
- **[R02] - F compiler qualification receipt.** Exact closure, output comparisons, IR traversal, and explicit claim limits.
- **[R03] - F provider receipt.** Provider checks occurred after emission.
- **[R04] - Selected R cold TS7 recovery.** Reproducibility evidence and provider-check limitation.
- **[R05] - Compiler API.** Check aliases prepare; preparation and erasure paths.
- **[R06] - TS backend compiler adapter.** Public adapter calls raw emitter.
- **[R07] - Checked prepared session.** Deep freeze, session ownership, exact re-encoding; no hostile-code sandbox.
- **[R08] - Default CLI.** Build routing; see compile-with-generated.mjs in the same snapshot.
- **[R09] - Generated compile driver.** Default prepare/emission route.
- **[R10] - Kernel selector identity.** Legacy generated checker versus distinct native provider.
- **[R11] - Legacy checker BUILD manifest.** Experimental identity and canCheckProofs:false.
- **[R12] - Closed syntax AST.** Current term/declaration constructors.
- **[R13] - Runtime IR model.** Constructible records and raw VerifiedIr naming.
- **[R14] - Primitive erasure dispatch.** Name-driven runtime operations.
- **[R15] - Primitive type erasure.** Includes String.Pos.Raw treatment.
- **[R16] - Strict primitive identity audit.** 43 operation spellings; five absent identities and Raw type.
- **[R17] - Strict atomic source-to-emission path.** Same-IR checking and explicitly false qualification fields.
- **[R18] - Strict preservation obligation ledger.** 33 open general-preservation rules.
- **[R19] - Strict current work state.** Current candidate, superseding older failures.
- **[R20] - Preparation session reuse.** Bounded parsed-source cache and prefix checkpoints.
- **[R21] - Source-shape guard example.** Exact implementation-pattern coupling.
- **[R22] - Integration Wasm lowering.** Hidden specialization inside target lowering.
- **[R23] - Concrete checker composition theorem.** Concrete knot; named native-reduction and string-comparison laws.
- **[R24] - Ordinary inductive transaction refinement.** Actual-source transaction theorem; closure scope remains qualified.
- **[R25] - Mutual recursor transaction frontier.** Successful build/validation equalities remain explicit premises.
- **[R26] - Independent algorithmic judgments.** Algorithmic conversion and recursorKConversion frontier.
- **[R27] - Native reduction law.** External evaluator must justify reductions.
- **[R28] - Public kernel API.** Axioms, admission, receipt counts, and rechecking checked requests.
- **[R29] - Public kernel session.** Low-level environment construction is a trusted integration boundary.
- **[R30] - Current checker cache scope restoration.** Scope-local caches cannot escape into parent context.
- **[R31] - Semantic audit.** Newest header supersedes older frontier descriptions.
- **[R32] - Specified-string obligations.** Reflexivity and generated-name results; positive comparison law remains.
- **[R33] - Proof runner.** Compilation exit status is not a comprehensive axiom gate.
- **[R34] - PSC0 package manifest.** Private workspace; current script inventory.
- **[R35] - Arena work state.** Native evidence and unfinished corpus scope.
- **[R36] - Proof workspace npm command, follow-up.** Builds production/metatheory libraries before direct companion checks.
- **[R37] - Proof library boundaries, follow-up.** Separate Lake source roots for production and reusable metatheory.
- **[R38] - Companion proof runner, follow-up.** Direct `.proof.lean` checks, changed-first ordering, and full sweep.
- **[R39] - Production-bound API companion, follow-up.** Actual implementation imports and explicitly limited orchestration claims.
- **[R40] - Kernel production source roots, follow-up.** Portable package manifest names `src`; assurance sources are separate.
- **[R41] - TS whole-module emitter/runtime, tooling follow-up.** Complete layouts/declarations, embedded runtime, private symbol identities and generator registry.
- **[R42] - Compiler preparation, tooling follow-up.** Accumulated declarations and admission-ready preparation result.
- **[R43] - IR module shape, tooling follow-up.** Imports, layouts and declarations; no source-ownership/export graph.
- **[R44] - TS erased representations, tooling follow-up.** Numeric, character/string and unit target types.

### Workflow evidence

- **[C01] - Successful F qualification.** Compiler job 113876931430; provider job 113896228512; timing source.
- **[C02] - Successful selected R recovery.** Cold declared-toolchain recovery.
- **[C03] - Latest strict candidate failure.** Job 113946142567: TS2367 in conformance fixture; later fixed point not reached.
- **[C04] - Latest proof run #840.** Mutual continuation proof elaboration failure; portable erasure passes.
- **[C05] - Last fully green proof run #836.** Production kernel source tree equals latest proof HEAD.
- **[C06] - Integration self-host workflow.** Node file-URL/path error; later semantic tests skipped.
- **[C07] - Arena tutorial.** 141/141 native cases.
- **[C08] - Arena historical corpus.** 17 correct, one declined.
- **[C09] - Arena Init/Std.** Timeouts, not full acceptance.

### External research

- **[E01] - Lean: Validating a Lean Proof.** Proof checking, statement interpretation, sandboxed elaboration, exported recheck.
- **[E02] - Lean FAQ.** Executable TCB and arbitrary build-time dependency code.
- **[E03] - CakeML project.** Formal semantics and verified compiler/bootstrap.
- **[E04] - CakeML verified compiler, ICFP 2016.** Semantic passes, resource outcomes, allocation validation.
- **[E05] - CompCert verified register allocation.** Untrusted allocation oracle with a dedicated validator.
- **[E06] - CompCert documentation.** Per-pass proofs and compiler composition.
- **[E07] - Candle verified prover.** Machine-level theorem guarantee and kernel-controlled output channel.
- **[E08] - Wasmtime security.** Isolation, imports, capabilities, and output sanitation.
- **[E09] - Node.js vm.** Explicitly not a security mechanism.
- **[E10] - Node.js permission model.** No malicious-code security guarantee.
- **[E11] - npm configuration.** Explicit ignore-scripts policy and npm run exception.
- **[E12] - MLIR dialect conversion.** Explicit legality and partial/full conversion distinction.
- **[E13] - Harrison: Towards self-verification of HOL Light.** Relative model assumptions; not a model of PSC0's exact logic.
- **[E14] - MetaRocq.** Separable checker, erasure, and compilation proof boundaries.
- **[E15] - Verifying a VC generator and compiler for a Dafny subset.** Shared program semantics across VCG and verified compilation; bounded subset.
- **[E16] - npm package.json.** Package/bin name mapping, local binaries, and published-file behavior.
- **[E17] - npm scopes.** Scoped package spelling and user/organization namespace ownership.
- **[E18] - TypeScript installation guidance.** Global convenience and per-project reproducibility.
- **[E19] - npm run.** Local dependency executables and script invocation behavior.
- **[E20] - npm ci.** Locked project installation and manifest/lockfile consistency.
- **[E21] - npm package-lock.json.** Project lockfile semantics and npm v12 shrinkwrap behavior.
- **[E22] - ESLint plugin configuration.** Explicit extension configuration, including local unpublished plugins.
- **[E23] - TypeScript 7.0 announcement.** No programmatic compiler API in 7.0; separately evolving integration boundary.
- **[E24] - TypeScript Compiler API wiki.** Examples explicitly target TS6-and-earlier APIs.
- **[E25] - TypeScript sourceMap.** JavaScript-to-TypeScript mapping behavior.
- **[E26] - VS Code language-server extension guide.** Server/client architecture and LSP reuse.
- **[E27] - TypeScript noEmitOnError.** TypeScript diagnostic-based emission policy, not proof checking.
- **[E28] - VS Code extension publication.** Marketplace and VSIX distribution.
- **[E29] - VS Code Workspace Trust extension guide.** Workspace-sensitive editor execution.

[R01]: https://github.com/dwijayuda/pskernel/blob/ed5d00aca0743bde583b45fe7756dd494ac3960f/psc0/AI_WORK_STATE.md
[R02]: https://github.com/dwijayuda/pskernel/blob/ed5d00aca0743bde583b45fe7756dd494ac3960f/psc0/docs/selfhost-language/worker-migration-qualification.json
[R03]: https://github.com/dwijayuda/pskernel/blob/ed5d00aca0743bde583b45fe7756dd494ac3960f/psc0/docs/selfhost-language/worker-migration-provider.json
[R04]: https://github.com/dwijayuda/pskernel/blob/ed5d00aca0743bde583b45fe7756dd494ac3960f/psc0/docs/selfhost-language/typescript7-native-recovery.json
[R05]: https://github.com/dwijayuda/pskernel/blob/ed5d00aca0743bde583b45fe7756dd494ac3960f/psc0/packages/compiler/src/Ps/Compiler/Api.lean
[R06]: https://github.com/dwijayuda/pskernel/blob/ed5d00aca0743bde583b45fe7756dd494ac3960f/psc0/packages/backend-ts/src/Ps/BackendTs/Compiler.lean
[R07]: https://github.com/dwijayuda/pskernel/blob/ed5d00aca0743bde583b45fe7756dd494ac3960f/psc0/scripts/checked-prepared-session.mjs
[R08]: https://github.com/dwijayuda/pskernel/blob/ed5d00aca0743bde583b45fe7756dd494ac3960f/psc0/packages/cli/bin/psc.mjs
[R09]: https://github.com/dwijayuda/pskernel/blob/ed5d00aca0743bde583b45fe7756dd494ac3960f/psc0/scripts/compile-with-generated.mjs
[R10]: https://github.com/dwijayuda/pskernel/blob/ed5d00aca0743bde583b45fe7756dd494ac3960f/psc0/scripts/checked-kernel-identity.mjs
[R11]: https://github.com/dwijayuda/pskernel/blob/ed5d00aca0743bde583b45fe7756dd494ac3960f/legacy/packages/pskernel-core/manifests/BUILD.json
[R12]: https://github.com/dwijayuda/pskernel/blob/ed5d00aca0743bde583b45fe7756dd494ac3960f/psc0/packages/syntax/src/Ps/Syntax/Ast.lean
[R13]: https://github.com/dwijayuda/pskernel/blob/ed5d00aca0743bde583b45fe7756dd494ac3960f/psc0/packages/compiler-ir/src/Ps/CompilerIr/Model.lean
[R14]: https://github.com/dwijayuda/pskernel/blob/ed5d00aca0743bde583b45fe7756dd494ac3960f/psc0/packages/erasure/src/Ps/Erasure/Expr.lean
[R15]: https://github.com/dwijayuda/pskernel/blob/ed5d00aca0743bde583b45fe7756dd494ac3960f/psc0/packages/erasure/src/Ps/Erasure/Basic.lean
[R16]: https://github.com/dwijayuda/pskernel/blob/d6b7044258efaa272dcf396ce08b0c10496edcd2/psc0/docs/selfhost-language/strict/PRIMITIVE_IDENTITY.md
[R17]: https://github.com/dwijayuda/pskernel/blob/d6b7044258efaa272dcf396ce08b0c10496edcd2/psc0/packages/backend-ts/src/Ps/BackendTs/Sh1.lean
[R18]: https://github.com/dwijayuda/pskernel/blob/d6b7044258efaa272dcf396ce08b0c10496edcd2/psc0/docs/selfhost-language/strict/correspondence-obligations.json
[R19]: https://github.com/dwijayuda/pskernel/blob/d6b7044258efaa272dcf396ce08b0c10496edcd2/psc0/AI_WORK_STATE.md
[R20]: https://github.com/dwijayuda/pskernel/blob/ed5d00aca0743bde583b45fe7756dd494ac3960f/psc0/scripts/generated-preparation-session.mjs
[R21]: https://github.com/dwijayuda/pskernel/blob/ed5d00aca0743bde583b45fe7756dd494ac3960f/psc0/scripts/check-elab-declarations-selfhost-source-syntax.mjs
[R22]: https://github.com/dwijayuda/pskernel/blob/cae6b6d5fb3d50138889e1aeb74436e7b5ea5316/psc15selfhost/packages/backend-wasm/src/Ps/BackendWasm/Lower.lean
[R23]: https://github.com/dwijayuda/pskernel/blob/64499d5db307a4d5548bc70c6b46fc32cc0cda94/psc15selfhost/packages/pskernel-core/metatheory/Ps/KernelCore/Metatheory/CheckerKnotConfiguration.lean
[R24]: https://github.com/dwijayuda/pskernel/blob/64499d5db307a4d5548bc70c6b46fc32cc0cda94/psc15selfhost/packages/pskernel-core/metatheory/Ps/KernelCore/Metatheory/AdmissionOrdinaryTransactionConfiguration.lean
[R25]: https://github.com/dwijayuda/pskernel/blob/64499d5db307a4d5548bc70c6b46fc32cc0cda94/psc15selfhost/packages/pskernel-core/metatheory/Ps/KernelCore/Metatheory/AdmissionMutualRecursorTransactionConfiguration.lean
[R26]: https://github.com/dwijayuda/pskernel/blob/64499d5db307a4d5548bc70c6b46fc32cc0cda94/psc15selfhost/packages/pskernel-core/metatheory/Ps/KernelCore/Metatheory/Judgments.lean
[R27]: https://github.com/dwijayuda/pskernel/blob/64499d5db307a4d5548bc70c6b46fc32cc0cda94/psc15selfhost/packages/pskernel-core/metatheory/Ps/KernelCore/Metatheory/NativeReduction.lean
[R28]: https://github.com/dwijayuda/pskernel/blob/64499d5db307a4d5548bc70c6b46fc32cc0cda94/psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/API/Kernel.lean
[R29]: https://github.com/dwijayuda/pskernel/blob/64499d5db307a4d5548bc70c6b46fc32cc0cda94/psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/API/Session.lean
[R30]: https://github.com/dwijayuda/pskernel/blob/64499d5db307a4d5548bc70c6b46fc32cc0cda94/psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Checker/State.lean
[R31]: https://github.com/dwijayuda/pskernel/blob/64499d5db307a4d5548bc70c6b46fc32cc0cda94/psc15selfhost/packages/pskernel-core/proof/PSKERNEL_CORE_SEMANTIC_AUDIT.md
[R32]: https://github.com/dwijayuda/pskernel/blob/64499d5db307a4d5548bc70c6b46fc32cc0cda94/psc15selfhost/packages/pskernel-core/metatheory/Ps/KernelCore/Metatheory/BootstrapStringObligations.lean
[R33]: https://github.com/dwijayuda/pskernel/blob/64499d5db307a4d5548bc70c6b46fc32cc0cda94/psc15selfhost/scripts/check-pskernel-core-proofs.mjs
[R34]: https://github.com/dwijayuda/pskernel/blob/ed5d00aca0743bde583b45fe7756dd494ac3960f/psc0/package.json
[R35]: https://github.com/dwijayuda/pskernel/blob/756f4b9175edc11adf19b6b50586af762d296edc/AI_WORK_STATE.md
[C01]: https://github.com/dwijayuda/pskernel/actions/runs/37947341800
[C02]: https://github.com/dwijayuda/pskernel/actions/runs/37947341899
[C03]: https://github.com/dwijayuda/pskernel/actions/runs/37967710379
[C04]: https://github.com/dwijayuda/pskernel/actions/runs/37951870008
[C05]: https://github.com/dwijayuda/pskernel/actions/runs/37949712969
[C06]: https://github.com/dwijayuda/pskernel/actions/runs/37491824471
[C07]: https://github.com/dwijayuda/pskernel/actions/runs/37676451213
[C08]: https://github.com/dwijayuda/pskernel/actions/runs/37676451307
[C09]: https://github.com/dwijayuda/pskernel/actions/runs/37676451387
[E01]: https://lean-lang.org/doc/reference/latest/ValidatingProofs/
[E02]: https://lean-lang.org/faq/
[E03]: https://cakeml.org/
[E04]: https://cakeml.org/icfp16.pdf
[E05]: https://compcert.org/doc/html/compcert.backend.Allocation.html
[E06]: https://compcert.org/doc/
[E07]: https://cakeml.org/candle/
[E08]: https://docs.wasmtime.dev/security.html
[E09]: https://nodejs.org/api/vm.html
[E10]: https://nodejs.org/api/permissions.html
[E11]: https://docs.npmjs.com/cli/v12/using-npm/config/
[E12]: https://mlir.llvm.org/docs/DialectConversion/
[E13]: https://www.cl.cam.ac.uk/~jrh13/papers/holhol.pdf
[E14]: https://metarocq.github.io/
[E15]: https://arxiv.org/html/2512.05262v1

[R36]: https://github.com/dwijayuda/pskernel/blob/85ccb4e1103d77ed77c09c5795fc48ae4ea8ea62/psc15selfhost/package.json
[R37]: https://github.com/dwijayuda/pskernel/blob/85ccb4e1103d77ed77c09c5795fc48ae4ea8ea62/psc15selfhost/lakefile.lean
[R38]: https://github.com/dwijayuda/pskernel/blob/85ccb4e1103d77ed77c09c5795fc48ae4ea8ea62/psc15selfhost/scripts/check-pskernel-core-proofs.mjs
[R39]: https://github.com/dwijayuda/pskernel/blob/85ccb4e1103d77ed77c09c5795fc48ae4ea8ea62/psc15selfhost/packages/pskernel-core/proof/Ps/KernelCore/API/Kernel.proof.lean
[R40]: https://github.com/dwijayuda/pskernel/blob/85ccb4e1103d77ed77c09c5795fc48ae4ea8ea62/psc15selfhost/packages/pskernel-core/package.json

[E16]: https://docs.npmjs.com/cli/v12/configuring-npm/package-json/
[E17]: https://docs.npmjs.com/cli/v12/using-npm/scope/
[E18]: https://www.typescriptlang.org/download/
[E19]: https://docs.npmjs.com/cli/v12/commands/npm-run/
[E20]: https://docs.npmjs.com/cli/v12/commands/npm-ci/
[E21]: https://docs.npmjs.com/cli/v12/configuring-npm/package-lock-json/
[E22]: https://eslint.org/docs/latest/use/configure/plugins

[R41]: https://github.com/dwijayuda/pskernel/blob/3fbf7f778ab20aaeaafe87ae07b04c00ab2d29f7/psc0/packages/backend-ts/src/Ps/BackendTs/Module.lean
[R42]: https://github.com/dwijayuda/pskernel/blob/3fbf7f778ab20aaeaafe87ae07b04c00ab2d29f7/psc0/packages/compiler/src/Ps/Compiler/Api.lean
[R43]: https://github.com/dwijayuda/pskernel/blob/3fbf7f778ab20aaeaafe87ae07b04c00ab2d29f7/psc0/packages/compiler-ir/src/Ps/CompilerIr/Model.lean
[R44]: https://github.com/dwijayuda/pskernel/blob/3fbf7f778ab20aaeaafe87ae07b04c00ab2d29f7/psc0/packages/backend-ts/src/Ps/BackendTs/Type.lean

[E23]: https://devblogs.microsoft.com/typescript/announcing-typescript-7-0/
[E24]: https://github.com/microsoft/TypeScript/wiki/Using-the-Compiler-API
[E25]: https://www.typescriptlang.org/tsconfig/sourceMap.html
[E26]: https://code.visualstudio.com/api/language-extensions/language-server-extension-guide
[E27]: https://www.typescriptlang.org/tsconfig/noEmitOnError.html
[E28]: https://code.visualstudio.com/api/working-with-extensions/publishing-extension
[E29]: https://code.visualstudio.com/api/extension-guides/workspace-trust

[E30]: https://www.w3.org/TR/wasm-js-api-1/
[E31]: https://nodejs.org/download/release/v22.23.3/docs/api/worker_threads.html
[E32]: https://webassembly.org/docs/security/


## PSCV P1–P5 progress and promotion limits (10 October 2026)

The accepted P0 [feature ownership map](docs/platform/PSCV_PROFILE_AND_PACKAGE_BOUNDARIES.md) remains in force. The qualified P1-E typed-witness observation is documented in [PSCV_P1E_TYPED_RESOLUTION.md](docs/platform/PSCV_P1E_TYPED_RESOLUTION.md); it does not freeze the Standard environment. The explicit [P1–P5 sound gates](docs/platform/PSCV_P1_TO_P5_SOUND_GATES.md) separate pure-source certification (P2) from executable backend preservation (P4). No production core/backend/bootstrap change or verified executable certification is authorized by these planning documents.
