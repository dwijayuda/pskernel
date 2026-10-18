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
strict PSum foundation selection before activating it. The current plan requires
nonempty varying telescopes; zero-varying/PUnit handling cannot be inferred from a
returned function. Standalone PSum remains unselected.
