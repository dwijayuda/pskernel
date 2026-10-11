# PSKernel-Fast: new-chat continuation prompt (P1g and beyond)

**Handoff written October 11, 2026. Read live GitHub before making ANY change.** The user owns this public open-source repository. This is authorized programming-language/compiler/kernel correctness, Lean semantics, theorem proving, formal verification, model construction and differential/conformance testing; no offensive-security work is intended.

## Mission

Continue **PSKernel-Fast**, independently designed for **very high real-kernel performance, exact Lean 4.35.0-rc4 semantic compatibility, small trusted checking authority, implementation/refinement metatheory and a CONDITIONAL consistency theorem**. Correctness and performance matter more than preserving old kernels, a premature proof interface, or an aesthetically pleasing prototype.

Work SYSTEMATICALLY and autonomously through meaningful, checkable milestones: inspect semantics/invariants and mathematical proof obligations, make coherent architecture choices, implement proof-first vertical slices, validate exact GitHub CI, and checkpoint with honest records. Avoid repeated local test-fix patches, per-counterexample semantic weakening, unsupported axioms, and claims that a structural typing proof already establishes a sound Lean kernel.

## Canonical repo/branch/toolchain

- Repository: https://github.com/dwijayuda/pskernel
- **ONLY active development branch:** `research/pskernel-fast-clean-v3-20261011`; existing branches/history and PRs must remain untouched. Do not merge or delete without an explicit request.
- Exact official compatibility target: `leanprover/lean4` `v4.35.0-rc4`, source SHA `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.
- **GitHub/cloud Actions exclusively. Do not use Desktop Commander, local checkout/build/test, or local repo filesystem.** Use GitHub connector to read/write and cloud CI for compilation/proof validation. Before each write re-fetch live branch HEAD and target file blob SHA. Never force-push or discard concurrent work.
- Canonical state: `pskernel-fast/AI_WORK_STATE.md`, `pskernel-fast/ARCHITECTURE_POLICY.json`, `pskernel-fast/PSKERNEL_FAST_SOUNDNESS_CONTRACT_V1.md`, `pskernel-fast/P1F_TAGGED_MODEL_EVIDENCE.md`, `pskernel-fast/P1F_TAGGED_MODEL_EVIDENCE.json`.
- Previous confirmed HEAD when this handoff started: `5412f4facbb8e72b53312ace262a1c097e718473` (**documentation-only** successor). DO NOT assume it is still HEAD; compare before writing.
- Last green checked **source/proof**: `367ddf25d3d97e7fb0b88c86dbeed7410d51dc10`, [CI #38129546961](https://github.com/dwijayuda/pskernel/actions/runs/38129546961).
- Last confirmed green **policy and full closure**: policy commit `779b65d3913a9dc7dd069009402f4ad87d2a9bfd`, [CI #38129970282](https://github.com/dwijayuda/pskernel/actions/runs/38129970282), job `114442084919`: **SUCCESS; pinned Lean 4.35.0-rc4, 94 Lake build jobs, 42 independent Lean modules audited, 110 exact theorem-assumption receipts, existing G1-G4.3b smokes green**. Re-fetch Actions runs/jobs/logs because later work may exist.
- Proof receipts are checked by `pskernel-fast/scripts/audit_axioms.py` with allowlist `propext`, `Classical.choice`, `Quot.sound`, failure on `sorryAx`/unexpected/missing receipts. The `SetTheoryBasis V` class is a **separate explicit strong MATHEMATICAL ASSUMPTION**, not a globally constructed instance, and is not reported as an additional `#print axioms` token.

## Actual verified state — never overclaim

