# PSC2 KernelCore Phase 7 Primitive/Resource Design

Date: 2026-09-27

Status: proposed for user review

Base: accepted Phase-6 merge `f23caa2b7f8923f0d1c94304b488bc4308eb4d28`

Branch: `psc2/kernel-core-phase7-primitives`

## 1. Purpose

Phase 7 extends the accepted PSC1-self-hostable KernelCore with the smallest primitive/resource layer needed to make ordinary checked terms observe Lean-4.34-compatible Nat resource limits and deterministic Nat primitive reduction.

The phase is intentionally narrower than the mature `PSC1Kernel.CheckerContext` and `TypeChecker` implementation. It does not import the mature checker context wholesale, does not add native evaluation, and does not add inductive/recursor, Quot, projection, string-constructor, or compiler-cutover semantics.

The primary success criterion is:

> a PSC1-subset trusted core can type-check Nat literals and normalize the mandatory Phase-7 Nat primitives under an explicit, pure resource configuration, while preserving all accepted Phase-1 through Phase-6 behavior and public APIs through default-resource wrappers.

## 2. Constraints

The following remain non-negotiable:

- trusted implementation stays in PSC1-subset `.lean`;
- every trusted source closure must pass the actual PSC1 self-host compiler gate;
- no `partial`, `unsafe`, `extern`, `implemented_by`, host IO, `Lean.*`, `Std.*`, macros, custom elaborators, host `List`/`Option` semantic storage, or performance caches are added to the trusted core;
- the mature `PSC1Kernel` remains the direct semantic oracle;
- no Phase-1 through Phase-6 gate may be weakened or redefined to make Phase 7 pass;
- current public KernelCore entry points remain source-compatible and become wrappers over explicit-resource variants;
- current explicit `Nat` reduction/inference/check/defeq budgets remain the trusted termination boundary for KernelCore; Phase 7 does not claim exact Lean `maxRecDepth`, heartbeat, or stack-accounting parity;
- native evaluation, `Lean.reduceNat`, `Lean.reduceBool`, and `eagerReduce` remain outside the trusted Phase-7 surface.

## 3. Why Phase 7 is a separate semantic island

The mature Lean-4.34-oriented reference checker has resource behavior that is observable independently of inductive and Quot semantics:

1. Nat literals are rejected when their runtime numeral size exceeds `maxNatSize`.
2. Nat primitive reduction uses the same resource bound for results.
3. `Nat.pow` rejects counts that do not fit a 32-bit unsigned integer; the mature bitwise extension applies the same boundary to `Nat.shiftLeft`.
4. Some operations can reject before constructing an oversized result.
5. Primitive reduction is a distinct stage from ordinary beta/zeta/delta WHNF, native evaluation, Quot reduction, and inductive recursor reduction.

That makes resource policy plus deterministic Nat primitives a coherent dependency-ordered slice that can be implemented and tested before the substantially larger inductive/recursor subsystem.

## 4. Architecture

Phase 7 adds two trusted modules:

```text
Ps.KernelCore.Resource
Ps.KernelCore.Primitive
```

The resulting dependency shape is:

```text
Ps.KernelCore
├── Data
├── Name
├── Level
├── Expr
├── Subst
├── Declaration
├── Environment
├── LocalContext
├── Resource        <- new
├── Primitive       <- new
├── Reduce          <- resource-aware primitive integration
├── Infer           <- resource-aware Nat literal checking
├── DefEq           <- resource-aware WHNF/primitive normalization
├── Check           <- resource-aware inference/defeq
└── Admission       <- resource-aware checking
```

`Resource` owns policy and resource arithmetic only.

`Primitive` owns pure recognition and reduction semantics for the selected built-in Nat names.

`Reduce`, `Infer`, `DefEq`, `Check`, and `Admission` consume those modules but do not duplicate primitive/resource rules.

## 5. Resource configuration

### 5.1 Trusted data type

Phase 7 introduces:

```text
structure PsKernelCoreResourceConfig where
  maxNatSize : Nat
```

and:

