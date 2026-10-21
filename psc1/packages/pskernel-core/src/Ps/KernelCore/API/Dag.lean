import Ps.KernelCore.API.Kernel
import Ps.KernelCore.API.DagDeclaration
import Ps.KernelCore.API.DagGenerated
import Ps.KernelCore.API.DagAdmission
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
batch atomically. With a complete command owner, quotient bootstrap checks the
owned Eq/refl syntax and constructs all four headers directly in the DAG. Its
appended nodes are decoded only for legacy environment publication; the old
standalone admission/command ABIs retain explicit Quot compatibility fallback.
Inductives and unsupported rules use complete original admission.
Successful admission records original same-batch type IDs and transparent
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

This remains a partial representation migration. External constant types,
projections without owning constructor types, unowned recursor descendants
and remaining admission rules may restart through PsKernelExpr. The general
ordered DefEq pipeline itself has direct DAG implementations.
Eliminating that fallback and adapter remains required for completion.
-/
structure PsKernelDagBatchResult where
  session : PsKernelKernelSession
  replies : List PsKernelDagReply

/-
Internal state of one validated command batch. Its declaration references are
not accepted by psKernelV1RunDag and are not retained in its returned session.
Only successful complete admission extends the table.
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

structure PsKernelDagCommandWithOwnerResult where
  reply : PsKernelDagReply
  execution : PsKernelDagExecutionState
  owner : Option PsKernelDagGeneratedState

def psKernelDagRunCommandWithOwner
    (input : PsKernelExprV2Decoded)
    (execution : PsKernelDagExecutionState)
    (levelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety)
    (arena : PsKernelExprV2PagedArena)
    (built : PsKernelExprV2Decoded)
    (command : PsKernelDagCommand)
    (owner : Option PsKernelDagGeneratedState) :
    Except PsKernelError PsKernelDagCommandWithOwnerResult :=
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
              Except.ok (PsKernelDagCommandWithOwnerResult.mk
                (PsKernelDagReply.checked value) execution owner)
  | PsKernelDagCommand.whnf root =>
      match psKernelDagRequire input root with
      | Except.error error => Except.error error
      | Except.ok expr =>
          match psKernelDagWhnfExpression session levelParams safety arena built
              execution.declarations root expr with
          | Except.error error => Except.error error
          | Except.ok value =>
              Except.ok (PsKernelDagCommandWithOwnerResult.mk
                (PsKernelDagReply.normalized value) execution owner)
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
                  Except.ok (PsKernelDagCommandWithOwnerResult.mk
                    (PsKernelDagReply.equal value) execution owner)
  | PsKernelDagCommand.admit request =>
      match psKernelDagDecodeDeclaration input request with
      | Except.error error =>
          Except.error (PsKernelError.rejectedInvalid error)
      | Except.ok declaration =>
          match psKernelDagAdmitDeclarationWithOwner session arena execution.declarations
              request declaration owner with
          | Except.error error => Except.error error
          | Except.ok result =>
              let admitted := result.admission;
              let declarations : List PsKernelExprV2DeclarationRef :=
                match result.owner with
                | Option.none =>
                    psKernelDagDeclarationsAfterAdmission request execution.declarations
                | Option.some generated =>
                    psKernelDagDeclarationsAfterAdmission request generated.declarations;
              let nextOwner : Option PsKernelDagGeneratedState :=
                match result.owner with
                | Option.none => Option.none
                | Option.some generated =>
                    Option.some (PsKernelDagGeneratedState.mk
                      generated.arena generated.built declarations);
              Except.ok
                (PsKernelDagCommandWithOwnerResult.mk
                  (PsKernelDagReply.admitted admitted.declaration.receipt)
                  (PsKernelDagExecutionState.mk admitted.session declarations)
                  nextOwner)

/- The legacy command ABI cannot return an appended arena/work table. It uses
   the common engine without an owned admission carrier, retaining the previous
   environment-only Quot fallback and never returning inaccessible new IDs. -/
