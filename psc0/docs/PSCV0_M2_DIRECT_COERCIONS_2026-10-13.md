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
