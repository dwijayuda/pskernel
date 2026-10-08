# PSC0 native PSKernel Core self-host architecture

Status: **native provider integration candidate**. Historical compiler-only
fixed-point receipts are separate from new PSKernel Core checked acceptance.
Only a completed `fixed-point --kernel pskernel-core` run proves the new path
for the exact commit checked; no permanent success is inferred from this document.

## Design boundaries

1. The historical 55-module source closure stays unchanged. Its root is
   `packages/bootstrap/src/Ps/Bootstrap/SelfHost.lean` and includes no kernel.
2. `packages/pskernel-core/src/Ps/KernelCore/SelfHost.lean` is the one
   PSKernel Core semantic source; it is built **natively through Lean 4.34**
   into `psc_kernel_core_provider`. Lean is the *compiler/runtime* for this
   implementation, not the independent admission authority.
3. The host-only `Ps.Host.KernelCoreProvider` decodes canonical admissions
   v2, builds the PSC0 prelude in a fresh PSKernel session, then uses
   `psKernelV1AdmitDeclaration`. An invalid, unsupported, exhausted or
   inconsistent request rejects. No unchecked environment insertion and no
   cross-provider fallback.
4. `scripts/checked-kernel-provider.mjs` selects the native executable
   explicitly. `pskernel-core` is the PSC0 default; `lean434-wasm` and
   `lean434` remain explicit *alternative* selectors. The old JS checker is
   historical and not the owned kernel for the new selector.
5. Native checked seed / generated JS compiler still emit TypeScript 5.8.3.
   Until direct JS is separately qualified, this retains the proven
   compiler-only output and does not introduce a new backend.
6. Checked artifacts are produced after provider acceptance of the exact
   admissions bytes. The generated compiler emits the same prepared module;
   TS/JS/source identities and fixed point are checked independently.
   Receipts are audit records, not cryptographic proof objects.

## Typical commands (from `psc0/`)

After installing Lean 4.34 and the pinned TypeScript dependency:

```sh
npm install --ignore-scripts --no-package-lock
lake build psc_kernel_core_provider
lake exe psc_kernel_core_provider_tests
node --test scripts/checked-kernel-core.test.mjs
node scripts/checked-selfhost.mjs fixed-point --kernel pskernel-core
```

If and only if the 12 portable package trees have **exact historical Git
identities**, skip the broad Lean regression suite in the repeated bootstrap:

```sh
node scripts/selfhost-baseline.mjs --assert-unchanged
node scripts/checked-selfhost.mjs fixed-point --kernel pskernel-core --fast
```

Fast still performs actual native kernel checks and full source/TS generation
comparison over bootstrap/selfhost/repeat. It does **not** skip semantic
checking; it only avoids rebuilding the same broad regression suite.
Fast refuses to run if any source in the 12 locked trees is changed or dirty,
including untracked files. For modifications, use the normal command.

## Efficient change classification

| Change | Cheap check | Required stronger gate |
| --- | --- | --- |
| Documentation or `legacy/` only | Static guards | None for immutable core; full reproducibility periodically |
| Optional JS/Wasm/Rust backend only | Package build/target tests | Their own backend conformance tests |
| Native provider host adapter | Native provider tests | Full checked fixed point |
| PSKernel semantic modules | Kernel unit, differential and rejection tests | Full checked fixed point |
| Any of 12 portable compiler packages | Source-closure/root/grammar checks | Full historical + native-core checked fixed point |
| Toolchain/policy/contract | Pin and identity checks | Full checked fixed point before release |

`.github/workflows/psc0-native-selfhost.yml` uses path-aware execution:
fast invariants plus native provider tests on pertinent PRs, and the expensive
fixed-point job step only on semantic changes or explicit dispatch. Lake
incremental compilation and GitHub cache reuse avoid recompiling unchanged
modules. Cache hits never substitute for kernel checking or fixed-point
comparison.

## Limits and future proof work

- The owned kernel remains a *candidate* until the full PSC0 corpus and
  acceptance policy are discharged. Documented Lean 4.34 compatibility is not
  formal kernel soundness.
- Native Lean must be installed to **build** the kernel provider; production
  consumers can receive a prebuilt native executable after platform-specific
  verification. This is separate from requiring the official Lean kernel at
  runtime. An executable built by Lean is not itself certified.
- A successful compiler-only fixed point does not imply a joint self-host
  kernel/compiler fixed point or soundness of erasure and backend semantics.
- Any new semantic code must first pass targeted checks and full
  relevant acceptance; **no** arbitrary edit can be guaranteed sound solely
  by a filename filter, checksum or compilation success.
- Lean 4.34.0 is historical pin; further Lean version changes are separate
  compatibility migrations.

### Primary references

- Lean 4.34 release: https://lean-lang.org/doc/reference/latest/releases/v4.34.0/
- Lean Lake incremental builds: https://lean-lang.org/doc/reference/latest/Build-Tools-and-Distribution/Lake/
- Historical PSC0 fixed point: `docs/continuity/COMPILER_FIXED_POINT_2026-10-03.md`
- PSKernel Core contract: `packages/pskernel-core/KERNEL_CONTRACT_V1.md`
- Kernel M4 native provider evidence: `packages/pskernel-core/M4_ACCEPTANCE.md`.
