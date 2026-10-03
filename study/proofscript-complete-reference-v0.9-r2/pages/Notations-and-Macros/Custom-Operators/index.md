<a id="operators"></a>

# ProofScript — 23.1. Custom Operators

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Use native notation, syntax categories, quotations, macros and elaborators in an explicitly declared extension environment. Macro hygiene preserves binding identity; a convenient generated name is not enough. Quoted parser code remains native code rather than being rewritten as ordinary surface expressions. Extensions produce syntax or candidate declarations and gain no independent proof authority.

**Compiler and coverage boundary.** Register collisions and lifted child slots explicitly. Do not globally rewrite strings, quoted grammar, tactic combinators or host code. Plugin operating-system permissions are separate from logical soundness.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Notations-and-Macros/Custom-Operators/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Notations-and-Macros/Custom-Operators/index.html). Source Git blob: `2854a4db8e4a058bb32cc754e095b6f4991a5862`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 23.1. Custom Operators

Lean supports custom infix, prefix, and postfix operators. New operators can be added by any Lean library, and the new operators have equal status to those that are part of the language. Each new operator is assigned an interpretation as a function, after which uses of the operator are translated into uses of the function. The operator's translation into a function call is referred to as its 
<a id="--tech-term-expansion"></a>
*expansion*. If this function is a [type class](../../Type-Classes/index.md#--tech-term-type-class) [method](../../Type-Classes/index.md#--tech-term-methods), then the resulting operator can be overloaded by defining instances of the class.

All operators have a 
<a id="--tech-term-precedence"></a>
*precedence*. Operator precedence determines the order of operations for unparenthesized expressions: because multiplication has a higher precedence than addition, `2 + 3 * 4` is equivalent to `2 + (3 * 4)`, and `2 * 3 + 4` is equivalent to `(2 * 3) + 4`. Infix operators additionally have an 
<a id="--tech-term-associativity"></a>
*associativity* that determines the meaning of a chain of operators that have the same precedence:

<a id="--tech-term-Left-associative"></a>
Left-associative

These operators nest to the left. Addition is left- associative, so `2 + 3 + 4 + 5` is equivalent to `((2 + 3) + 4) + 5`.

<a id="--tech-term-Right-associative"></a>
Right-associative

These operators nest to the right. The product type is right-associative, so `Nat × String × Unit × Option Int` is equivalent to `Nat × (String × (Unit × Option Int))`.

<a id="--tech-term-Non-associative"></a>
Non-associative

Chaining these operators is a syntax error. Explicit parenthesization is required. Equality is non-associative, so the following is an error:

```lean
1 + 2 = 3 = 2 + 1
```

The parser error is:

```lean
<example>:1:10-1:11: expected end of input
```

<a id="Precedence-for-Prefix-and-Infix-Operators"></a>
Precedence for Prefix and Infix Operators 

The proposition `¬A ∧ B` is equivalent to `(¬A) ∧ B`, because `¬` has a higher precedence than `∧`. Because `∧` has higher precedence than `=` and is right-associative, `¬A ∧ B = (¬A) ∧ B` is equivalent to `¬A ∧ ((B = ¬A) ∧ B)`.

Lean provides commands for defining new operators:

<a id="command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Operator Declarations**

Non-associative infix operators are defined using `infix`:

<a id="Lean___Parser___Command___mixfix"></a>

```ebnf
command ::= ...
    | docComment?
      attributes?
      attrKind infix:prec ((name := ident))? ((priority := prio))? str => term
```

Left-associative infix operators are defined using `infixl`:

<a id="Lean___Parser___Command___mixfix-next"></a>

```ebnf
command ::= ...
    | docComment?
      attributes?
      attrKind infixl:prec ((name := ident))? ((priority := prio))? str => term
```

Right-associative infix operators are defined using `infixr`:

<a id="Lean___Parser___Command___mixfix-next-next"></a>

```ebnf
command ::= ...
    | docComment?
      attributes?
      attrKind infixr:prec ((name := ident))? ((priority := prio))? str => term
```

Prefix operators are defined using `prefix`:

<a id="Lean___Parser___Command___mixfix-next-next-next"></a>

```ebnf
command ::= ...
    | docComment?
      attributes?
      attrKind prefix:prec ((name := ident))? ((priority := prio))? str => term
```

Postfix operators are defined using `postfix`:

<a id="Lean___Parser___Command___mixfix-next-next-next-next"></a>

```ebnf
command ::= ...
    | docComment?
      attributes?
      attrKind postfix:prec ((name := ident))? ((priority := prio))? str => term
```

Each of these commands may be preceded by [documentation comments](../../Definitions/Modifiers/index.md#--tech-term-Documentation-comments) and [attributes](../../Attributes/index.md#--tech-term-Attributes). The documentation comment is shown when the user hovers their mouse over the operator, and attributes may invoke arbitrary metaprograms, just as for any other declaration. The attribute `inherit_doc` causes the documentation of the function that implements the operator to be reused for the operator itself.

Operators interact with [section scopes](../../Namespaces-and-Sections/index.md#--tech-term-section-scope) in the same manner as attributes. By default, operators are available in any module that transitively imports the one in which they are established, but they may be declared `scoped` or `local` to restrict their availability either to contexts in which the current namespace has been opened or to the current [section scope](../../Namespaces-and-Sections/index.md#--tech-term-section-scope), respectively.

Custom operators require a [precedence](../Precedence/index.md#precedence) specifier, following a colon. There is no default precedence to fall back to for custom operators.

Operators may be explicitly named. This name denotes the extension to Lean's syntax, and is primarily used for metaprogramming. If no name is explicitly provided, then Lean generates one based on the operator. The specifics of the assignment of this name should not be relied upon, both because the internal name assignment algorithm may change and because the introduction of similar operators in upstream dependencies may lead to a clash, in which case Lean will modify the assigned name until it is unique.

<a id="Assigned-Operator-Names"></a>
Assigned Operator Names 

Given this infix operator:

```proofscript
infix:90 " ⤴ " => Option.getD
```

the internal name `«term_⤴_»` is assigned to the resulting parser extension.

<a id="Provided-Operator-Names"></a>
Provided Operator Names 

Given this infix operator:
<a id="getDOp-_LPAR_in-Provided-Operator-Names_RPAR_"></a>


```proofscript
infix:90 (name := getDOp) " ⤴ " => Option.getD
```

the resulting parser extension is named `getDOp`.

<a id="Inheriting-Documentation"></a>
Inheriting Documentation 

Given this infix operator:

```proofscript
@[inherit_doc]
infix:90 " ⤴ " => Option.getD
```

the resulting parser extension has the same documentation as `Option.getD`.

When multiple operators are defined that share the same syntax, Lean's parser attempts all of them. If more than one succeed, the one that used the most input is selected—this is called the 
<a id="--tech-term-local-longest-match-rule"></a>
*local longest-match rule*. In some cases, parsing multiple operators may succeed, all of them covering the same range of the input. In these cases, the operator's [priority](../../Type-Classes/Instance-Declarations/index.md#--tech-term-priorities) is used to select the appropriate result. Finally, if multiple operators with the same priority tie for the longest match, the parser saves all of the results, and the elaborator attempts each in turn, failing if elaboration does not succeed on exactly one of them.

<a id="Ambiguous-Operators-and-Priorities"></a>
Ambiguous Operators and Priorities 

Defining an alternative implementation of `+` as `Or` requires only an infix operator declaration.

```proofscript
infix:65  " + " => Or
```

With this declaration, Lean attempts to elaborate addition both using the built-in syntax for `HAdd.hAdd` and the new syntax for `Or`:

```proofscript
#check True + False
```

```lean
True + False : Prop
```

```proofscript
#check 2 + 2
```

```lean
2 + 2 : Nat
```

However, because the new operator is not associative, the [local longest-match rule](index.md#--tech-term-local-longest-match-rule) means that only `HAdd.hAdd` applies to an unparenthesized three-argument version:

```proofscript
#check True + False + True
```

```lean
failed to synthesize instance of type class
  HAdd Prop Prop ?m.3

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```

If the infix operator is declared with high priority, then Lean does not try the built-in `HAdd.hAdd` operator in ambiguous cases:

```proofscript
infix:65 (priority := high)  " + " => Or
```

```proofscript
#check True + False
```

```lean
True + False : Prop
```

```proofscript
#check 2 + 2
```

```lean
failed to synthesize instance of type class
  OfNat Prop 2
numerals are polymorphic in Lean, but the numeral `2` cannot be used in a context where the expected type is
  Prop
due to the absence of the instance above

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```

The new operator is not associative, so the [local longest-match rule](index.md#--tech-term-local-longest-match-rule) means that only `HAdd.hAdd` applies to the three-argument version:

```proofscript
#check True + False + True
```

```lean
failed to synthesize instance of type class
  HAdd Prop Prop ?m.3

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```

The actual operator is provided as a string literal. The new operator must satisfy the following requirements:

- It must contain at least one character.
- The first character may not be a single or double quote (`'` or `"`), unless the operator is `''`.
- It may not begin with a backtick (`````) followed by a character that would be a valid prefix of a quoted name.
- It may not begin with a digit.
- It may not include internal whitespace.

The operator string literal may begin or end with a space. These are not part of the operator's syntax, and their presence does not require spaces around uses of the operator. However, the presence of spaces cause Lean to insert spaces when showing the operator to the user. Omitting them causes the operator's arguments to be displayed immediately next to the operator itself.

Finally, the operator's meaning is provided, separated from the operator by `=>`. This may be any Lean term. Uses of the operator are desugared into function applications, with the provided term in the function position. Prefix and postfix operators apply the term to their single argument as an explicit argument. Infix operators apply the term to the left and right arguments, in that order. Other than its ability to accept arguments at each call site, there are no specific requirements imposed on the term. Operators may construct functions, so the term may expect more parameters than the operator. Implicit and [instance-implicit](../../Type-Classes/index.md#--tech-term-instance-implicit) parameters are resolved at each application site, which allows the operator to be defined by a [type class](../../Type-Classes/index.md#--tech-term-type-class) [method](../../Type-Classes/index.md#--tech-term-methods).

If the term consists either of a name from the global environment or of an application of such a name to one or more arguments, then Lean automatically generates an [unexpander](../Extending-Lean___s-Output/index.md#--tech-term-unexpanders) for the operator. This means that the operator will be displayed in [proof states](../../Tactic-Proofs/index.md#--tech-term-proof-state), error messages, and other output from Lean when the function term otherwise would have been displayed. Lean does not track whether the operator was used in the original term; it is inserted at every opportunity.

<a id="Custom-Operators-in-Lean___s-Output"></a>
Custom Operators in Lean's Output 

The function `perhapsFactorial` computes a factorial for a number if it's not too large.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="fact-_LPAR_in-Custom-Operators-in-Lean___s-Output_RPAR_"></a>
<a id="perhapsFactorial-_LPAR_in-Custom-Operators-in-Lean___s-Output_RPAR_"></a>


```proofscript
def fact : Nat → Nat
  | 0 => 1
  | n+1 => (n + 1) * fact n

function perhapsFactorial (n : Nat) : Option Nat :=
  if n < 8 then some (fact n) else none
```

The postfix interrobang operator can be used to represent it.

```proofscript
postfix:90 "‽" => perhapsFactorial
```

When attempting to prove that `∀ n, n ≥ 8 → (perhapsFactorial n).isNone`, the initial proof state uses the new operator, even though the theorem as written does not:

<a id="Infix-Operators___-Defined-Functions___-and-Unexpanders"></a>
Infix Operators, Defined Functions, and Unexpanders 

When an operator does not expand to the application of a defiend function, no unexpander is generated. Here, the postfix interrobang expands to an anonymous function that takes a factorial if its argument is not too large.
<a id="fact-_LPAR_in-Infix-Operators___-Defined-Functions___-and-Unexpanders_RPAR_"></a>


```proofscript
def fact : Nat → Nat
  | 0 => 1
  | n+1 => (n + 1) * fact n

set_option quotPrecheck false in
postfix:90 "‽" => fun (n : Nat) => if n < 8 then some (fact n) else none
```

Because there is no named function in the expansion, no unexpander can be generated:

```proofscript
#check 7‽
```

```lean
(fun n => if n < 8 then some (fact n) else none) 7 : Option Nat
```

Using a named function results in an unexpander, which is used for terms that consist of applications of `perhapsFactorial`:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="perhapsFactorial-_LPAR_in-Infix-Operators___-Defined-Functions___-and-Unexpanders_RPAR_"></a>


```proofscript
function perhapsFactorial (n : Nat) : Option Nat :=
  if n < 8 then some (fact n) else none

postfix:90 "‽'" => perhapsFactorial
```

```proofscript
#check 7‽'
```

```lean
7‽' : Option Nat
```

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
A `docComment` parses a "documentation comment" like `/-- foo -/`. This is not treated like
a regular comment (that is, as whitespace); it is parsed and forms part of the syntax tree structure.

At parse time, `docComment` checks the value of the `doc.verso` option. If it is true, the contents
are parsed as Verso markup. If not, the contents are treated as plain text or Markdown. Use
`plainDocComment` to always treat the contents as plain text.

A plain text doc comment node contains a `/--` atom and then the remainder of the comment, `foo -/`
in this example. Use `TSyntax.getDocString` to extract the body text from a doc string syntax node.
A Verso comment node contains the `/--` atom, the document's syntax tree, and a closing `-/` atom.
```


### Display 2


```text
`attrKind` matches `("scoped" <|> "local")?`, used before an attribute like `@[local simp]`.
```


### Display 3


```text
`infix:prec "op" => f` is equivalent to `notation:prec x:prec1 "op" y:prec1 => f x y`, where `prec1 := prec + 1`.
```


### Display 4


```text
`infixl:prec "op" => f` is equivalent to `notation:prec x:prec "op" y:prec1 => f x y`, where `prec1 := prec + 1`.
```


### Display 5


```text
`infixr:prec "op" => f` is equivalent to `notation:prec x:prec1 "op" y:prec => f x y`, where `prec1 := prec + 1`.
```


### Display 6


```text
`prefix:prec "op" => f` is equivalent to `notation:prec "op" x:prec => f x`.
```


### Display 7


```text
`postfix:prec "op" => f` is equivalent to `notation:prec x:prec "op" => f x`.
```


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
True + False : Prop
```


### Display 2


```text
2 + 2 : Nat
```


### Display 3


```text
failed to synthesize instance of type class
  HAdd Prop Prop ?m.3

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```


### Display 4


```text
sorry + sorry : Prop
```


### Display 5


```text
failed to synthesize instance of type class
  OfNat Prop 2
numerals are polymorphic in Lean, but the numeral `2` cannot be used in a context where the expected type is
  Prop
due to the absence of the instance above

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```


### Display 6


```text
(fun n => if n < 8 then some (fact n) else none) 7 : Option Nat
```


### Display 7


```text
7‽' : Option Nat
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
⊢ ∀ (n : Nat), n ≥ 8 → n‽.isNone = true
```

