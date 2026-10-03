# Lean 4 vs ProofScript PSC2 vs TypeScript — Complete Language Feature Comparison

**Status:** non-normative comparison/reference guide  
**ProofScript authority:** <code>ProofScript_Language_Reference_v0.9.0_r3.md</code>  
**ProofScript edition:** <code>ps-0.9-r3</code>  
**PSC2 language closure:** <code>psc2-language-v1</code>  
**PSC2 Standard language profile:** <code>psc2-standard-language-v1</code>  
**Lean compatibility profile:** <code>lean-subset-psc2-v1</code>  
**Pattern profile:** <code>psc2-pattern-v1</code>  
**Lean semantic pin used by ProofScript:** Lean 4.34.0, commit <code>293d5d0c0c3f3dded4688b3ccd6a33939ac5102b</code>

This document compares every current PSC2 language-family requirement and every current Standard proof/syntax selection against:

1. native Lean 4 syntax/semantics;
2. current ProofScript r3 syntax/semantics;
3. the closest TypeScript syntax or concept.

The ProofScript column is normative only insofar as it restates the current r3 language reference. The Lean and TypeScript columns are explanatory comparisons. A visually similar TypeScript construct is **not** assumed to have Lean/ProofScript semantics.

---

# 1. Reading conventions

| Marking | Meaning |
|---|---|
| **same semantics** | ProofScript intentionally uses the pinned Lean-compatible meaning |
| **surface alias/sugar** | ProofScript syntax lowers to an already-existing semantic construct |
| **closest TS analogue** | Similar programming purpose or appearance, but not semantically equivalent |
| **no TS equivalent** | TypeScript has no proof/type-theoretic counterpart |
| **not PSC2 core** | Lean or TypeScript may have it, but <code>psc2-language-v1</code> does not require it |
| **Post-PSC2** | Candidate for a later language/profile revision |
| **Standard-only selection** | In <code>psc2-standard-language-v1</code>, but not a new core logical construct |

The central semantic relationship is:

~~~text
Lean 4:
  rich dependent language + theorem prover + extensible frontend

ProofScript:
  Lean-compatible logical semantics
  + smaller closed Standard source profile
  + TypeScript-friendly application syntax
  + controlled extensibility

TypeScript:
  JavaScript runtime semantics
  + structural static type checking
  + JS/npm ecosystem
~~~

---

# 2. High-level capability matrix

| Area | Lean 4 | ProofScript PSC2 | TypeScript |
|---|---|---|---|
| Dependent types | yes | yes, Lean-compatible | no genuine dependent types |
| Prop / proofs as terms | yes | yes | no |
| Kernel-checked theorems | yes | yes | no |
| Universes | yes | yes | no |
| Inductive families | yes | yes | discriminated unions are only an analogue |
| Pattern matching | very rich | bounded <code>psc2-pattern-v1</code> | switch/narrowing/destructuring |
| Typeclasses | yes | yes, bounded ordinary synthesis | no built-in typeclass synthesis |
| Coercions | elaborator/typeclass-driven | Lean-compatible selected subset | structural assignability/conversion rules, not equivalent |
| Structural typing | not TS-style | not TS-style | yes |
| Null/undefined as ambient absence | no | no | yes |
| Native any | no | no | yes |
| Macros/custom syntax | extensive | Standard: no; Extensible: explicit | no ordinary library grammar extension |
| Theorem tactics | extensive | fixed Standard prover + extensions/plugins | none |
| General statement blocks | no | no | yes |
| JS/npm ecosystem | secondary | explicit interop target | native ecosystem |
| Async keywords | Lean-specific facilities | not current PSC2 syntax | async/await |
| Contracts | propositions/theorems/libraries | native pure requires/ensures surface | no proof-level equivalent |

---

# 3. Source kinds and profiles

## 3.1 Source files

| Lean 4 | ProofScript | TypeScript |
|---|---|---|
| <code>.lean</code> | <code>.ps</code> | <code>.ts</code> |
| native full Lean frontend | default <code>ps-standard-0.9-r3</code> | fixed TypeScript grammar |
| highly extensible | closed Standard grammar | libraries do not change grammar |

ProofScript can also intentionally consume a bounded <code>.lean</code> source subset:

~~~text
lean-subset-psc2-v1
~~~

It does **not** imply full Lean source compatibility.

## 3.2 Standard vs extensible grammar

| Capability | Lean 4 | ProofScript Standard | ProofScript Extensible | TypeScript |
|---|---|---|---|---|
| package adds notation | yes | no | explicitly permitted/profile-bound | no |
| package adds syntax | yes | no | explicitly permitted/profile-bound | no |
| custom elaborator | yes | no | explicitly permitted/profile-bound | no direct equivalent |
| custom tactic syntax | yes | no dependency mutation | explicitly permitted/profile-bound | none |
| parser categories | extensible | fixed | explicit extension | fixed |

ProofScript profile names:

~~~text
ps-standard-0.9-r3
ps-lean-extensible-0.9-r3
psc2-language-v1
psc2-standard-language-v1
lean-subset-psc2-v1
psc2-pattern-v1
~~~

---

# 4. Lexical rules, whitespace, comments, and CallGap

## 4.1 Ordinary comments/whitespace

ProofScript inherits the selected Lean-native lexical categories except where an owned PSC rule overrides them.

TypeScript follows ECMAScript/TypeScript lexical rules.

## 4.2 Parenthesized-call CallGap

Lean application normally uses whitespace juxtaposition:

~~~lean
f x
f x y
~~~

ProofScript owns parenthesized calls:

~~~proofscript
f(x)
f (x)
f /* comment */ (x)
~~~

All three above are one ProofScript parenthesized call.

A bare physical line break between the completed callable head and opening parenthesis breaks that PSC-owned call relation:

~~~proofscript
f
(x)
~~~

This is **not** one r3 parenthesized call.

TypeScript normally writes:

~~~ts
f(x)
f (x)
~~~

but has no PSC-style semantic concept named CallGap.

### ProofScript conceptual grammar

~~~ebnf
ParenthesizedCall :=
  CallableHead CallGap "(" CallArguments? ")"
~~~

CallGap allows horizontal inherited space/comments without a physical line terminator.

---

# 5. Modules, names, namespaces, sections, and visibility

## 5.1 Imports

| Lean 4 | ProofScript | TypeScript |
|---|---|---|
| <code>import Foo.Bar</code> | <code>import Foo.Bar</code> | <code>import { x } from "./foo.js"</code> |

ProofScript imports do not permit dependencies to mutate Standard grammar.

## 5.2 Qualified names

~~~lean
Foo.Bar.value
~~~

~~~proofscript
Foo.Bar.value
~~~

~~~ts
Foo.Bar.value
~~~

The spelling can look similar while module/name resolution rules differ.

## 5.3 Namespaces

Lean:

~~~lean
namespace Math

