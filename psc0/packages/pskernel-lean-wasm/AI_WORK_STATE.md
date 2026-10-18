# Linear-memory PSKernel-Lean-Wasm work state

Branch: feature/psc0-v72-pskernel-lean-wasm-linear-v1
Base: psc0/pscv0-v7-native-lean-v1 at
33676076bcda7b0de5ec1f9803f49b8b1d28a058
Lean: 4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc
Language: PSCV0 v7.2.
Kernel: official Lean C++ via Emscripten, wasm32 **linear memory**.
Compiler: current native PSC0 packages. No duplicated PSC2 source.
Previous wasm-gc experiment remains preserved on separate branch.
No VSIX work.

Checkpoint: Native Lean 4.35.0 PSC0 v7.2 admission endpoint GREEN, live
128-module provider closure GREEN, official wasm32 C++ kernel archives GREEN.
Full linked Wasm provider and native/Wasm parity NOT YET QUALIFIED.
Not qualified until real Linux cloud build, positive/negative differential
kernel checks, and byte-identical checked prebuilt manifest are green.
Wasm runtime and independent kernel equivalence must not be inferred from
successful source or host-only tests.

Immediate next: inspect workflow execution, repair verified toolchain/ABI
failures without bypassing any check, stage actual Lean 4.35 Wasm bytes.
Then expand conformance to full Standard and Lean Arena; benchmark startup,
memory, real declaration workload. Never publish an unchecked artifact.

## 2026-10-18: Stage1 wasm32 runtime blocker

CI #39122290519: source closure, Elan, Emscripten, i386 bootstrap and stage1 libc/uv progressed; compilation failed at `src/runtime/uv/system.cpp` no-libuv `lean_uv_os_get_group` signature mismatch against its header. This is the *first real* C++ stage1 error, not a parity failure. The exact narrow fallback signature fix and an early upstream-runtime source preflight have been prepared. The complete wasm kernel remains unbuilt and unqualified until Linux CI plus native/Wasm differential tests pass. No VSIX work.

## 2026-10-18: Exact native kernel admission now qualified

- Native [CI #39137531241](https://github.com/dwijayuda/pskernel/actions/runs/39137531241) and repeat [#39138054992](https://github.com/dwijayuda/pskernel/actions/runs/39138054992) passed all 11 official Lean 4.35.0 PSC0 v7.2 canonical admission cases, including valid Nat, unknown constant, ill-typed definition and opaque body, theorem not a Prop, duplicate index 1, malformed JSON, protocol violation, and unauthorized axiom refusal. These are actual kernel judgments, not mocked host tests.
- Earlier [CI #39136164227](https://github.com/dwijayuda/pskernel/actions/runs/39136164227) exposed deterministic-timeout on admission 0 even for a valid Nat definition; this was fixed via PSC0's established `IO.lazyPure` + `IO.asTask` fresh-counter evaluation boundary without disabling finite kernel checking budgets.
- Single-threaded Emscripten task behavior additionally requires the exact, pinned native-equivalent `reset_heartbeat()` C++ fallback. [#39138055063](https://github.com/dwijayuda/pskernel/actions/runs/39138055063) passed its source compatibility preflight. **This is not yet a runtime Wasm verification.**
- Strict per-case semantic-rejection parity is merged into the admission-integration branch from PR #147; a `deterministic-timeout` is not accepted as a negative proof result.
- The shared 11-case suite is currently an **admission-smoke** gate only. It cannot establish full Lean 4.35/PSC0 v7.2 parity or production readiness.

## 2026-10-18: Wasm build and acceleration evidence

- [CI #39129247395](https://github.com/dwijayuda/pskernel/actions/runs/39129247395) built real wasm32 `libleanrt.a` and `libleancpp_1.a` (the official C++ kernel plus required C++ library objects). This does not yet prove final provider linking.
- [CI #39128469062](https://github.com/dwijayuda/pskernel/actions/runs/39128469062) checked 149 exported C++ ABI definitions in the eight libuv runtime modules.
- Main full-kernel CI [#39128012190](https://github.com/dwijayuda/pskernel/actions/runs/39128012190) was still cross-building at the last verified check (commit `6713d423e3a498b1c2ab5b4085e71fd4e15c58bb`). Do not infer a linked, runnable or checked Wasm from this in-progress state.
- Draft PR #146 contains the verified native provider, shared 11-case admission corpus, exact-source patch, and **explicitly unqualified** build-only artifact staging. A full Wasm release still requires actual startup and native/Wasm admission parity.
- Draft PR #148 prepares SHA-256-sealed i386/wasm32 stage1 cache reuse, with synthetic tamper/invalidation tests green in [#39139918437](https://github.com/dwijayuda/pskernel/actions/runs/39139918437). Real cross-build reuse has **not** yet been validated.
- An independent [1205-definition dependent-batch test](https://github.com/dwijayuda/pskernel/actions/runs/39139830084) is underway. It matches the old provider's admission *count*, not the complexity or 9.9 MB size of the historical compiler workload; do not claim it replaces the original compiler regression.

## Critical path — do not bypass

1. Inspect full build #39128012190 to its terminal result and fix any actual stage1/module C/link or runtime initialization failure on the isolated feature branch.
2. Merge reviewed fixes from admission PR #146 after preserving current full-build artifacts; then require an exact-SHA end-to-end Linux C++→Wasm build.
3. Compare accepted and rejected declarations with the **same official Lean 4.35.0 native checker** under the complete current PSC0 Standard, including *semantic* rejection reasons, never timeouts.
4. Confirm Emscripten `.wasm` has linear memory, valid SHA-256, correct versioned source/toolchain identity, and file-backed JSON input. Distinguish `admission-smoke` from broad production qualification.
5. Preserve compiler branch and PR #109; no PSC0 native compiler source changes, no VSIX, no Wasm GC kernel promotion, no unchecked kernel admissions. Record real CI evidence before claiming readiness.
