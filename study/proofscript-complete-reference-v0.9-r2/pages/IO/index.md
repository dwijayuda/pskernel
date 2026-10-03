<a id="io"></a>

# ProofScript — 21. IO

[Reference home](../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Native IO separates a logical description from execution in a runtime environment. Console operations, mutable references, files, processes, clocks, randomness and tasks have exact APIs and effects. A file handle is a resource with identity and lifetime, not an immutable DTO. Browser, Node and Wasm hosts require explicit adapters; the existence of a Lean API does not establish that every target can implement it.

## ProofScript way of writing it


```proofscript
function announce(name: String): IO Unit := do {
  IO.println("Hello, " ++ name)
  IO.println("Done")
}
```

**Compiler and coverage boundary.** Retain native Task behavior rather than renaming Promise. Resource cleanup, cancellation, process termination and foreign failures need exact declared models; no undocumented async/await keyword is introduced.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [IO/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/IO/index.html). Source Git blob: `5e9cdcfd997097fd16dd6ae1229fae9ef2b62eff`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 21. IO

Lean is a pure functional programming language. While Lean code is strictly evaluated at run time, the order of evaluation that is used during type checking, especially while checking [definitional equality](../The-Type-System/index.md#--tech-term-definitional-equality), is formally unspecified and makes use of a number of heuristics that improve performance but are subject to change. This means that simply adding operations that perform side effects (such as file I/O, exceptions, or mutable references) would lead to programs in which the order of effects is unspecified. During type checking, even terms with free variables are reduced; this would make side effects even more difficult to predict. Finally, a basic principle of Lean's logic is that functions are *functions* that map each element of the domain to a unique element of the range. Including side effects such as console I/O, arbitrary mutable state, or random number generation would violate this principle.

Programs that may have side effects have a type (typically `IO α`) that distinguishes them from pure functions. Logically speaking, `IO` describes the sequencing and data dependencies of side effects. Many of the basic side effects, such as reading from files, are opaque constants from the perspective of Lean's logic. Others are specified by code that is logically equivalent to the run-time version. At run time, the compiler produces ordinary code.

1. [21.1. Logical Model](Logical-Model/index.md#The-Lean-Language-Reference--IO--Logical-Model)
2. [21.2. Control Structures](Control-Structures/index.md#io-monad-control)
3. [21.3. Console Output](Console-Output/index.md#The-Lean-Language-Reference--IO--Console-Output)
4. [21.4. Mutable References](Mutable-References/index.md#The-Lean-Language-Reference--IO--Mutable-References)
5. [21.5. Files, File Handles, and Streams](Files___-File-Handles___-and-Streams/index.md#The-Lean-Language-Reference--IO--Files___-File-Handles___-and-Streams)
6. [21.6. System and Platform Information](System-and-Platform-Information/index.md#platform-info)
7. [21.7. Environment Variables](Environment-Variables/index.md#io-monad-getenv)
8. [21.8. Timing](Timing/index.md#io-timing)
9. [21.9. Processes](Processes/index.md#io-processes)
10. [21.10. Random Numbers](Random-Numbers/index.md#The-Lean-Language-Reference--IO--Random-Numbers)
11. [21.11. Tasks and Threads](Tasks-and-Threads/index.md#concurrency)
