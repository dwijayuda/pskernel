import Ps.Core.Expr
import Ps.Core.Builtin

-- A bounded, pinned-Lean constructor-shape model for the currently selected
-- strictly positive nested containers. Not a general positivity theorem,
-- executable representation or source of recursive induction hypotheses.
inductive PsSelectedNestedContainer where
  | list (element sourceType : PsExpr)
  | option (element : PsExpr)
  | array (element : PsExpr) (levels : List PsLevel)
  | prod (left right : PsExpr)

def psSelectedNestedContainer? (type : PsExpr) : Option PsSelectedNestedContainer :=
  match type with
  | .app (.constE name levels) element =>
      if psNameEq name psListName then
        some (.list element type)
      else if psNameEq name psOptionName then
        some (.option element)
      else if psNameEq name psArrayName then
        some (.array element levels)
      else none
  | .app (.app (.constE name _) left) right =>
      if psNameEq name psProdName then some (.prod left right)
      else none
  | _ => none

-- All positive positions that must satisfy the family's uniform parameter
-- and index checks; Prod deliberately checks BOTH children.
def psSelectedNestedContainerElements : PsSelectedNestedContainer → List PsExpr
  | .list element _ => [element]
  | .option element => [element]
  | .array element _ => [element]
  | .prod left right => [left, right]

-- Pinned Lean 4.35.0 Init/Prelude constructor telescopes:
-- List.nil, List.cons α (List α), Option.none/some α,
-- Array.mk {toList : List α}, and Prod.mk α β.
def psSelectedNestedContainerConstructorFields :
    PsSelectedNestedContainer → List (List PsExpr)
  | .list element sourceType => [[], [element, sourceType]]
  | .option element => [[], [element]]
  | .array element levels => [[.app (.constE psListName levels) element]]
  | .prod left right => [[left, right]]
