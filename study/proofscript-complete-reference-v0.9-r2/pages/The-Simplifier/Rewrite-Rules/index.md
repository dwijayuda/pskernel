<a id="simp-rewrites"></a>

# ProofScript — 15.2. Rewrite Rules

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

simp uses selected rewrite theorems and congruence reasoning to construct checked evidence. simp only restricts the simplification set; simp at changes a hypothesis or location. The normal forms chosen by a library affect proof maintenance and automation. A simplifier is not a privileged evaluator permitted to replace an unproved goal with success.

**Compiler and coverage boundary.** Track the exact simp set, local hypotheses and configuration. A changed tactic script is not necessarily a changed theorem, but a cached proof must still match its dependency identity.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [The-Simplifier/Rewrite-Rules/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/The-Simplifier/Rewrite-Rules/index.html). Source Git blob: `472664001ec882f36c80d537fd6b8b47698279ac`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 15.2. Rewrite Rules

The simplifier has three kinds of rewrite rules:

  Declarations to unfold

The simplifier will only unfold [reducible](../../Definitions/Recursive-Definitions/index.md#--tech-term-Reducible) definitions by default. However, a rewrite rule can be added for any [semireducible](../../Definitions/Recursive-Definitions/index.md#--tech-term-Semireducible) or [irreducible](../../Definitions/Recursive-Definitions/index.md#--tech-term-Irreducible) definition that causes the simplifier to unfold it as well. When the simplifier is running in definitional mode (`dsimp` and its variants), definition unfolding only replaces the defined name with its value; otherwise, it also uses the equational lemmas produced by the equation compiler.

  Equational lemmas

The simplifier can treat equality proofs as rewrite rules, in which case the left side of the equality will be replaced with the right. These equational lemmas may have any number of parameters. The simplifier instantiates parameters to make the left side of the equality match the goal, and it performs a proof search to instantiate any additional parameters.

  Simplification procedures

The simplifier supports simplification procedures, known as 
<a id="--tech-term-simprocs"></a>
*simprocs*, that use Lean metaprogramming to perform rewrites that can't be efficiently specified using equations. Lean includes simprocs for the most important operations on built-in types.

Due to [propositional extensionality](../../The-Type-System/Propositions/index.md#--tech-term-Extensionality), equational lemmas can rewrite propositions to simpler, logically equivalent propositions. When the simplifier rewrites a proof goal to `True`, it automatically closes it. As a special case of equational lemmas, propositions other than equality can be tagged as rewrite rules They are preprocessed into rules that rewrite the proposition to `True`.

<a id="Rewriting-Propositions"></a>
Rewriting Propositions 

When asked to simplify an equality of pairs:

`simp` yields a conjunction of equalities:

The default simp set contains `Prod.mk.injEq`, which shows the equivalence of the two statements:

```proofscript
Prod.mk.injEq.{u, v} {α : Type u} {β : Type v} (fst : α) (snd : β) :
  ∀ (fst_1 : α) (snd_1 : β),
    ((fst, snd) = (fst_1, snd_1)) = (fst = fst_1 ∧ snd = snd_1)
```

In addition to rewrite rules, `simp` has a number of built-in reduction rules, [controlled by the `config` parameter](../Configuring-Simplification/index.md#simp-config). Even when the simp set is empty, `simp` can replace `let`-bound variables with their values, reduce [`match`](../../Terms/Pattern-Matching/index.md#Lean___Parser___Term___match) expressions whose [discriminants](../../Terms/Pattern-Matching/index.md#--tech-term-match-discriminants) are constructor applications, reduce structure projections applied to constructors, or apply lambdas to their arguments.

## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
α:Typeβ:Typew:αy:αx:βz:β⊢ (w, x) = (y, z)
```


### Display 2


```text
α:Typeβ:Typew:αy:αx:βz:β⊢ w = y ∧ x = z
```

