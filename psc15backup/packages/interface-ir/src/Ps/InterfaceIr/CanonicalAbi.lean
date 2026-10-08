import Ps.InterfaceIr.Validate

-- Synchronous Canonical ABI planning only; no memory access or handle authority.
inductive PsCanonicalPointerWidth where
  | memory32
  | memory64

inductive PsCanonicalFlatType where
  | i32
  | i64
  | f32
  | f64

inductive PsCanonicalDirection where
  | lift
  | lower

structure PsCanonicalLayout where
  alignment : Nat
  byteSize : Nat
  flatCount : Nat
  flatPrefix : List PsCanonicalFlatType
  fieldOffsets : List Nat
  payloadOffset : Nat
  needsMemory : Bool
  needsHandleTable : Bool

structure PsCanonicalFunctionPlan where
  interfaceName : String
  functionName : String
  direction : PsCanonicalDirection
  parameterLayout : PsCanonicalLayout
  resultLayout : PsCanonicalLayout
  coreParameters : List PsCanonicalFlatType
  coreResults : List PsCanonicalFlatType
  indirectParameters : Bool
  indirectResult : Bool

def psCanonicalPointerBytes (width : PsCanonicalPointerWidth) : Nat :=
  match width with
  | PsCanonicalPointerWidth.memory32 => 4
  | PsCanonicalPointerWidth.memory64 => 8

def psCanonicalPointerType (width : PsCanonicalPointerWidth) : PsCanonicalFlatType :=
  match width with
  | PsCanonicalPointerWidth.memory32 => PsCanonicalFlatType.i32
  | PsCanonicalPointerWidth.memory64 => PsCanonicalFlatType.i64

def psCanonicalMax (left right : Nat) : Nat :=
  if Nat.ble left right then right else left

def psCanonicalOr (left right : Bool) : Bool :=
  if left then true else right

def psCanonicalAlign (offset alignment : Nat) : Nat :=
  Nat.mul (Nat.div (Nat.add offset (Nat.sub alignment 1)) alignment) alignment

-- Seventeen slots distinguish every synchronous direct/indirect signature.
-- flatCount is exact; the prefix is never presented as a full large flattening.
def psCanonicalFlatAppend (left right : List PsCanonicalFlatType) : List PsCanonicalFlatType :=
  psListTake 17 (psListAppend left right)

def psCanonicalFlatCode (value : PsCanonicalFlatType) : Nat :=
  match value with
  | PsCanonicalFlatType.i32 => 0
  | PsCanonicalFlatType.i64 => 1
  | PsCanonicalFlatType.f32 => 2
  | PsCanonicalFlatType.f64 => 3

def psCanonicalJoinFlat (left right : PsCanonicalFlatType) : PsCanonicalFlatType :=
  if Nat.beq (psCanonicalFlatCode left) (psCanonicalFlatCode right) then left
  else
    let narrow : PsCanonicalFlatType -> Bool :=
      fun (value : PsCanonicalFlatType) =>
        match value with
        | PsCanonicalFlatType.i32 => true
        | PsCanonicalFlatType.f32 => true
        | _ => false;
    if narrow left then
      if narrow right then PsCanonicalFlatType.i32 else PsCanonicalFlatType.i64
    else PsCanonicalFlatType.i64

def psCanonicalJoinPrefixes (left : List PsCanonicalFlatType) :
    List PsCanonicalFlatType -> List PsCanonicalFlatType :=
  match left with
  | List.nil => fun (right : List PsCanonicalFlatType) => right
  | List.cons value rest =>
      let smaller : List PsCanonicalFlatType -> List PsCanonicalFlatType := psCanonicalJoinPrefixes rest;
      fun (right : List PsCanonicalFlatType) =>
        match right with
        | List.nil => left
        | List.cons other others => List.cons (psCanonicalJoinFlat value other) (smaller others)

