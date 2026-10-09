# Historical PSKernel Self-Host Development Plan

This document preserves the pre-migration 4.34 milestones and receipts. Current
PSC0 authoring, the user-selected 4.35 target, and current-stage evidence take
precedence: see `README.md`, `PSKERNEL_CORE_ARCHITECTURE.md`, and
`RESEARCH_AND_MIGRATION.md`. Completion statements below are historical and do
not certify this migrated revision.

## Active phase status

- **Phase A — Semantic closure: COMPLETE.**
  - Lean 4.34 compatibility matrix: 34/34 required rules implemented.
  - conformance registry: 34/34 rules mapped to direct differential/invariant tests.
  - `--require-complete` is enforced in CI for both compatibility and conformance audits.
  - green semantic baseline: `5d684efc33de559045bac74dfc0cb45fcc9a41ee`.
- **Phase B — Canonical architecture migration: COMPLETE.**
  - `PSKERNEL_REFERENCE.md` is now the canonical target architecture/migration guide.
  - preserve the Phase A semantic baseline while migrating source ownership, tests,
    dependency boundaries and public contracts.
  - completed: split tests/benchmarks, import fences and Lake registration audit,
    Core/Environment ownership, Checker/Ops/Knot, unified Admission hierarchy,
    acceleration/capability separation, ResourcePolicy and KernelContract-v1.
  - 61 rule ownership/evidence mappings preserve the 34-row compatibility matrix.
  - completion concerns production architecture; Phase D and provider promotion
    remain separately gated. See `ARCHITECTURE_MIGRATION_REPORT.md`.
- **Phase C — Competitive performance: M3 COMPLETE FOR THE BOUNDED PROFILE.**
  - M3 now uses the explicit small-workload latency/memory budgets in
    `M3_ACCEPTANCE.md` and `M3_WORKLOAD_BUDGETS.json`; all 28 budget checks and
    semantic/portable gates passed at `c13558c6d573ef477fed6f0ffa31a9b7e39650ca`.
    Native is the preferred CLI/server deployment target; broad JS optimization
    is deferred. Relative speed against Lean is informational, not an exit gate.
  - current pass is cost-bounded: three native and Node benchmark samples,
    ordinary conformance/portable gates, and measured cache-pressure diagnostics;
    no full compiler/kernel fixed-point generation or large proof-library replay.
  - current indexing/cache and checker-path work may continue when profiling identifies a
    concrete hotspot and all Phase A/B gates remain green.
  - performance work must not be mixed into structural move commits.
  - the first bounded pass established three-sample reports and nested cache
    diagnostics. A single-descent insertion experiment was rejected after a
    same-runner comparison showed no representative gain; production cache
    behavior is retained.
  - fresh generated-JavaScript measurements now exist for a small shared Node/native
    corpus. They expose a large runtime gap; broader JS throughput remains outside
    the bounded M3 scope. Lean WASM full-request timings are reported separately because its
    subprocess/prelude/JSON boundary differs from direct JS fixture calls.
  - a measured zero-lifting shortcut is retained: paired Node samples reduced
    beta-defeq time by about 38% and beta-WHNF time by about 7%, with checked
    application essentially unchanged. Equality scheduling was rejected and
    reverted. See `PERFORMANCE_BASELINE.md` for evidence and limits.
- **Phase D — Assurance Plane: LONG-TERM / NON-BLOCKING.**
  - formal specification/refinement, independent-checker consensus, fuzzing, receipts and
    broader interoperability strengthen the production kernel after the architecture boundary
    is stable.
  - Phase D is not required for the current production/provider milestone unless an explicit
    release decision promotes one of its checks to a gate.

If a new semantic mismatch with Lean 4.34 is discovered, temporarily return to Phase A only for that defect and add a conformance case before resuming Phase B.


This plan is the execution companion to
`PSKERNEL_CORE_ARCHITECTURE.md`.

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

