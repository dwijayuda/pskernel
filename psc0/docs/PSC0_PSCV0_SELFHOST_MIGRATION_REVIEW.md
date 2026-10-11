# PSC0: PSCV0 adoption and readable self-host migration review

> **Historical planning input:** this review studied an earlier 230,234-byte RC4 design document. The [full v7 reference](../PSCV0_LANGUAGE_REFERENCE.md) now supersedes that *language-design authority* for new work (SHA-256 `843940bd7f6a9b286e80b01d8c891a7e01b8868a9de7b05833fce32d49be6cd5`). The [v7 implementation matrix](PSCV0_V7_ADOPTION_AND_MIGRATION_MATRIX.md) preserves the distinction between design requirements and completed compiler qualification. The older review below remains historical evidence and does not authorize an older language fallback.


**Date:** 2026-10-11. **Status:** static source review, user-selected target and proposed implementation sequence; not executed language conformance or completed migration.
**Inspected source:** `psc0/npm-modular-packages-v1` at `f7b92aa3479cd2c39ce959cab82d69dfb8d969a4`.
**Selected reference:** the user's `Lean4_ProofScript_PSCV0_Lean435rc4_Expanded_Lean_First_Unified_Language_Reference(2).md`, SHA-256 `a419955383fd3e35d873f82c939ecf3a92dc65b162cc9d0d3cadf5b853a0f4b0`, 230234 bytes. See [adoption record](PSCV0_REFERENCE_ADOPTION.json).

## 1. Decision

**Yes: enrich the useful self-host language first, then migrate the compiler to authoritative `.ps`, with a readable source-level `.lean` projection. Do not wait for all PSCV0 features, and do not assume conversion alone repairs verbose algorithms.**

The uploaded PSCV0 document is the new language-design authority. Earlier PSC1/PSC0-SH/1 and ps-0.9-r3 documents describe historical bootstrap/execution capabilities, not the future language ceiling. The new edition requires no backwards-compatible old `.ps` parser mode. Keep exact old seeds and receipts as bootstrapping evidence, not as user-selectable legacy semantics in the new compiler.

The selected document has one Lean-grounded source language and distinct ordinary/verified assurance outcomes. A first implemented compiler-workload subset is a capability manifest, not a second PSCV0 grammar. Unimplemented specified features must be reported as unsupported, not redefined or implicitly supplied by a different parser.

This review does not import the full uploaded original into GitHub. Its exact attachment identity is recorded; the original remains unchanged in the conversation. Before implementation, obtain/retain the full original and verify its digest. This review is an implementation analysis, not a replacement language reference or standalone EBNF.

## 2. What current source shows

| Evidence | Observed capability or limitation |
| --- | --- |
| [CURRENT.md](selfhost-language/CURRENT.md) | `.lean` is still authoritative; new-only ps-0.9-r3 is bounded; generic APIs do not automatically use the strict qualified entry |
| [Syntax/Ast.lean](../packages/syntax/src/Ps/Syntax/Ast.lean) | One match scrutinee; constructor patterns contain binder names, not recursive subpatterns; lambda binders contain explicit types; no native surface nodes for do, record updates or arbitrary-expression projections |
| [Syntax/Translate.lean](../packages/syntax/src/Ps/Syntax/Translate.lean) | Both conversion directions are parser-to-source-printer paths; they are not readability-refactoring passes or semantic verification |
| [Syntax/PrintLean.lean](../packages/syntax/src/Ps/Syntax/PrintLean.lean) | Let sequences are printed with semicolon concatenation; compound function heads can return unsupportedApplication; source printer does not reconstruct do from lowered error matches |
| [Syntax/ParseProofScript.lean](../packages/syntax/src/Ps/Syntax/ParseProofScript.lean) | Own parser and pinned old grammar hash; call adjacency already uses source byte positions; no need to reinvent this distinction as a text regex |
| [Compiler/Api.lean](../packages/compiler/src/Ps/Compiler/Api.lean) | Repeated `Except.error` propagation and nested success continuations; a direct target for bounded Except-do and helper reuse |
| [Foundation/List.lean](../packages/foundation/src/Ps/Foundation/List.lean) | Generic `psListMap`, `psListMapExcept`, append and reverse helpers already exist |
| [Meta/SynthInstance.lean](../packages/meta/src/Ps/Meta/SynthInstance.lean) | Unification/instance-search machinery exists internally; this does NOT establish complete source `class`, `instance` or deriving support |
| [Elab/Recursion.lean](../packages/elab/src/Ps/Elab/Recursion.lean) | Typed normalization for changing parameters already exists; many older returned-function/`smaller` patterns are source history rather than a new required language restriction |
| [Elab/Term.lean](../packages/elab/src/Ps/Elab/Term.lean) | Existing expected-type and unification infrastructure; explicit `emptyCallUnsupported`, `matchExpectedType`, pattern and structural-recursion error boundaries |

