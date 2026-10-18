# M3+B named and generalizing matches: implementation design

Status: researched design, not implemented or qualified. This is remaining
selected M3+B work (v7.2 P-MATCH-NAMED and P-MATCH-DEPENDENT), not a new roadmap
milestone. Compiler inputs .lean and .ps must share the typed semantics.

## Pinned primary references

Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc:
- src/Lean/Parser/Term.lean matchDiscr/generalizingParam/match.
- src/Lean/Elab/Match.lean elabMatchTypeAndDiscrs, withEqs,
  elabMatchAltView, generalize, discriminant-refinement loop, elabMatchAux.
- src/Lean/Meta/Match/Match.lean withEqs, withAlts/mkMinorType, mkMatcher.
- src/Lean/Elab/PreDefinition/Structural/{Main,BRecOn,IndPred}.lean.
- tests/elab/match3.lean ex7/ex7' and head; match2.lean Bla.isNat2?;
  matchGenIssue.lean; matchGenBug.lean; discrRefinement{,2}.lean.
Upstream test sorry/axiom fixtures are reference data, never implementation
authority to admit holes or additional assumptions.

Native generalization defaults true. It extends the match telescope with
dependent ordinary locals and substitutes free-variable discriminants, skips
let declarations, checks the resulting type, and preserves pattern shadowing.
false disables this optional generalization; it does not erase mandatory index
refinement or permit type-incorrect branches. Named hypotheses have Eq/HEq
orientation ORIGINAL discriminant = branch pattern. The matcher receives actual
reflexivity arguments; these hypotheses are not automatically solved constraints.
The native ex7 explicitly disables generalization so h1/h2 retain original a.

## Shared syntax and lexical ownership

Retain optional generalizing intent and an optional equation name WITH each
discriminant, avoiding parallel lists. Both owned parsers recognize the pinned
match-specific parameter and named discriminants before ordinary term parsing;
nomatch and pattern-derived forms keep their selected grammar. Source visitors,
scope resolution, recursion/capture walks and printers preserve this metadata.
Equation names enter only branch scope, with checked duplicate/shadowing rules.
Computed discriminants retain the existing once-evaluated inaccessible aliases.

## Typed matching owner

Extend the existing PsElabMatchPlan and PatternMatrix rather than introducing
another matcher. Keep checked constructor coverage, first-match row priority,
complete elimination slots, actual recursive-field types and impossible-case
elimination. Separate named equations from index constraints:
- Index constraints remain automatic Eq/HEq refinement/contradiction evidence.
- Named equations remain visible checked proof binders in actual minor targets.
- Reconstruct reflexivity with the actual equality kind after applying the
  completed motive to original indices/major; no fresh motive fvar may escape.
- Bind the named proof before invoking a branch consumer and close its real
  lambda after dependent locals. Do not silently substitute it away.
- Preserve original lexical discriminant names where native named equations
  require them; pattern variables may shadow those names.
- Irrefutable columns still bind correct reflexivity, including multiple or
  computed discriminants, even when no constructor split is needed.
- The generalization policy controls optional dependent-local abstraction.
  Audit it separately from mandatory indexed equality transport and let capture.

## Required structural ownership integration

Do not merely add named equality to the legacy direct structural IH motive.
That produces an IH requiring original-parent = recursive-child, which is
generally unprovable. This is a missing ownership separation, not an application
problem to patch by fabricating a proof or dropping the equation.

The existing shared PreDefinition route already checks bodies against ordinary
provisional peer parameters, then MutualStructural specializes real constructor
branches, rewrites only checked strict-child calls, constructs independent
recursor motive families, and proves exact source equations. Its application
view retains post-major suffixes, including actual generalized/equality inputs.
This is the appropriate owner for named/generalizing recursive matches.

Inspect Command's remaining plain explicit-definition route before changes.
It currently selects the older direct-IH mechanism outside sections, while
where/omitted-header/section/mutual bodies already use shared PreDefinition.
Prefer one coherent typed owner over a named-match-only source retry. Account
for registration/privacy/proof behavior, generated eq_def identity, existing
indexed and positive-function recursion, nested-slot limits and performance.
Do not discard a working capability during routing consolidation.

WF/P0/P1 must use the same checked source match metadata. In particular explicit
generalizing=false can leave a WF callback dependent on the original major;
decrease evidence must use actual named equality transport, never an alias
that changes an outer hypothesis's type.

## Focused qualification

Extend existing paired actual-input and indexed-match fixtures:
1. Native match3 ex7-shaped positive with generalizing=false and real named Eq.
2. Explicit true/default dependent context refinement with proof consumed.
3. Irrefutable, computed and two-discriminant names; branch/pattern shadowing.
4. Indexed named HEq and impossible constructor branches checked by the kernel.
5. Recursive named matches through shared structural/WF owners, retaining exact
   source equations and actual output on the existing five target lanes.
6. Wrong equation orientation/type, leaked names, invalid option/placement,
   duplicate binders, nonexhaustiveness and nondecreasing recursion still reject.

Use independent pinned Lean controls plus actual .lean/.ps parsing/elaboration.
Do not infer parity from a host oracle, printer round trip or AST-only probe.
Official checking, foundation assumptions, readable output and ordinary versus
verified assurance boundaries remain unchanged. No host frontend in the
portable closure, new axiom, PSKernel-Core, self-hosting or budget increase.

Original design guided by upstream algorithms; preserve Apache-2.0 attribution.
