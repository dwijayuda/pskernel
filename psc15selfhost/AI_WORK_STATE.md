# AI Work State

Master plan: THE_PSCV_COMPILER_REFERENCE_VERSION_3.md
Branch: pscv/v3-execution

## Active execution

Mode: implementation first, as requested on 2026-10-07. Continue research and implementation with focused compilation, portable-profile and boundary checks. Extensive regression campaigns, fixed-point reruns and formal assurance are deferred to the later assurance pass; existing CI failures remain recorded and actionable. No implementation milestone implies final V3 acceptance.

- Complete 57-section map and workstream ledger: `contracts/registry/V3_IMPLEMENTATION_STATUS.json`.
- Deferred evidence and proof obligations: `contracts/registry/V3_ASSURANCE_HANDOFF.json`.
- Current checkpoint: portable dependency interface and link validation; production checked service and candidate/internal/bootstrap ownership are committed at fc7bc7b.
- Portable compiler code must continue to satisfy PSC1-selfhost-stable/1 and PSC1-portable-selfhost/1. No profile weakening, unchecked promotion, fabricated proof, or history rewrite.

## Next

1. Bind pass executions and build graph nodes to canonical artifacts, declared assumptions, resources and actual evidence. Keep pending validation/proof evidence explicit.
2. Complete target-specific interface adapters, backend validation, incremental interfaces/cache/resources, and comparator security mechanisms.
3. Complete executable/logical interop, SAVEF/offline archive tooling and FactoryBench implementation; leave missing independent evidence and global theorems explicit.
4. Maintain the ledger and handoff after each meaningful checkpoint. Do not call scaffold presence or implementation availability final acceptance.

## Historical checkpoint P0/P2/P3

- architecture/contract registry, ProviderSecurityProfile, compiler-wide TrustManifest and initial checked host identity implemented.

## Checkpoint P1/P4/P5/P6

- public Node `psc build` now routes through checked-build; `build-unchecked` is explicit bootstrap/internal
- algorithmic-defeq cache contract registered; non-transitive relation forbids union-find/transitive closure without proof
- VerifiedIR v1 gap registry is machine-readable
- PsSpecializedIrModule added in PSC1-selfhost-compatible Lean source
- validated JS/Wasm specialization paths now construct the explicit SpecializedIR capability
- next: open PR/cloud CI, then pass/build evidence + ModuleInterface semantic fingerprint prototype

## Checkpoint P7/P8/P12/P13

- generic PSC1-compatible PassDefinition/PassExecution model added
- specialization now has explicit current assurance metadata and can emit PassExecution
- typed structural ModuleInterface fingerprint replaces untyped QueryGraph interfaceKey
- current host extraction remains conservative canonical-admissions semantics, now versioned by contract
- Comparator-v1 challenge/replay scaffold added; current status is process-isolated prototype, not yet a production sandbox
- next: cloud validation, then declarative theory seed, defeq/cache source enforcement, SAVEF object format and verifier capsule

## Checkpoint P9/P16/P17/P18

- declarative Core theory seed registered with explicit target-unproved theorem status; no proof claim fabricated
- minimal local SAVEF KnowledgeObject format implemented with deterministic canonical hashing and fail-closed tamper detection
- specialization pass contract exported as the first SAVEF knowledge object
- offline pscv-verify prototype validates architecture/trust/provider-security/SAVEF closure without the full compiler
- FactoryBench-v4 holdout policy scaffold frozen with searchableByFactory=false; task corpus remains intentionally pending/sealed
- next: strengthen defeq cache source audit, add theory definitions/proof skeletons where self-host-compatible, then Wasm validation evidence

## CI repair checkpoint

- direct Rust semantic and source corpora passed; exact let-function-result rendering assertion was stale after canonical Rc/move function-result emission
- updated the regression to lock semantic ownership/ABI substrings without requiring the obsolete redundant local type annotation

## Checkpoint P15

