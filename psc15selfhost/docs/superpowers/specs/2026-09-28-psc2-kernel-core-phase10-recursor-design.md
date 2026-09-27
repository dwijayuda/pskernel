# PSC2 KernelCore Phase 10 Design — Recursor Metadata and Bounded Iota

Date: 2026-09-28

Branch: `psc2/kernel-core-phase10-recursor`

Base: Phase-9 closeout `5b25873bebf35bfce50e271d97f2e7a7537d3350`, whose accepted tested implementation/assurance head is `09e4d6d3794816a0025f4b3339219cccde47af33`.

## 1. Purpose

Phase 10 adds the smallest trusted recursor metadata and direct-constructor iota computation slice needed to advance KernelCore beyond Phase 8/9 without importing the mature kernel's broad recursor machinery.

The phase deliberately keeps **recursor generation outside the trusted kernel**. KernelCore accepts only canonical recursor metadata supplied by an upstream elaboration/lowering layer, validates that metadata against an already-admitted Phase-8 non-recursive inductive family, stores it as trusted environment metadata, and performs a bounded computation rule when the recursor major argument weak-head reduces directly to an admitted constructor.

This preserves the intended architecture:

```text
source / elaboration / lowering
  -> canonical inductive + recursor metadata
  -> TRUST BOUNDARY
  -> KernelCore validates and admits metadata
  -> KernelCore performs bounded semantic reduction
```

## 2. Success criterion

Phase 10 succeeds when trusted PSC1-subset `.lean` code can:

- represent recursor rules and recursor metadata in `PsKernelCoreConstantInfo`;
- expose recursor constants through existing constant accessors while keeping them non-delta-reducible;
- validate a recursor only for an already-admitted single-family Phase-8 inductive;
- reject malformed family links, arities, rule sets, constructor links, level parameters, safety metadata, recursor types and rule RHS types;
- preserve functional failure semantics: rejected recursor admission leaves the caller's original environment unchanged;
- store the accepted recursor as `.recInfo`;
- detect a recursor application using stored metadata;
- compute the major argument index using Lean-compatible metadata layout;
- weak-head reduce the major argument under the existing explicit budget/resource configuration;
- fire iota only when the major argument is directly an admitted constructor application with a matching recursor rule;
- instantiate recursor universe parameters in the selected rule RHS;
- apply fixed recursor arguments and constructor fields in the mature-kernel order;
- preserve any trailing outer arguments after the major argument;
- remain residual rather than widening semantics when the recursor shape is unsupported or malformed;
- keep all Phase-1 through Phase-9 assurance, actual PSC1 source/self-host checks, size reporting and full repository regression green.

## 3. Trusted metadata

Extend `Ps.KernelCore.Declaration` with:

```text
PsKernelCoreRecursorRule {
  ctor : PsKernelCoreName
  nFields : Nat
  rhs : PsKernelCoreExpr
}

PsKernelCoreRecursorInfo {
  base : PsKernelCoreConstantBase
  all : PsKernelCoreList PsKernelCoreName
  numParams : Nat
  numIndices : Nat
  numMotives : Nat
  numMinors : Nat
  rules : PsKernelCoreList PsKernelCoreRecursorRule
  k : Bool
  isUnsafe : Bool
}
```

Extend `PsKernelCoreConstantInfo` with:

```text
| recInfo (value : PsKernelCoreRecursorInfo)
```

All existing accessors must handle `recInfo` conservatively:

- `base`, `name`, `levelParams`, `type`: expose stored base;
- `deltaValue?`: none;
- `hints?`: none;
- `isUnsafe`: stored `isUnsafe`;
- `isPartial`: false;
- `isDefinition`: false;
- `definition?`: none.

No cache, session, replay or generated-code state is trusted metadata.

## 4. Admission boundary

Phase 10 admits recursor metadata only for the Phase-8 family profile already accepted by KernelCore:

- exactly one inductive family in `all`;
- non-recursive;
- non-nested;
- non-reflexive;
- ordinary admitted constructor metadata already present in the environment.

The recursor admission path must **not** create, repair or reinterpret inductive or constructor metadata. It validates against what is already trusted in the environment.

The minimum trusted validation contract is:

1. the recursor name is fresh;
2. `recursor.all` contains exactly the target admitted family name;
3. the family exists as `.inductInfo` and still satisfies the Phase-8 bounded profile;
4. `numParams` and `numIndices` equal the admitted family metadata;
5. Phase 10 accepts exactly one motive (`numMotives = 1`);
6. `numMinors` equals the constructor count;
7. the recursor has exactly one rule per admitted constructor;
8. rule order matches constructor order;
9. every rule constructor exists as `.ctorInfo`, belongs to the target family, and has the expected constructor index/order;
10. every `rule.nFields` equals the admitted constructor `numFields`;
11. `recursor.k` must be false in Phase 10;
12. `recursor.isUnsafe` must match the family safety flag;
13. level parameter names are unique;
14. the recursor base type and every rule RHS are closed with respect to metavariables/free variables under the existing KernelCore closure checks;
15. all levels referenced by the recursor type and rules are covered by the recursor level parameters;
16. the recursor base type is accepted by existing trusted checking/inference machinery and has a sort type;
17. each rule RHS is type checked against the corresponding expected branch result under the canonical recursor binder ordering described below.

