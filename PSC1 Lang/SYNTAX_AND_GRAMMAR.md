# PSC1 Syntax and Grammar

Status: **normative companion to PSC1_LANGUAGE_REFERENCE.md**

This document consolidates the bounded source syntax relevant to PSC1. It does
not claim a complete grammar for Lean 4.34. Where PSC1 accepts a Lean-compatible
form, acceptance is limited to the frozen/source-gated subset.

## 1. Grammar philosophy

PSC1 does not use a global textual preprocessor.

Parsing is category-aware:

1. recognize an exact PSC1-owned E-class form in its registered context;
2. recognize a D-class decoration when its discriminator holds;
3. recognize a documented bounded Lean-compatible form;
4. otherwise fail closed.

The broader v0.7 reference describes step 3 as defer to the pinned Lean parser
in its reference-Lean profile. The standalone/self-hosted PSC1 parser cannot
treat unknown input as valid merely because a Lean parser might accept it.

## 2. Lexical foundation

Identifiers, literals, comments, and punctuation follow the repository's
bounded Lean-compatible lexical model.

The lexer preserves trivia/span information required to distinguish forms such
as:

```text
f(x)             adjacent
f (x)            whitespace-separated
f/- comment -/(x) comment-separated
```

Only the first form is D-CALL.

Source positions and spans are part of the compiler foundation because
diagnostics, source maps, navigation, and semantic identity depend on them.

## 3. Declaration grammar

The following pseudo-grammar describes the required declaration family.

```text
DefinitionDecl
  ::= "def" Identifier Binder* [":" Type] ":=" Term ";"

ConstDecl
  ::= "const" Identifier [":" Type] ":=" Term ";"

FunctionDecl
  ::= "function" Identifier Binder* ExplicitParamGroup Binder*
      [":" Type] ":=" Term ";"

ExplicitParamGroup
  ::= "(" ExplicitParam ("," ExplicitParam)* ")"

ExplicitParam
  ::= Identifier ":" Type

Binder
  ::= "(" Identifier ":" Type ")"
   |  "{" Identifier ":" Type "}"
   |  "{{" Identifier ":" Type "}}"
   |  "[" InstanceBinderBody "]"
```

The pseudo-grammar emphasizes semantic constraints rather than parser
implementation shape:

- `const` has **no declaration parameters**.
- `function` has **at least one explicit declaration parameter group**.
- `def` is the canonical general form.
- All three elaborate to the same definition semantics.
- Canonical Lean lowering uses `def`.

Examples:

```proofscript
def x: Nat := 1;

const y: Nat := 2;

function add(x: Nat, y: Nat): Nat :=
  x + y;
```

Rejected:

```proofscript
const add(x: Nat): Nat := x;

function answer: Nat := 42;
```

### 3.1 Local `where` declarations

Owned braced form:

```text
WhereBlock ::= "where" "{" LocalDeclaration* "}"
```

Example:

```proofscript
def f(x: Nat): Nat :=
  helper(x)
where {
  helper(y: Nat): Nat := y + 1;
}
```

Canonical Lean:

```lean
def f (x : Nat) : Nat := helper x where
  helper (y : Nat) : Nat := y + 1
```

## 4. Calls and application

D-CALL pseudo-grammar:

```text
DecoratedCall
  ::= CallableHead "(" [Term ("," Term)*] ")"
```

The opening parenthesis must be lexically adjacent to the callable head for the
D-CALL feature to own it.

Examples:

```proofscript
f()
f(x)
f(x, y)
g(f(x), h(y))
f((x, y))
```

Meaning:

```text
f()       -> f ()
f(x)      -> f x
f(x, y)   -> (f x) y
f((x,y))  -> f (x,y)
```

Protected neighbors:

```proofscript
f (x)
f (x, y)
```

are not D-CALL; they use the admitted Lean-compatible application/tuple
interpretation.

Comments/whitespace break adjacency.

## 5. Expression precedence

