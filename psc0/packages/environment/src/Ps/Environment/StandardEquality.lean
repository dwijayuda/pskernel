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

-- Lean 4.35.0 Bool.beq splits on its RIGHT operand:
-- (a == true) reduces to a, and (a == false) reduces to not a.
-- Use the checked Bool recursor rather than inventing a new primitive.
def psStandardBEqBoolMethod : PsExpr :=
  let bool := PsExpr.constE psBoolName []
  let motive := PsExpr.lam (psRootName "_") bool bool .explicit
  let recursor := PsExpr.constE (psNameAppendStr psBoolName "rec") [.succ .zero]
  let notLeft := psLogicApply recursor
    [motive, .constE psBoolTrueName [], .constE psBoolFalseName [], .bvar 1]
  let result := psLogicApply recursor
    [motive, notLeft, .bvar 1, .bvar 0]
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

-- String equality is the existing Lean decision procedure reflected to
-- Bool. Erasure already audits String.decEq as the cross-target stringEq
-- intrinsic; this dictionary adds no new trusted string operation.
def psStandardBEqStringMethod : PsExpr :=
  let str := PsExpr.constE psStringName []
  let proposition := psLogicEq (.succ .zero) str (.fvar 0) (.fvar 1)
  let decision := psLogicApply (.constE (psDecisionName "String.decEq") [])
    [.fvar 0, .fvar 1]
  let result := psLogicApply (.constE (psDecisionName "Decidable.decide") [])
    [proposition, decision]
  psLogicLam 0 "left" str
    (psLogicLam 1 "right" str result)

-- A parameterized BEq instance over Option α. Its only assumption is a
-- checked BEq α dictionary supplied by ordinary typeclass search. Both
-- constructor splits are real Option.rec eliminations, not a host shortcut.
def psStandardBEqOptionInstance : PsDeclaration :=
  let u := psRootName "u"
  let alpha := PsExpr.fvar 0
  let dictionaryType := PsExpr.app (.constE (psRootName "BEq") [.param u]) alpha
  let option := psSelfHostOptionOf alpha (.param u)
  let bool := PsExpr.constE psBoolName []
  let recursor := PsExpr.constE psSelfHostOptionRecName [.succ .zero, .param u]
  let innerMotive := psLogicLam 8 "_" option bool
  let outerMotive := psLogicLam 9 "_" option
    (psLogicPi 10 "other" option bool)
  let noneBranch := psLogicLam 3 "other" option
    (psLogicApply recursor
      [alpha, innerMotive,
       .constE psBoolTrueName [],
       psLogicLam 5 "_" alpha (.constE psBoolFalseName []),
       .fvar 3])
  let elementEquality := psLogicApply
    (.constE (psNameAppendStr (psRootName "BEq") "beq") [.param u])
    [alpha, .fvar 1, .fvar 4, .fvar 5]
  let someBranch := psLogicLam 4 "leftValue" alpha
    (psLogicLam 3 "other" option
      (psLogicApply recursor
        [alpha, innerMotive,
         .constE psBoolFalseName [],
         psLogicLam 5 "rightValue" alpha elementEquality,
         .fvar 3]))
  let outer := psLogicApply
    (.constE psSelfHostOptionRecName [.succ (.param u), .param u])
    [alpha, outerMotive, noneBranch, someBranch, .fvar 2]
  let method := psLogicLam 2 "left" option
    (psLogicLam 3 "right" option (.app outer (.fvar 3)))
  let classType := PsExpr.app (.constE (psRootName "BEq") [.param u]) option
  let result := psLogicApply (.constE
    (psNameAppendStr (psRootName "BEq") "mk") [.param u]) [option, method]
  let type := psLogicPi 0 "α" (.sortE (.succ (.param u)))
    (psLogicPi 1 "instance" dictionaryType classType .instanceImplicit) .implicit
  let value := psLogicLam 0 "α" (.sortE (.succ (.param u)))
    (psLogicLam 1 "instance" dictionaryType result .instanceImplicit) .implicit
  .definitionDecl (psNameAppendStr (psRootName "PsStandard") "instBEqOption")
    [u] type value

def psStandardBEqInstances : List PsDeclaration :=
  [psStandardBEqInstance "Nat" (.constE psNatName [])
      (.constE psNatBeqName []),
   psStandardBEqInstance "Bool" (.constE psBoolName [])
      psStandardBEqBoolMethod,
   psStandardBEqInstance "Char" (.constE psCharName [])
      psStandardBEqCharMethod,
   psStandardBEqInstance "String" (.constE psStringName [])
      psStandardBEqStringMethod,
   psStandardBEqInstance "Unit" (.constE psUnitName [])
      psStandardBEqUnitMethod,
   psStandardBEqOptionInstance]

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
      value := .constE (psDeclarationName declaration)
        ((psDeclarationLevelParams declaration).map PsLevel.param)
      levelParams := psDeclarationLevelParams declaration
      type := psDeclarationType declaration
      className := some className }) environment.instances
  { environment with
    classes := className :: environment.classes
    classParameters := (className, { outputs := [], outputLevels := [] }) ::
      environment.classParameters
    instances }
