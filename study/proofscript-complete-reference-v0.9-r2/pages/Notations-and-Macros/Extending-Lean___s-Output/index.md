<a id="unexpand-and-delab"></a>

# ProofScript — 23.8. Extending Lean's Output

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Use native notation, syntax categories, quotations, macros and elaborators in an explicitly declared extension environment. Macro hygiene preserves binding identity; a convenient generated name is not enough. Quoted parser code remains native code rather than being rewritten as ordinary surface expressions. Extensions produce syntax or candidate declarations and gain no independent proof authority.

**Compiler and coverage boundary.** Register collisions and lifted child slots explicitly. Do not globally rewrite strings, quoted grammar, tactic combinators or host code. Plugin operating-system permissions are separate from logical soundness.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Notations-and-Macros/Extending-Lean___s-Output/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Notations-and-Macros/Extending-Lean___s-Output/index.html). Source Git blob: `409cfda0f19f5a17e582055eddb05ce822296737`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 23.8. Extending Lean's Output

Extending Lean with new syntax and implementing the new syntax with macros and elaborators allows users to express ideas to Lean more conveniently. However, Lean is an *interactive* theorem prover: it is also important that the feedback it provides can be readily understood. Syntax extensions should be used in *output* as well as in *input*.

There are two primary mechanisms for instructing Lean to use a syntax extension in its output:

  Unexpanders

