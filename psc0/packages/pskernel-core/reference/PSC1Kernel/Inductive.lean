import PSC1Kernel.Kernel

namespace PSC1Kernel

namespace Kernel

/--
Checked K5 slice: an ordinary inductive datatype with Lean-4.34-compatible
large-vs-Prop elimination selection. Shared parameters, indices, and
constructor fields are supported together with direct strictly-positive
recursive fields. Functional recursive fields are also supported when every
function-domain binder is non-recursive and the final codomain is the same
inductive. Nested, negative, and mutual occurrences still fail closed.

Unsupported inductive shapes fail closed instead of accepting exported
constructor/recursor metadata.
-/
structure SimpleConstructorDecl where
  name : Name
  type : Expr

structure SimpleInductiveDecl where
  levelParams : List Name
  name : Name
  type : Expr
  ctors : List SimpleConstructorDecl
  isUnsafe : Bool
  numParams : Nat := 0

def simpleRecName (name : Name) : Name :=
  .str name "rec"

def simpleInternalName (field : String) : Name :=
  .str (.str .anonymous "_psc1SimpleInd") field

def closeOpenLambdas : List OpenBinder → Expr → Expr
  | [], body => body
  | binder :: rest, body =>
      let inner := closeOpenLambdas rest body
      .lam
        binder.userName
        binder.type
        (inner.abstractFVars [binder.internalName])
        binder.binderInfo

def simpleNameListUnique (names : List Name) : Bool :=
  !Name.hasDuplicates names

def simpleElimNameCandidate : Nat → Name
  | 0 => .str .anonymous "u"
  | n + 1 => .str .anonymous ("u_" ++ toString (n + 1))

def simpleFreshElimNameAux
    (levelParams : List Name) : Nat → Nat → Name
  | 0, candidate => simpleElimNameCandidate candidate
  | fuel + 1, candidate =>
      let name := simpleElimNameCandidate candidate
      if nameMember name levelParams then
        simpleFreshElimNameAux levelParams fuel (candidate + 1)
      else
        name

def simpleFreshElimName (levelParams : List Name) : Name :=
  simpleFreshElimNameAux levelParams (levelParams.length + 1) 0

def simpleDeclaredNameMember (name : Name) : List Name → Bool
  | [] => false
  | candidate :: rest =>
      Name.eq name candidate || simpleDeclaredNameMember name rest

def simpleUniformParamArgsMatch
    (offset : Nat) : List Expr → Nat → Bool
  | [], _ => true
  | arg :: rest, index =>
      match arg with
      | .bvar bvarIndex =>
          bvarIndex == offset - 1 - index &&
            simpleUniformParamArgsMatch offset rest (index + 1)
      | _ => false

partial def simpleCheckUniformOccurrenceExpr
    (declaredNames : List Name)
    (expectedLevels : List Level)
    (numParams : Nat)
    (e : Expr)
    (offset : Nat := 0) : Except String Unit := do
  match e.getAppFn with
  | .const name levels =>
      let args := e.getAppArgs
      if simpleDeclaredNameMember name declaredNames &&
          args.length <= numParams then
        let ok :=
          args.length == numParams &&
          offset >= numParams &&
          Level.listEq levels expectedLevels &&
          simpleUniformParamArgsMatch offset args 0
        unless ok do
          throw
            "invalid occurrence of datatype being declared: it must be applied to the parameters and universe levels of the mutual declaration"
        return ()
  | _ => pure ()

  match e with
  | .app fn arg => do
      simpleCheckUniformOccurrenceExpr
        declaredNames expectedLevels numParams fn offset
      simpleCheckUniformOccurrenceExpr
        declaredNames expectedLevels numParams arg offset
  | .lam _ type body _ | .forallE _ type body _ => do
      simpleCheckUniformOccurrenceExpr
        declaredNames expectedLevels numParams type offset
      simpleCheckUniformOccurrenceExpr
        declaredNames expectedLevels numParams body (offset + 1)
  | .letE _ type value body _ => do
      simpleCheckUniformOccurrenceExpr
        declaredNames expectedLevels numParams type offset
      simpleCheckUniformOccurrenceExpr
        declaredNames expectedLevels numParams value offset
      simpleCheckUniformOccurrenceExpr
        declaredNames expectedLevels numParams body (offset + 1)
  | .mdata _ body | .proj _ _ body =>
      simpleCheckUniformOccurrenceExpr
        declaredNames expectedLevels numParams body offset
  | .bvar _ | .fvar _ | .mvar _ | .sort _ | .const _ _ | .lit _ =>
      pure ()

