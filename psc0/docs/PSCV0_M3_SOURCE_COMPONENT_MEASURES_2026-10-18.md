# Source-owned mutual well-founded measures — preparation

Reference: Lean4.35.0 commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc,
PreDefinition/FixedParams, WF/{PackMutual,Rel,Fix}, Meta/ArgsPacker.
Rel.checkCodomains requires one codomain independent of varying parameters.
PackMutual closes a common fixed prefix before packing varying arguments.
Fix refines dependent callbacks through PSum/PSigma/matcher branches before
introducing decrease goals. These are invariants, not optional shape checks.

Ps.Elab.WhereMutualWellFounded now connects existing source preparation to
the typed component plan. Each original measure/dictionary is elaborated in
its owned header, normalized and closed before moving contexts. Retained Core
calls determine cross-member fixed permutations. Each closed member is
specialized into a fresh shared fixed scope; only original varying parameters
are packed. Returned-function binders remain results. Codomains/dictionaries
must be fixed, resolved and shared; actual domain/type inference validates the
aggregate plan. Original captures, block universes and member identity remain
checked by WhereWellFounded and PreDefinition.

The existing three-member retained-source fixture checks reordered dependent
fixed parameters, one Nat varying parameter each, original returned-function
arity, source measures and actual inferred component callback signatures.
Existing malformed-owner and dependent-codomain refusals remain. This is an
internal construction stage, not source acceptance of mutual WF. It is not yet
qualified and is not in main18fe0b3e.

Next, construct proof-restricted per-callee callbacks in original source scopes,
re-elaborate each body under refined branch contexts, solve genuine decrease
goals, close the functional and public projections, derive exact source
equations from fix_eq/cases/funext and independently recover the retained body
authority for typed runtime members. Keep the source refusal until all stages
are coherent. The current packing stage requires a nonempty varying telescope;
zero-varying/PUnit handling is still an explicit capability question, never
silently inferred from a returned lambda. Standalone PSum stays unselected until
the complete source consumer and strict selected-manifest update are ready.
