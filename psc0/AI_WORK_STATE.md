# PSC0 AI work state — continuation authority

Updated: 2026-10-09 15:37:15 UTC. Times in this file are UTC; the user's timezone is Asia/Jakarta (UTC+07:00).

## Read this first

This is the current handoff for the ongoing dwijayuda/pskernel work. The user explicitly requested a detailed committed AI_WORK_STATE.md so a new chat can finish the work without drifting. Continue the authorized implementation; do not restart the research or ask the user to authorize work already accepted.

**Current result:** the practical new-only PSC0 grammar and twelve-worker migration are implemented. Selected R is fully qualified. The new TypeScript 7-only native recovery is independently cold-proven. Current F has passed the selected-R C1 candidate gate and is running C2/C3; its final provider gate is still pending. The separate repository-root TypeScript 7 migration is fully qualified: all seven commands passed, including builds, the complete package tests, package integration and repository boundary checks. Root independently authenticated its exact five-file evidence and all 11 adapter obligations.

**Do not mark the whole task complete from this snapshot.** Finish the exact active F run below, authenticate its final evidence, retain all three scopes of proof, reconcile the current guides, and integrate the qualified descendants. Do not repeat successful root or native cold qualification.

Everything at and below the later heading "Historical completed M6 and TypeScript 7 result" is archival. Some historical subsections contain words such as "Current", "next" or "selected"; those describe their old checkpoints, not today's active instructions. This active section takes precedence.

## User intent and persistent decisions

- Research why self-hosting is constrained, implement a suitable finite language subset and source migration, and make iteration faster and more effective.
- Create/use working branches for changes. Continue autonomously on already authorized work. Main remains untouched.
- Use the supplied new .ps grammar only. Do not keep an active old-grammar fallback or add backward compatibility.
- Retire TypeScript 5 from future development. Current PSC0 compilation, recovery, root workspace compilation and remaining compiler launchers must require TypeScript 7.0.2; do not install TS5/TS6 API fallbacks.
- Preserve immutable historical source revisions, original producer-version facts, seed identities and receipts. Historical 5.8.3 text is not permission to execute that compiler in today's workflow.
- Avoid a repeated guess/test/fix loop. Diagnose a demonstrated class, review related obligations together, use cheap preflight, and run the full qualification only at a coherent semantic checkpoint.
- Keep this file accurate after concrete milestones and before a handoff.

### Execution and scope boundaries

This continuation uses GitHub connector/MCP reads and writes, with actual builds/tests only in GitHub Actions. Do not clone, build, test or execute repository code locally; do not switch to a local shell, browser or DesktopCommander workflow. Pure in-memory text/JSON transformations and evidence hashing are permitted. Git-backed deliverables remain in the repository.

Use fresh branch-head leases for every update, preserve concurrent work and ancestry, and never force-push. Do not change provider/kernel/metatheory/definitional-equality/cache algorithms. The exporter correction below changes a TypeScript declaration only, not process behavior. Do not weaken gates, select F as a seed, merge main, or claim strict SH/1, unrestricted PSC1, full Standard or PSCV.

Pins: Lean 4.34.0, Node 22.23.3, TypeScript 7.0.2. Continue useful work while Actions runs; communicate meaningful progress to the user.

## Branches, exact sources and qualification runs

Read the live refs before doing further writes. This checkpoint is written on the root retirement branch after the source commit below; a documentation descendant is not a new compiler qualification.

| Branch or evidence | Exact identity at this checkpoint | Meaning |
| --- | --- | --- |
| psc0/typescript-7-only-v1 | source 9d150afbec1feda8c97058aa56aa5ab92347d96d; tree c97468df9855bb7379b49e0771ed5e373e39c8b2 | Combined descendant containing F/PSC0 retirement plus root TS7 changes |
| psc0/sh1-projection-grammar-v1 | fcd875c8f38db4b0524090bd10c7c2fd5024053d; tree 0bda17a81be9f790fa12a5fc38bd32d36f38f6ae | Pinned source of active F qualification and successful native cold recovery |
| psc0/sh1-implementation-v1 | last confirmed 5e3a991088aaa735c8f324c4e70a7a3dee4cd69a | Canonical integration remains at the earlier completed checkpoint; re-read before fast-forward |
| psc0/typescript-7-v1 | last confirmed 5e3a991088aaa735c8f324c4e70a7a3dee4cd69a | Earlier TS7 integration alias; re-read before fast-forward |
| main | last confirmed 37f63c39d4a07189938046c64152bba25d789450 | Unchanged by this work |
| Selected R source | fe2560aba0f347b1caf8d000d371464642d44f23 | Fully qualified, explicitly selected authoring compiler |

### Active F qualification — do not relaunch

