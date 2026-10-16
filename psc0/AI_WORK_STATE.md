## M3+B current checkpoint — source compatibility and qualification repair

Latest fully accepted compiler/test: `fbbc5271419dde8b183be723f07ff1f75a462013`.
All five gates passed at that SHA: native 38976283998 (33/33 reported steps),
F1 38976284003, F2 38976283981, F3/F4 38976283973 and focused 38976283967
(15/15). The receipt is
`docs/PSCV0_M3_NESTED_ELIMINATION_TYPED_RECURSION_QUALIFICATION_2026-10-16.md`.
It qualifies the accumulated typed-WF/direct-mutual-structural changes and
complete selected nested elimination/Hashable, including all existing outputs
on all five targets. The original native workloads and measurement step pass.

M3+B remains OPEN at approximately 65–70% (weighted estimate 67/100;
55–75% engineering uncertainty). All six weights remain data 30, source 15,
total recursion 20, P0 15, P1 10 and integration 10; accepted contributions
are 21, 10, 14, 13, 1 and 8. Unqualified local candidates add no points.

### Qualification repair: original main modifiers and real deriving refusals

The combined source/deriving/authoring tip
`ef8e3bb697861b65cfcc172d8372dfd9d2c3896b` is not accepted:

| Gate | Run | Result |
| --- | --- | --- |
| Native Linux | 38981566559 | FAILURE in checked source/module qualification |
| F1 | 38981566602 | SUCCESS |
| F2 | 38981566562 | SUCCESS |
| F3/F4 | 38981566550 | SUCCESS |
| Focused | 38981566596 | FAILURE while building source fixtures |

The native compiler, all new deriving production modules, and the new
nested/proof deriving fixtures compiled. Focused job 117243385545 stopped
before executing its source checks: pinned Lean rejected mixed partial and
non-partial original main declarations in the Where and MutualPartial
oracles. It also found an unregistered imported PreDefinitions fixture and
an untyped optionalType pattern. No five-target candidate qualification was
reached by that job.

Pinned MutualDef.checkModifiers/check (75–111) compares original main
headers before body elaboration or SCC partition. Main's later anyPartial
dispatch and getModifiersForLetRecs do not permit incompatible source main
modifiers, even when those mains are disconnected. v7.2
PSCV0-TERM-02/PSCV0-REC-STRATEGY-01 require the native group rule.

One shared original-main modifier predicate now guards both the source
preparation owner and retained typed-block validation. Local helpers are
excluded from that main-header check. A valid all-partial block still gives
plain recursive helpers its operational strategy; nonrecursive inherited
helpers remain ordinary, and unused hints add no captured header argument.
Explicit source partial opacity remains the v7.2 P0 policy, including when
native Main takes its nonrecursive-first path for its own declaration.

The independent Where evidence now uses a compatible two-main partial block
and a separate ordinary WF/P1 block. Exact native and portable mixed-main
refusals cover disconnected headers. The mutual fixture covers connected,
disconnected and body-error precedence, then reuses the same names in an
all-partial recovery with exact logical/body/provenance checks. A retained
source-kind/strategy corruption must fail at the shared whole-block gate.
The original seven Where requests, six exports/values and sixteen local
origins, and sixteen MutualPartial requests/five outputs, remain unchanged.
The existing PreDefinitions checks are now registered as a Lake library and
still execute inside the structural fixture. The owned default-binder pattern
has an explicit syntax type.

Native job 117243385381 reached module request 34 and rejected its stale
expected refusal: recursive List BEq is now supported. A complete NativeTests
audit found exactly three obsolete negative slots. Their counts and expected
elaboration phase are preserved with genuine missing-field-dictionary,
indexed-BEq and dependent-runtime-field refusals. The former capabilities
already have stronger independent positive coverage in the nested deriving
fixture, including generic groups, complete native strings/dictionaries and
all five required target lanes. Existing successful source/workload values,
request counts, checksums and budgets are unchanged.

### Checked WF authoring evidence retained

The same native job successfully exported the actual missing WF relation
closure before the unrelated source-test failure. It selected 34 new
declarations from 12 missing roots, with zero candidate axioms, 3 actual
recursor-rule comparisons and 2,329 shared source nodes. Official-kernel
replay passed against the unchanged frozen pre-WF environment.

The generated 466,947-byte candidate was reconstructed from its 228 emitted
JSON source chunks and matched CI SHA256
`b6bd56c4ab6378905d1d3ac2f0155eb5bc4742be3e19e684d64ac1a3007716f3`.
Native artifact 12081064126 is 3,696,804 bytes with archive SHA256
`0e1a9600ea9122d33556a7f711795a6f70c5acec6153429aecc6d6e526bfc034`.
That file is reviewed candidate data, not an active new Standard or a generic
WF execution claim. Its later selection must preserve actual dictionary
priorities, typed runtime layouts and independently measured snapshot identity.

All accumulated compiler/test changes still require five successful gates
at the next exact tip. The accepted compiler remains fbbc5271; this repair
does not raise the progress estimate. PR #109 remains draft/open/unmerged
on its original base. Native portable Lean, the exact 4.35.0 and v7.2 pins,
propext/Quot.sound, all original workloads and cloud-only validation remain
fixed. P1 remains fail-closed on the audited Classical.choice dependency.

---

## M3+B earlier checkpoint — mutual proof/default deriving and WF foundation authoring

Latest fully accepted compiler/test: `fbbc5271419dde8b183be723f07ff1f75a462013`.
All five gates passed at that SHA: native 38976283998 (33/33 reported steps),
F1 38976284003, F2 38976283981, F3/F4 38976283973 and focused 38976283967
(15/15). The receipt is
`docs/PSCV0_M3_NESTED_ELIMINATION_TYPED_RECURSION_QUALIFICATION_2026-10-16.md`.
It qualifies the accumulated typed-WF/direct-mutual-structural changes and
complete selected nested elimination/Hashable, including all existing outputs
on all five targets. The original native workloads and measurement step pass.

M3+B remains OPEN at approximately 65–70% (weighted estimate 67/100;
55–75% engineering uncertainty). All six weights remain data 30, source 15,
total recursion 20, P0 15, P1 10 and integration 10; accepted contributions
are 21, 10, 14, 13, 1 and 8. Unqualified local candidates add no points.

### Current candidate: mutual proof decisions and native ordered defaults

This checkpoint retains the unqualified source component/where work from
c55a7caf and complete selected nested Repr/BEq from 37ffb9a3, together with
the local-context repair and native hint-scope correction at
`a0c98a3fbc4d96c1d9e4438dca9a01f88925766a`. All accumulated
source/compiler/test changes require five successful gates at one tip.

Direct nonindexed mutual DecidableEq now uses the complete selected-slot
elimination owner. Each left family has its actual dependent decision motive;
recursive decisions come only from its real checked left-child hypotheses.
Each right operand is a bound variable under its own actual left motive;
no block-level synthetic local ID can collide with a later family's major.
Right-side cases bind every actual minor/IH, leave right IHs unused, and use
Decidable True for companion families. Existing equality transport and proof
field substitution remain responsible for same-constructor decisions.
Different-constructor and field failures use checked projections/discriminators.

The existing psElabIndexFunction owner now handles complete direct groups.
It checks the selected constructor's actual owner/ordinal, validates the
provided fallback, builds every constant motive and real minor telescope,
and checks the final projection or discriminator function. It does not
manufacture an inhabitant, a recursive hypothesis or an injectivity axiom.

Nonindexed group/nested Inhabited reuses the existing native constructor
algorithm: try constructors in order without new assumptions, then with
valid parameter requirements, pruning unused dictionaries. List.nil,
Option.none and Array.empty require no child default; a product uses its
actual component dictionaries. Group dispatch registers a genuinely generated
earlier closed instance before constructing the next member. It performs
no constructor-order search across families and introduces no forward/self
default. Other recursive deriving handlers continue using their original
input environment.

### Audited WF foundation authoring

This authoring checkpoint follows the unqualified proof/default deriving
commit `161b6e16652f3a597fe9d1d5b43988f9ee20a0b2` and includes all preceding
source, scope and nested deriving candidates in its exact-tip qualification.

A separate native-only export profile prepares the actual missing relation
declarations required by the next WF slice. The prior final Standard expression
is frozen unchanged as psSelfHostProdPreWellFoundedPreludeEnvironment; the
current final environment is its alias, so this checkpoint changes no active
logical declaration, class registry, runtime roster or snapshot identity.

The profile requests WellFoundedRelation, generic fix/fix_eq, invImage,
SizeOf and its actual Nat/default instances, sizeOfWFRel, the actual product
lexicographic instance/constructors, emptyWf and the selected Nat decrease
lemmas. It determines already-selected versus missing roots from the actual
frozen environment instead of assuming absence from a partial asset inventory.

Every missing root goes through the existing StandardExport closure,
official-kernel replay, real recursor-rule comparison and deterministic source
renderer at the pinned Lean commit. The approved assumption set remains
propext/Quot.sound. No proof body, theorem, dictionary or trusted admission
is fabricated or substituted by this profile.

The new native CI step runs that existing exporter, retains its source chunks
and exact generated-file SHA256, and uploads the candidate through the existing
artifact step. All earlier commands, frozen replay boundaries and budgets are
unchanged. The native workflow now has one additional required authoring step;
all five primary gates still need to pass at the same compiler/test SHA.

The resulting asset must be retrieved and reviewed before a later coherent
commit selects its declarations, real instance priorities and typed runtime
structure layout. Generic WF execution and relation-specific equations remain
a separate future compiler/runtime qualification.

### Independent evidence and target integration

Pscv0M3GroupProofDeriving separately declares native mutual families and
constructs the portable groups/instances. The direct decision fixture has
cross-family recursion, two equal-typed same-family children, dependent proof
fields and an unrelated always-false BEq instance. This checks actual
DecidableEq evidence independently of Boolean equality.

The fixture checks six generated instances and their exact requirements:
one DecidableEq A for each direct member, no requirements for either nested
empty default, and only Inhabited A for each required-default member.
Later defaults must reference the actual earlier instance and never themselves.

There are thirteen full recursor signature witnesses (2 direct, 8 nested
default and 3 required default slots), four direct second-family projection/
discriminator kernel equations, generic default equations and eight closed
output equations. Runtime preparation must yield exactly two real left
induction worker groups, each with two members and three captures; right
cases, projections and defaults must not create a recursive worker group.

The independently calculated output matrix is:

| flag | m3groupdecide | m3groupdecideatom | m3groupdefault | m3grouprequired |
| --- | ---: | ---: | ---: | ---: |
| false | 1 | 3 | 31 | 55 |
| true | 39 | 3 | 19 | 133 |

The focused workflow requires all thirteen source checks and adds these four
outputs to the established JS, strict compiled TypeScript, locked Rust,
V8 GC and Wasmtime component lanes. Rust generation remains immediately
paired with its execution. The original workloads, request counts, exported
names, expected outputs, checksums, budgets and pins are preserved. Existing
negative slots for newly supported capabilities retain genuine indexed or
nested-DecEq refusals; they are not removed to obtain a pass.

Both the shared equality/decision construction and the independent fixture
have static peer review. Compilation, source execution, fresh-kernel checks,
IR validation and target parity remain unqualified until exact-tip GitHub
Linux results are recorded. No local Lean/Lake/build/test execution occurred.

### Remaining selected boundaries and next work

