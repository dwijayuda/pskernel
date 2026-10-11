# Canonical kernel package rename

The package swap is a naming and integration change. It does not change kernel
rules, certify production readiness, or promote a checking provider.

| Previous location or identity | Current location or identity |
| --- | --- |
| `packages/pskernel-selfhost` | `packages/pskernel-core` |
| `@proofscript/psc1-kernel-selfhost` | `@proofscript/pskernel-core` |
| `Ps.KernelSelfHost` / `PsKernelSelfHost` Lake library | `Ps.KernelCore` / `PsKernelCore` |
| `test/KernelSelfHost` | `test/KernelCore` |
| `psc1_kernel_selfhost_foundation_tests` | `psc1_kernel_core_foundation_tests` |
| `psc1_kernel_selfhost_bench` | `psc1_kernel_core_bench` |
| `packages/pskernel-core` (experimental predecessor) | `packages/pskernel-core.old3` |
| Previous experimental provider selector `pskernel-core` | `pskernel-core.old3` |

The canonical source root remains `Ps.KernelCore.SelfHost`; self-hosting is a
capability of the core. Portable, benchmark and manual fixed-point workflows now
use the `psc1kernel-core-*` names. The existing topic branch remains
`psc2/psc1kernel-selfhost-portable`.

The archived predecessor keeps its `Ps.Kernel` modules, generated implementation,
source hashes and evidence bytes. Historical receipts and continuity records
retain their original paths and names; interpret those against their recorded
commits. Its wire protocol remains `pskernel-core/1` to preserve receipt identity,
but active package paths and explicit provider selection identify `.old3`.

`lean434-wasm` remains the default checking authority. The new core package is
private and non-authoritative; M4 integration and parity acceptance are still
required before provider promotion. Selecting `pskernel-core` cannot silently
execute the archived implementation.

Phase C continues with bounded native benchmarks and normal portable/conformance
gates. Full generated compiler/kernel fixed-point generation remains manual and
is excluded from the current cost-bounded task.