The guide explicitly lists general do, default/named arguments, empty-call completion, tuples, nested patterns, arbitrary result projection and broader class/instance source support as unsupported. It already admits annotated const, positive-arity function, adjacent calls, typed grouped lambdas, records, flat matches and some ordinary changing recursive parameters. Do not estimate all of these as new features.

The last whole installed-closure check covered 64 compiler bootstrap modules across 69 source files. It is not a claim that all optional packages, all kernel modules or every current `.lean` file are convertible to PSCV0. This review did not execute a new complete opportunity-count or rewrite benchmark.

## 3. Three distinct improvements

### 3.1 Existing-capability cleanup

Use existing generic helpers before adding a new language feature. For example, PrintLean has several structurally similar recursive traversals that propagate `Except` failures. `psListMapExcept` already supplies that behavior. Candidate replacement must preserve first failure, left-to-right evaluation and type parameters, and must be checked on actual generated output; merely matching text is not enough.

Current recursion normalization permits more ordinary worker arguments than the original stable profile. Rewriting a returned-function worker to explicit parameters can remove scaffolding without adding a new callable model. Preserve complete curried signatures, recursive argument position, zero-fuel outcome, first error and state-update ordering. Public parameter order is not an aesthetic detail.

**Do not delete fuel/resource limits for readability.** They are observable refusal/termination behavior. Distinguish removable adaptation scaffolding from necessary budgets.

### 3.2 Surface formatting and source intent

More attractive calls/braces do not turn nested Except matches into monadic sequencing or remove duplicate traversal algorithms. Source translation should retain high-level intent, declaration identity, comments/docstrings and names. A formatter is not a reverse compiler from JS or erased Core.

The current AST drops distinctions needed by richer formatting (e.g. aliases become ordinary definitions). Preserve the necessary surface nodes/origins until printing; extend them deliberately rather than attempting to guess syntax from arbitrary normalized code.

### 3.3 Small, reusable language additions

The highest-value additions have ordinary Lean-grounded lowerings to already supported constructs. They should be implemented in the portable compiler, not solely as a JavaScript preprocessor or native-Lean-only helper. For each feature, implement PS parsing, native Lean input counterpart where applicable, both source printers, normalization/elaboration, diagnostics and focused conformance together.

## 4. Prioritized feature assessment

Relative costs below are engineering judgments from current source, not measured schedules. Small means mostly a parser/printer/local lowering using existing semantics; medium spans typed elaboration and several traversals; large means new substantial semantic/algorithmic infrastructure. PSCV0's own P0 labels describe its intended baseline, not implementation cost.