def simpleCheckUniformOccurrences
    (declaredNames : List Name)
    (levelParams : List Name)
    (numParams : Nat)
    (ctorTypes : List Expr) : Except String Unit := do
  let expectedLevels := levelParams.map Level.param
  let rec go : List Expr → Except String Unit
    | [] => pure ()
    | ctorType :: rest => do
        simpleCheckUniformOccurrenceExpr
          declaredNames expectedLevels numParams ctorType 0
        go rest
  go ctorTypes

partial def exprContainsConst (target : Name) : Expr → Bool
  | .const name _ => Name.eq name target
  | .app fn arg => exprContainsConst target fn || exprContainsConst target arg
  | .lam _ type body _ =>
      exprContainsConst target type || exprContainsConst target body
  | .forallE _ type body _ =>
      exprContainsConst target type || exprContainsConst target body
  | .letE _ type value body _ =>
      exprContainsConst target type ||
        exprContainsConst target value ||
        exprContainsConst target body
  | .mdata _ body => exprContainsConst target body
  | .proj typeName _ body =>
      Name.eq typeName target || exprContainsConst target body
  | .bvar _ | .fvar _ | .mvar _ | .sort _ | .lit _ => false

structure SimpleRecursiveField where
  field : OpenBinder
  args : List OpenBinder
  indices : List Expr

structure SimpleConstructorShape where
  ctor : SimpleConstructorDecl
  fields : List OpenBinder
  recursiveFields : List SimpleRecursiveField
  resultIndices : List Expr

partial def openSimpleHeaderParams
    (ctx : CheckerContext)
    (type : Expr) :
    Nat → List OpenBinder →
      Except String (CheckerContext × List OpenBinder × Expr)
  | 0, revParams => do
      let result ← whnf ctx type
      pure (ctx, revParams.reverse, result)
  | remaining + 1, revParams => do
      let reduced ← whnf ctx type
      let .forallE userName domain body binderInfo := reduced
        | throw "simple inductive declaration has fewer parameters than declared"
      let domainType ← check ctx domain
      let _ ← ensureSort ctx domainType
      let localDomain := domain.consumeTypeAnnotations
      let (fresh, child) := ctx.withLocal userName localDomain binderInfo
      let param : OpenBinder := {
        internalName := fresh
        userName := userName
        type := localDomain
        binderInfo := binderInfo
      }
      openSimpleHeaderParams
        child (body.instantiate1 (.fvar fresh))
        remaining (param :: revParams)

partial def openSimpleHeaderIndices
    (ctx : CheckerContext)
    (type : Expr)
    (revIndices : List OpenBinder := []) :
    Except String (CheckerContext × List OpenBinder × Expr) := do
  let reduced ← whnf ctx type
  match reduced with
  | .forallE userName domain body binderInfo => do
      let domainType ← check ctx domain
      let _ ← ensureSort ctx domainType
      let localDomain := domain.consumeTypeAnnotations
      let (fresh, child) := ctx.withLocal userName localDomain binderInfo
      let index : OpenBinder := {
        internalName := fresh
        userName := userName
        type := localDomain
        binderInfo := binderInfo
      }
      openSimpleHeaderIndices
        child (body.instantiate1 (.fvar fresh))
        (index :: revIndices)
  | result =>
      pure (ctx, revIndices.reverse, result)

