# PSC1 AI work state

Updated 2026-10-25 Asia/Jakarta. Active diagnostic-fix branch
`fix/psc1-character-diagnostics-20261025`, based on qualified PR #182 HEAD
`4c977654b8ca39b5fb3568ca9ebea03eee9d4339`.
Use connected GitHub and Linux Actions only. Refresh HEAD before writes and use
single-parent expected-HEAD non-force updates. No merge or npm publication.

## Character diagnostic correction (in progress)

The sole production change in Lexer.lean replaces advancing only the unexpected
close character with advancing the actual body character followed by that close.
This repairs UTF-8 offsets and line/column progression for the entire malformed
unescaped-character class. Existing lexical acceptance, proof checking, IR and
resource policies are unchanged; qualification is in progress.

New 121-module source closure:
60dd756e29cf6fbd44386e342318c53b22f41f2f3beb21b05aa39505a366271a.
The frozen packaged compiler and old R1 source keep their own exact identities.
Run 40195466611 establishes the one-change/source-correspondence guard but fails
the new proof/test source build; no successful correction qualification is claimed.
The scoped universal character-lexer correspondence and actual-prefix theorem are
being repaired and will remain axiom-free. R1 snapshots keep old advisory-location
compatibility, and future development gates build these new regressions.

## Preserved qualified R1 lossless foundation

Implementation `c577d49888493857199fa3dc26f7ff78ed157def`, stacked draft PR #182 on PR #181
HEAD `d7e845b35e6c5cc80ffafe2f6f41fc475bf3842c`. Tested merge `e0b14e376f0231877b4c03321842f4eeaad97f5a` shares tree
`424e725cde95312d2b5cac9e87aa36df1fc3a676` with the implementation.

The additive Ps.Syntax.Lossless tape reuses the original lexers and comment/cursor
helpers. Native transport and the host source-refactoring API retain exact UTF-8
bytes, token/trivia spans, raw spellings and per-snapshot piece IDs. Logical module,
grammar/profile and exact-byte digests define source identity; URI is provenance.
Opaque, deeply frozen snapshots and copied buffers prevent forged/mutable edit
handles. Staged old-coordinate edits require exact current bytes, valid UTF-8
boundaries and sorted non-overlapping ranges. Nothing is written or published.
Capture is lexical only; parse/admission and semantic equivalence are not claimed.

[Contract/API](docs/PSC1_LOSSLESS_SOURCE.md),
[exact qualification receipt](docs/PSC1_LOSSLESS_SOURCE_QUALIFICATION_2026-10-25.json).
Linux focused run 40191237137/job 121162499744 PASSED: 358 captures, 49 refusal
cases, deterministic delimiter mixtures, bounded large trivia and exact capture
of all 121 compiler modules under both lexers. Helper maximum wall time is 355ms;
max RSS is 160,280 KiB. Artifact 12598640604 ZIP SHA256
ecd89e8f997ae1b78dd30f453f2099ba1c3800b6867786e781aba59b18192517
contains helper SHA256 and per-source identities/measurements.
The required development dependency independently passes at the identical PR
merge tree (job 121162707713; 359ms, 159,444 KiB).

[Ordinary development run 40191245319](https://github.com/dwijayuda/pskernel/actions/runs/40191245319)
PASSED, including every selected dependency and full finite-contract qualification:
37/37 qualified, zero blocked. Seven native backend mappings, both grammars,
independent official checking, strict IR, negative/resource policies, minimum Python
and installed native/source-library regressions remain required and pass.
The receipt owns job IDs, artifact identities and the exact tested tree.

The 121-module unified closure remains exactly
7a49ccbd8b11d029e54fa0d78da9e8fe66943193cc73d00c29b4ed392126a000.
The new sidecar is outside that import closure; all existing semantic source,
packaged host/payload inputs and original supervisor/profile files are unchanged.
No frozen generation chain, npm tarball or compiler-source promotion is relabeled.

The new helper alone uses 1 MiB input, 262,144 pieces, 32 MiB response, 4,096 edits,
240s, 4 GiB virtual address space, an 8 MiB main process stack and no task workers.
Run 40190581290 diagnoses official runtime mandatory libuv thread initialization:
1/2 GiB address-space probes fail while 4 GiB starts. Virtual stack reservation
does not represent resident memory. Existing compiler/checker limits are unchanged.

Tracked diagnostic defect: psLexReadCharacterBody's malformed-literal branch
advances the close character without first advancing the body character.
Apostrophe/U+1F600/U+03B1 retains an unterminatedCharacter stop offset 3 inside the
emoji. Run 40190697846 exposed the class through delimiter mixtures. R1 preserves
the original diagnostic as advisory metadata and marks its coordinates unverified.
Token/trivia/edit spans always require exact boundaries. Correcting the production
lexer needs its own source qualification; it is not silently changed here.

Remaining R2: resolved declaration/binder identities and capture-avoiding rename,
affected-closure elaboration, independent admission, public API/identity comparison.
R3/R4 keep explicit conversion/equivalence and behavioral obligations. No installed
refactoring CLI, automatic filesystem edit, semantic equivalence or non-Linux
developer-tool qualification is claimed.

## Preserved PR #181 readability slice

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
That checkpoint was the first maintenance slice. The additive R1 lexical
foundation is described above; binding-aware rename, semantic source editing,
broad language extensions and a generalized plugin framework remain unimplemented.

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
invariants; use the qualified R1 byte capture and establish resolved identities
before broad automatic source conversion or rename. Preserve the advisory
legacy-diagnostic boundary until its production fix has separate qualification. Do not replace workers with shorter forms
without correspondence/resource evidence. Existing source-shape guards remain
required until equivalent protection is explicitly qualified.

Product work remains source-package/application coverage, portable publication,
checked non-JS/provider dispatch, additional Rust platforms and final release
qualification. New compiler-source promotion needs its own generation evidence;
unchanged frozen packages do not require repeated long chains for documentation.
