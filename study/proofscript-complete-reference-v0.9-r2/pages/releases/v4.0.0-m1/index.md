<a id="release-v4___0___0-m1"></a>

# ProofScript — Lean 4.0.0-m1 (2021-01-04)

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

These articles are the mirrored Lean release notes, not ProofScript releases. They document historical syntax, APIs, implementations and changes. The page named v4.34.0 in this mirror still identifies itself as rc2. Native source at the selected stable commit overrides stale details for a current ProofScript conformance claim. Historical examples remain native and are not silently modernized.

**Compiler and coverage boundary.** The stable delta note explicitly excludes the old native-reduction kernel hooks. Upgrading the pin requires a new reference/profile review and regenerated evidence.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [releases/v4.0.0-m1/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/releases/v4.0.0-m1/index.html). Source Git blob: `5fa5f259eea4f49827637afa35df30a24ee12973`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## Lean 4.0.0-m1 (2021-01-04)

The Lean development team is proud to announce the first milestone release of Lean 4. This release is aimed at experimentation with the new features of Lean 4, eventually leading to a full release of 4.0.0 ready for general use.

This release is the result of almost three years of work since the release of Lean 3.4.0, reworking, extending, and improving almost all aspects of Lean. More information about Lean 4 can be found in the [official documentation](https://leanprover.github.io/lean4/doc/) as well as in the introductory talk ["An overview of Lean 4"](https://www.youtube.com/watch?v=UeGvhfW1v9M) at Lean Together 2021.

Leonardo de Moura & Sebastian Ullrich

<a id="The-Lean-Language-Reference--Release-Notes--Lean-4___0___0-m1-_LPAR_2021-01-04_RPAR_--Acknowledgements"></a>
### Acknowledgements

- Daniel Selsam - type class resolution, feedback, design discussions
- Marc Huisinga and Wojciech Nawrocki - Lean Server
- Joe Hendrix, Andrew Kent, Rob Dockins, Simon Winwood (Galois Inc) - early adopters, suggestions, feedback
- Daan Leijen, Simon Peyton Jones, Nikhil Swamy, Sebastian Graf, Max Wagner - design discussions, feedback, suggestions
