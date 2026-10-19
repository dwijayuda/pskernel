# Core qualification and risk ledger

## Qualified baseline and preserved candidate

Stage0 is `33676076bcda7b0de5ec1f9803f49b8b1d28a058` on `psc0/pscv0-v7-native-lean-v1`, tree `87b8b0af6c72f5e8b28af97f9f990e28f73ac56e`. Fresh ref/PR/run checks at 2026-10-18 23:24 UTC found PR109 open, draft and unmerged, with this same head.

| Existing Stage0 gate | Run | Result |
| --- | --- | --- |
| Native | [39099546592](https://github.com/dwijayuda/pskernel/actions/runs/39099546592) | Success |
| M3 | [39099546513](https://github.com/dwijayuda/pskernel/actions/runs/39099546513) | Success |
| F1 canonical model | [39099546493](https://github.com/dwijayuda/pskernel/actions/runs/39099546493) | Success |
| F2 | [39099546574](https://github.com/dwijayuda/pskernel/actions/runs/39099546574) | Success |
| F3 | [39099546446](https://github.com/dwijayuda/pskernel/actions/runs/39099546446) | Success |

These five successes share the exact Stage0 SHA. They retain their original scope; they do not qualify the new Core branch.

Full preparation `bf496ce399d9ec39794d6e9f7c3be919dfcffa58` is preserved separately. [Run39176676179](https://github.com/dwijayuda/pskernel/actions/runs/39176676179) passed Option-bind and recursor authoring; foundation compilation failed in new fixtures. Shared Data/Pattern/Deriving and opaque P1 implementation code compiled, but the new behavior matrix did not run. All six Full exit cells remain open. No Full candidate is silently promoted into Core.

## Initial Core receipts

| Exact candidate / run | Observation | Qualification limit |
| --- | --- | --- |
| `880facd5`, [39177571852](https://github.com/dwijayuda/pskernel/actions/runs/39177571852) | Source audit refused duplicate current/legacy module owners | Inventory implementation defect, corrected by canonical source-owner mapping |
| `851faf84`, [39178166346](https://github.com/dwijayuda/pskernel/actions/runs/39178166346), source job117825066237 | Complete explicit source graph and both seam import guards pass | Native jobs stopped before build because runner lacked rg; no native result at this SHA |
| `a34686fa`, [39178265318](https://github.com/dwijayuda/pskernel/actions/runs/39178265318), jobs117825360006/117825360002 | Source inventory and isolated fingerprint/replay probe pass | Fresh-kernel declarations are the bounded probe, not a selected Bootstrap/Core Standard |
| Same run, candidate-authoring job117825359808 | Full compatibility and both empty-boundary authoring probes pass | Checked candidate declarations; no selected Core profile or literal inclusion claim |

The seam test computes two SHA-256 vectors, resolves an out-of-order dependency during fresh replay, confirms no Nat prelude leaked into the kernel, and refuses an ill-typed definition. Generic replay defaults remain 2,000,000 heartbeats and 20,000 recursion depth. The existing reviewed Full import wrapper retains its unchanged 0/0 kernel import policy; this is checked insertion, not unchecked admission.

## Independently authored candidate results

All three jobs in run39178265318 succeeded at exact `a34686faa951f1b3ac8add59162d5dcb90d5c3ea`. The Full native tests retained 3,757 declarations, 44 classes, 371 ordinary instances and the original FNV/SHA identities, with source/module/deriving/instance/refusal checks passing.

| Candidate from an empty boundary | Checked declarations | Actual axioms | Compared recursor rules | Generated source bytes |
| --- | ---: | --- | ---: | ---: |
| Bootstrap | 76 | None | 24 | 118,573 |
| Byte/word | 1,945 | propext, Quot.sound | 113 | 16,111,994 |

The byte/word source size is substantial. It is not a tiny Core package, the full compiler dependency closure, or an installed/runtime measurement. The Bootstrap source must be retained unchanged and its explicit composition/metadata replayed before a reusable seed identity is selected.

The next candidate adds Engine, selected Pscv0Engine and 24 unchanged deriving expression builders; its direct context/selected-source and typed ownership gates remain pending CI. No whole Core milestone or selfhost stage is closed by this receipt.

## Measured baseline and open metrics

| Metric | Observed value / recipe | Scope |
| --- | --- | --- |
| Stage0 portable source | 316 modules; 26,384,235 bytes | Complete explicit seven-root graph |
| Stage0 environment source | 101 modules; 23,654,198 bytes | Included in portable total |
| Fingerprint seam at851 | 10 modules; 46,242 bytes | No Standard/Prelude import |
| Native Replay seam at851 | 12 repository modules; 50,030 bytes; explicit Lean import | Host replay, not portable kernel selfhost |
| Native build resources | GNU /usr/bin/time -v files in focused CI artifacts | Actual build observation; cold/warm and process-memory interpretation must be stated |
| Generated artifacts | SHA-256 and file bytes recorded for seam executable; candidate source hashes after successful exports | Neither size is a complete Core compiler release |
| npm archives / installed dependencies | Unmeasured | Requires genuinely separated packages and a fixed clean install recipe |
| Core speedup / completion percentage | No claim | Source graph reductions do not establish runtime performance or milestone completion |

Source audit JSON includes per-module paths, imports, byte counts, content hashes, feature signals, package manifests and separate hypothetical-root results. All generated CI artifacts are retained for 30 days; immutable source commits and this recipe allow reproduction. Selected environment pins cannot rely solely on expiring artifacts.

## Focused gates and concrete remaining risks

| Gate | Required next evidence | Current blocker / safeguard |
| --- | --- | --- |
| Bootstrap closure | Empty-boundary export/replay, exact declarations/family rules/assumptions and metadata | A small seed-root roster alone is insufficient |
| Core Standard | Typed ownership/root graph, full proof/type dependencies, exact inclusion and registration/runtime identity | Unsigned proofs require WF; new native bodies may collide with existing Full declarations |
| Core frontend/elaboration | Isolated selected readers/Command/Engine and actual .lean/.ps compiler-source admission | Deriving helper cuts and explicit selected-context threading; two native mutual-data groups |
| Core execution/backend | Compiler control/closure/error observations, exact primitive and typed erasure/IR, applicable target execution | Word/UTF8/ABI details and runtime selector identity remain explicit |
| Interface/cache | Authorized complete profile identity bound to consumed source, prepared results and module/cache artifacts | A profile record or claimed digest is not authority; reject cross-profile reuse |
| Selfhost | Entire authoritative Stage1–3 source manifest and deterministic/runtime comparison | Historical selfhost or native builds cannot substitute |
| Optional Full modules | Exact optional closure/inclusion, Full regression and installation absence/presence tests | Heavy data remain preserved; no runtime filtering or dependency metadata shortcut |
| Release integration | Applicable Core gates on the exact reviewed candidate and preserved Full regression receipts | No default/release promotion while profile or stage obligations remain open |

Full non-workload P0/P1, general WF/Prop recursion and extended deriving stay in their separate ledger. Core cannot omit a dependency merely because its source token is absent. Ordinary checked output retains its ordinary identity; unavailable verified/model/refinement claims fail.

## Operating rules

GitHub connectors and cloud Linux only for repository work. Refresh refs before writes, use expected HEAD and non-force updates, preserve active/pending CI and concurrent branches, and keep the qualified Stage0 line unchanged until a concrete promotion meets its gates. No larger budgets, hole acceptance, independent-kernel modification or automatic npm publication.

Update both handoff files with the current Core head, exact code/test receipts and next failing owned boundary. Record a negative or unavailable result precisely instead of inventing a pin, size reduction or completion claim.
