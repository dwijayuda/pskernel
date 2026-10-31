# Native PSC1 delivery work state — 2026-10-31

Base: a3013ea35c48fde083f9efa0a8a4a963e6a3fcb5, PR217 native preview.
Work branch: perf/psc1-native-delivery-20261031.

Actual baseline run 41177075940 / job124466784147 **passed** current-source
Rust-native G1 (133 owned source modules; source digest67ce17c1a92b893af8ce7bb915a64164236cedd31ed256f7952fc95dc52565ad),
all four output-target G1 corpora/refusals, and the native Lean checked preview.
The immutable artifact13033925109 has ZIP SHA256
475f3043e3b80dc92f0714221afcb573b3fd77a056ee444548b49e60b4537895.
This is the same source closure as the modular JS/TS cohort, but is not its
Rust G2/G3/fixed-point or installed-engine qualification.

Tiny cold CLI samples were about2.56–2.59s total,0.48–0.49s compiler transport,
0.038–0.042s native kernel. The existing preview reads the complete generated
Rust artifact/source inventory on each call. That is diagnostic/build evidence,
not needed for repeatedly executing the already qualified exact binary.

This follow-up reuses the exact admitted binary, strips only non-allocated ELF
symbols, and verifies unchanged program headers/entry/allocated sections. It
packages the existing checked host and exact official native Lean4.35 provider,
with runtime-only identity manifests. Generated Rust sources and qualification
reports remain in immutable inputs/evidence, not the request hot path.

CI qualifies relocated extraction, empty SDK PATH, actual five-corpus JS runtime
observations, exact source/IR/admission parity, fourteen native-kernel fixtures,
tampering refusal and preservation of prior publication. A same-runner alternating
cold comparison uses the same official native kernel for both the workspace
control and packaged host. It does not relabel the historical Lake checker or
make any full-self-build claim. The new package outcome and measured improvement
are pending its actual CI. No merge, npm publication, semantic/fuel relaxation,
proof-admission cache, new frontend or kernel replacement is authorized.

The original opt0/256-codegen-unit native compiler remains; no unchecked compiler
source optimization is hidden in packaging. Node remains the host, and output is
JS. Rust G2/G3, release-native optimization and broader platform/output delivery
remain separate work. Only adopt a passed package with its exact tested SHA.
