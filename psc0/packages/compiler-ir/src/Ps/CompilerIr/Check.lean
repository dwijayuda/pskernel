import Ps.CompilerIr.CheckTypes
import Ps.CompilerIr.CheckSize

-- Runtime typing evidence for one immutable module. Resource limits count
-- dispatcher steps and bound each complete type operation separately.
structure PsIrCheckOptions where
  maxSteps : Nat
  maxTypeSteps : Nat
  maxFindings : Nat

def psIrCheckOptionsWithLimits (maxSteps maxTypeSteps maxFindings : Nat) : PsIrCheckOptions :=
  PsIrCheckOptions.mk maxSteps maxTypeSteps maxFindings

def psIrCheckDefaultOptions : PsIrCheckOptions :=
  PsIrCheckOptions.mk 5000000 65536 1000

structure PsIrCheckFinding where
  code : String
  detail : String
  owner : String
  path : String
  expected : Option PsVerifiedIrType
  actual : Option PsVerifiedIrType

structure PsIrCheckReport where
  accepted : Bool
  traversalComplete : Bool
  visitedSteps : Nat
  expressionCount : Nat
  findingCount : Nat
  findings : List PsIrCheckFinding

structure PsIrCheckScope where
  owner : String
  path : String
  typeScope : List String
  bindings : List PsVerifiedIrParameter

inductive PsIrCheckValue where
  | invalid
  | mono (type : PsVerifiedIrType)
  | scheme (binders : List String) (type : PsVerifiedIrType)

structure PsIrCheckMatchPlan where
  scope : PsIrCheckScope
  substitutions : List (String × PsVerifiedIrType)
  constructors : List PsVerifiedIrConstructor

inductive PsIrCheckTask where
  | expression (scope : PsIrCheckScope) (expr : PsVerifiedIrExpr)
      (expected : Option PsVerifiedIrType) (allowScheme : Bool)
  | expect (scope : PsIrCheckScope) (expected : Option PsVerifiedIrType)
      (allowScheme : Bool)
  | discard
  | yieldValue (value : PsIrCheckValue)
  | callCallee (scope : PsIrCheckScope) (typeArguments : List PsVerifiedIrType)
      (arguments : List PsVerifiedIrExpr)
  | arguments (scope : PsIrCheckScope) (parameters : List PsVerifiedIrType)
      (arguments : List PsVerifiedIrExpr) (index : Nat)
  | lambdaResult (type : PsVerifiedIrType)
  | ifThen (scope : PsIrCheckScope) (elseBranch : PsVerifiedIrExpr)
      (expected : Option PsVerifiedIrType)
  | ifResult (scope : PsIrCheckScope) (thenValue : PsIrCheckValue)
  | alternatives (plan : PsIrCheckMatchPlan)
      (alternatives : List (String × List PsVerifiedIrMatchBinding × PsVerifiedIrExpr))
      (common : Option PsVerifiedIrType) (index : Nat)
  | alternativeResult (plan : PsIrCheckMatchPlan)
      (alternatives : List (String × List PsVerifiedIrMatchBinding × PsVerifiedIrExpr))
      (common : Option PsVerifiedIrType) (index : Nat)
  | fields (scope : PsIrCheckScope) (substitutions : List (String × PsVerifiedIrType))
      (expected : List PsVerifiedIrParameter)
      (actual : List (String × PsVerifiedIrExpr)) (seen : List String)
  | imports (remaining : List PsVerifiedIrExternalImport) (seen : List String)
  | declarations (remaining : List PsVerifiedIrDeclaration) (seen : List String)
  | structures (remaining : List PsVerifiedIrStructure)
      (inductives : List PsVerifiedIrInductive) (seen : List String)
  | inductives (remaining : List PsVerifiedIrInductive) (seen : List String)
  | constructors (scope : PsIrCheckScope)
      (remaining : List PsVerifiedIrConstructor) (seen : List String)
  | parameterTypes (scope : PsIrCheckScope)
      (remaining : List PsVerifiedIrParameter) (seen : List String)

structure PsIrCheckState where
  tasks : List PsIrCheckTask
  values : List PsIrCheckValue
  visitedSteps : Nat
  expressionCount : Nat
  findingCount : Nat
  findingsRev : List PsIrCheckFinding
  traversalComplete : Bool

def psIrCheckAt (scope : PsIrCheckScope) (part : String) : PsIrCheckScope :=
  PsIrCheckScope.mk scope.owner
    (String.Internal.append (String.Internal.append scope.path "/") part)
    scope.typeScope scope.bindings

def psIrCheckIndex (scope : PsIrCheckScope) (part : String) (index : Nat) :
    PsIrCheckScope :=
  psIrCheckAt scope (String.Internal.append part (psNatToString index))

def psIrCheckScopeRoot (owner : String) (typeScope : List String)
    (bindings : List PsVerifiedIrParameter) : PsIrCheckScope :=
  PsIrCheckScope.mk owner "root" typeScope bindings

def psIrCheckHasName (names : List String) (name : String) : Bool :=
  match names with
  | List.nil => false
  | List.cons current rest =>
      if psStringEq current name then true else psIrCheckHasName rest name

def psIrCheckFindParameter (parameters : List PsVerifiedIrParameter) (name : String) :
    Option PsVerifiedIrParameter :=
  match parameters with
  | List.nil => Option.none
  | List.cons parameter rest =>
      if psStringEq parameter.name name then Option.some parameter
      else psIrCheckFindParameter rest name

def psIrCheckFindDeclaration (declarations : List PsVerifiedIrDeclaration) (name : String) :
    Option PsVerifiedIrDeclaration :=
  match declarations with
  | List.nil => Option.none
  | List.cons declaration rest =>
      if psStringEq declaration.name name then Option.some declaration
      else psIrCheckFindDeclaration rest name

