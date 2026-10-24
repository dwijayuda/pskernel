# T05 private constructor helpers and paged-storage proof batch

## Activation boundary

The preceding ordinary-header narrow candidate passed at exact source
`f5d97bafbd48adde29101ed44f45288ae53b9c87`, run `40089243726`, attempt 1.
All three jobs and all 498 artifact files were independently verified. Each
complete route executed exactly 1,992 header assertions and retained the 1,884
cache matrix and other required controls. Read the dedicated header qualification
report and its source-bound evidence for the complete scoped result.

This constructor-helper candidate is newly activated and has **no test result
yet at creation**. It must obtain its own native and two-route receipts. The
preceding header source does not qualify these changed files. Integration
remains at the separately qualified T01F source
`0d9f062846d109c362210d441df5fd407ca2cdd7`.

The batch adds private parameter-alignment and result-shape helpers. It does
not implement constructor fields, positivity, universe bounds, recursor
generation, complete ordinary admission, or publication. The public ordinary
dispatcher and fallback are unchanged. T05 remains OPEN. B/D remain OPEN and
C remains FAIL; the exact earlier T01F qualification is recorded separately.

## Production scope

All production paths below are relative to `src/Ps/KernelCore/`.

### `API/DagOrdinaryConstructorParams.lean`

`psKernelExprV2OrdinaryOpenConstructorParamsWorker` aligns a constructor's
syntactic forall prefix with the existing header binders in the complete
parameter context and owning state. It invokes the supplied full-owner DefEq
callback with predecessor fuel, the constructor domain on the left, and the
header parameter type on the right. Callback decline, error, and false stop
immediately with the original outcome or diagnostic.

On true, the worker uses the callback-returned owner, constructs an fvar with
the existing parameter's internal name, and instantiates the body in that
arena. It threads every returned semantic cache, declaration reference, and
freshness field. Only the arena changes during this substitution. It allocates
no new local or fresh internal name, and it performs no preliminary WHNF,
metadata peeling, or annotation consumption.

Zero worker fuel precedes even an empty parameter list or invalid root.
Successor fuel with no parameters returns the complete original owner and ID
without lookup. The public `With` wrapper adds one; `WithFuel` selects the
actual `psKernelExprV2TryDefEqStateWithFuel` callback. These are private helpers;
their names do not imply a new public admission route.

### `API/DagOrdinaryConstructorResult.lean`

Six helpers implement the original structural result checks:

| Helper suffix | Responsibility |
| --- | --- |
| `ConsumeResultParams` | Match existing internal fvar names and retain the untouched suffix |
| `InductiveAppIndices` | Require the exact target, ordered universe list, parameter prefix and index arity |
| `ContainsConstWithFuel` | Traverse the original node order with a separate structural bound |
| `ContainsConstOnCanonical` | Obtain that bound from canonical depth metadata |
| `IndicesContainTarget` | Stop at the first occurrence or lookup failure |
| `ValidateConstructorResult` | Preserve shape-error-before-index-scan ordering and exact original errors |

There is no WHNF or DefEq in result-shape matching. Successful selectors return
the original ordered index IDs, including repetitions. Descriptor user names,
binder information and type IDs do not replace the internal-name comparison.
A projection's type name is checked before its receiver. Metadata and binder
names are handled exactly as in the original occurrence predicate.

The private `WithFuel` occurrence bound is independent of checker fuel.
`ContainsConstWithFuel 0` fails before lookup with
`PSKERNEL_V2_ORDINARY_CONTAINS_CONST_FUEL`; the canonical wrapper relies on
validated depth. Poisoned-owner or invalid-ID test probes do not establish the
canonical precondition.

The original V1 references are frozen at source `0d9f0628…`:

- `Admission/Inductive/Ordinary/Constructor.lean`, Git blob
  `56a70b8ac94283694bf375a8d5c8e7adfd3859b7`, SHA256
  `8bd99c203b50315d0e58ba4aebb1cebec7d0331db330163fef341bfe713d9145`.
- `Admission/Inductive/Common/Occurrence.lean`, Git blob
  `a8b911d20a603b46edcc63a0bf000c1bacec5341`.

Keep recursive applications compatible with PSC1's declared arity. A worker
whose single declared parameter returns a function must bind the recursive
partial application before applying the remaining arguments. The result-prefix
consumer uses this binding inside its original successful branch. The earlier
header repair supplies the direct compiler evidence for this restriction.

`SelfHost.lean` adds both imports so the real helpers appear in each authentic
complete route. Lake adds their production roots. No other existing production
body is changed by this batch.

## Universal proof gates

The native-only proof additions require **50 new reports**:

| Module | Reports | Scope |
| --- | ---: | --- |
| `PsKernelOrdinaryConstructorParamsProofs` | 17 | Arbitrary callback, owner, fuel, error, identity and substitution-step equations |
| `PsKernelOrdinaryConstructorResultProofs` | 16 | Structural result and occurrence correspondence plus exact error/order equations |
| `PsKernelExprV2PagedModelProofs` | 17 | Physical paged layout, lookup/append framing and one local metadata composition |

