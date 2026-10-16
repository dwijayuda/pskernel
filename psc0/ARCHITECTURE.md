# PSC0 native v7.2 — current, target, and later architecture

**Status:** Active architecture authority for the native PSC0/PSCV0 compiler on branch `psc0/pscv0-v7-native-lean-v1`. **This is a design and implementation contract, not a completed-language or verified-backend claim.** Updated 17 October 2026.

The earlier PSC2 self-host bootstrap plan formerly stored at this path is retained [verbatim as history](docs/history/PSC2_MINIMAL_SELFHOST_ARCHITECTURE_SNAPSHOT.md). It is **not** the current M3+B execution plan. The older [npm/kernel-centered architecture](docs/PSC0_SOUNDNESS_SECURE_EXTENSIBLE_ARCHITECTURE.md), [native redesign research](docs/PSCV0_NATIVE_LEAN_GRADE_ARCHITECTURE_REDESIGN_V1.md), and [direct-backend research](docs/PSCV0_DIRECT_JS_WASM_ARCHITECTURE.md) remain useful research/long-term perspectives, but do not override the active roadmap or source.

## 1. Authority and invariant ownership

1. Normative `.ps` behavior: [PSCV0 language reference v7.2](PSCV0_LANGUAGE_REFERENCE_v7.2.md), source blob `694115223777599ba28ee175e14bb642b7b6aa4b`; no v7/v7.1 compatibility mode. Ordinary `.lean` retains the normal Lean grammar and is not restricted by the selected `.ps` profile.
2. Operational stage/acceptance boundaries: [v7.2 directive](docs/PSCV0_V72_STAGE_DIRECTIVE_2026-10-16.md) and [current milestone roadmap](docs/PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md). Exact CI/source receipts and executable code supersede dated pending text.
3. Pin: official Lean **4.35.0**, commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. Study matching official source **and tests** before extending semantic algorithms. Adapt selected algorithms without copying Lean's entire elaborator.
4. During M3+B use **native portable `.lean` compiler sources and cloud Linux/GitHub CI**. No `pskernel-core`, independent kernel, self-host/bootstrap migration, Desktop Commander, local code execution or C5 release work. Preserve PR #109 (draft/open/original base) and existing qualified work.
5. **One owner per invariant:** parser owns syntax; elaborator owns source semantics and computed proof terms; official Lean kernel owns logical acceptance; erasure owns runtime relevance; typed IR validation owns representability; host owns admission/assurance and file publication; backend owns only target-specific implementation choices. A backend must never manufacture proof authority.

## 2. Implemented pipeline (not the same as end-state)

```text
.ps bytes, source identities, selected Standard and import closure
 → Ps.Syntax.Pscv0 (tokens, source owners, scoped declarations, patterns)
 → Ps.Elab.Scope / Command, Ps.Meta (resolution, inference, constraints)
 → prepared Ps.Core declarations + origin graph
 → canonical Ps.Bridge.CheckAdmissions serialization
 → official Lean 4.35 kernel replay in Ps.Host.NativeV7
 → same retained prepared declarations (never a replacement JSON token)
 → Ps.Erasure typed binder/field/index/recursor lowering
 → Ps.CompilerIr.Model + CheckTypes/Check + specialization
 → target-neutral checked module, then per-target capability checks
    ├─ Ps.BackendEcma shared plan → JavaScript + TypeScript
    ├─ Ps.BackendRust layout, captures and runtime
    └─ Ps.BackendWasm typed GC core + WIT/Canonical ABI component
 → Ps.Codegen provenance, source map, artifact bundle + host publication
```

**Actual source anchors:** `packages/{syntax,environment,core,meta,elab,bridge,erasure,compiler-ir,compiler,backend-ecma,backend-ts,backend-rust,backend-wasm,codegen}/src`, `host/src/Ps/Host/NativeV7.lean`, `packages/pskernel-lean/provider`, and `v7-native/lakefile.lean`. The host compiles with the official Lean kernel and a pinned selected prelude, not the independent PSKernel project.

**Current proven-by-CI boundary:** selected source and modules are accepted by official Lean; typed erasure and IR validation reject unsupported forms; published JS/TS/Rust/Wasm scalar and bounded recursive programs have differential oracles. This **does not prove** the elaborator's interpretation of every `.ps` source, the semantics of all primitives, general backend preservation, or complete v7.2 conformance. Never call a diagnostic receipt, serialized check result, or raw `PsVerifiedIrModule` a user-mintable verification capability.

