# PSC2 KernelCore Phase 8 Design — Minimal Non-Recursive Inductive Admission

Date: 2026-09-28

Branch: `psc2/kernel-core-phase8-inductive`

Base: accepted Phase-7 reviewed branch `psc2/kernel-core-phase7-primitives` at `b166c1890e28dcd6d09892bcf19d23286a642b55`

## 1. Purpose

Phase 8 introduces the smallest trusted inductive/constructor metadata and admission layer required to represent Lean's `Eq` as a genuine inductive declaration, rather than as a specially trusted ordinary constant.

The immediate architectural purpose is to establish a sound dependency for the following Quot phase. Mature Quot bootstrap logic requires that `Eq` already exists as an inductive with the expected constructor shape; therefore Phase 8 must make this statement meaningful inside `pskernel-core` before Quot is added.

Phase 8 is intentionally narrower than general Lean inductive support.

## 2. Success criterion

Phase 8 succeeds when KernelCore can, through trusted PSC1-subset `.lean` code:

1. represent non-recursive inductive metadata and constructor metadata;
2. validate and functionally admit a bounded single-inductive declaration and its constructors;
3. support indexed but non-recursive inductives such as Lean's `Eq`;
4. reject any constructor field/type that recursively refers to the new inductive;
5. store the admitted declaration as genuine `inductInfo` / `ctorInfo` entries in `PsKernelCoreEnvironment`;
6. recognize a correctly admitted `Eq` / `Eq.refl` pair in a form sufficient for the next Quot phase;
7. match `PSC1Kernel` on the directly covered admission surface;
8. keep all Phase-1 through Phase-7 assurance green;
9. keep the actual PSC1 self-host source gate green;
10. keep the full existing `npm run check` regression green.

This phase does not need to generate recursors or make recursive inductives work.

## 3. Why Phase 8 precedes Quot

The mature kernel's Quot bootstrap first validates that:

- `Eq` is stored as an inductive declaration;
- it has exactly the expected universe shape;
- it has exactly the expected constructor list;
- the referenced equality constructor exists;
- the constructor has the expected type.

A direct Quot phase on the current KernelCore would have only three choices:

1. weaken this requirement;
2. treat an ordinary axiom/constant with the correct type as `Eq`;
3. add hidden special-purpose trust logic.

All three enlarge or weaken the TCB in the wrong direction. Phase 8 instead gives the small kernel a real, reusable declaration representation for the minimum inductive shape Quot depends on.

## 4. Scope

### 4.1 Trusted declaration metadata

Extend `Ps.KernelCore.Declaration` with:

```text
PsKernelCoreInductiveInfo
PsKernelCoreConstructorInfo
```

Recommended fields mirror only the semantic subset needed by this phase and future compatibility:

```text
PsKernelCoreInductiveInfo {
  base       : PsKernelCoreConstantBase
  numParams  : Nat
  numIndices : Nat
  all        : PsKernelCoreList PsKernelCoreName
  ctors      : PsKernelCoreList PsKernelCoreName
  numNested  : Nat
  isRec      : Bool
  isReflexive: Bool
  isUnsafe   : Bool
}

PsKernelCoreConstructorInfo {
  base      : PsKernelCoreConstantBase
  induct    : PsKernelCoreName
  cidx      : Nat
  numParams : Nat
  numFields : Nat
  isUnsafe  : Bool
}
```

Extend:

```text
PsKernelCoreConstantInfo
```

with:

```text
| inductInfo (value : PsKernelCoreInductiveInfo)
| ctorInfo   (value : PsKernelCoreConstructorInfo)
```

Existing accessors (`base`, `name`, `levelParams`, `type`, unsafe/partial flags) must be updated conservatively.

No recursor metadata is added in Phase 8.

### 4.2 Admission model

The phase introduces a trusted admission entry point for one non-recursive inductive family and its constructors.

The implementation may accept a compact request structure or explicit parameters, but the trusted semantic contract must validate before mutating the returned environment.

Recommended public semantic shape:

```text
psKernelCoreAddNonRecursiveInductive
  : Nat
  -> PsKernelCoreResourceConfig
  -> PsKernelCoreEnvironment
  -> PsKernelCoreInductiveInfo
  -> PsKernelCoreList PsKernelCoreConstructorInfo
  -> PsKernelCoreResult String PsKernelCoreEnvironment
```

Exact API spelling can be adjusted during planning if existing Phase-7 `...WithResources` conventions make another wrapper shape cleaner. Existing resource-wrapper conventions must remain intact.

