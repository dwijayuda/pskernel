# 9. Proof Feedback and Debugging

Interactive feedback is central to practical theorem proving.

The Lean study material emphasizes reading the proof state rather than treating
errors as opaque compiler failures. PSC1 should preserve that experience.

## Read the goal first

A proof-state view should make the current context visible:

```text
P: Prop
h: P
⊢ P
```

The obvious next step is then `exact h` or `assumption`.

## Metavariable goals

Tactics such as `apply` and `refine` may create new goals.

A useful diagnostic reports:

- the generated goal;
- the local context;
- the source span that created it;
- why a candidate failed to elaborate.

## Cases and induction

After `cases` or `induction`, each branch should be named/stable enough for
the user to understand which constructor is being handled.

PSC1's current implementation carries recursor-derived branch information and
has tests for useful branch naming.

## Rewrite failures

A failed `rw` should distinguish common causes:

- the equality proof did not elaborate;
- the expected side does not occur;
- direction is wrong;
- dependent transport is outside the bounded implementation.

The solution should not be to silently rewrite a different occurrence.

## Simplifier diagnostics

Because PSC1 starts with `simp only`, users can see the explicit rule set.

That makes unexpected behavior easier to reproduce than a large ambient
simplifier database.

The bounded simplifier also uses a maximum step budget to fail predictably.

## Canonical Lean as a debugging view

For supported common-subset source, `psc emit-lean` can show canonical Lean.

This is useful to inspect:

- normalized definitions;
- binder structure;
- proof/tactic lowering;
- precedence/parentheses.

It does not mean the generated Lean text is itself the trusted proof checker.

## LSP/editor integration

The language service should expose the same semantic project/frontend model as
the CLI.

Editor diagnostics must not use a weaker checker just to provide fast feedback.

## Reproducible failures

A proof bug should be reducible to:

- source snippet;
- exact PSC1/Lean semantic version;
- imported checked environment;
- deterministic diagnostic/gate.

This is especially important while the self-host compiler is still converging.

## Next

Continue to [Worked Proof Patterns](./10-worked-proof-patterns.md).
