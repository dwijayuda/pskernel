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

## Current v1 invariants

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

The validator also establishes these structural-reference invariants for executable expressions:

- every record target names a declared structure;
- every projection target names a declared structure;
- every record/projection structure type-argument list has the declared arity;
- every record field name belongs to the named structure;
- every projection field name belongs to the named structure;
- every constructor target names a declared inductive;
- every match target names a declared inductive;
- every constructor/match inductive type-argument list has the declared arity;
- every constructor name belongs to the named inductive;
- every match-alternative constructor belongs to the named inductive;
- every constructor field name belongs to the selected constructor;
- every match binding field name belongs to the selected constructor.

Validation is recursive and fuel-bounded. Exhausting structural-reference validation returns `validationFuelExhausted`; unresolved type traversal also fails closed rather than accepting an incompletely traversed module.

These rules establish ownership/membership and arity only. They do not yet establish field completeness, duplicate-field rejection, field value types, expression result types, or match exhaustiveness.

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

Current validation failures are:

```text
PsVerifiedIrValidationError.unresolvedRuntimeType
PsVerifiedIrValidationError.validationFuelExhausted
PsVerifiedIrValidationError.unknownStructure
PsVerifiedIrValidationError.unknownInductive
PsVerifiedIrValidationError.unknownConstructor
PsVerifiedIrValidationError.unknownStructureField
PsVerifiedIrValidationError.unknownConstructorField
PsVerifiedIrValidationError.typeArgumentArity
```

The compiler exposes validator failures through:

```text
PsCompilerError.irValidation
```

Errors identify the malformed target/name where useful so negative tests and future diagnostics can remain stable without depending on backend-specific failure modes.

## What v1 does not yet establish

The current validator does **not yet claim** complete validation of:

- global declaration/type name uniqueness;
- general `PsVerifiedIrType.named` name resolution and arity;
- variable scope/name resolution;
- call arity or argument/result typing against declaration signatures;
- exact record/constructor field completeness;
- duplicate record/constructor fields or duplicate match bindings;
- field value types against declared field types;
- intrinsic type-argument/value-argument arity and type rules;
- condition/result typing for `ifE`;
- match exhaustiveness, duplicate alternatives, or branch result-type equality;
- external import identity/ABI compatibility;
- module-link compatibility.

Those are planned monotonic extensions of the ErasedIR → VerifiedIR boundary. Until they are implemented, do not describe `psc-verified-ir/1` as proving those properties.

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

## Cloud execution gate

Pull requests targeting `psc2/selfhost-lean-kernel` run the focused cloud gate:

```text
.github/workflows/psc15selfhost-cloud.yml
```

That workflow checks the portable source profile, builds the relevant semantic/compiler/backend layers, runs the erasure/VerifiedIR, minimal-selfhost and TypeScript-backend corpora, enforces semantic-boundary rules, and asks PSC itself to check the modified compiler IR and compiler API source.

The workflow is installed on the repository default branch so pull requests targeting the PSC2 integration branch can be executed entirely in GitHub Actions rather than relying on a developer workstation.

## Assurance status

Current evidence includes:

- self-host source-profile acceptance;
- Lean compilation;
- PSC parser/checker acceptance;
- positive resolved-module validation tests;
- negative top-level and nested `unknown` tests;
- positive structural-reference validation;
- negative unknown structure/field/projection tests;
- negative structure type-argument arity tests;
- negative unknown inductive/constructor/constructor-field tests;
- negative match-constructor and match-binding-field tests;
- existing erasure corpus;
- minimal self-host corpus;
- TypeScript backend corpus;
- semantic-boundary source gates.

A full compiler fixed point and native whole-closure contract remain release gates for the semantic checkpoint.
