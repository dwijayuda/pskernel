<a id="The-Lean-Language-Reference--The--grind--tactic--Local-Definitions"></a>

# ProofScript — 16.3. Local Definitions

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

grind combines reasoning such as congruence closure, propagation, case analysis, E-matching and algebraic/arithmetic procedures. Its selected lemmas, annotations and solver parameters determine the search problem. Keep these as native proof-producing facilities, not as a replacement for the kernel. The mirrored subchapters and examples retain their individual scopes and failure cases.

**Compiler and coverage boundary.** Lean 4.34 stable parameter-list changes for lia/grobner are inherited only under the selected tactic capability. A timeout must remain an incomplete-search result.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [The--grind--tactic/Local-Definitions/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/The--grind--tactic/Local-Definitions/index.html). Source Git blob: `56f51972e76866dbab5f9726f500501c7ce0f482`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 16.3. Local Definitions

`grind` has two flags that control how it treats local definitions with `let`. They are enabled by default, but duplicating the local definition's value can lead to the term exploding in size; consider disabling them when working with terms that contain many nested `let`s.

  `zeta` (default `true`)

This controls whether `grind` performs [ζ-reduction](../../The-Type-System/index.md#--tech-term-___-next-next-next). Unless this flag is disabled, terms that contain a `let` are reduced before they are added to the whiteboard, so that `let x := 5; x + x` is reduced to `5 + 5` before further processing. If it is disabled, the term is not reduced.

  `zetaDelta` (default `true`)

This flag controls whether `grind` replaces variables in terms that have local definitions in the context with their definitions.

If a proof goal is `let x := 5; (x + x = 10)`, running

results in a proof state in which the definition of `x` is in the context:

Running `grind` succeeds, because `5` is substituted for `x`. Without the `zetaDelta` flag, it fails.

## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
x:Nat := 5⊢ x + x = 10
```


### Display 2


```text
All goals completed! 🐙
```

