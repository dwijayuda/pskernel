<a id="The-Lean-Language-Reference--Basic-Types--Booleans"></a>

# ProofScript — 20.11. Booleans

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Nat, Int, machine integers, floats, characters, strings, bytes, options, products, sums, lists, arrays, maps, ranges, subtypes and lazy computations retain their distinct native contracts. A target representation is not their meaning. Nat subtraction saturates at zero; the selected Int quotient differs from JavaScript BigInt truncation for some negative inputs. String offsets and Unicode conversions require explicit mappings.

**Compiler and coverage boundary.** The full API entries below retain exact names and signature metadata. Distinguish a signature display from executable source. Unknown reachable primitives reject the requested executable profile.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Basic-Types/Booleans/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Basic-Types/Booleans/index.html). Source Git blob: `fae23f306a50b51544050aa6016fd491e96b118a`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 20.11. Booleans

<a id="Bool___false"></a>

**inductive type**

```text
Bool : Type
```

The Boolean values, `true` and `false`.

Logically speaking, this is equivalent to `Prop` (the type of propositions). The distinction is public important for programming: both propositions and their proofs are erased in the code generator, while `Bool` corresponds to the Boolean type in most programming languages and carries precisely one bit of run-time information.

**Constructors**

```text
Bool.false : Bool
```

The Boolean value `false`, not to be confused with the proposition `False`.

```text
Bool.true : Bool
```

The Boolean value `true`, not to be confused with the proposition `True`.

The constructors `Bool.true` and `Bool.false` are exported from the `Bool` namespace, so they can be written `true` and `false`.

<a id="The-Lean-Language-Reference--Basic-Types--Booleans--Run-Time-Representation"></a>
### 20.11.1. Run-Time Representation

