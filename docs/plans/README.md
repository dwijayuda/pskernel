# ProofScript / pskernel plans

These documents are living plans. They are intentionally versionable and may be revised as Full Std, Arena, ProofScript language work, and npm integration expose better designs.

## Planning rules

Every package plan should identify:

- **purpose**
- **Lean 4.34 analogue**
- **trust status**: TCB, optional TCB extension, or untrusted support layer
- **upstream/downstream dependencies**
- **MVP**
- **acceptance gates**
- **explicit non-goals**

## Current priority

1. Finish pskernel Lean 4.34 assurance.
2. Build package boundaries around the stable kernel API.
3. Build portable checked-module distribution.
4. Build conformance/export tooling.
5. Build ProofScript syntax → meta → elaboration.
6. Build compiler/runtime/TypeScript backend.
7. Build incremental language service → LSP/project tooling.

See:
- `00_MASTER_PLAN.md`
- `01_MODULE_AND_DISTRIBUTION.md`
- `02_FRONTEND_AND_THEOREM_PROVER.md`
- `03_COMPILER_RUNTIME_BACKENDS.md`
- `04_LANGUAGE_SERVICE_AND_TOOLING.md`
- `05_RELEASE_AND_ASSURANCE.md`

The source-derived Lean subsystem mapping is in `../LEAN_PACKAGE_ROADMAP.md`.
