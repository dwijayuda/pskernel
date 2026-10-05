import Ps.KernelCore.API.Session

def psKernelV1EnvironmentOutcome
    (result : Except String PsKernelEnvironment) : Except PsKernelError PsKernelEnvironment :=
  match result with
  | Except.ok environment => Except.ok environment
  | Except.error message => Except.error (psKernelErrorFromMessage message)

def psKernelV1DispatchDeclaration
    (session : PsKernelKernelSession)
    (request : PsKernelDeclarationRequest) : Except PsKernelError PsKernelEnvironment :=
  let fuel := session.resources.fuel;
  let depth := session.resources.maxRecDepth;
  let natSize := session.resources.maxNatSize;
  let environment := psKernelKernelSessionEnvironment session;
  match request with
  | PsKernelDeclarationRequest.axiomDecl value =>
      psKernelV1EnvironmentOutcome (psKernelAddAxiom fuel environment value depth natSize)
  | PsKernelDeclarationRequest.definitionDecl value =>
      psKernelV1EnvironmentOutcome (psKernelAddDefinition fuel environment value depth natSize)
  | PsKernelDeclarationRequest.theoremDecl value =>
      psKernelV1EnvironmentOutcome (psKernelAddTheorem fuel environment value depth natSize)
  | PsKernelDeclarationRequest.opaqueDecl value =>
      psKernelV1EnvironmentOutcome (psKernelAddOpaque fuel environment value depth natSize)
  | PsKernelDeclarationRequest.mutualDefinitions values =>
      psKernelV1EnvironmentOutcome (psKernelAddMutualDefinitions fuel environment values depth natSize)
  | PsKernelDeclarationRequest.quot =>
      psKernelV1EnvironmentOutcome (psKernelAddQuot environment)
  | PsKernelDeclarationRequest.ordinaryInductive value =>
      psKernelV1EnvironmentOutcome (psKernelAddSimpleInductive fuel environment value depth natSize)
  | PsKernelDeclarationRequest.mutualInductive value =>
      psKernelV1EnvironmentOutcome (psKernelAddSimpleMutualInductive fuel environment value depth natSize)
  | PsKernelDeclarationRequest.nestedInductive value =>
      psKernelV1EnvironmentOutcome (psKernelAddSimpleNestedInductive fuel environment value depth natSize)
  | PsKernelDeclarationRequest.unsupported feature =>
      Except.error (PsKernelError.declinedUnsupported feature)

def psKernelV1CheckedEnvironment
    (session : PsKernelKernelSession)
    (request : PsKernelDeclarationRequest) : Except PsKernelError PsKernelEnvironment :=
  match psKernelKernelSessionPreflight session with
  | Except.error error => Except.error error
  | Except.ok _ =>
      match psKernelV1DispatchDeclaration session request with
      | Except.error error => Except.error error
      | Except.ok environment =>
          if psKernelResourceAllowsSize session.resources (psKernelEnvironmentSize environment) then
            Except.ok (psKernelEnvironmentWithNativeEvaluator environment Option.none)
          else
            Except.error
              (PsKernelError.resourceExhausted PsKernelResourceError.declarationLimit "declaration limit exceeded")

def psKernelV1Receipt
    (session : PsKernelKernelSession)
    (environment : PsKernelEnvironment) : PsKernelCheckingReceipt :=
  PsKernelCheckingReceipt.mk psKernelTargetIdentityV1
    (psKernelEnvironmentSize session.environment) (psKernelEnvironmentSize environment)

def psKernelV1CheckDeclaration
    (session : PsKernelKernelSession)
    (request : PsKernelDeclarationRequest) : Except PsKernelError PsKernelCheckedDeclaration :=
  match psKernelV1CheckedEnvironment session request with
  | Except.error error => Except.error error
  | Except.ok environment =>
      Except.ok (PsKernelCheckedDeclaration.mk request (psKernelV1Receipt session environment))

def psKernelV1AdmitDeclaration
    (session : PsKernelKernelSession)
    (request : PsKernelDeclarationRequest) : Except PsKernelError PsKernelAdmissionResult :=
  match psKernelV1CheckedEnvironment session request with
  | Except.error error => Except.error error
  | Except.ok environment =>
      Except.ok (PsKernelAdmissionResult.mk
        (PsKernelKernelSession.mk environment session.resources session.provider)
        (PsKernelCheckedDeclaration.mk request (psKernelV1Receipt session environment)))

def psKernelV1AdmitChecked
    (session : PsKernelKernelSession)
    (checked : PsKernelCheckedDeclaration) : Except PsKernelError PsKernelAdmissionResult :=
  psKernelV1AdmitDeclaration session checked.request

def psKernelV1CheckExpression
    (session : PsKernelKernelSession)
    (levelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety)
    (expression : PsKernelExpr) : Except PsKernelError PsKernelCheckedExpression :=
  match psKernelKernelSessionPreflight session with
  | Except.error error => Except.error error
  | Except.ok _ =>
      match psKernelSessionCheck session.resources.fuel
          (psKernelKernelSessionChecker session levelParams safety) expression with
      | Except.error message => Except.error (psKernelErrorFromMessage message)
      | Except.ok result =>
          Except.ok (PsKernelCheckedExpression.mk expression (Prod.fst result))

def psKernelV1Whnf
    (session : PsKernelKernelSession)
    (levelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety)
    (expression : PsKernelExpr) : Except PsKernelError PsKernelExpr :=
  match psKernelV1CheckExpression session levelParams safety expression with
  | Except.error error => Except.error error
  | Except.ok _ =>
      match psKernelSessionWhnf session.resources.fuel
          (psKernelKernelSessionChecker session levelParams safety) expression with
      | Except.error message => Except.error (psKernelErrorFromMessage message)
      | Except.ok result => Except.ok (Prod.fst result)

def psKernelV1IsDefEq
    (session : PsKernelKernelSession)
    (levelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety)
    (left : PsKernelExpr)
    (right : PsKernelExpr) : Except PsKernelError Bool :=
  match psKernelV1CheckExpression session levelParams safety left with
  | Except.error error => Except.error error
  | Except.ok _ =>
      match psKernelV1CheckExpression session levelParams safety right with
      | Except.error error => Except.error error
      | Except.ok _ =>
          match psKernelSessionIsDefEq session.resources.fuel
              (psKernelKernelSessionChecker session levelParams safety) left right with
          | Except.error message => Except.error (psKernelErrorFromMessage message)
          | Except.ok result => Except.ok (Prod.fst result)
