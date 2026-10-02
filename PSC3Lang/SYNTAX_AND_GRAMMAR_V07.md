# PSC3 syntax and grammar authority: ProofScript v0.7

**Documentation correction · 3 October 2026.** This contract applies to every document in `PSC3Lang/`. It does not implement a parser, upgrade a toolchain, or raise a proof claim.

## 1. Authority and scope

The authoritative source for `.ps` syntax, grammar ownership and canonical lowering is [The ProofScript Language Reference v0.7.0](../study/proofscript-language-reference-v0.7.0/ProofScript_Language_Reference_v0.7.0_authoritative_draft.md), supported by [Appendix A: complete feature registry](../study/proofscript-language-reference-v0.7.0/appendices/A-complete-feature-registry.md), its [machine-readable registry](../study/proofscript-language-reference-v0.7.0/conformance/feature-registry.json), and the [conformance corpus](../study/proofscript-language-reference-v0.7.0/conformance/README.md).

Reference snapshot: repository commit `65369c75c7b63124f1ba7f2289e573181db281f0`; main-reference Git blob `8b4097363c5ade7d594b66706b94dff62400ff53`; registry-appendix Git blob `5c577000709646b37017b692c21ae66f1c6ebf84`. The reference identifies itself as an S1-specified authoritative candidate. Selecting it for these design documents does not close its production migration or S2/S3 obligations.

The reference's canonical semantic baseline is Lean **4.34.0**, commit `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`. Earlier PSC3 draft research into 4.34.1 remains a separately gated upgrade candidate, not an implicit change to v0.7 grammar or semantics. Existing repository toolchain files are untouched.

PSC3 remains the proposed language/platform iteration. `PSC3-0`, the v0.7 source-reference version, compiler revisions, Lean pins and runtime profiles are different identifiers. `LANGUAGE_REFERENCE.md` and all domain documents must follow this source authority rather than invent a replacement surface. Libraries and tooling may grow without adding new syntax. Future syntax requires an explicit proposal and reference/registry revision; a candidate example cannot silently enlarge the v0.7 accepted surface.

## 2. Source kinds and canonical relation

```text
.ps   -> v0.7 category-aware parser/lowerer -> canonical Lean/core
.lean -> supported pinned native Lean frontend -> compatible Lean/core
.psx  -> explicit target-specific/extension profile -> declared expansion path
```

For the Lean-compatible `.ps` profile, the reference states:

```text
meaningPS(p) := meaningLean434(canonicalLower(p))
```

`.ps` is not a filename alias for `.lean`. Some inherited L-class source is text-identical; D/E forms need structural lowering. Official Lean checks native `.lean` directly and checks the canonical lowering of `.ps`, not arbitrary original decorated bytes. A standalone frontend owes the same claimed semantics without requiring a Lean process at runtime.

The requested `.lean` subset constraint remains intact: no ProofScript-only call/header/body syntax is inserted into native `.lean`. Source maps connect diagnostics and evidence back to the original `.ps` spans. Module, import, option and dependency identities are preserved or explicitly represented in the lowering evidence.

## 3. Surface classification and parser ownership

| Class | Meaning | Rule |
|---|---|---|
| L | Inherited Lean | Preserve the selected Lean grammar and meaning for the claimed capability. |
| D | Conservative decoration | Apply only when its discriminator holds; preserve protected native neighbors. |
| E | Surface exception | Own only the registered context and lower deterministically to Lean. |
| X | Semantic divergence | Reject from the Lean-verified core. |

Ownership is registered E production, then matching D production, then deferred pinned Lean category. In a standalone parser, DEFER is not permission to accept unknown source. Term extensions do not automatically extend pattern, tactic, do-element or command grammars. No global punctuation rewrite is permitted. See reference §§4–7 and Appendix A.

## 4. Declaration and punctuation rules

`def` is the canonical general declaration. `const` is a parameterless declaration-head alias for `def`; its value may itself be a function. `function` is an alias requiring at least one explicit declaration parameter group. They do not introduce JS hoisting, `this`, freezing, or statement-body semantics.

```proofscript
const answer : Nat := 42;
const increment : Nat -> Nat := fun x => x + 1;
function add(x : Nat, y : Nat) : Nat := x + y;
def identity {α : Type}(x : α) : α := x;
```

Canonical Lean for `add` is:

```lean
def add (x : Nat) (y : Nat) : Nat := x + y
```

`:=` remains definition/binding/update syntax; `=` is propositional equality; `==` is Boolean equality with the relevant Lean machinery. Semicolons terminate registered expression-bodied declarations or separate members/alternatives only in their owned categories. They are not globally erased, and there is no JS-style automatic-semicolon-insertion policy.

**Not admitted in v0.7:** `function f(x : Nat) : Nat { x }`, `const x = 1`, `const f(x : Nat) : Nat := x;`, or `function answer : Nat := 42;`. Bare brace-bodied functions remain a future candidate, not a PSC3 default. See reference §§6, 8–9.

