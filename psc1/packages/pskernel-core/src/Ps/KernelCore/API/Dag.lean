import Ps.KernelCore.API.Kernel
import Ps.KernelCore.API.DagDeclaration
import Ps.KernelCore.API.DagGenerated
import Ps.KernelCore.API.DagAdmission
import Ps.KernelCore.API.DagOrdinaryAdmission
import Ps.KernelCore.API.DagMutualAdmission
import Ps.KernelCore.Checker.ExprV2.Terminal
import Ps.KernelCore.Checker.ExprV2.Check
import Ps.KernelCore.Checker.ExprV2.Whnf
import Ps.KernelCore.Checker.ExprV2.DefEq

/-
Checked DAG ingress for the complete KernelContract-v1 implementation.

One call owns one untrusted graph and one ordered command batch. It replays
the graph once and decodes each node once, preserving physical sharing.
Supported inference, the ordered full-state DefEq pipeline, and WHNF rules read the canonical DAG
with the original entry fuel, depth and rule ordering. Local types and let
values are IDs in the same owner. Unsupported work restarts the complete
original operation with unchanged resources and without partial publication.

Axioms, safe/unsafe/partial definitions, theorems, opaque declarations and
supported unsafe/partial mutual definitions attempt direct admission. Original static guards read the boundary-decoded expressions;
header checking, inference-only proposition testing, body checking and terminal
comparison share one fresh DAG checking state with separate inference caches.
Mutual members use fresh private checking owners and publish the completed
batch atomically. Ordinary inductives use the complete private DAG header,
constructor, elimination and recursor validation path. Mutual inductives use
the complete private shared-header, constructor and recursor path. Nested
inductives and unsupported rules use complete original admission.
Successful ordinary admission carries its synchronized checked generated owner;
its recursor type and rules are not imported a second time. Other successful
admission records original same-batch type IDs and transparent
definition body IDs. This permits owning constant/projection inference and
delta unfolding without repeatedly importing environment types or bodies.

psKernelV1RunDag is the public untrusted-input boundary. The portable source
profile exposes constructors and helper functions: the internal command
workers require the canonical arena/decoded correspondence established here.
They are not alternative untrusted-input entry points. Replies, like V1
receipts, are forgeable observations and never authorize proof admission.
Each declaration is checked before environment publication. No semantic cache
or declaration index escapes the validated batch. A sealed constructor API
remains a source-profile limitation.

At each public call, existing admitted session metadata is adapted into fresh
private appended IDs before commands execute. The original input table remains
the external namespace. No declaration table or semantic cache crosses calls.
This remains a partial representation migration. Unsupported descendants and
remaining admission rules may restart through PsKernelExpr. The general
ordered DefEq pipeline itself has direct DAG implementations.
Eliminating that fallback and adapter remains required for completion.
-/
structure PsKernelDagBatchResult where
  session : PsKernelKernelSession
  replies : List PsKernelDagReply

/-
Internal state of one validated command batch. Its declaration references are
not accepted by psKernelV1RunDag and are not retained in its returned session.
Initialization derives the table from that same session's admitted environment;
only successful complete admission extends it afterward.
-/
structure PsKernelDagExecutionState where
  session : PsKernelKernelSession
  declarations : List PsKernelExprV2DeclarationRef

def psKernelDagRequire
    (built : PsKernelExprV2Decoded) (root : Nat) :
    Except PsKernelError PsKernelExpr :=
  match psKernelExprV2DecodedRequire built root with
  | Except.error error => Except.error (PsKernelError.rejectedInvalid error)
  | Except.ok expr => Except.ok expr

def psKernelDagCheckTerminalOrOriginal
    (session : PsKernelKernelSession)
    (levelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety)
    (arena : PsKernelExprV2PagedArena)
    (root : Nat) (expr : PsKernelExpr) :
    Except PsKernelError PsKernelCheckedExpression :=
  let checker := psKernelKernelSessionChecker session levelParams safety;
  match psKernelExprV2TryCheckTerminalWithFuel
      session.resources.fuel checker.context arena root with
  | Option.none => psKernelV1CheckExpression session levelParams safety expr
  | Option.some result =>
      match result with
      | Except.error error => Except.error (psKernelErrorFromMessage error)
      | Except.ok type =>
          Except.ok (PsKernelCheckedExpression.mk expr type)

