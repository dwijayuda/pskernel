<a id="build-tools-and-distribution"></a>

# ProofScript — 24. Build Tools and Distribution

[Reference home](../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Lake and Elan in the source are Lean tools. Their commands, configuration and APIs remain native-host reference documentation. ProofScript may use npm package metadata, lockfiles and generated canonical sources, but that does not turn a Lake API into a PSC API. Pin source edition, grammar, semantic commit, dependencies, axiom policy, runtime and target separately.

**Compiler and coverage boundary.** Reference-tool execution does not imply a standalone dependency on Lean at runtime. Self-hosting and repeatable builds are engineering evidence, not compiler-preservation proofs.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Build-Tools-and-Distribution/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Build-Tools-and-Distribution/index.html). Source Git blob: `c839388a5d38c1b69f34481f9ffcb3477ae485ac`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 24. Build Tools and Distribution

The Lean 
<a id="--tech-term-toolchain"></a>
*toolchain* is the collection of command-line tools that are used to check proofs and compile programs in collections of Lean files. Toolchains are managed by `elan`, which installs toolchains as needed. Lean toolchains are designed to be self-contained, and most command-line users will never need to explicitly invoke any other than `lake` and `elan`. They contain the following tools:

  `lean`

The Lean compiler, used to elaborate and compile a Lean source file.

  `lake`

The Lean build tool, used to incrementally invoke `lean` and other tools while tracking dependencies.

  `leanc`

The C compiler that ships with Lean, which is a version of [Clang](https://clang.llvm.org/).

  `leanmake`

An implementation of the `make` build tool, used for compiling C dependencies.

  `leanchecker`

A tool that replays elaboration results from [`.olean` files](../Elaboration-and-Compilation/index.md#--tech-term-___olean-file) through the Lean kernel, providing additional assurance that all terms were properly checked.

In addition to these build tools, toolchains contain files that are needed to build Lean code. This includes source code, [`.olean` files](../Elaboration-and-Compilation/index.md#--tech-term-___olean-file), compiled libraries, C header files, and the compiled Lean run-time system. They also include external proof automation tools that are used by tactics included with Lean, such as `cadical` for `bv_decide`.

1. [24.1. Lake](Lake/index.md#lake)
2. [24.2. Managing Toolchains with Elan](Managing-Toolchains-with-Elan/index.md#elan)
