# PSC0-SH/1 implementation and migration plan

Status: proposed sequence; no compiler, host or kernel implementation is changed by this research branch. Baseline and scope are defined in [README.md](README.md). Language requirements are in [SPEC.md](SPEC.md).

## 1. Execute two coordinated tracks

The language track owns source capability design, portable normalization, compiler preparation APIs, source migration and generated-compiler evidence. The existing native-provider track owns kernel conversion, provider resource handling and native checked acceptance. Reuse accepted work from that track; do not overwrite it or import an unverified provider merely to make a language milestone look complete.

At inspected native commit `b109be0075630dd17b791e3b0c5fcad016df53e8`, bounded provider checks passed but the full compiler workflow failed on a reduction budget. Its 12-package baseline lock, scoped CI, explicit workspaces and Lake caching already address part of the iteration problem.[NATIVE][RUN][NATIVELOCK][NATIVECHECK]

Language implementation and small generated fixtures can proceed while that issue is resolved. A failed full-corpus acceptance must continue to block a claim that the native checked self-host milestone has passed.

## 2. Ordered implementation units

### M0 — preserve and make the baseline recoverable

**Work**

- Keep the original October 3 record and source hashes immutable.
- Reconcile the copied-package workspace issue using the existing integration work. Do not indiscriminately install/build every copied backend; the copied Wasm package expects an interface package absent from PSC0.
- Reproduce the original compiler-only lane in a controlled CI environment and record the exact current host/toolchain/source identities.
- Preserve a recoverable seed outside mutable dist, or publish an immutable CI artifact retrievable by digest. Record its parent, compiler bytes, source closure, prelude, TS/Node/Lean versions, options and evidence level.
- Keep kernel/provider qualification separate from this compiler-only reproduction.

**Acceptance**

A fresh environment can obtain or rebuild the pinned seed and verify its bytes. Cleaning the ordinary work directory does not destroy the only recovery path. Do not relabel historical source equality as a new build.

**Why first**

`build:auto` currently chooses by JS-file existence and `clean` deletes dist. A pleasant authoring language is unhelpful if one broken update strands the compiler.[AUTO][CLEAN]

### M1 — establish fast, source-aware development

**Files/API area**

`Compiler/Api.lean`, the generated compiler driver, build-current/generation orchestration, and a small host-side iteration wrapper. Do not edit kernel implementation.

**Work**

1. Add an explicit preparation seam in the old accepted source subset: start, step one ordered module, finish. Preserve both the environment and ordered declaration accumulator from the current aggregate implementation.[API]
2. Let the existing aggregate API delegate to that seam so old callers retain behavior.
3. Add a resident generated-compiler session for one exact executing compiler instance. Cache parsing and preparation conservatively.
4. Distinguish building a candidate from testing that candidate. A cached old compiler preparing changed compiler source is a valid build stage; it is not a test of the newly changed frontend.
5. Make Lean replay optional in the development route while retaining it in comparison/qualification routes. Preserve existing default script behavior until callers are migrated.
6. Deduplicate repeated source and closure checks within one orchestrated run, keyed by the inputs those checks actually inspect.
7. Add stage timings, cache hits/misses and provenance to a development receipt.

**Acceptance**

Cold and warm paths produce the same artifacts and diagnostics for the same inputs. A no-edit run performs no avoidable parse/preparation work. A leaf edit never silently selects stale dist source. A compiler-implementation change creates a new compiler session. Mis-keyed/missing/corrupt cache entries cause recomputation, not acceptance.

This is a new layer above the concurrent branch's `--fast` behavior, not a replacement for its full checked pipeline.

### M2 — implement the minimum recursion capability

**Files/API area**

A small new typed recursion planning/normalization module in `packages/elab`, integrated into `Declaration.lean`, `Context.lean` and `Term.lean`; focused bootstrap/generated tests.

**Work**

- Implement changing-parameter generalization using the algorithm in SPEC.
- Start with direct explicit matches, ordinary non-indexed constructors and Nat successor fields.
- Keep the old recursive-call validator for the normalized representation.
- Add positive and negative cases before migrating compiler source.
- Expose deterministic normalized-source output and origin mapping where source emission needs it.

**Acceptance**

The old seed builds the improved compiler while all its implementation source still uses the old accepted subset. The resulting generated compiler accepts accumulator/fuel-state examples and rejects nondecrease, unrelated children and unsupported dependent cases. Test two state parameters with swapping to catch accidental sequential updates.

