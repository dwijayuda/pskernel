# Continue the slim universal ProofScript milestone

Continue draft PR #180, branch `feat/psc1-slim-universal-npm-20261025`, from
PR #179 HEAD ba3bfb045619ceb2948820f874357b2058f79868.
Fetch live HEAD, work state, roadmap and current CI before writes.
Use connected GitHub and Linux GitHub Actions only. No local checkout/build/test.
Preserve single-parent history with fresh expected-HEAD non-force updates.
No merge or npm publication is authorized.

Read:
- AI_WORK_STATE.md
- docs/PSC1_DEVELOPMENT_ROADMAP.md
- NPM_DISTRIBUTION_CONTRACT.json
- docs/PSC1_SLIM_UNIVERSAL_PACKAGE.md
- docs/PSC1_SLIM_UNIVERSAL_QUALIFICATION_2026-10-25.json

## Verified current package

Code0a717520110c673006d3f5f5d7627e59d5853f62 passes package run40166882825/
job121089658777, including actual local/global installation, compiler/kernel
execution and packed public TypeScript types.
Qualified artifact12588024057 ZIP SHA256
163ca39fa564e407b1008e25cdfd358f0516e6af669963ceef585bd4c628e708.

Extract tarballs/proofscript-0.1.0-psc1.4.tgz:
3,703,113 bytes, SHA256
f198538c5396d25cc9944c50c698a00bea1685ce997b55e766dd4582fddf794e.
This is94.04% smaller than the prior62,181,083-byte root.
The archive also includes exact optional Rust/compiler-Wasm/native-kernel and
standalone Wasm-kernel tarballs. Their identities are in the input/receipt.

Default root embeds genuine qualified G3 JS/TS executors and official Lean4.35
C++ Emscripten6.0.9 linear-memory Wasm checking. No native compiler/checker,
Rust executor, compiler-Wasm executor, formatter binary, SDK or Python/PHP payload
is in the default root. It installs offline without scripts and has no OS/CPU/libc
npm restriction. Node22.23.3 remains the exact qualified runtime.

The closed resolver verifies allowed packages, versions, index/manifest/resources,
compiler root and executable identities before/after execution. Installed optional
Rust/Wasm packages enter the same existing generated-compiler-session.mjs.
No arbitrary plugins, source-selected tools, network fetch or silent fallback.
Native checking is explicit optional; missing/refusing/corrupt default Wasm fails.

Actual package tests:20 compiler cases/all four executors/both grammars,
12 local/global CLI cases,48 candidate mappings including16 with optional
executors absent,14 actual native/Wasm comparisons,36 refusal/rollback cases,
a checked dual-provider compile and public types. Project JSON is closed to
entryModule/sources/assurance; host paths/executors/checkers require explicit
host options. Four field-injection cases preserve prior output.
UTF-8 is fatal and BOM bytes are preserved in captured source before the existing
frontend. The BOM fixture is currently rejected by that frontend; the host does
not strip it or invent acceptance. Invalid UTF-8 is refused.

## Finish the current source gate before further implementation

Code0a717520 now PASSES normal source run40166884643; the final documentation-only
HEAD may be newer. Preserve the successful code/source gate recorded below.

Normal source run40166884643 PASSED at code
`0a717520110c673006d3f5f5d7627e59d5853f62`: full job121091590002 and final
gate121096509883,37/37 Practical Core criteria,0 blocked,all seven backends/both
grammars,minimum Python and installed native npm/source libraries.
Tested merge`559ea387ad22999b7b6aedd073fd61c8a0c1bc28` and code HEAD share
tree`0a232bbdf67f6f8de60950142af3be17f1231e4d`.
Full artifact12589082030 ZIP SHA256
`1c0d30be97a68c7ca3fb25667dd8412dbb477d8df447960d12fd5b88764700a2`.
This is separate from slim package40166882825 and does not imply complete
cross-platform or checked non-JS generated publication qualification.

Fetch its live state; the exact receipt may contain a newer terminal result.
Require every selected static/focused/closure/G1/full/final gate. Read completed
logs for actual failures. A package gate or qualified PR #179 parent is not a
current normal-source success. Do not repeat successful frozen G2/G3 chains.

