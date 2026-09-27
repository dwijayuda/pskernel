# PSC2 delivery roadmap

Status: ordered implementation plan; phase names are goals, not completion claims.
Execute the [first repair plan](plans/01_FOUNDATION_REPAIR.md) before broad feature
work. Later phases receive bounded implementation designs against actual code.

## Critical path

| Phase | Work | Exit |
| --- | --- | --- |
| M0 Reproducible workspace | Package/kernel registration, module maps, valid Lake roots, profile census, scoped CI | P2-WORKSPACE and P2-LEAN |
| M1 Honest admission | Versioned provider/adapter, genuine check/build admission, checked handoff, independent differential fixture | P2-ADMISSION |
| M2 Compiler closure | First failing real-source construct; complete stdlib/Meta/elab/erasure/runtime path; compositional fixture | P2-SOURCE and P2-COMPOSE |
| M3 JS generations | Canonical `.ps`, independent recheck, TS/tsc/G1, G2/G3 comparison, explicit source promotion | P2-DUAL, GENERATE, FIXED |
| M4 Kernel closure | Embedded-kernel feature census, conversion, generated execution and independent replay, kernel generations | P2-KERNEL and P2-KFIXED |
| M5 PSC2 language slices | Programming/prover/contracts profile delivered incrementally | P2-LANGUAGE and P2-CONTRACTS for declared scope |
| M6 Native/platform maturity | Rust host fixed point; Wasm conformance/optional host; interfaces/plugins/Task; release qualification | Applicable TARGETS/HOST/RELEASE gates |

M4's native-provider integration and source census can proceed alongside M1/M2;
M4's generated-kernel claim depends on M3 tooling. M5 designs and isolated
features may proceed earlier under the documented bootstrap subset, but must not
destabilize M0-M3. M6 backend fixes may land whenever they preserve shared
contracts and pass their affected gates. The milestones separate release claims,
not a prohibition on useful authorized parallel branch work.

If M0's Lean build exposes a semantic defect, M0 remains open while a bounded
prerequisite repair is assigned to the owning M1/M2 component. Phase order must
not prevent fixing the defect needed to close an earlier phase.

## M2 work selection

Use the actual compiler dependency closure as the workload. Stop at its first
real failing phase: parse, elaborate, admit, erase, emit, execute or compare.
Add the smallest faithful fix and regression, then resume. Do not replace this
with an ever-growing synthetic feature checklist, or rewrite source to avoid a
required semantic operation without documenting the profile decision.

The fixture composes source positions/text, collections, JSON, imports/names,
structures/inductives, recursion, compiler effects/rollback, higher-order
functions, required inference/instances, diagnostics and real provider calls.
Preserve useful existing features without making every Lean convenience a
bootstrap requirement.

## PSC2 feature delivery matrix

Every row is PLANNED for the richer PSC2 profile unless scoped executable
evidence is added. Inherited partial support must be measured before reuse.

| Order | Family and owner | Prerequisites | Completion example + required negative case |
| --- | --- | --- | --- |
| F1 | Namespaces/open/sections, visibility; syntax/environment/elab | Deterministic logical resolution | Cross-module scoped declarations; ambiguous/private lookup rejected |
| F2 | Static methods, updates, named/default arguments; syntax/elab | Structure/type-directed resolution, transactions | Receiver and dependent defaults elaborate to ordinary terms; ambiguous method/duplicate named argument rejected |
| F3 | Rich/equation/multi-scrutinee patterns; syntax/elab | ADT elimination, dependent motives | Nested patterns preserve evaluation order; invalid motive/refutable bind rejected |
| F4 | Local/mutual/well-founded recursion; elab/proof layer | Declaration groups, existing kernel admission, termination framework | Total measure-based function; nonterminating total declaration rejected |
| F5 | `let mut`, loops, control flow, typed recovery; syntax/elab/stdlib | Explicit effects, iteration and recursion | Loop with break/continue lowers consistently; out-of-scope control flow rejected |
| F6 | Universe/scoped instances/coercions and opacity; meta/environment/elab | Transactional search, provider profile | Imported universe-polymorphic API; cycle/ambiguity/illegal unfolding rejected |
| F7 | Structured proofs, rewriting, cases/induction; meta/elab | Goal/context operations, proof reconstruction | `have`/`calc` and dependent cases admitted; malformed generated proof rejected |
| F8 | Mature simp/registries/notation/deriving; prover/extensions | F1/F6/F7 and controlled registry APIs | Registered simplification/derive generates checked declarations; unknown attribute/unsafe expansion rejected |
| F9 | Pure contracts and caller obligations; verification layer | M1, specified program semantics, proof construction | Pre/post theorem bound to real definition; false postcondition or missing precondition fails |
| F10 | Effectful contracts/invariants/decreasing; verification/stdlib | F4/F5/F9 and sound effect specification framework | State loop proves initialization/preservation/exit; bad invariant/error outcome fails |
| F11 | Task/Resource, InterfaceIR, controlled plugins and service API | Frozen observables and versioned contracts | Cross-target modeled task/FFI; missing capability/cancellation case rejected |

Small F9 pure-contract work can precede F8; do not require a mature automation
engine when explicit checked proofs suffice. Rich automation (ring/omega/search/
SMT/AI) is library/plugin work after the required Meta/proof boundary exists.
Do not expand kernel authority for automation convenience.

## Release scopes

Publish named profiles with exact required feature sets: bootstrap compiler,
PSC2 programming, PSC2 prover, PSC2 verification, and optional platform/host
profiles. These labels are planning categories; concrete versioned manifests
must be defined before release. A partial release must say which profile/rows
remain unavailable and reject them explicitly.

PSC2 Standard cannot be declared complete by closing only M3. Conversely, M3
must not wait for every platform feature. Preserve the intended PSC2 reference
requirements; an explicit narrower profile is not a silent redefinition of
Standard.

## Risks and stop rules

| Risk | Response |
| --- | --- |
| Independent branch snapshots drift | Compare exact contracts/source, integrate one bounded change, rerun local gates |
| Kernel source exceeds bootstrap subset | Inventory actual features; adapt narrowly or declare a Lean-hosted extension profile; never pretend guard coverage |
| Codec success mislabeled verification | Block checked claims and wire real admission before verified erasure |
| Self-host source closure repeatedly moves | Freeze input manifest for each campaign; distinguish source changes from compiler changes |
| Runtime mismatch across backends | Minimize to shared-IR fixture with explicit expected values; fix the owning layer |
| Performance work consumes the schedule | Measure the actual compiler closure first; isolate expensive corpus research |
| Draft language semantics remain ambiguous | Close the applicable decision before implementation; preserve fail-closed neighboring cases |

No calendar estimate or percentage is authoritative. Report phase exits,
executed evidence and the next concrete blocker.
