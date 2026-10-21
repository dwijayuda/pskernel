import Ps.KernelCore.API.Kernel
import Ps.KernelCore.API.DagDeclaration
import Ps.KernelCore.Checker.ExprV2.Terminal
import Ps.KernelCore.Checker.ExprV2.Check
import Ps.KernelCore.Checker.ExprV2.Whnf
import Ps.KernelCore.Checker.ExprV2.DefEq

/-
Checked DAG ingress for the complete KernelContract-v1 implementation.

One call owns one untrusted graph and one ordered command batch. It replays
the graph once and decodes each node once, preserving physical sharing.
Sort/literal/binder/let/constant/application/projection checking and terminal/metadata/beta/zeta/Nat/projection WHNF read DAG nodes directly with the original entry
fuel/depth/rule ordering. Operation-owned core/public caches preserve function-position normalization,
constructor projections and the complete Nat post-core pipeline; no cache escapes a public WHNF call.
Successful admission records same-batch type IDs and transparent definition body IDs,
allowing direct constant inference, universe substitution and delta without importing
an environment type or body. The index never escapes
its validated batch; declarations already in an external session remain fallback. Collision-safe DAG equality, sort universe equality, literals and paired metadata supply
DefEq's definitive quick rules only after both complete checks. Unsupported checking, reductions, DefEq
and admission use the complete existing kernel with unchanged resources.

psKernelV1RunDag is the public untrusted-input boundary. The portable source
profile exposes constructors and helper functions: the internal command
workers require the canonical arena/decoded correspondence established here.
They are not alternative untrusted-input entry points. Replies, like V1
receipts, are forgeable observations and never authorize proof admission.
Every declaration is still rechecked by V1. No equality memo survives this
boundary. A sealed constructor API remains a source-profile limitation.

This is a partial representation migration. Checked lets use owning local
type/value IDs, scope-restored success pairs and the original fixed DefEq
budget. Supported checking and WHNF rules are DAG-native. Applications requiring
general DefEq, external constant types, projections without owning constructor
types, unsupported reductions, general DefEq and admission retain PsKernelExpr
internally. Eliminating that fallback and adapter remains required for completion.
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
      match psKernelExprV2TryWhnfWithDeclarationsFuel
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
          match psKernelExprV2TryQuickDefEqWithFuel
              session.resources.fuel checker.context arena left right with
          | Option.some attempted =>
              match attempted with
              | Except.error error => Except.error (psKernelErrorFromMessage error)
              | Except.ok value => Except.ok value
          | Option.none =>
              match psKernelSessionIsDefEq session.resources.fuel checker a b with
              | Except.error error => Except.error (psKernelErrorFromMessage error)
              | Except.ok result => Except.ok (Prod.fst result)

def psKernelDagRunCommand
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
      match psKernelDagRequire built root with
      | Except.error error => Except.error error
      | Except.ok expr =>
          match psKernelDagCheckExpression session levelParams safety arena built
              execution.declarations root expr with
          | Except.error error => Except.error error
          | Except.ok value =>
              Except.ok (Prod.mk (PsKernelDagReply.checked value) execution)
  | PsKernelDagCommand.whnf root =>
      match psKernelDagRequire built root with
      | Except.error error => Except.error error
      | Except.ok expr =>
          match psKernelDagWhnfExpression session levelParams safety arena built
              execution.declarations root expr with
          | Except.error error => Except.error error
          | Except.ok value =>
              Except.ok (Prod.mk (PsKernelDagReply.normalized value) execution)
  | PsKernelDagCommand.isDefEq left right =>
      match psKernelDagRequire built left with
      | Except.error error => Except.error error
      | Except.ok a =>
          match psKernelDagRequire built right with
          | Except.error error => Except.error error
          | Except.ok b =>
              match psKernelDagIsDefEq session levelParams safety arena built
                  execution.declarations left right a b with
              | Except.error error => Except.error error
              | Except.ok value =>
                  Except.ok (Prod.mk (PsKernelDagReply.equal value) execution)
  | PsKernelDagCommand.admit request =>
      match psKernelDagDecodeDeclaration built request with
      | Except.error error =>
          Except.error (PsKernelError.rejectedInvalid error)
      | Except.ok declaration =>
          match psKernelV1AdmitDeclaration session declaration with
          | Except.error error => Except.error error
          | Except.ok result =>
              Except.ok
                (Prod.mk
                  (PsKernelDagReply.admitted result.declaration.receipt)
                  (PsKernelDagExecutionState.mk result.session
                    (psKernelDagDeclarationsAfterAdmission request execution.declarations)))

def psKernelDagRunCommands
    (commands : List PsKernelDagCommand) :
    PsKernelDagExecutionState -> List PsKernelName ->
    PsKernelDefinitionSafety -> PsKernelExprV2PagedArena -> PsKernelExprV2Decoded ->
    Except PsKernelError PsKernelDagBatchResult :=
  match commands with
  | List.nil =>
      fun (execution : PsKernelDagExecutionState)
          (_levelParams : List PsKernelName)
          (_safety : PsKernelDefinitionSafety)
          (_arena : PsKernelExprV2PagedArena)
          (_built : PsKernelExprV2Decoded) =>
        Except.ok (PsKernelDagBatchResult.mk execution.session List.nil)
  | List.cons command rest =>
      let smaller := psKernelDagRunCommands rest;
      fun (execution : PsKernelDagExecutionState)
          (levelParams : List PsKernelName)
          (safety : PsKernelDefinitionSafety)
          (arena : PsKernelExprV2PagedArena)
          (built : PsKernelExprV2Decoded) =>
        match psKernelDagRunCommand execution levelParams safety arena built command with
        | Except.error error => Except.error error
        | Except.ok result =>
            match smaller (Prod.snd result) levelParams safety arena built with
            | Except.error error => Except.error error
            | Except.ok tail =>
                Except.ok
                  (PsKernelDagBatchResult.mk tail.session
                    (List.cons (Prod.fst result) tail.replies))

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