Any failed validation returns an error without returning a mutated environment.

## 5. Canonical recursor argument layout

Phase 10 follows the mature kernel's recursor application layout:

```text
[params..., motives..., minors..., indices..., major, trailing...]
```

The major argument index is therefore:

```text
majorIdx =
  numParams
+ numMotives
+ numMinors
+ numIndices
```

For this phase:

```text
numMotives = 1
numMinors = number of admitted constructors
```

The fixed arguments passed to a selected rule before constructor fields are:

```text
params ++ motives ++ minors
```

Indices select the major instance but are not separately passed to the rule RHS, matching the mature `reduceInductiveRecStatefulWith` computation order on this surface.

## 6. Rule type-preservation validation

Because recursor generation remains outside KernelCore, the trusted kernel must independently validate supplied rule semantics before admitting them.

For each constructor in constructor order:

1. identify the corresponding admitted constructor metadata;
2. recover the constructor field telescope after its shared parameters;
3. construct the constructor application from the shared parameters and field binders;
4. apply the recursor motive to the constructor result indices and constructed major value;
5. place canonical recursor binders in the environment/order expected by the supplied rule RHS;
6. infer/check the supplied `rule.rhs`;
7. require trusted definitional equality between the supplied RHS type and the expected branch result.

Since Phase-8 inductives are non-recursive, Phase 10 introduces **no induction-hypothesis binders** and performs no recursive-call validation.

This is intentionally smaller than mature `PSC1Kernel.Inductive`, whose recursor generator also handles recursive fields, functional recursive fields, K-targets and elimination-level selection.

## 7. Bounded direct-constructor iota

Reduction is added to the existing `Ps.KernelCore.Reduce` path.

The rule fires only when:

1. the application head is a constant found as `.recInfo` in the trusted environment;
2. the recursor universe argument count equals the recursor's level-parameter count;
3. the application contains a major argument at `majorIdx`;
4. the major argument weak-head reduces under the same explicit resource configuration and reduced budget;
5. the reduced major's application head is a constant naming an admitted constructor;
6. the recursor contains a rule for that constructor;
7. the constructor application supplies at least `rule.nFields` arguments.

Then:

```text
rhs0 = rule.rhs with recursor level params instantiated
rhs1 = rhs0 applied to (params ++ motives ++ minors)
fields = final rule.nFields arguments of the constructor application
rhs2 = rhs1 applied to fields
result = rhs2 applied to arguments after the major argument
```

The result is recursively reduced through the existing bounded WHNF path.

If any iota-specific precondition does not hold, the application remains residual; Phase 10 must not turn an unsupported recursor shape into an unrelated kernel error solely because the iota rule did not fire.

## 8. Eq compatibility target

Phase 8 already admits genuine `Eq` / `Eq.refl`, and Phase 10 should include a compatibility fixture demonstrating the bounded direct-constructor computation story for equality recursors.

The supported claim is narrow:

- an explicitly admitted equality recursor whose major argument is an actual admitted `Eq.refl` constructor application can reduce by the ordinary direct-constructor iota rule.

Phase 10 does **not** add general K conversion or constructor synthesis. If the major expression is not already a direct constructor application after ordinary WHNF, no special equality/K path is introduced.

## 9. Explicitly excluded mature recursor behavior

The following mature-kernel behavior remains outside Phase 10:

- recursive induction hypotheses;
- recursive, mutual or nested inductives;
- strict positivity;
- functional recursive fields;
- K-conversion constructor synthesis;
- proof irrelevance driven K recursor conversion beyond already existing DefEq behavior;
- structure eta or structure-to-constructor synthesis;
- Nat literal to constructor conversion for recursor matching;
- String literal to constructor conversion for recursor matching;
- projection computation;
- general elimination-level generation/selection inside KernelCore;
- recursor generation inside KernelCore;
- native/eager reduction;
- compiler `CheckedCore` provider cutover.

These exclusions are semantic boundaries, not merely missing tests.

## 10. Resource and recursion discipline

Phase 10 must thread the existing Phase-7 resource configuration and Phase-3 reduction budget exactly as the Phase-9 Quot reducer does.

The recursor hook may call the explicitly configured WHNF path for the major argument and selected reduced result. It may not call a default-resource wrapper from inside an explicitly configured path.

