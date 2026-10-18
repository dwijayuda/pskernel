import Ps.Environment.StandardInhabited

-- Pinned Lean 4.35.0 Init/Prelude foundation. Nonempty eliminates into Prop;
-- Classical.choice is the approved logical axiom, with no executable entry.
-- The witness wrapper is the checked definition used by native P0 fallback.
def psStandardClassicalExpectedDeclarations : List PsDeclaration :=
  let u := psRootName "u"
  let level := PsLevel.param u
  let sort := PsExpr.sortE level
  let prop := PsExpr.sortE .zero
  let nonemptyName := psRootName "Nonempty"
  let introName := psNameAppendStr nonemptyName "intro"
  let recName := psNameAppendStr nonemptyName "rec"
  let classicalName := psRootName "Classical"
  let choiceName := psNameAppendStr classicalName "choice"
  let ofNonemptyName := psNameAppendStr classicalName "ofNonempty"
  let alpha := PsExpr.fvar 0
  let value := PsExpr.fvar 1
  let motive := PsExpr.fvar 2
  let witness := PsExpr.fvar 4
  let family := PsExpr.app (.constE nonemptyName [level]) alpha
  let params := fun body => psLogicPi 0 "α" sort body .implicit
  let paramLams := fun body => psLogicLam 0 "α" sort body .implicit
  let intro := psLogicApply (.constE introName [level]) [alpha, value]
  let motiveType := psLogicPi 4 "t" family prop
  let minorType := psLogicPi 1 "val" alpha (.app motive intro)
  let recType := params
    (psLogicPi 2 "motive" motiveType
      (psLogicPi 3 "intro" minorType
        (psLogicPi 4 "t" family (.app motive witness))) .implicit)
  let choiceType := params (psLogicPi 4 "h" family alpha)
  let ofNonemptyType := params
    (psLogicPi 4 "inst" family alpha .instanceImplicit)
  let ofNonemptyValue := paramLams
    (psLogicLam 4 "inst" family
      (psLogicApply (.constE choiceName [level]) [alpha, witness])
      .instanceImplicit)
  [ .inductiveDecl (.mk nonemptyName [u]
      (psLogicPi 0 "α" sort prop) 1 0 [introName] false),
    .constructorDecl (.mk introName [u]
      (params (psLogicPi 1 "val" alpha family)) nonemptyName 0 1 1 []),
    .recursorDecl (.mk recName [u] recType [nonemptyName] 1 0 1 1),
    .axiomDecl choiceName [u] choiceType,
    .definitionDecl ofNonemptyName [u] ofNonemptyType ofNonemptyValue ]

-- Nonempty and its checked introduction/recursor already belong to Standard.
-- Audit these prerequisites unchanged; add only the two missing classical names.
def psStandardClassicalPrerequisiteDeclarations : List PsDeclaration :=
  psStandardClassicalExpectedDeclarations.take 3

def psStandardClassicalDeclarations : List PsDeclaration :=
  psStandardClassicalExpectedDeclarations.drop 3

-- This extends only the logical environment. Choice and its wrapper must not
-- become runtime primitives or enter the executable prelude catalogue.
def psStandardClassicalExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardClassicalDeclarations.foldl
    (fun env declaration => (psEnvironmentAdd env declaration).getD env) environment
  let className := psRootName "Nonempty"
  let classes :=
    if environment.classes.any (psNameEq className) then
      environment.classes
    else
      className :: environment.classes
  let classParameters :=
    if environment.classParameters.any (fun entry => psNameEq entry.fst className) then
      environment.classParameters
    else
      (className, { outputs := [], outputLevels := [] }) :: environment.classParameters
  { environment with
    classes := classes
    classParameters := classParameters
    -- Init/Prelude's constructive theorem is already in the checked closure.
    -- Select its ordinary instance explicitly; logical inclusion alone does
    -- not register a dictionary. The strict audit below rejects absence.
    instances := match psEnvironmentFind environment (psRootName "instNonemptyOfInhabited") with
      | none => environment.instances
      | some declaration => psInstanceIndexAdd environment.instances {
          value := .constE (psDeclarationName declaration)
            ((psDeclarationLevelParams declaration).map PsLevel.param)
          levelParams := psDeclarationLevelParams declaration
          type := psDeclarationType declaration
          className := some className
          priority := 1000 } }

-- Exact declaration and class metadata audit; official kernel replay and the
-- independent native signature audit remain required qualification gates.
def psStandardClassicalAudit (environment : PsEnvironment) : Except String Unit := do
  for declaration in psStandardClassicalExpectedDeclarations do
    psStandardAuditDeclaration environment declaration
  if !environment.classes.any (psNameEq (psRootName "Nonempty")) then
    throw "PSCV0-STANDARD: missing Nonempty class registration"
  let some declaration@(.theoremDecl ..) :=
      psEnvironmentFind environment (psRootName "instNonemptyOfInhabited")
    | throw "PSCV0-STANDARD: missing checked Inhabited-to-Nonempty theorem"
  psStandardAuditInstance environment declaration