def psCanonicalEmptyLayout : PsCanonicalLayout :=
  PsCanonicalLayout.mk 1 0 0 List.nil List.nil 0 false false

def psCanonicalScalarLayout (size : Nat) (flat : PsCanonicalFlatType) : PsCanonicalLayout :=
  PsCanonicalLayout.mk size size 1 [flat] List.nil 0 false false

def psCanonicalScalar (width : PsCanonicalPointerWidth) (value : PsForeignScalar) : PsCanonicalLayout :=
  match value with
  | PsForeignScalar.bool => psCanonicalScalarLayout 1 PsCanonicalFlatType.i32
  | PsForeignScalar.u8 => psCanonicalScalarLayout 1 PsCanonicalFlatType.i32
  | PsForeignScalar.s8 => psCanonicalScalarLayout 1 PsCanonicalFlatType.i32
  | PsForeignScalar.u16 => psCanonicalScalarLayout 2 PsCanonicalFlatType.i32
  | PsForeignScalar.s16 => psCanonicalScalarLayout 2 PsCanonicalFlatType.i32
  | PsForeignScalar.u32 => psCanonicalScalarLayout 4 PsCanonicalFlatType.i32
  | PsForeignScalar.s32 => psCanonicalScalarLayout 4 PsCanonicalFlatType.i32
  | PsForeignScalar.u64 => psCanonicalScalarLayout 8 PsCanonicalFlatType.i64
  | PsForeignScalar.s64 => psCanonicalScalarLayout 8 PsCanonicalFlatType.i64
  | PsForeignScalar.f32 => psCanonicalScalarLayout 4 PsCanonicalFlatType.f32
  | PsForeignScalar.f64 => psCanonicalScalarLayout 8 PsCanonicalFlatType.f64
  | PsForeignScalar.char => psCanonicalScalarLayout 4 PsCanonicalFlatType.i32
  | PsForeignScalar.string =>
      let pointer : PsCanonicalFlatType := psCanonicalPointerType width;
      let bytes : Nat := psCanonicalPointerBytes width;
      PsCanonicalLayout.mk bytes (Nat.mul bytes 2) 2 [pointer, pointer] List.nil 0 true false

def psCanonicalCheckSize (value : PsCanonicalLayout) : Except PsForeignError PsCanonicalLayout :=
  if Nat.ble value.byteSize 268435455 then Except.ok value
  else Except.error PsForeignError.invalidOrUnsupportedType

structure PsCanonicalSequenceState where
  size : Nat
  alignment : Nat
  flatCount : Nat
  flatPrefix : List PsCanonicalFlatType
  offsetsReverse : List Nat
  needsMemory : Bool
  needsHandleTable : Bool

def psCanonicalSequenceWorker (values : List PsCanonicalLayout) :
    PsCanonicalSequenceState -> Except PsForeignError PsCanonicalLayout :=
  match values with
  | List.nil =>
      fun (state : PsCanonicalSequenceState) =>
        psCanonicalCheckSize (PsCanonicalLayout.mk state.alignment
          (psCanonicalAlign state.size state.alignment) state.flatCount state.flatPrefix
          (psListReverse state.offsetsReverse) 0 state.needsMemory state.needsHandleTable)
  | List.cons value rest =>
      let smaller : PsCanonicalSequenceState -> Except PsForeignError PsCanonicalLayout :=
        psCanonicalSequenceWorker rest;
      fun (state : PsCanonicalSequenceState) =>
        let offset : Nat := psCanonicalAlign state.size value.alignment;
        let size : Nat := Nat.add offset value.byteSize;
        if Nat.ble size 268435455 then
          smaller (PsCanonicalSequenceState.mk size (psCanonicalMax state.alignment value.alignment)
            (Nat.add state.flatCount value.flatCount) (psCanonicalFlatAppend state.flatPrefix value.flatPrefix)
            (List.cons offset state.offsetsReverse) (psCanonicalOr state.needsMemory value.needsMemory)
            (psCanonicalOr state.needsHandleTable value.needsHandleTable))
        else Except.error PsForeignError.invalidOrUnsupportedType

