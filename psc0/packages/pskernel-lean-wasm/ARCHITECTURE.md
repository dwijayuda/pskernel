# Lean 4.35.0 C++ kernel — PSC0 v7.2 Wasm (linear memory)

## Chosen implementation

The official Lean 4.35.0 C++ kernel is compiled into a **wasm32
linear-memory** executable with the pinned Emscripten toolchain. The
small generated Lean admission endpoint imports **live PSC0** bridge,
Standard and provider modules, and calls the genuine
`Lean.Kernel.Environment.addDeclCore` admission path.

Wasm GC is **not** the target of this package. The PSC0 GC backend remains
a separate research project; a GC probe must never be shipped as a kernel.
No VSIX or editor loader is included.

## Trust boundary

- The kernel and its C++ dependencies are built from official Lean commit
  `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`, never a cached 4.34
  binary. Exact Emscripten version and source checkout are checked.
- PSC0 input is canonical admissions version 2, decoded by current
  `PsKernelLean.Protocol` from `psc0/packages/pskernel-lean/provider`;
  the active PSC0 Standard prelude is replayed before any declarations.
- C++ admission uses `addDeclCore`; error categories distinguish malformed
  requests, protocol errors, and actual kernel rejections.
- Native and wasm target runs of the **same endpoint** must agree on
  positive and negative cases before a manifest may mark a build qualified.
  This is a differential smoke gate, **not** proof of kernel soundness.
- Wasm must contain linear memory; all artifact bytes and exact source
  version are included in a versioned SHA-256 manifest. Every default API
  call checks the manifest and hashes again. No arbitrary launcher override.
- The host never accepts a missing binary, wrong identity, error output,
  corrupted artifact, or transport failure as a successful check.
- No source snapshots, old PSC2 runtime, 4.34 kernel, hidden fallback,
  generated GC code, or self-host compiler sources are bundled.

## Build stages

1. Fetch exact Lean 4.35.0 C++ sources into an ignored build cache.
2. Apply narrow, auditable Emscripten-only compatibility fixes to that cache.
3. Build a native 32-bit bootstrap stage0 for wasm32-compatible generation.
4. Cross-build target Lean runtime, Std, Lean and C++ kernel libraries.
5. Resolve the live PSC0 Lean import DAG into an **ignored** build overlay.
6. Emit provider C with native i386 stage0 against wasm32 .olean sysroot.
7. Compile/link through Emscripten into `wasm/pskernel-lean.wasm`
   and `wasm/pskernel-lean.cjs`.
8. Execute runtime health and native-vs-Wasm positive/negative parity.
9. Only after the preceding gates succeed, write manifest and stage bytes.

The independent PSC0/native kernel remains the development oracle.
The package is private until complete conformance (including Lean Arena and
broader Standard-identity fixtures) and deployment performance are demonstrated.
