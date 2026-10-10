# PSCV P1 — exact RC3 semantic pin and provisional profile inspection

**Status:** P1-A, source provenance and experimental, read-only profile selection. NOT a complete Standard environment manifest, PSCV compiler, PSCV-CERT-v1 issuer, or executable authority.

## Keep the normative RC3 semantic target, do not silently substitute RC4

The canonical PSCV-RC-v2 reference is Git object 208f128c13be2e07fde25ca413641a48df214324 and source SHA256 4c02626fd0b991e8526c64b65f4ffb66b9ce7b688298e82fb0309802a263db71. It specifies exact Lean 4.35.0-rc3 commit 470d5ce1400764999581fd26d5d72b00d990b0f4.

Separate PSKernel Core refinement currently targets RC4; the current PSC0 compiler/native provider retains historical Lean4.34. These must not silently be called one semantics. Moving normative PSCV RC3 to RC4 requires a new versioned semantics decision, source mapping, full environment regeneration, kernel/provider conformance and explicit approval. The compiler self-host pin can remain historical if a separately qualified bridge becomes available.

## Forty immutable source roots are not a Standard environment

Normative Appendix K.1 lists 23 immutable semantic source roots, and K.2 lists 17 prover roots. They identify the upstream source files and blob SHA-1 values, **not** which instances, coercions, simp, simprocs, ext, or grind registrations are activated.

New packages/pscv/src/lean-provenance.mjs parses Appendix K from the entire hash-checked canonical normative file, refuses duplicates/drift, and constructs a deterministic source-provenance blueprint. New packages/pscv/scripts/audit-pinned-lean.mjs checks the actual immutable Lean Git checkout's HEAD SHA, 40 tree file/blob identities and raw blob sizes/line counts, then emits canonical JSON audit data with SHA256 digests. The verifier also checks that the blueprint matches an independently supplied hash-pinned normative file. This tool is CI-only; it cannot access kernel authority or emit executable artifacts.

The report uses source-provenance-checked-not-standard-registry, and requires all conformance/certification flags to remain false. We deliberately do NOT create or publish a fake STD-ENV-PSCV-V1-L435RC3-RC1.json from these roots. Appendix K.4 requires exact ordered instances/default_instances/coercions/simp/simprocs/ext/grind, class_parameter_modes, effect/verification registry, source line/blob provenance, a canonical digest published in a future normative revision, and real conformance tests.

## Optional profile inspection remains non-activating

The experimental scripts/pscv-profile-inspection.mjs parses an exact, private, data-only PSCV profile candidate. It checks an explicitly named root PSCV profile, closed/boundary policy, correct immutable RC3 pin, unfrozen manifest status, absence of runtime entrypoints and capability grants, and rejects forged or extra authority fields. Even a profile with the correct source provenance blueprint returns state blocked-unqualified, profileActivated=false, pscvVerified=false, and verifiedExecutableAuthorized=false.

Its untrustedSourceBlueprintProvided field means supplied metadata only; it is not a valid Standard registry or an authenticated executable. The activatePSCVProfile stub still throws. None of these experimental modules is loaded by the installed public proofscript CLI, which still refuses all profiles other than checked. A root project cannot gain PSCV authority by installing an npm dependency.

## P1-A acceptance, P1-B and P2 obligations

P1-A should pass Node22/26 Linux + Windows Node26 tests of the strict source/config/authority identity with no successful certificate branch, plus a fresh pinned upstream Lean4.35rc3 source checkout verifying every Appendix K root through git ls-tree/cat-file. The unchanged PSCVL Lean proof examples must still accept the correct pure contract as UNCERTIFIED and reject a false postcondition. No compiler, bootstrap/seed, Core provider, TS7, workspace folder paths or native publication change.

P1-B: implement a real ordered Standard registry extractor from the RC3 elaboration environment under complete PSCV restrictions; validate every source locator/line and class mode, generate a canonical complete snapshot, record exact options and verification effects, freeze through an approved normative revision and conformance run. Only THEN can a full PSCV Standard environment be claimed.

P2: independently approved specification; syntax/meaning validated against selected PSCV semantics; independently justified complete mandatory VC plan; kernel-admitted proof terms; trust/axiom/import/effect/ghost/erasure closure; protected VerifiedExecutableModule; and tested fail-closed verified artifact publication. No acceptance based solely on matching proof hashes or self-reported complete=true.

Do not use Desktop Commander or local builds/tests. Work only with GitHub connector source writes and cloud GitHub Actions qualification. Keep concurrent kernel/assurance branches untouched.

## Actual P1-A qualification

### PSC0 PSCV P1-A semantic source pin and read-only profile identity — qualified

