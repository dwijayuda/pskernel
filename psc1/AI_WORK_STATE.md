# PSC1 AI work state

Updated 2026-10-25 Asia/Jakarta. Active checked-conversion branch
`feat/psc1-checked-source-conversion-20261025`, stacked on PR #184 implementation
`a77ec1a8153d94ff8586a3dfa37df521e75df501`.
Use connected GitHub and Linux Actions only. Refresh HEAD before writes and use
single-parent expected-HEAD non-force updates. No merge or npm publication.

## Checked conversion (R3; implemented, qualification in progress)

The host reuses the existing grammar printers and R2a ownership pipeline. It
independently admits the complete before/after closures and requires literal equality of privately retained
canonical admission strings and original strict-IR bytes, partial names and exact source/member
ownership. The ordinary logical/body pairing remains included in the comparison.
[Conversion guide](docs/PSC1_CHECKED_SOURCE_CONVERSION.md). Candidate source bytes and declaration origin maps are returned for review;
project files are never edited. This does not implement binding-aware rename.

Raw comments retain their order and bytes. The default refuses comments inside
declaration bodies; explicit owner-notes relocates them to the owning declaration's
leading notes. Canonical conversion intentionally changes layout, spelling and
source identities. Exact graph comparison is a finite compiler-mediated relation,
not formal source preservation or an effect-equivalence theorem.

A manifest-pinned developer CLI emits candidate JSON only. It does not select
tools from source input, publish packages or install new compiler payloads.
Native/shared-host build fccd4e01fa4ce6a01eeafde75032720b95493211 passes in Linux
run 40201874043/job 121194564980. Focused run 40202304083 passes ten conversion cases and eleven refusals,
including an independently accepted but semantically different candidate, and CLI
operation outside the repository cwd. Full qualification stops at a test-fixture
source-root layout error; that entry is corrected without changing the compiler.
Real application and full compiler conversion qualification remains in progress.

## R2a declaration ownership (implemented, qualification in progress)

Native implementation 9f6291450e431931bf42a3833b3fb7718fa5ad37 compiles in Linux
run 40199953080/job 121188821962. Host implementation
6c31f8fe5daea009c5a9af98f8abf873470f2aca adds an opaque read-only ownership index
over genuine R1 lexical capabilities, exact closure/source identities and actual
elaboration batches. It retains numeric/string Core-name components, batch roles,
source spans, name token-piece IDs and normalization ownership. The production
frontend, elaborator, seven backend emitters and frozen packages are unchanged.

The native adapter calls the existing origin-aware preparation and ordinary/
checked preparation, then strict IR validation. The host pins both helper and
independent official Lean checker; it admits exact candidate graph bytes before
returning an index. Tooling does not grant rename, reference-resolution,
semantic-equivalence or publication authority. This is not R2b.

Expanded focused run 40200895349/job 121191660829 PASSED at a77ec1a8:
121 modules and 4,676 members under both grammars, ten exact production-path
admission/IR comparisons, 42 refusal cases and the original 359/49 lossless corpus.
Native phase timings are 59,974ms/339,156KiB (Lean) and 62,098ms/398,296KiB (PS);
these exclude separate checker/host overhead. Ordinary run 40200961302 remains
in progress, so final R2a qualification is not yet claimed.
The selected ordinary lossless job now requires those tests without removing
existing lexical or character-proof regressions. Existing timeout, checker,
fuel, memory and stack policies remain unchanged.

## Qualified character-diagnostic prerequisite

Implementation `d70221c9b26827fba48ff5e85224f6a170fc0904`, tested merge
`cffaa232709d3b49061bd04a06eea7761fb364d4`, identical tree
`4362ebb25ae7070e64ef4402cc7be9d0a7234f17`.

The sole production expression in Lexer.lean now advances actual body then
following scalar before refusing a malformed unescaped character. Apostrophe,
U+1F600 and U+03B1 stops at byte 7 instead of byte 3 inside the emoji. All other
120 unified module bytes and frozen package/resource inputs retain their identities.
The corrected 121-module closure is
`60dd756e29cf6fbd44386e342318c53b22f41f2f3beb21b05aa39505a366271a`.

Two ordinary Lean 4.35 kernel checked leaf theorems preserve exact successful
results and error constructor/reason after erasing diagnostic spans, and establish
actual-prefix cursor advancement. An immutable baseline-leaf byte guard runs in
the selected development lossless job with the theorem target. No axiom, unsafe
shortcut, admission exemption or budget increase is introduced. This is scoped
leaf evidence, not whole-compiler formal preservation or a universal position theorem.

[Correction guide](docs/PSC1_CHARACTER_DIAGNOSTICS.md),
[exact receipt](docs/PSC1_CHARACTER_DIAGNOSTIC_QUALIFICATION_2026-10-25.json).
Focused run 40195964028/job 121176735555 PASSED: 664 position cases, 359 native
helper captures and 49 refusals, plus positive older advisory-wire compatibility.
Maximum helper wall time 360ms, RSS 159,684 KiB. Old unverified diagnostics remain
advisory and cannot become token/trivia/edit ranges. Snapshot authority is unchanged.

