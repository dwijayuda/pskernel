# R7–R8 continuation guideline: actual caller and independent substitution

Status: scoped proof/portability qualification passed at source
6a22235dfc235b1707bed3c5d5204b6aa1f01217. Broader Linux qualification passed at source-equivalent CI checkpoint
0734fa4f209da0df9343de0fbd6657311f1223e6; installed CLI passed at CI-only
0de2f52b79bfe160a3b978b0fbd22864b45d10a8. Do not call full compiler support
complete. The [usability/full-compiler contract](PSC1_MIN_KERNEL_USABILITY_PLAN.md)
and [C1 architecture guideline](PSC1_MIN_KERNEL_FULL_COMPILER_GUIDELINE.md)
remain the overall completion definitions.

Execution: user's GPT-6.1 Sol / High setting. All project proofs, builds,
compiler execution, tests and resource measurements run on GitHub Actions Linux.
Use fresh remote refs, one-parent commits and nonforce expected-HEAD updates.
Protected base 94e0c13f6a4b434f73c859cc0c716cb6fb8d1340 remains unchanged.
Preserve the [R6 guideline](PSC1_MIN_KERNEL_R6_GUIDELINE.md), earlier guards,
10/10/20 minute focused budgets and 256 MiB V8 old-space limits.

## What R7 proves

CompilerCaller imports the actual psEraseRuntimeExprWithFuelWorker and public
wrappers, not a substitute eraser. Values are Nat and String literals. Eligible
covers positive-fuel literals and recursive Core lets whose actual classifier
result is type or proof. The recursive premise is eligibility of the actually
instantiated body at the actual remaining fuel and nested scope; it does not
assume any eraser result.

Eligibility induction constructs an IR result and proves both the actual
worker equation and literal target evaluation. Source evaluation is a pure
literal/zeta relation. Public/default wrapper theorems connect fuel explicitly,
including the default 4096. Scope equations state the real nested transition:
local/type/runtime/erased contexts and names survive; currentDefinition becomes
none. A Nat-only bridge connects literal target evaluation to R5's IR relation.

The ten reports are fuel_zero, nested_idempotent, nested_context, nested_names,
eligible_positive, eligible_source, eligible_erases, public_preserves,
entry_preserves and natural_bridge. Three are axiom-free and seven propext-only.

These premises do not establish classifier soundness or typing. Runtime lets,
free variables, functions/calls, fresh capture names, closure/carrier semantics
and target engines are outside the worker-preservation domain.

## What R8 adds

CompilerSubstitution defines lifting and single capture-avoiding de Bruijn
substitution as inductive relations. Their definitions call no Core lift or
instantiate function. A bound variable below the cutoff stays unchanged;
lifting shifts those at or above it. Substitution preserves lower indices,
replaces the selected index with a lifted replacement, and lowers larger
indices. Type/body/value children follow their correct depths: lambda/forall
and let bodies increase depth; their type/value children do not. Projection
targets retain depth. Free/metavariables, literals, constants and sorts are
preserved as syntax.

All eleven PsExpr constructors are covered by constructive derivation and
exact correspondence with the actual Core workers, plus uniqueness and the
psExprInstantiate1 wrapper. This is syntactic refinement, not well-typed
substitution, metavariable resolution or a model of every Core expression.

An independent literal/zeta SourceEval uses the substitution relation. Forward
and reverse theorems prove equivalence with R7's source relation. Composing that
equivalence with the actual eraser theorem gives public/default correspondence
under R7's unchanged eligibility premises. The source relation is pure zeta;
it does not evaluate erased values and is not a full call-by-value semantics.

The fourteen fresh names in Ps.MinKernel.CompilerSubstitution are:

- lift_constructive, lift_correct, lift_iff, lift_unique;
- substitution_constructive, substitution_correct, substitution_iff,
  substitution_unique, instantiate1_derives;
- source_forward, source_reverse, source_iff;
- public_independent and entry_independent.

Every R8 report is exactly propext-only. No choice, quotient, sorryAx or new axiom
is admitted. The full retained suite has 259 distinct reports: 42 axiom-free,
217 propext-only. This was recomputed from hash-verified adopted-source artifacts,
deduplicating repeated build messages and checking for conflicting reports.
Counts audit dependencies; they do not measure whole-compiler soundness.

## Actual source and executable observations

Ps.MinKernel.Tests.CompilerCaller is a separately registered test-only root.
Its callers invoke the real recursive worker. Six depths (0, 1, 2, 4, 8, 16),
type/proof branches, sufficient/short fuel and eleven scalar values produce
264 native/generated cases: 132 sufficient-fuel and 132 short-fuel cases.
Values include empty/NUL/Unicode/quote/backslash/newline text, zero and
large naturals. These finite observations supplement the general theorems.

The exact 20-module caller closure passes source/target/original-IR guards,
strict TypeScript and pinned official Lean 4.35.0 replay. The official commit is
eb6cafb7290e8bd5f2937522d8d804f58f02bafc. Provider/semantic/strict-Sh1
qualification flags remain false. Official replay is a test oracle here,
not public minimal admission.

