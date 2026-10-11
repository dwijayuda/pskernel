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
