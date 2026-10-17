## M3+B current architecture checkpoint — precise nested recursor failure trace

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

### Complete nested recursor failure evidence

Compiler/test `77d8578984e7a640c3c1d922cd90e9341466027e` passed
native [38986515634](https://github.com/dwijayuda/pskernel/actions/runs/38986515634)
(job 117259146722, all 34 reported steps), F1
[38986515562](https://github.com/dwijayuda/pskernel/actions/runs/38986515562),
F2 [38986515545](https://github.com/dwijayuda/pskernel/actions/runs/38986515545)
and F3/F4 [38986515520](https://github.com/dwijayuda/pskernel/actions/runs/38986515520).
Native artifact 12082764468 contains 6,796,399 bytes, SHA-256
`c0c2e3840f5f25ebea93c70600339324b6c3f4032ae02352b6f86250bbe55c6e`.
The complete original native workloads, repeated components and measurements
remain passing.

Focused [38986515599](https://github.com/dwijayuda/pskernel/actions/runs/38986515599)
(job 117259146484) now passes GroupProof with its original two two-member
worker groups and three-capture invariant. Where also remains passing.
The sole remaining source fixture failure is
`derive M3NestedDisplay.Repr: PSCV0-ELABORATION: application argument type mismatch (in Prod.mk) (in M3NestedDisplay.rec_4)`.
Target execution was skipped, so this is still not five-gate acceptance.

The reported rec_4 is the outer `Prod Display (Prod Branch Display)`
specialization. Both fields use actual checked IHs: the left returns
`Nat -> Format`, and the right is the inner tuple accumulator
`List Format -> List Format`. This minor does not use a separately
synthesized tuple dictionary. Static inspection has not established a
semantic correction. The actual failed check must determine the repair.

An optional identity-default diagnostic callback now carries the existing
failed check's stage, actual context, expected type, generated term and
already inferred type when available. It distinguishes cursor opening,
argument construction, specialized constructor-value inference, closed
argument inference and argument-type unification. The normal public handler
retains identity behavior. Only the existing fixture's replay of an already
failed Repr member installs the diagnostic callback. Its bounded renderer
and first-failing-application walk delegate to the existing Core inference,
sort/forall, local-scope and definitional-equality owners. They print actual
function/argument/expected/actual types and local IDs, and never manufacture
a term, change the acceptance result or run on a successful derivation.

This checkpoint changes three elaborator modules and that failure replay,
plus both handoffs, architecture and roadmap. The successful generated
terms, check order, native oracles, source requests, outputs, exports,
budgets, pins and all logical/runtime policies are unchanged. Continue from
the next cloud failure payload, repair its actual owner, then qualify all
five gates at one compiler/test SHA before accepting the accumulated slice.

The reviewed WF foundation/relation/empty-dictionary and omitted-result
candidates remain staged. The indexed-dependent-case fixture has been
corrected against the actual prepared representation: two mutual worker
groups plus a separately typed singleton Vec helper, with all previous
positive source/equation/output evidence preserved. Dependent unary packet
construction and exact curried-adapter cancellation now have a frozen draft
and independent native fixture pending review; indexed constructor-directed
Inhabited is being implemented in isolation. None adds accepted percentage.

### Right-case induction scope and generated-argument diagnostics

Compiler/test `bfede05f9e6e8f4444b5d0539b59b74e9acd23cf` passed
native [38985507691](https://github.com/dwijayuda/pskernel/actions/runs/38985507691)
(job 117255929670, all 34 reported steps), F1
[38985507686](https://github.com/dwijayuda/pskernel/actions/runs/38985507686),
F2 [38985507695](https://github.com/dwijayuda/pskernel/actions/runs/38985507695)
and F3/F4 [38985507705](https://github.com/dwijayuda/pskernel/actions/runs/38985507705).
Native artifact 12083525971 contains 6,795,650 bytes; its archive SHA-256 is
`e80b981ba2734b2d0a7c227184cf7e2df4ff5228d5b3f02bc4652350436d5bfb`.
This includes the original source/Standard, module, GC/component,
TypeScript, Rust, repeated Wasmtime and measurement gates. The prior
`6a8bc71c` native run 38984039232 also completed all 34 steps successfully.

Focused [38985507703](https://github.com/dwijayuda/pskernel/actions/runs/38985507703)
(job 117255929507) compiled all fixtures and passed Where's complete source,
capture/SCC, local-WF and emission checks. It then reported
`derive M3NestedDisplay.Repr: PSCV0-ELABORATION: application argument type mismatch`
and the unchanged GroupProof left-IH worker invariant. Target execution
was skipped. Four passing gates therefore do not accept this compiler.

The concrete GroupProof cause is unused right-side induction hypotheses
remaining in the context consumed by equality substitution. Self-recursive
right IH types mention the right child; dependency reopening consequently
reapplies those unused IHs inside the proof, making recursor lifting retain
extra workers. The right-case callback now removes only the actual right-IH
local IDs from its proof-construction context. Their complete real lambda
binders remain in the enclosing checked minor. All left IHs, actual fields,
family parameters and checked target remain unchanged. The removed IHs
were opened after the fields/captures and cannot be dependencies of those
earlier declarations. No recursion, erasure or worker-count policy changes.
The fixture still requires exactly two two-member worker groups with three
captures, and reports actual worker/recursor identities on failure.

The nested Repr cause is not yet established. The shared actual-recursor
argument walker now accepts an optional error decorator, defaulting to
identity; it decorates only its existing ensure-forall, generation, inference
and unification failures. Deriving supplies the actual slot recursor and,
for minors, the actual constructor identity. Final method checking retains
the selected recursor context. The successful checked terms, processing
order and inferences are identical; the next cloud log must identify the
failing argument before a semantic correction is selected.

This coherent checkpoint changes three elaborator modules, one diagnostic
fixture and the four handoff/architecture/roadmap records. No expected value,
source fixture, request count, output/export, budget, pin, Core/kernel policy
or backend behavior is changed. Qualify all five gates at one exact new
compiler/test SHA. The accepted baseline and weighted estimate above remain
unchanged. Reviewed WF foundation/relation/empty-dictionary, omitted-result
inference and indexed dependent-case candidates remain separate unqualified
work; dependent unary argument packing is being prepared in isolation.

### Source qualification repair and precise failure context

Compiler/test `6a8bc71c4916fe753e1c8c20a739428df725b757` compiled all
focused fixtures and passed the first ten independent source checks,
including the repaired native guards and complete PreDefinitions checks.
F1 [38984039237](https://github.com/dwijayuda/pskernel/actions/runs/38984039237),
F2 [38984039188](https://github.com/dwijayuda/pskernel/actions/runs/38984039188)
and F3/F4 [38984039301](https://github.com/dwijayuda/pskernel/actions/runs/38984039301)
passed. Focused [38984039160](https://github.com/dwijayuda/pskernel/actions/runs/38984039160)
(job 117251226237) then reported three elaboration failures. Target lanes
were skipped, so the accumulated source/deriving candidate remains unqualified.

- Where's generic local-body fixture used bare `default`; the selected
  Standard registers the actual method `Inhabited.default`. The portable
  source now names that method. The independent native `default` oracle,
  actual local dictionary, all-kind captures, seven requests, six exports
  and sixteen local-origin assertions are unchanged.
- The two generic required-default equations omitted every explicit use of
  their section type parameters. Source scope consequently retained neither
  A/B nor the dependent `Inhabited A` dictionary. Named `A := A, B := B`
  arguments now state the intended generic equations. Their native witnesses,
  actual dictionary requirements, kernel checks and output values remain.
- NestedDeriving returned only `application argument type mismatch`.
  No semantic correction is claimed for that error yet. Failure-only context
  now identifies the public family/handler, actual source command/name/byte
  span, registration, slot plan or checked pipeline stage. Successful calls,
  source text, complete native strings, comparison-order checks, six exports
  and all expected values are unchanged. The next cloud log must identify
  the failing owner before a production repair is selected.

Native [38984039232](https://github.com/dwijayuda/pskernel/actions/runs/38984039232)
(job 117251226673) had passed source/Standard, modules, GC/components,
compiled TypeScript and locked Rust, and was running the repeated Wasmtime
embedding at the last pre-commit observation. It is not an acceptance
receipt. All five required gates must pass at one exact compiler/test SHA.

The reviewed WF asset/relation/empty-dictionary and omitted-result/dependent
case drafts remain separate unqualified work. This commit changes only the
three focused fixtures and the four handoff/architecture/roadmap records.
Production semantics, original workloads, budgets and pins are unchanged.

### Native oracle qualification correction

At compiler/test `cfe86ea64da3d34683974e09bf4cda76861f2e54`, F1
38982453387, F2 38982453388 and F3/F4 38982453392 passed.
Focused 38982453396 (job 117246201593) failed while building two native
oracles. Production modules compiled, including the current recursion
and deriving owners; focused source and target execution had not started.

The Where rejection must include Lean's full diagnostic prefix:
"invalid mutually recursive definitions, cannot mix partial and non-partial
definitions". The isolated correction changes only that native guard text.

The PreDefinitions cyclic Nat / Type-u component was incorrectly described
as a native positive. Pinned PreDefinition.Main partitions SCCs first
(lines 296–324), then Basic.checkCodomainsLevel (309–322) rejects differing
actual result universes in a recursive total component. The fixture now
asserts that actual native refusal and removes the two impossible native
rfl witnesses. Its disconnected same-signature functions remain the positive
control. The entire portable namespace is unchanged, including the existing
PSCV0-MUTUAL-TOTAL-SORT refusal and all requests, values and atomicity checks.
No source-wide universe gate or production change is introduced by this repair.

Native Linux 38982453386 (job 117246201628) finished SUCCESS with all
34 reported steps, including checked source/Standard, real three-module
emission, GC/components, strict compiled TypeScript, locked Rust, repeated
Wasmtime embedding and the original measurement step. The tip therefore
has four successful gates and one failed focused gate; it is not accepted.
Its native artifact 12082645231 is 6,796,096 bytes, SHA256
`d88c29d724d209ba5faa608009599e11cda4675112b7ec89780e1b7b4be27727`.
All five gates must pass at one exact compiler/test SHA after these fixture
corrections.

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

## M3+B earlier architecture checkpoint — proof/default deriving over complete groups and WF foundation authoring

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

## M3+B earlier architecture checkpoint — complete nested deriving over typed source components

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

## M3+B earlier architecture checkpoint — typed source components and local ownership

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

## M3+B earlier architecture checkpoint — complete nested elimination slots

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

## M3+B earlier checkpoint: accepted group deriving; checked recursion expansion

The accepted compiler/test is `01d762eb02eab1d2f795e5338cb3586cd1d1ace0`; all five gates passed.
The [group-deriving receipt](docs/PSCV0_M3_GROUP_DERIVING_QUALIFICATION_2026-10-17.md)
records exact runs, artifact digests and selected scope. The complete
group motive/minor owner now serves direct indexed Hashable/Repr and
nonindexed BEq. Actual child-family/index checking and the shared ordered
recursive-field rule protect elaboration, reduction and canonical transport.

The following recursion construction is implemented and requires its own
exact-SHA five-gate qualification before acceptance.

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

Remaining shared dependencies include nested specialization motives/traversal,
expanded dependent deriving, flat local where capture/strategy ownership,
compatible SCC dispatch and broader selected structural/WF construction.
Default source mutual/nested induction retains the pinned default refusal;
the .ps mutual grammar remains def/function-only. P1 is blocked by the exact
Classical.choice closure of pinned Lean.Order.fix/CCPO.csup and its equations.
Only propext and Quot.sound remain approved. M3+B stays OPEN.

The following dated sections retain earlier implementation history.

## M3+B earlier candidate: source mutual P0 and typed measured-state recursion

The selected def/function mutual command has one ordered source owner.
`Ps.Elab.Mutual` constructs independent real opaque headers before any P0
body, closes block-wide section/universe captures and uses typed local peer
aliases for the complete captured telescope. Every private actual body is
rechecked after alias substitution. Ordinary runtime selection reuses the
existing checked opaque/body pairing. Per-member and whole-group provenance
survive through all target artifacts and CLI origin JSON. The source grammar
does not add mutual inductive declarations; total/mutual-WF construction and
P1's assumption blocker retain explicit refusals.

`Ps.Elab.RecursionParameters` owns typed fixed/evolving parameter analysis.
The selected Nat-measure path now supports one changing measured Nat plus
independent evolving Nat state and fixed Nat captures, in any header order.
Its real Nat.fix motive returns the state function. Ordered checked Core
lets preserve source argument evaluation; checked extensionality and
congruence derive the public equation without extending conversion.
`Ps.Erasure.WellFounded` revalidates the actual closed definition and entry
arguments, then uses ordinary typed self-call erasure for its callback.

New independent native/source fixtures exercise these constructions and the
existing five runtime targets. Prior `34f43e6b` passed focused/F1/F2/F3-F4 but
native source qualification found a refusal-diagnostic regression; it is not
accepted. This compiler candidate needs all five gates on its own exact SHA.
The accepted baseline remains `a7c6dade`; M3+B and all remaining boundaries
in the six-exit roadmap stay open. See both handoffs for exact evidence.
The dated candidate sections below are historical checkpoints.

## M3+B earlier source group cases candidate

Source matching now specializes the actual complete group recursor through
`Ps.Elab.GroupElimination`: one inferred/unified argument cursor, selected
family motive, checked PUnit companion motives/minors, and the real ordered
constructor telescope. Dependent indices, major/context refinement, and
case-only runtime suffixes reuse their existing owners. Group IHs are hidden
from source case branches; full group induction and cross-family structural
calls remain explicitly unavailable. No new group syntax or trust authority
is introduced. The source fixture compares fresh kernel equations and scalar
observations across five targets; this candidate still requires all five
gates on one exact SHA.

The underlying group-runtime and one-Nat well-founded fixtures passed all
focused targets at `5c8bc97280098ad768b6de5ab9283624f97e5149`, run
`38961009875`. Production/F-gate evidence on its predecessor is mixed-SHA;
the latest fully accepted compiler remains `a7c6dade`. Both handoffs retain
exact lineage. Deriving, broader nested traversal, broader total/mutual
strategies and P1's Classical.choice policy blocker remain open.

## M3+B earlier candidate: typed group execution and Nat-measure recursion

The current compiler candidate adds exact checked companion workers for
complete direct-recursive inductive groups and a selected Nat-measure
well-founded source/Core/runtime path. Both require the new checkpoint's own
five gates. The latest fully accepted compiler at preparation remains
`a7c6dade87a9d8df74d5248e8276623e7870078c`; source Match/deriving and broader
nested/total/mutual strategies remain open. P1 is unavailable under the
unchanged two-assumption policy. See both handoffs for exact CI lineage.
The dated candidate sections below are historical checkpoints.

## M3+B earlier candidate: selected P0 ordinary partial body execution

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


# PSC0 native v7.2 — current, target, and later architecture

**Status:** Active architecture authority for the native PSC0/PSCV0 compiler on branch `psc0/pscv0-v7-native-lean-v1`. **This is a design and implementation contract, not a completed-language or verified-backend claim.** Updated 17 October 2026.

The earlier PSC2 self-host bootstrap plan formerly stored at this path is retained [verbatim as history](docs/history/PSC2_MINIMAL_SELFHOST_ARCHITECTURE_SNAPSHOT.md). It is **not** the current M3+B execution plan. The older [npm/kernel-centered architecture](docs/PSC0_SOUNDNESS_SECURE_EXTENSIBLE_ARCHITECTURE.md), [native redesign research](docs/PSCV0_NATIVE_LEAN_GRADE_ARCHITECTURE_REDESIGN_V1.md), and [direct-backend research](docs/PSCV0_DIRECT_JS_WASM_ARCHITECTURE.md) remain useful research/long-term perspectives, but do not override the active roadmap or source.

## 1. Authority and invariant ownership

1. Normative `.ps` behavior: [PSCV0 language reference v7.2](PSCV0_LANGUAGE_REFERENCE_v7.2.md), source blob `694115223777599ba28ee175e14bb642b7b6aa4b`; no v7/v7.1 compatibility mode. Ordinary `.lean` retains the normal Lean grammar and is not restricted by the selected `.ps` profile.
2. Operational stage/acceptance boundaries: [v7.2 directive](docs/PSCV0_V72_STAGE_DIRECTIVE_2026-10-16.md) and [current milestone roadmap](docs/PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md). Exact CI/source receipts and executable code supersede dated pending text.
3. Pin: official Lean **4.35.0**, commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. Study matching official source **and tests** before extending semantic algorithms. Adapt selected algorithms without copying Lean's entire elaborator.
4. During M3+B use **native portable `.lean` compiler sources and cloud Linux/GitHub CI**. No `pskernel-core`, independent kernel, self-host/bootstrap migration, Desktop Commander, local code execution or C5 release work. Preserve PR #109 (draft/open/original base) and existing qualified work.
5. **One owner per invariant:** parser owns syntax; elaborator owns source semantics and computed proof terms; official Lean kernel owns logical acceptance; erasure owns runtime relevance; typed IR validation owns representability; host owns admission/assurance and file publication; backend owns only target-specific implementation choices. A backend must never manufacture proof authority.

## 2. Implemented pipeline (not the same as end-state)

```text
.ps bytes, source identities, selected Standard and import closure
 → Ps.Syntax.Pscv0 (tokens, source owners, scoped declarations, patterns)
 → Ps.Elab.Scope / Command, Ps.Meta (resolution, inference, constraints)
 → prepared Ps.Core declarations + origin graph
 → canonical Ps.Bridge.CheckAdmissions serialization
 → official Lean 4.35 kernel replay in Ps.Host.NativeV7
 → same retained prepared declarations (never a replacement JSON token)
 → Ps.Erasure typed binder/field/index/recursor lowering
 → Ps.CompilerIr.Model + CheckTypes/Check + specialization
 → target-neutral checked module, then per-target capability checks
    ├─ Ps.BackendEcma shared plan → JavaScript + TypeScript
    ├─ Ps.BackendRust layout, captures and runtime
    └─ Ps.BackendWasm typed GC core + WIT/Canonical ABI component
 → Ps.Codegen provenance, source map, artifact bundle + host publication
```

**Actual source anchors:** `packages/{syntax,environment,core,meta,elab,bridge,erasure,compiler-ir,compiler,backend-ecma,backend-ts,backend-rust,backend-wasm,codegen}/src`, `host/src/Ps/Host/NativeV7.lean`, `packages/pskernel-lean/provider`, and `v7-native/lakefile.lean`. The host compiles with the official Lean kernel and a pinned selected prelude, not the independent PSKernel project.

**Current proven-by-CI boundary:** selected source and modules are accepted by official Lean; typed erasure and IR validation reject unsupported forms; published JS/TS/Rust/Wasm scalar and bounded recursive programs have differential oracles. This **does not prove** the elaborator's interpretation of every `.ps` source, the semantics of all primitives, general backend preservation, or complete v7.2 conformance. Never call a diagnostic receipt, serialized check result, or raw `PsVerifiedIrModule` a user-mintable verification capability.

**Selected already implemented:** scopes/public-private module interfaces, dependency ordering, scoped tabled typeclass solver with answer replay, selected dependent/indexed data and match matrices, checked direct-recursive deriving, structural recursion and checked Core definitional equality, explicit runtime type/proof/index erasure, IR validation, multi-target emission and measured runtime baselines. Current candidates add explicit ordinary P0 body/assurance identity, native atomic inductive-group formation/reduction, typed group companion workers, source group cases and checked Nat-measure recursion; acceptance requires each candidate's own five gates. **Not fully implemented:** broader nested matching, group induction and deriving consumers, full well-founded/strategy matrix, general P0 closure coverage, P1 fixedpoints, M4 effects/contracts/verified evidence, complete incremental tooling/optimization.

## 3. Target shared semantic architecture — no alternative proof kernel

### 3.1 A single, group-aware inductive and recursion owner (M3+B)

`Ps.Core.InductiveGroup` now owns an ordered group plan: family order determines motive order, and each family's constructor order determines its segment of the common minor telescope. Existing retained recursor metadata owns explicit group membership. `Ps.Elab.Data.psElabInductiveGroup` stages common headers and constructors, builds all motives before all minors, and reuses the same path for singleton declarations. `Ps.Bridge.CheckedAdmissions` checks unique related records and serializes one atomic official inductive batch. `Ps.Meta.Iota` consumes the same ordered plan for global minor offsets and cross-family recursive hypotheses, preserving common arguments and each family's own indices. Independent kernel equations and portable reduction comparisons qualify this candidate separately from source and runtime consumers. Constructor-only singleton compatibility retains no claim of explicit mutual membership.

`Ps.Meta.Recursor` exposes the complete group application while retaining the strict singleton API. `Ps.Compiler.RecursorLift` constructs one ordinary checked worker per family, sharing captured locals and the common recursor prefix. Names and capture count locate those workers; before typed erasure, their complete equations, captures, levels, group order and runtime identities are revalidated. Each recursive field dispatches through its actual family worker with that family's indices and return type using ordinary call erasure. These records are not admission evidence. No backend-specific mutual-fold semantics are introduced.

The shared owner and its remaining consumer obligations are:

- **Header plan:** collect every family's name, shared parameters, universe information and indices before checking any constructor. For mutually recursive groups use one consistent parameter context and a dependency graph, not sequential axioms falsely presented as checked declarations.
- **Constructor plan:** elaborate in the group environment; validate type, universe, unchanged uniform parameters, indices and strict positivity for **every occurrence**, including nested containers and nonrecursive-looking dependent fields. Track provenance and fields in the actual source telescope.
- **Recursor plan:** construct the full motive/minor telescope, actual recursive hypotheses and elimination universe rules for the group. Kernel-check the generated recursors and family declarations. Never create an unchecked IH, assume an impossible branch or use a fabricated equation.
- **Match/deriving consumer:** `Ps.Elab.PatternMatrix`, `Match`, and the five deriving handlers must use the **same checked group/recursor plan**. Nested/indexed/mutual cases are enabled only when that plan and all dependent erasure/runtime owners are ready. Preserve unsupported cases as truthful fail-closed refusals.

Official comparison: pinned `Lean/Elab/MutualInductive.lean` stages group headers, constructors, universe checking, kernel admission and finalization. Pinned `Lean/Elab/PreDefinition/Structural/*` separately validates decreasing arguments against actual recursive hypotheses. Adapt these algorithms to the narrower selected language; **do not** add a source-name whitelist or build a second kernel.

### 3.2 One explicit recursion-strategy/partial-body representation (M3 → M4)

Represent total structural, total well-founded, ordinary `partial`, fixedpoint and restricted `unsafe` as **distinct source strategies**, keeping declaration and suffix ownership separate from executable admission. The parser and scope retain a valid `partial_fixpoint` suffix as `fixedpointDefinition`; the elaborator refuses it at the exact assumption boundary. Pinned `Lean.Order.fix` uses `CCPO.csup`, which uses `Classical.choice`, including for existing Unit/Option CCPO instances; `fix_eq` and actual generated equations carry that dependency. The independent oracle records this blocker outside the admitted compiler Standard.

Source `partial` creates (a) a public logically opaque, independently inhabited declaration and (b) a private typed actual-body marker. After official checking of the original graph, the native host's explicit ordinary path pairs their matching types/universes and selects the actual body for runtime erasure. It retains the original logical graph and admits no defining equation for the opaque function. Generic library erasure still rejects markers. Single-source and project CLI requests carry assurance, and published origins take the returned assurance. These selected P0 candidates require exact integration qualification; general closure behavior remains open. Verified partial behavior still requires a checked operational model and source/body/target refinement.

`Ps.Elab.GroupElimination` owns the typed complete recursor-argument cursor shared by singleton and group source matching. The selected family keeps its complete dependent motive; companion families use actual checked PUnit at that result universe. All real minor binders close in retained order, while case-only group branches hide IHs. The existing dependent-context/equality and typed runtime suffix owners remain authoritative. Full induction requires a complete family of substantive motives and is still refused.

`Ps.Syntax` retains total `termination_by` and optional `decreasing_by by { ... }` as a `wellFoundedDefinition`, including scope and spans. `Ps.Elab.RecursionParameters` observes typed calls and closes parameter dependencies; fixed arguments must remain reducibly equal in each call's actual scope. The selected `Ps.Elab.WellFounded` construction has explicit Nat header parameters, one changing measure dependency, independent evolving Nat state and a Nat result. Its actual `WellFounded.Nat.fix` motive returns the state function. Checked Core lets preserve original argument evaluation order. Each recursive call has a scoped synthetic-opaque decrease goal; one tactic sequence runs over their creation order. The definition and `.eq_def` form one source-owned batch; real `fix_eq`, `funext` and congruence prove the equation with calls to public `f`, without extending conversion. `Ps.Erasure.WellFounded` revalidates the exact retained root definition and entry telescope, reconstructs a typed proof-restricted self-callback in original argument order, and delegates to the ordinary eraser. General dependent domains/results, several changing measured arguments, mutual cliques and general open-match equation normalization remain explicit work.

`Ps.Syntax.Pscv0.ProgramRead` retains a def/function-only `mutual ... end` command with ordered source members. `Ps.Elab.Mutual` owns compatible P0 group construction: block-wide captured section variables and common universe closure, independently inhabited real opaque headers before any body, complete typed peer aliases, and final alias-free implementation checking. `Ps.Elab.Command` owns the atomic scope update, visibility and exact member/group provenance. The host carries that provenance to every target artifact and CLI origin JSON. Total mutual and mutual well-founded recursion require separate checked constructions; neither inherits the P0 runtime interpretation.

Exactly one approved logical basis (current policy `propext`, `Quot.sound`), with explicit primitive and foreign-runtime trust ledger; any additional permitted assumptions require an explicit future policy decision. Succeeding at type checking must not silently change an explicit verified request to ordinary output.

### 3.3 Typed runtime relevance, stage invariants and optimization (M3–M5)

Use a single checked binder telescope for `runtimeValue`, runtime-reifiable types, erased dependent indices/type formers, and erased proofs, with source-position mappings shared by declaration/call/constructor/recursor/closure/projection. A computationally relevant erased value is an error. `PsVerifiedIrType.unknown` is diagnostic only and prohibited from accepted executable IR. Prevent typed runtime transformations from discarding overflow, failure/exception, cancellation, nontermination, order of evaluation, or persistent-data semantics.

Current `Ps.CompilerIr.Model` is an expression IR; it is **not** yet Lean's mature phase-separated LCNF/ANF pass architecture. Introduce explicit checked runtime/ANF and pure/impure effect phases **when supported workload evidence justifies them**, with validation after each semantic transformation; share lambda lifting, dictionary specialization, direct-call and closure analysis before splitting into JS/TS/Rust/Wasm-specific layouts. Keep direct JS/TS from one ECMAScript plan and Wasm GC storage separate from WIT boundary marshalling. No mandatory LLVM, `rustc` to Wasm, `tsc` to JS, or universal low-level IR.

### 3.4 Assurance and incremental/module boundaries (M4–M5)

Use three distinguishable outcomes under **one** source language: ordinary checked, closed verified and boundary-qualified verified. `PsV7Native.Request`, `Result` and native CLI now expose these identities; only ordinary checked emission is implemented. Both verified requests refuse without automatic downgrade. A future verified artifact requires all requested proof, specification, effect, assumption, runtime-model/target correspondence and erasure obligations to be discharged. `Return`, `Throw`, `Trap`, `Diverge` and trace/progress claims remain distinct and need target-appropriate evidence.

Project source imports and public/private interfaces are implemented for bounded sources; Lean-style incremental elaboration, deterministic red/green invalidation, editor info trees and fine-grained source maps remain broader M5 goals. Treat past in-memory prefix caching as a bounded optimization, never as reusable kernel admission authority. Extensions may propose syntax/proofs/IR, but cannot mint host checker tokens, load untrusted guests inside the trusted process, or authorize a verified release.

## 4. Architecture comparison to pinned Lean 4.35

| Area | Lean 4.35 architectural fact | PSC0 current / target judgment |
| --- | --- | --- |
| Meta/elaboration | Rich dependent metavariable solver, tabled typeclass resolution, incremental command processing | Native solver and scopes exist; selected subset is intentional, but broad completeness/tooling is behind Lean |
| Inductives/termination | Group-aware inductive elaboration, recursors, structural/WF/partial/fixpoint strategies | Shared group formation/admission/reduction, typed companion execution and Nat-measure recursion candidates; source group Match/deriving, broader nested traversal and total/mutual strategies remain critical |
| Kernel | Small mature checking kernel | Correct choice: **reuse official Lean**, never replace or bypass it in active PSC0 |
| Compiler optimizer | LCNF, pure/monomorphic/impure stages, pass validation and mature runtime | Checked expression IR + specialization are real, but not yet equivalent in pass structure or performance |
| Backend/ABI | Native-oriented runtime/foreign interfaces | PSC0's direct JS/TS/Rust/GC/components are a real specialized portability advantage on supported cases |
| Assurance | Logical checking and supporting verification tooling | PSC0 can offer a more explicit audited-artifact policy, but no general backend correctness claim yet |

**Verdict:** the PSC0 plan is strong and specialized, **not already equal to Lean 4 in implemented quality**. Improve the present pipeline's missing shared semantic stages; do not restart the compiler or claim theoretical strength from extra backends.

## 5. Exit ownership and next work

| Stage | Owner, exit and explicit non-goal |
| --- | --- |
| **M3+B** | Shared data family/group formation, motives/pattern/deriving, checked structural/WF recursion and v7.2 source strategy; P0 typed logical/body identity and selected ordinary executable foundations; P1 checked fixpoint/assumption gating. The six [roadmap exit criteria](docs/PSCV0_NATIVE_IMPLEMENTATION_ROADMAP.md) remain authoritative. |
| **M4+C** | Broader effects, runtime operational outcomes, partial executable control/state, loops/FFI boundaries, not a new source logic |
| **M4+D** | Proof obligations, contracts, partial/total/trace/refinement/assurance evidence and fail-closed verified artifact policy |
| **M5+E** | End-to-end conformance/evidence, validated optimization/performance, incremental tooling, C5 retained-source correspondence |
| **Later only** | Independent kernel, npm/self-host fixed point, language-source migration, plugin host/stdlib ecosystem and alternate distribution/runtime strategies |

**Development gate:** read fresh HEAD/CI and the stage directive; inspect the relevant pinned Lean implementation/tests; update the *one semantic owner* and compact independent positive/negative fixtures; keep original thresholds; run same-SHA native, F1, F2, F3/F4 and relevant focused backends; preserve evidence/previous history; update both `AI_WORK_STATE.md` and `AI_CONTINUE_PROMPT.md`. A green small slice is **not** the six-criterion M3 exit.

**Current accepted M3 checkpoints:** direct recursive `Hashable`/`Repr`/`BEq`/`DecidableEq`; checked computed strict children; fixed and evolving prefix recursion; exact open `Nat.add a 0` and `Nat.sub a 0`. Selected `HAdd` `k + 0` source and two-discriminant `Bool × Nat` pattern fixtures passed their focused lanes on recent descendants, with full native acceptance recorded for compiler `33c569e08af2484d90f3bd0b0da7a97cfaf1ad3a`. More general nested/mutual/data, P0/P1 and full M3 completion remain open.

Historical documents are evidence, not the source of current implementation authority. Update this document only when actual owner boundaries change.

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