- added PSC1-portable Wasm translation validator for a closed literal-declaration slice
- validator independently checks source SpecializedIR against WasmIR export/signature/body and fails closed on unsupported shapes
- negative drift test changes 42 -> 43 and must be rejected

## Checkpoint P10 formal seed

- added portable @proofscript/pscv-theory package
- real Lean proof terms establish declarative-conversion reflexivity and the exact-identity algorithmic-defeq quick slice
- full checker soundness remains explicitly target-unproved
- source audit enforces pair-local success-cache implementation and rejects equivalence-closure machinery
- theory package is wired for Lean build/test and psc1 checking under the portable self-host discipline

## Checkpoint behavioral/resource/SAVEF acceptance

- added typed BehavioralModuleInterface and PsCertifiedModuleInterface without changing current structural QueryGraph reuse semantics
- added psc-compilation-resource/1 with typed outcome classes and a concrete small->larger budget acceptance regression; general monotonicity remains target-unproved
- SAVEF now contains pass, formal-theory, and module-interface validation objects under one canonical object format
- offline verifier checks all three knowledge objects
- Version-3 15-criterion acceptance audit is wired into check:workspace
- current next gate: cloud CI must compile/check portable theory, Wasm validator, direct self-host fixed points, Rust self-host, and architecture acceptance together

## CI repair: portable Wasm closure

- cloud CI correctly detected that the new portable Validate.lean root expanded backend-wasm's minimal portable entry closure
- portable profile expectation now includes Validate.lean explicitly
- no profile weakening or new repair guard was added

## Checkpoint assurance/interoperability/archive

- provider IndependenceVector records shared and diverse checker axes; boolean independence is forbidden
- TrustDelta and SemanticDelta contracts distinguish trust expansion, semantic change, representation change, and security-only hardening
- portable TheoryBridge model and identity bridge added for logical interoperability; cross-foundation preservation remains per-bridge target-unproved
- semantic lock prototype binds source/Core/kernel/runtime/IR/provider-security/trust identities
- archive profile requires offline-verifiable contracts, trust, SAVEF objects, and verifier capsule
- offline verifier now binds semantic lock, archive profile, independence vectors, and all current SAVEF evidence

## Checkpoint promotion/bootstrap gates

- direct-JS canonical promotion is now machine-gated and remains intentionally NOT promoted while global erasure/specialization/JsIR preservation is incomplete
- bootstrap assurance B0-B10 is machine-classified; fixed point, reproducibility, DDC, and verified bootstrap cannot be conflated
- B7/B8 direct JS/Wasm bootstrap have existing fixed-point gates; B9 diverse bootstrap and B10 verified bootstrap remain explicitly incomplete

## Strict VerifiedIR implementation checkpoint

- legacy PsValidateErasedIrModule behavior split into psValidateErasedIrModuleReferences as the reference/shape first stage
- new portable Ps.CompilerIr.Validate module is now the production psValidateErasedIrModule entry point
- strict stage checks global uniqueness, type names/parameters, lexical variables, declaration calls, all current intrinsic signatures, exact aggregate fields, field typing, projection target typing, if typing, match binding typing, duplicate alternatives, branch result equality, and match exhaustiveness
- dedicated psc1_verified_ir_strict_tests corpus added and cloud CI gate wired
- external cross-module ABI/link compatibility remains intentionally deferred to InterfaceIR/link validation; gap registry will not be marked closed until the strict corpus and self-host fixed points are green

## 2026-10-07 continuation: portable validator and checked proof ownership

