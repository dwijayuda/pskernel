# PSC0 SH/1 implementation work state

Updated: 2026-10-08 UTC.

## Active checkpoint: isolated recursive generic-argument repair

Execution branch for this checkpoint: psc0/sh1-generic-erasure-v1.
Parent helper migration: 671685c3f0059574405a1e630dd965d421a26f05.
That migration passed its first bounded native development gate in run
37851669475; its full selected-seed qualification is running independently.

The current-definition erasure context now retains ordered declaration generic
arguments using a reversed accumulator. Type binders add their assigned Tn;
runtime and erased proof binders preserve the context. Recursive-IH calls use
those ordered arguments. This repairs the shared empty-type-argument omission
without collecting unrelated local types or changing kernel/provider internals.

The focused raw fixture covers one/two/three generics, interleaved type,
proposition/proof and runtime binders, and a monomorphic control. The harness
checks actual original-IR call paths and argument order, emits that same IR,
and compares bounded runtime behavior. It runs on N1 and C1/C2/C3, not the old Q.
The separate provider job also checks its exact C2/C3 admission streams.

Run 37852341550 passed the first bounded native gate for this repair at
cf8fbd784944a98b1e390b709685ca54c2511827. The original-IR assertions and
generated/native behavior checks passed; full C1/C2/C3 and provider outcomes
remain pending. Preserve C2-versus-C3 product equality; Q may produce a different
C1 TypeScript product while its C1 executable
already contains the new erasure implementation. A remains the selected seed.
The diagnostic IR inventory must determine the new finding counts. This
checkpoint does not implement the separate call-expression typing obligations
or activate strict SH/1 runtime enforcement.

The next coherent portable expression-checker design is recorded in
[docs/selfhost-language/RUNTIME_IR_PLAN.md](docs/selfhost-language/RUNTIME_IR_PLAN.md).
It preserves type/value scope, ordered simultaneous substitution, exact IR
calling conventions and explicit resource failures. It is a plan, not an
additional implemented or strictly qualified capability.

## Previous checkpoint: next three-helper source migration

The qualified Foundation checkpoint below remains the previous completed milestone.
This continuation migrates psExprApplyManyWorker, psExprAppViewAccWorker and
psErasureAddUniqueStringWorker to ordinary explicit value parameters. Public
worker/wrapper names, full types, argument ordering and algorithms are preserved.

Only Term.lean and Erasure/Definition.lean change inside the portable compiler
closure. The three spelling guards now accept the historical and qualified
forms while preserving their wrapper/primitive checks and unrelated imports.
A new bounded correspondence harness compiles preserved and current raw helper
slices with actual Name/Level/Expr source, compares all seven public function
types and checks application order, accumulator suffixes, typed partial
application and exact unique-name exhaustion. It runs before expensive C1.
A cheap behavior check also executes actual exported helpers in N1/C1/C2/C3.

Cloud validation is pending for this new checkpoint. Ordinary development uses
the existing native-candidate gate; the completed source-family milestone then
receives selected-Q current-source C1/C2/C3 and exact provider acceptance.
A remains the selected qualified seed. No strict runtime-profile claim is added.

An isolated follow-on erasure change is being designed: preserve the current
declaration's ordered generic arguments when reconstructing recursive calls.
It is not part of this helper-migration code checkpoint. Keep kernel/provider
implementation and metatheory unchanged.

## Completed checkpoint: qualified seed and first source migration

Implementation branch: psc0/sh1-implementation-v1.
Qualified portable source B: 70d6010ddccbdd6b4939f2fb3c088bfe4e607de0.
Run 37840481558 passed on its first execution for this migration: compiler job
113528289107 and provider job 113549202073 both completed successfully.

B contains 56 raw source modules / 991,890 bytes. Its raw closure SHA256 is
4b0e8ed609bdf1c6b7063d2d763f39f0d1c8d33ca7be375fa46bcece018c85ae.
C1, C2 and C3 agree on canonical surface, canonical admissions, TypeScript and
JavaScript. The generated compiler SHA256 is
7a095596679cf53de213deb354610de22e29146e5d3265f07dc1720ea920836d.

Foundation.List now uses ordinary explicit parameters in reverseAcc, append,
take and zip. The verified A seed consumed both the preserved reference and
current raw source before C1. All ten public types and 1,666 observations per
implementation passed, including typed partial applications and generic zip.
Raw .lean/.ps capabilities and all seven refusal cases passed in C1/C2/C3.
Preparation/session/CLI conformance and the corrected ownership guard passed.

The unchanged provider at 963030dc2d154008fccc82e7c8ed29331f138799 accepted
B's compiler admissions and the deduplicated raw capability stream. Its binary
SHA256 remains 88f2d20ea733742d48724ecbdc903271e18bcfcccc8682be596a676aef68e3ec.
Artifact generation preceded this separate provider check; no checked-emission
claim is inferred. Strict runtime SH/1 enforcement remains pending.

