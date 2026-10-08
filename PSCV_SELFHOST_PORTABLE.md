# PSCV Self-Host Portable — Long-Term Compiler Implementation Language

**Design edition:** Version 2 research proposal, 2026-10-08  
**Proposed implementation profile:** `PSCV-selfhost-portable/2`  
**Status:** PROPOSED; **not yet implemented, normatively adopted, or proven**  
**Destination:** `dwijayuda/pskernel` on default branch `main`  
**Repository snapshot studied:** `pscv/v3-execution` at `93add6da4e501c57f9016c7c3666ea52c87a66e7`  
**Upstream Lean semantics referenced:** Lean 4.35.0-rc3 at `470d5ce1400764999581fd26d5d72b00d990b0f4`  
**Current Lean bootstrap toolchain:** Lean 4.34.0 at `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`  
**Canonical compiler architecture:** [PSCV Compiler Reference V5.1](https://github.com/dwijayuda/pskernel/blob/pscv/v3-execution/psc15selfhost/THE_PSCV_COMPILER_REFERENCE_VERSION_5.1.md)  
**Existing language authority:** [ProofScript PSCV Language Reference](https://github.com/dwijayuda/pskernel/blob/pscv/v3-execution/psc15selfhost/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md)  
**Related isolated experiment:** [Lean-native frontend PR #81](https://github.com/dwijayuda/pskernel/pull/81)

> **Non-overriding rule.** This document proposes a new *compiler implementation source profile*. It does not revise the approved ProofScript/PSCV language grammar, the V5.1 semantic spine, `PSCV-VERIFY-v1`, `PSCV-CERT-v1`, the PSKernel kernel/provider boundary, or the existing frozen compiler bootstrap. In case of disagreement, the approved normative source prevails and promotion blocks until a versioned explicit decision is made.

## 0. Executive decision

Build PSCV in **one pleasant, Lean-compatible, total, backend-neutral ProofScript implementation language**, initially hosted by Lean 4 and eventually compiled by PSCV itself through independent JS, TS, direct Wasm and Rust compiler executables.

The desired source language should combine:
- **Lean 4:** ADTs, dependent and parametric types, pattern matching, monadic `do`, structured local mutation, proof terms, kernel-checked recursion, stable abstraction.
- **Rust:** explicit typed errors, data representation contracts, structural match, typed transformations, carefully controlled ownership-like API boundaries, bootstrapping stages.
- **Go:** simple loops, readable control flow, small modules, productive compiler development, seed-based bootstrap.
- **CompCert/CakeML:** small semantic representations, explicit per-pass correspondence, independently checked evidence, an independent distinction between bootstrap and compiler correctness.
- **Dafny/Verus:** contracts, local state, invariants, decreases, ghost code, explicit frames and disciplined proof obligation decomposition.

**Do not** permanently use `PSC1-selfhost-stable/1` as the source ergonomics ceiling; do not use unrestricted Lean, Rust, or Go semantics in the portable compiler's certified executable closure. Retain the current bootstrap as a *separately preserved seed*.

**Four-backend requirement:** each of TS, direct JS, direct Wasm and Rust must eventually emit a runnable *complete PSCV compiler* from the **same** closed `.ps` compiler source tree. Each resulting compiler must be able to compile the entire same source into **all four** targets. This implies a 4×4 = 16 producer/target re-entry matrix, not merely four demo programs.

**AI-proof objective:** maximize kernel-replayed, specification-preserving proof completion and minimize proof maintenance cost; compact readable source alone is not evidence of easier proofs. Restrictions should focus on proof-relevant complexity: uncontrolled aliasing, nondeterminism, opaque effects, partial recursion, unbounded tactic/instance search and arbitrary extensions.

**Implementation-first distinction:** development-mode compilation and explicitly unverified artifacts remain possible. Certified PSCV executable emission remains blocked by all required proof, effect, trust, specification, erasure and target-assurance gates.

## 1. Evidence method and source validity

Evidence categories:
- **OBSERVED:** inspected code/config or primary documentation; never generalized to unexamined files.
- **EXISTING REQUIREMENT:** already required by the approved PSCV language or V5.1 reference.
- **PROPOSED:** requirements for `PSCV-selfhost-portable/2` if explicitly adopted.
- **UNPROVEN:** a compiler capability, runtime correspondence, AI performance claim, preservation proof or certification gate still requiring evidence.

The researched implementation branch `pscv/v3-execution` is **not** automatically the same as GitHub `main`. Its documents are linked as research authority, not presented as already copied to `main`. No code, tests, kernel internals, profile JSON, active compiler branch or existing CI gate was changed by publishing this document.

**Method:** compare pinned primary sources from Lean, rustc and cmd/compile; compare PSCV's existing machine-readable source restrictions and backend interfaces; consult CompCert, CakeML, Verus, Dafny and Wasm specifications; derive a candidate profile, objective test suite and evidence-gated adoption plan. No compiler build, runtime benchmark, prover measurement, new self-host run or source-preservation theorem is claimed by this research.

## 2. Primary research: what real compiler codebases use

### 2.1 Lean 4 (pinned 4.35.0-rc3)

Inspected [LCNF](https://github.com/leanprover/lean4/tree/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF), [compiler IR](https://github.com/leanprover/lean4/tree/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/IR), [elaborator](https://github.com/leanprover/lean4/tree/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab), and [meta reasoning](https://github.com/leanprover/lean4/tree/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Meta).

Lean compiler code uses typed `inductive` and `structure` declarations, higher-order functions, local helpers, Reader/State/Except-style monads, `do` notation, `let mut`, `for`, `while`, `deriving`, typeclasses, mutual recursion, `partial def` and explicit `termination_by`. Concrete examples:
- [CompilerM.lean](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/CompilerM.lean) — Reader/State/Core monad stack, typed compiler state, instances.
- [PassManager.lean](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/PassManager.lean) — pass descriptors, finite loops, mutable local accumulators, typed errors.
- [ToLCNF.lean](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/ToLCNF.lean) — recursive lowering, monadic state and pattern matching.
- [InferType.lean](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/InferType.lean) — mutual and partial recursion for compiler type inference.
- [Specialize.lean](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Specialize.lean) — explicit termination measures and specialization transformations.
- [EmitC.lean](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/EmitC.lean) — stateful code builders, loops and data-layout handling.

An indicative, non-random 16-file Lean sample (~10,000 lines) has many textual occurrences of `do`, `for`, `let mut` and `partial def`. An indicative 16-file PSCV compiler/backend sample (~24,000 lines) has essentially no ordinary `do`/local-mutation/for-loop code and many fuel workers. These are approximate textual source scans, **not** AST-normalized statistics, matched functional scopes or measured productivity.

**Lessons to adopt:** compositional compiler monads, structural typing, local mutation as sugar for state, typed error propagation, finite iteration, total recursion, small Core and independent kernel checking. See the [Lean elaboration/kernel model](https://lean-lang.org/doc/reference/latest/Elaboration-and-Compilation/), [local state/loops](https://lean-lang.org/doc/reference/latest/Functors___-Monads-and--do--Notation/Syntax/) and [recursive functions](https://lean-lang.org/doc/reference/latest/Definitions/Recursive-Definitions/).

**Do not copy:** unrestricted `partial` (logically opaque), arbitrary `unsafe`/native evaluation, host IO, arbitrary macro/Meta syntax extension, LCNF runtime layout or Lean's entire standard environment into the closed portable profile. A Lean kernel check is not an executable backend semantic-preservation proof.

### 2.2 Rust/rustc

Inspected a recent pinned rustc snapshot at [`36aeef32c6c012e1af17af53a820aac042846c43`](https://github.com/rust-lang/rust/tree/36aeef32c6c012e1af17af53a820aac042846c43/compiler), including [expression parsing](https://github.com/rust-lang/rust/blob/36aeef32c6c012e1af17af53a820aac042846c43/compiler/rustc_parse/src/parser/expr.rs), [MIR inline](https://github.com/rust-lang/rust/blob/36aeef32c6c012e1af17af53a820aac042846c43/compiler/rustc_mir_transform/src/inline.rs), and [type context](https://github.com/rust-lang/rust/blob/36aeef32c6c012e1af17af53a820aac042846c43/compiler/rustc_middle/src/ty/context.rs).

Rust source uses enums/pattern matches, generics/traits, `Result` and `Option`, `?` error propagation, iterators, loops, arena-based allocation and sometimes local `unsafe`. The rustc compiler architecture distinguishes AST, HIR, THIR, MIR, optimization and backend codegen; queries cache computations ([rustc guide](https://rustc-dev-guide.rust-lang.org/overview.html)). Stage0, stage1, stage2 and stage3 have distinct bootstrap roles ([bootstrap guide](https://rustc-dev-guide.rust-lang.org/building/bootstrapping/what-bootstrapping-does.html)).

**Adopt:** clear typed error/result APIs, pattern matching, pass-specific IRs, query identity, structured data, staged bootstrap and explicit unsafe/boundary annotations. **Do not adopt as portable semantics:** general Rust lifetime/borrow checking, raw pointers, nondeterministic allocation behavior, unsafe memory layout or Rust-specific runtime intrinsics. Backends may use Rust ownership internally while representing the same PSCV abstract values.

### 2.3 Go/cmd/compile

Inspected [Go cmd/compile pinned `3b98eddbcd66230a78c4893f32099b5d3045a334`](https://github.com/golang/go/tree/3b98eddbcd66230a78c4893f32099b5d3045a334/src/cmd/compile), including [syntax/parser.go](https://github.com/golang/go/blob/3b98eddbcd66230a78c4893f32099b5d3045a334/src/cmd/compile/internal/syntax/parser.go) and [ssa/func.go](https://github.com/golang/go/blob/3b98eddbcd66230a78c4893f32099b5d3045a334/src/cmd/compile/internal/ssa/func.go). Its [compiler README](https://github.com/golang/go/blob/3b98eddbcd66230a78c4893f32099b5d3045a334/src/cmd/compile/README.md) describes syntax, type checking, IR, walk/desugaring, SSA and backends.

The implementation uses simple `for`/`switch`, slices, maps, structs/interfaces and explicit helper functions extensively. The Go toolchain is written in Go and bootstraps from an earlier compatible Go compiler ([official Go source build guide](https://go.dev/doc/install/source)). 

**Adopt:** straightforward iterative algorithms and small named operations. **Do not adopt blindly:** mutable shared map semantics, unspecified map iteration order, panic as normal typed error flow, runtime goroutines/channels and platform `int` width. All are challenging either to reproduce across backends or to verify with small reusable invariants.

### 2.4 CompCert, CakeML, Dafny and Verus

[CompCert](https://compcert.org/doc/) uses proof-oriented intermediate languages, pass-specific semantic preservation and, in [its research agenda](https://compcert.org/research.html), validation of untrusted optimizations by small checkers. [CakeML](https://cakeml.org/index.html) demonstrates compiler verification and self-bootstrap with independently meaningful evidence. [Dafny](https://dafny.org/dafny/OnlineTutorial/guide) makes loop invariants and decreases essential to general total correctness. [Verus](https://verus-lang.github.io/verus/guide/) demonstrates executable/spec/proof separation, while motivating careful alias/permission discipline.

**Lesson:** implementation correctness, checker soundness, pass preservation, generated-target behavior, trust assumptions and bootstrap fixed points are distinct claims. Pure total functions are easiest to model, but explicit local mutable state can remain tractable if the lowering produces small well-specified state-transformer/SSA obligations.

### 2.5 Research synthesis

| System | Valuable source feature | Verification / portability cost to avoid |
|---|---|---|
| Lean 4 | ADTs, monads, `do`, patterns, total recursion, kernel proofs | Unrestricted partial/unsafe/macro/Meta/IO/runtime specifics |
| Rust | Typed errors, compiler IRs, rich pattern matching, staged bootstrap | Borrow/lifetime/unsafe/runtime semantics in the language core |
| Go | Readable loops, simple algorithms, practical compiler modules | Shared mutation, implicit panics, map nondeterminism |
| CompCert/CakeML | Checked transformations and typed pass semantics | Mistaking fixed point for correctness or tests for proof |
| Dafny/Verus | Invariants, contracts, explicit frames and ghost proofs | Unrestricted heap mutation and large global solver search |

## 3. PSCV repository facts and compatibility requirements

**Existing state on the audited execution branch:**
1. [`selfhost-profile.json`](https://github.com/dwijayuda/pskernel/blob/pscv/v3-execution/psc15selfhost/selfhost-profile.json) declares `PSC1-selfhost-stable/1` and forbids source forms including mutual recursion, explicit decrease syntax, derivation, tactic proof, `let mut`, `for`, `while` and open macro syntax.
2. [`portable-selfhost-profile.json`](https://github.com/dwijayuda/pskernel/blob/pscv/v3-execution/psc15selfhost/portable-selfhost-profile.json) preserves those restrictions and guards additional fragile code patterns.
3. [`SELFHOST_SOURCE_STANDARD.md`](https://github.com/dwijayuda/pskernel/blob/pscv/v3-execution/psc15selfhost/docs/SELFHOST_SOURCE_STANDARD.md) explicitly says this is a *bootstrap implementation discipline*, not the future normative ProofScript feature ceiling. It defines profile, selfhost/guard and compiler fixed-point checks.
4. The compiler has distinct `PsErasedIrModule` and `PsValidatedIrModule` types; **validated IR is not logically certified source**. [IR model](https://github.com/dwijayuda/pskernel/blob/pscv/v3-execution/psc15selfhost/packages/compiler-ir/src/Ps/CompilerIr/Model.lean).
5. Source-to-target drivers exist for [TypeScript](https://github.com/dwijayuda/pskernel/blob/pscv/v3-execution/psc15selfhost/packages/driver-ts/src/Ps/DriverTs/Compiler.lean), [JavaScript](https://github.com/dwijayuda/pskernel/blob/pscv/v3-execution/psc15selfhost/packages/driver-js/src/Ps/DriverJs/Compiler.lean), [WebAssembly](https://github.com/dwijayuda/pskernel/blob/pscv/v3-execution/psc15selfhost/packages/driver-wasm/src/Ps/DriverWasm/Compiler.lean) and [Rust](https://github.com/dwijayuda/pskernel/blob/pscv/v3-execution/psc15selfhost/packages/driver-rust/src/Ps/DriverRust/Compiler.lean). They are not yet proof of full four-way compiler self-host portability.
6. V5.1 already defines the semantic spine: **Source → Core → Checked → Certified → RuntimeIR → validated runtime → specialization → TS/JS/Wasm/Rust**, plus an authority firewall and claim lattice. This proposal does not bypass those boundaries.
7. PSCV's [normative language reference](https://github.com/dwijayuda/pskernel/blob/pscv/v3-execution/psc15selfhost/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md), feature closure `2.4` and verified-do/recursion chapters already contemplate `let mut`, finite iteration, well-founded total recursion, contracts, ghost values and state/reader/typed-error effects. Their full implementation and backend closure are not established merely by the normative text.
8. [Experimental Lean frontend PR #81](https://github.com/dwijayuda/pskernel/pull/81) verifies a bounded `.ps` → `.lean` path with a 4.35 kernel; it does not have full source contracts, PSCV-CERT, or JS/TS/Wasm/Rust interop.

**Design conclusion:** extend compiler capabilities in coherent semantic *families* and retain the stable old compiler as bootstrap seed, rather than forcing future compiler source into historically restrictive fuel/primitive patterns or weakening self-host evidence to permit unsupported forms.

## 4. Profile identity and compatibility hierarchy

The proposed source implementation profile is `PSCV-selfhost-portable/2`, deliberately distinct from:
- `PSC1-selfhost-stable/1` — frozen compiler bootstrap seed.
- `PSC1-portable-selfhost/1` — existing post-seed limited portability checks.
- `ps-standard-0.9-r3` / `lean-subset-psc2-v1` — existing legacy language/compatibility identities.
- `pscv-v1` — the normative verified language.
- `pscv-closed-v1` / `pscv-boundary-v1` — normative trust and effect policies.
- `PSCV-VERIFY-v1` — verification-condition semantics.
- `PSCV-CERT-v1` — certified-build acceptance, not an executable emitter.

**Rule:** the source profile is a subset of the approved PSCV source grammar and must not redefine the language's Core, instance/coercion semantics, numeric primitives, effect meaning, or proof authority. Any extension not already covered by the normative source must be an explicit proposal for a *new named semantic profile revision*, not an implicit feature addition under the same identifier.

An implementation claiming `PSCV-selfhost-portable/2` needs a signed/hashed profile manifest binding: exact grammar, sources, Standard environment, Lean reference/pin, profile feature IDs, source import closure, primitive semantics, target runtime support, selected host capabilities and test/evidence metadata. Stable hashes are computed only after final manifests exist; this document invents no digest.

## 5. Weighted evaluation rubric — requested eleven criteria

**Interpretation:** weighted *architecture preference* scores, not objective measured compiler coverage, performance, proof throughput or security. Each candidate gets a 0–5 judgment per criterion. Sum = `Σ (weight × score / 5)`, max 100. Extra weight goes to soundness, actual ability to formally verify a compiler, and four-backend portability.



| Criterion | Weight | PSC1 | Lean full | Rust-like | Go-like | Pure minimal | Proposed V2 |
|---|---:|---:|---:|---:|---:|---:|---:|
| Soundness / fidelity | 14 | 3.5 | 3.8 | 3.3 | 2.9 | 4.6 | 4.5 |
| Formal/metatheoretic verification ability and cost | 18 | 3.3 | 3.6 | 2.9 | 2.5 | 4.8 | 4.3 |
| Malformed-input robustness | 9 | 3.5 | 3.5 | 3.8 | 3.2 | 4.5 | 4.4 |
| Compatibility completeness | 8 | 1.3 | 4.8 | 4.1 | 3.8 | 2.3 | 4.3 |
| Architecture | 9 | 2.8 | 4.2 | 3.7 | 3.7 | 3.8 | 4.7 |
| Performance | 8 | 2.0 | 4.2 | 4.2 | 4.1 | 2.6 | 4.2 |
| Portability | 10 | 4.3 | 1.4 | 2.1 | 3.5 | 4.7 | 4.5 |
| Longevity | 6 | 2.5 | 4.3 | 4.1 | 4.1 | 3.7 | 4.5 |
| Interoperability | 5 | 2.7 | 3.3 | 4.4 | 4.0 | 3.0 | 4.4 |
| Self-host/bootstrap | 9 | 4.0 | 2.0 | 2.7 | 3.4 | 3.1 | 4.3 |
| Auditability | 4 | 3.0 | 3.0 | 3.4 | 3.7 | 4.6 | 4.5 |
| **Weighted preference / 100** | **100** | **62.2** | **69.1** | **67.6** | **67.2** | **79.0** | **88.2** |

**Interpretation, not marketing:** portable V2 is preferred *if implemented* (estimate **88.2/100**), compared with pure minimal (**79.0**), Lean full (**69.1**), Rust-inspired (**67.6**), Go-inspired (**67.2**) and existing PSC1 style (**62.2**). These exact scores are normative **neither for soundness nor for release**, and could change substantially with different weights or measured evidence. A minimal total functional subset may outperform the portable V2 profile in measured AI proof throughput; retain the experiment rather than presuming the more convenient language is easier to prove.

**Criterion-specific tradeoffs:**
- *Soundness/fidelity:* one small meaning for each admitted construct; check elaborate/erase/call proof and target runtime correspondence.
- *Formal verification ability and performance:* favor total ADTs, clean induction, local state, typed results, controlled instances, named lemmas and bounded VCs over partial functions and arbitrary heap alias.
- *Malformed-input robustness:* explicit parser bounds, fuel/resource errors, negative tests and fail-closed unknown behavior.
- *Compatibility completeness:* sufficient features to express the *entire* PSCV compiler; avoid forcing boilerplate into every pass.
- *Architecture:* reuse V5.1 semantic spine and frontend/provider/backend boundaries.
- *Performance:* real array/byte/map builders, efficient traversals, explicit worklists and backend-specific semantics-preserving representations.
- *Portability:* four independent compiler runtimes; future Python/PHP/Java/Go feasibility.
- *Longevity:* stable source grammar, standards, semantics and versioned feature migration.
- *Interoperability:* source/environment identities, typed host interfaces, target ABIs, WIT if appropriate.
- *Self-host/bootstrap:* seed preservation, per-target re-entry, staging and cross-checking.
- *Auditability:* compact proof obligations, explicit assumptions, stable source maps, reproducible evidence.

## 6. Feature taxonomy and exact design decisions

**F0:** required within the full four-backend portable compiler closure. **F1:** useful extension staged behind an explicit profile revision and independent target/proof acceptance. **H:** host/build/assurance tooling outside the portable closed executable source. **X:** prohibited in the portable closed executable source.

| Source feature | Tier | Reason | Proof / backend restriction |
|---|---|---|---|
| `def` / `function`, typed `let`, named modules/imports | F0 | Core language structure | Explicit imports, scope identity, total executable meaning |
| `inductive` ADTs, recursive/indexed constructors | F0 | AST, typed Core, errors, IR | Positivity, constructor indices, exhaustive match |
| `structure`, field projection, record update | F0 | Compiler environments/state | Immutable values and field invariants |
| Nested pattern matching, local helpers/`where` | F0 | Readable passes | Small independent case obligations |
| Bounded generics and implicit arguments | F0 | Reusable algorithms | Closed specialization and deterministic inference |
| Higher-order immutable closures | F0 | Visitors/folds | Immutable captures, specified closure conversion |
| `List` / `Array` / `ByteArray` / tuples | F0 | Compiler data | Exact bounds, bytes, tuple/ADT semantics |
| `Option` / `Except` and typed errors | F0 | Recoverable failures | No implicit throws/traps |
| `do`, `let ←`, early `return` | F0 | Practical compiler state | Explicit WP/effect translation |
| Local `let mut` / assignment | F0 | Efficient accumulators | No escaping mutable refs or aliases |
| Finite `for` with `break`/`continue` | F0 | Parsers, arrays, optimization passes | Certified iterator semantics and loop measure |
| Structural recursion and `termination_by`/`decreasing_by` | F0 | Total parser/inference passes | Kernel-accepted proof of decreases |
| Mutual total recursion | F0 | Mutually defined syntax/inference | Joint well-founded measure |
| Closed deterministic class/instance/coercion resolution | F0 | Reusable typed APIs | Frozen registry, no ambient search differences |
| Pure, Reader, State, typed error effects | F0 | Compiler state and results | Registered WP and explicit state-on-error behavior |
| Approved contracts, theorem terms and proof tactics | F0 | Compiler correctness | Pinned proof environment, checked terms |
| Simple transparent `abbrev` | F0 | Reusable type/function aliases | No opaque executable effect |
| Ordered traversal over maps, hash-map lookup | F0 library | Fast symbol tables, deterministic build | Hash iteration cannot determine output order |
| Byte/string builders, immutable cursors/worklists | F0 library | Portable performance | UTF-8 semantics and bounds laws |
| Restricted, fully specified `deriving` | F1 | Avoid routine boilerplate | Only fixed standard derived declarations/laws, hashed expansion |
| General verified `while` | F1 | Flexibility | Explicit invariant/decreasing obligations |
| Efficient scoped mutable builders | F1 library | Performance | Pure abstract model and frame theorem |
| `Fin`, `Subtype` and dependent/refined invariants | F1 | Stronger contracts | Use where they *reduce* proof burden |
| `opaque` abstract specifications | F1 spec-only | Modular logical reasoning | No opaque executable with unverified relation |
| Arbitrary Lean `syntax`/`macro`/`Meta` | H | Development and proof producer | Not standard portable source; kernel checks final proofs |
| Raw IO, process/network/FFI | H or explicit boundary | Host/runtime tools | No closed proof of external effects without model |
| `unsafe`, `partial`, unchecked user `axiom` | X | Unsound/unproven executable closure | Transitive rejection; don't rely on token scanner |
| Aliased mutable pointers/general heap ownership | X | High cross-backend and proof cost | Future distinct region/heap profile required |
| Unrestricted reflection/dynamic eval | X | Runtime/proof portability | Host-only, explicit identity |
| Ambient globals/nondeterministic concurrent execution | X | Determinism and semantic fidelity | Explicit interfaces if added in future |
| Foreign unchecked native proof shortcuts | X | Soundness risk | Cannot grant proof authority |

**Admission rule:** syntax parsing or successful Lean elaboration alone does not make a feature F0. A feature needs a closed grammar rule, exact semantic/lowering contract, PSCV-owned checked runtime representation, all four target implementations, positive/negative tests, proof-relevant invariants and whole compiler closure acceptance. Unavailable features must produce deterministic typed rejection, never silent fallback.

### 6.1 Total recursion vs Lean-style `partial`

Lean compiler source uses `partial def` pragmatically. PSCV's approved verified executable profile rejects partial source. Copying all of Lean's partial internal helpers would obstruct a whole-compiler closed certificate.

Proposed solution: structural recursion and well-founded `termination_by` in the portable source; finite iterators and worklist libraries for deep traversals; recognized `Except ResourceExceeded` results for explicit resource budgets. A fuel-limited algorithm that substitutes a dummy success value at exhaustion is **not** equivalent to its intended specification. For algorithms requiring partial behavior or unproved termination, allow a separate **development-only or explicit-boundary module**, not a false closed artifact.

### 6.2 Local mutation rather than Rust/Go general mutation

Permit **locally scoped** mutable bindings under an admitted `do`, with early return, finite for, break and continue. Lower to explicit state passing or SSA plus a registered weakest-precondition specification. Keep mutable state from escaping into aliasable heap references. This preserves everyday compiler performance and readability without importing Rust's lifetime rules or Go's shared mutable heap into every future backend.

An especially important F0 ordering: **(1) `do` and typed error, (2) local mutation, (3) finite `for`, (4) mutable builder libraries, (5) generalized verified `while` only when necessary**. The last feature has a larger VC/termination search cost and need not gate initial portability if equivalent total worklists suffice.

### 6.3 Higher-order helpers and typeclasses

Allow immutable closure captures, fixed `map`/`fold`/`traverse` families and closed classes/instances. Explicit public signatures and deterministic instance resolution are mandatory. Reject unrestricted higher-rank polymorphic runtime values or open-ended specialization until four backend implementations and proof normalization exist. A standardized iterator with proved laws is often *easier* for an AI to verify than repeated handwritten recursion; test both rather than dictate one universal style.

### 6.4 Proof terms, ghost, contracts and deriving

Use the approved PSCV specification/proof grammar. Lean tactics `simp only`, `omega`, `grind`, `cases`, `induction`, `rw` and similar pinned tactics act only as **proof producers**. Kernel-checked proof terms and the exact allowed assumption closure carry authority. Ghost data must erase without executable influence and must not be silently visible to a backend.

A fixed `deriving` set is a worthwhile F1 convenience (equality, representation, finite structural lemmas), but generated declarations and theorem statements must be deterministic, digest-locked and independently checked. Arbitrary user-defined deriving handlers/macros are not F0.

## 7. Proposed source style for an AI-provable compiler

The code below is **illustrative only**. Its exact ProofScript syntax, constructor spelling, verified typed-error WP and library member names must pass the approved PSCV grammar before becoming an accepted compiler source file.

~~~proofscript
inductive ParseError where {
  | unexpectedEnd(offset: Nat)
  | invalidByte(offset: Nat)
}

structure Cursor where {
  bytes: ByteArray
  offset: Nat
}

function scanAscii(bytes: ByteArray): Except ParseError (Array UInt8)
  requires True
  ensures result => result.size <= bytes.size
:= do {
  let mut out := Array.empty
  for b in bytes {
    if b < 128 {
      out := out.push(b)
    } else {
      return Except.error(ParseError.invalidByte(out.size))
    }
  }
  return Except.ok(out)
}
~~~

**Source code design guidance:**
1. Prefer one typed error enum and one explicit mutable state record per logical subsystem over ad hoc heterogeneous flags.
2. Give every public compiler pass typed input/output and a named specification; document preservation of source spans, types, control flow and assumptions.
3. Use local state and finite loops for straightforward accumulation. Use immutable structural recursion for proofs and transformations where induction is simpler.
4. Avoid enormous fuel workers and blanket catches. A computation-limit failure is a typed error, not arbitrary result recovery.
5. Keep proof statements independent of executable implementation; an AI must not weaken an approved specification just to make a proof pass.
6. Keep imports, instance/coercion resolution, generated names and pass order deterministic.
7. Use small named invariants, lemmas and library contracts rather than unfolding every compiler operation in a huge tactic goal.
8. Separate pure transformation from target emitter, filesystem/CLI/network IO and runtime resource behavior.
9. Avoid copying target-owned data representations into the target-neutral Core.
10. Keep source positions on generated proof obligations and specify exact imported theorem dependencies.

**Current implementation warning:** none of the illustrative feature examples is claimed to compile using current PSC1 or PR #81. The examples are proposed contract cases for future development.

## 8. Portable runtime semantics — first-class backends and later backends

**Principle:** ProofScript semantics come from the pinned language/profile, not from JavaScript, Rust, Wasm, Go, PHP, Python or Java host defaults. Every implementation must either prove/validate the correspondence or reject the feature.

### 8.1 Numbers, characters, strings

- **Nat/Int:** preserve exact unbounded mathematical values where required. JS `Number` cannot model arbitrary Nat; JS/TS may use `BigInt` or a precise library, Wasm must have its own exact representation, and Rust uses exact integer support. Python big integers are convenient; Java `BigInteger`/Go big integer/PHP library semantics need wrappers.
- **Fixed-width machine ints:** define width, signedness, wrap/overflow/convert/divide/shift exactly and pin `USize`/`ISize` to target profile. Never inherit debug/release Rust overflow or JS precision limits as source semantics.
- **Float/Float32:** if included in the compiler implementation closure, make NaN, infinity, -0, rounding, comparisons and serialization explicit and test target drift. The initial proof-oriented compiler core may deliberately avoid floats even though PSCV as a language supports them.
- **Char/String:** compiler lexing, token offsets and source maps operate on canonical UTF-8 bytes and explicit Unicode scalar decoding. JS and Java use UTF-16-oriented string APIs; PHP strings are byte sequences; Go string iteration follows UTF-8 code points. Define invalid UTF-8 handling and byte offsets, not an unspecified "character index."
- **Canonical output:** no locale, time zone, file-system iteration order or platform newline effects on deterministic compiler artifacts.

### 8.2 Values, collections, evaluation

- ADTs and structures are abstract typed values. JS tags, Rust enums and Wasm runtime layouts are backend-private and may differ.
- Arrays have fixed, checked bounds semantics: proof-carrying `Fin` indices or explicit `Option`/`Except` results. No ambient JS undefined, Rust panic or Wasm trap as a successful PSCV value.
- Hash maps are allowed for lookup, but **no output-order-sensitive traversal may depend on hash iteration**. Use a stable key sort, source-order vector, or ordered-map interface. Go specifically does not guarantee map iteration order; other runtimes have distinct ordering rules.
- Immutable closures capture values under a closed environment, with target-independent call and evaluation order. General mutable closure captures with observable aliasing are outside the F0 subset.
- Generic specialization must be finite, type correct and linked to declared source/target identities; avoid target-specific specialization accidentally changing behavior.
- Keep evaluation order, short-circuit, early return, `break`, `continue` and explicit error propagation defined by the source semantics, not target-language quirks.

### 8.3 Effects, IO and resource behavior

- F0 effects: pure/Id, Reader, State and typed Except, with registered WP and **explicitly defined state-on-error behavior** (rollback vs retained state is not left to host runtime).
- Raw file/network/clock/random/FFI activity remains outside the closed compiler semantic core. Expose typed host capabilities with declared assumptions under the appropriate PSCV boundary policy.
- Mathematical termination does not guarantee finite machine resources. Expose resource budget, memory and stack behavior as separate runtime conditions and typed failures where possible; log unavoidable host limits rather than claiming closed total operation in an uncontrolled environment.
- Prefer explicit worklist/iterator lowering for deep compiler trees. JS stack depth and Wasm runtime stack differ; do not assume a portable tail-call optimization.
- Performance optimization may change representation, but it must not change semantic results, diagnostics, ordering or proof claims.

### 8.4 Backend semantic mapping

| Obligation | Direct JS | TS source | Direct Wasm | Rust source | Future backend impact |
|---|---|---|---|---|---|
| Unbounded Nat/Int | BigInt/exact lib | Same semantics with erased annotations | Explicit big-int runtime | Exact integer lib | Python native; Java/Go/PHP library |
| Machine integers | Width-specific arithmetic | Same JS runtime | i32/i64 + profiles | Explicit width ops | Target wrapper |
| UTF-8 source spans | Byte arrays | Byte arrays | Linear memory bytes | UTF-8 bytes | Avoid PHP/Java native character indexing |
| ADT values | Tagged records | Runtime tagged values | Tagged memory representation | enums/structs | Same abstract constructors |
| Closures | Explicit env or closure | Compatible JS closure | Closure conversion | Specialization/env | Explicit contract |
| Typed results | Tagged success/error | Typed TS union erased at runtime | Tagged ABI result | Result type | Typed wrapper |
| State/local mutation | Locals/SSA | Same behavior | Locals/state | Local mutable bindings | Same abstract transition |
| Hash maps | Explicit stable iteration | Same runtime policy | Ordered output adapter | Explicit ordering | No ambient map iteration |
| IO/capabilities | Node host adapter | Node host adapter | Explicit Wasm host ABI | CLI/FFI adapter | Interpreter/JVM/runtime-specific |
| Proof authority | External to JS engine | External to tsc | External to Wasm validator | External to rustc | Needs checked source proof |
| Preservation evidence | JsIR/correspondence | TS and JS relations | WasmIR + ABI validation | Rust output + rustc assumptions | Backend-specific |

### 8.5 Optional future Python, PHP, Java and Go backends

They are **not** required for v2 four-backend acceptance; nevertheless F0 must remain translatable without redefining semantics. Python string/boolean/dynamic-number behavior, PHP byte strings and integer precision, Java UTF-16 and primitive widths, and Go map ordering/`int`/panic require explicit adapters. A future backend must ship a descriptor, semantic runtime model, target IR validity checks, ABI, conformance corpus and separate assurance status.

This is an argument for a small *value-and-effects language*, not a large virtual machine in the source grammar or a permanent assumption of JavaScript objects.

## 9. AI proof-engineering contract

### 9.1 Why source-language restrictions matter

AI proof assistants perform better when the verification task is stable, local and machine-observable; whether a particular syntax actually improves success must be measured. The major proof difficulty comes from **large state spaces, overloaded implicit behavior, aliasing, nonlinear recursion, opaque dependencies, nondeterministic effects and nonlocal specification changes**, not necessarily source line count.

**Required proof-ready module metadata (proposed):**
1. Module/source/profile/environment digest and imported dependency closure.
2. Public function signature, effect, typed error, runtime and logical dependency closure.
3. Approved specification independent of implementation; explicitly named pre/post, frame and failure properties.
4. Named termination measure for recursion or bounded loop/iterator evidence.
5. Deterministic VC IDs with source spans, exact assumptions, proof state, tactic/solver pins and resource limits.
6. A small lemma API: constructor/exhaustiveness, data structure invariants, state transition, substitution/renaming, typing, semantic preservation.
7. Proof replay status separately from test status and from emitter/runtime correctness.
8. Stable artifact signatures so an AI can localize changed proof obligations rather than regenerate all of them.

### 9.2 Preferred patterns by module

| Module family | Programming pattern | Key proof properties |
|---|---|---|
| Lexer/parser | Mutable-local cursor, finite ByteArray traversal, typed errors | Bounds, progress, totality, exact spans |
| Core/AST | Algebraic data, pure constructors, exhaustive matches | Well-formedness, scope, substitution |
| Elaborator/unifier | Reader/State/Except with explicit backtracking contract | Sound substitutions, occurs-check, deterministic instances |
| Meta/reduction | Total recursive transformations with named measures | Conversion correspondence, invariant preservation |
| RuntimeIR/validation | Immutable typed IR + linear validation | Full-reference and type preservation |
| Optimizer/specializer | Pure pass + local arrays/worklists | Pass-specific semantic relation |
| Code emitters | Deterministic builders and typed target IR | Output exactness, name/scope and ABI correctness |
| Kernel | Minimal total functions and independent checking | Logical soundness, no hidden proof assumptions |
| Host/CLI | Explicit boundary capabilities, typed errors | No false closed assurance for external effects |

### 9.3 Lean and tool-driven proof policy

Use pinned `simp only`, `omega`, `grind`/`grind only`, induction, case split and rewriting to *construct* proofs. Only accepted proof terms under exact, audited theorem/axiom imports carry authority. Tool search success without accepted kernel evidence is insufficient. An AI may propose specifications, but it may not silently replace the approved specification, weaken effect constraints or introduce unapproved axioms. [Lean tactics](https://lean-lang.org/doc/reference/latest/Tactic-Proofs/) and [grind](https://lean-lang.org/doc/reference/latest/The--grind--tactic) provide concrete automation; [Verus](https://verus-lang.github.io/verus/guide/) motivates explicit spec/proof/executable separation.

### 9.4 Empirical AI proof-performance study

**No research in this document proves an AI proof-efficiency improvement.** Before making that claim, run 15–30 fixed tasks representing parse bounds, exact decoding, unification, type preservation, canonical serialization, specialization and backend lowering. Compare:
- A: current `PSC1-selfhost-stable/1` explicit-worker source;
- B: rich F0 `PSCV-selfhost-portable/2` source;
- C: equivalent pure functional/fold implementation where feasible.

Control: identical approved property, Lean/PSKernel version, imports, model configuration, available tools, wall-clock and token limits. Repeat each task with multiple controlled independent trials; report failures and dispersion.

**Record:** kernel-replayed proof completion; obligation coverage; admitted axioms; false-claim rejection; median/p95 wall-clock; token/tool-call/patch count to valid proof; VC count/size/depth; proof repair effort after behavior-preserving refactor; compilation and target runtime performance. Primary acceptance is **no soundness/specification regression** and statistically defensible proof-completion non-inferiority; proof effort reduction is then the optimization objective. A 20% median proof-effort reduction may be an experiment target, **not** an architecture fact or release requirement.

Pure recursive definitions might prove faster than mutable state on a given task. Keep both admitted idioms and select using repeatable evidence.

## 10. Four-backend complete self-hosting contract

### 10.1 Definitions: source portability vs executable self-host

- **D0 Lean developable:** canonical source checks with pinned Lean; any executable generation is labelled **development-unverified**.
- **P1 native source portable:** native PSCV accepts the same source/profile and satisfies checked semantic conformance on admitted module families.
- **P2 four-target runnable:** the *whole* compiler source closure emits and runs in TS, JS, Wasm and Rust.
- **P3 four-target self-hosting:** every compiler target can recompile the same full compiler source closure, with generation re-entry/fixed-point evidence.
- **P4 certified:** source spec coverage, proof/effect/assumption closure, erasure and requested backend preservation/certificate gates hold; P3 alone never implies P4.

A Wasm parser, a JS compiler backend demo, a native Rust emitter, or a program that calls Lean externally to perform its own elaboration is not P3 self-hosting.

### 10.2 Product requirements

| Target | Required result | Explicit runtime/toolchain assumption |
|---|---|---|
| `typescript` | Complete emitted TS compiler source, optional declarations/maps, executable through pinned tsc | TS type erasure, pinned tsc and Node/compatible JS runtime |
| `javascript` | Complete directly emitted JS compiler, no tsc dependency | Pinned JS runtime, byte/BigInt/collection shim |
| `wasm` | Complete direct Wasm compiler binary plus ABI and host adapter | Wasm engine, imports/exports and WASI/JS/native host capabilities |
| `rust` | Complete emitted Rust compiler source and native executable | Pinned rustc, linker, target triple and runtime dependencies |

Lean's own C backend does not implement these four targets. Do not use tsc as the mandatory JS backend or disguise transpiling Lean's generated C into four targets as proof of native PSCV IR conformance.

### 10.3 Mandatory 16-cell re-entry test

Let `C[t]` be a complete running compiler built using backend `t`, where `t` is TS, JS, Wasm or Rust. Every `C[t]` MUST be capable of compiling the **identical pinned canonical source closure** into each of the four target kinds:

| Running compiler | Emit TypeScript | Emit direct JS | Emit direct Wasm | Emit Rust |
|---|---|---|---|---|
| C[TypeScript] | REQUIRED | REQUIRED | REQUIRED | REQUIRED |
| C[JavaScript] | REQUIRED | REQUIRED | REQUIRED | REQUIRED |
| C[Wasm] | REQUIRED | REQUIRED | REQUIRED | REQUIRED |
| C[Rust] | REQUIRED | REQUIRED | REQUIRED | REQUIRED |

Per cell: freeze source/environment/toolchain identities; run parser, elaborator, checked session, erasure, runtime validation, specialization, backend and publisher; exercise malformed-input rejects; compile/run emitted result; record exact semantic and artifact identities; attempt stage2/stage3 self-reproduction; independently compare behavior to the reference and other producer targets.

**Equality rule:** do not demand byte-identical Rust, JS, TS and Wasm binaries to one another. Require canonical semantic/IR/behavioral correspondence, deterministic outputs for fixed *target and toolchain*, and justified equivalence across generations. Byte equality/fixed point is meaningful only with pinned equivalent compiler, profile, target, host ABI, toolchain and serialization rules.

A compiler assembled from emitted Wasm still needs actual source ingress, file/build output, host capability adapter and all four backends. Hidden calls back into a bootstrap Lean/PSC1 compiler invalidate P3 claims.

### 10.4 Required target conformance corpus

Cover: full module/import closure, deeply nested AST, worklist stack safety, malformed inputs and resource exhaustion, negative proof/spec gates, recursive ADT/closure/generic calls, state/error rollback semantics, 32/64-bit integer edges, large Nat/Int, Float edge cases if admitted, invalid UTF-8, byte source maps, deterministic map collisions/order, ABI/FFI boundaries, target runtime initialization/GC/RC, sealed host imports/exports, generated compiler re-entry, frozen stage2/stage3 profiles.

All 4 tools have distinct boundaries: TypeScript involves tsc + JS runtime; JS uses direct emitter; Wasm uses a validator + engine + ABI; Rust uses rustc + native runtime. The presence of validated RuntimeIR is **not** source logical certification, and compiler success is **not** target semantic preservation evidence.

## 11. Lean-first, PSCV-owned later: transition architecture

~~~text
                         authoritative PSCV source (.ps)
                                      |
                         versioned F0 source profile
                                      |
                  +-------------------+-------------------+
                  |                                       |
          Lean-hosted frontend                    native PSCV frontend
       closed grammar -> Lean syntax            PSCV parser/elaborator
                  |                                       |
     pinned Lean elaborator + kernel               PSKernel checked session
                  |                                       |
          checked Lean Core                        checked PSCV Core
                  |                                       |
       explicit Core->Runtime adapter               native erasure path
                  |                                       |
                  +-------------------+-------------------+
                                      |
               independent semantics and evidence comparator
                                      |
            source certification OR explicit development boundary
                                      |
                         target-neutral RuntimeIR
                                      |
                  strict validation -> specialization
                                      |
                 +--------+---------+---------+---------+
                 |        |         |         |         |
                 TS       JS       Wasm       Rust      (future...)
~~~

### 11.1 Lean-host reuse layers

**L0 — Existing M0:** the bounded PR #81 `.ps`→`.lean` bridge hosted by an existing Lean 4.34 translator and checked by pinned Lean 4.35. Contract lowering, complete grammar, source fidelity and four outputs are missing. Remain explicitly unverified.

**L1 — Closed PSCV language:** exact source maps, frozen grammar and stable import/name/instance/coercion resolution. A Lean parser can be a *host tool* but cannot admit arbitrary Lean syntax from the environment. Match the PSCV normative semantics, not merely Lean's default elaboration output.

**L2 — Trusted checker boundary:** use Lean kernel on elaborated declarations. Independently audit declaration imports, assumptions and runtime reachability, and keep approved specifications/checked proofs exact. Kernel typing does not imply approved spec coverage.

**L3 — Lean-Core-to-PSCV RuntimeIR adapter:** convert closed supported Lean Core/executable declarations to typed PSCV RuntimeIR; handle dependency closure, primitive intrinsics, recursive inductives, recursors, polymorphic specialization, closures and erasure; reject unknown runtime types or unverified semantic gaps. Never fabricate a verified IR constructor by an unchecked cast.

**L4 — Verify:** implement `requires`/`ensures`, call-site VCs, state/error WP, finite for invariants, termination and ghost-erasure models, using Lean's pinned proof infrastructure as untrusted proof producer where appropriate. PSCV certification only when the complete mandated closure is accepted.

**L5 — Existing target drivers:** feed the V5.1 target-neutral IR path and reuse backend TS, direct JS, Wasm and Rust with their independent validation. Provisional development emissions remain marked unverified.

**L6 — Native PSCV parity:** PSCV parser, elaborator, checking via PSKernel, erasure and runtime IR produce corresponding semantic identities; Lean becomes a differential reference and independent checker, not a production dependency.

**L7 — Independent bootstrap and assurance:** build all four compiler executables, run 16-cell re-entry, independent checker/proof gates, target preservation evidence and requested artifact/release claims.

### 11.2 Strict prohibitions during transition

- Do not assume the legacy Lean 4.34 translator's full semantics equals the 4.35 normative profile.
- Do not equate a Lean `Expr`, Lean `LCNF`, a generated C file, a checked Core term, or a well-formed RuntimeIR with the certified PSCV executable boundary.
- Do not rely on host Lean metaprogramming, raw IO or arbitrary `partial` functions inside the claimed portable compiler closure.
- Do not modify PSKernel kernel implementation, provider internals, defeq or metatheory in a language-profile migration workstream.
- Do not split the long-term authoritative compiler logic into unrelated `.lean` and `.ps` sources. During transition, preserve old frozen Lean sources until converted; new long-term source should be canonical `.ps` with generated Lean representation and semantic identity.
- Do not weaken V5.1 requirements or source assurance gates simply to obtain a green four-backend matrix.

## 12. Proposed repository structure (design only)

~~~text
PSCV_SELFHOST_PORTABLE.md
psc15selfhost/
  profiles/
    selfhost-portable-v2/
      profile.json
      feature-manifest.json
      standard-environment-lock.json
      runtime-semantics.json
      backend-capabilities.json
      tests/
        syntax/
        elaboration/
        semantics/
        negative/
        runtime/
        bootstrap/
        certification/
      ai-proof-benchmark/
        corpus.json
        scoring.md
  lean4-frontend/
    src/PscvLean/
      Syntax/
      Profile/
      Verify/
      RuntimeBridge/
        LeanCore.lean
        Intrinsics.lean
        Recursors.lean
        Closures.lean
        Erasure.lean
        RuntimeIr.lean
      Certificate/
  packages/
    foundation/       # frozen value/runtime semantics
    syntax/           # owned source parser
    core/             # abstract core and checker interfaces
    environment/
    meta/
    elab/
    compiler-ir/      # typed erased/validated runtime IR
    erasure/
    backend-ts/
    backend-js/
    backend-wasm/
    backend-rust/
    driver-ts/
    driver-js/
    driver-wasm/
    driver-rust/
  docs/
    architecture/
      PORTABLE_RUNTIME_SEMANTICS.md
      LEAN_CORE_BRIDGE.md
      BACKEND_SELFHOST_MATRIX.md
      AI_PROOF_EVALUATION.md
~~~

The tree is an **intended extension**, not an assertion of present files. Keep existing package ownership and V5.1 architecture until a versioned migration is approved. The profile manifest must name exact source/Standard environment/Lean/kernel/backend versions and approved trusted capabilities; no digest is invented in this proposal.

## 13. Concrete migration and feature implementation order

| Phase | Activity | Evidence gate |
|---|---|---|
| M0 | Preserve existing PSC1-stable seed and complete import/fixed-point records | Existing check/guard/fixed-point remains unchanged |
| M1 | Freeze F0 manifest, runtime semantic contracts and exact grammar crosswalk | Complete rule-to-conformance-test mapping; no source/Lean conflict |
| M2 | Build Lean-hosted canonical `.ps` source path, typed state/`do`, finite `for`, explicit errors | Pinned Lean 4.35 elaboration with negative tests and source maps |
| M3 | Add exact Nat/Int/bytes/arrays/maps, closure and total-recursion support | Runtime families pass typed semantics and proof/intrinsic tests |
| M4 | Implement the same F0 features in native PSCV front end and kernel-provider interface | Independent source acceptance and Core correspondence |
| M5 | Extend checked erasure, RuntimeIR validators and specialization; attach the Lean adapter | Target-neutral acceptance, exact dependency and specialization identity |
| M6 | Compile representative whole modules through all four backends | Real target engine and toolchain execution |
| M7 | Migrate compiler source package by package, using explicit specifications | Complete module import closure and differential behavioral parity |
| M8 | Four target executable compiler builds and full 16-cell re-entry | Stage generation, target parity and reproducibility records |
| M9 | Empirical AI proof-performance study, proof library hardening | Independently replayed proof and evidence metrics |
| M10 | Total certification, erasure, checker and backend semantic preservation | PSCV-CERT/ClaimSet gate satisfied; no inflated release claim |

**Migrate in this module order:** portable foundational collections/strings → syntax and parser → typed Core/IR and deterministic serialization → environment/meta/unifier/elaborator → erasure/specialization → backends → bootstrap/host adapters. Preserve ownership of independent kernel/proof and V5.1 execution workstreams.

**No broad blind rewrite:** each coherent family needs module-level contracts, full importer coverage, cross-target runtime replay, performance measurement and a rollback point. A feature family is implemented once in grammar/elaboration/runtime/erasure/backends, not by proliferating individual source-shape repair guards.

**Development vs assurance:** implement useful program behavior and properly typed boundary hooks first where practical. Track and retain unsolved proof/erasure/preservation obligations; never issue an executable with the PSCV verified claim before the required gates close.

## 14. Formal assurance claims that must never be conflated

1. **Parser acceptance:** source derives from exactly the frozen admitted grammar.
2. **Semantic/source fidelity:** elaboration respects pinned names, instance/coercion ordering, Core meaning and approved source behavior.
3. **Kernel logical acceptance:** core declarations and proof terms check against the permitted foundational/axiom dependencies.
4. **Specification coverage:** independently approved property attached to every required executable item; no vacuous self-authored spec.
5. **VC closure:** state/error, termination, call-site pre/post, frame, invariant and ghost obligations checked.
6. **Trust/assumption closure:** all transitive imports and external effects classified; closed means no unapproved boundaries.
7. **Erasure:** ghost/proof removal noninterfering with runtime behavior.
8. **RuntimeIR validity:** types/references/ABI shapes valid before backend entry.
9. **Compilation preservation:** source executable relation maintained through specialization, target IR and generated backend, by theorem or checked correspondence.
10. **Operational correctness:** compiler emitted into target actually runs and exposes correct CLI/API semantics.
11. **Self-host fixed point:** the executable can compile its own complete source and meet declared stage equivalence.
12. **Reproducibility/provenance:** exact toolchain/input/artifact identity, and DDC/independent generation if requested.

Fail closed on any mandatory claim. The same rules apply to AI-generated source, validators, tactics, bytecode producers and metadata. Negative-input robustness includes malformed terms/modules, false proofs, prohibited imported axioms, unresolved types, invalid indices, resource exhaustion and deterministic error reporting. No tests alone grant a proof; no passing fixed point grants compiler preservation.

## 15. Conformance and negative test matrix

The following IDs are proposed future tests, not existing CI:
- `SHP2-LEX-*`: exact UTF-8 tokens, comments, identifiers, malformed byte sequences and source spans.
- `SHP2-PARSE-*`: grammar closure, precedence, completeness, recovery and unsupported syntax rejection.
- `SHP2-ELAB-*`: deterministic names, implicit binders, instances/coercions, unification and elaboration parity.
- `SHP2-ADT-*`: constructors, indexed types, pattern exhaustiveness, polymorphism, immutable closures.
- `SHP2-TOTAL-*`: structural/mutual/well-founded recursion and negative nondecrease/partial cases.
- `SHP2-DO-*`: local scope, assignment, `for`/break/continue/early return and invariant.
- `SHP2-WP-*`: Reader/State/Except frame and state-on-error obligations.
- `SHP2-NUM-*`: Nat/Int, signed/unsigned, overflow, div/mod and Float if admitted.
- `SHP2-UTF8-*`: byte/scalar spans, invalid bytes, builder and canonical serialization.
- `SHP2-COLL-*`: arrays, bounds, ordered map traversal, collisions and deterministic diagnostics.
- `SHP2-IR-*`: typed erasure, malformed/unknown-runtime-type rejection, specialization relation.
- `SHP2-CERT-*`: missing spec, wrong lemma, unproved VC, imported axiom, effect and ghost leak.
- `SHP2-TS/JS/WASM/RUST-*`: actual target output, deep stack, host ABI, external compiler errors.
- `SHP2-BOOT-*`: 16 producer/target combinations, full source closure, fixed-point identity.
- `SHP2-AI-*`: held-out AI proof tasks with exact replay and empirical metrics.

**Acceptance semantics:** every unsupported F0 backend family must reject with an explicit code rather than emitting undefined, a dynamic-eval fallback, silently truncated integer, unchecked foreign shim or blanket "success" result. Fuzzing and differential tests can be produced by untrusted tools; only independently checked semantic outcomes and declared host assumptions can be claimed.

## 16. Risks, tradeoffs and mitigations

| Risk | Mitigation |
|---|---|
| Rich source lowers into enormous verification conditions | Keep effect/ADT primitives small, named local specs and proof benchmarks |
| Lean parser admits unintended extensions | Closed own syntax, exact environment pin, post-elaboration source-fidelity checks |
| Logic totality vs runtime stack/memory | Worklists, real stress tests, explicit resource budgets and typed failure semantics |
| The full compiler depends on host-specific macros/IO | Move host tools outside portable closure; test entire import graph |
| Too many future backend edge cases | Make value semantics target-neutral; exact runtime primitive parity corpus |
| JavaScript numbers and strings differ from PSCV | BigInt/exact ints, UTF-8 byte API, machine-width and Unicode edge tests |
| Wasm host ABI/heap/GC work hidden | Explicit imports, memory model, runtime library and executable re-entry |
| Rust source silently imports unsafe/borrow-specific meaning | Limit unsafe to audited target runtime; logical values remain backend neutral |
| Proof automation is brittle after edits | Small stable VCs, exact theorem dependency snapshots, proof-index metadata |
| AI edits specifications to "prove" bug | Independent immutable approval, axiom audit, kernel checking, no proof authority for AI |
| Rust/Go source simpler than proposed profile | Evaluate with comparable task/proof benchmarks; revisit profile quantitatively |
| Four emitted artifacts mistaken for four self-host compilers | Complete 16-cell matrix and stage2/3 re-entry, not emitter demos |
| Profile migration breaks current self-host work | Separate branch/opt-in profile, frozen seed, rollback and no in-place rewrite |

## 17. Acceptance checklist before adopting as implementation language

- [ ] Approved `PSCV-selfhost-portable/2` source grammar is explicitly reconciled with the existing normative PSCV reference.
- [ ] Exact Lean 4.35 semantic pin and current 4.34 bootstrap differences are documented/checked, not assumed away.
- [ ] Manifest binds Standard environment, allowed library operations, effects, integer/text/runtime semantics and semantic source identity.
- [ ] Every F0 source feature has source/Lean/native PSCV/Core/RuntimeIR/TS/JS/Wasm/Rust mapping and positive/negative tests.
- [ ] The same canonical compiler `.ps` source closure compiles through Lean and native PSCV with independently checked semantic correspondence.
- [ ] Ordinary compiler libraries (array/map/UTF-8, errors, typed state, recursion) have stable reusable contracts.
- [ ] Local mutable state, finite loops and exit conditions produce sound, reasonably sized verification obligations.
- [ ] Unrestricted partial/unsafe/axiom/heap aliases and raw IO cannot enter a closed certified dependency graph.
- [ ] Compiler source closure has explicit host capability boundaries and no hidden Lean-only/metaprogramming dependency.
- [ ] Whole compiler runnable in TypeScript-compiled JS, direct JS, direct Wasm and native Rust.
- [ ] Each of the four generated compilers can compile the same source closure into all four outputs (16 cells).
- [ ] Backend runtime, ABI, stack/resource, errors, determinism and numeric/string conformance tests pass.
- [ ] Stage0/1/2/3 identities, canonical output parity and justified fixed-point equivalence are recorded.
- [ ] Source checking, approved spec coverage, kernel proof closure, erasure, backend preservation and runtime assumptions remain separate acceptance claims.
- [ ] Repeated held-out AI proof benchmarks demonstrate at least proof success non-inferiority with measured uncertainty; no unsupported speedup claim.
- [ ] The existing PSC1 stable seed and independently owned V5.1/PSKernel work are preserved.

## 18. Verdict and next actionable decisions

**Recommendation:** adopt this document as a *research proposal and migration target*; do **not** immediately replace the current successful PSC1 compiler source. Prioritize source-profile conformance, exact portable runtime semantics, and the Lean-hosted parser/effect/recursion bridge before large source refactoring.

**Key design principle:** *the language used to build PSCV must be pleasant enough to maintain and simple enough to model.* It should be possible for an AI to prove the actual compiler in modular steps without recreating the state/control/alias complexity of Rust or Go in the source semantics. Yet over-restricting it to raw structural recursion and handwritten list workers makes the implementation harder to maintain and may move complexity into hidden libraries.

**Outstanding decisions requiring conformance evidence rather than guessing:** precise F0 constructor/record surface and `do` lowering; approved derivative syntax; typed-error state semantics; generics/closure specialization limit; total mutual recursion pattern; exact Nat/Int/string intrinsic runtime contract; Wasm host/GC/ABI model; target-specific proof-preservation evidence; AI proof-performance comparison. These are blocking at the feature-family promotion boundary, not reasons to suspend other compiler implementation work.

## 19. Primary references

1. Lean elaboration/kernel: https://lean-lang.org/doc/reference/latest/Elaboration-and-Compilation/
2. Lean `do` and local mutation: https://lean-lang.org/doc/reference/latest/Functors___-Monads-and--do--Notation/Syntax/
3. Lean total recursion: https://lean-lang.org/doc/reference/latest/Definitions/Recursive-Definitions/
4. Lean tactics and kernel proof terms: https://lean-lang.org/doc/reference/latest/Tactic-Proofs/
5. Lean `grind`: https://lean-lang.org/doc/reference/latest/The--grind--tactic
6. Lean bootstrap: https://github.com/leanprover/lean4/blob/master/doc/dev/bootstrap.md
7. Pinned Lean 4 compiler: https://github.com/leanprover/lean4/tree/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler
8. Rust compiler overview: https://rustc-dev-guide.rust-lang.org/overview.html
9. Rust compiler bootstrap: https://rustc-dev-guide.rust-lang.org/building/bootstrapping/what-bootstrapping-does.html
10. Rust implementation snapshot: https://github.com/rust-lang/rust/tree/36aeef32c6c012e1af17af53a820aac042846c43/compiler
11. Go compiler architecture: https://github.com/golang/go/blob/3b98eddbcd66230a78c4893f32099b5d3045a334/src/cmd/compile/README.md
12. Go self-bootstrap: https://go.dev/doc/install/source
13. Go language spec: https://go.dev/ref/spec
14. CompCert: https://compcert.org/doc/
15. CompCert research: https://compcert.org/research.html
16. CakeML: https://cakeml.org/index.html
17. Dafny invariants and termination: https://dafny.org/dafny/OnlineTutorial/guide
18. Verus verification architecture: https://verus-lang.github.io/verus/guide/
19. WebAssembly core: https://webassembly.github.io/spec/core/bikeshed/
20. TypeScript runtime/type erasure: https://www.typescriptlang.org/docs/handbook/typescript-from-scratch
21. PHP byte-string semantics: https://www.php.net/manual/en/language.types.string.php
22. PSCV language authority: https://github.com/dwijayuda/pskernel/blob/pscv/v3-execution/psc15selfhost/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md
23. PSCV compiler V5.1: https://github.com/dwijayuda/pskernel/blob/pscv/v3-execution/psc15selfhost/THE_PSCV_COMPILER_REFERENCE_VERSION_5.1.md
24. Self-hosting source standard: https://github.com/dwijayuda/pskernel/blob/pscv/v3-execution/psc15selfhost/docs/SELFHOST_SOURCE_STANDARD.md
25. Lean M0 frontend experiment: https://github.com/dwijayuda/pskernel/pull/81

---

**End of Version 2 research proposal. No verified implementation claim is implied.**
