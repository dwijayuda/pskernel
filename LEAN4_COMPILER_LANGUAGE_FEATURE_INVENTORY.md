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
| ordinary `import` | nonreexported source module imports | [Basic.lean:11](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Data/String/Basic.lean#L11) | Lake | Source graph must be exact |
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
| `axiom` declaration syntax | logical axiom declaration form | [Command.lean:231](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Parser/Command.lean#L231) | parser | Do not infer used by backend runtime; disallowed user axioms in PSCV |
| `protected theorem` | qualified theorem declaration scope | [Prelude.lean:873](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Prelude.lean#L873) | Init | Proof visibility and namespace semantics |
| `builtin_initialize` | module environment/trace initializer | [Specialize.lean:30](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Specialize.lean#L30) | compiler | Metaprogramming/bootstrap side-effect boundary |
| `register_builtin_option` | registered environment configuration option | [BEq.lean:22](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Deriving/BEq.lean#L22) | elaborator | Pin option registry |

## 5. Binders, polymorphism, dependent types and typeclasses

| Lean feature | What actual source uses it for | Pinned code evidence | Component | PSCV portable implication |
|---|---|---|---|---|
| `Sort u` | universe polymorphism and sorts | [Prelude.lean:42](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Prelude.lean#L42) | compiler | Underlying Lean dependent theory |
| `Type u` | universe-polymorphic type argument | [Basic.lean:37](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Data/Array/Basic.lean#L37) | compiler | Keep vs runtime specialization separate |
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
| constructor patterns `\| .ctor ... =>` | tagged pattern and branch binding | [Basic.lean:943](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Basic.lean#L943) | compiler | Typed source constructor identity |
| `if ... then ... else` | dependent/nondependent conditions | [CompilerM.lean:76](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/CompilerM.lean#L76) | compiler | No JavaScript truthiness |
| `if let some x := ...` | pattern guard conditional | [Basic.lean:816](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Basic.lean#L816) | compiler | Desugaring must preserve branches |
| `let x := ...` | pure local let binding | [CompilerM.lean:52](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/CompilerM.lean#L52) | compiler | Essential |
| pattern let `let ⟨x, y⟩ := ...` | pair constructor destructuring | [PassManager.lean:147](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/PassManager.lean#L147) | compiler | Source tuple semantics explicit |
| partial-pattern let `let .code := ... \| panic!` | pattern-match with failure continuation | [Specialize.lean:332](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Specialize.lean#L332) | compiler | Avoid unchecked panic in verified code |
| record update `{ s with field := value }` | typed functional update | [CompilerM.lean:55](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/CompilerM.lean#L55) | compiler | Essential immutable state abstraction |
| anonymous constructor `⟨a,b⟩` | type-directed tuple/structure construction | [PassManager.lean:147](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/PassManager.lean#L147) | compiler | No dynamic structural typing |
| leading-dot constructors `.some/.return/.code` | expected-type constructor inference | [Basic.lean:943](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Basic.lean#L943) | compiler | Exact constructor inference |
| `Option` patterning | optional values/nonexistence | [CompilerM.lean:76](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/CompilerM.lean#L76) | compiler | Typed absence, not JS undefined |
| `Except` matching and errors | typed success/failure branches | [Except.lean:121](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Control/Except.lean#L121) | Init | No host throw interpreted as logical Except |
| `\|>` pipelines | functional postfixed application composition | [Specialize.lean:45](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Specialize.lean#L45) | elaborator | Unfold to ordinary typed applications |
| `<\|` reverse application | readable nested function applications | [EmitC.lean:158](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/EmitC.lean#L158) | compiler | Pure syntax sugar |
| `←` monadic bind | read effect result in do | [VCGen.lean:40](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Tactic/Do/VCGen.lean#L40) | tactic | Exact monad and WP |
| `match-syntax` quotations | pattern matching on syntax trees | [Macro.lean:19](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Macro.lean#L19) | elaborator | Metaprogramming/host-only in PSCV |
| `try ... catch` | typed effectful exception handling | [EmitLLVM.lean:1254](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/IR/EmitLLVM.lean#L1254) | compiler | Model effect and exit behavior |
| `finally` | finalizer in structured exception scope | [TryCatch.lean:46](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/BuiltinDo/TryCatch.lean#L46) | elaborator | Host/effect boundary unless verified |
| `s! string interpolation` | interpolated strings | [EmitC.lean:235](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/EmitC.lean#L235) | compiler | Exact Unicode/formatting if admitted |
| `m! message interpolation` | diagnostic message syntax | [SynthInstance.lean:263](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Meta/SynthInstance.lean#L263) | meta | Host tooling not guaranteed source core |

## 7. Iteration, local mutation, effects, and proof-friendly recursion

| Lean feature | What actual source uses it for | Pinned code evidence | Component | PSCV portable implication |
|---|---|---|---|---|
| `do` monadic sequencing | sequencing with typed monads | [PassManager.lean:130](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/PassManager.lean#L130) | compiler | F0 portable when WP registered |
| `let mut` | locally scoped mutable accumulator | [PassManager.lean:141](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/PassManager.lean#L141) | compiler | SHP2 high-priority feature |
| `for x in values do` | finite collection iteration | [PassManager.lean:131](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/PassManager.lean#L131) | compiler | Registered finite iterator and invariant |
| `for h : i in range` | dependent/proof-carrying index iteration | [EmitC.lean:197](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/EmitC.lean#L197) | compiler | Index/array proof semantics |
| `while true do` | imperative repeated effectful loop | [EmitC.lean:404](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/EmitC.lean#L404) | compiler | Full PSCV verified while; optional source subset |
| `break` | loop control exit | [VCGen.lean:372](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Tactic/Do/VCGen.lean#L372) | elaborator | Verify invariant on exit |
| `continue` | loop next iteration | [VCGen.lean:376](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Tactic/Do/VCGen.lean#L376) | elaborator | Verify decreasing/progress |
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
| `for ... in #[]` array workflows | mutable/readable collection traversal | [EmitC.lean:197](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/EmitC.lean#L197) | compiler | Fast library contract and finiteness |

## 8. Syntax extensions, parser definitions, quotations and elaborator APIs

| Confirmed family | Codebase use | Pinned evidence | Layer | PSCV self-host relevance |
|---|---|---|---|---|
| `syntax` parser declaration | Defines array-literal syntax | [Basic.lean:29](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Data/Array/Basic.lean#L29) | Init | Host syntax, not automatic PSCV source |
| `scoped syntax` | Scoped DSL source extension | [Syntax.lean:25](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/lake/Lake/DSL/Syntax.lean#L25) | Lake | Pin source grammar and scope |
| `macro_rules` | Pattern-based macro expansion | [Basic.lean:31](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Data/Array/Basic.lean#L31) | Init | Allowed only if profiled and bounded |
| `scoped macro` | Defines a tactic syntax macro | [Basic.lean:63](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Basic.lean#L63) | compiler | Proof-producing extension, not kernel authority |
| `@[builtin_macro]` | Registers a builtin for-loop syntax transformer | [For.lean:24](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/BuiltinDo/For.lean#L24) | elaborator | Use as audited lowering mechanism |
| `@[builtin_command_elab]` | Registers command elaborator | [Macro.lean:18](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Macro.lean#L18) | elaborator | Host environment authority |
| `@[builtin_tactic]` | Registers VC generation tactic | [VCGen.lean:455](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Tactic/Do/VCGen.lean#L455) | tactic | Untrusted proof-producing tooling |
| `@[builtin_term_parser]` | Defines term syntax parser | [Command.lean:20](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Parser/Command.lean#L20) | parser | Closed grammar source |
| `syntax quotation ` | Parses quoted expression as syntax data | [Quotation.lean:32](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Quotation.lean#L32) | elaborator | Syntax data, not checked Core |
| ``(category|...)` quote | Category-annotated quoted syntax | [For.lean:26](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/BuiltinDo/For.lean#L26) | elaborator | Dependent on profile grammar |
| `$x` antiquotation | Splices syntax metavariable | [Macro.lean:19](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Macro.lean#L19) | elaborator | Preserve hygiene |
| `$xs*` splice | Splices variable-length syntax list | [Macro.lean:19](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Macro.lean#L19) | elaborator | Metaprogramming/host-only by default |
| `withFreshMacroScope` | Fresh hygienic macro scope | [Quotation.lean:31](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Quotation.lean#L31) | elaborator | Name/source identity matters |
| `match` over `Syntax` | Pattern matching on concrete syntax trees | [Macro.lean:19](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Macro.lean#L19) | elaborator | Source-level elaboration is untrusted |
| `TSyntax` typed syntax | A syntax tree with category type | [VCGen.lean:359](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Tactic/Do/VCGen.lean#L359) | tactic | Proof/host-only representation |
| `Quote` instance | Quotation typeclass implementation | [Quotation.lean:120](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Quotation.lean#L120) | elaborator | Meta feature not core runtime |
| `TermElabM` | Term elaboration monad | [Quotation.lean:27](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Quotation.lean#L27) | elaborator | Kernel independently checks final Expr |
| `MetaM` | Metavariable and proof engine monad | [VCGen.lean:40](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Tactic/Do/VCGen.lean#L40) | tactic | Not logical TCB itself |
| `register_builtin_option` | Compiler-scope elaborator option | [BEq.lean:22](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Deriving/BEq.lean#L22) | elaborator | Pin option meaning |
| `@[builtin_doElem_elab]` | Registers do-return elaborator | [Jump.lean:19](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/BuiltinDo/Jump.lean#L19) | elaborator | Structured exit semantics |
| ``(doCatch| ...)` | Quotation of typed catch syntax | [TryCatch.lean:22](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/BuiltinDo/TryCatch.lean#L22) | elaborator | Exceptional exit modeling |
| generated declaration syntax | Deriving BEq synthesizes functions | [BEq.lean:196](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Deriving/BEq.lean#L196) | elaborator | Generation must preserve proof dependencies |

## 9. Theorem proofs and verification tooling used by Lean libraries and compiler

| Confirmed family | Codebase use | Pinned evidence | Layer | PSCV self-host relevance |
|---|---|---|---|---|
| `theorem ... := by` | Proof constructed with tactics | [PassManager.lean:44](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/PassManager.lean#L44) | compiler | Kernel verifies accepted term |
| `@[simp]` theorem | Registered simplifier rewrite | [PassManager.lean:44](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/PassManager.lean#L44) | compiler | Versioned simp registry |
| `@[grind =]` theorem | Grind lemma annotation | [Basic.lean:43](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Data/Array/Basic.lean#L43) | Init | Tactic database is proof producer only |
| `rfl` | Definitional reflexivity proof | [Basic.lean:63](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Basic.lean#L63) | compiler | Kernel check |
| `rw [...]` | Rewriting by equality theorem | [Basic.lean:65](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Data/String/Basic.lean#L65) | Init | Approved lemma dependency |
| `simp_all` | Contextual simplification | [Basic.lean:678](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Data/String/Basic.lean#L678) | Init | Pinned simp semantics |
| `omega` | Arithmetic proof tactic | [Basic.lean:86](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Data/String/Basic.lean#L86) | Init | Proof is term-checked |
| `induction ... with` | Induction proof over an inductive | [Basic.lean:58](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Data/Array/Basic.lean#L58) | Init | Structural proof guidance |
| `fun_induction` | Induction over recursive function equation | [Basic.lean:111](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Data/String/Basic.lean#L111) | Init | Terminating computation theorem |
| `cases ... with` | Case split on constructors | [Basic.lean:60](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Data/Array/Basic.lean#L60) | Init | Exhaustive proof branches |
| `rcases` | Pattern-directed case analysis | [Basic.lean:51](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Data/String/Basic.lean#L51) | Init | Tactic proof source |
| `exact` | Provide goal proof term | [Basic.lean:67](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Data/String/Basic.lean#L67) | Init | Exact theorem type |
| `decide` | Decision procedure for decidable facts | [Basic.lean:610](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Data/Array/Basic.lean#L610) | Init | Not unchecked native proof |
| `have` | Local typed proof hypothesis | [EmitC.lean:421](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/EmitC.lean#L421) | compiler | Explicit bound justification |
| `termination_by` | Well-founded termination measure | [Specialize.lean:279](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Specialize.lean#L279) | compiler | Prove every decrease |
| `decreasing_by` | Termination proof tactic | [Basic.lean:86](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Data/String/Basic.lean#L86) | Init | Kernel accepted |
| `@[spec] theorem` | Generated contract theorem | [Contract.lean:148](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Tactic/Do/Contract.lean#L148) | verification | Approved spec and proof identity |
| `vcgen` | Generates verification conditions | [Contract.lean:149](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Tactic/Do/Contract.lean#L149) | verification | Proof producer not proof authority |
| `class WP` | Weakest-precondition abstraction | [Basic.lean:62](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Std/WP/Basic.lean#L62) | Std | Registered effect semantics |
| `@[simp, grind =]` WP lemma | Tactic automation for WP law | [Basic.lean:80](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Std/WP/Basic.lean#L80) | Std | Replay proof in kernel |
| `partial def genVCs` | Implementation of VC generator | [VCGen.lean:40](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Tactic/Do/VCGen.lean#L40) | verification | Partial tactic not closed executable source |
| `trace[Elab.Tactic.Do.vcgen]` | Verification tracing | [VCGen.lean:126](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Tactic/Do/VCGen.lean#L126) | verification | Not proof evidence |

## 10. Compiler attributes, runtime primitives, FFI and codegen hints

| Confirmed family | Codebase use | Pinned evidence | Layer | PSCV self-host relevance |
|---|---|---|---|---|
| `@[inline]` | Compiler inline attribute | [Basic.lean:55](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Basic.lean#L55) | compiler | Optimization does not define semantics |
| `@[always_inline]` | Strong inline attribute | [CompilerM.lean:51](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/CompilerM.lean#L51) | compiler | Not a proof |
| `@[expose]` | Expose selected declaration | [PassManager.lean:17](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/PassManager.lean#L17) | compiler | Transparency matters to elaboration |
| `@[implicit_reducible]` | Reduction/transparency attribute | [State.lean:25](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Control/State.lean#L25) | Init | Profile reduction must be pinned |
| `@[extern "..."]` | Bind compiled symbol to native runtime | [Basic.lean:165](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Data/Array/Basic.lean#L165) | Init | Runtime TCB/ABI boundary |
| `@[export ...]` | Export compiled C symbol | [ExportAttr.lean:30](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/ExportAttr.lean#L30) | compiler | ABI visibility independent of Core proof |
| `@[implemented_by]` | Link opaque declaration to unsafe/native body | [PassManager.lean:219](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/PassManager.lean#L219) | compiler | Logical/runtime correspondence needed |
| `@[builtin_macro]` | Macro elaboration registration | [Contract.lean:90](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Tactic/Do/Contract.lean#L90) | elaborator | Untrusted code generator |
| `@[builtin_command_elab]` | Command elaborator registration | [Contract.lean:158](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Tactic/Do/Contract.lean#L158) | elaborator | Untrusted proof producer |
| `@[builtin_tactic]` | Tactic elaborator registration | [VCGen.lean:455](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Tactic/Do/VCGen.lean#L455) | verification | Kernel checks result |
| `@[builtin_term_parser]` | Custom built-in parser attribute | [Command.lean:20](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Parser/Command.lean#L20) | parser | No automatic PSCV grammar inclusion |
| `@[inherit_doc]` | Reuses generated documentation | [Syntax.lean:63](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/lake/Lake/DSL/Syntax.lean#L63) | Lake | Doc tooling, nonlogical |
| `register_builtin_option` | Compile-time option namespace | [BEq.lean:22](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Deriving/BEq.lean#L22) | elaborator | Environment identity |
| `builtin_initialize` | Registers persistent compiler extension | [Specialize.lean:30](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Specialize.lean#L30) | compiler | Environment mutation/trust |
| `set_option` | Controls compiler/linter options | [Basic.lean:21](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Data/Array/Basic.lean#L21) | Init | Pinned build configuration |
| `trace[Compiler...]` | Compiler debug tracing | [Specialize.lean:406](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Specialize.lean#L406) | compiler | Diagnostics not semantic proof |
| `s!"..."` | String interpolation | [EmitC.lean:235](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/EmitC.lean#L235) | compiler | Encoding/output determinism |
| `m!"..."` | Structured diagnostics | [SynthInstance.lean:263](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Meta/SynthInstance.lean#L263) | meta | Host diagnostics |
| `panic!` | Unreachable branch runtime assertion | [Specialize.lean:332](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Specialize.lean#L332) | compiler | Replace with typed failure or proof in PSCV |
| `opaque` runtime fast path | Opaque declaration + implementation binding | [Basic.lean:125](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Basic.lean#L125) | compiler | Assumption must be inventoried |
| `noinline` optimization kind | One entry in Lean inline attribute kind enum | [InlineAttrs.lean:18](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/InlineAttrs.lean#L18) | compiler | Compiler feature, not necessarily used as source attribute |

## 11. Standard library, effects, IO and tooling code written in Lean

| Confirmed family | Codebase use | Pinned evidence | Layer | PSCV self-host relevance |
|---|---|---|---|---|
| `ReaderT` | Readonly contextual computation | [CompilerM.lean:49](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/CompilerM.lean#L49) | compiler | Reader effect model |
| `StateRefT` | Compiler mutable reference state | [CompilerM.lean:49](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/CompilerM.lean#L49) | compiler | Physical ref effects need abstraction |
| `StateT` | Logical state transformer | [State.lean:25](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Control/State.lean#L25) | Init | Typed state transition |
| `ExceptT` | Typed exception transformer | [Except.lean:131](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Control/Except.lean#L131) | Init | State/exceptions order matters |
| `OptionT` | Optional typed monad transformer | [VCGen.lean:60](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Tactic/Do/VCGen.lean#L60) | verification | Failure not proof success |
| `Monad` instance | Bind/pure implementation | [CompilerM.lean:52](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/CompilerM.lean#L52) | compiler | Typeclass laws and selection |
| `MonadScope` | Scoped specialized computation | [Specialize.lean:90](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Specialize.lean#L90) | compiler | Effect and environment closure |
| `ForM.forIn` | Iteration typeclass implementation | [State.lean:174](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Control/State.lean#L174) | Init | Finite iterator proof |
| `StateT ... BaseIO` | Server snapshot state evolution | [FileWorker.lean:250](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Server/FileWorker.lean#L250) | server | Nonlogical runtime effects |
| `IO` | Filesystem/process/runtime effect monad | [FileWorker.lean:365](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Server/FileWorker.lean#L365) | server | Boundary outside closed compiler |
| `BaseIO` | Lower-level runtime tasks | [FileWorker.lean:124](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Server/FileWorker.lean#L124) | server | Host TCB |
| `IO.Ref` | Shared mutable IO reference | [FileWorker.lean:90](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Server/FileWorker.lean#L90) | server | Not portable source alias |
| `ServerTask` | Asynchronous server response | [FileWorker.lean:124](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Server/FileWorker.lean#L124) | server | Concurrency outside portable core |
| `IO.FS.readFile` | Reads files during Lake build | [Syntax.lean:83](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/lake/Lake/DSL/Syntax.lean#L83) | Lake | Explicit host IO |
| `IO.FS` with `FilePath` | Package filesystem operation | [Package.lean:432](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/lake/Lake/Config/Package.lean#L432) | Lake | Platform trust assumption |
| Lake DSL `scoped syntax` | Package/config language defined in Lean | [Syntax.lean:25](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/lake/Lake/DSL/Syntax.lean#L25) | Lake | Separate from PSCV grammar |
| Lake command elaborator | Elaborates build DSL command | [Package.lean:21](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/lake/Lake/DSL/Package.lean#L21) | Lake | Custom host command handling |
| `IO.println` | Observable program IO | [Basic.lean:531](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Data/Array/Basic.lean#L531) | Init | Not kernel proof |
| `ByteArray` | Raw byte buffer and UTF-8 representation | [Basic.lean:65](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Data/String/Basic.lean#L65) | Init | Portable bytes not host String indices |
| `HashMap`/maps | Efficient lookup and memoization | [Specialize.lean:75](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Specialize.lean#L75) | compiler | Deterministic output ordering needed |
| `String` and UTF-8 | Unicode and bytesize proofs | [Basic.lean:41](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Data/String/Basic.lean#L41) | Init | Byte-offset correctness |
| `Array` literal and indexing | Arrays including proof-bearing bounds | [Basic.lean:29](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Data/Array/Basic.lean#L29) | Init | Cross-backend array model |
| `Name` | Hierarchical declaration identity | [PassManager.lean:141](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/PassManager.lean#L141) | compiler | Semantic namespace identity |
| `Expr` | Lean Core expression datatype | [CompilerM.lean:193](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/CompilerM.lean#L193) | compiler | Not the executable RuntimeIR |
| `Syntax/TSyntax` | Concrete parsed source AST | [Quotation.lean:27](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Quotation.lean#L27) | elaborator | Need explicit source fidelity relation |


## 13. Case studies: how Lean writes its actual compiler

This section ties syntax to real architectural responsibilities instead of merely enumerating tokens.

### 13.1 Typed compiler monads and Reader/State layers

[`src/Lean/Compiler/LCNF/CompilerM.lean` L49–55](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/CompilerM.lean#L49-L55) declares a compiler monad as a composition of a read-only context, mutable compilation state and Lean's `CoreM`. It then defines `Monad CompilerM` and helper operations such as `withReader`. This is *ordinary Lean programming* with higher-kinded type constructors, typeclasses, generic functions, records, lambdas, and effects—not merely theorem-proving syntax.

The design lesson for PSCV is to use **registered Reader/State/typed-error effects**, with explicit source semantics and WP theorems, instead of forcing every pass to take and return a manually bundled giant state record. It does not justify arbitrary mutable heap aliasing.

### 13.2 Simple loops and accumulator mutation in passes

[`PassManager.lean` L130–148](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/PassManager.lean#L130-L148) illustrates a conventional compiler algorithm: iterate through an array of pass descriptors, validate invariants, accumulate the first/last occurrence of a chosen pass, then destructure a pair of options or fail with a typed error. It uses `for`, `let mut`, conditional expressions, `Option`, pair patterns, `do` and `throwError`.

This pattern is substantially clearer than an ad hoc multi-argument fuel worker for ordinary finite traversals. For a verified portable compiler, each local mutation can be translated to a state/SSA relation while iterator finiteness, index bounds and early-exit postconditions are discharged with reusable library lemmas.

### 13.3 Dependent-index loops, C output and runtime assumptions

[`EmitC.lean` L197–200](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/EmitC.lean#L197-L200) uses an indexed for-loop with a proof-bearing loop variable; [`EmitC.lean` L403–410](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/EmitC.lean#L403-L410) uses a mutable local and `while true` to chase references; [`EmitC.lean` L973–978](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/EmitC.lean#L973-L978) handles code-generation errors.

That code shows the distinction between what Lean's compiler **uses** and what PSCV's verified implementation profile should **admit**. Lean can write an unbounded `while` because it is an ordinary compiler implementation. PSCV's closed verified program must prove a measure/invariant (or use a registered total traversal), and target emission must preserve the error and output-byte behavior.

### 13.4 Termination strategies are mixed, not uniformly total

[`InferType.lean` L120–148](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/InferType.lean#L120-L148) contains mutually recursive partial type-inference helpers. [`Specialize.lean` L273–280](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Specialize.lean#L273-L280), by contrast, uses an explicit `termination_by` measure for a local recursive traversal. [`Init/Data/String/Basic.lean` L73–86](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Data/String/Basic.lean#L73-L86) uses `termination_by` with `decreasing_by ... omega` for UTF-8 processing.

Thus **partial recursion and verified well-founded recursion coexist within the same upstream codebase**. The important question for a future PSCV compiler source is which algorithm families can be made total through standard iterators, worklists and explicit termination measures without destabilizing runtime behavior and proof size.

### 13.5 Phased IR and indexed types

[`LCNF/Basic.lean` L37–55](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Basic.lean#L37-L55) defines a `Purity` datatype and instances. Throughout LCNF, terms and declarations are indexed by their purity/phase, and operations distinguish pure and impure IR shapes. [`IR/Basic.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/IR/Basic.lean) defines another purpose-specific compiler representation.

This supports the principle already present in PSCV V5.1: only create a new IR where there is a real semantic or representation boundary, but use types to prevent phases from being accidentally mixed. A type-indexed implementation is not sufficient evidence of runtime semantic preservation.

### 13.6 Meta syntax, macros, quotation and the actual parser

[`Parser/Command.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Parser/Command.lean) defines grammar/parser combinators and declaration modifiers. [`Elab/Macro.lean` L18–40](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Macro.lean#L18-L40) shows a command elaborator generating syntax declarations/`macro_rules`. [`Elab/BuiltinDo/For.lean` L24–35](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/BuiltinDo/For.lean#L24-L35) performs a macro expansion on typed `doFor` syntax quotations. [`Elab/Quotation.lean` L27–33](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Quotation.lean#L27-L33) manipulates syntax with hygienic macro scopes.

**This is a powerful but high-trust-clarity feature family.** Lean 4 makes its compiler frontend extensible in Lean itself. For PSCV, the practical bootstrap approach is to reuse pinned Lean syntax/elaboration as *an untrusted development producer*, while the portable source grammar remains closed and the checked Core and imported-axiom effects remain explicit. ProofScript should not accidentally inherit every parser extension loaded into Lean's environment.

### 13.7 Intrinsic contracts and VC generation in Lean 4.35

The pinned [`Elab/Tactic/Do/Contract.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Tactic/Do/Contract.lean) contains implementation of experimental intrinsic `given`/`requires`/`ensures` contract syntax, generating a `spec` theorem proved through `vcgen`. The pinned [`VCGen.lean` L40–65](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Tactic/Do/VCGen.lean#L40-L65) uses a partially recursive metaprogram and mutable state to generate proof goals. [`Std/WP/Basic.lean` L62–81](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Std/WP/Basic.lean#L62-L81) defines the underlying weakest-precondition typeclass and theorems.

This is a direct research connection for PSCV verification. It is **not evidence** that all PSCV-owned source contracts, effects, ghost/erasure and release `PSCV-CERT` semantics have already been implemented by the experimental Lean frontend or by the production PSCV compiler.

### 13.8 Foundational collections and native runtime

[`Init/Data/Array/Basic.lean` L29–31](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Data/Array/Basic.lean#L29-L31) even defines array-literal syntax using `syntax` and `macro_rules`, showing that some "built-in-looking" language conveniences are actually **library-provided syntax**. The same file includes an [`@[extern]` native array operation](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Data/Array/Basic.lean#L165) and an [unsafe optimized operation](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init/Data/Array/Basic.lean#L512).

Therefore the compiler's apparent safe `Array` API may rely on separately trusted runtime primitives. PSCV can use analogous performance-oriented backend adapters only with precise representation, bounds, mutability and target-runtime correspondence evidence.

### 13.9 Build DSL, IDE and effects outside the semantic compiler

[`Lake/DSL/Syntax.lean` L25](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/lake/Lake/DSL/Syntax.lean#L25) uses scoped syntax for the build system, [`Lake/DSL/Package.lean` L21](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/lake/Lake/DSL/Package.lean#L21) implements command elaboration, and [`Lean/Server/FileWorker.lean` L365](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Server/FileWorker.lean#L365) uses `ReaderT ... (StateRefT ... IO)` to manage editor workloads. These features are vital to *the overall Lean toolchain*, but not necessarily a good fit for a four-backend **verified compiler semantic core**.

## 14. Research already present in pskernel/study

| Research folder | What exists in the repository | Correct use and version caveat |
|---|---|---|
| [`study/lean4-4.34.0`](https://github.com/dwijayuda/pskernel/tree/main/study/lean4-4.34.0) | Full Lean 4.34 source layout, `src/Lean/Compiler`, `Elab`, `Meta`, C++ kernel/runtime, docs, tests, stage0 | Use for local 4.34 behavior and origin comparison; current PSCV pin is 4.35-rc3 |
| [`study/lean4-4.34.0/doc/dev/bootstrap.md`](https://github.com/dwijayuda/pskernel/blob/main/study/lean4-4.34.0/doc/dev/bootstrap.md) | Upstream bootstrapping explanation with stage0 C and stage1–stage3 self-compilation | Confirms stages, not source/target compiler correctness proof |
| [`study/lean4-language-reference`](https://github.com/dwijayuda/pskernel/tree/main/study/lean4-language-reference) | Mirrored rendered Lean language reference; Syntax, Definitions, Types, Tactics, IO, Macros, Imports | Useful for all supported grammar families, **not** an exact Lean4.35 source pin |
| [`study/functional_programming_in_lean`](https://github.com/dwijayuda/pskernel/tree/main/study/functional_programming_in_lean) | Tutorial/book including monads, transforms, dependent types and performance | Explanatory pedagogy, not kernel specification |
| [`study/theorem_proving_in_lean4`](https://github.com/dwijayuda/pskernel/tree/main/study/theorem_proving_in_lean4) | Theorem/proof programming and tactics | Proof-source examples, not proof of PSCV compilation |
| [`study/lean4lean-master`](https://github.com/dwijayuda/pskernel/tree/main/study/lean4lean-master) | Separate Lean-for-Lean implementation of Lean kernel, written mostly in Lean | Alternative checker research; not the official upstream C++ kernel or independent PSKernel |
| [`study/HTPIwL`](https://github.com/dwijayuda/pskernel/tree/main/study/HTPIwL) | Logic and proof-engineering background | Conceptual foundations only |

**Direct file-level cross-check:** the local 4.34 [`CompilerM.lean`](https://github.com/dwijayuda/pskernel/blob/main/study/lean4-4.34.0/src/Lean/Compiler/LCNF/CompilerM.lean#L49) has the `ReaderT ... StateRefT ... CoreM` construction; local [`PassManager.lean`](https://github.com/dwijayuda/pskernel/blob/main/study/lean4-4.34.0/src/Lean/Compiler/LCNF/PassManager.lean#L130-L148) uses finite `for` and `let mut`; local [`Elab/Tactic/Do/Contract.lean`](https://github.com/dwijayuda/pskernel/blob/main/study/lean4-4.34.0/src/Lean/Elab/Tactic/Do/Contract.lean) already contains intrinsic contract infrastructure. The 4.35-rc3 version has additional code; features and behavior must be checked at the correct pin rather than inferred by similar filenames.

## 15. Two different questions: language usage versus verified portability

The feature inventory includes **three fundamentally different categories**:

1. **Actual Lean language constructs:** grammar-level source forms such as `inductive`, `structure`, `def`, `partial def`, `by`, `match`, `do`, `fun`, `let mut`, `for`, `namespace`, `syntax`, `macro_rules`.
2. **Library-provided syntax and APIs:** `Array`, `StateT`, `ReaderT`, `ExceptT`, `ForIn`, `HashMap`, `String`, indexed operations and `WP`. These are essential to how the code works, but they are not each a new kernel language construct.
3. **Compiler/runtime/host mechanisms:** `@[extern]`, `@[implemented_by]`, `builtin_initialize`, `IO`/`Task`, Lake DSL, generated C, LLVM backend and C++ kernel. These are real features and boundaries, but they do not prove a self-hosted implementation is total or portable across other runtimes.

Failing to distinguish the categories can make PSCV's desired self-host source language either too primitive (because useful library abstractions are rejected) or too broad (because host-only Lean metadata/FFI is mistaken for portable executable semantics).

## 16. PSCV self-host-portable feature selection from Lean evidence

The following is **advice inferred from the inventory**, not a change to the canonical [SHP2 language reference](https://github.com/dwijayuda/pskernel/blob/main/PSCV_SELFHOST_PORTABLE_LANGUAGE_REFERENCE.md). The approved ProofScript/PSCV language semantics remain authority.

| Lean feature family used in source | Suggested PSCV implementation profile | Benefit | Proof/portability obstacle |
|---|---|---|---|
| `def`, `structure`, `inductive`, `match` | **Core required** | Type-safe AST/IR and structural induction | Type and recursor/erasure mapping |
| Generics, implicit arguments, classes/instances | **Closed registered subset** | Reusable compiler abstraction | Instance/coercion search determinism |
| `fun` and higher-order immutable operations | **Core required** | Visitors, folds, functional passes | Closure conversion, specialization |
| `do` / monadic bind | **Required, limited effects** | Readable compiler states and errors | Exact WP and state/error ordering |
| `let mut` (local only) | **Required** | Efficient and readable accumulators | SSA/state lowering and local proof VCs |
| Finite `for` | **Required, certified iterator** | Less recursive boilerplate | Iterator termination and break/continue invariant |
| `while` | **Deferred in self-host source** | Convenient for worklists | Invariant/decreasing obligations; full PSCV still supports |
| `termination_by`/`decreasing_by` | **Required** | Total algorithms beyond syntactic subterm | Proof cost and runtime recursion strategy |
| `mutual` recursion | **Required when proven total** | Syntax/elaboration and inference | Joint well-founded measure |
| `Option`, `Except`, `ReaderT`, `StateT` | **Registered effects/library** | Error and context handling | State+error composition/rollback |
| `Array`, `ByteArray`, `String`, `HashMap` | **Registered abstract value library** | Runtime efficiency | UTF-8, bounds, deterministic maps, exact integers |
| `theorem`, `by`, `simp`, `omega`, `grind` | **Proof-only/profile-pinned** | AI assistance in metatheory | Kernel-replayed terms and exact theorem imports |
| `macro`, `syntax`, `elab`, quotation | **Lean host/tooling only initially** | Extensible development tools | Frozen grammar/source fidelity, runtime portability |
| `partial`, `unsafe`, runtime `opaque` escape | **Exclude from verified closed executable source** | Lean performance convenience | Totality, trust and runtime meaning |
| `@[extern]`, `@[implemented_by]`, FFI | **Explicit audited runtime boundary** | Native fast paths and host integration | Target-by-target semantic preservation |
| `IO`, server tasks, Lake DSL | **Host/tooling boundary** | Real compiler CLI, build and IDE support | External effects and platform assumptions |

**Do not copy Lean's codebase unchanged as PSCV source** and assume full self-hosting. Lean 4.35 uses source features outside the current `PSC1-selfhost-stable/1` parser/elaborator/backend closure, including `partial`/`unsafe`/macros/managed runtime state; this inventory supplies the evidence to identify and prioritize capability-family work.

## 17. What "all language features" means here, and what remains unverified

**High confidence in the listed feature families:** a pinned source-file link and nearby code confirm each positive usage or implementation. **High confidence in the audited compiler file count:** the 117-file tree and retrieval covered all compiler `.lean` files. **Lower confidence in raw keyword frequency:** the one-pass lexical heuristic is not a Lean parser, so comments, documentation and generated syntax quotations can appear as false positives or undercounts. **Explicitly not claimed:** 100% classification of all individual constructs in all 2,536 `.lean` files, or a complete static feature support database generated by building the pinned compiler.

The report should not be read as saying all Lean syntax is used by LCNF. For example, tactic syntax is implemented/used in `Elab`/`Init`/`Std`, while LCNF mostly uses ordinary typed functions, ADTs, mutable local code and compiler monads. Similarly, `axiom` and `noncomputable` are parsed language declarations but this research did not establish pervasive use of such declarations in the compiler backend. Features such as `nonrec`, `meta def`, `partial_fixpoint`, all user notation spellings, exotic tactic extensions and `run_tac` may be supported by Lean but require a separate **actual-source occurrence check** before adding them to a positive usage census.

**Open follow-up for a strictly exhaustive inventory:** run a pinned Lean 4.35 frontend/AST classifier over every target file and emit a machine-generated, line-indexed feature-use manifest. Its report must distinguish lexical source syntax, macro quotations, code strings, comments, expansion-generated constructs, imported-library dependencies, and runtime extensions; compare with this human-reviewed feature-family inventory. No such executable classifier or compile/test run was performed in the present research.

## 18. Primary source links and technical reading order

- [Lean 4.35.0-rc3 compiler](https://github.com/leanprover/lean4/tree/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler)
- [Lean 4.35 parser](https://github.com/leanprover/lean4/tree/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Parser)
- [Lean 4.35 elaborator](https://github.com/leanprover/lean4/tree/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab)
- [Lean 4.35 Meta](https://github.com/leanprover/lean4/tree/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Meta)
- [Lean 4.35 Init](https://github.com/leanprover/lean4/tree/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Init)
- [Lean 4.35 Std/WP](https://github.com/leanprover/lean4/tree/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Std/WP)
- [Lean 4.35 Lake](https://github.com/leanprover/lean4/tree/470d5ce1400764999581fd26d5d72b00d990b0f4/src/lake/Lake)
- [Lean 4.35 native C++ kernel](https://github.com/leanprover/lean4/tree/470d5ce1400764999581fd26d5d72b00d990b0f4/src/kernel)
- [Lean 4.35 runtime](https://github.com/leanprover/lean4/tree/470d5ce1400764999581fd26d5d72b00d990b0f4/src/runtime)
- [Pinned Lean 4.34 bootstrap explanation stored in pskernel](https://github.com/dwijayuda/pskernel/blob/main/study/lean4-4.34.0/doc/dev/bootstrap.md)
- [Lean Language Reference — declarations](https://lean-lang.org/doc/reference/latest/Definitions/)
- [Lean Language Reference — dependent types](https://lean-lang.org/doc/reference/latest/The-Type-System/)
- [Lean Language Reference — monads and do](https://lean-lang.org/doc/reference/latest/Functors___-Monads-and--do--Notation/Syntax/)
- [Lean Language Reference — macros and quotation](https://lean-lang.org/doc/reference/latest/Notations-and-Macros/Macros/)
- [Lean Language Reference — recursive definitions](https://lean-lang.org/doc/reference/latest/Definitions/Recursive-Definitions/)
- [Lean Language Reference — elaborators](https://lean-lang.org/doc/reference/latest/Notations-and-Macros/Elaborators/)
- [Lean Language Reference — tactics and proofs](https://lean-lang.org/doc/reference/latest/Tactic-Proofs/)
- [SHP2 long-term self-host portable language proposal](https://github.com/dwijayuda/pskernel/blob/main/PSCV_SELFHOST_PORTABLE_LANGUAGE_REFERENCE.md)

---

**Research status:** source-grounded inventory finished to feature-family level. The current document is a research/reference artifact only; no compiler/kernel implementation, language grammar, self-host acceptance or proof assurance was modified or certified by creating it.


## 19. Complete audited compiler-source file list (117/117)

Below is the **entire** pinned `src/Lean/Compiler` `.lean` directory tree visited in the lexical source scan. The table enumerates actual `.lean` files, not all imported library sources. Being listed means the file was retrieved for the approximate feature scan; it does not imply every quoted term/attribute within it was individually parsed and checked by a Lean AST classifier.

| # | Compiler subarea | Pinned Lean source file |
|---:|---|---|
| 1 | Compiler frontend/attributes | [`BorrowedAnnotation.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/BorrowedAnnotation.lean) |
| 2 | Compiler frontend/attributes | [`CSimpAttr.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/CSimpAttr.lean) |
| 3 | Compiler frontend/attributes | [`ClosedTermCache.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/ClosedTermCache.lean) |
| 4 | Compiler frontend/attributes | [`ExportAttr.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/ExportAttr.lean) |
| 5 | Compiler frontend/attributes | [`ExternAttr.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/ExternAttr.lean) |
| 6 | Compiler frontend/attributes | [`FFI.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/FFI.lean) |
| 7 | Compiler frontend/attributes | [`IR.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/IR.lean) |
| 8 | IR backend | [`IR/Basic.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/IR/Basic.lean) |
| 9 | IR backend | [`IR/Checker.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/IR/Checker.lean) |
| 10 | IR backend | [`IR/CompilerM.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/IR/CompilerM.lean) |
| 11 | IR backend | [`IR/EmitLLVM.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/IR/EmitLLVM.lean) |
| 12 | IR backend | [`IR/EmitUtil.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/IR/EmitUtil.lean) |
| 13 | IR backend | [`IR/Format.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/IR/Format.lean) |
| 14 | IR backend | [`IR/LLVMBindings.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/IR/LLVMBindings.lean) |
| 15 | IR backend | [`IR/Meta.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/IR/Meta.lean) |
| 16 | IR backend | [`IR/NormIds.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/IR/NormIds.lean) |
| 17 | IR backend | [`IR/Sorry.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/IR/Sorry.lean) |
| 18 | IR backend | [`IR/ToIR.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/IR/ToIR.lean) |
| 19 | IR backend | [`IR/ToIRType.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/IR/ToIRType.lean) |
| 20 | IR backend | [`IR/UnboxResult.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/IR/UnboxResult.lean) |
| 21 | Compiler frontend/attributes | [`ImplementedByAttr.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/ImplementedByAttr.lean) |
| 22 | Compiler frontend/attributes | [`InitAttr.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/InitAttr.lean) |
| 23 | Compiler frontend/attributes | [`InlineAttrs.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/InlineAttrs.lean) |
| 24 | Compiler frontend/attributes | [`LCNF.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF.lean) |
| 25 | LCNF backend | [`LCNF/AlphaEqv.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/AlphaEqv.lean) |
| 26 | LCNF backend | [`LCNF/AuxDeclCache.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/AuxDeclCache.lean) |
| 27 | LCNF backend | [`LCNF/BaseTypes.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/BaseTypes.lean) |
| 28 | LCNF backend | [`LCNF/Basic.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Basic.lean) |
| 29 | LCNF backend | [`LCNF/Bind.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Bind.lean) |
| 30 | LCNF backend | [`LCNF/CSE.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/CSE.lean) |
| 31 | LCNF backend | [`LCNF/Check.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Check.lean) |
| 32 | LCNF backend | [`LCNF/Closure.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Closure.lean) |
| 33 | LCNF backend | [`LCNF/CoalesceRC.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/CoalesceRC.lean) |
| 34 | LCNF backend | [`LCNF/CompatibleTypes.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/CompatibleTypes.lean) |
| 35 | LCNF backend | [`LCNF/CompilerM.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/CompilerM.lean) |
| 36 | LCNF backend | [`LCNF/ConfigOptions.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/ConfigOptions.lean) |
| 37 | LCNF backend | [`LCNF/DeclHash.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/DeclHash.lean) |
| 38 | LCNF backend | [`LCNF/DependsOn.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/DependsOn.lean) |
| 39 | LCNF backend | [`LCNF/ElimDead.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/ElimDead.lean) |
| 40 | LCNF backend | [`LCNF/ElimDeadBranches.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/ElimDeadBranches.lean) |
| 41 | LCNF backend | [`LCNF/EmitC.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/EmitC.lean) |
| 42 | LCNF backend | [`LCNF/EmitUtil.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/EmitUtil.lean) |
| 43 | LCNF backend | [`LCNF/ExpandResetReuse.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/ExpandResetReuse.lean) |
| 44 | LCNF backend | [`LCNF/ExplicitBoxing.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/ExplicitBoxing.lean) |
| 45 | LCNF backend | [`LCNF/ExplicitRC.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/ExplicitRC.lean) |
| 46 | LCNF backend | [`LCNF/ExtractClosed.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/ExtractClosed.lean) |
| 47 | LCNF backend | [`LCNF/FVarUtil.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/FVarUtil.lean) |
| 48 | LCNF backend | [`LCNF/FixedParams.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/FixedParams.lean) |
| 49 | LCNF backend | [`LCNF/FloatLetIn.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/FloatLetIn.lean) |
| 50 | LCNF backend | [`LCNF/InferBorrow.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/InferBorrow.lean) |
| 51 | LCNF backend | [`LCNF/InferType.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/InferType.lean) |
| 52 | LCNF backend | [`LCNF/Internalize.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Internalize.lean) |
| 53 | LCNF backend | [`LCNF/Irrelevant.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Irrelevant.lean) |
| 54 | LCNF backend | [`LCNF/JoinPoints.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/JoinPoints.lean) |
| 55 | LCNF backend | [`LCNF/LCtx.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/LCtx.lean) |
| 56 | LCNF backend | [`LCNF/LambdaLifting.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/LambdaLifting.lean) |
| 57 | LCNF backend | [`LCNF/Level.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Level.lean) |
| 58 | LCNF backend | [`LCNF/LiveVars.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/LiveVars.lean) |
| 59 | LCNF backend | [`LCNF/Main.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Main.lean) |
| 60 | LCNF backend | [`LCNF/MonadScope.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/MonadScope.lean) |
| 61 | LCNF backend | [`LCNF/MonoTypes.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/MonoTypes.lean) |
| 62 | LCNF backend | [`LCNF/OtherDecl.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/OtherDecl.lean) |
| 63 | LCNF backend | [`LCNF/PassManager.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/PassManager.lean) |
| 64 | LCNF backend | [`LCNF/Passes.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Passes.lean) |
| 65 | LCNF backend | [`LCNF/PhaseExt.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/PhaseExt.lean) |
| 66 | LCNF backend | [`LCNF/PrettyPrinter.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/PrettyPrinter.lean) |
| 67 | LCNF backend | [`LCNF/Probing.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Probing.lean) |
| 68 | LCNF backend | [`LCNF/PropagateBorrow.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/PropagateBorrow.lean) |
| 69 | LCNF backend | [`LCNF/PublicDeclsExt.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/PublicDeclsExt.lean) |
| 70 | LCNF backend | [`LCNF/PullFunDecls.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/PullFunDecls.lean) |
| 71 | LCNF backend | [`LCNF/PullLetDecls.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/PullLetDecls.lean) |
| 72 | LCNF backend | [`LCNF/PushProj.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/PushProj.lean) |
| 73 | LCNF backend | [`LCNF/ReduceArity.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/ReduceArity.lean) |
| 74 | LCNF backend | [`LCNF/ReduceJpArity.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/ReduceJpArity.lean) |
| 75 | LCNF backend | [`LCNF/Renaming.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Renaming.lean) |
| 76 | LCNF backend | [`LCNF/ResetReuse.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/ResetReuse.lean) |
| 77 | LCNF backend | [`LCNF/ScopeM.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/ScopeM.lean) |
| 78 | LCNF backend | [`LCNF/Simp.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Simp.lean) |
| 79 | LCNF backend | [`LCNF/Simp/Basic.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Simp/Basic.lean) |
| 80 | LCNF backend | [`LCNF/Simp/Config.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Simp/Config.lean) |
| 81 | LCNF backend | [`LCNF/Simp/ConstantFold.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Simp/ConstantFold.lean) |
| 82 | LCNF backend | [`LCNF/Simp/DefaultAlt.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Simp/DefaultAlt.lean) |
| 83 | LCNF backend | [`LCNF/Simp/DiscrM.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Simp/DiscrM.lean) |
| 84 | LCNF backend | [`LCNF/Simp/FunDeclInfo.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Simp/FunDeclInfo.lean) |
| 85 | LCNF backend | [`LCNF/Simp/InlineCandidate.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Simp/InlineCandidate.lean) |
| 86 | LCNF backend | [`LCNF/Simp/InlineProj.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Simp/InlineProj.lean) |
| 87 | LCNF backend | [`LCNF/Simp/JpCases.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Simp/JpCases.lean) |
| 88 | LCNF backend | [`LCNF/Simp/Main.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Simp/Main.lean) |
| 89 | LCNF backend | [`LCNF/Simp/SimpM.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Simp/SimpM.lean) |
| 90 | LCNF backend | [`LCNF/Simp/SimpValue.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Simp/SimpValue.lean) |
| 91 | LCNF backend | [`LCNF/Simp/Used.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Simp/Used.lean) |
| 92 | LCNF backend | [`LCNF/SimpCase.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/SimpCase.lean) |
| 93 | LCNF backend | [`LCNF/SimpleGroundExpr.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/SimpleGroundExpr.lean) |
| 94 | LCNF backend | [`LCNF/SpecInfo.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/SpecInfo.lean) |
| 95 | LCNF backend | [`LCNF/Specialize.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Specialize.lean) |
| 96 | LCNF backend | [`LCNF/SplitSCC.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/SplitSCC.lean) |
| 97 | LCNF backend | [`LCNF/StructProjCases.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/StructProjCases.lean) |
| 98 | LCNF backend | [`LCNF/ToDecl.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/ToDecl.lean) |
| 99 | LCNF backend | [`LCNF/ToExpr.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/ToExpr.lean) |
| 100 | LCNF backend | [`LCNF/ToImpure.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/ToImpure.lean) |
| 101 | LCNF backend | [`LCNF/ToImpureType.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/ToImpureType.lean) |
| 102 | LCNF backend | [`LCNF/ToLCNF.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/ToLCNF.lean) |
| 103 | LCNF backend | [`LCNF/ToMono.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/ToMono.lean) |
| 104 | LCNF backend | [`LCNF/Toposort.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Toposort.lean) |
| 105 | LCNF backend | [`LCNF/Types.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Types.lean) |
| 106 | LCNF backend | [`LCNF/Util.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Util.lean) |
| 107 | LCNF backend | [`LCNF/Visibility.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Visibility.lean) |
| 108 | Compiler frontend/attributes | [`Main.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/Main.lean) |
| 109 | Compiler frontend/attributes | [`MetaAttr.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/MetaAttr.lean) |
| 110 | Compiler frontend/attributes | [`ModPkgExt.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/ModPkgExt.lean) |
| 111 | Compiler frontend/attributes | [`NameDemangling.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/NameDemangling.lean) |
| 112 | Compiler frontend/attributes | [`NameMangling.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/NameMangling.lean) |
| 113 | Compiler frontend/attributes | [`NeverExtractAttr.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/NeverExtractAttr.lean) |
| 114 | Compiler frontend/attributes | [`NoncomputableAttr.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/NoncomputableAttr.lean) |
| 115 | Compiler frontend/attributes | [`Old.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/Old.lean) |
| 116 | Compiler frontend/attributes | [`Options.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/Options.lean) |
| 117 | Compiler frontend/attributes | [`Specialize.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/Specialize.lean) |

**Coverage verification:** GitHub pinned tree `e05e77632a5a66719c5fd83bd6adbdb081d1a232` contained 117 `.lean` blobs; 117 were retrieved in consecutive source-audit batches with no reported failures. Files under `src/Init`, `src/Std`, `src/Lean/Elab`, `src/Lean/Meta`, `src/lake` and `src/Lean/Server` were sampled and cited separately; this document does not claim to have scanned every source of the Lean language itself.
