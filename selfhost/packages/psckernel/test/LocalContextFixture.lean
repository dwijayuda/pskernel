import Ps.PSCKernel.Core.LocalContext

def psCKernelLocalContextFixtureBoolText (value : Bool) : String :=
  if value then "true" else "false"

def psCKernelLocalContextFixtureEmit (key : String) (value : String) : IO Unit :=
  IO.println (key ++ "\t" ++ value)

def psCKernelLocalContextFixtureDeclTag (decl : PsCKernelLocalDecl) : String :=
  match decl with
  | PsCKernelLocalDecl.cdecl _ _ _ _ _ _ => "local"
  | PsCKernelLocalDecl.ldecl _ _ _ _ _ _ _ => "let"

def psCKernelLocalContextFixtureBinderKey
    (binderInfo : PsCKernelBinderInfo) : String :=
  match binderInfo with
  | PsCKernelBinderInfo.default => "d"
  | PsCKernelBinderInfo.implicit => "i"
  | PsCKernelBinderInfo.strictImplicit => "s"
  | PsCKernelBinderInfo.instImplicit => "c"

def psCKernelLocalContextFixtureEntryIds
    (decls : List PsCKernelLocalDecl) : String :=
  match decls with
  | [] => ""
  | decl :: rest =>
      let idText : String :=
        psCKernelNameToString (psCKernelLocalDeclFVarId decl).name
      match rest with
      | [] => idText
      | _ => idText ++ "," ++ psCKernelLocalContextFixtureEntryIds rest

def psCKernelLocalContextFixtureConst (name : String) : PsCKernelExpr :=
  PsCKernelExpr.constE (psCKernelNameFromDotted name) []

def main : IO Unit := do
  let nameX : PsCKernelName := psCKernelNameFromDotted "x"
  let nameY : PsCKernelName := psCKernelNameFromDotted "y"
  let nameZ : PsCKernelName := psCKernelNameFromDotted "z"
  let idX : PsCKernelFVarId := { name := nameX }
  let idY : PsCKernelFVarId := { name := nameY }
  let idZ : PsCKernelFVarId := { name := nameZ }
  let typeT : PsCKernelExpr := psCKernelLocalContextFixtureConst "T"
  let typeU : PsCKernelExpr := psCKernelLocalContextFixtureConst "U"
  let valueV : PsCKernelExpr := psCKernelLocalContextFixtureConst "v"
  let first : PsCKernelLocalContext :=
    psCKernelLocalContextMkLocalDecl
      psCKernelLocalContextEmpty
      idX
      nameX
      typeT
      PsCKernelBinderInfo.implicit
      PsCKernelLocalDeclKind.default
  let ctx : PsCKernelLocalContext :=
    psCKernelLocalContextMkLetDecl
      first
      idY
      nameY
      typeU
      valueV
      false
      PsCKernelLocalDeclKind.default
  let extended : PsCKernelLocalContext :=
    psCKernelLocalContextMkLocalDecl
      ctx
      idZ
      nameZ
      typeT
      PsCKernelBinderInfo.default
      PsCKernelLocalDeclKind.default

  psCKernelLocalContextFixtureEmit
    "entries.order"
    (psCKernelLocalContextFixtureEntryIds (psCKernelLocalContextEntries ctx))
  psCKernelLocalContextFixtureEmit
    "entries.count"
    (toString (psCKernelLocalContextNumIndices ctx))

  match psCKernelLocalContextFind? ctx idX with
  | none =>
      psCKernelLocalContextFixtureEmit "local.kind" "missing"
      psCKernelLocalContextFixtureEmit "local.binder" "missing"
      psCKernelLocalContextFixtureEmit "local.user" "missing"
      psCKernelLocalContextFixtureEmit "local.type" "false"
  | some decl =>
      psCKernelLocalContextFixtureEmit
        "local.kind"
        (psCKernelLocalContextFixtureDeclTag decl)
      psCKernelLocalContextFixtureEmit
        "local.binder"
        (psCKernelLocalContextFixtureBinderKey (psCKernelLocalDeclBinderInfo decl))
      psCKernelLocalContextFixtureEmit
        "local.user"
        (psCKernelNameToString (psCKernelLocalDeclUserName decl))
      psCKernelLocalContextFixtureEmit
        "local.type"
        (psCKernelLocalContextFixtureBoolText
          (psCKernelExprEqStructural (psCKernelLocalDeclType decl) typeT))

  match psCKernelLocalContextFind? ctx idY with
  | none =>
      psCKernelLocalContextFixtureEmit "let.kind" "missing"
      psCKernelLocalContextFixtureEmit "let.value" "false"
  | some decl =>
      psCKernelLocalContextFixtureEmit
        "let.kind"
        (psCKernelLocalContextFixtureDeclTag decl)
      match psCKernelLocalDeclValue? decl false with
      | none => psCKernelLocalContextFixtureEmit "let.value" "false"
      | some value =>
          psCKernelLocalContextFixtureEmit
            "let.value"
            (psCKernelLocalContextFixtureBoolText
              (psCKernelExprEqStructural value valueV))

  psCKernelLocalContextFixtureEmit
    "missing"
    (psCKernelLocalContextFixtureBoolText
      (!psCKernelLocalContextContains ctx idZ))
  psCKernelLocalContextFixtureEmit
    "persistent"
    (psCKernelLocalContextFixtureBoolText
      (Nat.beq (psCKernelLocalContextNumIndices ctx) 2 &&
        Nat.beq (psCKernelLocalContextNumIndices extended) 3))
