# Complete checked unary packing

Candidate. Pinned reference: Lean4.35.0 commit
eb6cafb7290e8bd5f2937522d8d804f58f02bafc,
src/Lean/Meta/ArgsPacker.lean Unary.{uncurryType,uncurry,curry,casesOn}
and ArgsPacker/Basic.lean.varNamess. Upstream attribution is retained in
THIRD_PARTY_NOTICES.md. Original source arity is authoritative.

Ps.Meta.WellFounded already owns PSigma domain/constructor/projection and
dependent cases. The complete type/body transformations now use those same
helpers rather than rebuilding the encoding in mutual-WF elaboration.
Source telescope opening stops at its recorded arity: returned functions remain
results, and a final user PSigma is a single source slot. Dependent uncurrying
uses checked cases, not an assumed sigma eta conversion. The complete type,
branch and reconstructed source value are independently inferred. Empty varying
telescopes remain outside this selected WF helper contract.

The existing consolidated packing probe combines a three-slot dependent source
header, final user PSigma, returned function and exact curried round-trip
equation admitted by the official kernel. No new standalone test executable.

Mutual WF still needs the source owner, common measure and callbacks, exact
fix_eq-derived public equations, and complete runtime validation. Its combined
result may depend on the PSum tag. Strict IR cannot admit that as an unknown
runtime type: a validated adapter must recover each typed public member from
the actual checked functional before erasure, without treating a reflexive
public equation as authority to replace a body. Source admission remains closed
until that complete path exists.
