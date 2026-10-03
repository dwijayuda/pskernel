<a id="elaborators"></a>

# ProofScript — 23.6. Elaborators

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Use native notation, syntax categories, quotations, macros and elaborators in an explicitly declared extension environment. Macro hygiene preserves binding identity; a convenient generated name is not enough. Quoted parser code remains native code rather than being rewritten as ordinary surface expressions. Extensions produce syntax or candidate declarations and gain no independent proof authority.

**Compiler and coverage boundary.** Register collisions and lifted child slots explicitly. Do not globally rewrite strings, quoted grammar, tactic combinators or host code. Plugin operating-system permissions are separate from logical soundness.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Notations-and-Macros/Elaborators/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Notations-and-Macros/Elaborators/index.html). Source Git blob: `119b7c8841c183dbc05b7f74621e31ff129a905c`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 23.6. Elaborators

## See Also

- Elaborators process [new syntax extensions](../Defining-New-Syntax/index.md#syntax-ext).
- [Quotation patterns](../Macros/index.md#quote-patterns) are the most typical way to destructure syntax.

While macros allow Lean to be extended by translating new syntax into existing syntax, 
<a id="--tech-term-elaborators"></a>
*elaborators* allow the new syntax to be processed directly. Elaborators have access to everything that Lean itself uses to implement each feature of the language. Defining a new elaborator allows a language extension to be just as powerful as any built-in feature of Lean.

Elaborators come in two varieties:

- <a id="--tech-term-Command-elaborators"></a>
  *Command elaborators* are used to add new commands to Lean. Commands are implemented as side effects: they may add new constants to the global environment, extend compile-time tables such as the one that tracks [instances](../../Type-Classes/index.md#--tech-term-instances), they can provide feedback in the form of information, warnings, or errors, and they have full access to the `IO` monad. Command elaborators are associated with the [syntax kinds](../../Elaboration-and-Compilation/index.md#--tech-term-kind) that they can handle.
- <a id="--tech-term-Term-elaborators"></a>
  *Term elaborators* are used to implement new terms by translating the syntax into Lean's core type theory. They can do everything that command elaborators can do, and they additionally have access to the local context in which the term is being elaborated. Term elaborators can look up bound variables, bind new variables, unify two terms, and much more. A term elaborator must return a value of type `Lean.Expr`, which is the AST of the core type theory.

This section provides an overview and a few examples of elaborators. Because Lean's own elaborator uses the same tools, the source code of the elaborator is a good source of further examples. Just like macros, multiple elaborators may be associated with a syntax kind; they are tried in order, and elaborators may delegate to the next elaborator in the table by throwing the `unsupportedSyntax` exception.

<a id="command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Elaboration Rules**

The [`elab_rules`](index.md#Lean___Parser___Command___elab_rules) command takes a sequence of elaboration rules, specified as syntax pattern matches, and adds each as an elaborator. The rules are attempted in order, before previously-defined elaborators, and later elaborators may add further options.

<a id="Lean___Parser___Command___elab_rules"></a>

```ebnf
command ::= ...
    | docComment?
      (@[attrInstance,*])?
      attrKind elab_rules ((kind := ident))? (: ident)? (<= ident)?
        (| `((p:ident|)?Suitable syntax for p ) => term)*
```

Commands, terms, and tactics each maintain a table that maps syntax kinds to elaborators. The syntax category for which the elaborator should be used is specified after the colon, and must be `term`, `command`, or `tactic`. The [`<=`](index.md#Lean___Parser___Command___elab_rules) binds the provided identifier to the current expected type in the context in which a term is being elaborated; it may only be used for term elaborators, and if present, then `term` is implied as the syntax category.

<a id="attr-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**attribute**

**Elaborator Attribute**

Elaborators can be directly associated with syntax kinds by applying the appropriate attributes. Each takes the name of a syntax kind and associates the definition with the kind.

<a id="Lean___Parser___Attr___simple-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
attr ::= ...
    | term_elab (prio
       | ident)
```

<a id="Lean___Parser___Attr___simple-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
attr ::= ...
    | command_elab (prio
       | ident)
```

<a id="Lean___Parser___Attr___simple-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
attr ::= ...
    | tactic (prio
       | ident)
```

<a id="The-Lean-Language-Reference--Notations-and-Macros--Elaborators--Command-Elaborators"></a>
### 23.6.1. Command Elaborators

A command elaborator has type `CommandElab`, which is an abbreviation for `Syntax → CommandElabM Unit`. Command elaborators may be implicitly defined using [`elab_rules`](index.md#Lean___Parser___Command___elab_rules), or explicitly by defining a function and applying the `command_elab` attribute.

<a id="Querying-the-Environment"></a>
Querying the Environment 

A command elaborator can be used to query the environment to discover how many constants have a given name. This example uses `getEnv` from the `MonadEnv` class to get the current environment. `Environment.constants` yields a mapping from names to information about them (e.g. their type and whether they are a definition, [inductive type](../../The-Type-System/Inductive-Types/index.md#--tech-term-Inductive-types) declaration, etc). `logInfoAt` allows informational output to be associated with syntax from the original program, and a [token antiquotation](../Macros/index.md#--tech-term-token-antiquotations) is used to implement the Lean convention that output from interactive commands is associated with their keyword.

```proofscript
syntax "#count_constants " ident : command

elab_rules : command
  | `(#count_constants%$tok $x) => do
    let pattern := x.getId
    let env ← getEnv
    let mut count : Nat := 0
    for (y, _) in env.constants do
      if pattern.isSuffixOf y then
        count := count + 1
    logInfoAt tok m!"Found {count} instances of '{pattern}'"
```

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="interestingName-_LPAR_in-Querying-the-Environment_RPAR_"></a>
<a id="NS___interestingName-_LPAR_in-Querying-the-Environment_RPAR_"></a>


```proofscript
const interestingName := 55
const NS.interestingName := "Another one"

#count_constants interestingName
```

```lean
Found 2 instances of 'interestingName'
```

<a id="The-Lean-Language-Reference--Notations-and-Macros--Elaborators--Term-Elaborators"></a>
### 23.6.2. Term Elaborators

A term elaborator has type `TermElab`, which is an abbreviation for `Syntax → Option Expr → TermElabM Expr`. The optional `Expr` parameter is the type expected for the term being elaborated, which is `none` if no type is yet known. Like command elaborators, term elaborators may be implicitly defined using [`elab_rules`](index.md#Lean___Parser___Command___elab_rules), or explicitly by defining a function and applying the `term_elab` attribute.

<a id="Avoiding-a-Type"></a>
Avoiding a Type 

This examples demonstrates an elaborator for syntax that is the opposite of a type ascription. The provided term may have any type *other* than the one indicated, and metavariables are solved pessimistically. In this example, `elabType` invokes the term elaborator and then ensures that the resulting term is a type. `Meta.inferType` infers a type for a term, and `Meta.isDefEq` attempts to make two terms [definitionally equal](../../The-Type-System/index.md#--tech-term-definitional-equality) by unification, returning `true` if it succeeds.
<a id="notType-_LPAR_in-Avoiding-a-Type_RPAR_"></a>
<a id="elabNotType-_LPAR_in-Avoiding-a-Type_RPAR_"></a>


```proofscript
syntax (name := notType) "(" term  " !: " term ")" : term

@[term_elab notType]
def elabNotType : TermElab := fun stx _ => do
  let `(($tm:term !: $ty:term)) := stx
    | throwUnsupportedSyntax
  let unexpected ← elabType ty
  let e ← elabTerm tm none
  let eTy ← Meta.inferType e
  if (← Meta.isDefEq eTy unexpected) then
    throwErrorAt tm m!"Got unwanted type {eTy}"
  else pure e
```

If the type position does not contain a type, then `elabType` throws an error:

```proofscript
#eval ([1, 2, 3] !: "not a type")
```

```lean
type expected, got
  ("not a type" : String)
```

If the term's type is definitely not equal to the provided type, then elaboration succeeds:

```proofscript
#eval ([1, 2, 3] !: String)
```

```lean
[1, 2, 3]
```

If the types match, an error is thrown:

```proofscript
#eval (5 !: Nat)
```

```lean
Got unwanted type Nat
```

The type equality check may fill in missing information, so `sorry` (which may have any type) is also rejected:

```proofscript
#eval (sorry !: String)
```

```lean
Got unwanted type String
```

<a id="Using-Any-Local-Variable"></a>
Using Any Local Variable 

Term elaborators have access to the expected type and to the local context. This can be used to create a term analogue of the `assumption` tactic.

The first step is to access the local context using `getLocalHyps`. It returns the context with the outermost bindings on the left, so it is traversed in reverse order. For each local assumption, a type is inferred with `Meta.inferType`. If it can be equal to the expected type, then the assumption is returned; if no assumption is suitable, then an error is produced.

```proofscript
syntax "anything!" : term

elab_rules <= expected
  | `(anything!) => do
    let hyps ← getLocalHyps
    for h in hyps.reverse do
      let t ← Meta.inferType h
      if (← Meta.isDefEq t expected) then return h

    throwError m!"No assumption in {hyps} has type {expected}"
```

The new syntax finds the function's bound variable:

```proofscript
#eval (fun (n : Nat) => 2 + anything!) 5
```

```lean
7
```

It chooses the most recent suitable variable, as desired:

```proofscript
#eval
  let x := "x"
  let y := "y"
  "It was " ++ anything!
```

```lean
"It was y"
```

When no assumption is suitable, it returns an error that describes the attempt:

```proofscript
#eval
  let x := Nat.zero
  let y := "hello"
  fun (f : Nat → Nat) =>
    (anything! : Int → Int)
```

```lean
No assumption in [x, y, f] has type Int → Int
```

Because it uses unification, the natural number literal is chosen here, because numeric literals may have any type with an `OfNat` instance. Unfortunately, there is no `OfNat` instance for functions, so instance synthesis later fails.

```proofscript
#eval
  let x := 5
  let y := "hello"
  (anything! : Int → Int)
```

```lean
failed to synthesize instance of type class
  OfNat (Int → Int) 5
numerals are polymorphic in Lean, but the numeral `5` cannot be used in a context where the expected type is
  Int → Int
due to the absence of the instance above

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```

<a id="The-Lean-Language-Reference--Notations-and-Macros--Elaborators--Custom-Tactics"></a>
### 23.6.3. Custom Tactics

Custom tactics are described in the [section on tactics](../../Tactic-Proofs/Custom-Tactics/index.md#custom-tactics).

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
Syntax quotation for terms.
```


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Found 2 instances of 'interestingName'
```


### Display 2


```text
type expected, got
  ("not a type" : String)
```


### Display 3


```text
[1, 2, 3]
```


### Display 4


```text
Got unwanted type Nat
```


### Display 5


```text
Got unwanted type String
```


### Display 6


```text
7
```


### Display 7


```text
"It was y"
```


### Display 8


```text
No assumption in [x, y, f] has type Int → Int
```


### Display 9


```text
failed to synthesize instance of type class
  OfNat (Int → Int) 5
numerals are polymorphic in Lean, but the numeral `5` cannot be used in a context where the expected type is
  Int → Int
due to the absence of the instance above

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```

