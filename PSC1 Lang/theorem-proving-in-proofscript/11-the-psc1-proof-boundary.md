# 11. The PSC1 Proof Boundary

Full Lean is a large theorem-proving environment.

PSC1 intentionally freezes a smaller proof language first.

## What PSC1 preserves

PSC1 preserves the semantic foundations required for its supported subset:

- dependent functions/Pi;
- universes needed by the profile;
- implicit arguments;
- metavariables during elaboration;
- definitional equality;
- `Prop`;
- polymorphic `Eq`;
- inductives/recursors;
- bounded class/instance synthesis;
- structural recursion;
- kernel-checked proof terms.

## What the current tactic layer supports

```text
exact
exact?
assumption
intro
apply
refine
constructor
cases
induction
rfl
rw
simp only
```

Each word names a bounded PSC1 implementation, not the full Lean tactic of the
same name.

## What is not automatically PSC1

Examples of full Lean facilities that PSC1 does not claim merely by semantic
compatibility:

- arbitrary tactic combinators;
- unrestricted `simp`;
- `conv`;
- `grind`;
- `omega`;
- `linarith`;
- arbitrary classical automation;
- user-defined tactic syntax;
- tactic macros;
- custom elaborators;
- quotations/antiquotations;
- broad attributes and environment extensions.

These can be studied for future design without becoming first-freeze
requirements.

## Classical axioms

PSC1 should report any classical or other axiomatic assumptions used by a
checked proof.

The language must not silently strengthen its logic because one target runtime
can compute a choice.

## Dependent elimination boundary

The first `cases`/`induction` support is intentionally narrower than Lean's
full indexed dependent elimination.

When a goal requires unsupported motive/index reconstruction, the tactic should
fail with an explicit boundary rather than produce a guessed proof.

## Search boundary

`exact?` is deliberately bounded.

A small proof assistant with predictable search and strong kernel rechecking is
preferable to a broad opaque automation layer during self-hosting.

## Future growth rule

A new tactic belongs in PSC1 when:

1. real programs/proofs benefit from it;
2. its proof-term semantics are clear;
3. pskernel can recheck the generated term;
4. positive and negative regressions exist;
5. its syntax does not accidentally broaden the parser;
6. it does not weaken the trust story.

## Where to go next

For exact language categories and processing rules, read:

- [PSC1 Language Manual](../language-manual/README.md)
- [PSC1 Language Reference](../PSC1_LANGUAGE_REFERENCE.md)
- [Conformance, Portability, and Status](../CONFORMANCE_PORTABILITY_AND_STATUS.md)
