<a id="release-v4___2___0"></a>

# ProofScript — Lean 4.2.0 (2023-10-31)

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

These articles are the mirrored Lean release notes, not ProofScript releases. They document historical syntax, APIs, implementations and changes. The page named v4.34.0 in this mirror still identifies itself as rc2. Native source at the selected stable commit overrides stale details for a current ProofScript conformance claim. Historical examples remain native and are not silently modernized.

**Compiler and coverage boundary.** The stable delta note explicitly excludes the old native-reduction kernel hooks. Upgrading the pin requires a new reference/profile review and regenerated evidence.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [releases/v4.2.0/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/releases/v4.2.0/index.html). Source Git blob: `362e38cddf23dee3295b4b33518e587a8b4ac821`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## Lean 4.2.0 (2023-10-31)

- [isDefEq cache for terms not containing metavariables.](https://github.com/leanprover/lean4/pull/2644).
- Make [`Environment.mk`](https://github.com/leanprover/lean4/pull/2604) and [`Environment.add`](https://github.com/leanprover/lean4/pull/2642) private, and add [`replay`](https://github.com/leanprover/lean4/pull/2617) as a safer alternative.
- `IO.Process.output` no longer inherits the standard input of the caller.
- [Do not inhibit caching](https://github.com/leanprover/lean4/pull/2612) of default-level `match` reduction.
- [List the valid case tags](https://github.com/leanprover/lean4/pull/2629) when the user writes an invalid one.
- The derive handler for `DecidableEq` [now handles](https://github.com/leanprover/lean4/pull/2591) mutual inductive types.
- [Show path of failed import in Lake](https://github.com/leanprover/lean4/pull/2616).
- [Fix linker warnings on macOS](https://github.com/leanprover/lean4/pull/2598).
- **Lake:** Add `postUpdate?` package configuration option. Used by a package to specify some code which should be run after a successful `lake update` of the package or one of its downstream dependencies. ([lake#185](https://github.com/leanprover/lake/issues/185))
- Improvements to Lake startup time ([#2572](https://github.com/leanprover/lean4/pull/2572), [#2573](https://github.com/leanprover/lean4/pull/2573))
- `refine e` now replaces the main goal with metavariables which were created during elaboration of `e` and no longer captures pre-existing metavariables that occur in `e` ([#2502](https://github.com/leanprover/lean4/pull/2502)).

   

  - This is accomplished via changes to `withCollectingNewGoalsFrom`, which also affects `elabTermWithHoles`, `refine'`, `calc` (tactic), and `specialize`. Likewise, all of these now only include newly-created metavariables in their output.
  - Previously, both newly-created and pre-existing metavariables occurring in `e` were returned inconsistently in different edge cases, causing duplicated goals in the infoview (issue [#2495](https://github.com/leanprover/lean4/issues/2495)), erroneously closed goals (issue [#2434](https://github.com/leanprover/lean4/issues/2434)), and unintuitive behavior due to `refine e` capturing previously-created goals appearing unexpectedly in `e` (no issue; see PR).
