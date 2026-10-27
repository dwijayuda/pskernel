# PSC1 minimal-kernel implementation continuation guide

## R1 qualified checkpoint — continue with R2

The user-confirmed GPT-6.1 Sol/High R1 batch passes standalone Linux
[40459838298](https://github.com/dwijayuda/pskernel/actions/runs/40459838298) at
**`8b33b3a17b241d3b264600dd9616cc195933df65`**. Proof/native job122041556260
and portability/census job122041556046 are success. The actual helper is
`Ps.MinKernel.Profile.LowerUnusedBinder`; the proof is `BinderLowering.lean`.

`Ps.MinKernel.BinderLowering.lower_sound`, `lower_instantiate` and
`lower_motive_body` each print exactly`[propext]`. Every successful lowering
has an exact inverse under actual Core lifting, then the existing Core theorem
derives actual instantiation independence. This covers arbitrary syntax/open
references; it does not prove typing or grant canonical admission.

All21 positive transformations,13 removed-binder refusals and2 out-of-range
probes pass natively and through actual PSC1-generated JS. The exact six-module
source/test graph is independently admitted by official Lean4.35. The helper is
93lines/3853B, SHA256`da2b0d1911358e88b49c7e9bbed4c64f6c5a16ed1a9e73296892f6983f14f6f6`.
Its explicit import closure has4 modules/8879B. The6-module test source has21514B;
its full bundle is79089B TS/135332B JS, not an isolated checker payload.

The original Check.lean remains93lines/3322B with its original SHA and acceptance
boundary. The runtime ledger still selects Check only. A future connected
canonical checker must include and remeasure this helper's dependencies; the
12-record target cannot silently stand for the larger checker/decoder closure.

**Next mathematical batch:** R2 in the runtime-profile guide. Define the closed
regular-data/type-code profile and prove one actual recursor instance with all
parameters, levels, minors and major checked. Use the successful lowering equation
and R1 theorem; do not infer recursor typing, iota soundness or primitive semantics
from motive independence alone. Then R3 foundation/projection/conversion rules and
R4 canonical ingress. Do not repeat completed R1.

**Broader regression boundary:** the preceding57964262 main and783718f9 installed
runs are fully green. New R1 main40459842620 and installed40459838431 were still
in progress when this result was recorded. Requery live HEAD and latest runs;
a documentation reporting push may supersede the main run. Do not call current
whole-branch qualification complete until its selected gates are terminal.
The dated receipt retains exact run/job/artifact identities and failed development
attempts. Canonical min/dual still refuse, with0/124 modules,0/37 criteria and no
min-checked G1/G2/G3. No generated-code preservation theorem or hostile-input
resource qualification is added by R1.

## Current checkpoint: read before the historical extension plan

At `579642626daa67bd167dd1af626f5b0e0401cb00`, standalone Linux
[40455022116](https://github.com/dwijayuda/pskernel/actions/runs/40455022116)
passes both jobs. The source-origin runtime ledger and actual Core inverse-
lifting/constant-motive scope lemmas are complete. The executable STLC checker
and its existing consistency boundary are unchanged.

[Measured runtime profile and next proof batch](PSC1_MIN_KERNEL_RUNTIME_PROFILE.md)
is the current next-action authority. It records exact artifacts, all17 recursor
spines, the23-entry syntactic foundation frontier, theorem limits, and sequential
R1–R4 gates. Start with a proved executable unused-binder lowering function;
then define and model the regular-data/closed-type profile. Do not repeat the
runtime-ledger task described as future work in the historical sections below.
Those sections remain useful for later dependent/canonical/whole-compiler work.
The new theorem does not prove the recognizer or authorize logical admission.

This guide is for the next engineering run, including GPT-6.1 Sol with High
reasoning. Read the current work-state and live GitHub evidence before acting.
The exact code checkpoint described here is
`d6bebd230bcaadf35a254bfbc5a26a17228db55f` on
`research/psc1-minkernel-consistency-selfhost-20261027`, draft PR #194. The base
is `refactor/psc1-layout-20261026` at
`94e0c13f6a4b434f73c859cc0c716cb6fb8d1340`. Later documentation commits may
point back to this qualifying implementation; do not confuse their identities.

## Start with the actual acceptance boundary

The branch contains a small proved **simply typed fragment**, not a kernel that
checks the complete PSC1 compiler. Its types are Empty/Unit/Nat/arrows. Terms are
bound variables, positional references to earlier checked constants, Unit/Nat
literals, annotated lambdas and application. Sequential closed definitions start
from an empty environment. There are no axioms or imported declarations in that
calculus. Safe Lean source is the theorem's executable subject. Generated JS
parity is empirical evidence; compiler preservation is not proved.

The actual full compiler needs dependent Core, inductives/recursors, projections
and a modeled primitive foundation. The min canonical bridge is unproved, so
research `min` and `dual` explicitly refuse canonical admission with
`PSC1_MIN_CANONICAL_BRIDGE_UNPROVED`. Do not remove that refusal until the bridge,
its semantic preservation and its full supported environment are proved and
qualified. Do not run the official checker and label its answer a minimal-checker
answer. Default independent checking remains the official Lean Wasm provider.

## Current owners and APIs

All paths below are repository relative and case sensitive on Linux.

| Concern | Exact owner | Entry points / important facts |
| --- | --- | --- |
| Executable fragment | `psc1/packages/pskernel-min/src/Ps/MinKernel/Check.lean` | `PsMinTy`, `PsMinExpr`, `PsMinDeclaration`; `psMinTyEq`, `psMinLookup`, `psMinInfer`, `psMinCheckDeclarations`, `psMinCheckEnvironment` |
| Source/native vectors | `psc1/packages/pskernel-min/src/Ps/MinKernel/Tests/Vectors.lean`; `test/NativeTests.lean` within that package | `psMinRawVector`; 16 finite semantic vectors, not a graph checker |
| Runtime Lake project | `psc1/packages/pskernel-min/lakefile.lean` | Explicit runtime root `Ps.MinKernel.Check`; tests are separate roots |
| Proof project | `psc1/proofs/pskernel-min/MainTheorem.lean`; its `lakefile.lean` | Imports exact runtime source via relative `srcDir`, no copied implementation; capstones `Ps.MinKernel.Proofs.minKernel_hasModel` and `minKernel_consistent` |
| Research modes | `psc1/packages/pskernel-min/host/toolchain.mjs` | `createResearchKernelToolchain({mode, officialRoot})`, `checkerModes`, `defaultCheckerMode`; `checkCanonicalAdmissions(source)` |
| Official installed checker | `psc1/host-tools/kernel-toolchain.mjs` | `createIndependentKernelToolchain({root, provider:'wasm'|'native'|'both'})`; exact `KERNEL_DISTRIBUTION.json` and file pins verified before/after actual execution |
| Official native source checker | `psc1/packages/pskernel-lean/provider/PsKernelLean/{Convert,Protocol,Prelude,Admission}.lean` | `toLeanExpr`, `decodeCanonicalAdmissions`, `buildLeanPreludeEnvironment`, `admitCanonicalAdmissions`; trust-level-0 environment and `addDeclCore` |
| Canonical codec | `psc1/packages/bridge/src/Ps/Bridge/CheckedAdmissions.lean` | `psEncodeCheckedAdmissionsCanonical`, expression/name/level encoders, nested-inductive normalization and exact heights |
| Compiler ordinary pairing | `psc1/packages/compiler/src/Ps/Compiler/Ordinary.lean` | `psCompilerPrepareOrdinary`, `psCompilerOrdinaryIr`; preserve constructive opaque logical witness and separately typed executable body identities |
| Source preparation | `psc1/packages/compiler/src/Ps/Compiler/Api.lean` | `psCompilerPreparationStart`, `psCompilerPreparationStepParsedWithOrigins`, `psCompilerPreparationElaborated`, `psCompilerPreparationFinishWithOutput` |
| Supported source profile | `psc1/packages/compiler/src/Ps/Compiler/Sh1.lean` | `psSh1PackageSectionAllowed`, `psSh1DefaultSourceOptions`; `MinKernel` is allowed, source grammar/resource policy remains restrictive |
| Portable TypeScript compilation | `psc1/packages/backend-ts/src/Ps/BackendTs/Sh1.lean` | `psCompilerSh1TypeScriptSources`; source, target, original/transformed strict IR checks remain authoritative |
| CI source transport | `psc1/scripts/MinKernelSourceCompile.lean` | Reads exact Check and Vectors source, calls owned compiler, emits candidate TS/admissions; it does not independently admit them |
| Portability evidence | `psc1/scripts/minkernel-portability.mjs` | Calls `lake env lean --run scripts/MinKernelSourceCompile.lean`, independently checks retained admissions, runs pinned TS and emitted JS vectors |
| Complete source census | `psc1/scripts/minkernel-closure-audit.mjs` | Exact unified compiler closure, actual canonical graph and actual implicit prelude; measurement has no authority |
| Module-to-package capture | `psc1/scripts/workspace-layout.mjs` | `packageBySection` includes `['MinKernel','pskernel-min']`; adding a mapping grants no checking authority |
| Four-engine compiler root | `psc1/packages/compiler-unified/src/Ps/CompilerUnified/Service.lean` | `Ps.CompilerUnified.Service`, public `psCompilerServiceCandidate`; candidate only |

The root `psc1/lakefile.lean` does not import the fragment proof project. Keep the
runtime's own Lake project and the proof's own Lake project separate. Adding a
file does not register its Lake root. When a root is missing, register it in its
own project, then verify that no proof imports entered the runtime closure.

## Operating procedure

1. Read `psc1/AI_WORK_STATE.md`, `ARCHITECTURE.md`, the development roadmap,
   dedicated minimal-kernel work state, coverage, proof status and research guide.
   Read relevant repository instructions and the live PR before mutations.
2. Verify the current branch HEAD, parent ancestry, relevant workflow conclusions
   and source pin through GitHub. Do not replace the parent branch with this topic.
3. Create a single-parent commit from the **freshly observed** research HEAD.
   Update the ref non-force with `expected_sha`. If it changed, inspect and
   incorporate the concurrent change rather than resetting history.
4. Run all builds, proofs, tests, benchmarks and compiler executions in GitHub
   Actions on Linux. No local builds or Desktop Commander. Reading/editing source
   and preparing a reviewable patch does not itself establish validation.
5. Keep a passing implementation checkpoint long enough for its full CI to finish.
   Push final evidence/docs afterwards; distinguish code qualification from the
   final documentation checkpoint. Do not repeatedly cancel the only baseline.
6. No merge or npm publication is authorized. A draft PR is the review boundary.

At this checkpoint standalone run **40444275459** passed proof and
portability/closure. Main regression run **40444282214** completed successfully,
including full job **121996032136** and gate **122004044236**: 37 finite Practical
Core criteria qualified, zero blocked. Its full artifact is **12708933625**,
121480618 bytes, SHA-256
`1934cd5504bfe644de9648221af534f0e223d3131de9e3c193c7566faf195ce0`.
Installed run **40444275465** also completed successfully, jobs **121991853908**
(preflight) and **121992045246** (installed). Its toolchain artifact is
**12708639355**, 206728049 bytes, SHA-256
`1498b053387005ed19b7ee4037f5b1d8b3a779a74b9ec1cc011ac09485a41ce9`.
The unpublished `proofscript@0.1.0-psc1.9` root is 3823980 bytes, SHA-256
`7bfeb61f96854fccfc78f9014474003a4501f3bd2ef6adfceba75239bb90e17b`.
Installed tests retain the frozen122-module source identity; they do not qualify
the min kernel or promote the changed current compiler. Main's tested merge is
`1192135a60b7570ace969591f71f723521c32521`; its tree
`1e6eb1bf349cdde90b2ff35cc2b418b51a44a834` equals the implementation HEAD tree.
Use the dedicated work-state receipt for later terminal outcomes.

## Reproduce the mathematical and source checks in Linux Actions

The pinned semantic checker is Lean **4.35.0**, commit
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`, from
`psc1/NATIVE_SOURCE_PIN.json` and `psc1/lean-toolchain`. Recheck these files before
adding a third-party proof dependency. Do not silently use a different Lean build.

From the repository root, the existing workflow executes the equivalent of:

```bash
set -euo pipefail
cd psc1/proofs/pskernel-min
lake build 2>&1 | tee proof.log
cd ../../packages/pskernel-min
lake build minkernel_tests
.lake/build/bin/minkernel_tests
```

For each qualifying theorem preserve `#print axioms` output in the proof log.
The current capstones report `propext` only. No `sorry`, `sorryAx`, arbitrary
axioms, unsafe admission, unchecked declarations or hidden official-Lean calls are
allowed. The theorem derives an environment model from the actual executable
success equation. A model theorem about a separate abstract typing relation is
insufficient unless its bridge from executable acceptance is also proved.

From `psc1`, source portability and closure measurement use:

```bash
set -euo pipefail
node packages/pskernel-lean/host/check-pin.mjs
lake build PsBackendTs psc1_independent_checker psc1_source_census_probe psc2_joint_closure_inventory
node scripts/minkernel-portability.mjs
node scripts/minkernel-closure-audit.mjs
```

Pinned Node/TypeScript setup and environment are already in
`.github/workflows/psc1-minkernel.yml`. Reuse that workflow instead of inventing
an unqualified host script. `minkernel-portability.mjs` uses the owned native PSC1
source compiler once, then emitted TypeScript/JS; this is **not** a generated
compiler generation. Its finite manually paired official-Core fixtures are a
differential test, not a proved general canonical translation.

## Complete graph measurement: exact inputs and output schema

`readOwnedCompilerSources('Ps.CompilerUnified.Service')` from
`host-tools/compiler-source-inputs.mjs` captures dependency-ordered authored
modules using root Lake registrations. The current checkpoint contains 124
modules, 4742 original Core members and 4747 logical members after five ordinary
partial-body companions. It emits 3465 canonical admission records. These counts
describe the current source; the frozen G3 package retains a distinct 122-module
closure and its own immutable generations.

The audit invokes the following exact source probe interface with the complete
module/path pairs, a 240-second ceiling and retained source/binary hashes:

```text
.lake/build/bin/psc1_source_census_probe
  --qualify --assurance ordinary-checked --grammar lean
  --out <qualification.json> --admissions <admissions.json>
  --modules <module-name> <source-path> ...

.lake/build/bin/psc2_joint_closure_inventory --prelude <prelude.json>
```

The first probe writes `psc1-compiler-closure-probe/2`, exact canonical bytes and
`admissions.json.ir.json`; it performs actual official native admission before
strict original IR validation. Its records include parsed imports and per-source
origins/members. The second writes a **bare array**, not the normal joint-audit
object. Each row contains `name`, `nameWire`, `kind`, `levelParameters`,
`levelParameterWires`, `type`, `value` (null or expression) and `metadata`.

The combined report is `dist/pskernel-min/closure/report.json`, schema
`psc1-min-kernel-current-closure-audit/1`. Retain the raw admissions, prelude and
IR alongside it. Report source bytes/identities, not merely text filenames.
`GITHUB_SHA` can be the PR merge commit; bind head and tested tree separately.

Observed at d6bebd23: 308 inductive admission groups, 3152 definitions, five
opaques; expressions include 230478 applications, 52868 bound variables, 244702
constants, 12986 `forall`, 43860 lambdas, 5955 lets, 2862 Nat literals, 7168
projections, 531 sorts and 5875 string literals. Universe nodes are `p:128`,
`s:11786`, `z:11786`. The prelude has 115 declarations: 60 axioms,
14 constructors, 25 definitions, nine inductives and seven recursor records.
Array and quotient named references in this exact compiler graph were zero;
that does not remove Array from the full Practical Core/foundation profile.

The retained full compiler admission JSON has **29,887,093 bytes**. A direct
constant-reference scan touches 34 foundational axioms. A diagnostic fixed point
following prelude type/value/metadata constant references reaches 62 prelude
declarations and still 34 axioms. This is **not a safe pruning proof**: inductive
constructors, generated recursor rules and metadata dependencies require an
explicit closure policy and semantic theorem. Do not replace the actual115-entry
foundation with that62-entry diagnostic set merely because both counts exist.

The minimal checker's own canonical source graph is already outside its accepted
object calculus: 12 admission records (three inductives, nine definitions), with
105 lambdas, 396 constants, 277 applications, 75 bound variables, 54 foralls,
three lets, three projections and three sorts. It requires Nat/List/Option
recursors, Bool/Eq/ite and the recursors for its own type/expression datatypes.
The93-line STLC checker is a **metaprogram that checks the restricted AST**; its
host-language implementation does not thereby lie in that AST calculus. It cannot
check its own canonical Core graph today. Distinguish "PSC1 compiles the checker"
from "the generated checker admits its own compiled implementation" and from
"it admits the complete PSC1 compiler" at every self-hosting gate.

These are occurrence counts. Do **not** infer the number of dependent binders,
beta/delta/zeta/iota reductions, WHNF/DefEq calls or hot paths from these totals.
Those measurements require a scope-aware visitor or actual checker profiling.
The initial audit is one `.lean` grammar lane, not a grammar-parity test.

## Canonical codec reference: preserve structured identity

Read the codec and official decoder when implementing a bridge. The following
is a schema guide, not authority to accept arbitrary objects.

| Object | Tags and exact fields |
| --- | --- |
| Structured name | anonymous `{k:'a'}`; string `{k:'s',p:<parent>,v:<string>}`; numeric `{k:'n',p:<parent>,v:<decimal-string>}` |
| Level | zero `{k:'z'}`; successor `{k:'s',o:<level>}`; max/imax `{k:'max'|'imax',l:<level>,r:<level>}`; parameter `{k:'p',n:<name>}` |
| Bound variable | `{k:'b',i:<natural-number>}` |
| Sort | `{k:'sort',l:<level>}` |
| Constant | `{k:'const',n:<name>,ls:<level-array>}` |
| Application | `{k:'app',f:<function>,a:<argument>}` |
| Lambda / Pi | `{k:'lam'|'forall',n:<binder-name>,bi:<binder-info>,t:<domain>,b:<body>}` |
| Let | `{k:'let',n:<binder-name>,t:<type>,v:<value>,b:<body>}` |
| Literals | `{k:'nat',v:<decimal-string>}`; `{k:'str',v:<string>}` |
| Projection | `{k:'proj',n:<type-name>,i:<natural-number>,e:<expression>}` |
| Constant admission | `{kind:'constant',declaration:<constant-declaration>}` |
| Constant declaration | `k:'definition'|'theorem'|'opaque'`, `lp:<name-array>`, `n:<name>`, `t:<type>`, `v:<body>`; definitions have `h:{k:'regular',h:<decimal-string>}` and `s:'safe'`; opaque has `s:'safe'` |
| Inductive admission | `{kind:'inductive',declaration:{lp:<name-array>,np:<natural-number>,ts:[{n:<type-name>,t:<type>,cs:[{n:<ctor-name>,t:<ctor-type>}]}]}}` |
| Root | `{format:'proofscript-checked-admissions',version:2,admissions:[...]}`; some transport fixtures also carry the official protocol field |

Successor levels use **`o`**, while sorts use **`l`**. Bvar tag is **`b`**.
Name and level tags overlap: never count every `k:'s'` as a universe successor.
Use separate typed visitors. JSON natural indices/parameter counts and decimal
strings for Nat literals/regular heights have different representations. Preserve
range/round-trip checks rather than coercing arbitrary JS values with `Number`.

A pretty printed name is not an injective identity. `str anonymous 'A.B'` differs
from two nested name components, and numeric components differ from string digits.
The existing audit's readable constant table is a diagnostic projection. A future
trusted translator must key the full structured name and exact universe arguments,
preserve duplicate/refusal semantics and check de Bruijn scope under every binder.

Canonical source admission rejects raw user axioms and partial declarations.
Constructor and recursor source records are not each separate wire admissions:
constructors are inside the inductive group, and the official kernel generates
the checked recursors. Nested-inductive normalization creates adapter declarations.
Do not drop generated members or trust source metadata as the recursor's proof.

## Actual primitive foundation and model obligations

The environment is assembled in this order:
`Prelude.lean` → `SelfHostPrelude.lean` → `SelfHostProd.lean` →
`Control.lean` and `Order.lean`. The final root is
`psSelfHostProdPreludeEnvironment`. Audit that root, not just the first file.

`Prelude.lean` initially declares 68 axioms. Later phases replace exactly eight
of them: List, Option, Prod, Int, Int.ofNat, Int.negSucc, Decidable and ite. The
observed final foundation therefore contains 60 axioms. In particular **Int and
Decidable are checked inductive data in the final foundation**, and `ite` is a
checked definition. A claim that all Int/Decidable/ite declarations remain axioms
would be based on an incomplete read.

| Remaining axioms | Count | Modeling work |
| --- | ---: | --- |
| `Nat.add/sub/mul/div/mod/beq/ble/blt` | 8 | Interpret exact arithmetic, saturation/zero-divisor and comparison behavior; distinguish typing consistency from target arithmetic correctness |
| `Int.neg/add/sub/mul/repr` | 5 | Standard integer operations over the checked Int representation, plus textual representation |
| `UInt8/16/32/64`, `USize`, `Int8/16/32/64`, `ISize`, `Float`, `Float32` | 12 | These are abstract type axioms; actual supported uses and model size/inhabitance must be stated |
| `String`, `Bool`, `Bool.true/false`, `Unit`, `Unit.unit`, `Char`, `Char.ofNat/toNat` | 9 | Give carriers and constant interpretations, without assuming unprovided inductive computation rules |
| `String.push/singleton/utf8ByteSize/append`, `String.Internal.length/append/next/get/atEnd/extract`, `String.Pos.Raw.mk/byteIdx/next/atEnd` | 14 | Distinguish legacy/modern aliases and exact UTF-8 positions; prove only the semantics actually assumed by the logical rules |
| `Prod.fst/snd` | 2 | The carrier itself is checked inductive data; these named functions remain axioms, distinct from primitive projection syntax |
| `Array`, `Array.emptyWithCapacity/size/push/getD/setIfInBounds/map/foldl` | 8 | Carrier constructor and operations are axiomatic; no Array usage in the measured compiler graph does not waive Practical Core coverage |
| `Eq`, `Bool.decEq` | 2 | An interpretation of equality family and decision constant is required; a familiar name does not import standard Lean Eq automatically |
| **Total** | **60** | **No full foundation model proved on this branch** |

Nat, List, Option, Except, Prod, Int, Decidable and internal order True/False have
explicit inductive/constructor/recursor source records. `Order.lean` defines
`_psc1OrderFalse`, `_psc1OrderTrue`, constructive decisions, Nat/Int order relations,
their decision functions and the logical conditional. `Control.lean` supplies
total recursor-based folds/lazy folds/reverse/array-to-list definitions. Their
runtime intrinsics are a separate semantic layer.

`PsKernelLean.Prelude` builds an empty trust-level-0 environment, replays the
actual pinned foundation and defers only unknown constants during dependency
ordering. Every other kernel failure is fatal; no progress is fatal. For an
inductive it converts actual constructor metadata into a Lean inductive group;
separate constructor/recursor records are skipped because Lean generates them.
Native and official Wasm checking share this semantic boundary.

Before extending the minimal foundation, retain a model obligation for **each
exact permitted declaration** and its type. A whitelist of familiar names is not
a consistency theorem. A dependency slice may avoid unused declarations only if
the resulting accepted environment, permitted constants and checker profile are
defined explicitly and the complete required closure is measured again.

## Recommended next implementation batches

1. Add an injective diagnostic structured-name key and scope-aware dependency
   audit. Classify the 308 inductive groups, constructor fields, recursive/nested
   occurrences, universe parameters, recursor applications and dependent binders.
   Retain exact source/graph hashes and complete unsupported reasons. This is
   measurement, not a new acceptance path. Use the checker's own12-record graph
   as a smaller dependency workload, without assuming the present STLC calculus
   can admit it or that a name-reference fixed point is sound foundation pruning.
2. Build a pinned con-leche translation **experiment outside production admission**
   or choose the next direct semantic fragment after the research comparison.
   Include the actual primitive foundation in the feasibility test. Do not infer
   a theorem transfer from unmodified con-leche merely accepting a translated file.
3. For a direct extension, prove the representation/context/environment semantics
   and executable acceptance bridge before admitting the new rule. For a verified
   translation, prove acceptance preservation and all foundation/encoding obligations.
4. Qualify the corresponding portable source with the owned compiler and official
   exact source admission. Generated execution remains a separate trust assumption
   until a compiler-preservation result covers it.
5. Implement a bounded canonical ingress and wire min/dual only after a common
   domain theorem and actual official differential evidence exist. Retain official
   Wasm as default and production provider/package identity checks unchanged.
6. Only after the generated minimal executable admits the **complete current
   compiler closure**, run real G1/G2/G3 under that checker with fallback disabled.
   Preserve exact source/admission/IR/executable fixed-point requirements and
   current-source versus frozen-release distinctions.

Do not start an expensive G2/G3 sequence while its first required admission graph
is unsupported. Record the first missing mathematical/mechanical prerequisite and
continue a smaller fully covered fragment instead of relabeling official evidence.

## Critical negative tests before an admission bridge is exposed

- Malformed/unknown tags, missing or extra fields, duplicate fields, wrong versions,
  wrong decimal formats, negative/fractional/overflow indices and levels, invalid
  Unicode or byte encodings, oversized names/literals/inputs and excessive depth.
- Structured-name collisions, duplicate declarations, altered universe arity,
  changed binder annotations, free variables/metas, loose bound variables,
  incorrect lifting/substitution beneath Pi/lambda/let, dangling/forward constants.
- Forged `False`/Empty inhabitants, function/argument mismatch, type-as-term errors,
  illegal universe constraints, unapproved axioms, unsafe declarations and an
  unmodeled imported foundation; empty input must not smuggle in an unchecked env.
- Invalid inductive positivity/parameters/indices, constructor ownership, malformed
  motives/minor premises/recursor reductions, invalid projections, bogus definitional
  equalities and incorrectly cached results across environments or contexts.
- Ordinary partial companion/body/type/source identity mismatch; replacing an
  executable body while retaining a previous logical receipt; original/transformed
  IR mismatch and altered manifest/tool bytes before or after checking.
- Exhaustion at every stage and aggregate work limits; cyclic/aliased JS objects,
  hostile getters or unknown prototypes if arbitrary objects are ever accepted.
  Prefer bounded bytes with a separately proved decoder over granting JS object
  graphs implicit AST trust. Current typed Lean AST proofs do not cover these inputs.
- Source-selected checker/tool identity, copied receipt authority, min-to-official
  fallback, dual success when one checker refuses, cached answers for changed bytes,
  unsupported declarations that silently skip and forged provider responses.

## Source subset and proof pitfalls observed in this branch

Use the flat executable names listed above. Earlier namespaced convenience source
failed the existing SH1 profile; d6bebd23 deliberately changed names rather than
expanding the grammar or weakening policy. Proof code may use full Lean namespaces,
tactics and abstraction because its project stays outside the executable cycle.

Prefer the existing explicit recursion forms (`Nat.succ remaining`, fully qualified
constructors, simple matches and top-level flat functions). Do not assume native
Lean conveniences such as `abbrev`, deriving, local mutual recursion, custom
elaborators/macros, `Lean.*`, `Std.*`, extern/unsafe wrappers or imported proof
instances are accepted by the source-owned compiler. A native `lake build` pass
does not qualify that source for PSC1. Use the actual source compilation workflow.

Depth fuel is not aggregate work. Large arrow annotations can pass into a variable
type without being completely traversed at that moment; list lookup is structural,
not charged to inference fuel. Keep theorem consistency separate from ingress,
total resource and host stack/heap qualification. Never turn exhaustion into success.

Do not prove a parallel checker while silently changing the runtime algorithm.
Import the exact implementation. After changing a runtime constructor, equality
case, environment operation, resource outcome or declaration rule, recheck every
capstone dependency and the executable-to-model bridge, not just the vectors.

Finally, preserve candid status language: proved fragment, conditional theorem,
empirical differential evidence, unsupported profile, partial coverage and missing
self-host qualification are different results. A clean implementation handoff
should state exactly which one each artifact establishes.
