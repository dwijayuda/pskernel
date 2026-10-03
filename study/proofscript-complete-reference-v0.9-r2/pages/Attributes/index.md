<a id="attributes"></a>

# ProofScript — 9. Attributes

[Reference home](../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Attributes attach native metadata or invoke registered handlers. They may affect elaboration, simplification, instances, code generation or documentation. They do not grant proof authority. Keep the actual attribute names, scopes and handler identities rather than replacing them with TypeScript decorators.

**Compiler and coverage boundary.** Unknown attributes are unsupported unless declared in the environment. Tactic or derive outputs still require normal checking, and host execution permissions are a separate boundary.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Attributes/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Attributes/index.html). Source Git blob: `f42e5af784c3087365dc0b115af5aef21bbc9967`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 9. Attributes

<a id="--tech-term-Attributes"></a>
*Attributes* are an extensible set of compile-time annotations on declarations. They can be added as a [declaration modifier](../Definitions/Modifiers/index.md#declaration-modifiers) or using the [`attribute`](index.md#Lean___Parser___Command___attribute) command.

Attributes can associate information with declarations in compile-time tables (including [custom simp sets](../The-Simplifier/Simp-sets/index.md#--tech-term-Custom-simp-sets), [macros](../Notations-and-Macros/Macros/index.md#--tech-term-Macros), and [instances](../Type-Classes/index.md#--tech-term-instances)), impose additional requirements on definitions (e.g. rejecting them if their type is not a type class), or generate additional code. As with [macros](../Notations-and-Macros/Macros/index.md#--tech-term-Macros) and custom [elaborators](../Notations-and-Macros/Elaborators/index.md#--tech-term-elaborators) for terms, commands, and tactics, the [syntax category](../Notations-and-Macros/Defining-New-Syntax/index.md#--tech-term-syntax-categories) `attr` of attributes is designed to be extended, and there is a table that maps each extension to a compile-time program that interprets it.

Attributes are applied as 
<a id="--tech-term-attribute-instances"></a>
*attribute instances* that pair a scope indicator with an attribute. These may occur either in attributes as declaration modifiers or the stand-alone [`attribute`](index.md#Lean___Parser___Command___attribute) command.

<a id="Lean___Parser___Term___attrInstance"></a>

**syntax**

**Attribute Instances**

<a id="Lean___Parser___Term___attrInstance-next"></a>

```ebnf
attrInstance ::= ...
    | attrKind attr
```

An `attrKind` is the optional [attribute scope](index.md#scoped-attributes) keywords `local` or `scoped`. These control the visibility of the attribute's effects. The attribute itself is anything from the extensible [syntax category](../Notations-and-Macros/Defining-New-Syntax/index.md#--tech-term-syntax-categories) `attr`.

The attribute system is very powerful: attributes can associate arbitrary information with declarations and generate any number of helpers. This imposes some design trade-offs: storing this information takes space, and retrieving it takes time. As a result, some attributes can only be applied to a declaration in the module where the declaration is defined. This allows lookups to be much faster in large projects, because they don't need to examine data for all modules. Each attribute determines how to store its own metadata and what the appropriate tradeoff between flexibility and performance is for a given use case.

<a id="The-Lean-Language-Reference--Attributes--Attributes-as-Modifiers"></a>
### 9.1. Attributes as Modifiers

Attributes can be added to declarations as a [declaration modifier](../Definitions/Modifiers/index.md#declaration-modifiers). They are placed between the documentation comment and the visibility modifiers.

<a id="Lean___Parser___Term___attributes"></a>

**syntax**

**Attributes**

<a id="Lean___Parser___Term___attributes-next"></a>

```ebnf
attributes ::=
    @[attrInstance,*]
```

<a id="The-Lean-Language-Reference--Attributes--The--attribute--Command"></a>
### 9.2. The attribute Command

The [`attribute`](index.md#Lean___Parser___Command___attribute) command can be used to modify a declaration's attributes. Some example uses include:

- registering a pre-existing declaration as an [instance](../Type-Classes/index.md#--tech-term-instances) in the local scope by adding `instance`,
- marking a pre-existing theorem as a simp lemma or an extensionality lemma, using `simp` or `ext`, and
- temporarily removing a simp lemma from the default [simp set](../The-Simplifier/Simp-sets/index.md#--tech-term-simp-set).

<a id="command-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Attribute Modification**

The [`attribute`](index.md#Lean___Parser___Command___attribute) command adds or removes attributes from an existing declaration. The identifier is the name whose attributes are being modified.

<a id="Lean___Parser___Command___attribute"></a>

```ebnf
command ::= ...
    | attribute [(eraseAttr | attrInstance),*] ident
```

In addition to attribute instances that add an attribute to an existing declaration, some attributes can be removed; this is called 
<a id="--tech-term-erasing"></a>
*erasing* the attribute. Attributes can be erased by preceding their name with `-`. Not all attributes support erasure, however.

<a id="Lean___Parser___Command___eraseAttr"></a>

**syntax**

**Erasing Attributes**

Attributes are erased by preceding their name with a `-`.

<a id="Lean___Parser___Command___eraseAttr-next"></a>

```ebnf
eraseAttr ::= ...
    | -ident
```

<a id="scoped-attributes"></a>
### 9.3. Scoped Attributes

Many attributes can be applied in a particular scope. This determines whether the attribute's effect is visible only in the current section scope, in namespaces that open the current namespace, or everywhere. These scope indications are also used to control [syntax extensions](../Notations-and-Macros/Defining-New-Syntax/index.md#syntax-rules) and [type class instances](../Type-Classes/Instance-Declarations/index.md#instance-attribute). Each attribute is responsible for defining precisely what these terms mean for its particular effect.

<a id="attrKind"></a>

**syntax**

**Attribute Scopes**

Globally-scoped declarations (the default) are in effect whenever the [module](../Source-Files-and-Modules/index.md#--tech-term-module) in which they're established is transitively imported. They are indicated by the absence of another scope modifier.

<a id="Lean___Parser___Term___attrKind"></a>

```ebnf
attrKind ::=
```

Locally-scoped declarations are in effect only for the extent of the [section scope](../Namespaces-and-Sections/index.md#--tech-term-section-scope) in which they are established.

<a id="Lean___Parser___Term___attrKind-next"></a>

```ebnf
attrKind ::= ...
    | local
```

Scoped declarations are in effect whenever the [namespace](../Namespaces-and-Sections/index.md#--tech-term-current-namespace) in which they are established is opened.

<a id="Lean___Parser___Term___attrKind-next-next"></a>

```ebnf
attrKind ::= ...
    | scoped
```

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
`attrKind` matches `("scoped" <|> "local")?`, used before an attribute like `@[local simp]`.
```

