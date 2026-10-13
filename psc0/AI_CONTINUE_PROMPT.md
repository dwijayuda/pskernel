# PSCV0 v7 — New-chat continuation prompt (M1, then M2)

## Current qualified checkpoint — M1 universes and bounded index proofs (13 October 2026)

This section supersedes older checkpoint claims below.

- **Executable:** [4fe35ca32b8f3b49f85b89bb9b699d95f7fd7b7d](https://github.com/dwijayuda/pskernel/commit/4fe35ca32b8f3b49f85b89bb9b699d95f7fd7b7d).
- **Green Linux qualification:** [38382777891](https://github.com/dwijayuda/pskernel/actions/runs/38382777891), official Lean 4.35.0-rc4.
- **Selected Standard:** 258 declarations, 14 classes, 43 ordered instances; 171 portable / 179 native Lean modules.
- **Frozen FNV:** `fnv1a64:7381279441732502588`.
- **Frozen SHA-256:** `sha256:c1444324de1014fa01b9c82fb09f2a6ab96b824ac08ae6b6e548e2145fd61c85`.
- **215 shared runtime observations** passed in direct JS, strict TS, Rust, V8 Wasm GC and the native Wasmtime component host. All prior 198 observations remain.

Qualified: universe-polymorphic Option constructors/recursor, map/bind/getD/filter,
BEq and Inhabited; GetElem?, default implementation and both LawfulGetElem laws
at the element universe; higher-universe dictionary synthesis and erasure.
Explicit Option.bind may change universes; monadic Option do fixes a single
universe as RC4 does. An independent oracle and a negative do case cover that boundary.

Index automation now constructs checked natural-order proofs from definitional
normalization, closed comparisons, successor rules and bounded local transitivity
search. It is not full omega. Large natural indices remain arbitrary precision.
The unifier first tries congruence for a shared named application head, retaining
dictionary argument identity; failure rolls back and uses ordinary reduction.
This avoids unfolding an inferable dictionary argument into applied metavariables.

The official kernel admitted the selected definitions and source proofs; strict
IR and all existing runtime gates passed. Single-run all-target timings: parse
110 ms, elaborate 93 ms, prepare 121 ms, kernel 70 ms, erase 251 ms, emit 494 ms.
These are observations, not a controlled performance comparison.

**M1 remains incomplete.** Next: checked List/Fin indexing and optimized optional
laws, Array logical model and genuine size bounds, panic/alias/large-index coverage,
and controlled representative performance comparisons. Full M2 waiter tabling,
C5, pskernel-core and self-hosting remain excluded. Read live HEAD and CI first.

## Prior qualified checkpoint — M1 natural order (13 October 2026)

This section supersedes older status statements below; historical evidence is preserved.

- **Executable:** [064baf31641ff19785feae1416eb353b38737794](https://github.com/dwijayuda/pskernel/commit/064baf31641ff19785feae1416eb353b38737794).
- **Green Linux qualification:** [38379674588](https://github.com/dwijayuda/pskernel/actions/runs/38379674588), official Lean 4.35.0-rc4.
- **Selected Standard:** 258 declarations, 14 classes, 43 ordered instances.
- **Frozen FNV:** `fnv1a64:10485782345918084284`.
- **Frozen SHA-256:** `sha256:37a8c7e027c548b59a82060556e194051867ee10d02e5b02b1f20c4875693ce5`.
- **Native closure:** 171 portable / 179 total Lean modules.
- **Runtime observations:** 206 shared cases, preserving the previous 198; direct JS, strict TS, Rust, Wasm GC and Wasmtime component gates passed.

Qualified additions: Prop-only Nat.le recursor; checked zero, successor,
transitivity, predecessor/inversion and impossible-zero proofs; checked
Nat.ble logical model; checked Boolean reflection; Nat.decLe/Nat.decLt
dictionaries. Decidable.intro and its computational projection now erase
consistently to Bool. The reflection field is erased, not trusted as an
unchecked witness. Runtime comparison keeps the existing Nat.ble intrinsic.

The same run checked the independent RC4 source oracle and false-bound
rejection, admitted source proofs with the official kernel, validated strict
IR and qualified emitted artifacts. This is **not a compiler correctness
proof or full M1 completion**. A single measured all-target application run
reported prelude 10 ms, parse 98 ms, elaborate 93 ms, prepare 297 ms,
kernel 66 ms, erase 112 ms and emit 455 ms; these are observations, not
controlled performance comparisons.

**Next M1 dependencies:** universe-polymorphic Option/GetElem?/laws and
universe-aware do binding; bounded proof-producing index automation; complete
List/Array/Fin indexing, optimized optional laws, coherent panic behavior and
representative performance comparisons. Full M2 tabling, C5, pskernel-core
and self-hosting remain excluded. Re-read live HEAD and CI before editing.
Do not repeat the older Decidable-uniqueness work: it was already qualified.


## Most recent qualified continuation (13 October 2026)

**Newest independently qualified executable:** [`e0ac8c69c928261e21e9593ed3f2f4aa5157385a`](https://github.com/dwijayuda/pskernel/commit/e0ac8c69c928261e21e9593ed3f2f4aa5157385a), Linux GitHub Actions [38335736466](https://github.com/dwijayuda/pskernel/actions/runs/38335736466) **passed** (13 October 2026). This supersedes older executable-status statements below, which remain as preserved history. The pinned upstream is Lean 4.35.0-rc4 (`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`). The selected Standard now contains **234 declarations, 14 classes, 40 instances**, FNV `fnv1a64:403111548970955669`, SHA-256 `sha256:6e6f1fad15d4f0cb401a09c1ebc219c3f60dd50acb21061ca9eee4ab782bd85e`; portable/native closure remains 170/178 `.lean` modules with 198 shared runtime observations on TS, direct JS, Rust, and Wasm GC/Wasmtime.

M1 gained the checked RC4 `Decidable`/reflection/`dite` representation and a typed, meta-closed Prop proof-irrelevance rule in `Ps.Meta.Unify`. The source oracle now checks `Decidable P → P ∨ ¬P` and `∀ (a b : P), a = b` with official Lean. **Still blocked**: the fully generic proof equating independent `Decidable P` dictionaries failed source dependent-elaboration; do not claim `LawfulGetElem` or add an axiom. The latest attempted theorem was replaced with the passing `psPropProofIrrelevance` case, with negative obligations preserved. Proceed M1-first: correct dependent reflection elimination / propositional decision-coherence, checked two-law optional dictionary, then List/Array/Fin indexing and universe generalization. Only then M2 generator/consumer waiter tabling; native `.lean` and GitHub Actions only. Older dates/SHAs below are historical.


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
