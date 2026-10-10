# PSKernel Core for PSC0

This is the active kernel development package at `psc0/packages/pskernel-core`.
It imports the complete source, companion proofs, and metatheory from
`pscv/prove-pskernel-core-v1` at `85ccb4e1103d77ed77c09c5795fc48ae4ea8ea62`,
with the bounded cache policy and Arena adapter from `132d817071cd62c23a70c15984d6c73e14d6e856`.

The target is **Lean 4.35.0-rc4**, commit
`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`. Run Lake from this directory:
the package has its own toolchain and does not replace PSC0's selected compiler
seed or its historical provider receipts.

## Correctness status

The metatheory and model/consistency proof are **unfinished**. The checked audit
in `metatheory/Ps/KernelCore/Metatheory/JudgmentAdequacy.lean` shows that the
legacy algorithmic equality rule permits arbitrary equality, and its typing
relation consequently inhabits every type. This is a defect in the proof
specification, not an exhibited executable acceptance of False. Existing
operational refinement theorems cannot be used as a model-soundness proof.

The active string comparator now has a specified equality decision and a proof
of its positive-result law. This closes one primitive obligation; it does not
repair the inadequate judgments. The new semantic layer constructs a set model
of universes and dependent functions relative to an explicit set-theory
foundation. Its declarative dependent-function fragment has proved soundness
and relative consistency, and production term/universe substitution and binder opening/closing have
exact semantic correspondences. Concrete sort and constant inference cases are
covered under their stated cache/environment premises; the new reference
specialization removes the cache premise. Full checker validity, recursive
reduction/equality and complete admission model preservation remain open.
Cached mode additionally requires semantic cache invariants. The fragment
consistency theorem is not a consistency theorem for the complete kernel.
The next layer now proves hereditary product/function validity transport and
local model bridges for actual forall, checked application and checked lambda
runs. Recursive callback soundness and checked annotation coherence remain
explicit obligations. A formal counterexample shows that hereditary validity
alone cannot replace that coherence.
The checked-annotation layer now supplies an executable sufficient guard for
structural comparison. It decides whether two binder annotations have the same
zero condition for every universe-parameter and metavariable assignment,
preserves that agreement through universe substitution, and derives semantic
regime agreement on successful guarded comparison. It also validates annotations
against actual sort-exposure visits and characterizes the existing native
positive-universe test exactly.

These operations are assurance infrastructure. Public raw-expression acceptance
does not yet run the extra guard or produce validated annotations. Recursive
typing/reduction/equality, justification of lambda regimes and full admission
soundness remain open. No new axiom or stronger foundation assumption was added.
See [the current audit and reference comparison](RESEARCH_AND_MIGRATION.md).

Lambda inference now closes its recursively inferred body type directly. The
extra cheap-beta normalization of that type was removed from the shared
production branch in both cache modes and both inference modes. The lambda
model bridge therefore no longer assumes preservation by that extra pass.
`SemanticValidityScope.lean` transports both hereditary invariants across
scoped environments and fresh-variable closing; the returned lambda type
inherits them under explicit recursive and regime premises. Let-body
normalization and ordinary WHNF/beta reduction are unchanged.

This removes one operation and its proof obligation. It does not establish
checked annotation provenance, recursive checking soundness, or consistency of
the full kernel. The selected lambda regime still needs justification from
actual checking evidence. No new axiom or stronger foundation assumption was
added.

## Correctness-first reference mode

[Reference checker plan](REFERENCE_CORRECTNESS_PLAN.md) is the active roadmap.
One checking/admission implementation now has an explicit cache-disabled
specialization. Import `Ps.KernelCore.API.Reference` for the fixed
`psKernelReference*` API; use `--reference` for exact 4.35 Arena exports or
`--reference-historical` for the pinned historical regression corpus.
Ordinary invocation retains the existing cached policy.

Reference mode ignores semantic cache entries and does not publish new ones.
Its sort/constant inference bridges eliminate cache-coherence premises.
The full recursive checker/admission theorem is still open. Certified syntax
sharing and environment indexes remain; generated PSC0 qualification remains
open. Runtime performance and acceptance equivalence of the two modes are
separate obligations.