Pinned Lean's DecEq handler explicitly declines nested inductives. Indexed
DecidableEq/Inhabited and indexed BEq remain outside this candidate, as do
arbitrary nested containers, constructor-local specialization parameters and
function-valued nested fields. The source mutual grammar remains def/function
only. A hint alone does not extend a local function's captured header;
v7.2 rule 10 and PSCV0-D-WHERE-01 preserve pinned native scope.

Broader actual WF relation selection/typed argument packing, optional main
result inference, additional dependent equality/elimination and the remaining
selected matrix are still open. P1 remains blocked by Classical.choice in
the actual pinned fixedpoint/equation dependency closure; unused suffixes
are not P1 support.

Native portable .lean, official Lean 4.35.0 at
eb6cafb7290e8bd5f2937522d8d804f58f02bafc, the exact v7.2 reference blob,
approved propext/Quot.sound and the official checking boundary remain fixed.
PR #109 stays draft/open/unmerged on its original base. No M4/M5 promotion,
replacement kernel, self-hosting, source migration, LLVM, reset or merge is
part of this checkpoint.

---

## M3+B earlier checkpoint — accepted nested/typed recursion; source and deriving candidate

Latest fully accepted compiler/test: `fbbc5271419dde8b183be723f07ff1f75a462013`.
All five gates passed at that SHA: native 38976283998 (33/33 reported steps),
F1 38976284003, F2 38976283981, F3/F4 38976283973 and focused 38976283967
(15/15). The receipt is
`docs/PSCV0_M3_NESTED_ELIMINATION_TYPED_RECURSION_QUALIFICATION_2026-10-16.md`.
It qualifies the accumulated typed-WF/direct-mutual-structural changes and
complete selected nested elimination/Hashable, including all existing outputs
on all five targets. The original native workloads and measurement step pass.

M3+B remains OPEN at approximately 65–70% (weighted estimate 67/100;
55–75% engineering uncertainty). All six weights remain data 30, source 15,
total recursion 20, P0 15, P1 10 and integration 10; accepted contributions
are 21, 10, 14, 13, 1 and 8. Unqualified local candidates add no points.

### Qualification repair: local context and native hint scope

The combined source/deriving SHA
`37ffb9a356e6ff04c5b607b2c6537469dc5ec32d` failed all five gates at
Where.lean parsing (focused 38978211015, job 117232632319). The lexical
repair `9c65ddca8fb814b31eab6b9f77c42ecabcc6debb` removed the reserved
meta bindings. All five gates then failed at that SHA; focused 38978550909
(job 117233725275) compiled the new Where, PreDefinition, Repr and BEq
production modules but stopped at WhereWellFounded.lean:104–106.

The inner local-context expression was inferred as the enclosing
PsElabWellFoundedResult. This repair explicitly binds PsLocalContext and
uses pure for that inner record expression. The final adapter still returns
the actual checked definition, equation, meta context and source information
from the existing WF constructor. No source/kernel/runtime qualification
was reached by either failed candidate; fbbc5271 remains accepted.

A proposed automatic capture extension was discarded after exact-pin review.
Lean MutualDef.collectUsed/withUsed closes definitions and lifted locals from
their actual checked header/body/local types and values. PreDefinition.Main
then clears the local context before TerminationMeasure reopens the already
closed function header. A section or parent local mentioned only by an active
termination hint is therefore unavailable unless a real checked dependency
already retains it. v7.2 rule 10 and PSCV0-D-WHERE-01 require this native scope
and local-recursion behavior. Adapting only the native oracle would not justify
a different portable capture rule.

The original body-based capture closure and typed component owner remain.
Unused ordinary/inherited-P0 hints add no captures; active WF hints operate
only in the genuinely retained header. The discarded all-ambient dependency
preparation, strategy-term capture seeding and graph relocation are excluded
from this repair. Two exact native rejections and matching portable checks
characterize measure-only and proof-only missing locals. Unused ordinary/P0
hints must retain their owned syntax while adding no hidden header capture.
The existing seven requests, six exports and expected values, and sixteen
local-origin records are preserved.

All five gates must pass at the same repaired compiler/test tip before this
source and nested Repr/BEq candidate is accepted.

### Current candidate: complete selected nested Repr and BEq

The preceding source checkpoint is `c55a7caf857959e07c0e86b8496b422289c8b82b`.
Its flat where ownership, typed SCC strategy selection, original-block capture/
universe closure, local provenance and checked WF source-equation transport are
included unchanged. That checkpoint and this deriving change are unqualified
until all five gates pass at one combined compiler/test tip.

Repr and BEq now consume the existing complete visible/nested elimination plan.
The shared DerivingContext cursor can select an actual auxiliary slot while
retaining all group motives and minors. It validates the actual specialized
family, its own indices, full recursor prefix and real child-hypothesis types.
Right-hand binary cases retain their real telescopes while ignoring all right
IHs; they do not invent a new recursive dictionary or worker group.

Repr uses a Nat-to-Format motive for visible families, Option and Array, a List
of already rendered documents for List slots, and a right-tuple accumulator for
Prod slots. Actual ReprAtom evidence selects native List bracketFill; ordinary
List uses bracket and Array always uses bracketFill. The actual ReprTuple
dictionary handles an independent right product field, while real Prod-slot
hypotheses flatten recursive right tuples in native order. Public constructor
formatting preserves explicit fields, max precedence, group/nest and application
parentheses. Proof/type placeholders and existing structure formatting remain.

BEq uses actual field dictionaries and real selected child IHs. Ordinary List
comparison visits the head first. Array checks equal lengths before demanding
any field comparison, then visits the final element first as pinned Array.isEqv
does. Reverse mode propagates only through the same specialized List tail;
List-valued elements retain ordinary forward comparison. Option and Prod preserve
their native shape and field order. No reflexivity optimization may bypass a
user-supplied nonreflexive BEq dictionary.

### Independent evidence and required cloud qualification

Pscv0M3NestedDeriving independently declares the native mutual and indexed types,
then separately constructs the portable declarations/instances. It checks a
nine-slot dependent-parameter group and a two-slot indexed group, eleven full
signature witnesses, five generated instances, exact selected-slot refusal and
a source singleton deriving positive.

The Repr exports compare complete portable rendered strings against complete
independently rendered native strings, including newlines/spacing/parentheses,
at widths 23/120 and precedences 0/1024. Coverage includes marked/unmarked List,
Array, Option, recursively flattened right tuples, independent Prod Nat Nat and
indexed public Repr. Numeric result bits encode full String equality; no text
hash substitutes for the comparison.

The BEq fixture compares native masks, an actual nonreflexive element dictionary,
ordinary list order, reverse array order and unequal lengths. Open generated-method
WHNF probes establish which unresolved Boolean is demanded first; two general
comparison equations join fresh official-kernel admission. The right-case path
must not introduce additional worker groups.

The focused workflow now requires all twelve source checks and adds these six
outputs to the existing JS, strict compiled TS, locked Rust, V8 GC and Wasmtime
runner: m3nestedrepr, m3nestedtuplerepr, m3nestedindexedrepr, m3nestedbeq,
m3nestedarraybeq and m3nestedatombeq. Each Rust generation remains immediately
paired with its execution. All earlier workloads, request counts, outputs,
checksums, dependency pins and resource budgets remain unchanged.

The two now-supported recursive Repr/BEq capability negatives become real
function-valued nested-field refusals, preserving their precise phase and the
existing fixture's counts. The prior nested fixture retains its raw-key oracle,
all seven outputs and its remaining Inhabited/DecidableEq refusal coverage.

Both production handlers and the selected-slot cursor have independent static
review. No local Lean/Lake/build/test execution is claimed. Only exact-tip GitHub
Linux CI can qualify this source/kernel/IR/backend candidate. Record failed gates
and their actual causes; do not weaken expected values, assertions or budgets.
When four gates pass, let the full native run finish before another feature push.

### Remaining selected limits

Indexed BEq, indexed/group DecidableEq and broader Inhabited remain outside this
candidate. Pinned Lean's DecEq handler itself declines nested inductives; preserve
that explicit native boundary. Arbitrary containers, function-valued nested
fields and constructor-local specialization parameters retain their refusals.

The next proof/default deriving work targets direct nonindexed mutual DecidableEq
and native constructor-ordered nonindexed group/nested Inhabited. Actual broader
WF relations and typed argument packing, optional main-result inference, further
structural/dependent elimination and the rest of the selected matrix remain open.
The source checkpoint's eager unused-hint name-resolution and registration limits
remain explicit. P1 is still blocked by Classical.choice in the actual pinned
fixedpoint/equation closure. An unused nonrecursive suffix is not P1 support.

Native portable .lean, official Lean 4.35.0 and its pinned commit, the exact v7.2
reference blob, approved propext/Quot.sound, the original official checking
boundary and PR draft/open/original base remain fixed. M4/M5 completion, kernel
replacement, self-hosting, compiler-source migration, LLVM, resets and merging
remain outside this work.

---

## M3+B earlier checkpoint — accepted nested/typed recursion; local definitions candidate

Latest fully accepted compiler/test: `fbbc5271419dde8b183be723f07ff1f75a462013`.
All five gates passed at that SHA: native 38976283998 (33/33 reported steps),
F1 38976284003, F2 38976283981, F3/F4 38976283973 and focused 38976283967
(15/15). The receipt is
`docs/PSCV0_M3_NESTED_ELIMINATION_TYPED_RECURSION_QUALIFICATION_2026-10-16.md`.
It qualifies the accumulated typed-WF/direct-mutual-structural changes and
complete selected nested elimination/Hashable, including all existing outputs
on all five targets. The original native workloads and measurement step pass.

M3+B remains OPEN at approximately 65–70% (weighted estimate 67/100;
55–75% engineering uncertainty). All six weights remain data 30, source 15,
total recursion 20, P0 15, P1 10 and integration 10; accepted contributions
are 21, 10, 14, 13, 1 and 8. Unqualified local candidates add no points.

### Current candidate: owned local definitions and typed dependency components

This commit adds the selected flat v7.2 where block and one typed predefinition
owner shared by source mutual groups, local definitions and unregistered
standalone WF/P1 hints. Syntax retains each local def, optional local result,
default, complete body/suffix span and enclosing declaration. Both printers
preserve the selected language's spelling and ownership. The .ps mutual
grammar remains def/function-only; no mutual inductive grammar is introduced.

WhereScope resolves headers/defaults without sibling aliases and bodies with
the real scoped aliases. Actual typed body/header fvars determine captures;
source-name occurrence lists are only candidates. Transitive peer captures
include type, instance, value and proof dependencies. Parent-body lambda/let
locals do not enter helper scope. Local binders can shadow helper aliases.
Private module names, monotone fresh IDs, postponed constraints and full
original-block universe closure are retained before dependency partition.

PreDefinition.Basic carries closed peer types, checked bodies with actual peer
fvars, source header count, exact captures, retained source hints and ownership.
PreDefinition independently validates these invariants, computes dependencies
from typed values, partitions deterministic SCCs and substitutes already
checked predecessor constants. Common captures and whole-block levels are
checked before specialization. A late failure returns no partially committed
command environment.

The effective strategy comes from the typed component and the original main
sources. Pinned TerminationHints.ensureNone emits warnings, not rejections.
Genuine nonrecursive components use checked ordinary declarations and exact
eq_def theorems before unused WF/P1 hints are considered. Actual proof-valued
nonrecursive local helpers become checked theorem declarations. An original
partial main gives every lifted local helper inherited partial intent before
SCC partition; a recursive inherited helper retains opaque P0/body identity
even when its raw source owns an unused termination_by or partial_fixpoint
hint. Those hints and spans remain in the AST and supply no WF/P1 evidence.
Explicit source partial retains v7.2's independently inhabited logical opacity,
including the established standalone/all-explicit-partial paths. No P0 defining
equation is emitted.

