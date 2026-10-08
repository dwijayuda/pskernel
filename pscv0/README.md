# PSCV0 — Version 6 compiler workspace

**Current direction:** a new, minimal kernel-first compiler core with npm-first distribution, rather than preserving the prior PSC2/self-host implementation architecture.

## Start here

- **[New clean V6 core workspace](v6/)** — authority-conscious, npm-shaped packages implemented from scratch; currently P0, not yet a full PSCV compiler.
- **[Core npm design and soundness/security evaluation](v6/CORE_NPM_ARCHITECTURE.md)** — package boundaries, extension classes, source fidelity, kernel identities, optional Lean proofs, threat model and milestone gates.
- [V6 compiler reference](THE_PSCV_COMPILER_REFERENCE_VERSION_6.md) — standalone Lean-built compiler target and four backends.
- [Normative language reference](PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md) — closed PSCV semantics, verification and certification requirements.
- [V6 work state](AI_WORK_STATE.md) — check current branch/CI results before making readiness claims.

## Existing prior-implementation material

Previous packages/, host/, scripts/, contracts/, test/ and related files remain physically present for the existing compiler and provider rebuild paths. They are **not dependencies of the new v6/ core**, not compatibility obligations and not reasons to retain old architecture. Once the new core has replacement capabilities and regression evidence, obsolete implementation files can be deleted in separately reviewed commits; ordinary Git history remains available.

Historical research and V5.1 design are in [legacy/](legacy/). Existing official Lean kernel npm provider facades remain independent dependencies for P0 admission checking. Kernel correctness/metatheory is a separate workstream.

**No automatic certification:** current v6/ code can inspect source bytes, validate extension manifests and ask the pinned native/Wasm Lean 4.34 kernel to check a canonical admission stream. It does not parse or compile arbitrary .ps, produce PSCV certificates, compile four backends or support .proof.lean yet.
