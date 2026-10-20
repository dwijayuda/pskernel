# GPT-6.1 SOL HIGH — CONTINUE PSC1 IMPLEMENTATION FROM QUALIFIED ULTRA CHECKPOINT

You are the implementation lead for dwijayuda/pskernel. Continue autonomously from the architecture checkpoint below. Read the finalized decisions, verify the live branch and CI, then implement. Reopen a decision only when new source, correctness or measured performance evidence contradicts it. Do not repeat the completed architecture research.

## Exact checkpoint and authority

Repository: https://github.com/dwijayuda/pskernel
Working branch: research/psc1-ultra-qualified-20261021
Draft PR: https://github.com/dwijayuda/pskernel/pull/169
Exact qualified implementation: 5496943a30423269654fffcd7579b3c5dd16b4f9
Successful scoped Linux workflow: https://github.com/dwijayuda/pskernel/actions/runs/39495181966
Successful focused native workflow: https://github.com/dwijayuda/pskernel/actions/runs/39495181847
Tested GitHub merge: a4e3b9bd626c36437557b58f5e7dfb3c477fcf39

The prompt is anchored to this immutable qualified implementation. The commit saving this prompt and its evidence is a documentation descendant; resolve the live branch ref and inspect any intervening changes before writing. Do not invent the self-referential hash of the commit containing this file. The final report supplies that live documentation HEAD separately.

Preserved ancestry:
- #162 scoped correctness: a2778be648850a1f6a2381e28babcd4a6e783e31.
- #163 first Practical Core slice: ea03ce125ad4d4902070d6fef92d92b51cb2e857.
- #165 seven backends: 5539059a47c13a3dbc9806a504775b72f7bfd0fe.
- #166 patterns/namespaces: da880d864ca5f9e35729255fd7e4f8a17953cd39, green run39469312498.
- #167 typed-error candidate: a830668d2c23886843e616951836d8d990aa2ff5, originally failed run39423828387.
- #168 architecture integration: 7e25943b991446ee2ab5a32b445238ef5af47cb5. Its source integrates #166/#167 histories; run39490333445 remained red. It is preserved unchanged on research/psc1-ultra-architecture-20261021.
- #169 continues #168 without changing any earlier branch. Reproduction checkpoint8ad97dcc6fdfd3e6f8bebab8d77e895b4b5093ba: native39492745174 passes; scoped39492745046 records handler/WIT/prototype defects. Corrected ambient/PS fixture checkpoint9196093342837d816f9c328ff90e275476324e28 records actual JS intrinsic capture and TS prototype-field failure in both grammars, run39494671024 (superseded/cancelled after reproduction, not qualification).

Official independent semantic checker: Lean4.35.0, commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc. Owned PSKernel-Core is separately native-tested and is not the active direct checker. Pins: ubuntu24.04; Node22.23.3; TypeScript7.0.2; Rust/Cargo1.90.0; Python3.14.8 and3.15.0; PHP8.5.11 with GMP; wasm-tools1.254.0; Wasmtime49.0.4. Preserve exact lockfiles and tool identities; qualify upgrades separately.

Use GitHub connected tools and GitHub Actions Linux exclusively for repository development/qualification. No local checkout/build/test or Desktop Commander. Preserve history, no force push; fetch live refs and expected-SHA guard each update. Work on this continuation or an isolated descendant, never change another developer's branch unexpectedly. No main merge, release or npm publication. No unchecked axiom, fabricated certificate, kernel bypass, relaxed semantic test or generated execution fuel. Keep psc1/AI_WORK_STATE.md and execution status current. GitHub/CI work and draft PRs are authorized; avoid unnecessary confirmation questions.

## Read these current artifacts

