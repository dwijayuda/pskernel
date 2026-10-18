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
import Ps.Meta.Recursor

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

-- Roles are determined by the checked Core telescope, not source syntax.
-- Erased dependent type indices are NOT reifiable runtime generic types.
inductive PsErasedBinderKind where
  | type
  | index
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
  -- IR-only support identities are reserved separately from checked Core names.
  supportNames : List (String × String) := []

def psErasureDeclarationNameIndex (entries : List (Prod PsName String)) : PsErasureDeclarationNames :=
  match entries with
  | List.nil => { byCore := .empty, byOutput := .empty, count := 0, entries := .empty }
  | List.cons entry rest =>
      let tail := psErasureDeclarationNameIndex rest;
      match entry with
      | Prod.mk name value => { tail with
          byCore := psErasureIndexInsert String tail.byCore name value
          byOutput := psErasureIndexInsert Bool tail.byOutput (PsName.str PsName.anonymous value) true
          count := tail.count + 1 }

inductive PsErasureError where
  | fuelExhausted
  | binderMismatch
  | looseBoundVariable
  | unresolvedMetavariable
  | unknownLocal (id : Nat)
  | erasedLocalUsed (id : Nat)
  | unsupportedRuntimeTerm
  | missingTargetWordSize
  | inDeclaration (name : PsName) (cause : PsErasureError)
  | unsupportedApplication
  | unknownConstant (name : PsName)
  | noncomputableDependency (name : PsName)

def psErasureNoncomputableDependency? : PsErasureError → Option PsName
  | .noncomputableDependency name => some name
  | .inDeclaration _ error => psErasureNoncomputableDependency? error
  | _ => none

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
  sourceTypeIndices : List Nat
  fields : List PsRuntimeStructureField
  numFields : Nat
  -- A one-field family whose erased type-former parameter determines its field
  -- is represented by that field at each concrete use, never by an unknown IR type.
  unboxed : Bool := false

structure PsRuntimeConstructorField where
  sourceIndex : Nat
  name : String
  type : PsVerifiedIrType
  recursive : Bool
  recursiveTarget : Option PsName := none

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
  sourceTypeIndices : List Nat := []
  group : Option PsInductiveGroupPlan := none
  elimination : Option (PsInductiveEliminationPlan × Nat) := none

def psRuntimeRecursorMotives (info : PsRuntimeInductiveInfo) : Nat :=
  match info.elimination with
  | some (plan, _) => plan.slots.length
  | none => info.group.map (fun group => group.members.length) |>.getD 1

def psRuntimeRecursorMinors (info : PsRuntimeInductiveInfo) : Nat :=
  match info.elimination with
  | some (plan, _) => psInductiveEliminationNumMinors plan
  | none => info.group.map psInductiveGroupNumMinors |>.getD info.constructors.length

def psRuntimeRecursorMinorOffset (info : PsRuntimeInductiveInfo) : Option Nat :=
  match info.elimination with
  | some (plan, index) => psInductiveEliminationMinorOffset plan index
  | none =>
    match info.group with
    | none => some 0
    | some group => psInductiveGroupMinorOffset group info.coreName

-- Used by both partial-application completion and recursor lowering.
def psRuntimeRecursorArity (info : PsRuntimeInductiveInfo) : Nat :=
  info.numParams + psRuntimeRecursorMotives info + psRuntimeRecursorMinors info + info.numIndices + 1

structure PsErasureCurrentDefinition where
  name : String
  -- Only declaration binders contribute; restore their order at recursive calls.
  typeArgumentsRev : List PsVerifiedIrType
  runtimeParameters : List String
  coreName : Option PsName := none
  coreParametersRev : List PsExpr := []

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
  -- Immutable execution profile, separate from the abstract logical environment.
  targetWordSize : Option PsVerifiedIrWordSize := none
  recursorWorkerGroups : List PsRecursorWorkerGroup := []

-- Resolve target-dependent representations once, before strict IR validation.
-- This never changes a Core type, opaque value, or kernel reduction rule.
def psErasureTargetWordSize (scope : PsErasureScope) :
    Except PsErasureError PsVerifiedIrWordSize :=
  match scope.targetWordSize with
  | some size => .ok size
  | none => .error .missingTargetWordSize

