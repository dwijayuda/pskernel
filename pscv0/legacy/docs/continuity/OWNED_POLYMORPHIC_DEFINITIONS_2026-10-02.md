# Owned polymorphic definitions

`@proofscript/pskernel-core@0.1.0-checker.4` admits closed, safe, transparent
universe-polymorphic definitions through the default checked provider. Declaration
parameters must be distinct and nonanonymous. Every sort and constant argument
must refer only to declared parameters. Constant use checks arity and substitutes
universes simultaneously into its type; delta reduction substitutes into its
value. Parameter validation, substitutions, reduction and conversion consume the
same transition budget. Failure returns no environment and never invokes Lean.

The source remains generated into JavaScript by the preserved PSC seed from
cc79e840. Both Lean and canonical ProofScript check 459 kernel declarations and
emit identical TypeScript. All 15 modules compile with pinned Lean 4.34.0.
TypeScript 5.8.3 compiles the generated output without semantic edits.

Source manifest SHA-256:
`6dc3f454d1c20d82e5eff7025290b863772d6bedf0805dd96ba612812ce4e32f`.
Generated JavaScript SHA-256:
`8c2aa562cbcb2d6cee59368deab8c977767a5d5edcc42a41d27bdea13b94aee2`.

Validation completed:

- 317/317 isolated Linux tests, including 22 new polymorphic cases.
- 138/138 actual polymorphic declaration comparisons against pinned native Lean:
  67 accepted, 71 rejected. Records and harness hashes are committed.
- Fresh 47 foundation, 100 semantic and 68 checker computation cases.
- 671/671 universe and 559/559 comparable term comparisons; proof irrelevance
  and function eta remain two documented completeness gaps.
- Build and evidence identities pass. The original checker.0 EVIDENCE.json is
  historical receipt data; the current manifests and this checkpoint describe
  the new build.
- Integrated provider suite: 30/30 Linux tests, including the complete 317-test
  package baseline. Windows: 29 pass, one POSIX-only baseline test skipped.
- 70-module bootstrap closure, 14 source-isolation cases, source guards and
  2,361-declaration PSC source check pass.

The profile is `owned-polymorphic-definitions/2`. Old core routing stays retired;
Lean WASM and native Lean remain explicit alternatives outside the portable
closure. The first owned full-bootstrap blocker remains inductive admission of
`_pscCheckedNestedUnit`; primitives, recursors, conversion completeness and the
generated compiler/kernel fixed point still require work. This is not a kernel
release or a completed joint self-hosting claim.

CI run 37029694330 for d3c5d6d3 passed provider, host, source and parser checks.
The full checked bootstrap step failed; the later independent compiler diagnostic
was cancelled. At recovery on 2026-10-02, the previously protected local replay
processes were absent. Their logs and snapshots remain preserved and contain no
completed checked-emission result. A performance sample of the 68-module replay
identified per-character admission-string comparison as the next compiler cost.
The failed source experiment was reverted; generated outputs were not edited.