| Family | Current basis | Relative incremental cost | Decision |
| --- | --- | --- | --- |
| Generic traversal/helper reuse | Existing Foundation.List and improved changing-parameter normalization | Small; no new grammar | Do immediately as bounded refactoring families after migration baseline planning |
| Multiline, precedence-aware source formatting | Both source printers already exist | Small/medium | First-class part of round-trip migration, including comments and source origins |
| const/function/calls/braces | Partly implemented; positive-arity aliases already accepted | Small for existing aliases, medium for full PSCV0 delta | Correct canonical spellings, argument ownership, new reference identity and forbidden old forms together |
| Empty calls / nullary declarations | Syntax distinguishes empty argument lists but elaborator rejects them | Medium, not just token substitution | Implement exact required-Unit lowering and bounded completion; no guessed arguments or JS zero-arity model |
| Simple Except do | Existing Except data, matches and functions; no do surface | Medium, very high payoff | First major ergonomic feature; simple binds, immutable lets, terminal return and final action |
| Expected-type lambda domains / local matches | Existing expected-type checking and unification | Medium | Omit annotations only where a known expected type determines them; no general inference promise |
| Arbitrary-result structure projections | Named projections exist | Small/medium | Add typed projection after any admitted expression; evaluate base exactly once |
| Nondependent record updates | Construction/field lookup already exist | Medium | Reconstruct typed records from old fields plus replacements; preserve evaluation and dependencies |
| Nat constructor-pattern sugar | Current own source uses successor patterns; PS full pattern family restricted | Small for finite Nat/list cases | Resolve by actual scrutinee type; preserve k+1 descent, reject 1+k, k+m and subtraction patterns |
| if let / matches | Existing flat match | Small/medium for admitted flat patterns | Hygienic pattern bindings and branch scopes; lower into checked match |
| Tuple terms / irrefutable destructuring | Prod type exists, source tuple terms/patterns are not generally supported | Medium | Dedicated argument partition; never confuse f(x,y) with f((x,y)) |
| Nested and multiple matches | Flat pattern/one scrutinee AST today | Medium/large | Nondependent patterns first, one decision-tree lowering with first-match order and coverage |
| Raw strings | String literal machinery exists | Small relative to other features | Delimiter/escape/byte tests; no new kernel or target runtime semantics |
| String interpolation | No general ToString source environment | Medium | Shared PS expression parser inside interpolation; only pinned ToString behavior, not JS coercion |
| Named/default parameters | No source metadata/completion route in current supported subset | Medium | After high-payoff do/projections; declaration-scope defaults and binder identity preserved |
| local where helpers | No complete source-local declaration pipeline | Medium | Later selected typed nonrecursive/local dependency handling; do not silently implement unrestricted local recursion |
| Class/instance and full method notation | Internal meta-instance engine exists | Large for complete source/registry semantics | Useful second wave, not a prerequisite for bounded Except-do |
| deriving | No complete source registration/handler path | Medium/large after prerequisite classes | Repr/BEq candidate handlers before DecidableEq laws; each result checked |
| GetElem proof/Option/panic forms | Arrays/type support is not this complete source contract | Medium/large | Instance/prelude/bounds-proof and target-behavior work; never unchecked JS indexing |
| let mut, loops, early exit, general monadic exceptions | Larger whole-block transformations/effect dependencies | Large compared with simple do | Do not include in first self-host switch |
| Dependent matches, general well-founded recursion | Existing structural subset is deliberately restricted | Large | Separate compiler capability milestone, not a cosmetic migration |
| Contracts, erased state, vcgen | RC4 experimental verifier/effect infrastructure | Large | Later verification lane; keep ordinary/verified output distinct |

Recommended first source-language slice: PSCV0 call/body rules + source printers, Except-do, known-expected-type conveniences, result projections, nondependent record updates and small pattern sugar. Tuples/if-let are a follow-on within the same selected language. Do not gate the initial readable compiler on general classes, all standard APIs, dependent elimination or proof automation.

## 5. Concrete before/after using a real compiler function

Current `Ps.Compiler.Api` implementation:

```lean
def psCompilerElaborateSource
    (sourceKind : PsCompilerSourceKind)
    (source : String) :
    Except PsCompilerError PsElabModuleResult :=
  match psCompilerParseSource sourceKind source with
  | Except.error error =>
      Except.error error
  | Except.ok sourceModule =>
      psCompilerElaborateModule sourceModule
```

Proposed PSCV0 authoring source (not yet tested by PSC0):

```text
function psCompilerElaborateSource(
  sourceKind: PsCompilerSourceKind,
  source: String
): Except PsCompilerError PsElabModuleResult := do {
  let sourceModule ← psCompilerParseSource(sourceKind, source)
  psCompilerElaborateModule(sourceModule)
}
```

Intended readable Lean projection:

```lean
def psCompilerElaborateSource
    (sourceKind : PsCompilerSourceKind) (source : String) :
    Except PsCompilerError PsElabModuleResult := do
  let sourceModule ← psCompilerParseSource sourceKind source
  psCompilerElaborateModule sourceModule
```

This is a source-level projection of the preserved do node. Internally, bounded Except-do can lower to the existing explicit error/success branching. The example needs no catch, mutable state, arbitrary typeclass search or new backend feature. Name hygiene, first-error propagation and action order are required. For this homogenous Except example the semantics correspond to the existing branch structure; a general automatic nested-match-to-do rewrite must additionally reject recovery/error-transforming cases.

