# PSC1 AI work state

Updated 2026-10-27 Asia/Jakarta. Runtime/watch development starts from PR #192
HEAD 94e0c13f6a4b434f73c859cc0c716cb6fb8d1340, active draft PR#193, branch
feat/psc1-watch-runtime-20261027. Fetch live HEAD/CI before updates; preserve
single-parent expected-HEAD non-force history. Connected GitHub/Linux Actions only.
No merge or npm publication authorized.

## Current implementation; Apache-2.0 .11 qualification pending

The .9 package refuses any Node version except22.23.3 before checking.
This host change replaces both installed/session exact-version refusals with
Node>=22.23.3 or Bun>=1.4.0 policy. Exact CI executable versions/hashes remain
reproduction evidence. Bun uses a separate parse-only JS consumer (its --check
flag has different semantics), retains the independent official kernel and
mandatory public-API consumer, and child launches disable automatic installation,
macros and implicit env-file loading. Other runtimes remain unqualified.

CLI check/compile/build accept --watch, -w and -watch. The supervisor polls
only explicit sources/config paths every500ms, debounces saves, recaptures full
bounded exact-byte projects and serializes genuine checked subprocesses.
Invalid/deleted inputs wait for repair, including newly declared missing files.
No semantic/incremental cache or implicit dependency loading is introduced.
A private worker recaptures before execution and revalidates the same captured
inputs immediately before build publication (or before compile/check stdout).
A trusted host can veto publication; it cannot manufacture admission.
Edits after that final guard are handled by the next queued rebuild.
Success receipts remain JSON lines on stdout; progress/diagnostics stay on stderr.
Linux process groups receive interruption with bounded kill escalation.

Candidate proofscript@0.1.0-psc1.11 is a finite host overlay on exact .7 inputs.
Frozen compiler/kernel/provider payloads are unchanged. Actual Bun testing exposed
an additional exact pin in the optional Rust transport. A23-module production
host audit found this remaining pin. Both optional engine packages are .11 host/
metadata repacks; every payload byte, fixed point and source identity is compared
unchanged. Rust transport shares the runtime policy and original Linux lifetime
guard; Wasm transport is unchanged. Manifest/index pins are explicitly refreshed. Source/installed policy,
real dependency/config/atomic-save/recovery/watch/refusal/target/signal tests,
all prior regressions and actual Node/Bun runtime matrices are required.
Current code is implemented, not yet qualified. CI/results and new ZIP identities
will replace this pending section only after terminal success.

## Preserved evidence and boundaries

[Prior layout state](docs/history/AI_WORK_STATE_BEFORE_RUNTIME_WATCH_2026-10-27.md)
retains exact .9/root/archive hashes, full source40344469855 (37/37 finite
criteria), installed40344458391, current-source WasmG1/40344458240 and final docs
40352122925. This change does not rerun or promote unchanged frozen G2/G3.
Frozen122-module closure remains
073e5156a3fb521119bcfb4b06ad18ff136e734a0b2e10a676b1e16225835ef9;
development source124 modules is distinct. All seven mappings remain.

Official Lean4.35.0/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/trust0,
strict original/transformed IR, exact source/body pairing, negatives, semantic
fuel, resource/lifetime/memory/stack policies remain. Compiler/tools/G1 stay240s;
independent checker120s; manual correctness and240s performance stay separate.
Kernel-Wasm stays official C++/Emscripten linear memory; compiler-Wasm stays GC.
Python/PHP remain optional. No final cross-platform/public registry qualification.

[Roadmap](docs/PSC1_DEVELOPMENT_ROADMAP.md) remains the single queue.
The independent unassisted maintainer trial is still pending its arranged
participant; no AI/CI human-understanding claim.

## Latest owner steering: modular execution and Apache-2.0

The owner selected Apache-2.0 for all project-owned code. Root/PSC1 licenses and
notices plus50 active owned package manifests are updated; third-party licenses
and historical qualified archives remain intact. Nine owned installable tarballs
receive a finite license/notice/metadata overlay; original executable bytes are
compared unchanged and integrity descriptors refreshed. Two vendor SDK tarballs
are retained byte-for-byte. Real tarball licensing and engine-strict installation
are required; no merge/publication authorization is implied.

[Modular distribution decision](docs/architecture/modular-compiler-distribution.md)
inspects the supplied PSC0 archive without executing it. Its core/elab/erasure
entries re-export compiler and declare independent package compilation false;
those facades are not actual separated execution. Adopt genuine source-owned
JS/TS module graphs and cohesive exact-cohort packages for final release. Keep
native Rust/Wasm execution efficient, with organized source/debug output. The
module-graph pilot and its own self-host/fixed-point qualification are pending;
no textual split or package-name-only completion claim.

Pre-license implementation91c5d898adea8e8d184b7927adf2ed988af8c2d8 has actual
Bun1.4.4/four-engine/both-grammar compile/watch/refusal success. Run40437783359
also passed full installed watch, typed TS/Rust/Wasm targets, superseded-input
veto and actual Node/Bun native-child reaping, then the frozen application gate.
Remaining installed gates were still running when this licensing layer began.
Source40437789669 passed static/native/focused/closures/G1/lossless/trace/integration;
full release job121975136632 was still running. These are exact pre-license
partial results, not qualification of .11. Final receipts must use live terminal CI.
