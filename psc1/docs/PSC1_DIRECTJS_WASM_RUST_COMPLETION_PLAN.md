# PSC1 direct multi-backend completion plan (research baseline)

Status: **architecture and acceptance plan only**; no claim that PSC1 DirectJS, Rust, or Wasm builds have passed. Prepared 2026-10-20 using connected GitHub source inspection. Implementation and CI must be performed in subsequent commits on this branch, with exact SHA evidence.

## Repository identities

- Destination: `dwijayuda/pskernel/psc1/` on feature branch `psc1/direct-multibackend-v1`, branched from main `7d3e220e495f5d82178a3e66f191255045862bd5`.
- PSC1 source tree: exact Git tree `92111a1a0249b00e3dd5b5f1824e4dd8e349cd80` copied from `psc0/` at commit `5a9c0a42a3ab28e3e0607242c4efcc3aab629a4c`.
- Current PSC0 native source for compatibility analysis: `psc0/pscv0-v7-native-lean-v1` at `33676076bcda7b0de5ec1f9803f49b8b1d28a058`, draft PR #109.
- Current PSC0 Core-first direction: `psc0/core-first-environments-20261019` at `5371d9814800bc4c251068f90fbd246338c1a1d1`, draft PR #151. Its code qualification is separately pinned at `da1116dc28b282dfcf0c8e178c52a69f11477708`; CI run 39255930001 passed all four scoped jobs on 2026-10-19. This evidence applies to PSC0, **not** PSC1.
- PSC1 Lean toolchain is `leanprover/lean4:v4.34.0`; referenced PSC0 compiler uses `v4.35.0`. Align deliberately before copying newer Lean backend code.
- PSC1 still uses the older `ps-0.9-r3` frontend and TypeScript 7.0.2 compiler bootstrap. Do not relabel it as fully v7.2 compatible.

## Audited starting point

1. `psc1/packages/backend-js/src/Ps/BackendJs/`: existing Lean JS IR, Lower, Validate and Print, including printed generated declaration spans. Not currently a production DirectJS CLI with native `.d.ts` and `.js.map`.
2. `psc1/packages/backend-rust/src/Ps/BackendRust/`: substantial existing Lean Rust emitter. Not a registered, qualified primary PSC1 CLI target.
3. `psc1/packages/backend-wasm/src/Ps/BackendWasm/`: GC Wasm model, lowering and binary encoder; no equivalent complete standalone `Wat.lean` + component/WIT generation integration in the PSC1 snapshot.
4. `psc1/lakefile.lean` registers `PsBackendTs` but not `PsBackendJs`, `PsBackendRust`, or `PsBackendWasm`.
5. `psc1/npm-cli/psc.js` obtains checked/erased compiler output as TypeScript, invokes pinned `tsc`, and writes `.ts`, `.js`, `.d.ts`, `.js.map`. Its `.js` output is **not** DirectJS.
6. Several PSC1 npm manifests still refer to `psc0/` in their `repository.directory`, description and distribution assumptions. Rewrite intentionally before PSC1 publication; do not publish automatically.
7. Old and new `Ps.CompilerIr.Model` SHA values differ: PSC1 `a58fa183103817b9b65db45cc9e9798e6abcf4d3` vs PSC0 `340ffbb5e9f80792757c17cea74c6ffdcbeb4310`. The newer IR extends machine integers, float/intrinsic operations and representation. Port via checked, exhaustive adaptation, not text copy.

## Reuse targets in newer PSC0

- `psc0/packages/codegen/src/Ps/Codegen/{Artifact,Api,Doc,Names,Provenance,SourceMap}.lean` for artifact shape, source origins, deterministic naming and validated source maps.
- `psc0/packages/backend-ecma/src/Ps/BackendEcma/` for direct JS syntax, shared type/signature logic, `.d.ts`, and `.js.map`. Its `Module.lean` writes all three from one target plan, without calling `tsc`.
- `psc0/packages/backend-wasm/src/Ps/BackendWasm/{Wat,Module,Component,AbiComponent,AbiPlan,AbiSchema,AbiMarshal}.lean` for core binary/text parity, WIT and component ABI. Newer PSC0 `Module.lean` emits `.core.wasm`, `.core.wat`, plus `.wasm`, `.wat`, `.wit` when selecting a component.
- Newer `psc0/packages/backend-rust/src/Ps/BackendRust/` for target-specific fixes, but prefer preserving and qualifying compatible PSC1 Rust code first.
- Treat PR #109 C0–C4b backend receipts and PR #151 runtime observations as evidence about their pinned PSC0 profiles only. No cross-project portability claim without PSC1 CI.

## Architecture

```text
.ps (and supported .lean)
   -> parse / resolve / elaborate
   -> original canonical admissions -> independent kernel accept
   -> same accepted checked graph -> typed erasure
   -> validated, provenance-bearing PSC1 VerifiedIR
   -> target capability check + deterministic public API selection
   -> target-specific lowering/validation
        direct-js        -> module.js, module.d.ts, module.js.map
        rust             -> module.rs, psc1_runtime.rs, Cargo.toml as needed
        wasm-core        -> module.core.wasm, module.core.wat
        wasm-component   -> module.core.wasm, module.core.wat,
                            module.wasm, module.wat, module.wit
```

Frontend/kernel validation must not become backend compilation proof. No unchecked fallback or duplicate parsing/erasure; emission must use the accepted graph and reject unsupported features before publishing any partial output. Checked-state identity and target-runtime equivalence remain separately tested properties. Maintain the existing compiler-only bootstrap; do not gate DirectJS/Rust/Wasm availability on finishing self-hosting.

