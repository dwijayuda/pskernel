# TypeScript 7-only development

The user has retired TypeScript 5 from future development. The current PSC0
profile accepts **TypeScript 7.0.2 only**, and positional compilation always
uses `--ignoreConfig`. Current tooling has no supported TypeScript 5 fallback.

**Qualification status: passed.** The current twelve-worker F compiler migration
passed C1/C2/C3, all four fixed-point products, the twelve Core/IR ABI checks,
87-case behavior correspondence and independent provider acceptance in
[run 37947341800](https://github.com/dwijayuda/pskernel/actions/runs/37947341800).
TypeScript 7-only native selected-R recovery and the separate root workspace
qualification also passed, with exact evidence retained below. R remains the
selected authoring compiler; this source migration does not select F.

The [current implementation guide](CURRENT.md) identifies the selected compiler
and finite source migration. The [evidence ledger](qualification-evidence.json)
records actual successful and failed runs without treating source changes as proof.

## Current toolchain and source contract

| Component | Current contract |
| --- | --- |
| TypeScript compiler | Exactly 7.0.2; installed package `bin.tsc` launched through Node |
| Node runtime | 22.23.3 |
| Native Lean toolchain | 4.34.0 |
| Authored compiler source | The existing 61-module handwritten `.lean` closure |
| Current `.ps` grammar | `ps-0.9-r3/new-only/bounded-selfhost-subset` |
| Selected authoring compiler | Qualified R, source `fe2560aba0f347b1caf8d000d371464642d44f23` |
| Strict SH/1, full Standard and PSCV | Not activated or claimed |

Changing the TypeScript executable changes the final host compilation stage.
It does not expand the PSC parser, elaborator, recursion normalizer or runtime
coverage. The practical self-host authoring subset remains the finite language
documented in [SPEC.md](SPEC.md) and [IMPLEMENTATION.md](IMPLEMENTATION.md).

## One supported installed compiler

The JavaScript locator and native host share one version contract:

- `PSC0_TYPESCRIPT_VERSION` defaults to `7.0.2`. Any other value is refused,
  including `5.8.3`; refusal occurs before launcher resolution.
- `PSC0_TSC`, when supplied, must identify the absolute installed JavaScript
  launcher declared by the TypeScript package. Invalid explicit selections fail.
- Discovery uses installed package metadata. A shell shim or bare native binary
  is not the package launcher.
- Callers require the selected launcher to report `Version 7.0.2` before
  compilation.
- Positional builds always receive `--ignoreConfig`, explicit target/module
  and resolution settings, and the existing strict/declaration/source-map flags.

The installed-profile gate verifies the package, exact native platform
dependency and executable, authoritative selection failures, and positional
compilation from an unrelated project directory. The native host test keeps a
real wrong-version rejection check using a tiny package-shaped version reporter;
it does not install an old compiler. Existing generated runtime and erasure-index
fixtures use the single current profile.

CI installs only `typescript@7.0.2` for these paths. The old repeated full-source
TypeScript 5/7 comparison has been removed. Its completed measurements remain
historical observations in [TYPESCRIPT7_CHECKPOINT.md](TYPESCRIPT7_CHECKPOINT.md)
and the original receipts.

## Recovery without TypeScript 5

The immutable selected R manifest remains `selfhost-seed.json`, with identity
`47d88158e075f766f0d146ba3a13b28744c6e196d9844c71f4e52dc7351e2225`.
It records how that seed was originally qualified and recovered. Historical
producer facts remain part of its identity; they do not require the current
workflow to execute that old recipe.

The additional `selfhost-seed-recovery.json` policy pins the current native
recovery runner, its complete imported repository dependency set, the selected
manifest bytes, source closure and exact toolchain. It defines a separate
execution recipe while preserving the selected seed identity.

The current native route performs these steps:

1. Authenticate the policy, runner files and selected manifest before importing
   repository helpers or executing a compiler.
2. Check out pinned R source separately. For the independent cold proof, require
   its native build directory, source seed cache, source dependency directory and
   destination seed cache to be absent.
3. Build the native compiler and original-IR checker with Lean 4.34.0.
4. Prepare the ordered raw Lean closure, check its original IR and emit that same
   IR to TypeScript. Compile with exactly TypeScript 7.0.2.
5. Obtain native canonical admissions and native translations of all 61 modules.
   Preserve the exact printer text and canonical JSON serialization.
6. Compare all four final products against the selected manifest before
   materializing and verifying its cache.

| Product | Selected R SHA-256 |
| --- | --- |
| Canonical `.ps` source JSON | `985cf39d4a68df68a03123883105b6bdd9b81783c4bab98c8ec86ec683ac3b07` |
| Canonical admissions | `200e5881d1554f72530a0395524ee28dd3a64a6bd45f55cddd4fad1336981bf0` |
| TypeScript | `38fea23209f561efcab0c0111a2a15fa1e5761d33f31100fac8d6bfb1e032935` |
| JavaScript | `70db0131fa3af62f7193576407ad529be10df2f4296c712f53f7c31f42209061` |

The runner does not start the generated compiler, historical parent compiler or
TypeScript 5. Its original-IR result is distinct from provider acceptance. R's
previous provider acceptance remains a separately recorded fact.

The current `sh1-qualify.mjs` rejects `seed-identity`, `recover-seed`,
`recover-qualified-seed` and `recover-successor-seed` before TypeScript launcher
resolution. Those commands belong to their archived source revisions. Current
cache-miss recovery uses `sh1-native-seed-recovery.mjs`.

### Independent cold proof

[Run 37947341899](https://github.com/dwijayuda/pskernel/actions/runs/37947341899),
job **113876930974**, passed for runner source
`fcd875c8f38db4b0524090bd10c7c2fd5024053d`. The standalone job restored no
compiler artifact, seed cache or native build cache. Every one of its **75
recorded commands** succeeded, including native translation of all **61**
modules. All four selected-R hashes above matched; tracked source, closure and
selected manifest were unchanged.

The original IR check accepted **56,391 expressions**, visited **725,484
steps**, and reported **zero findings** before that same IR was emitted.
No generated compiler, historical parent compiler or TypeScript 5 was executed.
The recipe is `native-lean-original-ir-four-products-ts7/1`, with recipe SHA-256
`4ed186c2604bcfaee756881686e70f14569720d72fcd799d9997d2d92217b82a`
and policy SHA-256
`0cf0480524ba713e0bcdbeb3cfa3d345e37508743ee5e169b83ba8ee0de160fc`.

| Retained proof | Identity |
| --- | --- |
| [Exact native recovery receipt](typescript7-native-recovery.json) | 64,164 UTF-8 bytes; SHA-256 `0d5606c25e634082da39d80ffa5974b3c390d2765ded71bcf1abaf442b7e3919` |
| [Independent evidence and provenance](typescript7-native-recovery-evidence.json) | Exact completed run/jobs, policy, command and four-product bindings |
| [Complete decoded job log](evidence-logs/typescript7-native-recovery.log) | SHA-256 `6f47360b88446d7a06f12561772e8d9e317b1f3bfb6d34d610791436f99b3957` |
| Uploaded artifact | 11624048503; ZIP SHA-256 `967adc94a58d02e4e166e24601252f177a372dc5e6fd50ba01a7125cec9dfae5` |

Recorded recovery work took **86.497 seconds**; the complete job took **158
seconds**. Native build recorded 17.998 seconds, checked original-IR emission
59.859 seconds, the TypeScript phase 1.674 seconds and native admissions 3.486
seconds. These figures describe this run. The older parent-based recipe recorded
2,728.787 seconds in a different run using a different route; the two runs are
not a controlled compiler benchmark.

This proof qualifies the replacement recovery route for the existing selected
R. It neither selects F as a new seed nor substitutes for independent provider
acceptance of a newly qualified compiler.

## Efficient daily development

From `psc0`:

```sh
npm install
npm run check:typescript-profile
npm run dev:sh1
```

`dev:sh1` builds the required native targets and runs the bounded current-source
development gate. Use the resident preparation loop for repeated edits after
that gate produces N1:

```sh
PSC0_ITERATION_SHA256="$(node -p "require('./dist/sh1/N1/receipt.json').artifacts.javascriptSha256")"
npm run iterate:sh1 -- --compiler dist/sh1/N1/index.js --compiler-sha256 "$PSC0_ITERATION_SHA256" --loop
```

The loop retains preparation state and invalidates the affected suffix after a
module changes. Restart it when the compiler changes. Its `emit` command emits
TypeScript; it is not the full compiler fixed-point or independent provider gate.

For a coherent semantic checkpoint, CI runs the cheap authenticated-R behavior
and isolated ABI probe before N1, then the existing selected-seed C1 and current
C2/C3 qualification with all four products, actual current Core/IR ABI, behavior
correspondence and separate provider acceptance. Native selected-seed recovery
has its own independent cold proof. Ordinary edits should not repeat the full
qualification unless they change the qualified semantic or recovery contract.

## Root workspace: TypeScript 7-only qualification passed

The repository-root TypeScript workspace is distinct from `psc0`. All **21**
root and package compiler pins now require **7.0.2**, and the exact committed
npm lock contains that current compiler profile. The sole backend compiler-API
importer has been replaced by an installed TypeScript 7 CLI adapter. The remaining
older `selfhost` launchers likewise require 7.0.2 and use `--ignoreConfig`.

The adapter preserves the existing synchronous result contract, virtual source
content, logical diagnostic positions, module resolution and root
JavaScript/declaration/source-map products. It uses a unique sibling input and
private output directory, then removes its private files. Relative TypeScript
imports and package exports are qualified. Its supported input is an ordinary
`.ts` filename in an existing writable parent directory; original-basename
self references, declaration inputs, missing directories and unsupported
basename-dependent output are explicit refusals. It is not a general arbitrary
virtual-filesystem compiler host.

Ten unsupported `baseUrl` settings were removed while existing paths and
output layouts were preserved. Explicit Node type inputs cover the native CLI
adapter. A Lean exporter TypeScript declaration now describes its actual ignored
stdin; process behavior is unchanged. The package-map checker now enforces the
exact declared source language for all twenty packages, including the compiler's
existing mixed-source manifest.

[Root run 37951869293](https://github.com/dwijayuda/pskernel/actions/runs/37951869293),
job **113892421469**, passed at source
`9d150afbec1feda8c97058aa56aa5ab92347d96d`:

| Required root gate | Result |
| --- | --- |
| Clean installation from the committed lock | Passed; no lock regeneration |
| Root build | Passed |
| Ordered package tests | Passed, including all eleven adapter obligations |
| Conformance package build | Passed |
| Lean exporter package build | Passed |
| Package integration | Passed |
| Package map, source shape, editor and architecture checks | Passed |

The actual receipt spans 2026-10-09 15:27:57.441 through 15:28:22.403 UTC;
its seven command records total 24.845 seconds. It reports actual installed
TypeScript 7.0.2, Node v22.23.3 and `lockGenerated: false`. All 21 source,
lock and installed-profile bindings and all five original receipt files were
independently authenticated.

See the [exact root qualification](root-typescript7-qualification.json),
[complete provenance and attempts](root-typescript7-evidence.json),
[full decoded root log](evidence-logs/root-typescript7-qualification.log)
and [root development guide](../../../docs/TYPESCRIPT7.md). The exact
qualification file is 3,485 bytes with SHA-256
`a6f2b2e31ca61a8249954d43849bb622d01b876db7f8046a67353ce82e9de39a`.
The root gate does not execute a native bootstrap, Lean corpus or kernel oracle,
and adds no PSC0 fixed-point/provider or new seed-selection claim.

## Historical evidence

The [preserved original TypeScript 7 checkpoint guide](TYPESCRIPT7_CHECKPOINT.md)
contains the original package check, two-profile migration attempts, seed A
recovery, exact receipts and single-run measurements. The original source
revisions, manifests, logs and provider decisions are unchanged.

The measured direct TypeScript phase was a small part of the full generated
compiler pipeline. Preparation, admissions, erasure, IR checking and emission
have their own costs. Neither retiring TypeScript 5 nor removing its comparison
step establishes a measured speedup for those PSC phases.
