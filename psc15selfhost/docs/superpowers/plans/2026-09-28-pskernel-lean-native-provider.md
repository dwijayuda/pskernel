# PSC2 Lean 4.34 Native Kernel Provider Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `psc15selfhost/packages/pskernel-lean` a usable native Lean 4.34 kernel provider and gate `psc build ... --kernel lean434` on real Lean kernel admission without adding Lean to the PSC2 fixed-point closure.

**Architecture:** Add an optional Lean executable target to the existing `psc15selfhost` Lake project. The provider starts from `Lean.mkEmptyEnvironment` at trust level 0, translates the provider-owned `psSelfHostProdPreludeEnvironment` into Lean kernel declarations, admits that prelude through the real Lean 4.34 kernel, decodes the existing canonical admissions v2 JSON for the user module, and admits those declarations through `Lean.Environment.addDeclCore`. A Node adapter invokes the native executable only when `--kernel lean434` is requested; the ordinary fixed-point path remains unchanged.

**Tech Stack:** Lean 4.34.0, Lean kernel API (`Lean.Environment`, `Lean.Declaration`, `addDeclCore`), existing PSC1-compatible Lean core definitions, Node.js ESM host tooling, Lake, npm scripts.

**Spec:** `psc15selfhost/docs/superpowers/specs/2026-09-28-pskernel-lean-provider-design.md`

## Global Constraints

- Keep `pskernel-lean` forbidden from the minimal PSC2 bootstrap/fixed-point import closure.
- Pin provider semantics to `leanprover/lean4:v4.34.0`; do not accept a different Lean version silently.
- Start kernel checking from `Lean.mkEmptyEnvironment 0`; do not use the ambient imported `Init` environment as the PSC2 checked environment.
- Reconstruct the PSC2 provider-owned prelude from `psSelfHostProdPreludeEnvironment`; do not accept a caller-supplied prelude.
- Admit declarations through the real Lean checked kernel path; do not imitate kernel type checking in host JavaScript or provider glue.
- Reuse canonical admissions format `proofscript-checked-admissions`, version `2`, for module input.
- Do not translate PSC source to `.lean` source for verification.
- Fail closed on malformed input, unsupported forms, provider/version mismatch, missing binary, provider crash, unparseable response, or kernel rejection.
- Keep upstream copied `kernel/`, `runtime/`, and `util/` sources semantically untouched in this plan.
- Do not claim full Lean 4 equivalence from this provider integration.
- This plan implements KLP0-KLP3 (native provider through PSC2 host integration). KLP4 differential assurance and KLP5 WASM packaging are follow-up plans after the native seam is green.

## Review Focus

- Prelude declaration order: rebuilding the cons-based `PsEnvironment.declarations` in the wrong order must fail tests instead of silently creating a different environment; Task 2 pins chronological replay.
- Inductive duplication: PSC stores inductive, constructor, and recursor metadata separately, but Lean kernel admission generates constructor/recursor constants from the inductive block; Task 2 tests that constructor/recursor metadata is not admitted twice.
- Canonical protocol confusion: `version` is numeric `2`, names are structured JSON objects, and definition heights are strings inside hints; Task 3 tests exact accepted and rejected shapes.
- Host/provider split failure: default `psc build` and all fixed-point commands must work with no provider binary present; Task 6 and Task 7 test that `lean434` is the only path that requires the binary.
- Provider output spoofing/crash: empty output, malformed JSON, wrong protocol/provider/version, non-zero exit, and `accepted:false` must all stop emission; Task 5 tests every class.

---

## File Structure

### Provider-owned Lean code

- Create `psc15selfhost/packages/pskernel-lean/provider/PsKernelLean/Error.lean` — stable provider error taxonomy and JSON error-kind names.
- Create `psc15selfhost/packages/pskernel-lean/provider/PsKernelLean/Convert.lean` — `PsName`/`PsLevel`/`PsExpr` conversion and PSC declaration-to-Lean declaration conversion.
- Create `psc15selfhost/packages/pskernel-lean/provider/PsKernelLean/Prelude.lean` — trust-level-0 environment construction and PSC2 prelude replay.
- Create `psc15selfhost/packages/pskernel-lean/provider/PsKernelLean/Protocol.lean` — canonical admissions v2 JSON decoding and deterministic response encoding.
- Create `psc15selfhost/packages/pskernel-lean/provider/PsKernelLean/Check.lean` — sequential real-kernel admission of decoded module declarations.
- Create `psc15selfhost/packages/pskernel-lean/provider/PsKernelLean/Main.lean` — stdin/stdout native provider executable, `--health`, and `--version`.
- Create `psc15selfhost/packages/pskernel-lean/provider-test/PsKernelLeanTests.lean` — Lean-side provider unit/conformance tests.

