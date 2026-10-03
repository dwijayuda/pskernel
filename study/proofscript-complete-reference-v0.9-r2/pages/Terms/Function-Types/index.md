<a id="function-types"></a>

# ProofScript — 13.2. Function Types

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Terms keep native binding, precedence and type-directed elaboration. D-CALL is adjacency-sensitive: f(x,y) supplies two curried arguments; f((x,y)) and native f (x,y) supply one tuple. An empty call passes Unit. Lambdas use fun, records use :=, and match patterns remain native even when constructor terms use decorated calls. Braces delimit specific categories; they do not disable the native layout checks inside them.

**Compiler and coverage boundary.** Preserve grouping that influences elaboration. Do not flatten nested calls, split patterns on arbitrary bars, or rewrite punctuation inside strings and quotations.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Terms/Function-Types/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Terms/Function-Types/index.html). Source Git blob: `b7ac5f8b6e6c09fbb9989fb093d17651bd07e752`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 13.2. Function Types

Lean's function types describe more than just the function's domain and codomain. They also provide instructions for elaborating application sites by indicating that some parameters are to be discovered automatically via unification or [type class synthesis](../../Type-Classes/Instance-Synthesis/index.md#instance-synth), that others are optional with default values, and that yet others should be synthesized using a custom tactic script. Furthermore, their syntax contains support for abbreviating [curried](../../The-Type-System/Functions/index.md#--tech-term-currying) functions.

<a id="term-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Function types**

Dependent function types include an explicit name:

<a id="Lean___Parser___Term___depArrow"></a>

```ebnf
term ::= ...
    | (ident : term) → term
```

Non-dependent function types do not:

<a id="Lean___Parser___Term___arrow"></a>

```ebnf
term ::= ...
    | term → term
```

<a id="term-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Curried Function Types**

Dependent function types may include multiple parameters that have the same type in a single set of parentheses:

<a id="Lean___Parser___Term___depArrow-next"></a>

```ebnf
term ::= ...
    | (ident* : term) → term
```

This is equivalent to repeating the type annotation for each parameter name in a nested function type.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Implicit, Optional, and Auto Parameters**

Function types can describe functions that take implicit, instance implicit, optional, and automatic parameters. All but instance implicit parameters require one or more names.

<a id="Lean___Parser___Term___depArrow-next-next"></a>

```ebnf
term ::= ...
    | (ident* : term := term) → term
```

<a id="Lean___Parser___Term___depArrow-next-next-next"></a>

```ebnf
term ::= ...
    | (ident* : term := by tacticSeq) → term
```

<a id="Lean___Parser___Term___depArrow-next-next-next-next"></a>

```ebnf
term ::= ...
    | {ident* : term} → term
```

<a id="Lean___Parser___Term___depArrow-next-next-next-next-next"></a>

```ebnf
term ::= ...
    | [term] → term
```

<a id="Lean___Parser___Term___depArrow-next-next-next-next-next-next"></a>

```ebnf
term ::= ...
    | [ident : term] → term
```

<a id="Lean___Parser___Term___depArrow-next-next-next-next-next-next-next"></a>

```ebnf
term ::= ...
    | ⦃ident* : term⦄ → term
```

<a id="Multiple-Parameters___-Same-Type"></a>
Multiple Parameters, Same Type 

The type of `Nat.add` can be written in the following ways:

- `Nat → Nat → Nat`
- `(a : Nat) → (b : Nat) → Nat`
- `(a b : Nat) → Nat`

The last two types allow the function to be used with [named arguments](../Function-Application/index.md#--tech-term-named-arguments); aside from this, all three are equivalent.

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Explicit binder, like `(x y : A)` or `(x y)`.
Default values can be specified using `(x : A := v)` syntax, and tactics using `(x : A := by tac)`.
```


### Display 2


```text
A sequence of tactics in brackets, or a delimiter-free indented sequence of tactics.
Delimiter-free indentation is determined by the *first* tactic of the sequence.
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

