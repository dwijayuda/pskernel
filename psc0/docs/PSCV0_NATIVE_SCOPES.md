# Delayed term-scope abstraction

Core uses locally nameless binders: local identities during elaboration and bound
indices in closed expressions. Abstracting an unsolved metavariable first is
incorrect because a later assignment can introduce a local that was already
removed. The invariant is shared by lambda, forall, let/have, record update and
tactic-introduction scopes.

Meta/Context now retains typed delayed assignments. Elab/Abstraction closes a
term immediately when its remaining holes are confined to the outer context.
Otherwise it returns a managed metavariable in that outer context and retains
the open body plus an ordered lambda/forall/let abstraction recipe. Child goals
keep their actual captured contexts. Assignment settles ready scopes, instantiates
their children before abstraction, and checks the resulting scope. Productive
passes remove entries, so the pending count bounds nested completion. There are
no new Core constructors, kernel declarations, proof axioms or host elaborator
dependencies.

Occurs checks follow ordinary and delayed assignments. Assignment also checks
metavariable aliases: natural inference variables can lose unused captured locals
only when their types remain valid in the smaller context. Proof goals keep their
captured contexts. This prevents an apparently closed alias from later injecting
an escaping free local. Constraint snapshots include delayed assignments.

Lambdas, forall expressions, term lets/haves, record-update lets, tactic intro and
tactic locals use the mechanism. Match fields, dependent-context reintroduction,
equality transport and captured discriminants use the same closure path.
Substitution recipes defer alias removal too. The recipe order follows descending
fresh local identity, so interleaved aliases are removed after any dependent
binder types have entered the closed expression. The old proof-specific closure
list, immediate branch substitutions and record-update term-hole refusal are removed.
General delayed conversion constraints remain pending; this is not a claim of
complete higher-order elaboration.

The design follows the locally nameless/delayed-abstraction invariant documented
in Lean MetavarContext.lean and Meta/ExprDefEq.lean at
c29b6dda4f7c20e3eeaa717c4e565663c5cfa364. Our scope recipes are portable data,
not callbacks into the host elaborator. A small native boundary check protects
cycles through delayed assignments and aliases of goals from narrower scopes.
The existing composite covers refinement inside lambdas, nested dependent
binders, lets/haves and record updates; one refusal preserves unfinished goals.
