# Installed modular compiler preview

Historical scope: M4 version0.1.0-psc1-modular.1. For the current self-host-qualified
.3 installed preview and verified ZIP, see the
[integration guide](selfhosted-installed-toolchain.md). The M4 receipts below remain
unchanged historical evidence.

The preview keeps proofscript as the installation umbrella. Its three-line psc
launcher calls @proofscript/cli. That package owns the existing project capture,
diagnostics and watch supervisor; @proofscript/compiler owns checked execution
and independent admission. Fifteen lower packages contain the original 127
generated units with actual imports. There is no frozen whole-compiler fallback.

The qualified .13 distribution remains the reference. The new version is
0.1.0-psc1-modular.1, with an explicit direct-package API transition:
checked compile/build conveniences stay at proofscript and @proofscript/compiler.
Lower packages expose source APIs and generated/* subpaths; their old ./compiler
and checked backend aliases are removed. Root checked backend conveniences remain.
A lower emitter is never silently substituted for a checked compile API.

## Installation and navigation

The Linux workflow produces an unpublished root tarball with all 20 exact core
dependencies bundled. Install that root with npm's offline/ignore-scripts options.
Python/PHP, target SDKs and native checking remain explicit optional resources.
No install or compile operation downloads a missing SDK.

Use proofscript/foundation, proofscript/elab and other root subpaths rather than
assuming npm hoists bundled dependencies. Advanced generated subpaths forward to
the real owned implementation, for example proofscript/foundation/generated/runtime
and proofscript/foundation/generated/runtime/ts. Generated APIs are versioned
preview interfaces and have no independent admission/publication authority.

The checked host requires the sealed umbrella scope. Standalone lower generated
modules retain ordinary declared imports, but standalone checked-host installation
is not qualified. The original source-owned package candidate and its tarballs
remain independently preserved. Do not infer standalone checked-host support from
their installation tests.

## Resource and checking path

[Package assembly](../../scripts/modular-toolchain-package.mjs) verifies the exact
qualified original graph before copying it. It preserves every original file
except versioned package metadata; the installed verifier checks that correspondence.
The original declarations, units, ownership, entry points, source identity,
admission hash and partial declarations remain bound to the original manifest.
Generated bodies, declarations, readable TS, maps and captured sources are retained.

The installed graph root is the umbrella's isolated node_modules scope. Its
manifest lives outside that scope in dist/COMPILER_GRAPH.json. The existing
[verifier](../../host-tools/executable/verify.mjs) keeps its original candidate
profile and adds a separate installed profile: exact files/directories/hashes,
package versions, runtime and peer edges, ownership and original-file correspondence.
It preserves 128 MiB aggregate, 32 MiB/file, 8,192 files, 257 units/package records,
path bounds and regular-file/no-symlink policies.

One fixed bootstrap seal, @proofscript/compiler/dist/host/DISTRIBUTION_PIN.mjs,
cannot include its own digest. Only that exact bounded file is omitted from the
graph's hash inventory; the existing per-request common resource pins include it.
This is the existing trusted-bootstrap/stable-resource assumption, not a signature,
sandbox or protection against replacing all installed trusted code.

[Installed selection](../../host-tools/installed-engine-resolver.mjs) chooses the
fixed cohort manifest and JS/TS variant. It performs no upward directory search
or import of umbrella code. Node's ordinary package imports implement declared
dependencies; no lower package depends on proofscript or CLI. Source/project data
cannot choose a different graph, checker, SDK executable or publication capability.

The [checked API](../../npm-cli/compiler-api.mjs) invokes the unified candidate
runner for modular engines, then reuses the existing independent checker, strict
original/transformed IR, target consumers and transactional publication.
The default checker remains the genuine official Lean 4.35.0 C++ kernel built with
Emscripten and linear-memory Wasm. It is copied byte-identically from the qualified
kernel package. There is no native checker fallback.

The CLI files are relocated from their canonical [frontend](../../npm-cli/proofscript-cli.mjs),
[project capture](../../npm-cli/cli-project.mjs), [watch](../../npm-cli/cli-watch.mjs)
and [worker](../../npm-cli/cli-watch-worker.mjs) sources. Assembly records exact
source/installed hashes and finite import/version-label rewrites, then reverses
those rewrites to require body identity. These are host moves, not new compiler
implementations.

## Qualified Linux preview and installation

[Run 40714983520](https://github.com/dwijayuda/pskernel/actions/runs/40714983520)
passes at `ca92bbdbc7c0f34e1da4076db7300033802eab3e` on Node 22.23.3/Bun 1.4.4.
Both installed JS/TS engines pass 128 public-value/component builds and 20 source/
assurance refusals across the seven adapters, plus 16 smoke builds and 28 real
kernel acceptance/rejection cases. Each host checks the entire native-qualified
compiler admission using the default Wasm kernel, and fresh global root-only
check/build succeeds. Eighteen retained watch cases exercise real edits, bad/missing
sources, config recapture, supersession and cancellation. The original reference
CLI preserves its complete native guardian/cancellation tests unchanged.

[Boundary/IO/types run 40722004088](https://github.com/dwijayuda/pskernel/actions/runs/40722004088)
tests the exact same tarball: 46 metadata/resource/consumer refusals, 16 Unicode
callback/trap IO builds, eight unsupported Wasm-core dispatcher refusals, four
strict NodeNext/Bundler consumers and two additional TS-engine watch cases.

[Installed applications run 40725714755](https://github.com/dwijayuda/pskernel/actions/runs/40725714755)
passes 32 checked builds/528 retained cases: four 11-module CLI/JSON/file/compiler-like
apps, both grammars/engines and JS/strict TS output. Admission, IR and decoded-source
identities match independently checked native references. Actual runners import the
installed IO runtime; invalid input, permission/capability denials and prior-file
preservation remain covered. The 100,000-statement workload takes Node 6,250–11,765 ms
(maximum 168,740 KiB RSS) and Bun 1,605–2,865 ms (110,356 KiB), observed on these CI jobs.

[Download the installable preview](https://github.com/dwijayuda/pskernel/actions/runs/40723525652/artifacts/12832176204)
while signed in to GitHub. Extract GitHub's artifact ZIP, then its inner
proofscript-0.1.0-psc1-modular.1-installable.zip. Read INSTALL and SHA256SUMS, then:

```sh
npm install --offline --ignore-scripts ./proofscript-0.1.0-psc1-modular.1.tgz
npx --no-install psc --help
```

The root tarball is 11,329,698 bytes; SHA256
`7773a7a2abcebaf1fd77df836b2c687e013001c23885bb0bb584e6fe8d012507`.
It contains all 20 core packages. The optional
[target resource archive](https://github.com/dwijayuda/pskernel/actions/runs/40714983520/artifacts/12827921799)
contains matching TS/Rust/component consumers and optional Python/PHP providers.
Follow the existing [SDK resource guide](../guides/npm-packages.md) and receipt
instead of installing incompatible old compiler executors.

The installed graph is 1,423 files / 124,338,997 bytes. The tarball is the exact
successful implementation artifact; the delivery workflow does not rebuild it.
GitHub artifact retention is finite. No registry publication or permanent release
hosting is implied. The ZIP's focused receipt predates the final application/source
results; the [complete repository receipt](../PSC1_MODULAR_INSTALLED_QUALIFICATION_2026-10-28.json)
records all exact jobs, commits, artifact digests, attempts and measurements.
Source 40719527295 passes all 16 selected jobs/37 Core criteria; retained .11
reference CLI 40714983602 passes all nine jobs at the same implementation.

Rust/Wasm remain supported output backends through JS/TS engines. Their previously
qualified compiled compiler executors remain usable with .13 and explicitly refuse
this newer source cohort. Bool components execute false/true; richer component
String/IO and real non-JS host-IO applications remain separate work.
New modular G2/G3/fixed points, exact graph/package reproduction, native binary
reproduction, standalone checked-host installation and other-platform durability
remain unqualified. M5 must implement portable module planning/emission using the
same canonical compiler before genuine modular self-reproduction.
This finite Linux preview does not authorize merge, registry publication or .13 replacement.
