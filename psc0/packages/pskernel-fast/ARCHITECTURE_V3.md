# PSKernel-Fast V3 — Performance- and Correctness-First Kernel Architecture

> **Decision:** ARCHITECTURAL RESET, 11 October 2026.
>
> **Canonical scope:** `psc0/packages/pskernel-fast/`. This package is independent of the old `pskernel-core` checker and metatheory interfaces.
>
> **Compatibility authority:** pinned Lean **4.35.0-rc4**, commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.
>
> **Status:** architecture plus an intentionally incomplete *representation* prototype. No complete checker, qualified speed improvement, consistency theorem, or self-host milestone claimed.
>
> **GitHub source of truth:** `dwijayuda/pskernel`, `research/pskernel-fast-v3-greenfield-20261011`.

## 1. Non-negotiable product goals

Build the fastest practical **correct and Lean 4.35-compatible** small kernel that can be independently audited and eventually self-hosted. A new architecture is free to delete/rewrite every old implementation and proof interface. Old proof reuse, compatibility with previous PSKernel internals, and keeping existing self-host authoring patterns are **not design requirements**.

Priority / decision procedure:

1. **Reject a candidate immediately** if it can accept a known-invalid proof, permits untrusted code to add axioms/rules, or cannot articulate its actual positive-result correctness conditions.
2. **Reject full-compatibility claims** without explicit Lean version, input semantics, recursor reconstruction, primitive behavior, and appropriate negative evidence. Reasonably scoped MVPs must identify unsupported constructs.
3. Among **correct candidates**, prefer measured kernel-only throughput and bounded peak memory on representative workloads.
4. Among comparably fast candidates, prefer smaller semantic trusted computing base, simpler invariants, portability, auditability and longevity.
5. Reusing old source/proofs is an engineering convenience only. If it compromises (1–4), discard it.

Do not claim that a green test suite is a mathematical soundness theorem. Conversely, **formal preservation of the current proofs is NOT a release or design gate**. New formal work must target the *new* execution semantics; mathematical verification remains a high-value correctness strategy, not a constraint freezing the algorithm.

### What is explicitly abandoned

- Requirement that `Checker/Knot.lean` or the existing callback/fuel structure remain.
- Requirement to keep `PsKernelExpr` recursive trees, old `ExprMap`, old namespaces, caches, or source module boundaries.
- Requirement to preserve old generated `.ps`, PSC1 portable syntax, old source/ABI and old checker proof theorem statements.
- Requirement to keep every old metatheory theorem compiling, or to translate proofs before choosing a faster implementation.
- Requirement to use Lean-only optimizers if a smaller, faster runtime is justified; **however**, no second unreviewed trusted checker may silently decide admission. Backend/runtime variants need an explicit trust/refinement/validation story.
- Requirement to preserve an old failed or incomplete checker simply because it accumulated substantial proof files.

**Preserve repository history and old branches**, not architectural compatibility. Existing proof work can remain as an archive and an informative independent reference; it never has veto power.

## 2. Real source and benchmark evidence

### Official Lean 4.35

