import PSC1Kernel.ReplayJson
import Ps.KernelCore.API.Kernel

namespace PsKernelCoreArena

inductive Failure where
  | rejected (message : String)
  | declined (message : String)
  | resource (message : String)
  | internal (message : String)

def Failure.message : Failure -> String
  | .rejected message => message
  | .declined message => message
  | .resource message => message
  | .internal message => message

def Failure.exitCode : Failure -> UInt32
  | .rejected _ => 1
  | .declined _ => 2
  | .resource _ => 2
  | .internal _ => 3

def Failure.withContext (context : String) : Failure -> Failure
  | .rejected message => .rejected (context ++ message)
  | .declined message => .declined (context ++ message)
  | .resource message => .resource (context ++ message)
  | .internal message => .internal (context ++ message)

def fromKernelError : PsKernelError -> Failure
  | .rejectedInvalid message => .rejected message
  | .declinedUnsupported message => .declined message
  | .resourceExhausted _ message => .resource message
  | .internalError message => .internal message

def liftKernel (result : Except PsKernelError α) : Except Failure α :=
  match result with
  | .ok value => .ok value
  | .error error => .error (fromKernelError error)

def liftTransport (result : Except String α) : Except Failure α :=
  match result with
  | .ok value => .ok value
  | .error message => .error (.rejected message)

def coreName : PSC1Kernel.Name -> PsKernelName
  | .anonymous => .anonymous
  | .str parent value => .str (coreName parent) value
  | .num parent value => .num (coreName parent) value

def coreLevel : PSC1Kernel.Level -> PsKernelLevel
  | .zero => .zero
  | .succ level => .succ (coreLevel level)
  | .max left right => .max (coreLevel left) (coreLevel right)
  | .imax left right => .imax (coreLevel left) (coreLevel right)
  | .param name => .param (coreName name)
  | .mvar name => .mvar (coreName name)

def coreBinderInfo : PSC1Kernel.BinderInfo -> PsKernelBinderInfo
  | .default => .default
  | .implicit => .implicit
  | .strictImplicit => .strictImplicit
  | .instImplicit => .instImplicit

def coreLiteral : PSC1Kernel.Literal -> PsKernelLiteral
  | .nat value => .nat value
  | .str value => .str value

def coreExpr : PSC1Kernel.Expr -> PsKernelExpr
  | .bvar index => .bvar index
  | .fvar name => .fvar (coreName name)
  | .mvar name => .mvar (coreName name)
  | .sort level => .sort (coreLevel level)
  | .const name levels => .const (coreName name) (levels.map coreLevel)
  | .app fn arg => .app (coreExpr fn) (coreExpr arg)
  | .lam name type body binderInfo =>
      .lam (coreName name) (coreExpr type) (coreExpr body) (coreBinderInfo binderInfo)
  | .forallE name type body binderInfo =>
      .forallE (coreName name) (coreExpr type) (coreExpr body) (coreBinderInfo binderInfo)
  | .letE name type value body nondep =>
      .letE (coreName name) (coreExpr type) (coreExpr value) (coreExpr body) nondep
  | .lit value => .lit (coreLiteral value)
  | .mdata metadata expr => .mdata metadata (coreExpr expr)
  | .proj typeName index expr => .proj (coreName typeName) index (coreExpr expr)

def coreSafety : PSC1Kernel.DefinitionSafety -> PsKernelDefinitionSafety
  | .unsafeDef => .unsafeDef
  | .safe => .safe
  | .partialDef => .partialDef

def coreHints : PSC1Kernel.ReducibilityHints -> PsKernelReducibilityHints
  | .opaqueHint => .opaqueHint
  | .abbrevHint => .abbrevHint
  | .regular height => .regular height

def coreQuotKind : PSC1Kernel.QuotKind -> PsKernelQuotKind
  | .typeQ => .typeQ
  | .ctorQ => .ctorQ
  | .liftQ => .liftQ
  | .indQ => .indQ

def quotKindEq (left right : PsKernelQuotKind) : Bool :=
  match left, right with
  | .typeQ, .typeQ
  | .ctorQ, .ctorQ
  | .liftQ, .liftQ
  | .indQ, .indQ => true
  | _, _ => false