def psCanonicalSequence (values : List PsCanonicalLayout) : Except PsForeignError PsCanonicalLayout :=
  psCanonicalSequenceWorker values (PsCanonicalSequenceState.mk 0 1 0 List.nil List.nil false false)

def psCanonicalDiscriminantSize (count : Nat) : Except PsForeignError Nat :=
  if Nat.beq count 0 then Except.error PsForeignError.invalidOrUnsupportedType
  else if Nat.ble count 256 then Except.ok 1
  else if Nat.ble count 65536 then Except.ok 2
  else if Nat.ble count 4294967295 then Except.ok 4
  else Except.error PsForeignError.invalidOrUnsupportedType

def psCanonicalVariantPayload (values : List PsCanonicalLayout) : PsCanonicalLayout -> PsCanonicalLayout :=
  match values with
  | List.nil => fun (state : PsCanonicalLayout) => state
  | List.cons value rest =>
      let smaller : PsCanonicalLayout -> PsCanonicalLayout := psCanonicalVariantPayload rest;
      fun (state : PsCanonicalLayout) =>
        smaller (PsCanonicalLayout.mk (psCanonicalMax state.alignment value.alignment)
          (psCanonicalMax state.byteSize value.byteSize) (psCanonicalMax state.flatCount value.flatCount)
          (psCanonicalJoinPrefixes state.flatPrefix value.flatPrefix) List.nil 0
          (psCanonicalOr state.needsMemory value.needsMemory)
          (psCanonicalOr state.needsHandleTable value.needsHandleTable))

def psCanonicalVariant (values : List PsCanonicalLayout) : Except PsForeignError PsCanonicalLayout :=
  match psCanonicalDiscriminantSize (psListLength values) with
  | Except.error error => Except.error error
  | Except.ok tagSize =>
      let payload : PsCanonicalLayout := psCanonicalVariantPayload values psCanonicalEmptyLayout;
      let alignment : Nat := psCanonicalMax tagSize payload.alignment;
      let offset : Nat := psCanonicalAlign tagSize payload.alignment;
      psCanonicalCheckSize (PsCanonicalLayout.mk alignment
        (psCanonicalAlign (Nat.add offset payload.byteSize) alignment)
        (Nat.succ payload.flatCount) (psCanonicalFlatAppend [PsCanonicalFlatType.i32] payload.flatPrefix)
        List.nil offset payload.needsMemory payload.needsHandleTable)

def psCanonicalOptionLayout (convert : PsForeignType -> Except PsForeignError PsCanonicalLayout)
    (value : Option PsForeignType) : Except PsForeignError PsCanonicalLayout :=
  match value with
  | Option.none => Except.ok psCanonicalEmptyLayout
  | Option.some type => convert type

def psCanonicalLayoutsWith (convert : PsForeignType -> Except PsForeignError PsCanonicalLayout)
    (values : List PsForeignType) : Except PsForeignError PsCanonicalLayout :=
  match psListMapExcept convert values with
  | Except.error error => Except.error error
  | Except.ok layouts => psCanonicalSequence layouts

