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

The full-state carrier candidate on
`research/psc1-pskernel-v2-carrier-20261021` is undergoing separate exact-source
qualification. Its initial source is
`6cbeb1b3587335545d9d3a2bdd4b99c0c2244b4a`; this architecture description does
not promote it or inherit integration889's test results.

`Checker/ExprV2/DefEq.lean` owns recursive DefEq callbacks. The ordered path is
entry fuel/depth guards, exact syntax/success-cache checks, quick and binder
spines, mandatory cheap core normalization, proof irrelevance, the natural-number
prefix, ordered definition selection/lazy delta, full-shape rules, matching
projections and structure/String/unit terminal rules. Every callback receives
the exact predecessor fuel fixed by its owner; recursive loops consume only
their own bound. A failed argument shortcut only suppresses that same retry and
still performs ordered unfolding. Successful DefEq publishes the original
requested pair.

`Knot.lean`, `WhnfOwned.lean` and `CheckCallbacks.lean` connect public/core WHNF,
recursor reduction and inference using the complete seven-field CheckState.
Callbacks return the current owning state directly: its fresh counter and
checked-inference, infer-only, success, failure and unfold caches must survive
each transition. Pure WHNF helpers lift their output against that current state.
The old four-field WhnfState interfaces are thin compatibility boundaries,
rather than a second semantic algorithm.

The subsequent admission/public-boundary repair carries that complete state
through mandatory declaration sort/proposition normalization and supplies the
real fixed DefEq callback to standalone public DAG WHNF. Its extra8 owner,
12 propagation,336 admission differential and168 public-WHNF comparisons,
and11 additional local lemmas still require exact-source qualification.

`CheckCore.lean` remains the shared checked/infer-only worker with distinct
judgment caches. Proof irrelevance cannot publish a checked body judgment.
An unsuccessful Nat predecessor candidate discards its speculative arena.
Scope exit restores semantic caches and preserves only the allowed fresh-name
progression and appended arena. Typed local lookups use the current CheckContext;
mixed legacy-local input retains its explicit unsupported boundary.

Original same-batch type/body IDs become owning references only after checked
admission. Safe definitions and theorem bodies share their operation state.
Unsafe/partial mutual members use private work environments and fresh owners
per member; publication is atomic. Ordinary non-K generated recursor references
come from validated admission and private appended nodes, never supplied metadata.
Quot and ordinary constructor-major recursor paths have direct DAG implementations
in this candidate. K, structure-major and String-major normalization remain
explicitly incomplete and require their own migration and qualification.

The new native and generated carrier matrices require42 state probes,56 exact
failure/decline cases,540 V1 differential cases,38 DefEq state probes and44 DefEq
failure/decline cases. Ten local carrier lemmas supplement existing metadata,
scope, fuel and equality proofs. These counts describe test coverage, not proof
of the entire checker.

## Remaining whole-operation fallback inventory

There are four production fallback sites. They remain explicit and preserve
the complete original operation's resources and failure semantics.

| Site | Trigger and remaining work |
| --- | --- |
| `API/Dag.lean: psKernelDagCheckTerminalOrOriginal` | Checking/inference outside the supported owning DAG rules, including missing or mismatched same-operation type/recursor references |
| `API/Dag.lean: psKernelDagWhnfExpression` | Reductions outside the direct DAG worker, including K and unfinished major normalization, unsupported recursor descendants and missing owning references |
| `API/Dag.lean: psKernelDagIsDefEq` | Unsupported descendant callbacks or missing owning references; the ordered prefix, lazy delta/projection, full shape and final rules now have DAG paths in the carrier candidate |
| `API/DagAdmission.lean: psKernelDagAdmitDeclaration` | Inductive construction/admission and declaration cases not handled by direct admission |

Before these sites run, `psKernelV1RunDag` still decodes the validated arena once.
Supported operation results may decode newly appended nodes for the existing
public recursive-expression result type. Static admission guards now scan the canonical DAG with operation-owned
visited state; the initial public decode and remaining whole-operation admission
fallback are still present. These are acknowledged representation
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
4096 kernel fuel,60-second per-case wall limit and V8
`--max-old-space-size=2048` cap. That existing cap limits old-space heap rather
than operating-system RSS. A diagnostic job may finish
successfully while every profiled kernel case times out. Timeout-to-timeout
comparisons are censored observations, not a numeric speedup.

Completion requires: (A) a source-qualified usable scoped provider, (B) all
promoted operations implemented through complete DAG-native checking without
these fallback sites, and (C) all 193 applicable Arena records with legitimate
safety-contract classifications and no unexplained timeout/mismatch. Gate B
and gate C remain open. The dated work state reports gate A per exact revision.