Recursive total components use the existing direct structural owner. A selected
recursive WF singleton is reconstructed under the actual typed callback through
WhereWellFounded. The exact returned definition and equation are checked against
the retained source body. RecursorEquation owns checked case/rfl transport using
the complete actual elimination plan. It can locate an original header major
below actual typed result lambdas while proving equality of the complete returned
functions in the original header context. Result lambdas do not become source
parameters, captures or measure variables. An independently checked wrong
zero-function/equation must fail at the exact constructor-case proof obligation.

Source provenance retains each real qualified local name, full local span and
actual emitted declaration membership. NativeV7's production batch mapping uses
that local span for helper declarations and generated worker ancestry. Ordinary
origins with no locals preserve their existing JSON shape; local metadata is
serialized explicitly when present.

### Qualification plan and preserved workloads

Pscv0M3Where checks independent pinned declarations, all-kind captures, forward
inference/defaults, sibling and parent/helper recursion, proof shadowing, private
identities, block-wide inherited P0, ignored hints, local WF and actual production
origin serialization. Its seven Host requests and six scalar outputs use the
existing JS, strict TS, locked Rust, V8 GC and Wasmtime runner. The workflow now
requires eleven source checks and retains every existing target command.

Pscv0M3PreDefinitions adds typed corruption checks through the existing structural
fixture executable. Existing mutual-P0 request counts/outputs remain unchanged.
The WF fixture still has sixteen Host requests and twelve runtime outputs.
Its obsolete nonrecursive-WF refusal is replaced by a native/portable ordinary
unused-hint acceptance; all fourteen remaining negative slots keep exact owners.
The unsaturated-header negative is made otherwise well typed so it still reaches
the WF-ARITY rule after the new shared typed prepass. No expected runtime value,
benchmark checksum, pin, heartbeat/depth ceiling or workflow budget is changed.

This candidate has static and independent review only at publication. It needs
native, F1, F2, F3/F4 and focused success at one current compiler/test SHA.
The fbbc5271 receipt does not qualify these source changes. Let the full native
gate finish when the other four gates pass before publishing the next feature.

### Remaining boundaries and next work

Unused hints are still name-resolved before SCC selection; an unknown or
out-of-scope name can therefore fail even when the hint would be unused.
This is not full unused-hint diagnostic parity. Registered standalone WF,
abbrev/opaque where registration and optional top-level result annotations keep
their current separate limitations. The selected local omitted result supports
nondependent codomain inference; genuinely dependent omitted results need an
annotation. Local nested where, attributes, theorem/instance/function/const and
mutual blocks remain outside the selected local grammar.

True multi-member WF, broader actual relation/argument packing, additional
structural shapes and further deriving remain open. Recursive P1 retains the
exact Classical.choice assumption refusal. A nonrecursive unused suffix is not
P1 implementation. Native portable .lean, official Lean 4.35.0 at the pinned
commit, the exact v7.2 reference blob, approved propext/Quot.sound, PR draft/open
on its original base and all M4/M5 boundaries remain unchanged.

---

## M3+B earlier checkpoint — shared nested elimination candidate

Latest fully accepted compiler/test remains
`01d762eb02eab1d2f795e5338cb3586cd1d1ace0`, recorded in the group-deriving receipt.
The repaired typed-WF and total-mutual candidate
`62a43dcc1ac9069533e4a48bf54639121cb265fd` has passed F1 `38973463203`,
F2 `38973463414`, F3/F4 `38973463241` and focused `38973463517` (15/15).
The full native gate `38973463333` was cancelled by the next compiler push
under the existing cancel-in-progress workflow setting. Its focused log confirms
all source checks, fresh-kernel equations and JS/TS/Rust/V8/Wasmtime execution,
including all twelve WF and six structural outputs. It therefore has four
passes, not five-gate acceptance. The latest accepted compiler remains 01d762eb.

The shared nested elimination and Hashable candidate
`7ce2388184f2c29cc49a2b1a367c05191828265a` needed Lean continuation layout
repair `78f5f2e09b4a4497ddc179648f3ed3a291544f02`, then one legacy
constructor-target initialization in `90cc412e2a171fef95af181c62f9e8c3196049d1`.
At 90cc412e all production modules compile, and F1 `38975380612`,
F2 `38975380763` and F3/F4 `38975380793` pass. Focused `38975380963`
failed compiling the independent native M3NestedKey source command at its
default recursion-depth limit. Native `38975381664` was still in progress
when that fixture blocker was inspected. No source/runtime pass is claimed.

This commit isolates the raw structural/definitional key oracle at the actual
official-kernel boundary. An independent Lean.Declaration.inductDecl constructs
the same family and constructor types, retaining Id in the second List argument.
Its types are compared with decoded canonical admission; the actual fresh kernel
must admit it, and all three public/auxiliary recursor signature witnesses must
pass. The existing canonical admission, three-slot distinction and one-declaration
checks also remain. Native source-command postprocessing support is not claimed.
The provider's options, existing heartbeat/depth ceilings, seven runtime outputs,
all earlier assertions, dependency pins and workflow budgets remain unchanged.

This repaired compiler/test candidate requires its own exact-SHA native, F1, F2,
F3/F4 and focused success. Let its full native gate finish before publishing the
next feature when the other gates pass; implement follow-up work separately.
Neither earlier native results nor focused passes qualify a different tip.

M3+B remains OPEN at approximately 60% (50–70% engineering uncertainty).
All six exit weights remain data 30, source 15, total recursion 20, P0 15,
P1 10 and integration 10; accepted contributions remain 17, 10, 10, 13, 1
and 7 points. Unqualified code adds no accepted points.

### One shared visible and nested elimination plan

Core's checked slot plan retains each visible family and each selected nested
specialization: its actual type former, common parameters, own indices,
constructor head/telescope, recursor identity and ordered recursive-field
targets. List, Option, Array and Prod slots retain their actual container
declarations; no virtual datatype or fabricated recursive metadata is emitted.
Public recursors and auxiliary rec_N entries must match complete reconstructed
telescopes, including motive universes and every real child hypothesis.

Discovery follows the pinned raw structural specialization keys and queue order.
Definitionally equal List(Key A) and List(Id(Key A)) keep distinct slots.
A raw prepass checks uniform family arguments and universe variables before
reduction can erase an occurrence. Existing source uniformity diagnostics remain.
Core.LevelNormalize owns the unchanged normalization definitions; the former
Meta module is a compatibility import, with no Core-to-Meta dependency.

The canonical bridge now accepts the actual retained environment through
psEncodeCheckedAdmissionsCanonicalIn. All three Compiler.Api admission paths
supply it. Fresh official Lean regenerates recursors from the original visible
group; the obsolete shallow unit-wrapper adaptation is removed. The legacy
environment-free API still handles direct batches and refuses nested batches
without their actual container declarations.

Iota, source Match, deriving, checked worker lifting and typed erasure consume
the same complete plan. Every worker retains an exact closed recursor equation,
the common capture telescope and all slot identities. Dispatch selects rec_N
plus its actual specialized child type and indices, never just a base name such
as List. Array/Prod elimination binds the actual major and each typed projection
once. Array uses the existing checked List conversion and shares that allocation
between its field and corresponding IH. No backend-specific recursion is added.

### Nested Hashable and qualification scope

The shared deriving cursor now constructs selected nested Hashable for the
four actual containers. List/Array preserve native left-fold order and seed 7;
Option preserves native none/some policy; Prod combines left then right.
Real slot hypotheses supply recursive results. No self dictionary or production
partial-recursion fallback replaces total checked elimination.

Pscv0M3NestedInductive covers a six-slot singleton, a nested mutual group with
alpha-renamed dependent parameters, an indexed public family with its own
unindexed List slot, repeated/deep specializations, and the distinct raw Id key.
Fresh-kernel full-signature witnesses, actual cross-slot equations/reduction,
generic hash laws, source cases and direct selected-child recursion accompany
seven independent native runtime outputs. Equal-count stale signatures, missing
or duplicate auxiliaries, universe/order errors, worker aliasing, nonuniform raw
occurrences and constructor-local specialization captures have explicit refusals.
The two old capability negatives now exercise still-unsupported function-valued
nested fields; their original runtime exports and observations are unchanged.

The focused workflow builds the new executable and runs its source/kernel check
plus JS, strict compiled TS, locked Rust, V8 GC and Wasmtime against the existing
generic runner. Every existing fixture, command, output, count, checksum, pinned
dependency and budget remains. Source aggregation now requires all ten fixtures.
Each Rust input generator remains immediately paired with its own execution.

### Remaining obligations

This candidate does not establish nested Repr/BEq/DecidableEq/Inhabited, arbitrary
containers, constructor-local specialization parameters or function-valued nested
fields. Default source induction on mutual/nested types retains the pinned
refusal without an explicitly selected supported eliminator. The .ps mutual
grammar remains def/function-only. The direct structural-SCC API does not admit
nested recursive fields.

Flat where/capture/SCC source ownership and exact checked transport between WF
match equations are being implemented separately. Broader WF argument/relation
packing and the remaining deriving/recursion matrix are still open. P1 remains
blocked by Classical.choice in pinned Lean.Order.fix/CCPO.csup and its equations.
Only propext and Quot.sound are approved. Native portable .lean, the existing
official checking boundary, PR draft/open/original base and all M4/M5 boundaries
remain fixed.

---

## M3+B earlier checkpoint — accepted group deriving; typed and mutual recursion candidate

Latest fully accepted compiler/test: `01d762eb02eab1d2f795e5338cb3586cd1d1ace0`.
All five exact-SHA gates succeeded: native `38967030820` (33/33 reported
steps), F1 `38967031191`, F2 `38967030836`, F3/F4 `38967030843`,
focused `38967030789` (15/15). Full native source/Standard, modules,
all runtime lanes, repeated component calls and the original measurement
step passed. Receipt: `docs/PSCV0_M3_GROUP_DERIVING_QUALIFICATION_2026-10-17.md`.

This accepts direct indexed Hashable/Repr and nonindexed group BEq through
the complete checked motive/minor cursor, actual child-family/index
hypotheses, ordinary checked captured instances/workers, and the shared
strictly ordered recursive-field predicate. It also retains all previously
qualified group elimination, measured-Nat recursion and ordinary P0 scope.
Earlier candidate and mixed-SHA sections below are historical.

M3+B remains OPEN at approximately 60% (50–70% engineering uncertainty).
The weighted accepted contribution is approximately 58 points: data 17/30,
source strategies 10/15, total recursion 10/20, P0 13/15, P1 1/10,
integration 7/10. This is an engineering estimate, not a conformance rate.
All six exits remain in the denominator. Unqualified code adds no points.

The typed well-founded source commit is `c69c45213e75aef292183078a1a8a736319cb2fa`;
total mutual structural construction is `293a6f797d8135e10c407779a8dc429afa8345f6`.
Layout/source-wrapper repairs `2b809e8d` and `42e1874d` retain the original
bodies and outputs. The focused step now collects all nine required source
checks before failing if any fails; target execution requires complete success.

