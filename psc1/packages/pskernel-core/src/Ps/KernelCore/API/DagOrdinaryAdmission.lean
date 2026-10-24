import Ps.KernelCore.API.DagOrdinaryRecursorValidation
import Ps.KernelCore.API.DagOrdinaryElimination

/-
Private complete ordinary-inductive admission. The input table is the validated
original namespace; owner is the synchronized canonical work arena/table and
its declaration references. These internal correspondence premises are not
established by forgeable records or the defensive size checks below.

Header, constructor, elimination, recursor-type and rule checks use the DAG
checker callbacks. Existing V1 functions are reused only for pure generated
syntax and metadata. The provisional datatype, constructors and recursor remain
private. A successful environment/owner pair is returned only after every
generated rule passes independent Check and DefEq and the final decoded suffix
is synchronized. None/error returns no partial result. Public resource checks,
receipt creation and batch publication remain the caller's responsibility.
-/
structure PsKernelExprV2OrdinaryStagedRecursor where
  environment : PsKernelEnvironment
  owner : PsKernelDagGeneratedState
  rules : List PsKernelExprV2RecursorRuleRef

def psKernelExprV2OrdinaryFinishAdmission
    (environment : PsKernelEnvironment) (checked : PsKernelExprV2OrdinaryRuleState) :
    Except String PsKernelExprV2OrdinaryAdmissionResult :=
  match psKernelExprV2OrdinarySynchronizeOwner checked.state checked.built with
  | Except.error error => Except.error error
  | Except.ok owner =>
      Except.ok (PsKernelExprV2OrdinaryAdmissionResult.mk environment owner)

/- Called after independent recursor-type Check and mandatory EnsureSort.
   The fresh rule phase keeps the appended arena but uses established parent
   references plus the generated recursor ref. Type-check caches, freshness
   and callback-returned reference changes are not a new rule-checking owner. -/
def psKernelExprV2OrdinaryStageRecursor
    (environment : PsKernelEnvironment)
    (declarations : List PsKernelExprV2DeclarationRef)
    (plan : PsKernelExprV2OrdinaryRecursorPlan) (typeRoot : Nat)
    (sorted : PsKernelExprV2CheckState) (built : PsKernelExprV2Decoded) :
    Except String PsKernelExprV2OrdinaryStagedRecursor :=
  match psKernelExprV2OrdinaryExtendDecoded sorted.whnf.arena built with
  | Except.error error => Except.error error
  | Except.ok decoded =>
      let owner :=
        PsKernelDagGeneratedState.mk sorted.whnf.arena decoded declarations;
      match psKernelDagGeneratedImportRules plan.info.rules owner with
      | Except.error error => Except.error error
      | Except.ok imported =>
          let next := Prod.fst imported;
          let rules := Prod.snd imported;
          let reference :=
            PsKernelExprV2DeclarationRef.mk plan.info.base.name
              plan.info.base.levelParams typeRoot Option.none
              (PsKernelExprV2DeclarationRefKind.recursorDecl rules);
          let work :=
            psKernelEnvironmentAddUnchecked environment
              (PsKernelConstantInfo.recInfo plan.info);
          Except.ok
            (PsKernelExprV2OrdinaryStagedRecursor.mk work
              (PsKernelDagGeneratedState.mk next.arena next.built
                (List.cons reference next.declarations)) rules)