**Selected already implemented:** scopes/public-private module interfaces, dependency ordering, scoped tabled typeclass solver with answer replay, selected dependent/indexed data and match matrices, checked direct-recursive deriving, structural recursion and checked Core definitional equality, explicit runtime type/proof/index erasure, IR validation, multi-target emission and measured runtime baselines. **Not fully implemented:** mutual/nested/indexed family groups and deriving, full well-founded/strategy matrix, partial P0 ordinary execution, P1 fixedpoints, M4 effects/contracts/assurance grades, complete incremental tooling/optimization.

## 3. Target shared semantic architecture — no alternative proof kernel

### 3.1 A single, group-aware inductive and recursion owner (M3+B)

The core future change is *one staged declaration group plan*, rather than independent ad-hoc paths for each derived class or pattern:
- **Header plan:** collect every family's name, shared parameters, universe information and indices before checking any constructor. For mutually recursive groups use one consistent parameter context and a dependency graph, not sequential axioms falsely presented as checked declarations.
- **Constructor plan:** elaborate in the group environment; validate type, universe, unchanged uniform parameters, indices and strict positivity for **every occurrence**, including nested containers and nonrecursive-looking dependent fields. Track provenance and fields in the actual source telescope.
- **Recursor plan:** construct the full motive/minor telescope, actual recursive hypotheses and elimination universe rules for the group. Kernel-check the generated recursors and family declarations. Never create an unchecked IH, assume an impossible branch or use a fabricated equation.
- **Match/deriving consumer:** `Ps.Elab.PatternMatrix`, `Match`, and the five deriving handlers must use the **same checked group/recursor plan**. Nested/indexed/mutual cases are enabled only when that plan and all dependent erasure/runtime owners are ready. Preserve unsupported cases as truthful fail-closed refusals.

Official comparison: pinned `Lean/Elab/MutualInductive.lean` stages group headers, constructors, universe checking, kernel admission and finalization. Pinned `Lean/Elab/PreDefinition/Structural/*` separately validates decreasing arguments against actual recursive hypotheses. Adapt these algorithms to the narrower selected language; **do not** add a source-name whitelist or build a second kernel.

### 3.2 One explicit recursion-strategy/partial-body representation (M3 → M4)

Represent total structural, total well-founded, ordinary `partial`, fixedpoint and restricted `unsafe` as **distinct source strategies**, keeping declaration and suffix ownership separate from any executable admission decision. Source `partial` currently creates (a) a public logically opaque, independently inhabited declaration and (b) a private typed actual-body marker; those are not interchangeable. No `partial` executable artifact is currently admitted. Ordinary partial runtime lowering requires actual body/dependency identity and backend operational support. Any verified partial behavior requires a separately checked operational model plus source/body/target refinement. `partial_fixpoint` must reuse the pinned Lean construction and transitive assumption audit; no unapproved `Classical.ofNonempty` fallback, proof escapes, or manufactured equation theorem.

Exactly one approved logical basis (current policy `propext`, `Quot.sound`), with explicit primitive and foreign-runtime trust ledger; any additional permitted assumptions require an explicit future policy decision. Succeeding at type checking must not silently change an explicit verified request to ordinary output.

### 3.3 Typed runtime relevance, stage invariants and optimization (M3–M5)

Use a single checked binder telescope for `runtimeValue`, runtime-reifiable types, erased dependent indices/type formers, and erased proofs, with source-position mappings shared by declaration/call/constructor/recursor/closure/projection. A computationally relevant erased value is an error. `PsVerifiedIrType.unknown` is diagnostic only and prohibited from accepted executable IR. Prevent typed runtime transformations from discarding overflow, failure/exception, cancellation, nontermination, order of evaluation, or persistent-data semantics.

Current `Ps.CompilerIr.Model` is an expression IR; it is **not** yet Lean's mature phase-separated LCNF/ANF pass architecture. Introduce explicit checked runtime/ANF and pure/impure effect phases **when supported workload evidence justifies them**, with validation after each semantic transformation; share lambda lifting, dictionary specialization, direct-call and closure analysis before splitting into JS/TS/Rust/Wasm-specific layouts. Keep direct JS/TS from one ECMAScript plan and Wasm GC storage separate from WIT boundary marshalling. No mandatory LLVM, `rustc` to Wasm, `tsc` to JS, or universal low-level IR.

