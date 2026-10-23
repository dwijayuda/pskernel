# PSC1 development roadmap

Updated 2026-10-24 Asia/Jakarta. [AI_WORK_STATE](../AI_WORK_STATE.md) owns continuation.
Frozen [Practical Core v1](PSC1_PRACTICAL_CORE_V1_CONTRACT.json):14 families/37 criteria.
[Compact evidence](PSC1_SELFHOST_PROFILES_QUALIFICATION_2026-10-23.json) binds the
full [canonical receipt](PSC1_RUST_TS_SELFHOST_QUALIFICATION_2026-10-23.json),
including17 completed actual attempts, preserved failures and immutable artifacts.

## Current remaining queue — DirectJS and DirectWasm

| Order | Work | Acceptance / current evidence |
| --- | --- | --- |
|1|Finish measured DirectJS cache-key and Wasm ordinary-stack defect-class fixes.|e274/40023689471 passes51 all-input prefix proofs, ordinary accumulator/wrapper equivalence, negatives, deep/native/reference/runtime/owned-Wasm tests and both87/98-module grammars. DirectJS53c9b895 lazy-token emitter gate40025082793 pending; actual retained G2 profile40024746671 pending.|
|2|Execute genuine independent DirectJS and DirectWasm G1→G2→G3.|Previous0c/40020523049: both completeG1; JS G2 deadline1800162ms/1862136KiB, Wasm G2 stack123237ms/536280KiB. Neither has G3/fixedpoint. Actual new Wasm request8b01ac30/run40024688133 on proved e274 source is running. Exact source/admission/original+transformed IR/observations/source-byte (owned Wasm binary) fixed points required.|
|3|Qualify latest source across all seven backends, both grammars and real applications.|Preserved PR174 afed7c4b full40015619975 passes37/37, identical-tree merge; later source still needs full CI. Preserve independent Lean4.35 and strict IR/negative/refusal gates.|
|4|Separate performance and reproducibility qualification.|Keep original240s profile and independent clean-build repeatability distinct from1800s correctness. No heap/stack/fuel/checking relaxation; no merge or publication.|

Authoritative continuation: [AI_WORK_STATE](../AI_WORK_STATE.md).
Machine-readable immutable attempt identities, focused gates and current runs:
[Direct target evidence](PSC1_DIRECT_SELFHOST_QUALIFICATION_2026-10-24.json).
Preserve qualified Rust83e18fe1 and TS84e1e16f. Earlier sections below retain
historical attempts; this queue supersedes their older pending descriptions.

Corrected TS source748fd5fd/request079b26b9/run39993829327 independently qualifies
genuine G1/G2/G3 and exact source/admissions/IR/ten-case fixed points under1800s.
G2/G3:545895/588552ms,3051772/3005236KiB maxRSS. Audit39996915835 verifies
native G1 source equality, retained bytes and immutable iteration captures.
Same-run emitted JS SHA2560f749f57420d8be2353ef53f30fe48e222367a369c1159d70c8b5d2dca748fb2
matches across all generations. Focused39992803465 passes all retained-original
proofs/strict IR/native capture comparisons/both85-module grammars/runtime guards.
The closure regression exposed by39990180405 is corrected, its failure preserved.

