<a id="bound-variable-name-hints"></a>

# ProofScript — 14.7. Naming Bound Variables

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Tactics construct proof terms, and the checker decides whether those terms prove the requested claim. Use the inherited tactic language, including goal management, rewriting, induction and conv. Semicolon sequencing and the apply-to-all-goals combinator are distinct. Native grammar displays and tactic signatures below describe the selected environment, not a second ProofScript tactic system.

**Compiler and coverage boundary.** Term decorations may appear only in explicitly lifted tactic term slots. Preserve goal names, hygiene and source maps. Search failure is not proof of falsity.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Tactic-Proofs/Naming-Bound-Variables/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Tactic-Proofs/Naming-Bound-Variables/index.html). Source Git blob: `0ccd1ccf5cd57eb7287ef5a08136c2d0294af15c`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 14.7. Naming Bound Variables

When the [simplifier](../../The-Simplifier/index.md#the-simplifier) or the `rw` tactic introduce new binding forms such as function parameters, they select a name for the bound variable based on the one in the statement of the rewrite rule being applied. This name is made unique if necessary. In some situations, such as [preprocessing definitions for termination proofs that use well-founded recursion](../../Definitions/Recursive-Definitions/index.md#well-founded-preprocessing), the names that appear in termination proof obligations should be the corresponding names written in the original function definition.

The `binderNameHint` [gadget](../../Type-Classes/Class-Declarations/index.md#--tech-term-gadgets) can be used to indicate that a bound variable should be named according to the variables bound in some other term. By convention, the term `()` is used to indicate that a name should *not* be taken from the original definition.

<a id="binderNameHint"></a>

**def**

```text
binderNameHint.{u, v, w} {α : Sort u} {β : Sort v} {γ : Sort w} (v : α)
  (binder : β) (e : γ) : γ
```

The expression `binderNameHint v binder e` defined to be `e`.

If it is used on the right-hand side of an equation that is used for rewriting by `rw` or `simp`, and `v` is a local variable, and `binder` is an expression that (after beta-reduction) is a binder (`fun w => …` or `∀ w, …`), then it will rename `v` to the name used in that binder, and remove the `binderNameHint`.

A typical use of this gadget would be as follows; the gadget ensures that after rewriting, the local variable is still `name`, and not `x`:

```text
theorem all_eq_not_any_not (l : List α) (p : α → Bool) :
    l.all p = !l.any fun x => binderNameHint x p (!p x) := sorry

example (names : List String) : names.all (fun name => "Waldo".isPrefixOf name) = true := by
  rw [all_eq_not_any_not]
  -- ⊢ (!names.any fun name => !"Waldo".isPrefixOf name) = true
```

If `binder` is not a binder, then the name of `v` attains a macro scope. This only matters when the resulting term is used in a non-hygienic way, e.g. in termination proofs for well-founded recursion.

This gadget is supported by

- `simp`, `dsimp` and `rw` in the right-hand-side of an equation
- `simp` in the assumptions of congruence rules

It is ineffective in other positions (hypotheses of rewrite rules) or when used by other tactics (e.g. `apply`).
