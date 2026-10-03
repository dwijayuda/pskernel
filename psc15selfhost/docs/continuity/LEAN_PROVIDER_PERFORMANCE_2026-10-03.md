# Lean provider size/performance checkpoint — 2026-10-03

Base branch: `psc2/selfhost-lean-kernel` at `d4298a712d1e2ea6505185d311e9af10a698b2ca`.

This checkpoint refreshes the native `@proofscript/pskernel-lean` source closure to
the semantic snapshot already used by the working `@proofscript/pskernel-lean-wasm`
provider, ports the previously proven slim-native link, and measures the two execution
mechanisms on the compiler fixed-point admissions.

## Semantic source identity

The native package now carries the same Foundation/Core/Environment/Bridge/provider
snapshot used by the WASM package:

- source revision: `1b21b2483df7e8de7542873c24eaff2501539b1b`
- native source tree: `894b30c91a6a1733cfbfee275b2d68c661c18aa7`
- Foundation: `5cb363c31d7cec6dece85cb6178c0518f409f172`
- Core: `f7fd0326588d4028a952f832c4de03364905668c`
- Environment: `f80bc27eddcc35a712feee0b173abf5e7cdf3e5f`
- Bridge: `bff9e1f815ed9cacc8f0e1d005936d6a8dec41f3`
- provider: `694e217dc9f69f8cc0c417266298078b181f842d`

Lean remains pinned to 4.34.0 commit
`293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`.

## Slim native construction

`scripts/build-native-slim.mjs` emits C for the exact 19-module provider closure,
compiles only those modules, supplies a minimal Lean initializer, removes `-lLake`
from Lean's default user link, and links with `-Os -DNDEBUG` by default. Optional
`PSC_LEAN_NATIVE_OPT=-O2|-O3` exists for controlled benchmarking.

On Windows x64:

- conventional package-local Lake executable: **110,671,360 bytes**
- current slim `-Os` executable: **6,029,824 bytes**
- reduction versus conventional executable: **94.55%**
- reduction versus the previously committed 76,361,216-byte native prebuilt:
  **92.10%**
- current WASM module: **2,177,471 bytes**
- current WASM launcher: **69,410 bytes**

The slim Windows executable is about 2.68x the combined WASM module+launcher size,
while remaining small enough for ordinary npm distribution.

An `-O2` experiment produced 6,050,304 bytes and did not materially improve the
representative compiler-check runtime, so `-Os` remains the default.

## Semantic validation

The package-local conventional provider built successfully (40/40 Lake jobs).

The default slim source build passed its health, positive admission and real
kernel-rejection checks.

`native-slim-differential.test.mjs` reports:

```text
PSC2_LEAN_KERNEL_NATIVE_SLIM_DIFFERENTIAL: PASS
```

covering health, valid admission, kernel rejection, and malformed input against the
conventional provider built from the same source snapshot.

The exact current compiler admissions file is 9,976,683 bytes and represents the
55-module / 1,916-declaration compiler fixed-point closure. Conventional native,
slim native, and current WASM all accepted this input.

## Performance measurements

Measurements were made as cold provider processes on the same Windows host. These are
engineering measurements, not a cross-machine performance guarantee.

Representative full compiler closure (three slim and three WASM runs):

| Provider | Median |
| --- | ---: |
| slim native `-Os` | **1,904.34 ms** |
| Lean WASM | **4,242.92 ms** |

Median native speedup: **2.23x**.

The conventional native reference accepted the same full input in **1,777.25 ms** in
the recorded run.

A tiny one-declaration cold-check benchmark (eight runs each) measured:

| Provider | Median |
| --- | ---: |
| slim native | **103.52 ms** |
| Lean WASM | **491.56 ms** |

Median native speedup on the tiny check: **4.75x**.

A separate three-run `-O2` full-closure experiment measured approximately the same
native runtime and therefore does not justify its slightly larger binary.

## Default-provider decision

The requested switch criterion is native being proven at least **6x faster** than
WASM. Neither the representative full compiler closure (2.23x) nor the current tiny
cold check (4.75x) meets that threshold.

Therefore **`lean434-wasm` remains the default checked provider**.
`lean434` remains the faster native option for users/CI that prefer throughput over
single-artifact portability.

No result in this checkpoint changes compiler semantics or puts either kernel package
inside the 55-module compiler bootstrap closure.

## Distribution status

This commit updates the reproducible native source/build path only. The committed
five-platform `PREBUILT_MANIFEST.json` and binaries are intentionally not partially
replaced from one Windows build. A separate verified five-runner matrix must regenerate
all native targets from this exact semantic snapshot before those distribution bytes
are promoted.