### 4.3 Accepted semantic surface

Phase 8 accepts only a single inductive family with no recursive occurrence of itself in any constructor argument/type position other than the constructor result head.

The checker must validate at least:

- fresh inductive name;
- fresh constructor names;
- no duplicate constructor names;
- unique universe parameter names;
- no expression metavariables;
- no universe metavariables;
- no free variables after declaration closure;
- all referenced universe parameters are declared;
- inductive declared type is well-formed;
- constructor declared types are well-formed in the work environment;
- constructor universe parameters match the inductive's universe parameter contract;
- constructor result reduces/exposes to the new inductive constant;
- constructor result has the expected parameter/index arity;
- parameter prefix agrees with the inductive family;
- `constructor.induct` names the new inductive;
- `constructor.cidx` matches its position;
- `constructor.numParams` agrees with the inductive;
- `constructor.numFields` agrees with the constructor telescope after parameters;
- `inductive.ctors` agrees exactly with the admitted constructor sequence;
- `inductive.all` is valid for the bounded single-family case;
- `numNested = 0`;
- `isRec = false`;
- no recursive occurrence of the new inductive appears in constructor domains or other forbidden positions;
- unsafe metadata is propagated consistently with existing safety rules;
- failure leaves the caller's original environment unchanged.

The implementation must fail closed on unsupported shapes rather than silently accepting a more general inductive.

## 5. Non-recursion rule

Phase 8 deliberately avoids implementing strict positivity.

Instead, it enforces the stronger bounded rule:

> The newly declared inductive constant may not occur recursively in any constructor field/domain/type position, except as the constructor result head applied to the declared parameters/indices.

This rule is sufficient for `Eq`, which is indexed but not recursive.

Because recursive occurrences are rejected outright, this phase must not claim support for:

- `Nat`;
- `List`;
- recursive trees;
- mutual recursion;
- nested recursion;
- reflexive/nested positivity;
- any general strict-positivity algorithm.

## 6. `Eq` target fixture

The central compatibility fixture is Lean's equality family:

```text
Eq.{u} : {α : Sort u} -> α -> α -> Prop
Eq.refl : {α : Sort u} -> (a : α) -> Eq a a
```

Phase 8 must prove, through its own trusted representation, that:

- `Eq` is an `inductInfo`;
- it has one universe parameter;
- it has the expected parameter/index counts;
- it has exactly the expected constructor name list;
- `Eq.refl` is a `ctorInfo` referring to `Eq`;
- `Eq.refl` has the expected constructor telescope/result;
- the pair is accepted by direct differential fixtures against the mature `PSC1Kernel` admission path for the bounded overlap.

This does not require recursor generation or equality eliminator computation yet.

## 7. Environment behavior

The existing linear `PsKernelCoreEnvironment` remains the semantic environment.

No hash table, Array index, cache, session state, or replay machinery may enter the trusted core.

Admission should use a temporary/work environment when necessary so constructor types can reference the new inductive while preserving pure functional rejection semantics.

A failed declaration must return an error without mutating the caller's original environment value.

## 8. Interaction with existing semantic layers

### 8.1 Infer / Check

Phase 8 should add only the minimum recognition needed for inductive/constructor constants to participate as ordinary constants via their stored types and safety metadata.

No special recursor inference or projection inference is introduced.

### 8.2 Reduce / DefEq

No iota computation is introduced.

No constructor projection computation is introduced.

No structure eta is introduced.

Existing reduction/DefEq behavior should remain unchanged except for treating newly stored inductive/constructor declarations as non-delta-reducible constants with valid types/safety metadata.

### 8.3 Admission

Ordinary axiom/definition/theorem/opaque admission remains unchanged.

Phase 8 adds a separate bounded inductive admission path rather than overloading ordinary declaration admission with unreviewed complexity.

## 9. PSC1 self-host constraints

All trusted Phase-8 source must remain inside the already enforced PSC1-compatible subset.

Non-negotiable restrictions remain:

- no `partial`;
- no `unsafe` trusted implementation;
- no `extern` / `implemented_by`;
- no `IO`;
- no `Lean.*` implementation dependency;
- no `Std.*` implementation dependency;
- no custom syntax/macros/elaborators;
- no `namespace` dependency in trusted code where the current source gate forbids it;
- no `mutual` trusted definitions;
- no termination annotations or recursion machinery outside the accepted PSC1 profile;
- no host semantic `List` / `Option` storage where KernelCore local carriers are required;
- no host hash/index/cache/session machinery.

