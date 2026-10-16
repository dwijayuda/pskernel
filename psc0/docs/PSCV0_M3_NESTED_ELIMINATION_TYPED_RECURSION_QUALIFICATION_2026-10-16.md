# PSCV0 M3 selected nested elimination and typed recursion qualification

## Accepted identity

Accepted compiler/test SHA: `fbbc5271419dde8b183be723f07ff1f75a462013`.
Inspection date: 2026-10-16 UTC. This receipt is committed in a later documentation/feature checkpoint; it records the tested SHA above and does not qualify later compiler changes.

The previous fully accepted compiler/test SHA was `01d762eb02eab1d2f795e5338cb3586cd1d1ace0`. This acceptance includes the accumulated typed well-founded and direct mutual structural recursion changes plus the complete selected nested elimination and Hashable implementation.

Official Lean: **4.35.0**, pinned commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.
Only forward ProofScript specification: `psc0/PSCV0_LANGUAGE_REFERENCE_v7.2.md`, blob `694115223777599ba28ee175e14bb642b7b6aa4b`.
Approved assumptions remain **propext** and **Quot.sound**.

## Five successful gates at one SHA

| Gate | Run | Result |
| --- | --- | --- |
| Full native Linux | [38976283998](https://github.com/dwijayuda/pskernel/actions/runs/38976283998) | SUCCESS; job 117226865704, all 33 reported steps successful |
| F1 canonical model | [38976284003](https://github.com/dwijayuda/pskernel/actions/runs/38976284003) | SUCCESS |
| F2 logical operations | [38976283981](https://github.com/dwijayuda/pskernel/actions/runs/38976283981) | SUCCESS |
| F3/F4 checked conversions/platform | [38976283973](https://github.com/dwijayuda/pskernel/actions/runs/38976283973) | SUCCESS |
| Focused source/kernel/runtime | [38976283967](https://github.com/dwijayuda/pskernel/actions/runs/38976283967) | SUCCESS; job 117226400579, all 15 reported steps successful |

Each run reports the accepted SHA above. No pending, cancelled, failed or skipped gate is counted as acceptance.

### Retained artifacts

| Artifact | ID | Bytes | GitHub SHA256 digest |
| --- | --- | ---: | --- |
| pscv0-v7-native-fbbc5271419dde8b183be723f07ff1f75a462013 | 12078998869 | 6,706,095 | b942f1330ab9048b3367ad2caee05d98b58cbf4ef6d73c7f85fee2ba32ca492f |
| pscv0-m3-recursive-hash-fbbc5271419dde8b183be723f07ff1f75a462013 | 12078884425 | 1,724,235 | 67199bb88c12e35b8f7ec0d0bc7befdc1fa3deac2ca0aa1e63dfaf8170f88f9e |

Artifacts were present and unexpired when inspected. Their existing workflow retention is 30 days. Source-SHA files, source checks, emitted artifacts and per-target logs are retained by the workflows.

## Qualified shared construction

### Complete visible and nested elimination

One Core elimination plan represents the visible inductive group and the ordered actual List, Option, Array and Prod specializations. Each slot retains its closed type former, common parameters, own index telescope, constructor types, recursor identity and ordered field-to-slot recursion edges. Raw specialization keys and queue order follow pinned Lean; definitionally equal raw expressions are not silently merged.

The bridge consumes the actual retained environment and encodes the original visible inductive group. Fresh official Lean regenerates the public and auxiliary recursors. Complete regenerated telescopes are compared against retained signatures. Virtual slot metadata is never emitted as an invented datatype, recursor or induction hypothesis.

Iota, Match/cases, deriving, checked worker lifting and typed erasure consume this plan. Actual rec_N identity, specialized child type, child indices, capture prefix and exact closed worker equation are checked. Array/Prod typed projections are bound once; Array shares the existing checked List conversion between its field and corresponding hypothesis.

The fixture qualifies deep/repeated slots, all four selected containers, a mutual group with alpha-renamed dependent parameters, an indexed public family with an unindexed auxiliary List, actual source cases and direct-child source recursion. Equal-count stale signatures, missing/duplicate auxiliaries, universe/order errors, wrong worker association and nonuniform raw occurrences have explicit refusals.

### Raw key oracle

The original native M3NestedKey source command reached Lean's default recursion-depth limit during command processing. The accepted fixture independently constructs a Lean.Declaration.inductDecl with the same family and constructors, retaining Id in the aliased List argument. It compares that declaration with decoded canonical admission, requires fresh official-kernel acceptance, and checks all three recursor signature witnesses.

The original canonical admission, one-declaration assertion and distinct raw-versus-definitional key checks remain. This establishes the official-kernel behavior of this declaration. It does not claim that all native source-command postprocessing for this raw-key example succeeds at default depth. Provider options, existing budgets and ceilings were not increased.

### Nested Hashable

All four container policies use actual checked slot hypotheses. List and Array preserve native left-fold order and seed 7; Option preserves its none/some policy; Prod combines left then right. Generic recursive fields use actual parameter dictionaries. No self dictionary, synthetic hypothesis or production partial fallback replaces total elimination.

Seven independent native output functions are checked through direct JS, strict compiled TS, locked Rust, V8 Wasm GC and Wasmtime components:
`m3nestedfold`, `m3nestedhash`, `m3nestedmutualfold`, `m3nestedmutualhash`,
`m3nestedindexedfold`, `m3nestedindexedhash`, and `m3nesteddirect`.

### Typed well-founded recursion

The accepted tree retains explicit typed source headers, a selected measured major, fixed and evolving arguments, polymorphic domains, dependent state/result motives, all-kind entries and real returned-function suffixes. The construction uses actual WellFounded.Nat.fix and checked decreasing proofs. Public equations retain actual fix_eq and checked extensional transport. The definition/body/equation identities and universe closure are independently checked; no temporary recursive axiom or P0 marker supplies total recursion.

All twelve established well-founded runtime outputs pass across all five targets. Existing negative slots cover nondecrease, false measures, unsolved obligations, header/callback ownership and unsupported relation/shape boundaries.

### Direct mutual structural recursion

The accepted group mechanism uses one motive component for each actual source function at its family position, including multiple functions with equal types. It retains actual common captures, function-specific header order, cross-family indices, zero-owned companions at their real universes, real strict-child hypotheses and exact source equations.

All six established structural runtime outputs pass across all five targets. Refusals retain root-match, strict-child, complete peer arity, uniform fixed mapping, motive universe, unsupported nested-field and late-member atomicity boundaries.

## Cross-stage evidence

The focused run executes all ten required source checks and all existing target lanes. Its log records successful fixedpoint assumption/source audits; recursive Hashable/Repr/BEq/DecidableEq; group runtime and source match/cases; typed WF; ordinary mutual P0; group/indexed deriving; direct mutual structural recursion; and complete selected nested elimination/Hashable. Fresh official-kernel signatures/equations precede target execution.

The full native run passed source/Standard qualification, the existing parser and compiler corpus, admitted proof-asset reviews, linked module applications, GC and component formats, the original 1,069-observation runtime workloads, 35 platform probes per profile, repeated component calls/post-return and the original measurement step. Generic Nat/Bool recursion passed at 100,000/50,000 steps. Existing outputs, request counts, checksums, pins and budgets were preserved.

The measurement gate records the original native-reference and checked-compiler samples. This receipt makes no new performance-parity claim or general source-to-target preservation claim. No local Lean, Lake, build or compiler-test execution was used; execution evidence is GitHub Linux CI.

## Repair history and qualification accounting

The typed recursion candidate `62a43dcc1ac9069533e4a48bf54639121cb265fd` passed four gates, but its native run 38973463333 was cancelled by the next push. It was not previously fully accepted.

The nested implementation `7ce2388184f2c29cc49a2b1a367c05191828265a` first needed explicit Lean continuation layout in `78f5f2e09b4a4497ddc179648f3ed3a291544f02`, then initialization of a newly added optional legacy constructor field in `90cc412e2a171fef95af181c62f9e8c3196049d1`. At 90cc412e the logical gates and production compilation passed, but the native source-command oracle failed; its native run was cancelled by the repair push. The accepted fbbc5271 kernel-oracle repair preserves the original semantic assertions and runtime outputs.

Those isolated failures and repairs remain in the handoffs. Acceptance is established by the five current successful runs, not by combining earlier runs.

## Remaining six-exit obligations

M3+B remains OPEN. The weighted engineering estimate is now 67 points out of 100, reported approximately as 65–70%, with a broad 55–75% uncertainty interval.

| Exit | Weight | Accepted contribution | Principal remaining work |
| --- | ---: | ---: | --- |
| Selected data/elimination/deriving | 30 | 21 | Further selected deriving, dependent/match and structural traversal coverage; explicit native limitations |
| Source recursion strategies | 15 | 10 | Flat where/header/capture ownership and typed dependency-component dispatch qualification |
| Total recursion | 20 | 14 | Actual broader WF relations, dependent argument packing, genuine mutual WF and further structural coverage |
| Ordinary P0 | 15 | 13 | Broader mixed-component/local capture and operational matrix |
| P1 | 10 | 1 | Pinned fixedpoint construction/equations require forbidden Classical.choice |
| Integrated acceptance | 10 | 8 | Qualify the remaining selected matrix at exact implementation SHAs |

The weighted estimate is an engineering assessment, not a test-coverage percentage. No unqualified local candidate adds accepted points.

Nested Repr/BEq and the typed local-definition/SCC source layer are separate pending candidates at this receipt. Pinned Lean itself declines nested DecidableEq deriving; that native limitation must stay explicit. Arbitrary containers, function-valued nested fields and constructor-local specialization parameters remain outside the selected accepted nested shape. Default mutual/nested source induction retains the pinned refusal without an explicitly selected supported eliminator. ProofScript mutual grammar remains def/function-only.

P1 remains fail-closed: pinned Lean.Order.fix/CCPO.csup and their equations require Classical.choice. Only propext and Quot.sound are approved. There is no replacement kernel, pskernel-core integration, self-hosting, compiler-source migration, LLVM work, M4/M5 completion claim, branch reset or PR merge.
