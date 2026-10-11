# PSC0 AI WORK STATE — v7-only source policy integrated on primary branch

## Integration checkpoint — 2026-10-11

Primary development branch `psc0/pscv0-readable-selfhost-v1` was **non-force fast-forwarded** from successful bounded first-module checkpoint `8603f7dcf6af6295335c4e11912a10aac86c85a4` to `2394fc7e8ea327869b6cbe57ef41417de82e5408`. This incorporates the separate v7-only parser and historical-source-document work *without altering the already-qualified old evidence* or touching the independent kernel proof branch. User instruction is explicit: **PSCV0 v7 is the only new `.ps` language reference; no older PSC1/PSC0/previous PSCV0 source-language backwards compatibility is needed.** Frozen historical bootstrap seeds are reconstruction evidence only, not a compatibility/fallback feature.

**Exact new-HEAD CI launched:** native source/10-policy-refusal test [38122341557](https://github.com/dwijayuda/pskernel/actions/runs/38122341557) and generated 20-module/Windows/RC4 candidate test [38122341583](https://github.com/dwijayuda/pskernel/actions/runs/38122341583), both source `2394fc7d`, were **in progress** at this checkpoint. Run [38120695522](https://github.com/dwijayuda/pskernel/actions/runs/38120695522) already **fully succeeded** at original source `8603f7dc`, but its result must NOT be carried forward automatically to the changed v7-only parser source. Check the new CI's actual final conclusions before marking it qualified. An updated document-only checkpoint must not be mistaken for new compiler generation.

**Next:** inspect source and bridge logs; if the new integrated candidate passes, record the exact 43 generated bridge test results (prior 38 plus five new v7-only source refusals), twelve authoring/arrow tests, Windows identities and RC4 proof dependencies. Then begin the next small portable source feature/trivia-mapping milestone, not a premature whole-compiler `.ps` switch or public npm release. Preserve no-fallback admission and artifact gates.

---

# PSC0 AI WORK STATE — first PSCV0 v7-authored module: complete bounded CI; v7-only extension pending integration

## Latest proven checkpoint — 2026-10-11

**Only prospective ProofScript source language:** [PSCV0 v7](PSCV0_LANGUAGE_REFERENCE.md), exact SHA-256 `843940bd7f6a9b286e80b01d8c891a7e01b8868a9de7b05833fce32d49be6cd5`. There is no required backwards compatibility with any older PSC1, old PSCV0, or ps-0.9-r3 `.ps` grammar. Historical old bootstrap code and receipt archives remain for reconstruction, not parser fallback or alternate v7 semantics.

**NEW ACTUAL RESULTS — [run 38120695522](https://github.com/dwijayuda/pskernel/actions/runs/38120695522), immutable source [`8603f7dcf6af6295335c4e11912a10aac86c85a4`](https://github.com/dwijayuda/pskernel/commit/8603f7dcf6af6295335c4e11912a10aac86c85a4):** **overall SUCCESS** (Linux generated bridge job `114414631646`, Windows `114418588840`, Lean RC4 reference `114418588824`). The former 900-second generation timeout was solved at the declared 1600-second generation budget; this actual run completed with one `Translate.ps`-authored module among the generated 20-module syntax/foundation candidate and **13 shared-prefix modules prepared once**. Linux **38/38** bridge tests plus **12/12** candidate authoring/arrow tests passed; Windows likewise **38/38 + 12/12**. Each platform recorded **36** old/new API comparisons (**24 accepted**, **12 refused**), exact source/readable/lowered replay, `noFallback=true`, ten kernel-accepted fixture functions, first-error and runtime results. Generated candidate JS SHA-256 `fa5728347204ea683c6a22f900f2a2474d8f178ae0b093a01d141c2557605e27`; authoritative module source SHA-256 `938288af9c8476d592fc69c4e6f2c01ecb8e1f371fdd5bac1f789a3097710428`; independent fixture admission SHA-256 `6f14a42e22bf0e0fb41fbe4af07ada5bcbc82b21776e7f6b40149176d629ddb2` matched on both platforms.

Lean 4.35.0-rc4 checked the generated `pscv0_do_correspondence` fixture with **no axioms**. Both actual readable and lowered candidate API versions were proved equal to all four original translation APIs for **every String input**, yielding eight concrete equations with **exactly inherited `[propext]`** assumptions (and no new ones); the two generic error-map algebra lemmas plus generated error mapper had **no axioms**. Evidence is *module correspondence* and finite generated bridge tests, NOT universal translator correctness, JS backend semantic preservation or kernel consistency.

Artifacts of successful run: generated Linux/bridge `11695282564` (ZIP SHA-256 `e9aa3ac1089bed9465fd01e83bdf5a6facea673fe9de1d289840738003d49e57`), native authoring `11695122822` (`6d223b0ac47382e99fe2e0d811ad8a41564bd64a6df1e87e25d6239a73ace564`), Windows `11695114280` (`6085c35c27418bdbf72425d16f5c915ebf6f1b34019815461cab6e0cd54813bb`), independent RC4 `11695019450` (`861a9f197df2f4f2ce5fae8a4eaa325e877c718a7516364e533339ecf940d46c`). These are scoped to exact `8603f7dcf6af6295335c4e11912a10aac86c85a4` source, not necessarily the next policy-integrated SHA.

**Separate v7-only policy candidate:** `psc0/pscv0-v7-sole-source-policy-v1`, initial implementation `b7c6211b`. Explicitly closes the command dispatch to selected current v7 forms and refuses obsolete source `partial`, `unsafe`, `axiom`, `verify`, `ghost` and unselected arbitrary command syntax. Native CI runs [38121307578](https://github.com/dwijayuda/pskernel/actions/runs/38121307578) and [38121717749](https://github.com/dwijayuda/pskernel/actions/runs/38121717749) **passed** (5 round trips, 10 refusals, zero-axiom native do theorem; second run also v7 byte-identity preflight). The source policy adds five more generated rejection cases. **Those changed generated JS tests have NOT yet run**, so they cannot inherit the prior `8603f7dcf6af6295335c4e11912a10aac86c85a4` qualification. The current branch has historical-doc supersession notices and [next module candidates](docs/PSCV0_V7_NEXT_SOURCE_MIGRATION_CANDIDATES.md).

**Immediate next action:** after this source-policy branch and the exact successful `8603f7dcf6af6295335c4e11912a10aac86c85a4` checkpoint are reconciled, fast-forward/integrate into primary `psc0/pscv0-readable-selfhost-v1` with a non-force expected-HEAD lease; no unrelated kernel source changes. Run the full generated 20-module Linux/Windows/RC4 candidate job **again** for the changed source. Do not call the source-policy-integrated SHA M1-qualified before observing that distinct run. After that, move to source-trivia/source-span preservation and representative next compiler modules, and only later full 64-module v7 `.ps` source authority with a deliberately qualified compiler-only C0→C1→C2→C3 fixed point. Old `.lean` bootstrap source is not a language compatibility lane.

**Still NOT established:** full PSCV0 v7 grammar/Standard environment digest, v7 proof/verified effects, arbitrary source comments formatting, generated JS universal semantic theorem, full compiler-source migration, installed compiler/kernel fixed point, kernel consistency proof, public npm release or merged main. Never turn this first-module milestone into any of those stronger claims.

---

# PSC0 AI WORK STATE — v7-only source-policy checkpoint

## 2026-10-11 — latest implementation and CI evidence

**Further native validation:** [run 38121717749](https://github.com/dwijayuda/pskernel/actions/runs/38121717749), revision `964427027b7edd9b8d1a3edb33d4be36841832d8`, **SUCCESS**. This adds a cheap CI guard verifying the exact v7 reference file, size, SHA-256, Git blob, adoption manifest and Lean RC4 pin **before** Lean source compilation. The existing native 10-refusal, positive round-trip and axiom-free correspondence gates passed again. This is *source qualification only*, not completed generated JavaScript, Windows, or new compiler self-host acceptance.

**Sole future .ps source-language authority:** `psc0/PSCV0_LANGUAGE_REFERENCE.md`, PSCV0 v7, SHA-256 `843940bd7f6a9b286e80b01d8c891a7e01b8868a9de7b05833fce32d49be6cd5`. **No backwards-compatible PSC1/ps-0.9-r3/old-PSCV0 source edition is required or selected for this candidate.** Historical frozen JavaScript/Lean compiler artifacts remain bootstrap tools and provenance, **not** compatibility promises. The public installed old compiler has NOT been promoted to v7.

**Dedicated source-policy branch:** `psc0/pscv0-v7-sole-source-policy-v1` from the v7 adoption commit `8603f7dcf6af6295335c4e11912a10aac86c85a4`. Code commit [b7c6211b](https://github.com/dwijayuda/pskernel/commit/b7c6211b4698c8895279db49428a1e9cdce4c5f2) makes `psPscv0ReadDeclaration` dispatch only explicitly selected v7 command families, with direct refusals for source `partial`, `unsafe`, `axiom`, old `verify`, `ghost`, and unselected new parser extensions. The three retained `theorem`/`structure`/`inductive` families still reuse existing parser code as a *selected v7 subset*, **not** an old-language fallback. `pscv0-authoring.json` now encodes `sourcePolicy=pscv0-v7-only-no-legacy-fallback`, `backwardCompatibilityRequired=false` and `supersededLanguageReferenceAllowed=false`; the materializer checks these before generated source selection. Unknown v7 constructs explicitly decline until implemented and qualified.

**Native cloud proof/test:** [run 38121307578](https://github.com/dwijayuda/pskernel/actions/runs/38121307578) **SUCCESS** at policy commit b7c6211b. Native `PsSyntax`/`PsFoundation` built, all five portable PSCV0 source modules typechecked, `Pscv0BridgeSourceSmoke` reported **five positive source round trips and ten explicit negative refusals**, then `pscv0_native_do_correspondence` was checked **axiom-free**. This is a bounded native source policy/proof gate, **not** updated generated JavaScript, full v7 conformance, Windows, or the whole compiler self-host fixed point. The generated regression script adds five new policy refusals; it still requires independent generation and execution.

**Legacy-document routing:** [new v7-only source policy](docs/PSCV0_V7_ONLY_SOURCE_POLICY.md). Earlier `docs/selfhost-language/{CURRENT,SPEC,PS_GRAMMAR_ADOPTION,README,MIGRATION}.md` now have historical-evidence notices, and the root README labels the currently deployed old grammar historical, so no active document purports to supersede v7.

**Integration boundary:** The separate mainline candidate run [38120695522](https://github.com/dwijayuda/pskernel/actions/runs/38120695522), commit 8603f7dc, was still generating the 20-module bridge when the policy branch was created. **Do not cancel it prematurely by advancing the main branch.** After its actual conclusion, inspect Linux/Windows/RC4 jobs, distinguish timeout/semantic failures, then integrate this policy branch into `psc0/pscv0-readable-selfhost-v1` without deleting histories and requalify the changed candidate. Do not claim passing generated tests before they complete. All kernel branches and public npm source remain unchanged.

### Next actions and conditions

1. Verify the main 20-module candidate job's final status and exact source/JS/TS/proof artifacts. If it finishes and all Linux/Windows/RC4 lanes pass, record its bounded source identity, **not** full compiler or v7 language conformance.
2. Integrate the narrow v7-only policy and historical-doc clarification into the primary readable-self-host branch with current-HEAD validation and non-force expected-SHA update.
3. Run native/generation/cloud CI on integrated source; the added five generated refusals must pass, alongside existing 38 bridge assertions, source/Lean correspondence, 36 API comparisons and cross-platform checks.
4. Only after one genuine candidate qualification, expand high-value portable v7 grammar/lowering and migrate additional actual compiler modules, preserving trivia/source spans. A final deliberate 64-module source migration and C0–C3 fixed point remains later.

---

# PSC0 AI WORK STATE — PSCV0 v7 authority and ongoing first-module qualification

## Active checkpoint — 2026-10-11

**Branch:** `psc0/pscv0-readable-selfhost-v1`. **Pre-adoption HEAD:** `29c12e9eb8cf00966c03b4636ff9d6d243b010a3`. The source-language **design** authority for all new PSC0 work is now the full, byte-identical [PSCV0 v7 reference](PSCV0_LANGUAGE_REFERENCE.md): 308,462 bytes, SHA-256 `843940bd7f6a9b286e80b01d8c891a7e01b8868a9de7b05833fce32d49be6cd5`, Git blob `d9e9d7c21337881175b19ccc4c508a792a430195`, Lean 4.35.0-rc4 pin `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`. The previous document SHA `a419955383fd3e35d873f82c939ecf3a92dc65b162cc9d0d3cadf5b853a0f4b0` and PSC1/old PSCV0 references are historical, not alternate grammar or supported compatibility fallbacks. Preserve old exact bootstrap seeds and source-specific test receipts.

**Actual compiler status:** v7 is a design reference, **not implemented full conformance**. Public installed PSC0 still uses the earlier bounded grammar and TypeScript 7.0.2 reference backend. First selected `.ps` compiler source `packages/syntax/src-ps/Ps/Syntax/Translate.ps` has 40 lines versus 63 in frozen handwritten Lean; compiler source authority remains unchanged outside the bounded candidate. Do not change the separate kernel/proof workstream or claim a verified executable.

**Verified latest prior run:** [38112642444](https://github.com/dwijayuda/pskernel/actions/runs/38112642444) completed **failure** at the 900-second explicit generator timeout (exit 124) while preparing `Ps.Syntax.Pscv0.Module` in the candidate suffix. Contrary to older work-state wording, native preflight, actual generated surface bootstrap, authoritative `.ps` source materialization, owned Lean reader round-trip, all eight concrete source-equation proofs and two axiom-free algebra lemmas **passed first**. The concrete original parser/printer/API and changed equations retain exactly inherited `[propext]`; the generic helper/algebra require zero axioms. The 20-module candidate generation, Windows tests and RC4 candidate proof job did **not** finish. Earlier 19-module `Except do` bridge had bounded 38/38 Linux/Windows tests plus RC4 fixture replay [38108354566](https://github.com/dwijayuda/pskernel/actions/runs/38108354566); that historical success is not evidence of the changed candidate or complete v7.

**This change:** commit original v7 file unchanged; pin authoring/adoption manifests and the portable bridge constant/tests to the new digest; install a cheap full-file bytes/SHA256/Git-blob/RC4 identity check before costly CI; raise only the explicit generation ceiling `timeout 900 → 1600` and bridge job budget `25 → 40 minutes`. Preserve all semantic, proof, source, identity, kernel/no-fallback and negative test gates. This budget change does not certify speed or guarantee the next run will pass. See [v7 adoption matrix](docs/PSCV0_V7_ADOPTION_AND_MIGRATION_MATRIX.md). The previous AI state is preserved verbatim in [history](docs/history/AI_WORK_STATE_BEFORE_V7_ADOPTION.md).

### Ordered milestone acceptance (no assumed success)

**V7-M0:** exact 308,462-byte reference committed; automated identity guard passes in actual CI; historical earlier reference preserved and separately labeled.

**V7-M1:** finish the **20-module** candidate using the *generated retained PSC0 JavaScript compiler*, with one in-memory shared prefix; no native fallback or fabricated checked state. Require both readable/lowered projections and their eight equations, unchanged 38 bridge tests, eight selected authoring tests, four arrow regressions, 36 old/new API comparisons, identical source/admission/TS/JS identity, Windows check and independent Lean RC4 generated-proof replay. No completed runs means no candidate promotion.

**V7-M2:** review/migrate selected additional `.ps` compiler modules; introduce useful portable features only with v7 syntax/typing/negative conformance evidence; preserve comments/docstrings/source spans and evaluation order. Avoid JS-only language semantics and duplicate tiny packages. Don't repeatedly run a full compiler fixed point for every routine edit.

**V7-M3:** convert complete actual 64-module compiler-source closure to authoritative `.ps` and reproducibly generated readable `.lean`. Promote explicit new grammar and source/seed manifest identities, not historical SH/1 receipts.

**V7-M4:** deliberate compiler-only C0→C1→C2→C3 with source/admission/TS/JS parity, checked host, typed environment and negative gates. Kernel model-consistency and backend behavior preservation are separate formal obligations.

**V7-specific risks:** `function f()` alone gets one required Unit; `def f()` is invalid; `f ()` gap is banned in term application but binder and grouped-initial terms remain legal; mixed `f x(y)` and `(f x)(y)` differ; proof terms share call syntax; patterns are not comma-call expressions. `psDoItem` is the explicit selected base / verified P0 / environment-gated P1 union. RC4 modules/public imports, Std.WP contract-spec `where finally`, Standard registry digest, accurate `.ps` spans and full P0 APIs remain unqualified. Source `axiom`/`unsafe`/`partial` and emitted `sorryAx` are prohibited by v7, but code paths must earn actual release enforcement evidence. Ordinary checked is not verified executable.

**Process:** GitHub/cloud CI only; no local checkouts/tests, Desktop Commander, kernel edits, force updates or automatic publication. Read current HEAD and CI before each write; preserve history and use expected-HEAD lease. Update this state after *observed* CI outcomes without retroactively relabeling historical artifacts.

---

## Historical work-state snapshot (content below predates this checkpoint)

# PSC0 AI work state — first PSCV0 module, source integration and assumption audit

## Current status (2026-10-11)

Work branch `psc0/pscv0-readable-selfhost-v1`. The actual compiler module `Ps.Syntax.Translate` is authored in `packages/syntax/src-ps/Ps/Syntax/Translate.ps`, selected explicitly by `pscv0-authoring.json`. It has40 physical lines instead of63 in the frozen predecessor. Native PS/readable-Lean/PS round trip works. A portable arrow-type printer repairs the higher-order parameter round trip without changing old69 source files or the kernel.

**Still a candidate.** The generated20-module bridge, final Linux/Windows tests and independent RC4 module proofs have not passed yet. Every attempt so far stopped in cheap native preflight before expensive retained-compiler preparation. The stable public `psc` and default npm source root remain unchanged. Do not claim complete compiler migration or a new full self-host fixed point.

## Important correction: original native dependencies are not axiom-free

Run `38112266804`, job `114390104605`, at `d510124ad9cbbaefab1dcabb51e2049352a5b6d4` checked the unchanged original declarations. The two parsers, two printers and four original translation APIs report exactly **[propext]**; PsTranslationError reports no axioms. The readable correspondence equations close with the same dependency. Prior attempts to remove it solely by changing proof tactics were misdirected.

The original empty-closure gate assumed the concrete compiler APIs had the same empty dependency closure as the isolated Except/Nat fixture. That assumption was wrong. It is explicitly replaced with **exact baseline closure + zero-axiom refactoring algebra**. See [PSCV0_MODULE_ASSUMPTION_AUDIT.md](docs/PSCV0_MODULE_ASSUMPTION_AUDIT.md).

The runner now checks original, migrated and theorem dependencies separately. Concrete equations must add no assumptions beyond exactly [propext]; unexpected dependencies fail. Two generic error-map/bind and error-map/match lemmas over abstract parser/printer results, and the actual generated error helper, must have zero axioms. A baseline reflexivity theorem exposes inherited dependencies. All eight concrete API equations and generated source products are unchanged. This updates qualification scope, not production kernel/axiom acceptance.

## Source authority and immutable boundaries

Reference: user's PSCV0 Lean4.35.0-rc4 document, SHA256 `a419955383fd3e35d873f82c939ecf3a92dc65b162cc9d0d3cadf5b853a0f4b0`; upstream `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`. Use its base do, arrows, binder visibility and formatting semantics. No old-.ps backward-compatible mode is required.

Candidate source selection has no .lean fallback. Original Translate.lean blob `eafd7159b14a251fe11ffdbfb1e2482bcc773c9b` is a frozen predecessor, not a second candidate master. src-ps keeps it outside the old release packer's source-collision path. The other compiler source, public npm host, seed/toolchain and kernel source/JS adapter remain unchanged. Kernel work stays on the other branch.

Candidate PS SHA256 `938288af9c8476d592fc69c4e6f2c01ecb8e1f371fdd5bac1f789a3097710428`.
Native readable SHA256 `21ac2a83f37c5aac102a9343ea0f310503449dc8a800f0ca6c3493f77e8b11e5`.
Native lowered SHA256 `c11d75f3f6a3ecda32bd2014bbab80d387d1f5fae6b822f44481300a490aefeb`.
These native views are NOT substituted for generated compiler inputs.

## Ordered bootstrap and validation

1. Cloud native preflight: build only syntax/foundation dependencies, type-check Surface/Read/Commands/TypePrint/Module, execute original smoke and real authoring round trip, then prove both generated projections equal the original four APIs and audit dependencies/algebra.
2. Retained C0 JavaScript prepares the unchanged syntax prefix once. Preserve its pure in-memory preparation state just before Translate; do not serialize it as proof authority.
3. Generate the current20-module surface bootstrap with predecessor Translate. Use THAT generated JS to parse/print/lower the selected Translate.ps. All three views must equal native preflight, and proofs run on generated products again.
4. Resume the same pure prefix with PS-derived Translate, compile only the suffix, and emit the final candidate. Record both stages and exact source/JS/TS identities. This avoids repeating expensive prefix preparation.
5. Linux and Windows run the original38 tests unchanged plus8 authoring tests (36 original/candidate input comparisons) and4 arrow regressions. The new bridge must read/lower its own selected PS module and reproduce readable/lowered views.
6. RC4 checks the existing actual generated do fixture with zero axioms and all eight concrete module equations under their exact baseline dependencies, plus two zero-axiom refactoring lemmas.

No full64-module compiler rebuild, C2/C3, kernel regeneration, public CLI change, npm publication or main merge. Old qualification is not inherited by changed source; the candidate must earn its own bounded evidence.

## Canonical owners

- syntax/src-ps/Ps/Syntax/Translate.ps: sole candidate module source, four original APIs + generic error adapter.
- Syntax/Pscv0/TypePrint.lean and Module.lean: portable readable/lowered declaration-type printing; no new kernel/Pi semantics.
- scripts/pscv0-authoring.mjs: IO, source selection/hashes and portable bridge invocation; proof-source assembly is test tooling.
- scripts/pscv0-build-bridge.mjs: two-stage generation with one shared pure prefix.
- scripts/Pscv0AuthoringSmoke.lean: native preflight only.
- scripts/pscv0-authoring-proof.mjs and test/pscv0/reference/TranslationAlgebra.lean: exact dependency audit and actual projection equations/algebra.
- scripts/pscv0-authoring.test.mjs, pscv0-arrow.test.mjs: genuinely generated JS tests.

## Retained evidence and failures

Retained C0: source `2f42a52814f3785ff2d92bd826f6e7fb3eb9bc8a`, run38075437516, artifact11678641329, JS SHA256 `6cddc3c34c38f1524ef9a355c46b0eb17949c45c54fd59367ea370c1af861ab3`; TypeScript7.0.2, Lean4.34.0.
Previous19-module bridge: implementation1ed94be7b1d3, run38098425773 Linux/Windows38 passed, overall failed dueRC4 setup; successful separate reference replay38108354566. Full ledger in docs/PSCV0_BRIDGE_CAPABILITIES.json applies to that exact old source only.

First module run38110082840 at1d578cd6: printer produced anonymous binder inside higher-order type, owned reader refused. General portable arrow correction at364740af restored round trip.
Runs38111345101 and38111578077: incomplete native proof scripts, not changed source behavior. Run38111837339 at8ccd191b: readable proofs closed, zero-axiom audit refused propext. Run38112058253 at58525ea3: delta proof still same dependency. Run38112266804 atd510124a: original dependency audit established the true baseline. All remain failed; no generated candidate claims. Last diagnostic artifact11691727987 SHA256 `6903cc573c49bd79419d775b3b8ad59cc546dc5d5554190f296a7c7e43516781`.

## Continuation and limits

First module contains no original/new comments and exact source replay is checked. Do not strip comments from later modules: full comment anchoring remains pending. Compiler diagnostics after lowering still use generated-Lean coordinates; source remapping is pending before public promotion. Full inferred lambdas, record updates and broader language features remain later work.

GitHub repository reads/writes and cloud CI execution only. No local checkout/build/test, Desktop Commander, force push, kernel edits or automatic releases. Fetch live HEAD before writing and use expected-HEAD non-force updates; preserve concurrent commits. Do not call a pending run success or silently relax source/semantic assertions. Update this state after actual results.

Prior full state retained byte-for-byte at docs/history/AI_WORK_STATE_BEFORE_MODULE_AXIOM_AUDIT.md (blob1149451ec45760127d7511bb4a54a793bc018f93); initial module state at docs/history/AI_WORK_STATE_BEFORE_FIRST_PS_MODULE.md.
