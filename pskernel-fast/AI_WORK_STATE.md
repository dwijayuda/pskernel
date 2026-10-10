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

## Cloud CI evidence, October 11, 2026

Initial source commit `0a4f0ce48aa421be8df92fdc09ed6f6c204f80d5`: [run 38093827666](https://github.com/dwijayuda/pskernel/actions/runs/38093827666), job 114335503566 **failed during lean-action configuration** because this new package had no `lake-manifest.json` and the workflow used `auto-config: false`. **No source compilation, smoke or kernel proof checking ran.** The next workflow sets `auto-config: true` so Lake may generate the manifest. It also exposes a top-level `main` for the executable. The corrected revision must be validated by its own completed workflow; do not convert the first failure into a pass.

**Second workflow outcome:** corrected source commit `b712bc5109ecce5da2752e5de8a551e267fd7b9e`, [run 38093919479](https://github.com/dwijayuda/pskernel/actions/runs/38093919479), job 114335774523, **failed before compilation** for the same missing `lake-manifest.json` because `lean-action@v1` checks it even with `auto-config: true`. The next CI uses direct pinned elan installation followed by `lake update` and `lake build`. Both failures are **CI configuration blockers only; the prototype has not yet compiled or run**.

**Third workflow outcome:** source commit `6a13b87ecea0b37300ec51c4a47eb2f5b279dd76`, [run 38093991215](https://github.com/dwijayuda/pskernel/actions/runs/38093991215), job 114335993755, **reached Lean compilation** after `lake update`; failed on a malformed opening doc comment terminator in `TermStore.lean:7` (`-/-` instead of `-/`). Correct the syntax in one coherent source edit. The smoke executable never ran in that attempt. Next workflow also uses sparse checkout to avoid loading unrelated legacy files; it remains native G1 only.
