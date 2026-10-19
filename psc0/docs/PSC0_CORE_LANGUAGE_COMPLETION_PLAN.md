# Core language completion register and execution plan

## Decision

Complete the selected Core language/compiler M1–M5 first, then selfhost. This implements the user's 19 October 2026 10:21 Asia/Jakarta directive. The [Core roadmap](PSC0_CORE_FIRST_ROADMAP.md) owns milestone exits; the [selfhost plan](PSC0_CORE_SELFHOST_PLAN.md) retains the final whole-compiler stages. The language authority stays selected v7.2 and Lean 4.35.0 `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.

Use the existing native portable Lean implementation and shared reader → resolution → elaboration → prepared graph → independent checking → typed erasure → validated IR → backend pipeline. The earlier M1 and bounded M2+A receipts remain reusable. There is no architectural restart, language-version migration or blanket reassignment of every existing feature to unfinished work.

No milestone is accepted by this planning revision. No new complete Core profile is selected. The previous exact Source/List, project, Bootstrap and Full evidence remains unchanged.

## Feature and acceptance register

This register groups the existing Core responsibilities; it does not replace the normative grammar or invent new syntax. Before closing a row, its complete selected operation/form and interaction roster must be recorded in the executable conformance manifest with exact rule/fixture/owner/phase links. An unmapped selected rule stays open. Current bounded receipts establish only their declared cells.

| ID | Core responsibility | Primary milestone | Required evidence before closure |
| --- | --- | --- | --- |
| CL01 | Checked type foundation, universes, dependent functions, equality and proof terms | M1, D | Complete foundational declarations/metadata and exact assumption closure; positive admission and invalid-type/index/assumption refusals |
| CL02 | Core values and required standard APIs: Bool/Unit, Nat/Int, String/Char, products/sums, List/Array, Option/Except, Fin/Subtype and required byte/word operations | M1, A; M4 | Exact selected API/dependency roster, source registrations and primitive/runtime correspondence; target word size remains explicit |
| CL03 | Lexing and the distinct selected Lean/ProofScript surfaces, binders, applications, literals and declaration heads | M2 | Both readers preserve their source rules and produce corresponding checked semantics; phase-correct lexical, parse and elaboration refusals |
| CL04 | Namespace/section variables, local scope, resolution, inference, constraints and instances | M2, A | Complete scoped programs, inserted evidence, rollback/default ordering and negative ambiguity/visibility cases |
| CL05 | Modules, ordinary/public imports, declaration visibility, interfaces and source provenance | M1/M2, E | Complete multi-module chains, exact retained inputs, public/private and non-exposed-body contracts, import order/cycle/missing/dependency refusals |
| CL06 | Records, constructors, recursive and selected indexed/dependent data | M3, B | Checked family/rule metadata, positivity/index consistency, construction/elimination and runtime representation evidence |
| CL07 | Selected pattern matching and elimination, including dependent cases and proof elimination | M3, B/D | Correct motives/coverage/refinement, native correspondence, actual computational results and intended ill-typed/non-exhaustive refusals |
| CL08 | Structural/total recursion, selected mutual functions, closures and required checked WF dependencies | M3, B | Correct equations and executable bodies; dependency-complete proofs; preserved header/returned-function distinctions and nondecreasing refusals |
| CL09 | Selected Inhabited, BEq, DecidableEq, Repr and Hashable deriving | M3, B/A | Generated checked declaration/instance closure, dictionary execution and applicable required laws; unsupported handler/refusal scope retained |
| CL10 | Core control flow, local state/traversal, Option/Except/Id behavior and ordinary execution | M4, C | Actual values/errors/evaluation order and state; selected local mutation/control gaps remain explicit; host/foreign effects have typed declared boundaries |
| CL11 | Proof erasure, noncomputability, contracts and honest assurance identities | M4, D | Every selected promise has its proof/model/refinement/target evidence; ordinary checks are not behavioral certificates; unavailable verified features fail without downgrade |
| CL12 | Actual shared backend lowering and ABI/primitive behavior | M4/M5, C/E | Checked IR plus independent runtime observations on each applicable target; backend-specific coverage and formal correspondence claims stay distinct |
| CL13 | Integrated compiler API, projects and consumable artifacts | M5, E | Complete Core application workload, exact code/profile/runtime/checker identity and independently authorized artifact inputs |
| CL14 | Cold/warm/incremental reproducibility, reconstruction, diagnostics, provenance, tooling and validated optimization | M5, E | Real implemented consumers and comparison recipes, deterministic semantic products, source mapping/diagnostic checks and measured regressions |

