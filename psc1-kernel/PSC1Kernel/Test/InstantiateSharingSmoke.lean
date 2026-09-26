import PSC1Kernel.Instantiate

open PSC1Kernel

unsafe def sameObject (a b : Expr) : Bool :=
  ptrAddrUnsafe a == ptrAddrUnsafe b

def expectSharing (label : String) (ok : Bool) : IO Unit :=
  if ok then pure ()
  else throw <| IO.userError ("instantiate sharing smoke failed: " ++ label)

unsafe def main : IO Unit := do
  let A : Expr := .sort .zero
  let c : Expr := .const (.str .anonymous "C") []
  let e : Expr := .app (.app c A) (.lit (.nat 3))

  let lifted := e.liftLooseBVars 0 1
  expectSharing "no-op lift preserves root object" (sameObject e lifted)

  let instantiated := e.instantiate [.lit (.nat 9)]
  expectSharing "no-op instantiate preserves root object" (sameObject e instantiated)

  let absent : Name := .str .anonymous "absent"
  let abstracted := e.abstractFVars [absent]
  expectSharing "no-op abstract preserves root object" (sameObject e abstracted)

  let levelInstantiated := e.instantiateLevelParams [] []
  expectSharing "empty level substitution preserves root object"
    (sameObject e levelInstantiated)

  let withBVar : Expr := .app c (.bvar 0)
  let instantiatedChanged := withBVar.instantiate [.lit (.nat 9)]
  expectSharing "instantiate still changes targeted bvar"
    (Expr.eq instantiatedChanged (.app c (.lit (.nat 9))))

  let present : Name := .str .anonymous "x"
  let withFVar : Expr := .app c (.fvar present)
  let abstractedChanged := withFVar.abstractFVars [present]
  expectSharing "abstract still changes targeted fvar"
    (Expr.eq abstractedChanged (.app c (.bvar 0)))

  IO.println "PSC1 instantiate sharing smoke: PASS"