- Continued from GitHub HEAD 1dbfde24d7596f08dcb172947a5598383d185137; no earlier checkpoint restarted or history rewritten.
- Diagnosed cloud run 37502916227 (invalid erasure proof), 37502916378 (PSC1 grouped-lambda parse failure), and 37502916392 (the same parse failure plus a missing strict-validator import in the JS fixture).
- Strict validation now uses a named field-name walker and partial application instead of grouped inline lambdas; stable and portable profile rules are unchanged.
- Portable theory source retains executable witness/model data. Indexed propositions and Lean proof terms live in an explicit proof sidecar, compiled by the required theory gate; unsupported dependent Lean syntax is not presented as PSC1-portable.
- Repaired conditional proof omission with a checked if-elimination term. Lean 4.34.0 compiled the proof sidecar and specialization slice locally. SAVEF evidence paths and canonical object hashes now identify that sidecar. Global preservation and checker soundness remain target-unproved.
- Restored the JS fixture strict-validator import and updated the offline verifier assertion to check all five returned object identities.
- Local results: strict corpus 20/20; PSC1 validator/theory-source checks; strict-validator TypeScript emission; source and portable static profiles; JS backend corpus; Lean theory tests. Whole-closure/cloud checks remain pending, so no VerifiedIR gap is marked closed yet.

## VerifiedIR adversarial follow-up

- Added a counterexample with an unresolved phantom generic argument consumed by a match, and a forged structure named Array accepted as the built-in array type. Both were accepted by the prior validator.
- Constructor, projection, and match type arguments now undergo explicit scope/name validation; the built-in Array identity participates in global uniqueness.
- Expanded strict corpus from 20 to 31 cases, including call argument/result types, duplicate constructor fields, duplicate binding fields/locals, built-in arity, and a valid phantom-generic control. Four new rejection checks fail on the previous compiled validator and all 31 pass after the fix.
- fd7313b passes the local 56-module stable self-host contract with canonical source/admissions/TypeScript parity; the full workspace gate also passes. Cloud progressed through strict tests and now exposes backend closure-emission failures being repaired next.

## Backend closure repair checkpoint

- Cloud fd7313b: strict VerifiedIR, workspace/theory, Rust portable source and semantic gates progressed successfully. Wasm whole-compiler generation failed on an expression-valued call target; Rust Cargo compilation exposed an obsolete outer `move` prefix around the Rc-owned closure expression. Direct-JS fixed-point runs were still executing when this follow-up was prepared.
- Rust function-result emission now uses the owning closure expression emitted by the expression layer, without invalid `move { ... }` syntax. The compile fixture includes a let-captured closure; the Cargo gate now also executes repeated-call and callback-forwarding regressions.
- Wasm lowering carries the module declaration types through its worker, infers expression-valued callees with the strict IR type checker, evaluates each callee once into a local, and uses the existing typed closure-call path. Global function values receive typed wrappers with non-colliding generated parameter names.
- Local evidence: Wasm unit corpus and Node runtime corpus pass (including conditional callee selection, returned closure calls, and global function values); the whole SelfHostWasm compiler emits 702648 bytes which Node independently validates and instantiates. PSC1 checks and TypeScript emission of the Wasm lowerer pass. Rust semantic tests pass; local Cargo execution is unavailable because the installed Windows Rust toolchain lacks link.exe, so pinned Linux cloud Cargo remains required.
- No preservation theorem or fixed-point success is inferred from generation or instantiation. Cloud acceptance and remaining VerifiedIR link/interface gaps remain open.

## 2026-10-07 Rust callback ownership checkpoint

- GitHub head 8835161 passed native benchmark, portable kernel gates, M4 provider parity, bounded JS/Wasm baseline, strict VerifiedIR corpus, and whole-Wasm build/instantiate. Full Wasm recompilation failed with a stack overflow; direct-JS fixed-point jobs were still running when inspected. These are not successful bootstrap claims.
- Rust cloud run 37507278180 progressed past fixture compilation and found global function items used where Rc callbacks were required, sibling move closures consuming the same local, and captured variables returned by move. The emitter now tracks lexical locals, clones only free captures into each closure, returns owned local values, and coerces global function values to inferred Rc callable signatures. Direct calls and validated static function storage preserve their existing representation. Array callbacks consistently use Rc. Generic emitted values have Clone + 'static bounds because this IR has owned runtime values, without borrowed-lifetime types.
- Regression fixture covers reusable captured closures, sibling closures sharing a Nat, forwarding a global callback through a shadowing let binding, and conditionally selected globals. Cargo executes these tests in cloud CI.
- Local evidence: both Rust Lean suites pass; PSC1 checks Captures (444 declarations) and Module (523); stable all-portable source audit (262 modules) and PSC1-portable-selfhost/1 audit (84 modules) pass. Rust metadata-only checking of the full emitted SelfHostRust compiler and the expanded fixture passes. This bypasses linking only for local type/ownership diagnosis; it does not substitute for Cargo execution or the three-generation Rust fixed point. Local Windows lacks link.exe. Global preservation theorems and full V3 acceptance remain unproved/incomplete.

