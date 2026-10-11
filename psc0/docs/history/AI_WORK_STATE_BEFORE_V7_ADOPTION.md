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
