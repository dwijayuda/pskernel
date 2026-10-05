# Uniform algebraic fragment (checker.14)

This private experimental fragment adds monomorphic Type0 families with Type0 type parameters, closed or parameter-only nondependent fields, and direct uniform recursion. It does not establish a complete owned-checked compiler/kernel pair, joint self-hosting, proof authority or release readiness.

## Source judgment

`AlgebraicHeader.lean` validates the header, parameter telescope, exact Type0 result and full family name. `AlgebraicConstructor.lean` validates each parameterized constructor, its original field types and exact uniform result. `Parameters.lean`, `Closing.lean`, `Occurrence.lean`, `ExpressionEquality.lean` and `Positivity.lean` implement charged capture-avoiding template handling and a conservative covariance profile. Parameter occurrences under unvalidated or negative contexts, earlier field dependencies, free variables and nonuniform self applications reject. Validated covariant families may be used in nonrecursive field templates; nested self occurrences remain unsupported.

`AlgebraicMinor.lean` and `AlgebraicRecursor.lean` derive dependent minor types, direct recursive hypotheses, motives and recursor types. `AlgebraicAdmission.lean` checks the derived type before atomically returning the completed environment. Internal family/recursor metadata cannot enter through the user definition path.

`AlgebraicReduction.lean` traverses the constructor and eliminator spines, checks complete field arity and applies fields then direct recursive hypotheses in forward order. Neutral constants with universe parameters remain neutral rather than being mistaken for malformed monomorphic constructors. Every traversal and nested judgment uses transitions in the outer budget; no semantic work is supplied by handwritten JavaScript.

The production adapter enables the new route for explicit type-parameter families. It only decodes raw names, types and constructors. Existing parameter-free Nat, unit, record, enum and sum routes remain unchanged; no failed judgment is retried through another route. Parameter-free direct recursion is supported by the raw generated algebraic judgment, but is not newly enabled in the production dispatcher by this checkpoint.

## Evidence and remaining boundaries

Both PSC frontends and canonical ProofScript emission checked 1,105 declarations; independent native Lean checked all 36 source modules. The complete Linux kernel suite passed 651/651. The focused source suite passed 39/39. Real Lean and ProofScript option/list programs passed owned admission, checked emission, strict TypeScript and execution. The exact preserved `PsKernelList` admission also passed independently; this does not mean the complete closure passed.

The new native differential retains 84 records: 83 comparable cases match (29 accepts, 54 rejects), and one exact reference-boundary discrepancy is explicitly excluded from matching evidence. A malformed constructor with a loose bound variable is rejected by the owned checker as `invalidScope`, while the pinned native provider accepts it. A direct pinned Lean `addDeclCore` probe in an empty trust-zero environment reproduces that acceptance and reports `hasLooseBVars=true`. The owned rejection was not relaxed. This observation is not a general claim about Lean soundness; the exact input and control program are preserved in the continuation evidence.

General indexed/mutual/nested families, universe polymorphism, dependent fields, parameterized projections and the full standard prelude are not covered. Finite tests are bounded evidence, not a soundness theorem. Consult the continuation receipt for commands, hashes, failures and integrated results.
