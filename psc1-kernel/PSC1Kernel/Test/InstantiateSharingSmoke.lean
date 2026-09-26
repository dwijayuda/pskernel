import PSC1Kernel.Instantiate

open PSC1Kernel

unsafe def expectSharing (label : String) (left right : Expr) : IO Unit :=
  if ptrEq left right then pure ()
  else throw <| IO.userError ("instantiate sharing smoke failed: " ++ label)

unsafe def main : IO Unit := do
  let fName : Name := .str .anonymous "f"
  let xName : Name := .str .anonymous "x"
  let absent : Name := .str .anonymous "absent"
  let base : Expr :=
    .app
      (.const fName [])
      (.forallE xName (.sort .zero) (.const fName []) .default)

  let lifted := base.liftLooseBVars 0 1
  expectSharing "lift reuses unchanged composite" base lifted

  let instantiated := base.instantiate [.sort .zero]
  expectSharing "instantiate reuses unchanged composite" base instantiated

  let abstracted := base.abstractFVars [absent]
  expectSharing "abstractFVars reuses unchanged composite" base abstracted

  let levelsInstantiated := base.instantiateLevelParams [absent] [.zero]
  expectSharing "instantiateLevelParams reuses unchanged composite" base levelsInstantiated

  IO.println "PSC1 expression DAG sharing smoke: PASS"
