# PSC1 scoped correctness repair — 2026-10-20

## Scope and baseline

This work stays on `fix/psc1-scoped-correctness-20261020`, based on bounded hardening
`0fd7b9aa8bc2f51b21e0cd9477edde35063de0e4`. The baseline passed Linux Actions run
39322348232. It already contains the corrected PSKernel-Core source, specialization
input/output revalidation, and independent official Lean admission for native direct
output. New changes require their own exact-commit CI results; the baseline result
must not be presented as qualification of these repairs.

No substantial language feature, Lean pin upgrade, full compiler/kernel self-host
suite, unchecked-admission mode, or automatic npm publication is introduced.

## Current checked output architecture

```text
captured source closure (each file read once; canonical paths; cycle checks)
  -> existing parser/resolver/elaborator
  -> exact immutable canonical declaration graph
  -> independent official Lean 4.34.0 kernel admission
  -> erasure of that same graph
  -> bounded typed-IR validation
  -> specialization with input AND output revalidation
  -> entry-module public API and privately linked dependencies
  -> target printing / target checks
  -> formatting and final-layout source-map observation
  -> complete checksummed staged generation
  -> one atomic current-pointer replacement
```

The corrected **PSKernel-Core** is integrated in source and has its own native
regressions. The **official Lean kernel** is the current independent authority for
direct compiler output. These are different facts; this repair does not pretend the
owned kernel is already the default provider, or that either source checker proves
backend semantic preservation.

## Readable outputs

JS and TS use exact Prettier/Babel versions. Formatting is accepted only when the
normalized parsed syntax trees before and after match. Original declaration names
and normal public signatures are retained; no minification is used. Maps are built
from the final formatted AST, including all captured source texts, UTF-16 columns,
correct negative VLQ deltas and explicit generated-only boundaries. Map granularity
is declaration-level, not expression-level debugging.

Rust is formatted with rustfmt and ships a ready-to-build sibling `.cargo` directory
with exact direct dependency versions, Cargo.lock and a successful locked Cargo
check. The raw `.rs` and crate `src/lib.rs` are identical. WIT is indented source and
its full bounded scalar API is structurally compared to the observed component WIT.
WAT is the actual final binary printed by wasm-tools, not a fabricated reconstruction.

Install the host-only dependencies with `npm ci --prefix psc1/host-tools` after the
lockfile is committed. During first qualification the workflow captures the generated
lockfile for review. These dependencies are disclosed host formatting/I/O utilities,
not compiler elaboration or proof-checking authorities.

## Transaction contract

Every output owns a hidden store next to its requested filename:

```text
.module.js.psc1/
  generations/<content hash>/
    module.js
    module.d.ts
    module.js.map
    admissions.json
    psc1-input.json
    manifest.json
  current -> generations/<content hash>
module.js -> .module.js.psc1/current/module.js
module.d.ts -> .module.js.psc1/current/module.d.ts
module.js.map -> .module.js.psc1/current/module.js.map
module.js.bundle.json -> .module.js.psc1/current/manifest.json
```

A failed build leaves the previous accepted generation intact. Initial failed builds
can leave harmless dangling managed aliases or private stages, never a partially
accepted generation. Existing ordinary user files and foreign symlinks are not
silently overwritten. Use a new output path for migration from legacy flat output.
Linux is the qualified publication platform. Old generations are retained deliberately.
Readers requiring a multi-file consistent read must resolve the generation path once,
then read its files; separate alias opens spanning a concurrent publication can see
different complete generations. No claim of a global filesystem snapshot or proven
power-failure durability is made.

A bundle manifest records content hashes and the declared pipeline profile. It is
not a standalone mathematical proof or a signature authenticating arbitrary callers
of the host I/O helper. Trusted native emission reaches the helper only through the
private-constructor checked session.

## Native/npm command identity

`psc1/npm-cli/psc.js` is a transport launcher for the same native executable. It
checks the `psc1-native/1` identity and never falls back to archived generated PSC0
compiler/kernel artifacts. Set `PSC1_NATIVE` to a qualified executable and
`PSC1_HOST_TOOLS` to the installed `artifacts.mjs` file when not using the workspace
layout. The launcher remains private until platform binaries and installation
provenance are qualified. Historical generated packages and old self-host records
are retained as history, not claimed current distribution products.

## Qualification

The scoped Linux workflow checks the independent provider, forged IR rejection,
kernel correctness regressions, both source forms, JS/TS execution, declaration
consumers, imported helper visibility, snapshots, source maps, Rust locked builds,
Wasm/WAT roundtrips, component ABI identities and negative publication paths.
It deliberately does not regenerate the compiler or kernel, run full source self
checks, or assert a bootstrap fixed point.

The audit's full incremental compilation, runtime extraction/tree-shaking, formal
specialization-preservation proofs, expression-level source maps, and distributable
native npm artifacts remain separate work. They are not silently renamed completed.
