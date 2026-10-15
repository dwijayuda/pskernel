# Continue PSC0 / PSCV0 v7 — after qualified F3, M2 + Phase A

## Active continuation — remaining M2+A, 16 October 2026

The latest user request supersedes the previous stop-after-F3 instruction: continue until remaining M2+A is completed. F3 remains qualified at development bc69717469bbe72249d0d18022b1a51fa5cdd817; receipt 391d1083bc8e1b096690e52603b777af2c5974e1. Current research reviews F4 display and opaque Float/Float32 cross-width contracts before selecting them. Nothing beyond F3 is yet qualified.

Studied pinned Lean 4.35.0 Float/Float32.toString, repr and instances, native runtime/object.cpp, include/lean/lean.h, tests/compile/float.lean and its expected output, tests/elab/float32.lean. Runtime display uses fixed six decimal places with nearest-even rounding, canonical NaN and signed zero; host default string conversion is not sufficient. Planned implementation reuses shared typed-IR exact binary rounding and ordinary checked Format/Repr. Native opaque bodies/instances are exported with full official-kernel replay; no new axiom or unfolding rule. Cross-width conversions use native IEEE promote/demote through shared typed IR.

Continue F4, target-word profile ownership and selected API/registry/M2 exit audit in the existing M2+A -> M3+B -> M4+C/D -> M5/E roadmap. Keep native .lean, GitHub/cloud CI only, no pskernel-core/self-hosting/C5; update both handoffs each qualified milestone. Preserve all acceptance and resource ceilings.


## Current task boundary

The user requested F3 scientific literals and conversions across all backends, updated handoffs, and stopping at the next milestone. F3 is complete and qualified on the development branch. This request is finished; stop before F4. A subsequent explicit continuation may resume remaining M2+A from the next coherent work below.

Repository: `dwijayuda/pskernel`. Development: `psc0/pscv0-v7-native-lean-v1`. Research: `psc0/pscv0-v7-f3-conversions-research`. Draft PR109 base: `psc0/pscv0-v7-m1-parser-ownership-v1`; preserve it and do not merge. Read fresh heads and exact-commit CI before any write; expected-HEAD non-force updates must preserve concurrent history.

Use GitHub integration and cloud Linux CI exclusively. No local checkout/files/builds/tests or Desktop Commander. Native .lean implementation; official Lean kernel. No pskernel-core, bootstrap/self-hosting, compiler-source .ps migration or C5. Application .ps fixtures are allowed. Wasm uses GC internally, with linear memory only at explicit Canonical ABI boundaries.

Pin Lean 4.35.0, commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. Before each substantial feature, study the official corresponding source and tests, compare PSC0, choose the simplest correct design and document references/Apache-2.0 attribution. Only approved assumptions: propext and Quot.sound. No sorry, Classical.choice import, unchecked admission, new trust assumptions, relaxed criteria or increased budgets.

## F3 scientific literals and conversions — qualified milestone, 16 October 2026

**F3 scientific syntax and fixed-width numeric conversions are complete and qualified across the existing executable backends. M2 + Phase A remains open. Stop before F4 at this user-requested milestone.** The active order remains M2+A -> M3+B -> M4+C/D -> M5/E.

