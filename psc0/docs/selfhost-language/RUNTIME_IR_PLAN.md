# M6: portable expression checking for original PSC0 IR


## Active implementation checkpoint

The implementation on `psc0/sh1-ir-checker-v1` descends from
`829a2e953895f03225a77425141aa3ded5e78694`. It adds `CheckTypes.lean`,
`CheckSize.lean` and `Check.lean` beside the existing model, neutral record
factories for generated host calls, and a separate checked emission entry.
Source reviews are complete; native/generated qualification is pending.
A source implementation is not a qualified capability.

The active scalar typing ledger covers Nat, Int, Bool, Char, String and Unit,
with an explicit arity-one Array runtime type for the listed array intrinsics.
Optional scalar, external-import and empty-inductive/match capabilities remain
explicit refusals. This typing ledger does not establish bounds, text-position,
primitive, lowering or backend semantic correspondence.

The portable input preflight bounds every model/list occurrence before any
synchronous signature lookup or binding scan. Input and dispatcher budgets each
use `maxSteps`; each type operation has its own `maxTypeSteps` budget.
`visitedSteps` includes a completed input preflight and dispatcher work; a failed
preflight reports zero because its partial count is not returned. These are
separate bounded-work scopes, not a wall-clock or total allocation limit.
Finding counts count failed checking obligations: a type operation retains its
first error, and the finding-detail cap does not stop expression traversal.


The design requirements below record the pre-M6 gap and the implementation plan.
This document does not activate strict SH/1.
The current source and qualification results are recorded in
[IMPLEMENTATION.md](IMPLEMENTATION.md) and
[qualification-evidence.json](qualification-evidence.json).

## 1. The remaining architectural gap

The host inventory already tracks lexical scopes, annotated local types,
declarations, layouts and generic scope. Its `knownCall` helper recognizes a
variable with a known signature or a literal lambda. It does not infer the
type of a function-valued let, conditional, match, projection or another call.
Walking those child expressions does not return their types to the enclosing
call. The resulting `call-arity-needs-expression-typing` records are unfinished
checking obligations, not independent demonstrations of incorrect calls.

The existing erasure representation intentionally permits these shapes.
`psErasureEtaFunction` can construct a call whose callee is a function-valued
body. The next step is compositional IR typing over the current
`PsVerifiedIrType`, `PsVerifiedIrExpr` and `PsVerifiedIrModule`; it does not
require a replacement IR or new source-language inference.

Sources:
[host inventory](../../scripts/original-ir-inventory.mjs),
[original IR model](../../packages/compiler-ir/src/Ps/CompilerIr/Model.lean),
[eta construction](../../packages/erasure/src/Ps/Erasure/Expr.lean).

## 2. Reusable type and signature machinery

Build one portable implementation beside CompilerIr/Model.lean. Keep
well-formedness, equality and substitution separate from expression traversal,
and expose their explicit success/error results to the module checker.

- Retain ordered declaration and layout generic binders, not only their count.
- Distinguish the caller's type scope from the callee's generic telescope.
  Resolve parameters by owner/binder identity internally when names may overlap.
- Use simultaneous substitution. A mapping from two callee parameters to
  `[caller.T1, caller.T0]` must preserve that swap without recursively applying
  later substitutions inside an already selected replacement.
- Retain lexical term frames with checked monomorphic local types and nearest
  binding lookup. Predeclare all global signatures and layouts before bodies.
- Preserve the IR's actual function parameter grouping.
  `Function([A], Function([B], R))` is distinct from `Function([A, B], R)`.
- Keep generic schemes distinct from ordinary runtime function values.
  Unsupported uninstantiated generic values remain explicit obligations.

The current `psSubstituteVerifiedTypeWithFuel` illustrates the structural walk
but silently returns its input at zero fuel. Strict checking requires an
explicit exhausted result; it cannot reuse that fallback as success.

### Global values and functions

Follow the original backend's distinction:

| Declaration | Value type used by the checker |
| --- | --- |
| Nonempty runtime parameters | Function from those parameter types to resultType |
| Empty runtime parameters, no generics | resultType itself; it may be a function |
| Empty runtime parameters with generics | Preserve the existing genericValueUnsupported boundary |

The general TS emitter produces `export const` for the second case. Therefore,
an empty declaration parameter list must not automatically become an arity-zero
callable. This is a general signature rule, not a declaration-name exception.

Sources:
[type substitution](../../packages/erasure/src/Ps/Erasure/Expr.lean),
[declaration emission](../../packages/backend-ts/src/Ps/BackendTs/Module.lean).

## 3. Compositional infer/check operations

