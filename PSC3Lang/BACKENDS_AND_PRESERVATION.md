# Backends, bootstrap and semantic preservation

**Proposed architecture; no new backend or preservation proof is implemented by this document.**

## 1. Reconcile the backend directions

Earlier standalone PSC3 work preferred TS and Rust only. The current design request additionally favors direct JS and direct Wasm. This draft deliberately accommodates that change without discarding useful code or turning four emitters into simultaneous bootstrap prerequisites.

| Route | Proposed role | Promotion gate |
|---|---|---|
| Existing TS → JS | Preserve as working bootstrap/reference route where supported; first-class `.ts` artifact remains useful. | Existing bootstrap/conformance gates; exact external configuration recorded. |
| Direct JS | Favored ordinary JS application output after full supported-profile coverage. | Compiler corpus, runtime parity, source maps, npm consumer and self-host cutover gates. |
| Rust → native/Wasm | Retain optional first-class `.rs` output for native/library integration. | Per-target runtime/capability conformance and clean consumer builds. |
| Direct Wasm | Gated performance/portable-runtime and focused preservation target. | Explicit runtime/ABI profile, numeric/data/closure/resource tests and actual artifact execution. |

The long-term language does not require every route to support every capability. A browser DOM call cannot become a native capability merely because both routes accept the same syntax. Target restriction is metadata/evidence, not new type-theory semantics.

## 2. Shared semantics

```text
.ps / supported .lean / explicit .psx expansion
                     |
        source correspondence + elaboration
                     |
           kernel-admitted CheckedCore
                     |
          erasure and runtime lowering
                     |
               Runtime IR
        +------------+-------------+------------+
        |            |             |            |
       TS AST       JS AST        Rust AST      Wasm IR
        |            |             |            |
       .ts          .js            .rs          .wasm
        |                          |
       tsc                   rustc / link profile
        |                          |
       .js                   native or Wasm
```

One runtime IR describes PSC behavior, not JS number layout, Rust borrow checking or Wasm opcodes. Target-specific representations belong below it. Existing `VerifiedIR` naming does not grant proof authority to a value.

The direct JS emitter must use a restricted AST/IR, not regex stripping of generated TS. A TS artifact and a JS artifact can share semantic lowering and export-schema logic without sharing a text-hacking step.

## 3. Proof-producing compilation

For total pure programs, relate encoded input, source execution, target execution and decoded output. For effects or nondeterminism use the appropriate trace equivalence/refinement. Include resource assumptions or explicit resource outcomes. Textual equality of `.lean`, TS and Rust is not the goal.

Required connections are:

1. intended source/specification to admitted declarations;
2. proof/type erasure to runtime meaning;
3. runtime lowering to target AST/IR;
4. actual linked runtime primitives to their models;
5. AST/IR to exact emitted file bytes;
6. downstream transforms and execution assumptions.