def psErasureResolveWord (scope : PsErasureScope)
    (word : PsVerifiedIrMachineIntegerType) :
    Except PsErasureError PsVerifiedIrMachineIntegerType := do
  match word with
  | .usize => return match ← psErasureTargetWordSize scope with
      | .bits32 => .uint32 | .bits64 => .uint64
  | .isize => return match ← psErasureTargetWordSize scope with
      | .bits32 => .int32 | .bits64 => .int64
  | _ => return word

def psErasureResolvePrimitive (scope : PsErasureScope)
    (type : PsVerifiedIrType) : Except PsErasureError PsVerifiedIrType := do
  match type with
  | .primitive .usize => return .primitive (match ← psErasureTargetWordSize scope with
      | .bits32 => .uint32 | .bits64 => .uint64)
  | .primitive .isize => return .primitive (match ← psErasureTargetWordSize scope with
      | .bits32 => .int32 | .bits64 => .int64)
  | _ => return type

def psErasureNatRecursor : PsRuntimeInductiveInfo :=
  PsRuntimeInductiveInfo.mk "Nat" psNatName psNatRecName 0 List.nil
    (List.cons
      (PsRuntimeConstructorInfo.mk "Nat" "zero" psNatZeroName 0 List.nil 0)
      (List.cons
        (PsRuntimeConstructorInfo.mk "Nat" "succ" psNatSuccName 0
          (List.cons (PsRuntimeConstructorField.mk 0 "predecessor" (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat) true none) List.nil) 1)
        List.nil)) 0 [] none none

def psErasureBoolRecursor : PsRuntimeInductiveInfo :=
  PsRuntimeInductiveInfo.mk "Bool" psBoolName (psNameAppendStr psBoolName "rec") 0 []
    [PsRuntimeConstructorInfo.mk "Bool" "false" psBoolFalseName 0 [] 0,
     PsRuntimeConstructorInfo.mk "Bool" "true" psBoolTrueName 0 [] 0] 0 [] none none

-- Int has two Nat payloads, neither recursively contains an Int. Its runtime
-- representation is primitive, so elimination uses a sign split rather than
-- a tagged constructor allocation (Lean 4.35.0 Init/Prelude, LCNF/ToImpureType).
def psErasureIntRecursor : PsRuntimeInductiveInfo :=
  PsRuntimeInductiveInfo.mk "Int" psIntName (psNameAppendStr psIntName "rec") 0 []
    [PsRuntimeConstructorInfo.mk "Int" "ofNat" psIntOfNatName 0
       [PsRuntimeConstructorField.mk 0 "magnitude" (.primitive .nat) false none] 1,
     PsRuntimeConstructorInfo.mk "Int" "negSucc" psIntNegSuccName 0
       [PsRuntimeConstructorField.mk 0 "predecessor" (.primitive .nat) false none] 1] 0 [] none none

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
      (psErasureIndexInsert PsRuntimeInductiveInfo
        (psErasureIndexInsert PsRuntimeInductiveInfo PsErasureNameIndex.empty psNatRecName psErasureNatRecursor)
        (psNameAppendStr psBoolName "rec") psErasureBoolRecursor)
      (psNameAppendStr psIntName "rec") psErasureIntRecursor
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

-- The type of a proof-producing declaration is often a telescope, e.g.
--  ∀ (xs : coll) (i : idx) [Decidable (valid xs i)], lhs = rhs.
-- Looking only for a syntactic Sort result misses its Prop-valued codomain.
-- Open each checked binder in context; a computational function with a Nat
-- codomain is NOT erased. This is the same property for every user theorem,
-- proof-valued class method and proof-only Standard projection.
def psErasureIsProofFamily (environment : PsEnvironment) (fuel : Nat)
    (localContext : PsLocalContext) (type : PsExpr) : Bool :=
  match fuel with
  | 0 => false
  | fuel + 1 =>
    match psWhnf environment psMetaEmpty localContext type with
    | .forallE name domain body binder =>
      let pushed := psLocalPushBinding localContext name domain binder
      psErasureIsProofFamily environment fuel pushed.context
        (psExprInstantiate1 body (.fvar pushed.id))
    | residual => psErasureIsProp environment localContext residual

def psErasureIsNonRuntimeDeclaration (environment : PsEnvironment)
    (type : PsExpr) : Bool :=
  psErasureIsProofFamily environment 4096 psLocalEmpty type ||
    psErasureIsTypeFamily environment 4096 psLocalEmpty type

