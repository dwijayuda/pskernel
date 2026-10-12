import Ps.Foundation.List
import Ps.CompilerIr.Model
import Ps.Core.Builtin
import Ps.Core.Subst
import Ps.Environment.Basic
import Ps.Environment.LocalContext
import Ps.Meta.Context
import Ps.Meta.Infer
import Ps.Meta.Inductive
import Ps.Meta.Reduce

-- Persistent collision buckets accelerate lookup without changing name equality
-- or first-entry precedence. They contain compiler data, never admission authority.
inductive PsErasureNameIndex (Value : Type) where
  | empty
  | bucket (entries : List (Prod PsName Value))
  | branch (left right : PsErasureNameIndex Value)

def psErasureIndexBucket (Value : Type) (fuel : Nat) :
    PsErasureNameIndex Value -> Nat -> List (Prod PsName Value) :=
  match fuel with
  | Nat.zero => fun (index : PsErasureNameIndex Value) (_hash : Nat) =>
      match index with
      | PsErasureNameIndex.bucket entries => entries
      | _ => List.nil
  | Nat.succ remaining =>
      fun (index : PsErasureNameIndex Value) (hash : Nat) =>
        let smaller : PsErasureNameIndex Value -> Nat -> List (Prod PsName Value) := psErasureIndexBucket Value remaining;
        match index with
        | PsErasureNameIndex.branch left right =>
            if Nat.beq (Nat.mod hash 2) 0 then smaller left (Nat.div hash 2)
            else smaller right (Nat.div hash 2)
        | _ => List.nil

def psErasureIndexSet (Value : Type) (fuel : Nat) :
    PsErasureNameIndex Value -> Nat -> List (Prod PsName Value) -> PsErasureNameIndex Value :=
  match fuel with
  | Nat.zero => fun (_index : PsErasureNameIndex Value) (_hash : Nat) (entries : List (Prod PsName Value)) =>
      PsErasureNameIndex.bucket entries
  | Nat.succ remaining =>
      fun (index : PsErasureNameIndex Value) (hash : Nat) (entries : List (Prod PsName Value)) =>
        let smaller : PsErasureNameIndex Value -> Nat -> List (Prod PsName Value) -> PsErasureNameIndex Value := psErasureIndexSet Value remaining;
        let left : PsErasureNameIndex Value := match index with
          | PsErasureNameIndex.branch value _ => value
          | _ => PsErasureNameIndex.empty;
        let right : PsErasureNameIndex Value := match index with
          | PsErasureNameIndex.branch _ value => value
          | _ => PsErasureNameIndex.empty;
        if Nat.beq (Nat.mod hash 2) 0 then PsErasureNameIndex.branch (smaller left (Nat.div hash 2) entries) right
        else PsErasureNameIndex.branch left (smaller right (Nat.div hash 2) entries)

def psErasureIndexFindInBucket (Value : Type) (entries : List (Prod PsName Value)) : PsName -> Option Value :=
  match entries with
  | List.nil => fun (_target : PsName) => Option.none
  | List.cons entry rest =>
      let smaller : PsName -> Option Value := psErasureIndexFindInBucket Value rest;
      fun (target : PsName) =>
        match entry with
        | Prod.mk key value => if psNameEq key target then Option.some value else smaller target

def psErasureIndexFind (Value : Type) (index : PsErasureNameIndex Value) (name : PsName) : Option Value :=
  psErasureIndexFindInBucket Value (psErasureIndexBucket Value 16 index (psEnvironmentNameHash name)) name

def psErasureIndexInsert (Value : Type) (index : PsErasureNameIndex Value) (name : PsName) (value : Value) : PsErasureNameIndex Value :=
  let hash := psEnvironmentNameHash name;
  psErasureIndexSet Value 16 index hash (List.cons (Prod.mk name value) (psErasureIndexBucket Value 16 index hash))

def psErasureIndexPrepend (Value : Type) (entries : List (Prod PsName Value)) : PsErasureNameIndex Value -> PsErasureNameIndex Value :=
  match entries with
  | List.nil => fun (tail : PsErasureNameIndex Value) => tail
  | List.cons entry rest =>
      let smaller : PsErasureNameIndex Value -> PsErasureNameIndex Value := psErasureIndexPrepend Value rest;
      fun (tail : PsErasureNameIndex Value) =>
        match entry with
        | Prod.mk name value => psErasureIndexInsert Value (smaller tail) name value

