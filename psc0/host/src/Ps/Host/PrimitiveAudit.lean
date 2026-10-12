import PsKernelLean.Prelude

namespace PsV7Native

-- This is a signature audit, not a proof that foreign runtime bodies implement
-- Lean definitions. Prelude axioms remain explicit assumptions.
private def normalizeLevel (parameters : List Lean.Name) : Lean.Level → Lean.Level
  | .param name => .param (.num (.str .anonymous "u") (parameters.idxOf name))
  | .succ value => .succ (normalizeLevel parameters value)
  | .max a b => .max (normalizeLevel parameters a) (normalizeLevel parameters b)
  | .imax a b => .imax (normalizeLevel parameters a) (normalizeLevel parameters b)
  | value => value

private def normalizeType (parameters : List Lean.Name) : Lean.Expr → Lean.Expr
  | .sort level => .sort (normalizeLevel parameters level)
  | .const name levels => .const name (levels.map (normalizeLevel parameters))
  | .app fn arg => .app (normalizeType parameters fn) (normalizeType parameters arg)
  | .lam name type body binder => .lam name (normalizeType parameters type) (normalizeType parameters body) binder
  | .forallE name type body binder =>
      .forallE name (normalizeType parameters type) (normalizeType parameters body) binder
  | .letE name type value body nondep =>
      .letE name (normalizeType parameters type) (normalizeType parameters value) (normalizeType parameters body) nondep
  | .mdata _ value => normalizeType parameters value
  | .proj name index value => .proj name index (normalizeType parameters value)
  | value => value

def primitiveAudit : IO Lean.Json := do
  Lean.initSearchPath (← Lean.findSysroot)
  let native ← Lean.importModules #[{ module := `Init }] {}
  let mut entries := []
  for declaration in psSelfHostProdPreludeEnvironment.declarations do
    match declaration with
    | .axiomDecl name parameters type =>
      let nativeName := PsKernelLean.toLeanName name
      let portable ← match PsKernelLean.toLeanExpr type with
        | .ok value => pure value
        | .error _ => throw (IO.userError "primitive signature conversion failed")
      let original := native.find? nativeName
      let matched := match original with
        | none => false
        | some info => info.levelParams.length == parameters.length &&
            normalizeType (PsKernelLean.toLeanNames parameters) portable ==
              normalizeType info.levelParams info.type
      entries := Lean.Json.mkObj [
        ("name", Lean.toJson (toString nativeName)),
        ("signature", Lean.toJson (if matched then "native-alpha-match" else "portable-model")),
        ("portableType", Lean.toJson portable.dbgToString),
        ("nativeType", Lean.toJson (original.map (fun info => info.type.dbgToString))),
        ("bodyTrust", Lean.toJson ("assumption/runtime-primitive" : String))] :: entries
    | _ => pure ()
  return Lean.Json.mkObj [
    ("schema", Lean.toJson ("pscv0-primitive-signature-audit/1" : String)),
    ("leanCommit", Lean.toJson Lean.githash),
    ("limitation", Lean.toJson ("Signature comparison only; alpha matching ignores binder annotations. No runtime equivalence theorem." : String)),
    ("entries", Lean.toJson entries.reverse)]

end PsV7Native
