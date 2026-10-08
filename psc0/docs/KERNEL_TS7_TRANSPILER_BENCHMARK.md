# PSC0 Kernel TypeScript 7.0.2 / Bun / esbuild Performance Experiment

Status: experimental and non-authoritative. No default compiler, pinned
TypeScript 5.8.3 dependency, or checked self-host trust boundary is changed.

## Why this experiment exists

The verified 79-module PSKernel Core source produced a 4,229,736-byte
TypeScript file and 25,687,766 bytes of canonical admissions in
[GitHub Actions #37846234332](https://github.com/dwijayuda/pskernel/actions/runs/37846234332).
Its Lean-native PSC0 seed prepared the input in ~208s; native PSKernel Core
accepted it in ~2.7s. TypeScript 5.8.3 then hit its independent 120s
subprocess limit. The older generated-JavaScript PSC0 compiler lane also
takes tens of minutes before the TypeScript step, which this experiment does
not fix.

TypeScript 7.0.2 is the official stable native Go compiler, released in 2026.
Microsoft's independent workload comparisons typically show 8-12x faster
full builds, but a single huge generated PSC0 kernel can have different
type-checker complexity. Real measurements are required. References:
- https://devblogs.microsoft.com/typescript/announcing-typescript-7-0/
- https://www.npmjs.com/package/typescript

## Separate cloud-only experiment

Branch: psc0/kernel-fast-transpilers-v1 (based on PR #85).

Workflow: .github/workflows/psc0-kernel-fast-transpilers.yml

1. Verify original 55-module compiler source and 79-module kernel source
   closures. Build native PSC0 seed and native PSKernel Core checker on
   GitHub Actions only.
2. Emit *only* the complete 79-module kernel TypeScript source, after
   receiving fresh PSKernel Core acceptance of all canonical admissions.
   Preserve the distinct `psc2-checked-typescript` source receipt,
   TypeScript bytes and canonical admission stream as a single artifact.
3. Install **TypeScript 7.0.2** in an isolated toolchain; type-check under
   strict ES2022 ESM settings, generate JS, source map and declarations,
   then execute the existing independent generated-kernel smoke suite.
   Record wall clock, maximum resident memory, diagnostics and hashes.
4. Only after that TypeScript 7 strict check succeeds, independently
   transpile *the exact same checked source bytes* using esbuild and Bun,
   smoke test the JS outputs, record time/memory/hash. esbuild/Bun do not
   satisfy strict type checking on their own.
5. Keep all reports explicitly non-authoritative until independent
   kernel/conformance parity and reproducible compiler fixed points pass.

The benchmark does not silently use TS7 output in existing `buildChecked`
or set a generated kernel to "checked" merely from fast transpilation.
Different transpilers may yield different JavaScript bytes. Those differences
need not imply semantic inequality, but they prevent an existing byte-level
fixed-point contract from being reused unchanged.

## Decision criteria

A TypeScript 7 migration into a **separately reviewed follow-up** is
recommended only if: strict type checking succeeds, checked TypeScript inputs
are unchanged, generated kernel smoke passes, performance is materially
better, typechecking and emission contracts are specified, and full PSC0
compiler/self-host and negative-conformance suites pass under an
explicitly versioned TS7 identity. The historical TypeScript 5.8.3 baseline
remains independently reproducible. Do not re-label TS7-generated JavaScript
as matching an older TS5.8.3 artifact based on semantic similarity alone.

If TS7 remains slow, profile its `--extendedDiagnostics` and `--checkers`
performance before considering a module-split backend. Source partitioning
must preserve topological declaration order, canonical admissions, runtime
exports, and independent strict checking.

No proof, metatheory, or native kernel semantics are edited by this experiment.
