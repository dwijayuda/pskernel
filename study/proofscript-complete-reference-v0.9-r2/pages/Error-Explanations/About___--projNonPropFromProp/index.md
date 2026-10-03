<a id="lean___projNonPropFromProp"></a>

# ProofScript — About: projNonPropFromProp

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

The inherited error catalog explains invalid constructors, dependent eliminations, missing instances, unresolved names and other rejected programs. These are examples of failure, not snippets to copy into a successful program. Preserve native error IDs while mapping source positions back to .ps. A syntax overlay error should be distinguished from native elaboration, proof search, kernel rejection and unavailable target primitives.

**Compiler and coverage boundary.** Keep malformed, unsupported, cancelled, exhausted and internal-error outcomes distinct. Never turn an unsupported example into a permissive fallback or suppress a failed proof to make documentation appear runnable.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Error-Explanations/About___--projNonPropFromProp/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Error-Explanations/About___--projNonPropFromProp/index.html). Source Git blob: `6650be93aea159e201a4bb17e9a099f948b90a9a`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## About: projNonPropFromProp

Error code: `lean.projNonPropFromProp`

*Tried to project data from a proof.*

**Severity:**Error**Since:**4.23.0

This error occurs when attempting to project a piece of data from a proof of a proposition using an index projection. For example, if `h` is a proof of an existential proposition, attempting to extract the witness `h.1` is an example of this error. Such projections are disallowed because they may violate Lean's prohibition of large elimination from `Prop` (refer to the [Propositions](../../The-Type-System/Propositions/index.md#propositions) manual section for further details).

Instead of an index projection, consider using a pattern-matching `let`, [`match`](../../Terms/Pattern-Matching/index.md#Lean___Parser___Term___match) expression, or a destructuring tactic like `cases` to eliminate from one propositional type to another. Note that such elimination is only valid if the resulting value is also in `Prop`; if it is not, the error [`lean.propRecLargeElim`](../About___--propRecLargeElim/index.md#lean___propRecLargeElim) will be raised.

<a id="The-Lean-Language-Reference--Error-Explanations--About___--projNonPropFromProp--Examples"></a>
### Examples

<a id="Attempting-to-Use-Index-Projection-on-Existential-Proof"></a>
Attempting to Use Index Projection on Existential Proof   
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-0"></a>
Original
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-1"></a>
Fixed (let)
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-2"></a>
Fixed (cases)  
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-0"></a>

```proofscript
example (a : Nat) (h : ∃ x : Nat, x > a + 1) : ∃ x : Nat, x > 0 :=
  ⟨h.1, Nat.lt_of_succ_lt h.2⟩
```

```lean
Invalid projection: Cannot project a value of non-propositional type
  Nat
from the expression
  h
which has propositional type
  ∃ x, x > a + 1
```

<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-1"></a>

```proofscript
example (a : Nat) (h : ∃ x : Nat, x > a + 1) : ∃ x : Nat, x > a :=
  let ⟨w, hw⟩ := h
  ⟨w, Nat.lt_of_succ_lt hw⟩
```

<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-2"></a>

```proofscript
example (a : Nat) (h : ∃ x : Nat, x > a + 1) : ∃ x : Nat, x > a := by
  cases h with
  | intro w hw =>
    exists w
    omega
```

The witness associated with a proof of an existential proposition cannot be extracted using an index projection. Instead, it is necessary to use a pattern match: either a term like a `let` binding or a tactic like `cases`.

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Invalid projection: Cannot project a value of non-propositional type
  Nat
from the expression
  h
which has propositional type
  ∃ x, x > a + 1
```

