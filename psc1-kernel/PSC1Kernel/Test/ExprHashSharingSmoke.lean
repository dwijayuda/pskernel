import PSC1Kernel

open PSC1Kernel

def buildSharedDag (seed : Expr) : Nat → Expr
  | 0 => seed
  | depth + 1 =>
      let prev := buildSharedDag seed depth
      .app prev prev

unsafe def topChildrenShare (e : Expr) : Bool :=
  match e with
  | .app fn arg => ptrEq fn arg
  | _ => false

unsafe def main : IO Unit := do
  let leftName : Name := .str .anonymous "ExprHashLeft"
  let rightName : Name := .str .anonymous "ExprHashRight"
  let left := buildSharedDag (.const leftName []) 30
  let equalCopy := buildSharedDag (.const leftName []) 30
  let unequal := buildSharedDag (.const rightName []) 30

  unless Expr.eq left equalCopy do
    throw <| IO.userError "shared-DAG Expr.eq rejected structurally equal expressions"
  if Expr.eq left unequal then
    throw <| IO.userError "shared-DAG Expr.eq accepted structurally different expressions"

  let unchanged := left.instantiate [.fvar (.str .anonymous "unused")]
  unless ptrEq unchanged left do
    throw <| IO.userError "instantiation rebuilt an expression with no substitutable bound variables"

  let replacement : Expr := .fvar (.str .anonymous "replacement")
  let withBVar := buildSharedDag (.bvar 0) 24
  let instantiated := withBVar.instantiate [replacement]
  let expected := buildSharedDag replacement 24

  unless Expr.eq instantiated expected do
    throw <| IO.userError "shared-DAG instantiation changed structural semantics"
  unless topChildrenShare instantiated do
    throw <| IO.userError "shared-DAG instantiation failed to preserve transformed sharing"

  IO.println "PSC1 expression hash/sharing smoke: PASS"
