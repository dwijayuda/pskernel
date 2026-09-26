import PSC1Kernel.CheckerWhnfPointerCache

open PSC1Kernel

private def expect (label : String) (ok : Bool) : IO Unit :=
  if ok then pure () else throw <| IO.userError ("whnf pointer cache smoke failed: " ++ label)

def main : IO Unit := do
  let env := Environment.empty
  let input : Expr := .app (.const (.str .anonymous "f") []) (.sort .zero)
  let output : Expr := .sort (.succ .zero)
  let decls : List LocalDecl := []

  expect "initial miss"
    ((checkerWhnfCoreLookup env decls 0 1024 true input).isNone)
  let stored := checkerWhnfCoreStore env decls 0 1024 true input output
  expect "store is semantic identity" (Expr.eq stored output)
  match checkerWhnfCoreLookup env decls 0 1024 true input with
  | some hit => expect "same scope pointer hit" (Expr.eq hit output)
  | none => expect "same scope pointer hit" false

  expect "disabled lookup misses"
    ((checkerWhnfCoreLookup env decls 0 1024 false input).isNone)

  let x : Name := .str .anonymous "x"
  let localDecl : LocalDecl := .localDecl 0 x x (.sort .zero) .default
  expect "different local spine misses"
    ((checkerWhnfCoreLookup env [localDecl] 1 1024 true input).isNone)

  let env2 := { env with quotInitialized := true }
  expect "different environment misses"
    ((checkerWhnfCoreLookup env2 decls 0 1024 true input).isNone)

  expect "different maxNatSize misses after scope reset"
    ((checkerWhnfCoreLookup env2 decls 0 2048 true input).isNone)

  IO.println "PSC1 WHNF pointer cache isolation smoke: PASS"
