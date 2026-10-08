# Expression universe instantiation

`@proofscript/pskernel-core@0.1.0-checker.3` extends the bounded universe
substitution from checker.2 through every expression constructor. Binder names,
term variables and literals are preserved. Sort levels and constant arguments
are substituted simultaneously. Even a leaf without universe occurrences must
validate its parameter names and arity. Nested level operations use the outer
transition budget; malformed states, undeclared parameters and exhaustion fail.

The preserved PSC seed from cc79e840 compiled both Lean and canonical ProofScript:
441 declarations, identical emitted TypeScript, compiled with TypeScript 5.8.3.
The added module also compiled with pinned Lean 4.34.0. No generated semantic
output was edited. All 295 Linux tests passed, including 17 new expression tests,
256 independent generated expression trees and a bounded 50,000-deep traversal.
Fresh reference evidence covers 47 foundation, 100 semantic and 68 checker cases;
all 671 universe and 559 comparable checker differential cases match. Build and
evidence identity verification passes.

Source manifest SHA-256:
`c2ef9dbeca6648e83e6fe8ef8fcad6ca5b83869f14dc32735bb3de84139b5c72`.
Generated JavaScript SHA-256:
`3657d27cb274375d679f9f5cb7e4f894a45efa3cde575058b44c16e6a910e026`.

The owned bootstrap now includes all 15 kernel modules, 70 modules total. This
commit adds a prerequisite for polymorphic declaration checking; it does not
expand the host acceptance profile yet. The first full bootstrap rejection
remains the `_pscCheckedNestedUnit` inductive. Inductive admission, recursors,
prelude semantics, conversion completeness and the generated joint fixed point
remain release blockers. The protected 68-module reference compiler replay has
elaborated all modules but has not yet completed checked emission.
