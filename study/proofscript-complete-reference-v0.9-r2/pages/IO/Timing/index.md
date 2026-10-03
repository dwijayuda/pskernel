<a id="io-timing"></a>

# ProofScript — 21.8. Timing

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Native IO separates a logical description from execution in a runtime environment. Console operations, mutable references, files, processes, clocks, randomness and tasks have exact APIs and effects. A file handle is a resource with identity and lifetime, not an immutable DTO. Browser, Node and Wasm hosts require explicit adapters; the existence of a Lean API does not establish that every target can implement it.

**Compiler and coverage boundary.** Retain native Task behavior rather than renaming Promise. Resource cleanup, cancellation, process termination and foreign failures need exact declared models; no undocumented async/await keyword is introduced.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [IO/Timing/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/IO/Timing/index.html). Source Git blob: `c8770631e085401bea7ce91b531572939a39e1f4`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 21.8. Timing

<a id="IO___sleep"></a>

**opaque**

```text
IO.sleep (ms : UInt32) : BaseIO Unit
```

Pauses execution for the specified number of milliseconds.

<a id="IO___monoNanosNow"></a>

**opaque**

```text
IO.monoNanosNow : BaseIO Nat
```

Monotonically increasing time since an unspecified past point in nanoseconds. There is no relation to wall clock time.

<a id="IO___monoMsNow"></a>

**opaque**

```text
IO.monoMsNow : BaseIO Nat
```

Monotonically increasing time since an unspecified past point in milliseconds. There is no relation to wall clock time.

<a id="IO___getNumHeartbeats"></a>

**opaque**

```text
IO.getNumHeartbeats : BaseIO Nat
```

Returns the number of *heartbeats* that have occurred during the current thread's execution. The heartbeat count is the number of "small" memory allocations performed in a thread.

Heartbeats used to implement timeouts that are more deterministic across different hardware.

<a id="IO___addHeartbeats"></a>

**def**

```text
IO.addHeartbeats (count : Nat) : BaseIO Unit
```

Adjusts the heartbeat counter of the current thread by the given amount. This can be useful to give allocation-avoiding code additional “weight” and is also used to adjust the counter after resuming from a snapshot.

Heartbeats are a means of implementing “deterministic” timeouts. The heartbeat counter is the number of “small” memory allocations performed on the current execution thread.
