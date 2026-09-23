# Study reference policy

Status: **normative anti-drift research policy**

The checked repository is the source of truth for implementation state. The
`study/` tree is the source-of-reference collection used to answer semantic,
surface-language, backend, and tooling questions before changing that state.

## Reference precedence by concern

### Lean semantics and theorem-prover behavior

Primary:

- `study/lean4-4.34.0/`

Use the pinned Lean 4.34.0 source for kernel, Meta, elaboration, tactic,
recursor, equality, simplifier, parser, and runtime-semantic questions. When a
ProofScript feature claims Lean-compatible behavior, implementation work should
locate the corresponding Lean source path before changing semantics.

Secondary documentation:

- `study/lean4-language-reference/`

Use the generated Lean language reference to understand documented user-facing
syntax and behavior. If prose and executable Lean source appear to differ,
inspect the pinned source and tests before deciding implementation semantics.

Implementation cross-check only:

- `study/lean4lean-master/`

lean4lean is useful for an independent implementation perspective and for
finding smaller representations of Lean behavior. It does not override the
pinned Lean 4.34.0 source or pskernel's explicit compatibility gates.

## ProofScript language intent

Primary:

- `study/proofscript-language-reference-v0.7.0/`

The v0.7.0 authoritative draft is the current intended language-design
reference in the study corpus. In particular, preserve its central rule that
ProofScript may use a friendlier surface while Lean semantics remain
authoritative where dependent types, proofs, recursion, typeclasses, and tactic
meaning are involved.

Historical comparison:

- `study/proofscript-language-reference-v0.6.1/`

Use v0.6.1 to understand earlier decisions, compatibility changes, and
regressions. It must not silently override a deliberate v0.7.0 revision or the
current repository architecture.

The active repository docs and executable gates can be newer than both study
references. When they are newer, record the intentional revision rather than
quietly treating an old reference as current implementation truth.

## TypeScript and JavaScript ecosystem behavior

Primary study corpus:

- `study/typescriptlang/`

Use this material for TypeScript syntax/API conventions, compiler emission,
module resolution, ESM/CJS behavior, declaration files, source maps, project
references, and editor/tooling integration.

TypeScript documentation does **not** define ProofScript proof semantics,
dependent type theory, erasure correctness, or theorem acceptance. Backend
convenience must never flow backward into pskernel or Lean-compatible
elaboration.

## Required workflow for semantic changes

Before a Lean-sensitive language or theorem-prover change:

1. identify the current repository implementation and active plan;
2. inspect the relevant pinned Lean 4.34 source;
3. inspect the Lean language reference when user-facing syntax is involved;
4. inspect ProofScript v0.7.0 for intended surface/compatibility constraints;
5. use lean4lean only as a secondary implementation cross-check when useful;
6. inspect TypeScript references only if the change reaches compiler/backend,
   modules, declarations, JavaScript emission, or editor integration;
7. implement the smallest faithful supported slice;
8. add an executable regression for the accepted behavior;
9. keep unsupported neighboring behavior fail-closed;
10. report which gates actually executed.

## Conflict handling

Do not silently reconcile conflicting sources.

- Repository implementation state answers "what exists now".
- The active architecture/plan answers "what this repository currently intends
  to build".
- Lean 4.34 source answers "what Lean-compatible semantics require".
- ProofScript v0.7.0 study material answers "what the referenced ProofScript
  surface intended at that checkpoint".
- TypeScript study material answers host ecosystem questions.

If these disagree materially, document the conflict and make an explicit
architecture/spec revision before broadening support.

## Current examples

The current tactic work follows this policy:

- `refine`: checked against Lean's term-with-holes/refine elaboration;
- `constructor`: checked against Lean Meta's constructor-via-apply behavior;
- `cases` / `induction`: checked against Lean recursor/elimination behavior
  and pskernel's generated recursor binder order;
- `rw`: checked against Lean 4.34 Rewrite and the `rw` macro, including its
  post-rewrite cheap-rfl attempt;
- `simp only`: the first bounded slice reuses kernel-checked equality transport
  to a terminating fixed point and keeps Lean's broader simp database,
  preprocessing, congruence, and orientation machinery explicitly unsupported.

The dual-source `.ps` / supported `.lean` plan also follows the policy:
Lean syntax is bounded explicitly, both source forms converge before checked
core, and TypeScript remains only the downstream host/backend target.

## Evidence-driven correction recorded 2026-09-23

