# T06 quotient admission implementation batch — 2026-10-26

Base primary: 79031362b401f85d3c7f324cc3aa7dbf91c1bf0e.
Integration: ecafaabf844babd76a5de57bdf12909845961fba.
Candidate branch: work/psc1-pskernel-t06-quot-20261026.

Pinned primary source: https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/kernel/quot.cpp

Research and problem:
Pinned Lean checks Eq's inductive kind, single universe and sole constructor;
it structurally checks the two bootstrap types, checks all four reserved names,
then installs Quot, Quot.mk, Quot.lift and Quot.ind in a private environment.
The existing DAG checker still declined the explicit Quot admission command.
Earlier Quot owner/reduction qualification did not migrate this admission.

Implementation:
1. Extract the unchanged reserved-name and four-constant installation code into
   psKernelInstallCheckedQuot. Preserve the complete old admission function by
   a frozen-source equality theorem.
2. Match the two bounded expected bootstrap patterns against owning arena IDs.
   Pattern recursion is bounded by the expected type; no recursive input type
   is traversed/imported. Preserve binder erasure, metadata sensitivity and
   exact original error ordering.
3. Match private owner kind/name/universe metadata against the live environment,
   then route explicit Quot through the direct checker and shared atomic installer.
   Missing owners/children decline the whole original admission.
4. Qualify local structural correspondence for the supported pattern grammar,
   instantiated for both bootstrap types, plus installation/error/decline protocols.
   Run meaningful direct/public/negative controls and the retained official-lean
   Quot owner suite; strengthen its former expected-decline assertion.
5. After native preflight, qualify complete generated/canonical routes and
   independent source/archive evidence before adoption. Keep current integration
   untouched while this candidate is unqualified.

Acceptance for this batch:
- Actual pinned Lean/native production build and portable source checks pass.
- All nine new theorem reports have only standard axioms.
- New direct same-batch/public/idempotence, missing/wrong owner, shape mutation,
  reserved-name and exact-error controls pass.
- Retained ten positive/seven negative official Quot fixtures and full owner suite pass.
- Complete source qualification and independent evidence binding pass before adoption.

Limits and subsequent plan:
This batch covers Quot with same-batch or already adapted Eq owners. A pre-existing
session whose Eq owners are not demanded still uses the preserved original fallback;
removing that adapter limitation belongs to T04/T07 follow-up. Generated quotient
headers still use the separately qualified post-admission ownership bridge.
Mutual/nested admission remains T06 work. No local compiler/kernel execution,
resource increase, main merge, npm publication or global soundness claim.
Full Arena remains 174/193 with17timeouts/two contract differences. B OPEN/C FAIL/D OPEN.
