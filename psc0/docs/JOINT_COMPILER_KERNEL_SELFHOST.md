# PSC0 joint compiler–kernel self-host v1

Status: **implementation candidate; generated-kernel checker promotion is not yet established**.

## Starting point

The source base is the successful native-core compiler-only fixed point at
commit 963030dc2d154008fccc82e7c8ed29331f138799.
GitHub Actions run 37825822957 passed: the 55-module compiler generated
matching bootstrap, selfhost, and repeat generations, checked by native
PSKernel Core. This is not by itself a kernel self-host result.

## Kernel closure

Entry: packages/pskernel-core/src/Ps/KernelCore/SelfHost.lean.

joint-kernel-closure.mjs follows implementation source imports, detects
cycles and missing files, verifies all implementation modules are reachable,
hashes exact source bytes, rejects paths outside the implementation tree, and
excludes the upstream proof and metatheory directories. A PSKernel Core
source entry does not join or change the historical 55-module compiler closure.

workspace-layout.mjs now knows the KernelCore namespace. This adds source
discovery for the separate, optional kernel-generation pipeline only.

## Kernel generation experiment

Command from psc0/: npm run joint:kernel

1. Require an unchanged historical compiler source baseline and validate the
   checked compiler artifact's source count, TypeScript/JavaScript/admissions
   digests and PSKernel Core provider identity.
2. Recreate the current kernel's canonical ProofScript source workspace
   using the real PSC1 Lean->ProofScript translator, excluding proof/metatheory.
3. Build the full strictly typechecked native-PSC0 reference executable
   using pinned TypeScript 7.0.2 and native PSKernel Core checking. Preserve
   actual source TS, output JS, canonical admissions and the checked receipt.
4. Execute the PSC0-generated JavaScript compiler on the separately
   translated kernel source. It must elaborate every module and obtain fresh
   native PSKernel Core acceptance before emitting only checked TS source.
   The source-only receipt is a distinct non-executable record.
5. Require byte-identical emitted TS and canonical admissions between native
   and generated-compiler paths before reusing the already strictly compiled
   JS bytes. Any mismatch is a failure, never a native fallback.
6. Re-emit kernel source from the generated compiler, compare the full source
   closure, repeat generation and verify both TS and admissions equality.
7. Run executable generated-kernel smoke tests and record provenance, all
   content hashes and explicit pending joint checker acceptance claims.

Cache reuse is keyed to exact compiler, source, provider binary and profile
identity. Every reused checked artifact is separately checked against its
stored content hashes. This is an integrity check, not a transferable proof
certificate. Changed implementation source invalidates the cache.

## Stronger joint checker acceptance is separate

Even a successful kernel code-generation fixed point does not prove that the
generated JavaScript kernel can act as the trusted checker of the compiler.
A later promotion gate must additionally:

- provide a generated-JavaScript PSKernel Core provider for canonical
  admissions, with a checked and reproducible prelude;
- run independent native-versus-generated kernel differential conformance;
- successfully check the exact 55-module compiler admissions stream with the
  generated kernel, with finite declared resource limits and no fallbacks;
- close repeated joint kernel/compiler generation and record release evidence.

For this reason, the evidence explicitly writes generatedKernelAdmitsCompiler
and jointCheckerFixedPoint as false until the separate stronger gate exists.
Do not claim full joint self-host from a source-artifact equality result alone.

## Efficient validation

Run npm run joint:preflight to perform cheap exact source-closure checks.
The new cloud workflow separates the source-profile check from expensive
checked generation, supports Lake cache restoration, and leaves
proof/metatheory entirely outside runtime build targets.

Lean 4.34 remains the initial native compiler/runtime used for bootstrapping
PSKernel Core, and TypeScript 7.0.2 compiles the generated TypeScript to JS.
Native PSKernel Core remains the selected development checker. The generated
JS kernel is a separate execution/compatibility workstream.

Full assurance still requires an independent kernel soundness argument and
the compiler's semantic preservation evidence; fixed-point equality is
neither one on its own.

## Generated-JS kernel provider candidate

The `scripts/generated-core-provider.mjs` adapter independently decodes the
canonical proofscript-checked-admissions version-2 wire into the generated
PSKernel Core JS ADTs. It checks BigInt literals, exact structured names,
universe levels, binders and inductive declaration structure and rejects
unsupported forms rather than admitting them. A host-side Lean inventory
preserves the exact prelude structured names, and the generated checker replays
the prelude from an empty PSKernel session with no fallback.

The candidate is **non-authoritative** until its actual execution passes
differential evidence and the full compiler admissions replay. A small unit
suite runs independently of the expensive bootstrap; it does not itself show
kernel semantic parity.