inductive PsErasedBinderKind where
  | type
  | proof
  | runtime

-- Flat declaration entries are distinct from canonical unary function values.
-- These slots describe the checked declaration before call-site substitution.
structure PsErasureEntryInfo where
  binders : List PsErasedBinderKind
  runtimeArity : Nat
  typeArity : Nat

structure PsErasureDeclarationNames where
  byCore : PsErasureNameIndex String
  byOutput : PsErasureNameIndex Bool
  count : Nat
  entries : PsErasureNameIndex PsErasureEntryInfo

def psErasureDeclarationNameIndex (entries : List (Prod PsName String)) : PsErasureDeclarationNames :=
  match entries with
  | List.nil => PsErasureDeclarationNames.mk PsErasureNameIndex.empty PsErasureNameIndex.empty 0 PsErasureNameIndex.empty
  | List.cons entry rest =>
      let tail := psErasureDeclarationNameIndex rest;
      match entry with
      | Prod.mk name value => PsErasureDeclarationNames.mk
          (psErasureIndexInsert String tail.byCore name value)
          (psErasureIndexInsert Bool tail.byOutput (PsName.str PsName.anonymous value) true)
          (Nat.succ tail.count)
          tail.entries

inductive PsErasureError where
  | fuelExhausted
  | binderMismatch
  | looseBoundVariable
  | unresolvedMetavariable
  | unknownLocal (id : Nat)
  | erasedLocalUsed (id : Nat)
  | unsupportedRuntimeTerm
  | inDeclaration (name : PsName) (cause : PsErasureError)
  | unsupportedApplication
  | unknownConstant (name : PsName)

structure PsRuntimeStructureField where
  sourceIndex : Nat
  projectionIndex : Nat
  name : String
  type : PsVerifiedIrType

structure PsRuntimeStructureInfo where
  name : String
  coreName : PsName
  constructorName : PsName
  numParams : Nat
  typeParameters : List PsVerifiedIrTypeParameter
  fields : List PsRuntimeStructureField
  numFields : Nat

structure PsRuntimeConstructorField where
  sourceIndex : Nat
  name : String
  type : PsVerifiedIrType
  recursive : Bool

structure PsRuntimeConstructorInfo where
  inductiveName : String
  name : String
  coreName : PsName
  numParams : Nat
  fields : List PsRuntimeConstructorField
  numFields : Nat

structure PsRuntimeInductiveInfo where
  name : String
  coreName : PsName
  recursorName : PsName
  numParams : Nat
  typeParameters : List PsVerifiedIrTypeParameter
  constructors : List PsRuntimeConstructorInfo
  numIndices : Nat := 0

-- Used by both partial-application completion and recursor lowering.
def psRuntimeRecursorArity (info : PsRuntimeInductiveInfo) : Nat :=
  info.numParams + 1 + info.constructors.length + info.numIndices + 1

structure PsErasureCurrentDefinition where
  name : String
  -- Only declaration binders contribute; restore their order at recursive calls.
  typeArgumentsRev : List PsVerifiedIrType
  runtimeParameters : List String

structure PsErasureScope where
  localContext : PsLocalContext
  runtimeLocals : List (Nat × String)
  typeLocals : List (Nat × String)
  erasedLocals : List Nat
  declarationNames : PsErasureDeclarationNames
  runtimeConstructors : PsErasureNameIndex PsRuntimeConstructorInfo
  runtimeRecursors : PsErasureNameIndex PsRuntimeInductiveInfo
  runtimeStructures : PsErasureNameIndex PsRuntimeStructureInfo
  runtimeStructureConstructors : PsErasureNameIndex PsRuntimeStructureInfo
  runtimeExpressions : List (Nat × PsVerifiedIrExpr)
  currentDefinition : Option PsErasureCurrentDefinition