### Host integration

- Create `psc15selfhost/packages/pskernel-lean/js/provider.mjs` — fail-closed process adapter for native provider.
- Create `psc15selfhost/packages/pskernel-lean/scripts/provider-process-fixture.mjs` — deterministic fake provider used by Node adapter tests.
- Create `psc15selfhost/packages/pskernel-lean/scripts/provider-adapter-tests.mjs` — Node tests for process/output/error handling.
- Create `psc15selfhost/packages/pskernel-lean/scripts/provider-native-smoke.mjs` — optional smoke test against the built native provider.
- Modify `psc15selfhost/packages/backend-ts/src/Ps/BackendTs/Compiler.lean` — expose a stable canonical-admissions API for generated compilers without importing provider code.
- Modify `psc15selfhost/scripts/compile-with-generated.mjs` — optional kernel-gating stage before emission.
- Modify `psc15selfhost/packages/cli/bin/psc.mjs` — parse/pass `--kernel none|lean434` for `psc build`.
- Modify `psc15selfhost/package.json` — optional build/test scripts; do not add provider to `fixed-point`, `bootstrap`, or default `check` gates.
- Modify `psc15selfhost/lakefile.lean` — non-default provider library/executables only.

### Documentation

- Create `psc15selfhost/packages/pskernel-lean/README.md` — purpose/status/quick commands/provenance.
- Create `psc15selfhost/packages/pskernel-lean/BUILDING.md` — native build and troubleshooting instructions.
- Create `psc15selfhost/packages/pskernel-lean/INTEGRATION.md` — protocol, host boundary, trust/prelude policy, and follow-up WASM seam.

---

### Task 1: Establish the optional Lean 4.34 provider target and version/health protocol

**Files:**
- Modify: `psc15selfhost/lakefile.lean`
- Create: `psc15selfhost/packages/pskernel-lean/provider/PsKernelLean/Error.lean`
- Create: `psc15selfhost/packages/pskernel-lean/provider/PsKernelLean/Protocol.lean`
- Create: `psc15selfhost/packages/pskernel-lean/provider/PsKernelLean/Main.lean`
- Create: `psc15selfhost/packages/pskernel-lean/provider-test/PsKernelLeanTests.lean`

**Interfaces:**
- Consumes: parent toolchain `leanprover/lean4:v4.34.0`.
- Produces: Lake library `PsKernelLeanProvider`; executables `psc2_lean_kernel_provider` and `psc2_lean_kernel_provider_tests`; constants `providerProtocol = "pskernel-lean/1"`, `providerName = "lean4-cpp"`, `providerVersion = "4.34.0"`, `providerProfile = "lean4.34-core"`.

- [ ] **Step 1: Add the failing Lake/provider metadata test**

In `PsKernelLeanTests.lean`, assert the four exact constants above and assert that the declared expected Lean version is `4.34.0`.

- [ ] **Step 2: Run the test target before implementation**

Run from `psc15selfhost`:

```bash
lake build psc2_lean_kernel_provider_tests
```

Expected: FAIL because the provider target/modules do not exist.

- [ ] **Step 3: Add non-default Lake targets and minimal protocol/error modules**

Add `lean_lib PsKernelLeanProvider` with `srcDir := "packages/pskernel-lean/provider"`, `lean_exe psc2_lean_kernel_provider`, and `lean_exe psc2_lean_kernel_provider_tests`. Do not mark the provider as a default target.

Define `PsKernelLeanErrorKind` with stable cases needed by the spec: `protocolVersion`, `malformedRequest`, `unsupportedCoreForm`, `preludeMismatch`, `providerVersionMismatch`, `kernelRejection`, `providerInternalError`.