```text
psKernelCoreLeanNatMaxSizeDefault : Nat
psKernelCoreResourceConfigDefault : PsKernelCoreResourceConfig
```

The default Nat bound is the mature Lean-4.34 reference value:

```text
128 * 1024 * 1024
```

bytes.

The configuration is intentionally minimal. It does not contain:

- maxRecDepth;
- current recursion depth;
- heartbeats;
- cancellation state;
- native evaluator callbacks;
- eager-reduce state;
- IO/runtime handles.

### 5.2 Nat size model

`Resource` provides a PSC1-compatible pure model of the mature reference's supported 64-bit Nat runtime size boundary.

Required constants/helpers:

```text
psKernelCoreLeanUInt32Max
psKernelCoreLeanMaxSmallNat
psKernelCoreNatHeapWordCount
psKernelCoreNatSizeInBytes
psKernelCoreCheckNatSize
psKernelCoreCheckCountArg
```

Semantics:

- small Nat values up to the accepted immediate-scalar boundary occupy one 64-bit word for resource accounting;
- larger naturals are measured in whole 64-bit limbs;
- a numeral/result larger than `maxNatSize` returns the mature-compatible resource error;
- operation counts that use the mature UInt32 boundary are checked through the shared count helper.

The trusted code must express these helpers using recursion forms accepted by PSC1. If the direct reference recursion shape is rejected by the PSC1 gate, rewrite the algorithm structurally without weakening the source profile.

## 6. Primitive names and recognition

`Primitive` defines trusted local names for the mandatory Phase-7 surface:

```text
Nat
Bool
Bool.true
Bool.false
Nat.zero
Nat.succ
Nat.add
Nat.sub
Nat.mul
Nat.pow
Nat.gcd
Nat.mod
Nat.div
Nat.beq
Nat.ble
```

The module also owns pure helpers equivalent to the selected mature surface:

```text
psKernelCoreNatLiteralValue?
psKernelCoreBoolExpr
psKernelCoreIsNatZeroExpr
psKernelCoreNatPredExpr?
```

Primitive recognition must be exact enough to avoid reducing a similarly named or incorrectly universe-instantiated application.

The mature bitwise family is a separately gated Phase-7B extension:

```text
Nat.land
Nat.lor
Nat.xor
Nat.shiftLeft
Nat.shiftRight
```

Phase 7 acceptance does **not** depend on Phase 7B. Phase 7B may be included in the same implementation cycle only if its trusted implementation passes the unchanged PSC1 source profile without `Std`/Lean implementation imports, host/native callbacks, termination machinery, or source-gate weakening.

## 7. Mandatory Nat primitive semantics

### 7.1 Unary primitive

`Nat.succ` reduces when:

- the head constant has zero universe arguments;
- there is exactly one argument;
- the argument WHNFs to a recognized Nat literal/zero representation;
- the resulting Nat passes `maxNatSize`.

Otherwise the primitive stage returns `none` rather than inventing a reduction.

### 7.2 Mandatory binary primitives

For two recognized Nat operands, Phase 7 must support:

```text
Nat.add
Nat.sub
Nat.mul
Nat.pow
Nat.gcd
Nat.mod
Nat.div
Nat.beq
Nat.ble
```

Required reference behavior includes:

- subtraction uses Nat truncated subtraction;
- `Nat.mod a 0` returns `a`;
- `Nat.div a 0` returns `0`;
- `Nat.beq` returns `Bool.true` or `Bool.false`;
- `Nat.ble` returns `Bool.true` or `Bool.false`;
- Nat-producing results obey the configured Nat-size boundary;
- `Nat.pow` rejects an exponent larger than UInt32;
- `Nat.pow` uses the mature reference's conservative pre-result size guard before constructing a result that would exceed the configured maximum.

### 7.3 GCD implementation

The mature reference uses Euclidean recursion. KernelCore may use a PSC1-accepted fuel/structural formulation that is extensionally equal on the tested Nat domain. Varying algorithm state must be carried in a shape accepted by the existing PSC1 structural-recursion rules rather than by adding termination annotations or `partial`.

