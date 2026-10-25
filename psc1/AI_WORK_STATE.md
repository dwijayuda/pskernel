# PSC1 AI work state

Updated 2026-10-26 Asia/Jakarta. Active branch feat/psc1-binding-trace-20261025,
stacked on qualified PR #185 HEAD583f795f91f8ee83dc59556dc886a71de7950f6d.
R2b source-binding tracing is in implementation; new source qualification pending.
The following R3 evidence retains its original source identity.
Use connected GitHub and Linux Actions only. Fetch HEAD before every write and
use single-parent expected-HEAD non-force updates. No merge or npm publication.
The [roadmap](docs/PSC1_DEVELOPMENT_ROADMAP.md) owns the remaining-work queue;
dated receipts own evidence. [Prior work-state snapshot](docs/history/AI_WORK_STATE_BEFORE_R3_QUALIFICATION_2026-10-25.md)
preserves previous progress/failures without treating historical claims as current.

## R2b implementation in progress

The production elaborator now has an opt-in source trace at actual local allocation
and term-name resolution sites. Declaration-local event ordinals distinguish reused
raw local IDs. Successful scope restoration retains event history and restores the
outer active-binding map; failed branches yield no context/log. The existing
declaration routines share one implementation with a tracing flag; normal compiler
entry points remain disabled and do not accumulate events. No second resolver or
elaborator is added. Foundation commit35633131849fab031e5a459f2c0d876204231182 passes Linux
run40212099555/job121225316762:122 modules under both grammar censuses,
closure83d3497bf758fabc7bb2fcb78c658ac6687657cc199549732dd0a90aed5e565b.
Six actual elaboration cases preserve exact declaration admission bytes and pass
official Lean admission, including raw-ID reuse, branches, lambdas, match, Id do
and Except do. Disabled traces stay empty and invalid typed source still refuses.
The production module pipeline shares the opt-in implementation through real batch
origins. Linux40213400247/job121229268168 passes native module parity, official
admission, exact selected-definition alpha comparison and public/other-Core refusals.
Host implementation8fab91a6 plus grammar-fixture correctione04b9ae0 passes
40214342888/job121232132478:14 actual checked local renames and31 negatives under
both grammars. Inputs use the existing qualified printer for PS, then the real PS
parser/elaborator/checker. No parallel resolver/compiler is introduced.

Host indices are genuine opaque capabilities; source/member/snapshot/event identity
distinguishes raw-local-ID reuse. Both actual endpoints receive independent official
Lean admission and strict IR. Local rename compares all source-bound references
under an explicit byte-offset/binder correspondence; native Core comparison keeps
the selected public type and every other declaration exact, with existing Core
alpha equality for the selected definition value only. Candidates are copied bytes;
neither the API nor developer CLI writes project sources. Headers, partial,
normalized, ambiguous and unlocated binders refuse; structural direct self-calls
explicitly mark incomplete coverage. R3 literal graph/IR equality is unchanged.
Expanded malformed-wire, checker/tool/CLI and all-seven-backend/compiler-source
integration are implemented next and remain pending actual Linux results.

This is not yet qualified R2b, complete source tracing or rename. Structured
recursion, synthesized and normalization provenance, data declarations, exact
source transport and binding-aware editing remain to finish. Preserve the R3
and frozen package identities below; never reuse them for the changed compiler.

## Preserved qualified R3 source and assurance

The active portable compiler has 121 modules and 4,677 source Core members:
77e2173db1ffd86e7f7400c25986e9c23ec8975c4ff773e9489d89d5632dcacb.
Only Ps.Syntax.PrintLean changes inside the previously qualified closure.
The printer groups low-precedence/nested-match forms and threads indentation
through a decreasing-fuel fold compatible with PSC1's existing recursion rule.
No parser, structural-recursion, fuel, checker or memory/stack rule is weakened.

Implementation and tested merge 665cdf811d139adedabe895074618db12c6b55c0 share
tree 10c1ff320495dca5bbe6ae61eb0cc879c799ed18.
Final documentation descendants must preserve this source tree and pass their
selected final gate. This is different from the frozen installed compiler below.

