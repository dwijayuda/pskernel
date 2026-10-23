# PSC1 active work state

Updated 2026-10-23. Draft PR [#172](https://github.com/dwijayuda/pskernel/pull/172),
branch `fix/psc1-closure-normalization-20261021`. Use connected GitHub tools
and Linux Actions only. Fetch latest remote HEAD before every non-force,
expected-HEAD update. Preserve concurrent history. No merge or npm publication
is authorized.

## Verified active compiler checkpoint

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
| TypeScript | Both-grammar 85-module closure; bootstrap compiler candidate independently admitted | Strict TypeScript 7.0.2 compilation killed at 240006 ms before executing G1; G2/G3 not run |
| DirectJS reference | G1, ten frozen cases in normal CI | Prior G2 heap/time defect retained; no new fixed-point claim |

Rust uses its complete 92-module source closure and exact reviewed Cargo lock,
release opt-level 1. Real positive compiler requests take 323–538 ms and
20–23 MiB child RSS at this checkpoint; these small applications are not a
successful full compiler workload. TypeScript generics are retained rather
than unnecessarily monomorphized; its 6462076-byte source still cannot finish
strict checking within the existing deadline. Rust versus TS whole-compiler
performance cannot yet be compared.

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
is in progress at this recording. It is **not integrated or qualified** on the
active branch. Require full corpus and actual compiler workloads, then fresh
normal seven-backend qualification before promoting it.

The short TS CPU profile sampled only its Node launcher. It is not evidence
of a checker hotspot. Actual checker descendant inspection is running at
diagnostic commit `23626b21cada65ea6f78ac6db8dd0e3ffa6dff29`,
[run 39886224622](https://github.com/dwijayuda/pskernel/actions/runs/39886224622).
Do not implement speculative emitter rewrites or weaken strict checking.

## Next execution

Follow the dependency-ordered [roadmap](docs/PSC1_DEVELOPMENT_ROADMAP.md) and
[executable continuation prompt](docs/PSC1_RUST_TS_SELFHOST_CONTINUATION.md).
First resolve the ownership prototype and actual TS checker bottleneck.
Keep backend changes coherent, validate actual target compiler workloads, and
record terminal CI before claims. Do not repeatedly rerun the successful normal
baseline for documentation-only changes; run required fresh qualification after
source changes.

Previous full state and roadmap text are preserved verbatim under
`docs/history/2026-10-23-rust-ts-pivot-pre-reconciliation-*`; all commits,
qualification receipts, G1 artifacts and failed self-host evidence remain.
