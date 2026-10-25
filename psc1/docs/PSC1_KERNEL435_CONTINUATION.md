# Continue the Wasm-default ProofScript release integration

Continue draft PR #179 on
`integration/psc1-lean435-kernel-packages-20261025`, stacked on #178/
`feat/psc1-unified-selfhost-20261024`. Fetch live branch HEAD and CI before writes.
Use connected GitHub/cloud Actions only, no local checkout/build/test.
Routine development is Linux; explicitly requested macOS/Windows work is separate
release qualification. Preserve concurrent history using single-parent commits,
expected-HEAD updates and force=false. Do not merge or publish packages.

Read AI_WORK_STATE.md, NPM_DISTRIBUTION_CONTRACT.json,
docs/PSC1_DEVELOPMENT_ROADMAP.md, docs/PSC1_KERNEL_PACKAGES.md and
docs/PSC1_KERNEL435_QUALIFICATION_2026-10-25.json first.
Distinguish exact qualified artifacts, current source CI and final release gates.

## Completed artifact checkpoint — preserve and reuse

Integrated code `cd6a16ba1c9efc5668507ee6b9eb125f2d3b2fad`:
run40161362270/job121073432577 SUCCESS.
Seven-tarball artifact12586394254 ZIP SHA256
426c62ce4ca8fb87570d1ba169c681004d7da5e5faea80e2b3fbe07c9ef04b52.
Inside: kernel435-core/tarballs/proofscript-0.1.0-psc1.3.tgz,
62181083 bytes, SHA256
02c5db1989adf3ada1ad39318c3efc05498a3f3132b2f21fa6a564aceea3f60a.
This candidate is installable on Linux x64/glibc, default genuine Wasm checker,
with20 compiler cases,24 app builds/88 observations,24 refusal/tamper cases,
eight explicit dual checks, two native staged-publication checks and installed
public types all passed. Native compiler and checker are unavailable in default
generated cases; no native fallback. BOTH actual kernels also accept the exact
frozen compiler graph in10734ms combined; fullGenerationReplayed=false.

Fresh global test `d269846a50e33f15e18abe96b653735c0a93cf3e`:
run40160640974/job121071261017 SUCCESS, eight global-bin builds,
all four engines/both grammars, offline empty cache/no SDK/no native payloads.
Prior outputs survive invalid source and corrupt default Wasm is refused.
Receipt artifact12586541184 ZIP
e997fd9835ae91176a2a1d6d542713d92b39985fcdbc724397e6f894b680d89b.

Both4.35 kernels pass five-platform offline local/global acceptance/rejection/
corruption installation gates. Native run40155475188, artifact12584263337,
tgzSHA c8ffd49220328ec2a96ac1c4388d828df255cc21537b2484b523710fe6c17371.
Wasm run40158859386, artifact12585319493,
tgzSHA b203982eeb851b797f7a35a8a66f883472a6130f24f36c26b8931bd5e0881511.
Native binaries all below7MB; native five-platform tgz6446239 bytes.
Real C++ Wasm build40154206987/job121051950567 PASSED at630fa363:
module2212007 bytes/SHA
7412659c1089f230bfaed020e82c04fc57b88c242baa3d365def1aa2a390baac,
1:08:25 wall/1521832KiB maxRSS. Reuse sealed exact-source Emscripten6.0.9 cache;
do not repeat the hour-long build unnecessarily. Never relabel old4.34 artifacts.

Separate genuine G3 compiler execution bundles run40158598464 PASSED:
artifact12585698132 ZIP
178106f3d9329cf3b4ba576110cb96b0790e62351bf8756e3fbab77720dd25be.
@proofscript/compiler-rust-linux-x64,12917609-byte tgz,
SHA551f150d09d98fe48312c40cdaa793522534c84fff250097199ff75b467530f7.
@proofscript/compiler-wasm,1370182-byte tgz,
SHA340b90eca1d08b1f20b4ca618358d7ac7b7931371f2232eb6aa54101099fcc83.
Their typed APIs return candidates only; no checking/publication authority.
Wasm executes on all five platforms, Rust on Linux x64/glibc.
Root CLI still uses embedded engine assets; optional bundle discovery is pending.

Native compiler platform run40157017833 also PASSED .lean/.ps source/admission
checks on Linux arm64/macOS x64+arm64/Windows x64 with SDK absent from PATH.
These are not full backend publication/npm release gates.

The latest integrated run also includes fresh offline global installation before
qualified artifact upload: eight builds/all engines/both grammars, native payloads
unavailable, prior output preserved and corrupt Wasm refused. It additionally
refuses four missing/conflicting root/generated policy declarations across three
commands (12 refusals), with a working native checker available. The assembled
package and global tests now finish in one run; do not create another input-only
commit just to repeat the same global qualification.

