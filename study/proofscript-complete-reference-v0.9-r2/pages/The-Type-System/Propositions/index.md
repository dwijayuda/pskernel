<a id="propositions"></a>

# ProofScript — 4.2. Propositions

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Functions, propositions, universes, inductives and quotients retain their Lean meaning. A proof is an inhabitant of a proposition; Boolean truth is not the same object. Parameters may determine later parameter types. Universe levels cannot be approximated as machine integer ranks. Inductive constructors require the native positivity, universe, parameter and index checks. Quotient eliminators must respect their relation, rather than use runtime object identity.

**Compiler and coverage boundary.** Use exact declared core rules and axiom policies. Library names and hash matches alone cannot authorize primitive reductions. Soundness and exact acceptance equivalence are distinct obligations.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [The-Type-System/Propositions/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/The-Type-System/Propositions/index.html). Source Git blob: `39dcac72c18a0b1224585afe35e2655f76e4ae31`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 4.2. Propositions

<a id="--tech-term-Propositions"></a>
Propositions are meaningful statements that admit proof. 
<a id="--index-"></a>
 Nonsensical statements are not propositions, but false statements are. All propositions are classified by `Prop`.

Propositions have the following properties:

  Definitional proof irrelevance

Any two proofs of the same proposition are completely interchangeable.

  Run-time irrelevance

Propositions are erased from compiled code.

  Impredicativity

Propositions may quantify over types from any universe whatsoever.

  Restricted Elimination

With the exception of [subsingletons](../Inductive-Types/index.md#--tech-term-subsingleton), propositions cannot be eliminated into non-proposition types.

<a id="--tech-term-Extensionality"></a>
Extensionality 
<a id="--index--next"></a>

Any two logically equivalent propositions can be proven to be equal with the `propext` axiom.

<a id="propext"></a>

**axiom**

```text
propext {a b : Prop} : (a ↔ b) → a = b
```

The [axiom](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=axioms) of **propositional extensionality**. It asserts that if propositions `a` and `b` are logically equivalent (that is, if `a` can be proved from `b` and vice versa), then `a` and `b` are *equal*, meaning `a` can be replaced with `b` in all contexts.

The standard logical connectives provably respect propositional extensionality. However, an axiom is needed for higher order expressions like `P a` where `P : Prop → Prop` is unknown, as well as for equality. Propositional extensionality is intuitionistically valid.
