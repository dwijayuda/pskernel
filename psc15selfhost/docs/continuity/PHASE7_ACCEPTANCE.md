# PSC2 KernelCore Phase 7 Acceptance

Status: accepted

Date: 2026-09-27

Execution branch: `psc2/kernel-core-phase7-primitives-work`

Reviewed branch: `psc2/kernel-core-phase7-primitives`

Accepted implementation/assurance SHA:

```text
3a6611c63fa75f243960f3d6650265400eac1bf2
```

Exact acceptance evidence:

```text
GitHub Actions workflow: PSC2 minimal kernel
run: 36325642660
job: 108637778618
conclusion: success
Lean: 4.34.0
```

This acceptance record is intentionally committed after the exact tested implementation/assurance SHA. Its commit must be documentation-only relative to `3a6611c6...`.

## Accepted Phase 7 scope

Phase 7 adds PSC1-self-hostable Nat resource policy, the mandatory pure Nat primitive reduction slice, and configured resource propagation through the accepted semantic stack.

Trusted semantic additions:

```text
Ps.KernelCore.Resource
Ps.KernelCore.Primitive
```

Accepted mandatory primitive set:

```text
Nat.succ
Nat.add
Nat.sub
Nat.mul
Nat.pow
Nat.gcd
Nat.mod
Nat.div
Nat.beq
Nat.ble
```

The accepted resource configuration is:

```text
PsKernelCoreResourceConfig {
  maxNatSize : Nat
}
```

with the default `maxNatSize` corresponding to Lean 4.34's 128 MiB Nat limit for this explicitly covered resource surface.

Configured entry points are threaded through:

```text
Reduce -> Infer -> DefEq -> Check -> Admission
```

The accepted public pattern is `...WithResources` for explicit configuration while each pre-Phase-7 public API remains a default-resource wrapper. Existing APIs were not removed.

## Resource evidence

The exact acceptance run reports:

```text
PSC2_KERNEL_CORE_RESOURCE_PARITY: PASS
```

The Resource layer covers the selected Nat byte-size model, default limit, count-argument UInt32 bound and deterministic resource errors.

Execution exposed several PSC1-portability issues that were fixed without weakening the source gate:

- the first two-limb boundary fixture was corrected from `2^63` to `2^64`;
- trusted arithmetic was expressed through PSC1-supported named Nat operations rather than unsupported surface syntax;
- dynamic error construction uses the PSC1 bootstrap string append builtin `String.Internal.append`;
- giant decimal source numerals were replaced with equivalent constructions from small Nats after they caused the PSC1 bootstrap checker to overflow its stack.

The final Resource source passes the unchanged actual PSC1 self-host gate.

## Mandatory primitive evidence

The exact acceptance run reports:

```text
PSC2_KERNEL_CORE_PRIMITIVE_PARITY: PASS
```

The accepted pure primitive layer covers literal/`Nat.zero` recognition and the mandatory operations listed above, including:

- `Nat.succ` result construction and size checking;
- add/sub/mul resource checking;
- total bounded pow support with UInt32 exponent validation;
- gcd;
- `mod a 0 = a`;
- `div a 0 = 0`;
- `Nat.beq` and `Nat.ble` Boolean results;
- unknown operation / unsupported primitive shape remaining residual rather than claiming reduction;
- resource failure before accepting oversized computed Nat results on the tested surface.

`Ps.KernelCore.Primitive` is pure and does not import or call `Reduce`; operand normalization remains owned by the reducer.

## Configured integration evidence

The exact acceptance run reports:

```text
PSC2_KERNEL_CORE_RESOURCE_INTEGRATION: PASS
```

The integration fixture covers the configured resource path through the accepted layers, including direct primitive WHNF, beta/zeta/delta exposure, literal resource checking, primitive-aware DefEq, checked-expression propagation and declaration-admission propagation.

It also includes a nested tiny-resource regression intended to detect accidental fallback from a configured path to an old default-resource wrapper below Admission/Check/DefEq/WHNF.

Representative success and failure cases pin compatibility between the old APIs and their `WithResources psKernelCoreResourceConfigDefault` counterparts.

## Preserved semantic assurance

The exact accepted implementation/assurance SHA passed:

```text
PSC2_KERNEL_CORE_BOUNDARY: PASS
PSC2_KERNEL_CORE_NAME_PARITY: PASS
PSC2_KERNEL_CORE_LEVEL_PARITY: PASS
PSC2_KERNEL_CORE_EXPR_PARITY: PASS
PSC2_KERNEL_CORE_SUBST_PARITY: PASS
PSC2_KERNEL_CORE_DECLARATION_PARITY: PASS
PSC2_KERNEL_CORE_ENVIRONMENT_PARITY: PASS
PSC2_KERNEL_CORE_LOCAL_CONTEXT_PARITY: PASS
PSC2_KERNEL_CORE_RESOURCE_PARITY: PASS
PSC2_KERNEL_CORE_PRIMITIVE_PARITY: PASS
PSC2_KERNEL_CORE_RESOURCE_INTEGRATION: PASS
PSC2_KERNEL_CORE_REDUCTION_PARITY: PASS
PSC2_KERNEL_CORE_INFER_PARITY: PASS
PSC2_KERNEL_CORE_DEFEQ_PARITY: PASS
PSC2_KERNEL_CORE_CHECK_PARITY: PASS
PSC2_KERNEL_CORE_CHECK_ORDERING: PASS
PSC2_KERNEL_CORE_ADMISSION_PARITY: PASS
PSC2_BOOTSTRAP_CLOSURE: PASS
KERNEL_CORE_SOURCE_PROFILE: PASS (16 PSC1-subset, self-host-checkable modules)
Phase 1 aggregate assurance: success
Phase 2 aggregate assurance: success
Phase 3 aggregate assurance: success
Phase 4 aggregate assurance: success
Phase 5 aggregate assurance: success
Phase 6 aggregate assurance: success
Phase 7 aggregate assurance: success
Existing PSC2 regression gate (`npm run check`): success
```