Source repair `02f50d5b6fd0fd302b205381c206cb6a6711c817` addresses real WF
result-type shape loss. Closing argument lets could hide an already-known
function type behind a delayed type metavariable. The result type is now
retained after checking its free variables and rechecking it in the caller's
scope; ordered value lets, delayed decrease goals and the existing dependent
type-abstraction fallback remain. The twelve-output WF fixture is unchanged.

That repair also replaces a structural negative which stopped at unsupported
source-data formation with the Standard's actual Acc constructor and real
function-valued recursive field. It still requires exact
`PSCV0-MUTUAL-TOTAL: DIRECT-FIELD:` refusal. The independent native oracle's
initial automatic structural elaboration failed because Acc.brecOn only
supports Prop motives. Repair `913129f2ac168cb0b852e6cf4e9b6c640f085309`
uses the actual Acc.rec with an explicit Nat-valued motive and the real
function-valued child hypothesis. Its native axiom audit permits only
propext and Quot.sound; the portable relation is separately kernel-admitted.

At `913129f2`, F1 `38972836975`, F2 `38972836985` and F3/F4
`38972837002` passed. Focused run `38972837016` (job `117215101121`)
compiled all 627 Lean build jobs and executed all nine source commands.
The structural construction, exact refusals, fresh-kernel equations and all
five target emissions passed, as did every established source fixture.
Runtime target steps did not run because WF elaboration stopped at
`PSCV0-UNSUPPORTED-SOURCE-TERM (in m3wfbounded)`.

This commit corrects that fixture's bound proof to the actual exported
Nat.succ_le_succ. The selected Standard exports Fin.isLt and Nat.succ_le_succ
but does not export the originally referenced Nat.succ_lt_succ. Since Nat.lt
reduces to a successor inequality, applying succ_le_succ to the child's
actual isLt proof proves the same required bound. The dependent Fin value,
recursive call, independent native oracle, logical equation and all twelve
expected WF observations remain unchanged. No Standard or production code
change is needed for this correction.

Qualify this repaired compiler/test tip on native, F1, F2, F3/F4 and focused.
A prior native result cannot qualify the changed fixture. Both recursion
features remain candidates until all five exact-SHA gates succeed.

### Typed well-founded recursion candidate

The well-founded owner now uses the full explicit typed source header. One
changing measured parameter may have any checked domain depending only on
fixed captures; the Nat-valued measure may depend on those captures. All
remaining evolving arguments form the actual dependent state telescope, and
the result may be any checked type supported by ordinary erasure.

Typed call analysis closes dependencies before partitioning fixed, major and
state arguments. The real Nat.fix motive returns that state function.
Recursive arguments are checked and bound once in original order. The
public f.eq_def uses actual fix_eq and inferred-level funext/congrArg/Eq.trans
where state extensionality is required. No provisional global, recursive
proof assumption, eta conversion rule or runtime ABI is added.

Ps.Erasure.Entry owns validation of the actual definition, universe
arguments and current entry telescope. It recomputes binder roles, checks
local/order identities, and separates raw source-header arguments from
applications of a returned function. Ps.Erasure.WellFounded consumes that
validated entry and the real fixed-point term, then delegates typed
recursive calls to ordinary erasure. Proof Unit slots, erased indices,
polymorphic types and runtime parameters retain their existing conventions.

The original eight well-founded outputs remain unchanged. Four new native
oracles cover polymorphic List reversal with an ordered digest, a fixed
function and returned closure, evolving dependent Fin state with erased
family/proof captures, and a dependent Fin result. Fresh logical equations,
universe closure, all-kind entry roles, a returned-function application and
stale runtime argument-order refusal are checked in the same fixture.

Selected limits remain explicit: no several-changing-input measure pack,
no major domain depending on changing state, and no extension of ordinary
erasure's higher-rank/type-changing-state limits. Body lambdas do not enter
the source header or termination-measure scope.

### Total mutual structural recursion candidate

The shared scoped header preparation now feeds an actual typed structural
batch. Each source member root-matches one explicit major. Every function
owns exactly one ordered component of its actual family motive; families
may own zero, one or several functions. PUnit, an unwrapped component, or
right-associated Prod is constructed and checked at the actual motive
universe. Equal result types never identify functions.

The existing complete-group argument cursor builds motives and minors.
Every recursive call must target a real strict direct constructor field,
with the child's actual family/indices, invariant uniform parameters and
the full original member header. Its source identity selects the exact
component from that child's checked hypothesis; all other evolving
arguments and returned-function applications are checked in source order.

All completed ordinary definitions close without provisional peer locals
or recursive globals. Only then are the exact original source equations
proved against the actual public definitions using checked constructor
cases, delta/iota reduction and product projections. Any late failure
returns no batch. Existing ordinary compiler preparation constructs and
revalidates companion workers before shared erasure.

The new independent native fixture has six outputs. It exercises two
equal-typed functions with distinct observations, differing argument
arities/orders and evolving state, unequal family index telescopes, a
zero-owned companion at Type u, shared implicit/instance/value/proof
captures, exact public equation use and late-member atomicity. It runs
through direct JS, strict TS, locked Rust, V8 GC and Wasmtime components.

This slice requires a root match for every member, distinct header-local
indices, the same actual direct group and uniform parameters, and
equivalent successor motive universes. Nested/function-valued recursive
fields, escaping/unsaturated peers and general mutual well-founded
recursion retain precise refusals.

### Qualification and continuation

The current recursion implementation is a candidate. Require native, F1,
F2, F3/F4 and focused SUCCESS on one exact compiler/test SHA before accepting
it. M3 fixture/runner edits now trigger all five workflows; never combine
passes from different SHAs. Inspect full focused/native logs and retained
artifact metadata, and correct genuine failures without weakening checks.

Continue the shared nested specialization plan and flat local where typed
capture/SCC owner. Compatible disconnected mutual components, broader
structural/WF coverage and the final selected integration matrix remain
open. Where needs actual per-member capture closure and recursive component
dispatch; parser acceptance alone is insufficient. Default mutual/nested
source induction retains pinned Lean's refusal without a selected
eliminator. Source mutual remains def/function-only.

P1 remains unavailable because pinned Lean.Order.fix/CCPO.csup and their
equations require Classical.choice. Approved assumptions remain only
propext and Quot.sound. Continue unaffected work without expanding that
policy or inventing a fixed-point equation.

Native portable .lean; official Lean 4.35.0 at
eb6cafb7290e8bd5f2937522d8d804f58f02bafc. The only forward .ps reference is
PSCV0_LANGUAGE_REFERENCE_v7.2.md, blob 694115223777599ba28ee175e14bb642b7b6aa4b.
Original workloads, counts, checksums, budgets, pins and benchmark semantics
remain intact. Use connected GitHub/cloud CI, fresh expected-HEAD non-force
updates, and preserve concurrent history. PR #109 stays draft/open/unmerged
on psc0/pscv0-v7-m1-parser-ownership-v1; no new kernel, self-hosting, source
migration, LLVM or later-milestone promotion.

The following sections retain earlier checkpoint history.

## M3+B earlier candidate — source mutual P0 and typed measured-state recursion

The selected v7.2 def/function `mutual ... end` command now retains its
ordered members, per-member modifiers/spans and whole-group span. Compatible
P0 groups close the section telescope and universe union over the complete
source block, following pinned Lean before SCC partition. Every public
opaque has an independently constructed inhabitant in the original
environment; all real opaque headers are staged before any body. Typed local
peer aliases apply the exact captured Core telescope, including implicit,
instance and proof slots. They support bare peer values and shadowed names,
and are removed before final body checking. Every source member owns its
public opaque and private numeric implementation identity. The existing
ordinary host path executes only the separately checked actual bodies.

Mutual group provenance now survives elaboration, target artifact origins and
the CLI serializer. Ordinary origin JSON keeps its existing fields; mutual
origins also carry source index, ordered group member identity and complete
group byte span. The new independent native/source fixture covers recursion,
imports/privacy, common captures, disconnected members, nullary functions,
bare higher-order peers, shadowing, implicit/instance binders, delayed proofs,
body-only universe closure and exact strategy/assurance refusals. Divergent
pairs are checked but never invoked. Total mutual and mutual well-founded
strategies still require their own checked construction; P1 retains its exact
Classical.choice policy refusal.

Well-founded recursion now accepts multiple explicit Nat header parameters
and Nat results. Typed call analysis separates fixed captures, one changing
measured parameter and other evolving state. The actual Nat.fix motive
returns the state function, preserving nonprefix argument order and fixed
measure dependencies. Every source call argument becomes one checked Core
let in its original order; final calls revalidate fixed arguments. No source
body lambda is promoted into the termination clause's header scope.

The public `f.eq_def` still follows from real `Nat.fix_eq`. State callbacks
use checked `funext`, `congrArg` and `Eq.trans` to expose calls to actual
public `f`; portable conversion is unchanged. Runtime lowering revalidates
the retained root body and full entry telescope, reconstructs a typed
proof-restricted public self-call in original argument order, and delegates
to ordinary erasure. Independent oracles cover nonprefix state/major/fixed
slots, beta-equivalent fixed arguments, a fixed offset measure, two evolving
states using the original values, a no-state case, and successor equations.
The existing one-batch fixture adds four exports without changing original
workloads, expected results, iteration counts, budgets or dependency pins.

Initial candidate `d0c6ee3dfea9b8a36ef5574cdbc50d3b526cbbdb` triggered all
five gates. Its focused build compiled Mutual, RecursionParameters and both
well-founded owners, then every gate stopped at the new Command local
`scoped`, a reserved Lean keyword. The syntax-only repair renames it to
`scopedMembers` and the analogous new fixture local `universe` to
`universeBatch`. No semantic assertion or expected diagnostic changes.
The repaired exact SHA must run all five gates; the failed candidate has no
runtime acceptance. Runs: native `38963849148`, F1 `38963849068`,
F2 `38963849997`, F3/F4 `38963849156`, focused `38963849930`.

Previous source-case checkpoint `34f43e6bfdaf91cfa965b9449eca5bb30bf66597`
passed F1 `38962445093`, F2 `38962445118`, F3/F4 `38962445161` and focused
`38962445128`, including every group-match target. Native `38962445114`
compiled and regenerated the checked assets, then rejected source case 64
with TYPE-MISMATCH instead of its expected diagnostic for forbidden
Or True True elimination into Nat. The shared recursor cursor now preserves
the existing Core application-type error while checking the incompatible
motive earlier. Existing native expectations remain unchanged; the focused
fixture asserts that exact error for both singleton and group Prop cases.
The failed checkpoint is not accepted. The current compiler/test candidate
requires all five gates on its own SHA.

Latest fully accepted compiler remains
`a7c6dade87a9d8df74d5248e8276623e7870078c`. Approximately 40% was fully
qualified before these candidates (30–50% engineering uncertainty), with all
six exits retained in the denominator. Full group deriving/induction,
broader nested traversal, total mutual recursion, general dependent
well-founded domains/results and integration remain open. P1 is unavailable
under the unchanged approved assumptions `propext` and `Quot.sound`.
Continue implementation after the exact cloud checkpoint; PR #109 remains
draft/open/unmerged on its original base.

## M3+B earlier candidate — source cases over complete inductive groups

`Ps.Elab.GroupElimination` now consumes the actual checked recursor argument
telescope in complete family/minor order. Source `match`, pattern matrices,
and `cases` specialize the selected family's motive and use checked
`PUnit.{u}` / `PUnit.unit.{u}` for companion families, following pinned Lean's
`cases_on.cpp`. Every supplied argument is inferred and unified against the
real Pi domain. Singleton matching uses this same argument owner.

