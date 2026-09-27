# PSC2 KernelCore Phase 9 Design — Quot Bootstrap and Computation

Date: 2026-09-28

Branch: `psc2/kernel-core-phase9-quot`

Base: accepted Phase-8 closeout `2b9e36b3f6a2888193c9c7feb45caa9e44c36782`, whose tested implementation/assurance head is `381b610861035c4f092c6a60f58b5d0b0f4fa2bc`.

## 1. Purpose

Phase 9 adds the smallest trusted quotient island needed to match Lean 4.34's kernel-level Quot bootstrap on the explicitly covered surface. It builds on Phase 8's genuine admitted `Eq` / `Eq.refl`; it must not weaken that dependency by accepting a look-alike ordinary constant.

The phase has two semantic slices:

1. **Quot metadata/bootstrap** — represent quotient declarations, validate the admitted equality family, install `Quot`, `Quot.mk`, `Quot.lift`, `Quot.ind`, and preserve `quotInitialized` behavior.
2. **Bounded Quot computation** — reduce `Quot.lift`/`Quot.ind` only when their major argument weak-head reduces to `Quot.mk`, matching the mature kernel's covered rule.

Keeping these slices separate prevents reduction work from silently widening declaration trust.

## 2. Success criterion

Phase 9 succeeds when trusted PSC1-subset `.lean` code can:

- represent the four quotient declaration kinds;
- expose quotient declarations through existing constant accessors without making them delta-reducible definitions;
- reject Quot initialization unless genuine Phase-8 `Eq`/`Eq.refl` metadata has the expected bounded shape;
- reject collisions with reserved quotient names;
- install exactly the four quotient declarations with the expected universe parameters and types;
- set and preserve `quotInitialized`;
- make repeated initialization idempotent once `quotInitialized = true`;
- preserve the original environment on failed initialization;
- perform the bounded `Quot.lift` and `Quot.ind` computation rule when the major argument is a reducible `Quot.mk` application;
- remain residual for malformed/partial/non-Quot applications;
- keep all Phase-1 through Phase-8 assurance, actual PSC1 source/self-host checks, size reporting and full repository regression green.

## 3. Trusted metadata

Extend `Ps.KernelCore.Declaration` with:

```text
PsKernelCoreQuotKind
  typeQ
  ctorQ
  liftQ
  indQ

PsKernelCoreQuotInfo {
  base : PsKernelCoreConstantBase
  kind : PsKernelCoreQuotKind
}
```

Extend `PsKernelCoreConstantInfo` with:

```text
| quotInfo (value : PsKernelCoreQuotInfo)
```

All existing accessors must handle `quotInfo` conservatively:

- `base`, `name`, `levelParams`, `type`: expose stored base;
- `deltaValue?`: none;
- `hints?`: none;
- `isUnsafe`: false;
- `isPartial`: false;
- `isDefinition`: false;
- `definition?`: none.

No recursor metadata is introduced.

## 4. Equality prerequisite

Quot initialization must validate a genuine Phase-8 equality family rather than an arbitrary declaration with the right name.

The trusted check must require at least:

- `Eq` exists as `inductInfo`;
- exactly one universe parameter;
- exactly one constructor in its `ctors` list;
- the inductive type is structurally equivalent to the expected equality type modulo binder display names/annotations that Lean expression equality ignores on this surface;
- the named constructor exists as `ctorInfo` and belongs to `Eq`;
- the constructor has one universe parameter and the expected `Eq.refl` type;
- malformed variants fail closed.

The Phase-8 metadata contract remains binding: single family, non-recursive, non-nested, non-reflexive.

## 5. Quot bootstrap declarations

Reserved names:

```text
Quot
Quot.mk
Quot.lift
Quot.ind
```

If `env.quotInitialized = true`, initialization returns the same semantic environment without revalidating or re-adding declarations.

Otherwise all four names must be absent before any additions are returned. Failure is functional and leaves the caller's original environment unchanged.

The generated declaration types and universes should follow mature `PSC1Kernel.Quot` for the covered surface:

- `Quot.{u}` — quotient type former;
- `Quot.mk.{u}` — constructor-like introduction primitive;
- `Quot.lift.{u,v}` — quotient eliminator into `Sort v` with relation-respect proof;
- `Quot.ind.{u}` — proposition-valued induction primitive.

After all four declarations are added, return `psKernelCoreEnvironmentMarkQuotInitialized env4`.

The implementation may construct closed telescopes directly with de Bruijn indices if that is smaller and easier to keep PSC1-self-hostable than reproducing mature free-variable abstraction helpers. The resulting stored types are what parity tests pin.

## 6. Bounded computation rule

Phase 9 adds only the quotient primitive computation used by the mature kernel:

- if the application head is neither `Quot.lift` nor `Quot.ind`, remain residual;
- if the environment is not quotient-initialized, remain residual;
- find the major argument at the mature kernel's position (`5` for `Quot.lift`, `4` for `Quot.ind` after flattening application arguments);
- weak-head reduce that major argument using the same explicit resource/budget configuration;
- proceed only when the reduced major is exactly `Quot.mk` with three arguments;
- extract the representative from `Quot.mk` argument index `2`;
- extract the function/proof argument from eliminator argument index `3`;
- reduce to applying that argument to the representative, then reapply any trailing arguments after the major argument if present;
- malformed or underapplied shapes remain residual rather than erroring solely because the Quot rule did not fire.

No general recursor/iota machinery is introduced.

## 7. Resource and recursion discipline

The Quot reducer must thread the existing Phase-7 explicit resource configuration and Phase-3 reduction budget. It may not call a default-resource wrapper from inside an explicitly configured path.

Bootstrap declaration construction itself is pure and does not consume Nat numeral resources beyond existing ordinary checks.

## 8. PSC1 self-host restrictions

Trusted Phase-9 source inherits all current restrictions:

- no `partial`;
- no `unsafe` trusted implementation;
- no `extern` / `implemented_by`;
- no `IO`;
- no `Lean.*` or `Std.*` implementation dependency;
- no custom syntax/macros/elaborators;
- no `namespace` dependency where the source gate forbids it;
- no `mutual` trusted definitions;
- no termination annotations outside the accepted PSC1 profile;
- no host semantic `List` / `Option` storage where KernelCore-local carriers are required;
- no hash/index/cache/session/replay machinery.

Every trusted closure must pass the actual flattened `psc1 check` path.

## 9. Test-first evidence

Required RED/GREEN fixtures:

### 9.1 Metadata parity

`KernelCoreQuotMetadataTests.lean`

Covers the four quotient kinds and all existing `ConstantInfo` accessor/classification behavior against mature `PSC1Kernel`.

### 9.2 Bootstrap/admission parity

`KernelCoreQuotAdmissionParityTests.lean`

Covers:

- successful initialization from genuine admitted `Eq`/`Eq.refl`;
- all four declarations present with expected names, levels, types and kinds;
- `quotInitialized = true`;
- repeated initialization is idempotent;
- unrelated existing declarations are preserved.

### 9.3 Rejection matrix

`KernelCoreQuotRejectionTests.lean`

At minimum:

- missing Eq;
- Eq not `inductInfo`;
- wrong Eq universe arity;
- wrong Eq constructor count/name;
- missing constructor;
- constructor not `ctorInfo`/wrong parent;
- malformed Eq type;
- malformed refl type;
- each reserved Quot name collision;
- failure leaves the original environment observably unchanged.

### 9.4 Reduction parity

`KernelCoreQuotReductionParityTests.lean`

At minimum:

- initialized `Quot.lift ... (Quot.mk ... a)` reduces to `f a`;
- initialized `Quot.ind ... (Quot.mk ... a)` reduces to the proof/function applied to `a`;
- major expression is weak-head reduced before matching `Quot.mk`;
- uninitialized environment remains residual;
- underapplied eliminator remains residual;
- wrong major head remains residual;
- extra trailing arguments are preserved/reapplied;
- configured resource/budget path is used rather than a default wrapper.

## 10. Assurance gates

The exact accepted Phase-9 implementation head must pass:

```text
all Phase-1 through Phase-8 direct and aggregate gates
Phase-9 Quot metadata parity
Phase-9 Quot admission parity
Phase-9 Quot rejection matrix
Phase-9 Quot reduction parity
bootstrap-closure isolation
actual PSC1 KernelCore source profile
Phase-9 aggregate assurance
size reporter
full existing npm run check
```

No prior aggregate may be weakened or redefined to make Phase 9 pass.

## 11. Explicitly deferred work

Phase 9 does not include:

- general recursor metadata or recursor validation;
- iota reduction for ordinary inductives;
- recursive/mutual/nested inductives or strict positivity;
- projection computation or structure eta;
- Phase-7B Nat bitwise/shift work;
- native/eager reduction;
- K7/K8 full corpus parity through KernelCore;
- compiler `CheckedCore` provider cutover;
- removal of mature `PSC1Kernel`;
- formal proof of full Lean 4.34 equivalence.

## 12. Allowed claim after acceptance

> KernelCore has a PSC1-self-hostable Quot bootstrap tied to genuine Phase-8 equality metadata plus the bounded `Quot.lift`/`Quot.ind` computation rule, with exact differential/source/self-host/regression evidence on the explicitly covered surface; general recursor/iota/recursive-inductive and compiler-cutover semantics remain separately gated.
