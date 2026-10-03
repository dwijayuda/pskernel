<a id="The-Lean-Language-Reference--Terms--Proofs"></a>

# ProofScript — 13.13. Proofs

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Terms keep native binding, precedence and type-directed elaboration. D-CALL is adjacency-sensitive: f(x,y) supplies two curried arguments; f((x,y)) and native f (x,y) supply one tuple. An empty call passes Unit. Lambdas use fun, records use :=, and match patterns remain native even when constructor terms use decorated calls. Braces delimit specific categories; they do not disable the native layout checks inside them.

**Compiler and coverage boundary.** Preserve grouping that influences elaboration. Do not flatten nested calls, split patterns on arbitrary bars, or rewrite punctuation inside strings and quotations.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Terms/Proofs/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Terms/Proofs/index.html). Source Git blob: `6cc8f7a9a8372d76750587689f3cd393e457dc3a`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 13.13. Proofs

The syntax for invoking tactics (`by`) is described in [the section on proofs](../../Tactic-Proofs/Running-Tactics/index.md#by).
