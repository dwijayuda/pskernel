# ProofScript PSC2 Language Reference

Status: **comprehensive research-derived PSC2 draft**

Base language: **PSC1**

Semantic lineage: **Lean 4.34-compatible dependent semantics where PSC1/PSC2 claim compatibility**

Language-source lineage: **ProofScript v0.7 with v0.6.1 as the compatible compiler-ready baseline; v0.8 is not normative for PSC1/PSC2**

PSC2 is a strict extension profile over PSC1. Valid PSC1 programs SHOULD remain valid PSC2 programs. PSC1 remains the small bootstrap language and implementation subset; PSC2 is the first full productivity/adoption profile for everyday programming, theorem proving, research, and contract-based formal verification.

This reference is normative for the **planned PSC2 language profile** where it uses MUST/MUST NOT/SHOULD/SHOULD NOT/MAY. It is still a design draft until executable conformance gates close.

---

## 1. Purpose

ProofScript PSC2 is designed to be:

- a general-purpose programming language;
- a theorem-proving language;
- a formal-verification language;
- a practical source language for TypeScript/JavaScript developers;
- a low-friction migration target for Lean programmers and researchers;
- portable across TypeScript/JavaScript, Rust, and WebAssembly through one target-neutral executable IR;
- extensible through libraries, tactics, Meta code, controlled plugins, and FFI without continually enlarging the trusted kernel.

PSC2 deliberately does **not** pursue feature-count parity with Lean or TypeScript. It standardizes facilities whose absence would make ordinary programming, theorem development, verification, or migration disproportionately painful.

The central design rule is:

```text
library
  -> syntax/desugaring
  -> elaborator/Meta/tactic
  -> controlled plugin
  -> standardized semantic extension
  -> kernel change only when unavoidable
```

PSC2 succeeds when the user-facing platform grows substantially while the semantic core and trusted checker remain small and understandable.

---

## 2. Relationship to PSC1

PSC1 is the permanent small bootstrap foundation.

PSC2 inherits PSC1 unless this reference explicitly adds, strengthens, or standardizes a capability.

Conceptually:

```text
PSC1
  functions
  structures / inductives
  dependent functions
  Prop / proofs
  basic pattern matching
  bounded typeclasses
  structural recursion
  concrete effects
  modules/imports
  CheckedCore / VerifiedIR path

    +

PSC2
  programming ergonomics
  library-scale namespaces/typeclasses
  mature proof structuring and simplification
  contracts / VC generation
  controlled notation/attributes/plugins
  practical recursion/termination
  theorem-research conveniences
  target-neutral async/task platform
```

PSC2 MUST NOT silently change PSC1 semantics merely because a richer syntax is introduced.

A PSC2 source feature that can be expressed by elaborating/desugaring to PSC1 mechanisms SHOULD do so.

---

## 3. Normative architecture

All verified PSC2 source follows one semantic path:

```text
.ps / supported .lean
        |
        v
source-kind parser
        |
        v
canonical syntax / resolved names
        |
        v
Meta / elaboration / desugaring
        |
        +-> tactics / simplifier / deriving / VC generation
        |
        v
canonical dependent core
        |
        v
selected kernel provider
        |
        v
CheckedCore
        |
        v
proof/spec erasure
        |
        v
target-neutral VerifiedIR
        |
   +----+------+----+
   |           |    |
   v           v    v
  TS          Rust  Wasm
```

No backend may accept a source feature by inventing target-specific semantics upstream of CheckedCore/VerifiedIR.

Proof-only declarations may stop after kernel admission and need not produce executable IR.

---

## 4. Trust boundary

The logical trusted computing base SHOULD remain as small as practical.

Outside the logical TCB:

- lexer/parser;
- name resolver;
- elaborator/Meta implementation;
- pattern compiler;
- typeclass search;
- coercion insertion;
- notation expansion;
- deriving;
- tactics;
- simplifier;
- arithmetic/general proof automation;
- contract parser and VC generator;
- plugin implementation;
- erasure/optimizer;
- TS/Rust/Wasm backends;
- host runtime and FFI;
- package manager;
- LSP/editor/tooling.

These components may generate candidate terms, declarations, proofs, specifications, or executable IR. They do not decide logical truth.

Only the selected kernel/provider may grant kernel admission.

A bug in a tactic, simplifier, plugin, or VC generator MUST NOT be sufficient to admit an invalid theorem.

---

## 5. Design laws

### 5.1 Small semantics, rich platform

A large standard library or prover does not justify a large kernel.

### 5.2 One mechanism before multiple features

Prefer:

- one function model;
- structures/inductives for data;
- one core match/elimination model;
- one dependent type theory;
- one proof-term model;
- one target-neutral effect model per standardized effect;
- one CheckedCore path;
- one VerifiedIR meaning across executable backends.

### 5.3 Familiar syntax without foreign semantics

PSC2 may provide familiar TypeScript-like ergonomics such as method calls, updates, loops, local mutation syntax, async/await, and named/default arguments, but these MUST have ProofScript semantics.

PSC2 MUST NOT import JavaScript truthiness, prototypes, `this`, `any`, implicit `null`/`undefined`, floating `number` semantics for exact integers, or Promise semantics as the language definition.

### 5.4 Lean compatibility without Lean implementation identity

PSC2 SHOULD make common Lean source and theorem idioms inexpensive to migrate, but `.ps` need not expose every Lean parser/metaprogramming mechanism.

### 5.5 Fail closed

Unsupported or ambiguous syntax, elaboration, pattern motives, coercions, plugin capabilities, verification conditions, or backend mappings MUST fail with a diagnostic.

Silent fallback to weaker/unverified semantics is forbidden.

---

## 6. Normative wording and status labels

The words **MUST**, **MUST NOT**, **SHOULD**, **SHOULD NOT**, and **MAY** are normative when capitalized.

An **OPEN FREEZE OBLIGATION** marks behavior that PSC2 intends to support but whose exact source/runtime contract is not yet frozen.

An **OPTIONAL PROFILE** is not required for the smallest PSC2 implementation but is standardized enough that an implementation claiming that profile must follow this reference.

---

## 7. Surface feature classes

PSC2 preserves PSC1's source classification:

| Class | Meaning |
| --- | --- |
| L | Lean-compatible surface form within the claimed `.lean`/shared profile. |
| D | Conservative ProofScript decoration with canonical Lean/core meaning. |
| E | ProofScript-owned spelling with deterministic lowering. |
| X | Forbidden semantic divergence in portable verified source. |

To describe implementation location without colliding with these letters, this reference uses the full words:

- **LIBRARY**;
- **SYNTAX**;
- **ELAB**;
- **TACTIC**;
- **PLUGIN**;
- **VERIFY**;
- **KERNEL**.

A feature may belong to more than one implementation class.

---

## 8. Source kinds

### 8.1 `.ps`

`.ps` is the native ProofScript source format.

Its goals are:

- small regular surface;
- TypeScript-friendly function-call ergonomics where useful;
- Lean-compatible proof/type semantics;
- explicit portability and verification boundaries.

### 8.2 `.lean`

`.lean` is a Lean-compatible source frontend.

PSC2's `.lean` support SHOULD grow substantially beyond the PSC1 bounded subset, especially for common programming and theorem source.

The `.lean` frontend MAY support syntax not exposed natively in `.ps`, provided accepted constructs canonicalize to the claimed PSC2/Lean-compatible semantics.

PSC2 MUST NOT claim full Lean source compatibility until executable compatibility gates establish it for the claimed version/profile.

### 8.3 `.psx`

Where the project retains a mixed/unverified source profile, `.psx` MAY host explicit target-specific or unverified escape hatches.

Such code MUST NOT silently inherit the proof/portability claims of verified `.ps` code.

---

## 9. Contextual keywords and PSC1 compatibility

PSC2 introduces additional source words such as:

```text
abbrev opaque namespace section variable open
for while break continue
requires ensures invariant decreasing assert
async await deriving
noncomputable classical
```

To preserve PSC1 source compatibility, new PSC2 words SHOULD be contextual keywords wherever deterministic parsing permits it.

An identifier valid in PSC1 SHOULD NOT become invalid in unrelated syntactic positions merely because PSC2 introduces a new construct with the same spelling.

---

## 10. Lexical and punctuation rules

PSC2 inherits PSC1 lexical rules.

Key meanings remain:

- `:=` — definition/binding/update syntax in owned contexts;
- `=` — propositional equality;
- `==` — Boolean equality through supported `BEq`-style machinery;
- `->` — function/dependent-function arrow;
- `=>` — lambda/pattern/contract binder separator where defined;
- braces — category-specific owned blocks, not universal JavaScript blocks;
- semicolons — category-specific ProofScript termination/separation, never globally erased.

Whitespace remains significant for PSC1 D-CALL ownership:

```proofscript
f(x)      -- ProofScript adjacent call
f (x)     -- Lean-neighbor syntax, not the same lexical form
```

Implementations MUST parse syntax structurally, not by global textual rewriting.

---

## 11. Foundational types

PSC2 retains the PSC1 foundational vocabulary:

```text
Nat Int
UInt8 UInt16 UInt32 UInt64 USize
Int8 Int16 Int32 Int64 ISize
Float Float32
Bool Char String Unit
```

PSC2 MUST NOT introduce a JavaScript-like universal numeric `number` type that collapses these semantics.

`Nat` and `Int` retain exact mathematical integer semantics.

Fixed-width integer overflow/conversion follows the frozen PSC scalar contract, not backend defaults.

`Float`/`Float32` proofs and contracts apply only to the formally specified floating behavior; source verification MUST NOT silently reason as though floating-point values were mathematical reals.

---

## 12. Core collection/data vocabulary

The standard distribution SHOULD provide at least:

- `List`;
- `Option`;
- `Prod`/tuples;
- `Array`;
- ordered map/set families;
- `Result`/`Except`-style errors;
- strings and byte-oriented data abstractions;
- the iteration abstractions needed by PSC2 `for`.

These are principally libraries/runtime data, not reasons to add new kernel term forms.

---

## 13. Declarations

### 13.1 `def`

`def` remains the canonical ordinary definition declaration.

```proofscript
def answer: Nat := 42;

def add(x: Nat, y: Nat): Nat :=
  x + y;
```

### 13.2 `const`

`const` remains a parameterless `def` alias.

```proofscript
const answer: Nat := 42;
const inc: Nat -> Nat := fun n => n + 1;
```

`const` does not mean JavaScript object immutability; ProofScript values already follow their own immutable/value semantics.

### 13.3 `function`

`function` remains a parameterized `def` alias.

```proofscript
function add(x: Nat, y: Nat): Nat := x + y;
```

It does not introduce JavaScript hoisting, prototypes, `this`, or statement-body semantics.

### 13.4 `abbrev`

PSC2 standardizes transparent aliases:

```proofscript
abbrev UserId := Nat;
```

An `abbrev` MUST use the selected core/profile's ordinary transparency rules and MUST NOT be only pretty-printer metadata.

### 13.5 `opaque`

PSC2 standardizes explicit opaque definitions when supported by the selected kernel profile:

```proofscript
opaque implementationDetail(x: Nat): Nat := ...;
```

Opacity affects definitional unfolding/transparency and therefore is semantically significant.

### 13.6 `theorem`

```proofscript
theorem addZero(n: Nat): n + 0 = n := by {
  simp
}
```

A theorem body constructs proof evidence. The theorem's executable body normally erases.

### 13.7 `example`

PSC2 SHOULD support Lean-style scratch declarations for interactive theorem development:

```proofscript
example(n: Nat): n = n := by {
  rfl
}
```

`example` checks like a theorem/definition but does not introduce a public declaration name.

### 13.8 `axiom`

PSC2 MAY expose explicit axiom declarations for theorem research and compatibility:

```proofscript
axiom trustedFact: P;
```

Axioms extend the logical assumption boundary. Build/check artifacts MUST report non-foundational user axioms rather than disguising them as proved theorems.

### 13.9 `partial def`

`partial def` remains runtime-oriented.

A partial definition MUST NOT be used as an unchecked route to manufacture proof evidence or kernel definitional computation.

### 13.10 `unsafe`

A Lean-compatible or mixed profile MAY accept runtime-only `unsafe` declarations.

`unsafe` code is outside the verified portable semantics and MUST NOT gain proof authority.

Verified `.ps` SHOULD prefer explicit FFI/capability boundaries rather than pervasive unsafe code.

---

## 14. Visibility and API boundaries

PSC2 requires practical library visibility.

The native profile SHOULD provide:

- public declarations (default unless project policy says otherwise);
- `private` declarations with deterministic generated identity;
- explicit public re-export;
- module/package interface generation.

Visibility changes name accessibility, not the logical meaning of an admitted declaration.

---

## 15. Namespaces and sections

PSC2 requires scalable organization.

Native `.ps` may use owned braced blocks:

```proofscript
namespace Http {
  def defaultPort: Nat := 443;
}
```

The `.lean` frontend accepts the corresponding Lean syntax in its claimed profile.

PSC2 SHOULD support:

- `namespace`;
- `open`;
- `section`;
- shared `variable` declarations;
- local/scoped instances and notation;
- deterministic re-export/import conveniences.

Example:

```proofscript
section {
  variable {α: Type};

  theorem idEq(x: α): x = x := by {
    rfl
  }
}
```

Section conveniences MUST elaborate away before kernel admission.

---

## 16. Universe polymorphism

PSC2's theorem/research profile requires practical explicit universe syntax.

```proofscript
universe u v;

function id {α: Type u}(x: α): α := x;
```

Supported universe expressions MUST follow the selected Lean-compatible semantic profile, including the operations required by dependent polymorphic libraries.

