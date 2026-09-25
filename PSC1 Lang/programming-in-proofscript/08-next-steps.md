# 8. Next Steps

You now have the programming-oriented PSC1 model:

- ordinary pure functions and algebraic data;
- explicit project/module boundaries;
- proofs as useful program evidence;
- bounded typeclass polymorphism;
- explicit reader/state/error effects;
- dependent APIs where they improve contracts;
- proofs that can relate safe/simple specifications to efficient code;
- target-neutral semantics before backend lowering.

## If you want to prove more

Continue with:

- [Theorem Proving in ProofScript PSC1](../theorem-proving-in-proofscript/README.md)

That book focuses on proof terms, goals, tactics, equality, induction, and the
trust boundary.

## If you need exact syntax

Use:

- [PSC1 Language Manual](../language-manual/README.md)
- [Syntax and Grammar](../SYNTAX_AND_GRAMMAR.md)
- [Language Surface Quick Reference](../reference/language-surface.md)

## If you are implementing the compiler

Read:

- [PSC1 Language Reference](../PSC1_LANGUAGE_REFERENCE.md)
- [Semantics, Runtime, and Effects](../SEMANTICS_RUNTIME_AND_EFFECTS.md)
- [Conformance, Portability, and Status](../CONFORMANCE_PORTABILITY_AND_STATUS.md)
- repository `docs/plans/07_SELF_HOSTING_FOUNDATION.md`

## If you are writing libraries

Prefer:

- functions over new syntax;
- explicit algebraic data over sentinel/null behavior;
- typeclasses only for genuine type-directed evidence;
- dependent types for valuable invariants;
- portable APIs before target-specific FFI;
- proofs that remain useful at the package boundary.

The PSC1 design goal is not to make every program look like a proof.

It is to make proofs available exactly where they improve the program.
