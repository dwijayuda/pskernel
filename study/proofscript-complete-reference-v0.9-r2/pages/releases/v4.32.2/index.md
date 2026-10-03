<a id="release-v4___32___2"></a>

# ProofScript — Lean 4.32.2 (2026-07-28)

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

These articles are the mirrored Lean release notes, not ProofScript releases. They document historical syntax, APIs, implementations and changes. The page named v4.34.0 in this mirror still identifies itself as rc2. Native source at the selected stable commit overrides stale details for a current ProofScript conformance claim. Historical examples remain native and are not silently modernized.

**Compiler and coverage boundary.** The stable delta note explicitly excludes the old native-reduction kernel hooks. Upgrading the pin requires a new reference/profile review and regenerated evidence.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [releases/v4.32.2/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/releases/v4.32.2/index.html). Source Git blob: `9c44fcfddb95ee1c700865bf8a9945f9f950df9b`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## Lean 4.32.2 (2026-07-28)

This point release fixes a soundness bug in the kernel.

The issue was discovered by Ramana Kumar and reported by Kiran Gopinathan.

A malicious meta program can trick the kernel into accepting a proof of `False`, or any other theorem. The kernel’s handling of nested inductive types with phantom type parameters was incomplete and bypassed the type checker.

The bug can be exploited even when using `comparator`.

The external checker `nanoda` does not suffer from the same bug. However, by the nature of this bug, it is possible to write proof terms that exploit it and at the same time exploit unrelated bugs in the external checker, as demonstrated by Kumar with a bug in `nanoda` that was (independently) [reported and fixed very recently](https://github.com/ammkrn/nanoda_lib/pull/22/changes). We highly recommend users who have to account for malicious proofs and follow the [recommended way to validate proofs](../../ValidatingProofs/index.md#validating-comparator) to upgrade to the latest `nanoda` version as well.

The FRO takes these issues seriously and will invest in the checker ecosystem, towards more hardening, more testing and more independent implementations of kernels and checkers.

See [issue #14576](https://github.com/leanprover/lean4/issues/14576) for more details on the bug and [PR #14577](https://github.com/leanprover/lean4/pull/14577) for the fix.
