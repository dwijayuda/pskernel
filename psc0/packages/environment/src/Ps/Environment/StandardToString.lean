import Ps.Environment.StandardEquality

-- Lean 4.35.0-rc4 Init.Data.ToString.Basic: ToString is a one-field
-- kernel-checked structure class, not a source-only elaboration intrinsic.
-- Additional instances must be added only with their actual checked
-- runtime implementations; no invented dictionary or blanket fallback.
def psStandardToStringClass : List PsDeclaration :=
  let name := psRootName "ToString"
  let ctor := psNameAppendStr name "mk"
  let method := psNameAppendStr name "toString"
  let u := psRootName "u"
  let alpha := PsExpr.fvar 0
  let self := PsExpr.fvar 1
  let sort := PsExpr.sortE (.succ (.param u))
  let family := PsExpr.app (.constE name [.param u]) alpha
  let methodType := psLogicPi 2 "value" alpha (.constE psStringName [])
  let params := fun body => psLogicPi 0 "α" sort body .implicit
  let paramLams := fun body => psLogicLam 0 "α" sort body .implicit
  [ .inductiveDecl (.mk name [u]
      (psLogicPi 0 "α" sort sort) 1 0 [ctor] true),
    .constructorDecl (.mk ctor [u]
      (params (psLogicPi 2 "toString" methodType family))
      name 0 1 1 []),
    .definitionDecl method [u]
      (params (psLogicPi 1 "self" family methodType .instanceImplicit))
      (paramLams (psLogicLam 1 "self" family (.proj name 0 self) .instanceImplicit)) ]

def psStandardToStringInstance (suffix : String) (type primitive : PsExpr) :
    PsDeclaration :=
  let name := psRootName "ToString"
  let instanceName := psNameAppendStr (psRootName "PsStandard") ("instToString" ++ suffix)
  let typeOfInstance := PsExpr.app (.constE name [.zero]) type
  let body := psLogicApply (.constE (psNameAppendStr name "mk") [.zero]) [type, primitive]
  .definitionDecl instanceName [] typeOfInstance body

def psStandardToStringInstances : List PsDeclaration :=
  let str := PsExpr.constE psStringName []
  let int := PsExpr.constE psIntName []
  [ psStandardToStringInstance "String" str
      (PsExpr.lam (psRootName "s") str (.bvar 0) .explicit),
    psStandardToStringInstance "Int" int (.constE psIntReprName []) ]

def psStandardToStringDeclarations : List PsDeclaration :=
  psStandardToStringClass ++ psStandardToStringInstances

def psStandardPreludeDeclarationsWithToString : List PsDeclaration :=
  psStandardPreludeDeclarations ++ psStandardToStringDeclarations

def psStandardPreludeExtendWithToString (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardPreludeExtend environment
  let environment := psStandardToStringDeclarations.foldl
    (fun env decl => (psEnvironmentAdd env decl).getD env) environment
  let name := psRootName "ToString"
  let register := fun (idx : PsInstanceIndex) (declaration : PsDeclaration) =>
    psInstanceIndexAdd idx {
      value := .constE (psDeclarationName declaration) []
      type := psDeclarationType declaration
      className := some name }
  let instances := psStandardToStringInstances.foldl register environment.instances
  { environment with
    classes := name :: environment.classes
    classParameters := (name, { outputs := [], outputLevels := [] }) ::
      environment.classParameters
    instances }