All paths below are inside psc1/:
- AI_WORK_STATE.md.
- docs/PSC1_ULTRA_ARCHITECTURE_AUDIT.md: confirmed defects versus risks and corrected/open status.
- docs/PSC1_PRACTICAL_CORE_DECISIONS.md: fourteen-family bounded v1 contract.
- docs/PSC1_LANGUAGE_BACKEND_PARITY.md and .json: grammar/IR/backend/runtime/ABI/assurance axes.
- docs/PSC1_WASM_ARCHITECTURE_V2.md.
- docs/PSC1_COMPILER_SELFHOST_ARCHITECTURE.md and docs/PSC1_COMPILER_SOURCE_CENSUS_BASELINE.json.
- docs/PSC1_FOREIGN_INTEROP_ARCHITECTURE.md.
- docs/PSC1_SOURCE_REFACTOR_ARCHITECTURE.md.
- docs/PSC1_ULTRA_EXECUTION_STATUS.json and docs/PSC1_ULTRA_FOUNDATION_QUALIFICATION_2026-10-21.json.
- docs/PSC1_TYPED_ERRORS.md and the existing historical qualification receipts.

## Implemented architecture and limits

Both source parsers produce PsSyntaxModule and enter one elaborator. Canonical translation prints this shared AST; neither .lean input nor .ps means unrestricted Lean. Retain existing dependent terms, proof checking/erasure, structures/inductives, structural recursion and existing source forms. Source inductives/matches remain bounded; universe/class/instance/tactic/macro/mutual syntax is not implied by Core support.

Active publication requires captured source/import ownership, independent official admission of the exact canonical graph, exact ordinary logical/body graph pairing when partial, erasure of retained input, strict executable IR checks, target planning, target/ABI validation and atomic publication. Constructing a wrapper or matching JSON does not confer checking authority. Logical admission, IR validity, runtime observations and formal behavioral preservation are separate. Verified execution refuses; no preservation theorem or full self-host is claimed.

Retain the checked expression IR. No wholesale SSA replacement is justified. Fix the specific collection/control costs before reconsidering a new stage. Six closed targets share specialization/revalidation; Rust retains checked generic IR.

Keep all fourteen families in bounded roles: exact operators plus proposition-valued order with real decision evidence; predictable local and call inference; typed Id/Except do; finite List/Array/Nat-range for; ordinary partial while; lexical mutation; early return; ordinary partial definitions; tuples/patterns; persistent arrays/optional indexing; typed handlers; namespaces; typed host IO. Checked libraries express effects; platform adapters express IO. General iterators, mutable heap references, arbitrary monads and advanced dependent patterns are deferred. All fourteen full families remain incomplete; existing green selected fixtures are not family completion.

Seven targets: JS, TS, Rust, core Wasm, component Wasm, Python, PHP. Internal language values and public foreign ABI are separate capabilities. Component ABI remains Bool only. Python/PHP public aggregate marshalling remains unavailable. CompilerM all-target coverage, efficient indexing/iteration and Rust aggregate closures remain work.

Wasm: retain common IR and existing GC core. Qualified W0 uses one Bool schema for WIT and owned component bytes; host independent validation, actual-binary WAT, extracted-WIT equality and atomic publication remain. Reuse PSC0 native33676076bcda7b0de5ec1f9803f49b8b1d28a058 selectively. Its GC/Nat/boxing conventions differ. Compounds require explicit GC↔linear-memory Canonical ABI adapters, checked construction metadata, allocator/post-return and model/validator/encoder changes. Do not claim GC-native Canonical ABI interoperability. Implement W1-W6 from the roadmap without replacing working W0 prematurely.

Compiler semantics belong in portable compiler/backend modules. Host owns filesystem/package capture, checker, external tools and publication. Existing Bridge.CompilerHost and host-tools/compiler-host-protocol.mjs execute generated JS/Rust transport against an external checker, but candidate graph comes from native stage0. They are not a generated frontend/compiler, self-compilation or fixed point. The gateway does not yet publish artifacts.

