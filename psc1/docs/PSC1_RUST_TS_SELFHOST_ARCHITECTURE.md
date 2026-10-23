# Rust and TypeScript self-hosting

Active priority from 2026-10-23: Rust native execution, TypeScript readable
npm-compatible generated distribution. DirectJS remains a regression/reference.
No package publication or merge is authorized.

## One compiler source

Ps.Compiler.Service owns the existing request decoder, exact source capture,
frontend preparation, elaboration, original strict IR validation, admissions,
source origin identities and provisional response. Thin target modules provide
only existing production emission. There is no handwritten target compiler.

Rust and TypeScript keep the generic IR supported by their existing production
emitters, with strictly rechecked shared worker fusion and selected public API
checks. DirectJS retains its existing closed specialization/fusion plan. This
uses existing generic emission; it adds no handwritten compiler or language
semantics. Every final original/transformed IR graph is still strictly checked.

Both expose String -> String candidates; these cannot authorize admission.
The host separately admits the exact canonical graph with official Lean 4.35.0
at eb6cafb7290e8bd5f2937522d8d804f58f02bafc. Target tools compile only emitted
source. Rust's appended main and TypeScript's Node runner perform file transport
only. Neither substitutes compiler source semantics.

## Executable qualification

Manual workflow psc1-rust-ts-selfhost-qualification.yml has independent Rust/TS
jobs, fail-fast false, 15-minute job bounds and 240000 ms child bounds. Its
committed-request fallback binds exact parent/event/branch and permits only
the request file in the trigger commit. Normal development does not run G2/G3.

Each job captures every registered transitive source import, hashes exact bytes,
seeds once, checks the candidate graph independently, then builds actual emitted
target code. Native compiler binaries are removed after the sole seed call.
Each executing generated compiler must pass all ten existing positive/refusal
cases across both grammars. G2 and G3 must compile that exact compiler closure,
match source/admission/original IR/transformed IR identities, independently
admit, compile and execute the same corpus. Generated artifacts and compiler
transport inputs are hash-bound before/after execution. Artifact mutation,
symlinks and mismatched host target identities have negative tests.

Measured wall time and peak RSS use actual generated requests; Rust uses the
child's /usr/bin/time RSS rather than Node's parent RSS. Target compilation time,
tool failures and generated source size are separate from service execution.
Rust release optimization level 1 is an explicit reproducible build profile;
type/borrow checking, locked dependencies and all runtime qualification remain.
The source, toolchain and profile are recorded. Level 3 build performance and
whole-file formatting are measured defects, not grounds for larger limits.
The exact reviewed Cargo lock is committed (SHA256
4d375c97eebc30fce378df900dd76bdd2cb9d82ce7619f50fb7ab3161f8e576d). Historical DirectJS evidence
is retained; no Rust-vs-TS performance conclusion is assumed before measurement.

## Acceptance and boundary

Rust and TypeScript G1 now genuinely execute and pass the frozen ten-case
corpus. Exact current sources/runs and the fully qualified seven-backend
baseline are in PSC1_RUST_TS_SELFHOST_QUALIFICATION_2026-10-23.json.
A green build or native source closure alone is not G1 execution or self-hosting.
A ten-case G1 pass is not G2/G3. Exact generations and fixed-point evidence are
required independently for each target; neither substitutes for the other.
Retain all seven Practical Core backends and frozen 37-criterion qualification.
Do not relax fuel, stack/heap limits, strict IR, unsupported ABI refusals,
negative tests or independent admission to make a generation pass.

Linux process-tree supervision retains the 240000 ms child deadline and 32 MiB
per-stream cap, with SIGKILL for descendants and negative OS-level tests. The
245000 ms outer supervisor guard is cleanup only. Incremental candidate/case
checkpoints survive job interruption; each manual target job remains 15 minutes.

Source/graph/IR fixed points and native build-product bit equality are distinct.
The current controller asserts source, admission, IR and observation identities;
record repeated clean Rust executable and TS emitted-product identities before
claiming binary reproducibility. No G2/G3 or final reproducibility claim currently
passes. Later backend and shared cursor candidates remain isolated until reviewed
and normally qualified on the integrated source.
