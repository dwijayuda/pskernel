# PSC2 Complete Language Features — Syntax, Grammar, Semantics, and Examples

**Status:** non-normative consolidated handbook generated from the current r3 language specification  
**Normative authority:** <code>ProofScript_Language_Reference_v0.9.0_r3.md</code>  
**Language edition:** <code>ps-0.9-r3</code>  
**Required compiler language profile:** <code>psc2-language-v1</code>  
**Standard language profile:** <code>psc2-standard-language-v1</code>  
**Standard source profile:** <code>ps-standard-0.9-r3</code>  
**Extensible source profile:** <code>ps-lean-extensible-0.9-r3</code>  
**Lean compatibility profile:** <code>lean-subset-psc2-v1</code>  
**Pattern profile:** <code>psc2-pattern-v1</code>  
**Semantic pin:** Lean 4.34.0, commit <code>293d5d0c0c3f3dded4688b3ccd6a33939ac5102b</code>

This document collects the entire current PSC2 source-language surface into one place. It is intended as a feature handbook for humans, AI coding agents, compiler authors, library authors, and reviewers.

It covers:

- every required <code>psc2-language-v1</code> source family;
- the fixed Standard prover/notation/attribute surface in <code>psc2-standard-language-v1</code>;
- all current ProofScript-owned grammar;
- accepted syntax variants;
- semantic rules;
- canonical and edge-case examples;
- explicit rejection cases;
- the boundary between PSC2 core, Standard libraries/prover facilities, extensible profiles, tooling, and Post-PSC2 language work.

If this document disagrees with the normative language reference, the normative language reference wins.

---

# 1. Language model

ProofScript PSC2 is a Lean-compatible dependent programming and theorem-proving language with a smaller application-oriented surface.

The semantic foundation includes:

- <code>Prop</code>;
- <code>Type</code> and <code>Sort</code>;
- universe levels;
- dependent function/Pi types;
- lambdas and function application;
- propositions as types;
- proof terms;
- inductive families;
- constructors;
- recursors and dependent elimination;
- equality;
- quotient semantics from the pinned Lean foundation;
- proof irrelevance according to the pinned theory;
- selected typeclass-directed elaboration;
- selected coercions;
- definitional equality;
- structural recursion;
- explicitly selected total-recursion facilities.

ProofScript does not define a second JavaScript/TypeScript semantic model.

The basic design rule is:

~~~text
accepted ProofScript source
  -> ProofScript-owned surface interpretation where applicable
  -> selected Lean-compatible meaning
~~~

Unsupported input rejects rather than silently changing meaning.

---

# 2. Profile identities

## 2.1 Language edition

~~~text
ps-0.9-r3
~~~

## 2.2 Standard source profile

~~~text
ps-standard-0.9-r3
~~~

Standard has a closed grammar.

Ordinary dependencies cannot silently register:

- new syntax categories;
- new notation;
- new parser extensions;
- new macros;
- new term elaborators;
- new command elaborators;
- new tactic syntax;
- new tactic elaborators;
- new deriving handlers;
- new attribute handlers.

## 2.3 Extensible source profile

~~~text
ps-lean-extensible-0.9-r3
~~~

This profile may explicitly load declared syntax, notation, macros, elaborators, tactics, Meta facilities, and parser extensions.

Those extension identities are part of the source/environment identity.

## 2.4 Required PSC2 language profile

~~~text
psc2-language-v1
~~~

A compiler claiming <code>psc2-compiler-v1</code> must support this entire language closure.

## 2.5 Standard language-facing profile

~~~text
psc2-standard-language-v1
~~~

Conceptually:

~~~text
psc2-standard-language-v1
=
psc2-language-v1
+ ps-standard-0.9-r3 closed grammar
+ fixed Standard notation/attributes
+ fixed Standard prover surface
~~~

## 2.6 Lean compatibility profile

~~~text
lean-subset-psc2-v1
~~~

This is intentionally bounded. It does not imply full Lean source compatibility.

## 2.7 Pattern profile

~~~text
psc2-pattern-v1
~~~

Required patterns:

- variable;
- wildcard;
- constructor;
- nested constructor;
- tuple/product;
- supported literal;
- single-scrutinee match.

---

# 3. Complete feature checklist

| Feature family | PSC2 status |
|---|---|
| identifiers/literals/comments | required |
| modules/imports/qualified names | required |
| public import / transitive re-export | required |
| namespace/section/open/variable/include/omit/universe | required |
| private visibility | required |
| registered attributes | required |
| registered options | required |
| def | required |
| const | required |
| function | required |
| unbraced definition body | required |
| single-term braced definition body | required |
| theorem | required |
| example | required |
| abbrev | required |
| opaque | required |
| axiom | required |
| structure | required |
| class | required |
| instance | required |
| inductive | required |
| constructors | required |
| projections | required |
| record construction | required |
| record update | required |
| explicit binders | required |
| implicit binders | required |
| strict implicit binders | required |
| instance binders | required |
| universe syntax | required |
| lambda | required |
| let | required |
| function application | required |
| parenthesized calls | required |
| named arguments | required |
| default arguments | required |
| empty calls | required |
| call trailing comma | required |
| parameter trailing comma | required |
| generalized field notation | required |
| local where declarations | required |
| parenthesized terms | required |
| tuple/product terms | required |
| type ascription | required |
| dependent/Pi function syntax | required |
| forall/exists | required |
| native/braced if | required |
| psc2-pattern-v1 | required |
| single-scrutinee match | required |
| structural recursion | required |
| local recursion | required |
| mutual recursion | required |
| partial def | required |
| noncomputable | required |
| unsafe | excluded from PSC2 Standard |
| ordinary typeclass search | required |
| selected coercion insertion | required |
| Prop/Type/Sort/Pi/Eq | required |
| proof terms / by | required |
| have/show/suffices/calc | required |
| pure requires/ensures contracts | required |
| fixed Standard tactic surface | Standard selection |
| fixed Standard notation | Standard selection |
| fixed Standard attributes | Standard selection |
| #check/#print/#reduce/#eval | tooling only |

---

# 3.1 Current feature-registry IDs

These IDs are the current machine-readable r3 feature/profile identifiers. They are included here so every active registry entry has a human-readable location in this handbook.

