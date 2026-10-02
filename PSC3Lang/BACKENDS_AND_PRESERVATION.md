# Backends, bootstrap and semantic preservation

**Proposed architecture; no new backend or preservation proof is implemented here. Syntax authority: [ProofScript v0.7](SYNTAX_AND_GRAMMAR_V07.md).** All source routes respect that grammar and canonical meaning; target languages remain separate formats.

## 1. Backend directions

The earlier TS/Rust-only discussion was broadened by the request favoring direct JS and direct Wasm. Preserve useful existing routes without turning all emitters into mandatory bootstrap dependencies. The v0.7 syntax repair does not reverse these design priorities.

| Route | Role | Promotion gate |
|---|---|---|
| Existing TS → JS | Existing bootstrap/reference and useful `.ts` artifacts. | Bootstrap/conformance and exact downstream configuration. |
| Direct JS | Favored app output after supported-profile coverage. | Compiler corpus, runtime parity, maps, npm consumers and cutover. |
| Rust → native/Wasm | Optional `.rs` artifacts and native interoperation. | Runtime/capability conformance and clean target builds. |
| Direct Wasm | Gated performance/portable-runtime and preservation target. | Runtime/ABI, data/numeric/closure/resource tests and actual execution. |

Not every route supports every capability. DOM does not become native merely because syntax parses. Target restrictions are explicit, not new logical semantics.

## 2. Source and shared semantics

```text
.ps -> v0.7 parser/category-aware canonical lowering --+
.lean -> supported native frontend --------------------+-> Core
.psx -> declared extension expansion/lowering ---------+
                                                        |
                                                kernel admission
                                                        |
                                                   CheckedCore
                                                        |
                                                erasure / Runtime IR
                                      +-----------+------+-------+----------+
                                      |           |              |          |
                                    TS AST      JS AST        Rust AST    Wasm IR
                                      |           |              |          |
                                     .ts         .js            .rs        .wasm
                                      |                          |
                                     tsc                   rustc / link profile
                                      |                          |
                                     .js                   native / Wasm
```

Original `.ps` bytes may contain registered aliases and decorations not accepted by stock Lean. Renaming them is not lowering. Preserve the reference's D-CALL discriminator, argument/tuple distinctions, binders and source maps. Direct emitters do not invent a different parser or source grammar.

Runtime IR expresses PSC behavior rather than JS number layout, Rust ownership or Wasm opcodes. `VerifiedIR` naming does not itself prove construction correctness. JS generation uses structured IR, not regex stripping of TS. Shared export-schema/lowering logic does not justify text hacks.

## 3. Preservation connections

For total pure code, relate encoded inputs, actual source computation, target execution and decoded outputs. Effects/nondeterminism need appropriate trace relations. Include resource assumptions/outcomes. Textual equality across `.ps`, Lean, TS and Rust is not the objective.

Required connections are source/specification to admitted declarations; proof/type erasure to runtime meaning; target lowering; linked runtime implementation to its model; AST/IR to emitted bytes; and downstream/runtime assumptions. The source connection explicitly includes v0.7 canonical lowering for `.ps`.

CompCert illustrates scoped semantic-preservation claims; its theorems are not proofs of PSC. [C01](RESEARCH_SOURCES.md#compilation-and-targets)

## 4. Hybrid assurance

Prove stable regular passes and representation lemmas once. Use per-compilation certificates for selected complicated transformations, checked by a validator whose soundness theorem says acceptance implies preservation. A routine named validate is not that theorem.

Target semantics and proofs may be ordinary Lean/PSC definitions. The kernel needs no TS/Rust/Wasm-specific trusted instruction. Strict checking must justify actual certificate decisions through accepted logical mechanisms rather than a native Boolean oracle. Cache compositional proofs only with exact dependency identities.

## 5. Artifact binding

Use proved printing or justified parsing of the exact emitted file. A correct internal AST does not cover swapped arguments or operators in text/binary output.

Bind original source, canonical source/Core, target files, runtime, imports, configuration and assumptions. Hashes identify these inputs but do not prove their relation. Post-check formatting/bundling/minification/editing requires the appropriate renewed evidence. Release uses the checked immutable snapshot, not a mutable reread.

## 6. TypeScript route

Generate a restricted erasable-type subset with explicit ESM configuration. Extra runtime transformations require modeling; `erasableSyntaxOnly` is output discipline, not proof. [T13](RESEARCH_SOURCES.md#typescript-language-and-tooling)

A future validator can compare actual emitted JS with certified TS meaning, with every accepted normalization justified. This is downstream validation, not another generator. Record compiler/flags/dependencies. `.d.ts` communicates runtime interfaces and omits erased proof arguments; it does not validate arbitrary callers.

TS syntax belongs in labelled target artifacts, not ordinary `.ps` examples. A TS emitter is not permission to accept JS arrows, colon-named calls or bare function blocks in v0.7.

## 7. Rust route

Use explicit faithful runtime representations. Exact Nat/Int and primitive semantics cannot inherit convenient Rust overflow/cast defaults. [C02](RESEARCH_SOURCES.md#compilation-and-targets)

Native and Wasm are separate profiles. `wasm32-unknown-unknown` restrictions matter, and Rust-generated Wasm is not evidence of a PSC direct-Wasm backend. [C03](RESEARCH_SOURCES.md#compilation-and-targets)

Safe Rust helps with hazards but does not establish functional equivalence. Unsafe runtime/FFI dependencies require explicit evidence/assumptions. rustc/LLVM/linking remain assumptions until covered.

## 8. Direct Wasm

Select a concrete feature, memory/GC, ABI, import and representation profile. Arbitrary-precision arithmetic, strings, ADTs, closures and resources still require implementations. Owned binary emission does not eliminate those obligations.

Wasm validation is distinct from source-contract preservation. Engines and hosts remain separate boundaries. [C04](RESEARCH_SOURCES.md#compilation-and-targets)

Initial browser use can be coarse pure kernels behind JS adapters. Measure marshalling/startup before moving fine-grained events. No native DOM access is implied. GC and linear-memory profiles must not silently share an ABI identity.

## 9. Self-hosting and build trust

Keep the current minimal bootstrap while designing public capability growth. Direct targets, UI and all platform libraries need not enter the first fixed-point closure. The previous stable implementation subset may implement richer v0.7 capability coverage without using every accepted form itself.

Self-host evidence requires actual generated-compiler execution and comparison, not copied output or only test doubles. A compiler building a checker executable has a different trust role from a compiler proposing proof terms. Independent builds/checking and preservation evidence strengthen trust; ownership alone does not. [R05–R06](RESEARCH_SOURCES.md#repository-baselines)

## 10. Sequence

Stabilize one existing route and genuine admission; establish a useful semantic fragment; deliver a full JS workflow; promote direct JS only after coverage/cutover; retain Rust for actual native users; promote direct Wasm independently.

Do not require every proof before useful typed apps can run, or call those apps fully verified while preservation is absent. Backend count and source-syntax conformance are distinct release dimensions.