def psIrCheckFindImport (imports : List PsVerifiedIrExternalImport) (name : String) :
    Option PsVerifiedIrExternalImport :=
  match imports with
  | List.nil => Option.none
  | List.cons entry rest =>
      if psStringEq entry.localName name then Option.some entry
      else psIrCheckFindImport rest name

def psIrCheckFindStructure (structures : List PsVerifiedIrStructure) (name : String) :
    Option PsVerifiedIrStructure :=
  match structures with
  | List.nil => Option.none
  | List.cons layout rest =>
      if psStringEq layout.name name then Option.some layout
      else psIrCheckFindStructure rest name

def psIrCheckFindInductive (inductives : List PsVerifiedIrInductive) (name : String) :
    Option PsVerifiedIrInductive :=
  match inductives with
  | List.nil => Option.none
  | List.cons layout rest =>
      if psStringEq layout.name name then Option.some layout
      else psIrCheckFindInductive rest name

def psIrCheckFindConstructor (constructors : List PsVerifiedIrConstructor) (name : String) :
    Option PsVerifiedIrConstructor :=
  match constructors with
  | List.nil => Option.none
  | List.cons ctorInfo rest =>
      if psStringEq ctorInfo.name name then Option.some ctorInfo
      else psIrCheckFindConstructor rest name

def psIrCheckTypeParameterNames (parameters : List PsVerifiedIrTypeParameter) : List String :=
  psListMap (fun (parameter : PsVerifiedIrTypeParameter) => parameter.name) parameters

def psIrCheckParameterTypes (parameters : List PsVerifiedIrParameter) : List PsVerifiedIrType :=
  psListMap (fun (parameter : PsVerifiedIrParameter) => parameter.type) parameters

def psIrCheckStructureParameters (fields : List PsVerifiedIrStructureField) :
    List PsVerifiedIrParameter :=
  psListMap
    (fun (field : PsVerifiedIrStructureField) => PsVerifiedIrParameter.mk field.name field.type)
    fields

def psIrCheckConstructorParameters (fields : List PsVerifiedIrConstructorField) :
    List PsVerifiedIrParameter :=
  psListMap
    (fun (field : PsVerifiedIrConstructorField) => PsVerifiedIrParameter.mk field.name field.type)
    fields

def psIrCheckNamedArity (module : PsVerifiedIrModule) (name : String) : Option Nat :=
  if psStringEq name "Array" then Option.some 1
  else
    match psIrCheckFindStructure module.structures name with
    | Option.some layout => Option.some (psListLength layout.typeParameters)
    | Option.none =>
        match psIrCheckFindInductive module.inductives name with
        | Option.some layout => Option.some (psListLength layout.typeParameters)
        | Option.none => Option.none

def psIrCheckSetTasks (state : PsIrCheckState) (tasks : List PsIrCheckTask) : PsIrCheckState :=
  PsIrCheckState.mk tasks state.values state.visitedSteps state.expressionCount
    state.findingCount state.findingsRev state.traversalComplete

def psIrCheckSetValues (state : PsIrCheckState) (values : List PsIrCheckValue) : PsIrCheckState :=
  PsIrCheckState.mk state.tasks values state.visitedSteps state.expressionCount
    state.findingCount state.findingsRev state.traversalComplete

def psIrCheckPush (state : PsIrCheckState) (value : PsIrCheckValue) : PsIrCheckState :=
  psIrCheckSetValues state (List.cons value state.values)

def psIrCheckSchedule (state : PsIrCheckState) (tasks : List PsIrCheckTask) : PsIrCheckState :=
  psIrCheckSetTasks state (psListAppend tasks state.tasks)

def psIrCheckFinding (options : PsIrCheckOptions) (state : PsIrCheckState)
    (scope : PsIrCheckScope) (code detail : String)
    (expected actual : Option PsVerifiedIrType) : PsIrCheckState :=
  let finding := PsIrCheckFinding.mk code detail scope.owner scope.path expected actual;
  let findings :=
    if Nat.blt state.findingCount options.maxFindings then
      List.cons finding state.findingsRev
    else state.findingsRev;
  PsIrCheckState.mk state.tasks state.values state.visitedSteps state.expressionCount
    (Nat.succ state.findingCount) findings state.traversalComplete

def psIrCheckRecordIssue (options : PsIrCheckOptions) (state : PsIrCheckState)
    (scope : PsIrCheckScope) (issue : PsIrCheckIssue) : PsIrCheckState :=
  let failed := psIrCheckFinding options state scope issue.code issue.detail Option.none Option.none;
  if psStringEq issue.code "type-resource-limit" then
    PsIrCheckState.mk failed.tasks failed.values failed.visitedSteps failed.expressionCount
      failed.findingCount failed.findingsRev false
  else failed

def psIrCheckInternal (options : PsIrCheckOptions) (state : PsIrCheckState) : PsIrCheckState :=
  let failed := psIrCheckFinding options state
    (psIrCheckScopeRoot "module" List.nil List.nil)
    "checker-internal-state" "invalid continuation stack" Option.none Option.none;
  PsIrCheckState.mk List.nil List.nil failed.visitedSteps failed.expressionCount
    failed.findingCount failed.findingsRev false

def psIrCheckAnnotation (options : PsIrCheckOptions) (module : PsVerifiedIrModule)
    (state : PsIrCheckState) (scope : PsIrCheckScope) (type : PsVerifiedIrType) :
    PsIrCheckState :=
  match psIrCheckType options.maxTypeSteps (psIrCheckNamedArity module) scope.typeScope type with
  | Except.ok _ => state
  | Except.error issue => psIrCheckRecordIssue options state scope issue

def psIrCheckTypeArguments (options : PsIrCheckOptions) (module : PsVerifiedIrModule)
    (types : List PsVerifiedIrType) (scope : PsIrCheckScope) (index : Nat)
    (state : PsIrCheckState) : PsIrCheckState :=
  match types with
  | List.nil => state
  | List.cons type rest =>
      psIrCheckTypeArguments options module rest scope (Nat.succ index)
        (psIrCheckAnnotation options module state (psIrCheckIndex scope "typeArgument" index) type)

