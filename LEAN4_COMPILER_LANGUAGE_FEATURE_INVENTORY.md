# Lean 4 Compiler Source: Comprehensive .lean Language-Feature Inventory

**Status:** source-grounded research inventory, not a compiler implementation and not a mechanical exhaustive Lean AST theorem.  
**Repository destination:** `dwijayuda/pskernel`, root `main`.  
**Research date:** 2026-10-08.  
**Primary source:** Lean 4.35.0-rc3 commit `470d5ce1400764999581fd26d5d72b00d990b0f4` ([pinned Lean source tree](https://github.com/leanprover/lean4/tree/470d5ce1400764999581fd26d5d72b00d990b0f4)). This is the semantic reference pin currently used by the PSCV design.  
**Repository-local research source:** [`study/lean4-4.34.0`](https://github.com/dwijayuda/pskernel/tree/main/study/lean4-4.34.0) and [`study/lean4-language-reference`](https://github.com/dwijayuda/pskernel/tree/main/study/lean4-language-reference), with related [Functional Programming in Lean mirror](https://github.com/dwijayuda/pskernel/tree/main/study/functional_programming_in_lean) and [Lean4Lean mirror](https://github.com/dwijayuda/pskernel/tree/main/study/lean4lean-master).  
**Companion PSCV design:** [PSCV Self-Host Portable Language Reference](https://github.com/dwijayuda/pskernel/blob/main/PSCV_SELFHOST_PORTABLE_LANGUAGE_REFERENCE.md); [PSCV Compiler Reference V5.1](https://github.com/dwijayuda/pskernel/blob/pscv/v3-execution/psc15selfhost/THE_PSCV_COMPILER_REFERENCE_VERSION_5.1.md).

> **Inventory claim, carefully delimited.** This is a broad **language-feature-family** catalogue based on direct source-code inspection of **all 117 `src/Lean/Compiler/**/*.lean` files** from the pinned commit, representative files from the language frontend (`Elab`, `Meta`, `Parser`), `Init`, `Std`, Lake, the editor/server, and the user's existing GitHub study snapshots. It does **not** claim to be a fully parsed occurrence-by-occurrence census of every `.lean` file in the 2,536-file Lean/Init/Std/Lake source tree. A feature may be present in an uninspected helper; counts are intentionally labelled **approximate lexical counts**. Features supported in the language but **not confirmed in actual implementation files** are documented separately rather than misrepresented as used.

## 0. Executive findings

Lean 4 is a genuine self-hosted compiler frontend/backend implemented substantially in Lean 4 itself, with `module`/`public import`/`meta import` source modes, namespaces, implicit/dependent types, inductives/structures, instances/deriving, higher-order functions, extensive monadic `do`, `let mut`, finite indexed `for`, some `while`, early returns, `try/catch`, source macros, quotations, custom elaborators, theorem/tactic proofs, and managed `IO`/async runtime code. **It also uses `partial def`, `unsafe`, `opaque` and generated/external runtime primitives** where proving totality or implementing optimized platform-specific behavior would be impractical.

**It is not an all-Lean trusted kernel.** The [pinned `src/kernel`](https://github.com/leanprover/lean4/tree/470d5ce1400764999581fd26d5d72b00d990b0f4/src/kernel) contains C++ type checking, expression and inductive code. The [`src/runtime`](https://github.com/leanprover/lean4/tree/470d5ce1400764999581fd26d5d72b00d990b0f4/src/runtime) is mainly C++ runtime support. [`stage0`](https://github.com/leanprover/lean4/tree/470d5ce1400764999581fd26d5d72b00d990b0f4/stage0) supplies pre-generated C bootstrap artifacts. That distinction matters for the PSCV goal of eventually owning the compiler, runtime and kernel.

**PSCV implications:** use this inventory to select a *long-term readable portable implementation subset*, not to copy every Lean feature. In particular, `do`, local mutation, registered finite loops, ADTs, typed errors, and total recursion can improve the compiler source while keeping a smaller proof model. Arbitrary `partial`/`unsafe`, imported metaprogramming, ambient IO, unchecked FFI, aliasable refs, and full Lean macro facilities should remain development/host-only or explicit non-closed boundaries until separately modeled and proved. Compiler self-hosting does not itself establish kernel soundness or backend-preservation theorems.

## 1. Audit scope, reproducibility and methodology

### 1.1 Exact audited trees (pinned Git trees)

The repository tree listings directly identify these `.lean` file counts:

| Source subtree at pinned 4.35-rc3 commit | `.lean` files | What it implements |
|---|---:|---|
| `src/Lean` | **1,226** | Parser, elaboration, metavariable inference, tactics, compiler, server, utilities |
| `src/Lean/Compiler` | **117** (subset of `src/Lean`) | LCNF/IR, passes, C and LLVM emitters, external attributes |
| `src/Lean/Elab` | **320** (subset) | Definition/elaboration logic, syntax and tactic elaborators |
| `src/Lean/Meta` | **482** (subset) | Metavariables, synthesis, tactic engines and elaboration helpers |
| `src/Lean/Parser` | **17** (subset) | Parser combinators and Lean concrete syntax definitions |
| `src/Lean/Server` | **44** (subset) | Language server, snapshots, code actions, async tasks |
| `src/Init` | **652** | Prelude, typeclasses, recursors, monads, arrays, strings, proofs |
| `src/Std` | **493** | Standard libraries, tactics, WP/verification, collections, IO |
| `src/lake` | **165** | Lake build DSL, package model, build graph and CLI |
| **Non-overlapping Lean/Init/Std/lake total** | **2,536** | Counts exclude the C++ kernel/runtime and stage0 C |

Trees were read through the GitHub Git Trees API using the **pinned commit**, not a moving `master`. Counts refer to filenames ending in `.lean`; directory summaries inside `src/Lean` **overlap** and must not be summed.

### 1.2 All compiler `.lean` files were lexically surveyed

An API-based audit retrieved **117/117** pinned `src/Lean/Compiler/**/*.lean` files, approximately **26,880 lines** total. Source lines were searched for language-feature token patterns after stripping only simple `--` line-comment suffixes. These counts are **heuristics**: block/doc comments, strings, macro quotations and identifier names can inflate matches; matching tokens is not an AST-level parser classification.

| Source-token pattern | Compiler files with ≥1 apparent occurrence | Interpretation / confidence |
|---|---:|---|
| `do` | 106/117 | Widespread monadic code; strong source examples |
| `for` | 90/117 | Frequent loop-oriented code; may include prose in comments |
| `match` | 96/117 | Widespread structural pattern matching |
| `fun` | 98/117 | Widespread lambdas/closures; token method conservative |
| `where` | 85/117 | Local definitions, class fields or documentation |
| `partial def` | 75/117 | Widespread partial recursion; corroborated by code |
| `let mut` | 54/117 | Mutable locals widely used |
| `mutual` | 35/117 | Mutual recursion and grouped code |
| `inductive / structure` | 68/117 | Typed AST/IR/state declarations |
| `class / instance` | 38/117 | Typeclass abstractions |
| `deriving` | 31/117 | Autogenerated instances |
| `termination_by` | 6/117 | Explicit checked well-founded recursion, less frequent |
| `while` | 7/117 | Occasional while loops |
| `unsafe` token | 11/117 | Unsafe/runtime boundaries; some may be strings/docs |
| `@[…]` attribute opener | 59/117 | Compiler and elaboration attributes |

Do **not** interpret these as proportions of all source declarations or as frequencies across the complete 2,536 files. At least some matches reflect comments/strings; cited line-level examples below provide confirmation of actual syntax use. A future exact census requires Lean-parsed AST traversal of all source files under the pinned toolchain and explicit declaration/quotation classification.

### 1.3 How to read source evidence

Every feature-table row below links to a **pinned Lean 4 source file and code line** where the feature, its implementation syntax, or its parser/elaborator definition can be inspected. "compiler" means actual backend code; "elaborator/parser" means the Lean frontend; "Init/Std" means underlying library implementation; "Lake/server" means tooling written in Lean. Rows referencing a parser **define** a language form and are not necessarily evidence it occurs inside the LCNF backend. Example file paths, symbols and feature spellings preserve Lean's own terminology; PSCV status is an independent recommendation.

### 1.4 The `study` tree is informative but has its own pins

The pskernel `study/lean4-4.34.0` directory contains the original source layout with `src/Lean/Compiler`, `src/Lean/Elab`, `src/Lean/Meta`, C++ kernel and runtime, tests, stage0, and [`doc/dev/bootstrap.md`](https://github.com/dwijayuda/pskernel/blob/main/study/lean4-4.34.0/doc/dev/bootstrap.md). The pinned 4.34 snapshot contains **1,217 `src/Lean` `.lean` files**, versus **1,226** in upstream 4.35; it is a genuine independent snapshot, not the authoritative 4.35 code.

The repository-local `study/lean4-language-reference` is a mirrored HTML snapshot of the Lean documentation. Some pages include generated metadata from **2026-08-21** and an HTTrack mirror timestamp in September 2026; therefore it is a **useful reference** but not proof of exact 4.35-rc3 parser/runtime behavior. The user-facing [Lean 4 language reference](https://lean-lang.org/doc/reference/latest/) documents features and links to current compiler implementation; the pinned `.lean` source remains the historical oracle for this inventory.

## 2. Repository architecture: where Lean's own .lean source is used

| Layer | Actual locations | Why it matters for the language feature inventory |
|---|---|---|
| Foundation | `src/Init/Prelude.lean`, `src/Init/Data`, `src/Init/Control` | primitive inductive types, functional control abstractions, monad transformers, array/string operations and proofs |
| Parser & syntax | `src/Lean/Parser`, `src/Lean/Syntax.lean` | parser combinators, declaration modifiers, quotation syntax, categories, custom syntax |
| Elaborator | `src/Lean/Elab` | term/type elaboration, macros, instance resolution interface, mutual definitions, `do` lowering |
| Metaprogramming | `src/Lean/Meta` | metavariable operations, inference, unification, reduction, proof automation |
| Compiler | `src/Lean/Compiler/LCNF` and `src/Lean/Compiler/IR` | functional and stateful passes, typed IR, monomorphization, C/LLVM output, compiler attributes |
| Verified effects | `src/Std/WP`, `src/Lean/Elab/Tactic/Do` | weakest preconditions, intrinsic verification syntax and VC generation |
| Toolchain | `src/lake/Lake`, `src/Lean/Server` | package DSL, build graph, IO, async tasks, incremental processing |
| Trusted checker | `src/kernel` (C++) | final Lean typechecker; **not** principally `.lean` |
| Runtime | `src/runtime` (C++) | runtime objects, reference counting, allocation, big integers, IO |
| Bootstrap | `stage0/src` generated C, then stages 1–3 | breaks the self-hosting dependency cycle |

A useful source-to-output decomposition is `.lean text → Parser Syntax → Elaborator Expr → kernel check of declarations → LCNF/IR transformations → C or LLVM/native output`. Details of optimizer passes and runtime ABI are implementation mechanisms, **not additional Lean source-language syntax features**.

---


## 3. Module system, source units, visibility, namespace and imports

| Lean feature | What actual source uses it for | Pinned code evidence | Component | PSCV portable implication |
|---|---|---|---|---|
| `module` header | Lean 4 module framing | [CompilerM.lean:6](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/CompilerM.lean#L6) | compiler | Lean module control; not a proof rule |
| `prelude` | minimal import/prelude behavior | [CompilerM.lean:8](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/CompilerM.lean#L8) | compiler | Pin standard environment |
| `public import` | transitive compile-time interface imports | [CompilerM.lean:9](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/CompilerM.lean#L9) | compiler | Explicit import closure |
| `meta import` | compile-time/metaprogramming import mode | [Command.lean:11](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Parser/Command.lean#L11) | parser | Separate host-only Meta from portable runtime |
| ordinary `import` | nonreexported source module imports | [Syntax.lean:9](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/lake/Lake/DSL/Syntax.lean#L9) | Lake | Source graph must be exact |
| `public section` | visibility-scoped section mode | [PassManager.lean:13](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/PassManager.lean#L13) | compiler | Profile source visibility deterministically |
| `namespace ...` | qualified names and scoped declarations | [Basic.lean:18](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Basic.lean#L18) | compiler | Admit under approved name semantics |
| `open` / local namespace open | unqualified resolver/context | [EmitC.lean:98](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/EmitC.lean#L98) | compiler | Registry/name resolution can differ from PSCV |
| `open ... in` | expression-/declaration-scoped open | [Specialize.lean:303](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Specialize.lean#L303) | compiler | Bounded source-scoping feature |
| `private` declaration | name/visibility modifier | [CompilerM.lean:193](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/CompilerM.lean#L193) | compiler | Normal source privacy, independent of target |
| `protected` / public modifiers | namespaces and declaration lookup | [Command.lean:73](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Parser/Command.lean#L73) | parser | Do not treat Lean parser syntax as PSCV grammar |
| `universe u v` | named universe parameters | [Basic.lean:24](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Data/Array/Basic.lean#L24) | Init | Dependent-type parametric declarations |
| `variable {α : Type u}` | section binder variables | [Basic.lean:37](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Data/Array/Basic.lean#L37) | Init | Implicit binder and section dependency |
| `meta` declaration modifier | compile-time-only declaration restrictions | [Command.lean:94](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Parser/Command.lean#L94) | parser | Host/meta-specific; exclude unrestricted in portable source |

## 4. Core declarations, data definitions and definition modifiers

| Lean feature | What actual source uses it for | Pinned code evidence | Component | PSCV portable implication |
|---|---|---|---|---|
| `def` | ordinary typed function/value declaration | [EmitC.lean:27](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/EmitC.lean#L27) | compiler | Essential |
| `private def` | locally visible definition | [PassManager.lean:130](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/PassManager.lean#L130) | compiler | Essential |
| `abbrev` | reducible/transparent alias | [CompilerM.lean:49](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/CompilerM.lean#L49) | compiler | Controlled exposure in portable subset |
| `inductive` | sum types, indexed parameterized inductives | [Basic.lean:37](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Basic.lean#L37) | compiler | Essential AST/Core/IR |
| `structure ... where` | product records, field defaults | [PassManager.lean:51](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/PassManager.lean#L51) | compiler | Essential checked state |
| `class ... where` | typeclasses/typeclass fields | [ConstantFold.lean:35](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Simp/ConstantFold.lean#L35) | compiler | Allow closed instance registries |
| `instance ... where` | implementations of typeclasses | [PassManager.lean:22](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/PassManager.lean#L22) | compiler | Deterministic instance search |
| `instance (priority := low)` | priority-controlled instance selection | [EmitC.lean:148](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/EmitC.lean#L148) | compiler | Must freeze instance order |
| `deriving` | generated equality/hash/inhabited instances | [Basic.lean:29](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/IR/Basic.lean#L29) | compiler | Stable verified generated code only |
| `mutual ...` | mutually recursive definitions | [InferType.lean:120](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/InferType.lean#L120) | compiler | Total if promoted to PSCV |
| `where` local definitions | scoped helper equations | [CompilerM.lean:196](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/CompilerM.lean#L196) | compiler | Total and stable helpers |
| `partial def` | recursive compiled definition logically opaque | [CompilerM.lean:193](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/CompilerM.lean#L193) | compiler | Exclude from PSCV verified executable closure |
| `unsafe def` | runtime implementation outside safe logical reasoning | [Basic.lean:169](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Do/Basic.lean#L169) | elaborator | Exclude from PSCV certified source |
| `opaque` | constant without normal definitional reduction | [Basic.lean:125](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Basic.lean#L125) | compiler | Require source-spec/runtime implementation relation |
| `@[implemented_by]` | link opaque logical interface to runtime implementation | [PassManager.lean:219](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/PassManager.lean#L219) | compiler | Potential TCB boundary; not a proof |
| `theorem` | kernel-checked proposition and proof | [PassManager.lean:44](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/PassManager.lean#L44) | compiler | Proof-only/source verification |
| `example` | local checked proposition/sample | [Basic.lean:653](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Data/Array/Basic.lean#L653) | Init | Proof tests not runtime semantics |
| `noncomputable` modifier | logical value without ordinary executable code | [Command.lean:95](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Parser/Command.lean#L95) | parser | Proof/spec-only in PSCV |
| `axiom` declaration syntax | logical axiom declaration form | [Command.lean:506](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Parser/Command.lean#L506) | parser | Do not infer used by backend runtime; disallowed user axioms in PSCV |
| `protected theorem` | qualified theorem declaration scope | [Prelude.lean:873](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Prelude.lean#L873) | Init | Proof visibility and namespace semantics |
| `builtin_initialize` | module environment/trace initializer | [Specialize.lean:30](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Specialize.lean#L30) | compiler | Metaprogramming/bootstrap side-effect boundary |
| `register_builtin_option` | registered environment configuration option | [BEq.lean:22](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Deriving/BEq.lean#L22) | elaborator | Pin option registry |

## 5. Binders, polymorphism, dependent types and typeclasses

| Lean feature | What actual source uses it for | Pinned code evidence | Component | PSCV portable implication |
|---|---|---|---|---|
| `Sort u` | universe polymorphism and sorts | [InferType.lean:30](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/InferType.lean#L30) | compiler | Underlying Lean dependent theory |
| `Type u` | universe-polymorphic type argument | [InferType.lean:42](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/InferType.lean#L42) | compiler | Keep vs runtime specialization separate |
| implicit `{α}` binders | inferred type parameters | [Basic.lean:37](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Data/Array/Basic.lean#L37) | Init | Exact PSCV binder behavior |
| instance implicit `[ToString α]` | typeclass dictionary arguments | [EmitC.lean:148](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/EmitC.lean#L148) | compiler | Closed deterministic instances |
| dependent function `(x : α) → ...` | Pi type terms | [InferType.lean:30](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/InferType.lean#L30) | compiler | Proof-capable, potentially erased indices |
| function type `α → β` | nondependent arrows | [InferType.lean:30](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/InferType.lean#L30) | compiler | Essential |
| `outParam` typeclass parameters | dependent instance-search guidance | [CompilerM.lean:311](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/CompilerM.lean#L311) | compiler | Requires pinned resolution semantics |
| type-indexed IR `Arg pu` | phase-indexed Lean types | [InferType.lean:121](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/InferType.lean#L121) | compiler | Keep source-level proof indices where erasure is sound |
| `.pure` / `.impure` phase indices | target/source index specialization | [EmitC.lean:309](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/EmitC.lean#L309) | compiler | Do not conflate indexed phase with source effect |
| `Monad` typeclass instance | type-directed bind/pure interface | [CompilerM.lean:52](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/CompilerM.lean#L52) | compiler | Registered lawful effect interface |
| `MonadScope` instance | abstract computation scope | [Specialize.lean:90](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Specialize.lean#L90) | compiler | Bounded interface allowed with specified laws |
| `ToString` instance | formatted output via typeclasses | [PassManager.lean:22](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/PassManager.lean#L22) | compiler | No target-host formatting drift |
| `BEq` / `Hashable` deriving | equality/hash instances | [Basic.lean:29](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/IR/Basic.lean#L29) | compiler | Require equality/hash laws |
| `Coe` instance | coercion for typed syntax or terms | [Command.lean:277](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Parser/Command.lean#L277) | parser | Exact coercion behavior and source profile |
| `DecidableEq` derivation | decision procedure for equality | [Basic.lean:48](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Basic.lean#L48) | compiler | Kernel checked derivation semantics |
| `Inhabited` derivation | default inhabitant instance | [PassManager.lean:97](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/PassManager.lean#L97) | compiler | Avoid arbitrary default return on exhaustion |
| `Fin`-indexed looping | proof-carrying index in loop | [EmitC.lean:197](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/EmitC.lean#L197) | compiler | Bounds preservation across targets |
| `Prop` proof goal | propositional proofs embedded in definitions | [PassManager.lean:44](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/PassManager.lean#L44) | compiler | Erase proof-only dependencies safely |

## 6. Expressions, patterns, functions and local data

| Lean feature | What actual source uses it for | Pinned code evidence | Component | PSCV portable implication |
|---|---|---|---|---|
| ordinary application | Lean whitespace-call function application | [CompilerM.lean:52](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/CompilerM.lean#L52) | compiler | ProofScript uses different call surface |
| `fun x => ...` lambdas | first-class functions/closure capture | [CompilerM.lean:55](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/CompilerM.lean#L55) | compiler | No escaping mutable references |
| `match ... with` | pattern matching on ADTs | [CompilerM.lean:199](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/CompilerM.lean#L199) | compiler | Exhaustiveness and case order |
| constructor patterns `| .ctor ... =>` | tagged pattern and branch binding | [Basic.lean:943](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Basic.lean#L943) | compiler | Typed source constructor identity |
| `if ... then ... else` | dependent/nondependent conditions | [CompilerM.lean:76](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/CompilerM.lean#L76) | compiler | No JavaScript truthiness |
| `if let some x := ...` | pattern guard conditional | [Basic.lean:816](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Basic.lean#L816) | compiler | Desugaring must preserve branches |
| `let x := ...` | pure local let binding | [CompilerM.lean:52](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/CompilerM.lean#L52) | compiler | Essential |
| pattern let `let ⟨x, y⟩ := ...` | pair constructor destructuring | [PassManager.lean:147](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/PassManager.lean#L147) | compiler | Source tuple semantics explicit |
| partial-pattern let `let .code := ... | panic!` | pattern-match with failure continuation | [Specialize.lean:332](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Specialize.lean#L332) | compiler | Avoid unchecked panic in verified code |
| record update `{ s with field := value }` | typed functional update | [CompilerM.lean:55](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/CompilerM.lean#L55) | compiler | Essential immutable state abstraction |
| anonymous constructor `⟨a,b⟩` | type-directed tuple/structure construction | [PassManager.lean:147](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/PassManager.lean#L147) | compiler | No dynamic structural typing |
| leading-dot constructors `.some/.return/.code` | expected-type constructor inference | [Basic.lean:943](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Basic.lean#L943) | compiler | Exact constructor inference |
| `Option` patterning | optional values/nonexistence | [CompilerM.lean:76](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/CompilerM.lean#L76) | compiler | Typed absence, not JS undefined |
| `Except` matching and errors | typed success/failure branches | [Except.lean:121](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Control/Except.lean#L121) | Init | No host throw interpreted as logical Except |
| `|>` pipelines | functional postfixed application composition | [BEq.lean:196](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Deriving/BEq.lean#L196) | elaborator | Unfold to ordinary typed applications |
| `<|` reverse application | readable nested function applications | [EmitC.lean:158](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/EmitC.lean#L158) | compiler | Pure syntax sugar |
| `←` monadic bind | read effect result in do | [VCGen.lean:40](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Tactic/Do/VCGen.lean#L40) | tactic | Exact monad and WP |
| `match-syntax` quotations | pattern matching on syntax trees | [Macro.lean:19](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Macro.lean#L19) | elaborator | Metaprogramming/host-only in PSCV |
| `try ... catch` | typed effectful exception handling | [EmitLLVM.lean:1254](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/IR/EmitLLVM.lean#L1254) | compiler | Model effect and exit behavior |
| `finally` | finalizer in structured exception scope | [TryCatch.lean:46](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/BuiltinDo/TryCatch.lean#L46) | elaborator | Host/effect boundary unless verified |
| `s! string interpolation` | interpolated strings | [PassManager.lean:134](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/PassManager.lean#L134) | compiler | Exact Unicode/formatting if admitted |
| `m! message interpolation` | diagnostic message syntax | [SynthInstance.lean:55](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Meta/SynthInstance.lean#L55) | meta | Host tooling not guaranteed source core |

## 7. Iteration, local mutation, effects, and proof-friendly recursion

| Lean feature | What actual source uses it for | Pinned code evidence | Component | PSCV portable implication |
|---|---|---|---|---|
| `do` monadic sequencing | sequencing with typed monads | [PassManager.lean:130](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/PassManager.lean#L130) | compiler | F0 portable when WP registered |
| `let mut` | locally scoped mutable accumulator | [PassManager.lean:141](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/PassManager.lean#L141) | compiler | SHP2 high-priority feature |
| `for x in values do` | finite collection iteration | [PassManager.lean:131](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/PassManager.lean#L131) | compiler | Registered finite iterator and invariant |
| `for h : i in range` | dependent/proof-carrying index iteration | [EmitC.lean:197](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/EmitC.lean#L197) | compiler | Index/array proof semantics |
| `while true do` | imperative repeated effectful loop | [EmitC.lean:404](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/EmitC.lean#L404) | compiler | Full PSCV verified while; optional source subset |
| `break` | loop control exit | [For.lean:238](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/BuiltinDo/For.lean#L238) | elaborator | Verify invariant on exit |
| `continue` | loop next iteration | [For.lean:238](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/BuiltinDo/For.lean#L238) | elaborator | Verify decreasing/progress |
| `return` early exit | monadic return/continuation control | [EmitC.lean:197](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/EmitC.lean#L197) | compiler | Correct postcondition for every path |
| `unless condition do` | negated conditional statement | [Specialize.lean:393](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Specialize.lean#L393) | compiler | Equivalent Bool proof obligation |
| `try ... catch err =>` | exception handler pattern | [EmitLLVM.lean:1257](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/IR/EmitLLVM.lean#L1257) | compiler | Typed errors and target resource contract |
| `let x ← action` | monadic action bind | [PassManager.lean:141](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/PassManager.lean#L141) | compiler | Typed effect sequencing |
| `Id.run do` | pure local imperative syntax | [FileWorker.lean:106](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Server/FileWorker.lean#L106) | server | Lower locally mutable state into total computation |
| `StateT` | explicit state monad transformer | [State.lean:25](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Control/State.lean#L25) | Init | State model and WP |
| `ReaderT` | readonly environment and contextual effects | [CompilerM.lean:49](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/CompilerM.lean#L49) | compiler | Registered reader semantics |
| `StateRefT` | mutable-ref implementation of stateful compiler monad | [CompilerM.lean:49](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/CompilerM.lean#L49) | compiler | Host/local effect; audit aliasing |
| `ExceptT` | typed error transformer | [Except.lean:131](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Control/Except.lean#L131) | Init | Error and state order significant |
| `OptionT` | failure/optional computation transformer | [VCGen.lean:60](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Tactic/Do/VCGen.lean#L60) | VCGen | Failure not generic proof success |
| `CompilerM` | custom composite compiler monad | [CompilerM.lean:49](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/CompilerM.lean#L49) | compiler | Pinned transitive effect identity |
| `CoreM/MetaM/TermElabM/DoElabM` | compiler/elaboration custom monads | [VCGen.lean:40](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Tactic/Do/VCGen.lean#L40) | tactic | Host proof construction, not kernel authority |
| `termination_by` | well-founded termination measure | [Specialize.lean:279](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Specialize.lean#L279) | compiler | PSCV requires kernel decrease proof |
| `decreasing_by ... omega` | proof script for recursion decreases | [Basic.lean:86](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Data/String/Basic.lean#L86) | Init | Proof-producing tactic under kernel |
| `mutual` recursion | mutually defined functions | [InferType.lean:120](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/InferType.lean#L120) | compiler | Totality proof mandatory for SHP2 |
| `partial def` general recursion | logically opaque compiled recursion | [InferType.lean:121](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/InferType.lean#L121) | compiler | Forbidden in PSCV closed runtime |
| `unsafe def` | native unsafe escape hatch | [Basic.lean:512](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Data/Array/Basic.lean#L512) | Init | Not portable verified source |
| `panic!` and `assert!` | runtime dynamic assertions/failures | [Specialize.lean:332](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Specialize.lean#L332) | compiler | Typed failure preferred in verified compiler |
| `for ... in #[]` array workflows | mutable/readable collection traversal | [ToLCNF.lean:120](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/ToLCNF.lean#L120) | compiler | Fast library contract and finiteness |