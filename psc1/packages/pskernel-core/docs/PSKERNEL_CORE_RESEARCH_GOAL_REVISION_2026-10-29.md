# PSKernel-Core: research-backed goal revision

29 October 2026, Asia/Jakarta. Decision research for the authorized PSKernel implementation. This document revises the next delivery goal; it does not claim that the implementation or the original global acceptance gates are complete.

## Decision

Deliver **PSKernel-Core Bounded Independent Checker Preview 1**: the existing independently checking kernel, packaged with a supervised input-file interface, explicit assumption and resource outcomes, a frozen regression ledger, and reproducible Linux CI artifacts. The normative acceptance contract is [PSKERNEL_CORE_BOUNDED_PREVIEW_GOAL_2026-10-29.md](PSKERNEL_CORE_BOUNDED_PREVIEW_GOAL_2026-10-29.md).

This is a finite engineering milestone built on the adopted implementation. Full Lean compatibility, a whole-kernel performance win, a global soundness theorem, compiler declaration acceptance, fixed points and backend preservation are separate goals. They remain visible and unfinished. The original 193-case strict gate stays failed until its actual criteria pass. A preview completion statement must always be qualified by its scope.

There is no evidence-based guarantee of a completion date, absence of all bugs, or eventual success of the full research program. What can be made precise now is the deliverable, the finite work required, the acceptance measurements, and the conditions that block delivery. "Achievable" here means no unproved metatheory or successful self-hosting is required on this milestone's critical path. It does not mean an unconditional guarantee of software correctness.

## Live project evidence

