# PSC3 language reference

**Proposed requirements · review draft 0.3 · 3 October 2026. Syntax and grammar follow ProofScript v0.7.0.**

This is not a frozen specification or an implementation report. MUST, MUST NOT, SHOULD and MAY constrain the proposed profile. No capability is implemented or proved by inclusion here. Existing PSC1/PSC2 editions retain their own specifications.

The controlling source reference is [ProofScript v0.7.0](../study/proofscript-language-reference-v0.7.0/ProofScript_Language_Reference_v0.7.0_authoritative_draft.md), including its registry and category rules. [SYNTAX_AND_GRAMMAR_V07.md](SYNTAX_AND_GRAMMAR_V07.md) records the authority, source identity, examples and non-admitted forms. This document cannot replace that grammar with stock-Lean-only `.ps` or a new TypeScript-like dialect.

## 1. Scope

PSC3 combines general-purpose programming, theorem proving and formal verification over a declared Lean-based foundation. Ordinary programming is not conditional on proving every application contract. Requested assurance is a separate, inspectable property of a build and its exports.

The `.ps` reference is v0.7.0, whose canonical semantics use Lean 4.34.0 at `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`. `.lean` remains a supported native subset of that declared environment. Earlier 4.34.1 research is a separate upgrade candidate; it does not silently change the selected source reference. The [Lean profile](LEAN_PROFILE.md) defines compatibility dimensions. The [semantics companion](SEMANTICS_AND_EFFECTS.md) describes library proposals without redefining native constructs.

## 2. Source files, editions and environments

### 2.1 Ordinary source

An ordinary `.lean` file MUST be accepted by the pinned official frontend under its declared environment and satisfy PSC's supported-subset restrictions. It does not accept ProofScript-only decorations.

An ordinary `.ps` file MUST follow v0.7 L/D/E syntax and lower canonically to compatible Lean syntax or Core. Its contents need not be valid unmodified Lean. Renaming its extension is not canonical lowering. The reference equation is `meaningPS(p) := meaningLean434(canonicalLower(p))`.

Each logical module resolves to one source snapshot. Reject ambiguous `.ps` and `.lean` candidates unless the manifest selects one. Never use a stale sibling to make a build succeed. Source/import maps, options, exact dependencies and lowering identity are part of evidence identity. Canonical helper declarations and rewritten punctuation must retain the required source-map and hygiene correspondence.

The project records source-reference version separately from PSC platform edition. Existing PSC1/PSC2 meanings are not silently replaced. Moving to PSC3 does not require deleting valid v0.7 aliases or decorations.

### 2.2 Registered categories and extensions

The parser chooses an exact registered E production, then a D production whose discriminator holds, then the supported inherited Lean category. DEFER is not unconditional acceptance. Term decoration does not automatically extend pattern, tactic, command or do-element grammar.

Future syntax requires an explicit ID/class, grammar, discriminator, canonical lowering, compatibility cost, source mapping and conformance evidence. A document's experimental example cannot register it implicitly.

Reference §27 identifies `.psx` as explicitly target-specific/non-Lean-compatible source. Proposed UI markup is a separate experimental dialect within that boundary, selected by project metadata rather than the suffix alone. It must not inherit ordinary `.ps` verification/portability claims automatically. Plain UI libraries remain available from `.ps` and `.lean`. See [PSX](PSX_UI_PROPOSAL.md).

### 2.3 Compatibility dimensions

Report source syntax, elaboration environment, logical rules/axioms, executable closure, target profile and assurance separately. Checking exported Lean proof terms does not imply original tactic-script support. Runtime backend coverage does not imply theorem-library coverage. A proof-only feature need not have an executable realization.

## 3. Lexing, punctuation, formatting and declarations

Lean lexical rules are inherited except where a registered v0.7 D/E production owns its exact context. Formatting MUST preserve category ownership, parsed meaning and module identity.

`:=` denotes binding/definition/update in the applicable category; `=` is propositional equality; `==` is Boolean equality through the selected Lean machinery. Braces and semicolons are category-specific, not universal JS blocks or globally removable punctuation. No JS-style automatic-semicolon policy is introduced.

`def` is the canonical general definition. `const` is the parameterless declaration-head alias; `function` is the alias requiring an explicit declaration parameter group. Both lower to `def` and do not add hoisting, `this`, prototypes or object freezing. Reference §§8–9 govern their exact restrictions.

```proofscript
const answer : Nat := 42;
const increment : Nat -> Nat := fun x => x + 1;
function add(x : Nat, y : Nat) : Nat := x + y;
```

Expression-bodied decorated declarations use `:=` and their owned terminating semicolon. Bare brace-bodied `function` declarations are explicitly not admitted in v0.7 (§8.6). `theorem`, `example`, `abbrev` and `opaque` retain their separate inherited meanings; aliases do not automatically apply to them.

The project template MAY explicitly include `set_option autoImplicit false`. It must be part of the declared source/environment, not an invisible difference between PSC and its oracle. Accepted declarations must be closed and well-scoped; unfinished evidence cannot authorize release.

