# PSC0 Phase A — checked Lean 4.35.0 Sum foundation

Pinned upstream: `leanprover/lean4` commit
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`,
`src/Init/Core.lean` (`Sum`, `Sum.inl`, `Sum.inr`) and the
official kernel-generated `Sum.rec` metadata. See
`psc0/THIRD_PARTY_NOTICES.md` for Apache-2.0 attribution.

## Why this belongs in Phase A

The PSCV0 reference requires `Sum α β` as a first-party algebraic
type, distinct from TypeScript union types. No grammar modification,
interop adapter, dynamic union cast, or backend-specific data model is
needed. Reuse the same checked inductive, constructor, recursor, typed
erasure and Wasm GC machinery already exercised by Option/Except.

## Required kernel shape

- Two independent element universes `u` and `v`;
  `Sum (α : Type u) (β : Type v) : Type (max u v)`.
- Two constructors: `Sum.inl : α → Sum α β` and
  `Sum.inr : β → Sum α β`, with uniform type parameters implicit.
- Dependent `Sum.rec` eliminates into `Sort w`; its motive is
  implicit, each one-field minor is explicit, and its major premise
  is explicit. Recursor level parameter order is `[w,u,v]`.
- Portable Core must preserve exact names, binder info, constructor
  indices, field counts and generated iota rules for both branches.
  The official pinned Lean kernel must check every new declaration.
- Separate target-neutral logical identity from erased runtime tag
  layout; do not claim formal backend preservation from kernel replay.

## Acceptance

A two-case source fixture constructs `Sum.inl` and `Sum.inr`,
eliminates each through one `match`, and checks the same results
under official native Lean and existing JS/TypeScript/Rust/Wasm GC
and Wasmtime gates. Keep the frozen FNV/SHA registry strict and
obtain any changed digests from independent Linux drift refusal
before pinning them. Continue to reject unqualified kernel terms.

**Status:** implementation candidate only until full native and
cross-target CI at the exact source SHA passes. This scope does not
enable PSC0 self-hosting, pskernel-core or C5 and does not finish
the unrelated Float, USize/ISize, ByteArray and manifest work.
