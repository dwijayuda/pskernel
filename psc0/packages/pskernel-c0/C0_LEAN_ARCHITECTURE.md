# PSKernel-C0 — Lean-native performance architecture

**Scope:** `psc0/packages/pskernel-c0/src/Ps/KernelCore/**/*.lean` on
`perf/pskernel-c0-v7-rust-20261012`.
**Semantic target:** Lean 4.34.0. **Authoritative verdicts:** the existing
PSKernel checker, not the experimental Rust engine or an incomplete indexed
evaluator. The original `pskernel-core`, the PSC0 compiler, and the Rust backend
are not modified in this workstream.

## Source-grounded architectural decision — 2026-10-13

**Canonical research:** [C0_LEAN4_KERNEL_COMPARATIVE_SOURCE_RESEARCH_2026-10-13.md](C0_LEAN4_KERNEL_COMPARATIVE_SOURCE_RESEARCH_2026-10-13.md). The most recent native C0 source comparison uses [`497df6a`](https://github.com/dwijayuda/pskernel/commit/497df6a39947aa3532b2d1a6ffe84342125fd2fc), full [CI 38305932773](https://github.com/dwijayuda/pskernel/actions/runs/38305932773) **success**; later research-documentation commits do not mean new source qualification.

**Representation is an optimization choice, not a correctness premise.** Official Lean 4.34 C++ uses immutable shared runtime expressions with packed hash, loose-BVar range, approximate depth and semantic flags; con-leche has its own Lean expression type with computed packed metadata and explicitly avoids mandatory global hash-consing; Sokonanoda/MathGraph use closures, neutral values and elimination spines. C0's accepting recursive source is still the authority; its opt-in hash-consed `Nat`-handle arena is a **candidate**, not a proved faster replacement. Prototype/test (A) direct structurally shared/metadata-rich Lean term objects, (B) optional indexed DAG, (C) closure/value evaluation, using identical full accepted operations and real corpora.

**Exact syntax and scope gaps:** official Lean 4.34 `binder_info` has `Rec`, absent from `PsKernelBinderInfo`; official `mdata` is structured metadata, C0 stores a Nat. Current exact round-trip tests apply only to C0's restricted representation. Specify explicit unsupported/declined boundaries rather than claim arbitrary lossless Lean transport. The current indexed node exposes Nat handles, derived metadata and unsealed external store structure: never use external handle identity, hash, or range to approve a checked judgment. Keep environment/local-level/evaluator context and original fuel/error/fresh-name provenance on caches.

**Algorithmic invariants:** official `type_checker.h` warns that success-only DefEq may be **non-transitive as a sound but incomplete semi-decision procedure**, so never adopt Lean4Lean's union-find equivalence closure without carrying its own proof/operational invariants. Official WHNF/DefEq staged ordering and generated recursor-rule type preservation are reference constraints. External C++ v4.34 and independent Arena conformance must precede trusted indexed/closure promotion. Note that Lean4Lean master currently pins v4.33.0-rc2; con-leche master pins v4.35.0-rc3, so neither master is an exact v4.34 differential oracle.

**Current order:** P0 external compatibility/conformance and negative soundness gates; P1 sealed syntax/term metadata/provenance; P2 simultaneous coherent closure-vs-indexed-vs-direct evaluation designs; P3 trusted combined WHNF/DefEq/inference/declaration acceptance; P4 independent-run library performance, memory and allocated bytes. Source acceptance remains mandatory throughout. No self-host/generated Rust/metatheory work.

## Newest indexed transition design — verified 2026-10-13

Source HEAD [`aae8f5f3`](https://github.com/dwijayuda/pskernel/commit/aae8f5f3385347eeade9880a306086d2dd96150c), [full native CI 38294019928](https://github.com/dwijayuda/pskernel/actions/runs/38294019928) **success**. This is an **indexed substrate and source-checker measurement qualification**, not completion of indexed accepting evaluation.

**Two distinct fingerprints are mandatory.** Every immutable `PsKernelC0StoredNode` now carries:

- `hash`: exact canonical-node interning bucket hash, including names and binder information. Equal *hashes* are never accepted as equal nodes; `psKernelC0NodeEq` confirms exact identity after a bucket hit.
- `checkerHash`: child-derived hash designed to agree *exactly* with `psKernelExprHash` on the decoded source expression. Source checker hash intentionally omits lambda/Pi/let user binder names and binder information. This value indexes a candidate source-cache bucket only: the actual source-cache equivalence relation still compares complete expressions under its own predicate.

`psKernelC0IndexedSessionRetain` continues to use an independent source hash and **exact** `psKernelExprEqual` for lookup, but now uses the just-interned root's cached `checkerHash` to publish a new radix entry without rehashing the complete source a second time. Nested binder and metadata roots, collisions and persistent snapshots have negative/differential tests. The session wrapper still runs `PsKernelCheckerSession` for **all acceptance**.

**Indexed lifting** gained a store-local, operation-local memo over the exact canonical term ID and binder cutoff, with a fixed shift amount per invocation. It preserves sharing and cutoff semantics. Exact recursive-source lifting, the previous recursive indexed worker and invalid-handle/fuel-independent tests remain oracles. It is not substituted for the accepting source checker and the large synthetic DAG microbenchmark speedups have no whole-kernel interpretation.

### Design contract for a future accepting indexed engine

1. **Ownership and syntax:** one canonical arena persists through an entire accepting session; internal node handles cannot cross separate arenas or mutable environment revisions. A handle denotes syntax **only**. Immutable snapshots preserve old root identities. Separate checked judgment caches by environment, local context, universe parameter scope, evaluator capability and resource regime. Do not infer contextual judgment equality from canonical term equality or a hash.
2. **Operational accounting:** represent original `fuel`, `maxRecDepth`, `recDepth`, error ordering, cache publication, fresh-name `nextFresh`, local `nextIndex`, and failure state explicitly. Cache acceleration cannot skip resource expenditure that would have produced the original error; match the historical checker *at the same budget*. Structural `depth` is an indexed traversal bound, **not** substitute for checked fuel.
3. **WHNF ordering:** preserve source public core WHNF -> native evaluator -> Nat reduction -> delta; core covers local free-var unfolding, beta/zeta/metadata, projections and recursor/iota hooks. Quotient and native reductions must use the exact Lean 4.34 policies; do not re-order or silently drop an unsupported family. Carry indexed handles through intermediate reductions; decode/encode only for well-defined foreign/native adapter boundaries, not entire recursive calls.
4. **DefEq and inference:** build one typed context-aware indexed worker for positive/negative DefEq, proof irrelevance, delta transparency, universes, dependent Pi application and binder-local inference. Keep the existing original checked source engine and independently rebuilt unchanged `pskernel-core` as differential authorities until full semantic coverage. Preserve exact alpha/equality policies and environmental precedence.
5. **Atomic admission:** definitions, inductives, recursors, quotient and their metadata must pass exactly the historical checked obligations and error rules before any environment update is committed. No partially admitted declaration on a failed indexed check. Verify local freshness and environment isolation across sequential declarations.
6. **Promotion gate:** qualify each reduction family with positive, malformed, negative, insufficient-fuel, native-evaluator and deep-local cases against both references. Then run real multi-declaration library corpora and controlled *complete-operation* ablations, repeated cold/warm throughput, p50/p95, thread-local small allocations, allocated bytes and RSS. If persistent indexing loses on genuine workloads, redesign it instead of preserving an obsolete representation.

**Measured end-to-end cost, not incremental indexing attribution:** 24 x 12 fully checked mixed safe declarations, repeated paired C0/original: [CI 38293885978](https://github.com/dwijayuda/pskernel/actions/runs/38293885978) p50/p95 **20/20 vs 38/38 ms**; [CI 38294019928](https://github.com/dwijayuda/pskernel/actions/runs/38294019928) **25/26 vs 47/48 ms**. Small-allocation counter **36,206 C0 vs 34,971 original** and whole-process VmHWM C0 **1,167,820 kB** vs original **1,161,116 kB** latest. The current C0 source path wins on this fixture but does **not** demonstrate memory savings, realistic library superiority or an indexed accepting checker.



## Architecture and invariants

The accepting checker still uses recursive `PsKernelExpr` throughout its
resource-bounded WHNF, DefEq, inference, projection/recursor reduction and
declaration-admission operations. Its environment lookup, local-context
shadowing, universe levels, proof irrelevance, native primitives and rejection
behavior remain authoritative. An optimization must never interpret a cache
miss, unsupported reduction or depleted fuel as a successful check.

The current native architecture has three distinct layers:

1. **Checked operations:** `Checker/Knot.lean` owns recursive orchestration;
   `Checker/Inference/Core.lean` and `Checker/Reduction/{Whnf,WhnfCore}.lean`
   preserve the checked semantics. C0's demand-driven stuck-application head,
   pre-guarded DefEq quick checks, family-aware single-variable substitution,
   and once-per-spine infer-only arity calculation reduce specific repeated work.
2. **Persistent acceleration:** `Runtime/Acceleration/Cache.lean` uses
   collision-checked radix-16 expression/pair indexes. The global declaration
   index and the local declaration index are separate, and are not a
   substitute for exact name or expression comparisons.
3. **Opt-in canonical DAG:** `Core/{IndexedExpr,IndexedReduction}.lean` and
   `Checker/Reduction/IndexedWhnf.lean` implement exact term sharing, capture-
   avoiding indexed substitution and a context-free WHNF fragment.
   `Checker/IndexedSession.lean` can retain syntax across session operations
   without exposing raw arena IDs. It still delegates **all acceptance
   decisions** to the recursive checker, and is slower on the measured small
   warm-WHNF workload. Do not enable it in production on present evidence.

### Local-context cost model

`Core/LocalContext.lean` keeps the ordered declaration list authoritative.
Short-lived binder contexts use direct list lookup and do not maintain a trie.
Deep contexts may build an immutable radix snapshot and collect later bindings
in a small, newest-first pending overlay. Lookup checks pending entries before
the snapshot, preserving correct shadowing. Publication adds older pending
entries first, so the newest exact-name match wins. Old context snapshots
remain immutable; `nextIndex` continues to determine fresh-name identity.

The former eager promotion after eight local declarations was measured to
regress complete checked admission. Isolated diagnostic builds showed that
suppressing the optional local index recovered the time without changing
accept/reject outcomes. Deferred promotion and batch publication recovered
near parity on a 160-declaration library chain while maintaining a substantial
512-local lookup advantage. See
[CI 38233818758](https://github.com/dwijayuda/pskernel/actions/runs/38233818758)
and `C0_BENCHMARKS.md`.

**Under native qualification:** local contexts retain the ordered declaration
list as the independent lookup reference. After 128 declarations a
`Thunk` may represent an immutable radix snapshot, with a 16-entry pending
overlay for later bindings. Constructing a deeper context records a lazy
computation rather than eagerly materializing or copying the trie. For
lookup contexts with `nextIndex` below 512, direct list lookup does not
force the index at all. Above that heuristic, a lookup checks pending entries
first and, if needed, forces the memoized snapshot with `Thunk.get`.
This moves potentially expensive index allocation from binder introduction
to the deep lookup that could amortize it.

Lean's `Thunk` has a pure logical model as a delayed computation and runtime
call-by-need memoization; repeated forcing of the same snapshot computes it
once. Its caching is **not** a kernel equality or acceptance rule. The
`nextIndex` threshold is a performance heuristic, not an assumption that the
fresh-name counter equals the number of declarations. Every lookup branch
uses the same exact-name/shadowing semantics.

This design avoids eagerly building an index for one-shot 192- and
320-binder declarations while retaining an indexed representation for heavily queried
512-local contexts. The native build, negative/differential tests, matched
benchmark, and memory results for the lazy strategy must pass before it can
be called a performance improvement. Any future non-Lean backend must
implement equivalent lazy snapshot caching or transparently fall back to
the original exact list lookup without changing acceptance.

### Substitution cost model

A controlled full-checker ablation showed that the original general-purpose
`instantiate1` removed an observed checked-application slowdown, despite
synthetic C0 substitution microbenchmarks favoring one-pass traversal.
The accepted hybrid now probes loose variables for binder-headed
lambda/forall/let expressions and returns closed terms unchanged. Other
expression families retain the specialized capture-avoiding one-pass worker.
On the admitted 48-argument application benchmark, this restored fully
checked time to parity while keeping the infer-only gain.
See [CI 38222841665](https://github.com/dwijayuda/pskernel/actions/runs/38222841665).

## Measurement and release gates

The repository-owned native CI does **not** run self-host, bootstrap/fixed-point,
generated Rust or metatheory tests. It performs:

- Full native Lake build, resource/soundness-sensitive negative and differential
  conformance tests, and native Lean microbenchmarks.
- Matched complete-checker tests against the **unchanged original
  `pskernel-core/src`**, built in a temporary package on the same runner with
  Lean 4.34.0. Checked workloads include WHNF, positive/negative DefEq,
  infer-only and fully checked applications, nested definitions and growing
  declaration environments. These are still generated fixtures, not qualified
  full Lean libraries.
- Optional private source-family ablations which change **only** the copied
  diagnostic package, never the original core. A diagnostic is not adopted
  merely because an isolated helper microbenchmark is favorable.

Record source commit, exact CI run, workload, elapsed time, failed as well as
passed cases, and process-wide peak RSS separately from isolated allocations.
Interpret sub-millisecond/integer-millisecond samples cautiously and preserve
regressions in `C0_BENCHMARKS.md`.

## Remaining architectural milestones

1. Quantify representative complete-module/library checking, cold and warm
   effects, allocation/peak memory, stack/fuel behavior and p50/p95 throughput
   across unchanged original and C0 builds.
2. Make canonical term ownership and environment/context provenance explicit
   within the **real** checker so that indexed WHNF, DefEq and inference can
   avoid round-trip reconstruction. No handle from another arena can be a
   trusted equality assertion; no cache result may cross environment/local
   scopes or forget resource costs.
3. Complete context- and environment-dependent indexed reduction families
   (delta, projections, recursors/iota, primitives, quotient, universes) with
   identical reduction priority, checked inference and exhaustion behavior.
4. Optimize full declaration admission and restored recursor/nested-inductive
   validation without shortcutting obligations.
5. Promote a new accepting execution path only after extensive positive,
   negative, resource-budget and original-kernel differential qualification,
   with **measurable** end-to-end performance and memory benefits.

**Status:** performance architecture in progress; no complete indexed
accepting kernel or whole-library superiority has been established.



## Indexed loose de Bruijn range metadata — qualified experimental substrate

The immutable source-owned canonical indexed store now retains three independent
node metadata fields: `hash` (candidate index only), `depth` (bounded decoder
and rewrite recursion) and `looseBVarRange` (maximum free de Bruijn index + 1).
Every node is interned after its children; the range is computed from child
metadata in O(1) per constructor. Lambda/Pi/let body ranges shift down one
after binding; domains and let values remain at the parent depth.

Indexed lifting skips subterms when `range <= start`. Indexed one-binder
substitution at binder offset `offset` skips subterms when `range <= offset`.
These shortcuts are exact for capture-avoiding substitution and preserve
canonical IDs of unchanged subterms. The unoptimized indexed reference
remains an executable differential oracle; positive/negative/metadata and
multi-offset tests protect correctness.

[CI 38239387122](https://github.com/dwijayuda/pskernel/actions/runs/38239387122)
passed the native source build, all negative/differential checks, performance
suite and matched original-core checks. On an isolated closed shared DAG,
reference instantiation took 885 ms versus 1 ms for the memoized pruned route
over 100 operations. This does **not** change the accepted checker or prove
complete-kernel speedup. Metadata from an unvalidated external arena, raw
handle equality across stores, and context-free indexed WHNF must **never**
be accepted as checked conversion or declaration admission.

A separate attempt to replace the recursive-source comparator with direct
structural recursion measured slower and was rolled back. In current
production, binder-aware substitution and demand-driven reduction remain
the established accepting-path optimizations; the indexed range is a
prerequisite for future zero-reconstruction evaluation, not permission to
prematurely switch the trusted execution path.


### Incrementally maintained live-local count (October 12 native checkpoint)

The native `PsKernelLocalContext` now tracks `declCount` alongside the authoritative `decls` and independent fresh-name `nextIndex`. AddLocal/AddLet advance the live count once; the lazy radix promotion policy reads it in O(1) instead of traversing a list of up to 128 locals each extension. A recursor continuation must not equate `nextIndex` with binder depth; `psKernelLocalContextWithNextIndex` preserves the entire previous snapshot, its overlay and count while altering only the fresh-name counter. An elevated fresh index over a shallow context must not force index promotion. This field is an internal acceleration invariant, never an acceptance/type judgment.

[CI 38240821497](https://github.com/dwijayuda/pskernel/actions/runs/38240821497) passed native source build, negative/differential regression and full original-core matched checking. Fully checked timings were near parity. The single-family private historical list-scan ablation [38241386784](https://github.com/dwijayuda/pskernel/actions/runs/38241386784) is required before attributing any checker speedup to this field. Additional one-field storage may change memory; process peak is not sufficient attribution.


### Full-checker counter-family qualification

The additional native [three-way ablation CI 38241386784](https://github.com/dwijayuda/pskernel/actions/runs/38241386784) isolated the new exact `declCount` predicate from the prior `decls.length` predicate in a temporary copy. The complete 160-declaration admission sequence was exactly **37/38/38 ms in both versions**; depth-96/192/320/512 and fully checked applications stayed close, with some noise. There is **no significant full-checker speedup or memory reduction** proven for this incremental caching change. Its role is to avoid an O(depth) list scan per pre-promotion extension and to express live declaration count separately from recursor fresh-name counter. It does not change trusted judgments or invalidate any previous negative performance findings.


### Safe accepting Pi-spine metadata and original resource provenance (2026-10-12)

Native C0 now includes a **measured accepting-path** large-application acceleration. `psKernelC0CollectCheckedAppPath` records frames for the precise original nested application traversal, threading the original decreased fuel and entered recursion-depth context into each position; `psKernelC0CheckAppFrames` performs the same fully checked argument inference, Pi exposure, eager reduction, DefEq and state updates as recursive source checking. `psKernelC0SourceLooseRangeWithFuel` / `psKernelC0PiBodyRangesWithFuel` analyze immutable term syntax only, with bounded recursion and a safe fallback. Range zero exactly means no loose de Bruijn variable and therefore no effect of `instantiate1`. After any dependent substitution or context-dependent Pi exposure the cached suffix list is discarded. This metadata is never used to decide well-typedness or DefEq. Only root spines with at least 64 applications take the frame route by default, with original recursive inference retained as both general fallback and independently callable differential oracle.

[Native CI 38246930574](https://github.com/dwijayuda/pskernel/actions/runs/38246930574) passed all required Lean 4.34 native gates; 12 typed 192-argument checked calls completed in C0 9/7/7 ms versus original 33/34/34 ms across 3 rounds; smaller checked paths remained near parity or slightly slower. Retain negative acceptance, fuel, environment/context provenance and admission invariants; the experimental indexed DAG itself remains **non-accepting**, and complete environment-dependent indexed WHNF/DefEq and realistic whole-library qualification are still outstanding.


### Shared checker context, compact frames and accepting declaration evidence

[Commit 0859097f](https://github.com/dwijayuda/pskernel/commit/0859097f6c1f8bdd6b869d477db829575bc2823c), [successful CI 38248015655](https://github.com/dwijayuda/pskernel/actions/runs/38248015655). Instead of retaining `PsKernelCheckerContext` in each `PsKernelC0CheckedAppFrame`, the frame stores exact remaining inference fuel, the checked argument and recorded `recDepth`. The original context remains immutable and shared. Planning still invokes `psKernelCheckerContextEnterRecDepth` per node in source order; each head/argument reconstructs its authorized depth. Critically, `maxRecDepth = 0` remains unlimited and does not advance `recDepth`; no homemade resource rule is substituted. State and error behavior are checked against the independently callable original core, including at the router arity threshold.

A new sequence of 32 *accepted* 192-argument checked definitions demonstrates end-to-end admission improvement, C0 **32/32/32 ms** versus unchanged original **130/131/132 ms** (three CI rounds). This is a large non-dependent application family, not broad representative library coverage; compact frame storage itself has no isolated quantified effect. Whole-process memory did not demonstrate an improvement. General nested checked application routing and full environment-sensitive indexed evaluation remain explicit P0 gaps.


### Production fuel-indexed checked Pi engine — qualified checkpoint

On [5c8a1e83](https://github.com/dwijayuda/pskernel/commit/5c8a1e83e22debd4fd6c365ba9666e834e8c5d66), the accepting `psKernelCheckWithFuel` selects `psKernelC0CheckAppRecursive` for root app spines of 16+ args; fewer use `psKernelInferCoreWithFuel`. The fuel-indexed worker is structurally recursive on `Nat`, reconstructs no frame list, shares context through the original source-level recursion, and carries only checked type, state and exact Pi-body suffix ranges. Every application invokes the original `psKernelCheckerContextEnterRecDepth`, original fully checked head/argument inference, Pi WHNF, eager policy, DefEq and substitution semantics. After any affected dependent codomain, precomputed metadata is invalidated. A bounded failed analysis never becomes acceptance. Unlike a cached trusted indexed evaluator, this never uses cross-arena term IDs for equality.

[CI 38252783408](https://github.com/dwijayuda/pskernel/actions/runs/38252783408) passed full native build, negative/differential suite and matched original-core full checker; accepted 16/24/32/48/192 application + admitted-library fixtures favor C0 on specific source workload families, with other paths around parity. The old frame runner stays independently executable for differential/benchmark use, not production. Memory, p95 and representative libraries remain open. Next architecture design must integrate this benefit into recursively *nested* checked source inference through the same fuel-indexed core (lambda/let/forall/projection/metadata), not bolt on new public-only shortcuts; environment/context/resource-provenance caches and full indexed delta/iota/recursor/quotient/native WHNF/DefEq need exact qualification before trusted adoption.


### Recursively nested accepting application semantics — 12 October 2026

The checked core now has a single `psKernelInferCoreWithFuelUsing` that accepts an optional, *checked-only* application callback and recurses with the same immutable hook. Its public default `psKernelInferCoreWithFuel` calls the same source body with `none` and stays the independent original/reference implementation. In the hooked mode, a checked app of 16+ arguments delegates to `psKernelC0CheckAppRecursive` with the original fuel, checker environment, local/level context, safety and state. The authoritative head-before-argument inference, `psKernelCheckerContextEnterRecDepth`, WHNF, DefEq, eager reduction and resource classifications remain. For ordinary checked applications and infer-only expressions, the original suspended fallback executes unchanged. No raw indexed IDs are compared or cached as trusted equality.

The optimized fuel-indexed checked recursive worker additionally recognizes a nested application used as an argument when it has 16+ arguments, calling its own smaller-fuel worker with the original next context. This closes the most direct missing nested-argument workload without creating a second inference language implementation. [CI 38264313583](https://github.com/dwijayuda/pskernel/actions/runs/38264313583) and [CI 38265144787](https://github.com/dwijayuda/pskernel/actions/runs/38265144787) passed pinned Lean native build, negative/fuel/differential tests and matched original checker. Real safe checked declaration admissions now cover lambda/metadata-wrapped and nested-argument spines. Source-side bounded Pi ranges are still **syntactic no-op substitution metadata**, not an environment-dependent inference or proof cache.

Outstanding: confirm semantic coverage across more complex implicit/dependent/recursor/quotient/native reductions; implement accepting session-owned canonical DAG only with complete environment/context provenance and exact original fuel semantics; benchmark representative entire libraries and per-operation memory. No full indexed accepting redesign completed.


### Safe dependent-codomain resummarization in the accepting source pipeline

The fuel-indexed native source `Checker/Inference.lean` worker can now, after an actual dependent substitution invalidates syntactic Pi-body ranges, reenter *read-only* exact metadata analysis if the newly substituted type has a sufficiently long Pi prefix. The fixed 12-binder probe avoids paying full suffix-analysis overhead on short/dependent workloads, and `psKernelC0PiBodyRangesWithFuel` bounds the analysis with clean unchanged substitution fallback on budget exhaustion. Source variants are separately executable: `psKernelC0CheckAppRecursive` is prior invalidation-only C0; `psKernelC0CheckAppRecursiveResummarized` is the qualified current accepting route. The independent original recursive core and explicit-frame route are retained. Safe source terms, original environment/local-level scopes, fuel, reduction priority, DefEq, checked argument inference, eager policy, and admission all retain their authority; metadata means only syntactic non-effect of an operation on immutable terms.

[CI 38267242015](https://github.com/dwijayuda/pskernel/actions/runs/38267242015) validated genuine dependent Pi terms and independent low-fuel/error parity; [CI 38267860486](https://github.com/dwijayuda/pskernel/actions/runs/38267860486) validated production promotion with all mandatory native gates. 80 complete checked dependent-tail64 applications: C0 30/31/32 vs original 52/52/51 ms; 48 accepted safe definitions: 23/23/23 vs original 37/37/36 ms. The exact per-operation metadata improvement is conditional, not a new inference/WHNF rule and not a complete accepted indexed expression engine. Per-check memory, full Lean library corpus and all environment-sensitive indexed reductions remain unqualified.


### Source-native DefEq binder spines: exact substitution order and range summaries

The prior binder DefEq workers repeatedly appended fresh locals to an oldest-first list and reversed it when opening each domain and terminal expression. The redesigned native source uses **newest-first immutable substitutions**, which directly represent de Bruijn index 0 at list head, eliminating repeated append/reverse traversals. It retains the same context/fuel sequencing and callback semantics. At binder depth >=12 (constant shape probe), an optional bounded **bottom-up exact** `PsKernelExpr` loose-body-range summary computes whether local opening is necessary once per binder body rather than re-scanning all nested bodies. Metadata is purely syntactic, proven by regression against `psKernelExprHasLooseAt`; on failed or insufficient analysis the original body scan remains the only authority. Semantic equality still invokes the original DefEq callback and caches only successful checked judgments; no new soundness assumptions or unsafe pointers.

[CI 38270573104](https://github.com/dwijayuda/pskernel/actions/runs/38270573104) passed all native Lean 4.34 gates, including explicitly dependent binder-domain order, negative cases, and unchanged-original full-checker comparison. Complete depth-256 definitional equality of nontrivially distinct Pi or lambda spines accelerated from ~156–158 ms original to ~5–6 ms C0 over six calls on the same runner. Short/deep library and inductive admissions remained near parity; this does not establish a whole-library or RSS improvement. Retain original Lean 4.34 reduction semantics for every environment-dependent case and do not promote incomplete indexed-DAG equality or WHNF into acceptance. The major performance redesign remains incomplete.


### DefEq recursion budget follows the recursion graph, not the syntax tree

The native checker previously set `psKernelDefEqLambdaSpineWithFuel`, `psKernelDefEqForallSpineWithFuel` and `psKernelDefEqArgsWithFuel` budgets using the total recursive `psKernelExprNodeCount` of two terms, even though the respective workers only recurse through paired leading lambda, forall, or application constructors. The refactor replaces these unrelated total-node prepasses with structural spine lengths; one extra fuel unit guarantees the terminal mismatched/non-binder case still executes. The original callback uses its own resource budgets, and no rule or reduction sequencing changes. The application congruence path also avoids redundant argument-length re-traversal after confirming its heads are definitionally equal. Unlike experimental indexed term sharing, this is accepted native source execution and is entirely semantics-preserving on the qualified input families.

[Native CI 38278625946](https://github.com/dwijayuda/pskernel/actions/runs/38278625946) passed source build, negative/old-vs-new structural bound checks, microbenchmarks, and unchanged original-core full checker. The new complete DefEq large-domain benchmark measured ~2x advantage on domain depths256/512, while the prior 256-binder performance winner persisted. Realistic library and per-operation allocation qualification are still missing. The trusted indexed DAG remains unpromoted; precise Lean 4.34 environment-dependent WHNF/DefEq, recursor/projection/quotient/native/universe treatment, session provenance, and exact fuel/negative input semantics must be implemented before changing that boundary.


### Accepted WHNF zeta chain uses operation-local exact syntax metadata

The WHNF core's zeta reduction had a worst-case repeated syntactic closedness/substitution probe for deep successive let binders. `psKernelC0LetBodyRangesWithFuel` computes precise loose-body-variable ranges bottom-up, and a fixed 12-binder probe avoids expensive analysis on short chains. For a range-zero body, instantiation provably returns the identical expression and is omitted; any actual dependency invalidates the summary and invokes the historical single-variable substitution, then later chains may be analyzed independently. The same decreasing `Nat` fuel, `psKernelCheckerContextEnterRecDepth`, checker state, term caches, reduction priorities, and public entry remain. No arena ownership, delta unfolding, recursor/iota, projection, quotient, native reduction or level semantics are redefined.

The independent zeta range oracle and complete dependent substitution negative tests passed with [native CI 38280619138](https://github.com/dwijayuda/pskernel/actions/runs/38280619138). Three matched rounds of WHNF depth96 took C0 **632/605/625 ms** vs unchanged original **709/717/728**; sequential checked admission stayed near parity. The result is a modest bounded optimization, **not** evidence of a complete indexed WHNF redesign. Each let still performs immutable WHNF core cache read/write; those operations recursively hash the remaining expression. A provenance-safe cached structural fingerprint stored alongside immutable term nodes is a plausible next architectural target, provided full structural equality is retained for collision resolution and exact old reduction/resource precedence is maintained. Never use fingerprints alone to approve types or DefEq.


### Source-owned checked let metadata shares one accepted inference core

`Inference/Core.lean` now owns `psKernelInferCoreWithFuelUsingLetFrames`: the ordinary typed let/domain/value/DefEq/local/checker-cache rules are unchanged, but when a checked hook is present and an immutable source contains at least 12 consecutive lets, it carries the exact syntactic loose-variable and source hash frames already used by accepted WHNF. Cache lookup/publication uses `psKernelExprMap{Get,Insert}WithKnownHash`, **always collision-verified against complete expressions**; no hash or range issues an acceptance result. An unchanged body with exact loose range zero bypasses a no-op substitution, but still allocates and checks the original fresh local, type/value, closure and state. A dependent/changed body invalidates the frames, preserving old semantics. `psKernelInferCoreWithFuelUsing` remains a thin internal normal entry and the hook-free `psKernelInferCoreWithFuel` remains an independent semantic oracle. [Native CI 38284834874](https://github.com/dwijayuda/pskernel/actions/runs/38284834874) passed full qualification, including exact low-fuel/errors and fresh states and separately compiled original admission. 40 checked depth64 let definitions accelerated 4.1× on matched fixture; source overall memory unchanged. Real full-library and session-owned indexed reduction still open.


### Single accepted inference worker: let fingerprints and binder-body ranges

The native Lean `Checker/Inference/Core.lean` worker `psKernelInferCoreWithFuelUsingSourceFrames` now optionally retains two *syntactic* kinds of operation-local metadata without duplicating typing rules: (1) exact source let loose-range plus collision-checked structural fingerprint and (2) exact lambda/forall binder-body loose ranges from the existing `Core/Expr.lean` implementation. At a binder with range zero, inserting the new fresh local has no syntactic effect; otherwise the original capture-avoiding substitution remains. Domain/value validation, sort typing, generation of fresh local names, context and resource budgets, DefEq, WHNF and final inferred type/state are unchanged. The qualified hook-free recursive core remains an independent source oracle. Native [CI 38285916402](https://github.com/dwijayuda/pskernel/actions/runs/38285916402) passed entire checker and original differential tests. Whole lambda admission depth64 improved only ~15–20%, whereas checked let admission has a separate ~4× source-family win. Neither a complete session-owned indexed accepting evaluator nor broader resource/memory/library evidence has been established.
