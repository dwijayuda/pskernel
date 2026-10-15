# Lean 4 ↔ ProofScript `pscv0` — Language Reference v7.1 (Stable Lean 4.35.0)

**Status:** **PSCV0 language reference v7.1 — normative design target, not demonstrated complete compiler conformance.** One source language and distinct ordinary/verified assurance outcomes; new policy for `partial`, `partial_fixpoint`, verified divergent loops and tightly controlled `unsafe` boundaries. **Lean pin:** [stable v4.35.0](https://github.com/leanprover/lean4/releases/tag/v4.35.0), commit [`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`](https://github.com/leanprover/lean4/commit/eb6cafb7290e8bd5f2937522d8d804f58f02bafc). **Revision:** v7.1, 2026-10-16. The original v7 remains an immutable historical predecessor. Any features described as staged remain unimplemented design targets until pinned-source conformance and independent proof evidence exist.

**Authoritative stable pin (v7.1).** All **normative Lean semantics, parser references, elaboration, generated proof terms and runtime evidence** target stable **Lean 4.35.0**, commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`, superseding the earlier v7 RC4 research pin. Compare the exact upstream source and tests when implementing each feature. Historical references to RC3/RC4 and the 2026-10-11 audits describe document provenance, **not an alternative active toolchain**. The repository's earlier pin-migration evidence is in [`docs/PSCV0_LEAN_435_PIN_2026-10-14.md`](docs/PSCV0_LEAN_435_PIN_2026-10-14.md). Verification of a pinned release is not proof of compiler conformance.

**Source provenance:** This revision derives the ProofScript feature choices from the uploaded *ProofScript PSCV Language Reference NORMATIVE RC-v2 (Lean 4.35.0-rc3)* and the preceding side-by-side `pscv0` document. **New decisions** in this edition (nullary function lowering, command adoption, type catalog, parser safeguards, native `Nat` successor pattern admission, Lean section-variable fidelity, and IDE parity goals) are marked as proposals rather than silently attributed to that earlier RC. The *actual* Lean syntax/semantics pin for the revised language is 4.35.0.

**Consistency erratum (2026-10-11; source specification, not implementation evidence).** This version resolves four discrepancies without changing the intended Lean-semantic design: **(E1)** `PSCV0-DERIVE-01` permits an allowlisted trailing `deriving` clause but not arbitrary deriving handlers or the standalone deriving command; **(E2)** `.ps` dependent applications use adjacency-safe spelling such as `Vec(α, n + 1)`, while the Lean column retains native `Vec α (n + 1)`; **(E3)** both `useUnit()` and `useUnit(())` are admitted under the narrowly specified exactly-one-required-`Unit` rule; **(E4)** application-gap tests use Lean comments `/- ... -/`, distinguishing adjacency diagnostics from invalid C-style comment lexing. Corresponding grammar tables, explanatory prose, acceptance fixtures, and expected failure phases are aligned below. Section 13 remains a *proposed* test corpus; no tests are claimed to have executed.

**Historical audit provenance (v7).** The October 11 F01–F22 and C01–C05 consistency reviews are retained as historical research. The former RC4 pin was superseded by stable Lean 4.35.0 on October 14. **v7.1 adds a further normative amendment** for partial recursion, partial fixpoints, divergence-sensitive proof obligations, and controlled unsafe runtime boundaries. Historical v7 test expectations that contradict explicit v7.1 rules are revised in the normative conformance tables (§§13–14); they are not active acceptance criteria.

> **Design identity — precise subset statement.** **ProofScript `pscv0` is designed as a *semantic subset of Lean 4*, with a small owned application-friendly surface syntax.** Every admitted `pscv0` form must elaborate/desugar to ordinary well-typed Lean terms, declarations, proof terms or Lean-grounded verified-effect/library specifications. ProofScript is **not a character-for-character subset of Lean's source grammar**: `function`, `const`, comma-argument calls `f(x, y)`, and braced control forms are intentional surface modifications; Lean-native `erased`, `Subtype`, proof bullets, and quantifiers are retained unchanged. They do **not** define a second type theory or proof kernel.
>
> **Assurance interpretation (v7.1).** All source definitions and proof terms require Lean-grounded type checking and an approved assumption environment. A **verified** executable requires full discharge of **its mandatory specification, divergence/termination, effects, implementation-refinement, erasure and dependency obligations before any output**; the compiler must fail closed rather than silently issue an ordinary artifact. An **ordinary checked** executable may be explicitly requested and uses the same source grammar, but is not behaviorally certified. `partial` and qualified `unsafe` are therefore source-admissible only within the specified profiles and proof/assurance gates. Source/user axioms and emitted proof holes remain prohibited. Theorems about an opaque partial declaration are never themselves evidence about the behavior of its compiled body.
>
> **Scope.** Language features, syntax, grammar, examples, and the static meaning necessary to distinguish valid source. Excludes implementation architecture, CLI, package formats, release gates, build certificates, deployment and AI work management. The original uploaded release candidate retains its historical identities; the new name **`pscv0` is the user's proposed revision**, not an upstream Lean edition or an assertion that a compiler implements it.
>
> **Grammar policy (revised).** **Lean 4 grammar is the one grammar model used throughout this document.** Both comparison columns now use Lean’s grammar-reference categories and *schematic* syntax (`command`, `term`, `binder`, `tactic`, `doSeqItem`, `structField`, `structInstField`). A `pscv0` syntax rule is presented only as a **Lean grammar selection, restriction, or punctuation/layout transformation**. This **discontinues** the previous separately specified ProofScript EBNF model: the new document references Lean syntax categories and states only `pscv0` surface deltas. It retains a finite *selection* of Lean features without claiming the full Lean language is accepted. Lean’s actual parser-combinator declarations at the pinned commit—not a reconstructed standalone EBNF—define the upstream categories. ProofScript’s new tokens are not natively accepted by Lean until transformed; examples are design illustrations unless explicitly tested.

## v7.1 normative amendment — priority and proof-before-emission rule

**Normative priority.** Sections 0A–0B, §§5, 7/7B, 13 and 14 as revised below are the active v7.1 rules. Dated v7/RC3/RC4 retrospective errata are historical evidence only. Any legacy sentence prescribing blanket rejection of every `partial` or `unsafe` declaration, or universal termination of a program whose approved specification permits divergence, is superseded by the explicit rules here. A previously banned form is **not automatically executable or verified** merely because the parser admits it.

**Default safety stance.** A build requesting PSCV verified assurance is *fail-closed*: if any mandatory proof, partial-correctness/safety/liveness obligation, effect or runtime correspondence proof, approved assumption, erasure check, source-semantic preservation requirement, or backend admission check is missing, **emit no executable artifact**. No ordinary-output fallback is permitted. A separate **explicitly selected** ordinary checked build is still possible under the language's retained two-assurance design, but it must not be branded as verified. Project configurations may impose stronger closed-world rules.

**Three different claims must not be conflated:** (1) *type correctness* means well-typed terms and proof declarations relative to an audited kernel environment; (2) *partial correctness* means a result satisfies a specification if the operation terminates normally, and by itself proves nothing about responsiveness; (3) *total correctness* additionally establishes required termination. For a server or reactive loop with potentially unbounded lifetime, verified *safety over finite traces*, and any separately promised progress/fairness properties, are required; a vacuous postcondition on nontermination is insufficient.

**Untrusted runtime boundary.** Logical equality of a Lean function and its specification is **not automatically** a proof that emitted JS/Wasm/Rust or a foreign/`unsafe` implementation realizes that function. An artifact claiming **closed end-to-end verification** requires a proof that the relevant target behavior refines the approved logical/operational model, including failure and divergence behavior as applicable. Where external behavior is assumed rather than proved, use a distinct **boundary-qualified** assurance identity with immutable named assumptions, never a closed-verified identity. All assurance gates track transitive dependencies; `sorry`, `sorryAx`, unresolved metavariables and forbidden source `axiom` declarations remain blockers.

**Staging.** `partial def` and `partial function` are P0 *ordinary* source-admission goals, while executable certification of an arbitrary `partial` body requires a checked operational/refinement model and is separately gated. `partial_fixpoint` is P1 and must reuse the pinned Lean 4.35.0 kernel-checked fixed-point construction. Unsafe boundaries and invariant-only potentially divergent loops are staged until a sound typed/runtime model and proof rule exist. These are language requirements, **not claims that the present PSC0 compiler already passes them**.

**Version semantics.** This is a **complete standalone v7.1 reference derived from v7**, not a patch to be layered over v7 or a change to `.lean` syntax. Only `.ps` source is subject to PSCV0-specific source restrictions; imported/host `.lean` code keeps Lean's normal grammar but does not receive trusted verification status merely by existing.

## Executive syntax map — one rule per ambiguity

**Design rule:** follow pinned Lean 4.35.0 unless ProofScript syntax delivers clear programming ergonomics; for the few syntactic modifications that remain, allow **one canonical `pscv0` spelling** for ambiguous constructs. Lean `.lean` files keep normal Lean source syntax unchanged.

| Concern | Native Lean 4.35.0 | `pscv0` choice | Status |
|---|---|---|---|
| Ordinary definition | `def f (x : A) : R := t` | `def f(x: A): R := t` | admitted; Lean semantics |
| Named programming function | `def f (x : A) : R := t` | `function f(x: A): R := t` | keep ergonomic alias |
| Named value | `def x : A := t` | `const x: A := t` | keep parameterless alias; not JS `const` |
| Source call | `f x y` | `f(x, y)` for call punctuation; **also retain** `f x y` as native unparenthesized mathematical application | no change to Pi/application semantics |
| Parenthesized-argument gap | `f (x)`, `f (x, y)`, `f ()` are Lean applications | **reject all three in `.ps` application positions**; use `f(x)`, `f((x, y))`, `f(())` | grammatical restriction, not an indiscriminate whitespace ban |
| Typed binder parentheses | `variable (n : Nat)`, `def f (n : Nat)`, `fun (x : Nat) => ...` | **accept** selected native Lean binder syntax; these are NOT term applications | preserve Lean scopes, dependent binders and proofs |
| Standalone grouped terms | `#check (f x)`, `exact (hp)`, `(1 + 2 : Nat)` | **accept**; `(` begins an expected term and does NOT follow a completed application head | avoid false positive diagnostics |
| Uniformity across contexts | `#check f (x)`, `exact h (p)` may be Lean applications | **reject in `.ps`**, just like executable code; `#check f(x)`, `exact h(p)` | one `.ps` term grammar for code and proofs |
| Empty call | Lean uses a value such as `f ()` or default insertion | `f()` only means zero explicit source arguments, with narrowly defined completion | zero-argument syntax; not `f ()` |
| Unit argument | `f ()` | `f(())` for an explicitly written Unit; `f()` may complete exactly one required Unit | explicit argument versus narrowly defined empty-call insertion (§2) |
| Tuple argument | `f (x, y)` | `f((x, y))` | one tuple-argument spelling in `.ps` |
| Nullary declaration | `def f (_ : Unit) : R := t` | `function f(): R := t` | required Unit lowering, no second runtime arity |
| Conditional | native `if p then a else b` (and separate `bif` notation) | `if (p) { a } else { b }` lowers to native Lean `if` for `Prop` or coercible `Bool` | no implicit `bif`/`cond` transformation |
| `match`, `do`, proof, declarations | Lean layout-sensitive bodies; braced alternatives may be available | choose precisely defined **braced bodies**, including distinct `do`-statement branches | no duplicate indentation-only form for those bodies |
| Proof branches | `· exact hp`, `case ... => ...`, `next ... => ...` | **same native Lean syntax inside `by { ... }`** | no ASCII `.` bullet alias |
| Proof relevance | Lean `erased`, `erased mut`, `erased x ← action` | **exactly `erased`**, not `ghost` | native Lean 4.35.0 vocabulary |
| Refined values | Lean `Subtype`, `{x : A // P x}` | **same `Subtype` and `{x : A // P x}`** | no `refine type` declaration |
| Data invariants | Lean structure proof fields | explicit **proof fields** inside `structure ... where { ... }` | no trailing `invariant self =>` sugar |
| Verification proof attachment | 4.35.0 contract-generated `f.spec`; `where finally \| spec => ...` tactics | selected `where { finally { \| spec => { ... } } }` contract tail | one generated checked spec theorem; no `verify target :=` alias |
| Contracts and assertions | 4.35.0 experimental `given`, `requires`, `ensures`, `assert`, loop `invariant`/`decreasing` | same Lean heads with PSCV totality/proof restrictions | selected native forms |
| Mathematics | `∀`/`forall`, `∃`/`exists`, `λ`/`fun`, `→`/`->`, and standard notation | retain **both genuine Lean aliases**, because they are already one meaning and useful for math | no fabricated `exist` keyword |
| Successor patterns for `Nat` | `\| k + 1 => ...`, `\| .succ k => ...`, `\| k + 2 => ...` | **accept native Lean successor-pattern sugar**; prefer `k + 1` in arithmetic examples | `1 + k`, arbitrary variable addition, and subtraction are not constructor patterns |
| Shared theorem/program parameters | `section`, `variable (n : Nat)`, `variable {α : Type}` | keep **Lean `variable`** with exactly its binder visibility and section generalization | not a mutable/local runtime variable; not redundant function sugar |
| Lean interactive proof development | `#check`, tactic goals, `#print axioms`, `#eval` | support selected commands and expose cursor-position proof state in the editor | language syntax and IDE capabilities are separate from verified acceptance |
| Inspecting code | `#check`, `#eval`, `#reduce`, `#print`, `#print axioms` | identical selected commands; pure-total `#eval` only | diagnostic, not proof authority |
| Type foundation | `Prop`, `Type`, `Sort`, `Nat`, `Int`, `UInt8`... `Subtype`, `Fin`, `List`, `Array`, etc. | same Lean type names and semantics | explicit inventory in §8 |
| Pattern matching | Multi-discriminant, dependent/generalized match, `if let`, `nomatch`, pattern `let`, `matches` | adopt selected Lean grammar and checked eliminator semantics; canonical `.ps` braces where applicable | expanded `pscv0` baseline (§3, §4) |
| Deriving | Lean native trailing `deriving` | allow an **allowlisted trailing clause** on `structure`/`inductive` (`Repr`, `BEq`, `DecidableEq`, `Inhabited`, `Hashable`) | `PSCV0-DERIVE-01`; no standalone deriving command or arbitrary handler registration (§4, §6) |
| Collection access | Lean `GetElem`, `xs[i]`, `xs[i]?`, `xs[i]!`, `xs[i]'h` | adopt native forms and their precise proof/optional/panic meanings | baseline; `!` is not a verified safety claim (§3, §10) |
| Strings | Lean `s!"..."` interpolation and `r#"..."#` raw strings | native notation and `.ps`-checked embedded terms | baseline (§3) |
| Monadic errors | Lean `throw`, `try`, `catch`, `finally` in `do` | native meanings under admitted typed effect classes; `.ps` braced body selection | staged, no JS exceptions (§7) |
| Maps, JSON, filesystem, async | Lean library/effect families and external runtime adapters | curated API and boundary requirements, **no new global grammar** | application libraries, not core syntax (§8A) |
| Theorem libraries | pinned Lean tactics and notation registrations | broaden built-ins and enable explicitly pinned proof-producing extensions | checked proof terms; audited assumptions (§6) |
| Assurance | Lean typing/proofs plus runtime-world boundaries | ordinary checked output vs verified executable output | one language; only verified output requires complete certificate (§7B) |
| Partial recursion | Lean `partial def` and selected `partial function` lowering | permitted for ordinary execution; separately prove executable behavior to certify verified use | v7.1 §§5, 7B |
| Proof-friendly partial recursion | Lean `partial_fixpoint` as **post-definition suffix** | kernel-check the constructed fixed point, equations/monotonicity, and application-specific properties | v7.1 §5 |
| Controlled unsafe interop | Lean `unsafe` modifier / typed runtime boundary | ordinary or explicitly qualified boundary only until concrete runtime refinement is formally established | v7.1 §§5, 7B |

**Canonicalization principle:** aliases native to Lean's logical notation (e.g. `∀`/`forall`) are retained; confusing differences in callable syntax are removed. All omitted Lean syntax remains outside the closed `.ps` source profile; it is not silently borrowed from arbitrary Lean extensions.

### 4.35.0 upstream delta relevant to `pscv0`

The official [Lean 4.35.0 notes](https://lean-lang.org/doc/reference/4.35.0/releases/v4.35.0/) document experimental erased state in `do` (`erased`, `erased mut`, erased monadic binds), `given` logical contract variables, and new/adjusted VC and loop tooling. They also describe improved kernel reductions for several `Array`/`Vector` operations and array equality. **Impact:** target the 4.35.0 parser and proof/verification library exactly; do not copy RC3's assumed built-in registry or claim stable intrinsic-verification syntax. All such constructs still require independently checked final proof terms.

### 4.35.0 pin and unified `pscv0` decisions

1. **Keep `const` and `function`** alongside `def` because they communicate application-programming intent. `const` is a parameterless `def`; `function` provides a comma-separated explicit parameter list. They do not change Lean typing or runtime data semantics.
2. **Keep Lean mathematics, not duplicate syntax for mathematics.** In `.ps`, retain `∀` and `forall`, `∃` and `exists`, `λ` and `fun`, `->` and `→`, plus the other applicable pinned mathematical notations. The requested singular `exist` is **not** a Lean quantifier token; the native word is `exists`.
3. **Eliminate ambiguous parenthesis whitespace only in term application.** `f (x)`, `f (x, y)` and `f ()` are **parse errors in `.ps` when used as applications**, whether in an executable expression, proposition, tactic argument, contract, or `#check`/`#eval`. Write `f(x)`, `f((x, y))`, or `f(())`. Retain unparenthesized Lean application `f x y`. Crucially, **do not apply this restriction to native binder grammar** (`variable (n: Nat)`, `fun (x: Nat) => ...`) **or to a term that starts with grouping parentheses** (`#check (f x)`, `exact (hp)`, `(1 + 2)`).
4. **`function f()` means a required Lean `Unit` binder** and the source call `f()` supplies that `Unit` under the strict empty-call rule. A named `Unit` parameter such as `function g(u: Unit)` may be supplied either as **`g(())`** (one explicitly written argument) or **`g()`** (exactly-one-required-`Unit` completion); `g ()` is never accepted. This does **not** infer missing arbitrary arguments or make non-callable values callable. Defaults may permit `greet()` where declared parameters are optional.
5. **Use exactly one braced form for each ProofScript-owned body.** `by { ... }`, `do { ... }`, `match ... with { ... }`, `structure ... where { ... }`, `where { ... }`, and `if (p) { a } else { b }` are the designated `.ps` forms. Source `.lean` retains Lean layout syntax.
6. **Use Lean's actual proof language** inside braces: native middle-dot bullet `·`, `case`, `next`, and selected proof automation. ASCII `.` is **not** a bullet. Goal focus and proof sequencing mean the same thing as their selected Lean counterparts.
7. **Adopt native Lean verification vocabulary.** `erased` replaces `ghost`; `Subtype` and subtype notation replace `refine type`; explicit structure proof fields replace a redundant `invariant self` suffix; `theorem`/`vcgen` replaces the extra `verify` command. Intrinsic verification is experimental in 4.35.0, so this is a proposed pinned subset rather than a compiler-conformance claim.
8. **Keep diagnostics and type families Lean-native.** `#check`, `#print`, `#reduce` and bounded `#eval` belong to source analysis, not verified executable meaning. Types are `Nat`, `Int`, `Bool`, `UInt*`, `Int*`, `String`, `List`, `Array`, `Fin`, `Subtype`, etc., never ambient JS `number` or `any`.
9. **Retain Lean's meaningful native pattern sugar.** In `Nat` patterns, `k + 1` and `.succ k` are both allowed because the pinned Lean elaborator recognizes the former as a constructor pattern. Do not reclassify arbitrary `k + m`, `1 + k`, or `n - 1` arithmetic as a pattern. Prefer `k + 1` for parity, predecessor, and arithmetic-recursion examples; prefer `.succ k` when teaching the underlying constructor.
10. **Retain native Lean `variable`/`section` behavior.** Section variables used in definitions become function parameters of matching visibility and dependency; they are not mutable data. Theorems generalize section variables from the theorem statement, plus explicit `include` policy, rather than arbitrary use inside the proof. Recursion-changing inputs must appear as explicit declaration parameters, not be treated as varying section variables.
11. **Support Lean's interactive proof-workflow model.** `#check` already belongs to the language command selection. A future `.ps` VS Code integration should expose Lean-like goals, InfoView, diagnostics, type inspection and tactic feedback, with accurate `.ps` source positions; selected proof-syntax restrictions mean the project must not claim every Lean tactic or macro is available.
12. **Expand native Lean language features before adding punctuation.** Admit the selected 4.35.0 multi-discriminant and dependent `match` families, `if let`, `nomatch`, and pattern tests. Preserve the `.ps` braced-match/conditional convention; never replace constructor reasoning with TypeScript dynamic narrowing.
13. **Enable native `deriving` through a frozen allowlist.** Derivation is an elaboration operation producing declarations/instances; its handler identity and resulting declarations enter the environment, and any claimed laws remain checked evidence.
14. **Guarantee safe everyday APIs.** Support Lean array/list syntax and native `GetElem` variants, interpolation/raw strings, and a usable `List`/`Array`/`Option`/`Except` API baseline; maps/sets/JSON belong to curated libraries.
15. **Admit useful Lean `do` exception constructs carefully.** `throw`, `try`/`catch`, and conditional `finally` have monadic class requirements and typed effects; they do **not** copy JavaScript exceptions, and foreign/world effects remain explicit boundaries.
16. **Broaden theorem-authoring without broadening proof trust.** Pin built-in goal control and useful tactics; offer explicit, versioned import of proof-producing tactic/notation environments after review. No extension adds an axiom, proof hole, or verified certificate merely by being loaded.
17. **Separate ordinary checking from verified claims.** Under `pscv0` all source is Lean-grounded and checked. Ordinary executable programs may use permitted typed external capabilities, but only a closed and fully proved dependency closure can claim verified executable status; classify external assumptions separately.


**Conformance scope:** The chapter comparisons describe intentional surface rules, not evidence that a finished `pscv0` parser or verifier implements them. The original RC3 specification remains separate historical source material; the choices above supersede its redundant aliases only for this new `pscv0` design.

## Comparison guide and sources

| Marker | Meaning |
|---|---|
| **Shared Lean** | Already has the same or restricted native Lean source form and Lean meaning |
| **PSCV0 sugar** | Owned notation that desugars to a named Lean expression/declaration family |
| **PSCV0 verification** | Selected Lean-native contract/erased/loop/refinement forms with logic represented by Lean propositions and checked proof terms |
| **Restricted** | Lean can express more; `pscv0` deliberately recognizes a closed subset |
| **Lean encoding** | Lean example expresses the semantic equivalent but may not share PSCV0 syntax |
| **Illustrative** | Code shapes used to describe the design; no claim of compilation or proof closure |

**Sources of rule content:** the uploaded release candidate’s language chapters and selected PSCV verification proposals, plus the directly inspected pinned Lean 4.35.0 parser families and published Lean reference. `pscv0` additions are marked as surface deltas or proposed proof-language encodings rather than silently attributed to Lean. The authoritative Lean pin is the Git commit above; relevant exact Lean source links appear in the source concordance near the end. The public Lean language reference can explain parser behavior, but its `/latest/` pages are not a normative version pin.


### Reading schematic grammar, not an invented EBNF

The grammar tables are **selective Lean-4-style sketches**, modeled on its documented syntactic categories; they deliberately omit alternatives with `...`. They are *not* literal extracts of Lean parser combinator code and should not be used as a complete parser-generator specification. The `pscv0` column records what changes to source punctuation or accepted subfamilies, while typechecking and verification remain Lean-based. The specific syntax for PSCV0-only forms is a proposed design, not a claim that native Lean parses it.

## 0A. Adoption contract — language core, libraries, proof environment, and assurance

This revision implements the decisions proposed in the companion *PSCV0 Lean-First Language Feature Review* (2026-10-11) **as specification changes only**. It does not say that all Lean 4.35.0 programs parse as `.ps`, nor that the compiler can already execute/verify them. Source-derived facts retain the previous historical RC3/RC4 provenance; newly accepted families in this edition are explicitly proposed `pscv0` requirements.

| Ownership | Guaranteed direction | Not an implication |
|---|---|---|
| Lean-grounded language/core | `Prop`, `Type`, dependent functions, inductives, equality, kernel-checkable proofs, `Subtype`, `Fin` | no second logic, dynamic JS types, or unsound casts |
| **Selected** Lean source grammar | Multi-discriminant/dependent `match`, `if let`, `nomatch`, native `deriving`, `GetElem`, strings, goal control, `do`/exceptions where admitted | not unrestricted Lean parser/macros/attributes |
| ProofScript surface | `const`, `function`, adjacent `f(x, y)`, canonical braced bodies | no new function type/tuple semantics or truthiness |
| Curated first-party library | Practical `List`, `Array`, `Option`, `Except`, map/set, parsers/JSON, typed IO capabilities, as specified by manifest | library functions do not automatically register new notation/tactics |
| Named proof extension environment | Versioned, explicitly opted-in proof-producing tactics/notations and their registered declarations | no extension is an independent logical oracle; no silent dependency-based grammar expansion |
| **Ordinary checked output** | Valid source typing, selected terminating or partial definitions, and typed controlled runtime dependencies; proof terms still independently checked | explicit non-verified artifact identity; not a behavioral guarantee |
| **Verified executable output** | Every mandatory proof obligation (partial/total/trace behavior, effects, assumptions, runtime refinement, erasure, backend) discharged under a versioned assurance policy | no ordinary fallback, no unproved foreign behavior presented as closed verification |

**A binding rule:** every new feature must have an exact Lean parser/elaborator/lowering locator at the 4.35.0 pin, a selected `pscv0` grammar form, source examples, positive/negative acceptance cases, and an environment/assurance classification. Items labeled **P1 API** are product requirements, not permission to fabricate unspecified Lean/Std library symbols. If the exact signature/handler/registration cannot be pinned, the particular API remains *pending* despite the capability requirement.

**No hidden profile rollback (v7.1).** The `pscv0` verification discipline remains stronger than ordinary Lean programming. The new source forms `partial`, `partial_fixpoint` and restricted `unsafe` are **not proof escapes**: an ordinary build may use admitted executable recursion with explicit unverified identity; a verified build must prove every declared guarantee and accepted runtime correspondence first. User-written `.ps` `axiom` commands, source/generated `sorry` proof holes, unresolved metavariables and unapproved transitive assumptions remain prohibited in all emitted assurance categories. A weaker or external-boundary result is never silently upgraded to closed verified.

**Compatibility cost to watch:** rejecting `f (x)` inside `.ps` means some Lean proof terms and macro expansions require transcription, even as more Lean proof features become available. This is an explicit usability tradeoff; source-preserving conversion tools are preferable to silently changing the rule.

## 0B. Normative source-selection and grammar-category registry (second-pass closure)

This is a **constrained Lean 4 parser/elaborator overlay**, not an independent EBNF. In the schematic fragments below, `?`, `*`, and `+` denote optional, repetition, and nonempty repetition; an upstream `Lean.*` category is delegated to the immutable 4.35.0 pin **only after** the accepted subfamily has been selected. Ellipses are explanatory omissions, not wildcard admissions. A named `ps*` category without an explicitly selected meaning is not automatically valid source.

| Category | Selected meaning / ownership |
|---|---|
| `psBinderSeq` / `psNonemptyBinderSeq` | Canonical ordered telescope: **adjacent explicit groups are not admitted**. `psBinderSeq` permits an empty telescope for parameterless `def`-like declarations; `psNonemptyBinderSeq` requires at least one binder for a non-nullary `function`. A separator of at least one nonexplicit binder is required between any two explicit groups. Lean Pi-binder order and dependencies are preserved. |
| `psExplicitGroup` / `psParam` | **Nonempty** comma-separated explicit binder group; each `psParam` is `ident : term` with an optional Lean-grounded default. An empty group is not a normal declaration binder. |
| `psFunctionBinders` / `psNullaryFunctionGroup` | Non-nullary function: `psNonemptyBinderSeq` conforming to `PSCV0-BIND-02`. Nullary form: zero or more nonexplicit binders followed by one **final** `()`; only that terminal form inserts a required Lean `Unit` binder. Bare empty groups and adjacent explicit binder groups are excluded in all other declaration kinds. |
| `psNonExplicitBinder` / `psGivenBinder` / `psLambdaBinder` | `psNonExplicitBinder` is the selected native implicit, strict-implicit and instance declaration binder. `psGivenBinder` follows the 4.35.0 logical-contract binder selection. `psLambdaBinder` delegates to the **selected native** `Lean.Parser.Term.funBinder` family (ordinary names, typed/implicit/strict/instance binders as admitted in this profile); it is not the declaration-only comma `psExplicitGroup` grammar. |
| `psCallHead` / `psCallArgs` | Completed callable expression and adjacent positional-then-named argument list; zero written arguments follow `PSCV0-APP-03`. These belong to *term expressions*, not patterns or declaration binders. |
| `psDeclVal` / `psConstVal` / `psWhere` / `psLocalDeclaration` | `psDeclVal ::= ":=" psDeclTerm psRecursionSuffix? psWhere?` for selected `def`/`function`; `psConstVal ::= ":=" psDeclTerm psWhere?`; `psDeclTerm ::= term | "{" term "}"` denotes exactly one term. `psRecursionSuffix` is valid only for selected functions and eligible local definitions, after the body and before any `where`. `psConstVal` never accepts a recursion suffix. `psWhere` contains local selected `def` declarations, optionally followed by one eligible contract proof tail. |
| `psDefDecl` / `psFunctionDecl` / `psConstDecl` / `psDefOrFunction` | Modifier-free cores: `psDefDecl ::= "def" declId psBinderSeq (":" term)? psContractSeq? psDeclVal`; `psFunctionDecl ::= "function" declId psFunctionBinders (":" term)? psContractSeq? psDeclVal`; `psConstDecl ::= "const" declId (":" term)? psConstVal`; `psDefOrFunction ::= psDefDecl | psFunctionDecl`. Contract admissibility follows `PSCV0-CONTRACT-SCOPE-01`. Only `function` admits terminal source-nullary `()`. Selected heads remain authoritative even if Lean provides a broader declaration parser. |
| `psRecursiveDecl` / `psRecursionSuffix` | `psRecursionSuffix ::= psTermination | "partial_fixpoint"` appears immediately after the body, before any `where`. Selected total recursion uses `psTermination`; `partial_fixpoint` uses checked fixed-point construction with no competing suffix. `partial` and restricted `unsafe` prefixes use their corresponding executable-only strategy, with no termination/fixpoint suffix. The full modifier/recursion combination matrix in §5 and pinned Lean mutual-clique checks govern acceptance. |
| `selectedPsDeclaration` / `psModifiers` | `selectedPsDeclaration ::= selectedLeanDeclaration \| psDefDecl \| psFunctionDecl \| psConstDecl`, with selected Lean declarations only. Head-specific restrictions win over unrestricted native alternatives. Selected modifier order follows stable Lean 4.35.0: attributes / visibility, then optional `noncomputable` where `PSCV0-DECL-01` permits proof/spec use, optional restricted `unsafe` on `def`/`function` under `PSCV0-UNSAFE-01`, optional `partial` on `def`/`function` under `PSCV0-TERM-02`. The combination `unsafe partial` is **not** automatically admitted; separate policy/semantic justification is required. `partial_fixpoint` is **a recursion suffix**, not a leading modifier. `const` does not acquire these prefixes. The ordinary public-by-name source convention is unchanged. |
| `psContractSeq` / `psGivenClause` / `psRequiresClause` / `psEnsuresClause` | Only selected `def`/`function` declarations may carry the 4.35.0 sequence `given? requires? ensures?` in precisely that order, at most one of each. These are definition clauses, not repeatable arbitrary annotations. |
| `psSpecProofTail` / `psTacticSeq` | One contract-specific `where { finally { \| spec => { ... } } }` section with a selected Lean tactic sequence; lowers into native `where finally \| spec => ...`. |
| `psInstanceHeader` / `psInstanceFields` / `psPriority` | The **one** selected instance header is `psInstanceHeader ::= declId? psBinderSeq ":" term`: an optional named `declId` (including selected Lean universe-name suffixes), an ordered possibly empty non-nullary binder telescope, and a **mandatory** instance type. Anonymous instances omit `declId`; neither kind acquires a hidden `Unit` binder. Its optional command-head modifier is `psPriority ::= "(" "priority" ":=" psPriorityAtom ")"`, where `psPriorityAtom` is a nonnegative decimal literal or `low` / `mid` / `default` / `high`. The body uses newline-separated `psInstanceFields` inside `where { ... }`. Native `instance ... := value` and arbitrary priority expressions are excluded from initial Standard. Method binders use `psBinderSeq`, not term-call desugaring. |
| `psDoSeq` / `psDoItem` / `psDoIf` / `psDoIfLet` / `psDoCondition` | Selected 4.35.0 `doSeq`/`doSeqItem` bodies; conditional branches are do-sequences and may omit `else`, unlike term `if`. `psDoCondition` selects `Lean.Parser.Term.binderIdent ':' term` (preferred on a binder plus colon) or `term` as the **condition inside** `if ( ... )`; it is not declaration-binder or adjacent-call syntax. `psDoIfLet` is separate and initially selects only `:=`, not 4.35.0's monadic `←` variant. |
| `psBaseDoItem` / `psVerifiedDoItemP0` / `psStagedDoItemP1` | The selected union `psDoItem ::= psBaseDoItem \| psVerifiedDoItemP0 \| psStagedDoItemP1` remains: base monadic statements/conditionals; P0 mutable, `for`, **total** `while`/invariant/decreasing, erased state and proof assertions; P1 typed exception handlers subject to their frozen environment. **v7.1 adds `psWhilePartial` as a separately gated extension, not as an accidental relaxation of P0 total-loop `vcgen`.** Neither P0 nor P1 imports arbitrary Lean `do` syntax. P0/P1 native typed/verified-effect prerequisites, braced bodies, and LF separation remain mandatory. |
| `psCtor` / `selectedLeanPattern` | Constructor *declaration* versus Lean *match pattern*. Term-call comma syntax is not imported into pattern grammar. |
| `psBody` / `psProof` / `psQuantBinder` / `psArgs` | **Retired ambiguous aliases**; use `psDeclVal`, `psTacticSeq`, `psGivenBinder`, and `psCallArgs`, respectively. |
| `psCallable` / `psBinder` | **Retired ambiguous aliases**; use `psCallHead` / the native selected Lean binder or `psBinderSeq` according to position. |
| `psAttributes` | The selected declaration-attribute category in §6 (`simp`, `instance`, `default_instance`), not unrestricted Lean attribute handlers and not trailing `deriving`. |

**`PSCV0-DECL-01` and `PSCV0-DO-SELECT-01` (scope, revised v7.1).** Declaration aliases remain head-specific. `noncomputable` stays proof/spec-only and executable computational closure cannot depend on it. `partial` and restricted `unsafe` apply only to admitted `def`/`function` declarations and do not make proof values, arbitrary tactics, or unchecked casts source-admissible. `partial_fixpoint` attaches after a selected recursive body and must satisfy Lean 4.35.0's pinned elaboration and monotonicity requirements. For `do`, P0/P1 environment/effect gating remains mandatory. Invariant-only divergent loops are a separate staged proof rule and are not silently admitted by the total-loop grammar.

**Normative error taxonomy:** LEX (invalid source/trivia), PARSE (wrong context or token/adjacency), ELAB (typing, typeclass, default or `Unit` completion), **ELAB/VC-PROOF** (generated verification-condition proof construction fails or leaves unsolved goals), ENV (unregistered module/deriving/tactic/effect facility), KERNEL (an actually submitted checked proof/term is invalid), and ASSURANCE (artifact closure, assumptions or erasure policy). A negative fixture passes only when its intended stage and rule are exercised; an earlier unrelated lexer failure does not count as an adjacency or proof-closure pass.

**Versioned profile state:** These are normative **v7.1 design targets** over the stable Lean 4.35.0 source commit, not a measured PSC0 conformance claim. The stable source SHA alone is not a frozen PSCV0 Standard environment identity. Imports, notation, instances, tactic/deriving handlers, partial-fixpoint construction dependencies, runtime/unsafe boundaries, toolchain artifacts, and their reproducible manifest digest remain independent release gates (§14).

## 1. Files, lexical structure, and name scope

### Source text, identifiers, comments, and line breaks

**Feature / profile:** Shared lexical families; PSCV0 sugar whitespace restrictions  
**Source basis:** Ch. 5; A.1.1, A.3; Appendix I.4

**Lean 4 grammar family → ProofScript surface selection (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>sourceFile ::= module? importHeader command* EOF
identifier ::= Lean.ident
literal ::= Lean.numeral | Lean.string | Lean.char | ...
comment ::= &quot;--&quot; lineText | &quot;/-&quot; nestedComment &quot;-/&quot;</code></pre></td><td valign="top"><pre><code>psSourceFile ::= psImportHeader selectedPsCommand* EOF
identifier ::= Lean.ident
literal ::= Lean.literalRestricted
comment ::= Lean.comment
// Modification: UTF-8; ASCII-space/LF layout profile; no ASI</code></pre></td></tr></tbody></table>

**Side-by-side examples.**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>-- UTF-8 source; line comments
/- nested /- block -/ comments -/
def answer : Nat := 42</code></pre></td><td valign="top"><pre><code>-- UTF-8 .ps source; line comments
/- nested /- block -/ comments -/
const answer: Nat := 42</code></pre></td></tr></tbody></table>

**Source language distinction.** Standard ProofScript requires UTF-8, permits one leading BOM, normalizes CRLF to LF, rejects lone CR and horizontal tabs outside literals/comments, and uses only ASCII SPACE/LF as structural whitespace. Lean’s scanner is less restricted; neither language imports JavaScript automatic semicolon insertion.

**Lexical separation for application tests:** native Lean line comments `-- ...` and nested block comments `/- ... -/` are valid trivia. The JavaScript/C-style block spelling `/* ... */` is **not** a valid `.ps` comment. `PSCV0-APP-02` conformance must use lexically valid Lean trivia (e.g. `f /- gap -/ (x)`); invalid `/* ... */` input belongs in a **separate lexer-negative** test and cannot count as evidence that the application-gap rule fired. Lean-defined identifier and literal tokens are referenced, not redefined.

### Modules, imports, and public imports

**Feature / profile:** Shared with tighter ProofScript module grammar  
**Source basis:** Ch. 6; A.2; [module.import-header]

**Lean 4 grammar family → ProofScript surface selection (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>header ::= &quot;module&quot;? importCommand*
importCommand ::= &quot;import&quot; moduleName
                | &quot;public&quot; &quot;import&quot; moduleName (module mode only)
command ::= Lean.command</code></pre></td><td valign="top"><pre><code>psImportHeader ::= psImport*
psImport ::= &quot;import&quot; moduleName | &quot;public&quot; &quot;import&quot; moduleName
selectedPsCommand ::= selectedLeanCommand | selectedPsDeclaration
// .ps implicitly lowers to a Lean `module` header; no written `module` keyword required</code></pre></td></tr></tbody></table>

**Side-by-side examples.**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>module
public import Std

public def value : Nat := 1</code></pre></td><td valign="top"><pre><code>public import Std

const value: Nat := 1</code></pre></td></tr></tbody></table>

**Source language distinction — `PSCV0-MODULE-01` and `PSCV0-MODULE-02`.** Each `.ps` source file **implicitly targets a Lean 4.35.0 `module`**; the `.ps` source does not repeat the literal `module` header, but the lowering must emit it before imported modules. Both `import M` (private to this module) and `public import M` (re-export the imported module's public scope) use **module-style** 4.35.0 import meaning; importing a non-module or unavailable module rejects at ENV. All imports remain top-level and precede commands; `meta import`, `import all`, and legacy transitive-import semantics are outside the initial `.ps` selection. The Lean column therefore writes its `module` header explicitly, unlike the `.ps` column. All examples that omit imports/headers elsewhere are **fragments**, not self-contained module fixtures.

**Public-by-default source ↔ 4.35.0 private-by-default module lowering:** `pscv0` intentionally treats unmarked top-level/namespace declarations as publicly named. The canonical lowering establishes an appropriate Lean `public section` around the unmarked selected declaration scope (or equivalent explicit `public` modifiers); a written `.ps` `private` declaration overrides the default. A public **name is not the same as an exposed body**: Lean 4.35.0 ordinarily hides the body of a public definition from importing modules. Initial Standard PSCV0 preserves this non-exposed default, excludes user `@[expose]`, and requires explicitly public, checked interface theorems when clients need equalities unavailable by unfolding. This is a source/profile choice and a required module conformance condition, **not** a claim that the lowering already exists. Public signatures may not leak unexported private declarations; generated contract specification theorems must receive the correct intended visibility through the selected public section. Cross-module direct/public imports, name visibility, specification-theorem visibility and reducibility must be differential-tested against the pinned module system. `.ps` and `.lean` files remain distinct source kinds.

### Namespace, sections, open, variables, include / omit

**Feature / profile:** Shared names/scopes with PS deterministic resolution  
**Source basis:** Ch. 7; A.2; Appendix I `LEAN-SCOPE-SECTION`

**Lean 4 grammar family → ProofScript surface selection (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>command ::= &quot;namespace&quot; ident | &quot;section&quot; ident?
          | &quot;end&quot; ident? | &quot;open&quot; ident+
          | &quot;variable&quot; binder+ | &quot;include&quot; ident+
          | &quot;omit&quot; ident+ | &quot;universe&quot; ident+</code></pre></td><td valign="top"><pre><code>command ::= &quot;namespace&quot; ident | &quot;section&quot; ident?
          | &quot;end&quot; ident? | &quot;open&quot; ident+
          | &quot;variable&quot; selectedLeanBinder+ | &quot;include&quot; ident+
          | &quot;omit&quot; ident+ | &quot;universe&quot; ident+
// Modification: selected Lean commands; same scoping model</code></pre></td></tr></tbody></table>

**Side-by-side examples.**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>namespace MathOps
  def twice (n : Nat) : Nat := n + n
end MathOps

open MathOps
section
  variable (n : Nat)
  def result : Nat := twice n
  #check n
end

#check result
#eval result 7  -- 14</code></pre></td><td valign="top"><pre><code>namespace MathOps
  function twice(n: Nat): Nat := n + n
end MathOps

open MathOps
section
  variable (n: Nat)
  def result: Nat := twice(n)
  #check n
end

#check result
#eval result(7) -- 14</code></pre></td></tr></tbody></table>

**Source language distinction.** Namespace prefixes affect declaration names; sections do not. ProofScript's unqualified-name lookup has deterministic local/current/enclosing/opened/imported tiers; ambiguities reject. `#check` is an **admitted diagnostic command** in `pscv0` Standard, not an unknown command; detailed restrictions appear in §7A.

**Why `variable (n: Nat)`?** This declares one **explicit section parameter** shared by subsequent declarations. When `def result: Nat := twice(n)` uses `n`, Lean inserts an explicit `(n : Nat)` parameter into the definition's final signature: conceptually `result : Nat → Nat`. Accordingly `#check result` displays its parameterized type and `#eval result(7)` evaluates to `14`; the `result` declaration survives `end`, while the local section variable `n` does not. `open MathOps` only permits the unqualified name `twice`; it does not import or copy the definition. For a single declaration, the clearer equivalent is `function result(n: Nat): Nat := MathOps.twice(n)` without a `section`.

**Binder visibility is Lean-native.** `variable (n : Nat)` is explicit, `variable {α : Type}` is implicit, and `variable [Decidable p]` is an instance parameter where valid. These parentheses occur in a **command binder position**, not after a callable term, so the application adjacency restriction cannot reject them. For theorems, only dependencies in the theorem *statement* (plus `include`-forced dependencies) become theorem parameters: mentioning a section variable solely in a proof body must not silently change the theorem's statement. For recursion, a section variable is fixed within the definition body, so a decreasing recursive argument such as `n` in `even`/`odd` belongs in the function header. These are Lean 4.35.0 semantics, not new ProofScript rules. See [Lean section variables](https://lean-lang.org/doc/reference/4.35.0/Namespaces-and-Sections/).

## 2. Declarations, functions, and arguments

### Ordinary `def`

**Feature / profile:** Shared semantics; PSCV0 sugar parameter and body forms  
**Source basis:** Ch. 8; A.2, A.7–A.8

**Lean 4 grammar family → ProofScript surface selection (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>command ::= modifiers? &quot;def&quot; declId declSig? declVal
declSig ::= binder* (&quot;:&quot; term)?
declVal ::= &quot;:=&quot; term termination? whereDecls? | equations</code></pre></td><td valign="top"><pre><code>command ::= modifiers? &quot;def&quot; declId psBinderSeq (&quot;:&quot; term)? psContractSeq psDeclVal
psDeclVal ::= &quot;:=&quot; term psTermination? psWhere?
          | &quot;:=&quot; &quot;{&quot; term &quot;}&quot; psTermination? psWhere?
// Modification: comma explicit binders; optional one-term braces</code></pre></td></tr></tbody></table>

**Side-by-side examples.**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>def double (n : Nat) : Nat :=
  n + n</code></pre></td><td valign="top"><pre><code>def double(n: Nat): Nat := {
  n + n
}</code></pre></td></tr></tbody></table>

**Source language distinction.** Consecutive explicit parameters are comma-separated inside one group; `:= { term }` is a **single-term wrapper**, not a multi-statement block. Plain `:= term` is also valid. Braced record literals are separately parsed as terms. In declarations, `(n: Nat)` is parsed as an **explicit binder group**, not a call: `def double (n: Nat): Nat := n + n` is admitted by the selected declaration grammar, although the canonical formatter writes `def double(n: Nat): Nat := n + n`. For `function`, the canonical spelling is `function double(n: Nat)`. This allowance has no `f ()` consequence because a call after an expression head uses the separate term grammar.

### Value declaration: `const` versus Lean `def`

**Feature / profile:** PSCV0 sugar  
**Source basis:** Ch. 8 (`const`); A.2; Appendix H.1

**Lean 4 grammar family → ProofScript surface selection (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>command ::= &quot;def&quot; declId (&quot;:&quot; term)? &quot;:=&quot; term</code></pre></td><td valign="top"><pre><code>command ::= modifiers? &quot;const&quot; declId (&quot;:&quot; term)? psDeclVal
// Lowers to parameterless Lean def; not JS/TS const</code></pre></td></tr></tbody></table>

**Side-by-side examples.**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>def answer : Nat := 42
def inc : Nat → Nat := fun n =&gt; n + 1</code></pre></td><td valign="top"><pre><code>const answer: Nat := 42
const inc: Nat -&gt; Nat := { fun n =&gt; n + 1 }</code></pre></td></tr></tbody></table>

**Source language distinction.** `const` is a top-level/namespace **parameterless definition alias**—not TypeScript `const` and not a distinct Lean kernel constructor. In the provided design RC it is retained even though other ProofScript design discussions may have considered removing it.

### Function declaration: `function` versus `def`

**Feature / profile:** PSCV0 sugar declaration alias  
**Source basis:** Ch. 8–9; A.7

**Lean 4 grammar family → ProofScript surface selection (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>command ::= &quot;def&quot; declId binder* (&quot;:&quot; term)? declVal</code></pre></td><td valign="top"><pre><code>command ::= modifiers? &quot;function&quot; declId psFunctionBinders
            (&quot;:&quot; term)? psContractSeq psDeclVal
// Non-nullary: psNonemptyBinderSeq; nullary: psNonExplicitBinder* psNullaryFunctionGroup
// `psContractSeq` is ordered and non-repeating (§7)
// Modification: &#x27;function&#x27; =&gt; Lean &#x27;def&#x27;; comma binder group</code></pre></td></tr></tbody></table>

**Side-by-side examples.**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>def add (x : Nat) (y : Nat) : Nat :=
  x + y</code></pre></td><td valign="top"><pre><code>function add(x: Nat, y: Nat): Nat := {
  x + y
}</code></pre></td></tr></tbody></table>

**Source language distinction.** Lean application remains curried at the core level; ProofScript's comma-grouped source parameters and calls do not make a new noncurried type theory. `function name()` is a dedicated, terminal **nullary-function group** (with an inserted required Lean `Unit` binder); `function name(args)` and interleaved binders use `psNonemptyBinderSeq` under `PSCV0-BIND-02`. No other declaration or method gains hidden-`Unit` behavior simply by reusing the generic binder grammar.

### Explicit, implicit, strict-implicit, instance binders

**Feature / profile:** Shared binders with PS explicit-group grammar  
**Source basis:** Ch. 9; A.7; Appendix I `LEAN-BINDER-*`

**Lean 4 grammar family → ProofScript surface selection (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>binder ::= &quot;(&quot; ident+ &quot;:&quot; term &quot;)&quot; | &quot;{&quot; ident+ &quot;:&quot; term &quot;}&quot;
         | &quot;⦃&quot; ident+ &quot;:&quot; term &quot;⦄&quot; | &quot;[&quot; term &quot;]&quot;
// ASCII {{x : T}} is also a strict-implicit Lean spelling</code></pre></td><td valign="top"><pre><code>psBinderSeq ::= psNonExplicitBinder*
              (psExplicitGroup psNonExplicitBinder+)* psExplicitGroup?
psNonemptyBinderSeq ::= psBinderSeq  // only if at least one binder is present
psFunctionBinders ::= psNonemptyBinderSeq
                    | psNonExplicitBinder* psNullaryFunctionGroup
psExplicitGroup ::= &quot;(&quot; psParam (&quot;,&quot; psParam)* &quot;,&quot;? &quot;)&quot;   // nonempty
psNullaryFunctionGroup ::= &quot;()&quot;  // function only, terminal
psParam ::= ident &quot;:&quot; term (&quot;:=&quot; term)?
psNonExplicitBinder ::= selectedLeanImplicitBinder
                    | selectedLeanStrictImplicitBinder | selectedLeanInstBinder
// Adjacent explicit groups are rejected by grammar (BIND-02), never silently merged</code></pre></td></tr></tbody></table>

**Side-by-side examples.**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>def same {α : Type} [BEq α] (x : α) (y : α) : Bool :=
  x == y

def retain {{α : Type}} (x : α) : α := x</code></pre></td><td valign="top"><pre><code>function same {α: Type}[BEq α](x: α, y: α): Bool := {
  x == y
}
function retain {{α: Type}}(x: α): α := x</code></pre></td></tr></tbody></table>

**Source language distinction — `PSCV0-BIND-02`.** ProofScript preserves the **ordered Lean binder telescope**. A comma group contains one or more successive explicit binders; implicit (`{...}`), strict-implicit (`{{...}}` / `⦃...⦄`), and instance (`[...]`) binders may occur **before, between, or after** explicit groups. Two adjacent explicit groups without an intervening nonexplicit binder are **excluded by `psBinderSeq`** and rejected at the PARSE stage under `PSCV0-BIND-02`; a programmer must write one comma group, never rely on silent group merging. The `()` group is **not** a generic empty binder group: only a final `function` nullary group gets the required-`Unit` lowering. `def f()`, `abbrev T()`, `structure S()`, `inductive E()`, `| nil()`, and instance-field `field()` are rejected by the initial source grammar. `{{α: Type}}` remains the strict-implicit ASCII form. Closed PSCV0 restricts instance synthesis to a pinned deterministic registry.

**Interleaving illustration:** `function choose(n: Nat)[Decidable(n = 0)](x: Fin(n + 1)): Nat := x.val` lowers to the corresponding Lean telescope `(n : Nat) [Decidable (n = 0)] (x : Fin (n + 1))`; no binders are silently reordered. The `Decidable(...)` and `Fin(...)` spellings are PSCV0 term calls inside types and must respect `PSCV0-APP-02`.

### Default/optional arguments and named arguments

**Lean family:** Lean declaration binders, named arguments, optional/default binders, and dependent function application. **`pscv0` delta:** comma-separated explicit parameters and no-gap call parentheses. Default expressions are specified at declaration scope (including access to preceding binders) and instantiated when applied; admitted automatic parameters are resolved by the pinned Lean elaboration mechanism in their application context. This is not runtime overloading, and a caller cannot invent an undeclared default.

| Lean 4.35.0 | ProofScript `pscv0` |
|---|---|
| `def greet (name : String := "world") : String := name` | `function greet(name: String := "world"): String := name` |
| `greet (name := "Ada")` | `greet(name := "Ada")` |
| `greet` can be elaborated with a default in an expected-result context | `greet()` explicitly requests completion of all optional explicit arguments |
| `def add (x y : Nat) := x + y` | `function add(x: Nat, y: Nat): Nat := x + y` |

**Lean grammar (schematic):** `binder ::= ... | '(' ident ':' term (':=' term)? ')'`; native named arguments are supplied through Lean's application elaborator. **ProofScript modification (schematic):** an adjacent `(` after a call head begins a comma-separated list of positional arguments followed by optional named arguments. One optional trailing comma is permitted. A positional argument after a named argument or an unknown/duplicate name rejects.

### Zero-source-argument functions and `f()`

The Lean kernel has only unary application and dependent/Pi-function types; a source-nullary function is not a second core function kind.

| Source | `pscv0` acceptance | Desugaring / explanation |
|---|---|---|
| `function clock(): Nat := 42` | yes | Lean `def clock (_u : Unit) : Nat := 42` |
| `clock()` | yes | Lean `clock ()` through zero-source-argument completion |
| `clock(())` | yes when a `Unit` argument is required | an explicit one-argument application; may have the same Lean core term as `clock()` |
| `clock ()` | **no** | forbidden gap-parenthesized application in `.ps` |
| `function useUnit(u: Unit): Nat := 1` | yes | regular explicit parameter |
| `useUnit(())` | yes | explicitly pass `Unit` |
| `useUnit()` | yes under **exactly-one-Unit** completion rule | inserts `()` for its sole required explicit `Unit` binder; same core application as `useUnit(())` |
| `function greet(name: String := "world"): String := name` / `greet()` | yes | inserts declared default |
| `greet ()` | **no** | parse error, regardless of expected type |
| `function add(x: Nat, y: Nat): Nat := x + y` / `add()` | **no** | unresolved required arguments |

**Empty-source-argument rule (proposed):** First establish that the head is callable by a Lean Pi/function type (possibly via an **admitted** `CoeFun` instance), then resolve its implicit/instance binders and the explicitly declared default/automatic parameters under the pinned Lean elaborator. `f()` is admitted only when (a) that completion leaves **no** required explicit binders, or (b) it leaves **exactly one** required explicit binder whose instantiated type is *definitionally equal* to `Unit`, allowing the insertion of `()`. If that type remains an unsolved metavariable, do not guess `Unit`. All other required values reject; neither `Inhabited` values nor missing `Nat`/other values are synthesized. A bare non-callable value, e.g. `answer : Nat`, does not become callable through `answer()`.

This is an **elaboration rule**, not a proof or runtime arity model; the semantics of first-class functions remains their Lean Pi types. The rule does not restrict ordinary **nonempty** partial application: `add(1)` still denotes a function when another required parameter remains and the expected type permits it. For a named explicit `Unit` parameter, `useUnit()` and `useUnit(())` may elaborate to the same Lean term; `useUnit ()` remains syntactically forbidden.

### Parenthesized calls, native Lean application, and tuple arguments

**Adopted `pscv0` source rule `PSCV0-APP-01`.** `pscv0` keeps Lean's curried application semantics and supports two intentional spellings: adjacent comma calls `f(x, y)` and native *unparenthesized* Lean application `f x y`. It rejects **gap-parenthesized application** in `.ps`, which is the hazardous third possibility. This is a grammar/source-acceptance rule, not merely a formatter preference; `.lean` modules retain their normal Lean grammar.

| Expression | Lean meaning or comparison | `pscv0` acceptance |
|---|---|---|
| `f x y` | two Lean unary applications | **accept** |
| `f(x)` | one ProofScript call argument | **accept**; lowers to Lean `f x` |
| `f(x, y)` | two ProofScript call arguments | **accept**; lowers to Lean `f x y` |
| `f (x)` | one grouped argument in `.lean` | **reject**; use `f(x)` |
| `f (x, y)` | **one tuple** in `.lean`, not two arguments | **reject**; use `f((x, y))` |
| `f((x, y))` | one tuple argument | **accept**; lowers to Lean `f (x, y)` |
| `f()` | zero source arguments, type-directed completion | **accept only if** `PSCV0-APP-03` closes every required explicit argument |
| `f ()` | one explicit Unit value in Lean | **reject**; use `f(())` |
| `f(())` | one explicitly supplied `Unit` value | **accept** where parameter type is `Unit` |
| `h (g x)` | application to one grouped argument in `.lean` | **reject**; use `h(g x)` or `h(g(x))` |
| `(h) (x)` | grouped function applied to grouped argument in `.lean` | **reject**; use `(h)(x)` or `h(x)` |
| `f/- gap -/(x)` | a valid Lean block comment separates head and `(` | **reject with `PSCV0-APP-02`**, not a generic lexer failure |
| `f /- gap -/ (x)` | spaces plus a valid Lean block comment | **reject with `PSCV0-APP-02`** |
| `f(/- comment -/ x)` | comment *inside* adjacent call delimiters | **accept** where `f x` is well-typed; no head-to-`(` gap |
| `x + (y * z)` | `(` begins an operand after infix `+`, not an application head | **accept** |
| `(f x)` | grouped *standalone term* | **accept** |
| `#check (f x)` | `(` starts the command's term | **accept** |
| `exact (hp)` | `(` starts a tactic argument term | **accept** |
| `variable (n: Nat)` | `(` starts a typed command binder | **accept** |
| `fun (n: Nat) => n` | `(` starts a typed lambda binder | **accept** |

**`PSCV0-APP-02` — source-position and grammar-category test.** A parser should first determine whether it is parsing a **binder**, an **initial/grouped term**, or a **continuation of an already-completed expression**. Only in the last category is a parenthesis after a nonempty trivia gap banned as an application operand. The rule is not the text-level regex `identifier + space + '('`: such a rule would incorrectly reject `variable (n: Nat)`, theorem and `def` binders, `#check (term)`, `exact (proof)`, and infix grouping.

Within an application expression:

1. If an immediately adjacent `(` follows a callable, parse a ProofScript postfix **comma-argument call**. One trailing comma is allowed; positional arguments precede any named arguments.
2. If a Lean application argument begins with any ordinary **non-parenthesized** admitted term, keep Lean's normal left-associative application semantics (for example `f x y`).
3. If a **nonzero space/comment/newline gap** would join an existing callable expression to an argument whose first source token is `(`, report `PSCV0-APP-02` and reject that application. Comments never count as adjacency. A newline also follows the independent enclosing layout rules; if it separates two independent `do` statements, do not silently reinterpret them as one call.
4. Nested parentheses *inside an adjacent call argument list* remain ordinary Lean grouping/tuple/Unit syntax: `f((x, y))`, `f(())`, `f((g x))` are legal. Other ordinary grouped expressions remain legal wherever the surrounding Lean grammar expects a fresh term.

**`PSCV0-APP-03` — empty invocation.** `f()` means **no explicitly written arguments**; it neither creates a JavaScript zero-arity function model nor manufactures missing values for partial application. The head must be callable under the pinned Lean Pi/`CoeFun` rules. After Lean's permitted implicit/instance synthesis and declared default/automatic parameter completion, either **no required explicit binder remains** or **exactly one required explicit binder remains and its instantiated type is definitionally `Unit`**; in the latter case the elaborator inserts `()`. An unresolved binder type cannot be treated as `Unit`. Two required `Unit` arguments, `Unit` plus another required argument, a missing `Nat`, an unapproved `CoeFun`, or a non-callable `Nat` value must reject. Default expressions follow their declared lexical scope and binder instantiation; caller-local guesses are not defaults. A nonempty `f(x)` may still be a valid partial application where Lean permits it.

`function f(): R := body` lowers to a **required** Lean `Unit` binder with type `Unit → R`. Hence `f()` is accepted under the exactly-one-Unit case. The same completion is available to `function useUnit(u: Unit)`; both `useUnit()` and `useUnit(())` elaborate to Lean `useUnit ()` when `useUnit` has exactly that required explicit binder and the same implicit/instance resolution. This harmless equivalence is distinct from the spacing confusion between `f(x, y)` and `f (x, y)`. It is a **ProofScript** source/elaboration rule, not an assertion that Lean natively spells a zero-argument call as `f()`.

**No separate call grammar in proofs or diagnostics.** The same rules govern function bodies, theorem propositions, `by { ... }` term arguments, `do` elements, `requires`/`ensures` clauses, match branches, `#check`, `#eval`, and `#reduce`. For example, `exact h(p)` and `#check f(())` are valid when types fit; `exact h (p)` and `#check f ()` must fail as applications. A tactic head such as `exact` is not itself an applicative term; consequently `exact (hp)` remains a valid grouped *initial tactic argument*.

**Formatter/IDE requirement.** Formatting must preserve the same elaborated Lean term and argument partition. It must never insert a gap into `f(...)`, turn `f((x, y))` into `f(x, y)`, or auto-correct an invalid gap-parenthesized expression without explicit user action. Source spans, diagnostics, completion and hover types should operate on the exact `.ps` term grammar, not a fallback unrestricted `.lean` parser.

### Mixed native application and postfix calls (`PSCV0-APP-04`)

To combine Lean whitespace application with ProofScript postfix comma calls, parse an adjacent call as part of its immediately preceding **atomic/postfix head** before consuming it as an argument of the surrounding Lean application. Native application is left-associative over those completed terms; explicit parentheses override grouping. The application-gap rejection is then checked on the actual term-continuation syntax tree rather than regexing all whitespace. Field projection is a postfix operation and retains the pinned Lean type-directed field elaborator.

| Source `.ps` | Required argument tree before Lean elaboration |
|---|---|
| `f x(y)` | `f (x y)`; `x(y)` binds before `f` consumes its next operand |
| `f g(x, y)` | `f (g x y)`, not `(f g) x y` |
| `(f x)(y)` | `(f x) y`; grouping makes the result of `f x` the callable |
| `f(x) y` | `(f x) y`, after completing the first postfix call |
| `obj.method(x) y` | `(obj.method x) y`, before type-directed method-receiver insertion |
| `f (g x)` | **PARSE reject** (gap-parenthesized application); write `f(g x)` |

As a refinement-safe policy, formatting must round-trip the **argument tree**, not merely the resulting type; parentheses can intentionally choose a different Lean core term. The complete elaboration (including receiver insertion, implicit binders and overloads) is checked against 4.35.0 and may still reject ill-typed examples.

### Binder grammar is independent of term application (`PSCV0-BIND-01`)

Lean's native `variable`/`section` commands, function/theorem/definition signatures, lambda binders, quantifier binders, and instance binders are **binding constructs**. Their delimiters specify a variable with a type or implicit-argument status; they are not a function being applied to `()` or to `(n: Nat)`.

```proofscript
namespace MathOps
  function twice(n: Nat): Nat := n + n
end MathOps

open MathOps
section
  variable (n: Nat)  -- native Lean explicit section binder: VALID
  def result: Nat := twice(n)
  #check result      -- resulting signature has an explicit (n : Nat)
end

#check result
#eval result(7)      -- 14

const idNat: Nat -> Nat := fun (x: Nat) => x
#check (idNat 3)     -- parentheses start a grouped term, VALID
#check idNat(3)     -- adjacent ProofScript call, VALID
```

`variable (n: Nat)` stays valid even though `result (7)` and `twice (n)` are rejected in `.ps`. Parser decisions depend on **grammar category**, not on whether a space happens to occur before `(`. A source formatter should prefer `function twice(n: Nat)` and `result(7)` but preserve the native `variable (n: Nat)` syntax.

This reference intentionally retains a small amount of harmless duplicate notation (`f x` and `f(x)`, selected Unicode/text mathematical aliases) rather than introducing false equivalence with Lean's spaced parenthesized arguments. **Soundness still requires faithful elaboration, type checking and independent proof checking; the adjacency restriction primarily improves source predictability and refactoring safety.**

### Generalized field/method notation

**Feature / profile:** Shared semantics; PS method call syntax  
**Source basis:** Ch. 10; A.6; [elab.field]

**Lean 4 grammar family → ProofScript surface selection (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>term ::= term &quot;.&quot; ident | term argument+ | ...
// Lean generalized field notation uses type-directed elaboration</code></pre></td><td valign="top"><pre><code>term ::= term &quot;.&quot; ident | psCallHead &quot;(&quot; psCallArgs? &quot;)&quot;
psCallArgs ::= callArg (&quot;,&quot; callArg)* &quot;,&quot;?
callArg ::= term | ident &quot;:=&quot; term
// Unchanged field lookup; new comma-call postfix only</code></pre></td></tr></tbody></table>

**Side-by-side examples.**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>def stringLength (s : String) : Nat := s.length</code></pre></td><td valign="top"><pre><code>function stringLength(s: String): Nat := s.length
-- If mapped method exists: users.map(toName)</code></pre></td></tr></tbody></table>

**Source language distinction.** Both use *static, type-directed* field/method resolution, not JS prototype lookup. The `users.map(toName)` example presumes a visible admitted mapping and is illustrative, not a promise about every Standard library API.

### Single-term declaration body and local `where` definitions

**Feature / profile:** PSCV0 single-term body sugar; Lean-native `where` introducer  
**Original-source cross-check:** Ch. 8; A.8, A.12; Appendix B

**Lean 4 grammar family → ProofScript surface selection (schematic).**

**Lean source-fidelity:** the pinned [`Command.declValSimple`](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Parser/Command.lean#L188-L205) accepts a body, followed by a termination/fixpoint suffix, followed by optional `where` declarations. This order is preserved.

```text
psDeclTerm      ::= term | "{" term "}" -- one term, not statements
psDeclVal       ::= ":=" psDeclTerm psRecursionSuffix? psWhere?
psConstVal      ::= ":=" psDeclTerm psWhere? -- no recursion suffix
psRecursionSuffix ::= psTermination | "partial_fixpoint"
psWhere         ::= "where" "{" psLocalDeclaration+ "}"
                  | "where" "{" psLocalDeclaration* psSpecProofTail "}"
psLocalDeclaration ::= "def" ident psBinderSeq (":" term)? psLocalDeclVal
psLocalDeclVal  ::= ":=" psDeclTerm psRecursionSuffix?
psSpecProofTail ::= "finally" "{" "|" "spec" "=>" "{" psTacticSeq "}" "}"
```

A recursion suffix is reserved for selected `def`/`function` declarations and eligible local `where` definitions. It is not inherited by `const`, `theorem` or `opaque`. Local `partial_fixpoint` follows Lean's `Term.letRecDecl` recursion and mutual-clique checks; local `partial`/`unsafe` modifiers are not introduced by this rule. The `spec` section requires an eligible contract and cannot be used as a standalone local theorem.



**Side-by-side examples.**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>def plusOne (n : Nat) : Nat := helper n
where
  helper (x : Nat) : Nat := x + 1</code></pre></td><td valign="top"><pre><code>-- PSCV0: explicit local where with braced local definitions
function plusOne(n: Nat): Nat := helper(n)
where {
  def helper(x: Nat): Nat := x + 1
}</code></pre></td></tr></tbody></table>

**Source language distinction — `PSCV0-D-WHERE-01`.** The original source omitted `where` from its grammar; this edition retains Lean's introducer and selects `where { ... }`. The `def` keyword in `where { def helper(...) ... }` is an **owned ProofScript local-declaration introducer**, not a token retained in the generated Lean `where`. Lower `def helper(x: A, y: B): R := e` to native Lean `where helper (x : A) (y : B) : R := e'`, where `e'` is the recursively lowered term; remove the outer grouping braces, and preserve ordered binders, defaults, name resolution, recursion dependencies, and the selected `psTermination` suffix. Ordinary `where` holds newline-separated selected **local** definitions, not namespace/top-level `def` declarations. The initial profile does **not** admit local `function`/`const`, local theorem/instance/attribute/command forms, nested `where` in a local declaration, or `mutual` as independent local syntax. Recursive local definitions are accepted only when their selected 4.35.0 lowering and totality obligations can be discharged; no new local-recursion semantics is defined. **Exception: `PSCV0-CONTRACT-04`** permits one contract-owned terminal `finally { | spec => { psTacticSeq } }` in the same `where` block, possibly after local definitions. It is *not* a new standalone theorem, ordinary local declaration, or general `where finally` hook. If no intrinsic contract is present, a `spec` section is rejected. The compiler lowers this one section to 4.35.0 `where finally | spec => ...`, the mechanism by which the generated `f.spec` proof receives tactics (§7).

### Aliases and opacity: `abbrev` and `opaque`

**Feature / profile:** Shared Lean declaration families  
**Source basis:** Ch. 8, 17; A.2; Appendix I.5

**Lean 4 grammar family → ProofScript surface selection (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>command ::= &quot;abbrev&quot; declId declSig? declVal
          | &quot;opaque&quot; declId declSig declVal?</code></pre></td><td valign="top"><pre><code>command ::= &quot;abbrev&quot; declId psBinderSeq (&quot;:&quot; term)? psDeclVal
          | &quot;opaque&quot; declId psBinderSeq &quot;:&quot; term psDeclVal
// Intentional PSCV0 selection: an `opaque` must have an explicit right-hand-side body;
// native Lean's bodyless opaque alternative is excluded from initial .ps</code></pre></td></tr></tbody></table>

**Side-by-side examples.**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>abbrev UserId := Nat
opaque secret : Nat := 42</code></pre></td><td valign="top"><pre><code>abbrev UserId := Nat
opaque secret: Nat := 42</code></pre></td></tr></tbody></table>

**Source language distinction.** `abbrev` remains definitionally reducible in the permitted Lean transparency contexts, whereas `opaque` does not unfold under ordinary source conversion. The initial `.ps` profile admits **only body-present** `opaque name: T := value`, not native Lean's separately supported bodyless `opaque name : T`. This choice excludes an unnecessary unimplemented assumption-like declaration form. In PSCV, a public executable `opaque` declaration still needs approved specification coverage and proof evidence; the source form is not an exemption from validity. Public bodies are not automatically exposed to downstream module elaboration (§1).

### Visibility: `private` and declarations exported through modules

**Feature / profile:** Shared visibility concept, PS constrained module surface  
**Source basis:** Ch. 6–7; A.2

**Lean 4 grammar family → ProofScript surface selection (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>modifiers ::= docComment? attributes? visibility? ...
visibility ::= &quot;private&quot; | &quot;public&quot;</code></pre></td><td valign="top"><pre><code>psModifiers ::= psAttributes? &quot;private&quot;? &quot;noncomputable&quot;?
command ::= psModifiers? selectedPsDeclaration
// `noncomputable` is admitted ONLY for selected proof/spec def/function (§5)
// Deliberately restricted modifiers, not unconditional Lean alternatives</code></pre></td></tr></tbody></table>

**Side-by-side examples.**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>private def secret : Nat := 7
def publicValue : Nat := 3</code></pre></td><td valign="top"><pre><code>private const secret: Nat := 7
const publicValue: Nat := 3</code></pre></td></tr></tbody></table>

**Source language distinction.** ProofScript ordinary top-level declarations are public unless `private`; a `.ps` module lowers to 4.35.0 module mode with an implicit `public section` (or equivalent per-declaration public modifiers), while normal module imports remain private to the importing module and `public import` re-exports their public scope. **Only name visibility is public by default; definitional unfolding of public bodies across modules is not.** A client must use exported checked theorems or a future reviewed exposure facility. No TypeScript declaration merging or selective-export syntax is provided. See `PSCV0-MODULE-01/02` (§1).

## 3. Type theory, expressions, and everyday data

### `Prop`, `Type`, `Sort`, universes and dependent Pi

**Feature / profile:** Shared core logic  
**Source basis:** Ch. 4, 9, 16; A.6; Appendix I

**Lean 4 grammar family → ProofScript surface selection (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>term ::= &quot;Prop&quot; | &quot;Type&quot; level? | &quot;Sort&quot; level
     | &quot;(&quot; ident &quot;:&quot; term &quot;)&quot; &quot;→&quot; term
     | term &quot;→&quot; term</code></pre></td><td valign="top"><pre><code>term ::= &quot;Prop&quot; | &quot;Type&quot; level? | &quot;Sort&quot; level
     | &quot;(&quot; ident &quot;:&quot; term &quot;)&quot; (&quot;→&quot; | &quot;-&gt;&quot;) term
     | term (&quot;→&quot; | &quot;-&gt;&quot;) term
// No new universe or Pi forms</code></pre></td></tr></tbody></table>

**Side-by-side examples.**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>universe u
def id {α : Type u} (x : α) : α := x
-- Dependent result type: (n : Nat) → Fin n → Nat</code></pre></td><td valign="top"><pre><code>universe u
function id {α: Type u}(x: α): α := x
-- Dependent result type: (n: Nat) -&gt; Fin n -&gt; Nat</code></pre></td></tr></tbody></table>

**Source language distinction.** `Prop = Sort 0`, `Type u = Sort (u+1)`. Function arrows denote dependent Pi. The result type may reference prior arguments. The source grammar for universe-level terms is delegated to a pinned Lean parser category (not fully expanded in the uploaded text).

### Lambda terms, type ascription, and `let`

**Feature / profile:** Shared term families; PS tighter layout  
**Source basis:** Ch. 9–10; A.6

**Lean 4 grammar family → ProofScript surface selection (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>term ::= &quot;fun&quot; binder+ &quot;=&gt;&quot; term
     | &quot;(&quot; term &quot;:&quot; term &quot;)&quot;
     | &quot;let&quot; ident (&quot;:&quot; term)? &quot;:=&quot; term separator term</code></pre></td><td valign="top"><pre><code>term ::= &quot;fun&quot; psLambdaBinder+ &quot;=&gt;&quot; term
     | &quot;(&quot; term &quot;:&quot; term &quot;)&quot;
     | &quot;let&quot; ident (&quot;:&quot; term)? &quot;:=&quot; term separator term
psLambdaBinder ::= selectedLeanFunBinder
// selectedLeanFunBinder = the admitted 4.35.0 Lean.Parser.Term.funBinder cases;
// Native name, typed binder, and selected implicit/strict/instance forms;
// NOT declaration comma `psExplicitGroup` or JS arrow-lambda grammar</code></pre></td></tr></tbody></table>

**Side-by-side examples.**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>def increment : Nat → Nat := fun n =&gt; n + 1

def two : Nat :=
  let x := 1
  x + 1</code></pre></td><td valign="top"><pre><code>const increment: Nat -&gt; Nat := fun n =&gt; n + 1

function two(): Nat := {
  let x := 1
  x + 1
}</code></pre></td></tr></tbody></table>

**Source language distinction — lambda binder ownership.** Lambdas retain the native Lean `fun ... => ...` spelling rather than TypeScript's bare `x => ...`. The `psLambdaBinder` name above selects Lean 4.35.0's `Lean.Parser.Term.funBinder` in the admitted term/binder profile; it is **not** a hidden alias for the comma-grouped **declaration** production `psExplicitGroup`. Thus `fun x => x` and `fun (x: Nat) => x` retain native binder meaning; a new declaration-style `fun (x: Nat, y: Nat) => ...` comma-binder syntax is **not** introduced by this document. The source-empty `function f()`/required-Unit rule applies only to named functions and does not reinterpret lambdas. `let` has immutable logical meaning. In ProofScript a `let ...` followed by its body is **one term**, not a general statement list. The `TermBodySep` is a completed-value newline.

### Natural/scientific/string/char/Boolean/Unit literals

**Feature / profile:** Shared token families, constrained PS elaboration  
**Source basis:** Ch. 5, 22.2, 24.3; A.3, A.6

**Lean 4 grammar family → ProofScript surface selection (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>term ::= Lean.numeral | Lean.scientific | Lean.string
     | Lean.char | &quot;true&quot; | &quot;false&quot; | &quot;()&quot;</code></pre></td><td valign="top"><pre><code>term ::= Lean.numeral | Lean.scientific | Lean.string
     | Lean.char | &quot;true&quot; | &quot;false&quot; | &quot;()&quot;
// Lexical classes and overloaded numeral semantics inherited</code></pre></td></tr></tbody></table>

**Side-by-side examples.**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>def count : Nat := 42
def fraction : Float := 1.25
def text : String := &quot;Ada&quot;
def enabled : Bool := true
def letter : Char := &#x27;A&#x27;
def empty : Unit := ()</code></pre></td><td valign="top"><pre><code>const count: Nat := 42
const fraction: Float := 1.25
const text: String := &quot;Ada&quot;
const enabled: Bool := true
const letter: Char := &#x27;A&#x27;
const empty: Unit := ()</code></pre></td></tr></tbody></table>

**Source language distinction.** Token scanners are pinned Lean families. Numeric meaning is type-directed by instances; defaulting can select `Nat`, `Float` or an applicable signed type under the ProofScript Standard environment. The uploaded reference says its Lean-4.35-rc3 manifest/digest is still pending; no finalized registry is implied.

### Native interpolated/raw strings and string formatting

`pscv0` now requires Lean's **native** `s!"...{expr}..."` interpolation and raw-string lexical family `r"..."`, `r#"..."#` (with matching delimiter hashes), alongside ordinary escaped strings. No additional TypeScript template literal or `String.raw` grammar is introduced.

| Lean 4 | `pscv0` |
|---|---|
| `def greeting (name : String) : String := s!"Hello, {name}!"` | `function greeting(name: String): String := s!"Hello, {name}!"` |
| `def path : String := r#"C:\tmp\"quoted"#` | `const path: String := r#"C:\tmp\"quoted"#` |

Interpolation requires the pinned `ToString` behavior and parses `{expr}` with the same `.ps` expression grammar, including `f (x)` rejection. Raw-string contents are **not** parsed as terms. String conversion is typeclass-directed, not unrestricted JavaScript coercion. The exact 4.35.0 lexer/parser and initial `ToString` instances must be part of the environment conformance suite. [Lean strings](https://lean-lang.org/doc/reference/4.35.0/Basic-Types/Strings/).

### Native collection literals and bounds-aware indexing

`pscv0` guarantees Lean-native `List` literals `[x, y]`, `Array` literals `#[x, y]`, and the standard `GetElem` lookup variants. This is an admission of **existing Lean syntax**; it does not infer an array type from an untyped JavaScript object literal.

| Notation | Meaning in `pscv0` | Verification consequence |
|---|---|---|
| `xs[i]` | Lean `GetElem`; requires `valid xs i` proof | proof side-condition must be discharged (or type-checking fails) |
| `xs[i]'h` | Lean lookup with explicit proof `h : valid xs i` | checked evidence supplied explicitly |
| `xs[i]?` | optional `Option α` lookup | no required in-bounds proof; handle `none` |
| `xs[i]!` | panic/default `GetElem?` path | **not** bounds-safe proof; may panic at runtime |
| `#[a, b]` | `Array` literal | retains Lean array semantics |
| `[a, b]` | `List` literal under admitted expected type/notation | retains inductive list meaning |

```proofscript
function lookup(xs: Array Nat, i: Nat): Option Nat := xs[i]?

function readChecked(xs: Array Nat, i: Nat, h: i < xs.size): Nat := {
  xs[i]'h
}

#check lookup
#eval lookup(#[10, 20], 1)  -- some 20
```

`GetElem` class instances, `get_elem_tactic` behavior, and any source-derived proof discharge paths must be pinned and are **not** replaced by unchecked JavaScript indexing. A verified closure must reject unresolved index validity proofs; the `!` operator's panic/default path is a behavior to model explicitly if admitted, not a proof of bounds. [Lean basic classes / GetElem](https://lean-lang.org/doc/reference/4.35.0/Type-Classes/Basic-Classes/), [arrays](https://lean-lang.org/doc/reference/4.35.0/Basic-Types/Arrays/).

### Tuples/products and explicit grouping

**Feature / profile:** Shared product semantics; PSCV0 sugar tuple comma policy  
**Source basis:** Ch. 10, 26; A.6; Appendix B

**Lean 4 grammar family → ProofScript surface selection (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>term ::= &quot;(&quot; term &quot;)&quot; | &quot;(&quot; term &quot;,&quot; term (&quot;,&quot; term)* &quot;)&quot;</code></pre></td><td valign="top"><pre><code>term ::= &quot;(&quot; term &quot;)&quot; | &quot;(&quot; term &quot;,&quot; term (&quot;,&quot; term)* &quot;,&quot;? &quot;)&quot;
// Tuple is one term; f((x,y)) passes one tuple in comma-call</code></pre></td></tr></tbody></table>

**Side-by-side examples.**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>def pair : Nat × Bool := (4, true)
def left : Nat := pair.1</code></pre></td><td valign="top"><pre><code>const pair: Nat × Bool := (4, true,)
const left: Nat := Prod.fst(pair)</code></pre></td></tr></tbody></table>

**Source language distinction.** ProofScript tuple terms require **at least two elements**, mandatory commas between elements, and allow one trailing comma. Type-level products are still `Prod`/`×`, not TypeScript tuples. Direct `.1` numeric projection syntax is Lean; ProofScript’s `FieldSuffix` grammar requires an **Identifier** and does not explicitly promise numeric projections—use `Prod.fst(pair)` in ProofScript if available, or named structures.

### Propositions, quantifiers, proof versus Boolean equality

**Lean family:** the same native `Prop` declarations, Pi quantifier and `Exists` notation. **`pscv0` rule:** adopt the native spelling families intact: ASCII forms are not newly invented fallback grammar, and Unicode forms are first-class source syntax. The context decides whether an expression is a `Prop` or `Bool`.

| Lean 4.35.0 | ProofScript `pscv0` |
|---|---|
| `theorem same (n : Nat) : n = n := by rfl` | `theorem same(n: Nat): n = n := by { rfl }` |
| `example : ∃ n : Nat, n = 0 := ⟨0, rfl⟩` | `example : exists n : Nat, n = 0 := by { exact ⟨0, rfl⟩ }` |
| `example : ∀ n : Nat, n = n := by intro n; rfl` | <code>example : forall n : Nat, n = n := by { intro n&#10;  rfl&#10;}</code> (illustrative layout) |

#### Native mathematical symbol and text pairs

| Mathematical spelling | Lean-native textual / term equivalent | `pscv0` acceptance | Semantics / caution |
|---|---|---|---|
| `∀ x : A, P x` | `forall x : A, P x` | **both** | dependent Pi / universal quantifier |
| `∃ x : A, P x` | `exists x : A, P x` | **both** | `Exists`; the keyword is **`exists`**, not `exist` |
| `∃! x : A, P x` | `ExistsUnique(fun x : A => P x)` | when available in pinned Standard environment | unique existence; do not invent an `existUnique` keyword |
| `λ x => body` | `fun x => body` | **both** | ordinary lambda |
| `A → B` | `A -> B` | **both** | (non)dependent Pi arrow |
| `P ∧ Q` | `And P Q` | **both** | logical and, not Boolean `&&` |
| `P ∨ Q` | `Or P Q` | **both** | logical or, not Boolean `\|\|` |
| `¬ P` | `Not P` | **both** | logical negation, not Boolean `!` |
| `P ↔ Q` | `Iff P Q` | **both** | logical equivalence |
| `a ≠ b` | `a = b → False` | standard not-equal notation | proposition; **different from** Boolean `!=` |
| `a ≤ b` | `a <= b` | **both** where a typeclass instance exists | proposition-valued comparison |
| `a ≥ b` | `a >= b` | **both** where a typeclass instance exists | proposition-valued comparison |
| `A × B` | `Prod A B` | **both** | ordinary product type |
| `Σ x : A, B x` | `Sigma(fun x : A => B x)` | both only when admitted library/profile provides `Sigma` | dependent data pair |
| `⟨a, h⟩` | type-directed constructor term | admit Lean constructor notation | useful for `Subtype`, `Exists`, structures |
| `x ∈ s`, `x ∉ s` | Lean membership/not-membership notation | admit **only if** required library/instances are present | do not globally invent set syntax |

**Application-spelling note:** The textual `ExistsUnique(fun ...)` and `Sigma(fun ...)` entries above are *PSCV0-safe adaptations* of native Lean `ExistsUnique (fun ...)` / `Sigma (fun ...)`; they preserve the same Lean application while respecting `PSCV0-APP-02`. No Lean-only gap-parenthesized application spelling is implicitly admitted into `.ps` through a comparison table.

**Token policy:** Unicode notation and existing Lean ASCII forms are **native aliases**, not unnecessary ProofScript sugar. Textual constant applications such as `And P Q` are Lean expressions, not extra infix keywords `and`/`or`. The singular `exist` is not an accepted quantifier. `=` is propositional equality, while `==` is Boolean equality through `BEq`; `≠` and `!=` are not interchangeable. Native input shortcuts (`\forall`, `\exists`, `\l`, `\to`, etc.) are editor conveniences, not source-token alternates.

**Relevant Lean docs:** [Quantifiers](https://lean-lang.org/doc/reference/4.35.0/Basic-Propositions/Quantifiers/), [Subtype](https://lean-lang.org/doc/reference/4.35.0/Basic-Types/Subtypes/), [The Tactic Language](https://lean-lang.org/doc/reference/4.35.0/Tactic-Proofs/The-Tactic-Language/).

### Boolean/propositional `if`, dependent `if`, and `if let`

**Lean family:** `ite`, dependent `dite`, and native pattern-matching conditional `if let`. **`pscv0` modification:** one braced conditional spelling, without TypeScript truthiness or unbraced `then`/`else` variants in `.ps`. The Lean `.lean` source column retains native spelling. The binder `h : P` is a **proof binder**, not a spaced function-call argument.

| Lean 4.35.0 | `pscv0` canonical form |
|---|---|
| `if b then 1 else 0` | `if (b) { 1 } else { 0 }` |
| `if h : i < xs.size then some xs[i]'h else none` | `if (h : i < xs.size) { some(xs[i]'h) } else { none }` |
| `if let some n := value then n else 0` | `if let .some n := value { n } else { 0 }` |

**Lean 4 grammar (schematic):**

```text
term ::= ... | 'if' condition 'then' term 'else' term
            | 'if' binderIdent ':' condition 'then' term 'else' term
            | 'if' 'let' pattern ':=' term 'then' term 'else' term
```

**`pscv0` modification (schematic):**

```text
term ::= ... | 'if' '(' term ')' '{' term '}' 'else' '{' term '}'
            | 'if' '(' binderIdent ':' term ')' '{' term '}' 'else' '{' term '}'
            | 'if' 'let' selectedLeanPattern ':=' term
                    '{' term '}' 'else' '{' term '}'
```

**Context:** `if let` in a **term** uses one term per branch and requires `else`; `if let` in a **`doSeqItem`** uses selected `do`-sequence branches and may omit `else`. These are separate Lean parser categories and must not be conflated (§3 base do, `PSCV0-DO-IF-01`).

`if let` is not a duplicate of an ordinary Boolean condition; it **binds the pattern's variables in the successful branch**, expanding to Lean `match ... with | pattern => ... | _ => ...`. The dependent `if (h : P)` form provides `h : P` to the first branch and `h : ¬P` to the second, as Lean's `dite` does. Ordinary `if` accepts `Bool` or decidable `Prop` according to the Lean-grounded elaboration rules, without JS truthiness. The body braces each enclose **one term**, not a statement list.

**Proposed `pscv0` example:**

```proofscript
function fromOption(x: Option Nat): Nat := {
  if let .some n := x {
    n
  } else {
    0
  }
}
```

**Important:** `if p then a else b` continues to be **invalid `.ps` conditional syntax**; it is not silently re-enabled by the new Lean-first feature selection. A parsed `if` in a proof tactic (as opposed to a term) remains a distinct *tactic* grammar category subject to the pinned tactic environment. [Lean conditionals](https://lean-lang.org/doc/reference/4.35.0/Terms/Conditionals/).

### `nomatch`, `matches`, and term-level pattern bindings

Lean's `nomatch e` constructs a value from an impossible case only when exhaustiveness proves the absence of alternatives. `e matches p` is a Boolean pattern test, not a general dynamic cast. Adopt both native term forms, subject to the selected pattern grammar and checked Lean elaboration. Pattern `let` bindings are admitted where Lean can determine an irrefutable or properly handled pattern; do not allow silent runtime match failure.

| Lean 4.35.0 | `pscv0` |
|---|---|
| `def impossible (e : Empty) : Nat := nomatch e` | `function impossible(e: Empty): Nat := nomatch e` |
| `def isSome (x : Option Nat) : Bool := x matches some _` | `function isSome(x: Option Nat): Bool := x matches .some _` |
| native pattern `let` in a supported term or `do` context | same selected Lean binding grammar inside canonical `.ps` braces |

There is no new `as`, `typeof`, structural-union narrowing, or unsafe cast syntax. The pattern's constructor families are checked against the scrutinee's admitted Lean type, and impossible matches must truly be empty. [Lean pattern matching](https://lean-lang.org/doc/reference/4.35.0/Terms/Pattern-Matching/).

### Base `do`: monadic bind, simple `let`, `pure`, `return`

**Feature / profile:** Shared monadic semantics; a selected Lean `do` grammar subset  
**Source basis:** Ch. 10 (basic do); A.14; Appendix B

**Lean 4 grammar family → ProofScript surface selection (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>term ::= &quot;do&quot; doSeq
doSeqItem ::= &quot;let&quot; ident &quot;:=&quot; term | &quot;let&quot; ident &quot;←&quot; term
            | term | &quot;return&quot; term | ...</code></pre></td><td valign="top"><pre><code>term ::= &quot;do&quot; &quot;{&quot; psDoSeq &quot;}&quot;
psDoItem ::= &quot;let&quot; ident &quot;:=&quot; term
           | &quot;let&quot; ident &quot;←&quot; term | term | &quot;return&quot; term
           | psDoIf | psDoIfLet
psDoCondition ::= Lean.Parser.Term.binderIdent &quot;:&quot; term | term
psDoIf ::= &quot;if&quot; &quot;(&quot; psDoCondition &quot;)&quot; &quot;{&quot; psDoSeq &quot;}&quot;
           (&quot;else&quot; &quot;{&quot; psDoSeq &quot;}&quot;)?
psDoIfLet ::= &quot;if let&quot; selectedLeanPattern &quot;:=&quot; term
              &quot;{&quot; psDoSeq &quot;}&quot; (&quot;else&quot; &quot;{&quot; psDoSeq &quot;}&quot;)?
// Distinct from one-term conditional; preserves Lean `doIf`/`doSeq` elaboration</code></pre></td></tr></tbody></table>

**Side-by-side examples.**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>def compute : Id Nat := do
  let x ← pure 1
  pure (x + 1)</code></pre></td><td valign="top"><pre><code>function compute(): Id Nat := do {
  let x ← pure 1
  pure(x + 1)
}</code></pre></td></tr></tbody></table>

**Source language distinction — `PSCV0-DO-IF-01`.** This is **base ProofScript** (`PSCV0`) syntax, distinct from richer verified `do`. Besides term statements, immutable `let`, monadic bind and `pure`/`return`, the initial source selection admits native-Lean-grounded **`do` statement conditionals** with braced `psDoSeq` branches: `if (c) { action1; action2 }` in *schematic* notation (actual `.ps` statements are separated by **newlines**, never literal `;`), and `if let .some x := v { ... }`. `else` is optional for do-level control where Lean's typing and monadic sequencing permit it; it is mandatory for the one-term expression `if` of §3. An `if` in a `do` statement position selects `psDoIf`/`psDoIfLet`; one inside a term expected to return a value selects the term grammar. **`psDoCondition` is either a named proof binder plus proposition written `h : P`, or an ordinary selected condition term (`Bool` or decidable `Prop` as allowed by Lean). The named-binder alternative takes precedence when the next nontrivia token after a `binderIdent` is `:` (ordinary spaces are allowed); otherwise the ordinary term alternative is used, as in the pinned `doIfProp` parser.** Hence `if (h : i < xs.size) { ... }` is an admitted `do` condition and `h` has the corresponding Lean proof scope in its branches; this is **not** an extra term-call parameter group. This is the selected braced translation of 4.35.0 `doIfProp`, not a new verification axiom. The distinct `if let` form initially admits `:=` (pattern binding in the success branch); 4.35.0's `if let p ← action` remains outside this initial selection until specified separately. Nested `do` and pattern binding still use the pinned elaborator; no JS mutable-scoping rules are added. Standard source uses LF-separated `doSeqItem`s rather than general semicolons.

**Conditional `do` example (PSCV0 source sketch):**

```proofscript
function countPositive(xs: List Nat): Id Nat := do {
  let mut count := 0
  for x in xs {
    if (x > 0) {
      count := count + 1
    }
  }
  return count
}
```

**Named proof-binder in a `do` conditional (schematic; no compiler claim):**

```proofscript
function readIfValid(xs: Array Nat, i: Nat): Id(Option Nat) := do {
  if (h : i < xs.size) {
    return some(xs[i]'h)
  } else {
    return none
  }
}
```

The `h` binder is part of the condition, not a function argument. The exact `GetElem` proof and `Decidable` environment are assumed in this design fixture. Both examples are unexecuted; their `ForIn`, comparison, and indexing instances require the pinned environment.

### Type-directed coercions

**Feature / profile:** Shared class-based coercions; PS deterministic bounded algorithm  
**Source basis:** Ch. 12, 16.7, 22.10; A.12

**Lean 4 grammar family → ProofScript surface selection (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>command ::= &quot;instance&quot; declSig declVal
term ::= term | ...  // coercions are type-directed, not term syntax</code></pre></td><td valign="top"><pre><code>command ::= &quot;instance&quot; psPriority? psInstanceHeader
            &quot;where&quot; &quot;{&quot; psInstanceFields &quot;}&quot;
term ::= selectedLeanTerm  // no extra cast syntax
// Coercions limited by selected Lean instance environment</code></pre></td></tr></tbody></table>

**Side-by-side examples.**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>structure Wrapped where
  value : Nat
instance : Coe Wrapped Nat where
  coe x := x.value</code></pre></td><td valign="top"><pre><code>structure Wrapped where {
  value: Nat
}
instance : Coe Wrapped Nat where {
  coe(x: Wrapped): Nat := x.value
}</code></pre></td></tr></tbody></table>

**Source language distinction.** Coercions are **compile-time/type-directed** insertion, not runtime casts or JS coercion. ProofScript Standard may try one direct ordinary coercion, `CoeFun` to function, or `CoeSort` to sort; it excludes arbitrary chains and implicit auto-lifting. The actual instance declarations must belong to the visible bounded Standard registry.

## 4. Structures, records, classes, and algebraic data

### Structure declarations

**Feature / profile:** Shared structures; PSCV0 sugar outer braces  
**Source basis:** Ch. 11; A.2, A.10; Appendix B

**Lean 4 grammar family → ProofScript surface selection (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>command ::= &quot;structure&quot; declId declSig? (&quot;where&quot; structFields)?
structFields ::= structField*  // indentation-sensitive</code></pre></td><td valign="top"><pre><code>command ::= &quot;structure&quot; declId psBinderSeq &quot;where&quot; &quot;{&quot; structFields &quot;}&quot; psDerivingClause?
// Reuse Lean&#x27;s structField, structFields, dependent field checking
// Modification: braces delimit fields; optional allowlisted trailing deriving
// `psDerivingClause` is defined by PSCV0-DERIVE-01 below</code></pre></td></tr></tbody></table>

**Side-by-side examples.**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>structure User where
  id : Nat
  name : String
  active : Bool</code></pre></td><td valign="top"><pre><code>structure User where {
  id: Nat
  name: String
  active: Bool
}</code></pre></td></tr></tbody></table>

**Source language distinction.** Both have nominal structure types and Lean-grounded fields. Structure **declaration fields are not comma-separated** in ProofScript; braces only group the Lean-like layout fields. Commas belong in structure **values**, not declarations.

### Record construction and record updates

**Feature / profile:** Shared record syntax under tighter ProofScript elaboration  
**Source basis:** Ch. 11; A.6, A.10

**Lean 4 grammar family → ProofScript surface selection (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>term ::= &quot;{&quot; structInstField (&quot;,&quot; structInstField)* &quot;}&quot;
     | &quot;{&quot; term &quot;with&quot; structInstField (&quot;,&quot; structInstField)* &quot;}&quot;
// Lean also supports inferred shorthand, omitted fields and type annotation</code></pre></td><td valign="top"><pre><code>term ::= &quot;{&quot; psRecordField (&quot;,&quot; psRecordField)* &quot;,&quot;? &quot;}&quot;
     | &quot;{&quot; term &quot;with&quot; psRecordField (&quot;,&quot; psRecordField)* &quot;,&quot;? &quot;}&quot;
psRecordField ::= ident &quot;:=&quot; term
// Same nominal Lean structure, stricter field syntax</code></pre></td></tr></tbody></table>

**Side-by-side examples.**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>def alice : User := { id := 1, name := &quot;Alice&quot;, active := false }
def activate (u : User) : User := { u with active := true }</code></pre></td><td valign="top"><pre><code>const alice: User := {
  id := 1,
  name := &quot;Alice&quot;,
  active := false,
}
function activate(u: User): User := {
  { u with active := true }
}</code></pre></td></tr></tbody></table>

**Source language distinction.** Record **values** and updates require commas between fields and allow a final comma. ProofScript requires an expected structure type to elaborate a record construction and permits defaults only if declared; it does not guess a shape or fill missing fields through `Inhabited`. Dependent updates must type-check after reconstruction.

### Projections and static method selection

**Feature / profile:** Shared  
**Source basis:** Ch. 11, 22.11; A.6

**Lean 4 grammar family → ProofScript surface selection (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>term ::= term &quot;.&quot; ident | ...
// Lean generalized field notation; same structure projections</code></pre></td><td valign="top"><pre><code>term ::= term &quot;.&quot; ident
     | term &quot;.&quot; ident &quot;(&quot; psCallArgs? &quot;)&quot;
// Call postfix is PSCV0 sugar; resolution stays static</code></pre></td></tr></tbody></table>

**Side-by-side examples.**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>def nameOf (u : User) : String := u.name</code></pre></td><td valign="top"><pre><code>function nameOf(u: User): String := u.name</code></pre></td></tr></tbody></table>

**Source language distinction.** Both resolve a declared structure field statically. ProofScript's static generalized field search is deterministic, and method-call parentheses remain adjacency-sensitive.

### Classes and typeclass instances

**Feature / profile:** Shared typeclass semantics; PS outer-brace grammar  
**Source basis:** Ch. 12; A.2, A.10, A.12

**Lean 4 grammar family → ProofScript surface selection (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>command ::= &quot;class&quot; declId declSig? &quot;where&quot; structFields
          | &quot;instance&quot; declSig &quot;where&quot; structInstFields</code></pre></td><td valign="top"><pre><code>command ::= &quot;class&quot; declId psBinderSeq &quot;where&quot; &quot;{&quot; structFields &quot;}&quot;
          | &quot;instance&quot; psPriority? psInstanceHeader
            &quot;where&quot; &quot;{&quot; psInstanceFields &quot;}&quot;
psInstanceFields ::= (psInstanceField on separate source lines)*
psInstanceField ::= ident psBinderSeq? (&quot;:&quot; term)? &quot;:=&quot; term
// Field headers lower to Lean structure-instance declaration fields, not postfix calls
// Native value-form `instance ... := term` is outside initial PSCV0 Standard</code></pre></td></tr></tbody></table>

**Side-by-side examples.**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>class Sized (α : Type) where
  size : α → Nat

instance : Sized String where
  size s := s.length</code></pre></td><td valign="top"><pre><code>class Sized(α: Type) where {
  size: α -&gt; Nat
}

instance : Sized String where {
  size(s: String): Nat := s.length
}</code></pre></td></tr></tbody></table>

**Source language distinction — `PSCV0-INSTANCE-01`.** Classes are Lean typeclasses, **not** OO classes. Class fields retain Lean layout, while instance fields are **newline-only declaration fields** (no commas/semicolons) with ordered binders, optional dependent result type and one term body. Thus `size(s: String): Nat := ...` is a *field-declaration header*, not a call expression; it lowers to Lean `size (s : String) : Nat := ...`. Named/anonymous instance headers both use `psInstanceHeader ::= declId? psBinderSeq ":" term` (defined once in §4 below): the optional name precedes the binders, and the colon plus class/type term is mandatory. This is a **declaration header**, not a call; it never receives the `function f()` hidden-`Unit` rule. Initial Standard deliberately **excludes** the native value-form `instance ... := term` and supports only `instance ... where { ... }`; this must be reflected in grammar-negative tests. Lean additionally has forms outside this closed selection.

### Instance-implicit arguments and instance priorities

**Feature / profile:** Shared binders; PS deterministic instance resolution  
**Source basis:** Ch. 12, 22.9; A.2

**Lean 4 grammar family → ProofScript surface selection (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>binder ::= &quot;[&quot; term &quot;]&quot;
command ::= &quot;instance&quot; Lean.Command.optNamedPrio
            declSig &quot;where&quot; structInstFields
// Lean.namedPrio delegates its value to Lean.priorityParser</code></pre></td><td valign="top"><pre><code>binder ::= Lean.instBinder
command ::= &quot;instance&quot; psPriority? psInstanceHeader
            &quot;where&quot; &quot;{&quot; psInstanceFields &quot;}&quot;
psInstanceHeader ::= declId? psBinderSeq &quot;:&quot; term
psPriority ::= &quot;(&quot; &quot;priority&quot; &quot;:=&quot; psPriorityAtom &quot;)&quot;
psPriorityAtom ::= decimalNat | &quot;low&quot; | &quot;mid&quot; | &quot;default&quot; | &quot;high&quot;
// The optional instance name precedes its binder telescope.
// A command modifier, never a call or ordinary binder;
// arithmetic/prio macros remain outside this initial PSCV0 subset</code></pre></td></tr></tbody></table>

**Side-by-side examples.**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>def sizeOf {α : Type} [Sized α] (x : α) : Nat :=
  Sized.size x</code></pre></td><td valign="top"><pre><code>function sizeOf {α: Type}[Sized α](x: α): Nat := {
  Sized.size(x)
}</code></pre></td></tr></tbody></table>

**Source language distinction — `PSCV0-INSTANCE-PRIO-01` / `PSCV0-INSTANCE-HDR-01`.** Instance-implicit Pi binders work in both. Under `PSCV0-INSTANCE-HDR-01`, `instance : C T where { ... }` is anonymous, whereas `instance chosen : C T where { ... }` names the declaration; `instance (priority := high) chosen : C T where { ... }` also admits the selected priority modifier. `declId` can carry an admissible Lean universe suffix, while an omitted colon/type or a `()` binder is rejected at PARSE. Names, binder order, and type inference follow the selected Lean declaration semantics, with no special nullary lowering. 4.35.0's native `instance (priority := value)` modifier is a **command-head category**, not an application or parameter. The initial `.ps` selection admits a nonnegative decimal natural literal, `low`, `mid`, `default`, and `high` with pinned values `100`, `500`, `1000`, `10000`; absence of a modifier uses native `default = 1000`. Literal numbers outside those four named bands are admitted and preserve their numeric priority. 4.35.0 also parses priority arithmetic such as `high + 1`, but Standard `.ps` **deliberately excludes** it initially; do not imply full `Lean.priorityParser` admission from the Lean pin. ProofScript freezes candidate order (lexical locals before prioritized visible globals) and uses this same numeric ordering for admitted global priorities. The spacing in `instance (priority := high)` is native **modifier syntax** and is exempt from `PSCV0-APP-02`. This is a source-observable constraint, not a new `class` syntax. [Pinned 4.35.0 priority parser](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Parser/Command.lean) and [named values](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Notation.lean).

### Law fields in classes and structures

**Feature / profile:** Shared expressivity; PSCV0 encourages verified abstractions  
**Source basis:** Ch. 12 (`pscv.class.laws`)

**Lean 4 grammar family → ProofScript surface selection (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>command ::= &quot;class&quot; declId declSig? &quot;where&quot; structFields
structField ::= ident &quot;:&quot; term | ...</code></pre></td><td valign="top"><pre><code>command ::= &quot;class&quot; declId psBinderSeq &quot;where&quot; &quot;{&quot; structFields &quot;}&quot;
structField ::= Lean.structField
// Law: any field with a Prop-typed result, checked by Lean</code></pre></td></tr></tbody></table>

**Side-by-side examples.**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>class IdentityCodec (α : Type) where
  encode : α → α
  roundTrip : ∀ x : α, encode x = x</code></pre></td><td valign="top"><pre><code>class IdentityCodec(α: Type) where {
  encode: α -&gt; α
  roundTrip: forall x : α, encode(x) = x
}</code></pre></td></tr></tbody></table>

**Source language distinction.** A law is an ordinary field of a proposition type. An instance must supply proof evidence for it just as it supplies executable operations; this adds no novel kernel primitive.

### Inductive types and constructor declarations

**Feature / profile:** Shared inductive theory; PS constructor/header grammar  
**Source basis:** Ch. 13; A.2, A.11

**Lean 4 grammar family → ProofScript surface selection (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>command ::= &quot;inductive&quot; declId declSig? &quot;where&quot; ctor*
ctor ::= &quot;|&quot; ident binder* (&quot;:&quot; term)?</code></pre></td><td valign="top"><pre><code>command ::= &quot;inductive&quot; declId psBinderSeq (&quot;:&quot; term)?
            &quot;where&quot; &quot;{&quot; psCtor* &quot;}&quot; psDerivingClause?
psCtor ::= &quot;|&quot; ident psBinderSeq (&quot;:&quot; term)?
// Use the closed, ordered PSCV0 declaration-binder selection; no unrestricted Lean.binder.
// The optional constructor result type supports both ordinary and indexed inductives.
// Constructors checked by Lean inductive type checker
// Optional trailing clause follows PSCV0-DERIVE-01</code></pre></td></tr></tbody></table>

**Side-by-side examples.**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>inductive Outcome (ε : Type) (α : Type) where
  | ok (value : α)
  | error (error : ε)</code></pre></td><td valign="top"><pre><code>inductive Outcome(ε: Type, α: Type) where {
  | ok(value: α)
  | error(error: ε)
}</code></pre></td></tr></tbody></table>

**Source language distinction.** ProofScript uses a comma-grouped parameter telescope and *canonically* braces the `|` alternatives. The `.ps` grammar requires the selected braced form; ordinary `.lean` syntax retains native Lean layout. Constructor fields reuse unified explicit parameter groups. Strict positivity, parameters/indices, and recursors remain Lean-grounded; this is still not Lean’s unrestricted equation compiler.

### Qualified and shorthand constructors

**Feature / profile:** Shared constructor semantics; PSCV0 sugar call suffix  
**Source basis:** Ch. 13; A.6; [elab.constructor]

**Lean 4 grammar family → ProofScript surface selection (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>term ::= ident argument* | &quot;.&quot; ident argument* | ...
// Elaborator resolves anonymous-namespace constructor notation</code></pre></td><td valign="top"><pre><code>term ::= ident &quot;(&quot; psCallArgs? &quot;)&quot;
     | &quot;.&quot; ident &quot;(&quot; psCallArgs? &quot;)&quot;
     | selectedLeanConstructorTerm
// Both lower to ordinary Lean constructor applications</code></pre></td></tr></tbody></table>

**Side-by-side examples.**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>def ok : Outcome String Nat := Outcome.ok 42
def short : Outcome String Nat := .ok 42</code></pre></td><td valign="top"><pre><code>const ok: Outcome String Nat := Outcome.ok(42)
const short: Outcome String Nat := .ok(42)</code></pre></td></tr></tbody></table>

**Source language distinction.** Shorthand requires a known expected inductive type and a uniquely determined constructor. Neither language thereby uses dynamic enum-string dispatch.

### Native `deriving` and checked generated instances

**`PSCV0-DERIVE-01` (P0, normative selection):** admit Lean's native **trailing** `deriving` clause after `structure ... where { ... }` and `inductive ... where { ... }`, limited to the pinned allowlist. Do **not** admit an arbitrary deriving-handler registration, an `@[deriving]` attribute, a TypeScript decorator, or the standalone `deriving instance ... for ...` command in the initial Standard profile. This syntax is a selected *declaration suffix*, **not** a user declaration attribute. It does not add universal structural equality or a new `@derive` alias.

| Lean 4.35.0 | `pscv0` |
|---|---|
| <pre>structure User where&#10;  id : Nat&#10;  name : String&#10;  deriving Repr, BEq</pre> | <pre>structure User where {&#10;  id: Nat&#10;  name: String&#10;} deriving Repr, BEq</pre> |
| <pre>inductive Status where&#10;  &#124; ok (n : Nat)&#10;  &#124; error (s : String)&#10;  deriving Repr, BEq</pre> | <pre>inductive Status where {&#10;  &#124; ok(n: Nat)&#10;  &#124; error(message: String)&#10;} deriving Repr, BEq</pre> |

**Grammar (schematic):** Lean supplies `derivingClause ::= ('deriving' derivingClass (',' derivingClass)*)?` in the supported declaration families. The selected `pscv0` production is `psDerivingClause ::= 'deriving' allowedClass (',' allowedClass)*`, appearing **optionally** after the closing structural braces; an actual clause requires at least one handler. `allowedClass` is resolved against the **exact named, versioned registered handler list**, not simply any imported class name. The parser's declaration ownership and generated-instance results are pinned to 4.35.0.

**Initial allowlist:** `Repr`, `BEq`, `DecidableEq`, `Inhabited`, `Hashable`, subject to each handler's actual applicability and typeclass instance prerequisites. Additional built-ins (e.g. `LawfulBEq`, `Ord`, `SizeOf`) can be added via an explicitly revised environment snapshot after semantic review. The fact that Lean supports deriving a class does **not** mean all classes can always be derived for all user types.

**Safety and negative-case ownership:** the deriving handler is elaboration machinery. All emitted declarations and proof terms must satisfy normal Lean-grounded checking, and registration affects the deterministic environment. Generated executable methods are *not* proofs of unspecified algebraic laws. For `structure S where { ... } deriving SomeUnregisteredClass`, the trailing clause is **grammatically valid** but the handler/environment gate rejects it; a standalone `deriving instance ... for ...` rejects at the **closed-profile command grammar**. These must be independent tests. The standalone form may be admitted in a later explicit environment revision. [Lean deriving instances](https://lean-lang.org/doc/reference/4.35.0/Type-Classes/Deriving-Instances/).

### Indexed/dependent inductive families

**Feature / profile:** Shared dependent inductives; restricted PS source forms  
**Source basis:** Ch. 13; A.11; Appendix I `LEAN-CORE-IND`

**Lean 4 grammar family → ProofScript surface selection (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>command ::= &quot;inductive&quot; declId binder* &quot;:&quot; term &quot;where&quot; ctor*
ctor ::= &quot;|&quot; ident binder* &quot;:&quot; term</code></pre></td><td valign="top"><pre><code>command ::= &quot;inductive&quot; declId psBinderSeq &quot;:&quot; term
            &quot;where&quot; &quot;{&quot; psCtor* &quot;}&quot; psDerivingClause?
// Refer to the single `psCtor` production above; do not redefine it.
// Indexed constructors use its explicit result-type alternative to state indices.
// Preserve Lean parameters/indices and dependent result types
// Same selected trailing deriving clause as other inductives</code></pre></td></tr></tbody></table>

**Side-by-side examples.**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>inductive Vec (α : Type) : Nat → Type where
  | nil : Vec α 0
  | cons (n : Nat) (value : α) (tail : Vec α n) : Vec α (n + 1)</code></pre></td><td valign="top"><pre><code>inductive Vec(α: Type): Nat -&gt; Type where {
  | nil : Vec(α, 0)
  | cons(n: Nat, value: α, tail: Vec(α, n)): Vec(α, n + 1)
}</code></pre></td></tr></tbody></table>

**Source language distinction.** Indices may occur in constructor result types. The native Lean column legitimately uses `Vec α (n + 1)`; the `.ps` column instead uses `Vec(α, n + 1)` and `Vec(α, n)` because `Vec α (n + 1)` would violate `PSCV0-APP-02` in an **application continuation**. Do **not** "fix" this by writing `Vec α(n + 1)`, which attaches a call to `α` and is not a faithful two-argument application. The **new** `pscv0` selection explicitly admits Lean's named/generalizing discriminants for selected dependent matches (§4), but still does not promise that every unrestricted Lean equation-compiler/motive inference variant is supported. Each admitted dependent elimination must elaborate to checked Lean terms.

### Rich selected native Lean patterns and pattern syntax

**Decision:** replace the earlier restricted `psc2` single-pattern grammar with the *selected 4.35.0 Lean pattern family*. `pscv0` adopts Lean's constructor, nested, tuple, wildcard, variable, `Nat`/`Bool` literal, built-in list-style, and admitted type-specific pattern notations (including the pinned `Nat` successor form `k + 1`). Type-specific built-in patterns are required only when their precise handler/notation is included in the frozen environment; arbitrary imported `@[match_pattern]` handlers do not silently become active in the closed default grammar.

**Lean grammar (schematic):**

```text
pattern ::= Lean.pattern                  -- selected pinned cases only
matchAlt ::= '|' pattern (',' pattern)* '=>' term
          | '|' alternativePatternLists '=>' term
```

**`pscv0` grammar selection (schematic):**

```text
pattern ::= selectedLeanPattern
matchAlt ::= '|' selectedLeanPattern (',' selectedLeanPattern)* '=>' term
matchTerm ::= 'match' selectedLeanDiscriminants 'with' '{' matchAlt+ '}'
// selectedLeanPattern retains native Lean constructor/pattern arguments; no psCallArgs
```

**`PSCV0-PATTERN-01` — constructor patterns are not expression calls.** A `.ps` term constructor may be written `.some(x)` or `Outcome.ok(value)` by PSCV0 *expression* postfix rules, but a `match`/`if let` pattern uses the selected **native Lean pattern category**: write `| .some x => ...`; for a constructor with two fields write `| .pair x y => ...`; for *one tuple field* write `| .some (x, y) => ...`. The last form is a **pattern operand**, not term application; `PSCV0-APP-02` does not ban native pattern delimiters. The expression-call-looking `.some(x,y)` / `.some((x,y))` pattern notation is intentionally **not** part of initial Standard unless a future pinned pattern overlay is added. Reject these as unsupported patterns rather than guessing arity from commas. Constructors and patterns always elaborate through Lean's actual inductive type and recursors.

A scrutinee's family determines which constructors and patterns are admissible. In particular, `k + 1` in `Nat` pattern position is inherited Lean successor-pattern sugar rather than general arithmetic pattern matching: `1 + k`, `k + m` with arbitrary variable `m`, or `k - 1` are not accepted as equivalent constructor patterns. The same **selected Lean pattern grammar** applies inside `match` and `if let` patterns (independent of the application-only punctuation overlay); dependent patterns may induce proof obligations and elaborated motive information.

### Exhaustive multi-discriminant and dependent `match`

**Decision:** the new `pscv0` baseline admits Lean's **multiple match discriminants, named discriminants, and explicit dependent generalization** in the selected term grammar, instead of the previous single-discriminant subset. This is essential for dependent algorithms and theorem proving, not merely syntax comfort. `pscv0` retains the one **braced** body form and source-order alternatives; it does not add a separate runtime matching model.

| Lean 4.35.0 | `pscv0` modified punctuation |
|---|---|
| <pre>def choose (x : Option Nat) (fallback : Nat) : Nat :=&#10;  match x with&#10;  &#124; none => fallback&#10;  &#124; some n => n</pre> | <pre>function choose(x: Option Nat, fallback: Nat): Nat := {&#10;  match x with {&#10;    &#124; .none => fallback&#10;    &#124; .some n => n&#10;  }&#10;}</pre> |
| <pre>def both (x y : Option Nat) : Bool :=&#10;  match x, y with&#10;  &#124; some _, some _ => true&#10;  &#124; _, _ => false</pre> | <pre>function both(x: Option Nat, y: Option Nat): Bool := {&#10;  match x, y with {&#10;    &#124; .some _, .some _ => true&#10;    &#124; _, _ => false&#10;  }&#10;}</pre> |

**Dependent match forms (schematic):** `match (generalizing := true) discriminants with { alternatives }` and `match h : discriminant with { alternatives }` select Lean's actual dependent elaboration and optional equality-hypothesis behavior. The `(generalizing := true)` after the `match` keyword belongs to Lean's **match syntax category**, not to a function call; it does not violate `PSCV0-APP-02`. The exact motive/generalization rules and accepted syntactic placement must be checked against the pinned parser.

**Acceptance conditions:** check all patterns against corresponding discriminants; require the same number of pattern positions per alternative; preserve first-matching-alternative semantics; reject inexhaustive matches, duplicate binders, unsupported pattern modifiers, and unprovable dependent elaboration. Lower successful terms to ordinary Lean recursor/equation-compiler output, then check them with the Lean-grounded kernel acceptance relation. **Do not claim arbitrary user-defined pattern macros or unlimited equation syntax without registered, pinned expansion rules.**

### Equation-style definitions

Lean supports convenient equation-style declarations. Adopt the **selected native Lean equation compiler family** in `pscv0` as a P1 proof/programming enhancement once its exact grammar and restrictions are mapped to `pscv0` declaration binders and canonical body braces. This family has **no new `function` equation keyword** beyond the established alias; direct syntax acceptance remains *pending* until complete positive/negative parser, termination, and elaboration cases are added. Multi-discriminant `match` is P0 and must not wait for P1 equation-style syntax.

**Source:** [Lean 4.35 pattern matching](https://lean-lang.org/doc/reference/4.35.0/Terms/Pattern-Matching/) and [recursive definitions](https://lean-lang.org/doc/reference/4.35.0/Definitions/Recursive-Definitions/).

## 5. Recursion and computability

### Total structural recursion

**Feature / profile:** Shared total recursion; stricter PS base checker  
**Source basis:** Ch. 18.1–18.7; Ch. 27 `List.length` example

**Lean 4 grammar family → ProofScript surface selection (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>command ::= &quot;def&quot; declId declSig? declVal
// Recursive definitions may be accepted using recursor/termination proof</code></pre></td><td valign="top"><pre><code>command ::= &quot;def&quot; declId psBinderSeq (&quot;:&quot; term)? psDeclVal
          | &quot;function&quot; declId psFunctionBinders (&quot;:&quot; term)? psDeclVal
// Head-specific binders also apply to recursive declarations: only `function` has `()`.
// Recursive calls require an admitted Lean-checkable termination proof</code></pre></td></tr></tbody></table>

**Side-by-side examples.**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>def length {α : Type} (xs : List α) : Nat :=
  match xs with
  | [] =&gt; 0
  | _ :: tail =&gt; 1 + length tail</code></pre></td><td valign="top"><pre><code>function length {α: Type}(xs: List α): Nat := {
  match xs with {
    | .nil =&gt; 0
    | .cons _ tail =&gt; 1 + length(tail)
  }
}</code></pre></td></tr></tbody></table>

**Source language distinction.** The inherited base reference allowed only structural recursion; this `pscv0` revision also retains the already proposed bounded `termination_by` well-founded path. In the structural case, recursive calls must pass a designated strict constructor subterm. An arithmetic expression such as `n - 1` is not accepted as *structural-subterm evidence*. Lean offers more termination elaboration routes.

### Mutual recursion

**Feature / profile:** Shared mutual definitions with PS structural restrictions  
**Source basis:** Ch. 18.6; A.2

**Lean 4 grammar family → ProofScript surface selection (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>command ::= &quot;mutual&quot; declaration+ &quot;end&quot;
// Lean mutual groups are declaration groups</code></pre></td><td valign="top"><pre><code>command ::= &quot;mutual&quot; (psDefDecl | psFunctionDecl)+ &quot;end&quot;
// Members lower to Lean mutual declarations</code></pre></td></tr></tbody></table>

**Side-by-side examples.**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>mutual
  def even (n : Nat) : Bool :=
    match n with
    | 0 =&gt; true
    | k + 1 =&gt; odd k
  def odd (n : Nat) : Bool :=
    match n with
    | 0 =&gt; false
    | k + 1 =&gt; even k
end</code></pre></td><td valign="top"><pre><code>mutual
  function even(n: Nat): Bool := {
    match n with {
      | 0 =&gt; true
      | k + 1 =&gt; odd(k)
    }
  }
  function odd(n: Nat): Bool := {
    match n with {
      | 0 =&gt; false
      | k + 1 =&gt; even(k)
    }
  }
end</code></pre></td></tr></tbody></table>

**Source language distinction.** ProofScript demands one designated structural argument for each member of the recursive strongly connected component, strictly decreasing across every recursive edge. Both `| .succ k => ...` and `| k + 1 => ...` are permitted on `Nat`: Lean elaborates the second to an equivalent successor-constructor pattern, so the call on `k` is a call on a strict subterm. **This is not permission to recursively call on `n - 1` without separate termination evidence.** The two spellings belong to the same native Lean semantics; arithmetic-oriented examples prefer `k + 1`. See the [Lean recursive-definition reference](https://lean-lang.org/doc/reference/4.35.0/Definitions/Recursive-Definitions/).

### Well-founded recursion, `termination_by`, and `decreasing_by`

**Feature / profile:** PSCV0 verification addition over shared well-founded foundation  
**Source basis:** Ch. 18.8; A.18

**Lean 4 grammar family → ProofScript surface selection (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>declVal ::= &quot;:=&quot; term terminationSuffix? whereDecls?
terminationSuffix ::= &quot;termination_by&quot; term
                    (&quot;decreasing_by&quot; tacticSeq)?</code></pre></td><td valign="top"><pre><code>// Reuse the two `psDeclVal` alternatives from §2 (plain term OR {one term}).
// Both body forms admit the same optional selected termination suffix.
psTermination ::= &quot;termination_by&quot; term
                  (&quot;decreasing_by&quot; &quot;by&quot; &quot;{&quot; psTacticSeq &quot;}&quot;)?
// Use Lean&#x27;s decreasing proof kernel checks</code></pre></td></tr></tbody></table>

**Side-by-side examples.**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>def down (n : Nat) : Nat :=
  if n == 0 then 0 else down (n - 1)
termination_by n
decreasing_by omega</code></pre></td><td valign="top"><pre><code>function down(n: Nat): Nat := {
  if (n == 0) { 0 } else { down(n - 1) }
}
termination_by n
decreasing_by by {
  omega
}</code></pre></td></tr></tbody></table>

**Source language distinction — `PSCV0-TERM-01`.** PSCV0 extends the base structural-only profile with explicit well-founded/measure recursion. Each call must produce an accepted decrease proof. The selected **PSCV0** suffix is `termination_by measure` optionally followed by `decreasing_by by { psTacticSeq }`. This second spelling **is an owned ProofScript proof-body transformation**, not literal native Lean source: discard the `.ps` grouping `by {` and `}`, and emit Lean's `decreasing_by` followed by the corresponding native tactic sequence (e.g., `.ps` `decreasing_by by { omega }` lowers to `.lean` `decreasing_by omega`). Do not emit a term-level `by` into a native tactic position. Preserve Lean's goal focus and proof-term checking, and require the `pscv0` application grammar in embedded tactic arguments. Unlike Lean's richer termination suffix grammar (which also has variants such as `termination_by structural` and allows some independent suffix arrangements), initial PSCV0 intentionally selects the measure-first form above. The source example is a design illustration and has not been execution-tested.

### `partial`, `partial_fixpoint`, `unsafe`, `axiom` and `noncomputable` — v7.1

**Feature / profile:** revised selective admission; **source status is distinct from checked proof evidence and artifact admission**. The preceding `PSCV0-TERM-01` still governs ordinary total/structural/well-founded recursion. Stable Lean 4.35.0 is the source of parser/elaborator/kernel semantics: [Recursive Definitions](https://lean-lang.org/doc/reference/4.35.0/Definitions/Recursive-Definitions/), [Lean parser declaration modifiers](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Parser/Command.lean).

**`PSCV0-TERM-02` — selected `partial` declarations (P0 source, separately gated verified behavior).** A source `partial def` or `partial function` lowers to Lean's `partial def` with the same type/arguments and body semantics. Only genuine function definitions are admitted; `partial const` and arbitrary application of `partial` to theorem, axiom, inductive or other declaration heads are forbidden. Follow stable Lean's admissibility rule: the function result type must be inhabited (by a suitable `Nonempty` or `Inhabited` witness); an arbitrary `A → Empty` cannot be introduced by unguarded partial recursion. Mutual recursion must follow Lean's corresponding group rules. The type checker checks the predefinition, but the resulting constant is logically opaque: its executable body is not a proof equation.

**`PSCV0-FIXPOINT-01` — `partial_fixpoint` (P1 kernel-checkable construction).** The exact keyword is a **suffix following an ordinary `def` or a `function` lowered to Lean `def`**, not `partial_fixpoint def`. In v7.1 the baseline source selects the suffix alone; a user-supplied `monotonicity` tactic subclause is deferred pending a separately pinned braced-grammar translation. Use Lean 4.35.0's fixed-point elaboration, `Lean.Order.CCPO`/`fix` monotonicity obligations and checked unfolding equations; do **not** reproduce equations as unproved axioms, trust a generated theorem without checking its dependencies, or assume arbitrary recursion is eligible. Valid categories include inhabited-result tail recursion and suitable monotone monadic recursion (for example the supported `Option` structure). Non-tail recursion with unsupported result inspection must fail. Definitions in one mutual recursive fixed-point clique must be consistently annotated. `partial_fixpoint` and `termination_by` are mutually exclusive for the same function.

**Logical-versus-executable distinction.** A `partial_fixpoint` is **logically a total function** selected to satisfy justified equations, even where the executable code may diverge. Its unfolded equation may not uniquely specify a returned value on a divergent input. Monadic logical bottom (for instance an `Option.none` interpretation in suitable cases) is *not* a promise that compiled infinite recursion returns `none`. Kernel-approved equations and monotonicity establish a sound reasoning basis, **not** the application's promised correctness, termination, external safety, or backend implementation correctness.

**`PSCV0-UNSAFE-01` — restricted `unsafe` function boundary (P2 conditional).** `unsafe def` / `unsafe function` may be parsed only as explicitly declared, typed runtime/boundary functions in a registered environment. They are not available as proof-producing theorems, casts or arbitrary user metaprograms. The keyword by itself proves **nothing** about behavior, memory, effects, representation invariants, or fidelity to a safe logical function. Unsafe-produced or foreign-dependent runtime behavior can appear in an ordinary checked artifact with its unverified identity and approved target capability. A **closed verified** artifact requires a sound, kernel-checked implementation/refinement proof for all relevant runtime behavior, with target-specific backend correspondence; otherwise only an expressly approved **boundary-qualified** identity may be emitted, with immutable named assumptions and no closed assurance claim. Under a policy forbidding unproven external dependencies, even boundary-qualified emission must be rejected. An unsafe declaration cannot create trusted proof evidence by masking a logical computation.

**`PSCV0-TRUST-01` — no source proof authority expansion.** User-authored `axiom` commands, uncontrolled `native_decide`/`run_tac`/`unsafeCast`/`unsafePerformIO`-style proof escapes, unsanctioned custom elaborators/attributes, and `sorry`/`sorryAx` are *not* enabled by this amendment. Explicit imported foundational axioms remain scoped to the selected approved assumption set. Proof holes or unassigned metavariables block all emitted artifacts; a foreign function signature or ABI declaration does not prove the foreign implementation.

**`PSCV0-DECL-01` — `noncomputable` unchanged.** `noncomputable` remains available on selected proof/spec `def`/`function` declarations with Lean-compatible typing and approved logical dependencies. An executable's **computational** dependency closure may not rely on noncomputable-only implementations; this does not prohibit propositions/proof terms that are fully erased with certified noninterference.

**Canonical modifier/recursion source grammar (v7.1).** This is an owned ProofScript selection of the stable Lean 4.35.0 modifier ordering and termination-suffix parser, not a second proof calculus.

```text
psModifiers ::= psAttributes? "private"?
psFeatureModifier ::= "noncomputable" | "partial" | "unsafe"
psSelectedFunction ::= psModifiers? psFeatureModifier?
                      (psDefDecl | psFunctionDecl)
psDeclVal ::= ":=" psDeclTerm psRecursionSuffix? psWhere?
psRecursionSuffix ::= psTermination | "partial_fixpoint"
psConstDecl ::= "const" declId (":" term)? psConstVal
psConstVal ::= ":=" psDeclTerm psWhere?
-- The suffix belongs after the body, before where.
-- The modifier and suffix must satisfy PSCV0-REC-STRATEGY-01.
```

**`PSCV0-REC-STRATEGY-01` — admitted combinations (normative):**

| Declared function strategy | Allowed suffix | Assurance and contract constraints |
|---|---|---|
| Plain `def` / `function` | No suffix (termination inferred), or selected `termination_by` with optional proof | Selected Lean-grounded total function and contract rules |
| Plain `def` / `function` using `partial_fixpoint` | Exactly that suffix; no `termination_by` or `decreasing_by` | Check fixed-point and monotonicity evidence, generated equation dependencies, declared behavior, and executable adequacy |
| `partial def` / `partial function` | No recursion suffix | Opaque in the logic; verify behavioral claims only through a checked operational model and source/backend refinement |
| `unsafe def` / `unsafe function` | No recursion suffix | Registered runtime implementation only; a safe modeled specification and independently justified correspondence are required for any verified claim |
| `noncomputable def` / `noncomputable function` | No recursion suffix in this profile | Proof/specification-only; no executable computational body dependency |
| `const` | No recursion suffix or feature modifier | Nonrecursive source value with selected `psConstVal` |

Only selected `def`/`function` heads accept exactly **one** of the three leading feature modifiers. Repeated modifiers; `unsafe partial`, `partial unsafe`, `partial partial`, `unsafe unsafe`; `partial` or `unsafe` with `partial_fixpoint`; and `noncomputable` combined with executable recursion are all rejected at the source-profile/elaboration boundary. `partial_fixpoint` and `termination_by` are mutually exclusive. Even when Lean parses an alternative modifier combination, PSCV0 does not silently accept a logically different recursion strategy. Apply native mutual-recursion-clique checks and audit the effective opacity of **every** member before making any verified assertion.

**Lean 4.35.0 / PSCV0 surface comparison** (illustrative, not independently compiled fixtures):

| Lean 4.35.0 | PSCV0 v7.1 |
|---|---|
| `partial def find (p : Nat → Bool) (i : Nat) : Nat := if p i then i else find p (i + 1)` | `partial function find(p: Nat → Bool, i: Nat): Nat := if (p(i)) { i } else { find(p, i + 1) }` |
| `def find (p : Nat → Bool) (i : Nat) : Nat := if p i then i else find p (i + 1)` followed by `partial_fixpoint` | `function find(p: Nat → Bool, i: Nat): Nat := if (p(i)) { i } else { find(p, i + 1) }` followed by `partial_fixpoint` |
| `unsafe def boundary (x : Nat) : Nat := x` | `unsafe function boundary(x: Nat): Nat := x` (requires a registered restricted unsafe profile) |
| `noncomputable def choice ...` | selected proof/spec-only `noncomputable def`; executable dependency gate unchanged |

**`PSCV0-VERIFY-PARTIAL-01` — mandatory proof-before-emission.** Merely type-checking `partial def` does **not** establish executable body correctness: there is no general defining equation available to proofs. For verified admission, either use a supported `partial_fixpoint` model and prove the required specification, or establish a separately checked operational semantics and a refinement/simulation proof connecting that exact partial body to the model. In **all** cases also discharge the declared postcondition for terminating results, trace safety for relevant finite prefixes, and termination/progress properties *when promised*. A pure partial-correctness postcondition on a never-returning server is not enough to certify its operational safety. Any missing obligation blocks verified emission without ordinary fallback.

**Assurance decision matrix:**

| Construct | Explicit ordinary checked executable | Closed verified executable | Boundary-qualified verified executable |
|---|---|---|---|
| Total `def`/`function` | Type/kernel/environment checks | Mandatory behavior/effect/backend evidence | Same, with any allowed boundary assumptions disclosed |
| `partial def` / `partial function` | Allowed with inhabited type and executable backend support | Only with checked body/model refinement **and** required partial/total/trace obligations | Only with same internal proofs and any boundary assumptions permitted by policy |
| `partial_fixpoint` | Only after valid fixed-point construction and executable backend support | Checked fixpoint equations, application-specific correctness and required runtime refinement; totality only if promised | Same internal proof; disclosed approved runtime assumptions |
| `unsafe def` / `unsafe function` | Only registered typed boundary/capability | **Reject** unless unsafe implementation correspondence is formally established for the promised closed claim | Allowed only by an explicit approved, named boundary-assumption policy |
| User `axiom`, `sorry`/`sorryAx` proof holes | Reject emitted artifact | Reject | Reject |
| Proof-only `noncomputable` | Allowed in logical proof closure; no computational executable dependency | Same, under stricter assumption policy | Same |

**Operational precedence:** Parser admission ⟶ elaboration/type check ⟶ kernel and approved proof environment ⟶ effect/assumption/erasure dependency closure ⟶ verification-condition and partial/total/trace checks ⟶ executable-implementation/refinement evidence ⟶ each target's backend admission ⟶ *only then* artifact emission. Failure at any mandatory stage produces **no artifact** for the requested identity. Source grammar admission is never equivalent to verification acceptance.

**Compatibility and implementation status:** This is a v7.1 normative change; neither original v7's `N-PARTIAL` rejection nor a former blanket `unsafe` ban may be applied unconditionally. PSC0's actual implementation still needs P0/P1/P2 work and test/CI evidence; the document is not an assertion of current feature completion.

## 6. Proof language, tactics, and attributes

### Theorems, proofs, and explicit subgoal ownership

**Lean family:** `theorem`, `example`, `by` tactic sequences, Lean proof terms. **`pscv0` modification:** comma-separated explicit declaration binders and **mandatory `by { ... }`** for a multi-tactic proof. We adopt Lean's actual tactic **middle-dot** bullet `·` (U+00B7). The ASCII period `.` is field notation or punctuation, **not a Lean goal bullet**.

| Lean 4.35.0 | ProofScript `pscv0` |
|---|---|
| <pre>theorem andProof (P Q : Prop) (hp : P) (hq : Q) : P ∧ Q := by&#10;  constructor&#10;  · exact hp&#10;  · exact hq</pre> | <pre>theorem andProof(P: Prop, Q: Prop, hp: P, hq: Q): P ∧ Q := by {&#10;  constructor&#10;  · exact hp&#10;  · exact hq&#10;}</pre> |

**Why subgoal bullets matter:** `constructor` on `P ∧ Q` introduces two proof goals. `· exact hp` focuses the first and requires it to close; `· exact hq` handles the second. Unfocused sequential `exact hp` then `exact hq` can happen to work, but provides weaker local proof structure. Native `case` and `next` are alternative **Lean** ways to focus goals when identifying constructor/case names is clearer. They are not new ProofScript keywords.

**Lean grammar (schematic):**

```text
term    ::= ... | 'by' tacticSeq
tactic  ::= ... | '·' tacticSeq | 'case' caseName '=>' tacticSeq
                 | 'next' binders? '=>' tacticSeq
                 | selectedLeanTactic
```

**ProofScript restriction:**

```text
term ::= ... | 'by' '{' psTacticSeq '}'
-- psTacticSeq accepts native `·`, `case`, `next` for goal ownership
-- no separate `.` ASCII bullet production
```

The *source* tactic set is fixed/versioned rather than extended by arbitrary installed macros. Tactics generate proof terms, which are checked by the Lean-grounded kernel. `case`/`next` are permitted **only** with the native pinned parsing and goal-focusing behavior; no JS-like switch-case interpretation. **The tactic grammar is not an escape from `PSCV0-APP-02`:** `exact (hp)` may start a grouped tactic-argument term, and `exact h(hp)` may apply a proof function, but `exact h (hp)` must not be accepted as a spaced parenthesized application in `.ps`.

### Proof terms, `have`, `show`, `suffices`, `calc`

| Lean 4.35.0 | ProofScript `pscv0` |
|---|---|
| <pre>theorem trans (a b c : Nat) (h1 : a = b) (h2 : b = c) : a = c := by&#10;  calc&#10;    a = b := h1&#10;    _ = c := h2</pre> | <pre>theorem trans(a: Nat, b: Nat, c: Nat, h1: a = b, h2: b = c): a = c := by {&#10;  calc&#10;    a = b := h1&#10;    _ = c := h2&#10;}</pre> |

Adopt Lean `have`, `show`, `suffices`, and `calc` with their native checked meanings. `calc` need not be restricted to equality-only if a fixed, pinned Lean relation/transitivity instance is present; arbitrary custom notation/attributes remain outside the closed source grammar. Do not create alternative ProofScript spellings for these facilities.

### Selected native Lean tactics and goal control

| Group | Accepted native Lean tactic heads / combinators | `pscv0` decision |
|---|---|---|
| Intro & constructors | `intro`, `intros`, `constructor`, `constructor!`, `apply`, `exact`, `refine`, `assumption`, `rfl` | native spellings; proof term checked |
| Elimination | `cases`, `induction`, `rcases`, `rintro`, `obtain` | selected pinned forms |
| Rewriting / simplification | `rw`, `simp`, `simp only`, `simpa`, `simp_all`, `dsimp`, `change`, `unfold` | native spellings |
| Logical methods | `by_cases`, `by_contra`, `exfalso`, `use`, `ext`, `decide` | native spellings |
| Automation | `omega`, `grind`, `exact?` | proof-producing, no oracle acceptance |
| Intermediate facts | `have`, `show`, `suffices`, `calc`, `classical` | native Lean constructs |
| Goal focus | **`·`**, `case`, `next`, `all_goals`, `any_goals`, `<;>` | accept selected pinned control forms, never ASCII dot bullet |
| Arbitrary syntax plugins | `syntax`, `macro_rules`, user-defined tactic parsers | not available in closed `.ps`; an **explicit pinned proof environment** may admit selected proof-producing registrations |

**Important:** Lean's `;` inside the tactic language means tactic composition, **not** an ordinary program statement separator. The canonical `.ps` proof uses newline-separated tactics and `·` bullets. If a pinned native tactic combinator is admitted, its Lean meaning is preserved; it is not reinterpreted as JavaScript `;`.

**Examples (two native Lean goal-selection mechanisms in `.ps`):**

```proofscript
-- Canonical branch bullets
theorem pairLaw(P: Prop, Q: Prop, hp: P, hq: Q): P ∧ Q := by {
  constructor
  · exact hp
  · exact hq
}

-- Native case selection can also be used when there is a case name
theorem orLaw(P: Prop, Q: Prop, hp: P): P ∨ Q := by {
  exact Or.inl hp
}
```

`· exact` is one tactic branch and can contain a nested tactic sequence when required by Lean's proof grammar; a bullet must discharge the focused subgoal. Subgoal ownership is important for sound human/AI proof maintenance but is not a kernel axiom.

### Versioned proof-producing extension environment (without extending proof trust)

**Decision P1:** `pscv0` should be usable with substantial theorem libraries rather than only its initial small tactic list. Lean proof packages sometimes require custom tactic syntax, notation, attributes, and proof macros. The native proof extension mechanism is useful, but the default closed grammar must not be modified silently by an arbitrary ordinary import.

| Mode | Source-level admission | Proof acceptance |
|---|---|---|
| **Standard `pscv0`** | Frozen selected Lean tactic/notation and declaration registrations | Independently check the elaborated proof term and active axiom closure |
| **Explicit pinned proof environment** | Selected additional tactic/notation syntax declared by named exact extension manifest (package revision, handlers, parser registrations, imported theorems, priorities) | Same kernel/axiom policy; loaded code cannot grant verified status |
| **Unsupported/unpinned extension** | Reject source syntax or registry mutation that is not in the active environment identity | Never accept due to a plugin's “success” flag |

**No blanket imports of Lean's unrestricted Meta language.** An ordinary source package must not invoke ambient `register...` commands to change the certified grammar behind the compiler's back. A consciously chosen theorem-development extension is an explicit environment choice, and its generated proof obligations undergo exactly the same checks as ordinary proofs. The fact that Lean tactics construct kernel-checkable proof terms does not make plugin execution or generated axioms independently trustworthy.

**Proof language capability target:** native `·`, `case`, `next`, `focus`, `all_goals`, `any_goals`, admitted tactic combinators (`<;>` where pinned), structured `calc` (not arbitrarily equality-only), `simp`/`simp only`, `omega`, `grind`, selected named rewrite locations, and proof-term syntax required by supported libraries. Syntax not present in 4.35.0 Standard is opt-in, **not** magically part of the default. In particular, `aesop`, `linarith`, or mathlib-specific tactics require their defining libraries/registered environment and are not guaranteed merely by mentioning their names.

**Term grammar remains uniform.** An extension that accepts a term inside a tactic argument or quoted source must either parse that term using the same `pscv0` application rule or be explicitly isolated under a different, auditable syntax category; it must not silently turn `f (x)` back into a legal ordinary `.ps` application. String interpolation and editor quick fixes are covered by the same policy.

Lean research: [custom tactics](https://lean-lang.org/doc/reference/4.35.0/Tactic-Proofs/Custom-Tactics/), [tactic proof states](https://lean-lang.org/doc/reference/4.35.0/Tactic-Proofs/), [validating proofs and axioms](https://lean-lang.org/doc/reference/4.35.0/ValidatingProofs/).

### Source attributes and instance/default-instance registrations

**Feature / profile:** Shared base attributes; PS closed registry  
**Source basis:** Ch. 24.5–24.6; A.2

**Lean 4 grammar family → ProofScript surface selection (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>attributes ::= &quot;@[&quot; attr (&quot;,&quot; attr)* &quot;]&quot;
command ::= attributes? declaration</code></pre></td><td valign="top"><pre><code>psAttributes ::= &quot;@[&quot; (&quot;simp&quot; | &quot;instance&quot; | &quot;default_instance&quot;)
                  (&quot;,&quot; (&quot;simp&quot; | &quot;instance&quot; | &quot;default_instance&quot;))* &quot;]&quot;
command ::= psAttributes? selectedPsDeclaration
// Select Lean attribute semantics, not arbitrary plugin handlers</code></pre></td></tr></tbody></table>

**Side-by-side examples.**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>@[simp] theorem add_zero_right (n : Nat) : n + 0 = n := by
  simp</code></pre></td><td valign="top"><pre><code>@[simp] theorem addZeroRight(n: Nat): n + 0 = n := by {
  simp
}</code></pre></td></tr></tbody></table>

**Source language distinction.** Only `simp`, `instance`, and `default_instance` are exposed as **user attributes** by the ProofScript Standard grammar. Imported source may add admitted instance and simp entries but not arbitrary syntax or proof authority. `set_option`, `syntax`, `macro`, arbitrary deriving-handler registration, standalone `deriving instance ... for ...`, and custom attribute handlers are outside the **initial Standard source**. The **trailing allowlisted `deriving` clause** after `structure`/`inductive` is **inside** Standard source under `PSCV0-DERIVE-01`; it is a *declaration suffix*, not an `@[...]` attribute. This distinction overrides the older blanket exclusion of the word `deriving` in this paragraph.

## 7. PSCV0 verification syntax beside Lean verification forms

### Pure function contracts: `requires` and `ensures`

**Feature / profile:** PSCV0 verification contract syntax; Lean intrinsic prototype (experimental)  
**Source basis:** Ch. 21.1–21.7; A.16, A.18; Appendix I.8A

**Lean 4 grammar family → ProofScript surface selection (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>command ::= &quot;def&quot; declId declSig
            &quot;given&quot;? &quot;requires&quot;? &quot;ensures&quot;? declVal
// Lean 4.35.0 experimental intrinsic contracts</code></pre></td><td valign="top"><pre><code>command ::= &quot;def&quot; declId psBinderSeq (&quot;:&quot; term)? psContractSeq psDeclVal
          | &quot;function&quot; declId psFunctionBinders (&quot;:&quot; term)? psContractSeq psDeclVal
// Contract eligibility does not remove the source-nullary `function f()` form.
psContractSeq ::= psGivenClause? psRequiresClause? psEnsuresClause?   // fixed order
psGivenClause ::= &quot;given&quot; psGivenBinder+  // binderIdent or bracketedBinder
psRequiresClause ::= &quot;requires&quot; term | &quot;requires&quot; selectedLeanBasicFun
psEnsuresClause ::= &quot;ensures&quot; selectedLeanBasicFun  // mandatory result binder
// At most once each; native 4.35.0 contractDeclVal order, never arbitrary psContract*</code></pre></td></tr></tbody></table>

**Side-by-side examples.**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>-- Lean intrinsic verification, version-sensitive example
-- requires import Std.WP and its registered proof environment
def increment (n : Nat) : Id Nat
    requires n &lt; 100
    ensures r =&gt; r = n + 1 := do
  return n + 1</code></pre></td><td valign="top"><pre><code>-- PSCV0: requires a selected pinned Std.WP import/prelude
function increment(n: Nat): Id Nat
  requires n &lt; 100
  ensures r =&gt; r = n + 1 := do {
  return n + 1
}</code></pre></td></tr></tbody></table>

**Source language distinction — `PSCV0-CONTRACT-01/02`.** Clauses may occur only in the 4.35.0 sequence **`given? requires? ensures?`**, at most once each, after a selected `def` or `function` signature and before its value. `requires` accepts the pinned term or predicate-binder form; `ensures` requires a Lean `basicFun` result binder (e.g. `ensures r => ...`). Repetitions, missing `ensures` binder, and reordered clauses are **PARSE rejects**. These are genuine 4.35.0 intrinsic contracts, not harmless metadata. The generated `f.spec` proof obligations must be closed under the selected WP/effect model, with missing proofs blocking verified emission.

**`PSCV0-CONTRACT-03` prerequisite:** the Lean intrinsic contract macro requires the pinned `Std.WP.Triple` declaration; `do`-level proof-only `assert` requires `Gadget.assertGadget`. Example files requiring these operations must import `Std.WP` (or a frozen PSCV0 prelude that actually imports/exports the necessary declarations and registrations), and the effective `Std.WP`/tactic environment must be frozen before claiming conformance. The source file alone is not evidence that the intrinsic verifier is registered. These examples remain **illustrative syntax**, not execution-tested proofs.

### Logical contract binders: `given`

**Feature / profile:** PSCV0 verification; Lean 4.35 intrinsic counterpart  
**Source basis:** Ch. 21.3; A.18 [pscv.grammar.contract-order]

**Lean 4 grammar family → ProofScript surface selection (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>command ::= &quot;def&quot; declId declSig &quot;given&quot; binder+ ...
// Pinned Lean&#x27;s experimental givenClause</code></pre></td><td valign="top"><pre><code>psGivenClause ::= &quot;given&quot; psGivenBinder+
psGivenBinder ::= Lean.binderIdent | selectedLeanBracketedBinder
// A typed binder is `(target: Nat)`, never bare `target: Nat`; logical only</code></pre></td></tr></tbody></table>

**Side-by-side examples.**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>-- Requires import Std.WP; schematic (not tested)
def take (xs : List Nat) : Id Nat
    given (target : Nat)
    requires target = xs.length
    ensures r =&gt; r = target := do
  return xs.length</code></pre></td><td valign="top"><pre><code>-- Requires the selected Std.WP verification environment; schematic
function take(xs: List Nat): Id Nat
  given (target: Nat)
  requires target = xs.length
  ensures r =&gt; r = target := do {
  return xs.length
}</code></pre></td></tr></tbody></table>

**Source language distinction — `PSCV0-GIVEN-01`.** `given` introduces specification-only logical variables, never runtime arguments, with exactly Lean's binder grammar: untyped identifier or selected parenthesized/bracketed binder. In particular write `given (target: Nat)`, not `given target: Nat`. PSCV0 retains 4.35.0 `given` → `requires` → `ensures` order; the older non-native `reads`/`modifies`/`errors` clauses are **deferred**. Both snippets are **illustrative** and depend on `Std.WP`; they are not claimed to parse, elaborate or prove in a test run.

### Verification-only `assert`

**Feature / profile:** PSCV0 verification; Lean 4.35 experimental analogue  
**Source basis:** Ch. 10 (`pscv.assert`), Ch. 21.10; A.18

**Lean 4 grammar family → ProofScript surface selection (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>doSeqItem ::= &quot;assert&quot; term | ...
// Pinned Lean 4.35 experimental intrinsic verification</code></pre></td><td valign="top"><pre><code>psDoItem ::= &quot;assert&quot; term | selectedLeanDoItem
// Requires Prop; generates proof obligation; no JS runtime assert</code></pre></td></tr></tbody></table>

**Side-by-side examples.**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>-- Lean 4.35 verification context; illustrative
-- def check (n : Nat) : Id Nat := do
--   assert 0 ≤ n
--   return n</code></pre></td><td valign="top"><pre><code>-- PSCV0 verification context; illustrative
-- function check(n: Nat): Id Nat := do {
--   assert 0 &lt;= n
--   return n
-- }</code></pre></td></tr></tbody></table>

**Source language distinction.** `assert P` has `P : Prop`; it creates proof obligations and contributes proved facts to later verification, with **no required runtime check**. It is not JavaScript's throwing `assert`. Lean 4.35.0 requires the `Std.WP` assertion gadget/registered elaboration; a bare `assert` without that environment or a compatible verified effect model fails instead of silently becoming a runtime assertion. Verified status additionally requires successful proof closure.

### Local `let mut`, assignment, and early `return`

**Feature / profile:** PSCV0 verification practical do (Lean shares mainstream form)  
**Source basis:** Ch. 10 `pscv.do`, A.18; Appendix B

**Lean 4 grammar family → ProofScript surface selection (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>doSeqItem ::= &quot;let&quot; &quot;mut&quot; ident &quot;:=&quot; term
            | ident &quot;:=&quot; term | &quot;return&quot; term | ...</code></pre></td><td valign="top"><pre><code>psDoItem ::= &quot;let&quot; &quot;mut&quot; ident (&quot;:&quot; term)? &quot;:=&quot; term
           | ident &quot;:=&quot; term | &quot;return&quot; term | ...
// Retain Lean local-mutation translation; no unmodeled aliasing</code></pre></td></tr></tbody></table>

**Side-by-side examples.**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>def next (n : Nat) : Id Nat := do
  let mut x := n
  x := x + 1
  return x</code></pre></td><td valign="top"><pre><code>function next(n: Nat): Id Nat := do {
  let mut x := n
  x := x + 1
  return x
}</code></pre></td></tr></tbody></table>

**Source language distinction.** Local mutability is translated into a total stateful `do` computation. PSCV0 does **not** thereby admit mutable aliases/shared heap references. Early return must satisfy all applicable postconditions. `do` sequencing is line-based in ProofScript, not semicolon-separated.

### `for` loops, iterator specifications, `break`, and `continue`

**Lean family:** native `for`/`break`/`continue` `do` statements. **`pscv0` surface modification:** replace the outer Lean `do` loop-body delimiter with braced grouping, not another iterator or termination model. A verified effectful loop must have a checked invariant/iterator specification appropriate to the **actual Lean 4.35.0 loop semantics**; no new bare `invariant term` syntax is introduced merely because the earlier RC3 ProofScript draft proposed one.

| Lean 4.35.0 | ProofScript `pscv0` |
|---|---|
| <pre>def count (xs : List Nat) : Id Nat := do&#10;  let mut total := 0&#10;  for x in xs do&#10;    total := total + x&#10;  return total</pre> | <pre>function count(xs: List Nat): Id Nat := do {&#10;  let mut total := 0&#10;  for x in xs {&#10;    total := total + x&#10;  }&#10;  return total&#10;}</pre> |

The plain loops above demonstrate **syntax only**. For a verified executable result, a proof-capable iterator semantics, invariants or verified iterator lemmas, and all relevant termination obligations are still required. If an upstream selected Lean `for` invariant annotation is used, its binder/shape must follow the **pinned Lean 4.35.0 parser**, not the old invented `invariant total = prefixSum` spelling. `break`/`continue` retain Lean control-flow meaning and their verified proof obligations.

### `while` loops — total and explicitly potentially divergent verification (v7.1)

**Lean family:** stable Lean 4.35.0's selected intrinsic `invariant` and `decreasing` verification syntax. The native total-correctness example retains its pinned exit-state invariant semantics; PSCV0 keeps braced bodies.

For a **total** verified loop, the existing native-inspired source shape remains:

```text
psWhileTotal ::= "while" term
  "invariant" binder "=>" term
  "decreasing" term
  "{" psDoSeq "}"
```

For a **partial/ongoing** loop, v7.1 specifies a separately **staged and environment-gated** source form:

```text
psWhilePartial ::= "while" term
  "invariant" binder "=>" term
  "{" psDoSeq "}"
```

The second form is **not** a claim that Lean's intrinsic total-correctness `vcgen` will accept a missing decreasing clause. PSCV0 must use a separately justified, Lean-grounded small-step / trace proof rule for this form, including initialization, preservation, every `break`/`continue`/exceptional path, and effect/state invariants. A totality claim still requires a well-founded descent proof; liveness/fairness claims require their own proofs and explicit runtime scheduling assumptions. Without the selected trace-effect model, a verified request fails at **ENV/VC-PROOF**, not by silently deleting the verification annotations. Plain ordinary loops keep their admitted runtime behavior and explicit unverified identity.

**Total-correctness example (schematic `.ps`):**

```proofscript
function countDown(n: Nat): Id Nat
  ensures r => r = 0 := do {
  let mut i := n
  while i > 0
    invariant exit => if (exit) { i = 0 } else { True }
    decreasing i
  {
    i := i - 1
  }
  return i
}
```

**`PSCV0-LOOP-01`:** Proof-before-emission is **not** synonymous with proving termination for every loop. It requires proving every contract-mandated property under the chosen total/partial/trace interpretation. For a nonterminating service an empty postcondition is not a useful safety certificate: finite-prefix safety, termination-sensitive errors, external effects and any required progress properties must be covered. This is a future verified feature until operational semantics, VC rules and target correspondence have evidence.

### Verification-only `erased` state — use Lean's word

Lean 4.35.0 adds experimental `erased x := e`, `erased mut x := e`, and `erased x ← action` inside `do`. **`pscv0` adopts `erased` unchanged; `ghost` is not a keyword, not an accepted synonym, and not needed.**

| Lean 4.35.0 source family | `pscv0` braced source |
|---|---|
| <pre>def f (n : Nat) : Id Nat := do&#10;  erased mut visited : Nat := 0&#10;  return n</pre> | <pre>function f(n: Nat): Id Nat := do {&#10;  erased mut visited : Nat := 0&#10;  return n&#10;}</pre> |

**Lean grammar (schematic):** `doSeqItem ::= ... | 'erased' ident ':=' term | 'erased' 'mut' ident ':=' term | 'erased' ident '←' term`. ProofScript changes only the **outer `do { ... }` grouping**, and keeps the same Lean item grammar. Assignment/invariant/proof rules ensure that erased information cannot affect runtime return values, branches, or effects. These snippets illustrate syntax; the experimental Lean verification context must be enabled for actual acceptance. Source: [4.35.0 release notes](https://lean-lang.org/doc/reference/4.35.0/releases/v4.35.0/).

### Refined data — native Lean `Subtype`, no new `refine type` declaration

A Lean `Subtype` is exactly a value accompanied by evidence of its property. It already has a readable and established source notation: `{x : A // P x}`. There is **no** `pscv0` `refine type` syntax.

| Lean 4.35.0 | ProofScript `pscv0` |
|---|---|
| <pre>abbrev Positive := {n : Nat // n > 0}&#10;def onePositive : Positive := ⟨1, by decide⟩</pre> | <pre>abbrev Positive := {n : Nat // n > 0}&#10;const onePositive: Positive := ⟨1, by { decide }⟩</pre> |

**Lean grammar (schematic):** `term ::= ... | '{' ident ':' term '//' term '}' | 'Subtype' term`. **ProofScript delta:** none for these terms, apart from the enclosing `const` alias and optional proof grouping. This avoids another syntax family and preserves Lean's existing proof erasure / coercion story. This `Subtype` brace form must be recognized **before** general record/body brace parsing in its type-expression context.

### Structure invariants — native proof fields, no suffix sugar

A proof-valued field is enough to express an invariant, so `invariant self => ...` after a `structure` declaration is **not** a `pscv0` language form.

| Lean 4.35.0 | ProofScript `pscv0` |
|---|---|
| <pre>structure Account where&#10;  balance : Int&#10;  nonnegative : balance >= 0</pre> | <pre>structure Account where {&#10;  balance: Int&#10;  nonnegative: balance >= 0&#10;}</pre> |

Every constructor and update must supply an appropriate checked proof term. The `nonnegative` field lives in `Prop` and can be erased as Lean permits. No hidden constructor or unchecked proof obligation is introduced by alternative source syntax.

### Contract verification — native theorems and `vcgen`, no `verify` command

**Decision — `PSCV0-CONTRACT-04`:** discard the extra `verify target := by { ... }` command. For an 4.35.0 intrinsic `def`/`function` carrying `given`/`requires`/`ensures`, the pinned macro emits the ordinary definition **and** the `@[spec]` theorem `f.spec`; it runs `vcgen` and default proof steps, and—when the obligations remain—consumes **the `spec` subsection of the same definition's `where finally` tail**. A separate later theorem does **not** retroactively discharge the generated `f.spec` obligations. PSCV0 therefore admits one **contract-specific** braced tail, translating its selected tactic sequence directly into native 4.35.0 `where finally | spec => ...` (not into an extra `by` term or a new checker).

**Lean 4.35.0 proof-attachment shape (schematic; requires `import Std.WP`):**

```lean
-- import Std.WP
-- def f (n : Nat) : Id Nat
--     ensures r => r = n + 1 := do
--   return n + 1
-- where
--   finally
--     | spec =>
--       omega
```

**PSCV0 equivalent (selected design; not executed):**

```proofscript
-- Requires Std.WP as a pinned imported verification environment.
function f(n: Nat): Id Nat
  ensures r => r = n + 1 := do {
  return n + 1
}
where {
  finally {
    | spec => {
      omega
    }
  }
}
```

**Acceptance constraints:** the `spec` subsection is only permitted on a declaration with an intrinsic contract; it is at most one per definition, follows selected local `where` declarations, and is not arbitrary tactic injection. Missing imports/registrations give ENV errors; duplicate/misplaced `spec` is PARSE/profile rejection; unresolved VCs prevent completion of the generated theorem at **ELAB/VC-PROOF**, and the **ASSURANCE** gate then prevents verified emission. Do not classify a never-produced proof as a kernel rejection; reserve **KERNEL** for an invalid submitted term. Proof tactics construct evidence; the kernel checks the resulting terms. A standalone theorem is still useful to express additional API laws, **not** as a replacement for the contract's native VC attachment. Imported consumers of `f.spec` additionally depend on the selected 4.35.0 module-visibility policy (§1).

This is a *shape*, not a runnable file: the obligation proposition and compatible effect model must actually be declared. Lean theorems remain the final checked proof objects. `verify` is not a `pscv0` keyword.

### Effect/frame vocabulary — defer additional keywords until needed

The older PSCV design proposed `reads`, `modifies`, contract-only `old(...)`, and `errors` as new language syntax. **These are not part of the minimal Lean-native `pscv0` grammar in this revision.** They are deferred candidate features, not alternate required spellings for native Lean facilities. Their intended ideas—frame conditions, pre-state access, and typed error postconditions—can already be expressed with ordinary Lean predicates and checked WP/Hoare libraries; later source sugar should be accepted only if it materially improves programming effort and comes with an exact model.

| Need | Native Lean-style representation | `pscv0` rule |
|---|---|---|
| State pre/post | `State → Prop`, `Result → State → Prop` | use explicit predicates / `requires`, `ensures` in admitted verification contexts |
| Unchanged components | equality in a postcondition / checked frame lemma | no global `modifies` keyword yet |
| Old state | explicit `before` logical binder in a theorem/effect contract | no `old` syntax yet |
| Errors | typed `Except E A`, propositions for `.ok` and `.error` results | no separate `errors` clause yet |

**Boundary:** `IO`, FFI, external service behavior, mutable aliasing, and concurrency are not silently accepted as closed verified semantics. Effect models must have checked laws; arbitrary `Monad` instances are not enough.

### Verified effect families: pure, state, reader, typed error

**Feature / profile:** Shared monadic notation; PSCV0 verified-effect restrictions  
**Source basis:** Ch. 10, 21.14–21.18; A.18

**Lean 4 grammar family → ProofScript surface selection (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>term ::= &quot;do&quot; doSeq
// Lean library effect families include StateM / ReaderT / Except</code></pre></td><td valign="top"><pre><code>term ::= &quot;do&quot; &quot;{&quot; psDoSeq &quot;}&quot;
psDoItem ::= psBaseDoItem | psVerifiedDoItemP0 | psStagedDoItemP1
// Source selection §0B / §11.7: P1 arm needs explicit registration
// P0 verified arms retain their 4.35.0 typed and proof-effect prerequisites
// Original Lean effect types; checked WP law evidence required</code></pre></td></tr></tbody></table>

**Side-by-side examples.**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>def pureAdd (a b : Nat) : Id Nat := do
  return a + b

def checkedDiv (n d : Nat) : Except String Nat :=
  if d == 0 then .error &quot;zero&quot; else .ok (n / d)</code></pre></td><td valign="top"><pre><code>function pureAdd(a: Nat, b: Nat): Id Nat := do {
  return a + b
}

function checkedDiv(n: Nat, d: Nat): Except String Nat := {
  if (d == 0) { .error(&quot;zero&quot;) }
  else { .ok(n / d) }
}</code></pre></td></tr></tbody></table>

**Source language distinction.** PSCV0 requires proof-capable semantics for at least identity/pure, state, reader, and typed error effects. The existence of a `Monad`/`StateM` class instance alone does not verify effects. Raw `IO` and external world operations remain outside closed verified computation without an accepted model. This is a **language/effect-profile** distinction, not backend design.


## 7A. Lean-native inspection and development commands in `pscv0`

**Retained decision:** The current `pscv0` design already admits `#check`, `#eval`, `#print`, and `#reduce` as native Lean diagnostic/inspection commands (the older RC3 Standard proposal treated several tooling commands differently). They are **not** new kernel semantics, proof axioms, or deployment entry points. They can be supported by the same Lean parser/term-elaboration services without weakening the kernel.

### Command family and intended grammar

| Lean native command | `pscv0` accepted form | Meaning / gate |
|---|---|---|
| `#check term` | **yes** | elaborate a term and report its type; may report unresolved metavariables in a development diagnostic |
| `#print ident` | **yes** | inspect declaration/signature and selected definition information |
| `#print axioms ident` | **yes** | inspect the transitive axiom/dependency set of a named proposition/declaration; not a replacement for the release assurance audit |
| `#reduce term` | **yes** | kernel-style definitional reduction/normalization for inspection, subject to resource limits |
| `#eval term` | **yes, restricted** | evaluate a pure, total executable term for feedback; printing is not proof |
| `#eval!`, unrestricted `#eval` of `IO` | **no** in closed `pscv0` | no bypass around effect/axiom/partial policy |
| `#check_failure`, `#synth`, `#guard`, `#eval_msgs`, `#print commands` | **not in minimum closed grammar** | may be added only after a separately versioned source-feature decision |
| `set_option` (source-affecting) | **not in minimum closed grammar** | configure a tool session separately; formatter/diagnostic output controls are not proof authority |

**Lean grammar (schematic):**

```text
command ::= ... | "#check" term | "#print" ident
          | "#print" "axioms" ident | "#reduce" term | "#eval" term
```

The important feature is **not** a special parser just for `#check`: `#check` receives a normal ProofScript term, including a function call such as `MathOps.twice(7)`, and elaborates it using the **same selected Lean typing environment** as other terms. `#check MathOps.twice (7)` and `#eval result ()` are rejected **as applications** by `PSCV0-APP-02`, but `#check (MathOps.twice 7)` and `#eval (1 + 2 : Nat)` are valid grouped term arguments. This is the same rule as in ordinary code and `by` blocks. In the full Lean syntax this command is available during editing without introducing a global declaration or runtime effect.

**ProofScript overlay:** same command heads and ordinary `pscv0` term grammar inside the command; `#eval` additionally has a pure-total/allowed-dependency static predicate. Diagnostic commands are valid among ordinary commands in files, sections, and namespaces, subject to standard import-header rules. A command's output is neither a declaration nor an export and is not a verified proof term.

### Side-by-side runnable-intent examples

| Lean 4.35.0 | ProofScript `pscv0` |
|---|---|
| `#check Nat.succ` | `#check Nat.succ` |
| `#check Nat.add 1 2` | `#check Nat.add(1, 2)` |
| `#eval (1 + 2 : Nat)` | `#eval (1 + 2 : Nat)` |
| `#reduce (Nat.succ 2)` | `#reduce Nat.succ(2)` |
| `#print Nat.add` | `#print Nat.add` |
| `#print axioms Nat.add_comm` | `#print axioms Nat.add_comm` |

**Security and soundness boundary (v7.1):** Native Lean `#eval` may run world effects; PSCV0's closed-source `#eval` remains intentionally **pure/total and effect-limited**. Even though `partial` and qualified `unsafe` functions may now be admitted in ordinary source, their execution by this closed diagnostic remains prohibited. An explicitly weaker development-only evaluator could execute them under a visible non-proof identity. `#reduce`, `#check` and `#print` may inspect proofs but cannot discharge a missing obligation; `#print axioms` is an aid, not an artifact certificate.

Sources: [Lean Interacting with Lean](https://lean-lang.org/doc/reference/4.35.0/Interacting-with-Lean/), pinned [Lean Parser/Command.lean](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Parser/Command.lean), pinned [Init/Notation.lean](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Notation.lean).

### `#check`, scopes and practical proof interaction

Use Lean's command **unchanged** in `.ps`:

```proofscript
namespace MathOps
  function twice(n: Nat): Nat := n + n
end MathOps

#check MathOps.twice  -- signature includes (n : Nat) : Nat
#check MathOps.twice(7)  -- result type: Nat
#eval MathOps.twice(7)   -- 14

open MathOps
section
  variable (n: Nat)
  def result: Nat := twice(n)
  #check n               -- valid here: n is a section parameter
end

#check result             -- has explicit parameter (n : Nat)
#eval result(7)           -- 14
```

`#check` is a **typed inspection** tool, `#eval` runs admitted executable code, `#print` displays declarations, and `#print axioms` reports transitive logical assumptions. **None is a proof tactic or a substitute for proof closure.** An editor may show a partly elaborated goal while a file has unsolved work; a verified build must still reject unsolved obligations and disallowed assumptions. The distinction between an incomplete *editor buffer* and a *verified executable artifact* is mandatory.

### `pscv0` VS Code / LSP theorem-proving experience (informative target)

The language design should enable **the Lean-style development experience**, not merely accept a few `#` commands. Required user-visible capabilities for an eventual `.ps` language server/extension are: cursor-position tactic goals with local hypotheses; goals before and after each tactic, including `·`, `case`, `next`, `rw`, `simp`, `omega` and `grind`; expected/inferred types; syntax and elaboration diagnostics; completion, hover, go to definition, references and namespace lookup; theorem/instance exploration; `#check`/`#eval` output; and clearly marked unresolved proof obligations.

The best reuse path is to integrate with Lean's pinned elaboration and **InfoTree/Infoview interaction model** while retaining exact `.ps` source spans for user-facing navigation. Rewriting a `.ps` file to `.lean` text without accurate source-position mappings is insufficient for a high-quality proof editor. See the [Lean VS Code extension](https://github.com/leanprover/vscode-lean4) and [Infoview embedding notes](https://github.com/leanprover/vscode-lean4/tree/master/lean4-infoview).

**Important distinction:** proof-editor *experience parity* does not automatically mean *feature parity* with unrestricted Lean. The selected `pscv0` proof grammar may exclude some Lean macros, imported tactics or syntax extensions. For broadly comparable theorem proving, prioritize native Lean tactic grammar and proof-producing libraries, with explicitly versioned/approved environments and final kernel checking, rather than reinventing a smaller, incompatible tactic language. Do not claim complete Lean tactic/library coverage before it is tested.


## 7B. Lean `do` exceptions and ordinary-versus-verified execution

### Typed error handling with selected native `do` forms

**Decision:** add typed Lean monadic `throw`, `try`/`catch`, and `finally` to the admitted `do` capability *where the required class instances and elaboration rules exist*. Unlike JavaScript `throw`, these are not ambient unchecked exceptions: the surrounding monad chooses the error type/handling semantics, and a `try`/`finally` clause requires the appropriate `MonadFinally` support.

**Lean grammar family (schematic):**

```text
doSeqItem ::= ... | 'try' doSeq ('catch' catchAlt)* ('finally' doSeq)?
                   | 'throw' term | 'let' pattern '←' term
```

**`pscv0` modification (schematic):** select **the corresponding pinned 4.35.0 `do` categories** and use canonical braced do/catch/finally sub-bodies. No `new Error`, JavaScript exception object or implicit `Promise` semantics are added. Exact accepted delimiters and catch binder alternatives must be confirmed against the pinned `Lean.Parser.Do` grammar; the examples are proposed `pscv0` shapes, not compiler-tested parser fixtures.

**Lean 4 idiom:**

```lean
def recover (action : Except String Nat) : Except String Nat := do
  try
    let n ← action
    return n
  catch _ =>
    return 0
```

**Proposed `pscv0` braced equivalent:**

```proofscript
function recover(action: Except String Nat): Except String Nat := do {
  try {
    let n ← action
    return n
  } catch _ => {
    return 0
  }
}
```

The `catch` handler here is typed via `Except String`, not inferred from JS runtime values. `finally` is **only valid** when the effect model has an admitted `MonadFinally` instance with known semantics; it is not guaranteed for every monad. `assert P` remains proof-only and must not be conflated with throwing an ordinary typed error.

### Ordinary checked programs, external boundaries, and verified executable proofs — v7.1

| Source/action | Explicit ordinary type-checked program | Closed verified executable | Boundary-qualified verified executable |
|---|---|---|---|
| Total pure `def`/`function` | Accept after ordinary typing/environment checks | Accept only with mandatory accepted specification/proofs and required backend evidence | Same, with explicitly disclosed approved boundary assumptions |
| `partial def` / `partial function` | Accept only after inhabited result, type checks, valid runtime lowering | **No** proof from its opaque body; accept only when an independent checked operational/refinement proof establishes the requested correctness and trace/divergence properties | Same internal proofs, plus any explicitly allowed runtime assumptions |
| `partial_fixpoint` | Admit only if pinned fixpoint/monotonicity construction succeeds | Check generated equations, application-specific contracts and required executable/backend refinement; termination must be proven when promised | Same internal proof; audited runtime assumptions disclosed |
| Restricted `unsafe def` / `unsafe function` | Admitted only for registered typed target capability, with ordinary unverified identity | Reject unless exact implementation correspondence and applicable safety/effect/refinement obligations are **formally established** | Only with explicit separately approved named assumptions, and **never** described as closed verification |
| `while` with invariant and decreasing | Allowed under admitted typed executable semantics | Total-proof rule: init/preservation/exit/decrease and effects | Same, assumptions explicitly qualified |
| Potentially unbounded `while` (staged) | Ordinary typed loop where source profile enables it | Invariant/finite-trace proof and promised progress properties; **ENV/VC-PROOF reject** until sound staged model exists | Same checked internal trace obligations and documented approved boundary assumptions |
| Typed `Except`/`State`/`Reader` | Typed available effects | Verify required weakest-precondition and effect laws | Checked model or disclosed approved external assumptions |
| `IO`, clock, filesystem, network, FFI | Declared typed runtime capabilities; no automatic behavior proof | Not closed without formal connection between implementation and required specification | Possible only with explicit audited assumptions and non-closed identity |
| `xs[i]!` possible panic | Typed runtime panic behavior | No in-bounds proof from `!` notation alone; cover panic path in contract or use safe indexing | Same |
| Proof-only `noncomputable` | Permitted for proofs/specification, no runtime computational dependency | Same and tighter assumption closure | Same |
| User `axiom`, `sorry`/`sorryAx`, unresolved metavariables | **Never** emit | **Never** emit | **Never** emit |
| Imported audited axioms | Disclose exact permitted logical assumptions | Permit only approved closed axiom set | Permit only approved named assumptions, not proof holes |

**`PSCV0-TRUST-02` (unchanged, fail-closed).** In every emitted output, source and transitive generated `sorry`/`sorryAx` or unassigned metavariables block release. User source `axiom` remains forbidden. Imported axioms need immutable provenance and assurance-policy membership. Neither a checked FFI signature nor `unsafe` typing can establish runtime behavioral correctness. There is **no** downgrade from requested verified output to ordinary output.

**`PSCV0-VERIFY-PARTIAL-01` (new).** Verified admission of a partial function requires a kernel-checkable mathematical model *and a sound correspondence to the executable body*. Generated `partial_fixpoint` equations justify logical reasoning but are not by themselves an implementation or backend correctness theorem; `partial def` is opaque, so no equation is inferred merely from its body. Prove partial correctness for successful results and finite-prefix safety under all relevant modeled states/effects. Termination, responsiveness, fairness or progress are mandatory precisely when specified, not silently dropped.

**`PSCV0-UNSAFE-01` (new).** Verified unsafe dependencies are closed only when corresponding behavior is actually proven. Boundary-qualified outputs may disclose approved assumptions but may never claim an unconditional proof of that behavior. Under a strict no-unproven-runtime-boundary policy, emission is denied rather than accepting a mere assumption.

**One language, distinguishable assurance identities.** Ordinary output is an explicit, non-behavioral-guarantee choice; closed verified output requires complete self-contained assurance under the approved foundation; boundary-qualified verification always identifies exactly which external contracts are assumed. All proof terms are Lean-grounded and kernel checked, and all runtime/backend promises require additional independent evidence. The current document is a specification, not evidence that the corresponding PSC0 checker/backend gates are implemented.

**Research basis:** [stable Lean recursive definitions](https://lean-lang.org/doc/reference/4.35.0/Definitions/Recursive-Definitions/), [stable Lean modules](https://lean-lang.org/doc/reference/4.35.0/Source-Files-and-Modules/), [Lean 4.35.0 intrinsic verification](https://lean-lang.org/doc/reference/4.35.0/releases/v4.35.0/).

## 8. Operators, basis types, and language subset

### Operator precedence and associativity

The table below reproduces ProofScript Standard's exact **source operator notation** and binding strengths from Chapter 24.2. It is **not** a claim that Lean's full, extensible notation table uses precisely the same precedence. Both languages share much of the spelling and Lean-grounded target meaning. `L` = left-associative, `R` = right-associative, `N` = non-associative. Parenthesized calls/field suffixes bind more tightly than these infix operators.

| Source | Kind | Prec. | Semantic target |
|---|---:|---:|---|
| `->`, `→` | R | 25 | Pi/non-dependent arrow |
| `∨`, `\/` | R | 30 | `Or` |
| `\|\|` | L | 30 | Boolean `or` |
| `∧`, `/\\` | R | 35 | `And` |
| `&&` | L | 35 | Boolean `and` |
| `×` | R | 35 | `Prod` |
| `<`, `<=`, `≤`, `>`, `>=`, `≥` | N | 50 | `LT`/`LE`/`GT`/`GE` |
| `=` | N | 50 | `Eq` propositional equality |
| `≠` | N | 50 | `Not (Eq ...)` |
| `==` | N | 50 | `BEq.beq` Boolean equality |
| `!=` | N | 50 | pinned `bne`, definitionally `!(a == b)` |
| `+`, binary `-`, `++` | L | 65 | add/sub/append |
| `::` | R | 67 | `List.cons` |
| `*`, `/`, `%` | L | 70 | mul/div/mod |
| prefix `-` | prefix | 75 | negation |
| `<<<`, `>>>` | L | 75 | shifts |
| `^` | R | 80 | power |
| prefix `¬` | prefix | operand 40 | `Not` |
| prefix `!` | prefix | operand 40 | Boolean `not` |

**Spelling examples (side by side):**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>def arith (a b : Nat) : Nat := a + b * 2
def equal (a b : Nat) : Prop := a = b
def sameBool (a b : Nat) : Bool := a == b</code></pre></td><td valign="top"><pre><code>function arith(a: Nat, b: Nat): Nat := a + b * 2
function equal(a: Nat, b: Nat): Prop := a = b
function sameBool(a: Nat, b: Nat): Bool := a == b</code></pre></td></tr></tbody></table>

ProofScript forbids user-defined Standard notation and rejects unparenthesized chaining of nonassociative precedence-50 comparisons (`a < b < c`, `a = b = c`). Its `&&` and `||` are Boolean operations, while `∧`, `∨`, `¬` are propositional connectives. `≠` is `Not (Eq ...)`, `!=` is Boolean inequality; `Nat`/`Int` arithmetic retains exact Lean-grounded meaning.

### Complete `pscv0` type inventory: foundational, scalar, algebraic, and proof-indexed

This section makes a **closed intended `pscv0` baseline** explicit rather than relying on the vague phrase “Lean-compatible data types.” It distinguishes **core/kernel language constructors**, **Lean prelude/basic data**, and **curated Lean libraries**. “Required” is a design requirement for a future conforming `pscv0` environment, **not evidence the compiler already implements the type**. Lean is the semantic and library source, not JavaScript/TypeScript.

#### A. Core type-theory and logical forms (not ordinary runtime primitives)

| Family | `pscv0` status | Description / distinction |
|---|---|---|
| `Prop`, `Sort u`, `Type u` | **required — Lean core** | propositions and universes; `Type u = Sort (u+1)` |
| dependent Pi `(x : A) → B x`, `A → B` | **required — Lean core** | dependent and ordinary function types, not a JS arity system |
| `Eq` / `=`, `HEq` where explicitly imported | `Eq` **required**; `HEq` library-gated | propositional proof families, not Boolean `==` |
| `True`, `False`, `And`, `Or`, `Not`, `Exists` | **required — Lean prelude** | propositions; their proofs are computationally irrelevant where the Lean theory permits |
| `Quot` logical foundation | **required semantic support, restricted source use** | Lean kernel-provided quotient machinery, no new PSCV0 quotient axiom |
| `Subtype p` | **required — dependent data** | value plus proof; `{x : A // p x}` is selected Lean notation |

#### B. Required scalar/basic executable families

| Type | Kind | `pscv0` guarantee / example | Special care |
|---|---|---|---|
| `Unit` | inductive single-value type | `()` | a value, not a JS zero-arity call marker |
| `Bool` | inductive data | `true`, `false` | separate from `Prop`; `== : Bool` when `BEq` is available |
| `Nat` | exact naturals | `(42 : Nat)` | unbounded; subtraction saturates at 0 |
| `Int` | exact signed integers | `(-42 : Int)` | unbounded; never silently JS `number` |
| `UInt8`, `UInt16`, `UInt32`, `UInt64` | fixed unsigned | `(255 : UInt8)` | modulo-width literal/arithmetic semantics per Lean |
| `USize` | target-word unsigned | `(1 : USize)` | target word size is a defined platform assumption |
| `Int8`, `Int16`, `Int32`, `Int64` | fixed signed | `(-1 : Int8)` | two's-complement Lean model |
| `ISize` | target-word signed | `(1 : ISize)` | platform-specific word-width model |
| `Float`, `Float32` | floating-point | `(1.25 : Float)` | Lean pinned IEEE-related semantics, not mathematical reals |
| `Char` | Unicode character type | `'a'` | character validity follows Lean, not JS UTF-16 units |
| `String` | Lean string abstraction | `"Ada"` | source string operations must preserve Lean semantics |
| `ByteArray` | packed byte array | `(ByteArray.empty : ByteArray)` | distinct from `Array UInt8` in operational representation and API |

Do **not** call every row a **kernel primitive**. For example, `Bool`, signed fixed-width numbers, and strings have Lean declarations and implementations; some have compiler/runtime optimizations, and only a smaller core subset has special kernel treatment. The exact **closed initial instances/operators** must be frozen in a `pscv0` environment manifest before a toolchain can claim complete conformance.

#### C. Required algebraic/container/dependent families

| Type/family | Kind | Canonical Lean / `pscv0` syntax | Notes |
|---|---|---|---|
| `Empty` | empty inductive | `Empty` | **newly adopted** first-party type; differs from `False : Prop` |
| `Prod α β` | binary product | `(a, b)` | right-nested tuples where applicable; one tuple is one argument |
| `Sum α β` | tagged sum | `Sum.inl a`, `Sum.inr b` | not TS union type |
| `Option α` | option | `.some(x)`, `.none` in PSCV0 calls | no ambient JS null/undefined |
| `Except ε α` | typed result/error | `.ok(x)`, `.error(e)` | not JS thrown exception |
| `List α` | persistent inductive list | `[1, 2, 3]` | Lean notation, not automatically an `Array` |
| `Array α` | array abstraction | `#[1, 2, 3]` | Lean array syntax and API |
| `Fin n` | bounded natural | `Fin n` | carries proof of range bound |
| `BitVec n` | fixed-width bitvector | `BitVec 8` | **newly adopted required curated Lean library family** for bit-precise verification; not a kernel primitive |
| `Subtype p` | proof-carrying subset | `{x : Nat // x > 0}` | compile-time proof requirement |

`Empty` and `BitVec n` are **explicit `pscv0` design additions** relative to the uploaded RC-v2's Section 26 guaranteed basis. Their Lean semantics and source syntax are adopted, not reinvented. Actual distribution of their declarations, coercions, theorem sets, and reducibility must be verified against the frozen 4.35.0 environment.

#### D. Supported only when explicitly imported from a named Lean-derived library / profile

| Family | Intended treatment |
|---|---|
| `Vector α n`, dependent `Sigma` | curated first-party dependent containers; valuable but not part of the minimum guaranteed scalar registry |
| `Std.HashMap`, `Std.HashSet`, `Std.TreeMap`, `Std.TreeSet`, map/set APIs | opt-in approved library declarations and instances, not new grammar |
| `Range`, iterators, `ForIn` | opt-in or standard-library API; verified loops require the selected iterator's correctness/termination specifications |
| `StateM`, `ReaderT`, `ExceptT`, `Id`, monad transformers | library-defined effect families; PSCV verification additionally requires a proved weakest-precondition model |
| `IO`, platform handles, networking, raw FFI | explicit world/boundary profile only, never closed verified semantics by merely importing a type |
| user `structure`, `class`, `inductive` types | fully available under the selected Lean formation/positivity rules; their library APIs are user-defined |

A library import may provide declarations, functions, theorems, instances, and allowed attributes without adding new grammar to the closed source edition.

#### E. Source literals, infix operators, and side-by-side types

| Lean 4.35.0 | ProofScript `pscv0` |
|---|---|
| `def xs : List Nat := [1, 2, 3]` | `const xs: List Nat := [1, 2, 3]` |
| `def ys : Array Nat := #[1, 2, 3]` | `const ys: Array Nat := #[1, 2, 3]` |
| `def bytes : ByteArray := ByteArray.empty` | `const bytes: ByteArray := ByteArray.empty` |
| `def mask : BitVec 8 := 0xff` | `const mask: BitVec 8 := 0xff` (provided selected numeral instance) |
| `def small : UInt8 := 255` | `const small: UInt8 := 255` |
| `def maybeN : Option Nat := some 3` | `const maybeN: Option Nat := .some(3)` |
| `def pair : Nat × Bool := (1, true)` | `const pair: Nat × Bool := (1, true)` |

**Literal caveat:** natural/scientific tokens are elaborated using selected `OfNat` / `OfScientific` instances; a float token without an expected type requires a pinned default. `Nat`/`Int` are exact, fixed-width integers wrap as Lean specifies, and floats preserve pinned floating semantics. `= : Prop` and `== : Bool` remain separate. `[x,y]` and `#[x,y]` are **not interchangeable**. `BitVec n` numeral syntax and `ByteArray` APIs need source/instance verification, not speculative compiler intrinsics.

Primary sources: [Lean Basic Types](https://lean-lang.org/doc/reference/4.35.0/Basic-Types/), [Fixed-Precision Integers](https://lean-lang.org/doc/reference/4.35.0/Basic-Types/Fixed-Precision-Integers/), [Function Application](https://lean-lang.org/doc/reference/4.35.0/Terms/Function-Application/), and the uploaded original RC-v2 Chapter 26.

### Feature admission: selected Lean syntax, PSCV0 overlay, and exclusions

| Feature | Native Lean 4.35.0 | `pscv0` decision |
|---|---|---|
| `def`, `abbrev`, `opaque`, `theorem`, `example` | ordinary Lean declarations | retain selected native meaning; `.ps` binder groups are comma-separated |
| `function`, `const` | not Lean declaration heads | **keep** as identity-bearing programming sugar for `def` |
| `Prop`, `Type`, `Sort`, Pi, equality, inductives | native type foundation | adopt without alternative type system |
| Scalar and container families | Lean prelude/Std declarations | require explicit roster in §8; preserve exact semantics |
| `if let`, `nomatch`, multi-discriminant `match` | native Lean eliminator/pattern grammar | selected **P0** source families, braced `.ps` clauses |
| Native `deriving` | pinned deriving handlers | **P0** allowlist for structures/inductives, checked generated instances |
| `GetElem` notation | native `xs[i]`, `xs[i]?`, `xs[i]!`, `xs[i]'h` | **P0**; proof/Option/panic distinctions maintained |
| Strings | native `s!` interpolation, raw literals | **P0**, including `.ps`-checked embedded terms |
| Monadic `try`/`catch`/`finally` | Lean `do` exception/`MonadFinally` semantics | **P1 staged**; exact braced parser tests pending |
| Maps, sets, JSON, HTTP, tasks | Std/runtime API families | **P1 library or explicit boundary**, not new grammar |
| Proof extensions | tactic/notation registrations | **P1** opt-in exact environment; kernel/assumptions remain authoritative |
| Ordinary checked versus verified executable | same Lean-grounded terms | one grammar, different evidence/emission claims (§7B) |
| Native math notation | `∀`/`forall`, `∃`/`exists`, `λ`/`fun`, `→`/`->`, etc. | **accept actual Lean aliases**, not new `exist` or `and` keywords |
| Native application `f x y` | Lean curried application | keep; type/proof terms remain Lean-like |
| Adjacent `f(x, y)` | new ProofScript surface call | retain two-argument call lowering |
| Gap parenthesized argument `f (x)`, `f (x, y)`, `f ()` | meaningful Lean application forms | **reject in `.ps`**; use unambiguous `f(x)`, `f((x, y))`, `f(())` |
| `f()` | source-empty call sugar | allowed only for defaults/automatics or exactly one required Unit |
| `if`, `match`, `do`, `by`, `where` bodies | native Lean layout syntax | **one braced `.ps` form** per family; `.lean` unchanged |
| Proof `·`, `case`, `next` | native Lean tactic goal control | **admit** selected pinned forms, not ASCII dot alias |
| Subtype/proof fields | native `Subtype`, `{x // P x}`, structure proofs | **retain native Lean**, remove `refine type` / invariant suffix |
| Verification-only state | 4.35.0 native experimental `erased` | use `erased`, `erased mut`, erased bind (not `ghost`) |
| Intrinsic contracts | 4.35.0 `given`, `requires`, `ensures`, `assert`, `invariant`, `decreasing` | retain selected native spellings under strict proof policy |
| Verification proof | Lean `theorem` / `by` / `vcgen` | no redundant `verify` keyword |
| Frame/error sugar | no confirmed direct equivalent in 4.35.0 language grammar | **deferred**, use Lean predicates/effect models for now |
| `#check`, `#print`, `#reduce`, bounded `#eval` | native diagnostics | accept as non-authoritative inspection commands |
| `partial`, `partial_fixpoint`, restricted `unsafe` | Lean supports these distinct forms | v7.1 source admission gated by `PSCV0-TERM-02`, `PSCV0-FIXPOINT-01`, `PSCV0-UNSAFE-01`; verified emission requires actual proof/runtime evidence (§5, §7B) |
| user `axiom`, proof holes | Lean permits explicit assumptions and `sorry` development holes | reject user axioms in **all** `.ps` source; reject `sorryAx` in all emitted outputs; audit permitted imported assumptions separately |
| Raw `IO`, `extern`, aliased/concurrent mutable state | Lean runtime/FFI constructs | permitted only through typed, declared boundary capability where selected; never silently closed verified |
| User `syntax`, macros, custom elaborators | Lean source extensibility | not part of closed `.ps`; separate named extensible profile only |

## 8A. First-party application-library capability surface (no new keywords)

**Why this section exists:** a catalog of Lean data type *names* is not enough to make ProofScript practical for TypeScript developers. The distinction is between **syntax guarantees** already selected above and **curated APIs** that must actually ship or be reachable through frozen, versioned imports. The latter are not automatic additions to `pscv0`'s parser.

| Application task | Lean-grounded `pscv0` capability | Ownership / release evidence |
|---|---|---|
| Arrays and lists | `Array`, `List`, constructors/literals, `map`, `fold`, `filter`, `push`, `append`, iteration, safe indexing | native notation plus pinned library types/functions/instances; check signatures |
| Maps and sets | `Std.HashMap`, `Std.HashSet`, appropriate tree variants, lookup/insert/erase/iteration | curated P1 Std library; import and exact API signatures required |
| Optional and typed failures | `Option`, `Except`, `ExceptT`, `OptionT`, `getD`, `map`, monadic propagation | standard data types + verified effect specs when applicable |
| Strings, bytes, formatting | `String`, `Char`, `ByteArray`, UTF-8 conversion, `s!` strings, raw strings, string APIs | native lexing plus versioned `ToString`/other instances |
| JSON and validation | versioned JSON tree and **checked decoders** into structures/inductives/refinement values | library-only P1; no ambient `unknown`/unchecked `as` |
| Codecs/serialization | explicit encoders, decoders, schema/round-trip theorems where required | libraries; errors typed and foreign data untrusted |
| State, read-only environment, exceptions | `StateM`/`StateT`, `ReaderT`, `Except`, relevant WP/Hoare models | effect libraries and, for verified status, checked laws |
| Files, network, clocks, randomness | typed `IO`/capability wrappers and auditable signatures | explicit world-boundary P1; no closed-world proof by fiat |
| Tasks, async, cancellation | use Lean-grounded `Task`/effect abstractions initially; explicit scheduling/exception semantics | P1/P2 libraries; **do not** invent TS `async`/`await` keywords yet |
| JavaScript/TypeScript interop | typed adapter APIs and declaration import with runtime checking where needed | external boundary/tooling; `.d.ts` is not proof of JS implementation |
| Proof/theorem libraries | imported declarations, lemmas, registered tactics and notation | pinned proof environment with replay and axiom closure |

**Required release manifests:** specify imported module identities, public API declarations, builtin `GetElem`/`ToString`/numeric instances, notation and deriving handler entries, proof extension registrations, effect model and axiom dependencies. Importing a library whose type `Std.HashMap` exists does not guarantee that every recent convenience method or notation exists at the pinned 4.35.0 commit. Unknown API names should be treated as **pending** until a compiler/reference check confirms them.

### Minimal P0 API guarantees

The P0 `pscv0` environment MUST select and document concrete members for: constructing/iterating/converting `List`/`Array`, safe `GetElem`, mapping/folding/filtering, handling `Option` and `Except`, `String` formatting/encoding, and common `Nat`/`Int`/fixed-width conversions. Failure to name a stable operation is a *release gap* rather than an invitation to add syntax. At least one map/set implementation and typed JSON codec become P1 application-prelude requirements.

### Why not copy TypeScript structural typing?

The Lean alternatives are nominal structures and inductives with explicit adapter functions. A `structure` cannot be silently assigned another structure based solely on equal field names. This deliberate difference provides stable declaration identity and proof-friendly APIs. Code actions or generated adapters can reduce migration friction without redefining type soundness. Similarly, `Option` avoids nullable semantics, and a checked JSON decoder avoids uncontrolled `any` or assertions. Preserve the difference in diagnostics and examples rather than hiding it behind a superficially familiar keyword.

## 9. ProofScript identity, Lean fidelity, and deliberate deviations

`pscv0` is a **Lean-semantic subset**, not a forked type theory. The canonical surface stays TypeScript-friendly exactly where it earns its cost: `function`, `const`, comma-separated parameter groups and calls, expression-block braces, and braced control/proof bodies. Avoid extra spellings when Lean already provides readable, kernel-compatible syntax.

| Design tradeoff | Final `pscv0` choice | Why |
|---|---|---|
| `function` / `const` versus `def` | keep all three but give distinct **roles**: functional programming, parameterless values, general Lean definitions | user-facing identity; all lower to Lean declarations |
| Unicode vs text `∀`/`forall`, `∃`/`exists` | keep both native Lean notations | existing Lean syntax, common mathematical workflow |
| `ghost` vs `erased` | **erased only** | Lean 4.35.0 already supplies meaning and token |
| `refine type` vs `Subtype` | **Subtype only** | Lean already provides concise `{x : A // P x}` |
| `verify target` vs theorem/proof | **theorem / checked proof only** | one proof language is easier to audit |
| Structure-invariant suffix vs proof field | **proof fields only** | avoids hidden semantic fields and extra grammar |
| `f ()` vs `f()` vs `f(())` | reject `f ()`, use `f()` for source-empty and `f(())` for explicit Unit | fewer confused calls |
| `f (x, y)` vs `f(x, y)` | reject first **in `.ps`**, use `f((x, y))` for tuple | no whitespace-caused arity changes |
| Lean native layout vs `.ps` braced layout | one braced `.ps` form | fewer representations of the same construct |
| Tactic bullets | native middle dot **`·`** | does not collide with field selection `.` |
| Frames/typed error contracts | lean on predicates now, reevaluate new sugar later | avoid extra keywords without proven benefit |

### 9.1 A narrower and safer call rule

**Issue:** In Lean, `f (x, y)` applies `f` to *one tuple*, but ProofScript `f(x, y)` applies two arguments. Keeping both valid in `.ps` makes an ordinary space insertion potentially change meaning and typecheck accidentally.

**Resolution:** allow Lean unparenthesized application `f x y` and ProofScript adjacent `f(x, y)`, but **reject whitespace/comment/newline-separated parenthesized applications**. Use `f((x, y))` for one tuple and `f(())` for explicit Unit. This sacrifices a small fragment of Lean's exact source grammar to make `.ps` editing/formatting safer. The `.lean` compatibility path is intentionally unaffected.

### 9.2 One braced spelling for body-like source constructs

`pscv0` uses `by { ... }`, `do { ... }`, `match ... with { ... }`, `if (p) { ... } else { ... }`, `structure ... where { ... }`, `class ... where { ... }`, and braced `where` local declarations. We no longer promise a second, indentation-only Lean layout form in `.ps`; native Lean layout remains available when compiling `.lean` files under a separate bounded compatibility profile. All braces have **construct-specific Lean meaning**, never generic JS statement semantics.

### 9.3 Lean-native proof vocabulary and data semantics

Keep `erased`, `Subtype`, `Fin`, constructors, typeclass notation, theorems, tactic bullets, and mathematical symbols unchanged. `Nat`, `Int`, fixed-width integers, `Float`/`Float32`, `Bool`, `String`, `Char`, `ByteArray`, `Option`, `Except`, `List`, `Array`, `Prod`, `Sigma` (when imported), and `Subtype` retain the exact pinned type meaning rather than TypeScript/JavaScript value semantics.

## 10. Additional Lean-alignment comparisons

### Type-indexed safe indices (`Fin n`)

**Category:** Shared Lean dependent type  
**Basis:** Source Ch. 16, 26; Appendix I `LEAN-TYPE-FIN`

**Lean 4 grammar family → ProofScript overlay (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>command ::= &quot;def&quot; declId binder* (&quot;:&quot; term)? declVal
term ::= ... | &quot;Fin&quot; term | term &quot;.&quot; ident</code></pre></td><td valign="top"><pre><code>command ::= &quot;function&quot; declId psFunctionBinders (&quot;:&quot; term)? psDeclVal
term ::= ... | &quot;Fin&quot; term | term &quot;.&quot; ident
// Same dependent type and bounds proof as Lean</code></pre></td></tr></tbody></table>

**Side-by-side example**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>def atMost {n : Nat} (i : Fin n) : Nat := i.val</code></pre></td><td valign="top"><pre><code>function atMost {n: Nat}(i: Fin n): Nat := i.val</code></pre></td></tr></tbody>
</table>

**Meaning and boundary.** `Fin n` is Lean's dependent index/bounded-natural family. ProofScript inherits the same type; the syntax change is only the explicit binder group. The index proof is not a new runtime type or unchecked numeric cast.

### Proof-relevant subtypes, retaining native Lean syntax

**Lean grammar (schematic)** already includes `Subtype`, `{x : A // P x}`, and constructor notation `⟨value, proof⟩`. **`pscv0` adopts these same constructs without the unnecessary `refine type` alternate spelling.**

| Lean 4.35.0 | ProofScript `pscv0` |
|---|---|
| <pre>abbrev Positive := {n : Nat // n > 0}&#10;def p : Positive := ⟨1, by decide⟩</pre> | <pre>abbrev Positive := {n : Nat // n > 0}&#10;const p: Positive := ⟨1, by { decide }⟩</pre> |

The base value needs a proof that it satisfies the predicate; the proof is computationally irrelevant according to native Lean `Subtype` semantics. No special ProofScript proof field, runtime check, or extra cast is introduced.

### Partial application and currying remain fundamental

**Category:** Shared curried semantics  
**Basis:** Lean Function Application; source Ch. 9–10, 22.3

**Lean 4 grammar family → ProofScript overlay (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>term ::= ... | term argument+
argument ::= term | &quot;(&quot; ident &quot;:=&quot; term &quot;)&quot;</code></pre></td><td valign="top"><pre><code>term ::= ... | term argument+
            | psCallHead &quot;(&quot; psCallArgs? &quot;)&quot;
// Both elaborate to nested Lean unary applications</code></pre></td></tr></tbody></table>

**Side-by-side example**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>def add (x y : Nat) : Nat := x + y
def plusOne : Nat → Nat := add 1</code></pre></td><td valign="top"><pre><code>function add(x: Nat, y: Nat): Nat := x + y
const plusOne: Nat -&gt; Nat := add(1)</code></pre></td></tr></tbody>
</table>

**Meaning and boundary.** `f(x)` can return a function when more explicit binders remain, exactly as Lean's `f x`. An *empty* `f()` asks for bounded empty-invocation completion: defaults/automatics or exactly one required explicit `Unit`. In `.ps`, `f ()` is always rejected; the only explicit Unit call is `f(())`.

### Boolean condition versus proposition condition

**Category:** PSCV0 braced sugar over Lean conditions  
**Basis:** Lean Terms/Conditionals; source Ch. 10, 22.2

**Lean 4 grammar family → ProofScript overlay (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>term ::= ... | &quot;bif&quot; term &quot;then&quot; term &quot;else&quot; term
            | &quot;if&quot; term &quot;then&quot; term &quot;else&quot; term</code></pre></td><td valign="top"><pre><code>term ::= ... | &quot;if&quot; &quot;(&quot; term &quot;)&quot; &quot;{&quot; term &quot;}&quot;
            &quot;else&quot; &quot;{&quot; term &quot;}&quot;
// For both admissible condition types: lower to Lean `if condition then a else b`
// Lean native `bif`/`cond` is a distinct construct, not selected by ordinary PSCV0 `if`</code></pre></td></tr></tbody></table>

**Side-by-side example**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>def boolChoice (b : Bool) : Nat := if b then 1 else 0
def propChoice (n : Nat) : Nat := if n = 0 then 1 else 0</code></pre></td><td valign="top"><pre><code>function boolChoice(b: Bool): Nat := if (b) { 1 } else { 0 }
function propChoice(n: Nat): Nat := if (n = 0) { 1 } else { 0 }</code></pre></td></tr></tbody>
</table>

**Meaning and boundary — `PSCV0-IF-01`.** For both accepted `Bool` and `Prop` conditions, `if (c) { t } else { e }` lowers to the native Lean expression `if c then t else e` under 4.35.0's existing elaboration/coercion rules; **it does not silently lower a Bool condition to Lean's separate `bif ... then ... else ...` / `cond` family**. A proposition condition needs an admitted `Decidable` instance; Boolean values are handled only by Lean's actual native `if` mechanism, never JavaScript truthiness. Each *term-level* branch contains exactly one term. The distinct `do`-statement branch grammar (§3/§7) has do-sequences and may omit `else`.

### `assert!` runtime check is NOT PSCV0 proof-only `assert`

**Category:** PSCV0 verification  
**Basis:** Pinned Parser/Term.lean `assert!`; Parser/Do; source §21.10

**Lean 4 grammar family → ProofScript overlay (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>term ::= ... | &quot;assert!&quot; term ...    // runtime assertion
// &#x27;assert&#x27; is available only in pinned intrinsic verification</code></pre></td><td valign="top"><pre><code>psDoItem ::= ... | &quot;assert&quot; term
// Lean proof obligation required; `assert!` not substituted</code></pre></td></tr></tbody></table>

**Side-by-side example**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>-- Native Lean term-level runtime assertion (not formal proof):
-- assert! (n &gt; 0); n</code></pre></td><td valign="top"><pre><code>function checked(n: Nat): Id Nat := do {
  assert n = n
  return n
}</code></pre></td></tr></tbody>
</table>

**Meaning and boundary.** `assert` requires a provable proposition and contributes proof/VC semantics; Lean's `assert!` is a runtime checking mechanism. Neither proves a specification merely by running. The PSCV0 example still requires an admitted verification context and discharged obligation.

### List and array families are types, not implicit JS arrays

**Category:** Shared Lean basis type families  
**Basis:** Source Ch. 26–27; Lean Prelude/List/Array

**Lean 4 grammar family → ProofScript overlay (schematic).**

<table>
<thead><tr><th width="50%">Lean 4 grammar (schematic)</th><th width="50%">ProofScript `pscv0` modification (same Lean grammar family)</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>term ::= ... | ident argument+ | ident &quot;.&quot; ident
// `List`/`Array` are Lean data families, not grammar additions</code></pre></td><td valign="top"><pre><code>term ::= ... | ident argument+
            | psCallHead &quot;(&quot; psCallArgs? &quot;)&quot;
// Reuse Lean List / Array types and constructors</code></pre></td></tr></tbody></table>

**Side-by-side example**

<table>
<thead><tr><th width="50%">Lean 4.35.0</th><th width="50%">ProofScript `pscv0`</th></tr></thead>
<tbody><tr><td valign="top"><pre><code>def single : List Nat := List.cons 1 List.nil
def emptyArray : Array Nat := Array.empty</code></pre></td><td valign="top"><pre><code>const single: List Nat := List.cons(1, List.nil)
const emptyArray: Array Nat := Array.empty</code></pre></td></tr></tbody>
</table>

**Meaning and boundary.** The *historical source* guaranteed the basis types without a complete API/literal catalog. **This revised `pscv0` design explicitly admits native Lean list literals `[a, b]`, array literals `#[a, b]`, and indexed `GetElem` syntax** (see §3), while requiring the actual constructors, instances and convenience APIs to be frozen in the 4.35.0 environment. No JavaScript array behavior is imported. A complete application-library API is a separate, explicit requirement in §8A.

## 10A. TypeScript-to-ProofScript migration capability matrix

The objective is **not source-level JavaScript compatibility**. A general-purpose ProofScript project should nevertheless offer a practical, discoverable equivalent for common TypeScript work, even when it requires writing a proof, handling an `Option`, using a typed effect, or declaring a checked boundary.

| TypeScript programming need | `pscv0` alternative | Is language syntax missing? |
|---|---|---|
| `function` / top-level `const` | existing `function`, `const` (both Lean `def` meanings) | no |
| `interface` / structural object types | `structure`; typeclass for generic behavior, explicit adapters for related structures | **no**, intentional nominal typing |
| `type A = ...` | native Lean `abbrev`/`def` for appropriate type aliases | no new `type` alias keyword |
| `enum`, tagged union, discriminated union | `inductive` constructors + exhaustive multi-discriminant `match`, `if let` | no duplicate union syntax |
| Optional fields / nullish data | `Option α`, `.some`, `.none`, `getD`, checked matching | no `null`/`undefined` truthiness |
| Errors and `Result<T,E>` | `Except ε α`, `throw`, typed `try`/`catch` under admitted monad | **need selected Lean `do` error syntax**, not JS exceptions |
| Generic functions/interfaces | `{α : Type}`, `[C α]`, dependent Pi, typeclasses | no, but IDE explanation needed |
| Array indexing | `xs[i]` (proof), `xs[i]?` (Option), `xs[i]!` (panic) | native Lean syntax, now guaranteed |
| Arrays / lists / iterators | `Array`, `List`, `do` loops, `ForIn` and standard collections | library/pinned instance completeness needed |
| Map / Set / dictionaries | `Std.HashMap`, `Std.HashSet`, explicit typed lookup | P1 library guarantee, not syntax |
| Template strings | Lean `s!"...{expr}..."`; raw strings `r#"..."#` | now native syntax guarantee |
| `as`, `any`, unchecked coercion | checked type ascription `(x : T)`, explicit adapter/decoders, `Subtype`, proof obligations | intentionally no unsafe alias |
| `readonly`, ordinary mutable variables | immutable `let`/`def`, `let mut` and scoped assignment in `do`, verified effects | no copied JS reference semantics |
| `switch` / narrow-by-tag | selected Lean `match`, `if let`, `matches`, proof-level case analysis | now richer native feature coverage |
| `Promise` / `async` / event handling | typed task/effect libraries and IO boundaries | async *capability* P1, syntax P2 pending evidence |
| JSON response/request handling | typed JSON AST and validated decoders returning typed `Except` | P1 library/tooling, no `unknown` import as proof |
| Classes / method-call syntax | structures and typeclasses; type-directed `x.method(y)` notation | OO inheritance/prototype semantics intentionally absent |
| Importing npm/FFI libraries | explicit typed adapter and validation/boundary evidence | P1 package/runtime tooling, no magical TS semantic admission |
| Formal specifications/tests | dependent/refinement types, contracts, assertions, theorems, native Lean tactics, runtime tests separately | stronger than TS typing; tests do not stand in for proofs |

**Concrete example: discriminate a typed result without a TypeScript union.**

```proofscript
inductive Response where {
  | ok(value: Nat)
  | error(message: String)
} deriving Repr, BEq

function describe(x: Response): String := {
  match x with {
    | .ok n => s!"ok: {n}"
    | .error msg => msg
  }
}
```

**Concrete example: safe optional indexing.**

```proofscript
function getOrZero(xs: Array Nat, i: Nat): Nat := {
  match xs[i]? with {
    | .some n => n
    | .none => 0
  }
}
```

All examples remain *proposed `.ps` examples*, not actual compiler-conformance evidence. Their Lean equivalents rely on pinned selected constructors, notation, `ToString`/typeclass instances, and approved derivation handlers. The semantics of `match` and array indexing are not copied from TypeScript.

### Migration ergonomics that belong in tooling rather than grammar

The editor and converter should offer checked code actions for `f (x)` → `f(x)`, discriminated union → `inductive`, nullable fields → `Option`, JSON decoding → typed codec, index access → explicit `?`/proof path, and `switch` → `match`. Diagnostics should show **why** a proof is needed (bounds, exhaustiveness, totality, precondition), not merely report a parser failure. A conversion tool must preserve intended call arity and not change a tuple argument into two arguments.

### Language-extension threshold

A new surface keyword is justified only when an ordinary Lean feature or curated library produces repeated measurable pain across representative applications; the sugar must have one obvious lowering to Lean, preserve proofs/effects and erasure, and avoid two dangerously similar spellings. This is why `function`, `const`, and adjacent calls stay while `ghost`, `refine type`, `verify`, JS truthiness, `any`, `as`, `?.`, `??`, global JSX and premature `async`/`await` remain out of the guaranteed core.

## 11. Lean 4 grammar (schematic) → `pscv0` selected modifications

### 11.1 Grammar authority, subset meaning, and labels

The actual [Lean 4.35.0 parser](https://github.com/leanprover/lean4/tree/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Parser) determines native categories. The following **schematic** fragments document **selected native Lean productions and ProofScript's limited surface modifications**, not a separate comprehensive EBNF. `command`, `term`, `binder`, `tactic`, `doSeqItem`, `matchAlt`, `structField`, `structInstField`, `ctor`, `ident`, `level` stand for upstream Lean categories, subject to this document's closed `pscv0` selection. Ellipses represent omitted pinned alternatives, **not** permission to import all Lean syntax.

The following representation is used consistently in all language comparisons:

```text
Lean 4 grammar (schematic):
command ::= ... | 'def' declId declSig declVal
term    ::= ... | 'by' tacticSeq | term argument

pscv0 modification (schematic):
command ::= selectedLeanCommand | selectedPsDeclaration
term    ::= selectedLeanTerm | psCallHead '(' psCallArgs? ')'
-- Braced owned contexts belong to selected terms and `psDeclVal`;
-- no unscoped generic `psBracedTerm` or new term constructor is implied.

-- Negative source constraints are part of grammar acceptance, not style hints.
```

The grammar is valid only in the sense of a language *design* until executable conformance tests confirm the acceptance and desugaring rules. The selected Lean source families in §3/§4 (strings, `GetElem`, `if let`, multi-match, `nomatch`, `deriving`) are part of this grammar overlay and do not create a second independent EBNF. A new syntax family may change formatting but never the Lean proof kernel's accepted term semantics.

### 11.2 Source files, scope, and diagnostic commands

**Lean grammar (schematic):** `command ::= import | namespace | section | open | variable | declaration | #check | #print | #reduce | #eval | ...`. `pscv0` retains the selected Lean module and scope families; declaration header imports remain before non-import commands; ordinary dependencies do not register new parser grammars. `.ps` source remains UTF-8.

| Lean 4.35.0 | ProofScript `pscv0` |
|---|---|
| <pre>import Std&#10;namespace Math&#10;def one : Nat := 1&#10;end Math&#10;#check Nat.succ&#10;#print axioms Nat.add_comm</pre> | <pre>import Std&#10;namespace Math&#10;const one: Nat := 1&#10;end Math&#10;#check Nat.succ&#10;#print axioms Nat.add_comm</pre> |

`#eval` is admitted only for a pure/total executable expression supported by the pinned closed evaluation surface. Diagnostic evaluation does **not** prove contract obligations or contribute logical authority.

### 11.3 Definitions, binders, and `const` / `function`

**Lean grammar (schematic):**

```text
command ::= ... | 'def' declId declSig declVal
                  | 'theorem' declId declSig declVal
                  | 'abbrev' declId declSig declVal
binder  ::= ... | '(' ident ':' term ')' | '{' ident ':' term '}'
                  | '{{' ident ':' term '}}' | '[' classTerm ']'
```

**`pscv0` modification (schematic):**

```text
command ::= selectedLeanDeclaration
          | psConstDecl | psFunctionDecl  -- both defined in §0B
-- Authoritative binder selection: §2, PSCV0-BIND-02.
psBinderSeq ::= psNonExplicitBinder*
                (psExplicitGroup psNonExplicitBinder+)* psExplicitGroup?
psNonemptyBinderSeq ::= psBinderSeq  -- requires at least one binder
psFunctionBinders ::= psNonemptyBinderSeq
                    | psNonExplicitBinder* psNullaryFunctionGroup
psExplicitGroup ::= '(' psParam (',' psParam)* ','? ')'  -- nonempty
psNullaryFunctionGroup ::= '()'  -- only terminal group of `function`
psParam ::= ident ':' term (':=' term)?
```

These schematics describe surface shape, not complete parser precedence or all Lean modifiers. `function` and `const` lower to Lean `def`. A final nullary group **only on `function`** lowers to one hidden required `Unit` binder; it may follow nonexplicit binders, and no ordinary `psExplicitGroup` is empty. `def f()`, constructors and methods with `()` reject as initially unsupported. Nonexplicit binders may separate explicit groups without reordering, while **adjacent explicit groups fail parsing**: they must be written as one comma group in the source, not silently normalized after parsing. Non-explicit implicit/strict-implicit/instance binders remain selected Lean-native notation. `theorem` and `example` produce ordinary checked proof terms, not JS declarations.

| Lean 4.35.0 | ProofScript `pscv0` |
|---|---|
| <pre>def add (a b : Nat) : Nat := a + b&#10;def limit : Nat := 10</pre> | <pre>function add(a: Nat, b: Nat): Nat := a + b&#10;const limit: Nat := 10</pre> |

### 11.4 Application — precise Lean grammar overlay and restrictions

The native Lean [term parser](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Parser/Term.lean) recognizes juxtaposition application. Native `f (x, y)` therefore supplies one tuple, while native `f ()` supplies one `Unit` value. `pscv0` **preserves the same elaborated unary applications but rejects the spaced parenthesized argument spelling** at a completed callable expression. It also adds adjacent comma calls. The changes below are **schematic selections/constraints on Lean's grammar**, not a second independent grammar.

```text
Lean 4 grammar (schematic):
  term ::= ... | term argument | '(' term ')' | '(' term ',' term ... ')'
  binder ::= ... | '(' ident ':' term ')' | '{' ident ':' term '}'

pscv0 term overlay (schematic):
  application := selectedLeanApplication except gapParenthesizedOperand
  postfixCall := callable '(' callArg (',' callArg)* ','? ')'
              | callable '()'            -- subject to PSCV0-APP-03
  callArg := term | ident ':=' term

Source constraints, not new core constructors:
  PSCV0-APP-01: allow f x y and f(x, y); elaborate to Lean application.
  PSCV0-APP-02: reject completedCallable + trivia + '(' as an application.
  PSCV0-APP-03: f() requires a callable Pi/(admitted CoeFun) head;
                 after declared defaults, automatics and implicit/instance
                 synthesis, either no required explicit argument remains or
                 exactly one required binder is definitionally Unit; insert ();
                 reject unsolved types, non-callables and other missing values.
  PSCV0-BIND-01: do not apply APP-02 to binder or fresh-term positions.
```

| Valid `.ps` expression | Lean-equivalent meaning |
|---|---|
| `add(1, 2)` / `add 1 2` | `add 1 2` |
| `tupleFn((1, 2))` | `tupleFn (1, 2)` |
| `unitFn(())` | `unitFn ()` |
| `function now(): Nat := 42` / `now()` | hidden required Unit parameter; `now ()` in generated Lean |
| `f(g x)` / `f(g(x))` | grouped or nested argument of one call |
| `x + (y * z)` | expression grouping, **not** application |
| `variable (n: Nat)` | native typed section **binder**, **not** application |
| `fun (x: Nat) => x` | native typed lambda **binder** |
| `#check (add 1 2)` | command's first term is grouped |
| `by { exact (hp) }` | grouped proof term after the `exact` tactic head |

| Rejected `.ps` expression | Required equivalent or remedy |
|---|---|
| `add (1, 2)` | `add((1, 2))` for a tuple, or `add(1, 2)` for two arguments |
| `tupleFn (1, 2)` | `tupleFn((1, 2))` |
| `unitFn ()` | `unitFn(())` |
| `now ()` | `now()` (or explicit `now(())`) |
| `add (1)` | `add(1)` |
| `f /- gap -/ (x)` | `f(x)`; reject with `PSCV0-APP-02` (valid Lean comment trivia) |
| `exact h (hp)` inside `by { ... }` | `exact h(hp)` or `exact (h hp)` |
| `#check f (x)` | `#check f(x)` or `#check (f x)` |
| `#eval now ()` | `#eval now()` |

**Parser decision:** do **not** tokenize a blanket rule like “identifier followed by whitespace and `(` is invalid.” Instead, the selected Lean grammar first identifies the context (`binder`, `term-start`, `term-continuation`). Reject the gap-parenthesized term only in `term-continuation` when it would serve as an application argument. A fresh parenthesized term following an operator, binder head, tactic head, or diagnostic-command head remains valid. Use this same policy throughout executable code, declarations, propositions, tactic argument expressions, contract terms, and diagnostic commands.

This rule blocks invisible changes in argument count on whitespace edits while retaining dependent function types, section parameters, Lean's theorem-proving grammar and ordinary term grouping. It does not add a new runtime arity model or affect `.lean` files. See the full accepted-source decision procedure and examples in §2 (`PSCV0-APP-01` through `PSCV0-BIND-01`).

### 11.5 Terms, records, and mathematical symbols

**Lean grammar (schematic):** `term ::= 'fun' binders '=>' term | 'λ' binders '=>' term | 'forall' ... | '∀' ... | 'exists' ... | '∃' ... | '{' ident ':' term '//' term '}' | ...`.

**`pscv0` decisions:** accept native mathematics and `Subtype` notation unchanged. `exist` (singular) and a new `refine type` declaration are **not** accepted. Keep Lean's `Prod`, `Fin`, `Option`, `Except`, `List`, `Array`, structure constructors/projections, and user-annotated `Prop` terms with the selected pinned library profile. Record values (`{ field := value, ... }`) preserve Lean's nominal-structure meaning. A declaration body wrapper `:= { oneTerm }` does not introduce arbitrary JavaScript statements.

| Lean | `pscv0` |
|---|---|
| <pre>abbrev Positive := {n : Nat // n > 0}&#10;example : ∃ x : Nat, x = 0 := ⟨0, rfl⟩</pre> | <pre>abbrev Positive := {n : Nat // n > 0}&#10;example : exists x : Nat, x = 0 := by {&#10;  exact ⟨0, rfl⟩&#10;}</pre> |

### 11.6 Conditionals, multi-discriminant matching, structures, inductives, and deriving

**Lean grammar family (schematic):**

```text
term ::= ...
       | 'if' term 'then' term 'else' term
       | 'if' binderIdent ':' term 'then' term 'else' term
       | 'if' 'let' pattern ':=' term 'then' term 'else' term
       | 'nomatch' term (',' term)*
       | term 'matches' pattern
       | 'match' matchDiscriminants 'with' matchAlt+
matchAlt ::= '|' pattern (',' pattern)* '=>' term
command ::= ... | 'structure' declId ... 'where' structFields derivingClause?
               | 'inductive' declId ... 'where' ctor+ derivingClause?
```

**`pscv0` selected modification (schematic):**

```text
term ::= ...
       | 'if' '(' term ')' '{' term '}' 'else' '{' term '}'
       | 'if' '(' binderIdent ':' term ')' '{' term '}' 'else' '{' term '}'
       | 'if' 'let' selectedLeanPattern ':=' term
                    '{' term '}' 'else' '{' term '}'
       | 'nomatch' selectedLeanDiscriminants
       | term 'matches' selectedLeanPattern
       | 'match' selectedLeanDiscriminants 'with' '{' selectedLeanMatchAlt+ '}'
selectedLeanMatchAlt ::= '|' selectedLeanPattern
                            (',' selectedLeanPattern)* '=>' term
command ::= ...
          | 'structure' declId ... 'where' '{' selectedLeanStructFields '}'
                psDerivingClause?
          | 'class' declId ... 'where' '{' selectedLeanClassFields '}'
          | 'inductive' declId ... 'where' '{' selectedLeanCtorAlts '}'
                psDerivingClause?
// `psDerivingClause` is defined in §4 by PSCV0-DERIVE-01.
```

The **new selected Lean matching surface** includes more than one discriminant, optional names, dependent match generalization, and relevant constructor/tuple/list-style patterns where their pinned Lean `match_pattern` expansion and chosen environment permit them. A named `match h : x` or `match (generalizing := true) x` is native **match syntax**, not a spaced function application. Pattern sequences must align with discriminant counts; exhaustive checking, dependent motive formation, structural recursion, and checked recursor lowering remain required. `k + 1` is still **Nat-specific successor-pattern syntax**, not a general arithmetic pattern solver.

The `deriving` clause follows `PSCV0-DERIVE-01`: it is a trailing `structure`/`inductive` suffix (not an attribute or standalone Standard command), reusing native Lean class names and registered handler semantics; the initial allowlist is `Repr`, `BEq`, `DecidableEq`, `Inhabited`, `Hashable`. It does **not** grant arbitrary user handler registration, nor turn a typeclass declaration into a proven law without evidence. A derivation can fail if the required type or members do not support it.

| Lean 4.35.0 | ProofScript `pscv0` (illustrative) |
|---|---|
| <pre>def both (x y : Option Nat) : Bool :=&#10;  match x, y with&#10;  &#124; some _, some _ => true&#10;  &#124; _, _ => false</pre> | <pre>function both(x: Option Nat, y: Option Nat): Bool := {&#10;  match x, y with {&#10;    &#124; .some _, .some _ => true&#10;    &#124; _, _ => false&#10;  }&#10;}</pre> |
| <pre>structure Point where&#10;  x : Nat&#10;  y : Nat&#10;  deriving Repr, BEq</pre> | <pre>structure Point where {&#10;  x: Nat&#10;  y: Nat&#10;} deriving Repr, BEq</pre> |

Record *values* use commas; structure/class *field declarations* retain Lean-style newline sequencing. The brackets are **grammar-specific grouping**, not JavaScript object scopes. The corresponding unbraced native layout is used in `.lean`, not as a second `.ps` control-body form.

### 11.7 `do`, typed errors, `erased`, contracts, loops, and termination

**Lean grammar family (schematic):** `term ::= ... | 'do' doSeq | 'by' tacticSeq`. `doSeqItem` includes Lean's ordinary `let`, `let mut`, assignment, pattern binding, `return`, loops, selected `throw`/`try`/`catch`/`finally`, and 4.35.0 experimental erased verification state. The 4.35.0 intrinsic-verification parser/elaborator supplies experimental `given`, `requires`, `ensures`, `assert`, loop `invariant`/`decreasing`, and `vcgen` proof-construction facilities.

**`pscv0` modification (schematic):**

```text
term ::= ... | 'do' '{' psDoSeq '}'
psDoItem ::= psBaseDoItem | psVerifiedDoItemP0 | psStagedDoItemP1
psBaseDoItem ::= selectedLeanBinding | selectedLeanReturn
               | selectedLeanTermStatement | psDoIf | psDoIfLet
psVerifiedDoItemP0 ::= selectedLeanMutOrAssignment
                     | selectedLeanForOrSpecifiedWhile
                     | selectedLeanErasedOrAssert
psStagedDoItemP1 ::= selectedLeanThrowOrTryCatchFinally
// P0 verified arms require effect/verification prerequisites (§7)
// P1 arm requires explicit registration and pinned catch/monad behavior (§7B)
```

**Selection rule `PSCV0-DO-SELECT-01`:** §0B defines the exact three-arm ownership. Basic forms are part of Standard source; P0 verified items are conditional on their pinned proof/effect requirements; P1 exception handlers are **not** implicitly available from any ordinary import or generic `doSeqItem` placeholder. The category names above are schematic references to the selected forms already described in §§3, 7 and 7B, not an independent additional grammar or a blanket adoption of 4.35.0 `do` handlers.

The **outer braces and newline sequencing** are the `pscv0` overlay; `do`-level `if`/`if let` follow `PSCV0-DO-IF-01` with do-sequence arms and an optional `else`, distinct from term-level `if`. A declaration bearing a contract may carry `psContractSeq` in exact `given? requires? ensures?` order and a single contract-owned `where { finally { | spec => { ... } } }` proof tail (§7); there is no arbitrary `psContract*` grammar. **The typed monadic meaning must match the pinned Lean elaborator.** `catch`/`finally` are only admitted when the corresponding `MonadExcept`/`MonadFinally` class requirements and exact parser forms are available. The grammar line is schematic, not an assertion that the illustrative `{}` catch bodies below are already parsed by 4.35.0. A `Monad` instance alone never certifies the effect as verified.

**Vocabulary kept from Lean:** `erased` (not `ghost`), `Subtype` (not `refine type`), `termination_by`, `decreasing_by`, `given`, `requires`, `ensures`, proof-only `assert`, loop `invariant`, `decreasing`, and `vcgen` where provided by the pinned selected prover. Do **not** introduce `verify`, `old`, `reads`, `modifies`, or `errors` into the guaranteed core merely because those spellings appear in the older PSCV candidate. In typed error models, write checked Lean-grounded propositions over successful/error post-states first.

### 11.8 Tactics: native bullets and native focus, inside ProofScript braces

**Lean grammar (schematic):**

```text
term   ::= ... | 'by' tacticSeq
tactic ::= ... | 'constructor' | 'exact' term | '·' tacticSeq
                 | 'case' caseName '=>' tacticSeq | 'next' binders? '=>' tacticSeq
```

**`pscv0` modification (schematic):** `term ::= ... | 'by' '{' psTacticSeq '}'`. Source tactic text uses the native Lean tokens and syntax, with a fixed selected (not arbitrary import-extensible) tactic surface. The goal bullet **`·`** is U+00B7 middle dot; `.` remains field notation and is **not** a bullet.

| Lean (native) | ProofScript (same goal behavior) |
|---|---|
| <pre>theorem andProof (P Q : Prop) (hp : P) (hq : Q) : P ∧ Q := by&#10;  constructor&#10;  · exact hp&#10;  · exact hq</pre> | <pre>theorem andProof(P: Prop, Q: Prop, hp: P, hq: Q): P ∧ Q := by {&#10;  constructor&#10;  · exact hp&#10;  · exact hq&#10;}</pre> |

`case`, `next`, `all_goals`, and `<;>` are supported only where the selected pinned Lean tactic parser and proof-producing semantics recognize them. A tactic `;` does not become a general statement separator. No ASCII-dot bullet alias is introduced.

### 11.9 Source modifiers, types, literals, indexing, deriving handlers, and default environment

Attributes such as `@[simp]`, `@[instance]`, and `@[default_instance]` are selected from Lean's native attribute grammar under fixed initial registrations. The P0 `deriving` allowlist consists only of named, versioned Lean handlers. **`GetElem`** (`xs[i]`, `xs[i]?`, `xs[i]!`, `xs[i]'h`), `List`/`Array` literals, `s!`/raw strings and `if let` are now required selected Lean source syntax, not imported TypeScript conveniences.

The required basis-type inventory in §8 includes `Unit`, `Bool`, `Nat`, `Int`, fixed-width signed/unsigned integer families, `Float`/`Float32`, `Char`, `String`, `ByteArray`, `Prod`, `Sum`, `Option`, `Except`, `List`, `Array`, `Fin`, `Subtype`, and the explicitly adopted candidate `Empty`/`BitVec n` families. **These are different from JavaScript `number`, `string`, object, or array semantics**; some have kernel/runtime special support, others are ordinary library-defined Lean families. Map/set/JSON/io APIs belong to the versioned library/boundary capability surface in §8A, not to the grammar.

The Standard environment snapshot must freeze the source-observable instances, tactics, priority/defaulting behavior, deriving handlers, notation/attributes, imported modules and proof-extension registration identities. The Lean git commit pins upstream **source**, not the full custom `pscv0` environment digest. Until the snapshot is generated and tested, final conformance must not be claimed.

### 11.10 End-to-end side-by-side program

**Lean 4.35.0:**

```lean
structure User where
  id : Nat
  name : String

def label (u : User) (fallback : String := "anonymous") : String :=
  if u.name == "" then fallback else u.name

theorem andProof (P Q : Prop) (hp : P) (hq : Q) : P ∧ Q := by
  constructor
  · exact hp
  · exact hq

#check label
#check ∀ n : Nat, n = n
#eval label { id := 1, name := "Ada" }
```

**ProofScript `pscv0` (design illustration):**

```proofscript
structure User where {
  id: Nat
  name: String
}

function label(u: User, fallback: String := "anonymous"): String := {
  if (u.name == "") { fallback } else { u.name }
}

theorem andProof(P: Prop, Q: Prop, hp: P, hq: Q): P ∧ Q := by {
  constructor
  · exact hp
  · exact hq
}

#check label
#check forall n : Nat, n = n
#eval label({ id := 1, name := "Ada" })
```

The paired source is illustrative; exact acceptance depends on admitted static method/instance sets, 4.35.0 experimental language bindings, and actual parser/typechecker conformance.

### 11.11 Rejection examples and what schematic grammar does not prove

| Rejected `.ps` source | Reason / replacement |
|---|---|
| `f ()` | forbidden Lean spaced Unit application; write `f(())` |
| `f (x)` | forbidden spaced parenthesized application; write `f(x)` |
| `f (x, y)` | forbidden tuple/arity whitespace trap; write `f((x, y))` |
| `theorem t(P: Prop, hp: P): P := by { . exact hp }` | ASCII `.` is not Lean goal bullet; use `· exact hp` |
| `ghost mut n := 0` | no `ghost` keyword; use 4.35.0 `erased mut n := 0` in admitted `do` context |
| `refine type Positive := Nat where n => n > 0` | no `refine type`; use `abbrev Positive := {n : Nat // n > 0}` |
| `verify f := by { omega }` | no extra declaration head; use Lean theorem/checkable VC |
| `exist x : Nat, x = x` | singular `exist` is not a Lean quantifier; use `exists` or `∃` |
| `if b then 1 else 2` | native Lean layout is not `.ps` conditional; write `if (b) {1} else {2}` |
| <code>by&#10;  rfl</code> | `.ps` uses braced `by { rfl }`; native `.lean` remains unaffected |

No statement here proves actual compiler implementation or complete Lean parser compatibility. The reference is a **closed design overlay**, not a claim that arbitrary upstream Lean notation, macros, tactic parsers, or library definitions have become part of `pscv0`.

## 12. Separator, whitespace, and brace ownership

The separator policy follows Lean syntax **within** each selected construct but chooses only one source spelling for ambiguous `pscv0` bodies and argument application. There is **no universal JavaScript automatic semicolon insertion**.

| Construct | Lean 4 | `pscv0` | Separator / ownership |
|---|---|---|---|
| Explicit declaration parameter group | Lean binder telescope `(x : A) (y : B)` | `function f(x: A, y: B)` | commas inside the single group; one optional trailing comma |
| Two arguments | `f x y` | `f(x, y)` **or** Lean unparenthesized `f x y` | curry semantics; adjacent parentheses mean comma list |
| One tuple | `f (x, y)` | `f((x, y))` | one tuple term enclosed as one call argument |
| Explicit Unit | `f ()` | `f(())` | no gap-parenthesized call permitted |
| Source-empty call | not a separate native core arity | `f()` | callable head; declared defaults/automatics or exactly-one-Unit completion only; non-callable values reject |
| Values | `{ x := a, y := b }` | same | comma-separated nominal record fields |
| `Subtype` | `{x : T // P x}` | same | native double slash, not a record value |
| Structure/class declarations | Lean `where` layout | `where { ... }` | newline/layout fields, **not commas** |
| Instance fields | Lean `where` layout | `where { ... }` | native field declarations, no general comma/semicolon list |
| Match cases | `match x with \| ...` | `match x with { \| ... }` | Lean `\|` alternatives |
| Inductive constructors | `where \| ctor ...` | `where { \| ctor... }` | Lean `\|` alternatives |
| Braced declaration body | `:= term` | `:= { oneTerm }` or `:= term` | one term only, not a JS statement block |
| `if` | `if p then a else b` | `if (p) { a } else { b }` | exactly one term in each branch |
| `do` | `do` layout/brackets | `do { ... }` | native selected `doSeqItem` newline layout |
| `by` | `by` layout/brackets | `by { ... }` | selected native tactic grammar; `·` and `case` for subgoals |
| `where` locals | Lean layout | `where { ... }` | local declaration grammar |
| Mathematical symbols | `∀`, `∃`, `∧`, `↔`, `λ`, `→` | same | their native Lean counterpart spellings coexist |

### 12.1 No space before a parenthesized argument

**This is a parse rule rather than a linter preference.** Both `f(x, y)` and Lean `f (x, y)` can be meaningful, but with different arities. Therefore the latter is **not valid `.ps` when the parentheses would be an application operand**. Likewise `f ()` is rejected in that role; explicit `Unit` is `f(())`. **The rule is categorically limited to term application** and does not reject `variable (n: Nat)`, `fun (n: Nat) => ...`, `#check (f x)`, `exact (hp)`, or `x + (y * z)`. A formatter must not introduce an application gap or silently rewrite `f((x, y))` to `f(x, y)`.

### 12.2 Brace ownership

| Source | Selected grammar family | Precise meaning |
|---|---|---|
| `:= { x + 1 }` | definition body expression wrapper | exactly one term |
| `:= { id := 1, name := "Ada" }` | structure instance term | nominal expected structure, not a JS object |
| `:= {{ id := 1 }}` | body wrapper around a record value | still one structure value, not nested objects |
| `{ n : Nat // n > 0 }` | native subtype term | refined Lean type, not an expression block |
| `if (b) { a } else { c }` | conditional branches | one term per branch |
| `do { ... }` | selected Lean monadic sequencing | multiple `doSeqItem`s, no generic JS statements |
| <code>by { constructor&#10;  · exact hp&#10;  · exact hq }</code> | Lean tactic sequencing with focused goals | proof term construction, not ordinary runtime block |
| `structure S where { x: Nat }` | structure field sequence | Lean-dependent/nominal fields |
| `match x with { \| .some y => y \| .none => 0 }` | match alternatives | exhaustive selected Lean pattern checking |

### 12.3 Delimiter and Unicode hygiene

Whitespace or comments may occur between normal Lean tokens where its selected lexical rules permit them. **Only continuation of an already-completed callable with a parenthesized operand is special:** a space, line break, or comment between callable and `(` invalidates **that application** in `.ps`. This is not a global adjacency rule for binder declarations or standalone grouping. Mathematical Unicode tokens such as `∀`, `∃`, `·`, `λ`, and `→` are recognized as genuine source tokens, not editor decoration. The ASCII `.` for field notation does not become the distinct Unicode tactic bullet `·`.

## 13. Language acceptance, rejection, and minimal conformance cases

These are **proposed conformance cases**, not executed checks. Positive cases still need elaboration and proof verification under the pinned 4.35.0 environment; negative cases define **distinct** lexer, parser/adjacency, elaboration/type, registry/profile and verified-assurance rejection criteria. Each negative fixture must be otherwise well-formed for the rule it claims to test: a lexer error does **not** satisfy a required `PSCV0-APP-02` diagnostic, and a forbidden standalone `deriving` command does **not** exercise trailing-clause handler validation. In the compact cells below, written `\n` represents an actual line break in the executable source fixture, not two literal source characters.

| ID | `.ps` fragment | Expected result | Why |
|---|---|---|---|
| P-DECL-1 | `const count: Nat := 3` | accept | parameterless `def` sugar |
| P-DECL-2 | `function add(x: Nat, y: Nat): Nat := x + y` | accept | comma explicit binders |
| P-DECL-3 | `function now(): Nat := 42` | accept | required `Unit` binder lowering |
| P-CALL-1 | `add(1, 2)` | accept | two explicit arguments |
| P-CALL-2 | `add 1 2` | accept | unchanged Lean unparenthesized application |
| P-CALL-3 | `tupleFn((1, 2))` | accept for suitable tupleFn | one tuple argument |
| P-CALL-4 | `unitFn(())` | accept for suitable unitFn | one explicit `Unit` argument |
| P-CALL-5 | `now()` | accept | inserts required `Unit` from empty-call rule |
| P-CALL-6 | `greet()` with all-explicit-defaulted parameter list | accept | declared defaults applied |
| P-CALL-7 | `f(g x)` with suitable `f`, `g` | accept | Lean application inside adjacent comma call |
| P-CALL-8 | `(f)(x)` with suitable `f`, `x` | accept | grouped callable immediately followed by postfix call |
| P-CALL-9 | `f(())` applied to `function f(): Nat` | accept | explicit Unit may coincide with source-empty Unit completion |
| P-CALL-10 | `#check (f x)` with suitable `f`, `x` | accept | grouped initial term for diagnostic |
| P-CALL-11 | `x + (y * z)` with suitable operands | accept | fresh operand grouping after infix |
| P-CALL-12 | `exact (hp)` in a proof goal `P` with `hp : P` | accept | grouped initial tactic argument, not application |
| P-CALL-13 | `exact h(p)` in a proof with `h : P → Q`, `p : P` and goal `Q` | accept | same adjacent-call grammar in tactic term |
| P-CALL-14 | `#eval now()` where `now` is source-nullary/pure | accept | diagnostic uses same `f()` completion |
| P-CALL-15 | `variable (n: Nat)` | accept | grammar category is a binder, not application |
| P-CALL-16 | `fun (n: Nat) => n` | accept | grammar category is typed lambda binder |
| P-CALL-17 | `function useUnit(u: Unit): Nat := 1` then `useUnit()` | accept; core `useUnit ()` | exactly one required explicit `Unit` completed by `PSCV0-APP-03` |
| P-CALL-18 | same declaration then `useUnit(())` | accept; **same core application** as P-CALL-17 | one explicitly written `Unit` argument |
| P-CALL-19 | `abbrev OneUnit := Unit`; `function useAlias(u: OneUnit): Nat := 1`; `useAlias()` | accept if pinned definitional equality resolves `OneUnit` to `Unit` | definitional-`Unit` rather than mere token spelling |
| P-CALL-20 | `add(1)` with `add : Nat → Nat → Nat` and expected `Nat → Nat` | accept | ordinary nonempty partial application stays available |
| P-CALL-21 | `f(/- internal comment -/ x)` where `f : Nat → Nat`, `x : Nat` | accept | Lean comment is inside adjacent argument parentheses |
| P-VEC-INDEX | `Vec(α, n + 1)` in a well-scoped indexed constructor result | accept; preserve Lean `Vec α (n + 1)` meaning | dependent arguments via adjacent comma call |
| P-PROOF-1 | `by { constructor\n  · exact hp\n  · exact hq }` in `P ∧ Q` proof | accept | native Lean subgoal bullets |
| P-PROOF-2 | `by { exact ⟨0, rfl⟩ }` | accept with `∃ x, x = 0` expected | native constructor syntax |
| P-MATH-1 | `forall n : Nat, n = n` | accept | native ASCII quantifier |
| P-MATH-2 | `∀ n : Nat, n = n` | accept | native Unicode quantifier |
| P-MATH-3 | `exists n : Nat, n = 0` / `∃ n : Nat, n = 0` | accept | native existence notations |
| P-TYPE-1 | `abbrev Positive := {n : Nat // n > 0}` | accept | Lean `Subtype` notation |
| P-TYPE-2 | `const p: Positive := ⟨1, by { decide }⟩` | accept with appropriate imports | native subtype witness/proof |
| P-ERASED-1 | `erased mut steps : Nat := 0` inside admitted verified `do` | accept when 4.35.0 model available | native Lean verification state |
| P-DIAG-1 | `#check Nat.succ` | accept | native diagnostic |
| P-DIAG-2 | `#eval (1 + 2 : Nat)` | accept in pure subset | no proof authority |
| P-PAT-NAT-1 | `match n with { \| 0 => 0 \| k + 1 => k }` where `n : Nat` | accept | pinned Lean Nat successor pattern |
| P-PAT-NAT-2 | `match n with { \| 0 => 0 \| .succ k => k }` where `n : Nat` | accept | equivalent constructor syntax |
| P-PAT-NAT-3 | `match n with { \| 0 => 0 \| 1 => 1 \| k + 2 => k }` where `n : Nat` | accept | fixed positive literal successor count |
| P-SECTION-1 | `variable (n: Nat)` and `def r: Nat := n + 1` on separate lines inside `section ... end`, then `#check r` | accept | `r` has an explicit `Nat` parameter; commands are newline-separated |
| P-DIAG-SECTION | `#check MathOps.twice(7)` after defining `MathOps.twice` | accept | native inspection over PSCV0 calls |
| N-PAT-NAT-1 | `\| 1 + k => ...` in `Nat` match | **elaboration reject** | not reducible to accepted binder-constructor pattern |
| N-PAT-NAT-2 | `\| k + m => ...` with unconstrained `m` | **reject** | no arbitrary arithmetic pattern unification |
| N-PAT-NAT-3 | `\| k - 1 => ...` in `Nat` match | **reject** | subtraction is not Nat predecessor pattern syntax |
| N-CALL-1 | `now ()` | **parse reject** | spaced `Unit` application forbidden |
| N-CALL-2 | `unitFn ()` | **parse reject** | explicit unit must be `unitFn(())` |
| N-CALL-3 | `add (1, 2)` | **parse reject** | gap before parenthesized argument |
| N-CALL-4 | `tupleFn (1, 2)` | **parse reject** | tuple ambiguity removed |
| N-CALL-5 | `add (1)` | **parse reject** | only adjacent `add(1)` accepted |
| N-CALL-6 | `add/- gap -/(1, 2)` | **parser/adjacency reject: `PSCV0-APP-02`** | lexically valid Lean comment breaks head-to-`(` adjacency |
| N-CALL-6B | `add /- gap -/ (1, 2)` | **parser/adjacency reject: `PSCV0-APP-02`** | valid Lean comment plus spaces breaks adjacency |
| N-LEX-C-STYLE | `add/* gap */(1, 2)` | **lexer/syntax reject, not `PSCV0-APP-02` evidence** | C-style comments are not Lean comments |
| N-CALL-7 | `add()` with two required `Nat` parameters | **elaboration reject** | no arbitrary filler |
| N-CALL-8 | `f(x := 1, 2)` | **reject** | positional after named |
| N-CALL-9 | `h (g x)` in an expression | **parse reject** | parenthesized Lean application argument, use `h(g x)` |
| N-CALL-10 | `(h) (x)` in an expression | **parse reject** | gap-parenthesized application after grouped callable |
| N-CALL-11 | `#check f ()` | **parse reject** | commands share `.ps` term grammar, use `#check f(())` |
| N-CALL-12 | `#eval now ()` | **parse reject** | diagnostic expression cannot bypass gap rule |
| N-CALL-13 | `by { exact h (hp) }` when `h` is callable | **parse reject** | tactic argument cannot bypass gap rule |
| N-CALL-14 | `f()` with two required `Unit` parameters | **elaboration reject** | empty call cannot synthesize two required Unit values |
| N-CALL-15 | `f()` with an unresolved required non-Unit explicit parameter | **elaboration reject** | no arbitrary default or implicit partial application |
| N-CALL-16 | `const answer: Nat := 42` then `answer()` | **elaboration reject** | an ordinary `Nat` without an admitted `CoeFun` is not callable |
| N-CALL-17 | `f()` when the function requires both `Unit` and `Nat` | **elaboration reject** | completing exactly one Unit may not mask the other required argument |
| N-CALL-18 | `f()` where the remaining required binder's type is unresolved | **elaboration reject** | cannot guess a metavariable is definitionally `Unit` |
| N-VEC-GAP | `Vec α (n + 1)` used as a `.ps` constructor result-type application | **parser/adjacency reject: `PSCV0-APP-02`** | dependent type expressions obey the same application rule as program expressions |
| N-PROOF-1 | `by { constructor\n  . exact hp\n  . exact hq }` | **parse reject** | `.` is not Lean `·` bullet |
| N-PROOF-2 | `theorem bad(P: Prop): P := by { sorry }` | **ASSURANCE reject for ordinary and verified artifact emission** | incomplete editors may show holes, never emitted checked proofs |
| N-MATH-1 | `exist n : Nat, n = n` | **parse reject** | native word is `exists` |
| N-ERASED-1 | `ghost mut steps := 0` | **parse reject** | use `erased` |
| N-TYPE-1 | `refine type Positive := Nat where n => n > 0` | **parse reject** | use native `Subtype` |
| N-TYPE-2 | `structure A where { x: Nat } invariant self => ...` | **parse reject** | use explicit proof field |
| N-PROOF-3 | `verify f := by { omega }` | **parse reject** | use `theorem` / accepted VC proof |
| N-CONTROL-1 | `if b then 1 else 0` | **parse reject in `.ps`** | one braced conditional spelling |
| N-CONTROL-2 | `by\n  rfl` | **parse reject in `.ps`** | one `by { ... }` spelling |
| N-DIAG-1 | `#eval IO.println "hi"` | **reject closed source** | world effect not pure diagnostic |
| N-TRUST-1 | user `axiom h : False` | **PARSE/profile reject in all `.ps` source** | only approved **imported** assumptions can appear in an environment ledger |
| N-TRUST-2 | `partial function loop(): Nat := loop()` with only a type check, then claim it satisfies a total postcondition | **ASSURANCE reject verified output** | source partial recursion may type-check, but neither termination nor executable correctness was established |

### New P0/P1 acceptance and rejection cases (required tests, not recorded results)

| Case | `.ps` source / scenario | Expected result / invariant | Priority |
|---|---|---|---|
| P-MATCH-2 | `match x, y with { \| .some a, .some b => a + b \| _, _ => 0 }` on `Option Nat` | accepted; same two-discriminant Lean elaboration as native `match` | P0 |
| P-MATCH-DEPENDENT | `match (generalizing := true) index with { ... }` with an indexed scrutinee/motive | accepted only if pinned Lean elaboration succeeds; core evidence checked | P0 |
| P-MATCH-NAMED | `match h : value with { ... }` | binds correct equality hypothesis, not a function call | P0 |
| N-MATCH-ARITY | two discriminants but a branch provides one pattern | reject | P0 |
| N-MATCH-COVERAGE | incomplete constructor coverage | reject, no runtime `match failure` fallback | P0 |
| P-IFLET | `if let .some n := x { n } else { 0 }` where `x: Option Nat` | accepted, bound `n` visible only in success branch | P0 |
| P-DITE | `if (h : i < xs.size) { xs[i]'h } else { ... }` with matching result types | check `h`/`¬h` scopes against Lean dependent `if` | P0 |
| N-IFLET-SCOPE | reference bound `n` from success arm in else arm | reject | P0 |
| P-NOMATCH | `nomatch e` for `e: Empty` | accepted via checked empty elimination | P0 |
| N-NOMATCH | `nomatch n` where `n: Nat` | reject: constructors remain | P0 |
| P-DERIVING | `structure P where { x: Nat } deriving Repr, BEq` | trailing clause accepted only under allowlisted versioned handlers; generated declarations checked | P0 |
| P-DERIVING-INDUCTIVE | `inductive E where { \| a } deriving Repr` | selected trailing clause accepted when handler is applicable | P0 |
| N-DERIVING-UNKNOWN | `structure P where { x: Nat } deriving SomeUnregisteredClass` | **deriving handler/registry reject**, not standalone-command parser failure | P0 |
| N-DERIVING-STANDALONE | `deriving instance Repr for P` in closed Standard `.ps` | **profile/command grammar reject**, independent of allowlist | P0 |
| N-DERIVING-ATTRIBUTE | `@[deriving] structure P where { x: Nat }` | **attribute grammar reject** | P0 |
| P-INDEX-PROOF | `xs[i]'h` with `h: i < xs.size` | accepted, proof-checked `GetElem` | P0 |
| P-INDEX-OPTION | `xs[i]?` with out-of-bounds index | returns `none`, not a JS `undefined` | P0 |
| N-INDEX-PROOF | `xs[i]` with unresolved validity obligation | elaboration rejects or leaves blocking goal; never silently checked | P0 |
| P-STR-INTERP | `s!"x = {f(x)}"` | `ToString` insertion, same `.ps` call grammar inside interpolation | P0 |
| N-STR-GAP | `s!"x = {f (x)}"` | reject `.ps` gap-parenthesized application inside interpolation | P0 |
| P-STR-RAW | `r#"unescaped \n and "quotes""#` | raw string literal, no expression interpolation | P0 |
| P-EXCEPT | `try`/`catch` in `Except String` `do` block | typed handler semantics checked; exact `.ps` delimiters validated | P1 |
| N-FINALLY | `finally` without an admitted `MonadFinally` instance | typeclass/elaboration reject | P1 |
| P-PROOF-ENV | import pinned named tactic manifest and produce proof term | accepted **only** with checked proof and approved axiom closure | P1 |
| N-PROOF-ENV | unpinned installed plugin injects new notation or axiom | reject environment/verified status | P1 |
| P-ORDINARY-IO | declared `IO` boundary in ordinary checked output | allowed as ordinary executable only, with explicit effect identity | P1 |
| N-VERIFIED-IO | the same IO output claims closed verified certificate with no model | block verified emission | P0 |
| P-PARTIAL-ORDINARY | inhabited-return `partial function f(n: Nat): Nat := f(n)` in explicitly selected ordinary checked profile | **source/type acceptance** with valid recursion/backend; no verified certificate | P0 |
| N-TRUST-DERIVE | deriving handler claims a law but generated proof has hole/axiom outside policy | no closed verified acceptance | P0 |

All rows require executable implementation tests before any conformance claim. The strings shown in source/examples remain design fixtures until the formatter/parser/elaborator and Lean-reference lanes run them.

**Metamorphic assertions to execute:** `function now()` + `now()` must elaborate to the corresponding pinned Lean `def now (_u : Unit)` + `now ()`, while `now ()` is invalid **as `.ps`**; `useUnit()` and `useUnit(())` must elaborate to the **same** Lean `useUnit ()` application under the exactly-one-Unit rule, while `answer()` for `answer : Nat` rejects; `f((x,y))` must elaborate to the same core term as Lean `f (x,y)`; `f(x,y)` must elaborate to Lean `f x y`; `Vec(α, n + 1)` must preserve native dependent `Vec α (n + 1)` meaning, while `Vec α (n + 1)` rejects in `.ps`; `#check (f x)` and `exact (hp)` must remain valid fresh-term groupings; `variable (n: Nat)` and `fun (n: Nat) => n` must remain legal binders; and **the same** `PSCV0-APP-02` rejection must apply to `#check f (x)`, `by { exact h (p) }`, `f/- gap -/(x)` and `f /- gap -/ (x)` with **lexically valid** Lean comments. Keep invalid `/* ... */` as a separate lexer test. The **trailing** `deriving` rule must match the exact handler allowlist, while a standalone command fails at the command-profile gate. The native `·` bullet must produce the same focused subgoals as Lean; `forall`/`∀` and `exists`/`∃` must elaborate identically; `erased` must preserve verified noninterference; `Subtype` must use Lean's normal proof term/erasure meaning; error cases must be rejected without fallback to unrestricted Lean parser extensions.

### v5 clarification fixtures — do conditions and instance priorities (design-only)

The following rows state the selected source policy and expected stage; they are **not executed tests**. Names/types referenced in fragments require an otherwise valid fixture and a frozen Standard environment. In particular, malformed parser examples must not be counted as successful negative tests merely because another prerequisite is missing.

| ID | `.ps` fragment/scenario | Expected selection / diagnostic | Rule |
|---|---|---|---|
| P-DO-COND-TERM | `if (i < xs.size) { return () }` inside a suitable `do` block | Admit selected condition term, subject to monad/type elaboration | `PSCV0-DO-IF-01` |
| P-DO-COND-NAMED | `if (h : i < xs.size) { return some(xs[i]'h) } else { return none }` inside an appropriately typed `do` block | Admit `h` as the 4.35.0-style named proof binder; scope in branches is Lean-grounded | `PSCV0-DO-IF-01` |
| P-DO-IFLET | `if let .some n := x { return n }` in an admitted `do` context | Admit success-branch pattern binding; `else` is optional where the surrounding monad allows it | `PSCV0-DO-IF-01` |
| N-DO-IFLET-ARROW | `if let .some n ← action { return n }` | PARSE/profile reject: the `←` native `doIfLetBind` form is deferred from the initial `.ps` selection | `PSCV0-DO-IF-01` |
| P-INSTANCE-PRIO-NAMED | `instance (priority := high) : C T where { ... }` with valid class fields | PARSE admit native modifier (typeclass and field validity independently checked) | `PSCV0-INSTANCE-PRIO-01` |
| P-INSTANCE-PRIO-NUM | `instance (priority := 750) : C T where { ... }` with valid class fields | PARSE admit numeric priority, equal to its literal value | `PSCV0-INSTANCE-PRIO-01` |
| N-INSTANCE-PRIO-EXPR | `instance (priority := high + 1) : C T where { ... }` | PARSE/profile reject priority arithmetic in Standard `.ps`; native Lean supports the expression | `PSCV0-INSTANCE-PRIO-01` |
| N-INSTANCE-PRIO-UNKNOWN | `instance (priority := highest) : C T where { ... }` | PARSE/profile reject: `highest` is not an admitted priority name | `PSCV0-INSTANCE-PRIO-01` |

### v6 instance-header grammar fixtures (document-only expectations)

These are **specification fixtures**, not executed tests. Class `C`/type `T` and any instance fields are assumed to be well-scoped and appropriate in the positive cases; the purpose is to distinguish **instance-header source syntax** from later typeclass checking. `psPriority?` is the modifier *after* the `instance` keyword and *before* the optional name.

| ID | `.ps` fragment (schematic) | Intended decision / reason |
|---|---|---|
| P-INSTANCE-HDR-ANON | `instance : C T where { field := value }` | PARSE accept: anonymous header, mandatory class/type present |
| P-INSTANCE-HDR-NAMED | `instance chosen : C T where { field := value }` | PARSE accept: optional `declId` before the mandatory `:` |
| P-INSTANCE-HDR-BINDERS | `instance chosen {α: Type}[C α]: D α where { field := value }` | PARSE accept: ordered selected nonexplicit binders; typeclass/field checking still required |
| P-INSTANCE-HDR-PRIO | `instance (priority := high) chosen : C T where { field := value }` | PARSE accept: native command priority before the optional name |
| N-INSTANCE-HDR-TYPE | `instance chosen where { field := value }` | PARSE reject: missing mandatory `: term` result type |
| N-INSTANCE-HDR-EMPTY | `instance chosen() : C T where { field := value }` | PARSE reject: no nullary instance-header `()` sugar |
| N-INSTANCE-HDR-ADJACENT | `instance chosen(x: Nat)(y: Nat): C T where { field := value }` | PARSE reject `PSCV0-BIND-02`: adjacent explicit binder groups |
| N-INSTANCE-HDR-VALUE | `instance chosen : C T := v` | PARSE/profile reject: initial `.ps` instances require `where { ... }` |

`PSCV0-INSTANCE-HDR-01` is a **surface-selection rule**, not a new Lean typeclass or kernel declaration. On successful lowering, the named/anonymous header must preserve the Lean declaration identity and checked instance signature. An `instance` header can have **zero ordinary binders**, but never `function`'s explicit terminal `()` or its invented `Unit` insertion.

### 13A. Positive complete-file sketches and negative scenarios for differential test construction

The following positive cases are **complete `.ps` source sketches** (unlike the schematic expression-only rows above), while the negative table supplies **contextual scenarios still requiring independent fixture wrappers**. None has been run by a PSCV0 frontend or the pinned 4.35.0 toolchain. All `.ps` files implicitly lower to Lean 4.35.0 module mode. An implementation must create equivalent Lean files and compare parsed applications, elaborated types and checked terms, rather than crediting any generic failure. A module import's existence and typeclass registry must also be verified.

**Positive source fixture P-BINDER-INTERLEAVE (single `.ps` module):**

```proofscript
function choose(n: Nat)[Decidable(n = 0)](x: Fin(n + 1)): Nat := x.val
#check choose
```

Expected: ordered Lean Pi telescope `(n : Nat) [Decidable (n = 0)] (x : Fin (n + 1))`; no duplicate or reordered binders. The exact resulting theorem/evaluation environment is pending freeze.

**Positive source fixture P-MIXED-APP (single `.ps` module):**

```proofscript
function inc(n: Nat): Nat := n + 1
function twice(n: Nat): Nat := n + n
const v: Nat := twice inc(3)
#check v
```

Expected: `twice (inc 3)` and `Nat`, not `(twice inc) 3`. Differentially compare with Lean `public def v : Nat := twice (inc 3)` inside a `module`/`public section`. This is a deliberately falsifiable acceptance target, not an executed result.

**Positive source fixture P-MODULE-BASIC (producer `.ps`):**

```proofscript
public import Std
function inc(n: Nat): Nat := n + 1
private const localSecret: Nat := 7
```

Expected Lean module lowering has public `inc` name (body not necessarily exposed), private `localSecret`, and public re-export of `Std`'s public module scope. The importer may apply `inc`, but may not silently unfold it using `rfl` if its body is not exposed. Exported rewrite theorems and generated `f.spec` need separate visibility tests.

**Positive source fixture P-CONTRACT-VC (requires a frozen `Std.WP` environment):**

```proofscript
public import Std.WP
function plusOne(n: Nat): Id Nat
  ensures r => r = n + 1 := do {
  return n + 1
}
where {
  finally {
    | spec => {
      omega
    }
  }
}
```

Expected: translation to one Lean 4.35.0 definition plus its kernel-checkable generated `plusOne.spec` theorem; the selected `spec` tactics are attached to the very same definition. The fixture uses `public import Std.WP` conservatively because `plusOne.spec` is intended to be exported from a source-public declaration and can mention `Std.WP` in its public type. `omega` is illustrative: actual tactic registration, generated declaration visibility, proof success and module export remain **unverified**. The `public import` is a fixture design choice, not evidence that ordinary `import Std.WP` always fails.

**Two-module integration probe R01 (requires the pinned Lean toolchain and frozen Standard environment):** create `ContractProvider.ps` with the public `plusOne` contract shown above, then `ContractConsumer.ps` with `import ContractProvider` and `#check plusOne.spec`; require successful visibility of the generated specification without exposing a private proof body. Differentially run the lowered 4.35.0 modules. Repeat with provider `import Std.WP` (without `public`) and record the **actual** module diagnostic, if any: do **not** hard-code a negative result before testing whether a selected public prelude already exports the needed `Std.WP` interface. In both lanes check not only name visibility but also that the exported `plusOne.spec` type refers only to permitted public names. This is an integration requirement, **not an executed test**.

**Head-specific and constructor grammar regression fixtures:** a contracted `function f(): Id Nat` with a closed selected spec proof, and a recursively declared `function` with the terminal `()` source-nullary binder (where its definition genuinely passes Lean termination), must reach the contract/recursion elaborator rather than reject `()` as a generic binder; `def f()` must remain a PARSE rejection. `inductive Outcome where { | ok(value: Nat) }` must parse, a checked indexed constructor with a result `Vec(α, n + 1)` must parse, and `| pair(x: Nat)(y: Nat)` must reject under `PSCV0-BIND-02`. These are proposed tests requiring independent source files and valid Lean counterparts.

**Contextual positive and negative acceptance/phase fixtures:**

| ID | Complete fragment/context | Expected negative phase |
|---|---|---|
| N-BINDER-NULLARY | `def f(): Nat := 1` | PARSE: only `function` owns hidden `Unit` group |
| P-BINDER-INTERLEAVED | `function choose(n: Nat)[Decidable(n = 0)](x: Fin(n + 1)): Nat := x.val` | PARSE accept: explicit groups are separated by instance binder; Lean-dependent telescope order unchanged |
| N-BINDER-ADJACENT | `function f(x: Nat)(y: Nat): Nat := x + y` | PARSE reject `PSCV0-BIND-02`; use one `(x: Nat, y: Nat)` group |
| P-LAMBDA-BINDER | `fun (x: Nat) => x` | Admit the native 4.35.0 typed lambda binder; independent of named declaration comma groups |
| N-LAMBDA-COMMA-GROUP | `fun (x: Nat, y: Nat) => x + y` | No PSCV0 declaration-style comma-group expansion inside `fun`; excluded from selected lambda grammar |
| P-WHERE-LOCAL | <pre>function plusOne(n: Nat): Nat := helper(n)&#10;where {&#10;  def helper(x: Nat): Nat := x + 1&#10;}</pre> | PARSE accept as local `def` sugar; lower to native `where` without the local `def` keyword |
| N-WHERE-LOCAL-FUNCTION | `where { function helper(x: Nat): Nat := x }` as a local `where` form | PARSE reject; only selected local `def` form admitted initially |
| N-BINDER-CTOR-NULLARY | `inductive T where { \| nil() }` | PARSE: constructor empty binder group excluded |
| N-APP-MIXED-GAP | Given an earlier separate-line `function inc(x: Nat): Nat := x`, check `const bad: Nat := inc (1)` as the next declaration | PARSE: `PSCV0-APP-02`, not a generic lexer error or an invalid semicolon-separated declaration |
| N-PATTERN-COMMAS | match on `Option(Nat × Nat)` with branch `\| .some(x, y) => ...` | PARSE: no adjacent comma-pattern overlay |
| N-CONTRACT-REPEAT | definition containing two `requires` clauses | PARSE: `PSCV0-CONTRACT-01` |
| N-CONTRACT-ORDER | definition containing `ensures ...` before `requires ...` | PARSE: `PSCV0-CONTRACT-01` |
| N-CONTRACT-GIVEN-TYPED-BARE | definition using `given target: Nat` | PARSE: `PSCV0-GIVEN-01` |
| N-CONTRACT-NOSPEC | intrinsic contract with VCs remaining open and no adequate `spec` tactics | ELAB/VC-PROOF: generated theorem proof cannot close; ASSURANCE: no verified emission |
| N-CONTRACT-FINALLY-BARE | `where { finally { \| spec => { omega } } }` on a non-contract definition | PARSE/profile: no contract-owned proof tail |
| N-OPAQUE-BODYLESS | `opaque secret: Nat` | PARSE: excluded native alternative |
| N-INSTANCE-VALUE | `instance : Inhabited Nat := inferInstance` | PARSE/profile: initial Standard only admits `where` instance fields |
| P-DECL-HEAD-MUTUAL | `mutual` containing a selected `def` and `function` using their own legal binder groups | PARSE accepted under the two explicit declaration cores; no head-grammar relaxation |
| N-DECL-HEAD-MUTUAL-NULLARY | `mutual` containing `def bad()` | PARSE reject: `psDefDecl` does not acquire `function`'s hidden-`Unit` binder |
| P-NONCOMP-SPEC | selected `noncomputable def` used only in a proof/spec declaration, with a well-typed body and permitted dependencies | Source/ELAB eligible as proof/spec; **no** executable dependency claim |
| N-NONCOMP-EXEC | ordinary or verified emitted executable transitively depends computationally on a selected `noncomputable` definition | ASSURANCE reject both executable identities; not necessarily a parser error in the proof-only definition |
| P-DO-BASE | <pre>do {&#10;  let x ← pure(1)&#10;  return x&#10;}</pre> as a source do-sequence in a suitable `Id` context | Selected `psBaseDoItem`; statements are LF-separated in a proper fixture |
| P-DO-ERASED-VERIFIED | `erased mut steps: Nat := 0` inside a properly admitted 4.35.0 verified `do` context | Selected `psVerifiedDoItemP0`; subject to environment/proof-effect prerequisites |
| N-DO-P1-STANDARD | a typed `try`/`catch` `do` statement in initial Standard without the selected P1 environment | ENV/profile reject: P1 is staged, not implicitly admitted |
| P-DO-P1-SELECTED | the selected typed `try`/`catch` shape after explicit P1 environment activation, with required instances | Source admission conditional on frozen P1 grammar/handler selection; **not** an executed success |
| N-SOURCE-AXIOM | `axiom broken: False` in ordinary or verified source | PARSE/profile: `.ps` excludes source axioms |
| N-HOLE-ORDINARY | `theorem bad: False := by { sorry }` then ordinary artifact emission | ASSURANCE: `sorryAx` cannot be emitted even without verified label |
| N-HOLE-SUBTYPE | construction of a `Subtype` witness using `by { sorry }` | ASSURANCE: incomplete proof blocks both emitted identities |
| N-HOLE-INDEX | attempted proof of array bound with `by { sorry }` | ASSURANCE: proof hole blocks both identities |

These additional fixtures must be translated into harness-specific independent files with explicit active environment identities before being counted as executed test cases. The text intentionally does not assert a successful compiler run.

### v7.1 targeted positive and negative language-conformance fixtures (new; **not executed**)

All test programs must be formed under stable Lean 4.35.0 and an exact source/environment/target profile. A *source-accepted* fixture does not imply a *verified-emission-accepted* fixture. A negative passes only if the specified gate rejects for the intended reason; it is not sufficient to fail parsing unrelated syntax.

| Test ID | Scenario | Expected acceptance/gate |
|---|---|---|
| P-TERM-02-A | `partial function` with return `Nat` in ordinary selected profile | PARSE/ELAB accept if body is type correct and inhabited; runtime admission remains backend-gated |
| N-TERM-02-EMPTY | `partial` function whose result type is `Empty` | ELAB reject absent a sound admissibility route; no theorem `False` introduced by divergence |
| N-TERM-02-CONST | `partial const value: Nat := 0` | PARSE/profile reject invalid declaration head |
| N-TERM-02-PROOF | `partial theorem bogus: False := ...` | PARSE/profile reject; partial never provides proof authority |
| N-TERM-02-TOTAL | opaque `partial` body used to claim total correctness without termination proof | VC-PROOF/ASSURANCE reject verified emission |
| P-FIXPOINT-01-TAIL | `function search(...): Nat := ...` followed by `partial_fixpoint` with valid inhabited tail-recursive construction | ENV/ELAB/KERNEL accept fixed-point construction; ordinary/verified artifact gates remain separate |
| P-FIXPOINT-01-OPTION | Monotone `Option`-returning `partial_fixpoint` with a kernel-checked generated equation | ENV/ELAB/KERNEL accept if pinned construction and instances available |
| N-FIXPOINT-01-ORDER | `partial_fixpoint` placed before `def` as a head | PARSE reject; suffix only |
| N-FIXPOINT-01-DECREASE | Same definition uses `termination_by` and `partial_fixpoint` | ELAB/profile reject conflicting recursion strategies |
| N-FIXPOINT-01-NONMONO | Unsuitable recursive result inspection prevents required monotonicity | ELAB/VC-PROOF reject; do not admit unproved equations |
| N-FIXPOINT-01-UNPROVEN | Valid `partial_fixpoint` without the required application-specific postcondition proof | ASSURANCE reject verified emission, even when logical equations exist |
| N-FIXPOINT-01-RUNTIME | Logical equations accepted but emitter lacks required executable refinement/target proof | ASSURANCE/backend reject verified artifact |
| P-LOOP-01-TOTAL | Verified `while` with invariant/decreasing and required loop proof | Verified admit only after all VCs/target checks |
| P-LOOP-01-PARTIAL | `while` with invariant but no decreasing, in selected staged trace model, with proven finite-trace safety | Admit verified-partial only if sound model and obligations have been checked |
| N-LOOP-01-NOMODEL | Same invariant-only loop but no registered trace verifier | ENV/VC-PROOF reject verified emission |
| N-LOOP-01-VACUOUS | Infinite server only supplies a normal-return postcondition but no finite-trace safety proof | ASSURANCE reject claimed server safety |
| N-LOOP-01-LIVENESS | Loop claims responsiveness but proof covers safety only | VC-PROOF reject promised liveness |
| P-UNSAFE-01-ORDINARY | Registered typed `unsafe function` used by explicit ordinary build | Accept only as ordinary, unverified identity and allowed target capability |
| N-UNSAFE-01-UNREGISTERED | `unsafe function` without selected trusted runtime capability | ENV/profile reject |
| N-UNSAFE-01-PROOF | `unsafe`/`unsafeCast` tries to fabricate proof of `False` | PARSE/profile or KERNEL/ASSURANCE reject; no proof elevation |
| N-UNSAFE-01-CLOSED | Foreign/unsafe implementation has typed declaration but no checked implementation/refinement proof | ASSURANCE reject closed verified emission |
| P-UNSAFE-01-BOUNDARY | Foreign implementation with explicit approved assumption ledger and completed internal proofs | Qualified boundary output only when policy permits; never closed |
| N-UNSAFE-01-STRICT | Above assumption under a policy demanding fully proven external implementation | ASSURANCE reject, no weaker fallback |
| P-NONCOMP-01-PROOF | Proof-only `noncomputable` definition with allowed assumptions | Type/kernel admissible; no executable dependency |
| N-TRUST-01-AXIOM | User `axiom fabricated: False` in `.ps` | PARSE/profile reject in all output categories |
| N-TRUST-02-SORRY | Proof hole via `sorry`/`sorryAx` through a transitively imported/generated definition | ASSURANCE reject all artifacts regardless of chosen boundary profile |
| N-TRUST-02-ERASED | Partial/unsafe dependency incorrectly erased despite observable runtime effect | VC-PROOF/ASSURANCE reject noninterference |
| N-ASSURANCE-DOWNGRADE | Verified request fails but tool tries to emit ordinary executable instead | Reject; fail-closed requested identity |
| N-BACKEND-DIVERGENCE | Source/model verifies but backend transformation changes divergence, error or effect traces outside established refinement | Reject claimed closed verified artifact for that target |

**Metamorphic and differential tests:** compare source `partial function` lowering with Lean `partial def`, and source `partial_fixpoint` lowering with the exact stable Lean fixed-point environment. Independently recheck generated logical equations and proof terms with the kernel, and compare checked trace/operational semantics to emitted backend behavior. Freeze imported theorem/axiom closure, effect registrations, target ABI and module visibility. Type checking alone must never be counted as an executable behavioral proof.

**Implementation sequencing:** P0 vocabulary/source gates/ordinary recursion; P1 stable `partial_fixpoint` construction and proof availability; P1 partial/total/trace VC dependency tracking; P2 restricted unsafe and runtime/backend refinement. All remain pending until measured by CI and independent review.

## 14. Research outcome, decisions, and remaining conformance work

The design criterion was **maximum Lean semantic/syntactic reuse with only high-value ProofScript surface differences**. The following are user-requested design decisions; they are *not* claims that the compiler currently implements every feature.

| Question | Decision | Support / remaining risk |
|---|---|---|
| Lean baseline | pin **`v4.35.0`**, SHA `eb6cafb7290e8bd5f2937522d8d804f58f02bafc` | GitHub 4.35.0 release/tag and official release notes; stable release (2026-10-12) |
| Language identity | keep `const`, `function`, `def`; names lower to Lean declarations | distinctive but logically conservative |
| `f ()` vs `f()` | **reject `f ()` in `.ps` application positions** | avoids visually indistinguishable Unit application / empty call; preserve binder parentheses |
| `f (x,y)` vs `f(x,y)` | **reject `f (x,y)` in `.ps`** | prevents changing argument arity by a whitespace edit |
| `f(())` | valid explicit `Unit` argument | maps to ordinary Lean `f ()` |
| Native `f x y` | retain | useful for mathematical applications; unambiguous without parenthesized operand |
| Proof branch `. exact` | **reject ASCII `.`**; use native `· exact` | confirmed Lean tactic-language bullet is U+00B7 |
| Goal control | native `·`, `case`, `next`, selected `all_goals`, `<;>` | use upstream fixed tactic parser, never a new bullet language |
| `ghost` | **drop**; use 4.35.0 `erased` | upstream syntax present, albeit experimental |
| `refine type` | **drop**; use `Subtype` and `{x : A // P x}` | native Lean type and notation |
| Structure `invariant self` | **drop**; use proof field | avoids hidden semantic changes and redundant grammar |
| `verify target` | **drop**; use theorem / `by` / VC proof | one proof language, checked evidence |
| `∀`/`forall`, `∃`/`exists` | **both admitted** as native Lean notation | text forms are real Lean syntax; singular `exist` excluded |
| Braced vs Lean indentation body | one `.ps` braced spelling | user-facing consistency; Lean `.lean` remains native |
| `requires`, `ensures`, `given`, `invariant`, `decreasing` | retain selected Lean 4.35.0 intrinsic verification vocabulary | upstream experimental; require pinned proof semantics |
| `old` / `reads` / `modifies` / `errors` | defer as distinct language keywords | no confirmed native 4.35.0 equivalents; can start with Lean propositions/WP effects |
| Types / literals | preserve named Lean scalar, container, dependent and proof-indexed families | catalog §8; freeze exact Std environment for conformance |
| `Nat` successor matching | accept both `\| k + 1 => ...` and `\| .succ k => ...`; prefer arithmetic form in examples | pinned Lean built-in match-pattern expansion; **not** general arithmetic pattern solving |
| `variable (n : Nat)` | retain Lean section-parameter generalization under `PSCV0-BIND-01` | command binder is a different grammar category from term application; theorem statement generalization rules apply |
| Lean-style `#check` / proof editing | already accepted; specify full useful editor feedback and source spans | future VS Code/LSP InfoView target, **not** proof or unrestricted Lean feature parity |
| Multi-discriminant/dependent `match` | **adopt selected Lean 4.35.0 features** | preserves mathematical elaboration, proof terms and exhaustiveness; complete parser tests still pending |
| `if let`, `nomatch`, `matches`, let-patterns | **adopt selected Lean native terms**, with `.ps` braces where relevant | do not substitute TS union narrowing or unchecked cast semantics |
| Native `deriving` | **P0** trailing handler allowlist (`Repr`, `BEq`, `DecidableEq`, `Inhabited`, `Hashable`) | frozen handler provenance; no arbitrary dependency-based handlers |
| Strings and indexing | **P0** `s!`/raw strings, `GetElem`, `xs[i]`, `xs[i]?`, `xs[i]!`, array/list literals | pin lexer/parser and instance availability; `!` may panic |
| Monadic exceptions | **P1** admit selected `try`/`catch`/`finally` and `throw` under typed effects | exact proposed `.ps` brace mapping needs conformance; no JS exception model |
| Maps/sets, JSON, codecs, IO, HTTP, task APIs | **P1 library/boundary** guarantee, not added keywords | require stable actual Std/module signatures; distinguish external validation from proof |
| Proof tactics and theorem libraries | selected expanded native tactic grammar + **opt-in pinned extension environment** | kernel-checked output, no arbitrary proof authority; digest/registration audit |
| Ordinary versus verified artifacts | **one language; separate assurance/emission status** | ordinary typed boundaries remain unverified; mandatory proof obligations block verified output |
| Types and API completeness | preserve §8 type roster; guarantee practical P0 standard APIs in §8A | avoid “type exists therefore ergonomic library exists” false inference |

### 14.1 Primary remaining checks

1. **Parser acceptance closure.** Confirm selected Lean grammar categories and differentiate binder, fresh-term, and application-continuation positions. Exercise `PSCV0-APP-01`, `PSCV0-APP-02`, `PSCV0-APP-03`, `PSCV0-BIND-01`, and `PSCV0-DERIVE-01` in ordinary functions, dependent type expressions, structure/inductive declarations, theorem propositions, tactic terms, `do`, contracts and diagnostic commands. Keep valid Lean-comment trivia adjacency tests distinct from invalid C-style lexical tests. Also check Lean-native `Nat` patterns `k + 1`/`k + 2`, codepoint `·` versus `.`, and `exists` versus `exist`. Verify `1 + k`/`k + m` do not silently become structural constructor patterns.
2. **Elaboration correspondence.** Differentially compare `const`, `function`, named/default parameters, `f()`, `f(())`, `useUnit()`/`useUnit(())`/`useAlias()` (definitionally `Unit`), `f((x,y))`, `f(x,y)`, `Vec(α, n + 1)`, type ascription, `Subtype`, constructors and Unicode/text quantifier spellings to Lean 4.35.0 core terms. Reject `answer()` where the head has non-callable `Nat` type.
3. **Lean tactic integration.** Check the canonical multiline bullet form `by { constructor\n  · exact hp\n  · exact hq }` for goal ownership; treat `;` and `<;>` as **separate** selected tactic-combinator fixtures with their own native 4.35.0 grammar and proof semantics, not as alternative source statement separators. Check `case`, `next`, and `all_goals` without silently enabling arbitrary import-provided tactic macros.
4. **Lean 4.35 intrinsic verification.** Verify exact 4.35.0 semantics of `given`, `requires`, `ensures`, `assert`, `erased`, `invariant`, `decreasing` and `vcgen`. Upstream explicitly marks this family experimental.
5. **Partial/total verification, dependencies and erasure.** Confirm `partial def` stays opaque in logic, `partial_fixpoint` has genuinely checked equations, and `unsafe` never fabricates a proof. Check trace-safe divergence where allowed, and reject all holes, noncomputable computational dependencies, unproved runtime correspondence, and invalid erasure. If a verified claim requires termination, no partial form evades that goal.
6. **Source formatter.** Round-trip `f(x,y)`, `f((x,y))`, `f(())`, native `f x y`, `variable (n: Nat)`, `#check (f x)`, `exact (hp)`, and tactic bullet `·` without altering parse trees/Lean elaborated meaning. Confirm a whitespace-only edit never changes a well-formed two-argument call into a well-formed one-tuple call.
7. **Source provenance and Standard registry.** Pin 4.35.0 parser references, notation/token families, deriving-handler identities (`PSCV0-DERIVE-01`), built-in `match_pattern` expansions (especially `Nat.add`), numerics, signed/fixed-width values, `BitVec`, `Empty`, and supported libraries to exact generated declarations and registries; don't claim a completed Standard environment digest before it has been built.

8. **Scope and Lean tooling.** Check explicit/implicit/instance `variable` elaboration, especially theorem statement dependency selection and recursive definitions' fixed section variables. Exercise `#check`/`#eval` with `.ps` names, section-generated parameters, and unresolved proof states. Preserve InfoTree/Infoview source positions for `.ps` in the future editor/LSP integration; never infer verified status from an editor's proof-goal display.

### 14.1A Prioritized evidence and release acceptance

| Priority | Design acceptance / deliverable | Explicit unverified status |
|---|---|---|
| **P0** | `function`, `const`, braced ownership, `PSCV0-APP-*` invariants, Lean binder/section syntax, native math/proofs | source design chosen, conformance corpus not yet executed |
| **P0** | selected multi-discriminant/dependent `match`, built-in patterns, `if let`, `nomatch`, `matches` | native Lean capability verified from docs; `.ps` parser/Lean-lowering still untested |
| **P0** | trailing `deriving` with exact allowed handler registry | native Lean supported; `pscv0` braces and handler snapshot need conformance |
| **P0** | string interpolation/raw literals, list/array literals, `GetElem` variants and P0 application APIs | source grammar/instances/behavior require final environment freeze |
| **P0** | theorem goals, `·`/case/next, `simp`/`omega`/`grind`, `#check`/`#print axioms`, genuine proof validation | broader proof grammar/IDE coverage and axiom audit tests required |
| **P0** | ordinary versus verified identity; correct partial source gates and verified fail-closed proof/assumption/effect/erasure/refinement conditions | require executable negative cases: no silent verification claims for opaque partial/unsafe code |
| **P1** | typed `try`/`catch`/`finally`, map/set/JSON codecs, IO/boundary APIs, named proof environments | precise sources and extension manifests to be pinned; no hidden JS semantics |
| **P2** | async/ownership/resource/UI sugar beyond Lean libraries | defer until measured gain and verified lowering |

### 14.1B Consistency-erratum traceability (design fixtures, not executed)

| Erratum | Authoritative rule | Positive coverage | Negative coverage and required phase |
|---|---|---|---|
| E1 — trailing deriving versus attributes | `PSCV0-DERIVE-01`, §§4, 6, 11.6 | `P-DERIVING`, `P-DERIVING-INDUCTIVE` | `N-DERIVING-UNKNOWN` handler gate; `N-DERIVING-STANDALONE` command-profile gate; `N-DERIVING-ATTRIBUTE` attribute grammar |
| E2 — indexed `Vec` applications | `PSCV0-APP-01`/`02`, §4 indexed inductives | `P-VEC-INDEX` | `N-VEC-GAP` application parser; no whitespace-only arity change |
| E3 — exactly-one-required-Unit | `PSCV0-APP-03`, §2 | `P-CALL-17`–`20` | `N-CALL-14`–`18`: unsolved/missing parameters or non-callable head at elaboration |
| E4 — comments and adjacency | §1 lexer, `PSCV0-APP-02` | `P-CALL-21` (comment internal to call) | `N-CALL-6`/`6B`: application parser; `N-LEX-C-STYLE`: invalid C-style comment syntax **not** credited to adjacency |

**Verification corpus to construct:** positive and negative parsing with phase-specific diagnostics; differential Lean 4.35.0 elaboration and generated proof terms; real-world TS migration examples (JSON/collections/errors); theorem proofs including dependent matches and library tactics; specification and effect-boundary tests; formatter/source-map tests for `f(x, y)` vs `f((x, y))`, `Vec(α, n + 1)` vs native Lean `Vec α (n + 1)`, and comment-separated applications; backend semantic preservation tests. Unmeasured scores or simulated passing tests are not conformance evidence.

### 14.1C Source-policy acceptance supplement (F01–F22)

The second audit is resolved at the **design-decision** level, not claimed complete at the implementation or conformance level. Required checks are: nullary and interleaved binders (`PSCV0-BIND-02`); mixed postfix and whitespace calls (`APP-04`); constructor-pattern ownership (`PATTERN-01`); `do` conditional ownership (`DO-IF-01`); native `if` lowering (`IF-01`); contract ordering, typed `given`, import prerequisites and `spec` attachment (`CONTRACT-01` through `04`); module/public visibility and body exposure (`MODULE-01/02`); method/instance field lowering (`INSTANCE-01`); source axioms and emitted proof holes (`TRUST-01/02`). The selected bodyless-`opaque` and value-form-instance exclusions are deliberate restricted-subset decisions, not claims that Lean lacks them.

**Environment-manifest closure (still pending):** a conforming Standard snapshot must include: 4.35.0 SHA; exact module identities and public/private import graph; public-name and body-exposure policy; source-token and notation identities; term/typeclass/coercion instance priorities/default values; builtin and selected tactic registrations; `deriving` handler origins; `Std.WP` and `Gadget.assertGadget` availability; runtime-world/effect capability identities; imported axioms including assumption and `sorryAx` closure; and a reproducible digest over the complete profile. Until this manifest exists and the 4.35.0/PSCV0 differential test lanes pass, phrases such as P0/required are **future acceptance criteria**, not demonstrated environment implementations.

### 14.2 What this revision does not do

It does **not** turn `pscv0` into unrestricted Lean 4, add new kernel primitives, equate runtime testing with proof evidence, reclassify raw `IO` as closed verified computation, or claim implementation/conformance tests were executed. It deliberately removes some *proposed* RC3 ProofScript conveniences because native Lean syntax already expresses the same thing more simply. It also restricts a small part of native Lean parenthesized application **only in `.ps`**, so the semantic-subset claim remains precise.

### 14.3 Design outcome and unresolved exact-source checks

This revision's answer to “more or fewer features?” is **richer native Lean coverage and stronger libraries, but fewer redundant ProofScript sugars**. The new P0 features above are adopted as proposed source-profile requirements, not as proven implementation status. P1 proof/IO/JSON extensions require explicit environment and boundary identities. P2 new keywords require real ergonomic evidence.

The highest remaining language-design risks are: (1) keeping `f()`/defaults/`Unit` completion unambiguous in all contexts; (2) faithfully mapping multi-scrutinee and dependent match syntax, plus `if let`, to the 4.35.0 elaborator; (3) giving braces one clear grammar owner alongside record literals/`Subtype`/implicit binders; (4) ensuring `deriving` and tactics cannot alter accepted source meaning without a new environment identity; (5) exact `try`/`catch`/`finally` syntax and registered `MonadFinally` availability; and (6) preventing ordinary IO/boundary behavior from being mislabeled formally verified.

Native Lean features confirmed in current official reference: [Pattern Matching](https://lean-lang.org/doc/reference/4.35.0/Terms/Pattern-Matching/), [Conditionals](https://lean-lang.org/doc/reference/4.35.0/Terms/Conditionals/), [Deriving Instances](https://lean-lang.org/doc/reference/4.35.0/Type-Classes/Deriving-Instances/), [GetElem](https://lean-lang.org/doc/reference/4.35.0/Type-Classes/Basic-Classes/), [Strings](https://lean-lang.org/doc/reference/4.35.0/Basic-Types/Strings/), [Do Notation](https://lean-lang.org/doc/reference/4.35.0/Functors___-Monads-and--do--Notation/Syntax/), [Monadic Exceptions](https://lean-lang.org/doc/reference/4.35.0/Functors___-Monads-and--do--Notation/Varieties-of-Monads/), [Custom Tactics](https://lean-lang.org/doc/reference/4.35.0/Tactic-Proofs/Custom-Tactics/), and the [4.35 4.35.0 notes](https://lean-lang.org/doc/reference/4.35.0/releases/v4.35.0/). The immutable git commit, not a moving documentation URL, remains the specified semantic-source pin.

### 14.3A Third-pass consistency corrections and evidence boundary (C01–C05, R01)

The iterative re-audit of the 3,029-line v2 specification identified **three independently confirmed internal inconsistencies** and **one not-yet-executed source-supported integration risk**. Re-auditing the corrected v3 source identified **two additional internal grammar repetitions** (C04 and C05), now corrected. This v3 revision changes the normative text as follows:

| Finding | Correction / explicit limitation | Regression evidence required |
|---|---|---|
| C01 — source-nullary `function` | Every recursive and contract-carrying `function` production now uses `psFunctionBinders`, not `psBinderSeq`; only `function` admits a terminal `()` lowered to one required Lean `Unit` binder | Parse and elaborate ordinary, recursive and contracted nullary functions; ensure `def f()` still rejects |
| C02 — duplicated `psCtor` | One constructor grammar `\| ident psBinderSeq (":" term)?` owns both simple and indexed constructors; dependent section references this production rather than redefining it | Check implicit/explicit binder sequences, optional result-type annotations and noncanonical repeated explicit groups |
| C03 — VCs versus kernel checking | Open VCs cause **ELAB/VC-PROOF** failure, which in turn blocks verified emission at **ASSURANCE**; **KERNEL** remains reserved for an actually invalid submitted term | Compare unresolved contract goals, malformed checked terms, and separate assumption/erasure closure tests |
| R01 — contract import visibility | The complete public-contract fixture uses `public import Std.WP`; added a two-module exported `plusOne.spec` probe | Run both public/private import variants on pinned 4.35.0 and inspect exported theorem types before assigning pass/fail |

**Additional v3 audit correction C04 (repeated schematic declaration value).** §2 and the local-`where` subsection had both written `psDeclVal ::= ":=" term termination? psWhere?`, but §5 used `psTermination?` and defined the selected termination suffix. All three schematic locations now reference the *same* `psTermination?`; the wrapped single-term body has the same suffix policy. This is a grammar-name consistency fix, not an expansion of Lean termination syntax. Add positive well-founded-decrease and negative malformed-termination-source tests to the differential corpus.

**Additional v3 audit correction C05 (recursive braced-body rule).** The §5 well-founded-recursion sketch separately stated `psDeclVal ::= ":=" term psTermination? psWhere?`, which omitted the `:= { oneTerm }` alternative otherwise admitted for all definitions and used by its own recursive example. The §5 sketch now *references* the single two-alternative `psDeclVal` from §2 and states only the `psTermination` delta; therefore both ordinary and braced function bodies may carry the same termination suffix. Differential-test both spellings and malformed `decreasing_by` clauses.

**Test-fixture/Markdown repair (not a language defect).** Inline-code test cells now escape a literal alternative marker `|` using Markdown table-safe `\|`, not an HTML entity which would render verbatim inside a code span. The `N-APP-MIXED-GAP` contextual fixture no longer shows a semicolon separating two declarations while simultaneously instructing the reader to place them on different lines. These edits prevent accidental false-positive test results and preserve copyable source fragments.

**Repeat-audit rule:** only an independently supported contradiction or exact pinned-source mismatch warrants another normative correction. Absence of executable conformance evidence is reported as pending, not invented as a compiler failure. External source citations in §15 are research references; PSCV0 syntax and generated-code claims remain proposals until tested.

### 14.4 Second-pass audit disposition (F01–F22)

| Audit finding | Normative edit or explicit status |
|---|---|
| F01/F02 | Nonempty `psExplicitGroup`; only terminal `function ...()` lowers to required `Unit`; negative declaration-kind cases added |
| F03 | Native Lean `if` lowering for admitted `Bool`/`Prop` conditions, not silent `bif` |
| F04 | Ordered, potentially interleaved Lean declaration binders; maximal comma groups for consecutive explicit binders |
| F05 | Selected `psInstanceField` binder/definition shape; no call grammar inside instance field headers |
| F06 | `PSCV0-APP-04` defines mixed postfix/whitespace precedence and formatter invariants |
| F07 | `PSCV0-PATTERN-01` separates Lean pattern arguments from expression comma calls |
| F08 | `PSCV0-DO-IF-01` admits distinct braced `do` conditional sequences/optional `else` |
| F09 | `PSCV0-CONTRACT-04` adds one contract-owned `where finally` spec proof tail; no standalone theorem substitute |
| F10/F11 | Ordered/nonduplicating clauses; Lean-native typed `given (x: T)` binder |
| F12 | `Std.WP`/assert-gadget prerequisite explicit; executable evidence still pending |
| F13/F14 | Implicit Lean module lowering, exact `public import`, public names/non-exposed bodies, checked import reducibility |
| F15 | Pinned `Std` example replaces nonexistent baseline `Std.Data.List` import |
| F16/F22 | Reject source `axiom` and emitted `sorryAx` in all `.ps` modes; imports/audited assumptions separately classified |
| F17 | `Sigma(fun ...)` / `ExistsUnique(fun ...)` PSCV0-safe canonical spelling |
| F18 | Additional complete illustrative source fixtures and diagnostic-phase expectations; **not run** |
| F19 | Standard environment manifest/digest remains a named release blocker, not fabricated |
| F20 | Bodyless `opaque` and value-form `instance` intentionally excluded from initial Standard |
| F21 | Selected category glossary; retired aliases and principal glossary names aligned with schematics |

**Static consistency is necessary but not sufficient.** Exact parser acceptance, native RC4 elaboration, module exposure, `Std.WP` proof semantics, verified effect models, and kernel-accepted terms must all be tested. No score or release readiness claim follows solely from this revision.

### 14.5 v4 document-only corrective errata (D01–D04)

**D01 — canonical binder ownership.** The ordered `psBinderSeq` selection now **syntactically excludes adjacent `psExplicitGroup`s**; `psNonemptyBinderSeq` is the nonempty version for ordinary non-nullary `function` heads, and a terminal `psNullaryFunctionGroup` remains available only to `function`. Cross-references in §§0B, 2 and 11.3 use the same form. `PSCV0-BIND-02` rejects adjacent groups at PARSE rather than inferring a post-parse merge. Source `function f(x: Nat)(y: Nat)` is invalid, while `function f(x: Nat, y: Nat)` and genuine nonexplicit-binder interleaving remain admitted.

**D02 — local `where` lowering.** A `def` inside `where { ... }` is PSCV0 syntax, deliberately distinct from upstream Lean's `Term.letRecDecl` syntax, which does not begin with `def`. The selected lowering removes that local `def` token and the outer braces, converts explicit comma-group binders and terms, and preserves the local recursion/scope/termination interpretation. Only selected local `def` declarations and the already restricted contract-owned `finally`/`spec` tail are included; no ordinary local theorem/instance/mutual/attribute command is inferred.

**D03 — measure recursion tactic suffix.** The `.ps` source shape `decreasing_by by { ... }` is an explicitly owned braced tactic sequence. Its required lowering drops the source-only `by { ... }` delimiters and creates the pinned Lean `decreasing_by` tactic body; it does not pass the token `by` into Lean's tactic parser. The initial selection requires a preceding `termination_by` measure. This clarifies a formerly implicit syntax transformation rather than asserting a compiler failure.

**D04 — native lambda binder category selection.** The §3 schematic formerly used `psLambdaBinder` without a direct selected-family definition in the normative category registry. It now explicitly delegates to the pinned `Lean.Parser.Term.funBinder` family, subject to PSCV0's source-category selections. Declaration-only comma binders and `function f()` hidden-Unit lowering are not silently inherited by `fun` lambdas. This closes a documentation definition gap, not a reported Lean compiler rejection.

**Evidence status:** These are document corrections supported by comparisons with pinned Lean parser source; they are not claims of compiler conformance. Previous audit findings remain historical records, and the still-unresolved module/`Std.WP` visibility question is a separately classified integration risk, **not** a confirmed defect.

### 14.6 v5 document-only errata, source selection, and re-audit outcome

**R-v4-01 (`psDoCondition`).** §0B and §3 explicitly define the selected conditional form `Lean.Parser.Term.binderIdent ':' term | term` inside `if (...)`. `do`-level branches remain `psDoSeq` rather than one-term expression branches, and the `if let` variant uses the selected `:=` spelling only. The additional table in §13 captures positive named-proof-binder and negative unselected `←` cases.

**R-v4-02 (`psPriority`).** §0B/§4 specify the native command modifier with decimal naturals and `low`/`mid`/`default`/`high`, bound to pinned RC4 values; arbitrary RC4 priority expressions are explicitly excluded from the initial Standard source. This distinction does not change the pinned typeclass solver, source-visible ordering or Lean core semantics.

**E-v4-01 (category naming).** `psAttributes` is the selected source-attribute grammar, and `psDoSeq`/`psDoItem` are the canonical `do`-sequence categories, including the formerly unexpanded `selectedLeanDoSeq` occurrences.

**Validation boundary:** these are document selections and static text checks only. Neither PSCV0 compilation nor Lean compiler/parser/elaborator/kernel/conformance execution has been performed as part of this revision. The Standard environment digest and exported-contract cross-module visibility remain independently pending, not presumptive failures.

### 14.7 v6 targeted corrections and final document-only review boundary

- **V5-01 (`PSCV0-INSTANCE-HDR-01`):** §0B and §4 now specify the same instance header `declId? psBinderSeq ":" term`. The optional declaration name, mandatory result type, ordinary ordered binders, priority modifier, braced instance fields, and the absence of hidden `Unit` semantics are stated explicitly; all major instance grammar sketches point to this shared header. §13 adds positive and negative **design fixtures** for named/anonymous and malformed headers.
- **V5-02 (tactic grammar category):** The PSCV0 tactic sequence is named `psTacticSeq` in the registry, proof bodies, contract proof attachment, and §11 summaries. Lean-native tactic grammar references retain the Lean category where the document is describing Lean itself.
- **V5-03 (deriving grammar category):** All selected trailing deriving suffixes use `psDerivingClause` and delegate to `PSCV0-DERIVE-01`; §11 no longer introduces a competing name or independent production.
- **Prior review precaution:** The §14.1 tactic validation request now uses the canonical newline-separated `·` subgoal form, while `;`/`<;>` remain separately selected tactic-combinator candidates; the edit does **not** claim that any spelling was compiler-tested.

**Scope:** Only document/source comparisons and static text/grammar audits. No Lean compiler, PSCV0 parser, elaborator, kernel, CI, or conformance execution. The frozen Standard environment manifest and cross-module generated-`Std.WP`-spec visibility remain existing, separately tracked obligations, not presumed defects.

### 14.8 v7 document-only errata and iterative verification scope

The v6 re-audit identified three local documentation defects, now corrected in the normative text rather than merely noted here:

| Finding | Normative correction | Design fixtures / evidence boundary |
|---|---|---|
| V6-D01 — undefined verified `do` arm | §0B, §7 and §11.7 use the same `psBaseDoItem \| psVerifiedDoItemP0 \| psStagedDoItemP1` selection; P1 remains environment-gated and P0 verification requires its specified effects | `P-DO-BASE`, `P-DO-ERASED-VERIFIED`, `N-DO-P1-STANDARD`, `P-DO-P1-SELECTED`; not executed |
| V6-D02 — declaration aliases and noncomputability | §0B defines `psDefDecl`, `psFunctionDecl`, `psConstDecl` and `psDefOrFunction`, preserving head-specific binders; §5 distinguishes source parsing from executable dependency closure | `P-DECL-HEAD-MUTUAL`, `N-DECL-HEAD-MUTUAL-NULLARY`, `P-NONCOMP-SPEC`, `N-NONCOMP-EXEC`; not executed |
| V6-E01 — mixed fixtures under a negative heading | §13A now explicitly groups contextual positive **and** negative scenarios | Existing positive and negative case IDs retain their intended statuses |

**Second-pass additional issue V7-D01 (confirmed and corrected).** Older §1, §2 visibility, and §11.1 comparison sketches still used `psDeclaration`, `psParenthesizedCall`, or `psBracedTerm` without a defined acceptance category; the source-modifier sketch also omitted the otherwise admitted conditional `noncomputable` modifier. §0B now defines `selectedPsDeclaration` and the gated `psModifiers` selection, §§1/2 reference it, and §11.1 spells the adjacent-call production explicitly instead of suggesting an unowned generic braced-term parser. The correction is to cross-reference existing syntax and modifier gates, **not** to broaden admitted Lean declarations.

**Secondary consistency cleanup:** §11.1 and §11.3 no longer refer to undefined `psFunction` or `psConst` shorthand; those occurrences now use the head-specific aliases defined above. No previous `deriving`, adjacent-application, exactly-one-`Unit`, Lean comment, instance-priority, contract-ordering, or source-assurance choice is reopened.

**Document-only boundary:** This edition updates the normative design and rechecks its prose, grammar references and static examples. The frozen Standard environment manifest, experimental verification-effect specifics, P1 exception-handler registration, and cross-module generated-`Std.WP`-spec visibility remain identified implementation/evidence obligations, not established successful toolchain behavior or presumed new defects. No compiler, parser, elaborator, kernel, CI, or executable language-conformance tests were performed.

### 14.9 v7.1 source-rule, assurance and stable pin reconciliation (2026-10-16)

**Edition status:** v7.1 creates a new canonical candidate for subsequent PSC0 implementation. It preserves v7 untouched, retains historical v7 errata as history, and **normatively replaces** the previous blanket `partial`/`unsafe` bans in §§0A–0B, 5, 7/7B, 8 and 13–14. The minimum admitted grammar is still the restricted ProofScript subset, not all Lean 4 syntax.

**Stable pin audit:** active Lean version **4.35.0**, release commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. The initial October 11 v7 RC4 and earlier RC3 pins remain recorded only as document provenance. All active parser, elaborator, fixed-point, effects, kernel and source semantics are anchored to the stable commit. Versioned environment/manifest closure must be regenerated on that pin rather than borrowing an RC4 digest.

**Contradiction resolution:**
- Source `partial` is no longer universally a parse-time rejection; it is admitted for selected function-like heads in qualified ordinary code and requires separate runtime-correspondence proof before verified emission.
- `partial_fixpoint` is a checked **post-body** recursion clause, with constructibility/monotonicity and generated equations separate from application-level correctness. It is not synonymous with `partial`.
- `unsafe` is restricted to explicit typed runtime/boundary functions and is neither a proof tactic nor trusted implementation evidence. Closed verified use requires true implementation refinement; named assumptions support only properly labeled boundary-qualified assurance.
- Universal termination is required only for contracts claiming total correctness; partial/ongoing programs require sound safety/finite-trace obligations and all explicitly promised liveness/progress properties.
- User `axiom` and `sorry`/`sorryAx` bans, proof-hole closure, `noncomputable` executable-dependency gate, and independent kernel checking are unchanged.
- No verified artifact can be emitted while required contracts, runtime/backend proof, effects, assumption, erasure, termination-if-promised, or trace-safety obligations remain open. Ordinary emission can never be a hidden fallback.

**Evidence boundary:** This is a normative-document update with source-based design justification. It is **not** evidence of Lean kernel, PSC0 parser, custom frontend, target compiler or CI execution. Every added positive/negative fixture must run under stable Lean 4.35.0 and an exact frozen profile before conformance can be claimed.

**Selected upstream references:** [stable recursive definitions / partial-fixpoint theory](https://lean-lang.org/doc/reference/4.35.0/Definitions/Recursive-Definitions/), [stable source modules](https://lean-lang.org/doc/reference/4.35.0/Source-Files-and-Modules/), [stable release notes](https://lean-lang.org/doc/reference/4.35.0/releases/v4.35.0/), [pinned predefinition elaboration](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/PreDefinition/Main.lean), [pinned fixed-point elaboration](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/PreDefinition/PartialFixpoint/Main.lean).

## 15. Exact stable Lean 4.35.0 source concordance and research provenance

**Immutable active pin:** [leanprover/lean4 stable v4.35.0](https://github.com/leanprover/lean4/releases/tag/v4.35.0) → commit [`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`](https://github.com/leanprover/lean4/commit/eb6cafb7290e8bd5f2937522d8d804f58f02bafc), released October 12, 2026. The former RC4 [`c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`](https://github.com/leanprover/lean4/commit/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364) and RC3 references are historical research evidence, not current normative pins.

| Lean source family | Pinned source / reference | Relevance and restrictions |
|---|---|---|
| Term parsing, `match`, `field`, records, application | [`src/Lean/Parser/Term.lean`](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Parser/Term.lean) | Lean terms and whitespace application; PSCV0 adjacent comma calls are additional sugar |
| Declaration heads, `def`, structure, class, instance | [`src/Lean/Parser/Command.lean`](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Parser/Command.lean) | native headers; `const` and `function` are PSCV0 aliases |
| Basic parser/identifiers/trivia | [`src/Lean/Parser/Basic.lean`](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Parser/Basic.lean) | select Lean lexing rather than reconstruct lexical regexes |
| Binder terms and syntax | [`src/Lean/Parser/Term/Basic.lean`](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Parser/Term/Basic.lean) | selected explicit, implicit, strict implicit, instance binder forms |
| `do`, mutable/erased state, loops | [`src/Lean/Parser/Do.lean`](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Parser/Do.lean) | PS selected `do` grammar and experimental verification parallels |
| `#check` and `#eval` command parsing | [`src/Lean/Parser/Command.lean`](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Parser/Command.lean) | same command spelling; PSCV0 restricts evaluation effects |
| `#reduce` syntax | [`src/Init/Notation.lean`](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Notation.lean) | reducibility diagnostic, not proof authority |
| Lean stable 4.35.0 modules and exposure | [`Source Files and Modules`](https://lean-lang.org/doc/reference/4.35.0/Source-Files-and-Modules/) | `module`, imports, visibility, public section and exposures; source `.ps` retains its selected module translation |
| Intrinsic `where finally` grammar | [`src/Lean/Parser/Term.lean`](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Parser/Term.lean) | `whereDecls` / `whereFinally` / `whereFinallySubsection` used by stable Lean 4.35.0 generated contract spec proof |
| Lean intrinsic contract elaboration | [`src/Lean/Elab/Tactic/Do/Contract.lean`](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/Tactic/Do/Contract.lean) | experimental ordered `given`/`requires`/`ensures`, `Std.WP` prerequisite, generated `f.spec` and `where finally \| spec` proof attachment |
| Lean verification-condition generation | [`src/Lean/Elab/Tactic/Do/VCGen.lean`](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/Tactic/Do/VCGen.lean) | source reference for checkable VCs, not a trusted oracle |
| Partial recursion typing/admission | [`src/Lean/Elab/PreDefinition/Main.lean`](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/PreDefinition/Main.lean) | stable partial/unsafe recursion dispatch and term elaboration; PSCV0 adds independent assurance gates |
| Partial fixpoint construction | [`src/Lean/Elab/PreDefinition/PartialFixpoint/Main.lean`](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/PreDefinition/PartialFixpoint/Main.lean) | monotonicity, fixed-point elaboration, equations, and checking |
| Recursive and partial-fixpoint syntax | [`src/Lean/Parser/Term.lean`](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Parser/Term.lean) and [`src/Lean/Parser/Command.lean`](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Parser/Command.lean) | native `partial` modifier and `partial_fixpoint` post-body clause, not a second kernel |
| Chain-complete orders and monotonicity | [`Init/Internal/Order`](https://github.com/leanprover/lean4/tree/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Internal/Order) | checked monotonicity/fixpoint lemmas; exact imported environment provenance required |
| Recursive functions explanatory reference | [Lean 4.35.0 recursive definitions](https://lean-lang.org/doc/reference/4.35.0/Definitions/Recursive-Definitions/) | distinguishes total recursion, opaque partial functions, and fixed-point equations |
| Lean primitive kernel foundations | [`src/kernel`](https://github.com/leanprover/lean4/tree/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/kernel) | selected core theory, definitional equality, inductives, judgment checks |

**Official explanatory research (moving pages; pinned code above is normative for this proposal):**

- [Lean 4.35.0 release notes](https://lean-lang.org/doc/reference/4.35.0/releases/v4.35.0/): especially erased state, `given`, VC/loop updates and upstream experimental warnings.
- [Function Application](https://lean-lang.org/doc/reference/4.35.0/Terms/Function-Application/): juxtaposition/curried core, named/implicit/optional arguments.
- [Lean pattern matching](https://lean-lang.org/doc/reference/4.35.0/Terms/Pattern-Matching/): `match_pattern` reduction and `Nat` syntax `k + 1` versus the invalid reversed form `1 + k`.
- [Lean 4.35.0 Namespaces and Sections](https://lean-lang.org/doc/reference/4.35.0/Namespaces-and-Sections/): generalization of explicit/implicit/instance section variables, theorem-header dependency rules, fixed section variables in recursive functions.
- [Lean tactic proofs](https://lean-lang.org/doc/reference/4.35.0/Tactic-Proofs/): goal states, bullets, `case`, `next`, and tactic proof terms.
- [Lean Infoview](https://github.com/leanprover/vscode-lean4/tree/master/lean4-infoview): practical proof-state inspection and language-server integration.
- [Headers and Signatures](https://lean-lang.org/doc/reference/4.35.0/Definitions/Headers-and-Signatures/): `declSig`, binder scopes, optional and automatic parameters.
- [Interacting with Lean](https://lean-lang.org/doc/reference/4.35.0/Interacting-with-Lean/): distinction among `#check`, `#print`, `#reduce`, `#eval` and limits of execution as proof.
- [Basic Types](https://lean-lang.org/doc/reference/4.35.0/Basic-Types/) and [Fixed-Precision Integers](https://lean-lang.org/doc/reference/4.35.0/Basic-Types/Fixed-Precision-Integers/): data families, 8/16/32/64/word signed/unsigned types, wrapping behavior.
- [Terms](https://lean-lang.org/doc/reference/4.35.0/Terms/), [Definitions](https://lean-lang.org/doc/reference/4.35.0/Definitions/), [Monads and do-notation](https://lean-lang.org/doc/reference/4.35.0/Functors___-Monads-and--do--Notation/): selected source syntax and elaboration context.

**Historical document attribution:** The initial ProofScript PSCV normative RC-v2 and v7 used Lean 4.35 release candidates for historical research. **v7.1** supersedes the active toolchain pin with stable Lean 4.35.0 and selectively admits partial recursion, proof-friendly fixpoints and tightly governed unsafe boundaries without expanding proof authority. Its source/assurance decisions are **new** requirements, not claims about v7 or confirmed PSC0 implementation. Prior errata remain available for provenance.

**Research limitation:** Directly pinned source URLs anchor future verification; they do not automatically constitute successful parser/elaborator/kernel conformance runs. A released conforming `pscv0` would need a frozen environment manifest and executable positive/negative tests and proof replay as specified in §14.

