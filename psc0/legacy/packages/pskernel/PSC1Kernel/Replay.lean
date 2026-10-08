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
  levelParams : Option (List Nat) := none
  induct : Option Nat := none
  cidx : Option Nat := none
  numParams : Option Nat := none
  numFields : Option Nat := none
  isUnsafe : Option Bool := none

structure InductiveTypeRecord where
  name : Nat
  type : Nat
  ctors : List ConstructorRecord
  levelParams : Option (List Nat) := none
  numParams : Option Nat := none
  numIndices : Option Nat := none
  all : Option (List Nat) := none
  numNested : Option Nat := none
  isRec : Option Bool := none
  isReflexive : Option Bool := none
  isUnsafe : Option Bool := none

structure RecursorRuleRecord where
  ctor : Nat
  nFields : Nat
  rhs : Nat

structure RecursorRecord where
  name : Nat
  levelParams : List Nat
  type : Nat
  all : List Nat
  numParams : Nat
  numIndices : Nat
  numMotives : Nat
  numMinors : Nat
  rules : List RecursorRuleRecord
  k : Bool
  isUnsafe : Bool

structure InductiveRecord where
  levelParams : List Nat
  numParams : Nat
  types : List InductiveTypeRecord
  isUnsafe : Bool
  numNested : Nat
  recs : List RecursorRecord := []

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

def Record.declarationNameIndex? : Record → Option Nat
  | .axiomR value => some value.name
  | .definitionR value => some value.name
  | .theoremR value => some value.name
  | .opaqueR value => some value.name
  | .quotR value => some value.name
  | .inductiveR value =>
      match value.types with
      | first :: _ => some first.name
      | [] => none
  | _ => none

structure PendingMutual where
  all : List Name
  defs : List DefinitionInfo

structure IndexTable (α : Type) where
  dense : Array α
  sparse : List (Nat × α)
  count : Nat

