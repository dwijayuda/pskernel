import PSKernelFast.TermStore

namespace PSKernelFast

private def assertIO (condition : Bool) (description : String) : IO Unit :=
  if condition then
    pure ()
  else
    throw <| IO.userError description

def smoke : IO Unit := do
  let t : RawExpr := .lam (.sort 0) (.app (.bvar 0) (.bvar 0))
  match encodeClosed 32 t with
  | .error e => throw <| IO.userError s!"closed encode failed: {repr e}"
  | .ok (id, store) =>
    match decode store (store.nodes.size + 1) id with
    | .error e => throw <| IO.userError s!"decode failed: {repr e}"
    | .ok reconstructed =>
      assertIO (reconstructed == t) "closed term did not round-trip"
    assertIO (store.nodes.size == 4) "subterms did not share the bound variable node"

  match encodeClosed 32 (.bvar 0) with
  | .error (.looseBound 0 0) => pure ()
  | _ => throw <| IO.userError "escaped bound variable was not rejected"

  match encodeClosed 1 (.app (.sort 0) (.sort 1)) with
  | .error (.nodeLimit 1) => pure ()
  | _ => throw <| IO.userError "node budget was not enforced"

  let base : Store := {}
  match base.intern 10 (.sort 0) with
  | .error e => throw <| IO.userError s!"first interning failed: {repr e}"
  | .ok (id, s) =>
    match s.intern 10 (.sort 0) with
    | .error e => throw <| IO.userError s!"second interning failed: {repr e}"
    | .ok (id2, next) =>
      assertIO (id == id2 && next.nodes.size == 1)
        "interning identical nodes did not reuse a checked handle"

  let damaged : Store := {
    nodes := #[]
    byNode := (Std.HashMap.emptyWithCapacity 4).insert (.sort 0) 99
  }
  match damaged.intern 10 (.sort 0) with
  | .error (.invalidHandle 99) => pure ()
  | _ => throw <| IO.userError "forged interned handle was not declined"

  match decode {} 2 99 with
  | .error (.invalidHandle 99) => pure ()
  | _ => throw <| IO.userError "invalid decoded handle was not declined"

  let cyclic : Store := { nodes := #[.app 0 0] }
  match decode cyclic 3 0 with
  | .error .decodeFuelExhausted => pure ()
  | _ => throw <| IO.userError "cyclic handle did not exhaust decoder fuel"

  IO.println "PSKernel-Fast V3 term-store prototype: focused safety smoke passed"
end PSKernelFast

def main : IO Unit := PSKernelFast.smoke