## 4. Functions and elaboration

D-CALL lowers `f(x, y)` to `(f x) y`. `f((x, y))` passes one tuple; spaced `f (x, y)` is protected native tuple application. `f()` lowers to `f ()`, not a new zero-argument kernel call. Whitespace/comments between the head and parenthesis break the D-CALL discriminator. Do not equate distinct multi-argument and tuple forms while formatting.

Explicit `(x : A)`, implicit `{α : Type}`, strict-implicit `{{α : Type}}` and instance `[C α]` binders retain their roles. Comma-grouping is available only in registered headers. Native type application and dependent binders are not replaced by TS `<T>` syntax. Lambdas use `fun x => ...`, not bare `x => ...`.

Local inference is encouraged; public signatures SHOULD expose important data, effects and dependencies. Contextual typing and inserted arguments remain inspectable.

### 4.1 Names, methods and typeclasses

For accepted source, name resolution, generalized field notation, coercions and instance synthesis retain the meaning of the canonical Lean environment. If a resolution case is unsupported, reject it; do not choose a different candidate and call it compatible.

Priorities, imports and declaration order belong to the environment. Search budgets do not authorize a different meaning. Explain selected methods, arguments, instances and relevant declarations. The v0.7 reference §§21–23 governs these inherited mechanisms; a live/manual or later patch does not override the selected pin.

### 4.2 Named and default arguments

Use supported inherited Lean forms. For example, a native named call may be `connect host (timeout := 5000)`; `connect(host, timeout: 5000)` is not an admitted replacement grammar. Defaults use the inherited declaration rules. Named-argument support inside a decorated call requires actual category coverage, not an assumption that all text between parentheses is valid.

Parameter identity is part of an API used by name. Dependent elaboration order and runtime evaluation order are distinct. Options records are ordinary structures, not a second parameter system. Foreign overloads/variadics belong in [InterfaceIR](JS_INTEROP_AND_INTERFACE_IR.md).

### 4.3 Higher-order functions

Functions remain first-class in the logical fragment. Record the supported executable representation and polymorphism. A backend must preserve returned-function invocation, closure capture and partial application rather than invent a target calling convention.

## 5. Data, patterns, schemas and equality

Structures and inductives retain nominal identity and native formation/elimination rules. Registered braced data declarations retain `where`; fields/constructors use their category separators.

```proofscript
structure User where {
  name : String;
  active : Bool;
}

function activate(user : User) : User :=
  { user with active := true };

function getOrElse(value : Option Nat, fallback : Nat) : Nat :=
  match value with {
    | .none => fallback;
    | .some x => x;
  };
```

Structure values/updates are inherited Lean syntax. Dependent fields are not optional metadata: an update that changes their type must reconstruct them or supply appropriate evidence, never insert an unchecked cast.

The E-MATCH-BODY form retains `with`. Patterns stay native Lean: `.some x`, not `.some(x)`. Constructor-header decoration does not extend patterns. Exhaustiveness and motive synthesis must preserve native meaning for the claimed capability.

`Option α` is the recommended application absence type and `Except ε α` the standard native error type. The reference's illustrative user-defined `Result α ε` has success first, error second; do not confuse its order with `Except`. Foreign missing/undefined/null distinctions may require richer ordinary data, with explicit conversion policies.

Schema/codec libraries generate ordinary declarations. They do not create general structural subtyping or prove foreign behavior from declaration shapes. Propositional equality, definitional conversion and Boolean equality are distinct; `BEq` alone does not establish lawfulness.

## 6. Logical foundation and proof syntax

The selected logical profile retains sorts/universes, dependent functions, substitution, conversion, propositions, proof irrelevance, inductives/recursors and relevant quotient rules. Partial implementation coverage must fail closed rather than approximate the theory.

Proof/tactic syntax belongs to its inherited category. For example, the reference admits `theorem ... := by { ... }`; declaration-semicolon rewriting must not alter tactic sequencing. Structured proofs and automation construct evidence, never authority.

Axiom policy is independent of package and semantic-profile versions. Report exact transitive assumptions; names alone cannot confer foundational authority. `sorry`/`sorryAx`, incomplete proofs and arbitrary native-result assumptions do not qualify for strict release. Research or larger-trust profiles must be explicit.

Universe-polymorphic, indexed, classical and noncomputable mathematics remains legitimate. Noncomputable definitions are not silently forced into executable artifacts. Tactic and notation environments are versioned, and successful official Lean checking alone does not establish owned-frontend or backend compatibility.

## 7. Computation, partiality and effects

Total definitions use supported structural/well-founded mechanisms. Failed termination search is not proof of divergence. `partial def` retains its native logical/runtime boundary; runtime equations cannot be fabricated by the verifier. Other upstream recursion mechanisms require independently recorded capability evidence.

Application execution may include partiality and effects. Report whether type safety, partial correctness, total correctness, trace safety or another precise claim is established. A filename alone does not replace that evidence model.