Portable npm source libraries retain their current v2 contract. Target foreign adapters are separate optional packages with exact package/lock/wrapper identities, typed effects/errors/marshalling and explicit ownership. npm does not become portable across Cargo/Python/PHP. Foreign behavior never grants proof/definitional-reduction/kernel authority. Future refactoring uses lossless trivia/origin/resolved side tables plus re-elaboration/admission and appropriate equality/equivalence obligations; reparse alone proves nothing. Broad interop/refactoring is off first-self-host critical path.

## Corrections qualified in #169

- PrintCommon.psPrintDoBody groups terminal compound terms. Lean→PS→Lean roundtrips retain match alternatives inside inline do while dedented enclosing matches/catches remain owned by their scopes.
- DoTry.psElabDoNoFallthrough traverses immutable letPatternE. A later iteration failure is outside a preceding catch. errorPatternFor is observed against pinned native Lean: false→ok3, true→error9.
- Erasure.Basic reserves emitted ECMAScript intrinsics before collision allocation, preserving source/Core identity and property labels. Independently authored Lean/PS tests exercise global/lexical bindings, escaped-name collisions, source origins and separate JS/TS consumers.
- TS Expr/Module emit computed quoted data keys for record fields, constructor payloads and constructor maps; __proto__ remains an own data field.
- Wasm Component plan validation rejects every bare keyword from pinned wasm-tools1.254.0 WIT lexer; legal keyword-containing names remain accepted.
- Source census prints actual first parse/elaboration refusals, independently of import-blocked rows.

Exact #169 source/test delta before documentation:
packages/syntax/src/Ps/Syntax/PrintCommon.lean;
packages/elab/src/Ps/Elab/DoTry.lean;
packages/erasure/src/Ps/Erasure/Basic.lean;
packages/backend-ts/src/Ps/BackendTs/Expr.lean and Module.lean;
packages/backend-wasm/src/Ps/BackendWasm/Component.lean;
test/TypedErrorTests.lean, TypedErrorFixtures.lean, TypedErrorOracle.lean, BackendCommonTests.lean;
scripts/typed-error-conformance-tests.mjs, backend-architecture-tests.mjs, compiler-source-census.mjs, seven-backend-qualification.mjs.
Inherited #168 also adds Bridge/CompilerHost.lean, host-tools/compiler-host-protocol.mjs, Wasm Component.lean and host wiring, source census probe/drivers, direct component/protocol tests, six workspace backend import mappings, integrated shared parser/AST/printer/elaborator handlers, and the architecture artifacts above. The execution status records the complete changed-file inventory.

## Dependency-ordered execution

1. Enforce actual compiler closure acceptance.
Cloud commands: lake build psc1 psc1_source_census_probe; node scripts/compiler-source-census.mjs. Read dist/scoped-correctness/compiler-source-census/{inventory,stages}.json. Current census is semantic-compiler 67/40/35; directjs-compiler 79/48/41; rust-compiler 83/49/40 (modules/parse accepted/elaboration accepted); those are module/parse/elaboration counts, not self-host percentages. Probe currently hardcodes Lean and marks admission/IR/execution/fixedPoint not-run. Add independently tracked PS lane and strict selected-phase mode. Select the first true refused module, not blocked-by-import cascades. Fix modules topologically: Foundation/Core/Syntax→Environment/Meta→Elab→Erasure/Compiler.Api/Ordinary→CompilerIr→selected backend. First current parse refusal is Ps.Syntax.Ast35:41 at ++ in psSyntaxBindingPatternNames: the selected operator table has no ++. Normalize through a named typed list-append helper or an existing supported append function; preserve left-to-right names and duplicate leaves, and do not silently widen notation. First elaboration refusal is Ps.Erasure.Definition: structuralRecursionArity. Source-confirmed candidate psErasureRuntimePreludeClosure has three explicit binders and returns a list function, but directly calls itself with four arguments; use its existing partially applied smaller-worker pattern before the returned lambda. The module diagnostic does not isolate that declaration, so add per-declaration tracing and execute the candidate before calling it the sole cause. Preserve its signature, budgets and evaluation. Further known source blockers include private modifiers in Elab.Data and Rust.RuntimePlan, debug deriving Repr in CompilerIr.Validate, BEq/Repr deriving in BackendCommon.Plan. Use supported explicit equality where appropriate; preserve qualified/private ownership, never strip or skip unsupported declarations. Completion: complete selected JS closure parses/elaborates without skipped sources in each claimed grammar; exact remaining Rust-only first refusal recorded. Missing/cyclic/import-ownership and malformed sources must refuse.

