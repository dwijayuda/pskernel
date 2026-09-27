# Direct JavaScript backend design

Status: proposed implementation design; Generation A freeze is a prerequisite.
Authority: `../continuity/PSC2_NEXT_BOOTSTRAP.md`, `../../ARCHITECTURE.md`, and
`../../packages/compiler-ir/CONTRACT.md`.

## Choice and scope

Implement `VerifiedIR -> JsIR -> deterministic ESM .js` in PSC1-subset `.lean`.
Keep TS as a differential oracle and optional backend. Wasm stays an independent
VerifiedIR consumer. The initial JS milestones do not switch bootstrap authority.

Alternatives considered:

- Stripping TS output would retain coupling to TS syntax and omit the required
  private JS representation boundary; reject this approach.
- Emitting JS directly from Core would duplicate semantic work and bypass the
  shared VerifiedIR boundary; reject this approach.
- A small private JsIR makes target lowering and serialization independently
  testable and gives each a future adjacent preservation obligation; select it.

## Package and dependency boundaries

Planned portable files under `packages/backend-js/src/Ps/BackendJs/`:

| Module | Responsibility |
| --- | --- |
| `Model.lean` | Restricted JsIR, backend configuration and errors |
| `Lower.lean` | VerifiedIR validation and lowering; exhaustive fail-closed handling |
| `Emit.lean` | Deterministic JsIR serialization, escaping and parentheses |
| `Module.lean` | Public VerifiedIR-to-JS composition API |
| `Compiler.lean` | Thin adapter using `Ps.Compiler.Api` preparation services |

Split primitive lowering into focused modules as coverage grows. Do not create
empty abstraction packages or copy the entire TS emitter into one large file.

Package metadata is `portable: true`, `bootstrap: false` during differential
development. Production dependencies are limited to the semantic compiler/IR
and necessary portable foundation modules. The low-level emitter does not import
the compiler adapter. Neither imports TS, Rust, Wasm, kernel implementation,
project tooling, host IO, or a JavaScript parser/compiler.

The semantic compiler must never import the new backend. Backend selection stays
at a separate composition edge. The original TS bootstrap root and closure policy
stay unchanged until the independently gated JS cutover.

## Portable implementation discipline

Handwritten semantic implementation is `.lean`; canonical `.ps` is generated.
No handwritten TS/JS replacement for the lowerer or emitter. Node scripts may
orchestrate tests and execute output but may not rewrite or repair generated JS.

Use explicit PSC1-supported definitions, constructors, unary matches, terminated
local lets, and structural or explicit-fuel recursion. Avoid assuming full Lean
syntax or host library APIs are accepted. No `Lean.*`/`Std.*`, IO, unsafe/extern,
macros, custom elaborators, or host-only termination machinery in portable code.
Fuel exhaustion returns an error, never a fabricated successful output.

Every slice needs both lexical auditing and actual PSC1 compilation of its full
import closure. Generate canonical `.ps`, compile it with the existing compiler,
and execute that generated backend on the same fixtures as the Lean-hosted one.
A successful Lake build alone does not meet this requirement.

## Initial supported slice

Start with closed ESM modules exporting monomorphic constants whose bodies are
Nat, Int, Bool, String, or Unit literals. Reject imports, structures, inductives,
parameters, generic values, other expressions and unsupported types explicitly.
Validate that each literal agrees with its declared result type. Validate the
complete module before returning an artifact; no partially emitted success.

Use arbitrary-precision BigInt for Nat/Int, JS booleans, escaped JS strings, and
`undefined` for Unit. Include values beyond `2^53`, negative Int, empty strings,
quotes, backslashes, control characters, non-BMP Unicode and Unit in fixtures.

Initial JsIR represents only these literals and exported constants. It has no
arbitrary raw-source escape node. Use generated internal names and explicit export
mapping; never interpolate unchecked PSC names as JavaScript identifiers. Define
and test supported export names, reserved words, duplicates and collisions.
Reject unsupported names until their mapping is implemented soundly.

Output is UTF-8 ESM with fixed formatting, stable declaration order, a final LF,
and no timestamps, machine paths or environment-dependent names. Parenthesization
belongs to the serializer. Emit all source from JsIR; do not post-process TS.

## Coverage expansion

