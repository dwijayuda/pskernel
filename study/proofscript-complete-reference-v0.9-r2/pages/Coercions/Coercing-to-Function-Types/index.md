<a id="fun-coercion"></a>

# ProofScript — 11.4. Coercing to Function Types

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Coercions are native elaboration mechanisms, including coercion between types, to sorts and to function types. They are not JavaScript conversions based on truthiness or object prototypes. An implementation must preserve the selected coercion or reject the unsupported case. A foreign value needs an appropriate decoder or model before it can satisfy an owned logical invariant.

**Compiler and coverage boundary.** Record inserted coercions and their dependencies. Do not replace dependent coercions with unchecked target casts.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Coercions/Coercing-to-Function-Types/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Coercions/Coercing-to-Function-Types/index.html). Source Git blob: `d48c1062f102442688e9a4c16558c5cc73ed0f3e`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 11.4. Coercing to Function Types

Another situation where an expected type is not generally available is the function position in a function application term. Dependent function types are common; together with [implicit](../../Terms/Functions/index.md#--tech-term-implicit) parameters, they cause information to flow from the elaboration of one argument to the elaboration of the others. Attempting to deduce the type required for the function from the expected type of the entire application term and individually-inferred types of arguments will often fail. In these situations, Lean uses the `CoeFun` type class to coerce a non-function in an application position into a function. Like `CoeSort`, `CoeFun` instances do not chain with other coercions while inserting a function coercion, but they can be used as `CoeOut` instances during ordinary coercion insertion.

The second parameter to `CoeFun` is an output parameter that determines the resulting function type. This output parameter is function that computes the function type from the term that's being coerced, rather than the function type itself. Unlike `CoeDep`, the term itself is not taken into account during instance synthesis; it can, however, be used to create dependently typed coercions where the function type is determined by the term.

<a id="CoeFun___mk"></a>

**type class**

```text
CoeFun.{u, v} (α : Sort u) (γ : outParam (α → Sort v)) :
  Sort (max (max 1 u) v)
```

`CoeFun α (γ : α → Sort v)` is a coercion to a function. `γ a` should be a (coercion-to-)function type, and this is triggered whenever an element `f : α` appears in an application like `f x`, which would not make sense since `f` does not have a function type. `CoeFun` instances apply to `CoeOut` as well.

**Instance Constructor**

```text
CoeFun.mk.{u, v}
```

**Methods**

```text
coe : (f : α) → γ f
```

Coerces a value `f : α` to type `γ f`, which should be either be a function type or another `CoeFun` type, in order to resolve a mistyped application `f x`.

<a id="term-next-next-next-next-next-next-next"></a>

**syntax**

**Explicit Coercion to Functions**

<a id="coeFunNotation"></a>

```ebnf
term ::= ...
    | ⇑ term
```

<a id="Coercing-Decorated-Functions-to-Function-Types"></a>
Coercing Decorated Functions to Function Types 

The structure `NamedFun α β` pairs a function from `α` to `β` with a name.
<a id="NamedFun-_LPAR_in-Coercing-Decorated-Functions-to-Function-Types_RPAR_"></a>
<a id="NamedFun___function-_LPAR_in-Coercing-Decorated-Functions-to-Function-Types_RPAR_"></a>
<a id="NamedFun___name-_LPAR_in-Coercing-Decorated-Functions-to-Function-Types_RPAR_"></a>


```proofscript
structure NamedFun (α : Type u) (β : Type v) where
  function : α → β
  name : String
```

Existing functions can be named:
<a id="succ-_LPAR_in-Coercing-Decorated-Functions-to-Function-Types_RPAR_"></a>
<a id="asString-_LPAR_in-Coercing-Decorated-Functions-to-Function-Types_RPAR_"></a>
<a id="append-_LPAR_in-Coercing-Decorated-Functions-to-Function-Types_RPAR_"></a>


```proofscript
def succ : NamedFun Nat Nat where
  function n := n + 1
  name := "succ"

def asString [ToString α] : NamedFun α String where
  function := ToString.toString
  name := "asString"

def append : NamedFun (List α) (List α → List α) where
  function := (· ++ ·)
  name := "append"
```

Named functions can also be composed:
<a id="NamedFun___comp-_LPAR_in-Coercing-Decorated-Functions-to-Function-Types_RPAR_"></a>


```proofscript
def NamedFun.comp
    (f : NamedFun β γ)
    (g : NamedFun α β) :
    NamedFun α γ where
  function := f.function ∘ g.function
  name := f.name ++ " ∘ " ++ g.name
```

Unlike ordinary functions, named functions have a reasonable representation as a string:

```proofscript
instance : ToString (NamedFun α α'') where
  toString f := s!"#<{f.name}>"
```

```proofscript
#eval asString.comp succ
```

```lean
#<asString ∘ succ>
```

A `CoeFun` instance allows them to be applied just like ordinary functions:

```proofscript
instance : CoeFun (NamedFun α α'') (fun _ => α → α'') where
  coe | ⟨f, _⟩ => f
```

```proofscript
#eval append [1, 2, 3] [4, 5, 6]
```

```lean
[1, 2, 3, 4, 5, 6]
```

<a id="Dependent-Coercion-to-Functions"></a>
Dependent Coercion to Functions 

Sometimes, the type of the resulting function depends on the specific value that is being coerced. A `Writer` represents a means of appending a representation of some value to a string:
<a id="Writer-_LPAR_in-Dependent-Coercion-to-Functions_RPAR_"></a>
<a id="Writer___Writes-_LPAR_in-Dependent-Coercion-to-Functions_RPAR_"></a>
<a id="Writer___write-_LPAR_in-Dependent-Coercion-to-Functions_RPAR_"></a>
<a id="natWriter-_LPAR_in-Dependent-Coercion-to-Functions_RPAR_"></a>
<a id="stringWriter-_LPAR_in-Dependent-Coercion-to-Functions_RPAR_"></a>


```proofscript
structure Writer where
  Writes : Type u
  write : Writes → String → String

def natWriter : Writer where
  Writes := Nat
  write n out := out ++ toString n

def stringWriter : Writer where
  Writes := String
  write s out := out ++ s
```

Because the type of the parameter expected by the inner function depend on the `Writer.Writes` field, the `CoeFun` instance extracts the field:

```proofscript
instance :
    CoeFun Writer (·.Writes → String → String) where
  coe w := w.write
```

With this instance, concrete `Writer`s can be used as functions:

```proofscript
#eval "" |> natWriter (5 : Nat) |> stringWriter " hello"
```

```lean
"5 hello"
```

<a id="Coercing-to-Function-Types"></a>
Coercing to Function Types 

A well-typed interpreter is an interpreter for a programming language that uses indexed families to rule out run-time type errors. Functions written in the interpreted language can be interpreted as Lean functions, but their underlying source code can also be inspected.

The first step in the well-typed interpreter is to select the subset of Lean types that can be used. These types are represented by an [inductive type](../../The-Type-System/Inductive-Types/index.md#--tech-term-Inductive-types) of codes `Ty` and a function that maps these codes to actual types.
<a id="Ty-_LPAR_in-Coercing-to-Function-Types_RPAR_"></a>
<a id="Ty___nat-_LPAR_in-Coercing-to-Function-Types_RPAR_"></a>
<a id="Ty___arr-_LPAR_in-Coercing-to-Function-Types_RPAR_"></a>
<a id="Ty___interp-_LPAR_in-Coercing-to-Function-Types_RPAR_"></a>


```proofscript
inductive Ty where
  | nat
  | arr (dom cod : Ty)

abbrev Ty.interp : Ty → Type
  | .nat => Nat
  | .arr t t' => t.interp → t'.interp
```

The language itself is represented by an [indexed family](../../The-Type-System/Inductive-Types/index.md#--tech-term-indexed-families) over variable contexts and result types. Variables are represented by [de Bruijn indices](https://en.wikipedia.org/wiki/De_Bruijn_index).
<a id="Tm-_LPAR_in-Coercing-to-Function-Types_RPAR_"></a>
<a id="Tm___zero-_LPAR_in-Coercing-to-Function-Types_RPAR_"></a>
<a id="Tm___succ-_LPAR_in-Coercing-to-Function-Types_RPAR_"></a>
<a id="Tm___rep-_LPAR_in-Coercing-to-Function-Types_RPAR_"></a>
<a id="Tm___lam-_LPAR_in-Coercing-to-Function-Types_RPAR_"></a>
<a id="Tm___app-_LPAR_in-Coercing-to-Function-Types_RPAR_"></a>
<a id="Tm___var-_LPAR_in-Coercing-to-Function-Types_RPAR_"></a>


```proofscript
inductive Tm : List Ty → Ty → Type where
  | zero : Tm Γ .nat
  | succ (n : Tm Γ .nat) : Tm Γ .nat
  | rep (n : Tm Γ .nat)
    (start : Tm Γ t)
    (f : Tm Γ (.arr .nat (.arr t t))) :
    Tm Γ t
  | lam (body : Tm (t :: Γ) t') : Tm Γ (.arr t t')
  | app (f : Tm Γ (.arr t t')) (arg : Tm Γ t) : Tm Γ t'
  | var (i : Fin Γ.length) : Tm Γ Γ[i]
deriving Repr
```

Because the `OfNat` instance for `Fin` requires that the upper bound be non-zero, `Tm.var` can be inconvenient to use with numeric literals. The helper `Tm.v` can be used to avoid the need for type annotations in these cases.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="Tm___v-_LPAR_in-Coercing-to-Function-Types_RPAR_"></a>


```proofscript
function Tm.v
    (i : Fin (Γ.length + 1)) :
    Tm (t :: Γ) (t :: Γ)[i] :=
  .var (Γ := t :: Γ) i
```

A function that adds two natural numbers uses the `rep` operation to apply the successor `Tm.succ` repeatedly.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="plus-_LPAR_in-Coercing-to-Function-Types_RPAR_"></a>


```proofscript
const plus : Tm [] (.arr .nat (.arr .nat .nat)) :=
  .lam <| .lam <| .rep (.v 1) (.v 0) (.lam (.lam (.succ (.v 0))))
```

Each typing context can be interpreted as a type of run-time environments that provide a value for each variable in the context:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="Env-_LPAR_in-Coercing-to-Function-Types_RPAR_"></a>
<a id="Env___empty-_LPAR_in-Coercing-to-Function-Types_RPAR_"></a>
<a id="Env___extend-_LPAR_in-Coercing-to-Function-Types_RPAR_"></a>
<a id="Env___get-_LPAR_in-Coercing-to-Function-Types_RPAR_"></a>


```proofscript
def Env : List Ty → Type
  | [] => Unit
  | t :: Γ => t.interp × Env Γ

const Env.empty : Env [] := ()

function Env.extend (ρ : Env Γ) (v : t.interp) : Env (t :: Γ) :=
  (v, ρ)

function Env.get (i : Fin Γ.length) (ρ : Env Γ) : Γ[i].interp :=
  match Γ, ρ, i with
  | _::_, (v, _), ⟨0, _⟩ => v
  | _::_, (_, ρ'), ⟨i+1, _⟩ => ρ'.get ⟨i, by simp_all⟩
```

Finally, the interpreter is a recursive function over the term:
<a id="Tm___interp-_LPAR_in-Coercing-to-Function-Types_RPAR_"></a>


```proofscript
def Tm.interp (ρ : Env α'') : Tm α'' t → t.interp
  | .zero => 0
  | .succ n => n.interp ρ + 1
  | .rep n start f =>
    let f' := f.interp ρ
    (n.interp ρ).fold (fun n _ x => f' n x) (start.interp ρ)
  | .lam body => fun x => body.interp (ρ.extend x)
  | .app f arg => f.interp ρ (arg.interp ρ)
  | .var i => ρ.get i
```

Coercing a `Tm` to a function consists of calling the interpreter.

```proofscript
instance : CoeFun (Tm [] α'') (fun _ => α''.interp) where
  coe f := f.interp .empty
```

Because functions are represented by a first-order inductive type, their code can be inspected:

```proofscript
#eval plus
```

```lean
Tm.lam (Tm.lam (Tm.rep (Tm.var 1) (Tm.var 0) (Tm.lam (Tm.lam (Tm.succ (Tm.var 0))))))
```

At the same time, due to the coercion, they can be applied just like native Lean functions:

```proofscript
#eval plus 3 5
```

```lean
8
```

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
`⇑ t` coerces `t` to a function.
```


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
#<asString ∘ succ>
```


### Display 2


```text
[1, 2, 3, 4, 5, 6]
```


### Display 3


```text
"5 hello"
```


### Display 4


```text
Tm.lam (Tm.lam (Tm.rep (Tm.var 1) (Tm.var 0) (Tm.lam (Tm.lam (Tm.succ (Tm.var 0))))))
```


### Display 5


```text
8
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Γ:List Tyi✝:Fin Γ.lengthρ:Env Γhead✝:Tytail✝:List Tyfst✝:head✝.interpρ':Env tail✝i:NatisLt✝:i + 1 < (head✝ :: tail✝).length⊢ i < tail✝.length
```


### Display 2


```text
All goals completed! 🐙
```