Per-family indices, major-dependent results, and reverted dependent context
remain in the selected motive. Group case branches retain the actual minor
binders internally but expose no fabricated induction hypotheses or new map
of decreasing recursive calls. Existing enclosing singleton recursion keeps
its actual hypothesis map. Full group induction, cross-family source
structural recursion, and unsupported fixed-index heterogeneous transport
retain explicit refusals. The def/function-only source `mutual` grammar is
not widened into mutual inductive syntax.

The new source fixture covers alpha-renamed dependent parameters, the second
indexed family, dependent copy/context suffixes, Prop proofs, higher result
universes, impossible fixed-index branches, and nested cases under Nat
recursion. It checks fresh official-kernel equations, portable reduction,
complete metadata/PUnit refusals, and emits all five targets. Runtime exports
are `m3matchleft`, `m3matchright`, `m3matchnested`, and `m3matchzero`, with the
independent native oracle fixing every expected result.

Underlying group-fold and one-Nat-measure fixtures passed focused
`38961009875` on test-only `5c8bc97280098ad768b6de5ab9283624f97e5149`:
all 15 reported steps, JS, strict compiled TS, locked Rust, V8 GC and Wasmtime
components. The real Nat.fix and fix_eq assumption audit stays inside the
approved policy. Production `59fddc28ec01726e7a42258d7cc5f3020ed8969b` has
F1 `38960668822`, F2 `38960668820`, F3/F4 `38960668821`, and native
`38960669014` green; native completed all 33 reported steps, including the
unchanged performance checks. This is mixed-SHA evidence, not a replacement
for all five gates on this new exact compiler/test checkpoint.

Latest fully accepted compiler remains
`a7c6dade87a9d8df74d5248e8276623e7870078c`. Approximately 40% was fully
qualified before these candidates (30–50% engineering uncertainty); reassess
against all six exits only after exact integration acceptance. P1 remains
unavailable because pinned Lean.Order.fix/CCPO.csup requires
`Classical.choice`; approved assumptions remain only `propext` and
`Quot.sound`. Group deriving, broader nested traversal, multi-argument total
recursion and mutual source strategies remain active work. M3+B remains OPEN,
and PR #109 stays draft/open/unmerged on its original base.

## M3+B earlier candidate — group runtime and checked Nat-measure recursion

This checkpoint combines the retained atomic inductive-group implementation
with typed companion-worker execution and selected total well-founded
recursion. It is a **compiler candidate requiring all five gates on its own
exact SHA**, not a full M3+B acceptance claim.

Initial cloud compilation of `68a14501dc670142aa61c2bee4eae05fe7f68ac5`
failed in all five gates before runtime qualification: the three built-in
`PsRuntimeInductiveInfo.mk` calls omitted the new optional group argument,
and `Ps.Elab.WellFounded` referenced a name helper outside its import closure.
The following repair supplies explicit singleton `none` arguments and uses
ordinary Core name construction. No expected values or acceptance checks
change; all five gates must run again on the repaired compiler SHA.

The next build, `ec22f4437e9f0d346af0a0da6d7981788760f6fb`, compiled those
owners and found two detached `.mapError` continuations in
`Ps.Erasure.WellFounded`. They are joined to their parenthesized calls, along
with two analogous fixture continuations identified before that fixture could
compile. This is a Lean syntax repair; runtime results remain unqualified.

The repaired `0e2d628d6f4f4c7c7ed6f4e9f9a157374515012c` compiled the
well-founded runtime and expression owners, then all five builds stopped at a
split record-field value in `Ps.Erasure.Definition`. The next syntax-only
repair normalizes all three new split current-definition updates, their nested
scope records, and the analogous fixture companion-plan records. No semantic
expectation changes; qualification must resume on the repaired exact SHA.

Production compilation succeeds at `59fddc28ec01726e7a42258d7cc5f3020ed8969b`.
F1 `38960668822`, F2 `38960668820`, and F3/F4 `38960668821` pass; native
`38960669014` is still running. Focused `38960668913` stops only while
compiling the new fixtures: `prefix` is a reserved Lean identifier, and the
well-founded oracle needs the qualified `Lean.logInfo` API. The fixture-only
repair renames those locals and qualifies the call, preserving all assertions.
The repaired focused run and continuing production runs span SHAs; they cannot
serve as five-gate same-commit acceptance.

The group runtime path constructs one ordinary checked definition per family
from the actual complete recursor application. All workers retain the same
capture telescope, levels, parameters, motives and minor arguments; only the
family's own indices and major vary. A small names/capture-count record locates
these definitions. Before erasure, their complete retained equations and
runtime declaration identities are revalidated. Cross-family recursive calls
reuse ordinary typed call erasure, including erased slots and distinct result
types. No sidecar record grants proof or kernel authority. Native group syntax
does not expand v7.2's def/function-only source mutual grammar.

A total `termination_by` declaration now retains its measure and optional
`decreasing_by by { ... }` proof, scope and source spans. The selected executable
slice has one explicit Nat argument and Nat result. Its real logical body uses
the already checked `WellFounded.Nat.fix`; each source recursive call creates
a scoped decrease goal, and one proof sequence handles all goals in creation
order. The source-owned batch also contains a checked `f.eq_def` theorem from
`WellFounded.Nat.fix_eq`. This is exact fixedpoint unfolding; constructor
branch equations reduce, while broader open-match equation normalization is
not claimed. Runtime lowering recognizes that actual typed construction and
erases its checked decrease proof through the ordinary function ABI.

Focused evidence adds a parametric group fold with captured state, differing
family index counts/result types, and rejection of a well-typed stale worker
equation. The independent well-founded fixture covers arithmetic decrease,
multiple ordered proof goals, a nonidentity measure, default proof, source
ownership/private scope, a checked successor equation, and semantic refusals.
Both execute scalar observations across JS, compiled TS, Rust, V8 GC and
Wasmtime using the existing pinned tools. Original workloads, iteration counts,
checksums and budgets are unchanged.

Earlier group production `c16d16be58efbf4b40a467af25db59c88c648a10` passed F1
`38956942775`, F2 `38956942665`, F3/F4 `38956942889` and full native
`38956942787`. The corrected independent
group oracle on test-only `0179354359c9e75de3e7b6f74d7e86835232dff6` passed
focused `38958044907`, including the P0 captured recursive closure and existing
deriving target matrix. The earlier focused failures were test import,
parameter-spelling and direct mutual-recursor code-generation issues, not
relaxed expectations. These results span SHAs and do not establish same-commit
integration acceptance.

Latest fully accepted baseline at preparation remains
`a7c6dade87a9d8df74d5248e8276623e7870078c`. P1 remains fail-closed:
pinned `Lean.Order.fix` / `CCPO.csup` and generated equations require
unapproved `Classical.choice`; the independent oracle observes this exact
dependency outside the admitted Standard. Approved assumptions remain only
`propext` and `Quot.sound`.

M3+B stays OPEN. Approximately 40% was fully qualified before this candidate
(30–50% engineering uncertainty); do not count candidate code as accepted
coverage. Source group Match/deriving, broader nested traversal, broader total
and mutual-recursion strategies remain critical work. No M4 verification,
effect, general preservation or new performance claim is made. PR #109 remains
draft/open/unmerged. Preserve the historical checkpoints and receipts below.

## M3+B candidate — atomic groups, portable reduction and ordinary closures (17 October 2026)

The native `psElabInductiveGroup` entry point now stages all family headers,
checks compatible common parameters and result universes, elaborates every
constructor in the common environment, and constructs all group motives and
constructor minors. Existing singleton source declarations use the same
mechanism. `Ps.Core.InductiveGroup` owns ordered group shape;
`Ps.Bridge.CheckedAdmissions` resolves unique retained records and emits one
canonical official-Lean inductive batch. Duplicate/conflicting descriptors,
incomplete retained group recursors and reordered membership refuse.

This is a **new compiler candidate, not an acceptance receipt**. The focused
workflow includes independent Lean declarations, canonical group admission,
whole retained recursor-signature witnesses, cross-family reduction, indexed
and Prop elimination checks, and explicit unsupported-consumer refusals.
Portable iota selects the target family's global minor segment and each
recursive field's actual family recursor with its own indices. Independent
native and canonical kernel equations are compared with portable reduction;
malformed group metadata, ordinals and major families remain stuck. Source
match/deriving/runtime consumers and nested auxiliaries remain unfinished. The v7.2
`.ps` mutual grammar still selects def/function groups; it is not expanded to
mutual inductive syntax by this native API change.

The preceding P0 assurance and P1 source-strategy candidate is included.
A finite P0 fixture passes a recursive closure with changing captured state
through a higher-order function for comparison on every target lane.
Its parser indentation failure was corrected in
`ef47dee3de4de6298de276322a30b2bac3af0a73`; qualification must be read from
actual runs, never inferred from its successful compiler build. Its focused,
F1, F2 and F3/F4 gates passed; its native run was superseded/cancelled. The
first group builds found missing portable Lake registration and a Data record
indentation error; both are corrected without weakening checks. P1 remains
unavailable because pinned `Lean.Order.fix` and its equations transitively
require unapproved `Classical.choice`. Only `propext` and `Quot.sound` remain
approved; the isolated oracle observes that blocker without changing policy.

Require all five gates on this new compiler SHA. Latest fully accepted
baseline at preparation remains `a7c6dade87a9d8df74d5248e8276623e7870078c`.
M3+B stays OPEN, approximately 40% qualified (30–50% engineering uncertainty).
PR #109 remains draft/open/unmerged. Preserve the full history below.

## M3+B candidate — P0 assurance identities and retained P1 source strategy (17 October 2026)

This commit is a **new, unqualified compiler checkpoint** on top of live source
`9cf5a9a90e736ab1172bdf7b3107169cedf78ec1`. The latest fully accepted compiler
remains `a7c6dade87a9d8df74d5248e8276623e7870078c` and its five-gate nested
shared-model receipt. The newer P0 candidate's full native run
`38948302333` failed only at the stale expectation that all partial runtime
targets refuse; its focused/F1/F2/F3-F4 gates passed. Do not accept that
candidate from focused evidence alone.

The integration boundary now requires explicit ordinary partial artifacts,
exact targets and nonempty bundles, actual typed body identity, logical
opacity, generic-library refusal, and both verified-grade refusals including
imported dependencies. The native CLI propagates `--assurance` through both
single-source and project requests; saved origins use the returned assurance
identity. Original performance workloads, iteration counts and checksums are
unchanged.

A valid `partial_fixpoint` suffix is retained as its own source declaration
through source lowering and scope resolution. It is no longer misdiagnosed
as a declaration prefix. P1 elaboration remains unavailable under the
unchanged approved assumptions: the required pinned `Lean.Order.fix`
construction uses `CCPO.csup` and `Classical.choice`. An isolated official
Lean oracle inspects actual Unit/Option fixpoints and generated-equation
axiom closures; it is outside the compiler's admitted Standard environment.
No P1 executable, new logical assumption, equation, or verified fallback
is enabled.

Require this checkpoint's **own** native, F1, F2, F3/F4 and focused workflows.
M3+B remains OPEN; approximately 40% qualified (30–50% engineering
uncertainty), not a measured language-conformance percentage. Group-aware
data/elimination, broader total/WF recursion, P0 closure coverage and the
P1 assumption incompatibility remain. PR #109 stays draft/open/unmerged.


## M3+B current candidate: selected P0 ordinary partial body execution (NOT qualified)

