<a id="release-v4___29___1"></a>

# ProofScript — Lean 4.29.1 (2026-04-14)

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

These articles are the mirrored Lean release notes, not ProofScript releases. They document historical syntax, APIs, implementations and changes. The page named v4.34.0 in this mirror still identifies itself as rc2. Native source at the selected stable commit overrides stale details for a current ProofScript conformance claim. Historical examples remain native and are not silently modernized.

**Compiler and coverage boundary.** The stable delta note explicitly excludes the old native-reduction kernel hooks. Upgrading the pin requires a new reference/profile review and regenerated evidence.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [releases/v4.29.1/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/releases/v4.29.1/index.html). Source Git blob: `83c258b7b872b1cbf2607dfaeb55fb0ae855665c`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## Lean 4.29.1 (2026-04-14)

For this release, 1 change landed. In addition to the 0 feature additions, and 1 fix listed below, there were 0 refactoring changes, 0 documentation improvements, 0 performance improvements, 0 improvements to the test suite, and 0 other changes.

<a id="The-Lean-Language-Reference--Release-Notes--Lean-4___29___1-_LPAR_2026-04-14_RPAR_--Compiler"></a>
### Compiler

- [#13392](https://github.com/leanprover/lean4/pull/13392) fixes a heap buffer overflow in `lean_io_prim_handle_read` that was triggered through an integer overflow in the size computation of an allocation. In addition it places several checked arithmetic operations on all relevant allocation paths to have potential future overflows be turned into crashes instead. The offending code now throws an out of memory error instead.