On this review, primary is `a1a041b63ca4f2e34f5223240a7761e086f72f25`; integration is `d746fb8cdcb47f2031ac6db483cf63b7debbcbef`. The adopted production source tree is `bbe353e649feed5b796adb164dcec36eaca915ab`. GitHub run states and the committed [27 October acceptance evidence](https://github.com/dwijayuda/pskernel/blob/a1a041b63ca4f2e34f5223240a7761e086f72f25/psc1/packages/pskernel-core/docs/evidence/2026-10-27-nested-adoption-and-qualification.md) were read again. This review does not rerun or re-audit the earlier raw runtime archives; their scoped observations are the previously audited evidence, not new measurements.

| Observation | What it establishes | What it leaves open |
|---|---|---|
| Native adoption run [40441811683](https://github.com/dwijayuda/pskernel/actions/runs/40441811683), SUCCESS; 814 named reports across 61 modules | Existing finite structural/refinement obligations, including seven continuation theorems, satisfy the retained axiom audit | The missing complete checker/declaration/context/cache logical chain |
| Both nested programs passed all 8,400 String assertions in [40436829581](https://github.com/dwijayuda/pskernel/actions/runs/40436829581) | Exact-source finite String qualification | The aggregate run remains FAILURE; no universal completeness or speed theorem |
| Full original Arena: 174 strict passes, 17 timeouts, two safety-contract differences, 193 total | A stable baseline and explicit counterpressure for further engineering | Strict compatibility remains FAIL; 176 completed raw semantic envelopes matching a baseline does not remove the 19 non-passes |
| Delivery [40440807903](https://github.com/dwijayuda/pskernel/actions/runs/40440807903), SUCCESS | Both detached runtime packages and their API/checker/nested examples work without invoking Lean at runtime | A supported supervised end-user file interface and a complete operational acceptance ledger are not established by those examples |
| Emitter [40438887095](https://github.com/dwijayuda/pskernel/actions/runs/40438887095), SUCCESS | Exact paired emitted bytes, 3,391 comparisons and 21 harnesses per route; actual cache workers avoid per-level wrappers | Unchanged whole-workload qualification and a whole-kernel benefit; source remains isolated |
| Compiler diagnostic [40440382483](https://github.com/dwijayuda/pskernel/actions/runs/40440382483), SUCCESS as a diagnostic | A 1,773-admission export exists and a genuine rejection is recorded | Replay rejects declaration 1 on undeclared `Nat`; there is no accepted compiler closure |

The prior scalar A-B-B-A still has two completed and two censored observations. No plan may turn the completed subset into a passing performance median.

## Primary-source findings and consequences

### 1. A bounded checker should promise justified successful answers and explicit non-answers

[Lean4Lean, paper v3](https://arxiv.org/html/2403.14064v3), especially sections 3.2.1 and 4, describes recursive-depth fuel and timeout errors, and explains nontermination phenomena in Lean conversion. It relates executable terms to logical terms and keeps the well-typed-input premise of infer-only work explicit. Its published verification progress is not a theorem about PSKernel.

**Engineering inference:** a promise to finish arbitrary Lean checking within a fixed resource budget is the wrong release contract. Retain the genuine checker and original budgets, but supervise the process and preserve distinct accepted, invalid, unsupported, exhausted and internal-error outcomes. Do not call exhaustion an invalidity proof or treat an infer-only result as full checking.

This is especially concrete in PSKernel. At the adopted source, [Checker/ResourcePolicy.lean](https://github.com/dwijayuda/pskernel/blob/a1a041b63ca4f2e34f5223240a7761e086f72f25/psc1/packages/pskernel-core/src/Ps/KernelCore/Checker/ResourcePolicy.lean) explicitly states that fuel is a recursive bound, not a consumed instruction count; cancellation is sampled before entry and the pure checker cannot interrupt a running call. Existing five-way outcomes already live in [API/Outcome.lean](https://github.com/dwijayuda/pskernel/blob/a1a041b63ca4f2e34f5223240a7761e086f72f25/psc1/packages/pskernel-core/src/Ps/KernelCore/API/Outcome.lean). Reuse them rather than inventing a competing kernel result type.

The [Node 22 child-process documentation](https://nodejs.org/download/release/v22.23.3/docs/api/child_process.html) distinguishes process creation, timeout signalling, buffered-output limits and exit/close events. A timeout signal alone is not evidence that cleanup completed.

**Implementation consequence:** use a parent supervisor outside the pure kernel, direct executable/argument invocation, bounded output capture, child termination and reaping, and a single validated result envelope. Test the shutdown path in Linux Actions. The 2,048-MiB Node old-space setting is not a total-process RSS limit. Neither fuel nor the supervisor is a hard real-time or OS-isolation theorem.

### 2. A source theorem needs a deliberate specification and an implementation bridge

At pinned con-leche commit [`e3fd221f1e43826653e210ff725fb2cc3e0d93f0`](https://github.com/leanprover/con-leche/tree/e3fd221f1e43826653e210ff725fb2cc3e0d93f0), the [README](https://github.com/leanprover/con-leche/blob/e3fd221f1e43826653e210ff725fb2cc3e0d93f0/README.md) describes extra certification checks chosen to simplify verification. It now uses a positivity-based approach to inductives rather than the older nested-to-mutual modelling route described in earlier PSKernel research notes. Its verified and trusted modes have different proof coverage.

The actual [MainTheorem.lean](https://github.com/leanprover/con-leche/blob/e3fd221f1e43826653e210ff725fb2cc3e0d93f0/ConLeche/MainTheorem.lean) states `model_exists` for successful `checkDecls .verified`, under an explicit `SetTheory V` interface. It also describes a parser/prelude/fold corollary and the driver's connection. This is a conditional model theorem about that implementation, not unconditional certification of every host/runtime component.

**Engineering inference:** PSKernel should keep its own implementation and eventually prove a successful-checking/admission theorem through its actual environment, local-context, cache and owner invariants. It may be worth accepting additional checked work to simplify that proof, but this is a research option, not an implementation change approved by this document. Any future algorithm change still owes PSKernel's retained semantic, resource and performance qualification. Do not promise that mirroring another checker, importing its theorem, or adding more structural report counts closes this gap.

For Preview 1, preserve the existing statements, seven continuation results, production function bindings and strict axiom audit. Do not place the full model theorem on the preview's critical path.

### 3. The axiom policy has two different boundaries

[Lean's validation guidance](https://lean-lang.org/doc/reference/latest/ValidatingProofs/) separates acceptance of a proof from the intended meaning of its statement, and recommends inspecting dependency axioms. Source verification, fresh replay and independent checking address different layers.

PSKernel's current proof-build allowlist covers the theorems used to verify PSKernel. It is not automatically an allowlist for declarations in a file checked by PSKernel. [API/Kernel.lean](https://github.com/dwijayuda/pskernel/blob/a1a041b63ca4f2e34f5223240a7761e086f72f25/psc1/packages/pskernel-core/src/Ps/KernelCore/API/Kernel.lean) dispatches `axiomDecl`; [Admission/Declaration/Admission.lean](https://github.com/dwijayuda/pskernel/blob/a1a041b63ca4f2e34f5223240a7761e086f72f25/psc1/packages/pskernel-core/src/Ps/KernelCore/Admission/Declaration/Admission.lean) checks an axiom's header before adding it. This is normal relative-to-assumptions kernel behavior. The [existing stream adapter](https://github.com/dwijayuda/pskernel/blob/a1a041b63ca4f2e34f5223240a7761e086f72f25/psc1/scripts/pskernel-arena-replay.mjs) translates input axiom records into that API.

**Implementation consequence:** the new file interface must list input assumptions and have an explicit strict policy. A name alone does not authorize an axiom: the allowed standard declaration schemas must include universe parameters and types. Unknown or altered schemas decline under the strict wrapper profile. Keep a separate low-level API contract that explains relative checking. Do not mutate the retained Arena adapter, expected outcomes or denominator to manufacture agreement. The new strict wrapper is tested in addition to that original comparison.

An input axiom asserting False is an assumption-policy issue, not by itself proof of a typechecker bug. Conversely, reporting an arbitrary assumed statement as an unqualified verified theorem is unacceptable product behavior.

### 4. Benchmarks are evidence with a version, not a universal finish line

The pinned [Lean Kernel Arena README](https://github.com/leanprover/lean-kernel-arena/blob/1a1d74fadefaf947e7b1bbcb0f8374892cb9942e/README.md) separates acceptance, rejection and declined cases, records timeouts, and explains immutable rounds. Its scoring policy is external context. PSKernel's stricter retained 193-case gate and its classifications remain authoritative for this project.

**Engineering inference:** maintain two explicit results: preview operational evidence, and original strict compatibility. The latter may remain FAIL while the former is complete. Every preview package must prominently publish the full 193-row report and its non-passes. No filtered success denominator, new unsupported annotation, or timeout-as-rejection conversion is permitted. A preview is not a release meeting the original full goal.

The live Arena has evolved since the frozen September corpus. Review newer upstream cases as a separate versioned compatibility-delta backlog; do not silently replace the 193-case corpus or the pinned Lean 4.35.0 toolchain. Before any claim of current-Lean compatibility, a separately qualified upgrade is required.

### 5. Checking compiler declarations and verifying a compiled kernel are separate projects

[The CakeML backend paper](https://cakeml.org/jfp19.pdf), sections 10 and 11, composes pass-level semantic proofs with proof-producing translation and bootstrapping. Its implementation-to-machine-code result is stronger than obtaining matching compiler hashes or exporting a source closure. The paper also identifies a boundary around the user-interface specification and generated wrapper/linking assumptions.

[The CompCert TCB analysis](https://arxiv.org/abs/2201.10280) examines modelling and surrounding-tool assumptions that can remain despite compiler proofs.

**Engineering inference:** a PSC1-produced JavaScript checker still relies on PSC1 code generation, TypeScript/JavaScript processing, Node and the host. Finite native/emitted comparisons reduce risk but do not prove backend preservation. Genuine compiler replay must first close the checked prelude/dependency boundary, then measure progress through all admissions. Missing `Nat` is a first blocker, not a one-fix completion forecast. Compiler replay and backend proofs stay off Preview 1's critical path.

## Revised work order

1. Freeze the preview contract and implement the supervised file interface using the existing validated public DAG ingress and checked empty sessions. No low-level session record or checking receipt supplied by input may serve as authority. The provider has no native evaluator. Add input-assumption policy separately from proof-build axiom auditing.
2. Qualify the wrapper's success and all non-success paths, including protocol errors, child failure, deadline/cancellation and bounded diagnostic output. Preserve batch atomicity. Produce all failure diagnostics without turning progress text into a checking verdict.
3. Run the exact baseline programs through all original String and Arena gates; retain raw receipts, original budgets and every failure. Add focused diagnostics on original cases 83/82 only as diagnostic runs. Freeze the failure ledger and compare the complete classification map and semantic envelopes. Any new false acceptance or unexplained change blocks preview delivery.
4. Generate both detached runtime packages in Linux Actions, audit every manifest member, run the examples/CLI in an empty-PATH environment with Node addressed explicitly, and deliver the source-bound preview and its complete limitations ledger.

These are four work batches, not a promise of four turns or four days. The first batch's CI result determines a credible remaining estimate. Existing authenticated artifacts can be reused only for their exact unchanged inputs. Changed kernel, compiler, wrapper or proof bytes require checks appropriate to that change.

The isolated emitter is deferred from this critical path. Its full original gate/adoption rules are unchanged. A performance experiment that fails the required full gates is rejected or stays isolated; it cannot indefinitely delay delivery of the known baseline preview. No whole-kernel speedup is required or advertised for Preview 1.

## Later goals and decision boundaries

- **Strict practical compatibility:** all original 193 strict cases pass under original limits; both String routes and retained controls pass; all safety semantics are explicitly reconciled. This remains an engineering program with unresolved causes. It is not marked complete by the preview.
- **Kernel-assisted compiler replay:** install the actual checked prelude and complete dependency closure, replay the exact compiler admissions, and retain accepted/rejected progress and reproducible receipts. No dummy declarations, assumed checked environment or official-Lean acceptance callback.
- **Logical soundness:** define the intended judgments, environment/contexts/cache relation and implementation bridge; prove successful operation/admission soundness with reviewed hypotheses. Distinguish a model theorem under explicit foundational assumptions from an unconditional consistency claim.
- **Backend assurance:** formal semantic preservation, translation validation or independently justified target execution require their own specified proof boundary. A self-application fixed point alone is insufficient.

Do not assign an overall percent from test or theorem counts. Do not promise these research goals will complete by a date. Reassess them when a central preservation theorem and an accepted dependency-closed compiler replay exist.

## Completion of this revision

This research/roadmap revision is complete when its documents are committed with a non-force expected-HEAD update, every changed document is read back, production source/toolchain/test bodies and old acceptance criteria remain unchanged, and the next implementation task is explicit. Preview 1 itself remains NOT YET IMPLEMENTED/QUALIFIED as a complete operational product.