def psKernelDagRunCommandWithSource
    (input : PsKernelExprV2Decoded)
    (execution : PsKernelDagExecutionState)
    (levelParams : List PsKernelName)
    (safety : PsKernelDefinitionSafety)
    (arena : PsKernelExprV2PagedArena)
    (built : PsKernelExprV2Decoded)
    (command : PsKernelDagCommand) :
    Except PsKernelError (Prod PsKernelDagReply PsKernelDagExecutionState) :=
  match psKernelDagRunCommandWithOwner input execution levelParams safety
      arena built command Option.none with
  | Except.error error => Except.error error
  | Except.ok result => Except.ok (Prod.mk result.reply result.execution)

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

/- Lift the historical environment-only command ABI into the shared batch loop.
   This adapter appends nothing: its original arena/work table remains usable. -/
def psKernelDagRunCommandLegacyWithOwner
    (input : PsKernelExprV2Decoded) (execution : PsKernelDagExecutionState)
    (levelParams : List PsKernelName) (safety : PsKernelDefinitionSafety)
    (arena : PsKernelExprV2PagedArena) (built : PsKernelExprV2Decoded)
    (command : PsKernelDagCommand) :
    Except PsKernelError PsKernelDagCommandWithOwnerResult :=
  match psKernelDagRunCommandWithSource input execution levelParams safety
      arena built command with
  | Except.error error => Except.error error
  | Except.ok result =>
      let next := Prod.snd result;
      Except.ok (PsKernelDagCommandWithOwnerResult.mk (Prod.fst result) next
        (Option.some (PsKernelDagGeneratedState.mk arena built next.declarations)))

def psKernelDagRunCommandOwnedWithSource
    (input : PsKernelExprV2Decoded) (execution : PsKernelDagExecutionState)
    (levelParams : List PsKernelName) (safety : PsKernelDefinitionSafety)
    (arena : PsKernelExprV2PagedArena) (built : PsKernelExprV2Decoded)
    (command : PsKernelDagCommand) :
    Except PsKernelError PsKernelDagCommandWithOwnerResult :=
  let owner := PsKernelDagGeneratedState.mk arena built execution.declarations;
  psKernelDagRunCommandWithOwner input execution levelParams safety
    arena built command (Option.some owner)

/- One ordered batch loop serves both ABI boundaries. The original input table
   stays fixed; the callback returns the complete private command owner. -/
def psKernelDagRunCommandsUsing
    (commands : List PsKernelDagCommand) :
    (PsKernelExprV2Decoded -> PsKernelDagExecutionState -> List PsKernelName ->
      PsKernelDefinitionSafety -> PsKernelExprV2PagedArena -> PsKernelExprV2Decoded ->
      PsKernelDagCommand -> Except PsKernelError PsKernelDagCommandWithOwnerResult) ->
    PsKernelExprV2Decoded -> PsKernelDagExecutionState -> List PsKernelName ->
    PsKernelDefinitionSafety -> PsKernelExprV2PagedArena -> PsKernelExprV2Decoded ->
    Except PsKernelError PsKernelDagBatchResult :=
  match commands with
  | List.nil =>
      fun (_runCommand : PsKernelExprV2Decoded -> PsKernelDagExecutionState ->
          List PsKernelName -> PsKernelDefinitionSafety -> PsKernelExprV2PagedArena ->
          PsKernelExprV2Decoded -> PsKernelDagCommand ->
          Except PsKernelError PsKernelDagCommandWithOwnerResult)
          (_input : PsKernelExprV2Decoded)
          (execution : PsKernelDagExecutionState)
          (_levelParams : List PsKernelName)
          (_safety : PsKernelDefinitionSafety)
          (_arena : PsKernelExprV2PagedArena)
          (_built : PsKernelExprV2Decoded) =>
        Except.ok (PsKernelDagBatchResult.mk execution.session List.nil)
  | List.cons command rest =>
      fun (runCommand : PsKernelExprV2Decoded -> PsKernelDagExecutionState ->
          List PsKernelName -> PsKernelDefinitionSafety -> PsKernelExprV2PagedArena ->
          PsKernelExprV2Decoded -> PsKernelDagCommand ->
          Except PsKernelError PsKernelDagCommandWithOwnerResult)
          (input : PsKernelExprV2Decoded)
          (execution : PsKernelDagExecutionState)
          (levelParams : List PsKernelName)
          (safety : PsKernelDefinitionSafety)
          (arena : PsKernelExprV2PagedArena)
          (built : PsKernelExprV2Decoded) =>
        match runCommand input execution levelParams safety arena built command with
        | Except.error error => Except.error error
        | Except.ok result =>
            let nextExecution := result.execution;
            match result.owner with
            | Option.none =>
                Except.error (PsKernelError.internalError "PSKERNEL_V2_COMMAND_OWNER_LOST")
            | Option.some generated =>
                match psKernelDagGeneratedAfterCommandWithPrevious command
                    execution.session.environment nextExecution.session.environment generated with
                | Except.error error => Except.error (PsKernelError.internalError error)
                | Except.ok installed =>
                    let owner := PsKernelDagExecutionState.mk
                      nextExecution.session installed.declarations;
                    let recur := psKernelDagRunCommandsUsing rest;
                    match recur runCommand input owner levelParams safety
                        installed.arena installed.built with
                    | Except.error error => Except.error error
                    | Except.ok tail =>
                        Except.ok
                          (PsKernelDagBatchResult.mk tail.session
                            (List.cons result.reply tail.replies))

