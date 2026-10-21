import Ps.KernelCore.API.Kernel
import Ps.KernelCore.API.DagDeclaration
import Ps.KernelCore.API.DagAdmissionGuards
import Ps.KernelCore.Checker.ExprV2.Check
import Ps.KernelCore.Checker.ExprV2.DefEq

/-
Partial direct declaration admission over a validated input DAG. Static guards,
header/body inference and final definitive equality read the owning arena.
Decoded boundary terms are retained for environment publication, not traversed
by these direct checks. No legacy type/body is imported.

The header, theorem proposition test and body share separate inference caches,
WHNF and successful DefEq state,
fresh counters and the declaration index. Each declaration starts a fresh
context and state. The final comparison receives the returned checker owner;
no semantic cache is transferred to another declaration.

Unsafe recursive definitions use a separate header and fresh private body owner.
Mutual definitions use fresh owners for each header and each body; all headers
finish before the complete private work environment is installed. Inductives
request whole-original-admission fallback. A none from any attempted operation
discards its state and restarts the complete original admission.
-/

/- Unlike binder EnsureSort, admission always performs public WHNF, including
   on a syntactic sort. SessionEnsureSort has the same mandatory resource cost. -/
def psKernelExprV2AdmissionEnsureSortOwnedWith
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (root : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState PsKernelLevel)) :=
  match whnf context state root with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok reduced =>
          let next := Prod.fst reduced;
          match psKernelExprV2PagedRequire next.whnf.arena (Prod.snd reduced) with
          | Except.error error => Option.some (Except.error error)
          | Except.ok result =>
              match result.node with
              | PsKernelExprV2Node.sort level =>
                  Option.some (Except.ok (Prod.mk next level))
              | _ => Option.some (Except.error "expected sort")

def psKernelExprV2AdmissionEnsureSortWithFuel
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (root : Nat) :
    Option (Except String PsKernelExprV2CheckState) :=
  let whnf :=
    fun (nextContext : PsKernelExprV2CheckContext)
        (nextState : PsKernelExprV2CheckState) (nextRoot : Nat) =>
      psKernelExprV2TryWhnfCheckStateWithFuel fuel nextContext nextState nextRoot;
  match psKernelExprV2AdmissionEnsureSortOwnedWith whnf context state root with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok result => Option.some (Except.ok (Prod.fst result))

/- Infer-only and mandatory public WHNF return their current complete owner.
   Neither phase may restore an earlier snapshot of the semantic caches. -/
