# PSC0 CI qualification provenance — bounded P6 slice

## Claim and non-claim

The subject signed by this workflow is **qualification.json**, a newly assembled report about the existing Linux/Windows checks. It is not the reused compiler/kernel executable, a public npm release, a formal proof or a new self-host generation. Its source identity is the current host/workflow commit; its separately named inherited runtime source remains `2f42a52814f3785ff2d92bd826f6e7fb3eb9bc8a`.

GitHub/Sigstore provenance authenticates the report's bytes and originating workflow identity under that infrastructure's trust assumptions. It does not prove that the workflow's assertions are true. Review/pin the workflow source and check the report policy in addition to verifying its signature. This milestone claims no SLSA level, independent compiler implementation, full package authenticity, production release or kernel soundness.

## Three privilege domains, one unchanged compiler

1. **Host matrix:** existing Linux/Node22.23.3 and Windows/Node26.7.0 checks with read-only repository/actions permissions. These jobs have no OIDC or attestation-write grant. Compiler source, kernel adapter, grammar, seed, TS7 pin and the 85 earlier tests remain unchanged. Fifteen CI-evidence tests bring the test contract to100.
2. **Qualification job:** starts only after both host jobs succeed, only in this repository and branch. It downloads data from the exact current run/attempt, reads actual host-job metadata through GitHub's API, rejects incomplete/mixed evidence, builds the report and uses the official pinned `actions/attest` action. Only this job has `id-token: write` and `attestations: write`. It never imports the compiler or executes downloaded artifact code. No repository-content, package-registry or release write permission is granted.
3. **Fresh verifier:** a separate read-only job downloads the report, evidence and signature bundle, validates all report bindings and invokes the official GitHub CLI signature verifier. It has no signing permission. Positive verification is followed by modified-byte, wrong-source and wrong-workflow refusal controls and another positive control. A missing signature or unavailable trust service fails, not downgrades to hash-only success.

All actions in this fast workflow are pinned to exact reviewed Git commits. The existing checkout/setup/download/upload implementations are retained at their previously resolved versions. `persist-credentials: false` avoids leaving checkout authentication available to later test processes. This is CI privilege separation, not a claim to sandbox arbitrary hostile source or protect a compromised GitHub runner.

## Report gate

`psc0/scripts/architecture-evidence.mjs` is the sole CI report schema/assembler/verifier. It is not shipped in the npm CLI. It requires the eleven existing JSON reports plus complete TAP test output for each platform. Every report is bound to the current source, source edition and appropriate platform/runtime; required Boolean success outcomes must be literal `true`. Inherited source, compiler and kernel identities are pinned to the existing qualified evidence; regeneration and new fixed-point fields must stay false.

The TAP plan, case count and summaries must all agree:100 passed, zero failed/cancelled/skipped/todo. Sealing produces an unsigned `platform-envelope.json` tied to exact raw-report hashes, repository, workflow, ref, source, run and attempt. Incomplete jobs can still upload diagnostics, but cannot produce a signed aggregate. The signer checks both completed job conclusions and every recorded step, as well as the complete non-paginated job-list response. Reports are bounded regular files, never executed as modules; unknown files, missing editions, altered bytes and stale envelopes decline.

The aggregate manifest lists each raw report's digest. A consumer must check both the signature on the aggregate and the included report bytes. The verification command reconstructs the aggregate from the raw reports and signed job-metadata snapshot rather than accepting a free-standing `success` flag. `platform-envelope.json` is not itself a signing key or proof credential.

Run attempts are distinct. Rerun the **whole** workflow if needed; mixing a successful previous-attempt platform with a newly rerun platform is refused. The original runtime is still reused and its expiry/failure behavior is unchanged. No expensive C2/C3 or kernel regeneration is added.

## Verification

Obtain the exact implementation SHA and expected run/attempt from a trusted review channel, not just from the downloaded report. After downloading the `psc0-attested-qualification-<SHA>-<ATTEMPT>` artifact, verify the signature with the official CLI:

```sh
gh attestation verify qualification/qualification.json \
  --bundle qualification/attestation.jsonl \
  --repo dwijayuda/pskernel \
  --signer-workflow dwijayuda/pskernel/.github/workflows/psc0-checked-host.yml \
  --source-digest "$EXPECTED_SHA" --signer-digest "$EXPECTED_SHA" \
  --source-ref refs/heads/psc0/npm-modular-packages-v1 \
  --deny-self-hosted-runners --format json
```

Then use the reviewed `architecture-evidence.mjs verify qualification` with externally expected `GITHUB_REPOSITORY`, `GITHUB_REF`, `GITHUB_WORKFLOW_REF`, `GITHUB_SHA`, `GITHUB_RUN_ID` and `GITHUB_RUN_ATTEMPT`. Do not populate expectations by trusting arbitrary JSON in the subject. In CI these values come from the invoking workflow context. Trust roots may need online retrieval; including a signature bundle alone is not a promise of fully air-gapped verification.

## Operational boundaries

This writes a public GitHub attestation and Sigstore transparency entry for the qualification report. It does not publish an npm package, release asset, compiler ZIP or production binary. Existing CI evidence artifacts retain their30-day expiry. The old compiler-generation artifact is not retrospectively attested as if generated at today's source. Authentication cannot manufacture a source-to-binary theorem or a new C2/C3 result.

The signing job is isolated from compiler tests but runs repository-controlled verifier code. A malicious approved workflow/commit could still sign false assertions. Consumers must review the source pin; repository governance, GitHub identity service, Sigstore trust roots, hosted runners and the verifier itself are residual trust. The fresh verifier is a separate execution context, not an independent organization or formal audit.

References checked at implementation: [GitHub artifact-attestation guidance](https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations/use-artifact-attestations), [official CLI policy flags and trust explanation](https://cli.github.com/manual/gh_attestation_verify), [pinned official attestation action](https://github.com/actions/attest/blob/1e69f48acb82d1966a394da916b4c1698aa569d6/action.yml). Actual completion evidence belongs in AI_WORK_STATE.md and the qualification ledger, not in this design description.
