<a id="The-Lean-Language-Reference--Terms--Numeric-Literals"></a>

# ProofScript — 13.5. Numeric Literals

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Terms keep native binding, precedence and type-directed elaboration. D-CALL is adjacency-sensitive: f(x,y) supplies two curried arguments; f((x,y)) and native f (x,y) supply one tuple. An empty call passes Unit. Lambdas use fun, records use :=, and match patterns remain native even when constructor terms use decorated calls. Braces delimit specific categories; they do not disable the native layout checks inside them.

**Compiler and coverage boundary.** Preserve grouping that influences elaboration. Do not flatten nested calls, split patterns on arbitrary bars, or rewrite punctuation inside strings and quotations.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Terms/Numeric-Literals/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Terms/Numeric-Literals/index.html). Source Git blob: `99afd0909fe40fca7c932be82ce239a52d179697`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 13.5. Numeric Literals

There are two kinds of numeric literal: natural number literals and 
<a id="--tech-term-scientific-literals"></a>
scientific literals. Both are overloaded via [type classes](../../Type-Classes/index.md#--tech-term-type-class).

<a id="nat-literals"></a>
### 13.5.1. Natural Numbers

Natural numbers can be specified in several forms:

- A sequence of digits 0 through 9 is a decimal literal
- `0b` or `0B` followed by a sequence of one or more 0s and 1s is a binary literal
- `0o` or `0O` followed by a sequence of one or more digits 0 through 7 is an octal literal
- `0x` or `0X` followed by a sequence of one or more hex digits (0 through 9 and A through F, case-insensitive) is a hexadecimal literal

All numeric literals can also contain internal underscores, except for between the first two characters in a binary, octal, or hexadecimal literal. These are intended to help groups of digits in natural ways, for instance `1_000_000` or `0x_c0de_cafe`. (While it is possible to write the number 123 as `1_2__3`, this is not recommended.)

When Lean encounters a natural number literal `n`, it interprets it via the overloaded method `OfNat.ofNat n`. A [default instance](../../Type-Classes/Instance-Synthesis/index.md#--tech-term-default-instances) of `OfNat Nat n` ensures that the type `Nat` can be inferred when no other type information is present.

<a id="OfNat___mk"></a>

**type class**

```text
OfNat.{u} (α : Type u) : Nat → Type u
```

The class `OfNat α n` powers the numeric literal parser. If you write `37 : α`, Lean will attempt to synthesize `OfNat α 37`, and will generate the term `(OfNat.ofNat 37 : α)`.

There is a bit of infinite regress here since the desugaring apparently still contains a literal `37` in it. The type of expressions contains a primitive constructor for "raw natural number literals", which you can directly access using the macro `nat_lit 37`. Raw number literals are always of type `Nat`. So it would be more correct to say that Lean looks for an instance of `OfNat α (nat_lit 37)`, and it generates the term `(OfNat.ofNat (nat_lit 37) : α)`.

**Instance Constructor**

```text
OfNat.mk.{u}
```

**Methods**

```text
ofNat : α
```

The `OfNat.ofNat` function is automatically inserted by the parser when the user writes a numeric literal like `1 : α`. Implementations of this typeclass can therefore customize the behavior of `n : α` based on `n` and `α`.

<a id="Custom-Natural-Number-Literals"></a>
Custom Natural Number Literals 

The structure `NatInterval` represents an interval of natural numbers.
<a id="NatInterval-_LPAR_in-Custom-Natural-Number-Literals_RPAR_"></a>
<a id="NatInterval___low-_LPAR_in-Custom-Natural-Number-Literals_RPAR_"></a>
<a id="NatInterval___high-_LPAR_in-Custom-Natural-Number-Literals_RPAR_"></a>
<a id="NatInterval___low_le_high-_LPAR_in-Custom-Natural-Number-Literals_RPAR_"></a>


```proofscript
structure NatInterval where
  low : Nat
  high : Nat
  low_le_high : low ≤ high

instance : Add NatInterval where
  add
    | ⟨lo1, hi1, le1⟩, ⟨lo2, hi2, le2⟩ =>
      ⟨lo1 + lo2, hi1 + hi2, by grind⟩
```

An `OfNat` instance allows natural number literals to be used to represent intervals:

```proofscript
instance : OfNat NatInterval n where
  ofNat := ⟨n, n, by omega⟩
```

```proofscript
#eval (8 : NatInterval)
```

```lean
{ low := 8, high := 8, low_le_high := _ }
```

```proofscript
#eval (0b111 : NatInterval)
```

```lean
{ low := 7, high := 7, low_le_high := _ }
```

There are no separate integer literals. Terms such as `-5` consist of a prefix negation (which can be overloaded via the `Neg` type class) applied to a natural number literal.

<a id="The-Lean-Language-Reference--Terms--Numeric-Literals--Scientific-Numbers"></a>
### 13.5.2. Scientific Numbers

Scientific number literals consist of a sequence of decimal digits followed (without intervening whitespace) by an optional decimal part (a period followed by zero or more decimal digits) and an optional exponent part (the letter `e` followed by an optional `+` or `-` and then followed by one or more decimal digits). Scientific numbers are overloaded via the `OfScientific` type class.

<a id="OfScientific___mk"></a>

**type class**

```text
OfScientific.{u} (α : Type u) : Type u
```

For decimal and scientific numbers (e.g., `1.23`, `3.12e10`). Examples:

- `1.23` is syntax for `OfScientific.ofScientific (nat_lit 123) true (nat_lit 2)`
- `121e100` is syntax for `OfScientific.ofScientific (nat_lit 121) false (nat_lit 100)`

Note the use of `nat_lit`; there is no wrapping `OfNat.ofNat` in the resulting term.

**Instance Constructor**

```text
OfScientific.mk.{u}
```

**Methods**

```text
ofScientific : Nat → Bool → Nat → α
```

Produces a value from the given mantissa, exponent sign, and decimal exponent. For the exponent sign, `true` indicates a negative exponent.

Examples:

- `1.23` is syntax for `OfScientific.ofScientific (nat_lit 123) true (nat_lit 2)`
- `121e100` is syntax for `OfScientific.ofScientific (nat_lit 121) false (nat_lit 100)`

Note the use of `nat_lit`; there is no wrapping `OfNat.ofNat` in the resulting term.

There are an `OfScientific` instances for `Float` and `Float32`, but no separate floating-point literals.

<a id="The-Lean-Language-Reference--Terms--Numeric-Literals--Strings"></a>
### 13.5.3. Strings

String literals are described in the [chapter on strings.](../../Basic-Types/Strings/index.md#string-syntax)

<a id="The-Lean-Language-Reference--Terms--Numeric-Literals--Lists-and-Arrays"></a>
### 13.5.4. Lists and Arrays

List and array literals contain comma-separated sequences of elements inside of brackets, with arrays prefixed by a hash mark (`#`). Array literals are interpreted as list literals wrapped in a call to a conversion. For performance reasons, very large list and array literals are converted to sequences of local definitions, rather than just iterated applications of the list constructor.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**List Literals**

<a id="_FLQQ_term_LSQ___RSQ__FLQQ_"></a>

```ebnf
term ::= ...
    | [term,*]
```

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Array Literals**

<a id="_FLQQ_term____LSQ______RSQ__FLQQ_"></a>

```ebnf
term ::= ...
    | #[term,*]
```

<a id="Long-List-Literals"></a>
Long List Literals 

This list contains 32 elements. The generated code is an iterated application of `List.cons`:

```proofscript
#check
  [1,1,1,1,1,1,1,1,
   1,1,1,1,1,1,1,1,
   1,1,1,1,1,1,1,1,
   1,1,1,1,1,1,1,1]
```

```lean
[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1] : List Nat
```

With 33 elements, the list literal becomes a sequence of local definitions:

```proofscript
#check
  [1,1,1,1,1,1,1,1,
   1,1,1,1,1,1,1,1,
   1,1,1,1,1,1,1,1,
   1,1,1,1,1,1,1,1,
   1]
```

```lean
let y :=
  let y :=
    let y := [1, 1, 1, 1, 1];
    1 :: 1 :: 1 :: 1 :: y;
  let y := 1 :: 1 :: 1 :: 1 :: y;
  1 :: 1 :: 1 :: 1 :: y;
let y :=
  let y := 1 :: 1 :: 1 :: 1 :: y;
  1 :: 1 :: 1 :: 1 :: y;
let y := 1 :: 1 :: 1 :: 1 :: y;
1 :: 1 :: 1 :: 1 :: y : List Nat
```

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
The syntax `[a, b, c]` is shorthand for `a :: b :: c :: []`, or
`List.cons a (List.cons b (List.cons c List.nil))`. It allows conveniently constructing
list literals.

For lists of length at least 64, an alternative desugaring strategy is used
which uses let bindings as intermediates as in
`let left := [d, e, f]; a :: b :: c :: left` to avoid creating very deep expressions.
Note that this changes the order of evaluation, although it should not be observable
unless you use side effecting operations like `dbg_trace`.


Conventions for notations in identifiers:

 * The recommended spelling of `[]` in identifiers is `nil`.

 * The recommended spelling of `[a]` in identifiers is `singleton`.
```


### Display 2


```text
Syntax for `Array α`. 

Conventions for notations in identifiers:

 * The recommended spelling of `#[]` in identifiers is `empty`.

 * The recommended spelling of `#[x]` in identifiers is `singleton`.
```


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
{ low := 8, high := 8, low_le_high := _ }
```


### Display 2


```text
{ low := 7, high := 7, low_le_high := _ }
```


### Display 3


```text
[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1] : List Nat
```


### Display 4


```text
let y :=
  let y :=
    let y := [1, 1, 1, 1, 1];
    1 :: 1 :: 1 :: 1 :: y;
  let y := 1 :: 1 :: 1 :: 1 :: y;
  1 :: 1 :: 1 :: 1 :: y;
let y :=
  let y := 1 :: 1 :: 1 :: 1 :: y;
  1 :: 1 :: 1 :: 1 :: y;
let y := 1 :: 1 :: 1 :: 1 :: y;
1 :: 1 :: 1 :: 1 :: y : List Nat
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
lo1:Nathi1:Natle1:lo1 ≤ hi1lo2:Nathi2:Natle2:lo2 ≤ hi2⊢ lo1 + lo2 ≤ hi1 + hi2
```


### Display 2


```text
All goals completed! 🐙
```


### Display 3


```text
n:Nat⊢ n ≤ n
```

