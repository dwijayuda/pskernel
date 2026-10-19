import Ps.Foundation.Name
import Ps.Core.Expr

-- Source equation publishers establish provenance; a written suffix cannot.
structure PsSourceEquations where
  owner : PsName
  equations : List PsName
  unfolding? : Option PsName := none

def psSourceEquationsEqual (left right : PsSourceEquations) : Bool :=
  psNameEq left.owner right.owner &&
    left.equations.length == right.equations.length &&
    (left.equations.zip right.equations).all (fun pair => psNameEq pair.fst pair.snd) &&
    (match left.unfolding?, right.unfolding? with
    | none, none => true
    | some left, some right => psNameEq left right
    | _, _ => false)

def psSourceEquationsSingle (owner equation : PsName) : PsSourceEquations :=
  { owner, equations := [equation], unfolding? := some equation }

def psSourceEquationsUses (entry : PsSourceEquations) (name : PsName) : Bool :=
  psNameEq entry.owner name || entry.equations.any (psNameEq name) ||
    entry.unfolding?.any (psNameEq name)

-- Preserve conflicting records for validation at the actual import seam.
def psSourceEquationsMerge (left right : List PsSourceEquations) : List PsSourceEquations :=
  right.foldl (fun entries entry =>
    if entries.any (psSourceEquationsEqual entry) then entries
    else entries ++ [entry]) left

def psSourceEquationHead : PsExpr → PsExpr
  | .app fn _ => psSourceEquationHead fn
  | term => term

def psSourceEquationLeftOwner? : PsExpr → Option PsName
  | .forallE _ _ body _ => psSourceEquationLeftOwner? body
  | .app (.app (.app (.constE relation _) _) left) _ =>
    if psNameEq relation (.str .anonymous "Eq") then
      match psSourceEquationHead left with
      | .constE name _ => some name
      | _ => none
    else none
  | _ => none
