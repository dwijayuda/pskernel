# Core compiler capability inventory

## Authority and measured source denominator

Stage0 is `33676076bcda7b0de5ec1f9803f49b8b1d28a058` on `psc0/pscv0-v7-native-lean-v1`, using selected v7.2 and pinned Lean 4.35.0. Repository default `main` belongs to another historical line. Full M3 preparation is retained separately.

[Linux source inventory 39178166346](https://github.com/dwijayuda/pskernel/actions/runs/39178166346), source job `117825066237`, confirms the complete explicit portable import graph: **316 modules, 26,384,235 source bytes; 101 environment modules, 23,654,198 bytes; no unresolved project imports**. The candidate at `851faf84` adds only the fingerprint import seam to that portable graph: 317 modules and 26,384,298 bytes. These are source composition measurements, not a Core size improvement or semantic closure claim.

The scanner blanks nested comments, raw/ordinary strings and character literals, uses current source owners, and excludes historical duplicate `legacy` modules. It retains exact content hashes and imports in the CI artifact. Lean's implicit Init, inserted instances, generated declarations and runtime dependencies need the independent typed declaration audit. Feature counts are lexical signals, not source acceptance tests.

## Actual entry points

[NativeV7](../host/src/Ps/Host/NativeV7.lean) imports these seven portable roots:

- `Ps.Compiler.Pscv0Modules`
- `Ps.BackendTs.Readable`
- `Ps.BackendRust.Module`
- `Ps.BackendWasm.Module`
- `Ps.CompilerIr.Checked`
- `Ps.Codegen.Api`
- `Ps.Codegen.Provenance`

Its additional `PsKernelLean.Protocol` and `PsKernelLean.Prelude` imports are host checking adapters. The actual selected source route is `psCompilerPreparePscv0Project` in [Pscv0Modules](../packages/compiler/src/Ps/Compiler/Pscv0Modules.lean), using the readers and command elaborator in [Pscv0](../packages/compiler/src/Ps/Compiler/Pscv0.lean). The old `Bootstrap.SelfHost → BackendTs.Compiler → psCompilerPrepareSource` path is a different API and denominator.

## Actual workload and conversion obligations

| Source owner | Implementation requirement | Core acceptance obligation |
| --- | --- | --- |
| Foundation, Core, Meta | Polymorphic functions; Nat/List/tree recursion; callbacks and returned closures; records/local state | Preserve binders, captures, errors and actual recursive arguments through selected source and checked lowering |
| Syntax readers | Recursive patterns, records/default fields, token traversal, positions and both selected grammars | Preserve scope, UTF8 byte offsets, source identity and first errors without a native parser fallback |
| `Syntax/Ast.lean` | Mutual data: PsSyntaxTerm/PsSyntaxDoItem/PsSyntaxTactic | Explicit selected-source representation required; native mutual data is not authorized by the function-only selected mutual grammar |
| `BackendEcma/Syntax.lean` | Mutual data: Expr/Stmt | Preserve every constructor field and result family under a checked selected representation |
| Seven mutual function blocks | Fuel-recursive parser, instance search, equality and ECMA traversals | Qualify actual mutual functions and callbacks/partial applications of smaller fuel; distinguish this from mutual data |
| Elab, compiler, erasure | Inference, substitutions, declaration metadata, prepared admissions, proof erasure/runtime ownership | Preserve the shared checked owners and interfaces; features represented as PsExpr data are not automatically source-language requirements |
| Twelve deriving clauses | BEq, Repr and Inhabited on compiler data | Qualify the actual clauses and generated declaration closure |
| Fingerprint, originally StandardSnapshot | UInt64 FNV, UInt32 SHA, bytes and one padding while | Admit real word/byte proofs and primitive semantics; the padding loop has fewer than 64 iterations and can be converted to a checked bounded traversal |
| Foundation.Name, Syntax.Cursor | UTF8/string cursor operations, Nat/Int rendering | Preserve exact checked identities or qualify an equivalent selected-source conversion, including non-ASCII input |
| Wasm binary/component owners | UInt8 bytes, UInt32/UInt64 bit fields and ByteArray output | Keep these dependencies while Wasm remains advertised; this alone does not require native Float arithmetic |

One possible representation for each mutual-data group is a single indexed family over a closed role tag, retaining all constructor telescopes and result roles. This is a design option, not a completed conversion. An untyped sum is not a substitute for those distinctions.

The complete lexical scan reports nine mutual blocks (two data, seven functions), twelve deriving clauses and one while. It reports no implementation-source theorem, axiom, class, instance, opaque, partial definition, partial_fixpoint, termination_by or tactic-proof declaration. It does not imply those concepts are absent from library proofs or generated declarations. In particular, the typed UInt proof closure reaches Acc, WellFounded.fix/fixF, WellFoundedRelation and Nat.lt_wfRel.

## Import isolation gates

Removing Full composition from Api's five shared implementation roots yields a fully read 112-module graph with no Standard/Prelude dependency. The selected command frontend has additional Standard edges through DerivingInhabited and DerivingRepr. Their expression-builder helpers must move to generic leaves before the selected frontend can claim that import isolation.

The first Linux-guarded leaves are Fingerprint (10 modules, 46,242 bytes) and native Replay (12 repository modules, 50,030 bytes plus the explicit Lean toolchain import). These figures describe their exact `851faf84` source closures. They do not describe a complete Core compiler, seed or package.

## Qualification sequence

Freeze and compare the module roster against native declaration ownership. Collect actual type/body/family/rule dependencies, including private and generated helpers. Resolve the selected representation blockers. Admit the resulting Standard and metadata from an empty checked boundary, then execute actual compiler source through both selected routes. Expand only from observed failing obligations, keeping the complete source denominator visible.
