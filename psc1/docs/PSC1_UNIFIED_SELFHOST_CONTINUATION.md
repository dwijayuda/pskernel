# Continue PSC1 after unified four-engine self-host qualification

Use connected GitHub tools/cloud CI only; routine development stays Linux and separate final release builds/tests cover macOS and Windows. Fetch fresh PR #178
and branch `feat/psc1-unified-selfhost-20261024`; inspect actual final CI before
writes. Preserve history with expected-HEAD, single-parent non-force commits.
No local repository checkout/files/builds/tests, merge or registry publication.

Read `psc1/AI_WORK_STATE.md`, `docs/PSC1_DEVELOPMENT_ROADMAP.md`,
`docs/PSC1_UNIFIED_FOUR_ENGINE_QUALIFICATION_2026-10-25.json`,
`docs/PSC1_GENERATED_PACKAGE_QUALIFICATION_2026-10-25.json`, and the install guide.

The compiler source is frozen at implementation daa73501, 120 modules, closure
07eedac1888aad3d4192664cea8d21a515d23985f3befd6cb365d0194fee53af.
All four execution engines PASS genuine independently admitted G1/G2/G3 and
exact source/admission/original+specialized IR/raw-executable/four-output fixed
points (120 cross-target cases and27 refusals per engine).
Rust request2d27f142/run40141718481/job121014751809; JS/TS/Wasm request0cabb7ed/
run40147825207/jobs121032956240,121032956267,121032956320.
Immutable readbacks40147896149(Rust),40152095695(JS),40151632228(TS),
40151056584(Wasm) pass all source/admission/IR/executable inventories.

| Engine | G2/G3 request ms | Service maxRSS KiB (G2/G3) |
| --- | --- | --- |
| JS | 1621212 / 1656073 | 3568508 / 3496952 |
| TS | 1453401 / 1411839 | 3437396 / 3466012 |
| Rust | 2139961 / 2160767 | 1197260 / 1197296 |
| Wasm | 1090090 / 1091869 | 2904948 / 2719740 |

Do not repeat these successful frozen chains for documentation milestones.
A clean full-chain replay, formal compiler-preservation/DDC and performance240s
are separate unfinished claims. Preserve exact source-specific earlier
JS/TS/Rust/Wasm/Python/PHP successes and failures.

Package implementation55f9327ee738b5b2bf5d623c96280cb97de828b2 integrates all four
qualified G3 engines. Candidate40152198370 passes20 compiler cases,
24 application builds/88 observations and26 negatives, both grammars and real
7/9-module JSON/CLI sources with native compiler unavailable.
Fresh40152578991 passes16 local/global builds without checkout/build tree or
compiler SDK/Python on execution PATH, including explicit matching optional
Python/PHP installs. The Node-only Rust guard retains ten lifetime/integrity tests.
Production55f9327ee738b5b2bf5d623c96280cb97de828b2 PASSED package40152769340/job121047594235 (20 compiler cases,24 application builds/88 observations,26 negatives) and full40152772905/job121049906606/final gate121055266402 (37/37 criteria,0 blocked,seven backends,both grammars). Tested mergef9713323bb3beed393255ff755da3dd2023febdc shares treed884c41c8097ac59c91081f019481f60625ba793 with review55. Production artifact12582649787 ZIPda6a88220337c601fcf401ea7e06a55c45988f96c0a5692d28e958ed07c61916, core29a837faedaabb8c7e6ae30cec19ac53680084b5188de0eef2b7eabbd4f09198. Full artifact12583743977 ZIP8b10c96a59fab176c0cf7dcc967720c8384870d97745859f0a3a99a71cc17194. All package artifacts remain unpublished.

## Active kernel and platform integration mission

Latest development continues on `integration/psc1-lean435-kernel-packages-20261025`,
branched from qualified55f9327e. Routine development is Linux-only. The user
explicitly requested final native macOS/Windows builds and installed release tests;
those run in a separate release matrix. No merge or npm publication is authorized.

