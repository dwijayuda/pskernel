# Native proof erasure and evaluation boundaries

Proof payloads have no runtime representation. A proof parameter of a
computational function nevertheless retains an ignored Unit slot. Function
types, unary function values, flat declaration entries, application completion,
special builtin completion and supplied calls use the same convention. Proof
locals stay in the Core context for dependent typing and on the erased-local
list; the ignored IR parameter is never exposed as the proof's runtime value.
Names are reserved independently to avoid capture.

This boundary is semantically necessary. A term of type False -> Nat is a
function value, even when its body eliminates False. Erasing its lambda would
evaluate an impossible branch while merely passing the function. Likewise a
constrained indexed recursor's induction hypothesis can have type
Eq childIndex requiredIndex -> Result. Context reversion may pass that function
without ever applying it; it must not force Result before the equality is given.

Proof-returning declarations and proof arguments' payloads remain erased.
Supplied proofs become Unit literals without evaluating their terms. Fully
applied logical eliminators keep their existing checked lowering: equality
transport requires matching erased representations, and contradiction becomes
typed unreachable IR. No casts, fabricated proofs, or kernel changes are needed.
Type-parameter transport and constructor field layouts remain separate concerns.

The pinned Lean [LCNF type conversion](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Compiler/LCNF/Types.lean)
similarly preserves forall arity with erased domains. Its
[Core conversion](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Compiler/LCNF/ToLCNF.lean)
handles proof overapplication explicitly. This portable compiler uses existing
typed Unit slots rather than importing that host IR. Removing slots is a future
whole-call-graph optimization and must preserve partial application and evaluation
boundaries; dropping them locally is unsound operationally.

Validation extends the existing application with two unused False -> Nat values
(a lambda and a partially applied declaration), in addition to the nested indexed
tail that exercises proof-guarded induction hypotheses. The same native build,
official Lean checking, typed IR, strict TypeScript and JavaScript path qualify
the change. Exact run evidence belongs in AI_WORK_STATE.md.

## Checked field layout

Constructor and structure metadata now records the checked field count separately
from the runtime field list. Stored fields retain original source argument and
projection indices. Proof fields are opened in the Core telescope but omitted
from that list, including leading, interleaved and trailing proof fields.
Constructor saturation and partial completion use checked arity, while records
and tagged runtime constructors use only the stored field list.

Recursor minors consume exactly the checked field count before opening IHs.
They skip proof payloads without shifting the remaining binders. Structure
recursor flags likewise use original projection indices. This one layout is
shared by constructor emission, match binders and structure projections; it
avoids compacted-index guesses or special cases for the final proof field.

Proofs depending on earlier fields still belong to ordinary source elaboration
and kernel checking. This change does not admit Type/existential fields, arbitrary
proof-valued uniform parameters, or Prop-family runtime data. Function-typed
runtime fields can still accept proofs: their ignored Unit call slots follow the
evaluation-boundary rule above, unlike proof payload fields which store nothing.

Proof-carrying fields also exercise polymorphic proposition applications.
The shared unifier now checks a candidate assignment against its metavariable's
declared type before assignment, using the same bounded worker and transactional
context. This constrains universes when an implicit type parameter is inferred
(for example A : Sort u instantiated as Nat), instead of relying on explicit
type arguments. Occurs and local-scope checks remain in the assignment store.
The pinned [RC4 assignment checker](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Meta/ExprDefEq.lean)
likewise checks candidate types. Match-specific universe reconciliation is no
longer necessary and has been removed.
