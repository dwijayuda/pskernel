# Portable modular generation (M5)

Status: implementation under qualification. Native differential and small-candidate
tests and the 133-module two-grammar census pass. The native G0 graph matches all immutable renderer bytes. Portable G1 passes Linux40748275409 with exact native IR and rendered-byte identity. JS/TS G2/G3 and fixed points remain pending.
The [roadmap](../PSC1_DEVELOPMENT_ROADMAP.md) remains the overall queue.

The compiler owns module generation in
[CompilerUnified.Modular](../../packages/compiler-unified/src/Ps/CompilerUnified/Modular.lean).
It calls the existing parser, elaborator, preparation, strict original IR,
specialization, worker fusion and producer-provenance operations. The bounded
[production planner](../../packages/backend-common/src/Ps/BackendCommon/ExecutablePlan.lean)
and existing structured [JS](../../packages/backend-js/src/Ps/BackendJs/ModuleFiles.lean) /
[TS](../../packages/backend-ts/src/Ps/BackendTs/ModuleFiles.lean) renderers now use
portable persistent operations. There is no native container or second frontend
inside the canonical compiler closure.

## Ownership and failure boundaries

Each captured elaboration supplies actual tagged PsName members. The compiler
checks their order/count against that same elaboration's returned declarations.
The key encoding distinguishes string and numeric components and includes string
byte lengths. Hash tries always compare full keys; hash collisions grant no identity.

Erasure names must select exactly one source owner or an existing runtime-prelude
owner. Specialization and worker ownership follow complete producer provenance;
original and transformed IR are rechecked. Missing/duplicate/unknown ownership,
open values, unsafe specifiers, cross-source cycles, eager initializer cycles and
exhausted bounds refuse. No ownership is inferred by decoding generated names.

The portable calling conventions match those already used by the compiler:
explicit collection operations, fully applied recursive traversals, typed match
results and explicit effect blocks. This does not expand the language with ignored
Lean conveniences. Native Lean and the PSC1 frontend must accept the same actual
committed source. Internal import records supply Bool fields explicitly.

## Candidate transport and independent checking

The closed wire form is:

    ["psc1-modular-build/1", existingCompilerRequest, sourceOwnedSpecifiers]

The same psCompilerServiceCandidate entry dispatches it. Normal unified requests
retain their existing path. Successful generation returns candidate-only files:
admissions; capture/ownership; original, specialized and fused IR; module metadata;
shared JS helper support; and the actual JS/.d.mts/TS units. It does not emit a
whole-compiler bundle.

Each file row has four cells: [name, format, value, suffix]. The six fixed JSON
filenames use raw JSON values; emitted source uses text strings. Only admissions
has a required final newline. Host decoders enforce the format and suffix from the
filename. Canonical JSON reconstruction must reproduce the exact native IR and
admission bytes; numeric values outside safe integers refuse. This avoids a second
layer of JSON escaping without increasing either the wire or file bounds.

[Quarantine](../../host-tools/executable/quarantine.mjs) permits only the fixed
metadata filenames and bounded numbered units. It checks duplicates, complete
write sets and byte limits. Source data cannot choose a checker, SDK, arbitrary
filesystem target or publication capability. Candidate output is not admission.

The [generation host](../../host-tools/executable/generation-tools.mjs) compares
admission, IR, owners, ordering, imports/exports and every rendered module against
the native reference, then independently admits the exact Core through official
Lean 4.35.0 / eb6cafb7290e8bd5f2937522d8d804f58f02bafc before packaging/import.
The native reference planner is retained. Pre-M5 renderer bodies are native-only
test oracles: their audit allows only namespace changes and explicit materialization
of the former Bool=false field defaults. Complete-compiler unit bytes must match.

Whole-compiler native reference bundles are explicit corpus test oracles outside
every executable graph. They are not generation outputs or producer fallbacks.
The generated loader imports only the verified source-owned graph.

## Reproduction and qualification

[G1 preparation](../../host-tools/executable/prepare-generation.mjs) creates a new
source/graph input identity. [Self-host qualification](../../host-tools/executable/selfhost.mjs)
must run independently for JS and TS: G1 produces G2, G2 produces G3, and each
generation is independently admitted before use. Native frontend executables are
quarantined during these runs; only the official independent checker remains.

The host requires identical G1/G2/G3 manifests, complete file inventories and npm
tarball bytes, generated afresh in distinct directories. It reuses retained output,
strict TS, refusal, offline npm and exact installation tests. No self-host receipt
is inherited from the qualified .13 or M4 compiler source.

New candidate packages use 0.1.0-psc1-modular.2. Readable TS and accurate generated-TS
source maps remain shipped; maps refer to actual in-package sources rather than
embedding duplicate sourcesContent. No original-Lean line map is invented.

G1, corpus and tools retain 240-second requests; checking retains 120 seconds.
Only G2-self/G3-self may use the explicit 1800-second correctness profile. The
separate performance-240s profile is preserved. Heap/stack/fuel, 32 MiB files,
128 MiB stage/graph bounds, 8192 values/files, 257 units, 4096 reference depth and
131072 initializer edges remain. The existing loader also bounds transient
candidate strings at 128 MiB; supervision stdout/stderr remains 32 MiB.

Exact receipts must distinguish implementation, native tests, portable source
acceptance, independently checked G1, executing G2/G3, fixed points and performance.
This is finite reproduction/execution evidence, not a totality or semantic
preservation theorem. Existing ordinary source/logical-body pairing remains.

The qualified M4 proofscript umbrella, thin psc CLI, official linear-memory Wasm
kernel, optional Python/PHP and frozen .13 executors stay preserved. New root
promotion/platform qualification and authorization to merge or publish are separate
release gates. PSKernel-Core research is independent.

