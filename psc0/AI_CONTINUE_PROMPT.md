## Native keyword ownership — qualification pending

Preparation8f0950c0 / run39088579549 / job117560230257 built the native compiler
and is continuing retained foundation checks. Do not cancel it. The next child
also applies the existing native keyword table at application boundaries:
native then/deriving/mutual/monotonicity cannot become ordinary arguments.
The common ProofScript table alone does not own these native delimiters.
This follows pinned Parser.Term.ite/argument and Parser.Command; source grammars
remain separate and share semantic AST/elaboration. Full qualification is pending.

## Native term construction layout — qualification pending

Preparation3897a2e2 / run39088402975 / job117559717894 failed compilation in
the new Lean.Term module at five multiline record expressions. Shared binder,
scope, command and retained semantic modules compiled. AST construction is now
bound before the parse-result record throughout the affected term reader;
no semantic or acceptance change. Qualification of the complete native term
and ordered-binder slice remains pending. Main is still037fda49.

## Binder-view construction and complete prefix ownership — qualification pending

43a91de8 / run39088233267 / job117559220561 failed production compilation:
the new optional source-origin field is an explicit constructor argument in Lean.
Both constructor sites now supply it. No semantic qualification ran on that SHA.

Subsystem review also applies ordered annotation resolution to section-variable
groups, not just declaration/lambda binders. Selected section captures retain only
their selected origin names and IDs. Native tactic termination recognizes the
lexer's explicit EOF token, and native command separation permits EOF without a
final newline. These are shared syntax/scope invariants, not weakened assertions.
The exact native/portable shadowing rejections and prior positive observations
remain required. Main stays 037fda49; the new preparation child must qualify first.

# Continue PSC0 v7.2 — Complete M3+B

## Native term and binder-prefix correction — qualification pending

Preparation2f82244c/run39087221158/job117556210481 completed FAILURE. The native
compiler built; packing found a .ps fixture semicolon (the selected separator is
newline), and the new native control rejected the shadowing group {T value : T}.
The fixture also used unavailable Except.isError; the child uses !isOk.

This is a real semantic finding, not just a fixture repair. Pinned Lean
Elab/Binders.lean:136-168,208-235,423-456 expands names into binder views and
elaborates each annotation in the preceding names' context. PSC0's earlier
group-wide annotation cache incorrectly ignored shadowing. Shared Scope and
Binders now process names in order. Group-origin metadata preserves the existing
multi-name source receipt and actual ordered local IDs after scope expansion.
Old successful outputs keep their values using valid non-shadowing names; the
exact rejected shadowing forms remain explicit native/portable negative controls.
The canonical v7.2 ordered telescope rule is unchanged. Earlier bounded M2 job
success does not establish correctness of the contradicted binder interpretation.

The native program now uses an owned rich term reader, sharing v7 literals,
sort/universe nodes, operators, named-call AST, binder groups, projections/indexing
and tactic nodes. Native application checks actual whitespace and indentation
per Parser.Term.argument:885-897. Native conditional, match-row and tactic layout
remain grammar-owned. ProofScript keeps comma calls, braced blocks and newline
term separators. This is not conversion through .ps or a host compiler fallback.

Shared Core comparisons now cover grouped parameters, universe inference,
operators, named arguments and a scientific Float literal; actual native input
proofs reach the official kernel. Five target emissions and two mixed-module
directions remain in the existing paired fixture. Native data/class/instance/
deriving/where/do/full-termination syntax and complete mutual WF remain open.
No foundation, assumption, budget or runtime acceptance is relaxed. Do not
promote until complete preparation and exact-SHA integration qualify the child.


## Current native input routing slice — qualification pending

The current preparation child implements explicit v7.2 source-kind ownership
for isolated requests and named module sources. The CLI accepts .ps and .lean
and records the selected kind before reading source. The native adapter emits
PsSyntaxProgram and shares scope commands, binder groups, elaboration, kernel
checking, typed erasure, IR validation and all target emitters with .ps.
No source printing/conversion or host Lean fallback is involved.

A single paired fixture is integrated into the existing Where qualification:
exact checked definition comparison, shadowing multi-name annotations, mixed
module imports in both directions, official-kernel checking, five target
emissions and common assurance/noncomputable refusals. Existing backend observers
receive both source kinds (two native oracle values each); their execution is
pending. Source reconstruction and broad native syntax parity remain open.

Run39086069241/job117552793316 at1b1cb7fe completed FAILURE. The identical native
mutual equation now builds using checked equations, but the portable retained-call
fixture used non-selected braced mutual/native split explicit headers. This
child uses v7.2 mutual/end and comma groups; the second peer's type parameter is
explicit in both source and native control. It retains three reordered slots,
dependent fixed values, nested lambda/let call scope, original source arity,
returned-function exclusion and conservative underapplication assertions.
No acceptance condition or compiler call-analysis algorithm is relaxed.

Inspection also found the focused M3 Rust step wrote the noncomputable harness
before executing the P1 harness. This child executes each harness immediately
after generating it. Prior workflow success remains historical job evidence;
it does not establish the overwritten P1 Rust observations. Requalification
of that runtime lane is required. Main037fda49 remains unchanged.

See docs/PSCV0_M3_NATIVE_INPUT_ROUTING_2026-10-18.md for pinned references,
architecture and remaining native syntax work. M3+B is OPEN.


