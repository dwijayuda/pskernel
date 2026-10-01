import Ps.Bridge.CheckedAdmissions
import PsKernelLean.Protocol
import PsKernelLean.Convert
import PsKernelLean.Prelude
import PsKernelLean.Admission

def expectEq (label actual expected : String) : IO Unit := do
  if actual == expected then
    pure ()
  else
    throw <| IO.userError s!"{label}: expected {expected}, got {actual}"

def expectTrue (label : String) (value : Bool) : IO Unit := do
  if value then
    pure ()
  else
    throw <| IO.userError s!"{label}: expected true"

def expectOk {α : Type} (label : String)
    (result : Except PsKernelLean.PsKernelLeanError α) : IO α := do
  match result with
  | .ok value => pure value
  | .error error =>
      throw <| IO.userError s!"{label}: unexpected error {error.message}"

def expectErrorKind {α : Type} (label : String)
    (expected : PsKernelLean.PsKernelLeanErrorKind)
    (result : Except PsKernelLean.PsKernelLeanError α) : IO Unit := do
  match result with
  | .ok _ => throw <| IO.userError s!"{label}: expected error"
  | .error error =>
      expectTrue label (error.kind == expected)

def testCoreConversion : IO Unit := do
  let psName := PsName.num (PsName.str PsName.anonymous "A") 7
  let expectedName := Lean.Name.num (Lean.Name.str Lean.Name.anonymous "A") 7
  expectTrue "name conversion" (PsKernelLean.toLeanName psName == expectedName)

  let psLevel := PsLevel.imax
    (PsLevel.max PsLevel.zero (PsLevel.param (PsName.str PsName.anonymous "u")))
    (PsLevel.succ PsLevel.zero)
  let leanLevel ← expectOk "level conversion" (PsKernelLean.toLeanLevel psLevel)
  let expectedLevel := Lean.Level.imax
    (Lean.Level.max Lean.Level.zero (Lean.Level.param (Lean.Name.str Lean.Name.anonymous "u")))
    (Lean.Level.succ Lean.Level.zero)
  expectTrue "level shape" (leanLevel == expectedLevel)
  expectErrorKind "level mvar rejection"
    .unsupportedCoreForm
    (PsKernelLean.toLeanLevel (PsLevel.mvar 1))

  let binderName := PsName.str PsName.anonymous "x"
  let natName := PsName.str PsName.anonymous "Nat"
  let type0 := PsExpr.sortE (PsLevel.succ PsLevel.zero)
  let natType := PsExpr.constE natName []
  let composite :=
    PsExpr.letE binderName type0 type0
      (PsExpr.forallE binderName natType
        (PsExpr.lam binderName natType
          (PsExpr.app
            (PsExpr.constE (PsName.str natName "succ") [])
            (PsExpr.bvar 0))
          PsBinderInfo.strictImplicit)
        PsBinderInfo.instanceImplicit)
  let leanComposite ← expectOk "expression conversion" (PsKernelLean.toLeanExpr composite)
  let expectedComposite :=
    Lean.Expr.letE (Lean.Name.str Lean.Name.anonymous "x")
      (Lean.Expr.sort (Lean.Level.succ Lean.Level.zero))
      (Lean.Expr.sort (Lean.Level.succ Lean.Level.zero))
      (Lean.Expr.forallE (Lean.Name.str Lean.Name.anonymous "x")
        (Lean.Expr.const (Lean.Name.str Lean.Name.anonymous "Nat") [])
        (Lean.Expr.lam (Lean.Name.str Lean.Name.anonymous "x")
          (Lean.Expr.const (Lean.Name.str Lean.Name.anonymous "Nat") [])
          (Lean.Expr.app
            (Lean.Expr.const
              (Lean.Name.str (Lean.Name.str Lean.Name.anonymous "Nat") "succ") [])
            (Lean.Expr.bvar 0))
          Lean.BinderInfo.strictImplicit)
        Lean.BinderInfo.instImplicit)
      false
  expectTrue "expression shape" (leanComposite == expectedComposite)

  let natLiteral ← expectOk "nat literal"
    (PsKernelLean.toLeanExpr (PsExpr.lit (PsLiteral.natural 13)))
  expectTrue "nat literal shape"
    (natLiteral == Lean.Expr.lit (Lean.Literal.natVal 13))
  let stringLiteral ← expectOk "string literal"
    (PsKernelLean.toLeanExpr (PsExpr.lit (PsLiteral.string "psc")))
  expectTrue "string literal shape"
    (stringLiteral == Lean.Expr.lit (Lean.Literal.strVal "psc"))
  let projection ← expectOk "projection"
    (PsKernelLean.toLeanExpr
      (PsExpr.proj
        (PsName.str PsName.anonymous "Pair")
        1
        (PsExpr.bvar 0)))
  expectTrue "projection shape"
    (projection ==
      Lean.Expr.proj (Lean.Name.str Lean.Name.anonymous "Pair") 1 (Lean.Expr.bvar 0))

  expectErrorKind "free variable rejection"
    .unsupportedCoreForm
    (PsKernelLean.toLeanExpr (PsExpr.fvar 1))
  expectErrorKind "expression metavariable rejection"
    .unsupportedCoreForm
    (PsKernelLean.toLeanExpr (PsExpr.mvar 1))

