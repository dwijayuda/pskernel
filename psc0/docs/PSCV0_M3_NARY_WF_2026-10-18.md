# M3 n-ary dependent WF packing — 18 October 2026

## Pinned reference and decision

Primary reference: Lean4.35.0 commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc,
[Meta/ArgsPacker.Unary](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Meta/ArgsPacker.lean),
[WF/PackMutual](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/PreDefinition/WF/PackMutual.lean),
and [WF/Rel](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Lean/Elab/PreDefinition/WF/Rel.lean).
The corresponding wfrecUnary, wfrec-nat, termination_by_where and mutual_termination_by_errors native tests were studied alongside the existing PSC0 native differential fixture.

Lean records source arity independently of type shape, packs right-associated PSigma, uses dependent casesOn to uncurry, and preserves the last source field intact. PSC0 previously encoded exactly two changing measured/dependent fields, leaving other changing fields as curried state. The two-slot limit was a missing general mechanism, not a semantic language boundary.

The new implementation retains that useful state optimization but generalizes the dependency-closed measured telescope to arbitrary length. It does not add a three-argument special case. Fixed captures stay outside the pack; dependent state and result types stay under the real measure argument. The original header order, source argument evaluation order, actual decrease proofs and fixed-parameter checks remain authoritative.

## Shared mechanism

- The plan owns an ordered list of packed source identities, replacing Option(pair). Binder-type dependencies close the set in dependency order; no fixed capture becomes a runtime field.
- Ps.Meta.WellFounded owns arity-directed type/constructor/projection, fresh telescope opening, curried callback and iterated dependent elimination. Shared checked constructors replace the old pair-specific curry routines.
- Elaboration re-elaborates retained source under the actual dependent callback as before. It constructs the real checked fixpoint and exact public equation. Nested PSigma cases and funext justify callback equality; no sigma/function eta rule, axiom or cast is introduced.
- Erasure derives the ordered original field identities from manifest nested constructors at the checked root entry. The final original fvar terminates the view, even if its type is PSigma. Duplicate, permuted or foreign fields are refused. Its bound is the actual header size, not an arbitrary feature limit.
- One runtime callback constructor handles unary and n-ary entries, restores original public-header order and independently verifies the proof slot, dependent state and complete result. The complete adapter is still compared and type-checked before substitution.

Empty source telescopes remain governed by the source-recursion contract. Mutual WF sum packing and ordinary implicit/default/named recursive application remain separate unresolved consumers of the shared telescope architecture. This slice does not claim them complete.

## Qualification

Extend the existing consolidated WF fixture, preserving all prior controls. Native independent definitions cover three measured/dependent fields, four fields with evolving residual state and interleaved fixed captures, plus an explicit source unfolding equation. One combined observer adds10 required runtime comparisons across directJS, strict TypeScript, Rust, V8 GC and Wasmtime. A focused checked-Core control ensures that a user PSigma final field is never flattened. Existing reordered/duplicated/foreign-entry and non-proof callback controls remain unchanged in meaning.

The former three-measured-field negative still has no decrease proof. Its required refusal moves from the removed arity limitation to the actual unsolved decrease goal; it is not accepted without evidence. The explicit positive definitions supply real checked lexicographic proofs.

Implementation candidate only: no new qualification or runtime totals are claimed until the retained cloud gates complete. No Standard identity, assumption, budget, verified-assurance rule or target representation changes.
