<a id="The-Lean-Language-Reference--The-Type-System--Universes"></a>

# ProofScript — 4.3. Universes

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Functions, propositions, universes, inductives and quotients retain their Lean meaning. A proof is an inhabitant of a proposition; Boolean truth is not the same object. Parameters may determine later parameter types. Universe levels cannot be approximated as machine integer ranks. Inductive constructors require the native positivity, universe, parameter and index checks. Quotient eliminators must respect their relation, rather than use runtime object identity.

**Compiler and coverage boundary.** Use exact declared core rules and axiom policies. Library names and hash matches alone cannot authorize primitive reductions. Soundness and exact acceptance equivalence are distinct obligations.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [The-Type-System/Universes/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/The-Type-System/Universes/index.html). Source Git blob: `b620183483ba04f6f45b24d35650f02bd1d9631f`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Constructor"></a>
<a id="docstring-section-Fields"></a>
<a id="docstring-section-Constructor-next"></a>
<a id="docstring-section-Fields-next"></a>

---

## 4.3. Universes

Types are classified by 
<a id="--tech-term-universes"></a>
*universes*. 
<a id="--index--next-next"></a>
Universes are also referred to as 
<a id="--tech-term-sorts"></a>
*sorts*. Each universe has a 
<a id="--tech-term-level"></a>
*level*, 
<a id="--index--next-next-next"></a>
 which is a natural number. The `Sort` operator constructs a universe from a given level. 
<a id="--index--next-next-next-next"></a>
 If the level of a universe is smaller than that of another, the universe itself is said to be smaller. With the exception of propositions (described later in this chapter), types in a given universe may only quantify over types in smaller universes. `Sort 0` is the type of propositions, while each `Sort (u + 1)` is a type that describes data.

Every universe is an element of the next larger universe, so `Sort 5` includes `Sort 4`. This means that the following examples are accepted:

```proofscript
example : Sort 5 := Sort 4
example : Sort 2 := Sort 1
```

On the other hand, `Sort 3` is not an element of `Sort 5`:

```proofscript
example : Sort 5 := Sort 3
```

```lean
Type mismatch
  Type 2
has type
  Type 3
of sort `Type 4` but is expected to have type
  Type 4
of sort `Type 5`
```

Similarly, because `Unit` is in `Sort 1`, it is not in `Sort 2`:

```proofscript
example : Sort 1 := Unit
```

```proofscript
example : Sort 2 := Unit
```

```lean
Type mismatch
  Unit
has type
  Type
of sort `Type 1` but is expected to have type
  Type 1
of sort `Type 2`
```

Because propositions and data are used differently and are governed by different rules, the abbreviations `Type` and `Prop` are provided to make the distinction more convenient. 
<a id="--index--next-next-next-next-next"></a>

<a id="--index--next-next-next-next-next-next"></a>
 `Type u` is an abbreviation for `Sort (u + 1)`, so `Type 0` is `Sort 1` and `Type 3` is `Sort 4`. `Type 0` can also be abbreviated `Type`, so `Unit : Type` and `Type : Type 1`. `Prop` is an abbreviation for `Sort 0`.

<a id="The-Lean-Language-Reference--The-Type-System--Universes--Predicativity"></a>
### 4.3.1. Predicativity

Each universe contains dependent function types, which additionally represent universal quantification and implication. A function type's universe is determined by the universes of its argument and return types. The specific rules depend on whether the return type of the function is a proposition.

Predicates, which are functions that return propositions (that is, where the result of the function is some type in `Prop`) may have argument types in any universe whatsoever, but the function type itself remains in `Prop`. In other words, propositions feature 
<a id="--tech-term-impredicative"></a>
*impredicative* 
<a id="--index--next-next-next-next-next-next-next"></a>

<a id="--index--next-next-next-next-next-next-next-next"></a>
 quantification, because propositions can themselves be statements about all propositions (and all other types).

<a id="Impredicativity"></a>
Impredicativity 

Proof irrelevance can be written as a proposition that quantifies over all propositions:

```proofscript
example : Prop := ∀ (P : Prop) (p1 p2 : P), p1 = p2
```

A proposition may also quantify over all types, at any given level:

```proofscript
example : Prop := ∀ (α : Type), ∀ (x : α), x = x
example : Prop := ∀ (α : Type 5), ∀ (x : α), x = x
```

