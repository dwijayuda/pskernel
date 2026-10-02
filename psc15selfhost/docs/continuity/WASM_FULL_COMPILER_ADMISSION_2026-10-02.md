# Full compiler admission through the Lean Wasm provider

The retained tail-loop compiler snapshot contains 55 source modules and 1,755
declarations. Its 1,205 canonical admission entries occupy 9,891,566 bytes with
SHA-256 `b20cc6f4785ebdbb4de5fb27612789baf9b1a6baab833180eb52cc0f9d710e8a`.

Reproduction identified three independent provider blockers:

1. Character conversion and character counting used input-sized native recursion.
   Tail accumulators remove the observed Wasm stack overflow. The native bridge
   regression counts one million characters and distinguishes Unicode characters
   from UTF-8 bytes.
2. Node's input pipe can make the Emscripten synchronous stdin reader fail with a
   hardware fault/EPIPE or a truncated JSON parse. The host now passes a private
   file descriptor containing the exact UTF-8 request and removes it afterward.
   A host test verifies the digest of a 10 MB request including Unicode and
   escapes. A file-backed run of the previously failing request reached checking.
3. The bundled prelude snapshot lacked the existing compiler primitive `Int.repr`.
   Its name and type declaration now match the native provider's prelude.

The resulting isolated build uses Lean commit
`293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`, Emscripten 6.0.9 and the original
32-bit native stage0 emitter. Generated C, JavaScript and Wasm were rebuilt, never
patched. ProofScript source tree:
`22f39d23220cc53b499640b5777e944a9aad5a97`.

Linux Node 22.22.1 validation:

- Full compiler payload: accepted by the actual Wasm Lean kernel, 14,679 ms.
- Same payload with the final definition body replaced by `Sort 0`: rejected by
  the kernel at admission 1,204 with `declaration-type-mismatch`; total elapsed
  time for both checks was 25,825 ms.
- Accepted/rejected smoke inputs and prebuilt artifact integrity: PASS.
- Host exact-input, provider identity, tampering and override tests: PASS.

No invalid request is retried with a different checker. Lean Wasm remains the
default; native Lean is an explicit alternative. This is external checked
bootstrap evidence, not owned-kernel self-hosting. The owned checker has separate
promotion gates. The protected generated compiler replay had completed all 55
source elaborations when this record was written, but final emission was pending.
