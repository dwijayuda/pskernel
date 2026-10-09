# PSC0 Architecture Plan

**Status:** researched architectural direction and migration plan; implementation is pending.

**Decision update:** 10 October 2026, Asia/Jakarta.

**Repository evidence cut:** 9 October 2026, approximately 17:57 UTC. Source and CI claims below are pinned to that audit; they are not assertions about unseen later branch state. Re-fetch live heads and lane handoffs before implementation.

**Proof-organization follow-up:** the proof layout, imports, and runner were inspected at `pscv/prove-pskernel-core-v1` commit `85ccb4e1103d77ed77c09c5795fc48ae4ea8ea62`. This supplements the dated audit with organizational evidence; it does not requalify the newer branch's theorem set or CI.

**Canonical plan format:** this Markdown file. It supersedes the earlier PDF draft for future plan revisions.

## Decisions confirmed by the user

- Use ps-prefixed package basenames: `pscore`, `psfrontend`, `psc`, `psbackend-ts`, with `pskernel-core` retained for the kernel.
- Keep `psbackend-ts` in the required compiler distribution and self-host source closure. Use the pinned TypeScript 7 toolchain to produce executable JavaScript.
- Keep compiler implementation in the supported `.lean`/`.ps` source profile. Keep `pscore` backend-neutral and the logical kernel independent of backend code.
- Make `psbackend-js`, `psbackend-wasm`, `psbackend-rust`, and other backends optional extensions. Replacing the required TS backend is not a goal of this plan.
- Allow mature extension functionality to be adopted through explicit bundling, implementation-integration, or semantic-change decisions. Adoption never automatically waives kernel checks, required preservation evidence, isolation, or disclosure.
- Preserve the selected seed and demonstrated compiler fixed point. A joint generated compiler/kernel closure remains a separate acceptance milestone.
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

The desired platform has three different kinds of smallness. The logical kernel should be small enough to specify and audit. The compiler’s self-host closure should include only one reference compilation path. The installed product should keep optional backends, full-Lean integration, and extension execution machinery out of the default dependency closure when unused. These sizes must be measured separately.

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

Names below follow the user's selected ps-prefixed basename convention. Actual npm name/scope availability remains a publishing check. Use one coordinated release train initially. A logical boundary does not automatically deserve an independent npm package.

| Module / proposed package | Owns | Dependency rule |
| --- | --- | --- |
| pskernel-core | Kernel terms and declarations, admission, conversion, authoritative environments, kernel proof sources | No frontend, plugin loader, CLI, backend, or PSCV dependency |
| pscore | Canonical data contracts and bridge, fixed RuntimeIR, invariants, erasure, explicit semantic pass contracts | Pure internal modules; no host IO or backend imports |
| psfrontend | Default bounded .ps/.lean parsing, names, macros, elaboration, meta state | Produces Core proposals through public data contracts |
| psc | Trusted supervisor, CLI, policy, kernel service, resolver, extension runner, receipts, publication | Owns capabilities and decisions; does not import external package code |
| psbackend-ts | Required reference backend for the core distribution and self-hosting; TS7 runtime adapters | Consumes pipeline data; cannot publish; target-specific code stays outside pscore |
| pscv | Optional approved VCG/coverage implementation and obligation schema | Activation and final coverage decision stay in supervisor |
| Optional psbackend-js, psbackend-wasm, psbackend-rust, Lean adapter | Target-specific or compatibility functionality | Outside the required compiler/self-host closure; individually qualified |
| psc/sdk or development-only SDK package | Typed clients, schemas, fixture runner, examples | Convenience only; no authority or general service registry |

Here, core distribution means the required compiler product: psc, pscore, psfrontend, pskernel-core, and psbackend-ts with their declared runtime/toolchain dependencies. It does not mean putting TypeScript lowering or TypeScript-specific concepts inside pscore or the logical kernel. The source compiler remains written in its supported .lean/.ps profile.

Publish the supervisor and kernel at clear consumer boundaries. The compiler-core, frontend, and TS backend can initially be subpackages or subpaths under a shared version if separate publication would add only coordination work. Proof sources, docs, archives, and historical seeds remain in the repository without automatically entering release tarballs.