## R2a and R3 result

Read-only declaration ownership (R2a) is qualified at a77ec1a8153d94ff8586a3dfa37df521e75df501:
focused 40200895349, ordinary 40200961302, all selected dependencies and 37/37
finite criteria, zero blocked. It binds actual elaboration batch/member origins
to opaque source snapshots, with tagged Core names and synthesized ownership.
It grants no reference-resolution or rename authority.
[API](docs/PSC1_SOURCE_OWNERSHIP.md),
[receipt](docs/PSC1_SOURCE_OWNERSHIP_QUALIFICATION_2026-10-25.json).

Checked conversion (R3) passes run 40206625342/job 121209121451:
eleven focused conversions/fourteen refusals, actual converted 11-module
PracticalCli JSON/file execution, and all 121 compiler modules Lean -> PS -> Lean.
Original/final closures require independent official Lean admission, strict IR,
literal private canonical admission/original-IR byte equality, ordinary logical/
body pairing, partial names and ordered source/member ownership. Raw comment
bytes/order are retained; body-note movement requires explicit owner-notes.
The pinned Linux developer CLI returns candidate JSON/origin maps only and never
writes source files. This finite correspondence is not formal source preservation,
R4 effect equivalence, binding-aware rename or publication.
[Guide](docs/PSC1_CHECKED_SOURCE_CONVERSION.md),
[receipt](docs/PSC1_SOURCE_CONVERSION_QUALIFICATION_2026-10-25.json).

Full source conversion takes 110,726ms forward / 152,009ms reverse in that run,
excluding initial capture/original index construction. Scope fixtures compare
actual checked graph bytes and pass official Lean source parsing through nesting
depths 1/2/4/8/12, plus let/if/lambda contexts. Zero fuel still refuses.

Genuine new-source Wasm G1 40206504499/job 121208580049 PASSED:
121 modules/both grammar censuses, 40 cross-target cases and nine envelope refusals.
Request 96f8011fb52889fc9429402f668770fd43643714 changes only controls from
ef7531ed; subsequent host optimization preserves portable closure 77e2173d.
This is G1-only, not new G2/G3, fixed-point or self-compilation performance evidence.

Ordinary source run 40206628424 PASSED every selected dependency, full Linux-scoped
job121212292606 and final gate121218977024: 37/37 finite Practical Core criteria
qualified, zero blocked, releaseReady=true within that contract. It covers all
seven backend mappings/both grammars, runtime/negative/minimum-Python checks and
actual installed native npm/source-library tests. Full artifact12605114230 ZIP
f8357d2cbef9bc3a0bd4cf17e8a07d0d85175bddc4cf9a7c74d83e2bbd5f9e7e.
This is finite source qualification, not complete universal-release qualification.
Selected regressions retain 359 lexical
captures/49 refusals, ownership both grammars/ten production-path comparisons/
42 refusals, and conversion11/14.

## Readable source artifact and measured optimization