A first-class value must remain a value: do NOT rewrite a parameterless `def x : T := t` into `function x(): T := t`, because the PSCV0 nullary form adds a required Unit parameter and changes the type. Use `const x: T := t` or parameterless def instead.

## 6. Readable round-trip architecture

```text
historical authored .lean
        |
        v
candidate portable frontend + reviewed rewrite families
        |
        v
readable PSCV0 .ps  <-->  preserved surface/source representation
        |                            |
        |                            +--> readable native .lean printer
        v
hygienic, typed lowering into existing supported terms
        |
        v
existing elaborator / original-IR checks / independent kernel admission
        |
        v
existing erasure + TypeScript/JavaScript backend
```

Do not make the readable Lean writer consume erased IR or already-normalized nested bind chains. The same enriched source representation drives the PS printer and native Lean printer; the compilation projection may erase sugar without destroying the authoring representation.

Prefer a thin surface layer lowering to existing PsSyntaxTerm/Core forms. Extend normalized forms only when needed for real typing behavior. This limits churn in Recursion, Sh1, erasure and backend visitors. Some transformations need expected-type information and therefore belong in elaboration rather than a context-free parser macro.

For generated readable `.lean` to be part of the *self-host loop*, PSC0's own bounded Lean reader must accept the selected native equivalents too. It is insufficient that only installed native Lean understands the generated file. Printed high-level do/lambdas/updates need corresponding owned-reader support. Native Lean remains an independent comparison lane, not a hidden frontend dependency of the final JS compiler.

Maintain one authoring source after migration: `.ps`. Readable `.lean` is reproducible/generated; old `.lean` bootstrap sources remain at immutable historical commits. Do not maintain two manually edited masters or a third permanent lowered-authoring dialect. Preserve comments and docstrings explicitly or report loss and block authoritative migration; the current lexical AST alone does not preserve all source trivia.

## 7. Package ownership and avoiding language fragmentation

| Responsibility | Existing owner / proposed optional owner | Default or optional |
| --- | --- | --- |
| Lexer, spans, grammar categories, surface AST, PS/native-Lean parser and printers | `@proofscript/syntax` | Required compiler closure |
| Type-directed sugar lowering, expected-type conveniences, match and record elaboration, structural-recursion normalization | `@proofscript/elab`, with `meta` and `environment` | Required for features used to implement compiler |
| Unification and existing typeclass-search machinery | `@proofscript/meta` | Existing core infrastructure; do not duplicate in extension packages |
| Names, imports, selected instances/operators and deterministic registrations | `@proofscript/environment` | Essential environment mechanisms required; additional registries explicitly selected |
| Pi/lambda/application/let/inductive Core representation | `@proofscript/core` | Stable; no new kernel constructors for syntax sugar |
| Pure generic list/result helpers required by compiler | `@proofscript/foundation` | Keep small and inside bootstrap closure |
| Public List/Array/Option/Except API, map/set/JSON libraries | `@proofscript/stdlib` or later independent application packages | Optional unless exact foundational declarations are required by compiler; no forced stdlib dependency for prettier syntax |
| Proof-term checking | `@proofscript/pskernel-core` | Independent authority; no tactics or parser extensions inside kernel |
| Minimal goal construction/control | Later proposed `@proofscript/tactics-basic` | Optional module/package; names are proposals, not existing implementations |
| Simplification/rewrite engines, omega, grind | Later selected tactic packages/modules | Optional; do not port full automation just to migrate compiler source |
| deriving handlers | Initially reviewed modules over elab/meta; later optional `@proofscript/derive` | Syntax head and handler registry separate from generated declarations; no unchecked JS handler execution |
| Contracts/VC generation/effect models | Later proposed verification package(s) + shared elaboration hooks | Separate from ordinary compiler authoring requirement |
| Semantic IR, erasure, target emission | `compiler-ir`, `erasure`, `backend-ts` | Reuse existing target for surface-only improvements; changes require target evidence |
| Migration/format command and npm IO | Thin CLI adapter calling portable compiler API | No JavaScript-only implementation of a self-host language feature |