Universe declarations are elaboration/source conveniences; universe correctness remains a kernel obligation.

A PSC2 implementation that supports only a bounded bootstrap universe subset MUST NOT claim the full PSC2 theorem/research profile.

---

## 17. Binders

PSC2 retains Lean-compatible binder roles:

```proofscript
(x: A)       -- explicit
{α: Type}    -- implicit
{{α: Type}}  -- strict implicit where supported
[C α]        -- instance implicit
```

Binder order is semantically significant.

Dependent binders retain ordinary Pi semantics.

PSC2 does not replace dependent binders with TypeScript generic angle-bracket semantics.

---

## 18. Named arguments

PSC2 supports named arguments:

```proofscript
connect(host, timeout := 5000, retries := 3)
```

Rules:

1. the parameter name must be part of the declaration's stable source API;
2. unknown names are errors;
3. duplicate arguments are errors;
4. elaboration inserts arguments in declaration order;
5. dependent parameters are elaborated respecting dependency order even if source names appear later;
6. ambiguity MUST fail rather than choose by backend/source order.

Named arguments disappear before kernel admission.

---

## 19. Default arguments

PSC2 supports default parameter values:

```proofscript
function connect(host: String, timeout: Nat := 5000): Connection := ...;
```

An omitted optional parameter is elaborated by inserting the declared default expression.

Defaults do not create a second function type or runtime overloading mechanism.

A default expression MUST type-check in the declaration context.

---

## 20. Functions and lambdas

PSC2 retains PSC1 function semantics:

```proofscript
fun x => x + 1
fun (x: Nat) => x + 1
```

ProofScript does not require JavaScript/TypeScript arrow-lambda spelling in `.ps`.

Higher-order functions, polymorphic functions, and dependent functions remain first-class according to the selected executable/erasure profile.

---

## 21. Function application

PSC1 adjacent calls remain valid:

```proofscript
add(1, 2)
map(f, xs)
```

Multiple arguments retain curried semantic application, not an n-ary primitive kernel operation.

---

## 22. Generalized field/method notation

PSC2 standardizes static generalized field notation:

```proofscript
user.name
xs.map(f)
builder.append(text)
```

This is **ELAB**, not JavaScript prototype dispatch.

Preferred native resolution:

1. resolve an actual structure projection when applicable;
2. otherwise derive the static nominal/head type of the receiver;
3. search the associated type/namespace method candidates permitted by the PSC2 resolution rules;
4. require a unique elaboratable candidate whose receiver parameter accepts the receiver;
5. elaborate `x.f(a, b)` to ordinary application such as `T.f(x, a, b)`;
6. fail on ambiguity.

Runtime dynamic property lookup is not part of portable PSC2 semantics.

The `.lean` compatibility frontend MAY follow the compatible Lean generalized-field behavior for the claimed Lean profile, but canonical output must still be an ordinary term.

---

## 23. Operators and equality

PSC2 inherits PSC1's arithmetic/Boolean operator meaning.

The distinction remains fundamental:

```text
x = y    proposition / equality type
x == y   Bool-valued equality where BEq-like support exists
```

A Boolean comparison does not silently become a proposition.

User-defined operator notation in PSC2 expands to ordinary terms; it does not add arbitrary new primitive reduction rules.

---

## 24. Structures

Structures remain nominal Lean-compatible product-like declarations.

```proofscript
structure Point where {
  x: Float;
  y: Float;
}
```

Record construction:

```proofscript
const origin: Point := { x := 0, y := 0 };
```

Generated constructors/projections and dependent fields follow the selected kernel semantics.

---

## 25. Structure update

PSC2 requires immutable copy-with-update:

```proofscript
const next := { state with count := state.count + 1 };
```

Multiple updates are allowed:

```proofscript
const next := {
  state with
  count := state.count + 1,
  dirty := true
};
```

The update elaborates to ordinary projection/constructor operations.

It does not create JavaScript object spread semantics, prototype copying, property descriptors, or identity mutation.

---

## 26. Inductive types

PSC2 retains PSC1 Lean-compatible inductive semantics.

```proofscript
inductive Result(α: Type, ε: Type) where {
  | ok(value: α);
  | error(error: ε);
}
```

PSC2 Standard SHOULD support practical mutual inductive declarations when admitted by the selected kernel profile.

Dependent/indexed inductives required by theorem libraries MUST retain their dependent elimination semantics.

---

## 27. Quotients and standard theorem foundation

For a serious Lean-class theorem profile, PSC2 MUST have a standardized quotient/extensionality story.

Preferred architecture:

```text
small PSC kernel core
  + standardized Quot/theorem extension when required
```

or an equivalent small-kernel design with the same claimed logical behavior.

If the small PSC kernel profile does not support the required quotient semantics, code depending on them MUST explicitly require the appropriate standardized extension or Lean-compatible kernel provider.

PSC2 MUST NOT claim broad Lean/mathlib theorem compatibility while silently omitting foundational facilities required by those proofs.

---

## 28. Classes and instances

PSC2 classes remain typeclasses, not object-oriented classes.

```proofscript
class Sized(α: Type) where {
  size: α -> Nat;
}
```

PSC2 strengthens PSC1's bounded instance machinery to support library-scale use.

Standard requirements:

- recursive instance synthesis;
- cycle/depth control;
- deterministic priorities;
- local/scoped/imported instances;
- deterministic ambiguity errors;
- output-parameter behavior when required by the compatibility profile;
- transactional rollback on failed candidates.

Instance search is **ELAB**, not kernel authority.

---

## 29. Coercions

PSC2 supports controlled type-directed coercion insertion.

Coercions MUST be:

- statically resolved;
- bounded/cycle checked;
- deterministic;
- visible to diagnostics/tooling;
- translated to ordinary applications before kernel checking.

PSC2 does not import JavaScript implicit numeric/string/Boolean coercions.

---

## 30. Pattern language

PSC2 requires a practical pattern compiler.

Pattern forms SHOULD include:

- wildcard `_`;
- variable patterns;
- constructor patterns;
- nested constructor patterns;
- tuple/product patterns;
- literal patterns where semantically owned;
- alternatives where every alternative binds a compatible variable set;
- multi-scrutinee patterns;
- patterns in `let`, `do`, and `if let`;
- equation-style function clauses.

Example:

```proofscript
function valueOr(x: Option (Result Error Nat), fallback: Nat): Nat :=
  match x with {
    | .some (.ok n) => n;
    | _ => fallback;
  };
```

Rich patterns MUST compile to ordinary matches/eliminators/decision trees.

For dependent matches, the pattern compiler MUST synthesize a valid motive or fail with a diagnostic. It must not approximate dependent semantics.

---

## 31. Multi-scrutinee matching

PSC2 supports multiple scrutinees as source sugar:

```proofscript
match x, y with {
  | .some a, .some b => f(a, b);
  | _, _ => fallback;
}
```

