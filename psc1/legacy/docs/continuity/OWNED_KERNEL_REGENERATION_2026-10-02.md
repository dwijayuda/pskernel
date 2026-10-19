# Owned checker regeneration

The received `0.1.0-checker.0` checkpoint remains preserved at
`7f8c078efbc95616148e5eda5946a3f4b557a75e`. This independently regenerated
`0.1.0-checker.1` checkpoint uses the exact seed and reference-provider hashes in
`packages/pskernel-core/manifests/TOOLCHAIN.json`.

The semantic source change renames the Lean-reserved local identifier `prefix`
to `prefixRev` in `Universe.lean`. All 13 modules compile with Lean 4.34.0.
The PSC seed checks 376 declarations in both Lean and canonical ProofScript;
their TypeScript emissions are identical. TypeScript 5.8.3 compiles the result.
Generated semantic JavaScript is not edited.

Current compiler eta lowering emits explicit two-argument runner functions.
Test adapters now use the signatures in generated `foundation.d.ts`, including
the 50,000-fuel regression. The Linux baseline passes **264/264**, with no skips
or failures. Windows independently exercises the semantic tests but cannot run
the unchanged POSIX executable-bit and symlink tests under this filesystem policy.

Fresh oracle evidence: 47 foundation, 88 semantic, and 68 checker ground checks;
671 universe differential cases; 559 comparable checker cases (156 accepted,
403 rejected). Proof irrelevance and function eta remain two explicitly recorded
completeness gaps. The reference timeout was raised from 20 to 120 seconds after
an observed timeout; no failed comparison is retried into acceptance. Build and
evidence identity validation passes against the committed manifests and records.

The source manifest SHA-256 is
`ecdf7f8f4cfd9abb2faf09766f67a882eb40ebe0042045cd92731ce2965a0619`;
generated JavaScript SHA-256 is
`e3f91d3b731ec1eb345407781893982e823e583ea71ca8dae01542c0268f3cdb`.
This is a bounded checker fragment, not full Lean compatibility or a completed
joint self-hosting release. All remaining release gates stay closed.
