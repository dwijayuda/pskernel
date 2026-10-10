# PSC0 AI work state — checked-host milestone qualified

## Read first: current result (2026-10-11)

The bounded P0/P1/P2 **host-integration milestone is implemented and cloud-qualified** on `psc0/npm-modular-packages-v1`.

**Qualified implementation source:** `2c48a6cca20f081c9d1785d56d3c67d637651a78`.
**Successful fast workflow:** [38082117579](https://github.com/dwijayuda/pskernel/actions/runs/38082117579).
**Linux job:** `114301005999` (Node 22.23.3), success.
**Windows job:** `114301006107` (Node 26.7.0), success.

Both platforms passed all **30 host tests**, the **23-workspace** schema check, exact compiler/kernel source preservation, retained-runtime artifact verification, ordinary offline npm repacking/installation, and both `.ps` and `.lean` installed-host checks. The **64-module installed compiler bootstrap closure** was loaded/parsed in both source editions; a source-library application was checked, compiled and executed to `42n`; invalid input retained the previous executable. No compiler/kernel runtime generation or full C2/C3 cycle was run.

This is **preservation of the existing source-specific compiler qualification plus installed-host behavior**, not a newly measured installed C2/C3 fixed point, kernel self-hosting, full PSCV, or a formal soundness theorem. Documentation-only descendants do not claim their own runtime regeneration.

## Authority and scope

Repository: `dwijayuda/pskernel`. Work branch: `psc0/npm-modular-packages-v1`.
Starting source before this milestone: `58234f52f15f961f599799e2e93ec1f1f0f86962`.
Architecture: [PSC0-ARCH/1](docs/PSC0_SOUNDNESS_SECURE_EXTENSIBLE_ARCHITECTURE.md).
Implementation: [checked-host design and output contract](docs/PSC0_CHECKED_HOST_IMPLEMENTATION.md).
Evidence: [validation ledger](docs/PSC0_CHECKED_HOST_VALIDATION.md), [machine-readable checkpoint](docs/PSC0_CHECKED_HOST_QUALIFICATION.json).

The user asked for systematic, efficient work that preserves compiler self-hosting, uses the latest **qualified** self-host language and avoids expensive repeated self-host tests. Kernel implementation/metatheory are being developed separately; **do not change that branch, its source, its algorithms or its runtime adapter here**. Do not add a new language dialect, backends, arbitrary executable plugins or an expanded platform as part of this milestone.

All repository reads/writes use GitHub and all execution uses cloud CI. No local checkout/build/test, Desktop Commander, force push or automatic npm publication. Read live HEAD before writing and preserve concurrent history with an expected-HEAD non-force lease. Main was not changed by this work.

## Compiler self-host boundary and exact identities

- Language remains bounded `ps-0.9-r3`, new-only. Qualified strict PSC0-SH/1 entry is `psCompilerSh1TypeScriptSources`; generic APIs do not silently select strict SH/1.
- Preserve selected R seed, TypeScript **7.0.2**, bootstrap Node **22.23.3** and Lean **4.34.0**. Newer language-design documents are not an already qualified compiler dialect.
- Qualified compiler source: `1fa5559a72b293defc56ef7e7020cf82d4b44b79`; completed historical evidence run `38027413274`, following its recorded C1/C2/C3 runs. [CURRENT.md](docs/selfhost-language/CURRENT.md) defines that scope.
- Fast Git-object guard verified **69 source files** across all twelve compiler source packages are identical to that qualified source and to the retained npm runtime source. The actual bootstrap import closure is **64 modules**, with no kernel or optional-backend dependency.
- Compiler source inventory SHA-256: `fc08090151979be64458352a030a2aaa11bc0df5aab6a3e8cc71b3c4213ad0de`.
- Seed/grammar/toolchain inputs and the entire `packages/pskernel-core` plus `npm-runtime` directories remained identical to the pre-change baseline.
- Runtime reuse: successful npm run **38075437516**, source `2f42a52814f3785ff2d92bd826f6e7fb3eb9bc8a`, artifact **11678641329** (`proofscript-psc0-npm-ps-and-lean`). Downloaded artifact SHA-256: `3b89239132db2003a3ee0cc01c2c4c9795be4d4ae0097d86a62616fc48fa122a`.
- Repacking verifies original tarball digests and exact compiler/kernel JS byte identities before/after replacing host files. No hidden regenerated or substituted runtime is accepted.

**Do not update a baseline merely to make this guard green.** If portable source, grammar, seed, target toolchain or kernel changes, diagnose the changed semantic scope and intentionally qualify that change. Host-only modifications may reuse unchanged evidence. A new full fixed point, if genuinely required, is an explicit compiler-only milestone, not a routine host-edit loop.

## Implemented canonical owners

| Owner | Responsibility |
| --- | --- |
| `npm-cli/checked-session.mjs` | Shared provider-neutral frozen prepared graph, private session handles, exact admissions re-encoding, explicit provider identity, revocation |
| `scripts/checked-prepared-session.mjs` | Thin compatibility composition for historical checked hosts; no duplicated session implementation |
| `npm-cli/snapshot.mjs` | Bounded strict-UTF-8 capture, content digests, missing-input records, filesystem identity, immutable snapshot and revalidation |
| `npm-cli/libraries.mjs` | Recorded declarative npm source resolution; reserved namespace and package metadata validation; no third-party JS execution |
| `npm-cli/source-graph.mjs` | Bounded homogeneous source/import graph; qualified compiler owns parsing and elaboration |
| `npm-cli/build.mjs` | One installed `check`/`build` implementation through the shared session, exact snapshot binding and existing JS kernel |
| `npm-cli/publication.mjs` | Protected input/output identity, exclusive writer lock, immutable generation and one executable entry-point switch |
| `npm-cli/psc.js` | Thin CLI, explicit command/flag parsing; no separate prepare/check/emit implementation |
| `scripts/check-workspace.mjs` | Distinct authoring/staged/published schemas with actual source-root validation; exact minimal 13-package core |
| `scripts/npm-host-packaging.mjs` | Common host staging and truthful `.mjs` facade entrypoints for full release and fast repack |

No portable compiler logic was moved into handwritten JavaScript. These new `.mjs` files implement Node filesystem/process and publication orchestration outside the compiler self-host closure. Most scoped runtime packages still share the existing compiler runtime; independent per-package compilation is not claimed.

Historical checked-build entrypoints retain explicit historical provider selection; this milestone shares checked-session authority without pretending old and new kernel providers are identical. JS PSKernel Core remains the requested **npm CLI default**, with no automatic Lean-WASM fallback and no new kernel-trust promotion.

## Output contract

A successful `psc build Main.ps --out Main.js` produces an ES-module entry point referring to a complete generation under `.psc-artifacts/`. The generation holds canonical `.ts`, `.js`, `.d.ts`, `.js.map` and `receipt.json` files. The JSON build result gives the exact artifact directory and hashes. A requested `.ts` entry is likewise a module re-export; canonical generated TypeScript remains in the generation.

**Deploy/copy `.psc-artifacts/` together with the entry point.** This replaces the old multi-sibling-file layout; do not call a set of separate renames atomic. A failed new build leaves the previously committed executable intact. Old generations are retained; automatic garbage collection is deferred. Cleanup warnings cannot convert a committed build into a reported failure. The OS and installation owner remain trusted; no power-loss durability or hostile-OS guarantee is claimed.

## Cheap validation commands and CI

`.github/workflows/psc0-checked-host.yml` is the routine push gate. It uses sparse cloud checkout, Git source identity checks, fast Node tests and immutable runtime reuse. It does **not** invoke Lean compilation, regenerate the kernel/compiler, retranslate all sources or execute C2/C3.

Equivalent cloud steps:

```sh
node scripts/architecture-source-identity.mjs
node scripts/check-workspace.mjs
node --test scripts/checked-prepared-session.test.mjs scripts/architecture-host.test.mjs
```

Then the workflow retrieves the pinned old runtime, repacks the current host using `architecture-repack.mjs`, performs ordinary offline npm installation and invokes `architecture-installed-smoke.mjs` for both editions on Linux and Windows.

The full `.github/workflows/psc0-npm-distribution.yml` is now **explicit `workflow_dispatch` only**. Its generation/qualification gates are retained, not weakened; expensive work is no longer automatically repeated for host edits. It uses the same host-staging helper as the fast repacker. This complete release-generation path was deliberately **not rerun** in this milestone. Do not mistake the private repacked CI candidate for a new npm publication or a refreshed public ZIP release.

The pinned artifact expires **2026-11-09**. Before then, retain/renew it through a reviewed authenticated release/archive operation when necessary. Missing or expired evidence must fail rather than silently regenerate or substitute a runtime.

## Exact final evidence

Fast run `38082117579`, implementation `2c48a6cca20f081c9d1785d56d3c67d637651a78`:

| Platform | Job | Result | Evidence artifact |
| --- | --- | --- | --- |
| Linux / Node22.23.3 | `114301005999` | success | `11680682736` |
| Windows / Node26.7.0 | `114301006107` | success | `11680573015` |

Linux evidence ZIP SHA-256: `ababa0b4e0ac0e867d1fcdceaee80ec043b11c8e38addbbeb6fa558db0f8e0b3`.
Windows evidence ZIP SHA-256: `64b825cd10bd183d36e9c5618389d5bbc22033bcdff1c87bf93b27d7f2f30181`.
Each contains source-preservation, retained-runtime repack and both installed-edition reports. The separately restored workspace contract passed at initial source `07f8760bdeaf642c98df3c59b460bf6faddb666d` in run `38081491966`; the same workspace code also passed the final matrix.

Historical failures are retained in the validation ledger:
- Run `38081492032`, initial `07f8760b...`: Linux full success; Windows 29/30 tests exposed input/output canonical-path mismatch.
- Run `38081879291`, `b97a66cf...`: Linux full success; Windows all30 tests passed, then CI-only GNU tar failed to interpret a drive-letter archive path.
- Final `2c48a6cc...`: stream exact verified tarball bytes through stdin, no archive path syntax; both platforms fully passed. No test expectations or source-preservation baseline were relaxed.

## Remaining boundaries and next work

This completed **bounded host milestone is not all of PSC0-ARCH/1**. Full frontend CPU/process isolation, exhaustive malicious-input coverage, complete axiom/effect/specification policies, registry-integrity authentication, stronger release provenance, arbitrary executable guest isolation, independent backend compilation, complete code-generation preservation and new installed C2/C3 reproduction remain separate declared work. Kernel formal proofs and kernel self-hosting remain owned elsewhere.

Do not restart completed qualification or broaden the project automatically. For a subsequent user-authorized step, first read current HEAD and this ledger, select one architecture obligation, keep one canonical owner, and use the fast guard until a genuine portable-source change requires intentionally scoped compiler qualification.

The prior strict-SH/1 AI work state is preserved byte-for-byte at [AI_WORK_STATE_BEFORE_CHECKED_HOST.md](docs/selfhost-language/strict/history/AI_WORK_STATE_BEFORE_CHECKED_HOST.md), original blob `349308be31b8d6880b2b0a9a5201e776ddb06d36`. Its original qualification is not superseded by host tests.