def answer : Nat := 42

end Math
~~~

ProofScript:

~~~proofscript
namespace Math

const answer: Nat := {
  42
}

end Math
~~~

TypeScript:

~~~ts
namespace Math {
  export const answer: number = 42;
}
~~~

The TypeScript namespace is only a closest organizational analogue.

## 5.4 Sections and shared variables

Lean:

~~~lean
section

variable {α : Type}

def id (x : α) : α := x

end
~~~

ProofScript supports the corresponding selected native source family:

~~~proofscript
section

variable {α: Type}

function id(x: α): α := {
  x
}

end
~~~

TypeScript has no section/shared-implicit-variable language feature.

## 5.5 open

Lean:

~~~lean
open List
~~~

ProofScript:

~~~proofscript
open List
~~~

TypeScript has no exact equivalent; imports or qualified names are used.

## 5.6 include / omit

Lean:

~~~lean
section
variable {α : Type}
variable (x : α)

include x
-- declarations here may force x into generated declaration dependencies

omit x
-- declarations here may omit it when otherwise unused

end
~~~

ProofScript uses the selected native family:

~~~proofscript
section
variable {α: Type}
variable (x: α)

include x
-- supported declaration source

omit x

end
~~~

TypeScript has no equivalent section-variable dependency-control command.

## 5.7 universe declarations

Lean:

~~~lean
universe u v
~~~

ProofScript:

~~~proofscript
universe u v
~~~

TypeScript has no universe hierarchy.

## 5.8 private

Lean:

~~~lean
private def helper : Nat := 1
~~~

ProofScript:

~~~proofscript
private def helper(): Nat := {
  1
}
~~~

TypeScript closest forms include non-exported module bindings and class <code>private</code>, but these do not have the same declaration-identity semantics.

---

# 6. Definitions: def, const, function

## 6.1 def

Lean:

~~~lean
def double (n : Nat) : Nat :=
  n + n
~~~

ProofScript accepted variants:

~~~proofscript
def double(n: Nat): Nat :=
  n + n
~~~

~~~proofscript
def double(n: Nat): Nat := {
  n + n
}
~~~

TypeScript closest declaration:

~~~ts
function double(n: number): number {
  return n + n;
}
~~~

ProofScript braced and unbraced bodies are exactly equivalent.

## 6.2 const

Lean has no need for a distinct constant-binding keyword; the natural equivalent is a parameterless <code>def</code>:

~~~lean
def answer : Nat := 42
~~~

ProofScript accepted variants:

~~~proofscript
const answer: Nat := 42
~~~

~~~proofscript
const answer: Nat := {
  42
}
~~~

TypeScript:

~~~ts
const answer: number = 42;
~~~

ProofScript <code>const</code> means a parameterless logical definition. It does **not** mean JavaScript/TypeScript binding immutability.

## 6.3 function

Lean:

~~~lean
def add (x : Nat) (y : Nat) : Nat :=
  x + y
~~~

ProofScript accepted variants:

~~~proofscript
function add(x: Nat, y: Nat): Nat :=
  x + y
~~~

~~~proofscript
function add(x: Nat, y: Nat): Nat := {
  x + y
}
~~~

TypeScript:

~~~ts
function add(x: number, y: number): number {
  return x + y;
}
~~~

ProofScript core semantics remain curried/dependent functions even though the surface parameter/call syntax is TypeScript-like.

---

# 7. Braced definition-body variants

This is an owned r3 feature:

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
=
:= { term }
~~~

The braces:

- contain exactly one <code>PSTerm</code>;
- are not a statement block;
- do not imply return;
- do not create JavaScript scope semantics;
- do not create sequencing.

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

Invalid purely because braces do not sequence unrelated expressions:

~~~proofscript
function invalid(): Nat := {
  1
  2
}
~~~

## 7.1 Direct record body vs wrapped record body

Direct record term:

~~~proofscript
const user: User := {
  id := 1,
  name := "Alice"
}
~~~

Explicit single-term wrapper containing a record term:

~~~proofscript
const user: User := {
  {
    id := 1,
    name := "Alice"
  }
}
~~~

Both have the same value meaning.

This distinction has no direct Lean or TypeScript counterpart; it exists to preserve deterministic ownership of already-braced PSC terms.

---

# 8. theorem, example, abbrev, opaque, axiom

## 8.1 theorem

Lean:

~~~lean
theorem addZero (n : Nat) : n + 0 = n := by
  simp
~~~

ProofScript:

~~~proofscript
theorem addZero(n: Nat): n + 0 = n := by {
  simp
}
~~~

TypeScript: no theorem declaration exists.

A test such as:

~~~ts
expect(add(n, 0)).toBe(n);
~~~

is runtime/test evidence, not a proof term.

## 8.2 example

Lean:

~~~lean
example : 1 + 1 = 2 := by
  rfl
~~~

ProofScript accepts the corresponding native checking family:

~~~proofscript
example : 1 + 1 = 2 := by {
  rfl
}
~~~

TypeScript has no equivalent.

## 8.3 abbrev

Lean:

~~~lean
abbrev UserId := Nat
~~~

ProofScript:

~~~proofscript
abbrev UserId := Nat
~~~

TypeScript closest:

~~~ts
type UserId = number;
~~~

But TypeScript aliases do not have Lean definitional/transparency semantics.

## 8.4 opaque

Lean:

~~~lean
opaque hiddenValue : Nat := 42
~~~

ProofScript:

~~~proofscript
opaque hiddenValue: Nat := 42
~~~

TypeScript has no definitional-equality/opacity equivalent.

## 8.5 axiom

Lean:

~~~lean
axiom externalLaw : P
~~~

ProofScript:

~~~proofscript
axiom externalLaw : P
~~~

TypeScript has no proposition-level axiom mechanism.

A declaration file or type assertion is not equivalent to a logical axiom.

---

# 9. Declaration modifiers: partial, noncomputable, unsafe

## 9.1 partial

Lean:

~~~lean
partial def loop (n : Nat) : Nat :=
  loop n
~~~

ProofScript:

~~~proofscript
partial def loop(n: Nat): Nat := {
  loop(n)
}
~~~

TypeScript:

~~~ts
function loop(n: number): number {
  return loop(n);
}
~~~

TypeScript has no totality/proof distinction.

## 9.2 noncomputable

Lean:

~~~lean
noncomputable def chooseValue : α := ...
~~~

ProofScript:

~~~proofscript
noncomputable def chooseValue(): α := {
  ...
}
~~~

TypeScript has no corresponding logical/executable distinction.

## 9.3 unsafe

Lean supports <code>unsafe</code> declarations.

ProofScript:

~~~text
unsafe is excluded from:
  psc2-language-v1
  ps-standard-0.9-r3
~~~

An explicit extensible/host profile may define a separate unsafe boundary.

