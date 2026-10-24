# Continue PSC1 after the unified compiler milestone

Use connected GitHub tools and Linux GitHub Actions only. No local checkout,
files/builds/tests, force updates, main merge or npm publication. Fetch latest
HEAD of feat/psc1-unified-selfhost-20261024 and draft PR178 (stacked on PR177)
before expected-HEAD non-force writes. Read AI_WORK_STATE.md, the roadmap,
PSC1_UNIFIED_SELFHOST_QUALIFICATION_2026-10-25.json and
PSC1_UNIFIED_COMPILER_SERVICE.md.

Current structured v2 source `325b130a`, control `658df6d9` and request `783cf8fc`
has120 modules, source-closure SHA256
a3350d645a81ed17f69af59333978c60e3b8f9e1d6855a999e0bc5844e183990,
root SHA256688ffd1dfdfdc7500a97772291977e36bb763da7520228db3b77f59f5793a313.
Run40117051185 PASSED all four actual generated G1 engines, both grammar
source audits, independent admission, strict IR,160 cross-target cases and36
envelope refusals. Immutable readback40117873559/job `120942876835` additionally
verifies exact source/executable inventories and identical originalIR/canonical
admissions across engines. It does not run current v2 G2/G3.

Preserve genuinely qualified first string-envelope v1 JS/TS at source `b2ab4d34`,
run `40113918732`: JSjob120931150386 G2/G3 1112514/1096375 ms;
TSjob120931150136925482/1009493ms. Both pass exact executable/source/admission/
IR and all four output-target observations through G1/G2/G3. The overall matrix
failed only because Rust/Wasm failed; individual JS/TS qualification is real.
Do not carry those fixed-point claims over to changed v2 source.

Actual v1 blockers: Wasmjob120931150283 G2 reaches1800101ms, noG3/fixedpoint.
Rust initialjob120931150317 cannot build the15.2MB G1 at optimization 1 within
240s. Archived-input diagnostic40114865357: optimization 0/256 units builds in
51719ms; optimization 1/256 still times out240010ms. Only the new unified Rust
correctness service uses0/256 and a stable verified Cargo package path.
Historical single-emitter optimization 1 remains. Retry0cf66b05/run `40115403218`/
job `120935640656` passes G1/all 49 tests then G2 stack-overflows after1179495ms.
The exact stack site is not established. Preserve all failed evidence; do not
increase stack/heap/fuel or claim v2 fixes the stack/deadline without execution.

The single portable composition root imports the four existing compiler services;
its v2 envelope is [protocol,target,existing-request-array]. The decoder passes
existing validated request fields directly to production compile/emitter APIs.
It removes the avoidable huge nested JSON string. No alternate frontend/kernel
or handwritten compiler exists. Python/PHP remain outside this closure and
available through existing exact-build-pinned optional native providers.
Native Wasm component/typed-IO adapters and all seven target mappings remain;
portable component emission and generated-distribution/provider integration
have not been qualified.

Next dependency queue:
1. Attempt current structured-v2 Rust/Wasm G2/G3. Diagnose actual failures
   (including a real stack trace for any repeat Rust overflow) and optimize
   the generic mechanism. Keep optimization 1 target-build throughput tracked.
2. After source stabilizes, qualify all four engines' v2 G1/G2/G3/fixed points.
   Preserve the earlier v1 JS/TS compilers as working references.
3. Integrate generated engine assets, CLI selection, independent checking,
   component adaptation and optional-provider dispatch into the unpublished
   core distribution. Do not relabel the current native package as self-hosted.
4. Clean independent reproduction/final release checks; optimize toward the
   separate240s performance target. Publish/merge only with authorization.

Long chains launch only through an explicit request-only commit. Fetch fresh
HEAD, set parentCommit to it, and update exactly
.github/qualification-requests/psc1-unified-selfhost.json:
```json
{
  "schema": "psc1-unified-selfhost-request/1",
  "branch": "feat/psc1-unified-selfhost-20261024",
  "parentCommit": "<fresh exact HEAD>",
  "action": "qualify-independent-G1-G2-G3",
  "mode": "--self-host",
  "profile": "correctness-1800s",
  "g1TimeoutMs": 240000,
  "g2g3TimeoutMs": 1800000,
  "targets": ["rust", "wasm-core"]
}
```
For a source-validation milestone, action validate-independent-G1 and mode
--g1-only are supported. The closed engine list is js,ts,rust,wasm-core.
Do not duplicate unchanged live requests. Actual Linux commands are:
```sh
node scripts/generated-target-source-audit.mjs rust unified
node scripts/generated-target-qualification.mjs rust --self-host correctness-1800s unified
```
Official independent Lean 4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc,
strict original/transformed IR, source/logical pairing, negative tests,
G1/corpus/tools240s, checker120s, G2/G3 correctness 1800s, response128MiB and all
memory/stack/fuel policies remain unchanged. Python/PHP historical3600s and
the original performance240s profiles remain separate. No formal preservation,
DDC, new clean reproduction or complete generated npm release is claimed.

Final native seven-backend regression40117055147/Linux `120943685823`/gate120948016037 also PASSED37/37 finite criteria; review `783cf8fc`/tested merge `b816df5d` share treecfc8b5304f943945d1a52bc9de2047fb4ad4b928. See the exact receipt for three matching native tarballs and artifact `12570094990`.
