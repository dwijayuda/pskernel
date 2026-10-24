# PSC1 compiler self-host architecture

Current direction: Python and PHP generations from the same frozen compiler,
after qualified DirectJS and import-free DirectWasm generations. [Roadmap](PSC1_DEVELOPMENT_ROADMAP.md) orders the
work; [AI work state](../AI_WORK_STATE.md) and the
[direct-target receipt](PSC1_DIRECT_SELFHOST_QUALIFICATION_2026-10-24.json) bind
live status to immutable source/CI identities. Qualified Rust and TypeScript
remain preserved reference implementations generated from the same compiler.

## Python/PHP measured mechanisms

The shared compiler frontend/elaborator/checked IR/service remains unchanged.
Each target has one Portable emitter and a thin native API adapter preserving
defaults and metadata. Explicit ordinary state/Except source is backed by seven
complete state and four arity equalities. No handwritten second compiler exists.

| Actual defect | Measured evidence | Mechanism and guard |
| --- | --- | --- |
| PHP quadratic global captures | First seed envelope1002108077 bytes,961724361 encoded source bytes and18816024 global-reference capture text occurrences; read-only40070297469. | Lexical global demand preserves reference identity/order and all local/helper captures. Exhaustion falls back to full legacy captures, with a zero-budget theorem, scope cases and independent capture-token boundary. Seed envelope falls to59452682 bytes. |
| PHP inductive storage and destruction | Next G2 exceeds1G while converting1.79MB wire to chars; heap trace holds seven pending generators. Packed arrays fit memory, but exact GDB40072628964 crashes with32 recursive zend_array_destroy frames. | Compact immutable ArrayAccess nodes expose flat tag/field positions, inline first/second fields and packed overflow. Queue descendants before clearing only already-dead nodes; drain references iteratively. Other owners preserve live children. Two-million-cell generated execution and two-million-node cleanup/shared/weak/cycle/refusal tests pass at1G/default stack. |
| Python repeated UTF8 encoding | Old G2 hits1800s; exact archived-G1 profile40071913715 spends118.890/120s in106950 encodes. | Shared get/next/extract/byte-size/end views use immutable identity snapshots:8 entries/32MiB encoded content, oversized views not retained.234895 retained-helper comparisons, retained/current emitted intrinsics, errors/eviction/identity/concurrency and AST/origin boundaries pass. |
| Unlisted Python bytecode | SourceFileLoader may execute a timestamp/hash .pyc absent from the artifact manifest. | Source-only617004ce compiles exact bound source bytes for service/probe/consumer. A matching poisoned cache executes under standard loader but is ignored by production. Compiler semantics stay generated; no native delegation. |

The post-UTF8 Python profile40075153915 measures str.encode0.132s/120s,
_psc_run own44.239s and56.67M generator sends. Shared DirectCalls.lean therefore
classifies exactly two immutable layers of synchronous nonzero-parameter global
functions. The intrinsic whitelist excludes callbacks; implicit zero-argument
value forcing, dynamic calls, shadows, recursion and exhausted analysis keep
the scheduler. Full names are checked after hash lookup. The direct source
call depth is at most3, independent of declaration order. Python's independent
AST guard checks saved callee/arguments, actual non-generator flags and acyclic
depth before restoring old yield nodes for exact remaining-AST comparison.
PHP compares direct and retained schedulers with identical runtime/carrier.
Both targets pass200000-deep dynamic alias/local/parameter-shadow recursion.
Gate40077267520 passes87 modules per target in both grammars and all admitted
library/retained regression guards. Genuine request809070eb/run40077476210 independently admits both G1s, passes
strict IR/all ten cases, then both G2 requests fail the1800s deadline. No G3/fixed
point. This source gate did not establish compiler-generation qualification.

PHP extraction separately allocates a full character array even for a short
substring. Exact archived compiler-source diagnostic40077973238 compares25100
valid/malformed/boundary/huge-index cases and16 slices from18804166 source bytes:
retained22.741s, proposed0.0243s. This is an actual compiler-source runtime
operation, not a whole-compiler speedup. Source9c4a9b38/registration94ea0e84 passes gate40078556459, including25100
emitted API comparisons and1MB slices: use the existing two-key UTF8 validity cache, check full input before
bounds as required, compare GMP positions against native size before conversion,
then slice bytes. Preserve early empty-range behavior, invalid/non-boundary start,
and the historical rule that a mid-codepoint stop extends through the string end.
No extra retained cache or stack/memory limit is introduced. The same emitter's
legacy layout policy keeps exact old extraction runtime bytes and dependencies
for differential tests; the default catalog permits only this complete helper
block and its utf8Valid dependency to differ. PHP-only source changes leave the
Python owned compiler closure unchanged.

