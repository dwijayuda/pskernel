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

unsafe def main : IO Unit := do
  Lean.initSearchPath (← Lean.findSysroot)
  let env ← Lean.importModules #[{ module := `Init }] {}
  let records :=
    env.constants.fold (init := #[]) fun records name info =>
      if psEndsInSort info.type then
        records.push (name.toString, psConstantKindText info)
      else
        records
  IO.println s!"LEAN434_INIT_TYPE_COUNT\t{records.size}"
  for record in records do
    IO.println ("TYPE\t" ++ record.1 ++ "\t" ++ record.2)