def psIrCheckNames (options : PsIrCheckOptions) (names : List String)
    (scope : PsIrCheckScope) (code : String) (seen : List String) (state : PsIrCheckState) :
    PsIrCheckState :=
  match names with
  | List.nil => state
  | List.cons name rest =>
      let checked :=
        if Nat.beq (String.utf8ByteSize name) 0 then
          psIrCheckFinding options state scope "empty-name" code Option.none Option.none
        else
          if psIrCheckHasName seen name then
            psIrCheckFinding options state scope code name Option.none Option.none
          else state;
      psIrCheckNames options rest scope code (List.cons name seen) checked

def psIrCheckCompare (options : PsIrCheckOptions) (state : PsIrCheckState)
    (scope : PsIrCheckScope) (expected actual : PsVerifiedIrType) : PsIrCheckState :=
  match psIrCheckTypeEqual options.maxTypeSteps expected actual with
  | Except.error issue => psIrCheckRecordIssue options state scope issue
  | Except.ok same =>
      if same then state
      else psIrCheckFinding options state scope "type-mismatch" "runtime types differ"
        (Option.some expected) (Option.some actual)

def psIrCheckArity (options : PsIrCheckOptions) (state : PsIrCheckState)
    (scope : PsIrCheckScope) (code : String) (expected actual : Nat) : PsIrCheckState :=
  if Nat.beq expected actual then state
  else psIrCheckFinding options state scope code
    (String.Internal.append
      (String.Internal.append (String.Internal.append "expected " (psNatToString expected)) ", actual ")
      (psNatToString actual)) Option.none Option.none

def psIrCheckValueType (value : PsIrCheckValue) : Option PsVerifiedIrType :=
  match value with
  | PsIrCheckValue.mono type => Option.some type
  | _ => Option.none

def psIrCheckChooseExpected (value : PsIrCheckValue) (fallback : Option PsVerifiedIrType) :
    Option PsVerifiedIrType :=
  match value with
  | PsIrCheckValue.mono type => Option.some type
  | _ => fallback

def psIrCheckGlobalValue (declaration : PsVerifiedIrDeclaration) : PsIrCheckValue :=
  if psListIsEmpty declaration.parameters then
    if psListIsEmpty declaration.typeParameters then PsIrCheckValue.mono declaration.resultType
    else PsIrCheckValue.invalid
  else
    let type := PsVerifiedIrType.function
      (psIrCheckParameterTypes declaration.parameters) declaration.resultType;
    if psListIsEmpty declaration.typeParameters then PsIrCheckValue.mono type
    else PsIrCheckValue.scheme (psIrCheckTypeParameterNames declaration.typeParameters) type

def psIrCheckMissingFields (options : PsIrCheckOptions)
    (fields : List PsVerifiedIrParameter) (seen : List String)
    (scope : PsIrCheckScope) (state : PsIrCheckState) : PsIrCheckState :=
  match fields with
  | List.nil => state
  | List.cons field rest =>
      let checked :=
        if psIrCheckHasName seen field.name then state
        else psIrCheckFinding options state scope "missing-field" field.name Option.none Option.none;
      psIrCheckMissingFields options rest seen scope checked

def psIrCheckFieldOrder (expected : List PsVerifiedIrParameter)
    (actual : List (String × PsVerifiedIrExpr)) : Bool :=
  match expected with
  | List.nil => psListIsEmpty actual
  | List.cons field rest =>
      match actual with
      | List.nil => false
      | List.cons value values =>
          if psStringEq field.name value.fst then psIrCheckFieldOrder rest values else false

def psIrCheckMissingAlternatives (options : PsIrCheckOptions)
    (constructors : List PsVerifiedIrConstructor) (names : List String)
    (scope : PsIrCheckScope) (state : PsIrCheckState) : PsIrCheckState :=
  match constructors with
  | List.nil => state
  | List.cons ctorInfo rest =>
      let checked :=
        if psIrCheckHasName names ctorInfo.name then state
        else psIrCheckFinding options state scope "match-coverage" ctorInfo.name Option.none Option.none;
      psIrCheckMissingAlternatives options rest names scope checked

def psIrCheckMatchBindings (options : PsIrCheckOptions) (module : PsVerifiedIrModule)
    (bindings : List PsVerifiedIrMatchBinding) (fields : List PsVerifiedIrParameter)
    (substitutions : List (String × PsVerifiedIrType)) (scope : PsIrCheckScope)
    (seenFields seenNames : List String) (state : PsIrCheckState) : PsIrCheckState :=
  match bindings with
  | List.nil => state
  | List.cons binding rest =>
      let location := psIrCheckAt scope (String.Internal.append "binding:" binding.name);
      let annotated := psIrCheckAnnotation options module state location binding.type;
      let fieldUnique :=
        if psIrCheckHasName seenFields binding.field then
          psIrCheckFinding options annotated location "duplicate-match-field" binding.field Option.none Option.none
        else annotated;
      let nameUnique :=
        psIrCheckNames options (List.cons binding.name List.nil) location
          "duplicate-binder" seenNames fieldUnique;
      let checked :=
        match psIrCheckFindParameter fields binding.field with
        | Option.none =>
            psIrCheckFinding options nameUnique location "unresolved-match-field" binding.field Option.none Option.none
        | Option.some field =>
            match psIrCheckSubstitute options.maxTypeSteps substitutions field.type with
            | Except.error issue => psIrCheckRecordIssue options nameUnique location issue
            | Except.ok expected => psIrCheckCompare options nameUnique location expected binding.type;
      psIrCheckMatchBindings options module rest fields substitutions scope
        (List.cons binding.field seenFields) (List.cons binding.name seenNames) checked