def IndexTable.empty : IndexTable α :=
  { dense := #[], sparse := [], count := 0 }

def IndexTable.seed (values : Array α) : IndexTable α :=
  { dense := values, sparse := [], count := values.size }

def lookupSparse? (index : Nat) : List (Nat × α) → Option α
  | [] => none
  | (i, value) :: rest =>
      if i == index then some value else lookupSparse? index rest

def takeSparse?
    (index : Nat) : List (Nat × α) → Option (α × List (Nat × α))
  | [] => none
  | (i, value) :: rest =>
      if i == index then
        some (value, rest)
      else
        match takeSparse? index rest with
        | some (found, remaining) =>
            some (found, (i, value) :: remaining)
        | none => none

def IndexTable.get? (table : IndexTable α) (index : Nat) : Option α :=
  if index < table.dense.size then
    table.dense[index]?
  else
    lookupSparse? index table.sparse

partial def promoteIndexTable
    (dense : Array α)
    (sparse : List (Nat × α)) : Array α × List (Nat × α) :=
  match takeSparse? dense.size sparse with
  | some (value, rest) =>
      promoteIndexTable (dense.push value) rest
  | none => (dense, sparse)

def IndexTable.add
    (table : IndexTable α)
    (kind : String)
    (index : Nat)
    (value : α) : Except String (IndexTable α) :=
  if (table.get? index).isSome then
    .error ("lean4export " ++ kind ++ " index is already defined")
  else if index == table.dense.size then
    let (dense, sparse) :=
      promoteIndexTable (table.dense.push value) table.sparse
    .ok {
      dense := dense
      sparse := sparse
      count := table.count + 1
    }
  else
    .ok {
      dense := table.dense
      sparse := (index, value) :: table.sparse
      count := table.count + 1
    }

structure State where
  env : Environment
  maxRecDepth : Nat
  maxNatSize : Nat
  nativeEvaluator : Option NativeEvaluator
  names : IndexTable Name
  levels : IndexTable Level
  exprs : IndexTable Expr
  sawMeta : Bool
  records : Nat
  declarations : Nat
  pendingMutual : List PendingMutual

def State.empty
    (env : Environment := .empty)
    (maxRecDepth : Nat := 0)
    (maxNatSize : Nat := leanNatMaxSizeDefault)
    (nativeEvaluator : Option NativeEvaluator := none) : State :=
  {
    env := env
    maxRecDepth := maxRecDepth
    maxNatSize := maxNatSize
    nativeEvaluator := nativeEvaluator
    names := IndexTable.seed #[.anonymous]
    levels := IndexTable.seed #[.zero]
    exprs := IndexTable.empty
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
    names := state.names.count - 1
    levels := state.levels.count - 1
    expressions := state.exprs.count
    declarations := state.declarations
  }

def State.nameAt (state : State) (index : Nat) : Except String Name :=
  match state.names.get? index with
  | some value => .ok value
  | none => .error "lean4export Name reference is undefined"

def State.levelAt (state : State) (index : Nat) : Except String Level :=
  match state.levels.get? index with
  | some value => .ok value
  | none => .error "lean4export Level reference is undefined"

def State.exprAt (state : State) (index : Nat) : Except String Expr :=
  match state.exprs.get? index with
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

def replayNameString : Name → String
  | .anonymous => "_"
  | .str .anonymous value => value
  | .str parent value => replayNameString parent ++ "." ++ value
  | .num .anonymous value => toString value
  | .num parent value => replayNameString parent ++ "." ++ toString value

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
  let names ← state.names.add "Name" record.index value
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
  let levels ← state.levels.add "Level" record.index value
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
  let exprs ← state.exprs.add "Expr" record.index value
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
    let env ← Kernel.addDefinition state.env info state.maxRecDepth state.maxNatSize state.nativeEvaluator
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
      let env ← Kernel.addMutualDefinitions state.env ordered state.maxRecDepth state.maxNatSize state.nativeEvaluator
      pure {
        state with
        env := env
        pendingMutual := removePending all pending
      }
    else
      pure { state with pendingMutual := pending }

def replayLevelString : Level → String
  | .zero => "0"
  | .succ level => "succ(" ++ replayLevelString level ++ ")"
  | .max left right =>
      "max(" ++ replayLevelString left ++ "," ++ replayLevelString right ++ ")"
  | .imax left right =>
      "imax(" ++ replayLevelString left ++ "," ++ replayLevelString right ++ ")"
  | .param name => "param(" ++ replayNameString name ++ ")"
  | .mvar name => "mvar(" ++ replayNameString name ++ ")"

def replayLevelsString : List Level → String
  | [] => ""
  | [level] => replayLevelString level
  | level :: rest =>
      replayLevelString level ++ "," ++ replayLevelsString rest

def replayExprHead : Expr → String
  | .bvar index => "bvar(" ++ toString index ++ ")"
  | .fvar name => "fvar(" ++ replayNameString name ++ ")"
  | .mvar name => "mvar(" ++ replayNameString name ++ ")"
  | .sort level => "sort(" ++ replayLevelString level ++ ")"
  | .const name levels =>
      "const(" ++ replayNameString name ++ ";[" ++ replayLevelsString levels ++ "])"
  | .app _ _ => "app"
  | .lam _ _ _ _ => "lam"
  | .forallE _ _ _ _ => "forallE"
  | .letE _ _ _ _ _ => "letE"
  | .lit _ => "lit"
  | .mdata metadata _ => "mdata(" ++ toString metadata ++ ")"
  | .proj typeName index _ =>
      "proj(" ++ replayNameString typeName ++ "," ++ toString index ++ ")"

partial def replayExprDiffAt
    (path : String) : Expr → Expr → Option String
  | .bvar left, .bvar right =>
      if left == right then none
      else some (path ++ ": bvar " ++ toString left ++ " != " ++ toString right)
  | .fvar left, .fvar right =>
      if Name.eq left right then none
      else some (path ++ ": fvar " ++ replayNameString left ++
        " != " ++ replayNameString right)
  | .mvar left, .mvar right =>
      if Name.eq left right then none
      else some (path ++ ": mvar " ++ replayNameString left ++
        " != " ++ replayNameString right)
  | .sort left, .sort right =>
      if Level.eq left right then none
      else some (path ++ ": sort " ++ replayLevelString left ++
        " != " ++ replayLevelString right)
  | .const leftName leftLevels, .const rightName rightLevels =>
      if Name.eq leftName rightName && Level.listEq leftLevels rightLevels then none
      else some (path ++ ": " ++
        replayExprHead (.const leftName leftLevels) ++ " != " ++
        replayExprHead (.const rightName rightLevels))
  | .app leftFn leftArg, .app rightFn rightArg =>
      match replayExprDiffAt (path ++ ".fn") leftFn rightFn with
      | some diff => some diff
      | none => replayExprDiffAt (path ++ ".arg") leftArg rightArg
  | .lam _ leftType leftBody _, .lam _ rightType rightBody _ =>
      match replayExprDiffAt (path ++ ".lamType") leftType rightType with
      | some diff => some diff
      | none => replayExprDiffAt (path ++ ".lamBody") leftBody rightBody
  | .forallE _ leftType leftBody _, .forallE _ rightType rightBody _ =>
      match replayExprDiffAt (path ++ ".forallType") leftType rightType with
      | some diff => some diff
      | none => replayExprDiffAt (path ++ ".forallBody") leftBody rightBody
  | .letE _ leftType leftValue leftBody leftNondep,
      .letE _ rightType rightValue rightBody rightNondep =>
      if leftNondep != rightNondep then
        some (path ++ ": let nondep mismatch")
      else
        match replayExprDiffAt (path ++ ".letType") leftType rightType with
        | some diff => some diff
        | none =>
            match replayExprDiffAt (path ++ ".letValue") leftValue rightValue with
            | some diff => some diff
            | none => replayExprDiffAt (path ++ ".letBody") leftBody rightBody
  | .lit left, .lit right =>
      if Literal.eq left right then none else some (path ++ ": literal mismatch")
  | .mdata leftMeta leftExpr, .mdata rightMeta rightExpr =>
      if leftMeta != rightMeta then some (path ++ ": metadata mismatch")
      else replayExprDiffAt (path ++ ".mdata") leftExpr rightExpr
  | .proj leftName leftIndex leftExpr, .proj rightName rightIndex rightExpr =>
      if !Name.eq leftName rightName || leftIndex != rightIndex then
        some (path ++ ": projection metadata mismatch")
      else replayExprDiffAt (path ++ ".proj") leftExpr rightExpr
  | left, right =>
      some (path ++ ": node " ++ replayExprHead left ++
        " != " ++ replayExprHead right)

def replayExprDiff (left right : Expr) : String :=
  (replayExprDiffAt "root" left right).getD "no structural difference"

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
      } state.maxRecDepth state.maxNatSize state.nativeEvaluator
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
          } state.maxRecDepth state.maxNatSize state.nativeEvaluator
      | _ =>
          Kernel.addSimpleMutualInductive state.env {
            levelParams := levelParams
            numParams := record.numParams
            types := types
            isUnsafe := record.isUnsafe
          } state.maxRecDepth state.maxNatSize state.nativeEvaluator
  let rec resolveCtorNames :
      List ConstructorRecord → Except String (List Name)
    | [] => pure []
    | ctor :: rest => do
        let head ← state.nameAt ctor.name
        let tail ← resolveCtorNames rest
        pure (head :: tail)

  let rec verifyConstructors :
      List ConstructorRecord → Except String Unit
    | [] => pure ()
    | ctor :: rest => do
        let name ← state.nameAt ctor.name
        let expectedType ← state.exprAt ctor.type
        let some (.ctorInfo info) := env.find? name
          | throw "replayed constructor metadata is missing"
        unless Kernel.quotExprEqv info.base.type expectedType do
          throw "generated constructor type metadata mismatch"
        match ctor.levelParams with
        | some refs =>
            let expected ← resolveNames state refs
            unless namesEq info.base.levelParams expected do
              throw "generated constructor universe metadata mismatch"
        | none => pure ()
        match ctor.induct with
        | some ref =>
            unless Name.eq info.induct (← state.nameAt ref) do
              throw "generated constructor inductive metadata mismatch"
        | none => pure ()
        match ctor.cidx with
        | some expected =>
            unless info.cidx == expected do
              throw "generated constructor index metadata mismatch"
        | none => pure ()
        match ctor.numParams with
        | some expected =>
            unless info.numParams == expected do
              throw "generated constructor parameter metadata mismatch"
        | none => pure ()
        match ctor.numFields with
        | some expected =>
            unless info.numFields == expected do
              throw "generated constructor field metadata mismatch"
        | none => pure ()
        match ctor.isUnsafe with
        | some expected =>
            unless info.isUnsafe == expected do
              throw "generated constructor safety metadata mismatch"
        | none => pure ()
        verifyConstructors rest

  let rec verifyTypes :
      List InductiveTypeRecord → Except String Unit
    | [] => pure ()
    | type :: rest => do
        let name ← state.nameAt type.name
        let expectedType ← state.exprAt type.type
        let some (.inductInfo info) := env.find? name
          | throw "replayed inductive metadata is missing"
        unless Kernel.quotExprEqv info.base.type expectedType do
          throw "generated inductive type metadata mismatch"
        unless info.numNested == record.numNested do
          throw "replayed inductive nested-count mismatch"
        let expectedCtors ← resolveCtorNames type.ctors
        unless namesEq info.ctors expectedCtors do
          throw "generated inductive constructor-list mismatch"
        match type.levelParams with
        | some refs =>
            let expected ← resolveNames state refs
            unless namesEq info.base.levelParams expected do
              throw "generated inductive universe metadata mismatch"
        | none => pure ()
        match type.numParams with
        | some expected =>
            unless info.numParams == expected do
              throw "generated inductive parameter metadata mismatch"
        | none => pure ()
        match type.numIndices with
        | some expected =>
            unless info.numIndices == expected do
              throw "generated inductive index metadata mismatch"
        | none => pure ()
        match type.all with
        | some refs =>
            let expected ← resolveNames state refs
            unless namesEq info.all expected do
              throw "generated inductive all-list mismatch"
        | none => pure ()
        match type.numNested with
        | some expected =>
            unless info.numNested == expected do
              throw "generated inductive nested metadata mismatch"
        | none => pure ()
        match type.isRec with
        | some expected =>
            unless info.isRec == expected do
              throw "generated inductive recursion metadata mismatch"
        | none => pure ()
        match type.isReflexive with
        | some expected =>
            unless info.isReflexive == expected do
              throw "generated inductive reflexivity metadata mismatch"
        | none => pure ()
        match type.isUnsafe with
        | some expected =>
            unless info.isUnsafe == expected do
              throw "generated inductive safety metadata mismatch"
        | none => pure ()
        verifyConstructors type.ctors
        verifyTypes rest

  let rec verifyRules :
      List RecursorRule → List RecursorRuleRecord → Except String Unit
    | [], [] => pure ()
    | got :: gotRest, expected :: expectedRest => do
        let expectedCtor ← state.nameAt expected.ctor
        let expectedRhs ← state.exprAt expected.rhs
        unless Name.eq got.ctor expectedCtor do
          throw "generated recursor rule constructor mismatch"
        unless got.nFields == expected.nFields do
          throw "generated recursor rule field-count mismatch"
        unless Kernel.quotExprEqv got.rhs expectedRhs do
          throw "generated recursor rule rhs mismatch"
        verifyRules gotRest expectedRest
    | _, _ =>
        throw "generated recursor rule-count mismatch"

  let rec verifyRecursors :
      List RecursorRecord → Except String Unit
    | [] => pure ()
    | recursor :: rest => do
        let name ← state.nameAt recursor.name
        let some (.recInfo info) := env.find? name
          | throw "replayed recursor metadata is missing"
        let expectedLevels ← resolveNames state recursor.levelParams
        let expectedType ← state.exprAt recursor.type
        let expectedAll ← resolveNames state recursor.all
        unless namesEq info.base.levelParams expectedLevels do
          throw "generated recursor universe metadata mismatch"
        unless Kernel.quotExprEqv info.base.type expectedType do
          throw ("generated recursor type metadata mismatch for " ++
            replayNameString name ++
            " (name-index=" ++ toString recursor.name ++ "): " ++
            replayExprDiff info.base.type expectedType)
        unless namesEq info.all expectedAll do
          throw "generated recursor all-list mismatch"
        unless info.numParams == recursor.numParams do
          throw "generated recursor parameter metadata mismatch"
        unless info.numIndices == recursor.numIndices do
          throw "generated recursor index metadata mismatch"
        unless info.numMotives == recursor.numMotives do
          throw "generated recursor motive metadata mismatch"
        unless info.numMinors == recursor.numMinors do
          throw "generated recursor minor metadata mismatch"
        unless info.k == recursor.k do
          throw "generated recursor K metadata mismatch"
        unless info.isUnsafe == recursor.isUnsafe do
          throw "generated recursor safety metadata mismatch"
        verifyRules info.rules recursor.rules
        verifyRecursors rest

  verifyTypes record.types
  verifyRecursors record.recs
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
      } state.maxRecDepth state.maxNatSize state.nativeEvaluator
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
      } state.maxRecDepth state.maxNatSize state.nativeEvaluator
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
      } state.maxRecDepth state.maxNatSize state.nativeEvaluator
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
  | .axiomR _ | .definitionR _ | .theoremR _ | .opaqueR _ |
      .quotR _ | .inductiveR _ => do
      unless state.sawMeta do
        throw "lean4export metadata must be the first record"
      let label ←
        match record.declarationNameIndex? with
        | some index =>
            match state.nameAt index with
            | .ok name => pure (replayNameString name)
            | .error _ => pure ("name#" ++ toString index)
        | none => pure "<anonymous declaration>"
      let next ←
        match state.addDeclaration record with
        | .ok value => pure value
        | .error err =>
            throw ("declaration " ++ label ++ ": " ++ err)
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
