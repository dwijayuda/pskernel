# The ProofScript Language Reference v0.9.0 r3

**Status:** normative source-language specification

**Language edition:** ps-0.9-r3

**Semantic pin:** Lean 4.34.0, commit 293d5d0c0c3f3dded4688b3ccd6a33939ac5102b

This document defines ProofScript source syntax, source profiles, language semantics, grammar rules, and canonical examples.

It is intentionally independent of compiler architecture, bootstrap strategy, backend design, cache layout, artifact formats, release evidence, package implementation, and implementation sequencing.

The pinned Lean environment is the semantic authority for the native language categories explicitly included by this specification. A Lean feature is not part of ProofScript merely because Lean implements it.

## Normative words

- **MUST / MUST NOT** — required language behavior.
- **SHOULD / SHOULD NOT** — recommended source/tooling behavior that must not change program meaning.
- **MAY** — permitted behavior.
- **reject** — source is not accepted under the selected language/profile.
- **unsupported** — a recognized feature is outside the selected profile and must reject rather than silently change meaning.

## Table of contents

1. Language identities
2. Semantic foundation
3. Source kinds
4. Source profiles
5. Lexical rules
6. Names, modules, and scope
7. Declaration forms
8. Binders and universes
9. Zero-source-argument functions
10. Functions, lambdas, lets, and application
11. Field notation and record update
12. Conditionals
13. Structures and classes
14. Inductives
15. Patterns and match
16. Classes, instances, coercions, and type-directed resolution
17. Recursion and termination
18. Basic do notation
19. Primitive and data semantics
20. Propositions and proof source
21. Notation, attributes, and options
22. Pure contracts
23. psc2-language-v1 exact coverage
24. lean-subset-psc2-v1
25. psc2-standard-language-v1
26. Feature ownership rule
27. Post-PSC2 language roadmap
28. Grammar summary
29. Canonical examples
30. Explicit exclusions
31. Language completeness rule

## Glossary

**Native** — syntax or semantics taken from the pinned Lean 4.34.0 environment only when the selected ProofScript profile explicitly includes that category.

**Owned syntax** — a ProofScript production whose parsing or surface meaning is defined directly by this specification.

**Source profile** — a versioned set of source grammar/registration rules used to interpret a file.

**Standard** — the closed ps-standard-0.9-r3 source profile. Ordinary dependencies cannot mutate its grammar.

**Extensible** — ps-lean-extensible-0.9-r3, where explicitly declared syntax/Meta extensions are part of the profile/environment identity.

**psc2-language-v1** — the exact source-language capability closure that a psc2-compiler-v1 implementation must support.

**psc2-standard-language-v1** — psc2-language-v1 plus the closed Standard notation, attribute, and prover surface selected in this specification.

**lean-subset-psc2-v1** — the bounded native Lean source compatibility profile corresponding to the supported PSC2 semantic families.

**psc2-pattern-v1** — the required PSC2 pattern family: variable, wildcard, constructor, nested constructor, tuple/product, supported literal, and single-scrutinee match.

**CallGap** — the horizontal trivia allowed between a completed callable head and the opening parenthesis of a ProofScript-owned parenthesized call.

**Post-PSC2 language** — proposed future source-language work that is not current ps-0.9-r3 syntax.

**Tooling command** — a command accepted by development tools but not part of the program-declaration language, such as #check or #eval.

# 1. Language identities

ProofScript separates language identity from compiler and distribution identity.

The current source-language edition is:

~~~text
ps-0.9-r3
~~~

The closed Standard source profile is:

~~~text
ps-standard-0.9-r3
~~~

The declared-extensibility source profile is:

~~~text
ps-lean-extensible-0.9-r3
~~~

The exact language capability set required from the first PSC2 compiler family is:

~~~text
psc2-language-v1
~~~

A compiler claiming:

~~~text
psc2-compiler-v1
~~~

MUST implement all of psc2-language-v1.

The bounded native Lean source profile is:

~~~text
lean-subset-psc2-v1
~~~

The language-facing Standard PSC2 profile is:

~~~text
psc2-standard-language-v1
~~~

The packaged distribution named psc2-standard-v1 may combine the compiler with libraries, prover packages, runtime packages, and official extensions. Those package choices do not change the base language semantics unless a separately versioned source profile says they do.

# 2. Semantic foundation

ProofScript uses the pinned Lean logical foundation.

The included semantic foundation contains:

- Prop;
- Type and Sort;
- universe levels;
- dependent function/Pi types;
- lambdas and application;
- propositions as types;
- proof terms;
- inductive families and constructors;
- recursors and dependent elimination;
- equality;
- quotient semantics provided by the selected pinned logical foundation;
- proof irrelevance according to the pinned theory;
- typeclass-directed elaboration for the selected profile;
- coercions for the selected profile;
- definitional equality;
- structural recursion;
- explicitly selected total-recursion facilities.

ProofScript does not define a second TypeScript-like or JavaScript-like type theory.

For a source term or declaration accepted by a profile, its native logical meaning is the meaning of the corresponding pinned Lean construct after applying the ProofScript-owned surface rules defined here.

Unsupported input rejects.

# 3. Source kinds

## 3.1 .ps

A .ps file uses ProofScript syntax under an explicit ProofScript source profile.