TypeScript has no equivalent proof-authority boundary; <code>any</code> and assertions weaken static checking but are conceptually different.

---

# 10. Local where declarations

Lean:

~~~lean
def incrementTwice (x : Nat) : Nat :=
  helper (helper x)
where
  helper (n : Nat) : Nat := n + 1
~~~

ProofScript brace variant:

~~~proofscript
function incrementTwice(x: Nat): Nat := {
  helper(helper(x))
}
where {
  function helper(n: Nat): Nat := { n + 1 };
}
~~~

Conceptual ProofScript grammar:

~~~ebnf
WhereBody :=
  "{" WhereField (";" WhereField)* ";"? "}"
~~~

TypeScript closest equivalent is a nested function:

~~~ts
function incrementTwice(x: number): number {
  function helper(n: number): number {
    return n + 1;
  }
  return helper(helper(x));
}
~~~

The syntax and scoping mechanisms are not identical.

---

# 11. Binders

## 11.1 Explicit binders

Lean:

~~~lean
(x : Nat)
~~~

ProofScript:

~~~proofscript
(x: Nat)
~~~

TypeScript:

~~~ts
(x: number)
~~~

ProofScript explicit-group grammar:

~~~ebnf
ExplicitGroup :=
  "(" ExplicitEntry ("," ExplicitEntry)* ","? ")"

ExplicitEntry :=
  BinderIdent ":" PSTerm DefaultSuffix?
~~~

## 11.2 Implicit binders

Lean:

~~~lean
{α : Type}
~~~

ProofScript:

~~~proofscript
{α: Type}
~~~

TypeScript closest generic parameter:

~~~ts
<T>
~~~

The TypeScript form is not an implicit dependent binder.

## 11.3 Strict implicit binders

Lean:

~~~lean
{{α : Type}}
~~~

or the corresponding Unicode strict-implicit delimiter.

ProofScript includes the selected native strict-implicit binder semantics.

TypeScript: no equivalent.

## 11.4 Instance binders

Lean:

~~~lean
[Ord α]
~~~

ProofScript:

~~~proofscript
[Ord α]
~~~

TypeScript closest explicit dictionary argument:

~~~ts
(ord: Ord<T>)
~~~

TypeScript has no built-in instance synthesis.

## 11.5 Default parameter suffix

ProofScript grammar:

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

TypeScript:

~~~ts
function greet(name: string = "world"): string {
  return "Hello, " + name;
}
~~~

Lean optional/default parameters use native optional-parameter mechanisms.

## 11.6 Trailing explicit-parameter comma

ProofScript:

~~~proofscript
function add(
  x: Nat,
  y: Nat,
): Nat := {
  x + y
}
~~~

Allowed.

TypeScript also permits trailing parameter commas in ordinary function declarations.

Lean's ordinary binder lists are not comma-separated in the same way.

---

# 12. Zero-source-argument functions

Lean-style semantic expansion:

~~~lean
def now (_unit : Unit := ()) : Time :=
  clockValue
~~~

ProofScript:

~~~proofscript
function now(): Time := {
  clockValue
}
~~~

Conceptual equivalence:

~~~text
function f(): R
≈
def f (_unit : Unit := ()) : R
~~~

TypeScript:

~~~ts
function now(): Time {
  return clockValue;
}
~~~

TypeScript's function is genuinely a zero-parameter JavaScript function. ProofScript preserves the selected Lean-compatible core function model.

Rejected ProofScript forms:

~~~proofscript
function bad()(x: Nat): Nat := x
function bad(x: Nat)(): Nat := x
~~~

---

# 13. Lambdas and function types

## 13.1 Lambda

Lean:

~~~lean
fun x => x + 1
~~~

ProofScript:

~~~proofscript
fun x => x + 1
~~~

TypeScript:

~~~ts
x => x + 1
~~~

TypeScript arrow-lambda syntax is **not** current base ProofScript syntax.

## 13.2 Curried function model

Lean:

~~~lean
Nat → Nat → Nat
~~~

ProofScript:

~~~proofscript
Nat -> Nat -> Nat
~~~

TypeScript closest type:

~~~ts
(x: number, y: number) => number
~~~

or explicitly curried:

~~~ts
(x: number) => (y: number) => number
~~~

ProofScript multi-parameter surface syntax still elaborates into Lean-compatible ordered binders.

## 13.3 Dependent function / Pi type

Lean:

~~~lean
(n : Nat) → Fin n → Nat
~~~

ProofScript:

~~~proofscript
(n: Nat) -> Fin n -> Nat
~~~

TypeScript has no genuine dependent function type where a runtime/value-level <code>n</code> determines a later parameter's type.

---

# 14. let

Lean:

~~~lean
let x := 10
x + 1
~~~

ProofScript:

~~~proofscript
let x := 10
x + 1
~~~

TypeScript:

~~~ts
const x = 10;
return x + 1;
~~~

A ProofScript/Lean <code>let</code> is an expression binding; it does not imply mutable storage.

---

# 15. Function application

## 15.1 Lean juxtaposition

~~~lean
add 1 2
~~~

## 15.2 ProofScript parenthesized application

~~~proofscript
add(1, 2)
~~~

Also valid under CallGap:

~~~proofscript
add (1, 2)
~~~

TypeScript:

~~~ts
add(1, 2)
~~~

Same visual call syntax does not imply the same type theory or runtime model.

## 15.3 ProofScript grammar

~~~ebnf
CallArguments :=
  CallArgument ("," CallArgument)* ","?

CallArgument :=
    NamedCallArgument
  | PSTerm

NamedCallArgument :=
  Ident ":=" PSTerm
~~~

---

# 16. Named arguments

Lean:

~~~lean
connect (host := "localhost") (timeout := 5000)
~~~

ProofScript:

~~~proofscript
connect(host := "localhost", timeout := 5000)
~~~

TypeScript has no native named-argument syntax. Closest idiom:

~~~ts
connect({ host: "localhost", timeout: 5000 });
~~~

That is an object argument, not named application.

---

# 17. Default arguments and empty calls

ProofScript:

~~~proofscript
function greet(name: String := "world"): String := {
  "Hello, " ++ name
}

greet()
~~~

Accepted because the omitted explicit parameter is defaultable.

Rejected:

~~~proofscript
function add1(x: Nat): Nat := {
  x + 1
}

add1()
~~~

because <code>x</code> is an ordinary required explicit parameter.

TypeScript similarly statically rejects omitted required parameters:

~~~ts
function add1(x: number): number {
  return x + 1;
}

add1(); // type error
~~~

Lean uses native high-level application/default/automatic/implicit insertion semantics.

---

# 18. Call trailing commas

ProofScript:

~~~proofscript
f(
  x,
  y,
)
~~~

Valid.

Grammar:

~~~ebnf
CallArguments :=
  CallArgument ("," CallArgument)* ","?
~~~

TypeScript also accepts trailing commas in ordinary multiline argument lists.

