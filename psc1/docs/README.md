# PSC1 documentation index

The [qualified layout/ownership receipt](PSC1_LAYOUT_QUALIFICATION_2026-10-26.json)
records the .9 host package, current source, exact moves, CI and preserved payloads.
[Repository map](reference/repository-map.md) and [CLI roles](../npm-cli/README.md)
are the navigation entry points. Human comprehension remains pending.

Start with [the compiler README](../README.md), [architecture](../ARCHITECTURE.md)
and [contributor guide](../CONTRIBUTING.md). This index separates current guidance
from immutable evidence; dated records remain preserved.

## Current guides and authorities

| Question | Read |
| --- | --- |
| How do I use the qualified project-oriented CLI? | [CLI guide](./guides/cli.md), [workflow research](./development/typescript-workflows.md) |
| How do I install/use the current slim toolchain? | [Slim package guide](./PSC1_SLIM_UNIVERSAL_PACKAGE.md) |
| How do checked component/Python/PHP outputs work? | [Dispatch architecture](./PSC1_CHECKED_DISPATCH.md), [exact receipt](./PSC1_CHECKED_DISPATCH_QUALIFICATION_2026-10-26.json), [install](./PSC1_CHECKED_DISPATCH_INSTALL.md) |
| How do checked targets and transactions work? | [Guide](./PSC1_CHECKED_PUBLICATION.md), [receipt](./PSC1_CHECKED_PUBLICATION_QUALIFICATION_2026-10-26.json), [install](./PSC1_CHECKED_PUBLICATION_INSTALL.md) |
| How does a tiny program become checked output? | [Source-linked walkthrough](./guides/compilation-walkthrough.md), [pass contracts](./reference/pass-contracts.md) |
| Which capabilities are actually qualified? | [Current package scope](./PSC1_CAPABILITIES.md) |
| How can a new maintainer work without AI? | [Exercise and evidence rubric](./development/maintainer-exercise.md) |
| How does the real modular JS/TS component pilot work? | [Pilot guide](./guides/modular-pilot.md), [finite contract](../test/modular/contract.json), [qualification](./PSC1_MODULAR_PILOT_QUALIFICATION_2026-10-27.json) |
| What remains unfinished? | [One development roadmap](./PSC1_DEVELOPMENT_ROADMAP.md) |
| What must Practical Core v1 support? | [Finite language contract](./PSC1_PRACTICAL_CORE_V1_CONTRACT.json) |
| What must npm distribution qualify? | [Finite distribution contract](../NPM_DISTRIBUTION_CONTRACT.json) |
| How do optional backends work? | [Provider contract](../BACKEND_PROVIDER_CONTRACT.json), [provider design](./PSC1_BACKEND_PROVIDERS.md) |
| Where does installed host authority live? | [Host tools](../host-tools/README.md) |
| How are exact bytes, tokens and comments retained? | [Lossless capture contract](./PSC1_LOSSLESS_SOURCE.md) |
| How was the malformed-character location defect repaired? | [Correction and scoped proof](./PSC1_CHARACTER_DIAGNOSTICS.md) |
| How are actual declaration/member origins tied to source? | [Read-only ownership](./PSC1_SOURCE_OWNERSHIP.md) |
| How do I convert supported source grammars safely? | [Checked candidate conversion API/CLI](./PSC1_CHECKED_SOURCE_CONVERSION.md) |
| How do I produce a checked local rename candidate? | [Binding trace/rename API and deliberate bounds](./PSC1_SOURCE_BINDINGS.md) |
| Which refactor operations can be justified? | [Checked source-refactoring design](./PSC1_SOURCE_REFACTOR_ARCHITECTURE.md) |
| How can an engineering session continue? | [AI work state](../AI_WORK_STATE.md), [current continuation](./PSC1_SOURCE_REFACTOR_CONTINUATION.md) |

Acceptance contracts define requirements. Qualification receipts attach actual
results to exact source/artifact identities. Work state and this index point to
those authorities; they do not create qualification.

## Exact existing qualification

- [Project CLI and npm toolchain](./PSC1_CLI_QUALIFICATION_2026-10-26.json):
  qualified .8 host with all original kernel/dispatch/publication/application/type
  gates, 19 source groups and 55 real installed requests. G3 payloads unchanged;
  optional emit-only metadata decoupled; independent human trial pending.

- [Checked seven-target dispatch](./PSC1_CHECKED_DISPATCH_QUALIFICATION_2026-10-26.json):
  four unchanged genuine G3 engines, optional Python/PHP runtime consumers,
  actual Bool-component validation/execution, both grammars and immutable
  publication. The receipt separates producer bytes from installed-test/source
  commits and retains every prior gate. Linux x64 scope; final universal release
  remains incomplete.


- [Bounded source binding and local rename (R2b)](./PSC1_SOURCE_BINDINGS_QUALIFICATION_2026-10-26.json):
  implementation 9d07ae36/source 1714b8cf;40219590598 passes 23 renames/62 refusals,
  28 seven-target artifacts and whole122-module compiler indexing/rename under both
  grammars;current-source WasmG1 40218467242. Complete tracing remains unsupported.

