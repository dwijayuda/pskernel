import Ps.KernelCore.API.DagMutualRecursorValidation
import Ps.KernelCore.API.DagDeclaration

/- Private complete mutual-inductive admission over an established canonical
   owner and original validated boundary table. Defensive size checks do not
   authenticate forged internal tables. The public caller must establish the
   unchanged input prefix/ID correspondence and perform its resource preflight,
   declaration cap, capability clearing and atomic session publication.

   All header/constructor/recursor judgments use owning DAG callbacks. Existing
   boundary expressions and pure retained builders supply metadata/generated
   syntax only. No V1 checker, input re-import or original-admission restart is
   performed here. Error/decline returns no partial private environment. -/
structure PsKernelExprV2MutualPreparedAdmission where
  baseInfos : List PsKernelInductiveInfo
  context : PsKernelExprV2CheckContext
  state : PsKernelExprV2CheckState
  built : PsKernelExprV2Decoded

def psKernelExprV2MutualPrependTypeReferences
    (types : List PsKernelDagInductive) : List PsKernelName ->
    List PsKernelExprV2DeclarationRef -> List PsKernelExprV2DeclarationRef :=
  match types with
  | List.nil => fun (_levels : List PsKernelName) (declarations : List PsKernelExprV2DeclarationRef) => declarations
  | List.cons first rest =>
      let smaller := psKernelExprV2MutualPrependTypeReferences rest;
      fun (levels : List PsKernelName) (declarations : List PsKernelExprV2DeclarationRef) =>
        smaller levels (List.cons
          (PsKernelExprV2DeclarationRef.mk first.name levels first.type Option.none
            PsKernelExprV2DeclarationRefKind.inductiveDecl) declarations)

def psKernelExprV2MutualPrepareAdmissionAfterHeader
    (input built : PsKernelExprV2Decoded) (decl : PsKernelSimpleMutualInductiveDecl)
    (value : PsKernelDagInductiveGroup) (header : PsKernelExprV2MutualHeaderAnalysis) :
    Except String PsKernelExprV2MutualPreparedAdmission :=
  match psKernelExprV2OrdinaryExtendDecoded header.arena built with
  | Except.error error => Except.error error
  | Except.ok decoded =>
      match psKernelExprV2MutualDecodeTypeHeaders header.types input decoded with
      | Except.error error => Except.error error
      | Except.ok types =>
          let baseInfos := psKernelMakeSimpleMutualBaseInfos
            (psKernelSimpleMutualNames decl.types) decl types;
          let parentContext := header.parameters.context;
          let parentState := header.parameters.state;
          let work := psKernelAddMutualInductiveInfos baseInfos parentContext.scalar.environment;
          let context := PsKernelExprV2CheckContext.mk
            (psKernelCheckerContextWithEnvironment parentContext.scalar work) parentContext.locals;
          let declarations := psKernelExprV2MutualPrependTypeReferences value.types value.levelParams
            parentState.whnf.declarations;
          let state := psKernelExprV2CheckStateWithWhnf parentState
            (PsKernelExprV2WhnfState.mk header.arena parentState.whnf.coreCache
              parentState.whnf.publicCache declarations);
          Except.ok (PsKernelExprV2MutualPreparedAdmission.mk baseInfos context state decoded)

