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

## TypeScript/npm resolution evidence for the first FFI package policy

The host-side policy follows the repository's TypeScript study/reference role:
named ESM imports are resolved by TypeScript/Node as runtime modules, but their
package metadata is not proof evidence. The first project policy therefore
pins direct package roots to exact installed versions and fingerprints that
runtime policy separately from pskernel project integrity.

No claim is made yet about transitive npm lockfile closure. Semver ranges,
subpaths, builtins, and alternate module systems remain unsupported until their
runtime reproducibility and ABI story is specified.

## npm package-lock v3 evidence for transitive FFI assurance

The transitive FFI policy was checked against current npm package-lock
documentation in addition to the repository's TypeScript host references. npm
documents `package-lock.json` as the exact dependency-tree representation and
documents lockfile-v3 `packages` entries with package locations, exact
versions, `resolved` sources, SRI `integrity`, and dependency metadata.

ProofScript uses those fields only for runtime reproducibility/assurance. They
do not define ProofScript semantics and are not proof evidence. The checked
core and pskernel remain independent of npm. The first implementation also
keeps verified source checking independent of installation state; lock closure
validation begins only when verified build/run claims an executable host
runtime.

The repository's TypeScript study material remains relevant to ESM/host module
resolution and emitted import behavior. npm lock metadata supplements that host
layer; it does not flow backward into theorem elaboration.

## TypeScript/Node evidence for bounded package subpaths

The TypeScript study corpus documents package.json exports support under
`node16`, `nodenext`, and `bundler` resolution. The current verified
backend uses TypeScript `Bundler` resolution, so generated named ESM subpath
imports already pass through that host resolver.

Current Node package documentation defines `exports` as the public package
entry-point map, including explicit and patterned subpath exports, and states
that unexported subpaths are encapsulated. Node's ESM resolver selects runtime
conditions while TypeScript may additionally select `types` conditions.

ProofScript therefore records/pins the package **root** and leaves public
subpath resolution to those host tools. This is a host interoperability
decision only; neither resolver nor package exports metadata influences
pskernel proof admission.

## Stdlib reference policy

The first ProofScript-written stdlib tranche uses the v0.7 language reference
for intended surface examples and Lean 4.34 `Init.Data.Option` /
`Init.Data.List` as semantic/API inspiration. Lean source is a reference, not
code to copy wholesale: only operations that the current verified ProofScript
language can express without semantic shortcuts should enter `stdlib/`.

Because the current runtime erasure owns metadata only for checked-project
inductive admissions, the initial executable stdlib uses source-owned
`PsOption`/`PsList` rather than claiming that Prelude `Option`/`List`
already compile through verified IR. That limitation should be removed by an
explicit checked-runtime-metadata design, not by weakening erasure provenance.

## Lean 4.34 reflexivity evidence

The bounded standalone `rfl` checkpoint was derived from:

- `study/lean4-4.34.0/src/Lean/Meta/Tactic/Refl.lean`, where core equality
  reflexivity checks definitional equality and assigns `Eq.refl`;
- `study/lean4-4.34.0/src/Lean/Meta/Tactic/Rfl.lean`, where full Lean
  `applyRfl` extends that behavior to `HEq` and relations registered in a
  discrimination-tree-backed `@[refl]` environment extension;
- `study/lean4-4.34.0/src/Lean/Elab/Tactic/Rfl.lean`, which exposes the tactic
  layer without moving proof authority out of Meta/kernel checking.

ProofScript currently implements only the first Eq case and explicitly records
the remaining HEq/`@[refl]` behavior as unsupported rather than silently
claiming full Lean `rfl` parity.

## Lean induction naming evidence

The induction branch naming checkpoint follows the pinned Lean 4.34 induction
implementation. `Lean.Meta.MVarId.induction` exposes the introduced minor
premise fields, while the elaborator supports user-facing alternative variable
names around those fields. ProofScript's bounded flat tactic syntax does not yet
implement Lean's full `with | ctor ... =>` alternative grammar, so the current
small step preserves constructor binder names by default and names a direct
recursive hypothesis `<field>_ih`. This is a source-context convenience only;
recursor semantics remain unchanged.

## Lean library-search zero-subgoal application checkpoint

Pinned Lean 4.34 `Lean.Meta.Tactic.LibrarySearch` applies candidate lemmas and
then uses `solveByElim` for generated subsidiary goals. The current
ProofScript `exact?` broadening implements only the prefix of that behavior
that creates **no remaining goals**: candidate implicit/default arguments may
be inferred from the target, but every inserted metavariable must be resolved
by target unification itself.

Candidate application is trialed in an isolated ExprMetaContext. This preserves
Lean-style metavariable experimentation without allowing failed search
candidates to mutate the live elaboration state. Strict/instance implicit
search, symmetry/Iff alternatives, relevance indexing, and recursive
`solveByElim` remain explicit future work.

## Stdlib simplifier dogfood checkpoint

The bounded simplifier is exercised by
`ProofScript.Data.Option.optionGetOrElseNoneSome` in the end-to-end stdlib
project. The proof uses the explicit rules `optionOrElseNone` and
`optionGetOrElseSome` rather than Lean's global simp environment. Both rules
satisfy the current strict structural-decrease test, are pairwise
non-overlapping, and have all generic parameters constrained by ordinary value
terms. This remains intentionally narrower than Lean 4.34's simplifier, while
proof reconstruction continues through kernel-checked Eq transport.

## Lean 4.34 exact-search symmetry checkpoint

Pinned `Lean.Meta.Tactic.LibrarySearch.librarySearchSymm` searches both the
original goal and a symmetry-transformed goal, interleaving candidates from the
two searches. ProofScript now owns the smallest corresponding slice for
ordinary `Eq`: deterministic local/environment candidates are tried directly
and symmetrically, and a symmetric zero-subgoal hit is reconstructed with the
real `Eq.symm`. This does not imply support for Lean's Iff direction search
or recursive `solveByElim` discharge.
