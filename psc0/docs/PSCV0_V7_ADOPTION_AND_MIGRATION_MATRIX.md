## Current integration candidate — exact choice foundation and P0 Nonempty fallback

The implementation now adds the exact pinned Lean 4.35.0 Classical.choice axiom and checked Classical.ofNonempty definition, and registers the existing Nonempty class. Nonempty/intro/rec are audited prerequisites, not duplicate new declarations. P0 first searches constructively for Inhabited, then uses independent Nonempty evidence only when required. The actual recursive source body remains separate from the opaque logical inhabitant.

The selected foundation is exactly propext, Quot.sound and Classical.choice. No further axiom, source axiom, proof hole or runtime choice intrinsic is added. Standard is 3635 declarations, 42 classes, 359 ordinary instances and 13 defaults, with explicitly reviewed pins observed in preparation runs 39064740499 and 39065744204.

This compiler/test revision is a candidate awaiting all five same-SHA gates. The new P0 source/body/native controls passed preparatory construction, official-kernel ordinary emission and exact verified refusals; its ten runtime comparisons must still execute in the focused gate. Last full acceptance remains e6b7f11750fdde6e1feacab86cfb32f2a82be8a5 and 960 comparisons. Do not claim 970 or new acceptance before completed logs.

The separate preparation branch now contains commit 5dd8ed9701b215bf808ea1e058e382b3f639710a and cloud run 39067140365: repaired generated-equation privacy, larger WF state, indexed BEq, checked P1 runtime ownership, the retained Order audit and portable monotonicity proof probes. Those changes are not included in this foundation-only integration and remain independently under qualification. Continue them while allowing the healthy Native gate to finish.

See [the current integration receipt](PSCV0_M3_CLASSICAL_P0_INTEGRATION_2026-10-18.md) and the existing six-exit M3+B ledger. M3+B remains open. Keep v7.2, pinned Lean, GitHub/cloud Linux only, fresh expected-HEAD/non-force updates and PR109 draft/open/unmerged on its original base. Historical sections below describe their original compiler identities and are superseded only where this current checkpoint says so.

---

# PSC0 — PSCV0 v7 adoption and source/self-host migration matrix