-- A specialized dictionary may carry only types/proofs even when its generic
-- class has a value field. Inspect the instantiated checked telescope.
def psErasureIsErasedDictionary (environment : PsEnvironment) (fuel : Nat)
    (locals : PsLocalContext) (type : PsExpr) : Bool :=
  match fuel with
  | 0 => false
  | fuel + 1 =>
    let type := psWhnf environment psMetaEmpty locals type
    match type with
    | .forallE name domain body binder =>
      let pushed := psLocalPushBinding locals name domain binder
      psErasureIsErasedDictionary environment fuel pushed.context
        (psExprInstantiate1 body (.fvar pushed.id))
    | _ => Id.run do
      let view := psInferAppView type
      let .constE name levels := view.head | return false
      if !environment.classes.any (psNameEq name) then return false
      let some info := psEnvironmentFindInductive environment name | return false
      let [constructor] := info.constructors | return false
      let some ctor := psEnvironmentFindConstructor environment constructor | return false
      -- A zero-field Type-valued marker is still an ordinary runtime singleton.
      -- Its dictionaries and uses must share the existing empty-structure plan.
      -- This specialization applies only when actual fields carry erased data.
      if ctor.numFields == 0 || view.args.length != info.numParams ||
          !ctor.recursiveFields.isEmpty then return false
      let cursor := psExprInstantiateLevelParams ctor.levelParams levels ctor.type
      let some cursor := psReduceApplyType (psWhnf environment psMetaEmpty locals)
        cursor view.args | return false
      let mut cursor := cursor
      let mut locals := locals
      for _ in [:ctor.numFields] do
        let .forallE name domain body binder := psWhnf environment psMetaEmpty locals cursor
          | return false
        if !psErasureIsProp environment locals domain &&
            !psErasureIsTypeFamily environment fuel locals domain then return false
        let pushed := psLocalPushBinding locals name domain binder
        locals := pushed.context
        cursor := psExprInstantiate1 body (.fvar pushed.id)
      return true

-- A prepared empty structure is a runtime singleton. Its constructors already
-- have the checked nominal record representation with no retained fields.
-- Keep ordinary producer/forwarding calls even when all logical fields erase;
-- recognizing a dictionary does not make its computation a proof.
def psErasureHasEmptyStructureResult (environment : PsEnvironment)
    (structures : PsErasureNameIndex PsRuntimeStructureInfo) (fuel : Nat)
    (locals : PsLocalContext) (type : PsExpr) : Bool :=
  match fuel with
  | 0 => false
  | fuel + 1 =>
    match psWhnf environment psMetaEmpty locals type with
    | .forallE name domain body binder =>
      let pushed := psLocalPushBinding locals name domain binder
      psErasureHasEmptyStructureResult environment structures fuel pushed.context
        (psExprInstantiate1 body (.fvar pushed.id))
    | result =>
      let view := psInferAppView result
      match view.head with
      | .constE name _ =>
        match psErasureLookupStructure structures name with
        | some layout => !layout.unboxed && layout.fields.isEmpty &&
            psNameEq layout.coreName name && view.args.length == layout.numParams
        | none => false
      | _ => false

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
        PsErasedBinderKind.index
      else
        PsErasedBinderKind.runtime

-- Uniform datatype parameters occur in a checked family telescope, not in
-- the stored constructor fields. Retain only type parameters in target types;
-- numeric and proof parameters still participate in Core substitution. Ordinary
-- function binders keep psErasureClassifyBinder, so computational Nat arguments
-- are not discarded by this representation-specific rule.
def psErasureClassifyFamilyParameter (environment : PsEnvironment)
    (localContext : PsLocalContext) (type : PsExpr) : PsErasedBinderKind :=
  match psErasureClassifyBinder environment localContext type with
  | .type => .type
  | _ => .index

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
  if psEnvironmentIsNoncomputable environment name ||
      psErasureIsNonRuntimeDeclaration environment type then Except.ok entries
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
      let names := { scope.declarationNames with entries := entries };
      Except.ok
        ({ scope with declarationNames := names })

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
  let names := { scope.declarationNames with
    byOutput := psErasureIndexInsert Bool scope.declarationNames.byOutput
      (PsName.str PsName.anonymous name) true
    count := scope.declarationNames.count + 1 };
  { scope with declarationNames := names }

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
  else if psNameEq name psUnitName || psNameEq name (psRootName "PUnit") then
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