def psKernelDagCheckExpression
    (session : PsKernelKernelSession)
    (levelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety)
    (arena : PsKernelExprV2PagedArena)
    (built : PsKernelExprV2Decoded)
    (declarations : List PsKernelExprV2DeclarationRef)
    (root : Nat) (expr : PsKernelExpr) :
    Except PsKernelError PsKernelCheckedExpression :=
  let checker := psKernelKernelSessionChecker session levelParams safety;
  match psKernelExprV2TryCheckWithDeclarationsFuel
      session.resources.fuel checker.context arena declarations root with
  | Option.none =>
      psKernelDagCheckTerminalOrOriginal session levelParams safety arena root expr
  | Option.some attempted =>
      match attempted with
      | Except.error error => Except.error (psKernelErrorFromMessage error)
      | Except.ok inferred =>
          let next := Prod.fst inferred;
          match psKernelExprV2DecodeCanonicalFuel
              (Nat.succ (Nat.sub next.size built.size)) next built built.size with
          | Except.error error => Except.error (psKernelErrorFromMessage error)
          | Except.ok extended =>
              match psKernelDagRequire extended (Prod.snd inferred) with
              | Except.error error => Except.error error
              | Except.ok type =>
                  Except.ok (PsKernelCheckedExpression.mk expr type)

def psKernelDagWhnfExpression
    (session : PsKernelKernelSession)
    (levelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety)
    (arena : PsKernelExprV2PagedArena)
    (built : PsKernelExprV2Decoded)
    (declarations : List PsKernelExprV2DeclarationRef)
    (root : Nat) (expr : PsKernelExpr) :
    Except PsKernelError PsKernelExpr :=
  match psKernelDagCheckExpression session levelParams safety arena built declarations root expr with
  | Except.error error => Except.error error
  | Except.ok _ =>
      let checker := psKernelKernelSessionChecker session levelParams safety;
      match psKernelExprV2TryWhnfOwnedWithDeclarationsFuel
          session.resources.fuel checker.context arena declarations root with
      | Option.some result =>
          match result with
          | Except.error error => Except.error (psKernelErrorFromMessage error)
          | Except.ok reduced =>
              let next := Prod.fst reduced;
              match psKernelExprV2DecodeCanonicalFuel
                  (Nat.succ (Nat.sub next.size built.size)) next built built.size with
              | Except.error error => Except.error (psKernelErrorFromMessage error)
              | Except.ok extended => psKernelDagRequire extended (Prod.snd reduced)
      | Option.none =>
          match psKernelSessionWhnf session.resources.fuel checker expr with
          | Except.error error => Except.error (psKernelErrorFromMessage error)
          | Except.ok result => Except.ok (Prod.fst result)

def psKernelDagIsDefEq
    (session : PsKernelKernelSession)
    (levelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety)
    (arena : PsKernelExprV2PagedArena)
    (built : PsKernelExprV2Decoded)
    (declarations : List PsKernelExprV2DeclarationRef)
    (left right : Nat) (a b : PsKernelExpr) :
    Except PsKernelError Bool :=
  match psKernelDagCheckExpression session levelParams safety arena built declarations left a with
  | Except.error error => Except.error error
  | Except.ok _ =>
      match psKernelDagCheckExpression session levelParams safety arena built declarations right b with
      | Except.error error => Except.error error
      | Except.ok _ =>
          let checker := psKernelKernelSessionChecker session levelParams safety;
          match psKernelExprV2TryDefEqWithDeclarationsFuel
              session.resources.fuel checker.context arena declarations left right with
          | Option.some attempted =>
              match attempted with
              | Except.error error => Except.error (psKernelErrorFromMessage error)
              | Except.ok value => Except.ok value
          | Option.none =>
              match psKernelSessionIsDefEq session.resources.fuel checker a b with
              | Except.error error => Except.error (psKernelErrorFromMessage error)
              | Except.ok result => Except.ok (Prod.fst result)