Read AI_WORK_STATE.md, canonical v7.2, the M3 exit ledger and roadmap.
Live repository/CI overrides this checkpoint. Continue autonomously through
GitHub connectors and GitHub Linux CI only; no local checkout/files/build/test/
compiler or Desktop Commander. Native portable .lean; Lean4.35.0
 eb6cafb7290e8bd5f2937522d8d804f58f02bafc. Study pinned source/tests before
substantial design. Minimal coherent validation, no PSKernel-Core/C0/self-host/C5.
Approved assumptions exactly propext, Quot.sound, Classical.choice. Wasm GC inside;
linear memory only at explicit ABI boundaries.

**Input-language contract clarified by the user on18 October:** both `.ps`
and `.lean` files supplied to PSC0 follow the selected v7.2 language features,
semantics and assurance rules when compiling to JavaScript, TypeScript, Rust,
Wasm, WAT and other supported artifacts. This concerns compiler INPUTS; it is
not merely an instruction about the compiler implementation's .lean files.
The two source kinds keep their respective surface grammars: native Lean layout
and application in .lean, owned ProofScript spelling in .ps. Both must converge
on shared resolution/elaboration, checked Core, typed erasure, validated IR and
backends. A .lean extension cannot bypass unsupported-feature, dependency,
assumption, recursion or verification rules. Do not silently parse .lean as .ps,
treat arbitrary host Lean as accepted input, or infer input parity from native
reference tests. Record actual support separately until paired qualification
passes. Compiler implementation remains native portable .lean; self-hosting
and immediate C5 stay out of scope.

Repo dwijayuda/pskernel, main psc0/pscv0-v7-native-lean-v1, prep
psc0/m3-fixedpoint-foundation-20261018. PR109 draft/open/unmerged on its original
base; attach in a new chat. Fresh refs and expected-head non-force writes only.
Never supersede/cancel a healthy main Native; at most one active/one pending prep.

Main037fda4914ba30b5b8f2074e82ffbf9b0efeef0c is now the last complete
five-gate acceptance: Native39084512384, M3 39084512415, F1 39084512357,
F2 39084512390 and F3 39084512422 all SUCCESS. Exact artifacts and scope:
docs/PSCV0_M3_INTEGRATION_037FDA49_2026-10-18.md. Both attempts to retrieve the
whole focused log failed; no measured aggregate runtime count is claimed.

Preparation3386891/run39084134295/job117547901808 completed SUCCESS for
component-functional construction. Preparationade87651/run39084942848/
job117549579617 completed SUCCESS for fixed scopes and shared source preparation.
These later constructions are not in main037's accepted compiler/test identity.

Retained-call candidatea5287a1b50110d348303e67255ab888711931ff7,
run39085518962/job117551185828, completed FAILURE only in the packing build.
The new native reference theorem used decide on an opaque well-founded mutual
definition; reduction stopped at (callFirst 7 6 2).beq 7. Production and all other
retained foundation/WF/P1/noncomputable checks passed. The portable new probe
did not execute. The current child proves the identical expected equality using
simp with Lean's checked generated unfolding equations. No compiler algorithm,
expected result, acceptance condition, assumption or budget changes. Qualification
of this correction and the new portable probe remains pending; do not promote
until the entire preparation passes.

Continue complete mutual-WF source/proof/runtime integration using the shared
PSum/PSigma and fixed-scope owners. Preserve original capture identities, actual
member measures and common relation, branch-scoped decrease evidence, exact
original-body equations and whole-functional runtime validation. A valid f=f
cannot authorize body replacement. PSum remains a retained unselected5-declaration
asset. Source multi-member WF stays refused until the whole path is ready.

Reconcile six M3 exits and qualify Native/M3/F1/F2/F3 at one exact SHA.
Update both handoffs, roadmap and exit ledger each meaningful slice.
Do not stop merely to report a passed slice, weaken assertions or invent counts.

## Input parity within the existing roadmap

Read docs/PSCV0_V72_INPUT_LANGUAGE_CONTRACT_2026-10-18.md. Atade87651,
Compiler/Api.lean routes .lean through ParseLean into PsSyntaxModule, while
Host/NativeV7.lean uses the Pscv0 PsSyntaxProgram frontend with no explicit source
kind. ParseLean's declaration dispatch is the older def/partial-def/theorem/
inductive/structure selection. Existing .ps qualification therefore does not
establish .lean parity for newer scopes, strategies or mutual declarations.

Close the selected M3+B input-routing/feature gap as part of its existing source
strategy and cross-stage exits. Carry the same two-input obligation through
M4+C/D and M5+E; do not create another roadmap or reopen the historical bounded
M2 acceptance. Use common syntax/semantic owners and paired source fixtures,
not a second elaborator or a text/filename workaround. Do not claim parity before
actual .lean input traverses PSC0's checked pipeline and required backend lanes.


Preparation9223dd76/run39086928911 failed at the native authoring build because
`scoped` was used as a local name; it is a Lean keyword. The child renames those
locals and the analogous `syntax` local in the paired fixture. No parser rule,
semantic assertion, foundation or budget changes. Execution remains pending.


Preparationee267b56/run39087064923 failed at native parsing of a multiline
constructor argument inside the new program record. The child names the
constructed declarations before returning their parse records, keeping the same
syntax and semantics. Paired execution is still pending; do not promote.