For any future source changes, record37/37 only if actual Practical Core readiness evidence
says qualified37/blocked0. Save exact head/tested-merge/tree equality, full/gate
job IDs, artifact IDs and ZIP digests. Final reconciliation should change only
Markdown and the qualification receipt JSON; the unchanged dependency selector
can then reuse the successful source baseline and run static only. Do not reset
failed/cancelled debt or modify correctness selection to suppress required tests.
Stop at this verified milestone if the user has requested that boundary.

## Existing Linux qualification controller

The committed scripts/slim-universal-input.json pins the successful PR #179
integration run40161362270/job121073432577/artifact12586394254/ZIP
426c62ce4ca8fb87570d1ba169c681004d7da5e5faea80e2b3fbe07c9ef04b52,
sourcecd6a16ba1c9efc5668507ee6b9eb125f2d3b2fad and core tgz
02c5db1989adf3ada1ad39318c3efc05498a3f3132b2f21fa6a564aceea3f60a.
The five tarball payloads are verified before fresh assembly; original compiler
and kernel executables are never rebuilt or rewritten in this slice.

.github/workflows/psc1-slim-universal.yml triggers on relevant input/controller/
runtime changes. It assembles an empty staged root from only an explicit allowlist,
uploads candidate archives before expensive tests, runs actual offline local/global
tests with SDKs absent, typechecks real packed APIs and uploads qualified archives
only after every step passes. Candidate artifact names are not qualification.

These commands belong in Linux Actions, never local execution:
```sh
node scripts/slim-universal-package.mjs
node scripts/slim-universal-installed.mjs
```

Preserve resolved first-run failure40165875329/job121086684315:
npm-managed npm-shrinkwrap.json was absent after installation. Fix039888f8 writes
and pins immutable DEPENDENCY_LOCK.json while real dependency versions/resources
remain mandatory. Root-only retries and subsequent hardening gates pass.
Do not allow missing runtime pins or substitute a registry dependency.

## Next implementation after the verified milestone

1. Extend real CLI/JSON/file/multi-module/source-package coverage through the new
   checked compile/build APIs, both grammars and all four executors. Project/source
   closure capture must remain separate from host authority. Keep the original
   native/all-seven-output distribution available and qualified.
2. Implement portable transactional publication. Current build() explicitly
   refuses non-Linux. Do not remove that guard or ignore directory-fsync/rename
   failures without an equivalent immutable-generation/atomic-current-pointer/
   failure-preservation contract and actual permitted platform tests.
   The platform-independent compile API/stdout already avoids publication.
3. Add checked generated TS output via existing emitters/IR/admission/runtime
   adapters and pinned independent consumers. --engine selects execution;
   --target selects emitted output. Current checked generated target is JS.
4. Complete checked Rust/Wasm core/component and optional Python/PHP provider
   dispatch; retain all seven existing mappings. The candidate-only API exposes
   JS/TS/Rust/Wasm-core output with logicalAdmission:not-run and no publication
   authority. It is not checked multi-target publication.
5. Deliver additional genuine Rust executor platform binaries and equivalent
   lifetime/memory/stack supervision; current Rust bundle is Linux x64/glibc.
6. Perform exact final source/package/platform release and clean reproduction;
   merge/publish only with required qualification and user authorization.

The prior native distribution and matching optional Python/PHP packages remain
in PR #179 and its install guide/artifact. Do not claim that new root mirrors all
legacy CLI/source-library/platform behavior before actual acceptance tests pass.

## Frozen semantic and resource boundary

One existing120-module compiler root
07eedac1888aad3d4192664cea8d21a515d23985f3befd6cb365d0194fee53af.
All four genuine G1/G2/G3/source/admission/both-IR/executable/four-output fixed
points and immutable readbacks remain qualified and copied verbatim.
Rust40141718481/request2d27f142; JS/TS/Wasm40147825207/request0cabb7ed.
No handwritten compiler replacement or source change exists in this slice.

Official Lean4.35.0/eb6cafb7290e8bd5f2937522d8d804f58f02bafc, trustlevel0,
finite2000000-heartbeat/20000-recursion, exact source/logical pairing, strict
original/transformed IR, negatives/ABI refusals, semantic fuel and memory/stack/
lifetime policies remain mandatory. Kernel Wasm is official C++ linear memory;
compiler Wasm retains its GC architecture. G1/tools/corpus240s, checker120s,
original1800s correctness and separate240s performance remain unchanged.
Rust-only3600s is G2/G3 compiler requests only. Lexer31e10263 stays unpromoted.
