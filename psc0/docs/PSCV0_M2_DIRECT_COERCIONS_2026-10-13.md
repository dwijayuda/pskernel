# M2+A direct coercion boundaries

Implementation in progress; qualification is pending.

The canonical v7 coercion rule permits one direct Coe, CoeFun or CoeSort.
It excludes automatic chains and lifting. The pinned class definitions are
[Init.Coe at RC4](https://github.com/leanprover/lean4/blob/c29b6dda4f7c20e3eeaa717c4e565663c5cfa364/src/Init/Coe.lean).
The native reference descriptions explain
[function coercions](https://lean-lang.org/doc/reference/latest/Coercions/Coercing-to-Function-Types/)
and [sort coercions](https://lean-lang.org/doc/reference/latest/Coercions/Coercing-to-Sorts/).

Three checked structures/constructors/projections add nine declarations,
three class registrations, and no global instances, axioms or runtime primitives.
Coe consumes both known types. CoeFun/Sort select their output and output universe
from the input type; no requested result can backtrack into a different output.
Only the standard named dictionaries and visible local/global instances apply.

A checked Core application helper solves argument and universe constraints
before synthesis. One projection application inserts the conversion. Strict
unification checks the result without requesting a second conversion.
Callable/sort boundaries verify an actual Pi/Sort after weak-head reduction.
Empty calls preserve APP-03 completion. Type annotations, optional annotations,
forall codomains, declarations and recursion planning share the sort boundary.
Application result conversion happens after scoped synthetic obligations.

All failed alternatives preserve the incoming context. Resource refusal stays
an error. Postponed source terms retry through the existing captured-scope queue.
No backend changes or host elaborator delegation are involved. The compact
positive fixture is shared across existing targets and mirrored independently
in native Lean; negative checks cover chaining and non-Pi/non-Sort dictionaries.

Reference boundary: native instance synthesis does not unfold the ordinary
Carrier-valued definition `natural` to find an OfNat dictionary. The selected
portable reducer currently unfolds transparent definitions more aggressively.
The CoeSort observation uses an explicitly Nat-typed value on both sides to
qualify conversion to sorts independently of that existing transparency gap.
Full synthesis-transparency parity remains an M2 acceptance item; this fixture
does not establish it. The original unannotated native probe failed at OfNat,
not CoeSort, on Linux 38425764333.

The source and pinned oracle compiled on Linux 38426692213. The independent
strict guard reported the reviewed nine-declaration/three-class addition:
FNV `fnv1a64:946298686920218861`,
SHA-256 `sha256:9afbebe8bf188a119b1bc223bc7f793da6f2dc08db9caa98e381d9e97662b234`.
These exact digests are pinned. Full runtime qualification is pending.

## Shared runtime representation

The first full run (38426963318) rejected an unknown field in the generic
CoeFun template, even in programs that did not use it. This exposed a general
erasure boundary: a compile-time type former determines the runtime field type.

Nonrecursive one-field families whose erased parameter makes their generic
field unrepresentable now retain a Core layout template. At each concrete use,
the checked constructor telescope supplies the actual field type. The wrapper
is represented by this field; construction/projection are identity operations.
Generic projection definitions expand at their typed use sites. No CoeFun
name-specific backend rule or unknown/any representation is introduced.
Unresolved concrete types still fail the existing IR gate. Such wrappers do
not acquire an automatic foreign aggregate-construction capability.

A second general rule erases specialized class dictionaries whose instantiated
fields all contain only types/proofs. This handles CoeSort-to-Type dictionaries
without turning an erased type argument into a fake runtime generic.

The original six runtime observations remain required; two more exercise
local CoeFun dictionaries and a user-defined dependent-field wrapper.
This does not add general existential/higher-rank runtime data.
