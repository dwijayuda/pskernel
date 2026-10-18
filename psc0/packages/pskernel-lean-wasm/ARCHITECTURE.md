# PSC0 v7.2 Wasm-GC kernel architecture and trust boundary

## Invariants

1. `psc0/pscv0-v7-native-lean-v1` remains the separately developed compiler.
   This branch is isolated from PR #109 and does not alter its official checker.
2. One source authority: `PSCV0_LANGUAGE_REFERENCE_v7.2.md`, stable Lean
   4.35.0 `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
3. `.lean` and `.ps` inputs obey the same PSC0 v7.2 assurance and
   supported-language restrictions. A `.lean` extension is not a bypass.
4. The official Lean 4.35.0 kernel is the present acceptance oracle.
   The generated `gc-probe.core.wasm` is NOT a checker and is not published.
5. No direct Emscripten C++ Lean runtime: it uses linear memory, contrary
   to the requested Wasm-GC-only implementation.
6. No vendored 4.34 C++ kernel, PSC2 portable library snapshots,
   old protocol implementation, binary launcher or unreviewed 4.34 patches.
7. A rejected proof and an unavailable checker are **distinct**: fail closed
   with `PSC0-WASM-GC-KERNEL-NOT-READY` while unavailable.
8. `propext`, `Quot.sound`, `Classical.choice` are precisely the current
   approved standard foundation, not arbitrary user axioms. No proof holes.
9. Runtime equivalence cannot be inferred from successful Lean elaboration,
   kernel acceptance or Wasm compilation; differential and semantic tests
   are separate acceptance conditions.

## Staged implementation

P0 **Complete in source:** new branch, delete legacy package tree,
pin 4.35/v7.2, minimal package, fail-closed API and CI pipeline.
P1 **GC infrastructure:** prove emitted Wasm uses struct/array and has
no linear memory; run it under Node and browser-capable Wasm engines.
P2 **Real checker:** port/adapt a kernel to portable native Lean source
with precisely stated kernel rules and bounded resources. Do not pretend
a GC transport, fake stub or PSKernel-C0 experiment already provides
official-kernel-equivalent admission.
P3 **Conformance:** exact Standard+admissions identity; native vs GC
valid/invalid suites, Lean Arena, inductive/quotient/universe regressions,
version/assumption and performance evidence. No accepting API before this.
P4 **Editor distribution:** long-lived nonblocking worker, cancellation,
per-document snapshots, manifest/integrity validation, trusted VSIX
workspace-host loader; no unverified source fallback or silent downgrade.

## Why native Lean checking remains required today

The selected PSC0 native host currently uses `PsKernelLean.decodeCanonicalAdmissions`
followed by `Lean.Kernel.Environment.addDeclCore`, reconstructed from the
exact 4.35 Standard environment. It is not a GC kernel implementation.
The old `pskernel-lean-wasm` used Lean 4.34, an obsolete PSC2 prelude,
and linear-memory Emscripten. Its binary cannot be retained or relabeled.

Future GC kernel sources must use PSC0 `packages/*/src/Ps` and
`host/src/Ps/Host` as appropriate for explicit cross-boundary checks.
No duplicate pinned library snapshots inside this package. Native reference
code may stay host-only; the GC kernel source itself must be portable.
