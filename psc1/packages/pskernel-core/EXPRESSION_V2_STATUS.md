# Expression V2 architecture and qualification status

The target is Lean 4.35.0 at `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
The portable semantic root is `src/Ps/KernelCore/SelfHost.lean`. Native Lean
and authentic PSC1 → TypeScript 7.0.2 → Node 22 execute the same checked rules.
Exact qualification belongs to a source SHA and its terminal Actions jobs;
see [AI_WORK_STATE.md](AI_WORK_STATE.md). This document describes source
ownership and outstanding migration work, not a global soundness theorem.

## Containing audit correction

The new docs/ completion handoff uses exact3aa as the fully observed scoped A
baseline. This source adds String-literal projection expansion with complete
callback ownership, explicit-argument pair lookup, and V1/V2 cheap-recursion
cache-mode publication isolation. Fresh exact-source gates are required; see
the newest AI_WORK_STATE section. Full real-String dependency closure coverage,
the four fallback families and B/C/D completion remain open.

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

The full-state carrier at `4894fce8c7d048ae188495bc2090fedfddf7fcb4`
has terminal native, authentic generated-JavaScript, canonical-source, proof
and provider qualification. Integration source
`a2590cc15c764dae9c6abfb941d6c3155ead5c81` is independently qualified for the
scoped developer provider. Their history-preserving integration merge requires
fresh exact-source gates. The work state records those identities; predecessor
qualification does not establish a complete V2 replacement.

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
real fixed DefEq callback to standalone public DAG WHNF. Its extra eight owner,
12 propagation, 336 admission differential and 168 public-WHNF comparisons,
and11 additional local lemmas are part of its mandatory exact-source qualification.

`CheckCore.lean` remains the shared checked/infer-only worker with distinct
judgment caches. Proof irrelevance cannot publish a checked body judgment.
An unsuccessful Nat predecessor candidate discards its speculative arena.
Scope exit restores semantic caches and preserves only the allowed fresh-name
progression and appended arena. Typed local lookups use the current CheckContext;
mixed legacy-local input retains its explicit unsupported boundary.

Original same-batch type/body IDs become owning references only after checked
admission. Safe definitions and theorem bodies share their operation state.
Unsafe/partial mutual members use private work environments and fresh owners
per member; publication is atomic. Ordinary generated recursor references,
including K recursors, come from validated admission and private appended nodes,
never supplied metadata. Quot and constructor-major recursor paths have direct
DAG implementations. The current candidate also normalizes K majors, neutral
nonrecursive structure majors and String majors through the same full owner.

K resolves the recursor family from its checked private type, then performs
major inference, public type WHNF, expression-mvar index guards, candidate
construction/inference and DefEq in the original order. A false equality result
retains the entire returned state and the original major. Type universes, rather
than the recursor application's levels, instantiate the constructor candidate.
K conversion precedes the constructor shortcut; non-K retains that shortcut.

Structure normalization preserves the fixed callback sequence and requires
matching checked family metadata and a non-propositional structure type.
String normalization builds the canonical constructor form and always invokes
the owning public WHNF callback afterward. Natural, structure and String
normalizers feed one common recursor-rule pipeline. The raw WhnfState-only
compatibility helper retains its explicit limited scope. K/major tests and local equations pass at carrier4894; a new integration SHA
still requires all of its own terminal gates.

The new native and generated carrier matrices require42 state probes,56 exact
failure/decline cases,540 V1 differential cases,38 DefEq state probes and44 DefEq
failure/decline cases. Ten local carrier lemmas supplement existing metadata,
scope, fuel and equality proofs. These counts describe test coverage, not proof
of the entire checker.

The new recursor-major gates require126 public,504 core,360 independently owned
budget and432 reducer comparisons, plus4 complete-state sequences/40 failure
propagations,70 family/20 field controls and24 raw String callback probes/48
failures. Six genuine checked neutral-major cases and four direct declaration
admissions have native official controls. The deliberately ill-typed raw
String/Nat-rec probes measure callback behavior and are not admitted proofs.

K gates require108 public,432 core,648 reducer and96 independent-budget
comparisons,16 complete-owner/16 propagation/16 metadata controls and5 ordering
sentinels. Actual checked KUnit/KEquality declarations and theorem majors supply
six valid, three invalid and two strictly direct admission cases. Both generated
routes run the same matrices. Ten major and six K local theorems describe guards
and callback-state equations with explicit premises; they do not prove complete
recursor equivalence or global kernel soundness.

## Remaining whole-operation fallback inventory

There are four production fallback sites. They remain explicit and preserve
the complete original operation's resources and failure semantics.

| Site | Trigger and remaining work |
| --- | --- |
| `API/Dag.lean: psKernelDagCheckTerminalOrOriginal` | Checking/inference outside the supported owning DAG rules, including missing or mismatched same-operation type/recursor references |
| `API/Dag.lean: psKernelDagWhnfExpression` | Reductions outside the direct DAG worker, including unsupported recursor descendants and missing owning references; K/major normalization is qualified at carrier4894; each merge still requires its own gates |
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
