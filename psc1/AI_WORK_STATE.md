# PSC1 isolated TypeScript generator candidate

This branch is `fix/psc1-ts-generator-result-types-20261023`, separate from
PR #172's normal qualification. Its initial result annotations were integrated
as `d0bef34de7d5d3c495f2a4a73af7eccd892d0d74`; normal run 39887884270
is in progress. Do not claim that result for later isolated generator changes.

Current structured-generator source
`07fcc6037330166067d422d15a6630b1f7f626ae`, request
`0ab4874a22edbde7025e5f29004f3c7ee2bdd4a1`,
run 39889151346/job 120204444859 is validating at this recording.
The common structured tail emitter gains a generator mode, retaining exact
legacy pure output by all-input induction. It preserves ordinary typed emission
preflight and fuel failures, call-by-value argument evaluation, alias-escape and
shadow guards, existing driver protocol and public API. No native fallback,
strict-check bypass, any/cast workaround or resource change.

The prior annotated source a0a0a92f39deb7ff3c9336f41dc6ebcb681ae1d1
qualifies executing G1/all ten cases in 39887064597; G2 times out at 240091 ms,
G3 not run. Artifact 12473571856 (digest
0c5fc53de729edd9d8af10bd189344d0aa85a36b9e22fa1eabdd4573d014f83e)
retains exact emitted source, admissions, IR, requests and execution results.
Actual 30-second G2 runtime profile 39887994972 shows JSON parsing and generator
dispatch overhead; the earlier native-checker bottleneck was contextual return/
yield/conditional inference and is resolved by checked result annotations.

Next: query current terminal evidence, fix measured defects, exercise all ten
frozen cases and actual G2/G3 at existing bounds. Promote only reviewed changes
and run fresh full normal seven-backend qualification after integration.
No merge/npm publication. Keep official Lean 4.35.0 and strict original/
transformed IR authoritative; preserve old receipts and DirectJS G1.

---
The active branch checkpoint below is context, not qualification of this branch.

# PSC1 active work state

