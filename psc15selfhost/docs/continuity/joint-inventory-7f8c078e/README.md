# Joint declaration inventory at 7f8c078e

This is diagnostic elaboration evidence, not a checking receipt. `summary.json`
contains every declaration, its direct dependencies, expression and universe
forms, metadata and record digest. `declarations.json.gz` preserves the complete
types and bodies exported by `JointClosureInventory.lean`. The summary pins the
raw uncompressed SHA-256, source commit, compiler closure and kernel manifest.

The inventory contains 1,755 compiler, 376 kernel and 81 prelude declarations.
The transitive compiler/kernel dependency closure requires 55 prelude declarations
and 36 declared assumptions; it has zero unresolved references. Those assumptions
require an explicit owned-kernel primitive/axiom policy and appropriate semantics.
Their appearance here does not authorize blindly admitting them as axioms.

At this checkpoint the admission adapter incorrectly classified `PsKernelList` as
nested recursion. The subsequent parameterized-direct-recursion fix resolves that
adapter failure and was checked by the real native Lean provider. This historical
inventory intentionally retains the observed blocker.

Reproduction from the stated source checkout, with pinned native Lean:

```text
lake build psc2_joint_closure_inventory
.lake/build/bin/psc2_joint_closure_inventory packages/bootstrap/src/Ps/Bootstrap/SelfHost.lean packages/pskernel-core/dist/foundation.lean declarations.json
node scripts/summarize-joint-inventory.mjs declarations.json summary.json 7f8c078efbc95616148e5eda5946a3f4b557a75e 85540d078a7eb6ae5806a4e9e3756bba263075779d329558710541d1548daec9 packages/pskernel-core/manifests/SOURCE.json
node --test scripts/checked-joint-inventory.test.mjs
```

The audit target and scripts were added after the source checkpoint; they export
data through the existing frontend and codec and do not grant checked authority.
Literal types, projections, transitive references and opaque assumptions are
included. Unknown expression/universe forms and duplicate names are rejected.

Required owned semantics include inductive families, constructors, recursors and
their computation rules; polymorphic universes; binders, substitution and reduction;
conversion, proof irrelevance and applicable eta rules; literal/primitive policy;
and a protected checked-module identity consumed by emission. Exhaustion and
unsupported forms must remain failures throughout this work.
