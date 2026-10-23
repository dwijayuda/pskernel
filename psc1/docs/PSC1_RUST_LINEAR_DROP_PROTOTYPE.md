# Private linear recursive Rust destruction

Exact G2 artifact replay 39889679469 at diagnostic source
4ca3d4e72cc9d45f39329801023358fe50d56d70 reproduces the crash in 1801 ms,
with repeated alloc::rc::Rc<T,A>::drop_slow frames. The last-use String
correction removed the previous long copying delay; no response was adopted.

Generate safe iterative Drop only for private regular inductives with a nullary
sentinel and at most one direct recursive field, which must be last. Public enum
representations and their pattern ABI retain ordinary Drop. Other shapes retain
their existing behavior. Rc fields and Clone remain unchanged.

Replace the whole current node with its nullary variant, take its last recursive
Rc through a shared empty sentinel, drop the node's preceding fields, then
Rc::try_unwrap the tail. Stop on shared ownership. The sentinel makes reentrant
node Drop constant depth. No unsafe code, leaked values, stack/heap/fuel increase
or altered guest semantics. Field destruction order is preserved.

Generated match bindings borrow fields and clone owned payloads before executing
the branch, so private Drop enums never move a field out of a Drop value.
Native runtime comparisons retain the old emitter, test shared tails and exact
Probe destruction order, and drop 500000-node private values at the unchanged
process bounds. This is regression evidence, not a formal backend theorem.
Actual independent G1/G2/G3 and fresh normal qualification remain required.
