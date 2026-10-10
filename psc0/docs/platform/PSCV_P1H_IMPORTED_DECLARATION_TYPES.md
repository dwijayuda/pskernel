# PSCV P1-H — Imported declaration types and origin modules

P1-G established a complete normative **194-ID** review ledger and attached
seven paired Lean typeclass observations. P1-H inspects the actual Lean
4.35.0-rc3 imported constant declarations selected in those observations.

`PSCVL/SelectedInstanceDeclarations.lean` reads their declaration types
and the module index from Lean's imported environment. A separate review
checks the exact eleven selected declaration names, keeps them bound to
P1-E/P1-F's real compilation transcripts and the complete P1-G ledger,
and stores the observed module names and type expression representations.

This is a necessary diagnostic step toward exact source provenance.
**An imported module name is not a checked source file, Git blob, or
declaration line.** Exact immutable source locators and the actual
generic-to-concrete dependency elaboration remain to be completed.
Neither a type expression representation nor a printed instance
name establishes admissibility in a closed PSCV Standard profile.

P1 still has 191 unresolved IDs and incomplete ordered typeclass,
coercion, simplification, prover and verified effect registrations.
The private PSCV certificate and verified executable gates remain
unavailable. No compiler, native Core, TS7 backend, self-host seed or
npm release code is changed.
