# M3+B public generated recursor telescopes

Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc:
src/kernel/inductive.cpp mk_rec_infos/declare_recursors; src/kernel/expr.cpp
has_loose_bvars_in_domain/infer_implicit; src/util/name.cpp append_after;
tests/elab/match2.lean and the existing mutual/nested recursor source tests.

## Root cause and invariant

Preparation a25cadb9/run39102542931 compiled successfully but failed source
branchByRec with a type mismatch after native named placement was corrected.
The shared generated recursor type still used private _motive/_minor names and
made every motive explicit. Kernel type equality ignored those annotations,
so signature witnesses did not detect the source-call mismatch.

A public recursor signature must preserve both its checked dependent type and
the pinned binder names/kinds used by source elaboration. The same complete
elimination-slot owner now names motive/motive_1..., constructor-relative
minors, t majors, and field_ih hypotheses. It assembles the original telescope
and applies strict implicit inference once, following actual syntactic
dependencies through already implicit binders. Result-only dependency does
not make a parameter implicit: in particular an empty-family motive remains
explicit. No source/application recursor exception or compatibility alias.

Internal Core producers already supply every argument explicitly; their
positional layouts and proof/runtime ownership are unchanged. Source fixtures
for generated Vector/V recursors now use the selected native named motive.
The existing group qualification compares public top-level binder names/kinds
against the official kernel, in addition to full checked signature witnesses.
Both actual source languages still execute the positive-field recursor.

## Separate remaining audit

The retained legacy Nat.rec prelude signature also has a private explicit
motive. Its immutable foundation fingerprint differs from generated source
declarations, so this change does not silently rewrite its audited bytes.
A subsequent explicit foundation-metadata slice must reconcile that source
surface and independently measure/requalify its fingerprints. M3+B cannot
claim complete input parity before this is resolved. Existing Nat observations
are retained unchanged in this slice.

Named/generalizing match metadata is also selected by v7.2 and remains open.
Pinned Elab/Match.generalize and Meta/Match/Match.withEqs were studied:
generalization is optional/default true, while named Eq/HEq hypotheses must
relate original values to patterns and be separately supplied by reflexivity.
Do not model named equations as automatically solved index constraints.

Original portable Lean implementation guided by these upstream algorithms;
no copied upstream implementation body. Preserve upstream Apache-2.0 notices.
