# PSC1 source/backend parity contract

Audit baseline: `da880d864ca5f9e35729255fd7e4f8a17953cd39` (PR #166). Baseline final Linux run: [39469312498](https://github.com/dwijayuda/pskernel/actions/runs/39469312498). This draft does not qualify later integration commits. Typed-error handlers from PR #167 remain an integration candidate until their actual run passes.

## Shared source semantics

`Compiler.Api.psCompilerParseSource` dispatches to the Lean/ProofScript parsers; both return `PsSyntaxModule` and enter `Elab.Declaration.psElabModule`. There is one semantic elaborator. `Syntax.Translate` parses one grammar and prints the common AST in the other grammar; translation is not a second elaborator or a behavioral proof. Unsupported forms must refuse before output replacement.

Both grammars retain named definitions/theorems, explicit/implicit/strict-implicit/instance binders, lambdas/Pi terms, contextual literals, lets, Bool conditions, selected matches, structures/inductives, structural recursion, ordinary partial definitions, namespaces and imports. Source inductives currently require Type0 results, have no level parameters or indices, and matching requires an expected result type and the supported single-motive recursor. Core universe/inductive machinery is broader than source-language acceptance. Neither extension means unrestricted native Lean. User class/instance declarations, universe declarations, tactic blocks, mutual blocks, macros and arbitrary dependent matching are not present in the shared AST selection.

The governing `PSC1_LANGUAGE_REFERENCE_v7.2.md` explicitly retains adjacent comma calls and selected native curried application; old blanket bans on spaced application are stale. Empty `f()` reaches `Term.psElabTermWithFuel` as an empty argument list and is rejected. Explicit Unit `f(())` works. The exactly-one-Unit/nullary surface change remains deferred until separately selected and qualified; do not silently change this profile during architecture integration.

## Baseline matrix

“Selected” means only the recorded fixtures, never arbitrary combinations. The accompanying JSON separates grammar, IR, target lowering, runtime evidence, ABI and assurance.

| Capability | Lean / PS source | Shared Core / IR | Seven-target runtime evidence | Exact boundary |
| --- | --- | --- | --- | --- |
| Definitions, literals, immutable lets, Bool branches | Selected / selected | Present | Selected cases | Public signatures use target ABI gate |
| Pi/dependent binders and checked theorem terms | Selected / selected | Core; proofs/types erased | Runtime not applicable to erased terms | Not unrestricted universe syntax, tactics or dependent runtime layouts |
| Rank-one generic functions | Selected / selected | Typed generic IR | Selected private helpers | Closed specialization on JS/TS/Wasm/Python/PHP; Rust generic path retained |
| Products, records, inductives and matches | Bounded / bounded | Present | Internal selected cases | No general seven-target aggregate foreign ABI |
| Structural recursion | Bounded / bounded | Checked recursor lowering | Feature-by-feature census required | Deep non-tail evidence is target/case-specific |
| Ordinary partial recursion | Selected / selected | Checked opaque witness plus exact body pairing | Selected cases | No behavioral certificate; checked/verified refusal retained |
| Closures and higher-order calls | Selected / selected | Present | Capture/map plus selected private nested closures | Rust aggregate closure storage remains limited |
| Nat/Int arithmetic and Unicode | Selected / selected | Present | Native-oracle comparisons on all seven | Exact Nat/Int; raw UTF-8 positions match pinned Lean; Int division/modulo outside profile |
| Operators/comparisons | Selected / selected | Selected operations | Selected cases | Prop-valued ordering missing; Bool equality surface only Nat/Bool |
| Local/call inference | Bounded / bounded | No unresolved metas permitted | Selected contextual cases | No general Lean inference claim |
| Id/Except do, mutation, return, finite for | Selected / selected | Checked immutable state/control | Selected cases | Finite loops construct O(n) continuations |
| CompilerM control/state | Selected / selected | Admitted and strict IR | Native/private JS comparisons | Other targets need dedicated CompilerM execution cases |
| Ordinary while | Selected / selected | Lifted checked private helpers | Finite execution and external divergence deadlines on all seven | Explicit partial owner; Id/Except; nested procedural loop/effect/capture restrictions remain |
| Tuple/wildcard bindings | Selected / selected | Strict RHS let plus projections | Handwritten cases all seven | Unit binding only native/private-JS evidence; mutable/monadic patterns refused |
| Array literals/persistence/optional indexing | Selected / selected | Present | Aliasing/OOB/huge-index cases all seven | Optional access currently full scan; no proof/panic indexing claim |
| Typed error propagation | Selected / selected | Except/CompilerM library calls | Selected Except cases | Throw/try/catch absent at baseline; candidate #167 not yet qualified |
| Namespaces/import ownership | Selected / selected | Full Core names and captured source closure | Handwritten namespace cases and host refusal tests | Namespace identity never grants entry-module ownership |
| Typed IO / foreign imports | Missing / missing | No admitted execution profile | None | Raw IR imports fail strict validation |
| Fixed-width/floating scalars | Outside profile | Some model/printer constructors exist | No active-profile claim | Type names/printer cases do not confer support |

The existing regular corpus obtains 82 observations plus two identity fields from pinned native Lean. It executes 14 target/grammar bundles, but most common PS corpus is translated from Lean; data/pattern/namespace additions include handwritten paired sources. Component execution calls the combined `semantic` Bool predicate. That predicate observes internal values; it does not qualify public numeric/aggregate component marshalling or every possible feature interaction.

## ABI is a separate axis

| Target | Current public interface | Runtime/output |
| --- | --- | --- |
| JS | Nat/Int bigint, Bool, Unicode strings/Char, Unit | Direct readable .js plus .d.ts and map |
| TS | Same scalar runtime contract | Direct .ts plus declarations/map; optional combined TS/JS generation prints both independently |
| Rust | Qualified generic/aggregate interfaces, subject to extra printer restrictions | .rs plus locked Cargo source package; owned Rc sharing and selected exact numeric dependencies |
| Core Wasm | Existing lowered Wasm types, including GC values where admitted | Validated .wasm; WAT disassembled from actual binary; no portable host-language aggregate marshalling claim |
| Component Wasm | Bool only | Exact WIT, validated component/core binaries and readable WAT |
| Python | Exact int (Bool rejected as integer), Bool, surrogate-free str/Char, None | .py/.pyi; origins cover declaration starts; generator scheduler where selected |
| PHP | GMP Nat/Int, Bool, valid UTF-8 string/Char, null | .php export-map module and Composer requirements; selected generator scheduler |

`BackendCommon.Plan.psBackendPublicTypeSupported` is preliminary and conjunctive with emitter checks. For example it does not override Rust's restrictions on nested public functions or aggregate closure storage. Dynamic scalar targets refusing a public record do not thereby lack internal records.

## Rust aggregate closures: precise P1 correction design

Confirmed source limits: `BackendRust.Type.psRustDirectClosureTypeSupportedWithFuel` rejects named type arguments containing functions. `Module.psRustEmitStructureFieldList` and constructor-field printing permit only first-order static function storage; `psRustValidateStaticStoredFunction` rejects local values and lambdas. Private directly nested closure support does not remove these limits.

Adopt a single internal **owned value type** renderer V(T), recursively:
- primitive/type parameter: current owned representation;
- function(A..., B): `Rc<dyn Fn(V(A)...) -> V(B) + 'static>`;
- Array(A): `Vec<V(A)>`;
- named data(A...): existing generated layout instantiated with V(A...).

Use this renderer for locals, captures, lambda parameters/results, aggregate fields, constructor fields, projections, array element types and computed results. Keep direct declaration calls as direct Rust functions; wrap a global function used as a value in a typed Rc closure, using actual IR type arguments rather than arity/name guessing. Current generic bounds `Clone + 'static` suffice for owned captured values; rank-polymorphic runtime values remain outside the profile. Instantiate generic callback types using the checked IR substitution machinery before rendering. This extends the existing Rc closure design, avoiding a second defunctionalized closure enum and avoiding lifetimes/borrowing in the portable semantics.

Existing data fields uniformly use `Rc<field-value>` to make derived Clone shallow. Initially keep that outer storage wrapper, even for an Rc function value: `Rc<Rc<dyn Fn...>>`. This costs one existing field indirection but preserves projection/match invariants and limits patch scope. Removing double Rc later requires a typed storage/projection abstraction and benchmark evidence. Do not mix `fn(...)` and closure trait objects implicitly. `#[derive(Clone)]` remains sufficient; function equality, Send/Sync and shared mutable captures are not selected capabilities.

Patch locations:
1. `Type.lean`: introduce recursive owned-value rendering; relax named-function-argument rejection only when recursive rendering succeeds.
2. `Module.lean`: structure/constructor layout printing, declaration parameter/result rendering, private function-result checks, and storage validators use V(T); replace static-only validation after every value emitter handles the representation.
3. `Expr.lean`: `psRustEmitStoredExprWith`, lambda/local rendering, generic global adapters, projections/matches and calls use the same expected IR type. Clone each lexical capture once before `move`, retaining value capture through shadowing and mutation.
4. `Captures.lean`, `Tail.lean`, `TailAlias.lean`: verify simultaneous argument updates/capture ownership; never introduce RefCell or unsafe self-reference to satisfy recursive captures.
5. Strict IR and public ABI gates remain in force. Initially test private dependency-module callbacks through scalar Bool exports so Rust internal support is qualified independently of new public foreign ABIs.

Pure immutable construction does not require runtime backpatching: recursion calls code and finite closure environments own earlier values. Do not introduce Rc cycles for recursive functions; use direct global recursion or explicit environment/code references. Deep destruction of existing recursive data and host-stack safety are separate measured risks; Rc is not a cycle collector.

Required fixtures: captured closure in structure and inductive; Array of closures; generic container of callbacks; returned/projected callback; nested-arrow callback; shadowed global callback; capture before lexical mutation; imported private helpers; malformed IR and unsupported public signatures. Run both grammars/all seven targets, plus Rust Cargo type checking. Test old and new record aliases after updates. Do not mark aggregate closures portable until these pass.

## Package ownership and readable output

Runtime semantic helpers already live with backend sources; formatting and transactional publication live under `host-tools` and are included by `scripts/npm-native-distribution.mjs`. Their directory outside packages is not a missing installed dependency. The qualified private native package includes the compiler with all seven emitters, host tools and locked npm dependencies. Target tools such as Cargo/wasm-tools/interpreters remain separately required by selected target validation.

Historical `packages/proofscript/package.json` and several scoped package manifests still describe PSC0 paths/versioning/generated JS; the native packer constructs the correct private PSC1 package explicitly. Keep the legacy package tree from being mistaken for a release-ready modular package set. Sol High should reconcile package ownership and generate/validate one current distribution contract before publication. No release or npm publication is authorized here.

JS/TS formatting is checked by parsed syntax-tree equality. Rust is rustfmt/Cargo validated. WAT describes the actual binary. Python/PHP are readable direct text with syntax checking; their origins are declaration-level, not full debugger maps. Readability is not a semantic proof.

## Executable parity policy for Sol High

Add a declarative finite contract with stable feature/case IDs and required grammar/target pairs. Tests should emit per-case receipts containing source/import hashes, compiler/tool identities, canonical admission hash, strict IR result, runtime result/typed observation and qualification commit/run. Build the matrix from these receipts rather than hand-editing pass strings.

A policy command should:
1. Enumerate every selected portable case across Lean/PS and seven targets. Reject missing, duplicated, unknown or skipped required pairs.
2. Require real runtime execution after successful target validation; ordinary source fixtures must record exact assurance and external timeout expectations. Theorem/type-only cases require admission/erasure checks and declare runtime not applicable.
3. Match expected observations to pinned native Lean or an explicit independently justified contract. Preserve evaluation order, aliasing, scopes, Unicode and negative refusal cases.
4. Keep source-language coverage separate from public ABI tests. Bool harness observations must identify internal cases and may not imply aggregate marshalling support.
5. Preserve old receipts by commit; current qualification must name the tested tree/merge and source HEAD. No “complete” family without all cases of its selected finite contract.
6. Treat logical admission/IR validation/execution as independent evidence fields. Formal behavioral preservation stays unavailable unless an actual checked certificate is implemented.

Implement as `scripts/check-language-backend-parity.mjs` over a versioned JSON contract and generated CI receipts, with a nonzero exit for any unmet portable obligation. The existing scripts may remain test drivers; the policy checker aggregates their explicit evidence instead of duplicating semantic tests.

Primary comparison references: [pinned Lean Except implementation](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Control/Except.lean), [Go specification](https://go.dev/ref/spec), [Rust loop reference](https://doc.rust-lang.org/reference/expressions/loop-expr.html), [TypeScript contextual typing](https://www.typescriptlang.org/docs/handbook/2/everyday-types.html), [Python compound statements](https://docs.python.org/3/reference/compound_stmts.html), [PHP error-handling source](https://github.com/php/doc-en/blob/master/language/error-handling.xml). These support familiar bounded syntax, explicit evaluation/scope rules and typed error values; PSC1's exact contract remains the pinned Lean implementation and its own selected profile. Current online Lean “latest” documentation describes 4.36.0-rc1 and must not substitute for the pinned 4.35.0 semantics.
