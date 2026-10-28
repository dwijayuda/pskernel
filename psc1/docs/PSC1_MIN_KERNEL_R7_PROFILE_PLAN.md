# R7 actual recursive caller correspondence: experiment plan

Status: adopted scoped qualification passed at 6a22235dfc235b1707bed3c5d5204b6aa1f01217:
ten reports (three axiom-free, seven propext-only) and 264 native/generated cases.
Broader/installed evidence is terminal green at the source-equivalent CI SHAs in
the [R7/R8 guideline](PSC1_MIN_KERNEL_R8_GUIDELINE.md). The sequence below is
historical. Full compiler qualification remains open; prioritize actual modules.
Parent usability source: eea9306384ab68c220bece18e769fd16d7903f3a.
The [usability/full-compiler contract](PSC1_MIN_KERNEL_USABILITY_PLAN.md) remains
the overall completion definition. This is one C2 component, not C1/C2/C3 completion.

## Chosen actual caller domain

Import the real psEraseRuntimeExprWithFuelWorker and its public wrappers.
An independent pure operational source relation covers Nat/String literals and
Core zeta steps. It uses the existing Core psExprInstantiate1 operation; independent
de Bruijn/substitution correctness and typed source semantics remain obligations.
The target relation evaluates literal IR values. Eligibility restricts actual
type/proof-let branches and finite fuel without assuming any erasure result.

Prove by eligibility induction that the actual recursive worker, with its real
nested-scope transition, returns an IR value matching the source literal/zeta
derivation. Include zero-fuel refusal, nested-scope preservation/idempotence,
public/default wrapper connection and a bridge to R5's Nat IR semantics.
Runtime lets, variables/calls, freshness, classifier/type soundness, closures,
target engines and full recursive compiler preservation stay outside this batch.

## Qualification sequence

First build the proof-only roots and print ten fresh unique dependency reports.
Every report must be axiom-free or exactly propext-only; no sorryAx/choice/quotient
dependency. Preserve all R0–R6 guards and the existing 10/10/20 minute budgets.

After proof elaboration succeeds, qualify native and actual generated caller
paths from a separately registered test module, including short-fuel refusals
and multi-step type/proof-let chains with Unicode/NUL literal values. Independently
check exact source admissions and keep source/IR policies separate from semantics.
The draft native/generated harness is not qualified until its Linux checks pass.

The current usability tarball remains pinned to its source; this isolated branch
does not replace its qualification. Adoption requires exact diff review and
nonforce expected-HEAD updates preserving primary-branch history.

## Observed CI bootstrap defect

At usability source eea93063, source-trace restored its Lean cache and then spent
the entire 20-minute job budget downloading an unnecessary elan installer. Retry
is retained as separate evidence. Cache-aware bootstrap reuses an existing elan;
cold installs have bounded download/installer attempts. Toolchain pins, test
bodies and job budgets do not change. Its effect on the source-trace workflow
must be validated by selected CI after adoption; the isolated proof run alone
does not qualify a reusable workflow that it does not call.
