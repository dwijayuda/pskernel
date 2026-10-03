<a id="namespaces-sections"></a>

# ProofScript — 6. Namespaces and Sections

[Reference home](../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Retain namespace ... end and section ... end. These commands control names, local variables, options and registrations; they do not create JavaScript objects. Section-variable inclusion follows native rules, including the distinction between theorem statement dependencies and proof-body usage. Scoped notation and instances must retain their exact environments.

## ProofScript way of writing it


```proofscript
namespace Arithmetic

function square(n: Nat): Nat := n * n

theorem squareZero: square(0) = 0 := by
  rfl

end Arithmetic
```

**Compiler and coverage boundary.** Do not replace command scopes with a generic brace parser or move declarations past environment-changing commands.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Namespaces-and-Sections/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Namespaces-and-Sections/index.html). Source Git blob: `559642a93ac9b7b2fe63120e7f22573bfa68a7ba`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 6. Namespaces and Sections

Names are organized into hierarchical 
<a id="--tech-term-namespaces"></a>
*namespaces*, which are collections of names. Namespaces are the primary means of organizing APIs in Lean: they provide an ontology of operations, grouping related items. Additionally, while this is not done by giving them names in the namespace, the effects of features such as [syntax extensions](../Notations-and-Macros/index.md#language-extension), [instances](../Type-Classes/index.md#--tech-term-instances), and [attributes](../Attributes/index.md#--tech-term-Attributes) can be attached to a namespace.

Sorting operations into namespaces organizes libraries conceptually, from a global perspective. Any given Lean file will, however, typically not use all names equally. [Sections](index.md#--tech-term-section) provide a means of ordering a local view of the globally-available collection of names, as well as a way to precisely control the scope of compiler options along with language extensions, instances, and attributes. They also allow parameters shared by many declarations to be declared centrally and propagated as needed using the [`variable`](index.md#Lean___Parser___Command___variable) command.

<a id="namespaces"></a>
### 6.1. Namespaces

Names that contain periods (that aren't inside [guillemets](../Source-Files-and-Modules/index.md#--tech-term-guillemets)) are hierarchical names; the periods separate the *components* of a name. All but the final component of a name are the namespace, while the final component is the name itself.

Namespaces serve to group related definitions, theorems, types, and other declarations. When a namespace corresponds to a type's name, [generalized field notation](../Terms/Function-Application/index.md#--tech-term-generalized-field-notation) can be used to access its contents. In addition to organizing names, namespaces also group [syntax extensions](../Notations-and-Macros/index.md#language-extension), [attributes](../Attributes/index.md#attributes), and [instances](../Type-Classes/index.md#type-classes).

Namespaces are orthogonal to [modules](../Source-Files-and-Modules/index.md#--tech-term-module): a module is a unit of code that is elaborated, compiled, and loaded together, but there is no necessary connection between a module's name and the names that it provides. A module may contain names in any namespace, and the nesting structure of hierarchical modules is unrelated to that of hierarchical namespaces.

There is a root namespace, ordinarily denoted by simply omitting a namespace. It can be explicitly indicated by beginning a name with `_root_`. This can be necessary in contexts where a name would otherwise be interpreted relative to an ambient namespace (e.g. from a [section scope](index.md#--tech-term-section-scope)) or local scope.

<a id="Explicit-Root-Namespace"></a>
Explicit Root Namespace 

Names in the current namespace take precedence over names in the root namespace. In this example, `color` in the definition of `Forest.statement` refers to `Forest.color`:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="color-_LPAR_in-Explicit-Root-Namespace_RPAR_"></a>
<a id="Forest___color-_LPAR_in-Explicit-Root-Namespace_RPAR_"></a>
<a id="Forest___statement-_LPAR_in-Explicit-Root-Namespace_RPAR_"></a>


```proofscript
const color := "yellow"
namespace Forest
const color := "green"
const statement := s!"Lemons are {color}"
end Forest
```

```proofscript
#eval Forest.statement
```

```lean
"Lemons are green"
```

Within the `Forest` namespace, references to `color` in the root namespace must be qualified with `_root_`:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="Forest___nextStatement-_LPAR_in-Explicit-Root-Namespace_RPAR_"></a>


```proofscript
namespace Forest
const nextStatement :=
  s!"Ripe lemons are {_root_.color}, not {color}"
end Forest
```

```proofscript
#eval Forest.nextStatement
```

```lean
"Ripe lemons are yellow, not green"
```

<a id="The-Lean-Language-Reference--Namespaces-and-Sections--Namespaces--Namespaces-and-Section-Scopes"></a>
#### 6.1.1. Namespaces and Section Scopes

Every [section scope](index.md#--tech-term-section-scope) has a [current namespace](index.md#--tech-term-current-namespace), which is determined by the [`namespace`](index.md#Lean___Parser___Command___namespace) command.The [`namespace`](index.md#Lean___Parser___Command___namespace) command is described in the [section on commands that introduce section scopes](index.md#scope-commands). Names that are declared within the section scope are added to the current namespace. If the declared name has more than one component, then its namespace is nested within the current namespace; the body of the declaration's current namespace is the nested namespace. Section scopes also include a set of 
<a id="--tech-term-opened-namespaces"></a>
*opened namespaces*, which are namespaces whose contents are in scope without additional qualification. [Resolving](../Terms/Identifiers/index.md#--tech-term-resolving) an identifier to a particular name takes the current namespace and opened namespaces into account. However, 
<a id="--tech-term-protected"></a>
protected declarations (that is, those with the `protected` [modifier](../Definitions/Modifiers/index.md#declaration-modifiers)) are not brought into scope when their namespace is opened. The rules for resolving identifiers into names that take the current namespace and opened namespaces into account are described in the [section on identifiers as terms](../Terms/Identifiers/index.md#identifiers-and-resolution).

<a id="Current-Namespace"></a>
Current Namespace 

Defining an inductive type results in the type's constructors being placed in its namespace, in this case as `HotDrink.coffee`, `HotDrink.tea`, and `HotDrink.cocoa`.
<a id="HotDrink-_LPAR_in-Current-Namespace_RPAR_"></a>
<a id="HotDrink___coffee-_LPAR_in-Current-Namespace_RPAR_"></a>
<a id="HotDrink___tea-_LPAR_in-Current-Namespace_RPAR_"></a>
<a id="HotDrink___cocoa-_LPAR_in-Current-Namespace_RPAR_"></a>


```proofscript
inductive HotDrink where
  | coffee
  | tea
  | cocoa
```

Outside the namespace, these names must be qualified unless the namespace is opened:

```proofscript
#check HotDrink.tea
```

```lean
HotDrink.tea : HotDrink
```

```proofscript
#check tea
```

```lean
Unknown identifier `tea`
```

```proofscript
section
open HotDrink
#check tea
end
```

```lean
HotDrink.tea : HotDrink
```

If a function is defined directly inside the `HotDrink` namespace, then the body of the function is elaborated with the current namespace set to `HotDrink`. The constructors are in scope:
<a id="HotDrink___ofString___-_LPAR_in-Current-Namespace_RPAR_"></a>


```proofscript
def HotDrink.ofString? : String → Option HotDrink
  | "coffee" => some coffee
  | "tea" => some tea
  | "cocoa" => some cocoa
  | _ => none
```

Defining another inductive type creates a new namespace:
<a id="ColdDrink-_LPAR_in-Current-Namespace_RPAR_"></a>
<a id="ColdDrink___water-_LPAR_in-Current-Namespace_RPAR_"></a>
<a id="ColdDrink___juice-_LPAR_in-Current-Namespace_RPAR_"></a>


```proofscript
inductive ColdDrink where
  | water
  | juice
```

From within the `HotDrink` namespace, `HotDrink.toString` can be defined without an explicit prefix. Defining a function in the `ColdDrink` namespace requires an explicit `_root_` qualifier to avoid defining `HotDrink.ColdDrink.toString`:
<a id="HotDrink___toString-_LPAR_in-Current-Namespace_RPAR_"></a>
<a id="ColdDrink___toString-_LPAR_in-Current-Namespace_RPAR_"></a>


```proofscript
namespace HotDrink

def toString : HotDrink → String
  | coffee => "coffee"
  | tea => "tea"
  | cocoa => "cocoa"

def _root_.ColdDrink.toString : ColdDrink → String
  | .water => "water"
  | .juice => "juice"

end HotDrink
```

The [`open`](index.md#Lean___Parser___Command___open) command opens a namespace, making its contents available in the current section scope. There are many variations on opening namespaces, providing flexibility in managing the local scope.

<a id="command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Opening Namespaces**

The [`open`](index.md#Lean___Parser___Command___open) command is used to open a namespace:

<a id="Lean___Parser___Command___open"></a>

```ebnf
command ::= ...
    | open openDecl
```

<a id="Lean___Parser___Command___openDecl"></a>

**open declaration**

**Opening Entire Namespaces**

A sequence of one or more identifiers results in each namespace in the sequence being opened:

<a id="Lean___Parser___Command___openSimple"></a>

```ebnf
openDecl ::= ...
    | ident ident*
```

Each namespace in the sequence is considered relative to all currently-open namespaces, yielding a set of namespaces. Every namespace in this set is opened before the next namespace in the sequence is processed.

<a id="Opening-Nested-Namespaces"></a>
Opening Nested Namespaces 

Namespaces to be opened are considered relative to the currently-open namespaces. If the same component occurs in different namespace paths, a single [`open`](index.md#Lean___Parser___Command___open) command can be used to open all of them by iteratively bringing each into scope. This example defines names in a variety of namespaces:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="A___a1-_LPAR_in-Opening-Nested-Namespaces_RPAR_"></a>
<a id="A___B___a2-_LPAR_in-Opening-Nested-Namespaces_RPAR_"></a>
<a id="A___B___C___a3-_LPAR_in-Opening-Nested-Namespaces_RPAR_"></a>
<a id="B___a4-_LPAR_in-Opening-Nested-Namespaces_RPAR_"></a>
<a id="B___C___a5-_LPAR_in-Opening-Nested-Namespaces_RPAR_"></a>
<a id="C___a6-_LPAR_in-Opening-Nested-Namespaces_RPAR_"></a>


```proofscript
namespace A -- _root_.A
const a1 := 0
namespace B -- _root_.A.B
const a2 := 0
namespace C -- _root_.A.B.C
const a3 := 0
end C
end B
end A
namespace B -- _root_.B
const a4 := 0
namespace C -- _root_.B.C
const a5 := 0
end C
end B
namespace C -- _root_.C
const a6 := 0
end C
```

The names are:

- `A.a1`
- `A.B.a2`
- `A.B.C.a3`
- `B.a4`
- `B.C.a5`
- `C.a6`

All six names can be brought into scope with a single iterated [`open`](index.md#Lean___Parser___Command___open) command:

```proofscript
section
open A B C
example := [a1, a2, a3, a4, a5, a6]
end
```

If the initial namespace in the command is `A.B` instead, then neither `_root_.A`, `_root_.B`, nor `_root_.B.C` is opened:

```proofscript
section
open A.B C
example := [a1, a2, a3, a4, a5, a6]
end
```

```lean
Unknown identifier `a1`
```

```lean
Unknown identifier `a4`
```

```lean
Unknown identifier `a5`
```

Opening `A.B` makes `A.B.C` visible as `C` along with `_root_.C`, so the subsequent `C` opens both.

<a id="Lean___Parser___Command___openDecl-next"></a>

**open declaration**

**Hiding Names**

A `hiding` declaration specifies a set of names that should *not* be brought into scope. In contrast to opening an entire namespace, the provided identifier must uniquely designate a namespace to be opened.

<a id="Lean___Parser___Command___openHiding"></a>

```ebnf
openDecl ::= ...
    | ident hiding ident ident*
```

<a id="Lean___Parser___Command___openDecl-next-next"></a>

**open declaration**

**Renaming**

A `renaming` declaration allows some names from the opened namespace to be renamed; they are accessible under the new name in the current section scope. The provided identifier must uniquely designate a namespace to be opened.

<a id="Lean___Parser___Command___openRenaming"></a>

```ebnf
openDecl ::= ...
    | ident renaming (ident → ident),*
```

An ASCII arrow (`->`) may be used instead of the Unicode arrow (`→`).

<a id="Lean___Parser___Command___openDecl-next-next-next"></a>

**open declaration**

**Restricted Opening**

Parentheses indicate that *only* the names listed in the parentheses should be brought into scope.

<a id="Lean___Parser___Command___openOnly"></a>

```ebnf
openDecl ::= ...
    | ident (ident ident*)
```

The indicated namespace is added to each currently-opened namespace, and each name is considered in each resulting namespace. All of the listed names must be unambiguous; that is, they must exist in exactly one of the considered namespaces.

<a id="Lean___Parser___Command___openDecl-next-next-next-next"></a>

**open declaration**

**Scoped Declarations Only**

The `scoped` keyword indicates that all scoped attributes, instances, and syntax from the provided namespaces should be opened, while not making any of the names available.

<a id="Lean___Parser___Command___openScoped"></a>

```ebnf
openDecl ::= ...
    | scoped ident ident*
```

<a id="Opening-Scoped-Declarations"></a>
Opening Scoped Declarations 

In this example, a scoped [notation](../Notations-and-Macros/Notations/index.md#--tech-term-notation) and a definition are created in the namespace `NS`:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="NS___three-_LPAR_in-Opening-Scoped-Declarations_RPAR_"></a>


```proofscript
namespace NS
scoped notation "{!{" e "}!}" => (e, e)
const three := 3
end NS
```

Outside of the namespace, the notation is not available:

```lean
def x := {!{ "pear" }!}
```

```lean
<example>:1:21-1:22: unexpected token '!'; expected '}'
```

An `open scoped` command makes the notation available:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="x-_LPAR_in-Opening-Scoped-Declarations_RPAR_"></a>


```proofscript
open scoped NS
const x := {!{ "pear" }!}
```

However, the name `NS.three` is not in scope:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
const y := three
```

```lean
Unknown identifier `three`
```

<a id="The-Lean-Language-Reference--Namespaces-and-Sections--Namespaces--Exporting-Names"></a>
#### 6.1.2. Exporting Names

<a id="--tech-term-Exporting"></a>
*Exporting* a name makes it available in the current namespace. Unlike a definition, this alias is completely transparent: uses are resolved directly to the original name. Exporting a name to the root namespace makes it available without qualification; the Lean standard library does this for names such as the constructors of `Option` and key type class methods such as `get`.

<a id="command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Exporting Names**

The `export` command adds names from other namespaces to the current namespace, as if they had been declared in it. When the current namespace is opened, these exported names are also brought into scope.

<a id="Lean___Parser___Command___export"></a>

```ebnf
command ::= ...
    | export ident (ident*)
```

Internally, exported names are registered as aliases of their targets. From the perspective of the kernel, only the original name exists; the elaborator resolves aliases as part of [resolving](../Terms/Identifiers/index.md#--tech-term-resolving) identifiers to names.

<a id="Exported-Names"></a>
Exported Names 

The declaration of the [inductive type](../The-Type-System/Inductive-Types/index.md#--tech-term-Inductive-types) `Veg.Leafy` establishes the constructors `Veg.Leafy.spinach` and `Veg.Leafy.cabbage`:
<a id="Veg___Leafy-_LPAR_in-Exported-Names_RPAR_"></a>
<a id="Veg___Leafy___spinach-_LPAR_in-Exported-Names_RPAR_"></a>
<a id="Veg___Leafy___cabbage-_LPAR_in-Exported-Names_RPAR_"></a>


```proofscript
namespace Veg
inductive Leafy where
  | spinach
  | cabbage
export Leafy (spinach)
end Veg
export Veg.Leafy (cabbage)
```

The first `export` command makes `Veg.Leafy.spinach` accessible as `Veg.spinach` because the [current namespace](index.md#--tech-term-current-namespace) is `Veg`. The second makes `Veg.Leafy.cabbage` accessible as `cabbage`, because the current namespace is the root namespace.

<a id="scopes"></a>
### 6.2. Section Scopes

Many commands have an effect for the current 
<a id="--tech-term-section-scope"></a>
*section scope* (sometimes just called “scope” when clear). Every Lean module has a section scope. Nested scopes are created via the [`namespace`](index.md#Lean___Parser___Command___namespace) and [`section`](index.md#Lean___Parser___Command___section) commands, as well as the [`in`](index.md#Lean___Parser___Command___in) command combinator.

The following data are tracked in section scopes:

  The Current Namespace

The 
<a id="--tech-term-current-namespace"></a>
*current namespace* is the namespace into which new declarations will be defined. Additionally, [name resolution](../Terms/Identifiers/index.md#--tech-term-resolving) includes all prefixes of the current namespace in the scope for global names.

  Opened Namespaces

When a namespace is 
<a id="--tech-term-opened"></a>
*opened*, its names become available without an explicit prefix in the current scope. Additionally, scoped attributes and [scoped syntax extensions](../Notations-and-Macros/Defining-New-Syntax/index.md#syntax-rules) in namespaces that have been opened are active in the current section scope.

  Options

Compiler options are reverted to their original values at the end of the scope in which they were modified.

  Section Variables

[Section variables](index.md#--tech-term-Section-variables) are names (or [instance implicit](../Type-Classes/index.md#--tech-term-instance-implicit) parameters) that are automatically added as parameters to definitions. They are also added as universally-quantified assumptions to theorems when they occur in the theorem's statement.

<a id="scope-commands"></a>
#### 6.2.1. Controlling Section Scopes

The [`section`](index.md#Lean___Parser___Command___section) command creates a new 
<a id="--tech-term-section"></a>
section scope, but does not modify the current namespace, opened namespaces, or section variables. Changes made to the section scope are reverted when the section ends. Additionally, a section may cause a set of modifiers to be applied by default to all declarations in the section. Sections may optionally be named; the `end` command that closes a named section must use the same name. If section names have multiple components (that is, if they contain `.`-separated names), then multiple nested sections are introduced. Section names have no other effect, and are a readability aid.

<a id="command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Sections**

The [`section`](index.md#Lean___Parser___Command___section) command creates a section scope that lasts either until an `end` command or the end of the file. The section header, if present, modifies the declarations in the section.

<a id="Lean___Parser___Command___section"></a>

```ebnf
command ::= ...
    | sectionHeader section ident?
```

<a id="Lean___Parser___Command___sectionHeader"></a>

**syntax**

**Section Headers**

A section header, if present, modifies the declarations in the section.

<a id="Lean___Parser___Command___sectionHeader-next"></a>

```ebnf
sectionHeader ::= ...
    | (@[expose])?
      public? noncomputable? meta?
```

If the header includes `noncomputable`, then the definitions in the section are all considered to be noncomputable, and no compiled code is generated for them. This is needed for definitions that rely on noncomputational reasoning principles such as the Axiom of Choice.

The remaining modifiers are only useful in [modules](../Source-Files-and-Modules/index.md#--tech-term-module). If the header includes `@[expose]`, then all definitions in the section are [exposed](../Source-Files-and-Modules/index.md#--tech-term-exposed). If it includes `public`, then the declarations in such a 
<a id="--tech-term-public-section"></a>
public section are public, rather than private, by default. If it includes `meta`, then the section's declarations are all placed in the [meta phase](../Source-Files-and-Modules/index.md#--tech-term-meta-phase).

<a id="Named-Section"></a>
Named Section 

The name `english` is defined in the `Greetings` namespace.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="Greetings___english-_LPAR_in-Named-Section_RPAR_"></a>


```proofscript
const Greetings.english := "Hello"
```

Outside its namespace, it cannot be evaluated.

```proofscript
#eval english
```

```lean
Unknown identifier `english`
```

Opening a section allows modifications to the global scope to be contained. This section is named `Greetings`.

```proofscript
section Greetings
```

Even though the section name matches the definition's namespace, the name is not in scope because section names are purely for readability and ease of refactoring.

```proofscript
#eval english
```

```lean
Unknown identifier `english`
```

Opening the namespace `Greetings` brings `Greetings.english` as `english`:

```proofscript
open Greetings

#eval english
```

```lean
"Hello"
```

The section's name must be used to close it.

```proofscript
end
```

```lean
Missing name after `end`: Expected the current scope name `Greetings`

Hint: To end the current scope `Greetings`, specify its name:
  end ̲G̲r̲e̲e̲t̲i̲n̲g̲s̲
```

```proofscript
end Greetings
```

When the section is closed, the effects of the [`open`](index.md#Lean___Parser___Command___open) command are reverted.

```proofscript
#eval english
```

```lean
Unknown identifier `english`
```

The [`namespace`](index.md#Lean___Parser___Command___namespace) command creates a new section scope. Within this section scope, the current namespace is the name provided in the command, interpreted relative to the current namespace in the surrounding section scope. Like sections, changes made to the section scope are reverted when the namespace's scope ends.

To close a namespace, the `end` command requires a suffix of the current namespace, which is removed. All section scopes introduced by the [`namespace`](index.md#Lean___Parser___Command___namespace) command that introduced part of that suffix are closed.

<a id="command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Namespace Declarations**

The `namespace` command modifies the current namespace by appending the provided identifier. It creates a section scope that lasts either until an `end` command or the end of the file.

<a id="Lean___Parser___Command___namespace"></a>

```ebnf
command ::= ...
    | namespace ident
```

<a id="command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Section and Namespace Terminators**

Without an identifier, `end` closes the most recently opened section, which must be anonymous.

<a id="Lean___Parser___Command___end"></a>

```ebnf
command ::= ...
    | end
```

With an identifier, it closes the most recently opened section or namespace. If it is a section, the identifier must be a suffix of the concatenated names of the sections opened since the most recent [`namespace`](index.md#Lean___Parser___Command___namespace) command. If it is a namespace, then the identifier must be a suffix of the current namespace's extensions since the most recent [`section`](index.md#Lean___Parser___Command___section) that is still open; afterwards, the current namespace will have had this suffix removed.

<a id="Lean___Parser___Command___end-next"></a>

```ebnf
command ::= ...
    | end ident
```

The [`end`](../Definitions/Recursive-Definitions/index.md#Lean___Parser___Command___mutual) that closes a [`mutual`](../Definitions/Recursive-Definitions/index.md#Lean___Parser___Command___mutual) block is part of the syntax of [`mutual`](../Definitions/Recursive-Definitions/index.md#Lean___Parser___Command___mutual), rather than the `end` command.

<a id="Nesting-Namespaces-and-Sections"></a>
Nesting Namespaces and Sections 

Namespaces and sections may be nested. A single `end` command may close one or more namespaces or one or more sections, but not a mix of the two.

After setting the current namespace to `A.B.C` with two separate commands, `B.C` may be removed with a single `end`:

```proofscript
namespace A.B
namespace C
end B.C
```

At this point, the current namespace is `A`.

Next, an anonymous section and the namespace `D.E` are opened:

```proofscript
section
namespace D.E
```

At this point, the current namespace is `A.D.E`. An `end` command cannot close all three due to the intervening section:

```proofscript
end A.D.E
```

```lean
Invalid name after `end`: Expected `D.E`, but found `A.D.E`
```

Instead, namespaces and sections must be ended separately.

```proofscript
end D.E
end
end A
```

Rather than opening a section for a single command, the [`in`](index.md#Lean___Parser___Command___in) combinator can be used to create single-command section scope. The [`in`](index.md#Lean___Parser___Command___in) combinator is right-associative, allowing multiple scope modifications to be stacked.

<a id="command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Local Section Scopes**

The `in` command combinator introduces a section scope for a single command.

<a id="Lean___Parser___Command___in"></a>

```ebnf
command ::= ...
    | command in
      command
```

<a id="Using--in--for-Local-Scopes"></a>
Using [`in`](index.md#Lean___Parser___Command___in) for Local Scopes 

The contents of a namespace can be made available for a single command using [`in`](index.md#Lean___Parser___Command___in).

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="Dessert___cupcake-_LPAR_in-Using--in--for-Local-Scopes_RPAR_"></a>


```proofscript
const Dessert.cupcake := "delicious"

open Dessert in
#eval cupcake
```

After the single command, the effects of [`open`](index.md#Lean___Parser___Command___open) are reverted.

```proofscript
#eval cupcake
```

```lean
Unknown identifier `cupcake`
```

<a id="section-variables"></a>
#### 6.2.2. Section Variables

<a id="--tech-term-Section-variables"></a>
*Section variables* are parameters that are automatically added to declarations that mention them. This occurs whether or not the option `autoImplicit` is `true`. Section variables may be implicit, strict implicit, or explicit; instance implicit section variables are treated specially.

When the name of a section variable is encountered in a non-theorem declaration, it is added as a parameter. Any instance implicit section variables that mention the variable are also added. If any of the variables that were added depend on other variables, then those variables are added as well; this process is iterated until no more dependencies remain. All section variables are added in the order in which they are declared, before all other parameters. Section variables are added only when they occur in the *statement* of a theorem. Otherwise, modifying the proof of a theorem could change its statement if the proof term made use of a section variable.

Section variables are not added as definition parameters until after the definition's body has been elaborated. This means that they cannot vary in recursive definitions, and their values are fixed. Explicit parameters may shadow section variables and can be used for definitions in which the value must vary.

Variables are declared using the [`variable`](index.md#Lean___Parser___Command___variable) command.

<a id="command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Variable Declarations**

<a id="Lean___Parser___Command___variable"></a>

```ebnf
command ::= ...
    | variable bracketedBinder bracketedBinder*
```

The bracketed binders allowed after `variable` match the [syntax used in definition headers](../Definitions/Headers-and-Signatures/index.md#bracketed-parameter-syntax).

<a id="Section-Variables"></a>
Section Variables 

In this section, automatic implicit parameters are disabled, but a number of section variables are defined.

```proofscript
section
set_option autoImplicit false
universe u
variable {α : Type u} (xs : List α) [Zero α] [Add α]
```

Because automatic implicit parameters are disabled and `β` is neither a section variable nor bound as a parameter of the function, the following definition fails:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
function addAll (lst : List β) : β :=
  lst.foldr (init := 0) (· + ·)
```

```lean
Unknown identifier `β`

Note: It is not possible to treat `β` as an implicitly bound variable here because the `autoImplicit` option is set to `false`.
```

On the other hand, not even `xs` needs to be written directly in the definition when it uses the section variables:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
const addAll :=
  xs.foldr (init := 0) (· + ·)
```

<a id="Section-Variables-and-Recursion"></a>
Section Variables and Recursion 

Section variables are fixed in recursive functions. The variable `length` represents a number that should decrease:

```proofscript
variable (length : Nat)
```

However, it cannot be used directly to define recursive functions, because the body of the function does not treat the section variable as a parameter:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
function copies (x : α) : List α :=
  match length with
  | 0 => []
  | length' + 1 => x :: copies length' x
```

The error arises because `copies` expects only one explicit argument but has received two:

```lean
Function expected at
  copies length'
but this term has type
  List Nat

Note: Expected a function because this term is being applied to the argument
  x
```

Even though `length` is already a section variable, it can be shadowed in order to define the function:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
function copies (length : Nat) (x : α) : List α :=
  match length with
  | 0 => []
  | length' + 1 => x :: copies length' x
```

To add a section variable to a theorem even if it is not explicitly mentioned in the statement, mark the variable with the `include` command. All variables marked for inclusion are added to all theorems. The `omit` command removes the inclusion mark from a variable; it's typically a good idea to use it with [`in`](index.md#Lean___Parser___Command___in).

<a id="Included-and-Omitted-Section-Variables"></a>
Included and Omitted Section Variables 

This section's variables include a predicate as well as everything needed to prove that it holds universally, along with a useless extra assumption.

```proofscript
section
variable {p : Nat → Prop}
variable (pZero : p 0) (pStep : ∀ n, p n → p (n + 1))
variable (pFifteen : p 15)
```

However, only `p` is added to this theorem's assumptions, so it cannot be proved.

```proofscript
theorem p_all : ∀ n, p n := by
  intro n
  induction n
```

The `include` command causes the additional assumptions to be added unconditionally:

```proofscript
include pZero pStep pFifteen

theorem p_all : ∀ n, p n := by
  intro n
  induction n <;> simp [*]
```

Because the spurious assumption `pFifteen` was inserted, Lean issues a warning:

```lean
automatically included section variable(s) unused in theorem `p_all`:
  pFifteen
consider restructuring your `variable` declarations so that the variables are not in scope or explicitly omit them:
  omit pFifteen in theorem ...

Note: This linter can be disabled with `set_option linter.unusedSectionVars false`
```

This can be avoided by using `omit` to remove `pFifteen`:

```proofscript
include pZero pStep pFifteen

omit pFifteen in
theorem p_all : ∀ n, p n := by
  intro n
  induction n <;> simp [*]
```

```proofscript
end
```

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


````text
Makes names from other namespaces visible without writing the namespace prefix.

Names that are made available with `open` are visible within the current `section` or `namespace`
block. This makes referring to (type) definitions and theorems easier, but note that it can also
make [scoped instances], notations, and attributes from a different namespace available.

The `open` command can be used in a few different ways:

* `open Some.Namespace.Path1 Some.Namespace.Path2` makes all non-protected names in
  `Some.Namespace.Path1` and `Some.Namespace.Path2` available without the prefix, so that
  `Some.Namespace.Path1.x` and `Some.Namespace.Path2.y` can be referred to by writing only `x` and
  `y`.

* `open Some.Namespace.Path hiding def1 def2` opens all non-protected names in `Some.Namespace.Path`
  except `def1` and `def2`.

* `open Some.Namespace.Path (def1 def2)` only makes `Some.Namespace.Path.def1` and
  `Some.Namespace.Path.def2` available without the full prefix, so `Some.Namespace.Path.def3` would
  be unaffected.

  This works even if `def1` and `def2` are `protected`.

* `open Some.Namespace.Path renaming def1 → def1', def2 → def2'` same as `open Some.Namespace.Path
  (def1 def2)` but `def1`/`def2`'s names are changed to `def1'`/`def2'`.

  This works even if `def1` and `def2` are `protected`.

* `open scoped Some.Namespace.Path1 Some.Namespace.Path2` **only** opens [scoped instances],
  notations, and attributes from `Namespace1` and `Namespace2`; it does **not** make any other name
  available.

* `open <any of the open shapes above> in` makes the names `open`-ed visible only in the next
  command or expression.

[scoped instance]: https://lean-lang.org/theorem_proving_in_lean4/type_classes.html#scoped-instances
(Scoped instances in Theorem Proving in Lean)


## Examples

```lean
/-- SKI combinators https://en.wikipedia.org/wiki/SKI_combinator_calculus -/
namespace Combinator.Calculus
  def I (a : α) : α := a
  def K (a : α) : β → α := fun _ => a
  def S (x : α → β → γ) (y : α → β) (z : α) : γ := x z (y z)
end Combinator.Calculus

section
  -- open everything under `Combinator.Calculus`, *i.e.* `I`, `K` and `S`,
  -- until the section ends
  open Combinator.Calculus

  theorem SKx_eq_K : S K x = I := rfl
end

-- open everything under `Combinator.Calculus` only for the next command (the next `theorem`, here)
open Combinator.Calculus in
theorem SKx_eq_K' : S K x = I := rfl

section
  -- open only `S` and `K` under `Combinator.Calculus`
  open Combinator.Calculus (S K)

  theorem SKxy_eq_y : S K x y = y := rfl

  -- `I` is not in scope, we have to use its full path
  theorem SKxy_eq_Iy : S K x y = Combinator.Calculus.I y := rfl
end

section
  open Combinator.Calculus
    renaming
      I → identity,
      K → konstant

  #check identity
  #check konstant
end

section
  open Combinator.Calculus
    hiding S

  #check I
  #check K
end

section
  namespace Demo
    inductive MyType
    | val

    namespace N1
      scoped infix:68 " ≋ " => BEq.beq

      scoped instance : BEq MyType where
        beq _ _ := true

      def Alias := MyType
    end N1
  end Demo

  -- bring `≋` and the instance in scope, but not `Alias`
  open scoped Demo.N1

  #check Demo.MyType.val == Demo.MyType.val
  #check Demo.MyType.val ≋ Demo.MyType.val
  -- #check Alias -- unknown identifier 'Alias'
end
```
````


### Display 2


```text
`openDecl` is the body of an `open` declaration (see `open`)
```


### Display 3


````text
Adds names from other namespaces to the current namespace.

The command `export Some.Namespace (name₁ name₂)` makes `name₁` and `name₂`:

- visible in the current namespace without prefix `Some.Namespace`, like `open`, and
- visible from outside the current namespace `N` as `N.name₁` and `N.name₂`.

## Examples

```lean
namespace Morning.Sky
  def star := "venus"
end Morning.Sky

namespace Evening.Sky
  export Morning.Sky (star)
  -- `star` is now in scope
  #check star
end Evening.Sky

-- `star` is visible in `Evening.Sky`
#check Evening.Sky.star
```
````


### Display 4


```text
A `section`/`end` pair delimits the scope of `variable`, `include`, `open`, `set_option`, and `local`
commands. Sections can be nested. `section <id>` provides a label to the section that has to appear
with the matching `end`. In either case, the `end` can be omitted, in which case the section is
closed at the end of the file.
```


### Display 5


```text
`namespace <id>` opens a section with label `<id>` that influences naming and name resolution inside
the section:
* Declarations names are prefixed: `def seventeen : ℕ := 17` inside a namespace `Nat` is given the
  full name `Nat.seventeen`.
* Names introduced by `export` declarations are also prefixed by the identifier.
* All names starting with `<id>.` become available in the namespace without the prefix. These names
  are preferred over names introduced by outer namespaces or `open`.
* Within a namespace, declarations can be `protected`, which excludes them from the effects of
  opening the namespace.

As with `section`, namespaces can be nested and the scope of a namespace is terminated by a
corresponding `end <id>` or the end of the file.

`namespace` also acts like `section` in delimiting the scope of `variable`, `open`, and other scoped commands.
```


### Display 6


```text
`end` closes a `section` or `namespace` scope. If the scope is named `<id>`, it has to be closed
with `end <id>`. The `end` command is optional at the end of a file.
```


### Display 7


````text
Declares one or more typed variables, or modifies whether already-declared variables are
  implicit.

Introduces variables that can be used in definitions within the same `namespace` or `section` block.
When a definition mentions a variable, Lean will add it as an argument of the definition. This is
useful in particular when writing many definitions that have parameters in common (see below for an
example).

Variable declarations have the same flexibility as regular function parameters. In particular they
can be [explicit, implicit][binder docs], or [instance implicit][tpil classes] (in which case they
can be anonymous). This can be changed, for instance one can turn explicit variable `x` into an
implicit one with `variable {x}`. Note that currently, you should avoid changing how variables are
bound and declare new variables at the same time; see [issue 2789] for more on this topic.

In *theorem bodies* (i.e. proofs), variables are not included based on usage in order to ensure that
changes to the proof cannot change the statement of the overall theorem. Instead, variables are only
available to the proof if they have been mentioned in the theorem header or in an `include` command
or are instance implicit and depend only on such variables.

See [*Variables and Sections* from Theorem Proving in Lean][tpil vars] for a more detailed
discussion.

[tpil vars]:
https://lean-lang.org/theorem_proving_in_lean4/dependent_type_theory.html#variables-and-sections
(Variables and Sections on Theorem Proving in Lean) [tpil classes]:
https://lean-lang.org/theorem_proving_in_lean4/type_classes.html (Type classes on Theorem Proving in
Lean) [binder docs]:
https://leanprover-community.github.io/mathlib4_docs/Lean/Expr.html#Lean.BinderInfo (Documentation
for the BinderInfo type) [issue 2789]: https://github.com/leanprover/lean4/issues/2789 (Issue 2789
on github)

## Examples

```lean
section
  variable
    {α : Type u}      -- implicit
    (a : α)           -- explicit
    [instBEq : BEq α] -- instance implicit, named
    [Hashable α]      -- instance implicit, anonymous

  def isEqual (b : α) : Bool :=
    a == b

  #check isEqual
  -- isEqual.{u} {α : Type u} (a : α) [instBEq : BEq α] (b : α) : Bool

  variable
    {a} -- `a` is implicit now

  def eqComm {b : α} := a == b ↔ b == a

  #check eqComm
  -- eqComm.{u} {α : Type u} {a : α} [instBEq : BEq α] {b : α} : Prop
end
```

The following shows a typical use of `variable` to factor out definition arguments:

```lean
variable (Src : Type)

structure Logger where
  trace : List (Src × String)
#check Logger
-- Logger (Src : Type) : Type

namespace Logger
  -- switch `Src : Type` to be implicit until the `end Logger`
  variable {Src}

  def empty : Logger Src where
    trace := []
  #check empty
  -- Logger.empty {Src : Type} : Logger Src

  variable (log : Logger Src)

  def len :=
    log.trace.length
  #check len
  -- Logger.len {Src : Type} (log : Logger Src) : Nat

  variable (src : Src) [BEq Src]

  -- at this point all of `log`, `src`, `Src` and the `BEq` instance can all become arguments

  def filterSrc :=
    log.trace.filterMap
      fun (src', str') => if src' == src then some str' else none
  #check filterSrc
  -- Logger.filterSrc {Src : Type} (log : Logger Src) (src : Src) [inst✝ : BEq Src] : List String

  def lenSrc :=
    log.filterSrc src |>.length
  #check lenSrc
  -- Logger.lenSrc {Src : Type} (log : Logger Src) (src : Src) [inst✝ : BEq Src] : Nat
end Logger
```

The following example demonstrates availability of variables in proofs:
```lean
variable
  {α : Type}    -- available in the proof as indirectly mentioned through `a`
  [ToString α]  -- available in the proof as `α` is included
  (a : α)       -- available in the proof as mentioned in the header
  {β : Type}    -- not available in the proof
  [ToString β]  -- not available in the proof

theorem ex : a = a := rfl
```
After elaboration of the proof, the following warning will be generated to highlight the unused
hypothesis:
```
included section variable '[ToString α]' is not used in 'ex', consider excluding it
```
In such cases, the offending variable declaration should be moved down or into a section so that
only theorems that do depend on it follow it until the end of the section.
````


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
"Lemons are green"
```


### Display 2


```text
"Ripe lemons are yellow, not green"
```


### Display 3


```text
HotDrink.tea : HotDrink
```


### Display 4


```text
Unknown identifier `tea`
```


### Display 5


```text
Unknown identifier `a1`
```


### Display 6


```text
Unknown identifier `a4`
```


### Display 7


```text
Unknown identifier `a5`
```


### Display 8


```text
Unknown identifier `three`
```


### Display 9


```text
Unknown identifier `english`
```


### Display 10


```text
"Hello"
```


### Display 11


```text
Missing name after `end`: Expected the current scope name `Greetings`

Hint: To end the current scope `Greetings`, specify its name:
  end ̲G̲r̲e̲e̲t̲i̲n̲g̲s̲
```


### Display 12


```text
Invalid name after `end`: Expected `D.E`, but found `A.D.E`
```


### Display 13


```text
"delicious"
```


### Display 14


```text
Unknown identifier `cupcake`
```


### Display 15


```text
Unknown identifier `β`

Note: It is not possible to treat `β` as an implicitly bound variable here because the `autoImplicit` option is set to `false`.
```


### Display 16


```text
Function expected at
  copies length'
but this term has type
  List Nat

Note: Expected a function because this term is being applied to the argument
  x
```


### Display 17


```text
unsolved goals
zerop:Nat → Prop⊢ p 0

succp:Nat → Propn✝:Nata✝:p n✝⊢ p (n✝ + 1)
```


### Display 18


```text
automatically included section variable(s) unused in theorem `p_all`:
  pFifteen
consider restructuring your `variable` declarations so that the variables are not in scope or explicitly omit them:
  omit pFifteen in theorem ...

Note: This linter can be disabled with `set_option linter.unusedSectionVars false`
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
p:Nat → Prop⊢ ∀ (n : Nat), p n
```


### Display 2


```text
p:Nat → Propn:Nat⊢ p n
```


### Display 3


```text
zerop:Nat → Prop⊢ p 0succp:Nat → Propn✝:Nata✝:p n✝⊢ p (n✝ + 1)
```


### Display 4


```text
p✝:Nat → ProppFifteen:p✝ 15p:Nat → ProppZero:p 0pStep:∀ (n : Nat), p n → p (n + 1)⊢ ∀ (n : Nat), p n
```


### Display 5


```text
p✝:Nat → ProppFifteen:p✝ 15p:Nat → ProppZero:p 0pStep:∀ (n : Nat), p n → p (n + 1)n:Nat⊢ p n
```


### Display 6


```text
zerop✝:Nat → ProppFifteen:p✝ 15p:Nat → ProppZero:p 0pStep:∀ (n : Nat), p n → p (n + 1)⊢ p 0succp✝:Nat → ProppFifteen:p✝ 15p:Nat → ProppZero:p 0pStep:∀ (n : Nat), p n → p (n + 1)n✝:Nata✝:p n✝⊢ p (n✝ + 1)
```


### Display 7


```text
All goals completed! 🐙
```


### Display 8


```text
p:Nat → ProppZero:p 0pStep:∀ (n : Nat), p n → p (n + 1)⊢ ∀ (n : Nat), p n
```


### Display 9


```text
p:Nat → ProppZero:p 0pStep:∀ (n : Nat), p n → p (n + 1)n:Nat⊢ p n
```


### Display 10


```text
zerop:Nat → ProppZero:p 0pStep:∀ (n : Nat), p n → p (n + 1)⊢ p 0succp:Nat → ProppZero:p 0pStep:∀ (n : Nat), p n → p (n + 1)n✝:Nata✝:p n✝⊢ p (n✝ + 1)
```

