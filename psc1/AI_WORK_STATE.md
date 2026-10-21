# PSC1 — complete compiler sources and whole closures qualified; continue generation

Updated2026-10-21. Active draft [PR172](https://github.com/dwijayuda/pskernel/pull/172)
on fix/psc1-closure-normalization-20261021 preserves #171 at
1fad9ed53cda9b23ac30be9cea85e7857437564e and every intermediate commit.
Execute [the Sol High plan](docs/PSC1_SOL_HIGH_CONTINUATION_PROMPT.md)
continuously. The user explicitly requests no small-milestone handoff.

## Exact qualified checkpoint

Source head912dcc1c055f78ead505c057b1271b88fd1656e5.
Tested merge3c0e45261448a8c633fe82d4be79586d1ec1c90d.
All final GitHub workflow states were re-queried completed/success:
- [full scoped39527583902](https://github.com/dwijayuda/pskernel/actions/runs/39527583902),37/37 steps;
- [focused native39527583957](https://github.com/dwijayuda/pskernel/actions/runs/39527583957),11/11;
- [whole closures39527584037](https://github.com/dwijayuda/pskernel/actions/runs/39527584037), all3 phase jobs.

[Exact committed receipt](docs/PSC1_BACKEND_CLOSURES_QUALIFICATION_2026-10-21.json)
contains complete consolidated scoped qualification, per-lane canonical graph
identities, source/logical counts, partial names and all artifact metadata.
Scoped artifact12315040160:
sha256:4a63bc481457054c9e3fe9bcf44b7bab135d349e619bd1f962311ffa9dc0ec73.
Retention applies; committed receipts stay durable and are not authority tokens.

## Complete actual compiler closures

BOTH fresh grammar lanes accept every selected source module:
semantic67/67/67; DirectJS79/79/79; Rust84/84/84
(modules/parse/elaboration). Strict selected-phase gates run all source modules;
none is skipped. PS is owned canonical translation from repository Lean, retained
as actual readable parser inputs with byte counts/SHA256. It is not independently
authored PS compiler source.

Whole selected graphs actually passed independent official admission and original
strict IR validation in both lanes:
- semantic checked-only:2423 original/logical Core declarations;
- DirectJS ordinary-checked:3144 original /3146 logical declarations;
- Rust ordinary-checked:2961 original /2964 logical declarations.

Actual origin/member coverage equals the original source Core batch. Ordinary
logical expansion adds one retained private implementation body per actual partial:
DirectJS psBackendPublicTypeSupported and psJsNeedsUtf8Runtime; Rust the target
predicate and RuntimePlan typeRequirements/exprRequirements. The checker admits
the exact retained logical graph. Erasure then consumes the SAME immutable checked
batch or ordinary source/logical/body pairing; psCompilerOrdinaryIr repeats pairing
validation. The actual psStrictValidateModule entry point accepts the resulting
original IR. Canonical admission bytes match between lanes in each phase.

Official Lean4.35.0 checker commit
eb6cafb7290e8bd5f2937522d8d804f58f02bafc uses the unchanged provider-prelude
environment and kernel limits. Owned-kernel checks remain separate. This is exact
source-graph admission/IR evidence, not erasure/backend preservation, unrestricted
language conformance or generated compiler execution.

## Normalization and ownership

ParseDo124:67 and all subsequent syntax/elaboration/compiler/backend census
blockers are corrected. Complete module normalizations preserve all compiler
decision logic, validation/refusal order and existing budgets, using explicit
constructors, sequencing, typed callbacks and structural state workers.
Maintained both-lane gates and all prior native/runtime/refusal groups remain.

Unsupported private tokens formerly became trailing application arguments of a
preceding definition. Both parsers now refuse them cleanly. Original file-private
compiler helper leaf names move under explicit Ps.Internal.ElabData and
Ps.Internal.RustRuntimePlan owners; every call uses the qualified identity.
The active direct host excludes that reserved implementation namespace from public
entry roots while retaining the exact source/admission/runtime dependency graph.
This corrects the earlier Data normalization's global private leaf names.
[Ownership map and policy](docs/PSC1_COMPILER_INTERNAL_OWNERSHIP.md).
Actual handwritten Lean/PS captured-entry tests check admission, retained internal
helpers, hidden public roots and refusal of unqualified helper access.

Earlier immutable source/semantic/frontend receipts remain scoped to their
original source identities. New qualified checkpoint above includes this correction.

## Active continuation — canonical original IR identity, pending CI

Add portable CompilerIr.Encode, registered as an explicit Lake root and selected
DirectJS/Rust dependency. The candidate phase counts increase by one; do not
substitute the old79/84 checkpoint for the new live census. Every new source must
pass both maintained grammar gates.

[IR identity format](docs/PSC1_IR_IDENTITY_FORMAT.md) retains all constructor tags,
owners, labels, types, binders, list order and bodies; exact integer payloads are
decimal JSON strings. Encoding is data, not validation. Retain the actual original
IR that passed strict checking with size/hash and grammar byte parity, and derive
primitive inventories from those IR bytes. Exhausted serialization depth refuses.
New native tests cover independent JSON parsing, huge integers, Unicode/escapes,
graph/body identity changes, match labels/bindings/projections, malformed IR
validation and serialization exhaustion.

Add a LIVE DirectJS checked-only refusal test: the real complete backend source
with original partial functions must refuse unsupportedDeclaration before
independent admission; no automatic ordinary fallback. Explicit ordinary mode
continues as the separately qualified path.20 closure count/assurance contract
checks remain, alongside38 census integrity checks and every prior gate.

Next: qualify original/transformed IR identities and actual target emission, then
add/execute a portable scalar compiler facade. Native stage0 may generate G1 once;
afterwards deny native frontend/eraser/emitter delegation, retain the external
checker and target tools, and record actual subprocess allowlists. Execute
handwritten positive/negative multi-module/namespace/integer/Unicode/pattern/
handler/ordinary-loop cases, then identical compiler closure G1->G2->G3.
Rust owned aggregate callbacks and R1->R2->R3 follow with their own evidence.

## Commands and pending boundaries

Linux CI only:
- lake build psc1_source_census_probe psc1_backend_normalization_tests psc1_ir_encoding_tests
- node scripts/compiler-source-census-contract-tests.mjs
- node scripts/compiler-closure-contract-tests.mjs
- node scripts/compiler-source-census.mjs --strict-phase directjs-compiler
- node scripts/compiler-closure-assurance-tests.mjs
- node scripts/compiler-closure-qualification.mjs --phase semantic-compiler --assurance checked
- node scripts/compiler-closure-qualification.mjs --phase directjs-compiler --assurance ordinary-checked
- node scripts/compiler-closure-qualification.mjs --phase rust-compiler --assurance ordinary-checked

Generated compiler execution, transformed compiler IR, self-compilation and
G1/G2/G3/R1/R2/R3 remain not-run. Canonical IR encoding/inventories are pending in
the current candidate. No formal preservation theorem is provided. All14 full
Practical Core families remain incomplete. Efficient optional indexing/finite
iteration must be measured/fixed where actual compiler workloads reach them;
Rust aggregate closures, typed IO and remaining finite parity cases stay open.
Component Wasm ABI remains Bool-only. PSC2/Lean4.34 history is not current evidence.

GitHub/Linux CI exclusively; no local repository checkout/files/build/tests.
Fresh expected-SHA non-forced descendants only. No main merge/release/registry
publication, unchecked axiom/authority, source filtering, weakened tests or raised
existing budgets/pins. The final #171 scoped39508739868/focused39508739941 were
verified before continuation writes. Continue beyond this checkpoint.