- G1–G3: independent AST, structural preflight, preliminary beta/closure evaluator experiments; beta-only benchmarks do NOT establish real Lean kernel performance.
- G4.0: positive-sound symbolic universe equality, still incomplete (known official positive gaps).
- G4.3b **running checker**: restricted six-rule `Sort`, bound variable, dependent `Pi`, lambda, **syntactically exact** application types, and `nondep=false` let. `inferClosedGeneralPi` yields only a restricted typing-judgment witness; no real proof admission. Executing source qualified at `253afb42b477aacab22def288a2dd42d7ca9633b`.
- P1a/P1b: independent context/scope proofs, exact executable lift/substitution algebra, *bounded* typed beta/let subject-reduction and variable weakening; **NOT** general dependent typed substitution.
- P1c: independent ground-level erased syntax; executing lift/substitution commutes with erasure; successful G4.3b source/type ALWAYS has an erasure. Erasure is not set denotation.
- P1d: independent explicit `SetTheoryBasis V` ZF/Grothendieck model interface; conditional `Sort` and two-truth-value proposition mathematical rules; executable Pi codomain `Prop` classification. These are partial components, not a full model.
- P1e: proof-only `interpProp` interprets a restricted proposition-valued AST. The actual G4.3b checker accepts `∀ (P : Prop), P` and `∀ (P : Prop), P → P`, with independent source erasure and interpreted **false** and **true** values. `CheckedPropAnnotation` has genuine typing evidence; Pi set membership still requires separately established semantic fibre validity. These verified examples use an OLDER, provisional Prop carrier — they have NOT been requalified with P1f's tagged point.
- **Formal model-design failures:** Original provisional `True={empty}` forces its point to be a proposition value. V2 candidate equals a writable Kuratowski pair of `(empty,empty)`; both unsuitable for final Lean proof/data separation. Preserve their proofs as negative evidence, not as final model designs.
- **P1f new verified proof-only mathematical substrate**:
  - `Spec/SetEncoding.lean`: model singleton, Kuratowski pair, function graph and finite von Neumann numerals.
  - `Spec/TaggedProofPoint.lean`: `tag={empty,{{empty}}}`, `pt={tag}`, `True={pt}`, `Prop=powerset(True)`; tag not singleton or ordered pair; point ≠ encoded pair/graph/finite numeral and is NOT in Prop; pt IS in True; exactly two Prop truth values. Also proves **unrestricted image may equal pt**.
  - `Spec/FiniteUniverseClosure.lean`: pair closure in an inhabited Grothendieck universe **DERIVED** from Tarski's size/closure laws with finite pigeonhole argument; no new universe closure axiom.
  - `Spec/TaggedPointUniverse.lean`: tagged point/tag/True/Prop are in first positive Type universe; shifted tagged `Sort u` belongs to successor `Sort (u+1)` for ALL level valuations.
  - P1f tagged model is NOT YET the canonical `sortSet`/`propPi`/`interpProp` used by the P1e source proofs. It is qualified against the **specific defined representations**, not every possible set-valued computation or every quotient.
- **All major capstones STILL FALSE** in policy: a constructed `SetTheoryBasis V` instance, general term interpretation/`WellDenoted`, full proof irrelevance, typed quotient writable-slot safeguards, Type-valued dependent function graph semantics, general typed WHNF/DefEq, fully checked immutable declarations, model extension, relative `model_exists` / `no_derived_False`, official Lean 4.35 / Mathlib full compatibility, and actual kernel-only performance benchmarks. `admittedDeclarations=0` and `acceptingAdmissionAPIImplemented=false`.

## Crucial research boundary (DO NOT gloss over)

Con-leche's proof-point `ptTag={empty,{{empty}}}` is carefully selected for noncollision with **writable** numerals, Kuratowski pairs and graphs. But **universal quotient freshness is FALSE**: con-leche's `ConLeche/SetTheory/Derive/Quot.lean` proves `quotSet_eq_pt_countermodel` for unconstrained quotient inputs. P1f independently proves a general unrestricted image can equal pt. Therefore guard quotient/proof-point freshness at the **actually well-typed writable source syntax/model interface** and prove preservation; never add a false universal `QuotFreshness` axiom, blanket trusted helper, or arbitrary unchecked frontend annotation. Source references:
- https://github.com/leanprover/con-leche/blob/master/ConLeche/SetTheory/Derive/Pt.lean
- https://github.com/leanprover/con-leche/blob/master/ConLeche/SetTheory/Derive/Graphs.lean
- https://github.com/leanprover/con-leche/blob/master/ConLeche/SetTheory/Derive/Quot.lean
- https://github.com/leanprover/con-ron (independently optimized representation refinement)
Con-leche's current proof toolchain was studied at Lean 4.35.0-rc3; PSKernel-Fast is pinned to rc4. Its mathematical theorems DO NOT automatically certify this kernel.

