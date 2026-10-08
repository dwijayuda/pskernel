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


## 5. Proposed small PSCVL codebase (do not manufacture empty modules)

~~~text
pskernel/
  PSCVL/
    Main.lean                             # psc CLI; strict check/verify/build
    PSCVL.lean                            # trusted compiler library entry
    lakefile.lean
    lean-toolchain                        # leanprover/lean4:v4.35.0-rc3
    PSCVL/
      Source/
        Lexical.lean                      # strict UTF-8, CRLF, tab, spans
        Grammar.lean                      # owned Appendix A AST validation
        ProofGrammar.lean                 # Chapter 20 tactic whitelist
        Modules.lean                      # module identities/import graph
      Syntax/
        Decl.lean                         # const/function/inductive/structure
        Term.lean                         # call/tuple/record/if/match
        VerifiedDo.lean                   # local mut, loops, ghost
        Contract.lean                     # given/requires/ensures/errors/frames
      Elab/
        Lower.lean                        # owned Syntax -> Lean Syntax
        StandardEnv.lean                  # frozen registry/option identity
        Deterministic.lean                # name/unification/instances/coercions
      Verify/
        VC.lean                           # pinned vcgen adapter, call obligations
        Effects.lean                      # frozen Id/State/Reader/Except WP laws
        Frame.lean                        # old/reads/modifies logical model
        Erasure.lean                      # proof/ghost noninterference
      Assurance/
        SpecIdentity.lean                 # approved formal claims/digest
        Closure.lean                      # imports, axioms, runtime, effects
        Certificate.lean                  # accepted PSCV-CERT-v1
        Gate.lean                         # the ONLY verified emission authority
      Native/
        BuildPlan.lean                    # content-addressed generated Lean
        LeanDriver.lean                   # existing Lean/Lake build pipeline
        Publish.lean                      # check/publish atomically
      Distribution/
        Toolchain.lean                    # bundled pinned Lean SDK paths
    tests/
      grammar/
      elaboration/
      verification/
      assurance/
      native/
      release/
    manifests/
      STD-ENV-PSCV-V1-L435RC3-RC1.json   # PENDING normative freeze
      verification-registry.json          # PENDING normative freeze
    README.md
    CONFORMANCE.md
    NORMATIVE_ALIGNMENT.md
    PROOFSCRIPT_PSCV_LEAN_POWERED_NATIVE_COMPILER_ARCHITECTURE.md
~~~

These are **logical ownership boundaries**, not a command to create two dozen files now. Prefer a small set of cohesive `.lean` modules until feature families grow. Refactor the existing `Syntax.lean`, `Grammar.lean`, `Effect.lean` and `Policy.lean` incrementally rather than replacing proven working code unnecessarily.

**Minimal-core responsibility division:**

- `Source/Syntax` owns only source acceptance and canonical syntax lowering; does **not** contain native linker calls or certificate shortcuts.
- `Elab` delegates typechecking to Lean but owns the *observable* PSCV choices that Lean's default elaborator does not reproduce.
- `Verify` reuses checked Lean/`Std.WP` lemmas and pinned proof-producing algorithms; does not introduce a second type theory or unchecked solver oracle.
- `Assurance` owns immutable approval, specification coverage and closure; the verified token cannot be synthesized from a Boolean annotation.
- `Native` wraps the existing Lean/Lake backend and **cannot accept** raw source or uncertified Lean declarations as an alternative entry.
- `Distribution` bundles official binary/toolchain assets, rather than reimplementing their C/runtime/compiler features.

## 6. End-to-end data flow — exact stages and stop points

| Stage | Implementation owner | Input → output | Mandatory rejection/claim |
|---|---|---|---|
| P0 | PSCVL lexical gate | original UTF-8 bytes → normalized tokens/spans | Reject invalid UTF-8, nonpermitted BOM/CR/tabs, unclosed tokens. Do not accept a *lossy*-decoded source. |
| P1 | PSCVL module layer + Lean import infrastructure | `.ps` paths/import headers → deterministic logical module DAG | Reject ambiguous `Foo.ps`/`Foo.lean`, cycles, invalid `public import`, unapproved imported environments. |
| P2 | PSCVL Standard environment | exact pin/manifest/assurance policy → frozen context identity | Reject absent/mismatched registries. No ambient notation/simp/ext/grind/parser registration. |
| P3 | Lean parser + PSCVL recursive gate | tokens → **accepted owned PSCV AST** | Require complete `SourceFile → EOF`. Reject all unlisted nested term/tactic/do nodes **before elaboration**. |
| P4 | PSCVL owned lowering + Lean quotations | approved PSCV AST → generated Lean Syntax + source map | Only finite, versioned expansion rules. Audit output AST and declaration identity. |
| P5 | Lean elaborator/kernel + PSCV deterministic layer | Lean Syntax → checked core declarations | Enforce `PS-UNIFY-v1`, lookup/instance/default/coercion behavior, totality, options and visibility. |
| P6 | Lean `Std.WP`/VCGen + PSCV Verify | checked code and approved claims → exact obligations and checked proof evidence | Reject unresolved goals, hidden axiom/proof holes, unverified callees or incorrect effect models. |
| P7 | Lean module machinery (non-executable only) | checked declarations → optional `.olean`/index files | These are **not** `PSCV-CERT-v1` and must not be interpreted as executable emission. |
| P8 | PSCVL assurance + optional `leanchecker` | approved spec + local/imported checked proof + exec closure → accepted certificate | Reject missing approval, stale evidence, unsafe/partial/noncomputable/IO/FFI closure, ghost leak, bad import. |
| P9 | PSCVL Gate | accepted `PSCV-CERT-v1` → internal `VerifiedExecutableModule` | **Only** constructor of certified native-emission authority. No unchecked source/`Environment` bypass. |
| P10 | Lean/Lake native compiler | certified generated module → LCNF → C → objects → native binary | Pin executable toolchain; capture compiler assurance and provenance; reject failures. |
| P11 | PSCVL release adapter | validated binary + assurance report → published artifact | Atomic publish; never release partial/failed verified output. |

