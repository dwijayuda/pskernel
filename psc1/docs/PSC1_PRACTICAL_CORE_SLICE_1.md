# Practical Core v7.2 — first implementation slice

## Qualification

**The first scoped implementation slice passed** at
[`4be91b111c1773f02a009fb2f643b18912cee920`](https://github.com/dwijayuda/pskernel/commit/4be91b111c1773f02a009fb2f643b18912cee920),
[Linux run 39348537989](https://github.com/dwijayuda/pskernel/actions/runs/39348537989). CI checked merge commit
`aa3afeb4f7087f7b9781d67230dda919ff0b38ff`; its tree
`cb778954f86ce09fe22b4ed36240cb89f4e16382` is byte-identical to the implementation tree.
This receipt describes that exact implementation checkpoint, independently of
later documentation-only commits.

[Download the readable bundles and execution evidence](https://github.com/dwijayuda/pskernel/actions/runs/39348537989/artifacts/12231958323).
The artifact digest is `sha256:df0ba1a2cef4b11caf640b9bc2f1b1b2fdf817758a1525cb99216772d235374f`; retention expires
2026-11-03T00:38:16Z. The versioned
[`PSC1_PRACTICAL_CORE_SLICE_1_QUALIFICATION.json`](PSC1_PRACTICAL_CORE_SLICE_1_QUALIFICATION.json)
records the exact source, checkout, counts, target scope and artifact identity.

| Qualification group | Actual result |
|---|---|
| Host formatting/publication regressions | 15 passed |
| Native owned-kernel regressions | 18 passed |
| Preserved backend/publication matrix | 24 groups passed |
| Source ownership, generics and recursion edges | 5 groups passed |
| Contextual inference | 25 positive/negative checks passed |
| Typed do | 32 checks passed, including independent kernel reduction and negative cases |
| Operators | Checked-Core equivalence and negative suite passed |
| Ordinary admission | Independent admission, opacity, exact graph/body pairing and witness-budget suite passed |
| Practical forms runtime | 36 generated artifacts executed; 132 result assertions |
| Ordinary runtime/negative boundary cases | All 9 groups passed |

IR specialization input/output checks, maps, independent provider and host-boundary
suites also passed. These are overlapping scoped groups, not a single test census.

The separately qualified Lean 4.35 migration remains
[`1bd0854`](https://github.com/dwijayuda/pskernel/commit/1bd0854f735cf8d0c8f3d07f705195c131acbd61),
[run 39344155280](https://github.com/dwijayuda/pskernel/actions/runs/39344155280).
The complete fourteen-family matrix remains in
[`PSC1_PRACTICAL_CORE_STATUS.json`](PSC1_PRACTICAL_CORE_STATUS.json);
every full family is still explicitly incomplete.

## Selected behavior

| Area | Qualified bounded implementation | Remaining selected-family work |
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

## Exact runtime coverage

| Cases | Source forms | Targets actually executed |
|---|---|---|
| Contextual Int calls, named Prod/Array operations, Nat/Int arithmetic | Lean and ProofScript | JS, TS and Rust |
| Bool operator expression, Id do through a checked type alias, Except do/error sequencing | Lean and ProofScript | JS, TS, Rust, core Wasm and component Wasm |
| Ordinary recursive countdown | Lean and ProofScript | JS; returns 42 at 7 in both forms, with Lean also checked at 0 and 100000 |
| Ordinary recursive Bool dependency, kept private to the entry API | Lean | JS, TS, Rust, core Wasm and component Wasm |
| Existing checked CompilerM library | Lean | Independent kernel conversion and typed IR; read 7, write 8, observe sum 15 |

ProofScript ordinary partials also passed native independent admission and strict
IR tests. TS/Rust/Wasm ordinary fixtures in this receipt use Lean source. Numeric
Practical Core forms are not newly qualified on Wasm by this suite. The public
component ABI remains Bool only.

The runtime scripts keep full readable bundles and hashed execution records.
Rust consumers use independent dereferenced copies of sealed crates. JS generation
has no hidden TypeScript compiler; the separate TS consumer is compiled with the
pinned checker before execution.

## Corrections required by qualification

ProofScript native-spaced type application now consumes the final type argument
before `:=`, while record/call delimiter rules remain. Identity binds lower to
checked Core lets, preserving one evaluation and lexical scope. Sort-valued
definitions remain checked and available for type normalization but have no runtime
declaration. Host ownership and erasure share the same selected runtime-prelude
closure, including collision-aware names when Id.run is unused.

Wasm keeps mutually recursive heap types together and emits function types as
separate singleton groups without changing flat type indices. This permits the
Bool component boundary to match canonical function signatures. The formatter
preserves quoted constructor keys so its complete syntax-tree equality check
remains intact; computed payload fields retain their semantics.

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