The current architecture work is migrating the mature implementation toward the
Execution Plane defined by `PSKERNEL_REFERENCE.md`: Core, Environment, Checker,
Admission, Runtime/Acceleration, Runtime/Capability, API and a small SelfHost
semantic root. Every step must remain PSC1-self-hostable and semantically
equivalent to the pinned Lean-4.34 target.

## Phase A — Semantic closure

**Status: COMPLETE for the declared Lean-4.34 compatibility matrix.**

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

### A2. Native-reduction compatibility

Complete and differentially test:

- `Lean.reduceBool`
- `Lean.reduceNat`

Architecture:

- current backend-neutral provider lives in `Runtime/Capability/Lean434NativeReduction.lean`;
- final target ownership is `Runtime/Capability/Lean434NativeReduction.lean`;
- optional provider lives in checker context/session;
- no provider keeps ordinary semantic behavior;
- WHNF order matches Lean 4.34;
- lazy defeq order matches Lean 4.34;
- this is a target-specific trusted capability, not ordinary cache/index acceleration.

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
- canonical `.ps` round-trip green.

Generated compiler/kernel fixed-point proof is optional/manual and is not a
Phase A blocker.

## Phase B — Canonical architecture migration

**Status: COMPLETE (production architecture).**

Goal: make the source tree, dependency graph, trust model, tests and public API
tell the same story as the Lean-4.34 kernel theory while preserving one
PSC1-self-hostable semantic implementation.

The canonical target is `PSKERNEL_REFERENCE.md`. The incremental migration is complete.
Temporary import shims have been removed; callers use canonical module paths.

### B1. Split test and benchmark monoliths

Create subsystem-owned fixtures/conformance/hardening/benchmark modules with
thin aggregate executables. This is the first migration step because it improves
auditability without changing semantic source.

### B2. Machine-readable architecture and import fence

Add:

- `PSKERNEL_ARCHITECTURE.json`;
- an architecture audit script;
- semantic-root closure checks;
- target-pin consistency checks.

The initial manifest describes the current tree plus migration state; CI then
tightens allowed imports as canonical modules move.

### B3. Canonical Checker hierarchy

**Ownership implemented:** Checker hierarchy, Ops contract, single Knot owner and
Session delegation. Existing fuel workers and algorithm ordering are preserved;
legacy imports have been retired. Architecture
CI enforces callback-leaf import fences and unique wiring ownership. Context retains context/binder and builtin helpers used by checker leaves; Core
values/substitution and Environment history/wrapper/lookup/operations now have
canonical owners. ResourcePolicy and the public contract now have explicit portable owners.

Move existing checker components under one `Checker/` owner without changing
algorithms:

```text
Checker/
  Context
  State
  ResourcePolicy
  Projection
  Reduction/
  Inference/
  Recursor/
  DefEq/
  Ops
  Knot
  Session
```

`Checker/Knot` is the one owner of recursive infer/WHNF/recursor/defeq wiring.
PSC1-proven curried callback patterns may remain internally.

### B4. Unified admission hierarchy

**Ownership implemented.** Declaration, Quot and ordinary/mutual/nested admission
now use canonical owners; shared phases are explicit and legacy import paths
have been retired. Algorithms and phase ordering are unchanged.

Move declaration, Quot and inductive admission under `Admission/`. Ordinary,
mutual and nested inductives live under one `Admission/Inductive/` owner while
retaining their existing phase decomposition.

### B5. Separate acceleration from trusted capability

Final ownership:

```text
Runtime/Acceleration/
  Cache
  CachePolicy
  EnvironmentIndex

Runtime/Capability/
  Lean434NativeReduction
```

Acceleration must preserve semantic answers. Lean-4.34 native reduction is an
explicit trusted capability because an incorrect provider can affect
acceptance.

### B6. Stable checked-session API

`KernelContract-v1` is implemented; its entry points and trust boundary are
defined in `KERNEL_CONTRACT_V1.md`. It uses typed errors with the PSC1-supported
`Except` representation, rechecks checked receipts, and preserves full checking.
Public types must distinguish constructed/request state from checked/admitted
state; provider adapters may translate but may not implement fallback semantics.