- [ ] **Step 4: Implement `--version` and `--health` only**

`PsKernelLean.Main` must print deterministic JSON containing protocol/provider/version/profile and exit successfully for these two flags. Normal stdin checking can return a fail-closed `provider-internal-error` placeholder until Task 4.

- [ ] **Step 5: Run provider metadata tests and direct commands**

Run:

```bash
lake exe psc2_lean_kernel_provider_tests
lake exe psc2_lean_kernel_provider -- --version
lake exe psc2_lean_kernel_provider -- --health
```

Expected: tests PASS; both commands emit valid JSON identifying `pskernel-lean/1`, `lean4-cpp`, `4.34.0`, `lean4.34-core`.

- [ ] **Step 6: Commit**

```bash
git add psc15selfhost/lakefile.lean psc15selfhost/packages/pskernel-lean/provider psc15selfhost/packages/pskernel-lean/provider-test
git commit -m "feat(psc2): add Lean 4.34 kernel provider target"
```

### Task 2: Translate PSC Core and rebuild the pinned PSC2 prelude in a trust-level-0 Lean environment

**Files:**
- Create: `psc15selfhost/packages/pskernel-lean/provider/PsKernelLean/Convert.lean`
- Create: `psc15selfhost/packages/pskernel-lean/provider/PsKernelLean/Prelude.lean`
- Modify: `psc15selfhost/packages/pskernel-lean/provider-test/PsKernelLeanTests.lean`

**Interfaces:**
- Consumes: `PsName`, `PsLevel`, `PsExpr`, `PsDeclaration`, `psSelfHostProdPreludeEnvironment`.
- Produces:
  - `toLeanName : PsName -> Lean.Name`
  - `toLeanLevel : PsLevel -> Except PsKernelLeanError Lean.Level`
  - `toLeanExpr : PsExpr -> Except PsKernelLeanError Lean.Expr`
  - `toLeanPreludeDeclaration : List PsDeclaration -> PsDeclaration -> Except PsKernelLeanError (Option Lean.Declaration)`
  - `buildLeanPreludeEnvironment : IO (Except PsKernelLeanError Lean.Environment)`

- [ ] **Step 1: Write conversion tests for every supported Core constructor**

Cover anonymous/string/numeric names; universe `zero/succ/max/imax/param`; `bvar/sort/const/app/lam/forall/let/nat/string/proj`; binder-info preservation; and rejection of `fvar`/`mvar`/universe metavariables.

- [ ] **Step 2: Write prelude-order and inductive-deduplication tests**

Assert that `buildLeanPreludeEnvironment` finds required PSC bootstrap constants such as `Nat`, `Nat.zero`, `Nat.succ`, `List`, `Option`, `Except`, and `Prod`; assert that constructor/recursor metadata is not re-added after its parent inductive block; assert the environment was created at trust level 0.

- [ ] **Step 3: Run tests to verify the new cases fail**

Run:

```bash
lake exe psc2_lean_kernel_provider_tests
```

Expected: FAIL on missing conversion/prelude functions.

- [ ] **Step 4: Implement pure Core conversion**

Map PSC semantic nodes directly to `Lean.Name`, `Lean.Level`, and `Lean.Expr`; do not invoke Lean parser or elaborator APIs.

- [ ] **Step 5: Implement declaration/prelude replay**

Reverse `psSelfHostProdPreludeEnvironment.declarations` into chronological admission order. Convert/admit axioms, definitions, theorems, opaque declarations if present, and parent inductive blocks. Return `none` for standalone `.constructorDecl` and `.recursorDecl` metadata because the corresponding Lean inductive admission owns those generated constants. Treat unsupported/unsafe/partial forms as fail-closed errors unless a current prelude fixture proves they are required and a Lean-faithful mapping is implemented.

Use `Lean.mkEmptyEnvironment 0` and `Lean.Environment.addDeclCore` with finite explicit heartbeat/recursion limits. Never call an unchecked-add path.

- [ ] **Step 6: Run tests**

Run:

```bash
lake exe psc2_lean_kernel_provider_tests
```

Expected: PASS for conversion and prelude reconstruction.

- [ ] **Step 7: Commit**

