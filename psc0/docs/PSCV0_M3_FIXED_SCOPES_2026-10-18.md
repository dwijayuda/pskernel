# M3 fixed-parameter scopes and shared source preparation

Candidate child of3386891. Qualification pending; no source mutual-WF admission.

## Authority and reference

PSC0's portable compiler is authored in native `.lean` under the v7.2 language
and semantic contract. Use the selected v7.2 capabilities and audited library
closure, retaining a clean path to future readable `.ps` reconstruction.
Native Lean syntax remains native (v7.2 §§2, 11 and 14); `.ps` comma calls and
braced layout are not imposed on `.lean`. Host Lean compiler/elaborator APIs
belong only in the explicit host or independent reference-test boundary.
Do not use unrestricted host functionality to bypass an unavailable portable
capability. This is an authoring/design boundary, not a claim that PSC0 already
self-compiles or that current CI establishes full v7.2 conformance.

Pinned Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc:
[FixedParams.lean](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/PreDefinition/FixedParams.lean),
particularly FixedParamPerm.forallTelescope, instantiateForall and buildArgs;
[fixedParamsReorder.lean](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/tests/elab/fixedParamsReorder.lean)
and funind_mutual_dep.lean. Native fixed correspondence is positional and
common across an actual recursive component; equal names or numeric local IDs
from different owners do not establish correspondence. Source arity excludes
returned functions. Dependencies of a fixed parameter must also be fixed.
The graph differential was already qualified; this slice implements its typed
scope consumer. Upstream attribution is in THIRD_PARTY_NOTICES.md.

## Design

RecursionParameters validates a complete bijection before consuming a fixed
permutation. Open the first complete header bounded by its owned arity, allocate
common identities after all original slots, and substitute only earlier common
fixed values into dependent domains. Reject a domain retaining a varying or
foreign local. Preserve actual universes and binder kinds.

Specialize every member by walking exactly its original source slots. Check each
common fixed argument against that member's actual dependent domain; open only
varying slots. Return both the varying telescope and the complete original-order
argument list. A returned function stays in the result. Check the complete
specialized type in the common outer scope. All traversal is structural or uses
the existing checked telescope bound; no host MetaM enters portable code.

WhereWellFounded now separates preparation of the existing checked source
header/body/termination clause from singleton construction. The existing
consumer uses that same prepared record. Capture identity, body aliases, local
shadowing, delayed termination scope, original universe counters and independent
predefinition equation checks retain their current owners. This extraction
creates one reusable source owner; it does not add mutual recursion authority.

## Focused validation

Extend the existing packing executable rather than create another test family.
Three generic members share dependent fixed A:Type u / a:A in different header
positions and have one varying Nat slot. Their result is itself Nat -> A.
Check binder kinds, common fixed dependencies, complete original arguments and
source arity, then independently kernel-check the three original-header equations.
Reject a nonbijective permutation, an incorrect dependent fixed value and a fixed
Fin(n+1) whose n is varying. Retain the existing native graph differential,
heterogeneous component equations, unary packing and all integration gates.

These are typed construction/equation checks; source mutual decreasing calls,
exact source equations and validated executable adaptation remain separate work.
No foundation asset, manifest, workflow budget or acceptance assertion changes.