The historical negative invariant test is not merely deleted: keep an equivalent old-mode test and add new-mode success plus new semantic failure cases.[TEST][TERM]

### M3 — qualify an improved seed before dogfooding

Run the current-source generation procedure in section 3. Include raw authoring inputs that exercise the new normalizer, not only pre-normalized generated workspaces. Keep canonical-source fixed-point evidence as a separate lane.

Promote a versioned seed only with recorded claims. If full provider acceptance is pending, label the candidate's compiler/runtime evidence accurately; do not mint a checked seed claim.

This stage breaks the bootstrap cycle: the compiler learns the feature while written in the old subset, then its source can begin using it.

### M4 — migrate source by feature family

**First family: simple total collection/index workers.** Start with a small sample of list traversal, reverse/append/take/zip wrappers and index scans. Reuse existing foundation helpers. Preserve public names/signatures and avoid an accompanying data-structure redesign.[LIST]

**Second family: fuel and explicit state.** Migrate workers returning functions of context, indices, accumulators or result state. Preserve exhaustion behavior, first-error order and state-on-error policy.

**Third family: compiler internals.** Apply the same established conversion to declaration preparation, elaboration, erasure and emission helpers. Change the normalizer's own implementation only after its capability is seed-qualified.

Choose low-impact representatives first, then expand one verified family. Do not rewrite all high-fan-in modules together. In the measured import graph, Foundation.Name has 42 transitive importers, Core.Expr 31 and Environment.Basic 21; even small public changes can be broad. The ordered environment can make semantic invalidation broader still.

For each family, produce a dry-run inventory with source location, detected capability, proposed conversion, old guard coverage and unsupported cases. An AST-aware migration helper may apply proven mechanical forms; ambiguous cases stay unchanged for review. Regex replacement cannot classify binders or termination.

**Acceptance per family**

Changed source is accepted by the promoted generated compiler; relevant semantic and boundary fixtures pass; expected structural differences are reviewed; existing loopification is preserved or its change is explained. Retire only the shape guards covered by replacement capability tests. Commit each family separately so rollback is a normal revert.

### M5 — add conveniences in measured priority order

1. Common equation/lambda-wrapped declaration and harmless-let normalization.
2. Expected-type lambda domains with explicit fallback diagnostics.
3. Nested constructor patterns lowered to flat decision trees.
4. Except-only do if repeated explicit error plumbing remains a significant authoring cost.

These are independent improvements. Do not delay useful accumulator migration until a general equation compiler, all nested patterns or full monads are complete. Do not add unneeded source class/instance/deriving support.

Use actual remaining workaround counts to choose between items 2 and 3. A parser change affects a large part of this closure; it deserves a separate seed qualification rather than being mixed into a data-structure cleanup.

### M6 — strengthen the portable runtime contract

Add the small original-IR checker described in SPEC, initially reporting the old corpus. Close remaining runtime unknowns and explicit primitive/representation gaps before making stricter enforcement the default for promoted source.

Preserve the original TS path. Do not make the copied direct JS/Rust/Wasm backends prerequisites. Integrate a new target only after choosing a coherent IR interface, wiring its build/driver dependencies, and demonstrating the scalar/ADT/function contract and generated self-host evidence for that target.

This work can overlap M2–M5 when its changes are isolated and separately qualified.

### M7 — optionally make .ps authoritative

Consider this only after the generated PSC compiler can parse ordinary authored `.ps`, normalize the enabled SH/1 capabilities, check/compile its full source, produce stable successive generations and support useful diagnostics.

Do one controlled extension/authority migration with source correspondence checks. Do not simultaneously rename declarations, switch punctuation, change runtime representations and replace the provider. Keeping `.lean` as the authoring spelling is a valid outcome if it gives the best workflow; self-hosting depends on which compiler consumes it, not the filename extension.

## 3. Correct generation and promotion procedure

Let A be the exact source tree containing the improved compiler, written in the old subset. Let S0 be the pinned old compiler.

1. Build C1 = S0(A).
2. Build C2 = C1(A), actually reading the same current A.
3. Build C3 = C2(A), again from that exact A.
4. Compare the required canonical source, admissions, TS, and JS artifacts for the current generations, with all toolchains/configurations fixed.
5. Execute the raw new-authoring capability corpus using the generated C2 and C3. Record the normalized source, results and provider acceptance separately.