| Feature ID | Meaning |
|---|---|
| <code>L-CORE-LEAN</code> | explicitly included pinned Lean semantic categories |
| <code>M-PUBLIC-IMPORT-R3</code> | Lean-compatible <code>public import</code> module re-export |
| <code>D-CONST-ALIAS</code> | <code>const</code> parameterless-definition alias |
| <code>D-FUNCTION-ALIAS-R3</code> | <code>function</code> declaration alias |
| <code>D-FUNCTION-UNIT-R3</code> | zero-source-argument <code>function f()</code> sugar |
| <code>D-DECL-BODY-BRACE-R3</code> | single-term <code>:= { PSTerm }</code> body wrapper |
| <code>D-EXPLICIT-PARAMS</code> | comma-separated explicit parameter group |
| <code>E-CALL-PARENS-R3</code> | ProofScript-owned parenthesized call |
| <code>E-EMPTY-CALL-R3</code> | empty-call/default-completion syntax |
| <code>D-NAMED-CALL</code> | named argument syntax |
| <code>D-TRAILING-COMMA-CALL</code> | trailing comma in nonempty call |
| <code>D-TRAILING-COMMA-PARAMS</code> | trailing comma in explicit parameter group |
| <code>E-IF-BRACE</code> | one-term braced conditional branches |
| <code>E-STRUCT-BODY-R3</code> | structural braced structure fields |
| <code>E-CLASS-BODY-R3</code> | structural braced class fields |
| <code>E-INDUCTIVE-BODY-R3</code> | structural braced inductive constructors |
| <code>E-MATCH-BODY-R3</code> | structural braced match alternatives |
| <code>E-INSTANCE-BODY-R3</code> | structural braced instance initializer sequence |
| <code>E-WHERE-BODY-R3</code> | structural braced local where declarations |
| <code>N-BASIC-DO-PSC2</code> | required bounded native do subset |
| <code>S-PURE-CONTRACT-R3</code> | pure requires/ensures contract surface |
| <code>P-STANDARD-R3</code> | closed Standard source profile |
| <code>P-LEAN-EXTENSIBLE-R3</code> | declared extensible source profile |
| <code>P-PSC2-LANGUAGE-V1</code> | required PSC2 language capability profile |
| <code>P-PSC2-STANDARD-LANGUAGE-V1</code> | Standard language-facing PSC2 profile |
| <code>P-LEAN-SUBSET-PSC2-V1</code> | bounded Lean compatibility profile |
| <code>P-PATTERN-PSC2-V1</code> | required PSC2 pattern profile |

---

# 4. Lexical rules

## 4.1 Identifiers and literals

ProofScript uses the selected native lexical families for identifiers and literals.

Representative source:

~~~proofscript
const count: Nat := 42
const name: String := "Alice"
const enabled: Bool := true
~~~

The exact literal meaning is determined by the selected semantic type and native notation.

## 4.2 Comments

ProofScript inherits selected native comment forms.

Example:

~~~proofscript
-- line comment

/- block comment -/

function add(x: Nat, y: Nat): Nat := {
  x + y
}
~~~

## 4.3 No JavaScript automatic semicolon insertion

ProofScript does not use JavaScript automatic semicolon insertion.

A newline does not implicitly synthesize a general statement terminator.

---

# 5. CallGap

CallGap is the horizontal trivia between a completed callable head and the opening parenthesis of a ProofScript-owned call.

Accepted:

~~~proofscript
f(x)
f (x)
f /* comment */ (x)
~~~

A physical newline breaks this ownership:

~~~proofscript
f
(x)
~~~

The latter is not one r3 parenthesized call.

Conceptual grammar:

~~~ebnf
ParenthesizedCall :=
  CallableHead CallGap "(" CallArguments? ")"
~~~

CallGap permits inherited horizontal space/comments that do not contain a physical line terminator.

---

# 6. Modules and names

## 6.1 Ordinary import

~~~proofscript
import Std.Data.List
import MyProject.Util
~~~

An ordinary `import M` makes `M`'s public declarations available to the current module.

It does **not** re-export `M` as part of the current module's public dependency surface.

Imports do not grant new Standard parser registrations.

## 6.2 public import

~~~proofscript
public import Public.Core
public import Public.Data
~~~

`public import M` imports `M` and re-exports the public declarations reachable through `M`'s public-import closure.

Rules:

- ordinary top-level declarations are public unless marked `private`;
- `private` declarations are never exported or re-exported;
- ordinary `import` does not re-export;
- `public import` does re-export;
- `open` affects local name resolution only and never re-exports;
- re-export preserves declaration identity;
- ambiguous imported/re-exported names reject deterministically.

PSC2 does not require TypeScript/ECMAScript-style selective export lists, default exports, or namespace exports as core syntax.

A curated public API should use a facade module:

~~~proofscript
import Internal.BigModule

def selectedValue := Internal.BigModule.selectedValue
theorem selectedLaw := Internal.BigModule.selectedLaw
~~~

or intentionally public-import whole public modules:

~~~proofscript
public import Public.Core
public import Public.Data
~~~

## 6.3 Qualified names

~~~proofscript
Foo.Bar.value
Namespace.Type.constructor
~~~

## 6.4 One authoritative source per module

A logical module resolves to one selected source.

If both:

~~~text
Foo.ps
Foo.lean
~~~

could define the same module and no explicit selection exists, the build must reject ambiguity.

---

# 7. namespace

~~~proofscript
namespace Math

const answer: Nat := {
  42
}

end Math
~~~

Qualified use:

~~~proofscript
Math.answer
~~~

---

# 8. section

~~~proofscript
section

variable {α: Type}

function id(x: α): α := {
  x
}

end
~~~

Sections affect local declaration context; they do not introduce a different type theory.

---

# 9. variable

~~~proofscript
section

variable {α: Type}
variable (x: α)

function keep(): α := {
  x
}

end
~~~

Section variables follow selected native dependency/scope rules.

---

# 10. include and omit

Representative source:

~~~proofscript
section

variable {α: Type}
variable (x: α)

include x

function useX(): α := {
  x
}

omit x

end
~~~

These commands control selected declaration dependency behavior.

---

# 11. open

~~~proofscript
open List
open MyNamespace
~~~

The Standard profile permits only the selected deterministic namespace/open behavior.

---

# 12. universe

~~~proofscript
universe u v
~~~

Use in types:

~~~proofscript
function id {α: Type u}(x: α): α := {
  x
}
~~~

ProofScript retains Lean-compatible universe constraints for the supported source subset.

---

# 13. Visibility

## 13.1 Public/default declaration

~~~proofscript
def visible(): Nat := {
  1
}
~~~

## 13.2 private

~~~proofscript
private def helper(): Nat := {
  1
}
~~~

Visibility affects name accessibility, not theorem truth or type meaning.

---

# 14. def

A <code>def</code> is an ordinary definition under the selected Lean-compatible semantics.

Unbraced body:

~~~proofscript
def double(n: Nat): Nat :=
  n + n
~~~

Braced body:

~~~proofscript
def double(n: Nat): Nat := {
  n + n
}
~~~

Both are semantically identical.

---

# 15. const

A <code>const</code> is a module/namespace-level parameterless definition alias.

Unbraced:

~~~proofscript
const answer: Nat := 42
~~~

Braced:

~~~proofscript
const answer: Nat := {
  42
}
~~~

It does not mean:

- JS/TS rebinding restriction;
- object freezing;
- runtime constant folding;
- module hoisting.

A <code>const</code> may hold a function value:

~~~proofscript
const increment: Nat -> Nat := {
  fun n => n + 1
}
~~~

---

# 16. function

A <code>function</code> is a declaration-head alias for an ordinary function definition with ProofScript explicit-parameter syntax.

Unbraced:

~~~proofscript
function add(x: Nat, y: Nat): Nat :=
  x + y
~~~

Braced:

~~~proofscript
function add(x: Nat, y: Nat): Nat := {
  x + y
}
~~~

The core function model remains curried/dependent.

---

# 17. Definition-body variants

Feature identity:

~~~text
D-DECL-BODY-BRACE-R3
~~~

Grammar:

~~~ebnf
DefinitionBody :=
  ":=" (PSTerm | BracedDefinitionBody)

BracedDefinitionBody :=
  "{" PSTerm "}"
~~~

Semantic identity:

~~~text
:= term
≡
:= { term }
~~~

The braces are a single-term wrapper.

They do not add:

- statement sequencing;
- implicit return;
- JavaScript scope semantics;
- a second function model.

Valid:

~~~proofscript
function classify(x: Nat): Nat := {
  if (x == 0) {
    0
  } else {
    1
  }
}
~~~

Invalid as a declaration-body wrapper:

~~~proofscript
function invalid(): Nat := {
  1
  2
}
~~~

because two unrelated terms are not one <code>PSTerm</code>.

---

# 18. Record literal ownership inside definition bodies

A direct record literal remains a complete term:

~~~proofscript
const user: User := {
  id := 1,
  name := "Alice"
}
~~~

This is not interpreted as a generic body block containing field statements.

If an explicit body wrapper around the record is desired:

~~~proofscript
const user: User := {
  {
    id := 1,
    name := "Alice"
  }
}
~~~

Both have the same resulting value meaning.

---

# 19. theorem

~~~proofscript
theorem addZero(n: Nat): n + 0 = n := by {
  simp
}
~~~

A theorem is accepted only if the selected proof checker accepts its proof term.

---

# 20. example

~~~proofscript
example : 1 + 1 = 2 := by {
  rfl
}
~~~

An <code>example</code> checks a proposition/proof without defining an ordinary reusable named theorem unless the selected native form provides a name.

---

# 21. abbrev

~~~proofscript
abbrev UserId := Nat
~~~

An abbreviation follows the selected reducibility/transparency semantics.

It is not only pretty-printer metadata.

---

# 22. opaque

~~~proofscript
opaque hiddenValue: Nat := 42
~~~

Opacity controls definitional unfolding according to the selected semantics.

It does not authorize an ill-typed definition.

---

# 23. axiom

~~~proofscript
axiom externalLaw : P
~~~

An axiom is an explicit logical assumption.

A theorem depending on it carries that logical dependency.

An axiom is not equivalent to a proved theorem.

---

# 24. partial

~~~proofscript
partial def loop(n: Nat): Nat := {
  loop(n)
}
~~~

A partial definition is an explicit runtime-only recursion boundary and is not accepted as ordinary total logical computation.

---

# 25. noncomputable

~~~proofscript
noncomputable def chooseValue(): α := {
  ...
}
~~~

A noncomputable declaration may exist logically without requiring ordinary executable realization.

---

# 26. unsafe

<code>unsafe</code> is excluded from:

~~~text
psc2-language-v1
ps-standard-0.9-r3
~~~

A separately named extensible/host profile may define an unsafe boundary.

Standard source must not silently accept it.

---

# 27. Explicit binders

ProofScript explicit parameter group:

~~~proofscript
function add(x: Nat, y: Nat): Nat := {
  x + y
}
~~~

Grammar:

~~~ebnf
ExplicitGroup :=
  "(" ExplicitEntry ("," ExplicitEntry)* ","? ")"

ExplicitEntry :=
  BinderIdent ":" PSTerm DefaultSuffix?
~~~

Trailing comma is allowed:

~~~proofscript
function add(
  x: Nat,
  y: Nat,
): Nat := {
  x + y
}
~~~

---

# 28. Implicit binders

~~~proofscript
function id {α: Type}(x: α): α := {
  x
}
~~~

Implicit binders follow selected Lean-compatible insertion/elaboration behavior.

---

# 29. Strict implicit binders

PSC2 includes the selected native strict-implicit binder family.

Representative spelling:

~~~proofscript
function use {{α: Type}}(x: α): α := {
  x
}
~~~

The exact accepted strict-implicit delimiter/spelling follows the selected native grammar.

---

# 30. Instance binders

~~~proofscript
function compareValues {α: Type}[Ord α](x: α, y: α): Ordering := {
  compare(x, y)
}
~~~

The instance argument may be synthesized through the selected typeclass search.

---

# 31. Default parameter suffix

Grammar:

~~~ebnf
DefaultSuffix :=
  ":=" PSTerm
~~~

Example:

~~~proofscript
function greet(name: String := "world"): String := {
  "Hello, " ++ name
}
~~~

Defaults are elaboration/application semantics, not runtime overload dispatch.

---

# 32. Zero-source-argument functions

~~~proofscript
function now(): Time := {
  clockValue
}
~~~

Conceptual lowering:

~~~text
function f(): R
≈
def f (_unit : Unit := ()) : R
~~~

Rules:

1. the empty explicit group is final;
2. native implicit/instance binders may precede it;
3. it cannot be followed by another explicit parameter group.

Rejected:

~~~proofscript
function bad()(x: Nat): Nat := x
function bad(x: Nat)(): Nat := x
~~~

---

# 33. FunctionHeader grammar

~~~ebnf
FunctionHeader :=
  "function"
  Ident
  NativeNonExplicitBinder*
  (ExplicitGroup | EmptyExplicitGroup)
  (":" PSTerm)?

EmptyExplicitGroup :=
  "(" ")"
~~~

---

# 34. Lambdas

~~~proofscript
fun x => x + 1
~~~

Typed/dependent lambda forms follow selected native binder semantics.

Example:

~~~proofscript
const idNat: Nat -> Nat := {
  fun x => x
}
~~~

TypeScript arrow syntax such as:

~~~text
x => x + 1
~~~

is not current base ProofScript syntax.

---

# 35. Function/Pi types

Simple function type:

~~~proofscript
Nat -> Nat
~~~

Dependent function type:

~~~proofscript
(n: Nat) -> Fin n -> Nat
~~~

The type of a later parameter/result may depend on an earlier value.

---

# 36. forall

Representative proposition:

~~~proofscript
forall x : Nat, x = x
~~~

The selected native quantifier semantics are retained.

---

# 37. exists

Representative proposition:

~~~proofscript
exists x : Nat, x = 0
~~~

Existence is a proposition, not merely a runtime search result.

---

# 38. let

~~~proofscript
function plusOne(): Nat := {
  let x := 1
  x + 1
}
~~~

The complete <code>let ... body</code> form is one term.

