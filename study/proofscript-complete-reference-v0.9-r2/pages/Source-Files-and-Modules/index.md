<a id="files"></a>

# ProofScript — 5. Source Files and Modules

[Reference home](../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

A .ps module uses the selected ProofScript grammar; .lean uses native syntax. Canonical .lean output is a trace, not a fallback sibling. Select one source snapshot per logical module and reject ambiguous candidates. Imports retain native module syntax. Package resolution may use npm, but the resolved logical imports, options, extensions and executable capabilities must be explicit.

**Compiler and coverage boundary.** Keep source, elaboration and executable dependency closures separate. Do not silently process earlier commands in the final module environment.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Source-Files-and-Modules/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Source-Files-and-Modules/index.html). Source Git blob: `b1a2916cc4f44897caaaa5114f52e4519f90e2f1`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 5. Source Files and Modules

The smallest unit of compilation in Lean is a single [source file](index.md#--tech-term-source-files). Source files may import other source files based on their file names. In other words, the names and folder structures of files are significant in Lean code.

Each source file has an 
<a id="--tech-term-import-name"></a>
*import name* that is derived from a combination of its filename and the way in which Lean was invoked: Lean has a set of *root directories* in which it expects to find code, and the source file's import name is the names of the directories from the root to the filename, with dots (`.`) interspersed and `.lean` removed. For example, if Lean is invoked with `Projects/MyLib/src` as its root, the file `Projects/MyLib/src/Literature/Novel/SciFi.lean` could be imported as `Literature.Novel.SciFi`.

<a id="module-encoding"></a>
### 5.1. Encoding and Representation

Lean 
<a id="--tech-term-source-files"></a>
source files are Unicode text files encoded in UTF-8. Lines may end either with newline characters (`"\n"`, Unicode `'LINE FEED (LF)' (U+000A)`) or with a form feed and newline sequence (`"\r\n"`, Unicode `'CARRIAGE RETURN (CR)' (U+000D)` followed by `'LINE FEED (LF)' (U+000A)`). However, Lean normalizes line endings when parsing or comparing files, so all files are compared as if all their line endings are `"\n"`.

<a id="module-syntax"></a>
### 5.2. Concrete Syntax

Lean's concrete syntax is [extensible](../Notations-and-Macros/index.md#language-extension). In a language like Lean, it's not possible to completely describe the syntax once and for all, because libraries may define syntax in addition to new constants or [inductive types](../The-Type-System/Inductive-Types/index.md#--tech-term-Inductive-types). Rather than completely describing the language here, the overall framework is described, while the syntax of each language construct is documented in the section to which it belongs.

<a id="whitespace"></a>
#### 5.2.1. Whitespace

Tokens in Lean may be separated by any number of 
<a id="--tech-term-whitespace"></a>
*whitespace* character sequences. Whitespace may be a space (`" "`, Unicode `'SPACE (SP)' (U+0020)`), a valid newline sequence, or a comment. Neither tab characters nor carriage returns not followed by newlines are valid whitespace sequences.

<a id="comments"></a>
#### 5.2.2. Comments

Comments are stretches of the file that, despite not being whitespace, are treated as such. Lean has two syntaxes for comments:

  Line comments

A `--` that does not occur as part of a token begins a *line comment*. All characters from the initial `-` to the newline are treated as whitespace.
<a id="--index--next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

  Block comments

A `/-` that does not occur as part of a token and is not immediately followed by a `-` character begins a *block comment*.
<a id="--index--next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
 The block comment continues until a terminating `-/` is found. Block comments may be nested; a `-/` only terminates the comment if prior nested block comment openers `/-` have been terminated by a matching `-/`.

`/--` and `/-!` begin 
<a id="--tech-term-documentation"></a>
*documentation* rather than comments, which are also terminated with `-/` and may contain nested block comments. Even though documentation resembles comments, they are their own syntactic category; their valid placement is determined by Lean's grammar.

<a id="keywords-and-identifiers"></a>
#### 5.2.3. Keywords and Identifiers

An [identifier](../Notations-and-Macros/Defining-New-Syntax/index.md#--tech-term-Identifiers) consists of one or more identifier components, separated by `'.'`.
<a id="--index--next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

<a id="--tech-term-Identifier-components"></a>
Identifier components consist of a letter or letter-like character or an underscore (`'_'`), followed by zero or more identifier continuation characters. Letters are English letters, upper- or lowercase, and the letter-like characters include a range of non-English alphabetic scripts, including the Greek script which is widely used in Lean, the Coptic script, the members of the Unicode letter-like symbol block, which contains a number of double-struck characters (including `ℕ` and `ℤ`) and abbreviations, the Latin-1 supplemental letters (with the exception of `×` and `÷`), and the Latin Extended-A block. Identifier continuation characters consist of letters, letter-like characters, underscores (`'_'`), exclamation marks (`!`), question marks (`?`), subscripts, and single quotes (`'`). As an exception, underscore alone is not a valid identifier.

Identifiers components may also be surrounded by double 
<a id="--tech-term-guillemets"></a>
guillemets (`'«'` and `'»'`). Such identifier components may contain any character at all aside from `'»'`, even `'«'`, `'.'`, and newlines. The guillemets are not part of the resulting identifier component, so `«x»` and `x` denote the same identifier. `«Nat.add»`, on the other hand, is an identifier with a single component, while `Nat.add` has two.

Some potential identifier components may be reserved keywords. The specific set of reserved keywords depends on the set of active syntax extensions, which may depend on the set of imported files and the currently-opened namespaces; it is impossible to enumerate for Lean as a whole. These keywords must also be quoted with guillemets to be used as identifier components in most syntactic contexts. Contexts in which keywords may be used as identifiers without guillemets, such as constructor names in inductive types, are 
<a id="--tech-term-raw-identifier"></a>
*raw identifier* contexts.
<a id="--index--next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

Identifiers that contain one or more `'.'` characters, and thus consist of more than one identifier component, are called 
<a id="--tech-term-hierarchical-identifiers"></a>
hierarchical identifiers. Hierarchical identifiers are used to represent both import names and names in a namespace.

<a id="module-structure"></a>
### 5.3. Structure

<a id="Lean___Parser___Module___module"></a>

**syntax**

**Modules**

<a id="Lean___Parser___Module___module-next"></a>

```ebnf
module ::=
    header command*
```

A source file consists of a 
<a id="--tech-term-file-header"></a>
*file header* followed by a sequence of 
<a id="--tech-term-commands"></a>
*commands*.

If a source file's header begins with `module`, then it is referred to as a [*module*](index.md#--tech-term-module). Modules provide greater control over what information is exposed to clients.

<a id="module-headers"></a>
#### 5.3.1. Headers

Module headers list the modules that should be elaborated prior to the current module. Their declarations are visible in the current module.

<a id="Lean___Parser___Module___header"></a>

**syntax**

**Module Headers**

The module header consists of an optional `module` keyword followed by a sequence of 
<a id="--tech-term-import-statements"></a>
`import` statements:

<a id="Lean___Parser___Module___header-next"></a>

```ebnf
header ::=
    module?
    import*
```

The optional `prelude` keyword should only be used in Lean's source code:

<a id="Lean___Parser___Module___header-next-next"></a>

```ebnf
header ::= ...
    | module?
      prelude
      import*
```

If present, the `prelude` keyword indicates that the file is part of the implementation of the Lean 
<a id="--tech-term-prelude"></a>
*prelude*, which is the code that is available without any explicit imports—it should not be used outside of Lean's implementation.

<a id="Lean___Parser___Module___prelude"></a>

**syntax**

**Prelude Modules**

<a id="Lean___Parser___Module___prelude-next"></a>

```ebnf
prelude ::=
    prelude
```

<a id="Lean___Parser___Module___import"></a>

**syntax**

**Imports**

All [source files](index.md#--tech-term-source-files) may use plain imports:

<a id="Lean___Parser___Module___import-next"></a>

```ebnf
import ::= ...
    | import ident
```

In source files that are not modules, this imports the specified Lean file. Importing a file makes its contents available in the current source file, as well as those from source files transitively imported by its imports.

Source file names do not necessarily correspond to namespaces. Source files may add names to any namespace, and importing a source file has no effect on the set of currently open namespaces.

The [import name](index.md#--tech-term-import-name) is translated to a filename by replacing dots (`'.'`) in its name with directory separators and appending `.lean` or `.olean`. Lean searches its include path for the corresponding intermediate build product or importable module file.

[Modules](index.md#--tech-term-module) may use the following import syntax:

<a id="Lean___Parser___Module___import-next-next"></a>

```ebnf
import ::= ...
    | public? meta? import all? ident
```

All imports to a module must themselves be modules. Without modifiers, the imported module's public scope is added to the current module's private scope. The imported module is not made available to modules that import the current module. The modifiers have the following meanings:

  `public`

The imported module's public scope is added to the current module's public scope and made available to the current module's importers.

  `meta`

The contents of the imported module are made available at the [meta phase](index.md#--tech-term-meta-phase) in the current module.

  `all`

The imported module's private scope is added to the current module's [private scope](index.md#--tech-term-private-scope).

<a id="commands"></a>
#### 5.3.2. Commands

[Commands](index.md#--tech-term-commands) are top-level statements in Lean. Some examples are inductive type declarations, theorems, function definitions, namespace modifiers like `open` or `variable`, and interactive queries such as `#check`. The syntax of commands is user-extensible, and commands may even [add new syntax that is used to parse subsequent commands](../Notations-and-Macros/index.md#language-extension). Specific Lean commands are documented in the corresponding chapters of this manual, rather than being listed here.

<a id="module-scopes"></a>
### 5.4. Modules and Visibility

A 
<a id="--tech-term-module"></a>
module is a source file that has opted in to a distinction between public and private information. Lean ensures that private information can change without affecting clients that import only its public information. This discipline brings a number of benefits:

  Much-improved average build times

Changes to files that affect only non-exported information (e.g. proofs, comments, and docstrings) will not trigger rebuilds outside of these files. Even when dependent files have to be rebuilt, those files that cannot be affected (as determined by their `import` annotations) can be skipped.

  Control over API evolution

Library authors can trust that changes to non-exported information will not affect downstream users of their library. If only a function's signature is exposed, then downstream users cannot rely on definitional equalities that involve its unfolding; this means that the library's author is free to adopt a more efficient algorithm without unintentionally breaking client code.

  Avoiding accidental unfolding

Limiting the scope in which definitions can be unfolded allows for avoiding both reductions that should be replaced by application of more specific theorems as well as unproductive reductions that were not in fact necessary. This improves the speed of proof elaboration.

  Smaller executables

Separating compile-time and run-time code allows for more aggressive dead code elimination, guaranteeing that metaprograms such as tactics do not make it into the final binary.

  Reduced memory usage

Excluding private information such as proofs from importing can improve Lean's memory use both while building and editing a project. Porting mathlib4 to the module system has shown savings close to 50% from this even before imports are further minimized.

Modules contain two separate scopes: the 
<a id="--tech-term-public-scope"></a>
*public scope* consists of information that is visible in modules that import a module, while the 
<a id="--tech-term-private-scope"></a>
*private scope* consists of information that is generally visible only within the module. Some examples of information that can be private or public include:

  Names

Constants (such as definitions, inductive types, or constructors) may be private or public. A public constant's type may only refer to public names.

  Definitions

A public definition may be 
<a id="--tech-term-exposed"></a>
exposed or not. If a public definition is not exposed, then it cannot be unfolded in contexts that only have access to the public scope. Instead, clients must rely on the theorems about the definition that are provided in the public scope.

Each declaration has default visibility rules. Generally speaking, all names are private by default, unless defined in a [public section](../Namespaces-and-Sections/index.md#--tech-term-public-section). Even public names usually place the bodies of definitions in the private scope, and even proofs in exposed definitions are kept private. The specific visibility rules for each declaration command are documented together with the declaration itself.

<a id="Private-and-Public-Definitions"></a>
Private and Public Definitions 

The module `Greet.Create` defines a function `greeting`. Because there are no visibility modifiers, this function defaults to the [private scope](index.md#--tech-term-private-scope):

  `Greet/Create.lean`
<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="_private___0___greeting-_LPAR_in-Private-and-Public-Definitions_RPAR_"></a>


```proofscript
module
function greeting (name : String) : String :=
  s!"Hello, {name}"
```

The definition of `greeting` is not visible in the module `Greet`, even though it imports `Greet.Create`:

  `Greet.lean`
<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
module
import Greet.Create
function greetTwice (name1 name2 : String) : String :=
  greeting name1 ++ "\n" ++ greeting name2
```

```lean
Unknown identifier `greeting`
```

If `greeting` is made public, then `greetTwice` can refer to it:

  `Greet/Create.lean`
<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="greeting-_LPAR_in-Private-and-Public-Definitions_RPAR_"></a>


```proofscript
module
public function greeting (name : String) : String :=
  s!"Hello, {name}"
```

  `Greet.lean`
<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
module
import Greet.Create
function greetTwice (name1 name2 : String) : String :=
  greeting name1 ++ "\n" ++ greeting name2
```

<a id="Exposed-and-Unexposed-Definitions"></a>
Exposed and Unexposed Definitions 

The module `Greet.Create` defines a public function `greeting`.

  `Greet/Create.lean`
<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
module
public function greeting (name : String) : String :=
  s!"Hello, {name}"
```

Although the definition of `greeting` is visible in the module `Greet`, it cannot be unfolded in a proof because the definition's body is in the [private scope](index.md#--tech-term-private-scope) of `Greet`:

  `Greet.lean`
<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
module
import Greet.Create
function greetTwice (name1 name2 : String) : String :=
  greeting name1 ++ "\n" ++ greeting name2

theorem greetTwice_is_greet_twice {name1 name2 : String} :
    greetTwice name1 name2 = "Hello, " ++ name1 ++ "\n" ++ "Hello, " ++ name2 := by
  simp [greetTwice, greeting]
```

```lean
Invalid simp theorem `greeting`: Expected a definition with an exposed body
```

Adding the `@[expose]` attribute exposes the definition so that downstream modules can unfold `greeting`:

  `Greet/Create.lean`
<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
module
@[expose]
public function greeting (name : String) : String :=
  s!"Hello, {name}"
```

Now, the proof can proceed:

  `Greet.lean`
<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
module
import Greet.Create
function greetTwice (name1 name2 : String) : String :=
  greeting name1 ++ "\n" ++ greeting name2

theorem greetTwice_is_greet_twice {name1 name2 : String} :
    greetTwice name1 name2 = "Hello, " ++ name1 ++ "\n" ++ "Hello, " ++ name2 := by
  simp [greetTwice, greeting, toString]
  grind [String.append_assoc]
```

<a id="Proofs-are-Private"></a>
Proofs are Private  

In this module, the function `incr` is public, but its implementation is not exposed:

  `Main.lean`
<a id="incr-_LPAR_in-Proofs-are-Private_RPAR_"></a>
<a id="incr_eq_plus1-_LPAR_in-Proofs-are-Private_RPAR_"></a>


```proofscript
module

public def incr : Nat → Nat
  | 0 => 1
  | n + 1 => incr n + 1

public theorem incr_eq_plus1 : incr = (· + 1) := by
  funext n
  induction n <;> simp [incr, *]
```

Nonetheless, the proof of the theorem `incr_eq_plus1` can unfold its definition. This is because proofs of theorems are in the private scope. This is the case both for public and private theorems.

The option `backward.privateInPublic` can be used while transitioning from ordinary source files to modules. When it is set to `true`, private definitions are exported, though their names are not accessible in importing modules. However, references to them in the public part of their defining module are allowed. Such references result in a warning unless the option `backward.privateInPublic.warn` is set to `false`. These warnings can be used to locate and eventually eliminate these references, allowing `backward.privateInPublic` to be disabled. Similarly, `backward.proofsInPublic` causes proofs created with `by` to be public, rather than private; this can enable `by` to fill in metavariables in its expected type. Most use cases for `backward.proofsInPublic` also require that `backward.privateInPublic` is enabled.

<a id="backward___privateInPublic"></a>

**option**

```text
backward.privateInPublic
```

Default value: `false`

(module system) Export `private` declarations, allowing for arbitrary access to them while code is being ported to the module system. Such accesses will generate warnings unless `backward.privateInPublic.warn` is disabled.

<a id="backward___privateInPublic___warn"></a>

**option**

```text
backward.privateInPublic.warn
```

Default value: `true`

(module system) Warn on accesses to `private` declarations that are allowed only by `backward.privateInPublic` being enabled.

<a id="backward___proofsInPublic"></a>

**option**

```text
backward.proofsInPublic
```

Default value: `false`

(module system) Do not abstract proofs used in the public scope into auxiliary theorems. Enabling this option may lead to failures or, when `backward.privateInPublic` and its `warn` sub-option are enabled, additional warnings from private accesses.

<a id="Exporting-Private-Definitions"></a>
Exporting Private Definitions 

In the module `L.Defs`, the public definition of `f` refers to the private definition `drop2` in its signature. Because `backward.privateInPublic` is `true`, this is allowed, resulting in a warning:

  `L/Defs.lean`
<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="_private___0___drop2-_LPAR_in-Exporting-Private-Definitions_RPAR_"></a>
<a id="f-_LPAR_in-Exporting-Private-Definitions_RPAR_"></a>


```proofscript
module

set_option backward.privateInPublic true

function drop2 (xs : List α) : List α := xs.drop 2

public function f (xs : List α) (transform : List α → List α:= drop2) : List α :=
  transform xs
```

```lean
Private declaration `drop2` accessed publicly; this is allowed only because the `backward.privateInPublic` option is enabled. 

Disable `backward.privateInPublic.warn` to silence this warning.
```

When the module is imported, references to `f` use `drop2` as a default argument value; however, its name is inaccessible in the module `L`:

  `L.lean`
<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="_private___0___xs-_LPAR_in-Exporting-Private-Definitions_RPAR_"></a>


```proofscript
module
import L.Defs

const xs := [1, 2, 3]

set_option pp.explicit true in
#check f xs
```

```lean
@f Nat xs (@drop2✝ Nat) : List Nat
```

<a id="Proofs-in-Public"></a>
Proofs in Public 

In the plain source file `NotMod`, the definition of `two` uses the content of the proof to fill out the numeric value in the definition by solving a [`metavariable`](../Tactic-Proofs/Reading-Proof-States/index.md#--tech-term-metavariables):

  `NotMod.lean`

```proofscript
structure Half (n : Nat) where
  val : Nat
  ok : val + val = n

abbrev two := Half.mk _ <| by
  show 2 + 2 = 4
  rfl
```

Converting this file to a module results in an error, because the body of the definition is exposed in the public part but the proof is private and thus cannot change the public type:

  `Mod.lean`

```proofscript
module
public section

structure Half (n : Nat) where
  val : Nat
  ok : val + val = n

abbrev two := Half.mk _ <| by
  show 2 + 2 = 4
  rfl
```

```lean
tactic execution is stuck, goal contains metavariables
  ?m.3 + ?m.3 = ?m.5
```

Setting the option `backward.proofsInPublic` causes the proof to be in the public part of the module so it can solve the metavariable:

  `Mod.lean`

```proofscript
module
public section

structure Half (n : Nat) where
  val : Nat
  ok : val + val = n

set_option backward.proofsInPublic true in
abbrev two := Half.mk _ <| by
  show 2 + 2 = 4
  rfl
```

However, it is typically better style to reformulate the definition so that the proof has a complete goal:

  `Mod.lean`

```proofscript
module
public section

structure Half (n : Nat) where
  val : Nat
  ok : val + val = n

abbrev two : Half 4 := Half.mk 2 <| by
  rfl
```

The private scope of a module may be imported into another module using the `all` modifier. By default, this is only allowed if the imported module and the current module are from the same Lake [package](../Build-Tools-and-Distribution/Lake/index.md#--tech-term-package), as its main purpose is to allow for separating definitions and proofs into separate modules for internal organization of a library. The Lake package or library option [`allowImportAll`](../Build-Tools-and-Distribution/Lake/index.md#Lake___PackageConfig-allowImportAll) can be set to allow other packages to access to the current package's private scopes via `import all`. The imported private scope includes private imports of the imported module, including nested `import all`s. As a consequence, the set of private scopes accessible to the current module is the transitive closure of `import all` declarations.

The module system's `import all` is more powerful than `import` without the module system. It makes imported private definitions accessible directly by name, as if they were defined in the current module. A secondary use case for `import all` is to access code in multiple modules within a library that should nonetheless not be provided to downstream consumers, as well as to allow tests to access information that is not part of the public API.

<a id="Importing-Private-Information"></a>
Importing Private Information 

This library separates a module of definitions from a module of lemmas. This is a common pattern in Lean code.

  `Tree/Basic.lean`

```proofscript
module

public inductive Tree (α : Type u) : Type u where
  | leaf
  | branch (left : Tree α) (val : α) (right : Tree α)

public def Tree.count : Tree α → Nat
  | .leaf => 0
  | .branch left _ right => left.count + 1 + right.count
```

However, because `Tree.count` is not exposed, the proof in the lemma file cannot unfold it:

  `Tree/Lemmas.lean`

```proofscript
module
public import Tree.Basic
theorem Tree.count_leaf_eq_zero : count (.leaf : Tree α) = 0 := by
  simp [count]
```

```lean
Invalid simp theorem `count`: Expected a definition with an exposed body
```

Importing the private scope from `Tree.Basic` into the lemma module allows the definition to be unfolded in the proof.

  `Tree/Basic.lean`

```proofscript
module

public inductive Tree (α : Type u) : Type u where
  | leaf
  | branch (left : Tree α) (val : α) (right : Tree α)

public def Tree.count : Tree α → Nat
  | .leaf => 0
  | .branch left _ right => left.count + 1 + right.count
```

  `Tree/Lemmas.lean`

```proofscript
module
import all Tree.Basic
public import Tree.Basic
theorem Tree.count_leaf_eq_zero : count (.leaf : Tree α) = 0 := by
  simp [count]
```

<a id="meta-phase"></a>
#### 5.4.1. The Meta Phase

Definitions in Lean result in both a representation in the type theory that is designed for formal reasoning and a compiled representation that is designed for execution. This compiled representation is used to generate machine code, but it can also be executed directly using an interpreter. The code that runs during [elaboration](../Elaboration-and-Compilation/index.md#--tech-term-elaboration), such as [tactics](../Tactic-Proofs/index.md#tactics) or [macros](../Notations-and-Macros/Macros/index.md#macros), is the compiled form of definitions. If this compiled representation changes, then any code created by it may no longer be up to date, and it must be re-run. Because the compiler performs non-trivial optimizations, changes to any definition in the transitive dependency chain of a function could in principle invalidate its compiled representation. This means that metaprograms exported by modules induce a much stronger coupling than ordinary definitions. Furthermore, metaprograms run *during* the construction of ordinary terms; thus, they must be fully defined and compiled before use. After all, a function definition without a body cannot be run. The time at which metaprograms are run is referred to as the 
<a id="--tech-term-metaprogramming-phase"></a>
*metaprogramming phase*, frequently just called the 
<a id="--tech-term-meta-phase"></a>
*meta phase*.

Just as they distinguish between public and private information, modules additionally distinguish code that is available in the meta phase from ordinary code. Any declaration used as an entry point to compile-time execution has to be tagged with the `meta` modifier, which indicates that the declaration is available for use as a metaprogram. This is automatically done in built-in metaprogramming syntax such as [`syntax`](../Notations-and-Macros/Defining-New-Syntax/index.md#Lean___Parser___Command___syntax), [`macro`](../Notations-and-Macros/Macros/index.md#Lean___Parser___Command___macro), and `elab` but may need to be done explicitly when manually applying metaprogramming attributes such as `app_delab` or when defining helper declarations. A `meta` definition may only access (and thus invoke) other `meta` definitions in execution-relevant positions; a non-`meta` definition likewise may only access other non-`meta` definitions.

<a id="Meta-Definitions"></a>
Meta Definitions 

In this module, the helper function `revArrays` reverses the order of the elements in each array literal in a term. This is called by the macro `rev!`.

  `Main.lean`

```proofscript
module

open Lean

variable [Monad m] [MonadRef m] [MonadQuotation m]

partial def revArrays : Syntax → m Term
  | `(#[$xs,*]) => `(#[$((xs : Array Term).reverse),*])
  | other => do
    match other with
    | .node k i args =>
      pure ⟨.node k i (← args.mapM revArrays)⟩
    | _ => pure ⟨other⟩

macro "rev!" e:term : term => do
  revArrays e
```

The error message indicates that `revArrays` cannot be used from the macro because it is not defined in the module's [metaprogramming phase](index.md#--tech-term-metaprogramming-phase):

```lean
Invalid `meta` definition `_aux___macroRules_termRev!__1`, `revArrays` not marked `meta`
```

Marking `revArrays` with the [`meta`](../Definitions/Modifiers/index.md#Lean___Parser___Command___declModifiers) modifier allows the macro definition to call it:

  `Main.lean`

```proofscript
module

open Lean

variable [Monad m] [MonadRef m] [MonadQuotation m]

meta partial def revArrays : Syntax → m Term
  | `(#[$xs,*]) => `(#[$((xs : Array Term).reverse),*])
  | other => do
    match other with
    | .node k i args =>
      pure ⟨.node k i (← args.mapM revArrays)⟩
    | _ => pure ⟨other⟩

macro "rev!" e:term : term => do
  revArrays e

#eval rev! #[1, 2, 3]
```

```lean
#[3, 2, 1]
```

Libraries that were not originally part of the meta phase can be brought into it by importing a module with `meta import`. When a module is imported at the meta phase, all of its definitions are made available at that phase, whether or not they were marked `meta`. There is no meta-meta phase. In addition to making the imported module's public contents available at the meta phase, `meta import` indicates that the current module should be rebuilt if the compiled representation of the imported module changes, ensuring that modified metaprograms are re-run. If a definition should be usable in both phases, then it must be defined in a separate module and imported at both phases.

<a id="Cross-Phase-Code-Reuse"></a>
Cross-Phase Code Reuse 

In this module, the function `toPalindrome` is defined in the meta phase, which allows it to be used in a macro but not in an ordinary definition:

  `Phases.lean`
<a id="_private___0___toPalindrome-_LPAR_in-Cross-Phase-Code-Reuse_RPAR_"></a>


```proofscript
module

open Lean

variable [Monad m] [MonadRef m] [MonadQuotation m]

meta def toPalindrome (xs : Array α) : Array α := xs ++ xs.reverse

meta partial def palArrays : Syntax → m Term
  | `(#[$xs,*]) => `(#[$(toPalindrome (xs : Array Term)),*])
  | other => do
    match other with
    | .node k i args =>
      pure ⟨.node k i (← args.mapM palArrays)⟩
    | _ => pure ⟨other⟩

macro "pal!" e:term : term => do
  palArrays e

#check pal! (#[1, 2, 3] ++ [6, 7, 8])

public def colors := toPalindrome #["red", "green", "blue"]
```

```lean
Invalid definition `colors`, may not access declaration `toPalindrome` marked as `meta`
```

Moving `toPalindrome` to its own module, `Phases.Pal`, allows this module to be imported at both phases:

  `Phases/Pal.lean`
<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="toPalindrome-_LPAR_in-Cross-Phase-Code-Reuse_RPAR_"></a>


```proofscript
module

public function toPalindrome (xs : Array α) : Array α := xs ++ xs.reverse
```

  `Phases.lean`

```proofscript
module

meta import Phases.Pal
import Phases.Pal

open Lean

variable [Monad m] [MonadRef m] [MonadQuotation m]

meta partial def palArrays : Syntax → m Term
  | `(#[$xs,*]) => `(#[$(toPalindrome (xs : Array Term)),*])
  | other => do
    match other with
    | .node k i args =>
      pure ⟨.node k i (← args.mapM palArrays)⟩
    | _ => pure ⟨other⟩

local macro "pal!" e:term : term => do
  palArrays e

#check pal! (#[1, 2, 3] ++ [6, 7, 8])

public def colors := toPalindrome #["red", "green", "blue"]
```

If the macro `pal!` were public (that is, if it was not declared with the `local` modifier) then the `meta import` of `Phases.Pal` would need to be declared `public` as well.

In addition, the import must be public if the imported definition may be executed at compile time outside the current module, i.e. if it is reachable from some public `meta` definition in the current module. Use `public meta import`. If the declaration is already declared `meta`, then `public import` is sufficient.

Unlike definitions, most metaprograms are public by default. Thus, most `meta import` are also `public` in practice. The exception is when a definition is imported solely for use in local metaprograms, such as those declared with `local syntax`, `local macro`, or `local elab`.

As a guideline, it is usually preferable to keep the amount of [`meta`](../Definitions/Modifiers/index.md#Lean___Parser___Command___declModifiers) annotations as small as possible. This avoids locking otherwise-reusable declarations into the [meta phase](index.md#--tech-term-meta-phase) and it helps the build system avoid more rebuilds. Thus, when a metaprogram depends on other code that does not itself need to be marked [`meta`](../Definitions/Modifiers/index.md#Lean___Parser___Command___declModifiers), this other code should be placed in a separate module and not marked [`meta`](../Definitions/Modifiers/index.md#Lean___Parser___Command___declModifiers). Only the final module that actually registers a metaprogram needs the helpers to be in the meta phase. This module should use `public meta import` to import those helpers and then define its metaprograms using built-in syntax like `elab`, using `meta def`, or using [`meta section`](../Namespaces-and-Sections/index.md#Lean___Parser___Command___section).

<a id="module-contents"></a>
### 5.5. Elaborated Modules

When Lean elaborates a source file, the result is an [environment](../Elaboration-and-Compilation/index.md#--tech-term-environments). The environment includes the constants, [inductive types](../The-Type-System/Inductive-Types/index.md#--tech-term-Inductive-types), [theorems](../Definitions/Theorems/index.md#--tech-term-theorems), [type classes](../Type-Classes/index.md#--tech-term-type-class), [instances](../Type-Classes/index.md#--tech-term-instances), and everything else declared in the file, along with side tables that track data as diverse as [simp sets](../The-Simplifier/Simp-sets/index.md#--tech-term-simp-set), namespace aliases, and [documentation comments](../Definitions/Modifiers/index.md#--tech-term-Documentation-comments). If the file contains a module, then the environment additionally tracks which information is public and private, and the phase at which definitions are available.

As the source file is processed by Lean, commands add content to the environment. After elaboration, the environment is serialized to a 
<a id="--tech-term-___olean-file-next"></a>
`.olean` file, which contains both the environment and a compacted heap region with the run-time objects needed by the environment. This means that an imported source file can be loaded without re-executing all of its commands. Environments that result from elaborating modules are serialized into three [`.olean` files](index.md#--tech-term-___olean-file-next), containing the private, public, and server information in the environment. The server information consists of data such as API documentation and source positions of definitions that is only needed when using the Lean language server and does not need to be loaded along with the public information in other contexts.

<a id="The-Lean-Language-Reference--Source-Files-and-Modules--Module-System-Errors-and-Patterns"></a>
### 5.6. Module System Errors and Patterns

The following list contains common errors one might encounter when using the module system and especially porting existing files to the module system:

  Unknown constant errors

Check whether a private definition is being accessed in the [public scope](index.md#--tech-term-public-scope). If so, the problem can be solved by making the current declaration private as well, or by placing the reference into the private scope using the `private` modifier on a field or `by` for a proof.

  Definitional equality errors, especially after porting

Failures of expected definitional equalities are usually due to a missing `expose` attribute on a definition or alternatively, if imported, an `import all`. Prefer the former if anyone outside your library might feasibly require the same access. The error message should list non-exposed definitions that could not be unfolded. This may also appear as a kernel error when a tactic directly emits proof terms that reference specific declarations without going through the elaborator, such as for proof by reflection. In this case, there is no readily available trace for debugging; consider using `@[expose]`‍```section`s generously on the closure of relevant modules.

<a id="The-Lean-Language-Reference--Source-Files-and-Modules--Module-System-Errors-and-Patterns--Recipe-for-Porting-Existing-Files"></a>
#### 5.6.1. Recipe for Porting Existing Files

To gain the benefits of the module system, source files must be made into modules. Start by enabling the module system throughout all files with minimal breaking changes:

1. Prefix all files with `module`.
2. Make all existing imports [`public`](../Definitions/Modifiers/index.md#Lean___Parser___Command___declModifiers) unless they will be used only in proofs.

- Add `import all` when errors that mention references to private data occur.
- Add `public meta import` when errors that mention “must be `meta`” occur. The `public` may be omitted when defining local-only metaprograms.

1. Prefix the remainder of the file with `@[expose] public section` or, for programming-focused files, with [`public section`](../Namespaces-and-Sections/index.md#Lean___Parser___Command___section). The latter should be used for programs that will be run but not reasoned about.

After an initial build under the module system succeeds, the dependencies between modules can be iteratively minimized. In particular, removing uses of [`public`](../Definitions/Modifiers/index.md#Lean___Parser___Command___declModifiers) and `@[expose]` will help avoid unnecessary rebuilds.

<a id="code-distribution"></a>
### 5.7. Packages, Libraries, and Targets

Lean modules are organized into [*packages*](../Build-Tools-and-Distribution/Lake/index.md#--tech-term-package), which are units of code distribution. A [package](../Build-Tools-and-Distribution/Lake/index.md#--tech-term-package) may contain multiple libraries or executables.

Code in a package that is intended for use by other Lean packages is organized into 
<a id="--tech-term-libraries"></a>
libraries. Code that is intended to be compiled and run as independent programs is organized into 
<a id="--tech-term-executables"></a>
executables. Packages, libraries, and executables are described in detail in the section on [Lake, the standard Lean build tool](../Build-Tools-and-Distribution/Lake/index.md#lake).

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Parser for a Lean module. We never actually run this parser but instead use the imperative definitions in the parent module that
return the same syntax tree structure, but add error recovery. Still, it is helpful to have a `Parser` definition
for it in order to auto-generate helpers such as the pretty printer.
```


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Unknown identifier `greeting`
```


### Display 2


```text
unsolved goals
name1 name2:String⊢ greeting name1 ++ "\n" ++ greeting name2 = "Hello, " ++ name1 ++ "\n" ++ "Hello, " ++ name2
```


### Display 3


```text
Invalid simp theorem `greeting`: Expected a definition with an exposed body
```


### Display 4


```text
Private declaration `drop2` accessed publicly; this is allowed only because the `backward.privateInPublic` option is enabled. 

Disable `backward.privateInPublic.warn` to silence this warning.
```


### Display 5


```text
@f Nat xs (@drop2✝ Nat) : List Nat
```


### Display 6


```text
tactic execution is stuck, goal contains metavariables
  ?m.3 + ?m.3 = ?m.5
```


### Display 7


```text
`simp` made no progress
```


### Display 8


```text
Invalid simp theorem `count`: Expected a definition with an exposed body
```


### Display 9


```text
Invalid `meta` definition `_aux___macroRules_termRev!__1`, `revArrays` not marked `meta`
```


### Display 10


```text
#[3, 2, 1]
```


### Display 11


```text
#[1, 2, 3, 3, 2, 1] ++ [6, 7, 8] : Array Nat
```


### Display 12


```text
Invalid definition `colors`, may not access declaration `toPalindrome` marked as `meta`
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
name1:Stringname2:String⊢ greetTwice name1 name2 = "Hello, " ++ name1 ++ "\n" ++ "Hello, " ++ name2
```


### Display 2


```text
name1:Stringname2:String⊢ greeting name1 ++ "\n" ++ greeting name2 = "Hello, " ++ name1 ++ "\n" ++ "Hello, " ++ name2
```


### Display 3


```text
name1:Stringname2:String⊢ "Hello, " ++ name1 ++ "\n" ++ ("Hello, " ++ name2) = "Hello, " ++ name1 ++ "\n" ++ "Hello, " ++ name2
```


### Display 4


```text
All goals completed! 🐙
```


### Display 5


```text
⊢ incr = fun x => x + 1
```


### Display 6


```text
n:Nat⊢ incr n = n + 1
```


### Display 7


```text
zero⊢ incr 0 = 0 + 1succn✝:Nata✝:incr n✝ = n✝ + 1⊢ incr (n✝ + 1) = n✝ + 1 + 1
```


### Display 8


```text
⊢ ?m.3 + ?m.3 = ?m.5
```


### Display 9


```text
⊢ 2 + 2 = 4
```


### Display 10


```text
α:Type u_1⊢ leaf.count = 0
```

