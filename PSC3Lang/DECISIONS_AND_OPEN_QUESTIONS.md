# Decision ledger and open questions

**Draft 0.2.** Status applies to this design recommendation, not implementation completion. Recommended decisions may still require experiments before freeze.

## 1. Decision ledger

| ID | Status | Decision | Alternative and consequence | Revisit condition |
|---|---|---|---|---|
| D01 | Recommended | Ordinary `.ps` and `.lean` share native Lean contents and meaning. | Separate TS-like syntax costs another frontend/source-correspondence project. | Controlled user study shows unacceptable adoption cost despite library/tool improvements. |
| D02 | Recommended | Use v4.34.1 as the proposed new reference, leave old pins untouched. | Staying on 4.34.0 avoids immediate migration but ignores patch guidance. | A later reviewed pin offers a justified compatibility/runtime benefit. |
| D03 | Recommended | One canonical teaching declaration, native `def`. | Retain many aliases for familiarity; increases explanations and migration ambiguity. | A demonstrated user need outweighs cognitive/maintenance cost in a named extension. |
| D04 | Recommended | Error-first `Except ε α`; no second standard Result hierarchy. | Duplicate Result creates needless parameter-order and library conversions. | A distinctly different semantic purpose, not spelling preference. |
| D05 | Recommended | Library-first application platform and explicit capabilities. | Implement every app feature as syntax/kernel nodes; enlarges coupling. | A capability genuinely cannot be expressed in the chosen foundation. |
| D06 | Recommended | Nominal owned data; structural foreign interfaces only at boundaries. | Native unrestricted structural subtyping changes foundational/typechecking obligations. | A separate formally specified extension has compelling measured value. |
| D07 | Recommended | Bounded `.d.ts` importer and reviewed adapter catalog. | Claim all npm support; would conceal unsupported dynamic semantics. | Coverage expands with exact artifacts and conformance evidence. |
| D08 | Recommended | Exact values and explicit foreign numeric/text conversion. | Adopt JS defaults globally; violates source semantics and proof meaning. | Never by convenience; only explicit distinct types/operations. |
| D09 | Recommended | Native Lean Task remains native; `Psc.Async` is separately named. | Rename Promise to Task and assume equivalence; obscures execution differences. | Native compatibility implementation becomes sufficiently covered for a desired profile. |
| D10 | Experimental | Cold Async descriptions, explicit start, scoped children and first committed terminal outcome. | Eager descriptions imitate Promise more closely but complicate pure construction/reuse. | Full lifecycle/resource model or user evidence shows another library contract is superior. |
| D11 | Recommended | Typed resource outcomes preserve body and release failures. | Cleanup error overwrites body error; loses diagnostic information. | An explicit alternative combinator has a justified contract. |
| D12 | Recommended | Plain-library model/update/view baseline. | Make a markup parser the only route to UI; violates full plain-source goal. | Never remove the ordinary API; optional ergonomics may expand. |
| D13 | Experimental | `.psx` UI quotation as a bounded imported extension. | Arbitrary TSX or an unsafe escape file; creates semantic ambiguity. | Expansion parity and usability evidence are required before promotion. |
| D14 | Recommended | One initial renderer/React integration, not several custom frameworks. | Simultaneously build a DOM engine, hooks clone and server framework. | Real applications justify a second backend with equivalent interface behavior. |
| D15 | Recommended | ESM-first distribution with `.d.ts` and source maps. | Promise all module systems on day one. | CJS/other deployment coverage is explicitly tested and needed. |
| D16 | Recommended | Preserve TS/Rust artifacts and existing bootstrap. | Delete functioning routes because direct generation seems more independent. | A route has no consumers and explicit retirement/migration is approved. |
| D17 | Recommended | Favor direct JS after corpus/runtime/tooling/cutover gates. | Keep tsc mandatory forever, or switch on toy examples. | Measured delivery needs and conformance results determine promotion. |
| D18 | Experimental | Direct Wasm as a separately gated profile. | Four equal-priority mandatory backends block the core app release. | Runtime/ABI and performance/assurance evidence justify broader scope. |
| D19 | Recommended | Contracts are final theorems about fixed program/specification identities. | Accept proofs of arbitrary generated VCs without the connecting theorem. | This requirement does not weaken. |
| D20 | Recommended | Protect specification dependencies and release policy from automatic repair. | Let the agent modify acceptance criteria until green. | Requirement changes remain possible through explicit review. |
| D21 | Recommended | Separate admission, contract, termination and target preservation status. | One global verified badge overstates evidence. | Add new precise fields, not a misleading collapse. |
| D22 | Recommended | Full-app release gates alongside compiler/prover gates. | Endless bootstrap success without an application workflow. | Scope may be smaller per release, but full-app ambition remains explicit. |
| D23 | Deferred | General algebraic effect syntax or pervasive ownership types. | Add both while the existing monadic/platform contract is unresolved. | A complete competing model and task evidence justify the extra mechanisms. |
| D24 | Deferred | Arbitrary macro/elaborator compatibility and all mathlib source. | Calling an independent kernel compatible implies entire Lean frontend support. | Exact library/elaboration closure and oracle/replay tests exist. |
| D25 | Rejected | Treat source proofs or own emitters as final-executable proof automatically. | Hides printers, runtime, downstream compilers and execution assumptions. | No ownership-based exception. |