No Phase-1 through Phase-6 aggregate was weakened or redefined to make Phase 7 pass.

The compiler bootstrap closure remains isolated from `pskernel-core`; this phase does not make KernelCore the compiler's authoritative CheckedCore provider.

## Trusted source and PSC1 self-host evidence

The exact acceptance run reports:

```text
KERNEL_CORE_SOURCE_PROFILE: PASS (16 PSC1-subset, self-host-checkable modules)
```

Trusted files are the aggregate plus:

```text
Ps/KernelCore/Admission.lean
Ps/KernelCore/Check.lean
Ps/KernelCore/Data.lean
Ps/KernelCore/Declaration.lean
Ps/KernelCore/DefEq.lean
Ps/KernelCore/Environment.lean
Ps/KernelCore/Expr.lean
Ps/KernelCore/Infer.lean
Ps/KernelCore/Level.lean
Ps/KernelCore/LocalContext.lean
Ps/KernelCore/Name.lean
Ps/KernelCore/Primitive.lean
Ps/KernelCore/Reduce.lean
Ps/KernelCore/Resource.lean
Ps/KernelCore/Subst.lean
```

Every trusted closure was flattened and accepted by the actual PSC1 compiler. The source-profile restrictions and fail-closed timeout policy were not relaxed for Phase 7.

## Exact size evidence

From the exact accepted implementation/assurance SHA:

```text
KERNEL_CORE_SIZE_REPORT: PASS
KernelCore trusted .lean file count: 16
KernelCore trusted source bytes: 139953
KernelCore trusted nonblank/noncomment LOC: 3211
PSC1Kernel comparable .lean file count: 22
PSC1Kernel comparable semantic-source bytes: 306641
PSC1Kernel comparable nonblank/noncomment LOC: 7403
KernelCore/reference byte ratio: 0.4564
KernelCore/reference LOC ratio: 0.4337
```

Reference exclusions remain:

```text
Test/**
Replay.lean
ReplayJson.lean
NativeMap.lean
```

These ratios describe only the currently accepted semantic slice. They are not predictions of the final complete kernel size.

## Review/process evidence

The final whole-branch review was a self-review because this harness has no independent subagent-dispatch reviewer. It must not be represented as independent code review.

During execution another worker advanced the same Phase-7 work branch after the Resource checkpoint. That incoming implementation was reconciled rather than overwritten. Its Primitive and configured-resource work was checked against the approved Phase-7 specification/plan, then subjected to fresh exact-head CI and a whole-branch scope review.

The plan-head-to-accepted-head scope review found only the intended Phase-7 surface: Resource/Primitive, configured changes to Reduce/Infer/DefEq/Check/Admission, aggregate export, three Phase-7 tests, Lake/package/workflow wiring. No Quot, inductive/recursor, native, compiler/backend or unrelated source file was introduced.

## Allowed claims

After this acceptance it is valid to claim:

- KernelCore has a PSC1-self-hostable explicit Nat resource-policy layer for the tested Phase-7 surface.
- KernelCore has direct tested reduction semantics for the mandatory Phase-7 Nat primitive set listed above.
- configured `maxNatSize` propagates through the tested Reduce -> Infer -> DefEq -> Check -> Admission paths.
- existing semantic entry points remain default-resource wrappers and preserve their tested pre-Phase-7 behavior.
- all 16 trusted Phase-7 KernelCore `.lean` modules pass the actual PSC1 self-host checker.
- Phase-1 through Phase-7 assurance and the full existing repository regression are green on the exact accepted implementation/assurance SHA.

## Explicit non-claims

This acceptance must **not** be used to claim:

- Phase-7B `Nat.land`, `Nat.lor`, `Nat.xor`, `Nat.shiftLeft` or `Nat.shiftRight` support;
- complete Lean primitive reduction;
- exact Lean heartbeat or `maxRecDepth` accounting;
- native reduction or `eagerReduce`;
- string-literal constructor expansion;
- Quot admission or computation;
- inductive/constructor/recursor admission;
- strict positivity;
- iota reduction;
- projection computation;
- structure eta;
- mutual/nested inductive support;
- K7/K8 corpus parity through KernelCore;
- compiler CheckedCore provider cutover;
- replacement or removal of mature `PSC1Kernel`;
- full or formal equivalence to Lean 4.34;
- executable portable KernelCore fixed-point self-hosting;
- that the current size ratios predict the final kernel's size.

The strongest valid Phase-7 summary is:

> KernelCore now has PSC1-self-hostable Nat resource semantics and the mandatory Phase-7 Nat primitive reducer, with explicit resource configuration propagated through the accepted semantic stack and exact differential/self-host/regression evidence; bitwise/shift, Quot, inductive/recursor, native/corpus and compiler-cutover semantics remain separately gated.

## Recommended next slice

The approved roadmap leaves Phase 7B (`Nat.land`, `Nat.lor`, `Nat.xor`, `Nat.shiftLeft`, `Nat.shiftRight`) as its own next slice. It should remain separately gated and may not weaken PSC1 source acceptance. If Phase 7B is intentionally skipped, the next architectural dependency is the separately designed Quot phase.
