<a id="tactic-language-options"></a>

# ProofScript — 14.4. Options

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Tactics construct proof terms, and the checker decides whether those terms prove the requested claim. Use the inherited tactic language, including goal management, rewriting, induction and conv. Semicolon sequencing and the apply-to-all-goals combinator are distinct. Native grammar displays and tactic signatures below describe the selected environment, not a second ProofScript tactic system.

**Compiler and coverage boundary.** Term decorations may appear only in explicitly lifted tactic term slots. Preserve goal names, hygiene and source maps. Search failure is not proof of falsity.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Tactic-Proofs/Options/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Tactic-Proofs/Options/index.html). Source Git blob: `ca2f32647ef286135a356122defbaec1f3c08d2b`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 14.4. Options

These options affect the meaning of tactics.

<a id="tactic___customEliminators"></a>

**option**

```text
tactic.customEliminators
```

Default value: `true`

enable using custom eliminators in the 'induction' and 'cases' tactics defined using the '@[induction_eliminator]' and '@[cases_eliminator]' attributes

<a id="tactic___skipAssignedInstances"></a>

**option**

```text
tactic.skipAssignedInstances
```

Default value: `true`

in the `rw` and `simp` tactics, if an instance implicit argument is assigned, do not try to synthesize instance.

<a id="tactic___simp___trace"></a>

**option**

```text
tactic.simp.trace
```

Default value: `false`

When tracing is enabled, calls to `simp` or `dsimp` will print an equivalent `simp only` call.
