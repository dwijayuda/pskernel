# PSKernel-C0 architecture-first execution plan — C → D → E, then B → F → G

**Decision:** 2026-10-13. Architecture-first development is authoritative for the native C0 workstream.  
**Scope:** `dwijayuda/pskernel`, branch `perf/pskernel-c0-v7-rust-20261012`, `psc0/packages/pskernel-c0/`; native Lean 4.35.0 only.  
**Non-goals:** no changes to original `pskernel-core`, PSC0 compiler, generated Rust, Wasm/self-host or metatheory during C–E construction.

## Decision and bounded evidence freeze

Phase B's **exhaustive compatibility exit gate is deferred, not waived**. Preserve all official identical-byte accepted/rejected fixtures, real Init export digest, strict unsupported/rejected/resource distinctions and the independently verified accepted 79,416-record prefix. Preserve the known false rejection at record 86,383 (`Std.PRange.UpwardEnumerable.succMany?_add`) as an open regression. The native [CI 38395502669](https://github.com/dwijayuda/pskernel/actions/runs/38395502669) and real [CI 38395528602](https://github.com/dwijayuda/pskernel/actions/runs/38395528602) both passed on their explicit bounded gates, **not full Init acceptance**.

The full `Init` source is 6,452,982 exported records, 57,919 declarations, 345,690,182 bytes, pinned to Lean 4.35.0 and `lean4export` `5a9a355d`; the official Lean checker accepts it. C0 currently accepts an independently gated *prefix*, not this corpus. Documentation-only commits are not executable qualification.

## Clean architectural choices

**No historical architecture lock-in.** Evaluate three implementations on the same complete checked workload and identical source semantics: (A) lean-native shared recursive expressions, (B) canonical persistent/scratch indexed handles, (C) lazy closure/value execution. Pick a source/arena/closure hybrid only where measured costs, semantic clarity and resource behavior justify it. Never equate a syntax DAG microbenchmark with checker throughput.

**One coherent authority boundary.** A source-checked declaration is valid only if the accepting checked-session implementation has admitted it. The optional closure/arena executor is *not* a checked judgment or proof certificate. Candidate evaluation may produce diagnostic observations only, not admission, proof receipts or build artifacts. Failures classified as malformed, unsupported, resource-exhausted and rejected-invalid remain distinct.

**Cache ownership and invalidation.** A cache key must include all relevant environment revision, local scope, reduction/eager policy, universe instantiation, fuel semantics, safety policy and term ownership. No WHNF/DefEq/type cache can be transported across unqualified environment extensions; provisional mutual declarations are especially sensitive. Source-side syntax-only canonical caches may be shared across contexts only after exact structural equality.

## Phase E.3B — Proof-erased audited lineage and atomic checked publication