The default Standard profile is ps-standard-0.9-r3.

## 3.2 .lean

A .lean file is interpreted only through an explicitly selected Lean compatibility profile.

For PSC2 the profile is lean-subset-psc2-v1.

ProofScript syntax is not injected into .lean files.

Full Lean 4 source compatibility is not a PSC2 requirement.

## 3.3 Future dialects

A future dialect such as .psx requires its own explicit grammar/profile identity.

A file extension alone does not define JSX, UI, macro, effect, or runtime semantics.

# 4. Source profiles

## 4.1 ps-standard-0.9-r3

Standard has a closed, versioned grammar and a fixed registration set.

Ordinary dependencies MUST NOT silently add or replace:

- syntax categories;
- notation;
- macros;
- term elaborators;
- command elaborators;
- tactic syntax;
- tactic elaborators;
- deriving handlers;
- attribute handlers;
- parser extensions.

A Standard program has the same grammar independent of unrelated installed packages.

## 4.2 ps-lean-extensible-0.9-r3

The extensible profile may use explicitly declared syntax, notation, macro, tactic, elaborator, Meta, and parser extensions.

Every extension that can change source interpretation is part of the source-profile/environment identity.

An extension may construct candidate terms or declarations but does not gain independent proof authority.

## 4.3 Profile non-conversion rule

Source written for one profile MUST NOT be silently interpreted under a weaker or different profile.

A source transformation between profiles is an explicit migration or translation operation.

# 5. Lexical rules

ProofScript inherits the selected native Lean lexical categories except where this document defines an owned surface rule.

## 5.1 Whitespace and comments

Ordinary native whitespace and comments retain their pinned meaning.

ProofScript does not use JavaScript automatic semicolon insertion.

A physical line break is semantically relevant only where an owned grammar rule says so.

## 5.2 CallGap

CallGap is the horizontal trivia allowed between a completed callable head and a ProofScript-owned parenthesized call.

CallGap permits:

- ordinary inherited horizontal space trivia;
- inherited comments that contain no physical line terminator.

CallGap does not permit a bare physical line terminator.

Tabs are not introduced as special call-only whitespace.

Therefore:

~~~proofscript
f(1)
f (1)
f /* comment */ (1)
~~~

