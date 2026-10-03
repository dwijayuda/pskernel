<a id="identifiers-and-resolution"></a>

# ProofScript — 13.1. Identifiers

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Terms keep native binding, precedence and type-directed elaboration. D-CALL is adjacency-sensitive: f(x,y) supplies two curried arguments; f((x,y)) and native f (x,y) supply one tuple. An empty call passes Unit. Lambdas use fun, records use :=, and match patterns remain native even when constructor terms use decorated calls. Braces delimit specific categories; they do not disable the native layout checks inside them.

**Compiler and coverage boundary.** Preserve grouping that influences elaboration. Do not flatten nested calls, split patterns on arbitrary bars, or rewrite punctuation inside strings and quotations.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Terms/Identifiers/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Terms/Identifiers/index.html). Source Git blob: `59f200382a46d1e62f07f6221f5f485fee684f4a`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 13.1. Identifiers

<a id="term-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Identifiers**

```text
$x:ident
```

An identifier term is a reference to a name.The specific lexical syntax of identifiers is described [in the section on Lean's concrete syntax](../../Source-Files-and-Modules/index.md#keywords-and-identifiers). Identifiers also occur in contexts where they bind names, such as `let` and `fun`; however, these binding occurrences are not complete terms in and of themselves. The mapping from identifiers to names is not trivial: at any point in a [module](../../Source-Files-and-Modules/index.md#--tech-term-module), some number of [namespaces](../../Namespaces-and-Sections/index.md#--tech-term-namespaces) will be open, there may be [section variables](../../Namespaces-and-Sections/index.md#--tech-term-Section-variables), and there may be local bindings. Furthermore, identifiers may contain multiple dot-separated atomic identifiers; the dot both separates namespaces from their contents and variables from fields or functions that use [field notation](../Function-Application/index.md#--tech-term-field-notation). This creates ambiguity, because an identifier `A.B.C.D.e.f` could refer to any of the following:

- A name `f` in the namespace `A.B.C.D.e` (for instance, a function defined in `e`'s `where` block).
- An application of `T.f` to `A.B.C.D.e` if `A.B.C.D.e` has type `T`
- A projection of field `f` from a structure named `A.B.C.D.e`
- A series of field projections `B.C.D.e` from structure value `A`, followed by an application of `f` using field notation
- If namespace `Q` is opened, it could be a reference to any of the above with a `Q` prefix, such as a name `f` in the namespace `Q.A.B.C.D.e`

This list is not exhaustive. Given an identifier, the elaborator must discover which name or names an identifier refers to, and whether any of the trailing components are fields or functions applied via field notation. This is called 
<a id="--tech-term-resolving"></a>
*resolving* the name.

Some declarations in the global environment are lazily created the first time they are referenced. Resolving an identifier in a way that both creates one of these declarations and results in a reference to it is called 
<a id="--tech-term-realizing"></a>
*realizing* the name. The rules for resolving and realizing a name are the same, so even though this section refers only to resolving names, it applies to both.

Name resolution is affected by the following:

- [Pre-resolved names](../../Notations-and-Macros/Macros/index.md#--tech-term-pre-resolved-identifiers) attached to the identifier
- The [macro scopes](../../Notations-and-Macros/Macros/index.md#--tech-term-macro-scopes) attached to the identifier
- The local bindings in scope, including auxiliary definitions created as part of the elaboration of `let rec`.
- Aliases created with [`export`](../../Namespaces-and-Sections/index.md#Lean___Parser___Command___export) in modules transitively imported by the current module
- The current [section scope](../../Namespaces-and-Sections/index.md#--tech-term-section-scope), in particular the [current namespace](../../Namespaces-and-Sections/index.md#--tech-term-current-namespace), opened namespaces, and section variables

Any prefix of an identifier can resolve to a set of names. The suffix that was not included in the resolution process is then treated as field projections or field notation. Resolutions of longer prefixes take precedence over resolutions of shorter prefixes; in other words, as few components as of the identifier as possible are treated as field notation. An identifier prefix may refer to any of the following, with earlier items taking precedence over later ones:

1. A locally-bound variable whose name is identical to the identifier prefix, including macro scopes, with closer local bindings taking precedence over outer local bindings.
2. A local auxiliary definition whose name is identical to the identifier prefix
3. A [section variable](../../Namespaces-and-Sections/index.md#--tech-term-Section-variables) whose name is identical to the identifier prefix
4. A global name that is identical to a prefix of the [current namespace](../../Namespaces-and-Sections/index.md#--tech-term-current-namespace) appended to the identifier prefix, or for which an alias exists in a prefix of the current namespace, with longer prefixes of the current namespace taking precedence over shorter ones
5. A global name that has been brought into scope via [`open`](../../Namespaces-and-Sections/index.md#Lean___Parser___Command___open) commands that is identical to the identifier prefix

If an identifier resolves to multiple names, then the elaborator attempts to use all of them. If exactly one of them succeeds, then it is used as the meaning of the identifier. It is an error if more than one succeed or if all fail.

<a id="Local-Names-Take-Precedence"></a>
Local Names Take Precedence 

Local bindings take precedence over global bindings:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="x-_LPAR_in-Local-Names-Take-Precedence_RPAR_"></a>


```proofscript
const x := "global"

#eval
  let x := "local"
  x
```

```lean
"local"
```

The innermost local binding of a name takes precedence over others:

```proofscript
#eval
  let x := "outer"
  let x := "inner"
  x
```

```lean
"inner"
```

<a id="Longer-Prefixes-of-Current-Namespace-Take-Precedence"></a>
Longer Prefixes of Current Namespace Take Precedence 

The namespaces `A`, `B`, and `C` are nested. Both `A` and `C` contain a definition of `x`.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="A___x-_LPAR_in-Longer-Prefixes-of-Current-Namespace-Take-Precedence_RPAR_"></a>
<a id="A___B___C___x-_LPAR_in-Longer-Prefixes-of-Current-Namespace-Take-Precedence_RPAR_"></a>


```proofscript
namespace A
const x := "A.x"
namespace B
namespace C
const x := "A.B.C.x"
```

When the current namespace is `A.B.C`, `x` resolves to `A.B.C.x`.

```proofscript
#eval x
```

```lean
"A.B.C.x"
```

When the current namespace is `A.B`, `x` resolves to `A.x`.

```proofscript
end C
#eval x
```

```lean
"A.x"
```

<a id="Longer-Identifier-Prefixes-Take-Precedence"></a>
Longer Identifier Prefixes Take Precedence 

When an identifier could refer to different projections from names, the one with the longest name takes precedence:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="A-_LPAR_in-Longer-Identifier-Prefixes-Take-Precedence_RPAR_"></a>
<a id="A___y-_LPAR_in-Longer-Identifier-Prefixes-Take-Precedence_RPAR_"></a>
<a id="B-_LPAR_in-Longer-Identifier-Prefixes-Take-Precedence_RPAR_"></a>
<a id="B___y-_LPAR_in-Longer-Identifier-Prefixes-Take-Precedence_RPAR_"></a>
<a id="y-_LPAR_in-Longer-Identifier-Prefixes-Take-Precedence_RPAR_"></a>
<a id="y___y-_LPAR_in-Longer-Identifier-Prefixes-Take-Precedence_RPAR_"></a>


```proofscript
structure A where
  y : String
deriving Repr

structure B where
  y : A
deriving Repr

const y : B := ⟨⟨"shorter"⟩⟩
const y.y : A := ⟨"longer"⟩
```

Given the above declarations, `y.y.y` could in principle refer either to the `y` field of the `y` field of `y`, or to the `y` field of `y.y`. It refers to the `y` field of `y.y`, because the name `y.y` is a longer prefix of `y.y.y` than the name `y`:

```proofscript
#eval y.y.y
```

```lean
"longer"
```

<a id="Current-Namespace-Contents-Take-Precedence-Over-Opened-Namespaces"></a>
Current Namespace Contents Take Precedence Over Opened Namespaces 

When an identifier could refer either to a name defined in a prefix of the current namespace or to an opened namespace, the former takes precedence.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="A___x-_LPAR_in-Current-Namespace-Contents-Take-Precedence-Over-Opened-Namespaces_RPAR_"></a>
<a id="B___x-_LPAR_in-Current-Namespace-Contents-Take-Precedence-Over-Opened-Namespaces_RPAR_"></a>


```proofscript
namespace A
const x := "A.x"
end A

namespace B
const x := "B.x"
namespace C
open A
#eval x
```

Even though `A` was opened more recently than the declaration of `B.x`, the identifier `x` resolves to `B.x` rather than `A.x` because `B` is a prefix of the current namespace `B.C`.

```proofscript
#eval x
```

```lean
"B.x"
```

<a id="Ambiguous-Identifiers"></a>
Ambiguous Identifiers 

In this example, `x` could refer either to `A.x` or `B.x`, and neither takes precedence. Because both have the same type, it is an error.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="A___x-_LPAR_in-Ambiguous-Identifiers_RPAR_"></a>
<a id="B___x-_LPAR_in-Ambiguous-Identifiers_RPAR_"></a>


```proofscript
const A.x := "A.x"
const B.x := "B.x"
open A
open B
#eval x
```

```lean
Ambiguous term
  x
Possible interpretations:
  B.x : String

  A.x : String
```

<a id="Disambiguation-via-Typing"></a>
Disambiguation via Typing 

When otherwise-ambiguous names have different types, the types are used to disambiguate:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="C___x-_LPAR_in-Disambiguation-via-Typing_RPAR_"></a>
<a id="D___x-_LPAR_in-Disambiguation-via-Typing_RPAR_"></a>


```proofscript
const C.x := "C.x"
const D.x := 3
open C
open D
#eval (x : String)
```

```lean
"C.x"
```

<a id="The-Lean-Language-Reference--Terms--Identifiers--Leading--___"></a>
### 13.1.1. Leading .

When an identifier begins with a dot (`.`), the type that the elaborator expects for the expression is used to resolve it, rather than the current namespace and set of open namespaces. [Generalized field notation](../Function-Application/index.md#--tech-term-generalized-field-notation) is related: this 
<a id="--tech-term-leading-dot-notation"></a>
*leading dot notation* uses the expected type of the identifier to resolve it to a name, while field notation uses the inferred type of the term immediately prior to the dot.

Identifiers with a leading `.` are to be looked up in the 
<a id="--tech-term-expected-type___s-namespace"></a>
*expected type's namespace*. If the type expected for a term is a constant applied to zero or more arguments, then its namespace is the constant's name. If the type is not an application of a constant (e.g., a function, a metavariable, or a universe) then it doesn't have a namespace.

If the name is not found in the expected type's namespace, but the constant can be unfolded to yield another constant, then its namespace is consulted. This process is repeated until something other than an application of a constant is encountered, or until the constant can't be unfolded.

<a id="Leading--___"></a>
Leading `.` 

The expected type for `.replicate` is `List Unit`. This type's namespace is `List`, so `.replicate` resolves to `List.replicate`.

```proofscript
#eval show List Unit from .replicate 3 ()
```

```lean
[(), (), ()]
```

<a id="Leading--___--and-Unfolding-Definitions"></a>
Leading `.` and Unfolding Definitions 

The expected type for `.replicate` is `MyList Unit`. This type's namespace is `MyList`, but there is no definition `MyList.replicate`. Unfolding `MyList Unit` yields `List Unit`, so `.replicate` resolves to `List.replicate`.
<a id="MyList-_LPAR_in-Leading--___--and-Unfolding-Definitions_RPAR_"></a>


```proofscript
def MyList α := List α
#eval show MyList Unit from .replicate 3 ()
```

```lean
[(), (), ()]
```

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
"local"
```


### Display 2


```text
"inner"
```


### Display 3


```text
"A.B.C.x"
```


### Display 4


```text
"A.x"
```


### Display 5


```text
"longer"
```


### Display 6


```text
"B.x"
```


### Display 7


```text
Ambiguous term
  x
Possible interpretations:
  B.x : String
  
  A.x : String
```


### Display 8


```text
"C.x"
```


### Display 9


```text
[(), (), ()]
```

