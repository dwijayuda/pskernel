# Core environment closure audit and manifest contract

## Current evidence

The [machine-readable ledger](PSC0_CORE_STANDARD_MANIFEST.json) records measured source evidence and deliberately unqualified candidate profiles. It is not a loadable or authenticated environment manifest. The [retained source/blob inventory](PSC0_CORE_SOURCE_AUDIT.json) records both exact Stage0 and the refactored candidate, including every module in the seven-root closure. The complete source report is reproducible with [core-first-source-audit.py](../scripts/core-first-source-audit.py) and retained in the [Linux source inventory artifact](https://github.com/dwijayuda/pskernel/actions/runs/39178166346).

Stage0's seven portable roots reach 316 modules and 26,384,235 bytes. The 101 environment modules contribute 23,654,198 bytes. The actual closure imports SelfHostProd and StandardSnapshot; choosing the named “Core” prefix inside SelfHostProd would still import its Full assets. The legacy bootstrap constructor also contains primitive/axiom boundaries that must not be relabeled as a newly qualified Core.

## Heavy source assets at exact Stage0

These are Git blob bytes and authenticated content identities, not installed npm sizes.

| Asset | Bytes | Git blob SHA |
| --- | ---: | --- |
| StandardFloatOperationsData.lean | 11,179,796 | 9d0d6330875315aab2fc931dd37ac9f0785d676d |
| StandardUnsignedOperationsData.lean | 6,457,592 | f18badbaa052e191efad830441fa67c7c4d7902d |
| StandardPartialFixpointData.lean | 1,574,504 | 669948bc6fcbda80ae3ad34b64a737350e85f3e0 |
| StandardPlatformWordsData.lean | 773,868 | 4d2a5adad206f2d3a643495e9c6b342d326ceb91 |
| StandardFloatConversionsData.lean | 620,103 | 2b2a085e58158c3213fcc938a2a2008bda11c1f1 |
| StandardWellFoundedData.lean | 466,947 | 43ed069f2e2d58da49a2fed3ce0ff98ef1872733 |

The source audit measures all six bytes/hashes from Linux checkouts; the ledger also preserves SHA-256. These files remain in the repository. Opt-in distribution must remove their transitive default imports and package payloads without discarding required proofs.

UInt32/UInt64 operations are actual compiler hash/byte dependencies. Their proof closure includes well-founded declarations even though the compiler source has no termination_by clause. Unsigned and WF therefore cannot be classified wholly optional from names or source tokens. Float, platform and P1 are candidates for separate compositions only after actual typed workload closure confirms their exclusion.

## Three profile contracts

| Profile | Required content | Current status |
| --- | --- | --- |
| Bootstrap | The smallest measured dependency-complete environment capable of compiling the entire authoritative compiler workload | The 76-declaration root is an independently checked seed component; compiler sufficiency and complete profile identity remain open |
| Core | Bootstrap plus the frozen essential general-purpose application contract, complete metadata, runtime and applicable targets | Native dependency reachability is measured; no compiler-complete or application-default Core identity is selected |
| Full | Core plus explicitly selected checked optional library/capability compositions | Existing qualified Full identity is preserved; compatibility/inclusion with new native candidates is not assumed |

The target Bootstrap ⊆ Core ⊆ Full requires exact per-name kind/type/value/family/rule/reducibility/registration compatibility. Root-list inclusion is insufficient. If a new native candidate collides with an older Full primitive or handwritten declaration, report and review that migration before selecting the profile; preserve the old Full identity until its own qualification succeeds.

## Candidate authoring and typed dependency ownership

The native candidate authorer uses the existing pinned StandardExport owner. Both Bootstrap and byte/word probes pass `boundary := []` and `baseDeclarations := []`. The exporter collects native checked declarations, converts them, replays them into a fresh kernel, and compares regenerated constructor/recursor/quotient signatures and recursor rules. It preserves provenance and notices in generated data, whose only repository import is generic Environment.Basic.

The first Linux export at a34686fa independently checked 76 Bootstrap declarations with no axioms and compared 24 recursor rules; generated source is 118,573 bytes. The byte/word export independently checked 1,945 declarations with actual propext/Quot.sound and compared 113 rules; its source is 16,111,994 bytes. These successful authoring results establish neither literal inclusion nor a complete Core source/runtime profile.

The Bootstrap probe declares 26 explicit family/function seed roots and allows no logical assumptions. The byte/word probe adds the measured UInt8/UInt32/UInt64, ByteArray and String.toUTF8 roots and permits only propext/Quot.sound. Those are candidate policies; the report must state the actual reached assumptions and failures. They are not the complete compiler Standard.

The implemented compiler-owned native audit loads exactly the seven portable import roots, identifies source declaration owners through pinned Lean module metadata, and collects constants from actual checked types, bodies, family metadata and rule bodies. It includes private/generated helpers, preserves structural names, retains raw annotations and unsafe/partial entries, and compares its source module roster with the independent source scan. Quoted PsExpr names are data, not native dependency roots.

An export from that measured roster may not trim inconvenient roots. It must first record the complete graph, refuse unapproved assumptions or unsupported unsafe/partial declarations, and retain the failing path. A conversion or deliberate selected runtime model requires its own review and checking, not an unexplained exception.

## Measured extraction and seed identity

At `9f06af4cad58fd10c4224a52cd89e38a2a753b51`, [CI39180799552](https://github.com/dwijayuda/pskernel/actions/runs/39180799552) measured the actual new source boundaries:

| Root or composition | Modules | Source bytes | Scope |
| --- | ---: | ---: | --- |
| Engine | 113 | 1,705,386 | No Full, host or unresolved project import |
| Selected Pscv0Engine | 159 | 2,211,770 | Actual selected readers and Command, with the same isolation |
| Selected engine plus existing IR/codegen/backend roots | 223 | 2,765,757 | Candidate import graph; excludes the existing Full-bound project loader |
| Existing full portable composition | 321 | 26,398,392 | Preserved route still contains SelfHostProd and StandardSnapshot |
| Bootstrap root at `93107e` | 11 | 151,539 | Includes its 118,573-byte asset and generic data owners; no Full or external source import |

These rows compare explicitly different roots. They are not package size, complete compiler reduction or performance claims.

The typed audit of the full 321-module route identifies 191,611 source-owned native declarations, including generated/private/shared-node helpers, and 458 actual external roots. Their raw native dependency closure contains 5,690 declarations with exactly propext, Classical.choice and Quot.sound, and no unsafe or partial entries. Its JSON SHA-256 is `4fbd45b30ffbbb1c98f0da415d09d7b32abeea65ac37d62e2bea181096aeb02c`; [the authoring observation](core-first-evidence/9f06-authoring.json) retains the receipt. This is reachability, not independent Core candidate admission or proof of executable erasure. Classical.choice remains globally permitted only in the approved logical role; the stricter compiler-candidate exporter currently permits only propext/Quot.sound and is not automatically run. Raw assumption paths require review before selecting that profile.

The Bootstrap seed is saved as [BootstrapData](../packages/environment/src/Ps/Environment/BootstrapData.lean) and composed by [Bootstrap](../packages/environment/src/Ps/Environment/Bootstrap.lean). Source SHA-256 is `05fd8f7917054c52b66d8d448bdeeb8e9071fcd6d21d0a6ded088a758628da54`, Git blob `39c8e193ef2e48869c4757b6526a22c4adc82b12`. Independent finite replay at `93107e` measured a 49,889-byte logical payload, SHA-256 `8b89d77e562378015e70d95560735e5727994016615255c84842eab190dae041`, FNV64 `15218654452277382292`.

The seed contains 20 inductives, 24 constructors, 20 recursors, eleven definitions and one theorem; all eleven definition reducibility entries are preserved. It installs no class/instance/alias registry. The corrected native metadata report identifies `Decidable` and `Nonempty` as classes, both registered in Full and absent from the seed registries. This native metadata observation does not establish selected source registration.

The final [e059 qualification](core-first-evidence/e059-qualification.json) passed all four Linux jobs and reproduced the complete Bootstrap manifest byte for byte. Its [literal Full comparison](core-first-evidence/bootstrap-full-compatibility.json) finds 73 names present, 42 declarations completely identical, 31 present declarations with literal differences and three absent names: `PEmpty`, `PEmpty.rec` and `Bool.Reflects.match_1`. All 73 present names retain matching family, reducibility and noncomputable metadata. Semantic equivalence is undecided; literal inclusion of the current seed in the current Full environment fails.

The seed identity and empty assumption closure are measured only for these 76 declarations. The compiler-sufficient Bootstrap profile, including its actual assumptions and exact approved subset of the global logical policy, remains unqualified. Its complete source/runtime identity is not assigned.

## Admission and complete identity gates

A selected manifest must include canonical declarations; constructor/recursor rules; type/proof/body dependency edges; aliases and reducibility; class parameters; ordinary/default instance names and priorities; actual assumption closure; primitive signatures and runtime implementation correspondence; toolchain/checker/resource identity; capability/source/module interfaces; target ABI and word size. Preserve list order where semantically meaningful.

The generic Fingerprint leaf preserves existing logical serialization; it does not by itself encode every profile contract above. New profile identity must bind all relevant components and be independently measured before any expected digest is frozen.

The same authorized context must drive source elaboration, preparation, admissions, project interfaces, cache validation, erasure and backend emission. Reject a Full-only name/instance/primitive under Core, then verify it only succeeds under an explicitly checked optional composition. Reject forged labels/digests, changed prepared metadata, missing dependencies, wrong provider/assumptions, ABI/word-size mismatch and a cache entry from another profile.

## Separate closure claims

Source/import isolation, native declaration reachability, successful independent replay, runtime correspondence, actual selected-source compatibility, package isolation and selfhost are separate observations. The manifest never promotes one observation into another. New pins remain null until the corresponding reproducible qualification has passed.