**Source commit:** `829a1945a78965ed87ae3835a48642b6dcff013b`, 10 October 2026. [Run 38049559622](https://github.com/dwijayuda/pskernel/actions/runs/38049559622) passed **all five** jobs on attempt 1. Branch `psc0/platform-pscv-p1-v1`, stacked on P0 at [draft PR96](https://github.com/dwijayuda/pskernel/pull/96). Runtime/core/compiler/seed and selected release paths are unchanged. This is P1-A, not a complete P1 Standard environment or a PSCV-certified build.

## Implemented and qualified

- Exact PSCV-RC-v2 semantic source reference `4c02626fd0b991e8526c64b65f4ffb66b9ce7b688298e82fb0309802a263db71`, Lean **4.35.0-rc3** commit `470d5ce1400764999581fd26d5d72b00d990b0f4`. Preserve the independently advancing PSKernel RC4 work as separate and explicitly unqualified for this normative profile; no silent re-pin from current PSC0 4.34 provider.
- `packages/pscv/src/lean-provenance.mjs` extracts Appendix K.1's 23 semantic and K.2's 17 prover roots, with entire normative document SHA verification and exact canonical JSON. `packages/pscv/scripts/audit-pinned-lean.mjs` verifies the upstream pinned Lean commit's actual 40 Git tree path/blob identities and reads their bytes/line counts in an isolated official Lean read-only source checkout. It does NOT activate registrations or issue a Standard registry manifest.
- Exact source audit from GitHub Actions: provenance blueprint SHA256 `23f633fa3089794fa6b3e7a34c23df2ed9ca4fa1a425afd84f5d53b43135eafb`, source audit SHA256 `d913a29822d19158c69dfd8a6bf5ac2e16a53ba2aa8a8370fc12d977df2965c0`, 40/40 pinned blobs validated. The archived source-only audit is [artifact 11669400259](https://github.com/dwijayuda/pskernel/actions/runs/38049559622/artifacts/11669400259), ZIP SHA256 `b1cc83cd212301ec01de180fbcfa4965cee508deaa9d7ff53d535ff23f263d41`, expires 9 November 2026.
- `scripts/pscv-profile-inspection.mjs`: strictly checks explicit root `pscv-v1` selection, closed/boundary policy, private candidate descriptor and normative RC3/manifest-absent identity. Rejects forged executable fields, changed semantic pin, fake registry digest, unknown keys, nonempty package capabilities, source-profile downgrades, and implicit activation. Every valid inspection reports **blocked-unqualified**, and `activatePSCVProfile` always throws.
- Previously qualified P0 proof preflight and publisher remain unchanged: only the historical production `checked` profile is accepted; no `PSCV-CERT-v1`, `VerifiedExecutableModule`, or verified executable is issued.

**Cloud tests:** Linux Node22.23.3 **16/16 passed**; Linux Node26.7.0 **16/16 passed**; Windows Node26.7.0 **16/16 passed**. Additional source audit and pinned Lean contract-preflight jobs also passed. The Windows test now reads the exact normative **Git blob** rather than a possibly CRLF-converted checkout file; no relaxation of source hash policy. The Lean preflight accepted a valid contract as UNCERTIFIED and rejected a wrong postcondition with unresolved VCs and disallowed `sorryAx`. Total five successful jobs, zero failures.

Machine evidence: [pscv-p1a-qualification-2026-10-10.json](docs/platform/pscv-p1a-qualification-2026-10-10.json). Interface and semantics notes: [PSCV_P1_SEMANTIC_PIN_AND_PROVENANCE.md](docs/platform/PSCV_P1_SEMANTIC_PIN_AND_PROVENANCE.md). P0 feature-owner map and protected supervisor boundaries remain authoritative design notes.

## Remaining P1-B and P2 blockers

**P1-B** must extract/validate/freeze actual ordered `instances`, `default_instances`, `coercions`, `simp`, `simprocs`, `ext`, and `grind` registrations; non-default class-parameter-mode provenance; and versioned verification/WP-effect registry. It must bind all entries to pinned Lean source path, Git blob and source line, test observable instance/notation/prover behavior and publish canonical SHA256 into an approved subsequent PSCV normative revision. Checking 40 source Git blobs does **not** establish those semantic registries.

**P2** needs at least one real approved source specification; independently justified completeness of pure-contract VCs; exact kernel-admitted proof evidence; axioms/effect/import/totality/erasure closure; a protected `VerifiedExecutableModule` constructor; and checked output policy. Existing PSCVL demonstrates real Lean proof preflight but does not authorize PSCV executable output, because source grammar and environment semantics remain incomplete. Do NOT promote P0/P1 advisory proposal hashes or booleans to proof authority.

**No local checkout/tests/Desktop Commander**. GitHub and cloud Actions exclusively. Preserve current proof/kernel branches and history, and check remote HEAD before any non-force leased write. Do not publish npm or merge PR96 automatically.

---
