<a id="function-terms"></a>

# ProofScript — 13.3. Functions

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Terms keep native binding, precedence and type-directed elaboration. D-CALL is adjacency-sensitive: f(x,y) supplies two curried arguments; f((x,y)) and native f (x,y) supply one tuple. An empty call passes Unit. Lambdas use fun, records use :=, and match patterns remain native even when constructor terms use decorated calls. Braces delimit specific categories; they do not disable the native layout checks inside them.

**Compiler and coverage boundary.** Preserve grouping that influences elaboration. Do not flatten nested calls, split patterns on arbitrary bars, or rewrite punctuation inside strings and quotations.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Terms/Functions/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Terms/Functions/index.html). Source Git blob: `5bc971afd60bba9da8746c2c94d7695c5caf0a47`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 13.3. Functions

Terms with function types can be created via abstractions, introduced with the `fun` keyword.In various communities, function abstractions are also known as *lambdas*, due to Alonzo Church's notation for them, or *anonymous functions* because they don't need to be defined with a name in the global environment. While abstractions in the core type theory only allow a single variable to be bound, function terms are quite flexible in the high-level Lean syntax.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Function Abstraction**

The most basic function abstraction introduces a variable to stand for the function's parameter:

<a id="Lean___Parser___Term___fun"></a>

```ebnf
term ::= ...
    | fun ident => term
```

At elaboration time, Lean must be able to determine the function's domain. A type ascription is one way to provide this information:

<a id="Lean___Parser___Term___fun-next"></a>

```ebnf
term ::= ...
    | fun ident : term => term
```

Function definitions defined with keywords such as `def` desugar to `fun`. Inductive type declarations, on the other hand, introduce new values with function types (constructors and type constructors) that cannot themselves be implemented using just `fun`.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Curried Functions**

Multiple parameter names are accepted after `fun`:

<a id="Lean___Parser___Term___fun-next-next"></a>

```ebnf
term ::= ...
    | fun ident ident* => term
```

<a id="Lean___Parser___Term___fun-next-next-next"></a>

```ebnf
term ::= ...
    | fun ident ident* : term => term
```

Different type annotations for multiple parameters require parentheses:

<a id="Manual___FreeSyntax___embed"></a>

```ebnf
term ::= ...
    | fun (ident* : term) =>term
```

These are equivalent to writing nested `fun` terms.

The `=>` may be replaced by `↦` in all of the syntax described in this section.

