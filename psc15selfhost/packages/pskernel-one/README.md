# pskernel-one

An owned PSC1 kernel workstream targeting the complete pinned Lean 4.34 kernel.
This package is currently a **Name/Level foundation**, not a declaration checker,
bootstrap-capable kernel, provider, or self-hosted kernel. It is private and cannot
authorize checked emission. Full capability remains the release requirement.

Handwritten semantics live in `src/Ps/KernelOne/*.lean`. Canonical `.ps` is generated
by PSC; it is not independently edited. The package does not import KernelCore,
PSC1Kernel, Lean, Std, compiler services, IO or original C++/Wasm checking.

The initial change repairs comparison of normalized nested `max` leaves. It
compares both inclusions to support association, order and duplicate leaves while
rejecting a missing leaf. This is **not complete universe equivalence**: offsets,
successor distribution and nested imax congruence still need pinned normalization.
The internal Boolean comparison is not a provider accept/reject result.

From `psc15selfhost/`, implemented commands are:

```sh
lake exe pskernel_one_level_tests
lake build psc1
node scripts/pskernel-one-profile.mjs
node scripts/pskernel-one-profile.mjs --emit
lake exe pskernel_one_nat_boundary_tests
node scripts/pskernel-one-nat-runtime.mjs
node scripts/pskernel-one-runtime.mjs
```

The source profile checks its committed manifest, snapshots the four sources,
rejects external imports and symlink paths, calls the actual PSC frontend, emits
canonical PS and checks that PS again. `--emit` additionally requests TypeScript;
it only establishes emission. The separate runtime command invokes real `tsc`
and currently fails on the function-returning call-convention blocker. No
generated kernel execution or fixed point is claimed. `PSC1` selects an
explicit seed executable; its SHA-256 is recorded. `TSC` selects an installed real
TypeScript compiler for both runtime tests (pinned CI version 5.8.3).

`SOURCE_MANIFEST.json`, `LEAN_SOURCE_PIN.json`, `CAPABILITIES.json` and `SIZE.json`
are the initial machine-readable contract. Source changes require an explicit
`node scripts/pskernel-one-profile.mjs --write-manifest` after reviewing the diff.
This manifest is source identity, **not an acceptance proof**.

See `../../docs/pskernel-one/ARCHITECTURE.md`, `RESEARCH.md`, and `CONTINUATION.md`
for trust, source lineage, evidence, limitations and the next gate.
