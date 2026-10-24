import Ps.KernelCore.API.DagGenerated
import Ps.KernelCore.API.DagOrdinaryConstructorLoop
import Ps.KernelCore.API.DagOrdinaryHeader
import Ps.KernelCore.Admission.Inductive.Common.Elimination

/-
Private syntax/ownership adapters for ordinary admission. The canonical arena
extends the validated input, and built is its known correct decoded prefix.
Size checks below reject inconsistent carriers; they do not establish that
correspondence for caller-constructed records.

Only newly appended canonical nodes are decoded. Original input roots retain
their separate boundary table. Decoded checked header/constructor data feeds
the existing pure recursor constructors; no V1 checker is called here.
GeneratedImport is reused solely as a smart syntax builder. Its output is
private syntax, not an admission: the recursor type and every generated rule
must pass independent DAG checks before any successful environment result.
-/
structure PsKernelExprV2OrdinaryImported where
  state : PsKernelExprV2CheckState
  built : PsKernelExprV2Decoded
  root : Nat

structure PsKernelExprV2OrdinaryRuleState where
  state : PsKernelExprV2CheckState
  built : PsKernelExprV2Decoded

structure PsKernelExprV2OrdinaryRecursorData where
  parameters : List PsKernelOpenBinder
  indices : List PsKernelOpenBinder
  shapes : List PsKernelSimpleConstructorShape

structure PsKernelExprV2OrdinaryRecursorPlan where
  info : PsKernelRecursorInfo
  parameters : List PsKernelOpenBinder
  ruleBinders : List PsKernelOpenBinder
  motive : PsKernelExpr
  levels : List PsKernelLevel
  shapes : List PsKernelSimpleConstructorShape

structure PsKernelExprV2OrdinaryAdmissionResult where
  environment : PsKernelEnvironment
  owner : PsKernelDagGeneratedState

def psKernelExprV2OrdinaryExtendDecoded
    (arena : PsKernelExprV2PagedArena) (built : PsKernelExprV2Decoded) :
    Except String PsKernelExprV2Decoded :=
  if Nat.ble built.size arena.size then
    psKernelExprV2DecodeCanonicalFuel
      (Nat.succ (Nat.sub arena.size built.size)) arena built built.size
  else Except.error "PSKERNEL_V2_ORDINARY_DECODE_PREFIX_SIZE"

def psKernelExprV2OrdinarySynchronizeOwner
    (state : PsKernelExprV2CheckState) (built : PsKernelExprV2Decoded) :
    Except String PsKernelDagGeneratedState :=
  match psKernelExprV2OrdinaryExtendDecoded state.whnf.arena built with
  | Except.error error => Except.error error
  | Except.ok decoded =>
      Except.ok
        (PsKernelDagGeneratedState.mk state.whnf.arena decoded state.whnf.declarations)

def psKernelExprV2OrdinaryImportGenerated
    (source : PsKernelExpr) (state : PsKernelExprV2CheckState)
    (built : PsKernelExprV2Decoded) :
    Except String PsKernelExprV2OrdinaryImported :=
  match psKernelExprV2OrdinarySynchronizeOwner state built with
  | Except.error error => Except.error error
  | Except.ok owner =>
      match psKernelDagGeneratedImport source owner with
      | Except.error error => Except.error error
      | Except.ok imported =>
          let next := Prod.fst imported;
          Except.ok
            (PsKernelExprV2OrdinaryImported.mk
              (psKernelExprV2CheckStateWithArena state next.arena)
              next.built (Prod.snd imported))

def psKernelExprV2OrdinaryDecodeIds
    (values : List Nat) (built : PsKernelExprV2Decoded) :
    Except String (List PsKernelExpr) :=
  match values with
  | List.nil => Except.ok List.nil
  | List.cons root rest =>
      match psKernelExprV2DecodedRequire built root with
      | Except.error error => Except.error error
      | Except.ok first =>
          match psKernelExprV2OrdinaryDecodeIds rest built with
          | Except.error error => Except.error error
          | Except.ok tail => Except.ok (List.cons first tail)

def psKernelExprV2OrdinaryDecodeBinder
    (built : PsKernelExprV2Decoded) (binder : PsKernelExprV2OrdinaryOpenBinder) :
    Except String PsKernelOpenBinder :=
  match psKernelExprV2DecodedRequire built binder.type with
  | Except.error error => Except.error error
  | Except.ok type =>
      Except.ok
        (PsKernelOpenBinder.mk binder.internalName binder.userName type binder.binderInfo)