def nameListEq : List PsKernelName -> List PsKernelName -> Bool
  | [], [] => true
  | left :: leftRest, right :: rightRest =>
      psKernelNameEq left right && nameListEq leftRest rightRest
  | _, _ => false

partial def exprUsesName (target : PsKernelName) : PsKernelExpr -> Bool
  | .const name _ => psKernelNameEq target name
  | .app fn arg => exprUsesName target fn || exprUsesName target arg
  | .lam _ type body _ | .forallE _ type body _ =>
      exprUsesName target type || exprUsesName target body
  | .letE _ type value body _ =>
      exprUsesName target type || exprUsesName target value || exprUsesName target body
  | .mdata _ body | .proj _ _ body => exprUsesName target body
  | .bvar _ | .fvar _ | .mvar _ | .sort _ | .lit _ => false

structure PendingMutual where
  all : List PsKernelName
  defs : List PsKernelDefinitionInfo

def findPending? (all : List PsKernelName) : List PendingMutual -> Option PendingMutual
  | [] => none
  | group :: rest =>
      if nameListEq group.all all then some group else findPending? all rest

def removePending (all : List PsKernelName) : List PendingMutual -> List PendingMutual
  | [] => []
  | group :: rest =>
      if nameListEq group.all all then rest else group :: removePending all rest

def definitionMember?
    (name : PsKernelName) : List PsKernelDefinitionInfo -> Option PsKernelDefinitionInfo
  | [] => none
  | value :: rest =>
      if psKernelNameEq value.base.name name then some value else definitionMember? name rest

def orderDefinitions
    (all : List PsKernelName)
    (defs : List PsKernelDefinitionInfo) : Except Failure (List PsKernelDefinitionInfo) := do
  let rec go : List PsKernelName -> Except Failure (List PsKernelDefinitionInfo)
    | [] => pure []
    | name :: rest => do
        let some value := definitionMember? name defs
          | throw (.rejected "incomplete exported mutual definition group")
        let tail ← go rest
        pure (value :: tail)
  go all

def arenaResources : PsKernelResourcePolicy :=
  { psKernelResourcePolicyDefault with
    fuel := 262144
    maxDeclarations := 0 }

structure State where
  transport : PSC1Kernel.Replay.State
  session : PsKernelKernelSession
  sawMeta : Bool
  records : Nat
  declarations : Nat
  inputLeanVersion : String
  pendingMutual : List PendingMutual

def State.empty : Except Failure State := do
  let session ← liftKernel (psKernelKernelSessionEmpty arenaResources psKernelProviderDefault)
  pure {
    transport := PSC1Kernel.Replay.State.empty
    session := session
    sawMeta := false
    records := 0
    declarations := 0
    inputLeanVersion := ""
    pendingMutual := []
  }

def State.nameAt (state : State) (index : Nat) : Except Failure PsKernelName := do
  pure (coreName (← liftTransport (state.transport.nameAt index)))

def State.exprAt (state : State) (index : Nat) : Except Failure PsKernelExpr := do
  pure (coreExpr (← liftTransport (state.transport.exprAt index)))

def State.resolveNames (state : State) : List Nat -> Except Failure (List PsKernelName)
  | [] => pure []
  | index :: rest => do
      let name ← state.nameAt index
      let tail ← state.resolveNames rest
      pure (name :: tail)

def State.admitRequest
    (state : State)
    (request : PsKernelDeclarationRequest) : Except Failure State := do
  let result ← liftKernel (psKernelV1AdmitDeclaration state.session request)
  pure { state with session := result.session }