CompCert demonstrates the importance of a precisely scoped semantic-preservation theorem, including explicit boundaries. It does not supply proofs for PSC3 or its targets. [C01](RESEARCH_SOURCES.md#compilation-and-targets)

## 4. Recommended hybrid assurance

Prove regular passes and runtime representation lemmas once. For more complex optimizations, generate per-compilation certificates checked by a validator with a soundness theorem: acceptance implies the required source/target relation. Merely naming a routine `validate` is not that theorem.

Semantics, target ASTs and preservation theorems can be ordinary Lean/PSC definitions. The logical kernel need not grow TS/Rust-specific trusted instructions. Automation constructs proofs; strict acceptance checks evidence against the fixed claim. Reflective checking must justify the actual decision result through accepted logical machinery rather than a hidden native Boolean oracle.

Use compositional module/function certificates to avoid reproving an entire dependency graph after every edit. Track dependencies so an optimized function cannot cite an old runtime model after a library change.

## 5. Exact artifact binding

Prove printing or independently parse/check the exact emitted files with a justified target parser. A proof of an internal AST is insufficient when a printer can swap arguments or change an operator.

Bind the checked source graph, target source/binary, linked runtime, imports, semantic profile, toolchain configuration and permitted assumptions. Hashes identify these inputs but do not prove their relationship. A formatter/minifier/bundler or post-check edit invalidates relevant evidence unless separately validated.

Release operations must use the actual checked byte snapshot, not reread mutable files after approval. Cached accepted reports are reusable only under an exact valid dependency identity and checking policy.

## 6. TypeScript route

Generate a restricted mostly erasable-type subset and explicit modern ESM configuration. TS runtime constructs that require nontrivial transformations are excluded unless separately modeled. `erasableSyntaxOnly` is useful output discipline, not a theorem. [T13](RESEARCH_SOURCES.md#typescript-language-and-tooling)

A future checker may validate the actual JS emitted by tsc against the certified type-erased TS meaning. Every accepted normalization/module transform needs justification. This is downstream validation, not an additional code-generation backend.

Always record compiler version, flags and dependencies. Successful TypeScript type checking is output validation, not PSC proof authority. Generated `.d.ts` represents the callable runtime interface; it cannot validate arbitrary JS inputs or preserve erased proof parameters at runtime.

## 7. Rust route

Generate explicit runtime representations rather than inheriting convenient Rust defaults. In particular, exact Nat/Int need faithful implementations; machine arithmetic and conversions must use the specified semantics. Rust's operator rules include configuration-sensitive overflow behavior, which must not become PSC source meaning. [C02](RESEARCH_SOURCES.md#compilation-and-targets)

Native and Wasm are distinct deployment profiles. Rust's `wasm32-unknown-unknown` documentation describes platform restrictions; compilation through that target is not proof of native API availability or of PSC's own Wasm backend. [C03](RESEARCH_SOURCES.md#compilation-and-targets)

Restricted safe Rust can reduce some implementation hazards, but safety checking is not functional equivalence. Unsafe runtime/FFI internals and dependencies require explicit audit/model boundaries. Downstream rustc/LLVM/linking remain assumptions until appropriate preservation/validation covers them.

## 8. Direct Wasm route

Choose a concrete baseline feature set, memory/GC strategy, calling convention, host imports and runtime representation. Arbitrary-precision numbers, strings, ADTs, closures and resource handles still need implementations. Owning binary emission does not remove that work.

Wasm specifies decoding, validation and execution; validation is not proof that the module implements the PSC source contract. A direct Wasm route still relies on an engine and host adapter unless those are separately covered. [C04](RESEARCH_SOURCES.md#compilation-and-targets)

For browser apps, initial Wasm modules may implement coarse pure kernels behind a JS shell. Measure marshalling/startup costs before moving fine-grained UI/event work across the boundary. Direct Wasm does not grant native DOM access.

A Wasm-GC profile and a linear-memory profile must not silently share an ABI identifier. Keep both research options until measurements and proof/runtime complexity justify the first stable choice.

## 9. Self-hosting and checker build trust

Retain the current minimal bootstrap boundary while documentation evolves. Do not make direct JS, direct Wasm, UI libraries or all platform packages prerequisites for the next compiler generation. New language capabilities can be implemented in the previous stable subset.

A self-host test executes the actual generated compiler on its source and compares the specified next-generation artifacts/semantics. It is not copying an old output or passing orchestration tests with compiler doubles. It does not prove soundness.

The compiler that produces proof candidates may be untrusted relative to an independent checker. The compiler that builds the checker executable has a different trust role. Reproducibility, independent builds, diverse checking and eventually preservation evidence strengthen that story but do not create trust by ownership. [R05–R06](RESEARCH_SOURCES.md#repository-baselines)

## 10. Recommended sequence

First stabilize one existing generation route and genuine admission. Then prove/validate a small useful runtime fragment and deliver a complete JS app workflow. Promote direct JS only after it supports the required corpus and toolchain cutover. Keep Rust useful where there is a real native use case. Develop direct Wasm behind its own measured profile and promote it independently.

Do not demand all target proofs before any useful typed app can run. Do not label such an app fully verified while those proofs are absent. The roadmap ties release claims to evidence rather than backend count.
