import Ps.Environment.StandardNumeric

-- Shared explicit registration; logical declarations and instance search inputs
-- remain separate. Importing a proof closure never silently adds instances.
def psStandardRegisterInstances (environment : PsEnvironment) (className : String)
    (declarations : List PsDeclaration) (priority : Nat := 1000) : PsEnvironment :=
  -- Standard factories create ordinary instance definitions. Apply the native
  -- instance-command default only when no status was provided; imported native
  -- metadata and explicit reducible/irreducible choices remain authoritative.
  let environment := declarations.foldl (fun env declaration =>
    let name := psDeclarationName declaration
    if (psDeclarationValue declaration).isSome &&
        (psEnvironmentReducibility? env name).isNone then
      psEnvironmentSetReducibility env name .instanceReducible
    else env) environment
  let instances := declarations.foldl (fun index declaration =>
    psInstanceIndexAdd index {
      value := .constE (psDeclarationName declaration)
        ((psDeclarationLevelParams declaration).map PsLevel.param)
      levelParams := psDeclarationLevelParams declaration
      type := psDeclarationType declaration
      className := some (psDecisionName className)
      priority }) environment.instances
  { environment with instances }

def psStandardRegisterClass (environment : PsEnvironment) (name : String) : PsEnvironment :=
  let name := psDecisionName name
  { environment with
    classes := name :: environment.classes
    classParameters := (name, { outputs := [], outputLevels := [] }) :: environment.classParameters }


-- Lawfulness is indexed by the actual BEq dictionary. The pinned
-- Nat.instLawfulBEq uses instBEqOfDecidableEq; the selected Nat.beq-backed
-- dictionary therefore needs its own checked proof of the same native laws.
def psStandardNatLawfulBEqDeclaration : PsDeclaration :=
  let nat := PsExpr.constE psNatName []
  let bool := PsExpr.constE psBoolName []
  let level := PsLevel.succ .zero
  let dictionary := PsExpr.constE (psDecisionName "PsStandard.instBEqNat") []
  let left := PsExpr.fvar 0
  let right := PsExpr.fvar 1
  let call := fun name args => psLogicApply (.constE (psDecisionName name) []) args
  let reflexivity := psLogicLam 0 "value" nat
    (call "Nat.beq_refl" [left]) .implicit
  let parent := psLogicApply (.constE (psDecisionName "ReflBEq.mk") [.zero])
    [nat, dictionary, reflexivity]
  let evidence := psLogicEq level bool
    (call "Nat.beq" [left, right]) (.constE psBoolTrueName [])
  let equality := psLogicLam 0 "left" nat
    (psLogicLam 1 "right" nat
      (psLogicLam 2 "equal" evidence
        (call "Nat.eq_of_beq_eq_true" [left, right, .fvar 2])) .implicit) .implicit
  let type := psLogicApply (.constE (psRootName "LawfulBEq") [.zero]) [nat, dictionary]
  let value := psLogicApply (.constE (psDecisionName "LawfulBEq.mk") [.zero])
    [nat, dictionary, parent, equality]
  .theoremDecl (psDecisionName "PsStandard.instLawfulBEqNat") [] type value

-- Register the already checked Nat laws after the frozen authoring bases.
def psStandardLawfulBEqExtend (environment : PsEnvironment) : PsEnvironment :=
  let className := psRootName "LawfulBEq"
  match psEnvironmentFindInductive environment className,
      psEnvironmentFind environment (psDecisionName "Nat.instLawfulBEq") with
  | some _, some dictionary =>
    let environment := if environment.classes.any (psNameEq className) then environment
      else psStandardRegisterClass environment "LawfulBEq"
    let environment := psPreludeAdd environment psStandardNatLawfulBEqDeclaration
    psStandardRegisterInstances environment "LawfulBEq"
      [dictionary, psStandardNatLawfulBEqDeclaration] 1000
  | _, _ => environment