### 6.1 Resolve the alleged certification “chicken-and-egg” correctly

Elaborating checked Lean **proof/module artifacts** may happen before the full PSCV certificate. The language reference allows parsing, elaboration, proof-obligation generation, checking, and non-executable metadata while obligations remain open. **Native C/object/executable generation must not start before the mandatory certified handoff**.

Therefore:
1. Parse/normalize `.ps` and lower deterministically in-memory.
2. Construct checking-only Lean modules and any `.olean` needed for trusted replay/import composition; verify their identity before use.
3. Produce `PSCV-CERT-v1` only after all gates pass.
4. Then invoke Lean's native code emitter on the **same identity-bound generated code**.
5. Keep outputs staged; publish only when compiler and provenance checks finish successfully.

Generated `.lean` is a reproducible build intermediate; **ProofScript `.ps` plus approved specification remains authoritative**.

### 6.2 Pseudocode for a non-bypassable API (design, NOT existing Lean definitions)

~~~lean
-- Conceptual; replace placeholders with concrete, kernel-backed types.
structure ParsedPSCV where
  ownedSyntax : OwnedPSCVSyntax
  sourceIdentity : SourceIdentity

structure ElaboratedPSCV where
  declarations : CheckedLeanDeclarations
  obligations : Array CanonicalObligation
  environmentIdentity : EnvironmentIdentity

-- Constructor should be inaccessible to arbitrary callers.
structure VerifiedExecutableModule where
  certificate : AcceptedPSCVv1Certificate
  validatedCodegenInput : CanonicalLeanLoweringIdentity

def certify :
  ElaboratedPSCV →
  ApprovedSpecification →
  CheckedEvidence →
  AssurancePolicy →
  Except VerificationFailure VerifiedExecutableModule

-- Only this typed state enters code generation:
def compileNative :
  VerifiedExecutableModule →
  BundledLeanToolchain →
  TargetPlatform →
  IO (Except NativeBuildFailure NativeArtifact)
~~~

A client must **not** be able to construct `VerifiedExecutableModule` from a self-asserted `verified=true`, from a successful `check`, or from an arbitrary Lean `Environment`. Use private constructors and a checked composition root; serialization cannot bypass replay.

## 7. Source-language design — maximum parsing reuse, exact PSCV acceptance

### 7.1 Use existing Lean parser infrastructure, not unrestricted Lean language

Reuse `Lean.Parser.Module.parseCommand`, the mapped `Lean.Parser.Term` token/category families, syntax-tree source spans, `TSyntax` quotations and Lean's existing term parser primitives. The PSCV parser accepts *only* the union of:

1. **Appendix A** owned productions for the Standard/PSCV profile;
2. exact source-compatible **Appendix I** Lean families **with their narrower PSCV restrictions**;
3. finite **Chapter 20.2 StandardTactic** grammar.

Arbitrary Lean source syntax/macros/attributes/notational extensions are **not** automatically permitted because their code exists or because `import Lean` succeeded in the trusted compiler.

### 7.2 Exact difficult cases; these require explicit tests

