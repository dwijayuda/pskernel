<a id="The-Lean-Language-Reference--Run-Time-Code--Multi-Threaded-Execution"></a>

# ProofScript — 12.3. Multi-Threaded Execution

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

The inherited chapter describes Lean runtime mechanisms such as boxing, reference counting, threading and the native foreign-function ABI. Those are not automatic properties of JavaScript or Wasm output. ProofScript backends may choose different representations only under their stated preservation relation. An optimized or external implementation can disagree with its logical definition while the logical theorem remains valid; executable assurance must account for that gap.

**Compiler and coverage boundary.** Keep C signatures and Lean ABI names unchanged and clearly classified as native-host documentation. Do not pretend that owning an emitter proves its runtime correct.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Run-Time-Code/Multi-Threaded-Execution/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Run-Time-Code/Multi-Threaded-Execution/index.html). Source Git blob: `0129ff5db7d1ab5a208ca63b8b91b41982573e60`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 12.3. Multi-Threaded Execution

Lean includes primitives for parallel and concurrent programs, described using [tasks](../../IO/Tasks-and-Threads/index.md#--tech-term-Tasks). The Lean runtime system includes a task manager that assigns hardware resources to tasks. Along with the API for defining tasks, this is described in detail in the [section on multi-threaded programs](../../IO/Tasks-and-Threads/index.md#concurrency).