def psKernelExprV2OrdinaryValidateStagedRecursorWith
    (check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (defeq : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (fuel maxRecDepth maxNatSize : Nat) (isUnsafe : Bool)
    (plan : PsKernelExprV2OrdinaryRecursorPlan)
    (staged : PsKernelExprV2OrdinaryStagedRecursor) :
    Option (Except String PsKernelExprV2OrdinaryAdmissionResult) :=
  let context :=
    psKernelExprV2OrdinaryFreshContext staged.environment plan.info.base.levelParams
      isUnsafe maxRecDepth maxNatSize;
  let state := psKernelExprV2OrdinaryFreshState staged.owner;
  match psKernelExprV2OrdinaryValidateRecursorRulesWith
      check defeq fuel context state staged.owner.built plan staged.rules with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok checked =>
          Option.some (psKernelExprV2OrdinaryFinishAdmission staged.environment checked)

def psKernelExprV2OrdinaryCheckRecursorWith
    (check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (defeq : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (fuel : Nat) (environment : PsKernelEnvironment)
    (maxRecDepth maxNatSize : Nat) (isUnsafe : Bool)
    (owner : PsKernelDagGeneratedState) (plan : PsKernelExprV2OrdinaryRecursorPlan) :
    Option (Except String PsKernelExprV2OrdinaryAdmissionResult) :=
  let context :=
    psKernelExprV2OrdinaryFreshContext environment plan.info.base.levelParams
      isUnsafe maxRecDepth maxNatSize;
  let state := psKernelExprV2OrdinaryFreshState owner;
  match psKernelExprV2OrdinaryImportGenerated plan.info.base.type state owner.built with
  | Except.error error => Option.some (Except.error error)
  | Except.ok imported =>
      match check fuel context imported.state imported.root with
      | Option.none => Option.none
      | Option.some attemptedCheck =>
          match attemptedCheck with
          | Except.error error => Option.some (Except.error error)
          | Except.ok checked =>
              match psKernelExprV2AdmissionEnsureSortOwnedWith
                  (whnf fuel) context (Prod.fst checked) (Prod.snd checked) with
              | Option.none => Option.none
              | Option.some attemptedSort =>
                  match attemptedSort with
                  | Except.error error => Option.some (Except.error error)
                  | Except.ok sorted =>
                      match psKernelExprV2OrdinaryStageRecursor
                          environment owner.declarations plan imported.root
                          (Prod.fst sorted) imported.built with
                      | Except.error error => Option.some (Except.error error)
                      | Except.ok staged =>
                          psKernelExprV2OrdinaryValidateStagedRecursorWith check defeq
                            fuel maxRecDepth maxNatSize isUnsafe plan staged

def psKernelExprV2OrdinaryInitialInfo
    (decl : PsKernelSimpleInductiveDecl) (numIndices : Nat) : PsKernelInductiveInfo :=
  PsKernelInductiveInfo.mk
    (PsKernelConstantBase.mk decl.name decl.levelParams decl.type)
    decl.numParams numIndices (List.cons decl.name List.nil)
    (psKernelSimpleCtorNames decl.ctors) 0 false false decl.isUnsafe

def psKernelExprV2OrdinaryFinalInfo
    (initial : PsKernelInductiveInfo) (shapes : List PsKernelSimpleConstructorShape) :
    PsKernelInductiveInfo :=
  PsKernelInductiveInfo.mk initial.base initial.numParams initial.numIndices
    initial.all initial.ctors initial.numNested
    (psKernelSimpleHasRecursiveFields shapes)
    (psKernelSimpleHasReflexiveFields shapes) initial.isUnsafe

def psKernelExprV2OrdinaryAfterConstructorsWith
    (check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (defeq : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (fuel : Nat) (input built : PsKernelExprV2Decoded)
    (decl : PsKernelSimpleInductiveDecl) (value : PsKernelDagInductive)
    (header : PsKernelExprV2OrdinaryHeaderAnalysis) (initial : PsKernelInductiveInfo)
    (constructors : PsKernelExprV2OrdinaryConstructorsResult) :
    Option (Except String PsKernelExprV2OrdinaryAdmissionResult) :=
  match psKernelExprV2OrdinarySynchronizeOwner constructors.state built with
  | Except.error error => Option.some (Except.error error)
  | Except.ok owner =>
      match psKernelExprV2OrdinaryDecodeRecursorData
          input owner.built header constructors.shapes with
      | Except.error error => Option.some (Except.error error)
      | Except.ok data =>
          let finalInfo := psKernelExprV2OrdinaryFinalInfo initial data.shapes;
          let work :=
            psKernelEnvironmentReplaceUnchecked constructors.context.scalar.environment
              (PsKernelConstantInfo.inductInfo finalInfo);
          let context :=
            PsKernelExprV2CheckContext.mk
              (psKernelCheckerContextWithEnvironment constructors.context.scalar work)
              constructors.context.locals;
          match psKernelExprV2OrdinaryElimOnlyAtZeroWith check whnf defeq fuel
              context constructors.state header.parameters.binders header.resultLevel value.ctors with
          | Option.none => Option.none
          | Option.some attemptedElimination =>
              match attemptedElimination with
              | Except.error error => Option.some (Except.error error)
              | Except.ok onlyAtZero =>
                  let plan :=
                    psKernelExprV2OrdinaryMakeRecursorPlan decl header.resultLevel data onlyAtZero;
                  psKernelExprV2OrdinaryCheckRecursorWith check whnf defeq fuel work
                    context.scalar.maxRecDepth context.scalar.maxNatSize decl.isUnsafe owner plan

def psKernelExprV2OrdinaryAfterHeaderWith
    (check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (defeq : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (fuel : Nat) (input built : PsKernelExprV2Decoded)
    (decl : PsKernelSimpleInductiveDecl) (value : PsKernelDagInductive)
    (header : PsKernelExprV2OrdinaryHeaderAnalysis) :
    Option (Except String PsKernelExprV2OrdinaryAdmissionResult) :=
  let numIndices := psKernelExprV2OrdinaryOpenBinderCount header.indices.binders;
  let initial := psKernelExprV2OrdinaryInitialInfo decl numIndices;
  let parentContext := psKernelExprV2OrdinaryConstructorContext header;
  let parentState := psKernelExprV2OrdinaryConstructorState header;
  let work :=
    psKernelEnvironmentAddUnchecked parentContext.scalar.environment
      (PsKernelConstantInfo.inductInfo initial);
  let context :=
    PsKernelExprV2CheckContext.mk
      (psKernelCheckerContextWithEnvironment parentContext.scalar work) parentContext.locals;
  let reference :=
    PsKernelExprV2DeclarationRef.mk decl.name decl.levelParams value.type Option.none
      PsKernelExprV2DeclarationRefKind.inductiveDecl;
  let state :=
    psKernelExprV2CheckStateWithWhnf parentState
      (PsKernelExprV2WhnfState.mk parentState.whnf.arena
        parentState.whnf.coreCache parentState.whnf.publicCache
        (List.cons reference parentState.whnf.declarations));
  let analyze :=
    fun (phaseFuel : Nat) (nextContext : PsKernelExprV2CheckContext)
        (nextState : PsKernelExprV2CheckState) (target : PsKernelName)
        (levels : List PsKernelLevel)
        (parameters : List PsKernelExprV2OrdinaryOpenBinder) (nextNumIndices : Nat)
        (resultLevel : PsKernelLevel) (ctor : PsKernelDagConstructor) =>
      psKernelExprV2OrdinaryAnalyzeConstructorWith check whnf defeq phaseFuel
        nextContext nextState target levels parameters nextNumIndices resultLevel ctor;
  match psKernelExprV2OrdinaryAddConstructorsWorker (Nat.succ fuel) analyze input
      decl.name decl.numParams decl.isUnsafe (psKernelLevelParamsToLevels decl.levelParams)
      header.parameters.binders numIndices header.resultLevel context state 0 value.ctors with
  | Option.none => Option.none
  | Option.some attemptedConstructors =>
      match attemptedConstructors with
      | Except.error error => Option.some (Except.error error)
      | Except.ok constructors =>
          psKernelExprV2OrdinaryAfterConstructorsWith check whnf defeq fuel input built
            decl value header initial constructors

def psKernelExprV2OrdinaryAdmitWith
    (check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (defeq : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (fuel : Nat) (environment : PsKernelEnvironment)
    (maxRecDepth maxNatSize : Nat) (input : PsKernelExprV2Decoded)
    (owner : PsKernelDagGeneratedState)
    (levelParams : List PsKernelName) (numParams : Nat)
    (value : PsKernelDagInductive) (isUnsafe : Bool) :
    Option (Except String PsKernelExprV2OrdinaryAdmissionResult) :=
  if Nat.beq owner.built.size owner.arena.size then
    if Nat.ble input.size owner.built.size then
      match psKernelDagDecodeInductive input value with
      | Except.error error => Option.some (Except.error error)
      | Except.ok decoded =>
          let decl :=
            PsKernelSimpleInductiveDecl.mk levelParams decoded.name decoded.type
              decoded.ctors isUnsafe numParams;
          match psKernelExprV2OrdinaryAnalyzeHeaderWith check whnf fuel environment
              maxRecDepth maxNatSize owner.arena owner.declarations levelParams
              numParams value isUnsafe with
          | Option.none => Option.none
          | Option.some attemptedHeader =>
              match attemptedHeader with
              | Except.error error => Option.some (Except.error error)
              | Except.ok header =>
                  psKernelExprV2OrdinaryAfterHeaderWith check whnf defeq fuel
                    input owner.built decl value header
    else Option.some (Except.error "PSKERNEL_V2_GENERATED_OWNER_MISMATCH")
  else Option.some (Except.error "PSKERNEL_V2_GENERATED_OWNER_MISMATCH")

def psKernelExprV2OrdinaryAdmitWithFuel
    (fuel : Nat) (environment : PsKernelEnvironment)
    (maxRecDepth maxNatSize : Nat) (input : PsKernelExprV2Decoded)
    (owner : PsKernelDagGeneratedState)
    (levelParams : List PsKernelName) (numParams : Nat)
    (value : PsKernelDagInductive) (isUnsafe : Bool) :
    Option (Except String PsKernelExprV2OrdinaryAdmissionResult) :=
  psKernelExprV2OrdinaryAdmitWith
    psKernelExprV2TryCheckStateWithFuel psKernelExprV2TryWhnfCheckStateWithFuel
    psKernelExprV2TryDefEqStateWithFuel fuel environment maxRecDepth maxNatSize
    input owner levelParams numParams value isUnsafe
