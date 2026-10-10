# PSC0 AI work state — bounded frontend continuation

## Active scope (2026-10-11)

Repository: `dwijayuda/pskernel`; branch: `psc0/npm-modular-packages-v1`.
Starting HEAD: `81abfd94102a3628842d07de019f60e92e7b9ea4`.

The user authorized continuing the efficient architecture work, preserving the existing compiler self-host and latest **qualified** language. Kernel source, runtime adapter and metatheory remain owned by another branch and MUST NOT change here. Work exclusively through GitHub/cloud CI; no local checkout/build/test, Desktop Commander, force push, automatic npm publication, full C2/C3 loop or kernel regeneration.

Current slice: **owned frontend process/resource boundary**, completing the missing bounded parser/elaborator execution part of PSC0-ARCH/1. This is not an arbitrary-plugin framework, new language, new backend, kernel change or package reorganization.

## Prior qualified checkpoint — do not restart

The P0/P1/P2 checked-host milestone at `2c48a6cca20f081c9d1785d56d3c67d637651a78` passed fast workflow `38082117579` on Linux/Node22.23.3 and Windows/Node26.7.0. Both passed all30 host tests, 23-workspace checks, source identity, retained runtime installation, full64-module installed compiler closure scans and both PS/Lean checked library builds. [Prior work state](docs/history/AI_WORK_STATE_CHECKED_HOST_81abfd.md) is preserved byte-for-byte (blob `938de922e86b7e2d9db891bb90985822118ae132`). [Original qualification](docs/PSC0_CHECKED_HOST_QUALIFICATION.json) retains its exact source/run scope.

## Invariants that remain frozen

- Compiler language: bounded `ps-0.9-r3`, new-only. Strict-SH/1 entry `psCompilerSh1TypeScriptSources` remains explicitly selected only by its qualified lane.
- Source evidence: qualified source `1fa5559a72b293defc56ef7e7020cf82d4b44b79`; inherited **69 compiler source files**, **64 bootstrap-closure modules**, source inventory SHA-256 `fc08090151979be64458352a030a2aaa11bc0df5aab6a3e8cc71b3c4213ad0de`.
- Selected R seed, TypeScript7.0.2, bootstrap Node22.23.3 and Lean4.34.0 do not change. Do not adopt an unqualified newer language-design document as compiler behavior.
- Runtime reuse: run `38075437516`, source `2f42a52814f3785ff2d92bd826f6e7fb3eb9bc8a`, artifact `11678641329`, SHA-256 `3b89239132db2003a3ee0cc01c2c4c9795be4d4ae0097d86a62616fc48fa122a`. Compiler/kernel bytes remain exact; artifact expires 2026-11-09.
- `architecture-source-identity.mjs` MUST continue to pass unchanged. Never move its baseline merely to permit a semantic change.
- Existing JS PSKernel Core remains npm's selected checker, without Lean-WASM fallback or any new formal-soundness claim.

## New canonical owners

| File | Responsibility |
| --- | --- |
| `npm-cli/frontend-wire.mjs` | Byte-bounded strict-UTF8 JSON frames before decoding |
| `npm-cli/frontend-transport.mjs` | One private owned child, monotonic accumulated request deadline, bounded diagnostics, ordered identity and termination |
| `npm-cli/frontend-worker.mjs` | Loads the pinned existing compiler; parses/elaborates/retains shared checked session; no output paths or process-spawn API |
| `npm-cli/frontend-session.mjs` | Parent-local handles, accepted admission digest binding, parent-selected kernel callback; no transferable JSON authority |
| `npm-cli/source-graph.mjs` | Existing parent snapshot/graph owner; only import parsing delegates asynchronously to the worker |
| `npm-cli/build.mjs` | Parent keeps kernel selection, TypeScript, snapshots, staging and sole publication path; child must be closed before publication |
| `npm-cli/psc.js` | Thin CLI with explicit host-owned finite resource overrides |

Default limits: 300000ms accumulated active request wall time, including kernel handshake; 4096MiB V8 old space, **not total RSS**; 64MiB maximum encoded frame; 64KiB stderr; 4096 requests. Explicit `--frontend-timeout-ms` and `--frontend-heap-mb` permit intentional larger developer workloads within finite validation bounds; they never bypass logical admission. Imported libraries cannot change them.

The child holds actual prepared terms and the existing `createCheckedPreparedSession` handle. Only strings/plain protocol data cross the private pipes; parent invokes its unchanged selected kernel. A copied JSON value cannot authorize emit. Timeout, malformed protocol, unexpected result, cancellation or worker exit invalidates the session with no restart/fallback. Parent reaps child before its immutable-generation publication.

An owned Node process is **not a malicious-extension sandbox**. This slice bounds CPU-heavy compiler JS and separates its heap; it does not impose OS capabilities or bound native allocation/total RSS. Parent IO and existing kernel/tsc stages keep their separate limits. Arbitrary executable plugin loading remains absent.

## Cost-controlled validation

Use the existing fast workflow `.github/workflows/psc0-checked-host.yml`.

1. Unchanged Git source/pin/kernel guard and workspace schema checks.
2. Existing30 host tests plus `architecture-frontend.test.mjs` exercising real owned process timeout, cancellation, exit, malformed/oversized/stale/duplicate replies, kernel ordering, strict framing and limit validation.
3. Repack the same retained runtime, ordinary offline npm installation, prior installed PS/Lean checks and whole compiler-closure scan.
4. `architecture-frontend-installed.mjs`: actual child/direct retained compiler admissions and emitted TS equality on a small case, actual selected kernel acceptance, copied/closed handle refusal, explicit resource settings and timeout preserving a previously committed executable. These are bounded correspondence cases, not C2/C3.

No changes are made to test expectations to conceal a failure. Diagnose shared contracts or general causes; retain initial failures and exact corrected runs. Full release generation remains explicit-only and is not invoked.

## Current status

Implementation and targeted tests are staged for the coherent first checkpoint. **No new CI success is claimed yet.** Read actual branch HEAD and workflow results before any next write, then update this file with exact source/run IDs and any failure/limit. Preserve concurrent commits via expected-HEAD non-force updates.

## Deferred work / no drift

No kernel modification, new compiler dialect, full self-host regeneration, verified-backend theorem, full axiom/effect/specification policy, arbitrary third-party executable extension sandbox, authenticated registry publication, or broader platform rewrite is authorized by this slice. Source libraries remain declarative data. The previous `.psc-artifacts` output contract and single public commit point remain unchanged.

Architecture detail: [Frontend resource boundary](docs/PSC0_FRONTEND_RESOURCE_BOUNDARY.md). Existing [checked-host implementation](docs/PSC0_CHECKED_HOST_IMPLEMENTATION.md) and [architecture target](docs/PSC0_SOUNDNESS_SECURE_EXTENSIBLE_ARCHITECTURE.md) retain their distinct scopes.