The final code/source regression run40161364575 PASSED at
`cd6a16ba1c9efc5668507ee6b9eb125f2d3b2fad`: full job121075449014 and final
gate121080510772,37/37 Practical Core criteria,0 blocked,seven backends/both
grammars, minimum Python and installed native npm/source libraries.
Tested merge`460a2f7057cd39bbc7489552ce2785c92c3de717` and branch HEAD have
identical tree`55cf04f9c8d50738f77cef82dded1e97478c6d3d`.
Full evidence artifact12586859725 ZIP SHA256
`48b75a7a58b25e145423c3584b54d2f5c296c91ab1c1a4930077a63f8275cd0d`.
This current source result supersedes pending/cancelled snapshots; all earlier
evidence remains historical. The installable integrated artifact remains the
separately qualified40161362270 package described above. Whole-toolchain final
cross-platform release is still incomplete.

## Execute next work in dependency order

1. Query live PR #179 normal source CI and the receipt's sourceRegression field.
   Code checkpointcd6a16ba is now fully passed in40161364575; check any newer HEAD.
   Finish every newly selected gate; carry failed/cancelled test debt forward.
   Parent55f9327e's37/37 and the package tests above cannot be substituted for a
   changed-source gate. Read completed logs to fix actual failures only.
   Preserve exact tested merge/head/tree identities in the receipt.
2. Implement portable transactional publication in a small coherent slice.
   Read host-tools/artifacts.mjs and generated-compiler-session.mjs first.
   Native publisher explicitly rejects non-Linux today; session symlink/current
   pointer and directory fsync are also Linux-oriented. Do not simply remove
   guards or ignore fsync/rename failures. Define a complete immutable-generation
   and atomic-current-pointer contract, retain no partial publication and prior
   output on every failure. Test actual installed Windows/macOS publication,
   concurrency, refusal/corruption and recovery in separate release jobs.
3. Complete slim universal root packaging using existing qualified JS/TS engines
   and mandatory Wasm kernel. No install-time compiler SDK/network builds.
   Add explicit optional Rust/Wasm/native execution bundle discovery with closed
   manifests, exact source/transport/executable pins and bounded supervision.
   Existing standalone bundles are the starting point; do not rewrite compilers
   or trust their returned candidates. Keep root's independent admission, both
   strict IR checks, source pairing and target validation before publication.
   Additional Rust platforms need genuine compiled payloads plus lifetime/
   memory/stack supervision equivalent to the Linux /proc guard.
   Root remains functional until replacement passes all acceptance criteria.
4. Add generated TS output publication using the existing checked emitter/runtime.
   --engine is the compiler executor; --target is emitted output.
   Current generated CLI publishes JS only. Require both grammars/all four engines,
   real pinned TS consumer observations, negatives/ABI refusal/tamper/prior-output
   preservation and no native compiler fallback.
5. Extend generated publication to Rust/Wasm core/component and optional
   Python/PHP providers through the same checked pipeline. Keep all seven mappings
   and frozen Practical Core capabilities. Finish actual offline local/global
   compilation/consumer tests on every supported final platform.
6. Perform required exact final source/package/platform qualification and clean
   reproduction only when source/package scope is ready. No merge or publication
   without explicit user authorization. Report incomplete boundaries candidly.

## Reuse prepared Linux qualification controllers

The committed input JSONs already contain REAL successful run/job/artifact/ZIP/
commit/tarball identities, not placeholders:
- scripts/kernel435-wasm-package-input.json
- scripts/kernel435-integrated-inputs.json
- scripts/kernel435-frozen-compiler-input.json
- scripts/compiler-execution-bundle-input.json
- scripts/kernel435-global-input.json (historical standalone replay; current package
  run executes global tests directly on its same-job tarball)

Read corresponding workflows before triggering; relevant input-only changes
activate existing Actions jobs. scripts/kernel435-qualified-artifact.mjs checks
exact source/job success/artifact SHA and bounded archive extraction. Do not
weaken its validation or use an unqualified candidate artifact as qualified.
Reuse assembled candidate tarballs for focused failure diagnosis; run the full
required installed checks before promoting a new root package.

Boundary tests40157932317 pass36 host checks,17 native publisher and10 Rust
transport regressions. Additional accepted provider there is a real native
reference; actual Wasm success comes from the package/integration tests above.
Keep resolved lock/null-reader failures and all older evidence in Git/receipts.

## Frozen semantic and resource boundary

One existing120-module compiler, source closure
07eedac1888aad3d4192664cea8d21a515d23985f3befd6cb365d0194fee53af.
All four genuine G1/G2/G3 and exact fixed points remain qualified, with120
cross-target cases and27 refusals per engine. Do not repeat successful long
chains for package/docs-only edits. Do not promote the isolated lexer31e10263
without new-root qualification.

Official Lean4.35.0 commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc,
trustlevel0/finite2000000-heartbeat/20000-recursion, strict original/transformed IR,
exact source/logical pairing, negative tests, semantic fuel, memory/stack and
unsupported-ABI refusals stay mandatory. Kernel Wasm remains official C++
Emscripten linear memory; compiler Wasm retains its existing GC architecture.
G1/tools/corpus240s, checker120s unchanged; original1800s correctness and240s
performance remain separate; Rust-only3600s is G2/G3 compiler requests only.

Update the one roadmap, AI_WORK_STATE.md and exact qualification receipt with
actual terminal evidence. Optimize development throughput through existing
dependency-selected CI; do not hide failed debt or repeat successful audits.
