# pskernel

An independent TypeScript reimplementation of the **Lean 4.34.0 trusted kernel**, developed for ProofScript kernel research.

This repository is intentionally version-pinned. Lean 4.34.0 is the compatibility oracle; Lean4Lean is a secondary implementation/verification guide. The project does **not** claim full Lean compatibility or formal equivalence until the remaining gates in `PROGRESS.json` are closed.

## Current verified surface

The current implementation includes Lean core names/levels/expressions, substitution and local contexts, type inference, WHNF and kernel reduction, algorithmic definitional equality, quotients, ordinary/mutual/indexed/nested inductives, recursor generation/reduction, Lean 4.34 primitive recognition, `lean4export` 3.1.0 replay, resource limits, and identity-keyed kernel caches.

The pinned regression stack includes:

- 97 TypeScript kernel/unit tests
- official Lean 4.34 fresh-module checking
- official Lean 4.34 adversarial kernel regressions (21 expected-success + 1 expected-rejection)
- official-vs-TypeScript definitional-equality differential cases (42/42)
- complete `Init.Prelude` replay
- primitive dependency closure through `Nat.mod`, `Nat.div`, `Nat.gcd`, and `Nat.bitwise`
- bounded `Std` corpora (Parsec, SAT/CNF, ByteSlice)
- bounded `Lean.*` corpora (RBMap, PersistentArray, PersistentHashMap)
- a separate full imported `Lean.Data.RBMap` large-corpus gate

See `docs/CONFORMANCE.md` and `PROGRESS.json` for exact counts and remaining gates.

## Quick start

```bash
npm install
npm test
```

The corpus/oracle gates additionally require the pinned Lean toolchain and generated fixtures:

```bash
elan toolchain install leanprover/lean4:v4.34.0
./scripts/generate-oracle-fixtures.sh
npm run check:corpus
```

For the official adversarial source-file oracle, set `LEAN434_SRC` to a Lean 4.34.0 source checkout. Set `LEAN434_BIN` when the Lean 4.34 binaries are not already discoverable at the project-specific local path.

## Architecture / anti-drift

- `src/core/` — immutable core data model and substitution/context machinery
- `src/kernel/` — trusted checker, reduction, inductives, quotients, primitive recognizers
- `src/integration/` — exact JSON and lean4export replay boundary
- `oracle/replay-probe/` — Lean-side dependency-aware exporters
- `oracle/fixtures/` — generated, pinned replay corpora
- `scripts/` — oracle, corpus, differential, and anti-drift gates
- `docs/ANTI_DRIFT.md` — scope and compatibility rules

Final Lean 4.34 removes the deprecated in-kernel `Lean.reduceNat` / `Lean.reduceBool` compiler-interpreter reduction path. pskernel therefore has no NativeEvaluator/native-reduction kernel extension in the 4.34 profile.

Do not silently broaden acceptance to make a corpus pass. A Lean/TypeScript mismatch must be isolated and fixed at the semantic layer that differs from Lean 4.34.0.

## Additional assurance gates

### Arena correctness suite

The external Lean Kernel Arena static corpus can be checked without vendoring it into this repository:

```bash
npm run build
node scripts/arena-static-oracle.mjs /path/to/extracted-arena-tests
```

By default this checks correctness/adversarial cases and excludes `perf/`. Arena files are replayed using their recorded Lean version only at the test-harness boundary; this is cross-version compatibility evidence, not a replacement for the pinned Lean 4.34 oracle. Heavy Arena workers use an enlarged JS stack (`ARENA_STACK_KIB`, default 65500) while pskernel's own recursion budget remains the semantic guard.

### Canonical full Std replay

For release/nightly assurance, prefer the one-pass module-order stream over repeated dependency closures:

```bash
# Lean 4.34.0 must be on PATH, or set LEAN434_BIN.
npm run oracle:std-full
```

The default Node heap is 12 GiB. Override it with `PSKERNEL_STD_HEAP_MIB`. The runner keeps the checked environment but discards replay-local intern tables/caches between module shards.


On Windows/PowerShell, the repository includes a helper that validates Node/Lean, builds pskernel, runs the canonical stream with a 12 GiB heap / enlarged isolated-process stack, and writes a single log:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run-full-std-local.ps1
```

If memory is limited, override the heap, for example `-HeapMiB 8192`. On a machine with 24–32 GiB RAM, the default 12288 MiB is preferred. Send back `full-std.log` if the run fails or when it passes so the result can be recorded.
