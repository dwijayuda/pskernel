<a id="ordinary-coercion"></a>

# ProofScript — 11.2. Coercing Between Types

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Coercions are native elaboration mechanisms, including coercion between types, to sorts and to function types. They are not JavaScript conversions based on truthiness or object prototypes. An implementation must preserve the selected coercion or reject the unsupported case. A foreign value needs an appropriate decoder or model before it can satisfy an owned logical invariant.

**Compiler and coverage boundary.** Record inserted coercions and their dependencies. Do not replace dependent coercions with unchecked target casts.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Coercions/Coercing-Between-Types/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Coercions/Coercing-Between-Types/index.html). Source Git blob: `1ce6b242f38cc101a1f0e926c2d8f92c4283a486`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 11.2. Coercing Between Types

Coercions between types are inserted when the Lean elaborator successfully constructs a term, inferring its type, in a context where a term of some other type was expected. Before signaling an error, the elaborator attempts to insert a coercion from the inferred type to the expected type by synthesizing an instance of `CoeT`. There are two ways that this might succeed:

1. There could be a chain of coercions from the inferred type to the expected type through a number of intermediate types. These chained coercions are selected based on the inferred type and the expected type, but not the term being coerced.
2. There could be a single dependent coercion from the inferred type to the expected type. Dependent coercions take the term being coerced into account as well as the inferred and expected types, but they cannot be chained.

The simplest way to define a non-dependent coercion is by implementing a `Coe` instance, which is enough to synthesize a `CoeT` instance. This instance participates in chaining, and may be applied any number of times. The expected type of the expression is used to drive synthesis of `Coe` instances, rather than the inferred type. For instances that can be used at most once, or instances in which the inferred type should drive synthesis, one of the other coercion classes may be needed.

<a id="Defining-Coercions"></a>
Defining Coercions 

The type `Even` represents the even natural numbers.
<a id="Even-_LPAR_in-Defining-Coercions_RPAR_"></a>
<a id="Even___number-_LPAR_in-Defining-Coercions_RPAR_"></a>
<a id="Even___isEven-_LPAR_in-Defining-Coercions_RPAR_"></a>


```proofscript
structure Even where
  number : Nat
  isEven : number % 2 = 0
```

