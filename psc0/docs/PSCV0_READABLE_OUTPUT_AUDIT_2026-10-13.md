# Readable output: implementation audit and integrated roadmap

**Latest M2+A qualification:** [Linux 38418209663](https://github.com/dwijayuda/pskernel/actions/runs/38418209663)
at `d7e28a3870cdc399eca3c63c6d305b10109d2eca`. Checked equality/defaults use the existing
shared IR and JS/TS/Rust/WAT/WIT paths. 276 observations, 629 declaration mappings,
37 generated-parent origins and the declaration consumer pass. No new emitter
or C5 implementation; maps remain at declaration precision. Source optional
annotations retain defaults; command/member origins retain derived ownership.
[Design/evidence and remaining dependencies](PSCV0_M2_A_EQUALITY_DEFAULTS_2026-10-13.md).

**Prior M2+A qualification:** [Linux 38411211335](https://github.com/dwijayuda/pskernel/actions/runs/38411211335)
at `c6468b17ef8f0a97c9e0df76c1ffe49f35c68279` preserves this output architecture.
263 shared runtime observations, 591 declaration mappings and 26 generated-parent
origins passed; maps remain at declaration precision. Generalized Nat-indexed
local dictionaries now run across JS/TS/Rust/GC-Wasm. Type-polymorphic runtime
dictionary values are kernel-qualified and explicitly refused before IR emission;
their higher-rank representation remains future shared IR work.
[Current design/evidence](PSCV0_M2_GENERALIZED_CONSTRAINTS_2026-10-13.md).
No C5 emitter or source-authority migration was added.

**Subsequent M2+A qualification:** [Linux 38403318952](https://github.com/dwijayuda/pskernel/actions/runs/38403318952)
at `f1ce3840c1943c9f78be20a5428fd4adfa9053af` preserves the backends and plan audited here.
The enlarged source fixture has 260 shared observations, 572 declaration
mappings and 26 generated-parent origins. The added origins include ordinary
derived instances; mapping precision is still declaration-level.
[Generic deriving and its shared M2 mechanisms](PSCV0_M2_A_DERIVING_2026-10-13.md)
fit **M2+A → M3+B → M4+C/D**, then M5/E. No C5 emitter was added.
The historical audit evidence below remains tied to its stated revisions.

Audit date: 13 October 2026. Source inspected:
`b2e47ab9f5a45f6f3bdbd10db7ccb22a9bbe2a68` on
`psc0/pscv0-v7-native-lean-v1`; qualified executable:
`c00e146bd5c97788a4a6a39221849973aeafda84`,
[Linux 38388627512](https://github.com/dwijayuda/pskernel/actions/runs/38388627512).
The intervening commit only records M1 completion. This audit changes documentation,
not compiler behavior or qualification identity.

**Decision:** keep the existing emitters. Readable JS/TS/Rust/WAT/WIT already
exist for the selected native language. Lean/ProofScript have useful bounded
source-translation assets and historical qualification, but complete native C5
source reconstruction is missing. Integrate the remaining work into M2–M5
and A–E. C0–C4b remain historical delivery labels, not new work to repeat.

## Current implementation, by artifact

| Artifact | Implemented and qualified | Partial or missing |
| --- | --- | --- |
| JavaScript `.js` | `Ps.BackendEcma` lowers checked IR to a structured Program; direct ESM printing has no tsc/regex transpilation step. Shared Doc/names, functions, loops, lexical blocks, once-only argument evaluation and generator dispatcher. `.js/.d.ts/.js.map` bundle and provenance manifest. | Owning-declaration maps, not expression stepping. No anchored comment reconstruction. Stable collision naming under arbitrary edits remains open. Runtime support is currently inline; splitting it is an optional measured packaging decision. Generator/dictionary overhead remains substantial. |
| TypeScript `.ts` | Same ECMAScript Program and runtime semantics as JS, with dialect-specific annotations/type declarations. Native `BackendTs.Readable` is a thin adapter. Strict TS and runtime matrix pass. | No TS source-map artifact currently advertised. Formatting/parentheses/helper readability can improve through the shared structured printer. Do not revive the old string lowering path. |
| Rust `.rs` | Doc-based readable declarations/expressions/matches; source names and ranges; separate `pscv0_runtime.rs`; explicit Rc/closure/layout/borrow/clone decisions, persistent arrays and tail loops. Locked dependencies and source/runtime compilation pass. | Collision stability, origin precision, some redundant syntax and runtime verbosity remain. Final-owner destruction of deep recursive values is not generally stack safe. External effects and higher-rank runtime polymorphism remain capability limits. |
| WAT `.wat/.core.wat` | Named functions/locals/types/fields, structured control, visible GC and ABI helpers; embedded core modules are readable text. Binary and text serialize the same checked target plan. Independently reassembled binaries agree after only allowed name metadata removal. | Source occurrence/instruction attribution is incomplete. Function-level generated ranges exist; complete target symbol/origin coverage must be audited before finer-map claims. No qualified binary debugger source maps. |
| WIT `.wit` | Readable public worlds/interfaces/types from the same Canonical ABI plan used by component type encoding and adapters. Independent WIT parsing and extracted complete-interface comparison pass. Concrete generic records/variants and Nat/Int limb adapters are supported in the selected profile. | Not arbitrary dependent/generic/recursive source types. Resources, callbacks, imports/effects, async and threads are unqualified. The current String printer does not carry per-definition Doc ranges; WIT debugger maps are not promised. |
| ProofScript `.ps` | Existing owned syntax printers, v7 application/type printing, original-source retention/replay and bounded declaration/Except-do translation. Historical selected-module round trips and compiler-product comparisons exist. | No full current-program C5 presentation layer or native emission target. Current compiler syntax exceeds the bounded bridge. Comments cannot be canonically repositioned; native grouped binders have explicit printer refusals. No complete checked reconstruction of dependent definitions, scopes, effects, proofs/specs or generated helpers. |
| Lean `.lean` | Existing owned Lean/type/application printers and bounded readable/lowered projections, with historical pinned-RC4 checks and specific correspondence theorems. | No complete current-program C5 target or general Lean decompiler. Some forms, including empty invocation requiring typed completion, explicitly refuse. Native Standard/model correspondence, whole-program source coverage and reconstruction checks remain open. |

All runtime targets passed the same **250 observations** at the executable above.
The latest directJS audit reports **519 declaration mappings and 14 generated-parent
origins**, with independent UTF-16/Unicode decoding and an isolated strict
declaration consumer. Three-module JS/TS/Rust and four-module Wasm project checks
also passed. Four panic cases remain qualified. These are bounded functional
results, not complete v7, performance parity or semantic-preservation proofs.

C4/C4b use Wasm GC for language values. Linear memory exists only in explicit
Canonical ABI adapters. Keep the pure synchronous memory32 profile and its
post-return/lifetime contract until Phase C introduces a qualified extension.

## Source inspection and architectural ownership

- [Codegen.Doc](../packages/codegen/src/Ps/Codegen/Doc.lean): bounded layout and
  generated UTF-8 ranges. [Names](../packages/codegen/src/Ps/Codegen/Names.lean):
  semantic/output mappings, reserved names and deterministic allocation for a fixed
  traversal. It is currently an IR renaming view, not a pre-erasure source renamer.
- [Provenance](../packages/codegen/src/Ps/Codegen/Provenance.lean) and
  [SourceMap](../packages/codegen/src/Ps/Codegen/SourceMap.lean): declaration
  identity, reserved occurrence paths, original text/files and final-layout
  UTF-16 mappings. Occurrence storage alone does not establish fine-grained maps.
- [ECMAScript Module](../packages/backend-ecma/src/Ps/BackendEcma/Module.lean):
  one plan feeds JS, TS and declarations. [Rust Module](../packages/backend-rust/src/Ps/BackendRust/Module.lean):
  readable output retains ownership/layout decisions.
- [Wasm Module](../packages/backend-wasm/src/Ps/BackendWasm/Module.lean),
  [Wat](../packages/backend-wasm/src/Ps/BackendWasm/Wat.lean),
  [AbiSchema](../packages/backend-wasm/src/Ps/BackendWasm/AbiSchema.lean) and
  [AbiComponent](../packages/backend-wasm/src/Ps/BackendWasm/AbiComponent.lean):
  one checked module and one ABI plan feed text, binary and interface.
- [Syntax.Pscv0.Module](../packages/syntax/src/Ps/Syntax/Pscv0/Module.lean):
  native ordered-program parsing and historical declaration translation are
  intentionally separate. `psPscv0TranslateReadable` and
  `psPscv0LowerToLean` exist; `PSCV0-TRIVIA-PRINT-PENDING` still rejects
  canonical printing of comments. Exact source replay is not reconstruction.
- [Artifact](../packages/codegen/src/Ps/Codegen/Artifact.lean) enumerates five
  runtime target kinds, with no Lean/ProofScript target.
  [Native CLI](../scripts/Pscv0Native.lean) likewise exposes runtime emission,
  not C5 source emission. The complete inspected PSC0 tree has no separate
  SourcePresentation/reconstruction implementation.

Historical `packages/backend-js` and bootstrap TS string emitters also exist.
The native host selects `PsEcma` for JS/TS; those old packages are not a second
active native backend to extend. Preserve their receipts/callers until an
explicit migration, but do not duplicate new lowering there.

## Historical branches and evidence actually checked

Branch tips were read live; they are observations at the audit date.

| Branch or checkpoint | Finding | Reuse decision |
| --- | --- | --- |
| `psc0/pscv0-readable-selfhost-v1`, `5cba02e6444780ca86578762bdb95e6faa70f7df` | Native branch diverges from merge base `8213f02e...`. Reverse comparison finds four branch-only commits whose net change is the 871-line `PSCV0_V7_RUST_SYSTEMS_LANGUAGE_EXTENSION.md`, explicitly a proposal. Its bounded bridge still declares `declaration-except-do/1`, full conformance false, and comment-print refusal. | No missing C5 implementation to merge. Keep existing source-printer assets and historical proofs; do not adopt the unrelated Rust-only language proposal as v7 requirements. |
| `psc0/pscv0-v7-sole-source-policy-v1`, `2394fc7e8ea327869b6cbe57ef41417de82e5408` | Ancestor of native HEAD. Its source-only CI was green; the later policy-integrated generated bridge is [38128357665](https://github.com/dwijayuda/pskernel/actions/runs/38128357665), `a640a2d22adeabd4ca7919839a8991667bcc3eae`, also green. | Preserve the sole-v7 source gate. Generic historical printers must not silently reintroduce partial/unsafe/old grammar. |
| `psc0/pscv0-linux-source-closure-v1`, `0e8996d2aff414986f04dbc68c2689aaf118fb48` | Ancestor of native HEAD. Its document still said pending, but live [38134451122](https://github.com/dwijayuda/pskernel/actions/runs/38134451122), job 114455343638, is green: 20-module closure with five v7-authored modules, identical canonical admissions/TS/JS and Linux runtime. No kernel or Windows tests in that run; no full fixed point. | Preserve this real bounded evidence and correct stale status. It does not select current compiler source authority or complete C5 for the much larger native language. |
| First-module source `8603f7dcf6af6295335c4e11912a10aac86c85a4` | Live [38120695522](https://github.com/dwijayuda/pskernel/actions/runs/38120695522) is green. Retained ledger records selected PS/readable-Lean round trips, generated Linux/Windows behavior and independent RC4 correspondence. Eight module API equations inherit original propext; the do fixture and two algebra lemmas have no axioms. | Reuse the method and exact historical proof evidence, not a blanket translator-correctness claim. |
| RC4 replay `4269b087b3bf2bc81baf9920ab3f23aae251cc54` | Live [38108354566](https://github.com/dwijayuda/pskernel/actions/runs/38108354566) is green for the actual generated do fixture. | Specific function correspondence, not arbitrary source reconstruction or JS preservation. |
| Native C4/C4b `26f68bd3038869d16ba4e3a97957de8f16a531ed` | Live [38197409359](https://github.com/dwijayuda/pskernel/actions/runs/38197409359) is green; current M1 run requalifies the larger selected closure. | Keep current GC/component emitters, do not rebuild C3–C4b. |
| `codex/direct-js-ir-v1` `fb709788...`, `backend/rust-native` `84741107...`, `backend/wasm3-gc-adts` `e23bbe08...` | Tips inspected. Their changed paths/evidence concern psc15selfhost, older self-host plans or PSC1 bootstrap workflows. | Historical reference only; not evidence that native PSCV0 C5 or new features are implemented. No wholesale branch merge. |

The historical authoring manifest remains `candidate-not-promoted`. Retained
`src-ps` files are evidence/assets, not today's authoritative compiler inputs.
No self-hosting, old compiler regeneration or kernel work was executed for this
audit. Historical receipts were inspected read-only.

## One architecture, two output paths

```text
owned syntax + source/trivia + resolved symbol/occurrence identity
    → shared elaboration → retained presentation + prepared Core
    → official Lean admission of that exact graph
        ├─ checked source presentation → readable PS / Lean       [C5]
        └─ typed erasure → complete runtime IR validation
              ├─ shared ECMAScript Program → JS / TS / d.ts / JS map
              ├─ Rust ownership/layout → Rust + runtime
              └─ checked Wasm + ABI plans → WAT / WIT / Wasm
```

Never recover dependent types, proofs or original scopes from erased runtime IR.
Retained presentation is metadata associated with checked declarations, not an
alternate source of proof authority. Original syntax may be reused only when
its resolved meaning still corresponds to the checked graph. Generated or
transformed fragments require controlled reification and explicit provenance.

Reuse existing leaf/type/application printers where their capability contract
matches. Extend them around one selected-program presentation model rather than
building an unrelated pretty-printer family. Keep the native v7 command gate;
older printer cases for historical source kinds do not authorize v7 output.

Share Doc, identities, target-safe naming primitives and artifact file validation.
The existing artifact/naming types currently depend on runtime IR. When C5 needs
them, factor only the neutral file/symbol portion; source emission must not be
forced through the runtime IR checker or a fake runtime target. No new universal
IR or plugin framework is required.

Lean projection needs a declared Standard/environment correspondence. Official
checking of the reconstructed portable environment is not automatic equivalence
with imported native Init. Explicitly modeled primitives and M1 Array/Decidable
representations require reviewed name/universe/model mappings, checked adapters
where necessary, or a clear refusal. No new assumptions, sorry, invented proof
witnesses or arbitrary Lean-source decompilation claims.

## Placement in the existing milestones

This integrates old C5 and backend-performance D into the existing tracks; it
does not add a new milestone sequence. Finish semantic support before claiming
complete reconstruction, but retain information when the semantics are built.

| Existing milestone | Feature phase | Output work alongside its semantic owner | Exit evidence |
| --- | --- | --- | --- |
| M0 | Foundation for all phases | Preserve the qualified proof/type/index/runtime erasure boundary. Source presentation branches before erasure; runtime targets keep strict IR admission. | Existing M0/M1 gates remain intact; no proof/type reconstruction from runtime values. |
| M1 | Selected A indexing | Completed. Preserve exact dictionary/bound evidence and the selected Standard/model ledger for later source projection. No duplicate indexing or backend work. | [M1 completion](PSCV0_M1_COMPLETION_2026-10-13.md), current 250-observation qualification. |
| M2 | Remaining A and elaboration prerequisites | Generator/consumer search, expected types, levels/defaults, scope rollback. While touching these owners, retain ordered binder groups, resolved names, implicit/default argument decisions and occurrence-to-checked-declaration relations. Extend selected deriving/APIs using the same mechanisms. | Scoped answer replay and priority/cycle/budget oracle cases; each new A feature joins existing target observations. Retention must not alter Core equality or add a second elaboration engine. |
| M3 | B | Retain dependency/motive information for patterns, impossible cases, mutual/nested families, generated recursors and totality evidence. Generalize presentation for these features alongside implementation. | Kernel admission, invalid dependent/termination rejection, runtime erasure; representative reconstruction correspondences when a feature's printer is ready. |
| M4 | C/D | Retain typed do/control/effect/spec/VC/proof provenance. Extend every runtime backend only for actually admitted IR/effect capabilities. Add WIT/resource/import policies only when selected language/interop needs them. | Same effect/failure/assumption ledger controls checked versus verified output; mandatory obligations cannot disappear in any format. |
| M5 | Consolidates A–D; completes E | Complete C5 publication after required A–D semantics exist: full selected-program PS/Lean printing, comment anchoring, hygiene/qualified names, source bundles and explicit correspondence. Finish stable naming, shared layout cleanup, finer origins/maps and measured general performance improvements. | Reparse PS, check both projections with the appropriate portable/pinned official pipeline, compare resolved declarations under explicit environment/name mapping, prove non-definitional changes where needed, and preserve assumption closure. Whole selected-language/output conformance matrix closes in E. |

**Scheduling correction:** the older blanket instruction to begin C5 only after
all A–E closes is superseded for planning by this dependency-aware integration.
Do its retention work within M2–M4; finish its output/round-trip acceptance under
M5/E once the required A–D language exists. Do not delay retention until the end,
and do not divert M2 into a full source-emitter rewrite.

E evidence is collected with every feature. Existing JS/TS/Rust/WAT/WIT qualify
each new shared IR capability through the existing matrix; there is no second
backend-completion track. M5 optimization can occur earlier when a measured
bottleneck warrants a coherent shared change. The M1 JS/native measurements
are evidence of remaining work, not a reason to bypass semantics.

Source reconstruction is distinct from migrating the compiler's own source.
Compiler-source Lean-to-PS conversion remains a later explicitly qualified
activity after sufficient language closure. No source-authority switch,
self-host fixed point, pskernel-core integration or new Rust-only source dialect
is introduced by this plan.

## Minimal qualification and remaining limits

- Reuse the single shared runtime observation corpus across targets; add compact
  cases only for new semantic or output boundaries.
- Keep strict TS and isolated d.ts consumer checking; independent source-map
  decoding including Unicode and synthetic/unmapped intervals.
- Keep WIT parse/extracted-interface equality, core/component validation and WAT
  reassembly against direct binary output, plus ABI lifetime/refusal cases.
- For C5, use selected positive/negative round trips, stable reprinting and
  semantic correspondence. Mere text equality or successful checking of two
  different programs does not prove equivalence. Do not add repeated self-host
  runs or enormous golden output files.
- Finer Wasm binary debugger maps and optional TS/declaration maps are separately
  advertised capabilities. They are not already implemented and do not silently
  become prerequisites for the existing requested artifact bundles.
- Readability includes useful names, structure, precedence and visible runtime
  boundaries. It does not justify deleting necessary clones, proof-call slots,
  dispatcher calls, GC/ABI operations or totality evidence.

## Next concrete work

M1 is qualified. M2 generator/consumer instance search is the next implementation
slice; the current solver still has checked closed-answer memoization and active
cycle rejection. No waiter engine has been committed by this audit. Its design
must preserve local-scope ownership, branch snapshots, priority before outParam
reconciliation, independent answer validation and deterministic budgets. Pair
the resulting mechanisms with remaining A deriving/API work, and retain source
decisions at their actual elaboration owner. Update the AI work state at each
qualified slice without claiming all M2/A or all v7 complete.