def psKernelDagRunCommandWithSource
    (input : PsKernelExprV2Decoded)
    (execution : PsKernelDagExecutionState)
    (levelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety)
    (arena : PsKernelExprV2PagedArena)
    (built : PsKernelExprV2Decoded)
    (command : PsKernelDagCommand) :
    Except PsKernelError (Prod PsKernelDagReply PsKernelDagExecutionState) :=
  let session := execution.session;
  match command with
  | PsKernelDagCommand.check root =>
      match psKernelDagRequire input root with
      | Except.error error => Except.error error
      | Except.ok expr =>
          match psKernelDagCheckExpression session levelParams safety arena built
              execution.declarations root expr with
          | Except.error error => Except.error error
          | Except.ok value =>
              Except.ok (Prod.mk (PsKernelDagReply.checked value) execution)
  | PsKernelDagCommand.whnf root =>
      match psKernelDagRequire input root with
      | Except.error error => Except.error error
      | Except.ok expr =>
          match psKernelDagWhnfExpression session levelParams safety arena built
              execution.declarations root expr with
          | Except.error error => Except.error error
          | Except.ok value =>
              Except.ok (Prod.mk (PsKernelDagReply.normalized value) execution)
  | PsKernelDagCommand.isDefEq left right =>
      match psKernelDagRequire input left with
      | Except.error error => Except.error error
      | Except.ok a =>
          match psKernelDagRequire input right with
          | Except.error error => Except.error error
          | Except.ok b =>
              match psKernelDagIsDefEq session levelParams safety arena built
                  execution.declarations left right a b with
              | Except.error error => Except.error error
              | Except.ok value =>
                  Except.ok (Prod.mk (PsKernelDagReply.equal value) execution)
  | PsKernelDagCommand.admit request =>
      match psKernelDagDecodeDeclaration input request with
      | Except.error error =>
          Except.error (PsKernelError.rejectedInvalid error)
      | Except.ok declaration =>
          match psKernelDagAdmitDeclaration session arena execution.declarations
              request declaration with
          | Except.error error => Except.error error
          | Except.ok result =>
              Except.ok
                (Prod.mk
                  (PsKernelDagReply.admitted result.declaration.receipt)
                  (PsKernelDagExecutionState.mk result.session
                    (psKernelDagDeclarationsAfterAdmission request execution.declarations)))

/- Compatibility worker: callers supplying a single table retain the original
   behavior. Production RunCommands keeps input and work namespaces separate. -/
def psKernelDagRunCommand
    (execution : PsKernelDagExecutionState)
    (levelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety)
    (arena : PsKernelExprV2PagedArena)
    (built : PsKernelExprV2Decoded)
    (command : PsKernelDagCommand) :
    Except PsKernelError (Prod PsKernelDagReply PsKernelDagExecutionState) :=
  psKernelDagRunCommandWithSource built execution levelParams safety arena built command

/- An owned command result is private to one validated batch. It carries the
   checked generated syntax forward without importing ordinary recursors again.
   No caller can supply this record to the public untrusted-input entry point. -/
structure PsKernelDagOwnedCommandResult where
  reply : PsKernelDagReply
  execution : PsKernelDagExecutionState
  owner : PsKernelDagGeneratedState

/- Existing complete original admission remains the fallback. Generated metadata
   is imported only after that admission succeeds, before any batch publication. -/
def psKernelDagRunFallbackOwnedCommandWithSource
    (input : PsKernelExprV2Decoded)
    (execution : PsKernelDagExecutionState)
    (levelParams : List PsKernelName) (safety : PsKernelDefinitionSafety)
    (arena : PsKernelExprV2PagedArena) (built : PsKernelExprV2Decoded)
    (command : PsKernelDagCommand) :
    Except PsKernelError PsKernelDagOwnedCommandResult :=
  match psKernelDagRunCommandWithSource input execution
      levelParams safety arena built command with
  | Except.error error => Except.error error
  | Except.ok result =>
      let nextExecution := Prod.snd result;
      let generated :=
        PsKernelDagGeneratedState.mk arena built nextExecution.declarations;
      match psKernelDagGeneratedAfterCommandWithPrevious command
          execution.session.environment nextExecution.session.environment generated with
      | Except.error error => Except.error (PsKernelError.internalError error)
      | Except.ok owner =>
          Except.ok
            (PsKernelDagOwnedCommandResult.mk (Prod.fst result)
              (PsKernelDagExecutionState.mk nextExecution.session owner.declarations) owner)