The construct lowers to a deterministic decision tree or nested primitive matches.

Evaluation order MUST be defined by PSC2 source semantics and preserved across backends.

---

## 32. `if let` and pattern bindings

PSC2 SHOULD support:

```proofscript
if let .some x := value {
  use(x)
} else {
  fallback
}
```

and pattern bindings where failure behavior is statically defined by the context.

Irrefutable pattern positions MUST reject refutable patterns unless the syntax provides an explicit failure branch/effect.

---

## 33. Equation-style definitions

PSC2 accepts Lean-like equation clauses for functions where the pattern compiler can lower them soundly:

```proofscript
def length: List α -> Nat
  | .nil => 0
  | .cons _ xs => length(xs) + 1;
```

Equation syntax is not a second recursion semantics. It lowers to ordinary function/match/recursor structure.

---

## 34. Conditionals and branch evidence

PSC2 retains ordinary `if`.

Where supported by the dependent elaborator, PSC2 SHOULD also support named condition evidence analogous to Lean's dependent `if` patterns, allowing a branch to use evidence that the condition holds or does not hold.

This is particularly useful for verified programming and is analogous in developer experience to TypeScript control-flow narrowing, while remaining proof-theoretic rather than structural-typing based.

---

## 35. Local definitions

PSC2 retains `let` and `where` and adds practical local recursion.

Local helpers SHOULD not require promotion to top-level declarations merely because the compiler lacks a local recursion surface.

---

## 36. Local and mutual recursion

PSC2 requires practical local recursive and mutual recursive definitions when accepted by the same termination/partiality rules as top-level definitions.

Mutual recursion MUST NOT bypass termination or positivity rules.

---

## 37. Structural recursion

Structural recursion remains the simplest verified recursion mechanism.

When accepted structurally, recursion lowers to ordinary recursor/fixpoint machinery recognized by the selected semantics.

---

## 38. Well-founded recursion

PSC2's theorem/verification profile requires well-founded recursion.

A source form analogous to Lean's termination annotations is standardized:

```proofscript
def f(x: A): B := ...
termination_by measure(x)
```

Additional proof discharge may use an ordinary proof/tactic block.

Termination elaboration SHOULD generate proof obligations; it SHOULD NOT introduce a new trusted oracle.

---

## 39. `partial`

`partial` remains an explicit runtime-only escape for executable recursion that is not admitted as total logical computation.

A theorem MUST NOT become provable merely because a partial function happens to terminate in tests or on a backend.

---

## 40. `do` notation

PSC2 retains effect sequencing through `do`.

`do` is not a JavaScript statement block. Its meaning comes from the owned effect/bind/iteration semantics.

PSC2 Standard SHOULD support generic enough effect interfaces to implement compiler, tactic, parser, state, error, and asynchronous abstractions in libraries.

---

## 41. Local mutable-looking syntax

PSC2 supports imperative-looking local state in `do` contexts:

```proofscript
do {
  let mut total := 0;
  total := total + 1;
  return total;
}
```

Rules:

- mutation is lexically scoped;
- there are no portable raw addresses/references to mutable locals;
- aliasing semantics MUST be explicit if a future extension introduces references;
- elaboration lowers mutable-looking variables to the owned state/control-flow representation;
- the source feature does not change the logical core.

---

## 42. `for`

PSC2 supports `for` in `do`/owned sequencing contexts:

```proofscript
for x in xs {
  consume(x);
}
```

Iteration relies on a target-neutral iterable/`ForIn`-style abstraction.

The source semantics MUST not be defined by JavaScript iterators, Rust iterators, or Wasm instructions.

---

## 43. `while`

PSC2 supports owned `while` loops:

```proofscript
while condition {
  step();
}
```

The condition and body follow the selected `do`/effect semantics.

Verified termination may require a `decreasing` clause when total termination is part of the claim.

---

## 44. `break`, `continue`, and `return`

`break` and `continue` are legal only within supported loop contexts.

`return` is legal only where the enclosing expression/effect syntax defines it.

PSC2 does not introduce unrestricted JavaScript/C early-return statement semantics across arbitrary expression contexts.

These forms lower to structured control-flow/effect mechanisms before VerifiedIR.

---

## 45. Typed error handling

Recoverable errors use `Result`/`Except`-style values/effects.

PSC2 MAY provide syntax such as:

```proofscript
try {
  action()
} catch err {
  recover(err)
}
```

when it lowers to typed ProofScript error/effect semantics.

Host-language exceptions are not the definition of recoverable error semantics.

---

## 46. Effects

PSC2 standard libraries SHOULD provide reusable reader/state/error abstractions and the lifting/composition facilities needed by compiler, tactic, parser, and application code.

Generic effect libraries are ordinary ProofScript libraries unless a specific syntax form requires elaborator participation.

A backend MAY implement effects efficiently but cannot change their observable source meaning.

---

## 47. Task and asynchronous programming

PSC2 Platform defines a target-neutral asynchronous computation abstraction conceptually:

```proofscript
Task A
```

Standard operations SHOULD cover:

- spawn/start;
- join/await completion;
- cancellation;
- race;
- timeout;
- typed failure where applicable.

If native syntax is enabled:

```proofscript
async function load(id: UserId): Task User := ...;

const user := await load(id);
```

`async`/`await` is **SYNTAX/LIBRARY** over Task semantics.

TypeScript backends may use Promise/AbortController/event-loop mechanisms; Rust may use futures/runtime integration; Wasm may use host/component interfaces. Those target mechanisms do not define PSC2 semantics.

**OPEN FREEZE OBLIGATION:** finalize exact cancellation/failure/scheduling observables before claiming backend-neutral Task conformance.

---

## 48. Proposition universe and proofs

`Prop` remains the proposition universe.

A proposition is a type whose inhabitants are proofs under the selected dependent type theory.

PSC2 does not add a separate Boolean proof logic.

Proof terms remain kernel checked and may erase from runtime.

---

## 49. Equality

Propositional equality retains Lean-compatible meaning in the claimed profile.

Definitional equality remains a kernel/meta semantic relation distinct from an explicit proposition `x = y`.

Boolean equality `==` remains distinct from both.

---

## 50. Structured proof terms

PSC2 standardizes the common structured proof vocabulary:

```text
have
show
suffices
calc
```

These are **ELAB/TACTIC** conveniences that construct ordinary proof terms.

### 50.1 `have`

```proofscript
have h: P := proof;
```

introduces a local proof/value.

### 50.2 `show`

`show P from p` or the compatible tactic/term form directs expected-type elaboration.

### 50.3 `suffices`

`suffices` structures a proof around an intermediate goal and elaborates to ordinary local proof dependencies.

### 50.4 `calc`

```proofscript
calc
  a = b := h1
  _ = c := h2
```

elaborates through registered/known transitivity/congruence machinery and ordinary proof terms.

No `calc` step is trusted merely because it appears syntactically.

---

## 51. `classical`