C1 can legitimately differ from C2 when the compiler's emitter or normalization behavior changes across the seed boundary. The historical lane retains its original comparisons; the new lane must identify precisely which successive current-generation artifacts are expected to be equal. Do not demand old-seed byte equality for every compiler improvement.

After promotion, let B be compiler source migrated to ordinary SH/1. Repeat the same procedure using the promoted seed, and make each generated compiler consume B's **raw authored source**. If every generation only sees a pre-normalized workspace, the fixed point does not exercise the authoring normalizer.

A syntax-only translation route is insufficient here. The shared preparation/normalization seam must support ordinary authoring input and supply deterministic canonical output in its ordered environment. Source emission and compilation must use the same lowering implementation.

Required receipt fields:

- Exact source closure and module order, including the new module count.
- Parent and executing compiler digests.
- Language/capability set and normalizer identity.
- Canonical source and ordered admissions digests.
- Generated TS/JS digests and runtime/toolchain options.
- Prelude/environment identity.
- Provider executable/runtime/options/resource policy and actual result.
- Evidence level: preparation, generated execution, compiler fixed point, or kernel-checked fixed point.

Missing evidence is a pending claim, not a reason to rename admission-ready output as checked.

## 4. The efficient development workflow

The following workflow names describe functionality to implement. They are not commands already installed by this research branch.

| Workflow | When | Work and claim |
| --- | --- | --- |
| Edit feedback | Every edit | Real parser/profile checks, changed preparation suffix, focused diagnostics; no fixed-point claim |
| Candidate build/test | Compiler behavior change | Build from current source with the pinned seed, load the resulting candidate, run relevant capability/runtime cases |
| Current-source self-application | Feature or source-family milestone | Successive current-source generations and equality, with exact provenance |
| Checked qualification | Seed promotion and relevant provider/semantic changes | Required admissions accepted by selected provider plus source/generation evidence |
| Historical reproduction | Bootstrap changes or explicit recovery audit | Reproduce preserved old source/seed contract independently |

On main today, `npm run build:psc` is the closest existing current-source build, and `npm run fixed-point` is the coarse full-chain route. The former is not candidate self-application; the latter is expensive to repeat per edit.[BUILD][PKG]

### Cache identities and safe invalidation

| Cache/result | Minimum identity and invalidation |
| --- | --- |
| Parsed source | Exact bytes, source kind/path where relevant, executing parser implementation, options and diagnostic origins |
| Normalized/prepared module | Parsed input, executing normalizer/elaborator, full incoming environment/prelude, ordered declaration accumulator/provenance, resolution configuration and limits |
| In-memory state | Exact compiler import/session; do not share symbol-tagged values across independently imported generated modules |
| Emitted TS bundle | Entire prepared closure, runtime/prelude, emitter/options/target identity; retain aggregate emission initially |
| Compiled JS | TS bytes, TypeScript version, tsconfig/options, relevant package/runtime resolution |
| Provider result | Ordered canonical admission bytes, starting environment/prelude, provider executable plus runtime/toolchain closure, semantic options and resource policy |
| Qualification receipt | All required artifacts and stage results; a receipt is not independently granted provider authority |

Start conservatively. Parse independent modules in parallel where useful, but prepare the ordered semantic suffix sequentially until the complete state can be safely reused. Later fine-grained dependency tracking may reduce that suffix; include bodies used by definitional reduction, instance/name resolution, and negative lookup dependencies, not just exported signatures.

Generated TS creates fresh Symbol tags/brands and an import-local trampoline WeakMap. Even identical compiler bytes do not make two import instances' object graphs interchangeable.[MOD] Persistent caches should store a supported canonical serialization and reconstruct it, or cache source/artifacts only until such a format is defined.

Missing/corrupt cache entries require recomputation. Timeout/cancellation/budget exhaustion are operational outcomes, not permanent proof-invalid results. An editable acceptance-cache JSON cannot manufacture a checked session handle. If a provider exposes no resumable or attestable acceptance protocol, reuse may speed preliminary work but fresh provider checking remains necessary for qualification.

## 5. Measurement plan