def psIrCheckReadVariable (options : PsIrCheckOptions) (module : PsVerifiedIrModule)
    (state : PsIrCheckState) (scope : PsIrCheckScope) (name : String) : PsIrCheckState :=
  match psIrCheckFindParameter scope.bindings name with
  | Option.some parameter => psIrCheckPush state (PsIrCheckValue.mono parameter.type)
  | Option.none =>
      match psIrCheckFindDeclaration module.declarations name with
      | Option.some declaration => psIrCheckPush state (psIrCheckGlobalValue declaration)
      | Option.none =>
          match psIrCheckFindImport module.imports name with
          | Option.some entry => psIrCheckPush state (PsIrCheckValue.mono entry.type)
          | Option.none =>
              psIrCheckPush
                (psIrCheckFinding options state scope "unresolved-value-name" name Option.none Option.none)
                PsIrCheckValue.invalid

def psIrCheckApplyFunction (options : PsIrCheckOptions) (state : PsIrCheckState)
    (scope : PsIrCheckScope) (type : PsVerifiedIrType)
    (arguments : List PsVerifiedIrExpr) : PsIrCheckState :=
  match type with
  | PsVerifiedIrType.function parameters result =>
      let checked := psIrCheckArity options state scope "call-runtime-arity"
        (psListLength parameters) (psListLength arguments);
      psIrCheckSchedule checked
        [PsIrCheckTask.arguments scope parameters arguments 0,
         PsIrCheckTask.yieldValue (PsIrCheckValue.mono result)]
  | _ =>
      let checked := psIrCheckFinding options state scope "non-function-callee"
        "callee must have a runtime function type" Option.none (Option.some type);
      psIrCheckSchedule checked
        [PsIrCheckTask.arguments scope List.nil arguments 0,
         PsIrCheckTask.yieldValue PsIrCheckValue.invalid]

def psIrCheckCallee (options : PsIrCheckOptions) (state : PsIrCheckState)
    (scope : PsIrCheckScope) (value : PsIrCheckValue)
    (typeArguments : List PsVerifiedIrType) (arguments : List PsVerifiedIrExpr) : PsIrCheckState :=
  match value with
  | PsIrCheckValue.invalid =>
      psIrCheckSchedule state
        [PsIrCheckTask.arguments scope List.nil arguments 0,
         PsIrCheckTask.yieldValue PsIrCheckValue.invalid]
  | PsIrCheckValue.mono type =>
      let checked := psIrCheckArity options state scope "call-type-arity" 0
        (psListLength typeArguments);
      psIrCheckApplyFunction options checked scope type arguments
  | PsIrCheckValue.scheme binders type =>
      let checked := psIrCheckArity options state scope "call-type-arity"
        (psListLength binders) (psListLength typeArguments);
      if Nat.beq (psListLength binders) (psListLength typeArguments) then
        match psIrCheckSubstitute options.maxTypeSteps (psListZip binders typeArguments) type with
        | Except.error issue =>
            psIrCheckSchedule (psIrCheckRecordIssue options checked scope issue)
              [PsIrCheckTask.arguments scope List.nil arguments 0,
               PsIrCheckTask.yieldValue PsIrCheckValue.invalid]
        | Except.ok instantiated => psIrCheckApplyFunction options checked scope instantiated arguments
      else
        psIrCheckSchedule checked
          [PsIrCheckTask.arguments scope List.nil arguments 0,
           PsIrCheckTask.yieldValue PsIrCheckValue.invalid]

def psIrCheckRecord (options : PsIrCheckOptions) (module : PsVerifiedIrModule)
    (state : PsIrCheckState) (scope : PsIrCheckScope) (name : String)
    (typeArguments : List PsVerifiedIrType) (fields : List (String × PsVerifiedIrExpr)) :
    PsIrCheckState :=
  let annotated := psIrCheckTypeArguments options module typeArguments scope 0 state;
  match psIrCheckFindStructure module.structures name with
  | Option.none =>
      psIrCheckSchedule
        (psIrCheckFinding options annotated scope "unresolved-layout-owner" name Option.none Option.none)
        [PsIrCheckTask.fields scope List.nil List.nil fields List.nil,
         PsIrCheckTask.yieldValue PsIrCheckValue.invalid]
  | Option.some layout =>
      let checked := psIrCheckArity options annotated scope "layout-type-arity"
        (psListLength layout.typeParameters) (psListLength typeArguments);
      psIrCheckSchedule checked
        [PsIrCheckTask.fields scope
           (psListZip (psIrCheckTypeParameterNames layout.typeParameters) typeArguments)
           (psIrCheckStructureParameters layout.fields) fields List.nil,
         PsIrCheckTask.yieldValue (PsIrCheckValue.mono (PsVerifiedIrType.named name typeArguments))]

def psIrCheckConstructor (options : PsIrCheckOptions) (module : PsVerifiedIrModule)
    (state : PsIrCheckState) (scope : PsIrCheckScope) (name constructorName : String)
    (typeArguments : List PsVerifiedIrType) (fields : List (String × PsVerifiedIrExpr)) :
    PsIrCheckState :=
  let annotated := psIrCheckTypeArguments options module typeArguments scope 0 state;
  match psIrCheckFindInductive module.inductives name with
  | Option.none =>
      psIrCheckSchedule
        (psIrCheckFinding options annotated scope "unresolved-layout-owner" name Option.none Option.none)
        [PsIrCheckTask.fields scope List.nil List.nil fields List.nil,
         PsIrCheckTask.yieldValue PsIrCheckValue.invalid]
  | Option.some layout =>
      let arity := psIrCheckArity options annotated scope "layout-type-arity"
        (psListLength layout.typeParameters) (psListLength typeArguments);
      match psIrCheckFindConstructor layout.constructors constructorName with
      | Option.none =>
          psIrCheckSchedule
            (psIrCheckFinding options arity scope "unresolved-constructor" constructorName Option.none Option.none)
            [PsIrCheckTask.fields scope List.nil List.nil fields List.nil,
             PsIrCheckTask.yieldValue PsIrCheckValue.invalid]
      | Option.some ctorInfo =>
          let expected := psIrCheckConstructorParameters ctorInfo.fields;
          let checked :=
            if psIrCheckFieldOrder expected fields then arity
            else psIrCheckFinding options arity scope "constructor-field-order"
              constructorName Option.none Option.none;
          psIrCheckSchedule checked
            [PsIrCheckTask.fields scope
               (psListZip (psIrCheckTypeParameterNames layout.typeParameters) typeArguments)
               expected fields List.nil,
             PsIrCheckTask.yieldValue (PsIrCheckValue.mono (PsVerifiedIrType.named name typeArguments))]