Use one development-only compiler assurance workspace at `psc0/proofs/`, organized by package. This is a source/build boundary, not another mandatory npm package or compiler plugin framework. Its pinned Lean toolchain and optional proof libraries are installed by the assurance workflow only. Keep the kernel's canonical assurance library under its existing ownership and reuse its results at an explicit source/profile boundary; do not create a second kernel proof copy. Section 16 specifies the layout.

### Dependency direction

The supervisor orchestrates the frontend, kernel, and reference backend. Frontends and extensions depend on data contracts, never on supervisor internals. The kernel is independently buildable. Compiler semantic modules are pure and reusable. Backends consume explicit IR stages; they do not own common transformations secretly.

Keep one canonical Core wire schema. The elaborator may retain metavariables and convenient internal structures that are absent from admitted kernel terms. Avoid forcing an expensive total representation rewrite. Instead, prove that remaining conversion bridges preserve binders, universes, names/references, primitive identity, and the meaning of declarations.

The canonical schema must remain a data contract rather than a second semantic kernel. Do not duplicate admission rules in a “trusted bridge” and slowly create two checkers. Cheap structural validation belongs at decoding; logical admission belongs in PSKernel.

### First-release trust transition

The current generated JS compiler may remain a pinned first-party implementation while external packages use strict Wasm confinement. That protects against external extension execution but does not automatically remove all first-party compiler/runtime code from the admission TCB. Record that broader initial assumption explicitly.

The destination is to run candidate-producing frontend work through a qualified confined runner as well, then let the authority validate exact returned data. Moving the default JS frontend into an ordinary subprocess is useful organization but is not, by itself, a malicious-code security boundary. A qualified Wasm or OS-sandboxed route is required to make that stronger claim.


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

Node vm explicitly is not a security mechanism; Node’s permission model does not promise confinement against malicious code. Worker threads, Object.freeze, package manifests, and ordinary subprocesses therefore cannot satisfy this requirement alone. Do not ship an automatic unsandboxed fallback. [E09] [E10]

### Official output is a supervisor capability

- Compute identity from the actual bytes instantiated: package/version if known, resolved origin, content digest, entry module, protocol, and granted imports/capabilities.
- Record attempted and executed loads, including failures, and retain the extension dependency identities that influenced cache hits.
- Do not accept “built-in,” “trusted,” or “verified” status from a package’s own manifest.
- Capture guest messages as tagged, escaped diagnostics. Guests never share the official terminal/status stream or write final receipts.
- Include the list in machine-readable results and a concise mandatory CLI summary. Quiet/formatting options cannot remove the record; report an empty set explicitly when appropriate.
- Protect final output paths and the admission service from guest access. A killed or exhausted guest cannot turn its partial output into a successful build.

The host can attest which modules it loaded. It cannot infer every source library compiled inside an opaque binary, prove the truth of its publisher metadata from a name alone, or ensure a human reads output after external redirection. Record bundled dependency declarations separately from byte identities. Do not promise resistance to an attacker who replaces the launcher, engine, OS, or entire installation.

### Installation is part of the boundary

npm distributes packages; it does not make their code trustworthy. Controlled ingestion must use a lockfile/integrity identities and an explicit no-lifecycle-script policy for extension packages. Keep extensions out of the supervisor’s JS module-resolution graph and sanitize inherited execution hooks. Package provenance can establish an origin claim, not safety or semantic correctness.

Current npm configuration documents ignore-scripts, including the fact that explicitly requested npm run scripts still execute. Pin the intended ingestion behavior rather than relying on changing defaults. Prebuilt runner artifacts should not require executing an extension’s install script. This needs a narrow resolver and controlled runner, not a new package manager. [E11]

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
| 2. One isolated extension slice | Data-only descriptors, constrained Wasm runner, limits, actual-load reporting, three complete examples | External code cannot obtain admission, provider, reporting, or final-output authority |
| 3. Stabilize contracts | Primitive identities, canonical bridge, narrow SDK, deterministic syntax dispatch; only supported rewrite certificates | Supported extension changes require no trusted-core source changes |
| 4. Package and requalify | Minimal npm tarballs, coordinated versions, clean-install tests, cold recovery and complete new C1/C2/C3 checkpoint | Installable checked compiler and isolated examples without a repository checkout |
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

