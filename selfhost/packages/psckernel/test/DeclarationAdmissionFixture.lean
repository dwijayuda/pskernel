import Ps.PSCKernel.Core.DeclarationAdmission

def psCKernelAdmissionFixtureName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelAdmissionFixtureBase
    (name : String)
    (levelParams : List PsCKernelName)
    (declType : PsCKernelExpr) : PsCKernelConstantVal := {
  name := psCKernelAdmissionFixtureName name
  levelParams := levelParams
  declType := declType
}

def psCKernelAdmissionFixtureAxiom
    (name : String)
    (levelParams : List PsCKernelName)
    (declType : PsCKernelExpr) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.axiomInfo {
    base := psCKernelAdmissionFixtureBase name levelParams declType
    isUnsafe := false
  }

def psCKernelAdmissionFixtureDef
    (name : String)
    (levelParams : List PsCKernelName)
    (declType value : PsCKernelExpr) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.defnInfo {
    base := psCKernelAdmissionFixtureBase name levelParams declType
    value := value
    hints := PsCKernelReducibilityHints.regular 0
    safety := PsCKernelDefinitionSafety.safe
    all := [psCKernelAdmissionFixtureName name]
  }

def psCKernelAdmissionFixtureThm
    (name : String)
    (declType value : PsCKernelExpr) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.thmInfo {
    base := psCKernelAdmissionFixtureBase name [] declType
    value := value
    all := [psCKernelAdmissionFixtureName name]
  }

def psCKernelAdmissionFixtureOpaque
    (name : String)
    (declType value : PsCKernelExpr) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.opaqueInfo {
    base := psCKernelAdmissionFixtureBase name [] declType
    value := value
    isUnsafe := false
    all := [psCKernelAdmissionFixtureName name]
  }

def psCKernelAdmissionFixtureP : PsCKernelName :=
  psCKernelAdmissionFixtureName "P"

def psCKernelAdmissionFixtureProof : PsCKernelName :=
  psCKernelAdmissionFixtureName "p"

def psCKernelAdmissionFixtureSeed : PsCKernelEnvironment :=
  let env0 := psCKernelEnvironmentEmpty
  let propInfo := psCKernelAdmissionFixtureAxiom
    "P" [] (PsCKernelExpr.sortE psCKernelLevelZero)
  let env1 :=
    match psCKernelEnvironmentTryAdd env0 propInfo with
    | some env => env
    | none => env0
  let proofInfo := psCKernelAdmissionFixtureAxiom
    "p" [] (PsCKernelExpr.constE psCKernelAdmissionFixtureP [])
  match psCKernelEnvironmentTryAdd env1 proofInfo with
  | some env => env
  | none => env1

def psCKernelAdmissionFixtureAccepted
    (env : PsCKernelEnvironment)
    (info : PsCKernelConstantInfo) : Bool :=
  match psCKernelAdmitConstant? env info with
  | some _ => true
  | none => false

def psCKernelAdmissionFixtureEmit (key : String) (value : Bool) : IO Unit :=
  IO.println (key ++ "\t" ++ (if value then "true" else "false"))

