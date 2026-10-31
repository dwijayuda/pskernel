# Native PSC1 delivery — verified milestone, 2026-10-31

The current-source Rust G1 and native checked host passed run41177075940 at
a3013ea35c48fde083f9efa0a8a4a963e6a3fcb5. The source closure is133 modules,
digest67ce17c1a92b893af8ce7bb915a64164236cedd31ed256f7952fc95dc52565ad.
It matches the modular JS/TS source closure; Rust G2/G3 are not qualified.

## Tested package

Implementation2d4edd272577f2b44a3fde41b1a0b927b822e413 passed Linux
[run41179915274](https://github.com/dwijayuda/pskernel/actions/runs/41179915274),
job124475029582. [Artifact13034039084](https://github.com/dwijayuda/pskernel/actions/runs/41179915274/artifacts/13034039084)
contains the exact tested native tarball, full machine QUALIFICATION.json,
SHA256SUMS and installation instructions. No compiler/kernel rebuild was
performed for this packaging experiment.

The archive is12701770bytes, SHA256
7637b93e42cf297056f92bf9d0f8f3d37e846be8f7f855e08b11cac489695c7d.
The artifact ZIP SHA256 is
1d6fcfb68e6466f54a03e816bb27bdff37b9fc81f84adf8870450cf3f3374619.

The runtime-only manifest omits generated source/build evidence from per-request
verification but retains exact binary and every runtime-host identity check.
Setup coalescing is scoped to construction, never admission or publication.
The official native Lean4.35 kernel is reused from its qualified slim package.
Node remains host orchestration; no Lean/Rust SDK or install-time build is
required for packaged JS output. Linux x64/glibc only, tested Node22.23.3.

## Measurements and limitations

Same-runner, same-kernel paired median: workspace1505.642353ms ->
package1308.447571ms,13.0971% less time, six trials per variant across two grammars.
Exact emitted source, both IR values and admissions agree. This is a tiny-program
cold-process result, not a full-self-build result or a cross-engine comparison.

Compiler binary40843784->35368000bytes. A strict ELF comparison first rejected
GNU strip because it changed only `.init_array.sh_entsize` from0to8; the first
successful package retained the original executable. The final package restores
that original metadata outside all loadable segments, then requires identical
program headers/entry and all30 allocated sections. Executable instructions and
allocated data are not patched. Unexplained differences still retain original
bytes instead. Full actual runtime parity and corruption refusals then pass.

Five corpus programs execute with exact source/IR/admission parity. Fourteen
native kernel fixtures, typed-source refusal, compiler/kernel/host corruption
refusal, relocation/SDK-free PATH and previous-publication preservation pass.
The qualification tests the archive after extraction, not merely the assembly
folder. The raw reports remain immutable and earlier failures are preserved.

## Next measured work

Preserve this downloadable G1 package. Profile the current Rust G1 on the exact
full compiler request before choosing lookup/string/allocation/IR optimizations.
Separate native compiler execution from Rust tool build time and native kernel
admission. Current opt0/256-unit build policy and all semantic/resource limits
remain unchanged. Actual Rust G2/G3, full-self-build performance, broader packaged
targets/platforms and a Node-free host remain incomplete. No main merge or npm
publication. See the canonical AI_WORK_STATE.md and exact qualification summary.