## 5. Calls, binders and protected neighbors

```text
f(x, y)    -> (f x) y       [D-CALL: two curried arguments]
f((x, y))  -> f (x, y)     [D-CALL: one tuple argument]
f (x, y)   -> f (x, y)     [deferred native application]
f()        -> f ()        [one Unit argument, not zero core arguments]
```

Whitespace or comments between the callable head and `(` break D-CALL adjacency. `f(x)` and `f (x)` can denote the same unary application while belonging to different parser paths; this does not justify collapsing `f(x, y)` and `f (x, y)`. The formatter must preserve ownership and argument structure.

Explicit `(x : A)`, implicit `{α : Type}`, strict-implicit `{{α : Type}}` and instance `[C α]` binders retain their meanings. Comma-grouped complete binders apply only in registered headers. TypeScript `<T>` generics are not their replacement.

Named/default arguments use supported inherited Lean forms, not a new `name: value` call grammar. For example, use native `connect host (timeout := 5000)` when that native feature is supported. Do not assume all such forms work inside D-CALL without a corresponding category/conformance rule. See reference §§9–11, 21.

## 6. Data, patterns, conditionals and lambdas

```proofscript
structure User where {
  name : String;
  active : Bool;
}

inductive Result(α : Type, ε : Type) where {
  | ok(value : α);
  | error(error : ε);
}

function activate(user : User) : User :=
  { user with active := true };

function getOrElse(value : Option Nat, fallback : Nat) : Nat :=
  match value with {
    | .none => fallback;
    | .some x => x;
  };
```

The illustrated user-defined `Result` has success type first and error type second. Native `Except ε α` keeps its different parameter order. Neither is silently renamed into the other.

Braced structure/class/inductive declarations retain `where`; match retains `with`. Constructor declaration parameters may use their registered decoration, but **patterns remain native Lean**: `.some x`, not `.some(x)`. Lambdas use `fun x => ...`, not `x => ...` or `(x) => ...`.

The registered conditional is `if (c) { t } else { e }`, with one term in each branch. Native `if c then t else e` also remains available. Neither admits arbitrary JS statement blocks or truthiness. See reference §§12–17.

## 7. Commands, effects and proof syntax

```proofscript
namespace Math

function square(x : Nat) : Nat := x * x;

theorem squareZero : square(0) = 0 := by {
  rfl
}

end Math
```

Imports, namespaces, sections, attributes and options use their inherited command grammar. `namespace Math { ... }`, `section { ... }` and ESM-style source imports/exports are not admitted v0.7 replacements. ESM remains a valid target/package concern.

Proof/tactic syntax uses its own inherited category. Do not apply declaration-semicolon rules inside tactics. Effects, `do`, loops, local mutation and `return` keep their Lean meanings. Bracketed `do` needs the pinned-grammar evidence explicitly required by reference §18; this repair does not grant it blanket new acceptance. `E-WHERE-BODY` is registered for local declarations, not a general command-scope brace rule.

Plain definition-plus-theorem contracts are always the basic specification approach for supported logical features. Intrinsic `requires`/`ensures` or other upstream constructs remain separately gated inherited capabilities with exact pin/import/option requirements; do not invent clause repetition, proof sections, `async function`, `using`, `component`, `enum`, optional-property `?`, or `?.`/`??` syntax as part of the v0.7 base. Application libraries can expose these tasks using admitted functions and data. See reference §§17–23.

## 8. `.psx` and other extensions

Reference §27 describes `.psx` as explicitly target-specific/non-Lean-compatible source. The optional PSC3 UI proposal must fit that explicit extension boundary, not redefine `.psx` as ordinary verified `.ps` by filename. Existing `.psx` files are not automatically UI files.

Markup, an optional `view!` quotation, or another unregistered spelling must be labelled **extension pseudocode, not v0.7 syntax**, with an explicit dialect/version and registered expansion contract before implementation acceptance. A pure expansion may ultimately produce checked declarations, but the suffix or expansion alone does not prove the source correspondence, renderer, foreign code or whole application. Plain UI libraries remain usable through both v0.7 `.ps` and supported `.lean`.

## 9. Documentation and validation obligations

Every document in this directory must follow this reference or clearly separate a non-admitted extension proposal. `.ps` examples use `proofscript` fences; canonical/native Lean examples use `lean`; target-language examples use their own language; unresolved extension syntax uses `text` and an adjacent status warning.

Minimum regression cases are the reference's positive, negative and lowering corpus plus protected-call neighbors; valid/invalid aliases; braced declarations; match patterns versus constructor terms; namespaces; tactic/do category boundaries; original source-map locations; and paired `.ps`/canonical `.lean` examples. The chosen project capability profile may be smaller than the S1 surface; it must reject unsupported features explicitly.

This repair establishes documentation alignment only. No Lean/PSC parser execution, kernel proof replay, S2 reference proof, production refinement or backend equivalence is claimed.
