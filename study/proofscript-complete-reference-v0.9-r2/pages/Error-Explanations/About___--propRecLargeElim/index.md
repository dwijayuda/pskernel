<a id="lean___propRecLargeElim"></a>

# ProofScript — About: propRecLargeElim

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

The inherited error catalog explains invalid constructors, dependent eliminations, missing instances, unresolved names and other rejected programs. These are examples of failure, not snippets to copy into a successful program. Preserve native error IDs while mapping source positions back to .ps. A syntax overlay error should be distinguished from native elaboration, proof search, kernel rejection and unavailable target primitives.

**Compiler and coverage boundary.** Keep malformed, unsupported, cancelled, exhausted and internal-error outcomes distinct. Never turn an unsupported example into a permissive fallback or suppress a failed proof to make documentation appear runnable.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Error-Explanations/About___--propRecLargeElim/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Error-Explanations/About___--propRecLargeElim/index.html). Source Git blob: `3303b5ef0fcc584876a6f3822d3effb2ae7524da`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## About: propRecLargeElim

Error code: `lean.propRecLargeElim`

*Attempted to eliminate a proof into a higher type universe.*

**Severity:**Error**Since:**4.23.0

This error occurs when attempting to eliminate a proof of a proposition into a higher type universe. Because Lean's type theory does not allow large elimination from `Prop`, it is invalid to pattern-match on such values—e.g., by using `let` or [`match`](../../Terms/Pattern-Matching/index.md#Lean___Parser___Term___match)—to produce a piece of data in a non-propositional universe (i.e., `Type u`). More precisely, the motive of a propositional recursor must be a proposition. (See the manual section on [Subsingleton Elimination](../../The-Type-System/Inductive-Types/index.md#subsingleton-elimination) for exceptions to this rule.)

Note that this error will arise in any expression that eliminates from a proof into a non-propositional universe, even if that expression occurs within another expression of propositional type (e.g., in a `let` binding in a proof). The “Defining an intermediate data value within a proof” example below demonstrates such an occurrence. Errors of this kind can usually be resolved by moving the recursor application “outward,” so that its motive is the proposition being proved rather than the type of data-valued term.

<a id="The-Lean-Language-Reference--Error-Explanations--About___--propRecLargeElim--Examples"></a>
### Examples

<a id="Defining-an-Intermediate-Data-Value-Within-a-Proof"></a>
Defining an Intermediate Data Value Within a Proof   
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-0"></a>
Original
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-1"></a>
Fixed  
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-0"></a>

```proofscript
example {α : Type} [inst : Nonempty α] (p : α → Prop) :
    ∃ x, p x ∨ ¬ p x :=
  let val :=
    match inst with
    | .intro x => x
  ⟨val, Classical.em (p val)⟩
```

```lean
Tactic `cases` failed with a nested error:
Tactic `induction` failed: recursor `Nonempty.casesOn` can only eliminate into `Prop`

α:Typemotive:Nonempty α → Sort ?u.14h_1:(x : α) → motive ⋯inst✝:Nonempty α⊢ motive inst✝ after processing
  _
the dependent pattern matcher can solve the following kinds of equations
- <var> = <term> and <term> = <var>
- <term> = <term> where the terms are definitionally equal
- <constructor> = <constructor>, examples: List.cons x xs = List.cons y ys, and List.cons x xs = List.nil
```

<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-1"></a>

```proofscript
example {α : Type} [inst : Nonempty α] (p : α → Prop) :
    ∃ x, p x ∨ ¬ p x :=
  match inst with
  | .intro x => ⟨x, Classical.em (p x)⟩
```