PSC2's theorem profile supports an explicit `classical` proof/elaboration convenience analogous to Lean.

It introduces the standardized classical instances/choice facilities provided by the selected logical library/profile.

`classical` is not an executable backend mode and does not permit arbitrary unsafe computation.

Use of nonconstructive assumptions MUST remain visible to theorem/assumption reporting when relevant.

---

## 52. `noncomputable`

PSC2 supports `noncomputable` declarations/sections for theorem research and mathematical definitions whose construction depends on noncomputable logical choice.

A noncomputable declaration may participate in proofs according to the logical semantics but MUST NOT be emitted as ordinary executable TS/Rust/Wasm code unless a separate executable realization is provided.

Build tooling MUST diagnose reachable noncomputable definitions in executable entry points.

This distinction is essential for low-friction Lean mathematical migration.

---

## 53. Standard tactic layer

PSC2 Standard Prover SHOULD include at least:

```text
exact
assumption
intro
apply
refine
constructor
cases
induction
rfl
rw
simp only
exact?

by_cases
by_contra
exfalso
subst
generalize
change
unfold
dsimp
rcases
rintro
obtain
use
ext
simp
simpa
```

Tactic implementation is outside the TCB.

Every successful tactic sequence must yield a kernel-checkable proof term or explicit certificate whose kernel-checkable reconstruction yields one.

---

## 54. Rewriting

PSC2 requires practical `rw` support:

- forward/reverse rewrite;
- rewrite at goals and selected hypotheses;
- dependent contexts when soundly supported;
- multiple rewrite rules;
- useful diagnostics when no matching occurrence exists.

Rewriting constructs equality-recursion/congruence proof terms; it is not trusted text substitution.

---

## 55. Simplifier

PSC2 Standard Prover requires a mature deterministic simplifier.

Required interface includes:

```text
simp
simpa
simp only
simp at ...
```

Tooling SHOULD provide `simp?`-style suggestions.

The simplifier may use:

- registered simp lemmas;
- congruence lemmas;
- simplification procedures;
- indexes/discrimination structures;
- local hypotheses;
- configured transparency.

But it MUST produce/reconstruct kernel-checkable proof evidence.

A simplifier bug may make a proof fail or produce a rejected term; it must not create truth.

---

## 56. Structured destructuring tactics

PSC2 SHOULD provide the practical functionality associated with:

```text
rcases
rintro
obtain
use
```

These SHOULD share the same underlying pattern engine where practical rather than becoming independent semantic systems.

---

## 57. Cases and induction

PSC2 strengthens `cases`/`induction` for:

- indexed inductive families;
- dependent hypotheses;
- practical naming/pattern control;
- generated equality handling;
- library-scale theorem usage.

The underlying eliminator correctness remains kernel checked.

---

## 58. Advanced proof automation

PSC2's standard ecosystem SHOULD support packages/plugins for common automation such as:

- Presburger/integer arithmetic (`omega`-class);
- linear arithmetic (`linarith`/`lia`-class);
- ring normalization;
- numeric normalization;
- decision procedures;
- general proof search (`aesop`/`grind`-class);
- SMT integration.

These tools are not grammar/kernel requirements.

An external solver result MUST be reconstructed as a proof or accompanied by a certificate checked by trusted/specified code before it contributes to a verified theorem claim.

---

## 59. Attributes and registries

PSC2 provides controlled compile-time metadata.

Typical forms:

```proofscript
@[simp]
theorem ...

@[spec]
theorem ...
```

Standard registries MAY include:

- simp;
- extensionality;
- instances;
- verification specifications;
- deriving handlers;
- deprecation/documentation/tooling metadata.

An attribute is an index/registration mechanism, never logical authority.

Unknown attributes MUST fail unless a loaded controlled plugin defines them.

---

## 60. Notation

PSC2 Standard supports controlled readable notation needed by mathematical and domain libraries.

At minimum:

- prefix;
- postfix;
- infix;
- left/right associativity;
- precedence;
- scoped notation.

Lean-like declaration syntax MAY be reused where this improves migration, for example conceptually:

```proofscript
infixl:65 " ++ " => append;
```

Notation expands into ordinary owned syntax/terms before kernel admission.

PSC2 Standard does not require unrestricted runtime grammar mutation.

---

## 61. Deriving

PSC2 defines a controlled derive interface.

Example conceptual source:

```proofscript
structure User where {
  id: UserId;
  name: String;
}
deriving BEq, Repr
```

Potential standard derives include:

- Boolean/decidable equality where semantically valid;
- ordering where valid;
- representation/debug formatting;
- specified serialization/schema declarations;
- selected proof lemmas.

Generated code/proofs pass through ordinary elaboration and kernel admission.

---

## 62. Meta programming

PSC2's extensibility platform requires a self-hostable Meta API sufficient for:

- expression construction/inspection;
- local contexts;
- metavariables;
- unification/definitional equality requests;
- instance synthesis;
- declaration/environment queries;
- tactic goals;
- diagnostics;
- registered syntax/derive/tactic/spec extensions.

The Meta API may be large while remaining outside the kernel TCB.

PSC2 does not require exact source/API identity with every `Lean.Meta` implementation detail.

---

## 63. Controlled plugins

PSC2 plugins fall into non-authoritative categories:

- syntax/desugaring plugins;
- deriving/codegen plugins;
- Meta/tactic plugins;
- verification/VC/spec plugins;
- backend plugins;
- tooling plugins.

A plugin MAY generate source/core candidates, proofs, declarations, or target lowering.

A plugin MUST NOT override kernel acceptance.

Kernel semantic extensions are not ordinary plugins; they require a versioned semantic proposal and TCB review.

Plugin interfaces SHOULD themselves be implementable in ProofScript.

---

## 64. Interactive/research commands

PSC2 tooling SHOULD support common theorem/program research commands analogous to:

```text
#check
#eval
#reduce
#print
#synth
```

These are developer commands, not runtime language semantics.

`#eval` MUST not be presented as proof evidence.

`#reduce`/normalization results are only logically authoritative to the extent they are checked/recomputed by the semantic/kernel path.

---

## 65. Compiler/prover options

PSC2 MAY support a controlled `set_option`-style command for standardized elaborator/prover/tooling options.

Options that affect semantic acceptance, trust, or verification claims MUST be recorded in build artifacts and MUST NOT silently weaken checks.

---

# Part II — Formal verification

## 66. Verification model

PSC2 makes software contracts first-class source specifications while keeping verification proof-producing.

The model is:

```text
program + contracts
       |
       v
elaborated program/specification
       |
       v
untrusted VC generation
       |
       v
verification conditions : Prop
       |
  +----+-----+----------------+
  |          |                |
manual     tactics          solver
proof      / simp       + reconstruction
  |          |                |
  +----------+----------------+
             |
             v
         proof terms
             |
             v
           kernel
```

The VC generator itself is not proof authority.

---

## 67. Function preconditions: `requires`