-- Compute the retained source positions from the checked family telescope.
-- This must agree with the stored plan in runtime inductive/structure metadata.
def psErasureInductiveSourceTypeIndicesWithFuel
    (environment : PsEnvironment) (fuel : Nat)
    (context : PsLocalContext) (cursor : PsExpr) (count sourceIndex : Nat)
    (indicesRev : List Nat) : Except PsErasureError (List Nat) := do
  match count with
  | 0 => return indicesRev.reverse
  | count + 1 =>
    match fuel with
    | 0 => throw .fuelExhausted
    | remaining + 1 =>
      let .forallE name domain body binder :=
        psWhnf environment psMetaEmpty context cursor | throw .binderMismatch
      let pushed := psLocalPushBinding context name domain binder
      let next := psExprInstantiate1 body (.fvar pushed.id)
      match psErasureClassifyFamilyParameter environment context domain with
      | .type =>
        psErasureInductiveSourceTypeIndicesWithFuel environment remaining
          pushed.context next count (sourceIndex + 1) (sourceIndex :: indicesRev)
      | .index =>
        psErasureInductiveSourceTypeIndicesWithFuel environment remaining
          pushed.context next count (sourceIndex + 1) indicesRev
      | _ => throw .unsupportedRuntimeTerm

def psErasureInductiveSourceTypeIndices
    (environment : PsEnvironment) (scope : PsErasureScope)
    (info : PsInductiveInfo) : Except PsErasureError (List Nat) :=
  psErasureInductiveSourceTypeIndicesWithFuel environment 4096
    scope.localContext info.type info.numParams 0 []

def psErasureSelectSourceTypeArguments (arguments : List PsExpr)
    (positions : List Nat) : Except PsErasureError (List PsExpr) := do
  positions.mapM fun position =>
    match arguments[position]? with
    | some argument => pure argument
    | none => throw .binderMismatch

-- Reify data/class arguments using the same Core binder roles as declaration
-- erasure; never lower a predicate former as an unknown or Unit generic.
def psErasureReifyInductiveArgumentsWithFuel
    (environment : PsEnvironment) (scope : PsErasureScope)
    (erase : PsExpr → Except PsErasureError PsVerifiedIrType)
    (fuel : Nat) (cursor : PsExpr) (arguments : List PsExpr)
    (typesRev : List PsVerifiedIrType) :
    Except PsErasureError (List PsVerifiedIrType) := do
  match arguments with
  | [] => return typesRev.reverse
  | argument :: rest =>
    match fuel with
    | 0 => throw .fuelExhausted
    | remaining + 1 =>
      let .forallE _ domain body _ :=
        psWhnf environment psMetaEmpty scope.localContext cursor
        | throw .binderMismatch
      let next := psExprInstantiate1 body argument
      match psErasureClassifyFamilyParameter environment scope.localContext domain with
      | .type =>
        let value ← erase argument
        match value with
        | .unknown => throw .unsupportedRuntimeTerm
        | _ =>
          psErasureReifyInductiveArgumentsWithFuel environment scope erase
            remaining next rest (value :: typesRev)
      | .index =>
        psErasureReifyInductiveArgumentsWithFuel environment scope erase
          remaining next rest typesRev
      | _ => throw .unsupportedRuntimeTerm

def psErasureUnboxedFieldType (environment : PsEnvironment)
    (scope : PsErasureScope) (type : PsExpr) : Option PsExpr := do
  let view := psInferAppView type
  let .constE name levels := view.head | none
  let info ← psErasureLookupStructure scope.runtimeStructures name
  if !info.unboxed || view.args.length != info.numParams then none else do
    let ctor ← psEnvironmentFindConstructor environment info.constructorName
    let cursor := psExprInstantiateLevelParams ctor.levelParams levels ctor.type
    let cursor ← psReduceApplyType (psWhnf environment psMetaEmpty scope.localContext)
      cursor view.args
    let .forallE _ domain _ _ := psWhnf environment psMetaEmpty scope.localContext cursor | none
    return domain

