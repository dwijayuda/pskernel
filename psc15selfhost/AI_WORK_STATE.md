# AI Work State

Master plan: THE_PSCV_COMPILER_REFERENCE_VERSION_3.md
Branch: pscv/v3-execution

## Active execution

Checkpoint P0/P2/P3:
- architecture/contract registry: implemented in this checkpoint
- ProviderSecurityProfile: implemented in this checkpoint
- compiler-wide TrustManifest: implemented in this checkpoint
- checked host capability identity: strengthened in this checkpoint
- PSC1 self-host rule: all future portable Lean/ProofScript compiler code must pass PSC1-selfhost-stable/1 and PSC1-portable-selfhost/1 where applicable

## Next

1. close production AdmissionReady -> erasure bypass without breaking the bootstrap-only self-host path
2. make algorithmic-defeq/cache contracts machine-readable
3. finish VerifiedIR invariant gap registry
4. introduce explicit SpecializedIR capability using PSC1-compatible source patterns

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