def psErasureNatRecursor : PsRuntimeInductiveInfo :=
  PsRuntimeInductiveInfo.mk "Nat" psNatName psNatRecName 0 List.nil
    (List.cons
      (PsRuntimeConstructorInfo.mk "Nat" "zero" psNatZeroName 0 List.nil 0)
      (List.cons
        (PsRuntimeConstructorInfo.mk "Nat" "succ" psNatSuccName 0
          (List.cons (PsRuntimeConstructorField.mk 0 "predecessor" (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat) true) List.nil) 1)
        List.nil)) 0

def psErasureBoolRecursor : PsRuntimeInductiveInfo :=
  PsRuntimeInductiveInfo.mk "Bool" psBoolName (psNameAppendStr psBoolName "rec") 0 []
    [PsRuntimeConstructorInfo.mk "Bool" "false" psBoolFalseName 0 [] 0,
     PsRuntimeConstructorInfo.mk "Bool" "true" psBoolTrueName 0 [] 0] 0

def psErasureScopeEmpty
    (declarationNames : List (PsName × String)) :
    PsErasureScope :=
  {
    localContext := psLocalEmpty
    runtimeLocals := []
    typeLocals := []
    erasedLocals := []
    declarationNames := psErasureDeclarationNameIndex declarationNames
    runtimeConstructors := PsErasureNameIndex.empty
    runtimeRecursors := psErasureIndexInsert PsRuntimeInductiveInfo
      (psErasureIndexInsert PsRuntimeInductiveInfo PsErasureNameIndex.empty psNatRecName psErasureNatRecursor)
      (psNameAppendStr psBoolName "rec") psErasureBoolRecursor
    runtimeStructures := PsErasureNameIndex.empty
    runtimeStructureConstructors := PsErasureNameIndex.empty
    runtimeExpressions := []
    currentDefinition := Option.none
  }

def psErasureLookupRuntimeExpression
    (entries : List (Prod Nat PsVerifiedIrExpr)) :
    Nat -> Option PsVerifiedIrExpr :=
  match entries with
  | List.nil => fun (_target : Nat) => Option.none
  | List.cons entry rest =>
      let smaller : Nat -> Option PsVerifiedIrExpr := psErasureLookupRuntimeExpression rest;
      fun (target : Nat) =>
        match entry with
        | Prod.mk key value =>
            if Nat.beq key target then Option.some value
            else smaller target

def psErasureLookupNat
    (entries : List (Prod Nat String)) :
    Nat -> Option String :=
  match entries with
  | List.nil => fun (_target : Nat) => Option.none
  | List.cons entry rest =>
      let smaller : Nat -> Option String := psErasureLookupNat rest;
      fun (target : Nat) =>
        match entry with
        | Prod.mk key value =>
            if Nat.beq key target then Option.some value
            else smaller target

def psErasureLookupName (entries : PsErasureDeclarationNames) (name : PsName) : Option String :=
  psErasureIndexFind String entries.byCore name

def psErasureLookupEntry (entries : PsErasureDeclarationNames) (name : PsName) : Option PsErasureEntryInfo :=
  psErasureIndexFind PsErasureEntryInfo entries.entries name

def psErasureLookupStructure (entries : PsErasureNameIndex PsRuntimeStructureInfo) (name : PsName) : Option PsRuntimeStructureInfo :=
  psErasureIndexFind PsRuntimeStructureInfo entries name

def psErasureLookupConstructor (entries : PsErasureNameIndex PsRuntimeConstructorInfo) (name : PsName) : Option PsRuntimeConstructorInfo :=
  psErasureIndexFind PsRuntimeConstructorInfo entries name

def psErasureLookupRecursor (entries : PsErasureNameIndex PsRuntimeInductiveInfo) (name : PsName) : Option PsRuntimeInductiveInfo :=
  psErasureIndexFind PsRuntimeInductiveInfo entries name


def psErasureNatInList (values : List Nat) : Nat -> Bool :=
  match values with
  | List.nil => fun (_target : Nat) => false
  | List.cons value rest =>
      let smaller := psErasureNatInList rest;
      fun (target : Nat) =>
        if Nat.beq value target then true else smaller target


