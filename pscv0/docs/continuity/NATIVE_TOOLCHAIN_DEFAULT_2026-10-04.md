# Native PSC toolchain and native-default Lean kernel — 2026-10-04

Base commit: `b4d8d875ebaf578cac1fff96fe2cc3d42c8fc6e3`.

## Decision

The checked compiler profile now defaults to native `@proofscript/pskernel-lean`
(selector `lean434`). The WASM provider remains an explicit portable alternative:

```text
--kernel lean434
--kernel lean434-wasm
--kernel pskernel-core
```

There is no automatic fallback between these providers.

The earlier performance checkpoint retained WASM by a user-specified 6x switching
threshold. This checkpoint supersedes that default-provider choice by explicit user
direction to make the native provider the default.

## Current-semantic native kernel

The slim provider was rebuilt from the current ProofScript provider snapshot:

```text
ProofScript source revision:
1b21b2483df7e8de7542873c24eaff2501539b1b

Lean:
4.34.0
293d5d0c0c3f3dded4688b3ccd6a33939ac5102b

Windows x64 slim provider:
6,029,824 bytes
```

It accepted the exact preserved compiler admissions representing the 55-module /
1,916-declaration compiler closure:

```json
{"protocol":"pskernel-lean/1","provider":"lean4-cpp","leanVersion":"4.34.0","profile":"lean4.34-core","accepted":true}
```

## Native PSC + native TypeScript

The production-named `psc` executable is built directly by Lean 4.34. The native
host now resolves TypeScript in this order:

1. explicit `PSC_TYPESCRIPT_NATIVE_TSC`;
2. a sibling bundle at `../typescript/lib/tsc[.exe]` relative to `psc`;
3. the pinned npm `typescript/bin/tsc` launcher as a development fallback.

All routes require exactly TypeScript **7.0.2**.

The platform-native TypeScript executable was validated directly:

```text
typescript/lib/tsc.exe --version
Version 7.0.2
```

## Native toolchain bundle

`scripts/build-native-toolchain-bundle.mjs` assembles one platform at a time under:

```text
dist/native-toolchain/<platform>-<arch>/
```

The Windows x64 bundle contains:

```text
bin/psc.exe                  5,795,328 bytes
bin/pskernel-lean.exe        6,029,824 bytes
typescript/lib/tsc.exe      24,520,544 bytes
typescript/lib/lib*.d.ts     TypeScript standard libraries
TOOLCHAIN.json               pinned identities and key SHA-256 digests
FILES.json                   per-file digest inventory
licenses/                    Lean and TypeScript licensing files
```

The bundle was tested from a temporary directory with Node removed from PATH:

```text
psc.exe build example.ps --out example.js
PSC2_TYPESCRIPT: 7.0.2
exit 0
```

The same bundle reports a healthy native kernel and TypeScript compiler.

## Default-provider safety rule

The repository still carries older committed multi-platform native package prebuilts.
They are not silently used by the new default checked profile. The default native path
requires one of:

- the current `lean-checked` native provider;
- the current slim provider under `packages/pskernel-lean/.lake/build/bin`;
- explicit `PSC_LEAN_KERNEL_PROVIDER_BIN`.

This keeps the native-default switch fail-closed until all five package prebuilts have
been regenerated from the current source snapshot.

## Next evidence

- complete TypeScript 7 compiler fixed point;
- complete native-default checked fixed point;
- five-platform slim kernel prebuilt regeneration;
- five-platform native toolchain bundle matrix.
