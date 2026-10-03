<a id="The-Lean-Language-Reference--The--grind--tactic--Minimizing--grind--calls"></a>

# ProofScript — 16.2. Minimizing grind calls

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

grind combines reasoning such as congruence closure, propagation, case analysis, E-matching and algebraic/arithmetic procedures. Its selected lemmas, annotations and solver parameters determine the search problem. Keep these as native proof-producing facilities, not as a replacement for the kernel. The mirrored subchapters and examples retain their individual scopes and failure cases.

**Compiler and coverage boundary.** Lean 4.34 stable parameter-list changes for lia/grobner are inherited only under the selected tactic capability. A timeout must remain an incomplete-search result.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [The--grind--tactic/Minimizing--grind--calls/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/The--grind--tactic/Minimizing--grind--calls/index.html). Source Git blob: `2d61d77a0e9e83a831fa2b6c7f17a545dfdeb80b`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 16.2. Minimizing grind calls

The `grind only [...]` tactic invokes `grind` with a limited set of theorems, which can improve performance. Calls to `grind only` can be conveniently constructed using `grind?`, which automatically records the theorems used by `grind` and suggests a suitable `grind only`.

These theorems will typically include a symbol prefix such as `=`, `←`, or `→`, indicating the pattern that triggered the instantiation. See the [section on E-matching](../E___matching/index.md#e-matching) for details. Some theorems may be labelled with a `usr` prefix, which indicates that a custom pattern was used.