The selected authoring compiler Q remains the qualified A compiler from
e91b9558d665879871b8bf0893915ae64b27c7fe, with JS SHA256
9d8a91e890c779c6b377b8a482ae3e997a1630b360eb8d6e7c022b3964510096.
B verified all four products from A's retained artifact and materialized the
content-addressed qualified seed cache. Preserve S0 -> A -> B recovery;
do not silently claim the historical S0 can compile migrated B.

Ordinary edits use npm run dev:sh1. The first native development gate at
9641928bcf7d5394f46e19a31a8ae3fd096d44b5 passed in run 37834854232:
14.590 seconds for the bounded gate and about 74 seconds for the whole job
with restored build caches. Its TS/JS exactly match the independently qualified
A compiler. Full self-application is a separate promotion workload.

B's full generation totals were 983.965s, 968.930s and 984.134s. Warm unchanged
in-memory preparation reused all 56 modules with zero parse/prepare/finish work
in about 1.73 ms. These warm numbers exclude source reads and optional emission;
the generated compiler's cold preparation still takes about 10 minutes.

The remaining IR inventory is diagnostic: B has 244 call-expression typing
obligations and 19 type-argument arity findings, with no other recorded categories.
Retained A details show 19 generic helper calls with zero explicit type arguments.
Source review identifies an omission in recursive-IH reconstruction: the current
definition tracks runtime names only and reconstruction supplies List.nil type
arguments. The report lacks node ancestry, so a one-to-one mapping is not claimed.
The next M6 slice should preserve ordered current-declaration generic arguments,
then add callee-expression typing/scoped substitution. No whitelist or checker
weakening was introduced, and no extra implementation/test cycle was started.

All exact receipts and provenance are indexed in
docs/selfhost-language/qualification-evidence.json. Original A and B qualification,
provider and List-correspondence receipts are preserved beside it. This final
checkpoint updates only documentation/evidence after the qualified B source.

Follow-on source families, in order: psExprApplyManyWorker,
psErasureAddUniqueStringWorker, psExprAppViewAccWorker. Keep public types and
exhaustion/ordering behavior; use focused native comparisons before the next
planned source-family qualification. Further source migration, optional syntax
conveniences, strict M6 enforcement and optional .ps authority are documented
future work, not completed claims.

Earlier checkpoint notes below retain their original execution-time status.

## Scope of this work

Implement the accepted self-host authoring and iteration plan from research commit
80d04e7ab0e9214ffecf093a6272865f0eaca096. Start with ordinary structural recursion
that changes nondependent value parameters, a pure preparation seam, and focused
generated-compiler qualification. Migrate source families only after capability
evidence passes.

Execution branch: psc0/sh1-implementation-v1.
Historical compiler baseline: 37f63c39d4a07189938046c64152bba25d789450.
The historical 55-module record remains immutable.

## Boundaries

- GitHub/cloud only; no local checkout, builds or tests.
- Kernel/provider implementation and metatheory belong to the native workstream.
- No profile activation or checked/native success claim without corresponding evidence.
- Keep current public compiler APIs and source signatures compatible.
- Solve shared semantic/architectural causes; do not weaken gates to obtain a pass.
- Use focused validation for a complete implementation slice, then current-source
  C2/C3 qualification at the milestone.

## Implemented architecture

- Recursion: canonical stable/major worker plus function-valued generalized state;
  preserve public binder kinds and argument order with a wrapper. Reject unsupported
  dependent telescopes and escaping self references.
- Provenance: inspect and enforce which nested matches may introduce decreasing children.
- Preparation: pure start/parsed-step/source-step/finish with both environment and
  ordered declaration accumulator. Session caches retain a valid exact-source prefix
  within one compiler import.
- Qualification: pinned historical seed; isolated TypeScript5.8.3 installation;
  branch-scoped cloud workflow; raw .lean/.ps capability examples; candidate execution;
  explicit C2/C3 canonical source/admission/TS/JS equality.
- Native integration coordination: observed branch psc0/native-core-selfhost-v1 at
  963030dc2d154008fccc82e7c8ed29331f138799. Named native workflow run37825822957,
  job113478295740 completed its actual full checked compiler fixedpoint successfully.
  Source hash ee6dd22f1b74b97113cc1a5e36aadad3cceecb2b152653f2c0dc26dd07aa22f7;
  TypeScript hash fb173a348d1555d1ff224b9977f6fee68591b79f781a6b292c2572648415b033.
  This is evidence for the historical native baseline, not acceptance of our new worker
  admissions. New admissions will be checked through a separate pinned provider checkout.

## Design clarification

Canonical surface source is the output of the existing syntax translator. Lowered
worker/core structure is represented by canonical admissions. The minimum checkpoint
does not add a second elaboration-aware source printer. Generated compilers must
consume raw authored forms, so the new lowering path is exercised directly.

