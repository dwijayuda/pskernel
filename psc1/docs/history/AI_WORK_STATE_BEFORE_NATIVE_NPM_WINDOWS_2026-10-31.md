# PSC1 AI work state

Updated 2026-10-31 Asia/Jakarta. Native work remains on PR217,
`feat/psc1-native-rust-lean435-20261031`, stacked on qualified PR216.
The measured packaging implementation was developed separately on
`perf/psc1-native-delivery-20261031` to avoid rebuilding unchanged compiler sources.
Preserve expected-HEAD, single-parent, non-force history and Linux Actions only.
No main merge or npm publication is authorized.

## Completed native developer milestone

The actual Rust-native G1 build and native Lean checked preview passed
[41177075940](https://github.com/dwijayuda/pskernel/actions/runs/41177075940),
job124466784147, at a3013ea35c48fde083f9efa0a8a4a963e6a3fcb5.
It captures133 current owned compiler source modules, source closure
67ce17c1a92b893af8ce7bb915a64164236cedd31ed256f7952fc95dc52565ad.
This matches the modular JS/TS source closure but does NOT provide Rust G2/G3.
The original four-output G1 corpus and the new native checked preview passed.
Original G1 executable SHA2561467e30ba1dc579b389758a393b3d4781ae24835585429690317411902e92e75.

The relocatable Linux x64 native package passed
[41179915274](https://github.com/dwijayuda/pskernel/actions/runs/41179915274),
job124475029582, at implementation2d4edd272577f2b44a3fde41b1a0b927b822e413.
[Download verified artifact](https://github.com/dwijayuda/pskernel/actions/runs/41179915274/artifacts/13034039084)
(GitHub sign-in may be required). Artifact ZIP SHA256
1d6fcfb68e6466f54a03e816bb27bdff37b9fc81f84adf8870450cf3f3374619.
Inner `proofscript-native-linux-x64.tar.gz`:12701770bytes, SHA256
7637b93e42cf297056f92bf9d0f8f3d37e846be8f7f855e08b11cac489695c7d.
The package includes the actual native Rust compiler, previously qualified slim
native Lean4.35 kernel, unchanged checked host, examples, licenses and evidence.
It requires Node for host orchestration, not a Lean/Rust SDK or install-time build.
The packaged CLI currently supports checked JS output only.

## Measured improvement and safeguards

Same-runner alternating cold-process comparison, three trials per source grammar:
workspace preview median1505.6423529999993ms versus packaged native
1308.4475709999988ms; observed reduction13.097053334551134%.
Both variants use the SAME slim native kernel and source inputs, with exact
emitted-source/IR/admission equality. These are tiny-program observations,
not a Rust-vs-JS comparison or full-self-compilation result.

Runtime-only manifests avoid hashing build/source evidence on each command.
Setup-only resource-read coalescing reuses the existing host mechanism.
The native compiler shrank40843784->35368000bytes after stripping non-runtime
symbols; program headers, entry, and all30 allocated sections remain identical.
GNU strip normalized `.init_array.sh_entsize` from0to8. The packager restores
that original field outside every loadable segment and reruns the full strict
identity comparison. It does not ignore a mismatch or patch executable code.
All unsupported differences retain the exact original binary instead.

Qualification executes five real corpus applications including modules, Unicode/
large integers, lists, exception handlers and ordinary loops, with exact retained
source/IR/admission parity. Fourteen native-kernel acceptance/refusal fixtures,
compiler/kernel/host tamper refusals, invalid typed source and previous-output
preservation pass. The exact delivered archive is extracted to a different path
and tested with compiler SDKs absent from PATH.

See [exact summary](docs/PSC1_NATIVE_DELIVERY_QUALIFICATION_2026-10-31.json),
[native guide](docs/architecture/native-rust-lean435-preview.md), and
[native work record](docs/PSC1_NATIVE_DELIVERY_WORK_STATE.md).
The complete machine-generated report is retained as QUALIFICATION.json beside
the tarball; repository summaries do not grant admission authority.

## Explicitly unfinished

Current-source Rust G2/G3 and full self-rebuild performance are unqualified.
No four-minute or universal fastest-compiler claim is made. The compiler still
uses the existing opt0/256-codegen-unit native build; stripping is packaging,
not a compiler algorithm optimization. Node-free CLI, broader packaged output
consumers and non-Linux native release testing remain separate work.

Next: preserve this working artifact, profile the exact current Rust G1 on its
full compiler request under existing bounded policies, then optimize measured
string/lookup/allocation/IR costs and qualify real G2/G3. Measure build and runtime
costs separately before selecting release optimization. Do not rerun unchanged
G1/G2/G3 merely for host documentation or artifact delivery.

## Preserved tracks and history

The qualified modular JS/TS .10 distribution, Wasm default, all seven backends,
optional Python/PHP, native kernel source pin, strict original/transformed IR,
fresh independent admission, fuel4096 and existing compiler/checker limits are
unchanged. No source compiler, kernel or established package is replaced by this
preview. PSKernel-Min remains a separate research track.

The full previous checkpoint is retained byte-for-byte at
[history](docs/history/AI_WORK_STATE_BEFORE_NATIVE_DELIVERY_2026-10-31.md).
The general remaining-work queue stays in
[PSC1_DEVELOPMENT_ROADMAP.md](docs/PSC1_DEVELOPMENT_ROADMAP.md).
The present record updates native delivery evidence only. Native package
qualification, broader source gates and retained historical CLI suites remain
distinct; do not transfer a pass across source or runtime package identities.
