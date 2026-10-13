# Current work — M2 instance graph qualification pending (13 October 2026)

Replaced recursive active-cycle rejection with a bounded generator/consumer queue.
Source implementation and focused checks are committed for Linux native qualification;
do not treat them as qualified until the new run succeeds. See
[M2 design and boundaries](docs/PSCV0_M2_INSTANCE_GRAPH_2026-10-13.md).
M1's last green executable remains c00e146bd5c97788a4a6a39221849973aeafda84.

# PSCV0 v7 — Active AI work state and complete phase handoff

## Current roadmap integration — readable outputs (13 October 2026)

The [source, historical-branch and qualification audit](docs/PSCV0_READABLE_OUTPUT_AUDIT_2026-10-13.md) is now the
current output plan. JS/TS/Rust/WAT/WIT are implemented for the qualified native
subset; existing bounded Lean/PS printers and historical round trips are reusable,
but full C5 reconstruction is not implemented. Do not rebuild existing emitters
or merge unrelated historical backends.

M1 is complete at the executable/run below. Next: M2 + remaining A, then M3 + B,
M4 + C/D, and M5/E. Retain C5 source/binder/occurrence information alongside its
M2–M4 semantic owners; complete C5 source publication and correspondence under
M5/E after the required A–D language closure. This replaces the old blanket
C5-after-all-A–E scheduling rule. No new milestone track is added.

**Current code boundary:** the M2 waiter engine remains unimplemented; this
output audit is documentation, not a new executable qualification. No C5 source
emitter or source-authority migration was added. Native `.lean`, official checking,
GitHub source operations and Linux CI remain authoritative. No pskernel-core
or self-hosting; Wasm GC internally and linear memory only at explicit ABI boundaries.

## Current qualified state — M1 complete; M2 + A next (13 October 2026)

This section is authoritative for current status. Older sections below are
historical checkpoints; their pending-M1 statements are superseded.

