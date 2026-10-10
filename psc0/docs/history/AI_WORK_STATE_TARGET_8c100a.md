# PSC0 AI work state — target-toolchain identity qualified

## Read first: completed milestone (2026-10-11)

The **bounded target-toolchain identity and publication binding** milestone is implemented and cloud-qualified on `psc0/npm-modular-packages-v1` in `dwijayuda/pskernel`.

**Qualified source:** `494a0a715ebd1e29eba2d146903bb6a3a722be06`.
**Production implementation:** `011dac43b802b1a092119d21f884e3388f6b300b`; the two subsequent commits change comparison tests/documentation only.
**Successful fast workflow:** [38086137673](https://github.com/dwijayuda/pskernel/actions/runs/38086137673).
**Linux/Node22.23.3:** job `114312964660`, success.
**Windows/Node26.7.0:** job `114312964479`, success.

Both platforms passed **66/66 host tests**, **23 workspaces**, unchanged compiler/kernel source-preservation checks, exact retained-runtime verification, offline npm installation and all PS/Lean installed source/closure/frontend checks. On both editions and OSes, the new direct native TypeScript invocation freshly produced `.ts`, `.js`, `.d.ts` and `.js.map` bytes identical to the retained original launcher on actual checked compiler output. Native executable and library drift were refused; attempted publication after native drift preserved the old executable. Test modifications were restricted to isolated CI installations and restored in `finally` blocks.

This is bounded host/target correspondence plus inherited compiler-source qualification. **It is not a new installed C2/C3 fixed point, full PSCV verification, general semantic-preservation proof, authenticated release, or kernel soundness/self-host theorem.** Documentation-only descendants do not claim separate execution evidence.

Machine evidence: [PSC0_TARGET_TOOLCHAIN_QUALIFICATION.json](docs/PSC0_TARGET_TOOLCHAIN_QUALIFICATION.json).
Contract: [PSC0_TARGET_TOOLCHAIN_BOUNDARY.md](docs/PSC0_TARGET_TOOLCHAIN_BOUNDARY.md).
Historical failure/correction: [PSC0_TARGET_TOOLCHAIN_VALIDATION.md](docs/PSC0_TARGET_TOOLCHAIN_VALIDATION.md).

## User authority and scope

The user authorized systematic, efficient continuation of PSC0-ARCH/1 while preserving compiler self-hosting and using the latest **qualified** language. Work began at `2cbe78e3b09504091026434ea3b9a5d3f49b7941`.

Use GitHub and cloud CI only. No local files/checkouts/builds/tests, Desktop Commander, force pushes or automatic npm publication. Read live HEAD before writes and preserve concurrent changes using expected-HEAD non-force updates. Main was not changed.

Kernel implementation, its `npm-runtime` adapter and formal proofs are owned by another branch; do not change them here. This slice adds no new language, backend, executable plugin system, package rename or default dependency. The required 13 scoped packages remain the existing compiler closure plus JS checker; optional backends/providers/stdlib remain outside the default package.

## Completed prior milestones — do not restart

1. P0/P1/P2 checked host: implementation `2c48a6cca20f081c9d1785d56d3c67d637651a78`, run `38082117579`, 30 tests per platform; documentation checkpoint `81abfd94102a3628842d07de019f60e92e7b9ea4`.
2. Owned frontend process/resource boundary: implementation `29c2d611a39d7c3187b1b8d333e5d023090bba9f`, run `38083824580`, 50 tests per platform; documentation checkpoint `2cbe78e3b09504091026434ea3b9a5d3f49b7941`.

The previous complete state is retained unchanged at [AI_WORK_STATE_FRONTEND_2cbe78.md](docs/history/AI_WORK_STATE_FRONTEND_2cbe78.md), blob `1e28ce878faf256e61e3f354d929427c462677c6`. Its earlier archives and qualification records keep their own source/run scopes.

## Self-host and kernel identities preserved

| Item | Preserved identity |
| --- | --- |
| Language | bounded `ps-0.9-r3`, new-only |
| Qualified strict entry | `psCompilerSh1TypeScriptSources`; generic APIs do not silently select it |
| Qualified compiler source | `1fa5559a72b293defc56ef7e7020cf82d4b44b79` |
| Historical qualification completion | run `38027413274`, per `docs/selfhost-language/CURRENT.md` |
| Compiler source | **69 unchanged files** across all twelve source-ownership packages |
| Bootstrap closure | **64 modules**, scanned from both installed source editions |
| Source inventory SHA-256 | `fc08090151979be64458352a030a2aaa11bc0df5aab6a3e8cc71b3c4213ad0de` |
| Seed/toolchain | selected R seed; TypeScript7.0.2; bootstrap Node22.23.3; Lean4.34.0 |
| Retained runtime source | `2f42a52814f3785ff2d92bd826f6e7fb3eb9bc8a` |
| Retained runtime run/artifact | `38075437516` / `11678641329` |
| Runtime archive SHA-256 | `3b89239132db2003a3ee0cc01c2c4c9795be4d4ae0097d86a62616fc48fa122a` |
| Compiler JavaScript SHA-256 | `6cddc3c34c38f1524ef9a355c46b0eb17949c45c54fd59367ea370c1af861ab3` |
| Kernel JavaScript SHA-256 | `c3912cdbc078d8a56736ef2790221567f2fab8b129a0a26e80b437b79f95ba27` |

`architecture-source-identity.mjs` and its baselines are unchanged. The entire kernel source and adapter tree, compiler grammar and seed/toolchain inputs remained identical. Compiler/kernel JavaScript was reused byte-for-byte, not regenerated. No portable compiler `.lean`/`.ps` functions were moved into host JavaScript.

A real portable-source/grammar/seed/target-toolchain change requires deliberately scoped compiler qualification; never adjust a baseline merely to make a guard green. This new host target plan has bounded installed correspondence evidence, not proof that all possible generated programs preserve semantics. Kernel self-host and proof work remain separate.

The retained runtime artifact expires **2026-11-09**. Retain/renew through a reviewed archive/release operation when required; absence or expiry must fail rather than silently substitute runtime bytes.

## Current checked-build ownership

`psc.js` -> parent `build.mjs` -> captured target plan (for build only) and source snapshot -> owned frontend worker -> parent-selected existing JS kernel -> worker's frozen checked session -> generated TypeScript -> selected native TypeScript process -> exact product hashes -> worker closed -> source and target revalidation -> single immutable-generation publication switch.

| Owner | Responsibility |
| --- | --- |
| `target-files.mjs` | Bounded binary-safe streaming fingerprints and immutable target-package inventories |
| `target-process.mjs` | Absolute native executable, no shell/PATH lookup, sanitized environment, cancellation/deadline/diagnostic limits; await close |
| `target-toolchain.mjs` | Exact installed TypeScript7.0.2/native platform selection, fixed monolithic target plan, checked input/output hashes, state and identity revalidation |
| `build.mjs` | Bind plan hash to frontend checked handle; invoke native target; revalidate source AND target at existing publication boundary |
| Existing frontend/session/snapshot/publication modules | Retain prior canonical owners and invariants; no independent bypass added |

`psc check` does not resolve or execute TypeScript. `psc build` no longer passes through TypeScript's JavaScript wrapper: it runs the same selected installed native executable directly. This permits parent cancellation and avoids shell, PATH or wrapper-child lifetime ambiguity. The captured installation includes both TypeScript package files and the separately selected platform package, including executable and declaration libraries. Immediate `node_modules` children of each package root are excluded; the native dependency is a separately captured root.

The target plan retains ES2022/module/strict/declaration/map options and explicitly uses `--ignoreConfig`, `--noResolve`, and a newly created private empty `typeRoots`. Only the existing monolithic compiler-generated target profile is supported; foreign target-file linking is not introduced. Normal ProofScript source libraries remain supported through their existing checked source graph.

**Version nuance:** TypeScript6+ already defaults `types` to `[]`. Do not describe this implementation as fixing automatic ambient-type inclusion in the old TypeScript7 default. The final tests separately verify (a) the pinned default ignores unrelated malformed `@types`, (b) explicitly selecting that package produces its actual syntax error, and (c) the fixed target plan ignores surrounding project types/noEmit settings and produces fresh, byte-identical outputs.

Receipts now include the target plan/hash, native executable hash, package inventory digest, input TypeScript hash and four product hashes. They remain **audit data, not transferable proof authority**. Generated claims continue to say target semantics and full PSCV are not formally proved.

## Limits and residual trust

Target inventory limits: 4,096 entries, depth24, 128MiB/file, 256MiB total; binary files are streamed in64KiB chunks. Target process: 15s version query/4KiB diagnostics, 180s compile deadline/1MiB diagnostics, 32MiB per generated product. Cancellation, nonzero exit, malformed installation, exceeded limits or observed drift decline publication. Existing frontend/kernel limits remain unchanged.

Installed-byte hashing detects observed drift; it does not authenticate npm registry/publisher/builder, prove native TypeScript correctness, sandbox hostile native code, bind every OS/dynamic-library input, or eliminate transient filesystem races. No total native-process RSS limit or hard filesystem IO deadline is claimed. The environment allows only required system/temp paths and fixed locale rather than arbitrary Node/Go/preload/PATH settings.

The `.psc-artifacts/` generation/entry-point output contract is unchanged. Deploy the generation with its entry module. Failure preserves prior published output. Public ZIP regeneration, signed provenance, registry publication and main merge are not part of this milestone.

## Exact final evidence and cost

Final run `38086137673`, source `494a0a715ebd1e29eba2d146903bb6a3a722be06`:

| Platform | Job | Tests | Evidence artifact / SHA-256 |
| --- | --- | ---: | --- |
| Linux / Node22.23.3 | `114312964660` | 66/66 | `11682836528` / `b62f43ee904aee65460ca84ddc8dcb4a40ff7f3b501c0bd929a6929d1d5b8db9` |
| Windows / Node26.7.0 | `114312964479` | 66/66 | `11682667446` / `a73fa912382176ec6dc5abc02699181ebecb0b4760f6f4ba7467c605d74611ba` |

Each artifact contains nine reports: source preservation, two retained-runtime repacks, two installed source/closure checks, two frontend resource/correspondence checks and two target identity/correspondence checks. All source editions passed on both platforms.

Linux selected `@typescript/typescript-linux-x64@7.0.2`: native SHA `4f2de678286401759b3fb4475bafe35b8f32b4b3a07d92642bbf37eadc9b34a4`; inventory SHA `6caddf643a31343c2bd2bc92a305380f4bf5dc90743d4f3445bb4eff20f6efb9`; **530 files /30,443,488 bytes**.
Windows selected `@typescript/typescript-win32-x64@7.0.2`: native SHA `f9ecfbdc93753d2c972d66a8d0d75f5bd737fd4a5f88b422d9091ea282bcb2c7`; inventory SHA `818b5d17cba311fafc207becbeeee462ef6ade934d7b99ed0713b8071c661b47`; **529 files /30,862,525 bytes**.

The source diff adds **199 net physical production host lines** (211 new module lines,12 removed net integration lines) and **197 test lines**, excluding docs/workflow changes. No extra npm runtime dependency, compiler/kernel source change, full generation or C2/C3 cycle. Installed target comparison reuses the earlier suite's generated TypeScript instead of elaborating a new compiler or proof corpus.

## Recorded failed premise and stricter follow-up

Initial `011dac43b...`, run `38085378252`: source/workspace/66 unit tests passed but the target fixture wrongly expected nearby `@types` alone to break TypeScript7's original invocation. Record this as failed qualification, not a production soundness result. Official TypeScript6 release documentation and actual pinned behavior corrected the premise.

Commit `17e2964030fa2ac795345ca49cd78e9862df82b4` adds explicit positive/negative controls and surrounding tsconfig. Its run `38085900920` was superseded/cancelled, not counted as a complete pass. Final commit `494a0a715ebd1e29eba2d146903bb6a3a722be06` makes both controls non-emitting and requires generated files to be absent before the owned target runs, preventing stale-output false positives. No production implementation or existing test/source baseline was relaxed. Final Linux/Windows qualification then passed.

## Cheap validation and next-work guardrails

Use `.github/workflows/psc0-checked-host.yml`:

```sh
node scripts/architecture-source-identity.mjs
node scripts/check-workspace.mjs
node --test scripts/checked-prepared-session.test.mjs scripts/architecture-host.test.mjs scripts/architecture-frontend.test.mjs scripts/architecture-target.test.mjs
```

Then reuse the pinned runtime, repack/install the current host, run `architecture-installed-smoke.mjs`, `architecture-frontend-installed.mjs`, and `architecture-target-installed.mjs` for PS and Lean on both OSes. The full npm generation workflow is explicit-only and was not invoked. New qualification candidates remain private, not new public release ZIPs.

Next user-authorized work should select one remaining architecture obligation with a canonical owner. Do not restart the completed checked-host/frontend/target milestones, grow a general plugin platform, casually change compiler self-host baselines, modify kernel work, or run expensive full self-host tests for host-only edits. Axiom/effect/specification policy, authenticated source/release provenance, independently compiled backend packages, hostile guest isolation and a fresh installed compiler fixed point remain separate milestones.
