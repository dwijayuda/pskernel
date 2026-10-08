# Internal typed constants

`@proofscript/pskernel-core@0.1.0-checker.5` distinguishes transparent definition
bodies from internal opaque constants. Typing validates universe arity and
instantiates a constant's type; reduction preserves opaque constants as neutral
terms; conversion compares their names and universe arguments with the shared
transition budget. This is groundwork for derived inductive constants, not an
axiom admission API. The fresh production admission path still rejects external
axioms and opaque declarations. Failure and exhaustion return no environment.

The preserved PSC seed at cc79e840 generates all semantic JavaScript. Both source
frontends check 467 declarations with identical TypeScript emission. All 15
modules compile with pinned native Lean 4.34.0. Source-manifest SHA-256 is
`a9f6ae1d86679c1ee52daefa0d00217888078ab0de335786e2249b4e127c990f`;
generated JavaScript SHA-256 is
`287f6ad16747b3896892115d7d4dfa0b6eb6b210e004859244f43a420a08c857`.

Executed validation: 328/328 Linux package tests (11 new constant tests), 35/35
integrated Linux host/source-profile tests including that baseline, and 29/29
focused wire/source-profile tests after adding an explicit opaque-declaration
rejection case. Fresh reference evidence covers 47 foundation, 100 semantic,
68 checker, 138 polymorphic, 671 universe and 559 comparable term cases. The two
known term completeness gaps remain proof irrelevance and function eta.
Build/evidence identities, source guards, the 70-module closure and the preserved
PSC seed's 2,369-declaration compiler/kernel source check pass. That source check
does not establish owned-kernel admission of the closure.

The source profile now distinguishes the ordinary constructor name `opaque`
from the forbidden opaque declaration command, with regressions for qualified
constructor uses, modifiers and attributes. This does not permit opaque commands.

Integration base: 900c68e834614388664d9b31697c5af098155758. Its CI run
37035744959 passed provider, host, source, parser and native-reference steps;
the owned full-bootstrap step failed and the independent compiler diagnostic
was cancelled. Owned admission still stops at `_pscCheckedNestedUnit`.
The default remains the owned kernel; explicit Lean reference providers remain
outside the portable closure. No previous replay artifact was overwritten.
General inductives, primitives, prelude validation and the generated pair fixed
point remain release blockers. This checkpoint is private and nonauthoritative.
