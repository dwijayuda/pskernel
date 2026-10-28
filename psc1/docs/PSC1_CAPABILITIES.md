# Current capabilities and evidence scope

## Standalone compiler development

The [Linux x64 standalone profile](../standalone/README.md) has a separate
[2026-10-28 qualification](PSC1_INDEPENDENT_DEVELOPMENT_QUALIFICATION_2026-10-28.json).
It develops the full current 125-module `.ps` compiler using a bundled private
runtime and precompiled native official checker. Its baseline and changed-source
chains require actual generated compiler execution, fresh independent admission,
exact canonical artifact equality and observed changed diagnostic behavior.
No separate Lean/Lake, Node/Bun, TypeScript, Rust or C/C++ development toolchain
is required by that demonstrated cycle.

This establishes independent development in the delivered `.ps` workspace.
The repository still retains Lean bootstrap source ownership; the private runtime,
host and kernel are prebuilt components. The long correctness profile is distinct
from the unqualified 240-second full-compiler performance goal. This profile does
not broaden the npm target ABI or platform claims below.

## Earlier npm package qualifications

The newer [.9 layout milestone](PSC1_LAYOUT_QUALIFICATION_2026-10-26.json) passes
source 40344469855 (37/37 finite criteria), current-source WasmG1/40344458240 and
installed40344458391. It preserves the frozen122-module G3 source/executables;
current124-module source and its new ownership/module paths are qualified separately.
There is no new G2/G3, whole-compiler preservation or final cross-platform claim.
The .7 capability table and .8 CLI receipt below retain their original identities.

The newer [.8 project CLI](PSC1_CLI.md) is qualified separately in its
[exact receipt](PSC1_CLI_QUALIFICATION_2026-10-26.json). It retains the same frozen
G3 compiler/kernel executables and seven-target ABI scope. Three optional tools
have metadata-only .8 repacks; all worker/runtime files remain identical. The
.7 package table below keeps its original identity.

This page describes the **qualified installed .7 package**, not automatic
qualification of every later development commit. The distribution/provider
contracts define requirements; dated receipts bind actual runs to exact source
and artifact identities. [Work state](../AI_WORK_STATE.md) distinguishes current
development source from packaged compilers. Historical receipts stay immutable.

## Checked installed outputs

<!-- generated-capabilities:start -->
| Requested target | Compiler target | Explicit output consumer |
| --- | --- | --- |
| `js` | `js` | No additional SDK |
| `ts` | `ts` | Optional TypeScript 7.0.2 + pinned Linux x64 dependency |
| `rust` | `rust` | Optional Rust consumer .6 + exact Rust 1.90.0 SDK |
| `wasm-core` | `wasm-core` | Existing GC core; no additional SDK |
| `wasm-component` | `wasm-core` | Optional pinned wasm-tools; closed Bool ABI |
| `python` | `js` | Optional provider + bundled Python 3.14.8 |
| `php` | `js` | Optional provider + bundled PHP 8.5.12/GMP |
<!-- generated-capabilities:end -->

All rows describe actual Linux qualification in the
[dispatch receipt](PSC1_CHECKED_DISPATCH_QUALIFICATION_2026-10-26.json).
Actual installed run 40250645368 and source run 40250678016 pass. Final docs
40254268130 pass using that source baseline. These IDs are evidence for their
exact commits, not a moving latest-HEAD claim.

Default execution: genuine G3 JS/TS from one shared compiler source. Rust and
compiler-Wasm execution bundles are optional and separate from output consumers.
The checked API selects seven targets; compileCandidate selects only JS/TS/Rust/
Wasm-core and has no admission or publication authority.
Source metadata cannot select tools/checkers/output paths.

Default checking: genuine official Lean 4.35 C++/Emscripten **linear-memory Wasm**.
Native checking/comparison is explicit. Compiler-Wasm remains GC.
Missing/corrupt/refusing checking never falls back silently.
New optional native dispatch tools are qualified only on actual Ubuntu Linux x64.
Current generated components accept Bool public interfaces, at most 16 direct
parameters, supported WIT names and no imports/callback IO.
Both publication protocols retain immutable generations and explicit committed
uncertainty. Other-platform publication refuses.

## Qualified and incomplete are separate

- Practical Core v1 is frozen at 14 families / 37 finite criteria. It is not unrestricted Lean.
- Existing four-engine G1/G2/G3/fixed points remain attached to closure `073e5156`.
  A source extraction creates a new development closure; frozen executables are not relabeled.
- Lossless capture, ownership, finite conversion and bounded local rename are
  qualified candidate tools. General automatic semantic refactoring remains unqualified.
- Source libraries can be captured explicitly. Automatic npm source resolution
  and a public arbitrary-extension SDK remain incomplete.
- Optional providers are closed and pinned; package metadata grants no host,
  kernel, FFI or publication authority.
- Broader generated component String/IO, full provider application acceptance,
  additional native platforms and final clean universal release remain queued.
- The original 240-second compiler self-compilation performance target remains unqualified.
- No whole-compiler preservation proof, merge or npm publication is claimed.

See [the one roadmap](PSC1_DEVELOPMENT_ROADMAP.md),
[distribution requirements](../NPM_DISTRIBUTION_CONTRACT.json),
[provider protocols](../BACKEND_PROVIDER_CONTRACT.json) and
[exact install guide](PSC1_CHECKED_DISPATCH_INSTALL.md).
scripts/maintainer-docs.mjs checks this table against those contracts and checks
source-linked walkthrough anchors. It does not create runtime authority or CI evidence.
