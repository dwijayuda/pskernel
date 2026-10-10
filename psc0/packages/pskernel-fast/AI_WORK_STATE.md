# PSKernel-Fast V3 — AI Work State

## Context and binding decisions — 2026-10-11

Repository: `dwijayuda/pskernel`.
Topic branch: `research/pskernel-fast-v3-greenfield-20261011`.
Pinned toolchain: `leanprover/lean4:v4.35.0-rc4`, upstream source commit `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`.

User's priority: **correctness, Lean compatibility, measured performance, small auditable trusted core, memory efficiency**. Reuse of old source, architecture, proof artifacts and old source profiles has **no design priority**. Explicit architectural freedom is the reason for a fresh package rather than editing the old kernel.

Leave `psc0/pskernel-core-lean435-arena-v1` and draft PR #89 untouched. Git branches/history are retained but no old theorem interface constrains the new design. Do not merge unqualified kernel code or equate differential tests with soundness proofs.

Source of truth: GitHub and cloud CI. No desktop checkout, build or Desktop Commander. Re-read HEAD before every write, use non-force expected-HEAD updates, avoid repeated expensive full-corpus/fully generated selfhost runs.

## G0 implementation checkpoint

Architecture file: `ARCHITECTURE_V3.md` — reset design authority.
Seed source: `PSKernelFast/Core.lean` and `Main.lean` — a **simplified** RawExpr with Nat-only sort placeholder, immutable hash-consed Node array, typed failures, scope validation and bounded total decode. Compile/test is limited to native Lean 4.35; it is NOT a kernel proof checker.

Intended focused tests:
- encode/decode of a closed lambda/application term returns byte-for-byte structurally equal raw syntax;
- a second encoding reuses interned node IDs rather than allocating duplicate nodes;
- unbound de Bruijn input is rejected;
- invalid DAG child IDs and invalid decode root IDs are rejected;
- exhausting a decode budget rejects rather than looping.

**CI evidence:** evaluate the completed `PSKernel-Fast V3 greenfield G0` GitHub Actions job for the exact commit before marking this checkpoint green. A commit alone is *not* compilation evidence. No measured performance, full Lean 4.35 compatibility, soundness theorem or self-host success exists yet.

## Next vertical work

1. Check CI, diagnose any source or build failure at the *shared cause*, update exact evidence.
2. Implement full Lean 4.35 `Level` (including symbolic `imax`), names, binder metadata, literal and environment identities before classifying any expression as kernel checked.
3. Define independent raw reference syntax semantics and compare three evaluators: compact DAG + substitution (B), compact DAG + closure (A), computation-specialized call-by-need (C), on identical input identities.
4. Implement typed checked versus infer-only judgments, WHNF/DefEq and soundness-sensitive proof-irrelevance and annotation checks. Do not copy old proof statements merely to minimize migration.
5. Add safe declaration admission/inductives/recursors/quotients, full negative conformance and official Lean differential checks. Every supported result must be pinned and fail closed.
6. Prove the new chosen runtime's positive-result soundness against an explicit mathematical model and newly extended admitted environment under stated axiom assumptions.
7. Independently qualify generated native/JS/Wasm and future self-host source only after algorithm architecture and runtime are stable.

**No claimed speedup or success beyond G0 tests**; keep benchmarks parser-separated and compare official Lean at matching version and corpus.
