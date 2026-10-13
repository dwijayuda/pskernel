# PSCV0 v7 — Continue M2+A from the 14 October 2026 checkpoint

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
