<a id="do-elab"></a>

# ProofScript — 23.7. Extending do-Notation

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Use native notation, syntax categories, quotations, macros and elaborators in an explicitly declared extension environment. Macro hygiene preserves binding identity; a convenient generated name is not enough. Quoted parser code remains native code rather than being rewritten as ordinary surface expressions. Extensions produce syntax or candidate declarations and gain no independent proof authority.

**Compiler and coverage boundary.** Register collisions and lifted child slots explicitly. Do not globally rewrite strings, quoted grammar, tactic combinators or host code. Plugin operating-system permissions are separate from logical soundness.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Notations-and-Macros/Extending--do--Notation/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Notations-and-Macros/Extending--do--Notation/index.html). Source Git blob: `7f91e73909212f8e9f8e7450f2031ecb25374407`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 23.7. Extending do-Notation

Macros and elaborators can be used to extend Lean with new commands and terms. In addition, [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-notation can be extended. Extensions to [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-notation define new kinds of [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-elements. Macros translate the new [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-elements into previously existing [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-elements, while elaborators have access to more information and can produce arbitrary terms in Lean's type theory.

This chapter describes the extension mechanisms that are available for [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-notation. Extensible [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-notation was introduced in Lean version 4.29.0; prior to this release, it was not extensible. The extensible [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do) elaborator is controlled by the option `backward.do.legacy`, which defaults to `false`:

<a id="backward___do___legacy"></a>

**option**

```text
backward.do.legacy
```

Default value: `false`

Use the legacy `do` elaborator instead of the new, extensible implementation.

When `backward.do.legacy` is `false`, the extensible elaborator is enabled. Custom [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-element elaborators extend the desugaring described in [the section on syntax for monads](../../Functors___-Monads-and--do--Notation/Syntax/index.md#do-notation).

<a id="The-Lean-Language-Reference--Notations-and-Macros--Extending--do--Notation--Elaboration-Overview"></a>
### 23.7.1. Elaboration Overview

The [syntax kind](../Defining-New-Syntax/index.md#--tech-term-syntax-kind) `doElem` represents individual [`do`-elements](../../Functors___-Monads-and--do--Notation/Syntax/index.md#--tech-term-do-elements). A sequence of these elements is represented by the syntax kind `doSeq`, which makes up the body of a [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-block. The elaborator for [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do) invokes a specialized elaboration framework on the `doSeq` in its body, elaborating each `doElem` in turn. This specialized framework allows each element in the sequence to modify the elaboration of subsequent elements, as well as to track information such as enclosing loops (for `break` and `continue`), the way to escape via `return`, and the set of mutable variables.

Elaboration of [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-elements is very similar to that of terms. First, if the syntax in question is a [macro](../Macros/index.md#--tech-term-Macros), then it is expanded. This is repeated until the result of macro expansion is no longer a macro. Next, an internal table is consulted to find the elaboration procedure associated with the [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-element's syntax kind. This table is separate from the table of term elaborators, because [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-element elaborators have a different type. If a [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-element consists only of a term, then the Lean parser wraps it in the syntax kind `doExpr`; its elaborator invokes the term elaborator, ensuring that the term has the correct type for the [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-block.

<a id="The-Lean-Language-Reference--Notations-and-Macros--Extending--do--Notation--Macros-in--do--Notation"></a>
### 23.7.2. Macros in do-Notation

Macro expansion occurs during the elaboration of [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-elements. There is no fundamental difference between [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-element macros and term or command macros; they are distinguished by being defined for syntax that is part of the `doElem` syntax category.

<a id="Multi-Way--if"></a>
Multi-Way `if` 

As an alternative to a nested sequence of `if`-terms, this “multi-way `if`” places each condition at the same syntactic level:
<a id="multiIfTerm-_LPAR_in-Multi-Way--if_RPAR_"></a>


```proofscript
syntax (name := multiIfTerm)
  "if " withPosition(
    (colGe atomic("|" (atomic(ident " : "))? term) " => " term)+
    colGe "|" " else " " => " term
  ) : term
```

It is [indentation-sensitive](../Defining-New-Syntax/index.md#syntax-indentation). It can be implemented as a recursive macro that emits the expected nested `if`:
<a id="mkTermIf-_LPAR_in-Multi-Way--if_RPAR_"></a>


```proofscript
def mkTermIf (h? : Option Ident) (g b e : Term) : MacroM Term :=
  match h? with
  | some h => `(if $h:ident : $g then $b else $e)
  | none => `(if $g then $b else $e)

macro_rules
  | `(if | $[$h?:ident :]? $g:term => $b:term | else => $e:term) =>
      mkTermIf h? g b e
  | `(if | $[$h?:ident :]? $g:term => $b:term
         | $[$h2?:ident :]? $g2:term => $b2:term
         $[| $[$hs?:ident :]? $gs:term => $bs:term]*
         | else => $e:term) => do
      mkTermIf h? g b
        (← `(if | $[$h2?:ident :]? $g2 => $b2
                $[| $[$hs?:ident :]? $gs => $bs]*
                | else => $e))
```

It can be used like any other term:

```proofscript
#eval
  let sign : Int → String := fun n =>
    if
      | n < 0 => "neg"
      | n = 0 => "zero"
      | else => "pos"
  (sign (-2), sign 0, sign 5)
```

```lean
("neg", "zero", "pos")
```

This macro can be adapted to be a [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-element by placing it in the `doElem` syntax category and replacing each arm of the multi-way `if` with a `doSeq` instead of a `Term`. The syntax definition is almost the same; however, the `else` branch is optional:
<a id="multiIf-_LPAR_in-Multi-Way--if_RPAR_"></a>


```proofscript
syntax (name := multiIf)
  "if " withPosition(
    (colGe atomic("|" (atomic(ident " : "))? term) " => " doSeq)+
    (colGe "|" " else " " => " doSeq)?
  ) : doElem
```

Likewise, a helper function to attach the optional condition hypothesis name to `if` is useful:
<a id="mkDoIf-_LPAR_in-Multi-Way--if_RPAR_"></a>


```proofscript
def mkDoIf (h? : Option Ident) (g : Term) (b : TSyntax ``doSeq)
    (els? : Option (TSyntax ``doSeq)) : MacroM (TSyntax `doElem) :=
  match h? with
  | some h =>
    `(doElem| if $h : $g then $b $[else $els?]?)
  | none =>
    `(doElem| if $g then $b $[else $els?]?)
```

The implementation as a recursive macro is also nearly the same:

```proofscript
macro_rules
  | `(doElem| if | $[$h?:ident :]? $g:term => $b:doSeq
                   $[| else => $e:doSeq]?) =>
      mkDoIf h? g b e
  | `(doElem| if | $[$h?:ident :]? $g:term => $b:doSeq
                 | $[$h2?:ident :]? $g2:term => $b2:doSeq
                 $[| $[$hs?:ident :]? $gs:term => $bs:doSeq]*
                 $[| else => $e:doSeq]?) => do
      mkDoIf h? g b <| some
        (← `(doSeq| if | $[$h2?:ident :]? $g2 => $b2
                       $[| $[$hs?:ident :]? $gs => $bs]*
                       $[| else => $e]?))
```

It can be used in [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do):

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="getEven-_LPAR_in-Multi-Way--if_RPAR_"></a>


```proofscript
const getEven : IO { n : Nat // n % 2 = 0 ∨ n % 3 = 0} := do
  let n ← (← IO.getStdin).getLine
  let some n := n.toNat?
    | throw <| IO.userError s!"Not a Nat: {n}"
  if
    | h : n % 2 = 0 =>
      IO.println s!"{n} is even."
      return ⟨n, .inl h⟩
    | h : n % 3 = 0 =>
      IO.println s!"{n} is divisible by 3."
      return ⟨n, .inr h⟩
    | else =>
      throw <| IO.userError s!"Invalid input {n}"
```

<a id="The-Lean-Language-Reference--Notations-and-Macros--Extending--do--Notation--Macros-in--do--Notation--Limitations"></a>
#### 23.7.2.1. Limitations

When an extension can be implemented as a macro, it is usually best to do so. Macros are much simpler to maintain, and they inherit bug fixes from the implementation of the syntax that they expand to. However, macros cannot implement all possible extensions:

- They cannot access information about the set of mutable variables, nor can they override it.
- They cannot implement novel control structures that are not expressible in terms of built-in control structures.
- They cannot place a [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-sequence into some new context (such as underneath a binder) while keeping it as part of the enclosing [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-block for the purposes of early return and mutable variables.

In these cases, it may be necessary to define an elaborator.

<a id="Freezing-Mutable-Variables-with-a-Macro"></a>
Freezing Mutable Variables with a Macro 

Within a [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do) block, new `let` bindings may not shadow existing `let mut` bindings. However, many mutable variables are not modified after they are initialized. It might be convenient to indicate this fact by removing their mutability.

There is no existing way to replace a mutable variable with an immutable one, so this feature can't be implemented with a macro that expands to an existing [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-element which makes the variable immutable for the remainder of the block. However, the operator can be structured so that it introduces a scope in which the mutable variable is immutable by expanding to a function call:

```proofscript
macro "freeze " x:ident " in " body:doSeq : doElem =>
  `(doElem| (fun $x => do $body) $x)
```

While it may seem promising, this macro-based solution has severe drawbacks. First, the body of the resulting function constitutes a new [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-block. This means that mutable variables in the surrounding block cannot be modified:

```proofscript
#eval Id.run do
  let mut x : Nat := 0
  x := x + 1
  let mut y := 0
  freeze x in
    y := 2 * x
  return y
```

```lean
Variable `y` cannot be mutated. Only variables declared using `let mut` can be mutated.
      If you did not intend to mutate but define `y`, consider using `let y` instead
```

Additionally, an early `return` exits the inner [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do), rather than the surrounding one, as indicated by the fact that it is expected to return a `Unit` (in this case, the universe-polymorphic `PUnit`):

```proofscript
#eval Id.run do
  let mut x : Nat := 0
  x := x + 1
  let mut y := 0
  freeze x in
    return x
  return y
```

```lean
Type mismatch
  x
has type
  Nat
but is expected to have type
  PUnit
```

<a id="The-Lean-Language-Reference--Notations-and-Macros--Extending--do--Notation--Elaboration"></a>
### 23.7.3. Elaboration

Elaboration of [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-elements occurs in the `DoElabM` monad. This monad is a wrapper around `TermElabM` that provides one extra [reader](../../Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#reader-monad) value: a [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-elaboration context. The elaborators also receive an additional argument: a description of the elaboration 
<a id="--tech-term-continuation"></a>
*continuation*. The continuation represents the remainder of the [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-block, after the current element; it includes both a `DoElabM` action that will elaborate the remainder of the block and the name by which that term will refer to the result of the current elaboration step. Unlike term elaborators, which return the elaborated term to a surrounding elaboration context, [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-element elaborators invoke the provided continuation to arrange for the elaboration of the rest of the [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-block.

<a id="Lean___Elab___Do___Context___mk"></a>

**structure**

```text
Lean.Elab.Do.Context : Type
```

**Constructor**

```text
Lean.Elab.Do.Context.mk
```

**Fields**

```text
monadInfo : Elab.Do.MonadInfo
```

Inferred and cached information about the monad.

```text
mutVars : Array Elab.Do.MutVar
```

The mutable variables in declaration order. Kept in sync with `mutVarDefs`; insertions go through `declareMutVar` / `declareMutVars` only.

```text
mutVarDefs : Std.HashMap Name Elab.Do.MutVar
```

Maps mutable variable names to their `MutVar` record. Kept in sync with `mutVars`.

```text
doBlockResultType : Expr
```

The expected type of the current `do` block. This can be different from `ReturnCont.resultType` in `for` loop `do` blocks, for example.

```text
contInfo : Elab.Do.ContInfoRef
```

Information about `return`, `break` and `continue` continuations.

```text
deadCode : Elab.Do.CodeLiveness
```

Whether the current `do` element is dead code. `elabDoElem` will emit a warning if not `.alive`.

```text
ops : Elab.Do.DoOpsRef
```

Pluggable builders for `pure` and `bind` applications.

<a id="Lean___Elab___Do___MonadInfo___mk"></a>

**structure**

```text
Lean.Elab.Do.MonadInfo : Type
```

**Constructor**

```text
Lean.Elab.Do.MonadInfo.mk
```

**Fields**

```text
m : Expr
```

The inferred type of the monad of type `Type u → Type v`.

```text
u : Level
```

The `u` in `m : Type u → Type v`.

```text
v : Level
```

The `v` in `m : Type u → Type v`.

```text
cachedPUnit : Expr
```

The cached `PUnit` expression.

```text
cachedPUnitUnit : Expr
```

The cached `PUnit.unit` expression.

<a id="Lean___Elab___Do___CodeLiveness___deadSyntactically"></a>

**inductive type**

```text
Lean.Elab.Do.CodeLiveness : Type
```

Whether a code block is alive or dead.

**Constructors**

```text
Lean.Elab.Do.CodeLiveness.deadSyntactically :
  Elab.Do.CodeLiveness
```

We inferred the code is syntactically dead and don't need to elaborate it at all.

```text
Lean.Elab.Do.CodeLiveness.deadSemantically :
  Elab.Do.CodeLiveness
```

We inferred the code is semantically dead, but we need to elaborate it to produce a program.

```text
Lean.Elab.Do.CodeLiveness.alive : Elab.Do.CodeLiveness
```

The code is alive. (Or it is dead, but we failed to prove it so.)

To avoid circularity in the implementation, the `Context.contInfo` and `Context.ops` fields are references that are filled in after construction. Use `ContInfoRef.toContInfo` and `DoOpsRef.toDoOps` to recover the underlying data:

<a id="Lean___Elab___Do___ContInfoRef___toContInfo"></a>

**opaque**

```text
Lean.Elab.Do.ContInfoRef.toContInfo (m : Elab.Do.ContInfoRef) :
  Elab.Do.ContInfo
```

<a id="Lean___Elab___Do___ContInfo___mk"></a>

**structure**

```text
Lean.Elab.Do.ContInfo : Type
```

Information about a success, `return`, `break` or `continue` continuation that will be filled in after the code using it has been elaborated.

**Constructor**

```text
Lean.Elab.Do.ContInfo.mk
```

**Fields**

```text
returnCont : Elab.Do.ReturnCont
```

```text
breakCont : Option (Elab.Do.DoElabM Expr)
```

```text
continueCont : Option (Elab.Do.DoElabM Expr)
```

<a id="Lean___Elab___Do___DoOpsRef___toDoOps"></a>

**opaque**

```text
Lean.Elab.Do.DoOpsRef.toDoOps (r : Elab.Do.DoOpsRef) : Elab.Do.DoOps
```

<a id="Lean___Elab___Do___DoOps___mk"></a>

**structure**

```text
Lean.Elab.Do.DoOps : Type
```

Pluggable builders for the `pure` / `bind` applications emitted by the `do` elaborator.

**Constructor**

```text
Lean.Elab.Do.DoOps.mk
```

**Fields**

```text
mkPureApp : Expr → Expr → Elab.Do.DoElabM Expr
```

Build `pure (α:=α) e : m α`.

```text
mkBindApp : Expr → Expr → Expr → Expr → Elab.Do.DoElabM Expr
```

Build `bind (α:=α) (β:=β) e k : m β`.

```text
isPureApp? : Expr → Option Expr
```

If `e` is syntactically a `pure …` application, return the pure value; otherwise `none`. Used by `DoElemCont.mkBindUnlessPure` to contract `e >>= pure` to `e` and `pure e >>= k` to `let x := e; k x`.

```text
splitMonadApp? : Expr → Elab.TermElabM (Option (Elab.Do.MonadInfo × Expr))
```

Match a monad application `m α`, returning `MonadInfo` for `m` and `α`.

```text
mkMonadApp : Expr → Elab.Do.DoElabM Expr
```

Construct `m α` from `α`.

Elaborators are associated with syntax kinds using the `doElem_elab` attribute. They should have type `DoElab`. In addition to an elaborator, each custom [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-element that's implemented via an elaborator must be provided with [control information](index.md#do-elab-control-info).

<a id="Lean___Elab___Do___DoElab"></a>

**def**

```text
Lean.Elab.Do.DoElab : Type
```

The type of elaborators for `do` block elements.

It is ``elabTerm `(do $e; $rest) = elabDoElem e dec``, where `elabDoElem e ·` is the elaborator for `do` element `e`, and `dec` is the `DoElemCont` describing the elaboration of the rest of the block `rest`.

<a id="attr-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**attribute**

**Do Element Elaborators**

<a id="Lean___Parser___Attr___simple-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
attr ::= ...
    | doElem_elab
```

Registers a `do` element elaborator for the given syntax node kind.

A `do` element elaborator should have type `DoElab` (which is `Lean.Syntax → DoElemCont → DoElabM Expr`), i.e. should take syntax of the given syntax node kind and a `DoElemCont` as parameters and produce an expression.

When elaborating a `do` block `do e; rest`, the elaborator for `e` is invoked with the syntax of `e` and the `DoElemCont` representing `rest`.

The `elab_rules` and `elab` commands should usually be preferred over using this attribute directly.

Additionally, [`elab_rules`](../Elaborators/index.md#Lean___Parser___Command___elab_rules) can be used to simultaneously define an elaborator and associate it with syntax. Just as `elab_rules : term <= ty` binds the expected type to `ty`, `elab_rules : doElem <= dec` binds the continuation to `dec`.

Just as term elaborators may recursively invoke elaboration on their sub-terms by calling functions such as `elabTerm`, [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-element elaborators may elaborate nested [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-elements or sequences of [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-elements. To elaborate a single [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-element, call `elabDoElem`. To elaborate a non-empty array of [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-elements, call `elabDoElems1`. To elaborate a sequence of [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-elements, call `elabDoSeq`.

<a id="Lean___Elab___Do___elabDoElem"></a>

**opaque**

```text
Lean.Elab.Do.elabDoElem (stx : DoElem) (cont : Elab.Do.DoElemCont)
  (catchExPostpone : Bool := true) : Elab.Do.DoElabM Expr
```

<a id="Lean___Elab___Do___elabDoSeq"></a>

**opaque**

```text
Lean.Elab.Do.elabDoSeq (doSeq : DoSeq) (cont : Elab.Do.DoElemCont)
  (catchExPostpone : Bool := true) : Elab.Do.DoElabM Expr
```

<a id="Lean___Elab___Do___elabDoElems1"></a>

**opaque**

```text
Lean.Elab.Do.elabDoElems1 (doElems : Array DoElem)
  (cont : Elab.Do.DoElemCont) (catchExPostpone : Bool := true) :
  Elab.Do.DoElabM Expr
```

<a id="The-Lean-Language-Reference--Notations-and-Macros--Extending--do--Notation--Elaboration--Monad-Operations"></a>
#### 23.7.3.1. Monad Operations

The elaboration framework provides several helpers that make it more convenient and efficient to construct applications of the current monad and its operations.

<a id="Lean___Elab___Do___mkMonadApp"></a>

**def**

```text
Lean.Elab.Do.mkMonadApp (resultType : Expr) : Elab.Do.DoElabM Expr
```

Constructs `m α` from `α`.

<a id="Lean___Elab___Do___mkPureApp"></a>

**def**

```text
Lean.Elab.Do.mkPureApp (α e : Expr) : Elab.Do.DoElabM Expr
```

The expression `pure (α:=α) e`.

<a id="Lean___Elab___Do___mkBindApp"></a>

**def**

```text
Lean.Elab.Do.mkBindApp (α β e k : Expr) : Elab.Do.DoElabM Expr
```

The expression `Bind.bind (α:=α) (β:=β) e k`.

<a id="Lean___Elab___Do___mkPUnitUnit"></a>

**def**

```text
Lean.Elab.Do.mkPUnitUnit : Elab.Do.DoElabM Expr
```

The cached `PUnit.unit` expression.

<a id="The-Lean-Language-Reference--Notations-and-Macros--Extending--do--Notation--Elaboration--Continuations"></a>
#### 23.7.3.2. Continuations

A [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-elaboration continuation consists of an elaborator that is waiting for the result of the present element together with metadata such as the type that this result is expected to have.

<a id="Lean___Elab___Do___DoElemCont___mk"></a>

**structure**

```text
Lean.Elab.Do.DoElemCont : Type
```

Elaboration of a `do` block `do $e; $rest`, results in a call ``elabTerm `(do $e; $rest) = elabDoElem e dec``, where `elabDoElem e ·` is the elaborator for `do` element `e`, and `dec` is the `DoElemCont` describing the elaboration of the rest of the block `rest`.

If the semantics of `e` resumes its continuation `rest`, its elaborator must bind its result to `resultName`, ensure that it has type `resultType` and then elaborate `rest` using `dec`.

Clearly, for term elements `e : m α`, the result has type `α`. More subtly, for binding elements `let x := e` or `let x ← e`, the result has type `PUnit` and is unrelated to the type of the bound variable `x`.

Examples:

- `return` drops the continuation; `return x; pure ()` elaborates to `pure x`.
- `let x ← e; rest x` elaborates to `e >>= fun x => rest x`.
- `let x := 3; let y ← (let x ← e); rest x` elaborates to `let x := 3; e >>= fun x_1 => let y := (); rest x`, which is immediately zeta-reduced to `let x := 3; e >>= fun x_1 => rest x`.
- `one; two` elaborates to `one >>= fun (_ : PUnit) => two`; it is an error if `one` does not have type `PUnit`.

**Constructor**

```text
Lean.Elab.Do.DoElemCont.mk
```

**Fields**

```text
resultName : Name
```

The name of the monadic result variable.

```text
resultType : Expr
```

The type of the monadic result.

```text
k : Elab.Do.DoElabM Expr
```

The continuation to elaborate the `rest` of the block. It assumes that the result of the `do` block is bound to `resultName` with the correct type (that is, `resultType`, potentially refined by a dependent `match`).

```text
kind : Elab.Do.DoElemContKind
```

Whether we are OK with generating the code of the continuation multiple times, e.g. in different branches of a `match` or `if`.

<a id="Lean___Elab___Do___DoElemContKind___nonDuplicable"></a>

**inductive type**

```text
Lean.Elab.Do.DoElemContKind : Type
```

Whether the continuation of a `do` element is duplicable. Saying `nonDuplicable` is always safe; `duplicable` allows for more optimizations.

**Constructors**

```text
Lean.Elab.Do.DoElemContKind.nonDuplicable :
  Elab.Do.DoElemContKind
```

```text
Lean.Elab.Do.DoElemContKind.duplicable :
  Elab.Do.DoElemContKind
```

Many elaborators require that the continuation is expecting a particular type for its result. It is very common, for example, for an elaborator to result in `Unit` if it returns no result. Checking the type at an earlier stage can result in better error messages:

<a id="Lean___Elab___Do___DoElemCont___ensureUnit"></a>

**def**

```text
Lean.Elab.Do.DoElemCont.ensureUnit (dec : Elab.Do.DoElemCont) :
  Elab.Do.DoElabM Elab.Do.DoElemCont
```

Given a continuation `dec`, returns a continuation derived from `dec` with result type `PUnit`. If `dec` already has result type `PUnit`, simply returns `dec`. Otherwise, an error is logged and a new continuation is returned that calls `dec` with `sorry` as a result.

<a id="Lean___Elab___Do___DoElemCont___ensureUnitAt"></a>

**def**

```text
Lean.Elab.Do.DoElemCont.ensureUnitAt (dec : Elab.Do.DoElemCont)
  (ref : Syntax) : Elab.Do.DoElabM Elab.Do.DoElemCont
```

Given a continuation `dec` and a reference `ref`, returns a continuation derived from `dec` with result type `PUnit`. If `dec` already has result type `PUnit`, simply returns `dec`. Otherwise, an error is logged and a new continuation is returned that calls `dec` with `sorry` as a result. The error is reported at `ref`.

<a id="Lean___Elab___Do___DoElemCont___ensureHasTypeAt"></a>

**def**

```text
Lean.Elab.Do.DoElemCont.ensureHasTypeAt (dec : Elab.Do.DoElemCont)
  (ref : Syntax) (elementType : Expr) :
  Elab.Do.DoElabM Elab.Do.DoElemCont
```

Given a continuation `dec`, a reference `ref`, and an element result type `elementType`, returns a continuation derived from `dec` with result type `elementType`. If `dec` already has result type `elementType`, simply returns `dec`. Otherwise, an error is logged and a new continuation is returned that calls `dec` with `sorry` as a result. The error is reported at `ref`.

Invoking a continuation consists of providing it with the result of the current [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-element. There are three primary ways of doing this. `DoElemCont.continueWithUnit` ensures that the continuation is expecting `Unit` and then invokes it. `DoElemCont.elabAsSyntacticallyDeadCode` invokes the continuation in a context that asserts that the code is unreachable, generally causing the continuation to generate no code and also warning users if there is code present. `DoElemCont.mkBindUnlessPure` is responsible for the standard desugaring of [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-notation into applications of `bind`; it is used to invoke a continuation after elaborating a [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-element that consists of a term with a monadic type, and it contains an optimization that replaces a `bind` around a `pure` with a `let`-binding.

<a id="Lean___Elab___Do___DoElemCont___continueWithUnit"></a>

**def**

```text
Lean.Elab.Do.DoElemCont.continueWithUnit (dec : Elab.Do.DoElemCont) :
  Elab.Do.DoElabM Expr
```

Return `let $k.resultName : PUnit := PUnit.unit; $(← k.k)`, ensuring that the result type of `k.k` is `PUnit` and then immediately zeta-reduce the `let`.

<a id="Lean___Elab___Do___DoElemCont___elabAsSyntacticallyDeadCode"></a>

**def**

```text
Lean.Elab.Do.DoElemCont.elabAsSyntacticallyDeadCode
  (dec : Elab.Do.DoElemCont) : Elab.Do.DoElabM Unit
```

Elaborate the `DoElemCont` with the `deadCode` flag set to `deadSyntactically` to emit warnings.

<a id="Lean___Elab___Do___DoElemCont___mkBindUnlessPure"></a>

**def**

```text
Lean.Elab.Do.DoElemCont.mkBindUnlessPure (dec : Elab.Do.DoElemCont)
  (e : Expr) : Elab.Do.DoElabM Expr
```

Return `$e >>= fun ($dec.resultName : $dec.resultType) => $(← dec.k)`, cancelling the bind if `$(← dec.k)` is `pure $dec.resultName` or `e` is some `pure` computation.

<a id="Invoking-Continuations"></a>
Invoking Continuations 

A version of the built-in syntax `skip`, which is equivalent to `pure ()`, can be implemented using an elaborator that immediately invokes its continuation with `Unit`. For better error messages, it also asserts that the continuation is expecting `Unit`.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="doNothing-_LPAR_in-Invoking-Continuations_RPAR_"></a>
<a id="elabDoNothing-_LPAR_in-Invoking-Continuations_RPAR_"></a>


```proofscript
syntax (name := doNothing) "nothing" : doElem

@[doElem_elab doNothing]
const elabDoNothing : DoElab := fun stx dec => do
  let dec ← dec.ensureUnitAt stx
  dec.continueWithUnit
```

In order to generate code for control structures, the [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-element elaboration framework requires information about side effects that might be performed by each element. This [control info](index.md#do-elab-control-info) is registered via the `doElem_control_info` attribute. Because `nothing` does not modify mutable variables, throw exceptions, terminate loops early, or perform any other action, its control info is `ControlInfo.pure`.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="doNothing___control-_LPAR_in-Invoking-Continuations_RPAR_"></a>


```proofscript
@[doElem_control_info doNothing]
const doNothing.control : ControlInfoHandler := fun _ => do return .pure
```

It is indeed equivalent to `pure ()`:

```proofscript
#eval show Option Unit from do nothing
```

```lean
some ()
```

<a id="Elaborating--do--elements-with--elab_rules"></a>
Elaborating `do`-elements with `elab_rules` 

An alternative version of `nothing`, which is equivalent to the built-in syntax `skip`, can be implemented using [`elab_rules`](../Elaborators/index.md#Lean___Parser___Command___elab_rules) as an alternative to an elaborator with the `doElem_elab` attribute.
<a id="doNothing-_LPAR_in-Elaborating--do--elements-with--elab_rules_RPAR_"></a>
<a id="doNothing___control-_LPAR_in-Elaborating--do--elements-with--elab_rules_RPAR_"></a>


```proofscript
syntax (name := doNothing) "nothing" : doElem

elab_rules : doElem <= dec
  | `(doElem|nothing%$tk) => do
    let dec ← dec.ensureUnitAt tk
    dec.continueWithUnit

@[doElem_control_info doNothing]
def doNothing.control : ControlInfoHandler := fun _ => do return .pure
```

It is equivalent to `pure ()`:

```proofscript
#eval show Option Unit from do nothing
```

```lean
some ()
```

Because the elaborator invokes its continuation explicitly, rather than simply returning a value, it can control the context of elaboration. In particular, it can use `withReader` to modify the context, and it can invoke the continuation multiple times in order to support control structures with branching. To prevent code size explosions, continuations track whether they may be elaborated multiple times in `DoElemCont.kind`. A continuation is 
<a id="--tech-term-duplicable"></a>
*duplicable* if it may be invoked multiple times, and 
<a id="--tech-term-nonduplicable"></a>
*nonduplicable* if not. Nonduplicable continuations can be transformed into duplicable continuations using `DoElemCont.withDuplicableCont`.

<a id="Lean___Elab___Do___DoElemCont___withDuplicableCont"></a>

**def**

```text
Lean.Elab.Do.DoElemCont.withDuplicableCont
  (nondupDec : Elab.Do.DoElemCont) (callerInfo : Elab.Do.ControlInfo)
  (caller : Elab.Do.DoElemCont → Elab.Do.DoElabM Expr) :
  Elab.Do.DoElabM Expr
```

Call `caller` with a duplicable proxy of `dec`. When the proxy is elaborated more than once, a join point is introduced so that `dec` is only elaborated once to fill in the RHS of this join point.

This is useful for control-flow constructs like `if` and `match`, where multiple tail-called branches share the continuation.

Unreachable code does not need to be elaborated. When a [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-element's elaborator has detected that the result of the continuation's elaboration is unreachable, it can return its resulting term directly instead of passing it to the elaboration continuation. It should produce a term that justifies abandoning the program, such as a call to `False.elim`. Before returning this term, it should invoke `DoElemCont.elabAsSyntacticallyDeadCode` on the continuation, which warns users that the code that the continuation would elaborate is unreachable.

<a id="Unreachable-Code"></a>
Unreachable Code 

The operator `absurd` marks code as unreachable when provided with a proof of `False`, which indicates that the current local context is logically inconsistent. If passed a proof, it uses it; otherwise, it attempts some automation.
<a id="doAbsurd-_LPAR_in-Unreachable-Code_RPAR_"></a>


```proofscript
syntax (name := doAbsurd) "absurd" (" by " tacticSeq)? : doElem
```

Because `absurd` can never return, and control can never proceed past it, its control information sets `numRegularExits` to `0` and `noFallthrough` to `true`:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="inferAbsurd-_LPAR_in-Unreachable-Code_RPAR_"></a>


```proofscript
@[doElem_control_info doAbsurd]
const inferAbsurd : ControlInfoHandler := fun _ =>
  return { numRegularExits := 0, noFallthrough := true }
```

The elaborator first extracts the proof syntax, falling back to a default if none is provided. It then elaborates the proof as a proof of false. If this succeeds, it marks the rest of the [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-sequence as dead code using `DoElemCont.elabAsSyntacticallyDeadCode` and uses `False.elim` as the resulting term, which it returns directly rather than to the continuation. `False.elim` is provided with the type that the term is expected to have, which is determined using `Lean.Elab.Do.mkMonadApp` together with the result type. It is important to use `Do.Context.doBlockResultType` rather than the continuation's result type because [effect lifting](index.md#do-elab-effect-lift) may have locally modified the type.
<a id="elabAbsurd-_LPAR_in-Unreachable-Code_RPAR_"></a>


```proofscript
@[doElem_elab doAbsurd]
def elabAbsurd : DoElab := fun stx dec => do
  let `(doElem| absurd $[by $tac?]?) := stx
    | throwUnsupportedSyntax
  let proofStx : Term ←
    if let some tac := tac? then
      `(by $tac)
    else
      `(by first | contradiction | grind)
  let proof ← elabTermEnsuringType proofStx (mkConst ``False)
  dec.elabAsSyntacticallyDeadCode
  let ty ← mkMonadApp (← read).doBlockResultType
  return (← Meta.mkAppOptM ``False.elim #[some ty, some proof])
```

`absurd` allows the accumulated information from the nested conditionals to rule out the `else` clause as unreachable:

```proofscript
#eval show Id (String × String × String) from do
  let classify : Nat → String := fun n => Id.run do
    if n < 3 then return "small"
    else if h1 : n < 10 then return "medium"
    else if h2 : n ≥ 10 then return "large"
    else absurd
  return (classify 1, classify 5, classify 99)
```

Due to the call to `DoElemCont.elabAsSyntacticallyDeadCode`, steps after `absurd` receive a dead code warning:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="xs-_LPAR_in-Unreachable-Code_RPAR_"></a>
<a id="xs_all_odd-_LPAR_in-Unreachable-Code_RPAR_"></a>


```proofscript
const xs := #[1, 3, 5]
theorem xs_all_odd : ∀ x, x ∈ xs → x % 2 = 1 := by
  simp [xs]

#eval show Id Nat from do
  for h : n in 0...5 do
    let k := n * 2
    if h' : k ∈ xs then
      absurd by grind [xs_all_odd]
      return k
  pure 100
```

```lean
This `do` element and its control-flow region are dead code. Consider removing it.
```

However, it does run successfully:

```lean
100
```

<a id="do-elab-return-continue-break"></a>
#### 23.7.3.3. Control Flow: return, break, and continue

Three non-local jump instructions are supported in [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-notation: `return`, which terminates the entire [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-block early; `break`, which terminates a loop early; and `continue`, which terminates a single iteration of a loop early. A `return` is always allowed, while `break` and `continue` are only valid inside the body of a loop. During elaboration, each of these three jumps is represented by a continuation.

<a id="Lean___Elab___Do___getReturnCont"></a>

**def**

```text
Lean.Elab.Do.getReturnCont : Elab.Do.DoElabM Elab.Do.ReturnCont
```

<a id="Lean___Elab___Do___getBreakCont"></a>

**def**

```text
Lean.Elab.Do.getBreakCont :
  Elab.Do.DoElabM (Option (Elab.Do.DoElabM Expr))
```

<a id="Lean___Elab___Do___getContinueCont"></a>

**def**

```text
Lean.Elab.Do.getContinueCont :
  Elab.Do.DoElabM (Option (Elab.Do.DoElabM Expr))
```

The three continuations are installed in the context using the helper `enterLoopBody`.

<a id="Lean___Elab___Do___enterLoopBody"></a>

**def**

```text
Lean.Elab.Do.enterLoopBody {α : Type}
  (breakCont continueCont : Elab.Do.DoElabM Expr)
  (returnCont : Elab.Do.ReturnCont) (body : Elab.Do.DoElabM α) :
  Elab.Do.DoElabM α
```

Prepare the context for elaborating the body of a loop. This includes setting the return continuation, break continuation, continue continuation, as well as the changed result type of the `do` block in the loop body.

<a id="Single-Iteration-Loop"></a>
Single-Iteration Loop 

The single-iteration loop `once` executes its body a single time, skipping to the end of the loop on `break` or `continue`:
<a id="doOnce-_LPAR_in-Single-Iteration-Loop_RPAR_"></a>


```proofscript
syntax (name := doOnce) "once " doSeq : doElem
```

Its control info is based on that of the body. A `once` never breaks or continues itself, because it handles `break` and `continue` in its body; thus, it sets `breaks` and `continues` to `false`. `numRegularExits` is the number of times that control can reach the code following the `once`. The body's normal fallthrough, `break`, and `continue` all transfer control to the end of the loop, so control leaves a `once` at most once. `numRegularExits` is therefore `1` when the body can exit in any of these ways and `0` otherwise, in which case `noFallthrough` is set.
<a id="inferOnce-_LPAR_in-Single-Iteration-Loop_RPAR_"></a>


```proofscript
@[doElem_control_info doOnce]
def inferOnce : ControlInfoHandler := fun stx => do
  let `(doElem| once $body) := stx | throwUnsupportedSyntax
  let bodyInfo ← InferControlInfo.ofSeq body
  let exits :=
    bodyInfo.numRegularExits > 0 ||
    bodyInfo.breaks ||
    bodyInfo.continues
  return { bodyInfo with
    breaks := false
    continues := false
    numRegularExits := if exits then 1 else 0
    noFallthrough := !exits
  }
```

The actual elaborator for `once` uses `enterLoopBody` to associate the elaborator's overall continuation with the `break` and `continue` continuations inside the body. Because the elaborated body can reach that continuation from several places, the elaborator counts these uses. The body's control info does not indicate how many times `break` and `continue` may be invoked, so they are approximated as two exits each, safely ensuring that the continuation will be duplicated if either is used. The total approximated use count is passed to `DoElemCont.withDuplicableCont`, which shares the continuation rather than duplicating it at each use when the use count is greater than one, and so avoids code explosion. It computes this count from the body directly, since the value reported by the control info handler is at most `1` and does not reflect the number of internal uses.
<a id="elabOnce-_LPAR_in-Single-Iteration-Loop_RPAR_"></a>


```proofscript
@[doElem_elab doOnce]
def elabOnce : DoElab := fun stx dec => do
  let `(doElem| once $body) := stx | throwUnsupportedSyntax
  let dec ← dec.ensureUnit
  let bodyInfo ← InferControlInfo.ofSeq body
  let numRegularExits :=
    bodyInfo.numRegularExits +
    (if bodyInfo.breaks then 2 else 0) +
    (if bodyInfo.continues then 2 else 0)
  dec.withDuplicableCont { bodyInfo with numRegularExits } fun dec => do
    let returnCont ← getReturnCont
    let exitCont := dec.continueWithUnit
    enterLoopBody exitCont exitCont returnCont do
      elabDoSeq body dec
```

`once` can be used to terminate some part of a computation without terminating the entire [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-block with `return`:

```proofscript
#eval show Id Nat from do
  let mut x := 0
  once
    x := x + 2
    if x % 2 = 0 then break
    x := 0
  return x
```

```lean
2
```

<a id="do-elab-control-info"></a>
#### 23.7.3.4. Control Information

In addition to an elaborator, custom [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-elements must provide 
<a id="--tech-term-control-information"></a>
*control information*. This describes how the custom element interacts with surrounding control structures and mutable variables. The control information allows Lean to generate appropriate code; in particular, it allows `DoElemCont.withDuplicableCont` to analyze the code to be elaborated by the continuation, which enables better code generation. Control information is separate from elaborators because an elaborator needs to be able to analyze the *syntax* of sub-elements before elaborating them in order to know how to structure its continuations. **Custom [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-elements must provide accurate control information. Incorrect control information can result in incorrect code generation.**

<a id="attr-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**attribute**

**Do Element Control Information**

<a id="Lean___Parser___Attr___simple-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
attr ::= ...
    | doElem_control_info
```

Registers a `ControlInfo` inference handler for the given `doElem` syntax node kind.

A handler should have type `ControlInfoHandler` (i.e. `DoElem → TermElabM ControlInfo`). For pure handlers, use `fun stx => return ControlInfo.pure`.

<a id="Lean___Elab___Do___ControlInfoHandler"></a>

**def**

```text
Lean.Elab.Do.ControlInfoHandler : Type
```

A handler for inferring `ControlInfo` from a `doElem` syntax. Register with `@[doElem_control_info parserName]`.

If a [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-element neither reassigns variables nor causes early return or termination, the handler can return `ControlInfo.pure`. If it represents code with no regular exits and no other control effects, then the handler can return `ControlInfo.empty`; otherwise, set `ControlInfo.numRegularExits` to `0` and `ControlInfo.noFallthrough` to `true` while also recording any early returns, reassignments, or loop terminations.

<a id="Lean___Elab___Do___ControlInfo___mk"></a>

**structure**

```text
Lean.Elab.Do.ControlInfo : Type
```

Represents information about what control effects a `do` block has.

The fields split by flavor:

- `breaks`, `continues`, `returnsEarly`, and `reassigns` are **syntactic**: `true`/non-empty iff the corresponding construct appears anywhere in the source text of the block, independent of whether it is semantically reachable. Downstream elaborators must assume every such syntactic effect may occur, because the elaborator visits every doElem (only top-level `return`/`break`/`continue` short-circuit via `elabAsSyntacticallyDeadCode`).
- `numRegularExits` is also **syntactic**: the number of times the block wires the enclosing continuation into its elaborated expression. `withDuplicableCont` reads it as a join-point duplication trigger (`> 1`).
- `noFallthrough = true` asserts that the next doElem in the enclosing sequence is semantically irrelevant (control never falls through to it). `noFallthrough = false` makes no such assertion. The dead-code warning fires on the next element when this is `true`.

Invariant: `numRegularExits = 0 → noFallthrough`. The converse does not hold.

**Constructor**

```text
Lean.Elab.Do.ControlInfo.mk
```

**Fields**

```text
breaks : Bool
```

The `do` block syntactically contains a `break`.

```text
continues : Bool
```

The `do` block syntactically contains a `continue`.

```text
returnsEarly : Bool
```

The `do` block syntactically contains an early `return`.

```text
numRegularExits : Nat
```

The number of times the block wires the enclosing continuation into its elaborated expression. Consumed by `withDuplicableCont` to decide whether to introduce a join point (`> 1`).

```text
noFallthrough : Bool
```

When `true`, asserts that the next doElem in the enclosing sequence is semantically irrelevant (control never falls through to it). `false` asserts nothing.

```text
reassigns : NameSet
```

The variables that are syntactically reassigned somewhere in the `do` block.

<a id="Lean___Elab___Do___ControlInfo___pure"></a>

**def**

```text
Lean.Elab.Do.ControlInfo.pure : Elab.Do.ControlInfo
```

The left identity of `ControlInfo.sequence`: a `ControlInfo` describing an element that always falls through normally with a single regular exit.

<a id="Lean___Elab___Do___ControlInfo___empty"></a>

**def**

```text
Lean.Elab.Do.ControlInfo.empty : Elab.Do.ControlInfo
```

The identity of `ControlInfo.alternative`: a `ControlInfo` describing a block with no branches at all (so no regular exits and the next element is trivially unreachable).

If a [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-element itself contains other [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-elements, then it can use the combinators `ControlInfo.sequence` and `ControlInfo.alternative` to combine the control information from their sub-elements. `ControlInfo.sequence` is used for sequential steps, and `ControlInfo.alternative` is used to merge control-flow branches.

<a id="Lean___Elab___Do___ControlInfo___sequence"></a>

**def**

```text
Lean.Elab.Do.ControlInfo.sequence (a b : Elab.Do.ControlInfo) :
  Elab.Do.ControlInfo
```

The `ControlInfo` of a sequence `a; b`: effect flags are unioned, the regular exits are those of `b`, and the sequence falls through iff both parts fall through.

<a id="Lean___Elab___Do___ControlInfo___alternative"></a>

**def**

```text
Lean.Elab.Do.ControlInfo.alternative (a b : Elab.Do.ControlInfo) :
  Elab.Do.ControlInfo
```

The `ControlInfo` of branches `a | b`: effect flags are unioned, the regular exits are summed, and the alternative falls through iff at least one branch falls through.

Generally speaking, control information should be computed using `inferControlInfoElem` or `inferControlInfoSeq`.

<a id="Lean___Elab___Do___inferControlInfoElem"></a>

**def**

```text
Lean.Elab.Do.inferControlInfoElem (doElem : DoElem) :
  Elab.TermElabM Elab.Do.ControlInfo
```

Infer the `ControlInfo` of a single doElem.

<a id="Lean___Elab___Do___inferControlInfoSeq"></a>

**def**

```text
Lean.Elab.Do.inferControlInfoSeq (doSeq : DoSeq) :
  Elab.TermElabM Elab.Do.ControlInfo
```

Infer the `ControlInfo` of `doSeq`.

In some advanced cases, one of the functions in `Lean.Elab.Do.InferControlInfo` may be necessary:

<a id="Lean___Elab___Do___InferControlInfo___ofElem"></a>

**opaque**

```text
Lean.Elab.Do.InferControlInfo.ofElem (stx : DoElem) :
  Elab.TermElabM Elab.Do.ControlInfo
```

<a id="Lean___Elab___Do___InferControlInfo___ofSeq"></a>

**opaque**

```text
Lean.Elab.Do.InferControlInfo.ofSeq (stx : DoSeq) :
  Elab.TermElabM Elab.Do.ControlInfo
```

<a id="Lean___Elab___Do___InferControlInfo___ofOptionSeq"></a>

**opaque**

```text
Lean.Elab.Do.InferControlInfo.ofOptionSeq (stx? : Option DoSeq) :
  Elab.TermElabM Elab.Do.ControlInfo
```

<a id="Lean___Elab___Do___InferControlInfo___ofLetOrReassign"></a>

**opaque**

```text
Lean.Elab.Do.InferControlInfo.ofLetOrReassign (reassigned : Array Ident)
  (rhs? : Option DoElem)
  (otherwise? body? : Option (TSyntax `Lean.Parser.Term.doSeqIndent)) :
  Elab.TermElabM Elab.Do.ControlInfo
```

<a id="Lean___Elab___Do___InferControlInfo___ofLetOrReassignArrow"></a>

**opaque**

```text
Lean.Elab.Do.InferControlInfo.ofLetOrReassignArrow (reassignment : Bool)
  (decl :
    TSyntax [`Lean.Parser.Term.doIdDecl, `Lean.Parser.Term.doPatDecl]) :
  Elab.TermElabM Elab.Do.ControlInfo
```

<a id="The-Lean-Language-Reference--Notations-and-Macros--Extending--do--Notation--Elaboration--Mutable-Variables"></a>
#### 23.7.3.5. Mutable Variables

<a id="Lean___Elab___Do___MutVar___mk"></a>

**structure**

```text
Lean.Elab.Do.MutVar : Type
```

A mutable variable declared by `let mut` in a `do` block.

**Constructor**

```text
Lean.Elab.Do.MutVar.mk
```

**Fields**

```text
ident : Ident
```

The identifier of the `let mut` declaration.

```text
baseId : FVarId
```

The `FVarId` of the initial binding produced by `let mut`.

Each mutable variable corresponds to at least one elaborated variable (`Expr.fvar`). These elaborated variables exist in a local context that tracks their user-visible names. Mutation is implemented via a shadowing `let`-binding, and subsequent steps in the [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-block are elaborated in a context in which this shadowing `let` is the binding for the variable's user-visible name. Use the standard elaboration helpers `Lean.Meta.getFVarFromUserName` and `Lean.Meta.getLocalDeclFromUserName` to retrieve the local variable associated with a user name, and `TSyntax.getId` to convert an `Ident` to a user name that can be looked up.

When a mutable variable is established with `let mut`, a `let`-binding is created to represent it, and the initial variable's binding identifier and `Expr.fvar` are added to the context that is used around the continuation, which is invoked under `withReader` to add the new variable. After establishing the `let`-binding, use `declareMutVar` to register one mutable variable or an array of them.

<a id="Lean___Elab___Do___declareMutVar"></a>

**def**

```text
Lean.Elab.Do.declareMutVar {α : Type} (x : Ident)
  (k : Elab.Do.DoElabM α) : Elab.Do.DoElabM α
```

Register the given name as that of a `mut` variable.

<a id="Lean___Elab___Do___declareMutVars"></a>

**def**

```text
Lean.Elab.Do.declareMutVars {α : Type} (xs : Array Ident)
  (k : Elab.Do.DoElabM α) : Elab.Do.DoElabM α
```

Register the given names as that of `mut` variables.

To ensure that an identifier refers to a mutable variable, use `throwUnlessMutVarDeclared`:

<a id="Lean___Elab___Do___throwUnlessMutVarDeclared"></a>

**def**

```text
Lean.Elab.Do.throwUnlessMutVarDeclared (x : Ident) :
  Elab.Do.DoElabM Unit
```

Throw an error if the given name is not a declared `mut` variable.

<a id="Lean___Elab___Do___throwUnlessMutVarsDeclared"></a>

**def**

```text
Lean.Elab.Do.throwUnlessMutVarsDeclared (xs : Array Ident) :
  Elab.Do.DoElabM Unit
```

Throw an error if the given names are not declared `mut` variables.

<a id="Tracing-Mutable-Variables"></a>
Tracing Mutable Variables 

The new syntax `dbg_mut` traces the current values of all mutable variables.
<a id="dbgMut-_LPAR_in-Tracing-Mutable-Variables_RPAR_"></a>
<a id="elabDbgMut-_LPAR_in-Tracing-Mutable-Variables_RPAR_"></a>


```proofscript
syntax (name := dbgMut) "dbg_mut" : doElem

@[doElem_elab dbgMut] def elabDbgMut : DoElab := fun _stx cont => do
  let ctx ← readThe Do.Context
  let parts : Array Term ← ctx.mutVars.mapM fun (x : MutVar) => do
    let nameLit := x.getId.simpMacroScopes.toString
    `(term| s!"{$(quote nameLit)} = {repr $(x.ident)}")
  let msg ← `(term| String.intercalate ", " [$parts,*])
  elabDoElem (← `(doElem| dbg_trace $msg)) cont
```

There is no interesting control information for `dbg_mut`.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="dbgMut___control-_LPAR_in-Tracing-Mutable-Variables_RPAR_"></a>


```proofscript
@[doElem_control_info dbgMut]
const dbgMut.control : ControlInfoHandler := fun _ => do return .pure
```

Tracing a loop that computes Fibonacci numbers shows all the intermediate states:

```proofscript
#eval show IO Unit from do
  let mut x := 1
  let mut y := 1
  for _ in 0...5 do
    let z := y
    dbg_mut
    y := x + y
    x := z
```

```lean
x = 1, y = 1
x = 1, y = 2
x = 2, y = 3
x = 3, y = 5
x = 5, y = 8
```

The built-in elaborators for mutable variables take care of many subtle details, such as registering each resulting `let`-binding of the mutable variable as aliases so that IDEs can give appropriate feedback. If at all possible, it is best to reuse these built-in elaborators, either via a macro or by invoking `elabDoElem` on the appropriate syntax.

<a id="Mutating-Variables"></a>
Mutating Variables 

The operator `censor` replaces all mutable variables with the default value defined in their type's `Inhabited` instance.
<a id="doCensor-_LPAR_in-Mutating-Variables_RPAR_"></a>
<a id="elabCensor-_LPAR_in-Mutating-Variables_RPAR_"></a>


```proofscript
syntax (name := doCensor) "censor" : doElem

@[doElem_elab doCensor]
def elabCensor : DoElab := fun stx dec => do
  let vars := (← readThe Do.Context).mutVars
  let dec ← dec.ensureUnitAt stx
  if h : vars.size = 0 then
    logErrorAt stx "There are no mutable variables to censor."
    dec.continueWithUnit
  else
    let assigns ← vars.mapM fun v =>
      `(doElem| $(v.ident):ident := Inhabited.default)
    elabDoElems1 assigns dec
```

The [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-elaboration context is not available in the control info handler, so there is no way to precisely return the set of all mutable variables as being modified. However, the user names of all local variables are a suitable overapproximation:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="doCensor___control-_LPAR_in-Mutating-Variables_RPAR_"></a>


```proofscript
@[doElem_control_info doCensor]
const doCensor.control : ControlInfoHandler := fun _ => do
  return { ControlInfo.pure with
      reassigns := (← getLCtx).decls.map (·.map (·.userName))
        |>.foldl (init := .empty) fun
          | names, some n => names.insert n
          | names, none => names
    }
```

After using `censor`, all mutable variables have been reset to their types' default values:

```proofscript
#eval show IO Unit from do
  let mut x := 0
  let mut c := 'm'
  x := x + 1
  IO.println s!"x: {x}, c: {c}"
  c := 'f'
  IO.println s!"x: {x}, c: {c}"
  censor
  IO.println s!"x: {x}, c: {c}"
```

```lean
x: 1, c: m
x: 1, c: f
x: 0, c: A
```

<a id="do-elab-effect-lift"></a>
#### 23.7.3.6. Lifting Effects

Many useful monadic operators take a function whose return type is within the monad, running this function in some modified way. Examples include `withReader`, `tryCatch`, and `IO.FS.withFile`. Functions like `tryCatch` have dedicated syntax that allows both the code that might throw an exception and the code that handles it to be part of the surrounding [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-block, and thus be able to, for example, reassign mutable variables or return early. These other operators have no such syntax.

A [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-element elaborator can arrange for the body of the function that is passed to one of these operators in the elaborated expression to be part of the source [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-block, just as the exception-handling syntax does. This is done using a `EffectForwarder`, which generates suitable wrapper code around both the inner sequence of [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-elements and the function itself. There are three steps:

1. A `EffectForwarder` for the inner sequence is created based on its control info and the current element's continuation, using `EffectForwarder.ofCont`.
2. The inner sequence is elaborated using `EffectForwarder.lift`, which supplies the inner elaborator with a suitable continuation that generates the wrapping code.
3. Instead of invoking the original continuation, the elaborator invokes a continuation generated by `EffectForwarder.restoreCont`, which adds suitable unwrapping code to the result.

The lifting code resembles the implementation of Lean's built-in [monad transformers](../../Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#monad-transformers). For example, if the inner [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-sequence mutates a variable, then the wrapping and unwrapping code arranges for the variable to be passed to the lifted code and returned in a tuple, just like `StateT`. If the inner [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-sequence could throw an exception, then the lifted version resembles a use of `ExceptT`.

<a id="Lean___Elab___Do___EffectForwarder___mk"></a>

**structure**

```text
Lean.Elab.Do.EffectForwarder : Type
```

Plan for embedding a non-tail-resumptive body inside `origCont` via a monad-transformer stack.

**Constructor**

```text
Lean.Elab.Do.EffectForwarder.mk
```

**Fields**

```text
origCont : Elab.Do.DoElemCont
```

Continuation of the surrounding `do` block; restored after the body.

```text
returnBase? : Option Elab.Do.ControlStack
```

Substack at which the early-return handler was installed, if any.

```text
breakBase? : Option Elab.Do.ControlStack
```

Substack at which the `break` handler was installed, if any.

```text
continueBase? : Option Elab.Do.ControlStack
```

Substack at which the `continue` handler was installed, if any.

```text
liftedStack : Elab.Do.ControlStack
```

The full transformer stack over the base monad.

```text
liftedDoBlockResultType : Expr
```

The body's elaboration type, `stM dec.resultType`.

<a id="Lean___Elab___Do___EffectForwarder___ofCont"></a>

**def**

```text
Lean.Elab.Do.EffectForwarder.ofCont (info : Elab.Do.ControlInfo)
  (dec : Elab.Do.DoElemCont) : Elab.Do.DoElabM Elab.Do.EffectForwarder
```

Build the lifter plan for a body whose effects are summarised by `info`.

<a id="Lean___Elab___Do___EffectForwarder___lift"></a>

**def**

```text
Lean.Elab.Do.EffectForwarder.lift (l : Elab.Do.EffectForwarder)
  (elabElem : Elab.Do.DoElemCont → Elab.Do.DoElabM Expr) :
  Elab.Do.DoElabM Expr
```

Elaborate `elabElem` in the lifted stack: install `break`/`continue`/`return` handlers funnelling into `liftedStack` and set the doBlock result type to `liftedDoBlockResultType`. Semantically `MonadControl.liftWith fun runInBase => elabElem (runInBase pure)`. Conts passed to `elabElem` are implicitly wrapped in `runInBase`, realised later by `ControlStack.mkBreak`/`mkContinue`/`mkReturn` once the transformer stack `t` is fixed by aggregating effects across *all* `lift` sites for this lifter.

<a id="Lean___Elab___Do___EffectForwarder___restoreCont"></a>

**def**

```text
Lean.Elab.Do.EffectForwarder.restoreCont (l : Elab.Do.EffectForwarder) :
  Elab.Do.DoElabM Elab.Do.DoElemCont
```

Build a `DoElemCont` that unpacks the lifted body's result and resumes `origCont.k`.

<a id="Syntax-for--withReader"></a>
Syntax for `withReader` 

In a [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-block, `locally` allows a sequence of [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-elements to be run with a modified `MonadReader` context:
<a id="doLocally-_LPAR_in-Syntax-for--withReader_RPAR_"></a>


```proofscript
syntax (name := doLocally)
  "locally " ident " => " termBeforeDo " do " doSeq : doElem
```

The `termBeforeDo` parser matches Lean terms that do not themselves contain [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do) outside of parentheses or brackets. Because this new syntax contains a sequence of [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-elements, its control info must be computed from these elements:
<a id="inferLocally-_LPAR_in-Syntax-for--withReader_RPAR_"></a>


```proofscript
@[doElem_control_info doLocally]
def inferLocally : ControlInfoHandler := fun stx => do
  let `(doElem| locally $_:ident => $_ do $seq) := stx
    | throwUnsupportedSyntax
  InferControlInfo.ofSeq seq
```

The actual elaborator starts by computing the control information for the body, and then derives a control lifter from the control information and the original continuation. This control lifter can elaborate the body; it provides its own continuation to the elaborator. Ordinary term elaboration techniques are used to construct the application of `withReader`, with special attention paid to ensuring that the function argument is elaborated with a non-dependent function type in the correct universe for the monad (which is available in `Context.monadInfo` as `MonadInfo.u`). Finally, the control lifter is used once again to reconstruct a suitable continuation for the full elaboration result:
<a id="elabDoLocally-_LPAR_in-Syntax-for--withReader_RPAR_"></a>


```proofscript
@[doElem_elab doLocally] def elabDoLocally : DoElab := fun stx dec => do
  let `(doElem| locally $x:ident => $e do $seq) := stx
    | throwUnsupportedSyntax
  let lifter ← EffectForwarder.ofCont (← inferControlInfoElem stx) dec
  let body ← lifter.lift (elabDoSeq seq)
  let ρ ← Meta.mkFreshExprMVar (mkSort (.succ (← read).monadInfo.u))
  let f ← Term.elabTermEnsuringType (← `(fun $x => $e)) (← mkArrow ρ ρ)
  Term.synthesizeSyntheticMVarsNoPostponing
  let wrapped ← Meta.mkAppM ``MonadWithReaderOf.withReader #[f, body]
  (← lifter.restoreCont).mkBindUnlessPure wrapped
```

With this elaborator in place, the value provided by a `ReaderT` can be locally overridden while still permitting effects that are tied to the surrounding [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-block:
<a id="App-_LPAR_in-Syntax-for--withReader_RPAR_"></a>


```proofscript
abbrev App := ReaderT Nat Id

#eval show Id Nat from do
  Id.run <| (·.run 5) <| show App Nat from do
    let mut total := 0
    total := total + (← read)
    locally r => r + 100 do
      -- Mutates an outer variable
      total := total + (← read)
      if (← read) > 1000 then
        -- Early return from the outer block
        return 999
    return total
```

```lean
110
```

<a id="Locally-Violating-Invariants"></a>
Locally Violating Invariants 

When some invariant of a mutable variable needs to be maintained, it is typically most convenient to use a subtype. However, subtypes have the drawback that the invariant must *always* be maintained; it cannot be broken locally and re-established. While it is possible to use a second mutable variable for this purpose, this clutters the code and is error-prone. With a suitable extension to [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-notation, local breaking and re-establishment of invariants can be made convenient.

The first step is to establish syntax for this operation. An `open mut` will “open” the subtype, freeing the contained data from the restrictions of the predicate in the nested block. After the block is complete, the user must either prove or check that the invariant holds; placing a [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do) block in the `invariant` section indicates that a dynamic check is to be performed. The second syntax definition has an explicit high priority to avoid ambiguity, which ensures that it is used whenever a [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do)-block is present.
<a id="openMutPure-_LPAR_in-Locally-Violating-Invariants_RPAR_"></a>
<a id="openMutMon-_LPAR_in-Locally-Violating-Invariants_RPAR_"></a>


```proofscript
syntax (name := openMutPure)
  "open" "mut" ident "do" doSeq "invariant" term : doElem

syntax (name := openMutMon) (priority := high)
  "open" "mut" ident "do" doSeq "invariant" "do" doSeq : doElem
```

The control info handlers for these operations are a function of the embedded `doSeq` syntax:
<a id="openMutInfo-_LPAR_in-Locally-Violating-Invariants_RPAR_"></a>


```proofscript
@[doElem_control_info openMutPure, doElem_control_info openMutMon]
def openMutInfo : ControlInfoHandler := fun
  | `(doElem|open mut $x do $steps invariant do $steps') => do
    let info ← inferControlInfoSeq steps
    let info' ← inferControlInfoSeq steps'
    return info.sequence info'
  | `(doElem|open mut $x do $steps invariant $tm:term) =>
    inferControlInfoSeq steps
  | _ => throwUnsupportedSyntax
```

The workhorse of the elaborator is a helper that does the following:

1. It ensures that the provided name in fact refers to a variable with a subtype, extracting the base type and predicate.
2. It extracts the inner value from the subtype.
3. It `let`-binds the inner value, establishing the `let`-bound variable as an alias and arranging for it to be mutable.
4. It elaborates the body with a continuation that invokes the provided elaborator that “closes” the subtype, re-establishing the invariant.
<a id="openMutBody-_LPAR_in-Locally-Violating-Invariants_RPAR_"></a>


```proofscript
def openMutBody (x : Ident) (seq : TSyntax ``doSeq)
    (mkClose : (p outerTy : Expr) → (base : FVarId) → DoElabM Expr) :
    DoElabM Expr := do
  -- Ensure that it is mutable
  throwUnlessMutVarDeclared x
  -- Ensure that it is a subtype
  let outerDecl ← getLocalDeclFromUserName x.getId
  let ty ← whnf outerDecl.type
  let (``Subtype, #[α, p]) := ty.getAppFnArgs
    | throwError "`open mut`: `{x}` is not a subtype, but is a `{ty}`"

  -- Get the value from the subtype
  let base := outerDecl.fvarId
  let init ← mkAppM ``Subtype.val #[outerDecl.toExpr]

  -- Let-bind and continue
  withLetDecl x.getId α init (nondep := false) fun innerX => do
    addLocalVarInfo x innerX
    pushInfoLeaf <| .ofFVarAliasInfo {
      userName := x.getId, id := innerX.fvarId!, baseId := base
    }
    let bodyCont : DoElemCont := {
      resultName := ← mkFreshUserName `__r, resultType := ← mkPUnit
      k := mkClose p outerDecl.type base
    }
    mkLetFVars #[innerX] (← declareMutVar x do elabDoSeq seq bodyCont)
```

The call to `addLocalVarInfo` informs the language server about the connection between the elaborated `let`-bound variable and the identifier in the source code, enabling features such as type information on hover. The `pushInfoLeaf` combined with `Info.ofFVarAliasInfo` registers the `let`-bound variable as an alias of existing bindings.

Closing the pure version consists of introducing a new `let`-binding, shadowing and aliasing the mutable variable, with the updated value and proof.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="rebindMut-_LPAR_in-Locally-Violating-Invariants_RPAR_"></a>


```proofscript
function rebindMut (x : Ident) (outerTy repacked : Expr) (base : FVarId)
    (dec : DoElemCont) : DoElabM Expr :=
  withLetDecl x.getId outerTy repacked (nondep := false) fun newX => do
    addLocalVarInfo x newX
    pushInfoLeaf <| .ofFVarAliasInfo {
      userName := x.getId, id := newX.fvarId!, baseId := base
    }
    mkLetFVars #[newX] (← dec.continueWithUnit)
```

The elaborator for the pure version connects the two pieces:
<a id="elabOpenMutPure-_LPAR_in-Locally-Violating-Invariants_RPAR_"></a>


```proofscript
@[doElem_elab openMutPure]
def elabOpenMutPure : DoElab := fun stx dec => do
  let `(doElem| open mut $x:ident do $seq invariant $prf:term) := stx
    | throwUnsupportedSyntax
  let dec ← dec.ensureUnitAt x
  openMutBody x seq fun p outerTy base => do
    let cur ← getFVarFromUserName x.getId
    let proof ← Term.elabTermEnsuringType prf (mkApp p cur)
    rebindMut x outerTy (← mkAppM ``Subtype.mk #[cur, proof]) base dec
```

To demonstrate this feature in action, take the type `Pos` of nonzero natural numbers:
<a id="Pos-_LPAR_in-Locally-Violating-Invariants_RPAR_"></a>


```proofscript
abbrev Pos := { n : Nat // 0 < n }
```

Within the `open` block, `x` has type `Nat`. Both it and other mutable variables can be reassigned:

```proofscript
#eval show Id (Pos × Nat) from do
  let mut other := 100
  let mut x : Pos := ⟨10, by grind⟩
  open mut x do
    x := x * 2
    other := other + x
    x := x + 1
  invariant by grind
  return (x, other)
```

```lean
(21, 120)
```

Likewise, the inner block can `return` from the outer [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do) block:

```proofscript
#eval show Id (Nat × Nat) from do
  let mut other := 100
  let mut x : Pos := ⟨10, by grind⟩
  open mut x do
    x := x * 2
    other := other + x
    if other > 0 then return (0, other)
    x := x + 1
  invariant by grind
  return (x.val, other)
```

```lean
(0, 120)
```

For cases where it is impossible to prove that the returned value satisfies the predicate, it can still be useful to *check* that it does. The elaborator for the monadic variant expects a `PLift`'ed proof to be returned:
<a id="closeInvariant-_LPAR_in-Locally-Violating-Invariants_RPAR_"></a>
<a id="elabOpenMutMon-_LPAR_in-Locally-Violating-Invariants_RPAR_"></a>


```proofscript
def closeInvariant {α : Type} {P : α → Prop} [Monad m]
    (val : α) (act : m (PLift (P val))) : m (Subtype P) :=
  return ⟨val, (← act).down⟩

@[doElem_elab openMutMon]
def elabOpenMutMon : DoElab := fun stx dec => do
  let `(doElem| open mut $x:ident do $seq invariant do $invSeq) := stx
    | throwUnsupportedSyntax
  let dec ← dec.ensureUnitAt x
  openMutBody x seq fun _p outerTy base => do
    let cur ← getFVarFromUserName x.getId
    let actionStx ←
      ``(closeInvariant $(← Term.exprToSyntax cur) (do $invSeq))
    let action ← elabTermEnsuringType actionStx (← mkMonadApp outerTy)
    let rn ← mkFreshUserName `__repacked
    let closeCont : DoElemCont := {
      resultName := rn, resultType := outerTy
      k := do
        let d ← getLocalDeclFromUserName rn
        rebindMut x outerTy d.toExpr base dec
    }
    closeCont.mkBindUnlessPure action
```

Now, a runtime check can ensure the invariant, or throw an exception if it does not hold:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="trySub3-_LPAR_in-Locally-Violating-Invariants_RPAR_"></a>


```proofscript
function trySub3 (x : Pos) : IO Pos := do
  let mut x := x
  open mut x do
    x := x - 3
  invariant do
    if h : 0 < x then pure ⟨h⟩
    else throw (IO.userError s!"Not positive: x = {x}")
  return x
```

```proofscript
#eval trySub3 ⟨10, by grind⟩
```

```lean
7
```

```proofscript
#eval trySub3 ⟨3, by grind⟩
```

```lean
Not positive: x = 0
```

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
("neg", "zero", "pos")
```


### Display 2


```text
Variable `y` cannot be mutated. Only variables declared using `let mut` can be mutated.
      If you did not intend to mutate but define `y`, consider using `let y` instead
```


### Display 3


```text
Type mismatch
  x
has type
  Nat
but is expected to have type
  PUnit
```


### Display 4


```text
some ()
```


### Display 5


```text
("small", "medium", "large")
```


### Display 6


```text
100
```


### Display 7


```text
This `do` element and its control-flow region are dead code. Consider removing it.
```


### Display 8


```text
2
```


### Display 9


```text
x = 1, y = 1
x = 1, y = 2
x = 2, y = 3
x = 3, y = 5
x = 5, y = 8
```


### Display 10


```text
x: 1, c: m
x: 1, c: f
x: 0, c: A
```


### Display 11


```text
110
```


### Display 12


```text
(21, 120)
```


### Display 13


```text
(0, 120)
```


### Display 14


```text
7
```


### Display 15


```text
Not positive: x = 0
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
⊢ ∀ (x : Nat), x ∈ xs → x % 2 = 1
```


### Display 2


```text
All goals completed! 🐙
```


### Display 3


```text
other:Nat := 100⊢ 0 < 10
```


### Display 4


```text
other✝:Nat := 100x✝²:Pos := ⟨10, _eval._proof_1⟩x✝¹:Nat := x✝².valx✝:Nat := x✝¹ * 2other:Nat := other✝ + x✝x:Nat := x✝ + 1⊢ (fun n => 0 < n) x
```


### Display 5


```text
other✝:Nat := 100x✝²:Pos := ⟨10, _eval._proof_1⟩x✝¹:Nat := x✝².valx✝:Nat := x✝¹ * 2other:Nat := other✝ + x✝__r✝¹:Unitx:Nat := x✝ + 1⊢ (fun n => 0 < n) x
```


### Display 6


```text
⊢ 0 < 10
```


### Display 7


```text
⊢ 0 < 3
```

