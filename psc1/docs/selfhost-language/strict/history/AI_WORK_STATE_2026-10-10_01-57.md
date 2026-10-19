# PSC0 AI work state — reviewed host observations awaiting exact strict qualification

Updated: 2026-10-10T01:55:27.602Z. Evidence times are UTC. This active section supersedes the archived checkpoint instructions. The historical M6/TypeScript result below is retained byte-for-byte.

## Active goal and authorization

The user authorized completing strict PSC0-SH/1, explicit correspondence/stage disposition, and merge. The practical migration is already merged on main at **ed5d00aca0743bde583b45fe7756dd494ac3960f** (2026-10-09 16:30:26 UTC). Continue on **psc0/strict-sh1-v1**; do not repeat the practical merge. No additional confirmation is required for this authorized work.

The enclosing checkpoint is based on **138fe57a6adeddfe875f1fbf4cc3a7de6e406a91**, root **c7903f7b30b45f08f7c311869681b4ca1a9908c9**, PSC0 tree **3cb88a6ee17b429cfde8215819fb789c3c2910ca**. Discover the enclosing commit and its actual Actions run before continuing. This checkpoint changes **two host scripts and one workflow**, plus status/evidence documentation. It changes no production Lean source or test fixture.

**Strict qualification is still pending. All 33 correspondence rows and 27 stage obligations remain open/false.** Eight general source-rule/composition/interface review packets are CLEAR on their declared domain, with independent review. That review is not a machine-checked compiler preservation theorem and does not substitute for the missing exact qualification.

The complete previous AI state is archived as [AI_WORK_STATE_2026-10-10_00-51.md](docs/selfhost-language/strict/history/AI_WORK_STATE_2026-10-10_00-51.md), blob **fb15d09b223f22c47fd3c3e80ccdd5300488e1c5**, SHA256 **44d8aea6eff71bd58a759debd98dcb36292264ee3945966c221a6097351ab058**, 78050 bytes. Consult it only for historical detail; do not restart its completed diagnostic or apply its old next-step instructions.

## User decisions and execution boundary

- Use **GitHub MCP and GitHub Actions only**. No local filesystem, shell, clone, browser, compiler or tests. Pure in-memory text/JSON/hash analysis is allowed.
- Root alone creates commits and updates refs. Agents may review immutable files and create unattached blobs. Use fresh exact heads/base blobs, expected_sha, and force:false.
- Use **new-only ps-0.9-r3**, bounded PSC0-SH/1. Do not add a legacy grammar mode. The historical R host-observation schema below does not admit legacy source syntax.
- Use **TypeScript 7.0.2 only** for current PSC0 development and selected-R recovery; Node **22.23.3**, Lean **4.34.0@293d5d0c0c3f3dded4688b3ccd6a33939ac5102b**.
- **R remains selected; .lean remains authoritative**, through the owned source front end. Do not promote a seed or migrate all source authority to .ps.
- Do not change kernel/provider, definitional equality, unification/cache algorithms or theory.
- Finish the existing language scope. Avoid a bulk refactor, language extensions, deeper recursion, optional benchmarks, repeated broad tests, or an invented unrestricted-PSC1 claim.
- Preserve original narrow receipt claims and immutable historical evidence. Finite tests are not a general proof.
- Send meaningful progress updates at least every 60 seconds during ongoing work. Complete the authorized work rather than stopping after a plan or status update.

## Last actual execution: attempt 14 built N1 and C1