First establish phase timings on one pinned environment: load/parse, normalize, elaborate, admission encode, provider accept, erase, TS emit, tsc, generation compare. Record wall time, peak memory where available, source/module/declaration counts and cache counters.

Measure these representative scenarios before and after an iteration change:

- Cold build from the recoverable seed.
- Warm no-change repeat.
- Small late/leaf implementation edit.
- Shared core or prelude change.
- Compiler implementation/normalizer change.
- Provider-only change.
- One full current-source qualification.

A warm no-change source loop should do zero unnecessary parse/elaboration work. A leaf source edit should reuse its valid prefix. A parser/compiler implementation change must invalidate affected sessions even if source filenames did not change. These are testable workflow properties; no speed multiplier is asserted without timings.

For generated runtime, measure representative lexer/parser scans, list/index helpers and a real compiler corpus. Inspect whether existing count/tail-loop paths are retained. Profile a demonstrated hot path before extending generic loopification or replacing collections. Current array push/set copy; changing lists to arrays can worsen repeated accumulation.[EXPR][MOD]

Run full performance comparisons at milestones, not every keystroke. Set time budgets after the baseline is measured; do not invent a tenfold improvement target from source inspection.

## 6. Risk controls and stop conditions

| Risk | Concrete control |
| --- | --- |
| New source stranded on old seed | Feature implementation stays old-compatible; seed qualification precedes corpus migration |
| Semantically wrong accumulator lowering | Typed dependency/provenance analysis; swapping/multiple-state tests; reference behavior |
| Pattern lowering changes first match | Factored decision tree; overlap/default/order fixtures |
| “Checked” only means encodable | Separate preparation, actual provider acceptance and receipt integrity |
| Fast run silently uses stale compiler/source | Executing compiler and current closure digests in every receipt |
| Cache ignores semantic state | Full environment plus declaration accumulator; conservative suffix rebuild |
| Performance regresses behind nicer syntax | Preserve optimization paths; measure allocations/time on concrete workloads |
| New packages force a compiler rewrite | Integrate one coherent backend interface at a time |
| Parallel work overwrites provider changes | Separate branches and reviewed commit integration; never force-update native work |
| Migration loses the known-good compiler | Immutable recoverable seed and source-family rollback checkpoints |

Stop promotion, not all development, when required evidence fails. Preserve diagnostics and the failing corpus; fix the concrete issue or leave the associated claim pending. Do not respond by widening allowlists, replacing a semantic gate with a textual marker, or treating a larger fuel setting as proof of correctness.

## 7. Completion criteria

SH/1 is successfully adopted when the chosen compiler source families use ordinary structural recursion without handwritten state-currying adapters, the generated compiler consumes that authored source itself, capability-based checks replace the relevant spelling guards, current-generation artifacts meet their declared equality contracts, and the advertised provider qualification has actually passed.

The daily path must build and test current edits without repeating an unchanged full bootstrap. The historical 55-module point remains reproducible, later seeds have their own honest closure counts, and optional targets consume the same defined runtime contract instead of imposing new source dialects.

[TERM]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/elab/src/Ps/Elab/Term.lean#L2706-L2824
[LIST]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/foundation/src/Ps/Foundation/List.lean
[API]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/compiler/src/Ps/Compiler/Api.lean
[EXPR]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/backend-ts/src/Ps/BackendTs/Expr.lean
[MOD]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/packages/backend-ts/src/Ps/BackendTs/Module.lean
[BUILD]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/scripts/build-current.mjs
[PKG]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/package.json
[AUTO]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/scripts/build-auto.mjs
[CLEAN]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/scripts/clean.mjs
[NATIVE]: https://github.com/dwijayuda/pskernel/tree/b109be0075630dd17b791e3b0c5fcad016df53e8/psc0
[RUN]: https://github.com/dwijayuda/pskernel/actions/runs/37823400738
[TEST]: https://github.com/dwijayuda/pskernel/blob/37f63c39d4a07189938046c64152bba25d789450/psc0/test/BootstrapTests.lean
[NATIVECHECK]: https://github.com/dwijayuda/pskernel/blob/b109be0075630dd17b791e3b0c5fcad016df53e8/psc0/scripts/checked-selfhost.mjs
[NATIVELOCK]: https://github.com/dwijayuda/pskernel/blob/b109be0075630dd17b791e3b0c5fcad016df53e8/psc0/scripts/selfhost-baseline.mjs