These estimates exclude complete mechanized proofs, a new Wasm compiler, full Lean compatibility, a portable native-worker sandbox, a broad language server, and external runtime binary/dependency size. The approximately 80.9k existing assurance lines already demonstrate why proof work deserves its own budget.


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
| Cost and usability | Clean npm install runs checked builds and examples; no optional backend enters the mandatory closure; compare latency, memory, tarball size and dependencies to a measured baseline |

Run failure-injection tests at each transaction boundary, including backend crash, receipt write failure, malformed guest responses, timeout, and a changed byte buffer after validation. Test actual denied operations; a manifest saying “sandboxed” is not a test.

For performance, use repeated measurements on the same runner and workload. A provisional no-more-than-20% median regression budget without an accepted explanation is a reviewable planning gate, not a current performance result. Record warm edits and peak memory as well as full generations.

For extension ergonomics, require the example macro, tactic, and command to be implemented through the documented SDK only. Kernel and supervisor source should not need per-extension changes. Later optimizer/backend examples must demonstrate the exact evidence they support rather than an unsupported generic verified label.

### Definition of the first successful release

A clean npm installation builds the declared bounded language through one checked publication transaction, selects an unambiguous kernel artifact, reports actual extension identities, runs constrained external examples without privileged access, and reproduces its selected compiler closure. It states the remaining source-fidelity, semantic-preservation, model, runtime, and bootstrap assumptions precisely.

This is a complete architectural implementation milestone even while the later proof program remains unfinished. The obligation inventory can contain planned or in-progress proofs, and ordinary npm/self-host qualification does not need to execute that proof program. It must not be marketed as a fully verified compiler simply because its kernel accepts proof terms or its compiler reaches a fixed point.


## 20. Risks and decisions to keep explicit

### Highest risks

**Proof scope mismatch.** An operational theorem may be mistaken for foundation soundness, a typed IR for preservation, or a receipt for a certificate. Mitigation: a claim ledger with exact subjects, assumptions, and theorem meanings.

**Kernel reconciliation drift.** Multiple source copies, active branches, provider artifacts, and proof checkpoints can continue evolving independently. Mitigation: one maintained source, deliberate integration ownership, immutable artifact provenance, and exact cross-lane comparison before promotion.

**Supervisor growth.** Policy, caching, package loading, CLI commands, and compatibility runners could become a second large compiler. Mitigation: bounded data operations, one transaction, internal modules instead of a service bus, and defer capabilities without a concrete consumer.

**Isolation compatibility pressure.** Users will want arbitrary npm JS and native Lean macros. Mitigation: supported modes with no silent downgrade; strict Wasm first, platform-qualified native compatibility later.

**Overpromising validators.** Semantic equivalence is harder than IR well-formedness. Mitigation: a proved/reference path and restricted certificate families; refused evidence stays refused.

**Bootstrap disruption.** Introducing unsupported source constructs or promoting a new backend too early can lose reproducibility. Mitigation: preserve R, stage language changes, keep one mandatory target, and separate compiler-only from joint-kernel claims.

**Resource and runtime mismatch.** Demand, string positions, arrays, exceptions, and stack behavior can invalidate proofs about source programs. Mitigation: a finite runtime specification, primitive identities, conformance, and refinement obligations grounded in that specification.

### Deliberate architectural decisions

- No whole-compiler rewrite as the default migration strategy.
- No arbitrary same-process third-party JavaScript execution.
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

Repository sources are pinned to the inspected commits. Workflow links identify specific runs. External sources are primary documentation or research. R36–R40 are the later proof-organization inspection at `85ccb4e1103d77ed77c09c5795fc48ae4ea8ea62`; they do not update the original audit's CI/theorem-completion claims.

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
