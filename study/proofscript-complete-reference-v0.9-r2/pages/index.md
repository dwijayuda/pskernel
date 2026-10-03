# ProofScript — The Lean Language Reference

[Reference home](../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Read the ProofScript writing guide first, then follow the matching topic pages for inherited grammar, API signatures and detailed examples. All 222 mirrored HTML paths are accounted for: 218 articles and four nonarticle placeholders. This is content coverage, not a theorem that all examples compile or that all native capabilities are implemented by PSC.

**Compiler and coverage boundary.** Keep the v0.9-r2 surface authoritative and the stable semantic source above the rc2 mirror. Preserve the source attribution and distinguish generated presentation from executed evidence.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/index.html). Source Git blob: `351059186f54d753ab010bb092a74439c045693b`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## The Lean Language Reference

This is the *Lean Language Reference*. It is intended to be a comprehensive, precise description of Lean: a reference work in which Lean users can look up detailed information, rather than a tutorial intended for new users. For other documentation, please refer to the [Lean documentation overview](https://lean-lang.org/documentation/). This manual covers Lean version `4.34.0-rc2`.

Lean is an **interactive theorem prover** based on dependent type theory, designed for use both in cutting-edge mathematics and in software verification. Lean's core type theory is expressive enough to capture very complicated mathematical objects, but simple enough to admit independent implementations, reducing the risk of bugs that affect soundness. The core type theory is implemented in a minimal [kernel](Elaboration-and-Compilation/index.md#--tech-term-kernel) that does nothing other than check proof terms. This core theory and kernel are supported by advanced automation, realized in [an expressive tactic language](Tactic-Proofs/index.md#tactics). Each tactic produces a term in the core type theory that is checked by the kernel, so bugs in tactics do not threaten the soundness of Lean as a whole. Along with many other parts of Lean, the tactic language is user-extensible, so it can be built up to meet the needs of a given formalization project. Tactics are written in Lean itself, and can be used immediately upon definition; rebuilding the prover or loading external modules is not required.

Lean is also a pure **functional programming language**, with features such as a run-time system based on reference counting that can efficiently work with packed array structures, multi-threading, and monadic `IO`. As befits a programming language, Lean is primarily implemented in itself, including the language server, build tool, [elaborator](Elaboration-and-Compilation/index.md#--tech-term-Elaboration), and tactic system. This very book is written in [Verso](https://github.com/leanprover/verso), a documentation authoring tool written in Lean.

Familiarity with Lean's programming features is valuable even for users whose primary interest is in writing proofs, because Lean programs are used to implement new tactics and proof automation. Thus, this reference manual does not draw a barrier between the two aspects, but rather describes them together so they can shed light on one another.

### Contents

1. [1. Introduction](Introduction/index.md#introduction)
2. [2. Elaboration and Compilation](Elaboration-and-Compilation/index.md#The-Lean-Language-Reference--Elaboration-and-Compilation)
3. [3. Interacting with Lean](Interacting-with-Lean/index.md#interaction)
4. [4. The Type System](The-Type-System/index.md#type-system)
5. [5. Source Files and Modules](Source-Files-and-Modules/index.md#files)
6. [6. Namespaces and Sections](Namespaces-and-Sections/index.md#namespaces-sections)
7. [7. Definitions](Definitions/index.md#definitions)
8. [8. Axioms](Axioms/index.md#axioms)
9. [9. Attributes](Attributes/index.md#attributes)
10. [10. Type Classes](Type-Classes/index.md#type-classes)
11. [11. Coercions](Coercions/index.md#coercions)
12. [12. Run-Time Code](Run-Time-Code/index.md#runtime)
13. [13. Terms](Terms/index.md#terms)
14. [14. Tactic Proofs](Tactic-Proofs/index.md#tactics)
15. [15. The Simplifier](The-Simplifier/index.md#the-simplifier)
16. [16. The `grind` tactic](The--grind--tactic/index.md#grind-tactic)
17. [17. The `mvcgen` tactic](The--mvcgen--tactic/index.md#mvcgen-tactic)
18. [18. Functors, Monads and `do`-Notation](Functors___-Monads-and--do--Notation/index.md#monads-and-do)
19. [19. Basic Propositions](Basic-Propositions/index.md#basic-props)
20. [20. Basic Types](Basic-Types/index.md#basic-types)
21. [21. IO](IO/index.md#io)
22. [22. Iterators](Iterators/index.md#iterators)
23. [23. Notations and Macros](Notations-and-Macros/index.md#language-extension)
24. [24. Build Tools and Distribution](Build-Tools-and-Distribution/index.md#build-tools-and-distribution)
25. [Validating a Lean Proof](ValidatingProofs/index.md#validating-proofs)
26. [Error Explanations](Error-Explanations/index.md#The-Lean-Language-Reference--Error-Explanations)
27. [Release Notes](releases/index.md#release-notes)
28. [Supported Platforms](platforms/index.md#platforms)
29. [Index](the-index/index.md#The-Lean-Language-Reference--Index)
