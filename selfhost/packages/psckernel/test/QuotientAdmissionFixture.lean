import Ps.PSCKernel.Core.QuotientAdmission

def psCKernelQuotAdmissionFixtureName (text : String) : PsCKernelName :=
  psCKernelNameFromDotted text

def psCKernelQuotAdmissionFixtureArrow
    (domain codomain : PsCKernelExpr) : PsCKernelExpr :=
  PsCKernelExpr.forallE
    (psCKernelQuotAdmissionFixtureName "_")
    domain
    codomain
    PsCKernelBinderInfo.default

def psCKernelQuotAdmissionFixtureEqType
    (uName : PsCKernelName) : PsCKernelExpr :=
  let u := PsCKernelLevel.param uName
  PsCKernelExpr.forallE
    (psCKernelQuotAdmissionFixtureName "α")
    (PsCKernelExpr.sortE u)
    (psCKernelQuotAdmissionFixtureArrow
      (PsCKernelExpr.bvar 0)
      (psCKernelQuotAdmissionFixtureArrow
        (PsCKernelExpr.bvar 1)
        (PsCKernelExpr.sortE psCKernelLevelZero)))
    PsCKernelBinderInfo.implicit

def psCKernelQuotAdmissionFixtureEqReflType
    (uName : PsCKernelName) : PsCKernelExpr :=
  let u := PsCKernelLevel.param uName
  PsCKernelExpr.forallE
    (psCKernelQuotAdmissionFixtureName "α")
    (PsCKernelExpr.sortE u)
    (PsCKernelExpr.forallE
      (psCKernelQuotAdmissionFixtureName "a")
      (PsCKernelExpr.bvar 0)
      (psCKernelExprMkAppN
        (PsCKernelExpr.constE (psCKernelQuotAdmissionFixtureName "Eq") [u])
        [PsCKernelExpr.bvar 1, PsCKernelExpr.bvar 0, PsCKernelExpr.bvar 0])
      PsCKernelBinderInfo.default)
    PsCKernelBinderInfo.implicit

def psCKernelQuotAdmissionFixtureBase
    (name : PsCKernelName)
    (levelParams : List PsCKernelName)
    (declType : PsCKernelExpr) : PsCKernelConstantVal := {
  name := name
  levelParams := levelParams
  declType := declType
}

def psCKernelQuotAdmissionFixtureAddRaw
    (env : PsCKernelEnvironment)
    (info : PsCKernelConstantInfo) : PsCKernelEnvironment :=
  match psCKernelEnvironmentTryAdd env info with
  | some next => next
  | none => env

def psCKernelQuotAdmissionFixtureSeedEq
    (eqTypeOverride : Option PsCKernelExpr := none)
    (reflTypeOverride : Option PsCKernelExpr := none)
    (extraCtor : Bool := false)
    (eqAsAxiom : Bool := false)
    (uParams : List PsCKernelName := [psCKernelQuotAdmissionFixtureName "u"]) : PsCKernelEnvironment :=
  let uName :=
    match uParams with
    | head :: _ => head
    | [] => psCKernelQuotAdmissionFixtureName "u"
  let eqName := psCKernelQuotAdmissionFixtureName "Eq"
  let reflName := psCKernelQuotAdmissionFixtureName "Eq.refl"
  let extraName := psCKernelQuotAdmissionFixtureName "Eq.extra"
  let eqType :=
    match eqTypeOverride with
    | some type => type
    | none => psCKernelQuotAdmissionFixtureEqType uName
  let reflType :=
    match reflTypeOverride with
    | some type => type
    | none => psCKernelQuotAdmissionFixtureEqReflType uName
  let env0 := psCKernelEnvironmentEmpty
  let eqInfo :=
    if eqAsAxiom then
      PsCKernelConstantInfo.axiomInfo {
        base := psCKernelQuotAdmissionFixtureBase eqName uParams eqType
        isUnsafe := false
      }
    else
      PsCKernelConstantInfo.inductInfo {
        base := psCKernelQuotAdmissionFixtureBase eqName uParams eqType
        numParams := 2
        numIndices := 1
        all := [eqName]
        ctors := if extraCtor then [reflName, extraName] else [reflName]
        numNested := 0
        isRec := false
        isUnsafe := false
        isReflexive := false
      }
  let env1 := psCKernelQuotAdmissionFixtureAddRaw env0 eqInfo
  let reflInfo := PsCKernelConstantInfo.ctorInfo {
    base := psCKernelQuotAdmissionFixtureBase reflName [uName] reflType
    induct := eqName
    cidx := 0
    numParams := 2
    numFields := 0
    isUnsafe := false
  }
  let env2 := psCKernelQuotAdmissionFixtureAddRaw env1 reflInfo
  if extraCtor then
    psCKernelQuotAdmissionFixtureAddRaw env2 (PsCKernelConstantInfo.ctorInfo {
      base := psCKernelQuotAdmissionFixtureBase extraName [uName] reflType
      induct := eqName
      cidx := 1
      numParams := 2
      numFields := 0
      isUnsafe := false
    })
  else
    env2