def psCanonicalBodyWith (convert : PsForeignType -> Except PsForeignError PsCanonicalLayout)
    (body : PsForeignDefinitionBody) : Except PsForeignError PsCanonicalLayout :=
  match body with
  | PsForeignDefinitionBody.alias type => convert type
  | PsForeignDefinitionBody.record fields =>
      let fieldType : PsForeignField -> PsForeignType := fun (field : PsForeignField) => field.type;
      if psListIsEmpty fields then Except.error PsForeignError.invalidOrUnsupportedType
      else psCanonicalLayoutsWith convert (psListMap fieldType fields)
  | PsForeignDefinitionBody.variant cases =>
      let caseLayout : PsForeignCase -> Except PsForeignError PsCanonicalLayout :=
        fun (value : PsForeignCase) => psCanonicalOptionLayout convert value.payload;
      match psListMapExcept caseLayout cases with
      | Except.error error => Except.error error
      | Except.ok layouts => psCanonicalVariant layouts
  | PsForeignDefinitionBody.enumeration cases =>
      match psCanonicalDiscriminantSize (psListLength cases) with
      | Except.error error => Except.error error
      | Except.ok size => Except.ok (psCanonicalScalarLayout size PsCanonicalFlatType.i32)
  | PsForeignDefinitionBody.resource => Except.error PsForeignError.invalidOrUnsupportedType

def psCanonicalFindLayout (layouts : List (Prod String PsCanonicalLayout))
    (name : String) : Option PsCanonicalLayout :=
  match layouts with
  | List.nil => Option.none
  | List.cons entry rest =>
      if psStringEq (Prod.fst entry) name then Option.some (Prod.snd entry)
      else psCanonicalFindLayout rest name

def psCanonicalTypeWithFuel (width : PsCanonicalPointerWidth)
    (definitions : List PsForeignDefinition) (layouts : List (Prod String PsCanonicalLayout)) (fuel : Nat) :
    PsForeignType -> Except PsForeignError PsCanonicalLayout :=
  match fuel with
  | Nat.zero => fun (_type : PsForeignType) => Except.error PsForeignError.resourceExhausted
  | Nat.succ remaining =>
      let smaller : PsForeignType -> Except PsForeignError PsCanonicalLayout :=
        psCanonicalTypeWithFuel width definitions layouts remaining;
      fun (type : PsForeignType) =>
        match type with
        | PsForeignType.scalar scalar => Except.ok (psCanonicalScalar width scalar)
        | PsForeignType.named name =>
            match psCanonicalFindLayout layouts name with
            | Option.none => Except.error PsForeignError.invalidOrUnsupportedType
            | Option.some layout => Except.ok layout
        | PsForeignType.list element =>
            match smaller element with
            | Except.error error => Except.error error
            | Except.ok layout =>
                let pointer : PsCanonicalFlatType := psCanonicalPointerType width;
                let bytes : Nat := psCanonicalPointerBytes width;
                Except.ok (PsCanonicalLayout.mk bytes (Nat.mul bytes 2) 2 [pointer, pointer]
                  List.nil 0 true layout.needsHandleTable)
        | PsForeignType.option element =>
            match smaller element with
            | Except.error error => Except.error error
            | Except.ok layout => psCanonicalVariant [psCanonicalEmptyLayout, layout]
        | PsForeignType.result ok error =>
            match psCanonicalOptionLayout smaller ok with
            | Except.error failure => Except.error failure
            | Except.ok okLayout =>
                match psCanonicalOptionLayout smaller error with
                | Except.error failure => Except.error failure
                | Except.ok errorLayout => psCanonicalVariant [okLayout, errorLayout]
        | PsForeignType.tuple elements =>
            if psListIsEmpty elements then Except.error PsForeignError.invalidOrUnsupportedType
            else psCanonicalLayoutsWith smaller elements
        | PsForeignType.own name =>
            if psForeignIsResource definitions name then
              Except.ok (PsCanonicalLayout.mk 4 4 1 [PsCanonicalFlatType.i32] List.nil 0 false true)
            else Except.error PsForeignError.invalidOrUnsupportedType
        | PsForeignType.borrow name =>
            if psForeignIsResource definitions name then
              Except.ok (PsCanonicalLayout.mk 4 4 1 [PsCanonicalFlatType.i32] List.nil 0 false true)
            else Except.error PsForeignError.invalidOrUnsupportedType
        | PsForeignType.future _ => Except.error PsForeignError.invalidOrUnsupportedType
        | PsForeignType.stream _ => Except.error PsForeignError.invalidOrUnsupportedType

