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

Integrated code `3c9fae34d8a8912cce638777611942327b67ca35`:
run40160064167/job121069555210 SUCCESS.
Seven-tarball artifact12585887196 ZIP SHA256
064d226b8dcc9d5275f801b6ed9791519f053b1ae3e80a04fe804c798357261a.
Inside: kernel435-core/tarballs/proofscript-0.1.0-psc1.3.tgz,
62180617 bytes, SHA256
b2bf12d1d05c1f92361893411d761ff7b1418117f0e06c9985856768616b9346.
This candidate is installable on Linux x64/glibc, default genuine Wasm checker,
with20 compiler cases,24 app builds/88 observations,24 refusal/tamper cases,
eight explicit dual checks, two native staged-publication checks and installed
public types all passed. Native compiler and checker are unavailable in default
generated cases; no native fallback. BOTH actual kernels also accept the exact
frozen compiler graph in6222ms combined; fullGenerationReplayed=false.

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

## Execute next work in dependency order

1. Query live PR #179 normal source CI and the receipt's sourceRegression field.
   Finish every selected gate; carry failed/cancelled test debt forward.
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
- scripts/kernel435-global-input.json

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
