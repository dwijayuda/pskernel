# Core language milestones, followed by selfhost

## Current priority and preserved authority

On 19 October 2026 at 10:21 Asia/Jakarta, the user directed: complete M1–M5 for the Core language first, and selfhost last, as quickly and effectively as correctness permits. This execution order supersedes the earlier compiler-source-first order. The [previous roadmap](https://github.com/dwijayuda/pskernel/blob/c03b1264c19ee445944465dd22c79ae0182dd509/psc0/docs/PSC0_CORE_FIRST_ROADMAP.md) and all of its evidence remain in history.

The unchanged [selected v7.2 reference](../PSCV0_LANGUAGE_REFERENCE_v7.2.md) remains language authority. The [preserved Full roadmap](PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md) retains its original acceptance and deferred requirements. The revised order does not add syntax, remove a selected Core feature, expand logical authority or mark any milestone complete.

Core M1–M5 qualify the selected Core language and the actual Lean-backed compiler API. Their denominator is the complete Core capability and conformance manifest: source forms, declarations and metadata, logical/runtime dependencies, module/artifact contracts, applicable targets and assigned interactions. Every selected capability needs positive behavior, its relevant boundary refusals and independent checking/runtime evidence. A failing capability stays in the denominator. The complete authoritative compiler-source manifest remains separately retained for final selfhost; converting those implementation files is no longer an M1–M5 prerequisite.

[The completion register](PSC0_CORE_LANGUAGE_COMPLETION_PLAN.md) owns the immediate queue and acceptance mapping. Its evidence cells must be completed before an exit can close; the current examples are not a substitute for the full selected capability roster.

## M1–M5

| Milestone | Core responsibility | Falsifiable exit |
| --- | --- | --- |
| M1 | Foundational compilation, checked representations, environment and interface foundations | The actual compiler accepts the complete foundational Core conformance workload over an independently checked, dependency-complete composition with exact declarations, family/rule metadata, source registrations and declared runtime inputs. Prepared and decoded outputs pass finite independent admission. Wrong bases, malformed metadata, unauthorized assumptions and invalid index evidence fail at their owned boundaries. |
| M2 | Names, resolution, elaboration, constraints, instances and source semantics | Every selected Core source form works through its owned reader and shared elaborator, including complete multi-module programs. Binding, scope, inferred arguments, instances, rollback, visibility and first errors satisfy paired-source and pinned native correspondence contracts. Unsupported and ill-scoped inputs retain their required refusals. |
| M3 | Core data, elimination, matching, total recursion and selected deriving | Every selected Core data/recursion capability elaborates, produces independently checked declarations and has correct observable execution, including its assigned interactions with indices, dependencies, closures, fuel and deriving dictionaries. Ill-typed, non-exhaustive and nondecreasing cases remain refused. Native-only implementation representations do not enlarge the selected grammar. |
| M4 | Execution, control flow, primitives and proof/assurance boundaries | The complete Core execution workload preserves values, errors, evaluation order and state through checked lowering and each applicable runtime contract. Strings, words, bytes, closures and host/ABI boundaries receive required correspondence checks. Proof erasure and noncomputability policies are enforced; ordinary output cannot acquire an unavailable assurance/model/refinement identity. |
| M5 | Integrated compiler, code generation, optimization, modules, incremental products, tooling and reconstruction | The actual compiler API passes the complete Core end-to-end workload on exact reviewed code/profile/runtime identities. Applicable artifacts execute against the independent reference; optimization preserves the declared semantics. Real artifact consumers authenticate independently authorized inputs, and cold/warm/incremental products agree under the declared comparison recipe. Reconstruction, diagnostics, provenance and tooling satisfy their contracts. The compiler need not compile itself for this exit. |

No newly scoped Core milestone is currently marked complete. Original M1 and M2+A remain accepted for their original bounded workload and integration. Their mechanisms and exact receipts are reused; a new Core profile or capability still needs its own qualification.

## A–E workstreams

| Workstream | Core scope | Completion evidence |
| --- | --- | --- |
| A — Core Standard | Dependency-complete declarations, source registrations, primitive models and runtime contracts for the Core language | Exact checked composition and metadata, actual assumption closure, primitive correspondence and profile-sensitive refusals; supports M1/M2/M4 |
| B — Core data and recursion | Selected data, elimination, matching, recursion and deriving | Complete M3 capability/interaction evidence, independent admission, execution and negative controls |
| C — Core execution | Control flow, closures, errors, state and typed host/target boundaries | Complete M4 execution and applicable backend correspondence |
| D — Core verification | Independent checking, assumption closure, proof erasure, interface integrity and assurance identity | Required checks and refusals throughout M1–M5; every promised proof/model/target obligation remains mandatory |
| E — Core integration and delivery | Actual compiler API, projects, artifact consumers, targets, reproducibility, incrementality, reconstruction and tooling | Complete M5 evidence on the selected Core workload; selfhost is a subsequent phase |

These are owners in one shared compiler pipeline. Do not build separate semantics per source kind, backend or milestone.

## Historical acceptance and six Full exit cells

M1 retains its original acceptance. M2+A remains accepted for its original `pscv0-v7-native-bounded/73` workload, as recorded by the original roadmap. This order change does not reopen that accepted integration or promote it to complete Core conformance.

Full preparation remains at `bf496ce399d9ec39794d6e9f7c3be919dfcffa58`. Its [exit ledger](https://github.com/dwijayuda/pskernel/blob/bf496ce399d9ec39794d6e9f7c3be919dfcffa58/psc0/docs/PSCV0_M3_LEAN_FOUNDATION_AND_EXIT_LEDGER_2026-10-18.md) is authoritative for its unqualified candidates.

| Existing Full exit | Core disposition | Preserved obligation |
| --- | --- | --- |
| General data/elimination | Qualify every selected Core data/elimination capability and reached dependency | Other Full indexed/dependent, nested and non-Core elimination cases retain their explicit scope |
| All selected owned-source forms | Cover both source routes for every selected Core form, including ordinary complete applications | Other Full forms, registered heads and publication policies remain tracked |
| Total recursion | Require Core total recursion and all reached checked library proof dependencies | General Full WF/nested Prop source coverage remains separate unless required by Core |
| P0 | Preserve existing ordinary partial mechanisms and refusals; no source-scan absence is a language proof | General Full P0 completion and registered/default-instance policies remain open |
| P1 | Preserve reached logical dependencies and strict model/assurance gates | Full P1 construction and source/runtime/module exposure remain open |
| Cross-stage qualification | Complete Core source/kernel/IR/runtime integration first; compiler Stage1–3 is final-phase work | Full same-SHA and promised source/runtime combinations remain separate |

Full effects, advanced contracts/proof automation, complete Full library closure and full v7.2 conformance are not renamed Core results. An optional capability needs an explicit declaration/registration/runtime boundary; its required transitive dependencies cannot be dropped. Existing ordinary/partial/unsafe/verified/model/refinement distinctions remain.

## Execution order

1. Preserve the qualified infrastructure, exact candidate assets and Source/List regression. Map the existing Core capability contract to exact source rules, shared owners, positive/negative fixtures and runtime/checking obligations.
2. Complete M1/M2 foundational and source/elaboration gaps using full application/module fixtures. Extend declaration/runtime closure only for a demonstrated Core requirement.
3. Complete M3 data, matching, recursion and deriving together with the M4 behavior needed to execute them. Transfer reviewed shared work from Full only with new bounded Core evidence.
4. Complete M4 assurance/runtime correspondence and M5 actual compiler integration, applicable targets, artifact authentication, incrementality and reconstruction. Retain passing controls.
5. Accept M1–M5 only on the exact qualified code, Core profile, runtime and checker identities. Package/default changes and publication retain their separately applicable gates.
6. Then complete authoritative compiler-source conversions, measure compiler-sufficient Bootstrap, and run Stage1, Stage2 and Stage3 with the [unchanged final selfhost requirements](PSC0_CORE_SELFHOST_PLAN.md).

## Retained Foundation contribution

The complete Foundation.Source/List result at `1995a478af7aeb83032749fbdb9a2cfa96d28a88`, [run 39191534560](https://github.com/dwijayuda/pskernel/actions/runs/39191534560), remains qualified at its exact scope. It contributes checked seed/metadata to M1, paired source/project behavior to M2 and structural List/data evidence to M3. It does not close a whole milestone, native elaboration parity, emitted execution or a selfhost stage.

The original 76-declaration seed and the separate 92-declaration candidate stay pinned. Their Source/List gate is retained as a cheap regression. Token → Cursor → Name, the two native mutual-data representation conversions and compiler hash-padding conversion are final selfhost preparation unless one is independently needed to close a selected Core language/runtime obligation.

M5's remaining exit is complete Core artifact identity, applicable targets, incrementality, reconstruction and tooling. Whole-compiler Stage1–3 remains mandatory for the subsequent selfhost claim.

## Current implementation progress

The [module/runtime receipt](core-first-evidence/core-language-module-runtime-qualification.json) at `ddf0fc171e80d847b9e867c7b7f8045cc712b36c`, [run 39195343005](https://github.com/dwijayuda/pskernel/actions/runs/39195343005), passes all four Core Linux jobs. The selected leading-module/default-privacy/public-import slice passes complete paired project admission and owned refusals. Separately, the existing checked application baseline executes 1,069 observations each on TypeScript, direct JavaScript and Rust. It uses the Full compatibility context; the smaller Core profile, full native module contracts and complete milestone gates remain open. Continue with item 3 of the completion register rather than repeating these completed tests or resuming compiler-source conversions.