Research commit `f7cc68d9bd447d0202cb1da9275df567dbc77600` passed all 31 steps in [native38782250236](https://github.com/dwijayuda/pskernel/actions/runs/38782250236), plus independent [F1 replay38782250277](https://github.com/dwijayuda/pskernel/actions/runs/38782250277), [F2 replay38782250393](https://github.com/dwijayuda/pskernel/actions/runs/38782250393) and [F3 replay38782250286](https://github.com/dwijayuda/pskernel/actions/runs/38782250286). **933 shared runtime observations** pass in TypeScript, direct JavaScript and Rust. GC Wasm core/component execution uses the same observation table and passes under V8/Wasmtime; repeated native component calls and post-return pass. Native source/kernel/typed-IR checks, checked multi-module compilation, strict asset replay and the unchanged performance checks also pass.

Development commit `bc69717469bbe72249d0d18022b1a51fa5cdd817` passed all **31** native job steps in [native38785140484](https://github.com/dwijayuda/pskernel/actions/runs/38785140484), with independent [F1 replay38785140393](https://github.com/dwijayuda/pskernel/actions/runs/38785140393), [F2 replay38785140385](https://github.com/dwijayuda/pskernel/actions/runs/38785140385) and [F3 replay38785140508](https://github.com/dwijayuda/pskernel/actions/runs/38785140508) also green at that exact commit. The completed log confirms all 933 JS/TS/Rust observations, GC Wasm/core/component validation and execution, repeated native Wasmtime calls, source/kernel/IR checks, module integration and unchanged performance checks. This final receipt changes documentation only; compiler source and workflows remain identical to the qualified development commit, itself source-identical to qualified research. History was integrated by fast-forward from `4ce3b0dfd3ab536b5620d601c84f882496776903`, without rewriting or dropping commits. **This request is finished; stop before F4.**

### Completed mechanism and invariants

- Scientific tokens/AST preserve exact spelling and spans, including Lean and ProofScript printing. Pinned Lean lexical behavior covers decimal/exponent/underscore forms and leaves range punctuation unambiguous. Exact mantissa/sign/exponent decoding never parses through host floating point.
- OfNat and OfScientific share universe-aware expected-type constraints and scoped synthetic goals. Custom scientific instances, higher universes and ordinary-before-default scheduling are qualified; raw parameters preserve the observable distinction between `1.` and `1e0`.
- The selected checked F3 asset has 42 roots /134 declarations /one recursor /3,286 shared nodes. Explicit registration adds native OfScientific Float/Float32 and two checked OfNat dictionaries. Float's scientific default priority is 501; Float32 remains ordinary-only. Proof-closure dependencies are not silently registered as instances.
- A single exact-rational nearest-even algorithm is authored in `Ps/Erasure/FloatRuntime.lean` as typed IR, with Lean-compatible fast paths and overflow/underflow guards. Direct calls, partial applications, generics and Model conversions share it. Floating operand/result roles are explicit; integer Model constructor operands are not wrongly unwrapped.
- Private IR support names are reserved before local erasure, retained by record updates, emitted only when reachable and excluded from public exports. No proof dependency is compiled merely because it belongs to the logical asset.
- Shared typed intrinsics cover fixed-word/float conversion and Nat.log2. JavaScript/TypeScript round 64-bit integers directly to binary32 to avoid double rounding; Rust uses safe native numeric casts. Wasm uses native conversion and saturating opcodes through one byte-sequence instruction descriptor shared by binary/WAT/validation, with existing GC Nat/Int support and no new linear memory. Float-to-word conversion truncates toward zero, saturates and maps NaN to zero.
- The frozen pre-F3 environment remains the replay boundary. Compiler source stays native .lean, profile `pscv0-v7-native-bounded/63`; closure is 258 portable /272 native modules. No pskernel-core, bootstrap/self-hosting, C5 or compiler-source .ps migration ran. Only the approved `propext` and `Quot.sound` assumptions are used.

### Selected environment and provenance

Selected Standard: **3,315 declarations /32 classes /260 ordinary instances /9 defaults**. Snapshot v3 /surface v2: FNV `12963509668132181128`; declaration SHA-256 `bc08da1b91289aecc447678b691874558330e4816dbed426e6fbfb29ed8c7790`; source-surface SHA-256 `ade666bf0e47f4f4c93079ad3876ccf298e0f95bab3732ee24d33c66778f621a`. Both strict entry points independently measured these before selection in native38781449363.

Selected F3 asset: **620,103 UTF-8 bytes**, SHA-256 `a7484caea16ce69829f79bf59e3c0142fbada37f1690c8ead801e589b5f25d27`. The old 617,019-byte candidate predates the homogeneous-operator slice. F3 replay38781864830 established that only its boundary metadata needed refreshing: 57 already-qualified dictionary names added, zero removed, all declarations/nodes/proof text identical. The boundary now contains exactly 3,179 pre-F3 names; strict byte-exact replay is green. No acceptance condition was weakened.

Validation adds one coherent F3 fixture (52 observations), nine custom scientific observations and compact pinned Lean lexical/decoder oracles: **872 -> 933**. Cases cover exact decimals, nearest-even/subnormal/overflow boundaries, huge exponent guards, upstream double-rounding vectors, large Nat/Int, all fixed unsigned/signed widths for both floats, NaN/infinity, defaults, partial/generic calls and Model inputs. Scoped conformance plus kernel-checked logical replay is not a general backend-preservation theorem. Development performance recorded 109 ms median indexed-128 elaboration and 7,991 ms prelude initialization; research recorded 69 ms and 5,129 ms respectively. Cross-run variation is not a performance guarantee and existing generated collection costs remain visible. No resource ceiling increased.

### Primary references and remaining boundary

Pinned Lean **4.35.0**, `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`: `src/Lean/Parser/Basic.lean` (decimalNumberFn/takeDigitsFn), `src/Init/Meta/Defs.lean` (decodeScientificLitVal?), `src/Lean/Elab/BuiltinTerm.lean`, `src/Init/Data/OfScientific{,/Basic}.lean`, Float/Float32 and Model/Unpacked/{Round,Operations/OfScientific,Operations/OfNat,Operations/ToNat,Operations/Div}, `src/Init/Data/Nat/Log2.lean`, `src/Init/Data/SInt/Float{,32}.lean`, `src/include/lean/lean.h`, `src/runtime/object.cpp`; tests/elab/float_conversions.lean, tests/elab_fail/scientific.lean and tests/pkg/ofScientific (including double-rounding data). Apache-2.0 attribution is recorded beside adaptations. Official Wasm numeric-instruction semantics and Rust numeric-cast semantics were also reviewed.

Next, on a subsequent continuation request, study and complete F4 display and its checked ToString/Repr/Format boundary, then the remaining selected scalar/collection/registry and M2+A exits. Opaque Float.toFloat32/Float32.toFloat contracts and USize/ISize target-word profiles remain explicitly separate and unqualified by this F3 slice. Existing readable JS/TS/Rust/WAT/WIT paths are extended; spelling retention in .lean/.ps printers is not C5 source-reconstruction completion. Keep draft PR109, its existing base, GitHub/cloud-only execution and expected-HEAD non-force updates.


## Architecture map for the next request

Read current AI_WORK_STATE.md, docs/PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md, docs/PSCV0_M2_A_SCALAR_COMPLETION_2026-10-14.md and the canonical PSCV0_LANGUAGE_REFERENCE.md before changing code. Dated historical entries are evidence, not instructions to redo completed work. M1 is complete. Follow M2+A -> M3+B -> M4+C/D -> M5/E; do not create another milestone track.

Completed foundations include native scopes/applications/expected types/default and grouped binders, dependent matching, shared scoped synthetic constraints and generalized instance answers, selected universe-aware deriving, polymorphic Array/List, checked bytes and scalar foundations, ordinary-before-default scheduling and class-projection transparency. F1 bit/model transport, F2 arithmetic/comparison/classification and F3 scientific/fixed numeric conversions now execute through the existing generic/partial/closure/module/ABI paths.

Preserve syntax -> resolution -> elaboration -> prepared Core -> official checking -> typed erasure -> validated IR -> readable backend boundaries. Reuse the same prepared graph across checking and emission. No host frontend fallback or fabricated proof authority.

F3 ownership:
- packages/syntax: exact tokens/AST/decoder and source spelling in both printers.
- packages/elab/Literal, Basic, Term: shared numeric constraint mechanism, not eager floating parsing.
- packages/environment/StandardScientific, StandardFloatConversionsData, SelfHostProd and StandardSnapshot: checked selected roster, explicit instance/default metadata and frozen asset boundary.
- host/StandardExport, PrimitiveAudit and StandardManifest: native-reference authoring, audited primitive signatures, strict provenance and independent hashes.
- packages/erasure/FloatRuntime: shared typed-IR exact rational support; Float: typed operation descriptors and Model boundary; Basic/Expr/Definition: stable private support names and reachability.
- compiler-ir Model/CheckTypes: exact typed conversion signatures.
- backend-ecma: shared readable JS/TS conversion lowering; backend-rust: safe casts; backend-wasm: GC integer support and common prefixed instruction bytes for binary/WAT/stack validation.
- test/Pscv0NativeTests and scripts/pscv0-native-observations: one shared observation corpus and independent pinned Lean oracles.

## Next coherent work, only after continuation

Study F4 display from pinned Lean's Float/Float32, ToString/Repr/Format and runtime formatting implementations and their tests before designing it. Inspect the existing pure Format and deriving handlers to extend the actual missing boundary. Keep logical admission, executable behavior, readable source output and target-specific formatting decisions separate and explicit. Opaque cross-width float contracts and USize/ISize target profiles require their own already-planned review; do not silently treat them as F3-qualified.

Then audit the authoritative Phase A exit gate against current evidence: selected deriving, proof-bearing indexed access, scalar/collection conversions and comprehensive module/notation/instance/tactic/effect/axiom manifest. Selected strict declaration/surface hashes do not prove the full manifest complete. Do not claim M2+A completion from this scalar slice.

Implement complete coherent mechanisms before broad validation; use compact differential checks for critical invariants and the existing full backend/integration suite at meaningful milestones. Keep scoped runtime evidence distinct from formal preservation. Preserve source origins for later C5 while continuing native .lean now.

Independent authoring declarations use Lean's pooled-task kernel-counter reset. Source requests retain cumulative 2,000,000-heartbeat /20,000-depth limits; allocation telemetry is separate. No budget increases.

Update both AI_WORK_STATE.md and AI_CONTINUE_PROMPT.md, roadmap, scalar design and PR109 at every milestone. Read exact completed CI before reporting green. Stop at the requested slice boundary.
