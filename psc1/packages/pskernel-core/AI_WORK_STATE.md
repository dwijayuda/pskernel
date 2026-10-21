# PSKernel-Core Expression V2 integration work state

Date: 2026-10-21 (Asia/Jakarta; Actions timestamps use UTC)
Status: **IN PROGRESS — NOT a completed Expression V2 kernel**
Integration branch: `integration/psc1-pskernel-expr-v2-lean435-20261021`
Research parent: `research/psc1-pskernel-expr-v2-lean435-20261020`
Refreshed research HEAD: `c98be336e2e95dda998e4353dd791bdba5d8cb4f`
Toolchain: `leanprover/lean4:v4.35.0`
Exact Lean source: `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`

## Current checkpoint and evidence

The latest complete integration/canonical checkpoint is
[c9868aeab2ddbafc5ab6daa84583079a02c663da](https://github.com/dwijayuda/pskernel/commit/c9868aeab2ddbafc5ab6daa84583079a02c663da):
[integration39526200665](https://github.com/dwijayuda/pskernel/actions/runs/39526200665),
[correctness/canonical39526200700](https://github.com/dwijayuda/pskernel/actions/runs/39526200700)
and [research39526200664](https://github.com/dwijayuda/pskernel/actions/runs/39526200664)
passed. Actual source audit covers155 portable modules across two roots;
canonical reconstruction derives112 modules and1,353 declarations. Authentic
.lean/.ps checking, TS7.0.2, Node22.23.3, declarations/maps and detached canonical
DAG runtime pass, including owning constant types, ordinary/mutual inductive
type IDs and checked dependent projection inference. The integration executable
passes128 correctness-guarded ABBA observations,33 complete executable operations
and six separate profiles. Native includes official Lean fixtures,1,755
transformation cases and local metadata/cache lemmas. DirectJS still reports
its explicit emitter capability limit and is not qualified for the full kernel.
These passes do not establish full Arena qualification, acceptable memory
behavior, or a complete DAG checker. Original default V1 remains qualified;
the replacement still relies on full-operation fallback outside its migrated
rules. No integration PR is merged.

### Strict generated admission assertion correction — qualification pending

The5b131 generated job119008044447 in
[run39534547183](https://github.com/dwijayuda/pskernel/actions/runs/39534547183)
built the authentic complete executable and passed the416-case direct admission
matrix. It then failed the stored-definition assertion for the shared header/body
fixture, after exact old/new public session parity had passed. The expected
hand-written JS record lacked PSC1's nominal structure Symbol brands.

The expected definition is now independently reconstructed from the input DAG
through psKernelDagDecodeDefinition, using the authentic generated constructors.
Strict Reflect-key equality and every semantic assertion remain unchanged.
The new inference-only script also stops assuming exported runtime namespaces
for structure .mk constructors; plain input records use their declared fields.
No kernel decision, resource limit, or compiler behavior changes. These harness
corrections need a passing generated/canonical rerun and are not reported green.

Let106387 canonical job119004577217 in
[run39533476064](https://github.com/dwijayuda/pskernel/actions/runs/39533476064)
has independently passed the detached .ps-derived complete checker, all four
new generated Let/stateful cache markers, declarations/maps and source closure:
115 canonical modules,158 portable modules across two roots. DirectJS remains
explicitly unsupported. Its integration measurement job is still running.

### Unified checked and inference-only DAG worker — native qualified; generated CI pending

The syntax-directed checker now uses one implementation with an explicit
inference mode. The original unchecked lambda-domain, let-annotation/value,
and application-argument policies are confined to inference-only mode; the
checked entry retains all original validation. Inference-only application
uses the complete head spine, lazy reversed pending substitution and the exact
argument-count-plus-one exposure budget. Fixed WHNF/DefEq callbacks retain
the top-level fuel while inference recursion uses its predecessor.

Separate checked and inference-only caches belong to the same arena and local
scope. A helper constructs a type without publishing a judgment; the owning
entry publishes once in its selected cache. Scope exit restores both parent
caches. Fuel/depth guards still run before a cached result can authorize an
operation. The staged compatibility entry and original public checked API are
preserved. This is a prerequisite for direct theorem IsProp checking, not a
new untrusted admission shortcut.

The new native executable compares21 fixtures over3,780 exact fuel/depth
combinations, six official Lean valid-expression comparisons, cache-separation
and warm-entry guards, and numeral limits. A separate generated script checks
1,008 combinations plus the negative authorization sentinel in both authentic
source and canonical .ps executables with empty runtime PATH. Nine additional
local cache/publication/guard facts are checked with the existing proof gate.
Native job119010207629 in
[run39535224761](https://github.com/dwijayuda/pskernel/actions/runs/39535224761)
passes at71163ae02f1ab851b97cf124d36930503418ce17, including both inference-only
markers, the complete prior admission suite and nine new local proof reports.
Generated and canonical executable gates remain pending. No new closure count
is claimed. The complete general DefEq and reduction migrations remain open.

### Direct simple declaration admission — native qualified; generated CI pending

RunDag now attempts direct admission of axioms, safe/partial definitions and
opaque declarations against the owning DAG. It shares one checker state
between header checking, sort validation, body checking and final DefEq.
Duplicate-name/universe guards, expression/level metavariables, free variables,
undefined universes, safety modes and mismatch diagnostics retain the original
ordering. Admission sort validation always executes WHNF. The final comparison
keeps the returned successful-pair owner, including entries established by
checked lets/applications. Environment publication and same-batch type/body
index registration occur only after checking; declaration limits are checked
at their existing point and native evaluator removal is preserved.

Unsafe recursive definitions, theorems, mutual definitions and inductives
remain whole-original-admission fallback. Unsupported descendants discard
the attempted state and rerun complete original admission. Boundary static
guards still inspect the once-decoded expression; no legacy input tree is
reimported into the DAG during checking. Original default V1 is unchanged.

Qualification adds26 declaration cases across416 fuel/depth combinations,
four official Lean admission comparisons, exact environments/receipts/order/
lookup correspondence, header/body sharing sentinels at fuel5 and depth16,
safety/partial/opaque decisions, malformed-ID/duplicate/preflight precedence,
failed publication, declaration-limit ordering and cold/warm terminal DefEq
entry guards. Native job119008044720 in
[run39534547183](https://github.com/dwijayuda/pskernel/actions/runs/39534547183)
passed at5b13128c71c6e36bf8f36cc41759a96197783022. The actual log contains all
five admission markers, the1,755 transformation comparisons and the local
proof gates. Authentic PSC1 source checking also passed. Generated and detached
canonical executable qualification remain pending.

The existing24-observation complete-admission benchmark gains a separate
untimed diagnostic after all reported timing/GC/RSS captures. It requires
direct success for every corresponding input-slot-0 prefix, exact dispatcher
environment parity, original input ID ownership, and a direct ill-typed
definition rejection. Timed calls are not instrumented; the path-measured flag
remains false. The3fb6 benchmark run is retained as the pre-admission baseline.
No new numbers or source-closure counts are claimed before Actions reports them.

### Application conversion shares its owning DefEq state — native qualified; generated CI pending

Checked application now invokes the same captured-budget, scoped DefEq worker
when inferred argument type and function domain are structurally different.
It uses the returned state before result substitution; a successful comparison
is available to later work in the same scope. The existing syntactic shortcut
does not enter DefEq or publish a pair. The exact raw two-application
eagerReduce marker changes only the original comparison-context flag.
Unsupported comparison rules still restart the complete original operation.

New native and generated matrices require direct results for equivalent and
unequal universes and paired metadata types across720 fuel/depth combinations;
four fixtures are compared with official Lean. Separate controls check a
let-primed pair, cold-versus-warm comparison budget, returned-state publication,
syntax cache neutrality, all nine eager marker shapes, context preservation
and invalid node IDs. The previous one-sided metadata conversion fallback
remains explicitly tested. Native job119006670038 in
[run39534122743](https://github.com/dwijayuda/pskernel/actions/runs/39534122743)
passed at2be592e7e6af009869f437dcd88746ee448a69bc; the actual log contains all
four new native/official markers and the original proof gates. Generated and
canonical qualification remain pending. No new performance claim precedes
passing Actions.

### Checked lets and scope-owned DefEq pairs — native qualified; generated CI pending

The checked DAG path now carries optional local value IDs and implements fully
checked lets: annotation checking, sort validation, value checking, fixed-budget
DefEq, fresh local opening, body inference, cheap beta, abstraction and the
original closed-result rule. Public/core WHNF follow typed let values with the
original ordering and budget costs. A legacy local context still requests the
complete checker; no existing local is silently dropped.

Successful quick DefEq pairs now belong to the checking state and its arena.
The symmetric modular hash only filters candidates; both orientations use
collision-safe structural equality. Free-variable pairs are ineligible, scope
exit restores the parent's cache, failed comparisons publish no entry, and no
transitive closure is added. Fuel and recursion guards precede cache lookup.
Unsupported recursive work still falls back as one complete original operation.
The subsequent application conversion slice below extends this shared comparison
state to the original nonsyntactic argument/domain branch.

Qualification adds 16 positive/negative let fixtures, 3,120 native raw
fuel/depth combinations, public API parity, 16 official Lean comparisons,
typed-local public/core WHNF boundaries, escaped-local rejection, parent/child
cache restoration, collisions, symmetry, duplicate-pair reuse, fresh-owner
isolation and no-transitive-closure controls. Matching generated and detached
canonical JavaScript gates and eight additional local cache/entry-guard facts
are required. Native job119004577007 in
[run39533476073](https://github.com/dwijayuda/pskernel/actions/runs/39533476073)
passed at106387af9827a639455d329408745528ae318366, including all five new markers
and eight theorem reports with only approved axiom dependencies. Original native
correctness also passed. Authentic PSC1 source checking passed; generated and
canonical executable results remain pending. These are finite parity tests and
local proofs, not a full kernel soundness or cache-validity theorem. The last
fully qualified kernel source remains c9868 above.

### Complete admission measurement and Arena phase timing — pending CI

This commit adds six matched complete safe-definition admission fixtures:
8/32 declarations in constant chains, metadata-heavy bodies, and dependent
binder chains. Each executes in separate A-B-B-A Node workers with fuel4096,
fresh sessions, direct smart-constructed DAG inputs, and an empty runtime PATH.
The new24 observations report construction, cold/warm admission, independent
exact-result assertion time, whole-worker peak RSS and post-GC retained heap.
Receipts, declaration order, exact installed types/bodies, lookup correspondence,
unchanged resource policy and a decisive invalid definition are checked.
The original128-observation complete-operation benchmark remains unchanged.
No new measurements are claimed until Actions completes. The current direct
admission-path flag remains false: these public API comparisons do not prove
which internal branch executed.

Arena progress now reports monotonic elapsed milliseconds from replayFile entry
under the existing adapted-source hash. It excludes process startup and still
does not distinguish graph validation, decoding and declaration checking inside
the single RunDag call. The comparator rejects malformed/nonmonotonic timing,
retains only diagnostic allowlisted fields, and never treats progress as a
verdict. New24 Python controls and three real generated replay controls are
required in Actions; the existing135 controls remain. Full193 cases, official
300-second/generated60-second host limits, workers2 and kernel fuel4096 are
unchanged. This instrumentation changes no kernel acceptance or rejection rule.

### Checked projection inference — native/generated/canonical/official qualified

The production DAG checker now implements the original projection inference
rule using owning constructor type IDs: checked structure inference, full-budget
WHNF, live inductive/constructor shape checks, universe substitution, parameter
instantiation, dependent prior-field projections and both Prop/data restrictions.
It preserves the parameter-count-plus-one and field-index-plus-one loop bounds,
predecessor inference callback, and captured top-level WHNF callback. Projection
sort expectations always execute WHNF; the binder shortcut is not reused.

Thirteen positive/negative fixtures cover dependent fields, a universe-polymorphic
parameterized box, valid proof fields, both rejected data projections from Prop,
metadata, binders, wrong structures, invalid/UInt32-overflow indices and error
precedence. Native and generated tests require direct results across 2,535
fuel/depth combinations, full public parity and same-batch admission, warm-cache
entry guards, exact dependent result types and missing-owner fallback. A native
official comparison independently admits all four fixture inductives through
pinned Lean's checked addDeclCore API and compares all thirteen results.
Native integration39526200665/job118981306692 passes both explicit projection
markers, including all thirteen official checks. Generated job118981306463 and
canonical job118981306343 independently pass the same direct projection matrix,
full public cases and complete independent checker gates. Original correctness
and all six research jobs also pass at c9868. No production runtime calls
official Lean.

### Full 193-case Arena result after transport/diagnostic fixes

At [c9868aeab2ddbafc5ab6daa84583079a02c663da](https://github.com/dwijayuda/pskernel/commit/c9868aeab2ddbafc5ab6daa84583079a02c663da),
[run39526200684](https://github.com/dwijayuda/pskernel/actions/runs/39526200684),
official job118981306176 passed and generated comparison job118982048530
completed with a failed qualification gate. Its actual final log records all
193 cases, with the same outcomes as the earlier6626 and cfa40d6 checkpoints:

| Outcome | Cases |
| --- | ---: |
| Matched acceptance | 102 |
| Matched kernel rejection | 56 |
| Matched metadata rejection | 1 |
| Matched transport rejection | 7 |
| Host timeout at 60 seconds | 25 |
| Unsafe/partial contract agreement, separate classification | 2 |
| Internal error / unsupported | 0 / 0 |
| Observed false acceptance / false rejection among completed verdicts | 0 / 0 |
| Total / strict qualification | 193 / **incomplete** |

The official reference records 122 acceptances and 71 rejections. The current
source audit covers155 portable modules; this commit's canonical closure contains
112 modules and1,353 declarations. All135 transport/outcome controls pass. The nested-restored projection
case now matches rejection. Prelude all-list transport now reaches the checker;
that case times out and is not reported as unsupported or accepted.

Every timeout retained a valid adapted-source-hash-bound snapshot at public
RunDag entry (kernel-admission, coreInvoked=true, fuel4096). There were zero invalid
snapshots. Transport and ordering therefore completed, but the snapshot cannot
distinguish RunDag's graph validation, decoding or actual declaration checking.
Host timeout is not a kernel fuel result. The entire original set of 24 timed-out
cases remains, plus init-prelude. Some inputs are small: repeated-subproblem has
162 DAG nodes/5 admission commands, church-numerals197/4, refute-cheap-last367/7.
The largest reported input, grind-ring-5, has180,991 nodes/2,182 commands; the
prelude has54,535/1,774. Input size alone cannot explain the complete timeout set.
No case has been excluded and full-corpus qualification remains red.

### Ordinary/mutual admitted type IDs — native/generated/canonical qualified

Ordinary and mutual inductive headers and constructor types now extend the
same owning declaration index only after their entire original admission bundle
succeeds. Source review confirms that ordinary Admission/ConstructorAdmission
and mutual Header/AdmissionLoops install those exact input types unchanged.
No generated type is imported, and these references carry no delta body.

Native and generated tests add 48 mutual and 24 ordinary direct checking cases
across fuel and depth boundaries, compare each retained ID with the live
environment's exact installed type, and test failed mutual admission, live
unsafe-constructor rejection, public same-batch checking, and generated
recursor fallback with correct universe arity. Nested restoration deliberately
publishes no input-type index until its different correspondence is established.
Native, independent generated and canonical generated execution pass at cfa40d6,
with explicit mutual-index markers and the original rejection gates retained.
This slice enables DAG projection inference; it does not migrate inductive
admission or generated recursor checking.

### Full-operation allocation/CPU profiles — executed; performance gaps remain

All six isolated Node22 diagnostics passed at
[0c56fe39379ace6eabe28bc3aa5cf919bf3c3292](https://github.com/dwijayuda/pskernel/commit/0c56fe39379ace6eabe28bc3aa5cf919bf3c3292),
[run39521189386/job118965147146](https://github.com/dwijayuda/pskernel/actions/runs/39521189386),
and again at cfa40d6. They run the same fully checked public operations with
fuel4096 and fresh semantic caches, separately from ordinary ABBA timing.
Node22.23.3/V8 12.4.254.21-node.57 generated-module SHA256:
`3db20beb684357e70af278c82b9f3a5c8e20e0308b3fb9c6903aacb89511efc2`.

| Workload | Sampled allocated bytes original / DAG | Newly allocated surviving sampled bytes original / DAG | CPU samples original / DAG |
| --- | ---: | ---: | ---: |
| Unique-function WHNF128 | 1,480,253,088 /784,883,056 | 64,400 /232,360 | 1,607 /1,125 |
| Hash-collision WHNF128 | 3,321,448,600 /2,488,812,384 | 55,240 /166,640 | 3,823 /3,439 |
| Checked zeta24 | 34,619,472 /35,883,416 | 45,064 /35,520 | 49 /60 |

Allocation uses32KiB sampling including collected objects; the distinct survivor
pass uses4KiB sampling after GC. These are statistical estimates, not exact
allocation counts or a census of existing retained objects. CPU uses1ms
sampling. Short zeta profiles include inspector stop/post overhead outside the
operation, so their sampled total is not operation CPU time. Raw profiles,
source locations, allocation stacks and heap-space snapshots are preserved in
[artifact12312247313](https://github.com/dwijayuda/pskernel/actions/runs/39521189386/artifacts/12312247313).

The unique-function profile identifies original HasFVar/hash walks and the
generated trampoline among major costs. Collision profiles identify structural
ExprEq and paged cache lookup. Checked-zeta DAG stacks still execute original
InferCore/IsDefEq workers; this confirms fallback, not a specific closure cause.
These fixtures do not identify the cause of any Arena timeout. Newly surviving
DAG samples include cache entries, nodes and closures; they do not prove a leak.

Ordinary unprofiled A-B-B-A results from the same0c56 run:

| Workload | Original warm ms | DAG warm ms | Original peak RSS KiB | DAG peak RSS KiB | Original / DAG retained heap delta bytes |
| --- | ---: | ---: | ---: | ---: | ---: |
| Unique-function WHNF128, one call | 1,867.574–1,893.152 | 1,231.133–1,308.546 | 264,320–407,824 | 253,992–257,752 | 34,160–35,328 /82,824–91,248 |
| Hash-collision WHNF128, one call | 4,422.913–4,594.885 | 3,869.549–4,020.308 | 427,152–438,232 | 404,876–406,012 | 31,112–32,168 /87,664–90,608 |

Five-input pool construction is separate: unique3.245–3.296ms(original)
versus111.830–116.343ms(DAG), collision4.218–4.300ms versus109.715–116.661ms.
Peak RSS varies across runs; an earlier qualified run had materially worse
DAG RSS. Retained-heap and construction costs remain unresolved.

At cfa40d6, checked-zeta24 (two warm calls) still costs104.159–107.789ms
original versus110.202–120.495ms DAG; cold81.372–82.638 versus85.908–88.858ms;
peak RSS163,620–165,084 versus184,200–192,828KiB; retained heap24,080 versus
28,848–29,840bytes. This is a measured regression before direct checked-let
integration. At c9868, the same two-call checked-zeta fixture remains slower:
104.482–106.186ms original versus112.744–113.918ms DAG, with peak RSS
164,124–164,480 versus185,564–192,652KiB and retained heap24,080 versus
29,840–29,992bytes. No general performance or memory qualification is claimed.

### One owning declaration index and direct constant types — native/generated/canonical qualified

The owning batch now keeps one declaration table containing original admitted
type IDs, declaration kinds, universe parameters and optional transparent body
IDs. This replaces the narrower definition-body table; it adds no parallel
type cache or legacy type import. Successful axiom, definition, theorem, opaque
and mutual-definition admission extends the table; the newer ordinary/mutual
inductive extension is described above. Theorems and opaque declarations retain
type IDs but never delta bodies. External-session constants, generated recursor
types and nested restoration still request the complete checker.

DAG checking consults the live environment for lookup, universe arity and
unsafe/partial policy before using a matching admitted type ID. All public
check/WHNF/DefEq preliminary checks receive the same owning table, which never
escapes into the returned legacy session. The underlying original constant rule
is factored into a shared validation helper with its original order. A native
extensional proof retains its old equations and proves identical results for
all contexts/names/levels/modes. Native integration at
[1a4b431d0b7cbcb6f2d306a62bd571a0a03060d9](https://github.com/dwijayuda/pskernel/commit/1a4b431d0b7cbcb6f2d306a62bd571a0a03060d9),
[run39521023170](https://github.com/dwijayuda/pskernel/actions/runs/39521023170),
passed this proof and the complete native regression. Its generated job also
passed real checker smoke, 128 ABBA observations and33 strict executable
operations. The proof depends only
on the approved propext, Classical.choice and Quot.sound axioms. The first
canonical attempt failed during Lean download with TLS error35 before source
checking; only that job was rerun. The rerun canonical job118968681300 passed at the same1a4b431 source, and the
subsequent cfa40d6 canonical job118969755351 independently passed the complete
110-module/1,336-declaration closure.

Native and generated fixtures add567 direct constant inference comparisons
across nine admitted constants, three safety contexts, seven fuel values and
three entry depths. They cover universe substitution, live unsafe/partial
rejection, inferOnly's existing safety skip, arity-before-safety and lookup-
before-arity ordering, absent/mismatched index fallback, unchanged installed
types, full public same-batch checking, and a separate arena reusing node IDs.
The existing malformed, ill-typed, duplicate and resource-limited admission
controls remain. None of these internal references is a public admission
certificate, and arbitrary forged internal tables are outside RunDag's trust
boundary. This is not a proof of global index correspondence or soundness.

Native delta/binder qualification is now green at
[767acc6b12568c8d15dae1a2ac7150aacd8ddc00](https://github.com/dwijayuda/pskernel/commit/767acc6b12568c8d15dae1a2ac7150aacd8ddc00),
[native integration39520129735](https://github.com/dwijayuda/pskernel/actions/runs/39520129735).
Its complete generated gate also passed. The numeral change at2d29ebc now passed
the complete [integration39518432248](https://github.com/dwijayuda/pskernel/actions/runs/39518432248):
strict detached large-numeral JS,128 correctness-guarded ABBA observations
and33 complete executable operations all passed. The App slice5f0e434 passed native, generated and canonical gates as recorded
above. The declaration index now has native/generated/canonical evidence at cfa40d6.

### Dependent application checking — native/generated/canonical qualified

The production DAG checked-inference path now checks a function, exposes its
dependent function type with the original top-level WHNF budget, checks its
argument, and performs capture-avoiding DAG codomain instantiation when the
argument type is structurally equal to the domain. Equality still resolves
hash collisions structurally. The original checked application rule has this
syntactic-equality branch before invoking DefEq; no additional DefEq entry is
invented or skipped. Applications requiring general DefEq restart the complete
original operation with unchanged resources and publish no partial state.

Native and generated fixtures cover dependent first/second arguments, local
binders, a function type hidden under eight metadata nodes, an extra binder
that distinguishes the captured WHNF budget from a decremented one, invalid
functions/arguments, and exact fuel/depth boundaries. Universe/metadata type
conversion remains an explicit successful fallback; unequal types remain a
rejection. Literal-size errors precede type comparison, and checked App results
remain ineligible for the inference cache. An official Lean fixture checks
the same identity application. This is one production integration slice,
not full DAG-native application DefEq, inferOnly or complete checker migration.

The full193 independent run39517166070 at9b34a935 completed with the same165
strict matches,24 host timeouts,1 internal diagnostic,1 unsupported all-list
and2 unsafe/partial contract agreements as the earlier report. It passed110
controls and complete canonical generated execution. The later reporting and
all-list fixes still need fresh full-corpus outcomes.

### Current delta/binder qualification corrections — pending CI

The delta raw-worker resource matrix passed its first zero-fuel case, but the
separate public matrix compared a preflighting V1 entry with an internal DAG
helper that runs after RunDag's preflight. Native run39519363353 and generated
run39518665303 both rejected that harness mismatch. Both matrices now invoke
the identical session preflight before the internal helper and preserve exact
error tags/messages. The native failure label includes root/fuel/depth. No
production entry order or fuel rule changed.

The first dependent-binder commit e5623b6d failed native compilation because
two local variables used Lean's reserved token scoped. They are renamed to
scopedState. The binder implementation, local proofs and generated execution
still require passing evidence at the corrected source. Latest fully green
integration/canonical checkpoint remains9b34a935.

The preceding stateful source
[463d956f40f360960dd78ad8b8d8b3749a80c03f](https://github.com/dwijayuda/pskernel/commit/463d956f40f360960dd78ad8b8d8b3749a80c03f)
passed [integration39514448898](https://github.com/dwijayuda/pskernel/actions/runs/39514448898),
[original correctness/portability39514448820](https://github.com/dwijayuda/pskernel/actions/runs/39514448820)
and [all-six research39514448956](https://github.com/dwijayuda/pskernel/actions/runs/39514448956).
Its generated executable passed 578 transformations,96 correctness-guarded ABBA
samples and all33 whole-executable operations. Canonical reconstruction derived
101 modules/1,239 declarations. TypeScript7.0.2/Node22, declarations, maps and
detached V1 runtime passed. Canonical DAG runtime was added later and needs its
own evidence. DirectJS remains an explicitly unsupported emitter capability.

### Numeral recursive-alias repair — pending this commit's CI

Five scalar workers (GCD, heap-word counting, power, bitwise and right shift)
previously constructed their predecessor function before inspecting arguments.
The generated backend could therefore allocate an enormous closure chain from
a fuel initialized to a numeral or exponent. Recursive aliases are now delayed
inside their argument lambdas. Their supplied fuel, equations, zero-fuel
results, checks and errors are unchanged. A native proof file retains the exact
old equations and proves extensional equality for every supplied fuel.
All five lemmas and the native large-numeral regression passed at
[2d29ebc](https://github.com/dwijayuda/pskernel/commit/2d29ebc5785d44ee6406f378845412978b3fe1cc),
[native integration39518432248](https://github.com/dwijayuda/pskernel/actions/runs/39518432248).
Their printed dependencies are only propext and Quot.sound. Independent-JS
large-numeral qualification passed in integration39518432248.

The generated gate uses a30-second host watchdog, unchanged kernel fuel4096,
129-bit numerals, UInt32-limit exponent cases, low-fuel equations, exact numeral
size thresholds, complete checking/WHNF/positive-negative DefEq, and real
positive/negative declaration admission. It is run from both .lean-generated
and canonical .ps-generated bundles with PATH empty. It does not use official
Lean at runtime. This is a functional/allocation regression gate, not an
A-B performance result or a proof of an allocation bound.

### First complete independent Arena report — gate failed, no exclusions

[39513874902](https://github.com/dwijayuda/pskernel/actions/runs/39513874902)
completed all193 independent cases and110 controls at fuel4096. Strict matches:
165 (102 accepts,55 kernel rejections,1 metadata rejection,7 transport rejections).
Unresolved:24 host timeouts (5 bad/19 good), one nested restored-validation
diagnostic classified internal, one init-prelude noncanonical source all-list
declined as unsupported, and two agreeing unsafe/partial rejections with a
documented policy distinction. No false admission was observed among completed
verdicts; the timed-out cases remain unresolved. The official pinned reference
passed all193 (122 accepted/71 rejected). All body hashes were preserved.

Timeout records report only host wall time; they do not establish that kernel
admission began or attribute the cost. Some source fixtures contain padding Nat
literals above100,000, but they remain below the small-Nat threshold and therefore
do not enter heap-word counting. They do not establish that worker as the cause
of any timeout. Causation by the recursive-alias defect remains unmeasured.
Input diagnostics will separate numeric names from numerals. Known nested error
wrappers and the nonchecking Lean DefinitionVal.all annotation need principled
adapter fixes; neither is permission to weaken declaration checking.

No PR is merged. This branch remains a partial migration with full-checker
fallback and open performance/memory, Arena and formal-refinement obligations.

### Same-batch DAG delta migration — pending this commit's CI

After complete declaration admission succeeds, the ordered DAG batch records
definition names, universe parameters and canonical body IDs. The table is local
to that validated input arena and never escapes in the returned kernel session.
Direct WHNF unfolds those bodies by DAG universe substitution and spine rebuild,
without importing the environment body. Definitions from a preexisting external
session explicitly request the complete original fallback. Opaque values and
theorems remain inert; unsafe mutual-definition behavior retains the original
checker contract.

New native/generated tests require actual direct-worker results across264 raw
and complete-public fuel/depth combinations, exact15/16 recursion entry bounds,
polymorphic/partial/full application, mutual aliases and fuel-exhausting cycles,
wrong universe arity, command order, failed/duplicate/limited admission, and
same numeric IDs in a foreign arena. The ignored argument retains the original
five-fuel failure/six-fuel success ordering. An official Lean polymorphic identity
comparison and three local state-field/cache-initialization lemmas are included.
These are pending CI and do not prove global arena ownership or delta refinement.

### Arena metadata and diagnostic adaptation — pending this commit's CI

Pinned [Lean Declaration.lean](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Declaration.lean)
defines DefinitionVal.all and the corresponding theorem/opaque fields as source
mutual-block annotations unused by kernel checking. The replay adapter now
validates every referenced name and retains its exact table ID and typed name
segments in an explicit receipt. Order, duplicates and numeric names above2^53
are preserved. These annotations do not affect safe declaration grouping or
dependency order. Inductive and recursor all-lists still require agreement with
independently regenerated data. New controls exercise all three annotation
families and invalid IDs, while retaining forged-inductive/recursor rejections.

Public diagnostic adaptation now recognizes exactly one of the five fixed
nested-admission stage wrappers around an already-known diagnostic. It preserves
the original complete message and resource kind. Unknown messages, unknown or
malformed prefixes and repeated wrappers remain internal errors. The checker
does not change its acceptance, rejection or fuel behavior. Native and generated
controls cover bare/wrapped invalid, unsupported and resource messages.

The official Arena job additionally inspects every authenticated input and logs
source all-list annotations and actual numeral magnitudes separately from numeric
name salts. Optional synchronous progress records identify transport, ordering,
kernel admission and metadata phases; timeout reports retain the last
source-hash-bound snapshot. A snapshot never supplies an acceptance/rejection
verdict. All193 cases, the60-second generated host limit,2GiB heap and kernel
fuel4096 remain unchanged. The previous full gate is still failing until the new
complete report is observed. The authenticated input inspection passed for all193
with zero issues at [39518988495](https://github.com/dwijayuda/pskernel/actions/runs/39518988495).
It found exactly two noncanonical all records: opaque Lean.Syntax.getHeadInfo?
and getTailPos? with their private helper names. Only init-prelude has a numeral
above63 bits (2^64); none of the24 previously timed-out cases does. Their timeout
causes cannot be assigned to large exported numeral size checking.

### Direct binder checking — pending this commit's CI

The checked DAG path now infers Sort, FVar, Nat/String literal, metadata, lambda
and dependent forall types in the owning arena. Its local context stores type
IDs; its state owns a fresh-name counter, checked-inference cache and the existing
WHNF state. Binder closure restores every implemented semantic cache to the
parent scope while retaining the append-only child arena and monotone fresh
counter. Free-variable-sensitive judgments remain cache-ineligible.

Inference recursion receives predecessor fuel while type exposure uses the
original top-level WHNF fuel. Returned lambda types use the exact limited
CheapBeta rule, then abstract the fresh local and build a DAG forall. Public
replies decode only newly appended output nodes against the existing once-per-
batch decoder. Unsupported applications/constants/lets/projections still
request the complete original checker. No incomplete result or speculative
state is published when fallback is required.

Native/generated tests require direct results for dependent binders, negative
sort judgments, exact fuel/depth boundaries, fixed callback fuel, fresh-name
restoration, warmed cache entry guards, child-cache/local-context isolation,
real structural hash collisions and literal-size errors. Eight local state/
guard lemmas and official Lean dependent-lambda/forall comparisons are included.
The raw fresh-name collision fixture preserves the original checking API
behavior; declaration admission separately rejects free variables. Forgeable
checking receipts still never authorize admission.

### Current measured complete-operation performance

At9b34, generated checked-operation warm totals include public graph validation,
decode and full checking. Admission/input construction are separately recorded.
Two same-run observations per variant, unchanged fuel4096, fresh semantic caches:

| Operation | Depth / calls | Original ms | DAG ms |
| --- | --- | --- | --- |
| Paired metadata DefEq | 32 /4 |467.231–481.941|47.092–47.365|
| Paired metadata DefEq | 96 /2 |602.835–606.148|62.628–68.473|
| Checked Nat.succ WHNF |8 /3|538.528–544.487|141.596–142.228|
| Checked Nat.succ WHNF |32 /1|669.065–696.303|166.789–183.993|
| Checked Nat.succ WHNF |96 /1|2718.381–2853.210|869.559–896.915|
| Checked projection WHNF |8 /3|543.501–576.560|347.479–353.849|
| Checked projection WHNF |32 /1|194.231–198.017|137.053–139.114|
| Checked projection WHNF |96 /1|249.405–262.843|207.667–211.440|

Native paired metadata at depth192/20 calls measured20.334–20.486ms original,
1.435–1.451ms DAG and2.603–2.623ms official Lean. Official Lean has its own internal
resource policy; the PSKernel fuel4096 label applies only to PSKernel variants.

Memory is not yet qualified across workloads. Unique128 RSS varied from
264244–404340KiB original versus246680–246760KiB DAG, but retained deltas were
31448–35600 versus68512–75920bytes. Collision128 peak and retained results varied
substantially, including a1,037,320-byte DAG retained delta. The preceding463
run also showed a DAG unique128 RSS regression. Separate CPU and sampled
allocation diagnostics are needed; no cause or blanket memory improvement is
claimed. Full smoke runs changed coverage and are not matched memory workloads.

## Objective and execution constraints

Finish the paged expression architecture in the complete independent checker.
The user's complete acceptance criteria remain binding: production integration,
native and official Lean differential checking, all applicable Arena cases,
authentic PSC1 and canonical PS, executable independent JS, unchanged resources
and axioms, whole-checker memory/performance, and final-commit Actions evidence.

All repository reads/writes and tests use connected GitHub and GitHub Actions.
No local checkout or compilation, force updates, release or package publication.
Do not add proof holes, unchecked assumptions, higher kernel fuel, weakened
negative assertions, or exclusions for difficult cases. Finite tests do not
establish formal soundness.

## Actual implementation and remaining boundary

Production owns the paged Node/Entry, indexed storage, smart constructors,
metadata replay validator, collision-safe equality, lifting, multi/reverse
instantiation, abstraction, universe substitution, spine helpers and decoder.
Scalar expression syntax and scalar hashing were factored into shared modules;
the DAG foundation does not import the legacy recursive expression or checker
cache. Promoted Research module names forward to the production owners.

`psKernelV1RunDag` is the public untrusted-input boundary. It validates one arena
and decodes each unique node once for an ordered command batch. Input tables can
be constructed directly through the production paged smart constructors.
Sort/literal/metadata/binder inference, checked quick DefEq, and qualified WHNF slices
read DAG entries directly. All structural shortcuts resolve hash collisions.
Both terms still undergo complete checking before the DefEq shortcut.

**Application/let/projection inference, general constant type ownership, full DefEq, environment/local declaration expression fields,
external-session delta/recursor/String-constructor behavior and declaration admission still use
the original recursive expression internally.** This once-per-batch decoder and
the complete fallback are transitional. The default original V1 API also remains.
Do not describe this architecture as the finished replacement or retire the
oracle before the remaining semantic migration qualifies.

Kernel fuel4096 is a recursive bound, not a globally spent instruction count.
Public/core WHNF entry order, recursion-depth guards, C0 beta-spine batching and
expression-derived substitution bounds are preserved. Default DAG transforms use
cached depth after validation: the old expanded count+1 was already capped to
that depth. The native depth/count lemmas justify that numeric cap, not full
substitution refinement. Bounded zero-fuel transforms retain the input subtree.

All seven original semantic caches are restored when leaving a local scope;
only the maximum fresh-name counter survives. FVar-containing terms cannot
publish semantic cache knowledge across contexts. Same numeric IDs in separate
arenas are unrelated. The portable profile exposes internal helpers/records;
the documented checked boundary, not a sealed constructor type, establishes
canonical arena/decoded correspondence.

## Function-normalization migration (qualified at463d956)

The production slice at 50dd83b replaces the stateless WHNF fragment with an
operation-owned core cache and threads it through function-position and result
normalization. It directly handles beta/zeta/metadata function heads, preserving
the original predecessor fuel for both calls. Alpha-equivalent keys with
different IDs use collision-safe structural lookup and return the first stored
result syntax; FVar-containing keys are ineligible. Fuel/depth checks precede
hits. The public wrapper always starts empty and discards its internal cache.
Unsupported constant/local-let/recursor/projection/primitive paths still restart
the complete original checker with the original resources.

New native and generated tests cover distinct-ID cache hits, exact cached
syntax, a real hash collision, warmed-cache fuel/depth entry guards, local-scope
exclusion and complete public checking. Three local proofs establish empty
initialization and flag-based lookup/publication exclusion; they do not prove
arena ownership or global cache correctness.

The same complete-public benchmark now includes shared heads, copied
alpha-equivalent heads, unique tags and hash collisions at depths8/32/128.
Native samples use isolated processes with actual peak RSS and matching official
check+WHNF; official Lean exposes no PS fuel parameter. JS retains isolated
A-B-B-A, cold/warm, construction and post-GC heap measurements. An untimed raw
diagnostic reports actual cache growth after the public timing/memory snapshot;
it explicitly does not measure hit/miss/probe counters. No cache eviction or
fuel change is allowed.

Native complete-public checked WHNF results at 50dd83b, depth128 and ten calls
per isolated worker (two repetitions), are:

| Shape | Original PSKernel warm ms | DAG warm ms | Official Lean check + WHNF ms |
| --- | --- | --- | --- |
| Shared function head | 17.106–17.400 | 5.611–5.975 | 0.485–0.492 |
| Alpha-equivalent heads | 17.673–17.775 | 7.252–7.348 | 0.603–0.617 |
| Unique metadata tags | 30.684–31.040 | 11.999–12.126 | 23.142–23.380 |
| Deliberate hash collisions | 40.750–42.118 | 42.434–42.482 | 23.131–23.567 |

There are real smaller-workload regressions: alpha-equivalent depth8/100 calls
is 3.013–3.098ms DAG versus 2.443–2.499ms original; collision depth32/40 calls
is 16.590–16.997ms DAG versus 14.588–14.661ms original. The slice is not
generally performance-qualified. Across all 72 isolated workers peak RSS ranges
overlap: original 68,424–71,404KiB, DAG 68,352–71,212KiB and Lean
68,140–71,208KiB. These are process peaks, not allocation/retained-heap measures.
The benchmark's fuel4096 field applies to PSKernel only; official Lean uses
its own internal resource policy. Generated stateful timing/heap results remain
pending.

A focused follow-up delays construction of the recursive structural-equality
worker until a child comparison is needed. Identity, hash and scalar-shape
short circuits otherwise created an unnecessary chain of closures proportional
to cached depth. The comparison budget, validation/error order, memo lookup and
collision fallback are unchanged. Existing exact resource/semantic regressions
and complete-public collision/alpha workloads are the qualification gates; no
performance gain is claimed before their new native/generated measurements.
Native benchmark receipts now explicitly label fuel_scope=pskernel_only so
official Lean rows cannot be mistaken for the same PSKernel fuel mechanism.

## Nat and projection migration (native qualified at58fab; generated pending)

The production WHNF worker now preserves a fixed public callback during core
recursion and owns separate core/public caches. Public cache lookup remains
before core recursion-depth entry, while public fuel-zero remains first.
The owning environment, local context, maxNatSize and all other semantic policy
fields are fixed for the operation; only recursion depth varies internally.

The new Nat worker reads DAG nodes directly, performs successor and all fourteen
supported binary reductions, and constructs results directly in the same arena.
Primitive arithmetic/count/numeral checks have one shared scalar implementation;
the original checker keeps a small result-construction wrapper. The existing
PSKernel rule that BOTH arguments of any binary empty-level constant application
are normalized before primitive recognition is preserved. Pinned Lean 4.35
recognizes primitive names first; the finite-fuel PSKernel ordering is preserved
as published, not silently relabeled as identical official resource behavior.

Projection normalizes the major through the public callback, reads admitted
constructor name/parameter-count metadata, selects the existing field ID, and
recurses with the original predecessor core fuel. Failed selection returns the
exact original projection. Changed application heads retain the extra rebuilt
core recursion. Nonrecursor heads can remain stuck; active recursor/Quot heads,
actual delta targets, local let values and String-major constructor expansion
still request complete original-checker fallback. No legacy tree is imported by
these new workers. Full inference/DefEq/admission and those remaining reductions
have not yet migrated.

Native and generated additions exercise all primitive outcomes, numeral/count
limits, zero division/modulus, nonprimitive argument evaluation, real Nat
admission plus checked successor, real two-field inductive admission, correct
and invalid projections, changed function heads, exact resource errors and
environment isolation. Native also compares fourteen ordinary Nat reductions
against pinned official Lean. New local public-cache initialization/FVar
exclusion proofs extend the existing local claims; they do not prove full
cache-result validity. These additions passed the native gate at58fab; generated qualification is pending.

Canonical PS runtime qualification now reuses the complete compiled bundle for
the same strict DAG/transform smoke in a detached directory with PATH empty,
in addition to the existing complete V1 smoke. Counts continue to come from the
dependency manifest. Native and generated full-checker benchmarks remain required;
no new Nat/projection performance improvement is claimed.

## Definitive quick DefEq migration (this commit; qualification pending)

The production DAG path now implements the original fresh-operation entry rules:
fuel and recursion-depth guards, collision-safe structural equality, Sort universe
equivalence, literal equality and paired metadata descent. Sort/literal rules can
return definite false as well as true. All unsupported pairs request the complete
original operation with its original resources. Both operands are still fully
checked before a direct result can be observed.

This worker intentionally has no reusable semantic pair cache. Its metadata
descent is linear and starts from the empty state used by the public API; no
sibling can observe a prior result. It is not an existing-state recursive DefEq
callback. Constants with equivalent universe arguments are not moved earlier:
the original algorithm reaches that rule after reductions, which matters to fuel.

New native/generated fixtures compare 12 decisive cases and 4 explicit fallback
families, fuel0–64, entry depths0/15/16, nested metadata, real literal hash
collisions, wrong-typed operands and exact public error variants. Native also
compares the 12 corresponding raw judgments with pinned official Lean. Two local
lemmas prove arbitrary-arena fuel-zero and recursion-depth-error precedence over
syntax; they do not prove full DefEq refinement. Tests and proofs are pending CI.

## Expanded complete-operation measurements (this commit; results pending)

The isolated JS A-B-B-A driver now also times checked Nat.succ chains, constructor
projection with a deeply wrapped unselected field, and paired-metadata DefEq
whose operands are structurally distinct. Nat/structure environments undergo
real ordinary-inductive admission; its wall time is reported separately from
input construction and complete public calls. Nat reductions check the exact
expected numeral, projections the selected sort, and DefEq the strict Boolean.

The native driver adds isolated paired-metadata DefEq workers for original
PSKernel, DAG and official Lean. Official workers check both inputs before
calling the official DefEq operation. Only each measured representation is
constructed, and each process reports cold/warm time and peak RSS. The PS
fuel remains4096; official Lean uses its internal policy. New measurements
are pending Actions and cannot yet support a performance claim.

## Latest generated whole-checker measurements

[The463d956 integration log](https://github.com/dwijayuda/pskernel/actions/runs/39514448898)
records isolated A-B-B-A workers at unchanged fuel4096, full public checking,
validation/decoding included, and fresh semantic caches per public operation:

| Complete operation | Repeated calls | Original warm ms | DAG warm ms |
| --- | --- | --- | --- |
| Metadata DefEq, depth96 |4|676.665–678.099|57.260–59.817|
| Shared-function WHNF, depth128 |1|1025.213–1074.086|441.722–447.103|
| Unique-function WHNF, depth128 |1|1679.600–1694.843|1151.830–1158.018|
| Collision-function WHNF, depth128 |1|4268.574–4283.050|3524.619–3617.324|
| Zeta check-only, depth8 |3|85.236–85.618|98.839–99.623|

Memory remains a qualification gap. Unique-function depth128 peak RSS was
248,492–248,936KiB original versus 293,156–294,992KiB DAG. Post-GC heap was
21,356,528–21,356,800 bytes original versus 25,893,536–25,896,056 bytes DAG;
within-worker retained deltas were 34,664–35,024 versus70,968–206,576 bytes.
The separate untimed DAG diagnostic found 256 core publications, no shadowed
equivalent keys and zero appended nodes for that fixture. It does not measure
allocation or hit/miss/probe counts. These figures establish improvements on
specific complete operations alongside real memory/small-check regressions,
not general production performance acceptance.

## Milestone matrix

| Milestone | Implementation | Native correctness | PSC1 / PS / JS | Whole-checker performance | Status |
| --- | --- | --- | --- | --- | --- |
| Paged representation | Single production owner; all 12 families; exact cached metadata | Forgery, collision, sharing, page and reference tests pass | Qualified foundation; current complete closure builds | Construction and validation included in complete-operation measurements | Integrated foundation |
| Transformations | Lift, instantiate/multi/reverse, abstract, universe substitution, spines; scoped memo | 1,755 comparisons plus budget/sharing/negative cases pass | Authentic source and strict generated transform smoke pass | Large shared-DAG fixture; not a full checker speedup claim | Integrated prerequisite |
| Checked DAG ingress | One replay/decode per batch; complete V1 command and declaration families | Positive/negative/fuel/admission regressions pass | Strict standalone generated smoke passes; canonical closure check passes | Adapter cost retained; some fallback checks remain slower | Transitional |
| WHNF | Function normalization, separate core/public caches, Nat, constructor projection and same-batch delta | Native parity and boundary gates pass at c9868 | Independent generated and canonical executable gates pass at c9868 | Controlled checked-WHNF gains; mixed memory and fallback regressions | Partial; local-value slice awaiting CI; recursor/iota/String migration open |
| Inference and DefEq | DAG syntax-directed checking with owning constants/projections/lets, stateful App conversion and scoped quick DefEq; unified inferOnly worker added | Native Let/App gates pass at106387/2be592; new3,780-case inferOnly and six official checks pending | c9868 fully qualified; later generated/canonical jobs pending |128 guarded ABBA observations; latest generated comparison pending | Partial; inferOnly slice awaiting CI; general DefEq remains open |
| Declaration admission | Direct axiom/safe-partial definition/opaque path; ordinary/mutual input type IDs retained after original admission |416 fuel/depth comparisons, four official admission fixtures and shared-state/safety guards pass at5b131 | Authentic source accepted; generated/canonical runtime pending |24 matched observations plus untimed direct capability diagnostic pending | Partial; theorem/unsafe-recursive/mutual/inductive migration open |
| Canonical self-hosting | Complete production import closure derived from manifest | Pinned Lean build passes at c9868 |112 canonical modules /1,353 declarations; authentic PSC1, TS7.0.2, declarations/maps and detached JS pass | Generator/runtime costs measured; six profiles pass | Current partial integration qualified; DirectJS unsupported |
| Lean Arena | Complete193 corpus; all-list transport and nested outcomes repaired | Official122 accept /71 reject | c9868:166 matches,25 host timeouts,2 safety agreements;135 controls; all193 recorded | Every timeout reached RunDag entry; internal hotspot unresolved | **BLOCKED:25 host timeouts; no exclusions** |
| Formal invariants | Composite metadata, scope/cache guards, budget cap, five numeral recurrences and exact constant-rule factorization | Native proof gates pass at c9868 with approved logical axioms | Proofs intentionally outside portable executable closure | No formal allocation bound | Global DAG/substitution/DefEq/admission soundness remains open |

## Latest matched native measurements

Run39512106401 uses the same pinned toolchain, fuel and correctness guards.
DAG time includes public validation/decode. Input construction is separate.
These are two A-B-B-A observations per variant; no generalized improvement follows.

| Complete public operation | Fixture / calls | Original ms | DAG ms |
| --- | --- | --- | --- |
| Check | Metadata96 / 600 | 68 / 67 | 13 / 14 |
| Check | Zeta96 / 50 | 17 / 17 | 18 / 18 |
| Checked WHNF | Metadata96 / 300 | 34 / 34 | 7 / 8 |
| Checked WHNF | Zeta96 / 50 | 32 / 36 | 19 / 20 |
| Checked WHNF | Zeta192 / 20 | 44 / 56 | 25 / 26 |

Generated Node22 checked WHNF in the green269552f generated job also improves:
Zeta24 (two calls) original136.434/141.860ms vs DAG73.340/70.592ms;
peak RSS233,912/233,804KiB vs184,712/189,380KiB. Zeta48 (one call)
is110.821/117.433ms vs69.356/68.058ms. Ordinary zeta type checking still has
adapter overhead (depth24:59.389/63.765ms vs66.908/67.939ms).

The generated harness reports cold/warm full calls, construction, isolated-worker
peak RSS and post-GC heap. Earlier qualified numbers and adapter regressions are
retained below. Allocation, actual semantic cache hit/miss counts and trampoline
costs have not been fully instrumented. Do not infer them from GC event counts.

## Arena evidence and profile

The authenticated round-2026-09 archive has193 cases and SHA256
`98a69742b538296c5f413d0527dfeef8c4d1815fe64b12c8623cd33de63bee0d`.
Official run [39510753165](https://github.com/dwijayuda/pskernel/actions/runs/39510753165)
passed all122 historical good and71 historical bad cases, with positive/negative
controls and no exclusions or remaining timeouts. Only the metadata header was
adapted to the pinned4.35 commit; declaration-body bytes are hash-verified as
unchanged. This is not a fresh native4.35 export and is not independent-kernel
qualification.

The new host transport constructs direct DAG input, invokes the real complete
admission API once, and compares every supplied exported constant/constructor/
inductive/recursor field with the regenerated environment. Exported recursor
rules are never installed as trusted rules. Exact integers and duplicate keys,
invalid references, forged recursor counts/RHS and constructor metadata have
explicit controls. Unrepresented all-lists, oversized UInt32 hints and unsafe/
partial contract differences remain explicit outcomes. Projection type names
participate in dependency ordering. Blank records and non-LeanExport fvar/mvar
wire constructors are rejected; internal expression support is unaffected.

The comparison records every case, distinguishes kernel/metadata/transport
rejection from unsupported and host/kernel resource failures, and fails the full
gate if any case is unmatched. Node executes in a detached directory with empty
PATH; fuel remains4096. Host timeout60s, heap2GiB and two workers are reported
separately. Never turn an OOM/timeout into a semantic rejection or silently
remove the case.

## Next implementation obligations

Complete the operation-owned DAG WHNF state and function-position normalization
with exact cache-key, value, fuel and depth parity, then qualify its cache-heavy
complete-check performance. Cache eviction cannot be used to bound memory:
removing an existing hit can alter fixed-fuel acceptance. List lookup scalability
must be measured before broader migration.

Then migrate environment/local values and checker state to one owning arena,
followed by full delta, recursor/iota, projection, supported primitives, general
inference, lazy DefEq, universes, proof irrelevance and inductive admission.
Retain every established rejection and resource decision. Extend formal replay,
substitution and cache-ownership invariants; do not substitute test counts for
those obligations. Retire legacy adapters and duplicate research algorithms only
after replacement qualification. Keep the full193 independent report and final
Actions results visible throughout the remaining work.

## Historical evidence (superseded where the checkpoint above is newer)

## Execution evidence and corrections

- Commit 953de3067cf285f42ab74fa2cbde43b6ae977aba, run
  [39502809730](https://github.com/dwijayuda/pskernel/actions/runs/39502809730):
  native DAG, adversarial, fuel/depth, official Lean fixture and existing V2
  regressions passed. Authentic PSC1 source checking and JS/declaration/map
  generation passed. Generated runtime gate failed because its harness tried
  to access erased structure constructors; corrected to typed object records.
- Source audit found the JS expression comparator is curried. The older smoke
  harness and initial new harness treated a returned function as truthy.
  Corrected both-stage application, strict Boolean assertions and unequal-term
  sentinels are mandatory before treating JS semantic assertions as evidence.
- Commit 68508d13054d45bf6c244605511662245fc4209d factors one constant rule
  shared by original and DAG inference, preserving lookup/arity/safety/cache
  order. Native compilation of production source succeeded; the new benchmark
  target collided with Lean's global `measure` name. The target now uses a
  unique name. Run [39503690997](https://github.com/dwijayuda/pskernel/actions/runs/39503690997)
  is retained as failed evidence, not a passing qualification.
- Complete-check performance harnesses include validation and decoding, with
  A-B-B-A generated workers, cold and warm samples, construction, peak RSS and
  post-GC heap. Results remain pending. Native samples also compare official
  Lean on matched checked metadata/zeta terms; no generalized speedup claim.

## Current production integration slice

The paged Node/Entry, storage, smart constructors, replay validator and
collision-safe equality now have single owners under `Core/ExprV2`.
Scalar syntax and hash helpers have been extracted without semantic changes.
Research import modules forward to those owners. The production foundation
imports no Research module, recursive expression type or checker cache.
Decode remains a separately named transitional adapter.

Terminal checking and terminal WHNF operate on DAG nodes. Public DAG DefEq
fully checks both operands, applies the original entry resource guards, and
uses same-arena collision-safe structural equality for syntactic success.
The pair memo starts empty and is discarded per operation. A false syntax
result always falls back to full DefEq; it is never a negative DefEq verdict.
Composite checking, other reductions and declaration admission remain legacy.

Native run [39504184911](https://github.com/dwijayuda/pskernel/actions/runs/39504184911)
on 7ac92b1737504d01a56c14f0abc9aeeeed75a4f7 passed expanded exact check/WHNF/
identity fuel-depth parity, adversarial inputs, official comparison, existing
V2 regressions and the matched native performance harness. Its generated job
was still pending at this work-state update. The subsequent structural-equality
promotion requires new CI; this earlier result does not qualify later code.

| Native complete check fixture | Calls per phase | Original ms, A/A | DAG ms, B/B | Official Lean ms, first/last |
| --- | ---: | --- | --- | --- |
| Metadata, depth 32 | 1200 | 26 / 26 | 10 / 10 | 2 / 2 |
| Metadata, depth 96 | 600 | 67 / 72 | 13 / 15 | 3 / 2 |
| Metadata, depth 192 | 300 | 104 / 102 | 13 / 13 | 2 / 3 |
| Zeta, depth 32 | 100 | 6 / 5 | 7 / 7 | 2 / 3 |
| Zeta, depth 96 | 50 | 16 / 16 | 18 / 17 | 3 / 4 |
| Zeta, depth 192 | 20 | 22 / 23 | 22 / 23 | 3 / 2 |

DAG times include validation and decoding on every checked public call. Inputs
were preconstructed. The native clock is millisecond resolution; combined
construction was below that resolution. The metadata slice improves on these
fixtures, while zeta exhibits overhead or parity. These finite cases do not
establish a general kernel speedup or satisfy full migration acceptance.

Generated run 39504184911 has now also passed on 7ac92b1: authentic PSC1
checking of 1,173 declarations, TypeScript 7.0.2, JS/declarations/maps, real
positive/negative checks and admissions with PATH empty, and isolated Node22
A-B-B-A samples. This does not qualify the later foundation commit.

Generated metadata check samples (original vs DAG total milliseconds):
depth32/6 calls 217.115,215.529 vs 83.133,86.491;
depth96/4 calls 340.132,319.812 vs 77.781,80.440;
depth192/2 calls 363.929,391.873 vs 63.011,63.327.
At depth192, isolated peak RSS was 213,964–214,816 KiB original versus
140,424–140,588 KiB DAG; post-GC heaps were about19.23MB versus19.11MB.
DAG input construction cost was22.6–22.8ms for5 inputs versus0.708–0.710ms.
Generated zeta checks regressed: depth8/3calls90.463,94.854ms original versus
123.351,126.853ms DAG; depth24/2calls103.756,108.923 versus138.612,141.043;
depth48/1call101.532,95.461 versus117.685,123.007. The legacy fallback plus
input adapter is not qualified as a general replacement. Production default
V1 APIs retain the existing complete checker. Native/JS batch-throughput and
additional checked WHNF/DefEq measurements are being added; they do not erase
these observed regressions. Allocation counts and detailed cache counters
remain unmeasured.

### Consolidated foundation qualification (2026-10-20 UTC)

At implementation commit `713bd35a3959a4b7fb44cff3eb8c9857c84b2a6c`, both
[production DAG integration jobs](https://github.com/dwijayuda/pskernel/actions/runs/39505188175)
and all six [research jobs](https://github.com/dwijayuda/pskernel/actions/runs/39505188468)
passed. Authentic PSC1 checked 1,136 declarations in the complete SelfHost
closure. Generated TypeScript 7.0.2/Node 22.23.3 executed the complete kernel
and strict DAG assertions. The generated source was 5,138,980 bytes; smoke
peak RSS was 270,756 KiB and post-GC heap 36,843,824 bytes. These are whole
smoke-process observations, not an allocation bound or proof of soundness.
The corrected combined bridge passed its unequal-term sentinel and actual
result comparisons (1,315 declarations in that larger research closure).

The historical whole-JS and memory-probe harnesses also contained the curried
`psKernelExprEq(a,b)` truthiness bug. Their timing observations existed, but
those equality guards did not establish semantic equality. The integration
work now corrects both to `psKernelExprEq(a)(b)`, requires strict Booleans,
and checks an unequal sentinel before measurements. They must be rerun before
using their assertions as qualification evidence.

### Next transformation slice — qualification pending

The integration branch now includes one production generic DAG visitor for
multi-variable/reverse instantiation, abstraction, universe substitution, and
application spines. The bounded zero-budget behavior preserves the original
subtree. Memo keys include effective remaining depth and binder offset. The
actual default worker budget is capped by validated depth before constructing
recursive closures, avoiding expanded-tree fuel allocation on shared DAGs.
Native fixtures cover every expression family, partial-budget memo reuse,
forged graph data, and a 24-level shared graph without materializing its tree.
These additions are pending native and authentic PSC1/generated qualification;
the complete checker migration is still unfinished. The following integration
slice connects the canonical visitor to public checked zeta WHNF.

### Complete executable qualification expansion — pending CI

The original correctness workflow now runs on this integration branch and
derives the complete canonical source closure from imports, comparing it to
the reconstruction manifest instead of hardcoding 79. Exact Lean commit,
TypeScript 7.0.2 output, declarations, source-map structure, and detached Node
execution are checked. The generated .ps checker smoke now performs checking,
inference, beta/zeta/delta/iota, positive/negative DefEq, declaration admission,
ordinary and mutual inductives, cache-scope tests, and zero-fuel rejection.
Its previously vacuous curried equality assertions are fixed and sentinel-tested.
DirectJS is probed separately: known non-scalar/generic emitter limitations
are explicitly reported as unsupported, never as passing kernel execution.

### Checked zeta integration and local proof work — pending CI

The public DAG WHNF operation now calls the canonical DAG substitution visitor
for its terminal/metadata/zeta slice. Public and core WHNF keep separate exact
fuel and recursion-depth rules; unsupported reduction forms restart the original
operation with its original resources. Only newly appended result nodes are
decoded. The operation does not publish semantic cache state or carry a memo to
another command. Full beta/delta/recursor/projection/primitive migration remains.
DAG terminal-inference and reduction workers now delay recursive worker creation
until a branch needs it; this preserves numerical fuel and avoids allocating an
unused predecessor-fuel closure chain. No legacy substitution worker was changed.

Native proof files state conditional local metadata preservation for the six
composite entry builders, exact restoration of all seven scope-sensitive cache
fields, and fresh-counter/FVar-eligibility facts. These are pending proof-checking
in CI, not proofs of replay validity, substitution refinement, all cache uses,
DefEq, declaration admission or kernel soundness. No executable path imports them.

### Refreshed checkpoint (2026-10-21 Asia/Jakarta)

At `2760f486a0efc7e3631725c8f1c657fb97c3fafb`, native integration and the
original native correctness gate passed. PSC1 parsing failed on projection
from a parenthesized product expression in Transform.lean. The replacement
uses an ordinary let-bound record projection, without expanding the language
profile. The generated research bridge also encountered a Lean-download TLS
failure before compilation. Neither failure is reported as a passing gate.
The last fully green integration/research checkpoint remains
`69de396ec537c8130b87388ba8045859e443141b`. The 1,755 native transformation
oracle comparisons passed at `7ffd17f707225645c9aa2bc5282cbae2bcdbbee8` and
again at the following documentation/qualification checkpoint. Generated
transformation execution, the new checked zeta path, local proofs and expanded
canonical checker smoke still require successful CI on their implementation.

### Native zeta and local theorem evidence

Run [39509139906](https://github.com/dwijayuda/pskernel/actions/runs/39509139906)
passed native integration at `d0ad5dac3d0e057dec0bd5edd9ff4d797c0f8d77`,
including checked zeta fuel/depth parity, 1,755 transformation comparisons,
and all new local metadata/cache-scope theorem checks. The original native
correctness job in run39509139873 also passed. Generated and canonical .ps
qualification remain pending. Additional flat-pattern source fixes and strict
generated transformation tests are included next; they require their own CI.

### Complete Arena reference execution — pending CI

The new reference workflow evaluates every one of the 193 cases from the
SHA256-pinned round-2026-09 archive using official Lean at the exact 4.35 pin.
It records each verdict, original/adapted hashes, byte-identical declaration
body hashes, timeouts and driver errors. Only the historical first metadata
line is adapted; this is not a native 4.35 re-export or unchanged-envelope
qualification. No case, including performance cases, is excluded. Accept/reject
controls guard the oracle. This job establishes official reference coverage;
it explicitly does not establish PSKernel-Core corpus compatibility. A current
strict DAG transport with generated-recursors metadata comparison is required
for the independent checker. The older adapter's high fuel and dropped recursor
metadata are not reused.

Authentic PSC1 rejected the initially delayed recursive call form with
`structuralRecursionArity` in Terminal.lean. The supported form now binds the
one-argument recursive call inside the delayed lambda, then applies the local
function to context/arena/root. This retains the delayed computation without
changing the compiler, declared API staging, resources or semantic branches.
Application-spine reconstruction also matches its decreasing argument list at
the top level as required by PSC1 structural-recursion elaboration. These
source-profile corrections are pending authentic PSC1 validation.

The first complete Arena reference run39509681088 evaluated all 193 cases:
120 accepted,71 rejected,2 official-harness timeouts, with both controls passing.
The timed-out cases were good/perf/magma-list-deep-n36.ndjson and
magma-list-pair-n21.ndjson. No cases were excluded. The host timeout originally
killed lake without reliably reaping its leanchecker child; the harness now
kills/reaps the isolated process group. The official-reference wall cap is
300 seconds with two workers so the two performance cases can be evaluated.
PSKernel's fuel4096 and its published resource policy are unchanged. Corpus
coverage is not called complete until all actual verdicts are observed.

### Direct beta-spine integration — pending qualification

The checked DAG WHNF worker now handles direct syntactic lambda heads using
C0's simultaneous reversed-argument substitution and remaining-spine rebuild.
Both original core calls retain their exact predecessor fuel/depth. New native
and generated tests include multi-binder reversal, partial/overapplication,
nested beta/zeta, low budgets, and a cache-sensitive case which explicitly
requires fallback. General function normalization still needs operation-owned
structural core caches; erasing those caches would change low-fuel outcomes.
The implementation remains partial and is not yet a full DAG-native checker.

### Transformation elaboration and redundant count removal — pending CI

The next authentic PSC1 error was an untyped match RHS in TransformLeaf
(`matchExpectedType`). Explicit result annotations now cover both such RHSs;
this uses the existing language profile. Default canonical transformations
now read exact cached depth directly instead of traversing the graph to compute
an expanded count that the worker immediately caps to depth. A native lemma
checks depth <= recursive node count and the corresponding cap equality. The
explicit bounded API and all checker fuel limits remain unchanged. Global
validated-arena correspondence and substitution refinement remain unproved;
conditional local metadata lemmas and finite parity tests do not imply them.

### Full reference corpus observed; independent replay gate added

Run [39510753165](https://github.com/dwijayuda/pskernel/actions/runs/39510753165)
on dd466701 evaluated all 193 cases: 122 accepted, 71 rejected,zero timeouts,
both controls passed. This is official Lean reference evidence only. The
complete independent comparison gate now reconstructs the canonical .ps kernel,
compiles real TypeScript7.0.2/Node22, exercises adversarial transport controls,
and runs every adapted body in a detached process with PATH empty and kernel
fuel4096. The host limit is60 seconds/2GiB per case, explicitly separate from
kernel resources. Nonqualifying outcomes fail the full gate after writing all
results; unsupported inputs and resource limits are never counted as matches.
The adapter builds paged expressions directly and validates every supplied
exported constructor/recursor/Quot field against independently admitted data.
It does not install exported recursor bodies. Metadata-kind counts and actual
checker invocation are recorded. Noncanonical all-list metadata remains an
explicit transport limitation. General V1 admission still uses legacy internal
expressions, so a corpus pass would not establish a complete V2 migration.

The beta native build failure was a missing explicit Lake root registration,
not a semantic-test result; that registration is now included. Authentic PSC1
accepted the complete .lean source at dd466701. Its canonical/generated runtime
and the new beta/native proofs still require their own passing evidence.

### Generated transform harness ABI correction

Run [39510753173](https://github.com/dwijayuda/pskernel/actions/runs/39510753173)
checked all 1,225 source declarations with authentic PSC1 and built the complete
TypeScript 7.0.2 / JavaScript executable, declarations and source map. Execution
passed the preceding DAG/admission/negative checks, then the strict oracle-value
guard rejected the first bounded transform comparison because the host harness
under-applied a returned function. Erasure's actual ABI curries each function-value
arrow, while known declaration entries retain flat arguments. The seven affected
bounded-transform and raw-WHNF test calls now follow that ABI. The strict guard
remains; this correction has no kernel or fuel-policy effect and awaits runtime
qualification. Native Beta module registration was corrected in c29f418.