def State.addDefinitionRecord
    (state : State)
    (record : PSC1Kernel.Replay.DefinitionRecord) : Except Failure State := do
  let name ← state.nameAt record.name
  let levelParams ← state.resolveNames record.levelParams
  let type ← state.exprAt record.type
  let value ← state.exprAt record.value
  let info : PsKernelDefinitionInfo := {
    base := { name := name, levelParams := levelParams, type := type }
    value := value
    hints := coreHints record.hints
    safety := coreSafety record.safety
  }
  let all ←
    if record.all.isEmpty then pure [name]
    else state.resolveNames record.all
  let selfRef :=
    match info.safety with
    | .partialDef => exprUsesName name value
    | .safe | .unsafeDef => false
  if psKernelDefinitionSafetyIsSafe info.safety || (all.length <= 1 && !selfRef) then
    state.admitRequest (.definitionDecl info)
  else
    unless psKernelNameMember name all do
      throw (.rejected "exported mutual definition is missing from its all-list")
    let previous :=
      (findPending? all state.pendingMutual).getD { all := all, defs := [] }
    if (definitionMember? name previous.defs).isSome then
      throw (.rejected "duplicate exported mutual definition")
    let group := { previous with defs := previous.defs ++ [info] }
    let pending := removePending all state.pendingMutual ++ [group]
    if group.defs.length == all.length then
      let ordered ← orderDefinitions all group.defs
      let prepared := { state with pendingMutual := removePending all pending }
      let next ← prepared.admitRequest (.mutualDefinitions ordered)
      pure next
    else
      pure { state with pendingMutual := pending }

def State.resolveConstructors
    (state : State) :
    List PSC1Kernel.Replay.ConstructorRecord ->
      Except Failure (List PsKernelSimpleConstructorDecl)
  | [] => pure []
  | ctor :: rest => do
      let name ← state.nameAt ctor.name
      let type ← state.exprAt ctor.type
      let tail ← state.resolveConstructors rest
      pure ({ name := name, type := type } :: tail)

def State.resolveMutualTypes
    (state : State) :
    List PSC1Kernel.Replay.InductiveTypeRecord ->
      Except Failure (List PsKernelSimpleMutualTypeDecl)
  | [] => pure []
  | typeRecord :: rest => do
      let name ← state.nameAt typeRecord.name
      let type ← state.exprAt typeRecord.type
      let ctors ← state.resolveConstructors typeRecord.ctors
      let tail ← state.resolveMutualTypes rest
      pure ({ name := name, type := type, ctors := ctors } :: tail)

def State.addInductiveRecord
    (state : State)
    (record : PSC1Kernel.Replay.InductiveRecord) : Except Failure State := do
  if record.types.isEmpty then
    throw (.rejected "empty exported inductive group")
  let levelParams ← state.resolveNames record.levelParams
  let types ← state.resolveMutualTypes record.types
  if record.numNested > 0 then
    state.admitRequest (.nestedInductive {
      levelParams := levelParams
      numParams := record.numParams
      types := types
      isUnsafe := record.isUnsafe
    })
  else
    match types with
    | [typeRecord] =>
        state.admitRequest (.ordinaryInductive {
          levelParams := levelParams
          name := typeRecord.name
          type := typeRecord.type
          ctors := typeRecord.ctors
          isUnsafe := record.isUnsafe
          numParams := record.numParams
        })
    | _ =>
        state.admitRequest (.mutualInductive {
          levelParams := levelParams
          numParams := record.numParams
          types := types
          isUnsafe := record.isUnsafe
        })

def State.validateQuotRecord
    (state : State)
    (record : PSC1Kernel.Replay.QuotRecord) : Except Failure State := do
  let prepared ←
    if state.session.environment.quotInitialized then pure state
    else state.admitRequest .quot
  let name ← prepared.nameAt record.name
  let expectedLevels ← prepared.resolveNames record.levelParams
  let expectedType ← prepared.exprAt record.type
  let some (.quotInfo got) := psKernelEnvironmentFind prepared.session.environment name
    | throw (.rejected "exported Quot primitive is missing")
  unless nameListEq got.base.levelParams expectedLevels do
    throw (.rejected "exported Quot universe metadata mismatch")
  unless psKernelExprEq got.base.type expectedType do
    throw (.rejected "exported Quot type metadata mismatch")
  unless quotKindEq got.kind (coreQuotKind record.kind) do
    throw (.rejected "exported Quot kind mismatch")
  pure prepared

