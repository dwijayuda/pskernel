# Unit inductives and the next bootstrap dependency

`@proofscript/pskernel-core@0.1.0-checker.6` admits a bounded inductive fragment:
one family, zero term parameters or indices, one constructor with no fields.
Universe parameters remain supported. The generated machine checks the family
sort and constructor type, confirms the constructor returns that same family,
rejects declaration-name collisions, chooses a fresh motive universe, derives
the recursor type, and installs its iota metadata atomically. The host supplies
no recursor type or reduction rule. The generated reduction machine validates
constructor identity and universes before reducing a recursor application.

The new mixed admission driver starts empty and delegates each declaration to
generated definition or unit admission. All nested checks use the same outer
transition budget. External axioms/opaque declarations, unsupported inductive
shapes, rejection, timeout and exhaustion cannot produce an accepted result or
trigger fallback. Internal environment values are not public checked handles.

The production profile is `owned-unit-inductives/3`. A committed fixture contains
the exact first two admissions from the preserved compiler bootstrap snapshot.
Admission 0, `_pscCheckedNestedUnit`, now passes through the default production
provider. Admission 1, `PsSourcePos`, fails with `unknownConstant`: its constructor
has three `Nat` fields. Nat/prelude admission and constructor-field semantics are
the next required work. Passing this prefix is not a full source replay.

The preserved cc79e840 PSC seed checks 521 kernel declarations from both source
frontends with identical TypeScript output. TypeScript 5.8.3 compiles that output;
all 17 source modules compile with pinned Lean 4.34.0. No generated semantic code
was edited. Source-manifest SHA-256:
`140e5e2abc8f94391b6da51465e2034a9d99b86e28a27f67489b2b9e52586fd0`.
Generated JavaScript SHA-256:
`076eed5d89f8cb236df2f0ac5153f102c575d1e60bc8702a4fb4f70481b990fe`.

Executed validation:

- 359/359 Linux package tests, including 31 unit/recursor cases.
- 109/109 actual native Lean comparisons for the unit fragment: 51 accepted,
  58 rejected, with recorded requests, results and hashes.
- Fresh 47 foundation, 100 semantic, 68 checker and 138 polymorphic comparisons.
- 671/671 universe comparisons and 559/559 comparable term judgments. Function
  eta and proof irrelevance remain two explicitly recorded completeness gaps.
- 48/48 integrated Linux tests, including the full 359-test baseline. Windows
  passes 47 with its one POSIX-only baseline case skipped.
- Build/evidence identity verification and focused admission/source guards pass.
- The preserved PSC seed checks all 2,423 declarations in the expanded 72-module
  compiler/kernel source snapshot. This is a source check, not owned admission.
- The 72-module closure, three-root minimality and 14 source-isolation cases pass;
  neither external reference provider enters that closure.

Integration base is 2c0bd2f7f991bac624c2aeaa4f84843cd7f9ea69. Original receipt,
replay sources, logs and artifacts remain preserved. The owned package stays
default and in bootstrap; explicit Lean references stay outside the portable
closure. General inductives, primitives/prelude, conversion completeness,
generated compiler/kernel pair replay and fixed point remain release blockers.
The package remains private and nonauthoritative.
