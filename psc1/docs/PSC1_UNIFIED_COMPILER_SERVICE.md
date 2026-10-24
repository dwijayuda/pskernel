# Unified generated compiler service

The default portable composition root is `Ps.CompilerUnified.Service`.
It imports the existing JS, TypeScript, Rust and owned Wasm compiler services,
including the same frontend, elaborator, checked IR and verification pipeline.
Python/PHP emitters are absent from this closure and remain explicit optional
native provider packages from PR177. No handwritten compiler is introduced.

An execution engine is the runtime running the generated compiler. The output
target is selected independently for each request. The scalar entry point
`psCompilerServiceCandidate : String -> String` accepts a structured request (identity placeholder shown):

```json
["psc1-unified-compiler-service/2","rust",["psc1-compiler-service/1","request-id","<closure-sha256>","lean","checked","Entry",[["Entry","def truth : Bool := true\n"]]]]
```

Output targets are `js`, `ts`, `rust`, and `wasm-core`. The response is the
existing target-pinned candidate/refusal protocol, including original and
transformed IR and the host admission request. The generated service cannot
admit or publish its own result. Unknown targets (including optional Python/PHP)
and malformed envelopes refuse without source output. Nested wire, assurance,
source ownership, strict IR and public ABI refusals remain owned by the same
compiler services.

The native distribution retains its qualified fifth default output,
`wasm-component`, through its existing checked host adapter. That adapter is
not part of this portable composition root. A generated component-emission
claim must receive its own adapter/integration qualification.

## Linux qualification

```sh
lake build psc1_unified_service_seed psc1_unified_service_tests psc1_independent_checker psc1_source_census_probe
.lake/build/bin/psc1_unified_service_tests
node scripts/generated-target-source-audit.mjs js unified
node scripts/generated-target-qualification.mjs js --self-host correctness-1800s unified
```

Replace the execution engine `js` with `ts`, `rust`, or `wasm-core`.
The source closure and exported service are the same for every engine. Source
audit checks both grammars. Qualification makes one native seed call, removes
native compiler executables, executes all four output targets with the frozen
five positive/five negative corpus cases, checks nine envelope/optional-target
refusals, and attempts G2 and G3 from the exact enlarged source. Each successful
candidate requires official independent Lean admission. Source, admissions,
original/transformed IR, per-target observations and raw executable bytes must
match the G1 baseline. Operational manifests contain timing/path metadata and
are not themselves fixed-point artifacts.

The new unified Rust correctness executable uses optimization 0/codegen-units=256; exact archived15.2MB compiler source builds in51.7s, whereas both measured optimization 1 layouts exceed240s. This is an explicit correctness-first build setting for the enlarged service; historical single-emitter Rust remains optimization 1. Its stable Cargo package path and verified per-generation inputs prevent generation paths from changing crate metadata. Optimization1 target-build throughput remains a tracked blocker, separate from self-compilation execution.

Long CI qualification requires an explicit request-only commit at .github/qualification-requests/psc1-unified-selfhost.json. Select engines by a closed targets list; pin parentCommit to the fresh HEAD, action qualify-independent-G1-G2-G3, profile correctness-1800s, g1TimeoutMs 240000 and g2g3TimeoutMs 1800000. Ordinary edits do not launch long chains. Normal full CI retains the native unified dispatch/refusal gate and all seven-backend checks.

G1, corpus and target tools retain240s; official checker retains120s; only exact
G2-self/G3-self requests use the existing1800s correctness profile. The240s
performance profile remains separate. Semantic fuel, memory/stack policies,
source pairing and all negative tests are unchanged.

Artifacts are under `dist/generated-unified-<engine>-compiler/`, with source
inventories, exact requests/candidates, generated executable manifests,
independent-admission identities, process diagnostics and qualification.json.
The enlarged compiler earns qualification only for engines with actual passed
G1/G2/G3 evidence. Historical single-emitter chains and native package
qualification do not qualify the new composition.

## Evidence boundary

The first string-envelope v1 source b2ab4d34 genuinely passed JS and TS G1/G2/G3 and executable/source/admission/IR/four-target fixed points. V1 Wasm G2 reached1800s; Rust first exceeded the240s optimized target-build limit, then its optimization 0 retry passed G1 but overflowed the stack in G2. V2 removes the avoidable whole-request JSON string and directly feeds the existing decoded request to the same compiler/emitter APIs. Current v2 source `783cf8fc` passes all four G1 engines (160 corpus cases/36 envelope refusals), both source grammars and immutable originalIR/admission parity. V2 G2/G3/fixed points are not run in this milestone. See PSC1_UNIFIED_SELFHOST_QUALIFICATION_2026-10-25.json for exact independent scopes and artifacts.