-- Projection templates of unboxed families are instantiated at the use site.
-- They have no generic runtime signature: their erased type former is resolved
-- before a concrete field type is admitted to IR.
def psErasureUnboxedProjection (environment : PsEnvironment) (scope : PsErasureScope)
    (fuel : Nat) (locals : PsLocalContext) (indices : List Nat) (value : PsExpr) : Bool :=
  match fuel with
  | 0 => false
  | fuel + 1 => match value with
    | .lam name domain body binder =>
      let pushed := psLocalPushBinding locals name domain binder
      let indices := match psErasureClassifyBinder environment locals domain with
        | .index => pushed.id :: indices
        | _ => indices
      psErasureUnboxedProjection environment scope fuel pushed.context indices
        (psExprInstantiate1 body (.fvar pushed.id))
    | .proj family 0 target =>
      if !((psErasureLookupStructure scope.runtimeStructures family).map (·.unboxed)).getD false
      then false else
      match psInferType environment psMetaEmpty locals (.proj family 0 target) with
      | .error _ => false
      | .ok type => (psExprFVarIds type).any indices.contains
    | _ => false

-- A polymorphic unboxed method may be specialized only through a checked
-- dictionary value. Inference failures retain their resource classification.
def psErasureInferUnboxedProjection (environment : PsEnvironment)
    (scope : PsErasureScope) (value : PsExpr) : Except PsErasureError PsExpr :=
  match psInferType environment psMetaEmpty scope.localContext value with
  | .ok type => .ok type
  | .error .fuelExhausted => .error .fuelExhausted
  | .error _ => .error .unsupportedApplication

-- A declaration is an inert function value only before its checked runtime
-- entry is saturated. A Pi result alone may be a computed returned function.
def psErasureUnboxedFunctionValue (environment : PsEnvironment)
    (value : PsExpr) : Except PsErasureError Bool := do
  let view := psInferAppView value
  let .constE name levels := view.head | return false
  let some declaration := psEnvironmentFind environment name | return false
  let some (parameters, type, body) := (match declaration with
    | .definitionDecl _ parameters type body
    | .partialDecl _ parameters type body
    | .opaqueDecl _ parameters type body => some (parameters, type, body)
    | _ => none) | return false
  if parameters.length != levels.length then throw .binderMismatch
  let entry ← psErasureEntryInfoWithFuel environment 256 psLocalEmpty
    (psExprInstantiateLevelParams parameters levels type)
    (psExprInstantiateLevelParams parameters levels body)
  if view.args.length > entry.binders.length then return false
  let supplied := (entry.binders.take view.args.length).foldl (fun count kind =>
    match kind with
    | .runtime | .proof => count + 1
    | _ => count) 0
  return Nat.blt supplied entry.runtimeArity

-- Validate the original dictionary construction before any projection can
-- discard its other fields. Runtime arguments must already be values; erased
-- arguments retain their exact checked Core expressions. Inspect beneath erased
-- lambdas because they do not delay execution; runtime/proof lambdas do.
def psErasureUnboxedDictionaryValue (environment : PsEnvironment)
    (scope : PsErasureScope) (fuel : Nat) : PsExpr → Except PsErasureError PsExpr :=
  match fuel with
  | 0 => fun _ => .error .fuelExhausted
  | fuel + 1 => fun value => do
    let smaller := psErasureUnboxedDictionaryValue environment scope fuel
    match value with
    | .lit _ | .sortE _ | .forallE _ _ _ _ => return value
    | .lam name domain body binder =>
      match psErasureClassifyBinder environment scope.localContext domain with
      | .type | .index =>
        let pushed := psLocalPushBinding scope.localContext name domain binder
        let nextScope := { scope with localContext := pushed.context }
        let _ ← psErasureUnboxedDictionaryValue environment nextScope fuel
          (psExprInstantiate1 body (.fvar pushed.id))
        return value
      | _ => return value
    | .fvar id =>
      match psLocalFindById scope.localContext id with
      | some (.letDecl _ _ _ body) => smaller body
      | some _ => return value
      | none => throw (.unknownLocal id)
    | .letE _ domain argument body =>
      let argument ← match psErasureClassifyBinder environment scope.localContext domain with
        | .runtime => smaller argument
        | _ => pure argument
      smaller (psExprInstantiate1 body argument)
    | .constE name levels =>
      if psEnvironmentIsNoncomputable environment name then
        throw (.noncomputableDependency name)
      let some declaration := psEnvironmentFind environment name |
        throw (.unknownConstant name)
      if (psDeclarationLevelParams declaration).length != levels.length then
        throw .binderMismatch
      let retainFunction : Unit → Except PsErasureError PsExpr := fun _ => do
        if ← psErasureUnboxedFunctionValue environment value then return value
        else throw .unsupportedApplication
      match declaration with
      | .constructorDecl _ => return value
      | .definitionDecl _ parameters _ body =>
        if psEnvironmentCanUnfold environment .instances name then
          smaller (psExprInstantiateLevelParams parameters levels body)
        else retainFunction ()
      | _ => retainFunction ()
    | .app fn argument =>
      let functionType ← psErasureInferUnboxedProjection environment scope fn
      let .forallE _ domain _ _ := psWhnfWithTransparency .instances environment
        psMetaEmpty scope.localContext functionType | throw .unsupportedApplication
      let fn ← smaller fn
      let argument ← match psErasureClassifyBinder environment scope.localContext domain with
        | .runtime => smaller argument
        | _ => pure argument
      match fn with
      | .lam _ _ body _ => smaller (psExprInstantiate1 body argument)
      | _ =>
        let view := psInferAppView fn
        let .constE name _ := view.head | throw .unsupportedApplication
        let applied := PsExpr.app fn argument
        if (psEnvironmentFindConstructor environment name).isSome then return applied
        else if ← psErasureUnboxedFunctionValue environment applied then return applied
        else throw .unsupportedApplication
    | .proj owner index major =>
      let major ← smaller major
      let some field := psReduceProjectionIota (fun term => term)
        environment owner index major | throw .unsupportedApplication
      smaller field
    | .bvar _ => throw .looseBoundVariable
    | .mvar _ => throw .unresolvedMetavariable

