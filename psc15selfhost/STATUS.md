# PSC2 minimal self-host status

Status (2026-10-04): the project uses a **compiler-only bootstrap**. The generated
compiler closure contains **55 source modules** and no kernel package.

The active compiler source profile is now machine-enforced as `PSC1-selfhost-stable/1`.
Every bootstrap change is expected to pass the static profile, the whole-closure
Lean→PSC executable contract, and the generated-compiler fixed point. The generic
contract freezes the historical set of 75 one-off self-host repair guards: it may
shrink, but new repair-guard names are rejected. Future self-host failures must become
profile/contract invariants rather than new per-file repair tests. See `docs/SELFHOST_SOURCE_STANDARD.md`.

The compiler development policy is **self-hosted JS first**: after the one-time Lean
bootstrap exists, normal `psc`/`build:auto`/self-host guards use the generated
JavaScript compiler. Native Lean `psc` remains the seed/reference/recovery compiler.
The checked-kernel policy remains native-first:

- **default checked kernel:** `lean434` / `@proofscript/pskernel-lean`;
- portable alternative: `lean434-wasm`;
- experimental owned alternative: `pskernel-core`;
- TypeScript backend compiler: **TypeScript 7.0.2**;
- native PSC executable: Lean 4.34-built `psc`.

The last fully recorded compiler fixed point predates the TypeScript 7 migration and
used TypeScript 5.8.3. Its canonical source closure remains:

```text
55 modules
ee6dd22f1b74b97113cc1a5e36aadad3cceecb2b152653f2c0dc26dd07aa22f7
```

TypeScript 7.0.2 migration smoke tests pass, including a Lean-built native `psc`
compiling `.ps -> .ts -> .js/.d.ts/.js.map`.

The current Windows x64 native bundle contains:

- `psc.exe`: 5,795,328 bytes;
- `pskernel-lean.exe`: 6,029,824 bytes;
- TypeScript 7.0.2 native `tsc.exe`: 24,520,544 bytes;
- the TypeScript standard-library declarations required by native `tsc`.

The bundle works with Node removed from PATH: native `psc build` auto-detects the
sibling native TypeScript compiler and reports `PSC2_TYPESCRIPT: 7.0.2`.

The current-semantic slim native kernel accepts the preserved 55-module /
1,916-declaration compiler admissions. WASM remains available only when explicitly
selected; no failure causes automatic provider fallback.

The committed five-platform `pskernel-lean` npm prebuilts have not yet all been
regenerated from the refreshed provider snapshot. Therefore the default checked source
path deliberately requires a freshly built native provider or
`PSC_LEAN_KERNEL_PROVIDER_BIN` rather than silently using those older package
prebuilts.

Remaining release evidence:

1. rerun the complete compiler fixed point under TypeScript 7.0.2;
2. rerun bootstrap/selfhost/repeat with the new native default kernel;
3. regenerate and verify all five slim native kernel prebuilts;
4. produce platform-native PSC toolchain bundles for the supported target matrix.
