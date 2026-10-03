<a id="notations"></a>

# ProofScript — 23.3. Notations

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Use native notation, syntax categories, quotations, macros and elaborators in an explicitly declared extension environment. Macro hygiene preserves binding identity; a convenient generated name is not enough. Quoted parser code remains native code rather than being rewritten as ordinary surface expressions. Extensions produce syntax or candidate declarations and gain no independent proof authority.

**Compiler and coverage boundary.** Register collisions and lifted child slots explicitly. Do not globally rewrite strings, quoted grammar, tactic combinators or host code. Plugin operating-system permissions are separate from logical soundness.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Notations-and-Macros/Notations/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Notations-and-Macros/Notations/index.html). Source Git blob: `b3da47b44ee95e8c9ad7047fc6b0b7a7d5706bf6`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 23.3. Notations

The term 
<a id="--tech-term-notation"></a>
*notation* is used in two ways in Lean: it can refer to the general concept of concise ways of writing down ideas, and it is the name of a language feature that allows notations to be conveniently implemented with little code. Like custom operators, Lean notations allow the grammar of terms to be extended with new forms. However, notations are more general: the new syntax may freely intermix required keywords or operators with subterms, and they provide more precise control over precedence levels. Notations may also rearrange their parameters in the resulting subterms, while infix operators provide them to the function term in a fixed order. Because notations may define operators that use a mix of prefix, infix, and postfix components, they can be called 
<a id="--tech-term-mixfix"></a>
*mixfix* operators.

<a id="command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Notation Declarations**

