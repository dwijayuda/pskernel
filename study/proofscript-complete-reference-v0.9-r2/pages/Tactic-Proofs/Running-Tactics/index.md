<a id="by"></a>

# ProofScript — 14.1. Running Tactics

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Tactics construct proof terms, and the checker decides whether those terms prove the requested claim. Use the inherited tactic language, including goal management, rewriting, induction and conv. Semicolon sequencing and the apply-to-all-goals combinator are distinct. Native grammar displays and tactic signatures below describe the selected environment, not a second ProofScript tactic system.

**Compiler and coverage boundary.** Term decorations may appear only in explicitly lifted tactic term slots. Preserve goal names, hygiene and source maps. Search failure is not proof of falsity.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Tactic-Proofs/Running-Tactics/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Tactic-Proofs/Running-Tactics/index.html). Source Git blob: `419cd6c5b571e6ad423bc4959d2deccb53f7d5f3`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 14.1. Running Tactics

<a id="Lean___Parser___Term___byTactic"></a>

**syntax**

**Tactic Proofs with by**

Tactics are included in terms using `by`, which is followed by a sequence of tactics in which each has the same indentation:

<a id="Lean___Parser___Term___byTactic-next"></a>

```ebnf
term ::= ...
    | by
      tacticSeq
```

Alternatively, explicit braces and semicolons may be used:

<a id="Lean___Parser___Term___byTactic-next-next"></a>

```ebnf
term ::= ...
    | by { tactic* }
```

Tactics are invoked using the `by` term. When the elaborator encounters `by`, it invokes the tactic interpreter to construct the resulting term. Tactic proofs may be embedded via `by` in any context in which a term can occur.

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
`by tac` constructs a term of the expected type by running the tactic(s) `tac`.
```


### Display 2


```text
A sequence of tactics in brackets, or a delimiter-free indented sequence of tactics.
Delimiter-free indentation is determined by the *first* tactic of the sequence.
```


### Display 3


```text
The syntax `{ tacs }` is an alternative syntax for `· tacs`.
It runs the tactics in sequence, and fails if the goal is not solved.
```

