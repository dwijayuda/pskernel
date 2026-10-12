import Ps.Environment.StandardArithmetic

-- A checked subset of Lean 4.35.0-rc4 Init/Prelude's BEq class.
-- This models Boolean equality by an actual dictionary and proof-checked
-- projection. Instances are independently registered; parsing does not
-- special-case source types or create a new trusted equality primitive.
def psStandardBEqDeclarations : List PsDeclaration :=
  let name := psRootName "BEq"
  let ctor := psNameAppendStr name "mk"
  let u := psRootName "u"
  let alpha := PsExpr.fvar 0
  let self := PsExpr.fvar 1
  let typeSort := PsExpr.sortE (.succ (.param u))
  let family := PsExpr.app (.constE name [.param u]) alpha
  let bool := PsExpr.constE psBoolName []
  let methodType := psLogicPi 2 "a" alpha (psLogicPi 3 "b" alpha bool)
  let params := fun body => psLogicPi 0 "α" typeSort body .implicit
  let paramLams := fun body => psLogicLam 0 "α" typeSort body .implicit
  let nat := PsExpr.constE psNatName []
  let instanceName := psNameAppendStr (psRootName "PsStandard") "instBEqNat"
  [ .inductiveDecl (.mk name [u] (psLogicPi 0 "α" typeSort typeSort)
      1 0 [ctor] true),
    .constructorDecl (.mk ctor [u]
      (params (psLogicPi 2 "beq" methodType family)) name 0 1 1 []),
    .definitionDecl (psNameAppendStr name "beq") [u]
      (params (psLogicPi 1 "self" family methodType .instanceImplicit))
      (paramLams (psLogicLam 1 "self" family (.proj name 0 self) .instanceImplicit)),
    .definitionDecl instanceName []
      (PsExpr.app (.constE name [.zero]) nat)
      (psLogicApply (.constE ctor [.zero]) [nat, .constE psNatBeqName []]) ]

def psStandardPreludeDeclarations : List PsDeclaration :=
  psStandardOperatorDeclarations ++ psStandardBEqDeclarations

def psStandardPreludeExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardOperatorExtend environment
  let environment := psStandardBEqDeclarations.foldl
    (fun env decl => (psEnvironmentAdd env decl).getD env) environment
  let className := psRootName "BEq"
  let instanceName := psNameAppendStr (psRootName "PsStandard") "instBEqNat"
  let type := PsExpr.app (.constE className [.zero]) (.constE psNatName [])
  { environment with
    classes := className :: environment.classes
    classParameters := (className, { outputs := [], outputLevels := [] }) ::
      environment.classParameters
    instances := psInstanceIndexAdd environment.instances {
      value := .constE instanceName []
      type
      className := some className } }