def psCKernelQuotAdmissionFixtureAccepted
    (env : PsCKernelEnvironment) : Bool :=
  match psCKernelAddQuot? env with
  | some _ => true
  | none => false

def psCKernelQuotAdmissionFixtureLevelKey
    (level : PsCKernelLevel) : String :=
  match level with
  | PsCKernelLevel.zero => "0"
  | PsCKernelLevel.succ of =>
      "s(" ++ psCKernelQuotAdmissionFixtureLevelKey of ++ ")"
  | PsCKernelLevel.max left right =>
      "m(" ++ psCKernelQuotAdmissionFixtureLevelKey left ++ "," ++
        psCKernelQuotAdmissionFixtureLevelKey right ++ ")"
  | PsCKernelLevel.imax left right =>
      "i(" ++ psCKernelQuotAdmissionFixtureLevelKey left ++ "," ++
        psCKernelQuotAdmissionFixtureLevelKey right ++ ")"
  | PsCKernelLevel.param name =>
      "p{" ++ psCKernelNameToString name ++ "}"
  | PsCKernelLevel.mvar name =>
      "v{" ++ psCKernelNameToString name ++ "}"

def psCKernelQuotAdmissionFixtureLevelListKey
    (levels : List PsCKernelLevel) : String :=
  match levels with
  | [] => ""
  | level :: rest =>
      match rest with
      | [] => psCKernelQuotAdmissionFixtureLevelKey level
      | _ =>
          psCKernelQuotAdmissionFixtureLevelKey level ++ "," ++
          psCKernelQuotAdmissionFixtureLevelListKey rest

def psCKernelQuotAdmissionFixtureNameListKey
    (names : List PsCKernelName) : String :=
  match names with
  | [] => ""
  | name :: rest =>
      match rest with
      | [] => psCKernelNameToString name
      | _ =>
          psCKernelNameToString name ++ "," ++
          psCKernelQuotAdmissionFixtureNameListKey rest

def psCKernelQuotAdmissionFixtureBinderKey
    (info : PsCKernelBinderInfo) : String :=
  match info with
  | PsCKernelBinderInfo.default => "d"
  | PsCKernelBinderInfo.implicit => "i"
  | PsCKernelBinderInfo.strictImplicit => "s"
  | PsCKernelBinderInfo.instImplicit => "n"

