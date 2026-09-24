import Lean

open Lean

def constantKind : ConstantInfo → String
  | .axiomInfo .. => "axiom"
  | .defnInfo .. => "definition"
  | .thmInfo .. => "theorem"
  | .opaqueInfo .. => "opaque"
  | .quotInfo .. => "quot"
  | .inductInfo .. => "inductive"
  | .ctorInfo .. => "constructor"
  | .recInfo .. => "recursor"

def infoJson (env : Environment) (name : Name) : Json :=
  match env.find? name with
  | none =>
    Json.mkObj [
      ("name", name.toString),
      ("missing", true)
    ]
  | some ci =>
    let base : List (String × Json) := [
      ("name", toJson name.toString),
      ("kind", toJson (constantKind ci)),
      ("type", toJson (reprStr ci.type)),
      ("isUnsafe", toJson ci.isUnsafe)
    ]
    match ci with
    | .inductInfo iv =>
      Json.mkObj <| base ++ [
        ("ctors", Json.arr <| iv.ctors.toArray.map (fun n => toJson n.toString)),
        ("numParams", toJson iv.numParams),
        ("numIndices", toJson iv.numIndices)
      ]
    | .ctorInfo cv =>
      Json.mkObj <| base ++ [
        ("induct", toJson cv.induct.toString),
        ("numParams", toJson cv.numParams),
        ("numFields", toJson cv.numFields)
      ]
    | _ => Json.mkObj base

unsafe def main : IO Unit := do
  initSearchPath (← findSysroot)
  withImportModules #[{module := `Lean.Level}] {} fun env => do
    for name in [
      `Lean.Level,
      `Lean.Level.zero,
      `Lean.Level.succ,
      `Lean.Level.max,
      `Lean.Level.imax,
      `Lean.Level.param,
      `Lean.Level.mvar,
      `Lean.Level_impl,
      `Lean.Level.zero_impl,
      `Lean.Level.succ_impl,
      `Lean.Level.max_impl,
      `Lean.Level.imax_impl,
      `Lean.Level.param_impl,
      `Lean.Level.mvar_impl
    ] do
      IO.println (infoJson env name).compress