```bash
git add psc15selfhost/packages/pskernel-lean/provider/PsKernelLean/Convert.lean psc15selfhost/packages/pskernel-lean/provider/PsKernelLean/Prelude.lean psc15selfhost/packages/pskernel-lean/provider-test/PsKernelLeanTests.lean
git commit -m "feat(psc2): rebuild PSC prelude in Lean kernel"
```

### Task 3: Decode canonical checked-admissions v2 directly into Lean declarations

**Files:**
- Modify: `psc15selfhost/packages/pskernel-lean/provider/PsKernelLean/Protocol.lean`
- Modify: `psc15selfhost/packages/pskernel-lean/provider/PsKernelLean/Convert.lean`
- Modify: `psc15selfhost/packages/pskernel-lean/provider-test/PsKernelLeanTests.lean`

**Interfaces:**
- Consumes: canonical object `{ "admissions": [...], "format": "proofscript-checked-admissions", "version": 2 }` produced by `Ps.Bridge.CheckedAdmissions`.
- Produces: `decodeCanonicalAdmissions : String -> Except PsKernelLeanError (Array Lean.Declaration)`.

- [ ] **Step 1: Add exact protocol-shape tests**

Positive fixtures must cover one definition, one theorem, and one inductive admission. Tests must assert support for structured names, binder info, definition regular-height hints, and inductive constructor arrays.

- [ ] **Step 2: Add fail-closed protocol tests**

Reject: wrong/missing `format`, version other than numeric `2`, non-array `admissions`, unknown admission `kind`, malformed structured name, malformed level/expr tag, free/metavariable tags if manually injected, malformed definition hint height, and unsupported constant declaration kind.

- [ ] **Step 3: Run tests and observe failure**

Run:

```bash
lake exe psc2_lean_kernel_provider_tests
```

Expected: FAIL on missing decoder.

- [ ] **Step 4: Implement deterministic JSON decoding**

Use Lean JSON facilities only as a parser. Decode directly to semantic Lean values; never round-trip through Lean source syntax. Preserve declaration order from the `admissions` array.

- [ ] **Step 5: Run tests**

Run:

```bash
lake exe psc2_lean_kernel_provider_tests
```

Expected: PASS for exact protocol and malformed-input cases.

- [ ] **Step 6: Commit**

```bash
git add psc15selfhost/packages/pskernel-lean/provider/PsKernelLean/Protocol.lean psc15selfhost/packages/pskernel-lean/provider/PsKernelLean/Convert.lean psc15selfhost/packages/pskernel-lean/provider-test/PsKernelLeanTests.lean
git commit -m "feat(psc2): decode canonical admissions for Lean kernel"
```

### Task 4: Admit module declarations through the real Lean 4.34 kernel and expose stdin/stdout checking

**Files:**
- Create: `psc15selfhost/packages/pskernel-lean/provider/PsKernelLean/Check.lean`
- Modify: `psc15selfhost/packages/pskernel-lean/provider/PsKernelLean/Main.lean`
- Modify: `psc15selfhost/packages/pskernel-lean/provider-test/PsKernelLeanTests.lean`

**Interfaces:**
- Consumes: `buildLeanPreludeEnvironment`, `decodeCanonicalAdmissions`.
- Produces:
  - `checkCanonicalAdmissions : String -> IO PsKernelLeanResponse`
  - native executable contract: canonical admissions JSON on stdin, exactly one deterministic response JSON object on stdout.

- [ ] **Step 1: Add positive kernel-admission tests**

Construct canonical v2 admissions whose declarations are well-typed against the reconstructed PSC prelude; assert `accepted = true` and exact provider metadata.

- [ ] **Step 2: Add semantic negative tests that pass JSON shape validation**

Include at least: definition body with wrong declared type, invalid function application, universe/type mismatch, theorem proof with wrong type, and invalid inductive constructor type. Assert `accepted = false` with `errorKind = "kernel-rejection"`.

- [ ] **Step 3: Run tests and verify failure before checker implementation**

Run:

```bash
lake exe psc2_lean_kernel_provider_tests
```

Expected: FAIL on missing checker/admission behavior.

- [ ] **Step 4: Implement sequential checked admission**