Even though the `example` being defined has a propositional type, the body of `val` does not; it has type `α : Type`. Thus, pattern-matching on the proof of `Nonempty α` (a proposition) to produce `val` requires eliminating that proof into a non-propositional type and is disallowed. Instead, the [`match`](../../Terms/Pattern-Matching/index.md#Lean___Parser___Term___match) expression must be moved to the top level of the `example`, where the result is a `Prop`-valued proof of the existential claim stated in the example's header. This restructuring could also be done using a pattern-matching `let` binding.

<a id="Extracting-the-Witness-from-an-Existential-Proof"></a>
Extracting the Witness from an Existential Proof   
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-0"></a>
Original
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-1"></a>
Fixed (in Prop)
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-2"></a>
Fixed (in Type)  
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-0"></a>

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
function getWitness {α : Type u} {p : α → Prop} (h : ∃ x, p x) : α :=
  match h with
  | .intro x _ => x
```

```lean
Tactic `cases` failed with a nested error:
Tactic `induction` failed: recursor `Exists.casesOn` can only eliminate into `Prop`

α:Type up:α → Propmotive:(∃ x, p x) → Sort ?u.11h_1:(x : α) → (h : p x) → motive ⋯h✝:∃ x, p x⊢ motive h✝ after processing
  _
the dependent pattern matcher can solve the following kinds of equations
- <var> = <term> and <term> = <var>
- <term> = <term> where the terms are definitionally equal
- <constructor> = <constructor>, examples: List.cons x xs = List.cons y ys, and List.cons x xs = List.nil
```

<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-1"></a>
<a id="useWitness-_LPAR_in-Extracting-the-Witness-from-an-Existential-Proof_RPAR_"></a>


```proofscript
-- This is `Exists.elim`
theorem useWitness {α : Type u} {p : α → Prop} {q : Prop}
    (h : ∃ x, p x) (hq : (x : α) → p x → q) : q :=
  match h with
  | .intro x hx => hq x hx
```

<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-2"></a>

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
function getWitness {α : Type u} {p : α → Prop}
    (h : (x : α) ×' p x) : α :=
  match h with
  | .mk x _ => x
```

In this example, simply relocating the pattern-match is insufficient; the attempted definition `getWitness` is fundamentally unsound. (Consider the case where `p` is `fun (n : Nat) => n > 0`: if `h` and `h'` are proofs of `∃ x, x > 0`, with `h` using witness `1` and `h'` witness `2`, then since `h = h'` by proof irrelevance, it follows that `getWitness h = getWitness h'`—i.e., `1 = 2`.)

Instead, `getWitness` must be rewritten: either the resulting type of the function must be a proposition (the first fixed example above), or `h` must not be a proposition (the second).

In the first corrected example, the resulting type of `useWitness` is now a proposition `q`. This allows us to pattern-match on `h`—since we are eliminating into a propositional type—and pass the unpacked values to `hq`. From a programmatic perspective, one can view `useWitness` as rewriting `getWitness` in continuation-passing style, restricting subsequent computations to use its result only to construct values in `Prop`, as required by the prohibition on propositional large elimination. Note that `useWitness` is the existential elimination principle `Exists.elim`.

The second corrected example changes the type of `h` from an existential proposition to a `Type`-valued dependent pair (corresponding to the `PSigma` type constructor). Since this type is not propositional, eliminating into `α : Type u` is no longer invalid, and the previously attempted pattern match now type-checks.

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Tactic `cases` failed with a nested error:
Tactic `induction` failed: recursor `Nonempty.casesOn` can only eliminate into `Prop`

α:Typemotive:Nonempty α → Sort ?u.14h_1:(x : α) → motive ⋯inst✝:Nonempty α⊢ motive inst✝ after processing
  _
the dependent pattern matcher can solve the following kinds of equations
- <var> = <term> and <term> = <var>
- <term> = <term> where the terms are definitionally equal
- <constructor> = <constructor>, examples: List.cons x xs = List.cons y ys, and List.cons x xs = List.nil
```


### Display 2


```text
Tactic `cases` failed with a nested error:
Tactic `induction` failed: recursor `Exists.casesOn` can only eliminate into `Prop`

α:Type up:α → Propmotive:(∃ x, p x) → Sort ?u.11h_1:(x : α) → (h : p x) → motive ⋯h✝:∃ x, p x⊢ motive h✝ after processing
  _
the dependent pattern matcher can solve the following kinds of equations
- <var> = <term> and <term> = <var>
- <term> = <term> where the terms are definitionally equal
- <constructor> = <constructor>, examples: List.cons x xs = List.cons y ys, and List.cons x xs = List.nil
```