def psIrCheckProjection (options : PsIrCheckOptions) (module : PsVerifiedIrModule)
    (state : PsIrCheckState) (scope : PsIrCheckScope) (name : String)
    (typeArguments : List PsVerifiedIrType) (target : PsVerifiedIrExpr) (fieldName : String) :
    PsIrCheckState :=
  let annotated := psIrCheckTypeArguments options module typeArguments scope 0 state;
  let ownerType := PsVerifiedIrType.named name typeArguments;
  let checked :=
    match psIrCheckFindStructure module.structures name with
    | Option.none =>
        Prod.mk
          (psIrCheckFinding options annotated scope "unresolved-layout-owner" name Option.none Option.none)
          PsIrCheckValue.invalid
    | Option.some layout =>
        let arity := psIrCheckArity options annotated scope "layout-type-arity"
          (psListLength layout.typeParameters) (psListLength typeArguments);
        match psIrCheckFindParameter (psIrCheckStructureParameters layout.fields) fieldName with
        | Option.none =>
            Prod.mk
              (psIrCheckFinding options arity scope "unresolved-projection-field" fieldName Option.none Option.none)
              PsIrCheckValue.invalid
        | Option.some field =>
            match psIrCheckSubstitute options.maxTypeSteps
                (psListZip (psIrCheckTypeParameterNames layout.typeParameters) typeArguments) field.type with
            | Except.error issue =>
                Prod.mk (psIrCheckRecordIssue options arity scope issue) PsIrCheckValue.invalid
            | Except.ok type => Prod.mk arity (PsIrCheckValue.mono type);
  psIrCheckSchedule checked.fst
    [PsIrCheckTask.expression (psIrCheckAt scope "target") target (Option.some ownerType) false,
     PsIrCheckTask.discard, PsIrCheckTask.yieldValue checked.snd]

def psIrCheckMatch (options : PsIrCheckOptions) (module : PsVerifiedIrModule)
    (state : PsIrCheckState) (scope : PsIrCheckScope) (name : String)
    (typeArguments : List PsVerifiedIrType) (scrutinee : PsVerifiedIrExpr)
    (alternatives : List (String × List PsVerifiedIrMatchBinding × PsVerifiedIrExpr))
    (_expected : Option PsVerifiedIrType) : PsIrCheckState :=
  let annotated := psIrCheckTypeArguments options module typeArguments scope 0 state;
  let names := psListMap
    (fun (alternative : String × List PsVerifiedIrMatchBinding × PsVerifiedIrExpr) => alternative.fst)
    alternatives;
  let unique := psIrCheckNames options names scope "duplicate-match-alternative" List.nil annotated;
  let nonempty :=
    if psListIsEmpty alternatives then
      psIrCheckFinding options unique scope "empty-match-unsupported"
        "empty elimination is outside the active runtime contract" Option.none Option.none
    else unique;
  let layoutResult :=
    match psIrCheckFindInductive module.inductives name with
    | Option.none =>
        Prod.mk
          (psIrCheckFinding options nonempty scope "unresolved-layout-owner" name Option.none Option.none)
          (PsIrCheckMatchPlan.mk scope List.nil List.nil)
    | Option.some layout =>
        let arity := psIrCheckArity options nonempty scope "layout-type-arity"
          (psListLength layout.typeParameters) (psListLength typeArguments);
        let covered := psIrCheckMissingAlternatives options layout.constructors names scope arity;
        Prod.mk covered
          (PsIrCheckMatchPlan.mk scope
            (psListZip (psIrCheckTypeParameterNames layout.typeParameters) typeArguments)
            layout.constructors);
  psIrCheckSchedule layoutResult.fst
    [PsIrCheckTask.expression (psIrCheckAt scope "scrutinee") scrutinee
       (Option.some (PsVerifiedIrType.named name typeArguments)) false,
     PsIrCheckTask.discard,
     PsIrCheckTask.alternatives layoutResult.snd alternatives Option.none 0]