def psErasureUnboxedMethodArguments (environment : PsEnvironment)
    (scope : PsErasureScope) (fuel : Nat) (type : PsExpr)
    (arguments : List PsExpr) : Except PsErasureError Unit := do
  match fuel with
  | 0 => throw .fuelExhausted
  | fuel + 1 =>
    match psWhnfWithTransparency .instances environment psMetaEmpty scope.localContext type with
    | .forallE _ domain body _ =>
      match psErasureClassifyBinder environment scope.localContext domain with
      | .type | .index =>
        let argument :: rest := arguments | throw .binderMismatch
        psErasureUnboxedMethodArguments environment scope fuel
          (psExprInstantiate1 body argument) rest
      | _ => pure ()
    | _ => pure ()

def psErasureSpecializeUnboxedProjection (environment : PsEnvironment)
    (scope : PsErasureScope) (name : PsName) (original expanded : PsExpr) :
    Except PsErasureError PsExpr := do
  let some (owner, index, major, arguments) :=
    psReduceClassProjectionView environment name expanded | return expanded
  let projection := PsExpr.proj owner index major
  let projectionType ← psErasureInferUnboxedProjection environment scope projection
  let needsConcreteMethod := match psWhnfWithTransparency .instances environment
      psMetaEmpty scope.localContext projectionType with
    | .forallE _ domain _ _ =>
      match psErasureClassifyBinder environment scope.localContext domain with
      | .type | .index => true
      | _ => false
    | _ => false
  if !needsConcreteMethod then return expanded
  let originalType ← psErasureInferUnboxedProjection environment scope original
  psErasureUnboxedMethodArguments environment scope 256 projectionType arguments
  let majorType ← psErasureInferUnboxedProjection environment scope major
  let checkedMajor ← psErasureUnboxedDictionaryValue environment scope 256 major
  let normalizedMajor := psWhnfWithTransparency .instances environment
    psMetaEmpty scope.localContext checkedMajor
  let normalizedMajorType ← psErasureInferUnboxedProjection environment scope normalizedMajor
  if !psDefEqReadOnlyWithEnv environment psMetaEmpty scope.localContext
      majorType normalizedMajorType then throw .unsupportedApplication
  let majorTypeView := psInferAppView (psWhnfWithTransparency .instances environment
    psMetaEmpty scope.localContext majorType)
  let .constE typeOwner typeLevels := majorTypeView.head | throw .unsupportedApplication
  let constructorView := psInferAppView normalizedMajor
  let .constE _ constructorLevels := constructorView.head | throw .unsupportedApplication
  if !psNameEq typeOwner owner || typeLevels.length != constructorLevels.length ||
      !(typeLevels.zip constructorLevels).all
        (fun pair => psLevelEquivalent pair.fst pair.snd) then throw .binderMismatch
  -- Iota authenticates the single constructor, family, ordinal, levels and
  -- saturated parameter/field telescope before exposing the actual method.
  let some field := psReduceProjectionIota (fun term => term)
    environment owner index normalizedMajor | throw .unsupportedApplication
  let fieldType ← psErasureInferUnboxedProjection environment scope field
  if !psDefEqReadOnlyWithEnv environment psMetaEmpty scope.localContext
      projectionType fieldType then throw .unsupportedApplication
  -- Keep every suffix operand and its order. Existing erased-lambda application
  -- erasure instantiates only the leading type/index binders; runtime operands
  -- remain ordinary calls even when the stored method ignores an argument.
  let replacement := psExprApplyMany field arguments
  let replacementType ← psErasureInferUnboxedProjection environment scope replacement
  if !psDefEqReadOnlyWithEnv environment psMetaEmpty scope.localContext
      originalType replacementType then throw .unsupportedApplication
  return replacement