def psLevelNormalizesToZero (level : PsLevel) : Bool :=
  match level with
  | PsLevel.zero => true
  | PsLevel.succ _ => false
  | PsLevel.max left right =>
      if psLevelNormalizesToZero left then psLevelNormalizesToZero right else false
  | PsLevel.imax _ right => psLevelNormalizesToZero right
  | PsLevel.param _ => false
  | PsLevel.mvar _ => false

def psErasureNatNotEqual (left : Nat) (right : Nat) : Bool :=
  if Nat.beq left right then false else true


def psErasureIsProp
    (environment : PsEnvironment)
    (localContext : PsLocalContext)
    (expr : PsExpr) : Bool :=
  match
      psInferType
        environment
        psMetaEmpty
        localContext
        expr with
  | Except.error _ => false
  | Except.ok inferred =>
      match
          psWhnf
            environment
            psMetaEmpty
            localContext
            inferred with
      | .sortE level =>
          psLevelNormalizesToZero level
      | _ => false

-- A closed declaration whose result lies in Sort is a type family,
-- not an executable function. Open dependent binders before inspecting its
-- codomain; an ordinary polymorphic value (for example {A : Type} → A → A)
-- still has a value result and must remain in the runtime closure.
def psErasureIsTypeFamily (environment : PsEnvironment) (fuel : Nat)
    (localContext : PsLocalContext) (type : PsExpr) : Bool :=
  match fuel with
  | 0 => false
  | fuel + 1 =>
    match psWhnf environment psMetaEmpty localContext type with
    | .sortE _ => true
    | .forallE name domain body binder =>
      let pushed := psLocalPushBinding localContext name domain binder
      psErasureIsTypeFamily environment fuel pushed.context
        (psExprInstantiate1 body (.fvar pushed.id))
    | _ => false

def psErasureIsNonRuntimeDeclaration (environment : PsEnvironment)
    (type : PsExpr) : Bool :=
  psErasureIsProp environment psLocalEmpty type ||
    psErasureIsTypeFamily environment 4096 psLocalEmpty type

def psErasureClassifyBinder
    (environment : PsEnvironment)
    (localContext : PsLocalContext)
    (type : PsExpr) : PsErasedBinderKind :=
  match
      psWhnf
        environment
        psMetaEmpty
        localContext
        type with
  | .sortE level =>
      if psLevelNormalizesToZero level then
        PsErasedBinderKind.proof
      else
        PsErasedBinderKind.type
  | _ =>
      if psErasureIsProp environment localContext type then
        PsErasedBinderKind.proof
      else if psErasureIsTypeFamily environment 4096 localContext type then
        -- Higher-kinded type and predicate families (e.g. coll → idx → Prop)
        -- are compile-time indices, not runtime functions. Lean erases them.
        -- Unlike a function returning Nat/Bool, their codomain is a Sort.
        PsErasedBinderKind.type
      else
        PsErasedBinderKind.runtime

-- Mirror psEraseOpenDefinition's aligned raw forall/lambda prefix. In particular,
-- do not weak-head normalize the value or turn an instantiated result arrow into
-- another declaration parameter. Structure-recursor lowering preserves this prefix.
def psErasureEntryInfoWithFuel
    (environment : PsEnvironment) (fuel : Nat) :
    PsLocalContext -> PsExpr -> PsExpr -> Except PsErasureError PsErasureEntryInfo :=
  match fuel with
  | Nat.zero =>
      fun (_context : PsLocalContext) (_type : PsExpr) (_value : PsExpr) =>
        Except.error PsErasureError.fuelExhausted
  | Nat.succ remaining =>
      fun (context : PsLocalContext) (type : PsExpr) (value : PsExpr) =>
        match type with
        | PsExpr.forallE name domain typeBody binder =>
            match value with
            | PsExpr.lam _ _ valueBody _ =>
                -- Construct the smaller worker only when this prefix step is used.
                let smaller : PsLocalContext -> PsExpr -> PsExpr -> Except PsErasureError PsErasureEntryInfo :=
                  psErasureEntryInfoWithFuel environment remaining;
                let kind := psErasureClassifyBinder environment context domain;
                let pushed := psLocalPushBinding context name domain binder;
                let openedParameter := PsExpr.fvar pushed.id;
                -- Only the value's lambda spine is inspected. Replacing bound
                -- variables by fresh free variables cannot create or remove a lambda,
                -- so do not traverse the entire value body again for metadata.
                match smaller pushed.context
                    (psExprInstantiate1 typeBody openedParameter)
                    valueBody with
                | Except.error error => Except.error error
                | Except.ok tail =>
                    let runtimeArity : Nat :=
                      match kind with
                      | PsErasedBinderKind.runtime | PsErasedBinderKind.proof => Nat.succ tail.runtimeArity
                      | _ => tail.runtimeArity;
                    let typeArity : Nat :=
                      match kind with
                      | PsErasedBinderKind.type => Nat.succ tail.typeArity
                      | _ => tail.typeArity;
                    Except.ok
                      (PsErasureEntryInfo.mk
                        (List.cons kind tail.binders) runtimeArity typeArity)
            | _ => Except.ok (PsErasureEntryInfo.mk List.nil 0 0)
        | _ => Except.ok (PsErasureEntryInfo.mk List.nil 0 0)

