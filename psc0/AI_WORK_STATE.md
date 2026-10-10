# PSC0 AI work state — CI evidence provenance implementation

## Current task (2026-10-11)

Continue the approved small/secure compiler architecture on `psc0/npm-modular-packages-v1` in `dwijayuda/pskernel`. Starting source: `2d69574231125c4a4738e2cb4ad9fb24d2dc9b51`.

This slice adds **authenticated provenance for the complete two-platform qualification report**, not a compiler feature, kernel change, full P3 plugin framework or production release. Implemented files are CI-only: `scripts/architecture-evidence.mjs`, its15 tests and `.github/workflows/psc0-checked-host.yml`. Contract: [PSC0_CI_EVIDENCE_PROVENANCE.md](docs/PSC0_CI_EVIDENCE_PROVENANCE.md).

The original 85 host tests are retained;15 new completeness/source/runtime/attempt/refusal tests make100. Both current-run platform reports must agree with the actual completed GitHub jobs before the report is signed. Failed/missing/mixed data cannot produce a successful signed aggregate. Only the separate qualification job receives OIDC/attestation-write privileges. The compiler matrix and a fresh verifier remain read-only; no extra npm runtime dependency or shipped compiler/host file is added.

**Validation is pending.** Do not claim the new signature/verification pipeline passed until the actual complete workflow succeeds. Update this file with exact source, run, job and evidence identities after observing those results. A signature authenticates origin, not semantic correctness, and no self-host or kernel assurance claim is promoted by it.

## Unchanged boundaries

Use GitHub and cloud CI exclusively; no local files, checkout/build/test, Desktop Commander, force push, npm publication or main merge. Verify live HEAD and use non-force expected-HEAD writes, preserving concurrent commits. Kernel implementation and `npm-runtime` are owned by a separate branch and remain untouched.

Compiler source stays exactly qualified:69 files/twelve source-owning packages,64-module bootstrap closure, source `1fa5559a72b293defc56ef7e7020cf82d4b44b79`, inventory `fc08090151979be64458352a030a2aaa11bc0df5aab6a3e8cc71b3c4213ad0de`. Language remains `ps-0.9-r3/new-only`, strict entry `psCompilerSh1TypeScriptSources`, selected R seed and TypeScript7.0.2 unchanged. No newer unqualified dialect is substituted.

Runtime reuse remains source `2f42a52814f3785ff2d92bd826f6e7fb3eb9bc8a`, run38075437516, artifact11678641329, archive SHA `3b89239132db2003a3ee0cc01c2c4c9795be4d4ae0097d86a62616fc48fa122a`. Compiler JS SHA `6cddc3c34c38f1524ef9a355c46b0eb17949c45c54fd59367ea370c1af861ab3`; kernel JS SHA `c3912cdbc078d8a56736ef2790221567f2fab8b129a0a26e80b437b79f95ba27`. No runtime regeneration or full C2/C3 is performed. The old runtime's2026-11-09 expiry remains an explicit fail-closed dependency, not permission to substitute a new runtime.

## Prior complete checkpoint

The previous full state is preserved byte-for-byte at [AI_WORK_STATE_LIBRARY_2d6957.md](docs/history/AI_WORK_STATE_LIBRARY_2d6957.md), original blob `d7378a5f1ae12de5eb7fb45c02e1e10b7a180b11`. It records all four completed host/frontend/target/library milestones and their exact receipts. Do not restart or relabel them.

Last fully qualified runtime/host source: `5dcd90cbf62dff278e9cd1294f18e4f1faf98138`, run38087964327,85 tests per platform,23 workspaces, both installed PS/Lean editions. No production implementation changes are intended in this new CI-only slice.

## Continuation

Read actual CI results. Repair a genuine architectural defect without relaxing original tests, report completeness, source pins or verification policy. The report subject is `qualification.json`; retained compiler binaries must not be represented as freshly generated. The attestation goes to GitHub/Sigstore, not npm. Signature absence or verification failure is a failed milestone, never hash-only fallback. Rerun all jobs together when changing attempts.

Full kernel proof, verified target semantics, axiom/effect/specification enforcement, arbitrary guest isolation, package-publisher authentication and a new installed compiler fixed point remain separate. Keep the compiler small: this work adds no production LOC or runtime dependencies.