partial def openSimpleConstructorParams
    (ctx : CheckerContext)
    (params : List OpenBinder)
    (type : Expr) : Except String Expr := do
  match params with
  | [] => pure type
  | param :: rest =>
      let reduced ← whnf ctx type
      let .forallE _ domain body _ := reduced
        | throw "simple inductive constructor has fewer parameters than the datatype"
      unless ← isDefEq ctx domain param.type do
        throw "simple inductive constructor parameter does not match the datatype parameter"
      openSimpleConstructorParams
        ctx rest (body.instantiate1 (.fvar param.internalName))

def consumeSimpleResultParams :
    List OpenBinder → List Expr → Option (List Expr)
  | [], rest => some rest
  | _, [] => none
  | param :: params, arg :: args =>
      if Expr.eq arg (.fvar param.internalName) then
        consumeSimpleResultParams params args
      else
        none

def simpleInductiveAppIndices?
    (target : Name)
    (levels : List Level)
    (params : List OpenBinder)
    (numIndices : Nat)
    (e : Expr) : Option (List Expr) :=
  match e.getAppFn with
  | .const resultName resultLevels =>
      if !Name.eq resultName target || !Level.listEq resultLevels levels then
        none
      else
        match consumeSimpleResultParams params e.getAppArgs with
        | some indices =>
            if indices.length == numIndices then some indices else none
        | none => none
  | _ => none

partial def simpleIndicesContainTarget
    (target : Name) : List Expr → Bool
  | [] => false
  | index :: rest =>
      exprContainsConst target index ||
        simpleIndicesContainTarget target rest

partial def analyzeSimpleRecursiveArgument
    (ctx : CheckerContext)
    (target : Name)
    (levels : List Level)
    (params : List OpenBinder)
    (numIndices : Nat)
    (type : Expr)
    (revArgs : List OpenBinder := []) :
    Except String (CheckerContext × Option (List OpenBinder × List Expr)) := do
  let reduced ← whnf ctx type
  match simpleInductiveAppIndices? target levels params numIndices reduced with
  | some indices =>
      if simpleIndicesContainTarget target indices then
        throw "recursive argument index contains a recursive occurrence"
      pure (ctx, some (revArgs.reverse, indices))
  | none =>
      match reduced with
      | .forallE userName domain body binderInfo => do
          let domainWhnf ← whnf ctx domain
          if exprContainsConst target domain ||
              exprContainsConst target domainWhnf then
            throw "recursive function argument contains a negative recursive occurrence"
          let domainType ← check ctx domain
          let _ ← ensureSort ctx domainType
          let localDomain := domain.consumeTypeAnnotations
          let (fresh, child) := ctx.withLocal userName localDomain binderInfo
          let arg : OpenBinder := {
            internalName := fresh
            userName := userName
            type := localDomain
            binderInfo := binderInfo
          }
          analyzeSimpleRecursiveArgument
            child target levels params numIndices
            (body.instantiate1 (.fvar fresh)) (arg :: revArgs)
      | _ =>
          if exprContainsConst target type ||
              exprContainsConst target reduced then
            throw "simple inductive admission does not yet support nested recursive occurrences"
          pure (ctx, none)

partial def openSimpleConstructorFields
    (ctx : CheckerContext)
    (target : Name)
    (levels : List Level)
    (params : List OpenBinder)
    (numIndices : Nat)
    (resultLevel : Level)
    (type : Expr)
    (revFields : List OpenBinder := [])
    (revRecursive : List SimpleRecursiveField := []) :
    Except String
      (CheckerContext × List OpenBinder × List SimpleRecursiveField × Expr) := do
  let reduced ← whnf ctx type
  match reduced with
  | .forallE userName domain body binderInfo => do
      let domainType ← check ctx domain
      let fieldLevel ← ensureSort ctx domainType
      unless Level.le fieldLevel resultLevel ||
          Level.normalizesToZero resultLevel do
        throw "simple inductive constructor field universe is too large"
      let localDomain := domain.consumeTypeAnnotations
      let (fresh, child0) := ctx.withLocal userName localDomain binderInfo
      let field : OpenBinder := {
        internalName := fresh
        userName := userName
        type := localDomain
        binderInfo := binderInfo
      }
      let (analysisCtx, recursiveInfo?) ←
        analyzeSimpleRecursiveArgument
          child0 target levels params numIndices domain
      let continuationLctx : LocalContext := {
        child0.lctx with nextIndex := analysisCtx.lctx.nextIndex
      }
      let child : CheckerContext := { child0 with lctx := continuationLctx }
      let revRecursive' :=
        match recursiveInfo? with
        | some (args, recursiveIndices) =>
            {
              field := field
              args := args
              indices := recursiveIndices
            } :: revRecursive
        | none => revRecursive
      openSimpleConstructorFields
        child target levels params numIndices resultLevel
        (body.instantiate1 (.fvar fresh))
        (field :: revFields) revRecursive'
  | result =>
      pure (ctx, revFields.reverse, revRecursive.reverse, result)

