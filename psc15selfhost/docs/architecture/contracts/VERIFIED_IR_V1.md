# VerifiedIR validation contract v1

**Status:** implemented initial validation boundary. This contract intentionally states only what the current validator establishes; it is not yet the complete long-term VerifiedIR well-formedness contract.

Machine-oriented contract name:

```text
psc-verified-ir/1
```

## Purpose

The compiler previously used the historical `PsVerifiedIr*` node names directly for both construction and backend input, even though construction could leave `PsVerifiedIrType.unknown` in runtime positions.

The production architecture now distinguishes:

```text
Checked/prepared Core
        |
        v
erasure
        |
        v
PsErasedIrModule
        |
        v
psValidateErasedIrModule
        |
        v
PsValidatedIrModule
        |
        v
validated backend emitter
```

The underlying raw node family remains named `PsVerifiedIr*` temporarily to avoid a disruptive whole-tree rename. The wrapper types define the authority boundary.

## Current v1 invariant

A `PsValidatedIrModule` contains no `PsVerifiedIrType.unknown` in executable runtime type positions reachable through:

- external import types;
- structure field types;
- inductive constructor field types;
- declaration parameter types;
- declaration result types;
- expression type arguments;
- lambda parameter/result types;
- let-binding types;
- record/constructor/projection/match type arguments;
- match-binding types;
- nested function/named type arguments.

Validation is recursive and fuel-bounded. Exhausting validation depth fails closed rather than accepting an incompletely traversed module.

## Unknown-type inventory

At introduction time, every construction site for `PsVerifiedIrType.unknown` is in runtime-type erasure in `Ps.Erasure.Basic`.

The cases represent inability to derive a concrete executable runtime type, including:

- a free variable not classified as a runtime type parameter;
- an application whose normalized head is not a constant;
- a non-runtime forall/binder encountered where an executable type was requested;
- another unsupported normalized runtime-type shape.

No current `.unknown` case is defined as intentionally representation-irrelevant.

Therefore v1 rejects every reachable executable `.unknown`.

If ProofScript later needs a genuinely representation-irrelevant runtime type, add a distinct semantic constructor with explicit backend/runtime meaning. Do not weaken `unknown` validation.

## Construction API

```text
PsErasedIrModule {
  raw : PsVerifiedIrModule
}
```

Raw low-level erasure and low-level backend tests may continue to manipulate `PsVerifiedIrModule` while the migration is in progress.

The production compiler API constructs `PsErasedIrModule` after erasure.

## Validated API

```text
PsValidatedIrModule {
  raw : PsVerifiedIrModule
}
```

Only `psValidateErasedIrModule` constructs this wrapper on the production compiler path.

Compiler backend adapters call target-specific validated emitter entry points, which unwrap the validated module only inside the backend boundary.

## Error contract

Current validation failure:

```text
PsVerifiedIrValidationError.unresolvedRuntimeType
```

The compiler exposes this through:

```text
PsCompilerError.irValidation
```

More precise validation errors may be added when subsequent well-formedness checks are introduced.

## What v1 does not yet establish

This first validator does **not yet claim** complete validation of:

- global name uniqueness/resolution;
- call arity against declaration signatures;
- structure field existence/order;
- constructor/inductive consistency;
- intrinsic arity/type rules;
- match exhaustiveness/constructor ownership;
- external import identity/ABI compatibility;
- module-link compatibility.

Those are planned extensions of the ErasedIR → VerifiedIR boundary. Until they are implemented, do not describe `psc-verified-ir/1` as proving those properties.

## Backend rule

The production compiler path must be:

```text
psCompilerErasedIrFromPrepared
  -> psValidateErasedIrModule
  -> psCompilerVerifiedIrFromPrepared
  -> ps*EmitValidatedModule
```

A backend adapter that receives compiler-produced IR must not call a raw module emitter directly.

Low-level raw emitters remain useful for backend unit/negative tests but are not the production compiler composition boundary.

## Compatibility

Strengthening the validator with checks that reject previously malformed/uncontracted construction IR may remain within v1 when it only enforces invariants already required by the documented contract.

A change that gives previously invalid raw forms new executable semantics requires an explicit contract/version decision.

## Assurance status

Current evidence includes:

- self-host source-profile acceptance;
- Lean compilation;
- PSC parser/checker acceptance;
- positive resolved-module validation tests;
- negative top-level and nested `unknown` tests;
- existing erasure corpus;
- minimal self-host corpus;
- TypeScript backend corpus;
- semantic-boundary source gates.

A full compiler fixed point and native whole-closure contract remain release gates for the semantic checkpoint.
