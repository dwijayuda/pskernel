<a id="lean___inductionWithNoAlts"></a>

# ProofScript — About: inductionWithNoAlts

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

The inherited error catalog explains invalid constructors, dependent eliminations, missing instances, unresolved names and other rejected programs. These are examples of failure, not snippets to copy into a successful program. Preserve native error IDs while mapping source positions back to .ps. A syntax overlay error should be distinguished from native elaboration, proof search, kernel rejection and unavailable target primitives.

**Compiler and coverage boundary.** Keep malformed, unsupported, cancelled, exhausted and internal-error outcomes distinct. Never turn an unsupported example into a permissive fallback or suppress a failed proof to make documentation appear runnable.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Error-Explanations/About___--inductionWithNoAlts/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Error-Explanations/About___--inductionWithNoAlts/index.html). Source Git blob: `5eb8248c6fa41c576d6b9ef9369d588aeed6887e`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## About: inductionWithNoAlts

Error code: `lean.inductionWithNoAlts`

*Induction pattern with nontactic in natural-number-game-style `with` clause.*

**Severity:**Error**Since:**4.26.0

Tactic-based proofs using induction in Lean need to use a pattern-matching-like notation to describe individual cases of the proof. However, the `induction'` tactic in Mathlib and the specialized `induction` tactic for natural numbers used in the Natural Number Game follows a different pattern.

<a id="The-Lean-Language-Reference--Error-Explanations--About___--inductionWithNoAlts--Examples"></a>
### Examples

<a id="Adding-Explicit-Cases-to-an-Induction-Proof"></a>
Adding Explicit Cases to an Induction Proof   
<a id="error-example-next-next-next-next-next-button-0"></a>
Original
<a id="error-example-next-next-next-next-next-button-1"></a>
Fixed  
<a id="error-example-next-next-next-next-next-panel-0"></a>

```proofscript
theorem zero_mul (m : Nat) : 0 * m = 0 := by
  induction m with n n_ih
  rw [Nat.mul_zero]
  rw [Nat.mul_succ]
  rw [Nat.add_zero]
  rw [n_ih]
```

```lean
Invalid syntax for induction tactic: The `with` keyword must be followed by a tactic or by an alternative (e.g. `| zero =>`), but here it is followed by the identifier `n`.
```

<a id="error-example-next-next-next-next-next-panel-1"></a>

```proofscript
theorem zero_mul (m : Nat) : 0 * m = 0 := by
  induction m with
  | zero =>
    rw [Nat.mul_zero]
  | succ n n_ih =>
    rw [Nat.mul_succ]
    rw [Nat.add_zero]
    rw [n_ih]
```

The broken example has the structure of a correct proof in the Natural Numbers Game, and this proof will work if you `import Mathlib` and replace `induction` with `induction'`. Induction tactics in basic Lean expect the `with` keyword to be followed by a series of cases, and the names for the inductive case are provided in the `succ` case rather than being provided up-front.

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Invalid syntax for induction tactic: The `with` keyword must be followed by a tactic or by an alternative (e.g. `| zero =>`), but here it is followed by the identifier `n`.
```