### 3.4 Assurance and incremental/module boundaries (M4–M5)

Use three distinguishable outcomes under **one** source language: ordinary checked, closed verified and boundary-qualified verified. A verified artifact may be emitted only after all requested proof, specification, effect, assumption, runtime-model/target correspondence and erasure obligations are discharged; no automatic downgrade. `Return`, `Throw`, `Trap`, `Diverge` and trace/progress claims are distinct and need target-appropriate evidence. The present `PsV7Native.Request` does **not** yet expose these assurance selections, so this is target design rather than shipped support.

Project source imports and public/private interfaces are implemented for bounded sources; Lean-style incremental elaboration, deterministic red/green invalidation, editor info trees and fine-grained source maps remain broader M5 goals. Treat past in-memory prefix caching as a bounded optimization, never as reusable kernel admission authority. Extensions may propose syntax/proofs/IR, but cannot mint host checker tokens, load untrusted guests inside the trusted process, or authorize a verified release.

## 4. Architecture comparison to pinned Lean 4.35

| Area | Lean 4.35 architectural fact | PSC0 current / target judgment |
| --- | --- | --- |
| Meta/elaboration | Rich dependent metavariable solver, tabled typeclass resolution, incremental command processing | Native solver and scopes exist; selected subset is intentional, but broad completeness/tooling is behind Lean |
| Inductives/termination | Group-aware inductive elaboration, recursors, structural/WF/partial/fixpoint strategies | Selected single-family and direct recursion work; *general group/recursion owner is next critical path* |
| Kernel | Small mature checking kernel | Correct choice: **reuse official Lean**, never replace or bypass it in active PSC0 |
| Compiler optimizer | LCNF, pure/monomorphic/impure stages, pass validation and mature runtime | Checked expression IR + specialization are real, but not yet equivalent in pass structure or performance |
| Backend/ABI | Native-oriented runtime/foreign interfaces | PSC0's direct JS/TS/Rust/GC/components are a real specialized portability advantage on supported cases |
| Assurance | Logical checking and supporting verification tooling | PSC0 can offer a more explicit audited-artifact policy, but no general backend correctness claim yet |

**Verdict:** the PSC0 plan is strong and specialized, **not already equal to Lean 4 in implemented quality**. Improve the present pipeline's missing shared semantic stages; do not restart the compiler or claim theoretical strength from extra backends.

## 5. Exit ownership and next work

| Stage | Owner, exit and explicit non-goal |
| --- | --- |
| **M3+B** | Shared data family/group formation, motives/pattern/deriving, checked structural/WF recursion and v7.2 source strategy; P0 typed logical/body identity and selected ordinary executable foundations; P1 checked fixpoint/assumption gating. The six [roadmap exit criteria](docs/PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md) remain authoritative. |
| **M4+C** | Broader effects, runtime operational outcomes, partial executable control/state, loops/FFI boundaries, not a new source logic |
| **M4+D** | Proof obligations, contracts, partial/total/trace/refinement/assurance evidence and fail-closed verified artifact policy |
| **M5+E** | End-to-end conformance/evidence, validated optimization/performance, incremental tooling, C5 retained-source correspondence |
| **Later only** | Independent kernel, npm/self-host fixed point, language-source migration, plugin host/stdlib ecosystem and alternate distribution/runtime strategies |

**Development gate:** read fresh HEAD/CI and the stage directive; inspect the relevant pinned Lean implementation/tests; update the *one semantic owner* and compact independent positive/negative fixtures; keep original thresholds; run same-SHA native, F1, F2, F3/F4 and relevant focused backends; preserve evidence/previous history; update both `AI_WORK_STATE.md` and `AI_CONTINUE_PROMPT.md`. A green small slice is **not** the six-criterion M3 exit.

**Current accepted M3 checkpoints:** direct recursive `Hashable`/`Repr`/`BEq`/`DecidableEq`; checked computed strict children; fixed and evolving prefix recursion; exact open `Nat.add a 0` and `Nat.sub a 0`. Selected `HAdd` `k + 0` source and two-discriminant `Bool × Nat` pattern fixtures passed their focused lanes on recent descendants, with full native acceptance recorded for compiler `33c569e08af2484d90f3bd0b0da7a97cfaf1ad3a`. More general nested/mutual/data, P0/P1 and full M3 completion remain open.

Historical documents are evidence, not the source of current implementation authority. Update this document only when actual owner boundaries change.