While replacing the first simp smoke test, the repository exposed a current
surface limitation: `V061TypeExpr` accepts applications only when the applied
result is itself a sort. That limitation is now partially closed: nested named applications in a
theorem/result type elaborate as ordinary terms, while the final declaration
type must still inhabit a `Sort`. Thus `Eq (Nat.succ a) a` is now a valid
checked header form. The remaining gap is syntactic breadth (operators,
literals, lambdas/matches as needed, and native infix `=`), not permission to
bypass the final type check.

## Study-driven theorem statement checkpoint

The ProofScript v0.7 reference explicitly uses theorem statements such as
`n + 0 = n`. The verified frontend now supports that shape using the existing
Nat operation semantics rather than a theorem-only parser/elaborator shortcut.
This was also used to split the oversized notation elaborator into focused Nat,
Bool, support, and dispatcher modules so reference-driven surface growth does
not violate the repository source-shape gate.

## Lean 4.34 precedence evidence for theorem Bool terms

The pinned `study/lean4-4.34.0/src/Init/Notation.lean` declares both
propositional `=` and Boolean `==` at precedence 50. ProofScript's current
expression table intentionally orders `==` above the outer theorem
propositional equality layer. Therefore canonical lowering must parenthesize
that subtree instead of assuming the two parsers choose the same tree.
The Bool theorem-term checkpoint follows that rule and continues to use the
existing verified Bool/BEq elaboration helpers.

## Dependent Pi reference evidence

The authoritative ProofScript v0.7 reference explicitly lists dependent
functions and gives the type example `(x : Nat) -> Fin x -> Nat`. The pinned
Lean 4.34 parser models dependent arrow as a bracketed binder followed by
`->`/Unicode arrow at arrow precedence. The implemented checkpoint follows
that model for one explicit named binder and lowers/elaborates to ordinary
kernel `forallE`; it does not introduce a ProofScript-specific dependent
function semantics.

## Lean 4.34 exact-search evidence

Pinned Lean 4.34 implements `exact?` through
`Lean.Meta.Tactic.LibrarySearch`: relevant declarations are indexed, each
candidate may be applied, generated subgoals may be discharged by
`solveByElim`, symmetry and Iff directions can be considered, and
`exact?` requires a complete solution.

The ProofScript checkpoint deliberately implements only the subset for which
those extra mechanisms are unnecessary: exact local hypotheses and
zero-subgoal environment constants. This preserves the central Lean rule that
`exact?` must close the goal while avoiding an invented approximation of
full library search.

## ProofScript canonical-printer evidence

The DS1 canonical ProofScript printer follows the current parser plus the
authoritative v0.7 owned D/E forms: D-call, explicit parameter groups,
declaration semicolons, braced structure/class/inductive/match/where forms, and
Lean vocabulary for lambdas/proofs. Where the broader v0.7 reference shows
syntax the current parser has not implemented (for example braced tactic
blocks), the printer emits the parser-supported canonical subset instead of
claiming unreadable conformance. TypeScript references are not semantic
authority for this source canonicalization.

## DS2 Lean parser reference checkpoint

The first Lean-subset parser tranche was checked against the pinned Lean 4.34
command/term/tactic parser sources, especially:

- `study/lean4-4.34.0/src/Lean/Parser/Command.lean`
- `study/lean4-4.34.0/src/Lean/Parser/Term/Basic.lean`
- `study/lean4-4.34.0/src/Lean/Parser/Tactic.lean`

Only canonical syntax already emitted by psc is accepted in DS2.1. Broader Lean
parser capabilities in those sources are evidence for future explicit subset
work, not permission to accept unsupported syntax.

## Lean module-header evidence for DS5

The shared import header was checked against
`study/lean4-4.34.0/src/Lean/Parser/Module.lean`. The ProofScript v0.7 study
reference does not define a competing module-import surface, so the bounded
dual-source project layer adopts the Lean-compatible `import Foo.Bar` header
for both source kinds rather than inventing a second spelling.

Only the common logical-module header is inherited. Lean's broader module
header features such as `public`, `meta`, `all`, package facets, and the
full Lake resolver are not implied by this checkpoint.

## Source FFI design provenance

The authoritative ProofScript v0.7 study reference does not specify a concrete
`extern`/JavaScript FFI declaration. The landed
`extern function ... from "..." import ...;` form is therefore an explicit
repository design revision, not a claim of v0.7 source conformance.

Its logical treatment follows the existing pskernel/checked-core external
boundary: the signature is an opaque assumption and host execution is never
proof evidence. The named ESM host form is informed by the TypeScript/JavaScript
study material and existing verified TypeScript emitter, but those host
references do not define theorem or type-theoretic semantics.
