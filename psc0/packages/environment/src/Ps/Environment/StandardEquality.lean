import Ps.Environment.StandardArithmetic

-- A checked subset of Lean 4.35.0-rc4 Init/Prelude's BEq class.
-- This models Boolean equality by an actual dictionary and proof-checked
-- projection. Instances are independently registered; parsing does not
-- special-case source types or create a new trusted equality primitive.
def psStandardBEqClass : List PsDeclaration :=
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
  [ .inductiveDecl (.mk name [u] (psLogicPi 0 "α" typeSort typeSort)
      1 0 [ctor] true),
    .constructorDecl (.mk ctor [u]
      (params (psLogicPi 2 "beq" methodType family)) name 0 1 1 []),
    .definitionDecl (psNameAppendStr name "beq") [u]
      (params (psLogicPi 1 "self" family methodType .instanceImplicit))
      (paramLams (psLogicLam 1 "self" family (.proj name 0 self) .instanceImplicit)) ]

-- Preserve the actual Lean-grounded computation inside each dictionary.
-- No source-type branching belongs in the parser or elaborator.
def psStandardBEqInstance (suffix : String) (type method : PsExpr) :
    PsDeclaration :=
  let name := psRootName "BEq"
  let instanceName := psNameAppendStr (psRootName "PsStandard") ("instBEq" ++ suffix)
  let instanceType := PsExpr.app (.constE name [.zero]) type
  let value := psLogicApply (.constE (psNameAppendStr name "mk") [.zero])
    [type, method]
  .definitionDecl instanceName [] instanceType value

-- Lean Bool.beq: false == b is !b, true == b is b.
-- Use the checked Bool recursor rather than inventing a new primitive.
def psStandardBEqBoolMethod : PsExpr :=
  let bool := PsExpr.constE psBoolName []
  let motive := PsExpr.lam (psRootName "_") bool bool .explicit
  let recursor := PsExpr.constE (psNameAppendStr psBoolName "rec") [.succ .zero]
  let notRight := psLogicApply recursor
    [motive, .constE psBoolTrueName [], .constE psBoolFalseName [], .bvar 0]
  let result := psLogicApply recursor
    [motive, notRight, .bvar 0, .bvar 1]
  .lam (psRootName "left") bool
    (.lam (psRootName "right") bool result .explicit) .explicit

-- Unicode Char equality uses the already modeled Char.toNat primitive and
-- Nat.beq, preserving the full Unicode scalar identity.
def psStandardBEqCharMethod : PsExpr :=
  let char := PsExpr.constE psCharName []
  let convert := PsExpr.constE psCharToNatName []
  let result := psLogicApply (.constE psNatBeqName [])
    [.app convert (.bvar 1), .app convert (.bvar 0)]
  .lam (psRootName "left") char
    (.lam (psRootName "right") char result .explicit) .explicit

-- Unit has a single canonical inhabitant. Both ignored arguments are typed
-- and erased by the ordinary checked binder/IR pipeline.
def psStandardBEqUnitMethod : PsExpr :=
  let unit := PsExpr.constE psUnitName []
  .lam (psRootName "left") unit
    (.lam (psRootName "right") unit
      (.constE psBoolTrueName []) .explicit) .explicit

def psStandardBEqInstances : List PsDeclaration :=
  [psStandardBEqInstance "Nat" (.constE psNatName [])
      (.constE psNatBeqName []),
   psStandardBEqInstance "Bool" (.constE psBoolName [])
      psStandardBEqBoolMethod,
   psStandardBEqInstance "Char" (.constE psCharName [])
      psStandardBEqCharMethod,
   psStandardBEqInstance "Unit" (.constE psUnitName [])
      psStandardBEqUnitMethod]

def psStandardBEqDeclarations : List PsDeclaration :=
  psStandardBEqClass ++ psStandardBEqInstances

def psStandardPreludeDeclarations : List PsDeclaration :=
  psStandardOperatorDeclarations ++ psStandardBEqDeclarations

def psStandardPreludeExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardOperatorExtend environment
  let environment := psStandardBEqDeclarations.foldl
    (fun env decl => (psEnvironmentAdd env decl).getD env) environment
  let className := psRootName "BEq"
  let instances := psStandardBEqInstances.foldl (fun index declaration =>
    psInstanceIndexAdd index {
      value := .constE (psDeclarationName declaration) []
      type := psDeclarationType declaration
      className := some className }) environment.instances
  { environment with
    classes := className :: environment.classes
    classParameters := (className, { outputs := [], outputLevels := [] }) ::
      environment.classParameters
    instances }
