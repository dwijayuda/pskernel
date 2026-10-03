<a id="The-Lean-Language-Reference--Definitions--Definitions"></a>

# ProofScript — 7.3. Definitions

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Use def for general declarations, function for an explicitly parameterized definition, and const for a parameterless definition. Keep theorem, example, abbrev and opaque distinct. Expression bodies end through native boundary and suffix rules, not an added semicolon. Dependent binders and named/default arguments preserve native elaboration. Structural and well-founded recursion need the native evidence; partial definitions keep their opaque logical interpretation and separately accounted executable bodies.

**Compiler and coverage boundary.** Preserve declaration kinds, safety/reducibility metadata, native termination suffixes and local capture. An abbreviation is not a fresh nominal type.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Definitions/Definitions/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Definitions/Definitions/index.html). Source Git blob: `3fd846a9d43ddff1ca9e8ad384ccb1fb94ef3c31`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 7.3. Definitions

Definitions add a new constant to the global environment as a name that stands for a term. As part of the kernel's definitional equality, this new constant may be replaced via [δ-reduction](../../The-Type-System/index.md#--tech-term-___-next) with the term that it stands for. In the elaborator, this replacement is governed by the constant's [reducibility](../Recursive-Definitions/index.md#--tech-term-reducibility). The new constant may be [universe polymorphic](../../The-Type-System/Universes/index.md#--tech-term-universe-polymorphism), in which case occurrences may instantiate it with different universe level parameters.

Function definitions may be recursive. To preserve the consistency of Lean's type theory as a logic, recursive functions must either be opaque to the kernel (e.g. by [declaring them `partial`](../Recursive-Definitions/index.md#partial-functions)) or proven to terminate with one of the strategies described in [the section on recursive definitions](../Recursive-Definitions/index.md#recursive-definitions).

The headers and bodies of definitions are elaborated together. If the header is incompletely specified (e.g. a parameter's type or the codomain is missing), then the body may provide sufficient information for the elaborator to reconstruct the missing parts. However, [instance implicit](../../Type-Classes/index.md#--tech-term-instance-implicit) parameters must be specified in the header or as [section variables](../../Namespaces-and-Sections/index.md#--tech-term-Section-variables).

<a id="Lean___Parser___Command___declaration-next-next"></a>

**syntax**

**Definitions**

Definitions that use `:=` associate the term on the right-hand side with the constant's name. The term is wrapped in a `fun` for each parameter, and the type is found by binding the parameters in a function type. Definitions with `def` are [semireducible](../Recursive-Definitions/index.md#--tech-term-Semireducible).

<a id="Lean___Parser___Command___declaration-next-next-next"></a>

```ebnf
command ::= ...
    | declModifiers
      def declId optDeclSig := term
```

Definitions may use pattern matching. These definitions are desugared to uses of [`match`](../../Terms/Pattern-Matching/index.md#Lean___Parser___Term___match).

<a id="Lean___Parser___Command___declaration-next-next-next-next"></a>

```ebnf
command ::= ...
    | declModifiers
      def declId optDeclSig
        (| term => term)*
```

Values of structure types, or functions that return them, may be defined by providing values for their fields, following `where`:

<a id="Lean___Parser___Command___declaration-next-next-next-next-next"></a>

```ebnf
command ::= ...
    | declModifiers
      def declId optDeclSig where
        structInstField*
```

In [modules](../../Source-Files-and-Modules/index.md#--tech-term-module), the bodies of definitions defined with `def` are not exposed by default.

<a id="Lean___Parser___Command___declaration-next-next-next-next-next-next"></a>

**syntax**

**Abbreviations**

<a id="--tech-term-Abbreviations"></a>
Abbreviations are identical to definitions with `def`, except they are [reducible](../Recursive-Definitions/index.md#--tech-term-Reducible).

<a id="Lean___Parser___Command___declaration-next-next-next-next-next-next-next"></a>

```ebnf
command ::= ...
    | declModifiers
      abbrev declId optDeclSig := term
```

<a id="Lean___Parser___Command___declaration-next-next-next-next-next-next-next-next"></a>

```ebnf
command ::= ...
    | declModifiers
      abbrev declId optDeclSig
        (| term => term)*
```

<a id="Lean___Parser___Command___declaration-next-next-next-next-next-next-next-next-next"></a>

```ebnf
command ::= ...
    | declModifiers
      abbrev declId optDeclSig where
        structInstField*
```

In [modules](../../Source-Files-and-Modules/index.md#--tech-term-module), the bodies of definitions defined with `abbrev` are exposed by default.

<a id="--tech-term-Opaque-constants"></a>
*Opaque constants* are defined constants that are not subject to [δ-reduction](../../The-Type-System/index.md#--tech-term-___-next) in the kernel. They are useful for specifying the existence of some function. Unlike [axioms](../../Axioms/index.md#--tech-term-Axioms), opaque declarations can only be used for types that are inhabited, so they do not risk introducing inconsistency. Also unlike axioms, the inhabitant of the type is used in compiled code. The `implemented_by` attribute can be used to instruct the compiler to emit a call to some other function as the compilation of an opaque constant.

<a id="Lean___Parser___Command___declaration-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Opaque Constants**

Opaque definitions with right-hand sides are elaborated like other definitions. This demonstrates that the type is inhabited; the inhabitant plays no further role.

<a id="Lean___Parser___Command___declaration-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
command ::= ...
    | declModifiers
      opaque declId declSig := term
```

Opaque constants may also be specified without right-hand sides. The elaborator fills in the right-hand side by synthesizing an instance of `Inhabited`, or `Nonempty` if that fails.

<a id="Lean___Parser___Command___declaration-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
command ::= ...
    | declModifiers
      opaque declId declSig
```

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
`declId` matches `foo` or `foo.{u,v}`: an identifier possibly followed by a list of universe names
```


### Display 3


```text
`optDeclSig` matches the signature of a declaration with optional type: a list of binders and then possibly `: type`
```


### Display 4


```text
Termination hints are `termination_by` and `decreasing_by`, in that order.
```


### Display 5


```text
`declSig` matches the signature of a declaration with required type: a list of binders and then `: type`
```