The ordinary trusted lineage [c391e9e / native CI 38515613460](https://github.com/dwijayuda/pskernel/actions/runs/38515613460) and the audited foundation lineage [10f0e67a / native CI 38516202049](https://github.com/dwijayuda/pskernel/actions/runs/38516202049) both passed all mandatory native gates. The audited checked-root publication additions and mixed valid/invalid atomic rejection in [0db4128d / native CI 38516762681](https://github.com/dwijayuda/pskernel/actions/runs/38516762681) also passed full native qualification.

**Representation refinement:** use Prop-indexed proof-only state histories, not Type-valued execution histories. This avoids preserving unneeded lists of checked-state transition constructors as runtime data. The Prop source change is [0454fa3c](https://github.com/dwijayuda/pskernel/commit/0454fa3cee407995cfd94c6888bc5545bfea955b), [full native CI 38517005664](https://github.com/dwijayuda/pskernel/actions/runs/38517005664); full native CI **SUCCESS**, independently qualified. Do not claim an observed whole-kernel speedup or exact memory bound from proof erasure without a separate measured run.

**Closing the publication seam:** PsKernelC0SealedAuditedPublication binds an exact source checked-root commit equation to the complete audited work and fuel. Both a lone ill-typed root and a mixed valid/invalid staged batch are rejected atomically. Syntax staging, proof-lineage existence, approved axioms, and a cached WHNF cannot issue a checked publication by themselves. Existing full-check source, closed-variable/universe and canonical-root rules remain authoritative.

**Remaining integration:** the sealed trusted/audited entry points remain opt-in, and legacy raw checker-state APIs are still constructible. A subsequent coherent Phase E migration must make the real externally receiving API use a sealed checked-session provenance boundary (or explicitly mark external-import trust), then prove optimized evaluator/DefEq/inference preservation rather than delegating arbitrary results to the old source checker. Keep the source oracle independent until the source refinement and full negative/resource conformance have been qualified.

## Phase E.3 — Exact checked-state genesis and audited-policy lineage (2026-10-14)

**Verified Phase E.3 trusted lineage:** [c391e9e](https://github.com/dwijayuda/pskernel/commit/c391e9e0539b264f4ad8895908fa83e924d5b571), full [Lean 4.35 native CI 38515613460](https://github.com/dwijayuda/pskernel/actions/runs/38515613460) SUCCESS. Architecture/SealedState.lean adds an opt-in Type-indexed state provenance chain rooted in the literal empty trusted source checker (not just environmental admission), and requires the exact successful equation for each checked WHNF/inference/DefEq/full-check/admission/staging transition. Every result carries a new lineage; failed operations publish none. The entire certified work is indexed, so arbitrary caller-written success caches cannot enter this *opt-in* API without an equality proof from the actual genesis.

**Separate audited authorization lineage:** Architecture/SealedAuditedState.lean provides the same exact-state reachability for the approved-foundation profile, with literal audited genesis, exact signed axiom/capability permissions, exact successful checker transitions, and explicit all-history policy-change reauthorization. It cannot widen a manifest merely from a name match or turn approved assumptions into proofs. The mandatory C0SealedAuditedStateRegression.lean covers denied unauthorized axioms, approved exact signatures checked independently by the source kernel, rejection of post-admission unauthorized narrowing, negative typing, and resource exhaustion. Code checkpoint [10f0e67a](https://github.com/dwijayuda/pskernel/commit/10f0e67a2243f11feddc45a075fa1958fe6c92fa) has [native CI 38516202049](https://github.com/dwijayuda/pskernel/actions/runs/38516202049); check the completed result before declaring it qualified.

**Precise limits:** Existing raw checker/session constructors are still public; these lineages certify specific newly exposed APIs, not every legacy external path. Lineage certifies provenance of *execution and approvals*, not the soundness of the original source checker or each cache algorithm. Source semantic refinement, cache memoization correctness, imported environment provenance, complete independent accepting DefEq/infer/admission and fully matched kernel performance remain outstanding. The next architectural integration must be one coherent sealed audited acceptance boundary rather than perpetual extra candidate-only modules. Preserve all negative, resource/error and Lean 4.35 compatibility gates unchanged.

## Phase E.4I — Proved Nat/String literal conversion with full checked-provider parity

**Earlier completed:** [Sort-level native E.4H CI 38533431404](https://github.com/dwijayuda/pskernel/actions/runs/38533431404) **SUCCESS**, covering full native positive/negative, independent checker and source-equivalence gates.

**New coherent scalar fragment:** Architecture/CertifiedWork.lean also independently evaluates literal-literal DefEq (Nat and String, including Unicode) with an all-context Lean theorem proving exact result and entire source checked-cache state preservation. It shares the qualified selector with Sort-level and reflexive rules; all unhandled terms and exhausted resource cases retain the original source checker. The native literal comparison implements Lean 4.35's quick literal equality rule, not a new trusted primitive and not independent typing of the Nat/String constructors.

**Mandatory source tests and CI:** test/C0LiteralDefEqRegression.lean verifies all 0–4 Nat pairs, a Unicode/empty/String value matrix, exact source equation, checked cache and error semantics, and comparison of source full typing against the verified provider without assuming literal types require pre-admitted Nat/String declarations. [Executable CI 38534555546](https://github.com/dwijayuda/pskernel/actions/runs/38534555546) covers [6acc39a8](https://github.com/dwijayuda/pskernel/commit/6acc39a8592259a84d83d41b7905cbe0edc67e2d); do not assert full qualification until exact-SHA final SUCCESS.

**Critical caveat:** Scalar DefEq refinement is relative to C0's executable source decision procedure and does not prove its type-theory metatheory or general optimized higher-order DefEq. Check full performance on mixed and large nonreflexive workloads before claiming any speedup; preserve opaque/trusted-import isolation and exact error/resource semantics. Complete C/D/E and full B/F/G gates remain open.

## Phase E.4H — Independently source-equivalent Sort universe equality

The checked accepting DefEq selector now includes a **complete Sort-level comparison family**, not only structural reflexivity. The independent rule (Architecture/CertifiedWork.lean) uses the same pinned Lean 4.35 universe-level equivalence algorithm and exact source ordering: fuel/recursion checks, structural equality, positive cache hit, and level comparison with success-only cache update. A native Lean theorem proves that for any successful direct result, its entire value/state pair equals the original C0 source checker result for every input context, state and levels. The dependent-typed checked-work receipt binds that source equation, and actual trusted/audited provider state-lineage operations use it. On decline or non-Sort inputs, the already qualified reflexive or original source algorithm remains authoritative. The separate mandatory C0SortDefEqRegression tests exact proofs, Sort(max 0 0) versus Sort 0, Sort 0 versus Sort 1, raw-cache isolation, fuel/depth failure and verified provider full checking.

**Source executable checkpoint:** [b2ca36d3](https://github.com/dwijayuda/pskernel/commit/b2ca36d3986c809724386db56788043b9fee5352). **Qualification gate:** [full native CI 38533431404](https://github.com/dwijayuda/pskernel/actions/runs/38533431404), including original-vs-C0 independent checker. Full native CI 38533431404 completed SUCCESS; this exact source checkpoint is qualified. No broad independent DefEq, general source-cache semantic validity, Lean Init/Std/Mathlib conformance or Phase E exit claim follows. Further work should consolidate source-proved scalar/literal, closure, binder and dependent typing families into one selected accepting engine, preserving exact error/resource and audit semantics and avoiding duplicate full-tree equality probes on nonreflexive workloads.

## Phase E.4F/G — Verified public checked-root publication and proven reflexive DefEq

**E.4F public provider completed and qualified:** [3ecdde70 / full CI 38531065331](https://github.com/dwijayuda/pskernel/actions/runs/38531065331). The provenance-qualified public provider now supports source inference, explicit signed-foundation policy review, syntax-only single/batch root staging, exact whole-selection staging receipts, full-checked atomic root publication, and a combined publish-roots operation whose dependent return type requires BOTH exact source staging and exact successful audited closed-root checking. The mandatory provider publication regression rejects open/untyped/unknown-universe roots, mixed valid/invalid batches, cancelled resource policies, missing exact axiom permission and post-admission policy downgrades. This is complete for this provider-facing checked-publication scope; it is not a complete independent kernel and does not verify executable backend semantics.

**E.4G direct checked-DefEq proof candidate:** [16b80065 / CI 38531955659](https://github.com/dwijayuda/pskernel/actions/runs/38531955659), final workflow qualification pending. Based on upstream pinned Lean 4.35 src/kernel/type_checker.cpp quick_is_def_eq and the native source Checker/Knot.lean, the code extracts independent source-exact reflexive DefEq into a small, explicitly fuel/recursion-checked path. It reproduces the original source algorithm's positive cache insertion and follows exact source errors and fallbacks otherwise. A Lean all-context theorem (subject to exact-SHA native CI) establishes full source value/state equivalence; trusted/audited sessions use the proved path, but full expression checking still guards the verified public DefEq API.

**Performance and assurance cautions:** A sound-by-source-refinement quick fragment is not a complete semantic proof for the original kernel, and its extra syntactic precheck may have cost on nonreflexive large terms. Evaluate on matched complete checked workloads and avoid making a throughput claim from pass/fail tests. Do not use speculative source candidates to authorize type checking. Full Phase C/D/E exit still requires complete type-theoretically faithful independent reduction/inference/admission, verified cache ownership and resource/error behavior. Continue with Phase B full real library, F whole checked-workload comparisons and G formal soundness only after the earlier architectural gates.

## Phase E.4E — Matched public-provider full-check equivalence (qualified 2026-10-14)

**Qualified source:** [7966153d](https://github.com/dwijayuda/pskernel/commit/7966153db3a7bf3383e8b4da18deb58863a519ef), full [native Lean CI 38526076408](https://github.com/dwijayuda/pskernel/actions/runs/38526076408) SUCCESS. The mandatory native `C0VerifiedProviderRegression` now checks one identical safe definition through both the existing KernelContract-v1 public provider and the provenance-qualified verified provider. It compares successful **full source declaration admission**, environment size, type checking of the admitted constant, delta WHNF and DefEq; also requires zero new axiom/trust events and atomic rejection of duplicate admission. This is an entire checked declaration/query workload, not a syntax DAG or nonaccepting candidate benchmark. The separate exact-SHA [CI 38525449433](https://github.com/dwijayuda/pskernel/actions/runs/38525449433) qualified the concrete raw positive-DefEq-cache isolation and typed trust-denial regression.

**Assurance claim:** This confirms two native source-authoritative public interfaces agree on the selected fully checked fixture, under equal parameters. It does NOT establish semantic soundness of the old checker, complete independence of the optimized accepting engine, universal API equivalence, or Lean Init/Std/Mathlib support. The new provider still runs the original source evaluator for context-dependent normalization and DefEq; only the already-proved irreducible/meta WHNF fragment bypasses it.

**Next:** keep the verified provider as the prospective public proof-authoritative entry and make legacy raw construction explicitly low-level/trusted; prove or check state and cache ownership on all remaining public acceptance paths and imported snapshots; extend exact source-refinement proofs to a coherent nontrivial evaluator family before optimizing DefEq/inference. Preserve mandatory negative source tests, full same-byte compatibility and formal soundness acceptance criteria.

## Phase E.4D — Explicit source cache trust boundary and typed authorization errors

**Negative conformance qualification gate:** The raw source checker state exposes positive DefEq cache entries. In the regression, externally inserting an inconsistent positive pair for two different checked Sorts changes the result of raw DefEq; this proves the importance of NOT treating externally constructed checker state as a proof-authoritative verified session. The separately founded verified provider's DefEq path must still return false for the exact same Sort pair and must never import the raw cache entry. This tests a concrete trust distinction, not a flaw in actual source-checker-generated caches, nor an independent source-kernel soundness proof.

**Verified provider policy denial:** Missing exact axiom signatures and missing required unsafe/partial/Quot capabilities are typed `declinedUnsupported` requests at the provider boundary, while the checked audited admission still independently enforces the same permissions. Unknown internal kernel diagnostics are not turned into logical invalidity and no policy refusal creates a checked declaration.

**Additional completion gates:** make verified API imports construction-restricted at the actual public distribution boundary; audit all raw session consumers and keep only explicitly low-level/trusted uses; establish a mathematical semantic invariant for each cache family and every state transition; verify that resource/error semantics match pinned Lean 4.35; qualify full matched source/optimized checker conformance and library acceptance before Phase E exit.

## Phase E.4C — Source-checked verified provider and per-member mutual trust (2026-10-14, full native CI QUALIFIED)

**Executable:** [aad36e06](https://github.com/dwijayuda/pskernel/commit/aad36e06b7d2435b62aae72eed09a6a467c8d2e4), fully qualified by [native CI 38523854819](https://github.com/dwijayuda/pskernel/actions/runs/38523854819), covering all mandatory Lean 4.35 positive/negative export fixtures, source and architecture regressions, verified-session and provider public paths, root/assumption audits, resource behavior, performance diagnostics and independent original checker comparison.

**Provider entry architecture:** Keep `API/VerifiedProvider.lean` explicitly separate from legacy `PsKernelKernelSession`. Verified provider creation starts from the literal empty environment, checked state lineage and signed foundation manifest; never import unqualified `PsKernelCheckerState` or an arbitrary source environment. Apply KernelContract-v1 provider/target compatibility and existing typed preflight errors, require policy recursion and numeral size to equal the actual pinned genesis checker context on every operation, and enforce declaration limits after complete source admission with immutable-error atomicity. Full expression checking is mandatory before exposing provider WHNF or DefEq as a result. The verified provider's result remains source-authoritative, not independent proof of semantic soundness.

**Atomic mutual definitions:** The native source `psKernelAddMutualDefinitions` owns a single complete family admission check, including consistent safety, header/body validation, and safe/unsafe/partial semantics. `Architecture/Work.lean` now dispatches one `.mutualDefinitions values` request atomically; `AuditedAssumptions.lean` computes exact member-by-member `.unsafeDefinition` or `.partialDefinition` capability events. A valid family cannot be approved by permission for only one member. The provider forwards the complete original source request and its signed manifest. Invalid empty families are source-rejected as invalid, no longer reported as unsupported. Separate family-wide negative, one-capability and full two-member regressions passed full CI. This supersedes older E.4B notes where mutual definitions were temporarily declined.

**Remaining public trust boundary:** Merely exporting the facade does not disable constructible legacy raw environment/session records or establish the independent mathematical validity of their caches. For a production-only verified interface, migrate or explicitly isolate raw provider consumers and pin provider contract/operating policies to the mathematical lineage before claiming a sound independent accepting checker. Preserve exact checked-environment admission proofs, full signed assumption events, no failed partial publication, identical source resource/error semantics and required Lean compatibility gates. A raw construction API must not be relabeled "verified" without actual lineage proof.

**Next major implementation:** Consolidate verified-provider acceptance as the default offered interface where the contract permits; then develop the full source-equivalent optimized WHNF/DefEq/inference on qualified cache ownership and eventually full conformance and formal soundness. The native public bridge is NOT Phase E exit, nor evidence of an independent optimizer speedup. Do not relax the C/D/E/B/F/G gates.

## Phase E.4 — Provider-facing verified session migration (implementation checkpoint)

`API/VerifiedSession.lean` now offers an opt-in coherent facade over `SealedAuditedState.lean`: checked empty genesis, source declaration admission, WHNF, inference, full term checking, DefEq, syntax staging, fully reaudited trust policy changes, and exact atomic closed-root publication. This is a **provenance-qualified workflow**, not a new accepting typing rule or an unverified candidate promotion. All successful operations preserve the underlying exact state-lineage and approved foundation proofs.

**Qualification:** source and test checkpoints [d69bd4aa](https://github.com/dwijayuda/pskernel/commit/d69bd4aaf02d2bfc6fbeafec78f8dad7b2ad3768) and [58e2b3af](https://github.com/dwijayuda/pskernel/commit/58e2b3afb61db654df917f4e93aaa581f25785a5), mandatory native test `C0VerifiedSessionRegression.lean`, full [CI 38521016591](https://github.com/dwijayuda/pskernel/actions/runs/38521016591). Treat as PENDING until the complete exact commit run finishes successfully, including independent original checker comparison.

**Next architecture gate:** Determine the actual public/provider API entry points that accept raw `PsKernelCheckerSession`, `PsKernelCheckerState` or a constructed `PsKernelC0TrustedSourceWork`. Migrate the proof/admission-facing entry points to a construction-restricted facade without breaking the authorized source-trusted kernel's completeness, resource/error distinction or pinned Lean 4.35 semantics. Avoid incompatible public API replacement before exhaustive native regression, proof-carrying provenance, and negative malformed-state conformance. Separately prove/refine source cache correctness: lineage proves that an implementation operation ran, not that the source implementation was sound.

## Phase E.2 — Verified fuel-exact nested metadata WHNF (2026-10-14; full native CI qualified)

**Executable:** [64c5b6c3](https://github.com/dwijayuda/pskernel/commit/64c5b6c33fb03596cf3109b6199483fb7a760206). **Qualification:** [native Lean 4.35 CI 38510186410](https://github.com/dwijayuda/pskernel/actions/runs/38510186410) **SUCCESS** across the entire mandatory source compilation, official Lean accepted/rejected exports, CDE-0–10 semantics/assumption/store regressions, source and negative/resource fixtures, a 0–32 nested-metadata source-fuel grid, native microbenchmarks and independent original-versus-C0 checked kernel comparison. [CI 38510005087](https://github.com/dwijayuda/pskernel/actions/runs/38510005087) separately qualified the pure fragment proof and its initial integration.

- Architecture/CertifiedWork.lean defines a small fuel-recursive independent evaluator for arbitrary nested mdata wrappers terminating in precisely one of BVar, Sort, MVar, forallE/Pi or literal. Each wrapper and the irreducible head consume one source WHNF fuel step; insufficient fuel and every other head decline to the original source checker. No source context, recursor callback, cache or declaration metadata is read on the proven pure branch.
- Theorem psKernelC0IrreducibleWhnf_source is quantified over **every** source context, checker state, recursor callback and expression accepted by this pure fragment. It establishes equality of the public source-WHNF expression AND checker state. psKernelC0IrreducibleWhnf_certified proves the corresponding exact certified-work result. psKernelC0CertifiedWorkWhnfCanonicalFast_exact proves the optimized/public source operation equations for all source inputs (including failure cases), and PsKernelC0SourceExactWhnfOutput carries a result-specific Lean witness.
- Ordinary trusted and audited WHNF operations now use this proof-qualified source-free execution on eligible inputs by default, with one shared history/permission proof rebind. All other terms keep the authoritative source route; optionally metered closure-demand observations still cannot admit anything. This is a completed narrow source-equivalent WHNF fragment, **not** a general independent optimized evaluator, full DefEq/inference or kernel consistency.

## Phase E.3 — Next architectural gate: checker-state/cache provenance and whole accepting refinement

**Root trust-boundary constraint:** The existing SourceEnvironmentHistory and audited foundation witnesses establish source **environment admission and allowed foundation events**, not independently checked validity of caller-constructed PsKernelCheckerState caches. In current C0 Lean data structures, checker state and trusted work fields are constructible; in pinned Lean 4.35 src/kernel/type_checker.h, type_checker::state's WHNF/infer and success/failure DefEq caches are private to the checker. C0 quick DefEq reads cached successful pairs. Before claiming a verified PUBLIC accepting session, require explicit provenance for the exact checker state, not just its environment. This is an architectural exposure to qualify and close, not by itself evidence that a currently accepted checked declaration is invalid.

**Design acceptance criteria:**

1. Specify one cache/session provenance invariant rooted in the *actual* empty source checker and carrying exact source or proved-refined successful state transitions. Bind it to the immutable work and environment revision, local context, universes, transparency/reduction/safety policies and resource semantics. No user-supplied arbitrary success, infer or WHNF cache may acquire public proof authority.
2. Preserve provenance across full WHNF, checked inference, DefEq, full term check, source admission (with fresh cache invalidation), scratch staging and checked-root publication, including genuine failures leaving the previous work intact. Avoid re-auditing entire histories on each safe operation.
3. Require negative source-conformance evidence that externally substituted cache entries or stale environment-dependent entries cannot change public acceptance; confirm the same source-checked declarations, failures and resource categories as the independent original checker. Preserve explicit exact axiom signatures and default-denied unsafe/partial/Quot capabilities.
4. After session state lineage is sealed and qualified, establish closure/value/arena bisimulation and readback/refinement across the complete Lean 4.35 reduction families (beta/zeta, delta, native numerics, recursors, Quot, K/eta, universe/literals/local contexts), then integrate one accepting DefEq/inference/check/admission pipeline without source-first verification for proven families. Keep strict test/heap-resource claims separate from mathematical soundness and conditional consistency.

**Performance caveat:** The current direct fragment removes source WHNF invocation only on mathematically qualified easy inputs; it does not justify a whole-library competitive speedup. Full same-corpus C0/Lean 4.35/original/con-leche/con-ron comparison remains Phase F.

## Phase E refinement checkpoint — source-equivalence proof boundary (2026-10-14; qualified in CI 38508875844)

The opt-in checked-work WHNF bridge is implemented in Architecture/CertifiedWork.lean, checkpoints [7d85cc5d](https://github.com/dwijayuda/pskernel/commit/7d85cc5d69e035a12d7c719948568b38fc63cad1) and [8b3c453c](https://github.com/dwijayuda/pskernel/commit/8b3c453c5fd973ac3723afbc2283afe7367a4f2c). **Subsequently qualified in full [native CI 38508875844](https://github.com/dwijayuda/pskernel/actions/runs/38508875844) after the receipt-dependent pattern proof correction.**

**Proved selection invariant (Lean definitions/theorems subject to native compilation):** any candidate value selected by the accepting work API carries a propositional equality witness that it is the exact successful source WHNF result for the same input fuel, immutable certified work, active context and source cache state. The source result is computed first, the source follow-up state is the only returned session, and decline/mismatch is a non-vetoing source fallback. The receipt preserves the exact source WHNF function equation. Neither a Boolean expression comparison nor a shared hash constitutes proof authority.

**Lean 4.35 reference choice:** src/kernel/type_checker.cpp orders structural/core WHNF, native/Nat reductions and delta; src/kernel/type_checker.h owns environment-scoped caches and keeps algorithmic DefEq success/failure sets without transitive closure because its semidecision procedure is not transitive. C0 retains its exact source order, context and state; no unqualified fast result reaches full term checking or admission.

**Do not count this bridge as independent accepting-kernel completion.** It still invokes source WHNF, hence incurs extra cost and does not justify dropping the source oracle. For Phase E exit, establish and native-qualify a general WHNF refinement property across closures, universes, local contexts, recursor/K/eta, Quot, native primitives, reduction policy, fuel/resource/error behavior; after that, replace source evaluation only for fully qualified cases, then integrate independent DefEq/inference/admission without an unchecked source-term promotion. Preserve same-byte positive/negative export gates.

## Phase E.1 — Qualified source-free WHNF heads under full audit (2026-10-14; CI 38509487986)

A tighter, independently implemented accepting-WHNF fragment now follows the verified-source bridge above. For positive source fuel, C0 returns BVar, Sort, MVar, forallE/Pi and literal heads directly without invoking the original source normalization evaluator, exactly as pinned Lean 4.35's kernel src/kernel/type_checker.cpp and the project source WHNF direct cases do. The direct operation handles source fuel zero through the unmodified source path. All other expressions are routed to the previous source-first/candidate-cross-check operation, never to unproven direct evaluation.

The all-context proof obligation psKernelC0CertifiedWorkWhnfCanonicalFast_exact is authored in Architecture/CertifiedWork.lean. It equates both output expressions AND immutable checked work state (including the exact source checker state). The dependent-typed PsKernelC0SourceExactWhnfOutput records that full source WHNF equality for every successful result; direct and source-first operators construct it differently, then PsKernelC0CertifiedWorkWhnfQualified combines both. This makes the source result a programmatically inspectable certificate instead of an unchecked observation, but **formal Lean compilation of the new theorem is pending** and its statement does not extend to arbitrary closure reductions.

The complete audited history has an opt-in source-equivalent WHNF route in Architecture/AuditedAssumptions.lean: source-equivalent state, proven unchanged environment, checked admission history, full signed-axiom policy, and separate capability proofs are transported together. No change to core type checking, inference, DefEq, checked declaration admission, trusted foundations, or original checker oracle. Existing native C0CertifiedWorkRegression and C0AuditedAssumptionsRegression now cover direct heads, beta fallback, delta unfolding, zero-source-fuel and zero-candidate-quota, source-receipt proof typing, and preserved full audit proof/history.

**Status: full [native CI 38509487986](https://github.com/dwijayuda/pskernel/actions/runs/38509487986) SUCCESS; exact-SHA native status reporting is now available.** This is a *small, mathematically scoped independent acceptance integration*, NOT complete Phase D/E, formal soundness or whole-kernel performance. Native build is mandatory before counting any new theorem/behavior as qualified, and full C/D/E goals remain unchanged. Next: prove source refinement for nontrivial evaluator families on the exact Lean 4.35 context/resource semantics, replace source evaluation only for the proven families, then integrate the independent DefEq and inference work.

## C: representation and ownership

- Keep source `PsKernelExpr` as independent oracle; introduce private execution terms with explicit provenance (persistent immutable base and disposable scratch lifetimes).
- Enforce acyclic children-before-parents, persistent-to-persistent edges, checked hash collision behavior, immutable abort, selected-root promotion and strict whole-store readback. No externally supplied raw Nat handle determines semantic equality across stores.
- Define a compact execution-state interface independent of source substitution, with explicit resource accounting. Begin with operation-local ownership, then evaluate packed/tagged handle representation against native structural sharing.
- **C exit:** whole-operation benchmarks and error-category equivalence plus an auditable `StoreWF` contract. Formal proof is Phase G; no accepting indexed result until then.

## D: closure/value weak-head evaluator

- Establish an evaluation machine with explicit control closure, delayed environment substitutions, and argument spine. Reduce β and ζ without eagerly reconstructing the entire application spine. Distinguish neutral value, lambda closure, unsupported form and exhausted resource.
- Add typed handling of local binders, constants and universe application, projection, primitive numerals, quotation, recursors and transparency policy as separate coherent families. For any unqualified family, return an explicit decline and use the authoritative checker instead.
- Source reification must be capture avoiding; compare exact β/ζ/metadata behavior and resource/error classes against source WHNF. Never assume absence of syntactic target names proves absence under δ reduction.
- **D exit:** checked evaluator semantics for the supported Lean 4.35 closure; all actual source forms have positive/negative differential tests and bounded resource behavior.

## E: one accepting checker

- Connect the selected engine to one WHNF/DefEq/inference/proof/admission pipeline with explicit trusted boundary. The candidate may accelerate only operations whose complete context and semantic equivalence are qualified.
- Preserve full binder, universe, proof irrelevance, quotient, inductive, recursor, local, literal and safety semantics. Admission must be atomic: a failed mandatory check leaves the preceding environment intact.
- Remove duplicated historical fast paths only after broad positive and negative qualification; never add fallback acceptance based on an unchecked candidate.
- **E exit:** complete coherent accepting kernel over the planned scope, independent same-byte differential CI and resource/error equivalence. Passing only a small synthetic slice does not qualify E.

## Phase B after E

Resume complete pinned `Init` acceptance, then Std and Mathlib with known unsupported features and independent negative cases. Zero false acceptance is mandatory. Treat out-of-fuel as computational failure, not a logical rejection. The record-86,383 counterexample is a regression fixture, not something to bypass.

## F and G

F: independently measure Lean 4.35 official, project-local original, con-leche, con-ron and C0 on identical *fully checked* corpora with p50/p95 time, allocation bytes/events, RSS, memory lifetime, cold/warm and error rates. Do not assert a competitive ranking from unequal datasets.

G: prove source/optimized denotation, substitution/reification, canonical-store invariants and sound refinement or connect an independent verified acceptance gate. Consistency is a theorem under explicit axioms, not inferred from green tests.

## CDE-0 executable foundation (2026-10-13)

The architecture-first route has moved beyond planning. `Architecture/Execution.lean` now contains explicit control closures, delayed binder environments and an argument-spine machine for small syntactic β/ζ/metadata WHNF. `Architecture/Work.lean` implements an exact validated scratch syntax transaction, source-authoritative preview/check and atomic declaration admission through the existing checked kernel, with fresh session caches after environment changes. New `C0ArchitectureExecutionRegression.lean` and `C0ArchitectureWorkRegression.lean` run as mandatory native CI steps. Passing their small coherent source-differential slice establishes no formal refinement, full optimized WHNF or new accepting kernel. Source-owned proof checking remains the exclusive admission authority.

## CDE-1 — environment-aware lazy delta (2026-10-13)

`Architecture/Delta.lean` extends the closure/spine candidate with one source-owned, safety-guarded delta step on precisely reified syntax at a stuck constant head. It reenters the lazy execution machine for subsequent β/ζ steps, preserving an explicit reduction and quotation budget; partial/unsafe definitions are declined, opaque constants remain neutral. `Architecture/Work.lean` exposes `psKernelC0ArchitecturePreviewDelta`, which always computes the authoritative checked WHNF **first** and never publishes the candidate result as a proof. The mandatory `C0ArchitectureDeltaRegression.lean` checks direct/chained and universe-parametric aliases, delta-to-lambda β, ζ, non-reducible opaque heads, malformed/unsafe policy and fuel exhaustion. This is still a **non-accepting partial evaluator**, not complete Lean WHNF or Phase D exit acceptance.

## CDE-2 — lazy primitive Nat literal spine (implementation pending qualification)

The source-authoritative `Execution`/ `Delta` pipeline now includes `Architecture/NatLiteral.lean`, a **candidate-only** operation family. On a stuck primitive Nat head, it reifies only required delayed numeral arguments and delegates arithmetic and size/count limits to the already existing source primitive functions. When no Nat primitive head is recognized, it does **not** quote unrelated neutral arguments. Candidate evaluation tries this family before δ as the source WHNF pipeline does. Nonliteral arguments, full recursive primitive WHNF, projections, Quot, recursors, and full local-context reductions remain outside this feature boundary.

The mandatory delta regression was extended to all 14 binary primitive operation names, successor, captured β/ζ operands, neutral heads, explicit zero fuel and limited numeral size; a non-accepting result cannot enter checker admission. The code was pushed, but there is **no independently confirmed CDE-2 native CI success yet**: do not confuse the prior CDE-1 run 38412434965 with CDE-2 qualification. The next required gate is native compilation and successful source-differential/negative checks on the new HEAD. C, D and E remain incomplete.

## CDE-3 — local context and constructor-head projection (code pushed; CI pending)

`Architecture/Structural.lean` adds a single dispatcher on top of the CDE-2 closure machine, preserving β/ζ, primitive Nat, δ, and the existing checked authority seam. When the machine head is a local `fvar`, only source local-let declarations unfold; hypotheses are neutral. When the head is a `proj`, the delayed scrutinee is reified exactly and the **source** `psKernelReduceProjCore` checks constructor metadata and selects the field with the correct parameter offset. This is a bounded fast WHNF family; it does not recursively normalize a projection scrutinee yet. Unsupported scenarios remain candidate/source disagreements, never checked acceptance.

The mandatory native regression now includes local-let shadowing, constructor field projection with parameter offset, wrong type/index neutrality, β/ζ capture, and zero fuel, plus source-exclusive structural preview and ill-typed rejection tests. Constructor metadata injected by test code is for source-WHNF comparison only, **not inductive declaration admission**. This is implementation evidence, not compilation/CI qualification: previous success 38412434965 predates both CDE-2 and CDE-3. Architectural next step is one shared fuel-threaded nested-demand evaluator rather than ad hoc recursor/Quot helper fallbacks. Full C/D/E exit remains unclaimed.

## CDE-4 — shared-fuel nested demand stack (code pushed, qualification pending)

To avoid building another recursive evaluator with reset per-premise budgets, `Architecture/Demand.lean` adds continuation frames to the existing closure/spine machine. A source-recognized Nat head may demand one or two operands; a projection may demand its scrutinee. Each nested descent, return and primitive/structural transition consumes **the same** structurally recursive transition fuel. Source arithmetic size policy and source projection-selector metadata are reused, but *source WHNF* is never invoked within the candidate evaluation loop. When an operand remains stuck, the exact parent head/spine is restored, preserving source-visible weak-head syntax.

Integration through `Architecture/Work.lean` remains preview-only: the checked session normalizes first; candidates never issue checking verdicts or admission. Mandatory native regression fixtures now cover nested Nat, projection β/ζ majors, projection-as-operand, local lets, neutral/nonmatching heads and low shared fuel. CDE-2, CDE-3, and CDE-4 have **no newly confirmed passing native CI** in this session; [38412434965](https://github.com/dwijayuda/pskernel/actions/runs/38412434965) is a prior CDE-1 checkpoint. CDE-4 does not implement quotient/recursor, full typing/DefEq, globally metered quotation allocation, or C/D/E exit criteria.

**Next gate:** native Lean 4.35 compilation and exhaustive current mandatory source/negative tests, then a semantics-driven quotient/recursor demand extension with one fuel policy. Do not claim independent checked equivalence, whole Init compatibility or verified soundness from this partial candidate.

## CDE-5 — quotient major-demand and qualified CDE-2–5 (2026-10-14)

`Architecture/Demand.lean` now carries Quot.lift and Quot.ind major premises through the existing single-operation fuel/continuation stack; reduction requires the source quotient-initialized flag and exact `Quot.mk` three-argument shape. Function/representative selection and additional application arguments follow the source quotient reduction rule. Unlike Nat primitives, quotient eliminators have universe arguments; the head-dispatcher explicitly checks them before applying the Nat empty-level guard. Synthetic positive/negative source-WHNF differential tests cover lift, ind, nested β/ζ major, quotient result consumed by Nat, surplus args, wrong/missing constructor shapes, no initialization, and budget decline. The source checker is still the sole trusted judgment path.

**Qualified source:** [`e2eaac64`](https://github.com/dwijayuda/pskernel/commit/e2eaac64e8a17325c847e761c62d36a00e440639), full [native CI 38439633705](https://github.com/dwijayuda/pskernel/actions/runs/38439633705) **SUCCESS**. Compilation, source differentials CDE-0–5, official replay fixtures, negative conformance, performance microbenchmarks and independent original-core comparison passed. Prior CDE-2/3/4 historical notes saying 'CI pending' are superseded for their *bounded feature slices*. This is **not** complete Phase D/E qualification, formal refinement, full real Init/Std/Mathlib C0 acceptance, real Quot-admission proof, or competitive full-workload benchmark evidence.

Next architecture focus: ordinary recursor-major demand with precise constructor-rule/universe/fixed-argument semantics and careful K/literal cases, plus globally metered quotation and gradual consolidation of candidate-only execution before any accepting integration.

## CDE-6 — non-K constructor and Nat-literal recursors (2026-10-14)

The candidate continuation evaluator now recognizes source environment `recInfo` before the specialized zero-level Nat primitive gate. It does not admit K or unsafe recursors to the ordinary iota rewrite. A major premise is evaluated in the *same* fuel loop. Ordinary recursor rules are selected from the source environment, with exact occurrence universe instantiation, fixed parameter/motive/minor arguments, trailing constructor fields and surplus recursor arguments. Nat literals are normalized to `Nat.zero`/`Nat.succ` constructor shapes for rule matching; String-literal constructor expansion and structure/K handling are deferred.

Mandatory source-WHNF differentials exercise direct and β/ζ-major constructors, Nat zero/succ, polymorphic RHS, fixed argument ordering, constructor parameter skip, wrong names/arities, low fuel, and explicit K/unsafe policy distinction. The source checker remains the only authority for admission.

**Executable qualification:** [`7917de8a`](https://github.com/dwijayuda/pskernel/commit/7917de8a0f9ad08a967f3399599bbaa665bcb4d7), full [native CI 38441627839](https://github.com/dwijayuda/pskernel/actions/runs/38441627839) **SUCCESS**, including original-vs-C0 checker comparison. These are bounded experimental source differentials with synthetic WHNF fixtures, **not** complete Phase D/E, real checked inductive-recursive conformance or formal soundness evidence. Next: coherent K/structure/String families and one globally metered closure/resource contract, followed by whole-checker integration without candidate acceptance shortcuts.

## CDE-7 — String-literal projection and recursor majors (2026-10-14)

`Architecture/Demand.lean` now routes both projection and non-K recursor String-literal majors through one `String.ofList` expansion helper. The intermediate syntax is evaluated with the **same** continuation frame and operation transition fuel, not a recursively reset source WHNF call; UTF-8 byte size is checked against the quotation bound *before expansion*. Source `String.ofList` declaration semantics remain environment-dependent; the candidate is observational, not accepting. A synthetic safe alias in tests exposes the intended constructor result to both the source oracle and candidate, including empty/ASCII/UTF-8, β-reduced major and oversized negative cases.

**Full bounded executable qualification:** [`d4fb56e3`](https://github.com/dwijayuda/pskernel/commit/d4fb56e3b453f3a159f8441392642bb4429c3d34), [native CI 38443008075](https://github.com/dwijayuda/pskernel/actions/runs/38443008075) SUCCESS. The run covers native Lean 4.35 compilation, existing and new source differentials, official replay fixtures, negative/semantics/resource checks, microbenchmarks and independent original-checker comparison. This is not genuine String-library checked compatibility, full Phase D/E, or soundness proof. `C0_CDE8_TYPED_ELIMINATION_DESIGN.md` governs the next typed K/structure-eta and global resource work.

## CDE-8A/8B implementation foundations — source authority preserved

`Architecture/Budget.lean` adds monotone bounded expression-node traversal, captured-environment readback and conservative substitution expansion reservation, precharged final application-spine construction, and an opt-in `psKernelC0DemandRunWithBudget` that charges active expression syntax across transitions and sends the *remaining* quota to readback. No second reduction implementation was added; demand transitions still use the established CDE-4/7 dispatcher. It is **not** a full runtime-allocation bound until intermediate primitive, δ, projection and recursor reconstruction are also metered.

`Architecture/Typed.lean` introduces an explicitly non-accepting observation seam: K and structure-eta major conversion call the source's own type inference, WHNF and DefEq-dependent helpers using active environment recursor metadata. Invalid/missing/unsafe input declines and the original checking session retains all judgment authority. `Architecture/Work.lean` exposes both operations through validated transaction previews. Tests cover low quotas, nested/repeated captures, binder fidelity, typed major inference constraints and rejection of ill-typed applications.

**Status:** sources pushed; use the completed native CI for the latest *executable* source to qualify this bounded milestone. These foundations are not Phase C/D/E exit. Complete intermediate work accounting, real checked K/eta positive/negative families and unified accepting-kernel refinement before promoting candidate results.

**CDE-8 executable qualification update (2026-10-14):** The latest bounded implementation [`d5a179dc`](https://github.com/dwijayuda/pskernel/commit/d5a179dc08cd361f70a5d34001d1eea4cc99e736) has **full native [CI 38448498595](https://github.com/dwijayuda/pskernel/actions/runs/38448498595) SUCCESS**, including Lean 4.35 compilation, official source/reject fixtures, the mandatory bounded-resource and K/eta observation regressions, negative/resource/migration checks, microbenchmarks and independently rebuilt original checker comparison. The scope is **candidate work-budget foundation and source-typed observation only**; globally complete allocation metering, positive real-checked K/eta coverage, Phase C/D/E exits, full Phase B acceptance and formal soundness remain outstanding. Documentation commits after `d5a179dc` do not represent new executable qualification.

## CDE-8A.2 — whole demand-state work footprint (2026-10-14)

`Budget.lean` now charges the live closure environment, delayed argument environments and retained parent continuation frames at every transition using one shared finite-depth work quota. It additionally charges UTF-8 String literal storage and pre-reserves conservative `String.ofList` expansion work before the existing reduction dispatcher materializes it. Final quotation receives the remaining quota. Negative regressions cover hidden captures, saved frames, string bytes, and source-authoritative decline. The implementation is opt-in, not a new accepting kernel, and the cost units are conservative syntactic-work units rather than proved heap bytes. Latest code `57cbdd4e`; native qualification run [38452517448](https://github.com/dwijayuda/pskernel/actions/runs/38452517448) must finish before claiming the full gate. Remaining: meter *all* intermediate rewrites under a stated cost model, validate large checked workloads, then typed K/eta and trusted integration.

## CDE-8A.3 — source-rule rewrite preflight (2026-10-14)

The opt-in metered candidate now reserves budget before source `δ` definition body reconstruction and selected non-K recursor RHS instantiation. A missing constructor rule is a neutral candidate case, never logical rejection or resource-exhausted by assumption. Tests cover positive/small-budget and negative/unmatched rule outcomes. Corrected source [`d76e2cc4`](https://github.com/dwijayuda/pskernel/commit/d76e2cc4d5d2a0b5f107f37847c75e280c15c060), full native [CI 38453561566](https://github.com/dwijayuda/pskernel/actions/runs/38453561566) must be examined before declaring this bounded slice qualified. Internal source-rule temporary allocations and typed K/eta semantics are not globally metered or independently accepting.

**CDE-8A.3 qualification update (2026-10-14):** Executable commit [`d76e2cc4`](https://github.com/dwijayuda/pskernel/commit/d76e2cc4d5d2a0b5f107f37847c75e280c15c060) received **full native [CI 38453561566](https://github.com/dwijayuda/pskernel/actions/runs/38453561566) SUCCESS**. The run qualified native Lean 4.35 compilation, official positive/negative replay fixtures, CDE-0–8 candidate/source regressions (including delta-body/recursor-RHS preflight and neutral missing-rule cases), negative/resource/semantics and scratch-store checks, performance microbenchmarks and independent original-C0 checker comparison. The latest code is therefore qualified for this **bounded candidate-work-preflight slice**, not the full CDE-8A resource exit, a soundness/refinement proof, or trusted kernel replacement. Full C/D/E, B, F and G exits remain open; the original source checker remains the only accepting authority.

## CDE-8A.4 — candidate intermediate-rewrite syntactic-work coverage

The opt-in `Architecture/Budget.lean` runner now debits **one operation
quota** for active syntax, captured environments, saved continuation frames,
identifier/universe/numeral/String payloads, δ and ordinary iota source-body
universe substitution, application reconstruction, metered intermediate
quotation and every newly returned machine state. Primitive Nat numerical
work—including inner primitives beneath saved Nat frames—has preflight
allowances; recursor/Quot blocked resumes share the same saved-readback
charges as normal halted frames. Deep names debit before recursion.
Final readback uses only remaining work quota.

**Audit:** [C0_INTERMEDIATE_REWRITE_RESOURCE_AUDIT.md](C0_INTERMEDIATE_REWRITE_RESOURCE_AUDIT.md).
Executable `bf95088c`, [native CI 38459330291](https://github.com/dwijayuda/pskernel/actions/runs/38459330291).
This covers the declared *candidate syntactic-work* reduction families; it
does **not** prove a precise Lean runtime heap/CPU bound or complete phase
C/D/E. Source WHNF and checked admission remain exclusively authoritative.

## CDE-8B/8C — checked inductive/quotient and typed-observation integration

The checked architecture transaction now dispatches *all* source declaration
families (ordinary/mutual/nested inductives, Eq-dependent Quot and ordinary
declarations) and exposes validated, source-authoritative WHNF, infer, DefEq,
isProp and **full check** operations. Only full source checking certifies a
term; inference-only success is not an admission verdict. Successful source
admission replaces the session to invalidate caches, preserving the
explicit reduction policy. The candidate evaluator remains opt-in.

Real source-admitted K/structure-eta, dependent indexed Eq K, Quot
initialization and typed Quot.lift fixtures now demonstrate positive and
negative typed semantics. The source-justified K/eta major is allowed into
the *same* metered experimental demand machine, passing only quota remaining
after the wrapper charge. Synthetic recursor metadata does not grant an
admission. See
[C0_TYPED_ACCEPTING_PIPELINE_CHECKPOINT.md](C0_TYPED_ACCEPTING_PIPELINE_CHECKPOINT.md).

**Evidence:** native CI
[38462459034](https://github.com/dwijayuda/pskernel/actions/runs/38462459034),
[38464230358](https://github.com/dwijayuda/pskernel/actions/runs/38464230358),
[38464668623](https://github.com/dwijayuda/pskernel/actions/runs/38464668623),
and [38465192514](https://github.com/dwijayuda/pskernel/actions/runs/38465192514)
passed bounded checkpoints. Later `e49e14e8` must pass
[CI 38465553974](https://github.com/dwijayuda/pskernel/actions/runs/38465553974)
before qualification is extended to policy preservation.

**Still required for C/D/E:** a completely source-equivalent *independent*
typed evaluator and chosen representation, semantics/resource/error
refinement, one accepting WHNF/DefEq/inference/admission implementation and
whole-workload qualification. This work does not waive B/F/G exit gates.

**Latest qualified bounded CDE-8B/8C checkpoint:** [`e49e14e8`](https://github.com/dwijayuda/pskernel/commit/e49e14e8820ecf77a861e97ddba239778dd432a5), full [native CI 38465553974](https://github.com/dwijayuda/pskernel/actions/runs/38465553974) **SUCCESS**, including the latest full-check `Quot.lift` negative tests and reduction-policy-preserving checked admission. This supersedes earlier pending verification notes. Source checker authority remains exclusive; full independent accepting implementation, compatibility and formal refinement still open.

## CDE-9 — proof-carrying canonical representation, stable checked-work and closed checked publication

The next Phase C/E architecture milestone introduces Lean *proof-carrying*
immutable canonical replay validation, owner-bound decoded term roots and
exact source-syntax cross-store transfers. A certified work transaction keeps
the same validated scratch store while the source-only checker state changes;
WHNF, infer, DefEq, full Check, isProp and typed candidate previews no longer
need to replay the whole immutable index each time. Any staging or admission
change is independently recertified.

Syntax-only promotion remains distinct from **closed checked publication**,
which first validates all selected roots, excludes FVars/MVars and undeclared
universe parameters and then independently FULL source-checks every root
before returning an all-or-nothing immutable result. Source infer-only and
candidate WHNF are never substituted for `Check`. Owner/raw Nat handles do
not cross stores by pointer/number reinterpretation. See
[C0_CERTIFIED_STORE_AND_CHECKED_PUBLICATION.md](C0_CERTIFIED_STORE_AND_CHECKED_PUBLICATION.md).

Initial implementation [`8bd68a06`](https://github.com/dwijayuda/pskernel/commit/8bd68a06f6f697814ddaca1a236c365ea94bf7d3) passed [CI 38472302759](https://github.com/dwijayuda/pskernel/actions/runs/38472302759); expanded negative/transfer/closed-check source `76fd5f88` requires [CI 38472570733](https://github.com/dwijayuda/pskernel/actions/runs/38472570733) before full bounded qualification. The mathematical StoreWF theorem, exact equality soundness, independent optimized accepting kernel and B/F/G exits remain OPEN.

## CDE-9B — source-check proof receipts and measured replay reduction

Checked root publication is now a proof-carrying **source computation record**:
`PsKernelC0SourceCheckedRoot` stores owner-bound root syntax, active checking
context, pre-state, fuel, reported type, post-state and an actual Lean equality
proof that the *full* source checker returned that result. Every selected
root undergoes no-FVar/no-MVar, allowed-level and full source checking; the
batch returns no partial result on error. This must not be described as an
independent optimized checker or a proof that source checking is sound.

The native [certified-work microbenchmark](https://github.com/dwijayuda/pskernel/actions/runs/38473185917)
reported 270ms for 36 identical source WHNF/DefEq queries with whole-store
replay versus under 1ms timing resolution with reusable validated-work
proof on a 101-node DAG. This is **validation overhead only**, not
a whole-workload competition with Lean/con-leche/con-ron. The newer checked
receipt source `2d55fd03` is under [CI 38473598945](https://github.com/dwijayuda/pskernel/actions/runs/38473598945);
do not mark it green until the entire workflow succeeds.

**Qualified CDE-9B checked-root receipts:** [`2d55fd03`](https://github.com/dwijayuda/pskernel/commit/2d55fd039a2c9ae4d51586c640988b3ae23a2124) passed full [native CI 38473598945](https://github.com/dwijayuda/pskernel/actions/runs/38473598945). Per-root Lean equality witnesses record actual full source checker success for exact owner-bound syntax under a specific context, state and fuel; the all-or-nothing publication gate enforces closure/universe validation. Both one-root and multi-root positive cases and mixed invalid cases are qualified. This strengthens **checked-result provenance**, not the source checker's independent soundness. Full mathematical StoreWF and executable-resource refinement, independent accepting WHNF/DefEq/inference, whole Init/Std/Mathlib, full-workload benchmark parity and metatheory remain required.

## CDE-10 — exact source assumption manifests and amortized admission audit

The audited native source-history profile is extended beyond ordinary
axiom-name allowlists to **exact approved axiom declarations** (name,
complete proposition syntax and binder metadata, universe parameters and
unsafe classification). Separate explicit capabilities are required for
`Quot` bootstrap, unsafe axioms/definitions/opaques/inductives and partial
definitions. Source `Eq` checking by itself does not imply approval of the
Quot trusted foundation.

The complete immutable ledger carries Lean membership proofs. Per-source
declaration admission adds only the new events to the previously approved
proof, avoiding O(n²) whole-history replay; source judgments and staging
transport the existing audit proof along exact environment ownership.
Re-auditing an *explicitly changed policy* still checks the entire history.
See [C0_TRUSTED_FOUNDATION_AUDIT.md](C0_TRUSTED_FOUNDATION_AUDIT.md).

**Qualified:** [`e6900e27`](https://github.com/dwijayuda/pskernel/commit/e6900e2770437b6210ae19862adc7e6c6ec971dc), [native CI 38484702307](https://github.com/dwijayuda/pskernel/actions/runs/38484702307) SUCCESS, plus full green incremental and capability source runs. Later direct-membership/no-trust proof source `6979d7e9` awaits [CI 38485235073](https://github.com/dwijayuda/pskernel/actions/runs/38485235073). This does not finish the independent optimized accepting checker, full Lean Init/Std/Mathlib, real-workload performance or soundness refinement.

## CDE-10B — approved exact axiom signatures and incremental source-history proofs

The checked-environment history is now audited against *exact*
`PsKernelAxiomInfo` signatures, not names. Quot initialization and every
unsafe/partial declaration family have separately reviewed capabilities.
Lean proofs guarantee all historically source-admitted signatures and
capabilities are authorized. Empty permission lists prove those histories
contain none of the corresponding admissions.

Steady-state admissions extend permission proofs by checking only the
new source-admitted request; unchanged-environment source WHNF/inference/
checking/DefEq and syntax staging transport existing proofs through precise
Lean ownership equality. Only explicit policy modifications reconstruct
and re-audit the full immutable history.

**Full native qualification:** [`572c99a7`](https://github.com/dwijayuda/pskernel/commit/572c99a78834bc1219fc462046b023fad1b762f5),
[CI 38485620934](https://github.com/dwijayuda/pskernel/actions/runs/38485620934)
**SUCCESS**. The matched audit microbenchmark used 96 safe declarations and
112 identical source WHNF queries: proof transport 1ms, whole-history
re-audit per query 3ms. This is narrow validation-overhead evidence, not
a full-workload performance claim. See
[C0_TRUSTED_FOUNDATION_AUDIT.md](C0_TRUSTED_FOUNDATION_AUDIT.md).

**Beyond this bounded assurance slice:** finish mathematical and operational
refinement of the complete optimized checker, full Lean library replay,
resource semantics, matched whole-workload benchmarks and soundness/
trusted-foundation metatheory. Do not promote the candidate evaluator's
observations into accepting judgments merely because audit proofs hold.

## Milestone order and current first slice

1. Freeze existing B acceptance evidence and the counterexample (done).
2. **C/D foundation:** implement a separately compiled candidate evaluator using explicit control closure, delayed environment and argument stack. Initially handle only syntactic β/ζ/metadata and neutral heads, not delta/recursors. No trusted emission.
3. **C/D differential gate:** compare that candidate against source-owned WHNF on closed and appropriately scoped terms, including negative resource and binder cases. Keep source authority.
4. Extend coherent type/recursor/equality families with controlled ablations, then implement E end-to-end.
5. Return to Phase B and complete full-library conformance before qualifying performance or formal assurance.

**Current status:** architecture first approved; C–E implementation is ongoing, none of C–E may be declared complete on the basis of this plan or its initial candidate engine.
