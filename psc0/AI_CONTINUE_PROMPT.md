# PSCV0 v7 — Continue M2+A from the 14 October 2026 checkpoint

## Signed checked Standard integration — digest qualification required (14 October 2026)

The native candidate at `4c42b5b1ca4e7fccfc84d56dab20e2fb293ac976` passed [Linux 38544426724](https://github.com/dwijayuda/pskernel/actions/runs/38544426724) and source-transport run `7486f326f2f65da9d9ebff433ed24d83ff7ba5ce` passed [Linux 38545090626](https://github.com/dwijayuda/pskernel/actions/runs/38545090626), each with all 25 checks. The signed logical identity candidate has **15 checked declarations, five compared recursor rules, no new axioms, 93 shared nodes and 106,050 UTF-8 source bytes**, replacing the five old `Int8/Int16/Int32/Int64/ISize` type axioms. The signed stage is now imported after F0 Float logical identities using a separately frozen pre-signed export boundary, preserving byte-for-byte native regeneration. Prospective selected Standard count: 1,575 declarations (formerly 1,565); 23 classes and 153 instances unchanged. **This selected change is not yet qualified until independently observed new FNV/SHA hashes and full kernel/runtime regression pass.** F1 Float bits still cannot import unapproved `Classical.choice`; signed arithmetic and portable platform-width execution remain incomplete.



## M2+A next dependency: signed logical wrappers and F1 constructive Float blocker (14 October 2026)

The selected F0 Float/Float32 logical identity environment passed all 24 Linux gates at commit fbda73e1635fe35a5b7c31e2eda59a39f5e64b21, [CI 38534425757](https://github.com/dwijayuda/pskernel/actions/runs/38534425757). The F1 native bit/classification candidate at 5fc60b939efe0d509e9f98035bbee57a72369d2e failed its mandatory gate at [CI 38543575033](https://github.com/dwijayuda/pskernel/actions/runs/38543575033): its 1,075-declaration closure requires unapproved Classical.choice along Float.ofBits → Float.Model.ofBits → Float.Model.UnpackedFloat.unpack → Nat.pow_eq_zero. No source bit APIs or new trusted axioms were admitted. The native authoring command remains for constructive research; its unapproved candidate is not a mandatory regression gate.

Pinned Lean 4.35.0 src/Init/Data/SInt/Basic.lean provides an independent completion path: Int8/16/32/64 and ISize are genuine one-carrier checked inductives over their unsigned counterparts. A strict signed identity exporter is being qualified now, without runtime enabling, pskernel-core or self-hosting. Next: validate exported metadata and original-kernel replay, then sign-correct conversions and runtime operations. Remaining M2+A and F1–F4 are incomplete.



## F0 selected Standard digest — independently observed (14 October 2026)

Linux [run #38534047864](https://github.com/dwijayuda/pskernel/actions/runs/38534047864) at `bdfdb6b6402618908c1d52aa6494f37df7483713` compiled the newly selected 51-entry Float/Float32 Core model, independently regenerated its 254,044-byte source **byte-for-byte**, passed the F0 annotation and native-kernel negative probes, and correctly refused the previous /61 Standard digest. The run's independent candidate for the new selected Standard fingerprint was **FNV `fnv1a64:4585335486592655667`** and **SHA-256 `sha256:3bed7c1104a6209f6af124e932ce7c7ae6401f0f9483896e6730c51ffd35d0ca`**. These are now pinned in `StandardSnapshot.lean` without weakening either validation guard. The new selected environment is **pending full official kernel, source, runtime and CI qualification**; the last fully green regression remains `bb2dbbcc` on the unchanged /61 environment. F1–F4 executable Float, M2+A and later milestones remain open.



## F0 logical identity asset selected — kernel/registry qualification in progress (14 October 2026)

The pinned native F0 candidate passed all 24 Linux regression steps at `bb2dbbcc6432401fedf7f73f1b174d7ee765c3ab`, [CI #38532887281](https://github.com/dwijayuda/pskernel/actions/runs/38532887281), including rejection of a forged Format.mk signature. Exactly 51 logical entries were generated, with 8 independently compared recursor rules, no new axioms, and only pre-approved `propext` and `Quot.sound` in the existing foundation. Frozen candidate source: 254,044 UTF-8 bytes / SHA-256 `47e9e2ac59dc256d108e801e38c57a238c7cdfa1d1f06c16df2fd3390cf50501`. New pre-F0 exporter stage keeps the original /61 boundary. Integrating the selected source replaces exactly 2 legacy type axioms, so the prospective Standard declaration count is 1,565 (previously 1,516); classes and instances are not modified. **Selection is not qualified until a new independently observed FNV/SHA registry snapshot, official kernel replay, negative conformance and broad Linux workflow pass.** Float ofBits/equality/arithmetic/scientific/runtime/ABI (F1–F4), M2+A and later milestones are still incomplete.



## F0 Float identity — checked candidate qualification (14 October 2026)

Commit [`9b5f04e`](https://github.com/dwijayuda/pskernel/commit/9b5f04ed5b87707410dd859a247e0d724f326cc8) completed all 24 Linux gates in [Actions run 38531327231](https://github.com/dwijayuda/pskernel/actions/runs/38531327231). Native authoring exported **51 dependency-closed Float/Float32 logical identity declarations**, replaced exactly the legacy `Float`/`Float32` type axioms inside a discarded candidate, compared **8 recursor computation rules**, and independently replayed the candidate through the official pinned Lean 4.35.0 kernel. Imported candidate axioms: **none**; approved pre-existing foundation: exactly `propext` and `Quot.sound`. Source: 254,044 bytes / 1,444 shared source nodes. The **/61 selected Standard remains unchanged**, with 1,516 declarations / 23 classes / 153 instances, 426 cross-target observations and original frozen fingerprints. **F0 is not yet selected/published; runtime Float functionality, F1–F4 and M2+A remain incomplete.**

Root cause: pinned `Float.Model.Format.mk` constructor carries elaborator-generated `autoParam` tactic annotations. These transitively refer to `Lean.Syntax` but are definitionally equivalent to their annotated proof types. The native F0-only exporter removes only fully applied `autoParam` wrappers, proves each transformed signature in the original native environment with an ephemeral official-kernel typed alias, refuses altered term bodies, and separately replays the portable Core with exact regenerated metadata. Unrelated `optParam`/real Syntax dependencies remain untouched. The next authoring checkpoint adds negative policy probes and publishes the full verified candidate source through Linux Actions text logs for review; **no snapshot or release capability change is claimed until integration and requalification.**



## Current F0 implementation/audit slice — 14 October 2026

Verified last full-green executable: `34ff236b6fe9f936d7d44b8ace1c70612c7cc66e`, Linux [38515443060](https://github.com/dwijayuda/pskernel/actions/runs/38515443060), selected /61 1516 declarations / 23 classes / 153 instances and 426 shared runtime observations. Draft PR 109 remains open. Do not call F0 or M2+A complete.

New F0 design/inventory checkpoint: [Float logical/runtime boundary plan](docs/PSCV0_FLOAT_LOGICAL_RUNTIME_BOUNDARY_PLAN_2026-10-14.md), updated at `5675dafa`. Explicitly separates existing Float/Float32 name and IR scaffolding from the absent checked Standard logical families. Audits pinned Lean 4.35.0 Model/Float, Model/Float32, bits, IEEE-vs-structural equality, scientific literals and runtime/ABI proof obligations. No new source Float support is claimed.

New executable F0 *read-only closure discovery* at `64a79a738d279e973839c624468fbec222212eb5` expands the existing native `--audit-standard-closure` to both Float wrappers, bit transports, BEq and OfScientific. Linux [38521251051](https://github.com/dwijayuda/pskernel/actions/runs/38521251051) **completed successfully** at executable `64a79a738d279e973839c624468fbec222212eb5`. Its read-only F0 closure audit, official checker, parser/refusal suite, JS/TS/Rust, GC/Wasmtime component and existing performance gates passed. This certifies only audit tooling and unchanged /61 behavior; **Float and Float32 source/runtime are not yet implemented or qualified**. This does not import, assume, or emit floating declarations. Next, select a complete closed Lean logical model F0 candidate and replay it in the official kernel with strict assumptions/snapshot boundaries; then implement F1–F4 in dependency order. Preserve no C5/self-hosting/pskernel-core scope, no new assumptions, and existing cross-target baseline.

## Post-/61 research checkpoint — Float/Float32 semantic closure

Reviewed pinned Lean 4.35.0 `Init/Data/Float/{Float,Float32,Model/Float}.lean`, `Init/Data/OfScientific.lean` and the upstream floating conformance tests. The new [Float logical/runtime boundary plan](docs/PSCV0_FLOAT_LOGICAL_RUNTIME_BOUNDARY_PLAN_2026-10-14.md) pins canonical NaN bits, Boolean vs propositional equality, signed zero, f32 rounding, exact scientific literals, cross-target runtime/ABI responsibilities and negative conformance. **Research only: no Float implementation or new proof assurance is claimed.** Next dependency order is F0 selected Core closure, F1 bits/classification, F2 arithmetic/BEq, F3 conversion/literals, F4 all-target qualification. /61 remains last green executable at `34ff236b`, CI `38515443060`.


## New qualified /61 checkpoint — 14 October 2026

Executable commit `34ff236b6fe9f936d7d44b8ace1c70612c7cc66e` passed the full Linux workflow
[38515443060](https://github.com/dwijayuda/pskernel/actions/runs/38515443060).
Profile `pscv0-v7-native-bounded/61` is **green for its declared selected scope**; this
does NOT mean M2+A, all v7, C5, full compiler metatheory, or formal backend preservation
are complete. Standard selected 1516 declarations / 23 classes / 153 instances, FNV
`fnv1a64:6333670853941549394`; SHA candidate
`sha256:ebf02f5f8dfecf3769cbaeaa52e39dac3ba9c8dc034ea5284655da324bc75d60`.
426 shared cross-target runtime observations passed for TypeScript, JS and Rust;
Wasm GC/Wasmtime component, linked projects, parser/negative conformance, official kernel,
asset regeneration and performance gates passed. These are bounded runtime observations,
not a proof that every possible backend program preserves Lean semantics.

Resolution: the official Lean 4.35.0 `Init/Prelude.lean` defines
`Unit : Type := PUnit` and `Unit.unit := PUnit.unit`, but PSC0's APP-03
empty-call path rejected a fresh *universe metavariable* in the
`PUnit` argument domain before checked unification. The source check
now distinguishes unresolved term types (still refused) from the known
Unit/PUnit family, solves the universe using ordinary checked unification,
then rechecks definitional equality and inserts an ordinary typed Unit inhabitant.
All positive APP-03 cases (including `PUnit`) and the existing negatives passed.
No new axiom, untrusted cast, permissive fallback or relaxation of source/kernel
acceptance. Previous historical /61 failures and /60 baseline below remain for
audit but are superseded by this independently qualified executable checkpoint.

Further upstream sources studied for preceding /61 root fixes:
`src/runtime/interrupt.cpp` (thread-local heartbeats),
`src/kernel/environment.cpp` (checked `lean_add_decl`),
`src/Lean/Environment.lean` (`Kernel.Environment` checked replay),
`src/Lean/Declaration.lean` (kernel reducibility hints),
`src/Init/Data/UInt/Basic.lean`, `src/Init/Data/Hashable.lean`,
and `src/Init/Data/String/Defs.lean`.
Use pinned commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
Upstream licensing is acknowledged in the adapted source and
`psc0/THIRD_PARTY_NOTICES.md`.

Next: make `/61` the qualified baseline, update the latest frozen snapshot and
milestone status documentation consistently, audit hot-path performance/resource
telemetry, and continue the remaining M2+A language/standard exit criteria
without starting C5 or self-hosting.


Continue autonomously, but **update AI_WORK_STATE.md and this continuation prompt
after every milestone slice** before starting the next. The previous chat had
about 4% usage remaining. Read the work state and linked canonical specification,
architecture, roadmap and design receipts first. Do not assume transient tool
stores or unpublished parser drafts are available.

Repository: dwijayuda/pskernel.
Branch: psc0/pscv0-v7-native-lean-v1.
Preserve draft PR109: https://github.com/dwijayuda/pskernel/pull/109.
Use GitHub connector source operations and Linux Actions only; no local checkout,
shell/build or Desktop Commander. Native portable .lean, official Lean 4.35.0;
no pskernel-core, self-hosting or compiler-source .ps migration.
Wasm GC internally; linear memory only at explicit ABI boundaries.
Fetch live HEAD and CI; use expected-HEAD non-force writes. Do not merge.

Study the corresponding official Lean source/tests before substantial changes,
pinned to eb6cafb7290e8bd5f2937522d8d804f58f02bafc. Implement coherent shared
mechanisms, then focused and existing integration validation. No fabricated
axioms, relaxed acceptance, unchecked kernel fallback or symptom-specific patches.

The user already explicitly approved exactly pinned **propext and Quot.sound**
for the audited foundation. Do not request this approval again. All dependent
proofs still require official kernel checking; no further assumptions approved.

## Latest continuation: kernel-only replay, awaiting qualification

Run [38479812733](https://github.com/dwijayuda/pskernel/actions/runs/38479812733)
at `15cea236` passed build, quotient probes, frozen regeneration and GetElem
erasure. It failed later on a malformed new List.foldl fixture; it also exposed
AsyncConsts collisions between distinct imported private names.
The next code commit moves standalone checking/replay to official
`Lean.Kernel.Environment.addDeclCore` at trust zero, preserving full names and
all kernel checks. It fixes the fixture's APP-03 argument order and compiles the
provider Admission module to validate the changed API. No new assumptions.
The earlier quotient/Unit failure descriptions below are historical diagnoses.
Fetch the new run and inspect complete results; /60 remains the last full green.

## Exact current evidence

Latest code: 1f54142c6225020c39265254a582860bd4169937.
A documentation-only checkpoint follows it; fetch the actual branch HEAD.
Profile /61 is under qualification; **M2+A remains incomplete**.

Latest run38478159236, job115573914577, completed FAILURE:
https://github.com/dwijayuda/pskernel/actions/runs/38478159236

Build, frozen asset regeneration and strict digests passed. Source erasure failed:
`PSCV0-ERASURE: unknown constant Unit.unit (in PsStandard.instInhabitedUnit)`.
The log also contains repeated official-Lean duplicate normalized name Quot
panics. Native/backend integration was not reached. Fix both causes; continued
execution or a kernel receipt does not make the panics acceptable.

Last full green: d72fc7779b2e8d130915dfe4ace339634ba0addd, profile /60,
https://github.com/dwijayuda/pskernel/actions/runs/38466179341
399 shared observations +4 panic contracts; 217 portable/227 native modules;
Standard672/23/109. ToFormat/Repr, selected Hashable/nonrecursive deriving,
UInt/BitVec construction/conversions and typed unsigned ABI were qualified there.

## Repair slice has now been implemented; qualification first

A code commit after checkpoint 85b35cd implements quotient-group single admission,
exact descriptor validation, shared nullary erasure including PUnit's normalized
carrier and cache cleanup. It expands the existing quotient probe only.
Fetch the latest code/run and qualify this slice before the unsigned interface.
The steps below record the implementation's intended invariants, not missing
changes to apply again. Update both documents after CI.

## Repair design and validation

1. Study pinned kernel/quot.cpp, Lean/Environment.lean, Lean/Declaration.lean
   and quotient/collision tests. In
   psc0/packages/pskernel-lean/provider/PsKernelLean/Prelude.lean,
   all four quotient descriptors currently become the same generative .quotDecl,
   then tryPreludeDeclaration unconditionally re-adds it. Separate single group
   admission from exact member validation. Generate once; validate all descriptors
   against checked kernel metadata; reject partial groups, collisions and forged
   signatures. Do not silently ignore general duplicate declarations. Reuse the
   mechanism for authoring and production replay; retain Hash-stage refusal probes.

2. Inspect the shared erasure constant/application/eta boundary in
   psc0/packages/erasure/src/Ps/Erasure/Expr.lean and helpers. Unit.unit changed
   from axiom to checked native definition, so ordinary definition resolution
   now precedes its late literal fallback and requests a nonexistent runtime
   support entry. Centralize builtin literal/runtime identity handling before
   ordinary definition lookup for all call forms. Check related Bool/Nat literal
   identities and preserve arity/overapplication refusal. Do not import the
   logical proof closure into runtime support.

3. Remove only the temporary exact-old-key cache fallback from
   .github/workflows/psc0-pscv0-native-v7.yml; the latest run saved the new
   OS/architecture/toolchain-keyed cache.

4. Run existing focused gates and the complete native workflow. Inspect logs
   for panics; require independent native oracle, strict IR, JS/TS/Rust,
   V8/Wasmtime GC, WIT/WAT/components/ABI/projects and existing performance gates.
   The later four SHA known-answer vectors also still need execution. Update
   both handoff documents with exact results. Do not declare /61 or M2+A complete
   from build/digest success alone.

## Already implemented; do not redo

Unsigned operation asset: 803 declarations, 49,978 shared nodes, 6,457,592 bytes;
48 UInt8/16/32/64 operations, actual Nat.div, 24 arithmetic dictionaries,
exactly two approved axioms and four kernel quotient descriptors.
Six native definitions replaced old axioms: Nat.decEq, Bool.decEq, Unit.unit,
Unit, Nat.blt, Nat.div. Frozen exporter and exact regeneration are in place.
Proof dependencies stay outside runtime support.
15 unsigned shared/native observations plus product/display additions await
full integration; related unsigned div/mod/shift backend code already exists.

Current strict payload pins (independently obtained before optimizing checksums):
fnv1a64:16613033526791726173
sha256:8aea3c6be714db09f4a5a442e9fab57a40bdf13c11d86e811c2574165d55b04d

UInt64 FNV / UInt32 SHA and packed ByteArray now preserve those digests, sharing
canonical payload serialization. Audit/export startup fell from about73s to
2–5s in measured CI. Native rebuild12,317ms /warm561ms. Do not revert to boxed
Nat word arithmetic or confuse these bounded timings with full performance parity.

See AI_WORK_STATE.md and docs/PSCV0_M2_A_SCALAR_COMPLETION_2026-10-14.md for
the full evidence, source references, earlier Prod/List/Bool corrections and
remaining unsigned comparison/conversion/class-registration design.
Parser drafts were only in memory, never compiled/published: reconstruct the
shared longest-adjacent-operator plan from pinned notation/parser sources.

## Continue after this slice

Finish unsigned comparison/conversion/bitwise interface registration, then the
remaining M2+A exit gates: signed/platform words, Float/scientific, expanded
BitVec/bytes/selected APIs, comprehensive manifest, broader M2 evidence and
C5 semantic retention. Use the established roadmap:
**M2+A → M3+B → M4+C/D → M5/E**.
Recursive/indexed/dependent deriving belongs to M3+B.
Keep readable JS/TS/Rust/WAT/WIT via shared plans and retain semantics needed
for later C5 readable Lean/ProofScript reconstruction. Do not duplicate existing
backends or claim bounded printers/source replay establish full correspondence.

At each milestone slice, checkpoint exact HEAD, CI URLs/results, completed
versus unqualified work, blockers and next steps in BOTH handoff documents.
Preserve honest incomplete status until the canonical exit gates are satisfied.