are ProofScript-owned parenthesized calls, while a physical line break between f and ( breaks that ownership.

## 5.3 Contextual words

ProofScript-owned words are contextual where the grammar permits that treatment.

A spelling introduced for one owned form MUST NOT become globally reserved in unrelated positions unless this specification explicitly says so.

# 6. Names, modules, and scope

psc2-language-v1 includes:

- ordinary import declarations;
- public import declarations for module re-export;
- qualified names;
- namespace declarations and end;
- section declarations and end;
- open for the selected fixed namespace behavior;
- variable declarations;
- include and omit where meaningful to the selected native category;
- universe declarations;
- deterministic lexical/local scope;
- deterministic name resolution;
- public/private API visibility for supported declarations.

## 6.1 Module import and re-export

ProofScript uses the selected Lean-compatible distinction:

~~~proofscript
import Foo.Bar
public import Foo.Api
~~~

The rules are:

1. `import M` makes the public declarations of `M` available to the importing module but does **not** re-export `M` as part of this module's public dependency surface.
2. `public import M` imports `M` and re-exports the public declarations reachable through `M`'s public-import closure.
3. `private` declarations are never exported or re-exported.
4. `open M` affects local name resolution only; it never changes the module's exported API.
5. re-export does not copy declarations, change declaration identity, or create new proof authority.
6. import/re-export ambiguity rejects deterministically; there is no last-import-wins rule.
7. package configuration may select package entry modules, but package metadata does not change declaration visibility semantics.

A library that wants a curated public API SHOULD use a small facade module:

~~~proofscript
import Internal.BigModule

def selectedValue := Internal.BigModule.selectedValue
theorem selectedLaw := Internal.BigModule.selectedLaw
~~~

or public-import a whole intentionally public module:

~~~proofscript
public import Public.Core
public import Public.Data
~~~

PSC2 does not require TypeScript/ECMAScript-style selective export lists, default exports, or namespace exports as core language syntax.

## 6.2 Source identity

A logical module resolves to one authoritative source file.

If both `M.ps` and `M.lean` are candidates for the same module, the selected project/profile must choose one. Ambiguous source ownership rejects.

## 6.3 Import and grammar isolation

Imports do not grant new Standard grammar registrations.

A module reached through `public import` contributes declarations according to the module API rules above; it does not inject parser, macro, tactic-elaborator, or arbitrary Meta registrations into `ps-standard`.

# 7. Declaration forms

psc2-language-v1 includes these declaration families.

## 7.1 def

def has the selected native definition meaning.

Example:

~~~proofscript
def double(n : Nat) : Nat := {
  n + n
}
~~~

## 7.2 const

const is a module/namespace-level parameterless definition alias. It is not a local term-binding form.

~~~proofscript
const answer : Nat := {
  42
}
~~~

It has the same semantic category as an ordinary parameterless definition.

const does not mean:

- mutable JavaScript binding;
- object freezing;
- module hoisting;
- runtime constant folding.

## 7.3 function

function is a declaration-head alias for an ordinary function definition with ProofScript explicit-parameter syntax.

~~~proofscript
function add(x: Nat, y: Nat): Nat := {
  x + y
}
~~~

Its core function meaning remains curried/dependent function application.

It does not introduce JavaScript multi-argument function semantics, hoisting, this, or prototypes.

## 7.3.1 Braced definition bodies

The body of a def, const, or function declaration may be written in either form:

~~~proofscript
function add(x: Nat, y: Nat): Nat :=
  x + y
~~~

or:

~~~proofscript
function add(x: Nat, y: Nat): Nat := {
  x + y
}
~~~

The forms are semantically identical.

For these declarations:

~~~text
:= { term }
≡
:= term
~~~

The braces are a single-term declaration-body wrapper. They do not create a statement block, implicit return, new scope rule, sequencing rule, or JavaScript/TypeScript function-body semantics.

Exactly one PSTerm is contained by the wrapper. The contained term may itself be multiline or may be a construct such as if, match, do, let, or another term whose own grammar permits internal sequencing.

Therefore this is valid:

~~~proofscript
function classify(x: Nat): Nat := {
  if (x == 0) {
    0
  } else {
    1
  }
}
~~~

but braces alone do not make unrelated adjacent terms valid:

~~~proofscript
function invalid(): Nat := {
  1
  2
}
~~~

The declaration-body wrapper does not steal ownership from existing braced terms. In particular, a record literal or record update remains a PSTerm including its own braces:

~~~proofscript
const user: User := {
  id := 1,
  name := "Alice"
}
~~~

The example above is an unwrapped record-literal body, not a declaration-body wrapper around field statements.

To explicitly wrap a record literal as the one body term, use two brace layers:

~~~proofscript
const user: User := {
  {
    id := 1,
    name := "Alice"
  }
}
~~~

Both record examples have the same value meaning.

If a future extensible grammar makes the same token sequence valid both as a complete PSTerm and as a braced declaration-body wrapper containing another PSTerm, the complete PSTerm keeps ownership in ps-standard. An extensible profile must resolve or reject any additional ambiguity explicitly.

## 7.4 theorem

theorem introduces a proposition with a proof term.

~~~proofscript
theorem addZero(n: Nat): n + 0 = n := by {
  simp
}
~~~

A theorem is accepted only when its proof is valid under the selected logical environment.

## 7.5 example

example has the selected native proof/checking meaning and does not introduce a reusable named declaration unless the native form does so.

## 7.6 abbrev

abbrev is a reducible definitional alias with the selected pinned transparency meaning.

It is not merely display metadata.

## 7.7 opaque

opaque introduces a definition with the selected pinned opacity/reducibility semantics.

Opacity affects definitional reduction according to the selected native rules; it does not make an invalid declaration valid.

## 7.8 axiom

axiom introduces an explicit logical assumption.

~~~proofscript
axiom externalLaw : P
~~~

An axiom is part of the logical assumptions of declarations that depend on it.

It is never equivalent to a proved theorem.

## 7.9 structures, classes, inductives, and instances

ProofScript includes:

- structure;
- class;
- inductive;
- instance;
- constructors;
- projections;
- record construction;
- record update.

Their logical meaning is the selected native Lean meaning.

## 7.10 mutual

The supported mutual declaration/recursion form uses the selected native semantics for the declaration families admitted by psc2-language-v1.

## 7.11 partial and noncomputable

partial explicitly marks executable recursion that is not accepted as total logical computation.

noncomputable permits logical definitions whose executable realization is not required by the selected runtime profile.

Neither spelling grants proof authority to unchecked runtime behavior.

## 7.12 unsafe

unsafe is not part of ps-standard-0.9-r3.

A separately named extensible or host-adapter profile may admit unsafe source with explicit nonportable/unverified status.

## 7.13 local where declarations

A supported declaration may use the selected native local where-declaration form.

In ProofScript brace mode:

~~~ebnf
WhereBody :=
  "{" WhereField (";" WhereField)* ";"? "}"
~~~

At least one local declaration is required.

These declarations are lexically local to the owning declaration according to the selected native scope rules.

# 8. Binders and universes

psc2-language-v1 includes:

- explicit binders;
- implicit binders;
- strict implicit binders;
- instance binders;
- dependent binder types;
- explicit universe names and universe applications required by supported declarations.

ProofScript explicit parameter groups use:

~~~ebnf
DefaultSuffix :=
  ":=" PSTerm

ExplicitGroup :=
  "(" ExplicitEntry ("," ExplicitEntry)* ","? ")"

ExplicitEntry :=
  BinderIdent ":" PSTerm DefaultSuffix?
~~~

Example:

~~~proofscript
function choose(α: Type, x: α, y: α): α :=
  x
~~~

Native implicit, strict-implicit, and instance binder delimiters retain their selected native meanings.

# 9. Zero-source-argument functions

A function declaration may contain one final empty explicit parameter group.

~~~proofscript
function now(): Time :=
  clockValue
~~~

This is sugar for one optional Unit parameter defaulting to Unit.unit.

Conceptually:

~~~text
function f(): R
≈
def f (_unit : Unit := ()) : R
~~~

Rules:

1. the empty group is the final explicit group;
2. it represents zero source arguments, not a JavaScript zero-arity core function;
3. native implicit/instance binders may precede it;
4. it may not be followed by another explicit parameter group.

Reject:

~~~proofscript
function bad()(x: Nat): Nat := x
function bad(x: Nat)(): Nat := x
~~~

# 10. Functions, lambdas, lets, and application

## 10.1 Function model

Core functions are unary/curried.

Multiple source parameters elaborate to ordered binders.

## 10.2 Lambdas

Native lambda syntax and semantics are included for the supported binder subset.

## 10.3 let

Native let binding is included.

A let binding does not introduce mutable storage unless an explicitly different future construct says so.

## 10.4 Parenthesized calls

ProofScript owns parenthesized call syntax over a completed callable head.

~~~proofscript
add(1, 2)
add (1, 2)
~~~

Both have the same ProofScript call meaning.

The call is one application object containing the ordered argument list.

## 10.5 Call arguments

~~~ebnf
CallArguments :=
  CallArgument ("," CallArgument)* ","?

CallArgument :=
    NamedCallArgument
  | PSTerm

NamedCallArgument :=
  Ident ":=" PSTerm
~~~

A nonempty parenthesized call may have one trailing comma.

## 10.6 Named arguments

~~~proofscript
paint(color := red, width := 2)
~~~

Named arguments use native named-argument meaning.

They do not implement runtime object-style argument passing.

## 10.7 Default arguments

Default parameters use the selected native default-argument semantics.

Defaults are elaboration/application behavior; they do not create runtime overload dispatch.

## 10.8 Empty calls

~~~proofscript
f()
~~~

is a complete invocation request.

Its meaning is native high-level completion of omitted optional/automatic explicit parameters, followed by a ProofScript acceptance check.

An empty call is accepted only if every omitted explicit parameter can be supplied by the selected native optional/automatic mechanism.

An ordinary required explicit parameter cannot be silently omitted.

Thus:

~~~proofscript
function greet(name: String := "world"): String := name
greet()    -- accepted
~~~

while:

~~~proofscript
function add1(x: Nat): Nat := x + 1
add1()     -- reject
~~~

An explicit Unit argument is different:

~~~proofscript
f(())
~~~

## 10.9 Tuple arguments

One tuple argument requires explicit grouping:

~~~proofscript
tupled((1, 2))
~~~

The inner parentheses form the tuple; the outer parentheses form the call.

# 11. Field notation and record update

Generalized field notation is type-directed/static.

~~~proofscript
value.method(arg)
~~~

It does not mean JavaScript prototype lookup or arbitrary dynamic property dispatch.

The native field dot remains adjacent according to its native lexical rule.

Record update:

~~~proofscript
{ user with active := true }
~~~

has constructor/projection/update semantics of the selected native structure model.

It is not JavaScript object spread.

Dependent record updates are accepted only when the rebuilt value satisfies the declared dependent field types.

# 12. Conditionals

Native conditional semantics are included.

ProofScript also defines the braced form:

~~~proofscript
if (condition) { thenTerm } else { elseTerm }
~~~

Each branch contains exactly one term.

The braces are not a general statement block and do not imply an implicit return.

Grammar:

~~~ebnf
BracedIf :=
  "if" "(" PSTerm ")" "{" PSTerm "}"
  "else" "{" PSTerm "}"
~~~

# 13. Structures and classes

ProofScript-owned structure/class bodies are structural sequences.

~~~proofscript
structure User where {
  id: Nat,
  name: String,
  active: Bool
}
~~~

~~~proofscript
class Sized(α: Type) where {
  size: α -> Nat
}
~~~

Grammar:

~~~ebnf
StructBody :=
  "{" (StructField ("," StructField)*)? "}"

ClassBody :=
  "{" (ClassField ("," ClassField)*)? "}"
~~~

A trailing comma after the final structure or class field is rejected.

Structure/class identity is nominal/logical, not JavaScript structural-object identity.

# 14. Inductives

ProofScript includes ordinary and indexed inductive types supported by psc2-language-v1.

~~~proofscript
inductive LoadState(ε: Type, α: Type) where {
  | idle
  | loading(requestId: Nat)
  | ready(requestId: Nat, value: α)
  | failed(requestId: Nat, error: ε)
}
~~~

Grammar:

~~~ebnf
InductiveBody :=
  "{" ("|" ConstructorBody)* "}"
~~~

Constructor typing, positivity, parameters, indices, and elimination follow the selected native semantics.

# 15. Patterns and match

The required PSC2 pattern profile is:

~~~text
psc2-pattern-v1
~~~

It contains exactly these required pattern families:

- variable patterns;
- wildcard patterns;
- constructor patterns;
- nested constructor patterns;
- tuple/product patterns;
- supported literal patterns;
- single-scrutinee match.

Example:

~~~proofscript
function getOrElse(value: Option Nat, fallback: Nat): Nat :=
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

The required profile does not include:

- multi-scrutinee match syntax;
- generalized pattern alternatives;
- arbitrary user-defined pattern macros;
- full Lean equation-compiler surface;
- arbitrary dependent-pattern motive synthesis.

Those may be provided by a later language profile or an official extension that lowers to existing semantics.

# 16. Classes, instances, coercions, and type-directed resolution

Classes are native type-directed abstractions.

Instances are semantic registrations, not JavaScript classes.

psc2-language-v1 includes ordinary global and local instance registration and lookup needed by the supported source subset.

The Standard language may use fixed scoped registrations selected by its closed registry.

Custom user-defined synthesis procedures or arbitrary environment-extension hooks are not part of psc2-language-v1.

Coercion insertion is permitted only through the selected Lean-compatible coercion/typeclass semantics.

ProofScript never defines TypeScript-style structural assignability or JavaScript implicit conversion as native coercion semantics.

# 17. Recursion and termination

psc2-language-v1 requires:

- direct structural recursion;
- local recursive definitions in the supported declaration subset;
- explicit mutual recursion in the supported declaration subset;
- partial def as the explicit runtime-only recursion boundary.

General arbitrary Lean termination elaboration is not required by psc2-language-v1.

A future profile or Standard prover/extension may provide richer well-founded-recursion syntax or proof automation while preserving the same logical theory.

A termination proof and a functional-correctness proof are distinct claims.

# 18. Basic do notation

Ordinary do notation is part of psc2-language-v1.

The required subset supports ordinary sequencing over the selected Bind/Pure semantics, including:

- a term statement;
- a simple let binding;
- identifier or wildcard monadic binding;
- return/pure-style completion expressible by the selected native do category.

Its meaning is the selected native monadic/effect sequencing meaning.

It is not a JavaScript statement block.

The required PSC2 subset does not include dedicated syntax for:

- let mut;
- reassignment;
- for;
- while;
- break;
- continue;
- arbitrary refutable do-pattern binding.

Those are Post-PSC2 language candidates or official-extension candidates.

# 19. Primitive and data semantics

## 19.1 Nat

Nat denotes exact nonnegative natural numbers.

Nat subtraction truncates at zero.

Division and remainder use the selected pinned semantics.

## 19.2 Int

Int uses the selected exact mathematical integer semantics.

Signed division and remainder preserve the selected pinned behavior.

## 19.3 Fixed-width integers

Supported fixed-width and target-word integer types preserve their declared width, wrap/check behavior, shifts, and conversions.

A backend host integer representation does not define source semantics.

## 19.4 Float and Float32

Floating-point values follow the selected pinned floating semantics, including relevant rounding, NaN, infinities, and signed zero behavior.

They are not mathematical real numbers.

## 19.5 Bool

Bool is distinct from Prop.

A Boolean true value is not automatically proof evidence for an arbitrary proposition.

## 19.6 Char, String, ByteArray

These types retain their pinned semantic meanings.

A host UTF-16 string representation does not redefine ProofScript String semantics.

## 19.7 Standard data families

The language recognizes the native semantic distinctions among families such as:

- Unit;
- Prod;
- Sum;
- Option;
- Except;
- List;
- Array;
- Fin;
- subtypes.

Libraries may define additional collections without adding language primitives.

## 19.8 Operators and equality

The fixed Standard notation closure uses the selected pinned precedence and associativity rules unless an owned ProofScript production in this document says otherwise.

The equality distinction is fundamental:

~~~text
x = y     proposition / equality type
x == y    Bool-valued equality when the selected BEq-like operation exists
~~~

A Bool-valued comparison does not silently become a proposition.

Arithmetic, comparison, Boolean, and other fixed Standard operators denote the declarations selected by the Standard registry. They do not acquire JavaScript numeric/coercion semantics.

ps-standard-0.9-r3 does not permit ordinary dependencies to introduce new operator notation. The extensible profile may declare notation as part of its explicit grammar/environment identity.

# 20. Propositions and proof source

ProofScript source may contain propositions and proof terms using the selected logical foundation.

psc2-language-v1 includes:

- theorem declarations;
- by proof blocks;
- ordinary proof terms;
- have;
- show;
- suffices;
- calc;
- equality reasoning required by the supported proof surface.

The language requirement is proof-term meaning. Tactic-name breadth is a Standard-profile selection and does not create a second logical theory.

psc2-standard-language-v1 selects a fixed Standard prover surface. The fixed tactic heads for this profile are:

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

These tactics may fail, search, or construct proof terms according to their selected Standard semantics. The form simp only is a fixed variant of simp. Explicit classical proof mode is also part of the Standard prover surface. Successful theorem acceptance still requires a valid proof term.

Additional tactic names are not automatically Standard merely because a package is installed.

# 21. Notation, attributes, and options

ps-standard-0.9-r3 uses a fixed notation/attribute registration closure.

Ordinary source may use the notation already selected by that closure.

Ordinary dependencies cannot add new notation to Standard.

The Standard attribute names selected for this edition are:

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

Registering a new attribute handler is not Standard source behavior.

Attributes may guide elaboration, optimization, printing, or proof construction according to their selected semantics; they do not independently prove propositions.

## 21.1 Options

ps-standard-0.9-r3 permits set_option only for option names selected by the fixed Standard registration closure.

An unknown or unselected option rejects.

An option may affect elaboration, diagnostics, reduction/transparency, or other source-observable behavior only according to its selected pinned semantics.

Ordinary dependencies cannot register new Standard options.

Interactive commands such as #check, #print, #reduce, and #eval are tooling commands, not psc2-language-v1 program declarations.

# 22. Pure contracts

ProofScript defines one stable base contract surface for total pure functions.

Grammar:

~~~ebnf
ContractClause :=
    "requires" PSTerm
  | "ensures" Ident "=>" PSTerm

ContractedFunction :=
  FunctionHeader ContractClause* DefinitionBody
~~~

Example:

~~~proofscript
function debit(balance: Nat, amount: Nat): Except String Nat
  requires amount <= balance
  ensures result =>
    match result with {
      | .ok next => next = balance - amount
      | .error _ => False
    }
:=
  .ok(balance - amount)
~~~

Semantics:

For a function f : A -> B,

~~~text
requires Pre
ensures result => Post
~~~

denotes the proof obligation:

~~~text
forall x : A, Pre(x) -> Post(x, f(x))
~~~

for the corresponding binder structure.

Rules:

- multiple requires clauses conjoin;
- multiple ensures clauses conjoin;
- no requires clause means True;
- no ensures clause means no functional postcondition claim;
- the postcondition refers to the actual admitted function definition;
- changing the function or a referenced predicate changes the contract proposition;
- a contract is proof-level semantics, not automatic runtime validation.

Base r3 does not add dedicated syntax for:

- assert;
- loop invariant;
- old;
- ghost state;
- async contracts;
- effect trace contracts.

Those are Post-PSC2 language candidates.

# 23. psc2-language-v1 exact coverage

This section is the exact language capability closure required for a compiler to claim psc2-compiler-v1.

A required item cannot be omitted while retaining that claim.

| Family | psc2-language-v1 |
|---|---|
| lexical/native identifiers/literals/comments | required |
| modules/imports/qualified names | required |
| public import / transitive module re-export | required |
| namespace/section/open/variable/include/omit/universe | required |
| private declaration visibility | required |
| attribute command over registered attributes | required |
| set_option over registered options | required |
| interactive #check/#print/#reduce/#eval | tooling only; not psc2-language-v1 declarations |
| def | required |
| const | required |
| function | required |
| single-term braced def/const/function bodies | required |
| theorem/example | required |
| abbrev | required |
| opaque | required |
| axiom | required, with explicit assumption status |
| structure/class/instance | required |
| inductive/constructors/projections | required |
| explicit/implicit/strict-implicit/instance binders | required |
| lambdas/let/application | required |
| parenthesized/named/default/empty calls | required |
| generalized field notation | required |
| record construction/update | required |
| local where declarations | required |
| parenthesized/tuple/type-ascription terms | required |
| forall/exists/dependent-function syntax | required |
| native/braced if | required |
| psc2-pattern-v1 single-scrutinee match | required |
| basic do notation | required |
| structural/local/mutual recursion | required |
| partial def boundary | required |
| noncomputable logical declarations | required |
| unsafe | excluded from psc2-language-v1 and Standard; explicit extensible/host profiles only |
| typeclass search/ordinary instances | required |
| Lean-compatible coercion insertion | required |
| Prop/Type/Sort/universes/Pi/Eq | required |
| by/proof terms/have/show/suffices/calc | required |
| pure requires/ensures contracts | required |
| multi-scrutinee match | not required |
| equation-style definition sugar | not required |
| if-let / let-pattern / rich do-pattern sugar | not required |
| let mut / assignment / for / while / break / continue | not required |
| arbitrary Lean syntax/macros/elaborators | excluded |
| arbitrary quotation/Meta source | excluded from psc2-language-v1; extensible profile only |
| custom parser categories | excluded from psc2-language-v1; extensible profile only |
| arbitrary user attribute handlers | excluded from psc2-language-v1; extensible profile only |
| deriving framework | not required |
| arbitrary well-founded-recursion elaboration | not required |
| async/await/using/defer syntax | not current language |
| JSX/UI syntax | not current language |
| stateful/loop/async contract sugar | not current language |

This table is the closure rule. "Useful in Lean" is not an implicit inclusion rule.

## 23.1 Explicit ownership of broader PSC2 plans

The following table records where broader PSC2 research capabilities live without turning them into hidden psc2-language-v1 requirements.

| Capability family | Current language/profile status |
|---|---|
| multi-scrutinee match, pattern alternatives, if-let, rich pattern bindings | Post-PSC2 language / official-extension candidates |
| equation-style function definitions | Post-PSC2 language / official-extension candidate |
| let mut, assignment, for, while, break, continue | Post-PSC2 language candidates over explicit state/iteration semantics |
| typed recovery/try syntax | not current syntax; Except/application-error libraries first, future sugar optional |
| generic reader/state/error/effect abstractions | Standard libraries; no new language semantics required |
| Task/App/Fiber/Resource/Stream APIs | Standard library/runtime semantics; no current dedicated keywords |
| async/await/using/defer | Post-PSC2 language candidates |
| have/show/suffices/calc | current proof source |
| refine/exact?/by_cases/by_contra/exfalso/subst/generalize/dsimp/rcases/rintro/obtain/use/ext | psc2-standard-language-v1 Standard prover surface |
| rw/simp/simpa/simp only/cases/induction | psc2-standard-language-v1 Standard prover surface |
| omega/grind | selected Standard prover automation |
| ring/linarith/SMT/AI/general search families | libraries or controlled prover plugins unless a later Standard profile selects them |
| classical proof mode | psc2-standard-language-v1 Standard prover surface |
| fixed notation and fixed attributes | psc2-standard-language-v1 closed registration set |
| deriving | future official extension or controlled extension; not psc2-language-v1 |
| arbitrary macros/custom syntax/custom elaborators/Meta authoring | ps-lean-extensible or later controlled extension; not Standard |
| interactive #check/#print/#reduce/#eval | tooling profile, not program declarations |
| assert/invariant/old/ghost/stateful/effectful/async contract syntax | Post-PSC2 verification-language candidates |
| verification-condition generation | prover/library process; not source semantics by itself |
| runtime contract checking | Standard library/diagnostic facility; not proof |
| FFI declarations, generated npm/WIT/Rust bindings | host/interop profiles; not base language semantics |
| quotient/extensionality theorem support | pinned logical foundation plus libraries/prover theorems; no separate PSC2 syntax required |
| kernel-provider choice or dual checking | assurance policy; not source language |
| self-hosting/compiler generations | implementation/release topic; not source language |

# 24. lean-subset-psc2-v1

The .lean frontend for PSC2 is a compatibility frontend, not a claim of full Lean source support.

It must accept the native Lean spellings corresponding to the psc2-language-v1 semantic families where an exact canonical mapping exists.

Required compatibility families:

- ordinary import and public import module headers;
- def, theorem, example, abbrev, opaque, axiom;
- supported declaration modifiers;
- explicit, implicit, strict-implicit, and instance binders;
- supported universe applications;
- structures, classes, instances, inductives, constructors, projections;
- record construction/update;
- lambdas, lets, applications, literals, native conditionals, match;
- psc2-pattern-v1;
- basic do notation;
- structural/local/mutual recursion;
- partial and noncomputable boundaries supported by psc2-language-v1;
- selected propositions/equality/primitives;
- proof terms and the fixed Standard prover forms when psc2-standard-language-v1 is selected.

Excluded from lean-subset-psc2-v1:

- arbitrary syntax;
- macro and macro_rules;
- declare_syntax_cat;
- arbitrary notation declarations;
- arbitrary parser extensions;
- custom term/command/tactic elaborators;
- unrestricted quotations/metaprogramming;
- arbitrary environment extensions;
- unsupported attributes/commands;
- arbitrary deriving handlers;
- arbitrary Lean compiler intrinsics;
- unsupported termination/compiler extensions;
- source forms whose meaning cannot be mapped exactly to the selected ProofScript semantic profile.

Unsupported Lean input rejects explicitly.

# 25. psc2-standard-language-v1

psc2-standard-language-v1 is the language-facing Standard profile used by the PSC2 distribution.

It consists of:

~~~text
psc2-language-v1
+ ps-standard-0.9-r3 closed grammar
+ the fixed Standard notation/attribute closure
+ the fixed Standard prover surface listed in this document
~~~

Ordinary libraries can add declarations, types, functions, theorems, instances, and data.

They cannot mutate Standard grammar.

A library feature can be part of the PSC2 user experience without becoming a compiler-core language construct.

Examples include:

- collection libraries;
- codecs;
- parser libraries;
- application-effect libraries;
- resource libraries;
- stream libraries;
- theorem libraries;
- proof automation implemented behind the fixed Standard proof surface;
- foreign-interface libraries.

# 26. Feature ownership rule

When considering a capability for ProofScript, use this language-design rule:

1. if ordinary functions/types/theorems can express it, it is a library capability;
2. if it is only ergonomic surface over existing semantics, it may become an official syntax extension;
3. if it constructs proofs, it may be a prover/tactic capability without becoming trusted language theory;
4. if it needs controlled compile-time participation, it belongs to an explicit extensible/official-extension profile;
5. if it is foreign or target-specific, it belongs to an FFI/host boundary;
6. only a capability that changes genuine source/type/core meaning belongs in the base language.

This rule is semantic ownership, not an implementation prescription.

# 27. Post-PSC2 language roadmap

Post-PSC2 work is divided into language evolution and platform evolution.

Only language evolution is listed here.

None of the following syntax exists in ps-0.9-r3 unless separately stated.

## L1. Rich matching and definition ergonomics

Candidates:

- multi-scrutinee match;
- pattern alternatives;
- record patterns;
- if let;
- let-pattern and do-pattern bindings;
- equation-style function definitions.

Rule: these must lower to the same inductive/elimination semantics and may not create a second pattern theory.

## L2. Imperative-looking local control flow

Candidates:

- let mut;
- assignment;
- for;
- while;
- break;
- continue.

Rule: these must be syntax over explicit owned state/effect/iteration semantics, not JavaScript mutation semantics.

## L3. Richer verification syntax

Candidates:

- verified assert;
- loop invariant;
- decreasing convenience syntax;
- old/pre-state;
- ghost declarations;
- stateful/effectful postconditions;
- async/trace contracts.

Rule: accepted proof claims must reduce to explicit propositions/program logic over the existing trusted logical foundation.

## L4. Application-effect syntax

Candidates over the separately specified Standard application semantics:

- async;
- await;
- using;
- defer;
- structured concurrency sugar;
- stream iteration sugar.

Rule: syntax may not redefine cold/start, error, cancellation, cleanup, capability, or stream behavior.

## L5. Controlled language extensions

Candidates:

- official deriving syntax;
- fixed new notation families;
- controlled compile-time reflection syntax;
- versioned official macro-like conveniences.

Rule: ps-standard remains closed for each version. New registrations require a new Standard profile/version rather than dependency-driven grammar mutation.

## L6. UI dialects

Possible .psx or other UI syntax may be researched as a separate dialect.

A UI dialect must define:

- its own grammar identity;
- lowering to ordinary ProofScript semantics;
- foreign/runtime assumptions;
- interaction with Standard grammar.

## L7. Additional native compatibility

A later Lean compatibility profile may accept more Lean syntax.

It must remain explicitly bounded. Full Lean parser/macro/Meta compatibility is not implied by PSC2 or by this roadmap.

# 28. Grammar summary

The grammar below specifies the ProofScript-owned r3 forms. PSTerm, PatternGroup, BinderIdent, NativeNonExplicitBinder, CallableHead, StructField, ClassField, ConstructorBody, InstanceField, and WhereField denote pinned native categories restricted by the selected profile. CallableHead must be a completed callable term at the parenthesized-call postfix boundary.

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
  "function" Ident NativeNonExplicitBinder* (ExplicitGroup | EmptyExplicitGroup) (":" PSTerm)?

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

## 28.1 Parenthesized-call ownership

A parser must group a completed callable head followed by CallGap and ( as one ProofScript parenthesized-call form.

Conceptually:

~~~text
head CallGap "(" ")"        => empty call
head CallGap "(" args ")"   => nonempty call
~~~

A physical line break terminates this owned relation.

## 28.2 Category-specific separators

| Category | Separator | Trailing separator |
|---|---|---|
| nonempty parenthesized call | comma | allowed |
| nonempty explicit parameter group | comma | allowed |
| braced def/const/function body | exactly one PSTerm | not applicable |
| structure fields | comma | rejected |
| class fields | comma | rejected |
| inductive constructors | leading bar | not applicable |
| match alternatives | leading bar | not applicable |
| instance fields | native semicolon | allowed |
| local where declarations | native semicolon | allowed |
| native do/tactic sequences | native category rule | native category rule |

There is no universal ProofScript semicolon or trailing-comma rule.

# 29. Canonical examples

## 29.1 Values and functions

~~~proofscript
const answer: Nat := {
  42
}

function add(x: Nat, y: Nat): Nat := {
  x + y
}

function greet(name: String := "world"): String :=
  "Hello, " ++ name

function now(): Time := {
  clockValue
}
~~~

The braced and unbraced declaration-body forms are equivalent; short definitions may still use `:= term`.

Calls:

~~~proofscript
add(1, 2)
add (1, 2)
greet()
now()
tupled((1, 2))
~~~

## 29.2 Structures

~~~proofscript
structure User where {
  id: Nat,
  name: String,
  active: Bool
}

function activate(user: User): User := {
  { user with active := true }
}
~~~

## 29.3 Classes and instances

~~~proofscript
class Sized(α: Type) where {
  size: α -> Nat
}

instance : Sized String where {
  size(s: String): Nat := s.length;
}
~~~

## 29.4 Inductive and match

~~~proofscript
inductive Result(ε: Type, α: Type) where {
  | ok(value: α)
  | error(error: ε)
}

function unwrapOr(value: Result String Nat, fallback: Nat): Nat :=
  match value with {
    | .ok n => n
    | .error _ => fallback
  }
~~~

## 29.5 Proof

~~~proofscript
theorem addZero(n: Nat): n + 0 = n := by {
  simp
}
~~~

## 29.6 Contract

~~~proofscript
function debit(balance: Nat, amount: Nat): Except String Nat
  requires amount <= balance
  ensures result =>
    match result with {
      | .ok next => next = balance - amount
      | .error _ => False
    }
:=
  .ok(balance - amount)
~~~

## 29.7 Basic do

~~~proofscript
function load(): CompilerM Nat := do {
  let x ← readValue
  pure (x + 1)
}
~~~

This is effect sequencing through the selected Bind/Pure semantics, not a JavaScript statement body.

# 30. Explicit exclusions

ps-0.9-r3 does not define:

- JavaScript truthiness;
- implicit null or undefined;
- native any;
- prototype inheritance as native object semantics;
- arbitrary dynamic property lookup as field notation;
- JavaScript automatic semicolon insertion;
- JavaScript statement blocks;
- TypeScript structural assignability as the native type model;
- TypeScript arrow lambdas as base syntax;
- optional chaining as base syntax;
- Promise as native async semantics;
- async/await/using/defer keywords;
- JSX/UI syntax;
- let mut/assignment/for/while/break/continue;
- arbitrary dependency parser mutation in Standard;
- full Lean syntax/macro/elaborator/Meta parity;
- arbitrary user-defined syntax in Standard;
- trust in foreign declaration files as proof;
- hidden fallback to a weaker semantic profile.

# 31. Language completeness rule

The language specification is complete when every source capability is one of:

- defined directly in this document;
- an explicitly included pinned native category;
- selected by the closed Standard profile;
- assigned to a separately versioned extensible profile;
- listed as Post-PSC2 language work;
- explicitly excluded.

No unlisted Lean, TypeScript, JavaScript, backend, library, compiler, or host feature becomes language behavior by implication.

That is the intended PSC2 boundary: a complete small dependent language and proof surface, plus libraries and controlled extensions above it, rather than a clone of every Lean or TypeScript facility.
