<a id="The-Lean-Language-Reference--The--grind--tactic--Reducibility"></a>

# ProofScript — 16.13. Reducibility

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

grind combines reasoning such as congruence closure, propagation, case analysis, E-matching and algebraic/arithmetic procedures. Its selected lemmas, annotations and solver parameters determine the search problem. Keep these as native proof-producing facilities, not as a replacement for the kernel. The mirrored subchapters and examples retain their individual scopes and failure cases.

**Compiler and coverage boundary.** Lean 4.34 stable parameter-list changes for lia/grobner are inherited only under the selected tactic capability. A timeout must remain an incomplete-search result.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [The--grind--tactic/Reducibility/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/The--grind--tactic/Reducibility/index.html). Source Git blob: `2134ebbf445abaab6234c61a4e371764cf96a31b`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 16.13. Reducibility

[Reducible](../../Definitions/Recursive-Definitions/index.md#--tech-term-Reducible) definitions in terms are eagerly unfolded by `grind`. This enables more efficient definitional equality comparisons and indexing.

<a id="Reducibility-and-Congruence-Closure"></a>
Reducibility and Congruence Closure 

The definition of `one` is not [reducible](../../Definitions/Recursive-Definitions/index.md#--tech-term-Reducible):

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="one-_LPAR_in-Reducibility-and-Congruence-Closure_RPAR_"></a>


```proofscript
const one := 1
```

This means that `grind` does not unfold it:

```proofscript
example : one = 1 := by grind
```
<a id="--verso-unique-1721"></a>


```lean
`grind` failed
grindh:¬one = 1⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] ¬one = 1[eqc] False propositions[prop] one = 1[cutsat] Assignment satisfying linear constraints[assign] one := 2
```

`two`, on the other hand, is an abbreviation and thus reducible:
<a id="two-_LPAR_in-Reducibility-and-Congruence-Closure_RPAR_"></a>


```proofscript
abbrev two := 2
```

`grind` unfolds `two` before adding it to the “whiteboard”, allowing the proof to be completed immediately:

```proofscript
example : two = 2 := by grind
```

E-matching patterns also unfold reducible definitions. The patterns generated for theorems about abbreviations are expressed in terms of the unfolded abbreviations. Abbreviations should not generally be recursive; in particular, when using `grind`, recursive abbreviations can result in poor indexing performance and unpredictable patterns.

<a id="E-matching-and-Unfolding-Abbreviations"></a>
E-matching and Unfolding Abbreviations 

When adding `grind` annotations to theorems, E-matching patterns are generated based on the theorem statement. These patterns determine when the theorem is instantiated. The theorem `one_eq_1` mentions the [semireducible](../../Definitions/Recursive-Definitions/index.md#--tech-term-Semireducible) definition `one`, and the resulting pattern is also `one`:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="one-_LPAR_in-E-matching-and-Unfolding-Abbreviations_RPAR_"></a>
<a id="one_eq_1-_LPAR_in-E-matching-and-Unfolding-Abbreviations_RPAR_"></a>


```proofscript
const one := 1

@[grind? =]
theorem one_eq_1 : one = 1 := by rfl
```

```lean
one_eq_1: [one]
```

Applying the same annotation to a theorem about the [`reducible`](../../Definitions/Recursive-Definitions/index.md#--tech-term-Reducible) abbreviation `two` results in a pattern in which `two` is unfolded:
<a id="two-_LPAR_in-E-matching-and-Unfolding-Abbreviations_RPAR_"></a>
<a id="two_eq_2-_LPAR_in-E-matching-and-Unfolding-Abbreviations_RPAR_"></a>


```proofscript
abbrev two := 2

@[grind? =]
theorem two_eq_2: two = 2 := by grind
```

```lean
two_eq_2: [@OfNat.ofNat `[Nat] `[2] `[instOfNatNat 2]]
```

<a id="Recursive-Abbreviations-and--grind"></a>
Recursive Abbreviations and `grind` 

Using the `grind` attribute to add E-matching patterns for a recursive abbreviation's [equational lemmas](../../Elaboration-and-Compilation/index.md#--tech-term-equational-lemmas) does not result in useful patterns for recursive abbreviations. The `@[grind?]` attribute on this definition of the Fibonacci function results in three patterns, each corresponding to one of the three possibilities:

```proofscript
@[grind?]
def fib : Nat → Nat
  | 0 => 0
  | 1 => 1
  | n + 2 => fib n + fib (n + 1)
```

```lean
fib.eq_1: [fib `[0]]
```

```lean
fib.eq_2: [fib `[1]]
```

```lean
fib.eq_3: [fib (#0 + 2)]
```

Replacing the definition with an abbreviation results in patterns in which occurrences of the function are unfolded. These patterns are not particularly useful:

```proofscript
@[grind?]
abbrev fib : Nat → Nat
  | 0 => 0
  | 1 => 1
  | n + 2 => fib n + fib (n + 1)
```

```lean
fib.eq_1: [@OfNat.ofNat `[Nat] `[0] `[instOfNatNat 0]]
```

```lean
fib.eq_2: [@OfNat.ofNat `[Nat] `[1] `[instOfNatNat 1]]
```

```lean
fib.eq_3: [@HAdd.hAdd `[Nat] `[Nat] `[Nat] `[instHAdd] (fib #0) (fib (#0 + 1))]
```

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
`grind` failed
grindh:¬one = 1⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] ¬one = 1[eqc] False propositions[prop] one = 1[cutsat] Assignment satisfying linear constraints[assign] one := 2
```


### Display 2


```text
one_eq_1: [one]
```


### Display 3


```text
two_eq_2: [@OfNat.ofNat `[Nat] `[2] `[instOfNatNat 2]]
```


### Display 4


```text
fib.eq_3: [fib (#0 + 2)]fib.eq_1: [fib `[0]]fib.eq_2: [fib `[1]]
```


### Display 5


```text
fib.eq_3: [@HAdd.hAdd `[Nat] `[Nat] `[Nat] `[instHAdd] (fib #0) (fib (#0 + 1))]fib.eq_1: [@OfNat.ofNat `[Nat] `[0] `[instOfNatNat 0]]fib.eq_2: [@OfNat.ofNat `[Nat] `[1] `[instOfNatNat 1]]
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
⊢ one = 1
```


### Display 2


```text
All goals completed! 🐙
```


### Display 3


```text
⊢ two = 2
```