A new explicit `PsV7Native.Assurance` request/response distinguishes
`ordinary-checked` from unimplemented verified grades; verified
requests must fail without ordinary downgrade. After the **original**
canonical `partial` logical/core body is kernel-checked, the native
host's selected ordinary path alone pairs opaque public `f` with the
unique separately checked private `f.0` body (matching universes/type)
for runtime erasure, retaining the original logical graph untouched.
Generic library erasure still rejects partial markers. The focused
suite adds an independent pinned-Lean nonrecursive `partial` body
oracle, scalar two-input JS/TS/Rust/GC/Wasmtime runtime observations,
and explicit verified refusal. Detailed candidate contract:
`psc0/docs/PSCV0_M3_PARTIAL_P0_RUNTIME_CANDIDATE_2026-10-17.md`.

**Unqualified until own five exact same-commit gates.** Not general
partial recursion, model/body/target correctness, P1, effects, M4
verified assurance or full M3+B. Pinned v7.2/Lean 4.35.0,
no new assumptions, pskernel-core or selfhosting.

## Accepted common nested container ownership — 17 October 2026

Exact implementation `a7c6dade87a9d8df74d5248e8276623e7870078c` passed all five same-commit workflows:
native `38946629082` (33/33), F1 `38946629149`, F2 `38946629024`,
F3/F4 `38946629155`, focused `38946629090`.
Read `psc0/docs/PSCV0_M3_NESTED_SHARED_MODEL_QUALIFICATION_2026-10-17.md`.
`Ps.Core.Nested` now owns selected List/Option/Array/Prod field
shapes used by both source-positivity checks and checked canonical
recursor bridging; check-only Option/Prod oracles pass. Actual nested
recursive traversal/mutual/indexed group expansion is not closed.

The next **unqualified** P0 candidate will connect an independently
kernel-checked logical opaque `partial` declaration with its private
actual-body executable view *only for explicitly ordinary-checked builds*.
Verified requests must reject rather than downgrade. Preserve the
current partial blocker in generic compiler library entry points and the
canonical checking stream. This does **not** establish P1, verified
runtime correspondence, M4 effects or full M3+B.

## Accepted Array nested constructor adaptation — current checkpoint

**Compiler `8f217a80a6010b5db83affb5f608d494521b44bf`**: native
`38943289653` (33/33), F1 `38943289504`, F2 `38943289694`,
F3/F4 `38943289454`, focused `38943289601` all **SUCCESS**.
The subsequent test-only source SHA `59fa293d587e83c3c5fe6d9572debb82a385a30a`
passed focused `38943635308` including pinned native Lean oracle,
JS, compiled TS, Rust, V8 GC and Wasmtime for shallow `Array Rose`.
Read `psc0/docs/PSCV0_M3_ARRAY_NESTED_QUALIFICATION_2026-10-17.md`.
This is **not** nested recursion traversal, all-family deriving, P0/P1,
or full M3+B; old candidate-pending paragraphs are historical.
Next architecture priority: one common positive-container shape owner
across `Ps.Elab.Data` and `Ps.Bridge.CheckedAdmissions`, preserving
the exact pinned checked constructor fields and fail-closed boundaries.
M3+B remains OPEN; native portable .lean, no pskernel-core or self-hosting.

## M3 nested parameter validation — qualified; Array bridge candidate pending

Compiler `e3c3f8b6b9b2231b4bf69f4ae37bd2aa234b1cf9`: five exact same-SHA runs SUCCESS — native
`38941232123` (33/33 steps), F1 `38941232184`, F2 `38941232130`,
F3/F4 `38941232155`, focused `38941232165`. Receipt:
`psc0/docs/PSCV0_M3_NESTED_UNIFORM_QUALIFICATION_2026-10-17.md`.
Every nested family occurrence now checks the same Core uniform parameters
as a direct occurrence; nonuniform `BadNested(A)` under `List` refuses
at elaboration. Separate check-only `bde3dccd` and runtime `eb227eb6`
focused runs passed for one zero-parameter `List Rose` shallow
elimination case. This is NOT nested recursive traversal or deriving.

Current new candidate extends the checked nested recursor bridge for
`Array α` using Lean 4.35's exact `List α` backing field, with an
independent check-only `Array Rose` source/oracle. No assumption,
kernel-admission bypass, erasure shortcut or runtime speed claim.
**Candidate requires its own native/F1/F2/F3-F4/focused qualification.**
Current M3+B remains OPEN; continue canonical `psc0/ARCHITECTURE.md`,
v7.2-only .ps, native .lean, minimal tests, no pskernel-core/selfhost.

## Active architecture consolidation — 17 October 2026

`psc0/ARCHITECTURE.md` is now the single active native v7.2 architecture document for current implementation, target mechanisms, later-track non-goals and Lean 4.35 comparison; historical PSC2 text is preserved exactly in `psc0/docs/history/PSC2_MINIMAL_SELFHOST_ARCHITECTURE_SNAPSHOT.md`. Continue the six unchanged M3+B exits from the roadmap, beginning with one group-aware data/recursion validation owner. Source/CI receipts above remain independent; this doc commit makes no implementation or new qualification claim.

## M3+B exact qualification: open Nat.sub strict-child slice accepted (16 October 2026)

**Accepted compiler/test:** `721b97038926db5f34e2da1cf7157c68c18234ff`. All five exact same-commit
runs SUCCESS: native `38931145719` (33/33 steps), F1 `38931145674`,
F2 `38931145639`, F3/F4 `38931145711`, focused `38931145641`.
See `psc0/docs/PSCV0_M3_NAT_SUB_QUALIFICATION_2026-10-16.md`.
The pinned `Nat.sub a 0 ≡ a` conversion is checked for open terms,
with native oracle, source `rfl` equation, two scalar runtime inputs in
JS/TS/Rust/GC/Wasmtime and a phase-correct non-child subtraction refusal.
The previous **candidate pending-native** text remains historical.

**Next in-flight test-only candidate:** `3a2fbdfa` checks ordinary HAdd infix
`k + 0` and refuses `k + 1`; it must pass its own focused workflow
`38933071884` and does not by itself produce a new compiler qualification.
Entire M3+B **remains OPEN** for indexed/nested/mutual data, broad
elimination/well-founded total recursion and selected P0/P1.
No extra logical assumptions, unverified execution, benchmark relaxation or
performance speedup. Continue v7.2 only for .ps, native portable .lean,
GitHub/cloud CI, both handoffs and PR draft/open.

## Latest M3+B candidate: open Nat.sub strict child (not yet fully accepted)

