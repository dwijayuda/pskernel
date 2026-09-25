import PSC1Kernel.NestedInductive

namespace PSC1Kernel

namespace Replay

def pinnedLeanVersion : String := "4.34.0"

def pinnedLeanGitHash : String :=
  "293d5d0c0c3f3dded4688b3ccd6a33939ac5102b"

def supportedFormatVersion : String := "3.1.0"

structure Meta where
  leanVersion : String
  leanGitHash : String
  formatVersion : String

inductive NameNode where
  | str (parent : Nat) (value : String)
  | num (parent : Nat) (value : Nat)

structure NameRecord where
  index : Nat
  node : NameNode

inductive LevelNode where
  | succ (parent : Nat)
  | max (left right : Nat)
  | imax (left right : Nat)
  | param (name : Nat)

structure LevelRecord where
  index : Nat
  node : LevelNode

inductive ExprNode where
  | bvar (index : Nat)
  | sort (level : Nat)
  | const (name : Nat) (levels : List Nat)
  | app (fn arg : Nat)
  | lam (name type body : Nat) (binderInfo : BinderInfo)
  | forallE (name type body : Nat) (binderInfo : BinderInfo)
  | letE (name type value body : Nat) (nondep : Bool)
  | proj (typeName : Nat) (index : Nat) (struct : Nat)
  | natVal (value : Nat)
  | strVal (value : String)
  | mdata (metadata : Metadata) (expr : Nat)

structure ExprRecord where
  index : Nat
  node : ExprNode

structure AxiomRecord where
  name : Nat
  levelParams : List Nat
  type : Nat
  isUnsafe : Bool

structure DefinitionRecord where
  name : Nat
  levelParams : List Nat
  type : Nat
  value : Nat
  hints : ReducibilityHints
  safety : DefinitionSafety
  all : List Nat

structure TheoremRecord where
  name : Nat
  levelParams : List Nat
  type : Nat
  value : Nat

structure OpaqueRecord where
  name : Nat
  levelParams : List Nat
  type : Nat
  value : Nat
  isUnsafe : Bool

structure QuotRecord where
  name : Nat
  levelParams : List Nat
  type : Nat
  kind : QuotKind

structure ConstructorRecord where
  name : Nat
  type : Nat

structure InductiveTypeRecord where
  name : Nat
  type : Nat
  ctors : List ConstructorRecord

structure InductiveRecord where
  levelParams : List Nat
  numParams : Nat
  types : List InductiveTypeRecord
  isUnsafe : Bool
  numNested : Nat

inductive Record where
  | metaR (value : Meta)
  | nameR (value : NameRecord)
  | levelR (value : LevelRecord)
  | exprR (value : ExprRecord)
  | axiomR (value : AxiomRecord)
  | definitionR (value : DefinitionRecord)
  | theoremR (value : TheoremRecord)
  | opaqueR (value : OpaqueRecord)
  | quotR (value : QuotRecord)
  | inductiveR (value : InductiveRecord)

structure PendingMutual where
  all : List Name
  defs : List DefinitionInfo

structure State where
  env : Environment
  names : List (Nat × Name)
  levels : List (Nat × Level)
  exprs : List (Nat × Expr)
  sawMeta : Bool
  records : Nat
  declarations : Nat
  pendingMutual : List PendingMutual

def State.empty (env : Environment := .empty) : State :=
  {
    env := env
    names := [(0, .anonymous)]
    levels := [(0, .zero)]
    exprs := []
    sawMeta := false
    records := 0
    declarations := 0
    pendingMutual := []
  }

structure Stats where
  records : Nat
  names : Nat
  levels : Nat
  expressions : Nat
  declarations : Nat

def State.stats (state : State) : Stats :=
  {
    records := state.records
    names := if state.names.isEmpty then 0 else state.names.length - 1
    levels := if state.levels.isEmpty then 0 else state.levels.length - 1
    expressions := state.exprs.length
    declarations := state.declarations
  }

def lookupIndex? (index : Nat) : List (Nat × α) → Option α
  | [] => none
  | (i, value) :: rest =>
      if i == index then some value else lookupIndex? index rest

def hasIndex (index : Nat) (table : List (Nat × α)) : Bool :=
  (lookupIndex? index table).isSome