Both existing kernel packages are being upgraded to official Lean4.35.0/current
canonical admissions v2. The official C++ Wasm checker remains Emscripten linear
memory, separate from PSC1's Wasm backend. Archive branch0408f18b established the
slim kernel-only initialization/narrow-import/-Os/remove-unused-Lake strategy.
Current25-module provider closure retains all finite kernel checks and semantic
bodies. Linux x64/arm64 run40154010946 PASS14 real reference-parity cases and
standalone execution; raw binaries4079232/4160016 bytes. macOS x64/arm64 jobs
121053490973/121053490842 in40154709416 PASS equivalent gates,2771584/2798528 bytes.
That matrix's overall failure is Windows setup, not a macOS success override.
Windows-only retry40155170697 is active after fixing Bash-path export to native
Elan PATH. Linear Wasm build40154206987 is active at630fa363; do not restart it.
No new4.35 npm package or full cross-platform toolchain is qualified yet.

Next: assemble only pinned successful artifacts, match exact25-module source
closure, pack and install offline locally/globally, execute public API acceptance/
rejection/tamper tests on every platform; finish actual linear Wasm differential
checking and package integration before claiming release readiness. Preserve
qualified120-module compilers and all four G3 artifacts. Whole toolchain platform
selection/native compiler/Rust executable transport and generated output parity
remain separate release blockers. See scripts/kernel435-* and kernel435 workflows.

After the kernel/platform mission, complete generated publication coverage without duplicating compiler or
admission implementations. Current `psc generated build --engine js|ts|rust|wasm-core`
publishes independently admitted JS. Native `psc build` retains JS/TS/Rust/Wasm
core/component plus optional Python/PHP. Engine selection is independent from
the requested output target. Do not turn allFourEngineSelfHostQualified into an
unbounded release claim; final release and other generated outputs remain open.

Start a dependency-coherent host-boundary slice for generated TS publication:
- Inspect `npm-cli/generated.mjs`, `scripts/npm-generated-distribution.mjs`,
  `host-tools/generated-compiler-session.mjs`, and
  `host-tools/generated-target-tools.mjs`. The existing session has JS-specific
  closed candidate fields, checker target, syntax/API checks, stage filenames
  and transactional publication; preserve every boundary.
- Generalize shared host admission/publication only as needed; retain the JS API
  and avoid a second handwritten frontend/elaborator/compiler.
- Select output target from trusted CLI/host configuration, never from generated
  tool selectors. Keep exact captured sources and original/transformed strict IR,
  official independent admission before target publication, imported-file pins,
  bounded execution and refusal priority.
- Require all four installed engines to compile both grammars through TS output;
  run an independent pinned TypeScript consumer, equivalent JS observations,
  malformed-candidate/IR/target/ABI/tamper tests and preservation of prior output.
  Native compiler must remain disabled during generated compilation.
- Then add generated Rust and owned Wasm output validation through existing
  target tooling, component/typed IO adapters and optional-provider dispatch.
  Keep unsupported ABIs explicit; source packages cannot grant kernel/FFI/host
  authority. Complete all seven relevant mappings before declaring parity.

Preserve official Lean4.35.0 at eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
G1/corpus/tools240s and checker120s remain unchanged. Separate Rust-only
correctness3600s changes G2-self/G3-self only (190-minute job/170-minute step);
JS/TS/Wasm pass unchanged1800s. Original1800s and performance240s stay separate.
Semantic fuel, memory/stack, source/logical pairing, strict IR, negative tests
and all unsupported-ABI refusals remain required.

The measured Nat constructor/immutable borrowing/dependency optimization is
promoted. Main Rust crate staysopt0/256; numeric dependenciesopt3.
Rejected LLVM experiments retain real build deadlines/verification failures;
do not bypass them. An unpromoted lexer candidate remains on
optimization/psc1-lexer-string-suffix-20261025, code31e10263/state39f38d64.
Run40143764706 proves forall-input original-wrapper equality, retains320
comparisons/100001 tokens per grammar, both120-module censuses and admitted
real-file/malformed/Unicode Rust lexer observations. Stage-only gains
CheckedAdmissions4039→439ms/Rust.Expr3001→341ms are not whole-G2 speedup.
Use it later only with focused/full regressions and genuine changed-root
qualification, never by transferring frozen-root evidence.

Keep Practical Core v1 frozen at14 families/37 criteria; PSKernel-Core research
continues independently of compiler development and does not replace Lean
admission. Maintain one roadmap, exact receipts, AI_WORK_STATE.md and package
commands. Final source/package qualification and explicit authorization are
required before merge or npm publication.