## Next P1g: precise implementation/proof plan

1. **Inspect first**: LIVE HEAD/CI, state/policy/evidence, `TaggedProofPoint`, `TaggedPointUniverse`, P1d `UniverseSemantics`/`PropPi`, P1e `PropInterp`/`CheckedPropAnnotations`/`CertifiedPropExamples`. Enumerate old provisional model dependencies. Identify one canonical proof-only tagged semantic representation and a clean migration boundary; avoid adding parallel mutually inconsistent "final" models.
2. **Coherent tagged-model migration**, not a patch swarm: introduce a small **single-source-of-truth proof-only tagged Prop model** (or a justified parameterized model interface only if it really reduces proofs) comprising `pt`, true/false, Prop carrier, shifted Sort tower and explicit model membership laws. Ensure the existing proven P1f tag/point freshness lemmas remain reused without changing executable G4.3b semantics.
3. Define tagged proposition-valued `Pi` and a non-authoritative `interpTaggedProp` with correct semantics, **explicit validated fibre/annotation premises**, and proof-point-aware membership rules. Prove semantic true/false denotations of the same two ACTUALLY CHECKED source terms under the **new tagged carrier**; validate source erasure, checker-generated codomain regime and exact symbolic imax. Do not merely relabel old theorems with the new carrier.
4. Build hereditary semantic `WellDenoted`, typed Proof-vs-Type regime separation, proof-point behavior and beta/let denotation. Then independently construct **Type-valued** dependent graph Pi with actual set-theory closure/eta/app laws. Handle quotients through typed-slot/syntactic guards, **not** false global freshness. Preserve independent model assumptions, identify remaining Trusted Computing Base boundaries.
5. Only later: complete G4.4 typed WHNF/DefEq and all Lean universe/inductive/quotient primitives; build protected `FullyChecked` environment and model-preserving declaration fold; establish conditional set-model existence and no-derived-False, plus rigorous independent official Lean conformance and **real kernel-only** CPU/RSS/allocations benchmarks. Performance architecture stays flexible; proof work must not freeze an inferior kernel.

## Working methodology and handoff rules

- **Architecture/semantics first, tests second.** Prove general mathematical lemmas/invariants and diagnose root cause on Lean elaboration/CI failures. Do not change truth/acceptance semantics merely to satisfy a smoke test; no fix-hunting/patch stacks or weakening premises to make theorems compile.
- Keep the mathematical assumption boundary sharp. A theorem conditional on `[SetTheoryBasis V]` is **not** a proof that the model exists. A checked source proposition having a value is **not** proof term admission or a full kernel consistency theorem.
- Keep source `Spec` (mathematical assumptions and syntax), `Proof` (bridges/lemmas), and `Core` runtime authority isolated. Any external plugin, cache, fast normalization, theorem certificate or unchecked binder hint must NEVER authorize `Accepted`. Existing proof branches/PRs untouched.
- Before EACH write check live HEAD and file blob SHA; serial non-force updates; preserve concurrent commits. For changed source/workflow/policy, check EXACT commit GitHub Actions job outcome and full logs; report failed attempts transparently, do not assert green before confirmed.
- Update `pskernel-fast/AI_WORK_STATE.md` **at every meaningful green checkpoint** with actual HEAD, CI ID/job, succeeded/failed proofs, negative countermodels, remaining flags and next plan. Maintain `ARCHITECTURE_POLICY.json` and evidence with **strictly truthful** proof-status booleans. Do not stop just for unnecessary status reports if substantial work remains; give a bounded result and continue while tools allow.
- If the chat grows long, write a refreshed self-contained continuation prompt and current state file before ending.
- No local checkout or Desktop Commander. GitHub and cloud CI are the canonical source of truth.

**First response in the new chat:** verify live GitHub HEAD and the latest green run; report the actual (possibly newer) P1f/P1g state, then begin coherent P1g tagged semantic model integration and proof-first validation. **Do not assume the handoff SHA is current.**
