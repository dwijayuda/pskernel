# Continue PSC0 / PSCV0 v7 — M2 + Phase A

## F3 scientific literals and conversions — implementation checkpoint, 16 October 2026

The current user authorized completing F3 across all executable backends, then stopping at the next milestone. This commit implements the coherent family; **qualification is pending**. The previous qualified executable remains `9caedc25b4ba373186935a8cf363907ffa8cb6f7` (native38759692425, 872 observations). Do not report F3 or M2+A complete from this checkpoint.

Design: exact scientific tokens feed the shared universe-aware numeric literal/synthetic-constraint path. Select the independently checked 134-declaration F3 logical asset against the frozen pre-F3 environment, explicitly register OfScientific Float/Float32, two checked OfNat dictionaries, and Float's pinned default priority 501. No new assumptions. Exact rational rounding is authored once as typed IR helpers; reserve private support names before local erasure and emit reachable helpers. Rust and Wasm use native fixed-width conversions; JavaScript rounds 64-bit integers directly to binary32 before Number conversion. Wasm uses GC Nat/Int support; no new linear memory.

Pinned references: Lean 4.35.0 `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`, `src/Init/Data/OfScientific.lean`, `src/Init/Data/OfScientific/Basic.lean`, `src/Init/Meta/Defs.lean`, `src/Lean/Parser/Basic.lean`, `src/Lean/Elab/BuiltinTerm.lean`, `src/Init/Data/Float/Model/Unpacked/{Round,Operations/OfScientific,Operations/Div,Operations/OfNat,Operations/ToNat}.lean`, `src/Init/Data/SInt/Float{,32}.lean`, `src/include/lean/lean.h`, `tests/elab/float_conversions.lean`, and `tests/pkg/ofScientific`. Apache-2.0 attribution is retained. Wasm numeric conversions and Rust numeric casts were checked against their official specifications.

Validation plan: build the complete native compiler; preserve strict old declaration/surface digest pins for independent measurement and review before updating them. Replay F1/F2/F3 assets byte-for-byte. Run the existing full native/integration suite with one compact F3 fixture (52 observations), nine custom scientific literal observations, independent pinned Lean oracles, and all shared runtime backends. Expected shared total: 933, not yet qualified. Keep current time/resource ceilings.

Remaining after this slice: F4 display, opaque cross-width float contracts, target USize/ISize profiles, broader M2+A boundaries. Preserve the interleaved M2+A → M3+B → M4+C/D roadmap. No pskernel-core, self-hosting, C5, local execution, new trust assumptions, or claim of compiler semantic preservation.


## Resume contract

The current user authorized completing F3 scientific literals and conversions, then stopping before the following slice. Finish and qualify that coherent family before stopping; do not begin F4. Use the repository and canonical v7 specification as the authority; this prompt summarizes the current boundary.

GitHub repository: dwijayuda/pskernel. Development branch: `psc0/pscv0-v7-native-lean-v1`. Research branch: `psc0/pscv0-v7-f3-conversions-research`. Keep draft PR109 against its existing base; do not merge. Read fresh branch HEADs and exact-commit CI before writing; use expected-HEAD, non-force updates and preserve concurrent history.

Use GitHub integration and cloud Linux CI exclusively: no local checkout/files/builds/tests or Desktop Commander. Author implementation in native .lean. No pskernel-core, bootstrap/self-hosting, compiler-source .ps migration or C5. Application .ps fixtures are allowed. Wasm uses GC internally; linear memory only at explicit Canonical ABI boundaries.

Pin Lean 4.35.0, commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. Before each substantial feature, study the corresponding official Lean source and tests. Adapt the simplest suitable correct mechanism; record source references and Apache-2.0 attribution where applicable. Only approved assumptions: `propext`, `Quot.sound`. No new assumptions, sorry, Classical.choice import, unchecked casts, admission fallback, acceptance relaxation or increased budgets.

## Current qualified boundary

