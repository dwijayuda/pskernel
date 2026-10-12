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

-- Exact reviewed signatures at the pinned native toolchain. These exceptions
-- encode existing universe restriction / position representation policies.
-- New mismatches fail qualification instead of expanding trust implicitly.
private def modeledSignatures : List (String × String × String) := [
  ("Array.foldl", "forall {α : Type} {b : Type}, (b -> α -> b) -> b -> (Array α) -> Nat -> Nat -> b", "forall {α : Type.{u}} {β : Type.{v}}, (β -> α -> β) -> β -> (forall (as : Array.{u} α), (optParam.{1} Nat (OfNat.ofNat.{0} Nat 0 (instOfNatNat 0))) -> (optParam.{1} Nat (Array.size.{u} α as)) -> β)"),
  ("Array.map", "forall {α : Type} {b : Type}, (α -> b) -> (Array α) -> (Array b)", "forall {α : Type.{u}} {β : Type.{v}}, (α -> β) -> (Array.{u} α) -> (Array.{v} β)"),
  ("Array.setIfInBounds", "forall {α : Type}, (Array α) -> Nat -> α -> (Array α)", "forall {α : Type.{u_1}}, (Array.{u_1} α) -> Nat -> α -> (Array.{u_1} α)"),
  ("Array.getD", "forall {α : Type}, (Array α) -> Nat -> α -> α", "forall {α : Type.{u_1}}, (Array.{u_1} α) -> Nat -> α -> α"),
  ("Array.push", "forall {α : Type}, (Array α) -> α -> (Array α)", "forall {α : Type.{u}}, (Array.{u} α) -> α -> (Array.{u} α)"),
  ("Array.size", "forall {α : Type}, (Array α) -> Nat", "forall {α : Type.{u}}, ([mdata borrowed:1 Array.{u} α]) -> Nat"),
  ("Array.emptyWithCapacity", "forall {α : Type}, Nat -> (Array α)", "forall {α : Type.{u}}, ([mdata borrowed:1 Nat]) -> (Array.{u} α)"),
  ("Array", "Type -> Type", "Type.{u} -> Type.{u}"),
  ("Prod.snd", "forall {α : Type} {β : Type}, (Prod α β) -> β", "forall {α : Type.{u}} {β : Type.{v}}, (Prod.{u, v} α β) -> β"),
  ("Prod.fst", "forall {α : Type} {β : Type}, (Prod α β) -> α", "forall {α : Type.{u}} {β : Type.{v}}, (Prod.{u, v} α β) -> α"),
  ("String.Pos.Raw.byteIdx", "Nat -> Nat", "String.Pos.Raw -> Nat"),
  ("String.Pos.Raw.mk", "Nat -> Nat", "Nat -> String.Pos.Raw"),
  ("String.Internal.extract", "String -> Nat -> Nat -> String", "([mdata borrowed:1 String]) -> ([mdata borrowed:1 String.Pos.Raw]) -> ([mdata borrowed:1 String.Pos.Raw]) -> String"),
  ("String.Internal.atEnd", "String -> Nat -> Bool", "([mdata borrowed:1 String]) -> ([mdata borrowed:1 String.Pos.Raw]) -> Bool"),
  ("String.Internal.get", "String -> Nat -> Char", "([mdata borrowed:1 String]) -> ([mdata borrowed:1 String.Pos.Raw]) -> Char"),
  ("String.Internal.next", "String -> Nat -> Nat", "([mdata borrowed:1 String]) -> ([mdata borrowed:1 String.Pos.Raw]) -> String.Pos.Raw")]

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
      if !matched then
        let found := modeledSignatures.any fun (name, expected, nativeType) =>
          name == toString nativeName && expected == portable.dbgToString &&
            some nativeType == original.map (fun info => info.type.dbgToString)
        if !found then throw (IO.userError ("unreviewed primitive signature mismatch: " ++ toString nativeName))
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
