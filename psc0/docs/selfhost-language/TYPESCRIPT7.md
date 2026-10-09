# TypeScript 7-only development

The user has retired TypeScript 5 from future development. The current PSC0
profile accepts **TypeScript 7.0.2 only**, and positional compilation always
uses `--ignoreConfig`. Current tooling has no supported TypeScript 5 fallback.

**Qualification status:** the current-only PSC0 changes and native selected-R
recovery route are applied for cloud qualification. Their new full compiler
and independent cold-recovery evidence are pending. The separate repository-root
compiler-API adapter and workspace dependencies are a separate migration in
progress. These pending changes are not yet a repository-wide retirement result.

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

A successful isolated cold run is required before calling this replacement
recovery route qualified. The previous 45-minute parent-based recovery result
does not qualify the new route.

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

## Separate root workspace

The repository-root TypeScript workspace is distinct from `psc0`. Its old
backend uses TypeScript's programmatic compiler API. TypeScript 7's CLI migration
must preserve the actual compiler and CLI callers' virtual source content,
module resolution, output artifacts and diagnostics; updating package versions
alone is insufficient.

That adapter migration and its workspace pins are being completed separately.
Its own existing backend/compiler/CLI/integration gates must pass before this
guide can claim that TypeScript 5 is retired across the whole repository.

## Historical evidence

The [preserved original TypeScript 7 checkpoint guide](TYPESCRIPT7_CHECKPOINT.md)
contains the original package check, two-profile migration attempts, seed A
recovery, exact receipts and single-run measurements. The original source
revisions, manifests, logs and provider decisions are unchanged.

The measured direct TypeScript phase was a small part of the full generated
compiler pipeline. Preparation, admissions, erasure, IR checking and emission
have their own costs. Neither retiring TypeScript 5 nor removing its comparison
step establishes a measured speedup for those PSC phases.