Function abstractions may also use pattern matching syntax as part of their parameter specification, avoiding the need to introduce a local variable that is immediately destructured. This syntax is described in the [section on pattern matching](../Pattern-Matching/index.md#pattern-fun).

<a id="implicit-functions"></a>
### 13.3.1. Implicit Parameters

Lean supports implicit parameters to functions. This means that Lean itself can supply arguments to functions, rather than requiring users to supply all needed arguments. Implicit parameters come in three varieties:

  Ordinary implicit parameters

Ordinary 
<a id="--tech-term-implicit"></a>
implicit parameters are function parameters that Lean should determine values for via unification. In other words, each call site should have exactly one potential argument value that would cause the function call as a whole to be well-typed. The Lean elaborator attempts to find values for all implicit arguments at each occurrence of a function. Ordinary implicit parameters are written in curly braces (`{` and `}`).

  Strict implicit parameters

<a id="--tech-term-Strict-implicit"></a>
*Strict implicit* parameters are identical to ordinary implicit parameters, except Lean will only attempt to find argument values when subsequent explicit arguments are provided at a call site. Strict implicit parameters are written in double curly braces (`⦃` and `⦄`, or `{{` and `}}`).

  Instance implicit parameters

Arguments for [*instance implicit*](../../Type-Classes/index.md#--tech-term-instance-implicit) parameters are found via [type class synthesis](../../Type-Classes/Instance-Synthesis/index.md#instance-synth). Instance implicit parameters are written in square brackets (`[` and `]`). Unlike the other kinds of implicit parameter, instance implicit parameters that are written without a `:` specify the parameter's type rather than providing a name. Furthermore, only a single name is allowed. Most instance implicit parameters omit the parameter name because instances synthesized as parameters to functions are already available in the functions' bodies, even without being named explicitly.

<a id="Ordinary-vs-Strict-Implicit-Parameters"></a>
Ordinary vs Strict Implicit Parameters 

The difference between the functions `f` and `g` is that `α` is strictly implicit in `f`:
<a id="f-_LPAR_in-Ordinary-vs-Strict-Implicit-Parameters_RPAR_"></a>
<a id="g-_LPAR_in-Ordinary-vs-Strict-Implicit-Parameters_RPAR_"></a>


```proofscript
def f ⦃α : Type⦄ : α → α := fun x => x
def g {α : Type} : α → α := fun x => x
```

These functions are elaborated identically when applied to concrete arguments:

```proofscript
example : f 2 = g 2 := rfl
```

However, when the explicit argument is not provided, uses of `f` do not require the implicit `α` to be solved:

```proofscript
example := f
```

However, uses of `g` do require it to be solved, and fail to elaborate if there is insufficient information available:

```proofscript
example := g
```

```lean
don't know how to synthesize implicit argument `α`
  @g ?m.3
context:
⊢ Type
```

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Functions with Varying Binders**

The most general syntax for `fun` accepts a sequence of binders:

<a id="Lean___Parser___Term___fun-next-next-next-next"></a>

```ebnf
term ::= ...
    | fun funBinder funBinder* => term
```

<a id="Lean___Parser___Term___funBinder"></a>

**syntax**

**Function Binders**

Function binders may be identifiers:

<a id="ident___antiquot"></a>

```ebnf
funBinder ::= ...
    | ident
```

parenthesized sequences of identifiers:

<a id="Lean___Parser___Term___paren"></a>

```ebnf
funBinder ::= ...
    | ([anonymous]ident ident*)
```

sequences of identifiers with a type ascription:

<a id="Lean___Parser___Term___typeAscription"></a>

```ebnf
funBinder ::= ...
    | ([anonymous]ident ident* : term)
```

implicit parameters, with or without a type ascription:

<a id="Lean___Parser___Term___implicitBinder-next"></a>

```ebnf
funBinder ::= ...
    | {ident ident*}
```

<a id="Lean___Parser___Term___implicitBinder-next-next"></a>

```ebnf
funBinder ::= ...
    | {ident ident* : term}
```

instance implicits, anonymous or named:

<a id="Lean___Parser___Term___instBinder-next"></a>

```ebnf
funBinder ::= ...
    | [term]
```

<a id="Lean___Parser___Term___instBinder-next-next"></a>

```ebnf
funBinder ::= ...
    | [ident : term]
```

or strict implicit parameters, with or without a type ascription:

<a id="Lean___Parser___Term___strictImplicitBinder-next-next"></a>

```ebnf
funBinder ::= ...
    | ⦃ident ident*⦄
```

<a id="Lean___Parser___Term___strictImplicitBinder-next-next-next"></a>

```ebnf
funBinder ::= ...
    | ⦃ident* : term⦄
```

As usual, an `_` may be used instead of an identifier to create an anonymous parameter, and `⦃` and `⦄` may alternatively be written using `{{` and `}}`, respectively.

Lean's core language does not distinguish between implicit, instance, and explicit parameters: the various kinds of function and function type are definitionally equal. The differences can be observed only during elaboration.

If the expected type of a function includes implicit parameters, but its binders do not, then the resulting function may end up with more parameters than the binders indicated in the code. This is because the implicit parameters are added automatically.

<a id="Implicit-Parameters-from-Types"></a>
Implicit Parameters from Types 

The identity function can be written with a single explicit parameter. As long as its type is known, the implicit type parameter is added automatically.

```proofscript
#check (fun x => x : {α : Type} → α → α)
```

```lean
fun {α} x => x : {α : Type} → α → α
```

The following are all equivalent:

```proofscript
#check (fun {α} x => x : {α : Type} → α → α)
```

```lean
fun {α} x => x : {α : Type} → α → α
```

```proofscript
#check (fun {α} (x : α) => x : {α : Type} → α → α)
```

```lean
fun {α} x => x : {α : Type} → α → α
```

```proofscript
#check (fun {α : Type} (x : α) => x : {α : Type} → α → α)
```

```lean
fun {α} x => x : {α : Type} → α → α
```

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Parentheses, used for grouping expressions (e.g., `a * (b + c)`).
Can also be used for creating simple functions when combined with `·`. Here are some examples:
  - `(· + 1)` is shorthand for `fun x => x + 1`
  - `(· + ·)` is shorthand for `fun x y => x + y`
  - `(f · a b)` is shorthand for `fun x => f x a b`
  - `(h (· + 1) ·)` is shorthand for `fun x => h (fun y => y + 1) x`
  - also applies to other parentheses-like notations such as `(·, 1)` and `(· : Nat → Nat)`
```


### Display 2


```text
Type ascription notation: `(0 : Int)` instructs Lean to process `0` as a value of type `Int`.
An empty type ascription `(e :)` elaborates `e` without the expected type.
This is occasionally useful when Lean's heuristics for filling arguments from the expected type
do not yield the right result.
```


### Display 3


```text
Implicit binder, like `{x y : A}` or `{x y}`.
In regular applications, whenever all parameters before it have been specified,
then a `_` placeholder is automatically inserted for this parameter.
Implicit parameters should be able to be determined from the other arguments and the return type
by unification.

In `@` explicit mode, implicit binders behave like explicit binders.
```


### Display 4


```text
Instance-implicit binder, like `[C]` or `[inst : C]`.
In regular applications without `@` explicit mode, it is automatically inserted
and solved for by typeclass inference for the specified class `C`.
In `@` explicit mode, if `_` is used for an instance-implicit parameter, then it is still solved for by typeclass inference;
use `(_)` to inhibit this and have it be solved for by unification instead, like an implicit argument.
```


### Display 5


```text
Strict-implicit binder, like `⦃x y : A⦄` or `⦃x y⦄`.
In contrast to `{ ... }` implicit binders, strict-implicit binders do not automatically insert
a `_` placeholder until at least one subsequent explicit parameter is specified.
Do *not* use strict-implicit binders unless there is a subsequent explicit parameter.
Assuming this rule is followed, for fully applied expressions implicit and strict-implicit binders have the same behavior.

Example: If `h : ∀ ⦃x : A⦄, x ∈ s → p x` and `hs : y ∈ s`,
then `h` by itself elaborates to itself without inserting `_` for the `x : A` parameter,
and `h hs` has type `p y`.
In contrast, if `h' : ∀ {x : A}, x ∈ s → p x`, then `h` by itself elaborates to have type `?m ∈ s → p ?m`
with `?m` a fresh metavariable.
```


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Failed to infer type of example
```


### Display 2


```text
don't know how to synthesize implicit argument `α`
  @g ?m.3
context:
⊢ Type
```


### Display 3


```text
fun {α} x => x : {α : Type} → α → α
```