[Proof job 114214647274](https://github.com/dwijayuda/pskernel/actions/runs/38052617458/job/114214647274) at
`52eb8e72c2f20b5328cbf531a6be119947efb946` passed **248 build jobs**, all
**84 companion files** and the **219-declaration** semantic axiom audit.
The **134-module** dependency closure contains only the 12 allowed Con Leche
pure-math modules, with zero legacy judgment or production assurance imports.
The reference-policy audit checked **1,821 definitions** with zero cached-default
fallbacks. The overall workflow failed only its separate baseline-diagnostic
setup; this proof job passed. The diagnostic was rerun independently.
[Native tests and focused runtime checks](https://github.com/dwijayuda/pskernel/actions/runs/38051925196)
at `2a34f8299060fc6e91d2fc79a18ab8fcd9d4f0cf` passed the existing native
suites plus lambda raw-type, conversion and admission tests in all four
cache-mode/sort-regime combinations. Both Arena modes passed **141/141
tutorial and 18/18 bug cases**, with zero declines. The binary SHA-256 was
`51383d1c27a78d0496b99ec29b710d9e0491c6bea1211237b436145efc87f77d`.

Fresh exact 4.35 Prelude, UTF8, XOR and Int64 closures all passed in cached
mode. Reference mode passed Prelude, UTF8 and XOR, then **timed out on Int64
at 180 seconds (exit 124)**. That is an unresolved check, not acceptance or
a logical rejection. The runtime workflow therefore failed overall; its
native/Arena jobs passed. Its old lambda companion-proof failure was repaired
in the proof job above. No runtime source changed between the native-tested
revision and the final proof revision.

Full Init/Std/Mathlib were not rerun. Their earlier timeouts and missing
qualification remain open. Small-suite success does not prove cached/reference
equivalence, universal Lean compatibility, or full-kernel soundness.

The [controlled Int64 comparison](https://github.com/dwijayuda/pskernel/actions/runs/38052827877/job/114215267947)
built checkpoint `5e3fa749` and candidate `0aa3d403` on the same runner and
fed both the identical export. **Both reference checks timed out at 180
seconds**, exit 124. Their binary hashes match the recorded pre-change and
new runtime binaries. The timeout therefore predates the lambda change; this
bounded experiment does not establish equal performance or acceptance.
The diagnostic job is green because it preserved both timeout results as data,
not because Int64 passed.

The recoverable pre-refactor branch is
`checkpoint/pskernel-core-before-cache-free-reference-20261010` at
`32fb55d651cc8228794216ae298872978f3be0f9`.

## Authoring and ownership

Use [PSC0's current bounded self-host profile](../../docs/selfhost-language/CURRENT.md).
The former PSC1-selfhost-stable/1 and PSC1-portable-selfhost/1 restrictions are
historical, not this package's authoring policy. The currently qualified PSC0
frontend still has finite capabilities; Lean-native computed fields, pointer
primitives, arbitrary effects, and Std collections are not automatically portable.
Handwritten Lean remains source authority. Joint generated compiler/kernel
qualification has not been established by copying this package.

Production source is in `src/`; `metatheory/` and `proof/` contain assurance.
`host/` handles Arena transport. `reference/` is a frozen regression oracle,
not the semantic authority. The 4.35 native-evaluation change intentionally
differs from that 4.34 oracle. Native evaluator callbacks are inert in the
production checker; their legacy helper and record types remain for source
compatibility and historical proofs.

The assurance build uses a pinned Con Leche dependency only for 12 pure
set-theoretic modules. Its checker is not a runtime dependency or fallback.
The mathematical foundation is an explicit theorem parameter, not an internal
proof of its own existence. Dependency and axiom gates run with the proof suite.

## Commands

- `lake build psc_kernel_core_arena`
- `npm test`
- `npm run test:proofs`

The cloud workflow `psc0-pskernel-core-435.yml` checks the exact toolchain,
builds the existing metatheory suite and all 84 companion proofs, runs foundations and
evaluation-order regressions, and gates Arena verdicts and case counts.
Historical Arena 4.34 exports require explicit `--check-historical`;
the default adapter requires the exact 4.35.0-rc4 metadata identity.

The preserved LEAN_4_34 documents and M3/M4 receipts describe historical
checkpoints. They do not certify this migration. Current research, changes,
and outstanding evidence are recorded in [RESEARCH_AND_MIGRATION.md](RESEARCH_AND_MIGRATION.md).

## Prior native sharing stage and its measured results

[Run 38001623085](https://github.com/dwijayuda/pskernel/actions/runs/38001623085) at
`e9b0cdae39ea9a2ff0d7da841e0faacbf7943df4` verifies the native sharing layer,
the existing metatheory proof suite and all 84 companion proof files. Foundations,
scope/cache regressions and the depth-32 shared-expression family pass.
Fresh 4.35 Prelude, UTF8, XOR and Int64 dependency closures also pass.

The pure expression specification remains in Core/Expr/Basic. Executed syntax
walks use intrinsically certified memo entries, exact input/cursor validation,
and proved compiler simplification. Prepared substitution arguments avoid
repeated lifting of closed expressions. Operation-local scratch tables are separated from persistent hash checkpoints.
Context-free operations keep a fixed memo cursor; binding-sensitive operations
advance it. The two bounded eligibility scans share one scalar worker with an
all-input refinement theorem. Scope exit restores all parent caches and metadata.

This is a **Lean-native experiment**: `portable: false` and
`jointSelfhostQualified: false` are deliberate package metadata.
The current PSC0 frontend/backend has not qualified these execution primitives.
Portable graph storage and batched telescope/context transport remain open.

**Full conformance remains incomplete, and the final native candidate regresses
in the controlled performance check.** Historical and fresh 4.35 Init/Std time
out at their unchanged 500/590-second limits; Mathlib is skipped by its
prerequisite gates. On the same 500,000-record prefix and runner, the repair
baseline completes in 143.53/142.83 seconds while the candidate times out twice
at 180 seconds. Its lower measured memory is censored by timeout. This draft
experiment is not eligible for provider promotion.
See [the exact receipt](MIGRATION_EVIDENCE.json) for all completed measurements.

The [research report](RESEARCH_AND_MIGRATION.md) compares pinned official Lean,
Con Leche, current Con Ron, Nanoda and Lean4Lean, audits historical Arena branches,
and records both successful and failed experiments. Default-provider selection
and generated compiler/kernel qualification remain separate.
