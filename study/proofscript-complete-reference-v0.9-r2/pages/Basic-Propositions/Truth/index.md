<a id="true-false"></a>

# ProofScript — 19.1. Truth

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Truth and falsity, conjunction/disjunction, implication, negation, universal/existential quantification and equality keep their native definitions. An existential proof contains logical witness evidence, but elimination restrictions determine when it can construct runtime data. Equality transports dependent values only through justified terms. Computed Boolean comparison does not automatically produce equality evidence.

**Compiler and coverage boundary.** Preserve Prop elimination, proof irrelevance and universe rules. Erasure may remove irrelevant proofs but not the data they certify.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Basic-Propositions/Truth/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Basic-Propositions/Truth/index.html). Source Git blob: `c9a2f43cd9e2144392a2f6f566d51cd49c08d4da`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 19.1. Truth

Fundamentally, there are only two propositions in Lean: `True` and `False`. The axiom of propositional extensionality (`propext`) allows propositions to be considered equal when they are logically equivalent, and every true proposition is logically equivalent to `True`. Similarly, every false proposition is logically equivalent to `False`.

`True` is an inductively defined proposition with a single constructor that takes no parameters. It is always possible to prove `True`. `False`, on the other hand, is an inductively defined proposition with no constructors. Proving it requires finding an inconsistency in the current context.

Both `True` and `False` are [subsingletons](../../The-Type-System/Inductive-Types/index.md#subsingleton-elimination); this means that they can be used to compute inhabitants of non-propositional types. For `True`, this amounts to ignoring the proof, which is not informative. For `False`, this amounts to a demonstration that the current code is unreachable and does not need to be completed.

<a id="True___intro"></a>

**inductive proposition**

```text
True : Prop
```

`True` is a proposition and has only an introduction rule, `True.intro : True`. In other words, `True` is simply true, and has a canonical proof, `True.intro` For more information: [Propositional Logic](https://lean-lang.org/theorem_proving_in_lean4/propositions_and_proofs.html#propositional-logic)

**Constructors**

```text
True.intro : True
```

`True` is true, and `True.intro` (or more commonly, `trivial`) is the proof.

<a id="False"></a>

**inductive proposition**

```text
False : Prop
```

`False` is the empty proposition. Thus, it has no introduction rules. It represents a contradiction. `False` elimination rule, `False.rec`, expresses the fact that anything follows from a contradiction. This rule is sometimes called ex falso (short for ex falso sequitur quodlibet), or the principle of explosion. For more information: [Propositional Logic](https://lean-lang.org/theorem_proving_in_lean4/propositions_and_proofs.html#propositional-logic)

**Constructors**

<a id="False___elim"></a>

**def**

```text
False.elim.{u} {C : Sort u} (h : False) : C
```

`False.elim : False → C` says that from `False`, any desired proposition `C` holds. Also known as ex falso quodlibet (EFQ) or the principle of explosion.

The target type is actually `C : Sort u` which means it works for both propositions and types. When executed, this acts like an "unreachable" instruction: it is **undefined behavior** to run, but it will probably print "unreachable code". (You would need to construct a proof of false to run it anyway, which you can only do using `sorry` or unsound axioms.)

<a id="Dead-Code-and-Subsingleton-Elimination"></a>
Dead Code and Subsingleton Elimination 

The fourth branch in the definition of `f` is unreachable, so no concrete `String` value needs to be provided:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="f-_LPAR_in-Dead-Code-and-Subsingleton-Elimination_RPAR_"></a>


```proofscript
function f (n : Nat) : String :=
  if h1 : n < 11 then
    "Small"
  else if h2 : n > 13 then
    "Large"
  else if h3 : n % 2 = 1 then
    "Odd"
  else if h4 : n ≠ 12 then
    False.elim (by omega)
  else "Twelve"
```

In this example, `False.elim` indicates to Lean that the current local context is logically inconsistent: proving `False` suffices to abandon the branch.

Similarly, the definition of `g` appears to have the potential to be non-terminating. However, the recursive call occurs on an unreachable path through the program. The proof automation used for producing termination proofs can detect that the local assumptions are inconsistent.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="g-_LPAR_in-Dead-Code-and-Subsingleton-Elimination_RPAR_"></a>


```proofscript
function g (n : Nat) : String :=
  if n < 11 then
    "Small"
  else if n > 13 then
    "Large"
  else if n % 2 = 1 then
    "Odd"
  else if n ≠ 12 then
    g (n + 1)
  else "Twelve"
termination_by n
```

## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
n:Nath1:¬n < 11h2:¬n > 13h3:¬n % 2 = 1h4:n ≠ 12⊢ False
```


### Display 2


```text
All goals completed! 🐙
```

