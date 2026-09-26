# PSCKernel Fresh-Port Progress

Branch: `selfhost/psckernel-fresh-port`

Production authority remains the handwritten TypeScript `lean-ts-kernel`. PSCKernel is an independent PSC1-compatible Lean implementation under differential validation; this ledger intentionally tracks different notions of progress separately.

## Current checkpoint

Last completed feature slice: `Core/Name`

Verification checkpoint: `fce2e2f5defa65ffad9e756a7a38e9701bc9a681`

Fresh-port workflow run: `36233949520`

Pinned semantic authority: Lean `4.34.0`, githash `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`.

Upstream `selfhost/psc1-lean-bootstrap` checked after the `Name` milestone remains at `20c44dec16de2aacfaaba8447ad7c3c5ed4cc972`; there is no upstream drift to integrate at this checkpoint.

## Progressive parity dimensions

| Dimension | Current state | Evidence / next gate |
| --- | --- | --- |
| Structural files ported | **1 / 29** planned mirror files | `Core/Name.lean` exists. Next: `Core/Level.lean`. |
| Compiling files | **1 / 29** | `lake build PsPSCKernel` passes with `Core/Name`. |
| Unit semantic coverage | **Name: 13 passing cases** | `lake exe psckernel_name_tests` reports 13/13 PASS. |
| TS differential parity | **Name: 12 parity cases** | `scripts/psckernel-name-differential.mjs` passes. |
| Lean 4.34 oracle coverage | **Name: 2 explicitly classified TS deviations** plus Lean-authoritative ordering/replacement regressions | `NAME_ORACLE_DEVIATIONS.md`; differential accepts exactly two deviations. |
| Real corpus replay | **Not started** | Begins only after enough core/type-checker surface exists to consume real declarations. |
| `.lean -> .ps` readiness | **Not tested** | Portable source profile passes, but canonical `.ps` generation is not yet claimed. |
| Generated TS/JS kernel | **Not started** | Requires sufficient PSCKernel source plus self-host compiler support. |
| Production cutover | **Not started** | Production kernel remains `lean-ts-kernel`. |
| Kernel self-hosting | **Not started** | Requires generated kernel and bootstrap closure. |
| Fixed point | **Not started** | Requires repeated self-host generations with stable output/behavior. |

The `1 / 29` structural denominator is the literal file mirror enumerated by the approved fresh-port design: 8 `Core` files, 18 `Kernel` files (including subdirectories), 2 `Integration` files, and the public `Ps/PSCKernel.lean` barrel. It is not a semantic-completeness percentage.

## Completed `Core/Name` gates

- workspace shape: PASS, 18 workspaces;
- PSC1 portable source profile: PASS, 86 portable modules across 16 source roots;
- `PsPSCKernel` Lake build: PASS;
- `psckernel_name_tests`: PASS, 13/13;
- root TypeScript kernel build: PASS;
- TS ↔ PSCKernel `Name` differential: PASS, 12 parity cases;
- classified Lean-4.34 deviations: exactly 2 (`replacePrefix` nonmatch and anonymous display).

## Next dependency-ordered slice

`Core/Level` is next. It must reuse only the independently authored `PsCKernelName` representation from this package, not `Ps.Foundation.Name`, `@proofscript/core`, or the existing PSC1 kernel. Its implementation plan must cover raw/smart constructors, structural equality, parameter/metavariable traversal, offsets, instantiation, normalization, equivalence/order relations, string rendering where present, TS differential fixtures, and Lean 4.34 oracle regressions.