The conceptual public operations are:

- Infer an expression's runtime type under explicit type and term scopes.
- Check an expression against a supplied runtime type under those scopes.
- Check a whole module after its signature/layout declarations are registered.

| IR form | Required checks and resulting type |
| --- | --- |
| Variable | Resolve the nearest local binding or global value/scheme |
| Literal | Check its value domain and return its exact IR scalar type |
| Lambda | Check parameter/result annotations and body; return the annotated function type |
| Call | Infer callee, instantiate permitted generics, require a function, check exact runtime arity and argument types, return instantiated result |
| Let | Check initializer against its annotation in the old scope; check/infer the body under the new binding |
| If | Require Bool condition and compatible branch result types |
| Record/constructor | Instantiate its layout and check every field value and required order |
| Projection | Check target type/owner/instantiation and return the instantiated field type |
| Match | Check scrutinee, coverage, instantiated binding types and compatible branch results |
| Intrinsic | Instantiate an authoritative operand/result signature and check operation payloads |

Use the same type operations for calls and generic layouts. An arity-only
extension to `knownCall` would remain incomplete: false let/lambda annotations
could still supply apparently valid call arities. Check every declaration body
against its declared result, every lambda body against its result annotation,
and every let initializer against its annotated type.

For an empty match, use a justified expected-type rule for an empty inductive
or report an explicit unsupported case. Do not manufacture an unknown result.

## 4. Intrinsic, layout and import closure

The host inventory's intrinsic table supplies argument counts, not complete
operand/result types. The portable checker needs a declared signature ledger
for the enabled original target. Instantiate generic callbacks and collections
through the same scoped substitution mechanism used for ordinary calls.

Preserve type distinctions even when TS representations coincide: Nat and Int
both become bigint; Char and String both become string. TS acceptance cannot
replace these IR checks. Validate operation payloads such as signedness, width
and floating precision against enabled target capabilities.

Keep the existing field-name, duplicate, coverage and positional-constructor
checks. Named types need a module-owned layout or a declared runtime entry;
external import annotations require a separately qualified ABI contract.

Unused optional targets/scalars need not become prerequisites to this compiler's
narrow active contract. Unsupported enabled operations must fail explicitly.

Sources:
[IR intrinsic constructors](../../packages/compiler-ir/src/Ps/CompilerIr/Model.lean),
[intrinsic lowering](../../packages/erasure/src/Ps/Erasure/Expr.lean),
[TS type mapping](../../packages/backend-ts/src/Ps/BackendTs/Type.lean),
[TS expression emission](../../packages/backend-ts/src/Ps/BackendTs/Expr.lean).

## 5. Portable traversal and diagnostics

Use an explicit work stack or another bounded traversal expressible in the
already qualified authoring subset. Do not make mutual recursion or optional
syntax conveniences prerequisites. Resolve recursive references through their
predeclared signatures instead of recursively checking a referenced body.

Resource exhaustion is a distinct failure for expression/type/substitution
work. Capping stored diagnostic details must not stop obligation counting.
A complete traversal and successful validation remain separate outcomes.
An explicit unknown annotation never acts as a wildcard.

Memoization must include the relevant lexical/type environment identity,
rather than only an expression object's identity. Keep immutable compiler data
inside one compiler instance, consistent with the existing preparation seam.

Record structural IR paths, owners, callee forms, resolved signatures, supplied
type arguments, and expected/actual runtime types. The current IR has no source
origin field, so do not label these paths as source line numbers.

## 6. Integration and acceptance

1. Implement the portable type operations, ordered schemes and expression
   checker as one coherent slice. Keep the existing original TS-to-JS target.
2. Have the host inventory report this checker rather than maintain a second
   semantic checker that later needs a separate port.
3. Use focused native/generated examples for function-valued let/if/match/
   projection/call, generic substitution and malformed type annotations.
   Include the zero-parameter global-value distinction and explicit exhaustion.
4. Run the complete current compiler IR through the checker at the planned
   milestone, then current-source C2/C3 and the existing provider boundaries.
5. Connect a strict compilation path to successful checking of the exact IR
   passed to emission, and qualify that portable path through generated compilers.

The existing `PsVerifiedIrModule` type name itself conveys no extra evidence.

A successful expression checker still does not prove erasure or backend semantic
preservation. The full strict profile additionally needs its enabled primitive
laws, bounds/text-position contract, import ABI closure, evaluation-order/error
correspondence, actual enforcement and generated-compiler evidence. Preserve
those obligations explicitly; neither zero inventory findings nor selected
Core admission acceptance alone grants strict SH/1.