/- Resource and receipt publication follow the same complete-admission boundary
   as other declarations. The successful private owner contains the constructor
   and independently checked recursor references; no partial owner is returned
   on rejection. Native evaluator authority is cleared exactly as in V1. -/
def psKernelDagFinishOwnedOrdinaryAdmission
    (session : PsKernelKernelSession) (declaration : PsKernelDeclarationRequest)
    (checked : PsKernelExprV2OrdinaryAdmissionResult) :
    Except PsKernelError PsKernelDagOwnedCommandResult :=
  if psKernelResourceAllowsSize session.resources
      (psKernelEnvironmentSize checked.environment) then
    let environment :=
      psKernelEnvironmentWithNativeEvaluator checked.environment Option.none;
    let next :=
      PsKernelKernelSession.mk environment session.resources session.provider;
    let admitted :=
      PsKernelCheckedDeclaration.mk declaration (psKernelV1Receipt session environment);
    Except.ok
      (PsKernelDagOwnedCommandResult.mk
        (PsKernelDagReply.admitted admitted.receipt)
        (PsKernelDagExecutionState.mk next checked.owner.declarations) checked.owner)
  else
    Except.error
      (PsKernelError.resourceExhausted PsKernelResourceError.declarationLimit
        "declaration limit exceeded")

/- The injected worker is internal and receives the established canonical owner.
   It permits protocol proofs and controls for late failure/decline. Decline
   restarts the original request with the original session, arena, and input
   table; no intermediate ordinary environment or appended syntax is reused. -/
def psKernelDagRunOrdinaryOwnedWith
    (admit : PsKernelDagGeneratedState ->
      Option (Except String PsKernelExprV2OrdinaryAdmissionResult))
    (input : PsKernelExprV2Decoded)
    (execution : PsKernelDagExecutionState)
    (levelParams : List PsKernelName) (safety : PsKernelDefinitionSafety)
    (arena : PsKernelExprV2PagedArena) (built : PsKernelExprV2Decoded)
    (request : PsKernelDagDeclarationRequest)
    (declaration : PsKernelDeclarationRequest) :
    Except PsKernelError PsKernelDagOwnedCommandResult :=
  match psKernelKernelSessionPreflight execution.session with
  | Except.error error => Except.error error
  | Except.ok _ =>
      match admit (PsKernelDagGeneratedState.mk arena built execution.declarations) with
      | Option.none =>
          psKernelDagRunFallbackOwnedCommandWithSource input execution
            levelParams safety arena built (PsKernelDagCommand.admit request)
      | Option.some attempted =>
          match attempted with
          | Except.error error => Except.error (psKernelErrorFromMessage error)
          | Except.ok checked =>
              psKernelDagFinishOwnedOrdinaryAdmission execution.session declaration checked

/- Publish the four checked live Quot headers only after direct bootstrap
   validation and the unchanged public declaration limit succeed. Metadata
   import remains private and atomic; evaluator authority is cleared as in V1. -/
def psKernelDagFinishOwnedQuotAdmission
    (session : PsKernelKernelSession) (environment : PsKernelEnvironment)
    (prepared : PsKernelDagGeneratedState) :
    Except PsKernelError PsKernelDagOwnedCommandResult :=
  if psKernelResourceAllowsSize session.resources (psKernelEnvironmentSize environment) then
    let checked := psKernelEnvironmentWithNativeEvaluator environment Option.none;
    match psKernelDagGeneratedInstallQuotPlan (psKernelDagGeneratedPlanQuot checked) prepared with
    | Except.error error => Except.error (PsKernelError.internalError error)
    | Except.ok owner =>
        let next := PsKernelKernelSession.mk checked session.resources session.provider;
        Except.ok
          (PsKernelDagOwnedCommandResult.mk
            (PsKernelDagReply.admitted (psKernelV1Receipt session checked))
            (PsKernelDagExecutionState.mk next owner.declarations) owner)
  else
    Except.error
      (PsKernelError.resourceExhausted PsKernelResourceError.declarationLimit
        "declaration limit exceeded")

/- Internal injected callbacks expose owner/error/decline sequencing for native
   proofs. None restarts the exact original command and owner, discarding every
   prepared suffix. A hard rejection never invokes original admission. -/
