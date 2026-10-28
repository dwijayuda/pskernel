# Actual PSC1 modules: qualification guideline and blocking obligations

C1 continuation (2026-10-29): the [List signature component](PSC1_MIN_KERNEL_LIST_TYPE_GUIDELINE.md)
now supplies a constructive, independently specified type/scheme model and
actual worker refinement for all 21 List signatures, with 100 native/generated
observations. It is isolated from public admission. Counts below remain
1/124 admitted and 0/124 fully qualified. The next prerequisite is the actual
typed List body/history model, recursor and primitive contracts, and checker
refinement; Source C2 and all Min generations remain open.
The earlier diagnosis below describes the still-current public ground checker.


Current result (2026-10-28): **1/124 fresh actual source-module closures
Min-admitted; 1/124 also has finite native/generated runtime validation;
0/124 fully compiler-qualified.** No MinKernel-backed G1/G2/G3 is qualified.
The first module is `Ps.Foundation.Source`. These counts have different
completion criteria and must always appear together.

The [C1/C2/C3 completion contract](PSC1_MIN_KERNEL_USABILITY_PLAN.md) and
[full architecture research](PSC1_MIN_KERNEL_FULL_COMPILER_GUIDELINE.md)
remain binding. Prioritize an actual rejected compiler declaration and its
dependency impact before adding a proof or optimizing a traversal. All project
execution is GitHub Actions Linux only. The independent official checker is an
explicit regression oracle; it never substitutes for public MinKernel admission.

## Fresh evidence and scope