Lean normal whitespace application does not use this comma-list syntax.

---

# 19. Tuples/products

Lean:

~~~lean
(1, 2)
~~~

ProofScript:

~~~proofscript
(1, 2)
~~~

Calling with one tuple argument requires explicit inner grouping:

~~~proofscript
tupled((1, 2))
~~~

TypeScript tuple value:

~~~ts
const pair: [number, number] = [1, 2];
tupled(pair);
~~~

ProofScript's tuple/product family follows Lean-compatible product semantics.

---

# 20. Parenthesized terms and type ascription

Lean:

~~~lean
(x)
(x : Nat)
~~~

ProofScript:

~~~proofscript
(x)
(x : Nat)
~~~

TypeScript closest forms:

~~~ts
(x)
x as number
~~~

A TypeScript assertion is not semantically equivalent to Lean/PSC type ascription.

---

# 21. if

Lean native:

~~~lean
if condition then
  yes
else
  no
~~~

ProofScript native-compatible form may exist through selected native categories; r3 also owns a braced form:

~~~proofscript
if (condition) {
  yes
} else {
  no
}
~~~

Grammar:

~~~ebnf
BracedIf :=
  "if" "(" PSTerm ")" "{" PSTerm "}"
  "else" "{" PSTerm "}"
~~~

Each branch is one term.

TypeScript:

~~~ts
if (condition) {
  return yes;
} else {
  return no;
}
~~~

TypeScript braces are statement blocks; ProofScript braces here are single-term branches.

---

# 22. Structures

Lean:

~~~lean
structure User where
  id : Nat
  name : String
  active : Bool
~~~

ProofScript canonical owned form:

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

No trailing structure-field comma.

TypeScript closest:

~~~ts
interface User {
  id: number;
  name: string;
  active: boolean;
}
~~~

TypeScript interface compatibility is structural; ProofScript structures retain Lean-compatible logical/declaration identity.

---

# 23. Classes/typeclasses

Lean:

~~~lean
class Sized (α : Type) where
  size : α → Nat
~~~

ProofScript:

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

TypeScript closest shape declaration:

~~~ts
interface Sized<T> {
  size(value: T): number;
}
~~~

This is not a typeclass system.

---

# 24. Instances

Lean:

~~~lean
instance : Sized String where
  size s := s.length
~~~

ProofScript:

~~~proofscript
instance : Sized String where {
  size(s: String): Nat := s.length;
}
~~~

ProofScript conceptual body grammar:

~~~ebnf
InstanceBody :=
  "{" (InstanceField (";" InstanceField)* ";"?)? "}"
~~~

TypeScript requires explicit values:

~~~ts
const sizedString: Sized<string> = {
  size: s => s.length,
};
~~~

There is no automatic instance synthesis.

---

# 25. Typeclass search

Lean resolves instance implicit parameters by typeclass synthesis.

ProofScript <code>psc2-language-v1</code> includes ordinary global/local instance search required by the selected subset.

Example:

~~~proofscript
function compareValues {α: Type}[Ord α](x: α, y: α): Ordering := {
  compare(x, y)
}
~~~

Closest TypeScript:

~~~ts
function compareValues<T>(
  ord: Ord<T>,
  x: T,
  y: T
): Ordering {
  return ord.compare(x, y);
}
~~~

The TypeScript dictionary is explicit; it is not synthesized by the language.

---

# 26. Coercions

Lean has type-directed/elaboration-driven coercions.

ProofScript permits only selected Lean-compatible coercion insertion.

TypeScript's assignability and contextual typing are only loose analogues and must not be treated as PSC coercion semantics.

ProofScript explicitly rejects importing JavaScript implicit conversion semantics into native code.

---

# 27. Record construction

Lean:

~~~lean
{ id := 1, name := "Alice", active := true }
~~~

ProofScript:

~~~proofscript
const user: User := {
  id := 1,
  name := "Alice",
  active := true
}
~~~

TypeScript:

~~~ts
const user: User = {
  id: 1,
  name: "Alice",
  active: true,
};
~~~

The visual resemblance does not make ProofScript records structurally typed JavaScript objects.

---

# 28. Record update

Lean:

~~~lean
{ user with active := true }
~~~

ProofScript:

~~~proofscript
{ user with active := true }
~~~

TypeScript closest:

~~~ts
{ ...user, active: true }
~~~

ProofScript update means selected constructor/projection structure-update semantics, not JS spread/property-descriptor semantics.

---

# 29. Generalized field notation / method-style calls

Lean:

~~~lean
xs.map f
~~~

ProofScript:

~~~proofscript
users.map(toName)
~~~

The notation is static/type-directed.

TypeScript:

~~~ts
users.map(toName)
~~~

In TypeScript/JavaScript, this is property/method lookup on runtime objects/prototypes. The semantics are not equivalent.

---

# 30. Inductive types

Lean:

~~~lean
inductive Result (ε α : Type) where
  | ok : α → Result ε α
  | error : ε → Result ε α
~~~

ProofScript:

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

TypeScript closest:

~~~ts
type Result<E, A> =
  | { kind: "ok"; value: A }
  | { kind: "error"; error: E };
~~~

A TS discriminated union does not generate dependent recursors or proof principles.

---

# 31. Indexed inductives

Lean:

~~~lean
inductive Vec (α : Type) : Nat → Type where
  | nil : Vec α 0
  | cons : α → Vec α n → Vec α (n + 1)
~~~

ProofScript supports indexed/dependent inductive meaning in the selected PSC2 subset. A source form whose result-type syntax is admitted can express the same family.

TypeScript has no genuine equivalent. Literal-number generics and tuple-length tricks do not create dependent inductive families checked by a proof kernel.

---

# 32. Constructors and projections

Lean:

~~~lean
structure User where
  id : Nat
  name : String

def u : User := { id := 1, name := "Alice" }

#check User.mk
#check u.id
~~~

ProofScript:

~~~proofscript
structure User where {
  id: Nat,
  name: String
}

const u: User := {
  id := 1,
  name := "Alice"
}

const id: Nat := {
  u.id
}
~~~

Constructors and projections retain selected Lean-compatible declaration/type meaning.

TypeScript closest:

~~~ts
interface User {
  id: number;
  name: string;
}

const u: User = { id: 1, name: "Alice" };
const id: number = u.id;
~~~

TypeScript object construction/property access is a runtime/structural analogue only.

---

# 33. Pattern profile: psc2-pattern-v1

Required pattern families:

| Pattern family | Lean 4 | ProofScript | TypeScript closest analogue |
|---|---|---|---|
| variable | <code>x</code> | <code>x</code> | variable/destructuring bind |
| wildcard | <code>_</code> | <code>_</code> | omitted/ignored binding |
| constructor | <code>.some x</code> | <code>.some x</code> | discriminant branch |
| nested constructor | yes | yes | nested destructuring + narrowing |
| tuple/product | <code>(x, y)</code> | <code>(x, y)</code> | <code>[x, y]</code> |
| supported literal | yes | yes | literal case |
| single-scrutinee match | yes | required | switch/if |

