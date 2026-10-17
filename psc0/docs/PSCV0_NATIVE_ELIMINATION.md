# Native proof elimination and named goals

Selected forms are cases <local> and induction <local>, followed by existing
bullets or case <tag> <names>* => <tactics> / next <names>* => <tactics>.
Blocks retain the v7 newline/indentation boundary inside by braces. Case failure
is an error; it never inserts a sorry. Multiple targets, named discriminant
equations, custom using recursors, explicit generalizing and inline with
alternatives remain pending.

GoalSource owns goal-local source resolution. Elimination is a client of Match's
typed branch interface: constructor fields, recursive hypotheses, specialized
target and locals to clear. It reuses the same motive, dependent-context
reversion, index equalities, contradiction elimination and checked recursor
application as term matching. Cases removes IHs from the child goal; induction
exposes them. Original majors and generalized originals leave the child goal
context; specialized replacements retain their checked identities.

Optional metavariable origin data records goal tags and introduced binder
identities in constructor order. This ordering survives dependent index
substitution, which can reintroduce fields at different local-context positions.
Case renaming changes display/source names, never Core identities or types.
Tags compose with parent tags, and suffix selection must be unique. Apply and
constructor also retain the names of their remaining argument goals.

The source selection is grounded in Init/Tactics.lean (cases, induction, case,
next), Lean/Elab/Tactic/Induction.lean and Meta/Tactic/Cases.lean and
Meta/Tactic/Induction.lean at c29b6dda4f7c20e3eeaa717c4e565663c5cfa364.
All resulting terms pass through the existing official-kernel boundary.

The existing composite gains ordinary/logical/indexed/dependent case splits,
inductive computation, proof induction and empty elimination. Four refusals
protect missing IH access, unknown tags, binder arity and cleared-major scope.
This does not claim arbitrary recursors, full tactic syntax or full v7 coverage.