def simpleFieldArgs (shape : SimpleConstructorShape) : List Expr :=
  shape.fields.map (fun field => .fvar field.internalName)

def simpleParamArgs (params : List OpenBinder) : List Expr :=
  params.map (fun param => .fvar param.internalName)

def validateSimpleConstructorResult
    (target : Name)
    (levels : List Level)
    (params : List OpenBinder)
    (numIndices : Nat)
    (result : Expr) : Except String (List Expr) := do
  let some indices :=
      simpleInductiveAppIndices? target levels params numIndices result
    | throw "simple inductive constructor must return the declared datatype with matching parameters and index arity"
  if simpleIndicesContainTarget target indices then
    throw "simple inductive constructor return index contains a recursive occurrence"
  pure indices

def simpleMotiveApp
    (motive : Expr)
    (indices : List Expr)
    (major : Expr) : Expr :=
  applyArgs motive (indices ++ [major])

def simpleCtorApp
    (levels : List Level)
    (params : List OpenBinder)
    (shape : SimpleConstructorShape) : Expr :=
  applyArgs
    (.const shape.ctor.name levels)
    (simpleParamArgs params ++ simpleFieldArgs shape)

def makeSimpleIHBinders
    (motive : Expr)
    (shape : SimpleConstructorShape) : List OpenBinder :=
  let rec go : List SimpleRecursiveField → Nat → List OpenBinder
    | [], _ => []
    | recursive :: rest, index =>
        let internalName := .num (simpleInternalName "ih") index
        let binder : OpenBinder := {
          internalName := internalName
          userName := recursive.field.userName.appendAfter "_ih"
          type :=
            closeOpenBinders recursive.args
              (simpleMotiveApp motive recursive.indices
                (applyArgs
                  (.fvar recursive.field.internalName)
                  (recursive.args.map fun arg => Expr.fvar arg.internalName)))
          binderInfo := .default
        }
        binder :: go rest (index + 1)
  go shape.recursiveFields 0

def simpleHasRecursiveFields : List SimpleConstructorShape → Bool
  | [] => false
  | shape :: rest =>
      !shape.recursiveFields.isEmpty || simpleHasRecursiveFields rest

def simpleHasReflexiveFields : List SimpleConstructorShape → Bool
  | [] => false
  | shape :: rest =>
      shape.recursiveFields.any (fun recursive => !recursive.args.isEmpty) ||
        simpleHasReflexiveFields rest

partial def replaceSimpleConstant
    (target : Name)
    (replacement : ConstantInfo) : List ConstantInfo → List ConstantInfo
  | [] => []
  | info :: rest =>
      if Name.eq info.name target then
        replacement :: rest
      else
        info :: replaceSimpleConstant target replacement rest

def replaceSimpleInductiveInfo
    (env : Environment)
    (info : InductiveInfo) : Environment :=
  env.replaceUnchecked (.inductInfo info)

def makeSimpleMinorBinders
    (motive : Expr)
    (levels : List Level)
    (params : List OpenBinder) :
    List SimpleConstructorShape → Nat → List OpenBinder
  | [], _ => []
  | shape :: rest, index =>
      let internalName := .num (simpleInternalName "minor") index
      let ihBinders := makeSimpleIHBinders motive shape
      let binder : OpenBinder := {
        internalName := internalName
        userName := shape.ctor.name
        type :=
          closeOpenBinders (shape.fields ++ ihBinders)
            (simpleMotiveApp motive shape.resultIndices
              (simpleCtorApp levels params shape))
        binderInfo := .default
      }
      binder :: makeSimpleMinorBinders motive levels params rest (index + 1)