PSC2 standardizes:

```proofscript
function withdraw(balance: Nat, amount: Nat): Nat
  requires amount <= balance
  := balance - amount;
```

A `requires` clause denotes a proposition/specification that verified callers must establish.

Multiple `requires` clauses are permitted and are logically conjoined unless the specification abstraction explicitly defines another equivalent composition.

Effectful contracts MAY bind logical assertion arguments such as state:

```proofscript
def clear(): StateM Nat Unit
  requires s => s >= 0
  := do { ... }
```

Binder meaning is defined by the effect's verification model, not backend runtime layout.

---

## 68. Postconditions: `ensures`

PSC2 standardizes:

```proofscript
function withdraw(balance: Nat, amount: Nat): Nat
  requires amount <= balance
  ensures result => result = balance - amount :=
  balance - amount;
```

An `ensures` clause introduces a logical result binder and proposition.

Multiple `ensures` clauses are permitted and compose conjunctively in the standard pure-function model.

For effectful computations, the standard specification interface may additionally bind final logical effect state.

---

## 69. Contract elaboration

Contracts are not runtime wrappers by default.

The compiler separates:

1. executable implementation;
2. logical specification;
3. proof that implementation satisfies the specification;
4. caller obligations arising from preconditions.

A specification record/attribute without proof does not count as verification.

---

## 70. Verified `assert`

Within verified `do` code:

```proofscript
assert index <= xs.size;
```

means:

```text
create proposition obligation
-> discharge it
-> kernel check proof
-> no required runtime effect in verified output
```

Runtime debugging assertions MUST use a distinct API/explicit runtime-contract mode.

A runtime assertion passing is not a theorem.

---

## 71. Loop invariants

PSC2 supports invariants on verified loops.

Conceptual `for` form:

```proofscript
for x in xs
  invariant prefix suffix state => I(prefix, suffix, state)
{
  ...
}
```

The exact binders depend on the standardized loop/effect verification abstraction.

VC generation MUST establish at least:

1. invariant initialization;
2. preservation for each iteration;
3. exit/postcondition facts;
4. obligations introduced by `break`, `continue`, and early `return` where supported.

Loop invariants are logical specifications, not runtime Boolean guards.

---

## 72. `decreasing`

Verified loops and recursion MAY carry a decreasing measure/relation:

```proofscript
while condition
  invariant state => I(state)
  decreasing measure(state)
{
  ...
}
```

Termination evidence SHOULD reuse the same well-founded logical infrastructure used for recursive definitions.

---

## 73. Verification-condition discharge

Automatic VC generation MAY leave named goals.

PSC2 SHOULD support an ordinary proof section for remaining obligations, conceptually:

```proofscript
where finally {
  spec := by {
    ...
  }
}
```

**OPEN FREEZE OBLIGATION:** finalize the exact native `.ps` spelling of final contract proof sections. The `.lean` compatibility frontend may preserve the supported Lean spelling.

Remaining goals are ordinary propositions closed by ordinary proof terms/tactics.

---

## 74. Specification registry

Libraries MAY register kernel-admitted specification theorems for operations.

A `@[spec]`-like registry is an index from an operation/program shape to an admitted theorem/specification.

Registry membership does not confer truth; referenced specification theorems must already be admitted.

---

## 75. Stateful/effectful specifications

A standardized effect MAY define its logical assertion shape.

For state:

```text
precondition  : State -> Prop
postcondition : Result -> State -> Prop
```

is a representative model.

Exact interfaces may be generalized, but source contracts MUST be interpreted through a target-neutral logical effect model.

---

## 76. Error-effect specifications

For `Result`/`Except`, verification SHOULD distinguish success and failure outcomes explicitly.

A postcondition MUST NOT silently assume success unless the precondition/spec proves failures impossible.

Host exceptions are irrelevant to the logical error model unless the FFI adapter explicitly models them.

---

## 77. Async specifications

Contracts on `Task A` describe the logical completion/failure/cancellation model of Task, not JavaScript Promise internals or a particular Rust runtime.

Example:

```proofscript
async function loadUser(id: UserId): Task User
  requires valid(id)
  ensures user => user.id = id :=
  ...;
```

A contract about successful results must account explicitly for cancellation/failure semantics defined by Task.

---

## 78. Pre-state and `old`

PSC2 does not initially require a primitive `old(expr)`.

Preferred first mechanisms:

- explicit initial-state contract binders;
- immutable local values capturing pre-state data;
- proof-only ghost data.

A future `old(...)` syntax MAY be added only after its meaning is unambiguous across pure, stateful, exceptional, and asynchronous computations.

---

## 79. Ghost data

Proof/specification-only data MAY exist during checking.

Rules:

- ghost data must be identifiable before executable lowering;
- runtime computation MUST NOT depend on erased ghost values;
- erasure must fail closed if removing ghost data changes observable runtime behavior;
- a future `ghost` keyword is syntax convenience, not a new logical authority.

---

## 80. Runtime contract checking

Tooling MAY offer runtime evaluation of executable approximations of selected contracts for testing/debugging.

The UI/build manifest MUST state clearly:

```text
runtime contract checked != formally proved
```

Formal verification requires kernel-admitted proof obligations.

---

## 81. FFI and external specifications

External functions require an explicit trust/model status.

At minimum distinguish:

```text
verified modeled external
trusted/assumed external
unverified external
```

Trusted assumptions MUST appear in artifacts/manifests relevant to assurance claims.

An FFI declaration is never automatically verified because its type checks.

---

# Part III — Modules, interoperability, execution

## 82. Modules and imports

PSC2 retains deterministic logical modules.

```proofscript
import Foo.Bar
```

A module may be supplied by supported `.ps` or `.lean` source according to project configuration.

Ambiguous logical module resolution MUST fail.

PSC2 module semantics MUST NOT be Node/Cargo/filesystem resolution behavior by accident; host resolution maps files/packages into the explicit logical module graph.

---

## 83. Re-exports and package APIs

PSC2 SHOULD support explicit deterministic re-export so large libraries can define stable public surfaces.

Re-export does not duplicate semantic declarations; it creates controlled source/name visibility.

**OPEN FREEZE OBLIGATION:** freeze the exact native `.ps` re-export spelling before PSC2 syntax freeze.

---

## 84. Lean source interoperability

PSC2's `.lean` goal is low-friction source migration for ordinary Lean programming/theorem code.

Priority compatibility includes:

- declarations/binders;
- namespaces/sections/variables/open;
- structures/inductives/classes/instances;
- method/field notation;
- rich patterns/match;
- structural and well-founded recursion;
- `do`, loops, `let mut`;
- theorem/proof terms;
- common tactics/simplifier;
- universes;
- `noncomputable`/`classical`;
- controlled attributes/notation;
- supported contract syntax.

Not every Lean metaprogram or compiler intrinsic is automatically portable PSC2.

For the claimed overlap:

```text
.lean
  -> canonical semantics
  <- .ps
```