def main : IO Unit := do
  let sort0 := PsCKernelExpr.sortE psCKernelLevelZero
  let sort1 := PsCKernelExpr.sortE (psCKernelLevelSucc psCKernelLevelZero)
  let propExpr := PsCKernelExpr.constE psCKernelAdmissionFixtureP []
  let proofExpr := PsCKernelExpr.constE psCKernelAdmissionFixtureProof []

  psCKernelAdmissionFixtureEmit "valid-axiom"
    (psCKernelAdmissionFixtureAccepted
      psCKernelEnvironmentEmpty
      (psCKernelAdmissionFixtureAxiom "A" [] sort0))

  psCKernelAdmissionFixtureEmit "duplicate-name"
    (psCKernelAdmissionFixtureAccepted
      psCKernelAdmissionFixtureSeed
      (psCKernelAdmissionFixtureAxiom "P" [] sort0))

  let u := psCKernelAdmissionFixtureName "u"
  psCKernelAdmissionFixtureEmit "duplicate-level-params"
    (psCKernelAdmissionFixtureAccepted
      psCKernelEnvironmentEmpty
      (psCKernelAdmissionFixtureAxiom
        "A" [u, u] (PsCKernelExpr.sortE (PsCKernelLevel.param u))))

  psCKernelAdmissionFixtureEmit "declared-level-param"
    (psCKernelAdmissionFixtureAccepted
      psCKernelEnvironmentEmpty
      (psCKernelAdmissionFixtureAxiom
        "Poly" [u] (PsCKernelExpr.sortE (PsCKernelLevel.param u))))

  psCKernelAdmissionFixtureEmit "undefined-level-param"
    (psCKernelAdmissionFixtureAccepted
      psCKernelEnvironmentEmpty
      (psCKernelAdmissionFixtureAxiom
        "BadPoly" [] (PsCKernelExpr.sortE (PsCKernelLevel.param u))))

  psCKernelAdmissionFixtureEmit "type-must-be-type"
    (psCKernelAdmissionFixtureAccepted
      psCKernelAdmissionFixtureSeed
      (psCKernelAdmissionFixtureAxiom "badType" [] proofExpr))

  let freeId : PsCKernelFVarId := { name := psCKernelAdmissionFixtureName "free" }
  psCKernelAdmissionFixtureEmit "free-var-closed"
    (psCKernelAdmissionFixtureAccepted
      psCKernelEnvironmentEmpty
      (psCKernelAdmissionFixtureAxiom "freeType" [] (PsCKernelExpr.fvar freeId)))

  psCKernelAdmissionFixtureEmit "loose-bvar-closed"
    (psCKernelAdmissionFixtureAccepted
      psCKernelEnvironmentEmpty
      (psCKernelAdmissionFixtureAxiom "loose" [] (PsCKernelExpr.bvar 0)))

  let metaId : PsCKernelMVarId := { name := psCKernelAdmissionFixtureName "m" }
  psCKernelAdmissionFixtureEmit "mvar-closed"
    (psCKernelAdmissionFixtureAccepted
      psCKernelEnvironmentEmpty
      (psCKernelAdmissionFixtureAxiom "meta" [] (PsCKernelExpr.mvar metaId)))

  psCKernelAdmissionFixtureEmit "valid-definition"
    (psCKernelAdmissionFixtureAccepted
      psCKernelEnvironmentEmpty
      (psCKernelAdmissionFixtureDef "U" [] sort1 sort0))

  psCKernelAdmissionFixtureEmit "definition-mismatch"
    (psCKernelAdmissionFixtureAccepted
      psCKernelEnvironmentEmpty
      (psCKernelAdmissionFixtureDef "badDef" [] sort0 sort0))

  psCKernelAdmissionFixtureEmit "definition-value-closed"
    (psCKernelAdmissionFixtureAccepted
      psCKernelEnvironmentEmpty
      (psCKernelAdmissionFixtureDef "badValue" [] sort1 (PsCKernelExpr.fvar freeId)))

  psCKernelAdmissionFixtureEmit "valid-theorem"
    (psCKernelAdmissionFixtureAccepted
      psCKernelAdmissionFixtureSeed
      (psCKernelAdmissionFixtureThm "T" propExpr proofExpr))

  psCKernelAdmissionFixtureEmit "theorem-requires-prop"
    (psCKernelAdmissionFixtureAccepted
      psCKernelAdmissionFixtureSeed
      (psCKernelAdmissionFixtureThm "notTheorem" sort0 proofExpr))

  psCKernelAdmissionFixtureEmit "valid-opaque"
    (psCKernelAdmissionFixtureAccepted
      psCKernelEnvironmentEmpty
      (psCKernelAdmissionFixtureOpaque "O" sort1 sort0))

  psCKernelAdmissionFixtureEmit "opaque-mismatch"
    (psCKernelAdmissionFixtureAccepted
      psCKernelEnvironmentEmpty
      (psCKernelAdmissionFixtureOpaque "badOpaque" sort0 sort0))

  let before := psCKernelEnvironmentSize psCKernelAdmissionFixtureSeed
  let _ := psCKernelAdmitConstant?
    psCKernelAdmissionFixtureSeed
    (psCKernelAdmissionFixtureDef "badTxn" [] sort0 sort0)
  psCKernelAdmissionFixtureEmit "failure-persistent"
    (Nat.beq before (psCKernelEnvironmentSize psCKernelAdmissionFixtureSeed))