Because `Bool` is an [enum inductive](../../The-Type-System/Inductive-Types/index.md#--tech-term-enum-inductive) type, it is represented by a single byte in compiled code.

<a id="The-Lean-Language-Reference--Basic-Types--Booleans--Booleans-and-Propositions"></a>
### 20.11.2. Booleans and Propositions

Both `Bool` and `Prop` represent notions of truth. From a purely logical perspective, they are equivalent: [propositional extensionality](../../The-Type-System/Propositions/index.md#--tech-term-Extensionality) means that there are fundamentally only two propositions, namely `True` and `False`. However, there is an important pragmatic difference: `Bool` classifies *values* that can be computed by programs, while `Prop` classifies statements for which code generation doesn't make sense. In other words, `Bool` is the notion of truth and falsehood that's appropriate for programs, while `Prop` is the notion that's appropriate for mathematics. Because proofs are erased from compiled programs, keeping `Bool` and `Prop` distinct makes it clear which parts of a Lean file are intended for computation.

A `Bool` can be used wherever a `Prop` is expected. There is a [coercion](../../Coercions/index.md#--tech-term-coercion) from every `Bool` `b` to the proposition `b = true`. By `propext`, `true = true` is equal to `True`, and `false = true` is equal to `False`.

Not every proposition can be used by programs to make run-time decisions. Otherwise, a program could branch on whether the Collatz conjecture is true or false! Many propositions, however, can be checked algorithmically. These propositions are called [*decidable*](../../Type-Classes/Basic-Classes/index.md#--tech-term-decidable) propositions, and have instances of the `Decidable` type class. The function `Decidable.decide` converts a proof-carrying `Decidable` result into a `Bool`. This function is also a coercion from decidable propositions to `Bool`, so `(2 = 2 : Bool)` evaluates to `true`.

<a id="The-Lean-Language-Reference--Basic-Types--Booleans--Syntax"></a>
### 20.11.3. Syntax

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Boolean Infix Operators**

The infix operators `&&`, `||`, and `^^` are notations for `Bool.and`, `Bool.or`, and `Bool.xor`, respectively.

<a id="_FLQQ_term_________FLQQ_-next-next"></a>

```ebnf
term ::= ...
    | term && term
```

<a id="_FLQQ_term_________FLQQ_-next-next-next"></a>

```ebnf
term ::= ...
    | term || term
```

<a id="Bool____FLQQ_term_________FLQQ_"></a>

```ebnf
term ::= ...
    | term ^^ term
```

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Boolean Negation**

The prefix operator `!` is notation for `Bool.not`.

<a id="term____"></a>

```ebnf
term ::= ...
    | !term
```

<a id="The-Lean-Language-Reference--Basic-Types--Booleans--API-Reference"></a>
### 20.11.4. API Reference

<a id="The-Lean-Language-Reference--Basic-Types--Booleans--API-Reference--Logical-Operations"></a>
#### 20.11.4.1. Logical Operations

The functions `cond`, `and`, and `or` are short-circuiting. In other words, `false && BIG_EXPENSIVE_COMPUTATION` does not need to execute `BIG_EXPENSIVE_COMPUTATION` before returning `false`. These functions are defined using the `macro_inline` attribute, which causes the compiler to replace calls to them with their definitions while generating code, and the definitions use nested pattern matching to achieve the short-circuiting behavior.

<a id="cond"></a>

**def**

```text
cond.{u} {α : Sort u} (c : Bool) (x y : α) : α
```

The conditional function.

`cond c x y` is the same as `if c then x else y`, but optimized for a Boolean condition rather than a decidable proposition. It can also be written using the notation `bif c then x else y`.

Just like `ite`, `cond` is declared `@[macro_inline]`, which causes applications of `cond` to be unfolded. As a result, `x` and `y` are not evaluated at runtime until one of them is selected, and only the selected branch is evaluated.

<a id="Bool___dcond"></a>

**def**

```text
Bool.dcond.{u} {α : Sort u} (c : Bool) (x : c = true → α)
  (y : c = false → α) : α
```

The dependent conditional function, in which each branch is provided with a local assumption about the condition's value. This allows the value to be used in proofs as well as for control flow.

`dcond c (fun h => x) (fun h => y)` is the same as `if h : c then x else y`, but optimized for a Boolean condition rather than a decidable proposition. Unlike the non-dependent version `cond`, there is no special notation for `dcond`.

Just like `ite`, `dite`, and `cond`, `dcond` is declared `@[macro_inline]`, which causes applications of `dcond` to be unfolded. As a result, `x` and `y` are not evaluated at runtime until one of them is selected, and only the selected branch is evaluated. `dcond` is intended for metaprogramming use, rather than for use in verified programs, so behavioral lemmas are not provided.

<a id="Bool___not"></a>

**def**

```text
Bool.not (x : Bool) : Bool
```

Boolean negation, also known as Boolean complement. `not x` can be written `!x`.

This is a function that maps the value `true` to `false` and the value `false` to `true`. The propositional connective is `Not : Prop → Prop`.

Conventions for notations in identifiers:

- The recommended spelling of `!` in identifiers is `not`.

<a id="Bool___and"></a>

**def**

```text
Bool.and (x y : Bool) : Bool
```

Boolean “and”, also known as conjunction. `and x y` can be written `x && y`.

The corresponding propositional connective is `And : Prop → Prop → Prop`, written with the `∧` operator.

The Boolean `and` is a `@[macro_inline]` function in order to give it short-circuiting evaluation: if `x` is `false` then `y` is not evaluated at runtime.

Conventions for notations in identifiers:

- The recommended spelling of `&&` in identifiers is `and`.
- The recommended spelling of `||` in identifiers is `or`.

<a id="Bool___or"></a>

**def**

```text
Bool.or (x y : Bool) : Bool
```

Boolean “or”, also known as disjunction. `or x y` can be written `x || y`.

The corresponding propositional connective is `Or : Prop → Prop → Prop`, written with the `∨` operator.

The Boolean `or` is a `@[macro_inline]` function in order to give it short-circuiting evaluation: if `x` is `true` then `y` is not evaluated at runtime.

<a id="Bool___xor"></a>

**def**

```text
Bool.xor : Bool → Bool → Bool
```

Boolean “exclusive or”. `xor x y` can be written `x ^^ y`.

`x ^^ y` is `true` when precisely one of `x` or `y` is `true`. Unlike `and` and `or`, it does not have short-circuiting behavior, because one argument's value never determines the final value. Also unlike `and` and `or`, there is no commonly-used corresponding propositional connective.

Examples:

- `false ^^ false = false`
- `true ^^ false = true`
- `false ^^ true = true`
- `true ^^ true = false`

Conventions for notations in identifiers:

- The recommended spelling of `^^` in identifiers is `xor`.

<a id="The-Lean-Language-Reference--Basic-Types--Booleans--API-Reference--Comparisons"></a>
#### 20.11.4.2. Comparisons

Most comparisons on Booleans should be performed using the `DecidableEq Bool`, `LT Bool`, `LE Bool` instances.

<a id="Bool___decEq"></a>

**def**

```text
Bool.decEq (a b : Bool) : Decidable (a = b)
```

Decides whether two Booleans are equal.

This function should normally be called via the `DecidableEq Bool` instance that it exists to support.

<a id="The-Lean-Language-Reference--Basic-Types--Booleans--API-Reference--Conversions"></a>
#### 20.11.4.3. Conversions

<a id="Bool___toISize"></a>

**def**

```text
Bool.toISize (b : Bool) : ISize
```

Converts `true` to `1` and `false` to `0`.

<a id="Bool___toUInt8"></a>

**def**

```text
Bool.toUInt8 (b : Bool) : UInt8
```

Converts `true` to `1` and `false` to `0`.

<a id="Bool___toUInt16"></a>

**def**

```text
Bool.toUInt16 (b : Bool) : UInt16
```

Converts `true` to `1` and `false` to `0`.

<a id="Bool___toUInt32"></a>

**def**

```text
Bool.toUInt32 (b : Bool) : UInt32
```

Converts `true` to `1` and `false` to `0`.

<a id="Bool___toUInt64"></a>

**def**

```text
Bool.toUInt64 (b : Bool) : UInt64
```

Converts `true` to `1` and `false` to `0`.

<a id="Bool___toUSize"></a>

**def**

```text
Bool.toUSize (b : Bool) : USize
```

Converts `true` to `1` and `false` to `0`.

<a id="Bool___toInt8"></a>

**def**

```text
Bool.toInt8 (b : Bool) : Int8
```

Converts `true` to `1` and `false` to `0`.

<a id="Bool___toInt16"></a>

**def**

```text
Bool.toInt16 (b : Bool) : Int16
```

Converts `true` to `1` and `false` to `0`.

<a id="Bool___toInt32"></a>

**def**

```text
Bool.toInt32 (b : Bool) : Int32
```

Converts `true` to `1` and `false` to `0`.

<a id="Bool___toInt64"></a>

**def**

```text
Bool.toInt64 (b : Bool) : Int64
```

Converts `true` to `1` and `false` to `0`.

<a id="Bool___toNat"></a>

**def**

```text
Bool.toNat (b : Bool) : Nat
```

Converts `true` to `1` and `false` to `0`.

<a id="Bool___toInt"></a>

**def**

```text
Bool.toInt (b : Bool) : Int
```

Converts `true` to `1` and `false` to `0`.

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Boolean “and”, also known as conjunction. `and x y` can be written `x && y`.

The corresponding propositional connective is `And : Prop → Prop → Prop`, written with the `∧`
operator.

The Boolean `and` is a `@[macro_inline]` function in order to give it short-circuiting evaluation:
if `x` is `false` then `y` is not evaluated at runtime.


Conventions for notations in identifiers:

 * The recommended spelling of `&&` in identifiers is `and`.
```


### Display 2


```text
Boolean “or”, also known as disjunction. `or x y` can be written `x || y`.

The corresponding propositional connective is `Or : Prop → Prop → Prop`, written with the `∨`
operator.

The Boolean `or` is a `@[macro_inline]` function in order to give it short-circuiting evaluation:
if `x` is `true` then `y` is not evaluated at runtime.


Conventions for notations in identifiers:

 * The recommended spelling of `||` in identifiers is `or`.
```


### Display 3


```text
Boolean “exclusive or”. `xor x y` can be written `x ^^ y`.

`x ^^ y` is `true` when precisely one of `x` or `y` is `true`. Unlike `and` and `or`, it does not
have short-circuiting behavior, because one argument's value never determines the final value. Also
unlike `and` and `or`, there is no commonly-used corresponding propositional connective.

Examples:
 * `false ^^ false = false`
 * `true ^^ false = true`
 * `false ^^ true = true`
 * `true ^^ true = false`


Conventions for notations in identifiers:

 * The recommended spelling of `^^` in identifiers is `xor`.
```


### Display 4


```text
Boolean negation, also known as Boolean complement. `not x` can be written `!x`.

This is a function that maps the value `true` to `false` and the value `false` to `true`. The
propositional connective is `Not : Prop → Prop`.


Conventions for notations in identifiers:

 * The recommended spelling of `!` in identifiers is `not`.
```

