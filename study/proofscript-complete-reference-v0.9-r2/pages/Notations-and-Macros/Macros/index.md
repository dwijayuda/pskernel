<a id="macros"></a>

# ProofScript — 23.5. Macros

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Use native notation, syntax categories, quotations, macros and elaborators in an explicitly declared extension environment. Macro hygiene preserves binding identity; a convenient generated name is not enough. Quoted parser code remains native code rather than being rewritten as ordinary surface expressions. Extensions produce syntax or candidate declarations and gain no independent proof authority.

**Compiler and coverage boundary.** Register collisions and lifted child slots explicitly. Do not globally rewrite strings, quoted grammar, tactic combinators or host code. Plugin operating-system permissions are separate from logical soundness.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Notations-and-Macros/Macros/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Notations-and-Macros/Macros/index.html). Source Git blob: `92a98002362f233aa7d91bfbe27e3caeeea708b8`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 23.5. Macros

<a id="--tech-term-Macros"></a>
*Macros* are transformations from `Syntax` to `Syntax` that occur during [elaboration](../Elaborators/index.md#--tech-term-elaborators) and during [tactic execution](../../Tactic-Proofs/Custom-Tactics/index.md#tactic-macros). Replacing syntax with the result of transforming it with a macro is called 
<a id="--tech-term-macro-expansion"></a>
*macro expansion*. Multiple macros may be associated with a single [syntax kind](../Defining-New-Syntax/index.md#--tech-term-syntax-kind), and they are attempted in order of definition. Macros are run in a [monad](../../Functors___-Monads-and--do--Notation/index.md#--tech-term-Monad) that has access to some compile-time metadata and has the ability to either emit an error message or to delegate to subsequent macros, but the macro monad is much less powerful than the elaboration monads.

Macros are associated with [syntax kinds](../Defining-New-Syntax/index.md#--tech-term-syntax-kind). An internal table maps syntax kinds to macros of type `Syntax → MacroM Syntax`. Macros delegate to the next entry in the table by throwing the `unsupportedSyntax` exception. A given `Syntax` value *is a macro* when there is a macro associated with its syntax kind that does not throw `unsupportedSyntax`. If a macro throws any other exception, an error is reported to the user. [Syntax categories](../Defining-New-Syntax/index.md#--tech-term-syntax-categories) are irrelevant to macro expansion; however, because each syntax kind is typically associated with a single syntax category, they do not interfere in practice.

<a id="Macro-Error-Reporting"></a>
Macro Error Reporting 

The following macro reports an error when its parameter is the literal numeral five. It expands to its argument in all other cases.

```proofscript
syntax &"notFive" term:arg : term
open Lean in
macro_rules
  | `(term|notFive 5) =>
    Macro.throwError "'5' is not allowed here"
  | `(term|notFive $e) =>
    pure e
```

When applied to terms that are not syntactically the numeral five, elaboration succeeds:

```proofscript
#eval notFive (2 + 3)
```

```lean
5
```

When the error case is triggered, the user receives an error message:

```proofscript
#eval notFive 5
```

```lean
'5' is not allowed here
```

Before elaborating a piece of syntax, the elaborator checks whether its [syntax kind](../Defining-New-Syntax/index.md#--tech-term-syntax-kind) has macros associated with it. These are attempted in order. If a macro succeeds, potentially returning syntax with a different kind, the check is repeated and macros are expanded again until the outermost layer of syntax is no longer a macro. Elaboration or tactic execution can then proceed. Only the outermost layer of syntax (typically a `node`) is expanded, and the output of macro expansion may contain nested syntax that is a macro. These nested macros are expanded in turn when the elaborator reaches them.

In particular, macro expansion occurs in three situations in Lean:

1. During term elaboration, macros in the outermost layer of the syntax to be elaborated are expanded prior to invoking the [syntax's term elaborator](../Elaborators/index.md#elaborators).
2. During command elaboration, macros in the outermost layer of the syntax to be elaborated are expanded prior to invoking the [syntax's command elaborator](../Elaborators/index.md#elaborators).
3. During tactic execution, macros in the outermost layer of the syntax to be elaborated are expanded [prior to executing the syntax as a tactic](../../Tactic-Proofs/Custom-Tactics/index.md#tactic-macros).

<a id="macro-hygiene"></a>
### 23.5.1. Hygiene

A macro is 
<a id="--tech-term-hygienic"></a>
*hygienic* if its expansion cannot result in identifier capture. 
<a id="--tech-term-Identifier-capture"></a>
Identifier capture is when an identifier ends up referring to a binding site other than that which is in scope where the identifier occurs in the source code. There are two types of identifier capture:

- If a macro's expansion introduces binders, then identifiers that are parameters to the macro may end up referring to the introduced binders if their names happen to match.
- If a macro's expansion is intended to refer to a name, but the macro is used in a context that either locally binds this name or in which a new global name has been introduced, it may end up referring to the wrong name.

The first kind of variable capture can be avoided by ensuring that every binding introduced by a macro uses a freshly generated, globally-unique name, while the second can be avoided by always using fully-qualified names to refer to constants. The fresh names must be generated again at each invocation of the macro to avoid variable capture in recursive macros. These techniques are error-prone. Variable capture issues are difficult to test for because they rely on coincidences of name choices, and consistently applying these techniques results in noisy code.

Lean features automatic hygiene: in almost all cases, macros are automatically hygienic. Capture by introduced bindings is avoided by annotating identifiers introduced by a macro with 
<a id="--tech-term-macro-scopes"></a>
*macro scopes*, which uniquely identify each invocation of macro expansion. If the binding and the use of the identifier have the same macro scopes, then they were introduced by the same step of macro expansion and should refer to one another. Similarly, uses of global names in code generated by a macro are not captured by local bindings in the context in which they are expanded because these use sites have macro scopes that are not present in the binding occurrence. Capture by newly-introduced global names is prevented by annotating potential global name references with the set of global names that match at quotation time in code produced in the macro's body. Identifiers annotated with potential referents are called 
<a id="--tech-term-pre-resolved-identifiers"></a>
*pre-resolved identifiers*, and the `Syntax.Preresolved` field on the `Syntax.ident` constructor is used to store the potential referents. During elaboration, if an identifier has pre-resolved global names associated with it, then other global names are not considered as valid reference targets.

The introduction of macro scopes and pre-resolved identifiers to generated syntax occurs during [quotation](index.md#--tech-term-Quotation). Macros that construct syntax by other means than quotation should also ensure hygiene by some other means. For more details on Lean's hygiene algorithm, please consult Ullrich and de Moura (2020)Sebastian Ullrich and Leonardo de Moura, 2020. “Beyond notations: Hygienic macro expansion for theorem proving languages”. In *Proceedings of the International Joint Conference on Automated Reasoning.* and Ullrich (2023)Sebastian Ullrich, 2023. *[An Extensible Theorem Proving Frontend](https://www.lean-lang.org/papers/thesis-sebastian.pdf)*. Dr. Ing. dissertation, Karlsruhe Institute of Technology.

<a id="macro-monad"></a>
### 23.5.2. The Macro Monad

The macro monad `MacroM` is sufficiently powerful to implement hygiene and report errors. Macro expansion does not have the ability to modify the environment directly, to carry out unification, to examine the current local context, or to do anything else that only makes sense in one particular context. This allows the same macro mechanism to be used throughout Lean, and it makes macros much easier to write than [elaborators](../Elaborators/index.md#--tech-term-elaborators).

<a id="Lean___MacroM"></a>

**def**

```text
Lean.MacroM (α : Type) : Type
```

The `MacroM` monad is the main monad for macro expansion. It has the information needed to handle hygienic name generation, and is the monad that `macro` definitions live in.

Notably, this is a (relatively) pure monad: there is no `IO` and no access to the `Environment`. That means that things like declaration lookup are impossible here, as well as `IO.Ref` or other side-effecting operations. For more capabilities, macros can instead be written as `elab` using `adaptExpander`.

<a id="Lean___Macro___expandMacro___"></a>

**def**

```text
Lean.Macro.expandMacro? (stx : Lean.Syntax) :
  Lean.MacroM (Option Lean.Syntax)
```

`expandMacro? stx` returns `some stxNew` if `stx` is a macro, and `stxNew` is its expansion.

<a id="Lean___Macro___trace"></a>

**def**

```text
Lean.Macro.trace (clsName : Lean.Name) (msg : String) : Lean.MacroM Unit
```

Add a new trace message, with the given trace class and message.

<a id="macro-exceptions"></a>
#### 23.5.2.1. Exceptions and Errors

The `unsupportedSyntax` exception is used for control flow during macro expansion. It indicates that the current macro is incapable of expanding the received syntax, but that an error has not occurred. The exceptions thrown by `throwError` and `throwErrorAt` terminate macro expansion, reporting the error to the user.

<a id="Lean___Macro___throwUnsupported"></a>

**def**

```text
Lean.Macro.throwUnsupported {α : Type} : Lean.MacroM α
```

Throw an `unsupportedSyntax` exception.

<a id="Lean___Macro___Exception___unsupportedSyntax"></a>

**constructor of Lean.Macro.Exception**

```text
Lean.Macro.Exception.unsupportedSyntax : Lean.Macro.Exception
```

An unsupported syntax exception. We keep this separate because it is used for control flow: if one macro does not support a syntax then we try the next one.

<a id="Lean___Macro___throwError"></a>

**def**

```text
Lean.Macro.throwError {α : Type} (msg : String) : Lean.MacroM α
```

Throw an error with the given message, using the `ref` for the location information.

<a id="Lean___Macro___throwErrorAt"></a>

**def**

```text
Lean.Macro.throwErrorAt {α : Type} (ref : Lean.Syntax) (msg : String) :
  Lean.MacroM α
```

Throw an error with the given message and location information.

<a id="macro-monad-hygiene"></a>
#### 23.5.2.2. Hygiene-Related Operations

[Hygiene](index.md#--tech-term-hygienic) is implemented by adding [macro scopes](index.md#--tech-term-macro-scopes) to the identifiers that occur in syntax. Ordinarily, the process of [quotation](index.md#--tech-term-Quotation) adds all necessary scopes, but macros that construct syntax directly must add macro scopes to the identifiers that they introduce.

<a id="Lean___Macro___withFreshMacroScope"></a>

**def**

```text
Lean.Macro.withFreshMacroScope {α : Type} (x : Lean.MacroM α) :
  Lean.MacroM α
```

Increments the macro scope counter so that inside the body of `x` the macro scope is fresh.

<a id="Lean___Macro___addMacroScope"></a>

**def**

```text
Lean.Macro.addMacroScope (n : Lean.Name) : Lean.MacroM Lean.Name
```

Add a new macro scope to the name `n`.

<a id="macro-environment"></a>
#### 23.5.2.3. Querying the Environment

Macros have only limited support for querying the environment. They can check whether a constant exists and resolve names, but further introspection is unavailable.

<a id="Lean___Macro___hasDecl"></a>

**def**

```text
Lean.Macro.hasDecl (declName : Lean.Name) : Lean.MacroM Bool
```

Returns `true` if the environment contains a declaration with name `declName`

<a id="Lean___Macro___getCurrNamespace"></a>

**def**

```text
Lean.Macro.getCurrNamespace : Lean.MacroM Lean.Name
```

Gets the current namespace given the position in the file.

<a id="Lean___Macro___resolveNamespace"></a>

**def**

```text
Lean.Macro.resolveNamespace (n : Lean.Name) :
  Lean.MacroM (List Lean.Name)
```

Resolves the given name to an overload list of namespaces.

<a id="Lean___Macro___resolveGlobalName"></a>

**def**

```text
Lean.Macro.resolveGlobalName (n : Lean.Name) :
  Lean.MacroM (List (Lean.Name × List String))
```

Resolves the given name to an overload list of global definitions. The `List String` in each alternative is the deduced list of projections (which are ambiguous with name components).

Remark: it will not trigger actions associated with reserved names. Recall that Lean has reserved names. For example, a definition `foo` has a reserved name `foo.def` for theorem containing stating that `foo` is equal to its definition. The action associated with `foo.def` automatically proves the theorem. At the macro level, the name is resolved, but the action is not executed. The actions are executed by the elaborator when converting `Syntax` into `Expr`.

<a id="quotation"></a>
### 23.5.3. Quotation

<a id="--tech-term-Quotation"></a>
*Quotation* marks code for representation as data of type `Syntax`. Quoted code is parsed, but not elaborated—while it must be syntactically correct, it need not make sense. Quotation makes it much easier to programmatically generate code: rather than reverse-engineering the specific nesting of `node` values that Lean's parser would produce, the parser can be directly invoked to create them. This is also more robust in the face of refactoring of the grammar that may change the internals of the parse tree without affecting the user-visible concrete syntax. Quotation in Lean is surrounded by ```(`` and `)`.

The syntactic category or parser being quoted may be indicated by placing its name after the opening backtick and parenthesis, followed by a vertical bar (`|`). As a special case, the name `tactic` may be used to parse either tactics or sequences of tactics. If no syntactic category or parser is provided, Lean attempts to parse the quotation both as a term and as a non-empty sequence of commands. Term quotations have higher priority than command quotations, so in cases of ambiguity, the interpretation as a term is chosen; this can be overridden by explicitly indicating that the quotation is of a command sequence.

<a id="Term-vs-Command-Quotation-Syntax"></a>
Term vs Command Quotation Syntax 

In the following example, the contents of the quotation could either be a function application or a sequence of commands. Both match the same region of the file, so the [local longest-match rule](../Custom-Operators/index.md#--tech-term-local-longest-match-rule) is not relevant. Term quotation has a higher priority than command quotation, so the quotation is interpreted as a term. Terms expect their [antiquotations](index.md#--tech-term-antiquotations) to have type ``TSyntax `term`` rather than ``TSyntax `command``.

```proofscript
example (cmd1 cmd2 : TSyntax `command) : MacroM (TSyntax `command) :=
  `($cmd1 $cmd2)
```

The result is two type errors like the following:

```lean
Application type mismatch: The argument
  cmd1
has type
  TSyntax `command
but is expected to have type
  TSyntax `term
in the application
  cmd1.raw
```

The type of the quotation (``MacroM (TSyntax `command)``) is not used to select a result because syntax priorities are applied prior to elaboration. In this case, specifying that the antiquotations are commands resolves the ambiguity because function application would require terms in these positions:

```proofscript
example (cmd1 cmd2 : TSyntax `command) : MacroM (TSyntax `command) :=
  `($cmd1:command $cmd2:command)
```

Similarly, inserting a command into the quotation eliminates the possibility that it could be a term:

```proofscript
example (cmd1 cmd2 : TSyntax `command) : MacroM (TSyntax `command) :=
  `($cmd1 $cmd2 #eval "hello!")
```

<a id="term-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Quotations**

Lean's syntax includes quotations for terms, commands, tactics, and sequences of tactics, as well as a general quotation syntax that allows any input that Lean can parse to be quoted. Term quotations have the highest priority, followed by tactic quotations, general quotations, and finally command quotations.

<a id="Manual___FreeSyntax___more-next-next"></a>

```ebnf
term ::=
      `(term)
    | `(command+)
    | `(tactic|tactic)
    | `(tactic|tactic;*)
    | `(p:ident|Parse a p here )
```

Rather than having type `Syntax`, quotations are monadic actions with type `m Syntax`. Quotation is monadic because it implements [hygiene](index.md#--tech-term-hygienic) by adding [macro scopes](index.md#--tech-term-macro-scopes) and pre-resolving identifiers, as described in [the section on hygiene](index.md#macro-hygiene). The specific monad to be used is an implicit parameter to the quotation, and any monad for which there is an instance of the `MonadQuotation` type class is suitable. `MonadQuotation` extends `MonadRef`, which gives the quotation access to the source location of the syntax that the macro expander or elaborator is currently processing. `MonadQuotation` additionally includes the ability to add [macro scopes](index.md#--tech-term-macro-scopes) to identifiers and use a fresh macro scope for a sub-task. Monads that support quotation include `MacroM`, `TermElabM`, `CommandElabM`, and `TacticM`.

<a id="quasiquotation"></a>
#### 23.5.3.1. Quasiquotation

<a id="--tech-term-Quasiquotation"></a>
*Quasiquotation* is a form of quotation that may contain 
<a id="--tech-term-antiquotations"></a>
*antiquotations*, which are regions of the quotation that are not quoted, but instead are expressions that are evaluated to yield syntax. A quasiquotation is essentially a template; the outer quoted region provides a fixed framework that always yields the same outer syntax, while the antiquotations yield the parts of the final syntax that vary. All quotations in Lean are quasiquotations, so no special syntax is needed to distinguish quasiquotations from other quotations. The quotation process does not add macro scopes to identifiers that are inserted via antiquotations, because these identifiers either come from another quotation (in which case they already have macro scopes) or from the macro's input (in which case they should not have macro scopes, because they are not introduced by the macro).

Basic antiquotations consist of a dollar sign (`$`) immediately followed by an identifier. This means that the value of the corresponding variable, which should be a syntax tree, is to be substituted into this position of the quoted syntax. Entire expressions may be used as antiquotations by wrapping them in parentheses.

Lean's parser assigns every antiquotation a syntax category based on what the parser expects at the given position. If the parser expects syntax category `c`, then the antiquotation's type is `TSyntax c`.

Some syntax categories can be matched by elements of other categories. For example, numeric and string literals are valid terms in addition to being their own syntax categories. Antiquotations may be annotated with the expected category by suffixing them with a colon and the category name, which causes the parser to validate that the annotated category is acceptable in the given position and construct any intermediate layers that are required in the parse tree.

<a id="antiquot"></a>

**syntax**

**Antiquotations**

<a id="Manual___FreeSyntax___more-next-next-next"></a>

```ebnf
antiquot ::=
      $ident(:ident)?
    | $(term)(:ident)?
```

Whitespace is not permitted between the dollar sign ('$') that initiates an antiquotation and the identifier or parenthesized term that follows. Similarly, no whitespace is permitted around the colon that annotates the syntax category of the antiquotation.

<a id="Quasiquotation"></a>
Quasiquotation 

Both forms of antiquotation are used in this example. Because natural numbers are not syntax, `quote` is used to transform a number into syntax that represents it.

```proofscript
open Lean in
example [Monad m] [MonadQuotation m] (x : Term) (n : Nat) : m Syntax :=
  `($x + $(quote (n + 2)))
```

<a id="Antiquotation-Annotations"></a>
Antiquotation Annotations 

This example requires that `m` is a monad that can perform quotation.

```proofscript
variable {m : Type → Type} [Monad m] [MonadQuotation m]
```

By default, the antiquotation `$e` is expected to be a term, because that's the syntactic category that's immediately expected as the second argument to addition.
<a id="ex1-_LPAR_in-Antiquotation-Annotations_RPAR_"></a>


```proofscript
def ex1 (e) := show m _ from `(2 + $e)
#check ex1
```

```lean
ex1 {m : Type → Type} [Monad m] [MonadQuotation m] (e : TSyntax `term) : m (TSyntax `term)
```

Annotating `$e` as a numeric literal succeeds, because numeric literals are also valid terms. The expected type of the parameter `e` changes to ``TSyntax `num``.
<a id="ex2-_LPAR_in-Antiquotation-Annotations_RPAR_"></a>


```proofscript
def ex2 (e) := show m _ from `(2 + $e:num)
#check ex2
```

```lean
ex2 {m : Type → Type} [Monad m] [MonadQuotation m] (e : TSyntax `num) : m (TSyntax `term)
```

Spaces are not allowed between the dollar sign and the identifier.

```lean
def ex2 (e) := show m _ from `(2 + $ e:num)
```

```lean
<example>:1:34-1:36: unexpected token '$'; expected '`(tactic|', 'do' or no space before spliced term
```

Spaces are also not allowed before the colon:

```lean
def ex2 (e) := show m _ from `(2 + $e :num)
```

```lean
<example>:1:37-1:39: unexpected token ':'; expected ')'
```

<a id="Expanding-Quasiquotation"></a>
Expanding Quasiquotation 

Printing the definition of `f` demonstrates the expansion of a quasiquotation.
<a id="f-_LPAR_in-Expanding-Quasiquotation_RPAR_"></a>


```proofscript
open Lean in
def f [Monad m] [MonadQuotation m]
    (x : Term) (n : Nat) : m Syntax :=
  `(fun k => $x + $(quote (n + 2)) + k)
#print f
```

```lean
def f : {m : Type → Type} → [Monad m] → [Lean.MonadQuotation m] → Lean.Term → Nat → m Syntax :=
fun {m} [Monad m] [Lean.MonadQuotation m] x n => do
  let info ← Lean.MonadRef.mkInfoFromRefPos
  let scp ← Lean.getCurrMacroScope
  let quotCtx ← Lean.MonadQuotation.getContext
  pure
      {
          raw :=
            Syntax.node2 info `Lean.Parser.Term.fun (Syntax.atom info "fun")
              (Syntax.node4 info `Lean.Parser.Term.basicFun
                (Syntax.node1 info `null (Syntax.ident info "k".toRawSubstring' (Lean.addMacroScope quotCtx `k scp) []))
                (Syntax.node info `null #[]) (Syntax.atom info "=>")
                (Syntax.node3 info `«term_+_»
                  (Syntax.node3 info `«term_+_» x.raw (Syntax.atom info "+") (Lean.quote `term (n + 2)).raw)
                  (Syntax.atom info "+")
                  (Syntax.ident info "k".toRawSubstring' (Lean.addMacroScope quotCtx `k scp) []))) }.raw
```

In this output, the quotation is a [`do`](../../Functors___-Monads-and--do--Notation/Syntax/index.md#Lean___Parser___Term___do) block. It begins by constructing the source information for the resulting syntax, obtained by querying the compiler about the current user syntax being processed. It then obtains the current macro scope and the name of the module being processed, because macro scopes are added with respect to a module to enable independent compilation and avoid the need for a global counter. It then constructs a node using helpers such as `Syntax.node1` and `Syntax.node2`, which create a `Syntax.node` with the indicated number of children. The macro scope is added to each identifier, and `TSyntax.raw` is used to extract the contents of typed syntax wrappers. The antiquotations of `x` and `quote (n + 2)` occur directly in the expansion, as parameters to `Syntax.node3`.

<a id="splices"></a>
#### 23.5.3.2. Splices

In addition to including other syntax via antiquotations, quasiquotations can include 
<a id="--tech-term-splices"></a>
*splices*. Splices indicate that the elements of an array are to be inserted in order. The repeated elements may include separators, such as the commas between list or array elements. Splices may consist of an ordinary antiquotation with a 
<a id="--tech-term-splice-suffix"></a>
*splice suffix*, or they may be 
<a id="--tech-term-extended-splices"></a>
*extended splices* that provide additional repeated structure.

Splice suffixes consist of either an asterisk or a valid atom followed by an asterisk (`*`). Suffixes may follow any identifier or term antiquotation. An antiquotation with the splice suffix `*` corresponds to a use of `many` or `many1`; both the `*` and `+` suffixes in syntax rules correspond to the `*` splice suffix. An antiquotation with a splice suffix that includes an atom prior to the asterisk corresponds to a use of `sepBy` or `sepBy1`. The splice suffix `?` corresponds to a use of `optional` or the `?` suffix in a syntax rule. Because `?` is a valid identifier character, identifiers must be parenthesized to use it as a suffix.

While there is overlap between repetition specifiers for syntax and antiquotation suffixes, they have distinct syntaxes. When defining syntax, the suffixes `*`, `+`, `,*`, `,+`, `,*,?`, and `,+,?` are built in to Lean. There is no shorter way to specify separators other than `,`. Antiquotation suffixes are either just `*` or whatever atom was provided to `sepBy` or `sepBy1` followed by `*`. The syntax repetitions `+` and `*` correspond to the splice suffix `*`; the repetitions `,*`, `,+`, `,*,?`, and `,+,?` correspond to `,*`. The optional suffix `?` in syntax and splices correspond with each other.

| Syntax Repetition | Splice Suffix |
| --- | --- |
| `+` `*` | `*` |
| `,*` `,+` `,*,?` `,+,?` | `,*` |
| `sepBy(_, "S")` `sepBy1(_, "S")` | `S*` |
| `?` | `?` |

<a id="Suffixed-Splices"></a>
Suffixed Splices 

This example requires that `m` is a monad that can perform quotation.

```proofscript
variable {m : Type → Type} [Monad m] [MonadQuotation m]
```

By default, the antiquotation `$e` is expected to be an array of terms separated by commas, as is expected in the body of a list:
<a id="ex1-_LPAR_in-Suffixed-Splices_RPAR_"></a>


```proofscript
def ex1 (xs) := show m _ from `(#[$xs,*])
#check ex1
```

```lean
ex1 {m : Type → Type} [Monad m] [MonadQuotation m] (xs : Syntax.TSepArray `term ",") : m (TSyntax `term)
```

However, Lean includes a collection of coercions between various representations of arrays that will automatically insert or remove separators, so an ordinary array of terms is also acceptable:
<a id="ex2-_LPAR_in-Suffixed-Splices_RPAR_"></a>


```proofscript
def ex2 (xs : Array (TSyntax `term)) :=
  show m _ from `(#[$xs,*])
#check ex2
```

```lean
ex2 {m : Type → Type} [Monad m] [MonadQuotation m] (xs : Array (TSyntax `term)) : m (TSyntax `term)
```

Repetition annotations may also be used with term antiquotations and syntax category annotations. This example is in `CommandElabM` so the result can be conveniently logged.
<a id="ex3-_LPAR_in-Suffixed-Splices_RPAR_"></a>


```proofscript
def ex3 (size : Nat) := show CommandElabM _ from do
  let mut nums : Array Nat := #[]
  for i in [0:size] do
    nums := nums.push i
  let stx ← `(#[$(nums.map (Syntax.mkNumLit ∘ toString)):num,*])
  -- Using logInfo here causes the syntax to be rendered via
  -- the pretty printer.
  logInfo stx

#eval ex3 4
```

```lean
#[0, 1, 2, 3]
```

<a id="Non-Comma-Separators"></a>
Non-Comma Separators 

The following unconventional syntax for lists separates numeric elements by either em dashes or double asterisks, rather than by commas.

```proofscript
syntax "⟦" sepBy1(num, " — ") "⟧": term
syntax "⟦" sepBy1(num, " ** ") "⟧": term
```

This means that `—*` and `***` are valid splice suffixes between the `⟦` and `⟧` atoms. In the case of `***`, the first two asterisks are the atom in the syntax rule, while the third is the repetition suffix.

```proofscript
macro_rules
  | `(⟦$n:num—*⟧) => `(⟦$n***⟧)
  | `(⟦$n:num***⟧) => `([$n,*])
```

```proofscript
#eval ⟦1 — 2 — 3⟧
```

```lean
[1, 2, 3]
```

<a id="Optional-Splices"></a>
Optional Splices 

The following syntax declaration optionally matches a term between two tokens. The parentheses around the nested `term` are needed because `term?` is a valid identifier.

```proofscript
syntax "⟨| " (term)? " |⟩": term
```

The `?` splice suffix for a term expects an `Option Term`:
<a id="mkStx-_LPAR_in-Optional-Splices_RPAR_"></a>


```proofscript
def mkStx [Monad m] [MonadQuotation m]
    (e : Option Term) : m Term :=
  `(⟨| $(e)? |⟩)
```

```proofscript
#check mkStx
```

```lean
mkStx {m : Type → Type} [Monad m] [MonadQuotation m] (e : Option Term) : m Term
```

Supplying `some` results in the optional term being present.

```proofscript
#eval do logInfo (← mkStx (some (quote 5)))
```

```lean
⟨| 5 |⟩
```

Supplying `none` results in the optional term being absent.

```proofscript
#eval do logInfo (← mkStx none)
```

```lean
⟨| |⟩
```

<a id="token-antiquotations"></a>
#### 23.5.3.3. Token Antiquotations

In addition to antiquotations of complete syntax, Lean features 
<a id="--tech-term-token-antiquotations"></a>
*token antiquotations* which allow the source information of an atom to be replaced with the source information from some other syntax. The resulting synthetic source information is marked [canonical](../Defining-New-Syntax/index.md#--tech-term-canonical) so that it will be used for error messages, proof states, and other feedback. This is primarily useful to control the placement of error messages or other information that Lean reports to users. A token antiquotation does not allow an arbitrary atom to be inserted via evaluation. A token antiquotation consists of an atom (that is, a keyword)

<a id="antiquot-next"></a>

**syntax**

**Token Antiquotations**

Token antiquotations replace the source information (of type `SourceInfo`) on a token with the source information from some other syntax.

<a id="Manual___FreeSyntax___done"></a>

```ebnf
antiquot ::= ...
    | atom%$ident
```

<a id="quote-patterns"></a>
### 23.5.4. Matching Syntax

## See Also

New syntax is defined using [syntax extensions](../Defining-New-Syntax/index.md#syntax-rules).

Quasiquotations can be used in pattern matching to recognize syntax that matches a template. Just as antiquotations in a quotation that's used as a term are regions that are treated as ordinary non-quoted expressions, antiquotations in patterns are regions that are treated as ordinary Lean patterns. Quote patterns are compiled differently from other patterns, so they can't be intermixed with non-quote patterns in a single [`match`](../../Terms/Pattern-Matching/index.md#Lean___Parser___Term___match) expression. Like ordinary quotations, quote patterns are first processed by Lean's parser. The parser's output is then compiled into code that determines whether there is a match. Syntax matching assumes that the syntax being matched was produced by Lean's parser, either via quotation or directly in user code, and uses this to omit some checks. For example, if nothing but a particular keyword can be present in a given position, the check may be omitted.

Syntax matches a quote pattern in the following cases:

  Atoms

Keyword atoms (such as [`if`](../../Terms/Conditionals/index.md#termIfThenElse) or [`match`](../../Terms/Pattern-Matching/index.md#Lean___Parser___Term___match)) result in singleton nodes whose kind is `token.` followed by the atom. In many cases, it is not necessary to check for specific atom values because the grammar allows only a single keyword, and no checking will be performed. If the syntax of the term being matched requires the check, then the node kind is compared.

Literals, such as string or numeric literals, are compared via their underlying string representation. The pattern ```(0x15)`` and the quotation ```(21)`` do not match.

  Nodes

If both the pattern and the value being matched represent `Syntax.node`, there is a match when both have the same syntax kind, the same number of children, and each child pattern matches the corresponding child value.

  Identifiers

If both the pattern and the value being matched are identifiers, then their literal `Name` values are compared for equality modulo macro scopes. Identifiers that “look” the same match, and it does not matter if they refer to the same binding. This design choice allows quote pattern matching to be used in contexts that don't have access to a compile-time environment in which names can be compared by reference.

Because quotation pattern matching is based on the node kinds emitted by the parser, quotations that look identical may not match if they come from different syntax categories. If in doubt, including the syntax category in the quotation can help.

Variables bound by syntax pattern matches are of type `TSyntax k`, where `k` describes the potential syntax kinds. Variables in repetitions are of type `TSyntaxArray k`, or `TSepArray k sep` if the repetition is separated with the string `sep`. `TSyntax` is described in more detail in [the section on typed syntax](../Defining-New-Syntax/index.md#typed-syntax).

<a id="Syntax-Pattern-Matching"></a>
Syntax Pattern Matching 

List comprehensions are a notation for writing lists that is inspired by standard set builder notation. A list comprehension consists of square brackets that contain a result term followed by some nubmer of *qualifiers*; each qualifier either introduces a variable from some other list or imposes a condition that must be satisfied. Qualifiers are nested: each new variable's value is evaluated for every prior value.
<a id="qbind-_LPAR_in-Syntax-Pattern-Matching_RPAR_"></a>
<a id="qpred-_LPAR_in-Syntax-Pattern-Matching_RPAR_"></a>
<a id="qualifier-_LPAR_in-Syntax-Pattern-Matching_RPAR_"></a>


```proofscript
syntax qbind := ident "←" term

syntax qpred := term

syntax qualifier := atomic(qbind) <|> qpred

syntax "[" term "|" qualifier,* "]" : term
```

List comprehensions can be desugared to a sequence of calls to `List.flatMap`. Variable introductions are translated to a `flatMap` on the variable's value expression, while predicates are translated to a conditional that returns one or zero values if the predicate is true or false. The body of the final `flatMap` is the result term.

This desugaring can be implemented as a macro that uses quasiquotation patterns:

```proofscript
macro_rules
  | `(term|[$e | $qs,* ]) => do
    let init ← `([$e])
    qs.getElems.foldrM (β := Term) (init := init) fun
      | `(qualifier|$x ← $e'), r =>
        `(($e' : List _) |>.flatMap fun $x => $r)
      | `(qualifier|$e':term), r =>
        `((if $e' then [()] else []) |>.flatMap fun () => $r)
      | other, _ =>
        Macro.throwErrorAt other "Unknown qualifier"
```

Initially, the sequence of qualifiers has type ``TSepArray `qualifier ","``, indicating that it represents a comma-separated sequence of qualifiers. `TSepArray.getElems` transforms it into a ``TSyntaxArray `qualifier``, which is an abbreviation for ``Array (TSyntax `qualifier)``. This allows [generalized field notation](../../Terms/Function-Application/index.md#--tech-term-generalized-field-notation) to be used to call `Array.foldrM`. The `term` annotation in the branch for predicates is required to prevent the matched value from having syntax kind ```qualifier``; one `node` must be unwrapped from the value.

List comprehensions behave as expected:

```proofscript
#eval [ s!"{x}; {y}" |
  x ← (1...5).toList,
  x % 2 = 0,
  y ← [true, false]
]
```

```lean
["2; true", "2; false", "4; true", "4; false"]
```

<a id="defining-macros"></a>
### 23.5.5. Defining Macros

There are two primary ways to define macros: the [`macro_rules`](index.md#Lean___Parser___Command___macro_rules) command and the [`macro`](index.md#Lean___Parser___Command___macro) command. The [`macro_rules`](index.md#Lean___Parser___Command___macro_rules) command associates a macro with existing syntax, while the [`macro`](index.md#Lean___Parser___Command___macro) command simultaneously defines new syntax and a macro that translates it to existing syntax. The [`macro`](index.md#Lean___Parser___Command___macro) command can be seen as a generalization of [`notation`](../Notations/index.md#Lean___Parser___Command___notation) that allows the expansion to be generated programmatically, rather than simply by substitution.

<a id="macro_rules"></a>
#### 23.5.5.1. The macro_rules Command

<a id="command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Rule-Based Macros With macro_rules**

The [`macro_rules`](index.md#Lean___Parser___Command___macro_rules) command takes a sequence of rewrite rules, specified as syntax pattern matches, and adds each as a macro. The rules are attempted in order, before previously-defined macros, and later macro definitions may add further macro rules.

<a id="Lean___Parser___Command___macro_rules"></a>

```ebnf
command ::= ...
    | docComment?
      (@[attrInstance,*])?
      attrKind macro_rules ((kind := ident))?
        (| `((p:ident|)?Suitable syntax for p ) => term)*
```

The patterns in the macros must be quotation patterns. They may match syntax from any syntax category, but a given pattern can only ever match a single syntax kind. If no category or parser is specified for the quotation, then it may match terms or (sequences of) commands, but never both. In case of ambiguity, the term parser is chosen.

Internally, macros are tracked in a table that maps each [syntax kind](../Defining-New-Syntax/index.md#--tech-term-syntax-kind) to its macros. The [`macro_rules`](index.md#Lean___Parser___Command___macro_rules) command may be explicitly annotated with a syntax kind.

If a syntax kind is explicitly provided, the macro definition checks that each quotation pattern has that kind. If the parse result for the quotation was a [choice node](../../Elaboration-and-Compilation/index.md#--tech-term-choice-node) (that is, if the parse was ambiguous), then the pattern is duplicated once for each alternative with the specified kind. It is an error if none of the alternatives have the specified kind.

If no kind is provided explicitly, then the kind determined by the parser is used for each pattern. The patterns are not required to all have the same syntax kind; macros are defined for each syntax kind used by at least one of the patterns. It is an error if the parse result for a quotation pattern was a [choice node](../../Elaboration-and-Compilation/index.md#--tech-term-choice-node) (that is, if the parse was ambiguous).

The documentation comment associated with [`macro_rules`](index.md#Lean___Parser___Command___macro_rules) is displayed to users if the syntax itself has no documentation comment. Otherwise, the documentation comment for the syntax itself is shown.

As with [notations](../Notations/index.md#notations) and [operators](../Custom-Operators/index.md#operators), macro rules may be declared `scoped` or `local`. Scoped macros are only active when the current namespace is open, and local macro rules are only active in the current [section scope](../../Namespaces-and-Sections/index.md#--tech-term-section-scope).

<a id="Idiom-Brackets"></a>
Idiom Brackets 

Idiom brackets are an alternative syntax for working with applicative functors. If the idiom brackets contain a function application, then the function is wrapped in `pure` and applied to each argument using `<*>`. Lean does not support idiom brackets by default, but they can be defined using a macro.
<a id="idiom-_LPAR_in-Idiom-Brackets_RPAR_"></a>


```proofscript
syntax (name := idiom) "⟦" (term:arg)+ "⟧" : term

macro_rules
  | `(⟦$f $args*⟧) => do
    let mut out ← `(pure $f)
    for arg in args do
      out ← `($out <*> $arg)
    return out
```

This new syntax can be used immediately.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="addFirstThird-_LPAR_in-Idiom-Brackets_RPAR_"></a>


```proofscript
function addFirstThird [Add α] (xs : List α) : Option α :=
  ⟦Add.add xs[0]? xs[2]?⟧
```

```proofscript
#eval addFirstThird (α := Nat) []
```

```lean
none
```

```proofscript
#eval addFirstThird [1]
```

```lean
none
```

```proofscript
#eval addFirstThird [1,2,3,4]
```

```lean
some 4
```

<a id="Scoped-Macros"></a>
Scoped Macros 

Scoped macro rules are active only in their namespace. When the namespace `ConfusingNumbers` is open, numeric literals will be assigned an incorrect meaning.

```proofscript
namespace ConfusingNumbers
```

The following macro recognizes terms that are odd numeric literals, and replaces them with double their value. If it unconditionally replaced them with double their value, then macro expansion would become an infinite loop because the same rule would always match the output.

```proofscript
scoped macro_rules
  | `($n:num) => do
    if n.getNat % 2 = 0 then Lean.Macro.throwUnsupported
    let n' := (n.getNat * 2)
    `($(Syntax.mkNumLit (info := n.raw.getHeadInfo) (toString n')))
```

Once the namespace ends, the macro is no longer used.

```proofscript
end ConfusingNumbers
```

Without opening the namespace, numeric literals function in the usual way.

```proofscript
#eval (3, 4)
```

```lean
(3, 4)
```

When the namespace is open, the macro replaces `3` with `6`.

```proofscript
open ConfusingNumbers

#eval (3, 4)
```

```lean
(6, 4)
```

It is not typically useful to change the interpretation of numeric or other literals in macros. However, scoped macros can be very useful when adding new rules to extensible tactics such as `trivial` that work well with the contents of the namespaces but should not always be used.

Behind the scenes, a [`macro_rules`](index.md#Lean___Parser___Command___macro_rules) command generates one macro function for each syntax kind that is matched in its quote patterns. This function has a default case that throws the `unsupportedSyntax` exception, so further macros may be attempted.

A single [`macro_rules`](index.md#Lean___Parser___Command___macro_rules) command with two rules is not always equivalent to two separate single-match commands. First, the rules in a [`macro_rules`](index.md#Lean___Parser___Command___macro_rules) are tried from top to bottom, but recently-declared macros are attempted first, so the order would need to be reversed. Additionally, if an earlier rule in the macro throws the `unsupportedSyntax` exception, then the later rules are not tried; if they were instead in separate [`macro_rules`](index.md#Lean___Parser___Command___macro_rules) commands, then they would be attempted.

<a id="One-vs___-Two-Sets-of-Macro-Rules"></a>
One vs. Two Sets of Macro Rules 

The `arbitrary!` macro is intended to expand to some arbitrarily-determined value of a given type.
<a id="arbitrary___-_LPAR_in-One-vs___-Two-Sets-of-Macro-Rules_RPAR_"></a>


```proofscript
syntax (name := arbitrary!) "arbitrary! " term:arg : term
```

```proofscript
macro_rules
  | `(arbitrary! ()) => `(())
  | `(arbitrary! Nat) => `(42)
  | `(arbitrary! ($t1 × $t2)) => `((arbitrary! $t1, arbitrary! $t2))
  | `(arbitrary! Nat) => `(0)
```

Users may extend it by defining further sets of macro rules, such as this rule for `Empty` that fails:

```proofscript
macro_rules
  | `(arbitrary! Empty) => throwUnsupported
```

```proofscript
#eval arbitrary! (Nat × Nat)
```

```lean
(42, 42)
```

If all of the macro rules had been defined as individual cases, then the result would have instead used the later case for `Nat`. This is because the rules in a single [`macro_rules`](index.md#Lean___Parser___Command___macro_rules) command are checked from top to bottom, but more recently-defined [`macro_rules`](index.md#Lean___Parser___Command___macro_rules) commands take precedence over earlier ones.

```proofscript
macro_rules
  | `(arbitrary! ()) =>
    `(())
macro_rules
  | `(arbitrary! Nat) =>
    `(42)
macro_rules
  | `(arbitrary! ($t1 × $t2)) =>
    `((arbitrary! $t1, arbitrary! $t2))
macro_rules
  | `(arbitrary! Nat) =>
    `(0)
macro_rules
  | `(arbitrary! Empty) =>
    throwUnsupported
```

```proofscript
#eval arbitrary! (Nat × Nat)
```

```lean
(0, 0)
```

Additionally, if any rule throws the `unsupportedSyntax` exception, no further rules in that command are checked.

```proofscript
macro_rules
  | `(arbitrary! (List Nat)) => throwUnsupported
  | `(arbitrary! (List $_)) => `([])

macro_rules
  | `(arbitrary! (Array Nat)) => `(#[42])
macro_rules
  | `(arbitrary! (Array $_)) => throwUnsupported
```

The case for `List Nat` fails to elaborate, because macro expansion did not translate the `arbitrary!` syntax into something supported by the elaborator.

```proofscript
#eval arbitrary! (List Nat)
```

```lean
elaboration function for `arbitrary!` has not been implemented
  arbitrary! (List Nat)
```

The case for `Array Nat` succeeds, because the first set of macro rules are attempted after the second throws the exception.

```proofscript
#eval arbitrary! (Array Nat)
```

```lean
#[42]
```

<a id="macro-command"></a>
#### 23.5.5.2. The macro Command

The [`macro`](index.md#Lean___Parser___Command___macro) command simultaneously defines a new [syntax rule](../Defining-New-Syntax/index.md#--tech-term-syntax-rules) and associates it with a [macro](index.md#--tech-term-Macros). Unlike [`notation`](../Notations/index.md#Lean___Parser___Command___notation), which can define only new term syntax and in which the expansion is a term into which the parameters are to be substituted, the [`macro`](index.md#Lean___Parser___Command___macro) command may define syntax in any [syntax category](../Defining-New-Syntax/index.md#--tech-term-syntax-categories) and it may use arbitrary code in the `MacroM` monad to generate the expansion. Because macros are so much more flexible than notations, Lean cannot automatically generate an unexpander; this means that new syntax implemented via the [`macro`](index.md#Lean___Parser___Command___macro) command is available for use in *input* to Lean, but Lean's output does not use it without further work.

<a id="command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Macro Declarations**

<a id="Lean___Parser___Command___macro"></a>

```ebnf
command ::= ...
    | docComment?
      (@[attrInstance,*])?
      attrKind macro(:prec)? ((name := ident))? ((priority := prio))? macroArg* : ident =>
        macroRhs
```

<a id="Lean___Parser___Command___macroArg"></a>

**syntax**

**Macro Arguments**

A macro's arguments are either syntax items (as used in the [`syntax`](../Defining-New-Syntax/index.md#Lean___Parser___Command___syntax) command) or syntax items with attached names.

<a id="Lean___Parser___Command___macroArg-next"></a>

```ebnf
macroArg ::=
    stx
```

<a id="Lean___Parser___Command___macroArg-next-next"></a>

```ebnf
macroArg ::= ...
    | ident:stx
```

In the expansion, the names that are attached to syntax items are bound; they have type `TSyntax` for the appropriate syntax kinds. If the syntax matched by the parser does not have a defined kind (e.g. because the name is applied to a complex specification), then the type is `TSyntax Name.anonymous`.

The documentation comment is associated with the new syntax, and the attribute kind (none, `local`, or `scoped`) governs the visibility of the macro just as it does for notations: `scoped` macros are available in the namespace in which they are defined or in any [section scope](../../Namespaces-and-Sections/index.md#--tech-term-section-scope) that opens that namespace, while `local` macros are available only in the local section scope.

Behind the scenes, the [`macro`](index.md#Lean___Parser___Command___macro) command is itself implemented by a macro that expands it to a [`syntax`](../Defining-New-Syntax/index.md#Lean___Parser___Command___syntax) command and a [`macro_rules`](index.md#Lean___Parser___Command___macro_rules) command. Any attributes applied to the macro command are applied to the syntax definition, but not to the [`macro_rules`](index.md#Lean___Parser___Command___macro_rules) command.

<a id="macro-attribute"></a>
#### 23.5.5.3. The Macro Attribute

[Macros](index.md#--tech-term-Macros) can be manually added to a syntax kind using the [`macro`](index.md#Lean___Parser___Attr___macro) attribute. This low-level means of specifying macros is typically not useful, except as a result of code generation by macros that themselves generate macro definitions.

<a id="attr-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**attribute**

**The macro Attribute**

The [`macro`](index.md#Lean___Parser___Attr___macro) attribute specifies that a function is to be considered a [macro](index.md#--tech-term-Macros) for the specified syntax kind.

<a id="Lean___Parser___Attr___macro"></a>

```ebnf
attr ::= ...
    | macro ident
```

<a id="The-Macro-Attribute"></a>
The Macro Attribute 
<a id="rep-_LPAR_in-The-Macro-Attribute_RPAR_"></a>
<a id="expandRep-_LPAR_in-The-Macro-Attribute_RPAR_"></a>


```proofscript
/-- Generate a list based on N syntactic copies of a term -/
syntax (name := rep) "[" num " !!! " term "]" : term

@[macro rep]
def expandRep : Macro
  | `([ $n:num !!! $e:term]) =>
    let e' := Array.replicate n.getNat e
    `([$e',*])
  | _ =>
    throwUnsupported
```

Evaluating this new expression demonstrates that the macro is present.

```proofscript
#eval [3 !!! "hello"]
```

```lean
["hello", "hello", "hello"]
```

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Syntax quotation for terms.
```


### Display 2


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


### Display 3


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
'5' is not allowed here
```


### Display 3


```text
Application type mismatch: The argument
  cmd1
has type
  TSyntax `command
but is expected to have type
  TSyntax `term
in the application
  cmd1.raw
```


### Display 4


```text
Application type mismatch: The argument
  cmd2
has type
  TSyntax `command
but is expected to have type
  TSyntax `term
in the application
  cmd2.raw
```


### Display 5


```text
ex1 {m : Type → Type} [Monad m] [MonadQuotation m] (e : TSyntax `term) : m (TSyntax `term)
```


### Display 6


```text
ex2 {m : Type → Type} [Monad m] [MonadQuotation m] (e : TSyntax `num) : m (TSyntax `term)
```


### Display 7


```text
def f : {m : Type → Type} → [Monad m] → [Lean.MonadQuotation m] → Lean.Term → Nat → m Syntax :=
fun {m} [Monad m] [Lean.MonadQuotation m] x n => do
  let info ← Lean.MonadRef.mkInfoFromRefPos
  let scp ← Lean.getCurrMacroScope
  let quotCtx ← Lean.MonadQuotation.getContext
  pure
      {
          raw :=
            Syntax.node2 info `Lean.Parser.Term.fun (Syntax.atom info "fun")
              (Syntax.node4 info `Lean.Parser.Term.basicFun
                (Syntax.node1 info `null (Syntax.ident info "k".toRawSubstring' (Lean.addMacroScope quotCtx `k scp) []))
                (Syntax.node info `null #[]) (Syntax.atom info "=>")
                (Syntax.node3 info `«term_+_»
                  (Syntax.node3 info `«term_+_» x.raw (Syntax.atom info "+") (Lean.quote `term (n + 2)).raw)
                  (Syntax.atom info "+")
                  (Syntax.ident info "k".toRawSubstring' (Lean.addMacroScope quotCtx `k scp) []))) }.raw
```


### Display 8


```text
ex1 {m : Type → Type} [Monad m] [MonadQuotation m] (xs : Syntax.TSepArray `term ",") : m (TSyntax `term)
```


### Display 9


```text
ex2 {m : Type → Type} [Monad m] [MonadQuotation m] (xs : Array (TSyntax `term)) : m (TSyntax `term)
```


### Display 10


```text
#[0, 1, 2, 3]
```


### Display 11


```text
[1, 2, 3]
```


### Display 12


```text
mkStx {m : Type → Type} [Monad m] [MonadQuotation m] (e : Option Term) : m Term
```


### Display 13


```text
⟨| 5 |⟩
```


### Display 14


```text
⟨| |⟩
```


### Display 15


```text
["2; true", "2; false", "4; true", "4; false"]
```


### Display 16


```text
none
```


### Display 17


```text
some 4
```


### Display 18


```text
(3, 4)
```


### Display 19


```text
(6, 4)
```


### Display 20


```text
(42, 42)
```


### Display 21


```text
(0, 0)
```


### Display 22


```text
elaboration function for `arbitrary!` has not been implemented
  arbitrary! (List Nat)
```


### Display 23


```text
#[42]
```


### Display 24


```text
["hello", "hello", "hello"]
```

