# Native proposition families

User inductives may terminate in Prop, Type or Sort. Recursor construction asks
one Meta/Inductive classifier for its permitted elimination universe. For a
potentially zero result sort: empty families eliminate into any sort; multiple
constructors eliminate only into Prop; a singleton permits large elimination
only when every nonparameter field is a proof or is an entire argument of the
constructor result. Appearing inside an index expression does not suffice.
Fresh motive-universe names cannot collide with source universes.

The rule follows src/kernel/inductive.cpp, elim_only_at_universe_zero, at Lean
4.35.0-rc4 c29b6dda4f7c20e3eeaa717c4e565663c5cfa364. Generated declarations and
recursors remain subject to the official kernel. No local metadata is admission
authority.

Erasure uses the same family-sort classifier, omitting proposition families from
runtime data preparation. Empty proof eliminators become typed unreachable IR.
Nonrecursive singleton proof elimination may erase to its minor only when their
runtime representations agree. Recursive proof eliminators and extraction of
public index fields still need dedicated lowering; they fail closed today.
These limits do not weaken the kernel's large-elimination restriction.

Explicit result annotations on structures/classes, mutual/nested family
completion, recursor kernel K reduction parity and the rest of the selected
data/library inventory remain pending. The compact composite checks construction,
logical elimination, singleton runtime erasure and empty elimination. Three
refusals protect hidden witnesses, multiple constructors and computed indices.
Exact cloud qualification follows in AI_WORK_STATE.md.
