# @proofscript/pscv-kernel

Pinned admission checker adapter, not a new kernel.

The checkWithLeanKernel API loads only @proofscript/pskernel-lean (native) or @proofscript/pskernel-lean-wasm (Wasm), both exact Lean 4.34.0 at commit 293d5d0c0c3f3dded4688b3ccd6a33939ac5102b and protocol pskernel-lean/1.

Native execution disallows the PSC_LEAN_KERNEL_PROVIDER_BIN override and checkout fallback. It uses the bundled provider with manifest hash verification. Wasm uses its bundled verified launcher. Provider identity and decision shape are checked again at the adapter boundary. No caller-selectable binary path, checker callback, or package specifier is exposed.

This package only reports the Lean kernel admission outcome of supplied Core admissions. It does not prove that the admissions represent the user's PSCV program, or grant PSCV-CERT. The Node host and pinned provider npm packages remain in the preliminary TCB.

A matching Lean 4.35 provider, formal semantic environment and source-fidelity checks are needed for V6 verified profiles.