For each decoded declaration, call the Lean 4.34 checked environment API (`addDeclCore` semantics) on the current environment and carry the returned environment forward. Record the zero-based declaration index on rejection. Provider/internal exceptions must become deterministic fail-closed response objects.

- [ ] **Step 5: Wire stdin/stdout Main**

With no flag, read stdin to EOF, invoke `checkCanonicalAdmissions`, write one JSON response plus newline to stdout, and use exit code 0 for a well-formed provider response whether accepted or kernel-rejected. Use non-zero exit only for process-level catastrophic failures that prevented a response.

- [ ] **Step 6: Run Lean tests and manual stdin smoke**

Run:

```bash
lake exe psc2_lean_kernel_provider_tests
printf '%s\n' '<known-valid-canonical-admissions>' | lake exe psc2_lean_kernel_provider
```

Expected: tests PASS; smoke emits `accepted:true`.

- [ ] **Step 7: Commit**

```bash
git add psc15selfhost/packages/pskernel-lean/provider/PsKernelLean/Check.lean psc15selfhost/packages/pskernel-lean/provider/PsKernelLean/Main.lean psc15selfhost/packages/pskernel-lean/provider-test/PsKernelLeanTests.lean
git commit -m "feat(psc2): admit canonical core with Lean kernel"
```

### Task 5: Add the fail-closed Node native-provider adapter

**Files:**
- Create: `psc15selfhost/packages/pskernel-lean/js/provider.mjs`
- Create: `psc15selfhost/packages/pskernel-lean/scripts/provider-process-fixture.mjs`
- Create: `psc15selfhost/packages/pskernel-lean/scripts/provider-adapter-tests.mjs`
- Create: `psc15selfhost/packages/pskernel-lean/scripts/provider-native-smoke.mjs`
- Modify: `psc15selfhost/package.json`

**Interfaces:**
- Consumes: canonical admissions JSON string.
- Produces:
  - `runLean434KernelProvider(canonicalAdmissions, options?) -> PsKernelLeanResult`
  - options permit test injection of `{ command, args }`; production default resolves `PSC_LEAN_KERNEL_PROVIDER` first, otherwise `.lake/build/bin/psc2_lean_kernel_provider` (with `.exe` on Windows).
  - accepted result is returned; every unavailable/crash/malformed/rejected result throws a stable `PSC2_LEAN_KERNEL_*` error.

- [ ] **Step 1: Write adapter tests using the fake process fixture**

Cover accepted response, `accepted:false`, wrong protocol, wrong provider, wrong version, malformed JSON, empty stdout, non-zero exit, missing executable, and extra stdout garbage. Assert every non-accepted condition throws and never returns success.

- [ ] **Step 2: Run Node tests and verify failure**

Run:

```bash
node packages/pskernel-lean/scripts/provider-adapter-tests.mjs
```

Expected: FAIL because adapter/fixture do not exist.

- [ ] **Step 3: Implement process adapter**

Use `spawnSync` with canonical JSON on stdin, UTF-8 output, bounded output size, and no shell. Validate exact protocol/provider/version/profile fields before trusting `accepted`.

- [ ] **Step 4: Add optional npm scripts**

Add:

```text
build:kernel-lean -> lake build psc2_lean_kernel_provider
test:kernel-lean:unit -> lake exe psc2_lean_kernel_provider_tests
test:kernel-lean:adapter -> node packages/pskernel-lean/scripts/provider-adapter-tests.mjs
test:kernel-lean:smoke -> node packages/pskernel-lean/scripts/provider-native-smoke.mjs
test:kernel-lean -> unit + adapter + smoke
```

Do not add these scripts to `bootstrap`, `fixed-point`, or default `check`.

- [ ] **Step 5: Run adapter and native smoke**

Run:

```bash
npm run build:kernel-lean
npm run test:kernel-lean:adapter
npm run test:kernel-lean:smoke
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add psc15selfhost/packages/pskernel-lean/js psc15selfhost/packages/pskernel-lean/scripts psc15selfhost/package.json
git commit -m "feat(psc2): add Lean kernel host adapter"
```

### Task 6: Gate PSC2 builds on Lean kernel admission with `--kernel lean434`