should yield equivalent admitted declarations/CheckedCore meaning.

---

## 85. Lean compatibility levels

Tooling SHOULD report compatibility more precisely than one Boolean.

Suggested levels:

```text
L0  lexical/basic syntax
L1  core declarations/terms
L2  structures/inductives/classes/recursion
L3  standard prover/tactics/notation
L4  Meta/macro/plugin compatibility
L5  theorem-library compatibility
L6  kernel/artifact compatibility
```

A library/tool may state which level it requires.

---

## 86. TypeScript migration model

PSC2 provides familiar ergonomics without importing TypeScript's unsound/dynamic semantics.

Recommended conceptual mapping:

| TypeScript habit | PSC2 mechanism |
| --- | --- |
| function | `def` / `function` |
| const binding | immutable `let`/`const` according to context |
| object/record | `structure` |
| discriminated union | `inductive` |
| generics | polymorphism/dependent binders |
| interfaces/constraints | structures/classes/instances |
| destructuring | rich patterns |
| object spread update | structure update |
| method call | generalized static field/method notation |
| optional/default parameter | default/named arguments / `Option` |
| nullable/undefined | `Option` |
| recoverable exception | `Result`/`Except` |
| loops/local mutation | owned `do` desugaring |
| Promise/async-await | `Task` + async/await sugar |
| decorator/metadata | controlled attributes/registries |
| enum/union | `inductive` |
| readonly | immutable-by-default PSC values |

PSC2 intentionally does not provide `any`, JavaScript prototype inheritance, implicit nullish values, or truthiness as portable semantics.

---

## 87. FFI

FFI is an explicit boundary.

Target-specific APIs narrow portability.

Portable source SHOULD depend on target-neutral capability interfaces when possible.

TS/Rust/Wasm adapters MAY represent the same capability differently.

FFI code MUST NOT redefine source type/equality/proof semantics.

---

## 88. Erasure

After kernel checking, proof/specification-only content may erase.

Erasure MUST preserve executable semantics for terms retained at runtime.

Typical erased content:

- theorem proofs;
- proof arguments where computationally irrelevant;
- contract proof evidence;
- ghost values proven runtime irrelevant;
- verification-only metadata.

Erasure correctness is separate from theorem correctness and requires its own assurance story.

---

## 89. VerifiedIR

Executable lowering uses a target-neutral VerifiedIR.

VerifiedIR contains PSC runtime meaning, not target representation.

It MUST NOT contain as source semantics:

- JavaScript `number`/`bigint` choices;
- Rust borrowing/lifetimes/trait layout;
- Wasm opcodes/value types/GC layout;
- backend-specific calling conventions;
- package-manager assumptions.

Backend target IRs come later.

---

## 90. TypeScript backend

The TypeScript backend maps VerifiedIR to deterministic TypeScript source/runtime constructs.

TypeScript's type checker is useful output validation, not ProofScript proof authority.

Generated `.d.ts` SHOULD reflect the callable runtime API without pretending erased proof parameters exist at runtime.

---

## 91. Rust backend

The Rust backend consumes the same VerifiedIR.

Ownership, borrowing, cloning, monomorphization, layout, and runtime representations are backend decisions.

Rust semantics MUST NOT leak upward into PSC2 source semantics.

---

## 92. WebAssembly backend

The Wasm backend consumes the same VerifiedIR and may use GC, linear memory, typed references, SIMD, components/WASI, or other target features according to target profiles.

These do not redefine PSC2 source semantics.

---

## 93. Portable libraries

A pure library depending only on portable PSC2 APIs SHOULD be eligible for all applicable backends:

```text
library.ps
   |
VerifiedIR
   +-> TS
   +-> Rust
   +-> Wasm
```

A target-specific capability/FFI dependency narrows this set explicitly.

---

# Part IV — Kernel, self-hosting, extensibility

## 94. Kernel provider contract

PSC2 SHOULD target a stable canonical kernel input contract so multiple independent validators can check the same semantics.

Long-term providers may include:

```text
PSC small kernel
Lean-compatible kernel
Dual checker
```

Multiple validators are acceptable.

Multiple incompatible semantic languages hidden behind the same source are not.

---

## 95. Kernel profiles and standardized extensions

PSC2 SHOULD keep genuine foundational extensions explicit and versioned.

Examples:

```text
PSC core
+ Quot/extensionality profile
+ Lean-compatibility profile
```

A feature that changes what propositions/terms the kernel accepts is not an ordinary plugin.

Build artifacts SHOULD record the kernel/profile used for logical admission.

---

## 96. Dual checking

A dual-check mode SHOULD be available during development/release assurance:

```text
canonical core
   |        |
   v        v
PSC kernel  Lean-compatible kernel
   |        |
   +---compare---+
```

Agreement provides strong differential evidence but is not itself a formal equivalence proof.

---

## 97. PSC2 self-hosting rule

PSC2 features SHOULD be implementable in PSC1 whenever practical.

Examples:

```text
method notation -> PSC1-written elaborator -> application
rich patterns   -> PSC1-written pattern compiler -> primitive matches
loops/mutation  -> PSC1-written desugaring -> effects/recursion
calc/have       -> PSC1-written elaborator -> proof terms
simp            -> PSC1-written prover -> proof terms
contracts       -> PSC1-written VC generator -> Prop obligations
```

The compiler need not use a feature in order to implement that feature.

---

## 98. Lean bootstrap anchor

PSC2 development may begin before PSC1 reaches every fixed-point gate.

A future compiler may be authored as a documented constrained Lean subset:

```text
official Lean
   -> Compiler2.lean
   -> PSC2-capable compiler
   -> canonical Compiler2.ps
   -> PSC2 self-host
```

A Lean-built PSC2 compiler is a bootstrap milestone, not yet a PSC2 self-host claim.

---

## 99. Self-host fixed point

PSC2 self-hosting requires ordinary ProofScript compiler source to compile itself through repeated generations with a defined semantic fixed point.

Preferred evidence compares:

- admitted CheckedCore fingerprints;
- target-neutral VerifiedIR fingerprints;
- canonical generated source where appropriate;
- cross-host behavior.

Native executable byte identity is not generally required.

---

## 100. Plugin self-hosting

Syntax, tactic, derive, verification, backend, and tooling plugin APIs SHOULD themselves be implementable in ProofScript.

The desirable endpoint is a platform where ProofScript extends ProofScript without relying on JavaScript/TypeScript as the semantic implementation language.

Host adapters may still use host code when necessary.

---

# Part V — Conformance, assurance, and deferred semantics

## 101. Conformance requirements

A feature may be claimed as PSC2-conformant only when:

1. its accepted source syntax is documented;
2. its elaboration/lowering or foundational semantics is documented;
3. unsupported/ambiguous cases fail closed;
4. `.ps` and `.lean` agree where both claim support;
5. generated core is admitted by the selected kernel/profile;
6. proof-producing features produce kernel-checkable evidence;
7. executable meaning is target-neutral before backend lowering;
8. relevant TS/Rust/Wasm differential tests exist;
9. the feature has a bootstrap/self-host path;
10. trust assumptions are reported.

