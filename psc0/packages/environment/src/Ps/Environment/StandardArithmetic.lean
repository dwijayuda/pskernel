import Ps.Environment.SelfHostPrelude

-- Pinned Lean 4.35.0-rc4 Init/Prelude.lean: HAdd/HSub/HMul/HDiv/HMod
-- are universe-polymorphic one-field structure classes. The output type
-- is outParam, with an explicit output-only class-search position.
-- These are checked Core declarations, not signatures admitted as axioms.
structure PsStandardBinarySpec where
  className : String
  fieldName : String
  natMethod : PsName
  intMethod : Option PsName := none

def psStandardBinarySpecs : List PsStandardBinarySpec :=
  [ { className := "HAdd", fieldName := "hAdd", natMethod := psNatAddName,
      intMethod := some psIntAddName },
    { className := "HSub", fieldName := "hSub", natMethod := psNatSubName,
      intMethod := some psIntSubName },
    { className := "HMul", fieldName := "hMul", natMethod := psNatMulName,
      intMethod := some psIntMulName },
    { className := "HDiv", fieldName := "hDiv", natMethod := psNatDivName },
    { className := "HMod", fieldName := "hMod", natMethod := psNatModName } ]

def psStandardBinaryClass (spec : PsStandardBinarySpec) : List PsDeclaration :=
  let name := psRootName spec.className
  let ctor := psNameAppendStr name "mk"
  let field := psNameAppendStr name spec.fieldName
  let u := psRootName "u"
  let v := psRootName "v"
  let w := psRootName "w"
  let levels : List PsLevel := [.param u, .param v, .param w]
  let alpha := PsExpr.fvar 0
  let beta := PsExpr.fvar 1
  let gamma := PsExpr.fvar 2
  let self := PsExpr.fvar 3
  let uType := PsExpr.sortE (.succ (.param u))
  let vType := PsExpr.sortE (.succ (.param v))
  let wType := PsExpr.sortE (.succ (.param w))
  let outputType := PsExpr.app
    -- Type w itself inhabits Sort (w+2); outParam's universe describes
    -- its argument's sort, not the universe indexed by Type.
    (.constE (psRootName "outParam") [.succ (.succ (.param w))]) wType
  let resultSort := PsExpr.sortE (.succ (.max (.param u) (.max (.param v) (.param w))))
  let family := psLogicApply (.constE name levels) [alpha, beta, gamma]
  let methodType := psLogicPi 4 "a" alpha (psLogicPi 5 "b" beta gamma)
  let bindParams := fun body =>
    psLogicPi 0 "α" uType (psLogicPi 1 "β" vType
      (psLogicPi 2 "γ" outputType body .implicit) .implicit) .implicit
  let bindParamLams := fun body =>
    psLogicLam 0 "α" uType (psLogicLam 1 "β" vType
      (psLogicLam 2 "γ" outputType body .implicit) .implicit) .implicit
  let ctorType := bindParams (psLogicPi 4 spec.fieldName methodType family)
  let projectionType := bindParams (psLogicPi 3 "self" family methodType .instanceImplicit)
  let projectionValue := bindParamLams
    (psLogicLam 3 "self" family (.proj name 0 self) .instanceImplicit)
  [ .inductiveDecl (.mk name [u, v, w] (bindParams resultSort)
      3 0 [ctor] true),
    .constructorDecl (.mk ctor [u, v, w] ctorType name 0 3 1 []),
    .definitionDecl field [u, v, w] projectionType projectionValue ]

def psStandardBinaryInstance (spec : PsStandardBinarySpec)
    (typeName primitive : PsName) : PsDeclaration :=
  let className := psRootName spec.className
  let name := psNameAppendStr (psRootName "PsStandard") 
    ("inst" ++ spec.className ++ psNameToString typeName)
  let type := PsExpr.constE typeName []
  let classType := psLogicApply (.constE className [.zero, .zero, .zero])
    [type, type, type]
  let value := psLogicApply
    (.constE (psNameAppendStr className "mk") [.zero, .zero, .zero])
    [type, type, type, .constE primitive []]
  .definitionDecl name [] classType value

