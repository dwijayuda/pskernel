import PSKernelFast.Proof.TypedConversion

namespace PSKernelFast.Core

private def require (ok : Bool) (message : String) : IO Unit :=
  if ok then pure () else throw (IO.userError message)

private def expectEqual {params : List KName}
    (ctx : GeneralPiContext params)
    (lhs rhs : KExpr) : IO Unit := do
  require (compareTypedHead ctx lhs rhs 1).isEqual
    "well-typed reference head conversion was declined"

private def expectUnresolved {params : List KName}
    (ctx : GeneralPiContext params)
    (lhs rhs : KExpr) : IO Unit := do
  match compareTypedHead ctx lhs rhs 1 with
  | .unresolved => pure ()
  | _ => throw (IO.userError
      "unsupported conversion was treated as equality or error")

def typedConversionSmoke : IO Unit := do
  let ctx := GeneralPiContext.empty []
  let x : KName := .str .anonymous "x"
  let zero : ULevel := .zero
  let one : ULevel := .succ zero
  let s0 : KExpr := .sort zero
  let s1 : KExpr := .sort one
  let id : KExpr := .lam x s1 (.bvar 0) .default
  let beta : KExpr := .app id s0
  let zeta : KExpr := .letE x s1 s0 (.bvar 0) false
  let flaggedLet : KExpr := .letE x s1 s0 (.bvar 0) true

  expectEqual ctx s0 s0
  expectEqual ctx beta s0
  expectEqual ctx zeta s0

  expectUnresolved ctx s0 beta
  expectUnresolved ctx s0 zeta
  expectUnresolved ctx beta zeta
  expectUnresolved ctx beta s1
  expectUnresolved ctx flaggedLet s0
  expectUnresolved ctx (.const x []) (.const x [])
  match compareTypedHead ctx (.bvar 0) (.bvar 0) 1 with
  | .malformed => pure ()
  | _ => throw (IO.userError "unbound variable did not fail closed")
  match compareTypedHead ctx beta s0 0 with
  | .resourceExhausted => pure ()
  | _ => throw (IO.userError "zero budget was not fail closed")
  match compareTypedHead ctx (.bvar 0) (.bvar 0) 0 with
  | .malformed => pure ()
  | _ => throw (IO.userError "malformed input did not precede resource status")

  let base := GeneralPiContext.empty []
  match base.extend s1 with
  | none => throw (IO.userError "valid checked context could not extend")
  | some c =>
      expectEqual c (.bvar 0) (.bvar 0)

  IO.println "PSKernel-Fast G4.4a typed positive-only head comparison PASS"

end PSKernelFast.Core

def main : IO Unit :=
  PSKernelFast.Core.typedConversionSmoke
