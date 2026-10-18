# Generic mutual P0 runtime qualification — 17 October 2026

## Exact acceptance

Compiler/test SHA: `82b248a3ee2cd9246756690db23b7dffd612e022`. Branch:
psc0/pscv0-v7-native-lean-v1. PR #109 remains draft/open/unmerged on
psc0/pscv0-v7-m1-parser-ownership-v1.

All five gates completed successfully at this exact SHA. This receipt accepts
**960 focused runtime comparisons**, including 20 new generic P0 observations.
The weighted engineering estimate remains **78/100**. This extends selected
ordinary partial execution coverage; it does not close M3+B or establish
verified backend correspondence.

The compiler implementation is unchanged from the accepted independent-WF
SHA c23a6fb479d3c930dc97f9f13c0421b307e462a2. Its 940-comparison acceptance,
source equations, decrease proofs and bounded repairs remain documented in
[the independent-WF receipt](PSCV0_M3_INDEPENDENT_WF_QUALIFICATION_2026-10-17.md).

| Gate | Run | Job | Result |
| --- | --- | --- | --- |
| Native Linux | [39037331359](https://github.com/dwijayuda/pskernel/actions/runs/39037331359) | `117409699566` | SUCCESS; all 34 reported steps |
| Focused M3 | [39037331391](https://github.com/dwijayuda/pskernel/actions/runs/39037331391) | `117409699812` | SUCCESS; all 15 reported steps |
| F1 canonical model | [39037331355](https://github.com/dwijayuda/pskernel/actions/runs/39037331355) | `117409699515` | SUCCESS; all 10 reported steps |
| F2 logical operations | [39037331395](https://github.com/dwijayuda/pskernel/actions/runs/39037331395) | `117409699959` | SUCCESS; all 9 reported steps |
| F3/F4/platform | [39037331418](https://github.com/dwijayuda/pskernel/actions/runs/39037331418) | `117409699543` | SUCCESS; all 11 reported steps |

## What this fixture establishes

The same polymorphic mutual partial pair is instantiated at Nat and Bool in
one emitted module. It has the common telescope
{A : Type u} [dictionary : Inhabited A] (seed : A) (n : Nat).
At zero, the left entry returns the seed and the right returns the supplied
dictionary's default. At a successor, each invokes the other entry with the
predecessor. Both entry directions and both input parities are observed.

For Nat, the chosen dictionary defaults are 29/23 and seeds 47/41 for
false/true; the depths are 3/2. The wrapper returns 100 * left + right.
For Bool, the dictionary default is true and the seed is false, with the same
depths. The distinct encodings of both returned values prevent a shared
logical inhabitant from satisfying the runtime oracle.

| Input flag | Nat export | Bool export |
| --- | ---: | ---: |
| false | 2947 | 12 |
| true | 4123 | 21 |

The two exports are m3p0genericnat and m3p0genericbool. The output stem is
p0generic in the nested m3-mutual-partial/p0-generic directory. The independent
pinned native definitions calculate the expected values; a guard checks that
they remain exactly the values above.

### Logical construction and source admission

The executed construction check inspects both actual opaque/private-body pairs.
It checks the original universes and complete four-binder telescopes, exact peer
capture forwarding, retained dictionary projection, source origins and absence
of a logical eq_def. It does not substitute a handcrafted replacement body.

The independent native fixture checks that p0Left and p0Right are opaque and
collects the logical assumptions of both entries and both output wrappers.
Each transitive closure must fit the approved propext / Quot.sound set.

One ordinary-checked request selects both exports and all five targets. It must
return a nonempty declaration set and every requested nonempty artifact bundle
in order. Closed-verified and boundary-qualified-verified requests must each
fail at the assurance phase with PSCV0-ASSURANCE-DOWNGRADE and return no
successful artifact result. There is no verified-to-ordinary fallback.

The log records all three actual markers:

- PSCV0_M3_P0_GENERIC_NATIVE: PASS — native opacity and approved assumptions.
- PSCV0_M3_P0_GENERIC_CONSTRUCTION: PASS — retained real source/Core identities.
- PSCV0_M3_P0_GENERIC: PASS — ordinary five-target emission and both exact
  verified-assurance refusals.

### Runtime evidence

The unchanged shared runner validates the exact two oracle rows, [false, true],
the exact requested output keys and UInt64 decimal values. It compares every
export at both flags in direct JavaScript and strict compiled TypeScript.
The generated Rust harness contains one assert_eq! for every pair and runs
through the existing locked Cargo target. Its path is relative to that target's
canonical harness directory, so the nested P0 output is tested directly.

For Wasm, wasm-tools validates the GC core and component modules. The runner
checks exact core exports and exact Bool-to-UInt64 WIT exports, instantiates the
core in V8, invokes the component through Wasmtime, and compares both results
against the native oracle. The combined Wasm marker therefore covers two lanes.

The actual log contains two P0 ECMA PASS markers (direct JS and compiled TS),
one P0 Rust PASS marker and one P0 Wasm PASS marker. Together these executed
assertions establish 2 exports × 2 flags × 5 lanes = **20 new comparisons**.

The shared Wasm marker's historical wording includes "against checked
equations". That reusable label grants no logical equation to a partial
declaration: this fixture explicitly rejects eq_def and both verified modes.
These P0 results are ordinary runtime comparisons against the pinned native
oracle, not a partial-body theorem or formal backend correspondence.

## Retained complete focused matrix

All 668 focused build jobs and all 14 outer fixture commands completed.
The original source, logical construction, exact-refusal and runtime assertions
remain. Runtime counts are:

| Runtime suite | Exports | Flags | Lanes | Observed comparisons |
| --- | ---: | ---: | ---: | ---: |
| groupfold | 2 | 2 | 5 | 20 |
| wellfounded | 16 | 2 | 5 | 160 |
| groupmatch | 4 | 2 | 5 | 40 |
| mutual | 5 | 2 | 5 | 50 |
| groupderive | 6 | 2 | 5 | 60 |
| mutualstructural | 6 | 2 | 5 | 60 |
| nestedfold | 7 | 2 | 5 | 70 |
| wherefixture | 6 | 2 | 5 | 60 |
| nestedderive | 6 | 2 | 5 | 60 |
| groupproof | 4 | 2 | 5 | 40 |
| emptydict | 4 | 2 | 5 | 40 |
| indexedinhabited | 4 | 2 | 5 | 40 |
| p0generic | 2 | 2 | 5 | 20 |
| Original recursive deriving | 24 | 2 | 5 | 240 |
| **Total** | **96** | **2** | **5** | **960** |

Exact anchored runtime output contains **26 scalar ECMA, 13 scalar Rust and
13 scalar Wasm** PASS markers, plus the original deriving **2/1/1** markers.
There are 56 printed runtime PASS markers because each of the 14 Wasm markers
covers both V8 core and Wasmtime component execution.

The 19 original WF refusals, original independent decrease proofs, 38 approved
native WF assumption closures, public equations, typed source-curried callback
and runtime observations remain. The source-only result-inference fixture is
still the previously qualified implementation; the separate own-binder family
compiler change is not included in this acceptance.

## Full Native and foundation gates

Native Linux completed all 34 reported steps. The published log passes the
inferred-input / complete rollback / saved-scope instance regression and the
original synthetic/default/postponement/instance-graph checks. The original
source closure, checked Standard and linked three-module application pass;
App.compute(7) remains 18. JavaScript, strict TypeScript and locked Rust each
pass 1,069 shared runtime observations. All 35 platform probes per profile,
GC/core/component gates, repeated native Wasmtime calls and post-return checks
pass. Generic Nat/Bool recursion retains 100,000/50,000 steps. The M1 performance
JSON records sourceSha `82b248a3ee2cd9246756690db23b7dffd612e022`. The complete native run finished before
another compiler/test revision was pushed.

F1, F2 and F3/F4/platform all completed their original 10/9/11 reported steps.
The active logical foundation still contains 34 audited additions with no
candidate axioms and three approved recursor rules. Only propext and Quot.sound
are allowed; P1 remains unavailable because its audited construction reaches
Classical.choice.

The Standard identity remains 3,633 declarations / 41 package units / 359
source units, FNV 4990397000639020696, SHA-256
5e96678b7ca94ac8dcb63d36cee81c5997287f507ce8c0c26d28321b37ce97d7.
The source-surface SHA-256 is
7a996cfc6253693799d43fdcf78dd7f30eb0713a3eb31831daa9d804faf818c6.

## Revisions and the first harness refusal

The initial fixture commit was 075a381d5fefcb5d4ac40a49d4da42d8e3985024.
Focused run 39036074336/job 117405982802 failed host compilation at the new
batch-result indexing. Its 99,505-character log passed the native P0
declaration/assumption guard, then reported unresolved optional-array result
types and dotted .error/result fields at fixture lines 605–611. No runtime
assertions ran and no focused artifact was produced.

That first attempt passed Native Linux run 39036074254/job 117405982891, all
34 steps, plus F1 run 39036074245, F2 run 39036074326 and F3 run 39036074316.
Its native log is 4,475,217 characters; artifact 12102781024 is 6,796,924 bytes,
SHA-256 e629686fb76c0f4a39774d2666887c560909a86f17f6a155215100113b6dcb5c.
Those four successes could not compensate for the failed focused gate.

The accepted repair adds explicit Batch, Result, Option (Except Diagnostic
Result) and List Nat annotations in the host harness. The source program,
native oracle values, construction checks, runtime assertions and assurance
refusals are unchanged. The first healthy native run completed before the
non-force update. All five gates were then rerun at the corrected SHA.

Compared with the previously accepted fixture/workflow, changes are confined
to 204 additive fixture lines and eight additive workflow lines. The original
source outside those insertions is preserved.

## Exact sources and artifacts

| Item | Git blob |
| --- | --- |
| Accepted P0 fixture | f8713003826ece976b2712b2c7cf669d11192d6e |
| Focused workflow | cd49fea4c0b17e140c109da294fd127bfe413ef4 |
| Shared scalar runtime runner | 83f069245f7b94fa5a9bce4779ab6619b46512c3 |
| Sole v7.2 language reference | 694115223777599ba28ee175e14bb642b7b6aa4b |

| Gate | Published artifact | Bytes | ZIP SHA-256 |
| --- | --- | ---: | --- |
| Native Linux | [12102584599](https://github.com/dwijayuda/pskernel/actions/runs/39037331359/artifacts/12102584599) | 6,796,905 | `7918b7afaff029352de34a03f1fda602c59bac6b748ab8ea438956e972960a92` |
| Focused M3 | [12103270800](https://github.com/dwijayuda/pskernel/actions/runs/39037331391/artifacts/12103270800) | 3,038,425 | `1dfd2f978908211bac2e35652c66f65d529ad49955617efd9a377728423c2380` |
| F1 canonical model | [12102901344](https://github.com/dwijayuda/pskernel/actions/runs/39037331355/artifacts/12102901344) | 1,674,681 | `3161180f469d2dc616fde126b9c6887a395b0d63ffc7943519cc8aab3463e1a3` |
| F2 logical operations | [12103285058](https://github.com/dwijayuda/pskernel/actions/runs/39037331395/artifacts/12103285058) | 1,798,323 | `638e158688b29753608e76a747b481a698c52f239b4e11919b842bede55583db` |
| F3/F4/platform | [12103045934](https://github.com/dwijayuda/pskernel/actions/runs/39037331418/artifacts/12103045934) | 295,038 | `f1637ef8dae729786c22dc7e5b25e75eacc57517ea76153843a73f0c0b93f843` |

Focused artifact 12103270800 contains **286 files / 3,038,425 bytes**.
The uploaded ZIP digest in the job log matches the artifact API.
The inspected evidence is the published job logs, pinned source/runner
assertions, artifact metadata and upload receipt; ZIP contents were not
independently reopened. The focused log has **8,253,670 characters**.
The published native log has **4,475,093 characters**.

## Scope and continuation

Lean is pinned to 4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
The sole forward language reference is PSCV0_LANGUAGE_REFERENCE_v7.2.md;
v7 and v7.1 remain historical provenance. The existing
[stage directive](PSCV0_V72_STAGE_DIRECTIVE_2026-10-16.md) continues to govern
new slices.

The next coherent candidate is bounded own-binder-dependent omitted-result
inference with checked natural families, preserved scope/rollback and explicit
resource propagation through its actual production owners. It requires its
own five-gate compiler/test qualification; this P0 receipt does not credit it.

The full selected P0 matrix, broader indexed binary deriving, nested/source
induction, larger changing WF packs, arbitrary measure telescopes and general
mutual WF remain open. M3+B, M4 and M5 are not complete. Keep all fixed assertion,
assumption, resource and source-closure policies. Use fresh-HEAD non-force
updates and let healthy native CI finish before another compiler/test push.