2. Correct efficient collections/control where reached by compiler workloads.
Elab.Data.psElabArrayGetOption currently folds the full array; replace with checked efficient optional lookup, exact-once receiver/index evaluation, huge-Nat/OOB safety and persistent aliases. Test index0/end/OOB/huge, empty arrays, repeated accesses, evaluation order and all seven targets/both grammars.
Elab.DoFor and Environment.Control currently materialize finite continuation chains. Use the documented checked State→M R worker: minor state lambda; typed Continue State/Done R; recurse only under Continue. Erasure.Definition and Expr preserve worker lambda/IH placement; never globally delay arbitrary recursor hypotheses. Compare same-tool baseline workloads, first-return ranges10^3/10^6/10^9, list first-return, full traversal, skipped divergence, handlers and captures. Inspect actual IR; no work after Done/error, no runtime fuel, bounded stack. Only add a narrow checked worker-application fusion if demonstrated necessary. Completion requires measured time/memory/work receipts and preserved refusals; design alone is insufficient.

3. Qualify whole-closure admission and executable IR.
Use psCompilerPreparationStart→psCompilerPreparationStepParsedWithOrigins. Checked: psCompilerPrepareElaborated→psCompilerAdmissionsFromPrepared→external checker→psCompilerVerifiedIrFromPrepared. Partial source: psCompilerPrepareOrdinary→check .logical→psCompilerOrdinaryIr with retained exact pairing. Then psStrictValidateModule; JS psBackendClosedPlan and psJsEmitValidatedModule; Rust psBackendCheckPublicApi and psRustEmitSelectedValidatedModule. Inventory runtime primitives from reached IR, not keyword guesses. Negative tests: missing imports, unresolved metas, wrong bodies/stale graphs, fabricated wrappers, unknown types, incomplete traversal, unsupported intrinsics and verified requests. Completion: full selected closure independently admitted and original/transformed IR validated, with exact source/primitive inventories.

4. Execute the first real generated JS compiler.
Add a portable scalar transport facade over production preparation/emission; include every dependency in census. Extend Bridge.CompilerHost and host-tools/compiler-host-protocol.mjs with session-bound requests, candidate work state/artifacts, diagnostics and host-only atomic publication. Bind executable/service identity, closure/options/target/graph/artifacts to the pending session. Generated code cannot select checker tools or authorize publication. Generate G1 once with native stage0; remove/deny native compiler frontend/eraser/emitter thereafter. Allow only the explicit independent checker and target tools. G1 must compile handwritten positive/negative multi-module, namespace/private ownership, exact integer, Unicode, pattern, handler and ordinary-loop cases. Keep current scalar public ABI for service transport initially. Completion: actual generated compiler semantics execute with subprocess allowlist logs; a transport wrapper or native delegation is a failure.

5. Establish JS self-compilation and fixed point.
G1 compiles the identical captured compiler+JS closure into G2; G2 produces G3. Use new versioned4.35 generation manifests with exact source closure, compiler/service/tool/graph/IR/artifact identities. Compare canonical admissions, original/specialized IR, deterministic generated source and identical corpus observations. Negative stale manifests, missing/extra files, altered graph/artifacts/checker and prior-publication preservation must fail closed. Do not reuse old checked-selfhost.mjs lean434-wasm/PSC2 receipt schema as current evidence; selfhost-generation.mjs is also historical orchestration. Completion: real G1/G2/G3 execution and repeated-generation identities, exact Linux run/artifacts.