def psKernelExprV2OrdinaryDecodeBinders
    (values : List PsKernelExprV2OrdinaryOpenBinder) (built : PsKernelExprV2Decoded) :
    Except String (List PsKernelOpenBinder) :=
  match values with
  | List.nil => Except.ok List.nil
  | List.cons binder rest =>
      match psKernelExprV2OrdinaryDecodeBinder built binder with
      | Except.error error => Except.error error
      | Except.ok first =>
          match psKernelExprV2OrdinaryDecodeBinders rest built with
          | Except.error error => Except.error error
          | Except.ok tail => Except.ok (List.cons first tail)

def psKernelExprV2OrdinaryDecodeRecursiveField
    (built : PsKernelExprV2Decoded) (value : PsKernelExprV2OrdinaryRecursiveField) :
    Except String PsKernelSimpleRecursiveField :=
  match psKernelExprV2OrdinaryDecodeBinder built value.field with
  | Except.error error => Except.error error
  | Except.ok field =>
      match psKernelExprV2OrdinaryDecodeBinders value.arguments built with
      | Except.error error => Except.error error
      | Except.ok arguments =>
          match psKernelExprV2OrdinaryDecodeIds value.indices built with
          | Except.error error => Except.error error
          | Except.ok indices =>
              Except.ok (PsKernelSimpleRecursiveField.mk field arguments indices)

def psKernelExprV2OrdinaryDecodeRecursiveFields
    (values : List PsKernelExprV2OrdinaryRecursiveField) (built : PsKernelExprV2Decoded) :
    Except String (List PsKernelSimpleRecursiveField) :=
  match values with
  | List.nil => Except.ok List.nil
  | List.cons value rest =>
      match psKernelExprV2OrdinaryDecodeRecursiveField built value with
      | Except.error error => Except.error error
      | Except.ok first =>
          match psKernelExprV2OrdinaryDecodeRecursiveFields rest built with
          | Except.error error => Except.error error
          | Except.ok tail => Except.ok (List.cons first tail)

def psKernelExprV2OrdinaryDecodeShape
    (input built : PsKernelExprV2Decoded) (shape : PsKernelExprV2OrdinaryConstructorShape) :
    Except String PsKernelSimpleConstructorShape :=
  match psKernelExprV2DecodedRequire input shape.ctor.type with
  | Except.error error => Except.error error
  | Except.ok ctorType =>
      match psKernelExprV2OrdinaryDecodeBinders shape.fields built with
      | Except.error error => Except.error error
      | Except.ok fields =>
          match psKernelExprV2OrdinaryDecodeRecursiveFields shape.recursiveFields built with
          | Except.error error => Except.error error
          | Except.ok recursiveFields =>
              match psKernelExprV2OrdinaryDecodeIds shape.resultIndices built with
              | Except.error error => Except.error error
              | Except.ok indices =>
                  Except.ok
                    (PsKernelSimpleConstructorShape.mk
                      (PsKernelSimpleConstructorDecl.mk shape.ctor.name ctorType)
                      fields recursiveFields indices)

def psKernelExprV2OrdinaryDecodeShapes
    (values : List PsKernelExprV2OrdinaryConstructorShape)
    (input built : PsKernelExprV2Decoded) :
    Except String (List PsKernelSimpleConstructorShape) :=
  match values with
  | List.nil => Except.ok List.nil
  | List.cons value rest =>
      match psKernelExprV2OrdinaryDecodeShape input built value with
      | Except.error error => Except.error error
      | Except.ok first =>
          match psKernelExprV2OrdinaryDecodeShapes rest input built with
          | Except.error error => Except.error error
          | Except.ok tail => Except.ok (List.cons first tail)

def psKernelExprV2OrdinaryDecodeRecursorData
    (input built : PsKernelExprV2Decoded)
    (header : PsKernelExprV2OrdinaryHeaderAnalysis)
    (shapes : List PsKernelExprV2OrdinaryConstructorShape) :
    Except String PsKernelExprV2OrdinaryRecursorData :=
  match psKernelExprV2OrdinaryDecodeBinders header.parameters.binders built with
  | Except.error error => Except.error error
  | Except.ok parameters =>
      match psKernelExprV2OrdinaryDecodeBinders header.indices.binders built with
      | Except.error error => Except.error error
      | Except.ok indices =>
          match psKernelExprV2OrdinaryDecodeShapes shapes input built with
          | Except.error error => Except.error error
          | Except.ok decodedShapes =>
              Except.ok
                (PsKernelExprV2OrdinaryRecursorData.mk parameters indices decodedShapes)