| Caller artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| TypeScript | 860476 | 29997fd41a9f84074ed28e7051b31837adeb32ef23c1161f8be6d36d45d7b34e |
| JavaScript | 1135702 | 4f16333f8e27436754883f00ca81ddaddd3cfb3905c7e41bcc716658ccf1735a |
| Original IR | 848374 | d9a1abaf8a953d23c69b35a53601120f8e03435152ba341c5d09f0163cfd264a |
| Transport packet | 3210435 | 7b9ee71b8b2431ef8092ff7f2f332b16bf2cebdbd2e6d6289586e54d8d706a71 |
| Canonical packet | 3210434 | 643c79cd61852d0b3731279df1e6d904c2b6d702da974e77e563b20681db937c |
| Native cases | 31925 | c4222935462cac1349b83b2ae6f8f01231db1a1cb2b1684debf87b417f3f6fab |

The canonical adapter removes exactly one final LF. No other packet byte changes.
The caller packet is not claimed minimally admitted. It exceeds the stable R4B
2 MiB limit; no limit or rule changes were introduced by R7/R8.

## Usable checker and full compiler boundary

U1 remains delivered as the private, unpublished standalone R4B tarball documented
in [the usage guide](PSC1_MIN_KERNEL_USABLE_GUIDE.md). R7/R8 proof/test roots are
excluded from its ten runtime source roots; they add no rule to the shipped byte
checker. The exact original 42237-byte tarball SHA-256 is
42d7d524d903885f0f7d06b83fa21b9755759ff457d6d24b3df503196ed51929.
Later CI packages can differ in source metadata; never relabel their hashes as
that original deliverable.

The complete compiler graph remains 124 modules, 4743 source Core / 4748 logical
members, 3466 records, 115 prelude declarations and 29889352 packet bytes.
The same five partial bodies and 60 foundational contracts (35 directly used)
remain obligations. Inventory SHA-256 is
2e2e1a9f0bd6bf4f1daf31995273162a5532dcd13a87f51c2cb9dd8fffe65f2e.
Fully compiler-qualified coverage is 0/124 and Practical Core 0/37; no min G1/G2/G3 are qualified. The later [actual module checkpoint](PSC1_MIN_KERNEL_MODULE_GUIDELINE.md) records 1/124 fresh Min-admitted source closures and 525 finite Source runtime cases, without changing full qualification.

C1 requires scalable bytes/parser/state refinement and a sufficient inhabited
dependent/universe/foundation model. C2 requires actual typed recursive
preservation, telescope omission, freshness, closures/carriers and target
semantics. C3 requires the real public-min complete compiler generations and
installed user flows. Ordinary G1 regression success is not a min generation.

## CI failures and the shared repair

Initial R8 candidates 739bc695 and e9d8afef failed elaboration. Repairs made
binders/pinned Nat equations explicit and avoided the generated below-name
collision. Candidate cf947745 passed fourteen reports; adoption preserved U1
documentation and primary history.

R7/R8 broader jobs also exhausted their existing budgets downloading an
unnecessary elan installer. These are retained setup failures, not green runs.
Source-equivalent CI-only commits preserve all checker/compiler/proof/runtime
blobs. A shared Linux-Actions-only install-pinned-lean.sh now replaces fourteen
duplicated installer blocks across nine selected workflows: reuse an existing
elan, bound cold download/installer attempts, then retain repository-pinned
toolchain checks. No test body, cache key or job time limit is relaxed.

Use final live workflow status and the dated receipt; do not infer green from
a previous partial job. Build/portability and broader/installed/reporting evidence
must retain their own source SHA and run attempt. A CI-only diff may establish
source equivalence; record it explicitly rather than pretending every run used
the same commit.

## Continuation discipline

The current priority is actual module qualification, starting with the first
real 1/124. Build and retain the dependency-aware matrix and test fresh complete
source-module packets through the unchanged public API. Prioritize
Ps.Foundation.Source's two Nat-based records. Separate diagnostic projections,
fresh Min-admitted source closures and fully qualified compiler modules.

R9 remains parked at 72f51789 after its full packet exceeded the 120-second
generated-phase deadline. Fourteen reports and 39 fast cases passed, but that
does not qualify the experiment or any compiler module. Resume performance work
only when a real module rejection shows it is required. A digest traversal is
never parser/admission evidence. Physical adapter fidelity and full parser/arena
refinement remain open.

Continue C2 runtime binding with independently stated environments and actual
scope/name transitions. Do not extend literal/zeta evaluation to unrestricted
runtime lets and label it typed preservation. Freshness, classifier/type laws
and primitive string behavior need their own proofs or explicit open premises.

Review exact production diffs before adoption. Keep official Lean Wasm default;
production min/dual refuse PSC1_MIN_CANONICAL_BRIDGE_UNPROVED. No protected-base
write, force push, merge, npm publication, fixture whitelist or provider fallback.

## Terminal checkpoint evidence

- [Focused source 6a22235d, run 40680314750](https://github.com/dwijayuda/pskernel/actions/runs/40680314750): all proof/portability/package jobs passed.
- [Focused CI-only 0734fa4f, run 40694473038](https://github.com/dwijayuda/pskernel/actions/runs/40694473038): shared bootstrap and unchanged full focused suite passed.
- [Broader Linux 0734fa4f, run 40694479660](https://github.com/dwijayuda/pskernel/actions/runs/40694479660): every selected dependency, full/linux-scoped 122843776763 and final gate 122860388470 passed; benchmark unselected.
- [Installed CLI 0de2f52b, run 40691028398](https://github.com/dwijayuda/pskernel/actions/runs/40691028398): preflight 122825565247 and installed 122825918952 passed.

The 6a22235d..0734fa4f interval changes CI workflows/helper only; checker,
compiler, proof and packaged runtime source blobs are unchanged. The installed
run has the same production/proof source blobs. The dated receipt retains
these separate SHAs instead of asserting one run/head for all evidence.