A <code>let</code> binding does not imply mutable storage.

---

# 39. Parenthesized terms

~~~proofscript
(x)
(1 + 2)
~~~

Parentheses group a term according to selected precedence rules.

---

# 40. Tuple/product terms

~~~proofscript
(1, 2)
("Alice", true)
~~~

One tuple passed as one parenthesized call argument requires another grouping layer:

~~~proofscript
tupled((1, 2))
~~~

---

# 41. Type ascription

~~~proofscript
(x : Nat)
(1 : Nat)
~~~

Type ascription participates in type checking/elaboration.

It is not an unchecked type assertion.

---

# 42. Parenthesized function calls

~~~proofscript
add(1, 2)
~~~

Also valid:

~~~proofscript
add (1, 2)
~~~

under the CallGap rule.

---

# 43. Call arguments grammar

~~~ebnf
CallArguments :=
  CallArgument ("," CallArgument)* ","?

CallArgument :=
    NamedCallArgument
  | PSTerm
~~~

---

# 44. Named arguments

Grammar:

~~~ebnf
NamedCallArgument :=
  Ident ":=" PSTerm
~~~

Example:

~~~proofscript
connect(
  host := "localhost",
  timeout := 5000,
)
~~~

Named arguments are application/elaboration semantics, not runtime object passing.

---

# 45. Call trailing comma

Accepted:

~~~proofscript
f(
  x,
  y,
)
~~~

The trailing comma adds no argument.

---

# 46. Empty calls

~~~proofscript
greet()
~~~

An empty call requests completion of omitted optional/automatic explicit parameters.

Accepted:

~~~proofscript
function greet(name: String := "world"): String := {
  name
}

greet()
~~~

Rejected:

~~~proofscript
function add1(x: Nat): Nat := {
  x + 1
}

add1()
~~~

because an ordinary required explicit argument remains.

---

# 47. Empty call vs explicit Unit

These are different:

~~~proofscript
f()
f(())
~~~

<code>f()</code> is empty-invocation/default completion.

<code>f(())</code> supplies an explicit <code>Unit</code> value as one argument.

---

# 48. Generalized field notation

~~~proofscript
users.map(toName)
value.method(arg)
~~~

Field/method notation is static/type-directed.

It is not JavaScript prototype lookup or arbitrary dynamic property dispatch.

---

# 49. Structures

~~~proofscript
structure User where {
  id: Nat,
  name: String,
  active: Bool
}
~~~

Grammar:

~~~ebnf
StructBody :=
  "{" (StructField ("," StructField)*)? "}"
~~~

Rules:

- fields are comma-separated;
- no trailing field comma;
- structure identity is logical/nominal, not TypeScript structural object identity.

Rejected:

~~~proofscript
structure User where {
  id: Nat,
  name: String,
}
~~~

---

# 50. Record construction

~~~proofscript
const user: User := {
  id := 1,
  name := "Alice",
  active := true
}
~~~

Record construction uses selected structure constructor semantics.

---

# 51. Projections

~~~proofscript
const id: Nat := {
  user.id
}

const name: String := {
  user.name
}
~~~

Projection meaning comes from the declared structure.

---

# 52. Record update

~~~proofscript
function activate(user: User): User := {
  { user with active := true }
}
~~~

This means selected structure-update semantics.

It does not mean JavaScript object spread.

---

# 53. Classes

~~~proofscript
class Sized(α: Type) where {
  size: α -> Nat
}
~~~

Grammar:

~~~ebnf
ClassBody :=
  "{" (ClassField ("," ClassField)*)? "}"
~~~

No trailing class-field comma.

A class is a type-directed abstraction, not a JavaScript/TypeScript OO class.

---

# 54. Instances

~~~proofscript
instance : Sized String where {
  size(s: String): Nat := s.length;
}
~~~

Conceptual body grammar:

~~~ebnf
InstanceBody :=
  "{" (InstanceField (";" InstanceField)* ";"?)? "}"
~~~

Semicolon separates instance initializer fields in brace mode.

---

# 55. Typeclass search

Given:

~~~proofscript
class Sized(α: Type) where {
  size: α -> Nat
}

instance : Sized String where {
  size(s: String): Nat := s.length;
}
~~~

a function can request the class:

~~~proofscript
function sizeOf {α: Type}[Sized α](x: α): Nat := {
  Sized.size(x)
}
~~~

The selected instance may be inferred.

---

# 56. Coercions

PSC2 permits selected Lean-compatible coercion insertion.

Coercions are type-directed elaboration behavior.

They are not:

- JavaScript automatic conversions;
- TypeScript structural assignment;
- arbitrary runtime casts.

Ambiguous/unsupported coercion behavior rejects.

---

# 57. Inductive types

~~~proofscript
inductive Result(ε: Type, α: Type) where {
  | ok(value: α)
  | error(error: ε)
}
~~~

Grammar:

~~~ebnf
InductiveBody :=
  "{" ("|" ConstructorBody)* "}"
~~~

Inductive semantics include selected:

- constructor typing;
- positivity;
- parameters;
- indices;
- dependent elimination.

---

# 58. Constructors

Use constructors:

~~~proofscript
Result.ok(42)
Result.error("failed")
~~~

Shorthand constructor notation may be available in contexts where selected native elaboration determines the type:

~~~proofscript
.ok(42)
.error("failed")
~~~

---

# 59. Indexed inductives

PSC2 preserves selected indexed/dependent inductive semantics.

Representative concept:

~~~proofscript
inductive Vec(α: Type): Nat -> Type where {
  | nil : Vec α 0
  | cons(value: α, tail: Vec α n) : Vec α (n + 1)
}
~~~

Only result-type forms admitted by the selected PSC2 source subset are accepted.

---

# 60. Pattern profile

<code>psc2-pattern-v1</code> requires the following.

## 60.1 Variable pattern

~~~proofscript
| .some x => x
~~~

## 60.2 Wildcard pattern

~~~proofscript
| .error _ => fallback
~~~

## 60.3 Constructor pattern

~~~proofscript
| .some x => x
~~~

## 60.4 Nested constructor pattern

~~~proofscript
| .some (.ok x) => x
~~~

## 60.5 Tuple/product pattern

~~~proofscript
| (x, y) => x + y
~~~

where the containing native pattern category accepts that form.

## 60.6 Supported literal pattern

Representative:

~~~proofscript
| 0 => base
~~~

where literal matching has exact selected semantics.

---

# 61. match

~~~proofscript
function getOrElse(value: Option Nat, fallback: Nat): Nat := {
  match value with {
    | .none => fallback
    | .some x => x
  }
}
~~~

Grammar:

~~~ebnf
MatchBody :=
  "{" ("|" PatternGroup "=>" PSTerm)+ "}"
~~~

The required PSC2 profile is single-scrutinee.

Not required by PSC2 core:

- multi-scrutinee matching;
- arbitrary pattern alternatives;
- full Lean equation compiler;
- arbitrary dependent motive synthesis;
- user-defined pattern macros.

---

# 62. if

ProofScript braced conditional:

~~~proofscript
if (condition) {
  thenTerm
} else {
  elseTerm
}
~~~

Grammar:

~~~ebnf
BracedIf :=
  "if" "(" PSTerm ")" "{" PSTerm "}"
  "else" "{" PSTerm "}"
~~~

Each branch is exactly one term.

The braces are not generic statement blocks.

---

# 63. Structural recursion

~~~proofscript
function sum(xs: List Nat): Nat := {
  match xs with {
    | .nil => 0
    | .cons x rest => x + sum(rest)
  }
}
~~~

Accepted total recursion must satisfy the selected structural/termination semantics.

---

# 64. Local recursion

PSC2 requires supported local recursive definitions.

Representative:

~~~proofscript
function outer(n: Nat): Nat := {
  helper(n)
}
where {
  function helper(x: Nat): Nat := {
    if (x == 0) {
      0
    } else {
      helper(x - 1)
    }
  };
}
~~~

The actual accepted recursion must satisfy the selected termination/partial boundary.

---

# 65. mutual recursion

Representative PSC syntax:

~~~proofscript
mutual
  function even(n: Nat): Bool := {
    if (n == 0) {
      true
    } else {
      odd(n - 1)
    }
  }

  function odd(n: Nat): Bool := {
    if (n == 0) {
      false
    } else {
      even(n - 1)
    }
  }
end
~~~

Mutual recursion uses the selected native mutual-declaration meaning for supported declarations.

---

# 66. Well-founded recursion boundary

Full arbitrary Lean termination elaboration is not required by <code>psc2-language-v1</code>.

A later Standard prover/extension may provide richer termination syntax or automation.

The logical foundation remains Lean-compatible.

---

# 67. Basic do notation

~~~proofscript
function load(): CompilerM Nat := do {
  let x ← readValue
  pure (x + 1)
}
~~~

Required forms:

- term statement;
- simple <code>let</code>;
- identifier monadic bind;
- wildcard monadic bind;
- pure/return-style completion supported by the selected native do category.

The meaning is selected <code>Bind</code>/<code>Pure</code> sequencing.

It is not a JavaScript statement block.

---

# 68. Basic do examples

## 68.1 Monadic bind

~~~proofscript
do {
  let x ← readValue
  pure x
}
~~~

## 68.2 Wildcard bind

~~~proofscript
do {
  let _ ← logMessage("starting")
  pure ()
}
~~~

## 68.3 Simple let

~~~proofscript
do {
  let x := 10
  pure (x + 1)
}
~~~

Not PSC2 basic-do syntax:

~~~text
let mut
assignment
for
while
break
continue
arbitrary refutable do-pattern bind
~~~

---

# 69. Nat

~~~proofscript
const n: Nat := 42
~~~

Semantics:

- exact nonnegative natural numbers;
- subtraction truncates at zero;
- division/remainder use selected pinned definitions.

Example:

~~~proofscript
const x: Nat := {
  3 - 5
}
~~~

has natural-number subtraction semantics rather than JavaScript numeric semantics.

---

# 70. Int

~~~proofscript
const n: Int := -42
~~~

<code>Int</code> uses selected exact signed mathematical integer semantics.

---

# 71. Fixed-width and target-word integers

The supported integer families preserve explicit:

- width;
- overflow/wrapping/checking;
- shifts;
- conversions;
- target-word assumptions where applicable.

Representative families can include:

~~~text
UInt8
UInt16
UInt32
UInt64
USize
Int8
Int16
Int32
Int64
ISize
~~~

A host JavaScript number is not the source semantic definition.

---

# 72. Float and Float32

~~~proofscript
const x: Float := 1.5
~~~

Floating values preserve selected:

- rounding;
- NaN;
- infinities;
- signed zero;
- operation behavior.

They are distinct from exact <code>Nat</code>/<code>Int</code>.

---

# 73. Bool

~~~proofscript
const enabled: Bool := true
~~~

<code>Bool</code> is different from <code>Prop</code>.

A Boolean value does not automatically prove a proposition.

---

# 74. Proposition equality vs Boolean equality

Proposition:

~~~proofscript
x = y
~~~

Boolean-valued equality where selected:

~~~proofscript
x == y
~~~

These are different semantic categories.

---

# 75. Char

~~~proofscript
const c: Char := 'A'
~~~

The exact accepted literal syntax follows the selected lexical/native category.

<code>Char</code> retains pinned semantics.

---

# 76. String

~~~proofscript
const name: String := "Alice"
~~~

A host UTF-16 JavaScript representation does not redefine ProofScript string semantics.

---

# 77. ByteArray

<code>ByteArray</code> is a distinct binary-data abstraction.

It is not merely a String or arbitrary host buffer.

---

# 78. Unit

~~~proofscript
()
~~~

<code>Unit</code> has its selected one-value semantics.

It is used by zero-source-argument function sugar through an optional Unit binder.

---

# 79. Prod / tuples

~~~proofscript
const pair: Nat × String := {
  (1, "one")
}
~~~

Product syntax/semantics follow the selected native family.

---

# 80. Sum

<code>Sum α β</code> remains a distinct algebraic data family.

Representative constructor use follows selected native constructor syntax.

---

# 81. Option

~~~proofscript
const maybe: Option Nat := {
  .some(42)
}
~~~

Match:

~~~proofscript
match maybe with {
  | .none => 0
  | .some x => x
}
~~~

ProofScript does not replace <code>Option</code> with implicit null/undefined.

---

# 82. Except

~~~proofscript
const result: Except String Nat := {
  .ok(42)
}
~~~

Errors are explicit values in the typed result family.

Host exceptions do not automatically become this typed error channel.

---

# 83. List

Representative:

~~~proofscript
function length(xs: List α): Nat := {
  match xs with {
    | .nil => 0
    | .cons _ rest => 1 + length(rest)
  }
}
~~~

<code>List</code> is semantically distinct from <code>Array</code>.

---

# 84. Array

<code>Array α</code> is a separate data family with selected native/library semantics.

It is not interchangeable with List merely because both may be iterable collections.

---

# 85. Fin

~~~proofscript
function select(n: Nat, i: Fin n): Fin n := {
  i
}
~~~

<code>Fin n</code> carries a type-level bound indexed by <code>n</code>.

It is not merely a runtime integer check.

---

# 86. Subtypes

PSC2 supports selected subtype semantics from the pinned foundation.

A subtype combines a value with evidence of a proposition.

It is not equivalent to a TypeScript brand alone.

---

# 87. Prop

~~~proofscript
P : Prop
~~~

Propositions are types whose inhabitants are proofs.

---

# 88. Type and Sort

~~~proofscript
Type
Type u
Sort u
~~~

These are universe-level language constructs, not TypeScript generic meta-types.

