<a id="runtime"></a>

# ProofScript — 12. Run-Time Code

[Reference home](../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

The inherited chapter describes Lean runtime mechanisms such as boxing, reference counting, threading and the native foreign-function ABI. Those are not automatic properties of JavaScript or Wasm output. ProofScript backends may choose different representations only under their stated preservation relation. An optimized or external implementation can disagree with its logical definition while the logical theorem remains valid; executable assurance must account for that gap.

**Compiler and coverage boundary.** Keep C signatures and Lean ABI names unchanged and clearly classified as native-host documentation. Do not pretend that owning an emitter proves its runtime correct.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Run-Time-Code/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Run-Time-Code/index.html). Source Git blob: `1e871b2ef8f253c2512e00267112ed7fd445e0f5`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 12. Run-Time Code

Compiled Lean code uses services provided by the Lean runtime. The runtime contains efficient, low-level primitives that bridge the gap between the Lean language and the supported platforms. These services include:

  Memory management

Lean does not require programmers to manually manage memory. Space is allocated when needed to store a value, and values that can no longer be reached (and are thus irrelevant) are deallocated. In particular, Lean uses [reference counting](Reference-Counting/index.md#--tech-term-reference-counting), where each allocated object maintains a count of incoming references. The compiler emits calls to memory management routines that allocate memory and modify reference counts, and these routines are provided by the runtime, along with the data structures that represent Lean values in compiled code.

  Multiple Threads

The `Task` API provides the ability to write parallel and concurrent code. The runtime is responsible for scheduling Lean tasks across operating-system threads.

  Primitive operators

Many built-in types, including `Nat`, `Array`, `String`, and fixed-width integers, have special representations for reasons of efficiency. The runtime provides implementations of these types' primitive operators that take advantage of these optimized representations.

There are many primitive operators. They are described in their respective sections under [Basic Types](../Basic-Types/index.md#basic-types).

1. [12.1. Boxing](Boxing/index.md#boxing)
2. [12.2. Reference Counting](Reference-Counting/index.md#reference-counting)
3. [12.3. Multi-Threaded Execution](Multi-Threaded-Execution/index.md#The-Lean-Language-Reference--Run-Time-Code--Multi-Threaded-Execution)
4. [12.4. Foreign Function Interface](Foreign-Function-Interface/index.md#ffi)
