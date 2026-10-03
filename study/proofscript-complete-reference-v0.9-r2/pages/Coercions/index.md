<a id="coercions"></a>

# ProofScript — 11. Coercions

[Reference home](../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Coercions are native elaboration mechanisms, including coercion between types, to sorts and to function types. They are not JavaScript conversions based on truthiness or object prototypes. An implementation must preserve the selected coercion or reject the unsupported case. A foreign value needs an appropriate decoder or model before it can satisfy an owned logical invariant.

**Compiler and coverage boundary.** Record inserted coercions and their dependencies. Do not replace dependent coercions with unchecked target casts.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Coercions/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Coercions/index.html). Source Git blob: `104c99440bfb0fd7ed40f255a1059d929d3aba3f`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 11. Coercions

When the Lean elaborator is expecting one type but produces a term with a different type, it attempts to automatically insert a 
<a id="--tech-term-coercion"></a>
*coercion*, which is a specially designated function from the term's type to the expected type. Coercions make it possible to use specific types to represent data while interacting with APIs that expect less-informative types. They also allow mathematical developments to follow the usual practice of “punning”, where the same symbol is used to stand for both an algebraic structure and its carrier set, with the precise meaning determined by context.

Lean's standard library and metaprogramming APIs define many coercions. Some examples include:

- A `Nat` may be used where an `Int` is expected.
- A `Fin` may be used where a `Nat` is expected.
- An `α` may be used where an `Option α` is expected. The coercion wraps the value in `some`.
- An `α` may be used where a `Thunk α` is expected. The coercion wraps the term in a function to delay its evaluation.
- When one syntax category `c1` embeds into another category `c2`, a coercion from `TSyntax c1` to `TSyntax c2` performs any necessary wrapping to construct a valid syntax tree.

