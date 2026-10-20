# PSC1 Practical Core: control flow and data

This continuation is stacked on draft PR #165, whose preserved head is
`5539059a47c13a3dbc9806a504775b72f7bfd0fe`. Draft PR #166 implements the selected
control and data forms described below. All fourteen Practical Core families
remain explicitly incomplete in the machine-readable status.

## Qualification checkpoint

Implementation head `8d6f80ea5813edd0644440971095abffd9dddacd` passed all 34 steps in
[focused Linux run 39407097682](https://github.com/dwijayuda/pskernel/actions/runs/39407097682). The workflow tested
GitHub merge commit `164fb133a8da410140cc3a84dcd51382c4a230a6` against preserved PR #165.

The [immutable qualification receipt](PSC1_PRACTICAL_CORE_CONTROL_DATA_QUALIFICATION_2026-10-20.json)
records the exact compiler/tool identities, observed checks and package hashes.
[Retained evidence archive](https://github.com/dwijayuda/pskernel/actions/runs/39407097682/artifacts/12257218795): 38,733,488 bytes,
SHA-256 `2b59e2401d4d68149360e5bce8ac91a371d904bfec715141705c8c85bd6edd98`.
This is a scoped execution checkpoint; later heads require their own successful
focused check. All fourteen feature families remain incomplete.

The authoritative admission provider remains official Lean 4.35.0 at
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. The checked-out GitHub merge commit
and the source branch head are separate identities in each workflow receipt.
Source admission, strict executable-IR validation, and observed target behavior
are distinct checks. Successful execution does not establish a backend-preservation
theorem or a behavioral certificate.

## Selected source semantics

Both supported grammars use the same procedural AST and elaborator.

| Form | Implemented behavior | Selected boundary |
| --- | --- | --- |
| `let mut` and assignment | Lexically identified, fixed-type mutable bindings become successive immutable Core values | Assignment to an immutable or out-of-scope binding fails; a mutable name cannot be rebound or shadowed inside its controller |
| Procedural `if` | Each branch has its own scope; live mutable values pass to a checked continuation | Conditions are Bool; existing Bool equality/decision declarations are reused |
| Early `return` | Exits the enclosing procedural computation from branches and selected loops | Direct nested `do` statements share the controller; a parenthesized `do` term or lambda establishes a distinct computation |
| Contextual `pure` | In a selected do action, its argument receives the expected result type | Existing local/global bindings named `pure` retain precedence; this is not general type-class inference |
| `for` over List/Array | Collection captured once; bodies run left to right; mutation, early return, and selected effect sequencing are preserved | Arbitrary iterator instances and custom step forms are outside the profile |
| Nat ranges | `[lower:upper]` and `[:upper]`; endpoints captured once; equal/reversed bounds are empty | Unit step only; no generated execution fuel |
| `while` | Rechecks its Bool condition against current mutable state; selected bodies become private recursive helpers | Explicit partial declaration and ordinary assurance; Id/Except, direct tail recurrence, no nested procedural loop inside its body |
| Tuples | Unit, grouping, and right-associated product expression notation; contextual element types | Tuple destructuring and nested binding patterns remain absent |
| Arrays | `#[...]` and contextually typed empty literals reuse checked Array constructors | No new public aggregate ABI |
| Optional array access | Adjacent `xs[i]?` returns `Option`; receiver then Nat index are evaluated once | Plain, proof, and panic access forms are refused; the selected implementation scans the array |

Mutable shadowing follows the selected pinned Lean elaboration semantics. A new
mutable binding may shadow an earlier immutable binding. An already mutable name
cannot be shadowed within the same procedural controller. Closures capture the
value visible at their creation; later assignments do not mutate a host cell.
Native tests pin both accepted and refused cases.

Operator printers group low-precedence operands such as conditionals and match
expressions, preserving the source tree in both grammars. The Lean binder-type
parser also handles grouped arrows and the named or anonymous dependent-arrow
forms emitted by the printer, while retaining product precedence. Canonical
round trips and actual higher-order Rust consumers cover those boundaries.

The current do profile consists of monomorphic Type0 Id, Except, and the actual
checked CompilerM definitions. Branches, finite loops, mutation and early return
use the same controller for these effects. Source `while` deliberately excludes
CompilerM in this slice. This does not claim support for arbitrary Monad instances,
higher universe effects, handlers, or general typed IO.

## How the lowering stays inside the checked path

### Mutation, joins, and finite loops

The controller tracks the identity of a mutable binding separately from its
current Core-local identity. Assignment typechecks the new value against the
binding's established type. It then creates a Core let and advances that binding's
current identity. Scope exit restores the outer visible bindings.

A branch continuation accepts the visible mutable values and a final Unit
argument. The Unit thunk preserves lazy continuation entry, including branches
with no mutable locals. A branch that returns does not invoke that continuation.
Except errors propagate through the existing checked recursor; CompilerM uses
its existing checked bind/state operations.

Finite List and Nat-range iteration use two total definitions in
`Ps.Environment.Control`. They are built from the existing checked recursors and
independently admitted with the graph. Array iteration uses the existing Array
fold. Collections and endpoints are bound before the iteration. No unchecked
loop primitive or target-specific mutation instruction is added.

The finite implementation constructs continuations before running the bodies.
Its construction uses linear space in the iteration count. The selected tests
establish small finite semantic cases; they do not qualify arbitrary large
collections or claim constant-space finite iteration.

### Ordinary while helpers

A temporary elaborator-only signature identifies a while site inside an explicit
partial declaration. `Ps.Elab.DoWhile` builds the checked state/continuation term.
`Ps.Elab.DoLoopLift` replaces every marker before source declarations enter
admission:

1. Reopen the surrounding lexical Core binders.
2. Collect only referenced locals and their type dependencies.
3. Construct a private per-site partial helper and its capture arguments.
4. Specialize its continuation, retaining strict single evaluation through Core
   lets when an argument is not a value.
5. Require every generated self occurrence to be fully saturated and in a
   recognized direct tail position.
6. Recheck the closed helper and the rewritten source term.

The generic marker does not enter the runtime declaration graph. The pass rejects
escaping, partially applied, non-tail, or unrecognized recurrence. Sequential
loops use separate private helpers. A source self reference, when needed, becomes
an explicit captured function parameter rather than a forward global dependency.

Ordinary preparation remains unchanged: each partial helper and source function
gets a constructive opaque logical witness and a separately admitted exact
executable body. The helper has a fallback `Unit -> Result` parameter sufficient
for the existing witness search. That parameter supplies a logical inhabitant;
the runtime executes the checked recursive body. The fallback is never used as
a runtime timeout or a synthetic loop result. The immutable source/logical
pairing is revalidated before erasure.

The source profile conservatively rejects nested procedural loops in a while
body, CompilerM while, computations whose complete type has an unknown or function
head, and recurrence shapes not recognized as direct tail calls. Capturing a local type alias can lose the
local definitional equality needed to recheck a helper; those cases fail closed
and are outside this qualification. No general dependent closure conversion is
claimed.

The native admission test for the earlier generic helper remains a standalone
test of exact ordinary pairing. It is not evidence that source loops execute
through that generic helper.

### Tuples and optional arrays

Tuple syntax lowers to existing Prod constructors. `(a)` remains grouping;
`(a,b,c)` is right-associated; Unit has its existing constructor. Tuple
destructuring is a separate missing feature.

Array literals lower to existing empty/push operations. Optional lookup binds the
receiver and index in source order, then folds with an index/Option accumulator.
An empty or out-of-bounds lookup returns none without inventing a default element.
This is O(array length), including a successful low-index lookup. It adds no
logical axiom, backend opcode, or host aggregate alias.

## Evidence and its limits

The native source suites contain 101 Do outcomes, 71 Data outcomes and 27 While
outcomes. They include 42, 14 and 15 private-JS expected-value comparisons,
respectively. Do additionally retains 12 kernel-conversion checks, 29 rejection
checks, 14 translation round trips and four extra assertions. Data includes
18 canonical-Core comparisons, 18 parse refusals, 17 type refusals and four
round trips. While adds three graph/translation checks and nine boundary checks.

The runtime oracle has 78 fields: two toolchain identity fields and 76 result
observations. The results comprise 23 retained baseline fields, 33 selected
control/data fields, 18 ordinary-while fields and two focused Rust private-closure
fields. The regular matrix has 14 target/source bundles with 15 individual predicates
and a combined semantic predicate. The ordinary matrix has 14 finite bundles
with eight loop checks and a combined predicate, plus 14 external-timeout
divergence bundles. Component Wasm exposes only its selected Bool predicate.
The minimum Python line repeats both source syntaxes for the regular matrix,
ordinary finite cases and external divergence checks.

The ordinary matrix includes 100,000-iteration cases, condition/state updates,
captured values, sequential loops, while inside finite for, typed errors and
source-function capture. Six unsupported source-shape cases per syntax plus
default/verified assurance failures produce 16 refusal checks. Published artifacts
must survive the failed assurance requests unchanged. Each target's divergence
program first demonstrates a terminating early-return path, then must reach the
external deadline on its infinite path; a stack error, memory exhaustion, returned
value or generated fuel result is a failure.

The scripting suite records 24 retained artifact bundles and four boundary
records; the minimum Python repeat records 12 bundles and two boundary records.
The focused backend suite has 26 groups, including public component closure
parameter refusals in both grammars. These counts describe this continuation,
not the preserved historical seven-backend checkpoint.

Two additional Rust records, outside the 14 main bundles, compare reused private
higher-order captures with native Lean and require refusal before publication
when that same nested-function signature is public.

Native fixtures use three forms of evidence:

- Canonical Core comparisons for notation that should elaborate identically to
  existing named constructors.
- Independent Lean admission and strict executable-IR validation for every
  accepted typed fixture.
- Private generated-JavaScript execution against independently admitted explicit
  expected values where kernel conversion is not a valid execution oracle.

That last distinction is necessary because the provider's retained prelude
contains nonreducing declarations for selected existing condition/array
operations. Failure to reduce such a term to a literal is not an execution
mismatch. Tests keep the original expected values and compare actual execution.
They do not change those declarations' admission policy.

The seven-target corpus separately compares behavior with observations produced
by authentic native Lean code under the exact pin. The shared corpus exercises
Id control, selected Except behavior, finite loops, and internal tuple/array
operations. CompilerM mutation, early return and finite-loop state sequencing
are qualified through native admission/IR and private JS fixture execution;
they are not claimed as all-seven native-oracle cases.

All seven targets retain their established public ABI boundaries. The component
corpus exports a Bool predicate and exercises aggregate operations internally.
Python/PHP public aggregate functions remain refused. No test helper is a new
public aggregate ABI.

## Backend execution changes

The Wasm lowerer derives a computed callee's complete function type with the
bounded strict IR expression checker, evaluates that callee once before its
arguments, and uses the existing typed closure-call path. Size, traversal,
type, GC signature and final binary validation remain separate gates. This does
not widen the component public ABI.

PHP direct self-tail calls now reuse their declaration's generator frame.
Only fully saturated, unshadowed calls in recognized tail positions qualify.
Every argument is evaluated and saved before any parameter changes; closures
retain captured values. Calls in initializers, arguments or other non-tail
positions still use suspended scheduler frames. A focused interpreter fixture
checks parameter swaps, capture stability and a local function shadowing the
recursive name, alongside the retained deep non-tail recursion test.

Rust now retains strict IR types on both ordinary and tail-emitted local lets,
including empty arrays whose element type cannot be recovered from a size query.
Internal continuation values may use nested direct Rc closure arrows with explicit
return coercions and capture clones. Private helper signatures use that bounded
path. Public higher-order signature restrictions and named aggregate function
storage restrictions remain unchanged; a separate two-syntax regression checks
private reuse and refusal before publication for the public form.

## Fourteen-family status

| Family | Current implemented subset | Remaining family work |
| --- | --- | --- |
| Operators | Existing Nat arithmetic, selected Int arithmetic, Bool operations and selected equality | Prop-valued Nat/Int ordering with genuine checked decision evidence; Int division/modulo remains outside the active scalar profile |
| Local inference | Typed/inferred lets, contextual literals and selected data/control interactions | Broader inference qualification; unresolved metavariables still fail |
| Do | Selected Id/Except/checked CompilerM sequencing, contextual pure and shared control | General effect instances, higher universes and handler interactions |
| For | List, Array and finite unit-step Nat ranges | Broader iterator/control and resource qualification |
| While | Selected ordinary Id/Except loop specialization | Nested loop bodies, CompilerM/general effects and broader closure/control shapes |
| Mutation | Lexical fixed-type assignment, joins, closure capture and selected loops | Handler/general-effect interactions and broader scopes |
| Return | Terminal, branch and selected loop early return | Handler interactions and unsupported loop/control shapes |
| Partial definitions | Explicit ordinary exact witness/body pairing; selected generated loop helpers | Broader function/control qualification; verified mode still refuses |
| Tuples | Unit/grouping/product expressions | Destructuring and nested patterns |
| Arrays | Literals, contextual empties and optional lookup | Completion beyond the demonstrated minimum is not claimed; the refused access modes are intentional |
| Typed errors | Selected Except/CompilerM propagation through existing binds | Throw/try/catch syntax and handler/control/state semantics |
| Call inference | Transactional expected-result constraints for nondependent explicit arguments | Dependent/intervening-implicit telescopes remain sequential |
| Namespaces | Exact dotted references and local-before-global lookup | Namespace/end scopes, current/enclosing-name lookup, matched ends and integration with existing import ownership |
| Typed IO | No admitted source IO profile | Typed line input/output and bounded UTF-8 file read/write with paths, EOF, size/error contracts and target adapters |

The selected array minimum is literals and optional access. Plain/proof access
must remain refused until genuine validity evidence is implemented; panic access
is excluded. Their absence is not an unfinished obligation for this increment.
Existing entry-module export ownership and imported-helper privacy already work;
the namespace gap concerns lexical scopes and their integration with that policy.

No family is promoted to complete by a passing example. Historical five-target
receipts retain their original scope. The current status adds Python and PHP as
explicit target entries without retroactively extending that historical evidence.

## Reproduction and exclusions

Use the focused Linux PR workflow
`.github/workflows/psc1-scoped-correctness.yml`, which installs the pinned
toolchain and actual target consumers. Its receipts and logs are retained as the
run artifact. The workflow also runs the scripting/reference corpus on the minimum
Python line and tests installed unpublished native npm/source-library tarballs.

Relevant suites include `psc1_do_tests`, `psc1_data_tests`,
`psc1_while_tests`, `psc1_ordinary_tests`, `runtime-conformance-tests.mjs`,
`ordinary-while-conformance-tests.mjs`, and
`seven-backend-qualification.mjs`. These are focused compiler/admission/runtime
checks, not full self-host or fixed-point qualification.

The continuation does not merge a PR, publish a package, issue a release, add
unchecked logical authority, claim unrestricted Lean, or run full self-host/
joint-census/fixed-point qualification.
