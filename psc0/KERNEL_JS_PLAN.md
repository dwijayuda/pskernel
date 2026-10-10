# PSKernel Core JavaScript provider plan

**Status: planned intermediate provider; J0 currently blocked.** The installed preview continues to use the qualified native Core provider. No JavaScript provider, default switch, full compiler-admission replay, or new kernel self-host fixed point is announced here.

**Evidence date:** 10 October 2026, Asia/Jakarta. T1 compiler/platform work continues independently; canonical Core refinement remains a separate workstream.

## 1. Execution sequence and package boundaries

The intended sequence is **current native Core → qualified JavaScript Core → a later qualified Wasm option**. A future default change requires its own evidence and an explicit release selection. This updates the order of investigation in the [Wasm plan](docs/platform/wasm-core-provider-plan.md); its same-source, protected-admission and no-fallback requirements remain applicable.

Keep one `pskernel-core` semantic implementation. Produce the proposed `pskernel-core-js` artifact through the required PSC TypeScript backend and TypeScript 7. Keep `pskernel-core-native` and the later `pskernel-core-wasm` as execution artifacts of the selected source/profile, without separate handwritten checkers or copied semantic implementations. Initially these components may be bundled in `proofscript`; independent npm publication is unnecessary for feasibility.

JavaScript could simplify npm distribution by removing the default kernel's per-OS executable payload, including the Windows installation concern. Preview2 already has qualified Windows/native support. A JS artifact would still need fresh complete-product Windows/Linux tests; it would not automatically qualify macOS, ARM, browsers, other Node versions, or the TypeScript dependency.

## 2. What is demonstrated

| Evidence | Actual scope |
| --- | --- |
| Historical [run 37333010780][H1], source `f1ab944d…` | Native PSC/backend-ts generated Core JS using Lean 4.34 and TS 7.0.2; generated smoke and three bounded cross-runtime samples passed. This was not a complete canonical JS provider or npm qualification. |
| Current checked-in [SELFHOST_EVIDENCE.json][H2] | Explicitly a historical 24-source checkpoint. It does not certify the currently selected 79-module Core or current executable bytes. |
| Current J0 [run 38007233891][J1], harness `b94a6c55…` | Exact inputs and native public-API baseline passed. Current F prepared 20 Core modules, then refused a declaration in `Checker/State.lean`. No generated JS artifact was produced. |

The selected J0 inputs are:

- Core/native source: `963030dc2d154008fccc82e7c8ed29331f138799`.
- F compiler source: `fcd875c8f38db4b0524090bd10c7c2fd5024053d`.
- F JS SHA-256: `5eeecb1bfa00f11f1691f5ee4b437ecebe5c9a45b4e4256ab1bde23b0771df15`.
- Native provider SHA-256: `88f2d20ea733742d48724ecbdc903271e18bcfcccc8682be596a676aef68e3ec`.
- Node 22.23.3 / Lean 4.34.0 / TypeScript 7.0.2.

The probe inventories 79 unchanged Core modules plus one test-only portable fixture. Its native baseline makes seven calls covering acceptance, invalid type, unknown constant, loose variable, duplicate declaration, unsupported request and a fresh successful session. It uses public session/admission APIs without unchecked environment insertion. This baseline is separate from canonical wire-provider qualification.

Current Core Admission/Checker/Core/Runtime subtree hashes differ from the historical JS checkpoint. The selected revision is also not a claim about the latest ongoing Core refinement branch.

## 3. First observed blocker: standard-environment alignment

The exact refused declaration is [`psKernelCheckerStateExitLocalScope`][J2], original lines 163–175. Its first field uses:

```lean
nextFresh := Nat.max parent.nextFresh child.nextFresh
```

The generated F compiler reports `PsCompilerError.elaboration (PsElabError.unsupportedTerm)`. All preceding declarations in that module, including its record literals and nested record argument to `Prod.mk`, pass the diagnostic. The failed function is the addition after the historically passing module content.

Source inspection identifies missing `Nat.max` support as the immediate standard-environment gap: the selected compiler's Prelude, SelfHostPrelude, SelfHostProd and Builtin contain no such registration. The [reference resolver][J3] falls back from an absent qualified name to projection from a known first segment; treating `max` as a field of `Nat` explains the generic error. The failed declaration is execution evidence; this narrower explanation is source-based diagnosis, not a separately executed isolated-name test.

**Preserve the scope-exit function.** It restores parent-context semantic caches and carries forward the maximum fresh-name counter. Removing this refinement to obtain JS is unacceptable.

Investigate a proper standard-library solution:

1. Align source name resolution, the declared meaning of `Nat.max`, runtime execution and admission.
2. If adding it to a shared prelude, deliberately reconcile the selected native provider's prelude identity and declarations too. Compiler-only registration can otherwise emit references unknown to the pinned provider.
3. Alternatively, investigate an explicit portable library definition included and checked in the ordinary admission stream before its consumers. Establish correspondence with Lean 4.34's meaning. This could avoid expanding a trusted primitive set, but its source loading, name ownership and admission ordering must be explicit.
4. Requalify affected compiler/runtime inputs, then repeat J0 without rewriting Core. Do not insert an undocumented helper into the probe to make it pass.

There may be further gaps after this first refusal; J0 does not establish that `Nat.max` is the only remaining issue.

