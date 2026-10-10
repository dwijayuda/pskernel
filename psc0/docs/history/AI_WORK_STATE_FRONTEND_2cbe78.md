# PSC0 AI work state — frontend resource boundary qualified

## Read first: current completed milestone (2026-10-11)

The **owned frontend process/resource boundary** is implemented and cloud-qualified.

- Branch: `psc0/npm-modular-packages-v1` in `dwijayuda/pskernel`.
- Qualified implementation: `29c2d611a39d7c3187b1b8d333e5d023090bba9f`.
- Successful fast workflow: [38083824580](https://github.com/dwijayuda/pskernel/actions/runs/38083824580).
- Linux/Node22.23.3 job: `114306040560`, success.
- Windows/Node26.7.0 job: `114306040393`, success.
- **50/50 host tests on each platform**, unchanged source-preservation guard, **23 workspaces**, offline npm installation and both PS/Lean installed checks passed.
- The actual worker produced canonical admissions and TypeScript **identical to direct execution of the same retained compiler** on the bounded correspondence fixture. Actual JS-kernel admission passed; copied/closed handles and installed CLI timeouts were refused. The timeout preserved the previously committed executable.

This implementation passed its first coherent CI run; no test-fix loop, compiler rebuild, kernel regeneration or full C2/C3 cycle was used. These are **bounded host/correspondence results and inherited compiler-source qualification**, not a new installed self-host fixed point or formal semantic-preservation proof. Documentation-only descendants retain this precise implementation identity.

Machine evidence: [PSC0_FRONTEND_RESOURCE_QUALIFICATION.json](docs/PSC0_FRONTEND_RESOURCE_QUALIFICATION.json).
Design and limits: [PSC0_FRONTEND_RESOURCE_BOUNDARY.md](docs/PSC0_FRONTEND_RESOURCE_BOUNDARY.md).

## Authority and scope

The user authorized continuing efficient PSC0 architecture work while preserving compiler self-hosting and the latest **qualified** language. Kernel source, runtime adapter and metatheory are developed on another branch and MUST NOT change here. Use GitHub/cloud CI only: no local checkout/build/test, Desktop Commander, force push or automatic npm publication. Read live HEAD before writes; preserve concurrent history with an expected-HEAD non-force lease. Main was not changed.

This slice completed the missing bounded parser/elaborator execution obligation after P0/P1/P2. It does not introduce arbitrary executable plugins, a new language, a new backend, a new kernel or additional default npm packages.

## Prior qualified milestone — do not restart

The earlier P0/P1/P2 checked-host source `2c48a6cca20f081c9d1785d56d3c67d637651a78` passed fast run `38082117579` on Linux/Node22 and Windows/Node26, with all30 then-existing host tests. Its documentation checkpoint was `81abfd94102a3628842d07de019f60e92e7b9ea4`, the starting HEAD of this slice.

The [prior work state](docs/history/AI_WORK_STATE_CHECKED_HOST_81abfd.md) is preserved byte-for-byte, blob `938de922e86b7e2d9db891bb90985822118ae132`. [Original checked-host qualification](docs/PSC0_CHECKED_HOST_QUALIFICATION.json) and [validation ledger](docs/PSC0_CHECKED_HOST_VALIDATION.md) retain their original source/run scopes and historical failures. They are not rewritten as evidence of this newer source.

## Self-host and kernel identities preserved

| Item | Exact inherited identity |
| --- | --- |
| Language | bounded `ps-0.9-r3`, new-only |
| Qualified strict entry | `psCompilerSh1TypeScriptSources`; generic APIs do not silently select it |
| Qualified compiler source | `1fa5559a72b293defc56ef7e7020cf82d4b44b79` |
| Historical qualification completion | run `38027413274`, as defined by `docs/selfhost-language/CURRENT.md` |
| Entire compiler source | **69 unchanged files** across twelve source-ownership packages |
| Bootstrap import closure | **64 modules**, no kernel/optional-backend dependency |
| Source inventory SHA-256 | `fc08090151979be64458352a030a2aaa11bc0df5aab6a3e8cc71b3c4213ad0de` |
| Toolchain | selected R seed; TypeScript7.0.2; bootstrap Node22.23.3; Lean4.34.0 |
| Retained runtime source | `2f42a52814f3785ff2d92bd826f6e7fb3eb9bc8a` |
| Retained runtime run/artifact | `38075437516` / `11678641329` |
| Retained archive SHA-256 | `3b89239132db2003a3ee0cc01c2c4c9795be4d4ae0097d86a62616fc48fa122a` |
| Compiler JavaScript SHA-256 | `6cddc3c34c38f1524ef9a355c46b0eb17949c45c54fd59367ea370c1af861ab3` |
| Kernel JavaScript SHA-256 | `c3912cdbc078d8a56736ef2790221567f2fab8b129a0a26e80b437b79f95ba27` |

The unchanged `architecture-source-identity.mjs` guard verified these source/pin boundaries on both platforms. Repacking retained exact compiler/kernel bytes. The entire kernel source and `npm-runtime` adapter tree remained unchanged. No portable `.lean`/`.ps` compiler function was rewritten in host JavaScript.

**Never change a baseline simply to make the guard pass.** A real compiler/grammar/seed/target change needs deliberate compiler-only qualification. Normal host work reuses exact evidence. Kernel self-hosting and proof work are outside the user's present compiler-only scope.

The retained runtime artifact expires **2026-11-09**. Renew or archive it through a reviewed authenticated operation before expiry when needed; missing evidence must not silently trigger substitution, regeneration or unchecked release.

## Current ownership and data flow

`psc.js` -> `build.mjs` -> parent-owned source snapshot / `frontend-session.mjs` -> disposable owned worker -> parent-selected existing JS kernel -> worker's original checked session -> target-source string -> parent TypeScript staging -> worker closed/reaped -> parent snapshot revalidation -> single publication switch.

| Owner | Role |
| --- | --- |
| `frontend-wire.mjs` | Bounded strict-UTF8 byte framing before JSON parsing |
| `frontend-transport.mjs` | Owned child lifetime, monotonic aggregate request deadline, bounded diagnostics and ordered response identity |
| `frontend-worker.mjs` | Load exact installed compiler; parse/elaborate/retain the shared checked graph; no output destination or child-spawn operation |
| `frontend-session.mjs` | Parent-local handle ownership and accepted-admission digest binding; parent-owned kernel callback |
| `checked-session.mjs` | Unchanged provider-neutral freeze/re-encode/checked-session implementation reused inside the worker |
| `source-graph.mjs` | Existing parent source/metadata snapshot; delegates only parser work asynchronously |
| `build.mjs` | Parent retains kernel selection, TypeScript, output staging, snapshot revalidation and publication |
| `publication.mjs` | Unchanged immutable-generation single public commit point |

Actual prepared terms and their generated Symbol tags never cross process serialization. Plain JSON facts are not proof authority; only an active host-local handle bound to that owned connection authorizes emission. Invalid, stale, duplicate, oversized, premature or unchecked responses permanently invalidate the session. There is no restart, Lean-WASM fallback or unbounded in-process execution fallback.

Default frontend budget: **300000ms accumulated request wall time**, including the kernel handshake, and **4096MiB V8 old space**. Explicit CLI `--frontend-timeout-ms` and `--frontend-heap-mb` overrides allow finite larger developer workloads without changing acceptance rules. Library metadata cannot raise them. Maximum encoded frame:64MiB; diagnostics:64KiB; requests:4096.

**Limit statement:** this is an owned-process resource boundary, not a hostile-plugin OS sandbox. Old-space limits do not bound all RSS/native allocation. The budget covers active frontend requests, not all filesystem/TypeScript/publication wall time. Kernel and TypeScript keep their separate existing subprocess limits. Abrupt OS/parent termination, supply-chain compromise, source-graph IO hard timeouts and full process-tree sandboxing remain separate concerns.

The existing output contract is unchanged: an entry `.js`/`.ts` module points to an immutable `.psc-artifacts/` generation containing canonical TS, JS, declarations, map and receipt. Deploy that directory with the entry point. No executable is switched until the owned worker is closed and source revalidation succeeds. Receipts are audit data, not transferable proof credentials.

## Evidence and cost

Fast run `38083824580` qualified the first implementation commit `29c2d611a39d7c3187b1b8d333e5d023090bba9f`:

| Platform | Job | Tests | Source editions | Evidence artifact / SHA-256 |
| --- | --- | ---: | --- | --- |
| Linux/Node22.23.3 | `114306040560` | 50/50 | PS + Lean | `11680739771` / `30f19c41700f8f127050bd451fffe7d8cffeb19332bf3ed9e2928573d99a26fa` |
| Windows/Node26.7.0 | `114306040393` | 50/50 | PS + Lean | `11681273714` / `654c0ae7d0bece80805f61bef5af762961cb9f3497cdd4ec88a96be4fc8947b9` |

Each artifact contains seven evidence files: source preservation, two exact runtime repacks, two prior installed-source/closure checks, and two new frontend resource/correspondence checks. Both variants retained the full64-module installed compiler closure, compiled a source library application to `42n`, and passed direct/worker admissions and TS equality. Invalid source, forged/closed handles, unknown unchecked flags and explicit timeout refused without replacing prior output.

The host-only production delta is **275 net physical lines** relative to the starting source (254 lines in four new modules plus21 integration lines); tests add198 lines. This is not a semantic complexity metric. No compiler/kernel source LOC changed and no extra npm runtime dependency was added. Full generation, source retranslation and C2/C3 were not performed.

## Cheap validation / no drift

Use `.github/workflows/psc0-checked-host.yml`, which now runs:

```sh
node scripts/architecture-source-identity.mjs
node scripts/check-workspace.mjs
node --test scripts/checked-prepared-session.test.mjs scripts/architecture-host.test.mjs scripts/architecture-frontend.test.mjs
```

It then reuses the pinned runtime, repacks the current host, installs offline and runs `architecture-installed-smoke.mjs` plus `architecture-frontend-installed.mjs` for both editions on each OS. The full npm distribution generation workflow remains explicit-only and was **not** invoked. No npm publication, downloadable replacement ZIP release or merge to main is implied by these private qualification candidates.

Next authorized work should select one remaining PSC0-ARCH/1 obligation with a canonical owner. Do not restart this completed milestone, broaden it into a general plugin platform, weaken negative tests, update source baselines casually, touch kernel work, or run expensive self-host cycles merely because host files changed. Arbitrary guest sandboxing, effects/specification/axiom policies, backend-preservation proofs, authenticated public release, independently compiled scoped packages and a new installed C2/C3 proof remain separate milestones.