def addIndex
    (kind : String)
    (index : Nat)
    (value : α)
    (table : List (Nat × α)) : Except String (List (Nat × α)) :=
  if hasIndex index table then
    .error ("lean4export " ++ kind ++ " index is already defined")
  else
    .ok (table ++ [(index, value)])

def State.nameAt (state : State) (index : Nat) : Except String Name :=
  match lookupIndex? index state.names with
  | some value => .ok value
  | none => .error "lean4export Name reference is undefined"

def State.levelAt (state : State) (index : Nat) : Except String Level :=
  match lookupIndex? index state.levels with
  | some value => .ok value
  | none => .error "lean4export Level reference is undefined"

def State.exprAt (state : State) (index : Nat) : Except String Expr :=
  match lookupIndex? index state.exprs with
  | some value => .ok value
  | none => .error "lean4export Expr reference is undefined"

def resolveNames
    (state : State) : List Nat → Except String (List Name)
  | [] => pure []
  | index :: rest => do
      let value ← state.nameAt index
      let tail ← resolveNames state rest
      pure (value :: tail)

def resolveLevels
    (state : State) : List Nat → Except String (List Level)
  | [] => pure []
  | index :: rest => do
      let value ← state.levelAt index
      let tail ← resolveLevels state rest
      pure (value :: tail)

def namesEq : List Name → List Name → Bool
  | [], [] => true
  | a :: as, b :: bs =>
      Name.eq a b && namesEq as bs
  | _, _ => false

partial def exprUsesName (target : Name) : Expr → Bool
  | .const name _ => Name.eq target name
  | .app fn arg =>
      exprUsesName target fn || exprUsesName target arg
  | .lam _ type body _ | .forallE _ type body _ =>
      exprUsesName target type || exprUsesName target body
  | .letE _ type value body _ =>
      exprUsesName target type ||
        exprUsesName target value ||
        exprUsesName target body
  | .mdata _ body | .proj _ _ body => exprUsesName target body
  | .bvar _ | .fvar _ | .mvar _ | .sort _ | .lit _ => false

def State.addNameRecord
    (state : State)
    (record : NameRecord) : Except String State := do
  let value ←
    match record.node with
    | .str parent text =>
        pure (.str (← state.nameAt parent) text)
    | .num parent value =>
        pure (.num (← state.nameAt parent) value)
  let names ← addIndex "Name" record.index value state.names
  pure { state with names := names }

def State.addLevelRecord
    (state : State)
    (record : LevelRecord) : Except String State := do
  let value ←
    match record.node with
    | .succ parent =>
        pure (.succ (← state.levelAt parent))
    | .max left right =>
        pure (.max (← state.levelAt left) (← state.levelAt right))
    | .imax left right =>
        pure (.imax (← state.levelAt left) (← state.levelAt right))
    | .param name =>
        pure (.param (← state.nameAt name))
  let levels ← addIndex "Level" record.index value state.levels
  pure { state with levels := levels }

def State.addExprRecord
    (state : State)
    (record : ExprRecord) : Except String State := do
  let value ←
    match record.node with
    | .bvar index => pure (.bvar index)
    | .sort level => pure (.sort (← state.levelAt level))
    | .const name levels => do
        pure (.const (← state.nameAt name) (← resolveLevels state levels))
    | .app fn arg =>
        pure (.app (← state.exprAt fn) (← state.exprAt arg))
    | .lam name type body binderInfo =>
        pure (.lam
          (← state.nameAt name)
          (← state.exprAt type)
          (← state.exprAt body)
          binderInfo)
    | .forallE name type body binderInfo =>
        pure (.forallE
          (← state.nameAt name)
          (← state.exprAt type)
          (← state.exprAt body)
          binderInfo)
    | .letE name type value body nondep =>
        pure (.letE
          (← state.nameAt name)
          (← state.exprAt type)
          (← state.exprAt value)
          (← state.exprAt body)
          nondep)
    | .proj typeName index struct =>
        pure (.proj
          (← state.nameAt typeName)
          index
          (← state.exprAt struct))
    | .natVal value => pure (.lit (.nat value))
    | .strVal value => pure (.lit (.str value))
    | .mdata metadata expr =>
        pure (.mdata metadata (← state.exprAt expr))
  let exprs ← addIndex "Expr" record.index value state.exprs
  pure { state with exprs := exprs }

def findPending?
    (all : List Name) : List PendingMutual → Option PendingMutual
  | [] => none
  | group :: rest =>
      if namesEq group.all all then some group
      else findPending? all rest

