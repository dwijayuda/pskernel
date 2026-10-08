# ProofScript PSCV — Lean-Powered Native Compiler Architecture

**Status:** Researched **target architecture**, NOT an implemented/certified compiler or a change to PSCV normative syntax.
**Design:** **ProofScript `.ps` → thin PSCV frontend written in `.lean` → PSCV verification/certification → Lean native compilation → executable**.
**Normative authority:** [ProofScript PSCV Language Reference RC-v2](../pscv0/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md) (`ps-0.9-r3`, `pscv-v1`, `PSCV-VERIFY-v1`, `PSCV-CERT-v1`).
**Exact Lean semantic/source pin:** **4.35.0-rc3**, Git commit [`470d5ce1400764999581fd26d5d72b00d990b0f4`](https://github.com/leanprover/lean4/tree/470d5ce1400764999581fd26d5d72b00d990b0f4).
**Implementation baseline audited:** [`PSCVL/`](README.md) in `dwijayuda/pskernel` at `main` commit `0f007a8cd30985a20f8517633138d3d86e86e588`, 2026-10-08. Re-fetch remote HEAD before implementing.
**Related work:** [PSCV V6 proposal](../pscv0/THE_PSCV_COMPILER_REFERENCE_VERSION_6.md) is a **separate** compiler-design workstream; adopting this path does not overwrite V6 or kernel-owned code.

> **Architecture decision.** Reuse **as much of the actual Lean implementation as possible**, by importing and invoking its parser, `Syntax`, quotations/macros, elaborator/meta/kernel primitives, inductive and recursion elaboration, `Std.WP`/intrinsic `vcgen`, LCNF, native C emitter, Lake, C runtime and `leanchecker`. Do not copy/fork Lean internals merely to make PSCV appear independent.
>
> **Acceptance decision.** The PSCV language reference is stricter than Lean. Extra native Lean syntax, parser registrations, elaboration guesses, unpinned instances, assumptions and effect models are **not automatically PSCV**. A thin frontend must still implement the **exact observable PSCV rules**.
>
> **Release decision.** No executable artifact claiming PSCV verified status may be emitted until the approved specification, language/environment, proof, totality, effect, dependency, trust, erasure and `PSCV-CERT-v1` gates succeed. Current PSCVL remains **UNCERTIFIED preflight** with **no executable emission**.

## 1. Executive answer — which compiler do we build?

Build a **PSCV-owned language/conformance/assurance shell around the pinned Lean 4 compiler**; never implement a second dependent typechecker or native backend.

| Question | Finding from sources | Decision |
|---|---|---|
| Type system, dependent types, inductives, theorems, kernel | Lean already provides checked dependent declarations and a kernel. | **Reuse Lean**, no independent PSCV type theory/kernel. |
| `const`, `function`, braces, calls, `refine type` | Lean supports owned syntax/macro quotations lowering to ordinary definitions, curried application and `Subtype`. | Build small PSCV-owned syntax/AST/lowering. |
| Contracts, obligations, loops, ghost | Lean 4.35-rc3 has experimental `given`/`requires`/`ensures` expansion into `f.spec`, `vcgen`, `assert`, loop clauses and erased `do` state; `Std.WP` has proved effect laws. | **Reuse/adapt and constrain**. Never treat upstream experimental meaning as PSCV's normative authority. |
| Native executable | Lean compiler uses LCNF and emits C; Lake compiles/modules/links through its toolchain. | **Reuse Lean C backend and Lake**, no first-party PSCV IR optimizer/native emitter. |
| `psc` without user-installed Lean | A Lean program can itself be built as a native CLI; the toolchain supplies compilation/runtime assets. | Ship **a native `psc` CLI plus bundled pinned Lean SDK components**, platform by platform. |
| Exact Standard elaboration | PSCV Chapter 22 specifies `PS-UNIFY-v1`, deterministic instance/default order, bounded coercions; these need not match unrestricted Lean. | **Use Lean primitives**, but add narrow PSCV decision/validation layer; reject when equivalence is unproven. |
| Compiler assurance | Kernel proof checking does not prove C/backend correctness, approved human intent, or world behavior. | Distinguish source proof, replay, compiler preservation, foreign assumptions and provenance. |

This is the **lowest duplication** approach, not necessarily a tiny total implementation: exact PSCV Standard semantics, import identity and certification still require serious new work.

## 2. Research scope and immutable-source evidence

1. Normative basis: Chapters 2 (profiles), 5–10 (source grammar/terms), 18–24 (totality/prover/contracts/elaboration/environment), 28–32 (compatibility/compile gate), Appendix A (owned grammar), Appendix I (pinned source locators), Appendix J (tests), Appendix K (pending manifest).
2. Current local-to-repository implementation: `PSCVL/Main.lean`, `PSCVL/PSCVL/Syntax.lean`, `Grammar.lean`, `Policy.lean`, `Effect.lean`, `lakefile.lean`, [CONFORMANCE.md](CONFORMANCE.md), [NORMATIVE_ALIGNMENT.md](NORMATIVE_ALIGNMENT.md), and the [CI workflow](../.github/workflows/pscvl.yml).
3. Actual Lean 4.35.0-rc3 pinned sources below; **do not substitute a moving `master` or future Lean RC**.
4. Lean official [Elaboration and Compilation](https://lean-lang.org/doc/reference/latest/Elaboration-and-Compilation/), [Build Tools/Distribution](https://lean-lang.org/doc/reference/latest/Build-Tools-and-Distribution/), and [Lake](https://lean-lang.org/doc/reference/latest/Build-Tools-and-Distribution/Lake/) manuals are **informative only** because their `latest` versions may change after the pin.

**Evidence rule:** A verified upstream source API proves only that the facility exists. Its reuse in a new PSCV pipeline is **not** evidence that exact grammar, policy, proof replay, source-to-native semantics, or release packaging already works.

## 3. Pinned Lean 4.35.0-rc3 code-reuse inventory

Each linked source is at immutable Git commit `470d5ce1400764999581fd26d5d72b00d990b0f4`. **Reuse by importing/calling Lean, not copying the files.** Links identify inspected source families and entry points, not promises of compatibility across later releases.

| Reuse target | Exact pinned source / entry point | What PSCVL must still own |
|---|---|---|
| Complete-command parser | [`Lean/Parser/Module.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Parser/Module.lean#L135) (`Parser.parseCommand`) | Frozen source grammar and recursive AST/span validation |
| Terms, patterns, calls, binders | [`Lean/Parser/Term.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Parser/Term.lean); [`Term/Basic.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Parser/Term/Basic.lean#L219) | PSCV comma/call adjacency/strict binder/pattern subset |
| Verified `do` parser | [`Lean/Parser/Do.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Parser/Do.lean#L190-L217) (`doLoopInvariant`, `doLoopDecreasing`, `doFor`) | Braced PSCV `do`, verified control-flow grammar |
| Import-header parser | [`Lean/Elab/Import.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Import.lean#L187) (`parseImports`) | PSCV public imports, module identities, certified graph |
| Syntax quotations/macros | [`Lean/Elab/Macro.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Macro.lean), [`Lean/Elab/Quotation/`](https://github.com/leanprover/lean4/tree/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Quotation) | Finite ProofScript-owned lowering, expanded-tree audit |
| Frontend parse/elaborate | [`Lean/Elab/Frontend.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Frontend.lean#L64-L82) (`processCommand`), [`process`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Frontend.lean#L134-L138), [`runFrontend`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Frontend.lean#L269) | PSCV grammar/profile check BEFORE source elaboration; `process` is **not** native compilation |
| Lean declarations/inductives/structures | [`Lean/Elab/Declaration.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Declaration.lean#L161), [`Inductive.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Inductive.lean), [`Structure.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Structure.lean) | Owned syntax, positivity/totality profile restrictions |
| Lean Meta term elaboration | [`Lean/Elab/Term.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Term.lean) | Deterministic PSCV acceptance and result selection |
| Instance/coercion reference | [`Lean/Meta/SynthInstance.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Meta/SynthInstance.lean); [`Lean/Meta/Coe.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Meta/Coe.lean) | Chapter-22 exact candidate order, `PS-UNIFY-v1`, defaults, bounded coercions |
| Intrinsic contracts | [`Lean/Elab/Tactic/Do/Contract.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Tactic/Do/Contract.lean#L86-L154) (`expandDefContract`: `def` + `f.spec` via `vcgen`) | Approved claims, full clause order, calls, frames, error branches |
| Proof VC generator/specs | [`Lean/Elab/Tactic/Do/VCGen.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Tactic/Do/VCGen.lean), [`Spec.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Tactic/Do/Spec.lean) | Versioned PSCV obligations and checked interpretation |
| Verified do/erased state | [`Lean/Elab/Do/Basic.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Do/Basic.lean#L27-L40), [`Lean/Elab/BuiltinDo/Let.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/BuiltinDo/Let.lean#L103) | PSCV-owned `ghost`, noninterference and `assert` evidence |
| Weakest preconditions | [`Std/WP/Monad/Basic.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Std/WP/Monad/Basic.lean#L30-L44) (`WPMonad` pure/bind laws), [`Instances.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Std/WP/Monad/Instances.lean), [`Sound.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Std/WP/Monad/Sound.lean#L39-L47) | Approved Id/State/Reader/Except effect registry and primitive spec laws |
| Frame and typed exception models | [`Std/WP/Frame.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Std/WP/Frame.lean), [`Std/WP/EStack.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Std/WP/EStack.lean) | Abstract `reads`, `modifies`, `old`, distinct success/error posts |
| Kernel replay | [`src/LeanChecker.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/LeanChecker.lean#L17-L43) (`leanchecker`) | Axiom/effect/spec/claim/approval checks beyond kernel replay |
| Compile checked declarations | [`Lean/Compiler/Main.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/Main.lean#L15-L23) (`Compiler.compile`) | PSCV verified build gate |
| Optimizing Lean IR | [`Lean/Compiler/LCNF/Main.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/Main.lean), [`LCNF.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF.lean) | **Full reuse**: no PSCV IR rewrite |
| Emit native C | [`Lean/Compiler/LCNF/EmitC.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/EmitC.lean#L1174-L1187) (`emitCForDecls`, `emitC`) | **Full reuse**: no PSCV C emitter |
| Lean shell/compiler tooling | [`Lean/Shell.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Shell.lean#L8-L16) | Invoke shipped `lean`, `leanir`, `leanc` as appropriate |
| Module build and native linking | [`src/lake/Lake/Build/Actions.lean`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/lake/Lake/Build/Actions.lean#L29-L65) (`lean -o`, `-c`, `--setup`), [pinned Lake README](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/lake/README.md) | **Full reuse** with a thin certified build adapter |

### 3.1 Subtle source-level findings

- `Lean.Elab.Frontend.process` returns an **environment and diagnostics**. It is not native code generation; PSCVL currently stops there.
- [`expandDefContract`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Tactic/Do/Contract.lean#L86) constructs `f.spec` through `vcgen`, but does not supply approved-spec identity, full API coverage, imported trust closure, or compiler semantics evidence.
- The pinned `experimental.intrinsic` option explicitly says verification syntax is experimental ([source](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Elab/Do/Basic.lean#L27-L32)). PSCV freezes its own `PSCV-VERIFY-v1` meaning; later Lean changes do not silently migrate PSCV.
- [`WPMonad`](https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Std/WP/Monad/Basic.lean#L30-L44) includes checked pure/bind laws, unlike a plain `Monad` instance; external effects still need admitted primitive operation specs.
- `leanchecker` can replay admitted declarations, but alone cannot prove runtime foreign behavior, approved human requirements, complete source grammar, or preservation through native compilation.
- The default native pipeline is Lean **LCNF → C → C toolchain**; LLVM is not a necessary initial PSCV backend.

## 4. Required architectural boundaries

~~~text
PSC V1 LANGUAGE / STANDARD MANIFEST / APPROVED FORMAL SPEC
                          |
                    *.ps UTF-8
                          v
     +------------------------------------------+
     | PSCVL STRICT FRONTEND (.lean)            |
     | lexer, source grammar, owned syntax,     |
     | import graph, exact deterministic choices|
     +-------------------+----------------------+
                         |
                         v
     +------------------------------------------+
     | LEAN 4.35.0-rc3 (REUSE, NOT FORK)        |
     | elaborator, type theory, kernel,         |
     | Std.WP, intrinsic VCGen, recursion       |
     +-------------------+----------------------+
                         |
                         v
     +------------------------------------------+
     | PSCVL VERIFICATION / CERTIFICATION       |
     | approved-spec identity, VCs, axiom/      |
     | dependency/effect/termination/erasure    |
     | closure, kernel replay, PSCV-CERT-v1     |
     +-------------------+----------------------+
                         |
              VerifiedExecutableModule ONLY
                         |
                         v
     +------------------------------------------+
     | EXISTING LEAN NATIVE COMPILER            |
     | LCNF -> C emitter -> leanc/linker/runtime|
     +-------------------+----------------------+
                         |
                         v
       Native executable + scoped assurance report
~~~

**Trust distinction:** The **compiler host** may import broad Lean APIs. **Standard PSCV user source** may use only the frozen manifest and explicitly mapped source grammar. `import Lean` inside the implementation is **not** permission for a user's `.ps` module to extend ProofScript grammar by importing Lean's metaprogramming registries. Treat imported native Lean or world-effect components as explicitly modeled boundaries when permitted.

**One-logic invariant:** The PSCV frontend produces ordinary Lean propositions/checked terms; Lean's pinned kernel is the logical authority. Do not introduce PSCV-native axioms or a shadow typechecker. However, Lean kernel acceptance is not proof of application-spec completeness or native backend correctness.
