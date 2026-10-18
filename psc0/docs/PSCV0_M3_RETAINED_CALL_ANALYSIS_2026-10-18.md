# M3 retained-source parameter observations

Candidate child ofade87651; qualification pending. Source mutual WF remains closed.

## Reference and design

Lean4.35.0 eb6cafb7290e8bd5f2937522d8d804f58f02bafc
src/Lean/Elab/PreDefinition/FixedParams.lean:getFixedParamsInfo visits complete
applications in their actual typed context, comparing arguments reducibly without
proof irrelevance. Missing application slots become varying. WF/PackMutual.lean
keeps original header arity distinct from arguments to a returned function.
The existing finite-graph differential and fixedParamsReorder/funind_mutual_dep
controls remain relevant. Retain Apache-2.0 attribution in THIRD_PARTY_NOTICES.

The existing PreDefinition owner now independently rechecks each retained member
value in its actual complete-peer context, opens only its original header and
collects call observations under actual lambda/Pi/let scopes. Application spines
are visited once; original target arity owns only its prefix. Extra arguments
belong to the returned function. Missing slots are conservatively varying, as in
native analysis. No source spellings, guessed capture identities or additional
source-probe elaboration decide correspondence. The common typed graph consumer
still checks caller ownership, per-member dependencies and complete permutations.

The visitor does not rewrite a term, solve a decrease obligation, publish a peer,
allow a recursive callback escape or bypass the existing source consumer.
Its traversal uses the existing4096 bound and fails explicitly on exhaustion.
No arbitrary native host MetaM or new logical assumption enters portable code.

## Validation

The existing packing executable adds three actual parsed/scoped/typechecked source
members with a generic fixed type and dependent fixed value in different positions,
a changing Nat, a local let alias and a returned function. Check exactly one call
per member, correct original arity/permutation, conservative underapplication and
unowned-Core refusal. Independent pinned native definitions cover the same source
shape. Existing kernel equations, graph differential and all acceptance remain.
These source-preparation observations do not claim recursive source admission or
backend qualification, and the .lean oracle is not PSC0 .lean-input parity.

## First qualification and native proof-method correction

Candidatea5287a1/run39085518962/job117551185828 completed FAILURE only at
building the new native reference theorem. Native decide cannot definitionally
unfold the well-founded mutual fixedpoint; it stopped at (callFirst7 6 2).beq7.
The child uses simp with the three actual generated unfolding equations to prove
the same equality callFirst7 6 2=7. This is a proof-method correction in the
independent oracle, not a changed compiler rule or weaker expected result.
All production and other retained steps passed. The portable new observation
probe still awaits execution; candidate publication is not qualification.
