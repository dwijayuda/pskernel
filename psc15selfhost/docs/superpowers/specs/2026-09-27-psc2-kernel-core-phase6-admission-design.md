# PSC2 KernelCore Phase 6 — Checked Inference and Non-Inductive Declaration Admission Design

Status: design for review

Date: 2026-09-27

Base branch: `psc2/kernel-core-phase5-defeq`

Base merge SHA: `5b2b0879e57aaad95f947c911d55197b871316a8`

## 1. Purpose

Phase 6 turns the accepted infer-only + DefEq substrate into the first small trusted checker that can validate ordinary expressions and admit ordinary non-inductive declarations.

Accepted prerequisites are:

- Phase 1: `Name`, `Level`, `Expr`, substitution;
- Phase 2: declarations, environment, local context;
- Phase 3: basic total WHNF;
- Phase 4: infer-only type inference;
- Phase 5: bounded definitional equality.

Phase 6 adds two trusted semantic modules:

```text
Ps.KernelCore.Check
Ps.KernelCore.Admission
```

The result is a PSC1-self-hostable path for checking ordinary terms and admitting:

```text
axiom
definition
theorem
opaque
```

without yet trusting inductive, recursor, Quot, primitive/native, mutual-definition, or compiler-cutover semantics.

Phase 6 is not the complete Lean 4.34 kernel declaration checker.

## 2. Architectural choice

Phase 6 must **not** rewrite accepted `Ps.KernelCore.Infer` into a new `inferOnly : Bool` engine.

The mature `PSC1Kernel` uses a unified `inferCore ... inferOnly` implementation, but changing the accepted Phase-4 infer-only layer now would:

- enlarge the regression surface;
- make Phase-4 evidence harder to interpret;
- risk repeating the PSC1 elaboration-pathology problem encountered during Phase 5;
- mix a new checked-trust boundary with a refactor of an already accepted one.

Instead, Phase 6 adds a separate checked layer that reuses accepted lower-layer semantics.

The trusted dependency direction is:

```text
Infer
  ↓
DefEq
  ↓
Check
  ↓
Admission
```

`Check` may reuse names/helpers from `Infer`, but `Infer` remains semantically unchanged in Phase 6.

`Admission` depends on `Check` and accepted declaration/environment semantics.

This controlled duplication is acceptable because each layer has one clear contract and independent differential evidence.

## 3. Trusted module boundary

Create exactly two new trusted modules unless implementation proves a strong reason for one additional narrowly scoped helper module:

```text
packages/pskernel-core/src/Ps/KernelCore/Check.lean
packages/pskernel-core/src/Ps/KernelCore/Admission.lean
```

Export them from:

```text
packages/pskernel-core/src/Ps/KernelCore.lean
```

Expected trusted closure after Phase 6:

```text
14 modules
```

counting the aggregate module, unless a documented portability constraint requires one extra trusted helper module.

The target is semantic clarity, not a fixed LOC target.

## 4. `Check` public contract

Primary entry point:

```text
psKernelCoreCheck :
  Nat ->
  PsKernelCoreEnvironment ->
  PsKernelCoreLocalContext ->
  PsKernelCoreDefinitionSafety ->
  PsKernelCoreExpr ->
  PsKernelCoreResult String PsKernelCoreExpr
```

Arguments:

1. explicit KernelCore budget;
2. environment;
3. local context;
4. safety context of the declaration currently being checked;
5. expression.

Return value is the checked expression's type.

Budget `0` returns exactly:

```text
check budget exhausted
```

Trusted source must not use `partial`.

Recursive calls must use a PSC1-accepted decreasing-budget/currying shape.

## 5. Why `Check` is distinct from `Infer`

Accepted Phase-4 `psKernelCoreInfer` intentionally models mature infer-only behavior. In particular, it skips checks that full kernel checking performs.

Phase 6 `psKernelCoreCheck` adds the missing obligations:

- application argument checking;
- lambda-domain sort checking;
- let declared-type sort checking;
- let value type checking;
- safe/unsafe/partial constant-use restrictions.

`Check` must not change Phase-4 infer-only behavior.

## 6. Checked-expression semantics

### 6.1 Bound variables

Loose bound variables fail closed with the accepted checker error family.

Phase 6 may use the exact stable message:

```text
loose bound variable in type checker
```

### 6.2 Expression metavariables

Expression metavariables are not accepted by the trusted checker:

```text
kernel type checker does not support metavariables
```