**Files:**
- Modify: `psc15selfhost/packages/backend-ts/src/Ps/BackendTs/Compiler.lean`
- Modify: `psc15selfhost/scripts/compile-with-generated.mjs`
- Modify: `psc15selfhost/packages/cli/bin/psc.mjs`
- Create: `psc15selfhost/packages/pskernel-lean/scripts/psc-build-kernel-tests.mjs`

**Interfaces:**
- Consumes: generated compiler and `runLean434KernelProvider`.
- Produces:
  - portable compiler API `psCompilerKernelAdmissionsSource (sourceKind : PsCompilerSourceKind) (source : String) : Except PsCompilerError String` forwarding to canonical admissions generation.
  - CLI `psc build <entry> --out <output> [--compiler <compiler>] [--kernel none|lean434]`.
  - default kernel mode remains `none` for bootstrap/fixed-point compatibility in this milestone.

- [ ] **Step 1: Add a generated-compiler API test**

Extend the existing bootstrap/compiler tests or the new kernel integration test to assert generated compiler JS exposes `psCompilerKernelAdmissionsSource` and returns canonical admissions with `format = "proofscript-checked-admissions"` and `version = 2`.

- [ ] **Step 2: Add CLI/compile integration tests**

Using an injected fake provider, assert: `--kernel none` never invokes the provider; `--kernel lean434` checks admissions before TypeScript emission; provider rejection prevents output creation; unknown kernel mode fails; omitted flag preserves current behavior.

- [ ] **Step 3: Run tests before implementation**

Run:

```bash
node packages/pskernel-lean/scripts/psc-build-kernel-tests.mjs
```

Expected: FAIL because kernel CLI mode/API do not exist.

- [ ] **Step 4: Add the portable admissions forwarding API**

In `Ps.BackendTs.Compiler`, define the exact forwarding function named `psCompilerKernelAdmissionsSource`; it must contain no host/provider imports and remain PSC1-compatible.

- [ ] **Step 5: Integrate kernel mode into generated compilation host**

In `compile-with-generated.mjs`, after project flattening and before `psCompilerTypeScriptSource`, request canonical admissions only when `kernelMode === "lean434"`, invoke `runLean434KernelProvider`, and abort on any thrown provider error. Do not require the provider module/binary for `kernelMode === "none"` beyond importing the small JS adapter itself.

- [ ] **Step 6: Pass `--kernel` through CLI**

Update usage text and argument forwarding. Reject values other than `none` and `lean434`.

- [ ] **Step 7: Run integration tests and one real build**

Run:

```bash
npm run build:kernel-lean
node packages/pskernel-lean/scripts/psc-build-kernel-tests.mjs
node packages/cli/bin/psc.mjs build <small-valid-fixture.ps> --out /tmp/psc-kernel-test.js --kernel lean434
```

Expected: tests PASS; real build emits output only after provider acceptance.

- [ ] **Step 8: Commit**

```bash
git add psc15selfhost/packages/backend-ts/src/Ps/BackendTs/Compiler.lean psc15selfhost/scripts/compile-with-generated.mjs psc15selfhost/packages/cli/bin/psc.mjs psc15selfhost/packages/pskernel-lean/scripts/psc-build-kernel-tests.mjs
git commit -m "feat(psc2): gate builds with Lean 4.34 kernel"
```

### Task 7: Prove bootstrap isolation and add reproducible build/integration documentation

**Files:**
- Create: `psc15selfhost/packages/pskernel-lean/README.md`
- Create: `psc15selfhost/packages/pskernel-lean/BUILDING.md`
- Create: `psc15selfhost/packages/pskernel-lean/INTEGRATION.md`
- Modify: `psc15selfhost/packages/pskernel-lean/scripts/psc-build-kernel-tests.mjs`
- Existing regression files: `psc15selfhost/scripts/bootstrap-closure-contract.mjs`, `psc15selfhost/scripts/check-workspace.mjs`

**Interfaces:**
- Consumes: all KLP0-KLP3 commands from Tasks 1-6.
- Produces: reproducible human/AI continuation docs and regression evidence that provider remains optional.

- [ ] **Step 1: Add isolation assertions**

