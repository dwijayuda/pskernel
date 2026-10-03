<a id="The-Lean-Language-Reference--The--mvcgen--tactic--Predicate-Transformers"></a>

# ProofScript — 17.2. Predicate Transformers

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Verification-condition generation connects a computation to a program-logic specification. Predicate transformers, state/error behavior, supported monads and loop interfaces are part of that connection. The final proof must establish the approved property of the actual computation, not merely prove unrelated obligations emitted by a buggy generator. Intrinsic contracts are experimental at the selected pin.

**Compiler and coverage boundary.** Keep the native requires/ensures grammar, generated theorem identities, residual proof sections and assumption reports. The inherited example uses native spelling intentionally; it is already an L-class ProofScript form.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [The--mvcgen--tactic/Predicate-Transformers/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/The--mvcgen--tactic/Predicate-Transformers/index.html). Source Git blob: `2c1c3649ab763d9261e4f7eed560003937c447b2`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Extends-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next"></a>

---

## 17.2. Predicate Transformers

A 
<a id="--tech-term-predicate-transformer-semantics"></a>
*predicate transformer semantics* is an interpretation of programs as functions from predicates to predicates, rather than values to values. A 
<a id="--tech-term-postcondition"></a>
*postcondition* is an assertion that holds after running a program, while a 
<a id="--tech-term-precondition"></a>
*precondition* is an assertion that must hold prior to running the program in order for the postcondition to be guaranteed to hold.

The predicate transformer semantics used by `mvcgen` transforms postconditions into the 
<a id="--tech-term-weakest-preconditions"></a>
*weakest preconditions* under which the program will ensure the postcondition. An assertion P is weaker than P' if, in all states, P' suffices to prove P, but P does not suffice to prove P'. Logically equivalent assertions are considered to be equal.

The predicates in question are stateful: they can mention the program's current state. Furthermore, postconditions can relate the return value and any exceptions thrown by the program to the final state. `SPred` is a type of predicates that is parameterized over a monadic state, expressed as a list of the types of the fields that make up the state. The usual logical connectives and quantifiers are defined for `SPred`. Each monad that can be used with `mvcgen` is assigned a state type by an instance of `WP`, and `Assertion` is the corresponding type of assertions for that monad, which is used for preconditions. `Assertion` is a wrapper around `SPred`: while `SPred` is parameterized by a list of states types, `Assertion` is parameterized by a more informative type that it translates to a list of state types for `SPred`. A `PostCond` pairs an `Assertion` about a return value with assertions about potential exceptions; the available exceptions are also specified by the monad's `WP` instance.

<a id="The-Lean-Language-Reference--The--mvcgen--tactic--Predicate-Transformers--Stateful-Predicates"></a>
### 17.2.1. Stateful Predicates

The predicate transformer semantics of monadic programs is based on a logic in which propositions may mention the program's state. Here, “state” refers not only to mutable state, but also to read-only values such as those that are provided via `ReaderT`. Different monads have different state types available, but each individual state always has a type. Given a list of state types, `SPred` is a type of predicates over these states.

`SPred` is not inherently tied to the monadic verification framework. The related `Assertion` computes a suitable `SPred` for a monad's state as expressed via its `WP` instance's `PostShape` output parameter.

<a id="Std___Do___SPred"></a>

**def**

```text
Std.Do.SPred.{u} (σs : List (Type u)) : Type u
```

A predicate over states, where each state is defined by a list of component state types.

Example:

```proofscript
SPred [Nat, Bool] = (Nat → Bool → ULift Prop)
```

Ordinary propositions that do not mention the state can be used as stateful predicates by adding a trivial universal quantification. This is written with the syntax `⌜P⌝`, which is syntactic sugar for `SPred.pure`.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Notation for SPred**

<a id="Std___Do____FLQQ_term________FLQQ_"></a>

```ebnf
term ::= ...
    | ⌜term⌝
```

Embedding of pure Lean values into `SVal`. An alias for `SPred.pure`.

<a id="Std___Do___SPred___pure"></a>

**def**

```text
Std.Do.SPred.pure.{u} {σs : List (Type u)} (P : Prop) : SPred σs
```

A pure proposition `P : Prop` embedded into `SPred`. Prefer to use notation `⌜P⌝`.

<a id="Stateful-Predicates"></a>
Stateful Predicates 

The predicate `ItIsSecret` expresses that a state of type `String` is `"secret"`:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="ItIsSecret-_LPAR_in-Stateful-Predicates_RPAR_"></a>


```proofscript
const ItIsSecret : SPred [String] := fun s => ⌜s = "secret"⌝
```

<a id="The-Lean-Language-Reference--The--mvcgen--tactic--Predicate-Transformers--Stateful-Predicates--Entailment"></a>
#### 17.2.1.1. Entailment

Stateful predicates are related by *entailment*. Entailment of stateful predicates is defined as universally-quantified implication: if P and Q are predicates over a state \sigma, then P entails Q (written P \vdash_s Q) when ∀ s : \sigma, P(s) → Q(s).

<a id="Std___Do___SPred___entails"></a>

**def**

```text
Std.Do.SPred.entails.{u} {σs : List (Type u)} (P Q : SPred σs) : Prop
```

Entailment in `SPred`.

One predicate `P` entails another predicate `Q` if `Q` is true in every state in which `P` is true. Unlike implication (`SPred.imp`), entailment is not itself an `SPred`, but is instead an ordinary proposition.

<a id="Std___Do___SPred___bientails"></a>

**def**

```text
Std.Do.SPred.bientails.{u} {σs : List (Type u)} (P Q : SPred σs) : Prop
```

Logical equivalence of `SPred`.

Logically equivalent predicates are equal. Use `SPred.bientails.to_eq` to convert bi-entailment to equality.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Notation for SPred**

<a id="Std___Do____FLQQ_term__VDASH______FLQQ_"></a>

```ebnf
term ::= ...
    | term ⊢ₛ term
```

Entailment in `SPred`; sugar for `SPred.entails`.

<a id="Std___Do____FLQQ_term_VDASH______FLQQ_"></a>

```ebnf
term ::= ...
    | ⊢ₛ term
```

Tautology in `SPred`; sugar for `SPred.entails ⌜True⌝`.

<a id="Std___Do____FLQQ_term_____VDASH______FLQQ_"></a>

```ebnf
term ::= ...
    | term ⊣⊢ₛ term
```

Bi-entailment in `SPred`; sugar for `SPred.bientails`.

The logic of stateful predicates includes an implication connective. The difference between entailment and implication is that entailment is a statement in Lean's logic, while implication is internal to the stateful logic. Given stateful predicates `P` and `Q` for state `σ`, `P ⊢ₛ Q` is a `Prop` while `spred(P → Q)` is an `SPred σ`.

<a id="The-Lean-Language-Reference--The--mvcgen--tactic--Predicate-Transformers--Stateful-Predicates--Notation"></a>
#### 17.2.1.2. Notation