-- Reuse the validated type graph's dependency order; each named layout is
-- computed once per pointer width without expanding shared definition bodies.
def psCanonicalResolveOrdered (width : PsCanonicalPointerWidth)
    (definitions : List PsForeignDefinition) (depth : Nat) (ordered : List PsForeignDefinition) :
    List (Prod String PsCanonicalLayout) -> Except PsForeignError (List (Prod String PsCanonicalLayout)) :=
  match ordered with
  | List.nil => fun (layouts : List (Prod String PsCanonicalLayout)) => Except.ok layouts
  | List.cons definition rest =>
      let smaller : List (Prod String PsCanonicalLayout) -> Except PsForeignError (List (Prod String PsCanonicalLayout)) :=
        psCanonicalResolveOrdered width definitions depth rest;
      fun (layouts : List (Prod String PsCanonicalLayout)) =>
        match definition.body with
        | PsForeignDefinitionBody.resource => smaller layouts
        | _ =>
            match psCanonicalBodyWith (psCanonicalTypeWithFuel width definitions layouts depth) definition.body with
            | Except.error error => Except.error error
            | Except.ok layout => smaller (List.cons (Prod.mk definition.name layout) layouts)

def psCanonicalResolve (width : PsCanonicalPointerWidth) (definitions : List PsForeignDefinition)
    (depth : Nat) : Except PsForeignError (List (Prod String PsCanonicalLayout)) :=
  match psForeignAnalyzeDefinitions false depth definitions with
  | Except.error error => Except.error error
  | Except.ok graph => psCanonicalResolveOrdered width definitions depth graph.ordered List.nil

def psCanonicalSignature (width : PsCanonicalPointerWidth)
    (interfaceName functionName : String) (direction : PsCanonicalDirection)
    (parameters result : PsCanonicalLayout) : PsCanonicalFunctionPlan :=
  let indirectParameters : Bool := if Nat.ble parameters.flatCount 16 then false else true;
  let indirectResult : Bool := if Nat.ble result.flatCount 1 then false else true;
  let coreParameters : List PsCanonicalFlatType :=
    if indirectParameters then [psCanonicalPointerType width] else parameters.flatPrefix;
  let coreResults : List PsCanonicalFlatType := if indirectResult then List.nil else result.flatPrefix;
  match direction with
  | PsCanonicalDirection.lift =>
      let liftedResults : List PsCanonicalFlatType :=
        if indirectResult then [psCanonicalPointerType width] else coreResults;
      PsCanonicalFunctionPlan.mk interfaceName functionName direction parameters result coreParameters
        liftedResults indirectParameters indirectResult
  | PsCanonicalDirection.lower =>
      let loweredParameters : List PsCanonicalFlatType :=
        if indirectResult then psListAppend coreParameters [psCanonicalPointerType width] else coreParameters;
      PsCanonicalFunctionPlan.mk interfaceName functionName direction parameters result
        loweredParameters coreResults indirectParameters indirectResult

