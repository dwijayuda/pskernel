<a id="The-Lean-Language-Reference--Iterators--Run-Time-Considerations"></a>

# ProofScript — 22.1. Run-Time Considerations

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Iterator definitions describe state and stepping; consumers observe a sequence through the permitted interfaces. Combinators such as mapping and filtering transform that process without automatically inheriting termination, productivity, effect or allocation guarantees. Preserve the distinction between finite consumers and potentially unbounded iteration. Iterator proofs belong to the native abstraction and its law dependencies.

**Compiler and coverage boundary.** Version the iterator library and its instances. A foreign async stream additionally needs backpressure, cancellation and lifetime contracts; it is not an ordinary iterator by spelling alone.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Iterators/Run-Time-Considerations/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Iterators/Run-Time-Considerations/index.html). Source Git blob: `9dcbe995f43c55958b53103b0eefd6a6526a2b4f`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 22.1. Run-Time Considerations

For many use cases, using iterators can give a performance benefit by avoiding allocating intermediate data structures. Without iterators, zipping a list with an array requires first converting one of them to the other type, allocating an intermediate structure, and then using the appropriate `zip` function. Using iterators, the intermediate structure can be avoided.

When an iterator is consumed, the resulting computation should be thought of as a single loop, even if the iterator itself is built using combinators from a number of underlying iterators. One step of the loop may carry out multiple steps from the underlying iterators. In many cases, the Lean compiler can optimize iterator computations, removing the intermediate overhead, but this is not guaranteed. When profiling shows that significant time is taken by a tight loop that involves multiple sources of data, it can be necessary to inspect the compiler's IR to see whether the iterators' operations were fused. In particular, if the IR contains many pattern matches over steps, then it can be a sign of a failure to inline or specialize. If this is the case, it may be necessary to write a tail-recursive function by hand rather than using the higher-level API.