Not required by PSC2 core:

~~~text
multi-scrutinee match
generalized pattern alternatives
arbitrary dependent motive synthesis
user-defined pattern macros
full Lean equation-compiler surface
~~~

---

# 34. match

Lean:

~~~lean
match value with
| .none => fallback
| .some x => x
~~~

ProofScript:

~~~proofscript
match value with {
  | .none => fallback
  | .some x => x
}
~~~

Grammar:

~~~ebnf
MatchBody :=
  "{" ("|" PatternGroup "=>" PSTerm)+ "}"
~~~

TypeScript closest:

~~~ts
switch (value.kind) {
  case "none":
    return fallback;
  case "some":
    return value.value;
}
~~~

TypeScript narrowing can be powerful, but it is not dependent elimination.

---

# 35. Multi-scrutinee matching

Lean supports:

~~~lean
match x, y with
| ..., ... => ...
~~~

ProofScript:

~~~text
not required by psc2-language-v1
Post-PSC2 / official-extension candidate
~~~

TypeScript has no dedicated equivalent.

---

# 36. Recursion

## 36.1 Structural recursion

Lean checks accepted total recursive definitions according to its termination machinery.

ProofScript requires direct structural recursion in PSC2.

Example:

~~~proofscript
function sum(xs: List Nat): Nat := {
  match xs with {
    | .nil => 0
    | .cons x rest => x + sum(rest)
  }
}
~~~

TypeScript:

~~~ts
function sum(xs: number[]): number {
  if (xs.length === 0) return 0;
  return xs[0] + sum(xs.slice(1));
}
~~~

TypeScript does not prove termination.

## 36.2 Local recursion

Lean supports local recursive definitions.

ProofScript requires supported local recursion.

TypeScript nested functions can recurse, but again without logical totality checking.

## 36.3 mutual recursion

Lean:

~~~lean
mutual
  def even : Nat → Bool
    | 0 => true
    | n + 1 => odd n

  def odd : Nat → Bool
    | 0 => false
    | n + 1 => even n
end
~~~

ProofScript uses explicit <code>mutual</code> for the supported declaration subset. A representative PSC form is:

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

The exact accepted recursive bodies must still satisfy the selected PSC termination/partial rules.

TypeScript:

~~~ts
function even(n: number): boolean {
  return n === 0 ? true : odd(n - 1);
}

function odd(n: number): boolean {
  return n === 0 ? false : even(n - 1);
}
~~~

TypeScript permits mutual recursion through ordinary runtime/name semantics and does not prove termination.

## 36.4 arbitrary well-founded recursion

Lean supports broader well-founded termination machinery.

ProofScript:

~~~text
not required in full by psc2-language-v1
richer syntax/automation can be Standard prover/extension work
~~~

---

# 37. Basic do notation

Lean supports a rich <code>do</code> language.

PSC2 requires a deliberately bounded core subset.

Lean:

~~~lean
def load : CompilerM Nat := do
  let x ← readValue
  pure (x + 1)
~~~

ProofScript:

~~~proofscript
function load(): CompilerM Nat := do {
  let x ← readValue
  pure (x + 1)
}
~~~

Required PSC2 forms:

~~~text
term statement
simple let
identifier monadic bind
wildcard monadic bind
pure/return-style completion through selected native do semantics
~~~

Excluded from PSC2 basic-do core:

~~~text
refutable pattern bind
let mut
assignment
for
while
break
continue
~~~

TypeScript closest async-looking code:

~~~ts
async function load(): Promise<number> {
  const x = await readValue();
  return x + 1;
}
~~~

This is not equivalent: TS <code>await</code> is Promise-oriented, while PSC <code>do</code> is selected Bind/Pure semantics.

---

# 38. Primitive numeric semantics

## 38.1 Nat

Lean / ProofScript:

~~~proofscript
Nat
~~~

Exact nonnegative naturals.

ProofScript preserves truncating natural subtraction:

~~~text
3 - 5 = 0
~~~

TypeScript:

~~~ts
number
~~~

is IEEE-754 floating-point, not mathematical Nat.

## 38.2 Int

Lean / ProofScript:

~~~proofscript
Int
~~~

Exact mathematical signed integers under pinned semantics.

TypeScript closest:

~~~ts
number
bigint
~~~

Neither is automatically identical to PSC Int semantics for all operations.

## 38.3 Fixed-width/target-word integers

ProofScript retains selected widths/overflow/shift/conversion semantics.

TypeScript uses JS numbers, bigint, typed arrays, DataView, etc. as runtime mechanisms; they do not define PSC source semantics.

## 38.4 Float / Float32

Lean / ProofScript distinguish floating types from exact integers.

TypeScript's ordinary numeric type is:

~~~ts
number
~~~

a double-precision JS number.

---

# 39. Bool vs Prop

Lean:

~~~lean
Bool
Prop
~~~

ProofScript:

~~~proofscript
Bool
Prop
~~~

TypeScript:

~~~ts
boolean
~~~

has no corresponding proposition universe.

ProofScript equality distinction:

~~~proofscript
x = y    -- proposition
x == y   -- Bool-valued equality when supported
~~~

TypeScript:

~~~ts
x === y  // boolean
~~~

---

# 40. Text and bytes

Lean / ProofScript preserve distinct semantic types such as:

~~~text
Char
String
ByteArray
~~~

TypeScript/JavaScript primarily has:

~~~ts
string
Uint8Array
ArrayBuffer
~~~

Host UTF-16/string/typed-array representation choices do not define PSC source semantics.

---

# 41. Core data families

| Lean / ProofScript family | ProofScript meaning | TypeScript closest analogue |
|---|---|---|
| Unit | one-value type | void / undefined are not exact equivalents |
| Prod | product | tuple |
| Sum | disjoint sum | union/discriminated union |
| Option | explicit optional ADT | T \| undefined / null |
| Except | typed success/error ADT | Result-style union / thrown exceptions |
| List | recursive list | array is only an analogue |
| Array | array | Array<T> |
| Fin n | bounded natural indexed by n | number + validation, not a dependent type |
| subtype | value plus proof/property | branded/refined pattern, not kernel checked |

ProofScript deliberately keeps these semantic families distinct.

---

# 42. null, undefined, any, unknown

## 42.1 null / undefined

TypeScript:

~~~ts
string | null | undefined
~~~

ProofScript uses explicit data such as:

~~~proofscript
Option String
~~~

and does not import ambient JS null/undefined absence semantics.

## 42.2 any

TypeScript:

~~~ts
let x: any
~~~

can opt out of much static checking.

ProofScript has no native <code>any</code>.

## 42.3 unknown / foreign values

