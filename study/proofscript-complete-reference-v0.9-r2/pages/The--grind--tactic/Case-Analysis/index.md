<a id="grind-split"></a>

# ProofScript — 16.6. Case Analysis

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

grind combines reasoning such as congruence closure, propagation, case analysis, E-matching and algebraic/arithmetic procedures. Its selected lemmas, annotations and solver parameters determine the search problem. Keep these as native proof-producing facilities, not as a replacement for the kernel. The mirrored subchapters and examples retain their individual scopes and failure cases.

**Compiler and coverage boundary.** Lean 4.34 stable parameter-list changes for lia/grobner are inherited only under the selected tactic capability. A timeout must remain an incomplete-search result.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [The--grind--tactic/Case-Analysis/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/The--grind--tactic/Case-Analysis/index.html). Source Git blob: `1d0ea1eba3d5da3fc12b7746cb38e4f336eb6772`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 16.6. Case Analysis

In addition to congruence closure and constraint propagation, `grind` performs case analysis. During case analysis, `grind` considers each possible way that a term could have been built, or each possible value of a particular term, in a manner similar to the `cases` and `split` tactics. This case analysis is not exhaustive: `grind` only recursively splits cases up to a configured depth limit, and configuration options and annotations control which terms are candidates for splitting.

<a id="The-Lean-Language-Reference--The--grind--tactic--Case-Analysis--Selection-Heuristics"></a>
### 16.6.1. Selection Heuristics

`grind` decides which sub‑term to split on by combining three sources of signal:

  Structural flags

These configuration flags determine whether `grind` performs certain case splits:

  `splitIte` (default `true`)

Every `if`-term should be split, as if by the `split` tactic.

  `splitMatch` (default `true`)

