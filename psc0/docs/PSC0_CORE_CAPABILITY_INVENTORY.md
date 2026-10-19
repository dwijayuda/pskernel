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

Its additional `PsKernelLean.Protocol` and `PsKernelLean.Prelude` imports are host checking adapters. NativeV7 retains `psCompilerPreparePscv0Project` in [Pscv0Modules](../packages/compiler/src/Ps/Compiler/Pscv0Modules.lean) as its Full compatibility entry. Shared graph, imported-interface and selected-source preparation now belongs to [Pscv0ModuleEngine](../packages/compiler/src/Ps/Compiler/Pscv0ModuleEngine.lean), which accepts the actual environment/runtime context and uses Pscv0Engine. The old `Bootstrap.SelfHost → BackendTs.Compiler → psCompilerPrepareSource` path remains a different API and denominator.

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

At the recorded `9f06af4c`/`93107e` boundary, Engine had 113 modules / 1,705,386 bytes and selected Pscv0Engine had 159 modules / 2,211,770 bytes. All 24 unchanged expression-builder helpers had moved to InhabitedExpr/ReprExpr, removing their Full/Standard/host dependency. The paired selected `.lean`/`.ps` probe and independent canonical admission passed at `93107eab14b7347f9605b1396c7a79f2b628ba61`, [run 39181815014](https://github.com/dwijayuda/pskernel/actions/runs/39181815014). These cuts are complete.

Fresh selected project preparation now runs through Pscv0ModuleEngine with the actual caller environment/runtime context. At `d444e33d4f076d56ce141745c7ac0c7787dbd9f3`, its graph reaches 160 modules / 2,229,231 bytes; the project plus actual IR/codegen/backend roots reaches 224 modules / 2,783,218 bytes, with no Full, host or unresolved project import. The earlier 223-module / 2,765,757-byte graph excluded project preparation and remains historical. Actual whole-compiler source qualification and external artifact authentication are separate obligations; no selected persistent-cache loader currently exists. Retain the [complete source/blob inventory](PSC0_CORE_SOURCE_AUDIT.json).

The first Linux-guarded leaves are Fingerprint (10 modules, 46,242 bytes) and native Replay (12 repository modules, 50,030 bytes plus the explicit Lean toolchain import). These figures describe their exact `851faf84` source closures. They do not describe a complete Core compiler, seed or package.

## Qualification sequence

The earlier native ownership audit matched the full 321-module route to its source inventory, including 191,611 owned private/generated declarations and 458 external roots. Its 5,690-declaration raw external closure has no unsafe/partial entries and reaches the three approved logical assumptions. These dated observations are not a selected Core declaration manifest. Review assumption paths and the current source owner graph, resolve selected representation blockers, and expand independently checked candidate/source coverage only from observed failing obligations, retaining the complete compiler denominator.

## Qualified complete compiler-source subset

At `1995a478af7aeb83032749fbdb9a2cfa96d28a88`, [run 39191534560](https://github.com/dwijayuda/pskernel/actions/runs/39191534560) passed all four Core-first Linux jobs. PSC0 accepted both complete original Foundation.Source and Foundation.List files and their ProofScript counterparts through the explicit-context project engine, produced identical canonical admissions, and independently admitted both results over the measured 92-declaration candidate. It retained every original seed declaration/effective reducibility and the measured source metadata. Native elaboration parity, emitted backend execution and whole-compiler selfhost remain unqualified.

| Complete compiler module | Original bytes | ProofScript bytes | Original source declarations |
| --- | ---: | ---: | ---: |
| Ps.Foundation.Source | 148 | 151 | Two structures: PsSourcePos and PsSourceSpan |
| Ps.Foundation.List | 2,386 | 2,538 | Ten functions, all retained |

The List denominator contains psListLength, psListIsEmpty, psListAny, psListReverseAcc, psListReverse, psListAppend, psListMap, psListMapExcept, psListTake and psListZip. The gate imports both files through a separate entry, checks exact files/paths/hashes, and records all 25 prepared names. Generated helpers for ReverseAcc, Take and Zip are retained. The [raw receipt](core-first-evidence/compiler-source-qualification.json) distinguishes original headers from generated and prepared declarations.

The measured candidate environment source graph is 11 modules / 211,778 bytes, including its 174,266-byte data asset; it has no Full or external explicit import. The complete compiler denominator remains the broader inventory. [Next inspected modules](core-first-evidence/next-compiler-source-workload.json) are Token, then Cursor/Name with measured String/Char and actual extern/runtime obligations. They have no selected-source acceptance yet.
