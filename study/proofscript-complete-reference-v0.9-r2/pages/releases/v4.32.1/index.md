<a id="release-v4___32___1"></a>

# ProofScript — Lean 4.32.1 (2026-07-22)

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

These articles are the mirrored Lean release notes, not ProofScript releases. They document historical syntax, APIs, implementations and changes. The page named v4.34.0 in this mirror still identifies itself as rc2. Native source at the selected stable commit overrides stale details for a current ProofScript conformance claim. Historical examples remain native and are not silently modernized.

**Compiler and coverage boundary.** The stable delta note explicitly excludes the old native-reduction kernel hooks. Upgrading the pin requires a new reference/profile review and regenerated evidence.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [releases/v4.32.1/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/releases/v4.32.1/index.html). Source Git blob: `616946d180b9dc56cf0eb3b9f3a5d771bda40575`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## Lean 4.32.1 (2026-07-22)

This point release fixes a soundness bug in the kernel.

The issue was discovered by Patrick Hulin with the help of GPT-5.6 Sol.

This bug can be used by a malicious meta program to trick the kernel into accepting a proof of `False`, or any other theorem. It requires the malicious meta program to run in the same process as the kernel. In that situation, malicious meta programs already have other, blunter, ways to let the system accept bad proofs, so this bug does not create a new attack vector.

The [recommended way to check possibly dishonest proofs](../../ValidatingProofs/index.md#validating-comparator) using comparator is **not** affected by this bug.

See [issue #14484](https://github.com/leanprover/lean4/issues/14484) for more details on the bug and [PR #14498](https://github.com/leanprover/lean4/pull/14498) for the fix.