Genuine new-source Wasm G1 run 40196021448/job 121177024041 PASSED: 121 modules
under both grammar censuses, 40 cross-target cases and nine envelope refusals.
Request `029b66ba18badad54172e22825f8e299bcc6b050` differs from implementation
only in the manual workflow branch guard and request. All G1/tool/corpus limits
remain 240s. No new G2/G3, fixed point, package promotion or performance-target
qualification is claimed.

Ordinary development run 40196244138 passes every selected dependency and 37/37 finite Practical Core criteria, zero blocked (releaseReady=true).
The receipt records exact selected jobs, artifacts and finite-contract evidence.
Documentation-only descendants carry this successful source baseline through the existing dependency selector. Verify their final static gate before reporting HEAD complete.

## Immediate continuation

The location prerequisite is complete. Next R2a attaches existing actual
`PsElabBatchOrigin` / `PsElabMemberOrigin` to exact source snapshots through
`psCompilerPreparationStepParsedWithOrigins`; do not add a second elaborator.
Finite criteria are in the refactoring architecture and the roadmap owns the
single dependency-ordered queue. R2a is read-only ownership, not rename.
Then R2b must trace local binders/references at actual resolution sites; context-local
raw IDs are not stable global source identities. Only after that implement
capture-avoiding edits with affected-closure elaboration, independent admission
and explicit public API/identity correspondence. R2a/R2b are still pending.
Preserve all previous generation/package identities and existing source proof guards.

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

Historical R1 diagnostic defect: run 40190697846 exposed
psLexReadCharacterBody advancing the close character without first advancing
the body. Its original apostrophe/U+1F600/U+03B1 stop is byte 3 inside the emoji.
The separately qualified correction at the top of this document repairs the
current lexer; the original R1 receipt still describes its unchanged baseline.
Older-helper diagnostics remain advisory with coordinates marked unverified.
Token/trivia/edit spans always require exact boundaries.

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

## Preserved PR #181 validation

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

PR #181 source closure (before the current diagnostic correction):
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
legacy-helper diagnostic boundary after the separately qualified production fix. Do not replace workers with shorter forms
without correspondence/resource evidence. Existing source-shape guards remain
required until equivalent protection is explicitly qualified.

Product work remains source-package/application coverage, portable publication,
checked non-JS/provider dispatch, additional Rust platforms and final release
qualification. New compiler-source promotion needs its own generation evidence;
unchanged frozen packages do not require repeated long chains for documentation.

## Development test scheduling for source tools

Current-source ownership correspondence and negative tests remain ordinary CI
requirements. Fixed 121-module/digest and no-production-change assertions belong
to the dated milestone workflow, not every future compiler change. Dedicated
conversion/native build caches use exact Lean source/toolchain/Lake identities
and still run Lake dependency validation. Documentation-only pushes do not run
these dedicated expensive suites. The aggregate lossless/ownership/conversion
job allows 20 minutes for additional suites; each compiler request remains 240s,
the checker 120s and original memory/stack/fuel policies are unchanged.

## Diagnosed Lean printer scope blocker

Run 40202979940 at 420e647b passes focused conversion and the real 11-module
CLI/JSON application (native compilation and actual file IO), and complete
Lean-to-PS compiler conversion. PS-to-Lean then refuses Ps.Syntax.Token /
psTokenKindEq with matchNonExhaustive: fixed-column nested alternatives escape
into their enclosing match. This is a genuine printer/layout defect; no parser
or checker refusal is relaxed. The fix threads indentation through the existing
printer, groups low-precedence embedding positions and preserves the public fuel
entry point. New tests compare actual independently checked admission/IR bytes
and compile printed fixtures with official Lean 4.35 source parsing. Qualification
of this compiler-source change and new-source G1 are pending. Frozen packaged
compiler generations and qualified PR #184 source remain unchanged.

The new scope/official-Lean source tests pass in ordinary run 40204771123.
Dedicated run 40204767954 stops first on an archived do test that expected parse
refusal from the pre-Practical-Core grammar. The same Nat-result/non-effect case
is now required to refuse with doUnsupportedEffect during elaboration. Typed Id
do and ordinary explicit higher-order calls keep separate roundtrip tests.
No unsupported effect is admitted and no production parser/elaborator changes.

Whole-source run 40205234865 exposes structuralRecursionArity in the new printer
worker, despite passing the official-Lean/layout fixtures and real application.
The fix applies the structurally recursive fold to fuel alone, then passes
indentation through its returned worker. This retains the existing PSC1 arity
restriction instead of widening the language. Dedicated CI now checks both
real source censuses before long conversion workloads. New source identity and
fresh generated G1 must pass before qualification; prior receipts remain scoped.