Test that `pskernel-lean` remains in `forbiddenBootstrapPackageNames`, remains excluded by `check-workspace.mjs`, and that `bootstrap`/`fixed-point` script definitions do not call any `kernel-lean` script.

- [ ] **Step 2: Run closure/isolation gates**

Run:

```bash
npm run test:bootstrap-closure-contract
npm run check:workspace
node packages/pskernel-lean/scripts/psc-build-kernel-tests.mjs
```

Expected: PASS.

- [ ] **Step 3: Write `README.md`**

Document purpose, current KLP0-KLP3 status, exact Lean pin, upstream copied-source provenance, trust model, quick build/test commands, and explicit statement that copied C++ source is reference/provenance in this milestone while the native provider links through the pinned Lean 4.34 toolchain.

- [ ] **Step 4: Write `BUILDING.md`**

Document prerequisites (`elan`, Lean 4.34 toolchain, Node/npm), Linux/macOS/Windows/WSL command variants, `npm run build:kernel-lean`, direct `lake` commands, binary location, `PSC_LEAN_KERNEL_PROVIDER` override, common missing-toolchain/binary/permissions diagnostics, and the exact commands the user can run locally if this environment cannot compile the native binary.

- [ ] **Step 5: Write `INTEGRATION.md`**

Document canonical admissions v2 contract, provider response schema, empty-env/prelude replay policy, host sequence, fail-closed behavior, why `.lean` source translation is forbidden, and follow-up seams for KLP4 dual checking and KLP5 WASM using the same logical protocol.

- [ ] **Step 6: Run full native-provider and PSC bootstrap regressions**

Run:

```bash
npm run test:kernel-lean
npm run test:bootstrap
npm run test:bootstrap-closure-contract
npm run check:workspace
npm run check:source:bootstrap
```

Expected: all PASS. If the environment cannot execute the native build, record the exact failing build command/output and leave `BUILDING.md` with the reproducible user-machine command; do not claim the native gate passed.

- [ ] **Step 7: Commit**

```bash
git add psc15selfhost/packages/pskernel-lean/README.md psc15selfhost/packages/pskernel-lean/BUILDING.md psc15selfhost/packages/pskernel-lean/INTEGRATION.md psc15selfhost/packages/pskernel-lean/scripts/psc-build-kernel-tests.mjs
git commit -m "docs(psc2): document Lean kernel provider integration"
```

### Task 8: Final KLP0-KLP3 verification and handoff evidence

**Files:**
- Modify only if verification exposes defects; otherwise no product-code changes.

**Interfaces:**
- Consumes: Tasks 1-7.
- Produces: concrete KLP0-KLP3 evidence and a clean branch ready for review/merge consideration.

- [ ] **Step 1: Verify branch diff does not semantically edit copied upstream kernel/runtime/util**

Run:

```bash
git diff psc2/minimal-selfhost-psc15...HEAD -- psc15selfhost/packages/pskernel-lean/kernel psc15selfhost/packages/pskernel-lean/runtime psc15selfhost/packages/pskernel-lean/util
```

Expected: no semantic source edits.

- [ ] **Step 2: Run complete provider gates**

Run:

```bash
npm run build:kernel-lean
npm run test:kernel-lean
```

Expected: PASS.

- [ ] **Step 3: Run existing self-host regression gates**

Run:

```bash
npm run check:workspace
npm run check:bootstrap-closure
npm run test:bootstrap
```

Expected: PASS without requiring the kernel provider during the bootstrap/fixed-point portions themselves.

- [ ] **Step 4: Run end-to-end accepted and rejected PSC2 build fixtures**

Run one valid source through `psc build ... --kernel lean434` and one deliberately kernel-invalid canonical fixture through the provider. Expected: valid build emits output; invalid declaration receives `accepted:false` and no output artifact is emitted.

- [ ] **Step 5: Record exact evidence in the final branch report**

Report branch HEAD, commands executed, PASS/FAIL outputs, unsupported provider/Core forms still intentionally fail-closed, and explicitly defer KLP4/KLP5 to follow-up plans.

- [ ] **Step 6: Commit any verification-only fixes separately**

If needed:

```bash
git add <only-files-fixed-by-verification>
git commit -m "fix(psc2): harden Lean kernel provider verification"
```
