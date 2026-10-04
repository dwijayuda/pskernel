# PSKernel Self-Host Development Plan

This plan is the execution companion to
`PSKERNEL_SELFHOST_ARCHITECTURE.md`.

Target: a feature-complete, readable, explainable, self-hosted Lean-4.34
compatible kernel with competitive native performance from one source.

## Current baseline

The portable self-host implementation already contains:

- core Name/Level/Expr/substitution;
- environment and checker state;
- WHNF and primitive reductions;
- projection typing/reduction;
- inference;
- recursor reduction;
- algorithmic definitional equality;
- Quot;
- declaration admission;
- ordinary, mutual and nested inductives;
- generated source/artifact fixed-point tooling.

The current architecture work is converting the mature flat implementation into
clear theory/runtime modules while keeping every step self-hostable.

## Phase A — Semantic closure

Goal: exact declared Lean-4.34 kernel feature coverage.

### A1. Compatibility matrix

Normative file:

- `LEAN_4_34_COMPATIBILITY.json`
- `LEAN_4_34_CONFORMANCE.json`

Audit:

- `scripts/psc1kernel-compatibility-audit.mjs`

Exit condition:

```text
node scripts/psc1kernel-compatibility-audit.mjs --require-complete
PASS
```

### A2. Remaining native-reduction compatibility

Complete and differentially test:

- `Lean.reduceBool`
- `Lean.reduceNat`

Architecture:

- backend-neutral provider in `Runtime/NativeReduction.lean`;
- optional provider in checker context/session;
- no provider keeps ordinary semantic behavior;
- WHNF order matches Lean 4.34;
- lazy defeq order matches Lean 4.34.

### A3. Rule-complete conformance suite

Build a finite focused suite covering every compatibility rule.

Minimum policy per rule:

- positive;
- negative;
- edge case where meaningful.

Do not use giant external replay as the primary completion criterion.

### Phase A exit gates

- compatibility matrix complete;
- source profile green;
- PSC1 check green;
- Lean build green;
- differential/conformance green;
- canonical `.ps` round-trip green;
- fixed point green;
- generated runtime smoke green.

## Phase B — Explainability and readability

Goal: source code should teach the kernel theory.

This phase changes module boundaries/documentation, not semantics.

### B1. Separate theory from runtime

Runtime-only modules:

- `Runtime/Cache.lean`
- `Runtime/EnvironmentIndex.lean`
- `Runtime/NativeReduction.lean`

Theory-facing modules should never depend on runtime implementation details
beyond narrow operations.

### B2. Split oversized theory modules

Priority order:

1. definitional equality;
2. inductive admission;
3. mutual inductives;
4. nested inductives;
5. inference/reduction where useful.

Already-started target:

```text
Theory/DefEq/
    BinderSpines.lean
    Quick.lean
    LazyDelta.lean
    FinalRules.lean
    Shortcuts.lean
    FullShape.lean
```

Future useful boundaries may include:

```text
Theory/DefEq/
    Quick.lean
    BinderSpines.lean
    Projection.lean

Theory/Inductive/
    Header.lean
    Positivity.lean
    Elimination.lean
    Recursor.lean

Theory/Nested/
    Discover.lean
    Flatten.lean
    Restore.lean
```

Do not split merely to make files smaller; split when a theory concept becomes
independently explainable.

### B3. Rule documentation

For each compatibility rule add:

- rule ID;
- mathematical/semantic statement;
- Lean 4.34 locator;
- implementation symbol;
- test locator.

Keep `KERNEL_THEORY.md` synchronized.

### B4. Reading-order quality

The intended reading order should remain:

1. Name/Level/Expr;
2. substitution;
3. environment;
4. inference;
5. WHNF/reduction;
6. defeq;
7. Quot;
8. inductives;
9. mutual;
10. nested;
11. declaration admission.

### Phase B exit gates

- no unexplained compatibility rule;
- high-risk theory rules each have dedicated source/documentation;
- runtime optimizations are visibly separated;
- `KERNEL_THEORY.md` matches source layout;
- all Phase A gates remain green.

## Phase C — Competitive performance

Goal: improve performance without changing semantic algorithms first.

### C1. Environment lookup

Use persistent bounded name index while preserving the ordered semantic
declaration list.

Invariant:

```text
ordered constants list = semantic source of truth
runtime index          = lookup accelerator only
```

Collision handling must always use structural `PsKernelName` equality.

### C2. Checker caches

Replace linear maps/sets behind `Runtime/Cache` with indexed structures.

Keep:

- success pair cache;
- failure pair cache;
- inference/WHNF/unfold maps.

Never introduce transitive equivalence closure.

### C3. Expression metadata

After profiling, consider cached:

- structural hash;
- `hasFVar`;
- `hasMVar`;
- `hasLooseBVar`;
- node count.

Keep metadata semantically derived.

### C4. Benchmark both artifacts

Same source:

```text
PSC/backend-ts -> JS
Lean compiler   -> native
```

Compare:

- official Lean 4.34 kernel baseline;
- PSKernel native;
- PSKernel JS.

Initial native target:

- usable within roughly 1.5–2x Lean on representative workloads.

Longer-term target:

- around Lean performance where practical.

JS target:

- portable and fast enough for npm/browser use; it need not beat native Lean.

### Phase C exit gates

- semantic/conformance gates unchanged;
- measured performance regression tests exist;
- environment/cache improvements show real workload gains;
- native performance is competitive enough for intended deployment;
- JS remains portable and self-host generated.

## Continuous self-host gate

Every phase must preserve:

```text
portable .lean source
      |
      v
psc1 check
      |
      v
canonical .ps
      |
      v
psc1 check again
      |
      v
generated compiler
      |
      v
kernel TS/JS
      |
      v
source fixed point
      |
      v
artifact fixed point
      |
      v
runtime smoke
```

If a refactor makes this harder, the refactor is suspect.

## Milestone definitions

### M1 — Lean 4.34 feature complete

- all compatibility rows implemented;
- conformance suite green;
- no known semantic gaps.

### M2 — Explainable kernel

- theory/runtime architecture established;
- large modules split by theory concept;
- rule documentation complete;
- `KERNEL_THEORY.md` usable as a learning path.

### M3 — Competitive kernel

- indexed environment/cache structures;
- measured native performance near intended target;
- JS remains practical;
- no semantic regressions.

### M4 — Provider-ready

Not required for M1–M3, but needed before replacing the current authority:

- canonical declaration adapter exists;
- dual-check mode exists;
- provider parity gate is green;
- generated self-host kernel remains fixed-point reproducible.

Until M4 is explicitly accepted, `lean434-wasm` remains the default authority.

## Work-selection rule

When choosing the next task, prefer:

```text
current phase exit blocker
> compatibility defect
> readability debt obscuring a high-risk rule
> measured performance hotspot
> optional feature
```

This prevents the project from drifting into unrelated language/backend work.