Core has three meanings that must not be conflated: logical kernel, essential compiler mechanisms, and installed npm dependency closure. `do` syntax belongs in compiler frontend support but not in the proof kernel. `Except` operations are data/library semantics. Omega is proof construction, never proof authority.

All ordinary PSCV0 term contexts share one grammar, including tactic arguments, strings, types and diagnostics. Optional packages select defined handlers or APIs; they do not create package-local interpretations of calls or silently enable new parser syntax through an ordinary import. Current source-only library support does not yet authorize executable plugins; keep future extension execution behind the pending secure guest boundary.

No new npm dependencies or tactic packages are created in this review. Prefer adding a module to an existing owner over proliferating tiny packages. If a feature is used in the compiler implementation, its implementation and exact helper dependencies must join the measured self-host closure; it cannot be supplied only by an optional external tool.

## 8. Transition and qualification sequence

### M0 — Adopt target and resolve reference ambiguities

Pin exact uploaded bytes and RC4 source revision. Keep old qualification labels as historical facts. Create one capability manifest for the intended PSCV0 compiler-workload subset. Label proposed, implemented and qualified separately. Before code changes, record a small errata decision where the reference contradicts itself; do not import unrestricted Lean as a fallback.

### M1 — Build a bridge compiler, still bootstrappable

Implement the new portable parser/lowering/printer support in source that the existing seed can compile. The *implementation source used to build the bridge* may temporarily use the old bounded `.lean` constructs; that is not backwards compatibility offered to new `.ps` users. Do not write the compiler in a feature before its predecessor can compile that feature's implementation.

Develop one coherent feature family at a time, covering both source readers/printers and all affected walkers. A new syntax node can affect source span utilities, structural-recursion normalization, Sh1 admission constraints, quotation/printing and host grammar identities. Audit these owners, not only the test currently failing.

### M2 — Qualify bridge behavior, then refactor compiler source

Use small positive/negative and differential RC4 fixtures. Include duplicate binders, capture, first-error behavior, evaluation order, malformed branches, record dependency errors, tuple argument partition and illegal gap calls. Check expected canonical Core/IR where applicable, not just that two source files typecheck.

Then migrate a representative group (Compiler.Api, one printer/traversal, one elaboration worker), followed by mechanically reviewable families through the 64-module closure. First prove the feature implementation is executable by a generated compiler; only then let compiler source depend on it.

### M3 — Change source authority to PSCV0 `.ps`

Migrate the source manifest, import-closure selection, CLI grammar check, cache/snapshot identities, strict capability entry, all current fixtures and source printers atomically to the new candidate identity. New `.ps` output and input have one PSCV0 edition; no old PS parser branch or configuration fallback. The frozen old seed remains historical recovery evidence.

Generate pretty `.lean` from the retained rich source representation. Feed it back through the owned Lean reader and compare meaningful normalized declarations/types/effects and generated behavior. Byte equality with the original ugly source is neither required nor desirable. Where lowering changes normal forms, use explicit correspondence arguments/proofs and bounded behavior tests; two successful kernel checks alone do not establish semantic equivalence.

### M4 — Deliberate compiler-only promotion

Routine edits: small cached/incremental cloud builds, changed-feature fixtures and whole-closure parse/coverage; retain existing host tests. No new kernel build, repeated full source retranslation across optional packages or full C2/C3 after every edit.

At a stable candidate, perform a deliberate compiler-only self-host qualification and readable PS/Lean round-trip check. The newly generated compiler must consume the full new authoritative source and reproduce the declared fixed-point artifacts. Then explicitly select the new authoring seed with source/runtime provenance and recovery instructions.

**Important:** the current fast guard relies on exact identity with 69 old files. It cannot honestly qualify changed language/compiler source by itself. Preserve its existing historical lane and introduce the new feature/promotion lane; do not silently loosen the baseline, rename an old receipt or claim unchanged-code inheritance after a source migration. A limited static audit is useful early but not a replacement for the final self-host check.

## 9. RC4 target versus current 4.34 execution

