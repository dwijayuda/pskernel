# PSC1 AI work state

Updated 2026-10-26 Asia/Jakarta. Active draft [PR#191](https://github.com/dwijayuda/pskernel/pull/191),
feat/psc1-cli-project-workflow-20261026, follows PR#190 at
10db75c3bb45725c259d4549228dbe6a7ecc1d00.
Qualified implementation/test head: 9b251a971819ecfc5450ac71e1caca967ec6c947.
Later checkpoint commits contain documentation/receipts only. Fetch live HEAD
and actual terminal CI before writes. Preserve expected-HEAD, single-parent,
non-force history. Use connected GitHub/Linux Actions only.
No merge or npm registry publication is authorized.

[One roadmap](docs/PSC1_DEVELOPMENT_ROADMAP.md), [CLI guide](docs/PSC1_CLI.md),
[research and decisions](docs/PSC1_TYPESCRIPT_WORKFLOW_RESEARCH.md),
[exact CLI receipt](docs/PSC1_CLI_QUALIFICATION_2026-10-26.json),
[preceding work state](docs/history/AI_WORK_STATE_BEFORE_CLI_2026-10-26.md).

## Implemented and qualified on Linux

The installed proofscript/psc/psc1 aliases use a small developer adapter around
the unchanged checked command. Help and no-argument help, safe init/--init,
a conventional text version, -p/-o/equals forms, source-only file projects,
current-directory project selection, --showConfig and text/JSON diagnostics
are implemented. Existing source commands, legacy inline projects, success
JSON receipts and verified --identity remain. --version deliberately changes
from JSON to text; machine callers use --identity.

Projects cannot choose engine, kernel, SDK, output, service or checker tools.
File projects capture declared relative regular non-symlink sources in order,
preserving exact UTF8/BOM bytes and checking snapshot changes. At most 4,096
files; 128 MiB per input/aggregate source/encoded project; inner limits unchanged.
init never overwrites. A late config failure can leave its new source file.
showConfig has logicalAdmission:not-run and publication:not-requested.
The adapter does not fabricate compiler spans or introduce another frontend.
Compiler execution, output target and independent checking remain separate.

The source-linked guide contains init/check/build/explicit JS consumption,
npm scripts, source configuration, engine/target/checker mapping, failure and
resource boundaries. Research uses official TypeScript/npm/Node/VSCode sources;
developer behavior hypotheses are not presented as survey results.

## Exact Linux evidence

CLI/toolchain run **40314294152 /121543173394** passes at the qualified head:
- 19 source/CLI subprocess groups and all seven historical host AST/format gates.
- 55 actual installed requests, including21 positive checked commands;
 both grammars, local and global, all three aliases, npm run/exec, a multi-module
 file project, optional Rust/Wasm engines and installed-resource tamper refusal.
- Four full example/edit/refusal flows observe42 then43; ill-typed replacement
 preserves each prior generation pointer and artifact bytes.
- All existing offline installed/kernel/candidate/negative, component/provider,
 transaction/SIGKILL, checked publication, actual application/IO consumer and
 packed-TypeScript declaration gates remain and pass. Exact counts and hashes
 are in the receipt and immutable Actions artifact.

Ordinary source **40314305497**, full **121548383462**, gate **121559536094**
passes every selected dependency and **37/37 finite Practical Core criteria**.
The optional benchmark remains skipped/unqualified. This is finite source
qualification, not a final universal release or a whole-compiler proof.
Current source integration executes 28 before/after artifacts across both
grammars/seven targets; 123 modules / 4,742 Core members remain separate from G3.

## Installable artifact and preserved payloads

Root `proofscript@0.1.0-psc1.8`: **3822242 bytes**, SHA256
c9cae0ba95d3f55f1d4e88d03b9247b97f8c88895588867828e514e55513de67.
Actions artifact **12648248091**, ZIP SHA256
dfee107e7615ebb2e3f2d7bcbff831369509fe166c936086e448d9f76d08c54f.
Use its eleven exact tarballs and package-receipt.json. Nothing is published
to the registry. Default JS/TS execution and the genuine official Lean4.35
linear-memory Wasm checker remain in the root; optional engines/SDKs/providers
are explicit. Root installation remains offline, script-free and SDK-free.

All 126 retained root payload files are byte-identical. Component/Python/PHP
tools are .8 metadata-only repacks: every non-package.json file is identical.
Remove their unnecessary reverse optional peer to exactly the .7 root; it let
npm prune a .8 compiler when installing the tools. The root still requires
exact optional versions, complete inventories and resource hashes. Rust/Wasm
compiler payload packages remain .7. No worker/runtime/compiler/kernel is rebuilt.
Canonical full assembly selects the same new CLI and decoupled tool metadata;
the qualified bytes in this slice are the explicitly recorded host-only assembly.

Frozen packaged G3 source: 122 modules / 4,742 members, closure
073e5156a3fb521119bcfb4b06ad18ff136e734a0b2e10a676b1e16225835ef9.
Four original G3 fixed points remain JS/TS/Wasm 40223062370 and Rust 40223086966.
Application replay uses physical output stores and the exact ancestral
8383c6983e5fa2f2d945b02ba4b349ab64522c64 source snapshot, retaining every original
source/census/closure/contract/admission/runtime assertion. A separate receipt
records source/test commits and archived stores. A symlinked harness output
was correctly refused; the production store guard was not weakened.
Failed attempts remain in the receipt, never relabelled successful.

## Continue and remaining boundaries

The user can arrange an independent maintainer. No unassisted result has been
received: humanQualified:false. CI and the AI-authored exercise rehearsal are
not human comprehension evidence. Gather the participant result and fix actual
ambiguities. Next CLI work is compiler-origin structured diagnostics/editor
integration, then qualified watch/incremental dependency/cancellation behavior.
Automatic source packages/general extensions and additional platform publication
remain separate roadmap items. Source projects must never grant host authority.

Official Lean 4.35.0/eb6cafb7290e8bd5f2937522d8d804f58f02bafc, trust0,
independent admission, strict original/transformed IR, source/body pairing and
semantic fuel, negatives, memory/stack/lifetime policies remain unchanged.
Compiler/tool requests 240s; checker 120s. Manual G2/G3 correctness and original
240-second performance targets remain separate. No new G2/G3 qualification,
compiler-source promotion, whole-compiler preservation theorem, macOS/Windows
publication or final universal release is claimed. Kernel Wasm stays official
C++/Emscripten linear memory; compiler Wasm stays GC.
