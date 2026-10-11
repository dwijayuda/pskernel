# PSKernel-C0 — Active PSC0 fork

- Source branch: `psc0/pscv0-v7-native-lean-v1`
- Source commit: `a8fbc17f1ad2d24efbde14a7cbe993a4400d4c01`
- Original package: `psc0/packages/pskernel-core` (untouched)
- Copy: `psc0/packages/pskernel-c0`
- Rust backend available in sibling `psc0/packages/backend-rust`.
- Status: source package duplicated. C0 is not yet independently namespace-isolated, benchmarked or integrated into the PSC0 build. No performance gains are claimed.

## Direction

Prioritize major performance architecture changes, especially compact term storage, shared structure, substitution, demand-driven WHNF/DefEq, and declaration-local allocation. Defer metatheory/consistency proof work. Preserve kernel semantic acceptance and compare against the source kernel before integration. Keep the active PSC0 compiler and Rust backend unchanged until C0 meets explicit compatibility and performance gates.
