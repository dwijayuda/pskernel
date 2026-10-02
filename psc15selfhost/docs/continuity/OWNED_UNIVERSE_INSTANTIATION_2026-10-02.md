# Bounded simultaneous universe instantiation

`@proofscript/pskernel-core@0.1.0-checker.2` adds the source module
`Ps.Kernel.LevelInstantiate` as a prerequisite for polymorphic inductive checking.
It validates parameter arity, nonanonymous names and uniqueness before traversing
the target. Replacements are simultaneous: parameters inside a replacement are
not substituted again. Undeclared target parameters, malformed reconstruction
states and exhaustion produce separate failures. Name comparison, validation and
traversal share one transition budget. No host implementation supplies semantics.

The generated kernel was rebuilt with the preserved PSC seed from commit
`cc79e84014ed1d49b0c31971e0a8ceb99b32472c`, SHA-256
`a0673677219da539df555961129385ae4cf5099f303f0c883dd3a26f726449ff`.
Lean and canonical ProofScript both check 411 declarations and emit identical
TypeScript. All 14 source modules also compile under pinned Lean 4.34.0.
TypeScript 5.8.3 compiles the output without generated semantic edits.

Source manifest SHA-256:
`cfd16c97fb093976528440c31b7815ee7725cd63a153919460bb352cab4ed6bd`.
Generated JavaScript SHA-256:
`4889b036bdf287a225800523d3f4c26bb5e494e77e3de19b454a8d33fcf3dd50`.

Validation: 278/278 Linux tests, no failures or skips; 14 new tests cover 512
independent generated substitution trees, simultaneous replacement, structural
name identity, malformed parameters and 50,000-deep bounded traversal. Fresh
reference evidence verifies 47 foundation, 94 semantic and 68 checker ground
cases. Added negative controls reject recursive replacement and arity bypass.
All 671 universe and 559 comparable checker differential cases match. Proof
irrelevance and function eta remain explicit completeness gaps. Build and
evidence identities pass against the full source manifest and generated records.

The bootstrap now contains 69 modules. The default checker still admits only
monomorphic transparent definitions. Polymorphic declaration support and
inductives remain closed until their complete checks pass; this helper does not
promote acceptance, release authority or joint self-hosting claims.

CI run 37021270554 on cc79e840 passed provider, host, source, parser and native
reference checks. Its checked bootstrap failed with
`PSC2_KERNEL_REJECTED: unsupported-admission:inductive`; the overall run was
subsequently cancelled during the independent compiler diagnostic.

The preserved 68-module reference replay using cc79e840 sources elaborated the
refactored prelude in 5,324 ms (683,084 minus 677,760), versus 3,379,431 ms in the
protected older tail-loop replay. This is measured performance evidence, not a
completed fixed point. Original replays and their worktree remain protected.