def psKernelDagRunQuotOwnedWith
    (prepare : PsKernelEnvironment -> PsKernelDagGeneratedState ->
      Except String PsKernelDagGeneratedState)
    (admit : PsKernelEnvironment -> PsKernelExprV2PagedArena ->
      List PsKernelExprV2DeclarationRef -> Option (Except String PsKernelEnvironment))
    (input : PsKernelExprV2Decoded) (execution : PsKernelDagExecutionState)
    (levelParams : List PsKernelName) (safety : PsKernelDefinitionSafety)
    (arena : PsKernelExprV2PagedArena) (built : PsKernelExprV2Decoded) :
    Except PsKernelError PsKernelDagOwnedCommandResult :=
  match psKernelKernelSessionPreflight execution.session with
  | Except.error error => Except.error error
  | Except.ok _ =>
      let environment := psKernelKernelSessionEnvironment execution.session;
      match prepare environment (PsKernelDagGeneratedState.mk arena built execution.declarations) with
      | Except.error error => Except.error (PsKernelError.internalError error)
      | Except.ok prepared =>
          match admit environment prepared.arena prepared.declarations with
          | Option.none =>
              psKernelDagRunFallbackOwnedCommandWithSource input execution levelParams safety
                arena built (PsKernelDagCommand.admit PsKernelDagDeclarationRequest.quot)
          | Option.some attempted =>
              match attempted with
              | Except.error error => Except.error (psKernelErrorFromMessage error)
              | Except.ok checked =>
                  psKernelDagFinishOwnedQuotAdmission execution.session checked prepared

def psKernelDagRunOwnedCommandWithSource
    (input : PsKernelExprV2Decoded)
    (execution : PsKernelDagExecutionState)
    (levelParams : List PsKernelName) (safety : PsKernelDefinitionSafety)
    (arena : PsKernelExprV2PagedArena) (built : PsKernelExprV2Decoded)
    (command : PsKernelDagCommand) :
    Except PsKernelError PsKernelDagOwnedCommandResult :=
  match command with
  | PsKernelDagCommand.admit request =>
      match request with
      | PsKernelDagDeclarationRequest.ordinaryInductive levels numParams value isUnsafe =>
          match psKernelDagDecodeDeclaration input request with
          | Except.error error => Except.error (PsKernelError.rejectedInvalid error)
          | Except.ok declaration =>
              let admit :=
                fun (owner : PsKernelDagGeneratedState) =>
                  psKernelExprV2OrdinaryAdmitWithFuel execution.session.resources.fuel
                    (psKernelKernelSessionEnvironment execution.session)
                    execution.session.resources.maxRecDepth execution.session.resources.maxNatSize
                    input owner levels numParams value isUnsafe;
              psKernelDagRunOrdinaryOwnedWith admit input execution
                levelParams safety arena built request declaration
      | PsKernelDagDeclarationRequest.mutualInductive value =>
          match psKernelDagDecodeDeclaration input request with
          | Except.error error => Except.error (PsKernelError.rejectedInvalid error)
          | Except.ok declaration =>
              let admit :=
                fun (owner : PsKernelDagGeneratedState) =>
                  psKernelExprV2MutualAdmitWithFuel execution.session.resources.fuel
                    (psKernelKernelSessionEnvironment execution.session)
                    execution.session.resources.maxRecDepth execution.session.resources.maxNatSize
                    input owner value;
              psKernelDagRunOrdinaryOwnedWith admit input execution
                levelParams safety arena built request declaration
      | PsKernelDagDeclarationRequest.quot =>
          psKernelDagRunQuotOwnedWith psKernelDagGeneratedPrepareQuot psKernelDagTryAdmitQuot
            input execution levelParams safety arena built
      | _ =>
          psKernelDagRunFallbackOwnedCommandWithSource input execution
            levelParams safety arena built command
  | _ =>
      psKernelDagRunFallbackOwnedCommandWithSource input execution
        levelParams safety arena built command