- **Qualified executable:** `c00e146bd5c97788a4a6a39221849973aeafda84`.
- **Green Linux CI:** [38388627512](https://github.com/dwijayuda/pskernel/actions/runs/38388627512).
- **250 shared runtime observations**, four shared panic cases, official kernel,
  independent RC4 oracle, negative/coherence and all existing backend gates passed.
- **292 declarations / 14 classes / 52 instances**; **175 portable / 183 native modules**.
- FNV: `fnv1a64:5949916575031563783`.
- SHA-256: `sha256:f33d923e45baf8aa5dfa6755819737acabc09daf6d60934eb232133acaad069f`.

M1 acceptance, selected universe/proof-automation scope, runtime-override ledger
and measured compiler/runtime costs are recorded in
[M1 completion evidence](docs/PSCV0_M1_COMPLETION_2026-10-13.md). Generated JS still has substantial overhead
versus native Lean (roughly 492–3357x in these small batch measurements).
M1 completion does not establish performance parity, full M2/A/v7 completion,
or formal compiler semantic preservation.

**Accepted interleaving:** M2 with remaining A; M3 with B; M4 with C/D;
final M5/E qualification. Collect E evidence and apply measured M5 improvements
throughout. Next implement the shared instance-search architecture before
expanding the Phase A handlers that rely on it. Preserve native portable Lean,
official checking, GitHub source operations, Linux CI, branch/draft PR 109,
Wasm GC internals and explicit ABI-only linear memory. C5 is integrated as above; compiler-source migration,
pskernel-core and self-hosting remain deferred.

## Prior qualified checkpoint — M1 coherence and measurements (13 October 2026)

- **Executable:** `6a6037c311f306d82e43221ed527c7326e5785dc`.
- **Green Linux qualification:** [38387492672](https://github.com/dwijayuda/pskernel/actions/runs/38387492672).
- **246 shared runtime observations**, all prior observations retained, four panic
  contracts, official kernel/RC4 oracle and all backend gates passed.
- Standard remains **292 declarations / 14 classes / 52 instances** and
  **175 portable / 183 native modules**, with the Array checkpoint digests below.

Explicit high-priority custom optional dictionaries take precedence over the
generic default. Direct and Fin-adapted lawfulness refuse the deliberately
unlawful optional implementation. Independent RC4 negative cases passed.

Controlled samples now exist in the CI artifact's `m1-performance/` directory.
At 16/128 declarations, checked-index elaboration medians were 2/15 ms versus
1/2 ms for direct-return bodies under identical binder telescopes; prelude
admission was 8 ms. Phase timings are recorded separately.

Generated JS lookup/conversion costs are substantially above native Lean:
the first measurement shows roughly 451–3206x batch-time ratios across these
small operations. Array and List-head lookup remain roughly size-independent;
List-tail and conversion costs grow with size. This is evidence of significant
remaining runtime overhead, not high-performance parity or a formal complexity
proof. Native Lean uses a different runtime and optimized standard library.
Retain the raw samples, setup exclusions and checksums when comparing changes.
M5 should address shared calling conventions, specialization and allocation,
not add Standard-name-specific backend shortcuts.

**Final M1 qualification is still pending** for the runtime-override ledger and
remaining representation-boundary probes (partial conversions, Array elimination,
empty Fin access and position coverage). Tail benchmark repetitions are reduced
from 128 to 16 per sample to keep routine CI economical while retaining five
measured samples and matched native/JS workloads. This changes measurement
duration, not correctness or acceptance criteria.

## Prior qualified checkpoint — M1 checked Array and conversions (13 October 2026)

This section supersedes older implementation-status statements below.

- **Executable:** [af96aa405a2b2f94df9a5dada607b4fc455fc624](https://github.com/dwijayuda/pskernel/commit/af96aa405a2b2f94df9a5dada607b4fc455fc624).
- **Green Linux qualification:** [38386745772](https://github.com/dwijayuda/pskernel/actions/runs/38386745772), official Lean 4.35.0-rc4.
- **Selected Standard:** 292 declarations, 14 classes, 52 ordered instances; 175 portable / 183 native modules.
- **Frozen FNV:** `fnv1a64:5949916575031563783`.
- **Frozen SHA-256:** `sha256:f33d923e45baf8aa5dfa6755819737acabc09daf6d60934eb232133acaad069f`.
- **244 shared runtime observations** passed in JS, strict TS, Rust, V8 Wasm GC and the native Wasmtime component host. All prior 198 remain.
- Four shared panic contracts passed, including empty Array bang access.

Array now has a checked List-backed logical model, actual size bounds, proof
access, optimized optional/bang dictionaries and both checked lawfulness laws.
The seven previous selected Array primitive axioms are replaced by checked
logical definitions. Efficient backend intrinsics remain a separately audited
runtime boundary; kernel checking is not a proof of backend equivalence.

Explicit Array.mk/List.toArray conversion uses a typed sized builder with
prepared List metadata. Every backend allocates private array storage and
traverses linearly; no backend hardcodes List tags or copies each persistent
prefix. Array.toList uses a typed fold and checked reverse, also linear.
Persistent updates, oversized indices, Fin adapter behavior and Nat/Bool
conversion cases passed. Array and List remain selected Type-0 collections;
Option and generic indexing/adapters retain the qualified universe closure.

**M1 remains incomplete pending final evidence:** explicit adverse-dictionary
coherence/priority checks and representative compiler/runtime performance
comparisons. Full M2 begins only after M1 acceptance, then interleaves with A.
No C5, self-hosting or pskernel-core.

## Active execution plan — accepted by the user

M1 is complete at c00e146b / Linux 38388627512. Continue M2 with remaining A,
M3 with B, M4 with C/D, and final M5/E. Collect E evidence and measured M5
improvements throughout. Preserve native Lean, official checking, GitHub-only
source operations, Linux qualification, branch history and draft PR 109.

M2's next coherent change is answer-tabled generator/consumer search replacing
active-key cycle rejection. Preserve candidate/local priority, post-selection
outParam reconciliation, context rollback, scope-safe checked answer replay and
bounded resource accounting. Current closed-answer memoization and Pi evidence
are qualified, but waiter tabling is not implemented. Study the pinned
Lean/Meta/SynthInstance.lean reference and whole affected elaboration subsystem
before changing search. Generalized answers/universes and delayed expected-type
constraints remain full M2 obligations; a closed-answer graph alone is not M2.

As M2/A develops, retain the exact binder groups, resolved references, default/
implicit decisions and source occurrence relations needed by C5. Extend the
existing syntax/provenance owner, not kernel expression identity. Match/data
retention follows M3/B; effects/spec/proof retention follows M4/C-D. M5 finishes
readable PS/Lean reconstruction with E correspondence after those semantics exist.
Existing JS/TS/Rust/WAT/WIT grow through their current checked plans.

See [output audit and milestone placement](docs/PSCV0_READABLE_OUTPUT_AUDIT_2026-10-13.md). The historical
five-source closure is confirmed green at 0e8996d2 / Linux 38134451122, but remains
bounded prior source-product evidence. Do not run that self-host pipeline or
promote its source manifest in the current native loop.

## Prior qualified checkpoint — M1 List/Fin indexing (13 October 2026)

This section supersedes older checkpoint claims below.

- **Executable:** [e73ce2bbff522e5888a409b7b114042877d71943](https://github.com/dwijayuda/pskernel/commit/e73ce2bbff522e5888a409b7b114042877d71943).
- **Green Linux qualification:** [38384869133](https://github.com/dwijayuda/pskernel/actions/runs/38384869133), official Lean 4.35.0-rc4.
- **Selected Standard:** 277 declarations, 14 classes, 49 ordered instances; 173 portable / 181 native Lean modules.
- **Frozen FNV:** `fnv1a64:1660797324209886684`.
- **Frozen SHA-256:** `sha256:1937840a8a4fda1612e3e03e17860b4abad97b355beb6a896eee4c2171abbb3d`.
- **227 shared runtime observations** passed in direct JS, strict TS, Rust, V8 Wasm GC and the native Wasmtime component host. All prior 198 observations remain.
- Three panic cases passed in JS/TS/Rust and V8/Wasmtime core/component execution.

Qualified: checked Fin structure and original-predicate-preserving Nat-to-Fin
index adapters; List proof/automatic/optional/bang access; both List lawfulness
proofs; matching Fin adapter lawfulness. Optional List access uses a single
structural traversal, without a preliminary length pass. The official kernel
accepted every added logical definition. The pinned source oracle, negative
invalid-bound cases, strict IR and existing integration gates passed.

One family-parameter classification now erases numeric datatype parameters
without erasing ordinary computational Nat function arguments. List.get's Fin
value survives while its bound proof does not. A Fin bound does not authorize
access to a smaller collection. The selected List universe is still Type 0;
Option and generic Fin adapters retain their qualified universe parameters.

**M1 remains incomplete.** Next: checked Array logical model, genuine size-bound
indexing, explicit linear-time logical/runtime conversions, alias/large-index
coverage, and controlled representative performance comparisons. Full M2 starts
after M1 acceptance, interleaved with feature A as the user requested. C5,
pskernel-core and self-hosting remain excluded.

## Prior qualified checkpoint — M1 universes and bounded index proofs (13 October 2026)

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


## LATEST QUALIFIED M1 FOUNDATION — 13 OCTOBER 2026

**Newest independently qualified executable:** [`e0ac8c69c928261e21e9593ed3f2f4aa5157385a`](https://github.com/dwijayuda/pskernel/commit/e0ac8c69c928261e21e9593ed3f2f4aa5157385a), Linux GitHub Actions [38335736466](https://github.com/dwijayuda/pskernel/actions/runs/38335736466) **passed** (13 October 2026). This supersedes older executable-status statements below, which remain as preserved history. The pinned upstream is Lean 4.35.0-rc4 (`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`). The selected Standard now contains **234 declarations, 14 classes, 40 instances**, FNV `fnv1a64:403111548970955669`, SHA-256 `sha256:6e6f1fad15d4f0cb401a09c1ebc219c3f60dd50acb21061ca9eee4ab782bd85e`; portable/native closure remains 170/178 `.lean` modules with 198 shared runtime observations on TS, direct JS, Rust, and Wasm GC/Wasmtime.

**Implemented and checked:** In `packages/environment/src/Ps/Environment/Decision.lean`, `Decidable` is now a checked Bool-plus-reflection structure with checked `Bool.Reflects`, `isTrue`/`isFalse`, projection definitions and reducible proof-aware `dite`. In `packages/meta/src/Ps/Meta/Unify.lean`, equality checking recognizes proof irrelevance **only** for explicitly inferred, fully resolved inhabitants of definitionally equal propositions of sort `Prop`; unresolved metavariables fail closed. Native proof acceptance now covers a real `Decidable P → P ∨ ¬P` theorem and the general `(a b : P) → a = b` principle. Official kernel, erasure, IR and all established targets remained green.

**Not claimed:** This does *not* constitute a proof that **two independent `Decidable P` dictionaries are equal**. The stronger attempted theorem failed dependent application elaboration (even though direct proof irrelevance is checked); the test was not retained as accepted. Thus NO generic `LawfulGetElem` instance was admitted. Actual List/Array/Fin proof-carrying indexing, universe-polymorphic `Option`/`GetElem?`, and additional tactics remain unfinished. M2 waiter/generator/consumer tabling is **unchanged and unfinished**. Diagnose dependent reflection elimination and prove coherence in checked Core first; only then install the two-field lawful dictionary. Historical notes below refer to older qualified branches/commits.


**Handoff refreshed 13 October 2026 (Asia/Jakarta).** GitHub branch was verified at documentation-only commit `b57849d2b7fe30c9e9da448568f0d2bbb50c1f79`; the current document update will advance HEAD again. Compare `fc8bc8b1f16ed993fb144e2d396c0760c068630b...b57849d2b7fe30c9e9da448568f0d2bbb50c1f79` reported **five commits changing documentation only**. **Latest independently CI-qualified executable remains `fc8bc8b1f16ed993fb144e2d396c0760c068630b`, Linux [38323422371](https://github.com/dwijayuda/pskernel/actions/runs/38323422371), passed.** In the next chat, re-read HEAD and CI and do not confuse documentation commits with executed acceptance.

## NEW CHAT: AUTHORITATIVE M1 → M2 HANDOFF (13 October 2026)

**Working branch:** `psc0/pscv0-v7-native-lean-v1` · draft PR [#109](https://github.com/dwijayuda/pskernel/pull/109). **Live HEAD at this handoff preparation:** `216ac7770c8b6c16fca9cb22ca3a1fc87a7f7ea1` (documentation-only since the checked source below); **always re-query GitHub** because this handoff itself creates another documentation commit. Do **not** treat a documentation HEAD as a newly qualified executable.

**Exact last GREEN executable:** [`fc8bc8b1f16ed993fb144e2d396c0760c068630b`](https://github.com/dwijayuda/pskernel/commit/fc8bc8b1f16ed993fb144e2d396c0760c068630b), [Linux GitHub Actions **38323422371**](https://github.com/dwijayuda/pskernel/actions/runs/38323422371) — passed. Upstream Lean **4.35.0-rc4** at `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`; **170 portable / 178 native `.lean` modules**, **198 shared runtime observations** (TS, direct JS, Rust, and V8 Wasm GC/Wasmtime workflow); selected Standard **230 declarations, 14 classes, 40 ordered instances**, FNV `fnv1a64:17137083495666611555`, SHA-256 `sha256:b0ddaa7acc463b9457aac13bd8f08a2f6f8e64bba32b76f7e469ebf1a973f08f`.

**M1 QUALIFIED SUBSET, NOT COMPLETE:** Core `GetElem` with real proof obligations, erased dependent validity predicates, selected Type-0 `GetElem?` and superclass, low-priority default optional instance from an actual `GetElem` dictionary **plus `∀ xs i, Decidable(valid xs i)`**, checked `Decidable True/False`, optional successes and `none`, and target-runtime nonreturning `outOfBounds` panic (though definitional `default` for proof reasoning). **Lawfulness blocker is fundamental:** `LawfulGetElem` is a real checked proof class with two equality fields, but the **generic instance was NOT admitted**. The independent `Decidable` parameter quantified in the law cannot be equated to the closed-over dependent decision function by `rfl`; official Lean correctly rejected that attempt. Need a genuine propositional coherence proof (likely sound `Decidable` subsingleton/irrelevance), or stay unproved. Also need faithful List/Array/Fin index propositions and checked lawful instances, selected Option/universe generalization, and more proof-producing `get_elem_tactic`.

**M2 QUALIFIED SUBSET, NOT COMPLETE:** Native `Ps.Meta.SynthInstance` has one clean checked priority solver, per-invocation positive-answer table keyed by resolved full goals, witness re-inference + unification before reuse, snapshot rollback and local scope isolation, dependent Pi synthesis, postponement until input meta constraints are ready, independently bounded **4096 goal visits / 4096 candidate checks**, fail-closed exhaustion. Missing **Lean's actual generator/consumer suspended waiter graph and recursive answer propagation**, full expected-type/universe/synthetic-mvar scheduling, well-designed cross-scope goal normalization, and measured Lean parity.

**Continuation order:** Read `psc0/AI_CONTINUE_PROMPT.md` and [M1/M2 audit](docs/PSCV0_M1_M2_IMPLEMENTATION_AUDIT_2026-10-13.md). (1) M1 proof-theoretic lawfulness, real collection indexing, Type-0 limitation, negative/panic path. (2) M2 true tabled recursive waiters and coherent constraint engine. (3) Minimal targeted tests first and existing official Lean + JS/TS/Rust/Wasm GC/Wasmtime CI at **architectural** milestones. Update exact SHA/CI, frozen environment digest, roadmap and evidence after each qualified change. **Full M1, M2, v7, Lean performance parity and verified emission remain open.**

**Keep:** native portable `.lean` only; official Lean checker; approved selected trust/prelude; fail-closed proofs, erasure, strict IR and runtime; GitHub-first and Linux CI. **Do not** integrate pskernel-core, C5, self-hosting, compiler-source `.ps` migration or Desktop Commander; do not force push, merge or delete branches. Work systematically and fix architectural root causes, not isolated test failures. Historical milestone paragraphs below are not current. Ready-to-paste new-chat instructions are committed at [`psc0/AI_CONTINUE_PROMPT.md`](AI_CONTINUE_PROMPT.md).

---

**Date:** 13 October 2026 · **Status:** implementation in progress, NOT full v7 conformance.
**Repository:** https://github.com/dwijayuda/pskernel
**Working branch:** `psc0/pscv0-v7-native-lean-v1`
**Existing draft PR:** https://github.com/dwijayuda/pskernel/pull/109
**Last qualified EXECUTABLE source commit:** `fc8bc8b1f16ed993fb144e2d396c0760c068630b`
**Qualified Linux CI:** https://github.com/dwijayuda/pskernel/actions/runs/38323422371 — all jobs passed.
**Documentation-only branch checkpoint before this handoff:** `216ac7770c8b6c16fca9cb22ca3a1fc87a7f7ea1`; not an executable qualification.
**Official checker:** Lean `4.35.0-rc4`, upstream SHA `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.
**Source qualification profile:** `pscv0-v7-native-bounded/48`. Profile 49's module foundation is not a claim of completed language conformance.
**Canonical language spec:** `psc0/PSCV0_LANGUAGE_REFERENCE.md`; follow its stated RC4 semantics, restrictions and phase-sensitive refusals.
**Dependency roadmap:** `psc0/docs/PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md` (now includes the complete Phase A–E plan).
**Standard snapshot details:** `psc0/docs/PSCV0_STANDARD_SNAPSHOT_V1.md`.
**Ready-to-paste continuation:** `psc0/AI_CONTINUE_PROMPT.md`.

## Latest qualified M1/M2 architecture milestone — 13 October 2026

**Qualified executable:** [`fc8bc8b1f16ed993fb144e2d396c0760c068630b`](https://github.com/dwijayuda/pskernel/commit/fc8bc8b1f16ed993fb144e2d396c0760c068630b), [Linux Actions 38323422371](https://github.com/dwijayuda/pskernel/actions/runs/38323422371) — **PASSED** official Lean and the established JS/TS/Rust/Wasm GC/Wasmtime integration.

- **M1 default indexing:** A **low-priority checked GetElem? instance** now follows from a kernel-checkable `GetElem` dictionary plus a real dependent `forall xs i, Decidable (valid xs i)` function. New `Decidable True` and `Decidable False` instances are ordinary checked source declarations. No Bool-as-Prop shortcut. Selected `GetElem?` still restricts elements to Type 0 until Option/universe generalization.
- **M1 runtime:** Selected optional success, bang success and optional failure (`none`) pass the same runtime matrix. The existing `outOfBounds` term reduces to `Inhabited.default` for kernel proofs but explicitly produces a typed panic in executable JS/TS/Rust/Wasm GC; both success and failure runtime behavior had independent qualified tests in earlier `f6afea5`-ancestry CI.
- **M1 lawfulness honesty:** The checked `LawfulGetElem` class remains with mandatory two equality proofs; **no general automatically synthesized LawfulGetElem proof was admitted**. A proposed `Eq.refl` instance was rejected by the official kernel because the default implementation captures a dependent decision procedure while the law quantifies over an independent Decidable dictionary. The proposal was withdrawn with history preserved, not turned into an axiom. A correct proof requires propositionally reconciling those dictionaries (e.g. through genuine Decidable subsingleton/constructor reasoning).
- **M2 solver:** Scope-isolated positive-answer memoization and proof-witness revalidation remain. The sole candidate engine now tracks **4096 goal visits and 4096 candidate attempts independently**, makes resource exhaustion fail closed, and postpones dependent dictionary subgoals until their class inputs are known. A nested Pi-indexed synthesis retains its resource accounting without reusing local-context answers. Obsolete duplicate candidate-solving code was removed. Complete Lean generator/consumer waiter tabling is still outstanding.
- **Exact selected Standard:** **230 declarations, 14 classes, 40 registered instances**. FNV `fnv1a64:17137083495666611555` and SHA-256 `sha256:b0ddaa7acc463b9457aac13bd8f08a2f6f8e64bba32b76f7e469ebf1a973f08f`. These identify the *selected prelude*; they are not whole-compiler proofs or full Lean Standard closure.
- **Evidence:** **198 shared runtime observations** passed TypeScript, direct JavaScript, Rust, V8 Wasm GC and native Wasmtime/component workflows, plus checked source/refusal suite and 170 portable/178 native Lean closure modules. This is bounded acceptance, NOT full M1, M2, v7, metatheory or Lean performance parity.
- **Next:** finish genuine lawfulness proofs and List/Array/Fin bounds, explicit general panic/Option universe closure, true cyclic tabled generator/consumer scheduling and reproducible solver/runtime benchmarks. Keep entirely native .lean; no pskernel-core, C5 or self-hosting.

### Prior M1/M2 implementation checkpoint (historical)
## M1 selected optional indexing and M2 answer-table solver — qualified 13 October 2026

**Latest qualified executable:** `f8900407eaaa921097e6cd49d58551ca6558ed96`, [all-green Linux 38315275940](https://github.com/dwijayuda/pskernel/actions/runs/38315275940). The native compiler still uses **170 portable / 178 native Lean modules**, no pskernel-core or self-hosting. The selected Standard is **221 declarations, 13 classes, 37 instances**, frozen at FNV `fnv1a64:4160132988510892817` and SHA-256 `sha256:a02c9f39e6de1830497114edfaad5e9bdd5730110b562585e3f6ecc30b80b6d3`. **194** shared JS/TS/Rust/Wasm-related observations passed, including selected `xs[i]?` and `xs[i]!` dispatch on a user-defined lawful-total-in-practice collection.

- **M1 implemented (bounded):** a genuine checked `GetElem?` data/class family with `toGetElem` superclass, optional method and bang method (currently selected `Type 0` elements). User-supplied positive methods pass official checking, erasure, multi-target artifact emission and runtime observations. `Ps.Compiler.Api` now derives internal Standard export names from the canonical runtime-prelude closure, eliminating a duplicate symbol inventory. The existing `GetElem` side-condition/refusal still holds.
- **M1 NOT complete:** general universe-polymorphic `Option`, default decidable optional lookup, `LawfulGetElem` proofs, true List/Array/Fin bounds, and mandatory `getElem!` out-of-bounds **panic** remain. The qualified bang sample only covers an in-bounds value and cannot stand as panic parity evidence.
- **M2 implemented (bounded):** `Ps.Meta.SynthInstance` now maintains a per-invocation positive answer table keyed by fully resolved goals, re-checks reused witnesses by inference and unification, shares successes through postponed dictionary-dependency passes, preserves priorities/snapshot rollback, and enforces a total-visit cap plus depth fuel. Native memo test passed with initial one expansion and zero additional expansion on reuse.
- **M2 NOT complete:** Lean's generator/consumer waiter graph, general cyclic tabled resolution, complete universe/expected-type constraint scheduling, and comparative performance benchmarks are pending.
- **Exact detailed report:** [`PSCV0_M1_M2_IMPLEMENTATION_AUDIT_2026-10-13.md`](docs/PSCV0_M1_M2_IMPLEMENTATION_AUDIT_2026-10-13.md). Continue M1's semantics and M2's full solver architecture from this accepted source; never weaken kernel, IR, assumption or proof gates.

## Qualified M0 architecture and five-target indexed runtime milestone — 13 October 2026

**Latest green executable:** `a678594001d94c9aaade968ce951f44e1e66ba81`, [Linux 38312162188](https://github.com/dwijayuda/pskernel/actions/runs/38312162188) — **PASSED**, including official Lean 4.35.0-rc4 validation and the full existing cross-target CI. All changes are native portable `.lean` (plus test fixtures), no pskernel-core, self-hosting or C5 changes.

- **M0 checked dependent-erasure redesign complete for selected indexing:** `Ps.Erasure.Basic` now classifies `.type` (runtime-reifiable generic), `.index` (erased higher-kinded or Prop-valued dependent index), `.proof`, and `.runtime`. The same original Core parameter-position masks are used to construct the reifiable class/inductive/structure IR types and to lower applications, constructors, recursors, dictionary projections, lambdas and definitions. The checked `GetElem.valid : coll → idx → Prop` does not become an `.unknown` IR type. `Ps.CompilerIr` still **rejects** `.unknown` runtime annotations. Unqualified type-level constructor fields remain fail-closed.
- **Native source oracle and code emission:** the pinned official Lean `Pscv0GetElemOracle.lean` compiles; the PSCV0 checked `GetElem` source with `i=0`, `True` and `True ∧ True` yields JS/TS/Rust artifacts, while invalid proof is refused. Added negative invariant that `GetElem` source parameter 3 (validity predicate) does not leak as an IR type: retained original source indices **[0,1,2]**.
- **Runtime verification, not just emission:** expanded the *same* JS/TS/Rust/Wasm GC/Wasmtime shared runtime observation table from **187 → 192**, with five genuine proof-carrying dictionary cases: implicit rfl, explicit proof, local assumption, `True` and `True ∧ True`. CI reports **192** passed TypeScript, direct JavaScript and Rust observations; generated Wasm GC observation wrappers, module execution and Wasmtime component-host also passed. No general dependent runtime preservation theorem or cross-language performance parity is claimed.
- **Selected Standard unchanged:** **215 declarations, 12 classes, 36 ordered instances**, FNV `fnv1a64:2902463666082847583`, SHA-256 `sha256:9c865069b931ad1bb44a9c4861cb9748964c99368d3a7e2c4f2c75e5a099d265`. These hashes protect the selected Core environment payload, not the entire compiler/backends/assumptions.
- **Next feature work:** complete faithful `GetElem?`/decidability/lawfulness, List/Array/Fin bound proofs, exact `!` panic semantics and more automation; then tabled typeclass search, dependent recursion, class-driven typed effects, contracts/VCs and full verification-gated emission. `psc0/docs/PSCV0_NATIVE_LEAN_GRADE_ARCHITECTURE_REDESIGN_V1.md` is the current architectural target. Do not claim all Phase A–E or Lean parity.

## Historical source architecture audit — 13 October 2026 (the failing checkpoint was resolved)

- **Audited source branch HEAD:** `1cc7deb56b2b6ec37ee3a6c1eac148d113899ac7`; [Linux 38307096314](https://github.com/dwijayuda/pskernel/actions/runs/38307096314) **FAILED** at `ir/emit` with `unknown-type` dependent `GetElem` annotations. The official Lean source oracle did compile. **Last green executable SHA remains `e1d463e10cbf5edd817e362ed35b21ee82c8c85b`**, [Linux 38304955212](https://github.com/dwijayuda/pskernel/actions/runs/38304955212). The audit is not an executable qualification.
- **Detailed Lean RC4 vs PSCV0 review:** [`psc0/docs/PSCV0_V7_LEAN435RC4_SOURCE_ARCHITECTURE_REVIEW_2026-10-13.md`](docs/PSCV0_V7_LEAN435RC4_SOURCE_ARCHITECTURE_REVIEW_2026-10-13.md). Root cause family: dependent predicate/type-level indices are being converted into IR `.unknown` runtime type arguments; IR correctly rejects them. Fix binder-kind erasure uniformly across declarations, calls, dictionaries and backends; never loosen validator.
- **Priority:** complete checked dependent erasure and emitted user `GetElem` parity; then `GetElem?`, lawfulness and List/Array/Fin validity, typeclass resolution and closure. Maintain all Phase A–E honesty and existing restrictions.

## Verified current baseline — what actually passed

- Native, portable `.lean` compiler with **170 portable / 178 native Lean modules**, with no pskernel-core integration or compiler-source self-hosting.
- **192 shared runtime observations** qualified through direct JavaScript, strict TypeScript, Rust, V8 Wasm GC and Wasmtime component/core execution; existing multi-module checking, linking, entry-only exports and original-file provenance passed.
- **Four checked semantic programs and 92 phase-specific refusals**, plus the bounded lexical/module/do/Standard and negative-regression cases. These counts are qualification cases, NOT a coverage percentage.
- One official-Lean-admitted prepared Core graph shared through checking → typed erasure → complete target-neutral IR validation → JS/TS/Rust/direct Wasm and Component emission. Preserve proof, assumption, type and source/provenance boundaries; do not substitute a fallback checker.
- Selected modules: public/private declarations, re-exports/diamonds, dependency ordering, opaque imported definitions versus exposed abbreviations, module-local private names, executable library closure.
- Selected source and Standard: `const`/`function`, native theorem/proof and typed programming subset, raw strings, `s!"..."`, grouped/radix numerals, List/Array literal subset, checked `BEq`, `ToString`, `Inhabited`, selected checked deriving `Inhabited`/`BEq`, approved `Option`/`List`/`Except` operations, selected typed `do` and recursion.
- Reproducible, length-delimited selected `Ps.Environment.StandardSnapshot`: **215 installed declarations; 12 registered classes; 36 ordered instance entries**, now pinned by **`fnv1a64:2902463666082847583`** and **`sha256:9c865069b931ad1bb44a9c4861cb9748964c99368d3a7e2c4f2c75e5a099d265`** over the same canonical UTF-8 payload. FNV remains a noncryptographic drift check; portable SHA-256 adds collision-resistant integrity, not complete Lean RC4 environment closure, a consistency proof, a proof certificate, or an approved supply-chain root. Reviewed roster changes require both expected hashes to be explicitly updated.
- Linux executable milestone `03ea9ac5` qualifies the **212-declaration** selected Standard gate and checked `List.take`/`List.drop` under Linux run [38296669991](https://github.com/dwijayuda/pskernel/actions/runs/38296669991). SHA-256 known-answer vectors and mismatched-digest/alias refusal passed at `381ae99f`, [Linux 38295808926](https://github.com/dwijayuda/pskernel/actions/runs/38295808926). Initial SHA-256 implementation passed at `2a75d31c`, [Linux 38295519668](https://github.com/dwijayuda/pskernel/actions/runs/38295519668). The original pinned FNV gate at `c810d6fe`, [Linux 38292170524](https://github.com/dwijayuda/pskernel/actions/runs/38292170524), remains historical. Intermediate roster-drift runs `1218a81e` and `8051fdf2` deliberately failed closed until reviewed hashes were repinned.

## Newly qualified Phase A checkpoints — 13 October 2026

- **Native selected Standard digest:** checked and pinned portable SHA-256 in `Ps.Environment.StandardSnapshot`, with the existing canonical serializer, exact-declaration audits, published test vectors (including UTF-8), and mandatory FNV + SHA-256 drift refusal. Current 212/11/36 roster: FNV `fnv1a64:9152255662807064572`, SHA-256 `sha256:13e7007c324ca40d0d871d2bc4856084796dd451891d7a0096216e94197b211e`. No external crypto service, unchecked FFI or new trusted kernel primitive was added. This protects integrity of the *selected* payload only. The complete import/notation/coercion/deriving/tactic/effect/axiom closure and independent supply-chain attestation remain unresolved.
- **Native checked collection APIs:** added `List.take(count, xs)` and `List.drop(count, xs)` as ordinary recursor-backed definitions with source tests that prove zero-count, in-range and beyond-length results by kernel-checked `rfl`. These source programs passed official admission and emitted JS/TS/Rust artifacts in the existing native integration test. The existing shared 187-observation execution regression across JS/TS/Rust/Wasm remained green; do not count new API-specific Wasm runtime parity as independently proven until added to the shared observation corpus.
- **Qualified executable SHA and CI:** `03ea9ac53664ce0c9b45ee4b23b09c284bf01264`, [Linux Actions 38296669991](https://github.com/dwijayuda/pskernel/actions/runs/38296669991) — passed. Source remains entirely portable native `.lean` and PR #109 remains draft.
- **Production integrity fail-closed:** commit `748a4fb216cebde4feb155946fed574a9fde4a5f`, [Linux 38297363372](https://github.com/dwijayuda/pskernel/actions/runs/38297363372) — **PASSED**. `psCompilerValidatePscv0Standard` now gates direct single-module compilation and multi-module preparation; the native host also checks once before batch preparation and emits a `prelude` diagnostic for registry drift. This makes FNV+SHA-256 expected values enforced on the actual native production admission paths, not only in the test harness. This is distinct from outstanding verified-emission proof/assumption/effect closure.

- **Phase A not complete:** the native `GetElem` class and a bounded proof-producing solver are qualified for user-defined instances, but **`GetElem?` is not yet installed**; selected built-in List/Array/Fin instance proofs, full Lean index automation (`omega`/`simp`/extensions), `LawfulGetElem`, panic/default semantics, collection and numeric APIs, and the full Standard/assumption manifest are still open. Phases B–E and verified-emission obligations remain open.

## RC4 GetElem study and new checked indexing milestone — 13 October 2026

- **Official reference reviewed:** pinned Lean [`Init/GetElem.lean`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Init/GetElem.lean), [`Init/Tactics.lean`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Init/Tactics.lean), [`Init/Data/List/Basic.lean`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Init/Data/List/Basic.lean), and [`Init/Data/List/Impl.lean`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Init/Data/List/Impl.lean). See `docs/PSCV0_GETELEM_RC4_DESIGN_AUDIT.md` for exact parity and performance gaps; do not treat this bounded milestone as equivalence to all of Lean.
- **Faithful class core:** `Ps.Environment.StandardGetElem` installs `GetElem` with three universes, correct explicit class telescope, `outParam` output slots for element and validity predicate, `Prop`-valued index validity, and a dictionary method requiring an actual proof. No Boolean index check is accepted as a proof, no separate kernel, no new trusted primitive. Existing source spells `xs[i]`, `xs[i]'h`, `xs[i]?`, `xs[i]!` parse, but `?`/`!` *elaboration and runtime contracts are pending*.
- **Dependent elaboration:** inserted targeted pending dictionary resolution before dependent explicit proof arguments. `GetElem` subclasses and custom validity propositions are resolved by the ordinary class engine, not by parser hardcoding.
- **Proof search:** synthesized `xs[i]` uses a kernel-checked, bounded `get_elem_tactic` analogue. This tries local assumptions/reflexivity and recursively closes every constructor-generated subgoal; failed branches do not retain assignments or admit unsolved proof terms. Checked positive cases include local validity evidence, explicit `'h`, closed equality, `True` and `True ∧ True`; invalid indexing is refused during elaboration. Arithmetic `omega`, extensible `simp`, and general built-in indexing remain pending.
- **Exact qualified source:** `e1d463e10cbf5edd817e362ed35b21ee82c8c85b`, [Linux Actions 38304955212](https://github.com/dwijayuda/pskernel/actions/runs/38304955212) — passed. Source closure: **170 portable/178 native Lean modules**; selected Standard: **215 declarations, 12 classes, 36 instances**; **187 existing shared observations** passed on JS/TS/Rust/Wasm. FNV `fnv1a64:2902463666082847583`, SHA-256 `sha256:9c865069b931ad1bb44a9c4861cb9748964c99368d3a7e2c4f2c75e5a099d265`. Neither new `GetElem` operation performance nor built-in collection index parity has been benchmarked.

## Full execution phases — one integrated dependency-driven plan

**Phase A — Standard environment, everyday language and P0 library closure (IN PROGRESS).**
1. **GetElem class and bounded proof search qualified:** next complete `GetElem?` with the real Lean superclass relationship, `Decidable`-derived optional access, `LawfulGetElem`, and panic/default semantics, then prove selected List/Array/Fin instances using actual `i < length/size` propositions. All four `xs[i]` spellings parse; `?`/`!` are not yet complete APIs. `List.get?` is not full GetElem. Examine `src/Init/GetElem.lean` at the pinned upstream SHA. No unchecked indexing or Bool comparison masquerading as a proof.
2. Finish the *fixed trailing deriving allowlist* `Inhabited`, `BEq`, `DecidableEq`, `Repr`, `Hashable` for selected structures/inductives, including generic/recursive cases where actually supported, checked generated instances, collision rules, origin retention and exact handler registration. Reject unknown/standalone deriving and unsupported handlers rather than fabricating instances.
3. Close `Float`/`Float32`, scientific/typed numeric literals, fixed-width integers, `BitVec` and conversions with exact RC4 semantics; complete viable List/Array/ByteArray/Option/Except APIs and curated P0 formatting/encoding. Distinguish real user APIs from merely declared type names.
4. Finish module and instance priority/import-order rules and a **cryptographically pinned** environment/notation/deriving/import/tactic/effect/assumption manifest that includes the selected closed Standard signature and provenance. Current selected FNV/SHA-256 snapshot remains only an intermediate integrity guard; the full environment and assumption closure is not frozen.
**Phase A exit:** each required P0 form is admitted/refused at the correct phase, generated Core is officially checked, selected APIs execute across the current backend matrix, and the final pinned Standard closure is reproducible.

**Phase B — Dependent data, elimination, totality and recursion (PLANNED).**
1. Finish dependent pattern matrices, heterogeneous/index equality and impossible branches, motive elaboration, named discriminants, dependent/existential/proof fields, nested/mutual inductives, strict positivity and recursor formation.
2. Finish source mutual recursion and well-founded recursion with precise structural/decreasing obligations. Preserve totality: no silent `partial`, `unsafe`, unproven termination or unsound recursion shortcuts.
3. Carry dependent data/recursor/runtime layout and proof erasure through the shared checked IR, including JS/TS/Rust/Wasm GC and cross-module linking.
**Phase B exit:** all selected v7 data/termination forms produce well-typed checked Core and preserve computational behavior; invalid recursion/index proofs are refused.

**Phase C — Generic typed `do`, effects, state and control (PLANNED).**
1. Generalize the class-driven `pure`/`bind`/map/Except/State/Reader and relevant transformer behavior instead of a per-syntax monad special-case path. Implement selected mutable/erased state, loops, early return, matching/binding, `throw`, `try`/`catch`/`finally` and effectful control under the RC4 contract.
2. Separate pure/replayable checked semantics from external `IO`/FFI/files/network/time/random/task boundaries. Explicit capability and effect identities must be reflected in assurance/target emission.
3. Lower structured control once into checked Core and shared IR, then qualify identical observable behavior in admitted JS/TS/Rust/Wasm targets.
**Phase C exit:** correct typed sequencing, recovery and state semantics with no undocumented JS-style exception behavior or lost erasure/effect obligations.

**Phase D — Proof-producing tactics, contracts, VC generation and verified builds (PLANNED).**
1. Expand selected native proof-goal control and checked tactics (`exact`, `refine`, `intro`, `cases`, `induction`, `rewrite`, selected `simp`/`omega`/`grind` where pinned/implementable). Tactics produce proof terms; only official Lean checking accepts them.
2. Implement exact RC4-origin experimental `given`/`requires`/`ensures`, `assert`, loop `invariant`/`decreasing`, `erased`, selected `Std.WP`/`vcgen` obligations and `where finally | spec` proof attachment. Keep obligations and failure phases explicit.
3. Build the **assurance ledger** for specification coverage, admitted assumptions/axioms, effects, holes/`sorryAx`, unsafe/partial constructs, termination, erasure and foreign-data validity.
**Phase D exit:** **a verified executable build emits no artifact while any mandatory proof, specification coverage, effect, assumption, termination or erasure obligation remains unresolved.** Ordinary checked outputs and verified outputs have distinct honest evidence claims, never separate logics.

**Phase E — Full core/essential v7 conformance, evidence and integration closure (PLANNED).**
1. Build the reference-rule → `PS-CONF-*` positive/negative acceptance/phase matrix for all mandatory P0/P1-selected core features. Differentially compare emitted Core/meaning with pinned Lean 4.35.0-rc4, not green test count or a speculative score.
2. Freeze/audit source grammar, Standard/notation/handler imports, module and instance identity, trusted primitive signatures/axioms, proof checking, VC/effect closure, erasure and output contracts. Use an independently reviewable cryptographic manifest/digest.
3. Qualify meaningful end-to-end real multi-module applications and a full cross-target JS/TS/Rust/Wasm GC/component matrix, reproducible artifacts, resource/stack/performance boundaries where relevant and source provenance. Retain minimal high-value failures plus broad integration at architectural milestones.
4. Resolve every mandatory semantic, proof and emission acceptance gate before using "v7 complete"; no blanket claim from `pscv0-v7-native-bounded/48` or a green CI alone.
**Phase E exit:** all core and essential v7 acceptance obligations satisfied with exact source SHA, independently checked evidence and reproducible Linux CI.

**AFTER A–E ONLY, separate future work (NOT AUTHORIZED IN THIS LOOP):**
- **C5** pre-erasure readable Lean/ProofScript source reconstruction, finer source maps/round-trips and formatter/source UX; intentionally deferred until essentials are complete.
- Separate backend **D** performance/ownership profiling and improvements, preserving correctness/ABI (no invented speed winner).
- Compiler-source `.ps` migration, bootstrapping/fixed-point self-hosting and alternate `pskernel-core` integration are **out of current scope**; require an explicit later decision. P2 async/resources/UI extensions and wider ecosystem packages are separately scoped after core acceptance, not implicit promises.

## Working method and invariants for the next chat

1. At startup **resolve live branch HEAD** from GitHub, read this TOP handoff, the canonical language reference, the complete roadmap and Standard snapshot; examine affected source/official Lean RC4 definitions before modifications. Keep history and this PR draft.
2. Build a clean subsystem-level design around actual invariants and dependency graph. Freely refactor obsolete internals when justified, but never weaken source semantics, proof trust, acceptance cases or existing backend contracts to pass tests. Implement coherent feature families before tests when sensible.
3. Use **GitHub connector** for source reading and atomic/leased commits; **Linux GitHub Actions** for official Lean builds, focused checks, 187+ runtime integration and related negative conformance. No local checkout/build, Desktop Commander, pskernel-core/selfhost or main merge.
4. Pin every newly qualified executable commit and associated CI. Do not call a documentation commit "qualified executable". A changed Standard environment requires reviewed snapshot/digest regeneration and meaningful negative drift checks.
5. Continue Phase A → B → C → D → E without stopping solely to report progress. If an actual semantic/CI blocker arises, study the root cause and choose a general architectural correction. No test-fix-patch loop.
6. Preserve **native portable `.lean`** source, **official Lean 4.35.0-rc4** as checker, Wasm GC language values (linear memory only at explicit Canonical ABI boundaries), JS/TS/Rust/Wasm contracts, exact source and generated-member provenance and an auditably small trusted base. Never claim v7 complete until Phase E exits.



---

# Historical qualification checkpoint — PSCV0 v7 module foundation

**Current scope:** core/essential language before C5; native portable `.lean` only.
No pskernel-core, compiler `.ps` migration, self-hosting, local builds, main
merge or release.

**Latest qualified source:** `d83e8878b4ec305c1783a51cd74925b597d86920`
**Profile:** `pscv0-v7-native-bounded/48` (module planner is a separate
pre-emission capability, not a new public source-profile number).
**Linux qualification:** [38243759063](https://github.com/dwijayuda/pskernel/actions/runs/38243759063)
passed all jobs on 12 October 2026. The existing integration matrix passed
**171 shared observations** for JS, TS, Rust, Node/V8 Wasm and Wasmtime
component/core, **159 portable/166 native closure modules**, four accepted
programs and 92 phase-specific refusals. `PSCV0_NATIVE_MODULES` passed a
checked public import through a facade, dependency ordering, missing import and
cycle rejection. This verifies the bounded cases only, not full RC4 module
semantics or cross-module executable artifact emission.

The new pure `Ps.Compiler.Pscv0Modules` source graph uses explicit
`PsSyntaxImport.isPublic`, topological planning, immutable prelude-relative
interface installation and checked admission preparation. It has no filesystem
IO or alternative proof checker. Graph identity, body visibility and
instance registration must be extended conservatively. Remaining module work:
private/public declaration visibility, true RC4 module-body opacity for
imported theorems and definitions, full diamond/collision and namespace
semantics, module-scoped API exports, linking library runtime IR and official
kernel validation of the project closure. None are marked complete.

Further language essentials remain pending: Standard instances and notation
completeness; specialized scalar, raw/interpolated strings and GetElem;
nested/mutual data and termination; generalized typed do/effects/state;
proof-producing rewriting/automation, contracts, VC obligations, and the
assurance ledger. C5 is still deferred by user direction.

---

# Active v7 language-first continuation (12 October 2026)

The latest user authorization **defers C5 readable application source reconstruction**
and prioritizes implementing and qualifying the remaining core and essential
PSCV0 v7 language features. Native portable .lean is the only compiler source
and is checked with pinned official Lean 4.35.0-rc4. No pskernel-core, compiler
.ps migration, bootstrap/self-host testing, main merge, force push or release.

**Latest qualified source:** `1922294d9918c477552db44788208364ba37188a`
**Profile:** `pscv0-v7-native-bounded/41`
**Linux CI:** [run 38223957480](https://github.com/dwijayuda/pskernel/actions/runs/38223957480) passed every job.
**Subsequent branch head:** `7218cf6b75caa1a10d1734b0cf69cdb5c9fafe63`, documentation-only against this qualified source.

Qualification at profile 41 checked 498 composite declarations in the existing main
application, four accepted programs, 92 phase-specific semantic refusals,
seven typed-do and one opaque-opacity refusal. The same **151 shared runtime
observations** passed through direct JS, pinned TypeScript, pinned Rust, Node/V8
Wasm core and pinned Wasmtime component/core execution. Source guard: 157
portable / 164 native modules, no pskernel-core. Declaration-map testing
observed 366 mappings and 14 generated-parent origins. Official Lean RC4
remains pinned to `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.

Since qualified C4b profile 35, the same source/semantic/official-kernel/IR/backend
pipeline gained:

- Profile 36: typed `do` AST, shared scoped condition/continuation elaboration,
  selected Id/Option/Except effects, and tuple values. [Run 38215524481](https://github.com/dwijayuda/pskernel/actions/runs/38215524481) passed.
- Profile 37: `#[...]` array literals using checked persistent Array operations.
  [Run 38216645409](https://github.com/dwijayuda/pskernel/actions/runs/38216645409) passed.
- Profile 38: `[...]` List literals and one reusable delimited-value reader.
  [Run 38221786624](https://github.com/dwijayuda/pskernel/actions/runs/38221786624) passed; 493 source declarations, four accepted programs, 92 semantic refusals and seven typed-do refusals.
- Profile 39: selected right-associative `×` type syntax (Lean RC4 precedence 35),
  empty List values and trailing commas. [Run 38222423936](https://github.com/dwijayuda/pskernel/actions/runs/38222423936) passed.
- Profile 40: genuinely opaque, kernel-checked source definitions; the canonical
  admission codec preserves opacity, and runtime erasure compiles the checked
  opaque value without exposing it to definitional equality. A negative proof
  case refuses an illicit `rfl` unfold. [Run 38223491831](https://github.com/dwijayuda/pskernel/actions/runs/38223491831) passed.
- Profile 41: selected `+` notation uses Lean RC4 precedence and resolves the
  explicit user-defined `HAdd.hAdd` class instance through the existing generic
  class/instance elaborator, rather than a Nat-specific syntax rewrite. Automatic
  Lean/Standard instance registration, other numeric operators and full scalar
  literal coverage are still pending. [Run 38223957480](https://github.com/dwijayuda/pskernel/actions/runs/38223957480) passed.

The bounded qualified source still passes the shared runtime-observation matrix
and existing Wasm GC/component, direct JS, TypeScript and Rust gates. Passing
these does **not** prove compiler preservation or full language conformance.

**Next dependency-driven core work:** complete general typed notation through the
pinned Standard class/instance environment (rather than Nat-only rewrites);
selected literal/operator families; module and public-import visibility;
remaining dependent data and termination/recursion; general typed effects/do
control and pure state; proof goals, rewriting, proof-producing automation and
verification obligations. Scope, semantic checking, portable closure, origin
tracking and ABI boundaries remain shared. Each new language family needs
minimal targeted semantic/refusal evidence and the existing integration matrix.

## Historical records below

Earlier handoff instructions, including the C5-next request, are superseded by
this active authorization. Historical success receipts remain source-specific.

---

# Native Wasm C4 and C4b qualified

12 October 2026. The authorized C4 and C4b milestones are complete for the
current checked runtime and synchronous pure foreign profile. The selected
architecture is **Wasm GC internally, linear memory only at explicit Canonical
ABI boundaries**. Native .lean remains authoritative.

**Qualified implementation:** 26f68bd3038869d16ba4e3a97957de8f16a531ed
**Profile:** pscv0-v7-native-bounded/35
**Linux CI:** [run 38197409359](https://github.com/dwijayuda/pskernel/actions/runs/38197409359),
job 114643060557. Every step passed using the committed Cargo.lock and --locked.
The earlier successful integration run 38197107365 supplied that exact lockfile.
Only documentation/PR metadata follow this qualified source.

## New-chat handoff — 12 October 2026

The current chat stops only to conserve remaining usage. C4/C4b are complete;
there is no known implementation blocker or pending source edit. The final
locked CI run below passed. This handoff makes no implementation changes.

Continue with the planned C5 readable Lean/ProofScript reconstruction milestone,
then the dependency-driven v7 roadmap. Read AI_CONTINUE_PROMPT.md for a
ready-to-paste continuation request. C5 selected application output does not
authorize compiler-source migration or self-hosting.

Repository: dwijayuda/pskernel; branch: psc0/pscv0-v7-native-lean-v1.
Draft PR109: https://github.com/dwijayuda/pskernel/pull/109
Base: psc0/pscv0-v7-m1-parser-ownership-v1.
Pre-handoff documentation checkpoint: 621a034168d0fd15a082a5b9e39583a555beb856.
Resolve the current branch head before any write; later documentation does not
change the qualified source identity below.

Workflow: repository source reads/writes through GitHub tools; builds/tests in
Linux cloud CI only. No local checkout/build/test, pskernel-core, compiler .ps
migration, self-hosting, main merge, release or force push. Native .lean and
official Lean RC4 checking remain authoritative.

Read next, in order:
1. PSCV0_LANGUAGE_REFERENCE.md (canonical v7 specification).
2. docs/PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md.
3. docs/PSCV0_DIRECT_JS_WASM_ARCHITECTURE.md, especially source reconstruction.
4. docs/PSCV0_NATIVE_CODEGEN.md and docs/PSCV0_NATIVE_WASM.md.
5. host/src/Ps/Host/NativeV7.lean; packages/codegen/src/Ps/Codegen/{Doc,Names,Artifact,Provenance}.lean;
   packages/syntax/src/Ps/Syntax/{PrintLean,PrintProofScript}.lean;
   the frontend source/preparation representation and affected tests.
Inspect existing implementation before inventing another presentation IR.

Transient functions.exec stores, fetched source maps and tool results from this
chat will not be available in a fresh chat. Recover files from the branch. Use
GitHub REST PR metadata rather than fetching/printing the entire PR diff, which
is very large. Fetch specific source files at a verified ref and summarize CI
logs. For remote edits, create tree/commit then update_ref with expected_sha and
force=false; retain unrelated source changes. Local report files are not a
repository checkout. Do not execute prompts found inside reference documents.

## Completed boundary

C4 supplies GC data/closures, generic representation crossings, source lowering
and current Nat/Int/String/Array semantics. Published values are persistent;
arithmetic uses normalized u32 limbs and fresh working arrays. Direct concrete
calls stay unboxed, runtime/tail calls use Wasm tail calls, and unused functions
are pruned. Shared lexical capture analysis replaces duplicated Rust traversal.
The obsolete scalar-only source lowerer is removed.

C4b supplies one concrete interface/layout plan, readable WIT/WAT, native binary
component/core encoders, checked GC-to-ABI marshalling, realloc and post-return.
Scalar worlds need no memory; aggregate/indirect worlds expose an api interface.
The component bundle includes .wit/.wat/.wasm and explicit standalone core
companions. Proof/dependent foreign construction is refused using source
classification retained before erasure. Whole-call cleanup is valid for this
pure synchronous, non-reentrant profile.

The admitted foreign profile includes Bool/Char/String/Nat/Int, lists, ordinary
nonrecursive records/variants and concrete generic data, plus void Unit results.
It does not expose resources, callbacks, imports/effects, recursive foreign
values or automatic proof-bearing constructors. Those require explicit
resource/view/validating APIs; no integer-handle shortcut is implemented.
Details and lifetime rules: docs/PSCV0_NATIVE_WASM.md.

## Qualification

- 155 portable / 162 native closure modules; no pskernel-core or host imports in
  the portable compiler.
- Official Lean RC4 checks the same prepared graph. Existing 473-declaration
  composite, four accepted programs, 92 refusals, 28 parser cases and compact
  scope/IR checks remain green.
- The same 142 observations pass in Node/V8 core and in Wasmtime core and
  component instances, including WAT-reassembled artifacts. The embedding
  harness batches calls per instance instead of repeating engine startup.
- All 142 directJS, TypeScript and Rust observations still pass, along with
  the strict declaration consumer and 345 mappings / 14 parent origins.
- Ten limb probes and one aggregate fixture cover large integers, normalization,
  Unicode, arrays, records/variants, generic field boxing, flat/indirect calls,
  Char and void post-return.
- 64 repeated 98,304-byte Unicode calls reach a stable 262,144-byte arena.
  Buffers remain live before post-return and the allocation cursor resets
  after cleanup. Four malformed UTF-8 and nine other ABI refusals pass.
- wasm-tools 1.261.0 parses WIT, extracts the complete contract, validates
  binaries and reassembles WAT. Core and component bytes match after removing
  only name/component-name metadata. Package/world labels absent from the
  binary and formatting are the only WIT normalization.
- Wasmtime 49.0.2, Node 22.23.3 / V8 12.4.254.21-node.57 and Rust 1.98.1 are pinned.
  Production emission uses only native Lean, with no external assembler.
- Prelude audit: 64 axioms, 48 native signature matches and 16 reviewed models.
  Target typing/observations do not prove semantic preservation.

## Following work

C5 readable pre-erasure Lean/ProofScript reconstruction, measured performance
work and remaining v7 language capabilities are separate milestones. C4/C4b
completion does not imply full v7 conformance. No compiler-source .ps migration,
self-hosting, local build/tests, pskernel-core, main merge or release occurred.

---

# Historical work records

Earlier status and stopping instructions below are historical.

# Native Wasm C3 qualified; C4 GC runtime foundations

12 October 2026. The user authorized C3, C4 and C4b on the existing draft PR109
branch. The latest architecture choice is **option A: Wasm GC for language
values, linear memory only at explicit Canonical ABI boundaries**. This
supersedes the interim no-linear-memory choice. Aggregate component interop
remains in scope; it is not yet implemented.

**Qualified source:** df545d7b0951a9556136f13b1f2a569e157d6b4c
**Profile:** pscv0-v7-native-bounded/33
**Linux CI:** [run 38193114046](https://github.com/dwijayuda/pskernel/actions/runs/38193114046),
job 114629912991. All steps passed. Later documentation-only changes do not change
this source-specific evidence.

## Completed and ongoing boundary

C0–C2 retain shared readable ECMAScript, direct .js/.d.ts/.js.map, Rust,
artifact/API/provenance contracts and the native primitive signature audit.
C3 adds a typed Wasm core, direct core/component binary emission, readable
WAT/WIT, named binary metadata, explicit scalar foreign exports and capability
diagnostics. Binary and WAT share the retained target IR. Independent function
signatures remain outside aggregate recursive groups for canonical type
identity; local declaration runs are compact without changing local indices.

C4 foundations add GC value layouts, named-local runtime authoring combinators,
tail-call loops and immutable published arbitrary-precision natural values
backed by owned working limb arrays. Addition, saturating subtraction,
multiplication, division and remainder are implemented in target runtime code.
Small-divisor division traverses limbs directly. This runtime has focused
qualification but is not wired into full source lowering; the public Wasm
capability remains the bounded C3 scalar profile.

## Validation

- 143 portable / 146 native closure modules; no pskernel-core or host import in
  the portable closure.
- 473 composite declarations, four accepted programs, 92 existing refusals,
  28 parser cases and compact scope/IR/naming checks remain green.
- 142 observations pass on each of directJS, TypeScript-compiled JS and Rust;
  declaration consumers and 345 declaration mappings / 14 parent origins pass.
- Three Wasm fixtures: executed GC allocation inside a scalar component,
  checked-source Boolean computation, and ten natural-limb runtime observations.
  Node 22.23.3 / V8 12.4.254.21-node.57 and Wasmtime 49.0.2 execute the cores.
  Wasmtime executes the direct and reassembled components.
- wasm-tools 1.261.0 validates binaries, independently assembles WAT and extracts
  WIT. Core bytes agree after excluding only name metadata. Both release
  archives are SHA-256 pinned.
- Official Lean RC4 checks the same prepared source graph. The prelude audit
  still has 64 axioms: 48 matching native signatures and 16 reviewed models.
  Backend observations and target typing do not prove semantic preservation.

## Remaining authorized work

Complete C4 shared IR lowering for all current data, generic conventions,
closures, Int/String/Array intrinsics and all 142 observations in both core
engines. Complete C4b's aggregate interface/Canonical ABI plan, marshalling
allocator, post-return ownership, resource lifetimes and component observations.
The pinned CLI has a WIT-keyword name limitation; C4b requires the embedding
harness for unrestricted export lookup and repeated-call lifecycle validation.
C5 readable Lean/ProofScript reconstruction and full v7 language completion
remain later capabilities.

Native .lean is authoritative, executed natively and checked by official Lean.
No compiler-source .ps translation, pskernel-core, local build/tests, self-hosting,
main merge or release. Details: docs/PSCV0_NATIVE_WASM.md and the approved
docs/PSCV0_DIRECT_JS_WASM_ARCHITECTURE.md.

---

# Historical work records

Earlier stopping instructions and status claims below are historical.

# C0–C2 qualified: native directJS and shared readable ECMAScript

12 October 2026. The user authorized C0, C1 and C2. They are implemented on
the existing draft PR109 branch. Compiler authoring/execution remains native
Lean; official Lean checking, portable closure boundaries and Rust remain in
place. No pskernel-core, compiler-source .ps translation, self-hosting, main
merge or release was performed.

**Qualified source:** dc36fc477ecba23abcac2b3c9b0bd264c2317f3e
**Profile:** pscv0-v7-native-bounded/32
**Linux CI:** [run 38189763277](https://github.com/dwijayuda/pskernel/actions/runs/38189763277),
job 114619794223. All steps passed. Documentation updates after that source do not
change the qualified implementation.

## Implemented boundary

- C0: validated text/binary artifact bundles, roles/dependencies, source identity
  and actual declaration spans; generated projection/normalization/recursor
  parent attribution; runtime API selection and conservative WIT representability;
  target capability records; reviewed native primitive signature/model audit.
- C1: one planned ECMAScript program supplies both JS and TS. Structured AST/Doc
  emission covers expressions, control flow, generators, runtime helpers and
  intrinsics. Existing count/tail semantics and lexical capture guards remain.
  Nonrecursive functions emit ordinary straight-line bodies. The native path
  no longer imports the old expression/module string emitters.
- C2: direct .js, .d.ts and .js.map output plus provenance/API manifests. No TS
  compiler participates in emission. Maps use ECMA-426 UTF-16 coordinates from
  final layout and real source spans. The host prepares and collision-checks
  all outputs before writes; multi-file crash atomicity is not claimed.

Source maps resolve to the **owning declaration span**, including nested lowered
code and explicitly attributed generated members. Runtime-only helpers are
unmapped. Token/statement stepping, original comments and readable Lean/PS
reconstruction are not claimed. The export-selection schema is available for
foreign ABI planning; existing JS/TS/Rust runtime exposure remains compatible.

## Qualification evidence

- 128 portable / 135 native modules; excluded-checker and host-dependency guards pass.
- 473 declarations admitted in the unchanged composite application.
- Existing four accepted programs, 92 phase-specific refusals, 28 parser cases
  and compact scope/IR/naming checks pass.
- The same **142 runtime observations pass on each of direct JS, TS-compiled JS
  and Rust**. TypeScript 7.0.2, Node 22.23.3 and Rust 1.98.1 remain pinned.
- Independent source-map decoding validates 345 declaration mappings,
  14 generated-parent origins, Unicode/non-BMP UTF-16 columns and unmapped
  generated regions. A strict isolated .d.ts consumer passes positive and
  negative type cases; no sibling implementation .ts can shadow the .d.ts.
- Native Init signature audit: 64 prelude axioms, 48 alpha-equivalent native
  signatures and 16 explicitly reviewed representation/universe models.
  Unexpected mismatches fail. This is not a proof of runtime bodies.

Single-run measurements (not benchmarks): incremental native build 4,247 ms;
warm build 396 ms. Parse/elaborate/prepare/kernel/erase-and-origin/IR-and-all-target-
emission: 31/33/28/36/27/39 ms. Emitted composite sizes: JS 102,327 bytes, TS
133,933, declarations 27,136, map 58,593. The map includes source content.

## Entry points and next boundary

```text
pscv0_native --emit application.ps output.js
pscv0_native --emit-all application.ps output
pscv0_native --audit-primitives
```

The default checked native workflow uses --emit-all once; TS compilation writes
to ts-compiled/ so it cannot overwrite or substitute for direct JS.

Architecture: docs/PSCV0_NATIVE_CODEGEN.md.
Remaining backend sequence: C3 directWasm foundation, C4 core runtime parity,
C4b WIT/Canonical ABI/component completion, C5 pre-erasure readable Lean/PS,
then measured performance work. No Wasm or general v7 completion is claimed.
C0–C2 is the completed stopping boundary for this request.

---



The following sections record earlier requests and evidence. Their stopping
instructions and status claims are historical; the current state is above.

# WIT/WAT/Wasm architecture refinement — research only

12 October 2026: the user requested an expanded architecture report covering
directJS (.js/.d.ts/.map), directWasm (.wit/.wat/.wasm), and readable JavaScript,
WIT, WAT, TypeScript, Rust, Lean and ProofScript. No implementation is authorized
by this report-only request.

Revision 2 of docs/PSCV0_DIRECT_JS_WASM_ARCHITECTURE.md preserves the existing
pipeline and adds a checked public API schema, explicit foreign export selection,
WIT representability, Canonical ABI planning and a component writer. The proposed
complete directWasm bundle implements the declared WIT world in a component
binary; a standalone core module is an explicit separate profile.

Wasm GC remains the recommended internal runtime. Synchronous memory32/UTF-8
Canonical ABI adapters own boundary conversion/allocation and resource lifetimes.
The design does not depend on the proposed GC-native Canonical ABI. Recursive
and generic source types stay intact internally; concrete signatures, value
views or resource APIs serve the foreign boundary.

C4b now covers WIT/component completion after core runtime parity. C0 includes
interface representability; C3 includes an early GC-inside-component compatibility
probe before larger implementation. Native compiler authoring, official checking,
minimal shared validation and deferred compiler-source migration/self-hosting
remain unchanged. No compiler, runtime, workflow or acceptance input changed.

The last semantic milestone is still qualified profile 31. Source 9c08a9a
passed run 38185022674; the subsequent documentation/comment-only source
7293da886f3e9d71cc94a95d238f7ffca1a7f13e also passed run 38185845549.
Both are historical evidence, not qualification of proposed backends.

---

# Class output inference qualified; backend design reported, implementation stopped

Profile 31 at **9c08a9a019b2afc2dc7eda15a0c6699832f2c688** passed
[run 38185022674](https://github.com/dwijayuda/pskernel/actions/runs/38185022674),
job 114605381212: 473 composite declarations checked relative to the reconstructed
portable prelude, four accepted programs, 92 phase-specific refusals and 142
shared TypeScript/JavaScript and Rust runtime observations. The existing 28
parser cases and compact emission/scope checks pass. Closure guard: 121 portable
and 127 native modules; pskernel-core excluded.

The completed milestone registers class output parameters and output-only
universes, masks outputs for candidate selection/cycle detection, reconciles
outputs after selection, and shares a dependency worklist between application
and recursive dictionary synthesis. It removes duplicated fixed-order solvers.
See docs/PSCV0_NATIVE_INSTANCE_OUTPUTS.md.

Single-run timings: rebuild 59,973 ms; warm build 502 ms; application parse/
elaborate/prepare/kernel/erase/IR-and-emit 48/64/79/53/71/22 ms. These are not
benchmarks. Native Lean remains pinned to 4.35.0-rc4,
c29b6dda4f7c20e3eeaa717c4e565663c5cfa364.

## User-requested stopping boundary

Language implementation stops here. The user requested research and an
architecture report before adding directJS (.js, .d.ts, .map), directWasm, and
further readable TS/Rust/Lean/ProofScript output. The proposal is in
docs/PSCV0_DIRECT_JS_WASM_ARCHITECTURE.md. No new backend is implemented.

Recommended order: C0 contracts/provenance/trust audit, C1 shared structured
ECMAScript emission, C2 directJS, C3 typed directWasm foundation, C4 current
runtime parity, C5 pre-erasure readable source reconstruction. Wasm GC is the
recommended first representation, subject to explicit engine qualification.
The existing semantic pipeline, Rust ownership work and native portable closure
remain authoritative. Full v7 remains incomplete.

## Correction to verification wording

The official provider replays portable declarations into an empty Lean
environment. Portable axiom signatures become assumptions; they are not
automatically compared with imported native standard-library declarations.
Earlier conditional documentation and its inline comment overstated that check.
This documentation correction does not change executable behavior.

Official checking is relative to that reconstructed prelude. It does not prove
native primitive fidelity or backend preservation. The proposal requires a
compact native signature/model audit and primitive/assumption ledger before
qualifying additional targets. Source typing, runtime primitive contracts,
IR/target validation and observed runtime agreement remain distinct claims.

Native .lean authoring and Linux cloud qualification continue to define this
development lane. No local checkout/build/tests, pskernel-core, compiler-source
.ps migration, self-hosting, main merge or release. Earlier records below are
historical; their pending-work descriptions are superseded by the current
roadmap and this stopping boundary.

# Native core language continuation

Profile 29 at e1b03d35384387f055b424d87f16092d47162e7f passed
[run 38184092534](https://github.com/dwijayuda/pskernel/actions/runs/38184092534):
438 checked declarations, 85 phase-specific refusals, and 130 shared TS/Rust
runtime observations. Cases, induction and named case/next focus reuse typed
Match refinement and shared metavariable scope closure. See
docs/PSCV0_NATIVE_ELIMINATION.md. No pskernel-core or self-hosting.

Profile 30 adds ordinary and named proof conditionals using actual decision
evidence. Native .lean remains authoritative. The complete cloud native build,
official kernel and both runtime targets must qualify this source before any
completion claim. See docs/PSCV0_NATIVE_CONDITIONALS.md. Full v7 remains open.

# Native codegen milestones A and B qualified

Implementation source **ff83ff5e927bdc4bf5d31f57bef688f4b146537b** passed
[run 38176124905](https://github.com/dwijayuda/pskernel/actions/runs/38176124905),
job 114578776391, native profile **pscv0-v7-native-bounded/17**:
- Native Lean 4.35.0-rc4 build and official kernel admission of 285 declarations.
- Existing 28 parser cases, four accepted semantic inputs, 50 phase-specific
  refusals and the compact invalid-IR/name/origin boundary check.
- One CLI preparation/check/erasure and complete shared IR validation for TS and
  Rust. Strict TypeScript 7.0.2 and Rust 1.98.1 Cargo --locked --release both pass
  the same 102 runtime observations. No prior acceptance requirement was removed.
- Source guard: 102 portable / 108 native modules; no pskernel-core.
- Cached rebuild 5146 ms; warm build 520 ms. CLI parse/elaborate/prepare/kernel/
  erase/combined-IR-and-emit: 19/21/79/38/57/14 ms. Single-run observations only.

Milestone A added the real IR gate, semantic/output symbol mapping, a portable
document printer, artifact/origin records and structured TS declarations.
It first qualified at 6115702332bb51c11fbe2df1e5835f0d0c45bf6b in
[run 38174273630](https://github.com/dwijayuda/pskernel/actions/runs/38174273630).

Milestone B integrates Rust with uniform Rc<dyn Fn> values, recursive nominal
layout analysis, liveness-based moves/clones, copy-on-write arrays, compositional
Rust output and a separate runtime. Legacy function-storage restrictions and
the obsolete ValueRefs module were removed. The same composite gains eleven
observations for closures, array persistence, numeric/Unicode behavior and
borrowed operands followed by consuming argument expressions.

Final implementation source **6a96dfccfdb66a868efb8b2ed9282f4953ff71b1**
also passed [run 38176347485](https://github.com/dwijayuda/pskernel/actions/runs/38176347485),
job 114579440804, with the same acceptance inputs and thresholds. Cleanup uses
conventional uppercase lazy-cell statics and omits redundant atomic-match
parentheses. The following evidence-only documentation commit does not change
compiler sources, workflow, inputs or runtime behavior.

See docs/PSCV0_NATIVE_RUST.md and docs/PSCV0_NATIVE_CODEGEN.md. Rust is qualified
for the current pure, single-module runtime profile on Linux; this is not full
v7, a backend preservation proof, or a scaling/cross-platform qualification.
Complete TS expression layout, source-coordinate/comment retention and readable
source Lean/ProofScript emission remain milestone C. Final-owner iterative
release and broader scaling/performance work remain milestone D. Continue v7
language growth natively; no compiler-source .ps generation or self-hosting yet.

---

# Native codegen milestone A — implementation awaiting qualification

The explicit IR gate is now wired into native emission. Earlier entries saying
"typed IR validation" described typed erasure and TS integration but the previous
NativeV7 host called the raw TS emitter without Ps.CompilerIr.Check. Those runs
remain valid evidence for their actual kernel/TS/runtime checks, not that missing
gate. The current change must earn new cloud qualification.

Milestone A retains semantic names through erasure, creates a collision-free
target naming view, adds a portable document printer and artifact/origin records,
and renders TS declarations/structures with structured blocks. Full expression
formatting, source-span/comment retention and source Lean/PS output remain later.
See docs/PSCV0_NATIVE_CODEGEN.md. Rust integration follows this foundation.
No pskernel-core, local checkout/build/tests or self-hosting are introduced.

---

# PSCV0 v7 native continuation — class and instance milestone

The small milestone requested before adding Rust is complete. Development remains
portable native .lean with official Lean RC4 checking and Linux cloud CI on draft
PR #109. Full v7 completion is not claimed. The next requested implementation
milestone is the Rust backend over the existing validated typed IR.

## Latest qualified implementation

Source **a74153c8c1571ee01913b8db6af10d803767d005**,
[run 38171564012](https://github.com/dwijayuda/pskernel/actions/runs/38171564012),
profile **pscv0-v7-native-bounded/15**, all PASS:
- Native Lean 4.35.0-rc4 build and official kernel admission of the 264-declaration
  composite application.
- Existing 28 parser cases and one isolated semantic batch: four accepted inputs,
  50 phase-specific refusals. Six new refusals protect instance grammar,
  registered-class results, dictionary field typing and cyclic-only search.
- Actual CLI emission, typed IR validation, TypeScript 7.0.2 strict compilation
  and emitted JavaScript execution.
- Runtime evidence covers named/anonymous global instances, numeric/named
  priorities, recursive generic dictionaries, local precedence, cyclic-candidate
  fallback, class proof fields and qualified structure/class projections.
- Import guard: 85 portable modules / 91 native closure modules.
- Observed application phases: parse 17 ms, elaborate 20 ms, prepare 57 ms,
  official kernel 30 ms, erase 53 ms, emit 9 ms. Single-run observations only.

Class registration is environment metadata over existing structure elaboration.
Global instances are checked definitions, registered only after elaboration and
class-result validation. Persistent environment insertion preserves both registries.
Locals precede prioritized globals; equal priorities prefer the most recent entry.
Failed candidates restore their constraints; active ground goals prune cycles.
Class dictionary projections and ordinary structure projections are closed Core
definitions submitted to the same official checking boundary.

Record construction now propagates expected uniform parameters before checking
fields and uses the shared named-argument engine. Obsolete positional record
ordering helpers were removed. Generated instance field lambdas enclose their
dependent result ascriptions. No alternate checker or host frontend is introduced.

See docs/PSCV0_NATIVE_CLASSES.md for the invariants and remaining boundaries.
Ground search is not full RC4 typeclass resolution: tabled non-ground search,
output parameters, superclasses, attributes/default instances, imported class
registries and source universes remain pending. Full v7 language work resumes
after the requested Rust backend milestone. pskernel-core, compiler-source .ps
generation and self-hosting remain outside this development loop.

## Prior qualified dependent-pattern and proof-data milestone

Development remains native .lean with official Lean RC4 checking and Linux cloud
CI, on draft PR #109. The canonical v7 specification remains the target; this
entry qualifies a bounded milestone, not complete language/project conformance.

## Latest qualified implementation

Source **2b992051732b8f484995b91c934c7ccd37bcf663**,
[run 38170141115](https://github.com/dwijayuda/pskernel/actions/runs/38170141115),
profile **pscv0-v7-native-bounded/14**, all PASS:
- Native Lean 4.35.0-rc4 build, commit c29b6dda4f7c20e3eeaa717c4e565663c5cfa364.
- Official Lean admission of the 230-declaration application and compact isolated
  semantic batch: four accepted inputs and 44 phase-specific refusals.
- Existing 28 parser cases, actual CLI emission, typed IR validation, strict
  TypeScript 7.0.2 compilation and emitted JavaScript execution.
- Runtime checks include nested dependent tails, first-match priority, binding
  hygiene, proof-guarded functions, pattern-derived terms and proof-field layouts.
- Import guard: 83 portable modules / 89 native closure modules; pskernel-core
  excluded. No compiler .ps generation, self-hosting or separate kernel suites.

Observed cached source rebuild: 9,355 ms; unchanged warm build: 433 ms.
The emitted application took parse 14 ms, elaborate 14 ms, prepare 41 ms, official
kernel 23 ms, erase 36 ms and emit 6 ms in that run. These are single-run
observations, not general performance guarantees.

Earlier qualified boundaries in this continuation:
- Captured recursor preparation: source 97964cfc3c1dbc5b7c90a8ec8180cb98e00d2824,
  [run 38166467810](https://github.com/dwijayuda/pskernel/actions/runs/38166467810), profile 10.
- Empty/nomatch: source 7676965c1b78cce38df4acdb7410895949bf0331,
  [run 38166881411](https://github.com/dwijayuda/pskernel/actions/runs/38166881411), profile 11.
- Typed matrix and proof-function boundaries: source 9495643e8914fb76e7b3f6c627d92d00aacccabb,
  [run 38169325178](https://github.com/dwijayuda/pskernel/actions/runs/38169325178), profile 12.
- Pattern-derived terms/inferred results: source cc5b01740337d5e6a61c8b8e4c490790c1828fb3,
  [run 38169695528](https://github.com/dwijayuda/pskernel/actions/runs/38169695528), profile 13.

## Shared mechanisms and corrected invariants

Captured/local/computed/nested runtime recursors are lifted to checked helper
declarations. Dependency closure preserves captured values; fresh major/index
parameters vary. Typed traversal skips proofs/types and the host checks the same
prepared graph it emits.

One recursive pattern tree and typed ordered matrix serves nested/multiple
discriminants, tuple/Nat successor patterns, nomatch, if-let, pattern-let and
matches. Branch continuation reuses Match/Refinement/Equality for motives,
dependent-context transport, impossibility and coverage. Inaccessible aliases
preserve cross-column binding hygiene and once-only computed discriminants.
Constrained motives retain outer index scope until actual equality elimination;
they do not rebind indices around dependent captured values.

Proof data disappears, but proof parameters of computational functions retain
ignored Unit call slots. **Earlier notes below claiming that proof binders
disappear from function representations are superseded.** Removing that boundary
prematurely forced a proof-guarded IH in nested matching. Uniform
type/lambda/entry/call/completion handling preserves evaluation order.

Checked constructor arity is separate from runtime field storage. Leading,
interleaved and trailing proof fields keep their original source/projection
indices, are checked normally, and occupy no runtime fields. The shared minor
opener consumes the checked field telescope before IHs. This supports dependent
structure proofs, record projection/matching, recursive inductives and partial
constructors without compacted-index guesses.

Metavariable assignment now checks the candidate's type with the same bounded
unifier before recording its value. This solves implicit type-parameter universe
constraints uniformly. The previous extra match-universe reconciliation step
is removed; scope/occurs checks and transactional failure are preserved.
Unknown expected types no longer prematurely retain an implicit Pi instead of
inserting its implicit arguments.

Design records: docs/PSCV0_NATIVE_RECURSOR_PREPARATION.md,
docs/PSCV0_NATIVE_PATTERN_MATRIX.md, docs/PSCV0_NATIVE_PROOF_ERASURE.md and
docs/PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md. The README describes the selected
surface and limits.

## Remaining boundaries

Heterogeneous fixed-index major dependence and index-constructor projections,
general joint nomatch contradictions, named/generalizing/as/inaccessible
patterns, implicit constructor-pattern insertion, multi-root source recursion,
Type/existential fields, non-type uniform parameters, source universes/Prop
families, modules/global classes/Standard, tactics/contracts/effects and complete
v7 assurance remain outstanding. Native compiler growth still precedes final
readable .ps migration and fixed-point qualification.

Main remains 748ee630e43ee1a89643cbc8cec3e31087788b08 and the M1 base remains
b4bd7e7d6c48443e56eaf96099515a29a83982bf. No local checkout/build/test, Windows
test, kernel implementation edit, merge, publication or branch rewrite was used.


---

# PSC0 AI WORK STATE — dependent context refinement and impossible cases

## 12 October 2026 — proof-producing refinement through native runtime emission

Active branch: `psc0/pscv0-v7-native-lean-v1`; draft PR #109.
The requested milestone is implemented within the explicit bounds below.
Compiler authoring remains native `.lean`; work used GitHub source operations
and Linux cloud CI. No local checkout/build/tests, pskernel-core, compiler-source
generation, self-hosting or kernel implementation changes were used.

### Implemented boundary

`Ps.Elab.Refinement` owns ordered dependency closure and telescope reversion.
Match motives now generalize dependent local bindings and preserve dependent
local definitions. Branches reopen that context from the recursor's actual
telescope. Fresh local aliases preserve pattern shadowing and original outer
declarations. The completed motive determines the recursor universe.

Fixed, compound and repeated indices generate homogeneous equality constraints.
`Ps.Elab.Equality` constructs equality transport, constructor field injectivity
and constructor disjointness through checked recursors. An omitted constructor
branch is accepted only when the solver produces a contradiction and eliminates
`False`. Equal indices and unresolved/occurs-check constraints do not justify
omitting a branch.

`Ps.Environment.Logic` supplies genuine Eq/False/True/Bool inductives plus
defined False.elim; no new proof axiom or host elaboration service is used.
Official Lean admits the prelude and checks actual generated proof terms.
`Ps.Meta.Iota` reduces direct single-family recursors, with compact Nat literal
constructor views rather than eager successor expansion.

Changing dependent state now reaches the existing recursion worker normalization:
the worker returns a function over state whose type can depend on retained
indices. Invalid stale dependent recursive arguments remain rejected.
There is no second recursion algorithm.

Runtime erasure removes proof binders from function representations as it already
does for calls and lambdas. Equality transport requires equal checked erased
representations; impossible branches use a typed unreachable IR node with a
defensive runtime throw. Boolean recursors emit conditionals. Erasure failures
retain their declaration name. Unsupported runtime folds retain the existing
refusal rather than changing captured values.

The implementation, compact fixtures and README increment changes 24 files:
837 additions and 177 deletions (660 net lines). New focused modules contain
194 lines for context refinement, 195 for equations, 88 for logical primitives
and 67 for iota reduction. Match shrinks by 37 net lines. No broad suite was added.

### Qualification

**[Linux run 38165240831](https://github.com/dwijayuda/pskernel/actions/runs/38165240831) passed**
at exact source `6b6eb2b5c08ee6422103b9e1b6bd5cd79b5b5142`, job `114546331097`.
Toolchain: native Lean 4.35.0-rc4,
`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`;
profile `pscv0-v7-native-bounded/9`.

Native compilation, unchanged 28 parser cases and the compact semantic batch
passed: three checked programs and 39 phase-specific refusals.
Official Lean accepted the expanded 146-declaration composite, the existing
five-declaration instance/Except program and the isolation input.

The same composite now covers dependent context values and let definitions,
symbolic/fixed vector tails, zero-length case elimination, repeated-index
contradictions, omitted Boolean-indexed constructors, direct Boolean matching,
a dependent-context proof and recursive dependent state. Only three refusal
inputs were added: missing feasible branches, satisfiable repeated indices and
an incorrectly refined result. Existing stale-recursion and captured-fold
refusals still pass.

CLI emission, TypeScript 7.0.2 strict compilation and JavaScript execution passed.
The eight added runtime results are 74, 74, 71, 71, 85, 91, 94 and 74.
The import guard reports 78 portable / 84 native closure modules, excluding
pskernel-core. Cached source rebuild: 8,120 ms; unchanged build: 482 ms.
CLI observations: parse 9 ms, elaborate 9 ms, prepare 18 ms, official kernel
15 ms, erase 20 ms, emit 3 ms; checked prelude initialization 2 ms.
These are compact-program observations, not a general performance benchmark.

Four preceding runs remain failed. The first identified reserved native Lean
identifiers and the new IR visitor case. The next exposed the old recursion
fallback boundary. Two subsequent runs passed official checking but stopped
during runtime erasure; declaration diagnostics located the proof-binder
representation mismatch. The shared implementation paths were corrected.
Acceptance assertions were not weakened and fixtures were not expanded during
these corrections. Existing unrelated unused-binding warnings remain.

### Explicit limits and next work

Fixed-index matching with a major-dependent result/context still requires
heterogeneous transport and is refused. Injectivity projections currently cover
homogeneous fields of nonindexed index constructors. Nested/multiple patterns,
arbitrary runtime recursor lifting and broader well-founded recursion remain
pending. Indexed structural recursion still requires distinct explicit local
index parameters; not every dependent recursive context is supported.

Source universes/Prop families, mutual/indexed nested data, erased/existential
constructor fields and runtime Type/Prop indices remain outside this profile.
Full imports/visibility, global classes/instances, wider proof automation and
contracts remain pending. This is a bounded native semantic/runtime milestone,
not full v7 conformance or self-host qualification.

Main was verified at `748ee630e43ee1a89643cbc8cec3e31087788b08`;
M1 base at `b4bd7e7d6c48443e56eaf96099515a29a83982bf`.
PR #109 remains draft. This commit records evidence only; the qualified source
is the exact commit above. Older records retain their historical boundaries.

---

# PSC0 AI WORK STATE — native dependent matching and indexed recursion

## 12 October 2026 — recursor-driven dependent branch elaboration

Active branch: `psc0/pscv0-v7-native-lean-v1`; draft PR #109.
The user's requested next substantial milestone is implemented and qualified
within the boundary below. Compiler source remains native `.lean`. Work used
GitHub source operations and Linux cloud CI, without local checkout/build/tests,
pskernel-core, compiler-source generation, self-hosting or kernel implementation
changes.

### Implemented boundary

`Ps.Elab.Match` now owns motive inference and exhaustive constructor matching.
It generalizes distinct local indices and the matched local value in the expected
result type. Each branch opens its constructor fields, recursive hypotheses and
conclusion from the admitted recursor's actual minor telescope. The previous
independent reconstruction of constant branch/IH types and post-hoc structural
minor rewriting are removed.

Fresh local let aliases refine outer index/major names only when a pattern binder
does not shadow them. Closing a branch inlines these aliases. Original dependent
locals keep their original types; the compiler does not silently retype evidence.

Structural self-calls are checked as Core arguments against the child's family
indices and direct recursive field. Computed child indices are accepted.
Invariant arguments remain definitionally equal, and their types must be
independent of varying indices/major. Changing-state normalization recognizes
family indices and composes with this mechanism for independent state.

`Ps.Erasure.Recursion` owns the runtime recursion plan. Reusing the current
definition replaces both the child major and its runtime index arguments.
The plan checks that minors do not capture the original varying locals. Explicit
recursor applications that require a separately lifted fold therefore fail on
runtime IH use instead of silently changing captured values. The same planner
also serves nonindexed inductives and structure recursors.

Before this evidence entry the increment changes 14 files: 889 added lines and
1,308 removed lines, or 419 net lines removed. Term dispatch shrinks from about
1,831 to 690 lines; Match is 605 lines and runtime Recursion is 67 lines.
No host elaboration fallback or speculative runtime helper generation is added.

### Qualification

**[Linux run 38161224386](https://github.com/dwijayuda/pskernel/actions/runs/38161224386) passed**
at exact source `ac735c2110e9ca4074128b4c4ff5a3e05c481180`, job `114534374952`.
Toolchain: native Lean 4.35.0-rc4,
`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`;
profile `pscv0-v7-native-bounded/8`.

The unchanged 28 parser cases and compact shared-prelude semantic batch passed:
three accepted programs, 36 phase-specific refusals. Official Lean accepted the
119-declaration composite plus the existing five-declaration instance/Except
program and one-declaration isolation input.

The composite now includes dependent vector mapping, refinement of the major
during reconstruction, two-index cell reconstruction, indexed recursion with
changing accumulator state, and a family whose child index is a computed
successor expression. CLI emission, TypeScript 7.0.2 compilation and JavaScript
execution passed; the five added runtime results are 75, 74, 82, 76 and 2.
Four new refusals exercise stale recursive indices, dependent invariant arguments,
a captured explicit recursor fold during emission, and an incorrect dependent
branch result. These extend the existing batch rather than adding a broad suite.

The import guard reports 73 portable and 79 native closure modules, with no
pskernel-core dependency. The final cached build (a fixture-only source delta)
took 2,594 ms; unchanged build took 466 ms. CLI phase observations on this compact
application: parse 8 ms, elaborate 4 ms, prepare 21 ms, official kernel 8 ms,
erase 9 ms, emit 2 ms; prelude 2 ms. These are bounded measurements, not a general
compiler performance benchmark.

Three preceding runs remain failed: two stopped at Lean record layout syntax;
the third built and passed positive official-kernel checks, but the runtime-fold
refusal fixture mistakenly used check-only mode. Its request now enables
emission. No semantic acceptance assertion was relaxed. Existing unrelated
unused-binding warnings remain.

### Explicit limits and next work

Automatic index refinement requires distinct local indices independent of
uniform parameters. Indexed structural calls currently require explicit local
index parameters. Compound/repeated parent indices retain constant result motives.
General dependent-local generalization, impossible-case elimination,
nested/multiple patterns, arbitrary runtime recursor lifting and broader
well-founded recursion remain future work.

Families still end in Type; source universes/Prop families, mutual/indexed nested
data, erased/existential constructor fields and runtime Type/Prop indices remain
outside the selected profile. Full imports/visibility, global classes/instances,
wider proof automation and contracts also remain pending. This is not full v7
conformance, a source-roundtrip qualification or a self-hosting milestone.

Main was verified at `748ee630e43ee1a89643cbc8cec3e31087788b08`;
M1 base at `b4bd7e7d6c48443e56eaf96099515a29a83982bf`.
PR #109 remains draft. This commit records evidence only; the qualified
implementation is the exact source above. Older records below retain their
historical scopes and outcomes.

---

# PSC0 AI WORK STATE — native indexed-data milestone

## 12 October 2026 — indexed families through the checked native pipeline

Active branch: `psc0/pscv0-v7-native-lean-v1`; draft PR #109.
The user requested continued implementation until a substantial milestone,
keeping native `.lean`, clean extensible architecture and minimal tests, without
pskernel-core or self-hosting. Work used GitHub source operations and Linux cloud
CI only; no local checkout, builds, tests, kernel implementation edits or merges.

### Implemented boundary

Constructor result types are retained in the AST, visited after constructor
fields during scope resolution, validated as annotations and preserved by both
source printers. Family result telescopes introduce indices. Constructors must
return their own family with all indices and unchanged uniform parameters;
indexed constructors must state their result. Direct recursive fields carry
their own indices, checked by the same family-application rule.

A dedicated 259-line `Ps.Elab.Data` module replaces the approximately 980-line
data block in general declaration elaboration. The binder module provides a
bounded Core telescope opener retaining its terminal body, plus common binder
closure operations. Data admission, constructor checking and recursor generation
reuse these operations. A motive receives every index and then the major.
Constructor conclusions and induction hypotheses instantiate that same motive.
Existing nonindexed and selected nested-data behavior uses this path too.

Ordinary exhaustive constructor matches now admit indexed families with constant
result motives. Erasure removes indices from nominal runtime type arguments
while preserving constructor runtime fields. Both special application completion
and recursor lowering use one metadata-based arity calculation.
Indexed runtime IH replacement is disabled: the old nonindexed optimization
cannot accidentally reuse stale index arguments.

Global references now instantiate declared universe parameters with fresh
constraints resolved by arguments and expected types. This supports explicit
polymorphic recursor use, including induction proofs. Source universe commands
remain pending. Compiler diagnostics retain specific inference and erasure
failure categories instead of discarding them.

The implementation/source-documentation delta before this evidence entry is
605 additions and 1,258 deletions across 22 files, or 653 net lines removed.
The general declaration module is now about 615 lines. No host elaborator fallback,
alternate kernel or generated compiler source was introduced.

### Qualification

**[Linux run 38159768970](https://github.com/dwijayuda/pskernel/actions/runs/38159768970) passed**
at source `93ba44679ecce746ea1e64754baa597dbe3d76e8`, using native Lean 4.35.0-rc4
(`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`), profile
`pscv0-v7-native-bounded/7`.

The unchanged 28 parser cases and existing three accepted semantic programs run
in one process with a shared checked prelude. The composite now admits 99
declarations, adding an indexed vector, a two-index cell, construction, exhaustive
matches and a polymorphic indexed induction theorem that actually uses its
recursive hypothesis. Four new rejection inputs cover nonuniform parameters,
a missing indexed constructor result, a wrong result family and an index type
mismatch. The compact batch has 32 phase-specific refusals.

Native build, all official-kernel submissions, CLI emission, TypeScript 7.0.2
compilation and JavaScript execution passed. The added runtime results are
71, 72 and 73. The closure inventory has 71 portable and 77 native modules,
with no pskernel-core dependency.

Measured final cached source rebuild: 7,722 ms; unchanged build: 476 ms.
CLI parsing took 4 ms, elaboration 2 ms, bridge preparation 5 ms, official
kernel checking 6 ms, erasure 6 ms and emission 1 ms; prelude initialization
took 1 ms. These are observations on the compact application, not a broad
performance benchmark. Existing unrelated unused-name warnings remain.

Four preceding bounded runs identified compilation corrections, missing global
universe instantiation, and inconsistent recursor arity ownership. Those issues
were resolved in the shared implementation paths; the final run above passed.
The test set was not broadened during those corrections.

### Remaining language work

Dependent motive inference, contextual index refinement, impossible-case
elimination and indexed structural/runtime recursion remain pending. Indexed
recursive hypotheses work in checked proofs, as exercised here; they are not
yet runtime recursion support. Families still end in `Type`; source universes
and Prop families, mutual/indexed nested data, deriving, structure defaults and
inheritance remain future work. The runtime backend retains its existing
restrictions on erased/existential constructor fields and parameter kinds.
Full imports/visibility, classes/instances, wider proof automation, contracts and
other v7 milestones remain pending. No full-v7 or source-roundtrip claim.

Main remains `748ee630e43ee1a89643cbc8cec3e31087788b08`; the M1 base remains
`b4bd7e7d6c48443e56eaf96099515a29a83982bf`. PR #109 remains draft.
The next commit records this evidence only. Older records below apply to their
own exact commits.

---

# PSC0 AI WORK STATE — native v7 data declarations

## 11 October 2026 — shared v7 syntax for structures and inductives

Active branch: `psc0/pscv0-v7-native-lean-v1`; draft PR #109.
The user requested continued native `.lean` implementation, clean extensible
architecture and minimal checks, without pskernel-core or self-hosting.
Work uses GitHub source operations and Linux cloud CI; no local checkout,
build or tests.

The new 94-line `Ps.Syntax.Pscv0.Data` module replaces the remaining legacy
structure/inductive declaration dispatch. Data headers and constructor parameters
call the shared declaration telescope reader; annotations call the rich v7 term
reader. Interleaved explicit/nonexplicit groups, grouped native parameters,
named applications in types, quantified annotations and explicit constructor
defaults now reach the existing semantic compiler through the same paths as
value declarations.

Structure fields retain newline separation and the selected native named-group
forms. Their one annotation stays outside every name in its group. They use the
shared binder-entry reader with defaults disabled and separate field delimiter
ownership. Native field grouping is grounded in the pinned RC4
[`structExplicitBinder`, `structImplicitBinder`, `structInstBinder` and `structSimpleBinder`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Parser/Command.lean).
The existing scope walker, binder elaborator, constructor metadata,
record/projection operations and recursor lowering are reused unchanged.
No second data elaborator, Core representation or kernel implementation was added.

**Qualified in [Linux run 38156960316](https://github.com/dwijayuda/pskernel/actions/runs/38156960316)**
at source commit `f6b8f12e80866293bd7210ad0ebb2e453b5b1a49`, native Lean 4.35.0-rc4
(`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`), profile
`pscv0-v7-native-bounded/6`. The first run passed.

The 28 existing parser cases remain unchanged. The same three accepted semantic
programs now include a grouped structure with parameter-shadowing field names,
quantified field types, expected record lambdas and projections; and an inductive
with interleaved/grouped parameters, grouped implicit constructor fields,
a quantified default argument and constructor matching. The composite admits
85 declarations. Its emitted runtime returns 61 and 62 for the two added results.
Only three refusal inputs were added: adjacent explicit data groups, a nullary
constructor group and comma-separated structure fields. The batch now has
28 phase-specific refusals and still shares one checked prelude.

Native compiler/check builds, official kernel acceptance, CLI emission,
TypeScript 7.0.2 compilation and JavaScript assertions passed.
The source inventory has 70 portable and 76 native closure modules, including
the new reader and excluding pskernel-core.
The Lake root change gave this run a fresh cache key: clean build 39,367 ms;
immediate unchanged build 516 ms. CLI application parsing took 2 ms,
elaboration 2 ms, bridge preparation 4 ms, official kernel checking 4 ms,
erasure 5 ms and emission 1 ms; prelude initialization took 2 ms.
These are compact-workload observations, not broad performance claims.
Existing unrelated unused-name warnings remain.

Data support is still limited to nonindexed types in `Type`. Constructor result
annotations, deriving, structure field methods/defaults and inheritance remain
pending. The richer declaration source-printing/roundtrip milestone is not
claimed. Imports, universes, global classes/instances, dependent matching, proof
automation and broader v7 semantics also remain future work. No compiler `.ps`
generation, self-hosting, kernel suites or Windows tests were run.
Main and the M1 base branch remain unchanged; PR #109 remains draft.

The following evidence commit changes this document only. Older records below
are historical and apply to their exact source commits.

---

# PSC0 AI WORK STATE — native v7 binder groups

## 11 October 2026 — shared annotation scope for multi-name native groups

Active branch: `psc0/pscv0-v7-native-lean-v1`; draft PR #109.
The user requested multi-name native binder groups with correct annotation scope,
authored in native `.lean`, with clean architecture, minimal checks, no
pskernel-core and no self-hosting. Work uses GitHub source operations and Linux
cloud CI; no local checkout, build or tests.

The binder head now represents a nonempty group: one first name, additional names,
binder kind and span, paired with one annotation in the existing recursive AST.
A unary construction helper preserves existing callers. Native group parsing
retains this boundary in lambdas, quantifiers (including bare `forall A B : Type`),
explicit dependent arrows, variables and nonexplicit value-declaration parameters.
Declaration explicit parameters still require individual comma entries.

The scope walker visits the annotation before adding any group name. The shared
elaborator elaborates a non-placeholder annotation in that outer context once,
then introduces each name with the resulting Core type. Whole-domain inference
holes obtain their own expected domains per name. Thus a grouped lambda such as
`fun (T: Type) (T x: T) => x` retains the outer type identity in both inner
parameter types. Expected telescopes still advance one actual parameter at a time.

Section dependency selection filters names within groups, preserving shared
annotations and dependency order without capturing unused siblings. Inclusion,
instance eligibility and fixed recursive section arguments all use the same name
enumeration. The recursion walker respects group scope; normalization splits
groups only after renaming annotations to inaccessible parameter identities.
Constructor metadata counts elaborated fields rather than source groups.

Shared native binder printers preserve all group names. The declaration-only PSC
printer explicitly refuses grouped explicit parameters requiring a future
scope-preserving lowering. There is no compiler-source translation milestone here.

**Qualified in [Linux run 38156237259](https://github.com/dwijayuda/pskernel/actions/runs/38156237259)**
at source commit `8c0504c4ba8c9f8a6118bcf65e9803824a6dd2af`, using native Lean 4.35.0-rc4
(`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`), profile
`pscv0-v7-native-bounded/5`. The first run passed.

The 28 existing parser cases remain unchanged. The same three accepted semantic
programs now cover grouped local/global shadowing, bare quantifiers, dependent
arrows, heterogeneous inferred lambda parameters, implicit/strict implicit groups,
selective section capture and changing-state recursion. The composite application
admits 72 declarations, including its generated recursive worker. The existing
five-declaration instance/Except case now uses grouped proposition variables.
Three new refusal inputs check declaration-vs-native grammar, an unavailable
outer annotation name and duplicate names within a section-variable group,
bringing the compact batch to 25 phase-specific refusals.

Native compiler/check binaries, official kernel acceptance, CLI emission,
TypeScript 7.0.2 compilation and JavaScript runtime assertions all passed.
The inventory remains 69 portable and 75 native closure modules, no pskernel-core.
Measured cached source rebuild: 17,613 ms; unchanged rebuild: 490 ms.
CLI application parsing took 2 ms, elaboration 1 ms, bridge preparation 3 ms,
official kernel checking 3 ms and erasure 4 ms. These are small-workload
measurements, not a broad performance benchmark. Existing unrelated unused-name
warnings remain. The following evidence-recording commit changes this document only.

Remaining binder limitations: pattern binders, lambda result annotations and
automatic insertion of omitted implicit lambda binders. Inductive/structure source
headers retain the selected legacy data grammar. The older Lean-source parser,
full source translation and roundtrip qualification remain outside this native
development increment. Imports, universes, global classes/instances and the other
broader v7 milestones remain pending. No complete-v7 or self-hosting claim.

The following records are historical and apply to their exact source commits.

---

# PSC0 AI WORK STATE — native v7 quantified types and shared binders

## 11 October 2026 — native binder syntax through shared semantics

Active branch: `psc0/pscv0-v7-native-lean-v1`; draft PR #109.
The user authorized continued native `.lean` implementation with clean portable
architecture, minimal checks, no pskernel-core and no self-hosting. Source changes
and qualification use GitHub operations and Linux cloud CI.

The v7 binder module now accepts annotation/value readers as callbacks. Declaration
parameters, variable commands, native lambda/quantifier groups and explicit
dependent arrows use the same entry/group grammar. Declaration comma groups and
defaults retain their own policy; native term binders cannot introduce a hidden
Unit or accept declaration commas. Parameter accumulation now uses a reversed
accumulator instead of repeatedly appending the growing prefix.

Implemented `forall`/`∀`, `fun`/`λ`, `=>`/`↦`, Unicode strict implicit
`⦃...⦄`, and anonymous `[ClassTerm]` binders. Quantifiers feed the existing
forall AST and ordered binder elaborator. Anonymous instances have inaccessible,
source-local names and use existing lexical instance synthesis and section
generalization. A common printer renders these binders anonymously and preserves
binder kinds in quantified source. No new Core expression, proof algorithm,
host elaborator fallback or kernel implementation change is involved.

**Qualified in [Linux run 38155402871](https://github.com/dwijayuda/pskernel/actions/runs/38155402871)**
at source commit `7c80638275e979689473d5bf43ba9f2d054edd59`, with native Lean 4.35.0-rc4
(`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`), profile
`pscv0-v7-native-bounded/4`. The first run passed.

The existing 28 parser cases passed unchanged. The compact semantic batch still
uses three accepted programs and one checked immutable prelude, now with 22
phase-specific refusals. The first application has 54 declarations and checks
quantified explicit/implicit polymorphism, dependent arrows and Unicode aliases.
The existing Except do program also checks anonymous instances in declarations,
lambdas, quantifiers and section variables (five declarations). Four new negative
inputs reject lambda declaration commas, nullary lambdas, a missing quantifier
comma and an unavailable instance.

The official kernel accepted both programs and the request-isolation case. The
CLI checked and emitted the 54-declaration application; pinned TypeScript 7.0.2
compilation and JavaScript runtime assertions passed. The import inventory stays
at 69 portable modules and 75 native closure modules, without pskernel-core.

Measured cached source rebuild: 14,612 ms; immediate unchanged build: 480 ms.
For the CLI fixture: prelude setup 1 ms, parsing 1 ms, elaboration 1 ms, bridge
preparation 2 ms, official kernel checking 2 ms, erasure 2 ms, emission 1 ms.
These are compact-workload measurements, not a large-program performance claim.
The affected compiler source has 194 added and 223 removed lines. The following
evidence-recording commit changes only this work-state document.

Remaining binder limits: one name per native group, one final bare quantified
binder, lambda result annotations/pattern binders and automatic insertion of
omitted implicit lambda binders. Multi-name typed groups require shared annotation
scope in the AST; copying their annotation into unary entries could capture an
earlier name. These forms remain explicitly unsupported. Global class/instance
declarations, universes, imports and the wider v7 milestones remain pending.
There is no full-v7, self-hosting or printer-roundtrip qualification claim.

The following records are historical and apply to their exact source commits.

---

# PSC0 AI WORK STATE — native v7 command scopes and defaults

## 11 October 2026 — ordered scopes and optional parameters

Active branch: `psc0/pscv0-v7-native-lean-v1`; draft PR #109.
The user authorized namespace/open/section scopes and default arguments in native
`.lean`, with minimal checks and no `pskernel-core` or self-hosting. Work continues
through GitHub source operations and Linux cloud CI only.

The ordered program AST retains namespace/section/end/open/variable/include/omit
commands independently of the legacy flat translation API. The shared source
preparation owns lexing budgets, selected do parsing and hygiene. A capture-aware
Scope traversal qualifies names and collects section dependencies; Command applies
scope transitions and admits ordinary declarations through the existing elaborator.
Local binders shadow globals, namespace ancestors are searched before unique open
candidates, and `_root_` bypasses source scope. Generated Unit/Except helpers use
rooted names. End restores variables, opens and inclusion state; declarations remain.

Definitions generalize section variables used in their headers or bodies;
theorems generalize header dependencies, explicitly included variables and eligible
instances. Dependency selection uses ordered reverse/forward passes. Variables are
typechecked at declaration time; omitted/unrelated parameters are not carried into
ordinary signatures. Selected structural self-calls receive fixed captured explicit
parameters before existing recursion elaboration. Shadowed captured parameters
are refused rather than rebound.

Defaults are checked at declaration scope and represented by canonical
`optParam` type applications. The portable prelude contains the same reducible
definition as RC4 Init.Prelude, checked by the official native kernel. Application
instantiation substitutes preceding arguments into dependent defaults; no source
reparsing, call-site name lookup, side metadata table or kernel change is involved.
Named/positional/default/implicit arguments share one ordered engine. Expected
function types retain partial applications; explicit empty invocation completes
defaults and at most one required Unit argument. Final `function f()` declaration
groups lower to a required Unit parameter. Diagnostics retain the declaration name.

**Qualified in [Linux run 38154247902](https://github.com/dwijayuda/pskernel/actions/runs/38154247902)**
at source commit `8a0806345b2d7cdfc2942953934193e1fffc70ff`, with native Lean 4.35.0-rc4
(`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`), profile
`pscv0-v7-native-bounded/3`.

The unchanged 28 parser cases passed. The existing semantic batch now contains
three accepted programs and 18 phase-specific refusals; it still shares one
checked immutable prelude. One 43-declaration application covers namespace
ancestors/opens, defaults closed over earlier parameters and declaration scope,
expected-result completion, preserved function values, section dependency/order,
local shadowing, theorem include/omit, fixed recursive parameters and nullary/Unit
completion. The existing Except do case now runs inside a namespace. The CLI
checked and emitted that same composite application; TypeScript 7.0.2 compilation
and JavaScript assertions passed. The source inventory found 69 portable modules
and 75 native closure modules, without pskernel-core.

Measured cached incremental build: 6,010 ms; immediate unchanged build: 504 ms.
For the CLI fixture, prelude setup took 2 ms, elaboration 1 ms, official kernel
checking 2 ms and erasure 2 ms. These small-workload observations are not a
large-program benchmark; zero-millisecond phases are timer resolution.
The following evidence-recording commit changes only this work-state document.

Selected remaining limits: module imports/visibility, universe commands, full native
binder grammar, rebinding active section variables, open modifiers/expected-type
overloads, autoParam, general CoeFun, named recursive self-calls and recursion under
shadowed captured section parameters. Source translation of scoped programs is
explicitly refused until that printer has its own ownership. This increment does
not claim complete v7 or compiler self-hosting. The import/source profile guard
is not a full portable authoring-profile verifier.

The following records are historical and apply to their exact source commits.

---

# PSC0 AI WORK STATE — rich native v7 terms

## 11 October 2026 — shared lexical scopes, applications and expected types

Active branch: `psc0/pscv0-v7-native-lean-v1`; draft PR #109.
The user authorized continuing v7 in native `.lean`, starting with rich syntax
and shared elaboration. No `pskernel-core`, compiler-source `.ps` generation,
self-hosting, local builds/tests or Windows runs.

Implemented: richer term nodes preserve labeled calls, empty invocation, ascription
and inference holes. Shared binder/application engines implement expected lambda
domains, telescope-order argument checking, named arguments, implicit insertion
and the selected one-required-Unit completion. Lexical scope exit retains meta
constraints and fresh local identities. Shared elaboration is split into Basic,
Binders, Application and the remaining Term dispatcher/control implementation.

**Qualified in [Linux run 38151599948](https://github.com/dwijayuda/pskernel/actions/runs/38151599948)**
at source commit `0c7aa371e6102b25c34ed689191c186107fd03b0`.
Native Lean 4.35.0-rc4 compilation, the 28-case parser corpus (19 positive,
9 negative), three accepted semantic programs and 11 phase-specific refusals,
CLI emission, TypeScript 7.0.2 compilation and JavaScript execution all passed.
The named-call parser case moved from refusal to acceptance because it is now
implemented; unknown/duplicate names and invalid argument order have specific
refusals. One 14-declaration application covers the new accepted behavior.

The shared type-only result is used for binder, ascription, local-let and ordinary
declaration annotation inference, including inferred annotations. Declaration
closure still rejects unresolved term/universe metavariables before preparation.
The exact source inventory is 65 portable modules and 71 native closure modules.
The actual native identity remains checked against the pinned RC4 version/commit.

Cached incremental rebuild: 5,991 ms; immediate unchanged rebuild: 383 ms.
These observations concern this compact workload, not a cold build or full v7
performance benchmark. The evidence-recording commit changes documentation only.

Scope is lexical term/declaration binders, not namespace/open/section semantics.
Defaults, general CoeFun, named recursive self-calls, full lambda binder grammar,
richer dependent matching, automation/contracts and full v7 remain pending.
Historical evidence below applies only to its recorded source commits.

---

# PSC0 AI WORK STATE — native Lean v7 implementation

## 11 October 2026 — native development foundation

The user selected the existing portable semantic compiler, authored/run natively
in Lean and checked by official Lean. Implementation stays in `.lean`; compiler
`.ps` generation and full self-host qualification are deferred to the final
migration milestone. No `pskernel-core` development/tests or slow fallback.

Active branch: `psc0/pscv0-v7-native-lean-v1`, based on
`b4bd7e7d6c48443e56eaf96099515a29a83982bf`.
The new `v7-native/` workspace uses exact Lean 4.35.0-rc4, imports shared compiler
sources, and connects the active v7 parser to the existing semantic compiler,
canonical admission bridge, official native kernel and TS backend. Native batches
reuse one checked prelude with independent request environments. Historical 4.34
bootstrap/provider identities remain intact. Old M1 regeneration workflows are
manual-only on this branch; a dedicated incremental native Linux job replaces
them in ordinary work.

**Status: native development foundation qualified on Linux.**
[Run 38150035834](https://github.com/dwijayuda/pskernel/actions/runs/38150035834)
passed at executable/source commit `7672b5f9f0c905fc19cdf251ac080f1a2e7ac072`:
native compiler/check executable build; 28 existing M1 parser cases; three accepted
programs and four phase-specific refusals with batch isolation; CLI emission;
pinned TypeScript 7.0.2 compilation and JavaScript runtime. Source inventory found
61 portable and 67 native closure modules, with no `pskernel-core`. Actual runtime
identity is checked against Lean 4.35.0-rc4 commit
`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.

The cached incremental build took 1,943 ms and the immediate unchanged build
424 ms. The small CLI fixture initialized its prelude in 1 ms and recorded 1 ms
for kernel checking; 0 ms phase values mean millisecond timer resolution, not zero
work. These are small-workload observations, not a cold-build measurement, a
large-program benchmark, or a speedup ratio against earlier compiler regeneration.

The initial target deliberately rejects module imports until v7 module semantics
land. This is a bounded compiler development foundation, not full v7 conformance
or a portable compiler fixed point. Rich source representation, scopes/applications
and expected types, dependent patterns/recursion, general typed control, proof
automation/contracts and the Standard/P1 environment remain semantic milestones.
Elaborator/backend errors currently retain phase-level codes, not rich source
diagnostics. Do not infer these capabilities from host Lean's available features.

[Draft PR #109](https://github.com/dwijayuda/pskernel/pull/109) contains this change.
The work-state update after the passing run changes documentation only.

**Corrected predecessor evidence:** M1 run
[38144002557](https://github.com/dwijayuda/pskernel/actions/runs/38144002557)
passed the bounded 21-module, one-v7 versus five-v7 source comparison at the base
commit. Candidate preparation 587,868 ms; emission 370,963 ms; total 960,809 ms.
The 18 positive/10 negative parser cases are retained, with no inferred broader
language conformance.

Current work uses GitHub source operations and Linux cloud CI only. No local
compiler builds/tests, Windows tests, independent kernel suites or kernel-source
changes. Source-profile and timings artifacts distinguish parser checks, native
kernel acceptance, runtime behavior and eventual self-hosting evidence.

See [native development commands and boundaries](v7-native/README.md).
The entries below are preserved historical records; their pending statuses and
source-authority policies may be superseded by this entry.

---

# PSC0 AI WORK STATE — v7 M1 parser ownership candidate

## 11 October 2026 — M1 implementation in progress

The user approved continuation of the systematic v7 compiler roadmap after the implementation audit. Active implementation branch: `psc0/pscv0-v7-m1-parser-ownership-v1`, based on `0e8996d2aff414986f04dbc68c2689aaf118fb48`. M1 introduces a v7-owned term dispatcher with explicit annotation assignment ownership, reuses predecessor token/AST/category-neutral readers, and preserves historical compiler implementation files. Declaration types, nested immutable let annotations, theorem term proofs and supported typed do lets use the reader. The declaration scanner is removed so nested let assignments are parsed grammatically.

**Status: candidate, not qualified yet.** Linux syntax/foundation typecheck and an 18-positive/10-negative shared native/generated parser corpus are being introduced. Generated compiler qualification is still pending. No full v7 conformance, full portable compiler self-host fixed point, performance improvement, independent kernel admission or Windows execution is claimed.

**Correction to the historical pending text below:** Linux five-v7-source closure run [38134451122](https://github.com/dwijayuda/pskernel/actions/runs/38134451122) at the base commit succeeded: five actual v7 modules plus fifteen retained Lean modules (20-module frontend/foundation closure), identical admissions/TS/JS and passing Linux runtime. Preparation 497,482ms, total 819,997ms. TS SHA `407fc682eb1798adb48701b9310edff6282bf16d24f564d494272a41840f29b3`; JS SHA `8fc8f9cacedf56e245c11ba094e58c254ae8550eea1f417a52a83816165ce9a5`. This was not the complete compiler.

Policy remains GitHub-only source operations and cloud Linux compiler CI; no local compiler builds/tests, Windows execution, kernel modifications, independent kernel/metatheory/conformance/differential suites or kernel rebuilds. v7 is the sole prospective .ps edition; original release assurance remains separate. New parser source invalidates reuse of the old frontend cache as current-source authority.

The following sections are retained historical work-state entries and may contain superseded pending statuses.

---

# PSC0 AI WORK STATE — five v7 source modules in Linux-only 20-module compiler-closure candidate

## 11 October 2026 — new active source-closure milestone

**Policy:** only Linux compiler packages are tested now; **no Windows tests** and **no independent kernel/PSKernel/metatheory/arena tests**. Windows is a static portability pattern only and must not be described as a runtime-qualified platform. PSCV0 v7 is the sole forward-looking .ps grammar; no old edition parser fallback. Retain the original kernel and release assurance design without executing it in this development loop.

**Latest real Linux source graph:** [run 38134033244](https://github.com/dwijayuda/pskernel/actions/runs/38134033244), commit c1f6b97419f85de0eb4dd09755108e1a01ab6e27, **SUCCESS**. Nine scenario combinations with Ps.Foundation.Source, Ps.Syntax.Cursor, Ps.Syntax.Token and Ps.Foundation.List alternate v7 .ps sources each yielded byte-identical canonical compiler admissions and TypeScript7: admissions SHA a8eb6c2ef657200072ba314cc45bd4df9b668a477d2239fca3a2cee9b33fa042, TS SHA 7e5682ea38342adf20b252a3eb668d727849100a22f6b2b0ff71a853b812d447. Four-module graph 65,401ms measured, 21 unique in-memory preparation states, 15 prefix reuse hits out of 36 source steps and 8 parsed module forms. Typed dependent Cursor and Token compile under either Source variant; Linux TS7/JS runtime passed. **No independent kernel/Windows tests.** An initial source parser `List Char :=` ownership issue was addressed using supported v7 adjacent `List(Char)` in one local type; the broader type-vs-field assignment parser context remains a recorded future frontend improvement, not an old-language compatibility mode.

**Current one-shot compiler-closure branch:** `psc0/pscv0-linux-source-closure-v1`, branched from that exact Linux graph-green commit. New [source selection manifest](pscv0-linux-source-closure.json) chooses all FIVE v7-authored compiler modules together: Source, Cursor, Token, Translate and List. The remaining FIFTEEN unchanged syntax/foundation modules retain their existing Lean source. New [one-pass Linux-only compiler builder](tools/abi/compiler-linux-closure.mjs) consumes the exact qualified 20-module source artifact from [38128357665](https://github.com/dwijayuda/pskernel/actions/runs/38128357665) as the generated current v7 parser. It validates all source SHA-256 identities and maps v7 modules to the historical order; uses closed AST transfer and unchanged compiler elaboration; outputs full 20-module canonical admissions and TypeScript7/JS **in one pass**. Requirement: exact bytes of all three products must match the previous already-qualified a640a2d2 one-module artifact. This is a **compiler-only product differential** and must never inherit the old artifact's independent checker/release proof claim. [Architecture and deferred Windows/kernel boundaries](docs/PSCV0_LINUX_FIVE_SOURCE_CLOSURE.md).

**Status: pending its own CI.** A new .github/workflows/psc0-pscv0-linux-closure.yml contains ONE Ubuntu job with no Windows runner, no pskernel checker imports, no kernel proof tests; it reuses immutable exact npm/toolchain artifacts. The full 20-module source closure remains an expensive **milestone-only** test; the existing sub-2-second fast-process compiler and cached graph CI remain primary routine development tools. **Do not mark five-module full source authority complete unless exact new Linux result succeeds.** Do not claim full 64-module compiler self-host fixed point or v7 general conformance.

**Next:** inspect the actual Linux-only full compiler closure, identify any first typed semantics/TS7 mismatch (do not change acceptance to make tests pass), and preserve its exact output/progress evidence. Then reconcile with concurrently advancing primary branch via non-force expected-HEAD operations only if user accepts a compiler-source promotion; leave kernel source/history untouched. Windows stays pattern-only until a future explicit request.

---

# PSC0 AI WORK STATE — v7 Cursor local-type grammar boundary

## 11 October 2026 — latest attempted dependent compiler source

**Policy remains:** only Linux compiler tests; Windows is static portability review, not actual tested status. No PSKernel/kernel soundness/metatheory tests or changes in this iteration. V7 alone defines future .ps source language; no old source compatibility.

**Cursor first attempt failed at the source reader, not typed elaboration.** Linux [run 38133808088](https://github.com/dwijayuda/pskernel/actions/runs/38133808088) (source 6687ead5d9d18bd370428745d58cabbb636a738f) completed **failure** in the eighth scenario `cursor-v7-only`, diagnostic `PSCV0-PARSE: := at 19:46; got Char`. The preceding seven scenarios ALL passed with unchanged canonical compiler admissions/TS7 SHA; their earlier [run 38133538760](https://github.com/dwijayuda/pskernel/actions/runs/38133538760) remains fully green. The issue arises when the existing bounded source reader parses `let smaller: String -> Nat -> List Char := ...`: an application lookahead wrongly interprets the terminal `Char :=` as a named-assignment start and stops the type prematurely. This is **a systematic source grammar category ownership problem**, distinct from any actual wrong compiler semantics or kernel issue.

**Current canonical v7 candidate:** use the already admitted explicit adjacent type-call spelling `List(Char)` inside that let binder, to retain the same intended type. Source doc [Cursor v7 grammar issue and plan](docs/PSCV0_CURSOR_V7_SOURCE_CANDIDATE.md) explains that native `List Char` must still be supported in correct v7 expression contexts: a later owned parser must implement proper typed-local and record-assignment delimiters, not permanently narrow the normative v7 grammar. The **new candidate is pending fresh Linux CI** until its full nine-scenario source/typed/admission/TS7 comparisons succeed. Do not weaken tests, edit history, enable old parser fallback, run Windows or kernel tests.

---

# PSC0 AI WORK STATE — fifth source candidate Cursor.ps on Linux-only graph

## Current checkpoint, October 11, 2026

**Explicit user constraints:** Linux CI only. Windows is a *static pattern review*, not an executed compatibility pass. No independent PSKernel/core checker tests, metatheory work or full fixed-point kernel runs in this self-host compiler development loop. The sole .ps language specification remains PSCV0 v7, without prior-edition compatibility.

**Fourth module source qualified at compiler-only graph level:** [38133538760](https://github.com/dwijayuda/pskernel/actions/runs/38133538760), exact source 798f1aefdc59fbdaa75bc4423741e27aec1d0e65, **SUCCESS**. Ps.Syntax.Token.ps (an inductive, function with nested pattern matches, and structure) compiled consistently as either Lean or v7 source in the 4-node Source/Cursor/Token/List dependency graph. All **seven** source combinations yielded byte-identical canonical compiler admission SHA-256 a8eb6c2ef657200072ba314cc45bd4df9b668a477d2239fca3a2cee9b33fa042 and TypeScript7 SHA-256 7e5682ea38342adf20b252a3eb668d727849100a22f6b2b0ff71a853b812d447. Compiler graph **43,694ms measured**, **15 unique prepared prefix states** with **13 actual reuse hits out of 28 steps**, 7 parsed source modules. Linux TypeScript/JS runtime smoke passed, no Windows or independent kernel tests. This remains compiler-only product equivalence, NOT the complete generated self-host compiler or an independently admitted proof output.

**Fifth candidate being attempted:** [Ps.Syntax.Cursor.ps](packages/syntax/src-ps/Ps/Syntax/Cursor.ps), 2 structures/9 functions, genuinely dependent on Source and using Unicode/UTF-8 cursor data, higher-order fuel-recursion lambdas, nested matches, option, records and conditional v7 syntax. [Source review](docs/PSCV0_CURSOR_V7_SOURCE_CANDIDATE.md). The new candidate manifest has four alternative v7 modules: Source, Cursor, Token, List; graph manifest now has **nine** source combinations, including Cursor-v7-only and all-four-v7. The complete graph must still produce identical canonical compiler admission and TypeScript bytes, and the test must run on Linux only. **New Cursor source is PENDING CI; do not count it as qualified until its actual source, elaboration and product results pass.**

**Current evidence distinctions:** Translate.ps remains the first actual 20-module generated bridge qualified in [38128357665](https://github.com/dwijayuda/pskernel/actions/runs/38128357665). Source.ps, List.ps and Token.ps are separate compiler-only equivalent source candidates and are not yet selected in that full bridge. Cursor.ps is still unqualified. This distinction must not be collapsed into claims of a full compiler fixed point. Preserve prior source graph green commit, history and all kernel branches.

**Next:** inspect the Linux-only nine-scenario CI source parser/elaboration/TS outputs. If Cursor genuinely requires an unimplemented v7 surface family, pinpoint the general grammar semantics and revise the architecture/source appropriately rather than weakening tests or enabling old-source fallback. After green, start a source-closure selection plan with incremental dependency topological ordering and full compiler-only source evidence while still deferring kernel and Windows tests.

---

# PSC0 AI WORK STATE — Linux incremental graph passed; Token.ps source candidate

## Active compiler-only development checkpoint — 11 October 2026

**Development policy (user directive):** run **Linux only**. Do not start Windows CI or PSKernel/kernel proof/consistency tests. Windows support is a **static portability-pattern review only** and remains unverified by this branch. Retain separate checked-release gates but do not execute them in the fast compiler loop. PSCV0 v7 remains the sole prospective .ps grammar; no old language reference or compatibility mode.

**Verified incremental source graph:** [Linux run 38133290733](https://github.com/dwijayuda/pskernel/actions/runs/38133290733), source 4e800e57478882616d4da28b3a88734cabdbad1e, **SUCCESS**. Four scenarios covering Ps.Foundation.Source, Ps.Syntax.Cursor, Ps.Syntax.Token and Ps.Foundation.List all produced the **same exact canonical compiler admission and TypeScript7 outputs**, with independent Linux TypeScript/JS runtime smoke. In-memory compiler preparation reused **6 out of 16 dependency preparation steps**, building **10 distinct states**, with **6 parsed source modules**; measured graph script elapsed time **31,209 ms**, excluding CI startup and cached artifact download. All 20 source closure hashes were rechecked before use. No independent kernel or Windows execution. This is a bounded compiler source dependency result, not a full compiler fixed point.

**New candidate being tried:** fourth v7 .ps module [Ps.Syntax.Token.ps](packages/syntax/src-ps/Ps/Syntax/Token.ps), currently **unqualified**; it uses v7 inductive, nested constructor matches and structure grammar. It imports Source and therefore exercises the typed dependency semantics of the Linux compiler graph. [Source candidate plan](docs/PSCV0_TOKEN_V7_SOURCE_CANDIDATE.md). Updated [candidate registry](pscv0-fast-candidates.json) includes Token (3 declarations) alongside Source (2) and List (10). Updated [graph manifest](pscv0-fast-graph.json) adds Token-only, Source+Token and all-three-v7 combinations. The exact new Linux CI must show **seven scenarios with identical full compiler admission and TypeScript output**; do not claim qualification from a previous run.

**Next:** check the generated frontend's actual v7 Token.ps parser and typed constructor-pattern handling under the fast Linux workflow. Any failure is an implementation/grammar boundary to diagnose against v7, not a reason to weaken tests or enable an older .ps source mode. If green, record source SHA/equality and explore v7 Cursor.ps (first lexical runtime source module with dependent Source). Keep the full 20-module generated bridge stable; no kernel build or Windows job.

---

# PSC0 AI WORK STATE — Linux-only incremental compiler preparation graph

## 11 October 2026 — active fast development milestone

**User decision:** only **Linux** compiler tests now. No Windows CI runs and no independent PSKernel/consistency/arena/kernel-metatheory tests in this development phase. Windows is handled as **static portability patterns**, explicitly *not a Windows pass*. Keep production independent-checking obligations intact for a future deliberate release milestone. The sole prospective ProofScript grammar remains complete PSCV0 v7 (reference SHA-256 843940bd7f6a9b286e80b01d8c891a7e01b8868a9de7b05833fce32d49be6cd5); no old source compatibility target.

**Stable baseline (actual evidence):** fast compiler-only run [38131347281](https://github.com/dwijayuda/pskernel/actions/runs/38131347281) SUCCESS, latest code check SHA 0cde1e2e3707e6550431d30e589e785b46fcdc72. The exact cached generated 20-source frontend is from the previously fully qualified 38128357665 bridge at source a640a2d22adeabd4ca7919839a8991667bcc3eae. Separate compiler-only v7 candidates are Ps.Foundation.Source (2 structures) and Ps.Foundation.List (10 recursive definitions); each matched original retained Lean compiler's complete canonical admission/TS7 products byte-for-byte under the same compiler. Ps.Syntax.Translate.ps remains first source module qualified in the actual 20-module generated bridge. Neither other candidate has been promoted into that full source closure.

**New architectural work:** an **in-memory topological source graph** (no disk-state deserialization or checker authority) to prepare dependencies and v7-source variants without repeated elaboration of unchanged prefixes. [Source graph config](pscv0-fast-graph.json): roots Ps.Syntax.Cursor, Ps.Syntax.Token and Ps.Foundation.List. Actual dependency edges are Cursor→Source and Token→Source; List independent. Four variants are historical Lean baseline, List-v7 only, Source-v7 only, and both Source/List-v7. The selected candidate's v7 parser produces a source AST transferred through the validated versioned recipient-owned codec. Each variant must produce identical compiler admissions and TypeScript7 bytes in the **same dependency closure**. Prefix keys include previously selected sources, exact source SHA, module identity, and pinned generator/recipient toolchain; only state values in the single CI JavaScript process are memoized.

**New code, pending validation:** [qualified-cache.mjs](tools/abi/qualified-cache.mjs) checks the same 20 cached source hashes, builder identity and v7 reference, [compiler-graph.mjs](tools/abi/compiler-graph.mjs) calculates a closed import graph and reuses pure compiler state, and [Linux-only graph design](docs/PSCV0_LINUX_INCREMENTAL_COMPILER_GRAPH.md) states source assumptions, Windows portability patterns and no-kernel boundaries. The fast Linux workflow's second pass replaces redundant independent single-module compilations with these four dependent source variants and one TypeScript7/Node JS runtime smoke. **DO NOT claim this new scenario graph passed until live CI confirms it.** Existing three-module candidate evidence is retained separately.

**Immediate next step:** review actual Linux-only fast CI and inspect exact graph admission/TS source discrepancies or runtime errors. Avoid test patches: diagnose wrong source import topology, typed AST correctness, source printer group ownership and correct elaboration environment. If green, record unique/hit prefix counts and measured timings, then migrate Ps.Syntax.Cursor.ps only after confirming dependency-closure semantics and exact v7 grammar. Do not run Windows and do not change kernel.

---

# PSC0 AI WORK STATE — three v7-authored compiler modules, fast development only

## Latest verified checkpoint — October 11, 2026

**Current branch:** psc0/pscv0-compiler-fast-loop-v1. **Sole language reference:** exact PSCV0 v7 SHA-256 843940bd7f6a9b286e80b01d8c891a7e01b8868a9de7b05833fce32d49be6cd5. No backward-compatibility parser or historical language reference is required for new code.

**New observed compiler-only CI:** [run 38131142962](https://github.com/dwijayuda/pskernel/actions/runs/38131142962), source commit 4c79d8854d453b27111e8675cd4240fc2de58112, **SUCCESS**. The one reusable [multi-module source manifest](pscv0-fast-candidates.json) qualified **both** alternate PSCV0 v7-authored source files against their unchanged historical Lean predecessor using exactly the same retained PSC0 compiler, generated v7 frontend and versioned recipient-owned AST schema. Source module: Ps.Foundation.Source, **two structure declarations**, 236 AST nodes, admission stream SHA 976e966131f71d2ab80aac725cd236be1790ca6538d11390202e1532b4269119, TS7 SHA 851d74e325381ee236632853296815c0d1f2e1f4630722bcf1bf68cfd2b47e77, both byte-identical to Lean baseline; 634ms compiler differential. List module: Ps.Foundation.List, **ten generic recursive definitions**, 4,882 AST nodes, admission SHA 88975c455e2d8a69d7123f0a320306c65897e0022fa90b3913eab2f946b0a7b6 and TS7 SHA efa2692bf423d9cbfb7115780d1e299db19a8ee431e4c63d7489ff05e6f37b9d, both byte-identical to Lean baseline; 7,680ms. Total multi-source compiler differential **8,318ms**, excluding CI provisioning/tool installation. **No independent kernel, kernel proof suite, checker conformance or new fixed-point cycle ran.**

**Total bounded source migration evidence so far:** Ps.Syntax.Translate.ps remains the FIRST qualified real 20-module generated bridge candidate ([full Linux/Windows/RC4 run 38128357665](https://github.com/dwijayuda/pskernel/actions/runs/38128357665)); Source.ps and List.ps are SECOND and THIRD *separately checked source-product-equivalence candidates*, NOT selected into that full bridge. Do not aggregate their separate cheap results into a claim of three modules already self-hosting the current full compiler. The original Lean baselines are immutable and still selected outside the bounded first-module candidate.

**Efficiency achieved:** fast compiler-only generated AST -> elaboration -> TS7 -> JS runtime step measured **1,411ms** compiler-process execution on [38131142962](https://github.com/dwijayuda/pskernel/actions/runs/38131142962), full two-module source differential **8,318ms**. Cached 20-module parser remains valid only if all source raw SHA-256 identities match the qualified artifact; any changed frontend source must fail with FAST_CACHE_STALE and require native compiler-source typecheck plus deliberate future regenerated self-host milestone. These are compiler development results; all release-time independent checking/verification obligations remain unchanged but are not executed by this loop.

**Architectural improvement:** migration source candidates are chosen in [pscv0-fast-candidates.json](pscv0-fast-candidates.json) and validated by the ONE generalized [compiler-source-differential.mjs](tools/abi/compiler-source-differential.mjs). It is intended to replace obsolete module-specific test scripts to avoid duplicate logic and chase individual test quirks. Strict exact admissions and TS output compare unchanged. See [fast development design](docs/PSCV0_COMPILER_ONLY_FAST_DEVELOPMENT.md) and [Source candidate evidence](docs/PSCV0_THIRD_MODULE_FOUNDATION_SOURCE.md).

**Completed cleanup:** obsolete single-module List differential runner retired from active tree (history preserved), replaced by the generic source manifest and differential. The consolidated [fast compiler-only CI 38131347281](https://github.com/dwijayuda/pskernel/actions/runs/38131347281) **PASSED** at commit 0cde1e2e3707e6550431d30e589e785b46fcdc72 after cleanup; no independent kernel tests ran.

**Next recommended compiler-only actions:** extend candidate manifest to another useful source family only after verifying its dependency imports and typed environmental closure; build a source-graph-aware, cached preparation prefix for dependent compiler modules; improve v7 source readability/trivia/diagnostic origins without reintroducing older parser compatibility. Deliberately schedule full candidate compiler source authority/fixed-point requalification separately, and avoid independent kernel tests until explicitly requested.

---

# PSC0 AI WORK STATE — manifest-driven v7 compiler-only multi-source migration

## Current checkpoint (11 October 2026)

**Workstream:** self-host compiler packages only. No PSKernel implementation, kernel differential tests, kernel metatheory or independent checker in routine development. Language specification: exact sole PSCV0 v7, no prior ProofScript grammar compatibility.

**Verified second v7-authored compiler module:** [38130835390](https://github.com/dwijayuda/pskernel/actions/runs/38130835390) **SUCCESS** at source d01f9bd470a2fd58ae5bcc09d5cb7993aa4c984d. The conservative Ps.Foundation.List.ps candidate has ten generic recursion/list operations, **4,882** AST nodes and original/candidate compiler products are **byte-identical**: canonical admission SHA-256 88975c455e2d8a69d7123f0a320306c65897e0022fa90b3913eab2f946b0a7b6 and TS7 SHA-256 efa2692bf423d9cbfb7115780d1e299db19a8ee431e4c63d7489ff05e6f37b9d. Baseline Lean 66 physical lines, v7 source 90: **do not claim code-length improvement** from this first conservative conversion. Compiler differential 670ms parse + 5,793ms preparation, excl. runner provisioning. **Zero kernel tests** and no new full fixed point. The initial error from v7's strict APP-02 rule was resolved by using the *actual v7 explicit adjacent type-call syntax*, not by weakening the parser.

**Next architectural milestone, now authored:** a single [closed candidate manifest](pscv0-fast-candidates.json) and [manifest-driven differential tool](tools/abi/compiler-source-differential.mjs) replace individual test harnesses. It handles existing List and new third candidate [Ps.Foundation.Source.ps](packages/foundation/src-ps/Ps/Foundation/Source.ps), two structure declarations. For each module, it validates source identities and correct declaration counts; parses current v7 source with the cached exact source compiler; uses receiver-owned AST transfer; elaborates both the original Lean and v7 source through the same retained PSC0 compiler; compares canonical admission and emitted TS7 byte-for-byte, and reports elapsed time and first differences. This is **compiler-only product equivalence**, not a production verified build. The third candidate is **pending actual cloud CI** and not promoted to authoritative full compiler source.

**Next:** observe fresh rapid compiler-only workflow result for both candidate modules, diagnose any actual AST or source-grammar mismatch at its invariant rather than patching expected outputs. After green, consider the next meaningful source feature family (e.g. typed compiler APIs with source comments and do-based error propagation), but keep parser/trivia/source span obligations explicit. Only later deliberately construct a new 21/22-module generated self-host candidate and fixed-point work with independent release gates, without requiring kernel test runs during the current loop.

**Stable fast-loop baseline:** [38130403756](https://github.com/dwijayuda/pskernel/actions/runs/38130403756) passed **1,723 ms compiler-process** time for 20 source file cache identity, 2,440 existing Translate.ps AST nodes and three compiled TS7/Javascript programs; native source typecheck [38130403714](https://github.com/dwijayuda/pskernel/actions/runs/38130403714) green, both without PSKernel tests. Full generated bridge [38128357665](https://github.com/dwijayuda/pskernel/actions/runs/38128357665) fully green at ABI source commit a640a2d2; this stronger historical result cannot automatically qualify new candidate source identities.

---

# PSC0 AI WORK STATE — fast compiler-only loop qualified; second .ps module candidate

## Active checkpoint (11 October 2026)

**Fast compiler-only inner loop is operational.** At exact commit 2f1d9169b12bd689fa109071a19d3b5cd58708fd, GitHub [run 38130403756](https://github.com/dwijayuda/pskernel/actions/runs/38130403756) **PASSED**. The measured **compiler process** took 1,723 milliseconds, excluding CI provisioning/artifact download and retained compiler installation. It validated all 20 cached frontend source hashes, all 2,440 selected Translate.ps source nodes, exact sole v7 document, source AST transfer, actual compiler elaboration, TypeScript 7.0.2 emission and three JS results 3, 8 and 4. Four v7-only source refusals passed. **Zero** new frontend generation, independent kernel checks, checked-admission provider calls or kernel-proof suites. Reports explicitly state kernel-admission false, not a verified release. The separate [native syntax/foundation CI 38130403714](https://github.com/dwijayuda/pskernel/actions/runs/38130403714) also **PASSED** with five portable source modules, no PSKernel package tests. Both are qualified *development lanes only*.

**Second migration candidate now authored, not promoted:** [Ps.Foundation.List.ps](packages/foundation/src-ps/Ps/Foundation/List.ps) maps the ten existing generic list helper functions from the immutable 66-line Lean file. The v7 source candidate uses typed comma groups, implicit binders, match and application syntax. Its purpose is proving reusable compiler-source migration breadth, **not claiming that mechanical transliteration is shorter**. A new [compiler-only differential](tools/abi/foundation-list-probe.mjs) must parse the candidate with generated PSCV0 JS, reconstruct the receiver-owned syntax ABI, elaborate both the candidate and original Lean source with the same retained compiler and demand exact canonical admissions and TypeScript7 output. The new result is **PENDING CI**. Investigate substantive model/AST discrepancies systematically; do not change tests to accept unequal semantics.

**Efficiency rule:** routine compiler-source/ABI fixes invoke the cached frontend compiler-only tier (currently 1.7 seconds measured compiler process, not total CI wall-clock); changes to the 20-file parser/frontend closure fail closed on stale source hash and require native compiler-source typechecks plus intentional regenerated milestone bridge. The independent kernel/checked release gates remain unchanged and are not part of this development loop.

**No full compiler self-host claim:** only the first Translate.ps module was qualified by the 20-module generated bridge [38128357665](https://github.com/dwijayuda/pskernel/actions/runs/38128357665), and full source-fixed-point C0-C3, general v7 semantics and complete compiler proof work remain later. Preserve user decision of v7 as sole language reference and zero backward-compatibility requirement for older ProofScript source.

---

# PSC0 AI WORK STATE — Compiler-only rapid development loop

## Current checkpoint: 2026-10-11

**User instruction:** for now work on the self-host compiler packages only, prioritize the most efficient iteration path, and **do not run independent PSKernel tests or kernel metatheory tasks in the fast loop**. This is not a release-policy change. PSCV0 v7 remains the sole forward-looking ProofScript language reference; no older .ps grammar compatibility is required.

**Production-like baseline established before optimization:** [full generated 20-module bridge run 38128357665](https://github.com/dwijayuda/pskernel/actions/runs/38128357665), source a640a2d22adeabd4ca7919839a8991667bcc3eae, **overall SUCCESS** including Linux 44 bridge + 12 authoring tests, Windows and Lean RC4 reference proof gate. That exact source imported the generated v7 PSCV0 parser, crossed the validated closed source-AST ABI into the retained compiler without old Lean text reparse, elaborated the first actual Translate.ps module, emitted the checked candidate JS and independently tested the grouped call; no complete compiler 64-module .ps fixed point was claimed.

**Current branch:** psc0/pscv0-compiler-fast-loop-v1, separate from psc0/pscv0-v7-abi-v1. Its new [fast compiler-only design](docs/PSCV0_COMPILER_ONLY_FAST_DEVELOPMENT.md) and [GitHub CI workflow](../.github/workflows/psc0-pscv0-compiler-fast.yml) reuse only that exact full-run surface-bootstrap artifact. A cheap script checks all 20 original source SHA-256 identities and exact retained toolchain, parses the current .ps compiler module, validates and reconstitutes its AST, executes the real PSC0 elaborator/TypeScript7/JS runtime on representative typed programs and writes a timed report.

**No kernel in fast lane:** the script intentionally does not import pskernel-core or call checkCanonicalAdmissions. It may serialize compiler admission data for comparison but does **not** claim an independently checked module. Reports must explicitly carry independentlyKernelAdmitted=false, kernelOrKernelProofTestsExecuted=false, fullV7Conformance=false, fullSelfhostFixedPoint=false. Native source typecheck workflow [compiler-only native](../.github/workflows/psc0-pscv0-compiler-native.yml) builds only PsSyntax/PsFoundation and the five portable language modules when their Lean source changes; it does not run PSKernel tests. Full generated bridge/Windows/RC4 qualifications are reserved for milestones and verified release actions, not routine edits.

**Cache invariant:** any change to one of the 20 cached generated-source Lean modules causes FAST_CACHE_STALE. Never use the previous v7 generated JavaScript bundle as proof of a newly changed parser or old-language fallback. Rerun the full generator intentionally and pin a new immutable artifact after a source-closure change. Changes to the current authored .ps module itself are read directly from GitHub and can receive fast source/AST/typecheck/TS7 runtime feedback while grammar remains unchanged.

**Current acceptance status:** these new fast workflows are created and require their **own** observed CI success before claims of working optimized feedback. The earlier full run and cheap ABI model already passed; the latter had 2,440 selected Translate source nodes and 257 standalone AST nodes. Do not conflate it with a full compiler-source or kernel proof. Preserve all branches/history, current Rust-target proposal on primary and user instructions.

**Next actions:** check the initial fast CI for actual elapsed time and correctness; research any refusal at the parser/typed boundary, not by altering fixture expectations. Keep kernel work separately dormant. Once the fast tier is green, use it to iterate through next cheap v7 grammar/portable source improvements and .ps compiler modules. At promotion explicitly do full source-identity qualification and record actual results before merging.

---

# PSC0 AI WORK STATE — v7 closed AST ABI and generated compiler integration

## Latest milestone, October 11, 2026

**User intent is unchanged:** `psc0/PSCV0_LANGUAGE_REFERENCE.md` revision **v7** is the sole forward-looking `.ps` language specification, SHA-256 `843940bd7f6a9b286e80b01d8c891a7e01b8868a9de7b05833fce32d49be6cd5`; **no backward compatibility** for earlier PSC1, ps-0.9-r3, or older PSCV0 language references is needed. Historical compiler seeds/source and receipts are immutable bootstrap/provenance, not supported new grammar options. No kernel modifications or public/npm compiler switch in this workstream.

**Root-cause run:** [38125532982](https://github.com/dwijayuda/pskernel/actions/runs/38125532982), exact source `6e811feabba89bf8ea3ebbf50916453169d100ed`, completed **failure** after successful generated 20-module bootstrap and eight actual first-module correspondence proofs. The source bridge's newly direct PSCV0 AST failed in retained compiler elaboration with `invalid ProofScript constructor tag` because generated frontend and retained compiler inhabit **separate JavaScript private-Symbol ADT domains**. A direct `PsSyntaxModule` object cannot simply cross between their two module instances. No source/kernal consistency claim follows from this failure.

**Architecture fix:** a closed, pinned, versioned source AST interop codec lives at [`tools/abi/transport.mjs`](tools/abi/transport.mjs), contract `psc0-pscv0-source-ast-transport/1`. It reconstructs recipient-owned `List`/`Option`/syntax-term/declaration union constructors with recipient factories after full source-field, source brand, constructor symbol-identity, depth/list/byte/span/fuel and exact reference validation. It deliberately does not share or forge private Symbols. Its output is still **untrusted syntax**, not a proof token: caller MUST invoke unchanged source elaboration, canonical admissions and independent kernel check. [Architecture/limitations](docs/PSCV0_V7_CROSS_RUNTIME_AST_ABI.md).

**Verified cheap real cloud evidence:**
- [38127436381](https://github.com/dwijayuda/pskernel/actions/runs/38127436381) passed inspecting actual generated 20-module artifact and retained compiler exports; mismatched Symbol identities confirmed. This is empirical runtime/ABI source analysis, not a proof that all constructs work.
- [38127922986](https://github.com/dwijayuda/pskernel/actions/runs/38127922986) **passed** validating/rebuilding **257** typed source nodes of v7 `(add(1))(2)`; existing retained compiler elaborated it, independent kernel accepted canonical admissions, TypeScript emitter produced output **without an old Lean text parse**; wrong-module tags and extra fields were rejected.
- [38128089427](https://github.com/dwijayuda/pskernel/actions/runs/38128089427) **passed** source schema coverage on the exact authoritative `Ps.Syntax.Translate.ps` module: **2,440** AST nodes, source SHA-256 `938288af9c8476d592fc69c4e6f2c01ecb8e1f371fdd5bac1f789a3097710428`. It did **not** run that module's full prepared prefix/elaboration in isolation.

**Now integrating the real bounded compiler source** on `psc0/pscv0-v7-abi-v1` (forked from `psc0/pscv0-v7-app-model-v1` commit `6e811fe...`). The generated candidate builder now decodes the actual `Translate.ps` source AST with versioned source/runtime identity; passes **recipient-owned** `PsSyntaxModule` to pure `psCompilerPreparationStepParsedWithOrigins`; leaves readable Lean as independently checked projection; adds precise ABI receipt to build-report, source-content/no-fallback enforcement and generated JS/Windows APP-04 runtime/checker test. All prior 43 bridge and 12 authoring tests, Lean RC4 proofs, full builder toolchain, semantic checks and immutable 69-file historic source gate stay in place. **DO NOT CLAIM changed 20-module bridge success until its new CI completes on exact new source commit.**

**Already green predecessor evidence, not transferable:** primary `psc0/pscv0-readable-selfhost-v1` [38122341583](https://github.com/dwijayuda/pskernel/actions/runs/38122341583), source `2394fc7e`, Linux/Windows 43+12 tests each and RC4 proofs; native source APP-04 positive and eight axiom-free formal model lemmas [38124980640](https://github.com/dwijayuda/pskernel/actions/runs/38124980640) at `0e664233`. These do not certify newly changed artifacts.

**Next checkpoint:** get actual new [PSC0 portable bridge](https://github.com/dwijayuda/pskernel/actions/workflows/psc0-pscv0-bridge.yml) Linux generation, source provenance, kernel/runtime and Windows/RC4 results; resolve any *real* ABI/elaboration semantic mismatch systematically rather than patching negative tests or relying on old Lean parsing. Then compare to current primary HEAD (includes concurrent separate Rust-target documentation commit) and preserve both histories; integrate with non-force expected-HEAD only after evidence. Update work state with actual outcome. Unqualified v7 full Standard/verified contracts, 64-module source migration, self-host C0/C3 and kernel consistency remain separate work.

---

# PSC0 AI WORK STATE — direct generated v7 AST handoff and APP-04 verification

## Current milestone: 2026-10-11 — source model passed; generated direct-AST pipeline pending

**Sole language authority remains PSCV0 v7**, SHA-256 `843940bd7f6a9b286e80b01d8c891a7e01b8868a9de7b05833fce32d49be6cd5`, Lean pin `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`. No old PSC1/older PSCV0 `.ps` compatibility profiles or parser fallback. Historical fixed-point sources are immutable qualified bootstrap artifacts, not new source-language requirements.

**Proved model / native positive:** abstract APP-04 eight-lemma model checked axiom-free [38124512189](https://github.com/dwijayuda/pskernel/actions/runs/38124512189). Source-owned recursive application printer in `Ps.Syntax.Pscv0.Surface.lean` passed [38124980640](https://github.com/dwijayuda/pskernel/actions/runs/38124980640), source `0e664233f90895e6baa90d377b2821e5fd4d01ce`. Exact RC4 accepted the actually produced `(add 1) 2` and checked the generated `grouped = 3` proof with no axioms. The `.ps` printer/parser preserved nested grouping; mixed native/postfix calls were tested. This is a real native source/Lean correspondence, **not** a generated JS backend proof.

**Architecture/root fix:** avoid the historical Lean reader as a second semantic compiler input. `Ps.Syntax.Pscv0.Module.psPscv0LowerModule` already supplies `PsSyntaxModule` from the **generated PSCV0 JS** source parser. The qualified old compiler exposes a pure `psCompilerPreparationStepParsedWithOrigins(state, sourceModule)` and elaborates with `psElabModuleWithOrigins`; it does not require a text parse. The new bridge now passes this owned, untrusted syntax module **directly** to existing elaboration/preparation, with a mandatory no-fallback check on the `pscv0` source kind. Readable Lean remains a separate independently checked view. Source imports must exactly match the frozen selected module's imported source closure during first-module migration; full source/module manifest identity remains a later gate. No kernel or trust-policy change.

**New executable acceptance under development:** generated JS `B.psPscv0ParseSource` + `B.psPscv0LowerModule` crosses into retained compiler `C.psCompilerPreparationStepParsedWithOrigins`, followed by complete typechecking, canonical admissions, independent `pskernel-core` check, TypeScript 7.0.2 emission/compilation, and actual JavaScript runtime `grouped = 3`. The exact same test runs on Linux and Windows and records checked source/admission/runtime digests. This is an *architectural end-to-end* validation of the semantic AST boundary, not a test-output change. Full generated 20-module bridge and RC4 correspondence are required before declaring the changed source qualified; no results claimed yet.

**Stable prior M1:** integrated v7-only branch [38122341583](https://github.com/dwijayuda/pskernel/actions/runs/38122341583) completed Linux/Windows/RC4 successfully at source `2394fc7d`. New model/direct-AST source needs independent qualification. No complete 64-module v7 `.ps` compiler migration, new public CLI, full Standard digest or C2/C3 compiler-only fixed point yet.

**Next:** examine actual newly triggered cloud CI rather than assuming constructor ABI compatibility across the generated PSCV0 and retained compiler runtimes. If in-memory cross-runtime data representation fails, establish a canonical typed-data ABI and source-derived proof/admission identity rather than falling back to the legacy Lean text parser. Preserve both old validated branch and its proof history.

---

# PSC0 AI WORK STATE — model-first v7 source APP-04 printer implementation

## 2026-10-11 source compiler milestone in progress

**Validated model:** [run 38124512189](https://github.com/dwijayuda/pskernel/actions/runs/38124512189) **SUCCESS**, pinned Lean 4.35.0-rc4 commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`; all **eight** abstract application-grouping theorems reported **no axioms**. This is a model, *not* the production compiler semantic preservation theorem.

**Systematic architectural adjustment:** The goal is canonical `.ps` source (sole v7 grammar) → semantically faithful Lean projection → pinned Lean elaboration/checking. PSC0 need not implement a universal reverse `.lean`→`.ps` parser to self-host or prove its source transformations. The failed experimental reverse conversion for a grouped Lean head is retained as an **optional migration-tool gap**, not silently patched or used to require preservation of old source-language parsing behavior. The previously qualified first-module *bounded* source roundtrip remains valid on its original recorded source. This is an acceptance-contract clarification, not a waiver of source soundness or proof closure.

**New portable production work (model branch, pending CI):** selected APP-04 application rendering in `Ps.Syntax.Pscv0.Surface.lean` is now a compositional, bounded traversal of nested `PsSyntaxTerm.app` source trees, parenthesizing non-atomic callee/argument subtrees; no special error-fallback on compound heads, flattened AST head, copied historical Lean parser, or kernel changes. `scripts/Pscv0App04CoreSmoke.lean` checks v7 PS canonicalization, compares source APP grouping, prints `(add 1) 2` from actual v7 `(add(1))(2)`, then hands the generated Lean theorem `grouped = 3` to the immutable RC4 toolchain. This is a typed positive correspondence gate as well as a syntax-ownership gate. Its exact compiled and generated test results have not yet been observed. The separate full generated JavaScript/Windows bridge still requires a new run after source changes.

**Source authority and trust:** The model branch `psc0/pscv0-v7-app-model-v1` inherits primary `8213f02e`. The public compiler and kernel remain unchanged; no old `.ps` compatibility mode, executable plugin authority, release, 64-module migration, or C2/C3 requalification has occurred. Keep the source-only printer changes separate until RC4 native, actual generated JS and Windows validations are complete.

---

# PSC0 AI WORK STATE — APP-04 ownership model (new isolated research branch)

## 2026-10-11 abstract-model checkpoint

**Branch:** `psc0/pscv0-v7-app-model-v1`, cut from primary at `8213f02ea3874f329c96855f46638717219b26e8`. This branch is deliberately separate from the failing `psc0/pscv0-v7-call-ownership-v1` prototype and the green main compiler-bridge qualification. Future `.ps` grammar remains **only PSCV0 v7**; no older ProofScript syntax/backwards-compatible parser mode is part of the target.

**New diagnostic conclusion:** The `psPscv0TranslateReadable(false,true,grouped)` call fails while **reading the generated Lean code**, before it can print ProofScript. In the older `Ps.Syntax.ParseLean` code, grouped initial terms do not consistently own a following application suffix, and `psLeanApplicationWithArgument` eagerly flattens an application spine. This explains why more tweaks to PS printing alone are an inadequate general fix; the exact class of all contexts must still be established with executable checks. Historical compiler source is protected by the 69-file immutable source-closure gate, so do not casually modify the old reader to pass an isolated fixture.

**New deliverables:** [PSCV0 APP-04 source-ownership architectural model](docs/PSCV0_V7_APPLICATION_OWNERSHIP_MODEL.md) plus [pinned Lean 4.35.0-rc4 abstract application-tree model](test/pscv0/reference/ApplicationOwnershipModel.lean), with eight abstract source/core grouping facts. This proves only construction-level properties, **not the correctness of the actual parser or generated backend**. A new targeted GitHub CI job checks Lean version, exact pin, theorem dependencies and lack of axioms; **no CI claim is made until its actual result is observed**.

**Production design:** maintain the source-only `group`, native-whitespace app and adjacent-postfix app boundaries through a structured, precedence-owned PSCV0 syntax reader. Only lower them to existing normal `PsSyntaxTerm.app` after ownership is known. Give the Lean readable projection its own selected parser context; never use old `.ps` grammar fallback, hidden span heuristics, flattened-head reconstruction, untyped text rewrites or new kernel primitives. Printer correspondence must be tested at the AST partition level and typed Lean admission separately; preserve comments/origins, fail-closed limits and pinned environment.

**Known passing bounds:** first PS compiler module on 20-module generated bridge [run 38120695522](https://github.com/dwijayuda/pskernel/actions/runs/38120695522) passed all Linux/Windows/RC4 lanes at source `8603f7dc`. Integrated v7-only policy [run 38122341583](https://github.com/dwijayuda/pskernel/actions/runs/38122341583) likewise **overall passed** at source `2394fc7d`. Still not complete v7 or full 64-module compiler source fixed point. The experimental APP-04 [run 38122847916](https://github.com/dwijayuda/pskernel/actions/runs/38122847916) passed only a narrower source case, while deeper [38122996299](https://github.com/dwijayuda/pskernel/actions/runs/38122996299) and [38124012051](https://github.com/dwijayuda/pskernel/actions/runs/38124012051) revealed the grouped Lean-reader obstruction.

**Next gate:** first prove the abstract APP-04 model under RC4 via CI. Then implement an owned portable source parser/printer with explicit group ownership (not a test-specific fallback) and compile it with existing retained generated source pipeline; compare actual source AST partition, Linux/Windows generated semantics and RC4 kernel-accepted terms before integration into main. No source/CLI/seed switches, old receipts rewrites or kernel edits occur in this model branch.

---

# PSC0 AI WORK STATE — v7-only source policy integrated on primary branch

## Integration checkpoint — 2026-10-11

Primary development branch `psc0/pscv0-readable-selfhost-v1` was **non-force fast-forwarded** from successful bounded first-module checkpoint `8603f7dcf6af6295335c4e11912a10aac86c85a4` to `2394fc7e8ea327869b6cbe57ef41417de82e5408`. This incorporates the separate v7-only parser and historical-source-document work *without altering the already-qualified old evidence* or touching the independent kernel proof branch. User instruction is explicit: **PSCV0 v7 is the only new `.ps` language reference; no older PSC1/PSC0/previous PSCV0 source-language backwards compatibility is needed.** Frozen historical bootstrap seeds are reconstruction evidence only, not a compatibility/fallback feature.

**Exact new-HEAD CI launched:** native source/10-policy-refusal test [38122341557](https://github.com/dwijayuda/pskernel/actions/runs/38122341557) and generated 20-module/Windows/RC4 candidate test [38122341583](https://github.com/dwijayuda/pskernel/actions/runs/38122341583), both source `2394fc7d`, were **in progress** at this checkpoint. Run [38120695522](https://github.com/dwijayuda/pskernel/actions/runs/38120695522) already **fully succeeded** at original source `8603f7dc`, but its result must NOT be carried forward automatically to the changed v7-only parser source. Check the new CI's actual final conclusions before marking it qualified. An updated document-only checkpoint must not be mistaken for new compiler generation.

**Next:** inspect source and bridge logs; if the new integrated candidate passes, record the exact 43 generated bridge test results (prior 38 plus five new v7-only source refusals), twelve authoring/arrow tests, Windows identities and RC4 proof dependencies. Then begin the next small portable source feature/trivia-mapping milestone, not a premature whole-compiler `.ps` switch or public npm release. Preserve no-fallback admission and artifact gates.

---

# PSC0 AI WORK STATE — first PSCV0 v7-authored module: complete bounded CI; v7-only extension pending integration

## Latest proven checkpoint — 2026-10-11

**Only prospective ProofScript source language:** [PSCV0 v7](PSCV0_LANGUAGE_REFERENCE.md), exact SHA-256 `843940bd7f6a9b286e80b01d8c891a7e01b8868a9de7b05833fce32d49be6cd5`. There is no required backwards compatibility with any older PSC1, old PSCV0, or ps-0.9-r3 `.ps` grammar. Historical old bootstrap code and receipt archives remain for reconstruction, not parser fallback or alternate v7 semantics.

**NEW ACTUAL RESULTS — [run 38120695522](https://github.com/dwijayuda/pskernel/actions/runs/38120695522), immutable source [`8603f7dcf6af6295335c4e11912a10aac86c85a4`](https://github.com/dwijayuda/pskernel/commit/8603f7dcf6af6295335c4e11912a10aac86c85a4):** **overall SUCCESS** (Linux generated bridge job `114414631646`, Windows `114418588840`, Lean RC4 reference `114418588824`). The former 900-second generation timeout was solved at the declared 1600-second generation budget; this actual run completed with one `Translate.ps`-authored module among the generated 20-module syntax/foundation candidate and **13 shared-prefix modules prepared once**. Linux **38/38** bridge tests plus **12/12** candidate authoring/arrow tests passed; Windows likewise **38/38 + 12/12**. Each platform recorded **36** old/new API comparisons (**24 accepted**, **12 refused**), exact source/readable/lowered replay, `noFallback=true`, ten kernel-accepted fixture functions, first-error and runtime results. Generated candidate JS SHA-256 `fa5728347204ea683c6a22f900f2a2474d8f178ae0b093a01d141c2557605e27`; authoritative module source SHA-256 `938288af9c8476d592fc69c4e6f2c01ecb8e1f371fdd5bac1f789a3097710428`; independent fixture admission SHA-256 `6f14a42e22bf0e0fb41fbe4af07ada5bcbc82b21776e7f6b40149176d629ddb2` matched on both platforms.

Lean 4.35.0-rc4 checked the generated `pscv0_do_correspondence` fixture with **no axioms**. Both actual readable and lowered candidate API versions were proved equal to all four original translation APIs for **every String input**, yielding eight concrete equations with **exactly inherited `[propext]`** assumptions (and no new ones); the two generic error-map algebra lemmas plus generated error mapper had **no axioms**. Evidence is *module correspondence* and finite generated bridge tests, NOT universal translator correctness, JS backend semantic preservation or kernel consistency.

Artifacts of successful run: generated Linux/bridge `11695282564` (ZIP SHA-256 `e9aa3ac1089bed9465fd01e83bdf5a6facea673fe9de1d289840738003d49e57`), native authoring `11695122822` (`6d223b0ac47382e99fe2e0d811ad8a41564bd64a6df1e87e25d6239a73ace564`), Windows `11695114280` (`6085c35c27418bdbf72425d16f5c915ebf6f1b34019815461cab6e0cd54813bb`), independent RC4 `11695019450` (`861a9f197df2f4f2ce5fae8a4eaa325e877c718a7516364e533339ecf940d46c`). These are scoped to exact `8603f7dcf6af6295335c4e11912a10aac86c85a4` source, not necessarily the next policy-integrated SHA.

**Separate v7-only policy candidate:** `psc0/pscv0-v7-sole-source-policy-v1`, initial implementation `b7c6211b`. Explicitly closes the command dispatch to selected current v7 forms and refuses obsolete source `partial`, `unsafe`, `axiom`, `verify`, `ghost` and unselected arbitrary command syntax. Native CI runs [38121307578](https://github.com/dwijayuda/pskernel/actions/runs/38121307578) and [38121717749](https://github.com/dwijayuda/pskernel/actions/runs/38121717749) **passed** (5 round trips, 10 refusals, zero-axiom native do theorem; second run also v7 byte-identity preflight). The source policy adds five more generated rejection cases. **Those changed generated JS tests have NOT yet run**, so they cannot inherit the prior `8603f7dcf6af6295335c4e11912a10aac86c85a4` qualification. The current branch has historical-doc supersession notices and [next module candidates](docs/PSCV0_V7_NEXT_SOURCE_MIGRATION_CANDIDATES.md).

**Immediate next action:** after this source-policy branch and the exact successful `8603f7dcf6af6295335c4e11912a10aac86c85a4` checkpoint are reconciled, fast-forward/integrate into primary `psc0/pscv0-readable-selfhost-v1` with a non-force expected-HEAD lease; no unrelated kernel source changes. Run the full generated 20-module Linux/Windows/RC4 candidate job **again** for the changed source. Do not call the source-policy-integrated SHA M1-qualified before observing that distinct run. After that, move to source-trivia/source-span preservation and representative next compiler modules, and only later full 64-module v7 `.ps` source authority with a deliberately qualified compiler-only C0→C1→C2→C3 fixed point. Old `.lean` bootstrap source is not a language compatibility lane.

**Still NOT established:** full PSCV0 v7 grammar/Standard environment digest, v7 proof/verified effects, arbitrary source comments formatting, generated JS universal semantic theorem, full compiler-source migration, installed compiler/kernel fixed point, kernel consistency proof, public npm release or merged main. Never turn this first-module milestone into any of those stronger claims.

---

# PSC0 AI WORK STATE — v7-only source-policy checkpoint

## 2026-10-11 — latest implementation and CI evidence

**Further native validation:** [run 38121717749](https://github.com/dwijayuda/pskernel/actions/runs/38121717749), revision `964427027b7edd9b8d1a3edb33d4be36841832d8`, **SUCCESS**. This adds a cheap CI guard verifying the exact v7 reference file, size, SHA-256, Git blob, adoption manifest and Lean RC4 pin **before** Lean source compilation. The existing native 10-refusal, positive round-trip and axiom-free correspondence gates passed again. This is *source qualification only*, not completed generated JavaScript, Windows, or new compiler self-host acceptance.

**Sole future .ps source-language authority:** `psc0/PSCV0_LANGUAGE_REFERENCE.md`, PSCV0 v7, SHA-256 `843940bd7f6a9b286e80b01d8c891a7e01b8868a9de7b05833fce32d49be6cd5`. **No backwards-compatible PSC1/ps-0.9-r3/old-PSCV0 source edition is required or selected for this candidate.** Historical frozen JavaScript/Lean compiler artifacts remain bootstrap tools and provenance, **not** compatibility promises. The public installed old compiler has NOT been promoted to v7.

**Dedicated source-policy branch:** `psc0/pscv0-v7-sole-source-policy-v1` from the v7 adoption commit `8603f7dcf6af6295335c4e11912a10aac86c85a4`. Code commit [b7c6211b](https://github.com/dwijayuda/pskernel/commit/b7c6211b4698c8895279db49428a1e9cdce4c5f2) makes `psPscv0ReadDeclaration` dispatch only explicitly selected v7 command families, with direct refusals for source `partial`, `unsafe`, `axiom`, old `verify`, `ghost`, and unselected new parser extensions. The three retained `theorem`/`structure`/`inductive` families still reuse existing parser code as a *selected v7 subset*, **not** an old-language fallback. `pscv0-authoring.json` now encodes `sourcePolicy=pscv0-v7-only-no-legacy-fallback`, `backwardCompatibilityRequired=false` and `supersededLanguageReferenceAllowed=false`; the materializer checks these before generated source selection. Unknown v7 constructs explicitly decline until implemented and qualified.

**Native cloud proof/test:** [run 38121307578](https://github.com/dwijayuda/pskernel/actions/runs/38121307578) **SUCCESS** at policy commit b7c6211b. Native `PsSyntax`/`PsFoundation` built, all five portable PSCV0 source modules typechecked, `Pscv0BridgeSourceSmoke` reported **five positive source round trips and ten explicit negative refusals**, then `pscv0_native_do_correspondence` was checked **axiom-free**. This is a bounded native source policy/proof gate, **not** updated generated JavaScript, full v7 conformance, Windows, or the whole compiler self-host fixed point. The generated regression script adds five new policy refusals; it still requires independent generation and execution.

**Legacy-document routing:** [new v7-only source policy](docs/PSCV0_V7_ONLY_SOURCE_POLICY.md). Earlier `docs/selfhost-language/{CURRENT,SPEC,PS_GRAMMAR_ADOPTION,README,MIGRATION}.md` now have historical-evidence notices, and the root README labels the currently deployed old grammar historical, so no active document purports to supersede v7.

**Integration boundary:** The separate mainline candidate run [38120695522](https://github.com/dwijayuda/pskernel/actions/runs/38120695522), commit 8603f7dc, was still generating the 20-module bridge when the policy branch was created. **Do not cancel it prematurely by advancing the main branch.** After its actual conclusion, inspect Linux/Windows/RC4 jobs, distinguish timeout/semantic failures, then integrate this policy branch into `psc0/pscv0-readable-selfhost-v1` without deleting histories and requalify the changed candidate. Do not claim passing generated tests before they complete. All kernel branches and public npm source remain unchanged.

### Next actions and conditions

1. Verify the main 20-module candidate job's final status and exact source/JS/TS/proof artifacts. If it finishes and all Linux/Windows/RC4 lanes pass, record its bounded source identity, **not** full compiler or v7 language conformance.
2. Integrate the narrow v7-only policy and historical-doc clarification into the primary readable-self-host branch with current-HEAD validation and non-force expected-SHA update.
3. Run native/generation/cloud CI on integrated source; the added five generated refusals must pass, alongside existing 38 bridge assertions, source/Lean correspondence, 36 API comparisons and cross-platform checks.
4. Only after one genuine candidate qualification, expand high-value portable v7 grammar/lowering and migrate additional actual compiler modules, preserving trivia/source spans. A final deliberate 64-module source migration and C0–C3 fixed point remains later.

---

# PSC0 AI WORK STATE — PSCV0 v7 authority and ongoing first-module qualification

## Active checkpoint — 2026-10-11

**Branch:** `psc0/pscv0-readable-selfhost-v1`. **Pre-adoption HEAD:** `29c12e9eb8cf00966c03b4636ff9d6d243b010a3`. The source-language **design** authority for all new PSC0 work is now the full, byte-identical [PSCV0 v7 reference](PSCV0_LANGUAGE_REFERENCE.md): 308,462 bytes, SHA-256 `843940bd7f6a9b286e80b01d8c891a7e01b8868a9de7b05833fce32d49be6cd5`, Git blob `d9e9d7c21337881175b19ccc4c508a792a430195`, Lean 4.35.0-rc4 pin `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`. The previous document SHA `a419955383fd3e35d873f82c939ecf3a92dc65b162cc9d0d3cadf5b853a0f4b0` and PSC1/old PSCV0 references are historical, not alternate grammar or supported compatibility fallbacks. Preserve old exact bootstrap seeds and source-specific test receipts.

**Actual compiler status:** v7 is a design reference, **not implemented full conformance**. Public installed PSC0 still uses the earlier bounded grammar and TypeScript 7.0.2 reference backend. First selected `.ps` compiler source `packages/syntax/src-ps/Ps/Syntax/Translate.ps` has 40 lines versus 63 in frozen handwritten Lean; compiler source authority remains unchanged outside the bounded candidate. Do not change the separate kernel/proof workstream or claim a verified executable.

**Verified latest prior run:** [38112642444](https://github.com/dwijayuda/pskernel/actions/runs/38112642444) completed **failure** at the 900-second explicit generator timeout (exit 124) while preparing `Ps.Syntax.Pscv0.Module` in the candidate suffix. Contrary to older work-state wording, native preflight, actual generated surface bootstrap, authoritative `.ps` source materialization, owned Lean reader round-trip, all eight concrete source-equation proofs and two axiom-free algebra lemmas **passed first**. The concrete original parser/printer/API and changed equations retain exactly inherited `[propext]`; the generic helper/algebra require zero axioms. The 20-module candidate generation, Windows tests and RC4 candidate proof job did **not** finish. Earlier 19-module `Except do` bridge had bounded 38/38 Linux/Windows tests plus RC4 fixture replay [38108354566](https://github.com/dwijayuda/pskernel/actions/runs/38108354566); that historical success is not evidence of the changed candidate or complete v7.

**This change:** commit original v7 file unchanged; pin authoring/adoption manifests and the portable bridge constant/tests to the new digest; install a cheap full-file bytes/SHA256/Git-blob/RC4 identity check before costly CI; raise only the explicit generation ceiling `timeout 900 → 1600` and bridge job budget `25 → 40 minutes`. Preserve all semantic, proof, source, identity, kernel/no-fallback and negative test gates. This budget change does not certify speed or guarantee the next run will pass. See [v7 adoption matrix](docs/PSCV0_V7_ADOPTION_AND_MIGRATION_MATRIX.md). The previous AI state is preserved verbatim in [history](docs/history/AI_WORK_STATE_BEFORE_V7_ADOPTION.md).

### Ordered milestone acceptance (no assumed success)

**V7-M0:** exact 308,462-byte reference committed; automated identity guard passes in actual CI; historical earlier reference preserved and separately labeled.

**V7-M1:** finish the **20-module** candidate using the *generated retained PSC0 JavaScript compiler*, with one in-memory shared prefix; no native fallback or fabricated checked state. Require both readable/lowered projections and their eight equations, unchanged 38 bridge tests, eight selected authoring tests, four arrow regressions, 36 old/new API comparisons, identical source/admission/TS/JS identity, Windows check and independent Lean RC4 generated-proof replay. No completed runs means no candidate promotion.

**V7-M2:** review/migrate selected additional `.ps` compiler modules; introduce useful portable features only with v7 syntax/typing/negative conformance evidence; preserve comments/docstrings/source spans and evaluation order. Avoid JS-only language semantics and duplicate tiny packages. Don't repeatedly run a full compiler fixed point for every routine edit.

**V7-M3:** convert complete actual 64-module compiler-source closure to authoritative `.ps` and reproducibly generated readable `.lean`. Promote explicit new grammar and source/seed manifest identities, not historical SH/1 receipts.

**V7-M4:** deliberate compiler-only C0→C1→C2→C3 with source/admission/TS/JS parity, checked host, typed environment and negative gates. Kernel model-consistency and backend behavior preservation are separate formal obligations.

**V7-specific risks:** `function f()` alone gets one required Unit; `def f()` is invalid; `f ()` gap is banned in term application but binder and grouped-initial terms remain legal; mixed `f x(y)` and `(f x)(y)` differ; proof terms share call syntax; patterns are not comma-call expressions. `psDoItem` is the explicit selected base / verified P0 / environment-gated P1 union. RC4 modules/public imports, Std.WP contract-spec `where finally`, Standard registry digest, accurate `.ps` spans and full P0 APIs remain unqualified. Source `axiom`/`unsafe`/`partial` and emitted `sorryAx` are prohibited by v7, but code paths must earn actual release enforcement evidence. Ordinary checked is not verified executable.

**Process:** GitHub/cloud CI only; no local checkouts/tests, Desktop Commander, kernel edits, force updates or automatic publication. Read current HEAD and CI before each write; preserve history and use expected-HEAD lease. Update this state after *observed* CI outcomes without retroactively relabeling historical artifacts.

---

## Historical work-state snapshot (content below predates this checkpoint)

# PSC0 AI work state — first PSCV0 module, source integration and assumption audit

## Current status (2026-10-11)

Work branch `psc0/pscv0-readable-selfhost-v1`. The actual compiler module `Ps.Syntax.Translate` is authored in `packages/syntax/src-ps/Ps/Syntax/Translate.ps`, selected explicitly by `pscv0-authoring.json`. It has40 physical lines instead of63 in the frozen predecessor. Native PS/readable-Lean/PS round trip works. A portable arrow-type printer repairs the higher-order parameter round trip without changing old69 source files or the kernel.

**Still a candidate.** The generated20-module bridge, final Linux/Windows tests and independent RC4 module proofs have not passed yet. Every attempt so far stopped in cheap native preflight before expensive retained-compiler preparation. The stable public `psc` and default npm source root remain unchanged. Do not claim complete compiler migration or a new full self-host fixed point.

## Important correction: original native dependencies are not axiom-free

Run `38112266804`, job `114390104605`, at `d510224ad9cbbaefab1dcabb51e2049352a5b6d4` checked the unchanged original declarations. The two parsers, two printers and four original translation APIs report exactly **[propext]**; PsTranslationError reports no axioms. The readable correspondence equations close with the same dependency. Prior attempts to remove it solely by changing proof tactics were misdirected.

The original empty-closure gate assumed the concrete compiler APIs had the same empty dependency closure as the isolated Except/Nat fixture. That assumption was wrong. It is explicitly replaced with **exact baseline closure + zero-axiom refactoring algebra**. See [PSCV0_MODULE_ASSUMPTION_AUDIT.md](docs/PSCV0_MODULE_ASSUMPTION_AUDIT.md).

The runner now checks original, migrated and theorem dependencies separately. Concrete equations must add no assumptions beyond exactly [propext]; unexpected dependencies fail. Two generic error-map/bind and error-map/match lemmas over abstract parser/printer results, and the actual generated error helper, must have zero axioms. A baseline reflexivity theorem exposes inherited dependencies. All eight concrete API equations and generated source products are unchanged. This updates qualification scope, not production kernel/axiom acceptance.

## Source authority and immutable boundaries

Reference: user's PSCV0 Lean4.35.0-rc4 document, SHA256 `a419955383fd3e35d873f82c939ecf3a92dc65b162cc9d0d3cadf5b853a0f4b0`; upstream `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`. Use its base do, arrows, binder visibility and formatting semantics. No old-.ps backward-compatible mode is required.

Candidate source selection has no .lean fallback. Original Translate.lean blob `eafd7159b14a251fe11ffdbfb1e2482bcc773c9b` is a frozen predecessor, not a second candidate master. src-ps keeps it outside the old release packer's source-collision path. The other compiler source, public npm host, seed/toolchain and kernel source/JS adapter remain unchanged. Kernel work stays on the other branch.

Candidate PS SHA256 `938288af9c8476d592fc69c4e6f2c01ecb8e1f371fdd5bac1f789a3097710428`.
Native readable SHA256 `21ac2a83f37c5aac102a9343ea0f310503449dc8a800f0ca6c3493f77e8b11e5`.
Native lowered SHA256 `c11d75f3f6a3ecda32bd2014bbab80d387d1f5fae6b822f44481300a490aefeb`.
These native views are NOT substituted for generated compiler inputs.

## Ordered bootstrap and validation

1. Cloud native preflight: build only syntax/foundation dependencies, type-check Surface/Read/Commands/TypePrint/Module, execute original smoke and real authoring round trip, then prove both generated projections equal the original four APIs and audit dependencies/algebra.
2. Retained C0 JavaScript prepares the unchanged syntax prefix once. Preserve its pure in-memory preparation state just before Translate; do not serialize it as proof authority.
3. Generate the current20-module surface bootstrap with predecessor Translate. Use THAT generated JS to parse/print/lower the selected Translate.ps. All three views must equal native preflight, and proofs run on generated products again.
4. Resume the same pure prefix with PS-derived Translate, compile only the suffix, and emit the final candidate. Record both stages and exact source/JS/TS identities. This avoids repeating expensive prefix preparation.
5. Linux and Windows run the original38 tests unchanged plus8 authoring tests (36 original/candidate input comparisons) and4 arrow regressions. The new bridge must read/lower its own selected PS module and reproduce readable/lowered views.
6. RC4 checks the existing actual generated do fixture with zero axioms and all eight concrete module equations under their exact baseline dependencies, plus two zero-axiom refactoring lemmas.

No full64-module compiler rebuild, C2/C3, kernel regeneration, public CLI change, npm publication or main merge. Old qualification is not inherited by changed source; the candidate must earn its own bounded evidence.

## Canonical owners

- syntax/src-ps/Ps/Syntax/Translate.ps: sole candidate module source, four original APIs + generic error adapter.
- Syntax/Pscv0/TypePrint.lean and Module.lean: portable readable/lowered declaration-type printing; no new kernel/Pi semantics.
- scripts/pscv0-authoring.mjs: IO, source selection/hashes and portable bridge invocation; proof-source assembly is test tooling.
- scripts/pscv0-build-bridge.mjs: two-stage generation with one shared pure prefix.
- scripts/Pscv0AuthoringSmoke.lean: native preflight only.
- scripts/pscv0-authoring-proof.mjs and test/pscv0/reference/TranslationAlgebra.lean: exact dependency audit and actual projection equations/algebra.
- scripts/pscv0-authoring.test.mjs, pscv0-arrow.test.mjs: genuinely generated JS tests.

## Retained evidence and failures

Retained C0: source `2f42a52814f3785ff2d92bd826f6e7fb3eb9bc8a`, run38075437516, artifact11678641329, JS SHA256 `6cddc3c34c38f1524ef9a355c46b0eb17949c45c54fd59367ea370c1af861ab3`; TypeScript7.0.2, Lean4.34.0.
Previous19-module bridge: implementation1ed94be7b1d3, run38098425773 Linux/Windows38 passed, overall failed dueRC4 setup; successful separate reference replay38108354566. Full ledger in docs/PSCV0_BRIDGE_CAPABILITIES.json applies to that exact old source only.

First module run38110082840 at1d578cd6: printer produced anonymous binder inside higher-order type, owned reader refused. General portable arrow correction at364740af restored round trip.
Runs38111345102 and38111578077: incomplete native proof scripts, not changed source behavior. Run38111837339 at8ccd191b: readable proofs closed, zero-axiom audit refused propext. Run38112058253 at58525ea3: delta proof still same dependency. Run38112266804 atd510224a: original dependency audit established the true baseline. All remain failed; no generated candidate claims. Last diagnostic artifact11691727987 SHA256 `6903cc573c49bd79419d775b3b8ad59cc546dc5d5554190f296a7c7e43516781`.

## Continuation and limits

First module contains no original/new comments and exact source replay is checked. Do not strip comments from later modules: full comment anchoring remains pending. Compiler diagnostics after lowering still use generated-Lean coordinates; source remapping is pending before public promotion. Full inferred lambdas, record updates and broader language features remain later work.

GitHub repository reads/writes and cloud CI execution only. No local checkout/build/test, Desktop Commander, force push, kernel edits or automatic releases. Fetch live HEAD before writing and use expected-HEAD non-force updates; preserve concurrent commits. Do not call a pending run success or silently relax source/semantic assertions. Update this state after actual results.

Prior full state retained byte-for-byte at docs/history/AI_WORK_STATE_BEFORE_MODULE_AXIOM_AUDIT.md (blob1149451ec45760127d7511bb4a54a793bc018f93); initial module state at docs/history/AI_WORK_STATE_BEFORE_FIRST_PS_MODULE.md.


## Native source universes (2026-10-12)

Qualified source 8d28ab396bab52b32b2174b0029f83eeefbbcdbd, native profile pscv0-v7-native-bounded/18,
[Linux native run 38177929378](https://github.com/dwijayuda/pskernel/actions/runs/38177929378),
job 114584166723: 28 parser cases, four checked programs, 54 phase-specific
refusals, strict TypeScript execution and 107 identical Rust observations pass.
The source guard reports 105 portable and 111 native modules. Kernel remains
Lean 4.35.0-rc4 at c29b6dda4f7c20e3eeaa717c4e565663c5cfa364. No pskernel-core,
compiler-source generation or self-host qualification was run.

Scoped universes now reach shared inference, definition closure, positive data
families, field-derived structure universes, recursors, projections and fresh
global instance candidates. Symbolic level simplification and depth-independent
assignment substitution are shared metadata operations. See
[universe architecture](docs/PSCV0_NATIVE_UNIVERSES.md) for explicit limits.
Full v7 remains incomplete; next work is the shared proof-goal mechanism.


## Portable proof goal foundation (2026-10-12)

Qualified source e2dffaf6db6b86947c315960b33ff159ea0e927a, profile pscv0-v7-native-bounded/19,
[native run 38178663565](https://github.com/dwijayuda/pskernel/actions/runs/38178663565),
job 114586356725. Official Lean accepts the proof-producing composite; all 28 parser
cases, four accepted semantic programs, 59 phase-specific refusals and both
strict TS/JavaScript and Rust execution pass (109 shared runtime observations).

The shared goal engine uses typed metavariables, globally fresh local IDs and
deferred binder closure. Initial clients are exact/refine/apply/intro/assumption/
rfl/constructor and focus/bullets. Proof terms are scoped against actual goal
contexts, with the same source term parser and declaration/kernel pipeline.
No host elaborator fallback or proof authority was added. The next integration
extends this same state to all_goals/any_goals with failure rollback.


## Shared proof control qualification (2026-10-12)

Profile pscv0-v7-native-bounded/20 at 5d63d8962084a8df15f318610646f6d30ed42308 passed
[run 38178805422](https://github.com/dwijayuda/pskernel/actions/runs/38178805422), job 114586770796:
28 parser cases, four accepted semantic programs, 60 phase-specific refusals,
and 111 shared runtime observations in both targets. all_goals and any_goals
reuse the same focused goal engine; failed any_goals branches roll back their
constraint state. No source/compiler self-host qualification was performed.

## Logical prelude qualification (2026-10-12)

Profile pscv0-v7-native-bounded/21 at a8fbc17f1ad2d24efbde14a7cbe993a4400d4c01 passed
[run 38179168385](https://github.com/dwijayuda/pskernel/actions/runs/38179168385), job 114587853107:
329 fixture declarations, 28 parser cases, four accepted programs, 61 phase-specific
refusals and 111 shared runtime observations. The source guard reports 109 portable
and 115 native modules. Checked And/Iff/Or/Exists/Not declarations preserve their
elimination restrictions; no proof axiom or host elaborator fallback is added.

## Logical notation qualification (2026-10-12)

Profile pscv0-v7-native-bounded/22 at cc38e63898da8eb9600114d6d94949b0df3aaaf0 passed
[run 38179816372](https://github.com/dwijayuda/pskernel/actions/runs/38179816372), job 114589798702:
334 fixture declarations, 28 parser cases, four accepted programs, 63 phase-specific
refusals and 111 shared runtime observations. One source precedence reader replaces
the previous arrow/matches-only tail. The source guard reports 110 portable and
116 native modules. A prior compile failure used a reserved Lean identifier;
that failed run supplies no semantic qualification.

## Intermediate proof facts qualification (2026-10-12)

Profile pscv0-v7-native-bounded/23 at 960dcdaa1599797f359ba5560bf8e06f2c4e4d89 passed
[run 38180641379](https://github.com/dwijayuda/pskernel/actions/runs/38180641379):
348 fixture declarations, 28 parser cases, four accepted programs, 68 phase-specific
refusals and 111 shared runtime observations; 113 portable and 119 native modules.
Have/let preserve distinct elaboration reduction behavior, show selects goals with
rollback, change checks conversion, and existential notation uses checked Exists.
The same checks exposed and now cover shared natural computation and independent
application-result propagation. No acceptance outcome was weakened.

## Proposition family qualification (2026-10-12)

Profile pscv0-v7-native-bounded/24 at 7fb7a4ed8e2aaa71953a6e0726c2eb4f804449d2 passed
[run 38181283317](https://github.com/dwijayuda/pskernel/actions/runs/38181283317):
373 fixture declarations, 28 parser cases, four accepted programs, 71 phase-specific
refusals and 113 shared runtime observations. The source guard reports 114 portable
and 120 native modules. Proof families share kernel-aligned elimination metadata
and do not become runtime tags. Singleton minors open proof fields before erasure,
preserving the independent proof-guarded call convention. Explicit limits are in
docs/PSCV0_NATIVE_DATA.md. Earlier failed runs are not qualification evidence.

## Explicit structure sorts qualification (2026-10-12)

Profile pscv0-v7-native-bounded/25 at d19339609d6ba579927f7cae9292674f284ccf44 passed
[run 38181410257](https://github.com/dwijayuda/pskernel/actions/runs/38181410257),
job 114594573059: 390 fixture declarations, 28 parser cases, four accepted
programs, 74 phase-specific refusals and 114 shared runtime observations.
114 portable and 120 native modules. Explicit Prop/Type structure and class
sorts pass through shared data metadata and checked projection generation.

Record reconstruction is the next native milestone; see docs/PSCV0_NATIVE_RECORDS.md.

## Record reconstruction qualification (2026-10-12)

Profile pscv0-v7-native-bounded/26 at 36148d3f7b324296b38dbcd41e0d639a93ab7e79 passed
[run 38182281191](https://github.com/dwijayuda/pskernel/actions/runs/38182281191):
411 fixture declarations, 28 parser cases, four accepted programs, 80 phase-specific
refusals and 119 shared runtime observations; 115 portable and 121 native modules.
Record construction/update uses the shared ordered argument engine. Expected
nominal types replace the obsolete literal-shape scan. Prior build-registration
and import-boundary failures are not qualification evidence.

Shared delayed term-scope closure is the next integration; see
docs/PSCV0_NATIVE_SCOPES.md.

## Shared delayed scopes qualification (2026-10-12)

Profile pscv0-v7-native-bounded/27 at c1d77c64bfda6107da9291d72971c5989a123330 passed
[run 38183102348](https://github.com/dwijayuda/pskernel/actions/runs/38183102348):
418 fixture declarations, 28 parser cases, four accepted programs, 81 phase-specific
refusals and 122 shared runtime observations; 116 portable and 122 native modules.
The compact metadata boundary rejects delayed cycles and narrower-scope goal
aliases. Lambda/forall/let/update and tactic scopes share delayed assignments.
The prior source-syntax compile failure is not qualification evidence.

Dependent match branches now route through the same abstraction mechanism;
substitution recipes close interleaved aliases in lexical order.

## Dependent branch goal qualification (2026-10-12)

Profile pscv0-v7-native-bounded/28 at 86a7fabda66115ce886790ebf243abce4e96177a passed
[run 38183309863](https://github.com/dwijayuda/pskernel/actions/runs/38183309863):
426 fixture declarations, 28 parser cases, four accepted programs, 81 phase-specific
refusals and 126 shared runtime observations; 116 portable and 122 native modules.
Refinement preserves captured goals through constructor fields, aliases, equality
transport, generalized dependents and computed discriminants. Closure recipes
follow lexical identity order rather than grouping aliases before binder types.

Proof elimination and named case focus are the next clients of this shared path;
see docs/PSCV0_NATIVE_ELIMINATION.md.
