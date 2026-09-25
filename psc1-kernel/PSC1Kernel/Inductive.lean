import PSC1Kernel.Kernel

namespace PSC1Kernel

namespace Kernel

/--
Checked K5 slice: an ordinary, non-parametric, non-indexed inductive datatype
in a non-Prop sort. Constructor fields are supported when they are
non-recursive; recursive occurrences still fail closed.

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

structure SimpleConstructorShape where
  ctor : SimpleConstructorDecl
  fields : List OpenBinder

partial def openSimpleConstructorFields
    (ctx : CheckerContext)
    (target : Name)
    (resultLevel : Level)
    (type : Expr)
    (revFields : List OpenBinder := []) :
    Except String (CheckerContext × List OpenBinder × Expr) := do
  let reduced ← whnf ctx type
  match reduced with
  | .forallE userName domain body binderInfo => do
      let domainType ← check ctx domain
      let fieldLevel ← ensureSort ctx domainType
      unless Level.le fieldLevel resultLevel do
        throw "simple inductive constructor field universe is too large"
      let domainWhnf ← whnf ctx domain
      if exprContainsConst target domain ||
          exprContainsConst target domainWhnf then
        throw "simple inductive admission does not yet support recursive constructor fields"
      let (fresh, child) := ctx.withLocal userName domain binderInfo
      let field : OpenBinder := {
        internalName := fresh
        userName := userName
        type := domain
        binderInfo := binderInfo
      }
      openSimpleConstructorFields
        child target resultLevel (body.instantiate1 (.fvar fresh))
        (field :: revFields)
  | result =>
      pure (ctx, revFields.reverse, result)

def simpleFieldArgs (shape : SimpleConstructorShape) : List Expr :=
  shape.fields.map (fun field => .fvar field.internalName)

def simpleCtorApp
    (levels : List Level)
    (shape : SimpleConstructorShape) : Expr :=
  applyArgs (.const shape.ctor.name levels) (simpleFieldArgs shape)

def makeSimpleMinorBinders
    (motive : Expr)
    (levels : List Level) :
    List SimpleConstructorShape → Nat → List OpenBinder
  | [], _ => []
  | shape :: rest, index =>
      let internalName := .num (simpleInternalName "minor") index
      let binder : OpenBinder := {
        internalName := internalName
        userName := shape.ctor.name
        type :=
          closeOpenBinders shape.fields
            (.app motive (simpleCtorApp levels shape))
        binderInfo := .default
      }
      binder :: makeSimpleMinorBinders motive levels rest (index + 1)

def makeSimpleRecursorRules
    (ruleBinders : List OpenBinder) :
    List SimpleConstructorShape → List OpenBinder → List RecursorRule
  | [], [] => []
  | shape :: shapes, minor :: minors =>
      let body :=
        applyArgs (.fvar minor.internalName) (simpleFieldArgs shape)
      {
        ctor := shape.ctor.name
        nFields := shape.fields.length
        rhs := closeOpenLambdas (ruleBinders ++ shape.fields) body
      } :: makeSimpleRecursorRules ruleBinders shapes minors
  | _, _ => []

def validateSimpleRecursorRules
    (ctx : CheckerContext)
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
          (.app motive (simpleCtorApp levels shape))
      unless ← isDefEq ctx gotType expectedType do
        throw "generated simple recursor rule is not type preserving"
      validateSimpleRecursorRules ctx ruleBinders motive levels shapes rules
  | _, _ => throw "generated simple recursor rule count mismatch"

def addSimpleInductive
    (env : Environment)
    (decl : SimpleInductiveDecl) : Except String Environment := do
  if Name.hasDuplicates decl.levelParams then
    throw "duplicate universe parameter"
  if !decl.levelParams.isEmpty then
    throw "simple inductive admission does not yet support universe parameters"
  if decl.ctors.isEmpty then
    throw "simple inductive admission does not yet support empty datatypes"

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
  let headerWhnf ← whnf headerCtx decl.type
  let .sort resultLevel := headerWhnf
    | throw "simple inductive type must have no parameters or indices"
  if Level.normalizesToZero resultLevel then
    throw "simple inductive admission currently requires a non-Prop result sort"

  let levels := decl.levelParams.map Level.param
  let inductExpr : Expr := .const decl.name levels
  let inductInfo : InductiveInfo := {
    base := {
      name := decl.name
      levelParams := decl.levelParams
      type := decl.type
    }
    numParams := 0
    numIndices := 0
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
        let ctorCtx := mkChecker work decl.levelParams safety
        let ctorTypeType ← check ctorCtx ctor.type
        let _ ← ensureSort ctorCtx ctorTypeType
        let (resultCtx, fields, result) ←
          openSimpleConstructorFields
            ctorCtx decl.name resultLevel ctor.type
        unless Expr.eq result inductExpr do
          throw "simple inductive constructor must return the declared datatype"
        let work' := work.addUnchecked (.ctorInfo {
          base := {
            name := ctor.name
            levelParams := decl.levelParams
            type := ctor.type
          }
          induct := decl.name
          cidx := index
          numParams := 0
          numFields := fields.length
          isUnsafe := decl.isUnsafe
        })
        let (done, shapes) ← addConstructors work' (index + 1) rest
        let shape : SimpleConstructorShape := { ctor := ctor, fields := fields }
        -- Keep resultCtx live through validation above; generated metadata is
        -- closed again before it is exposed.
        let _ := resultCtx
        pure (done, shape :: shapes)

  let (work1, ctorShapes) ← addConstructors work0 0 decl.ctors

  let elimName : Name := .str .anonymous "u"
  let elimLevel : Level := .param elimName
  let recLevelParams := elimName :: decl.levelParams
  let motiveInternal := simpleInternalName "motive"
  let motive : Expr := .fvar motiveInternal
  let motiveBinder : OpenBinder := {
    internalName := motiveInternal
    userName := .str .anonymous "motive"
    type := mkArrow inductExpr (.sort elimLevel)
    binderInfo := .implicit
  }
  let minorBinders := makeSimpleMinorBinders motive levels ctorShapes 0
  let majorInternal := simpleInternalName "major"
  let major : Expr := .fvar majorInternal
  let majorBinder : OpenBinder := {
    internalName := majorInternal
    userName := .str .anonymous "t"
    type := inductExpr
    binderInfo := .default
  }
  let ruleBinders := [motiveBinder] ++ minorBinders
  let recType :=
    closeOpenBinders
      (ruleBinders ++ [majorBinder])
      (.app motive major)
  let rules :=
    makeSimpleRecursorRules ruleBinders ctorShapes minorBinders
  let recInfo : RecursorInfo := {
    base := {
      name := recName
      levelParams := recLevelParams
      type := recType
    }
    all := [decl.name]
    numParams := 0
    numIndices := 0
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
  validateSimpleRecursorRules recCtx ruleBinders motive levels ctorShapes rules

  pure (work1.addUnchecked (.recInfo recInfo))

end Kernel

end PSC1Kernel