Unexpanders are the inverse of [macros](../Macros/index.md#--tech-term-Macros). Macros implement new syntax in terms of the old syntax by translation, *expanding* the new feature into encodings in pre-existing features. Like macros, 
<a id="--tech-term-unexpanders"></a>
*unexpanders* translate `Syntax` into `Syntax`; unlike macros, they transform the encodings into the new extensions.

  Delaborators

Delaborators are the inverse of [elaborators](../Elaborators/index.md#--tech-term-elaborators). While elaborators translate `Syntax` into the core type theory's `Expr`, 
<a id="--tech-term-delaborators"></a>
*delaborators* translate `Expr`s into `Syntax`.

Before an `Expr` is displayed, it is first delaborated and then unexpanded. The delaborator tracks the position in the original `Expr` that its output originated from; this position is encoded in the resulting syntax's `SourceInfo`. Just as macro expansion automatically annotates the resulting syntax with synthetic source information that correspond to the original syntax's position, the unexpansion mechanism preserves the resulting syntax's association with the underlying `Expr`. This association enables Lean's interactive features that provide information about the resulting syntax when it is shown in [proof states](../../Tactic-Proofs/index.md#--tech-term-proof-state) and diagnostics.

<a id="Unexpanders"></a>
### 23.8.1. Unexpanders

Just as macros are registered in a table that maps [syntax kinds](../Defining-New-Syntax/index.md#--tech-term-syntax-kind) to macro implementations, unexpanders are registered in a table that maps the names of constants to unexpander implementations. Before Lean displays syntax to users, it attempts to rewrite each application of a constant in the syntax according to this table. Occurrences of the context that are not applications are treated as applications with zero arguments.

Unexpansion proceeds from the inside out. The unexpander is passed the syntax of the application, with implicit arguments hidden, after the arguments have been unexpanded. If the option `pp.explicit` is `true` or `pp.notation` is `false`, then unexpanders are not used.

An unexpander has type `Lean.PrettyPrinter.Unexpander`, which is an abbreviation for `Syntax → Lean.PrettyPrinter.UnexpandM Syntax`. In the remainder of this section, the names `Unexpander` and `UnexpandM` are used unqualified. `UnexpandM` is a monad that supports quotation and failure via its `MonadQuotation` and `MonadExcept Unit` instances.

An unexpander should either return unexpanded syntax or fail using `throw ()`. If the unexpander succeeds, then the resulting syntax is unexpanded again; if it fails, then the next unexpander is tried. When no unexpander succeeds for the syntax, its child nodes are unexpanded until all opportunities for unexpansion are exhausted.

<a id="Lean___PrettyPrinter___Unexpander"></a>

**def**

```text
Lean.PrettyPrinter.Unexpander : Type
```

Function that tries to reverse macro expansions as a post-processing step of delaboration. While less general than an arbitrary delaborator, it can be declared without importing `Lean`. Used by the `[app_unexpander]` attribute.

<a id="Lean___PrettyPrinter___UnexpandM"></a>

**def**

```text
Lean.PrettyPrinter.UnexpandM (α : Type) : Type
```

The unexpander monad, essentially `Syntax → Option α`. The `Syntax` is the `ref`, and it has the possibility of failure without an error message.

An unexpander for a constant is registered by applying the `app_unexpander` attribute. [Custom operators](../Custom-Operators/index.md#operators) and [notations](../Notations/index.md#notations) automatically create unexpanders for the syntax that they introduce.

<a id="attr-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**attribute**

**Unexpander Registration**

<a id="Lean___Parser___Attr___simple-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
attr ::= ...
    | app_unexpander ident
```

Registers an unexpander of type `Unexpander` for applications of a constant.

<a id="Custom-Unit-Type"></a>
Custom Unit Type 

A type equivalent to `Unit`, but with its own notation, can be defined as a zero-field structure and a macro:
<a id="Solo-_LPAR_in-Custom-Unit-Type_RPAR_"></a>
<a id="Solo___mk-_LPAR_in-Custom-Unit-Type_RPAR_"></a>


```proofscript
structure Solo where
  mk ::

syntax "‹" "›" : term

macro_rules
  | `(term|‹›) => ``(Solo.mk)
```

While the new notation can be used to write theorem statements, it does not appear in proof states. For example, when proving that all values of type `Solo` are equal to `‹›`, the initial proof state is:

This proof state shows the constructor using [structure instance](../../The-Type-System/Inductive-Types/index.md#--tech-term-structure-instance) syntax. An unexpander can be used to override this choice. Because `Solo.mk` cannot be applied to any arguments, the unexpander is free to ignore the syntax, which will always be ```(Solo.mk)``.
<a id="unexpandSolo-_LPAR_in-Custom-Unit-Type_RPAR_"></a>


```proofscript
@[app_unexpander Solo.mk]
def unexpandSolo : Lean.PrettyPrinter.Unexpander
  | _ => `(‹›)
```

With this unexpander, the initial state of the proof now renders with the correct syntax:

<a id="Unexpansion-and-Arguments"></a>
Unexpansion and Arguments 

A `ListCursor` represents a position in a `List`. `ListCursor.before` contains the reversed list of elements prior to the position, and `ListCursor.after` contains the elements after the position.
<a id="ListCursor-_LPAR_in-Unexpansion-and-Arguments_RPAR_"></a>
<a id="ListCursor___before-_LPAR_in-Unexpansion-and-Arguments_RPAR_"></a>
<a id="ListCursor___after-_LPAR_in-Unexpansion-and-Arguments_RPAR_"></a>


```proofscript
structure ListCursor (α) where
  before : List α
  after : List α
deriving Repr
```

List cursors can be moved to the left or to the right:
<a id="ListCursor___left-_LPAR_in-Unexpansion-and-Arguments_RPAR_"></a>
<a id="ListCursor___right-_LPAR_in-Unexpansion-and-Arguments_RPAR_"></a>


```proofscript
def ListCursor.left : ListCursor α → Option (ListCursor α)
  | ⟨[], _⟩ => none
  | ⟨l :: ls, rs⟩ => some ⟨ls, l :: rs⟩

def ListCursor.right : ListCursor α → Option (ListCursor α)
  | ⟨_, []⟩ => none
  | ⟨ls, r :: rs⟩ => some ⟨r :: ls, rs⟩
```

They can also be moved all the way to the left or all the way to the right:
<a id="ListCursor___rewind-_LPAR_in-Unexpansion-and-Arguments_RPAR_"></a>
<a id="ListCursor___fastForward-_LPAR_in-Unexpansion-and-Arguments_RPAR_"></a>


```proofscript
def ListCursor.rewind : ListCursor α → ListCursor α
  | xs@⟨[], _⟩ => xs
  | ⟨l :: ls, rs⟩ => rewind ⟨ls, l :: rs⟩
termination_by xs => xs.before

def ListCursor.fastForward : ListCursor α → ListCursor α
  | xs@⟨_, []⟩ => xs
  | ⟨ls, r :: rs⟩ => fastForward ⟨r :: ls, rs⟩
termination_by xs => xs.after
```

However, the need to reverse the list of previous elements can make list cursors difficult to understand. A cursor can be given a notation in which a flag (`🚩`) marks the cursor's location in a list:

```proofscript
syntax "[" term,* " 🚩 " term,* "]": term
macro_rules
  | `([$ls,* 🚩 $rs,*]) =>
    ``(ListCursor.mk [$[$((ls : Array Lean.Term).reverse)],*] [$rs,*])
```

In the macro, the sequences of elements have type ``Syntax.TSepArray `term ","``. The type annotation as `Array Lean.Term` causes a coercion to fire so that `Array.reverse` can be applied, and a similar coercion reinserts the separating commas. These coercions are described in the section on [typed syntax](../Defining-New-Syntax/index.md#typed-syntax).

While the syntax works, it is not used in Lean's output:

```proofscript
#check [1, 2, 3 🚩 4, 5]
```

```lean
{ before := [3, 2, 1], after := [4, 5] } : ListCursor Nat
```

An unexpander solves this problem. The unexpander relies on the built-in unexpanders for list literals already having rewritten the two lists:
<a id="unexpandListCursor-_LPAR_in-Unexpansion-and-Arguments_RPAR_"></a>


```proofscript
@[app_unexpander ListCursor.mk]
def unexpandListCursor : Lean.PrettyPrinter.Unexpander
  | `($_ [$ls,*] [$rs,*]) =>
    `([$((ls : Array Lean.Term).reverse),* 🚩 $(rs),*])
  | _ => throw ()
```

```proofscript
#check [1, 2, 3 🚩 4, 5]
```

```lean
[1, 2, 3 🚩 4, 5] : ListCursor Nat
```

```proofscript
#reduce [1, 2, 3 🚩 4, 5].right
```

```lean
some [1, 2, 3, 4 🚩 5]
```

```proofscript
#reduce [1, 2, 3 🚩 4, 5].left >>= (·.left)
```

```lean
some [1 🚩 2, 3, 4, 5]
```

<a id="delaborators"></a>
### 23.8.2. Delaborators

A delaborator is function of type `Lean.PrettyPrinter.Delaborator.Delab`, which is an abbreviation for `Lean.PrettyPrinter.Delaborator.DelabM Term`. Unlike unexpanders, delaborators are not implemented as functions. This is to make it easier to implement them correctly: the monad `DelabM` tracks the current position in the expression that's being delaborated so the delaboration mechanism can annotate the resulting syntax.

Delaborators are registered with the `delab` attribute. An internal table maps the names of the constructors of `Expr` (without namespaces) to delaborators. Additionally, the name `app.` c is consulted to find delaborators for applications of the constant c, and the name `mdata.` k is consulted to find delaborators for `Expr.mdata` constructors with a single key k in their metadata.

<a id="attr-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**attribute**

**Delaborator Registration**

The `delab` attribute registers a delaborator for the indicated constructor or metadata key of `Expr`.

<a id="Lean___Parser___Attr___simple-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
attr ::= ...
    | delab ident
```

The `app_delab` attribute registers a delaborator for applications of the indicated constant after [resolving](../../Terms/Identifiers/index.md#--tech-term-resolving) it in the current [scope](../../Namespaces-and-Sections/index.md#--tech-term-section-scope).

<a id="Lean___PrettyPrinter___Delaborator___attrApp_delab_"></a>

```ebnf
attr ::= ...
    | app_delab ident
```

The monad `DelabM` is a [reader monad](../../Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#--tech-term-Reader-monads) that includes access to the current position in the `Expr`. Recursive delaboration is performed by adjusting the reader monad's tracked position, rather than by explicitly passing a subexpression to another function. The most important functions for working with subexpressions in delaborators are in the namespace `Lean.PrettyPrinter.Delaborator.SubExp`:

- `getExpr` retrieves the current expression for analysis.
- `withAppFn` adjusts the current position to be that of the function in an application.
- `withAppArg` adjusts the current position to be that of the argument in an application
- `withAppFnArgs` decomposes the current expression into a non-application function and its arguments, focusing on each.
- `withBindingBody` descends into the body of a function or function type.

Further functions to descend into the remaining constructors of `Expr` are available.

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
`@[app_delab c]` registers a delaborator for applications with head constant `c`.
Such delaborators also apply to the constant `c` itself (known as a "nullary application").

This attribute should be applied to definitions of type `Lean.PrettyPrinter.Delaborator.Delab`.

When defining delaborators for constant applications, one should prefer this attribute over `@[delab app.c]`,
as `@[app_delab c]` first performs name resolution on `c` in the current scope.
```


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
{ before := [3, 2, 1], after := [4, 5] } : ListCursor Nat
```


### Display 2


```text
[1, 2, 3 🚩 4, 5] : ListCursor Nat
```


### Display 3


```text
some [1, 2, 3, 4 🚩 5]
```


### Display 4


```text
some [1 🚩 2, 3, 4, 5]
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
v:Solo⊢ v = { }
```


### Display 2


```text
v:Solo⊢ v = ‹›
```