> **Measured v7 M1 checkpoint:** Full generated first `.ps` module bridge run [38120695522](https://github.com/dwijayuda/pskernel/actions/runs/38120695522) at source `8603f7dcf6af6295335c4e11912a10aac86c85a4` passed Linux/Windows 38 bridge + 12 authoring/arrow tests per platform, independent RC4 correspondence proof and ten checked/runtime fixture functions. This replaces the earlier 900-second-timeout status *for that exact source only*. The later v7-only parser-policy changes require their own generated CI before they inherit any qualification; full PSCV0 v7 and full compiler fixed point remain unproved.


**Review date:** 2026-10-11. **Status:** source-grounded *implementation plan* and reference adoption, NOT complete PSCV0 compiler conformance or verified executable certification.

The new authoritative language *design* is the complete [v7 document](../PSCV0_LANGUAGE_REFERENCE.md), byte-identical to the user's upload (308,462 UTF-8 bytes; SHA-256 `843940bd7f6a9b286e80b01d8c891a7e01b8868a9de7b05833fce32d49be6cd5`). Semantic upstream target: Lean `v4.35.0-rc4`, commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`. The prior `a419955383fd3e35d873f82c939ecf3a92dc65b162cc9d0d3cadf5b853a0f4b0` reference is historical. Earlier bridge tests remain evidence for the exact earlier selected syntax and code, not proof of unimplemented v7 features. ProofScript v7 is a **semantic subset of Lean**, with one source language and two *assurance outcomes*, not a new type theory or a JS compatibility mode.

## Implementation-oriented findings

| Selected v7 capability | What repository code/tests actually establish before v7 | Portable owner / increment / required evidence |
|---|---|---|
| `const`, `function`, `def`, `psFunctionBinders`, head-specific nullary `Unit`, interleaved telescope `BIND-02` | Bounded positive-arity functions/aliases, first authoring module; no general `function f()` completion/ordered binder conformance | `syntax` & `elab`; verify source-level head ownership, type-preserving desugaring and `def f()` refusal before claiming v7 |
| `APP-01..04`: adjacent comma calls, curried `f x y`, forbid application-continuation `f (x)`, mixed `f x(y)`, bounded `f()` | First bridge owns limited source-position call-gap syntax; empty-call completion unsupported, no general type-directed `Unit` insertion | Parser plus typed elaboration; compare exact AST application trees and Lean RC4 Core; negative diagnostics must fail at intended stage, not unrelated lexing |
| Retained high-level `do`, base/verified P0/staged P1 item union; `Except` semantics | First `declaration-except-do/1` bridge *boundedly generated*, first compiler `Translate.ps` uses four `do` bodies; no general class-monadic/loop/try/finally or verified erasure | `syntax`, `elab`, selected effect packages; maintain first-error/order/hygiene, no JS-only lowering; P1 needs explicit registered effect environment |
| `match` multi-discriminant/dependent, `if let`, `nomatch`, native pattern category and `k+1` | Old AST has one scrutinee and flat patterns; typechecking and structural-recursion infrastructure exists but no complete v7 source elimination | `syntax` & `elab`; typed motives/coverage and checked recursors; pattern grammar is separate from term comma calls |
| Native structures/records/update/projections, classes/instances, trailing deriving allowlist | Partial structures/named projection and internal class synthesis, not general source handler conformance | `syntax`, `meta`, `environment`, `elab`; no new kernel constructors or untrusted handler authority; frozen instances/deriving registries |
| List/Array/Option/Except, GetElem proof/Option/panic, raw/interpolated strings, `Empty`, `BitVec` | Runtime/data foundation partly present; no full source literal/instance/API coverage | source parser, `foundation`, selected `stdlib`; signed/width semantics and exact RC4 API/import snapshot, no JS indexing fallback |
| RC4 module mode, `public import`, public names but non-exposed bodies | Existing npm import/source graph does not imply RC4 module visibility or proof-spec export | `syntax` and `environment`; run two-module differential tests including `f.spec` without invented visibility outcomes |
| Lean proof/tactic goals, `Std.WP` `given/requires/ensures`, `assert`, `erased`, `where finally | spec` | Historical RC4 success for *one generated Except do fixture*; not the v7 compiler contract/tactic family | exact RC4 parsing/proof elab and checked kernel term, independent generated-spec/axiom/effect audit; no bare `verify` replacement |
| `axiom`, `partial`, `unsafe` source exclusion; emitted `sorryAx` prohibition, noncomputable proof-only | Current negative/source-gating tests cover narrow subsets, not every v7 transitive trust case | host + `compiler-ir`/`erasure` + checked admission; type/policy/axiom ledger; differentiate ELAB/VC-PROOF, KERNEL and ASSURANCE |
| Frozen Standard environment (operators, notation, instance priorities, tactics, derive handlers, imports, module exports, assumptions) | Lean source SHA pinned, but PSCV0 environment manifest/digest not built | `environment`; complete reproducible manifest and exact RC4 differential conformance gate are release blockers |

**An important distinction:** the new v7 rules are **requirements**, not a license to label current legacy compiler features as supported. The v7 reference's embedded positive/negative tables are specifications until converted into executable whole-fixture checks with exact error phases, pinned modules and admitted Lean counterpart. In particular, the RC4 `Std.WP` experimental effects are not presumed installed.

## Ordered milestones and evidence

**M0 — v7 reference authority (this commit):** put exact document in `psc0/PSCV0_LANGUAGE_REFERENCE.md`; pin 308,462-byte length, SHA-256 and Git blob in adoption and authoring manifests, portable constant and generated tests. Run cheap identity check before native preparation. Preserve old exact historical source/receipts. Do not change shipping grammar selection merely by changing metadata.

**M1 — first real PSCV0 module in generated bridge:** shared live preparation prefix, actual generated portable JS PSCV0 translator (never a native fallback), 20-module candidate, readable/lowered source views and their eight equations, two assumption-free algebra lemmas, unchanged 38 bridge generated tests, 36 old/new API comparisons, eight authoring tests, four arrow regressions, Windows tests and independent RC4 replay. Latest pre-v7 [run 38112642444](https://github.com/dwijayuda/pskernel/actions/runs/38112642444) passed native/generated source proof and materialization, then hit the 900-second explicit budget during candidate suffix preparation; it did NOT qualify M1. New 1600-second cap is a bounded resource policy change, not a success claim.

**M2 — next readable features:** choose incremental, *portable* grammar/typed lowering families that measurably simplify actual compiler source. Begin with helper reuse and source-preserving printing, then selective expected-type sugar, richer result projections/record updates, optional tuple and match families when their existing IR accommodates them. Comments/docstrings, naming and source spans must be faithfully preserved or migration must refuse. Do not duplicate grammar in optional plugin packages.

**M3 — authoritative full `.ps` source:** migrate representative compiler APIs/workers, then actual entire selected 64-module bootstrap closure; generate readable `.lean` projection from preserved surface nodes, with same checked semantics and new exact source-identity receipts. Preserve original handwritten Lean seeds as immutable recovery artifacts only.

**M4 — compiler-only qualification:** explicitly promote after C0→C1→C2→C3 source/admission/TS/JS parity and Linux/Windows negative/qualified runtime testing. Ordinary typechecking, kernel admission, policy-verified and executable semantics claims are **separate**. Never infer formal kernel consistency or backend correctness from a fixed point or finite corpus.

## Failure-phase and resource discipline

- **LEX/PARSE:** comment/gap `f /-gap-/ (x)` tests must reach actual `APP-02`, unlike invalid C-style comments; `variable (n:Nat)` must remain legal; `f x(y)` must bind to `x(y)`; `def f()`, comma-patterns and unregistered P1 do forms reject under their specific rule.
- **ELAB:** `f()` may only use defaults/automatics or a sole definitionally-`Unit` binder; do not guess required `Nat` or an unsolved metavariable.
- **ENV:** no silent import-driven tactic, deriving, effect or syntax registration. The exact RC4 and custom Standard environment identities are different objects.
- **ELAB/VC-PROOF:** unclosed contract goals are *not* failures of the kernel on a submitted term. **KERNEL** is reserved for actual invalid submitted proof/term; **ASSURANCE** additionally blocks incomplete verification, axiom, effect, erasure and emitted proof-hole closure.
- **Build resource:** native preflight first, preserved earlier checked compiler runtime, bounded generator with one prefix, one selected `.ps` module. A timeout is an incomplete result, not a reason to reduce semantic tests or repeat full kernel generation.

## Trust and package ownership

Preserve TS7.0.2 self-host bootstrap, the current modular twelve-source-package compiler closure and the existing host-owned checking/admission gate. Pure helpers are `foundation`, parsing/source-origin/printing are `syntax`, typing and sugar `elab`/`meta`/`environment`; the kernel checks independently and never trusts plugin decisions. Optional tactics, stdlib, backends, LSP and npm extensions must remain outside the mandatory closure until justified. Formal PSKernel Core metatheory and Lean 4.35 compatibility run in separate branches.

References: [v7 source](../PSCV0_LANGUAGE_REFERENCE.md), [adoption identity](PSCV0_REFERENCE_ADOPTION.json), [current work state](../AI_WORK_STATE.md), [older migration review](PSC0_PSCV0_SELFHOST_MIGRATION_REVIEW.md), [bridge validation](PSCV0_BRIDGE_VALIDATION.md), [architecture contract](PSC0_SOUNDNESS_SECURE_EXTENSIBLE_ARCHITECTURE.md).