def psCKernelQuotAdmissionFixtureExprKey
    (expr : PsCKernelExpr) : String :=
  match expr with
  | PsCKernelExpr.bvar index => "b" ++ toString index
  | PsCKernelExpr.fvar id =>
      "f{" ++ psCKernelNameToString id.name ++ "}"
  | PsCKernelExpr.mvar id =>
      "v{" ++ psCKernelNameToString id.name ++ "}"
  | PsCKernelExpr.sortE level =>
      "S{" ++ psCKernelQuotAdmissionFixtureLevelKey level ++ "}"
  | PsCKernelExpr.constE name levels =>
      "C{" ++ psCKernelNameToString name ++ "}[" ++
        psCKernelQuotAdmissionFixtureLevelListKey levels ++ "]"
  | PsCKernelExpr.app fn arg =>
      "A(" ++ psCKernelQuotAdmissionFixtureExprKey fn ++ "," ++
        psCKernelQuotAdmissionFixtureExprKey arg ++ ")"
  | PsCKernelExpr.lam name type body binderInfo =>
      "L{" ++ psCKernelNameToString name ++ ";" ++
        psCKernelQuotAdmissionFixtureBinderKey binderInfo ++ "}(" ++
        psCKernelQuotAdmissionFixtureExprKey type ++ "," ++
        psCKernelQuotAdmissionFixtureExprKey body ++ ")"
  | PsCKernelExpr.forallE name type body binderInfo =>
      "P{" ++ psCKernelNameToString name ++ ";" ++
        psCKernelQuotAdmissionFixtureBinderKey binderInfo ++ "}(" ++
        psCKernelQuotAdmissionFixtureExprKey type ++ "," ++
        psCKernelQuotAdmissionFixtureExprKey body ++ ")"
  | PsCKernelExpr.letE name type value body nondep =>
      "T{" ++ psCKernelNameToString name ++ ";" ++
        (if nondep then "1" else "0") ++ "}(" ++
        psCKernelQuotAdmissionFixtureExprKey type ++ "," ++
        psCKernelQuotAdmissionFixtureExprKey value ++ "," ++
        psCKernelQuotAdmissionFixtureExprKey body ++ ")"
  | PsCKernelExpr.lit literal =>
      match literal with
      | PsCKernelLiteral.natVal value => "N" ++ toString value
      | PsCKernelLiteral.strVal value => "Q" ++ value
  | PsCKernelExpr.proj typeName index value =>
      "R{" ++ psCKernelNameToString typeName ++ ";" ++ toString index ++ "}(" ++
        psCKernelQuotAdmissionFixtureExprKey value ++ ")"

def psCKernelQuotAdmissionFixtureKindKey
    (kind : PsCKernelQuotKind) : String :=
  match kind with
  | PsCKernelQuotKind.type => "type"
  | PsCKernelQuotKind.ctor => "ctor"
  | PsCKernelQuotKind.lift => "lift"
  | PsCKernelQuotKind.ind => "ind"

def psCKernelQuotAdmissionFixtureInfoKey
    (env : PsCKernelEnvironment)
    (name : PsCKernelName) : String :=
  match psCKernelEnvironmentFind? env name with
  | some (PsCKernelConstantInfo.quotInfo info) =>
      psCKernelQuotAdmissionFixtureKindKey info.kind ++ "|" ++
      psCKernelQuotAdmissionFixtureNameListKey info.base.levelParams ++ "|" ++
      psCKernelQuotAdmissionFixtureExprKey info.base.declType
  | _ => "none"

def psCKernelQuotAdmissionFixtureEmit
    (key value : String) : IO Unit :=
  IO.println (key ++ "\t" ++ value)

def psCKernelQuotAdmissionFixtureEmitBool
    (key : String)
    (value : Bool) : IO Unit :=
  psCKernelQuotAdmissionFixtureEmit key (if value then "true" else "false")

def psCKernelQuotAdmissionFixtureConflict
    (name : String) : Bool :=
  let env0 := psCKernelQuotAdmissionFixtureSeedEq
  let conflict := PsCKernelConstantInfo.axiomInfo {
    base := psCKernelQuotAdmissionFixtureBase
      (psCKernelQuotAdmissionFixtureName name)
      []
      (PsCKernelExpr.sortE psCKernelLevelZero)
    isUnsafe := false
  }
  let env := psCKernelQuotAdmissionFixtureAddRaw env0 conflict
  !psCKernelQuotAdmissionFixtureAccepted env

