# PSCV0 native M1 and M2 — Implementation evidence and remaining Lean parity

## Current qualification — direct coercions and typed postponed results (13 October 2026)

Executable `35641f810e31f3c9d309c01028acd53ebe4112d9`;
[green Linux 38430940757](https://github.com/dwijayuda/pskernel/actions/runs/38430940757).
**293 shared runtime observations**, four panic contracts, **187 portable /
195 native modules**, profile `pscv0-v7-native-bounded/50`. Official RC4
kernel, independent oracle, all semantic/refusal gates, strict IR, readable
JS/TS/Rust, GC-Wasm V8/Wasmtime, WIT/WAT/components and project gates passed.

- Direct Coe, CoeFun and CoeSort use one checked class projection; no coercion
  chains or implicit lifting. Applications, annotations and expected types share
  these operations. Local dictionaries and APP-03 completion are qualified.
- Expected-term adaptation joins the transactional source/Core worklist.
  Mandatory defaults resolve before blocked result adaptation; failed attempts
  retain the original lexical scope and cannot leak assignments.
- Nonrecursive one-field wrappers whose erased uniform parameter determines
  their field use the concrete field representation. Type/proof-only fields
  erase; runtime fields depending on existential type fields remain refused.
  This does not introduce general higher-rank or existential runtime IR.

Standard: **308 declarations / 18 classes / 54 instances**, adding nine checked
coercion declarations and no global instances, axioms or primitives.
FNV `fnv1a64:946298686920218861`;
SHA `sha256:9afbebe8bf188a119b1bc223bc7f793da6f2dc08db9caa98e381d9e97662b234`.
See [direct coercion design/evidence](PSCV0_M2_DIRECT_COERCIONS_2026-10-13.md).

**M2+A remains incomplete.** The next source change introduces explicit
instance-search transparency, module-preserved reducibility and a reviewed
digest update; it is not yet qualified. Continue remaining Repr/Hashable,
faithful selected scalar/Float/BitVec/bytes/string/collection APIs, comprehensive
manifest, broader M2 coverage and C5 semantic retention. Keep the accepted
**M2+A → M3+B → M4+C/D → M5/E** dependencies and unchanged exit gates.
Native .lean and official Lean only; no pskernel-core, self-hosting or
compiler-source migration.


## Current qualification — M2+A scheduling, indexed lookup and literals (13 October 2026)

Executable `4d2e644d3974a6e6a4b68a15b7148bdb4f83e372`;
[green Linux 38425066964](https://github.com/dwijayuda/pskernel/actions/runs/38425066964).
**285 shared runtime observations**, four panic contracts, **186 portable /
194 native modules**, profile `pscv0-v7-native-bounded/50`.
Official Lean RC4 kernel, independent oracle, semantic refusals, strict IR,
JS/TS/Rust, V8/Wasmtime GC, WIT/WAT/component/ABI and project checks passed.

- One transactional worklist now serves Core constraints and captured source
  terms. Later arguments can determine record/lambda/tactic types; numeral
  fallback and mandatory defaults run after ordinary work reaches quiescence.
- Global instances are indexed by class while preserving priority/tie order.
  Generator buckets use rigid class plus lexical scope, followed by full
  definitionally-equal input checks. At 32 goals: zero generator comparisons
  across classes, 528 within one class. No general linearity claim.
- Numeric literals use genuine checked OfNat dictionaries. Typed Core
  application resolves class universes before search; deriving reuses it.
  Custom numeric types, local dictionaries and higher universes are qualified.

Standard: **299 declarations / 15 classes / 54 instances**.
The reviewed change adds OfNat/constructor/projection and Nat/Int dictionaries,
without new axioms or primitives.
FNV `fnv1a64:4206739069382061916`;
SHA-256 `sha256:00c6142b5f5b0e47abb8b317dc4fff3d595ab9f5e931822c4f48fca809758647`.

Direct Coe/CoeFun/CoeSort boundaries are implemented but **qualification is
pending** in subsequent source commits. They add nine checked declarations,
three classes and no global instances. Keep strict digest review.
See [scheduling and lookup](PSCV0_M2_POSTPONED_ELABORATION_2026-10-13.md)
and [direct coercion design](PSCV0_M2_DIRECT_COERCIONS_2026-10-13.md).

**M2+A is not complete.** Continue autonomously: remaining Repr/Hashable,
faithful scalar/Float/BitVec/bytes/string/collection APIs, comprehensive
module/notation/handler/tactic/effect/assumption manifest, broader M2 coverage
and C5 semantic retention. Keep dependent/indexed/recursive deriving with M3's
shared data/transport/termination work. Preserve
**M2+A → M3+B → M4+C/D → M5/E**; do not redefine the exit gates.
Native .lean, official kernel, GitHub source operations and Linux CI only.
No pskernel-core, self-hosting or compiler-source migration.

## Prior qualification — M2+A checked equality and structure defaults (13 October 2026)

Executable `d7e28a3870cdc399eca3c63c6d305b10109d2eca`; [green Linux 38418209663](https://github.com/dwijayuda/pskernel/actions/runs/38418209663).
**276 shared runtime observations** (all prior 263 retained), four panic
contracts, **183 portable / 191 native modules**, profile
`pscv0-v7-native-bounded/49`. Official Lean RC4 kernel, independent upstream
deriving oracle, 92 semantic refusals, existing do/opacity checks, strict IR,
JS/TS/Rust, V8/Wasmtime GC/component/ABI, declarations/maps and project gates pass.

- `DecidableEq` derives checked decisions for non-indexed, nonrecursive
  families with independent runtime fields, including generic universes,
  empty families and dependent proof fields. It uses Eq.rec/congruence and
  existing dependent-context substitution; no BEq-to-equality axiom.
- `BEq` skips proof fields and shares the new recursor builder.
  `Inhabited` honors explicit structure defaults and still prunes unused
  parameter assumptions. Record/constructor completion uses the shared queue.
- Typed proof conversion is shared by application/let inference and
  unification. Different propositions and runtime values remain distinct.
  Record and deriving diagnostics retain their source/constructor owners.

Standard now has **294 declarations / 14 classes / 52 instances**. The only
additions are checked `DecidableEq`/`decEq` definitions; no new axiom,
primitive, class or global instance.
FNV `fnv1a64:8231265721298810139`;
SHA-256 `sha256:89c4125cc3ca36bf198421e64673659a0acdf0207004af46738d36d32fcfd540`.

[Design, reviewed Standard change and exact evidence](PSCV0_M2_A_EQUALITY_DEFAULTS_2026-10-13.md).
**Selected milestone complete; full M2, Phase A and v7 remain open.**
Continue **M2+A → M3+B → M4+C/D → M5/E**. Repr needs faithful Std.Format,
quoting and rendering; Hashable needs UInt64/mixHash and their audited runtime
correspondence. Keep indexed/recursive deriving and dependent computational
fields with M3's general data/transport/termination mechanisms. Broader M2
scheduling/scoping/scaling, selected APIs, the complete manifest and C5
retention/publication remain on the existing roadmap. Native Lean only;
no pskernel-core, self-hosting or compiler-source migration.

## Prior qualification — M2+A generalized answers and synthetic constraints (13 October 2026)

Executable `c6468b17ef8f0a97c9e0df76c1ffe49f35c68279`;
[green Linux 38411211335](https://github.com/dwijayuda/pskernel/actions/runs/38411211335):
**263 shared runtime observations**, four panic contracts, **182 portable /
190 native modules**. Official Lean RC4 kernel and independent oracle,
92 phase-specific semantic refusals, existing do/opacity checks, strict IR,
JS/TS/Rust, V8/Wasmtime GC/component/ABI, declarations/maps and project gates passed.
Standard remains 292 declarations / 14 classes / 52 instances, with unchanged
FNV `fnv1a64:5949916575031563783` and
SHA-256 `sha256:f33d923e45baf8aa5dfa6755819737acabc09daf6d60934eb232133acaad069f`.

Scoped natural term/universe answer templates now freshen on shared replay.
The graph retains generalized answers and checks each receiving target;
root answers cannot retain term parameters. One scoped queue handles expected
types, instance holes and mandatory omitted defaults for calls/records/proof
applications. The old instance-only retry loop is removed. Global registration
also checks synthesis order and determined outputs. All mechanisms remain
portable native Lean under official checking.

[Design, exact evidence and boundaries](PSCV0_M2_GENERALIZED_CONSTRAINTS_2026-10-13.md).
The type-polymorphic local-dictionary case is kernel-qualified and explicitly
refused at erasure pending higher-rank runtime IR. Nat-indexed dictionary
sharing is qualified across every existing target. Generalized graph evidence:
6 generators / 6 answers / 1 generalized / 1 freshened shared answer. Earlier
widths 1/8/32 retain 2 generators, 3 candidates and 7/21/69 transitions.

**This completes the selected M2+A milestone, not full M2, A or v7.**
Continue **M2+A → M3+B → M4+C/D → M5/E**. Remaining M2 includes broader
postponed syntax/tactic scheduling, scoping/depth parity, search scaling and C5
occurrence retention. Remaining A includes Repr/DecidableEq/Hashable, structure
defaults, proof-field deriving and the comprehensive manifest. Keep dependent/
indexed/recursive deriving with M3+B. No pskernel-core or self-hosting.

## Prior qualification — M2 + Phase A deriving (13 October 2026)

Executable `f1ce3840c1943c9f78be20a5428fd4adfa9053af`;
[green Linux 38403318952](https://github.com/dwijayuda/pskernel/actions/runs/38403318952):
260 shared runtime observations, four panic contracts, 180 portable / 188 native
modules. Official Lean RC4 kernel/oracle, semantic refusals, strict IR and all
existing JS/TS/Rust/GC-Wasm/component gates passed. Standard remains
292 declarations / 14 classes / 52 instances with unchanged M1 FNV/SHA digests.

Parameter/universe-aware `Inhabited` and independent nonrecursive `BEq` now
share one family telescope and checked instance-search path. Inhabited uses
RC4 two-pass constructor selection and prunes unused requirements. Structures
keep projection comparisons; fieldless/payload inductives share a recursor
builder with actual motive universes and fresh local identities.

M2 also gains actual-universe projection inference, common-successor maximum
normalization, and checked rigid-spine matching that can defer head-level
constraints until typed arguments determine them. No unresolved equality is
committed, and the generator/consumer ownership/replay contract is unchanged.

[Design, boundaries and qualification](PSCV0_M2_A_DERIVING_2026-10-13.md);
[prior graph invariants and growth evidence](PSCV0_M2_INSTANCE_GRAPH_2026-10-13.md).
**Follow M2+A → M3+B → M4+C/D**, then M5/E. Full M2, A and v7 remain incomplete.
The later qualification above adds generalized answer abstraction/freshening
and the selected shared constraint queue; keep dependent/indexed/recursive
deriving with M3+B. Repr/DecidableEq/Hashable and the other documented A gaps
remain open. Native Lean / official checking only; no pskernel-core or self-hosting.

## Current roadmap integration — readable outputs (13 October 2026)

The [source, historical-branch and qualification audit](PSCV0_READABLE_OUTPUT_AUDIT_2026-10-13.md) is now the
current output plan. JS/TS/Rust/WAT/WIT are implemented for the qualified native
subset; existing bounded Lean/PS printers and historical round trips are reusable,
but full C5 reconstruction is not implemented. Do not rebuild existing emitters
or merge unrelated historical backends.

M1 is complete at the executable/run below. Next: M2 + remaining A, then M3 + B,
M4 + C/D, and M5/E. Retain C5 source/binder/occurrence information alongside its
M2–M4 semantic owners; complete C5 source publication and correspondence under
M5/E after the required A–D language closure. This replaces the old blanket
C5-after-all-A–E scheduling rule. No new milestone track is added.

**Current code boundary:** the qualifications above cover bounded M2 instance
search, generic deriving, generalized answers and the selected shared constraint
queue. Full postponed-syntax/tactic scheduling remains open.
No C5 source emitter or source-authority migration was added. Native `.lean`, official checking,
GitHub source operations and Linux CI remain authoritative. No pskernel-core
or self-hosting; Wasm GC internally and linear memory only at explicit ABI boundaries.

## M1 completion checkpoint — preserved baseline (13 October 2026)

This section records the M1 completion baseline. The M2 qualification above
supersedes its executable status. Older pending-M1 statements are historical.

- **Qualified executable:** `c00e146bd5c97788a4a6a39221849973aeafda84`.
- **Green Linux CI:** [38388627512](https://github.com/dwijayuda/pskernel/actions/runs/38388627512).
- **250 shared runtime observations**, four shared panic cases, official kernel,
  independent RC4 oracle, negative/coherence and all existing backend gates passed.
- **292 declarations / 14 classes / 52 instances**; **175 portable / 183 native modules**.
- FNV: `fnv1a64:5949916575031563783`.
- SHA-256: `sha256:f33d923e45baf8aa5dfa6755819737acabc09daf6d60934eb232133acaad069f`.

M1 acceptance, selected universe/proof-automation scope, runtime-override ledger
and measured compiler/runtime costs are recorded in
[M1 completion evidence](PSCV0_M1_COMPLETION_2026-10-13.md). Generated JS still has substantial overhead
versus native Lean (roughly 492–3357x in these small batch measurements).
M1 completion does not establish performance parity, full M2/A/v7 completion,
or formal compiler semantic preservation.

**Accepted interleaving:** M2 with remaining A; M3 with B; M4 with C/D;
final M5/E qualification. Collect E evidence and apply measured M5 improvements
throughout. Continue the shared instance-search architecture alongside
the Phase A handlers that rely on it. Preserve native portable Lean,
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


## Latest independently qualified M1 proof-theory milestone (13 October 2026)

**Newest independently qualified executable:** [`e0ac8c69c928261e21e9593ed3f2f4aa5157385a`](https://github.com/dwijayuda/pskernel/commit/e0ac8c69c928261e21e9593ed3f2f4aa5157385a), Linux GitHub Actions [38335736466](https://github.com/dwijayuda/pskernel/actions/runs/38335736466) **passed** (13 October 2026). This supersedes older executable-status statements below, which remain as preserved history. The pinned upstream is Lean 4.35.0-rc4 (`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`). The selected Standard now contains **234 declarations, 14 classes, 40 instances**, FNV `fnv1a64:403111548970955669`, SHA-256 `sha256:6e6f1fad15d4f0cb401a09c1ebc219c3f60dd50acb21061ca9eee4ab782bd85e`; portable/native closure remains 170/178 `.lean` modules with 198 shared runtime observations on TS, direct JS, Rust, and Wasm GC/Wasmtime.

| Boundary | Evidence | Status |
| --- | --- | --- |
| Portable native `.lean` source and selected prelude | `Decision.lean` implements `Decidable` as checked structure, `Bool.Reflects`, `isTrue`/`isFalse`, and proof-driven `dite` | **Qualified** only within selected Standard |
| Native unification | Closed, typed proof irrelevance requires both values have definitionally equal types of sort `Prop`; unresolved metavariables fail closed | **Qualified** on established tests, no formal completeness/performance parity claim |
| Source proof/kernel | `Decidable P → P ∨ ¬P` and `∀ (a b : P), a = b` accepted, full native and cross-target matrix green | **Qualified** source proofs, not compiler correctness proof |
| Generic `LawfulGetElem` | Two laws remain mandatory; independent `Decidable` witnesses not yet related by a checked equality proof; attempted source theorem failed in dependent application elaboration | **Open; no instance admitted** |
| List/Array/Fin and M2 generator/consumer tabling | No additional implementations in this milestone | **Open** |

The previously recorded 230-declaration FNV/SHA source roster is superseded by 234/14/40 and the digests above. Linux green CI and exact SHA are evidence of this bounded implementation, not RC4/full-v7 parity or Lean-scale performance.


**Date:** 2026-10-13 · **Repository:** https://github.com/dwijayuda/pskernel · **Branch:** `psc0/pscv0-v7-native-lean-v1` · **Draft PR:** [#109](https://github.com/dwijayuda/pskernel/pull/109).

**Latest green executable:** [`fc8bc8b1f16ed993fb144e2d396c0760c068630b`](https://github.com/dwijayuda/pskernel/commit/fc8bc8b1f16ed993fb144e2d396c0760c068630b), [Linux CI 38323422371](https://github.com/dwijayuda/pskernel/actions/runs/38323422371) — **PASSED**. **Pinned upstream Lean:** 4.35.0-rc4, [`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`](https://github.com/leanprover/lean4/tree/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364). **Qualification remains bounded:** NOT full PSCV0 v7, Lean feature parity, metatheory, verified-emission or self-hosting.

## Newest implemented M1/M2 extension (qualified after the original audit table)

| Feature | Qualified result | Still open |
| --- | --- | --- |
| Derived optional indexing | A checked low-priority instance uses `GetElem` plus `∀ xs i, Decidable (valid xs i)`; verified `True` and `False` instances; positive, bang and missing-element observations | List/Array/Fin `Nat.lt` proofs and general polymorphic Option |
| Bang failure | Nonreturning typed `outOfBounds` in JS/TS/Rust/Wasm; proof-side definitional `Inhabited.default` | Additional runtime numeric/index boundary and memory/performance validation |
| Lawfulness | Exact `LawfulGetElem` proof fields are present and kernel-enforced | Generic lawful default witness: plain `rfl` failed because two independently scoped Decidable dictionaries are not definitionally identical |
| M2 proof-aware tabling | Completed-answer memo, normalized full goals with witness re-inference, per-invocation scoping, dependent-Pi synthesis, input-readiness scheduler | Generator/consumer waiters, complete cycle fixed point, full expected-type/universe constraint scheduling |
| M2 budgets | Independent 4096 candidate-check and 4096 goal-visit ceilings, shared through Pi scopes; exhaustion refuses | Lean-equivalent heartbeat/memory caps and real-world performance comparison |

**CI:** [38323422371](https://github.com/dwijayuda/pskernel/actions/runs/38323422371) succeeded: **198 runtime observations** in direct JS, strict TS, Rust and Wasm-related qualification, 170 portable/178 native Lean modules, pinned selected Standard **230/14/40** and official checker. FNV `fnv1a64:17137083495666611555`, SHA-256 `sha256:b0ddaa7acc463b9457aac13bd8f08a2f6f8e64bba32b76f7e469ebf1a973f08f`.

**Proof gap is architectural, not a failed assertion to bypass.** The default `getElem?` uses a stored dependent decision procedure while the `LawfulGetElem` equation allows a separate instance. It requires a checked proof of agreement (or a faithful `Decidable`/subsingleton theory), not merely `Eq.refl`. The proposed proof instance was retracted while preserving source history. No axiom, unchecked cast, stale dictionary, or source-level test relaxation was introduced.

**Status distinction:** M1 and M2 have stronger qualified selected implementations, but **neither is complete**. The following table records the earlier historical subset and should not be used as the latest progress summary.

## 1. Previously qualified milestones (historical baseline)

| Area | Source of truth | Observed evidence | Not yet established |
|---|---|---|---|
| M1: checked optional class | `packages/environment/src/Ps/Environment/StandardGetElem.lean` | Added selected `GetElem?` class, `toGetElem` superclass dictionary, `getElem?` and `getElem!` fields, checked projections; low-priority superclass projection instance. Native source and artifacts accepted. | Full 3-universe Lean `GetElem?` signature; generic default instance from decidability; built-in lawful indexing; automatic panic |
| M1: syntax/typing/erasure | `packages/syntax/src/Ps/Syntax/Pscv0/TermParts.lean`, `packages/erasure/src/Ps/Erasure/{Basic,Definition,Inductive,Expr}.lean` | Existing four `xs[i]`, `xs[i]'h`, `xs[i]?`, `xs[i]!` source spellings now include selected executable optional and bang methods; checked Core source masks still eliminate predicate family `valid` and proofs safely | Unrestricted dependent indices, optional method universe closure |
| M1: central Standard ownership | `packages/compiler/src/Ps/Compiler/Api.lean`, `packages/environment/src/Ps/Environment/SelfHostProd.lean` | Native compiler derives its internal runtime names from the **same runtime-prelude declaration list** used for code generation; accidental public export of new Standard names is refused and was corrected at the root | Provenance and complete trust closure of all selected runtime primitives |
| M2: checked answer-table solver | `packages/meta/src/Ps/Meta/SynthInstance.lean` | Replaced duplicate depth-first recursive candidate selection with a **per-synthesis answer table**, closed positive-answer reuse, rechecking with `psInferType` and `psUnify`, class input/output reconciliation, priority-preserving candidate selection, dependency worklist and context rollback | Lean's generator/consumer graph, suspended waiters, full tabling of cyclic goals, maximal universe/unification completeness |
| M2: search resource behavior | `Ps.Meta.SynthInstance.psSynthInstanceSearch` | 64-depth default fuel and separate 4096 visit budget prevent unbounded growth. An independent source-level native check observed a ground witness reused with **no new expansion**, initial count **1**. Failed/rejected goals are not cached. | Benchmark parity with Lean, terminal memory bounds for all environments and real-world concurrent IDE workloads |
| Regression evidence | `test/Pscv0NativeTests.lean`, `scripts/pscv0-native-observations.mjs`, CI | **194 shared observations** ran in strict TypeScript, direct JS, Rust and the Wasm GC / Wasmtime workflows, including 7 new indexed behaviors since the original 187 baseline. Official Lean oracle and invalid-proof refusal remain green. | Exhaustive conformance, quantified performance and formal compiler semantic preservation |

### Selected Standard snapshot

**221 declarations, 13 registered classes, 37 ordered instances**. Reviewed fingerprints:
- FNV: `fnv1a64:4160132988510892817`.
- SHA-256: `sha256:a02c9f39e6de1830497114edfaad5e9bdd5730110b562585e3f6ecc30b80b6d3`.

These identify the checked **selected** Standard payload, not the upstream Lean environment, an approved trusted supply chain, the backend runtime interpretation, or any consistency proof. The official Lean native provider remains the admission authority.

## 2. Intentional semantic restrictions

**Optional indexing:** The selected executable `GetElem?` currently requires `elem : Type 0`, because the runtime `Option` family is not yet universe-polymorphic. The superclass dictionary is computationally real, not an axiom. `xs[i]?` dispatches to an explicitly checked optional instance. `xs[i]!` dispatches to its checked method, but the current positive sample is in bounds and supplies that method; we have **not** validated general out-of-bounds panic behavior. Declaring this equivalent to unrestricted Lean `GetElem?` would be inaccurate.

**Proofs:** `xs[i]` requires real `Prop` evidence. The native tactic covers local assumptions, definitional reflexivity and bounded trivial constructors. Invalid `xs[1]` where only `i=0` is valid continues to fail at elaboration; proofs do not survive as executable data.

**Class table:** Successful answers are reused only after all expression metavariables are instantiated, with a full-target key (not the `outParam`-masked candidate lookup key). Cached expressions are **re-typechecked and re-unified**. Entries are local to the immutable environment, local instances and registry for one synthesis invocation; they must never be shared between modules, snapshots or distinct local contexts. This is answer memoization and dependency scheduling, not yet complete SLG/tabled generation with consumer waiters.

**Trust:** No pskernel-core integration, compiler self-hosting, unchecked `Bool ⇒ Prop` evidence, suppression of `PsVerifiedIrType.unknown` checks, hidden proof admission, or silent fallback in verified compilation was added.

## 3. Pinned Lean RC4 architectural comparison

- Lean [`Init/GetElem.lean`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Init/GetElem.lean) defines full-universe `GetElem?` **extending** `GetElem`, a low-priority `Decidable`-based optional instance, exact `getElem!` runtime panic semantics and the two-proposition `LawfulGetElem` contract. The current PSC subset has superclass storage and selected optional methods but does not yet cover these advanced rules.
- Lean [`Lean/Meta/SynthInstance.lean`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Meta/SynthInstance.lean) uses a true answer table with goal generators, answer consumers, suspended waiters, normalized keys, local-instance and size/resource constraints. The new PSC memo reuses validated completed answers and preserves fail-closed recursion; cyclic producer/consumer dependencies are pending.
- Lean [`Lean/Compiler/LCNF/ToMono.lean`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Compiler/LCNF/ToMono.lean) and [`MonoTypes.lean`](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Lean/Compiler/LCNF/MonoTypes.lean) explicitly erase proofs and higher-kinded type formers. PSCV0's qualified M0 roles and source masks follow this separation.

## 4. Next coherent implementation gates (without weakening acceptance)

**M1 remaining (mandatory for exact Lean parity):**
1. Generalize `Option`, `Inhabited`, and related runtime class families across selected Lean universe levels before lifting `GetElem?` beyond Type 0.
2. Implement the general `GetElem? ← GetElem + ∀ xs i, Decidable(valid xs i)` instance. The decision must produce checked `Decidable` evidence, not a raw Boolean presumed to prove bounds.
3. Provide `LawfulGetElem` with real kernel-checked `getElem?_def` and `getElem!_def` obligations. Build sound List/Array/Fin validity and lawful instances rather than inventing a generic index validity axiom.
4. Implement Lean's `outOfBounds` **kernel-definition/runtime-panic split** through an explicitly audited compilation boundary and all target backends. Check both positive and negative runtime paths, including Wasm traps; do not replace panics with defaults.
5. Expand `omega`/simplification and index proof tactic extensibility with proof-producing, bounded tactics.

**M2 remaining (mandatory for Lean-grade completeness):**
1. Upgrade completed-answer memoization to actual generator/consumer goal scheduling with suspended waiters, canonical goals and stable ordering across recursion cycles.
2. Integrate synthetic metas, postponed expected-type/universe constraints, output parameter resolution, local/ordered imported instances and deterministic rollback into a single constraint engine.
3. Benchmark class diamonds, cyclic refusal, polymorphic outputs and real compiler compile-time/peak-memory growth against the pinned Lean reference. Reject resource exhaustion without weakening proof obligations.

**After M1/M2:** continue source/recursor completeness, generic typed effects, assurance ledger and all Phase B–E gates. No C5, pskernel-core or self-hosting until explicitly requested.

## 5. Current qualification and next-chat handoff (supersedes historical checkpoints)

The **latest green executable** is [`fc8bc8b1f16ed993fb144e2d396c0760c068630b`](https://github.com/dwijayuda/pskernel/commit/fc8bc8b1f16ed993fb144e2d396c0760c068630b), [Linux CI 38323422371](https://github.com/dwijayuda/pskernel/actions/runs/38323422371) — **PASSED**: pinned official Lean, **198 shared observations** in direct JS, strict TypeScript, Rust and the V8 Wasm GC/Wasmtime workflow; 170 portable/178 native `.lean` modules. The Standard is **230 declarations/14 classes/40 instances**, FNV `fnv1a64:17137083495666611555` and SHA-256 `sha256:b0ddaa7acc463b9457aac13bd8f08a2f6f8e64bba32b76f7e469ebf1a973f08f`. Branch commits since this executable qualification are documentation-only, and draft PR #109 is still open.

**Status reconciliation:** the low-priority checked `GetElem?` derivation from dependent `Decidable`, positive/negative optional lookup, and the typed `outOfBounds` runtime panic have been qualified **after** the historical task checklist above; do not re-implement them. The **general `LawfulGetElem` proof has not been admitted** because the equation quantifies over an independent decision witness. Remaining M1: actual proof of lawfulness, List/Array/Fin validity, universe generalization and wider proof automation. Remaining M2: generator/consumer waiters, cyclic answer propagation, integrated constraints and measured Lean performance. Preserve fail-closed resource/proof semantics.

**New chat:** start from the current TOP of `psc0/AI_WORK_STATE.md` and `psc0/AI_CONTINUE_PROMPT.md`, check the live GitHub head/CI, then implement M1 before M2 with native `.lean`, the official Lean checker, minimal targeted tests and the existing Linux cross-backend milestone CI. No pskernel-core, self-hosting, C5 or Desktop Commander.