No new unbounded recursion, `partial`, host cache, memo table or session state is introduced to trusted KernelCore.

## 11. PSC1 self-host restrictions

Trusted Phase-10 source inherits all current restrictions:

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

## 12. Test-first evidence

Required RED/GREEN fixtures:

### 12.1 Metadata parity

`KernelCoreRecursorMetadataTests.lean`

Covers:

- `PsKernelCoreRecursorRule` and `PsKernelCoreRecursorInfo` representation;
- `.recInfo` constant metadata;
- all existing `ConstantInfo` accessor/classification behavior against mature `PSC1Kernel`.

### 12.2 Admission parity

`KernelCoreRecursorAdmissionParityTests.lean`

Covers:

- successful recursor admission for a representative Phase-8 single non-recursive family;
- one motive;
- one minor per constructor;
- multiple constructors where supported by Phase-8 metadata;
- parameters, indices and constructor fields;
- accepted metadata is stored as `.recInfo`;
- unrelated existing declarations are preserved.

### 12.3 Rejection matrix

`KernelCoreRecursorRejectionTests.lean`

At minimum:

- duplicate/freshness collision;
- missing target inductive;
- target not `.inductInfo`;
- wrong `all` family list;
- recursive/nested/reflexive target metadata;
- wrong parameter count;
- wrong index count;
- zero or multiple motives;
- wrong minor count;
- wrong rule count;
- wrong rule order;
- missing constructor;
- constructor not `.ctorInfo`;
- constructor belongs to another family;
- wrong constructor field count;
- `k = true`;
- safety mismatch;
- duplicate recursor universe parameter;
- uncovered universe parameter;
- mvar/fvar leakage;
- malformed recursor type;
- ill-typed rule RHS;
- failure leaves original environment observably unchanged.

### 12.4 Direct-constructor iota parity

`KernelCoreRecursorReductionParityTests.lean`

At minimum:

- direct constructor major fires matching rule;
- major is WHNF-reduced before constructor matching;
- constructor fields are passed in the mature-kernel order;
- parameters/motive/minors are passed before fields;
- indices are used only to locate the major and are not spuriously passed to the rule RHS;
- recursor universe parameters instantiate the rule RHS;
- trailing outer arguments are preserved/reapplied;
- underapplied recursor remains residual;
- wrong major head remains residual;
- unknown constructor remains residual;
- recursor level arity mismatch remains residual;
- configured resource/budget path is used rather than a default wrapper.

### 12.5 Eq direct-iota compatibility

`KernelCoreEqRecursorCompatibilityTests.lean`

Covers an explicitly admitted equality recursor reducing on an actual admitted `Eq.refl` major application without invoking K conversion.

## 13. Assurance gates

The exact accepted Phase-10 implementation head must pass:

```text
all Phase-1 through Phase-9 direct and aggregate gates
Phase-10 recursor metadata parity
Phase-10 recursor admission parity
Phase-10 recursor rejection matrix
Phase-10 direct-constructor iota parity
Phase-10 Eq direct-iota compatibility
bootstrap-closure isolation
actual PSC1 KernelCore source profile
Phase-10 aggregate assurance
size reporter
full existing npm run check
```

No previous aggregate may be weakened, removed or redefined to make Phase 10 pass.

## 14. Expected code boundary

The intended trusted-source delta is limited to:

```text
Ps/KernelCore/Declaration.lean   # bounded recursor metadata
Ps/KernelCore/Recursor.lean      # new validation/admission module
Ps/KernelCore/Reduce.lean        # bounded direct-constructor iota hook
Ps/KernelCore.lean               # aggregate export
```

Additional changes are expected only in Phase-10 tests, Lake/package scripts, CI assurance wiring, design/plan/acceptance documentation and size/reporting plumbing if required.

A need to add recursive-inductive, K, structure-eta, literal-constructor or compiler-provider machinery is a scope-upgrade signal and must stop Phase 10 rather than silently widening it.

## 15. Deferred work

After Phase 10, still separately gated:

- recursive/mutual/nested inductive admission;
- strict positivity;
- recursive recursor/IH semantics;
- K recursor conversion;
- structure eta and projection computation;
- literal-to-constructor recursor conversion;
- Phase-7B Nat bitwise/shift work;
- broader K7/K8 corpus routing through KernelCore;
- compiler `CheckedCore` provider cutover;
- removal of mature `PSC1Kernel`;
- formal proof of full Lean 4.34 equivalence.

## 16. Allowed claim after acceptance

> KernelCore has a PSC1-self-hostable recursor-metadata admission path for the explicitly bounded Phase-8 non-recursive family profile plus direct-constructor iota reduction, with exact differential/source/self-host/regression evidence; recursive-inductive/IH, K, structure/literal conversion and compiler-cutover semantics remain separately gated.
