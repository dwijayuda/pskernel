import Ps.KernelCore.API.Kernel
import Ps.KernelCore.API.DagDeclaration
import Ps.KernelCore.Checker.ExprV2.Check
import Ps.KernelCore.Checker.ExprV2.DefEq

/-
Partial direct declaration admission over a validated input DAG. Static guards
read the already decoded boundary terms; header/body inference and final
definitive equality read the owning arena. No legacy type/body is imported.

The header and body share checked-inference, WHNF and successful DefEq state,
fresh counters and the declaration index. Each declaration starts a fresh
context and state. The final comparison receives the returned checker owner;
no semantic cache is transferred to another declaration.

Unsafe recursive definitions, theorems, mutual definitions and inductives
request whole-original-admission fallback. A none from any attempted operation
discards its state and restarts the complete original admission.
-/

def psKernelExprV2AdmissionEnsureSortWithFuel
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (root : Nat) :
    Option (Except String PsKernelExprV2CheckState) :=
  match psKernelExprV2CheckWhnfWithFuel fuel context state.whnf root with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok reduced =>
          let next := Prod.fst reduced;
          match psKernelExprV2PagedRequire next.arena (Prod.snd reduced) with
          | Except.error error => Option.some (Except.error error)
          | Except.ok result =>
              match result.node with
              | PsKernelExprV2Node.sort _ =>
                  Option.some
                    (Except.ok (psKernelExprV2CheckStateWithWhnf state next))
              | _ => Option.some (Except.error "expected sort")

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
    match psKernelCheckNoMVarNoFVar base.type with
    | Except.error error => Option.some (Except.error error)
    | Except.ok _ =>
        match psKernelCheckLevelParams base.type base.levelParams with
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
    (body : PsKernelExpr) (bodyRoot : Nat) (mismatch : String) :
    Option (Except String Unit) :=
  match psKernelCheckNoMVarNoFVar body with
  | Except.error error => Option.some (Except.error error)
  | Except.ok _ =>
      match psKernelCheckLevelParams body base.levelParams with
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

def psKernelDagTryAdmitSimpleWithFuel
    (fuel : Nat) (environment : PsKernelEnvironment)
    (maxRecDepth maxNatSize : Nat) (arena : PsKernelExprV2PagedArena)
    (declarations : List PsKernelExprV2DeclarationRef)
    (source : PsKernelDagDeclarationRequest)
    (declaration : PsKernelDeclarationRequest) :
    Option (Except String PsKernelEnvironment) :=
  match psKernelDagSimpleAdmissionPlan source declaration with
  | Option.none => Option.none
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
              match plan.body with
              | Option.none =>
                  Option.some (psKernelEnvironmentAdd environment plan.info)
              | Option.some body =>
                  match psKernelExprV2AdmissionCheckBodyWithFuel fuel context afterHeader
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