For universes at [level](index.md#--tech-term-level) `1` and higher (that is, the `Type u` hierarchy), quantification is 
<a id="--tech-term-predicative"></a>
*predicative*. 
<a id="--index--next-next-next-next-next-next-next-next-next"></a>

<a id="--index--next-next-next-next-next-next-next-next-next-next"></a>
 For these universes, the universe of a function type is the least upper bound of the argument and return types' universes.

<a id="Universe-levels-of-function-types"></a>
Universe levels of function types 

Both of these types are in `Type 2`:

```proofscript
example (α : Type 1) (β : Type 2) : Type 2 := α → β
example (α : Type 2) (β : Type 1) : Type 2 := α → β
```

<a id="Predicativity-of--Type"></a>
Predicativity of `Type` 

This example is not accepted, because `α`'s level is greater than `1`. In other words, the annotated universe is smaller than the function type's universe:

```proofscript
example (α : Type 2) (β : Type 1) : Type 1 := α → β
```

```lean
Type mismatch
  α → β
has type
  Type 2
of sort `Type 3` but is expected to have type
  Type 1
of sort `Type 2`
```

Lean's universes are not 
<a id="--tech-term-cumulative"></a>
cumulative;
<a id="--index--next-next-next-next-next-next-next-next-next-next-next"></a>
 a type in `Type u` is not automatically also in `Type (u + 1)`. Each type inhabits precisely one universe.

<a id="No-cumulativity"></a>
No cumulativity 

This example is not accepted because the annotated universe is larger than the function type's universe:

```proofscript
example (α : Type 2) (β : Type 1) : Type 3 := α → β
```

```lean
Type mismatch
  α → β
has type
  Type 2
of sort `Type 3` but is expected to have type
  Type 3
of sort `Type 4`
```

<a id="The-Lean-Language-Reference--The-Type-System--Universes--Polymorphism"></a>
### 4.3.2. Polymorphism

Lean supports 
<a id="--tech-term-universe-polymorphism"></a>
*universe polymorphism*, 
<a id="--index--next-next-next-next-next-next-next-next-next-next-next-next"></a>

<a id="--index--next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
 which means that constants defined in the Lean environment can take 
<a id="--tech-term-universe-parameters"></a>
universe parameters. These parameters can then be instantiated with universe levels when the constant is used. Universe parameters are written in curly braces following a dot after a constant name.

<a id="Universe-polymorphic-identity-function"></a>
Universe-polymorphic identity function 

When fully explicit, the identity function takes a universe parameter `u`. Its signature is:

```proofscript
id.{u} {α : Sort u} (x : α) : α
```

Universe variables may additionally occur in [universe level expressions](index.md#level-expressions), which provide specific universe levels in definitions. When the polymorphic definition is instantiated with concrete levels, these universe level expressions are also evaluated to yield concrete levels.

<a id="Universe-level-expressions"></a>
Universe level expressions 

In this example, `Codec` is in a universe that is one greater than the universe of the type it contains:
<a id="Codec___type-_LPAR_in-Universe-level-expressions_RPAR_"></a>
<a id="Codec___encode-_LPAR_in-Universe-level-expressions_RPAR_"></a>
<a id="Codec___decode-_LPAR_in-Universe-level-expressions_RPAR_"></a>


```proofscript
structure Codec.{u} : Type (u + 1) where
  type : Type u
  encode : Array UInt32 → type → Array UInt32
  decode : Array UInt32 → Nat → Option (type × Nat)
```

Lean automatically infers most level parameters. In the following example, it is not necessary to annotate the type as `Codec.{0}`, because `Char`'s type is `Type 0`, so `u` must be `0`:
<a id="Codec___char-_LPAR_in-Universe-level-expressions_RPAR_"></a>


```proofscript
def Codec.char : Codec where
  type := Char
  encode buf ch := buf.push ch.val
  decode buf i := do
    let v ← buf[i]?
    if h : v.isValidChar then
      let ch : Char := ⟨v, h⟩
      return (ch, i + 1)
    else
      failure
```

Universe-polymorphic definitions in fact create a *schematic definition* that can be instantiated at a variety of levels, and different instantiations of universes create incompatible values.

<a id="Universe-polymorphism-and-definitional-equality"></a>
Universe polymorphism and definitional equality 

This can be seen in the following example, in which `T` is a gratuitously-universe-polymorphic function that always returns `true`. Because it is marked `opaque`, Lean can't check equality by unfolding the definitions. Both instantiations of `T` have the parameters and the same type, but their differing universe instantiations make them incompatible.
<a id="T-_LPAR_in-Universe-polymorphism-and-definitional-equality_RPAR_"></a>
<a id="test-_LPAR_in-Universe-polymorphism-and-definitional-equality_RPAR_"></a>


```proofscript
opaque T.{u} (_ : Nat) : Bool :=
  (fun (α : Sort u) => true) PUnit.{u}

set_option pp.universes true

def test.{u, v} : T.{u} 0 = T.{v} 0 := rfl
```

```lean
Type mismatch
  rfl.{?u.5}
has type
  Eq.{?u.5} ?m.7 ?m.7
but is expected to have type
  Eq.{1} (T.{u} 0) (T.{v} 0)
```

Auto-bound implicit arguments are as universe-polymorphic as possible. Defining the identity function as follows:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="id___"></a>


```proofscript
function id' (x : α) := x
```

results in the signature:

```proofscript
id'.{u} {α : Sort u} (x : α) : α
```

<a id="Universe-monomorphism-in-auto-bound-implicit-parameters"></a>
Universe monomorphism in auto-bound implicit parameters 

On the other hand, because `Nat` is in universe `Type 0`, this function automatically ends up with a concrete universe level for `α`, because `m` is applied to both `Nat` and `α`, so both must have the same type and thus be in the same universe:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="count-_LPAR_in-Universe-monomorphism-in-auto-bound-implicit-parameters_RPAR_"></a>


```proofscript
partial function count [Monad m] (p : α → Bool) (act : m α) : m Nat := do
  if p (← act) then
    return 1 + (← count p act)
  else
    return 0
```

<a id="level-expressions"></a>
#### 4.3.2.1. Level Expressions

Levels that occur in a definition are not restricted to just variables and addition of constants. More complex relationships between universes can be defined using level expressions.

```text
Level ::= 0 | 1 | 2 | ...  -- Concrete levels
        | u, v             -- Variables
        | Level + n        -- Addition of constants
        | max Level Level  -- Least upper bound
        | imax Level Level -- Impredicative LUB
```

Given an assignment of level variables to concrete numbers, evaluating these expressions follows the usual rules of arithmetic. The `imax` operation is defined as follows:

\mathtt{imax}\ u\ v = \begin{cases}0 & \mathrm{when\ }v = 0\\\mathtt{max}\ u\ v&\mathrm{otherwise}\end{cases}

`imax` is used to implement [impredicative](index.md#--tech-term-impredicative) quantification for `Prop`. In particular, if `A : Sort u` and `B : Sort v`, then `(x : A) → B : Sort (imax u v)`. If `B : Prop`, then the function type is itself a `Prop`; otherwise, the function type's level is the maximum of `u` and `v`.

<a id="The-Lean-Language-Reference--The-Type-System--Universes--Polymorphism--Universe-Variable-Bindings"></a>
#### 4.3.2.2. Universe Variable Bindings

Universe-polymorphic definitions bind universe variables. These bindings may be either explicit or implicit. Explicit universe variable binding and instantiation occurs as a suffix to the definition's name. Universe parameters are defined or provided by suffixing the name of a constant with a period (`.`) followed by a comma-separated sequence of universe variables between curly braces.

<a id="Universe-polymorphic--map"></a>
Universe-polymorphic `map` 

The following declaration of `map` declares two universe parameters (`u` and `v`) and instantiates the polymorphic `List` with each in turn:
<a id="map-_LPAR_in-Universe-polymorphic--map_RPAR_"></a>


```proofscript
def map.{u, v} {α : Type u} {β : Type v}
    (f : α → β) :
    List.{u} α → List.{v} β
  | [] => []
  | x :: xs => f x :: map f xs
```

Just as Lean automatically instantiates implicit parameters, it also automatically instantiates universe parameters. When [automatic implicit parameter insertion](../../Definitions/Headers-and-Signatures/index.md#automatic-implicit-parameters) is enabled (i.e. the `autoImplicit` option is set to `true`, which is the default), it is not necessary to explicitly bind universe variables; they are inserted automatically. When it is set to `false`, then they must be added explicitly or declared using the `universe` command.

<a id="Automatic-Implicit-Parameters-and-Universe-Polymorphism"></a>
Automatic Implicit Parameters and Universe Polymorphism 

When `autoImplicit` is `true` (which is the default setting), this definition is accepted even though it does not bind its universe parameters:

```proofscript
set_option autoImplicit true
def map {α : Type u} {β : Type v} (f : α → β) : List α → List β
  | [] => []
  | x :: xs => f x :: map f xs
```

When `autoImplicit` is `false`, the definition is rejected because `u` and `v` are not in scope:

```proofscript
set_option autoImplicit false
def map {α : Type u} {β : Type v} (f : α → β) : List α → List β
  | [] => []
  | x :: xs => f x :: map f xs
```

```lean
unknown universe level `u`
```

```lean
unknown universe level `v`
```

In addition to using `autoImplicit`, particular identifiers can be declared as universe variables in a particular [section scope](../../Namespaces-and-Sections/index.md#--tech-term-section-scope) using the `universe` command.

<a id="Lean___Parser___Command___universe"></a>

**syntax**

**Universe Parameter Declarations**

<a id="Lean___Parser___Command___universe-next"></a>

```ebnf
command ::= ...
    | universe ident ident*
```

Declares one or more universe variables for the extent of the current scope.

Just as the `variable` command causes a particular identifier to be treated as a parameter with a particular type, the `universe` command causes the subsequent identifiers to be implicitly quantified as universe parameters in declarations that mention them, even if the option `autoImplicit` is `false`.

<a id="The--universe--command-when--autoImplicit--is--false"></a>
The `universe` command when `autoImplicit` is `false` 
<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="id___-_LPAR_in-The--universe--command-when--autoImplicit--is--false_RPAR_"></a>


```proofscript
set_option autoImplicit false
universe u
function id₃ (α : Type u) (a : α) := a
```

Because the automatic implicit parameter feature only inserts parameters that are used in the declaration's [header](../../Definitions/Headers-and-Signatures/index.md#--tech-term-header), universe variables that occur only on the right-hand side of a definition are not inserted as arguments unless they have been declared with `universe` even when `autoImplicit` is `true`.

<a id="Automatic-universe-parameters-and-the--universe--command"></a>
Automatic universe parameters and the `universe` command 

This definition with an explicit universe parameter is accepted:

```proofscript
def L.{u} := List (Type u)
```

Even with automatic implicit parameters, this definition is rejected, because `u` is not mentioned in the header, which precedes the `:=`:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
set_option autoImplicit true
const L := List (Type u)
```

```lean
unknown universe level `u`
```

With a universe declaration, `u` is accepted as a parameter even on the right-hand side:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
universe u
const L := List (Type u)
```

The resulting definition of `L` is universe-polymorphic, with `u` inserted as a universe parameter.

Declarations in the scope of a `universe` command are not made polymorphic if the universe variables do not occur in them or in other automatically-inserted arguments.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
universe u
const L := List (Type 0)
#check L
```

<a id="The-Lean-Language-Reference--The-Type-System--Universes--Polymorphism--Universe-Lifting"></a>
#### 4.3.2.3. Universe Lifting

When a type's universe is smaller than the one expected in some context, 
<a id="--tech-term-universe-lifting"></a>
*universe lifting* operators can bridge the gap. These are wrappers around terms of a given type that are in larger universes than the wrapped type. There are two lifting operators:

- `PLift` can lift any type, including [propositions](../Propositions/index.md#--tech-term-Propositions), by one level. It can be used to include proofs in data structures such as lists.
- `ULift` can lift any non-proposition type by any number of levels.

<a id="PLift___up"></a>

**structure**

```text
PLift.{u} (α : Sort u) : Type u
```

Lifts a proposition or type to a higher universe level.

`PLift α` wraps a proof or value of type `α`. The resulting type is in the next largest universe after that of `α`. In particular, propositions become data.

The related type `ULift` can be used to lift a non-proposition type by any number of levels.

Examples:

- `(False : Prop)`
- `(PLift False : Type)`
- `([.up (by trivial), .up (by simp), .up (by decide)] : List (PLift True))`
- `(Nat : Type 0)`
- `(PLift Nat : Type 1)`

**Constructor**

```text
PLift.up.{u}
```

Wraps a proof or value to increase its type's universe level by 1.

**Fields**

```text
down : α
```

Extracts a wrapped proof or value from a universe-lifted proposition or type.

<a id="ULift___up"></a>

**structure**

```text
ULift.{r, s} (α : Type s) : Type (max s r)
```

Lifts a type to a higher universe level.

`ULift α` wraps a value of type `α`. Instead of occupying the same universe as `α`, which would be the minimal level, it takes a further level parameter and occupies their maximum. The resulting type may occupy any universe that's at least as large as that of `α`.

The resulting universe of the lifting operator is the first parameter, and may be written explicitly while allowing `α`'s level to be inferred.

The related type `PLift` can be used to lift a proposition or type by one level.

Examples:

- `(Nat : Type 0)`
- `(ULift Nat : Type 0)`
- `(ULift Nat : Type 1)`
- `(ULift Nat : Type 5)`
- `(ULift.{7} (PUnit : Type 3) : Type 7)`

**Constructor**

```text
ULift.up.{r, s}
```

Wraps a value to increase its type's universe level.

**Fields**

```text
down : α
```

Extracts a wrapped value from a universe-lifted type.

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


````text
Declares one or more universe variables.

`universe u v`

`Prop`, `Type`, `Type u` and `Sort u` are types that classify other types, also known as
*universes*. In `Type u` and `Sort u`, the variable `u` stands for the universe's *level*, and a
universe at level `u` can only classify universes that are at levels lower than `u`. For more
details on type universes, please refer to [the relevant chapter of Theorem Proving in Lean][tpil
universes].

Just as type arguments allow polymorphic definitions to be used at many different types, universe
parameters, represented by universe variables, allow a definition to be used at any required level.
While Lean mostly handles universe levels automatically, declaring them explicitly can provide more
control when writing signatures. The `universe` keyword allows the declared universe variables to be
used in a collection of definitions, and Lean will ensure that these definitions use them
consistently.

[tpil universes]: https://lean-lang.org/theorem_proving_in_lean4/dependent_type_theory.html#types-as-objects
(Type universes on Theorem Proving in Lean)

```lean
/- Explicit type-universe parameter. -/
def id₁.{u} (α : Type u) (a : α) := a

/- Implicit type-universe parameter, equivalent to `id₁`.
  Requires option `autoImplicit true`, which is the default. -/
def id₂ (α : Type u) (a : α) := a

/- Explicit standalone universe variable declaration, equivalent to `id₁` and `id₂`. -/
universe u
def id₃ (α : Type u) (a : α) := a
```

On a more technical note, using a universe variable only in the right-hand side of a definition
causes an error if the universe has not been declared previously.

```lean
def L₁.{u} := List (Type u)

-- def L₂ := List (Type u) -- error: `unknown universe level 'u'`

universe u
def L₃ := List (Type u)
```

## Examples

```lean
universe u v w

structure Pair (α : Type u) (β : Type v) : Type (max u v) where
  a : α
  b : β

#check Pair.{v, w}
-- Pair : Type v → Type w → Type (max v w)
```
````


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Type mismatch
  Type 2
has type
  Type 3
of sort `Type 4` but is expected to have type
  Type 4
of sort `Type 5`
```


### Display 2


```text
Type mismatch
  Unit
has type
  Type
of sort `Type 1` but is expected to have type
  Type 1
of sort `Type 2`
```


### Display 3


```text
Type mismatch
  α → β
has type
  Type 2
of sort `Type 3` but is expected to have type
  Type 1
of sort `Type 2`
```


### Display 4


```text
Type mismatch
  α → β
has type
  Type 2
of sort `Type 3` but is expected to have type
  Type 3
of sort `Type 4`
```


### Display 5


```text
Variable name `α` is not explicitly referenced.

Hint: The binding can be removed (if unused) or named `_` (if used implicitly). Alternatively, prefix the name with `_` to silence this warning:
  [apply] _α

Note: This linter can be disabled with `set_option linter.unusedVariables false`
```


### Display 6


```text
Not a definitional equality: the left-hand side
  T.{u} 0
is not definitionally equal to the right-hand side
  T.{v} 0
```


### Display 7


```text
Type mismatch
  rfl.{?u.5}
has type
  Eq.{?u.5} ?m.7 ?m.7
but is expected to have type
  Eq.{1} (T.{u} 0) (T.{v} 0)
```


### Display 8


```text
unknown universe level `u`
```


### Display 9


```text
unknown universe level `v`
```


### Display 10


```text
L : Type 1
```

