# Core environment closure audit and manifest contract

## Current evidence

The [machine-readable ledger](PSC0_CORE_STANDARD_MANIFEST.json) records measured source evidence and deliberately unqualified candidate profiles. It is not a loadable or authenticated environment manifest. The complete source report is reproducible with [core-first-source-audit.py](../scripts/core-first-source-audit.py) and retained in the [Linux source inventory artifact](https://github.com/dwijayuda/pskernel/actions/runs/39178166346).

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
| Bootstrap | A small exact seed sufficient to admit the first real compiler source subset and its dependencies | Independent empty-boundary authoring probe; no selected Bootstrap identity |
| Core | Dependency-complete Standard and metadata for the entire frozen compiler/bootstrap workload, runtime and applicable targets | Actual native ownership/dependency audit and authoring are separate gates; no selected Core identity |
| Full | Core plus explicitly selected checked optional library/capability compositions | Existing qualified Full identity is preserved; compatibility/inclusion with new native candidates is not assumed |

The target Bootstrap ⊆ Core ⊆ Full requires exact per-name kind/type/value/family/rule/reducibility/registration compatibility. Root-list inclusion is insufficient. If a new native candidate collides with an older Full primitive or handwritten declaration, report and review that migration before selecting the profile; preserve the old Full identity until its own qualification succeeds.

## Candidate authoring and typed dependency ownership

The native candidate authorer uses the existing pinned StandardExport owner. Both Bootstrap and byte/word probes pass `boundary := []` and `baseDeclarations := []`. The exporter collects native checked declarations, converts them, replays them into a fresh kernel, and compares regenerated constructor/recursor/quotient signatures and recursor rules. It preserves provenance and notices in generated data, whose only repository import is generic Environment.Basic.

The first Linux export at a34686fa independently checked 76 Bootstrap declarations with no axioms and compared 24 recursor rules; generated source is 118,573 bytes. The byte/word export independently checked 1,945 declarations with actual propext/Quot.sound and compared 113 rules; its source is 16,111,994 bytes. These successful authoring results establish neither literal inclusion nor a complete Core source/runtime profile.

The Bootstrap probe declares 26 explicit family/function seed roots and allows no logical assumptions. The byte/word probe adds the measured UInt8/UInt32/UInt64, ByteArray and String.toUTF8 roots and permits only propext/Quot.sound. Those are candidate policies; the report must state the actual reached assumptions and failures. They are not the complete compiler Standard.

The compiler-owned native audit must load exactly the seven portable import roots, identify source declaration owners through pinned Lean module metadata, and collect constants from actual checked types, bodies, family metadata and rule bodies. It must include private/generated helpers, preserve structural names, retain raw annotations and unsafe/partial entries, and compare its source module roster with the independent source scan. Quoted PsExpr names are data, not native dependency roots.

An export from that measured roster may not trim inconvenient roots. It must first record the complete graph, refuse unapproved assumptions or unsupported unsafe/partial declarations, and retain the failing path. A conversion or deliberate selected runtime model requires its own review and checking, not an unexplained exception.

## Admission and complete identity gates

A selected manifest must include canonical declarations; constructor/recursor rules; type/proof/body dependency edges; aliases and reducibility; class parameters; ordinary/default instance names and priorities; actual assumption closure; primitive signatures and runtime implementation correspondence; toolchain/checker/resource identity; capability/source/module interfaces; target ABI and word size. Preserve list order where semantically meaningful.

The generic Fingerprint leaf preserves existing logical serialization; it does not by itself encode every profile contract above. New profile identity must bind all relevant components and be independently measured before any expected digest is frozen.

The same authorized context must drive source elaboration, preparation, admissions, project interfaces, cache validation, erasure and backend emission. Reject a Full-only name/instance/primitive under Core, then verify it only succeeds under an explicitly checked optional composition. Reject forged labels/digests, changed prepared metadata, missing dependencies, wrong provider/assumptions, ABI/word-size mismatch and a cache entry from another profile.

## Separate closure claims

Source/import isolation, native declaration reachability, successful independent replay, runtime correspondence, actual selected-source compatibility, package isolation and selfhost are separate observations. The manifest never promotes one observation into another. New pins remain null until the corresponding reproducible qualification has passed.
