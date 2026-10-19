import Ps.Environment.Logic

-- Executable values inhabit Type 0 = Sort 1; instantiation of the class
-- therefore uses universe 1, not universe 0 (Prop).
def psStandardInhabitedType (type : PsExpr)
    (level : PsLevel := .succ .zero) : PsExpr :=
  .app (.constE (psRootName "Inhabited") [level]) type

def psStandardInhabitedValue (type value : PsExpr)
    (level : PsLevel := .succ .zero) : PsExpr :=
  psLogicApply (.constE (psNameAppendStr (psRootName "Inhabited") "mk")
    [level]) [type, value]

-- Construct a proof-checkable default application after typeclass search.
-- The universe is the inferred sort of the requested field type, not a
-- guessed Type-0 specialization.
def psStandardInhabitedDefault (level : PsLevel)
    (type dictionary : PsExpr) : PsExpr :=
  psLogicApply (.constE (psNameAppendStr (psRootName "Inhabited") "default")
    [level]) [type, dictionary]