def psIrCheckExpression (options : PsIrCheckOptions) (module : PsVerifiedIrModule)
    (state : PsIrCheckState) (scope : PsIrCheckScope) (expr : PsVerifiedIrExpr)
    (expected : Option PsVerifiedIrType) (allowScheme : Bool) : PsIrCheckState :=
  let counted := PsIrCheckState.mk state.tasks state.values state.visitedSteps
    (Nat.succ state.expressionCount) state.findingCount state.findingsRev state.traversalComplete;
  let next := psIrCheckSchedule counted [PsIrCheckTask.expect scope expected allowScheme];
  match expr with
  | PsVerifiedIrExpr.literal literal =>
      match psIrCheckLiteralType literal with
      | Except.error issue => psIrCheckPush (psIrCheckRecordIssue options next scope issue) PsIrCheckValue.invalid
      | Except.ok type => psIrCheckPush next (PsIrCheckValue.mono type)
  | PsVerifiedIrExpr.var name => psIrCheckReadVariable options module next scope name
  | PsVerifiedIrExpr.intrinsic operation typeArguments arguments =>
      let annotated := psIrCheckTypeArguments options module typeArguments scope 0 next;
      match psIrCheckIntrinsicSignature operation typeArguments with
      | Except.error issue =>
          psIrCheckSchedule (psIrCheckRecordIssue options annotated scope issue)
            [PsIrCheckTask.arguments scope List.nil arguments 0,
             PsIrCheckTask.yieldValue PsIrCheckValue.invalid]
      | Except.ok signature =>
          let checked := psIrCheckArity options annotated scope "intrinsic-runtime-arity"
            (psListLength signature.parameters) (psListLength arguments);
          psIrCheckSchedule checked
            [PsIrCheckTask.arguments scope signature.parameters arguments 0,
             PsIrCheckTask.yieldValue (PsIrCheckValue.mono signature.resultType)]
  | PsVerifiedIrExpr.lambda parameters resultType body =>
      let annotated := psIrCheckAnnotation options module next (psIrCheckAt scope "resultType") resultType;
      let bodyScope := PsIrCheckScope.mk scope.owner
        (String.Internal.append scope.path "/body") scope.typeScope
        (psListAppend parameters scope.bindings);
      psIrCheckSchedule annotated
        [PsIrCheckTask.parameterTypes (psIrCheckAt scope "parameters") parameters List.nil,
         PsIrCheckTask.expression bodyScope body (Option.some resultType) false,
         PsIrCheckTask.lambdaResult
           (PsVerifiedIrType.function (psIrCheckParameterTypes parameters) resultType)]
  | PsVerifiedIrExpr.call fn typeArguments arguments =>
      let annotated := psIrCheckTypeArguments options module typeArguments scope 0 next;
      psIrCheckSchedule annotated
        [PsIrCheckTask.expression (psIrCheckAt scope "callee") fn Option.none true,
         PsIrCheckTask.callCallee scope typeArguments arguments]
  | PsVerifiedIrExpr.letE name type value body =>
      let annotated := psIrCheckAnnotation options module next (psIrCheckAt scope "letType") type;
      let named := psIrCheckNames options [name] scope "duplicate-binder" List.nil annotated;
      let bodyScope := PsIrCheckScope.mk scope.owner
        (String.Internal.append scope.path "/body") scope.typeScope
        (List.cons (PsVerifiedIrParameter.mk name type) scope.bindings);
      psIrCheckSchedule named
        [PsIrCheckTask.expression (psIrCheckAt scope "initializer") value (Option.some type) false,
         PsIrCheckTask.discard,
         PsIrCheckTask.expression bodyScope body Option.none false]
  | PsVerifiedIrExpr.ifE condition thenBranch elseBranch =>
      psIrCheckSchedule next
        [PsIrCheckTask.expression (psIrCheckAt scope "condition") condition
           (Option.some (PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.bool)) false,
         PsIrCheckTask.discard,
         PsIrCheckTask.expression (psIrCheckAt scope "then") thenBranch Option.none false,
         PsIrCheckTask.ifThen scope elseBranch expected]
  | PsVerifiedIrExpr.record name typeArguments fields =>
      psIrCheckRecord options module next scope name typeArguments fields
  | PsVerifiedIrExpr.constructor name constructorName typeArguments fields =>
      psIrCheckConstructor options module next scope name constructorName typeArguments fields
  | PsVerifiedIrExpr.projection name typeArguments target field =>
      psIrCheckProjection options module next scope name typeArguments target field
  | PsVerifiedIrExpr.matchE name typeArguments scrutinee alternatives =>
      psIrCheckMatch options module next scope name typeArguments scrutinee alternatives expected

def psIrCheckAlternative (options : PsIrCheckOptions) (module : PsVerifiedIrModule)
    (state : PsIrCheckState) (plan : PsIrCheckMatchPlan)
    (alternative : String × List PsVerifiedIrMatchBinding × PsVerifiedIrExpr)
    (remaining : List (String × List PsVerifiedIrMatchBinding × PsVerifiedIrExpr))
    (common : Option PsVerifiedIrType) (index : Nat) : PsIrCheckState :=
  let scope := psIrCheckAt (psIrCheckIndex plan.scope "alternative" index) alternative.fst;
  let bindings := alternative.snd.fst;
  let fields : PsIrCheckState × List PsVerifiedIrParameter :=
    match psIrCheckFindConstructor plan.constructors alternative.fst with
    | Option.none =>
        Prod.mk
          (psIrCheckFinding options state scope "unexpected-match-alternative" alternative.fst Option.none Option.none)
          List.nil
    | Option.some ctorInfo =>
        Prod.mk state (psIrCheckConstructorParameters ctorInfo.fields);
  let checked := psIrCheckMatchBindings options module bindings fields.snd
    plan.substitutions scope List.nil List.nil fields.fst;
  let parameters := psListMap
    (fun (binding : PsVerifiedIrMatchBinding) => PsVerifiedIrParameter.mk binding.name binding.type)
    bindings;
  let bodyScope := PsIrCheckScope.mk scope.owner
    (String.Internal.append scope.path "/body") scope.typeScope
    (psListAppend parameters scope.bindings);
  psIrCheckSchedule checked
    [PsIrCheckTask.expression bodyScope alternative.snd.snd common false,
     PsIrCheckTask.alternativeResult plan remaining common (Nat.succ index)]

