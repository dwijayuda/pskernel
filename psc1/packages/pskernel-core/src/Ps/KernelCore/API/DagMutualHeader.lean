import Ps.KernelCore.API.DagOrdinaryHeader
import Ps.KernelCore.API.DagOrdinaryConstructorParams
import Ps.KernelCore.Admission.Inductive.Mutual.Header

/- Private mutual-header analysis, not admission. Every returned ID belongs
   to one append-only arena. Later closed checks start with fresh locals,
   caches and freshness; parameter alignment always resumes the first shared
   parameter owner. Only the arena is carried across those scope boundaries.
   No provisional declaration or environment is installed by this module. -/

structure PsKernelExprV2MutualTypeHeader where
  declaration : PsKernelDagInductive
  indices : PsKernelExprV2OrdinaryOpenResult

structure PsKernelExprV2MutualHeaderAnalysis where
  parameters : PsKernelExprV2OrdinaryOpenResult
  types : List PsKernelExprV2MutualTypeHeader
  resultLevel : PsKernelLevel
  arena : PsKernelExprV2PagedArena

def psKernelExprV2MutualTypeCount
    (types : List PsKernelDagInductive) : Nat :=
  match types with
  | List.nil => 0
  | List.cons _ rest => Nat.succ (psKernelExprV2MutualTypeCount rest)

def psKernelExprV2MutualTypeNames
    (types : List PsKernelDagInductive) : List PsKernelName :=
  match types with
  | List.nil => List.nil
  | List.cons value rest =>
      List.cons value.name (psKernelExprV2MutualTypeNames rest)

def psKernelExprV2MutualRecNames
    (types : List PsKernelDagInductive) : List PsKernelName :=
  match types with
  | List.nil => List.nil
  | List.cons value rest =>
      List.cons (psKernelSimpleRecName value.name)
        (psKernelExprV2MutualRecNames rest)

def psKernelExprV2MutualCtorNames
    (types : List PsKernelDagInductive) : List PsKernelName :=
  match types with
  | List.nil => List.nil
  | List.cons value rest =>
      psKernelMutualNameListAppend (psKernelExprV2OrdinaryCtorNames value.ctors)
        (psKernelExprV2MutualCtorNames rest)

def psKernelExprV2MutualUniformOccurrences
    (types : List PsKernelDagInductive) :
    PsKernelExprV2PagedArena -> List PsKernelName -> List PsKernelLevel ->
    Nat -> Except String Unit :=
  match types with
  | List.nil =>
      fun (_arena : PsKernelExprV2PagedArena) (_names : List PsKernelName)
          (_levels : List PsKernelLevel) (_numParams : Nat) => Except.ok ()
  | List.cons value rest =>
      let smaller := psKernelExprV2MutualUniformOccurrences rest;
      fun (arena : PsKernelExprV2PagedArena) (names : List PsKernelName)
          (levels : List PsKernelLevel) (numParams : Nat) =>
        match psKernelExprV2OrdinaryUniformOccurrences
            (psKernelExprV2OrdinaryCtorTypes value.ctors) arena names levels numParams with
        | Except.error error => Except.error error
        | Except.ok _ => smaller arena names levels numParams

/- Group-level validation precedes every individual type/static/check phase.
   Use the complete mutual name set when inspecting constructor occurrences. -/
def psKernelExprV2MutualHeaderGuardsOnCanonical
    (arena : PsKernelExprV2PagedArena) (environment : PsKernelEnvironment)
    (value : PsKernelDagInductiveGroup) : Except String Unit :=
  if psKernelNameHasDuplicates value.levelParams then
    Except.error "duplicate universe parameter"
  else if psKernelNatLt (psKernelExprV2MutualTypeCount value.types) 2 then
    Except.error "mutual inductive admission requires at least two datatypes"
  else
    let typeNames := psKernelExprV2MutualTypeNames value.types;
    let allNames := psKernelMutualNameListAppend typeNames
      (psKernelMutualNameListAppend (psKernelExprV2MutualRecNames value.types)
        (psKernelExprV2MutualCtorNames value.types));
    if psKernelSimpleNameListUnique allNames then
      match psKernelCheckFreshInductiveNames allNames environment with
      | Except.error error => Except.error error
      | Except.ok _ =>
          psKernelExprV2MutualUniformOccurrences value.types arena typeNames
            (psKernelLevelParamsToLevels value.levelParams) value.numParams
    else Except.error "duplicate inductive, constructor, or recursor name"

