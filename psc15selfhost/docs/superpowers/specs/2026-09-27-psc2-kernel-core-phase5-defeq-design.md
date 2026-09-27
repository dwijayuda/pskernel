# PSC2 KernelCore Phase 5 — Minimal Definitional Equality Design

Status: design for review

Date: 2026-09-27

Base branch: `psc2/kernel-core-phase4-infer`

Base merge SHA: `c195a366657ef5775f608f1689fba218ed01855c`

## 1. Purpose

Phase 5 adds the smallest trusted definitional-equality layer that can soundly build on the already accepted KernelCore foundation:

- Phase 1: `Name`, `Level`, `Expr`, substitution;
- Phase 2: declarations, environment, local context;
- Phase 3: basic total WHNF;
- Phase 4: infer-only type inference.

The result is a PSC1-self-hostable `Ps.KernelCore.DefEq` module that agrees with the mature `PSC1Kernel` oracle on an explicitly bounded DefEq surface while deliberately deferring semantics that require trusted inductive metadata, Quot, primitive/native reduction, structure metadata, or the mature checker's performance state.

Phase 5 is not the complete Lean 4.34 definitional-equality algorithm.

## 2. Design principle

Do not port the mature stateful DefEq checker wholesale.

The mature checker combines semantic equality with:

- positive/failure caches;
- stateful lazy delta;
- projection-specific lazy reduction;
- structure eta;
- recursor/iota behavior;
- Quot behavior;
- Nat/native reduction;
- String literal expansion;
- unit-like structure handling;
- exact recursion-depth/resource accounting.

Those dependencies would enlarge the TCB and collapse later assurance phases into Phase 5.

Instead, Phase 5 trusts only equality behavior whose dependencies already exist in accepted KernelCore modules.

## 3. Trusted module boundary

Create exactly one new trusted semantic module:

```text
packages/pskernel-core/src/Ps/KernelCore/DefEq.lean
```

Export it from:

```text
packages/pskernel-core/src/Ps/KernelCore.lean
```

The primary public entry point is:

```text
psKernelCoreIsDefEq :
  Nat ->
  PsKernelCoreEnvironment ->
  PsKernelCoreLocalContext ->
  PsKernelCoreExpr ->
  PsKernelCoreExpr ->
  PsKernelCoreResult String Bool
```

The first argument is an explicit totality/resource budget. Trusted DefEq source must not use `partial`.

The recursive implementation must use a PSC1-accepted decreasing-budget/currying shape rather than relying on Lean-only recursion acceptance.

## 4. Trusted dependencies

`DefEq.lean` may depend only on accepted KernelCore semantics, principally:

```text
Ps.KernelCore.Infer
Ps.KernelCore.Reduce
Ps.KernelCore.Subst
Ps.KernelCore.Level
Ps.KernelCore.Expr
Ps.KernelCore.Environment
Ps.KernelCore.LocalContext
```

It must not import `Lean.*`, `Std.*`, mature `PSC1Kernel` implementation modules, IO, runtime caches, replay code, compiler/backend code, or unchecked metadata adapters.

## 5. Phase-5 equality surface

### 5.1 Structural fast path

If the two KernelCore expressions are structurally identical, return `ok true` before any inference or reduction.

The structural comparator used here must be trusted KernelCore code or an already accepted equivalent. If Phase 5 needs a new expression structural-equality helper, it must be introduced explicitly, tested before DefEq depends on it, and pass the real PSC1 source gate.

Structural identity includes exact expression structure. Later DefEq rules may equate terms that are not structurally identical.

### 5.2 Metadata transparency

`mdata` wrappers are semantically transparent for DefEq.

A metadata-wrapped term compares equal to its body when the body is otherwise DefEq, and metadata payload differences do not affect equality.

### 5.3 Basic WHNF comparison

After fast-path checks, Phase 5 may reduce both sides using the accepted Phase-3 `psKernelCoreWhnf` behavior with the remaining DefEq budget.

This gives Phase 5 accepted overlap behavior for:

- beta reduction;
- zeta reduction;
- metadata stripping;
- local-let unfolding;
- ordinary definition delta unfolding;
- universe substitution during ordinary definition unfolding.