## 2026-10-07 Wasm tail-call checkpoint

- Reproduced the cloud full-compiler stack overflow locally with an expanded stack trace. The first failures combined byte-position scanning and lexical character-list construction. The Wasm instruction model/encoder now supports return_call (0x12) and return_call_ref (0x15), as specified by WebAssembly Core. A portable backwards pass promotes only calls in genuine function-tail positions, including nested conditional arms; computations/casts/stores after a call prevent promotion. Applied to generated functions and runtime helpers.
- The UTF-8 byte-size runtime worker now accumulates a Nat and makes a tail call, preserving arbitrary-precision byte counts. Tests cover nested tail branches versus a non-tail call, 200,000 recursive UInt32 calls, and an 80,000-byte Unicode string constructed from supported-size literals. Both Wasm unit and runtime suites pass. The engine rejects single array.new_fixed lengths above 10,000; the long-input test uses four 5,000-character chunks. General large-literal emission remains a backend limitation to address, not a proof claim.
- PSC1 checks the new TailCalls source (415 declarations). All-portable source and portable-selfhost audits pass (263 and 85 modules). The full workspace audit passes its 17 milestone checks, not full V3 acceptance.
- Whole-Wasm recompilation now advances past those runtime recursion failures but still overflows in a non-tail lexical source-to-list worker. Next action is a semantics-preserving portable accumulator rewrite and continued full fixed-point diagnosis. No Wasm fixed-point success is claimed.

## 2026-10-07 VerifiedIR invariant registry reconciliation

- Moved the 15 strict executable invariants already implemented in Validate.lean from gaps to implemented. The registry now records 30 implemented invariants and two open boundaries: external-import interface/ABI compatibility and module-link compatibility. Evidence is explicit: the 31-case strict corpus, validator path, and successful strict-corpus cloud step on 8835161 (run 37507278125, job 112419614389). This records executable checks only; it does not certify validator soundness, global preservation, or a full compiler fixed point.
- Cloud run 37510526556 stopped in BackendRustSourceTests because scalar snapshot expectations still required bare local returns. Corrected those expectations to the new owned local return form. Both Lean and ProofScript scalar-source tests pass locally; the accepted language and self-host profile were not relaxed.
- Direct-JS cloud run 37507277988 timed out after 20 minutes during generation-2 preparation at module 41/58 (Elab.Term), before VerifiedIR validation. Performance diagnosis is active rather than treating a timeout as a successful bootstrap.

## 2026-10-07 portable traversal and direct-JS UTF-8 checkpoint