def psKernelExprV2MutualClosedContext
    (environment : PsKernelEnvironment) (value : PsKernelDagInductiveGroup)
    (maxRecDepth maxNatSize : Nat) : PsKernelExprV2CheckContext :=
  let safety :=
    if value.isUnsafe then PsKernelDefinitionSafety.unsafeDef
    else PsKernelDefinitionSafety.safe;
  let checker := psKernelMkCheckerSession environment value.levelParams
    safety maxRecDepth maxNatSize;
  psKernelExprV2CheckContextEmpty checker.context

def psKernelExprV2MutualClosedState
    (arena : PsKernelExprV2PagedArena)
    (declarations : List PsKernelExprV2DeclarationRef) : PsKernelExprV2CheckState :=
  psKernelExprV2CheckStateWithWhnf (psKernelExprV2CheckStateEmpty arena)
    (psKernelExprV2WhnfStateForDeclarations arena declarations)

def psKernelExprV2MutualResumeParameters
    (parameters : PsKernelExprV2OrdinaryOpenResult)
    (arena : PsKernelExprV2PagedArena) : PsKernelExprV2CheckState :=
  psKernelExprV2CheckStateWithArena parameters.state arena

def psKernelExprV2MutualFinishIndices
    (resultLevel : PsKernelLevel) (indices : PsKernelExprV2OrdinaryOpenResult) :
    Except String PsKernelExprV2OrdinaryOpenResult :=
  match psKernelExprV2PagedRequire indices.state.whnf.arena indices.result with
  | Except.error error => Except.error error
  | Except.ok entry =>
      match entry.node with
      | PsKernelExprV2Node.sort level =>
          if psKernelLevelEquivalent level resultLevel then Except.ok indices
          else Except.error "mutually inductive types must live in the same universe"
      | _ => Except.error "mutual inductive result must be a sort"

/- Closed type checking is mandatory even if the shared parameter alignment
   could succeed. Its semantic state is discarded after EnsureSort; only its
   appended arena is retained so none of its private IDs can be misinterpreted. -/
def psKernelExprV2MutualRemainingPhasesWith
    (check whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (defeq : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (fuel : Nat) (closedContext : PsKernelExprV2CheckContext)
    (closedState : PsKernelExprV2CheckState)
    (parameters : PsKernelExprV2OrdinaryOpenResult)
    (type : Nat) (resultLevel : PsKernelLevel) :
    Option (Except String PsKernelExprV2OrdinaryOpenResult) :=
  match check fuel closedContext closedState type with
  | Option.none => Option.none
  | Option.some attemptedCheck =>
      match attemptedCheck with
      | Except.error error => Option.some (Except.error error)
      | Except.ok checked =>
          match psKernelExprV2AdmissionEnsureSortOwnedWith
              (whnf fuel) closedContext (Prod.fst checked) (Prod.snd checked) with
          | Option.none => Option.none
          | Option.some attemptedSort =>
              match attemptedSort with
              | Except.error error => Option.some (Except.error error)
              | Except.ok sorted =>
                  let state := psKernelExprV2MutualResumeParameters
                    parameters (Prod.fst sorted).whnf.arena;
                  match psKernelExprV2OrdinaryOpenConstructorParamsWith defeq fuel
                      parameters.context state parameters.binders type with
                  | Option.none => Option.none
                  | Option.some attemptedParams =>
                      match attemptedParams with
                      | Except.error error => Option.some (Except.error error)
                      | Except.ok aligned =>
                          match psKernelExprV2OrdinaryOpenHeaderIndicesWith check whnf fuel
                              parameters.context (Prod.fst aligned) (Prod.snd aligned) with
                          | Option.none => Option.none
                          | Option.some attemptedIndices =>
                              match attemptedIndices with
                              | Except.error error => Option.some (Except.error error)
                              | Except.ok indices =>
                                  Option.some
                                    (psKernelExprV2MutualFinishIndices resultLevel indices)

def psKernelExprV2MutualRemainingHeadersWith
    (types : List PsKernelDagInductive) :
    (Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat))) ->
    (Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat))) ->
    (Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool))) ->
    Nat -> PsKernelExprV2CheckContext -> List PsKernelExprV2DeclarationRef ->
    PsKernelExprV2OrdinaryOpenResult -> PsKernelLevel -> PsKernelExprV2PagedArena ->
    Option (Except String (Prod (List PsKernelExprV2MutualTypeHeader) PsKernelExprV2PagedArena)) :=
  match types with
  | List.nil =>
      fun
        (_check _whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
        (_defeq : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Bool)))
        (_fuel : Nat) (_context : PsKernelExprV2CheckContext)
        (_declarations : List PsKernelExprV2DeclarationRef)
        (_parameters : PsKernelExprV2OrdinaryOpenResult) (_level : PsKernelLevel)
        (arena : PsKernelExprV2PagedArena) =>
        Option.some (Except.ok (Prod.mk List.nil arena))
  | List.cons value rest =>
      let smaller := psKernelExprV2MutualRemainingHeadersWith rest;
      fun
        (check whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
        (defeq : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Bool)))
        (fuel : Nat) (context : PsKernelExprV2CheckContext)
        (declarations : List PsKernelExprV2DeclarationRef)
        (parameters : PsKernelExprV2OrdinaryOpenResult) (level : PsKernelLevel)
        (arena : PsKernelExprV2PagedArena) =>
        match psKernelExprV2AdmissionStaticOnCanonical arena value.type
            context.scalar.levelParams with
        | Except.error error => Option.some (Except.error error)
        | Except.ok _ =>
            match psKernelExprV2MutualRemainingPhasesWith check whnf defeq fuel context
                (psKernelExprV2MutualClosedState arena declarations) parameters value.type level with
            | Option.none => Option.none
            | Option.some attempted =>
                match attempted with
                | Except.error error => Option.some (Except.error error)
                | Except.ok indices =>
                    match smaller check whnf defeq fuel context declarations parameters
                        level indices.state.whnf.arena with
                    | Option.none => Option.none
                    | Option.some attemptedRest =>
                        match attemptedRest with
                        | Except.error error => Option.some (Except.error error)
                        | Except.ok tail =>
                            Option.some (Except.ok
                              (Prod.mk (List.cons
                                (PsKernelExprV2MutualTypeHeader.mk value indices) (Prod.fst tail))
                                (Prod.snd tail)))