def psStandardBinaryDeclarations : List PsDeclaration :=
  psStandardBinarySpecs.flatMap fun spec =>
    psStandardBinaryClass spec ++
    [psStandardBinaryInstance spec psNatName spec.natMethod] ++
    spec.intMethod.toList.map (psStandardBinaryInstance spec psIntName)

def psStandardBinaryExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardBinaryDeclarations.foldl
    (fun env declaration => (psEnvironmentAdd env declaration).getD env) environment
  let names := psStandardBinarySpecs.map fun spec => psRootName spec.className
  let classParameters := names.map fun name =>
    (name, { outputs := [2], outputLevels := [2] : PsClassParameters })
  let instances := psStandardBinarySpecs.foldl (fun idx spec =>
    let className := psRootName spec.className
    let add := fun (acc : PsInstanceIndex) (typeName primitive : PsName) =>
      let declaration := psStandardBinaryInstance spec typeName primitive
      psInstanceIndexAdd acc {
        value := .constE (psDeclarationName declaration) []
        type := psDeclarationType declaration
        className := some className }
    let idx := add idx psNatName spec.natMethod
    match spec.intMethod with
    | none => idx
    | some intMethod => add idx psIntName intMethod) environment.instances
  { environment with
    classes := names ++ environment.classes
    classParameters := classParameters ++ environment.classParameters
    instances }


-- Lean RC4 Init/Prelude.lean: Neg (α : Type u) is a one-field class.
-- Its method and instance are kernel-checked, never admitted as new axioms.
def psStandardNegDeclarations : List PsDeclaration :=
  let name := psRootName "Neg"
  let ctor := psNameAppendStr name "mk"
  let u := psRootName "u"
  let a := PsExpr.fvar 0
  let self := PsExpr.fvar 1
  let type := PsExpr.sortE (.succ (.param u))
  let family := PsExpr.app (.constE name [.param u]) a
  let methodType := psLogicPi 2 "value" a a
  let params := fun body => psLogicPi 0 "α" type body .implicit
  let paramLams := fun body => psLogicLam 0 "α" type body .implicit
  let instName := psNameAppendStr (psRootName "PsStandard") "instNegInt"
  let int := PsExpr.constE psIntName []
  [ .inductiveDecl (.mk name [u] (psLogicPi 0 "α" type type) 1 0 [ctor] true),
    .constructorDecl (.mk ctor [u]
      (params (psLogicPi 2 "neg" methodType family)) name 0 1 1 []),
    .definitionDecl (psNameAppendStr name "neg") [u]
      (params (psLogicPi 1 "self" family methodType .instanceImplicit))
      (paramLams (psLogicLam 1 "self" family (.proj name 0 self) .instanceImplicit)),
    .definitionDecl instName []
      (PsExpr.app (.constE name [.zero]) int)
      (psLogicApply (.constE ctor [.zero]) [int, .constE psIntNegName []]) ]

def psStandardOperatorDeclarations : List PsDeclaration :=
  psStandardBinaryDeclarations ++ psStandardNegDeclarations

def psStandardOperatorExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardBinaryExtend environment
  let environment := psStandardNegDeclarations.foldl
    (fun env decl => (psEnvironmentAdd env decl).getD env) environment
  let className := psRootName "Neg"
  let instName := psNameAppendStr (psRootName "PsStandard") "instNegInt"
  let instanceType := PsExpr.app (.constE className [.zero]) (.constE psIntName [])
  { environment with
    classes := className :: environment.classes
    classParameters := (className, { outputs := [], outputLevels := [] }) ::
      environment.classParameters
    instances := psInstanceIndexAdd environment.instances {
      value := .constE instName []
      type := instanceType
      className := some className } }