def psCanonicalPlanFunction (policy : PsForeignPolicy) (width : PsCanonicalPointerWidth)
    (maximumLayouts selectedLayouts : List (Prod String PsCanonicalLayout))
    (interface : PsForeignInterface) (direction : PsCanonicalDirection)
    (function : PsForeignFunction) : Except PsForeignError PsCanonicalFunctionPlan :=
  let parameterType : PsForeignField -> PsForeignType := fun (field : PsForeignField) => field.type;
  let types : List PsForeignType := psListMap parameterType function.parameters;
  -- Core component validation bounds every value type using memory64 size,
  -- including when the selected memory has 32-bit pointers.
  let maximum : PsForeignType -> Except PsForeignError PsCanonicalLayout :=
    psCanonicalTypeWithFuel PsCanonicalPointerWidth.memory64 interface.definitions maximumLayouts policy.typeDepth;
  let selected : PsForeignType -> Except PsForeignError PsCanonicalLayout :=
    psCanonicalTypeWithFuel width interface.definitions selectedLayouts policy.typeDepth;
  if function.asynchronous then Except.error PsForeignError.invalidOrUnsupportedType
  else
    match psCanonicalLayoutsWith maximum types with
    | Except.error error => Except.error error
    | Except.ok _ =>
        match psCanonicalOptionLayout maximum function.result with
        | Except.error error => Except.error error
        | Except.ok _ =>
            match psCanonicalLayoutsWith selected types with
            | Except.error error => Except.error error
            | Except.ok parameters =>
                match psCanonicalOptionLayout selected function.result with
                | Except.error error => Except.error error
                | Except.ok result => Except.ok (psCanonicalSignature width interface.name function.name direction parameters result)

def psCanonicalPlanInterfaceWith (policy : PsForeignPolicy) (width : PsCanonicalPointerWidth)
    (maximumLayouts selectedLayouts : List (Prod String PsCanonicalLayout))
    (world : PsForeignWorld) (interface : PsForeignInterface) : Except PsForeignError (List PsCanonicalFunctionPlan) :=
  let lower : PsForeignFunction -> Except PsForeignError PsCanonicalFunctionPlan :=
    psCanonicalPlanFunction policy width maximumLayouts selectedLayouts interface PsCanonicalDirection.lower;
  let lift : PsForeignFunction -> Except PsForeignError PsCanonicalFunctionPlan :=
    psCanonicalPlanFunction policy width maximumLayouts selectedLayouts interface PsCanonicalDirection.lift;
  let imports : Except PsForeignError (List PsCanonicalFunctionPlan) :=
    if psForeignContains interface.name world.imports then psListMapExcept lower interface.functions else Except.ok List.nil;
  let exports : Except PsForeignError (List PsCanonicalFunctionPlan) :=
    if psForeignContains interface.name world.exports then psListMapExcept lift interface.functions else Except.ok List.nil;
  match imports with
  | Except.error error => Except.error error
  | Except.ok lowered =>
      match exports with
      | Except.error error => Except.error error
      | Except.ok lifted => Except.ok (psListAppend lowered lifted)

def psCanonicalPlanInterface (policy : PsForeignPolicy) (width : PsCanonicalPointerWidth)
    (world : PsForeignWorld) (interface : PsForeignInterface) : Except PsForeignError (List PsCanonicalFunctionPlan) :=
  match psCanonicalResolve PsCanonicalPointerWidth.memory64 interface.definitions policy.typeDepth with
  | Except.error error => Except.error error
  | Except.ok maximumLayouts =>
      match width with
      | PsCanonicalPointerWidth.memory64 =>
          psCanonicalPlanInterfaceWith policy width maximumLayouts maximumLayouts world interface
      | PsCanonicalPointerWidth.memory32 =>
          match psCanonicalResolve width interface.definitions policy.typeDepth with
          | Except.error error => Except.error error
          | Except.ok selectedLayouts =>
              psCanonicalPlanInterfaceWith policy width maximumLayouts selectedLayouts world interface

-- The public world planner validates interface, type, target, borrow and
-- capability policy before producing adapter data. Plans are not live handles.
def psCanonicalPlanWorld (policy : PsForeignPolicy) (width : PsCanonicalPointerWidth)
    (world : PsForeignWorld) : Except PsForeignError (List PsCanonicalFunctionPlan) :=
  if psStringEq policy.target "component-model" then
    if policy.allowAsync then Except.error PsForeignError.invalidOrUnsupportedType
    else
      match psForeignValidateWorld policy world with
      | Except.error error => Except.error error
      | Except.ok _ => psListFlatMapExcept (psCanonicalPlanInterface policy width world) world.interfaces
  else Except.error PsForeignError.targetUnavailable