Updated 2026-10-23. Draft PR [#172](https://github.com/dwijayuda/pskernel/pull/172),
branch `fix/psc1-closure-normalization-20261021`. Use connected GitHub tools
and Linux Actions only. Fetch latest remote HEAD before every non-force,
expected-HEAD update. Preserve concurrent history. No merge or npm publication
is authorized.

## Latest candidate and verified compiler checkpoint

TypeScript generator result annotations are being integrated from isolated source
`535f1c3927622c4ed1a23bde67f2bb96cbc2c226`. Run 39887064597 at request
`a0a0a92f39deb7ff3c9336f41dc6ebcb681ae1d1` passes the all-input legacy
context equality, 264 old/current comparisons, both full source grammar audits,
strict TypeScript compilation and all ten actual G1 corpus cases. G2 times out
at 240091 ms; G3/fixed point remain unqualified. Fresh normal seven-backend
qualification is required for the integrated source; the previous normal pass
below remains the verified baseline.

## Verified previous compiler checkpoint

Source/profile commit `76bf4120de83bf776a4e790672f7b2d0198e25db`;
qualified branch HEAD `ea10eff9b3de063941c6029bb6c821f9cc10cc3f`;
tested merge `4e5f4d2c8c90178aa7cf301717004cfc6182596f`.
[Normal Linux run 39880807914](https://github.com/dwijayuda/pskernel/actions/runs/39880807914)
completed successfully: every selected job, all 47 full-job steps, all 37 finite
Practical Core criteria. The benchmark lane was dependency-skipped. Both
grammars, all seven targets, real applications, strict IR, official independent
Lean admission, host negatives, source closure checks and installed native
package qualification pass. Package remains unpublished.

The authoritative finite contract is
[PSC1_PRACTICAL_CORE_V1_CONTRACT.json](docs/PSC1_PRACTICAL_CORE_V1_CONTRACT.json):
14 families, 37 criteria, both grammars, seven targets, four application
categories. This does not claim unrestricted language completeness or a formal
backend preservation theorem.

Exact jobs, steps, toolchain/source/package identities, artifact retention,
manual results and boundaries are recorded in
[the current machine-readable receipt](docs/PSC1_RUST_TS_SELFHOST_QUALIFICATION_2026-10-23.json).
Full artifact 12471552943 expires 2026-11-06; preserve needed evidence before
expiry. Historical receipts remain unchanged.

## Self-hosting status and priority

Rust native execution and TypeScript readable npm-compatible distribution lead
this work. One shared compiler source, frontend, elaborator, checked IR and
verification pipeline live behind `Ps.Compiler.Service`; thin target facades
use existing production emitters. No handwritten target compiler was added.
DirectJS remains the working reference/regression backend. Its diagnosed G2
heap defect remains open; DirectJS-specific G2 tuning is not prioritized.

[Manual run 39880803794](https://github.com/dwijayuda/pskernel/actions/runs/39880803794)
at qualified HEAD gives:

| Target | Actually qualified | Current blocker |
| --- | --- | --- |
| Rust | G1 executable and all five positive/five negative frozen cases | G2 full compiler request killed at 240031 ms before candidate admission; G3 not run |
| TypeScript (baseline) | Both-grammar 85-module closure; bootstrap compiler candidate independently admitted | Original strict compilation timed out; later typed-generator source now passes G1 in 39887064597, G2 still times out |
| DirectJS reference | G1, ten frozen cases in normal CI | Prior G2 heap/time defect retained; no new fixed-point claim |

Rust uses its complete 92-module source closure and exact reviewed Cargo lock,
release opt-level 1. Real positive compiler requests take 323–538 ms and
20–23 MiB child RSS at this checkpoint; these small applications are not a
successful full compiler workload. TypeScript generics are retained rather
than unnecessarily monomorphized; its original 6462076-byte source could not finish strict checking. Explicit nested
generator annotations derived from checked result types now resolve that stall;
strict checking and actual G1 pass on the isolated annotated source. Both targets now execute real small compiler workloads. Rust positives on the
ownership candidate take 291–437 ms and 14–17 MiB child RSS; TS annotated G1
positives take 747–3189 ms and 193–404 MiB RSS. Different candidate sources and
isolated runner processes limit this comparison; neither completes full G2.

The official checker remains Lean 4.35.0 commit
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. Preserve strict original and
transformed IR, independent canonical admission, negative tests, ABI refusals,
source identities and unchanged fuel/heap/stack/request limits. Each target
must independently pass actual G1/G2/G3 and exact source/admission/IR/corpus
fixed points before qualification. Bootstrap emission alone does not qualify
a generation.

## Implementation completed on the active branch

Shared service/facades, registered roots, native single-seed transport,
hash-bound target artifacts, independent admission, frozen ten-case corpus,
source inventory, target runners, locked Rust dependencies and separate manual
matrix qualification are implemented. The native compiler binaries are removed
after the sole seed call. Linux whole-process-group supervision enforces
240000 ms per child and 32 MiB per stream; the 245000 ms outer guard permits
cleanup only. OS regressions cover ignored TERM, inherited pipes, exited
parents and output overflow. Incremental receipts survive interruption.

TS source normalization includes an all-input visitor equality proof and
264 retained-old/current module output/runtime comparisons. Both complete
owned source closures pass both grammar audits. Whole-file rustfmt times out
on large compiler output, so this manual build compiles exact raw emitted Rust
with concise Cargo diagnostics; normal production formatting is unchanged.
Readable large-source formatting remains open.

## Isolated measured Rust optimization

Bounded exact artifact replay in
[diagnostic 39882471895](https://github.com/dwijayuda/pskernel/actions/runs/39882471895)
finds both 12/60-second samples in `String::clone` from
`psJsonStringToChars`, before frontend decode completes.

Branch `fix/psc1-rust-owned-string-moves-20261023` contains a separate ownership
prototype: exact borrowed String forwarding wrappers, removal of redundant
rvalue clones, and evaluation-order-preserving invariant String loop moves.
Native guards and retained-old/current Rust execution comparisons pass;
a generated handler corpus exposed missing struct-expression grouping, fixed
in `9052b59fe7bafc000a2fa8ec24f0ead266276682`.
Current request HEAD `f037377574124cf7a374d627f0c57e4a855e09e5`,
[run 39886083977](https://github.com/dwijayuda/pskernel/actions/runs/39886083977)
passes all ten G1 cases, then G2 aborts with stack overflow at 103782 ms.
It is **not integrated or normally qualified** on the active branch. Require full corpus and actual compiler workloads, then fresh
normal seven-backend qualification before promoting it.

The short TS CPU profile sampled only its Node launcher. It is not evidence
of a checker hotspot. Actual checker descendant inspection completed at
diagnostic commit `23626b21cada65ea6f78ac6db8dd0e3ffa6dff29`,
[run 39886224622](https://github.com/dwijayuda/pskernel/actions/runs/39886224622).
It identifies the native TypeScript checker repeatedly traversing contextual
return/yield/conditional inference. The integrated annotation correction uses
checked declaration/lambda/let result types, retains legacy consumer bytes by
all-input proof, and preserves strict/noEmitOnError. G2 execution profiling is
next. Rust exact replay 39886925277 remains in String cloning at its shorter
180-second diagnostic deadline; it does not identify the crash stack or prove
a destructor failure. Diagnose before changing destruction or stack behavior.

## Next execution

Follow the dependency-ordered [roadmap](docs/PSC1_DEVELOPMENT_ROADMAP.md) and
[executable continuation prompt](docs/PSC1_RUST_TS_SELFHOST_CONTINUATION.md).
First resolve the Rust ownership candidate's remaining cloning/stack failure
and profile actual TypeScript G2 execution after the checker correction.
Keep backend changes coherent, validate actual target compiler workloads, and
record terminal CI before claims. Do not repeatedly rerun the successful normal
baseline for documentation-only changes; run required fresh qualification after
source changes.

Previous full state and roadmap text are preserved verbatim under
`docs/history/2026-10-23-rust-ts-pivot-pre-reconciliation-*`; all commits,
qualification receipts, G1 artifacts and failed self-host evidence remain.