- Rewrote character collection and token collection as structural accumulator workers, preserving order, UTF-8 byte offsets, and the previous fuel behavior. Foundation list length and lexer/parser length wrappers now use a structural accumulator. Bootstrap tests pass, including zero/partial fuel, UTF-8 offsets, 20,000 characters, and lexical EOF/fuel boundaries. Compared the old and new token workers on the affected source fixtures and Unicode/trivia cases: token text and offsets are identical. Three previously failing bootstrap fixtures used stale ProofScript semicolons; updated only those inputs to the printer/parser's current newline/block syntax while retaining the same shape and elaboration equality assertions.
- Direct-JS String.get/next/atEnd and UTF-8 byte size now share an index for exactly one immutable string. This preserves misaligned/out-of-range fallback behavior and bounds retained cache entries to one string. Reserved the two helper names to avoid emitted global collisions. Unit corpus and differential TS-backend corpus pass, including cache replacement, all offsets around mixed Unicode, and 70,000-byte sequential access. PSC1 checks the changed printer (782 declarations); stable and portable source profiles pass.
- The generated-JS performance profile for preparing Lexer still shows substantial recursive-call bookkeeping/GC and repeated token-list counting, beyond UTF-8 traversal. Full fixed-point verification is not complete. The local diagnostic fixed-point attempts predate the final ParseCommon wrapper change and are not acceptance evidence for this checkpoint. Next work: remove the remaining source-preparation bottlenecks without weakening admission/profile checks; continue Rust cloud compilation and Wasm full recompilation.

## 2026-10-07 parser cursor count checkpoint

- A generated-JS CPU profile identified repeated parser token-list length scans alongside call bookkeeping and GC. PsTokenCursor now retains its remaining-token count, computed once at construction and decremented as tokens are consumed. Parser fuel bounds use that count; dotted-name parsing preserves the same bounds and token order.
- Lean 4.34.0 checks a separate proof sidecar for accumulator/list-length equality and cursor count preservation under construction, advancement, and prefix removal. These are local invariant theorems, not a proof of the whole parser or global compiler preservation.
- Bootstrap tests pass, including a dotted-name cursor regression; PSC1 parses/checks ParseProofScript (258 declarations), and stable all-portable and portable-selfhost source audits pass unchanged. The latest full generated-JS run is still pending, so the optimization is not recorded as a successful fixed point.
- GitHub e9778df has green native benchmark, provider parity, bounded JS/Wasm baseline, and portable kernel gates. The full Rust/JS/Wasm self-host gates remain in progress and must be followed before acceptance claims.

## 2026-10-07 Wasm large-literal checkpoint

- Replaced unbounded string-literal array.new_fixed emission with structural, at-most-4096-character chunks joined by the existing string append runtime. The worker accumulates emitted instructions, preserves code-point order, and emits the existing empty-string representation. This removes the previously observed engine rejection above 10,000 array.new_fixed operands.
- The runtime corpus now compiles and executes one 20,000-character emoji literal (80,000 UTF-8 bytes), plus a mixed-Unicode content-equality check crossing the chunk boundary and spanning over 14,000 characters. Wasm unit/runtime tests pass. PSC1 checks RuntimeString (470 declarations), and the portable profile remains unchanged and passing.
- No whole-compiler fixed-point or general translation-preservation theorem is inferred from these bounded runtime checks.

## 2026-10-07 fresh eta application checkpoint

- Erasure now applies freshly generated eta variables through let/if/match results and binds immediately returned lambda parameters directly. The helper is restricted to arguments created by the existing freshness scan; it is not general beta substitution and is not used for effectful/computed arguments. Portable structural recursion and source admission rules remain unchanged.
- Added a cloud-wired JavaScript/Wasm runtime corpus covering both branches, match cases, shadowed parameters, deliberately colliding eta-name candidates, opaque callback forwarding, and 1,000 recursive calls. Lean and canonical ProofScript source produce identical JavaScript. The existing erasure, specialization, and Rust source suites pass; PSC1 checks the erasure module (736 declarations).
- A generated-JS diagnostic profile on the same Lexer preparation workload decreased from approximately 122 seconds to 88 seconds locally. This is a workload-specific measurement, not a full fixed-point or benchmark-acceptance claim.
- The runtime corpus exposed unconditional self-host Wasm ABI injection into ordinary modules lacking the specialized byte-list types. ABI helpers are now added only when their required byte-list type family exists. The ordinary module compiles/executes without those helpers; the full SelfHostWasm compiler still builds and instantiates with the helpers (667115 bytes).
- The full emitted SelfHostRust compiler passes local metadata-only type/ownership checking. The 56-module stable self-host contract passes canonical source, admissions, and TypeScript parity. Local source/profile and workspace gates pass; general erasure/specialization preservation remains target-unproved.
- GitHub e9778df direct JS timed out after 20 minutes at source preparation module 13/58 (run 37512767797, job 112438116083). Native Rust built and entered generation-2 compilation, then overflowed its stack (run 37512768115, job 112437895111). These remain failed full-bootstrap results. The cached-count and eta changes require a new cloud run; the earlier local cached-count fixed-point diagnostic was interrupted and is not acceptance evidence.
- User requested stopping before the next stage. Finish publishing/checking this repair checkpoint, then stop before further invariant/link work, global-preservation work, or promotion/bootstrap acceptance work. The two VerifiedIR interface/link gaps, full fixed points, global proofs, diverse/verified bootstrap and final V3 acceptance remain open.