[121 reviewable PS modules](https://github.com/dwijayuda/pskernel/actions/runs/40206663537/artifacts/12604625486)
are exported from identical PSC1 source under control
9df702a46eafb5709ef3cc8ffb78d3eac2754a3a. ZIP SHA256
6bffb02c4122ac34f4299509905513569ab9ed2a3cea956296e0f8d0e9d43f73.
SOURCE_MANIFEST.json records all source/tool hashes, origins and measurements.
Candidate closure 961056d60107aa485e854f8eb035d6c1a298acf4c504d87a6fd70e2c4c488272
is not a promoted compiler/package source.

The optimized exporter took 360,068ms and host-only peak RSS 1,197,708KiB versus
the earlier 420e647b export's 526,720ms / 1,620,508KiB. These are different runs and
printer sources, so they are observed measurements rather than a controlled
benchmark. Redundant provisional token capture/elaboration/checking is removed:
a validated, unaccepted parsed layout preview guides retained comments, then one
final candidate capture/elaboration/independent check follows. Independent
original/final admission and literal graph correspondence remain mandatory.

Failed scope run 40202979940, intermediate arity run 40205234865 and G1 census
failure 40205367044 remain preserved. Superseded ef753 run 40205811877 was canceled
after forward conversion for the optimized successor. The receipt records exact
failure/source identities; none is relabeled as a pass.

## Preserved qualifications and distribution boundary

| Scope | Exact existing evidence |
| --- | --- |
| R1 lexical capture and stale-safe byte edits | c577d498, focused40191237137/source40191245319; [receipt](docs/PSC1_LOSSLESS_SOURCE_QUALIFICATION_2026-10-25.json). Lexical only. |
| Character diagnostics | d70221c9, focused40195964028 (664 positions), WasmG1 40196021448/source40196244138; [receipt](docs/PSC1_CHARACTER_DIAGNOSTIC_QUALIFICATION_2026-10-25.json). Two scoped ordinary Lean leaf theorems, not whole-compiler proof. |
| Documentation, host formatting, 27-definition Wasm extraction | 446a0f21, correspondence40184892095/package40184641007/WasmG1 40184951724/source40184897417; [receipt](docs/PSC1_READABILITY_QUALIFICATION_2026-10-25.json). |
| Frozen four-engine self-hosting | 120 modules, daa735017e34ee94da79d747c363237b4adbc4ef; [receipt](docs/PSC1_UNIFIED_FOUR_ENGINE_QUALIFICATION_2026-10-25.json). Genuine G1/G2/G3 and exact fixed points; unchanged payloads. |
| Current installable host package | proofscript@0.1.0-psc1.4, 3,704,169 bytes, package40184641007/artifact12595861227; [install guide](docs/PSC1_SLIM_UNIVERSAL_PACKAGE.md). |
| Official kernels | Native40155475188/Wasm40158859386, five-platform kernel tests; [receipt](docs/PSC1_KERNEL435_QUALIFICATION_2026-10-25.json). Full root-platform publication remains separate. |

Frozen compiler closure:
07eedac1888aad3d4192664cea8d21a515d23985f3befd6cb365d0194fee53af.
The slim root embeds frozen G3 JS/TS and the mandatory official C++/Emscripten
linear-memory Wasm checker. Rust/compiler-Wasm execution and native checking are
explicit pinned optional packages; Python/PHP output providers remain optional.
Checked generated output/publication is JS and publication is qualified on Linux.
Other exposed output mappings remain candidate-only; other OS publication refuses.
All seven native mappings and prior package/kernel qualifications are preserved.
Source developer tooling is outside the slim root hostFiles allowlist.
No new source, generated executor or package is silently promoted.

## Next work and fixed policies

The full ordinary source gate passes; final documentation descendants must also
pass their selected gate while preserving the qualified source baseline.
[Executable continuation](docs/PSC1_SOURCE_REFACTOR_CONTINUATION.md) identifies exact
remaining implementation sites and gates. Next is R2b source-bound local binder/
reference tracing at actual elaboration resolution, then one capture-avoiding
rename with explicit Core/API correspondence and affected-closure admission.
Context-local raw IDs are not global source identities. Do not add a second
elaborator, textual global rename or blanket equivalence claim.
R4, slim real application/source-package coverage, checked generated non-JS output,
portable transactions and final clean changed-source/platform release remain pending.

Keep official Lean4.35.0/eb6cafb7290e8bd5f2937522d8d804f58f02bafc, trust0,
2M heartbeats/20k recursion, strict original/transformed IR, exact logical/runtime
pairing, semantic fuel, negative/resource/ABI refusal policies. Compiler/tool/G1/
corpus240s and checker120s remain. Manual Rust3600s and other1800s correctness
profiles apply only to their existing G2/G3 requests. The original240s selfcompile
performance target is unqualified. The compiler Wasm GC architecture is unchanged;
the independent Lean kernel stays official C++ linear memory.
Use dependency-selected CI, exact-source caches and early whole-source censuses.
No need to rerun unchanged frozen generation chains for documentation/host work.
