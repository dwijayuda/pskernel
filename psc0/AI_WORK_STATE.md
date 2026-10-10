# PSC0 AI work state — source-library disclosure qualified

## Read first: completed milestone (2026-10-11)

The **source-library identity and host-owned disclosure** milestone is implemented and cloud-qualified on `psc0/npm-modular-packages-v1`, repository `dwijayuda/pskernel`.

- Qualified implementation: `5dcd90cbf62dff278e9cd1294f18e4f1faf98138`.
- Successful first implementation run: [38087964327](https://github.com/dwijayuda/pskernel/actions/runs/38087964327).
- Linux/Node22.23.3: job `114318345926`, success.
- Windows/Node26.7.0: job `114318346027`, success.
- Both platforms passed **85/85 host tests**, **23 workspaces**, unchanged compiler/kernel source-preservation checks, exact retained-runtime verification, offline npm installation and both PS/Lean installed checks.
- Real installed source-library checks passed: receipt/snapshot/checked-binding agreement, raw source/manifest hashes, unchanged canonical admissions after nonsemantic package metadata changes, pure JSON stdout plus mandatory host stderr notices, no package entrypoint or lifecycle-script execution by the compiler, refusal of invalid library source and unsupported executable-extension requests, and preservation of the previous executable.

This first coherent implementation passed without a test-fix loop, compiler/kernel regeneration, full C2/C3, new dependencies or source-language changes. Documentation-only descendants retain this exact qualification source rather than claiming separate execution.

Contract: [PSC0_SOURCE_LIBRARY_DISCLOSURE.md](docs/PSC0_SOURCE_LIBRARY_DISCLOSURE.md).
Machine evidence: [PSC0_SOURCE_LIBRARY_QUALIFICATION.json](docs/PSC0_SOURCE_LIBRARY_QUALIFICATION.json).

**Scope:** this is the source-only portion of PSC0-ARCH/1's INV-12 disclosure requirement and additional INV-02 input binding. It is not all P3, arbitrary executable guest support, full PSCV, a new installed self-host fixed point, authenticated package provenance or a formal semantic/soundness proof.

## Authority and no-drift boundaries

The user authorized efficient systematic architecture continuation while keeping the compiler self-hostable and using the latest **qualified** language. Starting HEAD for this milestone was `8c100a74f9724f39e55d3e707484a7e1be75de8a`.

Use GitHub for repository work and cloud CI for execution. No local files/checkouts/builds/tests, Desktop Commander, force push, automatic npm publication or unrequested main merge/release. Verify live HEAD before every write and preserve concurrent history through expected-HEAD non-force updates.

Kernel implementation, the `psc0/npm-runtime` kernel adapter, and metatheory are owned by another branch; they MUST NOT change here. No additional default packages, compiler rewrite, new language dialect or general plugin platform was introduced. The 13 required scoped packages remain the existing compiler closure plus JS checker; optional backends, providers and stdlib remain outside the default install.

## Prior completed milestones — do not restart

| Milestone | Qualified implementation | Successful run | Host tests/platform |
| --- | --- | --- | ---: |
| P0/P1/P2 checked host | `2c48a6cca20f081c9d1785d56d3c67d637651a78` | `38082117579` | 30 |
| Owned frontend process/resource boundary | `29c2d611a39d7c3187b1b8d333e5d023090bba9f` | `38083824580` | 50 |
| Native target-toolchain identity | `494a0a715ebd1e29eba2d146903bb6a3a722be06` | `38086137673` | 66 |
| Source-library identity/disclosure | `5dcd90cbf62dff278e9cd1294f18e4f1faf98138` | `38087964327` | 85 |

The previous complete state is archived byte-for-byte at [AI_WORK_STATE_TARGET_8c100a.md](docs/history/AI_WORK_STATE_TARGET_8c100a.md), blob `cb6330c50ac297923c22b41aa19f2a8c8d056ebb`. Follow its links for older full work states, target/frontend ownership and exact historical validation failures. Those records keep their original source/run scope.

## Preserved compiler self-host and kernel identities

| Item | Inherited identity |
| --- | --- |
| Language | bounded `ps-0.9-r3`, new-only |
| Strict entry | `psCompilerSh1TypeScriptSources`; generic APIs do not implicitly select strict SH/1 |
| Qualified compiler source | `1fa5559a72b293defc56ef7e7020cf82d4b44b79` |
| Historical qualification completion | run `38027413274`, per `docs/selfhost-language/CURRENT.md` |
| Compiler source | **69 unchanged files** across twelve source-owning packages |
| Bootstrap closure | **64 modules**, loaded/parsed from both installed source editions |
| Compiler source inventory SHA-256 | `fc08090151979be64458352a030a2aaa11bc0df5aab6a3e8cc71b3c4213ad0de` |
| Seed/toolchain | selected R seed; TypeScript7.0.2; bootstrap Node22.23.3; Lean4.34.0 |
| Retained runtime source | `2f42a52814f3785ff2d92bd826f6e7fb3eb9bc8a` |
| Retained runtime run/artifact | `38075437516` / `11678641329` |
| Retained archive SHA-256 | `3b89239132db2003a3ee0cc01c2c4c9795be4d4ae0097d86a62616fc48fa122a` |
| Compiler JavaScript SHA-256 | `6cddc3c34c38f1524ef9a355c46b0eb17949c45c54fd59367ea370c1af861ab3` |
| Kernel JavaScript SHA-256 | `c3912cdbc078d8a56736ef2790221567f2fab8b129a0a26e80b437b79f95ba27` |

The existing source-identity guard and baselines are unchanged. The entire kernel source/adapter, compiler source, grammar and seed/toolchain inputs remained identical. Both editions reused exact compiler/kernel JS bytes. No portable `.lean`/`.ps` functions were rewritten in handwritten host JavaScript.

Do not change a baseline merely to make the guard pass. A genuine portable-source/grammar/seed/target-toolchain change needs deliberately scoped compiler-only qualification; host-only changes can reuse the inherited source-specific evidence. **No new installed C2/C3 fixed point is established by this source-preservation gate.** Kernel self-host and proofs remain separate.

The retained runtime artifact expires **2026-11-09**. Archive/renew it through an explicitly reviewed operation when needed. Missing or expired evidence must fail rather than silently substitute or regenerate a runtime.

## Canonical ownership and user-visible contract

| Owner | Current responsibility |
| --- | --- |
| `npm-cli/library-disclosure.mjs` | Parent-owned deterministic source-library inventory, metadata shape checks, mandatory stderr notices; no proof authority |
| `npm-cli/libraries.mjs` | Existing source-only npm resolution; describes captured package manifests; no JS entrypoint/lifecycle execution |
| `npm-cli/snapshot.mjs` | Existing immutable byte capture/revalidation; `fileEvidence` exposes raw fingerprints of already observed bytes |
| `npm-cli/source-graph.mjs` | Records resolved module aliases before physical-file compilation deduplication; seals inventory into snapshot |
| `npm-cli/build.mjs` | Writes disclosure after complete capture and before admission; binds inventory digest into checked session and receipt |

The inventory distinguishes declared mappings from **actually loaded source libraries**. It records namespace, reported version, manifest hash, consumed module raw hashes and script names. Script command bodies are not printed/executed. Unused declared packages are not opened or claimed loaded. The optional `@proofscript/stdlib` has no extra proof authority.

`fileEvidence` uses original captured bytes including UTF-8 BOMs, not decoded text hashing or a second read. Multiple logical aliases for one real file are all captured/disclosed; compilation still deduplicates the physical source. Metadata/source/realpath changes continue to invalidate the snapshot.

Inventory schema: `psc0-source-library-disclosure/1`; hash domain: `PSC0/LIBRARY-DISCLOSURE/1\0`. Receipt schema4 includes `libraryDisclosure`; its digest also appears in `checkedBinding` and the source snapshot. Canonical admissions still come from the unchanged compiler and selected JS kernel. No receipt or library claim becomes proof authority.

The parent emits `PSC_SOURCE_LIBRARIES:` and per-package `PSC_SOURCE_LIBRARY:` JSON records on **stderr**, including in `--json` mode. stdout remains the result JSON. Package metadata cannot supply a logger or suppress switch. Notices describe loaded sources, not successful proof checking; admission may still fail. A failed graph capture does not claim a complete zero-library inventory.

The supported `proofscript.library` subobject has exactly `{schemaVersion:1,modulePrefix:<namespace>,sourceRoot:"src"}`. Unknown fields in that semantic subobject are refused. Any root-project or loaded-library `proofscript.extensions` property, including an empty array, is explicitly unsupported in this source-only edition. Ordinary additional package metadata does not acquire compiler authority. No executable extension protocol was added.

Budget additions: at most256 declared libraries,2048 recorded modules,128 bounded script names/package and256KiB rendered notice. Existing source/frontend/kernel/target limits are retained. These finite input limits are not a proof against all filesystem races or hostile OS behavior.

## Final cloud evidence and size

| Platform | Job | Evidence artifact | SHA-256 |
| --- | --- | --- | --- |
| Linux / Node22.23.3 | `114318345926` | `11683070444` | `32e46fbc605e36c56aefc4d2bfcd431fc6a3c499e25528caf0c93ab3dbbe05ec` |
| Windows / Node26.7.0 | `114318346027` | `11683800367` | `d45bef696107de9e56059f09ae9a04973359cd9d1c7580a2c0088db469b4e80b` |

Each contains **11 evidence files**: source-preservation, two runtime repacks, two installed source/closure checks, two frontend correspondence checks, two target correspondence checks, and two new library-disclosure checks. All passed. The library fixture's final disclosure digest matched across the two OSes for each edition: PS `066a801ad67d56e46d94446536c048fef5f12b8a052cfc8e82462a80f1ab3ae2`; Lean `f51d6abe8eda2e839d6b3ba7b188389717ab6d3940cc1c2d8543e4a075cd718b`. This is fixture-specific deterministic evidence, not universal reproducibility.

All66 earlier host tests remain unchanged and passed;19 new focused tests bring the total to85. The installed tests deliberately modify only isolated CI fixture packages, and restore their source/metadata in `finally`. No fake package entrypoint marker was produced. Invalid library source and an unsupported executable request did not replace the previous executable.

Production delta: **91 net physical host lines**. Tests: **243 new physical lines** (161 focused tests +82 installed checks). No npm dependency or portable compiler/kernel source-line changes. The first implementation run passed; no test assertion or source-preservation baseline was weakened.

## Cheap continuation and remaining scope

Continue to use `.github/workflows/psc0-checked-host.yml`: unchanged source/pin guard,23-workspace validation,85 focused tests and retained-runtime installed PS/Lean checks on Linux/Windows. The full npm-generation workflow remains explicit `workflow_dispatch` only and was not run. These are private qualification candidates, not a replacement public ZIP or npm publication; main was not merged.

The compiler source-specific self-host evidence is preserved, but executable guest isolation, complete effect/specification/axiom policies, lockfile-to-registry authenticity, independently compiled backend packages, verified code generation, authenticated public releases and a new installed fixed point remain separate milestones. Do not expand this source-only ledger into a general plugin framework without an explicit scoped design.

Source-only import is not safe npm installation: npm may have run lifecycle code before `psc` starts, so the inventory deliberately says `installationHistory: "not-observed"`. Hashes identify consumed bytes, not publisher authenticity or whole-package correctness. The OS can redirect stderr and a modified trusted host can alter its own code; this protection is against package metadata/ordinary source input, not malicious in-process JavaScript.

For the next user-authorized step, read live HEAD, choose one remaining PSC0-ARCH/1 obligation and keep a single canonical owner. Do not restart completed tests unnecessarily, touch kernel work, casually change the language baseline or run expensive fixed-point cycles solely because host code changed.
