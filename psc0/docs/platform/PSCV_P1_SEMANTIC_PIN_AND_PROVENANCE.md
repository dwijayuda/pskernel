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
