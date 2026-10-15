# M2 structural instance-table keys

## Reference and design

Lean 4.35.0 (eb6cafb7290e8bd5f2937522d8d804f58f02bafc), src/Lean/Meta/SynthInstance.lean, MkTableKey uses structural expression identity; definitionally equal but structurally different targets can have separate table nodes. AbstractMVars.lean separates answer abstraction from consumer contexts. Relevant inspected tests are tests/elab/typeclass_diamond.lean, typeclass_outparam.lean, instanceReducibility.lean and synth1.lean. These are design references under Lean's Apache-2.0 license; the portable implementation is independently authored.

PSC0 previously bucketed goals only by class and scope, then performed pairwise definitional-equality searches. Distinct inputs of the same class therefore produced a quadratic table-comparison workload. The existing generator/consumer scheduler, generalized answers, priority selection and checked replay do not require that representation.

Ready PSC0 goals already instantiate inputs and mask output arguments and output-only levels. Their keys have no remaining assignable input metavariables, so Lean's metavariable-renaming pass is unnecessary here. Bounded beta/zeta and instances-permitted delta normalization retains sharing of reducible wrappers before hashing the complete structural expression with its scope. It does not execute primitive arithmetic, iota or arbitrary runtime computations inside indices. This normalization is an optimization, not a complete conversion procedure.

The existing persistent bounded-depth bucket index owns storage. Equal hashes never establish semantic equality: collision candidates must have alpha-equal keys and identical closed local signatures. Replayed evidence is still freshened and checked against the receiver's actual dependent target. Hashes ignore binder names consistently with alpha equality. Omitting binder annotations from the hash merely permits collisions; equality still checks them.

## Validation boundary

The existing graph corpus retains seeded/unseeded cycles, diamonds, reducible aliases, hidden aliases, generalized answers, output priority, local-context isolation, rollback and budgets. The measured distinct-goal workload now requires bounded comparisons for both different classes and different inputs to one class. Focused invariants check alpha-equivalent key hashing and that constructing a key does not evaluate an enormous primitive exponentiation.

This improves table lookup, not every source of instance-search complexity: candidate enumeration and dependent local-context checks remain distinct costs. No global linear-time solver claim is made. Implementation is prepared for qualification; no successful CI receipt yet.