Every [`match`](../../Terms/Pattern-Matching/index.md#Lean___Parser___Term___match)-term should be split, as if by the `split` tactic.

  `splitImp` (default `false`)

Hypotheses of the form `A → B` whose antecedent `A` is **propositional** are split by considering all possibilities for `A`. Arithmetic antecedents are special‑cased: if `A` is an arithmetic literal (that is, a proposition formed by operators such as `≤`, `=`, `¬`, `Dvd`, …) then `grind` will split *even when `splitImp := false`* so the integer solver can propagate facts.

  Global limits

The `grind` option `splits := n` caps the depth of the search tree. Once a branch performs `n` splits `grind` stops splitting further in that branch; if the branch cannot be closed it reports that the split threshold has been reached.

  Manual annotations

Inductive predicates or structures may be tagged with the `grind cases` attribute. `grind` treats every instance of that predicate as a candidate for splitting.

<a id="attr-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**attribute**

**Case Analysis**

<a id="Lean___Parser___Attr___grind"></a>

```ebnf
attr ::= ...
    | grind cases
```

The `cases` modifier marks inductively-defined predicates as suitable for case splitting.

<a id="attr-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**attribute**

**Eager Case Analysis**

<a id="Lean___Parser___Attr___grind-next"></a>

```ebnf
attr ::= ...
    | grind cases eager
```

The `cases eager` modifier marks inductively-defined predicates as suitable for case splitting, and instructs `grind` to perform it eagerly while preprocessing hypotheses.

<a id="Splitting-Conditional-Expressions"></a>
Splitting Conditional Expressions 

In this example, `grind` proves the theorem by considering both cases for the conditional:

```proofscript
example (c : Bool) (x y : Nat)
    (h : (if c then x else y) = 0) :
    x = 0 ∨ y = 0 := by
  grind
```

Disabling `splitIte` causes the proof to fail:

```proofscript
example (c : Bool) (x y : Nat)
    (h : (if c then x else y) = 0) :
    x = 0 ∨ y = 0 := by
  grind -splitIte
```

In particular, it cannot make progress after discovering that the conditional expression is equal to `0`:
<a id="--verso-unique-1308"></a>


```lean
`grind` failed
grindc:Boolx y:Nath:(if c = true then x else y) = 0left:¬x = 0right:¬y = 0⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] (if c = true then x else y) = 0[prop] ¬x = 0[prop] ¬y = 0[eqc] False propositions[prop] x = 0[prop] y = 0[eqc] Equivalence classes[eqc] others[eqc] {0, if c = true then x else y}[cutsat] Assignment satisfying linear constraints[assign] x := 1[assign] y := 2
```

Forbidding all case splitting causes the proof to fail for the same reason:

```proofscript
example (c : Bool) (x y : Nat)
    (h : (if c then x else y) = 0) :
    x = 0 ∨ y = 0 := by
  grind (splits := 0)
```
<a id="--verso-unique-1313"></a>


```lean
`grind` failed
grindc:Boolx y:Nath:(if c = true then x else y) = 0left:¬x = 0right:¬y = 0⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] (if c = true then x else y) = 0[prop] ¬x = 0[prop] ¬y = 0[eqc] False propositions[prop] x = 0[prop] y = 0[eqc] Equivalence classes[eqc] others[eqc] {0, if c = true then x else y}[cutsat] Assignment satisfying linear constraints[assign] x := 1[assign] y := 2[limits] Thresholds reached[limit] maximum number of case-splits has been reached, threshold: `(splits := 0)`
```

Allowing just one split is sufficient:

```proofscript
example (c : Bool) (x y : Nat)
    (h : (if c then x else y) = 0) :
    x = 0 ∨ y = 0 := by
  grind (splits := 1)
```

<a id="Splitting-Pattern-Matching"></a>
Splitting Pattern Matching 

Disabling case splitting on pattern matches causes `grind` to fail in this example:

```proofscript
example (h : y = match x with | 0 => 1 | _ => 2) :
    y > 0 := by
  grind -splitMatch
```
<a id="--verso-unique-1321"></a>


```lean
`grind` failed
grindy x:Nath:y =
  match x with
  | 0 => 1
  | x => 2h_1:y = 0⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] y =
      match x with
      | 0 => 1
      | x => 2[prop] y = 0[prop] (x = 0 → False) →
      (match x with
        | 0 => 1
        | x => 2) =
        2[eqc] True propositions[prop] (x = 0 → False) →
      (match x with
        | 0 => 1
        | x => 2) =
        2[eqc] Equivalence classes[eqc] {y, 0}[eqc] {match x with
    | 0 => 1
    | x => 2}[eqc] {x = 0 → False, (fun x_0 => x_0 = 0 → False) x, x = 0 → False}[ematch] E-matching patterns[thm] _example.match_1.congr_eq_1: [_example.match_1 #4 (@Lean.Grind.genPattern `[Nat] #0 #3 `[0]) #2 #1][thm] _example.match_1.congr_eq_2: [_example.match_1 #6 (@Lean.Grind.genPattern `[Nat] #1 #5 #2) #4 #3][cutsat] Assignment satisfying linear constraints[assign] y := 0[assign] x := 1[assign] match x with
    | 0 => 1
    | x => 2 := 0
[grind] Diagnostics[thm] E-Matching instances[thm] _example.match_1.congr_eq_2 ↦ 1
```

Enabling the option causes the proof to succeed:

```proofscript
example (h : y = match x with | 0 => 1 | _ => 2) :
    y > 0 := by
  grind
```

<a id="Splitting-Predicates"></a>
Splitting Predicates 

`Not30` is a somewhat verbose way to state that a number is not `30`:
<a id="Not30-_LPAR_in-Splitting-Predicates_RPAR_"></a>
<a id="Not30___gt-_LPAR_in-Splitting-Predicates_RPAR_"></a>
<a id="Not30___lt-_LPAR_in-Splitting-Predicates_RPAR_"></a>


```proofscript
inductive Not30 : Nat → Prop where
  | gt : x > 30 → Not30 x
  | lt : x < 30 → Not30 x
```

By default, `grind` cannot show that `Not30` implies that a number is, in fact, not `30`:

```proofscript
example : Not30 n → n ≠ 30 := by grind
```

This is because `grind` does not consider both cases for `Not30`
<a id="--verso-unique-1329"></a>


```lean
`grind` failed
grindn:Nath:Not30 nh_1:n = 30⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] Not30 n[prop] n = 30[eqc] True propositions[prop] Not30 n[eqc] Equivalence classes[eqc] {n, 30}[cutsat] Assignment satisfying linear constraints[assign] n := 30
```

Adding the `grind cases` attribute to `Not30` allows the proof to succeed:

```proofscript
attribute [grind cases] Not30

example : Not30 n → n ≠ 30 := by grind
```

Similarly, the `grind cases` attribute on `Even` allows `grind` to perform case splits:
<a id="Even-_LPAR_in-Splitting-Predicates_RPAR_"></a>
<a id="Even___zero-_LPAR_in-Splitting-Predicates_RPAR_"></a>
<a id="Even___step-_LPAR_in-Splitting-Predicates_RPAR_"></a>


```proofscript
@[grind cases]
inductive Even : Nat → Prop
  | zero : Even 0
  | step : Even n → Even (n + 2)

attribute [grind cases] Even

example (h : Even 5) : False := by
  grind

set_option trace.grind.split true in
example (h : Even (n + 2)) : Even n := by
  grind