---

# 89. Dependent types

Example:

~~~proofscript
function select(n: Nat, i: Fin n): Fin n := {
  i
}
~~~

The value <code>n</code> appears in the type of <code>i</code> and the result.

---

# 90. Equality

A proposition:

~~~proofscript
theorem reflNat(n: Nat): n = n := by {
  rfl
}
~~~

Equality is part of the logical theory.

---

# 91. Quotients

ProofScript inherits quotient semantics from the pinned logical foundation.

No new PSC2-specific quotient syntax is required.

Quotient theorems/libraries can be supplied above the core syntax.

---

# 92. Proof irrelevance

ProofScript inherits proof irrelevance according to the pinned logical foundation.

This affects logical equality/semantics of proofs, not ordinary runtime object identity.

---

# 93. Proof terms

A theorem may be defined by an explicit proof term or a tactic block that produces one.

Representative:

~~~proofscript
theorem identityProof(P: Prop, h: P): P := {
  h
}
~~~

where the selected theorem/term grammar accepts the term directly.

---

# 94. by blocks

~~~proofscript
theorem addZero(n: Nat): n + 0 = n := by {
  simp
}
~~~

The block is proof/tactic syntax.

A tactic implementation is not independent proof authority; accepted output must be a valid proof.

---

# 95. have

~~~proofscript
theorem chain(P Q: Prop, hp: P, h: P -> Q): Q := by {
  have hq : Q := h(hp)
  exact hq
}
~~~

---

# 96. show

Representative proof form:

~~~proofscript
theorem t(P: Prop, h: P): P := by {
  show P
  exact h
}
~~~

---

# 97. suffices

Representative:

~~~proofscript
theorem t(P Q: Prop, hPQ: P -> Q, hp: P): Q := by {
  suffices h : P from hPQ(h)
  exact hp
}
~~~

The exact selected tactic/term form follows the Standard prover surface.

---

# 98. calc

~~~proofscript
theorem transEq(a b c: Nat, h1: a = b, h2: b = c): a = c := by {
  calc
    a = b := h1
    _ = c := h2
}
~~~

---

# 99. Standard prover surface

<code>psc2-standard-language-v1</code> fixes the following tactic heads:

~~~text
rfl
exact
exact?
apply
refine
intro
intros
assumption
constructor
cases
induction
rw
simp
simpa
simp_all
unfold
change
dsimp
have
show
suffices
by_cases
by_contra
exfalso
subst
generalize
rcases
rintro
obtain
use
ext
decide
omega
grind
~~~

Fixed variant:

~~~text
simp only
~~~

Fixed proof command:

~~~text
classical
~~~

These are Standard prover selections, not new kernel primitives.

---

# 100. Tactic examples

## 100.1 rfl

~~~proofscript
theorem refl(n: Nat): n = n := by {
  rfl
}
~~~

## 100.2 exact

~~~proofscript
theorem useProof(P: Prop, h: P): P := by {
  exact h
}
~~~

## 100.3 assumption

~~~proofscript
theorem useAssumption(P: Prop, h: P): P := by {
  assumption
}
~~~

## 100.4 intro

~~~proofscript
theorem identity(P: Prop): P -> P := by {
  intro h
  exact h
}
~~~

## 100.5 apply

~~~proofscript
theorem useImp(P Q: Prop, hPQ: P -> Q, hP: P): Q := by {
  apply hPQ
  exact hP
}
~~~

## 100.6 constructor

~~~proofscript
theorem pairProof(P Q: Prop, hp: P, hq: Q): P ∧ Q := by {
  constructor
  exact hp
  exact hq
}
~~~

## 100.7 cases

~~~proofscript
theorem optionCases(x: Option Nat): True := by {
  cases x
  · trivial
  · trivial
}
~~~

Only forms selected by the Standard prover/profile are accepted.

## 100.8 induction

~~~proofscript
theorem natExample(n: Nat): n = n := by {
  induction n
  · rfl
  · simp
}
~~~

## 100.9 rw

~~~proofscript
theorem rewriteExample(a b: Nat, h: a = b): a + 1 = b + 1 := by {
  rw [h]
}
~~~

## 100.10 simp / simpa / simp only / simp_all

~~~proofscript
theorem simpExample(n: Nat): n + 0 = n := by {
  simp
}
~~~

~~~proofscript
theorem simpaExample(n: Nat): n + 0 = n := by {
  simpa
}
~~~

~~~proofscript
theorem simpOnlyExample(n: Nat): n + 0 = n := by {
  simp only [Nat.add_zero]
}
~~~

## 100.11 refine

~~~proofscript
theorem refineExample(P: Prop, h: P): P := by {
  refine ?_
  exact h
}
~~~

## 100.12 by_cases

~~~proofscript
theorem caseSplit(P: Prop): P ∨ ¬P := by {
  classical
  by_cases h : P
  · exact Or.inl h
  · exact Or.inr h
}
~~~

## 100.13 by_contra / exfalso

These are selected contradiction-oriented proof tactics in Standard.

## 100.14 subst / generalize

Selected context-rewriting proof tactics.

## 100.15 rcases / rintro / obtain / use

Selected structured proof/destructuring tactics.

## 100.16 ext

Selected extensionality proof tactic.

## 100.17 decide

Selected proof-by-decision tactic where a decidable proposition is available.

## 100.18 omega / grind

Selected Standard prover automation.

Their success must still yield acceptable proof evidence.

---

# 101. classical

~~~proofscript
theorem excludedMiddle(P: Prop): P ∨ ¬P := by {
  classical
  by_cases h : P
  · exact Or.inl h
  · exact Or.inr h
}
~~~

Classical proof mode affects proof construction/assumption use according to the selected logical foundation.

---

# 102. Attributes

Fixed Standard attributes:

~~~text
simp
instance
default_instance
inline
macro_inline
reducible
irreducible
deprecated
inherit_doc
pp_nodot
~~~

Declaration attribute:

~~~proofscript
@[simp]
theorem addZero(n: Nat): n + 0 = n := by {
  simp
}
~~~

Attribute command:

~~~proofscript
attribute [simp] someTheorem
~~~

Ordinary dependencies cannot register new Standard attribute handlers.

---

# 103. set_option

~~~proofscript
set_option selectedOption value
~~~

Only options selected by the exact Standard registration closure are accepted.

Unknown/unselected options reject.

Options may affect selected source-observable elaboration/diagnostic behavior but do not independently change the logical theory.

---

# 104. Notation policy

Standard notation is fixed by the Standard registration closure.

Ordinary dependencies cannot add:

~~~text
notation
infix
infixl
infixr
prefix
postfix
~~~

to <code>ps-standard</code> source.

The extensible profile may explicitly declare such extensions.

---

# 105. Equality operator policy

Proposition equality:

~~~proofscript
x = y
~~~

Boolean equality:

~~~proofscript
x == y
~~~

