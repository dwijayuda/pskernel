# Experimental JsIR v0

**Status:** experimental direct-JavaScript target slice. This is not yet a frozen compatibility contract and is not part of the compiler bootstrap closure.

Working identity:

```text
psc-js-ir/0-experimental
```

## Purpose

Establish an independent path:

```text
PsValidatedIrModule
        |
        v
      JsIR
        |
        v
deterministic ES2022 module text
        |
        v
       .js
```

without routing JavaScript execution through TypeScript.

The existing TypeScript backend remains the canonical bootstrap backend during this phase and serves as an independent differential oracle.

## Initial supported slice

The first lowerer intentionally supports only modules with:

- no external imports;
- no structures;
- no inductives;
- no declaration type parameters;
- parameter/result types limited to `Nat`, `Int`, `Bool`, `String`, and `Unit`;
- ECMAScript-safe ASCII declaration/parameter/reference names;
- natural/integer/string/bool/unit literals;
- variables;
- ordinary value calls with no type arguments;
- `if` expressions;
- `Nat.add`.

All other VerifiedIR constructs reject explicitly.

This is a proof-of-architecture slice, not a claim of JavaScript-backend completeness.

## JsIR model

The current JsIR contains:

```text
Literal
  natural
  integer
  string
  bool
  unit

Expression
  literal
  variable
  bigint-add
  call
  conditional

Declaration
  name
  value parameters
  expression body

Module
  ordered declarations
```

Types are checked as a lowering precondition but are not retained in this initial runtime JsIR.

## Identifier policy

The experimental slice accepts only conservative ASCII ECMAScript identifiers:

- first character: `A-Z`, `a-z`, `_`, or `$`;
- remaining characters additionally allow `0-9`;
- ECMAScript reserved words are rejected.

A later JsIR version may add a deterministic symbol/export mapping. The first slice rejects rather than silently renaming public declarations.

## Emission

The direct emitter produces deterministic ES2022 ESM.

Examples:

```js
export const answer = 42n;
export function idNat(x) { return x; }
export function plusOne(x) { return (x + 1n); }
```

There is no TypeScript syntax and no `tsc` step in the direct path.

## Runtime semantics

The backend declares and must refine:

```text
psc-runtime-semantics/1
```

For the initial slice, the only arithmetic intrinsic is `Nat.add`, represented using JavaScript `BigInt`.

Unsupported VerifiedIR operations are errors; they never fall back to backend-ts.

## Differential authority

The first conformance gate emits the **same validated IR fixture** through:

```text
ValidatedIR -> JsIR -> direct .js
ValidatedIR -> backend-ts -> .ts -> TypeScript 7.0.2 -> .js
```

Both modules are executed in Node and compared for:

- exported natural constant;
- identity function;
- `Nat.add`;
- ordinary function calls;
- conditional behavior;
- String literal;
- Bool literal;
- Unit/undefined.

Passing this differential test is evidence only for this closed initial slice.

## Bootstrap status

`backend-js` is explicitly forbidden from the bootstrap closure in this phase.

Promotion requires, at minimum:

1. expanded runtime-semantic differential coverage;
2. structures/ADTs/closures needed by the compiler;
3. target-name/export mapping;
4. source-map provenance;
5. `.d.ts` generation from interface information;
6. current compiler corpus emission;
7. direct-JS self-host fixed point;
8. cold/reference differential gates.

Until those gates close, backend-ts/driver-ts remain the canonical self-host backend.