def psIrCheckStep (options : PsIrCheckOptions) (module : PsVerifiedIrModule)
    (task : PsIrCheckTask) (state : PsIrCheckState) : PsIrCheckState :=
  match task with
  | PsIrCheckTask.expression scope expr expected allowScheme =>
      psIrCheckExpression options module state scope expr expected allowScheme
  | PsIrCheckTask.expect scope expected allowScheme =>
      match state.values with
      | List.nil => psIrCheckInternal options state
      | List.cons value values =>
          match value with
          | PsIrCheckValue.invalid => state
          | PsIrCheckValue.scheme _ _ =>
              if allowScheme then state
              else psIrCheckPush
                (psIrCheckFinding options (psIrCheckSetValues state values) scope
                  "generic-value-reference" "generic values require direct explicit instantiation"
                  expected Option.none) PsIrCheckValue.invalid
          | PsIrCheckValue.mono actual =>
              match expected with
              | Option.none => state
              | Option.some wanted => psIrCheckCompare options state scope wanted actual
  | PsIrCheckTask.discard =>
      match state.values with
      | List.nil => psIrCheckInternal options state
      | List.cons _ values => psIrCheckSetValues state values
  | PsIrCheckTask.yieldValue value => psIrCheckPush state value
  | PsIrCheckTask.callCallee scope typeArguments arguments =>
      match state.values with
      | List.nil => psIrCheckInternal options state
      | List.cons value values =>
          psIrCheckCallee options (psIrCheckSetValues state values) scope value typeArguments arguments
  | PsIrCheckTask.arguments scope parameters arguments index =>
      match arguments with
      | List.nil => state
      | List.cons argument rest =>
          let parameter : Option PsVerifiedIrType × List PsVerifiedIrType :=
            match parameters with
            | List.nil => Prod.mk Option.none List.nil
            | List.cons type types => Prod.mk (Option.some type) types;
          psIrCheckSchedule state
            [PsIrCheckTask.expression (psIrCheckIndex scope "argument" index) argument parameter.fst false,
             PsIrCheckTask.discard,
             PsIrCheckTask.arguments scope parameter.snd rest (Nat.succ index)]
  | PsIrCheckTask.lambdaResult type =>
      match state.values with
      | List.nil => psIrCheckInternal options state
      | List.cons _ values =>
          psIrCheckPush (psIrCheckSetValues state values) (PsIrCheckValue.mono type)
  | PsIrCheckTask.ifThen scope elseBranch expected =>
      match state.values with
      | List.nil => psIrCheckInternal options state
      | List.cons value values =>
          psIrCheckSchedule (psIrCheckSetValues state values)
            [PsIrCheckTask.expression (psIrCheckAt scope "else") elseBranch
               (psIrCheckChooseExpected value expected) false,
             PsIrCheckTask.ifResult scope value]
  | PsIrCheckTask.ifResult scope thenValue =>
      match state.values with
      | List.nil => psIrCheckInternal options state
      | List.cons elseValue values =>
          let remaining := psIrCheckSetValues state values;
          match thenValue with
          | PsIrCheckValue.mono type => psIrCheckPush remaining (PsIrCheckValue.mono type)
          | _ => psIrCheckPush remaining elseValue
  | PsIrCheckTask.alternatives plan alternatives common index =>
      match alternatives with
      | List.nil =>
          match common with
          | Option.none => psIrCheckPush state PsIrCheckValue.invalid
          | Option.some type => psIrCheckPush state (PsIrCheckValue.mono type)
      | List.cons alternative rest =>
          psIrCheckAlternative options module state plan alternative rest common index
  | PsIrCheckTask.alternativeResult plan alternatives common index =>
      match state.values with
      | List.nil => psIrCheckInternal options state
      | List.cons value values =>
          let expected :=
            match common with
            | Option.some type => Option.some type
            | Option.none => psIrCheckValueType value;
          psIrCheckSchedule (psIrCheckSetValues state values)
            [PsIrCheckTask.alternatives plan alternatives expected index]
  | PsIrCheckTask.fields scope substitutions expected actual seen =>
      match actual with
      | List.nil => psIrCheckMissingFields options expected seen scope state
      | List.cons field rest =>
          let location := psIrCheckAt scope (String.Internal.append "field:" field.fst);
          let unique := psIrCheckNames options [field.fst] location "duplicate-field" seen state;
          let fieldType : PsIrCheckState × Option PsVerifiedIrType :=
            match psIrCheckFindParameter expected field.fst with
            | Option.none =>
                Prod.mk
                  (psIrCheckFinding options unique location "unexpected-field" field.fst Option.none Option.none)
                  Option.none
            | Option.some parameter =>
                match psIrCheckSubstitute options.maxTypeSteps substitutions parameter.type with
                | Except.error issue =>
                    Prod.mk (psIrCheckRecordIssue options unique location issue) Option.none
                | Except.ok type => Prod.mk unique (Option.some type);
          psIrCheckSchedule fieldType.fst
            [PsIrCheckTask.expression location field.snd fieldType.snd false,
             PsIrCheckTask.discard,
             PsIrCheckTask.fields scope substitutions expected rest (List.cons field.fst seen)]
  | PsIrCheckTask.imports remaining seen =>
      match remaining with
      | List.nil => state
      | List.cons entry rest =>
          let scope := psIrCheckScopeRoot entry.localName List.nil List.nil;
          let named := psIrCheckNames options [entry.localName] scope "duplicate-value-name" seen state;
          let annotated := psIrCheckAnnotation options module named scope entry.type;
          let failed := psIrCheckFinding options annotated scope "external-import-abi-unqualified"
            entry.source Option.none Option.none;
          psIrCheckSchedule failed [PsIrCheckTask.imports rest (List.cons entry.localName seen)]
  | PsIrCheckTask.declarations remaining seen =>
      match remaining with
      | List.nil => state
      | List.cons declaration rest =>
          let types := psIrCheckTypeParameterNames declaration.typeParameters;
          let scope := psIrCheckScopeRoot declaration.name types declaration.parameters;
          let named := psIrCheckNames options [declaration.name] scope "duplicate-value-name" seen state;
          let scopeChecked := psIrCheckNames options types scope "duplicate-type-parameter" List.nil named;
          let annotated := psIrCheckAnnotation options module scopeChecked
            (psIrCheckAt scope "resultType") declaration.resultType;
          let checked :=
            if psListIsEmpty declaration.parameters then
              if psListIsEmpty declaration.typeParameters then annotated
              else psIrCheckFinding options annotated scope "generic-value-unsupported"
                declaration.name Option.none Option.none
            else annotated;
          psIrCheckSchedule checked
            [PsIrCheckTask.parameterTypes (psIrCheckAt scope "parameters") declaration.parameters List.nil,
             PsIrCheckTask.expression (psIrCheckAt scope "body") declaration.body
               (Option.some declaration.resultType) false,
             PsIrCheckTask.discard,
             PsIrCheckTask.declarations rest (List.cons declaration.name seen)]
  | PsIrCheckTask.structures remaining inductives seen =>
      match remaining with
      | List.nil => psIrCheckSchedule state [PsIrCheckTask.inductives inductives seen]
      | List.cons layout rest =>
          let types := psIrCheckTypeParameterNames layout.typeParameters;
          let scope := psIrCheckScopeRoot layout.name types List.nil;
          let named := psIrCheckNames options [layout.name] scope "duplicate-layout-name" seen state;
          let scopeChecked := psIrCheckNames options types scope "duplicate-type-parameter" List.nil named;
          psIrCheckSchedule scopeChecked
            [PsIrCheckTask.parameterTypes (psIrCheckAt scope "fields")
               (psIrCheckStructureParameters layout.fields) List.nil,
             PsIrCheckTask.structures rest inductives (List.cons layout.name seen)]
  | PsIrCheckTask.inductives remaining seen =>
      match remaining with
      | List.nil => state
      | List.cons layout rest =>
          let types := psIrCheckTypeParameterNames layout.typeParameters;
          let scope := psIrCheckScopeRoot layout.name types List.nil;
          let named := psIrCheckNames options [layout.name] scope "duplicate-layout-name" seen state;
          let scopeChecked := psIrCheckNames options types scope "duplicate-type-parameter" List.nil named;
          let checked :=
            if psListIsEmpty layout.constructors then
              psIrCheckFinding options scopeChecked scope "empty-layout-unsupported"
                layout.name Option.none Option.none
            else scopeChecked;
          psIrCheckSchedule checked
            [PsIrCheckTask.constructors scope layout.constructors List.nil,
             PsIrCheckTask.inductives rest (List.cons layout.name seen)]
  | PsIrCheckTask.constructors scope remaining seen =>
      match remaining with
      | List.nil => state
      | List.cons ctorInfo rest =>
          let location := psIrCheckAt scope (String.Internal.append "constructor:" ctorInfo.name);
          let named := psIrCheckNames options [ctorInfo.name] location "duplicate-constructor-name" seen state;
          psIrCheckSchedule named
            [PsIrCheckTask.parameterTypes (psIrCheckAt location "fields")
               (psIrCheckConstructorParameters ctorInfo.fields) List.nil,
             PsIrCheckTask.constructors scope rest (List.cons ctorInfo.name seen)]
  | PsIrCheckTask.parameterTypes scope remaining seen =>
      match remaining with
      | List.nil => state
      | List.cons parameter rest =>
          let location := psIrCheckAt scope parameter.name;
          let named := psIrCheckNames options [parameter.name] location "duplicate-binder" seen state;
          let annotated := psIrCheckAnnotation options module named location parameter.type;
          psIrCheckSchedule annotated
            [PsIrCheckTask.parameterTypes scope rest (List.cons parameter.name seen)]