def removePending
    (all : List Name) : List PendingMutual → List PendingMutual
  | [] => []
  | group :: rest =>
      if namesEq group.all all then rest
      else group :: removePending all rest

def definitionMember?
    (name : Name) : List DefinitionInfo → Option DefinitionInfo
  | [] => none
  | value :: rest =>
      if Name.eq value.base.name name then some value
      else definitionMember? name rest

def orderDefinitions
    (all : List Name)
    (defs : List DefinitionInfo) : Except String (List DefinitionInfo) := do
  let rec go : List Name → Except String (List DefinitionInfo)
    | [] => pure []
    | name :: rest => do
        let some value := definitionMember? name defs
          | throw "incomplete exported mutual definition group"
        let tail ← go rest
        pure (value :: tail)
  go all

def State.addDefinitionRecord
    (state : State)
    (record : DefinitionRecord) : Except String State := do
  let name ← state.nameAt record.name
  let levelParams ← resolveNames state record.levelParams
  let type ← state.exprAt record.type
  let value ← state.exprAt record.value
  let info : DefinitionInfo := {
    base := {
      name := name
      levelParams := levelParams
      type := type
    }
    value := value
    hints := record.hints
    safety := record.safety
  }
  let all ←
    if record.all.isEmpty then pure [name]
    else resolveNames state record.all
  let selfRef :=
    match record.safety with
    | .partialDef => exprUsesName name value
    | .safe | .unsafeDef => false
  if record.safety.isSafe || (all.length <= 1 && !selfRef) then
    let env ← Kernel.addDefinition state.env info
    pure { state with env := env }
  else
    unless Kernel.nameMember name all do
      throw "exported mutual definition is missing from its all-list"
    let previous :=
      (findPending? all state.pendingMutual).getD {
        all := all
        defs := []
      }
    if (definitionMember? name previous.defs).isSome then
      throw "duplicate exported mutual definition"
    let group := { previous with defs := previous.defs ++ [info] }
    let pending :=
      removePending all state.pendingMutual ++ [group]
    if group.defs.length == all.length then
      let ordered ← orderDefinitions all group.defs
      let env ← Kernel.addMutualDefinitions state.env ordered
      pure {
        state with
        env := env
        pendingMutual := removePending all pending
      }
    else
      pure { state with pendingMutual := pending }

def State.addInductiveRecord
    (state : State)
    (record : InductiveRecord) : Except String State := do
  if record.types.isEmpty then
    throw "empty exported inductive group"
  let levelParams ← resolveNames state record.levelParams

  let rec resolveCtors :
      List ConstructorRecord → Except String (List Kernel.SimpleConstructorDecl)
    | [] => pure []
    | ctor :: rest => do
        let name ← state.nameAt ctor.name
        let type ← state.exprAt ctor.type
        let tail ← resolveCtors rest
        pure ({ name := name, type := type } :: tail)

  let rec resolveTypes :
      List InductiveTypeRecord →
        Except String (List Kernel.SimpleMutualTypeDecl)
    | [] => pure []
    | type :: rest => do
        let name ← state.nameAt type.name
        let typeExpr ← state.exprAt type.type
        let ctors ← resolveCtors type.ctors
        let tail ← resolveTypes rest
        pure ({
          name := name
          type := typeExpr
          ctors := ctors
        } :: tail)

  let types ← resolveTypes record.types
  let env ←
    if record.numNested > 0 then
      Kernel.addSimpleNestedInductive state.env {
        levelParams := levelParams
        numParams := record.numParams
        types := types
        isUnsafe := record.isUnsafe
      }
    else
      match types with
      | [type] =>
          Kernel.addSimpleInductive state.env {
            levelParams := levelParams
            name := type.name
            type := type.type
            ctors := type.ctors
            isUnsafe := record.isUnsafe
            numParams := record.numParams
          }
      | _ =>
          Kernel.addSimpleMutualInductive state.env {
            levelParams := levelParams
            numParams := record.numParams
            types := types
            isUnsafe := record.isUnsafe
          }
  let rec verifyNested : List Kernel.SimpleMutualTypeDecl → Except String Unit
    | [] => pure ()
    | type :: rest => do
        let some (.inductInfo info) := env.find? type.name
          | throw "replayed inductive metadata is missing"
        unless info.numNested == record.numNested do
          throw "replayed inductive nested-count mismatch"
        verifyNested rest
  verifyNested types
  pure { state with env := env }