A coercion allows even numbers to be used where natural numbers are expected. The `coe` attribute marks the projection as a coercion so that it can be shown accordingly in proof states and error messages, as described in the [section on implementing coercions](index.md#coercion-impl).

```proofscript
attribute [coe] Even.number

instance : Coe Even Nat where
  coe := Even.number
```

With this coercion in place, even numbers can be used where natural numbers are expected.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="four-_LPAR_in-Defining-Coercions_RPAR_"></a>


```proofscript
const four : Even := ⟨4, by omega⟩

#eval (four : Nat) + 1
```

```lean
5
```

Due to coercion chaining, there is also a coercion from `Even` to `Int` formed by chaining the `Coe Even Nat` instance with the existing coercion from `Nat` to `Int`:

```proofscript
#eval (four : Int) - 5
```

```lean
-1
```

<a id="--tech-term-Dependent-coercions"></a>
Dependent coercions are needed when the specific term being coerced is required in order to determine whether or how to coerce the term: for example, only decidable propositions can be coerced to `Bool`, so the proposition in question must occur as part of the instance's type so that it can require the `Decidable` instance. Non-dependent coercions are used whenever all values of the inferred type can be coerced to the target type.

<a id="Defining-Dependent-Coercions"></a>
Defining Dependent Coercions 

The string `"four"` can be coerced into the natural number `4` with this instance declaration:

```proofscript
instance : CoeDep String "four" Nat where
  coe := 4

#eval ("four" : Nat)
```

```lean
4
```

Ordinary type errors are produced for other strings:

```proofscript
#eval ("three" : Nat)
```

```lean
Type mismatch
  "three"
has type
  String
but is expected to have type
  Nat
```

Non-dependent coercions may be chained: if there is a coercion from `α` to `β` and from `β` to `γ`, then there is also a coercion from `α` to `γ`. 
<a id="--index--next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
 The chain should be in the form `CoeHead`?`CoeOut`*`Coe`*`CoeTail`?, which is to say it may consist of:

- An optional instance of `CoeHead α α'`, followed by
- Zero or more instances of `CoeOut α' …`, …, `CoeOut … α''`, followed by
- Zero or more instances of `Coe α'' …`, …, `Coe … β'`, followed by
- An optional instance of `CoeTail β' γ`

Most coercions can be implemented as instances of `Coe`. `CoeHead`, `CoeOut`, and `CoeTail` are needed in certain special situations.

`CoeHead` and `CoeOut` instances are chained from the inferred type towards the expected type. In other words, information in the type found for the term is used to resolve a chain of instances. `Coe` and `CoeTail` instances are chained from the expected type towards the inferred type, so information in the expected type is used to resolve a chain of instances. If these chains meet in the middle, a coercion has been found. This is reflected in their type signatures: `CoeHead` and `CoeOut` use [semi-output parameters](../../Type-Classes/Instance-Synthesis/index.md#--tech-term-Semi-output-parameters) for the coercion's target, while `Coe` and `CoeTail` use [semi-output parameters](../../Type-Classes/Instance-Synthesis/index.md#--tech-term-Semi-output-parameters) for the coercions' source.

When an instance provides a value for a [semi-output parameter](../../Type-Classes/Instance-Synthesis/index.md#--tech-term-Semi-output-parameters), the value is used during instance synthesis. However, if no value is provided, then a value may be assigned by the synthesis algorithm. Consequently, every semi-output parameter should be assigned a type when an instance is selected. This means that `CoeOut` should be used when the variables that occur in the coercion's output are a subset of those in its input, and `Coe` should be used when the variables in the input are a subset of those in the output.

<a id="CoeOut--vs--Coe--instances"></a>
`CoeOut` vs `Coe` instances 

A `Truthy` value is a value paired with an indication of whether it should be considered to be true or false. A `Decision` is either `yes`, `no`, or `maybe`, with the latter containing further data for consideration.
<a id="Truthy-_LPAR_in-CoeOut--vs--Coe--instances_RPAR_"></a>
<a id="Truthy___val-_LPAR_in-CoeOut--vs--Coe--instances_RPAR_"></a>
<a id="Truthy___isTrue-_LPAR_in-CoeOut--vs--Coe--instances_RPAR_"></a>
<a id="Decision-_LPAR_in-CoeOut--vs--Coe--instances_RPAR_"></a>
<a id="Decision___yes-_LPAR_in-CoeOut--vs--Coe--instances_RPAR_"></a>
<a id="Decision___maybe-_LPAR_in-CoeOut--vs--Coe--instances_RPAR_"></a>
<a id="Decision___no-_LPAR_in-CoeOut--vs--Coe--instances_RPAR_"></a>


```proofscript
structure Truthy (α : Type) where
  val : α
  isTrue : Bool

inductive Decision (α : Type) where
  | yes
  | maybe (val : α)
  | no
```

“Truthy” values can be converted to `Bool`s by forgetting the contained value. `Bool`s can be converted to `Decision`s by discounting the `maybe` case.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="Truthy___toBool-_LPAR_in-CoeOut--vs--Coe--instances_RPAR_"></a>
<a id="Decision___ofBool-_LPAR_in-CoeOut--vs--Coe--instances_RPAR_"></a>


```proofscript
@[coe]
const Truthy.toBool : Truthy α → Bool :=
  Truthy.isTrue

@[coe]
def Decision.ofBool : Bool → Decision α
  | true => .yes
  | false => .no
```

`Truthy.toBool` must be a `CoeOut` instance, because the target of the coercion contains fewer unknown type variables than the source, while `Decision.ofBool` must be a `Coe` instance, because the source of the coercion contains fewer variables than the target:

```proofscript
instance : CoeOut (Truthy α) Bool := ⟨Truthy.isTrue⟩

instance : Coe Bool (Decision α) := ⟨Decision.ofBool⟩
```

With these instances, coercion chaining works:

```proofscript
#eval ({ val := 1, isTrue := true : Truthy Nat } : Decision String)
```

```lean
Decision.yes
```

Attempting to use the wrong class leads to an error:

```proofscript
instance : Coe (Truthy α) Bool := ⟨Truthy.isTrue⟩
```

```lean
instance does not provide concrete values for (semi-)out-params
  Coe (Truthy ?α) Bool
```

<a id="CoeHead___mk"></a>

**type class**

```text
CoeHead.{u, v} (α : Sort u) (β : semiOutParam (Sort v)) :
  Sort (max (max 1 u) v)
```

`CoeHead α β` is for coercions that are applied from left-to-right at most once at beginning of the coercion chain.

**Instance Constructor**

```text
CoeHead.mk.{u, v}
```

**Methods**

```text
coe : α → β
```

Coerces a value of type `α` to type `β`. Accessible by the notation `↑x`, or by double type ascription `((x : α) : β)`.

<a id="CoeOut___mk"></a>

**type class**

```text
CoeOut.{u, v} (α : Sort u) (β : semiOutParam (Sort v)) :
  Sort (max (max 1 u) v)
```

`CoeOut α β` is for coercions that are applied from left-to-right.

**Instance Constructor**

```text
CoeOut.mk.{u, v}
```

**Methods**

```text
coe : α → β
```

Coerces a value of type `α` to type `β`. Accessible by the notation `↑x`, or by double type ascription `((x : α) : β)`.

<a id="CoeTail___mk"></a>

**type class**

```text
CoeTail.{u, v} (α : semiOutParam (Sort u)) (β : Sort v) :
  Sort (max (max 1 u) v)
```

`CoeTail α β` is for coercions that can only appear at the end of a sequence of coercions. That is, `α` can be further coerced via `Coe σ α` and `CoeHead τ σ` instances but `β` will only be the expected type of the expression.

**Instance Constructor**

```text
CoeTail.mk.{u, v}
```

**Methods**

```text
coe : α → β
```

Coerces a value of type `α` to type `β`. Accessible by the notation `↑x`, or by double type ascription `((x : α) : β)`.

Instances of `CoeT` can be synthesized when an appropriate chain of instances exists, or when there is a single applicable `CoeDep` instance.When coercing from `Nat` to another type, a `NatCast` instances also suffices. If both exist, then the `CoeDep` instance takes priority.

<a id="CoeT___mk"></a>

**type class**

```text
CoeT.{u, v} (α : Sort u) : α → (β : Sort v) → Sort (max 1 v)
```

`CoeT` is the core typeclass which is invoked by Lean to resolve a type error. It can also be triggered explicitly with the notation `↑x` or by double type ascription `((x : α) : β)`.

A `CoeT` chain has the grammar `CoeHead? CoeOut* Coe* CoeTail? | CoeDep`.

**Instance Constructor**

```text
CoeT.mk.{u, v}
```

**Methods**

```text
coe : β
```

The resulting value of type `β`. The input `x : α` is a parameter to the type class, so the value of type `β` may possibly depend on additional typeclasses on `x`.

Dependent coercions may not be chained. As an alternative to a chain of coercions, a term `e` of type `α` can be coerced to `β` using an instance of `CoeDep α e β`. Dependent coercions are useful in situations where only some of the values can be coerced; this mechanism is used to coerce only decidable propositions to `Bool`. They are also useful when the value itself occurs in the coercion's target type.

<a id="CoeDep___mk"></a>

**type class**

```text
CoeDep.{u, v} (α : Sort u) : α → (β : Sort v) → Sort (max 1 v)
```

`CoeDep α (x : α) β` is a typeclass for dependent coercions, that is, the type `β` can depend on `x` (or rather, the value of `x` is available to typeclass search so an instance that relates `β` to `x` is allowed).

Dependent coercions do not participate in the transitive chaining process of regular coercions: they must exactly match the type mismatch on both sides.

**Instance Constructor**

```text
CoeDep.mk.{u, v}
```

**Methods**

```text
coe : β
```

The resulting value of type `β`. The input `x : α` is a parameter to the type class, so the value of type `β` may possibly depend on additional typeclasses on `x`.

<a id="Dependent-Coercion"></a>
Dependent Coercion 

A type of non-empty lists can be defined as a pair of a list and a proof that it is not empty. This type can be coerced to ordinary lists by applying the projection:
<a id="NonEmptyList-_LPAR_in-Dependent-Coercion_RPAR_"></a>
<a id="NonEmptyList___contents-_LPAR_in-Dependent-Coercion_RPAR_"></a>
<a id="NonEmptyList___non_empty-_LPAR_in-Dependent-Coercion_RPAR_"></a>


```proofscript
structure NonEmptyList (α : Type u) : Type u where
  contents : List α
  non_empty : contents ≠ []

instance : Coe (NonEmptyList α) (List α) where
  coe xs := xs.contents
```

The coercion works as expected:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="oneTwoThree-_LPAR_in-Dependent-Coercion_RPAR_"></a>


```proofscript
const oneTwoThree : NonEmptyList Nat := ⟨[1, 2, 3], by simp⟩

#eval (oneTwoThree : List Nat) ++ [4]
```

Arbitrary lists cannot, however, be coerced to non-empty lists, because some arbitrarily-chosen lists may indeed be empty:

```proofscript
instance : Coe (List α) (NonEmptyList α) where
  coe xs := ⟨xs, _⟩
```

```lean
don't know how to synthesize placeholder for argument `non_empty`
context:
α:Type u_1xs:List α⊢ xs ≠ []
```

A dependent coercion can restrict the domain of the coercion to only lists that are not empty:

```proofscript
instance : CoeDep (List α) (x :: xs) (NonEmptyList α) where
  coe := ⟨x :: xs, by simp⟩

#eval ([1, 2, 3] : NonEmptyList Nat)
```

```lean
{ contents := [1, 2, 3], non_empty := _ }
```

Dependent coercion insertion requires that the term to be coerced syntactically matches the term in the instance header. Lists that are known to be non-empty, but which are not syntactically instances of `(· :: ·)`, cannot be coerced with this instance.

```proofscript
#check
  fun (xs : List Nat) =>
    let ys : List Nat := xs ++ [4]
    (ys : NonEmptyList Nat)
```

When coercion insertion fails, the original type error is reported:

```lean
Type mismatch
  ys
has type
  List Nat
but is expected to have type
  NonEmptyList Nat
```

<a id="term-next-next-next-next-next"></a>

**syntax**

**Coercions**

<a id="coeNotation"></a>

```ebnf
term ::= ...
    | ↑term
```

Coercions can be explicitly placed using the prefix operator [`↑`](index.md#coeNotation).

Unlike using nested [type ascriptions](../../Terms/Type-Ascription/index.md#--tech-term-Type-ascriptions), the [`↑`](index.md#coeNotation) syntax for placing coercions does not require the involved types to be written explicitly.

<a id="Controlling-Coercion-Insertion"></a>
Controlling Coercion Insertion 

Instance synthesis and coercion insertion interact with one another. Synthesizing an instance may make type information known that later triggers coercion insertion. The specific placement of coercions may matter.

In this definition of `sub`, the `Sub Int` instance is synthesized based on the function's return type. This instance requires that the two parameters also be `Int`s, but they are `Nat`s. Coercions are inserted around each argument to the subtraction operator. This can be seen in the output of `#print`.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="sub-_LPAR_in-Controlling-Coercion-Insertion_RPAR_"></a>


```proofscript
function sub (n k : Nat) : Int := n - k

#print sub
```

```lean
def sub : Nat → Nat → Int :=
fun n k => ↑n - ↑k
```

Placing the coercion operator outside the subtraction causes the elaborator to attempt to infer a type for the subtraction and then insert a coercion. Because the arguments are both `Nat`s, the `Sub Nat` instance is selected, leading to the difference being a `Nat`. The difference is then coerced to an `Int`.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="sub___-_LPAR_in-Controlling-Coercion-Insertion_RPAR_"></a>


```proofscript
function sub' (n k : Nat) : Int := ↑ (n - k)

#print sub'
```

These two functions are not equivalent because subtraction of natural numbers truncates at zero:

```proofscript
#eval sub 4 8
```

```lean
-4
```

```proofscript
#eval sub' 4 8
```

```lean
0
```

<a id="coercion-impl"></a>
### 11.2.1. Implementing Coercions

The appropriate `CoeHead`, `CoeOut`, `Coe`, or `CoeTail` instance is sufficient to cause a desired coercion to be inserted. However, the implementation of the coercion should be registered as a coercion using the `coe` attribute. This causes Lean to display uses of the coercion with the [`↑`](index.md#coeNotation) operator. It also causes the `norm_cast` tactic to treat the coercion as a cast, rather than as an ordinary function.

<a id="attr-next-next-next-next-next"></a>

**attribute**

**Coercion Declarations**

<a id="Lean___Attr___coe"></a>

```ebnf
attr ::= ...
    | coe
```

The `@[coe]` attribute on a function (which should also appear in a `instance : Coe A B := ⟨myFn⟩` declaration) allows the delaborator to show applications of this function as `↑` when printing expressions.

<a id="Implementing-Coercions"></a>
Implementing Coercions 

The [enum inductive](../../The-Type-System/Inductive-Types/index.md#--tech-term-enum-inductive) type `Weekday` represents the days of the week:
<a id="Weekday-_LPAR_in-Implementing-Coercions_RPAR_"></a>
<a id="Weekday___mo-_LPAR_in-Implementing-Coercions_RPAR_"></a>
<a id="Weekday___tu-_LPAR_in-Implementing-Coercions_RPAR_"></a>
<a id="Weekday___we-_LPAR_in-Implementing-Coercions_RPAR_"></a>
<a id="Weekday___th-_LPAR_in-Implementing-Coercions_RPAR_"></a>
<a id="Weekday___fr-_LPAR_in-Implementing-Coercions_RPAR_"></a>
<a id="Weekday___sa-_LPAR_in-Implementing-Coercions_RPAR_"></a>
<a id="Weekday___su-_LPAR_in-Implementing-Coercions_RPAR_"></a>


```proofscript
inductive Weekday where
  | mo | tu | we | th | fr | sa | su
```

As a seven-element type, it contains the same information as `Fin 7`. There is a bijection:
<a id="Weekday___toFin-_LPAR_in-Implementing-Coercions_RPAR_"></a>
<a id="Weekday___fromFin-_LPAR_in-Implementing-Coercions_RPAR_"></a>


```proofscript
def Weekday.toFin : Weekday → Fin 7
  | mo => 0
  | tu => 1
  | we => 2
  | th => 3
  | fr => 4
  | sa => 5
  | su => 6

def Weekday.fromFin : Fin 7 → Weekday
  | 0 => mo
  | 1 => tu
  | 2 => we
  | 3 => th
  | 4 => fr
  | 5 => sa
  | 6 => su
```

Each type can be coerced to the other:

```proofscript
instance : Coe Weekday (Fin 7) where
  coe := Weekday.toFin

instance : Coe (Fin 7) Weekday where
  coe := Weekday.fromFin
```

While this works, instances of the coercions that occur in Lean's output are not presented using the coercion operator, which is what Lean users expect. Instead, the name `Weekday.fromFin` is used explicitly:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="wednesday-_LPAR_in-Implementing-Coercions_RPAR_"></a>


```proofscript
const wednesday : Weekday := (2 : Fin 7)

#print wednesday
```

```lean
def wednesday : Weekday :=
Weekday.fromFin 2
```

Adding the `coe` attribute to the definition of a coercion causes it to be displayed using the coercion operator:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="friday-_LPAR_in-Implementing-Coercions_RPAR_"></a>


```proofscript
attribute [coe] Weekday.fromFin
attribute [coe] Weekday.toFin

const friday : Weekday := (5 : Fin 7)

#print friday
```

```lean
def friday : Weekday :=
↑5
```

<a id="nat-api-cast"></a>
### 11.2.2. Coercions from Natural Numbers and Integers

The type classes `NatCast` and `IntCast` are special cases of `Coe` that are used to define a coercion from `Nat` or `Int` to some other type that is in some sense canonical. They exist to enable better integration with large libraries of mathematics, such as [Mathlib](https://github.com/leanprover-community/mathlib4), that make heavy use of coercions to map from the natural numbers or integers to other structures (typically rings). Ideally, the coercion of a natural number or integer into these structures is a [simp normal form](../../The-Simplifier/Simp-Normal-Forms/index.md#--tech-term-simp-normal-form), because it is a convenient way to denote them.

When the coercion application is expected to be the [simp normal form](../../The-Simplifier/Simp-Normal-Forms/index.md#--tech-term-simp-normal-form) for a type, it is important that *all* such coercions are [definitionally equal](../../The-Type-System/index.md#--tech-term-definitional-equality) in practice. Otherwise, the [simp normal form](../../The-Simplifier/Simp-Normal-Forms/index.md#--tech-term-simp-normal-form) would need to choose a single chained coercion path, but lemmas could accidentally be stated using a different path. Because `simp`'s internal index is based on the underlying structure of the term, rather than its presentation in the surface syntax, these differences would cause the lemmas to not be applied where expected. `NatCast` and `IntCast` instances, on the other hand, should be defined such that they are always [definitionally equal](../../The-Type-System/index.md#--tech-term-definitional-equality), avoiding the problem. The Lean standard library's instances are arranged such that `NatCast` or `IntCast` instances are chosen preferentially over chains of coercion instances during coercion insertion. They can also be used as `CoeOut` instances, allowing a graceful fallback to coercion chaining when needed.

<a id="NatCast___mk"></a>

**type class**

```text
NatCast.{u} (R : Type u) : Type u
```

The canonical homomorphism `Nat → R`. In most use cases, the target type will have a (semi)ring structure, and this homomorphism should be a (semi)ring homomorphism.

`NatCast` and `IntCast` exist to allow different libraries with their own types that can be notated as natural numbers to have consistent `simp` normal forms without needing to create coercion simplification sets that are aware of all combinations. Libraries should make it easy to work with `NatCast` where possible. For instance, in Mathlib there will be such a homomorphism (and thus a `NatCast R` instance) whenever `R` is an additive monoid with a `1`.

The prototypical example is `Int.ofNat`.

**Instance Constructor**

```text
NatCast.mk.{u}
```

**Methods**

```text
natCast : Nat → R
```

The canonical map `Nat → R`.

<a id="Nat___cast"></a>

**def**

```text
Nat.cast.{u} {R : Type u} [NatCast R] : Nat → R
```

The canonical homomorphism `Nat → R`. In most use cases, the target type will have a (semi)ring structure, and this homomorphism should be a (semi)ring homomorphism.

`NatCast` and `IntCast` exist to allow different libraries with their own types that can be notated as natural numbers to have consistent `simp` normal forms without needing to create coercion simplification sets that are aware of all combinations. Libraries should make it easy to work with `NatCast` where possible. For instance, in Mathlib there will be such a homomorphism (and thus a `NatCast R` instance) whenever `R` is an additive monoid with a `1`.

The prototypical example is `Int.ofNat`.

<a id="IntCast___mk"></a>

**type class**

```text
IntCast.{u} (R : Type u) : Type u
```

The canonical homomorphism `Int → R`. In most use cases, the target type will have a ring structure, and this homomorphism should be a ring homomorphism.

`IntCast` and `NatCast` exist to allow different libraries with their own types that can be notated as natural numbers to have consistent `simp` normal forms without needing to create coercion simplification sets that are aware of all combinations. Libraries should make it easy to work with `IntCast` where possible. For instance, in Mathlib there will be such a homomorphism (and thus an `IntCast R` instance) whenever `R` is an additive group with a `1`.

**Instance Constructor**

```text
IntCast.mk.{u}
```

**Methods**

```text
intCast : Int → R
```

The canonical map `Int → R`.

<a id="Int___cast"></a>

**def**

```text
Int.cast.{u} {R : Type u} [IntCast R] : Int → R
```

The canonical homomorphism `Int → R`. In most use cases, the target type will have a ring structure, and this homomorphism should be a ring homomorphism.

`IntCast` and `NatCast` exist to allow different libraries with their own types that can be notated as natural numbers to have consistent `simp` normal forms without needing to create coercion simplification sets that are aware of all combinations. Libraries should make it easy to work with `IntCast` where possible. For instance, in Mathlib there will be such a homomorphism (and thus an `IntCast R` instance) whenever `R` is an additive group with a `1`.

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
`↑x` represents a coercion, which converts `x` of type `α` to type `β`, using
typeclasses to resolve a suitable conversion function. You can often leave the
`↑` off entirely, since coercion is triggered implicitly whenever there is a
type error, but in ambiguous cases it can be useful to use `↑` to disambiguate
between e.g. `↑x + ↑y` and `↑(x + y)`.
```


### Display 2


```text
The `@[coe]` attribute on a function (which should also appear in a
`instance : Coe A B := ⟨myFn⟩` declaration) allows the delaborator to show
applications of this function as `↑` when printing expressions.
```


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
5
```


### Display 2


```text
-1
```


### Display 3


```text
4
```


### Display 4


```text
Type mismatch
  "three"
has type
  String
but is expected to have type
  Nat
```


### Display 5


```text
Decision.yes
```


### Display 6


```text
instance does not provide concrete values for (semi-)out-params
  Coe (Truthy ?α) Bool
```


### Display 7


```text
[1, 2, 3, 4]
```


### Display 8


```text
don't know how to synthesize placeholder for argument `non_empty`
context:
α:Type u_1xs:List α⊢ xs ≠ []
```


### Display 9


```text
{ contents := [1, 2, 3], non_empty := _ }
```


### Display 10


```text
fun xs =>
  let ys := xs ++ [4];
  sorry : (xs : List Nat) → ?m.14 xs
```


### Display 11


```text
Type mismatch
  ys
has type
  List Nat
but is expected to have type
  NonEmptyList Nat
```


### Display 12


```text
def sub : Nat → Nat → Int :=
fun n k => ↑n - ↑k
```


### Display 13


```text
def sub' : Nat → Nat → Int :=
fun n k => ↑(n - k)
```


### Display 14


```text
-4
```


### Display 15


```text
0
```


### Display 16


```text
def wednesday : Weekday :=
Weekday.fromFin 2
```


### Display 17


```text
def friday : Weekday :=
↑5
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
⊢ 4 % 2 = 0
```


### Display 2


```text
All goals completed! 🐙
```


### Display 3


```text
⊢ [1, 2, 3] ≠ []
```


### Display 4


```text
α:Type ?u.7x:αxs:List α⊢ x :: xs ≠ []
```

