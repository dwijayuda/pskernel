<a id="grind-propagation"></a>

# ProofScript — 16.5. Constraint Propagation

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

grind combines reasoning such as congruence closure, propagation, case analysis, E-matching and algebraic/arithmetic procedures. Its selected lemmas, annotations and solver parameters determine the search problem. Keep these as native proof-producing facilities, not as a replacement for the kernel. The mirrored subchapters and examples retain their individual scopes and failure cases.

**Compiler and coverage boundary.** Lean 4.34 stable parameter-list changes for lia/grobner are inherited only under the selected tactic capability. A timeout must remain an incomplete-search result.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [The--grind--tactic/Constraint-Propagation/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/The--grind--tactic/Constraint-Propagation/index.html). Source Git blob: `8b5b998cfcd0eb04ec1b725e770ff52601c8a680`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 16.5. Constraint Propagation

<a id="--tech-term-Constraint-propagation"></a>
Constraint propagation works on the `True` and `False` buckets of the whiteboard. Whenever a term is added to one of those buckets, `grind` fires dozens of small 
<a id="--tech-term-forward-rules"></a>
*forward rules* that derive further information from its logical consequences:

  Boolean connectives 

The truth tables of the Boolean connectives can be used to derive further true and false facts. For example:

- If `A` is `True`, then `A ∨ B` becomes `True`.
- If `A ∧ B` is `True`, then both `A` and `B` become `True`.
- If `A ∧ B` is `False`, at least one of `A`, `B` becomes `False`.

   Inductive Types

