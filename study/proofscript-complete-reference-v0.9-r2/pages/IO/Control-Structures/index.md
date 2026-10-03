<a id="io-monad-control"></a>

# ProofScript — 21.2. Control Structures

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Native IO separates a logical description from execution in a runtime environment. Console operations, mutable references, files, processes, clocks, randomness and tasks have exact APIs and effects. A file handle is a resource with identity and lifetime, not an immutable DTO. Browser, Node and Wasm hosts require explicit adapters; the existence of a Lean API does not establish that every target can implement it.

**Compiler and coverage boundary.** Retain native Task behavior rather than renaming Promise. Resource cleanup, cancellation, process termination and foreign failures need exact declared models; no undocumented async/await keyword is introduced.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [IO/Control-Structures/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/IO/Control-Structures/index.html). Source Git blob: `5a7ff1511edaf26c09d1e4b1261e7a408927c457`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 21.2. Control Structures

Normally, programs written in `IO` use [the same control structures as those written in other monads](../../Functors___-Monads-and--do--Notation/index.md#monads-and-do). There is one specific `IO` helper.

<a id="IO___iterate"></a>

**opaque**

```text
IO.iterate {α β : Type} (a : α) (f : α → IO (α ⊕ β)) : IO β
```

Iterates an `IO` action. Starting with an initial state, the action is applied repeatedly until it returns a final value in `Sum.inr`. Each time it returns `Sum.inl`, the returned value is treated as a new state.
