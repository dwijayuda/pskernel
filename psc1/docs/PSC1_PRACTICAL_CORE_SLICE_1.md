# Practical Core v7.2 — first implementation slice

## Qualification

This is an implementation candidate until its exact commit passes focused Linux CI.
The separately qualified Lean 4.35 migration is
[`1bd0854`](https://github.com/dwijayuda/pskernel/commit/1bd0854f735cf8d0c8f3d07f705195c131acbd61),
[run 39344155280](https://github.com/dwijayuda/pskernel/actions/runs/39344155280).
Do not use that pin-only run as language execution evidence.
The complete fourteen-family matrix remains in
[`PSC1_PRACTICAL_CORE_STATUS.json`](PSC1_PRACTICAL_CORE_STATUS.json).

## Selected behavior

| Area | Implemented candidate | Remaining selected-family work |
|---|---|---|
| Operators | Fixed precedence; Nat +, -, *, /, %; Int +, -, *, unary minus; Boolean !, &&, ||; selected equality and product types | Prop ordering including a < b, general decision/if-proof paths, remaining operator type combinations |
| Inference | Expected-result constraints reach ordinary nondependent explicit call arguments before contextual literals; existing local inference retained | Broader dependent/universe/class inference and further interaction qualification |
| do / return | Shared AST and typed controller; immutable typed/inferred locals and binds; Unit sequencing; terminal return; Id, Except, checked CompilerM | Early exits through branches/loops/handlers, mutable locals, finite iteration, while, general effects |
| Id | Actual checked ordinary definitions of Id and Id.run at Type 0; only referenced runtime helper definitions emitted | Higher-universe Id and generalized universe inference |
| partial def | Explicit ordinary checked path with independently constructed inhabitant and exact executable-body admission | Broader inhabited types, total/partial loop integration, behavioral verification |

Both .lean and .ps use the shared semantic pipeline. Native Lean do supports
layout and braced semicolon forms. ProofScript do uses braces and newline-separated
statements; semicolons remain rejected. Ordinary term if is still Boolean-valued.
Boolean conjunction/disjunction lower through checked conditionals and preserve
short-circuit behavior. Ordering syntax is recognized and explicitly rejected until
its genuine proposition/decision path exists; no Boolean stand-in is called a proof.

## Ordinary execution contract

```text
psc1 build input.lean --assurance ordinary --target js --out module.js
psc1 check input.ps --assurance ordinary
psc1 admissions input.lean --assurance ordinary
```

The default checked mode retains the old refusal of partial declarations.
An explicit `--assurance verified` request fails without ordinary fallback.
Duplicate, incomplete and unknown assurance options fail before staging.

For a partial function `f : T := body`, the compiler constructs an inhabitant
of `T` without consulting or executing `body`. It emits a safe opaque logical
`f` with that inhabitant, followed by a safe private declaration with type
`T` and the exact source body referring to opaque `f`. The independent official
Lean kernel admits both. No recursive equation axiom or opaque unfolding rule
is introduced. Numeric generated-name components are unspellable by the source
name parser, and duplicate ownership is checked.

The captured original declarations are retained for runtime erasure. Before
erasure, the compiler reconstructs the entire ordered logical expansion and
compares its canonical admission bytes with the paired logical graph. Runtime
code uses the original executable body, never the witness or body-marker graph.
The host performs admission before this runtime path. Private dependencies,
source snapshots, specialization validation, public name selection, declarations,
maps and transactional publication keep the existing boundaries.

Witness construction has a shared attempt budget, consumed across all recursive
children and failed alternatives. Failure means this subset did not construct an
inhabitant; it does not prove the type uninhabited. Runtime recursion has no
semantic fuel cutoff. Intentional divergence is tested only by an external
child-process timeout.

Bundles record `ordinary-checked` or `checked-logical`,
`behaviorallyVerified: false`, and captured partial declaration names. They also
retain exact Lean version/commit and checksummed source/admission/output evidence.
These labels do not claim behavioral certification.

## Focused qualification commands

Run only in the authorized Linux cloud workflow, from psc1:

```text
lake build contextual_inference_tests psc1_do_tests psc1_operator_tests psc1_ordinary_tests
.lake/build/bin/contextual_inference_tests
.lake/build/bin/psc1_do_tests
.lake/build/bin/psc1_operator_tests
.lake/build/bin/psc1_ordinary_tests
node scripts/practical-forms-backend-tests.mjs
node scripts/practical-ordinary-tests.mjs
```

The new runtime suites exercise actual generated JS, independently compiled TS,
copied Rust consumers, core Wasm and Bool-only public components. They retain real
readable outputs and execution records beneath `dist/scoped-correctness/`.
Native do tests independently check result conversion with a dependent identity
fixture, including a deliberately wrong expected result, without adding Eq.refl
or any trusted declaration. Partial boundary tests distinguish witness/body
behavior, reject forged pairings, and require logical opacity.

No full self-host compiler/kernel generation, census, fixed point, package release,
merge, full v7.2 conformance or unrestricted Lean support is included.