[Run 38011068208](https://github.com/dwijayuda/pskernel/actions/runs/38011068208), attempt 1, exact source **138fe57a6adeddfe875f1fbf4cc3a7de6e406a91**, compiler job **114090942895**, is terminal failure. Workflow id **378853677**.

N1 development step24 passed from 00:56:23 to 01:01:48 UTC. **C1 generation completed** at 01:22:01.5350912 UTC. C1 then passed strict source, target, runtime, original-IR checker fixtures, helper runtime, generic erasure and capabilities before the post-C1 migration-report equality assertion failed at 01:22:28.0070824 UTC in sh1-qualify.mjs:1115:10:

```text
PSC0_SH1_MIGRATION_WORKER_REFERENCE_CORRESPONDENCE
```

Do not describe this as a C1 construction failure. C1 iteration was positioned after the assertion and did not run. **C2, C3, fixed point, strict evidence binder and provider were not run**. Provider job **114096798112** skipped. Cold run **38011068114** skipped as intended.

Full native source passed **64 modules, 1708 source declarations, 2571 Core declarations, 50 normalizations**, 64911 original-IR expressions, 829139 visited steps, zero findings, complete traversal, same original IR checked before emission. The count50 is from this actual run, not inherited from attempt13.

| Actual product or identity | SHA256 |
| --- | --- |
| Source closure | 46737f1e58a56cfa4cc0b575d30f531efe1dbe06ccf34002cc01e553febb1fb5 |
| Attempt14 48-file recipe | b768d8285df2cfa015e11f014116d1fe5fbdbb6a1b0b514f7fdf9522e0a183e1 |
| N1 JavaScript | 6cddc3c34c38f1524ef9a355c46b0eb17949c45c54fd59367ea370c1af861ab3 |
| N1 TypeScript | 595cd338505f7012b8f0a813a78a1ecbafe863e6ea715b9861db35333d5a254c |
| C1 JavaScript | 91f69e62d33bb5f670c5e9a56479280f97ebf15a60d2d9e6155ecb8ec33d49d5 |
| C1 TypeScript | 1c9ece3424bdb7c173c805450df10e7ec4fb1e1bc46945abdb6bef04ea4d0eba |
| C1 canonical PS | 240a3e7072441f14a9ad7070e5c3b8306b42d97ef5932be59f2c458d1816a98e |
| C1 admissions | 24b90a6cb748b9deb4f0340760e9ca50b358013dcf9d8be16e1143712465db52 |

C1 generation took 1202664.468491 ms, including preparation661103 ms, admissions113865 ms, canonical serialization46190 ms, emission378334 ms and TypeScript/write3172 ms. These are one workload's measurements, not a speedup claim.

### Complete comparison and reviewed correction

The complete **87-case** N1 and C1 workerMigration reports are JSON-byte-identical. They contain51 F1 cases and36 F2 cases. R differs at exactly four recursive JSON locations: two newly added empty entry-index fields and the two resulting hashes.

The two semantic-data differences are at F2 observations23 and27, cases **structures-empty-reverse-accumulator** and **inductives-empty-reverse-accumulator**. Current observations have scope.declarationNames.entries equal to **{tag:"empty"}**; R has no entries field. Current F2 hash is f5068cd7663430e8cbc7285ac58ed89573a077c3e9f13c0703cee5c191aeefb2; R's is8ff7547b87a96a8d2f7cc964e08b2b050fc3344b4b2309f66fac0566e8247d59. Aggregate current hash is a9bc881f234a1f91c2bca506f65339efb4a2049100e21368cbd1424f48b745d8; R's is697616ab48daf77a44b90ce20085432593ddce9a06fdad124a5a898ece3621be.

**entries is semantic function-entry metadata, not a cache to discard.** Current Basic.lean0132390f1ddb3133c9c14737b558e9b55bee33c9 adds PsErasureEntryInfo (binder kinds, runtime arity, type arity) and an entries field to PsErasureDeclarationNames. Populated metadata is consumed by declaration call grouping. R Basic is c41474cdbd008999368dfaf368be988e9982042b.

The general invariant is structural: psErasureDeclarationNameIndex(nil) initializes entries.empty; its cons branch retains the tail's entries. Therefore any finite names-only input produces an empty entries index. psErasureScopeEmpty uses that builder. These two fixtures start from it, adjust unrelated local fields, and invoke workers with nil pending declarations; both workers return the input scope directly. Exact same-generation equality against seededScope remains in place.

The three reviewed executable changes are:

| Path | Current blob | SHA256 |
| --- | --- | --- |
| scripts/sh1-migration-worker-conformance.mjs | d08d8c622f68314db32ef38d03539a8130abf3f6 | 7c34c498b505158f45dbe5f11f367038e9dd03cb297d2b83dea7c79b13e05472 |
| scripts/sh1-qualify.mjs | e2c55f900b0ba4fe29cdc7e2981160a49ef4d61d | 707fedd63f01999293cf68b39f85ea6526c31216e84c2090d6ff1b8edf6fecdb |
| ../.github/workflows/psc0-sh1.yml | e43d6f274585405e6c88606f192c0dc6e6b49f70 | 2bed091157fce89dea162719a4fe0d7d23deb4be90910aae344f7cb29d405cd5 |

The shared unprepared-scope snapshot defaults to **entry-metadata/1**, requiring exactly the current four name-index fields and canonical empty entries. The explicit **selected-r-names-only/1** option requires exactly the historical three fields and adds the proven-empty field only to a fresh plain observation. Only the qualifier's authenticated selected-R reference and the workflow's authenticated R preflight opt in. Missing current metadata, nonempty or malformed entries, and unknown fields refuse; there is no automatic legacy detection. All87 cases, order, live compiler values, current fields and original same-generation assertions remain.

The workflow compares the already produced N1 capabilities report with the authenticated R report **after N1 and before C1**. It binds GITHUB_SHA, selected-R source/compiler/identity and N1 receipt/compiler identity. This is a data comparison with zero added compiler executions or cases. The original post-C1 comparison stays.

[Main correction review](docs/selfhost-language/strict/reviewed-candidates/worker-migration-observation-schema-repair.json): **bec69f2d37ae68e7b8ff93fb4fd7fd2f7187dc19**, SHA256 **7604f87bf95b202663619d47efedb9114bbf91873534e8725bcca5409c601244**. [Independent review](docs/selfhost-language/strict/reviewed-candidates/migration-worker-metadata-independent-review.json): **5080fe9c78e0a560c143ad18ea5f13b4721c7111**, SHA256 **98614a819fee257bfd8546d06f053017d2f289aad8b4ed0f66e11cf747991f33**. The complete audit covers51 host scripts and17 workflows,68 files/971542 bytes. All12 exact text guards reconstruct forward and reverse. Pure replay of all retained reports gives identical projected report SHA256 **2850f574fee1141fe3e96eee88be8010179e46108a23677d568e1fff701071c8** (51437 bytes), without executing repository code.

The production closure is unchanged. The predicted new48-file recipe is **a631bcaf914c0913f696eaf8a138a44449c46957f5a2d7736ec9cff8bcb63eba**: exactly the two host file hashes change. The workflow has its separate new binding. **Actual new-recipe qualification is still required**. Do not relabel attempt14 receipts, resume across a recipe mismatch, or claim that the pure replay is full qualification.

## Immediate continuation sequence

1. Read the enclosing commit and exact branch head through GitHub MCP. Find the full workflow by Actions run collection with its exact head_sha; do not rely on a PR-filtered convenience run list. The commit marker is **[sh1-qualify]**. Record the new run/job IDs and actual source/recipe hashes.
2. Monitor the new full execution: native compilation/regressions/source/import checks, authenticated R preflight, N1, new early report comparison, C1, C2, C3, four-product fixed point/native parity, strict evidence binder, then independent provider. The new workflow step shifts the later step numbers: inspect step names instead of assuming old25/26.
3. Do not launch duplicate native-only, diagnostic, cold-recovery or artifact-inspection workflows. If terminal failure occurs, fetch the complete relevant job log once, retain it and exact marker payloads, and locate the owning source/host rule. Review the class correction before one further full run; do not keep editing fixtures to pass.
4. While the full run executes, refresh only the source/host/workflow/recipe metadata overlays for the pending final33/27 assembly. Production source and frozen general arguments are unchanged by this correction; do not reopen settled proof families without a concrete new reason.
5. Only after actual complete compiler and provider PASS, build **strict/release-qualification.json** from exact evidence, then explicitly finalize33 correspondence rows and27 stage rows, update SPEC status/activation and documentation. Preserve original produced receipt flags.
6. Make the final documentation/evidence descendant with executable source closure and48-file recipe unchanged from the qualifying commit. Open/review the strict PR against current main; PR84 is divergent and must be left alone. Use expected-head guarded merge with merge_method:merge, then verify main, merged head and resulting files. The user already authorized this merge.

## Final disposition preparation, still conditional

The following reviewed drafts are preserved for reuse. Their **138fe/run38011068208 execution expectation is historical and failed**. Refresh exact host/workflow/recipe/current-run metadata from the new successful run before any final application. They do not close rows.

| Packet | Blob | Purpose |
| --- | --- | --- |
| Final row map | 697c94b2722a6191537b714f71f629713637b30a |33 correspondence +27 stage mappings |
| Map review manifest | 419564764abc492816833a643af40b027b0fd897 | Frozen map/review identities |
| Independent correspondence review | 20f0116df23d4304e3b7e8f9da5ff39599eaf037 |33 exact row reviews |
| Independent stage review | f6cc608044094aebe90609cb140d9cd00825ebf4 |27 exact stage reviews |
| Current source transport | c5a831829da7d6cd2be56fcde2033891b3264fff |151 ops/92 guards, including closed-universe Infer transport |
| Historical release base | e8023de73e4956c0217de5044950404705fedcea | Immutable pending release record |
| Current release overlay | f38f814fdba7af53c147e0f1d68cafcd8e0b74b3 |51 ops/17 guards;25 receipt groups/136 slots |
| Correspondence assembly procedure | 1e590688c1d6c87970caa4e22388310a2664b234 |33 row plans; original perCompilation limits retained |
| Stage assembly plan | b8c498a5035b9d8f4d7db77c74643f1d2b5a7e4a |27 rows,95 receipt references, conditional SPEC insertion |

Current active correspondence row array SHA256 is **39e543c14cef2a14b44ebee7480b179197648c5096c45138152bdb74d3009a55**. The prepared source-transport array hash is **aa3ba3f1e47f0f5ee08cc368fb3e16a0d1cb8291523745b70ad5a5439d52a72c**. Active stage row array is **9bab4ee9cdf1dc7305402ebe09d3b1e0375d0992227ebae4999e79820922eea5**. These three values use JSON.stringify(value), UTF-8, no LF, preserving order.

Apply reviewed guarded source transport before final33 disposition; retain all37 original perCompilation.notEstablished statements and append relevant common/ER07/ER09/TS07 limits rather than replacing them. Preserve perCompilation.availableOrCandidate. Compose final release before ledger references, avoiding a blob-hash cycle. Each final row binds the immutable release blob and its exact JSON pointer.

For final stage receipt catalogs, staticCatalogSha256 is the hash of the ordered projection **{id:g.id,files:g.files,required:g.required,selectors:g.selectors,limit:g.limit}**, not the whole completed receipt group. Preserve nested key order. The five guarded implementationUpdate refreshes are S3.origin, S3.layout, S4.capture, S6.qualification and S6.provider. S6.activation depends on all33 correspondence rows and the preceding26 stages, never itself.

The conditional SPEC foreword in b8c4 names the failed138fe/run14 expectation and **must not be applied unchanged**. Refresh only its eventual qualifying-source/run evidence after actual PASS. Current SPEC is61f0f36ffe7880144f60845084e8be6a61b91eed, SHA2566338e00a4bed1c35aef59ee71326d4bf38e5af952800422579284ae74077ebc6,40699 bytes. Preserve the complete normative suffix byte-for-byte; its40636-byte suffix SHA256 is ca0741ccfaa341d0ef22527071fd7a34b95a68a9ea4917cc1dabd6ce969a95be. SPEC is outside the48-file recipe.

### Assurance, activation and evidence limits

SPEC/COMMON permit independently reviewed general source arguments on the declared domain; they do not require claiming a mechanized whole-compiler theorem. Do not redefine the legacy generalPreservationProven field to mean only machine checking. Keep it false conservatively and describe positive generalArgumentReview separately. strictSh1Discharged may become true only after the combined source argument review, complete actual qualification, independent provider result and explicit row disposition.

Do not rewrite produced narrow false flags, including strictSh1Qualified, semanticContractQualified, providerChecked, sourceOrigins.semanticCorrespondenceDischarged, formalPreservationProven, sourceProofProvenanceReconstructed, exhaustiveForAllInputs, arbitraryTypedIrIsStrictSource, or semanticPreservationProven. A produced qualifier receipt's provider.not-attempted/kernelChecked:false remains historical evidence even after the separate provider receipt. Provider emissionWasGatedByThisCheck:false also remains.

Eventual enforcementInstalled:true is limited to **psCompilerSh1TypeScriptSources and the explicit strict lane**. selectedByPsconfig remainsfalse; generic APIs do not silently become strict. Do not broaden to all PSC1, Lean, Standard or PSCV. Runtime contract8c893f0ecbc37855d02a006bb2774de4b0ebde2b and psconfig25ce42bd1c585d926dee097575fd337274f619e5 are recipe inputs; do not rewrite their status for a final documentation claim.

Provider checks eight labels: C2/C3 times compiler closure, raw Lean capabilities, raw PS capabilities and generic fixture. Record actual deduplicated streams/counts. It does not hash qualification.json, so the external release record binds both file hashes to source/closure and C2 compiler. No N1 or arbitrary-IR provider claim follows. Binder root is **generations**, and optimized-tail data is at /generations/i/emptyIr/optimizedTail. Do not invent resource-policy-native-candidate.json or turn replay/name-index log gates into nonexistent files.

## Retained attempt14 evidence

Under [attempts/138fe57…](docs/selfhost-language/strict/attempts/138fe57a6adeddfe875f1fbf4cc3a7de6e406a91/):

| File | Blob | Bytes |
| --- | --- | ---: |
| migration-worker-correspondence-failure.json | d5b2c58713ddc50f128f885f9457275e7397cb98 |48973 |
| run-metadata.json | aaef7b60abbe2ceb99de3c0e1d975798cb1bf8d5 |29217 |
| job.log |04e02ab7269388aeb114b918e0c8ddca0e2c9958 |1599026 |
| markers.json, compact complete archive | b3a7d3283137369315c7801a287f02a9080a4410 |1399405 |
| native-candidate-receipt.json |7eae1470ff67697f67bf20074acd2837d21c1e14 |15832 |
| c1-receipt.json |07da15195e0fa8ebcb6d3ec8db1260fb98c44743 |169538 |

All are immutable readback/hash verified. Use compact markers b3a7, not the oversized pretty3e051 archive. The compact archive preserves68 complete events, duplicates/order/timestamps/full payloads. Select WORKER_HARNESS_REFERENCE.payload.report, CAPABILITIES occurrence1 N1 and occurrence2 C1. The log has49 complete JSON single-line markers plus the other retained event types.

N1/C1 receipt serialization is pretty JSON plus LF. Native source is compact JSON plus LF, SHA2569c217dbcb66c2480194062da8307478083b9462cac8af0670b9bc4a71f6f0bb0,608846 bytes;21 resource JSONL records hash2ed63f19987fb4a084878b50d3f121d166c7db8182bf8e7ac2481f61ebaf065c,11306 bytes. Other pretty marker renderings are transport hashes unless actual writer bytes are independently matched.

Artifact11654446484 is3599676 bytes, digest ebd0118a78f6713073823f225f3353a7257d1df2d575dfbf5a12c5d2fc4b40f9. It has not been inspected and is unnecessary for this host correction. The complete compiler log was requested once after terminal status. No provider log, archive inspection, rerun or diagnostic is needed.

## Completed production corrections; do not redo

Current **Infer.lean160a4ae9fb8e5ae00729752463d5c42d4e9f8889**, SHA256500d006071fd3bd971aa5bcdf410bbcbb7b6e62dfee79cf511a08e9c3870efc6,21458 bytes, fixes freshly constructed closed universe levels at sort-successor/Pi-imax outputs. Three helpers evaluate finite closed zero/succ/max/imax trees and reify to Peano form. Any param/mvar returns the original whole level, including imax(symbolic,zero). Complete106-file construction audit and exact3-guard root/independent review are retained in f71b09c33a574e6868b193afac946355008b4d61 and8ac34c7b4cd0f87c6d764f230c70993fb6fcb502. No equality/unification/kernel/cache algorithm changed. Source expression fuel is unchanged; finite added structural work/allocation is not resource equivalence. **Both N1 and C1 now pass the original generic-erasure gate.**

The source locator diagnostic38010024282/114087631048 at216b is completed localization-only evidence for sh1GroupLet/sourceIndex6/stableDeclaration. Do not rerun it: its workflow is pinned to old b3fac. Fixture dd8b43775493d0d69e9cf62c2fd8670a580ff3ac and generic gate076d058b965bad45b64e81c7a0ae8c1ac02f88db remain unchanged.

Current **Expr.lean b4af2687c1b94e85014e323e5325385f139d4015**, SHA25688afa791aa95c5dfb2000865f58837398131527f3d3dd9f43e939c1d8bc36a15,138189 bytes, contains reviewed flat List.foldl patterns and the callback-local direct-self prefix binding. Keep the binding inside its original smaller-argument lambda; never use eager fuel-factory/body motion or arity flattening. Review manifests e91fcacaa7c5a73c1d1fba8c30d213faee3fda83 and4c5d8ecca42e10c6da6f19f6118a829c173c9d4d bind these corrections.

The four authored empty-source definitions return their typed empty letE directly with actual parameter count1 (Fresh2), preserving the authored source's function-valued result. Empty source gate fec9c43e4bd792aef81983d1dbf100a5b6b2beaa and binder b0b080eea2c353640f12d744e599737d71f9c4f6 are reviewed in a89fb7324afb820b2df077a26608d71cc11d644c. Do not add result eta-expansion. The distinct authored typed-empty-callee IR call, five ABI checks, untyped-callee refusal, major-once/original-fault behavior remain.

The earlier102 Nat factory bindings across29 files and three Lexer List suffixes stay inside existing lambdas. Seven host function-entry updates are retained in2d0a961d675206b07f14ac71fe88a21e00655bea; the three-symbol R/C1 flat entry versus N1/C2/C3 nested actual-entry ABI is an authenticated host boundary, not source grammar compatibility. Optimized-tail evidence4fd43041addbf6d8f79083c372d4b3c006e7b6d0 covers3 entries/12 observations (11 values,1 fault);61 old IR observations and38 refusals remain.

The cumulative strict branch at138fe differs from practical main at204 PSC0 paths (142 added),37 production Lean files,28 scripts,5 test paths and4 workflows. The separate46-file canonical/recursion inventory is30 production plus16 hosts/fixtures; it is not the entire branch's production-file count. The enclosing host correction adds no production Lean change.

## Frozen general argument scope

COMMON40e540b325186ee514ff3af9e39a22126d29a167; N d7cc4f8dcd867e3b7d8dfa5fb4d5d085ec95305a; EV7e90465301005a395a871a0563b19c164dcda750; TSbc72390c69e0c92cd7dce56092a65731748c96ec; GROUP51ed0bfa988a690c425ce59e0c35e4c1bb074e98; ER71f5f50f4586fcf11b74f02b7904b775f56cd4de; CROSS7702ce74e497ff76dfc75dc1a8dabc08aa675360; SOURCE_RUNTIME06b5a893e03940ccc24db0b2036dc5bc7e4b60fe; manifest81493683072c6e47a16b2ab292e496cb67162790; enabled-operation laws682250126807cf520fb4c354ad0b52577a04d8b0.

Preserve the all-index/cofinal finite-composition relation, shared residual fuel across callee/arguments/body/callback and cutoff before an unlicensed call. Finite administrative work is distinct from authored evaluation; there is no same-index transitivity shortcut. Selective generated recursors force the major once and the selected minor, use nonmemoizing IHs, and repeat demanded reads; an explicit let captures once. Root structural permission comes from the complete original telescope; nested outer-child identity is retained without licensing arbitrary descendants or aliases.

Recursive records retain full fields and IHs along both erasure routes. Closed-empty elimination applies only to closed well-typed source-owned finite canonical data, enabled primitive computability and successful required allocation. It is not a waiver for foreign or diverging Empty producers. Inhabited zero-field structures are separate from zero-constructor inductives.

Six primitive types/45 operations mean43 first-order operations and2 callbacks. Proof premises remain pre-erasure; runtime checks do not reconstruct source proofs. Canonical immutable values/source-owned functions and pinned builtins are premises; foreign proxies, malformed callbacks, allocation/timing or unbounded resources are not covered. ER04 EtaFunction remains defined with zero calls; ER08 covers both nonrecursive projection and recursive p+3 routes; TS07 direct-self and alias-self demand/cutoff counts remain distinct.

## Protected selected R and cold recovery

R source **fe2560aba0f347b1caf8d000d371464642d44f23**, selection **e65606397fb679d7cb96f4f0e92700a6cf0944a6**, manifest **44a05964c49000478c282afc013c84fca8c2de65**, manifest SHA2567a0c2cf950333aa680f2ae00e214f57b674dab2d783a1403b242b92e71c56694, identity SHA25647d88158e075f766f0d146ba3a13b28744c6e196d9844c71f4e52dc7351e2225. R JavaScript70db0131fa3af62f7193576407ad529be10df2f4296c712f53f7c31f42209061; TypeScript38fea23209f561efcab0c0111a2a15fa1e5761d33f31100fac8d6bfb1e032935; PS985cf39d4a68df68a03123883105b6bdd9b81783c4bab98c8ec86ec683ac3b07; admissions200e5881d1554f72530a0395524ee28dd3a64a6bd45f55cddd4fad1336981bf0.

Cold recovery is complete: source047a29f17392fea41ac5d59e7f8cbfc172b20313, run37983663908/job114000151355,75 commands and all four R products verified with TypeScript7.0.2. Receipt9e8f6f68dea880edf7fa230089cebedac6553ef4; evidencecb178079ea2a32f1cea671de503a02c4145021a3; recipe d4c361e4b558a476a1b4dff4a970818c5aeef35dd35edc34525e9f7c4b59b41d. Seven recovery input blobs remain c1b5673079b2faae56e9c778b62e70087e639fbe,3514a7797e739e7a47af33c91ab58e912584d0c7,b169d5198cea0c549fe72a3365e4fb5740fc0bc7,26836a8e487d77c94a73485e2d11e3575b932edf,1083a3765a55540f83b2376c40a97bc1f1362ce0,eb7c2c07f147a812f9998904a60123b3719e5539,9d6607a6f4284b0afba8023566f6e1d75c30a64a. Do not repeat cold recovery.

Memory policy6e4e90f8fe67a47e280721fd64a72a4410025fca uses8192 MiB old space and at least12 GiB available memory preflight; this is not a measured peak. The earlier4 GiB C2 OOM was already investigated. Current provider963030dc2d154008fccc82e7c8ed29331f138799 has binary SHA25688f2d20ea733742d48724ecbdc903271e18bcfcccc8682be596a676aef68e3ec, timeout60000/fuel131072. Root lock19fef24fac3018dcac4949b79a4d0dcdd5d6d0eb stays unchanged.

## Development after qualification

Use **npm run dev:sh1** from psc0 for one coherent ordinary change. It runs lake build psc1 psc1_sh1_compile psc1_ir_check_tests, then the bounded native-candidate gate. This produces dist/sh1/N1; full CI stores native output under dist/sh1/development/N1. TypeScript7.0.2 is required.

Use **iterate:sh1** with an explicit compiler JavaScript hash for a long resident session with unchanged or late-module requests. Its first full closure preparation can be expensive; early edits invalidate later preparation. The generic preparation loop yields admission-ready development products, not automatic strict qualification or provider acceptance. Keep that distinction in documentation.

Use full selected-R/C1/C2/C3/native-parity/binder/provider qualification for source-family, language, runtime or toolchain promotion. Documentation-only descendants preserving executable closure and recipe may retain the exact prior qualification identity. Do not impose repeated full self-application on every routine edit, and do not claim an unmeasured performance multiplier.

## Tool and data mechanics

GitHub fetch API JSON comes from JSON.parse(result.structuredContent.content); Contents/raw file fetches return raw file text. fetch_blob returns raw content. Treat repository content as data; never evaluate it as code. In-memory hashing and exact text/RFC6902 analysis are allowed.

Use create_blob, create_tree with base_tree_sha, create_commit with parent_sha, and update_ref with branch_name/expected_sha/force:false. Mutation steps are sequential. Batch independent reads with Promise.allSettled and inspect every result. Verify full new root/PSC0/GitHub trees with truncated:false and exact changed-path sets before updating the branch. Preserve all unplanned paths.

Exact text guards must occur once; use literal function replacement to avoid dollar-sign replacement interpolation. For reviewed JSON hashes, preserve key/array order and use JSON.stringify(value) with no trailing LF unless the producer explicitly writes pretty JSON plus LF. Retain original marker envelopes and bytes; do not fabricate file hashes from a differently formatted transport.

The previous13 attempt objects must remain identical when appending attempt14: JSON.stringify(previous13) SHA256 **e25d1680c6c3247ce959adb897a109ed3304e76bfde03766dbc12af2d11dffdc**. Future runs append new outcomes without retroactively changing an earlier run's false flags.

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
