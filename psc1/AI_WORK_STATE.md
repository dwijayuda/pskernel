# PSC1 AI work state

Updated 2026-10-25 Asia/Jakarta. Active draft PR #181, branch
`refactor/psc1-readability-20261025`, based on qualified PR #180 HEAD
`3089cbc369bc8a11f540c13140c7003c9dadf4a8`.
Use connected GitHub and Linux Actions only. Refresh HEAD before writes and use
single-parent expected-HEAD non-force updates. No merge or npm publication.

## Active R1 lossless capture (in progress)

Branch `feat/psc1-lossless-source-20261025` follows PR #181 HEAD
`d7e845b35e6c5cc80ffafe2f6f41fc475bf3842c`. Additive lexer sidecar and
native capture helper compile on official Lean 4.35.0 in Linux run 40189711916.
The original lexer/parser/compiler and packaged artifacts remain unchanged.
Opaque host snapshots retain exact bytes, logical identity, grammar/profile and
per-snapshot piece IDs. Candidate edits require the exact current bytes and are
never published or labeled semantically equivalent. Host, negative, corpus and
resource tests are being added; this is not yet a qualified R1 result.

## Readability slice

Implementation: `446a0f21c6288a7c20b843bbeadcd18ba1460fa2`.
Documentation commit 40bd3bb3 establishes current README/architecture/contributor,
docs-index and host guides. Previous README/architecture snapshots are preserved
under docs/history. Root research and PSC1 pins are explicitly distinguished.
Historical profile fields are retained and point to current finite contracts.

Host commit `dfb44062bbc1fb490fa5696483938f07e0f63e0c` formats/documents the
installed engine resolver, API and CLI with existing pinned Prettier 3.6.2.
Babel 7.28.0 compares all three executable ASTs with immutable baseline 3089cbc3,
ignoring comments/positions/literal spelling metadata only. No host behavior changes.

Module commit fef84d24 extracts 27 public definitions and 935 lines verbatim into
`packages/backend-wasm/src/Ps/BackendWasm/Lower/TypeInventory.lean`.
Lower.lean decreases from 6472 to 5538 lines. The new module imports only Wasm
Type and Foundation.List, retains traversal/de-duplication/fuel behavior and has
an explicit Lake root. All moved and remaining declaration bytes are checked.
Commit 446a0f21 relocates five prefix-guard paths without dropping assertions.

[Contributor guide](CONTRIBUTING.md), [docs index](docs/README.md),
[exact readability receipt](docs/PSC1_READABILITY_QUALIFICATION_2026-10-25.json).
This is the first maintenance slice; lossless source editing, binding-aware rename,
broad language extensions and a generalized plugin framework are not implemented.

## Actual validation

- Correspondence run 40184892095/job 121143498849 PASSED: three formatted,
  baseline-equivalent executable ASTs; exact 27-definition extraction; all 52
  recursive-prefix worker guards; 467 owned Wasm definitions scanned, no violations.
- Package run 40184641007/job 121142731401 PASSED at host commit dfb44062:
  20 compiler cases, 12 local/global CLI cases, 48 candidate mappings,
  14 genuine native/Wasm acceptance/rejection comparisons, 36 negative or
  publication-failure cases and actual packed public TypeScript APIs.
- The packaged host and frozen inputs are unchanged between dfb44062 and
  implementation 446a0f21; GitHub comparison contains only compiler extraction,
  its tests/docs, Lake registration and the correspondence workflow.
- New-source Wasm G1 run 40184951724/job 121143765230 PASSED. Both grammar
  censuses accept all 121 modules. Genuine generated Wasm runs 40 cross-target
  cases (including semantic refusals) and nine envelope refusals, with native
  compiler executables removed after the one seed. Existing 240s request/tool/
  corpus and 120s checker limits remain. This is G1-only, with no new G2/G3,
  fixed point or 240s self-compilation performance qualification.

New source closure:
`7a49ccbd8b11d029e54fa0d78da9e8fe66943193cc73d00c29b4ed392126a000`.
G1 qualification branch `qualification/psc1-readable-wasm-g1-20261025`,
control 1114d60b, request `b0cf4895a8ad3ec97be45e7382d5dbf690acb340`.
GitHub comparison against 446a0f21 changes only the workflow branch guard and
explicit request JSON; no PSC1 source changes.
Artifact 12595587700 ZIP SHA256
`3e1114b99c8944618c756ad1aa490644291ea53bcc4baef6b349dc98eba3779a`.

