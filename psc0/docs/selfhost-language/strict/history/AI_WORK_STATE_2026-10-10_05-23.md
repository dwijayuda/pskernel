# PSC0 AI work state — complete retained generations; evidence-only finish pending

Updated: 2026-10-10T05:23:40Z. Evidence times are UTC. This section supersedes all archived next-step instructions. The historical completed M6 and TypeScript result below is retained byte-for-byte.

## Active goal and authorization

The user authorized completing strict PSC0-SH/1, all 33 correspondence dispositions, all 27 stage obligations, and the merge. The practical language migration is already merged on main at **ed5d00aca0743bde583b45fe7756dd494ac3960f**. Continue on **psc0/strict-sh1-v1**. Do not repeat the practical migration or request permission again for the authorized finish and merge.

**Current status: C2 and C3 generation plus their seven conformance report kinds completed, but strict qualification is not yet complete.** The continuation failed in the evidence binder after both generations had finished. No qualification JSON, strict binder JSON, complete file inventory or provider acceptance was produced by that failed attempt. All active33/27 flags remain false/open until actual evidence completion and final disposition. Eight source-rule, composition and interface review packets are CLEAR on their declared domain; those are bounded reviewed arguments, not a machine-checked theorem for the whole compiler.

The enclosing commit publishes a reviewed one-line binder correction, an authenticated evidence-only finishing command/workflow, the actual failed attempt16 evidence, a scheduling-budget correction for future full runs, and this handoff. **It does not rebuild or relabel the four retained generations.** Its orchestration HEAD must be taken from the enclosing Git commit and actual Actions API; it cannot be written into its own content in advance.

Previous full checkpoint: [AI_WORK_STATE_2026-10-10_04-15.md](docs/selfhost-language/strict/history/AI_WORK_STATE_2026-10-10_04-15.md), blob **de60892fbce6fb0319fdde8e8af8432463b1aab4**, SHA256 **7218911da7c99ef6f6207cef8294856267a5c245c71e5adac1c407c751200642**, 71595 bytes. It contains the full earlier source proofs, file inventories and helper histories. Its statement that the continuation is running is obsolete. Its old continuation-only final assembly helpers must not be invoked against the new three-execution evidence model.

## User decisions and execution boundary

- Use **GitHub MCP and GitHub Actions only**. No local filesystem, shell, clone, browser, compiler or tests. Pure in-memory JSON, text, digest and metadata assembly is allowed.
- Root alone creates commits and moves refs. Review agents may create unattached blobs. Authenticate immutable blob reads, fresh branch heads, exact trees and expected SHA leases; never force-push.
- Use new-only **ps-0.9-r3** source grammar. Do not add backward-compatibility syntax.
- Active development and recovery use **TypeScript7.0.2**, **Node22.23.3**, and **Lean4.34.0@293d5d0c0c3f3dded4688b3ccd6a33939ac5102b**. A TypeScript5 producer string may remain only in immutable historical seed metadata; no TypeScript5 compiler installation or future development path is authorized or needed.
- **R remains selected; .lean remains authoritative.** The frontend is owned. Do not migrate source authority to .ps, promote a seed, redesign the language, add optional recursion depth/features or bulk-refactor unrelated code as part of this finish.
- No kernel/provider, definitional-equality, unification/cache algorithm or theory changes. Source placement changes in MetaUnify are already part of the reviewed work; do not inaccurately claim its file never changed.
- Preserve all failures and exact evidence provenance. A matched artifact tuple, passing fixtures or a reviewed proof packet alone does not complete strict qualification. Do not flip33/27 flags early.
- Avoid repeated generation/test/fix loops. The immediate finish reuses actual complete generation evidence and executes only the remaining evidence binding, finalization and independent provider gate.
- Progress commentary should remain frequent. Do not end with a status-only response while authorized work is still feasible.

## The exact compiled checkpoint and actual ownership

Compiled source is **1fa5559a72b293defc56ef7e7020cf82d4b44b79**, root **600c031e9235d20baa8bf074aba8c550509f50a4**, PSC0 tree **54b05a1c135ad5c7aff0902658465159a223757c**. All retained generations use this source, the64-module closure **46737f1e58a56cfa4cc0b575d30f531efe1dbe06ccf34002cc01e553febb1fb5**, and48-file recipe **a631bcaf914c0913f696eaf8a138a44449c46957f5a2d7736ec9cff8bcb63eba**.

