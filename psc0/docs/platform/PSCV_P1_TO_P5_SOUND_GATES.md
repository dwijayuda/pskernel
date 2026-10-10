# PSC0 PSCV P1–P5: sound execution and acceptance boundaries

**Status: stagewise implementation roadmap, NOT a declaration of P1–P5 completion.** Read alongside the [P0 ownership map](PSCV_PROFILE_AND_PACKAGE_BOUNDARIES.md) and exact PSCV normative RC-v2 source. All proof/certificate claims must be tied to a selected semantic version, approved specification, exact input/environment/profile, kernel admission, and executable preservation assumptions.

## P1 — approved closed semantic environment

Existing qualified P1-A through P1-E checkpoints pin Lean **4.35.0-rc3**, source provenance, ambient registry observation, 3 direct Boolean source mappings, a class-head index and 7 real imported-environment typed synthesis witnesses. **None of this is the closed Standard.**

P1 exit requires all **194 distinct** required IDs (230 rows) mapped exactly once to appropriate declarations and class/basis types, including 191 unresolved IDs, with actual elaborator resolution (including transitive generic dictionaries), scoped visibility, priority and tie semantics, source blob/line provenance, and ordered approved `instances/default_instances/coercions/simp/simprocs/ext/grind`. The permitted effects/WP and options must be frozen with conformance checks. Ratify a versioned manifest digest by approved normative revision. The 9,742 ambient Lean instances are not automatically allowed. Independent Core rc4 work must not silently replace the normative rc3 target. Until P1 closes, `pscv-v1` remains unavailable.

## P2 — independently certified *pure source/Core* pilot

First select an approved pure specification/source profile and authenticate every input byte, imported dependency, environment and approved trust assumption. Produce mandatory obligations from an independently justified completeness rule, not from a plugin's asserted list. Reject missing, duplicate, changed, or unproved obligations. Recheck the exact proof terms with the selected authoritative kernel; enforce totality, axiom/assumption/effect and ghost/erasure closure. Only the supervisor may create the protected internal verified handoff. **Do not claim that generated TypeScript/JS is verified merely from P2**. The production certification gate stays fail-closed until this work is independently qualified.

## P3 — broaden normative language by proof-preserving slices

Implement and qualify the exact bounded grammar and fixed Standard tactic surface, theorem placement/proofs, refinement types, contracts/call sites, recurrence and termination, verified `do`/state, for/while loop obligations, ghost/noninterference, imports, WP/verified effects, and approved standard libraries. Each slice needs source-to-Core interpretation, independently complete obligations, genuine kernel replay and negative conformance. Missing feature slices must refuse the *full PSCV* profile; success on a subset cannot claim complete language conformance.

## P4 — executable correspondence and replayable artifacts

For P2/P3 certified source/Core programs, establish the selected erasure -> RuntimeIR -> TS7 backend/ABI/runtime correspondence with sound preservation arguments, checked validators or **explicitly declared** trusted implementation assumptions. Bind every verified handoff, compiler pass, runtime/FFI dependency, output bytes, environment, provider and receipt together; independent replay must detect substitution. Without the preservation link, publish only a correctly scoped checked or source-certified result, not an end-to-end verified executable.

## P5 — full conformance and release qualification

Complete positive/negative tests for every normative syntax/semantics/Standard registry feature and resource/failure rule; independently replay kernel proofs, required-obligation coverage, provider identities, erasure/backend claims and certificates. Run clean-machine npm Windows/Linux qualifications with durable binary/toolchain retention, exact manifests and reproducible source/seed references. Publish a claim matrix listing proved guarantees, trusted assumptions, incomplete proof obligations and bounds. A green CI suite alone is not a mathematical consistency or compiler-preservation theorem.

## Preserve independence and no promotion by convenience

- Keep existing PSC0 compiler layout; use logical `pscore`/`psfrontend` interfaces without folder renames solely for style.
- Preserve the 62-module compiler/self-host source and selected authoring seed, TypeScript 7 baseline, pinned release native kernel and separate Core proof/refinement branches.
- Proof companions live in `psc0/proofs/**/*.proof.lean` when implemented, may use full Lean/tactics and remain outside ordinary self-host builds.
- P0/P1 metadata and candidate proofs cannot mint `PSCV-CERT-v1` or `VerifiedExecutableModule`. A requested certified build fails rather than downgrading to ordinary checked output.
- An optional plugin may propose candidate syntax/proofs/IR, but it may not alter the supervisor's necessary obligation set, proof admission, disclosure or publication authority.
- Never infer unobserved P1 closure from selected Lean imported-environment examples. The next actionable P1 family is **transitive concrete dictionary selection plus source/declaration-line provenance**, not more name-only heuristics.