def psErasureAddDeclarationEntry
    (environment : PsEnvironment) (name : PsName) (type value : PsExpr)
    (entries : PsErasureNameIndex PsErasureEntryInfo) :
    Except PsErasureError (PsErasureNameIndex PsErasureEntryInfo) :=
  -- The emitted declaration loop drops these definitions before opening binders.
  if psErasureIsNonRuntimeDeclaration environment type then Except.ok entries
  else
    match psErasureEntryInfoWithFuel environment 4096 psLocalEmpty type value with
    | Except.error error => Except.error error
    | Except.ok info =>
        Except.ok (psErasureIndexInsert PsErasureEntryInfo entries name info)

def psErasureDeclarationEntryIndex
    (environment : PsEnvironment) (declarations : List PsDeclaration) :
    Except PsErasureError (PsErasureNameIndex PsErasureEntryInfo) :=
  match declarations with
  | List.nil => Except.ok PsErasureNameIndex.empty
  | List.cons declaration rest =>
      match psErasureDeclarationEntryIndex environment rest with
      | Except.error error => Except.error error
      | Except.ok tail =>
          match declaration with
          | PsDeclaration.definitionDecl name _ type value =>
              psErasureAddDeclarationEntry environment name type value tail
          | PsDeclaration.partialDecl name _ type value
          | PsDeclaration.opaqueDecl name _ type value =>
              psErasureAddDeclarationEntry environment name type value tail
          | _ => Except.ok tail

def psErasurePrepareDeclarationEntries
    (environment : PsEnvironment) (declarations : List PsDeclaration)
    (scope : PsErasureScope) : Except PsErasureError PsErasureScope :=
  match psErasureDeclarationEntryIndex environment declarations with
  | Except.error error => Except.error error
  | Except.ok entries =>
      let names := PsErasureDeclarationNames.mk
        scope.declarationNames.byCore scope.declarationNames.byOutput
        scope.declarationNames.count entries;
      Except.ok
        (PsErasureScope.mk scope.localContext scope.runtimeLocals scope.typeLocals
          scope.erasedLocals names scope.runtimeConstructors scope.runtimeRecursors
          scope.runtimeStructures scope.runtimeStructureConstructors
          scope.runtimeExpressions scope.currentDefinition)

-- Semantic identifiers retain their original spelling. Code generation owns
-- target keywords, Unicode policy and collision-safe output names.
def psErasureSafeIdentifier (raw fallback : String) : String :=
  if raw.isEmpty then fallback else raw

def psErasureLocalNameUsed (scope : PsErasureScope) (candidate : String) : Bool :=
  let localUses : (Nat × String) -> Bool :=
    fun (entry : Nat × String) =>
      match entry with
      | Prod.mk _ value => psStringEq value candidate;
  if psListAny localUses scope.runtimeLocals then true
  else
    match psErasureIndexFind Bool scope.declarationNames.byOutput (PsName.str PsName.anonymous candidate) with
    | Option.some _ => true
    | Option.none => false