The selected reference pins Lean `v4.35.0-rc4`, commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`. The existing npm seed and checker are Lean-4.34-based. Adopting the design does not prove them RC4 conformant.

For early ergonomics, select ordinary term/inductive transformations whose acceptance can be checked by the retained provider AND whose intended meaning is tested against RC4. Record this as a restricted migration candidate with explicit compatibility evidence, not full RC4 support. Exact instance, primitive, array and experimental verification changes must not be silently backported or assumed identical.

Coordinate a separately qualified kernel/provider/prelude upgrade when RC4-specific features need it. Do not modify the kernel workstream here. Do not rewrite the entire PSC0 architecture into the separate Lean-fork frontend project simply because the language specification is Lean-first: this repository's standalone self-host frontend still needs portable implementations of selected syntax/elaboration.

## 10. Reference issues discovered, not silently corrected

1. The dedicated trailing `deriving` adoption sections (including the initial allowlist) conflict with the older attributes paragraph still listing deriving as excluded. Recommended erratum: trailing allowlisted deriving is selected; arbitrary deriving-handler registration remains excluded. This is an explicit review recommendation, not a claim the source document is internally uniform.
2. Some illustrative dependent applications such as `Vec α (n + 1)` contradict the no-gap-parenthesized-application rule when read as ordinary `.ps` type terms. Use an allowed adjacent grouping such as `Vec(α, n + 1)` in the example; preserve `.lean` spelling in its Lean column.
3. C-style comments in a few negative call examples do not isolate the intended adjacency rule under the document's Lean comment lexer. Test valid Lean trivia, e.g. `f /- gap -/ (x)`, and require the appropriate adjacency diagnostic rather than a generic lexer rejection.
4. The detailed exactly-one-required-Unit completion rule admits `useUnit()` for `function useUnit(u: Unit)`. Earlier prose suggesting only `useUnit(())` is permitted needs alignment. Never implement first-class nullary functions as a separate JS arity model.

The reference explicitly leaves some exact parser/handler forms pending, including selected equation-style syntax and monadic catch/finally mappings. Do not fill those gaps with invented grammar or unpinned APIs. Closed-environment manifests and exact Lean source locators remain required.

## 11. Completion criteria and nonclaims

The migration is complete only when the selected new source subset is implemented by the portable compiler, the full compiler source is authoritative readable `.ps`, emitted readable `.lean` is accepted by the owned reader, actual checking and target behavior pass the declared correspondence gates, and a new compiler-only self-host checkpoint is recorded. Public runtime claims must match the new grammar and supported capabilities.

This review changes documentation and future design authority only. No parser, elaborator, kernel, compiler source, npm dependencies, seed, runtime, output package or test baseline changed. No new language fixtures, code generation, C2/C3 cycle, kernel build or npm publication was executed. All examples above are proposed code, except the explicitly quoted original source.

## 12. Sources

Primary task source: exact uploaded PSCV0 document identified above, especially §§0A,2–6,7B,8A,11–14. It is a design reference, not existing implementation evidence.

Repository source links in §2 are pinned for this review at `f7b92aa3479cd2c39ce959cab82d69dfb8d969a4`; moving relative links are convenient navigation, not a different inspected commit. Current strict SH/1 and host qualification retain their original exact-source scope.

External explanatory primary sources inspected:
- [Lean function application](https://lean-lang.org/doc/reference/latest/Terms/Function-Application/): curried semantics, typed binder/default insertion and generalized field notation.
- [Lean pattern matching](https://lean-lang.org/doc/reference/latest/Terms/Pattern-Matching/): patterns, coverage, dependent matching and constructor lowerings.
- [Lean do notation](https://lean-lang.org/doc/reference/latest/Functors___-Monads-and--do--Notation/Syntax/): local bind translation versus whole-block mutable/early-return transformations.
- [Lean deriving](https://lean-lang.org/doc/reference/latest/Type-Classes/Deriving-Instances/): handler-generated instances rather than a new logical rule.
- [Lean elaboration and compilation](https://lean-lang.org/doc/reference/latest/Elaboration-and-Compilation/): separation of syntax, elaboration, checked terms and executable lowering.
- [Lean custom tactics](https://lean-lang.org/doc/reference/latest/Tactic-Proofs/Custom-Tactics/): proof-producing elaboration does not make an implementation a new kernel authority.
- [Lean RC4 release notes](https://lean-lang.org/doc/reference/latest/releases/v4.35.0/): experimental intrinsic verification and version-sensitive elaboration changes.

These moving explanatory pages do not replace the reference's immutable upstream source pin. Implementation cost categories and sequencing are this review's engineering judgments, not claims made by the uploaded reference or upstream Lean.
