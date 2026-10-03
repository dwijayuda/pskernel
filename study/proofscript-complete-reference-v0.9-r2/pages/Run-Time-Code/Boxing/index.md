<a id="boxing"></a>

# ProofScript — 12.1. Boxing

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

The inherited chapter describes Lean runtime mechanisms such as boxing, reference counting, threading and the native foreign-function ABI. Those are not automatic properties of JavaScript or Wasm output. ProofScript backends may choose different representations only under their stated preservation relation. An optimized or external implementation can disagree with its logical definition while the logical theorem remains valid; executable assurance must account for that gap.

**Compiler and coverage boundary.** Keep C signatures and Lean ABI names unchanged and clearly classified as native-host documentation. Do not pretend that owning an emitter proves its runtime correct.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Run-Time-Code/Boxing/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Run-Time-Code/Boxing/index.html). Source Git blob: `6b3f0d6e650b5b8ef4bd0330b7aad5761849f6f4`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 12.1. Boxing

Lean values may be represented at runtime in two ways:

- <a id="--tech-term-Boxed"></a>
  *Boxed* values may be pointers to heap values or require shifting and masking.
- <a id="--tech-term-Unboxed"></a>
  *Unboxed* values are immediately available.

Boxed values are either a pointer to an object, in which case the lowest-order bit is 0, or an immediate value, in which case the lowest-order bit is 1 and the value is found by shifting the representation to the right by one bit.

Types with an unboxed representation, such as `UInt8` and [enum inductive](../../The-Type-System/Inductive-Types/index.md#--tech-term-enum-inductive) types, are represented as the corresponding C types in contexts where the compiler can be sure that the value has said type. In some contexts, such as generic container types like `Array`, otherwise-unboxed values must be boxed prior to storage. In other words, `Bool.not` is called with and returns unboxed `uint8_t` values because the [enum inductive](../../The-Type-System/Inductive-Types/index.md#--tech-term-enum-inductive) type `Bool` has an unboxed representation, but the individual `Bool` values in an `Array Bool` are boxed. A field of type `Bool` in an inductive type's constructor is represented unboxed, while `Bool`s stored in polymorphic fields that are instantiated as `Bool` are boxed.
