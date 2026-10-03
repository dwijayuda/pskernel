<a id="coercion-insertion"></a>

# ProofScript — 11.1. Coercion Insertion

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Coercions are native elaboration mechanisms, including coercion between types, to sorts and to function types. They are not JavaScript conversions based on truthiness or object prototypes. An implementation must preserve the selected coercion or reject the unsupported case. A foreign value needs an appropriate decoder or model before it can satisfy an owned logical invariant.

**Compiler and coverage boundary.** Record inserted coercions and their dependencies. Do not replace dependent coercions with unchecked target casts.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Coercions/Coercion-Insertion/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Coercions/Coercion-Insertion/index.html). Source Git blob: `b6ae045a05627ba64dc8793aac13e6d9d0e1d151`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 11.1. Coercion Insertion

The process of searching for a coercion from one type to another is called 
<a id="--tech-term-coercion-insertion"></a>
*coercion insertion*. Coercion insertion is attempted in the following situations where an error would otherwise occur:

- The expected type for a term is not equal to the type found for the term.
- A type or proposition is expected, but the term's type is not a [universe](../../The-Type-System/Universes/index.md#--tech-term-universes).
- A term is applied as though it were a function, but its type is not a function type.

Coercions are also inserted when they are explicitly requested. Each situation in which coercions may be inserted has a corresponding prefix operator that triggers the appropriate insertion.

Because coercions are inserted automatically, nested [type ascriptions](../../Terms/Type-Ascription/index.md#--tech-term-Type-ascriptions) provide a way to precisely control the types involved in a coercion. If `α` and `β` are not the same type, `((e : α) : β)` arranges for `e` to have type `α` and then inserts a coercion from `α` to `β`.

When a coercion is discovered, the instances used to find it are unfolded and removed from the resulting term. To the extent possible, calls to `Coe.coe` and related functions do not occur in the final term. This process of unfolding makes terms more readable. Even more importantly, it means that coercions can control the evaluation of the coerced terms by wrapping them in functions.

<a id="Controlling-Evaluation-with-Coercions"></a>
Controlling Evaluation with Coercions 

The structure `Later` represents a term that can be evaluated in the future, by calling the contained function.
<a id="Later-_LPAR_in-Controlling-Evaluation-with-Coercions_RPAR_"></a>
<a id="Later___get-_LPAR_in-Controlling-Evaluation-with-Coercions_RPAR_"></a>


```proofscript
structure Later (α : Type u) where
  get : Unit → α
```

A coercion from any value to a later value is performed by creating a function that wraps it.

```proofscript
instance : CoeTail α (Later α) where
  coe x := { get := fun () => x }
```

However, if coercion insertion resulted in an application of `CoeTail.coe`, then this coercion would not have the desired effect at runtime, because the coerced value would be evaluated and then saved in the function's closure. Because coercion implementations are unfolded, this instance is nonetheless useful.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="tomorrow-_LPAR_in-Controlling-Evaluation-with-Coercions_RPAR_"></a>


```proofscript
const tomorrow : Later String :=
  (Nat.fold 10000
    (init := "")
    (fun _ _ s => s ++ "tomorrow") : String)
```

Printing the resulting definition shows that the computation is inside the function's body:

```proofscript
#print tomorrow
```

```lean
def tomorrow : Later String :=
{ get := fun x => Nat.fold 10000 (fun x x_1 s => s ++ "tomorrow") "" }
```

<a id="Duplicate-Evaluation-in-Coercions"></a>
Duplicate Evaluation in Coercions 

Because the contents of `Coe` instances are unfolded during coercion insertion, coercions that use their argument more than once should be careful to ensure that evaluation occurs just once. This can be done by using a helper function that is not part of the instance, or by using `let` to evaluate the coerced term and then reuse its resulting value.

The structure `Twice` requires that both fields have the same value:
<a id="Twice-_LPAR_in-Duplicate-Evaluation-in-Coercions_RPAR_"></a>
<a id="Twice___first-_LPAR_in-Duplicate-Evaluation-in-Coercions_RPAR_"></a>
<a id="Twice___second-_LPAR_in-Duplicate-Evaluation-in-Coercions_RPAR_"></a>
<a id="Twice___first_eq_second-_LPAR_in-Duplicate-Evaluation-in-Coercions_RPAR_"></a>


```proofscript
structure Twice (α : Type u) where
  first : α
  second : α
  first_eq_second : first = second
```

One way to define a coercion from `α` to `Twice α` is with a helper function `twice`. The `coe` attribute marks it as a coercion so it can be shown correctly in proof goals and error messages.
<a id="twice-_LPAR_in-Duplicate-Evaluation-in-Coercions_RPAR_"></a>


```proofscript
@[coe]
def twice (x : α) : Twice α where
  first := x
  second := x
  first_eq_second := rfl

instance : Coe α (Twice α) := ⟨twice⟩
```

When the `Coe` instance is unfolded, the call to `twice` remains, which causes its argument to be evaluated before the body of the function is executed. As a result, the `dbg_trace` is included in the resulting term just once:

```proofscript
#eval ((dbg_trace "hello"; 5 : Nat) : Twice Nat)
```

This is used to demonstrate the effect:

```lean
hello
```

Inlining the helper into the `Coe` instance results in a term that duplicates the `dbg_trace`:

```proofscript
instance : Coe α (Twice α) where
  coe x := ⟨x, x, rfl⟩

#eval ((dbg_trace "hello"; 5 : Nat) : Twice Nat)
```

```lean
hello
hello
```

Introducing an intermediate name for the result of the evaluation prevents the duplication of `dbg_trace`:

```proofscript
instance : Coe α (Twice α) where
  coe x := let y := x; ⟨y, y, rfl⟩

#eval ((dbg_trace "hello"; 5 : Nat) : Twice Nat)
```

```lean
hello
```

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
def tomorrow : Later String :=
{ get := fun x => Nat.fold 10000 (fun x x_1 s => s ++ "tomorrow") "" }
```


### Display 2


```text
{ first := 5, second := 5, first_eq_second := _ }hello
```


### Display 3


```text
{ first := 5, second := 5, first_eq_second := _ }hello
hello
```

