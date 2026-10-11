# PSKernel-Fast V3 — G2 comparative beta-evaluator evidence

**Research date:** October 11, 2026, Asia/Jakarta.  
**Source commit checked:** [`3ed28be5834078d5cd33a762cb183cf9693a2520`](https://github.com/dwijayuda/pskernel/commit/3ed28be5834078d5cd33a762cb183cf9693a2520).  
**Validated GitHub Actions:** [run 38107735958](https://github.com/dwijayuda/pskernel/actions/runs/38107735958), job `114376707944`, **success**.  
**Pinned toolchain:** Lean `v4.35.0-rc4`, commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.  
**Source:** `pskernel-fast/src/PSKernelFast/{TermStore,Reduction,DagReduction,ReductionSmoke,ReductionBench}.lean`.  
**Scope:** tiny untyped lambda-calculus beta-only weak-head normalization; neither Lean kernel checking nor soundness proof of the lazy evaluators.

## 1. What was actually checked

- **16 Lean build jobs** successful on GitHub Actions.
- Import/architecture boundary audit passed (six independent V3 Lean source files; no old `Ps.KernelCore` import).
- Named deterministic test cases with **independent expected results**: captured binder under lambda, second binder, multiple beta, shared/duplicated body, neutral head not reducing its argument, longer beta chain, escaped bound-variable rejection, invalid handle, omega fuel exhaustion.
- Additional **92 bounded generated closed expressions**, with equal final WHNF for eager tree substitution, lazy closure/tree and lazy closure/direct DAG. Generated run counted zero paired exhaustion.
- Two local Lean theorems compiled: `eagerHeadStep_sound` (the executable eager one-step result is a valid `HeadBeta` step) and `isScoped_sound` (executable successful scopedness check entails declarative `RawScoped` binder condition).
- No declaration checking, theorem acceptance API, Lean universe semantics, inductive/quotient checking, complete laziness refinement theorem, or full Lean 4.35 compatibility.

## 2. Exact repeated timing

The benchmark generates 28 independent closed identity-chain terms, encodes and strictly decodes them into the G1 term store **before** timing. Each strategy uses identical validated input terms and returns an equivalent raw WHNF, checked via per-run result digest. Both lazy engines include final readback in their timed segment. Each strategy processes `28 × 180 = 5040` expressions per repetition, **5 repetitions**, with rotating strategy order and warmup.

| Repetition | Eager substitution | Lazy tree closures | Lazy DAG handles |
| ---: | ---: | ---: | ---: |
| 1 | 121 ms | 7 ms | 7 ms |
| 2 | 128 ms | 6 ms | 7 ms |
| 3 | 120 ms | 7 ms | 7 ms |
| 4 | 120 ms | 7 ms | 7 ms |
| 5 | 121 ms | 6 ms | 7 ms |
| **Median** | **121 ms** | **7 ms** | **7 ms** |

These are **single-host wall times**, in milliseconds, with very short lazy runtimes. No retired instruction counts or per-engine peak RSS were collected. They exclude DAG parsing/encoding/decoding and any Lean type checking. The eager engine limits **beta contractions**, whereas lazy engines limit **machine transitions**; their resource outcomes are not directly comparable under equal numeric fuel. This benchmark does not establish any speedup factor against Lean's actual kernel, MathGraph, con-ron, or Mathlib.

For this very narrow corpus, beta closures reduced measured elapsed time substantially. Direct DAG handle-based evaluation had **no measured advantage** over raw-tree closures. The ratio of 121/7 is a property of this tiny workload, not a product-level speed ratio or representative estimate.

## 3. Important architectural decision

**Keep lazy closures as the leading experimental WHNF algorithm, but do not force the compact DAG layout as the engine's canonical representation.** Its correctness, memory behavior and performance still need separate evidence on large shared graphs. The tree-backed and DAG-backed closure engines are both experimental and neither can authorize proof checking. Choose the simplest representation meeting the real benchmark and proof requirements.

An especially important concern is that the validating store decoder produces a RawExpr to check scope. Runtime benchmark preparation performs that validation once, outside timed runs; any future public proof checker must ensure the validated store representation is sealed or proven sound, not allow a forged prevalidated handle as a shortcut.

## 4. Proof and correctness inventory

| Obligation | State |
| --- | --- |
| A successful primitive eager weak-head step satisfies the explicit `HeadBeta` relation | **Proved in compiling Lean source** |
| Successful `isScoped` entails binder-scope `RawScoped` | **Proved in compiling Lean source** |
| Two lazy engines match eager on fixed + 92 generated cases | **Tested, not universally proved** |
| Eager finite WHNF trace soundness and eventual terminality | **Open** |
| Lazy tree machine/closure readback refinement to declarative beta WHNF | **Open** |
| Direct DAG closure machine refinement and store invariant | **Open** |
| Trusted handle validation/interned ID uniqueness under adversarial mutation | **Open; no admission capability exists** |
| Lean 4.35 type checking / DefEq / inductives / quotients | **Not implemented** |
| Actual runtime proof-acceptance soundness and consistency | **Not implemented/proved** |
| Native vs self-hosted JS/Wasm qualification | **Not attempted** |

## 5. Next major milestone

Do not spend further time polishing the tiny beta benchmark for a headline ratio. Move to **G3: Lean-semantic CoreExpr and universe/constant infrastructure**, with a versioned source-rule matrix, checked-result grades and context-aware definitional equality. Use the existing three evaluators as design experiments, not as mandated source APIs. Profile the first actual Lean-compatible checker vertical slice when constructed, and add model/refinement proofs for the code that can return a positive checked result.

Preserve the live old proof work/PR #89 as Git history only; **no old implementation or proof preservation requirement** applies to V3. Each future source change gets its own completed cloud CI evidence.
