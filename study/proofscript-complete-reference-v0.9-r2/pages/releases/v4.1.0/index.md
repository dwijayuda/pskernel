<a id="release-v4___1___0"></a>

# ProofScript — Lean 4.1.0 (2023-09-26)

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

These articles are the mirrored Lean release notes, not ProofScript releases. They document historical syntax, APIs, implementations and changes. The page named v4.34.0 in this mirror still identifies itself as rc2. Native source at the selected stable commit overrides stale details for a current ProofScript conformance claim. Historical examples remain native and are not silently modernized.

**Compiler and coverage boundary.** The stable delta note explicitly excludes the old native-reduction kernel hooks. Upgrading the pin requires a new reference/profile review and regenerated evidence.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [releases/v4.1.0/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/releases/v4.1.0/index.html). Source Git blob: `60c86fa568ad3df93fc236147332a333fc105397`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## Lean 4.1.0 (2023-09-26)

- The error positioning on missing tokens has been [improved](https://github.com/leanprover/lean4/pull/2393). In particular, this should make it easier to spot errors in incomplete tactic proofs.
- After elaborating a configuration file, Lake will now cache the configuration to a `lakefile.olean`. Subsequent runs of Lake will import this OLean instead of elaborating the configuration file. This provides a significant performance improvement (benchmarks indicate that using the OLean cuts Lake's startup time in half), but there are some important details to keep in mind:

   

  - Lake will regenerate this OLean after each modification to the `lakefile.lean` or `lean-toolchain`. You can also force a reconfigure by passing the new `--reconfigure` / `-R` option to `lake`.
  - Lake configuration options (i.e., `-K`) will be fixed at the moment of elaboration. Setting these options when `lake` is using the cached configuration will have no effect. To change options, run `lake` with `-R` / `--reconfigure`.
  - **The `lakefile.olean` is a local configuration and should not be committed to Git. Therefore, existing Lake packages need to add it to their `.gitignore`.**
- The signature of `Lake.buildO` has changed, `args` has been split into `weakArgs` and `traceArgs`. `traceArgs` are included in the input trace and `weakArgs` are not. See Lake's [FFI example](https://github.com/leanprover/lean4/blob/releases/v4.1.0/src/lake/examples/ffi/lib/lakefile.lean) for a demonstration of how to adapt to this change.
- The signatures of `Lean.importModules`, `Lean.Elab.headerToImports`, and `Lean.Elab.parseImports`
- There is now [an `occs` field](https://github.com/leanprover/lean4/pull/2470) in the configuration object for the `rewrite` tactic, allowing control of which occurrences of a pattern should be rewritten. This was previously a separate argument for `Lean.MVarId.rewrite`, and this has been removed in favour of an additional field of `Rewrite.Config`. It was not previously accessible from user tactics.
