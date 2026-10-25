# PSC1 documentation index

Start with [the compiler README](../README.md), [architecture](../ARCHITECTURE.md)
and [contributor guide](../CONTRIBUTING.md). This index separates current guidance
from immutable evidence; dated records remain preserved.

## Current guides and authorities

| Question | Read |
| --- | --- |
| How do I install/use the current slim toolchain? | [Slim package guide](PSC1_SLIM_UNIVERSAL_PACKAGE.md) |
| What remains unfinished? | [One development roadmap](PSC1_DEVELOPMENT_ROADMAP.md) |
| What must Practical Core v1 support? | [Finite language contract](PSC1_PRACTICAL_CORE_V1_CONTRACT.json) |
| What must npm distribution qualify? | [Finite distribution contract](../NPM_DISTRIBUTION_CONTRACT.json) |
| How do optional backends work? | [Provider contract](../BACKEND_PROVIDER_CONTRACT.json), [provider design](PSC1_BACKEND_PROVIDERS.md) |
| Where does installed host authority live? | [Host tools](../host-tools/README.md) |
| How are exact bytes, tokens and comments retained? | [Lossless capture contract](PSC1_LOSSLESS_SOURCE.md) |
| Which refactor operations can be justified? | [Checked source-refactoring design](PSC1_SOURCE_REFACTOR_ARCHITECTURE.md) |
| How can an engineering session continue? | [AI work state](../AI_WORK_STATE.md), [package continuation](PSC1_SLIM_UNIVERSAL_CONTINUATION.md) |

Acceptance contracts define requirements. Qualification receipts attach actual
results to exact source/artifact identities. Work state and this index point to
those authorities; they do not create qualification.

## Exact existing qualification

- [Lossless R1 capture](PSC1_LOSSLESS_SOURCE_QUALIFICATION_2026-10-25.json):
  implementation c577d498, focused 40191237137 (358 captures, 49 refusals),
  normal 40191245319 (37/37 finite criteria), unchanged unified/frozen source identities.

- [Current readability slice](PSC1_READABILITY_QUALIFICATION_2026-10-25.json):
  implementation 446a0f21, host package 40184641007, new-source Wasm G1
  40184951724 and normal source 40184897417. Frozen packaged source and
  refactored compiler source are explicitly distinguished.
- [Preserved PR #180 slim package and normal source](PSC1_SLIM_UNIVERSAL_QUALIFICATION_2026-10-25.json):
  implementation 0a717520, package 40166882825, source 40166884643.
- [Frozen four-engine self-hosting](PSC1_UNIFIED_FOUR_ENGINE_QUALIFICATION_2026-10-25.json):
  exact source/admission/IR/executable/target fixed points for the frozen closure.
- [Official kernel packages and native distribution](PSC1_KERNEL435_QUALIFICATION_2026-10-25.json):
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
