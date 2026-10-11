# Portable native proof goals

The native semantic compiler owns typed goals; official Lean checks completed
terms. There is no host tactic fallback, extra proof axiom or pskernel-core path.
This implementation begins the required tactic family; it does not complete it.

## Invariants

Each goal is a typed metavariable with its captured local context. All sibling
goals share constraint state and a monotonically increasing local-ID allocator.
Every assignment checks its expected type. Intro records a deferred binder
closure: solve and substitute the child first, then abstract its introduced
local. Abstraction before substitution would permit future free locals to escape.
Closures discharge from innermost to outermost. The final result contains no
term holes and follows the ordinary declaration/kernel pipeline.

Proof AST nodes retain lexical namespace/open context. Terms inside tactics use
the same application grammar as ordinary terms. Section dependency collection
is static, while name resolution runs against each goal's actual local context.
Consequently a newly introduced local can shadow a global or an outer binder.

The initial registry includes exact, refine, apply, intro, assumption, rfl,
constructor, focus, all_goals, any_goals and middle-dot bullets. Application opens typed metavariables
and orders nondependent obligations first. Constructor candidates and assumption
attempts own snapshots; failed attempts do not leak assignments. Focus isolates
one goal; bullets additionally require it and all generated subgoals to close.
A successful tactic is never sufficient evidence to admit an incomplete proof.

## Pinned reference and remaining scope

Lean 4.35.0-rc4 commit c29b6dda4f7c20e3eeaa717c4e565663c5cfa364:
- src/Lean/Meta/Tactic/Apply.lean: MVarId.apply and reorderGoals.
- src/Lean/Elab/Tactic/Basic.lean: focus, focusAndDone, getUnsolvedGoals.
- src/Lean/Parser/Tactic.lean: tactic sequence and bullet categories.

Remaining required clients include case/next/combinators,
additional introduction/elimination, rewriting, simplification, omega/grind,
intermediate facts, structured calc and contract/effect verification. Intro
patterns and named holes need their explicit selected syntax. Data/Prop and
library completeness remain independently tracked. Source-printer support here
prints proof syntax only; no compiler-source .ps conversion or self-host runs.

Compact qualification extends the existing composite with proof-producing
clients, nested scopes and four executable values. Six refusals protect holes,
unsolved goals, bullet completion, reflexivity and the uniform application rule.
The full native cloud workflow passed at 5d63d8962084a8df15f318610646f6d30ed42308,
run 38178805422. Exact evidence is recorded in AI_WORK_STATE.md.


## Logical prelude

Connectives.lean adds checked definitions/inductives for And, Iff, Or, Exists
and Not. And/Iff carry singleton eliminators and ordinary proof projections;
Or/Exists retain Prop-only elimination. No axiom is added. Existing Core universe
and recursor metadata represent these families without a separate proof calculus.
The same native composite now checks construction, projections, existential
witnesses, and independently introduced sibling goals; a negative case protects
Or's large-elimination restriction. The full native cloud workflow passed at a8fbc17f1ad2d24efbde14a7cbe993a4400d4c01,
run 38179168385: 329 fixture declarations, 61 phase-specific refusals and 111
shared TypeScript/Rust observations.

## Local facts, target selection and existential notation

Term/tactic have share local-value elaboration with let. During body elaboration,
have introduces an ordinary opaque local binding while let introduces a reducible
local definition. Both eventually close to ordinary checked Core let terms.
Tactic locals extend only the focused goal; deferred scope closure substitutes
solved children before abstracting locals. Completed facts cannot retain holes.
Named and anonymous-this facts and nested by blocks use ordinary term checking.
Patterns, local function headers and let configuration flags remain pending.

Term show lowers to a type ascription. Tactic change checks definitional equality;
tactic show tries goals in order with independent source/unification snapshots and
moves the first match to the front. Hypothesis locations remain pending.

Existential Unicode/text notation follows the pinned explicitBinders macro:
typed parenthesized groups or a single unbracketed optional-type group expand
into nested Exists/lambda applications. Its per-name annotation copying follows
Init/NotationExtra.lean and is distinct from native forall group elaboration.
This adds no kernel expression or proof authority.

References at the pinned RC4 commit: Lean/Elab/Binders.lean (nondependent lets),
Lean/Parser/Term.lean (have/show), Init/Tactics.lean (show/locals) and
Init/NotationExtra.lean (existential grammar and expansion). Qualification pending
the next exact cloud run; no full-v7 completion claim.
