<a id="precedence"></a>

# ProofScript — 23.2. Precedence

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Use native notation, syntax categories, quotations, macros and elaborators in an explicitly declared extension environment. Macro hygiene preserves binding identity; a convenient generated name is not enough. Quoted parser code remains native code rather than being rewritten as ordinary surface expressions. Extensions produce syntax or candidate declarations and gain no independent proof authority.

**Compiler and coverage boundary.** Register collisions and lifted child slots explicitly. Do not globally rewrite strings, quoted grammar, tactic combinators or host code. Plugin operating-system permissions are separate from logical soundness.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Notations-and-Macros/Precedence/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Notations-and-Macros/Precedence/index.html). Source Git blob: `7df7ea2d300a988574964b8eb289c89a01a8426a`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 23.2. Precedence

Infix operators, notations, and other syntactic extensions to Lean make use of explicit [precedence](../Custom-Operators/index.md#--tech-term-precedence) annotations. While precedences in Lean can technically be any natural number, by convention they range from 10 to 1024, respectively denoted `min` and `max`. Function application has the highest precedence.

<a id="prec"></a>

**syntax**

**Parser Precedences**

Most operator precedences consist of explicit numbers. The named precedence levels denote the outer edges of the range, close to the minimum or maximum, and are typically used by more involved syntax extensions.

<a id="num___antiquot-next"></a>

```ebnf
prec ::=
    num
```

Precedences may also be denoted as sums or differences of precedences; these are typically used to assign precedences that are relative to one of the named precedences.

<a id="Lean___Parser___Syntax___addPrec"></a>

```ebnf
prec ::= ...
    | prec + prec
```

<a id="Lean___Parser___Syntax___subPrec"></a>

```ebnf
prec ::= ...
    | prec - prec
```

<a id="_FLQQ_prec_LPAR___RPAR__FLQQ_"></a>

```ebnf
prec ::= ...
    | (prec)
```

The maximum precedence is used to parse terms that occur in a function position. Operators should typically not use this level, because it can interfere with users' expectation that function application binds more tightly than any other operator, but it is useful in more involved syntax extensions to indicate how other constructs interact with function application.

<a id="precMax"></a>

```ebnf
prec ::= ...
    | max
```

Argument precedence is one less than the maximum precedence. This level is useful for defining syntax that should be treated as an argument to a function, such as `fun` or [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do).

<a id="precArg"></a>

```ebnf
prec ::= ...
    | arg
```

Lead precedence is less than argument precedence, and should be used for custom syntax that should not occur as a function argument, such as `let`.

<a id="precLead"></a>

```ebnf
prec ::= ...
    | lead
```

The minimum precedence can be used to ensure that an operator binds less tightly than all other operators.

<a id="precMin"></a>

```ebnf
prec ::= ...
    | min
```

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Addition of precedences. This is normally used only for offsetting, e.g. `max + 1`.
```


### Display 2


```text
Subtraction of precedences. This is normally used only for offsetting, e.g. `max - 1`.
```


### Display 3


```text
Parentheses are used for grouping precedence expressions.
```


### Display 4


```text
Maximum precedence used in term parsers, in particular for terms in
function position (`ident`, `paren`, ...)
```


### Display 5


```text
Precedence used for application arguments (`do`, `by`, ...).
```


### Display 6


```text
Precedence used for terms not supposed to be used as arguments (`let`, `have`, ...).
```


### Display 7


```text
Minimum precedence used in term parsers.
```

