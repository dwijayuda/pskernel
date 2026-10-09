# Strict PSC0-SH/1 implementation plan

Status: active implementation from ed5d00aca0743bde583b45fe7756dd494ac3960f; not yet strict-qualified. The qualified practical checkpoint was merged to main on 2026-10-09 at 16:30:26 UTC. Work proceeds on psc0/strict-sh1-v1. [AI_WORK_STATE.md](../../../AI_WORK_STATE.md) is the continuation authority; [merge-baseline.json](merge-baseline.json) records the verified integration.

## Goal and scope

Finish the mandatory source/runtime contract already defined by [SPEC.md](../SPEC.md) for the enabled TS→JS compiler lane. Improve authoring through the existing portable frontend, preserve selected R, and keep new-only ps-0.9-r3 and TypeScript 7.0.2. Merging the practical checkpoint removes the old bounded recursion/projection obstacles already repaired there; it does not enable all PSC1 or activate strict SH/1.

The work is a dependency-ordered implementation and evidence project. It does not require rewriting the 226 historical source locators or implementing optional syntax, scalars or targets. New helper modules stay inside the twelve existing compiler packages.

## Assurance policy

Every mandatory obligation needs a semantic rule, admissibility condition, implementation owner and evidence method. Distinguish:

- Core admission: exact declarations accepted by the pinned provider.
- Runtime IR typing: complete accepted report on the particular original IR.
- Compiler qualification: raw source replay, fixed-point products and stated execution checks for exact source/toolchain identities.
- Semantic correspondence: preservation through source normalization, erasure, runtime representation and TS/JS lowering.
- Formal verification: only the exact theorem actually established under its stated assumptions.

The specification does not require one monolithic machine-checked compiler theorem. It also does not permit replacing general preservation with a finite fixture pass. Use executable admission checks, per-compilation correspondence relations and complete rule-level arguments where appropriate; label finite conformance separately. Any enabled row without a defensible disposition remains open. Resource exhaustion never counts as complete evidence.

## Stages and exit conditions

| Stage | Work | Exit condition |
| --- | --- | --- |
| S0 | Freeze the enabled contract and rule ledger | Nine required capability families, eleven IR expression forms, six primitives plus Array and 45 operations have explicit domains and assurance methods |
| S1 | Real portable source boundary | Raw named modules pass the actual lexer/parser, ordered import policy, bounded source checks, existing preparation and exact-IR checked emission; unsupported forms and exhausted budgets refuse |
| S2 | Value and operation admission | Canonical Unicode carriers and valid domains are checked; array guards preserve valid values/evaluation order; operation-complete native/generated conformance retains all observations |
| S3 | Erasure/layout correspondence | Preserve and validate actual binder, proof/type omission, generic, field and constructor mappings associated with the particular prepared source/Core/IR |
| S4 | Evaluation and capture | Every enabled IR/normalization family has an explicit evaluation/demand/capture rule and supported correspondence disposition; initialization and errors are included |
| S5 | TS/JS lowering | Name/freshness/layout assumptions and generator, eta, count-loop and tail-loop routes have complete supported dispositions under exact TS7/Node identities |
| S6 | Qualification and activation | One coherent exact-source native/N1/C1/C2/C3 qualification and separate provider evidence; every enabled mandatory row closed before strict activation |

S1 and S2 form the first substantive implementation checkpoint. Qualifying that checkpoint does not close S3–S5 by implication. The [obligation ledger](obligations.json) and companion correspondence ledger record what remains.

## Source boundary design

Use one source kind for each ordered bundle and retain each module's identity and raw text. Lex and parse exactly that text. Validate imports before preparation discards them. A missing, forward, cyclic, duplicate or out-of-package dependency must not be silently ignored.

Traverse all AST declaration/term constructors with bounded explicit work. Preserve byte spans and owner names for source diagnostics. Reuse installed elaboration and structural-recursion rules; avoid duplicating type inference. Since the Lean parser lowers do immediately, identify the synthetic helper reference using the original do token span, without banning ordinary helper names or fields.

The current atomic entry returns the prepared object, original IR, accepted complete checker report and emitted TS together. The host serializes these exact objects and hashes the exact compiler/raw closure/grammar/options/outputs. It must not supply a freely forgeable “already checked” flag to emission.

The historical selected R does not export APIs being added now. It builds C1 through its existing qualified route. Current native/N1/C1/C2/C3 must exercise the new boundary; API absence on a current compiler is a refusal, not an implicit downgrade.