The implementation remains pure and trusted; no host primitive or native callback is allowed.

### 7.4 Phase 7B bitwise extension

If included, Phase 7B must match the mature reference for:

```text
Nat.land
Nat.lor
Nat.xor
Nat.shiftLeft
Nat.shiftRight
```

including:

- configured Nat-size checks on Nat-producing results;
- zero-left `Nat.shiftLeft` reducing to zero before count rejection;
- UInt32 count rejection for nonzero `Nat.shiftLeft`;
- conservative shift-left growth rejection;
- no corresponding growth precheck for `Nat.shiftRight`.

If this cannot be expressed within the unchanged PSC1 trusted-source profile, it remains explicitly deferred. The core gate may not be broadened merely to include these operations.

## 8. Resource-aware API threading

Phase 7 adds explicit-resource variants while preserving the accepted APIs as default wrappers.

Configured entry points:

```text
psKernelCoreWhnfWithResources
psKernelCoreInferWithResources
psKernelCoreIsDefEqWithResources
psKernelCoreCheckWithResources
psKernelCoreAddAxiomWithResources
psKernelCoreAddDefinitionWithResources
psKernelCoreAddTheoremWithResources
psKernelCoreAddOpaqueWithResources
```

Each receives `PsKernelCoreResourceConfig` in addition to its current parameters.

Current entry points remain valid and must be simple wrappers over the default configuration:

```text
oldAPI args = configuredAPI PsKernelCoreResourceConfigDefault args
```

The implementation plan must pin one consistent argument order following existing KernelCore style. The resource parameter is explicit in configured APIs and is never hidden in mutable/global state.

## 9. Reduction decomposition and data flow

The current Phase-4 reducer combines basic WHNF behavior with delta unfolding. Phase 7 must internally separate those concerns closely enough to preserve the mature selected ordering without changing the public Phase-4 contract.

The configured path is conceptually:

```text
expression
  -> core WHNF step
       metadata transparency
       local-let lookup
       zeta
       beta
       no native/Quot/recursor/projection primitive work
  -> mandatory Nat primitive attempt
       WHNF primitive operands with the same resource config
       apply pure primitive reduction
  -> if no primitive step: ordinary delta unfold when available
  -> repeat until no selected Phase-7 step applies
  -> result
```

This mirrors the selected mature ordering: ordinary core reduction exposes the head, the primitive stage is attempted, and delta unfolding is then allowed to expose another reducible form for the next loop.

Required compatibility rule:

- the existing `psKernelCoreWhnf` remains a default-resource wrapper;
- all previously accepted Phase-4 reduction parity cases must stay green;
- the internal decomposition may change, but it may not alter previously accepted observable behavior merely to simplify Phase 7.

Primitive operands may themselves require beta/zeta/delta exposure. The same resource configuration must be threaded through those recursive WHNF calls.

Phase 7 must not add native, Quot, recursor/iota, projection, structure-eta, or string-constructor reduction to satisfy a primitive test.

## 10. Inference and checking data flow

For a Nat literal:

```text
InferWithResources
  -> check numeral size against resources.maxNatSize
  -> on success return Nat type
  -> on failure return the resource error
```

String literals retain current behavior in Phase 7; string constructor expansion remains deferred.

`CheckWithResources` uses resource-aware inference and DefEq rather than reimplementing literal checks.

`AdmissionWithResources` delegates to the configured checked-expression layer. It must not copy Nat-size logic into declaration admission.

## 11. DefEq integration

The configured DefEq layer must use the configured WHNF/reduction path, so primitive normalization can participate in definitional equality for the explicitly covered surface.

Representative accepted behavior:

```text
Nat.add 2 3  ≡  5
Nat.mul 3 4  ≡  12
Nat.beq 2 2  ≡  Bool.true
```

provided the required declarations/names are represented in the test environment as needed by the existing KernelCore fixtures.

This phase does not attempt to clone additional mature Nat-offset defeq rules beyond what is already accepted or directly required by the mandatory primitive overlap.

