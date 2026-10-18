# Source-owned mutual well-founded components — preparation

Reference: Lean4.35.0 commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
Study: PreDefinition/FixedParams, WF/{PackMutual,Rel,Fix}, Meta/ArgsPacker;
tests/elab/fixedParamsReorder.lean and fixedParamsDep.lean. Upstream test axioms
are not imported or treated as admissible source evidence.

Rel.checkCodomains requires one codomain independent of varying parameters;
Rel.elabWFRel then synthesizes one dictionary in the common fixed scope.
The first candidate incorrectly transported a closed dictionary application
without beta reduction and mistook its unused arguments for dependencies.
Run39092554668/job117572173163 failed exactly that check. The replacement removes
per-member dictionary transport and follows the upstream ownership boundary.

Ps.Elab.WhereMutualWellFounded connects retained source headers and measures to
typed fixed permutations and PSigma/PSum planning. Measures close over their
original headers before specialization. Only original varying arguments are
packed; a returned function remains the result. Types, source identity, captures
and whole-block universes remain independently checked.

The body stage keeps each original lexical header and predecessor aliases.
It instantiates the common fixed prefix by the owned permutation, then derives
each callback signature from the actual fix constructor. Per-callee callbacks
use real sum injections and dependent tuple currying. Source elaboration receives
only these proof-restricted callbacks; ordinary dependent matching refines their
current argument before fresh decrease goals are created. Every final call must
preserve its common fixed arguments in the call's real branch context. Proof
elaboration disables recursive authority. Closed bodies are checked, specialized
back into the common fixed scope and packed through typed dependent elimination.

The existing packing fixture has the native three-member oracle and original
reordered dependent headers, local argument lets and returned-function calls.
It now builds the source recursive functional and a genuine fixedpoint equation;
both enter the official Lean kernel. This candidate is not yet qualified.
No executable, workflow, budget increase or new trusted assumption is added.

The public dispatcher still refuses source mutual WF. Complete public projections,
exact equations against retained original bodies, typed executable ownership and
strict PSum foundation selection before activating it. Pinned WF/Main.lean31-35 explicitly rejects members with no varying
arguments. The nonempty-varying check therefore matches Lean4.35.0; PUnit is not
a missing M3 capability. Standalone PSum remains unselected.

## Qualified construction and exact-equation candidate

Internal source bodies and actual fix_eq are now prep-qualified at3f7e0491;
see PSCV0_M3_SOURCE_COMPONENT_3F7E0491_2026-10-18.md. Native lambda argument
candidate5785ada4 is being qualified separately on the same preparation branch.

The next child closes one shared packed auxiliary over the common fixed prefix.
Public definitions are typed projections/currying in their exact original header
order, including captures, implicit parameters and returned functions. This
shares the functional once rather than embedding it in every member.
The actual fix_eq proof supplies each original-header equation. The independent
PreDefinition equation owner stages all checked public definitions, replaces
all retained peers with those constants, and reconstructs the exact RHS from
retained Core. Existing checked constructor-case transport handles dependent
matcher motive differences. Singleton WF uses the same validator. No invented
eta conversion, unchecked functional rewrite or temporary axiom is introduced.

The existing three-member/native oracle fixture now submits the shared auxiliary,
three public definitions and their three exact source equations to the official
kernel. These checks are pending. Source mutual WF remains refused until typed
executable ownership, strict PSum selection and end-to-end source qualification
are also complete. M3+B remains open.