def psIrCheckRun (options : PsIrCheckOptions) (module : PsVerifiedIrModule)
    (fuel : Nat) (state : PsIrCheckState) : PsIrCheckState :=
  match fuel with
  | Nat.zero =>
      if psListIsEmpty state.tasks then state
      else
        let failed := psIrCheckFinding options state
          (psIrCheckScopeRoot "module" List.nil List.nil)
          "checker-resource-limit" "dispatcher steps exhausted" Option.none Option.none;
        PsIrCheckState.mk List.nil failed.values failed.visitedSteps failed.expressionCount
          failed.findingCount failed.findingsRev false
  | Nat.succ remaining =>
      match state.tasks with
      | List.nil => state
      | List.cons task tasks =>
          let next := PsIrCheckState.mk tasks state.values (Nat.succ state.visitedSteps)
            state.expressionCount state.findingCount state.findingsRev state.traversalComplete;
          psIrCheckRun options module remaining (psIrCheckStep options module task next)

def psIrCheckSizedModule (options : PsIrCheckOptions) (module : PsVerifiedIrModule)
    (inputNodes : Nat) : PsIrCheckReport :=
  let importedNames := psListMap
    (fun (entry : PsVerifiedIrExternalImport) => entry.localName) module.imports;
  let initial := PsIrCheckState.mk
    [PsIrCheckTask.imports module.imports List.nil,
     PsIrCheckTask.structures module.structures module.inductives ["Array"],
     PsIrCheckTask.declarations module.declarations importedNames]
    List.nil inputNodes 0 0 List.nil true;
  let traversed := psIrCheckRun options module options.maxSteps initial;
  let complete :=
    if traversed.traversalComplete then
      if psListIsEmpty traversed.values then traversed
      else psIrCheckInternal options traversed
    else traversed;
  let accepted :=
    if complete.traversalComplete then Nat.beq complete.findingCount 0 else false;
  PsIrCheckReport.mk accepted complete.traversalComplete complete.visitedSteps
    complete.expressionCount complete.findingCount (psListReverse complete.findingsRev)

-- Size validation precedes every synchronous signature, name or binding scan.
-- A complete traversal means every checking obligation concluded; type helpers
-- retain the first failure inside an individual annotation, not every defect.
def psCheckVerifiedIrModule (options : PsIrCheckOptions) (module : PsVerifiedIrModule) :
    PsIrCheckReport :=
  match psIrCheckModuleSize options.maxSteps module with
  | Except.error issue =>
      let finding := PsIrCheckFinding.mk issue.code issue.detail "module" "input"
        Option.none Option.none;
      let findings :=
        if Nat.beq options.maxFindings 0 then List.nil else List.cons finding List.nil;
      PsIrCheckReport.mk false false 0 0 1 findings
  | Except.ok inputNodes => psIrCheckSizedModule options module inputNodes
