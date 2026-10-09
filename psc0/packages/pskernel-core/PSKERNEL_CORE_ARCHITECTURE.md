# PSKernel Core architecture for PSC0

This is the current guidance for `psc0/packages/pskernel-core`.
The user-selected semantic target is Lean **4.35.0-rc4** at
`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`. The source authority is handwritten Lean,
using [PSC0's current bounded self-host language](../../docs/selfhost-language/CURRENT.md).
The former PSC1-selfhost-stable/1 and PSC1-portable-selfhost/1 profiles do not
constrain this migration.

## Source and semantic authority

Keep one production semantic implementation rooted at `Ps.KernelCore.SelfHost`.
Core owns expressions, levels, declarations and substitution; Environment owns
semantic declarations and derived lookup structures; Checker owns inference,
reduction, recursors and definitional equality with one recursive wiring owner
in Checker/Knot; Admission owns declaration transactions; API owns
KernelContract-v1. Runtime/Acceleration may preserve an existing judgment but
must not create a semantic fact.

Host transport, reference kernels, tests and metatheory stay outside the
production closure. Import fences and ownership are recorded in
`PSKERNEL_ARCHITECTURE.json`. GitHub remains canonical; follow
`GITHUB_FIRST_WORKFLOW.md` and the user's cloud-only execution instruction.

## Current profile and preservation requirements

Use the qualified PSC0 frontend's actual finite capabilities. Structural workers
may carry changing arguments around their decreasing Nat/List argument. Explicit
types, flat matches, immutable records and Except/Option remain appropriate.
General do notation, computed fields, host pointer operations and arbitrary Std
collections are not made portable by using a newer Lean compiler.

The migrated source has not yet earned joint generated compiler/kernel
qualification. Preserve the selected PSC0 compiler seed and existing provider
selection until their separate exact-source qualification and explicit selection.
This package has its own Lake toolchain so that 4.35 kernel work does not silently
repin the 4.34 compiler recovery path.

## Trust and compatibility

Fail closed on invalid input, unsupported cases, exhaustion and internal errors.
Never substitute an alternate checker after failure. Hash equality is not term
equality. Cache validity must include local context, environment and checking
mode; the definitional-equality cache must not infer transitivity from pair tests.

Lean 4.35 removes compiler-backed Lean.reduceBool/Lean.reduceNat reduction.
`psKernelReduceNative` is therefore inert regardless of legacy evaluator fields.
The historical helper is retained for source compatibility and proof history,
not as an active 4.35 capability. `PSKERNEL_TCB.json` records this distinction.

The frozen reference and LEAN_4_34 inventories are historical comparison material.
They do not override the 4.35 target. The target delta and exact upstream source
identities are in `RESEARCH_AND_MIGRATION.md`. No end-to-end consistency theorem
is claimed while the final semantic refinement obligations remain open.

## Evidence and next stage

Require the full metatheory, all 84 companion proofs, foundation tests and
evaluation-order regressions for coherent kernel changes. Report complete Arena
coverage and verdicts, including declines and timeouts. Historical exports use an
explicit adapter mode; fresh 4.35 exports use exact version and commit checks.
An accepted prefix does not certify Init, Std or Mathlib.

The current stage migrates the latest kernel/proofs and fixes confirmed dispatch
and target-compatibility defects. Stored hashes/variable summaries, DAG-aware
substitution and refined cache scopes are the next performance stage. Their
representation and erasure invariants must accompany implementation. Generated
JavaScript must never be patched to change kernel semantics.

## Sharing execution experiment

The architectural stage is now active. The native candidate uses one certified
cursor-aware syntax fold for node counts, variable queries, lifting, term and
universe substitution, and free-variable abstraction. Every memo entry carries
an equality to the pure fold. Address/cursor keys select candidates only; a hit
checks the actual node and cursor. A memo belongs to one fixed operation and its
parameters. No semantic checker, admission rule, cache transitivity rule or
timeout changes in this experiment.

Core/Expr/Basic retains the pure expression definitions. Core/Expr/Shared and
Core/SharedMemo contain safe Lean proofs and compiler-simplification equalities,
so native calls execute the proved traversal. This uses Lean's existing
withPtrAddr/withPtrEqDecEq contracts, Squash and Std.HashMap. It introduces no
project-defined unsafe code or unchecked cast.

This is **native-only experimental support**, not evidence that the current
PSC0 bounded frontend/backend supports those primitives. Joint generated
qualification remains false. The portable pure definitions are still the
semantic specification; promoting this execution layer to generated PSC0
requires explicit runtime support and preservation/qualification evidence.
The explicit portable graph/storage design in the research report remains the
alternative if that extension cannot be qualified. Neither path may silently
replace the default provider.

Cloud validation must check the general fold/refinement proofs, the existing
metatheory, shared terms with cursor changes, all constructors, and the unchanged
Arena corpus limits. No corpus completion is claimed before those runs finish.
