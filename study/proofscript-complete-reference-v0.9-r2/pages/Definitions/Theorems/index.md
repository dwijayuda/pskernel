<a id="The-Lean-Language-Reference--Definitions--Theorems"></a>

# ProofScript — 7.4. Theorems

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Use def for general declarations, function for an explicitly parameterized definition, and const for a parameterless definition. Keep theorem, example, abbrev and opaque distinct. Expression bodies end through native boundary and suffix rules, not an added semicolon. Dependent binders and named/default arguments preserve native elaboration. Structural and well-founded recursion need the native evidence; partial definitions keep their opaque logical interpretation and separately accounted executable bodies.

**Compiler and coverage boundary.** Preserve declaration kinds, safety/reducibility metadata, native termination suffixes and local capture. An abbreviation is not a fresh nominal type.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Definitions/Theorems/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Definitions/Theorems/index.html). Source Git blob: `ff48488f9e4a31dea338e2c55e04ada9815dbe16`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 7.4. Theorems

Because [propositions](../../The-Type-System/Propositions/index.md#--tech-term-Propositions) are types whose inhabitants count as proofs, 
<a id="--tech-term-theorems"></a>
theorems and definitions are technically very similar. However, because their use cases are quite different, they differ in many details:

- The theorem statement must be a proposition. The types of definitions may inhabit any [universe](../../The-Type-System/Universes/index.md#--tech-term-universes).
- A theorem's header (that is, the theorem statement) is completely elaborated before the body is elaborated. Section variables only become parameters to the theorem if they (or their dependents) are mentioned in the header. This prevents changes to a proof from unintentionally changing the theorem statement.
- Theorems are [irreducible](../Recursive-Definitions/index.md#--tech-term-Irreducible) by default. Because all proofs of the same proposition are [definitionally equal](../../The-Type-System/index.md#--tech-term-definitional-equality), there are few reasons to unfold a theorem.

Theorems may be recursive, subject to the same conditions as [recursive function definitions](../Recursive-Definitions/index.md#recursive-definitions). However, it is more common to use tactics such as `induction` or `fun_induction` instead.

<a id="Lean___Parser___Command___declaration-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Theorems**

The syntax of theorems is like that of definitions, except the codomain (that is, the theorem statement) in the signature is mandatory.

<a id="Lean___Parser___Command___declaration-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
command ::= ...
    | declModifiers
      theorem declId declSig := term
```

<a id="Lean___Parser___Command___declaration-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
command ::= ...
    | declModifiers
      theorem declId declSig
        (| term => term)*
```

<a id="Lean___Parser___Command___declaration-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
command ::= ...
    | declModifiers
      theorem declId declSig where
        structInstField*
```

In [modules](../../Source-Files-and-Modules/index.md#--tech-term-module), proofs of theorems are not exposed by default.

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
`declSig` matches the signature of a declaration with required type: a list of binders and then `: type`
```


### Display 4


```text
Termination hints are `termination_by` and `decreasing_by`, in that order.
```