def makeSimpleRecursiveCalls
    (recName : Name)
    (recLevels : List Level)
    (params : List OpenBinder)
    (motive : Expr)
    (minors : List OpenBinder)
    (shape : SimpleConstructorShape) : List Expr :=
  let fixed :=
    simpleParamArgs params ++
      [motive] ++ minors.map (fun minor => Expr.fvar minor.internalName)
  shape.recursiveFields.map fun recursive =>
    let appliedField :=
      applyArgs
        (.fvar recursive.field.internalName)
        (recursive.args.map fun arg => Expr.fvar arg.internalName)
    let recursiveCall :=
      applyArgs (.const recName recLevels)
        (fixed ++ recursive.indices ++ [appliedField])
    closeOpenLambdas recursive.args recursiveCall

def makeSimpleRecursorRules
    (recName : Name)
    (recLevels : List Level)
    (params : List OpenBinder)
    (motive : Expr)
    (allMinors : List OpenBinder)
    (ruleBinders : List OpenBinder) :
    List SimpleConstructorShape → List OpenBinder → List RecursorRule
  | [], [] => []
  | shape :: shapes, minor :: minors =>
      let recursiveCalls :=
        makeSimpleRecursiveCalls
          recName recLevels params motive allMinors shape
      let body :=
        applyArgs (.fvar minor.internalName)
          (simpleFieldArgs shape ++ recursiveCalls)
      {
        ctor := shape.ctor.name
        nFields := shape.fields.length
        rhs := closeOpenLambdas (ruleBinders ++ shape.fields) body
      } :: makeSimpleRecursorRules
        recName recLevels params motive allMinors ruleBinders shapes minors
  | _, _ => []

def validateSimpleRecursorRules
    (ctx : CheckerContext)
    (params : List OpenBinder)
    (ruleBinders : List OpenBinder)
    (motive : Expr)
    (levels : List Level) :
    List SimpleConstructorShape → List RecursorRule → Except String Unit
  | [], [] => pure ()
  | shape :: shapes, rule :: rules => do
      let gotType ← check ctx rule.rhs
      let expectedType :=
        closeOpenBinders
          (ruleBinders ++ shape.fields)
          (simpleMotiveApp motive shape.resultIndices
            (simpleCtorApp levels params shape))
      unless ← isDefEq ctx gotType expectedType do
        throw "generated simple recursor rule is not type preserving"
      validateSimpleRecursorRules ctx params ruleBinders motive levels shapes rules
  | _, _ => throw "generated simple recursor rule count mismatch"

def simpleExprMember (needle : Expr) : List Expr → Bool
  | [] => false
  | item :: rest => Expr.eq needle item || simpleExprMember needle rest

partial def simpleCtorAllowsLargeElimCore
    (ctx : CheckerContext)
    (type : Expr)
    (revNonProp : List Expr := []) : Except String Bool := do
  let reduced ← whnf ctx type
  match reduced with
  | .forallE userName domain body binderInfo => do
      let domainType ← check ctx domain
      let fieldLevel ← ensureSort ctx domainType
      let localDomain := domain.consumeTypeAnnotations
      let (fresh, child) := ctx.withLocal userName localDomain binderInfo
      let revNonProp' :=
        if Level.normalizesToZero fieldLevel then
          revNonProp
        else
          .fvar fresh :: revNonProp
      simpleCtorAllowsLargeElimCore
        child (body.instantiate1 (.fvar fresh)) revNonProp'
  | result =>
      let resultArgs := result.getAppArgs
      pure (revNonProp.all fun field => simpleExprMember field resultArgs)

def simpleCtorAllowsLargeElim
    (ctx : CheckerContext)
    (params : List OpenBinder)
    (type : Expr) : Except String Bool := do
  let afterParams ← openSimpleConstructorParams ctx params type
  simpleCtorAllowsLargeElimCore ctx afterParams