```

<a id="The-Lean-Language-Reference--The--grind--tactic--Case-Analysis--Performance"></a>
### 16.6.2. Performance

Case analysis is powerful, but computationally expensive: each level of case splitting multiplies the search space. It's important to be judicious and not perform unnecessary splits. In particular:

- Increase `splits` **only** when the goal genuinely needs deeper branching; each extra level multiplies the search space.
- Disable `splitMatch` when large pattern‑matching definitions explode the tree; this can be observed by setting the `trace.grind.split`.
- Flags can be combined, e.g. `by grind -splitMatch (splits := 10) +splitImp`.
- The `grind cases` attribute is [*scoped*](../../Attributes/index.md#scoped-attributes). The modifiers `local` and `scoped` restrict extra splitting to a section or namespace.

<a id="trace___grind___split"></a>

**option**

```text
trace.grind.split
```

Default value: `false`

enable/disable tracing for the given module and submodules

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Marks a theorem or definition for use by the `grind` tactic.

An optional modifier (e.g. `=`, `→`, `←`, `cases`, `intro`, `ext`, `inj`, etc.)
controls how `grind` uses the declaration:
* whether it is applied forwards, backwards, or both,
* whether equalities are used on the left, right, or both sides,
* whether case-splits, constructors, extensionality, or injectivity are applied,
* or whether custom instantiation patterns are used.

See the individual modifier docstrings for details.
```


### Display 2


```text
The `cases` modifier marks inductively-defined predicates as suitable for case splitting.
```


### Display 3


```text
The `cases eager` modifier marks inductively-defined predicates as suitable for case splitting,
and instructs `grind` to perform it eagerly while preprocessing hypotheses.
```


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
`grind` failed
grindc:Boolx y:Nath:(if c = true then x else y) = 0left:¬x = 0right:¬y = 0⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] (if c = true then x else y) = 0[prop] ¬x = 0[prop] ¬y = 0[eqc] False propositions[prop] x = 0[prop] y = 0[eqc] Equivalence classes[eqc] others[eqc] {0, if c = true then x else y}[cutsat] Assignment satisfying linear constraints[assign] x := 1[assign] y := 2
```


### Display 2


```text
`grind` failed
grindc:Boolx y:Nath:(if c = true then x else y) = 0left:¬x = 0right:¬y = 0⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] (if c = true then x else y) = 0[prop] ¬x = 0[prop] ¬y = 0[eqc] False propositions[prop] x = 0[prop] y = 0[eqc] Equivalence classes[eqc] others[eqc] {0, if c = true then x else y}[cutsat] Assignment satisfying linear constraints[assign] x := 1[assign] y := 2[limits] Thresholds reached[limit] maximum number of case-splits has been reached, threshold: `(splits := 0)`
```


### Display 3


```text
`grind` failed
grindy x:Nath:y =
  match x with
  | 0 => 1
  | x => 2h_1:y = 0⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] y =
      match x with
      | 0 => 1
      | x => 2[prop] y = 0[prop] (x = 0 → False) →
      (match x with
        | 0 => 1
        | x => 2) =
        2[eqc] True propositions[prop] (x = 0 → False) →
      (match x with
        | 0 => 1
        | x => 2) =
        2[eqc] Equivalence classes[eqc] {y, 0}[eqc] {match x with
    | 0 => 1
    | x => 2}[eqc] {x = 0 → False, (fun x_0 => x_0 = 0 → False) x, x = 0 → False}[ematch] E-matching patterns[thm] _example.match_1.congr_eq_1: [_example.match_1 #4 (@Lean.Grind.genPattern `[Nat] #0 #3 `[0]) #2 #1][thm] _example.match_1.congr_eq_2: [_example.match_1 #6 (@Lean.Grind.genPattern `[Nat] #1 #5 #2) #4 #3][cutsat] Assignment satisfying linear constraints[assign] y := 0[assign] x := 1[assign] match x with
    | 0 => 1
    | x => 2 := 0
[grind] Diagnostics[thm] E-Matching instances[thm] _example.match_1.congr_eq_2 ↦ 1
```


### Display 4


```text
`grind` failed
grindn:Nath:Not30 nh_1:n = 30⊢ False
[grind] Goal diagnostics[facts] Asserted facts[prop] Not30 n[prop] n = 30[eqc] True propositions[prop] Not30 n[eqc] Equivalence classes[eqc] {n, 30}[cutsat] Assignment satisfying linear constraints[assign] n := 30
```


### Display 5


```text
[grind.split] Even (n + 2), generation: 0
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
c:Boolx:Naty:Nath:(if c = true then x else y) = 0⊢ x = 0 ∨ y = 0
```


### Display 2


```text
All goals completed! 🐙
```


### Display 3


```text
y:Natx:Nath:y =
  match x with
  | 0 => 1
  | x => 2⊢ y > 0
```


### Display 4


```text
n:Nat⊢ Not30 n → n ≠ 30
```


### Display 5


```text
h:Even 5⊢ False
```


### Display 6


```text
n:Nath:Even (n + 2)⊢ Even n
```