def psErasureExpandUnboxedProjection (environment : PsEnvironment)
    (scope : PsErasureScope) (value : PsExpr) : Except PsErasureError (Option PsExpr) := do
  let view := psInferAppView value
  let .constE name levels := view.head | return none
  let some declaration := psEnvironmentFind environment name | return none
  let some body := psDeclarationValue declaration | return none
  if !psErasureUnboxedProjection environment scope 4096 psLocalEmpty [] body then
    return none
  if (psDeclarationLevelParams declaration).length != levels.length then
    throw .binderMismatch
  let expanded := psWhnfCore psMetaEmpty scope.localContext
    (psExprApplyMany (psExprInstantiateLevelParams
      (psDeclarationLevelParams declaration) levels body) view.args)
  return some (← psErasureSpecializeUnboxedProjection environment scope name value expanded)

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
        -- A checked proposition has an irrelevant carrier. This lets a
        -- Sort-polymorphic datatype retain its declared type-parameter layout
        -- at universe zero; it does not invent a type for unsupported indices.
        if psErasureIsProp environment scope.localContext value then
          Except.ok psErasureProofSlotType
        else match psErasureUnboxedFieldType environment scope value with
        | some fieldType => smaller scope fieldType
        | none => match value with
          | .fvar id =>
              match psErasureLookupNat scope.typeLocals id with
              | Option.some name =>
                  Except.ok (PsVerifiedIrType.typeParameter name)
              | Option.none =>
                  Except.ok PsVerifiedIrType.unknown
          | .constE name _ =>
              match psErasurePrimitiveType name with
              | Option.some primitive => psErasureResolvePrimitive scope primitive
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
                    -- Higher-kinded predicate indices cannot become runtime types.
                    -- Interpret only the Core family's retained type parameters.
                    let arguments := match psEnvironmentFindInductive environment name with
                      | some info =>
                        if view.args.length < info.numParams then
                          Except.error PsErasureError.binderMismatch
                        else
                          psErasureReifyInductiveArgumentsWithFuel environment scope
                            (smaller scope) 4096 info.type
                            (view.args.take info.numParams) []
                      | none => psErasureMapRuntimeTypes (smaller scope) view.args
                    match arguments with
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
                  let nextScope : PsErasureScope := { scope with
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
              | .index =>
                  let pushed := psLocalPushBinding scope.localContext name domain binder
                  let nextScope := { scope with
                    localContext := pushed.context
                    erasedLocals := pushed.id :: scope.erasedLocals }
                  smaller nextScope (psExprInstantiate1 body (.fvar pushed.id))
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

-- Prepared single-field layouts are shared by explicit scalar/model adapters.
-- Proof and index erasure have already determined the physical field identity.
def psErasureSingleRuntimeField (scope : PsErasureScope) (owner : PsName) :
    Except PsErasureError (PsRuntimeStructureInfo × PsRuntimeStructureField) := do
  let some info := psErasureLookupStructure scope.runtimeStructures owner
    | throw .unsupportedRuntimeTerm
  let [field] := info.fields | throw .unsupportedRuntimeTerm
  if info.unboxed || !info.typeParameters.isEmpty then throw .unsupportedRuntimeTerm
  return (info, field)

