# PSCV0 — Version 6 implementation workspace

**Status:** V6 architecture and staged implementation workspace. This folder was copied from the PSCV execution branch and reorganized on 2026-10-08. **Layout organization alone does not implement or certify V6.**

## Authorities and first steps

1. [V6 compiler reference](THE_PSCV_COMPILER_REFERENCE_VERSION_6.md) — **proposed** standalone, Lean-built, npm-first compiler architecture, optional full Lean integration, and mixed `.proof.ps`/`.proof.lean` evidence.
2. [Normative PSCV language reference](PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md) — defines `pscv-v1`, `PSCV-VERIFY-v1` and `PSCV-CERT-v1`. V6 does not silently modify its closed language or verification policy.
3. [V6 architecture map](ARCHITECTURE.md) — current source ownership, reuse boundaries and releases.
4. [V6 work state](AI_WORK_STATE.md) — new implementation tracking; historical status remains in [legacy/AI_WORK_STATE.md](legacy/AI_WORK_STATE.md).
5. [V5.1 reference](legacy/THE_PSCV_COMPILER_REFERENCE_VERSION_5.1.md) — inherited architecture and historical research.

## Active, retained implementation inputs

- `packages/`: current compiler implementation (foundation, syntax, Core, elaborator, bridges, erasure, IR, four backends), native CLI and kernel/provider integration; bootstrap compatibility modules retained **transitionally** because active code, Lake roots and tests still depend on them.
- `host/`, `scripts/`: current native host and production checked-session implementation, which V6 must reconcile before a certified standalone release.
- `contracts/`, `profiles/`, `language-authority.json`, `TRUST_MANIFEST.json`: existing semantic/profile/security and evidence contracts (some reflect V5.1/bootstrap assumptions; reuse requires review).
- `lakefile.lean`, `lean-toolchain`, `package.json`, `psconfig.json`, `psc.semantic-lock.json`, `rust-toolchain.toml`: transitional build and package configuration.
- `test/`, `stdlib/`, `theory/`, `savef/`, `factory/`, `lean-checked/`: live regression, library, theory, verification, SAVEF, benchmark and optional checker/reference integration assets.

## Archived under `legacy/`

Previous architecture drafts (original through V5.1), previous bootstrap/status/handoff and coordination documents, earlier `docs/` materials and `packages/pskernel-core.old2/`. These files are retained **byte-for-byte** for comparison and recovery, not approved as new V6 implementation authority.

**Not moved:** `packages/bootstrap`, `packages/driver-*`, `packages/pskernel-core.old3` and their tests are still imported by the existing Lake/workspace closure. Moving them before a new V6 composition is available would break baseline validation. Archive these later only after checking the complete import/test/host dependency graph and adjusting build definitions in an intentional implementation change.

## Scope and limitations

This commit performs repository organization only. It does **not** replace the production checked compiler service, implement optional Lean proof correspondence, publish npm packages, complete V6 proof obligations or establish a standalone release. Kernel implementation/metatheory remain owned by their separate workstream. The untouched `main/psc15selfhost/` folder and unrelated repository paths are not modified.