The meanings remain distinct.

---

# 106. Tooling commands

Tooling-profile commands include:

~~~proofscript
#check foo
#print foo
#reduce expr
#eval expr
~~~

These are not <code>psc2-language-v1</code> program declarations.

They are development/tooling operations.

---

# 107. Pure contracts

The base PSC2 contract surface applies to total pure functions.

## 107.1 requires

~~~proofscript
function debit(balance: Nat, amount: Nat): Except String Nat
  requires amount <= balance
:= {
  .ok(balance - amount)
}
~~~

A precondition is a proposition about the call inputs.

## 107.2 ensures

~~~proofscript
function debit(balance: Nat, amount: Nat): Except String Nat
  requires amount <= balance
  ensures result =>
    match result with {
      | .ok next => next = balance - amount
      | .error _ => False
    }
:= {
  .ok(balance - amount)
}
~~~

## 107.3 Grammar

~~~ebnf
ContractClause :=
    "requires" PSTerm
  | "ensures" Ident "=>" PSTerm

ContractedFunction :=
  FunctionHeader ContractClause* DefinitionBody
~~~

## 107.4 Semantics

For a function conceptually:

~~~text
f : A -> B
~~~

with:

~~~text
requires Pre
ensures result => Post
~~~

the proof obligation is conceptually:

~~~text
forall x : A,
  Pre(x) ->
  Post(x, f(x))
~~~

for the real binder structure.

## 107.5 Multiple clauses

Multiple preconditions conjoin.

Multiple postconditions conjoin.

No <code>requires</code> means <code>True</code> precondition.

No <code>ensures</code> means no functional postcondition claim.

## 107.6 What contracts do not mean

A contract is not automatically:

- runtime validation;
- a JavaScript assertion;
- proof of foreign code behavior;
- proof of backend/compiler correctness.

---

# 108. Contract syntax not in current r3

Not current PSC2 syntax:

~~~text
assert
loop invariant
old
ghost
stateful postcondition syntax
effectful postcondition syntax
async/trace contracts
~~~

These are Post-PSC2 verification-language candidates.

---

# 109. Standard libraries vs language features

A capability can be part of the PSC2 user experience without being compiler-core syntax.

Typical library-owned families include:

- collections;
- codecs;
- parsers;
- application effects;
- resources;
- streams;
- theorem libraries;
- proof libraries;
- foreign-interface wrappers.

A library can add:

- types;
- functions;
- theorems;
- instances;
- data.

It cannot mutate Standard grammar.

---

# 110. lean-subset-psc2-v1

The PSC2 <code>.lean</code> frontend must accept native Lean spellings corresponding to the supported PSC2 semantic families where an exact mapping exists.

Required families include:

- <code>def</code>;
- <code>theorem</code>;
- <code>example</code>;
- <code>abbrev</code>;
- <code>opaque</code>;
- <code>axiom</code>;
- supported declaration modifiers;
- explicit/implicit/strict-implicit/instance binders;
- selected universe syntax;
- structures/classes/instances;
- inductives/constructors/projections;
- records/update;
- lambdas;
- lets;
- applications;
- literals;
- conditionals;
- match;
- <code>psc2-pattern-v1</code>;
- basic <code>do</code>;
- structural/local/mutual recursion;
- partial/noncomputable boundaries;
- selected propositions/equality/primitives;
- selected proof source.

Excluded unless a later compatibility profile says otherwise:

- arbitrary <code>syntax</code>;
- <code>macro</code>;
- <code>macro_rules</code>;
- <code>declare_syntax_cat</code>;
- arbitrary notation declarations;
- arbitrary parser extensions;
- arbitrary term/command/tactic elaborators;
- unrestricted quotations/metaprogramming;
- arbitrary environment extensions;
- unsupported commands/attributes;
- arbitrary deriving handlers;
- arbitrary Lean compiler intrinsics;
- unsupported termination/compiler extensions.

Unsupported Lean source must reject explicitly.

---

# 111. ProofScript Standard forbidden dynamic syntax heads

The Standard registry forbids ordinary source from dynamically introducing:

~~~text
syntax
macro
macro_rules
elab
elab_rules
declare_syntax_cat
notation
infix
infixl
infixr
prefix
postfix
~~~

Quotation/Meta authoring is not Standard source.

Use the extensible profile for explicitly declared language extensions.

---

# 112. Exact current owned grammar

The following is the consolidated ProofScript-owned r3 grammar.

Native categories such as <code>PSTerm</code>, <code>PatternGroup</code>, <code>BinderIdent</code>, <code>StructField</code>, <code>ClassField</code>, <code>ConstructorBody</code>, <code>InstanceField</code>, and <code>WhereField</code> denote selected pinned native categories restricted by the active profile.

~~~ebnf
DefaultSuffix :=
  ":=" PSTerm

ExplicitGroup :=
  "(" ExplicitEntry ("," ExplicitEntry)* ","? ")"

EmptyExplicitGroup :=
  "(" ")"

ExplicitEntry :=
  BinderIdent ":" PSTerm DefaultSuffix?

FunctionHeader :=
  "function"
  Ident
  NativeNonExplicitBinder*
  (ExplicitGroup | EmptyExplicitGroup)
  (":" PSTerm)?

DefinitionBody :=
  ":=" (PSTerm | BracedDefinitionBody)

BracedDefinitionBody :=
  "{" PSTerm "}"

CallArguments :=
  CallArgument ("," CallArgument)* ","?

CallArgument :=
    NamedCallArgument
  | PSTerm

NamedCallArgument :=
  Ident ":=" PSTerm

ParenthesizedCall :=
  CallableHead CallGap "(" CallArguments? ")"

StructBody :=
  "{" (StructField ("," StructField)*)? "}"

ClassBody :=
  "{" (ClassField ("," ClassField)*)? "}"

InductiveBody :=
  "{" ("|" ConstructorBody)* "}"

MatchBody :=
  "{" ("|" PatternGroup "=>" PSTerm)+ "}"

InstanceBody :=
  "{" (InstanceField (";" InstanceField)* ";"?)? "}"

WhereBody :=
  "{" WhereField (";" WhereField)* ";"? "}"

BracedIf :=
  "if" "(" PSTerm ")" "{" PSTerm "}"
  "else" "{" PSTerm "}"

ContractClause :=
    "requires" PSTerm
  | "ensures" Ident "=>" PSTerm
~~~

---

# 113. Separator matrix

| Category | Separator/boundary | Trailing separator |
|---|---|---|
| explicit parameter group | comma | allowed |
| nonempty parenthesized call | comma | allowed |
| braced def/const/function body | exactly one PSTerm | not applicable |
| structure fields | comma | rejected |
| class fields | comma | rejected |
| inductive constructors | leading bar | not applicable |
| match alternatives | leading bar | not applicable |
| instance fields | native semicolon | allowed |
| local where declarations | native semicolon | allowed |
| do/tactic sequences | selected native rule | selected native rule |