def psKernelDagRunCommandsWithSource
    (commands : List PsKernelDagCommand) :
    PsKernelExprV2Decoded -> PsKernelDagExecutionState -> List PsKernelName ->
    PsKernelDefinitionSafety -> PsKernelExprV2PagedArena -> PsKernelExprV2Decoded ->
    Except PsKernelError PsKernelDagBatchResult :=
  match commands with
  | List.nil =>
      fun (_input : PsKernelExprV2Decoded)
          (execution : PsKernelDagExecutionState)
          (_levelParams : List PsKernelName)
          (_safety : PsKernelDefinitionSafety)
          (_arena : PsKernelExprV2PagedArena)
          (_built : PsKernelExprV2Decoded) =>
        Except.ok (PsKernelDagBatchResult.mk execution.session List.nil)
  | List.cons command rest =>
      fun (input : PsKernelExprV2Decoded)
          (execution : PsKernelDagExecutionState)
          (levelParams : List PsKernelName)
          (safety : PsKernelDefinitionSafety)
          (arena : PsKernelExprV2PagedArena)
          (built : PsKernelExprV2Decoded) =>
        match psKernelDagRunOwnedCommandWithSource input execution
            levelParams safety arena built command with
        | Except.error error => Except.error error
        | Except.ok result =>
            match psKernelDagGeneratedDemandRange
                result.execution.session.environment built.size result.owner with
            | Except.error error => Except.error (PsKernelError.internalError error)
            | Except.ok ready =>
                let owner := PsKernelDagExecutionState.mk
                  result.execution.session ready.declarations;
                let recur := psKernelDagRunCommandsWithSource rest;
                match recur input owner levelParams safety ready.arena ready.built with
                | Except.error error => Except.error error
                | Except.ok tail =>
                    Except.ok
                      (PsKernelDagBatchResult.mk tail.session
                        (List.cons result.reply tail.replies))

/- The input namespace is captured once. Appended generated nodes may be used
   internally but never become valid external command/declaration IDs. -/
def psKernelDagRunCommands
    (commands : List PsKernelDagCommand) :
    PsKernelDagExecutionState -> List PsKernelName ->
    PsKernelDefinitionSafety -> PsKernelExprV2PagedArena -> PsKernelExprV2Decoded ->
    Except PsKernelError PsKernelDagBatchResult :=
  fun (execution : PsKernelDagExecutionState)
      (levelParams : List PsKernelName) (safety : PsKernelDefinitionSafety)
      (arena : PsKernelExprV2PagedArena) (built : PsKernelExprV2Decoded) =>
    psKernelDagRunCommandsWithSource commands
      built execution levelParams safety arena built

/- The original decoded input remains the only external ID namespace.
   Imported metadata belongs solely to the new private working arena.
   The exact admitted session accompanies its derived index; every operation
   creates fresh semantic caches, including after an environment extension.
   Import or command failure returns before any session/reply publication. -/
def psKernelDagRunSessionCommands
    (session : PsKernelKernelSession)
    (levelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety)
    (arena : PsKernelExprV2PagedArena)
    (built : PsKernelExprV2Decoded)
    (commands : List PsKernelDagCommand) :
    Except PsKernelError PsKernelDagBatchResult :=
  match psKernelDagGeneratedFromSession session arena built with
  | Except.error error => Except.error (PsKernelError.internalError error)
  | Except.ok installed =>
      psKernelDagRunCommandsWithSource commands built
        (PsKernelDagExecutionState.mk session installed.declarations)
        levelParams safety installed.arena installed.built

def psKernelV1RunDag
    (session : PsKernelKernelSession)
    (levelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety)
    (source : PsKernelExprV2PagedArena)
    (commands : List PsKernelDagCommand) :
    Except PsKernelError PsKernelDagBatchResult :=
  match psKernelKernelSessionPreflight session with
  | Except.error error => Except.error error
  | Except.ok _ =>
      match psKernelExprV2PagedValidate source with
      | Except.error error =>
          Except.error (PsKernelError.rejectedInvalid error)
      | Except.ok canonical =>
          match psKernelExprV2DecodeCanonicalFuel
              (Nat.succ canonical.size) canonical psKernelExprV2DecodedEmpty 0 with
          | Except.error error =>
              Except.error (PsKernelError.rejectedInvalid error)
          | Except.ok built =>
              psKernelDagRunSessionCommands session levelParams safety
                canonical built commands
