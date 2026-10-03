<a id="declaration-modifiers"></a>

# ProofScript — 7.1. Modifiers

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Use def for general declarations, function for an explicitly parameterized definition, and const for a parameterless definition. Keep theorem, example, abbrev and opaque distinct. Expression bodies end through native boundary and suffix rules, not an added semicolon. Dependent binders and named/default arguments preserve native elaboration. Structural and well-founded recursion need the native evidence; partial definitions keep their opaque logical interpretation and separately accounted executable bodies.

**Compiler and coverage boundary.** Preserve declaration kinds, safety/reducibility metadata, native termination suffixes and local capture. An abbreviation is not a fresh nominal type.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Definitions/Modifiers/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Definitions/Modifiers/index.html). Source Git blob: `1fcafd0ff6afff5df82b591bce29403965d8f05c`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 7.1. Modifiers

Declarations accept a consistent set of 
<a id="--tech-term-modifiers"></a>
*modifiers*, all of which are optional. Modifiers change some aspect of the declaration's interpretation; for example, they can add documentation or change its scope. The order of modifiers is fixed, but not every kind of declaration accepts every kind of modifier.

<a id="declModifiers"></a>

**syntax**

**Declaration Modifiers**

Modifiers consist of the following, in order, all of which are optional:

1. a documentation comment,
2. a list of [attributes](../../Attributes/index.md#--tech-term-Attributes),
3. namespace control, specifying whether the resulting name is [private](index.md#--tech-term-private) or [protected](../../Namespaces-and-Sections/index.md#--tech-term-protected),
4. the `noncomputable` keyword, which exempts a definition from compilation,
5. the `unsafe` keyword, and
6. a recursion modifier `partial` or `nonrec`, which disable termination proofs or disallow recursion entirely.

<a id="Lean___Parser___Command___declModifiers"></a>

```ebnf
declModifiers ::=
    docComment?
    attributes?
    visibility?
    noncomputable?
    unsafe?
    (partial | nonrec)?
```

<a id="--tech-term-Documentation-comments"></a>
*Documentation comments* are used to provide in-source API documentation for the declaration that they modify. Documentation comments are not, in fact comments: it is a syntax error to put a documentation comment in a position where it is not processed as documentation. They also occur in positions where some kind of text is required, but string escaping would be onerous, such as the desired messages on the [`#guard_msgs`](../../Interacting-with-Lean/index.md#Lean___guardMsgsCmd) command.

<a id="docComment"></a>

**syntax**

**Documentation Comments**

Documentation comments are like ordinary block comments, but they begin with the sequence `/--` rather than `/-`; just like ordinary comments, they are terminated with `-/`.

<a id="Lean___Parser___Command___docComment"></a>

```ebnf
docComment ::=
    /--
    ...
    -/
```

Attributes are an extensible collection of modifiers that associate additional information with declarations. They are described in a [dedicated section](../../Attributes/index.md#attributes).

If a declaration is marked 
<a id="--tech-term-private"></a>
`private`, then it is not accessible outside the module in which it is defined. If it is `protected`, then opening its namespace does not bring it into scope.

Functions marked `noncomputable` are not compiled and cannot be executed. Functions must be noncomputable if they use noncomputable reasoning principles such as the axiom of choice or excluded middle to produce data that is relevant to the answer that they return, or if they use features of Lean that are exempted from code generation for efficiency reasons, such as [recursors](../../The-Type-System/Inductive-Types/index.md#--tech-term-recursor). Noncomputable functions are very useful for specification and reasoning, even if they cannot be compiled and executed.

The `unsafe` marker exempts a definition from kernel checking and enables it to access features that may undermine Lean's guarantees. It should be used with great care, and only with a thorough understanding of Lean's internals.

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
`declModifiers` is the collection of modifiers on a declaration:
* a doc comment `/-- ... -/`
* a list of attributes `@[attr1, attr2]`
* a visibility specifier, `private` or `public`
* `protected`
* `noncomputable`
* `unsafe`
* `partial` or `nonrec`

All modifiers are optional, and have to come in the listed order.

`nestedDeclModifiers` is the same as `declModifiers`, but attributes are printed
on the same line as the declaration. It is used for declarations nested inside other syntax,
such as inductive constructors, structure projections, and `let rec` / `where` definitions.
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

