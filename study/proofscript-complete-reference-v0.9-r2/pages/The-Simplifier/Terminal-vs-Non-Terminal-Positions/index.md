<a id="terminal-simp"></a>

# ProofScript — 15.5. Terminal vs Non-Terminal Positions

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

simp uses selected rewrite theorems and congruence reasoning to construct checked evidence. simp only restricts the simplification set; simp at changes a hypothesis or location. The normal forms chosen by a library affect proof maintenance and automation. A simplifier is not a privileged evaluator permitted to replace an unproved goal with success.

**Compiler and coverage boundary.** Track the exact simp set, local hypotheses and configuration. A changed tactic script is not necessarily a changed theorem, but a cached proof must still match its dependency identity.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [The-Simplifier/Terminal-vs-Non-Terminal-Positions/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/The-Simplifier/Terminal-vs-Non-Terminal-Positions/index.html). Source Git blob: `ba6a85ff4e25d64706ad5c47be79c9b859600328`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 15.5. Terminal vs Non-Terminal Positions

To write maintainable proofs, avoid using `simp` without [`only`](../../Tactic-Proofs/Tactic-Reference/index.md#simp) unless it closes the goal. Such uses of `simp` that do not close a goal are referred to as 
<a id="--tech-term-non-terminal-simps"></a>
*non-terminal simps*. This is because additions to the default simp set may make `simp` more powerful or just cause it to select a different sequence of rewrites and arrive at a different simp normal form. When [`only`](../../Tactic-Proofs/Tactic-Reference/index.md#simp) is specified, additional lemmas will not affect that invocation of the tactic. In practice, terminal uses of `simp` are not nearly as likely to be broken by the addition of new simp lemmas, and when they are, it's easier to understand the issue and fix it.

When working in non-terminal positions, `simp?` (or one of the other simplification tactics with `?` in their names) can be used to generate an appropriate invocation with [`only`](../../Tactic-Proofs/Tactic-Reference/index.md#simp). Just as `apply?` or `rw?` suggest the use of relevant lemmas, `simp?` suggests an invocation of `simp` with a minimal simp set that was used to reach the normal form.

<a id="Using--simp___"></a>
Using `simp?` 

The non-terminal `simp?` in this proof suggests a smaller `simp` with [`only`](../../Tactic-Proofs/Tactic-Reference/index.md#simp):

```proofscript
example (xs : Array Unit) : xs.size = 2 → xs = #[(), ()] := by
  intros
  ext
  simp?
  assumption
```

The suggested rewrite is:

```lean
Try this:
  [apply] simp only [List.size_toArray, List.length_cons, List.length_nil, Nat.zero_add, Nat.reduceAdd]
```

which results in the more maintainable proof:

```proofscript
example (xs : Array Unit) : xs.size = 2 → xs = #[(), ()] := by
  intros
  ext
  simp only [
    List.size_toArray, List.length_cons, List.length_nil,
    Nat.zero_add, Nat.reduceAdd
  ]
  assumption
```

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Try this:
  [apply] simp only [List.size_toArray, List.length_cons, List.length_nil, Nat.zero_add, Nat.reduceAdd]
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
xs:Array Unit⊢ xs.size = 2 → xs = #[(), ()]
```


### Display 2


```text
xs:Array Unita✝:xs.size = 2⊢ xs = #[(), ()]
```


### Display 3


```text
h₁xs:Array Unita✝:xs.size = 2⊢ xs.size = #[(), ()].size
```


### Display 4


```text
h₁xs:Array Unita✝:xs.size = 2⊢ xs.size = 2
```


### Display 5


```text
All goals completed! 🐙
```