The current shared ProofScript binary table is:

| Precedence | Operators | Associativity in current parser |
| ---: | --- | --- |
| 1 | `||` | left |
| 2 | `&&` | left |
| 3 | `==`, `!=` | left |
| 4 | `<`, `<=`, `>`, `>=` | left |
| 5 | `+`, `-` | left |
| 6 | `*`, `/`, `%` | left |

Higher numbers bind more tightly.

Application/call syntax binds more tightly than this table.

Propositional `=` is handled separately and is non-associative in the
supported theorem/type grammar. It binds below the current arithmetic,
relations, and Bool binary terms, but above `->`.

The canonical Lean printer uses Lean's own target precedence and must add
parentheses whenever necessary. It must not assume the ProofScript numerical
precedence table is identical to Lean's.

## 6. Literals and primitive terms

The frozen PSC1 scalar vocabulary is:

```text
Nat Int
UInt8 UInt16 UInt32 UInt64 USize
Int8 Int16 Int32 Int64 ISize
Float Float32
Bool Char String Unit
```

The exact set of literal spellings accepted for every scalar is determined by
the frozen parser/elaborator profile. Naming a type does not imply that every
possible Lean literal/notation for that type is already accepted.

Current verified expression/theorem work includes:

- natural-number literals;
- `true`, `false`;
- unary `!`;
- Nat `+ - * / %`;
- Nat `< <= > >=`;
- bounded Nat/Bool `== !=`;
- Bool `&& ||`;
- propositional `=`.

A source implementation must not treat this list as permission to emit a
backend operator without corresponding checked semantics.

## 7. Conditionals

Supported native-style form:

```proofscript
if c then t else e
```

Owned E-IF-BRACE form:

```proofscript
if (c) {
  t
} else {
  e
}
```

Pseudo-grammar:

```text
BracedIf
  ::= "if" "(" Term ")" "{" Term "}" "else" "{" Term "}"
```

Each branch is one term.

This is invalid as a generic multi-statement block:

```proofscript
if (c) { x; y; } else { z }
```

## 8. Structures

Owned form:

```text
StructureDecl
  ::= "structure" Identifier Binder* "where"
      "{" StructureMember* "}"
```

Example:

```proofscript
structure Box where {
  {α: Type};
  value: α;
}
```

Canonical Lean:

```lean
structure Box where
  {α : Type}
  value : α
```

Field semantics are not JavaScript property semantics.

Record construction:

```proofscript
{ field := value, other := value2 }
```

uses the admitted record-term semantics.

Structure update is not a first-freeze requirement unless adopted by the frozen
compiler.

## 9. Classes and instances

Owned class-body form:

```proofscript
class Sized(α: Type) where {
  size: α -> Nat;
}
```

The class is a Lean-compatible typeclass declaration, not an OOP class.

Instance syntax belongs to the bounded class/instance profile. The exact
accepted instance declaration forms are determined by the source feature
matrix; arbitrary Lean instance convenience is not implied.

## 10. Inductives

Owned braced form:

```text
InductiveDecl
  ::= "inductive" Identifier Binder* "where"
      "{" ConstructorDecl* "}"

ConstructorDecl
  ::= "|" ConstructorName [ExplicitParamGroup] ";"
```

Representative example:

```proofscript
inductive Option(α: Type) where {
  | none;
  | some(value: α);
}
```

Canonical Lean:

```lean
inductive Option (α : Type) where
  | none
  | some (value : α)
```

The constructor pseudo-grammar is intentionally illustrative rather than a
claim that all dependent/indexed constructor forms are already source-complete.
The semantic checker remains authoritative.

## 11. Match

Owned braced form:

```text
MatchExpr
  ::= "match" Term "with"
      "{" MatchAlt+ "}"

MatchAlt
  ::= "|" Pattern "=>" Term ";"
```

Example:

```proofscript
match value with {
  | .none => fallback;
  | .some x => f(x);
}
```

