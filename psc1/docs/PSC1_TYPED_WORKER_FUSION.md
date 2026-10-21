# Typed full-application worker fusion candidate

Actual qualified G1's exact self-compilation replay exhausted the default4GB
Node heap in its input JSON character scanner. CPU samples were dominated by
WeakMap closure registration and nested returned-worker lambdas, not UTF-8 lookup.
The original/specialized IR and emitted code were read directly from the qualified
artifact under graph/source hashes. The fuel-only declaration returns three unary
state lambdas; each byte suspends nested generator applications. Source tail position
alone does not match the existing target's saturated-declaration tail-loop rule.

WorkerFusion adds a typed private full-arity companion only to a non-generic,
nonzero-parameter declaration with a function result and at most64 combined
arguments. Before each returned lambda, it accepts local values/literals,
Nat equality/subtraction and value matches/branches/lets. Arbitrary calls,
projections, indexing, global reads and other computational prefixes decline.
Typed let bindings model beta application and retain original lexical scopes,
including lambda/parameter shadowing; fresh names avoid every original var/binder.

Only fully saturated known global/alias call spines select companions. Intermediate
partial and escaping function uses retain the original declarations and signatures.
Alias operands must be values, are captured exactly once before rewriting, and
keep their old values across later shadowing. The original alias binding stays
when any ordinary/partial occurrence remains. Scope masking blocks accidental
rewriting of a local function that shadows a global worker. Every original
declaration remains; no source or body is filtered to fit a budget.

The shared closed plan rechecks specialized input, runs fusion, strictly validates
the exact transformed module and retains public roots. Companion functions are
runtime IR helpers, not additional Core admission receipts. Canonical original IR
remains unchanged; the existing specializedIr response field now contains the
full closed specialization-plus-fusion result. Type checks do not prove behavioral
preservation. All existing checker/queue/process/heap/stack bounds remain.

The11 checked structural returned-state helpers in Bridge.Json are normalized
consistently so their partial smaller-worker binding lies inside the state lambda.
Their complete bodies/signatures/decisions remain. This exposes the same narrow
guarded worker shape rather than delaying arbitrary recursor hypotheses globally.

New native tests require exact strict input/output checks, collision-safe names,
retained original/escaping definitions and refusal of forged wrappers/divergent
prefixes. Linux target tests compare the same original/fused observations,
a billion-step input with immediate return,30000 full steps, lexical shadowing,
old captures, exact-once ordered operands and external deadlines on ignored
divergent prefixes. These tests and actual G1/G2/G3 are PENDING Linux execution.
Existing all-source/both-grammar, whole-closure and full scoped gates remain.
