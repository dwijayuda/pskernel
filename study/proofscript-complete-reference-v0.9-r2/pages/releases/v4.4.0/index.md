<a id="release-v4___4___0"></a>

# ProofScript — Lean 4.4.0 (2023-12-31)

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

These articles are the mirrored Lean release notes, not ProofScript releases. They document historical syntax, APIs, implementations and changes. The page named v4.34.0 in this mirror still identifies itself as rc2. Native source at the selected stable commit overrides stale details for a current ProofScript conformance claim. Historical examples remain native and are not silently modernized.

**Compiler and coverage boundary.** The stable delta note explicitly excludes the old native-reduction kernel hooks. Upgrading the pin requires a new reference/profile review and regenerated evidence.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [releases/v4.4.0/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/releases/v4.4.0/index.html). Source Git blob: `398523bc5349a8cfb7a0994167b066e4332bc589`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## Lean 4.4.0 (2023-12-31)

- Lake and the language server now support per-package server options using the `moreServerOptions` config field, as well as options that apply to both the language server and `lean` using the `leanOptions` config field. Setting either of these fields instead of `moreServerArgs` ensures that viewing files from a dependency uses the options for that dependency. Additionally, `moreServerArgs` is being deprecated in favor of the `moreGlobalServerArgs` field. See PR [#2858](https://github.com/leanprover/lean4/pull/2858).

   

  A Lakefile with the following deprecated package declaration:

   

  ```text
  def moreServerArgs := #[
    "-Dpp.unicode.fun=true"
  ]
  def moreLeanArgs := moreServerArgs

  package SomePackage where
    moreServerArgs := moreServerArgs
    moreLeanArgs := moreLeanArgs
  ```

  

  ... can be updated to the following package declaration to use per-package options:

   

  ```text
  package SomePackage where
    leanOptions := #[⟨`pp.unicode.fun, true⟩]
  ```
- [Rename request handler](https://github.com/leanprover/lean4/pull/2462).
- [Import auto-completion](https://github.com/leanprover/lean4/pull/2904).
- [`pp.beta`` to apply beta reduction when pretty printing](https://github.com/leanprover/lean4/pull/2864).
- [Embed and check githash in .olean](https://github.com/leanprover/lean4/pull/2766).
- [Guess lexicographic order for well-founded recursion](https://github.com/leanprover/lean4/pull/2874).
- [Allow trailing comma in tuples, lists, and tactics](https://github.com/leanprover/lean4/pull/2643).

Bug fixes for [#2628](https://github.com/leanprover/lean4/issues/2628), [#2883](https://github.com/leanprover/lean4/issues/2883), [#2810](https://github.com/leanprover/lean4/issues/2810), [#2925](https://github.com/leanprover/lean4/issues/2925), and [#2914](https://github.com/leanprover/lean4/issues/2914).

**Lake:**

- `lake init .` and a bare `lake init` and will now use the current directory as the package name. [#2890](https://github.com/leanprover/lean4/pull/2890)
- `lake new` and `lake init` will now produce errors on invalid package names such as `..`, `foo/bar`, `Init`, `Lean`, `Lake`, and `Main`. See issue [#2637](https://github.com/leanprover/lean4/issues/2637) and PR [#2890](https://github.com/leanprover/lean4/pull/2890).
- `lean_lib` no longer converts its name to upper camel case (e.g., `lean_lib bar` will include modules named `bar.*` rather than `Bar.*`). See issue [#2567](https://github.com/leanprover/lean4/issues/2567) and PR [#2889](https://github.com/leanprover/lean4/pull/2889).
- Lean and Lake now properly support non-identifier library names (e.g., `lake new 123-hello` and `import «123Hello»` now work correctly). See issue [#2865](https://github.com/leanprover/lean4/issues/2865) and PR [#2889](https://github.com/leanprover/lean4/pull/2888).
- Lake now filters the environment extensions loaded from a compiled configuration (`lakefile.olean`) to include only those relevant to Lake's workspace loading process. This resolves segmentation faults caused by environment extension type mismatches (e.g., when defining custom elaborators via `elab` in configurations). See issue [#2632](https://github.com/leanprover/lean4/issues/2632) and PR [#2896](https://github.com/leanprover/lean4/pull/2896).
- Cloud releases will now properly be re-unpacked if the build directory is removed. See PR [#2928](https://github.com/leanprover/lean4/pull/2928).
- Lake's `math` template has been simplified. See PR [#2930](https://github.com/leanprover/lean4/pull/2930).
- `lake exe <target>` now parses `target` like a build target (as the help text states it should) rather than as a basic name. For example, `lake exe @mathlib/runLinter` should now work. See PR [#2932](https://github.com/leanprover/lean4/pull/2932).
- `lake new foo.bar [std]` now generates executables named `foo-bar` and `lake new foo.bar exe` properly creates `foo/bar.lean`. See PR [#2932](https://github.com/leanprover/lean4/pull/2932).
- Later packages and libraries in the dependency tree are now preferred over earlier ones. That is, the later ones "shadow" the earlier ones. Such an ordering is more consistent with how declarations generally work in programming languages. This will break any package that relied on the previous ordering. See issue [#2548](https://github.com/leanprover/lean4/issues/2548) and PR [#2937](https://github.com/leanprover/lean4/pull/2937).
- Executable roots are no longer mistakenly treated as importable. They will no longer be picked up by `findModule?`. See PR [#2937](https://github.com/leanprover/lean4/pull/2937).
