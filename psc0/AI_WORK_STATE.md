# PSC0 work state — Core-first execution

Updated 19 October 2026 UTC. This handoff belongs to the isolated `psc0/core-first-environments-20261019` branch. Read its current GitHub ref before every write; never reset it to an earlier receipt.

## Active user direction

The user authorized adapting and beginning the Core-first prompt now. Preserve PSC0 architecture and selected v7.2, define explicit Core M1–M5/A–E exits from the actual compiler workload, keep Full milestones/history separately, and implement the first independently testable environment slice. Earlier prohibitions on starting Core/compiler selfhost are superseded by this direction. Existing checking, source/runtime and repository safeguards remain.

Start with [Core architecture](docs/PSC0_CORE_FIRST_ARCHITECTURE.md), [roadmap](docs/PSC0_CORE_FIRST_ROADMAP.md), [closure ledger](docs/PSC0_CORE_STANDARD_MANIFEST.md), [qualification](docs/PSC0_CORE_QUALIFICATION_LEDGER.md) and [selfhost plan](docs/PSC0_CORE_SELFHOST_PLAN.md). The original v7.2 reference and Full roadmap are unchanged.

## Exact preserved lines

- Qualified Stage0: `psc0/pscv0-v7-native-lean-v1` at `33676076bcda7b0de5ec1f9803f49b8b1d28a058`, tree `87b8b0af6c72f5e8b28af97f9f990e28f73ac56e`. PR109 was open/draft/unmerged at the last fresh audit.
- Its five same-SHA gates are successful: Native39099546592, M339099546513, F139099546493, F239099546574, F339099546446. Preserve their bounded scope.
- Repository default main is a different historical SH/1 line. It is not Stage0.
- Full M3 preparation remains `psc0/m3-fixedpoint-foundation-20261018` at `bf496ce399d9ec39794d6e9f7c3be919dfcffa58`, tree `f75ba7308134ab6be473347aafb5d2788c84b608`. Run39176676179 failed new fixture compilation; Option-bind and recursor authoring passed. Its six Full exits remain open and its unqualified work is not copied wholesale into Core.
- PSKernel-Core/C0 and unrelated research branches remain untouched.

## Completed Core evidence

Core branch began at exact qualified Stage0. Source-only audit880facd5 first rejected current/legacy duplicate module owners. That defect was corrected. Source audit at851faf84 succeeded; native jobs stopped before build because the Linux runner lacked rg, corrected to its available grep tool.

Exact `a34686faa951f1b3ac8add59162d5dcb90d5c3ea`, run39178265318, passed all three jobs:

| Job | Result |
| --- | --- |
| source-inventory117825360006 | Complete explicit import/blob/package inventory; isolated fingerprint/replay imports |
| native-seams117825360002 | SHA vectors, actual replay dependency deferral, no Nat seed leakage, ill-typed declaration refusal |
| candidate-authoring117825359808 | Full native compatibility/identity checks; bootstrap and byte/word empty-boundary export/replay |

Stage0 source closure:316 modules /26,384,235 bytes, including101 Environment modules /23,654,198 bytes. Fingerprint leaf:10 modules /46,242 bytes. Replay leaf:12 repository modules /50,030 bytes plus explicit native Lean.

Bootstrap export:76 declarations, no axioms,24 compared recursor rules,118,573 source bytes. Byte/word:1,945 declarations, actual propext/Quot.sound,113 compared rules,16,111,994 source bytes. These are checked native authoring candidates, not complete selected Core or package-size claims. New candidate-vs-Full declaration compatibility is unproven.

## This candidate's additional work

Generic Engine and Full API wrapper preserve all34 old public functions and the old Full runtime selection point. Corrected Engine transfer:31,778 characters/FNV32 eda4edd5. Wrapper:9,832/FNV32 2cedfdf9. FNV32 values here check text transfer, not semantic profile identity.

The selected Pscv0Engine uses actual selected readers and Command, retains the supplied context, and leaves Pscv0Modules/cache interfaces unchanged. Its Full wrapper still checks the existing Standard before elaboration. InhabitedExpr and ReprExpr move24 existing builder bodies unchanged, removing their Standard construction imports from the selected frontend.

New tests exercise generic and selected source preparation against closed independently checked small bases, canonical admissions, missing-base/refusal ownership and runtime selector forwarding. New native source-owner audit measures checked type/body/family/rule dependencies and compares module ownership with the exact source graph. All these additions require their new exact-SHA CI result; do not inherit a346's success.

The source audit prints bounded per-module records for durable connector review. CI transports only the small Bootstrap source; the16.1 MB candidate remains an artifact. Preserve Bootstrap bytes unchanged when creating BootstrapData, then qualify its exact composition/manifest and finite replay. Do not create Core/Full inclusion claims from seed names.

## Concrete next steps

1. Fetch this branch's actual head, workflow runs and jobs. Resolve new compilation or probe failures at their owned boundary; never weaken refusals or raise limits.
2. Capture the native ownership report, compare source modules exactly and inspect real assumptions/unsafe/partial dependencies before attempting an entire compiler-derived export. The compiler authorer has a strict refusal policy; it must never trim roots.
3. Retain the76-declaration Bootstrap source via the connected GitHub/CI transport, compose it from empty with exact reducibility, record actual empty class/instance registries and check compatibility differences against Full. Do not silently install native class flags absent from the portable manifest.
4. Qualify Engine/selected source/import isolation and preserve Full native identity/source checks on the reviewed candidate. Save precise receipts and source/artifact hashes in the ledger.
5. Continue actual compiler source conversion only after required Core declaration/runtime and module identity gates. Two native mutual-data groups and the bounded SHA padding loop need explicit handling. Old selfhost wrappers/native implementation builds are not Stage1.
6. Keep complete Core Standard, project/module/cache identity, runtime/backend correspondence, real npm isolation and Stage1–3 open until their declared tests pass.

## Invariants

Use GitHub connectors and cloud Linux CI for all repository work; no local checkout, filesystem editing, compiler, shell or alternate desktop execution for this repository. The explicitly supplied local prompt was input only.

Pinned Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc. Maximum logical assumptions propext/Quot.sound/Classical.choice; record actual reached closure. No unauthorized axioms, holes, runtime choice, kernel changes, broader budgets or relaxed negative gates. Ordinary checked does not become verified/model/refinement by choosing Core. WasmGC remains internal; linear memory only explicit ABI.

Refresh refs and use expected-HEAD non-force writes. Root coordinates writes; read-only agents can review independent areas. Preserve healthy qualified-line runs and concurrent branches. Do not require unrelated Full exits before a qualified Core slice, and do not relabel deferrals as completion.
