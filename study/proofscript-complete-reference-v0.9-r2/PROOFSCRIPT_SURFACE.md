# ProofScript source presentation contract

**Unchanged grammar:** `ps-0.9-r2`, Lean-native separators. This companion restates the selected surface, not a new edition or implementation. The complete v0.9-r2 reference attachment is identified by SHA-256 `d29c0b2d5780e6cdb08a4c9ac00cc7442a64b1c8133b51c5f0c0e9a343b11b8d`.

## Authority

`.ps` is parsed by a category-aware overlay and lowered to compatible native syntax/Core. `.lean` stays native. Unknown inherited grammar in a standalone frontend is unsupported, not automatically accepted. Registered exceptions own only their exact contexts; decorators require their discriminators; otherwise the selected native category decides. Successful output must preserve the declared environment, binding identities and canonical relation.

## Definitions and delimiters

`def` is the general declaration. `const` has no declaration parameters and lowers to `def`. `function` requires a nonempty explicit parameter group and lowers to `def`. All use native body/suffix boundaries: no additional general semicolon. A value may have function type without using the function alias.


```proofscript
const limit: Nat := 100
const increment: Nat -> Nat := fun n => n + 1

function activate(user: User): User :=
  { user with active := true }
```


A record, match, conditional, proof term or do expression at the end of a body does not acquire an outer terminator. `:=` is definition/binding/update syntax; `=` is propositional equality; `==` is selected Boolean comparison. Bare JavaScript function blocks and automatic semicolon insertion are not admitted.

## Native semicolons and layout

Native `let x := e; body`, do sequencing, tactic sequencing, and supported instance/local-declaration separators retain their meaning. `t1; t2` differs from `t1 <;> t2`. Structure/class field declarations, inductive constructors and match alternatives do not acquire added separators. Braces create explicit category boundaries but retain the appropriate native indentation checks and nested continuation rules. Formatting cannot merge distinct parser paths or blindly delete punctuation.

## Calls and binders

| Source | Meaning |
|---|---|
| `f(x,y)` | One native application argument sequence with two curried arguments. |
| `f((x,y))` | One tuple argument. |
| `f (x,y)` | Protected native tuple application. |
| `f()` | One Unit argument, not zero core arguments. |
| `f(x)(y)` | Preserve separate application groups. |
| `f(x, option := y)` | Native named-argument matching. |
| `f(x,y,)` | Nonempty list with no extra final argument. |

Whitespace or native comments between the callable head and opening parenthesis break D-CALL ownership. Preserve original positions. Complete explicit binders can be comma-grouped in registered headers. Explicit, implicit, strict-implicit and instance binders retain their kinds; no TypeScript generic-angle replacement is introduced. Defaults use `:=` and native elaboration.

## Data and matching


```proofscript
structure User where {
  name: String
  active: Bool
}

inductive Outcome(α: Type) where {
  | pending
  | ready(value: α)
}

function valueOr(value: Option Nat, fallback: Nat): Nat :=
  match value with {
    | .none => fallback
    | .some n => n
  }
```


Braced structures/classes/inductives retain `where`; braced matches retain `with`. Patterns are native (`.some n`), even when a constructor term uses `.some(n)`. Lambdas use `fun`. Dependent fields and motives retain their type constraints. Record values keep native assignment and comma rules, not TypeScript object properties.

## Proofs, commands and effects

Namespaces and sections retain native `... end`. Imports, attributes, options, proof terms and tactics retain their categories and scope. Decorations inside command/tactic/quotation child slots require explicit coverage; term decoration does not recursively rewrite arbitrary syntax. Native do is not JavaScript statements; return, mutation, loops and failure retain native semantics.

Intrinsic contracts, erased bindings, coinductive suffixes and native automation remain gated inherited capabilities. Runtime Task/IO and host replacements need explicit executable support. No base async/await/using/component/JSX/optional-chaining grammar is invented by this collection.

## Registered surface families

The active owned families are `D-CALL`, `D-EXPLICIT-PARAMS`, `D-CONST-ALIAS`, `D-FUNCTION-ALIAS`, `D-NAMED-CALL`, `D-TRAILING-COMMA`, `E-IF-BRACE`, `E-STRUCT-BODY`, `E-CLASS-BODY`, `E-INDUCTIVE-BODY`, `E-MATCH-BODY`, `E-WHERE-BODY`, and `E-INSTANCE-BODY`. Their native dependencies remain explicit. `D-DECL-SEMI` is retired; legacy source requires explicit migration.

The inherited markers include `L-CORE-LEAN`, `L-DO-BRACKETED-434`, `L-INTRINSIC-CONTRACTS-434`, `L-ERASED-DO-434`, `L-RECALL-434`, `L-MONOTONICITY-BY-434`, and `L-LIA-GROBNER-PARAMS-434`. Reference inclusion is not an implementation-support claim.

## Rejection and evidence

Reject missing or conflicting syntax, unknown capabilities, incompatible environments, incomplete proofs, failed admission and exhausted resources. Do not reparse a committed malformed decoration as a permissive fallback. Preserve original source maps. A source theorem, a compilation-preservation theorem and a tested executable are different evidence. None is inferred from a documentation example.
