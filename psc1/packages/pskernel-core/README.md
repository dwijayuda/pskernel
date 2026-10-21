# @proofscript/pskernel-core

This package contains the independent, portable PSKernel-Core implementation.
The current integration target is Lean **4.35.0**, pinned to
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.

**Expression V2 is in progress.** The paged expression DAG, transformations,
and several checker/admission rules are integrated, but general operations
still retain complete V1 fallback. V1 remains the default/reference checker.
Local proofs and passing differential tests do not constitute a global
soundness theorem or full Lean Arena qualification.

## Start here

- [AI_WORK_STATE.md](AI_WORK_STATE.md): source-anchored current evidence,
  unresolved gates, performance regressions and continuation work.
- [EXPRESSION_V2_STATUS.md](EXPRESSION_V2_STATUS.md): DAG ownership, exact
  fallback inventory, proof limits and completion gates.
- [PERFORMANCE_2026-10-21.md](PERFORMANCE_2026-10-21.md): source-specific
  public-operation/admission measurements and authentic timeout profiles.
- [PROVIDER.md](PROVIDER.md): native and generated-JavaScript batch checking,
  the supported canonical transport, failure protocol, and reproducible builds.
- [KERNEL_CONTRACT_V1.md](KERNEL_CONTRACT_V1.md): typed checked API,
  resource outcomes, session publication and trust boundary.
- [PSKERNEL_CORE_ARCHITECTURE.md](PSKERNEL_CORE_ARCHITECTURE.md): ownership rules.

Import `Ps.KernelCore.API.Kernel` for checked sessions, expressions and
declaration admission. Construct sessions with `psKernelKernelSessionEmpty`
and extend them only through successful checked admission. Untrusted callers
must never inject an environment, semantic cache or native evaluator.

`Ps.KernelCore.API.Dag` exposes the experimental validated DAG batch API
`psKernelV1RunDag`. This API validates its input graph and independently
checks declarations. Unsupported DAG operations restart the preserved V1
operation with the same resources; that migration fallback does not invoke
official Lean.

The complete portable execution root is
`src/Ps/KernelCore/SelfHost.lean`. The authentic PSC1/TypeScript 7.0.2
route builds JavaScript with declarations and source maps. Canonical `.ps`
sources are reconstructed and independently checked by the portability
workflow. Complete-kernel DirectJS emission remains unsupported.

## Source and qualification boundaries

Semantic source is organized under `Core/`, `Environment/`,
`Runtime/`, `Checker/`, `Admission/` and `API/`. Source must retain
the PSC1 portable profile: no unchecked proof terms, trusted runtime
intrinsics, or new native implementation escape hatches. Host IO and
transport adapters stay outside this portable closure.

The current developer provider is bounded and explicitly scoped. It does not
silently install a standard environment, use the historical PSC0 npm
provider, or publish a new npm release. The checked V1 API supports more
forms than the canonical provider transport; consult its contract before
integration.

Historical `LEAN_4_34_*.json`, migration reports, and self-host receipts
describe earlier checkpoints and remain preserved for provenance. Their
names, module counts and pass states do not qualify this branch's current
4.35/V2 source. Current status is the exact revision and terminal Actions
evidence in `AI_WORK_STATE.md`.