Patterns remain in the bounded Lean-compatible pattern family.

PSC1 does not require constructor-call pattern sugar such as `.some(x)`.

## 12. Lambdas, lets, and function types

Lambda:

```proofscript
fun x => body
fun (x: Nat) => body
```

Let:

```proofscript
let x := value
body
```

Exact source sequencing/layout is controlled by the supported expression
grammar. `let` is lexical binding, not mutable JavaScript `let`.

Function type:

```proofscript
Nat -> Nat
```

Dependent function type:

```proofscript
(x: Nat) -> Fin x -> Nat
```

TypeScript arrow lambdas and generic `<T>` binder syntax are not normative
PSC1 forms.

## 13. Proof/theorem syntax

Representative theorem:

```proofscript
theorem addZero(n: Nat): n + 0 = n := by {
  rfl
}
```

The theorem header uses the same supported dependent type/proposition parser;
the body constructs an ordinary kernel-checkable proof term.

Current tactic names supported by the bounded frontend are described in the
main reference and conformance/status document. The syntax accepted by one
tactic does not globally change term parsing.

## 14. `do` and effects

PSC1 requires `do`-style sequencing for its compiler effect capability.

The exact frozen source grammar must map to the owned reader/state/error
semantics. It must not be interpreted as JavaScript async/Promise semantics.

`return`, where accepted in `do`, is an effect-notation operation rather
than an unrestricted early control-flow statement.

Mutation-looking syntax and imperative loops are optional for the first freeze.

## 15. Imports

Bounded shared module header:

```proofscript
import Foo.Bar
```

A ProofScript source printer may accept/normalize documented punctuation around
imports, but canonical Lean-compatible import output does not introduce a
declaration semicolon.

One logical module name resolves to exactly one source candidate in the
configured graph. Ambiguity fails closed.

## 16. External runtime binding extension

Current repository extension:

```text
ExternalDecl
  ::= "extern" "function" Identifier ExplicitParamGroup
      ":" Type
      "from" StringLiteral
      "import" Identifier
      ";"
```

Example:

```proofscript
extern function hostShout(value: String): String
  from "host-lib/feature"
  import shout;
```

This is not part of the old v0.7 feature registry. It is a current
repository-defined host-boundary extension.

Its binding metadata is executable/runtime information, not proof evidence.

Canonical `.ps -> .lean` translation must reject a module when this metadata
cannot be represented faithfully rather than emit an incomplete logical
surrogate as if round-trip equivalence held.

## 17. Source forms intentionally excluded from the PSC1 core

PSC1 does not admit these as equivalent shortcuts:

```typescript
(x) => x + 1       // TypeScript/JS arrow lambda
foo<T>(x)          // TS generic syntax replacing Lean binders
if (x) {...}       // if intended to use JS truthiness
obj.method.call()  // not proof of method-notation support
return value       // not unrestricted early return
```

Neither `null` nor `undefined` is implicit `Option.none`.

## 18. Optional syntax that does not block the first freeze

Unless real compiler source adopts it, the first PSC1 freeze does not require:

- list/array literal sugar;
- tuple destructuring;
- generic indexing syntax;
- multiple/richer pattern forms;
- `if let`;
- local/mutual recursion syntax;
- mutation syntax;
- loops/`break`/`continue`;
- method notation;
- named/default arguments;
- field defaults;
- interpolation;
- broad namespace/section/open syntax;
- arbitrary notation/macros.

If an optional feature is already implemented, it remains supported and must
not be silently weakened.

## 19. Grammar evolution rule

A new syntax form requires:

1. feature ID/classification;
2. exact ownership/discriminator;
3. AST node or explicit normalization rule;
4. canonical semantic lowering;
5. protected-neighbor tests;
6. positive and negative parser cases;
7. elaboration behavior;
8. canonical printer behavior;
9. executable backend path when relevant;
10. explicit REQUIRED/OPTIONAL/DEFERRED/HOST classification.

Parser convenience alone is insufficient.
