import Lean

open Lean

partial def psEndsInSort : Expr → Bool
  | .forallE _ _ body _ => psEndsInSort body
  | .sort _ => true
  | _ => false

def psConstantKindText : ConstantInfo → String
  | .axiomInfo _ => "axiom"
  | .defnInfo _ => "definition"
  | .thmInfo _ => "theorem"
  | .opaqueInfo _ => "opaque"
  | .quotInfo _ => "quotient"
  | .inductInfo _ => "inductive"
  | .ctorInfo _ => "constructor"
  | .recInfo _ => "recursor"

def psBoolText (value : Bool) : String :=
  if value then "true" else "false"

unsafe def psPrintTypeSurface
    (surface : String)
    (moduleName : Name) : IO Unit := do
  let env ← Lean.importModules #[{ module := moduleName }] {}
  let records :=
    env.constants.fold (init := #[]) fun records name info =>
      if psEndsInSort info.type then
        let definingModule :=
          match env.getModuleIdxFor? name with
          | none => "<builtin>"
          | some moduleIdx => env.header.moduleNames[moduleIdx.toNat]!.toString
        records.push
          (name.toString, psConstantKindText info, psBoolText name.isInternal, definingModule)
      else
        records
  IO.println ("SURFACE\t" ++ surface ++ "\t" ++ toString records.size)
  for record in records do
    IO.println
      ("TYPE\t" ++ surface ++ "\t" ++ record.1 ++ "\t" ++ record.2.1 ++ "\t" ++
        record.2.2.1 ++ "\t" ++ record.2.2.2)

unsafe def main : IO Unit := do
  Lean.initSearchPath (← Lean.findSysroot)
  psPrintTypeSurface "Init" `Init
  psPrintTypeSurface "Std" `Std
  psPrintTypeSurface "Lean" `Lean