Python's exact archived hot-worker AST audit40078613463 confirms self tails
without nested definitions in equality, JSON, list reversal and name lookup.
The new emitter loops only lambda-free exact global-self tails with nonzero arity,
no lexical shadow/type arguments and conservative4096 analysis fallback.
The saved callee and argument evaluation remain; the original fresh result
temporary snapshots the argument tuple before parallel parameter rebinding.
Other calls retain the scheduler. No frame is reused for a body creating a lambda,
so escaping closures retain distinct captured bindings. A separate retained
policy keeps the original scheduler output; existing WithIoAndDirectCalls API
retains its previous no-loop behavior.

Independent AST validation restores only the exact three-statement snapshot/
rebind/continue pattern to the original self-tail yield, checking original callee,
arity/arguments and lambda absence, then compares all remaining AST. Declaration
origins are checked against exact actual headers. Gate40079503171 at e20a1154
passes87-module/both-grammar censuses, all retained/admitted guards,43 loop
comparisons,2M steps,200k escaping-closure fallback, swaps and typed IO order/
first-error tests without changing Python recursion limits. Genuine Python
requeste6327cdd/run40079719620 and PHP extraction request1174300d/run40078954006
are active independently. Later Python-only source does not change the PHP
owned closure. Keep source stable and read terminal evidence before next fixes.
No current G2/G3/fixed-point success is inferred from these focused tests.

Strict IR already requires canonical constructor field order; the PHP emitter
evaluates in that order. Reordered construction remains refused, while match
bindings resolve indices by owner/constructor/field. Native legacy layout is a
policy of the same emitter for differential execution. Public aggregate ABIs
remain refused; records/arrays keep their existing source semantics.

Source/regression gate40073537409 at617004ce passes both complete86-module
closures in both grammars, proofs, retained boundaries and four independently
admitted runtime libraries. Current genuine generations are tracked by the
[Python/PHP receipt](PSC1_PYTHON_PHP_SELFHOST_QUALIFICATION_2026-10-24.json);
these focused tests alone do not qualify G2/G3 or fixed points. Existing
memory/stack/fuel/admission/IR/refusal policies are unchanged.

## Current qualified evidence — 2026-10-24

Executable source133e5892, request2d1f8244, Linux40062120079 PASSED actual
independently admittedG1→G2→G3 and exact fixed points for BOTH DirectJS and
owned import-free DirectWasm. Native compiler tools are disabled after one seed.
All generations pass strict original/transformed IR and ten positive/negative
observations. JS G2/G3824066/832426ms, maxRSS3076776/3179880KiB;
Wasm876840/888398ms, maxRSS1508096/1816228KiB. Different closures87/98modules
prevent interpreting these as a matched backend speed comparison.

Fresh clean audit40064496804, control36d917b0, restores no .lake cache. Its
independently checkedG1 reproduces exact source inventories, admissions, IR,
observations and raw target source/executable bytes of each qualifiedG1/G2/G3.
JS module.js SHA8dad2e7fb1e3eb834bed9fc7581b8f2cce36f834c5e7842f19b6f8bb904b871a;
owned module.wasm SHAaddc90b9cfff0dcbb8ea8d8f1d7824187750b5250514915608cda5607f170b72.
Operational manifests include events/timings/paths, so raw code equality is
recorded separately from service-manifest hashes. This audit is not a second
fullG2/G3 replay, DDC or formal compiler-preservation proof.

The final successful mechanism fixes address source classes: eleven owned JS
recursive-prefix bindings moved beneath all dynamic arguments; three Wasm
encoder list helpers use fully applied ordered reverse accumulators; shared
lookup prefixes defer work until their dynamic lookup name arrives. Complete
retained-original API equalities and class scans accompany actual generated
qualification. Earlier measured lazyUTF8/direct-dispatch and ordered collector
fixes remain. No representation rewrite, alternate compiler or resource-limit
increase was required. Original performance240s remains unqualified.