The syntax of stateful predicates overlaps with that of ordinary Lean terms. In particular, stateful predicates use the usual syntax for logical connectives and quantifiers. The syntax associated with stateful predicates is automatically enabled in contexts such as pre- and postconditions where they are clearly intended; other contexts must explicitly opt in to the syntax using `spred`. The usual meanings of these operators can be recovered by using the [`term`](index.md#Std___Do____FLQQ_termTerm_LPAR___RPAR__FLQQ_) operator.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Predicate Terms**

`spred` indicates that logical connectives and quantifiers should be understood as those pertaining to stateful predicates, while [`term`](index.md#Std___Do____FLQQ_termTerm_LPAR___RPAR__FLQQ_) indicates that they should have the usual meaning.

<a id="Std___Do____FLQQ_termSpred_LPAR___RPAR__FLQQ_"></a>

```ebnf
term ::= ...
    | spred(term)
```

<a id="Std___Do____FLQQ_termTerm_LPAR___RPAR__FLQQ_"></a>

```ebnf
term ::= ...
    | term(term)
```

<a id="The-Lean-Language-Reference--The--mvcgen--tactic--Predicate-Transformers--Stateful-Predicates--Connectives-and-Quantifiers"></a>
#### 17.2.1.3. Connectives and Quantifiers

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Predicate Connectives**

<a id="Std___Do____FLQQ_termSpred_LPAR___RPAR__FLQQ_-next"></a>

```ebnf
term ::= ...
    | spred(term ∧ term)
```

Syntactic sugar for `SPred.and`.

<a id="Std___Do____FLQQ_termSpred_LPAR___RPAR__FLQQ_-next-next"></a>

```ebnf
term ::= ...
    | spred(term ∨ term)
```

Syntactic sugar for `SPred.or`.

<a id="Std___Do____FLQQ_termSpred_LPAR___RPAR__FLQQ_-next-next-next"></a>

```ebnf
term ::= ...
    | spred(¬ term)
```

Syntactic sugar for `SPred.not`.

<a id="Std___Do____FLQQ_termSpred_LPAR___RPAR__FLQQ_-next-next-next-next"></a>

```ebnf
term ::= ...
    | spred(term → term)
```

Syntactic sugar for `SPred.imp`.

<a id="Std___Do____FLQQ_termSpred_LPAR___RPAR__FLQQ_-next-next-next-next-next"></a>

```ebnf
term ::= ...
    | spred(term ↔ term)
```

Syntactic sugar for `SPred.iff`.

<a id="Std___Do___SPred___and"></a>

**def**

```text
Std.Do.SPred.and.{u} {σs : List (Type u)} (P Q : SPred σs) : SPred σs
```

Conjunction in `SPred`: states that satisfy `P` and satisfy `Q` satisfy `spred(P ∧ Q)`.

<a id="Std___Do___SPred___conjunction"></a>

**def**

```text
Std.Do.SPred.conjunction.{u} {σs : List (Type u)}
  (env : List (SPred σs)) : SPred σs
```

Conjunction of a list of stateful predicates. A state satisfies `conjunction env` if it satisfies all predicates in `env`.

<a id="Std___Do___SPred___or"></a>

**def**

```text
Std.Do.SPred.or.{u} {σs : List (Type u)} (P Q : SPred σs) : SPred σs
```

Disjunction in `SPred`: states that either satisfy `P` or satisfy `Q` satisfy `spred(P ∨ Q)`.

<a id="Std___Do___SPred___not"></a>

**def**

```text
Std.Do.SPred.not.{u} {σs : List (Type u)} (P : SPred σs) : SPred σs
```

Negation in `SPred`: states that do not satisfy `P` satisfy `spred(¬ P)`.

<a id="Std___Do___SPred___imp"></a>

**def**

```text
Std.Do.SPred.imp.{u} {σs : List (Type u)} (P Q : SPred σs) : SPred σs
```

Implication in `SPred`: states that satisfy `Q` whenever they satisfy `P` satisfy `spred(P → Q)`.

<a id="Std___Do___SPred___iff"></a>

**def**

```text
Std.Do.SPred.iff.{u} {σs : List (Type u)} (P Q : SPred σs) : SPred σs
```

Biimplication in `SPred`: states that either satisfy both `P` and `Q` or satisfy neither satisfy `spred(P ↔ Q)`.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Predicate Quantifiers**

<a id="Std___Do____FLQQ_termSpred_LPAR___RPAR__FLQQ_-next-next-next-next-next-next"></a>

```ebnf
term ::= ...
    | spred(∀ ident, term)
```

<a id="Std___Do____FLQQ_termSpred_LPAR___RPAR__FLQQ_-next-next-next-next-next-next-next"></a>

```ebnf
term ::= ...
    | spred(∀ ident : term,  term)
```

<a id="Std___Do____FLQQ_termSpred_LPAR___RPAR__FLQQ_-next-next-next-next-next-next-next-next"></a>

```ebnf
term ::= ...
    | spred(∀ (ident (ident | hole)* : term),  term)
```

<a id="Std___Do____FLQQ_termSpred_LPAR___RPAR__FLQQ_-next-next-next-next-next-next-next-next-next"></a>

```ebnf
term ::= ...
    | spred(∀ _, term)
```

<a id="Std___Do____FLQQ_termSpred_LPAR___RPAR__FLQQ_-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
term ::= ...
    | spred(∀ _ : term,  term)
```

<a id="Std___Do____FLQQ_termSpred_LPAR___RPAR__FLQQ_-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
term ::= ...
    | spred(∀ (_ (ident | hole)* : term),  term)
```

Each form of universal quantification is syntactic sugar for an invocation of `SPred.forall` on a function that takes the quantified variable as a parameter.

<a id="Std___Do____FLQQ_termSpred_LPAR___RPAR__FLQQ_-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
term ::= ...
    | spred(∃ ident, term)
```

<a id="Std___Do____FLQQ_termSpred_LPAR___RPAR__FLQQ_-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
term ::= ...
    | spred(∃ ident : term,  term)
```

<a id="Std___Do____FLQQ_termSpred_LPAR___RPAR__FLQQ_-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
term ::= ...
    | spred(∃ (ident binderIdent* : term),  term)
```

<a id="Std___Do____FLQQ_termSpred_LPAR___RPAR__FLQQ_-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
term ::= ...
    | spred(∃ _, term)
```

<a id="Std___Do____FLQQ_termSpred_LPAR___RPAR__FLQQ_-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
term ::= ...
    | spred(∃ _ : term,  term)
```

<a id="Std___Do____FLQQ_termSpred_LPAR___RPAR__FLQQ_-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
term ::= ...
    | spred(∃ (_ binderIdent* : term),  term)
```

Each form of existential quantification is syntactic sugar for an invocation of `SPred.exists` on a function that takes the quantified variable as a parameter.

<a id="Std___Do___SPred___forall"></a>

**def**

```text
Std.Do.SPred.forall.{u, v} {α : Sort u} {σs : List (Type v)}
  (P : α → SPred σs) : SPred σs
```

Universal quantifier in `SPred`.

<a id="Std___Do___SPred___exists"></a>

**def**

```text
Std.Do.SPred.exists.{u, v} {α : Sort u} {σs : List (Type v)}
  (P : α → SPred σs) : SPred σs
```

Existential quantifier in `SPred`.

<a id="The-Lean-Language-Reference--The--mvcgen--tactic--Predicate-Transformers--Stateful-Predicates--Stateful-Values"></a>
#### 17.2.1.4. Stateful Values

Just as `SPred` represents predicate over states, `SVal` represents a value that is derived from a state.

<a id="Std___Do___SVal"></a>

**def**

```text
Std.Do.SVal.{u} (σs : List (Type u)) (α : Type u) : Type u
```

A value indexed by a curried tuple of states.

Example:

```text
example : SVal [Nat, Bool] String = (Nat → Bool → String) := rfl
```

<a id="Std___Do___SVal___getThe"></a>

**def**

```text
Std.Do.SVal.getThe.{u} {σs : List (Type u)} (σ : Type u)
  [SVal.GetTy σ σs] : SVal σs σ
```

Gets the top-most state of type `σ` from an `SVal`.

<a id="Std___Do___SVal___StateTuple"></a>

**def**

```text
Std.Do.SVal.StateTuple.{u} (σs : List (Type u)) : Type u
```

A tuple capturing the whole state of an `SVal`.

<a id="Std___Do___SVal___curry"></a>

**def**

```text
Std.Do.SVal.curry.{u} {α : Type u} {σs : List (Type u)}
  (f : SVal.StateTuple σs → α) : SVal σs α
```

Curries a function taking a `StateTuple` into an `SVal`.

<a id="Std___Do___SVal___uncurry"></a>

**def**

```text
Std.Do.SVal.uncurry.{u} {α : Type u} {σs : List (Type u)}
  (f : SVal σs α) : SVal.StateTuple σs → α
```

Uncurries an `SVal` into a function taking a `StateTuple`.

<a id="The-Lean-Language-Reference--The--mvcgen--tactic--Predicate-Transformers--Assertions"></a>
### 17.2.2. Assertions

The language of assertions about monadic programs is parameterized by a 
<a id="--tech-term-postcondition-shape"></a>
*postcondition shape*, which describes the inputs to and outputs from a computation in a given monad. Preconditions may mention the initial values of the monad's state, while postconditions may mention the returned value, the final values of the monad's state, and must furthermore account for any exceptions that could have been thrown. The postcondition shape of a given monad determines the states and exceptions in the monad. `PostShape.pure` describes a monad in which assertions may not mention any states, `PostShape.arg` describes a state value, and `PostShape.except` describes a possible exception. Because these constructors can be continually added, the postcondition shape of a monad transformer can be defined in terms of the postcondition shape of the underlying transformed monad. Behind the scenes, an `Assertion` is translated into an appropriate `SPred` by translating the postcondition shape into a list of state types, discarding exceptions.

<a id="Std___Do___PostShape___pure"></a>

**inductive type**

```text
Std.Do.PostShape.{u} : Type (u + 1)
```

The “shape” of the postconditions that are used to reason about a monad.

A postcondition shape is an abstraction of many possible monadic effects, based on the structure of pure functions that can simulate them. The postcondition shape of a monad is given by its `WP` instance. This shape is used to determine both its `Assertion`s and its `PostCond`s.

**Constructors**

```text
Std.Do.PostShape.pure.{u} : PostShape
```

The assertions and postconditions in this monad use neither state nor exceptions.

```text
Std.Do.PostShape.arg.{u} (σ : Type u) :
  PostShape → PostShape
```

The assertions in this monad may mention the current value of a state of type `σ`, and postconditions may mention the state's final value.

```text
Std.Do.PostShape.except.{u} (ε : Type u) :
  PostShape → PostShape
```

The postconditions in this monad include assertions about exceptional values of type `ε` that result from premature termination.

<a id="Std___Do___PostShape___args"></a>

**def**

```text
Std.Do.PostShape.args.{u} : PostShape → List (Type u)
```

Extracts the list of state types under `PostShape.arg` constructors, discarding exception types.

The state types determine the shape of assertions in the monad.

<a id="Std___Do___Assertion"></a>

**def**

```text
Std.Do.Assertion.{u} (ps : PostShape) : Type u
```

An assertion about the state fields for a monad whose postcondition shape is `ps`.

Concretely, this is an abbreviation for `SPred` applied to the `.arg`s in the given predicate shape, so all theorems about `SPred` apply.

Examples:

```text
example : Assertion (.arg ρ .pure) = (ρ → ULift Prop) := rfl
example : Assertion (.except ε .pure) = ULift Prop := rfl
example : Assertion (.arg σ (.except ε .pure)) = (σ → ULift Prop) := rfl
example : Assertion (.except ε (.arg σ .pure)) = (σ → ULift Prop) := rfl
```

<a id="Std___Do___PostCond"></a>

**def**

```text
Std.Do.PostCond.{u} (α : Type u) (ps : PostShape) : Type u
```

A postcondition for the given predicate shape, with one `Assertion` for the terminating case and one `Assertion` for each `.except` layer in the predicate shape.

```text
variable (α σ ε : Type)
example : PostCond α (.arg σ .pure) = ((α → σ → ULift Prop) × PUnit) := rfl
example : PostCond α (.except ε .pure) = ((α → ULift Prop) × (ε → ULift Prop) × PUnit) := rfl
example : PostCond α (.arg σ (.except ε .pure)) = ((α → σ → ULift Prop) × (ε → ULift Prop) × PUnit) := rfl
example : PostCond α (.except ε (.arg σ .pure)) = ((α → σ → ULift Prop) × (ε → σ → ULift Prop) × PUnit) := rfl
```

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Postconditions**

<a id="Std___Do____FLQQ_term_________GT___FLQQ_"></a>

```ebnf
term ::= ...
    | ⇓ term* => term
```

Syntactic sugar for a nested sequence of product constructors, terminating in `()`, in which the first element is an assertion about non-exceptional return values and the remaining elements are assertions about the exceptional cases for a postcondition.

<a id="Std___Do___ExceptConds"></a>

**def**

```text
Std.Do.ExceptConds.{u} : PostShape → Type u
```

An assertion about each potential exception that's declared in a postcondition shape.

Examples:

```text
example : ExceptConds (.pure) = Unit := rfl
example : ExceptConds (.except ε .pure) = ((ε → ULift Prop) × Unit) := rfl
example : ExceptConds (.arg σ (.except ε .pure)) = ((ε → ULift Prop) × Unit) := rfl
example : ExceptConds (.except ε (.arg σ .pure)) = ((ε → σ → ULift Prop) × Unit) := rfl
```

Postconditions for programs that might throw exceptions come in two varieties. The 
<a id="--tech-term-total-correctness-interpretation"></a>
*total correctness interpretation* `⦃P⦄ prog ⦃⇓ r => Q' r⦄` asserts that, given `P` holds, then `prog` terminates *and* `Q'` holds for the result. The 
<a id="--tech-term-partial-correctness-interpretation"></a>
*partial correctness interpretation* `⦃P⦄ prog ⦃⇓? r => Q' r⦄` asserts that, given `P` holds, and *if* `prog` terminates *then* `Q'` holds for the result.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Exception-Free Postconditions**

<a id="Std___Do____FLQQ_term_________GT___FLQQ_-next"></a>

```ebnf
term ::= ...
    | ⇓ term* => term
```

A postcondition expressing total correctness. That is, it expresses that the asserted computation finishes without throwing an exception *and* the result satisfies the given predicate `p`.

<a id="Std___Do___PostCond___noThrow"></a>

**def**

```text
Std.Do.PostCond.noThrow.{u_1} {α : Type u_1} {ps : PostShape}
  (p : α → Assertion ps) : PostCond α ps
```

A postcondition expressing total correctness. That is, it expresses that the asserted computation finishes without throwing an exception *and* the result satisfies the given predicate `p`.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Partial Postconditions**

<a id="Std___Do____FLQQ_term____________GT___FLQQ_"></a>

```ebnf
term ::= ...
    | ⇓? term* => term
```

A postcondition expressing partial correctness. That is, it expresses that *if* the asserted computation finishes without throwing an exception *then* the result satisfies the given predicate `p`. Nothing is asserted when the computation throws an exception.

<a id="Std___Do___PostCond___mayThrow"></a>

**def**

```text
Std.Do.PostCond.mayThrow.{u_1} {α : Type u_1} {ps : PostShape}
  (p : α → Assertion ps) : PostCond α ps
```

A postcondition expressing partial correctness. That is, it expresses that *if* the asserted computation finishes without throwing an exception *then* the result satisfies the given predicate `p`. Nothing is asserted when the computation throws an exception.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Postcondition Entailment**

<a id="Std___Do____FLQQ_term__VDASH______FLQQ_-next"></a>

```ebnf
term ::= ...
    | term ⊢ₚ term
```

Syntactic sugar for `PostCond.entails`

<a id="Std___Do___PostCond___entails"></a>

**def**

```text
Std.Do.PostCond.entails.{u_1} {α : Type u_1} {ps : PostShape}
  (p q : PostCond α ps) : Prop
```

Entailment of postconditions.

This consists of:

- Entailment of the assertion about the return value, for all possible return values.
- Entailment of the exception conditions.

While implication of postconditions (`PostCond.imp`) results in a new postcondition, entailment is an ordinary proposition.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Postcondition Conjunction**

<a id="Std___Do____FLQQ_term_________FLQQ_"></a>

```ebnf
term ::= ...
    | term ∧ₚ term
```

Syntactic sugar for `PostCond.and`

<a id="Std___Do___PostCond___and"></a>

**def**

```text
Std.Do.PostCond.and.{u_1} {α : Type u_1} {ps : PostShape}
  (p q : PostCond α ps) : PostCond α ps
```

Conjunction of postconditions.

This is defined pointwise, as the conjunction of the assertions about the return value and the conjunctions of the assertions about each potential exception.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Postcondition Implication**

<a id="Std___Do____FLQQ_term__ARR______FLQQ_"></a>

```ebnf
term ::= ...
    | term →ₚ term
```

Syntactic sugar for `PostCond.imp`

<a id="Std___Do___PostCond___imp"></a>

**def**

```text
Std.Do.PostCond.imp.{u_1} {α : Type u_1} {ps : PostShape}
  (p q : PostCond α ps) : PostCond α ps
```

Implication of postconditions.

This is defined pointwise, as the implication of the assertions about the return value and the implications of each of the assertions about each potential exception.

While entailment of postconditions (`PostCond.entails`) is an ordinary proposition, implication of postconditions is itself a postcondition.

<a id="The-Lean-Language-Reference--The--mvcgen--tactic--Predicate-Transformers--Predicate-Transformers"></a>
### 17.2.3. Predicate Transformers

A predicate transformer is a function from postconditions for some postcondition state into assertions for that state. The function must be 
<a id="--tech-term-conjunctive"></a>
*conjunctive*, which means it must distribute over `PostCond.and`.

<a id="Std___Do___PredTrans___mk"></a>

**structure**

```text
Std.Do.PredTrans.{u} (ps : PostShape) (α : Type u) : Type u
```

The type of predicate transformers for a given `ps : PostShape` and return type `α : Type`. A predicate transformer `x : PredTrans ps α` is a function that takes a postcondition `Q : PostCond α ps` and returns a precondition `x.apply Q : Assertion ps`.

**Constructor**

```text
Std.Do.PredTrans.mk.{u}
```

**Fields**

```text
trans : PostCond α ps → Assertion ps
```

The function implementing the predicate transformer.

```text
conjunctiveRaw : PredTrans.Conjunctive self.trans
```

The predicate transformer is conjunctive: `t (Q₁ ∧ₚ Q₂) ⊣⊢ₛ t Q₁ ∧ t Q₂`. So the stronger the postcondition, the stronger the resulting precondition.

<a id="Std___Do___PredTrans___Conjunctive"></a>

**def**

```text
Std.Do.PredTrans.Conjunctive.{u} {ps : PostShape} {α : Type u}
  (t : PostCond α ps → Assertion ps) : Prop
```

Transforming a conjunction of postconditions is the same as the conjunction of transformed postconditions.

<a id="Std___Do___PredTrans___Monotonic"></a>

**def**

```text
Std.Do.PredTrans.Monotonic.{u} {ps : PostShape} {α : Type u}
  (t : PostCond α ps → Assertion ps) : Prop
```

The stronger the postcondition, the stronger the transformed precondition.

Predicate transformers form a monad. The `pure` operator is the identity transformer; it simply instantiates the postcondition with the its argument. The `bind` operator composes predicate transformers.

<a id="Std___Do___PredTrans___pure"></a>

**def**

```text
Std.Do.PredTrans.pure.{u} {ps : PostShape} {α : Type u} (a : α) :
  PredTrans ps α
```

The identity predicate transformer that transforms the postcondition's assertion about the return value into an assertion about `a`.

<a id="Std___Do___PredTrans___bind"></a>

**def**

```text
Std.Do.PredTrans.bind.{u} {ps : PostShape} {α β : Type u}
  (x : PredTrans ps α) (f : α → PredTrans ps β) : PredTrans ps β
```

Sequences two predicate transformers by composing them.

The helper operators `PredTrans.pushArg`, `PredTrans.pushExcept`, and `PredTrans.pushOption` modify a predicate transformer by adding a standard side effect. They are used to implement the `WP` instances for transformers such as `StateT`, `ExceptT`, and `OptionT`; they can also be used to implement monads that can be thought of in terms of one of these. For example, `PredTrans.pushArg` is typically used for state monads, but can also be used to implement a reader monad's instance, treating the reader's value as read-only state.

<a id="Std___Do___PredTrans___pushArg"></a>

**def**

```text
Std.Do.PredTrans.pushArg.{u} {ps : PostShape} {α σ : Type u}
  (x : StateT σ (PredTrans ps) α) : PredTrans (PostShape.arg σ ps) α
```

Adds the ability to make assertions about a state of type `σ` to a predicate transformer with postcondition shape `ps`, resulting in postcondition shape `.arg σ ps`. This is done by interpreting `StateT σ (PredTrans ps) α` into `PredTrans (.arg σ ps) α`.

This can be used to for all kinds of state-like effects, including reader effects or append-only states, by interpreting them as states.

<a id="Std___Do___PredTrans___pushExcept"></a>

**def**

```text
Std.Do.PredTrans.pushExcept.{u_1} {ps : PostShape} {α ε : Type u_1}
  (x : ExceptT ε (PredTrans ps) α) : PredTrans (PostShape.except ε ps) α
```

Adds the ability to make assertions about exceptions of type `ε` to a predicate transformer with postcondition shape `ps`, resulting in postcondition shape `.except ε ps`. This is done by interpreting `ExceptT ε (PredTrans ps) α` into `PredTrans (.except ε ps) α`.

This can be used for all kinds of exception-like effects, such as early termination, by interpreting them as exceptions.

<a id="Std___Do___PredTrans___pushOption"></a>

**def**

```text
Std.Do.PredTrans.pushOption.{u_1} {ps : PostShape} {α : Type u_1}
  (x : OptionT (PredTrans ps) α) :
  PredTrans (PostShape.except PUnit ps) α
```

Adds the ability to make assertions about early termination to a predicate transformer with postcondition shape `ps`, resulting in postcondition shape `.except PUnit ps`. This is done by interpreting `OptionT (PredTrans ps) α` into `PredTrans (.except PUnit ps) α`, which models the type `Option` as being equivalent to `Except PUnit`.

<a id="The-Lean-Language-Reference--The--mvcgen--tactic--Predicate-Transformers--Predicate-Transformers--Weakest-Preconditions"></a>
#### 17.2.3.1. Weakest Preconditions

The [weakest precondition](index.md#--tech-term-weakest-preconditions) semantics of a monad are provided by the `WP` type class. Instances of `WP` determine the monad's postcondition shape and provide the logical rules for interpreting the monad's operations as a predicate transformer in its postcondition shape.

<a id="Std___Do___WP___mk"></a>

**type class**

```text
Std.Do.WP.{u, v} (m : Type u → Type v) (ps : outParam PostShape) :
  Type (max (u + 1) v)
```

A weakest precondition interpretation of a monadic program `x : m α` in terms of a predicate transformer `PredTrans ps α`. The monad `m` determines `ps : PostShape`.

For practical reasoning, an instance of `WPMonad m ps` is typically needed in addition to `WP m ps`.

**Instance Constructor**

```text
Std.Do.WP.mk.{u, v}
```

**Methods**

```text
wp : {α : Type u} → m α → PredTrans ps α
```

Interpret a monadic program `x : m α` in terms of a predicate transformer `PredTrans ps α`.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Weakest Preconditions**

<a id="Std___Do____FLQQ_termWp____________FLQQ_"></a>

```ebnf
term ::= ...
    | wp⟦term (: term)?⟧
```

`wp⟦x⟧ Q` is defined as `(WP.wp x).apply Q`.

<a id="The-Lean-Language-Reference--The--mvcgen--tactic--Predicate-Transformers--Predicate-Transformers--Weakest-Precondition-Monad-Morphisms"></a>
#### 17.2.3.2. Weakest Precondition Monad Morphisms

Most of the built-in specification lemmas for `mvcgen` relies on the presence of a `WPMonad` instance, in addition to the `WP` instance. In addition to being lawful, weakest preconditions of the monad's implementations of `pure` and `bind` should correspond to the `pure` and `bind` operators for the predicate transformer monad. Without a `WPMonad` instance, `mvcgen` typically returns the original proof goal unchanged.

<a id="Std___Do___WPMonad___mk"></a>

**type class**

```text
Std.Do.WPMonad.{u, v} (m : Type u → Type v) (ps : outParam PostShape)
  [Monad m] : Type (max (u + 1) v)
```

A monad with weakest preconditions (`WP`) that is also a monad morphism, preserving `pure` and `bind`.

In practice, `mvcgen` is not useful for reasoning about programs in a monad that is without a `WPMonad` instance. The specification lemmas for `Pure.pure` and `Bind.bind`, as well as those for operators like `Functor.map`, require that their monad have a `WPMonad` instance.

**Instance Constructor**

```text
Std.Do.WPMonad.mk.{u, v}
```

**Extends**

- <a id="0-LawfulMonad-Std.Do.WPMonad"></a>
  `LawfulMonad m`
- <a id="1-Std.Do.WP-Std.Do.WPMonad"></a>
  `WP m ps`

**Methods**

```text
map_const : ∀ {α β : Type u}, Functor.mapConst = Functor.map ∘ Function.const β
```

 Inherited from 

1. `LawfulMonad m`
2. `WP m ps`

```text
id_map : ∀ {α : Type u} (x : m α), id <$> x = x
```

 Inherited from 

1. `LawfulMonad m`
2. `WP m ps`

```text
comp_map : ∀ {α β γ : Type u} (g : α → β) (h : β → γ) (x : m α), (h ∘ g) <$> x = h <$> g <$> x
```

 Inherited from 

1. `LawfulMonad m`
2. `WP m ps`

```text
seqLeft_eq : ∀ {α β : Type u} (x : m α) (y : m β), x <* y = Function.const β <$> x <*> y
```

 Inherited from 

1. `LawfulMonad m`
2. `WP m ps`

```text
seqRight_eq : ∀ {α β : Type u} (x : m α) (y : m β), x *> y = Function.const α id <$> x <*> y
```

 Inherited from 

1. `LawfulMonad m`
2. `WP m ps`

```text
pure_seq : ∀ {α β : Type u} (g : α → β) (x : m α), pure g <*> x = g <$> x
```

 Inherited from 

1. `LawfulMonad m`
2. `WP m ps`

```text
map_pure : ∀ {α β : Type u} (g : α → β) (x : α), g <$> pure x = pure (g x)
```

 Inherited from 

1. `LawfulMonad m`
2. `WP m ps`

```text
seq_pure : ∀ {α β : Type u} (g : m (α → β)) (x : α), g <*> pure x = (fun h => h x) <$> g
```

 Inherited from 

1. `LawfulMonad m`
2. `WP m ps`

```text
seq_assoc : ∀ {α β γ : Type u} (x : m α) (g : m (α → β)) (h : m (β → γ)), h <*> (g <*> x) = Function.comp <$> h <*> g <*> x
```

 Inherited from 

1. `LawfulMonad m`
2. `WP m ps`

```text
bind_pure_comp : ∀ {α β : Type u} (f : α → β) (x : m α),
  (do
      let a ← x
      pure (f a)) =
    f <$> x
```

 Inherited from 

1. `LawfulMonad m`
2. `WP m ps`

```text
bind_map : ∀ {α β : Type u} (f : m (α → β)) (x : m α),
  (do
      let x_1 ← f
      x_1 <$> x) =
    f <*> x
```

 Inherited from 

1. `LawfulMonad m`
2. `WP m ps`

```text
pure_bind : ∀ {α β : Type u} (x : α) (f : α → m β), pure x >>= f = f x
```

 Inherited from 

1. `LawfulMonad m`
2. `WP m ps`

```text
bind_assoc : ∀ {α β γ : Type u} (x : m α) (f : α → m β) (g : β → m γ), x >>= f >>= g = x >>= fun x => f x >>= g
```

 Inherited from 

1. `LawfulMonad m`
2. `WP m ps`

```text
wp : {α : Type u} → m α → PredTrans ps α
```

 Inherited from 

1. `LawfulMonad m`
2. `WP m ps`

```text
wp_pure : ∀ {α : Type u} (a : α), wp (pure a) = pure a
```

`WP.wp` preserves `pure`.

```text
wp_bind : ∀ {α β : Type u} (x : m α) (f : α → m β),
  (wp do
      let a ← x
      f a) =
    do
    let a ← wp x
    wp (f a)
```

`WP.wp` preserves `bind`.

<a id="Missing--WPMonad--Instance"></a>
Missing `WPMonad` Instance 

The single-field structure `Identity` acts like the identity monad `Id`. It has a `WP` instance, but no `WPMonad` instance:
<a id="Identity-_LPAR_in-Missing--WPMonad--Instance_RPAR_"></a>
<a id="Identity___run-_LPAR_in-Missing--WPMonad--Instance_RPAR_"></a>
<a id="Identity___of_wp_run_eq-_LPAR_in-Missing--WPMonad--Instance_RPAR_"></a>


```proofscript
structure Identity (α : Type u) where
  run : α

variable {α : Type u}

instance : Monad Identity where
  pure x := ⟨x⟩
  bind x f := f x.run

instance : WP Identity .pure where
  wp x := PredTrans.pure x.run

theorem Identity.of_wp_run_eq {x : α} {prog : Identity α}
    (h : Identity.run prog = x) (P : α → Prop) :
    (⊢ₛ wp⟦prog⟧ (⇓ a => ⟨P a⟩)) → P x := by
  simp_all [WP.wp, ← h]
```

The missing instance prevents `mvcgen` from using its specifications for `pure` and `bind`. This tends to show up as a verification condition that's equal to the original goal. This function that reverses a list:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="rev-_LPAR_in-Missing--WPMonad--Instance_RPAR_"></a>


```proofscript
function rev (xs : List α) : Identity (List α) := do
  let mut out := []
  for x in xs do
    out := x :: out
  return out
```

It is correct if it is equal to `List.reverse`. However, `mvcgen` does not make the goal easier to prove:

```proofscript
theorem rev_correct :
    (rev xs).run = xs.reverse := by
  generalize h : (rev xs).run = x
  apply Identity.of_wp_run_eq h
  mvcgen [rev]
```
<a id="--verso-unique-1767"></a>


```lean
unsolved goals
vc1α✝:Type u_1xs x:List α✝h:(rev xs).run = xout✝:List α✝ := []⊢ (wp⟦do
      let __s ← forIn xs out✝ fun x __s => pure (ForInStep.yield (x :: __s))
      pure __s⟧
    (PostCond.noThrow fun a => { down := a = xs.reverse })).down
```

When the verification condition is just the original problem, without even any simplification of `bind`, the problem is usually a missing `WPMonad` instance. The issue can be resolved by adding a suitable instance:

```proofscript
instance : WPMonad Identity .pure where
  wp_pure _ := rfl
  wp_bind _ _ := rfl
```

With this instance, and a suitable invariant, `mvcgen` and `grind` can prove the theorem.

```proofscript
theorem rev_correct :
    (rev xs).run = xs.reverse := by
  generalize h : (rev xs).run = x
  apply Identity.of_wp_run_eq h
  simp only [rev]
  mvcgen invariants
  · ⇓⟨xs, out⟩ =>
    ⌜out = xs.prefix.reverse⌝
  with grind
```

<a id="mvcgen-adequacy"></a>
#### 17.2.3.3. Adequacy Lemmas

Monads that can be invoked from pure code typically provide a invocation operator that takes any required input state as a parameter and returns either a value paired with an output state or some kind of exceptional value. Examples include `StateT.run`, `ExceptT.run`, and `Id.run`. 
<a id="--tech-term-Adequacy-lemmas"></a>
*Adequacy lemmas* provide a bridge between statements about invocations of monadic programs and those programs' [weakest precondition](index.md#--tech-term-weakest-preconditions) semantics as given by their `WP` instances. They show that a property about the invocation is true if its weakest precondition is true.

<a id="Std___Do___Id___of_wp_run_eq"></a>

**theorem**

```text
Std.Do.Id.of_wp_run_eq.{u} {α : Type u} {x : α} {prog : Id α}
  (h : prog.run = x) (P : α → Prop) :
  (⊢ₛ wp⟦prog⟧ (PostCond.noThrow fun a => { down := P a })) → P x
```

Soundness lemma for `Id.run`. Derived from `WPSound.of_wp_canReturn`: `Id.run prog = x` is the `MonadAttach.CanReturn prog x` witness.

<a id="Std___Do___StateM___of_wp_run_eq"></a>

**theorem**

```text
Std.Do.StateM.of_wp_run_eq {α σ : Type} {x : α × σ} {s : σ}
  {prog : StateM σ α} (h : StateT.run prog s = x) (P : α × σ → Prop) :
  (⊢ₛ wp⟦prog⟧ (PostCond.noThrow fun a s' => ⌜P (a, s')⌝) s) → P x
```

Soundness lemma for `StateM.run`: `Id`-specialization of `StateT.of_wp_run`.

<a id="Std___Do___StateM___of_wp_run____eq"></a>

**theorem**

```text
Std.Do.StateM.of_wp_run'_eq {α σ : Type} {x : α} {s : σ}
  {prog : StateM σ α} (h : StateT.run' prog s = x) (P : α → Prop) :
  (⊢ₛ wp⟦prog⟧ (PostCond.noThrow fun a => ⌜P a⌝) s) → P x
```

Soundness lemma for `StateM.run'`: `Id`-specialization of `StateT.of_wp_run`.

<a id="Std___Do___ReaderM___of_wp_run_eq"></a>

**theorem**

```text
Std.Do.ReaderM.of_wp_run_eq.{u} {α ρ : Type u} {x : α} {r : ρ}
  {prog : ReaderM ρ α} (h : ReaderT.run prog r = x) (P : α → Prop) :
  (⊢ₛ wp⟦prog⟧ (PostCond.noThrow fun a x => ⌜P a⌝) r) → P x
```

Soundness lemma for `ReaderM.run`: `Id`-specialization of `ReaderT.of_wp_run`.

<a id="Std___Do___Except___of_wp_eq"></a>

**theorem**

```text
Std.Do.Except.of_wp_eq {ε α : Type} {x prog : Except ε α} (h : prog = x)
  (P : Except ε α → Prop) :
  (⊢ₛ
      wp⟦prog⟧
        (fun a => ⌜P (Except.ok a)⌝, fun e => ⌜P (Except.error e)⌝,
          PUnit.unit)) →
    P x
```

Soundness lemma for `Except`: `Id`-specialization of `ExceptT.of_wp_run`.

<a id="Std___Do___EStateM___of_wp_run_eq"></a>

**theorem**

```text
Std.Do.EStateM.of_wp_run_eq.{u_1} {ε σ : Type u_1} {s : σ}
  {α : Type u_1} {x : EStateM.Result ε σ α} {prog : EStateM ε σ α}
  (h : prog.run s = x) (P : EStateM.Result ε σ α → Prop) :
  (⊢ₛ
      wp⟦prog⟧
        (fun a s' => ⌜P (EStateM.Result.ok a s')⌝, fun e s' =>
          ⌜P (EStateM.Result.error e s')⌝, PUnit.unit)
        s) →
    P x
```

Soundness lemma for `EStateM.run`. Useful if you want to prove a property about an expression `x` defined as `EStateM.run prog s` and you want to use `mvcgen` to reason about `prog`.

<a id="The-Lean-Language-Reference--The--mvcgen--tactic--Predicate-Transformers--Hoare-Triples"></a>
### 17.2.4. Hoare Triples

A 
<a id="--tech-term-Hoare-triple"></a>
*Hoare triple* (Hoare, 1969)C. A. R. Hoare (1969). “An Axiomatic Basis for Computer Programming”. *Communications of the ACM.* **12**(10), pp. 576–583. consists of a precondition, a program, and a postcondition. Running the program in a state for which the precondition is true results in a state where the postcondition is true.

<a id="Std___Do___Triple"></a>

**def**

```text
Std.Do.Triple.{u, v} {m : Type u → Type v} {ps : PostShape} [WP m ps]
  {α : Type u} (x : m α) (P : Assertion ps) (Q : PostCond α ps) : Prop
```

A Hoare triple for reasoning about monadic programs. A Hoare triple `Triple x P Q` is a *specification* for `x`: if assertion `P` holds before `x`, then postcondition `Q` holds after running `x`.

`⦃P⦄ x ⦃Q⦄` is convenient syntax for `Triple x P Q`.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Hoare Triples**

<a id="Std___Do___triple"></a>

```ebnf
term ::= ...
    | ⦃ term ⦄ term ⦃ term ⦄
```

`⦃P⦄ x ⦃Q⦄` is syntactic sugar for `Triple x P Q`.

<a id="Std___Do___Triple___and"></a>

**theorem**

```text
Std.Do.Triple.and.{u, v} {m : Type u → Type v} {ps : PostShape}
  {α : Type u} {P₁ : Assertion ps} {Q₁ : PostCond α ps}
  {P₂ : Assertion ps} {Q₂ : PostCond α ps} [WP m ps] (x : m α)
  (h₁ : ⦃P₁⦄ x ⦃Q₁⦄) (h₂ : ⦃P₂⦄ x ⦃Q₂⦄) : ⦃P₁ ∧ P₂⦄ x ⦃Q₁ ∧ₚ Q₂⦄
```

Conjunction for two Hoare triple specifications of a program `x`. This theorem is useful for decomposing proofs, because unrelated facts about `x` can be proven separately and then combined with this theorem.

<a id="Std___Do___Triple___mp"></a>

**theorem**

```text
Std.Do.Triple.mp.{u, v} {m : Type u → Type v} {ps : PostShape}
  {α : Type u} {P₁ : Assertion ps} {Q₁ : PostCond α ps}
  {P₂ : Assertion ps} {Q₂ : PostCond α ps} [WP m ps] (x : m α)
  (h₁ : ⦃P₁⦄ x ⦃Q₁⦄) (h₂ : ⦃P₂⦄ x ⦃Q₁ →ₚ Q₂⦄) : ⦃P₁ ∧ P₂⦄ x ⦃Q₁ ∧ₚ Q₂⦄
```

Modus ponens for two Hoare triple specifications of a program `x`. This theorem is useful for separating proofs. If `h₁ : Triple x P₁ Q₁` proves a basic property about `x` and `h₂ : Triple x P₂ (Q₁ →ₚ Q₂)` is an advanced proof for `Q₂` that builds on the basic proof for `Q₁`, then `mp x h₁ h₂` is a proof for `Q₂` about `x`.

<a id="The-Lean-Language-Reference--The--mvcgen--tactic--Predicate-Transformers--Specification-Lemmas"></a>
### 17.2.5. Specification Lemmas

<a id="--tech-term-Specification-lemmas"></a>
*Specification lemmas* are designated theorems that associate Hoare triples with functions. When `mvcgen` encounters a function, it checks whether there are any registered specification lemmas and attempts to use them to discharge intermediate [verification conditions](../Overview/index.md#--tech-term-verification-conditions). If there is no applicable specification lemma, then the connection between the statement's pre- and postconditions will become a verification condition. Specification lemmas allow compositional reasoning about libraries of monadic code.

When applied to a theorem whose statement is a Hoare triple, the `spec` attribute registers the theorem as a specification lemma. These lemmas are used in order of priority.

The `spec` attribute may also be applied to definitions. On definitions, it indicates that the definition should be unfolded during verification condition generation.

<a id="attr-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**attribute**

**Specification Lemmas**

<a id="Lean___Parser___Attr___spec"></a>

```ebnf
attr ::= ...
    | spec prio?
```

Theorems tagged with the `spec` attribute are used by the `mspec` and `mvcgen` tactics.

- When used on a theorem `foo_spec : Triple (foo a b c) P Q`, then `mspec` and `mvcgen` will use `foo_spec` as a specification for calls to `foo`.
- Otherwise, when used on a definition that `@[simp]` would work on, it is added to the internal simp set of `mvcgen` that is used within `wp⟦·⟧` contexts to simplify match discriminants and applications of constants.

Universally-quantified variables in specification lemmas can be used to relate input states to output states and return values. These variables are referred to as 
<a id="--tech-term-schematic-variables"></a>
*schematic variables*.

<a id="Schematic-Variables"></a>
Schematic Variables 

The function `double` doubles the value of a `Nat` state:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="double-_LPAR_in-Schematic-Variables_RPAR_"></a>


```proofscript
const double : StateM Nat Unit := do
  modify (2 * ·)
```

Its specification should *relate* the initial and final states, but it cannot know their precise values. The specification uses a schematic variable to stand for the initial state:
<a id="double_spec-_LPAR_in-Schematic-Variables_RPAR_"></a>


```proofscript
theorem double_spec :
    ⦃ fun s => ⌜s = n⌝ ⦄ double ⦃ ⇓ () s => ⌜s = 2 * n⌝ ⦄ := by
  simp [double]
  mvcgen with grind
```

The assertion in the precondition is a function because the `PostShape` of `StateM Nat` is `.arg Nat .pure`, and `Assertion (.arg Nat .pure)` is `SPred [Nat]`.

<a id="The-Lean-Language-Reference--The--mvcgen--tactic--Predicate-Transformers--Invariant-Specifications"></a>
### 17.2.6. Invariant Specifications

These types are used in invariants. The [specification lemmas](index.md#--tech-term-Specification-lemmas) for `ForIn.forIn` and `ForIn'.forIn'` take parameters of type `Invariant`, and `mvcgen` ensures that invariants are not accidentally generated by other automation.

<a id="Std___Do___Invariant"></a>

**def**

```text
Std.Do.Invariant.{u₁, u₂} {α : Type u₁} (xs : List α) (β : Type u₂)
  (ps : PostShape) : Type (max u₂ u₁)
```

The type of loop invariants used by the specifications of `for ... in ...` loops. A loop invariant is a `PostCond` that takes as parameters

- A `List.Cursor xs` representing the iteration state of the loop. It is parameterized by the list of elements `xs` that the `for` loop iterates over.
- A state tuple of type `β`, which will be a nesting of `MProd`s representing the elaboration of `let mut` variables and early return.

The loop specification lemmas will use this in the following way: Before entering the loop, the cursor's prefix is empty and the suffix is `xs`. After leaving the loop, the cursor's prefix is `xs` and the suffix is empty. During the induction step, the invariant holds for a suffix with head element `x`. After running the loop body, the invariant then holds after shifting `x` to the prefix.

<a id="Std___Do___Invariant___withEarlyReturn"></a>

**def**

```text
Std.Do.Invariant.withEarlyReturn.{u₁, u₂} {β : Type (max u₁ u₂)}
  {ps : PostShape} {α : Type (max u₁ u₂)} {xs : List α}
  {γ : Type (max u₁ u₂)} (onContinue : xs.Cursor → β → Assertion ps)
  (onReturn : γ → β → Assertion ps)
  (onExcept : ExceptConds ps := ExceptConds.false) :
  Invariant xs (MProd (Option γ) β) ps
```

Helper definition for specifying loop invariants for loops with early return.

`for ... in ...` loops with early return of type `γ` elaborate to a call like this:

```text
forIn (β := MProd (Option γ) ...) (b := ⟨none, ...⟩) collection loopBody
```

Note that the first component of the `MProd` state tuple is the optional early return value. It is `none` as long as there was no early return and `some r` if the loop returned early with `r`.

This function allows to specify different invariants for the loop body depending on whether the loop terminated early or not. When there was an early return, the loop has effectively finished, which is encoded by the additional `⌜xs.suffix = []⌝` assertion in the invariant. This assertion is vital for successfully proving the induction step, as it contradicts with the assumption that `xs.suffix = x::rest` of the inductive hypothesis at the start of the loop body, meaning that users won't need to prove anything about the bogus case where the loop has returned early yet takes another iteration of the loop body.

Invariants use lists to model the sequence of values in a `for` loop. The current position in the loop is tracked with a `List.Cursor` that represents a position in a list as a combination of the elements to the left of the position and the elements to the right. This type is not a traditional zipper, in which the prefix is reversed for efficient movement: it is intended for use in specifications and proofs, not in run-time code, so the prefix is in the original order.

<a id="List___Cursor___mk"></a>

**structure**

```text
List.Cursor.{u} {α : Type u} (l : List α) : Type u
```

A pointer at a specific location in a list. List cursors are used in loop invariants for the `mvcgen` tactic.

Moving the cursor to the left or right takes time linear in the current position of the cursor, so this data structure is not appropriate for run-time code.

**Constructor**

```text
List.Cursor.mk.{u}
```

**Fields**

```text
prefix : List α
```

The elements before to the current position in the list.

```text
suffix : List α
```

The elements starting at the current position. If the position is after the last element of the list, then the suffix is empty; otherwise, the first element of the suffix is the current element that the cursor points to.

```text
property : self.prefix ++ self.suffix = l
```

Appending the prefix to the suffix yields the original list.

<a id="List___Cursor___at"></a>

**def**

```text
List.Cursor.at.{u_1} {α : Type u_1} (l : List α) (n : Nat) : l.Cursor
```

Creates a cursor at position `n` in the list `l`. The prefix contains the first `n` elements, and the suffix contains the remaining elements. If `n` is larger than the length of the list, the cursor is positioned at the end of the list.

<a id="List___Cursor___pos"></a>

**def**

```text
List.Cursor.pos.{u_1} {α✝ : Type u_1} {l : List α✝} (c : l.Cursor) : Nat
```

The position of the cursor in the list. It's a shortcut for the number of elements in the prefix.

<a id="List___Cursor___current"></a>

**def**

```text
List.Cursor.current.{u_1} {α : Type u_1} {l : List α} (c : l.Cursor)
  (h : 0 < c.suffix.length := by get_elem_tactic) : α
```

Returns the element at the current cursor position.

Requires that is a current element: the suffix must be non-empty, so the cursor is not at the end of the list.

<a id="List___Cursor___tail"></a>

**def**

```text
List.Cursor.tail.{u_1} {α✝ : Type u_1} {l : List α✝} (s : l.Cursor)
  (h : 0 < s.suffix.length := by get_elem_tactic) : l.Cursor
```

Advances the cursor by one position, moving the current element from the suffix to the prefix.

Requires that the cursor is not already at the end of the list.

<a id="List___Cursor___begin"></a>

**def**

```text
List.Cursor.begin.{u_1} {α : Type u_1} (l : List α) : l.Cursor
```

Creates a cursor at the beginning of the list (position 0). The prefix is empty and the suffix is the entire list.

<a id="List___Cursor___end"></a>

**def**

```text
List.Cursor.end.{u_1} {α : Type u_1} (l : List α) : l.Cursor
```

Creates a cursor at the end of the list. The prefix is the entire list and the suffix is empty.

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Embedding of pure Lean values into `SVal`. An alias for `SPred.pure`.
```


### Display 2


```text
Entailment in `SPred`; sugar for `SPred.entails`.
```


### Display 3


```text
Tautology in `SPred`; sugar for `SPred.entails ⌜True⌝`.
```


### Display 4


```text
Bi-entailment in `SPred`; sugar for `SPred.bientails`.
```


### Display 5


```text
An embedding of the special syntax for `SPred` into ordinary terms that provides alternative
interpretations of logical connectives and quantifiers.

Within `spred(...)`, `term(...)` escapes to the ordinary Lean interpretation of this syntax.
```


### Display 6


```text
Escapes from a surrounding `spred(...)` term, returning to the usual interpretations of quantifiers
and connectives.
```


### Display 7


```text
`And a b`, or `a ∧ b`, is the conjunction of propositions. It can be
constructed and destructed like a pair: if `ha : a` and `hb : b` then
`⟨ha, hb⟩ : a ∧ b`, and if `h : a ∧ b` then `h.left : a` and `h.right : b`.


Conventions for notations in identifiers:

 * The recommended spelling of `∧` in identifiers is `and`.
```


### Display 8


```text
`Or a b`, or `a ∨ b`, is the disjunction of propositions. There are two
constructors for `Or`, called `Or.inl : a → a ∨ b` and `Or.inr : b → a ∨ b`,
and you can use `match` or `cases` to destruct an `Or` assumption into the
two cases.


Conventions for notations in identifiers:

 * The recommended spelling of `∨` in identifiers is `or`.
```


### Display 9


```text
`Not p`, or `¬p`, is the negation of `p`. It is defined to be `p → False`,
so if your goal is `¬p` you can use `intro h` to turn the goal into
`h : p ⊢ False`, and if you have `hn : ¬p` and `h : p` then `hn h : False`
and `(hn h).elim` will prove anything.
For more information: [Propositional Logic](https://lean-lang.org/theorem_proving_in_lean4/propositions_and_proofs.html#propositional-logic)


Conventions for notations in identifiers:

 * The recommended spelling of `¬` in identifiers is `not`.
```


### Display 10


```text
If and only if, or logical bi-implication. `a ↔ b` means that `a` implies `b` and vice versa.
By `propext`, this implies that `a` and `b` are equal and hence any expression involving `a`
is equivalent to the corresponding expression with `b` instead.


Conventions for notations in identifiers:

 * The recommended spelling of `↔` in identifiers is `iff`.
```


### Display 11


```text
Explicit binder, like `(x y : A)` or `(x y)`.
Default values can be specified using `(x : A := v)` syntax, and tactics using `(x : A := by tac)`.
```


### Display 12


```text
A *hole* (or *placeholder term*), which stands for an unknown term that is expected to be inferred based on context.
For example, in `@id _ Nat.zero`, the `_` must be the type of `Nat.zero`, which is `Nat`.

The way this works is that holes create fresh metavariables.
The elaborator is allowed to assign terms to metavariables while it is checking definitional equalities.
This is often known as *unification*.

Normally, all holes must be solved for. However, there are a few contexts where this is not necessary:
* In `match` patterns, holes are catch-all patterns.
* In some tactics, such as `refine'` and `apply`, unsolved-for placeholders become new goals.

Related concept: implicit parameters are automatically filled in with holes during the elaboration process.

See also `?m` syntax (synthetic holes).
```


### Display 13


```text
`binderIdent` matches an `ident` or a `_`. It is used for identifiers in binding
position, where `_` means that the value should be left unnamed and inaccessible.
```


### Display 14


```text
A postcondition expressing total correctness.
That is, it expresses that the asserted computation finishes without throwing an exception
*and* the result satisfies the given predicate `p`.
```


### Display 15


```text
A postcondition expressing partial correctness.
That is, it expresses that *if* the asserted computation finishes without throwing an exception
*then* the result satisfies the given predicate `p`.
Nothing is asserted when the computation throws an exception.
```


### Display 16


```text
Entailment of postconditions.

This consists of:
 * Entailment of the assertion about the return value, for all possible return values.
 * Entailment of the exception conditions.

While implication of postconditions (`PostCond.imp`) results in a new postcondition, entailment is
an ordinary proposition.
```


### Display 17


```text
Conjunction of postconditions.

This is defined pointwise, as the conjunction of the assertions about the return value and the
conjunctions of the assertions about each potential exception.
```


### Display 18


```text
Implication of postconditions.

This is defined pointwise, as the implication of the assertions about the return value and the
implications of each of the assertions about each potential exception.

While entailment of postconditions (`PostCond.entails`) is an ordinary proposition, implication of
postconditions is itself a postcondition.
```


### Display 19


```text
`wp⟦x⟧ Q` is defined as `(WP.wp x).apply Q`.
```


### Display 20


```text
A Hoare triple for reasoning about monadic programs. A Hoare triple `Triple x P Q` is a
*specification* for `x`: if assertion `P` holds before `x`, then postcondition `Q` holds after
running `x`.

`⦃P⦄ x ⦃Q⦄` is convenient syntax for `Triple x P Q`.
```


### Display 21


```text
Theorems tagged with the `spec` attribute are used by the `mspec` and `mvcgen` tactics.

* When used on a theorem `foo_spec : Triple (foo a b c) P Q`, then `mspec` and `mvcgen` will use
  `foo_spec` as a specification for calls to `foo`.
* Otherwise, when used on a definition that `@[simp]` would work on, it is added to the internal
  simp set of `mvcgen` that is used within `wp⟦·⟧` contexts to simplify match discriminants and
  applications of constants.
```


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
unsolved goals
vc1α✝:Type u_1xs x:List α✝h:(rev xs).run = xout✝:List α✝ := []⊢ (wp⟦do
      let __s ← forIn xs out✝ fun x __s => pure (ForInStep.yield (x :: __s))
      pure __s⟧
    (PostCond.noThrow fun a => { down := a = xs.reverse })).down
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
α:Type ux:αprog:Identity αh:prog.run = xP:α → Prop⊢ (⊢ₛ wp⟦prog⟧ (PostCond.noThrow fun a => { down := P a })) → P x
```


### Display 2


```text
All goals completed! 🐙
```


### Display 3


```text
α✝:Type u_1xs:List α✝⊢ (rev xs).run = xs.reverse
```


### Display 4


```text
α✝:Type u_1xs:List α✝x:List α✝h:(rev xs).run = x⊢ x = xs.reverse
```


### Display 5


```text
α✝:Type u_1xs:List α✝x:List α✝h:(rev xs).run = x⊢ ⊢ₛ wp⟦rev xs⟧ (PostCond.noThrow fun a => { down := a = xs.reverse })
```


### Display 6


```text
vc1α✝:Type u_1xs:List α✝x:List α✝h:(rev xs).run = xout✝:List α✝ := []⊢ (wp⟦do
      let __s ← forIn xs out✝ fun x __s => pure (ForInStep.yield (x :: __s))
      pure __s⟧
    (PostCond.noThrow fun a => { down := a = xs.reverse })).down
```


### Display 7


```text
α✝:Type u_1xs:List α✝x:List α✝h:(rev xs).run = x⊢ ⊢ₛ
  wp⟦do
      let __s ← forIn xs [] fun x __s => pure (ForInStep.yield (x :: __s))
      pure __s⟧
    (PostCond.noThrow fun a => { down := a = xs.reverse })
```


### Display 8


```text
n:Nat⊢ ⦃fun s => ⌜s = n⌝⦄ double ⦃PostCond.noThrow fun x s => ⌜s = 2 * n⌝⦄
```


### Display 9


```text
n:Nat⊢ ⦃fun s => ⌜s = n⌝⦄ modify fun x => 2 * x ⦃PostCond.noThrow fun x s => ⌜s = 2 * n⌝⦄
```