def testPreludeReplay : IO Unit := do
  let result ← PsKernelLean.buildLeanPreludeEnvironment
  let env ← expectOk "prelude replay" result
  expectTrue "trust level zero" (env.header.trustLevel == 0)
  let required : List Lean.Name := [
    Lean.Name.str Lean.Name.anonymous "Nat",
    Lean.Name.str (Lean.Name.str Lean.Name.anonymous "Nat") "zero",
    Lean.Name.str (Lean.Name.str Lean.Name.anonymous "Nat") "succ",
    Lean.Name.str Lean.Name.anonymous "List",
    Lean.Name.str Lean.Name.anonymous "Option",
    Lean.Name.str Lean.Name.anonymous "Except",
    Lean.Name.str Lean.Name.anonymous "Prod"
  ]
  for name in required do
    expectTrue s!"prelude declaration {name}" (env.find? name).isSome

def canonicalDecodeFixture : Except PsCheckedAdmissionCodecError String :=
  let natType := PsExpr.constE psNatName []
  let definitionDecl :=
    PsDeclaration.definitionDecl
      (psRootName "decodedDefinition")
      []
      natType
      (PsExpr.lit (PsLiteral.natural 1))
  let theoremDecl :=
    PsDeclaration.theoremDecl
      (psRootName "decodedTheorem")
      []
      (PsExpr.sortE PsLevel.zero)
      (PsExpr.sortE PsLevel.zero)
  let flagName := psRootName "DecodedFlag"
  let onName := psNameAppendStr flagName "on"
  let flagType := PsExpr.constE flagName []
  let inductiveDecl :=
    PsDeclaration.inductiveDecl
      (PsInductiveInfo.mk
        flagName
        []
        (PsExpr.sortE (PsLevel.succ PsLevel.zero))
        0
        0
        [onName]
        false)
  let constructorDecl :=
    PsDeclaration.constructorDecl
      (PsConstructorInfo.mk
        onName
        []
        flagType
        flagName
        0
        0
        0
        [])
  psEncodeCheckedAdmissionsCanonical
    [definitionDecl, theoremDecl, inductiveDecl, constructorDecl]

def testCanonicalAdmissionsDecode : IO Unit := do
  let encoded ←
    match canonicalDecodeFixture with
    | .ok value => pure value
    | .error _ => throw <| IO.userError "fixture encoding failed"
  let decoded ← expectOk "canonical admissions decode"
    (PsKernelLean.decodeCanonicalAdmissions encoded)
  match decoded.toList with
  | [Lean.Declaration.defnDecl definitionInfo,
     Lean.Declaration.thmDecl theoremInfo,
     Lean.Declaration.inductDecl _ 0 [inductiveInfo] false] =>
      expectTrue "decoded definition name"
        (definitionInfo.name == Lean.Name.str Lean.Name.anonymous "decodedDefinition")
      expectTrue "decoded definition regular height"
        (match definitionInfo.hints with | .regular 1 => true | _ => false)
      expectTrue "decoded theorem name"
        (theoremInfo.name == Lean.Name.str Lean.Name.anonymous "decodedTheorem")
      expectTrue "decoded inductive name"
        (inductiveInfo.name == Lean.Name.str Lean.Name.anonymous "DecodedFlag")
      match inductiveInfo.ctors with
      | [constructorInfo] =>
          expectTrue "decoded constructor name"
            (constructorInfo.name ==
              Lean.Name.str (Lean.Name.str Lean.Name.anonymous "DecodedFlag") "on")
      | _ => throw <| IO.userError "decoded constructor count"
  | _ => throw <| IO.userError "decoded declaration shapes"

