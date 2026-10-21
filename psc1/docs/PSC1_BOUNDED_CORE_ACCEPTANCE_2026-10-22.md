# Bounded numeric, inference and control acceptance

The frozen Practical Core v1 scope remains fourteen families and 37 finite
criteria. This change completes executable coverage bindings for nine existing
criteria; it does not enlarge the language, create a new logical axiom, or
qualify a source before its exact Linux CI completes.

| Criterion | Executed source / evidence |
| --- | --- |
| operators.numeric | numericCase: beyond-64-bit Nat arithmetic, saturated subtraction, normal/zero division and remainder, signed add/sub/mul, precedence/association; mixed-domain and Bool arithmetic/equality refusals |
| operators.short-circuit | shortCircuitCase: both dynamic Bool inputs, skipped divergence and typed equality; actual seven-adapter IO consumers observe skipped foreign errors and a deliberately reached trapping control |
| local-inference.rollback | rollbackCase plus the native ContextualInferenceTests assignment/fresh-identity rollback boundary, existing ambiguous/unresolved refusals |
| call-inference.telescopes | telescopeCase: dependent explicit type, intervening implicit and expected-result constraints |
| call-inference.refusals | callCase: native/comma calls and explicit f(()); wrong arity/type, unresolved empty generic call and empty f() refusals |
| typed-do.ownership | ownerLambdaCase: grouped do under a lambda, independent nested owner and nested loop return; wrong state/error/result and cross-owner assignment refusals |
| early-return.owners | ownerLambdaCase and retained ownerCase: nested branch/loop return exits its owner and skips the owned continuation |
| mutation.joins | joinsCase: branch/loop joins, mutable shadowing of an immutable value, original RHS scope and old closure capture; mutable shadow/type/escape refusals |
| typed-errors.scope | handlerScopeCase: nested typed rethrow, handler binder scope, lexical rollback and return bypass; malformed/mistyped and escaping-handler refusals |

Both independently authored source grammars run against official Lean 4.35.0
reference results. The order suite grows from four to six cases (84 complete
case/grammar/target obligations); inference/control grows from five to ten
(140 obligations). Existing cases and all previous refusal receipts remain.
The exact-commit full matrix includes all seven backends and minimum Python.

The IO program's Bool result depends on checked execution through its foreign
dispatcher. On success, false-and and true-or must skip a sentinel foreign
request. Each consumer also provides a valid typed error response followed by
a sentinel trap: the now-reachable request must escape as the exact foreign
error. Original real file/console effects and the original handler trap test
remain required. No new public export, ABI, host capability or source exception
conversion is introduced.

Readiness requires both the complete order receipt and complete seven-adapter
foreign-error evidence for short circuit. Missing either cannot qualify that
criterion, even with an otherwise successful scoped qualification. Contract
mutation tests cover this composite evidence boundary.

Nine new bindings make 25 of the 37 criteria eligible for qualification.
Eligibility is not a CI result. The remaining twelve unbound criteria are
finite for-loop collection/range/streaming acceptance, while controller and
divergence, partial pairing and recursion, product patterns and identity,
Array operations/evaluation order, and namespace identity/ownership.
They must acquire complete executable evidence without weakening their meaning.
G2/G3 stay deferred until all criteria/applications qualify and feature freeze.
