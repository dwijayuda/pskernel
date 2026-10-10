# PSKernel-Fast V3 work state

## Scope and authority

New-generation PSKernel-Fast independent architecture. **Performance and semantic correctness take precedence over preserving old checker or old proof work.** V3 is canonical at [architecture](PSKERNEL_FAST_ARCHITECTURE_V3.md). Lean target: 4.35.0-rc4; source commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.

Working branch: `research/pskernel-fast-clean-v3-20261011`. Source ancestor: V2 research commit `80f198c41fe7e3a8bd96a910672f26f5ddd94882`. Active kernel proof branch, its prior evidence and draft PR #89 are **not dependencies and are not modified**.

## Completed document decisions

- V3 architecture document created with full freedom for a new kernel implementation, compact DAG / closure/NbE alternatives, formal method target, benchmark gates and clean architecture.
- V2 document on THIS research branch explicitly marked superseded.
- No V1/V2 checker integration, migration theorem or old self-host source profile is required to select V3's implementation.

## Prototype state

The first G1 term-store experiment consists of:
- `src/PSKernelFast/TermStore.lean`: tiny closed AST, total scope-validating encoder, collision-checked interning, capped allocation, fuel-limited decoder;
- `src/PSKernelFast/Smoke.lean`: narrow safety smoke cases;
- standalone pinned Lean 4.35 Lake configuration and GitHub Actions focused workflow.

**Evidence status at authoring:** source committed once the associated commit is created; CI outcome **not yet known**. No kernel checker/admission implementation, executable proof soundness theorem or measured speedup. Do not upgrade to passed/verified unless the completed cloud CI job and exact commit are inspected.

## Next steps

1. Inspect workflow outcomes and fix any real Lean compiler errors in the coherent term-store slice; no proof shortcut.
2. Prove exact interning/encoding/scope invariants on the current implementation (not an unrelated reference model).
3. Add exact Name/Level/Expr representations and scope/level checks toward full Lean 4.35 syntax.
4. Build two comparable WHNF engines (eager DAG vs lazy closure) behind the same input/output contract and profile on controlled corpus.
5. Only after correct reduction/typing gates, add a checked inference/DefEq engine and declaration admission; keep fail-closed error types.
6. Track actual source LOC, trusted runtime dependencies, CI, mem/RSS and the current open formal-obligation ledger on every milestone.

## Operating rules

GitHub and cloud CI only, no local checkout or Desktop Commander. Re-read live HEAD before write; preserve branch history and concurrent work; no force update. Use small fast tests for ordinary changes and budgeted broad Init/Std/Mathlib only at stated release gates. Do not claim green CI, self-host, Lean-compatibility or consistency without matching evidence.