The full fixture mapping for these rows is still open; therefore neither a row percentage nor an overall completion percentage is assigned. Reuse existing native/paired/runtime cases and their exact outputs before adding a new case. Missing source coverage cannot be replaced by native implementation compilation.

Existing explicit Full deferrals remain: optional Float/platform compositions, general non-Core effects and advanced verification/recursion facilities keep their own gates. Native mutual inductive syntax remains outside the selected function-like mutual source grammar. No dependency reached by a Core declaration, proof, instance or runtime model becomes optional solely because a compiler-source token scan does not mention it. P0/P1 and restricted unsafe retain their exact selected capability and assurance boundaries; moving selfhost later gives them no new authority or completion claim.

## Immediate critical path

Items 1 and 2 below are completed at their bounded scopes on `ddf0fc171e80d847b9e867c7b7f8045cc712b36c`, [run 39195343005](https://github.com/dwijayuda/pskernel/actions/runs/39195343005). [The receipt](core-first-evidence/core-language-module-runtime-qualification.json) records the complete paired module chain, eight owned parser refusals and 1,069 runtime observations each for TypeScript/direct JavaScript/Rust in the existing Full compatibility baseline. The next active item is 3. CL05/CL12 and whole-milestone exits remain open.

The next bounded CL04/CL05 cells passed at `36f30bc4e0887d1bb60ae67660046cc441ed0c39`, [run 39236888998](https://github.com/dwijayuda/pskernel/actions/runs/39236888998), with all four jobs successful. [The scope/module receipt](core-first-evidence/core-language-scope-module-qualification.json) records public-section inheritance and restoration, EOF canonical equality, actual module kinds, imported-body controls and separate pinned-native oracles. These cells advance item 3; complete CL04/CL05 and M1–M5 exits remain open.

The imported-name visibility cells now pass at `9024dd92c147ffbbafc3834021ad11540d89578a`, [run 39245007181](https://github.com/dwijayuda/pskernel/actions/runs/39245007181), with all four jobs successful. [The import-visibility receipt](core-first-evidence/core-language-import-visibility-qualification.json) records 13 independently admitted positive projects, 8 owned refusals, actual type/body/proof dependencies, both public diamond orders and opaque bridges. The pinned module oracle now has 25 cases: 17 successes and eight semantic refusals. The first integrated attempts exposed old fixture headers that needed public imports for exported types; those corrections preserve declaration bodies, original source assets, canonical admissions and intended opacity refusals. Complete CL05 and M1–M5 exits remain open.

| Priority | Concrete owner and work | Completion observation |
| --- | --- | --- |
| 1 | Selected native module headers/public imports and visibility in Syntax.Lean.Program; shared project owner remains Pscv0ModuleEngine | Complete paired module-mode provider/facade/client preparation and canonical independent admission, default-private and explicit-public behavior, owned header/import refusals |
| 2 | Execute existing checked application products on the Core branch through the existing TS/JS/Rust runners | Exact compiler SHA and emitted products, unchanged shared observations and trap controls; explicitly report the Full compatibility development baseline |
| 3 | Complete named/dotted-scope and separately specified legacy behavior; map inherited M1/M2 evidence | Preserve qualified public-section/EOF, module-kind, body and public import-visibility cells; close the remaining scope and legacy boundaries with exact fixtures and profile obligations |
| 4 | Checked computed/let-target cases and induction in Elab.Elimination | Reuse only reviewed expression-abstraction/target preparation and distinct-index guard; new paired proof/computational fixtures and independent admission |
| 5 | Complete remaining Core data/matching/recursion/deriving and required control flow | Follow the actual first failing shared owner, retaining the entire selected capability/interaction roster |
| 6 | Complete M4 assurance/runtime and M5 integration, targets, incremental artifacts and reconstruction | Exact end-to-end language/compiler acceptance; then start final selfhost |

The preserved Full Elimination candidate is reusable source, not a passing receipt. Do not copy its unrelated name-alias/match/WF implementation. Review its smallest shared expression-abstraction dependency, check the complete generalized telescope and preserve induction-only index restrictions without imposing them on cases.

The selected Lean reader now supports leading module headers, per-declaration visibility and named/anonymous `public section`. Ordinary nested sections and namespaces inherit the current default; explicit private declarations remain private and explicit ends restore the previous default. EOF closes the remaining namespace/section scopes in both selected source kinds. `private section`, `public namespace` and `private namespace` retain owned syntax refusals, matching the pinned native controls. ProofScript keeps its own selected section syntax.

Actual module kind is retained by both readers. Module clients cannot import headerless Lean providers; legacy clients can import either kind. Nine positive project cases, eight module-kind refusals and four parser-bit checks pass. Paired public-import clients can unfold an exposed abbreviation and use an exported specification theorem; direct reflexivity cannot unfold an imported ordinary definition. The current native oracles separately pass 17 declaration classifications, three invalid scope forms and 25 module compilations (17 successes/eight semantic refusals).

Public signatures and data-valued exposed definitions now have bounded ordinary/private-import versus public-import controls. The direct legacy fixture establishes imported-name availability only. Remaining work includes named-end/dotted-scope behavior, legacy local-private references and imported implementation closure, and native proof abstraction inside exposed definitions. The earlier M3 mixed-input positive uses a real module provider; its whole M3 input-parity executable is not newly qualified by this Core run. Complete module/native elaboration parity and the full fixture denominator remain open.

For the next scope correction, preserve the existing AST and PsScopeFrame representation: named namespace/section headers introduce one frame per component; named ends close exactly matching innermost labels without skipping unnamed barriers; bare end requires an unnamed section. The Lean visibility adapter must mirror each push/pop, including sequential default restoration inside a public dotted section. Ordinary dotted scopes need paired/native positives and owned refusals. Rooted `_root_` headers retain their separate unverified boundary.

Legacy imported-body parity requires an explicit legacy import view that retains original declaration kinds, implementation dependencies, relevant metadata and closure across all reachable import edges. Converting every opaque declaration back to a definition is incorrect because real source-level opaque declarations must stay opaque. Qualify local legacy private references separately and retain private source-name restrictions.

## How to finish efficiently

- Keep one remaining-capability register. Each item has one shared owner, an observable positive result, its relevant owned refusals and applicable checking/runtime evidence. Close the item with an exact receipt, then move on.
- Reuse accepted M1/M2 infrastructure, existing native source fixtures, canonical admission and target runners. Transfer a reviewed Full correction only when it closes a selected Core obligation.
- Work on dependencies in order; parallelize independent review/implementation preparation and serialize branch integration. Preserve at most one active and one pending Core run; do not cancel healthy evidence.
- Use focused source/kernel/runtime gates while changing one owner, then complete the required integrated regression on the candidate that will be accepted. Do not broaden tests once they have resolved the concrete risk; do not skip required gates.
- Restore established Lake caches and let source traces rebuild changed dependencies. Preserve exact toolchain/reference checks and report timings as cache-assisted measurements. Keep resource limits unchanged.
- Prefer actual execution over adding more descriptive manifests. There is no selected persistent-cache loader today; M5 requires implementing and qualifying the real owner before claiming incremental artifact reuse.
- Defer new compiler-source conversions, whole-compiler fixed-point runs, unrelated Full completion, optional-package expansion and speculative optimization until they are on the current Core critical path. Preserve completed work and every promised final gate.

The previous run's measured candidate exports were short (Bootstrap 2.24 s, Foundation 2.29 s, byte/word 7.57 s); its uncached seam builds together took about 111 s. That evidence supports restoring the established cache before redesigning CI gates. It does not support a claimed compiler speedup, runtime speedup or fixed completion date. The exact source of those observations is [run 39191534560](https://github.com/dwijayuda/pskernel/actions/runs/39191534560).

## Evidence and remaining boundaries

The development baseline uses the existing Full compatibility context, including optional capabilities already present in its fixtures. Its successful application execution can establish those observed compiler/runtime behaviors. It does not establish the smaller Core Standard closure, installed package size, whole-language conformance, formal target refinement or a selfhost stage.

The 76-declaration seed, 92-declaration Foundation candidate and complete Source/List test stay as exact independently identified components. Compiler-sufficient Bootstrap and its full implementation-source dependencies are final selfhost preparation. Core Standard for M1–M5 instead closes the dependency-complete selected Core language/application contract.

Before final selfhost, record the exact M1–M5-qualified Lean-backed compiler that executes Stage1. Preserve historical Stage0 `33676076bcda7b0de5ec1f9803f49b8b1d28a058` and its five receipts separately. Then compile every authoritative source module, recompile with the resulting compiler and establish Stage2/Stage3 fixed-point/checking/runtime correspondence under the retained plan.

No merge, release-default selection or npm publication is authorized by a green slice or by this ordering revision.