def psKernelExprV2OrdinaryMakeRecursorPlan
    (decl : PsKernelSimpleInductiveDecl) (resultLevel : PsKernelLevel)
    (data : PsKernelExprV2OrdinaryRecursorData) (elimOnlyAtZero : Bool) :
    PsKernelExprV2OrdinaryRecursorPlan :=
  let levels := psKernelLevelParamsToLevels decl.levelParams;
  let indexArgs := psKernelOpenBinderExprs data.indices;
  let inductExpr :=
    psKernelApplyArgs (PsKernelExpr.const decl.name levels)
      (psKernelExprListAppend (psKernelSimpleParamArgs data.parameters) indexArgs);
  let elimName := psKernelSimpleFreshElimName decl.levelParams;
  let elimLevel :=
    if elimOnlyAtZero then PsKernelLevel.zero else PsKernelLevel.param elimName;
  let recLevelParams :=
    if elimOnlyAtZero then decl.levelParams else List.cons elimName decl.levelParams;
  let motiveInternal := psKernelSimpleInternalName "motive";
  let motive := PsKernelExpr.fvar motiveInternal;
  let motiveBinder :=
    PsKernelOpenBinder.mk motiveInternal (PsKernelName.str PsKernelName.anonymous "motive")
      (psKernelCloseOpenBinders data.indices
        (psKernelMkArrow inductExpr (PsKernelExpr.sort elimLevel)))
      PsKernelBinderInfo.default;
  let minorBinders :=
    psKernelMakeSimpleMinorBinders motive levels data.parameters data.shapes;
  let majorInternal := psKernelSimpleInternalName "major";
  let major := PsKernelExpr.fvar majorInternal;
  let majorBinder :=
    PsKernelOpenBinder.mk majorInternal (PsKernelName.str PsKernelName.anonymous "t")
      inductExpr PsKernelBinderInfo.default;
  let ruleBinders :=
    psKernelOpenBinderListAppend data.parameters (List.cons motiveBinder minorBinders);
  let recBinders :=
    psKernelOpenBinderListAppend ruleBinders
      (psKernelOpenBinderListAppend data.indices (List.cons majorBinder List.nil));
  let recTypeRaw :=
    psKernelCloseOpenBinders recBinders (psKernelSimpleMotiveApp motive indexArgs major);
  let recType := psKernelExprInferImplicitAll recTypeRaw true;
  let recName := psKernelSimpleRecName decl.name;
  let recLevels := psKernelLevelParamsToLevels recLevelParams;
  let rules :=
    psKernelMakeSimpleRecursorRules recName recLevels data.parameters
      motive minorBinders ruleBinders data.shapes minorBinders;
  let info :=
    PsKernelRecursorInfo.mk
      (PsKernelConstantBase.mk recName recLevelParams recType)
      (List.cons decl.name List.nil) decl.numParams
      (psKernelOpenBinderListLength data.indices) 1
      (psKernelOpenBinderListLength minorBinders) rules
      (psKernelSimpleKTarget resultLevel data.shapes) decl.isUnsafe;
  PsKernelExprV2OrdinaryRecursorPlan.mk
    info data.parameters ruleBinders motive levels data.shapes

def psKernelExprV2OrdinaryExpectedRuleType
    (parameters ruleBinders : List PsKernelOpenBinder)
    (motive : PsKernelExpr) (levels : List PsKernelLevel)
    (shape : PsKernelSimpleConstructorShape) : PsKernelExpr :=
  psKernelCloseOpenBinders
    (psKernelOpenBinderListAppend ruleBinders shape.fields)
    (psKernelSimpleMotiveApp motive shape.resultIndices
      (psKernelSimpleCtorApp levels parameters shape))

def psKernelExprV2OrdinaryPrepareExpectedRuleType
    (parameters ruleBinders : List PsKernelOpenBinder)
    (motive : PsKernelExpr) (levels : List PsKernelLevel)
    (shape : PsKernelSimpleConstructorShape)
    (state : PsKernelExprV2CheckState) (built : PsKernelExprV2Decoded) :
    Except String PsKernelExprV2OrdinaryImported :=
  psKernelExprV2OrdinaryImportGenerated
    (psKernelExprV2OrdinaryExpectedRuleType parameters ruleBinders motive levels shape)
    state built

def psKernelExprV2OrdinaryFreshContext
    (environment : PsKernelEnvironment) (levelParams : List PsKernelName)
    (isUnsafe : Bool) (maxRecDepth maxNatSize : Nat) :
    PsKernelExprV2CheckContext :=
  let safety :=
    if isUnsafe then PsKernelDefinitionSafety.unsafeDef
    else PsKernelDefinitionSafety.safe;
  let session :=
    psKernelMkCheckerSession environment levelParams safety maxRecDepth maxNatSize;
  psKernelExprV2CheckContextEmpty session.context

def psKernelExprV2OrdinaryFreshState
    (owner : PsKernelDagGeneratedState) : PsKernelExprV2CheckState :=
  psKernelExprV2CheckStateWithWhnf (psKernelExprV2CheckStateEmpty owner.arena)
    (psKernelExprV2WhnfStateForDeclarations owner.arena owner.declarations)