The official kernel uses several separate C++/runtime modules: [expressions](https://github.com/leanprover/lean4/blob/v4.35.0-rc4/src/kernel/expr.cpp), [type checking/conversion](https://github.com/leanprover/lean4/blob/v4.35.0-rc4/src/kernel/type_checker.cpp), [levels](https://github.com/leanprover/lean4/blob/v4.35.0-rc4/src/kernel/level.cpp), [inductives](https://github.com/leanprover/lean4/blob/v4.35.0-rc4/src/kernel/inductive.cpp), [quotients](https://github.com/leanprover/lean4/blob/v4.35.0-rc4/src/kernel/quot.cpp) and admission. The official DefEq algorithm is not unrestricted normalization: it deliberately schedules syntactic comparisons, cheap WHNF, proof irrelevance, lazy δ, projections, eta, recursor reductions, numerals and strings. It also distinguishes **fully checked** from inference-only caching.

[Lean 4.35-rc4 release notes](https://lean-lang.org/doc/reference/latest/releases/v4.35.0/) remove compiler-backed `Lean.reduceBool` / `Lean.reduceNat` kernel privileges. **Normal built-in Nat kernel computation remains** in `type_checker.cpp`; these are different concepts. Formal compatibility must pin version and refuse incompatible historical exports.

### Fast checkers: what is independently useful

| Implementation | Key lesson | Evidence qualification |
| --- | --- | --- |
| [sokonanoda](https://github.com/intgrah/sokonanoda) | Closure/value evaluation, efficient conversion scheduling | Arena fast, but no standalone full soundness proof |
| [MathGraph](https://github.com/metalogiclabs/mathgraph-lean-kernel) | Shared values/closures, well-targeted evaluation caches, selective unfold | Derived from sokonanoda, not a separate clean-room design |
| [nanoclo](https://github.com/sgraf812/nanoclo) | Lazy environments, interned closures and exact read-set projections | Context-pruning proof and mask-overflow policy essential |
| [nanobruijn](https://github.com/nomeata/nanobruijn) | Constant-time lazy binder shifts and sharing modulo depth | Full representation change, not soundness proof for entire checker |
| [lazylean](https://github.com/corun1024/lazylean) | Call-by-need, live-memory-bounded sessions, large computation handling | Upstream 0.5.1 claims **not** directly comparable to Arena's earlier 0.3.0 |
| [con-ron](https://github.com/leanprover/con-ron) | Packed tags, per-constructor arrays, scratch/permanent tiers; Rust refinement methodology | Driver/export assumptions and Aeneas trust still matter |
| [con-leche](https://github.com/leanprover/con-leche) | Actual checker/model consistency under explicit axioms and assumptions | Verified mode intentionally declines ordinary Lean axioms |
| [Official Lean](https://github.com/leanprover/lean4) | Exact implementation behavior and differential target | Official != unconditional perfect soundness; runtime has TCB |
| [lean4lean](https://github.com/digama0/lean4lean) | Faithful independent execution/proof ideas | Shares official implementation lineage |

As observed in the October 2026 [Lean Kernel Arena](https://arena.lean-lang.org/), fast independent checkers outperform the official 4.34.1 kernel on Mathlib export instruction-cost metrics. This is **not a measured prediction** for PSKernel-Fast. The Arena normalizes instructions to a virtual CPU time and includes loader differences. Memory, small/large inputs, supported cases, experimental checker versions and proof assurance are separate axes.

### Why a greenfield path is warranted

The current `psc0/packages/pskernel-core` (observed 11 October 2026) contains approximately 92 Lean source files / 935 KB and 182 metatheory files / 3.18 MB, excluding host/protocol and imported dependencies. It is **not** an acceptable measure of semantic trusted-base LOC, and cannot predict V3 implementation cost. Its raw recursive syntax, callback/fuel knot, checked/infer-only caches and proof-only annotated syntax have different natural representations from the proposed compact closure machine. Retaining them to preserve existing proofs could lock in avoidable work and prevent an optimal architecture. We will not do that.

## 3. Architecture alternatives: test before choosing the winner

Three *real implementations* should be compared on the **same Lean 4.35 inputs and host**, not by theoretical preferences:

| Candidate | Storage | Evaluator / conversion | Strength | Risk |
| --- | --- | --- | --- | --- |
| **A: compact DAG + closure NbE** (preferred research hypothesis) | Hash-consed immutable handles + scratch generation | WHNF closure/neutral spines; lazy δ, typed Eq | High sharing and low beta-copy cost | More complex well-scoped value semantics |
| **B: compact DAG + official-style substitution** | Same DAG | Exact official WHNF & DefEq scheduling | More direct official compatibility | Repeated instantiation may remain expensive |
| **C: compact DAG + call-by-need** | DAG + shareable environments/thunks | Lazy abstract machine; especially large `decide` reductions | Potentially smallest live heap on heavy computation | Thunk updates, lifecycle and proof complexity |

**Selection is conditional.** A is the starting architectural hypothesis based on upstream observations, not a foregone conclusion. Implement matching vertical semantic slices, run a matched corpus, reject any that produces incorrect acceptance, then compare kernel-only instructions and memory. If B is simpler and faster on the relevant workloads, choose B. C may win on large reflective proofs but lose startup/small-proof cost; a hybrid is allowed **only if both paths share a justified accepting semantics**.

Do not count duplicate maintained production checkers as the smallness goal. Exploration can temporarily keep prototypes A/B/C in the research branch, but release one canonical acceptance implementation (potentially with two *verified equivalent* evaluation strategies).

## 4. Proposed single production trusted core

~~~text
UNTRUSTED EXPORT / ProofScript SOURCE OUTPUT
                  |
        Reader + protocol validation
        (not logical proof authority)
                  |
          RawDecl / RawExpr
                  |
   Canonicalize, check names and scope
                  |
      Immutable term DAG / TermId
                  |
         Kernel Verify Driver
      +-------------------------+
      | fully checked inference |
      | typed DefEq / WHNF      |
      | reduction + levels      |
      | recursor/quotient rules |
      +-------------------------+
                  |
         Checked declaration
                  |
        ATOMIC environment commit
                  |
           Verified session
~~~

### Small trusted logic, fast internal representation

The trusted logical rules are expression typing, universe constraints, definitional equality, proof irrelevance, primitive reduction, inductive/recursor and quotient checking, and safe declaration admission. Everything else (export parsing, CLI, caches, NPM installation, tactics, compiler front end, benchmarking, diagnostics) is separate from the logical rules **unless its behavior can affect an accepting verdict**. A corrupt cache or handle can affect acceptance, so representation validity/caches and any unchecked runtime/FFI still matter to the TCB.

Use:

- **Immutable hash-consed names, universe levels and expression nodes.** Hash map collisions must compare complete structural keys; equal hashes are not equality proofs.
- **Opaque validated IDs** with checked generation/tag/bounds; never expose a raw integer/pointer as a trusted proof certificate.
- **Persistent admitted nodes and per-check scratch nodes** with no cross-epoch alias or post-commit dangling references.
- **Closure and neutral-spine evaluation** for beta/let; do not normalize arguments until conversion demands them.
- **Proof irrelevance only after sound typing/relevance checks**; metadata or raw identifier names cannot grant it.
- **Explicit deterministic resource policy**: all exhaustion/unsupported/internal paths fail closed.
- **Strongly distinct checked and infer-only result grades**; no unchecked result can be used to publish a declaration.
- **Atomically checked declaration batches**; recompute/validate recursor metadata, positivity, elimination and generated aux declarations.

### Error and outcome contract

Public outcomes should discriminate `accepted`, `rejectedInvalid`, `declinedUnsupported`, `resourceExhausted` and `internalError`. These are not interchangeable. A status of `accepted` must arise only after a fully successful declaration check; no extension-provided “cached certificate” or alternate provider fallback may override another kernel's failure.

### Formal specification is free to be new

Develop a fresh mathematical typed judgment system and a model consistent with the **new machine**. Choose an executable representation amenable to proof, but do not preserve existing proof APIs or import old failed typing/equality judgments. In particular, the old project's overly permissive algorithmic equality specification must not reappear as an assumed “sound” relation. A complete end-to-end theorem requires:

~~~text
decoded raw declaration well formed
  -> actual check succeeds
  -> all checked positive DefEq / reductions are sound
  -> well-formed modeled environment extends for each fresh declaration
  -> explicit permitted axioms are modeled
  -> no *derived* False in the selected consistency profile
~~~

Ordinary Lean allows users to assume an axiom `False`; a universal “kernel never accepts a theorem of False” claim is therefore **false without an axiom restriction**. Versioned normal Lean compatibility and an axiom-constrained verified-consistency profile are distinct products. No code rewrite can bypass this logical fact.

**Security:** native in-process extensions are not sandboxed by a Lean datatype alone. Untrusted packages must not share mutable kernel memory/FFI unchecked. Supply proposals via a sealed process/Wasm boundary or enforce results with the trusted checker. An alternate backend performing unverified trusted reductions expands the TCB, regardless of the file name.

## 5. Compatibility roadmap (not proof-artifact preservation)

- Phase 0: canonical raw grammar, full universe levels `zero/succ/max/imax/param`, de Bruijn, names and literal representation. This is currently not implemented in the experimental seed.
- Phase 1: infer/check for `Sort`, constants, Pi/lambda/app/let, structural variable scopes and universe instantiations; checked versus infer-only must be enforced.
- Phase 2: β/ζ/δ, weak-head normalization, DefEq, proof irrelevance, typed eta and literal computation. Verify the exact official 4.35 acceptance policy, including reducibility hints.
- Phase 3: positivity, ordinary/mutual/nested inductives, generated recursors and quotients, all kernel-checked.
- Phase 4: safe definition/theorem/opaque admission, environment/axiom policy and full supported export replay.
- Phase 5: formally verify actual accepting paths under explicit model assumptions; native and other backends qualify separately.
- Phase 6: mature loader/resource/runtime, fully pinned large-corpus benchmarks and future self-host certification.

**No claim of Lean compatibility beyond the exact features implemented, tested and (for verified claims) proved.** An incomplete checker must decline unsupported inputs, never guess success.

## 6. Smallest greenfield MVP, and what it proves

Initial independent package lives at `psc0/packages/pskernel-fast/` and uses pinned Lean 4.35.0-rc4. It shall:

1. Define a purposely limited raw term grammar to exercise scope, sharing and conversion-oriented structures; no declaration acceptance yet.
2. Implement a canonical node interner (hash-consed DAG) and exact node lookup with collision-aware equality.
3. Reject invalid child IDs and unbound de Bruijn variables instead of constructing a “checked” term.
4. Decode the DAG back into raw syntax with *bounded total recursion*, preventing invalid references or forged cycles from hanging the runtime.
5. Check repeated interning reuses identical handles and round-trip encoding/decoding retains the exact raw expression.
6. Run a native cloud CI job with the **exact pinned toolchain**. Failure/pending are reported honestly.

**Status of a successful MVP:** verified by focused tests *only* as a representation experiment. It has no Lean proof typing, no DefEq theorem, no theorem/inductive admission, no Mathlib performance claim, and no self-host fixed point. The next MVP should add a small scope-preserving closure evaluator and compare it to ordinary substitution on a bounded corpus.

## 7. Performance methodology and acceptance budget

Everything performance-related is a *target until measured*. Capture source SHA, compiler, export version/hash, OS/CPU, read/parse time, kernel-only time, median/min/max over ≥3 runs, peak RSS, allocations and GC. Report every `accepted`/`rejected`/`declined`/resource/internal status. All comparisons must use identical Lean semantics and identical data, not Arena 4.34 scores versus V3 4.35.

Suggested staged **decision thresholds**, not guarantees:

| Gate | Aspirational benefit | Safety criterion |
| --- | --- | --- |
| Representation pilot | No massive time/RSS regression, collision safety | All focused invalid handles and scopes rejected |
| Typed inference & closures | ≥2x on measured β/let-heavy work | Exact raw/closure semantic correspondence |
| Full conversion | Significant kernel-only improvement on real imports | Zero false accepts, no premature false rejects within scope |
| Large library | ≥1.5x relative to a **matching** V3 baseline if justified | Complete supported fresh Lean 4.35 export results |
| Memory | ≥30% reduction on allocation-heavy workload if ID storage warranted | No stale pointers, immutable admitted environment |

Avoid assuming a specific 15x or 25x gain will transfer from a different checker/programming language to this one.

**Benchmark candidates:** arithmetic with large numerals; repeated binder/scope shifts; beta/let ladders; expensive eta/proof irrelevance; same-head vs delayed delta; recursor/projection/quotient cases; malformed axioms/recursors; resource exhaustion; the current Arena tutorials and negative suite; bounded Init/Std prefixes, then full Init/Std/Mathlib at release qualification.

## 8. Source size, implementation cost and self-host tradeoff

Keep separate metrics for semantic trusted LOC, representation/runtime LOC, host/protocol LOC, formal proof LOC, number of trusted foreign operations, compiled binary size, peak memory and per-declaration speed. No exact code size or completion date can be estimated honestly before a prototype.

V3 is **allowed to be initially larger than V1** if it achieves meaningful correctness/performance gains. Smallness remains an objective but must not veto the best sound algorithm. If performance demands Rust/C++/native specialized representation, prototype and benchmark it, and record its increased TCB explicitly rather than pretending a single-source “portable” identity already exists. Self-host is a long-term goal to be re-earned by the resulting design, **not** an obligation to constrain this architectural reset to the current PSC0 bounded authoring language.

Old metatheory can be archived without importing a single theorem. Formal work after implementation should aim at the new stable semantic interfaces; machine invariants and soundness-critical proof conditions should be identified *during* algorithm development to avoid avoidable unsoundness.

## 9. Work sequencing and anti-drift rules

| Milestone | Deliverable | Hard acceptance |
| --- | --- | --- |
| **G0** | New design + independent package + canonical representation test | Pinned native build + no malformed-input acceptance |
| G1 | Universe/name/term semantics with checked scopes and compact storage | Precise parity against independent raw representation |
| G2 | Substitution/reference evaluator and closure-based WHNF | Correct beta/let/reduction cases, measured cost |
| G3 | Checked core typing, typed conversion and explicitly scoped axioms | No unsound acceptance, pinned Lean core differential suite |
| G4 | Full Lean inductive/quotient/primitive compatibility | Complete advertised conformance, atomic admission |
| G5 | Soundness/model and optimized runtime assurance | Stated theorems with explicit assumptions and TCB |
| G6 | Native/JS/Wasm and distributable kernel | Verified artifacts, independent cold and self-host gates |

Do not do “test-fix-patch” without tracing the shared semantic cause. Work algorithm by algorithm. Keep source/CI evidence in `AI_WORK_STATE.md` with branch HEAD and precise known limits. Do not rewrite the active proof branch `psc0/pskernel-core-lean435-arena-v1` or merge draft PR #89. Old files/history are left intact **only for recovery/evidence**, not to restrict the design.

## 10. Summary decision

**Adopt an independent, performance-and-correctness-first PSKernel-Fast V3.** Discard old proof-preservation constraints, explore a clean compact DAG/closure architecture, select engines from measured parity and speed, and formally verify the chosen executable kernel on its own merits. The only architectural restrictions are the real requirements of correctness, exact Lean 4.35 compatibility, auditable trust, reliability and eventually qualified deployment.