## Execution order and exact acceptance criteria

### P0 — Independent PSC1 target wiring

- Add an authoritative artifact-returning Lean service between validated PSC1 VerifiedIR and CLI, with explicit target/capability/error types, exact file roles, origin map and validated portable output paths.
- Register backend libs/executables in `psc1/lakefile.lean`; qualify build on Linux in GitHub Actions only.
- Fix PSC1 metadata and path assumptions without changing PSC0 or touching existing global npm packages.
- Decide Lean 4.35.0 pin before reusing newer backend source. Preserve provenance and license notices.
- CI must prove all three backends can be imported and a deliberate unsupported operation fails closed.

### P1 — Native DirectJS (first useful production outcome)

- Port minimal `Ps.Codegen` + `Ps.BackendEcma` functionality, adapting to PSC1 IR explicitly and exhaustively. Retain current TypeScript emitter as separate `ts` target, not hidden DirectJS fallback.
- Emit importable `module.js`, correct public `module.d.ts` generated from checked types, and valid ECMA-426-compatible `module.js.map` pointing to original input filenames/locations, not intermediate TypeScript.
- Compare Node execution to the existing checked TypeScript emission and compile a TypeScript consumer against generated declarations. Verify source map segment ranges and stable/deterministic bytes; test Unicode and renaming.
- Never invoke `tsc` to produce the DirectJS artifact. `tsc --noEmit` may validate the declaration file in CI.

### P2 — Rust target

- Wire validated PSC1 IR to its existing Rust backend, selectively port PSC0 fixes after testing their dependencies.
- Emit `module.rs` and deterministic runtime companion and/or `Cargo.toml` as needed, with explicit supported target/profile.
- Build via pinned Rust toolchain in Linux CI; run actual exported computations and verify observable parity with DirectJS, including recursion, integers, strings, variants, records and error/refusal cases.
- Qualify memory ownership, cloning/sharing, function values, imports/exports and stack safety rather than assuming Rust compilation implies matching semantics.

### P3 — Wasm core first, then component

- First qualify `module.core.wasm` with executable GC Wasm semantics; generate `module.core.wat` from the same validated final module object. Validate both; compare normalization where tools allow.
- Then add components, using the newer PSC0 scalar-WIT and ABI component code. Generate real `module.wasm`, `module.wat` and `module.wit` together from one public API manifest; validate the binary/component type and execute exports.
- WIT is an interface contract, not the executable. Permit only ABI-representable exports, e.g. tested fixed-width scalars initially; reject polymorphic/dependent/function/recursive exports until explicit tested adapters exist. Introduce strings, lists and records through canonical ABI with exact layout and ownership tests.
- Wasm GC may represent internal language values, while linear memory is permitted **only** for required explicit component ABI marshalling; no implicit dependency on linear-memory application semantics.
- Use pinned `wasm-tools`/Wasmtime or equivalent component-capable runner in Linux CI and retain negative-validation cases.

### P4 — Target-independent qualification and CLI

Suggested interface (not currently implemented):

```sh
psc build src/Main.ps --target js --out dist/Main
psc build src/Main.ps --target rust --out dist/Main
psc build src/Main.ps --target wasm-core --out dist/Main
psc build src/Main.ps --target wasm-component --out dist/Main --exports exports.json
psc build src/Main.ps --emit-all --out-dir dist
```

- One checked source/IR graph, distinct target-specific capability checks, deterministic outputs and explicit refusal ledger.
- CI matrix: official Lean build; independent checker admission/rejection; runtime parity on JS, Rust, Wasm core, Wasm component; artifact syntactic validation; `.d.ts` and source maps; precise negative tests.
- Emit atomic output sets only after all artifacts for a target validate. Never publish incomplete `.wit` beside unrelated `.wasm`.
- Preserve compiler phase/error ownership, no proof holes, no unchecked assumptions, no fallback on failed target, and exact CI SHA qualification.
- Document known supported features separately for `.ps` and `.lean`. PSC1 v7.2 feature upgrades are a distinct proposal, not prerequisites for backend functional delivery.

## Feature selection for first integrated test

First: closed, checked functions over Bool, fixed-width integers and Unit, calls, ifs, one namespace/module and simple public exports. Second: structs, sum types, strings and basic recursion. Later: polymorphism specialization, closures, unbounded Nat/Int, memory-sensitive aggregates, complex effects and FFI. Every unsupported case must fail deterministically with its target capability reason. Do not silently exclude source-level features from the declared supported denominator.

## Stop conditions for claims

- **Source exists** != **backend imports/builds**.
- **WAT generated** != **valid Wasm binary** != **executable component**.
- **Kernel accepted** != **runtime-preservation proof**.
- **Rust compiles** != **cross-backend behavioral parity**.
- **CI green for PSC0** != **CI green for PSC1**.
- **TypeScript-produced JS** != **native DirectJS**.

## Evidence references

- PSC1: `psc1/npm-cli/psc.js`, `psc1/lakefile.lean`, `psc1/ARCHITECTURE.md`, `psc1/packages/backend-{js,rust,wasm}/`.
- PSC0: `psc0/v7-native/README.md`, `psc0/packages/codegen/`, `psc0/packages/backend-ecma/`, `psc0/packages/backend-wasm/`.
- PSC0 qualified Core-first baseline: https://github.com/dwijayuda/pskernel/actions/runs/39255930001
- WIT contract: https://github.com/WebAssembly/component-model/blob/main/design/mvp/WIT.md
- WAT binary conversion reference: https://webassembly.github.io/wabt/doc/wat2wasm.1.html
