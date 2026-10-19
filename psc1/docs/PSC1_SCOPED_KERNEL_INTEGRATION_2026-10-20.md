# PSC1 scoped kernel correctness integration

The 17 updated native kernel modules and their supporting portable-source compatibility changes were copied **by identical Git blob SHA**, from the successful correction branch `fix/psc1-pskernel-core-cross-branch-20261020`, commit `0a53836489c4e88f46df8f5b8b0c19cc41bafbbb`. Its native regression qualified at [Actions #39316092939](https://github.com/dwijayuda/pskernel/actions/runs/39316092939).

This branch retains Lean 4.34.0 and the source grammar, adds no language features and invokes only the isolated native kernel build and focused regression tests. It does not run complete kernel self-host tests, reconstruct all source, or claim native DirectJS/Rust/Wasm obtains independent kernel-admission authority. That trust integration is still separate.

The IR-specialization postcheck and source-map regression changes on this branch are separate from the transferred kernel files.