def psErasureLocalNameWithFuel
    (scope : PsErasureScope) (base : String) (fuel : Nat) (index : Nat) : String :=
  match fuel with
  | Nat.zero =>
      String.Internal.append base (String.Internal.append "$" (psNatToString index))
  | Nat.succ remaining =>
      let candidate := String.Internal.append base (String.Internal.append "$" (psNatToString index));
      if psErasureLocalNameUsed scope candidate then
        psErasureLocalNameWithFuel scope base remaining (Nat.succ index)
      else candidate

def psErasureLocalName (scope : PsErasureScope) (raw fallback : String) (id : Nat) : String :=
  let sanitized := psErasureSafeIdentifier raw fallback;
  let base := sanitized;
  let fuel := Nat.succ (Nat.add (psListLength scope.runtimeLocals) scope.declarationNames.count);
  if psStringEq base "_" then psErasureLocalNameWithFuel scope fallback fuel id
  else if psErasureLocalNameUsed scope base then psErasureLocalNameWithFuel scope base fuel id
  else base

def psErasureReserveOutputName (scope : PsErasureScope) (name : String) :
    PsErasureScope :=
  let names := PsErasureDeclarationNames.mk
    scope.declarationNames.byCore
    (psErasureIndexInsert Bool scope.declarationNames.byOutput
      (PsName.str PsName.anonymous name) true)
    (Nat.succ scope.declarationNames.count)
    scope.declarationNames.entries;
  PsErasureScope.mk scope.localContext scope.runtimeLocals scope.typeLocals
    scope.erasedLocals names scope.runtimeConstructors scope.runtimeRecursors
    scope.runtimeStructures scope.runtimeStructureConstructors
    scope.runtimeExpressions scope.currentDefinition

-- Proof data is erased, but computational functions retain an ignored Unit
-- slot at each proof binder. Dropping the slot could force a proof-guarded body
-- before its caller has supplied the proof (notably constrained recursor IHs).
def psErasureProofSlotType : PsVerifiedIrType :=
  .primitive .unit

def psErasureProofSlotValue : PsVerifiedIrExpr :=
  .literal .unit

-- Reserve the output name without exposing the proof as a computational local.
def psErasureOpenProofSlot (scope : PsErasureScope)
    (context : PsLocalContext) (id : Nat) :
    PsVerifiedIrParameter × PsErasureScope :=
  let name := psErasureLocalNameWithFuel scope "_psProof"
    (scope.runtimeLocals.length + scope.declarationNames.count + 1) id
  let reserved := psErasureReserveOutputName scope name
  (.mk name psErasureProofSlotType, { reserved with
    localContext := context
    erasedLocals := id :: scope.erasedLocals })

structure PsErasureAppView where
  head : PsExpr
  args : List PsExpr

def psErasureAppViewAcc (expr : PsExpr) : List PsExpr -> PsErasureAppView :=
  match expr with
  | PsExpr.app fn arg =>
      let smaller : List PsExpr -> PsErasureAppView := psErasureAppViewAcc fn;
      fun (args : List PsExpr) => smaller (List.cons arg args)
  | _ =>
      fun (args : List PsExpr) => PsErasureAppView.mk expr args

def psErasureAppView (expr : PsExpr) : PsErasureAppView :=
  psErasureAppViewAcc expr []

def psErasureExprListAtWorker
    (index : Nat) :
    List PsExpr -> Option PsExpr :=
  match index with
  | 0 =>
      fun (values : List PsExpr) =>
        match values with
        | [] => Option.none
        | value :: _ => Option.some value
  | nextIndex + 1 =>
      fun (values : List PsExpr) =>
        let smaller :
            List PsExpr -> Option PsExpr :=
          psErasureExprListAtWorker nextIndex;
        match values with
        | [] => Option.none
        | _ :: rest => smaller rest

def psErasureExprListAt
    (values : List PsExpr)
    (index : Nat) : Option PsExpr :=
  psErasureExprListAtWorker
    index
    values

