# Core qualification and risk ledger

## Qualified baseline and preserved candidate

Stage0 is `33676076bcda7b0de5ec1f9803f49b8b1d28a058` on `psc0/pscv0-v7-native-lean-v1`, tree `87b8b0af6c72f5e8b28af97f9f990e28f73ac56e`. Fresh ref and PR checks at 2026-10-19 01:19 UTC found PR #109 open, draft and unmerged, with this same head.

| Existing Stage0 gate | Run | Result |
| --- | --- | --- |
| Native | [39099546592](https://github.com/dwijayuda/pskernel/actions/runs/39099546592) | Success |
| M3 | [39099546513](https://github.com/dwijayuda/pskernel/actions/runs/39099546513) | Success |
| F1 canonical model | [39099546493](https://github.com/dwijayuda/pskernel/actions/runs/39099546493) | Success |
| F2 | [39099546574](https://github.com/dwijayuda/pskernel/actions/runs/39099546574) | Success |
| F3 | [39099546446](https://github.com/dwijayuda/pskernel/actions/runs/39099546446) | Success |

These five successes share the exact Stage0 SHA. They retain their original scope; they do not qualify the new Core branch.

Full preparation `bf496ce399d9ec39794d6e9f7c3be919dfcffa58` is preserved separately. [Run 39176676179](https://github.com/dwijayuda/pskernel/actions/runs/39176676179) passed Option-bind and recursor authoring; foundation compilation failed in new fixtures. Shared Data/Pattern/Deriving and opaque P1 implementation code compiled, but the new behavior matrix did not run. All six Full exit cells remain open. No Full candidate is silently promoted into Core.

## Initial Core receipts

| Exact candidate / run | Observation | Qualification limit |
| --- | --- | --- |
| `880facd5`, [39177571852](https://github.com/dwijayuda/pskernel/actions/runs/39177571852) | Source audit refused duplicate current/legacy module owners | Inventory implementation defect, corrected by canonical source-owner mapping |
| `851faf84`, [39178166346](https://github.com/dwijayuda/pskernel/actions/runs/39178166346), source job 117825066237 | Complete explicit source graph and both seam import guards pass | Native jobs stopped before build because runner lacked rg; no native result at this SHA |
| `a34686fa`, [39178265318](https://github.com/dwijayuda/pskernel/actions/runs/39178265318), jobs 117825360006/117825360002 | Source inventory and isolated fingerprint/replay probe pass | Fresh-kernel declarations are the bounded probe, not a selected Bootstrap/Core Standard |
| Same run, candidate-authoring job 117825359808 | Full compatibility and both empty-boundary authoring probes pass | Checked candidate declarations; no selected Core profile or literal inclusion claim |

The seam test computes two SHA-256 vectors, resolves an out-of-order dependency during fresh replay, confirms no Nat prelude leaked into the kernel, and refuses an ill-typed definition. Generic replay defaults remain 2,000,000 heartbeats and 20,000 recursion depth. The existing reviewed Full import wrapper retains its unchanged 0/0 kernel import policy; this is checked insertion, not unchecked admission.

## Qualified initial Core environment and frontend slice

[Draft PR #151](https://github.com/dwijayuda/pskernel/pull/151) preserves the Core candidate separately from qualified Stage0 and unfinished Full M3 preparation.

All four jobs of [run 39181815014](https://github.com/dwijayuda/pskernel/actions/runs/39181815014) passed at exact `93107eab14b7347f9605b1396c7a79f2b628ba61`:

| Job | Result and bounded scope |
| --- | --- |
| source-inventory 117835978775 | Complete source/blob inventory; zero Full/unresolved imports for every isolated root |
| native-seams 117835978577 | Engine and actual selected .lean/.ps routes, retained canonical graph, finite official-kernel admission and source/phase refusals |
| bootstrap-closure 117835978751 | Cold independent build, exact 76-declaration trust-zero replay, family metadata, 24 regenerated rules, eleven reducibility entries and measured identity |
| candidate-authoring 117835978684 | Native ownership/closure, typed mutation controls, unchanged Full native compatibility, native asset reproduction and literal seed-versus-Full comparison |

The expanded test at `9f06af4c`, run 39180799552, first failed at an incorrect expectation that environment insertion performs kernel admission. The compiler had retained the real dependency. A probe-only correction checks the same decoded canonical graph under an empty trust-zero kernel and requires exactly the missing base constant. Engine implementation, positive admission, finite limits and other negative controls were unchanged. The corrected probe and selected-source test passed at `93107e`.

The selected-source test uses a previously independently checked one-declaration base and a small namespace/copy/twice program. It verifies the two applications remain in the actual body, exact canonical equality of the selected input forms, independent finite admission and no Nat fallback. Its ordinary checked result does not claim compiler-source conversion, project/cache authentication or emitted backend execution.

### Final metadata correction and complete requalification

All four jobs of [run 39183454255](https://github.com/dwijayuda/pskernel/actions/runs/39183454255) passed at `e059098683d3388fc9f893ec12027b4998eafd52`, tree `bc0cffc2ab7ad51bb133bc8943602c10b6afd29f`. The run completed at 2026-10-19 01:08:19 UTC. [The retained receipt](core-first-evidence/e059-qualification.json) records exact resources and scope.

| Job | Result |
| --- | --- |
| [source-inventory 117840891994](https://github.com/dwijayuda/pskernel/actions/runs/39183454255/job/117840891994) | Success; same measured source boundaries and asset identities |
| [native-seams 117840891940](https://github.com/dwijayuda/pskernel/actions/runs/39183454255/job/117840891940) | Success; fingerprint, Engine and actual paired selected-source controls |
| [bootstrap-closure 117840891809](https://github.com/dwijayuda/pskernel/actions/runs/39183454255/job/117840891809) | Success; raw replay manifest is byte for byte identical to the previous successful run |
| [candidate-authoring 117840892112](https://github.com/dwijayuda/pskernel/actions/runs/39183454255/job/117840892112) | Success; native controls, unchanged Full identity, source reproduction and corrected class metadata |

The native class query at `93107e` had imported Init without loading its environment extensions. The final correction uses a separate initialized `Init` import with `loadExts := true` only for class and output-parameter reporting. It does not change declaration export, kernel admission, seed contents or source registry selection.

The corrected report contains exactly two native classes, `Decidable` and `Nonempty`. Both have empty native output-parameter and output-level lists; both are registered in Full and absent from the Bootstrap registries. Full has no explicit class-parameter record for `Decidable` and has an explicit empty record for `Nonempty`. Native `Nonempty` remains an inductive, not a structure. The only changed report fields are the class rows and the new `nativeClassMetadataExtensionsLoaded: true` flag; all 76 declaration-comparison rows are identical.

Bootstrap source remains 118,573 bytes with SHA-256 `05fd8f7917054c52b66d8d448bdeeb8e9071fcd6d21d0a6ded088a758628da54`; the complete raw manifest, 49,889-byte payload and both logical hashes are unchanged. The byte/word source and raw native closure hashes are also unchanged. This is the latest code qualification; a documentation/evidence-only descendant is not a new same-SHA CI receipt.

## Independently authored candidate results

All three jobs in run 39178265318 succeeded at exact `a34686faa951f1b3ac8add59162d5dcb90d5c3ea`. The Full native tests retained 3,757 declarations, 44 classes, 371 ordinary instances and the original FNV/SHA identities, with source/module/deriving/instance/refusal checks passing.

| Candidate from an empty boundary | Checked declarations | Actual axioms | Compared recursor rules | Generated source bytes |
| --- | ---: | --- | ---: | ---: |
| Bootstrap | 76 | None | 24 | 118,573 |
| Byte/word | 1,945 | propext, Quot.sound | 113 | 16,111,994 |

The byte/word source size is substantial. It is not a tiny Core package, the full compiler dependency closure, or an installed/runtime measurement. The exact Bootstrap source is now committed and reproduced byte for byte; the independent replay records its seed identity in [PSC0_BOOTSTRAP_SEED_MANIFEST.json](PSC0_BOOTSTRAP_SEED_MANIFEST.json). The full compiler-sufficient Bootstrap profile remains unqualified.

Engine, selected Pscv0Engine and all 24 unchanged deriving expression builders are now committed and passed the focused source/admission gates. No whole Core milestone or selfhost stage is closed by this receipt.

## Measured baseline and open metrics

| Metric | Observed value / recipe | Scope |
| --- | --- | --- |
| Stage0 portable source | 316 modules; 26,384,235 bytes | Complete explicit seven-root graph |
| Stage0 environment source | 101 modules; 23,654,198 bytes | Included in portable total |
| Fingerprint seam at `851faf84` | 10 modules; 46,242 bytes | No Standard/Prelude import |
| Native Replay seam at `851faf84` | 12 repository modules; 50,030 bytes; explicit Lean import | Host replay, not portable kernel selfhost |
| Engine at `9f06af4c` / `93107e` | 113 modules; 1,705,386 bytes | Actual isolated source graph |
| Selected Pscv0Engine | 159 modules; 2,211,770 bytes | Actual selected single-source graph |
| Selected engine plus actual backend/IR roots | 223 modules; 2,765,757 bytes | Excludes existing project loader; not complete compiler size |
| Bootstrap root | 11 modules; 151,539 bytes | Includes exact seed asset; no Full import |
| Bootstrap cold native build at `93107e` | 10.34s; max RSS 1,643,232 KiB; 35 Lake jobs | GNU time of lake build; excludes toolchain installation |
| Bootstrap replay at `93107e` | 0.56s; max RSS 844,992 KiB | Command also imports native Init metadata; not a kernel-only or application benchmark |
| Native build resources | GNU /usr/bin/time -v files and retained JSON observations | Engine/selected builds are sequential incremental targets within a cold job; shared runner variation prevents a speedup inference |
| Generated artifacts | SHA-256 and file bytes recorded for seam executable; candidate source hashes after successful exports | Neither size is a complete Core compiler release |
| npm archives / installed dependencies | Unmeasured | Requires genuinely separated packages and a fixed clean install recipe |
| Core speedup / completion percentage | No claim | Source graph reductions do not establish runtime performance or milestone completion |

Source audit JSON includes per-module paths, imports, byte counts, content hashes, feature signals, package manifests and separate hypothetical-root results. Complete native raw graphs remain CI artifacts retained for 30 days; immutable source commits and the recipe allow reproduction. The committed source/blob inventory, exact Bootstrap asset/manifest, literal Full comparison, native assumption paths and resource observations preserve the bounded findings independently of artifact expiry. Selected environment pins cannot rely solely on expiring artifacts.

## Literal inclusion and assumption-path findings

The [seed-versus-Full report](core-first-evidence/bootstrap-full-compatibility.json) authenticates every rendered seed declaration against its actual pinned native declaration, then compares complete literal kind/levels/type/body/proof/family metadata and environment status with Full. Independent reconstruction of all 76 canonical declaration hashes and the complete payload produced no mismatch.

There are 73 seed names present in Full, of which 42 declarations are fully identical. All 73 present names have matching family metadata, effective/explicit reducibility and noncomputable flags. The other 31 present declarations differ in literal type, universe-parameter, body/proof or kind fields. PEmpty, PEmpty.rec and Bool.Reflects.match_1 are absent. Decidable.reflects_decide is a native theorem but a Full definition. These observations do not decide semantic equivalence; they do refute literal inclusion of the current seed in the current Full environment. Preserve both versions and qualify a migration before selecting nested profiles.

The full native compiler audit reaches 5,690 external declarations from 458 real external roots in 321 source-owned modules. All three approved logical assumptions are reached, with no unsafe/partial entry in that raw closure. [Recorded paths](core-first-evidence/native-assumption-paths.json) show that Classical.choice is reachable from 24 external roots, including the current SHA padding while implementation, String slicing/search and integer order metadata. The sampled paths include theorem dependencies; a raw path is not an erasure proof and does not authorize runtime choice. The compiler candidate exporter remains narrower (propext/Quot.sound only) and is not automatically run or granted exceptions.

## Focused gates and concrete remaining risks

| Gate | Required next evidence | Current blocker / safeguard |
| --- | --- | --- |
| Bootstrap closure | Checked 76-declaration seed is complete at its recorded scope; next measure the compiler-sufficient closure and source registrations | Seed qualification is not whole-compiler sufficiency |
| Core Standard | Typed graph is measured; next qualify selected declarations, all proof/type dependencies, inclusion and registration/runtime identity | Byte/word source is 16.1 MB; 34 seed declarations do not match Full literally; native assumption/opaque implementation paths need classification |
| Core frontend/elaboration | Isolated selected single-source seam is qualified; next actual compiler-source admission and exact project/profile threading | Existing project composition remains Full; two native mutual-data groups require selected representations |
| Core execution/backend | Compiler control/closure/error observations, exact primitive and typed erasure/IR, applicable target execution | Word/UTF8/ABI details and runtime selector identity remain explicit |
| Interface/cache | Authorized complete profile identity bound to consumed source, prepared results and module/cache artifacts | A profile record or claimed digest is not authority; reject cross-profile reuse |
| Selfhost | Entire authoritative Stage1–3 source manifest and deterministic/runtime comparison | Historical selfhost or native builds cannot substitute |
| Optional Full modules | Exact optional closure/inclusion, Full regression and installation absence/presence tests | Heavy data remain preserved; no runtime filtering or dependency metadata shortcut |
| Release integration | Applicable Core gates on the exact reviewed candidate and preserved Full regression receipts | No default/release promotion while profile or stage obligations remain open |

Full non-workload P0/P1, general WF/Prop recursion and extended deriving stay in their separate ledger. Core cannot omit a dependency merely because its source token is absent. Ordinary checked output retains its ordinary identity; unavailable verified/model/refinement claims fail.

## Operating rules

GitHub connectors and cloud Linux only for repository work. Refresh refs before writes, use expected HEAD and non-force updates, preserve active/pending CI and concurrent branches, and keep the qualified Stage0 line unchanged until a concrete promotion meets its gates. No larger budgets, hole acceptance, independent-kernel modification or automatic npm publication.

Update both handoff files with the current Core head, exact code/test receipts and next failing owned boundary. Record a negative or unavailable result precisely instead of inventing a pin, size reduction or completion claim.

Documentation and evidence ledgers are not loadable profile inputs and do not trigger native rebuilds. Executable source, generated assets, workflow changes, toolchain and consumed reference identity inputs remain gated. A final evidence-only commit must identify its qualified code ancestor and preserve every executable/test/workflow blob; do not call it a new same-SHA CI run.
