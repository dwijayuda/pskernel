import PSC1Kernel.Kernel

namespace PSC1Kernel

namespace Kernel

/--
First checked K5 slice: an ordinary, non-parametric, non-indexed,
non-recursive inductive datatype in a non-Prop sort.

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

partial def simpleFreshElimNameAux
    (levelParams : List Name)
    (candidate : Nat) : Name :=
  let base : Name := .str .anonymous "u"
  let name := if candidate == 0 then base else .num base candidate
  if nameMember name levelParams then
    simpleFreshElimNameAux levelParams (candidate + 1)
  else
    name

def simpleFreshElimName (levelParams : List Name) : Name :=
  simpleFreshElimNameAux levelParams 0

def makeSimpleMinorBinders
    (motive : Expr)
    (levels : List Level) :
    List SimpleConstructorDecl → Nat → List OpenBinder
  | [], _ => []
  | ctor :: rest, index =>
      let internalName := .num (simpleInternalName "minor") index
      let ctorExpr := Expr.const ctor.name levels
      let binder : OpenBinder := {
        internalName := internalName
        userName := ctor.name
        type := .app motive ctorExpr
        binderInfo := .default
      }
      binder :: makeSimpleMinorBinders motive levels rest (index + 1)

def makeSimpleRecursorRules
    (ruleBinders : List OpenBinder) :
    List SimpleConstructorDecl → List OpenBinder → List RecursorRule
  | [], [] => []
  | ctor :: ctors, minor :: minors =>
      {
        ctor := ctor.name
        nFields := 0
        rhs := closeOpenLambdas ruleBinders (.fvar minor.internalName)
      } :: makeSimpleRecursorRules ruleBinders ctors minors
  | _, _ => []

def validateSimpleRecursorRules
    (ctx : CheckerContext)
    (ruleBinders : List OpenBinder)
    (motive : Expr)
    (levels : List Level) :
    List SimpleConstructorDecl → List RecursorRule → Except String Unit
  | [], [] => pure ()
  | ctor :: ctors, rule :: rules => do
      let gotType ← check ctx rule.rhs
      let expectedType :=
        closeOpenBinders ruleBinders
          (.app motive (.const ctor.name levels))
      unless ← isDefEq ctx gotType expectedType do
        throw "generated simple recursor rule is not type preserving"
      validateSimpleRecursorRules ctx ruleBinders motive levels ctors rules
  | _, _ => throw "generated simple recursor rule count mismatch"

def addSimpleInductive
    (env : Environment)
    (decl : SimpleInductiveDecl) : Except String Environment := do
  if Name.hasDuplicates decl.levelParams then
    throw "duplicate universe parameter"
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
      List SimpleConstructorDecl → Except String Environment
    | [] => pure work
    | ctor :: rest => do
        checkNoMVarNoFVar ctor.type
        checkLevelParams ctor.type decl.levelParams
        let ctorCtx := mkChecker work decl.levelParams safety
        let ctorTypeType ← check ctorCtx ctor.type
        let _ ← ensureSort ctorCtx ctorTypeType
        let ctorWhnf ← whnf ctorCtx ctor.type
        unless Expr.eq ctorWhnf inductExpr do
          throw "simple inductive constructor must have no fields and return the declared datatype"
        let work' := work.addUnchecked (.ctorInfo {
          base := {
            name := ctor.name
            levelParams := decl.levelParams
            type := ctor.type
          }
          induct := decl.name
          cidx := index
          numParams := 0
          numFields := 0
          isUnsafe := decl.isUnsafe
        })
        addConstructors work' (index + 1) rest

  let work1 ← addConstructors work0 0 decl.ctors

  let elimName := simpleFreshElimName decl.levelParams
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
  let minorBinders := makeSimpleMinorBinders motive levels decl.ctors 0
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
    makeSimpleRecursorRules ruleBinders decl.ctors minorBinders
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
  validateSimpleRecursorRules recCtx ruleBinders motive levels decl.ctors rules

  pure (work1.addUnchecked (.recInfo recInfo))

end Kernel

end PSC1Kernel