## 4. J0 and J1 gates

| Gate | Required result |
| --- | --- |
| J0: unchanged-Core generation | Exact selected source and F/compiler identity; complete preparation; native admission of generated candidates; checked emission of the same original IR; TS7 validation; retained TS/JS hashes. |
| J0: bounded generated execution | Same public-API fixture decisions as native, fresh sessions and exact large-natural behavior, under recorded time/memory observations. |
| J1: canonical provider | Reuse the canonical codec, checked prelude and admission seam; one fresh session per batch; truthful JS execution identity. |
| J1: deployment workload | Same-request native parity, required positive/negative cases, and complete retained F admission streams within declared budgets. Disagreement or exhaustion blocks qualification. |
| J1: installed product | Authenticated artifact/runner, strict request/result binding, refusal preservation and disclosure; fresh Windows/Linux Node22/26 installations with `--ignore-scripts`, without a native Core executable requirement. |

J0 has reached neither generated-candidate admission nor IR/TS emission. J1 has not started.

The canonical native adapter currently uses namespace declarations absent from the portable parser. Current source maps also name `Ps.Kernel` instead of the actual `Ps.KernelCore`. The probe uses a bounded private collector; it does not patch the production resolver or duplicate the canonical codec. Resolve these interfaces deliberately before a full provider.

Use one release-owned Node subprocess and a small canonical batch/result interface. Authenticate the exact generated bytes that execute; keep the publisher, project filesystem authority and extension reporting in the supervisor. Preserve `nativeEvaluator = none`. Missing artifacts, malformed results, timeouts, crashes, resource exhaustion and logical rejection produce no admission. There is no automatic fallback or “accept if either runtime accepts.”

A subprocess provides lifecycle separation. **It is not a sandbox for arbitrary JavaScript.** The generated checker and its adapter are approved distribution code; npm extensions cannot supply a replacement checker or acquire its authority. Do not claim a hard total-memory bound from a V8 heap option alone.

## 5. Proof and self-host boundaries

Reuse source-level Core models, metatheory and implementation-refinement results only at matching source/profile revisions. Organize later compiler/provider assurance in `psc0/proofs/**/*.proof.lean`, outside the bootstrap closure.

Executing Core JS additionally assumes or proves refinement through PSC elaboration/erasure/IR, TS emission, TS7 translation, runtime representations, Node/V8, codec and host transaction. Source kernel proofs alone do not establish that executable's answers. Native/JS comparison supplies independent bounded evidence, not universal equivalence; shared compiler production makes common failures worth considering.

Logical consistency, compiler correctness, generated-kernel behavior and a joint compiler/kernel fixed point are distinct claims. Preserve the selected seed and current compiler evidence. Full formal assurance remains a later gate for stronger claims; mandatory admission and runtime-validation gates apply immediately.

## 6. Reproduction and retained result

The [manual/scoped workflow][J4], [probe script][J5] and [portable fixture][J6] are development evidence tools, outside the installed runtime and compiler closure. J0 uses a 35-minute job bound and a 20-minute generation-step bound. No kernel/compiler/provider implementation or release default changed.

- Initial refusal: [run 38006611207][J7].
- Diagnostic harness correction: run 38006933737 assumed an unavailable structure-constructor export; it did not change acceptance expectations.
- Final exact declaration diagnosis: [run 38007233891][J1], job `114078714365`.
- [Artifact 11651433881][J8], 9,415 bytes, ZIP SHA-256 `681568a386b61cca5f024b812cab135263a36dc9622472d6e043da1050188c10`.
- Artifact expiry: **9 November 2026, 07:04 Jakarta**. This document preserves the finding; the artifact's full file inventory and evidence require durable retention if needed beyond that date.

[H1]: https://github.com/dwijayuda/pskernel/actions/runs/37333010780
[H2]: https://github.com/dwijayuda/pskernel/blob/4265f1d614d15fc9e6ed133a923779ba7af16db8/psc0/packages/pskernel-core/SELFHOST_EVIDENCE.json
[J1]: https://github.com/dwijayuda/pskernel/actions/runs/38007233891
[J2]: https://github.com/dwijayuda/pskernel/blob/963030dc2d154008fccc82e7c8ed29331f138799/psc0/packages/pskernel-core/src/Ps/KernelCore/Checker/State.lean#L163-L175
[J3]: https://github.com/dwijayuda/pskernel/blob/4265f1d614d15fc9e6ed133a923779ba7af16db8/psc0/packages/elab/src/Ps/Elab/Term.lean
[J4]: https://github.com/dwijayuda/pskernel/blob/b94a6c552d8cc208ce2202527f7f30e28e8836ee/.github/workflows/psc0-kernel-js-probe.yml
[J5]: https://github.com/dwijayuda/pskernel/blob/b94a6c552d8cc208ce2202527f7f30e28e8836ee/psc0/scripts/kernel-js-probe.mjs
[J6]: https://github.com/dwijayuda/pskernel/blob/b94a6c552d8cc208ce2202527f7f30e28e8836ee/psc0/test/fixtures/KernelJsProbe.lean
[J7]: https://github.com/dwijayuda/pskernel/actions/runs/38006611207
[J8]: https://github.com/dwijayuda/pskernel/actions/runs/38007233891/artifacts/11651433881
