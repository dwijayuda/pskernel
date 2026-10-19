# PSC0 work state — Core-first initial environment slice

Updated 19 October 2026, Asia/Jakarta. Active development is isolated on `psc0/core-first-environments-20261019`, [draft PR #151](https://github.com/dwijayuda/pskernel/pull/151), targeting the qualified PSC0 line. Fetch the current ref before every write; never reset it to an earlier receipt.

## Active user direction

The user authorized adapting and executing the Core-first prompt immediately: preserve selected v7.2 and the existing architecture, make actual Core/compiler requirements the M1–M5/A–E exits, keep unrelated Full requirements separate, and prioritize genuine compiler selfhost. Earlier no-Core/no-compiler-selfhost restrictions are superseded. Logical checking, source parity, independent kernel, runtime, repository and branch safeguards remain.

The initial requested deliverables now exist: capability inventory, exact source/native dependency audit, Core roadmap, optional-module/package plan, selfhost plan, qualification/risk ledger and an independently testable environment slice. No full Core milestone or selfhost stage has been declared complete.

Start with [architecture](docs/PSC0_CORE_FIRST_ARCHITECTURE.md), [roadmap](docs/PSC0_CORE_FIRST_ROADMAP.md), [environment ledger](docs/PSC0_CORE_STANDARD_MANIFEST.md), [qualification](docs/PSC0_CORE_QUALIFICATION_LEDGER.md), [capabilities](docs/PSC0_CORE_CAPABILITY_INVENTORY.md) and [selfhost](docs/PSC0_CORE_SELFHOST_PLAN.md). The original roadmap/reference remain unchanged.

## Qualified code and current evidence

Latest qualified code: `e059098683d3388fc9f893ec12027b4998eafd52`, tree `bc0cffc2ab7ad51bb133bc8943602c10b6afd29f`. [Run 39183454255](https://github.com/dwijayuda/pskernel/actions/runs/39183454255) completed successfully on 19 October 2026 at 01:08:19 UTC (08:08:19 Asia/Jakarta). All four jobs passed: source-inventory 117840891994, native-seams 117840891940, bootstrap-closure 117840891809 and candidate-authoring 117840892112.

The final code correction loads native class metadata explicitly for reporting. It finds `Decidable` and `Nonempty`, both unregistered in the Bootstrap seed and registered in Full. All 76 declaration-comparison rows and the complete raw Bootstrap manifest are unchanged from the prior successful run. [Exact qualification evidence](docs/core-first-evidence/e059-qualification.json) records the code SHA, job scopes, identities and measured command resources.

Initial complete slice: `93107eab14b7347f9605b1396c7a79f2b628ba61`, tree `b892380af4a6629f9f39676d1d457ea8f62ad748`, [run 39181815014](https://github.com/dwijayuda/pskernel/actions/runs/39181815014). All four jobs passed: source-inventory 117835978775, native-seams 117835978577, bootstrap-closure 117835978751 and candidate-authoring 117835978684.

A final documentation/evidence commit can follow the qualified code SHA. It must preserve every executable, test, asset and workflow blob; its lack of a new CI run is not a failure or a same-SHA receipt. The workflow excludes non-loadable Core design ledgers from triggers while gating actual source and reference identity inputs.

## Implemented boundaries

- Fingerprint contains unchanged logical serializers/hash bodies; StandardSnapshot retains exact Full pins and audits.
- Replay contains unchanged conversion/admission machinery plus an empty-boundary generic entry; the Full Prelude wrapper retains its reviewed import policy.
- Engine carries actual base environment and runtime selector through preparation and canonical admission generation. Api preserves the Full public interface and defaults.
- Pscv0Engine carries that context through the actual selected .lean/.ps readers and Command. Pscv0 remains the Full wrapper; the existing Pscv0Modules/project/cache path is still Full-bound.
- All 24 Inhabited/Repr expression helpers moved unchanged into generic leaves; their original owners still construct/register the same Full declarations.
- BootstrapData is the exact independently authored asset, composed by Bootstrap without Full imports, native axioms or implicit source registries.
- Linux tests cover actual selected input/canonical correspondence and finite independent admission over a small checked base. Runtime roster tests cover none/32/64 context selection; actual emitted backend execution is a separate gate.

An internal context record is an input, not an authenticated profile token. Environment insertion is not kernel admission. The corrected Engine negative test preserves the exact canonical dependency and requires its precise missing-constant rejection in a fresh official kernel.

## Exact Bootstrap seed evidence

[Manifest](docs/PSC0_BOOTSTRAP_SEED_MANIFEST.json): 76 declarations = 20 inductives + 24 constructors + 20 recursors + 11 definitions + 1 theorem; 11 reducibility entries; 24 regenerated rules; no axioms; empty trust-zero replay; finite 2,000,000/20,000 per-declaration limits.

- Source: 118,573 bytes; SHA256 `05fd8f7917054c52b66d8d448bdeeb8e9071fcd6d21d0a6ded088a758628da54`; Git blob `39c8e193ef2e48869c4757b6526a22c4adc82b12`.
- Logical payload: 49,889 bytes; SHA256 `8b89d77e562378015e70d95560735e5727994016615255c84842eab190dae041`; FNV64 decimal string `15218654452277382292`.
- Native generation reproduces committed source byte for byte. Independent AST reconstruction reproduced both payload hashes and all 76 declaration hashes.
- Preserve the raw manifest numeric FNV token or encode it as a decimal string; JavaScript Number cannot represent this UInt64 exactly.
- Source class/instance/alias registries remain unselected. Bootstrap target means the smallest complete compiler-sufficient environment; this 76-declaration seed is only a component toward it.

The literal [Full comparison](docs/core-first-evidence/bootstrap-full-compatibility.json) has 73 names present and 42 declarations completely equal. All 73 present names have matching family/reducibility/noncomputable metadata; 31 differ in literal type/universe/body/kind. PEmpty, PEmpty.rec and Bool.Reflects.match_1 are absent. Decidable.reflects_decide is a native theorem versus Full definition. No semantic-equivalence or Bootstrap/Core/Full inclusion claim follows. Do not silently normalize or replace declarations to make the report green.

The earlier empty native class roster at `93107e` was an unloaded-extension query. The qualified correction uses a separate initialized Init import for class/output-parameter reporting and finds `Decidable` and `Nonempty`. Both are registered in Full and absent from the seed's class registry; both have empty native output-parameter and output-level lists. The seed and declaration authentication are unchanged.

## Source/native measurements and critical findings

[Source manifest](docs/PSC0_CORE_SOURCE_AUDIT.json) records the complete explicit Stage0 and candidate graphs with per-module paths/imports/bytes/SHA256/Git blobs.

| Measured graph | Modules | Bytes |
| --- | ---: | ---: |
| Exact Stage0 portable roots | 316 | 26,384,235 |
| Refactored existing Full portable route | 321 | 26,398,392 |
| Engine | 113 | 1,705,386 |
| Selected Pscv0Engine | 159 | 2,211,770 |
| Selected engine plus actual backend/IR roots | 223 | 2,765,757 |
| Bootstrap root | 11 | 151,539 |

The 223-module graph excludes the existing project loader and is not a complete selfhost compiler. Source/import size is not installed package size or runtime performance.

Typed native ownership includes 191,611 private/generated/source declarations in 321 modules, 458 external roots and 5,690 raw external closure declarations. Actual axioms are propext/Classical.choice/Quot.sound; unsafe/partial rosters are empty. Raw graph SHA256: `4fbd45b30ffbbb1c98f0da415d09d7b32abeea65ac37d62e2bea181096aeb02c`. [Assumption paths](docs/core-first-evidence/native-assumption-paths.json) include SHA while, String search/slicing and integer order proof dependencies. Reachability does not establish executable erasure or permit runtime choice. The narrower compiler exporter still allows only propext/Quot.sound and is not auto-run.

The independently checked byte/word probe has 1,945 declarations, 113 compared rules, actual propext/Quot.sound and 16,111,994 generated source bytes. Do not call it tiny Core or trim required WF/proof dependencies. Its source SHA256 is `7d61ebb72eb891ab7a39cee3e780411f26219b2fcfa57570effa7d4f127ed17a`. It remains a CI artifact and has not become an installed package.

## Next owned work

1. Resolve exact seed/Full declaration compatibility and required source registries before selecting a nested profile. Record a checked migration; preserve existing Full identities.
2. Extend retained exact environment/runtime identity through project/module interfaces, admission and cache validation. Reject wrong-profile artifacts, changed metadata, omitted dependencies and target/word-size mismatches.
3. Freeze and compile a real selected compiler-source subset, then the entire authoritative compiler. The selected single-source seam is already qualified; do not redo its 24 helper moves.
4. Implement faithful selected representations for Syntax term/do/tactic mutual data and ECMA Expr/Stmt mutual data. Qualify actual fueled mutual functions/deriving; convert the bounded SHA padding while with checked correspondence if selected syntax requires it.
5. Qualify actual runtime/primitive/backend behavior and genuine Stage1–3, then separate npm payloads and measure clean install sizes. Installing a library cannot add parser/elaborator/backend mechanisms.

Core need not wait for unrelated Full P0/P1/general WF/extended deriving exits. It cannot omit a reached dependency merely because no matching token appears in the compiler source.

## Preserved qualified and Full lines

Qualified Stage0 remains `psc0/pscv0-v7-native-lean-v1` at `33676076bcda7b0de5ec1f9803f49b8b1d28a058`, tree `87b8b0af6c72f5e8b28af97f9f990e28f73ac56e`; PR #109 open/draft/unmerged. Original five same-SHA gates: Native 39099546592, M3 39099546513, F1 39099546493, F2 39099546574, F3 39099546446, all success. They retain their original scope and do not qualify a different Core SHA.

Full preparation remains `psc0/m3-fixedpoint-foundation-20261018` at `bf496ce399d9ec39794d6e9f7c3be919dfcffa58`, tree `f75ba7308134ab6be473347aafb5d2788c84b608`. Run 39176676179 failed new fixtures; Option-bind and recursor authoring passed. All six Full exits remain open. Do not copy that unqualified candidate wholesale into Core.

Full native compatibility on Core preserves 3,757 declarations, 44 classes, 371 ordinary instances, 13 defaults, FNV `fnv1a64:3071911941504503432`, logical SHA `sha256:364627b451f83a04064643d29f0fa3bb1bda85eab70d588d3e66755ddc67efe1`. Core CI did not rerun all five broader Full workflows.

## Continuing constraints

Repository work uses connected GitHub and cloud Linux only: no local checkout, repository shell/filesystem work or local compiler builds. Root is sole writer; parallel agents are read-only reviewers. Refresh refs, preserve history, expected SHA, force:false. Preserve healthy qualified-line Native CI and at most one active/one pending Core run.

Canonical v7.2 reference blob `694115223777599ba28ee175e14bb642b7b6aa4b` is unchanged. Lean 4.35.0 commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. Maximum approved logical assumptions: propext, Quot.sound, Classical.choice; actual seed closure is empty. No holes, new axioms, runtime choice, budget expansion, relaxed refusal or unchecked authority. Preserve ordinary/partial/unsafe/verified/model/refinement distinctions, compiler WasmGC internals and explicit ABI boundaries.

PSKernel-Core/C0 and unrelated research/wasm lines are outside this task. Do not change release defaults, publish npm packages or merge incomplete Core into the qualified line. Draft PR #151 is a review surface, not a promotion.
