import PSC1Kernel.Kernel

namespace PSC1Kernel

namespace Kernel

/--
Checked K5 slice: an ordinary inductive datatype in a result universe that is
provably nonzero. Shared parameters, indices, and constructor fields are
supported together with direct strictly-positive recursive fields. Function-
recursive, nested, negative, and mutual occurrences still fail closed.

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
      let (fresh, child) := ctx.withLocal userName domain binderInfo
      let param : OpenBinder := {
        internalName := fresh
        userName := userName
        type := domain
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
      let (fresh, child) := ctx.withLocal userName domain binderInfo
      let index : OpenBinder := {
        internalName := fresh
        userName := userName
        type := domain
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
      unless Level.le fieldLevel resultLevel do
        throw "simple inductive constructor field universe is too large"
      let domainWhnf ← whnf ctx domain
      let recursiveIndices? :=
        simpleInductiveAppIndices? target levels params numIndices domainWhnf
      if recursiveIndices?.isNone &&
          (exprContainsConst target domain ||
            exprContainsConst target domainWhnf) then
        throw "simple inductive admission supports only direct strictly-positive recursive fields"
      let (fresh, child) := ctx.withLocal userName domain binderInfo
      let field : OpenBinder := {
        internalName := fresh
        userName := userName
        type := domain
        binderInfo := binderInfo
      }
      let revRecursive' :=
        match recursiveIndices? with
        | some recursiveIndices =>
            {
              field := field
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
            simpleMotiveApp motive recursive.indices
              (.fvar recursive.field.internalName)
          binderInfo := .default
        }
        binder :: go rest (index + 1)
  go shape.recursiveFields 0

def simpleHasRecursiveFields : List SimpleConstructorShape → Bool
  | [] => false
  | shape :: rest =>
      !shape.recursiveFields.isEmpty || simpleHasRecursiveFields rest

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
  { env with
    constants :=
      replaceSimpleConstant info.base.name (.inductInfo info) env.constants }

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
    applyArgs (.const recName recLevels)
      (fixed ++ recursive.indices ++ [.fvar recursive.field.internalName])

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

def addSimpleInductive
    (env : Environment)
    (decl : SimpleInductiveDecl) : Except String Environment := do
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

  checkNoMVarNoFVar decl.type
  checkLevelParams decl.type decl.levelParams
  let safety :=
    if decl.isUnsafe then DefinitionSafety.unsafeDef else DefinitionSafety.safe
  let headerCtx := mkChecker env decl.levelParams safety
  let headerType ← check headerCtx decl.type
  let _ ← ensureSort headerCtx headerType
  let (headerParamCtx, params, afterParams) ←
    openSimpleHeaderParams headerCtx decl.type decl.numParams []
  let (headerIndexCtx, indices, headerResult) ←
    openSimpleHeaderIndices headerParamCtx afterParams
  let .sort resultLevel := headerResult
    | throw "simple inductive result must be a sort"
  if !Level.isNotZero resultLevel then
    throw "simple inductive admission currently requires a result universe that is provably nonzero"

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
        let closedCtorCtx := mkChecker work decl.levelParams safety
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
  let finalInductInfo : InductiveInfo := {
    inductInfo with isRec := isRecursive
  }
  let work1 := replaceSimpleInductiveInfo work1 finalInductInfo

  let elimName := simpleFreshElimName decl.levelParams
  let elimLevel : Level := .param elimName
  let recLevelParams := elimName :: decl.levelParams
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
    k := false
    isUnsafe := decl.isUnsafe
  }

  -- Validate generated metadata independently before exposing it.
  let recCtx := mkChecker work1 recLevelParams safety
  let recTypeType ← check recCtx recType
  let _ ← ensureSort recCtx recTypeType
  let work2 := work1.addUnchecked (.recInfo recInfo)
  let ruleCtx := mkChecker work2 recLevelParams safety
  validateSimpleRecursorRules
    ruleCtx params ruleBinders motive levels ctorShapes rules

  pure work2

end Kernel

end PSC1Kernel