def main : IO Unit := do
  let validSeed := psCKernelQuotAdmissionFixtureSeedEq
  match psCKernelAddQuot? validSeed with
  | none =>
      psCKernelQuotAdmissionFixtureEmitBool "valid-init" false
      psCKernelQuotAdmissionFixtureEmit "quot-info" "none"
      psCKernelQuotAdmissionFixtureEmit "quot-mk-info" "none"
      psCKernelQuotAdmissionFixtureEmit "quot-lift-info" "none"
      psCKernelQuotAdmissionFixtureEmit "quot-ind-info" "none"
  | some env =>
      psCKernelQuotAdmissionFixtureEmitBool "valid-init"
        (env.quotInitialized && Nat.beq (psCKernelEnvironmentSize env) 6)
      psCKernelQuotAdmissionFixtureEmit "quot-info"
        (psCKernelQuotAdmissionFixtureInfoKey env
          (psCKernelQuotAdmissionFixtureName "Quot"))
      psCKernelQuotAdmissionFixtureEmit "quot-mk-info"
        (psCKernelQuotAdmissionFixtureInfoKey env
          (psCKernelQuotAdmissionFixtureName "Quot.mk"))
      psCKernelQuotAdmissionFixtureEmit "quot-lift-info"
        (psCKernelQuotAdmissionFixtureInfoKey env
          (psCKernelQuotAdmissionFixtureName "Quot.lift"))
      psCKernelQuotAdmissionFixtureEmit "quot-ind-info"
        (psCKernelQuotAdmissionFixtureInfoKey env
          (psCKernelQuotAdmissionFixtureName "Quot.ind"))

  let idempotent :=
    match psCKernelAddQuot? psCKernelQuotAdmissionFixtureSeedEq with
    | none => false
    | some once =>
        match psCKernelAddQuot? once with
        | none => false
        | some twice =>
            once.quotInitialized && twice.quotInitialized &&
            Nat.beq (psCKernelEnvironmentSize once) (psCKernelEnvironmentSize twice)
  psCKernelQuotAdmissionFixtureEmitBool "idempotent" idempotent

  psCKernelQuotAdmissionFixtureEmitBool "missing-eq"
    (!psCKernelQuotAdmissionFixtureAccepted psCKernelEnvironmentEmpty)

  psCKernelQuotAdmissionFixtureEmitBool "eq-wrong-kind"
    (!psCKernelQuotAdmissionFixtureAccepted
      (psCKernelQuotAdmissionFixtureSeedEq (eqAsAxiom := true)))

  let u := psCKernelQuotAdmissionFixtureName "u"
  let v := psCKernelQuotAdmissionFixtureName "v"
  psCKernelQuotAdmissionFixtureEmitBool "eq-wrong-universe-arity"
    (!psCKernelQuotAdmissionFixtureAccepted
      (psCKernelQuotAdmissionFixtureSeedEq (uParams := [u, v])))

  psCKernelQuotAdmissionFixtureEmitBool "eq-wrong-ctor-count"
    (!psCKernelQuotAdmissionFixtureAccepted
      (psCKernelQuotAdmissionFixtureSeedEq (extraCtor := true)))

  let badType := PsCKernelExpr.sortE psCKernelLevelZero
  psCKernelQuotAdmissionFixtureEmitBool "eq-wrong-type"
    (!psCKernelQuotAdmissionFixtureAccepted
      (psCKernelQuotAdmissionFixtureSeedEq (eqTypeOverride := some badType)))

  psCKernelQuotAdmissionFixtureEmitBool "refl-wrong-type"
    (!psCKernelQuotAdmissionFixtureAccepted
      (psCKernelQuotAdmissionFixtureSeedEq (reflTypeOverride := some badType)))

  psCKernelQuotAdmissionFixtureEmitBool "conflict-quot"
    (psCKernelQuotAdmissionFixtureConflict "Quot")
  psCKernelQuotAdmissionFixtureEmitBool "conflict-quot-mk"
    (psCKernelQuotAdmissionFixtureConflict "Quot.mk")
  psCKernelQuotAdmissionFixtureEmitBool "conflict-quot-lift"
    (psCKernelQuotAdmissionFixtureConflict "Quot.lift")
  psCKernelQuotAdmissionFixtureEmitBool "conflict-quot-ind"
    (psCKernelQuotAdmissionFixtureConflict "Quot.ind")

  let failedEnv :=
    psCKernelQuotAdmissionFixtureSeedEq (eqTypeOverride := some badType)
  let before := psCKernelEnvironmentSize failedEnv
  let rejected := !psCKernelQuotAdmissionFixtureAccepted failedEnv
  psCKernelQuotAdmissionFixtureEmitBool "failure-persistent"
    (rejected &&
      Nat.beq before (psCKernelEnvironmentSize failedEnv) &&
      !failedEnv.quotInitialized)