def State.addDeclaration
    (state : State)
    (record : Record) : Except String State := do
  match record with
  | .axiomR value => do
      let env ← Kernel.addAxiom state.env {
        base := {
          name := ← state.nameAt value.name
          levelParams := ← resolveNames state value.levelParams
          type := ← state.exprAt value.type
        }
        isUnsafe := value.isUnsafe
      }
      pure { state with env := env }
  | .definitionR value =>
      state.addDefinitionRecord value
  | .theoremR value => do
      let env ← Kernel.addTheorem state.env {
        base := {
          name := ← state.nameAt value.name
          levelParams := ← resolveNames state value.levelParams
          type := ← state.exprAt value.type
        }
        value := ← state.exprAt value.value
      }
      pure { state with env := env }
  | .opaqueR value => do
      let env ← Kernel.addOpaque state.env {
        base := {
          name := ← state.nameAt value.name
          levelParams := ← resolveNames state value.levelParams
          type := ← state.exprAt value.type
        }
        value := ← state.exprAt value.value
        isUnsafe := value.isUnsafe
      }
      pure { state with env := env }
  | .quotR value => do
      let env ←
        if state.env.quotInitialized then pure state.env
        else Kernel.addQuot state.env
      let name ← state.nameAt value.name
      let expectedLevels ← resolveNames state value.levelParams
      let expectedType ← state.exprAt value.type
      let some (.quotInfo got) := env.find? name
        | throw "exported Quot primitive is missing"
      unless Kernel.namesEq got.base.levelParams expectedLevels do
        throw "exported Quot universe metadata mismatch"
      unless Kernel.quotExprEqv got.base.type expectedType do
        throw "exported Quot type metadata mismatch"
      let kindOk :=
        match got.kind, value.kind with
        | .typeQ, .typeQ
        | .ctorQ, .ctorQ
        | .liftQ, .liftQ
        | .indQ, .indQ => true
        | _, _ => false
      unless kindOk do
        throw "exported Quot kind mismatch"
      pure { state with env := env }
  | .inductiveR value =>
      state.addInductiveRecord value
  | _ => throw "internal replay declaration dispatch error"

def State.replay
    (state : State)
    (record : Record) : Except String State := do
  match record with
  | .metaR value =>
      if state.records != 0 || state.sawMeta then
        throw "duplicate or non-initial lean4export metadata"
      unless value.leanVersion == pinnedLeanVersion do
        throw "lean4export Lean version does not match pinned 4.34.0"
      unless value.leanGitHash == pinnedLeanGitHash do
        throw "lean4export Lean git hash does not match pinned final 4.34 commit"
      unless value.formatVersion == supportedFormatVersion do
        throw "unsupported lean4export format"
      pure {
        state with
        sawMeta := true
        records := state.records + 1
      }
  | .nameR value => do
      unless state.sawMeta do
        throw "lean4export metadata must be the first record"
      let next ← state.addNameRecord value
      pure { next with records := state.records + 1 }
  | .levelR value => do
      unless state.sawMeta do
        throw "lean4export metadata must be the first record"
      let next ← state.addLevelRecord value
      pure { next with records := state.records + 1 }
  | .exprR value => do
      unless state.sawMeta do
        throw "lean4export metadata must be the first record"
      let next ← state.addExprRecord value
      pure { next with records := state.records + 1 }
  | .axiom _ | .definition _ | .theorem _ | .opaque _ |
      .quot _ | .inductive _ => do
      unless state.sawMeta do
        throw "lean4export metadata must be the first record"
      let next ← state.addDeclaration record
      pure {
        next with
        records := state.records + 1
        declarations := state.declarations + 1
      }

def State.finish (state : State) : Except String Stats := do
  unless state.sawMeta do
    throw "lean4export stream is missing initial metadata"
  unless state.pendingMutual.isEmpty do
    throw "incomplete exported mutual definition group"
  pure state.stats

def replayAll
    (initial : State)
    (records : List Record) : Except String State := do
  let rec go : State → List Record → Except String State
    | state, [] => pure state
    | state, record :: rest => do
        let next ← state.replay record
        go next rest
  let final ← go initial records
  let _ ← final.finish
  pure final

end Replay

end PSC1Kernel
