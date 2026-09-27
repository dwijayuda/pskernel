# PSC2 KernelCore Phase 3 — Basic Reduction / WHNF Design

Status: approved design, awaiting implementation plan review.

Date: 2026-09-27

Branch: `psc2/kernel-core-phase3-reduce`

Base accepted Phase-2 work head: `81f8e33f60361418d2fa651cc27be90ff00e8525`

## Purpose

Phase 3 adds the smallest useful weak-head reduction substrate to `pskernel-core` without importing the large, stateful, mutually dependent reduction machinery from `PSC1Kernel`.

The permanent architectural goal remains a small trusted semantic kernel. Therefore this phase must establish enough reduction for later inference and definitional equality while keeping recursors, Quot, native evaluation, primitive Nat/String execution, memoization, and checker-state machinery out of the trusted core.

This phase is deliberately named **basic/core WHNF**. It MUST NOT be documented as full Lean 4.34 WHNF parity.

## Context

Phase 1 established PSC1-self-hostable foundational semantics:

- `Data`
- `Name`
- `Level`
- `Expr`
- `Subst`

Phase 2 added:

- `Declaration`
- `Environment`
- `LocalContext`

All trusted KernelCore source remains PSC1-subset `.lean`, outside the active PSC2 bootstrap closure, and checked through the actual `psc1 check` path.

The mature `PSC1Kernel` remains the differential oracle.

## Why full reference WHNF is not copied

The mature reference WHNF is intentionally broader than this phase. Its reduction path is coupled to:

- recursor/iota reduction;
- projection reduction using constructor metadata;
- Quot reduction;
- inference callbacks;
- definitional-equality callbacks;
- Nat/String/native reduction;
- checker state and memo caches;
- recursion/resource configuration;
- `partial` recursion in the reference implementation.

Copying that design into `pskernel-core` now would enlarge the TCB before the required declaration kinds and checking semantics exist, and would violate the project's rule that optimization and host/runtime policy do not define semantics.

## Architectural decision

Add a single trusted semantic module:

```text
Ps.KernelCore.Reduce
```

The module provides a small **budgeted total WHNF** function over the Phase-2 environment and local context.

Conceptually:

```text
psKernelCoreWhnf
  budget
  environment
  localContext
  expression
    -> PsKernelCoreResult String PsKernelCoreExpr
```

Exact currying may be adjusted to satisfy the PSC1 recursion checker, but the observable API must retain the explicit budget and pure inputs.

The reduction budget exists to make trusted source structurally total and PSC1-self-hostable. It is a deterministic implementation/resource guard, **not** a claim that Lean 4.34 has this exact public WHNF budget API.

Differential parity against `PSC1Kernel` is evaluated only with a budget known to be sufficient for the fixture. Budget-exhaustion behavior is tested separately as a KernelCore totality/resource property.

## Budget semantics

The trusted reduction entry point MUST be structurally recursive on a `Nat` budget.

Rules:

1. A call with budget `0` returns a deterministic error:

   ```text
   reduction budget exhausted
   ```

2. A call with `Nat.succ remaining` may inspect and reduce the expression.
3. Every recursive call to WHNF uses `remaining` or another structurally smaller budget derived from it.
4. The implementation MUST NOT use `partial`, `unsafe`, hidden fuel globals, process state, or an unbounded recursion escape.
5. The exact number of budget units consumed is an implementation contract of KernelCore Phase 3 and must remain deterministic under tests, but it is not part of the Lean-compatibility claim.

A later phase may replace or layer this guard with the existing explicit `maxRecDepth` compatibility model, but it may not reintroduce trusted `partial` recursion without a separately justified architecture change.

## Trusted reductions included

### 1. Easy weak-head forms

The following remain unchanged when no other rule applies:

- `bvar`
- `mvar`
- `sort`
- `forallE`
- `lam`
- literals
- non-let local `fvar`
- constants that cannot be delta-unfolded
- applications whose head cannot reduce further
- projections, for now

### 2. Metadata stripping

```text
mdata metadata body
```

reduces by discarding metadata at WHNF and continuing with `body`.

### 3. Local let unfolding

