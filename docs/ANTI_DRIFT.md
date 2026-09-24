# Anti-drift contract

1. Compatibility target is exactly Lean 4.34.0 until ORACLE_LOCK.json changes deliberately.
2. `src/core` contains data model and capture-safe structural operations only.
3. `src/kernel` contains trusted checking/reduction logic; no parser, tactics, compiler or LSP.
4. Unsupported declarations fail closed. Never trust imported/generated metadata merely to improve corpus coverage.
5. Lean4Lean is a guide, not the oracle. The uploaded Lean 4.34.0 C++ kernel wins on behavioral disagreements.
6. Every milestone must pass strict TypeScript, semantic regression tests, and this guard before progress is marked verified.
7. Percentages are forbidden unless computed from an explicit acceptance matrix. No `full`, `equivalent`, or `complete` claim before differential soundness+completeness gates pass.
8. One implementation per concern: no duplicate checker/inductive/defeq paths.

9. The export boundary is pinned too: lean4export commit `076e8e57707e813375e8f9da8bf989799ace9680`, NDJSON format `3.1.0`, and Lean toolchain `v4.34.0`. Corpus evidence from another exporter/toolchain is not compatibility evidence for this target.
10. Oracle construction is reproducible from the uploaded Lean 4.34.0 source. Locally built binaries are tools for differential evidence, never a replacement specification.

## ProofScript foundation priority

11. On `main`, the controlling ProofScript execution plan is
    `docs/plans/07_SELF_HOSTING_FOUNDATION.md`.
12. Until SH0-SH10 close, unrelated ProofScript infrastructure expansion is
    deferred. A new language/runtime feature needs a concrete self-hosted
    compiler blocker or standard-library prerequisite.
13. The legacy software checker/software IR/backend lane must be removed early
    and must not be reintroduced. ProofScript has one semantic compiler path:
    source -> Meta/Elab -> pskernel -> checked core -> erasure -> verified IR.
14. TypeScript kernel assurance work belongs on
    `kernel/lean434-study-hardening`. ProofScript foundation work on `main`
    must not weaken or broaden kernel semantics merely to make the compiler
    easier to implement.
15. Host-specific Node/npm/TypeScript/VS Code integration may remain TypeScript
    when it is an explicit capability boundary and owns no ProofScript language
    semantics.