def psKernelExprV2MutualAfterConstructorsWith
    (check whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (defeq : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (fuel : Nat) (input : PsKernelExprV2Decoded) (value : PsKernelDagInductiveGroup)
    (header : PsKernelExprV2MutualHeaderAnalysis) (prepared : PsKernelExprV2MutualPreparedAdmission)
    (constructors : PsKernelExprV2MutualConstructorsResult) :
    Option (Except String PsKernelExprV2OrdinaryAdmissionResult) :=
  match psKernelExprV2OrdinarySynchronizeOwner constructors.state prepared.built with
  | Except.error error => Option.some (Except.error error)
  | Except.ok owner =>
      match psKernelExprV2MutualDecodeRecursorData input owner.built header constructors.shapes with
      | Except.error error => Option.some (Except.error error)
      | Except.ok data =>
          let work := psKernelReplaceMutualInductiveInfos prepared.baseInfos
            (psKernelSimpleMutualHasRecursiveFields data.constructors)
            (psKernelSimpleMutualHasReflexiveFields data.constructors)
            constructors.context.scalar.environment;
          match psKernelExprV2MutualMakeRecursorPlan value.levelParams header.resultLevel value.isUnsafe data with
          | Except.error error => Option.some (Except.error error)
          | Except.ok plan =>
              psKernelExprV2MutualCheckRecursorsWith check whnf defeq fuel work
                prepared.context.scalar.maxRecDepth prepared.context.scalar.maxNatSize
                value.isUnsafe owner plan

def psKernelExprV2MutualAfterHeaderWith
    (check whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (defeq : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (fuel : Nat) (input built : PsKernelExprV2Decoded) (decl : PsKernelSimpleMutualInductiveDecl)
    (value : PsKernelDagInductiveGroup) (header : PsKernelExprV2MutualHeaderAnalysis) :
    Option (Except String PsKernelExprV2OrdinaryAdmissionResult) :=
  match psKernelExprV2MutualPrepareAdmissionAfterHeader input built decl value header with
  | Except.error error => Option.some (Except.error error)
  | Except.ok prepared =>
      let levels := psKernelLevelParamsToLevels value.levelParams;
      let targets := psKernelExprV2MutualTypeNames value.types;
      let analyze := fun (phaseFuel : Nat) (context : PsKernelExprV2CheckContext)
          (state : PsKernelExprV2CheckState) (owner : Nat) (ctor : PsKernelDagConstructor) =>
        psKernelExprV2MutualAnalyzeConstructorWith check whnf defeq phaseFuel context state
          targets header.types owner levels header.parameters.binders header.resultLevel ctor;
      let visit := psKernelExprV2MutualAddTypesWorker header.types;
      match visit analyze fuel input (psKernelExprV2OrdinaryOpenBinderCount header.parameters.binders)
          prepared.context prepared.state 0 with
      | Option.none => Option.none
      | Option.some attempted =>
          match attempted with
          | Except.error error => Option.some (Except.error error)
          | Except.ok constructors =>
              psKernelExprV2MutualAfterConstructorsWith check whnf defeq fuel input value header prepared constructors

def psKernelExprV2MutualAdmitWith
    (check whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (defeq : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (fuel : Nat) (environment : PsKernelEnvironment) (maxRecDepth maxNatSize : Nat)
    (input : PsKernelExprV2Decoded) (owner : PsKernelDagGeneratedState)
    (value : PsKernelDagInductiveGroup) : Option (Except String PsKernelExprV2OrdinaryAdmissionResult) :=
  if Nat.beq owner.built.size owner.arena.size then
    if Nat.ble input.size owner.built.size then
      match psKernelDagDecodeGroup input value with
      | Except.error error => Option.some (Except.error error)
      | Except.ok decl =>
          match psKernelExprV2MutualAnalyzeHeaderWith check whnf defeq fuel environment
              maxRecDepth maxNatSize owner.arena owner.declarations value with
          | Option.none => Option.none
          | Option.some attempted =>
              match attempted with
              | Except.error error => Option.some (Except.error error)
              | Except.ok header =>
                  psKernelExprV2MutualAfterHeaderWith check whnf defeq fuel input owner.built decl value header
    else Option.some (Except.error "PSKERNEL_V2_GENERATED_OWNER_MISMATCH")
  else Option.some (Except.error "PSKERNEL_V2_GENERATED_OWNER_MISMATCH")

def psKernelExprV2MutualAdmitWithFuel
    (fuel : Nat) (environment : PsKernelEnvironment) (maxRecDepth maxNatSize : Nat)
    (input : PsKernelExprV2Decoded) (owner : PsKernelDagGeneratedState)
    (value : PsKernelDagInductiveGroup) : Option (Except String PsKernelExprV2OrdinaryAdmissionResult) :=
  psKernelExprV2MutualAdmitWith psKernelExprV2TryCheckStateWithFuel
    psKernelExprV2TryWhnfCheckStateWithFuel psKernelExprV2TryDefEqStateWithFuel
    fuel environment maxRecDepth maxNatSize input owner value