Every trusted closure must pass the actual flattened `psc1 check` path, not merely Lean compilation or lexical linting.

## 10. Differential and RED/GREEN evidence

Implementation must follow the established test-first sequence.

Required direct fixtures should include at least:

### Declaration representation

- `inductInfo` accessor parity;
- `ctorInfo` accessor parity;
- unsafe/partial/definition classification behavior.

### Positive admission

- simple non-indexed non-recursive one-constructor inductive;
- multi-constructor non-recursive inductive if it fits the same bounded logic;
- indexed `Eq` shape;
- constructor metadata stored exactly as expected;
- original `quotInitialized` flag preserved.

### Negative admission

- duplicate inductive name;
- duplicate constructor name;
- duplicate universe parameter;
- expression metavariable;
- universe metavariable;
- free variable;
- undefined universe parameter;
- malformed inductive sort/type;
- constructor whose result is not the new inductive;
- wrong result arity;
- wrong parameter prefix;
- wrong `induct` field;
- wrong constructor index;
- wrong `numParams`;
- wrong `numFields`;
- inconsistent `ctors` list;
- unsupported nested/mutual metadata;
- any recursive occurrence in a constructor domain;
- malformed `Eq` / `Eq.refl` variants;
- rejected admission leaves the original environment observably unchanged;
- explicit budget/resource exhaustion where Phase-7 resource plumbing makes it relevant.

The direct oracle is the corresponding bounded behavior of mature `PSC1Kernel` where available. KernelCore-only fail-closed tests must cover restrictions that are intentionally stronger than the mature kernel's full feature set.

## 11. Assurance gates

The exact accepted Phase-8 implementation head must pass:

```text
all Phase-1 through Phase-7 direct parity gates
Phase-8 declaration-metadata parity
Phase-8 non-recursive-inductive admission parity
Eq / Eq.refl compatibility fixture
bootstrap-closure isolation
actual PSC1 KernelCore source profile
Phase-1 aggregate assurance
Phase-2 aggregate assurance
Phase-3 aggregate assurance
Phase-4 aggregate assurance
Phase-5 aggregate assurance
Phase-6 aggregate assurance
Phase-7 aggregate assurance
Phase-8 aggregate assurance
full existing npm run check
```

No earlier aggregate may be weakened or redefined to make Phase 8 pass.

The size reporter must be rerun on the exact accepted implementation head.

## 12. Bootstrap / compiler boundary

`pskernel-core` remains outside the active PSC2 compiler bootstrap admission closure during Phase 8.

This phase does not make KernelCore the authoritative `CheckedCore` provider and does not rename `AdmissionReadyModule`.

Compiler cutover remains separately gated after the remaining foundational semantic islands are mature enough.

## 13. Explicitly deferred work

Phase 8 does not include:

- strict positivity;
- recursive inductives;
- mutual inductives;
- nested inductives;
- recursor metadata;
- recursor generation;
- recursor validation;
- iota reduction;
- projection computation;
- structures;
- structure eta;
- Quot declarations;
- Quot computation;
- Phase-7B Nat bitwise/shift operations;
- String constructor expansion;
- native/eager reduction;
- exact Lean heartbeat/maxRecDepth semantics;
- K7/K8 corpus parity through KernelCore;
- compiler CheckedCore provider cutover;
- removal of mature PSC1Kernel;
- full or formal Lean 4.34 equivalence.

## 14. Allowed claims after acceptance

If all gates pass, the strongest intended claim is:

> KernelCore supports a PSC1-self-hostable, fail-closed non-recursive inductive/constructor admission slice with direct differential evidence for the explicitly covered surface, including a genuine admitted `Eq` / `Eq.refl` representation sufficient to unblock a later Quot phase; recursive/positive/recursor/iota/projection/Quot and compiler-cutover semantics remain separately gated.

It must not be described as general inductive support.

## 15. Next phase

After Phase 8 acceptance, the preferred next architectural phase is Quot:

1. validate the admitted genuine `Eq` / `Eq.refl` shape;
2. install `Quot`, `Quot.mk`, `Quot.lift`, `Quot.ind` as trusted quotient declarations;
3. preserve `quotInitialized` semantics;
4. add the bounded Quot computation rule to reduction/DefEq;
5. preserve all prior self-host/parity/regression gates.

Only after Quot should the roadmap decide between Phase-7B bitwise/shifts and the larger recursive-inductive/recursor/positivity program.