After a successful `npm run joint:kernel`, execute
`npm run joint:verify-generated` to check that the generated JS kernel
replays the actual 55-module compiler canonical admissions under a bounded
subprocess and memory policy. That gate records
`generatedKernelAdmitsCompiler=true` only on genuine acceptance; it retains
`jointCheckerFixedPoint=false` until the final compiler+kernel repeat cycle.

### Triggering expensive GitHub CI only when requested

The PR runs the source-contract checks on ordinary edits and preserves the
baseline. Its time-intensive generation and generated-checker replay run only
on `workflow_dispatch` or the explicit `enhancement` PR-label event. This
prevents a 26-minute compiler bootstrap plus kernel generation being repeated
just because unrelated files are edited.

## Fast native kernel generation

`npm run joint:native` builds the 79-module KernelCore implementation using
the **Lean-native execution of PSC0's compiler source**, with canonical
admissions checked by native PSKernel Core, then generates TypeScript and
JavaScript and runs the independent generated-kernel runtime smoke tests.

This isolates two different costs and guarantees:

- **Native PSC0 compiler → checked JavaScript kernel** proves that the
  compiled PSC0 frontend can handle its kernel implementation; it is the
  efficient build/development path.
- **PSC0-generated JavaScript compiler → checked JavaScript kernel** is the
  stronger self-host source-emission test, which remains separate and may be
  much slower.

The native path records `generatedCompilerSelfhost=false` and
`jointCheckerFixedPoint=false`; do not misreport the native compiler as
having been compiled by PSC0 itself. The stronger generated-JS checker must
still accept the compiler and pass the repeated-generation contract.

Cached source and output receipts are never accepted as kernel-check
authorization merely because their SHA values match. The current selected
native PSKernel Core rechecks cached compiler canonical admissions before
they can be used for new checked artifact production.

The deliberate GitHub full-certification event runs both the fast native
kernel-generation lane and the slower generated-compiler/kernel lane, while
routine PR edits run lightweight profile and wire checks only.

## TypeScript timeout diagnosis and no-duplicate-tsc staging (2026-10-09)

Run: https://github.com/dwijayuda/pskernel/actions/runs/37834917811

The native-PSC0 kernel build and its generated JS runtime smoke passed.
The generated-JS compiler then spent roughly 50 minutes on the complete
79-module compiler workload before a second TypeScript compilation reached
its separate 120-second subprocess timeout. The slow JS compiler preparation
and the eventual TypeScript timeout are distinct performance problems.

A new buildChecked emission mode named 'typescript-only' preserves the
same mandatory native PSKernel Core canonical-admissions check and emits an
atomic TS source, admissions stream and 'psc2-checked-typescript' audit
receipt, with NO JavaScript. An existing sibling JS file is forbidden.
The usual full checked-build mode, strict TypeScript checking, and 120-second
timeout remain unchanged. PSC0_BUILD_TRACE=1 records elapsed times and sizes
at source-snapshot, generated preparation, admissions check, TS emission
and tsc boundaries.

The joint workflow builds the full native reference and strictly compiles its
TypeScript ONCE with pinned tsc. The generated JS compiler must independently
produce the exact same TS bytes and exact same admissions bytes under a fresh
kernel check. Only with both matching can it associate that single full
reference compilation's JS with the independently generated source.
A distinct provenance string records this optimization. No receipt or hash
alone is checking authority; cache reuse replays current native checking.

Remaining issue: TypeScript-only emission removes the second tsc cost but
DOES NOT solve the approximately 50-minute generated-JS frontend runtime.
A follow-up architectural profiler should diagnose its actual preparation,
checker and erasure/emission timing separately, not patch individual tests.
The generated JS kernel's independent full compiler checking and repeated
joint fixed point are still separate mandatory acceptance gates.

## Mandatory TS7.0.2 toolchain cutover (2026-10-09)

The active PSC0 workspace now uses exactly TypeScript 7.0.2 as its
TypeScript-to-JavaScript toolchain. The earlier JavaScript output hashes
are historical observations, not matching-current-toolchain evidence.
No dual TypeScript compiler path or fallback is retained. Both the native
PSC0 host and the generated-compiler/checked-build host enforce the exact
TS7 version and pass '--ignoreConfig' for explicitly named .ts files.
Checked full-emission and TypeScript-source receipts include a structured
TS7 toolchain identity, and consumers require it. The kernel admission
check remains prior to all executable output. Repeat-generation JS fixed
points must be regenerated and validated with the new compiler, not assumed
from their unchanged TypeScript source hashes.

Evidence: PR #86, Actions #37851336504: strict native TypeScript 7.0.2
accepted the actual 79-module generated kernel TypeScript and emitted a
runnable JS kernel in 23.279 seconds (429 MiB peak RSS), versus an older
TypeScript compile exceeding a 120-second time limit on the same source.
The independent generated-JS PSC0 compiler remains a separate performance
and correctness gate, and joint checker promotion is not implied.