def psKernelExprV2AdmissionIsPropOwnedWith
    (inferType : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (root : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  match inferType context state root with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok inferred =>
          match psKernelExprV2AdmissionEnsureSortOwnedWith whnf context
              (Prod.fst inferred) (Prod.snd inferred) with
          | Option.none => Option.none
          | Option.some sorted =>
              match sorted with
              | Except.error error => Option.some (Except.error error)
              | Except.ok result =>
                  Option.some (Except.ok
                    (Prod.mk (Prod.fst result)
                      (psKernelLevelNormalizesToZero (Prod.snd result))))

def psKernelExprV2AdmissionIsPropWithFuel
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (root : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  let inferType :=
    fun (nextContext : PsKernelExprV2CheckContext)
        (nextState : PsKernelExprV2CheckState) (nextRoot : Nat) =>
      psKernelExprV2TryInferStateWithFuel fuel nextContext nextState nextRoot;
  let whnf :=
    fun (nextContext : PsKernelExprV2CheckContext)
        (nextState : PsKernelExprV2CheckState) (nextRoot : Nat) =>
      psKernelExprV2TryWhnfCheckStateWithFuel fuel nextContext nextState nextRoot;
  psKernelExprV2AdmissionIsPropOwnedWith inferType whnf context state root

def psKernelExprV2AdmissionCheckHeaderWithFuel
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState)
    (base : PsKernelConstantBase) (typeRoot : Nat) :
    Option (Except String PsKernelExprV2CheckState) :=
  if psKernelEnvironmentContains context.scalar.environment base.name then
    Option.some (Except.error "already declared")
  else if psKernelNameHasDuplicates base.levelParams then
    Option.some (Except.error "duplicate universe parameter")
  else
    match psKernelExprV2AdmissionStaticOnCanonical
        state.whnf.arena typeRoot base.levelParams with
    | Except.error error => Option.some (Except.error error)
    | Except.ok _ =>
        match psKernelExprV2TryCheckStateWithFuel fuel context state typeRoot with
        | Option.none => Option.none
        | Option.some attempted =>
            match attempted with
            | Except.error error => Option.some (Except.error error)
            | Except.ok checked =>
                psKernelExprV2AdmissionEnsureSortWithFuel fuel context
                  (Prod.fst checked) (Prod.snd checked)

def psKernelExprV2AdmissionCheckBodyWithFuel
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState)
    (base : PsKernelConstantBase) (typeRoot : Nat)
    (_body : PsKernelExpr) (bodyRoot : Nat) (mismatch : String) :
    Option (Except String Unit) :=
  match psKernelExprV2AdmissionStaticOnCanonical
      state.whnf.arena bodyRoot base.levelParams with
  | Except.error error => Option.some (Except.error error)
  | Except.ok _ =>
      match psKernelExprV2TryCheckStateWithFuel fuel context state bodyRoot with
      | Option.none => Option.none
      | Option.some attempted =>
          match attempted with
          | Except.error error => Option.some (Except.error error)
          | Except.ok checked =>
              match psKernelExprV2TryDefEqStateWithFuel fuel context
                  (Prod.fst checked) (Prod.snd checked) typeRoot with
              | Option.none => Option.none
              | Option.some compared =>
                  match compared with
                  | Except.error error => Option.some (Except.error error)
                  | Except.ok result =>
                      if Prod.snd result then Option.some (Except.ok ())
                      else Option.some (Except.error mismatch)

/- A trusted internal plan, not an admission certificate. DecodeDeclaration
   establishes correspondence between every root and its boundary expression. -/
structure PsKernelDagSimpleAdmissionPlan where
  base : PsKernelConstantBase
  typeRoot : Nat
  body : Option (Prod PsKernelExpr Nat)
  mismatch : String
  safety : PsKernelDefinitionSafety
  info : PsKernelConstantInfo

def psKernelDagSimpleAdmissionPlan
    (source : PsKernelDagDeclarationRequest)
    (declaration : PsKernelDeclarationRequest) :
    Option PsKernelDagSimpleAdmissionPlan :=
  match source with
  | PsKernelDagDeclarationRequest.axiomDecl base _ =>
      match declaration with
      | PsKernelDeclarationRequest.axiomDecl value =>
          let safety : PsKernelDefinitionSafety :=
            if value.isUnsafe then PsKernelDefinitionSafety.unsafeDef
            else PsKernelDefinitionSafety.safe;
          Option.some
            (PsKernelDagSimpleAdmissionPlan.mk value.base base.type Option.none
              "" safety (PsKernelConstantInfo.axiomInfo value))
      | _ => Option.none
  | PsKernelDagDeclarationRequest.definitionDecl input =>
      match declaration with
      | PsKernelDeclarationRequest.definitionDecl value =>
          if psKernelDefinitionSafetyIsUnsafe value.safety then Option.none
          else
            Option.some
              (PsKernelDagSimpleAdmissionPlan.mk value.base input.base.type
                (Option.some (Prod.mk value.value input.value))
                "definition type mismatch" PsKernelDefinitionSafety.safe
                (PsKernelConstantInfo.defnInfo value))
      | _ => Option.none
  | PsKernelDagDeclarationRequest.theoremDecl base body =>
      match declaration with
      | PsKernelDeclarationRequest.theoremDecl value =>
          Option.some
            (PsKernelDagSimpleAdmissionPlan.mk value.base base.type
              (Option.some (Prod.mk value.value body))
              "theorem proof type mismatch" PsKernelDefinitionSafety.safe
              (PsKernelConstantInfo.thmInfo value))
      | _ => Option.none
  | PsKernelDagDeclarationRequest.opaqueDecl base body _ =>
      match declaration with
      | PsKernelDeclarationRequest.opaqueDecl value =>
          Option.some
            (PsKernelDagSimpleAdmissionPlan.mk value.base base.type
              (Option.some (Prod.mk value.value body))
              "opaque value type mismatch" PsKernelDefinitionSafety.safe
              (PsKernelConstantInfo.opaqueInfo value))
      | _ => Option.none
  | _ => Option.none

def psKernelExprV2AdmissionPrepareBodyWithFuel
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (plan : PsKernelDagSimpleAdmissionPlan) :
    Option (Except String PsKernelExprV2CheckState) :=
  match plan.info with
  | PsKernelConstantInfo.thmInfo _ =>
      match psKernelExprV2AdmissionIsPropWithFuel fuel context state plan.typeRoot with
      | Option.none => Option.none
      | Option.some attempted =>
          match attempted with
          | Except.error error => Option.some (Except.error error)
          | Except.ok result =>
              if Prod.snd result then Option.some (Except.ok (Prod.fst result))
              else Option.some (Except.error "theorem type is not a proposition")
  | _ => Option.some (Except.ok state)

/- Unsafe recursion checks its header in the original environment, then checks
   the body in a fresh owner over a private recursive work environment. The
   temporary self reference is not published into the caller's batch index. -/
def psKernelDagTryAdmitUnsafeDefinitionWithFuel
    (fuel : Nat) (environment : PsKernelEnvironment)
    (maxRecDepth maxNatSize : Nat) (arena : PsKernelExprV2PagedArena)
    (declarations : List PsKernelExprV2DeclarationRef)
    (source : PsKernelDagDefinition) (value : PsKernelDefinitionInfo) :
    Option (Except String PsKernelEnvironment) :=
  if psKernelDefinitionSafetyIsUnsafe value.safety then
    let headerChecker := psKernelMkCheckerSession environment value.base.levelParams
      PsKernelDefinitionSafety.unsafeDef maxRecDepth maxNatSize;
    let headerContext := psKernelExprV2CheckContextEmpty headerChecker.context;
    let headerState :=
      psKernelExprV2CheckStateWithWhnf (psKernelExprV2CheckStateEmpty arena)
        (psKernelExprV2WhnfStateForDeclarations arena declarations);
    match psKernelExprV2AdmissionCheckHeaderWithFuel fuel headerContext headerState
        value.base source.base.type with
    | Option.none => Option.none
    | Option.some attemptedHeader =>
        match attemptedHeader with
        | Except.error error => Option.some (Except.error error)
        | Except.ok _ =>
            match psKernelEnvironmentAdd environment (PsKernelConstantInfo.defnInfo value) with
            | Except.error error => Option.some (Except.error error)
            | Except.ok work =>
                let bodyChecker := psKernelMkCheckerSession work value.base.levelParams
                  PsKernelDefinitionSafety.unsafeDef maxRecDepth maxNatSize;
                let bodyContext := psKernelExprV2CheckContextEmpty bodyChecker.context;
                let bodyDeclarations :=
                  List.cons (psKernelDagDefinitionRef source) declarations;
                let bodyState :=
                  psKernelExprV2CheckStateWithWhnf (psKernelExprV2CheckStateEmpty arena)
                    (psKernelExprV2WhnfStateForDeclarations arena bodyDeclarations);
                match psKernelExprV2AdmissionCheckBodyWithFuel fuel bodyContext bodyState
                    value.base source.base.type value.value source.value
                    "definition type mismatch" with
                | Option.none => Option.none
                | Option.some attemptedBody =>
                    match attemptedBody with
                    | Except.error error => Option.some (Except.error error)
                    | Except.ok _ => Option.some (Except.ok work)
  else Option.none

/- Every header and every body owns a fresh checker, preserving PSKernel's
   published cache/fuel behavior. Headers see only the original environment. -/
def psKernelDagTryMutualHeaders
    (sources : List PsKernelDagDefinition) :
    List PsKernelDefinitionInfo -> Nat -> PsKernelEnvironment ->
    PsKernelDefinitionInfo -> Nat -> Nat -> PsKernelExprV2PagedArena ->
    List PsKernelExprV2DeclarationRef -> List PsKernelName ->
    Option (Except String Unit) :=
  match sources with
  | List.nil =>
      fun (values : List PsKernelDefinitionInfo) (_fuel : Nat)
          (_environment : PsKernelEnvironment) (_first : PsKernelDefinitionInfo)
          (_maxRecDepth : Nat) (_maxNatSize : Nat) (_arena : PsKernelExprV2PagedArena)
          (_declarations : List PsKernelExprV2DeclarationRef) (_seen : List PsKernelName) =>
        match values with
        | List.nil => Option.some (Except.ok Unit.unit)
        | List.cons _ _ => Option.none
  | List.cons source rest =>
      fun (values : List PsKernelDefinitionInfo) (fuel : Nat)
          (environment : PsKernelEnvironment) (first : PsKernelDefinitionInfo)
          (maxRecDepth : Nat) (maxNatSize : Nat) (arena : PsKernelExprV2PagedArena)
          (declarations : List PsKernelExprV2DeclarationRef) (seen : List PsKernelName) =>
        match values with
        | List.nil => Option.none
        | List.cons value remaining =>
            if psKernelSafetyEq value.safety first.safety then
              if psKernelNameListsEq value.base.levelParams first.base.levelParams then
                if psKernelNameMember value.base.name seen then
                  Option.some
                    (Except.error "invalid mutual definition, duplicate declaration name")
                else
                  let checker := psKernelMkCheckerSession environment value.base.levelParams
                    first.safety maxRecDepth maxNatSize;
                  let context := psKernelExprV2CheckContextEmpty checker.context;
                  let state :=
                    psKernelExprV2CheckStateWithWhnf (psKernelExprV2CheckStateEmpty arena)
                      (psKernelExprV2WhnfStateForDeclarations arena declarations);
                  match psKernelExprV2AdmissionCheckHeaderWithFuel fuel context state
                      value.base source.base.type with
                  | Option.none => Option.none
                  | Option.some attempted =>
                      match attempted with
                      | Except.error error => Option.some (Except.error error)
                      | Except.ok _ =>
                          let recur := psKernelDagTryMutualHeaders rest;
                          recur remaining fuel environment first maxRecDepth maxNatSize
                            arena declarations (List.cons value.base.name seen)
              else
                Option.some
                  (Except.error
                    "invalid mutual definition, declarations must have the same universe level parameters")
            else
              Option.some
                (Except.error
                  "invalid mutual definition, declarations must have the same safety annotation")

def psKernelDagTryMutualBodies
    (sources : List PsKernelDagDefinition) :
    List PsKernelDefinitionInfo -> Nat -> PsKernelEnvironment ->
    PsKernelDefinitionSafety -> Nat -> Nat -> PsKernelExprV2PagedArena ->
    List PsKernelExprV2DeclarationRef -> Option (Except String Unit) :=
  match sources with
  | List.nil =>
      fun (values : List PsKernelDefinitionInfo) (_fuel : Nat)
          (_environment : PsKernelEnvironment) (_safety : PsKernelDefinitionSafety)
          (_maxRecDepth : Nat) (_maxNatSize : Nat) (_arena : PsKernelExprV2PagedArena)
          (_declarations : List PsKernelExprV2DeclarationRef) =>
        match values with
        | List.nil => Option.some (Except.ok Unit.unit)
        | List.cons _ _ => Option.none
  | List.cons source rest =>
      fun (values : List PsKernelDefinitionInfo) (fuel : Nat)
          (environment : PsKernelEnvironment) (safety : PsKernelDefinitionSafety)
          (maxRecDepth : Nat) (maxNatSize : Nat) (arena : PsKernelExprV2PagedArena)
          (declarations : List PsKernelExprV2DeclarationRef) =>
        match values with
        | List.nil => Option.none
        | List.cons value remaining =>
            let checker := psKernelMkCheckerSession environment value.base.levelParams
              safety maxRecDepth maxNatSize;
            let context := psKernelExprV2CheckContextEmpty checker.context;
            let state :=
              psKernelExprV2CheckStateWithWhnf (psKernelExprV2CheckStateEmpty arena)
                (psKernelExprV2WhnfStateForDeclarations arena declarations);
            match psKernelExprV2AdmissionCheckBodyWithFuel fuel context state
                value.base source.base.type value.value source.value
                "definition type mismatch" with
            | Option.none => Option.none
            | Option.some attempted =>
                match attempted with
                | Except.error error => Option.some (Except.error error)
                | Except.ok _ =>
                    let recur := psKernelDagTryMutualBodies rest;
                    recur remaining fuel environment safety maxRecDepth maxNatSize
                      arena declarations

def psKernelDagTryAdmitMutualDefinitionsWithFuel
    (fuel : Nat) (environment : PsKernelEnvironment)
    (maxRecDepth maxNatSize : Nat) (arena : PsKernelExprV2PagedArena)
    (declarations : List PsKernelExprV2DeclarationRef)
    (sources : List PsKernelDagDefinition) (values : List PsKernelDefinitionInfo) :
    Option (Except String PsKernelEnvironment) :=
  match values with
  | List.nil => Option.some (Except.error "invalid empty mutual definition")
  | List.cons first _ =>
      if psKernelDefinitionSafetyIsSafe first.safety then
        Option.some
          (Except.error "invalid mutual definition, declaration is not tagged as unsafe/partial")
      else
        match psKernelDagTryMutualHeaders sources values fuel environment first
            maxRecDepth maxNatSize arena declarations List.nil with
        | Option.none => Option.none
        | Option.some attemptedHeaders =>
            match attemptedHeaders with
            | Except.error error => Option.some (Except.error error)
            | Except.ok _ =>
                let work := psKernelMutualWorkEnvironment values environment;
                let workDeclarations := psKernelDagAddAdmittedDefinitions sources declarations;
                match psKernelDagTryMutualBodies sources values fuel work first.safety
                    maxRecDepth maxNatSize arena workDeclarations with
                | Option.none => Option.none
                | Option.some attemptedBodies =>
                    match attemptedBodies with
                    | Except.error error => Option.some (Except.error error)
                    | Except.ok _ => Option.some (Except.ok work)

def psKernelDagTryAdmitSimpleWithFuel
    (fuel : Nat) (environment : PsKernelEnvironment)
    (maxRecDepth maxNatSize : Nat) (arena : PsKernelExprV2PagedArena)
    (declarations : List PsKernelExprV2DeclarationRef)
    (source : PsKernelDagDeclarationRequest)
    (declaration : PsKernelDeclarationRequest) :
    Option (Except String PsKernelEnvironment) :=
  match psKernelDagSimpleAdmissionPlan source declaration with
  | Option.none =>
      match source with
      | PsKernelDagDeclarationRequest.definitionDecl input =>
          match declaration with
          | PsKernelDeclarationRequest.definitionDecl value =>
              if psKernelDefinitionSafetyIsUnsafe value.safety then
                psKernelDagTryAdmitUnsafeDefinitionWithFuel fuel environment
                  maxRecDepth maxNatSize arena declarations input value
              else Option.none
          | _ => Option.none
      | PsKernelDagDeclarationRequest.mutualDefinitions inputs =>
          match declaration with
          | PsKernelDeclarationRequest.mutualDefinitions values =>
              psKernelDagTryAdmitMutualDefinitionsWithFuel fuel environment
                maxRecDepth maxNatSize arena declarations inputs values
          | _ => Option.none
      | _ => Option.none
  | Option.some plan =>
      let checker := psKernelMkCheckerSession environment plan.base.levelParams
        plan.safety maxRecDepth maxNatSize;
      let context := psKernelExprV2CheckContextEmpty checker.context;
      let initial :=
        psKernelExprV2CheckStateWithWhnf (psKernelExprV2CheckStateEmpty arena)
          (psKernelExprV2WhnfStateForDeclarations arena declarations);
      match psKernelExprV2AdmissionCheckHeaderWithFuel fuel context initial
          plan.base plan.typeRoot with
      | Option.none => Option.none
      | Option.some attemptedHeader =>
          match attemptedHeader with
          | Except.error error => Option.some (Except.error error)
          | Except.ok afterHeader =>
              match psKernelExprV2AdmissionPrepareBodyWithFuel fuel context afterHeader plan with
              | Option.none => Option.none
              | Option.some attemptedPreparation =>
                  match attemptedPreparation with
                  | Except.error error => Option.some (Except.error error)
                  | Except.ok prepared =>
                      match plan.body with
                      | Option.none =>
                          Option.some (psKernelEnvironmentAdd environment plan.info)
                      | Option.some body =>
                          match psKernelExprV2AdmissionCheckBodyWithFuel fuel context prepared
                              plan.base plan.typeRoot (Prod.fst body) (Prod.snd body) plan.mismatch with
                          | Option.none => Option.none
                          | Option.some attemptedBody =>
                              match attemptedBody with
                              | Except.error error => Option.some (Except.error error)
                              | Except.ok _ =>
                                  Option.some (psKernelEnvironmentAdd environment plan.info)

def psKernelDagAdmitDeclaration
    (session : PsKernelKernelSession) (arena : PsKernelExprV2PagedArena)
    (declarations : List PsKernelExprV2DeclarationRef)
    (source : PsKernelDagDeclarationRequest)
    (declaration : PsKernelDeclarationRequest) :
    Except PsKernelError PsKernelAdmissionResult :=
  match psKernelKernelSessionPreflight session with
  | Except.error error => Except.error error
  | Except.ok _ =>
      match psKernelDagTryAdmitSimpleWithFuel session.resources.fuel
          (psKernelKernelSessionEnvironment session)
          session.resources.maxRecDepth session.resources.maxNatSize
          arena declarations source declaration with
      | Option.none => psKernelV1AdmitDeclaration session declaration
      | Option.some attempted =>
          match attempted with
          | Except.error error => Except.error (psKernelErrorFromMessage error)
          | Except.ok environment =>
              if psKernelResourceAllowsSize session.resources
                  (psKernelEnvironmentSize environment) then
                let checkedEnvironment :=
                  psKernelEnvironmentWithNativeEvaluator environment Option.none;
                Except.ok
                  (PsKernelAdmissionResult.mk
                    (PsKernelKernelSession.mk checkedEnvironment session.resources session.provider)
                    (PsKernelCheckedDeclaration.mk declaration
                      (psKernelV1Receipt session checkedEnvironment)))
              else
                Except.error
                  (PsKernelError.resourceExhausted PsKernelResourceError.declarationLimit
                    "declaration limit exceeded")