## Initial implementation checkpoint (historical)

The first coherent implementation checkpoint contains portable recursion lowering,
preparation/session reuse, raw capability fixtures, C2/C3 qualification, diagnostic IR
inventory and a separate pinned native-provider acceptance job. Its commit requests
[sh1-qualify]; compiler and provider outcomes are pending cloud execution. After earned capability
qualification, migrate a bounded Foundation.List family using a pinned qualified seed.
The independent host IR report is diagnostic evidence; full strict runtime typing and
PSC0-SH/1 strict profile activation remain separate obligations.

## Review decisions before first execution

The child-provenance boundary also requires alpha-equality of the nested expected
result telescope and the whole worker result. This prevents a narrower induction
hypothesis from disguising missing state application. Fixtures include the rejection
and preservation of valid outer hypotheses. Session results are deeply immutable;
parsed cache limits are entry/source-text limits, not a hard compiler-heap bound.

## Setup checkpoint after first cloud attempt

Commit e67647ec4821d609188e6feb5a4de2380857767e started run37831018572.
Job113496067989 stopped in Lean Action configuration because the historical branch
had no lake-manifest.json; no semantic tests or compiler generation ran. Add the
correct dependency-free manifest and explicitly register Ps.Elab.Recursion in Lake.
Preserve the historical changed-argument refusal test by selecting BatchStable; the
enhanced path is covered by the generated raw-source capability corpus. Rerun the
same coherent qualification after these integration corrections.

## Native build checkpoint

Run37831457914 at e52c30313b1e9124864a304a41f3b4b4c8f74bd0 recovered and
cached S0 successfully (JavaScript SHA25674dcebb7b296d81924d92987e99146b5d1c5ff9fbe3d8076ca591952d2ef7f76).
The new recursion module, context and term changes compiled natively. The wrapper
used two Lean4.34 reserved words as local names (`meta` and `public`); rename them
to metaContext and publicDeclaration together. No semantic acceptance rule changed.
Candidate and full qualification remain pending; reuse the cached seed/build outputs.

## Development gate validation checkpoint

Run37831951758 at e91b9558d665879871b8bf0893915ae64b27c7fe has passed native
compilation and the generated C1 candidate, including raw capability and session
conformance. Current-source C2/C3 and subsequent provider decisions remain pending.
The implementation branch is held at that immutable revision while qualification runs.

A separate psc0/sh1-development-gate-v1 checkpoint adds host-only iteration/recovery
tooling for one bounded native-candidate validation. Portable compiler source remains
identical to e91b9558. No active selfhost-seed.json or Foundation source migration is
included. The temporary workflow branch filter and ref-scoped concurrency preserve
the running full qualification.

Ordinary pushes build the current native PSC frontend and use it to emit N1, then
execute raw capabilities, preparation sessions and a two-module resident CLI smoke.
This evidence is native-seeded development execution, not selected-seed ancestry or
a self-host fixed point. Full qualification retains selected-seed C1/C2/C3 and the
independent provider job. The frozen diagnostic ownership case shares the existing
session conformance boundary. Historical recovery verifies complete provenance and
all four seed products; a malformed cache reconstructs rather than becoming selected.

Once A is qualified, pin its actual source/toolchain/product identities, restore the
implementation workflow branch filter, and apply the staged Foundation.List migration
with its bounded behavior/public-type correspondence gate. Preserve A's historical
source recovery path before allowing B to use the new authoring capability.

## Bounded development result

Commit9641928bcf7d5394f46e19a31a8ae3fd096d44b5 passed run37834854232 on its
first execution. Job113509175107 took74seconds including a15second incremental
native build. The native-candidate receipt reports14590.443683milliseconds for
N1 generation and bounded capability/session/CLI checks. The raw closure has56
modules and SHA2567e18013c260de84b08d57e923aef184993b0c5fea4de4775a68288a8ff9e157a.
N1 JavaScript SHA2569d8a91e890c779c6b377b8a482ae3e997a1630b360eb8d6e7c022b3964510096.
These are single cached Linux x64 development measurements, not a fixed-point or
provider claim. The Foundation behavior matrix correctly skipped unchanged source.
See docs/selfhost-language/qualification-evidence.json for this durable checkpoint.

The next migration checkpoint is staged with additive dev:sh1/iterate:sh1 commands,
the same verified-seed Foundation comparison moved ahead of expensive C1 generation,
and a focused update of check-modular-preparation-source.mjs. That legacy guard
still assumed the old worker spelling and accidentally scanned two structures after
the new state type was added. Its replacement preserves prepared declarations-only
ownership and all unchanged admission/provider-session boundaries; generated session
correspondence already supplies the semantic evidence. Run it in B's early source
checks. Portable compiler source and selected seed remain at A until full evidence.