def psErasurePrimitiveType
    (name : PsName) : Option PsVerifiedIrType :=
  if psNameEq name psNatName then
    Option.some
      (PsVerifiedIrType.primitive
        PsVerifiedIrPrimitiveType.nat)
  else if psNameEq name psIntName then
    Option.some
      (PsVerifiedIrType.primitive
        PsVerifiedIrPrimitiveType.int)
  else if psNameEq name psUInt8Name then
    Option.some
      (PsVerifiedIrType.primitive
        PsVerifiedIrPrimitiveType.uint8)
  else if psNameEq name psUInt16Name then
    Option.some
      (PsVerifiedIrType.primitive
        PsVerifiedIrPrimitiveType.uint16)
  else if psNameEq name psUInt32Name then
    Option.some
      (PsVerifiedIrType.primitive
        PsVerifiedIrPrimitiveType.uint32)
  else if psNameEq name psUInt64Name then
    Option.some
      (PsVerifiedIrType.primitive
        PsVerifiedIrPrimitiveType.uint64)
  else if psNameEq name psUSizeName then
    Option.some
      (PsVerifiedIrType.primitive
        PsVerifiedIrPrimitiveType.usize)
  else if psNameEq name psInt8Name then
    Option.some
      (PsVerifiedIrType.primitive
        PsVerifiedIrPrimitiveType.int8)
  else if psNameEq name psInt16Name then
    Option.some
      (PsVerifiedIrType.primitive
        PsVerifiedIrPrimitiveType.int16)
  else if psNameEq name psInt32Name then
    Option.some
      (PsVerifiedIrType.primitive
        PsVerifiedIrPrimitiveType.int32)
  else if psNameEq name psInt64Name then
    Option.some
      (PsVerifiedIrType.primitive
        PsVerifiedIrPrimitiveType.int64)
  else if psNameEq name psISizeName then
    Option.some
      (PsVerifiedIrType.primitive
        PsVerifiedIrPrimitiveType.isize)
  else if psNameEq name psFloatName then
    Option.some
      (PsVerifiedIrType.primitive
        PsVerifiedIrPrimitiveType.float)
  else if psNameEq name psFloat32Name then
    Option.some
      (PsVerifiedIrType.primitive
        PsVerifiedIrPrimitiveType.float32)
  else if psNameEq name psBoolName then
    Option.some
      (PsVerifiedIrType.primitive
        PsVerifiedIrPrimitiveType.bool)
  else if psNameEq name psCharName then
    Option.some
      (PsVerifiedIrType.primitive
        PsVerifiedIrPrimitiveType.char)
  else if psNameEq name psStringName then
    Option.some
      (PsVerifiedIrType.primitive
        PsVerifiedIrPrimitiveType.string)
  else if psNameEq name psUnitName then
    Option.some
      (PsVerifiedIrType.primitive
        PsVerifiedIrPrimitiveType.unit)
  else if psStringEq (psNameToString name) "String.Pos.Raw" then
    Option.some
      (PsVerifiedIrType.primitive
        PsVerifiedIrPrimitiveType.nat)
  else
    Option.none

def psErasureMapRuntimeTypes
    (erase : PsExpr -> Except PsErasureError PsVerifiedIrType)
    (values : List PsExpr) : Except PsErasureError (List PsVerifiedIrType) :=
  match values with
  | List.nil => Except.ok List.nil
  | List.cons value rest =>
      match erase value with
      | Except.error error => Except.error error
      | Except.ok result =>
          match psErasureMapRuntimeTypes erase rest with
          | Except.error error => Except.error error
          | Except.ok results => Except.ok (List.cons result results)