This is intentionally simpler than the mature checker's lazy-delta strategy.

**Phase-5 claim boundary:** eager use of accepted basic WHNF is permitted for this bounded equality surface, but Phase 5 must not claim exact Lean/PSC1 lazy-delta ordering, reducibility-hint scheduling, or mature checker performance behavior.

### 5.4 Sort equality

Two sorts are DefEq when their universe levels are equivalent under accepted KernelCore level equivalence, not merely structurally equal.

### 5.5 Constant equality

Residual constants compare equal when:

- names are structurally equal; and
- their universe-level lists are pairwise equivalent with equal length.

Opaque declarations and theorems do not gain delta unfolding merely because DefEq is running. Phase-5 fixtures must pin that ordinary opaque/theorem bodies remain unavailable to WHNF/DefEq.

### 5.6 Free variables

Residual free variables compare equal only when their KernelCore names are equal.

Unknown free variables are not looked up merely to decide same-name residual equality.

### 5.7 Literal equality

Nat and String literals compare by literal kind and literal value.

Phase 5 does not expand String literals into constructor applications.

### 5.8 Applications

Residual applications compare recursively:

- function with function;
- argument with argument.

Equivalent nested application spines therefore compare recursively without requiring mature checker app caches.

Argument comparison is DefEq comparison, not Phase-4 infer-only argument checking.

### 5.9 Lambdas

Two lambdas compare by:

1. DefEq of their domains;
2. opening both bodies with the same fresh local;
3. recursively comparing the opened bodies in the extended local context.

Binder user names are not semantically significant.

The common fresh local must be generated deterministically from the current local context and a stable user-name choice. The test suite must include lambdas with different binder names and populated local contexts.

Binder info does **not** participate directly in the equality decision on this Phase-5 overlap surface. When extending the local context, use the right-hand binder info, matching the mature spine algorithm. A fixture must prove that otherwise equal lambdas with differing binder info remain DefEq if the mature oracle does.

### 5.10 Foralls

Two forall expressions compare analogously to lambdas:

1. domains are DefEq;
2. bodies are opened under the same fresh local;
3. opened bodies are compared recursively.

Different binder names alone do not make foralls non-DefEq.

Binder info does **not** participate directly in the equality decision on this Phase-5 overlap surface; local-context extension uses the right-hand binder info as in the mature oracle.

### 5.11 Proof irrelevance

Proof irrelevance is included because its dependencies now exist.

For residual terms `a` and `b`, Phase 5 uses Phase-4 inference to determine whether `a` is a proof:

1. infer `a` to obtain `aType`;
2. infer `aType` and reduce that inferred type with accepted WHNF;
3. if the result is `sort u` and `u` normalizes to zero, `aType` is a proposition;
4. infer `b` to obtain `bType`;
5. compare `aType` and `bType` recursively with Phase-5 DefEq;
6. if the types are DefEq, the proof terms are DefEq regardless of proof bodies.

If the first term is successfully shown not to be a proof, continue with ordinary equality rules.

If inference or WHNF needed for this proof-irrelevance path returns an error, **propagate that error**. Do not silently reinterpret an inference failure as “not a proof,” and never turn it into `true`. This matches the mature checker’s monadic failure behavior.

### 5.12 Function eta

Function eta is included for the non-structure function case.

When one residual side is a lambda and the other is not:

1. infer the non-lambda side;
2. WHNF its inferred type;
3. if the type exposes a forall, eta-expand the non-lambda term to a lambda applying it to `bvar 0`;
4. recursively compare the two lambdas.

Test both orientations:

```text
(fun x => f x) ≡ f
f ≡ (fun x => f x)
```

when `f` has a function type.

If inference or WHNF required by eta returns an error, **propagate that error**. If inference succeeds but the reduced type is not a forall, eta simply does not prove equality and ordinary comparison continues.

Phase 5 does not implement structure eta.

## 6. Deliberately deferred behavior

The following are outside Phase 5 and must not be smuggled into `DefEq.lean`:

- structure eta;
- projection computation requiring constructor/inductive metadata;
- projection-specific lazy delta;
- recursor reduction / iota;
- inductive metadata validation;
- Quot admission or computation;
- Nat primitive reduction beyond already accepted Phase-3 behavior;
- native evaluation;
- String-literal constructor expansion;
- unit-like structure equality;
- success/failure pair caches;
- unfold caches;
- checker sessions;
- exact mature lazy-delta ordering;
- exact reducibility-hint scheduling;
- exact Lean kernel recursion-depth accounting;
- checked inference;
- closed declaration admission;
- active compiler `CheckedCore` integration.

## 7. Deferred projection behavior

Structural equality still makes two structurally identical projections equal through the initial fast path.

If comparison reaches residual non-identical projection expressions and equality cannot be decided using already accepted generic reduction, Phase 5 must fail closed with the stable error:

```text
projection definitional equality unavailable before inductive metadata
```

It must not return `true` based on unvalidated projection metadata.

## 8. Budget semantics

Budget `0` returns exactly:

```text
defeq budget exhausted
```

For `psKernelCoreIsDefEq (Nat.succ remaining)`, the current call owns one DefEq step. Every recursive DefEq call receives exactly `remaining`.

When that call invokes accepted Phase-3 WHNF or Phase-4 inference, those lower-layer calls also receive exactly `remaining`. They retain their own established budget error strings if they exhaust their budgets.

This gives a deterministic rule:

```text
DefEq recursion: Nat.succ remaining -> recursive DefEq remaining
Lower-layer work from that frame: budget remaining
```

The implementation plan must pin at least one threshold fixture where the same term pair:

- fails at budget `N - 1`; and
- succeeds at budget `N`.

If the failing threshold is caused by a lower layer, the fixture must pin that lower-layer error. If it is caused by DefEq recursion itself, it must pin `defeq budget exhausted`.

The budget is a KernelCore totality/resource contract. It is not claimed to match Lean's internal recursion-depth counter.

## 9. Error behavior

Stable Phase-5-specific errors:

```text
defeq budget exhausted
projection definitional equality unavailable before inductive metadata
```

Errors from accepted lower layers propagate when required to decide an explicitly supported DefEq rule.

A negative equality decision is represented as:

```text
PsKernelCoreResult.ok false
```

not as an error.

Unsupported semantics whose absence could make `false` unsound must fail closed with an explicit error instead of silently returning `false`.

## 10. Differential oracle

The mature oracle is `PSC1Kernel` definitional equality, using the existing reference checker entry point appropriate to the repository's test harness.

The test adapter must remain outside trusted source.

Phase-5 parity claims apply only to the explicitly selected overlap cases. The test harness must not imply parity for deferred features simply because the mature checker supports them.

## 11. Required RED differential matrix

Before production `DefEq.lean` exists, create a failing Phase-5 parity executable covering at least:

### Positive overlap

1. structural reflexivity;
2. metadata wrapper transparency;
3. equivalent but structurally different universe sorts;
4. same residual constant with equivalent universe levels;
5. same free variable;
6. equal Nat literals;
7. equal String literals;
8. beta-equivalent expressions;
9. zeta-equivalent expressions;
10. local-let-unfolding equality;
11. ordinary definition delta equality;
12. application equality;
13. lambda equality;
14. lambdas with different binder user names;
15. lambdas with differing binder info when accepted by the oracle;
16. forall equality;
17. foralls with different binder user names;
18. foralls with differing binder info when accepted by the oracle;
19. nested/dependent lambda equality;
20. nested/dependent forall equality;
21. proof irrelevance for two distinct proof bodies of the same proposition;
22. proof terms whose proposition types are themselves DefEq after accepted reduction;
23. function eta, lambda-left orientation;
24. function eta, lambda-right orientation.

### Negative overlap

25. different residual constant names;
26. same constant name with non-equivalent levels;
27. different free variables;
28. unequal Nat literals;
29. Nat literal versus String literal;
30. applications with unequal arguments;
31. lambdas with non-DefEq domains;
32. foralls with non-DefEq domains;
33. proof-like terms whose proposition types are not DefEq;
34. function eta attempted on a successfully inferred non-function term does not yield equality;
35. two different opaque constants remain unequal when no accepted rule proves equality.

### Error-propagation and KernelCore boundary cases

