# PSC1 AI work state

Updated2026-10-26 Asia/Jakarta. Active CLI work follows draft PR#190 at
10db75c3bb45725c259d4549228dbe6a7ecc1d00 on
feat/psc1-cli-project-workflow-20261026.
Use connected GitHub/Linux Actions only; fetch live HEAD and actual CI before
writes; preserve expected-HEAD single-parent non-force history.
No merge or registry publication is authorized.

[One roadmap](docs/PSC1_DEVELOPMENT_ROADMAP.md),
[new CLI guide](docs/PSC1_CLI.md),
[TypeScript workflow research](docs/PSC1_TYPESCRIPT_WORKFLOW_RESEARCH.md),
[previous maintainability checkpoint](docs/history/AI_WORK_STATE_BEFORE_CLI_2026-10-26.md).
Previous relative links resolve at10db75c3.

## Implemented; Linux validation pending

The new installed proofscript/psc/psc1 adapter supplies help, safe init,
version, explicit -p/-o and --option=value forms, source-only file projects,
current-directory project selection, --showConfig and text/JSON diagnostics.
Engine, output target and independent checker remain distinct.
No second compiler or hidden SDK download is introduced.

The existing universal-cli.mjs, universal.mjs and all seven feature AST-guarded
host modules remain unchanged. The adapter captures bounded exact source data,
then delegates to the existing checked command with a private inline snapshot.
Projects cannot select host/checker/SDK/publication capabilities. Legacy inline
projects and explicit source commands remain supported. Success JSON receipts
are unchanged; --version intentionally becomes human-readable, while --identity
retains verified installation JSON.

The source-only project format has at most4096 declared files, relative
non-symlink paths, exact UTF8/BOM capture,128MiB input/aggregate/encoded-project
bounds and existing inner request limits. init never overwrites; a late config
creation failure can leave the newly created source. showConfig explicitly
does not admit or publish. Diagnostics preserve original failures and never
invent source positions. Publication uncertainty retains its existing meaning.

Host-only package assembly uses exact successful .7 installed replay
40250645368/job121341566743/artifact12622001061, ZIP
d2f0221c06736636731a4b102a88e56abd3cb6242713d510dca42673704e162e.
It verifies current retained production-host files, preserves all compiler,
kernel, optional consumer/provider payload bytes, and creates an unpublished
proofscript0.1.0-psc1.8 host candidate. Canonical full assembly includes the
same new CLI modules/bin aliases. No compiler rebuild is required for this change.

## Required actual qualification

.github/workflows/psc1-cli.yml runs source/CLI subprocess regressions and all
historical seven-host AST/format gates, then actual offline local/global npm
project init/inspect/check/compile/build/edit/refusal tasks, npm run/exec,
multi-module files, optional Rust/Wasm engines and changed-resource refusal.
It reruns every original installed/kernel/dispatch/publication/application,
IO consumer and packed-type gate. Each compiler/tool240s, checker120s and all
existing fuel/memory/stack/lifetime/negative policies remain unchanged.
The ordinary PR source workflow remains conservative and mandatory.
Do not claim any test or .8 artifact qualified before terminal success.

## Preserved qualifications and unfinished work

PR#190 implementation e760e95b passes maintainability/G1 run40272793607 and
normal source40272797072 (37/37 finite criteria); final docs40276858130 passes.
Current123-module source remains separate from the frozen122-module .7 G3
closure073e5156a3fb521119bcfb4b06ad18ff136e734a0b2e10a676b1e16225835ef9.
The original four G3 fixed points remain JS/TS/Wasm40223062370 and
Rust40223086966. No new compiler generations or preservation theorem are claimed.
Official Lean4.35.0/eb6cafb7290e8bd5f2937522d8d804f58f02bafc, trust0,
independent admission, strict original/transformed IR, source/body pairing and
all resource policies are preserved. Kernel Wasm remains official C++/Emscripten
linear memory; compiler Wasm remains GC.

The user can arrange an independent maintainer. The human trial still awaits
actual results; do not infer human understanding from the automated rehearsal.
Watch/incremental execution, real compiler-origin structured diagnostics,
automatic source packages/extensions, additional release platforms and final
publication remain separate work. Continue from the roadmap and actual evidence.
