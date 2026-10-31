# Native Rust PSC1 + native Lean 4.35 developer preview

The native compiler and native kernel now have a tested, relocatable Linux x64
package. The compiler is generated from the existing133-module owned PSC1 source,
not handwritten Rust compiler logic. Node remains the trusted orchestration layer.
This is a G1 developer preview, not a current-source Rust G2/G3-qualified release.

## Get the tested package

[Verified delivery artifact](https://github.com/dwijayuda/pskernel/actions/runs/41179915274/artifacts/13034039084)
from successful [run41179915274](https://github.com/dwijayuda/pskernel/actions/runs/41179915274),
implementation2d4edd272577f2b44a3fde41b1a0b927b822e413.
The artifact contains the native tarball, machine report, checksums and INSTALL.md.
GitHub sign-in may be required. After extracting the outer artifact:

```sh
sha256sum -c SHA256SUMS
tar -xzf proofscript-native-linux-x64.tar.gz
cd proofscript-native-linux-x64
node bin/psc --identity
node bin/psc compile examples/Main.ps
node bin/psc build examples/Main.ps --out ./out
```

Tested environment: Linux x64/glibc, Ubuntu24.04, Node22.23.3. Requires Node for
host orchestration, but no Lean SDK, Rust SDK, npm dependency installation, or
install-time build. Supported source inputs are `.ps` and the PSC1 `.lean` subset;
`-p` selects an explicit source project. Packaged output is JS only.
`check` follows the same full checked compilation path without returning source.
No directory search, fallback to a different compiler or checker, or SDK download.

Inner archive12701770bytes, SHA256
7637b93e42cf297056f92bf9d0f8f3d37e846be8f7f855e08b11cac489695c7d.
[Exact repository summary](../PSC1_NATIVE_DELIVERY_QUALIFICATION_2026-10-31.json)
records all source/artifact identities. The full machine report is retained
beside the delivered tarball, not substituted by the summary.

## Performance change

Runtime-only manifests and setup-scoped identity-read coalescing avoid repeatedly
reading generated Rust source and audit evidence. Every runtime file and native
binary is still checked, and every issued compilation independently admits its
canonical graph through official Lean before output publication.

Same-runner paired tiny-program cold-process median:1505.64ms ->1308.45ms,
13.1% less time. Six calls per variant, alternating order, two source grammars;
identical slim native kernel, source, emitted output, IR and admissions.
These numbers are not a full compiler rebuild or Rust-versus-JS benchmark.

The native executable shrinks40,843,784to35,368,000bytes through symbol removal.
The ELF audit preserves identical program headers, entry and all30 allocated
sections. GNU strip's normalization of one nonloaded `.init_array` header field
is reversed to its exact original value before the final identity check.
If any other difference remains, the packager retains the original binary.
Compiler source algorithms and Rust opt0/256-unit generation are unchanged.

## Qualification

The actual G1 build passed [41177075940](https://github.com/dwijayuda/pskernel/actions/runs/41177075940)
at a3013ea35c48fde083f9efa0a8a4a963e6a3fcb5. It uses the existing source census,
unified Rust generator and independent Lean checker, with four output-target
corpora and refusal tests. The packaged compiler source closure
67ce17c1a92b893af8ce7bb915a64164236cedd31ed256f7952fc95dc52565ad
matches the current modular JS/TS source closure; qualification is still separate.

Delivery reuses the exact G1 artifact and qualified slim native Lean kernel.
It tests relocated extraction with SDKs absent from PATH, actual execution of
five programs, exact source/IR/admission parity,14 kernel acceptance/refusal
fixtures, invalid source, compiler/kernel/host tampering, and preservation of
the previous published generation after a failed edit.

The original `createGeneratedJsCompilerSession` and bounded Rust process guard
remain unchanged. The class name is historical: the semantic compiler is native
Rust, and the checker executable is native official Lean. Source/wire data cannot
choose either executable. Original/transformed IR, source/origin binding, target
syntax/API checks, independent admission and transactional output remain required.

## Remaining work

Native current-source G2/G3 and full self-rebuild timing remain unqualified.
There is no240-second or universal fastest-compiler claim. Node-free CLI, additional
packaged output consumers and non-Linux whole-toolchain releases need separate
implementation and qualification. The existing modular .10 JS/TS/Wasm-default
distribution, all backends, optional providers, published resource policies and
fuel4096 are preserved. No merge into main or npm registry publication.