If terms formed by applications of two different constructors of the same [inductive type](../../The-Type-System/Inductive-Types/index.md#--tech-term-Inductive-types) (e.g. `none` and `some`) are placed in the same equivalence class, a contradiction is derived. If two terms formed by applications of the same constructor are placed in the same equivalence class, then their arguments are also made equal.

  Projections

From `h : (x, y) = (x', y')` we derive `x = x'` and `y = y'`.

  Casts

Any term `cast h a : β` is equated with `a : α` immediately (using [heterogeneous equality](../../Basic-Propositions/Propositional-Equality/index.md#--tech-term-Heterogeneous-equality)).

  Reduction

Definitional reduction is propagated, so `(a, b).1` is equated with `a`.

Below is a *representative slice* of the propagators that demonstrates their overall style. Each follows the same skeleton.

1. It inspect the truth value of sub‑expressions.
2. If further facts can be derived, it either equates terms (connecting them on the metaphorical whiteboard) using (`pushEq`), or it indicates truth values using (`pushEqTrue` / `pushEqFalse`). These steps produce proof terms using internal helper lemmas such as `Grind.and_eq_of_eq_true_left`.
3. If a contradiction arises, the goal is closed using (`closeGoal`).

<a id="--tech-term-Upward-propagation"></a>
*Upward propagation* derives facts about a term from facts about sub-terms, while 
<a id="--tech-term-downward-propagation"></a>
*downward propagation* derives facts about sub-terms from facts about a term.
<a id="ExamplePropagators___propagateAndUp"></a>
<a id="ExamplePropagators___propagateAndDown"></a>


```proofscript
/-- Propagate equalities *upwards* for conjunctions. -/
builtin_grind_propagator propagateAndUp ↑And := fun e => do
  let_expr And a b := e | return ()
  if (← isEqTrue a) then
    -- a = True  ⇒  (a ∧ b) = b
    pushEq e b <|
      mkApp3 (mkConst ``Grind.and_eq_of_eq_true_left)
        a b (← mkEqTrueProof a)
  else if (← isEqTrue b) then
    -- b = True  ⇒  (a ∧ b) = a
    pushEq e a <|
      mkApp3 (mkConst ``Grind.and_eq_of_eq_true_right)
        a b (← mkEqTrueProof b)
  else if (← isEqFalse a) then
    -- a = False  ⇒  (a ∧ b) = False
    pushEqFalse e <|
      mkApp3 (mkConst ``Grind.and_eq_of_eq_false_left)
        a b (← mkEqFalseProof a)
  else if (← isEqFalse b) then
    -- b = False  ⇒  (a ∧ b) = False
    pushEqFalse e <|
      mkApp3 (mkConst ``Grind.and_eq_of_eq_false_right)
        a b (← mkEqFalseProof b)

/--
Truth flows *down* when the whole `And` is proven `True`.
-/
builtin_grind_propagator propagateAndDown ↓And :=
  fun e => do
  if (← isEqTrue e) then
    let_expr And a b := e | return ()
    let h ← mkEqTrueProof e
    -- (a ∧ b) = True  ⇒  a = True
    pushEqTrue a <| mkApp3
      (mkConst ``Grind.eq_true_of_and_eq_true_left) a b h
    -- (a ∧ b) = True  ⇒  b = True
    pushEqTrue b <| mkApp3
      (mkConst ``Grind.eq_true_of_and_eq_true_right) a b h
```

Other frequently‑triggered propagators follow the same pattern:

| Propagator | Handles | Notes |
| --- | --- | --- |
| `propagateOrUp` / `propagateOrDown` | `A ∨ B` | Uses the truth table for disjunction to derive further truth values |
| `propagateNotUp` / `propagateNotDown` | `¬ A` | Ensures that `¬ A` and `A` have opposite truth values |
| `propagateEqUp` / `propagateEqDown` | `a = b` | Bridges Booleans, detects constructor clash |
| `propagateIte` / `propagateDIte` | `ite` / `dite` | Equates the term with the chosen branch once the condition's truth value is known |
| `propagateEtaStruct` | Values of structures tagged `[grind ext]` | Generates η‑expansion `a = ⟨a.1, …⟩` |

Many specialized variants for `Bool` mirror these rules exactly (e.g. `propagateBoolAndUp`).

<a id="The-Lean-Language-Reference--The--grind--tactic--Constraint-Propagation--Propagation___Only-Examples"></a>
### 16.5.1. Propagation‑Only Examples

These goals are closed **purely** by constraint propagation—no case splits, no theory solvers:

```proofscript
-- Boolean connective: a && !a is always false.
example (a : Bool) : (a && !a) = false := by
  grind

-- Conditional (ite):
-- once the condition is true, ite picks the 'then' branch.
example (c : Bool) (t e : Nat) (h : c = true) :
    (if c then t else e) = t := by
  grind

-- Negation propagates truth downwards.
example (a : Bool) (h : (!a) = true) : a = false := by
  grind
```

These snippets run instantly because the relevant propagators (`propagateBoolAndUp`, `propagateIte`, `propagateBoolNotDown`) fire as soon as the hypotheses are internalized. Setting the option `trace.grind.eqc` to `true` causes `grind` to print a line every time two equivalence classes merge, which is handy for seeing propagation in action.

The set of propagation rules is expanded and refined over time, so the InfoView will show increasingly rich `True` and `False` buckets. The full equivalence classes are displayed automatically *only when `grind` fails*, and only for the first subgoal that it could not close—use this output to inspect missing facts and understand why the subgoal remains open.

<a id="Identifying-Missing-Facts"></a>
Identifying Missing Facts 

In this example, `grind` fails:

```proofscript
example :
    x = y ∧ y = z →
    w = x ∨ w = v →
    w = z := by
  grind
```

The resulting error message includes the identified equivalence classes along with the true and false propositions:
<a id="--verso-unique-1300"></a>


```lean
`grind` failed
grindα:Sort u_1x y z w v:αleft:x = yright:y = zh_1:w = x ∨ w = vh_2:¬w = z⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] x = y[prop] y = z[prop] w = x ∨ w = v[prop] ¬w = z[eqc] True propositions[prop] w = x ∨ w = v[prop] w = v[eqc] False propositions[prop] w = x[prop] w = z[eqc] Equivalence classes[eqc] {x, y, z}[eqc] {w, v}
```

Both `x = y` and `y = z` were discovered by constraint propagation from the `x = y ∧ y = z` premise. In this proof, `grind` performed a case split on `w = x ∨ w = v`. In the second branch, it could not place `w` and `z` in the same equivalence class.

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
`grind` failed
grindα:Sort u_1x y z w v:αleft:x = yright:y = zh_1:w = x ∨ w = vh_2:¬w = z⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] x = y[prop] y = z[prop] w = x ∨ w = v[prop] ¬w = z[eqc] True propositions[prop] w = x ∨ w = v[prop] w = v[eqc] False propositions[prop] w = x[prop] w = z[eqc] Equivalence classes[eqc] {x, y, z}[eqc] {w, v}
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
a:Bool⊢ (a && !a) = false
```


### Display 2


```text
All goals completed! 🐙
```


### Display 3


```text
c:Boolt:Nate:Nath:c = true⊢ (if c = true then t else e) = t
```


### Display 4


```text
a:Boolh:(!a) = true⊢ a = false
```


### Display 5


```text
α✝:Sort u_1x:α✝y:α✝z:α✝w:α✝v:α✝⊢ x = y ∧ y = z → w = x ∨ w = v → w = z
```

