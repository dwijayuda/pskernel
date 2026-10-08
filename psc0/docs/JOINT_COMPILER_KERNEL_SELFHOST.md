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
3. Use the generated PSC0 compiler to elaborate that kernel source and
   use the native PSKernel Core checker to admit the canonical declarations
   before emitting TypeScript and JavaScript.
4. Exercise the generated JavaScript kernel's foundation, WHNF, defeq,
   inductive, nested, mutual and duplicate-rejection smoke corpus.
5. Re-emit the kernel's ProofScript source from the generated compiler,
   compare the canonical source closure, then compile and check the
   emitted kernel again.
6. Compare both checked kernel artifacts and record all source, compiler,
   native checker and generated artifact digests.

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
PSKernel Core, and TypeScript 5.8.3 compiles the generated TypeScript to JS.
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