TypeScript has <code>unknown</code>.

ProofScript foreign boundaries may model unknown/dynamic values explicitly, but such values are not silently treated as arbitrary native PSC values.

---

# 43. Structural typing vs logical declaration identity

TypeScript:

~~~ts
interface Named {
  name: string;
}

const x = { name: "Alice", age: 30 };
const y: Named = x; // shape-compatible
~~~

ProofScript does not use TypeScript structural assignability as its native type model.

Declared structures/inductives/classes retain Lean-compatible logical identities and typing rules.

---

# 44. Prop, Type, Sort, universes

Lean / ProofScript:

~~~lean
Prop
Type
Type u
Sort u
~~~

TypeScript has no universe hierarchy.

These concepts are fundamental to dependent type theory, not merely generic type parameters.

---

# 45. forall and exists

Lean:

~~~lean
∀ x : α, P x
∃ x : α, P x
~~~

ProofScript includes selected native forall/exists term families:

~~~proofscript
forall x : α, P x
exists x : α, P x
~~~

or the accepted native spellings in the selected profile.

TypeScript has no proposition-level quantifier language.

Generic <code>&lt;T&gt;</code> is not universal quantification over propositions in this sense.

---

# 46. Equality and proof irrelevance

Lean and ProofScript use proposition-level equality and inherit proof irrelevance according to the pinned theory.

TypeScript equality operators return booleans and do not create equality proofs.

---

# 47. Quotients

Lean's logical foundation includes quotient semantics.

ProofScript inherits the selected quotient foundation without requiring special new PSC syntax.

TypeScript has no logical quotient construction.

---

# 48. Proof terms and by blocks

Lean:

~~~lean
theorem t : P := by
  ...
~~~

ProofScript:

~~~proofscript
theorem t: P := by {
  ...
}
~~~

TypeScript has no proof-term block.

Successful tactics must ultimately produce a valid proof term under the selected ProofScript logical checker.

---

# 49. Structured proof terms

## 49.1 have

Lean:

~~~lean
have h : P := proof
~~~

ProofScript:

~~~proofscript
have h : P := proof
~~~

TypeScript: no proof equivalent.

## 49.2 show

Lean:

~~~lean
show P from proof
~~~

ProofScript includes the corresponding selected proof form.

TypeScript: no equivalent.

## 49.3 suffices

Lean and ProofScript use proof-structuring <code>suffices</code>.

TypeScript: no equivalent.

## 49.4 calc

Lean:

~~~lean
calc
  a = b := h1
  _ = c := h2
~~~

ProofScript:

~~~proofscript
calc
  a = b := h1
  _ = c := h2
~~~

TypeScript: no proposition/proof-chain equivalent.

---

# 50. Standard tactic surface

The following are selected by <code>psc2-standard-language-v1</code>. They are not new kernel primitives.

| Tactic/form | Lean 4 | ProofScript Standard | TypeScript equivalent |
|---|---|---|---|
| rfl | yes | yes | none |
| exact | yes | yes | none |
| exact? | yes | yes | none |
| apply | yes | yes | none |
| refine | yes | yes | none |
| intro | yes | yes | none |
| intros | yes | yes | none |
| assumption | yes | yes | none |
| constructor | yes | yes | none |
| cases | yes | yes | none |
| induction | yes | yes | none |
| rw | yes | yes | none |
| simp | yes | yes | none |
| simpa | yes | yes | none |
| simp only | yes | yes | none |
| simp_all | yes | yes | none |
| unfold | yes | yes | none |
| change | yes | yes | none |
| dsimp | yes | yes | none |
| have | yes | yes | none |
| show | yes | yes | none |
| suffices | yes | yes | none |
| by_cases | yes | yes | none |
| by_contra | yes | yes | none |
| exfalso | yes | yes | none |
| subst | yes | yes | none |
| generalize | yes | yes | none |
| rcases | yes | yes | none |
| rintro | yes | yes | none |
| obtain | yes | yes | none |
| use | yes | yes | none |
| ext | yes | yes | none |
| decide | yes | yes | none |
| omega | yes | yes | none |
| grind | yes | yes | none |

Additional automation such as <code>ring</code>, <code>linarith</code>, SMT integration, or AI/general search is not automatically part of the Standard profile unless a later version selects it.

---

# 51. classical proof mode

Lean:

~~~lean
classical
~~~

ProofScript Standard selects classical proof mode.

TypeScript has no constructive-vs-classical proof distinction.

---

# 52. Attributes

Lean declaration attribute:

~~~lean
@[simp]
theorem add_zero' (n : Nat) : n + 0 = n := by
  simp
~~~

Lean attribute command:

~~~lean
attribute [simp] someTheorem
~~~

ProofScript declaration attribute:

~~~proofscript
@[simp]
theorem addZero(n: Nat): n + 0 = n := by {
  simp
}
~~~

ProofScript attribute command over a registered Standard attribute:

~~~proofscript
attribute [simp] someTheorem
~~~

ProofScript Standard fixed attribute names:

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

ProofScript dependencies cannot register arbitrary new Standard attribute handlers.

TypeScript closest concepts include decorators and declaration modifiers:

~~~ts
@decorator
class Example {}
~~~

but TypeScript decorators are not theorem/elaboration attribute registries and do not have Lean/PSC proof meaning.

---

# 53. set_option

Lean:

~~~lean
set_option pp.universes true
~~~

ProofScript:

~~~proofscript
set_option selectedOption value
~~~

Only names selected by the fixed Standard registration closure are accepted.

Unknown/unselected Standard options reject.

TypeScript generally configures the compiler externally:

~~~json
{
  "compilerOptions": {
    "strict": true
  }
}
~~~

This is not an exact source-language equivalent.

---

# 54. Notation

Lean can define new notation/operators.

ProofScript Standard:

~~~text
fixed notation closure
ordinary dependencies cannot add new notation
~~~

ProofScript Extensible can explicitly select custom notation/extensions as part of its environment/profile identity.

TypeScript user libraries cannot add new parser operators.

---

# 55. Tooling commands

Lean:

~~~lean
#check foo
#print foo
#reduce expr
#eval expr
~~~

ProofScript tooling-profile spelling:

~~~proofscript
#check foo
#print foo
#reduce expr
#eval expr
~~~

These are **not** <code>psc2-language-v1</code> program declarations; they are development/tooling commands.

TypeScript uses compiler/editor/tool operations rather than analogous source commands, for example:

~~~text
tsc --noEmit
editor hover / go-to-definition / type display
~~~

---

# 56. Pure contracts: requires

ProofScript:

~~~proofscript
function debit(balance: Nat, amount: Nat): Except String Nat
  requires amount <= balance
:= {
  .ok(balance - amount)
}
~~~

Lean closest logical encoding:

~~~lean
def debit
    (balance amount : Nat)
    (h : amount ≤ balance) :
    Except String Nat :=
  .ok (balance - amount)
