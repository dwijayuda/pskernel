import Lean

-- Independent pinned native signatures, before portable authoring checks.
set_option pp.universes true
#print Nonempty
#print Nonempty.intro
#print Nonempty.rec
#print Classical.choice
#print Classical.ofNonempty
#print instNonemptyOfInhabited
#print axioms instNonemptyOfInhabited
#print axioms Classical.ofNonempty
