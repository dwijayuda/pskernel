import Ps.KernelCore.API.DagMutualConstructorLoop
import Ps.KernelCore.API.DagOrdinaryGenerated
import Ps.KernelCore.Admission.Inductive.Mutual.AdmissionLoops

/- Private syntax adapters for mutual recursors. input is the existing
   validated original boundary table; built is its known-correct decoded
   append-only continuation. Internal decoded records are not certificates.
   Original closed types are read only from input; checked opened IDs are
   read only from built. No input root is traversed or re-expanded here.

   The retained mutual builders below construct syntax/metadata only. No V1
   checker is called and no environment is published. Every generated type
   and rule still requires independent owning DAG Check/EnsureSort/DefEq. -/
structure PsKernelExprV2MutualRecursorData where
  parameters : List PsKernelOpenBinder
  types : List PsKernelSimpleMutualTypeShape
  constructors : List PsKernelSimpleMutualConstructorShape

structure PsKernelExprV2MutualRecursorPlan where
  data : PsKernelExprV2MutualRecursorData
  levels : List PsKernelLevel
  recLevelParams : List PsKernelName
  motives : List PsKernelOpenBinder
  minors : List PsKernelOpenBinder
  ruleBinders : List PsKernelOpenBinder
  infos : List PsKernelRecursorInfo

def psKernelExprV2MutualDecodeConstructorDecls
    (values : List PsKernelDagConstructor) : PsKernelExprV2Decoded ->
    Except String (List PsKernelSimpleConstructorDecl) :=
  match values with
  | List.nil => fun (_input : PsKernelExprV2Decoded) => Except.ok List.nil
  | List.cons first rest =>
      let smaller := psKernelExprV2MutualDecodeConstructorDecls rest;
      fun (input : PsKernelExprV2Decoded) =>
        match psKernelExprV2DecodedRequire input first.type with
        | Except.error error => Except.error error
        | Except.ok type =>
            match smaller input with
            | Except.error error => Except.error error
            | Except.ok tail => Except.ok
                (List.cons (PsKernelSimpleConstructorDecl.mk first.name type) tail)

def psKernelExprV2MutualDecodeTypeHeader
    (input built : PsKernelExprV2Decoded) (header : PsKernelExprV2MutualTypeHeader) :
    Except String PsKernelSimpleMutualTypeShape :=
  match psKernelExprV2DecodedRequire input header.declaration.type with
  | Except.error error => Except.error error
  | Except.ok type =>
      match psKernelExprV2MutualDecodeConstructorDecls header.declaration.ctors input with
      | Except.error error => Except.error error
      | Except.ok constructors =>
          match psKernelExprV2OrdinaryDecodeBinders header.indices.binders built with
          | Except.error error => Except.error error
          | Except.ok indices => Except.ok (PsKernelSimpleMutualTypeShape.mk
              (PsKernelSimpleMutualTypeDecl.mk header.declaration.name type constructors) indices)

def psKernelExprV2MutualDecodeTypeHeaders
    (values : List PsKernelExprV2MutualTypeHeader) :
    PsKernelExprV2Decoded -> PsKernelExprV2Decoded -> Except String (List PsKernelSimpleMutualTypeShape) :=
  match values with
  | List.nil => fun (_input _built : PsKernelExprV2Decoded) => Except.ok List.nil
  | List.cons first rest =>
      let smaller := psKernelExprV2MutualDecodeTypeHeaders rest;
      fun (input built : PsKernelExprV2Decoded) =>
        match psKernelExprV2MutualDecodeTypeHeader input built first with
        | Except.error error => Except.error error
        | Except.ok shape =>
            match smaller input built with
            | Except.error error => Except.error error
            | Except.ok tail => Except.ok (List.cons shape tail)

def psKernelExprV2MutualDecodeRecursiveField
    (built : PsKernelExprV2Decoded) (value : PsKernelExprV2MutualRecursiveField) :
    Except String PsKernelSimpleMutualRecursiveField :=
  match psKernelExprV2OrdinaryDecodeBinder built value.field with
  | Except.error error => Except.error error
  | Except.ok field =>
      match psKernelExprV2OrdinaryDecodeBinders value.arguments built with
      | Except.error error => Except.error error
      | Except.ok arguments =>
          match psKernelExprV2OrdinaryDecodeIds value.indices built with
          | Except.error error => Except.error error
          | Except.ok indices => Except.ok
              (PsKernelSimpleMutualRecursiveField.mk field arguments value.target indices)

def psKernelExprV2MutualDecodeRecursiveFields
    (values : List PsKernelExprV2MutualRecursiveField) :
    PsKernelExprV2Decoded -> Except String (List PsKernelSimpleMutualRecursiveField) :=
  match values with
  | List.nil => fun (_built : PsKernelExprV2Decoded) => Except.ok List.nil
  | List.cons first rest =>
      let smaller := psKernelExprV2MutualDecodeRecursiveFields rest;
      fun (built : PsKernelExprV2Decoded) =>
        match psKernelExprV2MutualDecodeRecursiveField built first with
        | Except.error error => Except.error error
        | Except.ok field =>
            match smaller built with
            | Except.error error => Except.error error
            | Except.ok tail => Except.ok (List.cons field tail)

