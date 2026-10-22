# PSC1 Practical Core v1 release candidate

The finite v1 compiler is qualified at source
9ee6c5ffe8ac344b349fde7eee8f5ef867bd5dde, tested merge
00decc7fb81fc4023f68cdcdbf8cff1fdd028b12 against base
1fad9ed53cda9b23ac30be9cea85e7857437564e.
[Linux run 39829564386](https://github.com/dwijayuda/pskernel/actions/runs/39829564386)
passes native/focused, complete semantic/JS/Rust source closures, G1, host boundary,
full integration and aggregate. All 47 full-job steps succeed.

The [frozen contract](PSC1_PRACTICAL_CORE_V1_CONTRACT.json) owns scope:
14 families, 37 criteria, both authored grammars, seven targets and four actual
application categories. The [exact receipt](PSC1_PRACTICAL_CORE_V1_QUALIFICATION_2026-10-23.json)
records observations, source/IR/admission identities, every job/step and artifact
digests/expiry. The [derived inventory](PSC1_PRACTICAL_CORE_STATUS.json) distinguishes
finite v1 qualification from unrestricted language or backend claims. The older
status is preserved in history/PSC1_PRACTICAL_CORE_STATUS_BEFORE_V1_2026-10-23.json.

## Use the tested Linux package

The [full qualification artifact](https://github.com/dwijayuda/pskernel/actions/runs/39829564386/artifacts/12451785253)
contains the unpublished proofscript-0.1.0-psc1.2.tgz under
npm-native/run-nrc1Xa/tarballs/. After extracting the artifact, locate that file
and check its SHA-256 before installation:

```sh
sha256sum proofscript-0.1.0-psc1.2.tgz
# c70a7e8965f4ddef4c48f14f9e645da3dc0389e23a841f372c2ff80f670f1956
npm install ./proofscript-0.1.0-psc1.2.tgz
npx psc --identity
npx psc check src/Main.ps
npx psc build src/Main.ps --targets ts,js --out-dir dist
```

The tarball is 37798419 bytes and the native compiler is 124537496 bytes, binary
SHA-256 33381d3809c8b6aed91de062959161cf38bf24164075b17bc291c7ea0955b0a9.
Qualified platform: Linux x64, glibc 2.39, Node 22.23.3. This is measured platform
evidence, not a lower glibc compatibility guarantee. Target-specific tools and
runtimes are separate prerequisites. See [the npm guide](PSC1_NPM_ECOSYSTEM.md).

The artifact ZIP digest is
9a72ab29e62693915432efc326597809fea500047d34693d6b55fda8ffbc4b76.
Retention expires 2026-11-05T19:03:04Z (2026-11-06 02:03:04 Asia/Jakarta).
The committed receipt survives; it cannot recover expired tarball bytes.
A future authorized release must retain the exact tested package or qualify a
new package built from its exact source. No registry or GitHub Release upload
is performed by this continuation.

## Language, applications and ABI choices

The frozen scope includes checked Nat/Int order, bounded inference/control,
typed handlers, persistent collections, namespaces, ordinary partial execution
and typed IO. Real CLI/JSON-file, multi-module-library and streaming compiler-like
applications execute in both grammars across all seven target mappings.
See [CLI/JSON use](PSC1_PRACTICAL_APPLICATIONS_V1.md),
[compiler-like use](PSC1_COMPILER_APPLICATION_V1.md) and
[IO capabilities](PSC1_TYPED_IO_V1.md).

Default checked admission retains official Lean 4.35.0 at
eb6cafb7290e8bd5f2937522d8d804f58f02bafc. Explicit ordinary mode preserves
constructive logical-witness/exact-executable-body pairing. Verified mode refuses
without behavioral certificates. Source, transformed and target IR remain strict.

Default component public ABI is Bool-only. Explicit wasm-string accepts selected
Bool/String signatures; io-dispatcher additionally accepts the checked dispatcher.
[Wasm ABI limits](PSC1_WASM_STRING_ABI_V1.md) include a fixed 16 MiB arena and
2 MiB IO payload configuration ceiling. Other public compound signatures refuse.
Node/Python/Rust/PHP/core/component IO hosts require explicit capabilities,
held path roots and bounded UTF-8/line sizes. PHP's standalone profile requires
Linux CLI FFI; this grants no source FFI primitive.

## Remaining release actions

No finite Practical Core v1 acceptance item is blocked at the qualified source.
Review and authorization for merging the preserved PR stack, registry publication
and release uploads remain separate. PR #172 remains draft. Changed compiler,
runtime, dependency or package bytes require fresh relevant and final qualification;
a branch name or this status file cannot transfer the old results.

G1's ten selected cases pass. G2/G3 and fixed-point qualification remain in the
separate manual workflow on finalized feature-frozen compiler source. The original
G2 heap/timeout defect remains tracked; it is not resolved by G1's printer fix.
This development continuation does not manufacture a workflow-dispatch event or
move self-hosting back into normal feature CI.

Unrestricted Lean, general effects/metaprogramming, unsupported public aggregate
ABIs, non-Linux distribution and formal backend-preservation certificates remain
outside v1. PSKernel-Core Expression V2 research remains independent of production
official admission.

## Maintain the inventory

From the PSC1 workspace in Linux CI, the pure inventory command checks the
committed status against the frozen contract and immutable checkpoint:

```sh
node scripts/practical-core-release-status.mjs
# After recording a genuinely qualified replacement checkpoint:
node scripts/practical-core-release-status.mjs --write
```

The generator's checkpointPath must explicitly name the reviewed immutable
checkpoint. Its contractBlobSha pins exact contract bytes from that source;
changed acceptance text cannot inherit the old checkpoint at the same count.
Update that identity only with genuinely qualified replacement evidence. Static tests reject inconsistent source/merge/checker/package
identities, incomplete/failed/skipped/duplicate required gates, missing G1 or
compiler closure evidence, and stale inventory bytes. These are consistency checks
on recorded evidence, not independent proof admission or live GitHub authentication.
Live CI run conclusions and actual artifacts remain necessary evidence.