[Full40062210987](https://github.com/dwijayuda/pskernel/actions/runs/40062210987)
PASSED: Linux120780825013 and final gate120786364196;37/37 qualified,0 blocked,
releaseReady=true, all seven backends, both grammars, applications, minimum
Python and installed native package/IO/library regressions. Tested review HEAD
06186537cf9339fc3f24a7d13387c2ad55ee0749 and merge
980d096ca3e85b9ad2970f16602ad1d14a089d69 have identical Git tree
cbf312e1f4bca9e7085719c12b627be5c16099a7, verified through GitHub APIs and checkout log.
Artifact12549325904, digest
sha256:6ad48b109e2e995c344a6855a85de44380f6ee628b67f4033990a152598a7bf9.
This qualifies the tested compiler source; the final receipt update edits docs only.

Earlier diagnoses, old-source pending statements and architecture milestones
below are retained as dated history. The roadmap and current receipt govern
live status; later actual qualification supersedes those pending statements.

## Shared semantics and authority

All targets execute Ps.Internal.CompilerService.candidate, the same frontend,
elaborator, ordinary source/logical graph pairing, erasure, checked IR and
backend-neutral planning. Only target planning/emission and runtime carriers
differ. The host transports requests, invokes official independent Lean4.35.0,
validates tools/ABIs/artifacts and supervises resource limits. It does not parse,
elaborate, lower or print on behalf of a generated compiler.

A qualification uses a native seed once, then removes native compiler tools.
G1 must execute all positive and negative cases. Its actual emitted service
compiles the captured compiler closure to G2; G2 does the same to G3. Each
generation requires independent admission and strict original/transformed IR,
then the same executable observations. Fixed points compare exact captured
source closure, canonical admissions/IR/observations and target source bytes;
owned Wasm additionally binds decoded binary bytes. Same-run equality is
distinct from independent clean-build reproducibility or semantic preservation.

DirectJS uses a generator driver for ordinary/non-tail calls and conservative
statement loops for recognized self tails. Immutable parameter snapshots per
iteration preserve escaping value/function captures. Unsupported aliases,
fresh-name collisions and exhausted analysis fuel fall back to the old printer.

DirectWasm uses the existing owned GC binary emitter. The generated compiler
has no native imports. Its small host adapter copies scalar GC String/Nat/Int/
Bool/Unit values; it rejects unknown ABI/binary inputs. It cannot delegate
compiler semantics. BinaryBytes is the single bounded-Nat byte algorithm;
the native UInt8 surface is a carrier adapter. Internal raw float-bit metadata
is bounded Nat with explicit32/64-bit target validation. This does not admit
floating source operations or previously refused machine-scalar source IR.

## Retained artifact comparison boundary

Read-only Linux40035257537 validates exact archived JS40027650302 and qualified
TS39993829327 source/artifact/closure identities. No compiler executes in this
audit. JS has8,429 generator functions/3,889 generator IIFEs; qualified TS has
9,404/4,286. Common generated instantiate/name/equality workers have broadly
similar loop/driver shapes. Fewer generator sites alone is therefore not a
performance qualification or a sufficient diagnosis of the JS deadline.

The older JS executable is7,257,030 bytes with23,473 nested constructor-field
loads; TS executable is11,120,678 bytes with flat, type-tagged constructor fields.
These are different target closures and source snapshots, not a matched speed
benchmark. Retain the current representation and existing ABI pending measured
causality. Actual CPU evidence—not counts or file size—justifies the bounded
UTF8 views and direct driver dispatch already under execution. Avoid a second
compiler implementation or speculative representation rewrite.

## Patterns learned from actual generated compiler workloads

| Defect class | Mechanism and evidence | Required safeguard |
| --- | --- | --- |
|Recursive-prefix construction|A recursive worker bound before remaining dynamic input binders constructs unused closure chains eagerly. Large literal fuel made this catastrophic in Wasm.51 workers passed all-input equality. The next retained G2 map identifies a 52nd, the main lower-expression worker: its 335-character type exceeded the old regex bound. Its new patch defers the prefix under all four inputs and scans the actual owned Wasm closure without annotation-length bounds. A retained-original negative guard prevents that blind spot from recurring.|Keep original fuel/errors/APIs; verify actual generated execution as equality alone does not establish space behavior.|
|Declaration-spine reconstruction|Wasm G2 traces identify ordinary expansion, then psCheckedNestedCollect. An explicit ordered accumulator fixes ordinary expansion. The checked collector uses reversed declarations plus a complete Except-state fold to preserve its original rightmost-error priority; normalization preserves declaration/wrapper order.|Prove complete old/new API equality, exercise refusal priority and10000 declarations. Do not bypass canonical source/logical graph checks.|
|Generator allocation and captures|An actual retained JS G2 profile exposed generator/GC overhead. Statement loops remove per-let generator IIFEs while retaining the established driver for non-tail work.|Immutable iteration snapshots, alias/capture/hygiene/fuel negatives, native and retained-emitter comparisons, deep tail/non-tail execution.|
|UTF8 cache-key StringEqual|After statement loops, actual retained G2 profiling40024746671 attributes33.9% of ticks to V8 StringEqual. Port the qualified TS lazy-token pattern to eligible invariant JS self-tail loops. The fixture measures40000→2 cache-key lookups with identical results over10584 comparisons.|At most two indexed views; tokens retain no String/index arrays. Verify lexical aliases and recursive arguments, preserve position evaluation before lookup, reject shadowing/changing sources/freshness collisions, retain size-only non-admission and exact extraction fallback. Never replace source String equality.|

Erasure's subsequent actual G2 failure maps to psErasureDeclarationEntryIndex
via retained-binary/IR audit40027922448. The same source scan finds right-fold
reconstruction in index prepending and declaration-name indexing. A shared
fully applied reverse fold now handles all three. Full gate40028430603 at
52cff171 proves the generic fold and all three old/new APIs, preserving complete
index structures, duplicate first-entry precedence, insertion/count semantics,
exact error states,4096 entry-analysis fuel and16-bit index policy. Both full
source grammars and all earlier runtime/refusal gates pass; actual generations
must still qualify this changed common compiler source.

Subsequent Wasm G2 ran829660ms before a psListLength specialization on
PsWasmStructType exhausted the stack. The six non-tail foundation list APIs
(length/append/map/mapExcept/take/zip) now use fully applied accumulators with
all-input retained API proofs and100000-element ordering/error/truncation tests.
Full focused40031387906 passes all prior gates and both source grammars.

Actual retained JS profile40031550466 verifies the real String-equality worker
uses lazy tokens: StringEqual is0.1% of sampled ticks in that240s diagnostic.
The compiler still timed out in standard1800s G2. It contains12171 invoke and3693
tail-invoke sites; the helper and driver both perform a dispatch lookup for
registered functions. Direct emission now yields the existing driver packet,
preserving callee/argument order and tail semantics while removing the helper
generator. Full gate40032762325 passes64 foreign-function order/trap cases and
deep existing regressions; registered lookups40→20 and delegated fixture sites35→0.
These measurements motivate actual new G1/G2/G3 execution, not a timing or
fixed-point claim. The driver, private map and fallback helpers remain compatible.

Source normalization follows the supported grammars deliberately: explicit
constructor matches, typed callbacks, and fully applied structural workers with
deferred callbacks. Do not broaden the language or weaken recursion validation
to make a backend helper compile itself.

Native proofs and fixtures do not qualify self-hosting. Current attempts,
failures and immutable artifact identities remain in the receipt. Both direct
targets have executed independently admitted G1 with all ten cases; G2/G3 and
fixed points require successful actual generation chains after the fixes.
PR174 afed7c4b full CI passed37/37/all seven backends/both grammars/applications;
later compiler changes require their own full integration run.

G1/tool/corpus limits remain240s, independent checking120s, with unchanged
memory/stack, semantic fuel and negative/refusal policies. Manual G2/G3
correctness1800s is separate from the original performance240s profile. No
correctness receipt implies the shorter performance target or publication
authorization. The historical design below is preserved as dated evidence.

## Historical compiler-only design baseline

Decision date: 2026-10-21. This design concerns the compiler, not the owned kernel.
The source census baseline is immutable commit
da880d864ca5f9e35729255fd7e4f8a17953cd39. Live CI regenerates the inventory on
the integration checkout; baseline counts must not be substituted for that result.

## Selected boundary

Retain the existing pure compiler rather than reimplementing its semantics in a
Node or Rust host. Ps.Compiler.Api/Ordinary own parsing, elaboration, canonical
Core preparation and checked ordinary graph pairing. Ps.Erasure and
Ps.CompilerIr own executable construction/validation. BackendCommon and the
selected printer/lowerer own target planning and emission. Those modules do not
explicitly import Lean, IO or System at the inspected baseline.

The external host captures and resolves the ordered source closure, owns the
official independent checker, launches target tools and publishes artifacts.
Host source resolution is not compiler semantic elaboration. Passing an
untrusted candidate graph through the independent checker establishes logical
admission of that graph, not source-to-Core correctness or backend preservation.

| Selected phase | Baseline local modules | Lines | UTF-8 bytes |
| --- | ---: | ---: | ---: |
| Api + Ordinary semantic compiler | 66 | 31,122 | 1,227,616 |
| Semantic compiler + DirectJS plan/lower/validate/print | 78 | 39,289 | 1,547,280 |
| Semantic compiler + Rust plan/module emitter | 82 | 38,984 | 1,551,285 |
| Full native host closure | 131 | 61,513 | 2,476,295 |

These are explicit-import closures of production Lake roots, not a measured
runtime primitive census. The full host additionally imports native Lean.
Lean implicit Init/prelude operations remain runtime obligations even when
there is no explicit import. The committed baseline JSON has per-module paths,
Git blob identities, import edges and phase membership.

Do not include Main, host filesystem/process services, PsKernelLean or the
owned kernel in the generated compiler source closure. Historical
Ps.Bootstrap.SelfHost only imports the TS composition root; its outdated
4.34-Wasm comment is not qualification for current DirectJS/Rust self-hosting.

## Historical source-census blockers (2026-10-21)

The source was inspected, but inspection is distinct from running the new probe.

* CompilerIr.Validate uses deriving Repr. BackendCommon.Plan uses deriving
  BEq/Repr. ParseLean's declaration dispatcher recognizes def, partial def,
  theorem, inductive and structure; deriving is outside that dispatcher.
* Elab.Data contains private declarations. Rust.RuntimePlan contains private
  def/private partial def. Private modifiers are outside the same parser.
* ProjectCompiler.psHostPackageDirectory historically only mapped BackendTs.
  BackendCommon/Js/Rust/Wasm/Python/Php need explicit workspace fallback
  mappings. This is source resolution, independent of parsing.
* DirectJS.Print's new recursive helper and Rust.RuntimePlan's traversal must
  pass the actual source parser, elaborator, ordinary-body admission, executable
  IR and target runtime. Native compilation of those files does not establish
  that PSC1 can compile them.

Fix source syntax deliberately. For tiny compiler enums, explicit supported
equality functions can replace deriving without introducing a generic deriving
framework. Debug-only Repr need not enter executable bootstrap source. Where
private helpers are migrated, assign collision-free qualified identities and
preserve the declared package/public surface; do not silently strip privacy
tokens or skip unsupported declarations.

The live census walks the selected import graph in dependency order. Each
module receives separate parse and elaboration status. A refused import blocks
dependent elaboration rather than creating cascaded fabricated failures.
Independent admission, IR, generation, generated execution and fixed points
remain explicit not-run stages until separately executed. A successful census
command means the inventory/probe completed, not that self-hosting passed.

## Versioned compiler/host protocol

Use psc1-compiler-host/1 and keep wire data separate from host authority.

1. Host captures exact bytes, source kind, stable module identity, entry module,
   import edges and dependency order. The ordered closure digest uses module,
   source kind and each file's UTF-8 hash. Absolute machine paths are diagnostic.
2. Portable core prepares the canonical candidate graph and its retained source
   work state. Ordinary compilation also retains the exact source/runtime graph
   and the separately admitted logical expansion.
3. Host pins the canonical bytes in a pending session. Generated code submits an
   admission envelope containing protocol/op, requestId, sourceClosureDigest,
   target and those exact admissions. Generated metadata cannot select a checker.
4. Host verifies exact field/identity/byte matches and invokes the separate
   official checker pinned to Lean 4.35.0 commit
   eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
5. Only the host's successful invocation creates its admitted session state.
   A wire receipt correlates request, source, graph, target and checker identity.
   The generated core can use that receipt to resume; constructing matching
   JSON cannot cause the host to publish.
6. Generated core emits validated executable IR/target artifacts from its
   retained work state. Host validates the staged target, exact public ABI and
   manifests and publishes only through its own admitted session. Hashes bind
   identity; they do not prove erasure or behavioral equivalence.

Rejected/malformed/stale/mismatched requests do not authorize output. Checker
failure consumes the checking attempt as rejected. Accepted sessions are
single use. No protocol field means behaviorally verified. External checking
cannot authorize arbitrary foreign contracts or unchecked axioms.

The implemented transport foundation consists of:

* Ps.Bridge.CompilerHost: pure request encoding and receipt correlation using
  existing portable JSON functions; no native services.
* host-tools/compiler-host-protocol.mjs: host-owned exact-byte session and
  independent checker invocation.
* compiler-host-protocol-tests.mjs: native stage 0 compiles the transport module
  into JS and Rust, then actual generated consumers exchange envelopes with
  the independent checker and exercise mismatch/refusal boundaries.

This is a protocol transport feasibility slice. Its small candidate graph comes
from native stage 0. It does not claim a generated parser, a generated compiler,
source closure self-compilation or a fixed point. The gateway does not yet
publish executable artifacts and is not the native CLI's publication path.

## Dependency-ordered implementation

1. **Inventory and source normalization.** Run the live stage census. Fix the
   first true unsupported source form in dependency order. Retain one source of
   compiler semantics; avoid a hand-maintained alternate bootstrap compiler.
   Acceptance: every selected JS closure file parses/elaborates in both selected
   input forms where claimed; no skipped declarations/imports. Record exact
   first refusal for remaining Rust-only files.
2. **Whole-closure preparation/admission/IR.** Run the complete prepared closure
   through official independent admission, exact ordinary graph pairing where
   needed, erasure and strict original/specialized IR checks. Add actual
   primitive requirements to the inventory from reached IR, not keyword guesses.
   Acceptance: no unresolved metas/unknown IR types/missing runtime intrinsics;
   fabricated wrappers, mismatched bodies and missing imports fail closed.
3. **Generated JS compiler service.** Add a supported scalar transport entrypoint
   around the real compiler preparation/emission functions. Generate JS using
   stage 0 once. Move filesystem/checker/tools/publication into the host session.
   Acceptance: generated JS compiles handwritten positive/negative language,
   scope, import, exact integer, Unicode and ordinary-control cases. Instrument
   the host's subprocess allowlist: no handwritten psc1 frontend/emitter call
   after stage 0; the independent checker remains allowed.
4. **JS self-compilation and repeat generation.** G1 compiles the same captured
   JS compiler closure into G2, and G2 into G3. Compare canonical admissions,
   validated IR and deterministic generated source/artifact identities under
   pinned tools; execute all generations on the same corpus. Do not infer a
   fixed point from compiling one unrelated fixture or from an unused wrapper.
5. **Rust compiler service and fixed point.** Reuse the same protocol and source
   preparation. Complete Rust-only closure, ownership/runtime/closure operations
   exposed by actual reached IR. Generate R1, execute its corpus, self-compile
   R2/R3 and compare canonical compiler artifacts plus runtime observations.
   Native executable byte identity is not required unless the locked build is
   demonstrated reproducible; canonical source/IR identity must be explicit.
6. **Portable host services and packages.** Package JS/Rust hosts, checker and
   runtime adapters with explicit dependency/tool pins. Add source IO/foreign
   adapters only as needed; broad foreign ecosystems and automatic refactoring
   are not prerequisites for first compiler-only self-host success.

Every milestone requires a named GitHub Linux run and actual logs/artifacts.
Failure categories remain source parse, elaboration, canonical admission,
erasure, IR validation, target emission, runtime, host protocol and fixed-point
comparison. Maintain the work state with the first actionable blocker, never a
percentage or a blanket “self-hostable” label.

## Concrete service identity and correspondence trust

For the first generated compiler service, the host launches a hash-pinned, CI-qualified generated executable/module and retains its owned process/channel and captured request identity. Bind the entire response, source/import closure, options, target and staged artifacts to that pending session. Caller-selected service binaries or arbitrary outside candidate JSON cannot enter checked publication.

This trusts the generated compiler's engineering correctness to the same degree as the existing native compiler. Exact graph admission and matching hashes do not prove source-to-Core, erasure or backend preservation. The host alone invokes the independent checker, validates IR/target/ABI and grants publication state. An arbitrary compiler plugin needs a separate certification/replay mechanism or candidate-only output. Never replace this boundary with hidden handwritten native elaboration, erasure or emission; that would invalidate compiler-only self-hosting.

Census the compiler+Rust-emitter closure independently of the JS service and record the shared union. Rust qualification also stresses deep source/AST/list traversal, non-tail calls and dropping the final owner of deep Rc DAG/tree values. Shallow cloning does not solve recursive evaluation/destruction; measure limits or use stack-safe workers rather than enlarging the process stack.

## Current qualified diagnostic checkpoint

At 5496943a30423269654fffcd7579b3c5dd16b4f9, run39495181966, the actual census is semantic-compiler 67/40/35; directjs-compiler 79/48/41; rust-compiler 83/49/40 (modules/parse accepted/elaboration accepted).
It covers Lean parse/elaboration only. Admission, IR, generated compiler execution
and repeated generations remain not-run, despite successful generated transport.

First parse refusal: Ps.Syntax.Ast35:41, ++ in psSyntaxBindingPatternNames.
The selected operator table has no ++. Normalize with a supported named typed list
append helper and rerun; do not skip the declaration or widen notation silently.
First elaboration refusal: Ps.Erasure.Definition, structuralRecursionArity.
A source-confirmed candidate is psErasureRuntimePreludeClosure: three authored
explicit binders followed by a returned list function, but a direct four-argument
recursive call. Use the established partially applied smaller-worker pattern.
The module-level diagnostic does not prove this is the sole failing declaration;
add per-declaration tracing and qualify the actual normalization before claiming a fix.

The finalized continuation prompt specifies dual-grammar strict census, whole-closure
admission/IR and actual generated compiler/fixed-point gates. Historical
checked-selfhost.mjs still uses lean434/PSC2 receipt profiles and is not current evidence.

## Current class-complete owned backend fixes — 2026-10-24

Focused40061782715 at133e5892 proves complete retained function equality for all
eleven remaining eager recursive prefixes in the owned JS backend. The scanner
covers233 actual owned definitions and rejects every retained original. This
includes the backend's own high-fuel lower/type/validate/alias/observed-print
workers, rather than only emitted application loops. Million-fuel early-result
and refusal tests pass; actual generated qualification remains required.

The retained Wasm trace40036672078 reaches private binary encoder flatMap on
function/value-type lists. The confirmed source uses non-tail list reconstruction.
The private flatMap, byte-chunk and UTF8-char helpers now use fully applied
reverse accumulators. Focused40061544936 and40061782715 prove all three complete
old/new APIs, exact output bytes/order and first-error priority, with100000-element
cases and the retained96-opcode/native/owned-GC comparisons. The top Nat division
frame is insufficient evidence for a separate arithmetic defect; no limit was
raised. This fixes encoding as a class rather than modifying individual inputs.

## Python/PHP source architecture — 2026-10-24

The qualified direct-target pattern separates one portable compiler implementation
from host transport, native adapters and independent checking. Apply the same
boundary to Python/PHP: CompilerService imports Portable; native Module preserves
its existing API and calls Portable. Default-argument/metadata compatibility
does not enter captured compiler source. Source capture still traverses all
registered owned imports and excludes test references/host/kernel/CLI code.

Original Python/PHP emitters used StateT, private declarations, default record
initializers, library methods and nested source patterns outside the supported
compiler grammar. The port keeps the same semantic operations and target text,
using ordinary functions State -> Except Error (Prod Value State), explicit
record constructors, ordered accumulators and flat case analysis. It adds no
grammar extension or alternate compiler. The source controller continues to
admit Id, Except and CompilerM; unimplemented StateT elaboration is not bypassed.

Native operation correspondence proofs bind seven complete state APIs.
Flat arity dispatch is compared with the original exact-list patterns for
arity1/2/3/5, including shorter, exact and arbitrary longer lists. Retained
original emitters are native test references only, outside every owned compiler
closure.144 output/refusal comparisons cover all output fields, not merely
execution results.34816 runtime selector combinations preserve raw helper text,
dependency order, duplicates and unknowns. Four actual source library probes
are independently admitted and executed across both grammars and both targets.
None of these fixture/proof results alone qualifies a generated compiler.

Full source census now reaches86 modules per target. Recursive workers bind a
partially applied smaller function below dynamic inputs; effects use explicit
Except constructors rather than contextual spellings inside match branches.
Keep exact errors, first-error order, lexical captures, declaration positions,
source/IR identities and all existing fuel/resource/ABI boundaries.

Next qualification uses the existing one-seed harness with Python3.14.8 and
PHP8.5.12/ext-gmp, interpreter hashes, unchanged240s G1/tools and120s checker,
and separate1800s correctness G2/G3. Original240s performance remains separate.
Generated source equality is distinct from operational manifest event/timing
hashes, clean-build reproducibility, DDC or formal compiler preservation.