6. Complete Rust owned callbacks, compiler execution and generations.
Where reached, implement recursive owned V(T)=Rc<dyn Fn(V(A)...)→V(B)+'static>, including named generic data/arrays, captures, results and global function-value adapters. Modules BackendRust/{Type,Module,Expr,Captures,Tail,TailAlias,Runtime,RuntimePlan}. Retain existing outer Rc field storage first; no unsafe/RefCell/cycles introduced for convenience. Test captured callbacks in records/inductives/arrays/generic containers, returned/projected/nested callbacks, lexical shadowing, old-value captures and imported private helpers through scalar harnesses. Cargo must typecheck; malformed IR/public ABI refusals remain. Then R1 compiles corpus and identical Rust compiler closure to R2/R3. Include deep AST recursion and final-owner Rc destruction; do not hide stack issues by enlarging stacks. Completion: same admission/IR/generation gates as JS. Raw native executable-byte identity requires separately demonstrated reproducible locked builds.

7. Finish selected Practical Core and source/backend contract.
Use the fourteen explicit decisions; add Prop Nat/Int ordering with genuine admitted decision evidence, required inference/pattern/effect cases and bounded typed IO. IO must include console line input/output AND UTF-8 file read/write with path roots, EOF/newline/limits/typed errors; stdout alone is not completion. Platform adapters refuse unavailable capabilities before publication. Extend ordinary while restrictions only when required and with semantics/oracle tests. Add all-target CompilerM and Unit-pattern execution where missing.
Implement scripts/check-language-backend-parity.mjs over a finite versioned case contract and generated receipts. Reject missing/duplicate/unknown/skipped grammar×target obligations. Record source/import hashes, admission/IR/runtime/ABI/assurance separately; theorem/type-only cases declare runtime not applicable. Both grammars need authored tests, not only translation. Selected-v1 complete means every required case passes all relevant targets and negative boundaries, never a Bool smoke test.

8. Complete Wasm and optional ecosystem work after first self-host prerequisites.
Follow W1 readable owned WAT; W2 checked concrete ABI schema/construction evidence; W3 memory/globals/load/store/allocator/post-return with target validators; W4 String/Nat/Int; W5 arrays/records/variants/indirection; W6 separate effects/resources. Keep Bool W0 working throughout. Test malformed UTF-8/scalars/tags/ranges, overflow/alignment, realloc prefixes, cleanup/reentry/traps and extracted-WIT equality. Real aggregates need real adapters. Implement initial JS/TS and Rust foreign adapters only when demanded; Python/PHP follow with target-specific package/lock/marshalling/lifetime tests. Reconcile legacy package manifests with current native distribution contract before any separately authorized release. Preserve existing offline npm/source-library canaries.

9. Later source refactoring.
Retain trivia/comments, byte spans, stable source/binder identities and typed resolved origins. Stage against input digests; re-elaborate/re-admit closure, preserve public API and use the appropriate alpha/definitional/behavioral relation. Refuse stale or unsupported transformations without replacing output. Keep broad refactoring out of first compiler bootstrap.

## Qualification and stopping rules

After every substantial milestone, run focused native/IR/target/refusal checks, then the full psc1-scoped-correctness workflow at exact head and inspect actual logs/artifacts. Retain psc1-architecture-native for fast control diagnostics. Existing scoped workflow covers host formatting/maps/publication, owned kernel separately, source/runtime/oracle/ordinary divergence, both Python lines, direct components, protocol transport, census and installed packages. Do not drop these gates.

A passing census process means its diagnostic inventory completed, not all source modules accepted. Generated transport is not self-hosting. Kernel acceptance is not a backend preservation proof. Never infer current qualification from PSC0/historical PSC1 receipts.

Report exact completed/pending boundaries, source head/tested merge/run/tool identities, first actionable failures and durable resume commands in AI_WORK_STATE and JSON. Full JS/Rust self-host success needs actual generated compiler execution and repeated generations; broader seven-target language completion and future optional work remain separately assessed. Continue autonomously through the dependency plan.
