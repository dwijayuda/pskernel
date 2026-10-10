# PSKernel Core for PSC0

This is the active kernel development package at `psc0/packages/pskernel-core`.
It imports the complete source, companion proofs, and metatheory from
`pscv/prove-pskernel-core-v1` at `85ccb4e1103d77ed77c09c5795fc48ae4ea8ea62`,
with the bounded cache policy and Arena adapter from `132d817071cd62c23a70c15984d6c73e14d6e856`.

The target is **Lean 4.35.0-rc4**, commit
`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`. Run Lake from this directory:
the package has its own toolchain and does not replace PSC0's selected compiler
seed or its historical provider receipts.

## Runtime annotations and proof handoff

The annotated syntax, universe-regime test and guarded structural comparator
now have a single owner in runtime Core. The model imports those exact
operations. Their structural equivalence and transport through lifting,
substitution, free-name closing and universe instantiation are proved, together
with hereditary-validity transport. The application bridge fixes one concrete
term/result reading with all four validity facts under explicit recursive and
guard premises. Public checking and admission still exchange raw expressions;
carrying and validating these annotations throughout those paths is unfinished.
See [the work state](AI_WORK_STATE.md) and
[the continuation prompt](AI_CONTINUATION_PROMPT.md) for an exact handoff.

[Proof job 114228540945](https://github.com/dwijayuda/pskernel/actions/runs/38057387016/job/114228540945) at
`9cf6d802ea9bc33fabd220abfb38b3fe432495ba` passed **254 build jobs**, all **84 companion files**,
the **242-declaration** semantic axiom audit and **12 native annotated-syntax cases**.
The 140-module dependency closure contains exactly 12 allowed Con Leche
pure-math modules, zero legacy-judgment imports and zero production-assurance
imports. The reference-policy audit checked 1,824 definitions with zero cached
fallbacks. The complete workflow passed.

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

The executable representation and guards now live in runtime Core, with
coherence and validity transport proved in metatheory. Public raw-expression acceptance
does not yet run the extra guard or produce validated annotations. Recursive
typing/reduction/equality, global annotation coherence and full admission
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
the full kernel. The new checked lambda bridge derives its level from actual codomain-sort
visits; their recursive soundness and global annotation coherence remain open. No new axiom or stronger foundation assumption was
added.

Checked lambda inference now obtains its codomain sort from an additional
infer-only visit to the actual body type followed by sort exposure. The
reference lambda trace records these calls. The new
`lambda_trace_checked_reading` theorem fixes that actual level on both the
lambda and its returned type and proves typing plus their four hereditary
validity facts under the local recursive obligations. It no longer asks for an
arbitrary lambda level or a separate proof-valued-fibre premise.

This certification runs in the shared checked lambda rule in both cache modes.
Infer-only retains its validity precondition, and cached hits retain their
separate cache invariant. Non-resource certification failures decline;
resource failures keep their resource classification. Globally coherent
annotations through raw comparison, joint recursive soundness, and full safe
admission remain open. The public API does not yet return or carry a complete
validated annotated expression.

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

[Proof job 114221834109](https://github.com/dwijayuda/pskernel/actions/runs/38055104083/job/114221834109)
at `2baa33e165f914d14f635d68934293e3fcea89ed` passed **249 build jobs**,
all **84 companion files** and the **221-declaration** semantic axiom audit.
The **135-module** dependency closure contains only the 12 allowed Con Leche
pure-math modules, zero legacy judgment imports and zero production assurance
imports. The reference-policy audit checked **1,824 definitions** with zero
cached-default fallbacks. The complete final audit workflow passed.
[Native and conformance run 38054667785](https://github.com/dwijayuda/pskernel/actions/runs/38054667785)
at `e600c3ac862e68009511f778203758415838a9df` passed the native suites,
lambda type/conversion/admission tests and the new checked-only certification,
decline and resource-classification cases. Both Arena modes passed
**141/141 tutorial and 18/18 bug cases**, with zero declines.

Fresh exact 4.35 Prelude/UTF8/XOR/Int64 closures all passed in cached mode.
Reference mode passed Prelude/UTF8/XOR, then **timed out on Int64 at 180 seconds,
exit 124**. That check remains unresolved; the runtime workflow failed overall
on this timeout. Full Init/Std/Mathlib were not rerun, and their earlier
qualification gaps remain open. No general compatibility, mode-equivalence or
performance claim follows from these focused checks.

The final source adds an explicit local type annotation required by PSC0's
authoring guide. Its [cloud rebuild](https://github.com/dwijayuda/pskernel/actions/runs/38055104083/job/114221834301)
matched the runtime-tested binary's SHA-256 exactly:
`dc710ab555596a973a1bb301e52da1f5adf414ade63aeb691ba2cb6717016ce6`.
The final audit above therefore applies to the final typed source, with
executable evidence tied to the matching binary. Generated PSC0 qualification
remains separate.

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