| Evidence | Actual owner | Outcome |
|---|---|---|
| N1 and C1, native/name-index and original log-only gates | run38015134511, compiler114103608774, HEAD1fa5559a | Generation evidence complete; original job later cancelled at90-minute budget |
| Retained C2 and C3 and their seven report kinds each | run38021634599, compiler114123691566, orchestration HEAD43fa000c4adbc9d4754e20c213595c1449f00961, checkout1fa5559a | Generations complete; binder failed afterwards |
| Corrected strict binder, qualification JSON, complete catalog and provider acceptance | New evidence-completion run at the enclosing publication HEAD, actual IDs pending | Must be executed and authenticated; no result inferred |

The original run's provider114120597914 and continuation provider114136283916 were **skipped**. They must never be relabeled successful. New binder/qualification/provider results must identify the new evidence producer explicitly. Keep priorExecution and the old continuationInputs unchanged in metadata; use generationExecution for the actual failed C2/C3 producer and evidenceProducer/currentExecution for the new finish.

The canonical binder is a generation-recipe input. Its correction changes one of48 files for **future normal runs**, predicting recipe **18bfaff7d1d107a95f54733abcd624e5f43cb60dd25be827c764e488b82725fc** if everything else remains unchanged. That prediction did not generate the retained artifacts. The finish checks out1fa and leaves all48 original recipe files unchanged; it imports the corrected binder as an extra sibling script. Both facts must remain explicit.

## Actual attempt16 and the proven defect