[Normal39993835819](https://github.com/dwijayuda/pskernel/actions/runs/39993835819)
PASSED at request/head079b26b945ceda507e89846aaab651e17fcb3b06,
tested merge9731f74f3d4ecaa93ad283ffedddfa7ddddc5f01 (identical Git tree to head).
Full Linux job120557858120 and final gate120570273055 passed:
37/37 qualified,0 blocked, releaseReady=true, both .lean/.ps grammars,
all seven backends, all four application categories, minimum-Python compatibility,
installed native package/standalone IO and explicit negative/refusal boundaries.
Artifact12521052731 digest010fff20b7522ae545672fb06e9d2c2500b40c81b53ec45e74be6b273de154d5,
expires2026-11-06T17:55:42Z. This qualifies the source candidate; draft173 remains
unmerged. The post-qualification record update changes documentation only.

Preserve qualified Rust branch83e18fe1/source5e0b548e/run39908529181:
actual G1/G2/G3/exact fixed point,692788/660042ms. Neither target's1800s correctness
replaces original240s performance. Prior exact240s TS39988689772 fails G2;
current corrected G2 also exceeds240s. Same-run executable equality is narrower
than independent clean-build repeatability.

> The previous TS-only queue is superseded by the current DirectJS/DirectWasm queue above.

Use shared source/frontend/elaboration/checked IR for all backends. Preserve generic
fallbacks and explicit unsupported-ABI refusals. Keep DirectJS regression coverage,
qualified Rust history and separate PSKernel research. Deferred feature expansion
does not remove working language functionality.

## Active user-directed DirectJS/DirectWasm mission — 2026-10-24 Asia/Jakarta

This supersedes the earlier no-DirectJS-detour work order while preserving all
qualified Rust/TS snapshots and Practical Core gates. Reuse the same compiler
service/frontend/elaborator/strict IR and official independent Lean4.35.0 checker.
1. DirectJS: bounded UTF8 cache and constructor-directed visitor proven/native
   tested at c5ae2ecc;87-module Lean/PS source census passes40010724322. Execute
   actual independent G1/G2/G3 and exact fixed point under the separate1800s profile.
2. DirectWasm: owned binary facade and import-free opaque-GC transport pass actual
   scalar/Unicode/arbitrary Nat/Int engine tests. Normalize98-module source closure
   within supported grammar, then execute the same genuine generation chain.
3. Preserve all-seven-backend/application/negative regression gates, qualify
   independent reproducibility separately, and optimize measured generated
   compiler bottlenecks without weakening fuel, checking, memory/stack or ABI
   refusal policies. Neither native fixtures nor source census qualify self-hosting.

### Current measured blockers — 2026-10-24 Asia/Jakarta

1. DirectWasm: both source grammars/native transport/carrier gates passed88f5b3aa.
   G1 afed7c4b/run40015615536 refuses original IR; complete diagnostic40017368933
   identifies exactly30 propagated UInt32/UInt64 raw bit-metadata findings.
   Normalize metadata to bounded Nat and retain scalar/float refusals; then
   execute independent G1/G2/G3 and exact source/admission/IR/binary fixed point.
2. DirectJS: request b9b73a70/run40012562356 passes independent G1 and ten cases;
   G2 exceeds1800s at1800208ms/3117056KiB. Profile the immutable G1 artifact and
   exact G2 request40017280827 before the next generic backend optimization.
3. Keep PR174 integration checkpointafed7c4b while focused work proceeds on
   work/psc1-direct-selfhost-blockers-20261024; preserve both histories and all
   qualified Rust/TS evidence. Finish all-seven-backend/native/application gates
   and independent generation evidence before integrating qualified claims.

### Proved blocker fixes and active generations

Source82b27063/Linux40020188747 PASSED all48 recursive-worker equalities,
byte bounds/modulus, JS visitor proof,7540 runtime and780 native/reference
statement comparisons,deep recursion/captures/refusals,actual owned Wasm
transport and87/98-module .lean/.ps census. No fuel/heap/stack/checking change.
Wasm G1 at03007171 had admitted bootstrap/3076 closed declarations and executed
the first real compilation; large integer compilation exposed eager recursive
prefix construction. Source82b27063 delays that construction in48 workers with
all-input equality proofs. JS statement loops address measured generator/GC
allocation; old G2 reached1800s without completing.

Active actual independent G1/G2/G3 and fixed-point run40020523049 at
request0c0b0be6/source82b27063 runs both targets with one native seed per target.
Terminal correctness/fixed-point status is pending. Performance240s and
independent clean builds remain separate. Exact attempts and evidence are in
PSC1_DIRECT_SELFHOST_QUALIFICATION_2026-10-24.json. Next order: diagnose any
actual generation failure, qualify both fixed points, finish current-source
seven-backend/application gates, then measured performance/reproducibility.
Preserve PR174 integration checkpoint and qualified Rust/TS references.