~~~

or a separate theorem about the implementation.

TypeScript closest runtime check:

~~~ts
function debit(balance: number, amount: number): number {
  if (amount > balance) throw new Error("insufficient balance");
  return balance - amount;
}
~~~

The TypeScript check is runtime behavior, not proof evidence.

---

# 57. Pure contracts: ensures

ProofScript:

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

Conceptual semantics:

~~~text
forall inputs,
  Pre(inputs) ->
  Post(inputs, f(inputs))
~~~

Lean expresses the same property through theorem/dependent/proposition source rather than a dedicated base <code>ensures</code> keyword.

TypeScript has no built-in proof postcondition language.

---

# 58. Contract grammar and variants

ProofScript grammar:

~~~ebnf
ContractClause :=
    "requires" PSTerm
  | "ensures" Ident "=>" PSTerm
~~~

Rules:

~~~text
multiple requires => conjunction
multiple ensures  => conjunction
no requires       => True
no ensures        => no functional postcondition claim
~~~

Current r3 does **not** add dedicated syntax for:

~~~text
assert
loop invariant
old
ghost state
async contract
effect-trace contract
~~~

Those are Post-PSC2 verification-language candidates.

---

# 59. ProofScript owned EBNF — complete current r3 summary

The following EBNF is the current owned PSC2 grammar summary. Referenced native categories such as <code>PSTerm</code>, <code>PatternGroup</code>, <code>StructField</code>, and <code>WhereField</code> are restricted by the selected profile.

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

# 60. Separator/trailing-separator matrix

| PSC category | Boundary | Trailing separator |
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
| do/tactic sequences | selected native category rule | selected native rule |

There is no universal ProofScript semicolon or universal trailing-comma policy.

---

# 61. Full PSC2 exact-coverage checklist

This mirrors the current <code>psc2-language-v1</code> closure.

| Feature family | PSC2 status | Main comparison section |
|---|---|---|
| lexical identifiers/literals/comments | required | 4 |
| modules/imports/qualified names | required | 5 |
| namespace/section/open/variable/include/omit/universe | required | 5 |
| private visibility | required | 5 |
| attributes over registered set | required | 52 |
| set_option over registered set | required | 53 |
| #check/#print/#reduce/#eval | tooling only | 55 |
| def | required | 6 |
| const | required | 6 |
| function | required | 6 |
| single-term braced bodies | required | 7 |
| theorem/example | required | 8 |
| abbrev | required | 8 |
| opaque | required | 8 |
| axiom | required | 8 |
| structure | required | 22 |
| class | required | 23 |
| instance | required | 24 |
| inductive/constructors/projections | required | 30–32 |
| explicit binder | required | 11 |
| implicit binder | required | 11 |
| strict implicit binder | required | 11 |
| instance binder | required | 11 |
| lambda | required | 13 |
| let | required | 14 |
| application | required | 15 |
| parenthesized calls | required | 15 |
| named arguments | required | 16 |
| default arguments | required | 17 |
| empty calls | required | 17 |
| call trailing comma | required | 18 |
| generalized field notation | required | 29 |
| record construction | required | 27 |
| record update | required | 28 |
| local where | required | 10 |
| parenthesized terms | required | 20 |
| tuple/product terms | required | 19 |
| type ascription | required | 20 |
| forall/exists/Pi | required | 45 |
| native/braced if | required | 21 |
| psc2-pattern-v1 | required | 33 |
| single-scrutinee match | required | 34 |
| basic do | required | 37 |
| structural recursion | required | 36 |
| local recursion | required | 36 |
| mutual recursion | required | 36 |
| partial | required | 9 |
| noncomputable | required | 9 |
| unsafe | excluded from PSC2 Standard | 9 |
| ordinary instance search | required | 25 |
| Lean-compatible coercions | required | 26 |
| Prop/Type/Sort/universes/Pi/Eq | required | 44–47 |
| proof terms/by | required | 48 |
| have/show/suffices/calc | required | 49 |
| requires/ensures | required | 56–58 |

---

# 62. Lean features deliberately not required by PSC2 core

| Lean feature | PSC2 status | Reason/owner |
|---|---|---|
| multi-scrutinee match | not core | Post-PSC2 / extension |
| rich pattern alternatives | not core | Post-PSC2 / extension |
| equation-style definition surface | not core | Post-PSC2 / extension |
| if-let convenience | not core | Post-PSC2 / extension |
| rich let/do pattern bindings | not core | Post-PSC2 / extension |
| let mut | not core | Post-PSC2 |
| reassignment | not core | Post-PSC2 |
| for | not core | Post-PSC2 |
| while | not core | Post-PSC2 |
| break | not core | Post-PSC2 |
| continue | not core | Post-PSC2 |
| arbitrary syntax declarations | excluded from Standard | Extensible profile |
| macro / macro_rules | excluded from Standard | Extensible profile |
| arbitrary notation declarations | excluded from Standard | Extensible profile |
| custom parser categories | excluded from Standard | Extensible profile |
| custom term/command/tactic elaborators | excluded from Standard | Extensible/profile/plugin |
| unrestricted quotations/Meta authoring | excluded from PSC2 Standard | Extensible |
| arbitrary environment extensions | excluded from Standard | Extensible |
| arbitrary deriving handlers | not core | official/controlled extension |
| arbitrary Lean compiler intrinsics | not core | host/compatibility boundary |
| full termination-elaboration parity | not core | bounded PSC2 + later prover/extension |

This is intentional language design, not missing semantics.

---

# 63. TypeScript features deliberately not imported into PSC2

| TypeScript / JS feature | PSC2 status |
|---|---|
| native any | excluded |
| JavaScript truthiness | excluded |
| implicit null/undefined absence | excluded |
| TypeScript structural assignability as native type semantics | excluded |
| JS prototype inheritance as native record/class semantics | excluded |
| dynamic property lookup as field notation | excluded |
| automatic semicolon insertion | excluded |
| general statement function blocks | excluded |
| arrow lambdas | not current base syntax |
| optional chaining | not current syntax |
| async keyword | Post-PSC2 candidate |
| await keyword | Post-PSC2 candidate |
| Promise as native async semantics | explicitly not the PSC semantic definition |
| using/defer-style resource syntax | Post-PSC2 candidate |
| assignment | Post-PSC2 candidate |
| for/while/break/continue | Post-PSC2 candidates |
| JSX | possible future separate dialect |

---

# 64. Post-PSC2 language candidates side by side

These are **not current r3 syntax**.