Coercions are found using type class [synthesis](../Type-Classes/index.md#--tech-term-synthesizes). The set of coercions can be extended by adding further instances of the appropriate type classes.

<a id="Coercions"></a>
Coercions 

All of the following examples rely on coercions:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="th-_LPAR_in-Coercions_RPAR_"></a>


```proofscript
example (n : Nat) : Int := n
example (n : Fin k) : Nat := n
example (x : α) : Option α := x

function th (f : Int → String) (x : Nat) : Thunk String := f x

open Lean in
example (n : Ident) : Term := n
```

In the case of `th`, using `#print` demonstrates that evaluation of the function application is delayed until the thunk's value is requested:

```proofscript
#print th
```

```lean
def th : (Int → String) → Nat → Thunk String :=
fun f x => { fn := fun x_1 => f ↑x }
```

Coercions are not used to resolve [generalized field notation](../Terms/Function-Application/index.md#--tech-term-generalized-field-notation): only the inferred type of the term is considered. However, a [type ascription](../Terms/Type-Ascription/index.md#--tech-term-Type-ascriptions) can be used to trigger a coercion to the type that has the desired generalized field. Coercions are also not used to resolve `OfNat` instances: even though there is a default instance for `OfNat Nat`, a coercion from `Nat` to `α` does not allow natural number literals to be used for `α`.

<a id="Coercions-and-Generalized-Field-Notation"></a>
Coercions and Generalized Field Notation 

The name `Nat.bdiv` is not defined, but `Int.bdiv` exists. The coercion from `Nat` to `Int` is not considered when looking up the field `bdiv`:

```proofscript
example (n : Nat) := n.bdiv 2
```

```lean
Invalid field `bdiv`: The environment does not contain `Nat.bdiv`, so it is not possible to project the field `bdiv` from an expression
  n
of type `Nat`
```

This is because coercions are only inserted when there is an expected type that differs from an inferred type, and generalized fields are resolved based on the inferred type of the term before the dot. Coercions can be triggered by adding a type ascription, which additionally causes the inferred type of the entire ascription term to be `Int`, allowing the function `Int.bdiv` to be found.

```proofscript
example (n : Nat) := (n : Int).bdiv 2
```

<a id="Coercions-and--OfNat"></a>
Coercions and `OfNat` 

`Bin` is an inductive type that represents binary numbers.
<a id="Bin-_LPAR_in-Coercions-and--OfNat_RPAR_"></a>
<a id="Bin___done-_LPAR_in-Coercions-and--OfNat_RPAR_"></a>
<a id="Bin___zero-_LPAR_in-Coercions-and--OfNat_RPAR_"></a>
<a id="Bin___one-_LPAR_in-Coercions-and--OfNat_RPAR_"></a>
<a id="Bin___toString-_LPAR_in-Coercions-and--OfNat_RPAR_"></a>


```proofscript
inductive Bin where
  | done
  | zero : Bin → Bin
  | one : Bin → Bin

def Bin.toString : Bin → String
  | .done => ""
  | .one b => b.toString ++ "1"
  | .zero b => b.toString ++ "0"

instance : ToString Bin where
  toString
    | .done => "0"
    | b => Bin.toString b
```

Binary numbers can be converted to natural numbers by repeatedly applying `Bin.succ`:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="Bin___succ-_LPAR_in-Coercions-and--OfNat_RPAR_"></a>
<a id="Bin___ofNat-_LPAR_in-Coercions-and--OfNat_RPAR_"></a>


```proofscript
function Bin.succ (b : Bin) : Bin :=
  match b with
  | .done => Bin.done.one
  | .zero b => .one b
  | .one b => .zero b.succ

function Bin.ofNat (n : Nat) : Bin :=
  match n with
  | 0 => .done
  | n + 1 => (Bin.ofNat n).succ
```

Even if `Bin.ofNat` is registered as a coercion, natural number literals cannot be used for `Bin`:

```proofscript
attribute [coe] Bin.ofNat

instance : Coe Nat Bin where
  coe := Bin.ofNat
```

```proofscript
#eval (9 : Bin)
```

```lean
failed to synthesize instance of type class
  OfNat Bin 9
numerals are polymorphic in Lean, but the numeral `9` cannot be used in a context where the expected type is
  Bin
due to the absence of the instance above

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```

This is because coercions are inserted in response to mismatched types, but a failure to synthesize an `OfNat` instance is not a type mismatch.

The coercion can be used in the definition of the `OfNat Bin` instance:

```proofscript
instance : OfNat Bin n where
  ofNat := n

#eval (10 : Bin)
```

```lean
1010
```

Most new coercions can be defined by declaring an instance of the `Coe` [type class](../Type-Classes/index.md#--tech-term-type-class) and applying the `coe` attribute to the function that performs the coercion. To enable more control over coercions or to enable them in more contexts, Lean provides further classes that can be implemented, described in the rest of this chapter.

<a id="Defining-Coercions___-Decimal-Numbers"></a>
Defining Coercions: Decimal Numbers 

Decimal numbers can be defined as arrays of digits.
<a id="Decimal-_LPAR_in-Defining-Coercions___-Decimal-Numbers_RPAR_"></a>
<a id="Decimal___digits-_LPAR_in-Defining-Coercions___-Decimal-Numbers_RPAR_"></a>


```proofscript
structure Decimal where
  digits : Array (Fin 10)
```

Adding a coercion allows them to be used in contexts that expect `Nat`, but also contexts that expect any type that `Nat` can be coerced to.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="Decimal___toNat-_LPAR_in-Defining-Coercions___-Decimal-Numbers_RPAR_"></a>


```proofscript
@[coe]
function Decimal.toNat (d : Decimal) : Nat :=
  d.digits.foldl (init := 0) fun n d => n * 10 + d.val

instance : Coe Decimal Nat where
  coe := Decimal.toNat
```

This can be demonstrated by treating a `Decimal` as an `Int` as well as a `Nat`:
<a id="twoHundredThirteen-_LPAR_in-Defining-Coercions___-Decimal-Numbers_RPAR_"></a>
<a id="one-_LPAR_in-Defining-Coercions___-Decimal-Numbers_RPAR_"></a>


```proofscript
def twoHundredThirteen : Decimal where
  digits := #[2, 1, 3]

def one : Decimal where
  digits := #[1]

#eval (one : Int) - (twoHundredThirteen : Nat)
```

```lean
-212
```

<a id="Coe___mk"></a>

**type class**

```text
Coe.{u, v} (α : semiOutParam (Sort u)) (β : Sort v) :
  Sort (max (max 1 u) v)
```

`Coe α β` is the typeclass for coercions from `α` to `β`. It can be transitively chained with other `Coe` instances, and coercion is automatically used when `x` has type `α` but it is used in a context where `β` is expected. You can use the `↑x` operator to explicitly trigger coercion.

**Instance Constructor**

```text
Coe.mk.{u, v}
```

**Methods**

```text
coe : α → β
```

Coerces a value of type `α` to type `β`. Accessible by the notation `↑x`, or by double type ascription `((x : α) : β)`.

1. [11.1. Coercion Insertion](Coercion-Insertion/index.md#coercion-insertion)
2. [11.2. Coercing Between Types](Coercing-Between-Types/index.md#ordinary-coercion)
3. [11.3. Coercing to Sorts](Coercing-to-Sorts/index.md#sort-coercion)
4. [11.4. Coercing to Function Types](Coercing-to-Function-Types/index.md#fun-coercion)
5. [11.5. Implementation Details](Implementation-Details/index.md#coercion-impl-details)

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
def th : (Int → String) → Nat → Thunk String :=
fun f x => { fn := fun x_1 => f ↑x }
```


### Display 2


```text
Invalid field `bdiv`: The environment does not contain `Nat.bdiv`, so it is not possible to project the field `bdiv` from an expression
  n
of type `Nat`
```


### Display 3


```text
failed to synthesize instance of type class
  OfNat Bin 9
numerals are polymorphic in Lean, but the numeral `9` cannot be used in a context where the expected type is
  Bin
due to the absence of the instance above

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```


### Display 4


```text
1010
```


### Display 5


```text
-212
```