## 2026-10-07 implementation-first authority checkpoint

- Reconciled all 57 reference sections into an explicit workstream ledger. Scaffolding, implementation availability, assurance and release acceptance remain separate states.
- Split the portable compiler into Model, Frontend, Candidate and Internal owners. Compiler.Api and each driver Compiler module are compatibility facades over explicitly marked bootstrap transforms. Existing declaration identities and bootstrap entry points are preserved.
- Production checked-build now composes a checked service. Live session handles bind target policy, provider/security identity, semantic/assumption/resource policy and exact accepted admissions. The service supports TS, direct JS, Rust and Wasm emission through those handles, revocation, session closure, output bounds and byte-digest receipts. Receipts cannot recreate authority. Transformation preservation remains explicitly unproved, and trusted host composition does not claim to sandbox malicious host code.
- Production import topology audit rejects raw transform references outside the checked session and checks candidate/internal ownership. Existing source guards retain their assertions under the new owners.
- Focused evidence: Lean compiler build, PSC1 Internal check (1993 declarations), portable profile (91 modules), source-owner guards, authority topology, and 25 checked-session/service tests pass. Extensive whole-closure and formal campaigns are deferred by user instruction.
- GitHub 0849ae7: four bounded/native/provider workflows passed; direct Rust run 37516533780 passed fixture execution and whole-compiler generation, then failed its native fixed point with a stack overflow. This is an open implementation/assurance issue, not successful bootstrap evidence.

## 2026-10-07 portable interface and link checkpoint

- The default strict validator now rejects external imports without an interface context. The explicit context validator checks provider/export resolution, exact function/value signatures, semantic/runtime-value profiles, declared target availability, required capabilities and recursive public layouts. It rejects unresolved foreign representations rather than assigning meanings silently.
- The portable link validator derives exported signatures from actual declarations, validates all bodies, enforces public export visibility and transitive capability declarations, and returns deterministic dependency order. Duplicate identities, missing providers, cycles, generic exported declarations and forged linked-module host contracts fail closed. Host contracts retain explicit assumption identities; matching metadata does not establish foreign code behavior.
- Added the runtime-values/link contract and 20 focused boundary cases, including nested layout drift, recursive types, invalid bodies and capability laundering. All pass locally, as do the existing 31 strict cases and JS backend corpus. PSC1 checks Link and its closure (427 declarations); structural rules for both new modules, all-portable source (273 modules) and portable-selfhost profile (91 modules) pass without rule changes. The focused corpus and PSC1 check are registered in cloud CI.
- The invariant registry now has 37 implemented checks. The original external-interface/ABI gap is narrowed to target-specific external ABI adapter validation; module-link compatibility is implemented for the declared acyclic, monomorphic boundary profile. Artifact/evidence binding, target-specific adapters and global validator/link soundness remain pending and are explicitly recorded in INTERFACE_LINK_V1.json.
- Continue immediately with artifact/pass evidence and real build integration. Extensive testing and formal proof campaigns remain deferred; no release or promotion gate has been relaxed.
