# Installed modular compiler preview

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

## Qualification boundaries

Initial [Linux run 40711483603](https://github.com/dwijayuda/pskernel/actions/runs/40711483603)
passes at 8ed9e07ab2342a2afb41fdcce637826aa4d06dfc: 16 installed checked
builds/publications and 28 independent kernel acceptance/rejection cases on
Node 22.23.3/Bun 1.4.4. This qualifies the finite smoke scope only.
[Receipt](../PSC1_MODULAR_HOST_RUNTIME_QUALIFICATION_2026-10-28.json).

Extended acceptance runs the retained M3 public-value observations through installed
JS/TS engines and all seven checked targets, compares source/admission/IR identities,
checks the native-qualified compiler admissions with the actual default Wasm kernel,
and tests fresh global installation. Nine applicable retained watch bodies run on
each host. The original reference CLI retains its complete native-engine cancellation
tests unchanged; the preview refuses those older executors' source cohort.

Rust/Wasm remain supported output backends through JS/TS engines. Their previously
qualified compiled compiler executors remain usable with .13, and explicitly refuse
this newer source cohort. New modular G2/G3/fixed points, native binary reproduction,
standalone checked-host installation and other-platform durability remain unqualified.
This preview does not authorize merge, registry publication or .13 replacement.
