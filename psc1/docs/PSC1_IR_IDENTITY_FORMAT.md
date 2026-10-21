# Original IR identity transport v1

Ps.CompilerIr.Encode serializes the actual construction IR as compact deterministic
JSON tagged tuples. It does not validate IR or confer checking authority. The exact
same graph must separately pass psStrictValidateModule.

Module: ["psc1-ir/1", imports, structures, inductives, declarations].
All source list ordering, labels, binders, type arguments, owners and bodies are
retained. Parameter/field pairs and declaration records are positional arrays.
Expression/type/intrinsic/literal constructor names are explicit tags. Nat/Int/
machine-integer payloads are exact decimal JSON strings, so host parsing cannot
round them through floating point. Native strings and booleans retain their JSON
meanings. Every constructor in the current IR model is encoded.

Type/expression path depth is bounded by4096; exhaustion refuses with no successful
encoding, rather than producing a partial graph. This is serialization traversal,
not execution fuel or a change to any existing compiler/checker/target budget.

The closure diagnostic serializes the same original IR value that actually passed
strict validation. Linux orchestration checks encoding size, canonical compact
JSON, module shape and structure/inductive/declaration counts, retains bytes and
SHA256, and requires exact byte parity between grammar lanes. Primitive/type
inventories traverse these actual IR bytes, not source keywords. They cover the
whole original graph, not a dynamic execution trace or specialized liveness set.

Original IR validity, logical admission, transformed IR validity, target execution
and behavioral preservation remain separate. This format is the identity basis
for later generation manifests; repeated compiler execution is still required.
