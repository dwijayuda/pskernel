# Native runtime emission: C0–C3 and GC runtime foundations

Current status, 13 October 2026: C0–C4b runtime/output foundations are qualified
at c00e146b / Linux 38388627512 with 250 shared observations. The current primitive
audit is schema /2 and includes checked logical models with runtime overrides;
the original counts below are historical. [Current seven-format audit](PSCV0_READABLE_OUTPUT_AUDIT_2026-10-13.md)
distinguishes complete bounded outputs from remaining C5 and map precision work.

The native Lean host retains one immutable prepared graph through official
Lean kernel admission, typed erasure and the complete shared IR checker.
Only then does it plan requested targets. Reports and raw lowering APIs do
not grant admission authority. The compiler is authored and executed in Lean;
there is no host elaborator fallback, pskernel-core or self-host generation.

## Shared plans, target boundaries

```text
v7 syntax + actual command-batch origins
  -> elaboration -> prepared Core + actual helper-parent associations
  -> official Lean checking -> erasure -> complete IR validation
  -> runtime public API / target names / source identities
     -> one ECMAScript Program -> TS implementation
                              -> JS implementation + declarations + map
     -> existing Rust ownership/layout plan -> Rust + runtime
     -> typed Wasm core plan -> direct .core.wasm + readable .core.wat
                            -> scalar interface/lifts -> .wit + .wat + .wasm
  -> validated portable artifact bundles -> native host publication
```

Ps.BackendEcma.Syntax contains expression and statement nodes plus a bounded
Doc printer. Lower owns shared IR lowering, including generators, once-only
argument evaluation, lexical bindings, conditionals, matches, count loops and
tail loops. Runtime and Intrinsic use these nodes too. Type annotations and
type declarations are target-only type text; no executable JS is obtained by
stripping, parsing or transpiling emitted TS.

The host builds one ECMAScript Program for all requested ECMAScript dialects.
Name allocation, runtime export planning and definition lowering are shared.
JS/TS layout and .d.ts signatures consume that plan. The inline runtime is
self-contained: generator requests use a bounded-host-stack dispatcher, array
callbacks join that dispatcher, and UTF-8 operations share the existing bounded
two-string index cache. Optimized tail matches own lexical blocks, preserving
JavaScript temporal-dead-zone boundaries. Nonrecursive straight-line functions
do not acquire unnecessary loops. A simultaneous tail assignment evaluates
all new arguments before replacing old parameters.

The native readable TS entry is now a thin adapter. The historical bootstrap
string APIs remain for their existing callers, outside the native portable
closure. Their target-independent recognizers were extracted into
BackendTs.Analysis and reused; they were not copied into a second active
lowering algorithm. Migrating the historical bootstrap path is not this task.

## Names, provenance and maps

Core and erasure retain semantic names. Codegen allocates target names without
changing Core equality, declarations or proof terms. Public declarations are
allocated first; lexical names already carry erasure's scope disambiguation.
Reserved language/runtime names, normalized-name collisions and prototype
property spelling are handled at the target boundary. Common Unicode letters
remain readable. Collision-group canonicalization under arbitrary edits remains
future work.

The command elaborator retains origins from its actual output batch, including
normalization members and generated structure projections. Preparation records
the actual parent of each lifted recursor helper. No second elaboration or
name-prefix guessing reconstructs those relationships.

PsSourceIdentity keeps a file and qualified semantic declaration independently
of target spelling and byte offsets. Occurrence paths are available for later
finer origins. C0–C2 source resolution is **owning declaration span**: nested
lowered code maps to that declaration, and generated members retain their
parent reason. This is not token/statement stepping or comment reconstruction.
Runtime-only helpers are unmapped. Pre-erasure Lean/ProofScript source
reconstruction and finer origins remain C5 work.

Doc's UTF-8 generated ranges remain available in the manifest. SourceMap
separately converts final-layout positions and original source offsets to
zero-based UTF-16 columns, emits ECMA-426 v3 VLQ segments, retains original
source content and terminates attribution at generated-range boundaries.
Source-map URLs encode unsafe filename bytes. These maps are real original
source mappings, not renamed generated-byte metadata.

## Artifact and public API contracts

A bundle contains relative paths, roles, text/binary payloads, dependencies,
semantic/output symbols, runtime API information and source origins. Portable
validation rejects traversal, absolute paths, Windows-invalid/reserved names
and case-folded path collisions. The CLI constructs all selected bundles and
manifests, checks output collisions and then writes them. This does not claim
crash-atomic replacement of several filesystem paths.

The public API is derived after the checked IR gate. It supports all-runtime
exposure or explicit unique export selection, refusing unknown names. Generic
parameters, actual runtime parameter/result types and data declarations are
retained. Erased proof declarations do not become fictitious foreign exports;
Unit proof-call slots that remain in the ABI are visible in .d.ts.

The C0 WIT classifier conservatively refuses unbounded integers, generic and
recursive data, function values, target-sized integers and Unit where explicit
adapters/policies are required. This does not restrict their internal language
representation. C4/C4b supply the selected integer/aggregate adapters, typed
GC runtime/lowering, direct component/core encoders, readable WAT and WIT,
and Canonical ABI allocation/post-return. Pre-erasure source-invariant evidence
prevents erased proof obligations from disappearing at foreign construction.
The selected ABI plan supersedes the conservative C0 classification only for
an actually admitted component bundle.
The user selected GC language values with linear memory only at explicit
Canonical ABI boundaries. Target capability records describe the bounded
qualified profiles, not full v7 conformance. See PSCV0_NATIVE_WASM.md.

## Trust ledger

The provider checks definitions/inductives relative to its reconstructed
portable prelude. Prelude axioms remain assumptions. The native-only
PrimitiveAudit imports the pinned native Init environment and compares all 64
axiom signatures modulo binder names/annotations, metadata and universe naming:
48 match; 16 are explicitly recorded models. Those models restrict Array/Prod
universes or represent String.Pos.Raw by Nat (including explicit fold bounds).
Unexpected mismatches fail qualification. Exact reviewed portable/native
signatures live with the audit at the pinned toolchain.

Matching a signature does not prove a primitive body or foreign runtime
implementation. Checked Core, primitive assumptions, runtime IR validation and
observed target behavior are distinct assurance boundaries.

## Native CLI and validation

```text
pscv0_native --emit application.ps output.js
pscv0_native --emit application.ps output.ts
pscv0_native --emit application.ps output.rs
pscv0_native --emit-all application.ps output
pscv0_native --audit-primitives
pscv0_native --emit-wasm-core application.ps output
pscv0_native --emit-wasm application.ps output exports.json
```

JS emission produces output.js, output.d.ts, output.js.map and a host provenance
manifest. TS remains output.ts plus its manifest; Rust retains its companion
pscv0_runtime.rs and locked runtime dependency policy. Application .ps files
are inputs; compiler sources remain handwritten .lean.

Validation reuses the same 473-declaration composite, four accepted programs,
92 phase-specific refusals and 28 parser cases. Its 142 runtime observations run
on direct JS, TS-compiled JS, Rust and both Wasm core/component forms.
The Wasm qualification reuses the table through a batched Wasmtime embedding
harness, plus focused binary/WIT/ABI checks. Added checks are confined to the new
boundaries: artifact paths, primitive signatures, independent map decoding
(including non-BMP UTF-16 columns and generated/unmapped regions) and an isolated
strict .d.ts consumer with negative type cases. The consumer directory contains
no sibling .ts implementation that could shadow the declaration file.
Exact source/run evidence is recorded in AI_WORK_STATE.md.
