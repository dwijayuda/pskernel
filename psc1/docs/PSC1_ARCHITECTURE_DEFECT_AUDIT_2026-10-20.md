# PSC1 Compiler Architecture Defect Audit — 2026-10-20

**Scope:** `dwijayuda/pskernel`, branch `psc1/direct-multibackend-v1`, immutable source commit `98c8cf7caa6f9d132a27e67e447516355b77ae19`. Read-only code inspection and examination of existing GitHub Linux CI, not a newly executed targeted defect-reproduction suite. Documentation addition does not modify compiler implementation. Main and PSC0 are not mutated. This report distinguishes confirmed implementation/design defects from risks requiring reproductions.

## Baseline: actual qualification

- [PSC1 direct backends run 39313598555](https://github.com/dwijayuda/pskernel/actions/runs/39313598555): SUCCESS for its scoped build-and-smoke workflow.
- DirectJS output and actual Node execution, emitted Rust compiled/tested via Cargo, core Wasm GC validated and instantiated, scalar WIT/component artifact validated and invoked via Wasmtime, and declaration-level source-map UTF-16 exercise passed in this workflow lineage.
- It does **not** establish verified kernel admission, cross-backend preservation for general inputs, complete PSC1 or PSCV0 v7.2 language conformance, or npm package publication readiness.

## Architecture graph (as implemented)

```text
Native CLI (.ps/.lean)
  -> project loader with transitive source flattening
  -> source elaboration
  -> canonical admission *encoding* (NOT independent kernel acceptance)
  -> erasure + embedded runtime prelude
  -> independently bounded typed-IR validator
  -> target-specific backend lowering / printing
       JS source + separately typed declarations + original-source map
       Rust .rs (requires external Cargo project/dependencies)
       Wasm GC .wasm + wasm-tools text printer
       Component scalar WIT -> wasm-tools embed/new -> .wasm, .wat, .wit
  -> file output (nontransactional)

Npm CLI ("psc")
  -> generated JS compiler + JS PSKernel-Core check
  -> TypeScript 7 emission -> tsc -> JS/.d.ts/.map
  (does not invoke the native DirectJS/Rust/Wasm path)
```

## Confirmed architectural defects

### P0-01 — Independent checker acceptance is not required for native output

**Status:** Confirmed code-path/design defect. Not a demonstrated false proof acceptance.

`psCompilerValidatePrepared` validates canonical admission serializability, and `psCompilerVerifiedIrFromPrepared` reconstructs a host environment, erases terms, and returns a raw IR. The native host turns it into a validated IR directly without any checked-module token obtained from a separate kernel. Sources: [Compiler API](https://github.com/dwijayuda/pskernel/blob/98c8cf7caa6f9d132a27e67e447516355b77ae19/psc1/packages/compiler/src/Ps/Compiler/Api.lean#L232-L311), [DirectBackend](https://github.com/dwijayuda/pskernel/blob/98c8cf7caa6f9d132a27e67e447516355b77ae19/psc1/host/src/Ps/Host/DirectBackend.lean#L11-L21).

**Fix:** Introduce a `CheckedModule`/session identity from an independent kernel with canonical input and environment digest; permit erasure/emission only through that token. Keep decode/type validation independent; don't treat serialization or executable compilation as kernel proof.

### P0-02 — Audited PSC1 kernel lacks corrections already isolated on a separate branch

**Status:** Confirmed source drift, with independent bug explanations; latest integration qualification not assumed.

Compare `psc1/packages/pskernel-core/src` to `fix/psc1-pskernel-core-cross-branch-20261020`. Seventeen kernel source modules differ. [Cross-branch correction audit](https://github.com/dwijayuda/pskernel/blob/fix/psc1-pskernel-core-cross-branch-20261020/psc1/packages/pskernel-core/FIX_PORT_AUDIT_2026-10-20.md) records binder-local semantic cache leakage, free-variable-dependent cache keys, universe max-offset normalization, constructor Pi-spine handling, mutual inductive budget separation, and equality ordering. This kernel is relevant to the npm path; the native direct build currently does not call it.

**Fix:** Qualify and integrate this exact port into the intended kernel lane; ensure generated checker artifacts are rebuilt/proven identical to the qualified source. Wire independent kernel admission into the native backend path separately.

### P1-03 — 'validated' and 'specialized' types are constructible wrappers with no post-pass check

**Status:** Confirmed authority/interface weakness; actual incorrect transformation not demonstrated.

`PsValidatedIrModule`, `PsSpecializedIrModule` expose public `raw` constructors: [Model](https://github.com/dwijayuda/pskernel/blob/98c8cf7caa6f9d132a27e67e447516355b77ae19/psc1/packages/compiler-ir/src/Ps/CompilerIr/Model.lean#L256-L269). `psIrSpecializeValidatedModule` simply wraps transformed raw IR: [Specialize](https://github.com/dwijayuda/pskernel/blob/98c8cf7caa6f9d132a27e67e447516355b77ae19/psc1/packages/compiler-ir/src/Ps/CompilerIr/Specialize.lean#L1716-L1729). `psRustEmitValidatedModule` accepts the wrapper directly: [Rust Module](https://github.com/dwijayuda/pskernel/blob/98c8cf7caa6f9d132a27e67e447516355b77ae19/psc1/packages/backend-rust/src/Ps/BackendRust/Module.lean#L1265-L1268).

**Fix:** Restrict authority to a validated session/handle, revalidate every transformed output against a typed checker, and add independently checked specialization-preservation witnesses or testable refinement obligations.

### P1-04 — Flattened module graph and unconditional JS exports

**Status:** Confirmed design defect.

The project loader concatenates all imported declarations and entry declarations into one global declaration list: [ProjectCompiler](https://github.com/dwijayuda/pskernel/blob/98c8cf7caa6f9d132a27e67e447516355b77ae19/psc1/host/src/Ps/Host/ProjectCompiler.lean#L382-L466). Erasure sets `imports := []`: [Erasure](https://github.com/dwijayuda/pskernel/blob/98c8cf7caa6f9d132a27e67e447516355b77ae19/psc1/packages/erasure/src/Ps/Erasure/Definition.lean#L489-L532). JavaScript prints `export const/function` for every lowered declaration: [JS printer](https://github.com/dwijayuda/pskernel/blob/98c8cf7caa6f9d132a27e67e447516355b77ae19/psc1/packages/backend-js/src/Ps/BackendJs/Print.lean#L1070-L1096). There is no consistent entry-module public API or private reachability plan across targets.

**Fix:** Carry a module graph and source/public/private identities through checking/erasure, link reachable definitions separately from public API, and select deterministic exports for all three targets.

### P1-05 — JS `.d.ts` is generated before specialization from a different IR

**Status:** Confirmed early refusal and architectural mismatch; concrete wrong declaration for a valid program not reproduced.

`psHostDirectDeclarationSource` rejects every raw generic declaration, then JS lowering performs specialization separately: [Host](https://github.com/dwijayuda/pskernel/blob/98c8cf7caa6f9d132a27e67e447516355b77ae19/psc1/host/src/Ps/Host/DirectBackend.lean#L40-L69). The specializing pass intentionally drops generic source definitions before cloning specific instantiations: [Specialize seed](https://github.com/dwijayuda/pskernel/blob/98c8cf7caa6f9d132a27e67e447516355b77ae19/psc1/packages/compiler-ir/src/Ps/CompilerIr/Specialize.lean#L1319-L1367). This blocks programs containing internal generics that could otherwise be specialized.

**Fix:** One shared ECMAScript target plan with checked public signature mapping, link identities, specializing names, JS body, `.d.ts` and `.js.map`; validate a TypeScript consumer in CI.

### P1-06 — Output files can become partially updated

**Status:** Confirmed implementation issue.

DirectJS writes JS, declaration and map independently: [DirectBackend](https://github.com/dwijayuda/pskernel/blob/98c8cf7caa6f9d132a27e67e447516355b77ae19/psc1/host/src/Ps/Host/DirectBackend.lean#L74-L86). Component output moves five public paths one-by-one in a `try/finally` block and only stages under a predictable `.psc1-stage` name: [WasmComponent](https://github.com/dwijayuda/pskernel/blob/98c8cf7caa6f9d132a27e67e447516355b77ae19/psc1/host/src/Ps/Host/WasmComponent.lean#L79-L116). An interrupted or failing update can mix generations; an abandoned staging directory blocks rebuilding.

**Fix:** Unique private stage, checksummed manifest and immutable versioned bundle, then atomic directory/pointer promotion. Test simulated failure at each publication step and recovery.

### P1-07 — A single source snapshot is not preserved through mapping or across targets

**Status:** Confirmed multiple source reads / pipeline divergence; an actual racing-file case not reproduced.

`psHostLoadModuleWithFuel` reads each file to elaborate it: [ProjectCompiler](https://github.com/dwijayuda/pskernel/blob/98c8cf7caa6f9d132a27e67e447516355b77ae19/psc1/host/src/Ps/Host/ProjectCompiler.lean#L382-L419). DirectJS later independently re-reads and re-parses the entry file to build source maps: [DirectBackend](https://github.com/dwijayuda/pskernel/blob/98c8cf7caa6f9d132a27e67e447516355b77ae19/psc1/host/src/Ps/Host/DirectBackend.lean#L59-L79). Each target separately invokes `psHostDirectValidatedIr`; the native CLI has no single `--emit-all` session: [Main](https://github.com/dwijayuda/pskernel/blob/98c8cf7caa6f9d132a27e67e447516355b77ae19/psc1/packages/cli/src/Main.lean#L21-L59). Concurrent file changes can produce mismatched code, maps or per-target inputs.

**Fix:** An immutable, fully hashed source-closure snapshot, one accepted checked graph per multi-target build, and one persisted provenance table from the original elaboration.

### P1-08 — Source maps do not explicitly mark unmapped generated gaps

**Status:** Confirmed construction defect with a specific plausible downstream symptom; debugger misattribution requires a test.

If an emitted declaration has no matching entry-source name, `psDirectMapSegments` silently skips it without emitting a one-field unmapped segment or range boundary. [DirectSourceMap](https://github.com/dwijayuda/pskernel/blob/98c8cf7caa6f9d132a27e67e447516355b77ae19/psc1/host/src/Ps/Host/DirectSourceMap.lean#L50-L90). ECMA-426 source maps use unmapped segments to avoid extending attribution across generated-only spans. Subsequent source locations can therefore inherit a previous declaration's source position when emitted output is interleaved. Current maps also attribute only whole declarations, not nested expression positions.

**Fix:** Carry origin per emitted span, produce explicit generated-only segments at boundaries, validate with an independent ECMA-426 parser and stack trace debugger; preserve full source set, not just entry basename. Normative reference: https://tc39.es/ecma426/2024/

### P1-09 — DirectJS chooses the non-stack-safe printer despite having a stack-safe variant

**Status:** Confirmed backend selection; deep-recursion runtime divergence is an untested risk.

`psJsEmitValidatedModuleWithPositions` calls `psJsPrintModuleWithPositions`, which calls ordinary `psJsPrintDeclaration`. In the same module `psJsPrintModuleStackSafeWithPositions` and the generator-dispatch prelude exist but are unused by the native CLI. [JS printer](https://github.com/dwijayuda/pskernel/blob/98c8cf7caa6f9d132a27e67e447516355b77ae19/psc1/packages/backend-js/src/Ps/BackendJs/Print.lean#L1633-L1750). This leaves recursion depth behavior different from the explicitly stack-safe variant and from the other target backends.

**Fix:** Select one preserving recursion-lowering strategy and test deep tail and non-tail recursion with exact low/high resource limits and compared results on JS/Rust/Wasm.

### P1-10 — WIT advertised scalar types outpace executed ABI conformance

**Status:** Confirmed test coverage gap, not a demonstrated wrong adapter.

`psHostWitScalarType` advertises Bool plus u8/u16/u32/u64/s8/s16/s32/s64/f32/f64, while the current Linux smoke exercises actual component invocations for Bool values only. [WIT types](https://github.com/dwijayuda/pskernel/blob/98c8cf7caa6f9d132a27e67e447516355b77ae19/psc1/host/src/Ps/Host/WasmComponent.lean#L3-L45), [workflow](https://github.com/dwijayuda/pskernel/blob/98c8cf7caa6f9d132a27e67e447516355b77ae19/.github/workflows/psc1-direct-backends.yml#L198-L253). Component validation is not a cross-language semantic equivalence proof; arithmetic width, signedness and NaN require runtime tests. `component wit` consistency is tested by substring of the export name rather than an exact ABI/interface comparator: [WIT checking](https://github.com/dwijayuda/pskernel/blob/98c8cf7caa6f9d132a27e67e447516355b77ae19/psc1/host/src/Ps/Host/WasmComponent.lean#L95-L105).

**Fix:** Create signed/unsigned boundary, overflow, NaN/negative zero, multiple-argument, and failure tests per advertised scalar; structurally compare parsed WIT/export signatures.

### P1-11 — Public npm `psc` and native Lean `psc1` are divergent compilers

**Status:** Confirmed implementation split.

The npm CLI reports PSC0 and calls the old generated JS compiler/JS kernel and TypeScript 7 emitter: [npm-cli](https://github.com/dwijayuda/pskernel/blob/98c8cf7caa6f9d132a27e67e447516355b77ae19/psc1/npm-cli/psc.js#L108-L164). The new DirectJS/Rust/Wasm commands exist only in the separate Lean executable: [Main](https://github.com/dwijayuda/pskernel/blob/98c8cf7caa6f9d132a27e67e447516355b77ae19/psc1/packages/cli/src/Main.lean#L21-L59). Package manifests still advertise `0.1.0-psc0.1`, source path `psc0/`, and old distribution identity: [meta package](https://github.com/dwijayuda/pskernel/blob/98c8cf7caa6f9d132a27e67e447516355b77ae19/psc1/packages/proofscript/package.json#L1-L88).

**Fix:** Define one public CLI command model, explicit native/generated host strategy and authority profile, then package the exact qualified backend runtime/tool dependencies. No automatic npm publication.

### P1-12 — Rust output does not include its essential build contract

**Status:** Confirmed standalone packaging gap.

Rust runtime source unconditionally imports `num_bigint`/`num_traits`: [Runtime](https://github.com/dwijayuda/pskernel/blob/98c8cf7caa6f9d132a27e67e447516355b77ae19/psc1/packages/backend-rust/src/Ps/BackendRust/Runtime.lean#L11-L20); native host only writes `.rs`: [DirectBackend](https://github.com/dwijayuda/pskernel/blob/98c8cf7caa6f9d132a27e67e447516355b77ae19/psc1/host/src/Ps/Host/DirectBackend.lean#L88-L98). CI supplies a handwritten Cargo manifest. A user cannot reliably compile arbitrary emitted Rust by receiving a single `.rs` without knowing/providing those dependencies.

**Fix:** Emit a minimal `Cargo.toml` and pinned `Cargo.lock` (or publish versioned runtime crate) with explicit target/toolchain identity. Separate runtime from source file and qualify multi-module linking.

### P2-13 — Error ownership and diagnostics collapse to generic strings

**Status:** Confirmed usability/observability defect.

The host discards source erasure/IR/target error details and emits generic strings such as `PSC1_DIRECT_JS_TARGET_UNSUPPORTED`: [DirectBackend](https://github.com/dwijayuda/pskernel/blob/98c8cf7caa6f9d132a27e67e447516355b77ae19/psc1/host/src/Ps/Host/DirectBackend.lean#L14-L21), [DirectBackend](https://github.com/dwijayuda/pskernel/blob/98c8cf7caa6f9d132a27e67e447516355b77ae19/psc1/host/src/Ps/Host/DirectBackend.lean#L59-L70). The IR validator collapses the detailed `PsIrCheckReport` to two enum cases: [Validate](https://github.com/dwijayuda/pskernel/blob/98c8cf7caa6f9d132a27e67e447516355b77ae19/psc1/packages/compiler-ir/src/Ps/CompilerIr/Validate.lean#L7-L28).

**Fix:** Preserve structured phase, exact error kind, source span, target feature, runtime profile and checker identity through CLI JSON and human-friendly diagnostics; reject/return failures without silent retries.

### P2-14 — CI is a narrow single-profile smoke, not a compiler-wide acceptance gate

**Status:** Confirmed coverage gap.

The qualified GitHub workflow only auto-triggers for pushes to one feature branch, not `main` or pull requests, and contains one large joint smoke job: [workflow](https://github.com/dwijayuda/pskernel/blob/98c8cf7caa6f9d132a27e67e447516355b77ae19/.github/workflows/psc1-direct-backends.yml#L1-L75). It checks a few programs (`idNat`, `Bool`, simple WIT) and a source map VLQ sample; it does not cover a feature/target matrix, Rust/JS/Wasm deep recursion, multi-module imports, type declarations with TypeScript consumer, deterministic repeat builds or negative compiler/ABI test families. The existing green job cannot be read as whole-language completion.

**Fix:** Define an explicit supported feature denominator and separate Linux jobs per source form, admission, typed IR, direct JS, Rust, Wasm GC, component, TypeScript declarations, provenance, determinism, negative refusals and end-to-end differential comparison. Apply to PRs and integration target.

### P2-15 — Runtime packaging and import model induce duplication and scale risks

**Status:** Confirmed duplication mechanism; magnitude not benchmarked.

Rust source assembly embeds the complete runtime prelude into each emitted module: [Rust Module](https://github.com/dwijayuda/pskernel/blob/98c8cf7caa6f9d132a27e67e447516355b77ae19/psc1/packages/backend-rust/src/Ps/BackendRust/Module.lean#L1217-L1263). Source modules are flattened before backend emission. This impedes independent compilation/incrementality and can increase generated source volume and rebuild work.

**Fix:** Move runtime into pinned target packages/crates, tree-shake reachable helpers after shared semantic reachability selection, benchmark cold/incremental rebuilds and include artifact-size regression budgets.

### P2-16 — Historical metadata and toolchain drift

**Status:** Confirmed maintenance risk, not an immediate semantic bug.

`psc1/lean-toolchain` pins Lean 4.34.0 while the evolving PSC0 v7.2 work uses stable 4.35.0; PSC1 package manifests and workflow names still include PSC0/PSC2 identities. `license: UNLICENSED` and public npm metadata need an explicit distribution/licensing audit: [package](https://github.com/dwijayuda/pskernel/blob/98c8cf7caa6f9d132a27e67e447516355b77ae19/psc1/packages/proofscript/package.json#L1-L19). Pinning target dependencies in CI is positive, but distribution manifest/tool installer ownership is incomplete.

**Fix:** Publish one standalone PSC1 package/version/profile manifest; preserve applicable upstream notices. Treat a Lean-pin upgrade as its own review and qualification matrix, not a search-and-replace migration.

## Confirmed good foundations — preserve these

- Lean-native frontend and existing backend-neutral typed IR are genuine code, not placeholders.
- Bounded typed-IR checker rejects ill-typed/unknown source in the scoped tested profile.
- Native DirectJS emits runnable JavaScript without invoking TypeScript 7.
- Wasm GC binary encoder works for a bounded executable profile and binary-to-WAT roundtrip is qualified.
- Explicit scalar WIT export/component generation and actual Wasmtime Bool invocation work.
- Wasm adapters do not automatically expose unbounded Nat or dependent/generic values without ABI policy.
- CI pins wasm-tools 1.254.0 and Wasmtime 49.0.4 by artifact SHA-256; kernel independent admission and broader semantic parity remain separate.
- Self-hosting is kept outside the immediate backend-completion critical path.

## Minimal prioritized repair plan

**Gate A — Trust and correctness first:** finish separate kernel fix branch CI; integrate qualified kernel files to the selected PSC1 lane; bind exact compiled canonical admissions/environment to a checked-module session; revalidate specialized IR. Before release claim, run positive and negative independent kernel acceptance and integrity tests.

**Gate B — One semantic/API boundary:** represent multi-module graph and public API before erasure; preserve source and checked provenance; emit JS/Rust/Wasm from one immutable session; ensure source-map declarations/source content cannot be from a different read of files.

**Gate C — One target plan per backend:** unify JS/TS declaration output and stack-safe lowering, emit precise source maps including unmapped spans, ship Cargo manifest and runtime crate, test all explicitly advertised scalar WIT types.

**Gate D — Publication and distribution:** validate complete artifact bundle with SHA/provenance before publication, emit manifest under versioned immutable directory, recover interrupted publication, wire public `psc` to qualified native targets and explicit TypeScript fallback only on user-selected target.

**Gate E — Qualification coverage:** add GitHub PR+main linux matrix, first using executable `Bool`, fixed-width integer and unit examples, then structures, inductives, recursion, closures, imports and large integer/Unicode. Maintain individual target refusals and repeated/differential tests. Report executable SHA, CI run, exact profile/feature denominator and any exceptions, without unsupported percentage completion.

## Evidence discipline

- **Confirmed** refers to source-code/design facts at the pinned SHA; it does not mean a new adversarial/negative fixture was run.
- **Risk** refers to a plausible observable defect not reproduced in this audit; add a regression reproducer before claiming incorrect runtime semantics or exploitability.
- A missing independent checker is a trust gap, **not** a demonstrated bogus proof.
- Kernel port PR CI and compiler backend CI are distinct; a passing one does not imply passing the other.
- All proposed work is authorized open-source compiler, kernel and formal-methods correctness engineering; do not introduce offensive tooling or shortcuts.