Development commit `9caedc25b4ba373186935a8cf363907ffa8cb6f7` passed all 30 job steps in [native38759692425](https://github.com/dwijayuda/pskernel/actions/runs/38759692425): **872 shared runtime observations** on TypeScript, direct JavaScript and Rust, GC Wasm/core/component checks using the shared observation table, repeated native Wasmtime calls, source/kernel/typed-IR checks, module integration, byte-exact checked assets and existing performance checks. Independent [F1 replay38759692456](https://github.com/dwijayuda/pskernel/actions/runs/38759692456), [F2 replay38759692430](https://github.com/dwijayuda/pskernel/actions/runs/38759692430), and [F3 logical replay38759692551](https://github.com/dwijayuda/pskernel/actions/runs/38759692551) also passed at this exact commit. The final receipt commit changes documentation only; compiler source and workflow configuration remain identical to this qualified commit.

The integrated source was first fully qualified at research `a77f3e5dd52c0267e5443eff1d32081431f5257c` ([native38757435938](https://github.com/dwijayuda/pskernel/actions/runs/38757435938), F1 38757436024, F2 38757435899, F3 logical 38757435982). Research diagnostics and refusals remain in Git history. Development integration preserved both parents and its broader workflow triggers.

M1 is complete. M2+A remains incomplete; follow the existing interleaving M2+A -> M3+B -> M4+C/D -> M5/E. Read the current checkpoint in AI_WORK_STATE.md, docs/PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md and docs/PSCV0_M2_A_SCALAR_COMPLETION_2026-10-14.md. Older checkpoints are historical, not current instructions.

Completed earlier: executable Float F1 bit/model transport, generic/partial/closure and ABI paths; F2 both-width arithmetic, neg/abs, IEEE comparison/classification, canonical logical equality; universe-polymorphic Array and List foundations; transactional scoped default instances. This slice adds:
- Shared synthetic OfNat constraints using a fresh Type(u), raw Nat index, and expected-type information; no eager Nat shortcut, including for a local OfNat Nat dictionary.
- Native Add/Sub/Mul/Div/Mod/Append classes and six generic H* bridges; 57 checked homogeneous dictionaries replace redundant ground heterogeneous search/runtime entries. Frozen logical asset boundaries remain intact.
- Standard defaults: six bridges at 1000, Neg Int at 500, OfNat Nat at 100. Ordinary synthesis reaches quiescence before default commitment.
- General class-projection reduction at instances/implicit transparency; preserve stuck applications and irreducible dictionary boundaries. Native projection status and constructor metadata determine eligibility. Opaque ordinary constants keep the cheap path.
- Standard instance factories supply instanceReducible only when explicit metadata is absent. Imported or explicitly overridden statuses remain authoritative.

Selected snapshot v3 / surface v2: FNV `4909868320704722088`; declaration SHA-256 `990f59c079198da859bbe7b98e11dc96ca6668851825f48df5fadeb24524148f`; surface SHA-256 `e188d6f21d7ac7604ebbd41d34f48b626b1385789da98c0f288bbc1162fe2098`. Independently measured at both strict boundaries in native38754937813 before updating pins. Selected Standard has **3,179 declarations /31 classes /256 ordinary instances /8 defaults**; native38757435938 independently reports the declaration/class/ordinary counts and the strict registry audit checks each default.. Pins and observations alone are not a semantic preservation theorem.

## Next coherent slice — scientific literals, then F3 conversions

No scientific frontend implementation is included in this checkpoint. Earlier in-memory drafting is not durable repository evidence. Reconstruct against the current qualified source instead of assuming it exists.

1. Inspect the whole syntax/literal/constraint/selected-Standard subsystem and pinned references below. Preserve scientific spelling and spans in tokens/AST/printers; decode exact mantissa, exponent sign and magnitude without host floating-point parsing. Reuse the numeral constraint owner with a checked, universe-aware OfScientific dictionary. Custom instances must observe the distinction between 1. and 1e0. Keep range punctuation unambiguous and malformed literals refused.
2. The F3 logical candidate already has independent cloud replay: 42 roots /134 declarations /one recursor /3,286 shared nodes /617,019 UTF-8 bytes, SHA-256 `45e6c8b81fbd971c891d173acef36c2ce6f6c59b674a06ffc9bfbe2e8cff6391`. It remains unselected. Reuse existing host StandardExport authoring and research workflow. Freeze the pre-F3 environment before selection so asset regeneration remains byte-exact. A frontend-only selection can admit just OfScientific, mk, ofScientific and rec before executable floating conversions; do not claim F3 completion from that prerequisite.
3. OfScientific Float/Float32 dictionaries are in the logical candidate; OfNat Float/Float32 dictionaries still need review. Float's scientific default has native priority 501; Float32 has no default. Cross-width opaque conversions and target-sized words have separate logical contracts.
4. Implement conversion operand/result typing once in shared IR and erasure; don't blindly unwrap every argument as a Float.Model. Readable JS/TS, safe Rust and GC Wasm must agree. Integer/scientific conversion rounds directly to the target width, nearest-even; Float32 through an intermediate Float64 can double round. Float-to-fixed-integer truncates toward zero, saturates, and maps NaN to zero.
5. Evaluate a single shared typed-IR exact-rational rounding helper, reusing existing arbitrary-precision Nat operations, against separate backend helpers. This is an unimplemented design candidate, not an approved semantic replacement. Preserve bounded native fast paths, exact overflow/subnormal behavior, and fail-closed checked logical/runtime boundaries. Wasm saturating conversion opcodes require the existing binary/WAT instruction descriptor to represent prefixed subopcodes coherently.
6. Finish F4 display, explicit USize/ISize target profiles and authoritative M2+A exits before advancing the roadmap. No new milestone track is needed.

## Primary reference map

All Lean paths below are relative to pinned leanprover/lean4:
- Literal/operator slice: src/Init/Prelude.lean, src/Init/Data/Int/Basic.lean, src/Lean/Elab/BuiltinTerm.lean; tests/elab/{hmulDefaultInstance,dotNotationAndDefaultInstance,ofNat_class}.lean.
- Class projections: src/Lean/Meta/{WHNF,GetUnfoldableConst,Basic,TransparencyMode}.lean; tests/elab/{instanceReducibility,isDefEqProjInstWithMVar,reducibleClassField_perf}.lean. Lean.mkNatLit builds an overloaded numeral; use Lean.mkRawNatLit for raw Core indices/oracles.
- Defaults: src/Lean/Meta/{Instances,SynthInstance}.lean, src/Lean/Elab/SyntheticMVars.lean, src/Lean/Elab/Term/TermElabM.lean; tests/elab/{defaultInstanceWithPrio,defaultInstBacktrackIssue}.lean and tests/elab_fail/defaultInstance.lean.
- Scientific: src/Lean/Parser/Basic.lean (decimalNumberFn/takeDigitsFn), src/Init/Meta/Defs.lean (decodeScientificLitVal?), src/Init/Data/OfScientific{,/Basic}.lean, src/Lean/Elab/BuiltinTerm.lean; tests/elab_fail/scientific.lean and tests/pkg/ofScientific (including double-rounding vectors).
- Floating model/conversions: src/Init/Data/Float/*, src/Init/Data/Float/Model/Unpacked/Operations/{OfNat,ToNat,OfScientific}.lean and src/Init/Data/Float/Model/Unpacked/Round.lean; tests/elab/float_conversions.lean; src/runtime/object.cpp and src/include/lean/lean.h.

## Validation and handoff discipline

Implement coherent mechanisms before broad tests; use compact native differential checks and the existing full backend/integration suite at meaningful milestones. Preserve source/kernel/typed-IR boundaries, readable JS/TS/Rust/WAT/WIT and source origins for deferred reconstruction. Keep scoped runtime conformance distinct from checked logical admission and formal preservation.

Independent authoring declarations use Lean's pooled-task kernel-counter reset. Source requests retain cumulative 2,000,000-heartbeat /20,000-depth limits; allocation telemetry is a separate measure. No budget increases.

Update both AI_WORK_STATE.md and AI_CONTINUE_PROMPT.md, roadmap, scalar design and PR109 at every qualified milestone. Stop before the next slice when the user requests that boundary.