[Linux run 40704877559](https://github.com/dwijayuda/pskernel/actions/runs/40704877559)
passed at source `4e0bb6a7ba32f22effd6b814f31de51a5ebb1213`,
job `122874182518`. Artifact `12823741490` is 3669884 bytes with SHA-256
`bc028dd3dcf9c1e2c7186653d713de4d33275e284c93cceb32eca940fadda390`.
It contains matrix.json, MATRIX.md, source identities, record inventory,
fresh producer qualifications, exact refusal prefixes, kernel-blockers.json,
source-runtime/receipt.json and complete captured producer bytes.
The dated [machine receipt](PSC1_MIN_KERNEL_MODULE_QUALIFICATION_2026-10-28.json)
records this checkpoint. Subsequent adoption CI must keep its own SHA and run.

Adoption [run 40708696489](https://github.com/dwijayuda/pskernel/actions/runs/40708696489)
passed at `f27399e13f187957bb79e7dd20db9ca9a68c77eb`,
job `122887721077`. Its hash-verified artifact `12826040236` is
3671081 bytes, SHA-256
`bfecc7ed9cb6dd4ef86911dc4a63137598bfa2293e56a2292423e0f7d4c3abfb`.
The stricter fresh member/owner checks and closure-wide partial checks pass.
Counts and exact Source/consumer packet, IR and generated-code identities are
unchanged. The matrix retains 326 declared import edges and 827 combined
import/Core owner edges; 12 dependency closures retain partial-body obligations.

The denominator is the actual `Ps.CompilerUnified.Service` source closure:
124 modules, 2685282 source bytes, 4743 source Core / 4748 logical members,
3466 records, 115 implicit prelude declarations and 29889352 transport bytes.
Inventory SHA-256:
`2e2e1a9f0bd6bf4f1daf31995273162a5532dcd13a87f51c2cb9dd8fffe65f2e`.
Test consumers and kernel runtime modules are excluded from the denominator.

Every one of the 124 dependency projections was actually submitted to the
unchanged public byte API. Six import-free leaves were additionally captured
independently by the production source census; all positive projections require
this fresh capture. This is **not 124 fresh independent producer captures**.
A rejected frontier avoids repeatedly compiling its blocked dependents.
The matrix performs 136 public API calls including controls and refusal
prefixes; the Source runtime check makes one additional public API call.

Projection diagnostics: accepted 1, Core refusal 7, ASCII profile 30,
expression tag 38, byte budget 36, decimal 1, inductive domain 11.
These are rejection categories for the captured projections, not complete
semantic diagnoses or fresh producer results for every module.

## Matrix construction and admission gate

Record both explicit source imports and dependencies obtained from actual Core
constant/projection names. Map type, constructor and recursor members back to
source origins. Close both source dependencies and generated auxiliary record
dependencies; do not remove an inconvenient support declaration.
Retain exact source paths, SHA-256 identities, complete member coverage,
record indices, generated support and partial-body obligations.

The scanner preserves exact production record byte slices and parses one record
at a time. Large diagnostic packets can be reconstructed from retained global
bytes and record indices. This scanner is an untrusted diagnostic tool, not a
new parser theorem or admission authority.

A projection alone never increments admission. Require a fresh actual source
closure, successful source preparation and IR guards, complete fresh source
members, no extra source owners or unresolved partial bodies, exact canonical
bytes accepted by the unchanged standalone checkBytes API, and pinned official
replay. Cross-check the official version/commit and both byte identities.
Canonicalization removes exactly one final transport LF; no other byte changes.

Run each public query in an isolated 256 MiB V8 old-generation process with a
120-second deadline. Keep the 20-minute matrix job ceiling and existing focused
10/10/20-minute budgets. Timeout/OOM is a failure, never acceptance.
The adoption tightens fresh coverage checks and checks partial obligations
across the entire dependency closure; it adds no kernel acceptance rule.

## First actual module: Ps.Foundation.Source

Source: `packages/foundation/src/Ps/Foundation/Source.lean`, 148 bytes,
SHA-256 `33d898574406817537cc0c1a728e50eae2838a47178ad1fe4adba53d54d6c736`.
It defines the real `PsSourcePos` with three Nat fields and `PsSourceSpan`
with two positions. It has no imports or Core dependencies.

The fresh production packet has two inductive records and all six logical
type/constructor/recursor members; no missing members, extra source owners,
generated support or partial-body obligations. It is byte-identical to its
dependency projection. Unlike the full graph, it needs no nested-unit support.

| Actual packet | Bytes | SHA-256 |
| --- | ---: | --- |
| Producer transport | 1388 | 976e966131f71d2ab80aac725cd236be1790ca6538d11390202e1532b4269119 |
| Canonical public input | 1387 | 354322a05552cc8cd8a2285dde51d960e84da990c19b78d4085a3a16ccd3e93d |
| Source plus separate runtime consumers | 21578 | f018cba378ed81641d5fb759db73859a6a8adf19e6edb2d909897664fff5cc52 |

Both fresh Source and the complete Source-plus-consumers packet passed public
MinKernel without delegation and independent Lean 4.35.0 replay, commit
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.

The native harness imports the actual Source module. The source-owned compiler
compiles its exact source plus a separately labelled test consumer, checks the
original/transformed IR, emits TypeScript, and strict TSC produces the JavaScript.
375 position-field and 150 span-field observations compare actual native and
generated paths with independent input fields. Values include zero, 65536,
`2^64+1` and `2^256+7`. All 525 pass.

This is finite ABI/runtime evidence. Formal preservation from the actual
source compiler and eraser through structure layout, target construction and
projection remains unproved. The actual producer flags remain
providerChecked=false, semanticContractQualified=false and
strictSh1Qualified=false. Therefore Source does not become a fully
compiler-qualified module and no generation is counted.

## Actual dependency frontier and precise rejection witnesses

| Fresh leaf | Canonical bytes | First observed obstacle | Closures containing it |
| --- | ---: | --- | ---: |
| Ps.Foundation.Source | 1387 | Accepted | 42 |
| Ps.Foundation.List | 57195 | First declaration has a quantified type binder | 71 |
| Ps.Foundation.Name | 39022 | First PsName group has a String carrier; whole packet also has string literals | 107 |
| Ps.Foundation.Text | 26128 | First PsTextBuilder has List String carrier; whole packet also has string literals | 29 |
| Ps.CompilerIr.Model | 101240 | First _pscCheckedNestedUnit has a universe parameter | 57 |
| Ps.BackendRust.Runtime | 16432 | Whole packet has non-ASCII text; first constant has string expressions | 4 |

Dependency impact is computed from the actual matrix and includes the module
itself. It measures shared obligations, not guaranteed future successes.
Fresh CompilerIr.Model differs from its global projection because the fresh
producer retains additional support; that difference is exactly why projected
acceptance/refusal cannot qualify a module.

All six fresh exact leaf packets also passed an independent replay in
[Linux run 40711545422](https://github.com/dwijayuda/pskernel/actions/runs/40711545422),
job `122897859118`, source `69abac84449cd550b8f8dc702d5203471b1b9a65`.
This diagnostic branch changes only the workflow relative to adoption f27399e1.
Its artifact `12825978772` is 3672056 bytes, SHA-256
`772ca0a4027089d855fa6698c682d8097ddcc4b732f235ade89170f0b476e0f1`.
leaf-official-replay.json retains every input identity and pinned response.
Five Min refusals therefore remain coverage gaps on these officially accepted
inputs; replay grants no Min acceptance and advances no qualification count.
This does not prove universal producer correctness.

The fresh List packet refuses at prefix 1:
`psListLengthAcc.$psc0SH.0`, SHA-256
`3c43f32a4872d8c730174119043bebf61fd6b9605201ebce84b74f4386ad3835`.
Its leading binder domain is Sort 1 and its body uses a bound type variable.
The source is the actual generic list accumulator, not a synthetic test.

Read-only queries of the same generated kernel show
psMinRegCoreType(Sort 1)=none and psMinRegCoreType(bvar 0)=none;
Nat and List Nat both translate successfully. The current implementation
translates forall as nondependent arrows and has no type-variable context.
The public refusal remains authoritative; these internal queries only explain it.
The actual blocker is semantic expressiveness, not packet size or timeout.

## Chosen next implementation approach and unresolved fundamental obstacle

Start C1 from the unchanged **21 actual List Core members**, retaining their
complete fresh packet as the acceptance target. List is small, shared by
71 closures, and isolates parametric typing/recursion before String/Char runtime
contracts or the full dependent/universe checker. Name has larger impact but
its actual packet references 24 external names, including Char.toNat,
Int.ofNat/Int.repr, String.Internal.get/next/atEnd/length/append,
String.Pos.Raw.mk/byteIdx and String.utf8ByteSize. Its real equality routine
walks UTF-8 byte positions with fuel; its printer converts naturals through Int.
Ground String literals alone would not qualify that entire module. This source
comparison supports choosing the smaller List metatheory first. Do not promise that fixing
List alone will qualify all 71 dependents.

A read-only audit of all 21 actual packet records finds no declaration universe
parameters and only Sort 1 in their sort nodes. It finds 19 external names:
Bool, Bool.decEq, Bool.false, Bool.true, Eq, Except, Except.error, Except.ok,
Except.rec, List, List.cons, List.nil, List.rec, Nat, Nat.rec, Nat.succ, Prod,
Prod.mk and ite. In particular psListAny needs equality/decidability/conditional
semantics, psListTakeAcc needs Nat recursion, and the generated accumulator
helpers need List recursion. These observations delimit investigation; they
are not a typing proof or proof that rank-one syntax alone is sufficient.

The necessary candidate architecture is a predicative rank-one scheme layer:
separate leading type quantification from term arrows; introduce rigid type
variables, explicit kind/universe contexts and typed instantiation; interpret
List/Except/Prod and their recursion at instantiated types. Audit the actual
lowered recursor motives and recursive helpers before fixing this scope:
if they need dependent elimination or stronger polymorphism, expand the model
explicitly rather than erasing the evidence.

**The unresolved fundamental obligation is a sound interpretation and
implementation-refinement theorem for those polymorphic declarations under the
current trust restrictions.** The existing ground regular model cannot supply
that theorem. There is no justified local acceptance patch for Sort 1/bvar.
This is an open metatheory obligation, not evidence that the goal is impossible.

The exact current model confirms the gap:
[RegularModel.Denote](../proofs/pskernel-min/RegularModel.lean) interprets closed
regular type codes into Type and has no variable/scheme context.
[psMinRegCoreType](../packages/pskernel-min/src/Ps/MinKernel/Profile/RegularIngressProfile.lean)
has no sort/bound-variable branch or type environment. A polymorphic forall
over Type cannot simply be added to the same Type-valued interpretation:
state the predicative code universe, its interpretation, closure and level
boundaries explicitly. No Type-in-Type shortcut is justified.
The existing [byte admission source-model theorem](../proofs/pskernel-min/RegularIngressSemantics.lean)
then needs an actual extended translation/history refinement, not only a new
syntax constructor.

Before connecting a new rule, establish the model's consistency and an inhabited
interpretation for admitted data; prove context weakening/substitution and
scheme instantiation; prove constructor/recursor and recursive-definition laws;
then refine the actual type checker and public exact-byte/state path to it.
Keep all assumptions explicit and every report axiom-free or exactly propext.
Do not interpret Sort 1 as Nat, erase a type binder without proof, whitelist the
captured packet, admit an arbitrary axiom, or replace Min with official replay.

C2 in parallel work order means binding the existing regular carrier semantics
to actual Source structure erasure, constructor/projection layout and emitted
target operations for arbitrary admitted field values. R7/R8 establish scoped
literal/zeta and syntactic substitution facts only; they do not discharge this
obligation. Do not pad progress with field-equality lemmas that never connect to
the production compiler. Register and prove an actual compiler theorem before
changing Source's full qualification field.
The existing [CompilerPreservation.Value/Eval](../proofs/pskernel-min/CompilerPreservation.lean)
has only natural, Boolean and unit values, with scalar/let/control evaluation;
it has no structure value or constructor/projection evaluation rule.
RegularModel's separate carrier/fold interpretation does not automatically bind
the actual compiler's runtime object layout. This is the concrete C2 gap for
Source, even though all its finite runtime checks pass.

Then repeat fresh List admission and runtime qualification, update the frontier
and matrix, and address Name/Text primitive contracts, universe-parameterized
generated support, and subsequent exact rejected declarations. Investigate
parser/state/resource changes when actual newly eligible packets require them.
R9 remains parked: 39 fast cases and 14 reports passed, but the full generated
packet traversal exceeded 120 seconds. Digest traversal is not parser soundness.

The complete graph also retains 60 foundational contracts (35 directly used)
and five partial-body obligations: psBackendPublicTypeSupported,
psJsNeedsUtf8Runtime, psTsNeedsUtf8Runtime,
Ps.Internal.RustRuntimePlan.typeRequirements and
Ps.Internal.RustRuntimePlan.exprRequirements.
Define their semantics/termination or reject them; never hide them in an
external trusted prelude.

Per-module successes also need composition before whole-compiler qualification.
Independent fresh closures may carry different auxiliary declarations and
overlapping names; their acceptance counts cannot establish a shared global
environment. Retain exact import/source/record identities and prove the
environment extension, freshness and dependency-interface laws. If incremental
checking becomes necessary for larger eligible modules, define a public checked
state transition and a model-preservation theorem for every exact-byte chunk.
A digest/cache can locate previously checked data; it cannot grant admission.
The final global capture must cover all source members and support obligations.

C3 is complete only after the real full compiler passes its public Min byte
path, actual Min-backed G1/G2/G3 succeed at exact retained payload identities,
and installed CLI/library user flows pass. Ordinary G1 regression success and
the standalone R4B runtime do not count as these generations.

## Durable continuation and preservation rules

Run the matrix workflow after changes to compiler sources, kernel/proofs,
host source capture or drivers. Its artifact is the complete 124-row matrix;
the dated receipt summarizes only immutable successful checkpoints. Inspect
the current CI head before copying a previous count. Failed/superseded runs
remain labelled and do not advance qualification.

The stable U1 checker remains privately usable; the original tarball and hash
remain in its [usage guide](PSC1_MIN_KERNEL_USABLE_GUIDE.md).
The R7/R8 baseline retains 259 unique printed reports: 42 axiom-free and
217 propext-only; see [R7/R8 guideline](PSC1_MIN_KERNEL_R8_GUIDELINE.md).
The later C1 signature component adds thirteen guarded reports, without changing
the admitted compiler-module count; its dated receipt records the separate scope.
This matrix adds no proof or acceptance rule. Existing proof and runtime gates
must continue passing on adoption.

Preserve remote history with a fresh-head, one-parent commit and nonforce lease.
Protected base 94e0c13f6a4b434f73c859cc0c716cb6fb8d1340 stays unchanged;
do not merge the draft PR or publish npm. Official Lean Wasm remains default.
Production min/dual continue refusing PSC1_MIN_CANONICAL_BRIDGE_UNPROVED until
the full admission/preservation bridge is proved and qualified.

## Terminal adoption regression evidence

All selected workflows at adoption f27399e13f187957bb79e7dd20db9ca9a68c77eb
are terminal success:

- [Actual module matrix 40708696489](https://github.com/dwijayuda/pskernel/actions/runs/40708696489):
  complete dependency diagnostics, six fresh leaves, actual Source 525-case runtime.
- [Focused 40708696485](https://github.com/dwijayuda/pskernel/actions/runs/40708696485):
  proof 122887721713, compiler-preservation 122887721290 and
  portability/closure/package 122888949386 passed.
- [Broader Linux 40708703986](https://github.com/dwijayuda/pskernel/actions/runs/40708703986):
  all selected jobs passed, including full/linux-scoped 122895606482 and
  final gate 122910373047; benchmark was unselected/skipped.
- [Installed CLI 40708696445](https://github.com/dwijayuda/pskernel/actions/runs/40708696445):
  preflight 122887721956 and installed 122888099835 passed.

The separate six-leaf oracle run 40711545422 is also terminal success at its
recorded workflow-only source. Ordinary generations/regression suites above
do not qualify Min-backed G1/G2/G3. Source, IR, canonical packet and target
identities are retained independently from these pass/fail statuses.

The current private R4B regression pack at f27399e1 is 42240 bytes, SHA-256
`08931b3a19702ac1938222cda2c3ff0eff3e93357c69c9124ef8e96a0a8c17bd`.
It passed offline qualification. Its source metadata differs from U1's original
42237-byte deliverable; the original tarball is preserved and not relabelled.
The compiled kernel JavaScript remains SHA-256
`2cfe8dd6564b7ec6e968841c1ef43b01897d7ca5303095eb2b8c9b48dd27ded3`.

This reporting update changes Markdown/JSON documentation only. The exact
implementation/driver/proof/source checkpoint remains f27399e1.
All proofs, builds, compiler execution, tests and resource measurements ran
on GitHub Actions Linux; local work was read-only artifact parsing, hashing
and export. The overall full-compiler/self-hosting goal remains incomplete
at the explicit C1/C2 fundamental proof obligations above.
