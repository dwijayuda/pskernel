# PSKernel-Fast V3 — Performance- and Soundness-First Architecture

**Status:** authoritative *design target* for the V3 research branch; implementation and performance claims require separate evidence.  
**Date:** 2026-10-11. **Repository:** [dwijayuda/pskernel](https://github.com/dwijayuda/pskernel).  
**Design branch:** `research/pskernel-fast-clean-v3-20261011`.  
**Lean semantics target:** **Lean 4.35.0-rc4**, official commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.  
**Previous V2 research:** `research/pskernel-fast-major-v2-20261011`.  
**Existing proof branch:** `psc0/pskernel-core-lean435-arena-v1` — reference/history only; NOT a constraint, requirement, source dependency or release gate for V3.

## G2 research decision — 11 October 2026

The first [three-engine experimental evidence](G2_EVALUATION_EVIDENCE.md) found that eager tree substitution, lazy tree closures and lazy DAG-handle closures agreed on the bounded beta-only test domain, while repeated median times were 121 ms, 7 ms and 7 ms respectively on a small identity-chain corpus. **This is not a Lean kernel benchmark.** It establishes no measured speed benefit for *direct DAG traversal* over ordinary closure/tree evaluation on that workload. Therefore **a compact DAG is an optional storage candidate, not a mandatory end-state**; correctness, memory and real Lean-checking throughput choose the representation. Lazy closures remain a favored hypothesis but require a separate semantic refinement proof before they can authorize any positive kernel result.

## 0. Binding decisions — clean architectural freedom

1. **Performance, semantic correctness, Lean compatibility, fail-closed behavior, and clear trust boundaries come before preservation of any V1/V2 internal API, implementation, proof, file hierarchy, or existing self-host subset.**
2. Design **PSKernel-Fast as a new kernel implementation**, not an optimization shim atop `Checker/Knot.lean`. The previous instruction to preserve that function's implementation and old proof statements is **withdrawn**. Code and historical proof material may be consulted or reused **only when independently advantageous**.
3. Maintain **one production semantic authority** once V3 is qualified. During development, older PSKernel, official Lean, and independent checkers may serve as test oracles; no agreement vote is a proof of soundness.
4. **Correctness is NOT downgraded by discarding proofs.** Define actual semantics and invariants up front, test every accepting rule against official Lean, and build new *implementation-specific* refinement/model proofs for V3. Prefer replacing an unprovable design, not adding axioms to force proof completion.
5. No historic requirement to preserve the old kernel's fuel/callback structure, cache policy, PSC1-era source subset, native provider wiring, or previous binary/JS behavior. Public compatibility target is **Lean 4.35 semantics**, **not PSKernel V1 behavior**.
6. Start native in Lean 4.35 with **independent benchmarking**. Portable JS/Wasm/self-host comes after an algorithm earns correctness and competitive performance. If an implementation-specific native optimization cannot be self-hosted yet, keep a documented portable semantic interface and backends as a separate qualification.
7. Keep existing GitHub branches, work-in-progress and PR #89 untouched. Preserve history for recovery; **do not maintain or update their proofs solely to appease compatibility with V3**.
8. **No “test-fix patch hunting.”** Revisit the algorithm and invariants when a family of tests fails. Never whitelist proof names, downgrade CI, fake theorem soundness, or add unchecked fast-result acceptance.
9. **Design for a small actual trusted computing base**, not minimum file count. Avoid a generic extensibility framework inside proof checking; host extensions can only propose input or nonauthoritative hints.
10. Results are not valid until measured: the fastest Arena checker on one export is not necessarily the fastest kernel-only checker, best worst-case checker, or most suitable for ProofScript.

These decisions **supersede** conflicting proof-preservation language in `PSKERNEL_FAST_MAJOR_ARCHITECTURE_V2.md` and `PSKERNEL_FAST_ARCHITECTURE.md` on this branch. Those are historical research.

## 1. What is meant by “correct”

**Semantic fidelity:** For each supported well-formed Lean 4.35.0-rc4 declaration/environment, V3's kernel checking follows the normative formation, inference, definitional equality and admission rules, including correct universes, proof irrelevance, inductive positivity/eliminators/recursors, quotient theory, literal computation, opacity, declaration trust and unsafe/partial distinctions.

**Positive-result soundness:** If V3 returns `Accepted` on a new theorem or definition, its *actual* proof term/type obeys the specified kernel judgments under the accepted environment and axiom policy. Untrusted engines, checked-result records, compiler plugins and caches cannot assert a theorem.

**Relative consistency:** Under an explicit modeled set-theory foundation and explicit interpretations of allowed axioms, new accepted declarations preserve model validity and cannot derive `False`. **Arbitrary Lean axiom admission cannot imply unconditional consistency**: `axiom bad : False` is accepted as an assumption under ordinary Lean-style admission. An assurance mode can restrict modeled axioms and thereby intentionally decline Lean-valid inputs; report separate compatibility scopes.

**Robustness:** Invalid terms are rejected, unsupported features declined, resource failures reported; no OOM, timeout, overflow, forged handle or unsupported version can be interpreted as successful proof acceptance.

**Algorithmic parity:** A sound but incomplete conversion procedure may reject some Lean-valid cases or time out; track this as a compatibility defect. Correctness, compatibility, and termination/resource behavior are separate measures.

**Parser/protocol trust:** Even a correct core can be subverted by a decoder that silently changes expression identity or binder scopes. Parsing is outside the logical kernel but the input-to-checked-term boundary, importer/external artifact protocol and hash binding must be audited and tested.

## 2. Reference algorithms and design options

**External, current research** (see [original source analysis](https://github.com/dwijayuda/pskernel/blob/research/pskernel-fast-architecture-20261011/psc0/packages/pskernel-core/PSKERNEL_FAST_ARCHITECTURE.md) on the earlier research branch; V3 treats all numbers as date-scoped):

| Candidate / source | Valuable idea | Limit/independence |
|---|---|---|
| [Official Lean 4.35 C++ kernel](https://github.com/leanprover/lean4/tree/v4.35.0-rc4/src/kernel) | Exact inference, WHNF, ordered DefEq, recursors, quotient, Nat/String primitive semantics | Semantic oracle, not the V3 implementation or performance target |
| [sokonanoda](https://github.com/intgrah/sokonanoda) | Fast closure/value based conversion; selective delta; shared spines | Top Arena throughput, some declined malformed cases; no full-model soundness proof |
| [MathGraph](https://github.com/metalogiclabs/mathgraph-lean-kernel) | Fast value evaluation, memoized environments, specialized conversion | Derived from sokonanoda, not independent clean-room semantics |
| [nanoclo](https://github.com/sgraf812/nanoclo) | Interned lazy environments; read-set-pruned caching | Precise scope and overflow invariants required |
| [nanobruijn](https://github.com/nomeata/nanobruijn) | Shift-homomorphic caching and lazy de Bruijn offsets/OSNF | More complex encoding/reification and bounds proofs |
| [lazylean](https://github.com/corun1024/lazylean) | Call-by-need thunks, Krivine machine, memory-bounded long-running computation | Arena's scored 0.3.0 differs from newer 0.5.1 author-reported performance |
| [con-ron](https://github.com/leanprover/con-ron) | Compact constructor-typed stores, tagged IDs, per-declaration scratch, refinement through Aeneas | Driver is outside theorem; Rust not inherently required |
| [con-leche](https://github.com/leanprover/con-leche) | Explicit logical model/relative consistency proof | Valid assumptions/axiom-policy restrictions; not a proof of V3 |
| [lean4lean](https://github.com/digama0/lean4lean) | Readable Lean-based rule comparison and metatheory | Similar algorithmic lineage to official |
| [Lean Kernel Arena](https://arena.lean-lang.org/) | Same-export ranking and negative compatibility tests | Virtual CPU whole-checker workload; benchmark official version may differ from 4.35 |

**No presumed winner:** Benchmark **three competing executors** over *one fixed logical/decoder contract*, on equal hardware and identical export:
- **A — eager DAG/substitution**: compact hash-consed syntax + direct WHNF; simplest correctness baseline.
- **B — closure-based WHNF/NbE**: shared DAG, immutable closure environments and selective conversion; **favored hypothesis** for performance/robustness.
- **C — call-by-need evaluator**: B plus memoizing thunks/bounded scratch for heavy closed computation; more complexity, optional after measured evidence.

Do not invent a requirement that A remain the production evaluator or that B be strictly compatible with its internal data types. The only shared requirement is public Lean semantics and an exact representation/decoder specification. C may be introduced only if its improvement justifies extra trusted and proof surface.

## 3. Proposed clean-generation core architecture

~~~text
   pinned Lean 4.35 declaration/export
                  |
       untrusted Input / Host Adapter
          strict decoding + limits
                  |
  [Validated raw syntax + version policy]
                  |
       Core/TermStore + Context
    immutable compact DAG / IDs / scopes
                  |
        Checked Kernel Machine
       Infer / Check / WHNF / DefEq
            /             \
    lazy closures      typed conversion
    neutral spines     proof irrelevance
    lazy delta         eta, projections,
    bounded work       recursors, literals
            \             /
       typed success / typed error
                  |
        Admission transaction
    definitions, theorems, opaque,
    axioms, quotient, inductives
    atomic recursor rule generation
                  |
     Immutable Checked Environment
                  |
   single kernel verdict and receipts

Proof-only: precise judgments, model, checker/optimized
           representation refinement, assumptions audit
Host-only: format import/export, benchmarks, independent
           cross-checkers, profiling and CI
~~~

### 3.1 Minimal ownership

| Module family | Only responsibility | Forbidden |
|---|---|---|
| `Core/NameLevel` | Names, universe level normalization/comparison | External axiom interpretation |
| `Core/TermStore` | Bounded immutable canonical nodes and IDs, verified exact interning | “equal hash ⇒ equal proof” |
| `Core/Context` | Typed local variables, stable scope identities, universe substitution | Forged free variables crossing scope |
| `Kernel/Check` | Syntax-directed full checking, separate infer-only capability | Unchecked final theorem acceptance |
| `Kernel/Eval` | WHNF of closures; reductions with versioned semantics | Unspecified foreign proof evaluator |
| `Kernel/Convert` | Legal DefEq judgment, staged equal/unequal/unknown with exact type context | Unsound transitive union-find of heuristic DefEq |
| `Kernel/Primitive` | Exact versioned Nat/String literal computation and limits | 4.34-only `reduceBool`/`reduceNat` machine hooks in 4.35 |
| `Kernel/Inductive` | Check positivity/uniform params/elimination and derive recursors | Trust exported recursor body |
| `Kernel/Admission` | Atomic checked environment extension | Partial-commit after failure |
| `Kernel/API` | Opaque sessions, typed verdicts, axiom policy and failure categories | “trusted” acceptance from npm/host plugins |
| `Proof/*` | Correctness model and refinement, never imported by runtime | Making theorem proofs a runtime dependency |
| `Host/*` | Export protocol, CLI, npm/Wasm/native adapters and isolation | Altering semantic rule via configuration |

**One source of *logical* authority** does not mean forcing one physical memory layout onto every backend. Backends may specialize storage and GC as long as the representation/inference/DefEq refinement obligations and native-vs-generated checking outcomes are established. These differences must not be silently trusted.

### 3.2 Internal expression representation

Use a compact immutable DAG with small indices/handles, explicit node tags and versioned arena epochs. Favor con-ron-style per-constructor arrays if measurement confirms memory gain; a single tagged array remains a legitimate simpler baseline. Represent sort/universe levels, names and lists by canonical handles to avoid repeated traversal.

- **Raw syntax is not trusted** until decoded, scoped and validated.
- **Exact structural identity** uses collision-checked interning (no “hash equals expression”).
- **Binder identity** uses controlled levels/de Bruijn indices with scoped local-context keys; no name-forging shortcut.
- **Scratch and persistent storage** have nonaliasing handle generations; failed admission never exposes provisional nodes or metadata.
- **Memory overflow, index overflow or invalid handles** must return typed failure; never wrap into another valid node.
- **Proof erasure/decoding** is precise: decoding every live handle yields exactly one well-formed semantic term; native pointer equality can only accelerate this established fact.
- **All semantic annotations used by an accepting rule** come from actual, validated checker observations. They are not post-hoc guessed or sourced from untrusted metadata.

A full de Bruijn + lazy shift representation is optional. Choose it only if correct interning, binder semantics and profiling justify it better than closure environments. Do not simultaneously introduce independent environment pruning and OSNF until each is grounded.

### 3.3 Inference and checked result design

Do not rely on a raw `Expr` + Boolean “trust me, checked” flag:

~~~text
Mode = InferOnly | FullyChecked

CheckedVisit (internal, unforgeable by untrusted clients)
  termId
  inferredTypeId
  mode
  exact scope/context/level-parameter/environment identity
  witnessed binder-sort readings and relevance evidence
  semantic/primitive policy
  completed result status

Result = Accepted(CheckedVisit) | RejectedInvalid
       | DeclinedUnsupported | ResourceExhausted
       | InternalError
~~~

A `FullyChecked` result is minted only by checking all corresponding premises; infer-only may operate on preliminarily trusted definitions but cannot be reused as a fully checked theorem. Validated annotations attach to **actual** lambda/Pi/let and DefEq visits. Avoid making V1's annotation classes/API permanent just to reuse old theorems.

The desired correctness result is a theorem about **the executable checker's produced witnesses and environment**, not a semantically weaker post hoc mathematical relation.

### 3.4 Conversion and lazy evaluation

Represent evaluable expressions as closures `(termId, environmentId, universeSubstId, binderScope)` and semantic values with neutral spines. Beta/let reductions extend closure environments rather than constructing large substituted trees. Unfold definitions only as demanded by ordered compatible DefEq heuristics. Compare identical structural nodes and properly typed irrelevant proofs early.

Important requirements:
- preserve Lean 4.35 universe equivalence (`imax`/`max`), proof irrelevance and decidable Prop behavior;
- preserve recursive inductive computation, quotient rules, string/Nat literal reductions and limits, projection/K/eta rules;
- the compiler-backed reducers removed in 4.35 are NOT equivalent to deleting ordinary kernel Nat computations;
- a cheap negative comparison must not short-circuit remaining legitimate equality reductions;
- any affirmative cache result must refine sound DefEq in its exact context; a hash and a transitive heuristic equality class do not certify convertibility;
- do not allow host-level shortcuts or extensions to add axioms, trusted primitive reductions, or bypass admission;
- deterministic bounded evaluation first. Parallel/interruptible scheduling is a later optimization only if it improves correctness and resource accounting.

Performance-friendly checked semantics are compatible with formal methods; the mathematical specification must describe **accepted results**, not cement a particular data structure or evaluation order.

### 3.5 Environment, admission, and the theorem of safety

Acceptance is transactional. A declaration is either checked **completely**, including generated recursors/quotient rules/universe parameters, and committed to an immutable environment generation, or not committed.

A soundness proof must justify a **constructive model extension for each newly admitted name**. Do not assume an arbitrary fixed interpretation of new constants magically matches the checked term. Distinguish ordinary Lean-compatible, arbitrary-axiom mode from **modeled axioms only** consistency-assurance mode. State assumptions and Lean implementation/runtime/decoder trust boundaries explicitly.

## 4. Formal-methods design without V1 proof lock-in

Use an **independent small logical specification**, e.g. `Lean435Spec`, for well-scoped syntax, typing, universe levels, conversion, declaration/inductive formation and model interpretation. It must be reviewed against official Lean, not against V1's unsound legacy judgments.

Proof work can be entirely new and organized around these intended theorem interfaces:

1. `decode_sound` — untrusted bytes decoded into exactly the claimed scoped Core term, with explicit parser assumptions.
2. `term_store_sound` — every live interned ID denotes a unique exact term; no aliases/collisions/invalid generations.
3. `whnf_positive_sound` — evaluator's accepted reduction step preserves the corresponding definitional equality/type under exact scope/level policy.
4. `convert_positive_sound` — each affirmative conversion result implies compatible definitional equality under checked premises.
5. `infer_fully_checked_sound` — actual full-checker success implies the type and annotation observations are valid in the current modeled context.
6. `inductive_admission_sound` — positivity/elimination/constructor/recursor rules extend a well-formed environment soundly.
7. `declaration_model_extension` — a fresh accepted declaration yields a model extension preserving old interpretations and reserved `False` behavior (under explicitly modeled axioms).
8. `public_acceptance_sound` and conditional `no_derived_False` — honest end-to-end boundary from checked session to modeled environment.
9. `optimized_representation_refines_spec` — optional native storage/evaluator alternatives preserve the above semantics.

**None is currently claimed proved.** An old theorem can be reused only if it has the exact required statement and proof dependencies; no requirement to retain an old theorem name, source module, checker algorithm or proof inventory. Never add `sorry` or new soundness axioms to manufacture completion. Proof complexity is an **engineering quality signal**: redesign V3 when a needed invariant is impossible or disproportionately difficult.

Correctness gates apply to implementation even before full metatheory exists: no unsound shortcut, official Lean differential matching, fail-closed errors, independent corpus, and a clear open-theorem inventory. No green CI may be described as a global consistency proof.

## 5. Benchmark criteria — fair, broader than the Arena score

Pin toolchain, exported corpus, parser, semantic/axiom policy, runner and result classification. Report **kernel-only work separately from host parsing/import** and **instructions, wall-clock, peak RSS, allocations, scratch high water**. At least three controlled samples for a matched comparison.

Corpus families:
- current Arena valid/invalid and exact official 4.35 fresh exports;
- beta/let substitution ladders, deep scoped binders/universe substitutions;
- same-head application comparison, proof irrelevance, difficult lazy delta;
- large shared expression graphs and hash/collision/scratch reuse;
- ordinary, nested and mutual inductives and recursors; quotient;
- primitive Nat and String big computations, Int64 and resource exhaustion;
- reflective `decide`-heavy proofs; worst-case live-memory stability;
- broad fresh Init/Std/Mathlib later, when small conformance and resource gates are stable.

**Initial engineering *targets*, not forecasts:**
- Zero known false proof acceptance on the supported negative corpus and exact version-match conformance; complete resource and error classification.
- B vs A: target ≥2× kernel-only speed on β/let-dominated workloads; target ≥1.5× on representative library replay once full replay is implemented.
- Aim to reduce peak scratch/retained memory by ≥30% for at least one allocation-heavy workload.
- Aim for a small execution TCB (~8–20K handwritten semantic LOC as a *design envelope only*, not a measured estimate or release condition). A larger codebase is acceptable if clear correctness/compatibility require it; keep audits and component bounds.
- Eventual competitive Mathlib score is aspirational. **Do not extrapolate sokonanoda's 23× or MathGraph's ~15× Arena speedup into an unmeasured Lean-native V3 claim.**
- Verify self-host/JS/Wasm only when executable parity is actually demonstrated, rather than imposing today's PSC0 bounded source constraints on the fast architecture.

**Critical fork:** If compact DAG or closures do not beat a simpler eager evaluator enough to justify their extra soundness/maintenance surface, choose the simpler architecture. The requirement is *performance AND correctness*, not “NbE at all costs.”

## 6. Implementation stages with greenfield freedom

| Stage | New-generation implementation | Exit gate |
|---|---|---|
| G0 — contracts and baseline | Freeze exact semantics/axiom policy, define result/errors, input schema, baseline workload and versioned manifest | Reviewed spec, no code acceptance claims |
| G1 — small independent core | Scoped RawExpr + optional DAG IDs, interning/decoding, checked bounds and generation, resource types | Roundtrip, malformed input, collision and scope tests; source correctness inventory |
| G2 — competing reduction strategies | A eager raw/DAG evaluator, B closure WHNF; optionally C call-by-need only after evidence | Same tested WHNF/DefEq semantics against official, measured kernel-only CPU/RSS |
| G3 — checked inference and conversion | Typed checked/infer-only results; universes, proof irrelevance, eta, reduction | Supported complete rule-family positive and negative corpus, checked annotation invariants |
| G4 — full admission | Ordinary declarations, definitions, theorems, opacity, quotient, inductives/recursors, transactions | Independent Lean 4.35 conformance + no untrusted unchecked acceptance |
| G5 — soundness proof | Spec/model/refinement, fresh declarations, conditional consistency; optimized backend bridges | Exact theorem and assumptions manifest with no unsupported claim |
| G6 — scale & distribution | Broad fresh Init/Std/Mathlib; native performance; later generated JS/Wasm/self-host | Full corpus outcome/throughput/RSS + independently qualified backend artifacts |

**No V1 compatibility step.** Old source/proofs serve as optional reference material; they can be discarded from the eventual V3 package. Keep Git history and old branches, but do not route new checker callbacks through the old `Checker/Knot`.

**No big-bang false acceptance.** Build source units by semantic family; add negative tests for malformed binder/level rules before enabling each acceptance path. If unexpected mismatches occur, change the underlying algorithm or precise spec, not just the failing test.

## 7. Trusted boundaries and extensibility

The kernel may be bundled in an npm package, native binary or Wasm module. **No extension can change accepted typing/DefEq/inductive rules** merely by installing an npm package. Extensions can synthesize candidate proof terms, add front-end syntax, backend commands, tactics, editor services, or optimization hints. The kernel validates the final terms.

For untrusted plugins, host-level sandbox/process or Wasm isolation is necessary; opaque records in the same mutable JavaScript process do not constitute isolation. A proven optimization may be part of the kernel TCB if it supplies positive equality facts; an unverified external cache should only supply suggestions subsequently rechecked by the kernel.

No workflow creates one `proofscript` meta-install bundling every package. PSKernel-Fast's package dependency closure stays focused on its own checker and runtime.

## 8. Immediate repository changes and status truth

This **research branch** is an independent start for `pskernel-fast/` with separate architecture, plan, optional executable MVP and focused cloud CI. It does **not** rewrite the ongoing PSKernel core/proof branch, or merge PR #89. The older V2 design should be marked *superseded on this research branch only*, so future agents do not accidentally enforce old proof preservation.

All further code changes must update `pskernel-fast/AI_WORK_STATE.md` and record:
- exact source SHA and completed CI log;
- what was built and tested, which tests skipped;
- algorithm/representation decisions and measured data;
- trusted modules, formal proof status and assumptions;
- remaining semantic classes and the next architectural milestone.

**Current truth as this document is written:** this is a new design. No V3 proof checker, benchmark, full Lean compatibility or soundness theorem has yet been established.

## 9. Primary source links

- [Official Lean 4.35 kernel](https://github.com/leanprover/lean4/tree/v4.35.0-rc4/src/kernel), especially [type_checker.cpp](https://github.com/leanprover/lean4/blob/v4.35.0-rc4/src/kernel/type_checker.cpp) and [inductive.cpp](https://github.com/leanprover/lean4/blob/v4.35.0-rc4/src/kernel/inductive.cpp).
- [Lean Kernel Arena](https://arena.lean-lang.org/) and [export protocol](https://github.com/leanprover/lean4export).
- [sokonanoda](https://github.com/intgrah/sokonanoda), [MathGraph](https://github.com/metalogiclabs/mathgraph-lean-kernel), [nanoclo](https://github.com/sgraf812/nanoclo), [nanobruijn](https://github.com/nomeata/nanobruijn), [lazylean](https://github.com/corun1024/lazylean).
- [con-ron](https://github.com/leanprover/con-ron), [con-leche](https://github.com/leanprover/con-leche), [lean4lean](https://github.com/digama0/lean4lean).
- Original [V2 major architecture](../psc0/packages/pskernel-core/PSKERNEL_FAST_MAJOR_ARCHITECTURE_V2.md) — **historical and superseded**, not an implementation or proof migration constraint.
