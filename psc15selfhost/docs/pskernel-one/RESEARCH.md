# Research and traceability ledger

Audit began 2026-10-02 Asia/Jakarta. Every branch is reference material unless
explicitly selected below. No historical document authorizes unrelated work.

## Live state and baseline

All advertised heads were fetched into a separate shallow checkout. Initially
there was no `psc2/pskernel-one` head. The original local checkout contained
uncommitted compiler changes and was left untouched. Open PRs were queried;
none was named pskernel-one. `LIVE_AUDIT.json` records the observed PR list, recent
commits and relevant CI identities. Branch tips are a snapshot, not a lock against
future concurrent changes; remote heads are refreshed before each update.

| Reference | Pinned observed head | Interpretation |
| --- | --- | --- |
| minimal-selfhost-psc15 | 90d02086146fce06df6d0a720e50f340adcbf52a | Selected compiler baseline; preserves source isolation |
| pskernel-core | 71951ebe241033abaaf4afe875d378fd8b49f13b | Earlier foundation; not strongest accepted kernel |
| Phase 12 | b33e63ed6df2ad10a4a350b19af504fca45655f2 | Strongest reviewed accepted portable kernel reference; bounded |
| Phase 13 | daf8e703040ecbbddb27d874c1336d6f6d04050d | Shadow design; assumes prelude headers; no authoritative cutover |
| Phase 13 work chat 2 | ffbd1cccfd8f44dc83e32c4c5cf064aa271ae0eb | Compiler portability changes on separate work branch |
| Lean native provider | 88b18bbcec82bad02cb3db8ee5b5b96cae91ae86 | Latest queried runs failed; not advertised as green |
| Lean Wasm provider | 4dece7df717152e90c8c54009c4aec0709b85a8a | Completed native/Wasm differential and packaged-consumer steps observed |

Phase-12 success run `36690404216` is at `5a33460e6987736516f1b4ab87ad373977daec5d`,
not the later documentation head. Wasm run `36916202568`, job `110550661127`, is
successful at `4dece7df`; its step record includes real provider build,
native/Wasm differential parity and packed npm consumer execution. This is
historical provider evidence, not current pskernel-one evidence.

## Source pin and semantic decisions

The project ORACLE_LOCK, active toolchain and current provider metadata agree
with upstream tag v4.34.0 → `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`.
The vendored `src/kernel/level.cpp` was compared byte-for-byte to that upstream
commit: 18,351 bytes, SHA-256
`7cb927c6fabd9fb843f548443494d3673a08074e26fe32b679e80f4664fc7f25`.
Other source paths in the capability index require further function-level audit;
the successful level-file comparison is not generalized to all vendored sources.

| Decision | Exact reference | Local implementation | Regression/evidence |
| --- | --- | --- | --- |
| Preserve structured name identity | pinned `src/util/name.cpp`; Phase12 `Name.lean` | `Ps.KernelOne.Name` | Name-boundary negative case; broader direct tests pending |
| Reassociation and duplicate max leaves | pinned `src/kernel/level.cpp`: `push_max_args`, `normalize`, `is_equivalent` | `LevelMaxContains`, `LevelMaxSubset`, `LevelEquivalentNormalized` | `LevelTests.lean`: positive/negative cases and 144 ordered pairs |
| Both inclusions required | same normalized max behavior | same functions | missing-parameter cases and reverse ordered pairs |
| Keep incomplete comparison explicit | pinned normalization also handles offset subsumption and successor distribution | `CAPABILITIES.json` | no full-universe claim |
| Differential oracle invokes C++ | pinned `src/Lean/Environment.lean`: extern `lean_kernel_is_def_eq` | host-only `LevelTests.lean` adapter | RED run 36923917657; native GREEN run 36924352252 |
| No assumed-prelude integration | Phase13 design at daf8e703 | no shadow provider ported | admission/prelude remain missing |
| Preserve compiler-only isolation | compiler baseline bootstrap-closure-contract and manifest/source loader | KernelOne `bootstrap:false`, no bootstrap imports | existing closure checks |
| Nat.rec is a value fold | pinned `Init.Prelude` Nat recursor and Nat induction computation | separate compiler IR/erasure/TS change | `NatRecFixture.lean` and real tsc/JS tests; see continuation evidence |

The current level implementation accepts additional true max equalities. It does
not reinterpret absence of a supported proof of equality as full Lean rejection.
Lean4Lean and Kernel Arena were identified as secondary references; neither was
used as authority or executed in this first slice. Full replay remains open.

## Documentation coverage

`branch-docs.json.gz` (gzip-compressed JSON) is reproduced from the repository root by
`node psc15selfhost/scripts/pskernel-one-inventory.mjs` after fetching branch tips.
It records 303 tips, 121,026 document occurrences, 614 unique text blobs and
4,518,186 UTF-8 bytes at the audit snapshot. Text extensions and conventional
README/license names are inventoried and mechanically searched by topic. The
129 binary-document occurrences are listed but not read. Identical text blobs
are deduplicated; occurrence references remain traceable to branch commits.

Closely read material: the complete small Data/Name/Level port; pinned level.cpp
normalization/equality and environment.cpp admission paths; current compiler
preparation/integrity and erasure/emitter code relevant to Nat; compiler baseline
SELFHOST_RESEARCH_2026-10-02.md; source-profile and closure scripts. The architecture,
coordination, Phase12 acceptance, Phase13 design, provider READMEs and continuity
documents received targeted section review. No claim that every document or
every line of the target kernel was studied is made.

## Provenance and licensing

The three initial portable modules are selectively renamed from this repository's
Phase12 sources at b33e63ed. The new max-set comparison is written for KernelOne,
guided by the pinned original normalization law; it is not a wholesale Lean4Lean
port. Original Lean is Apache-2.0 (Microsoft contributors); its license is included
as `packages/pskernel-one/LEAN_LICENSE` for source-reference provenance. This does
not invent a project-wide license for repository-authored code. No Lean4Lean code
or runtime dependency is included. Publication/license review remains open.