The result correspondence statements assume the explicit existing `ArenaModel`
and valid input IDs. They derive the actual selector/consumer witnesses and
decoded V1 results; they do not assume the desired helper result. The storage
proofs establish physical `Layout` facts, including rollover and preservation
of old IDs, from structural page-size conditions. Their local app-metadata
composition uses the original child-correspondence hypotheses.

The existing **172 reports** remain required. The unchanged eight
`PsKernelExprV2MetadataProofs` reports are additionally audited as imported
proof dependencies, yielding **230 total = 50 new + 180 retained**. All reports
must be exact, ordered, unique, and limited to the permitted standard axioms.
No axiom, sorry/admit, native_decide, compiler execution, or Boolean result is
accepted as a universal proof.

The workflow builds the native-only existing Occurrence and unchanged Metadata
`.olean` dependencies before checking the new files. The library declarations
remain outside the portable production closure. A pinned-API review replaced
the unsupported `by_contra` tactic spelling with `Decidable.by_contra` in one
storage proof body, preserving all 19 statements and 17 reports. Actual Lean
checking remains mandatory.

The full replay-validation-to-`ArenaModel` and actual decoder correspondence
are still open. Any later draft under `t05-model-bridge` is a separate batch;
it is not registered, counted, or qualified here.

## Native and generated regression inventories

Native parameter regression requires **284 assertions**:

| Group | Assertions |
| --- | ---: |
| 18 fixtures × 6 fuels × raw/wrapped worker, plus 11 required direct positives | 227 |
| Complete owner propagation and three ordered callbacks | 21 |
| Fuel/lookup/shape boundaries | 28 |
| Deliberately broken callback-owner faults | 8 |

The direct fixtures prepare an authentic V1 header session and an actual DAG
header owner. The V1 constructor prefix is copied from the frozen original,
with only its private declaration and recursive name changed. Both interfaces
are compared at fuels 0, 1, 2, 3, 8 and 4096. Positive rows must return the new
worker's direct success and preserve local/freshness history. These are prefix
successes; some bodies intentionally exercise substitution without claiming a
complete, well-typed constructor declaration.

Native protocol controls stamp all five caches, both pair sets, declaration
references, freshness and the arena distinctly. Damaged-owner rows explicitly
violate owner lineage to test propagation of BAD_ROOT/BAD_REFERENCE. No claim
of canonical input or admission success is attached to them. PagedMkFVar's
error branch is presently uninhabited; no fake executable error case is added.

Generated parameter regression requires **268 assertions per route**:
`harness=1`, `direct=227`, `protocol=20`, `boundaries=14`, `faults=6`. It uses the
same direct fixture/fuel table, actual full-owner DefEq, and existing canonical
builders appended to the returned header owner. This keeps the research
importer out of the portable SelfHost closure. Its additional controls have
their own fixed inventory; do not substitute native284 for generated268.

Both native and generated result regressions require **432 assertions**:

| Section | Assertions |
| --- | ---: |
| Constructor-tag control | 1 |
| 46 selector rows × decoded selector, decoded validator and exact original IDs | 138 |
| Direct parameter-prefix consumer | 26 |
| 30 node expressions × two target names × four bound/wrapper checks | 240 |
| Explicit bound and short-circuit probes | 16 |
| Index-list hit/error ordering | 7 |
| Shape mismatch before recursive-index rejection | 4 |

All original **1,992 header assertions**, **1,884 cache assertions**, scalar
hash, DAG, prefix-owner, original generated smoke and invalid-recursor controls
remain required. The two new generated PASS markers also have strict JSON
contracts, exact section counts, and source/run/attempt/route/kernel/harness
bindings in the workflow receipts.

## Qualification and continuation

Use the existing single narrow push workflow; do not introduce another
overlapping trigger or rerun an old source. Native proofs and regressions must
pass before bounded code generation and complete builds. Preserve the added
small structural-module precheck and every prior strict body check. Both the
generated integration route and reconstructed canonical `.ps` route must use
one exact source and attempt. Inspect the actual artifacts, copied source,
complete manifests, bundle bytes, logs, counters and receipts.

All project execution stays on GitHub Actions Linux. Retain exact Lean4.35.0
commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`, TypeScript7.0.2, Node22,
fuel4096, detached runtime with empty PATH and old-space2048MiB. Old-space is
not a hard RSS limit. Do not alter the final mixed-job25-minute cap, route
parallelism2, five paused full qualification work triggers or frozen controls.

After this helper batch passes, continue constructor fields, positivity,
recursive-argument indices and universe bounds. Temporary recursive-argument
locals must restore the post-field owner while retaining appended arena and
freshness history. Closed constructor checks use fresh independent owners.
Private provisional environment/reference invariants, elimination/K policy,
motive/minor/IH construction, recursor rules, generated-type/rule checking,
owned admission results and private atomic publication remain outstanding.
