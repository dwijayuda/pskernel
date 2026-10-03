<a id="tactics"></a>

# ProofScript — 14. Tactic Proofs

[Reference home](../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Tactics construct proof terms, and the checker decides whether those terms prove the requested claim. Use the inherited tactic language, including goal management, rewriting, induction and conv. Semicolon sequencing and the apply-to-all-goals combinator are distinct. Native grammar displays and tactic signatures below describe the selected environment, not a second ProofScript tactic system.

## ProofScript way of writing it


```proofscript
theorem twoTruths: True ∧ True := by {
  constructor; trivial; trivial
}

theorem twoTruthsAll: True ∧ True := by {
  constructor <;> trivial
}
```

**Compiler and coverage boundary.** Term decorations may appear only in explicitly lifted tactic term slots. Preserve goal names, hygiene and source maps. Search failure is not proof of falsity.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Tactic-Proofs/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Tactic-Proofs/index.html). Source Git blob: `a0ff5e4e2e5d4030ff69efef0727e721d00f7319`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 14. Tactic Proofs

The tactic language is a special-purpose programming language for constructing proofs. In Lean, [propositions](../The-Type-System/Propositions/index.md#--tech-term-Propositions) are represented by types, and proofs are terms that inhabit these types. The [section on propositions](../The-Type-System/Propositions/index.md#propositions) describes propositions in more detail. While terms are designed to make it convenient to indicate a specific inhabitant of a type, tactics are designed to make it convenient to demonstrate that a type is inhabited. This distinction exists because it's important that definitions pick out the precise objects of interest and that programs return the intended results, but proof irrelevance means that there's no *technical* reason to prefer one proof term over another. For example, given two assumptions of a given type, a program must be carefully written to use the correct one, while a proof may use either without consequence.

Tactics are imperative programs that modify a 
<a id="--tech-term-proof-state"></a>
*proof state*.
<a id="--index--next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
 A proof state consists of an ordered sequence of 
<a id="--tech-term-goals"></a>
*goals*, which are contexts of local assumptions together with types to be inhabited; a tactic may either *succeed* with a possibly-empty sequence of further goals (called 
<a id="--tech-term-subgoals"></a>
*subgoals*) or *fail* if it cannot make progress. If a tactic succeeds with no subgoals, then the proof is complete. If it succeeds with one or more subgoals, then its goal or goals will be proved when those subgoals have been proved. The first goal in the proof state is called the 
<a id="--tech-term-main-goal"></a>
*main goal*.
<a id="--index--next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

<a id="--index--next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
 While most tactics affect only the main goal, operators such as `<;>` and `all_goals` can be used to apply a tactic to many goals, and operators such as bullets, `next` or `case` can narrow the focus of subsequent tactics to only a single goal in the proof state.

Behind the scenes, tactics construct 
<a id="--tech-term-proof-terms"></a>
proof terms. Proof terms are independently checkable evidence of a theorem's truth, written in Lean's type theory. Each proof is checked in the [kernel](../Elaboration-and-Compilation/index.md#--tech-term-kernel), and can be verified with independently-implemented external checkers, so the worst outcome from a bug in a tactic is a confusing error message, rather than an incorrect proof. Each goal in a tactic proof corresponds to an incomplete portion of a proof term.

1. [14.1. Running Tactics](Running-Tactics/index.md#by)
2. [14.2. Reading Proof States](Reading-Proof-States/index.md#proof-states)
3. [14.3. The Tactic Language](The-Tactic-Language/index.md#tactic-language)
4. [14.4. Options](Options/index.md#tactic-language-options)
5. [14.5. Tactic Reference](Tactic-Reference/index.md#tactic-ref)
6. [14.6. Targeted Rewriting with `conv`](Targeted-Rewriting-with--conv/index.md#conv)
7. [14.7. Naming Bound Variables](Naming-Bound-Variables/index.md#bound-variable-name-hints)
8. [14.8. Custom Tactics](Custom-Tactics/index.md#custom-tactics)