def psEraseRuntimeTypeWithFuelWorker
    (environment : PsEnvironment)
    (fuel : Nat) :
    PsErasureScope -> PsExpr -> Except PsErasureError PsVerifiedIrType :=
  match fuel with
  | Nat.zero =>
      fun (_scope : PsErasureScope) (_type : PsExpr) => Except.error PsErasureError.fuelExhausted
  | Nat.succ remaining =>
      fun (scope : PsErasureScope) (type : PsExpr) =>
        let smaller : PsErasureScope -> PsExpr -> Except PsErasureError PsVerifiedIrType :=
          psEraseRuntimeTypeWithFuelWorker environment remaining;
        let value :=
          psWhnf
            environment
            psMetaEmpty
            scope.localContext
            type;
        match value with
        | .fvar id =>
            match psErasureLookupNat scope.typeLocals id with
            | Option.some name =>
                Except.ok (PsVerifiedIrType.typeParameter name)
            | Option.none =>
                Except.ok PsVerifiedIrType.unknown
        | .constE name _ =>
            match psErasurePrimitiveType name with
            | Option.some primitive => Except.ok primitive
            | Option.none =>
                let outputName : String :=
                  match psErasureLookupName
                      scope.declarationNames
                      name with
                  | Option.some known => known
                  | Option.none =>
                      psErasureSafeIdentifier
                        (psNameToString name)
                        "Type";
                Except.ok
                  (PsVerifiedIrType.named outputName [])
        | .app _ _ =>
            let view := psErasureAppView value;
            match view.head with
            | .constE name _ =>
                if psNameEq name psDecidableName && view.args.length == 1 then
                  Except.ok (.primitive .bool)
                else
                  let outputName : String :=
                    match psErasureLookupName
                        scope.declarationNames
                        name with
                    | Option.some known => known
                    | Option.none =>
                        psErasureSafeIdentifier
                          (psNameToString name)
                          "Type";
                  -- Indexed families retain only uniform type parameters in the
                  -- runtime representation; constructor fields carry runtime data.
                  let arguments := match psEnvironmentFindInductive environment name with
                    | some info => view.args.take info.numParams
                    | none => view.args
                  match psErasureMapRuntimeTypes (smaller scope) arguments with
                  | Except.error error => Except.error error
                  | Except.ok arguments =>
                      Except.ok
                        (PsVerifiedIrType.named
                          outputName
                          arguments)
            | _ => Except.ok PsVerifiedIrType.unknown
        | .forallE name domain body binder =>
            match
                psErasureClassifyBinder
                  environment
                  scope.localContext
                  domain with
            | .runtime =>
                let pushed :=
                  psLocalPushBinding
                    scope.localContext
                    name
                    domain
                    binder;
                let runtimeName :=
                  psErasureSafeIdentifier
                    (psNameToString name)
                    "_arg";
                let nextScope : PsErasureScope := {
                  localContext := pushed.context
                  runtimeLocals :=
                    List.cons (Prod.mk pushed.id runtimeName) scope.runtimeLocals
                  typeLocals := scope.typeLocals
                  erasedLocals := scope.erasedLocals
                  declarationNames := scope.declarationNames
                  runtimeConstructors := scope.runtimeConstructors
                  runtimeRecursors := scope.runtimeRecursors
                  runtimeStructures := scope.runtimeStructures
                  runtimeStructureConstructors := scope.runtimeStructureConstructors
                  runtimeExpressions := []
                  currentDefinition := Option.none
                };
                match
                    smaller scope
                      domain with
                | Except.error error => Except.error error
                | Except.ok parameter =>
                    match
                        smaller nextScope
                          (psExprInstantiate1
                            body
                            (PsExpr.fvar pushed.id)) with
                    | Except.error error => Except.error error
                    | Except.ok result =>
                        -- Function values use unary groups, including beneath named
                        -- type arguments. This shape commutes with type substitution.
                        Except.ok
                          (PsVerifiedIrType.function
                            [parameter]
                            result)
            | .proof =>
                -- Retain the call boundary while erasing the proof payload.
                let pushed := psLocalPushBinding scope.localContext name domain binder
                let nextScope := { scope with
                  localContext := pushed.context
                  erasedLocals := pushed.id :: scope.erasedLocals
                  currentDefinition := none }
                match smaller nextScope (psExprInstantiate1 body (.fvar pushed.id)) with
                | .error error => .error error
                | .ok result => .ok (.function [psErasureProofSlotType] result)
            | .type =>
                Except.ok PsVerifiedIrType.unknown
        | _ =>
            Except.ok PsVerifiedIrType.unknown


def psEraseRuntimeTypeWithFuel
    (environment : PsEnvironment) (scope : PsErasureScope)
    (fuel : Nat) (type : PsExpr) : Except PsErasureError PsVerifiedIrType :=
  psEraseRuntimeTypeWithFuelWorker environment fuel scope type

def psEraseRuntimeType
    (environment : PsEnvironment)
    (scope : PsErasureScope)
    (type : PsExpr) :
    Except PsErasureError PsVerifiedIrType :=
  psEraseRuntimeTypeWithFuel environment scope 4096 type
