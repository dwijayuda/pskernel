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

ProofScript work on `main` is now foundation-first:

1. Retire the legacy software semantic lane so there is one checked-core path.
2. Close the self-hosting text foundation: Char/String/source positions.
3. Close compiler collections: Array/Map/Set plus the core data libraries.
4. Close controlled effects: Except/State/Reader/do.
5. Close compiler recursion: mutual/local recursive groups and executable partial definitions.
6. Freeze the bounded Lean bootstrap subset.
7. Implement the ProofScript compiler in supported `.lean`.
8. Bootstrap to JavaScript, then translate/refactor the compiler to `.ps`.
9. Establish reproducible and later verified self-hosting.

Unrelated ProofScript infrastructure expansion is deferred until these gates
close. The controlling plan is
`07_SELF_HOSTING_FOUNDATION.md`.

The TypeScript Lean 4.34 kernel assurance effort continues independently on
`kernel/lean434-study-hardening`. Kernel changes are not to be made on
`main` merely to unblock ProofScript compiler work.

See:
- `00_MASTER_PLAN.md`
- `01_MODULE_AND_DISTRIBUTION.md`
- `02_FRONTEND_AND_THEOREM_PROVER.md`
- `03_COMPILER_RUNTIME_BACKENDS.md`
- `04_LANGUAGE_SERVICE_AND_TOOLING.md`
- `05_RELEASE_AND_ASSURANCE.md`

The source-derived Lean subsystem mapping is in `../LEAN_PACKAGE_ROADMAP.md`.