For an `fvar name`:

- look up `name` in `PsKernelCoreLocalContext`;
- if it is a `letDecl`, continue WHNF on its value;
- if it is a normal local declaration or missing, return the original `fvar`.

### 4. Zeta reduction

```text
let x : T := value; body
```

reduces to the existing capture-safe term substitution:

```text
psKernelCoreExprInstantiate1 body value
```

and WHNF continues on the result.

The `nondep` marker does not change this basic WHNF rule.

### 5. Beta reduction

For application:

```text
(fn arg)
```

WHNF first reduces the function position only.

If the reduced function is:

```text
lam name type body binderInfo
```

then beta reduction produces:

```text
psKernelCoreExprInstantiate1 body arg
```

and WHNF continues on that result.

The argument itself is not eagerly reduced merely because it appears in an application.

Nested applications are handled by repeated function-head WHNF and beta steps.

### 6. Delta unfolding of ordinary definitions

A constant may delta-unfold only when the environment contains a `defnInfo` whose `deltaValue?` is present.

This phase deliberately preserves the existing Phase-2 declaration policy:

- definitions may unfold;
- axioms do not unfold;
- theorems do not unfold through `deltaValue?`;
- opaque declarations do not unfold through `deltaValue?`.

If universe argument arity differs from the definition's `levelParams` arity, delta unfolding does not occur and the constant remains residual.

### 7. Universe-parameter instantiation for delta values

Delta unfolding must instantiate the definition value's universe parameters before further WHNF.

The implementation must reuse the existing `PsKernelCoreLevelSubst` / `psKernelCoreLevelInstantiateParams` semantics rather than introducing an incompatible universe substitution model.

A small expression traversal is therefore required to instantiate universe parameters in every level-bearing expression position, including:

- `sort` levels;
- constant universe argument lists;
- nested expression children.

Binder names, local/free/meta names, literals, metadata numbers, projection names/indices, and binder info remain unchanged by universe substitution.

A helper that zips definition `levelParams` with supplied universe levels must fail closed on arity mismatch.

The exact helper location may be `Reduce.lean` for Phase 3 to avoid broadening older module APIs unnecessarily. It must remain pure and PSC1-subset.

## Application and delta interaction

The preferred simple algorithm is head-driven:

1. WHNF the application function position.
2. If it becomes a lambda, beta-reduce one argument and continue.
3. Otherwise rebuild the application with the reduced head and return it as basic WHNF.

Delta reduction of a constant in function position happens naturally when WHNF is called on that constant. A definition body that becomes a lambda can therefore immediately enable beta reduction without a separate whole-application delta algorithm.

This keeps application traversal small and avoids eagerly reducing arguments.

## Explicitly deferred semantics

The following are outside Phase 3 and MUST NOT be pulled into `Reduce.lean` merely to increase fixture coverage:

- recursor/iota computation;
- ordinary inductive metadata;
- constructor/recursor declaration variants;
- projection computation requiring constructor metadata;
- structure eta;
- Quot reduction;
- Nat primitive reduction;
- String literal constructor expansion;
- native evaluation/provider calls;
- inference/checking;
- definitional equality;
- proof irrelevance;
- function eta;
- lazy-delta ordering used by full defeq;
- memoization or expression caches;
- mutable checker/session state;
- replay/JSON/host IO;
- compiler `CheckedCore` integration.

A projection expression is therefore residual in Phase 3 even if its child can conceptually reduce to a constructor in the mature kernel.

## Reference/oracle strategy

`PSC1Kernel` remains semantic authority for the behaviors that overlap this basic subset.

Differential tests compare normalized observable results for fixtures that do **not** require deferred semantics.

The test adapter may use richer Lean/reference conveniences because it is outside the TCB. `Ps.KernelCore.Reduce` itself may not depend on reference modules.

## Required RED → GREEN parity cases

Before production `Reduce.lean` exists, add a differential fixture that fails because the module is missing.

At minimum it must cover:

1. easy WHNF value remains unchanged;
2. metadata is stripped;
3. zeta reduction of `letE`;
4. simple beta reduction;
5. nested beta reduction;
6. beta remains capture-safe under binders;
7. application does not eagerly normalize an irrelevant argument;
8. local `letDecl` fvar unfolds;
9. ordinary local fvar remains residual;
10. direct delta unfolding of a definition;
11. delta in function position enables beta;
12. universe-parameter substitution in a delta value;
13. universe substitution through nested expression constructors;
14. universe arity mismatch leaves the constant residual;
15. theorem remains non-delta-reducible;
16. opaque declaration remains non-delta-reducible;
17. axiom remains residual;
18. missing constant remains residual;
19. projection remains residual in this phase;
20. insufficient reduction budget fails with the exact deterministic error.

Tests for deferred recursor/Quot/Nat/native semantics MUST NOT be disguised as expected full parity in this phase.

## Source-discipline requirements

All new trusted code must satisfy the existing KernelCore source checker and actual PSC1 compiler path.

Trusted Phase-3 code must not introduce:

- `partial`;
- `unsafe`;
- `extern`;
- `implemented_by`;
- `Lean.*` or `Std.*` implementation dependencies;
- `IO`;
- custom syntax/macros/elaborators;
- host `List` / `Option` as semantic storage when kernel-local carriers are sufficient;
- namespace conveniences already rejected by the source profile;
- caches, arrays, hash maps, sessions, replay, or host/runtime policy.

If an apparently natural Lean implementation fails `psc1 check`, rewrite it into a PSC1-native structural form. Do not weaken the source gate.

## Package/dependency boundary

`Ps.KernelCore.Reduce` may depend only on trusted KernelCore modules needed for semantics, expected to include:

```text
Data
Name
Level
Expr
Subst
Declaration
Environment
LocalContext
```

`pskernel-core` remains:

```text
bootstrap: false
portable: true
role: minimal-trusted-kernel
```

It remains outside the active PSC2 self-host bootstrap closure during Phase 3.

## Gates

Phase 3 is accepted only when all of the following pass on the same implementation head:

1. existing KernelCore boundary gate;
2. Phase-1 Name/Level/Expr/Subst parity;
3. Phase-2 Declaration/Environment/LocalContext parity;
4. new basic reduction/WHNF differential parity;
5. bootstrap-closure isolation;
6. actual KernelCore `psc1 check` source/self-host profile;
7. Phase-1 aggregate assurance;
8. Phase-2 aggregate assurance;
9. new Phase-3 aggregate assurance;
10. size reporter;
11. full existing repository `npm run check` regression gate.

No existing semantic or adversarial gate may be weakened to make Phase 3 pass.

## Size/evidence discipline

The Phase-3 acceptance record must report:

- trusted module count;
- trusted source bytes;
- trusted nonblank/noncomment LOC;
- comparable reference baseline;
- ratio to the reference baseline;
- exact tested implementation SHA;
- exact CI workflow run;
- explicit deferred semantics / non-claims.

The project optimizes for trusted semantic surface, not an arbitrary LOC target.

## Non-claims

Passing Phase 3 does **not** establish:

- full Lean 4.34 WHNF parity;
- completed type inference/checking;
- definitional-equality parity;
- recursor/iota computation parity;
- projection parity;
- Quot parity;
- native/Nat/String reduction parity;
- full Lean 4.34 equivalence;
- readiness to replace the current admission-ready compiler boundary.

The strongest valid claim is:

> KernelCore has a small PSC1-self-hostable basic WHNF substrate with differential parity against PSC1Kernel for the explicitly covered beta/zeta/metadata/local-let/delta subset, under sufficient explicit reduction budget.

## Follow-on phases

After Phase 3 is green, the preferred sequence is:

```text
Phase 4  minimal infer/check using basic WHNF
Phase 5  definitional equality + proof irrelevance / eta / lazy delta
Phase 6  primitive inductive metadata + projection/recursor computation
Phase 7  Quot primitives
Phase 8  primitive Nat/String/native/resource boundaries as justified
Phase 9  corpus/adversarial parity and compiler CheckedCore integration
```

Exact numbering may change, but the semantic dependency direction should remain: keep later features from contaminating the basic WHNF TCB slice before their own parity gates exist.