| Family | Normative behavior | Why a Lean-only frontend is insufficient |
|---|---|---|
| Lexer | UTF-8, one optional BOM, CRLF/LF, reject forbidden lone CR or TAB, byte-accurate source positions | Lean's shell intentionally exposes a lossy UTF-8 decoder; PSCV must reject malformed source instead. |
| Calls | `f(x,y)` is two arguments; `f (x,y)` is one tuple; `f((x,y))` one grouped tuple; adjacency is token/source-position based | Native Lean whitespace application has different ownership than PSCV's postfix multi-argument form. |
| Empty call/parameters | `f()` invokes omitted default/automatic binders; `f(())` supplies explicit Unit; `function f()` uses specified optional Unit sugar | Not JavaScript zero-arity, not a universal unit parameter for all calls. |
| Binders | comma-oriented explicit `(x:A, y:B,)`; `{x:A}`, strict `{{x:A}}`, instance `[C α]`; defaults elaborated in definition's scope | Lean's broad binder language and default elaboration must not silently add spellings or different scoping. |
| Named calls | positional prefix followed by named suffix, no duplicate/unknown names, exact telescope binding | Some Lean application choices or implicit insertion paths may not match Chapter 22. |
| Braced body/if | `:= { PSTerm }` is exactly **one term**, not sequencing; `if (c) {a} else {b}` has no truthiness | Lean has other conditionals/layouts; PSCV must own the source shape. |
| Struct/class vs records | Structure/class declaration fields are newline/layout, records/updates are comma-oriented | A universal comma/semicolon replacement is incorrect. |
| Instance/where/do/proofs | Internal sequences are newline-only in Standard; no general semicolon | Native Lean supports extra separator syntax and tactic semicolon composition. |
| Pattern/match | Single-scrutinee bounded braced `match` with specified patterns and exhaustiveness | Lean's full equation/motive/pattern compiler is larger than the admitted PSCV source subset. |
| Verified `do` | Braced `do { ... }`, mutable locals, `ghost`, `assert`, `for` and `while` with specified VCs | Lean has more control-flow syntax, including `repeat` and multiple-stream `for` syntax. |
| Tactics | Exactly Chapter 20.2 heads/argument shapes; no bullets/`case`/tactic configs/`at`/unlisted macros | Lean's tactic registry is extensible and many syntax variants share the same broad node family. |
| `import`/`public import` | Header only, no cycles, deterministic registry propagation, certified dependencies | Arbitrary imports can mutate Lean parser/tactic/attribute registries and break closed Standard semantics. |

**Implementation pattern:** source bytes → controlled parse → **recursive positive typed AST validation**, not just keyword bans → typed owned lowering → expanded/lowered tree validation → Lean elaboration. An AST kind that is not on the finite allowed list must reject even inside an otherwise admitted `def`/`theorem`. A scanner must retain token adjacency/indentation; plain text regex alone is not enough.

**Current gap:** `PSCVL/PSCVL/Grammar.lean` has a bounded command whitelist and partial recursive denylists; this is not yet Appendix-A complete. Current native Lean syntax quirks that only pass `check-preview` are **never** conformance evidence.

## 8. Deterministic elaboration — the large unavoidable PSCV-owned responsibility

The reference specifies **`PS-UNIFY-v1`** and precise observable source meaning (Chapter 22); Lean's default elaborator is much broader. Kernel acceptance guarantees core typing, **not** that the elaborator selected the intended source-level instance, default, coercion chain or identifier.

**Maximal reuse strategy:**

- Use Lean's native `Expr`, `Level`, `MetaM`, `MVarId`, local contexts, WHNF/defeq, checked kernel terms, and ordinary declaration/inductive compilation; do not implement dependent type theory.
- For family **A**, if native Lean is shown to produce exactly the PSCV outcome/meaning under the frozen environment, invoke it directly.
- For family **B**, use Lean lower-level metavariable/defeq primitives with a *small deterministic PSCV wrapper*: FIFO constraints, occurs/local-context checks, pattern-only metavariable assignment, no uncontrolled higher-order imitation; first eligible ordered instance; one-hop coercion; explicit final default-instance phase.
- For family **C**, lower PSCV-owned syntax to already understood Lean terms after the proper PSCV source-specific rule checks.

Important normative details to enforce:
1. Local instance candidates are lexically prioritized; later same-scope candidates precede earlier ones.
2. Global/imported instances use priority, module order, and the specified depth-first `ImportLinearization`, not hash iteration or installation order.
3. Source default values are elaborated in the **declaration's preceding-parameter scope** and instantiated at calls, never parsed again in caller scope.
4. `PS-UNIFY-v1` is a FIFO constraint algorithm with narrowly admitted pattern assignments and fixed postponement behavior, not full Lean higher-order search.
5. `CoeT`, `CoeFun`, and `CoeSort` are bounded; Standard `autoLift=false` and no uncontrolled chains.
6. Fixed Standard options, initial notation, simp/default/instance/coercion/grind/ext registries must come from the **generated and frozen manifest**.
7. Resource exhaustion/ambiguous resolution fails explicitly, not semantic success or fallback to raw Lean.

**Implementation-cost conclusion:** First prove/test how much native Lean behavior already matches a closed PSCV environment; write custom logic only for observed normative divergences. But a wrapper that merely rechecks final Lean type correctness is **not** enough for differences in source-observable elaboration choices.

**Release blocker:** `STD-ENV-PSCV-V1-L435RC3-RC1.json` and the PSCV verification-registry snapshot/digests are marked **PENDING** in Normative RC-v2. They must be generated, provenance-validated, hashed and frozen. Do not invent those hashes or claim final Standard conformance before that work.