Compiler/test `721b97038926db5f34e2da1cf7157c68c18234ff` implements exact pinned Lean 4.35.0
`Nat.sub a 0 ≡ a` reduction in shared native `Ps.Meta.NatReduce`.
The independent Lean oracle, checked .ps unfolding equation, 15 scalar
exports × 2 inputs across JS/strict TS/Rust/V8 GC/Wasmtime, and a
`Nat.sub(k,1)` non-child refusal now pass the **focused** workflow
[38931145641](https://github.com/dwijayuda/pskernel/actions/runs/38931145641).
Independent F1 [38931145674](https://github.com/dwijayuda/pskernel/actions/runs/38931145674),
F2 [38931145639](https://github.com/dwijayuda/pskernel/actions/runs/38931145639),
F3/F4/platform [38931145711](https://github.com/dwijayuda/pskernel/actions/runs/38931145711)
all SUCCESS on this exact code commit. The full native workflow
[38931145719](https://github.com/dwijayuda/pskernel/actions/runs/38931145719)
was **still IN PROGRESS when this checkpoint was committed**. Re-read its
final result before accepting. No old 4/5 green results establish
full integrated 5/5 success.

Fully accepted previous M3 prefix-recursion compiler `8f8aa47f`, with
five same-commit green workflows and final receipt
`psc0/docs/PSCV0_M3_PREFIX_RECURSION_QUALIFICATION_2026-10-16.md`,
remains the acceptance baseline. M2+A remains complete for original
bounded profile. v7.2 alone is future .ps; native .lean semantics unrestricted.
No source axiom/sorry/new classical assumption, pskernel-core, self-hosting,
unchecked totality, runtime performance-parity or completed M3 claim.

## Accepted M3+B prefix recursion / normalized evolving state — 16 October 2026

**Implementation/test commit `8f8aa47fc3b742488bd1ce4ad15024a63c0b6d4f`: all five same-commit gates
SUCCESS**. Native 38928344482 (job 117065962490: 33/33 steps, none
skipped); F1 38928344465; F2 38928344501; F3/F4/platform 38928344471;
focused 38928344644, including pinned Lean oracle, JavaScript, strict TS,
Rust, V8 GC, Wasmtime. Exact artifacts and digests:
[qualification](docs/PSCV0_M3_PREFIX_RECURSION_QUALIFICATION_2026-10-16.md).
The preceding pending-run and false-negative fixture notes are *history*
superseded by this evidence, not current blockers. PR #109 remains draft/open.

The admitted subset: a computed recursive major after pure unchanged
binder references, justified by read-only Core definitional equality to an
existing strict constructor field and IH; and separately qualified evolving
prefix state using the already checked worker-normalization machinery.
Defining equations, a changed-prefix state execution oracle, and a
nondecreasing *later* major refusal passed. **No general computed
discriminants, nested/mutual recursion, arbitrary decrease, P0 executable
partial or P1 fixedpoint admission is implied. M3+B remains OPEN.**

# PSCV0 — M3 structural strict-child accepted; M3+B continues

## Accepted M3+B structural strict-child slice — 16 October 2026

Selected compiler/test `8e7f18885a3e917fbdf000d7d108842b2cc1f067` passed all five exact same-commit gates:
native 38923349115 (33/33 steps), F1 38923349086, F2 38923349001,
F3/F4/platform 38923349042, focused 38923349138 (JS, compiled TS, Rust, V8 GC, Wasmtime).
See [structural child qualification](docs/PSCV0_M3_STRUCTURAL_CHILD_QUALIFICATION_2026-10-16.md).
It admits first-position computed children only by checked definitional equality
to an existing strict IH field. `Nat.add k 0` canonical conversion succeeds;
infix `k + 0`, non-first computed majors and general arithmetic decreases are
not yet qualified. The nondecreasing-successor negative rejects as intended.
Older pending-candidate notes below are **historical**, not live qualification blockers.
M3+B **remains OPEN** for nested/indexed/mutual data and deriving, more
elimination/motives, broader total recursion, source strategy matrix,
selected P0/P1 obligations, and cross-stage acceptance. Continue v7.2 only,
native portable .lean, pinned 4.35.0, no pskernel-core/self-hosting, no
weakened gates, same prior accepted M2+A and other evidence.

Updated 16 October 2026. **The selected direct-recursive DecidableEq slice is COMPLETE; M3+B remains OPEN.** v7.2 only for forward .ps development, no legacy modes or native .lean grammar restrictions. Reapply the attached user prompt and docs/PSCV0_V72_STAGE_DIRECTIVE_2026-10-16.md before each coherent slice; inspect fresh HEAD/CI/both handoffs/relevant v7.2 clauses/pinned sources.

## Exact accepted compiler

**3fc077fd836e32b0d4250ea7b21183bb06897eab**, tree52d39bde0d280342e4ccadf5ba483ea88e5e2ca3. This handoff is a documentation-only child, not a new compiler qualification.

All FIVE same-commit workflows passed: native38910660953, F1 38910660803, F2 38910660921, F3/F4/platform38910661102, focused recursive deriving38910660969. Native job117005717235 reports all33 steps passed, including setup/cleanup, none skipped. Read docs/PSCV0_M3_RECURSIVE_DECEQ_QUALIFICATION_2026-10-16.md; these final metadata-derived IDs supersede intermediate summaries. Full source/Standard, modules, GC/components, TypeScript/Rust, repeated native Wasmtime/post-return, unchanged measurement and publication passed.

The final fix aligns RecursorLift root eligibility with erasure's raw forall/lambda entry boundary. A function hidden behind a reduced result alias uses existing checked capture-preserving helper lifting. No new class-name special case, call arity, weakened erasure refusal or budget. Existing restoration/alpha-equality/official checking remain. The focused equality fixture includes native Nat/Bool decisions, independence from non-reflexive BEq, scalar-dependent proof fields with recursion, checked equations and exact refusals. This is the selected direct-recursive family, not all recursive/dependent equality.

Historical cc499 invalid oracle proof and2407 erasure failure are preserved in the design/history. Do not restart those repaired candidates or repeat the now-complete five-run gate. The source design and recursor-entry note retain their dated candidate history; the new qualification receipt supersedes their pending state.

## Next implementation

Continue broader M3 data/elimination/recursion mechanisms: nested/indexed/mutual families, motives/pattern matrices, structural/well-founded recursion, strategy ownership and selected P0/P1. No implementation beyond the accepted DecEq baseline is claimed by this handoff. Inspect actual source owners before choosing the next coherent slice; do not infer absence from an old roadmap or enable a guard without full downstream support.

Partial independent inhabitant/public opaque/private actual-body marker remains in the prepared graph. Every shared partial executable admission still fails. Never run the witness, drop the marker, invent body equations/totality, add Classical/Nonempty fallback or downgrade verified requests. P0 execution/assurance and P1 fixedpoints remain open.

## Preserved acceptance, authority and performance

BEq058fb67f accepted native38905476639, F1 38905476304, F2 38905476313, F3/F4/platform38905476451 and focused38905476153. Hashable/Repr4501164e/docsad47b42f and original M2 profile73integration2a707206/acceptance280e1e4e remain accepted with unchanged historical receipts. Never relabel them full v7.2.

v7.2blob694115223777599ba28ee175e14bb642b7b6aa4b/SHA256c65487eccbd2829d1d9e5e1be3bc7f4cb37849b841ab3257ea0dd47665b8a30e. Runtime133af061/paired38840337837/artifact12021226623 retain9.25–10.11xfromList, smaller indexing gains and unresolved deep-list/reversal. No new speedup, production parity or global preservation claim.

## Contract

GitHub/cloud Linux ONLY; no local files/checkouts/shell/build/tests/Desktop Commander. Native portable .lean; official4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc; onlypropext/Quot.sound. No pskernel-core/self-hosting/compiler-source migration/C5/sorry/unchecked admission/weaker gates/larger budgets. GC internally; linear memory explicit ABI. Fresh expected-HEAD/non-force writes, preserve concurrent history, BOTH handoffs each slice. PR109 draft/open/originalbase psc0/pscv0-v7-m1-parser-ownership-v1, never merge. Continue M3+B -> M4+C/D -> M5+E; no fabricated qualification or percentages.


## Candidate: definitionally equal strict-child recursion — qualification pending

A first-position recursive argument may now be inferred and compared by read-only
definitional equality to an existing, checked strict constructor child and IH.
The term is elaborated only once and checked against the dependent child telescope
and invariant arguments; arbitrary arithmetic decreases and computed non-first
majors remain unavailable. The independent pinned Lean oracle and one new
Bool-to-UInt64 observation in each existing target lane await same-commit
native/F1/F2/F3-F4/focused qualification. This does not close M3+B.
The unrelated fixed-discriminant cloud preparation commit 9f15ef1 failed
invariant validation. Its code and logs are preserved as an unqualified
experiment. No erasure gates, assumptions or performance budgets changed.

### M3 structural-child candidate correction — pending qualification
Focused run 38921593998 at 80d0654 built native Lean and the oracle but
rejected the new .ps example at recursive major selection. The shared
NatReduce converter only recognized closed binary arithmetic literals.
Official pinned Init/Prelude.lean defines Nat.add a 0 by reduction on the
second operand. This child patch adds only that exact definitional rule,
not zero-add, arbitrary arithmetic decreasing, a new IH or proof axiom.
The candidate still requires its own exact-commit five-workflow replay.

### Focused explicit-Nat conversion qualification pending
The pinned kernel equation Nat.add a 0 reduces even with open a. The new
computed-child fixture now spells this as Nat.add(k, 0), testing the direct
canonical constant before generalized infix HAdd dictionary normalization.
Previous infix k + 0 tests still fail in the selected PSC0 elaboration path;
do not claim full infix definitional-equivalence parity from this case.
The proof and target observations remain unchanged. Native and focused
qualification on this commit are required for acceptance.

### Fixed structural-child qualification and refusal
Focused run 38922907562 passed on f560a1df, including native oracle and
JavaScript, TypeScript, Rust, GC and Wasmtime for the explicit Nat.add(k, 0)
case. Full same-commit integration replays were not triggered by that fixture-
only child. This new candidate adds the intended-phase refusal for a
nondecreasing successor argument and documents that infix HAdd projections
require separately checked instance unfolding. Exact native/F1/F2/F3-F4
and focused runs on this commit are pending before formal slice acceptance.

## M3+B candidate — computed major after fixed invariant prefix (qualification pending)

Against exact accepted strict-child baseline 8e7f1888 / documentation 1cf46bc5,
shared native `Term.lean` now permits an elaborated computed recursive major
at a non-first explicit parameter position only if **every preceding
argument is the unchanged corresponding local binder reference**. This
prevents reordering any evaluated prefix expression. The prechecked major
is cached with its actual telescope position, reused only once and
revalidated against the selected strict child and dependent invariants.
No new arithmetic heuristic, IH, trust principle or erasure shortcut is added.

One independent pinned-Lean `laterChild(flag, n)` oracle, selected .ps
defining equation and one scalar Bool→UInt64 cross-backend observation are
added to the existing focused suite. A changing prefix `Bool.not(flag)`
must reject at the structural invariant rule in elaboration. Prior
Pos/Neg cases and all original budgets remain intact.

This is a candidate only. Require exact same-commit native, F1, F2,
F3/F4/platform and focused JS/TS/Rust/V8-GC/Wasmtime qualification
before acceptance. Nested/mutual data, dependent motives, well-founded
recursion, P0 ordinary execution, P1 fixedpoints and entire M3+B remain open.

### Focused qualification correction: changing parameters can be total
The focused 38927587017 candidate compiled and accepted the newly written
`badPrefix(flag, n)` negative, because its changed flag is permitted through
the existing checked changing-argument worker normalization; termination
is controlled by the strictly decreasing structural n, not invariant flag.
Therefore this was a *false negative expectation*, not unsound acceptance.
Do **not** outlaw legitimate changing state to satisfy this fixture.
The same focused suite instead checks `badLaterMajor(flag, Nat.succ(k))`
with an unchanged prefix but a nondecreasing recursive major at a later
argument position; that must reject by the same strict-child rule. Actual
typed-elaboration and proof gates remain intact. Qualification pending.

### Candidate positive evidence — evolving prefix state
The prior `badPrefix` refusal was invalid: recursion may change a prefix
state parameter while strictly decreasing a later major through the
existing checked worker-normalization. Focused 38927983884 successfully
qualified the corrected nondecreasing-later-major refusal at 6fe169bf.
This candidate adds `m3flipPrefix(flag,n)`, an independent pinned-Lean
structural proof, one exact Bool→UInt64 observation for each flag across
existing JS/TS/Rust/GC/Wasmtime lanes, and a checked source equation.
It preserves the conservative once-only computed-major prefix path as
a distinct supported case and leaves unsupported dependent/nested/mutual
recursion unchanged. The full five-gate exact-commit acceptance is pending.


## Latest exact CI checkpoint for fixed/evolving-prefix recursion
Compiler/test `8f8aa47fc3b742488bd1ce4ad15024a63c0b6d4f`: F1 **SUCCESS** run 38928344465,
F2 **SUCCESS** run 38928344501, F3/F4/platform **SUCCESS**
run 38928344471, focused **SUCCESS** run 38928344644
(JS, strict TS, Rust, V8 GC, Wasmtime; artifact 12057652697;
SHA256 6810c1bb993307f038cf0ad950e1eb77850a7b1df0d235efdea5d841f3c80c3f).
**Native run 38928344482 was still in progress in Wasmtime embedding when
this snapshot was written**. Recheck its conclusion; do not claim all five
green before it finishes. The candidate is not yet formally accepted.

An independently reviewed next native `Nat.sub a 0` reduction candidate
is prepared as **unattached blobs only**, not source branch changes:
`psc0/packages/meta/src/Ps/Meta/NatReduce.lean` = ce55c61324d6993f50c83c0e58e91108db9fac21,
`psc0/test/Pscv0M3RecursiveDeriving.lean` = 0caefd5276d56f461fa6e39facc4a0477e93947b,
`psc0/scripts/pscv0-m3-recursive-deriving.mjs` = 48e0b456c199dce2c0f6099c2800227a33c83188.
The code is based on pinned Lean 4.35.0 `Init/Prelude.lean`,
whose `Nat.sub a 0` equation is definitional. Do not advance this
unqualified candidate to the main development branch until exact native
qualification of the current recursion compiler has resolved. When
admitting it, build a new tree on fresh HEAD using these blobs, validate
a native oracle and negative `Nat.sub(k,1)` strict-child refusal, and
rerun all five gates. No runtime speedup is claimed.

## New v7.2 M3 total recursion conversion candidate — exact CI pending
This descendant of accepted compiler `8f8aa47f` and docs `88931aa3`
extends the shared, portable `Ps.Meta.NatReduce` conversion with **exact**
open `Nat.sub a 0 ↝ a` (stable Lean 4.35.0 `Init/Prelude.lean`).
It is a definitional right-zero equation, not an arithmetic decreasing
heuristic, and does not admit `Nat.sub k 1` as a structural subterm.

The existing focused independent pinned-Lean oracle and generated application
now exercise `normalizedSubChild`, a checked source unfolding equation and
one additional Bool→UInt64 output per flag in all previously supported lanes.
The new `badSubMajor(Nat.sub(k,1))` negative must reject at the structural
major rule. Existing strict-child, fixed/evolving-prefix, direct-recursive
deriving, benchmark, module, proof, erasure and runtime cases are preserved.
Five exact-commit native/F1/F2/F3-F4/focused workflows are REQUIRED before
admission. No new speedup or entire M3+B closure is claimed.

## Experimental M3 HAdd-infix computed-child conformance (focused qualification pending)

Prior Nat.sub compiler/test `721b97038926db5f34e2da1cf7157c68c18234ff`
still awaits exact native run `38931145719`; the four independent
gate results are green. This **fixture-only** candidate does not modify
compiler code. It tests `k + 0` through checked HAdd Nat instance
resolution against an existing strict-child IH, and a separate `k + 1`
negative that must reject at the structural elaboration rule.
The native Lean 4.35 oracle checks the equation by rfl; one additional
Bool-to-UInt64 source observation is compared on the existing
JS/strict TS/Rust/V8 GC/Wasmtime lanes.

The focused workflow must pass before claiming source infix conformance.
This is not automatic arithmetic termination, general well-founded
recursion, executable partial P0, P1 fixedpoints or full M3+B.
No new axiom, weakened original test or performance claim.

## M3+B candidate: child-typed computed operator majors (qualification pending)

The fixture-only `3a2fbdfa3ec4c63e6134792892b6c1a26028c25e`
failed focused run `38933071884`: `m3infixChild(k + 0)` rejected at
`PSCV0-RECURSION: recursive major must be a direct recursive field`.
Native Lean 4.35.0 accepts the same strict-child expression by definitional
equality. This candidate adds a **shared expected-type hint** for computed
recursive arguments: only when all actual constructor-recursive field types
are read-only definitionally equal is that common checked child type supplied
to the ordinary term elaborator. Varied indexed child types fall back to the
previous inference route. It still chooses an *existing checked IH* only
after exact Core definitional equality; no new termination heuristic or
trust principle is introduced. No source-specific HAdd rewrite or changed
backend semantics. The existing infix `k+0` positive and nondecreasing
`k+1` refusal demand their intended phases in the focused suite.
Five exact same-commit native/F1/F2/F3-F4/focused replays are required.
Full M3+B remains open; old Nat.sub all-five receipt is unaffected.

## In-flight HAdd infix conversion candidate: progress only admitted constraints

Candidate `bdd9cde559a2b9bc457b752c4d0685c9a172615c` built
native Lean, but focused `38933591612` still rejected `m3infixChild(k + 0)`
at the strict recursive child rule after adding a common checked-IH type
hint. The operator elaborator can leave ordinary instance/metavariable
constraints queued under postponement. This correction invokes the
existing `psElabProgressPending` **non-default** queue solver after
elaborating a computed major, then compares its Core term only with
actual strict constructor fields and their checked IHs. It does **not**
run final default-instance selection, force suspended source resolution,
replace the read-only definitional equality criterion, or expand the
logical foundation. The pinned oracle, equation, `k+1` negative and
runtime targets are unchanged. Both full native and focused same-commit
replays are required; this is NOT yet accepted or full M3+B.

## HAdd infix strict-child candidate: WIT export identity correction (qualification pending)

The prior `40b216a09fa20e737cfe2e02d78f28f5e86a4064`
candidate focused run `38934185882` reached native checked source
and passed direct JS, strict compiled TS and locked Rust execution.
Its only focused failure was the new fixture's mixed-case export
`m3infixOutput`: WIT correctly converted it to `m3infix-output`
and the exact unchanged ABI assertion expected the camel-case name.
The new export is now consistently **`m3infixoutput`** across native
oracle JSON, selected PSC source, generated JS/TS/Rust and WIT/GC/
Wasmtime comparison. This corrects fixture ownership, NOT compiler
semantics, and does NOT relax or remove the ABI assertion.
The computed-major synthetic-constraint queue is skipped when
empty; when work exists, it still uses the original non-default
`psElabProgressPending` solver before strict-child/IH validation.
Previously accepted Nat.sub and prefix-recursion receipts are intact.
Five exact-commit native/F1/F2/F3-F4/focused gates must all pass.
Overall M3+B remains OPEN; no self-hosting or pskernel-core.

## Next M3+B pattern-matrix qualification — two discriminants (focused only pending)

The current checked HAdd computed-major compiler `33c569e0` has
F1/F2/F3-F4 and focused green on its own SHA while its full native
workflow `38934640403` is in progress. Preserve this qualification
boundary. This **test-only descendant** adds one independent pinned
Lean 4.35.0 `Bool × Nat` multi-discriminant match oracle, selected
PSCV0 `m3matrixSelect` with native checked equation, and one
Bool→UInt64 observation for each input across existing
JS/TS/Rust/V8 GC/Wasmtime lanes. A deliberately nonexhaustive
two-column function must be refused at `PSCV0-MATCH: missing feasible
constructor branch` during elaboration. It reuses existing common
`Ps.Elab.PatternMatrix`/typed eliminator; no compiler implementation
is changed or positive result claimed before the focused run.
If the probe fails, fix the actual typed motive/pattern owner without
accepting erroneous branches or weakening refusal. M3+B remains OPEN.

## Next M3+B code candidate — uniform parameters through positive nested containers

At compiler HEAD, `Ps.Elab.Data` previously validated uniform parameters
on direct recursive fields only; its nested List/Option/Array/Prod acceptance
walker could encounter the same family with changed parameters without
applying `psElabDataIndices`. This change replaces that permissive boolean
walker with one bounded, common checked-occurrence validator. It reuses the
same universe/family/parameter telescope check for **every nested recursive
occurrence**, including both sides of `Prod`. Nonrecursive fields remain
unchanged. Indexed nested cases and unsupported variance still reject;
no nested IH, positivity axiom, new recursor, or new runtime capability is
invented. Official Lean 4.35 kernel checking remains authoritative.

The existing nested-family `deriving Hashable` refusal already traverses
a positively nested family, and its phase/rule are unchanged; one additional
deliberately nonuniform nested family must reject at the precise
`constructor parameters must remain uniform` elaboration rule. Minimal
focused CI and all native/F1/F2/F3-F4 gates are required before accepting
this bounded validation improvement. It is NOT complete general
mutual/nested recursion, deriving, M3+B, P0 or P1.

## Focused M3+B probe: check-only nested one-family elimination

After the preceding native `.lean` nested uniform-parameter validator
candidate, the inspected canonical admission bridge showed a bounded,
zero-parameter/zero-index nested adapter (`psCheckedNestedWrapper`) for
List/Option/Prod, distinct from the portable recursive deriving machinery.
This test-only child asks the **existing official native host** to check a
zero-parameter, strictly positive two-constructor `Rose` with a
`List Rose` field and a shallow `match`; the independently checked
pinned Lean oracle constructs an equivalent family and equation.
No target artifacts are requested: passing establishes only logical
inductive/recursor admission, not executable nested recursion/IR/ABI.
The initial actual recursive deriving/target runtime fixture and every
earlier exact-phase negative remain unchanged, with only a positive
batch request and its indexing added. Native kernel rejects imply
the bridge or recursor requires architectural work, never a gate bypass.
Full M3+B remains open; nested indexed/mutual groups, runtime/deriving,
P0/P1 and verified target behavior are not claimed.

## M3 bounded nested family runtime probe — qualification pending

The check-only `M3NestedRose` / `List M3NestedRose` source plus
shallow constructor match passed the focused kernel replay on
`bde3dccd` (run `38941701921`). This next fixture-only child
adds the same strictly positive no-parameter family to the existing
compiled multi-target source and exports `m3nestedoutput`, comparing
`leaf` and `node(List.nil)` against the independent pinned Lean
4.35.0 oracle for both Bool inputs. It tests Core admission, typed
erasure, IR checks, JS/strict TS/Rust/V8-GC/Wasmtime without adding
backend-specific recursion shortcuts. The bound is *one-level shallow
elimination over a nested field*, NOT general nested recursive functions,
nested deriving, indexed/mutual types, P0 or P1.
Original negatives and other runtime observations are unchanged.
If the existing erasure/runtime refuses, inspect the actual shared
runtime representation and report the unsupported boundary instead of
loosening an unrelated checker.

## Candidate: Array-nested shallow runtime (focused-only test, pending)

Following the successful check-only `Array Rose` admission on
`8f217a80` focused run `38943289601`, this **test-only** child
adds the same monomorphic `M3NestedArrayRose` to the existing selected
executable source and one `Bool → UInt64` observation:
`m3nestedarrayoutput`. For false it constructs `node(#[])`,
for true it constructs `leaf`. An independent pinned Lean oracle
computes both results; existing JS, strict TS, Rust, V8 GC core and
Wasmtime exact-output scripts check the new export without widening
ABI or weakening original assertions. A fully qualified check-only
inductive does not automatically mean its backend representation is
safe; any failure must be traced through shared erasure and IR instead
of inventing a backend value. This is shallow elimination, **not**
nested recursive traversal/deriving or the complete M3+B exit.

## M3+B candidate: one selected nested-container model (qualification pending)

New portable native `Ps.Core.Nested` is the sole owner of the
pinned Lean 4.35.0 List/Option/Array/Prod constructor-field shapes
and positive nested child positions. `Ps.Elab.Data` and the canonical
`Ps.Bridge.CheckedAdmissions` adapter now consume this same view,
rather than independently recognizing or encoding the containers.
The elaborator still checks uniform family parameters for each
occurrence and the official kernel checks all generated declarations.
No new constructor shape, induction hypothesis, axiom, recursion
strategy, erasure privilege, target ABI or benchmark budget was added.

The existing focused native-oracle and five-target fixture still tests
the accepted shallow List/Array runtime work. Two small, separately
check-only Option/Prod family requests and corresponding pinned-Lean
equations exercise previously untested bridge shapes, while all
existing phase-specific negatives and outputs remain unchanged.
Selected nested *shallow* checking is not nested recursive
traversal, deriving, indexed/mutual group support, P0/P1 or M3 exit.
Full native/F1/F2/F3-F4/focused same-commit gates are required
before acceptance. Preserve older qualified receipts and PR #109.

## Candidate: actual recursively calling partial runtime body — focused qualification pending

Original selected P0 ordinary host candidate `e6a14c86b11ee50570554ae75d371628d3759e0b`
passed focused/native Lean oracle/JS/strict TS/Rust/GC/Wasmtime
`38948302365` and F1/F2/F3-F4 on the exact code SHA. Full
native `38948302333` is still in progress; **not yet all-five accepted**.
This *test-only* descendant keeps the same compiler implementation
and adds pinned Lean `partialCount(n)` with a real recursive call on
a strict Nat predecessor, and source `partial function
m3partialCount(n)` plus two `Bool → UInt64` output observations.
Unlike the earlier nonrecursive partial body, this directly exercises
public source self-calls being bound to the actual executable body,
not the independent logical inhabitant. The logical declaration
remains opaque, no defining equation is admitted as proof, and the
explicit verified request still fails without ordinary downgrade.

Focus uses unchanged selected JS, TS, Rust, V8 GC and Wasmtime
paths and all previous phase-specific failures/budgets. The new
case validates only these bounded finite runs, not arbitrary
termination, diverging behavior, trace safety, partial_fixpoint P1,
model/body/target refinement, or full M3+B. Require its own focused
qualification before counting it; do not relabel the older native
run as belonging to this test-only descendant.

## Test-only next M3 data slice: shallow Option/Prod target representation

After accepted shared List/Option/Array/Prod `Ps.Core.Nested`
shape ownership and successful check-only Option/Prod family fixtures,
this child adds actual `Option.none` and `Prod.mk` nested
constructor values under a monomorphic self-family, then a shallow
checked match and two `Bool → UInt64` observations for each target.
Both outputs are compared against independent pinned Lean 4.35
`M3NestedOptionRose`/`M3NestedProdRose` oracles through existing
JS/strict TS/Rust/V8 GC/Wasmtime checkers, retaining prior scalar
observations, ABI and all phase-specific negatives.

This is source/IR/runtime evidence for shallow constructors, NOT
nested recursive traversal/deriving, parameterized indexed/mutual
groups, general effect/partial trace/refinement semantics or full
M3+B. The earlier P0 ordinary partial compiler `e6a14c86`
continues its own native qualification; focused recursive P0
`77f5fe75` passed independently. This test-only descendant
requires its own focused qualification and does not inherit the
earlier full native result. No new compiler semantic implementation,
kernel, assumptions, backend special cases or performance budget.