| Stage | Coverage and key obligations |
| --- | --- |
| J0 | Frozen TS baseline; prerequisite evidence recorded |
| J1 | Package boundary, literal/module JsIR, deterministic emitter, RED/GREEN differential fixtures |
| J2 | Variables, parameters, functions, lambdas, calls, lets, conditionals; lexical scope, capture avoidance, evaluation order |
| J3 | Nat/Int/Bool primitives; arity, saturating Nat subtraction, division/modulo zero semantics |
| J4 | Records, projections, ADTs and matches; constructor/field validation, one scrutinee evaluation, exhaustive dispatch |
| J5 | Strings/Char, arrays, machine integers, floats; runtime edge-case contracts |
| J6 | Actual compiler corpus coverage; generated-source backend execution and end-to-end differential compiler runs |
| J7 | Separate direct-JS generations, exact source/artifact comparisons, no `tsc` in subsequent generation closure |

Stages describe acceptance slices, not claims of implemented support. Reorder
individual J3-J5 features only when actual compiler dependencies justify it.
External capabilities need an explicit target binding contract; an import field
in the existing IR is not permission to treat arbitrary module loading as pure.

Runtime contracts must be explicit before accepting each primitive:

- Nat/Int never silently become Number; reference-test arithmetic corner cases.
- Machine integers use retained semantic width/signedness and explicit wrapping.
  Reject USize/ISize until a validated target-word-size policy is supplied.
- Float32 uses required f32 rounding at the specified operation boundaries;
  test NaN, infinities, signed zero and rounding against the declared semantics.
- Char uses Unicode scalar semantics; String indexing/positions must respect the
  PSC byte/scalar operation contracts rather than JS UTF-16 defaults.
- Array operations preserve PSC value semantics; mutation must not alter aliases
  unless the semantic contract explicitly permits it.
- Equality is selected by PSC operation/type; never use JS coercive equality.

TS parity is useful evidence, not the final definition of PSC semantics. Resolve
disagreements using the semantic contract and a suitable Lean reference fixture;
do not reproduce a TS bug merely to get a passing comparison.

## Test and self-host acceptance

First add failing fixtures, then production code, then verify:

1. Package dependency/import checks exclude other backends and host code. Existing
   TS bootstrap closure and target-neutrality gates remain green.
2. Lean unit tests exercise actual lowerer and serializer success and rejection.
3. The PSC compiler accepts the full portable backend source closure. Source
   translation round-trips and generated-backend execution match the Lean host.
4. Node parses/imports direct ESM without `tsc` and compares results to the TS
   path on identical VerifiedIR. Compare BigInt structurally, not via lossy Number
   conversion; retain distinctions for undefined, NaN and signed zero as needed.
5. Repeated compilation yields identical bytes. Negative fixtures cover malformed
   module metadata, free variables, duplicate names, unsupported constructs,
   invalid primitive arities and exhausted lowering fuel as those features enter.
6. At J6 include the backend's own implementation in the compiler source corpus,
   plus ordinary library/application fixtures so it is not a special reproducer.
7. At J7 generation N compiles canonical compiler `.ps` to JS generation N+1;
   N+1 compiles the same source to N+2. Compare exact JS bytes and canonical source
   closure hashes. Subsequent generation commands must require neither Lean nor
   TS/`tsc`; audit transitive package dependencies and spawned commands.

Command names for new gates are assigned when executable implementations exist;
do not add placeholder commands that return success. Add branch CI for those
real gates, because the existing kernel workflow does not watch this branch.

The initial Lean/TS host is a bootstrap seed and differential reference. Its use
before direct-JS closure must remain visible in evidence. No authority switch
until actual compiler coverage and repeated direct-JS generations pass.

## Later artifacts and assurance

Generate `.d.ts` from checked exported interface information, not by parsing JS.
Generate source maps from tracked provenance, not guessed line correspondence.
Both remain separate from runtime semantic preservation and require their own
acceptance gates before claiming the full next-bootstrap distribution milestone.

Mechanize adjacent `VerifiedIR -> JsIR` and `JsIR -> emitted JS` preservation for
the restricted emitted language. Runtime primitive refinement is a separate
obligation. Full kernel-backed compilation requires genuine kernel-issued
CheckedCore upstream; this backend cannot manufacture it. Tests and fixed points
do not establish those theorems or full Lean 4 equivalence.
