<a id="The-Lean-Language-Reference--Definitions--Example-Declarations"></a>

# ProofScript — 7.5. Example Declarations

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Use def for general declarations, function for an explicitly parameterized definition, and const for a parameterless definition. Keep theorem, example, abbrev and opaque distinct. Expression bodies end through native boundary and suffix rules, not an added semicolon. Dependent binders and named/default arguments preserve native elaboration. Structural and well-founded recursion need the native evidence; partial definitions keep their opaque logical interpretation and separately accounted executable bodies.

**Compiler and coverage boundary.** Preserve declaration kinds, safety/reducibility metadata, native termination suffixes and local capture. An abbreviation is not a fresh nominal type.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Definitions/Example-Declarations/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Definitions/Example-Declarations/index.html). Source Git blob: `46d915f30d7ce5a51a47b401e64aa57bd03e7b87`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 7.5. Example Declarations

An 
<a id="--tech-term-example"></a>
example is an anonymous definition that is elaborated and then discarded. Examples are useful for incremental testing during development and to make it easier to understand a file.

<a id="Lean___Parser___Command___declaration-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Examples**

<a id="Lean___Parser___Command___declaration-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
command ::= ...
    | declModifiers
      example optDeclSig := term
```

<a id="Lean___Parser___Command___declaration-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
command ::= ...
    | declModifiers
      example optDeclSig
        (| term => term)*
```

<a id="Lean___Parser___Command___declaration-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

```ebnf
command ::= ...
    | declModifiers
      example optDeclSig where
        structInstField*
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
`optDeclSig` matches the signature of a declaration with optional type: a list of binders and then possibly `: type`
```


### Display 3


```text
Termination hints are `termination_by` and `decreasing_by`, in that order.
```

