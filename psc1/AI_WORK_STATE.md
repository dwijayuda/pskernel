# PSC1 AI work state

Updated 2026-10-24 Asia/Jakarta. Use connected GitHub tools and Linux Actions only.
Fetch exact HEAD before expected-HEAD non-force writes. No PR merge or npm
publication authorized. Practical Core v1 remains 14 families / 37 finite criteria.
[Roadmap](docs/PSC1_DEVELOPMENT_ROADMAP.md) owns the dependency queue;
[canonical receipt](docs/PSC1_DIRECT_SELFHOST_QUALIFICATION_2026-10-24.json)
owns immutable attempts, artifacts, timings and source identities.

## Active Python/PHP self-hosting mission — 2026-10-24

Continue on feat/psc1-python-php-selfhost-20261024, draft
[PR176](https://github.com/dwijayuda/pskernel/pull/176), based on preserved
direct-target checkpoint6393226e5d29ad246e9421fe398d78c43954c6d9.
Latest executable/source checkpoint:6f73c9f0bbd04a5577ac90d80f7a0481914cb1f4; source preflight is pending.
No Python/PHP G1, G2/G3 or fixed-point qualification is claimed yet.

The existing emitters now have one portable implementation each:
Ps.BackendPython.Portable and Ps.BackendPhp.Portable. The old Module paths are
native compatibility adapters preserving existing APIs/defaults/metadata.
Both native CLI and generated compiler facades call the same portable emitter.
There is no second handwritten compiler, alternate frontend or native delegation.

The proved normal form is State -> Except Error (Prod Value State):
seven complete operation equalities to StateT (Except) passed official Lean;
four complete arity-dispatch equalities are added at this checkpoint and await CI.
The source port uses explicit state/results, flat constructor cases and typed
workers under dynamic inputs, without extending the frozen language grammar.
Ordered line/origin accumulators preserve printed output and offsets.

Linux40068694963/job120797262656 at62cd0f1b:
native build,34816 retained runtime catalog/order/duplicate/unknown comparisons,
seven state API proofs/tests,144 complete retained-emitter output/refusal
comparisons, and all four independently admitted/generated runtime probes
(Python/PHP × Lean/PS,104 runtime and8 state queries each) PASSED.
These are compiler/library regressions, not generated compiler qualification.
Both closures contain86 modules. Python's entire closure parses in both
grammars; elaboration reached the final entry and refused contextual throw.
PHP's remaining parse refusal was the nested do RHS at643:13.
Current6f73c9f0 replaces contextual pure/throw with explicit Except
constructors and extracts that RHS into an ordinary typed helper. Re-query CI.

The shared production harness supports both targets, the existing ten cases,
hash-bound unchanged-wire transport and the same independent admission/IR
pipeline. Python3.14.8 and PHP8.5.11/ext-gmp are pinned; qualification records
interpreter binary hashes. Preserve G1/corpus/tools240s,checker120s,
G2/G3 correctness1800s, separate original performance240s and all other limits.
PHP retains1G; Python recursion and integer-digit global settings are unchanged.

Next: finish the whole source/negative gate, issue one request-only
.github/qualification-requests/psc1-python-php-selfhost.json commit from fresh HEAD,
then execute genuine independent G1→G2→G3/fixed points for both targets. Diagnose
actual generated requests rather than infer performance from fixtures.
Obtain full current-source37/37/seven-backend/application evidence and clean
reproduction separately. No merge or publication.
[Continuation](docs/PSC1_PYTHON_PHP_SELFHOST_CONTINUATION.md) and
[receipt](docs/PSC1_PYTHON_PHP_SELFHOST_QUALIFICATION_2026-10-24.json) own resumption.
The older direct-target performance queue below is deferred by this user mission.

## Completed DirectJS and owned DirectWasm mission

Source commit 133e589288b563e74578b771ec35595beb3a9fe8 is genuinely self-hosted
for both targets by request 2d1f8244d8402fbccd5a018890d61d8ed4d20775,
parent eefedf2a3f9f0002975870e8128bb0f404723946.
[Qualification 40062120079](https://github.com/dwijayuda/pskernel/actions/runs/40062120079)
PASSED both jobs: JS 120777813920 and Wasm 120777813877.
Each target used one native seed, disabled native compiler tools afterward,
executed G1 → G2 → G3, independently admitted each generation, validated strict
original/transformed IR, and passed all ten positive/negative observations.
Exact captured source/admission/IR/observation/target-byte fixed points passed.

| Target | Modules | G2 ms / maxRSS KiB | G3 ms / maxRSS KiB |
| --- | --- | --- | --- |
| DirectJS | 87 | 824066 / 3076776 | 832426 / 3179880 |
| Owned DirectWasm | 98 | 876840 / 1508096 | 888398 / 1816228 |

These are actual generated compiler workloads with different target closures,
not a matched backend speed benchmark. Memory uses Linux child maxRSS and
separately sampled descendant RSS; see exact execution events in the receipt.

JS closure: 5b1824ce8d98a9ec9068f351f28abab8485a9786510c47fd5b4cedeac8734a2e.
Wasm closure: 322f29eb0b4c734ea09c7f4ee53380633faa3799b367808c0d393783cd6e48c1.
JS source SHA256 across all three generations:
8dad2e7fb1e3eb834bed9fc7581b8f2cce36f834c5e7842f19b6f8bb904b871a.
Owned Wasm binary SHA256 across all three:
addc90b9cfff0dcbb8ea8d8f1d7824187750b5250514915608cda5607f170b72.
Artifacts: JS 12548433615; Wasm 12549160290. Digests, request and producer
identities are in the receipt. Operational manifests contain timings/events,
so different manifest hashes do not contradict equal compiler executable bytes.

## Independent clean G1 reproduction

[Audit 40064496804](https://github.com/dwijayuda/pskernel/actions/runs/40064496804)
PASSED both clean Linux jobs at diagnostic control commit
36d917b01a008fcae2259fc7a604b3e8a47e3db1 on
diagnostic/psc1-direct-clean-g1-20261024.
No .lake build cache was restored. Fresh native seed/checker builds execute
the production G1-only harness, independently admit G1, validate strict IR and
all ten cases, then compare exact source inventory, admissions, IR, observations
and JS source / Wasm hex+binary bytes against EACH qualified G1/G2/G3.
All comparisons passed. Artifacts 12548393011 (JS), 12548652944 (Wasm).
The diagnostic request/script/workflow are preserved on that branch.

Scope: independently rebuilt G1 reproduces the three previously qualified
generation artifacts. A second independent full G2/G3 replay was not run.
This is not a DDC or formal compiler semantic-preservation proof.

## Source mechanisms and regression evidence

Focused 40061782715/job120776657312 PASSED at source133e5892:
- Eleven all-input full JS API equalities against retained originals, covering
  decimal/type/expr lowering, validation, tail aliases/captures and printing.
  Move recursive prefixes beneath every dynamic input; scan233 owned definitions,
  reject all eleven original defects, test million-fuel early results/refusals.
- Three complete Wasm encoder API equalities: Except flatMap, byte chunks and
  UTF8 characters use fully applied reverse accumulators, preserving bytes,
  order and first-error priority, including100000-element cases.
- Three shared environment/constructor/recursor lookup equalities and100000
  early/missing/kind/duplicate-payload cases, source146270cf.
- All earlier52 Wasm prefix, six foundation and checked/erasure collector/index
  equalities; original fuel, errors, insertion/index and source/logical pairing.
- All retained JS lazy UTF8 views, capture/alias/fuel,10584 view comparisons,
  64 direct-dispatch order/trap tests, native/reference comparisons.
- Owned import-free GC Wasm transport,96-opcode/Unicode/Nat/Int cases and
  complete87/98-module Lean/PS source censuses. No verification or limit changes.

Earlier failures remain immutable in the receipt. In particular the older
shared-lookup-only JS baseline d7c6f166/run40061402443 FAILED its G2 deadline:
1800233ms /3107644KiB, no G3/fixed point. It lacks the eleven later JS fixes.
Earlier Wasm stack traces reached encoder flatMap; the top Nat division frame
did not establish an arithmetic defect. Fix the demonstrated source class,
rather than raising stack/fuel or replacing the compiler architecture.

## Full Practical Core and review

[Full40062210987](https://github.com/dwijayuda/pskernel/actions/runs/40062210987)
PASSED: Linux120780825013 and final gate120786364196;37/37 qualified,0 blocked,
releaseReady=true, all seven backends, both grammars, applications, minimum
Python and installed native package/IO/library regressions. Tested review HEAD
06186537cf9339fc3f24a7d13387c2ad55ee0749 and merge
980d096ca3e85b9ad2970f16602ad1d14a089d69 have identical Git tree
cbf312e1f4bca9e7085719c12b627be5c16099a7, verified through GitHub APIs and checkout log.
Artifact12549325904, digest
sha256:6ad48b109e2e995c344a6855a85de44380f6ee628b67f4033990a152598a7bf9.
This qualifies the tested compiler source; the final receipt update edits docs only.

Draft [PR175](https://github.com/dwijayuda/pskernel/pull/175) remains open,
unmerged, based on preserved PR174/integrationafed7c4b. The review branch
work/psc1-direct-selfhost-blockers-20261024 was advanced without force.
Final evidence reconciliation edits documentation only; compiler code remains
the qualified133e5892 source. No merge or package publication occurred.

## Boundaries and next executable work

The original performance-240s profile remains separate and unqualified;
the measured current G2/G3 times exceed240s. Correctness-1800s does not weaken it.
G1/corpus/tools240s, checker120s, G2/G3 correctness1800s, semantic fuel and
all memory/stack/security/refusal limits remain unchanged.

Official independent Lean4.35.0 checker
eb6cafb7290e8bd5f2937522d8d804f58f02bafc, strict original/transformed IR and
negative tests remain mandatory. All targets share the existing compiler
service, frontend, elaborator and checked pipeline. Only emission/runtime
carriers differ; no alternate handwritten compiler or native delegation.

Preserve qualified Rust branch fix/psc1-rust-owned-string-moves-20261023,
head83e18fe183498f7d8b0fc3e3faa5bdacc41cb23d, source5e0b548e/run39908529181,
G2/G3692788/660042ms. Preserve TS perf/psc1-erasure-applied-workers-20261023,
head84e1e16f61cec3d28d9fdc62d6eaca4f3c0a8577, source748fd5fd,
request079b26b9/run39993829327, G2/G3545895/588552ms; full39993835819 passed37/37.
These qualify older snapshots, not a fresh Rust/TS replay of changed common source.

No active self-host qualification requests remain. Next dependency queue:
profile the now-completing exact generated compiler workload, optimize one
measured generic bottleneck with retained-original API/negative proofs, then
rerun changed-source focused and genuine qualification. Keep original240s
performance acceptance explicit. Independent full-chain repeatability is a
separate future evidence scope. Do not repeat unchanged correctness chains for
documentation-only updates. See the [executable continuation](docs/PSC1_DIRECT_SELFHOST_CONTINUATION.md).
