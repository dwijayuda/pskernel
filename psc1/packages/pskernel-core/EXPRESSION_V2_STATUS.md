# Expression V2 architecture and qualification status

The target is Lean 4.35.0 at `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
The portable semantic root is `src/Ps/KernelCore/SelfHost.lean`. Native Lean
and authentic PSC1 → TypeScript 7.0.2 → Node 22 execute the same checked rules.
Exact qualification belongs to a source SHA and its terminal Actions jobs;
see [AI_WORK_STATE.md](AI_WORK_STATE.md). This document describes source
ownership and outstanding migration work, not a global soundness theorem.

## Public boundaries

| Entry | Inputs and authority | Result |
| --- | --- | --- |
| `psKernelKernelSessionEmpty` and checked V1 API | Explicit policy/provider; environment starts empty and grows only through successful admission | Checked session or a typed error |
| `psKernelV1RunDag` | Untrusted paged graph and ordered commands; graph is replayed/validated before internal ID-based workers run | Atomic batch replies/session or an error |
| Canonical batch CLI/API | Strict canonical-admissions-v2 transport, safe definitions/theorems/inductive groups, fresh empty session, fuel at most 4096 | Versioned JSON acceptance/refusal/resource/transport protocol; no partial environment |
| Internal ExprV2 helpers | Canonical arena, matching IDs and declaration/local references belonging to the same operation | Internal attempt; an outer `none` requests complete-operation fallback |

Exported constructors and internal helpers are not additional safe untrusted-input
entry points. The current source profile cannot seal every constructor. A forged
reply, cache or declaration index is never evidence that a declaration was admitted.
Hosts must construct fresh sessions and use checked APIs; the canonical provider
offers a concrete transport boundary that enforces that discipline.

## One DAG checking owner

`Checker/ExprV2/DefEq.lean` owns recursive DefEq callbacks. Its ordered path is
entry fuel/depth guards, exact syntax/success-cache checks, the existing quick and
binder-spine prefix, mandatory cheap core normalization, proof irrelevance, then
the ordered natural-number prefix and the complete definition-selection/lazy-delta
loop. The full-shape successor adds residual core WHNF, application/list and
function-eta/binder/sort/literal rules under the same owner. Matching projections
and structure/string/unit terminal rules still decline. This successor requires
fresh qualification;480 is the latest terminal-green scoped developer checkpoint.
The callbacks use the exact predecessor fuel chosen by the owner; the loop
spends only its own recursive bound. The Nat lazy stage retains its separate
entry-fuel guard; predecessor comparison does not add another depth entry.
Unfold and failed-argument-shortcut caches belong to that owner. A failed shortcut
only skips the same argument retry and still performs ordered unfolding.

`CheckCore.lean` is the shared inference/checking worker. Checked and
inference-only judgments have separate caches. Proof irrelevance may infer a
proposition's type but cannot publish a checked body judgment. An unsuccessful
Nat predecessor candidate is discarded before eager reduction, retaining the
original immutable arena owner. Successful DefEq publishes the original requested
pair, not a substituted or normalized pair. Scope exit restores semantic caches
while preserving only the permitted fresh-name progression and appended arena.

Declaration references retain original same-batch type/body IDs only after
successful admission. Safe definitions and theorem bodies share their operation
state as required. Unsafe/partial mutual members use private work environments
and fresh per-member checker owners; publication occurs only after the whole
batch succeeds. No external recursor body is accepted as trusted metadata.

## Remaining whole-operation fallback inventory

There are four production fallback sites. They remain explicit and preserve
the complete original operation's resources and failure semantics.

| Site | Trigger and remaining work |
| --- | --- |
| `API/Dag.lean: psKernelDagCheckTerminalOrOriginal` | General checking/inference outside the supported owning DAG rules, including missing owning external type/recursor references |
| `API/Dag.lean: psKernelDagWhnfExpression` | Reductions outside the direct DAG worker, including general recursor/iota/Quot paths |
| `API/Dag.lean: psKernelDagIsDefEq` | Residual lazy projection, full-shape/final eta/congruence and unsupported descendant callbacks; definition selection and the ordered lazy-delta loop now have a DAG path |
| `API/DagAdmission.lean: psKernelDagAdmitDeclaration` | Inductive construction/admission and declaration cases not handled by direct admission |

Before these sites run, `psKernelV1RunDag` still decodes the validated arena once.
Supported operation results may decode newly appended nodes for the existing
public recursive-expression result type. Static admission guards still read
boundary-decoded recursive expressions. These are acknowledged representation
migration costs; the kernel is **not** a complete DAG-native V2 replacement.

The separately selectable V1 checker remains the semantic oracle. Its inference
cache predicate now rejects never-cacheable node kinds before performing a
recursive free-variable scan. A frozen pre-change predicate in the proof gate
establishes exact Boolean equivalence; neither cache contents nor resource guards
are changed. This implementation change does not erase historical benchmark
sources or make older results apply to newer source.

## Evidence and trust

Native regression and official-Lean fixtures, authentic portable-source checking,
canonical source reconstruction/rechecking, detached generated execution and
negative/resource sentinels are distinct gates. Provider packaging includes readable
source, `.d.ts`, source maps and their referenced sources. Artifact hashes bind
files to the checkout and run; they never justify a kernel judgment.

Local proofs cover selected metadata, cache scope, scanner equivalence and exact
entry/resource/owner facts. Four equality theorems and fifteen fuel-worker
function equivalences qualify delayed closure construction at e015; this is a
local refinement result, not a global soundness theorem. The new inference-cache equivalence and Nat entry/owner
lemmas are audited by the same native proof gate. Finite matrices do not prove
global type safety, algorithmic equivalence or semantic soundness of the whole
kernel/compiler/runtime pipeline.

Full-kernel DirectJS remains explicitly unsupported. No portable `unsafe`,
`extern`, unchecked axiom, compiler intrinsic or `implemented_by` path is added.
The obsolete native Bool/Nat evaluator does not participate in the 4.35 provider.

## Performance and completion gates

The integration suite measures complete public operations and declaration
admission, including validation and decoding, with separate construction, cold,
warm, RSS and retained-heap observations. Favorable selected admission results
do not establish a whole-kernel speedup. Construction and memory regressions
remain visible in [the measured checkpoint report](PERFORMANCE_2026-10-21.md).

The authentic Arena profiler runs original authenticated bodies at the unchanged
4096 kernel fuel and 60-second / 2-GiB host policy. A diagnostic job may finish
successfully while every profiled kernel case times out. Timeout-to-timeout
comparisons are censored observations, not a numeric speedup.

Completion requires: (A) a source-qualified usable scoped provider, (B) all
promoted operations implemented through complete DAG-native checking without
these fallback sites, and (C) all 193 applicable Arena records with legitimate
safety-contract classifications and no unexplained timeout/mismatch. Gate B
and gate C remain open. The dated work state reports gate A per exact revision.
