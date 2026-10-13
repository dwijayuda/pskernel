# PSCV0 v7 — New-chat continuation prompt (M1, then M2)

**Handoff refreshed 13 October 2026 (Asia/Jakarta).** GitHub branch was verified at documentation-only commit `b57849d2b7fe30c9e9da448568f0d2bbb50c1f79`; the current document update will advance HEAD again. Compare `fc8bc8b1f16ed993fb144e2d396c0760c068630b...b57849d2b7fe30c9e9da448568f0d2bbb50c1f79` reported **five commits changing documentation only**. **Latest independently CI-qualified executable remains `fc8bc8b1f16ed993fb144e2d396c0760c068630b`, Linux [38323422371](https://github.com/dwijayuda/pskernel/actions/runs/38323422371), passed.** In the next chat, re-read HEAD and CI and do not confuse documentation commits with executed acceptance.

Continue implementing **my PSCV0 v7 native Lean compiler** autonomously, systematically and dependency-first, completing **M1 before M2**. Do not redo already qualified work.

**GitHub repo:** https://github.com/dwijayuda/pskernel
**Branch:** `psc0/pscv0-v7-native-lean-v1`
**Draft PR:** https://github.com/dwijayuda/pskernel/pull/109

## Recover the current state (mandatory)

Use **GitHub as the canonical source of truth**. Resolve the live branch HEAD and CI *before* editing. Read:
1. `psc0/AI_WORK_STATE.md` — current TOP and new-chat handoff; lower historical entries can be superseded.
2. `psc0/docs/PSCV0_M1_M2_IMPLEMENTATION_AUDIT_2026-10-13.md` — qualification and proof blockers.
3. `psc0/docs/PSCV0_NATIVE_LEAN_GRADE_ARCHITECTURE_REDESIGN_V1.md` — architecture and invariants.
4. `psc0/docs/PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md`, `psc0/docs/PSCV0_STANDARD_SNAPSHOT_V1.md`, and canonical `psc0/PSCV0_LANGUAGE_REFERENCE.md`.
5. Current native `.lean` sources in `Ps.Environment.StandardGetElem`, `Ps.Environment.Decision`, `Ps.Meta.SynthInstance`, `Ps.Erasure`, `Ps.CompilerIr`, compiler and native host; pinned upstream Lean.

**Last qualified executable as of this handoff:** `fc8bc8b1f16ed993fb144e2d396c0760c068630b`, **green Linux CI** https://github.com/dwijayuda/pskernel/actions/runs/38323422371. Branch HEAD at handoff was `6d8c96ddb7d8fb7e0ff00dce85eca1ae4ee27ebc` and was documentation-only beyond the qualified code; do not confuse it with newer executable acceptance. Official Lean is **4.35.0-rc4** at upstream commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`. 170 portable / 178 native `.lean` modules; **198 shared runtime observations** in strict TS, direct JS, Rust and V8 Wasm GC/Wasmtime qualification. Selected Standard: **230 declarations, 14 classes, 40 ordered instances**, FNV `fnv1a64:17137083495666611555`, SHA-256 `sha256:b0ddaa7acc463b9457aac13bd8f08a2f6f8e64bba32b76f7e469ebf1a973f08f`. These certify a **bounded** profile, not all of Lean or PSCV0 v7.

## M1 — finish sound, exact indexing first

Already qualified: checked proof-carrying `GetElem`; selected Type-0 `GetElem?` with superclass; a **low-priority default** derived from a checked `GetElem` dictionary plus a genuinely dependent `∀ xs i, Decidable(valid xs i)`; `Decidable True`/`False`; runtime successful optional/bang and invalid optional returning `none`; an audited `outOfBounds` term that is definitionally `Inhabited.default` in proofs but **panics at runtime**. Preserve this behavior across JS/TS/Rust/Wasm.

**Critical unsolved obligation:** `LawfulGetElem` is a kernel-checked Prop class with TWO equality proof fields, but its generic default-derived instance is **not proven**. The prior `rfl` attempt failed in the official kernel: the implementation captures one dependent decision procedure, but its law quantifies over an independent `Decidable` dictionary. Solve the general coherence proof propositionally (genuine `Decidable` subsingleton/proof-irrelevance or equivalent sound reasoning), or refuse the instance. **Never** add an axiom, invent a witness, treat Bool as Prop, weaken the law, or relax tests.

Then coherently implement the actual `List`/`Array`/`Fin` indexing family: proof-bearing `i < length/size`, lawful `GetElem?`, safe optional lookup, precise bang-panic semantics, valid/invalid proof cases, and all-target IR/runtime behavior. Generalize the Type-0-only `Option`/`GetElem?` closure correctly across universes, including checked constructors, recursors, erasure and backends, before claiming full RC4 fidelity. Extend proof-producing `get_elem_tactic` only with sound bounded assumption/rfl/constructor/arithmetic/simp/omega capabilities.

Reference pinned Lean [`src/Init/GetElem.lean`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Init/GetElem.lean) and dependent primitives. Prefer a complete architecture for related indexing behaviors to a patch for one fixture.

## M2 — complete instance search after coherent M1 milestones

Already qualified: `Ps.Meta.SynthInstance` has invocation-local **positive-answer memoization** with full resolved goal keys, re-inference/re-unification before reuse, priority-preserving candidate selection, rollback, dependent Pi synthesis, postponement until inputs are ready, and **independent 4096 goal-visit and 4096 candidate-attempt caps** propagated across nested search. Unsupported/exhausted work fails closed. Duplicate old candidate paths were removed.

**Still missing:** true Lean-style **generator/consumer goal table**, suspended waiters, new-answer propagation through mutual cycles, coherent synthetic metavariable/expected-type/universe dependency scheduling, output-masked candidate keys vs full answer keys, deterministic local/import instance scope, and proven bounded resource behavior.

Study pinned Lean [`src/Lean/Meta/SynthInstance.lean`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Meta/SynthInstance.lean); redesign the existing sole solver cleanly **rather than layering a second implementation or only increasing fuel**. Minimal high-value positive/refusal scenarios: diamonds, cycles, dependent chains, polymorphic outputs, local shadowing; then real compile-time and peak-memory comparisons with the pinned Lean implementation.

## Implementation discipline and boundaries

Understand specifications, dependency graph and invariants before code changes. **Implement coherent features first and test at meaningful boundaries**; use earlier tests only for critical assumptions. Freely replace weak internal architecture, without compatibility scaffolding or test-by-test patching. Preserve checked source/Core → **official Lean kernel** → explicit proof/type erasure → strict validated IR → JS/TS/Rust/Wasm GC and Canonical ABI adapters; do not weaken correctness, proof coverage, assumptions, typed panic, runtime results, fingerprint guards or CI.

**Mandatory:** compiler remains portable native **`.lean`**. **No** pskernel-core, self-hosting, compiler-source `.ps` migration, C5, Desktop Commander/local checkout/build, force push, branch deletion, merger to main, or unrelated backend redesign. GitHub-first source edits and **Linux GitHub Actions** qualification. Preserve branches, draft PR #109, original provenance, GC internals and ABI-only linear memory.

Run minimal relevant positive/negative tests first and the established official Lean plus cross-target regression after each coherent implementation phase. Report exact executable SHA/CI; distinguish elaborated, kernel accepted, IR validated, emitted, runtime qualified and benchmarked. **Full M1/M2, full v7, formal compiler correctness and performance parity are still not achieved.** Continue autonomously within each conversation turn, with no repeated permission requests or promise of asynchronous completion. After each qualified milestone update the TOP of `psc0/AI_WORK_STATE.md`, this prompt, roadmap and audit, preserving history.

**Start now: read the latest HEAD and CI, inspect the real M1 lawfulness/dependency proof, implement its sound root-cause resolution, then complete indexing before full M2 waiter tabling.**