Notations are defined using the [`notation`](index.md#Lean___Parser___Command___notation) command.

<a id="Lean___Parser___Command___notation"></a>

```ebnf
command ::= ...
    | docComment?
      attributes?
      attrKind notation(:prec)? ((name := ident))? ((priority := prio))? notationItem* => term
```

<a id="Lean___Parser___Command___notationItem"></a>

**syntax**

**Notation Items**

The body of a notation definition consists of a sequence of 
<a id="--tech-term-notation-items"></a>
*notation items*, which may be either string literals or identifiers with optional precedences.

<a id="str___antiquot"></a>

```ebnf
notationItem ::=
    str
```

<a id="Lean___Parser___Command___identPrec"></a>

```ebnf
notationItem ::= ...
    | ident(:prec)?
```

As with operator declarations, the contents of the documentation comments are shown to users while they interact with the new syntax. Adding the `inherit_doc` attribute causes the documentation comment of the function at the head of the term into which the notation expands to be copied to the new syntax. Other attributes may be added to invoke other compile-time metaprograms on the resulting definition.

Notations interact with [section scopes](../../Namespaces-and-Sections/index.md#--tech-term-section-scope) in the same manner as attributes and operators. By default, notations are available in any module that transitively imports the one in which they are established, but they may be declared `scoped` or `local` to restrict their availability either to contexts in which the current namespace has been opened or to the current [section scope](../../Namespaces-and-Sections/index.md#--tech-term-section-scope), respectively.

Like operators, the [local longest-match rule](../Custom-Operators/index.md#--tech-term-local-longest-match-rule) is used while parsing notations. If more than one notation ties for the longest match, the declared priorities are used to determine which parse result applies. If this still does not resolve the ambiguity, then all are saved, and the elaborator is expected to attempt all of them, succeeding when exactly one can be elaborated.

Rather than a single operator with its fixity and token, the body of a notation declaration consists of a sequence of 
<a id="--tech-term-notation-items-next"></a>
*notation items*, which may be either new [atoms](../Defining-New-Syntax/index.md#--tech-term-Atoms) (including both keywords such as `if`, `#eval`, or `where` and symbols such as `=>`, `+`, `↗`, `⟦`, or `⋉`) or positions for terms. Just as they do in operators, string literals identify the placement of atoms. Leading and trailing spaces in the strings do not affect parsing, but they cause Lean to insert spaces in the corresponding position when displaying the syntax in [proof states](../../Tactic-Proofs/index.md#--tech-term-proof-state) and error messages. Identifiers indicate positions where terms are expected, and name the corresponding term so it can be inserted in the notation's expansion.

While custom operators have a single notion of precedence, there are many involved in a notation. The notation itself has a precedence, as does each term to be parsed. The notation's precedence determines which contexts it may be parsed in: the parser only attempts to parse productions whose precedence is at least as high as the current context. For example, because multiplication has higher precedence than addition, the parser will attempt to parse an infix multiplication term while parsing the arguments to addition, but not vice versa. The precedence of each term to be parsed determines which other productions may occur in them.

If no precedence is supplied for the notation itself, the default value depends on the form of the notation. If the notation both begins and ends with an atom (represented by string literals), then the default precedence is `max`. This applies both to notations that consist only of a single atom and to notations with multiple items, in which the first and last items are both atoms. Otherwise, the default precedence of the whole notation is `lead`. If no precedence is provided for notation items that are terms, then they default to precedence `min`.

After the required double arrow ([`=>`](index.md#Lean___Parser___Command___notation)), the notation is provided with an expansion. While operators are always expanded by applying their function to the operator's arguments in order, notations may place their term items in any position in the expansion. The terms are referred to by name. Term items may occur any number of times in the expansion. Because notation expansion is a purely syntactic process that occurs prior to elaboration or code generation, duplicating terms in the expansion may lead to duplicated computation when the resulting term is evaluated, or even duplicated side effects when working in a monad.

<a id="Ignored-Terms-in-Notation-Expansion"></a>
Ignored Terms in Notation Expansion 

This notation ignores its first parameter:
<a id="ignore-_LPAR_in-Ignored-Terms-in-Notation-Expansion_RPAR_"></a>


```proofscript
notation (name := ignore) "ignore " _ign:arg e:arg => e
```

The term in the ignored position is discarded, and Lean never attempts to elaborate it, so terms that would otherwise result in errors can be used here:

```proofscript
#eval ignore (2 + "whatever") 5
```

```lean
5
```

However, the ignored term must still be syntactically valid:

```lean
#eval ignore (2 +) 5
```

```lean
<example>:1:17-1:18: unexpected token ')'; expected term
```

<a id="Duplicated-Terms-in-Notation-Expansion"></a>
Duplicated Terms in Notation Expansion 

The `dup!` notation duplicates its sub-term.
<a id="dup-_LPAR_in-Duplicated-Terms-in-Notation-Expansion_RPAR_"></a>


```proofscript
notation (name := dup) "dup!" t:arg => (t, t)
```

Because the term is duplicated, it can be elaborated separately with different types:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="e-_LPAR_in-Duplicated-Terms-in-Notation-Expansion_RPAR_"></a>


```proofscript
const e : Nat × Int := dup! (2 + 2)
```

Printing the resulting definition demonstrates that the work of addition will be performed twice:

```proofscript
#print e
```

```lean
def e : Nat × Int :=
(2 + 2, 2 + 2)
```

When the expansion consists of the application of a function defined in the global environment and each term in the notation occurs exactly once, an [unexpander](../Extending-Lean___s-Output/index.md#--tech-term-unexpanders) is generated. The new notation will be displayed in [proof states](../../Tactic-Proofs/index.md#--tech-term-proof-state), error messages, and other output from Lean when matching function application terms otherwise would have been displayed. As with custom operators, Lean does not track whether the notation was used in the original term; it is used at every opportunity in Lean's output.

<a id="Notations___-Defined-Functions___-and-Unexpanders"></a>
Notations, Defined Functions, and Unexpanders 

When a notation does not expand to the application of a defined function, no unexpander is generated. Here, the notation expands to an anonymous function:

```proofscript
notation "[" start " ⇒ " stop "]" => fun x => x > start && x < stop
```

Because there is no named function in the expansion, no unexpander can be generated:

```proofscript
#check [5 ⇒ 8]
```

```lean
fun x => decide (x > 5) && decide (x < 8) : Nat → Bool
```

Using a named function results in an unexpander, which is used for terms that consist of applications of `between`:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="between-_LPAR_in-Notations___-Defined-Functions___-and-Unexpanders_RPAR_"></a>


```proofscript
function between (start stop : Nat) : Nat → Prop :=
  fun x => x > start && x < stop

notation "[" start " ⇒' " stop "]" => between start stop
```

```proofscript
#check [5 ⇒' 8]
```

```lean
[5 ⇒' 8] : Nat → Prop
```

<a id="operators-and-notations"></a>
### 23.3.1. Operators and Notations

Internally, operator declarations are translated into notation declarations. Term notation items are inserted where the operator would expect arguments, and in the corresponding positions in the expansion. For prefix and postfix operators, the notation's precedence as well as the precedences of its term items is the operator's declared precedence. For non-associative infix operators, the notation's precedence is the declared precedence, but both arguments are parsed at a precedence level that is one higher, which prevents successive uses of the notation without parentheses. Associative infix operators use the operator's precedence for the notation and for one argument, while a precedence that is one level higher is used for the other argument; this prevents successive applications in one direction only. Left-associative operators use the higher precedence for their right argument, while right-associative operators use the higher precedence for their left argument.

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


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
5
```


### Display 2


```text
def e : Nat × Int :=
(2 + 2, 2 + 2)
```


### Display 3


```text
fun x => decide (x > 5) && decide (x < 8) : Nat → Bool
```


### Display 4


```text
[5 ⇒' 8] : Nat → Prop
```