def testCanonicalAdmissionsRejectMalformed : IO Unit := do
  expectErrorKind "malformed json" .malformedRequest
    (PsKernelLean.decodeCanonicalAdmissions "{")
  expectErrorKind "wrong format" .malformedRequest
    (PsKernelLean.decodeCanonicalAdmissions
      "{\"admissions\":[],\"format\":\"wrong\",\"version\":2}")
  expectErrorKind "wrong version" .protocolVersion
    (PsKernelLean.decodeCanonicalAdmissions
      "{\"admissions\":[],\"format\":\"proofscript-checked-admissions\",\"version\":1}")
  expectErrorKind "string version" .protocolVersion
    (PsKernelLean.decodeCanonicalAdmissions
      "{\"admissions\":[],\"format\":\"proofscript-checked-admissions\",\"version\":\"2\"}")
  expectErrorKind "unknown admission kind" .malformedRequest
    (PsKernelLean.decodeCanonicalAdmissions
      "{\"admissions\":[{\"declaration\":{},\"kind\":\"mystery\"}],\"format\":\"proofscript-checked-admissions\",\"version\":2}")
  expectErrorKind "malformed structured name" .malformedRequest
    (PsKernelLean.decodeCanonicalAdmissions
      "{\"admissions\":[{\"declaration\":{\"h\":{\"h\":\"1\",\"k\":\"regular\"},\"k\":\"definition\",\"lp\":[],\"n\":{\"k\":\"s\"},\"s\":\"safe\",\"t\":{\"k\":\"sort\",\"l\":{\"k\":\"z\"}},\"v\":{\"k\":\"sort\",\"l\":{\"k\":\"z\"}}},\"kind\":\"constant\"}],\"format\":\"proofscript-checked-admissions\",\"version\":2}")
  expectErrorKind "bad hint height" .malformedRequest
    (PsKernelLean.decodeCanonicalAdmissions
      "{\"admissions\":[{\"declaration\":{\"h\":{\"h\":\"01\",\"k\":\"regular\"},\"k\":\"definition\",\"lp\":[],\"n\":{\"k\":\"s\",\"p\":{\"k\":\"a\"},\"v\":\"bad\"},\"s\":\"safe\",\"t\":{\"k\":\"sort\",\"l\":{\"k\":\"z\"}},\"v\":{\"k\":\"sort\",\"l\":{\"k\":\"z\"}}},\"kind\":\"constant\"}],\"format\":\"proofscript-checked-admissions\",\"version\":2}")

def kernelAdmissionFixture
    (name : String)
    (value : PsExpr) : Except PsCheckedAdmissionCodecError String :=
  psEncodeCheckedAdmissionsCanonical [
    PsDeclaration.definitionDecl
      (psRootName name)
      []
      (PsExpr.constE psNatName [])
      value
  ]

def testKernelAdmission : IO Unit := do
  let acceptedSource ←
    match kernelAdmissionFixture "kernelAccepted" (PsExpr.lit (PsLiteral.natural 1)) with
    | .ok value => pure value
    | .error _ => throw <| IO.userError "accepted admission fixture encoding failed"
  let acceptedResult ← PsKernelLean.admitCanonicalAdmissions acceptedSource
  let acceptedEnv ← expectOk "kernel accepts valid definition" acceptedResult
  expectTrue "accepted declaration installed"
    (acceptedEnv.find? (Lean.Name.str Lean.Name.anonymous "kernelAccepted")).isSome

  let rejectedSource ←
    match kernelAdmissionFixture "kernelRejected" (PsExpr.sortE PsLevel.zero) with
    | .ok value => pure value
    | .error _ => throw <| IO.userError "rejected admission fixture encoding failed"
  let rejectedResult ← PsKernelLean.admitCanonicalAdmissions rejectedSource
  match rejectedResult with
  | .ok _ => throw <| IO.userError "kernel must reject ill-typed definition"
  | .error error =>
      expectTrue "semantic rejection kind" (error.kind == .kernelRejection)
      expectTrue "semantic rejection index" (error.declarationIndex == some 0)

def main : IO Unit := do
  expectEq "providerProtocol" PsKernelLean.providerProtocol "pskernel-lean/1"
  expectEq "providerName" PsKernelLean.providerName "lean4-cpp"
  expectEq "providerVersion" PsKernelLean.providerVersion "4.34.0"
  expectEq "providerProfile" PsKernelLean.providerProfile "lean4.34-core"
  expectEq "leanVersion" Lean.versionString "4.34.0"
  testCoreConversion
  testPreludeReplay
  testCanonicalAdmissionsDecode
  testCanonicalAdmissionsRejectMalformed
  testKernelAdmission
  IO.println "PSC2_LEAN_KERNEL_PROVIDER_TESTS: PASS"
