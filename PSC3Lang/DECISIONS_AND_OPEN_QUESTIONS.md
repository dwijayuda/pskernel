# Decision ledger and open questions

**Draft 0.3 · v0.7 syntax repair.** Decisions describe this design, not implemented or proved capabilities. [ProofScript v0.7](SYNTAX_AND_GRAMMAR_V07.md) controls syntax/grammar; prior conflicting recommendations are withdrawn.

## 1. Decision ledger

| ID | Status | Decision | Alternative and consequence | Revisit condition |
|---|---|---|---|---|
| D01 | Required source baseline | `.ps` follows v0.7 L/D/E syntax and canonical lowering; `.lean` stays native. | Byte-identical alias policy incorrectly removes admitted decorations. | Only an explicit source-reference revision, not backend convenience. |
| D02 | Required reference identity | v0.7 canonical baseline is Lean 4.34.0; retain 4.34.1 as upgrade research only. | Silently selecting a later patch changes the claimed reference without evidence. | Explicit profile/reference update and regenerated conformance. |
| D03 | Required source baseline | `def` canonical; retain v0.7 `const` and `function` restrictions, `:=` and category semicolons. | Removing aliases or adding bare brace bodies contradicts reference §8. | Explicit future registry/reference revision. |
| D04 | Recommended library policy | Native `Except ε α`; user-defined reference-style `Result α ε` remains distinct. | Confusing parameter orders changes types; adding synonyms can fragment libraries. | A justified semantic API need, not an unreviewed rename. |
| D05 | Recommended | Library-first apps and explicit capabilities. | Every app feature becomes new syntax/kernel nodes. | Capability cannot be expressed coherently above the foundation. |
| D06 | Recommended | Nominal owned data and structural foreign interfaces at boundaries. | Native unrestricted structural subtyping changes logical obligations. | Separate specified extension with compelling evidence. |
| D07 | Recommended | Bounded `.d.ts` importer and adapter catalog. | All-npm claims hide dynamic/unsupported behavior. | Coverage grows with exact artifacts/tests. |
| D08 | Required semantics | Exact values and explicit foreign number/text conversion. | Global JS defaults violate canonical meaning. | Distinct explicit types/operations only. |
| D09 | Recommended | Native Lean Task unchanged; `Psc.Async` separately named. | Promise renaming hides execution differences. | Covered native profile meets a concrete need. |
| D10 | Experimental library | Cold Async descriptions, explicit start, scoped children and terminal arbitration. | Eager behavior changes reuse/start semantics. | Complete lifecycle/resource model and user evidence. |
| D11 | Recommended library | Preserve body and cleanup failures in typed outcomes. | Cleanup overwrites useful failure evidence. | Explicit alternate combinator with a documented contract. |
| D12 | Recommended | Plain library model/update/view, usable from v0.7 `.ps` and native `.lean`. | Markup becomes the only UI route. | Never remove the ordinary API. |
| D13 | Experimental extension | `.psx` UI is an opt-in dialect within v0.7's target-specific/non-Lean boundary. | Treating suffix as ordinary verified `.ps` changes source/trust meaning. | Explicit registry/version, expansion and usability gates. |
| D14 | Recommended | One initial renderer/React integration. | Simultaneous new DOM, hooks and server frameworks. | Real apps justify another adapter. |
| D15 | Recommended target | ESM artifacts, `.d.ts` and maps; native logical source imports remain unchanged. | ESM output is mistaken for new `.ps` grammar. | Other deployment modes are needed and tested. |
| D16 | Recommended | Preserve TS/Rust artifacts and current bootstrap. | Delete working routes solely for emitter ownership. | Approved retirement with actual consumer evidence. |
| D17 | Recommended | Favor direct JS after coverage/runtime/tooling/cutover gates. | Switch on toy examples or mandate tsc forever without need. | Conformance and delivery evidence. |
| D18 | Experimental target | Independently gated direct Wasm profile. | Four equal-priority bootstrap requirements block delivery. | ABI/runtime and performance/assurance evidence. |
| D19 | Required assurance | Final theorem refers to actual program and fixed specification. | Accept unrelated VC proofs as program verification. | No weakening of this requirement. |
| D20 | Required assurance | Protect specification dependencies and release policy from automatic repair. | Agent edits acceptance criteria until green. | Requirement changes receive explicit review. |
| D21 | Required reporting | Separate source, admission, contract, termination and preservation status. | Single verified badge overstates evidence. | Add precise fields rather than collapse them. |
| D22 | Recommended | Full-app gates alongside compiler/prover gates. | Bootstrap milestones substitute for application use. | Per-release scope can vary; app ambition remains. |
| D23 | Deferred grammar | General effect or pervasive ownership syntax. | New mechanisms arrive before existing semantics is clear. | Explicit proposal plus models/tasks and grammar revision. |
| D24 | Deferred coverage | Arbitrary macro/elaborator and all-mathlib source compatibility. | Kernel support is confused with full frontend support. | Exact closure and oracle/replay evidence. |
| D25 | Rejected claim | Source proofs or owned emitters imply final-executable correctness automatically. | Printers, runtimes and downstream assumptions disappear. | No ownership exception. |
| D26 | Required parser discipline | Preserve D-CALL adjacency, native patterns, `fun`, `where`/`with` and inherited scopes. | Whitespace normalization or TS-like replacement changes reference grammar. | Future reference revision only, never a formatter decision. |