| Candidate | Lean 4 analogue | ProofScript direction | TypeScript analogue |
|---|---|---|---|
| multi-scrutinee match | native | future extension/profile | nested switch/tuple logic |
| pattern alternatives | richer Lean pattern language | future | switch case combinations |
| if let | available Lean convenience forms | future | if + narrowing |
| equation-style functions | native Lean definitions | future | multiple branches manually |
| let mut | Lean do mutation | future explicit semantics | let |
| assignment | Lean do mutation | future explicit semantics | = |
| for | Lean do iteration | future | for |
| while | Lean do iteration | future | while |
| break/continue | Lean do control flow | future | native |
| typed try/recovery syntax | Except/monadic facilities | library first, syntax optional | try/catch |
| async/await | IO/Task/future facilities | future syntax over PSC app semantics | native async/await |
| using/defer | bracket/resource libraries | future syntax | using / try-finally patterns |
| assert contract | theorem/program-logic mechanisms | future verification syntax | runtime assert |
| invariant | theorem/program logic | future verification syntax | comments/runtime libs only |
| old/pre-state | verification logic | future | no native equivalent |
| ghost data | proof/program logic | future | no native proof equivalent |
| state/effect/async contracts | theorem/program logic | future | runtime libraries |
| deriving | Lean deriving handlers | future official/controlled extension | code generation/decorators |
| compile-time reflection | Lean Meta/reflection | controlled future form | compiler API/type-level tricks |
| UI/JSX dialect | DSL/macro ecosystem | separate .psx-style profile possible | JSX/TSX |
| larger Lean compatibility | native Lean | later bounded profiles | not applicable |

---

# 65. End-to-end sample: data + function + theorem

## Lean 4

~~~lean
structure User where
  id : Nat
  name : String
  active : Bool

def activate (user : User) : User :=
  { user with active := true }

theorem activate_active (user : User) :
    (activate user).active = true := by
  rfl
~~~

## ProofScript

~~~proofscript
structure User where {
  id: Nat,
  name: String,
  active: Bool
}

function activate(user: User): User := {
  { user with active := true }
}

theorem activateActive(user: User):
  activate(user).active = true := by {
  rfl
}
~~~

## TypeScript

~~~ts
interface User {
  id: number;
  name: string;
  active: boolean;
}

function activate(user: User): User {
  return { ...user, active: true };
}

// Runtime test, not a theorem:
const user = activate({ id: 1, name: "Alice", active: false });
console.assert(user.active === true);
~~~

---

# 66. End-to-end sample: generic/typeclass-like programming

## Lean 4

~~~lean
class Sized (α : Type) where
  size : α → Nat

instance : Sized String where
  size s := s.length

def sizeOf {α : Type} [Sized α] (x : α) : Nat :=
  Sized.size x
~~~

## ProofScript

~~~proofscript
class Sized(α: Type) where {
  size: α -> Nat
}

instance : Sized String where {
  size(s: String): Nat := s.length;
}

function sizeOf {α: Type}[Sized α](x: α): Nat := {
  Sized.size(x)
}
~~~

## TypeScript

~~~ts
interface Sized<T> {
  size(value: T): number;
}

const sizedString: Sized<string> = {
  size: s => s.length,
};

function sizeOf<T>(sized: Sized<T>, x: T): number {
  return sized.size(x);
}
~~~

The explicit <code>sized</code> argument shows the semantic gap: TypeScript has no built-in instance synthesis.

---

# 67. End-to-end sample: Option / nullable data

## Lean 4

~~~lean
def getOrElse (value : Option Nat) (fallback : Nat) : Nat :=
  match value with
  | .none => fallback
  | .some x => x
~~~

## ProofScript

~~~proofscript
function getOrElse(value: Option Nat, fallback: Nat): Nat := {
  match value with {
    | .none => fallback
    | .some x => x
  }
}
~~~

## TypeScript

~~~ts
function getOrElse(
  value: number | undefined,
  fallback: number
): number {
  return value === undefined ? fallback : value;
}
~~~

The TS union is a practical analogue, not the same ADT/proof semantics.

---

# 68. End-to-end sample: contract

## Lean 4

~~~lean
def debit
    (balance amount : Nat)
    (h : amount ≤ balance) :
    Except String Nat :=
  .ok (balance - amount)

theorem debit_ok
    (balance amount : Nat)
    (h : amount ≤ balance) :
    debit balance amount h = .ok (balance - amount) := by
  rfl
~~~

## ProofScript

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

## TypeScript

~~~ts
function debit(balance: number, amount: number): number {
  if (amount > balance) {
    throw new Error("insufficient balance");
  }
  return balance - amount;
}
~~~

The TypeScript function has runtime validation only. The PSC contract is intended to denote proof obligations.

---

# 69. End-to-end sample: monadic/effect sequencing

## Lean 4

~~~lean
def load : CompilerM Nat := do
  let x ← readValue
  pure (x + 1)
~~~

## ProofScript

~~~proofscript
function load(): CompilerM Nat := do {
  let x ← readValue
  pure (x + 1)
}
~~~

## TypeScript

~~~ts
async function load(): Promise<number> {
  const x = await readValue();
  return x + 1;
}
~~~

The TypeScript code is only a workflow analogue. Promise semantics do not define ProofScript <code>do</code>.

---

# 70. Summary: where PSC2 intentionally sits

~~~text
Lean semantics                    TypeScript ergonomics/ecosystem
      \                                      /
       \                                    /
        -------- ProofScript PSC2 ----------
                 |
                 + dependent types
                 + kernel-checked proofs
                 + inductives/typeclasses
                 + exact Nat/Int semantics
                 + explicit Option/Except
                 + f(x, y) call syntax
                 + comma parameter lists
                 + := { term } body syntax
                 + structural braces
                 + closed Standard grammar
                 + requires/ensures
                 + controlled extensibility
                 + npm/JS interop direction
~~~

The intended result is **not** "TypeScript with proofs" and not "all Lean syntax with different punctuation."

It is a deliberately bounded application-facing language whose accepted constructs preserve Lean-compatible dependent/proof semantics, while libraries, prover packages, controlled extensions, tooling, foreign interfaces, and Post-PSC2 profiles supply capabilities that do not need to be compiler-core syntax.

---

# 71. Reference basis

ProofScript authority in this repository:

~~~text
study/proofscript-v0.9-r3-research/ProofScript_Language_Reference_v0.9.0_r3.md
study/proofscript-v0.9-r3-research/FEATURE-REGISTRY-r3.json
study/proofscript-v0.9-r3-research/PS-STANDARD-REGISTRY-r3.json
study/proofscript-v0.9-r3-research/POST_PSC2_LANGUAGE_ROADMAP.md
~~~

Lean semantic target:

~~~text
Lean 4.34.0
commit 293d5d0c0c3f3dded4688b3ccd6a33939ac5102b
~~~

External explanatory references consulted:

~~~text
Lean Language Reference:
https://lean-lang.org/doc/reference/latest/

TypeScript Handbook:
https://www.typescriptlang.org/docs/handbook/
~~~

Where this comparison and the ProofScript language reference disagree, the ProofScript language reference is authoritative for PSC2.