### B7. Fine-grained rule ownership

`LEAN_4_34_KERNEL_RULES.json` contains 61 mappings, including all 34 unchanged
compatibility rows and 27 focused algorithm/resource/API rules. CI checks unique
canonical symbol ownership and test evidence reachable from the foundation main.
These are regression scenarios, not exhaustive branch coverage or formal proofs.

### Phase B exit gates

- canonical source tree follows the Reference ownership model;
- architecture/import-fence CI is green;
- SelfHost closure imports no compatibility shim, test, benchmark or frozen
  reference-kernel module;
- tests/benchmarks are split by subsystem;
- Checker recursive wiring has one owner;
- ordinary/mutual/nested admission share one canonical hierarchy;
- acceleration and trusted capabilities are visibly separate;
- KernelContract-v1 is stable;
- `KERNEL_THEORY.md` matches the canonical source layout;
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

Replace linear maps/sets behind `Runtime/Acceleration/Cache` with indexed structures.

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

Historical optimization guide (not an M3 release gate):

- approximately 1.5–2x Lean where practical.

Longer-term target:

- around Lean performance where practical.

JS target:

- preserve the portable artifact and meet the named small Node workload budgets;
  browser and broader npm/provider readiness are separate deployment work.

### Phase C exit gates

- semantic/conformance gates unchanged;
- measured performance regression tests exist;
- environment/cache improvements show real workload gains;
- all native and JS ceilings in `M3_WORKLOAD_BUDGETS.json` pass on the declared
  profile; every one of three samples meets latency and peak-memory limits;
- JS remains portable through the PSC/backend-ts path.

## Continuous portable-source self-host gate

Every phase must preserve:

```text
portable .lean source
      |
      v
portable-source profile
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
Lean build + differential/conformance
```

The expensive generated compiler/kernel fixed-point workflow is manual-only.
Use it for explicit bootstrap/release checkpoints, not as a normal
readability/performance gate.

## Milestone definitions

### M1 — Lean 4.34 feature complete

- all compatibility rows implemented;
- conformance suite green;
- no known semantic gaps.

### M2 — Canonical explainable kernel

- `PSKERNEL_REFERENCE.md` Execution Plane ownership established;
- tests/benchmarks split by subsystem;
- architecture manifest/import-fence CI established;
- Checker recursive knot has one owner;
- admission/inductive hierarchy is canonical;
- acceleration/trusted-capability distinction is explicit;
- rule documentation complete;
- `KERNEL_THEORY.md` usable as a learning path.

### M3 — Competitive kernel

Bounded acceptance scope: `M3_ACCEPTANCE.md`. **Status: COMPLETE**, verified at
`c13558c6d573ef477fed6f0ffa31a9b7e39650ca`. Continue enforcing these gates;
new deployment profiles and larger workloads need their own explicit budgets.

- indexed environment/cache structures;
- measured native performance meets the declared CLI/server workload budgets;
- JS meets its declared small Node workload budgets and remains portable;
- corrected runtime-selected admission inputs and complete timing/memory evidence;
- no semantic regressions.

### M4 — Provider-ready

Implemented by the native adapter and bounded provider gate described in
`M4_ACCEPTANCE.md`. Acceptance is tied to the reviewed revision's green checks.
Not required for M1–M3, but needed before replacing the current authority:

- canonical declaration adapter exists;
- dual-check mode exists;
- provider parity gate is green;
- generated self-host kernel can be manually reproduced when a release
  checkpoint requires it.

Completing M4 does not change the default authority: `lean434-wasm` remains the
default until a separate explicit provider-promotion decision.

## Work-selection rule

When choosing the next task, prefer:

```text
current phase exit blocker
> compatibility defect
> Reference migration step that improves trust/auditability without semantics
> readability debt obscuring a high-risk rule
> measured performance hotspot
> optional Assurance-Plane feature
```

This prevents the project from drifting into unrelated language/backend work.