/- Historical source/work compatibility entry. Its theorem/API contract is
   retained; production uses the owned entry below. The outer List match keeps
   the established staged generated ABI. -/
def psKernelDagRunCommandsWithSource
    (commands : List PsKernelDagCommand) :
    PsKernelExprV2Decoded -> PsKernelDagExecutionState -> List PsKernelName ->
    PsKernelDefinitionSafety -> PsKernelExprV2PagedArena -> PsKernelExprV2Decoded ->
    Except PsKernelError PsKernelDagBatchResult :=
  match commands with
  | List.nil =>
      fun (input : PsKernelExprV2Decoded) (execution : PsKernelDagExecutionState)
          (levelParams : List PsKernelName) (safety : PsKernelDefinitionSafety)
          (arena : PsKernelExprV2PagedArena) (built : PsKernelExprV2Decoded) =>
        let run := psKernelDagRunCommandsUsing List.nil;
        run psKernelDagRunCommandLegacyWithOwner input execution levelParams safety arena built
  | List.cons command rest =>
      fun (input : PsKernelExprV2Decoded) (execution : PsKernelDagExecutionState)
          (levelParams : List PsKernelName) (safety : PsKernelDefinitionSafety)
          (arena : PsKernelExprV2PagedArena) (built : PsKernelExprV2Decoded) =>
        let run := psKernelDagRunCommandsUsing (List.cons command rest);
        run psKernelDagRunCommandLegacyWithOwner input execution levelParams safety arena built

def psKernelDagRunCommandsOwnedWithSource
    (commands : List PsKernelDagCommand) :
    PsKernelExprV2Decoded -> PsKernelDagExecutionState -> List PsKernelName ->
    PsKernelDefinitionSafety -> PsKernelExprV2PagedArena -> PsKernelExprV2Decoded ->
    Except PsKernelError PsKernelDagBatchResult :=
  match commands with
  | List.nil =>
      fun (input : PsKernelExprV2Decoded) (execution : PsKernelDagExecutionState)
          (levelParams : List PsKernelName) (safety : PsKernelDefinitionSafety)
          (arena : PsKernelExprV2PagedArena) (built : PsKernelExprV2Decoded) =>
        let run := psKernelDagRunCommandsUsing List.nil;
        run psKernelDagRunCommandOwnedWithSource input execution levelParams safety arena built
  | List.cons command rest =>
      fun (input : PsKernelExprV2Decoded) (execution : PsKernelDagExecutionState)
          (levelParams : List PsKernelName) (safety : PsKernelDefinitionSafety)
          (arena : PsKernelExprV2PagedArena) (built : PsKernelExprV2Decoded) =>
        let run := psKernelDagRunCommandsUsing (List.cons command rest);
        run psKernelDagRunCommandOwnedWithSource input execution levelParams safety arena built

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
    psKernelDagRunCommandsOwnedWithSource commands
      built execution levelParams safety arena built

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
              psKernelDagRunCommands commands
                (PsKernelDagExecutionState.mk session List.nil)
                levelParams safety canonical built