## 12. Errors and fail-closed behavior

The trusted layer preserves stable mature-compatible messages where Phase 7 explicitly models the boundary.

Required Nat-size error:

```text
the kernel refused a Nat numeral because its size exceeds the maximum
```

Required oversized-count form:

```text
the kernel refused to evaluate <operation> because its second argument does not fit in a 32-bit unsigned integer
```

`Nat.pow` additionally uses the mature-compatible pre-result overflow message when the predicted result exceeds the maximum numeral size.

Existing budget errors remain distinct, for example:

```text
reduction budget exhausted
inference budget exhausted
check budget exhausted
```

A resource failure must not be translated into a generic budget failure, and vice versa.

Unknown/malformed primitive shapes fail closed as "no primitive reduction" unless ordinary existing inference/checking rules independently reject the term.

## 13. Differential evidence

Phase 7 requires direct comparison against mature `PSC1Kernel` behavior for the mandatory overlap. Phase 7B, if implemented, gets separate evidence and cannot substitute for missing mandatory evidence.

### 13.1 Resource parity fixture

Pin:

- default 128 MiB configuration;
- immediate/small Nat size boundary;
- heap Nat word-count examples;
- exact-at-limit acceptance;
- just-over-limit rejection;
- UInt32 count boundary acceptance/rejection through the shared helper;
- stable error strings for selected resource failures.

Large-limit behavior should be tested through size helpers and small custom configurations where practical; the suite does not need to allocate a 128 MiB numeral merely to prove the default constant exists.

### 13.2 Mandatory primitive parity fixture

Pin:

- `Nat.zero` recognition;
- `Nat.succ`;
- add/sub/mul;
- pow/gcd/mod/div;
- beq/ble;
- divide/mod by zero;
- malformed arity;
- nonzero universe-argument rejection from primitive reduction;
- unreduced/nonliteral operand behavior;
- maxNatSize failures;
- UInt32 exponent failure;
- conservative pow growth rejection.

### 13.3 Optional Phase-7B parity fixture

Only if Phase 7B is included, pin:

- land/lor/xor;
- shiftLeft/shiftRight;
- zero-left shiftLeft ordering;
- UInt32 shift count boundary;
- configured growth rejection;
- malformed/unreduced behavior.

### 13.4 Integrated parity fixture

Pin configured behavior through:

- WHNF;
- Infer;
- DefEq;
- Check;
- ordinary Admission.

Representative scenarios:

- primitive operands exposed by beta/zeta/delta;
- Nat literal accepted/rejected under two resource configs;
- DefEq succeeds through primitive normalization;
- Check succeeds/fails because primitive normalization changes compatibility;
- admission rejects an oversized literal without mutating the caller environment;
- default API result equals configured API with default resources.

## 14. TDD and assurance order

Implementation proceeds RED-first per semantic island.

Expected gate order:

```text
Lean compilation
  -> Resource direct parity
  -> Mandatory primitive direct parity
  -> Optional Phase-7B direct parity, only if included
  -> Configured integration parity
  -> Phase-1 through Phase-6 direct gates
  -> bootstrap isolation
  -> actual PSC1 self-host source profile
  -> Phase-1 through Phase-6 aggregate assurance
  -> Phase-7 aggregate assurance
  -> full npm run check
```

Production behavior must not be written before the corresponding intended RED failure is observed.

If concurrent branch work appears, stop and reconcile rather than overwriting it.

## 15. Size and TCB discipline

The Phase-7 acceptance record must report:

- trusted `.lean` file count;
- trusted source bytes;
- trusted nonblank/noncomment LOC;
- ratio to the same comparable `PSC1Kernel` semantic baseline used in prior phases;
- actual PSC1 self-host closure count;
- no new host runtime dependencies in the trusted core.

A larger LOC count is acceptable when required for explicit pure semantics, but the design prefers semantic clarity over importing mature runtime machinery.

## 16. Explicit non-scope

Phase 7 does not implement or claim:

- native reduction;
- `Lean.reduceNat` / `Lean.reduceBool` host callbacks;
- `eagerReduce` marker semantics;
- exact Lean `maxRecDepth` or heartbeat accounting;
- Quot declaration/reduction;
- inductive declaration admission;
- constructor admission;
- recursor metadata validation/admission;
- strict positivity;
- iota reduction;
- projection inference/computation;
- structure eta;
- string-literal constructor expansion;
- mutual-definition admission;
- nested/mutual inductive lowering;
- complete Lean primitive coverage outside the mandatory Nat family and any separately evidenced Phase-7B extension;
- native evaluation;
- K7/K8 corpus parity through KernelCore;
- compiler `CheckedCore` provider cutover;
- replacement/removal of mature `PSC1Kernel`;
- formal equivalence to Lean 4.34;
- complete behavioral equivalence to Lean 4.34;
- executable PSC2 fixed-point self-hosting.

## 17. Acceptance criteria

Phase 7 is accepted only when all of the following hold:

1. `Resource.lean` exists and contains only the explicit pure resource policy needed by this phase.
2. `Primitive.lean` exists and owns the mandatory Nat primitive recognition/reduction semantics.
3. configured resource-aware variants exist through Reduce, Infer, DefEq, Check, and ordinary Admission.
4. accepted Phase-1 through Phase-6 APIs remain available as default-resource wrappers.
5. Nat literals observe configured `maxNatSize` in the configured inference/check/admission path.
6. `Nat.succ`, add/sub/mul, pow/gcd/mod/div, and beq/ble directly match mature `PSC1Kernel` behavior for the tested overlap.
7. configured DefEq can observe mandatory primitive normalization.
8. resource errors remain distinct from explicit KernelCore budget errors.
9. no native, Quot, inductive/recursor, projection, structure-eta, or string-constructor semantics are pulled into the trusted core.
10. all trusted KernelCore source passes the actual PSC1 self-host gate.
11. all Phase-1 through Phase-6 assurance remains green without weakening.
12. Phase-7 aggregate assurance is green.
13. full existing repository `npm run check` is green.
14. an exact-head acceptance document records CI, trusted-source, size, allowed-claim, and non-claim evidence.

Phase 7B bitwise support is additional acceptance evidence if present, but absence of Phase 7B does not weaken or block the mandatory Phase-7 acceptance criteria above.

## 18. Allowed claims after acceptance

If all acceptance criteria pass, it will be valid to claim:

- KernelCore has an explicit PSC1-self-hostable Nat resource configuration for the Phase-7 surface;
- configured Nat literal checking enforces the tested `maxNatSize` behavior;
- the mandatory named Nat primitives reduce in trusted KernelCore with direct differential evidence against mature `PSC1Kernel`;
- configured WHNF/Infer/DefEq/Check/ordinary Admission propagate the Phase-7 resource/primitive semantics for the explicitly covered surface;
- existing APIs preserve default-resource behavior through wrappers;
- all trusted Phase-7 source passes the actual PSC1 self-host checker;
- if Phase 7B is implemented and separately green, the accepted claim may additionally name the tested bitwise/shift primitives.

It will still not be valid to claim complete Lean kernel primitive coverage, complete Lean resource semantics, complete Lean 4.34 equivalence, inductive/Quot correctness, corpus parity, compiler cutover, or fixed-point self-hosting.

## 19. Expected follow-on order

After Phase 7, the dependency-ordered roadmap is expected to continue with separate design/spec/plan cycles for:

1. Phase 7B bitwise primitives if they were not included with Phase 7;
2. Quot semantics;
3. primitive inductive/constructor/recursor metadata and admission, including strict positivity;
4. recursor/iota/projection/structure-eta computation;
5. mutual/nested source lowering outside the TCB;
6. broader K7/K8 corpus and adversarial parity;
7. compiler checked-core provider cutover;
8. executable portable self-host/fixed-point evidence.

This ordering is provisional and may be adjusted by measured corpus/dependency pressure, but later phases may not bypass missing semantic gates merely to reach compiler integration sooner.