def psKernelExprV2MutualAnalyzeHeaderWith
    (check whnf : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (defeq : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (fuel : Nat) (environment : PsKernelEnvironment) (maxRecDepth maxNatSize : Nat)
    (arena : PsKernelExprV2PagedArena) (declarations : List PsKernelExprV2DeclarationRef)
    (value : PsKernelDagInductiveGroup) :
    Option (Except String PsKernelExprV2MutualHeaderAnalysis) :=
  match psKernelExprV2MutualHeaderGuardsOnCanonical arena environment value with
  | Except.error error => Option.some (Except.error error)
  | Except.ok _ =>
      match value.types with
      | List.nil => Option.some (Except.error "empty mutual inductive declaration")
      | List.cons first remaining =>
          match psKernelExprV2AdmissionStaticOnCanonical arena first.type value.levelParams with
          | Except.error error => Option.some (Except.error error)
          | Except.ok _ =>
              let context := psKernelExprV2MutualClosedContext
                environment value maxRecDepth maxNatSize;
              match psKernelExprV2OrdinaryHeaderPhasesWith check whnf fuel context
                  (psKernelExprV2MutualClosedState arena declarations) first.type value.numParams with
              | Option.none => Option.none
              | Option.some attemptedFirst =>
                  match attemptedFirst with
                  | Except.error error => Option.some (Except.error error)
                  | Except.ok firstHeader =>
                      match psKernelExprV2MutualRemainingHeadersWith remaining check whnf defeq
                          fuel context declarations firstHeader.parameters firstHeader.resultLevel
                          firstHeader.indices.state.whnf.arena with
                      | Option.none => Option.none
                      | Option.some attemptedRemaining =>
                          match attemptedRemaining with
                          | Except.error error => Option.some (Except.error error)
                          | Except.ok tail =>
                              Option.some (Except.ok (PsKernelExprV2MutualHeaderAnalysis.mk
                                firstHeader.parameters
                                (List.cons (PsKernelExprV2MutualTypeHeader.mk first firstHeader.indices)
                                  (Prod.fst tail)) firstHeader.resultLevel (Prod.snd tail)))

def psKernelExprV2MutualAnalyzeHeaderWithFuel
    (fuel : Nat) (environment : PsKernelEnvironment) (maxRecDepth maxNatSize : Nat)
    (arena : PsKernelExprV2PagedArena) (declarations : List PsKernelExprV2DeclarationRef)
    (value : PsKernelDagInductiveGroup) :
    Option (Except String PsKernelExprV2MutualHeaderAnalysis) :=
  psKernelExprV2MutualAnalyzeHeaderWith psKernelExprV2TryCheckStateWithFuel
    psKernelExprV2TryWhnfCheckStateWithFuel psKernelExprV2TryDefEqStateWithFuel
    fuel environment maxRecDepth maxNatSize arena declarations value
