# Native typed pattern matrices

The stored syntax has one recursive pattern tree and one matrix match node:
ordered discriminants, ordered rows, and one pattern per row/column. Flat parser
clients use construction helpers; they do not introduce a second stored form.
Native parsing owns constructor whitespace application, grouped nested patterns,
tuples, natural literals and successor patterns. Expression comma calls are not
constructor patterns. Scope resolution collects binders recursively, checks
duplicate variables, and qualifies constructor identities.

Ps.Elab.PatternMatrix owns ordered row specialization. A constructor split
preserves row order and retains wildcard/variable rows in every applicable branch.
Field patterns precede remaining columns. Completed rows choose the first body.
Fresh inaccessible discriminant aliases, created only when needed, save binding values before any user
pattern name enters scope, avoiding cross-column capture. Computed discriminants
are evaluated once. Original local majors retain their identities, so the shared
dependent motive can refine later discriminants and their dependent context.
Structural-call lookup follows let aliases to an actual registered recursive child.

Every split calls Ps.Elab.MatchWith. That module alone owns motives, recursor
telescopes, branch context reversion, homogeneous index constraints, contradiction
proofs and coverage rejection. Branch continuations let the matrix elaborate
remaining columns inside the refined context; no syntax marker, unchecked cast,
type mutation or separate matrix-specific proof engine is used. Existing Core
preparation lifts runtime recursors only when needed and checks the resulting
helper graph before erasure.

An empty matrix tries the existing checked impossibility operation on remaining
discriminants. It does not blindly unfold recursive fields. More general
joint-discriminant contradictions, named discriminant equations, generalizing
controls, inaccessible/as patterns, implicit constructor-pattern insertion and
the complete selected pattern notation registry remain pending. Natural literal
patterns currently specialize through successor constructors with bounded fuel;
a shared checked literal decision strategy remains a performance extension.
Root source recursion with multiple discriminants remains outside the structural
normalizer's selected profile.

The compact native application exercises row priority, fallthrough after nested
failure, differing field binder names, cross-column shadowing, tuples, nested
indexed refinement and dependent later discriminants. Four refusal inputs protect
row arity, duplicate variables, nested coverage and expression-call punctuation.
Qualification must be recorded by exact source/run in AI_WORK_STATE.md.
