<a id="pattern-matching"></a>

# ProofScript — 13.8. Pattern Matching

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Terms keep native binding, precedence and type-directed elaboration. D-CALL is adjacency-sensitive: f(x,y) supplies two curried arguments; f((x,y)) and native f (x,y) supply one tuple. An empty call passes Unit. Lambdas use fun, records use :=, and match patterns remain native even when constructor terms use decorated calls. Braces delimit specific categories; they do not disable the native layout checks inside them.

**Compiler and coverage boundary.** Preserve grouping that influences elaboration. Do not flatten nested calls, split patterns on arbitrary bars, or rewrite punctuation inside strings and quotations.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Terms/Pattern-Matching/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Terms/Pattern-Matching/index.html). Source Git blob: `58f9c04d8dbacbdda4cb3fcf534cbeeda1d40dec`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 13.8. Pattern Matching

<a id="--tech-term-Pattern-matching"></a>
*Pattern matching* is a way to recognize and destructure values using a syntax of 
<a id="--tech-term-patterns"></a>
*patterns* that are a subset of the terms. A pattern that recognizes and destructures a value is similar to the syntax that would be used to construct the value. One or more 
<a id="--tech-term-match-discriminants"></a>
*match discriminants* are simultaneously compared to a series of 
<a id="--tech-term-match-alternatives"></a>
*match alternatives*. Discriminants may be named. Each alternative contains one or more comma-separated sequences of patterns; all pattern sequences must contain the same number of patterns as there are discriminants. When a pattern sequence matches all of the discriminants, the term following the corresponding [`=>`](index.md#Lean___Parser___Term___match) is evaluated in an environment extended with values for each [pattern variable](index.md#--tech-term-Pattern-variables) as well as an equality hypothesis for each named discriminant. This term is called the 
<a id="--tech-term-right-hand-side"></a>
*right-hand side* of the match alternative.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Pattern Matching**

<a id="Lean___Parser___Term___match"></a>

```ebnf
term ::= ...
    | match
          ((generalizing := (trueVal | falseVal)))?
          ((motive := term))?
          matchDiscr,*
        with
      (| (term,*)|* => term)*
```

<a id="matchDiscr"></a>

**syntax**

**Match Discriminants**

<a id="Lean___Parser___Term___matchDiscr"></a>

```ebnf
matchDiscr ::=
    term
```

<a id="Lean___Parser___Term___matchDiscr-next"></a>

```ebnf
matchDiscr ::= ...
    | ident : term
```

Pattern matching expressions may alternatively use [quasiquotations](../../Notations-and-Macros/Macros/index.md#--tech-term-Quasiquotation) as patterns, matching the corresponding `Lean.Syntax` values and treating the contents of [antiquotations](../../Notations-and-Macros/Macros/index.md#--tech-term-antiquotations) as ordinary patterns. Quotation patterns are compiled differently than other patterns, so if one pattern in a [`match`](index.md#Lean___Parser___Term___match) is syntax, then all of them must be. Quotation patterns are described in [the section on quotations](../../Notations-and-Macros/Macros/index.md#quote-patterns).

Patterns are a subset of the terms. They consist of the following:

  Catch-All Patterns

The hole syntax `_` is a pattern that matches any value and binds no pattern variables. Catch-all patterns are not entirely equivalent to unused pattern variables. They can be used in positions where the pattern's typing would otherwise require a more specific [inaccessible pattern](index.md#--tech-term-Inaccessible-patterns), while variables cannot be used in these positions.

  Identifiers

If an identifier is not bound in the current scope and is not applied to arguments, then it represents a pattern variable. 
<a id="--tech-term-Pattern-variables"></a>
*Pattern variables* match any value, and the values thus matched are bound to the pattern variable in the local environment in which the [right-hand side](index.md#--tech-term-right-hand-side) is evaluated. If the identifier is bound, it is a pattern if it is bound to the [constructor](../../The-Type-System/Inductive-Types/index.md#--tech-term-constructors) of an [inductive type](../../The-Type-System/Inductive-Types/index.md#--tech-term-Inductive-types) or if its definition has the `match_pattern` attribute.

  Applications

Function applications are patterns if the function being applied is an identifier that is bound to a constructor or that has the `match_pattern` attribute and if all arguments are also patterns. If the identifier is a constructor, the pattern matches values built with that constructor if the argument patterns match the constructor's arguments. If it is a function with the `match_pattern` attribute, then the function application is unfolded and the resulting term's [normal form](../../The-Type-System/index.md#--tech-term-normal-form) is used as the pattern. Default arguments are inserted as usual, and their normal forms are used as patterns. [Ellipses](../Function-Application/index.md#--tech-term-ellipsis), however, result in all further arguments being treated as universal patterns, even those with associated default values or tactics.

  Literals

[Character literals](../../Basic-Types/Characters/index.md#char-syntax) and [string literals](../../Basic-Types/Strings/index.md#string-syntax) are patterns that match the corresponding character or string. [Raw string literals](../../Basic-Types/Strings/index.md#raw-string-literals) are allowed as patterns, but [interpolated strings](../../Basic-Types/Strings/index.md#string-interpolation) are not. [Natural number literals](../../Basic-Types/Natural-Numbers/index.md#nat-syntax) in patterns are interpreted by synthesizing the corresponding `OfNat` instance and reducing the resulting term to [normal form](../../The-Type-System/index.md#--tech-term-normal-form), which must be a pattern. Similarly, [scientific literals](../Numeric-Literals/index.md#--tech-term-scientific-literals) are interpreted via the corresponding `OfScientific` instance.

  Structure Instances

[Structure instances](../../The-Type-System/Inductive-Types/index.md#--tech-term-structure-instance) may be used as patterns. They are interpreted as the corresponding structure constructor.

  Quoted names

Quoted names, such as ```x`` and `````none```, match the corresponding `Lean.Name` value.

  Macros

Macros in patterns are expanded. They are patterns if the resulting expansions are patterns.

  Inaccessible patterns

<a id="--tech-term-Inaccessible-patterns"></a>
Inaccessible patterns are patterns that are forced to have a particular value by later typing constraints. Any term may be used as an inaccessible term. Inaccessible terms are parenthesized, with a preceding period (`.`).

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Inaccessible Patterns**

<a id="Lean___Parser___Term___inaccessible"></a>

```ebnf
term ::= ...
    | .(term)
```

<a id="Inaccessible-Patterns"></a>
Inaccessible Patterns 

A number's *parity* is whether it's even or odd:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="Parity-_LPAR_in-Inaccessible-Patterns_RPAR_"></a>
<a id="Parity___even-_LPAR_in-Inaccessible-Patterns_RPAR_"></a>
<a id="Parity___odd-_LPAR_in-Inaccessible-Patterns_RPAR_"></a>
<a id="Nat___parity-_LPAR_in-Inaccessible-Patterns_RPAR_"></a>


```proofscript
inductive Parity : Nat → Type where
  | even (h : Nat) : Parity (h + h)
  | odd (h : Nat) : Parity ((h + h) + 1)

function Nat.parity (n : Nat) : Parity n :=
  match n with
  | 0 => .even 0
  | n' + 1 =>
    match n'.parity with
    | .even h => .odd h
    | .odd h =>
      have eq : (h + 1) + (h + 1) = (h + h + 1 + 1) :=
        by omega
      eq ▸ .even (h + 1)
```

Because a value of type `Parity` contains half of a number (rounded down) as part of its representation of evenness or oddness, division by two can be implemented (in an unconventional manner) by finding a parity and then extracting the number.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="half-_LPAR_in-Inaccessible-Patterns_RPAR_"></a>


```proofscript
function half (n : Nat) : Nat :=
  match n, n.parity with
  | .(h + h),     .even h => h
  | .(h + h + 1), .odd h  => h
```

Because the index structure of `Parity.even` and `Parity.odd` force the number to have a certain form that is not otherwise a valid pattern, patterns that match on it must use inaccessible patterns for the number being divided.

Patterns may additionally be named. 
<a id="--tech-term-Named-patterns"></a>
Named patterns associate a name with a pattern; in subsequent patterns and on the right-hand side of the match alternative, the name refers to the part of the value that was matched by the given pattern. Named patterns are written with an `@` between the name and the pattern. Just like discriminants, named patterns may also be provided with names for equality assumptions.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Named Patterns**

<a id="Lean___Parser___Term___namedPattern"></a>

```ebnf
term ::= ...
    | ident@term
```

<a id="Lean___Parser___Term___namedPattern-next"></a>

```ebnf
term ::= ...
    | ident@ident:term
```

<a id="The-Lean-Language-Reference--Terms--Pattern-Matching--Types"></a>
### 13.8.1. Types

Each discriminant must be well typed. Because patterns are a subset of terms, their types can also be checked. Each pattern that matches a given discriminant must have the same type as the corresponding discriminant.

The [right-hand side](index.md#--tech-term-right-hand-side) of each match alternative should have the same type as the overall [`match`](index.md#Lean___Parser___Term___match) term. To support dependent types, matching a discriminant against a pattern refines the types that are expected within the scope of the pattern. In both subsequent patterns in the same match alternative and the right-hand side's type, occurrences of the discriminant are replaced by the pattern that it was matched against.

<a id="Type-Refinement"></a>
Type Refinement 

This [indexed family](../../The-Type-System/Inductive-Types/index.md#--tech-term-indexed-families) describes mostly-balanced trees, with the depth encoded in the type.
<a id="BalancedTree-_LPAR_in-Type-Refinement_RPAR_"></a>
<a id="BalancedTree___empty-_LPAR_in-Type-Refinement_RPAR_"></a>
<a id="BalancedTree___branch-_LPAR_in-Type-Refinement_RPAR_"></a>
<a id="BalancedTree___lbranch-_LPAR_in-Type-Refinement_RPAR_"></a>
<a id="BalancedTree___rbranch-_LPAR_in-Type-Refinement_RPAR_"></a>


```proofscript
inductive BalancedTree (α : Type u) : Nat → Type u where
  | empty : BalancedTree α 0
  | branch
    (left : BalancedTree α n)
    (val : α)
    (right : BalancedTree α n) :
    BalancedTree α (n + 1)
  | lbranch
    (left : BalancedTree α (n + 1))
    (val : α)
    (right : BalancedTree α n) :
    BalancedTree α (n + 2)
  | rbranch
    (left : BalancedTree α n)
    (val : α)
    (right : BalancedTree α (n + 1)) :
    BalancedTree α (n + 2)
```

To begin the implementation of a function to construct a perfectly balanced tree with some initial element and a given depth, a [hole](../Holes/index.md#--tech-term-hole) can be used for the definition.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
function BalancedTree.filledWith
    (x : α) (depth : Nat) :
    BalancedTree α depth :=
  _
```

The error message demonstrates that the tree should have the indicated depth.

```lean
don't know how to synthesize placeholder
context:
α:Type ux:αdepth:Nat⊢ BalancedTree α depth
```

Matching on the expected depth and inserting holes results in an error message for each hole. These messages demonstrate that the expected type has been refined, with `depth` replaced by the matched values.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
function BalancedTree.filledWith
    (x : α) (depth : Nat) :
    BalancedTree α depth :=
  match depth with
  | 0 => _
  | n + 1 => _
```

The first hole yields the following message:

```lean
don't know how to synthesize placeholder
context:
α:Type ux:αdepth:Nat⊢ BalancedTree α 0
```

The second hole yields the following message:

```lean
don't know how to synthesize placeholder
context:
α:Type ux:αdepth n:Nat⊢ BalancedTree α (n + 1)
```

Matching on the depth of a tree and the tree itself leads to a refinement of the tree's type according to the depth's pattern. This means that certain combinations are not well-typed, such as `0` and `branch`, because refining the second discriminant's type yields `BalancedTree α 0` which does not match the constructor's type.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="BalancedTree___isPerfectlyBalanced-_LPAR_in-Type-Refinement_RPAR_"></a>


```proofscript
function BalancedTree.isPerfectlyBalanced
    (n : Nat) (t : BalancedTree α n) : Bool :=
  match n, t with
  | 0, .empty => true
  | 0, .branch left val right =>
    isPerfectlyBalanced left &&
    isPerfectlyBalanced right
  | _, _ => false
```

```lean
Type mismatch
  left.branch val right
has type
  BalancedTree ?m.13 (?m.12 + 1)
but is expected to have type
  BalancedTree α 0
```

<a id="The-Lean-Language-Reference--Terms--Pattern-Matching--Types--Pattern-Equality-Proofs"></a>
#### 13.8.1.1. Pattern Equality Proofs

When a discriminant is named, [`match`](index.md#Lean___Parser___Term___match) generates a proof that the pattern and discriminant are equal, binding it to the provided name in the [right-hand side](index.md#--tech-term-right-hand-side). This is useful to bridge the gap between dependent pattern matching on indexed families and APIs that expect explicit propositional arguments, and it can help tactics that make use of assumptions to succeed.

<a id="Pattern-Equality-Proofs"></a>
Pattern Equality Proofs 

The function `last?`, which either throws an exception or returns the last element of its argument, uses the standard library function `List.getLast`. This function expects a proof that the list in question is nonempty. Naming the match on `xs` ensures that there's an assumption in scope that states that `xs` is equal to `_ :: _`, which `simp_all` uses to discharge the goal.
<a id="last___-_LPAR_in-Pattern-Equality-Proofs_RPAR_"></a>


```proofscript
def last? (xs : List α) : Except String α :=
  match h : xs with
  | [] =>
    .error "Can't take first element of empty list"
  | _ :: _ =>
    .ok <| xs.getLast (show xs ≠ [] by intro h'; simp_all)
```

Without the name, `simp_all` is unable to find the contradiction.
<a id="last______-_LPAR_in-Pattern-Equality-Proofs_RPAR_"></a>


```proofscript
def last?' (xs : List α) : Except String α :=
  match xs with
  | [] =>
    .error "Can't take first element of empty list"
  | _ :: _ =>
    .ok <| xs.getLast (show xs ≠ [] by intro h'; simp_all)
```

```lean
simp_all made no progress
```

<a id="The-Lean-Language-Reference--Terms--Pattern-Matching--Types--Explicit-Motives"></a>
#### 13.8.1.2. Explicit Motives

Pattern matching is not a built-in primitive of Lean. Instead, it is translated to applications of [recursors](../../The-Type-System/Inductive-Types/index.md#--tech-term-recursor) via [auxiliary matching functions](../../Elaboration-and-Compilation/index.md#--tech-term-auxiliary-matching-functions). Both require a [*motive*](../../The-Type-System/Inductive-Types/index.md#--tech-term-motive) that explains the relationship between the discriminant and the resulting type. Generally, the [`match`](index.md#Lean___Parser___Term___match) elaborator is capable of synthesizing an appropriate motive, and the refinement of types that occurs during pattern matching is a result of the motive that was selected. In some specialized circumstances, a different motive may be needed and may be provided explicitly using the `(motive := …)` syntax of [`match`](index.md#Lean___Parser___Term___match). This motive should be a function type that expects at least as many parameters as there are discriminants. The type that results from applying a function with this type to the discriminants in order is the type of the entire [`match`](index.md#Lean___Parser___Term___match) term, and the type that results from applying a function with this type to all patterns in each alternative is the type of that alternative's [right-hand side](index.md#--tech-term-right-hand-side).

<a id="Matching-with-an-Explicit-Motive"></a>
Matching with an Explicit Motive 

An explicit motive can be used to provide type information that is otherwise unavailable from the surrounding context. Attempting to match on a number and a proof that it is in fact `5` is an error, because there's no reason to connect the number to the proof:

```proofscript
#eval
  match 5, rfl with
  | 5, rfl => "ok"
```

```lean
Invalid match expression: This pattern contains metavariables:
  Eq.refl ?m.14
```

An explicit motive explains the relationship between the discriminants:

```proofscript
#eval
  match (motive := (n : Nat) → n = 5 → String) 5, rfl with
  | 5, rfl => "ok"
```

```lean
"ok"
```

<a id="The-Lean-Language-Reference--Terms--Pattern-Matching--Types--Discriminant-Refinement"></a>
#### 13.8.1.3. Discriminant Refinement

When matching on an indexed family, the indices must also be discriminants. Otherwise, the pattern would not be well typed: it is a type error if an index is just a variable but the type of a constructor requires a more specific value. However, a process called 
<a id="--tech-term-discriminant-refinement"></a>
discriminant refinement automatically adds indices as additional discriminants.

<a id="Discriminant-Refinement"></a>
Discriminant Refinement 

In the definition of `f`, the equality proof is the only discriminant. However, equality is an indexed family, and the match is only valid when `n` is an additional discriminant.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="f-_LPAR_in-Discriminant-Refinement_RPAR_"></a>


```proofscript
function f (n : Nat) (p : n = 3) : String :=
  match p with
  | rfl => "ok"
```

Using `#print` demonstrates that the additional discriminant was added automatically.

```proofscript
#print f
```

```lean
def f : (n : Nat) → n = 3 → String :=
fun n p =>
  match 3, p with
  | .(n), ⋯ => "ok"
```

<a id="match-generalization"></a>
#### 13.8.1.4. Generalization

The pattern match elaborator automatically determines the motive by finding occurrences of the discriminants in the expected type, generalizing them in the types of subsequent discriminants so that the appropriate pattern can be substituted. Additionally, occurrences of the discriminants in the types of variables in the context are generalized and substituted by default. This latter behavior can be turned off by passing the `(generalizing := false)` flag to [`match`](index.md#Lean___Parser___Term___match).

<a id="Matching___-With-and-Without-Generalization"></a>
Matching, With and Without Generalization 

In this definition of `boolCases`, the assumption `b` is generalized in the type of `h` and then replaced with the actual pattern. This means that `ifTrue` and `ifFalse` have the types `true = true → α` and `false = false → α` in their respective cases, but `h`'s type mentions the original discriminant.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
function boolCases (b : Bool)
    (ifTrue : b = true → α)
    (ifFalse : b = false → α) :
    α :=
  match h : b with
  | true  => ifTrue h
  | false => ifFalse h
```

The error for the first case is typical of both:

```lean
Application type mismatch: The argument
  h
has type
  b = true
but is expected to have type
  true = true
in the application
  ifTrue h
```

Turning off generalization allows type checking to succeed, because `b` remains in the types of `ifTrue` and `ifFalse`.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
function boolCases (b : Bool)
    (ifTrue : b = true → α)
    (ifFalse : b = false → α) :
    α :=
  match (generalizing := false) h : b with
  | true  => ifTrue h
  | false => ifFalse h
```

In the generalized version, `rfl` could have been used as the proof arguments as an alternative.

<a id="match_pattern-functions"></a>
### 13.8.2. Custom Pattern Functions

In patterns, defined constants with the `match_pattern` attribute are unfolded and normalized rather than rejected. This allows a more convenient syntax to be used for many patterns. In the standard library, `Nat.add`, `HAdd.hAdd`, `Add.add`, and `Neg.neg` all have this attribute, which allows patterns like `n + 1` instead of `Nat.succ n`. Similarly, `Unit` and `Unit.unit` are definitions that set the respective [universe parameters](../../The-Type-System/Universes/index.md#--tech-term-universe-parameters) of `PUnit` and `PUnit.unit` to 0; the `match_pattern` attribute on `Unit.unit` allows it to be used in patterns, where it expands to `PUnit.unit.{0}`.

<a id="attr-next-next-next-next-next-next-next-next-next"></a>

**attribute**

**Attribute for Match Patterns**

The `match_pattern` attribute indicates that a definition should be unfolded, rather than rejected, in a pattern.

<a id="Lean___Parser___Attr___simple-next-next-next-next-next-next-next"></a>

```ebnf
attr ::= ...
    | match_pattern
```

<a id="Match-Patterns-Follow-Reduction"></a>
Match Patterns Follow Reduction 

The following function can't be compiled:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="nonzero-_LPAR_in-Match-Patterns-Follow-Reduction_RPAR_"></a>


```proofscript
function nonzero (n : Nat) : Bool :=
  match n with
  | 0 => false
  | 1 + k => true
```

The error message on the pattern `1 + _` is:

```lean
Invalid pattern(s): `k` is an explicit pattern variable, but it only occurs in positions that are inaccessible to pattern matching:
  .(Nat.add 1 k)
```

This is because `Nat.add` is defined by recursion on its second parameter, equivalently to:
<a id="add-_LPAR_in-Match-Patterns-Follow-Reduction_RPAR_"></a>


```proofscript
def add : Nat → Nat → Nat
  | a, Nat.zero   => a
  | a, Nat.succ b => Nat.succ (Nat.add a b)
```

No [ι-reduction](../../The-Type-System/Inductive-Types/index.md#--tech-term-___-reduction) is possible, because the value being matched is a variable, not a constructor. `1 + k` gets stuck as `Nat.add 1 k`, which is not a valid pattern.

In the case of `k + 1`, that is, `Nat.add k (.succ .zero)`, the second pattern matches, so it reduces to `Nat.succ (Nat.add k .zero)`. The second pattern now matches, yielding `Nat.succ k`, which is a valid pattern.

<a id="pattern-fun"></a>
### 13.8.3. Pattern Matching Functions

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Pattern-Matching Functions**

Functions may be specified via pattern matching by writing a sequence of patterns after `fun`, each preceded by a vertical bar (`|`).

<a id="Lean___Parser___Term___fun-next-next-next-next-next"></a>

```ebnf
term ::= ...
    | fun
        (| term,* => term)*
```

This desugars to a function that immediately pattern-matches on its arguments.

<a id="Pattern-Matching-Functions"></a>
Pattern-Matching Functions 

`isZero` is defined using a pattern-matching function abstraction, while `isZero'` is defined using a pattern match expression:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="isZero-_LPAR_in-Pattern-Matching-Functions_RPAR_"></a>
<a id="isZero___-_LPAR_in-Pattern-Matching-Functions_RPAR_"></a>


```proofscript
const isZero : Nat → Bool :=
  fun
    | 0 => true
    | _ => false

const isZero' : Nat → Bool :=
  fun n =>
    match n with
    | 0 => true
    | _ => false
```

Because the former is syntactic sugar for the latter, they are definitionally equal:

```proofscript
example : isZero = isZero' := rfl
```

The desugaring is visible in the output of `#print`:

```proofscript
#print isZero
```

outputs

```lean
def isZero : Nat → Bool :=
fun x =>
  match x with
  | 0 => true
  | x => false
```

while

```proofscript
#print isZero'
```

outputs

```lean
def isZero' : Nat → Bool :=
fun n =>
  match n with
  | 0 => true
  | x => false
```

<a id="The-Lean-Language-Reference--Terms--Pattern-Matching--Other-Pattern-Matching-Operators"></a>
### 13.8.4. Other Pattern Matching Operators

In addition to [`match`](index.md#Lean___Parser___Term___match) and [`if let`](../Conditionals/index.md#termIfLet), there are a few other operators that perform pattern matching.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**The matches Operator**

The [`matches`](index.md#Lean____FLQQ_term_Matches_____FLQQ_) operator returns `true` if the term on the left matches the pattern on the right.

<a id="Lean____FLQQ_term_Matches_____FLQQ_"></a>

```ebnf
term ::= ...
    | term matches term
```

When branching on the result of [`matches`](index.md#Lean____FLQQ_term_Matches_____FLQQ_), it's usually better to use [`if let`](../Conditionals/index.md#termIfLet), which can bind pattern variables in addition to checking whether a pattern matches.

If there are no constructor patterns that could match a discriminant or sequence of discriminants, then the code in question is unreachable, as there must be a false assumption in the local context. The [`nomatch`](index.md#Lean___Parser___Term___nomatch) expression is a match with zero cases that can have any type whatsoever, so long as there are no possible cases that could match the discriminants.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Caseless Pattern Matches**

<a id="Lean___Parser___Term___nomatch"></a>

```ebnf
term ::= ...
    | nomatch term,*
```

<a id="Inconsistent-Indices"></a>
Inconsistent Indices 

There are no constructor patterns that can match both proofs in this example:

```proofscript
example (p1 : x = "Hello") (p2 : x = "world") : False :=
  nomatch p1, p2
```

This is because they separately refine the value of `x` to unequal strings. Thus, the [`nomatch`](index.md#Lean___Parser___Term___nomatch) operator allows the example's body to prove `False` (or any other proposition or type).

When the expected type is a function type, [`nofun`](index.md#Lean___Parser___Term___nofun) is shorthand for a function that takes as many parameters as the type indicates in which the body is [`nomatch`](index.md#Lean___Parser___Term___nomatch) applied to all of the parameters.

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Caseless Functions**

<a id="Lean___Parser___Term___nofun"></a>

```ebnf
term ::= ...
    | nofun
```

<a id="Impossible-Functions"></a>
Impossible Functions 

Instead of introducing arguments for both equality proofs and then using both in a [`nomatch`](index.md#Lean___Parser___Term___nomatch), it is possible to use [`nofun`](index.md#Lean___Parser___Term___nofun).

```proofscript
example : x = "Hello" → x = "world" → False := nofun
```

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


````text
Pattern matching. `match e, ... with | p, ... => f | ...` matches each given
term `e` against each pattern `p` of a match alternative. When all patterns
of an alternative match, the `match` term evaluates to the value of the
corresponding right-hand side `f` with the pattern variables bound to the
respective matched values.
If used as `match h : e, ... with | p, ... => f | ...`, `h : e = p` is available
within `f`.

When not constructing a proof, `match` does not automatically substitute variables
matched on in dependent variables' types. Use `match (generalizing := true) ...` to
enforce this.

Syntax quotations can also be used in a pattern match.
This matches a `Syntax` value against quotations, pattern variables, or `_`.

Quoted identifiers only match identical identifiers - custom matching such as by the preresolved
names only should be done explicitly.

`Syntax.atom`s are ignored during matching by default except when part of a built-in literal.
For users introducing new atoms, we recommend wrapping them in dedicated syntax kinds if they
should participate in matching.
For example, in
```lean
syntax "c" ("foo" <|> "bar") ...
```
`foo` and `bar` are indistinguishable during matching, but in
```lean
syntax foo := "foo"
syntax "c" (foo <|> "bar") ...
```
they are not.
````


### Display 2


```text
`matchDiscr` matches a "match discriminant", either `h : tm` or `tm`, used in `match` as
`match h1 : e1, e2, h3 : e3 with ...`.
```


### Display 3


```text
`.(e)` marks an "inaccessible pattern", which does not influence evaluation of the pattern match, but may be necessary for type-checking.
In contrast to regular patterns, `e` may be an arbitrary term of the appropriate type.
```


### Display 4


```text
`x@e` or `x@h:e` matches the pattern `e` and binds its value to the identifier `x`.
If present, the identifier `h` is bound to a proof of `x = e`.
```


### Display 5


```text
Empty match/ex falso. `nomatch e` is of arbitrary type `α : Sort u` if
Lean can show that an empty set of patterns is exhaustive given `e`'s type,
e.g. because it has no constructors.
```


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
don't know how to synthesize placeholder
context:
α:Type ux:αdepth:Nat⊢ BalancedTree α depth
```


### Display 2


```text
don't know how to synthesize placeholder
context:
α:Type ux:αdepth:Nat⊢ BalancedTree α 0
```


### Display 3


```text
don't know how to synthesize placeholder
context:
α:Type ux:αdepth n:Nat⊢ BalancedTree α (n + 1)
```


### Display 4


```text
Type mismatch
  left.branch val right
has type
  BalancedTree ?m.13 (?m.12 + 1)
but is expected to have type
  BalancedTree α 0
```


### Display 5


```text
simp_all made no progress
```


### Display 6


```text
Invalid match expression: This pattern contains metavariables:
  Eq.refl ?m.14
```


### Display 7


```text
"ok"
```


### Display 8


```text
def f : (n : Nat) → n = 3 → String :=
fun n p =>
  match 3, p with
  | .(n), ⋯ => "ok"
```


### Display 9


```text
Application type mismatch: The argument
  h
has type
  b = true
but is expected to have type
  true = true
in the application
  ifTrue h
```


### Display 10


```text
Application type mismatch: The argument
  h
has type
  b = false
but is expected to have type
  false = false
in the application
  ifFalse h
```


### Display 11


```text
Invalid pattern(s): `k` is an explicit pattern variable, but it only occurs in positions that are inaccessible to pattern matching:
  .(Nat.add 1 k)
```


### Display 12


```text
def isZero : Nat → Bool :=
fun x =>
  match x with
  | 0 => true
  | x => false
```


### Display 13


```text
def isZero' : Nat → Bool :=
fun n =>
  match n with
  | 0 => true
  | x => false
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
n:Nath:Nat⊢ h + 1 + (h + 1) = h + h + 1 + 1
```


### Display 2


```text
All goals completed! 🐙
```


### Display 3


```text
α:Type ?u.3xs:List αhead✝:αtail✝:List αh:xs = head✝ :: tail✝h':xs = []⊢ False
```


### Display 4


```text
α:Type ?u.3xs:List αhead✝:αtail✝:List αh':xs = []⊢ False
```