## 2. Open implementation/profile obligations

| ID | Question | Review role | Decisive evidence |
|---|---|---|---|
| O01 | Which v0.7 feature IDs and inherited environments are implemented? | Frontend/library | Exact registry/profile manifests and positive/negative/lowering corpus. |
| O02 | Which scalar/string/collection operations are executable? | Runtime/semantics | Pinned operation matrix and representation evidence. |
| O03 | Which inherited module/visibility/initialization modes are covered? | Frontend/tooling | Logical graph, scope, private-name and export tests. |
| O04 | Complete Async cancellation/cleanup/fairness contract? | Effects/runtime | Trace model, scheduling tests and explicit restrictions. |
| O05 | Schema presence/unknown-field/version rules? | Library/interop | Codec laws, migrations and consumers. |
| O06 | Exact optional UI dialect and v0.7 interpolation/lowering contract? | UI/frontend | Registered proposal, paired expansions, maps, formatter and user tasks. |
| O07 | Supported React/runtime versions and lifetimes? | Adapter/UI | Locked dependencies and browser tests. |
| O08 | First direct-Wasm memory/GC/ABI profile? | Backend/runtime | Actual artifacts, marshalling and measurements. |
| O09 | First source-to-Core and target-preservation theorem scope? | Assurance | Checked statements and exact artifact replay. |
| O10 | Kernel readiness under the declared canonical pin? | Kernel | Positive/adversarial replay and explicit proof scope. |
| O11 | Compatibility across source, APIs, proofs and bundles? | Governance | Version policy exercised on actual changes. |
| O12 | Does v0.7 plus libraries/tooling meet TS adoption needs? | Research/usability | Counterbalanced tasks against native Lean and TS baselines. |

Roles are proposed, not assigned people. Open coverage can limit a release without blocking unrelated work. These questions do not reopen settled v0.7 syntax by implication. Native grammar, future extension grammar and library semantic design are different questions.

## 3. Anti-drift rules

The external repository v0.7 reference and registry govern source syntax; `SYNTAX_AND_GRAMMAR_V07.md` records the local contract. `LANGUAGE_REFERENCE.md` describes PSC3 requirements within it. Domain documents cannot override them.

An accepted design update changes affected examples, manifest, ledger and tests together. New grammar needs explicit source-reference/registry evolution and evidence, not a prose example. No document entry changes compiler code, package names, runtime pins or old source semantics automatically.

The correction of draft 0.2's byte-alias policy is intentional and recorded, not a claim that that policy ever had a conforming implementation.