## Runtime design

Keep the six existing scalar representations and Array arity. The enabled operation contract belongs in ENABLED_RUNTIME.md and enabled-runtime-contract.json. Optional machine/floating/word scalar families remain rejected.

Validate JavaScript strings as Unicode scalar sequences at external carrier boundaries, including identifiers. Reject lone surrogates without replacement or normalization and bound validation work explicitly. Native Lean strings already satisfy their representation invariant.

For proof-required Array get/set, invalid indices produce a deterministic refusal before Number conversion. Preserve array/index/value evaluation exactly once in the original order, and allow in-bounds Unit elements. This is defense against invalid runtime inputs, not reconstruction of proof arguments removed by erasure.

The reference is the pinned Lean 4.34.0 implementation. String length counts scalars; raw string positions use UTF-8 byte offsets. Preserve the pinned behavior of get/next/extract, including explicitly distinguished invalid boundaries. Do not change cache algorithms or demand order speculatively.

Build one finite operation manifest and native reference vector. Compile one checked fixture module per executing compiler and retain its results, operation coverage, negative refusals and hashes. Native examples are independent conformance evidence, not a general lowering proof.

## Correspondence design

Use the existing normalization plans and erasure metadata before they disappear. Keep a companion record keyed by declaration and structural path, bound to source, grammar, compiler, normalization, Core and IR identities. Compare the actual transformation inputs/outputs; do not perform a second full preparation just to generate evidence.

Explicitly cover public wrappers/workers, structural decrease and simultaneous changing-state updates; runtime versus erased binders; constructor/record fields and projections; exact function groups and generic order; first errors and state-on-error behavior; let/capture scope; global initialization; target names and generated-name freshness; and all enabled emitter optimization routes.

Prefer small admission/provenance checks over rewriting unrelated compiler code. Static risks in arbitrary handcrafted IR are not automatically failures in the qualified source closure. Conversely, a source-closure pass does not establish the safety of arbitrary typed IR.

## First integrated implementation checkpoint

[implementation-checkpoint.json](implementation-checkpoint.json) binds every candidate source, host gate, reference and recipe input by its exact Git blob. The new portable source and atomic backend APIs, target admission, Unicode and array guards, native/current host consumers and actual-file evidence binder are implemented candidates. Cloud execution is still pending at this source checkpoint.

The finite source gate has two positive raw Lean/PS bundles, twenty-one portable refusals and two host Unicode refusals. Target conformance has nine accepted and twenty refused cases. Runtime conformance covers all forty-five enabled operations with 186 independent native observations, eight bounds failures, nine order/fault probes, five invalid carriers and two Unicode/position families. These counts describe planned assertions until their actual receipts pass.

The workflow's [sh1-qualify] source commit runs native preflight and current C1/C2/C3 qualification in one coordinated run; the frozen provider runs only after the compiler job qualifies. The native reference is executed once. Full-source preparation/IR checking is not repeated just to collect reports. The final binder reads the actual files, verifies executing/producing compiler identities and records exact receipt/product hashes.

The [correspondence guide](CORRESPONDENCE.md) and [33-rule ledger](correspondence-obligations.json) complete the rule inventory, not its general preservation proofs. All nine erasure, four normalization, eleven expression and nine backend/runtime rules retain their specific remaining obligations. S3–S5 stay open even after finite source/runtime/target qualification.

## Qualification workflow and stop rules

All repository execution occurs in GitHub Actions. Review source and related semantic obligations before a native preflight. Add gates and their source identities to the coherent existing qualification recipe. Reuse the prepared module, original IR, returned checker report and compiled native reference.

Retain exact logs and receipts, including failures if any. Do not relabel skipped/exhausted/failed cases as success or keep rerunning passed gates without a concrete remaining risk. After coherent preflight, run the required exact-source full qualification and frozen provider acceptance separately.

Do not select the candidate as a seed. Do not merge unqualified strict source. Documentation-only progress checkpoints may be committed with [skip ci]; they neither invalidate nor re-earn the baseline's source qualifications.

## Source basis

This plan implements existing requirements in SPEC §§2–8 and reconciles their status with CURRENT.md, IMPLEMENTATION.md, qualification-evidence.json, Compiler/Api.lean, BackendTs/Checked.lean, CompilerIr/Check.lean and the original-ir-inventory host boundary. All baseline sources are pinned to ed5d00aca0743bde583b45fe7756dd494ac3960f. New implementation, operation and correspondence evidence must name their own actual source revision.