def State.addDeclaration
    (state : State)
    (record : PSC1Kernel.Replay.Record) : Except Failure State := do
  match record with
  | .axiomR value =>
      state.admitRequest (.axiomDecl {
        base := {
          name := ← state.nameAt value.name
          levelParams := ← state.resolveNames value.levelParams
          type := ← state.exprAt value.type
        }
        isUnsafe := value.isUnsafe
      })
  | .definitionR value =>
      state.addDefinitionRecord value
  | .theoremR value =>
      state.admitRequest (.theoremDecl {
        base := {
          name := ← state.nameAt value.name
          levelParams := ← state.resolveNames value.levelParams
          type := ← state.exprAt value.type
        }
        value := ← state.exprAt value.value
      })
  | .opaqueR value =>
      state.admitRequest (.opaqueDecl {
        base := {
          name := ← state.nameAt value.name
          levelParams := ← state.resolveNames value.levelParams
          type := ← state.exprAt value.type
        }
        value := ← state.exprAt value.value
        isUnsafe := value.isUnsafe
      })
  | .quotR value =>
      state.validateQuotRecord value
  | .inductiveR value =>
      state.addInductiveRecord value
  | _ =>
      throw (.internal "internal Arena declaration dispatch error")

def lean341Version : String := "4.34.1"
def lean341Commit : String := "5045d0056413266e57c625dcd7c365b10e377c52"

def State.acceptMeta
    (state : State)
    (value : PSC1Kernel.Replay.Meta) : Except Failure State := do
  if state.records != 0 || state.sawMeta then
    throw (.rejected "duplicate or non-initial lean4export metadata")
  unless value.formatVersion == PSC1Kernel.Replay.supportedFormatVersion do
    throw (.declined "unsupported lean4export format")
  let pinned434 :=
    value.leanVersion == PSC1Kernel.Replay.pinnedLeanVersion &&
      value.leanGitHash == PSC1Kernel.Replay.pinnedLeanGitHash
  let compatible341 :=
    value.leanVersion == lean341Version &&
      value.leanGitHash == lean341Commit
  unless pinned434 || compatible341 do
    throw (.declined "Lean version is outside the audited 4.34.0/4.34.1 Arena profile")
  pure {
    state with
    sawMeta := true
    records := state.records + 1
    inputLeanVersion := value.leanVersion
  }

def State.replayRecord
    (state : State)
    (record : PSC1Kernel.Replay.Record) : Except Failure State := do
  match record with
  | .metaR value =>
      state.acceptMeta value
  | .nameR value => do
      unless state.sawMeta do
        throw (.rejected "lean4export metadata must be the first record")
      let transport ← liftTransport (state.transport.addNameRecord value)
      pure { state with transport := transport, records := state.records + 1 }
  | .levelR value => do
      unless state.sawMeta do
        throw (.rejected "lean4export metadata must be the first record")
      let transport ← liftTransport (state.transport.addLevelRecord value)
      pure { state with transport := transport, records := state.records + 1 }
  | .exprR value => do
      unless state.sawMeta do
        throw (.rejected "lean4export metadata must be the first record")
      let transport ← liftTransport (state.transport.addExprRecord value)
      pure { state with transport := transport, records := state.records + 1 }
  | .axiomR _ | .definitionR _ | .theoremR _ | .opaqueR _ |
      .quotR _ | .inductiveR _ => do
      unless state.sawMeta do
        throw (.rejected "lean4export metadata must be the first record")
      let next ← state.addDeclaration record
      pure {
        next with
        records := state.records + 1
        declarations := state.declarations + 1
      }

def State.replayLine
    (state : State)
    (raw : String) : Except Failure State := do
  if raw.trimAscii.isEmpty then
    pure state
  else
    let record ← liftTransport (PSC1Kernel.ReplayJson.decodeLine raw)
    state.replayRecord record

structure Stats where
  records : Nat
  declarations : Nat
  constants : Nat
  leanVersion : String

def State.finish (state : State) : Except Failure Stats := do
  unless state.sawMeta do
    throw (.rejected "lean4export stream is missing initial metadata")
  unless state.pendingMutual.isEmpty do
    throw (.rejected "incomplete exported mutual definition group")
  pure {
    records := state.records
    declarations := state.declarations
    constants := psKernelEnvironmentSize state.session.environment
    leanVersion := state.inputLeanVersion
  }

end PsKernelCoreArena
