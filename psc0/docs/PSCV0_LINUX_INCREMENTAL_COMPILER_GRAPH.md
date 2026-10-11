# PSC0 v7 compiler-only incremental source graph (Linux development)

**Date:** 2026-10-11. **Branch:** `psc0/pscv0-compiler-fast-loop-v1`. **Normative .ps authority:** the exact [PSCV0 v7 language reference](../PSCV0_LANGUAGE_REFERENCE.md), SHA-256 `843940bd7f6a9b286e80b01d8c891a7e01b8868a9de7b05833fce32d49be6cd5`. No older .ps compatibility mode.

## Goal and actual source dependencies

Previous compiler-only CI validated individual v7-authored `Ps.Foundation.Source` and `Ps.Foundation.List` modules, each producing **byte-identical canonical admissions and TypeScript 7 output** compared to its retained Lean source. The older per-module harness restarted the compiler's elaboration environment from scratch for each candidate. The next engineering requirement is **source-graph-aware preparation and shared-prefix reuse** for dependent compiler modules—without rerunning an entire 20-module source generation on each edit.

The smallest useful subgraph is grounded in the retained source imports:

```text
Ps.Foundation.Source (.ps candidate | retained .lean)
  ├── Ps.Syntax.Cursor (.lean, imports Source)
  └── Ps.Syntax.Token (.lean, imports Source)

Ps.Foundation.List (.ps candidate | retained .lean, no imports)
```

Both `Cursor` and `Token` depend on `Source`, so migration must preserve their **typed shared environment**, not merely compare each file as an isolated declaration. A manifest-selected root and its transitive exact imports define the topological preparation order. There is no hidden fallback to the old `.ps` parser: when a candidate is selected, only the generated v7 source reader and the closed recipient-owned AST ABI are used.

## In-memory source-prefix cache

The [incremental compiler source graph driver](../tools/abi/compiler-graph.mjs) reads [its exact source-graph manifest](../pscv0-fast-graph.json) and the [v7 candidate registry](../pscv0-fast-candidates.json). It verifies cached frontend provenance against the **source SHA-256 of each of the 20 qualified historical syntax/foundation modules**, the pinned actual generated bootstrap JavaScript and retained compiler package. This verification is now shared through [qualified-cache.mjs](../tools/abi/qualified-cache.mjs).

A prefix cache key depends on the complete preceding key plus each module's name, source kind (historical Lean or new v7) and exact raw source SHA-256. **All preparation states exist only in the current compiler process, never serialized or loaded as checker authority.** A changed predecessor creates a different key, preventing an obsolete environment from being reused for a changed module. This implements the existing compiler's pure `psCompilerPreparationStepParsedWithOrigins` API, not a new kernel or type system.

The four acceptance scenarios are:
1. Entire retained Lean baseline.
2. V7 `List` with original `Source`, `Cursor` and `Token`.
3. V7 `Source` with original `Cursor`, `Token` and `List`.
4. Both v7 `Source` and v7 `List`, retaining `Cursor`/`Token` until independently migrated.

For all four, the final ordered declarations must yield **byte-identical canonical compiler admission stream and emitted TypeScript 7 program**. The graph check records distinct prepared prefixes, **actual prefix-cache hits**, parsed-module reuse, source/import digests and elapsed CPU process time. After proving identical compiler outputs, the one Linux TypeScript 7 build and Node runtime exercises list length/empty/reverse, token-kind comparisons and cursor completion. **None is a kernel checker test or verified source-to-core theorem.**

## Linux-only development policy and Windows portability patterns

Per explicit user decision, **only Linux CI is executed at this stage**. The current jobs use `runs-on: ubuntu-latest`. **Do not schedule, call, or require Windows runners** for these compiler-development iterations; do not execute the historic cross-platform bridge while iterating on these unpromoted candidates. Windows portability is a design/static-review pattern, not a tested guarantee. Apply these patterns when editing compiler host code:

- Build paths using Node `path.join`/`path.resolve` and load JavaScript via `pathToFileURL`, not hard-coded forward-slash executable paths or shell-specific invocations.
- Parse import/module names as logical POSIX-independent source identifiers; derive each real file path with the host OS path package, and reject noncanonical paths and `..` traversal.
- Use UTF-8/byte SHA-256 for source and artifact identities; normalize input only when the language grammar explicitly owns that normalization. Preserve original source bytes and source positions.
- Keep the TypeScript target and JS runtime semantics platform-neutral; no platform-specific behavior is allowed to influence typing, source tree ownership or admission results.
- Treat **Windows as unverified** until a later explicit cross-platform milestone; a static review is **not** a Windows test pass.

The code path does not test PSKernel, differential kernel compatibility, kernel metatheory or proof admission in this loop. Canonical admissions are serialized only as compiler-generated comparison products. The production release and independent checked-assurance gates remain separate, unchanged, and not invoked by this development workflow. No source candidate has been automatically promoted to the full compiler-source master.

## Evidence and next steps

Existing successful source/ABI qualification: [full generated first-module bridge 38128357665](https://github.com/dwijayuda/pskernel/actions/runs/38128357665), [fast compiler loop 38130403756](https://github.com/dwijayuda/pskernel/actions/runs/38130403756), [two-module source differential 38131142962](https://github.com/dwijayuda/pskernel/actions/runs/38131142962). **The new incremental-graph workflow must obtain its own green Linux CI result** before counting dependency-closure qualification or timing savings; no new pass is claimed by this design document.

After the graph passes, introduce a genuinely dependent v7-authored module such as `Ps.Syntax.Cursor` as an additional optional source candidate. Keep exact import closure, type-directed evaluation, source locations and no fallback. Then advance toward intentional compiler-only source closure promotion; do not assume the full PSC0 compiler is already self-hosting on v7.
