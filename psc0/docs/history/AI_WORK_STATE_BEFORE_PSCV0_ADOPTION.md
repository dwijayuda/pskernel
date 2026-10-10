# PSC0 AI work state — CI evidence provenance qualified

## Read first: completed milestone (2026-10-11)

The bounded P6 slice **authenticated provenance for the complete CI qualification report** is implemented and cloud-qualified on `psc0/npm-modular-packages-v1`, repository `dwijayuda/pskernel`.

**Qualified implementation:** `af6b7727163f57bcf78bbde28d96a878fd82d0f8`.
**Successful first implementation run:** [38089350504](https://github.com/dwijayuda/pskernel/actions/runs/38089350504), attempt1; all four jobs succeeded. Started2026-10-10T21:53:35Z; completed status at21:58:51Z (5m16s).

| Job | ID | Result |
| --- | --- | --- |
| Linux / Node22.23.3 | `114322397344` | success,100/100 tests and both installed editions |
| Windows / Node26.7.0 | `114322397205` | success,100/100 tests and both installed editions |
| Sign complete qualification report | `114323224056` | success, GitHub/Sigstore attestation created |
| Fresh read-only verification | `114323277788` | success, signature and raw evidence verified; three refusal controls passed |

The signed subject is **qualification.json**, SHA-256 `ca5c8cb4194f117c0fb94f4dd81576a81dcfc94ca90deef6a9305764281c26fa`. [GitHub attestation54684871](https://github.com/dwijayuda/pskernel/attestations/54684871) was generated using the Public Good Sigstore instance and recorded at Rekor index3194241897. It authenticates the report's bytes and workflow origin—not the truth of every assertion, a new compiler binary, semantic preservation or kernel soundness.

The first coherent implementation passed without changing a test expectation, semantic baseline, compiler, kernel or shipped host. Documentation-only descendants must retain this exact implementation/source/run distinction rather than claiming a fresh execution.

Contract: [PSC0_CI_EVIDENCE_PROVENANCE.md](docs/PSC0_CI_EVIDENCE_PROVENANCE.md).
Machine ledger: [PSC0_CI_EVIDENCE_QUALIFICATION.json](docs/PSC0_CI_EVIDENCE_QUALIFICATION.json).

## Authority and scope

Starting HEAD was `2d69574231125c4a4738e2cb4ad9fb24d2dc9b51`. User authorized continued systematic, efficient architecture implementation while preserving the compiler self-host and latest **qualified** language. Kernel development and its adapter are owned elsewhere.

Use GitHub for repository reads/writes and cloud CI for execution. No local files/checkouts/builds/tests, Desktop Commander, force pushes, automatic npm publication or unrequested main merge. Inspect live HEAD before writes; use expected-HEAD non-force updates and preserve concurrent work. No package/backend/plugin-platform expansion is implied by this milestone.

This slice changes only CI scripts, the fast workflow and documentation. **Zero production/shipped LOC, zero npm dependencies, zero portable compiler/kernel lines changed.** The 13 required packages and all installed CLI behavior remain as qualified in the preceding milestone. No runtime regeneration, source-language migration or full C2/C3 was performed.

## Prior checkpoints — do not restart

| Milestone | Implementation | Successful run | Tests/platform |
| --- | --- | --- | ---: |
| P0/P1/P2 checked host | `2c48a6cca20f081c9d1785d56d3c67d637651a78` | `38082117579` | 30 |
| Frontend process/resource boundary | `29c2d611a39d7c3187b1b8d333e5d023090bba9f` | `38083824580` | 50 |
| Native target-toolchain identity | `494a0a715ebd1e29eba2d146903bb6a3a722be06` | `38086137673` | 66 |
| Source-library identity/disclosure | `5dcd90cbf62dff278e9cd1294f18e4f1faf98138` | `38087964327` | 85 |
| CI report provenance | `af6b7727163f57bcf78bbde28d96a878fd82d0f8` | `38089350504` | 100 |

The previous complete state is preserved byte-for-byte at [AI_WORK_STATE_LIBRARY_2d6957.md](docs/history/AI_WORK_STATE_LIBRARY_2d6957.md), original Git blob `d7378a5f1ae12de5eb7fb45c02e1e10b7a180b11`. Follow its historical links for prior owner maps, target/frontend/source-library contracts and original qualification failures. Nothing in the current provenance reclassifies earlier failed runs as success.

## Exact inherited compiler and runtime identities

- Qualified compiler source: `1fa5559a72b293defc56ef7e7020cf82d4b44b79`; historical completion run38027413274, scoped by `docs/selfhost-language/CURRENT.md`.
- **69 files** in12 source-owning compiler packages remain unchanged; **64 bootstrap modules** were scanned/parsed from each installed source edition.
- Compiler source inventory SHA-256: `fc08090151979be64458352a030a2aaa11bc0df5aab6a3e8cc71b3c4213ad0de`.
- Qualified language: bounded `ps-0.9-r3/new-only`; strict entry `psCompilerSh1TypeScriptSources`. Generic APIs do not silently select strict SH/1. Selected R seed, TypeScript7.0.2, bootstrap Node22.23.3 and Lean4.34.0 remain unchanged.
- Retained npm runtime source: `2f42a52814f3785ff2d92bd826f6e7fb3eb9bc8a`; run38075437516; artifact11678641329; archive SHA `3b89239132db2003a3ee0cc01c2c4c9795be4d4ae0097d86a62616fc48fa122a`.
- Compiler JS SHA: `6cddc3c34c38f1524ef9a355c46b0eb17949c45c54fd59367ea370c1af861ab3`.
- Kernel JS SHA: `c3912cdbc078d8a56736ef2790221567f2fab8b129a0a26e80b437b79f95ba27`.

Compiler source, installed host source, kernel implementation and `npm-runtime` adapter were unchanged in this slice. The original preservation guard, baseline and all85 prior tests were retained; fifteen CI-evidence tests were added. No new installed compiler fixed point is claimed. Never change a baseline just to make a guard pass; genuine semantic-source changes need deliberately scoped compiler-only requalification.

The retained runtime expires2026-11-09. Its authentication/history is not retroactively rewritten: the new attestation signs a report about reuse, not an assertion that the old executable was generated at the new commit. Missing/expired runtime evidence must fail rather than trigger substitution or unrequested regeneration. Public ZIP generation and the full release workflow remain explicit-only and were not invoked.

## Canonical evidence ownership and privilege separation

`psc0/scripts/architecture-evidence.mjs` is the single CI-only report assembler/validator; it is not imported by `psc` or installed in the runtime. It requires eleven existing JSON reports and full TAP output per platform. Every required source/runtime/edition/platform identity and Boolean result is checked, including non-regeneration and non-fixed-point fields. It validates raw byte hashes, bounded regular files, the exact report set and complete100-test summaries with zero failure/cancellation/skip/todo.

A platform envelope binds those raw files to repository, workflow, ref, source SHA, run and attempt. The signing job reconstructs both envelopes and cross-checks actual completed GitHub job metadata. Incomplete, duplicate, skipped, stale or mixed-attempt evidence cannot produce a successfully assembled report. Diagnostic uploads after failures remain unsigned; a platform envelope by itself is neither a signature nor proof authority.

The host matrix has only repository/actions read permissions. The separate qualification job alone receives `id-token: write` and `attestations: write`; it never imports the compiler or executes downloaded artifact code. It signs only `qualification.json`. A fresh verifier runs without signing privileges. No content-write, package-registry or release grant is added. All Actions implementations are pinned to exact commits; checkout credentials are not persisted into later steps.

The official `actions/attest@1e69f48acb82d1966a394da916b4c1698aa569d6` action generates build provenance for the **report**. The existing checkout/setup/download/upload action implementations remain pinned to their previously resolved versions. No custom cryptographic implementation or npm Sigstore runtime dependency was introduced.

The read-only verifier checks the report/evidence bindings and uses `gh attestation verify` with the exact repository, workflow, source-ref and source/signer commit, denying self-hosted runners. It passed genuine positive verification, modified-subject refusal, wrong-source refusal, wrong-signer-workflow refusal, then a second positive and complete report check. Signature verification failure is not downgraded to hash-only success.

## Final evidence artifacts

All belong to run38089350504, attempt1, implementation `af6b7727163f57bcf78bbde28d96a878fd82d0f8`:

| Artifact | ID | ZIP SHA-256 |
| --- | --- | --- |
| Linux,13 evidence files | `11683393152` | `a8efe5fec7c8e6e6cd721b2ef005cb42ff4f7fb7770562275e3cc0143af4412d` |
| Windows,13 evidence files | `11682967263` | `46b92648106d0557382fe17518cecfc4d6d8147691fbece036c1d851ff28dcda` |
| Attested qualification,29 files | `11684056972` | `181462c7b41db04e58a538294e3bf6a477b8ee609ecdccf4e037001972cb2707` |
| Fresh verification,10 files | `11683538181` | `c28514572e23d1f5b218412aa7eb2b1578044bfaee63d6a2a23c1c4d4334454a` |

The29-file signed bundle contains the13-file evidence set from each platform, normalized jobs.json, qualification.json and the portable attestation.jsonl. Verify the signature on qualification.json and then reconstruct the raw-file bindings; the ZIP digest alone is not authenticity. The fresh verifier's artifact retains its CLI version, successful verification JSON, negative-control outputs, final positive JSON and result text. Artifact retention remains30 days.

CI size delta:134 new evidence-tool lines,103 test lines,116 net workflow lines; documentation excluded. Production compiler/kernel/host additions:0. New runtime dependencies:0. First-run full success; no implementation correction or test-fix iteration was required.

## Continuation and remaining obligations

Use the fast `.github/workflows/psc0-checked-host.yml`; it retains source identity,23-workspace validation,100 tests and the unchanged installed PS/Lean checks. After those pass, CI authenticates only the aggregate qualification report. Rerun the **whole** workflow when a new attempt is necessary: do not combine evidence from different attempts.

The external verifier's expected source/ref/run/attempt must come from a reviewed source, not be accepted blindly from downloaded JSON. The provenance guide gives the actual command. Bundled signatures do not guarantee air-gapped verification; trust-root retrieval may require network access. The fresh verifier is a separate execution context, not an independent organization, formal audit or second compiler implementation.

This closes a bounded report-origin gap, not all P6 or full compiler verification. Approved workflow code, repository governance, GitHub OIDC, Sigstore roots/transparency service, hosted runners and the verification tool remain trusted. A malicious approved workflow could sign false assertions. No SLSA level, package-publisher authentication, formal soundness, semantic-preservation theorem or new C2/C3 result is implied.

Do not restart completed milestones or enlarge a general plugin platform automatically. For the next user-authorized continuation, choose one remaining architecture obligation with a small canonical owner. Kernel proofs/self-hosting remain elsewhere; executable guest isolation, complete effect/specification/axiom policies, independent backend implementation, authenticated executable release and a fresh installed compiler fixed point remain separate work. No new public compiler ZIP, npm publication or main merge occurred here. A public GitHub attestation and Sigstore transparency entry were created for the CI report only.