### 6.3 Free variables

A free variable must exist in the local context.

Its declared local type is returned.

Unknown free variables fail closed.

### 6.4 Sorts

`sort u` has type:

```text
sort (succ u)
```

using accepted KernelCore level semantics.

### 6.5 Constants and safety restrictions

For a constant reference:

1. declaration must exist;
2. universe argument count must match declaration parameters;
3. if the referenced declaration is unsafe and the current safety context is not unsafe, reject it;
4. if the referenced declaration is partial and the current safety context is safe, reject it;
5. otherwise instantiate the declaration type with the supplied universe levels.

Stable safety errors:

```text
safe declaration uses unsafe constant
safe declaration uses partial constant
```

Phase 6 does not add primitive/native execution just because a constant has a special Lean name.

### 6.6 Literals

Supported literals keep the already accepted Phase-4 typing behavior:

```text
Nat literal    -> Nat
String literal -> String
```

Phase 6 parity fixtures must use ordinary small Nat literals. Exact Lean `maxNatSize` resource behavior is deferred to the later resource/primitive phase.

### 6.7 Metadata

Metadata is transparent for checked inference.

### 6.8 Applications

For `app fn arg`:

1. recursively check `fn`;
2. expose its type as a forall using accepted WHNF;
3. recursively check `arg`;
4. compare the inferred argument type against the forall domain with Phase-5 DefEq;
5. if equal, instantiate the forall body with `arg` and return it;
6. otherwise reject with an application-type mismatch.

The trusted semantic condition is DefEq failure/success, not exact reproduction of mature diagnostic prose.

The Phase-6 small-core stable mismatch error may be:

```text
application type mismatch
```

Differential fixtures compare accept/reject semantics and successful result types; they do not require byte-for-byte equality with mature rich diagnostics.

Phase 6 does not implement the mature `eagerReduce` marker special case. Fixtures requiring that marker are excluded.

### 6.9 Lambdas

For a lambda:

1. recursively check the domain;
2. require the domain's type to expose a sort;
3. create a deterministic fresh local;
4. open the body with that local;
5. recursively check the opened body under the extended local context;
6. close the inferred body type and return the corresponding forall.

Unlike infer-only mode, a malformed lambda domain must fail.

### 6.10 Foralls

For a forall:

1. recursively check the domain;
2. require its inferred type to expose a sort;
3. open the body under a deterministic fresh local;
4. recursively check the opened body;
5. require the body's inferred type to expose a sort;
6. return the sort formed with accepted `imax` semantics.

This matches the already accepted infer-only structural result while adding full safety/checked traversal of nested references.

### 6.11 Lets

For a let expression:

1. recursively check the declared type;
2. require that inferred type to expose a sort;
3. recursively check the value;
4. require DefEq between value type and declared type;
5. extend the local context with the checked let;
6. open and recursively check the body;
7. close the resulting type using the accepted Phase-4 binder-closing behavior, removing a dead type-level let when permitted by the accepted contract.

Stable small-core mismatch error:

```text
let value type mismatch
```

Unlike infer-only mode, malformed declared types and mismatched values must fail.

### 6.12 Projections

Projection checking remains unavailable before trusted inductive/constructor metadata.

Fail closed with:

```text
projection checking unavailable before inductive metadata
```

Do not infer projection types from unvalidated metadata.

## 7. DefEq integration

`Check` calls accepted Phase-5:

```text
psKernelCoreIsDefEq
```

for application and let-value type comparison.

If DefEq returns an error, propagate it.

If DefEq returns `ok false`, return the Phase-6 mismatch error.

Phase 6 must not reimplement equality rules in `Check`.

## 8. Checked-expression budget semantics

Budget follows the same explicit small-core discipline used in Phases 3–5.

For:

```text
psKernelCoreCheck (Nat.succ remaining)
```

- recursive `Check` calls receive `remaining`;
- lower-layer WHNF calls receive `remaining`;
- lower-layer DefEq calls receive `remaining`.

Lower-layer budget failures keep their existing error strings.

The Phase-6 fixture must pin at least one threshold where:

- budget `N - 1` fails;
- budget `N` succeeds.

The budget is a totality/resource contract, not a claim of exact Lean recursion-depth accounting.

## 9. `Admission` public contract

Phase 6 introduces ordinary non-inductive declaration admission APIs:

```text
psKernelCoreAddAxiom :
  Nat ->
  PsKernelCoreEnvironment ->
  PsKernelCoreAxiomInfo ->
  PsKernelCoreResult String PsKernelCoreEnvironment

psKernelCoreAddDefinition :
  Nat ->
  PsKernelCoreEnvironment ->
  PsKernelCoreDefinitionInfo ->
  PsKernelCoreResult String PsKernelCoreEnvironment

psKernelCoreAddTheorem :
  Nat ->
  PsKernelCoreEnvironment ->
  PsKernelCoreTheoremInfo ->
  PsKernelCoreResult String PsKernelCoreEnvironment

psKernelCoreAddOpaque :
  Nat ->
  PsKernelCoreEnvironment ->
  PsKernelCoreOpaqueInfo ->
  PsKernelCoreResult String PsKernelCoreEnvironment
```

These APIs return a new environment only after all required validation succeeds.

The input environment remains immutable, so rejection cannot partially mutate it.

Budget `0` returns:

```text
admission budget exhausted
```

unless a lower-layer call reached from a positive budget returns its own established budget error first.

## 10. Shared declaration-base validation

Before admitting any ordinary declaration, Phase 6 validates its `PsKernelCoreConstantBase`.

Required order:

1. reject an already-declared name;
2. reject duplicate universe parameter names;
3. reject expression metavariables in the declared type;
4. reject free variables in the declared type;
5. reject universe metavariables in the declared type;
6. reject references to undefined universe level parameters;
7. checked-infer the declared type under the declaration's safety context;
8. require its inferred type to expose a sort.

Stable errors should align with the mature kernel where practical:

```text
already declared
duplicate universe parameter
declaration has metavariables
declaration has free variables
invalid reference to undefined universe level parameter
```

Universe metavariables are included in the metavariable rejection contract.

## 11. Admission-owned structural validation helpers

To avoid bloating foundational `Expr`/`Level` modules solely for declaration admission, `Admission.lean` may own small trusted helpers for:

```text
name membership over PsKernelCoreList
find undefined level parameter
find undefined expression level parameter
expression has metavariable
expression has free variable
closed-expression validation
level-parameter validation
```

These helpers must be:

- pure;
- structurally recursive;
- PSC1-self-hostable;
- directly unit-tested or exercised by the admission differential fixture.

Do not add unchecked host-side validation whose result is trusted by the kernel.

## 12. Axiom admission

For an axiom:

1. derive checking safety from `isUnsafe`;
2. validate the constant base;
3. add the axiom to the environment through trusted environment semantics.

No body exists.

An unsafe axiom may be admitted after the same base validation under unsafe checking context.

## 13. Definition admission

### 13.1 Common body validation

Definition body validation requires:

1. no expression metavariables;
2. no free variables;
3. no universe metavariables;
4. no undefined universe-level parameters;
5. checked inference of the value under the required safety context;
6. DefEq between inferred value type and declared type.

Stable mismatch error:

```text
definition type mismatch
```

### 13.2 Safe definitions

For `.safe` definitions:

1. validate header under safe context;
2. validate body against the original environment under safe context;
3. only then add the declaration.

Safe code must reject unsafe and partial constant use through `Check`.

### 13.3 Partial definitions

For `.partialDef` definitions, match the mature ordinary-single-definition behavior used by `PSC1Kernel.Kernel.addDefinition`:

1. validate header under safe checking context;
2. validate the body under safe checking context;
3. validate before adding the declaration to the returned environment.

Phase 6 does not add special mutual/recursive partial-definition admission.

A single partial definition is therefore not automatically granted self-reference merely because its safety tag is partial.

### 13.4 Unsafe definitions and self-reference

For `.unsafeDef` definitions, preserve the mature single-definition behavior:

1. validate the header against the original environment under unsafe context;
2. add the **full definition** to a temporary work environment;
3. check the body under unsafe context against that work environment;
4. on success, return the work environment;
5. on failure, return an error and the caller retains the original immutable environment.

This intentionally permits an unsafe recursive body to reference and unfold itself while being checked.

Phase-6 fixtures must include a bounded accepted unsafe self-reference case and a rejected malformed unsafe definition case.

The explicit KernelCore budget remains responsible for terminating trusted checking.

## 14. Theorem admission

For a theorem:

1. validate its constant base under safe context;
2. prove that the declared theorem type is a proposition;
3. validate the proof expression is closed and uses only declared universe parameters;
4. checked-infer the proof under safe context;
5. require DefEq between proof type and declared theorem type;
6. add the theorem only after success.

Stable theorem errors:

```text
theorem type is not a proposition
theorem proof type mismatch
```

### 14.1 Proposition test

`Admission.lean` may define a small helper conceptually:

```text
psKernelCoreIsProp :
  Nat ->
  PsKernelCoreEnvironment ->
  PsKernelCoreExpr ->
  PsKernelCoreResult String Bool
```

It should checked-infer the expression and use accepted WHNF to determine whether its type is `sort 0` under accepted level-normalization semantics.

Do not add a separate theorem-specific equality algorithm.

## 15. Opaque admission

Opaque bodies are checked by the ordinary **safe** checker, even when `OpaqueInfo.isUnsafe` is set, matching the mature reference boundary.

Required flow:

1. validate constant base under safe checking context;
2. validate the opaque value is closed and level-correct;
3. checked-infer the opaque value under safe context;
4. require DefEq with the declared type;
5. add only after success.

Stable mismatch error:

```text
opaque value type mismatch
```

`OpaqueInfo.isUnsafe` remains declaration metadata; it does not relax body checking in this Phase-6 admission path.

## 16. Environment mutation discipline

Admission is pure and functional.

A rejected declaration must never appear in the returned environment because no successful environment is returned.

For tests, retain the original environment and prove:

```text
size unchanged
name absent
existing declarations unchanged
quotInitialized unchanged
```

after every rejected admission attempt.

Phase 6 must not add hash indexes, mutable sessions, caches, or host-side mutation to trusted environment semantics.

## 17. Deliberately deferred semantics

Phase 6 must **not** add:

- inductive declaration forms;
- constructor declaration forms;
- recursor metadata;
- positivity checking;
- recursor validation;
- iota reduction;
- projection inference/computation;
- structure eta;
- Quot declaration/admission/computation;
- mutual-definition admission;
- nested-inductive lowering;
- complex-inductive preprocessing;
- native evaluator/provider;
- Nat primitive arithmetic reduction beyond previously accepted behavior;
- String constructor expansion;
- exact `maxNatSize` behavior;
- exact mature recursion-depth/heartbeat accounting;
- checker sessions/caches;
- compiler `CheckedCore` cutover;
- K7/K8 corpus claims through KernelCore;
- full Lean 4.34 equivalence.

If a proposed fixture needs one of these features, defer the fixture rather than widening Phase 6.

## 18. Differential oracle for checked expressions

The mature checked-expression oracle is:

```text
PSC1Kernel.check
```

using a matched mature environment/local context/safety configuration.

The test adapter remains outside trusted source.

Phase-6 parity claims apply only to the explicitly selected overlap surface.

Rich mature error prose does not need byte-for-byte reproduction where the small core intentionally uses a stable shorter mismatch error. The fixture must still compare:

- success vs rejection;
- successful inferred type;
- exact messages for explicitly pinned KernelCore boundary/safety errors.

## 19. Required checked-expression RED matrix

Before production `Check.lean` exists, create a failing differential executable covering at least:

### Positive cases

1. sort;
2. known local variable;
3. monomorphic constant;
4. polymorphic constant with valid universe instantiation;
5. small Nat literal;
6. String literal;
7. metadata transparency;
8. well-typed application;
9. dependent application;
10. lambda whose domain is a valid type;
11. dependent lambda;
12. forall with valid domain/codomain sorts;
13. valid let;
14. dependent let;
15. unsafe constant used from unsafe checking context;
16. partial constant used from partial/unsafe-permitted context where the mature oracle permits it.

### Negative cases

17. loose bound variable;
18. expression metavariable;
19. unknown free variable;
20. unknown constant;
21. incorrect universe arity;
22. safe context uses unsafe constant;
23. safe context uses partial constant;
24. application argument type mismatch;
25. lambda domain is not a type;
26. malformed forall domain;
27. malformed forall codomain;
28. let declared type is not a type;
29. let value type mismatch;
30. application of a non-function;
31. projection -> exact deferred error.

### Budget/error propagation

32. budget zero -> exact `check budget exhausted`;
33. pinned success/failure budget threshold;
34. DefEq lower-layer error propagation;
35. WHNF lower-layer error propagation where reachable on supported overlap.

Do not include eager-reduce marker/native/primitive/recursor/Quot fixtures in Phase 6.

## 20. Differential oracle for declaration admission

Mature admission oracles are:

```text
PSC1Kernel.Kernel.addAxiom
PSC1Kernel.Kernel.addDefinition
PSC1Kernel.Kernel.addTheorem
PSC1Kernel.Kernel.addOpaque
```