There is no universal ProofScript semicolon rule.

---

# 114. Canonical syntax examples

## 114.1 Constants

~~~proofscript
const answer: Nat := {
  42
}
~~~

## 114.2 Functions

~~~proofscript
function add(x: Nat, y: Nat): Nat := {
  x + y
}
~~~

## 114.3 Generic function

~~~proofscript
function id {α: Type}(x: α): α := {
  x
}
~~~

## 114.4 Default argument

~~~proofscript
function greet(name: String := "world"): String := {
  "Hello, " ++ name
}
~~~

## 114.5 Zero-source-argument function

~~~proofscript
function now(): Time := {
  clockValue
}
~~~

## 114.6 Structure

~~~proofscript
structure User where {
  id: Nat,
  name: String,
  active: Bool
}
~~~

## 114.7 Record value

~~~proofscript
const user: User := {
  id := 1,
  name := "Alice",
  active := false
}
~~~

## 114.8 Record update

~~~proofscript
function activate(user: User): User := {
  { user with active := true }
}
~~~

## 114.9 Inductive

~~~proofscript
inductive Result(ε: Type, α: Type) where {
  | ok(value: α)
  | error(error: ε)
}
~~~

## 114.10 Match

~~~proofscript
function getOrElse(value: Option Nat, fallback: Nat): Nat := {
  match value with {
    | .none => fallback
    | .some x => x
  }
}
~~~

## 114.11 Class

~~~proofscript
class Sized(α: Type) where {
  size: α -> Nat
}
~~~

## 114.12 Instance

~~~proofscript
instance : Sized String where {
  size(s: String): Nat := s.length;
}
~~~

## 114.13 Theorem

~~~proofscript
theorem addZero(n: Nat): n + 0 = n := by {
  simp
}
~~~

## 114.14 Do

~~~proofscript
function load(): CompilerM Nat := do {
  let x ← readValue
  pure (x + 1)
}
~~~

## 114.15 Contract

~~~proofscript
function debit(balance: Nat, amount: Nat): Except String Nat
  requires amount <= balance
  ensures result =>
    match result with {
      | .ok next => next = balance - amount
      | .error _ => False
    }
:= {
  .ok(balance - amount)
}
~~~

---

# 115. Rejection examples

## 115.1 Required explicit parameter omitted

~~~proofscript
function add1(x: Nat): Nat := {
  x + 1
}

add1() -- reject
~~~

## 115.2 Invalid zero-argument placement

~~~proofscript
function bad()(x: Nat): Nat := x
function bad(x: Nat)(): Nat := x
~~~

Reject.

## 115.3 Structure trailing comma

~~~proofscript
structure User where {
  id: Nat,
  name: String,
}
~~~

Reject.

## 115.4 Two unrelated terms inside definition-body wrapper

~~~proofscript
function bad(): Nat := {
  1
  2
}
~~~

Reject as a one-term wrapper.

## 115.5 Dynamic Standard syntax registration

~~~proofscript
syntax "something" : term
~~~

Reject in <code>ps-standard</code>.

## 115.6 Unsafe Standard source

~~~proofscript
unsafe def x := ...
~~~

Reject under <code>psc2-language-v1</code>/<code>ps-standard</code>.

---

# 116. Features deliberately not in PSC2 core

The following are intentionally not required by <code>psc2-language-v1</code>:

- multi-scrutinee match;
- generalized pattern alternatives;
- equation-style function definition sugar;
- <code>if let</code> convenience;
- rich let/do pattern sugar;
- <code>let mut</code>;
- reassignment;
- <code>for</code>;
- <code>while</code>;
- <code>break</code>;
- <code>continue</code>;
- arbitrary Lean syntax/macros/elaborators;
- arbitrary quotation/Meta source;
- custom parser categories;
- arbitrary user attribute handlers;
- general deriving framework;
- arbitrary full Lean well-founded-recursion elaboration;
- <code>async</code>;
- <code>await</code>;
- <code>using</code>;
- <code>defer</code>;
- JSX/UI syntax;
- stateful/loop/async contract sugar.

Their absence is intentional, not an implicit promise to emulate all Lean or TypeScript syntax.

---

# 117. Post-PSC2 language candidates

## 117.1 Rich matching

Candidates:

- multi-scrutinee match;
- pattern alternatives;
- record patterns;
- if-let;
- let-pattern;
- do-pattern;
- equation-style definitions.

## 117.2 Imperative-looking local control

Candidates:

- let mut;
- assignment;
- for;
- while;
- break;
- continue.

These must lower to explicit owned state/effect/iteration semantics rather than import JavaScript mutation rules.

## 117.3 Rich verification syntax

Candidates:

- assert;
- invariant;
- decreasing convenience;
- old/pre-state;
- ghost;
- modifies/frame clauses;
- effectful/async postconditions.

## 117.4 Application-effect syntax

Candidates:

- async;
- await;
- using;
- defer;
- structured concurrency sugar;
- stream iteration sugar.

## 117.5 Controlled extension syntax

Candidates:

- official deriving;
- additional fixed notation families;
- controlled compile-time reflection;
- official macro-like conveniences.

## 117.6 UI dialect

A future <code>.psx</code> or other UI profile would need a separate grammar/profile identity.

---

# 118. Explicit JavaScript/TypeScript semantics not imported

Current ProofScript does not define:

- JavaScript truthiness;
- implicit null/undefined;
- native any;
- prototype inheritance as native object semantics;
- arbitrary dynamic property lookup as field semantics;
- JavaScript automatic semicolon insertion;
- JavaScript statement function blocks;
- TypeScript structural assignability as the native type system;
- TypeScript arrow-lambda syntax as base syntax;
- optional chaining as base syntax;
- Promise as the definition of async semantics;
- automatic JSX.

---

# 119. Feature ownership rule

For future design, prefer:

~~~text
ordinary library
  before
new language syntax

proof-producing prover/library
  before
kernel growth

official syntax sugar
  before
new core semantic constructs

controlled extension profile
  before
open Standard grammar

FFI/host boundary
  for target-specific behavior
~~~

A feature is not a compiler-core language feature merely because Lean or TypeScript has a similar feature.

---

# 120. Final PSC2 language boundary

The current PSC2 language is complete when every relevant capability is one of:

1. directly defined in the normative r3 language;
2. explicitly inherited from the pinned native Lean semantic categories;
3. selected in the closed Standard language profile;
4. assigned to the extensible profile;
5. assigned to a library/prover/tooling/interop layer;
6. listed as Post-PSC2 language work;
7. explicitly excluded.

The intended PSC2 result is:

~~~text
small predictable application-facing syntax
+
Lean-compatible dependent semantics
+
kernel-checkable proof terms
+
closed Standard grammar
+
fixed Standard prover surface
+
libraries and controlled extensions above the core
~~~