## 2. Open freeze obligations

| ID | Question that needs an exact answer | Review role | Decisive evidence |
|---|---|---|---|
| O01 | What exact native modules/declarations/options are in the first source and elaboration closure? | Frontend/library maintainers | Generated manifests and official/owned positive/negative corpus. |
| O02 | Which scalar/string/collection primitives are executable, with which exact pinned rules? | Runtime and semantics maintainers | Operation matrix, boundary corpus and representation lemmas. |
| O03 | Which native module mode and visibility forms are supported? | Frontend/tooling | Module graph, export, initialization and private-name tests. |
| O04 | What is the complete Async cancellation/cleanup/fairness contract? | Effects/runtime | Executable trace model, adversarial scheduling tests, explicit unsupported cases. |
| O05 | How are API schemas versioned and presence/unknown fields handled? | Library/interop | Codec laws, migration tests and clean cross-language consumers. |
| O06 | What is the minimal `.psx` grammar and supported Lean macro implementation? | UI/frontend | Paired expansions, parser/formatter/source-map tests, user tasks. |
| O07 | Which React/runtime versions and lifecycle guarantees are supported? | Adapter/UI | Exact dependency pins and real browser tests. |
| O08 | What deployment profile starts direct Wasm: linear memory, GC or a bounded hybrid? | Backend/runtime | ABI specification, actual artifact tests and marshalling/performance measurements. |
| O09 | Which source-to-Core and compiler-preservation theorems can the first certified profile claim? | Assurance maintainers | Checked theorem statements and exact-artifact replay. |
| O10 | What evidence demonstrates independent kernel readiness at the new pin? | Kernel maintainers | Positive/adversarial replay and explicit implementation-proof scope. |
| O11 | What compatibility promise applies to source, APIs, proof scripts and proof bundles? | Language governance | Version policy exercised on a deliberately changed dependency/specification. |
| O12 | Does strict native syntax meet TS adoption needs? | Usability/research | Counterbalanced tasks, documented training, transparent measures. |

Roles are proposed review responsibilities, not claims that people have been assigned. An unresolved item may restrict a release profile instead of blocking every unrelated feature. But the release must not silently choose a backend-specific answer.

## 3. Anti-drift rules

Only one file is the proposed language authority: LANGUAGE_REFERENCE.md. Domain documents refine named areas. A changed decision updates that reference, this ledger, affected examples and tests in one reviewable change.

No new design entry changes existing compiler code, package names or old semantics by itself. Status transitions need evidence. Do not turn an experimental entry into a recommended/frozen one just because implementation effort has already been spent.
