# Semantic source location

No kernel implementation is present here yet. The planned source root is
`src/Ps/Kernel/`, separate from the legacy `Ps.KernelCore` modules preserved in
`../pskernel-core.old/src/`. See `../ARCHITECTURE.md` for the module contract.
Do not import or copy legacy checking authority into this package implicitly.
The manifest keeps `portable: false` until real portable semantic sources and
their compilation/execution gates exist; this is not the final target profile.