The adapter converts matched small-core/reference declarations and compares:

- accepted vs rejected;
- resulting environment membership/size for success;
- important stable error messages where the small core intentionally matches the reference;
- unchanged original environment on rejection.

## 21. Required declaration-admission RED matrix

Before production `Admission.lean` exists, create a failing differential executable covering at least:

### Positive

1. simple safe axiom;
2. unsafe axiom;
3. simple safe definition;
4. polymorphic safe definition;
5. simple theorem whose type is Prop;
6. theorem with proof body distinct but DefEq to expected type;
7. simple opaque declaration;
8. unsafe definition with bounded self-reference accepted through the temporary work environment.

### Base-validation negative cases

9. duplicate declaration name;
10. duplicate adjacent universe parameter;
11. duplicate non-adjacent universe parameter;
12. declaration type contains expression metavariable;
13. declaration type contains universe metavariable;
14. declaration type contains free variable;
15. declaration type references undefined universe parameter;
16. declaration type is not itself a type/sort.

### Definition negative cases

17. definition body contains expression metavariable;
18. definition body contains universe metavariable;
19. definition body contains free variable;
20. definition body references undefined universe parameter;
21. definition body type mismatch;
22. safe definition uses unsafe constant;
23. safe definition uses partial constant;
24. malformed unsafe self-reference is rejected.

### Theorem negative cases

25. theorem type is not a proposition;
26. theorem proof contains metavariable/free variable;
27. theorem proof type mismatch;
28. theorem uses forbidden unsafe/partial dependency under safe checking.

### Opaque negative cases

29. opaque body type mismatch;
30. opaque body contains metavariable/free variable;
31. opaque body uses forbidden unsafe/partial dependency despite `isUnsafe` metadata.

### Functional-environment behavior

32. rejected admission leaves original environment size unchanged;
33. rejected name remains absent;
34. pre-existing declarations remain retrievable;
35. `quotInitialized` flag is preserved across accepted/rejected ordinary admission.

### Budget

36. admission budget zero -> exact `admission budget exhausted`;
37. pinned success/failure threshold for one ordinary declaration.

If exact reference behavior for any proposed unsafe/partial fixture differs from the preliminary expectation, the RED oracle result controls and the written spec must be corrected before GREEN implementation rather than weakening the test.

## 22. TDD progression

Required implementation sequence:

```text
Phase-6 checked-expression RED fixture
↓
minimal trusted Check GREEN
↓
direct checked-expression parity
↓
actual PSC1 self-host source check
↓
Phase-6 admission RED fixture
↓
minimal trusted Admission GREEN
↓
direct admission parity
↓
actual PSC1 self-host source check
↓
KernelCore boundary/isolation
↓
Phase 1 aggregate
↓
Phase 2 aggregate
↓
Phase 3 aggregate
↓
Phase 4 aggregate
↓
Phase 5 aggregate
↓
Phase 6 aggregate
↓
size report
↓
full npm run check
```

No prior assurance command may be weakened or redefined to make Phase 6 pass.

## 23. PSC1 source requirements

Both trusted modules must pass the hardened real source path in:

```text
scripts/check-kernel-core-source.mjs
```

The Phase-5 hardening remains in force:

- build PSC1 once;
- invoke the actual PSC1 binary on flattened trusted closures;
- emit per-entry progress;
- fail closed on timeout/process failure;
- retain all lexical/source restrictions.

Trusted Phase-6 source must avoid:

- `partial`;
- `unsafe` implementation code;
- `extern`;
- `implemented_by`;
- IO;
- `Lean.*` / `Std.*` implementation dependencies;
- macros/custom elaborators;
- host `List` / `Option` semantic storage;
- caches/session state;
- namespaces/sections outside the accepted PSC1 profile;
- mutual definitions in trusted source unless a later explicitly accepted source-profile expansion proves necessary.

Prefer first-order helpers and small declaration bodies. Phase 5 demonstrated that semantically-correct but large/higher-order trusted declarations can be pathological for PSC1 elaboration even when Lean accepts them.

## 24. CI and assurance

Add direct executables conceptually named:

```text
psc2_kernel_core_check_parity_tests
psc2_kernel_core_admission_parity_tests
```

Add aggregate command:

```text
npm run assurance:kernel-core:phase6
```

Phase-6 aggregate must include, in dependency order:

```text
source profile
boundary
Name
Level
Expr
Subst
Declaration
Environment
LocalContext
Reduction
Infer
DefEq
Check
Admission
size report
```

Phase-1 through Phase-5 aggregate commands remain unchanged.

Workflow branch triggers should cover the reviewed and isolated execution Phase-6 branches while Phase 6 is active.

## 25. Size discipline

Continue reporting:

- trusted `.lean` file count;
- trusted source bytes;
- trusted nonblank/noncomment LOC;
- comparable mature-reference baseline;
- byte/LOC ratios.

Do not optimize for an arbitrary percentage target.

The trusted core may grow where semantic validation genuinely belongs in the kernel.

Do not hide admission validation in untrusted helpers merely to make the TCB appear smaller.

## 26. Compiler integration boundary

Phase 6 still does **not** make KernelCore the active compiler admission provider.

Current compiler flow remains unchanged.

Future cutover still targets:

```text
AdmissionReadyModule
  -> pskernel-core admission/checking
  -> CheckedCore / CheckedModule
  -> erasure
  -> VerifiedIR
```

Phase 6 only establishes the ordinary-declaration trusted semantic primitive needed before that later cutover.

No component outside KernelCore may claim an ordinary declaration is `CheckedCore` merely because Phase 6 exists.

## 27. Acceptance criteria

Phase 6 is accepted only when all are true:

1. `Ps.KernelCore.Check` exists as trusted PSC1-subset `.lean` source.
2. `Ps.KernelCore.Admission` exists as trusted PSC1-subset `.lean` source.
3. Checked-expression overlap matrix has direct differential evidence against `PSC1Kernel.check`.
4. Ordinary declaration-admission matrix has direct differential evidence against mature `Kernel.add*` APIs.
5. Actual PSC1 source checking accepts every trusted KernelCore closure.
6. Prior Phase-1 through Phase-5 assurances remain green unchanged.
7. Phase-6 aggregate assurance is green.
8. Full repository `npm run check` is green on the exact implementation/assurance SHA.
9. Exact size/source-profile evidence is recorded.
10. `PHASE6_ACCEPTANCE.md` records exact SHA/workflow/job evidence.
11. The acceptance record explicitly lists allowed claims and non-claims.
12. The acceptance record is documentation-only after the exact tested implementation/assurance SHA.

## 28. Allowed claims after acceptance

If all acceptance criteria pass, it is valid to claim:

- KernelCore has a PSC1-self-hostable checked-expression layer for the explicitly covered non-inductive surface.
- KernelCore can validate and functionally admit the explicitly covered axiom/definition/theorem/opaque declarations.
- Phase-6 application and let checks use the accepted Phase-5 DefEq layer.
- safe/unsafe/partial constant-use restrictions are enforced on the explicitly covered checked surface.
- admitted ordinary declarations are checked for closure, level-parameter validity, type well-formedness, and body/proof/value type compatibility according to the accepted Phase-6 surface.
- unsafe single-definition self-reference is supported only through the explicitly tested temporary-environment behavior.
- previous Phase-1–5 evidence remains green.

## 29. Explicit non-claims

Phase-6 acceptance must **not** be used to claim:

- complete Lean declaration admission;
- inductive/constructor/recursor support;
- strict positivity;
- projection checking/computation;
- iota reduction;
- Quot support;
- mutual-definition admission;
- nested/mutual inductive support;
- complete primitive Nat/String behavior;
- native reduction;
- exact Lean resource accounting;
- checker-cache/session equivalence;
- compiler `CheckedCore` cutover;
- K7/K8 corpus parity through KernelCore;
- replacement/removal of mature `PSC1Kernel`;
- formal equivalence to Lean 4.34;
- complete behavioral equivalence to Lean 4.34;
- executable PSC2 fixed-point self-hosting.

The strongest valid Phase-6 summary should be:

> KernelCore has a PSC1-self-hostable checked-expression layer and ordinary non-inductive declaration admission with direct differential evidence for the explicitly covered Phase-6 surface; inductive, Quot, primitive/native, mutual-definition, corpus, and compiler-cutover semantics remain separately gated.

## 30. Recommended next phase

After Phase 6 acceptance, the next phase must be selected from the remaining mature semantic islands based on dependency pressure, not convenience.

The expected next architectural slice is **primitive/resource handling** required by mature checking/reduction before broad corpus parity, followed by separately gated Quot and primitive inductive/recursor semantics.

Do not combine those later islands into Phase 6.