`do`, state/error monads, loops, mutable locals and `return` keep inherited Lean meanings. Bracketed `do` is subject to reference §18's pinned-grammar gate; this draft does not register a new block rule. E-IF-BRACE is `if (c) { t } else { e }` with one term per branch; sequencing is not imported from JS statements.

Preserve transformer order and effect sequencing. Discarding logical state on failure does not undo a network/database effect. Resource and `Psc.Async` APIs are separately named library proposals; there are no newly admitted `async function` or `using` keywords, and native Lean Task/IO are not redefined as Promise/futures.

## 8. Scalars and runtime primitives

Nat/Int retain exact reference values. Fixed-width integers, target words, floats, characters, strings and bytes require operation-level bindings to the selected reference. The inherited scalar/conversion matrix remains an implementation/release obligation, not closed by this repair.

Reject missing primitive semantics for a requested executable profile. Do not fall back to JS number, Rust debug/release overflow, host string length or unchecked conversions. Target-word width and resource behavior remain explicit. Floating contracts concern specified floating behavior or a proved relation, not automatic real arithmetic.

## 9. Specifications and contracts

Ordinary propositions and theorems about actual definitions are the baseline. Final evidence must bind the implementation, requested specification and fixed semantic dependencies; unrelated discharged VCs are insufficient.

Upstream intrinsic verification syntax remains a separately gated inherited capability under the selected pin, imports and options. Earlier 4.34.1 parser/test research does not automatically certify the v0.7/4.34.0 frontend. Recheck exact placement, clause count and generated-theorem behavior before advertising it. Do not invent repeated clauses, new final proof-section syntax or automatic proof parameters. Plain definition-plus-theorem examples remain usable without that extension.

Verified callers discharge their required preconditions; ordinary type checking does not imply those proofs. Explicit proof/subtype APIs and external runtime-validating wrappers are separate mechanisms. `.d.ts` is not a runtime guard.

State/error/async contracts state relevant outcomes and assumptions. Successful-result clauses do not establish eventual success. Total correctness needs termination/liveness evidence under stated conditions. Erasure must retain runtime-relevant witnesses and data.

## 10. Modules, commands and platform interfaces

Use inherited commands such as `import Foo.Bar`, `namespace Name ... end Name`, `section ... end`, supported visibility, attributes and options. Braced namespaces/sections and ESM-style `.ps` imports/exports are not admitted v0.7 replacements. `E-WHERE-BODY` is a local-declaration context, not a general command block.

Logical imports map to exact dependencies. JS ESM/package export resolution is a target/tooling responsibility, not a new source grammar. Track source, elaboration and runtime dependency closures separately. Prefer explicit application entry points until native initialization modes are fully covered.

Platform network/storage/time/UI/process APIs are ordinary declared libraries and adapters. Build-time plugins need explicit permissions and appropriate isolation. External behavior remains assumed unless its implementation/model relationship is established.

## 11. UI and full-app authorship

The application profile should permit browser, service and CLI apps without hand-written TS/JS glue for supported APIs. Runtime/framework adapters may be foreign implementations with explicit identities and assumptions.

UI is available through ordinary v0.7 library values/functions and their native Lean equivalents. `.psx` markup is an explicitly profiled, non-base proposal. Its expansion still needs source correspondence and checking; it grants no proof of renderer, browser or remote services.

Client/server source sharing requires capability and serialization checks. Code splitting, workers, SSR and hydration are individually profiled; a shared type name is not a security boundary.

## 12. Compilation and evidence

The common path is v0.7 `.ps` lowering or native `.lean` interpretation, elaboration, kernel admission, erasure, Runtime IR and target lowering. Existing TS/Rust and proposed direct JS/Wasm consume one semantic representation. Target layout cannot redefine source syntax or meaning.

Preservation is behavioral equivalence/refinement under explicit representation, effect and resource relations. Evidence about an internal AST does not cover an incorrect printer; bind it to actual files and runtime dependencies. A compiler building the checker has a build-trust role distinct from a compiler proposing proofs. Self-hosting and differential agreement are not soundness theorems.

## 13. Diagnostics, incomplete work and policy

Editors may retain incomplete source/goals. Release states distinguish accepted, rejected, unsupported, search incomplete, resource limit, cancelled and internal error. Timeout is not proof of falsehood.

Diagnostics identify original `.ps` spans, lowered/expanded spans, module, expected/actual types, obligation and target capability. Provide the same data to human tools and AI agents. Agents may not silently alter approved specifications, dependencies, assumptions or release authority to turn failure into success.

## 14. Conformance and freeze

The source gate starts with the v0.7 registry and positive/negative/lowering corpus. Test D-CALL neighbors, alias restrictions, brace/separator categories, native patterns, lambda forms, namespace scope and formatting/source maps. Accepting similar-looking examples is not S2 proof or production refinement.

A stable PSC3 edition additionally needs precise library/effect/primitive closure, actual application workflows, migration rules and evidence reporting. Unsupported features remain rejected or explicitly profiled. See [ROADMAP_AND_CONFORMANCE.md](ROADMAP_AND_CONFORMANCE.md).