Normal source run [40184897417](https://github.com/dwijayuda/pskernel/actions/runs/40184897417)
PASSED: full job 121146243734, final gate 121152107403; 37/37 Practical Core criteria,
zero blocked, releaseReady=true within the finite contract. All seven native
backends, both grammars, minimum Python, runtime/IO/negative checks and installed
native npm/source libraries pass.
Tested merge `1b9eca5fd94ca4271369238ed34dd094f66d9134` and implementation
446a0f21 share Git tree `cf56c28b8e67e6f8d643465fc74086cf7c95e409`.
Full artifact 12597345757, ZIP SHA256
`c27b05c898cc1ca1be1525172b927847a27649efdbc0cc169e89b433049d7316`.
This source qualification is distinct from slim host package 40184641007 and
new-source Wasm G1 40184951724; it does not qualify new-source G2/G3 or a complete
cross-platform/generated-non-JS release.

## Qualified installable host package

Unpublished `proofscript@0.1.0-psc1.4`: 3,704,169 bytes, SHA256
`8eb0c18270fd4224671a8da3babc0cd428139abd8bec2dc8ded7d572745809d8`.
Five-tarball qualified artifact 12595861227 from run 40184641007, ZIP SHA256
`2cbb2fa57328a60f0372eaa30f9eed2b2ad9e7c79ce26d2961f50ffacd75e1e7`.
Use [the current install guide](docs/PSC1_SLIM_UNIVERSAL_PACKAGE.md).

The root retains frozen G3 JS/TS and the mandatory official C++/Emscripten
linear-memory Wasm checker. Rust/compiler-Wasm and native checking are explicit
pinned optional packages. Actual empty-cache offline installs disable scripts
and start without optional/native payloads or compiler SDKs.
Checked generated output remains JS; other exposed mappings are candidate-only.
Linux publication retains locks, immutable generations, fsync and atomic pointer
commit; other OS publication still refuses. No fallback or arbitrary plugin/tool
selection is introduced.

## Preserved frozen compiler and kernel evidence

Frozen packaged compiler: 120 modules, implementation daa735017e34ee94da79d747c363237b4adbc4ef,
closure `07eedac1888aad3d4192664cea8d21a515d23985f3befd6cb365d0194fee53af`.
All four prior G1/G2/G3 and exact source/admission/original+specialized IR/
executable/four-target fixed points retain their original identities:
Rust 40141718481; JS/TS/Wasm 40147825207.
[Four-engine receipt](docs/PSC1_UNIFIED_FOUR_ENGINE_QUALIFICATION_2026-10-25.json).
Do not present these as G2/G3 evidence for the refactored 121-module source.

Both official Lean 4.35 kernel packages retain five-platform qualification:
native 40155475188, linear-memory Wasm 40158859386.
Compiled bundles 40158598464 retain Wasm execution on five platforms and Rust on
Linux x64. The previous native distribution and optional Python/PHP providers
remain preserved with their seven-output/source-library/application evidence.
[Kernel/package receipt](docs/PSC1_KERNEL435_QUALIFICATION_2026-10-25.json),
[prior slim receipt](docs/PSC1_SLIM_UNIVERSAL_QUALIFICATION_2026-10-25.json).

Official Lean 4.35.0 commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc,
trustlevel0, finite 2,000,000-heartbeat/20,000-recursion bounds, exact source/logical
pairing, independent admission, strict both IR, fuel, memory/stack/lifetime,
negative tests and unsupported ABI refusals remain unchanged.
Original 240s performance and 1800s correctness profiles remain separate;
Rust-only 3600s applies only to G2/G3 requests. The isolated lexer 31e10263 remains
unpromoted. Formal compiler semantic preservation and final clean release
reproduction are not claimed.

## Continue from this checkpoint

The [single development roadmap](docs/PSC1_DEVELOPMENT_ROADMAP.md) owns the remaining
queue. Preserve the completed readability slice and its exact evidence.
For further maintenance, prefer independent helper/module boundaries and recorded
invariants; build lossless token/trivia and resolved identities before broad
automatic source conversion or rename. Do not replace workers with shorter forms
without correspondence/resource evidence. Existing source-shape guards remain
required until equivalent protection is explicitly qualified.

Product work remains source-package/application coverage, portable publication,
checked non-JS/provider dispatch, additional Rust platforms and final release
qualification. New compiler-source promotion needs its own generation evidence;
unchanged frozen packages do not require repeated long chains for documentation.