36. proof-irrelevance inference failure propagates the lower-layer error;
37. eta inference failure propagates the lower-layer error;
38. budget zero -> exact `defeq budget exhausted`;
39. pinned success/failure budget threshold;
40. structurally identical projection -> `ok true` via fast path;
41. residual non-identical projection requiring deferred metadata -> exact projection-deferred error.

If a proposed fixture depends on recursor, Quot, structure, native, or primitive behavior deferred from this phase, remove it from the Phase-5 matrix rather than widening the trusted scope.

## 12. TDD and gate order

Required progression:

```text
Phase-5 DefEq RED fixture
↓
minimal trusted GREEN implementation
↓
direct DefEq differential parity
↓
KernelCore boundary/isolation
↓
actual PSC1 self-host source check
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
full npm run check
```

No earlier gate may be weakened, removed, or redefined to make Phase 5 pass.

## 13. PSC1 source requirements

The trusted module must pass the real source path:

```text
lake exe psc1 check <flattened-module>
```

through `scripts/check-kernel-core-source.mjs`.

Trusted DefEq must therefore avoid:

- `partial`;
- `unsafe`;
- `extern`;
- `implemented_by`;
- IO;
- `Lean.*` and `Std.*` implementation dependencies;
- macros/custom elaborators;
- host `List` / `Option` semantic storage;
- caches/session state;
- namespace/section conveniences outside the accepted PSC1 profile.

Use KernelCore-local carriers and PSC1-safe curried recursion patterns.

## 14. Size discipline

`report-kernel-core-size.mjs` continues to track:

- trusted `.lean` file count;
- trusted bytes;
- trusted nonblank/noncomment LOC;
- comparable PSC1Kernel baseline bytes/LOC;
- ratios.

The purpose is trend visibility, not a predetermined percentage target.

Do not optimize source LOC by hiding semantics in untrusted unchecked helpers.

## 15. Integration boundary

Phase 5 does not change the compiler trust flow.

The current compiler still does not obtain `CheckedCore` from KernelCore.

Phase 5 only establishes a trusted DefEq primitive that later checked inference/declaration admission can call.

The eventual flow remains:

```text
AdmissionReadyModule
  -> pskernel-core admission/checking
  -> CheckedCore / CheckedModule
  -> erasure
  -> VerifiedIR
```

That cutover belongs to a later phase.

## 16. Acceptance criteria

Phase 5 is accepted only when all are true:

1. `Ps.KernelCore.DefEq` exists as trusted PSC1-subset `.lean` source.
2. The explicit Phase-5 overlap matrix has direct differential evidence against the mature oracle.
3. Actual `psc1 check` accepts every trusted KernelCore module including DefEq.
4. Phase-1 through Phase-4 assurances remain green unchanged.
5. A Phase-5 aggregate assurance gate is green.
6. Full repository `npm run check` is green on the exact implementation/assurance SHA.
7. The exact size report is recorded.
8. `PHASE5_ACCEPTANCE.md` records exact SHA/run/job evidence, allowed claims, and explicit non-claims.
9. The acceptance commit after the tested implementation SHA is documentation-only.

## 17. Explicit non-claims

Phase 5 must not be described as proving or implementing:

- full Lean 4.34 DefEq;
- formal equivalence to Lean 4.34;
- exact lazy-delta scheduling;
- full reducibility-hint semantics;
- projection/recursor/inductive equality;
- structure eta;
- Quot equality/computation;
- complete primitive Nat/String/native equality;
- checked type inference;
- complete declaration admission;
- replacement of mature `PSC1Kernel`;
- compiler checked-core cutover;
- fixed-point PSC2 self-hosting.

The strongest permitted summary is:

> KernelCore has a PSC1-self-hostable minimal definitional-equality foundation with direct parity against the mature PSC1Kernel oracle for the explicitly covered Phase-5 surface, while metadata-dependent, primitive, admission, and compiler-cutover semantics remain separately gated.

## 18. Next phase

After Phase 5, the dependency-ordered next phase is checked inference and declaration admission using accepted Infer + WHNF + DefEq.

That phase should introduce argument/domain/let validation and closed declaration checking without yet pretending inductive/Quot metadata is trustworthy. Primitive inductive/recursor and Quot admission must retain their own later assurance boundaries.