[Continuation run38021634599](https://github.com/dwijayuda/pskernel/actions/runs/38021634599), workflow380237977, attempt1:
- compiler114123691566 started2026-10-10T03:44:45Z; fixed-point step8 ran03:45:32–04:56:36; job completed04:56:41 with **failure**.
- C2 completed04:02:20.7441118, generation time1007239.538882ms (about16m47s).
- C3 completed04:55:57.2340924, generation time3179019.831969ms (about52m59s).
- All seven per-generation conformance report kinds completed; the final C3 generic marker was emitted04:56:36.2332968.
- Evidence collector step9 was skipped; upload step10 succeeded. Provider114136283916 was skipped.
- Failure was AssertionError ERR_ASSERTION deepStrictEqual at sh1-strict-evidence.mjs:969, called from bindStrictQualificationEvidence:1740 and sh1-qualify.mjs:1254. No qualification was completed.

The original code extracted15 passing native IR fixture names with line.slice(pass), where pass is the string 'PSC0_SH1_IR_NATIVE_PASS: '. JavaScript converts that nonnumeric string to0, retaining the prefix. The producer's15 actual names exactly match the expected names after the fixed prefix is removed. The reviewed correction is exactly **line.slice(pass.length)** (+7 bytes). All15 count, order, uniqueness and content assertions, failure-marker refusal, summary binding, policies, digests and remaining checks stay intact. Independent source review covered all26 non-test sh1 scripts and the native Lean producer; no other same-form marker extraction defect was found.

Original binder: blob **b0b080eea2c353640f12d744e599737d71f9c4f6**, SHA256 **bd18cbb77c80fb57038b7d270e468c5b029164095dad958a84c52d113d67b049**, 91970 bytes.
Corrected canonical binder: blob **7700fef35acd06789b94f72078869fdef489214f**, SHA256 **829c7c8c70ce3388e6a8e8044ee07b5c65649546d1556a62d599a552fdcdb606**, 91977 bytes.
Repair review packet: **7c7ae4343cb94989df72b284dc9bd67c76794872**, SHA256 **65de6d37b9c4b75a1dc40999cf7ada6f2be59dfc0c1d23d63edef23b33a62b39**, 33943 bytes.

### Immutable attempt16 retained evidence

All seven files are attached under docs/selfhost-language/strict/attempts/43fa000c4adbc9d4754e20c213595c1449f00961/. Root independently authenticated every retained blob and the actual failure log.

| File | Git blob | SHA256 | Bytes |
|---|---|---|---:|
| qualification-failure.json | 4a0c37ce78e74217b340ff2ce30973ed573db1d7 | 1ab6c8bbf6f55cbd0ab8213bcf315493b220564d911741c663c46ce5692d1725 |43125|
| job.log | 6747dc056c2642f069cc1c45c37f9dea492e0b50 | 1ee74d4316074988052bb6e1e86f14d6ede117c03af8e46a3f469c46e6aa3548 |875228|
| markers.compact.json | a8b515f0be02a944054aec2446e54d2623e5dd63 | 5465a52a4b21b81e074ecdec0c2c3bc54904dada3072dec65529c275b14d6657 |914322|
| continuation-inputs.json | 8731e55592d0bcb57b977c4cc98fcfe91a64b7a9 | de17c0d640e014a006783c8b34b948f5d0ca8ddd53d9bbe956feab5ee8c07638 |161276|
| c2-receipt.json | 5b234f02309d91ce30f12b8eb0e1a85d4c719142 | 5da7545d89d7b28a4f296cbd1bd3b154aef5bac38af143caa836deb5c61f5a02 |166707|
| c3-receipt.json | 8615d1bf2b32190c94858380096b2ae3fa01195a | eaf6c772de3d9f27b4b1a42412746165b22be0c5cf431944827c95af7d8050d1 |166709|
| run-metadata.json | 227e846d233c501a14600f0ebbe63f0118331273 | 0039ae74b0f23a29dd216f6b9f77328cad718e8c50ea837e7a806f73c743d477 |94892|

Retained archive: artifact11659939542, name psc0-sh1-continuation-ts7.0.2-38021634599,11739089 bytes, API/upload-log SHA256 **599fd5160f132d0795246bc102f8b306ae3bd8d42238201cef2d3e69dbef6f80**, upload reported444 files. It expires2026-11-09T04:56:36Z. Its raw bytes and actual complete444-file inventory are to be authenticated by the new workflow, not assumed already checked. It contains the original authenticated predecessor ZIP, SHA256 **6ee7b3da60346bec004665d9bb2276ceb680a1a3d882d0aeb397398a9e1c1812**,5147944 bytes,344 files. The old continuation imported277 files and omitted67 as recorded by8731. The new import preserves every one of those277 files.

Actual C2 and C3 have identical four products:
- PS:240a3e7072441f14a9ad7070e5c3b8306b42d97ef5932be59f2c458d1816a98e
- Admissions:e77c40ccd38fc3ea6a2d3342732f23b54665d066aeeda38533d04ff54aeeb020
- TS:595cd338505f7012b8f0a813a78a1ecbafe863e6ea715b9861db35333d5a254c
- JS:6cddc3c34c38f1524ef9a355c46b0eb17949c45c54fd59367ea370c1af861ab3

The attempts ledger appends actual failure16 while preserving original15 values exactly. First15 compact-array SHA256 is **561074de6df43b4550bc848f8f1c45d714692205f820179a3cb718f8cbee81af**; all16 compact-array SHA256 is **557a694fb4e41826e9b11a6ca69b7e8131aec91090436ff8262fa0b70552c8a2**. Attempt16 compact value SHA256 is **a806cc796aac0f7d62e4c131754595eeb1d07d36c5c557851fb957b45b66c399**. The new finish will be attempt17. Never overwrite attempt16 with a success.

## Evidence-only finishing implementation

New scripts/sh1-finish-evidence.mjs: blob **793adba3bc690bbef566e922c9efb3457d372d87**, SHA256 **804f4e67d9c9e4165cdbeec01dd3a2c7a5635f08e3d95ab9f88f75054a79316d**,38509 bytes,649 lines.
Design/source packet: **1d5a535c27171d6b9a6bc5c54e33560d31c83d2f**, SHA256 **e496babd155a981e5d23f26ed3b796f7df274acab79c13a8386033a4e82d8c89**,33715 bytes.
New workflow .github/workflows/psc0-sh1-finish-evidence.yml: blob **3bba73b4c6f56e616e3c51194030896e291ede4a**, SHA256 **68cb5484b0a817209dc80d26c16248d9771ac8f23ded28e558d376dc62273388**,55773 bytes.
Original qualifier stays blob **e2c55f900b0ba4fe29cdc7e2981160a49ef4d61d**, SHA256 **707fedd63f01999293cf68b39f85ea6526c31216e84c2090d6ff1b8edf6fecdb**,73618 bytes.

Root verified18 reused sections byte-for-byte against the original qualifier: eight helpers, original preflight, seven read-only generation assertion groups, final binder/qualification/seed-retention section, and final fixed-point marker. The original remaining assertions and qualification construction are preserved. The finisher never invokes buildGeneration, compiler APIs, conformance runs or resource-policy rewriting. selectedAuthoringSeed reads and authenticates metadata/products; retaining promotable products is not a selected-seed promotion.

The workflow:
1. Checks out immutable1fa at the exact original Actions source root; installs pinned Node/Lean.
2. Authenticates both historical runs/jobs/outcomes and archives; checks the original277 inputs, actual four receipts/products, completed16 ordered C2/C3 generation/gate log markers and all48 recipe sources.
3. Restores444 retained files safely with unique paths and exact raw digests; retains the current ZIP and source generation log as two additional imported files. The finisher must see at least446 authenticated envelopes.
4. Fetches the reviewed finisher and corrected canonical binder from the same actual orchestration HEAD. Installs them into extra sidecar paths scripts/sh1-finish-evidence.mjs and scripts/sh1-strict-evidence-finish.mjs. The original canonical1fa binder remains unchanged inside that checkout.
5. Installs/verifies TypeScript7 only in new evidence-finish profile directories so old profiles remain intact.
6. Runs only the corrected binder and the original final qualification construction. Checks every imported input before and after, refuses to overwrite prior qualification/binder/seed/completion outputs, and emits a separate evidence-completion.json with exact generation/execution ownership and output envelopes.
7. Collects the original135-file compiler catalog and24 returned JSON values, plus finish inputs/inventory/completion and profile metadata. The collector runs after authenticated inputs even when finishing fails; partial evidence is explicitly incomplete and cannot qualify.
8. Runs the unchanged independent provider gate only when finishing succeeds and the catalog is complete. Its artifact root is qualification-artifacts/dist/sh1. No provider acceptance is inferred from artifact equality or declarations alone.

Finisher invocation: node scripts/sh1-finish-evidence.mjs --inputs dist/sh1-evidence-finish-inputs/inputs.json --inputs-sha256 ACTUAL_RAW_INPUTS_HASH --out dist/sh1.
Compiler finish artifact: psc0-sh1-evidence-finish-ts7.0.2-RUN_ID. Provider artifact: psc0-sh1-evidence-finish-kernel-ts7.0.2-RUN_ID.
Current inventory: dist/sh1-evidence-finish-inputs/evidence-inventory.json.
Output completion companion: dist/sh1/evidence-completion.json.
Markers: PSC0_SH1_EVIDENCE_FINISH_INPUTS, PSC0_SH1_EVIDENCE_COMPLETION, PSC0_SH1_FIXED_POINT, PSC0_SH1_EVIDENCE_FINISH_INVENTORY, PSC0_SH1_RETURNED_JSON; provider uses PSC0_SH1_PROVIDER_ADMISSIONS and its raw-file envelope marker.

The current finish and provider budgets are45 minutes each, not ETAs. Future ordinary full compiler qualification budget changes from90 to180 minutes because the observed earlier sequence plus actual53-minute C3 exceeds90. This does not request another full generation now. Do not add [sh1-qualify] to this commit message. Ordinary script/workflow path triggers may run the standard native-only gate; that is distinct from repeating C2/C3.

Independent workflow review verified archive/API/path authentication, exact expected constants,135 ordered catalog paths,446-envelope contract, same-HEAD producer binding, preserved imported profiles and unchanged provider block apart from artifact names. It corrected one failure-only diagnostic label: retained N1 raw source evidence is compact JSON+LF, so serialization labels now require exact raw equality and unrecognized formatting is retained verbatim. There is no execution claimed by source review.

## Final disposition assembly — prepare now, execute only on actual finish/provider success

Immutable proof/source catalog remains unchanged:
- disposition/source map697c94b2722a6191537b714f71f629713637b30a; SHA256474236ad91ccec5a0b0f612d4bee74accd499329a08a93e1c743bf11923a6c07.
- original33 active row SHA25639e543c14cef2a14b44ebee7480b179197648c5096c45138152bdb74d3009a55; prepared33 row SHA256aa3ba3f1e47f0f5ee08cc368fb3e16a0d1cb8291523745b70ad5a5439d52a72c.
- original27 active row SHA2569bab4ee9cdf1dc7305402ebe09d3b1e0375d0992227ebae4999e79820922eea5.
-151/92 source patch guards,33 source plans,72 available entries,37 limits,313 runtime references,95 static catalog references and59 dependencies stay exact.
- effective25-group static projection SHA256d00c507b197bb4c573f77d7ec9d2f55c7aed0d5c275f588ec42dcd49e73c2eee; original static fields and source hashes stay intact.
- Existing strict-binder group keeps the original recipe-bound source record as the reviewed base, with separate currentEvidenceProducer pointers/hashes for the exact repaired producer. Do not falsify the old source blob to make an actual producer fit.
- SPEC normative suffix37395 bytes, SHA256a72c480414486f9f8af25a845265f1e0ffb34d4bcbf855f7455d1ce85bb5fa26, starts '## 1. One language, explicit capabilities'. Only completion status/ownership prose may change.

The previous helper record docs/selfhost-language/strict/reviewed-candidates/continuation-assembly-tools.json, blob2143d746f59ee49e8c2d2d7e4d815dae6cd62814, SHA2561d353a38426de9ce4b191c15545e3885104ae0404c18647dc25e7e14472adcbc, contains all eight pure-data helper sources and old amendments. It is historical input for the new guarded adaptation, **not a runnable current success assembler**.

Shared new execution pending object: unattached blob **2b53fed7fd1429585885bbd555dbc6a59eca4fde**, SHA256 **b5a2f5815065b8acfdc321d88a33d55c337d3d09c5328cf794ab9f2be3c8bd84**,31008 bytes. Agents are preparing explicit guarded overlays of old fb80c0d509affd14637cca15a78c51366b6148df correspondence and58d6aa5a3e59edbf7f926d10315d59d699404a8e stage metadata. Current IDs/HEAD/workflow/tree/status slots remain pending until actual publication and execution. Row24's execution ownership wording needs the new three-execution model; source arguments and all other row semantics remain protected.

New actual evidence argument names are evidenceFinishInputs/evidenceFinishInputsValue, evidenceInventory/evidenceInventoryValue, evidenceCompletion/evidenceCompletionValue, plus existing qualification/strictBinder/provider and resolveReceiptGroupIds. Pin required archive fields; retain all additional authenticated metadata unchanged rather than treating it as invented evidence. Do not assume a raw JSON serialization without checking bytes.

Required final dependency order, with one fixed final timestamp:
1. Authenticate actual finish inputs, inventory, completion, all catalog files/selectors, raw qualification/binder JSON, current run/jobs/outcomes and provider acceptance. Preserve the separate original/log-only and generation owners.
2. Bind136 files (135 compiler plus provider),223 selectors and25 groups, including eight declared empty boundaries, with raw evidence envelopes and producer provenance.
3. Finalize and store/read back the release record first, to avoid a ledger/reference digest cycle.
4. Assemble final33 correspondence rows; run root active-summary helper in correspondence-only mode with obligations:null and the fixed timestamp; store/read back the complete final33 including its top summary.
5. Assemble final27 obligations and bounded SPEC status using that exact final33. Pass the projected release before catalog binding where required; do not substitute the full catalog draft into guards for its earlier source.
6. Apply full active summaries with the same timestamp and verify final33 bytes did not change. Append actual attempt17 and preserve all first16 compact values.
7. Update CURRENT, IMPLEMENTATION, PLAN, README, runtime and migration completion prose. Keep .lean/R/new-only/TS7 and all general preservation limits explicit. Old STATUS.md's historical TS5 baseline is not an active development requirement.
8. Commit final evidence/ledgers/docs and a resumable AI work state. Create the strict PR, allow required ordinary PR CI, refresh base/head and merge with expected_head_sha. Verify main contains the actual authorized merge. PR84 is unrelated/divergent; leave it alone.

The active qualified result must still state generalPreservationProven:false and no whole-compiler formal theorem. Source arguments apply only to declared owned finite canonical data, primitive computability and successful allocation, with precise callback/major-once/telescope premises. Do not use same-index transitivity, alias a root telescope with a descendant, or claim unobserved atomic-worker progress. Bounded strict discharge is not unrestricted PSC1 support.

## Immediate resume checklist

First read the enclosing branch HEAD and actual Actions run list. If the new finish has already started, observe it; do not dispatch a duplicate. If terminal, retrieve each job log once, retain exact raw envelopes and metadata, and complete the final assembly only on actual success. Prior log6747 is already retained and needs no fresh Actions-log retrieval. If the finish fails, preserve the actual failure and available diagnostic JSON; identify the concrete evidence invariant before changing anything. Do not automatically rerun C2/C3 or loosen policies.

Before this publication the strict HEAD was7453e27ee4da58563976347e21df06dadbcd6ac1, rootb07163f835d2b9a207e11a151574e96145b9665e, PSC0 tree6df584d5fd9a2c42cfdc29ca8cb122b24c21d249. Main last verifieded5d00aca0743bde583b45fe7756dd494ac3960f. The new HEAD/root/tree must be read from GitHub after the ref update. All evidence-only code/workflow candidates are independently readable blobs and become branch paths only through the enclosing commit.

After strict completion, use the existing development loop rather than whole-compiler qualification for every edit:
- npm run dev:sh1 builds the bounded native tools and native candidate.
- npm run iterate:sh1 uses an explicitly pinned resident compiler (--compiler and --compiler-sha256) for one-shot or loop iteration, rereads the closure and invalidates changed suffixes.
- npm run check:typescript-profile checks the active TS7 profile.
These are development checks; generic loop output is not automatic provider acceptance or strict release qualification. No speedup percentage has been measured. Full qualification belongs at promotion/release milestones.

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