def psKernelExprV2MutualDecodeConstructorShape
    (input built : PsKernelExprV2Decoded) (shape : PsKernelExprV2MutualConstructorShape) :
    Except String PsKernelSimpleMutualConstructorShape :=
  match psKernelExprV2DecodedRequire input shape.ctor.type with
  | Except.error error => Except.error error
  | Except.ok type =>
      match psKernelExprV2OrdinaryDecodeBinders shape.fields built with
      | Except.error error => Except.error error
      | Except.ok fields =>
          match psKernelExprV2MutualDecodeRecursiveFields shape.recursiveFields built with
          | Except.error error => Except.error error
          | Except.ok recursiveFields =>
              match psKernelExprV2OrdinaryDecodeIds shape.resultIndices built with
              | Except.error error => Except.error error
              | Except.ok indices => Except.ok
                  (PsKernelSimpleMutualConstructorShape.mk shape.owner
                    (PsKernelSimpleConstructorDecl.mk shape.ctor.name type)
                    fields recursiveFields indices)

def psKernelExprV2MutualDecodeConstructorShapes
    (values : List PsKernelExprV2MutualConstructorShape) :
    PsKernelExprV2Decoded -> PsKernelExprV2Decoded ->
    Except String (List PsKernelSimpleMutualConstructorShape) :=
  match values with
  | List.nil => fun (_input _built : PsKernelExprV2Decoded) => Except.ok List.nil
  | List.cons first rest =>
      let smaller := psKernelExprV2MutualDecodeConstructorShapes rest;
      fun (input built : PsKernelExprV2Decoded) =>
        match psKernelExprV2MutualDecodeConstructorShape input built first with
        | Except.error error => Except.error error
        | Except.ok shape =>
            match smaller input built with
            | Except.error error => Except.error error
            | Except.ok tail => Except.ok (List.cons shape tail)

def psKernelExprV2MutualDecodeRecursorData
    (input built : PsKernelExprV2Decoded) (header : PsKernelExprV2MutualHeaderAnalysis)
    (shapes : List PsKernelExprV2MutualConstructorShape) :
    Except String PsKernelExprV2MutualRecursorData :=
  match psKernelExprV2OrdinaryDecodeBinders header.parameters.binders built with
  | Except.error error => Except.error error
  | Except.ok parameters =>
      match psKernelExprV2MutualDecodeTypeHeaders header.types input built with
      | Except.error error => Except.error error
      | Except.ok types =>
          match psKernelExprV2MutualDecodeConstructorShapes shapes input built with
          | Except.error error => Except.error error
          | Except.ok constructors => Except.ok
              (PsKernelExprV2MutualRecursorData.mk parameters types constructors)

def psKernelExprV2MutualLegacyTypeNames
    (types : List PsKernelSimpleMutualTypeShape) : List PsKernelName :=
  match types with
  | List.nil => List.nil
  | List.cons first rest => List.cons first.decl.name (psKernelExprV2MutualLegacyTypeNames rest)

def psKernelExprV2MutualMakeRecursorPlan
    (levelParams : List PsKernelName) (resultLevel : PsKernelLevel) (isUnsafe : Bool)
    (data : PsKernelExprV2MutualRecursorData) : Except String PsKernelExprV2MutualRecursorPlan :=
  let levels := psKernelLevelParamsToLevels levelParams;
  let elimOnlyAtZero := if psKernelLevelIsNotZero resultLevel then false else true;
  let elimName := psKernelSimpleFreshElimName levelParams;
  let elimLevel := if elimOnlyAtZero then PsKernelLevel.zero else PsKernelLevel.param elimName;
  let recLevelParams := if elimOnlyAtZero then levelParams else List.cons elimName levelParams;
  let motives := psKernelMakeSimpleMutualMotives levels data.parameters elimLevel data.types;
  match psKernelMakeSimpleMutualMinors levels data.parameters motives data.constructors with
  | Except.error error => Except.error error
  | Except.ok minors =>
      let ruleBinders := psKernelOpenBinderListAppend data.parameters
        (psKernelOpenBinderListAppend motives minors);
      let typeNames := psKernelExprV2MutualLegacyTypeNames data.types;
      match psKernelBuildSimpleMutualRecInfosFromConstructorsWorker data.types
          data.types recLevelParams typeNames levels data.parameters motives minors
          ruleBinders data.constructors 0 isUnsafe with
      | Except.error error => Except.error error
      | Except.ok infos => Except.ok (PsKernelExprV2MutualRecursorPlan.mk
          data levels recLevelParams motives minors ruleBinders infos)

def psKernelExprV2MutualExpectedRuleType
    (plan : PsKernelExprV2MutualRecursorPlan) (owner : Nat)
    (shape : PsKernelSimpleMutualConstructorShape) : Except String PsKernelExpr :=
  match psKernelSimpleMutualMotiveApp plan.motives owner shape.resultIndices
      (psKernelSimpleMutualCtorApp plan.levels plan.data.parameters shape) with
  | Except.error error => Except.error error
  | Except.ok result => Except.ok
      (psKernelCloseOpenBinders (psKernelOpenBinderListAppend plan.ruleBinders shape.fields) result)

def psKernelExprV2MutualPrepareExpectedRuleType
    (plan : PsKernelExprV2MutualRecursorPlan) (owner : Nat)
    (shape : PsKernelSimpleMutualConstructorShape) (state : PsKernelExprV2CheckState)
    (built : PsKernelExprV2Decoded) : Except String PsKernelExprV2OrdinaryImported :=
  match psKernelExprV2MutualExpectedRuleType plan owner shape with
  | Except.error error => Except.error error
  | Except.ok type => psKernelExprV2OrdinaryImportGenerated type state built