- [Run 37947341800](https://github.com/dwijayuda/pskernel/actions/runs/37947341800), source fcd875c8f38db4b0524090bd10c7c2fd5024053d.
- Compiler job 113876931430.
- Latest observed steps: installed TS7/source/seed gates passed; native build and 75/10/16 suites passed; source/import/session and CLI gates passed; authenticated R 87-case plus supported ABI probe passed; bounded N1 development passed; **selected-R C1 passed**; C2/C3 fixed-point step 25 is in progress.
- Steps 26–28/provider completion are not yet final. Step 26 should be skipped because F must not be promoted to a new selected seed.
- Expected final compiler gates: steps 3,6,7,8,9,11,14,17,18,19,20,21,22,23,24,25,28 succeed. The retired successor-recovery job must be absent.
- Do not push executable changes to this branch while its run is active. Its concurrency policy can cancel an active qualification.
- C1 step success is earned; do not invent complete generation receipts, current C2/C3 hashes, provider acceptance or runtime speedups before reading the final evidence.

### Completed root TypeScript 7 qualification

- [Run 37951869293](https://github.com/dwijayuda/pskernel/actions/runs/37951869293), source 9d150afbec1feda8c97058aa56aa5ab92347d96d.
- Root job 113892421469, workflow ID 379741182, attempt 1.
- Completed successfully: all seven required commands exited zero. The receipt spans 2026-10-09T15:27:57.441Z through 15:28:22.403Z; the job completed at 15:28:26 UTC. Root and projection_repair independently authenticated the full primary log, actual completed API objects, all five original receipt files, all 21 package bindings, the unchanged exact lock (lockGenerated=false), and the 11-obligation adapter record.
- Dedicated workflow: .github/workflows/root-typescript7-qualify.yml.
- The passing ordered commands are npm ci; root build; test:packages; conformance build; lean4export build; package integration; check:packages. Their recorded command times total 24,845 ms. This is a run measurement, not a TS5/TS7 benchmark.
- This root gate does not qualify PSC0, run Lean corpus/oracle tests, change provider acceptance, or promote a seed.
- The workflow is branch/path plus [root-ts7-qualify] gated. Do not add the marker to evidence/documentation-only commits or rerun after sufficient proof.

## Why the subset was needed and what actually changed

The original root configuration did not actively select PSC1-selfhost-stable/1 or PSC1-portable-selfhost/1 as the compiler source contract. The practical restrictions came from the owned parser, elaborator, structural recursion normalizer, prelude, erasure and backend coverage. Acceptance by host Lean or a broader language/profile label did not prove that the generated compiler could consume and rebuild that source.

The old recursion normalization required non-decreasing arguments to stay unchanged. Source used returned-function state adapters to work around that implementation boundary. The implemented bounded normalization supports ordinary changing parameters around accepted structural Nat/List/regular-inductive descent and preserves the public function types. Shared exact-name / first-segment / longest proper local-prefix resolution fixes recursive record-parameter projections without changing structural identity checks or adding error fallbacks.

This is a finite practical authoring subset, not unrestricted Lean/PSC1. Do not broaden it by changing a profile string. Current .ps parser/printer/import/session handling is new-only ps-0.9-r3; the 61-module handwritten .lean closure remains authoritative. Switching all handwritten compiler authority to .ps is not part of the completed claim.

### New-only .ps contract

Grammar identity:

    {"edition":"ps-0.9-r3","mode":"new-only","support":"bounded-selfhost-subset","referenceSha256":"4c02626fd0b991e8526c64b65f4ffb66b9ce7b688298e82fb0309802a263db71","fullStandardConformance":false,"fullPscvConformance":false}

The supplied reference is 401,569 bytes / 8,546 lines and is a design RC with broader Standard/environment conformance pending. Implemented forms include newline-oriented sequences, one explicit comma-separated declaration/constructor binder group, strict record commas, bar cases, grouped/adjacent/native-gap calls and typed lambdas. f(()) remains one Unit argument; empty f() is not silently rewritten to Unit and unsupported completion is refused.

PS lexical boundaries preserve raw UTF-8 positions and LF/CRLF handling, allow a leading BOM only, and reject tabs, lone CR and later BOMs outside the documented literal/comment boundaries. Host decoding is fatal for invalid UTF-8. There is no active legacy PS parser/semicolon mode. Historical Lean/seed source remains at immutable historical refs.

### Finite F production migration

Production edits first landed at 9ee0b1fd38dd1456a187d4675f9027440a989f2d and remain unchanged through fcd and the root branch. F changes twelve workers in nine Lean files and removes three projection aliases in a tenth; seven existing source guards were aligned. Public types, parameter order, fuel/zero behavior, reversal/order rules and collision limit 4096 are preserved requirements.

The ten production source files are in the following psc0/packages packages. Read the actual source or candidate ledger for exact declaration locations before editing.

| Package | Source file |
| --- | --- |
| backend-ts | Expr.lean |
| backend-ts | Module.lean |
| compiler | Api.lean |
| elab | Declaration.lean |
| erasure | Basic.lean |
| erasure | Definition.lean |
| erasure | Expr.lean |
| erasure | Inductive.lean |
| erasure | Structure.lean |
| compiler-ir | Check.lean |

The twelve worker names, in ABI-probe order, are psErasureLocalNameWithFuel, psErasureEtaNameWithFuel, psTsFreshMatchTempWorker, psTsFreshInternalWorker, psCompilerPreparationSourcesWorker, psAddDeclarationListWorker, psElabDeclarationsWorker, psBuildErasureDeclarationNamesWorker, psEraseDefinitionsLoopWorker, psPrepareRuntimeStructures, psPrepareRuntimeInductives and psTsBuildSymbolMap. The three removed identity aliases are one limits := options in psIrCheckMatchBindings and two currentState := state aliases in psIrCheckRun.

The twelve signature arities in probe order are [4,4,3,4,2,2,3,2,4,5,5,3]; original partial splits are [3+1,3+1,2+1,3+1,1+1,1+1,1+2,1+1,3+1,3+2,3+2,2+1]. The migration is F1=4 workers plus F2=8 workers, with 44 direct cases + 7 wrapper cases + 36 state cases = 87 unique behavior cases per compiler.

The complete original inventory has 241 locators; 226 remain explicitly deferred. Not every function-valued result is a workaround. Do not perform a wholesale rewrite or silently mark those deferred entries done.

### Earlier F failures are preserved, not hidden

1. Run 37939061854 at 9ee failed a new host fixture's nonexistent structure-constructor call. f62c38c890af13b1e8ccb2a4d2650b9c7c6d2d5f corrected all 48 invalid calls across 20 structure types with existing neutral factories, same-compiler template copies and three explicit non-IR host records. All independent expectations were retained.
2. Run 37941485695, compiler job 113856701970, at f62 passed the complete R and N1 87-case reports. Their observation SHA-256 is 697616ab48daf77a44b90ce20085432593ddce9a06fdad124a5a898ece3621be. Native original IR accepted 56,602 expressions / 728,064 visited steps / zero findings; all 61 modules round-tripped with 902,538 PS bytes. It then failed before C1 emission because the isolated ABI fixture used unsupported axiom declarations.
3. fcd replaces that fixture with 19 one-constructor monomorphic inductives and the same 12 explicitly typed partial wrappers. The complete first explicit binder type supplies each reference signature. The early supported probe passed; full actual prepared Core/IR ABI checks remain in every C generation. No current compiler source behavior was changed by these fixture repairs.

Attempt-2 F closure: 6306cdac131f849a9a96de3dc4d628a48b953072b45fc6cc829075bd90b67ac7. Its N1 JavaScript is 5eeecb1bfa00f11f1691f5ee4b437ecebe5c9a45b4e4256ab1bde23b0771df15 and TS is 0d90517192bba53dbc6190c774158559b64871b7222ba37b0df5a65a325db99a. Those are the recorded attempt-2 native results, not substituted final F proof.

Existing files in docs/selfhost-language retain worker-migration-attempt-1.json, worker-migration-fixture-repair.json, worker-migration-attempt-2.json, worker-migration-abi-repair.json and their primary logs. The candidate ledger and qualification-evidence.json still need their final successful F update.

## Selected R and proven TypeScript 7-only native recovery

R source fe2560aba0f347b1caf8d000d371464642d44f23 qualified in [run 37925722635](https://github.com/dwijayuda/pskernel/actions/runs/37925722635). Compiler job 113804052074, independent provider job 113827136830 and original parent-based cold job 113827137018 passed. Explicit selection is commit e65606397fb679d7cb96f4f0e92700a6cf0944a6. The later collector run 37938411520 retained 18 exact receipt files.

- R source closure: f96c811f575cae2be58ccca3ffe587ead83bffa6f8bd862d40936bef28ef3226.
- R selected identity: 47d88158e075f766f0d146ba3a13b28744c6e196d9844c71f4e52dc7351e2225.
- Selected manifest actual file SHA-256: 7a0c2cf950333aa680f2ae00e214f57b674dab2d783a1403b242b92e71c56694.
- Selected manifest Git blob: 44a05964c49000478c282afc013c84fca8c2de65.
- Current selection does not depend on promoting F.

| Exact selected R product | SHA-256 |
| --- | --- |
| Canonical PS source JSON | 985cf39d4a68df68a03123883105b6bdd9b81783c4bab98c8ec86ec683ac3b07 |
| Canonical admissions | 200e5881d1554f72530a0395524ee28dd3a64a6bd45f55cddd4fad1336981bf0 |
| TypeScript | 38fea23209f561efcab0c0111a2a15fa1e5761d33f31100fac8d6bfb1e032935 |
| JavaScript | 70db0131fa3af62f7193576407ad529be10df2f4296c712f53f7c31f42209061 |

### New cold proof — already successful

[Run 37947341899](https://github.com/dwijayuda/pskernel/actions/runs/37947341899), job 113876930974, source fcd, passed at 14:54:23 UTC. It used no restored compiler artifact, seed cache or native build cache. All 75 recorded commands, including 61 native PS translations, succeeded. All four products above matched, and the tracked raw source, closure and selected manifest remained unchanged.

The native recipe is native-lean-original-ir-four-products-ts7/1. Its original IR check accepted 56,391 expressions / 725,484 visited steps / zero findings, then emitted that same IR. No generated compiler, historical A/S0 compiler, or TypeScript 5 was executed. The exact selected-R seed identity is preserved; this is a new recovery recipe, not a re-identification of the seed.

- Recipe SHA-256: 4ed186c2604bcfaee756881686e70f14569720d72fcd799d9997d2d92217b82a.
- Policy SHA-256: 0cf0480524ba713e0bcdbeb3cfa3d345e37508743ee5e169b83ba8ee0de160fc.
- Runner scripts/sh1-native-seed-recovery.mjs blob: 4e2fe462ba5c8160ff5c08f70ce52152173b0d6f.
- selfhost-seed-recovery.json blob: fd75854159544e431497bc7dee8482bea727b5e4.
- Independent workflow .github/workflows/psc0-sh1-ts7-recovery.yml blob: 4512b46247642f2ab6043a5d81ba8d2a62fd703f.
- Exact receipt SHA-256: 0d5606c25e634082da39d80ffa5974b3c390d2765ded71bcf1abaf442b7e3919, 64,164 bytes; blob c495ddf6e7d5075e204e4b0c5957c8c0d3d6a24b.
- Full decoded log SHA-256: 6f47360b88446d7a06f12561772e8d9e317b1f3bfb6d34d610791436f99b3957; blob d5ae70f7459ad82ba2aa3a23043e374921fb2316.
- Artifact ID 11624048503, ZIP digest 967adc94a58d02e4e166e24601252f177a372dc5e6fd50ba01a7125cec9dfae5. Archive bytes were not downloaded by the reviewers.

Recorded recovery work was 86.497 seconds; the whole job was 158 seconds. The old parent-based recipe recorded 2,728.787 seconds in a separate run. This is not a controlled benchmark or a measured PSC parsing/self-compilation speedup.

Root and grammar_adoption_audit independently checked the actual completed run/jobs, complete log, 75-command receipt, all four hashes, source/manifest invariance and policy pins. The cold receipts are prepared as immutable blobs but still need the final repository retention paths:

- docs/selfhost-language/typescript7-native-recovery.json.
- docs/selfhost-language/typescript7-native-recovery-evidence.json.
- docs/selfhost-language/evidence-logs/typescript7-native-recovery.log.
- API metadata under docs/selfhost-language/seed-evidence/fcd875c8f38db4b0524090bd10c7c2fd5024053d/.

Current PSC0 rejects seed-identity, recover-seed, recover-qualified-seed and recover-successor-seed before resolving TypeScript. Cache misses use the pinned native runner. Do not restore the old TS5 dispatch or repeat the retired full-source TS5/TS7 comparison.

The independent provider remains source 963030dc2d154008fccc82e7c8ed29331f138799, tree 38c8c55bd2b214753e56c58c15c4901c32c01b86, binary 88f2d20ea733742d48724ecbdc903271e18bcfcccc8682be596a676aef68e3ec. Lean commit is 293d5d0c0c3f3dded4688b3ccd6a33939ac5102b; fuel 131072 and timeout 60000. Its acceptance is a separate post-emission gate.

## Root workspace TypeScript 5 retirement

The root workspace is distinct from psc0. TypeScript 7.0 has no old programmatic compiler API, so changing version strings alone was insufficient. The implementation replaces the one API importer in packages/backend-ts/src/typescript-compiler.ts with an exact installed-7.0.2 CLI adapter. Microsoft primary reference: https://devblogs.microsoft.com/typescript/announcing-typescript-7-0/.

All 21 root/package TypeScript pins are now 7.0.2. Ten unsupported baseUrl fields were removed without changing paths or output layouts; existing rootDir/outDir preserve dist/src exports. Root/backend Node types are explicit at 22.15.3. Two remaining selfhost launchers require 7.0.2 before compilation and use --ignoreConfig.

### Root source commits and bounded corrections

| Source | Change and actual evidence |
| --- | --- |
| a02f03b97bb3385b66ad670dabf7f13d334fc79f | 40-file initial root migration. Run 37949490366/job 113884245962 passed lock resolution, clean TS7 install/profile and root build, then the new map-footer test required a trailing newline that the adapter already makes optional. |
| 3fce771a3607341ce0c9dfc1f1fa3974e2f0dbab | Committed exact npm lock and changed only that footer assertion to accept EOF/LF/CRLF after the same URI. Run 37950075083/job 113886266262 passed complete package tests and all 11 adapter obligations plus conformance build; the additional lean4export build exposed an existing inaccurate stdin type. |
| 5d3cbc82cb8759b909d1a957d6a22d542509d8c5 | Type-only ChildProcessByStdio<null,Readable,Readable> declaration matching the unchanged ignored-stdin/piped-output spawn. Run 37950522687/job 113887806499 passed all builds, package tests, 11 adapter obligations and package integration; final package-map check found a pre-existing source-language metadata mismatch. |
| 9d150afbec1feda8c97058aa56aa5ab92347d96d | Aligns the compiler map with its existing mixed-source manifest and paired files; replaces the stale Compiler API note; strengthens exact nonempty language matching across all 20 outer packages. Full root run 37951869293 passed all seven command phases and all eleven adapter obligations; no additional source correction is needed. |

No adapter implementation changed after the initial reviewed CLI replacement. The footer correction changes one test formatting assumption; the exporter correction changes types only; the map correction preserves actual paired-source inventory and every other boundary rule. No native bootstrap target is qualified by the root gate.

Before the latest root run, independent static review read all 178 TS files in the exact twelve source-shape scopes, all ten editor inputs, all 20 package manifests, the complete package tree and all remaining architecture obligations. No further violations were found: maximum TS 300 lines / 201 characters; editor modules 228 lines / 88 characters. This was source review, not a substitute for the actual gate.

### Adapter contract

compileTypeScript remains synchronous and preserves its result fields. It verifies installed package metadata and actual launcher version, creates an exclusive unique sibling source in the logical source directory, emits into a private temporary directory, selects root JS/declaration/map products, restores logical diagnostic/map names, and removes private files in finally. Original logical source and existing output products are not overwritten.

It supports ordinary .ts input names in an existing writable parent directory. The real project CLI creates that directory before calling it. Relative TS imports and package exports are covered. Original-basename self references, unsupported source kinds, malformed maps and basename-dependent emitted output are explicit refusals. This is not a general arbitrary virtual-filesystem compiler host. No TypeScript 5/6 API fallback is permitted.

Key current blobs: adapter 1f178560ba824e58538235e93d348a7c97ab54e9; contract test b57719346e08faec054bb1287fc1c36459d79cd7; root gate runner 1dc573166836765fc7b8d0fa4714b5d1d29ae609; workflow 348ab35eaf3210b5a96ac53c08d7c5b201c29c1e; exporter type correction b9b86b7f10584756fda519221e47895ce526038f.

### Exact root lock

package-lock.json is the actual 21,592-byte npm-generated file from the initial cloud run. SHA-256: 69c5e49b040ff3d45909e15cf1e2123af39fa223b00a7241b533c022a49e33e1. Git blob: 19fef24fac3018dcac4949b79a4d0dcdd5d6d0eb.

It was resolved with --package-lock-only --ignore-scripts before any installation, then installed with npm ci and rehashed. Every one of the 21 source/lock/profile manifest bindings was independently checked. The exact file has remained identical in subsequent runs. Do not fabricate, reserialize or invent registry metadata/integrity.

The root runner logs exact JSON file content in PS_ROOT_TS7_EVIDENCE_FILE or ordered MANIFEST/CHUNK records. Concatenate decoded content with no separators and verify actual UTF-8 byte count/SHA. The adapter's PS_ROOT_TYPESCRIPT7_CONTRACT is a compact stdout record, not a standalone receipt file. Preserve that distinction.

The successful root result has been independently authenticated and is retained as immutable blobs pending final repository paths. Failed attempts remain failed; their earlier completed phases do not imply whole-run qualification.

| Successful root proof | Exact identity |
| --- | --- |
| Evidence index blob | 87dc087ead86d551a6b2e48f0594dd858e7b1b83 |
| Complete primary log blob | f59f0590c714205f93826c9512c1c0c438a41418 |
| Primary log SHA-256 / UTF-8 bytes | 5836caa0146f2002bec6954ce285ab7789e7ac1758ede4da80248448cdc79e86 / 84,888 |
| Full API + exact manifest sources + inheritance proof blob | 45b848ea37dacd4f9aba554b8d90fd794c7cfdb6 |
| Complete authenticated report blob | 83977c047ba4a382d0512ec9294ba1bbcf30d29e |
| Original qualification.json blob | 31ec99a5260603659e38ad24c33028c510b46e93 |
| Original qualification SHA-256 / bytes | a6f2b2e31ca61a8249954d43849bb622d01b876db7f8046a67353ce82e9de39a / 3,485 |
| Original installed-profile.json blob | 68ab7c2309f8722988d71d05f05743693f794851 |
| Original installed TypeScript metadata blob | f4242a69df961fcaf5210ac08ace176ced18c6a4 |
| Original uploaded evidence-index.json blob | c77c051646afea76427cb175cb14f85c80b0a8cd |
| Artifact ID / size | 11626670229 / 13,228 bytes |
| Artifact archive SHA-256 | a424a5c9bacbc31caf51160c471266401d0d4c520b87bce7cb3100c60d552cf6 |

Final root paths: docs/selfhost-language/root-typescript7-qualification.json for the exact receipt; root-typescript7-evidence.json for provenance; evidence-logs/root-typescript7-qualification.log for the full log; and seed-evidence/9d150afbec1feda8c97058aa56aa5ab92347d96d/root-typescript7/ for other original files and API. projection_repair is preparing this final path-to-blob manifest and the root docs/TYPESCRIPT7.md status update without executable/ref changes.

## Exact remaining work and integration order

1. Re-read the live refs and the active F run. The root TS7 run and independent native cold recovery are already successful and authenticated. Do not resume an earlier failed source or launch duplicate runs.
2. Finish F: authenticate the complete compiler log, run and job identities; N1/C1/C2/C3 raw-source and four-product equality; original-IR checks before emission; full actual Core/IR ABI for all twelve workers; all 87 R/F behavior observations; bounded grammar/projection/generic/session evidence; exact single TS7 installed profile. Preserve strict/unrestricted flags as false.
3. Finish F's independent provider job: authenticate its exact file envelope and compact object, unchanged provider identity, and all eight required C2/C3 roles (compiler, raw Lean, raw PS, recursive-generic). Match each role to the actual generation admission hash. Provider acceptance is post-emission; cold native recovery is separate.
4. Retain the already-proven root run 37951869293 evidence at the stated repository paths and reconcile root docs/TYPESCRIPT7.md. Root independently checked all exact source/run/job/file/command/lock/profile/contract bindings. Preserve the three actual failed attempts and their precise corrections; no further root qualification is needed for docs-only retention.
5. Retain the already-proven native cold files at the paths above. Its exact receipt/log/API blobs are listed below.
6. Instantiate the ten-file F documentation template only after actual compiler/provider proof. Apply the disjoint TS7 retirement post-pass and update TYPESCRIPT7.md, qualification-evidence.json, worker-migration-candidate.json and this file. Preserve selected R, all historical hashes, all 226 deferred locators and the historical AI tail.
7. Prefer final documentation/evidence work on the root retirement branch, which already descends from fcd and includes both scopes. Once all required gates are proven and executable source remains exactly the qualified source per scope, fast-forward the F working branch and canonical implementation/TS7 branches to the combined descendant with fresh leases. Verify ancestry and file identities; do not discard either scope or force-push.
8. Report actual changed files, branch/commit/run identities, proofs, remaining finite language limits and daily iteration commands. Main stays unchanged. Stop optional testing after sufficient proof.

If a gate fails, retain its actual log/receipt and diagnose the whole demonstrated class before changing code. Do not reinterpret a failed phase as a pass, remove a check, or retry a long pipeline merely to collect information that can be reviewed from the source.

## Recoverable prepared artifacts and evidence

The in-memory functions store unexpectedly reset around 15:23 UTC. All committed source and Actions runs remained intact. Do not assume a prior store/load key still exists. Use this file, fresh GitHub reads and the immutable blobs below. Fetch a blob with the GitHub connector's fetch_blob(repository_full_name, blob_sha), or the GitHub git/blobs API; no local checkout is needed.

| Git blob | Purpose |
| --- | --- |
| c423053bd360ed4db193c450f52aec8fe9e24a1c | Initial 40-file guarded root TS7 migration bundle, exact old/new blobs |
| e712fce4a08e4bc9723a91523a2de54502f21957 | Root metadata correction, complete remaining-boundary static audit and authenticated attempt-3 failure facts |
| fe3478ead5638f8647e67a5ef2a2f2de4e2eb896 | Pure-data root evidence reader with separate failed-file extraction and strict passing qualification |
| 6f1278311cdaa160a0cb076d431c728a98ebcadf | Newly rebuilt pure-data F evidence toolkit factory: parseFWorkflowLog, reviewFCompilerEvidence, reviewFProviderEvidence; source reviewed but not yet used on completed F evidence at this checkpoint |
| 947971df08c812200f9f71138d6ce4a7c4741a0e | Guarded ten-file final F documentation template: 16 applied-source + 92 qualification operations |
| 697e9a1f4e635c446a237b1bb268955a003a04da | Pure-data F documentation instantiator; requires actual qualified F input, does no IO/execution |
| 9b719316fd4297bab7e73cfd8b1bdd7bf6999cd3 | Post-instantiation TS7 retirement pass: 19 guarded JSON operations + 5 backlog text replacements; protects seven immutable locator/audit regions |
| 310c41f7a9b4d7a4052d9ab3c5a81795bd606ab3 | Independently reviewed cold-native recovery retention manifest; suggested paths must be mapped to the final paths above |
| c495ddf6e7d5075e204e4b0c5957c8c0d3d6a24b | Exact successful native cold receipt |
| d5ae70f7459ad82ba2aa3a23043e374921fb2316 | Complete decoded native cold job log |
| fbe7b5b822e931f984c011076780baaeca07f89d | Exact completed native cold run API response |
| 4e8ce6d40000a47991f38ed0bd025ad6cabf36a1 | Exact completed native cold jobs API response |
| f22f733ac640308e605c320bf10bb3901929222d | Actual native cold artifact metadata serialization |

The ten F template bases are unchanged through root source 9d: selfhost-language README bbbf7a07c2b7be0731bf845f957457f9377a486b; IMPLEMENTATION 457792e29a18393434c86aef43a4ea0eeab4a024; MIGRATION 18bf1fb8317964cda2352bb7e98828863ccce6c1; SPEC d5e550809b60552050169bcc52c01175f4a33827; proposal.json f73489ab63ebd474276f2aac4aa7ef2298b833f3; migration-backlog.json 615b76512ef894fac42b94b730fd424c11338f14; MIGRATION_BACKLOG 7c1ad6a0dcf253bfd395866ad772a09fee88a642; CURRENT 90a482894c01111f62349b8455ca86756806c7be; psc0/README ef15e197cdcf10b9ed6d8cbc3028551f16090e89; PS_GRAMMAR_ADOPTION e3c072536d021f4172afb8736a716bd9c6255d0e. Re-read and guard their blobs before applying anything.

Root also prepared nine literal TS7 policy replacements across psc0/README and the selfhost-language README, CURRENT, IMPLEMENTATION, MIGRATION and PS_GRAMMAR_ADOPTION guides. Those in-memory strings were lost in the reset; reconstruct the narrowly scoped replacements from the actual current paragraphs. Replace current/future TS5 execution instructions with the proven TS7-only native route, and route historical comparisons to TYPESCRIPT7_CHECKPOINT.md. Do not rewrite old producer facts. Current TYPESCRIPT7.md blob is 7462e111a12b2f73adc8359469deec644d0dfc2f; its archived original guide is preserved separately.

The final F document instantiator needs exact template text; ten {path,blobSha,content} bases; parameters fQualifyingSourceRef, fRunId, fCompilerJobId, fProviderJobId, fModuleCount, fSourceClosureSha256, fCompilerSha256, fQualificationDocTarget, fQualificationReceiptSha256, fProviderDocTarget, fProviderReceiptSha256; seven actual evidence objects (compilerQualification, providerAcceptance, behaviorCorrespondence, publicTypeAndIrAbi, hostProofScriptPreparation, providerReceiptLogging, qualificationReceipts); and explicit authenticated qualificationEvidence. Run/job IDs in that input are strings. Never fill these with planned values.

Pure evidence readers inspect authenticated external results; they do not execute compiler code or create proof. Ordinary compact log JSON can be retained as a new document with its own hash, but cannot be labelled original artifact bytes. Native cold receipt reconstruction is exact because its complete logged object reserializes to the runner's separately recorded original file digest. Provider and root envelopes retain actual read-back file contents.

### Parallel owners at this checkpoint

- Root: integration, final docs, this committed checkpoint, and independent review of primary evidence.
- projection_repair: completed successful root run 37951869293 evidence authentication; preparing final root documentation and exact retained file/provenance paths, including the three failed attempts. No executable/ref changes or retries.
- grammar_adoption_audit: rebuilding and persisting a pure-data F evidence reader from actual fcd source contracts after the store reset; cannot invent missing records or F success.
- migration_inventory: completed independent adapter, root runner/evidence-reader, 178-file source-shape and ten-input editor reviews; now reviewing final F template and TS7 post-pass composition, plus precise worker source mapping and the nine guide retirement edits.

Agent state is not durable authority. If a new chat cannot access these agents, continue from the committed code, this file and the exact external evidence. Do not repeat completed static audits or successful cold recovery merely because the old chat's memory is unavailable.

## Daily development after this checkpoint closes

From psc0, the supported short cycle is:

    npm install
    npm run check:typescript-profile
    npm run dev:sh1
    PSC0_ITERATION_SHA256="$(node -p "require('./dist/sh1/N1/receipt.json').artifacts.javascriptSha256")"
    npm run iterate:sh1 -- --compiler dist/sh1/N1/index.js --compiler-sha256 "$PSC0_ITERATION_SHA256" --loop

These are developer commands, not permission to execute repository code locally in this cloud-only session. The resident loop accepts prepare/Enter, emit, reset and quit. It retains preparation state and invalidates the changed module and dependent suffix. Restart when the compiler changes. emit produces TypeScript; it does not replace fixed-point/provider qualification. Use full qualification for coherent semantic/toolchain/recovery checkpoints, not for every small edit.

Root development uses the committed TS7 lock with npm ci and the documented package commands in docs/TYPESCRIPT7.md. The active root API is the TS7 CLI adapter. Historical TS5/TS7 measurements remain historical; no whole-pipeline or worker speedup is claimed without a suitable measured comparison.

## Historical completed M6 and TypeScript 7 result

This section preserves the completed checkpoint before the active R/F continuation.
Its selected-seed, integration and next-step descriptions are historical; the
active status above is authoritative for this continuation.

The bounded portable runtime IR checker, same-IR checked emission and scoped-let
backend correction are qualified under TypeScript 5.8.3 at
`1b5fd12382c920944924c9d03e0851984293caa2`
([run 37906602597](https://github.com/dwijayuda/pskernel/actions/runs/37906602597)).
Current PSC0 TypeScript 7.0.2 integration is qualified at
`99786185f77edf952f11989d4c9bc44028f22f11`
([run 37910429506](https://github.com/dwijayuda/pskernel/actions/runs/37910429506)).
The second source retains the same portable M6 code. Both checkpoints have
separate compiler and selected-provider receipts.

Canonical integration uses a normal fast-forward of
`psc0/sh1-implementation-v1` to the qualified TS7 descendant and documentation.
The exact qualifying source remains the immutable reference above; a later
documentation commit does not claim a fresh compiler run.

The independently qualified M6 baseline at `1b5fd12382c920944924c9d03e0851984293caa2` records:

| Evidence | Observed result |
| --- | --- |
| Portable compiler source | 61 modules; 1,088,337 bytes |
| Native full original IR | 54,879 expressions; 707,753 visited steps; complete; accepted; zero findings |
| Native fixtures | Eight cases passed |
| N1/C1/C2/C3 runtime conformance | 59 observations per generation, including 29 observations across four let-scope cases |
| Generated checker refusals | 36 negative IR cases and five malformed/foreign carrier cases per generation; resource and direct type-operation cases also passed |
| Current C2/C3 full original IR | Complete; accepted; zero findings; same original IR checked before emission |
| Current C2/C3 products | Canonical surface source, normalized admissions, TS and JS agree; N1 TS/JS also agree |
| Independent selected provider | Three exact admission streams accepted after emission |

The generated C2/C3 summaries do not print their full expression or visited-step
counts. Those fields are not inferred from the native counts; their full reports
remain in `dist/sh1/C2/original-ir-inventory.json` and the corresponding C3 artifact path.

The native development gate's internal total was 144.586 seconds. The C1/C2/C3
generation totals were 1,145.486 / 1,187.825 / 1,199.391 seconds.
Across those three generations, preparation accounted for 60.17% of the recorded
total; `tscAndWrite` accounted for 30.655 seconds, or about 0.87%. The latter
includes evidence writes, hashing and identity work as well as TypeScript.
These are observed phase timings from one qualification run, not controlled benchmarks.

The compiler bundle preserves all 28 complete logged JSON receipts, including
their original provider-not-attempted fields. The separate later provider receipt
records `accepted: true` and `emissionWasGatedByThisCheck: false`.
Compiler qualification, bounded IR typing and exact-stream provider acceptance
are earned; strict SH/1 and profile activation remain false.

See [runtime-ir-checker-qualification.json](docs/selfhost-language/runtime-ir-checker-qualification.json),
[runtime-ir-checker-provider.json](docs/selfhost-language/runtime-ir-checker-provider.json) and
[runtime-ir-checker-execution.json](docs/selfhost-language/runtime-ir-checker-execution.json)
for complete receipts and the retained attempt history.

Current emission uses exact TypeScript 7.0.2. Historical S0/A recovery uses exact
5.8.3, including a byte-checked TypeScript replay when reusing authenticated A.
Frozen recovery receives and verifies its actual historical child launcher
before building. The root workspace still uses the old TypeScript programmatic
API and remains on 5.8.3. Lean 4.34.0 and Node 22.23.3 keep their pins.

The completed same-source comparison compiled the full emitted compiler with
TypeScript 5.8.3 in **9,281.561787 ms** and 7.0.2 in **2,866.119670 ms**.
That single sequential pair gives a **3.238× direct-CLI speed ratio** and
**69.12% less elapsed time**. It includes startup, checking and emission; it does
not measure the complete self-host pipeline. The input TS SHA-256 is
`f20c9132ae2f8adade08346b0457f6bb02b6e5145097116d2a827121304a8f70`.
See [TYPESCRIPT7.md](docs/selfhost-language/TYPESCRIPT7.md) and
[typescript7-qualification.json](docs/selfhost-language/typescript7-qualification.json)
for the exact measurement and scope.

A remains the selected authoring seed. Compiler qualification, bounded runtime
IR typing, exact provider acceptance and strict SH/1 are separate. Strict SH/1
and named-profile activation remain false. Kernel/provider implementation,
defeq/cache internals and metatheory are unchanged.

The execution histories retain all source-form and emission findings, without
rewriting earlier failures as passes:
[runtime-ir-checker-execution.json](docs/selfhost-language/runtime-ir-checker-execution.json),
[first complete native acceptance](docs/selfhost-language/runtime-ir-checker-first-native.json)
and [typescript7-execution.json](docs/selfhost-language/typescript7-execution.json).
The source-compatible callback/match/record-alias forms are documented in
[SPEC.md](docs/selfhost-language/SPEC.md). The general projection-normalizer
repair remains future work; no syntax exception or checker weakening was added.

## Current source and qualification checkpoints

The current qualified integration source is the TypeScript 7 M6 checkpoint
`99786185f77edf952f11989d4c9bc44028f22f11` above. The earlier recursive
generic-argument repair E,
`cf8fbd784944a98b1e390b709685ca54c2511827`, was independently qualified on
`psc0/sh1-generic-erasure-v1`: compiler and pinned-provider jobs passed on the
first execution of [run 37852341550](https://github.com/dwijayuda/pskernel/actions/runs/37852341550).
Its parent helper migration H,
`671685c3f0059574405a1e630dd965d421a26f05`, independently passed both jobs on
the first execution of [run 37851669475](https://github.com/dwijayuda/pskernel/actions/runs/37851669475).

The canonical integration branch is `psc0/sh1-implementation-v1`; integration
preserves each feature branch's source/qualification provenance and uses normal
fast-forwards. Documentation-only descendants preserve the exact qualified
executable sources.

| Checkpoint | Source commit | Result |
| --- | --- | --- |
| A: recursion capability and preparation/session implementation | `e91b9558d665879871b8bf0893915ae64b27c7fe` | Compiler-qualified and exact admissions accepted; remains the selected authoring seed |
| B: Foundation.List migration | `70d6010ddccbdd6b4939f2fb3c088bfe4e607de0` | Compiler-qualified and exact admissions accepted on its first migration execution |
| H: three compiler helpers | `671685c3f0059574405a1e630dd965d421a26f05` | Compiler-qualified and exact admissions accepted on its first execution |
| E: recursive generic-argument erasure | `cf8fbd784944a98b1e390b709685ca54c2511827` | Compiler-qualified and exact admissions accepted on its first execution |
| M6: bounded runtime IR checker and scoped-let correction | `1b5fd12382c920944924c9d03e0851984293caa2` | Qualified under TypeScript 5.8.3, with current IR typing and separate provider acceptance |
| Current TypeScript 7.0.2 integration | `99786185f77edf952f11989d4c9bc44028f22f11` | Same portable M6 source qualified under 7.0.2; historical recovery remains 5.8.3 |

Compiler qualification, Core-provider acceptance and strict runtime SH/1 remain
separate axes. Strict SH/1 is still false, and psconfig retains the existing PSC1
bootstrap lane. No named profile was activated by these changes.

## Completed implementation in this continuation

The helper migration H changes only `Elab/Term.lean` and
`Erasure/Definition.lean` inside the portable closure:

- `psExprApplyManyWorker` now takes its expression accumulator as an ordinary
  explicit parameter.
- `psExprAppViewAccWorker` now takes its argument accumulator as an ordinary
  explicit parameter.
- `psErasureAddUniqueStringWorker` now takes its changing candidate base as an
  ordinary explicit parameter while descending through Nat fuel.

All public worker/wrapper names, complete types, argument order and algorithms
are preserved. The unique-name helper retains its exact zero-fuel and collision
exhaustion suffixes. The three guards accept historical and qualified forms
while retaining wrapper, primitive and unrelated source/admission checks.

The correspondence gate compiles preserved/current raw helper slices with actual
Name/Level/Expr dependencies. It checks seven public types and 2,198 observations
per compiled slice, including typed partial applications. A separate 1,568-observation
check exercises actual exported helpers in each generated compiler. All of these
checks passed on the first compiler execution of both H and E.

The isolated E repair changes `Erasure/Basic.lean`, `Erasure/Definition.lean`
and `Erasure/Expr.lean`. `PsErasureCurrentDefinition` now retains a reversed
accumulator of the current declaration's generic arguments. Type binders record
their assigned Tn in order; runtime and erased proof binders preserve the context.
Recursive induction-hypothesis calls receive the restored declaration order.
The implementation neither captures unrelated local types nor whitelists helper
names.

The focused fixture checks exact original-IR argument order for one, two and
three generics, interleaved proposition/proof/runtime binders, and a monomorphic
control. It emits the same IR object whose calls were asserted. All N1/C1/C2/C3
executions passed 19 behavior observations; N1/C1 also passed native parity.
Kernel/provider implementation and metatheory were unchanged.

## H evidence before the erasure repair

H's compiler job `113565800146` passed on its first execution in
[run 37851669475](https://github.com/dwijayuda/pskernel/actions/runs/37851669475);
provider job `113583716467` also passed on that first execution.

H contains 56 raw modules / 991,563 Git blob bytes, a reduction of 327 bytes
from B. Raw source closure SHA256:
`03c493835b44507fbe692f065f953f9c8252a44edcdf7e62932c3608831d0903`.
C1/C2/C3 agree on canonical surface, ordered admissions, TypeScript and JavaScript.
N1's TypeScript/JavaScript also agree with the generated generations.
The generated JavaScript SHA256 is
`fb7708698c333c1985ae82c0eb5b061c8738f41feffc12f3fddccb1c74fc6855`.

All three full-source inventories complete with 244 expression-typing obligations
and 19 type-argument arity findings. E's isolated repair resolves the latter
category below. H recovered the pinned A seed from its verified cache.

The unchanged pinned provider accepted H's two deduplicated compiler/capability
admission streams after emission. Its preserved receipts are
[qualification](docs/selfhost-language/helper-migration-qualification.json),
[helper correspondence](docs/selfhost-language/helper-migration-correspondence.json),
[small compiler receipts](docs/selfhost-language/helper-migration-compiler-evidence.json)
and [provider acceptance](docs/selfhost-language/helper-migration-provider.json).
The provider identity and checked-emission boundary are the same as E below.

## Historical E evidence before the portable checker

Run 37852341550: compiler job `113568120771` and provider job
`113579690742` both succeeded on the first execution.

E contains 56 raw modules / 992,338 Git blob bytes. Raw source closure SHA256:
`d7866a3c8da745db5b0f6c7ce67381915f6265263615c13a243ec674c1ab13e2`.

C2 and C3 agree on canonical surface, ordered admissions, TypeScript and
JavaScript. Their generated JavaScript SHA256 is
`b6783f5d3ae25fe2da233da3a2c607445efa007a62bbde0275cfa6b8b8b04816`;
native-generated N1 has the same JavaScript bytes. C1's JavaScript is
`d3fd03481ce03d4d2f962f932d4987aff28a7dcf68a395467be2dc57f1d60a2c`.
Its difference is permitted by the C2-versus-C3 contract: the older Q produced
C1's IR, while the new C1 executable contains the repaired erasure used for C2.

The complete C2/C3 IR inventories have **zero type-argument arity findings** and
**244 call-expression typing obligations**, with no other recorded categories.
C1 retains the historical 19 type-argument arity findings in its Q-produced IR.
B's 244-plus-19 result and its empty generic erasure context are historical;
the new repair must not be listed as future work again. The remaining 244
records identify unfinished expression typing, not 244 proven runtime failures.

The unchanged pinned provider source is
`963030dc2d154008fccc82e7c8ed29331f138799`, with binary SHA256
`88f2d20ea733742d48724ecbdc903271e18bcfcccc8682be596a676aef68e3ec`.
It accepted three deduplicated streams: E compiler admissions, raw .lean/.ps
capabilities, and the focused generic-erasure fixture. Default fuel 131,072 and
timeout 60,000 ms were unchanged. Emission preceded this separate check;
`emissionWasGatedByThisCheck` remains false.

Exact qualification, correspondence, compiler and provider receipts are indexed
in [docs/selfhost-language/qualification-evidence.json](docs/selfhost-language/qualification-evidence.json).
E's preserved receipts include
[qualification](docs/selfhost-language/recursive-generic-erasure-qualification.json),
[C2 generic conformance](docs/selfhost-language/recursive-generic-erasure-conformance.json),
[small compiler receipts](docs/selfhost-language/recursive-generic-erasure-compiler-evidence.json)
and [provider acceptance](docs/selfhost-language/recursive-generic-erasure-provider.json).

## Seed, development workflow and next work

The selected authoring compiler Q remains A from
`e91b9558d665879871b8bf0893915ae64b27c7fe`, with JavaScript SHA256
`9d8a91e890c779c6b377b8a482ae3e997a1630b360eb8d6e7c022b3964510096`.
Do not silently promote E, M6 or the TS7 compiler as the seed, or claim the
historical S0 can consume the migrated source. Preserve the authenticated S0 -> A recovery route and A's
qualified seed cache/artifact identities.

Ordinary edits use `npm run dev:sh1`; `npm run iterate:sh1 -- ... --loop`
provides optional resident preparation reuse. Full runs also execute the bounded
native gate before expensive selected-Q generation. Source-family and semantic
milestones receive C1/C2/C3 plus exact provider checks, selected by
`[sh1-qualify]` or full manual dispatch. Independent checkpoint branches may
qualify in parallel. H and E passed their native, compiler and provider gates on their first
execution. M6 and TS7 preserve their separate attempt histories above.

H's bounded native gate took 39.951 seconds, and E's took 25.886 seconds.
Full C1/C2/C3 generation totals were 993.651/1,011.667/991.582 seconds for H and
607.562/606.556/632.401 seconds for E. These are recorded single-run scopes,
not a benchmark or a general speedup claim. The earlier 14.590-second
development result used a smaller bounded gate; warm resident preparation
measurements exclude source reads and optional emission.

The current TS7 native development gate recorded **106.462 seconds** internally
(`106461.999493 ms`), excluding the preceding `lake build`. Current C1/C2/C3
generation totals were 1,065.963 / 1,111.846 / 1,153.540 seconds. These
single-run stage totals are separate from the direct CLI comparison and do not
attribute all cross-run timing differences to TypeScript.

The qualified bounded M6 implementation is described in
[docs/selfhost-language/RUNTIME_IR_PLAN.md](docs/selfhost-language/RUNTIME_IR_PLAN.md).
Its portable expression checker covers the active current IR, with scoped
simultaneous type substitution, checked body/initializer annotations, exact
function grouping, global value/function distinction and explicit resource
failures. The current host inventory reports that portable checker.

The recommended next language slice is the bounded parameter-projection
normalizer repair in MIGRATION.md. Keep its implementation consumable by A and
qualify direct raw-source uses of the repaired form. Replace compatibility aliases
only after a separate explicit qualification and selection of a seed that accepts
that authored source.

Strict runtime enforcement additionally needs enabled primitive/layout/import
and scalar/bounds/text-position contracts, erasure/backend correspondence and
generated evidence for the enforced path. Neither zero type-arity findings nor
Core admission acceptance grants strict SH/1. Broader optional source conveniences
and .ps authority remain separately gated future work.

## Scope of this work

Implement the accepted self-host authoring and iteration plan from research commit
80d04e7ab0e9214ffecf093a6272865f0eaca096. Start with ordinary structural recursion
that changes nondependent value parameters, a pure preparation seam, and focused
generated-compiler qualification. Migrate source families only after capability
evidence passes.

M6 TS5 qualification branch: psc0/sh1-ir-checker-v1.
Current TS7 qualification branch: psc0/typescript-7-v1.
Qualified integration branch: psc0/sh1-implementation-v1.
Historical compiler baseline: 37f63c39d4a07189938046c64152bba25d789450.
The historical 55-module record remains immutable.

## Boundaries

- GitHub/cloud only; no local checkout, builds or tests.
- Kernel/provider implementation and metatheory belong to the native workstream.
- No profile activation or checked/native success claim without corresponding evidence.
- Keep current public compiler APIs and source signatures compatible.
- Solve shared semantic/architectural causes; do not weaken gates to obtain a pass.
- Use focused validation for a complete implementation slice, then current-source
  C2/C3 qualification at the milestone.

## Historical execution notes

The following notes retain their original execution-time status from the initial
implementation and first migration. Pending statements below are historical;
the current checkpoint and next work are stated above.

### Implemented architecture

- Recursion: canonical stable/major worker plus function-valued generalized state;
  preserve public binder kinds and argument order with a wrapper. Reject unsupported
  dependent telescopes and escaping self references.
- Provenance: inspect and enforce which nested matches may introduce decreasing children.
- Preparation: pure start/parsed-step/source-step/finish with both environment and
  ordered declaration accumulator. Session caches retain a valid exact-source prefix
  within one compiler import.
- Qualification: pinned historical seed; isolated TypeScript5.8.3 installation;
  branch-scoped cloud workflow; raw .lean/.ps capability examples; candidate execution;
  explicit C2/C3 canonical source/admission/TS/JS equality.
- Native integration coordination: observed branch psc0/native-core-selfhost-v1 at
  963030dc2d154008fccc82e7c8ed29331f138799. Named native workflow run37825822957,
  job113478295740 completed its actual full checked compiler fixedpoint successfully.
  Source hash ee6dd22f1b74b97113cc1a5e36aadad3cceecb2b152653f2c0dc26dd07aa22f7;
  TypeScript hash fb173a348d1555d1ff224b9977f6fee68591b79f781a6b292c2572648415b033.
  This is evidence for the historical native baseline, not acceptance of our new worker
  admissions. New admissions will be checked through a separate pinned provider checkout.

### Design clarification

Canonical surface source is the output of the existing syntax translator. Lowered
worker/core structure is represented by canonical admissions. The minimum checkpoint
does not add a second elaboration-aware source printer. Generated compilers must
consume raw authored forms, so the new lowering path is exercised directly.

### Initial implementation checkpoint (historical)

The first coherent implementation checkpoint contains portable recursion lowering,
preparation/session reuse, raw capability fixtures, C2/C3 qualification, diagnostic IR
inventory and a separate pinned native-provider acceptance job. Its commit requests
[sh1-qualify]; compiler and provider outcomes are pending cloud execution. After earned capability
qualification, migrate a bounded Foundation.List family using a pinned qualified seed.
The independent host IR report is diagnostic evidence; full strict runtime typing and
PSC0-SH/1 strict profile activation remain separate obligations.

### Review decisions before first execution

The child-provenance boundary also requires alpha-equality of the nested expected
result telescope and the whole worker result. This prevents a narrower induction
hypothesis from disguising missing state application. Fixtures include the rejection
and preservation of valid outer hypotheses. Session results are deeply immutable;
parsed cache limits are entry/source-text limits, not a hard compiler-heap bound.

### Setup checkpoint after first cloud attempt

Commit e67647ec4821d609188e6feb5a4de2380857767e started run37831018572.
Job113496067989 stopped in Lean Action configuration because the historical branch
had no lake-manifest.json; no semantic tests or compiler generation ran. Add the
correct dependency-free manifest and explicitly register Ps.Elab.Recursion in Lake.
Preserve the historical changed-argument refusal test by selecting BatchStable; the
enhanced path is covered by the generated raw-source capability corpus. Rerun the
same coherent qualification after these integration corrections.

### Native build checkpoint

Run37831457914 at e52c30313b1e9124864a304a41f3b4b4c8f74bd0 recovered and
cached S0 successfully (JavaScript SHA25674dcebb7b296d81924d92987e99146b5d1c5ff9fbe3d8076ca591952d2ef7f76).
The new recursion module, context and term changes compiled natively. The wrapper
used two Lean4.34 reserved words as local names (`meta` and `public`); rename them
to metaContext and publicDeclaration together. No semantic acceptance rule changed.
Candidate and full qualification remain pending; reuse the cached seed/build outputs.

### Development gate validation checkpoint

Run37831951758 at e91b9558d665879871b8bf0893915ae64b27c7fe has passed native
compilation and the generated C1 candidate, including raw capability and session
conformance. Current-source C2/C3 and subsequent provider decisions remain pending.
The implementation branch is held at that immutable revision while qualification runs.

A separate psc0/sh1-development-gate-v1 checkpoint adds host-only iteration/recovery
tooling for one bounded native-candidate validation. Portable compiler source remains
identical to e91b9558. No active selfhost-seed.json or Foundation source migration is
included. The temporary workflow branch filter and ref-scoped concurrency preserve
the running full qualification.

Ordinary pushes build the current native PSC frontend and use it to emit N1, then
execute raw capabilities, preparation sessions and a two-module resident CLI smoke.
This evidence is native-seeded development execution, not selected-seed ancestry or
a self-host fixed point. Full qualification retains selected-seed C1/C2/C3 and the
independent provider job. The frozen diagnostic ownership case shares the existing
session conformance boundary. Historical recovery verifies complete provenance and
all four seed products; a malformed cache reconstructs rather than becoming selected.

Once A is qualified, pin its actual source/toolchain/product identities, restore the
implementation workflow branch filter, and apply the staged Foundation.List migration
with its bounded behavior/public-type correspondence gate. Preserve A's historical
source recovery path before allowing B to use the new authoring capability.

### Bounded development result

Commit9641928bcf7d5394f46e19a31a8ae3fd096d44b5 passed run37834854232 on its
first execution. Job113509175107 took74seconds including a15second incremental
native build. The native-candidate receipt reports14590.443683milliseconds for
N1 generation and bounded capability/session/CLI checks. The raw closure has56
modules and SHA2567e18013c260de84b08d57e923aef184993b0c5fea4de4775a68288a8ff9e157a.
N1 JavaScript SHA2569d8a91e890c779c6b377b8a482ae3e997a1630b360eb8d6e7c022b3964510096.
These are single cached Linux x64 development measurements, not a fixed-point or
provider claim. The Foundation behavior matrix correctly skipped unchanged source.
See docs/selfhost-language/qualification-evidence.json for this durable checkpoint.

The next migration checkpoint is staged with additive dev:sh1/iterate:sh1 commands,
the same verified-seed Foundation comparison moved ahead of expensive C1 generation,
and a focused update of check-modular-preparation-source.mjs. That legacy guard
still assumed the old worker spelling and accidentally scanned two structures after
the new state type was added. Its replacement preserves prepared declarations-only
ownership and all unchanged admission/provider-session boundaries; generated session
correspondence already supplies the semantic evidence. Run it in B's early source
checks. Portable compiler source and selected seed remain at A until full evidence.