- [Checked grammar conversion (R3)](./PSC1_SOURCE_CONVERSION_QUALIFICATION_2026-10-25.json):
  implementation fa265940, source closure 77e2173d; conversion40206625342,
  genuine WasmG1 40206504499 and readable source artifact 40206663537.
  Ordinary source 40206628424 passes 37/37, zero blocked. Exact source/publication boundaries and artifacts are in the receipt.

- [Read-only declaration ownership (R2a)](./PSC1_SOURCE_OWNERSHIP_QUALIFICATION_2026-10-25.json):
  implementation a77ec1a8, focused 40200895349 (121 modules in both grammars,
  ten production-path graph comparisons and 42 refusals), ordinary 40200961302
  (37/37 finite criteria). That receipt grants no reference/rename authority; bounded R2b has separate evidence.

- [Character diagnostic correction](./PSC1_CHARACTER_DIAGNOSTIC_QUALIFICATION_2026-10-25.json):
  implementation d70221c9, focused 40195964028 (664 position cases, 359 captures,
  49 refusals), genuine new-source Wasm G1 40196021448, ordinary source 40196244138
  (37/37 finite criteria, zero blocked). Scoped leaf proofs; separate current/frozen source identities.

- [Lossless R1 capture](./PSC1_LOSSLESS_SOURCE_QUALIFICATION_2026-10-25.json):
  implementation c577d498, focused 40191237137 (358 captures, 49 refusals),
  normal 40191245319 (37/37 finite criteria), unchanged unified/frozen source identities.

- [Current readability slice](./PSC1_READABILITY_QUALIFICATION_2026-10-25.json):
  implementation 446a0f21, host package 40184641007, new-source Wasm G1
  40184951724 and normal source 40184897417. Frozen packaged source and
  refactored compiler source are explicitly distinguished.
- [Preserved PR #180 slim package and normal source](./PSC1_SLIM_UNIVERSAL_QUALIFICATION_2026-10-25.json):
  implementation 0a717520, package 40166882825, source 40166884643.
- [Frozen four-engine self-hosting](./PSC1_UNIFIED_FOUR_ENGINE_QUALIFICATION_2026-10-25.json):
  exact source/admission/IR/executable/target fixed points for the frozen closure.
- [Official kernel packages and native distribution](./PSC1_KERNEL435_QUALIFICATION_2026-10-25.json):
  independent native and linear-memory Wasm checker platform evidence.

Later changes must link their own evidence. The existence of a receipt with a
similar filename does not qualify current HEAD.

## Historical material

`history/` contains superseded snapshots. Dated audits, failure records and
qualification JSON elsewhere in this directory also describe their stated commits.
Use their exact scope/date before applying an old conclusion to current code.
The two BEFORE_READABILITY snapshots reproduce commit 3089cbc3 verbatim; consult
that commit's original paths when following their original relative links.
Older guides can remain useful for retained native packages without describing the
current slim generated CLI.

`../profile.json` retains historical native-profile fields and points to current
contracts. It is not a current self-hosting/npm readiness authority.
Do not delete past failures or relabel previous artifacts after a source change.

## Current generated IO milestone

Read [generated IO applications](./PSC1_GENERATED_IO_APPLICATIONS.md) and the exact [qualification receipt](./PSC1_GENERATED_IO_QUALIFICATION_2026-10-26.json). The [roadmap](./PSC1_DEVELOPMENT_ROADMAP.md) owns remaining release work.

Qualified new-G3 packages: [installation and exact artifact](./PSC1_GENERATED_IO_INSTALL.md).
[Executable continuation](./PSC1_SOURCE_REFACTOR_CONTINUATION.md) starts with the next
release item; the preceding generated IO/npm milestone remains qualified.

## Qualified checked publication

PR #188:Linux transaction and four-target installed qualification40238538092,
source 37/37 and all selected dependencies40238649527. See the current receipt
and installation guide above. Other-platform publication remains disabled.
The new BEFORE_CHECKED_PUBLICATION snapshots reproduce563ee855 verbatim;
resolve their original relative links at that commit and original paths.

## Qualified automated maintainability slice

[Exact receipt](./PSC1_MAINTAINABILITY_QUALIFICATION_2026-10-26.json): current source
123 modules / 4742 members, exact RuntimeNeeds extraction, actual walkthrough and
current-source Wasm G1 in 40272793607; all 37 finite source criteria in 40272797072.
Packaged .7 G3 payloads retain their separate 122-module source and fixed points.
The independent human trial remains pending; CI is a reference-command rehearsal.

## Browse by purpose

- [Guides](guides/README.md): installation, CLI and compilation walkthrough.
- [Architecture](architecture/README.md): owners, pass boundaries and dependencies.
- [Reference](reference/README.md): contracts, repository map and vocabulary.
- [Development](development/README.md): queue, validation and maintainer trial.
- [Evidence](evidence/README.md): immutable qualification receipts.

Flat guide URLs remain compatibility links. Dated receipts/contracts retain their
paths and bytes; indexes improve discovery without rewriting historical evidence.