---

## 102. Verification acceptance gates

Before PSC2 claims first-class contract verification, conformance tests MUST include at least:

1. valid pure pre/postcondition proof;
2. caller precondition generation;
3. stateful pre/postcondition proof;
4. verified `assert` generation and runtime erasure;
5. loop invariant initialization/preservation/exit;
6. decreasing/termination proof;
7. deliberately false contract rejection;
8. deliberately false invariant rejection;
9. `.ps`/`.lean` contract semantic equivalence for the claimed overlap;
10. equal pre-backend VerifiedIR after proof erasure;
11. explicit trusted external-assumption reporting;
12. strict separation of runtime checking from proof status.

---

## 103. Prover acceptance gates

Before claiming PSC2 Standard Prover, tests SHOULD cover:

- `have`/`show`/`suffices`;
- `calc` equality and non-equality transitivity where registered;
- forward/reverse `rw`;
- `simp`, `simpa`, `simp only`, `simp at`;
- `by_cases`/`by_contra`;
- `rcases`/`rintro`/`obtain`/`use` equivalents;
- dependent `cases`/`induction`;
- scoped/local instances and coercions;
- universe-polymorphic examples;
- `noncomputable`/`classical` theorem examples;
- a quotient/extensionality example in the enabled theorem profile;
- negative tests for malformed/unsound tactic output.

---

## 104. Programming acceptance gates

Before claiming PSC2 programming ergonomics, tests SHOULD cover:

- generalized method resolution and ambiguity failure;
- structure updates;
- named/default dependent arguments;
- nested/multi-scrutinee patterns;
- equation-style definitions;
- local/mutual recursion;
- well-founded termination obligations;
- `let mut`/assignment;
- `for`/`while`/break/continue;
- namespace/section/open resolution;
- transparent/opaque behavior;
- deriving through ordinary declaration checking;
- portable source differential behavior across TS/Rust/Wasm where applicable.

---

## 105. Claim discipline

PSC2 MUST distinguish at least these claims:

```text
parsed
elaborated
kernel checked
contract verified
portable
compiled for target X
backend differential tested
compiler-preservation proved
Lean-compatible at level Lx
```

One claim MUST NOT imply another without evidence.

In particular:

- parser acceptance is not proof;
- successful TS/Rust compilation is not proof;
- runtime contract success is not proof;
- dual-kernel agreement is not a formal equivalence theorem;
- theorem verification does not by itself prove backend/compiler correctness.

---

## 106. Deliberately excluded native semantics

PSC2 does not natively adopt:

- JavaScript `any`;
- implicit `null`/`undefined`;
- prototype chains;
- JavaScript `this` semantics;
- structural object identity as the foundational type system;
- implicit truthiness/coercion;
- unrestricted statement mutation;
- Promise/event-loop behavior as Task semantics;
- host exceptions as ordinary error semantics;
- Rust borrowing/lifetimes as source semantics;
- Wasm opcodes/memory layout as source semantics;
- arbitrary parser/environment mutation that can bypass controlled extension boundaries;
- arbitrary kernel plugins.

---

## 107. Optional ergonomic candidates not required for PSC2 freeze

The following may be useful but are not required merely for familiarity:

- Option-aware optional chaining/nullish sugar;
- universal arrow-lambda syntax;
- variadic/rest parameters beyond ordinary list/array APIs;
- object-spread syntax beyond typed structure update;
- JavaScript-style classes/inheritance;
- unrestricted decorators;
- unrestricted macros;
- implicit host exception conversion;
- target-specific async syntax beyond standardized Task lowering.

These should be added only when they make ProofScript materially easier without creating overlapping semantics.

---

## 108. Open freeze obligations

Before PSC2 can be declared frozen, the repository must close or explicitly defer:

1. exact native `.ps` re-export syntax;
2. exact final contract-obligation proof-section spelling;
3. Task cancellation/failure/scheduling observables;
4. final standardized attribute/registry set;
5. final controlled notation grammar and scope rules;
6. exact output-parameter/coercion compatibility subset;
7. exact quotient/extensionality kernel/profile boundary;
8. well-founded recursion source/proof details;
9. precise transparency/opacity behavior across kernel providers;
10. plugin capability/versioning/permission model;
11. contract semantics for async/cancellation and complex effects;
12. executable treatment of reachable `noncomputable` declarations;
13. exact compatibility level promised for Lean source at PSC2 release.

An implementation MUST NOT invent backend-specific answers and then describe them as PSC2 semantics.

---

## 109. Reference examples

### 109.1 TypeScript-friendly ordinary programming

```proofscript
structure User where {
  id: Nat;
  name: String;
}

function rename(user: User, name: String): User :=
  { user with name := name };

function names(users: List User): List String :=
  users.map(fun u => u.name);
```

### 109.2 Rich matching

```proofscript
function getValue(x: Option (Result String Nat)): Nat :=
  match x with {
    | .some (.ok n) => n;
    | _ => 0;
  };
```

### 109.3 Imperative-looking but owned control flow

```proofscript
function sum(xs: List Nat): Nat := do {
  let mut acc := 0;
  for x in xs {
    acc := acc + x;
  }
  return acc;
};
```

### 109.4 Structured theorem proof

```proofscript
theorem addTwo(n: Nat): n + 2 = n + 1 + 1 := by {
  calc
    n + 2 = n + (1 + 1) := by simp
    _ = n + 1 + 1 := by simp
};
```

### 109.5 Verified contract

```proofscript
function withdraw(balance: Nat, amount: Nat): Nat
  requires amount <= balance
  ensures result => result = balance - amount :=
  balance - amount;
```

### 109.6 Verified loop

```proofscript
def sumVerified(xs: List Nat): Nat
  ensures result => result = xs.sum := do {
  let mut acc := 0;
  for x in xs
    invariant prefix suffix acc => acc = prefix.sum
  {
    acc := acc + x;
  }
  assert acc = xs.sum;
  return acc;
};
```

### 109.7 Mathematical/research source

```proofscript
universe u;

noncomputable section {
  variable {α: Type u};

  theorem identity(x: α): x = x := by {
    classical
    rfl
  }
}
```

---

## 110. PSC2 language identity

PSC2 should be understood as:

```text
small PSC1 semantic/bootstrap foundation
             +
comfortable programming surface
             +
mature proof-producing prover layer
             +
first-class contract verification
             +
controlled extensibility
             +
TS / Rust / Wasm portability
             +
Lean migration/compatibility path
```

The intended long-term property is:

> ProofScript may become a very capable programming and theorem-proving platform without requiring its trusted semantic foundation to grow at the same rate.

PSC1 remains the small language that can implement the compiler. PSC2 is the language people should be comfortable using every day.