def simpleElimOnlyAtZero
    (ctx : CheckerContext)
    (params : List OpenBinder)
    (resultLevel : Level)
    (ctors : List SimpleConstructorDecl) : Except String Bool := do
  if Level.isNotZero resultLevel then
    pure false
  else
    match ctors with
    | [] => pure false
    | [ctor] => do
        let canEliminateLarge ←
          simpleCtorAllowsLargeElim ctx params ctor.type
        pure (!canEliminateLarge)
    | _ => pure true

def simpleKTarget
    (resultLevel : Level)
    (shapes : List SimpleConstructorShape) : Bool :=
  if !Level.normalizesToZero resultLevel then
    false
  else
    match shapes with
    | [shape] => shape.fields.isEmpty
    | _ => false

def addSimpleInductive
    (env : Environment)
    (decl : SimpleInductiveDecl)
    (maxRecDepth : Nat := 0)
    (maxNatSize : Nat := leanNatMaxSizeDefault)
    (nativeEvaluator : Option NativeEvaluator := none) : Except String Environment := do
  if Name.hasDuplicates decl.levelParams then
    throw "duplicate universe parameter"
  let recName := simpleRecName decl.name
  let allNames := decl.name :: recName :: decl.ctors.map (fun ctor => ctor.name)
  unless simpleNameListUnique allNames do
    throw "duplicate inductive, constructor, or recursor name"
  let rec checkFresh : List Name → Except String Unit
    | [] => pure ()
    | name :: rest => do
        if env.contains name then
          throw "inductive declaration name is already declared"
        checkFresh rest
  checkFresh allNames

  simpleCheckUniformOccurrences
    [decl.name] decl.levelParams decl.numParams
    (decl.ctors.map fun ctor => ctor.type)

  checkNoMVarNoFVar decl.type
  checkLevelParams decl.type decl.levelParams
  let safety :=
    if decl.isUnsafe then DefinitionSafety.unsafeDef else DefinitionSafety.safe
  let headerCtx := mkChecker env decl.levelParams safety maxRecDepth maxNatSize nativeEvaluator
  let headerType ← check headerCtx decl.type
  let _ ← ensureSort headerCtx headerType
  let (headerParamCtx, params, afterParams) ←
    openSimpleHeaderParams headerCtx decl.type decl.numParams []
  let (headerIndexCtx, indices, headerResult) ←
    openSimpleHeaderIndices headerParamCtx afterParams
  let .sort resultLevel := headerResult
    | throw "simple inductive result must be a sort"
  let levels := decl.levelParams.map Level.param
  let paramArgs := simpleParamArgs params
  let indexArgs := indices.map (fun index => Expr.fvar index.internalName)
  let inductExpr : Expr :=
    applyArgs (.const decl.name levels) (paramArgs ++ indexArgs)
  let inductInfo : InductiveInfo := {
    base := {
      name := decl.name
      levelParams := decl.levelParams
      type := decl.type
    }
    numParams := decl.numParams
    numIndices := indices.length
    all := [decl.name]
    ctors := decl.ctors.map (fun ctor => ctor.name)
    numNested := 0
    isRec := false
    isReflexive := false
    isUnsafe := decl.isUnsafe
  }
  let work0 := env.addUnchecked (.inductInfo inductInfo)

  let rec addConstructors
      (work : Environment)
      (index : Nat) :
      List SimpleConstructorDecl →
        Except String (Environment × List SimpleConstructorShape)
    | [] => pure (work, [])
    | ctor :: rest => do
        checkNoMVarNoFVar ctor.type
        checkLevelParams ctor.type decl.levelParams
        let closedCtorCtx := mkChecker work decl.levelParams safety maxRecDepth maxNatSize nativeEvaluator
        let ctorTypeType ← check closedCtorCtx ctor.type
        let _ ← ensureSort closedCtorCtx ctorTypeType
        let ctorCtx : CheckerContext := { headerParamCtx with env := work }
        let afterParams ← openSimpleConstructorParams ctorCtx params ctor.type
        let (resultCtx, fields, recursiveFields, result) ←
          openSimpleConstructorFields
            ctorCtx decl.name levels params indices.length resultLevel afterParams
        let resultIndices ←
          validateSimpleConstructorResult
            decl.name levels params indices.length result
        let work' := work.addUnchecked (.ctorInfo {
          base := {
            name := ctor.name
            levelParams := decl.levelParams
            type := ctor.type
          }
          induct := decl.name
          cidx := index
          numParams := decl.numParams
          numFields := fields.length
          isUnsafe := decl.isUnsafe
        })
        let (done, shapes) ← addConstructors work' (index + 1) rest
        let shape : SimpleConstructorShape := {
          ctor := ctor
          fields := fields
          recursiveFields := recursiveFields
          resultIndices := resultIndices
        }
        -- Keep resultCtx live through validation above; generated metadata is
        -- closed again before it is exposed.
        let _ := resultCtx
        pure (done, shape :: shapes)

  let (work1, ctorShapes) ← addConstructors work0 0 decl.ctors

  let isRecursive := simpleHasRecursiveFields ctorShapes
  let isReflexive := simpleHasReflexiveFields ctorShapes
  let finalInductInfo : InductiveInfo := {
    inductInfo with
    isRec := isRecursive
    isReflexive := isReflexive
  }
  let work1 := replaceSimpleInductiveInfo work1 finalInductInfo

  let elimCtx : CheckerContext := { headerParamCtx with env := work1 }
  let elimOnlyAtZero ←
    simpleElimOnlyAtZero elimCtx params resultLevel decl.ctors
  let kTarget := simpleKTarget resultLevel ctorShapes
  let elimName := simpleFreshElimName decl.levelParams
  let elimLevel : Level :=
    if elimOnlyAtZero then .zero else .param elimName
  let recLevelParams :=
    if elimOnlyAtZero then decl.levelParams else elimName :: decl.levelParams
  let motiveInternal := simpleInternalName "motive"
  let motive : Expr := .fvar motiveInternal
  let motiveBinder : OpenBinder := {
    internalName := motiveInternal
    userName := .str .anonymous "motive"
    type :=
      closeOpenBinders indices
        (mkArrow inductExpr (.sort elimLevel))
    binderInfo := .default
  }
  let minorBinders := makeSimpleMinorBinders motive levels params ctorShapes 0
  let majorInternal := simpleInternalName "major"
  let major : Expr := .fvar majorInternal
  let majorBinder : OpenBinder := {
    internalName := majorInternal
    userName := .str .anonymous "t"
    type := inductExpr
    binderInfo := .default
  }
  let coreRuleBinders := [motiveBinder] ++ minorBinders
  let ruleBinders := params ++ coreRuleBinders
  let recTypeRaw :=
    closeOpenBinders
      (ruleBinders ++ indices ++ [majorBinder])
      (simpleMotiveApp motive indexArgs major)
  let recType := recTypeRaw.inferImplicitAll true
  let recLevels := recLevelParams.map Level.param
  let rules :=
    makeSimpleRecursorRules
      recName recLevels params motive minorBinders ruleBinders ctorShapes minorBinders
  let recInfo : RecursorInfo := {
    base := {
      name := recName
      levelParams := recLevelParams
      type := recType
    }
    all := [decl.name]
    numParams := decl.numParams
    numIndices := indices.length
    numMotives := 1
    numMinors := minorBinders.length
    rules := rules
    k := kTarget
    isUnsafe := decl.isUnsafe
  }

  -- Validate generated metadata independently before exposing it.
  let recCtx := mkChecker work1 recLevelParams safety maxRecDepth maxNatSize nativeEvaluator
  let recTypeType ← check recCtx recType
  let _ ← ensureSort recCtx recTypeType
  let work2 := work1.addUnchecked (.recInfo recInfo)
  let ruleCtx := mkChecker work2 recLevelParams safety maxRecDepth maxNatSize nativeEvaluator
  validateSimpleRecursorRules
    ruleCtx params ruleBinders motive levels ctorShapes rules

  pure work2

end Kernel

end PSC1Kernel
