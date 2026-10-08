import PSC1Kernel.Inductive

namespace PSC1Kernel

namespace Kernel

/--
Bounded ordinary mutual-inductive admission for the PSC1 bootstrap kernel.

This layer deliberately excludes nested-inductive preprocessing. It supports
shared parameters, per-type indices, direct/functional strictly-positive
cross-recursion, generated multi-motive recursors, and Lean-4.34-compatible
large-vs-Prop elimination selection for ordinary mutual declarations.
-/
structure SimpleMutualTypeDecl where
  name : Name
  type : Expr
  ctors : List SimpleConstructorDecl

structure SimpleMutualInductiveDecl where
  levelParams : List Name
  numParams : Nat
  types : List SimpleMutualTypeDecl
  isUnsafe : Bool

structure SimpleMutualTypeShape where
  decl : SimpleMutualTypeDecl
  indices : List OpenBinder

structure SimpleMutualRecursiveField where
  field : OpenBinder
  args : List OpenBinder
  target : Nat
  indices : List Expr

structure SimpleMutualConstructorShape where
  owner : Nat
  ctor : SimpleConstructorDecl
  fields : List OpenBinder
  recursiveFields : List SimpleMutualRecursiveField
  resultIndices : List Expr

def simpleMutualNames (decl : SimpleMutualInductiveDecl) : List Name :=
  decl.types.map (fun type => type.name)

partial def simpleMutualContainsConst
    (targets : List Name) : Expr → Bool
  | .const name _ => nameMember name targets
  | .app fn arg =>
      simpleMutualContainsConst targets fn ||
        simpleMutualContainsConst targets arg
  | .lam _ type body _ | .forallE _ type body _ =>
      simpleMutualContainsConst targets type ||
        simpleMutualContainsConst targets body
  | .letE _ type value body _ =>
      simpleMutualContainsConst targets type ||
        simpleMutualContainsConst targets value ||
        simpleMutualContainsConst targets body
  | .mdata _ body => simpleMutualContainsConst targets body
  | .proj typeName _ body =>
      nameMember typeName targets ||
        simpleMutualContainsConst targets body
  | .bvar _ | .fvar _ | .mvar _ | .sort _ | .lit _ => false

def simpleMutualTargetIndex?
    (name : Name) : List SimpleMutualTypeShape → Nat → Option Nat
  | [], _ => none
  | shape :: rest, index =>
      if Name.eq name shape.decl.name then
        some index
      else
        simpleMutualTargetIndex? name rest (index + 1)

structure SimpleMutualAppInfo where
  target : Nat
  indices : List Expr

def simpleMutualAppInfo?
    (targets : List Name)
    (shapes : List SimpleMutualTypeShape)
    (levels : List Level)
    (params : List OpenBinder)
    (e : Expr) : Option SimpleMutualAppInfo :=
  match e.getAppFn with
  | .const name foundLevels =>
      if !Level.listEq foundLevels levels then
        none
      else
        match simpleMutualTargetIndex? name shapes 0 with
        | none => none
        | some target =>
            match listGet? shapes target with
            | none => none
            | some shape =>
                match consumeSimpleResultParams params e.getAppArgs with
                | none => none
                | some indices =>
                    if indices.length != shape.indices.length then
                      none
                    else if indices.any (simpleMutualContainsConst targets) then
                      none
                    else
                      some { target := target, indices := indices }
  | _ => none

partial def analyzeSimpleMutualRecursiveArgument
    (ctx : CheckerContext)
    (targets : List Name)
    (shapes : List SimpleMutualTypeShape)
    (levels : List Level)
    (params : List OpenBinder)
    (field : OpenBinder)
    (domain : Expr)
    (revArgs : List OpenBinder := [])
    (applied : Expr := .fvar field.internalName) :
    Except String (Option SimpleMutualRecursiveField) := do
  let reduced ← whnf ctx domain
  match simpleMutualAppInfo? targets shapes levels params reduced with
  | some info =>
      pure (some {
        field := field
        args := revArgs.reverse
        target := info.target
        indices := info.indices
      })
  | none =>
      match reduced with
      | .forallE userName argDomain body binderInfo =>
          if simpleMutualContainsConst targets argDomain then
            throw "mutual inductive field has a non-positive recursive occurrence"
          let localDomain := argDomain.consumeTypeAnnotations
          let (fresh, child) := ctx.withLocal userName localDomain binderInfo
          let arg : OpenBinder := {
            internalName := fresh
            userName := userName
            type := localDomain
            binderInfo := binderInfo
          }
          analyzeSimpleMutualRecursiveArgument
            child targets shapes levels params field
            (body.instantiate1 (.fvar fresh))
            (arg :: revArgs) (.app applied (.fvar fresh))
      | _ =>
          if simpleMutualContainsConst targets domain ||
              simpleMutualContainsConst targets reduced then
            throw "nested or invalid mutual inductive occurrence is not supported"
          pure none

partial def openSimpleMutualConstructorFields
    (ctx : CheckerContext)
    (targets : List Name)
    (shapes : List SimpleMutualTypeShape)
    (levels : List Level)
    (params : List OpenBinder)
    (resultLevel : Level)
    (type : Expr)
    (revFields : List OpenBinder := [])
    (revRecursive : List SimpleMutualRecursiveField := []) :
    Except String
      (CheckerContext × List OpenBinder ×
        List SimpleMutualRecursiveField × Expr) := do
  let reduced ← whnf ctx type
  match reduced with
  | .forallE userName domain body binderInfo => do
      let domainType ← check ctx domain
      let fieldLevel ← ensureSort ctx domainType
      unless Level.le fieldLevel resultLevel ||
          Level.normalizesToZero resultLevel do
        throw "mutual inductive constructor field universe is too large"
      let localDomain := domain.consumeTypeAnnotations
      let (fresh, child) := ctx.withLocal userName localDomain binderInfo
      let field : OpenBinder := {
        internalName := fresh
        userName := userName
        type := localDomain
        binderInfo := binderInfo
      }
      let recursive? ←
        analyzeSimpleMutualRecursiveArgument
          child targets shapes levels params field domain
      let revRecursive' :=
        match recursive? with
        | some recursive => recursive :: revRecursive
        | none => revRecursive
      openSimpleMutualConstructorFields
        child targets shapes levels params resultLevel
        (body.instantiate1 (.fvar fresh))
        (field :: revFields) revRecursive'
  | result =>
      pure (ctx, revFields.reverse, revRecursive.reverse, result)

def simpleMutualCtorApp
    (levels : List Level)
    (params : List OpenBinder)
    (shape : SimpleMutualConstructorShape) : Expr :=
  applyArgs (.const shape.ctor.name levels)
    (simpleParamArgs params ++
      shape.fields.map (fun field => Expr.fvar field.internalName))

def simpleMutualMotiveApp
    (motives : List OpenBinder)
    (target : Nat)
    (indices : List Expr)
    (major : Expr) : Except String Expr := do
  let some motive := listGet? motives target
    | throw "mutual recursor motive target is out of bounds"
  pure <| simpleMotiveApp (.fvar motive.internalName) indices major

def simpleMutualHasRecursiveFields :
    List SimpleMutualConstructorShape → Bool
  | [] => false
  | shape :: rest =>
      !shape.recursiveFields.isEmpty ||
        simpleMutualHasRecursiveFields rest

def simpleMutualHasReflexiveFields :
    List SimpleMutualConstructorShape → Bool
  | [] => false
  | shape :: rest =>
      shape.recursiveFields.any (fun recursive => !recursive.args.isEmpty) ||
        simpleMutualHasReflexiveFields rest

def simpleMutualIHBinders
    (motives : List OpenBinder)
    (shape : SimpleMutualConstructorShape) :
    Except String (List OpenBinder) := do
  let rec go :
      List SimpleMutualRecursiveField → Nat →
        Except String (List OpenBinder)
    | [], _ => pure []
    | recursive :: rest, index => do
        let target ←
          simpleMutualMotiveApp motives recursive.target recursive.indices
            (applyArgs (.fvar recursive.field.internalName)
              (recursive.args.map fun arg => .fvar arg.internalName))
        let internalName := .num (simpleInternalName "mutualIH") index
        let binder : OpenBinder := {
          internalName := internalName
          userName := recursive.field.userName.appendAfter "_ih"
          type := closeOpenBinders recursive.args target
          binderInfo := .default
        }
        let tail ← go rest (index + 1)
        pure (binder :: tail)
  go shape.recursiveFields 0

def makeSimpleMutualMotives
    (levels : List Level)
    (params : List OpenBinder)
    (elimLevel : Level) :
    List SimpleMutualTypeShape → Nat → List OpenBinder
  | [], _ => []
  | shape :: rest, index =>
      let inductExpr :=
        applyArgs (.const shape.decl.name levels)
          (simpleParamArgs params ++
            shape.indices.map (fun binder => Expr.fvar binder.internalName))
      let internalName := .num (simpleInternalName "mutualMotive") index
      let userName : Name :=
        .str .anonymous ("motive_" ++ toString (index + 1))
      let motive : OpenBinder := {
        internalName := internalName
        userName := userName
        type :=
          closeOpenBinders shape.indices
            (mkArrow inductExpr (.sort elimLevel))
        binderInfo := .default
      }
      motive :: makeSimpleMutualMotives levels params elimLevel rest (index + 1)

def makeSimpleMutualMinors
    (levels : List Level)
    (params : List OpenBinder)
    (motives : List OpenBinder) :
    List SimpleMutualConstructorShape → Nat →
      Except String (List OpenBinder)
  | [], _ => pure []
  | shape :: rest, index => do
      let ihBinders ← simpleMutualIHBinders motives shape
      let result ←
        simpleMutualMotiveApp motives shape.owner shape.resultIndices
          (simpleMutualCtorApp levels params shape)
      let minor : OpenBinder := {
        internalName := .num (simpleInternalName "mutualMinor") index
        userName := shape.ctor.name
        type := closeOpenBinders (shape.fields ++ ihBinders) result
        binderInfo := .default
      }
      let tail ← makeSimpleMutualMinors
        levels params motives rest (index + 1)
      pure (minor :: tail)

def makeSimpleMutualRecursiveCalls
    (recLevelParams : List Name)
    (typeShapes : List SimpleMutualTypeShape)
    (params : List OpenBinder)
    (motives minors : List OpenBinder)
    (shape : SimpleMutualConstructorShape) :
    Except String (List Expr) := do
  let recLevels := recLevelParams.map Level.param
  let fixed :=
    simpleParamArgs params ++
      motives.map (fun motive => Expr.fvar motive.internalName) ++
      minors.map (fun minor => Expr.fvar minor.internalName)
  let rec go :
      List SimpleMutualRecursiveField → Except String (List Expr)
    | [] => pure []
    | recursive :: rest => do
        let some targetShape := listGet? typeShapes recursive.target
          | throw "mutual recursive-call target is out of bounds"
        let applied :=
          applyArgs (.fvar recursive.field.internalName)
            (recursive.args.map fun arg => .fvar arg.internalName)
        let call :=
          applyArgs
            (.const (simpleRecName targetShape.decl.name) recLevels)
            (fixed ++ recursive.indices ++ [applied])
        let call :=
          if recursive.args.isEmpty then call
          else closeOpenLambdas recursive.args call
        let tail ← go rest
        pure (call :: tail)
  go shape.recursiveFields

def makeSimpleMutualRules
    (recLevelParams : List Name)
    (typeShapes : List SimpleMutualTypeShape)
    (params motives minors ruleBinders : List OpenBinder)
    (owner : Nat)
    (ctorShapes : List SimpleMutualConstructorShape) :
    Except String (List RecursorRule) := do
  let rec go :
      List SimpleMutualConstructorShape → Nat →
        Except String (List RecursorRule)
    | [], _ => pure []
    | shape :: rest, minorIndex =>
        if shape.owner != owner then
          go rest (minorIndex + 1)
        else do
          let some minor := listGet? minors minorIndex
            | throw "mutual minor index is out of bounds"
          let recursiveCalls ←
            makeSimpleMutualRecursiveCalls
              recLevelParams typeShapes params motives minors shape
          let body :=
            applyArgs (.fvar minor.internalName)
              (shape.fields.map (fun field => Expr.fvar field.internalName) ++
                recursiveCalls)
          let rule : RecursorRule := {
            ctor := shape.ctor.name
            nFields := shape.fields.length
            rhs := closeOpenLambdas (ruleBinders ++ shape.fields) body
          }
          let tail ← go rest (minorIndex + 1)
          pure (rule :: tail)
  go ctorShapes 0

def validateSimpleMutualRules
    (ctx : CheckerContext)
    (levels : List Level)
    (params motives minors ruleBinders : List OpenBinder)
    (owner : Nat)
    (ctorShapes : List SimpleMutualConstructorShape)
    (rules : List RecursorRule) : Except String Unit := do
  let rec go :
      List SimpleMutualConstructorShape → Nat → List RecursorRule →
        Except String Unit
    | [], _, [] => pure ()
    | [], _, _ => throw "mutual recursor rule count mismatch"
    | shape :: rest, minorIndex, pending =>
        if shape.owner != owner then
          go rest (minorIndex + 1) pending
        else
          match pending with
          | [] => throw "mutual recursor rule count mismatch"
          | rule :: tail => do
              let some minor := listGet? minors minorIndex
                | throw "mutual rule minor index is out of bounds"
              let gotType ← check ctx rule.rhs
              let expectedResult ←
                simpleMutualMotiveApp motives owner shape.resultIndices
                  (simpleMutualCtorApp levels params shape)
              let expectedType :=
                closeOpenBinders
                  (ruleBinders ++ shape.fields)
                  expectedResult
              unless ← isDefEq ctx gotType expectedType do
                throw "generated mutual recursor rule is not type preserving"
              let _ := minor
              go rest (minorIndex + 1) tail
  go ctorShapes 0 rules

def addSimpleMutualInductive
    (env : Environment)
    (decl : SimpleMutualInductiveDecl)
    (maxRecDepth : Nat := 0)
    (maxNatSize : Nat := leanNatMaxSizeDefault)
    (nativeEvaluator : Option NativeEvaluator := none) : Except String Environment := do
  if Name.hasDuplicates decl.levelParams then
    throw "duplicate universe parameter"
  if decl.types.length < 2 then
    throw "mutual inductive admission requires at least two datatypes"
  let typeNames := simpleMutualNames decl
  unless simpleNameListUnique typeNames do
    throw "duplicate mutual inductive type name"
  let recNames := typeNames.map simpleRecName
  let ctorNames :=
    decl.types.foldl
      (fun acc type => acc ++ type.ctors.map (fun ctor => ctor.name)) []
  unless simpleNameListUnique (typeNames ++ recNames ++ ctorNames) do
    throw "duplicate mutual inductive, constructor, or recursor name"
  let rec checkFresh : List Name → Except String Unit
    | [] => pure ()
    | name :: rest => do
        if env.contains name then
          throw "mutual inductive declaration name is already declared"
        checkFresh rest
  checkFresh (typeNames ++ recNames ++ ctorNames)

  simpleCheckUniformOccurrences
    typeNames decl.levelParams decl.numParams
    (decl.types.foldl
      (fun acc type => acc ++ type.ctors.map (fun ctor => ctor.type)) [])

  let safety :=
    if decl.isUnsafe then DefinitionSafety.unsafeDef else DefinitionSafety.safe
  let levels := decl.levelParams.map Level.param

  let first :: remaining := decl.types
    | throw "empty mutual inductive declaration"
  checkNoMVarNoFVar first.type
  checkLevelParams first.type decl.levelParams
  let firstCtx := mkChecker env decl.levelParams safety maxRecDepth maxNatSize nativeEvaluator
  let firstTypeType ← check firstCtx first.type
  let _ ← ensureSort firstCtx firstTypeType
  let (headerParamCtx, params, firstAfterParams) ←
    openSimpleHeaderParams firstCtx first.type decl.numParams []
  let (_, firstIndices, firstResult) ←
    openSimpleHeaderIndices headerParamCtx firstAfterParams
  let .sort resultLevel := firstResult
    | throw "mutual inductive result must be a sort"
  let firstShape : SimpleMutualTypeShape := {
    decl := first
    indices := firstIndices
  }

  let rec openRemaining :
      List SimpleMutualTypeDecl →
        Except String (List SimpleMutualTypeShape)
    | [] => pure []
    | type :: rest => do
        checkNoMVarNoFVar type.type
        checkLevelParams type.type decl.levelParams
        let closedCtx := mkChecker env decl.levelParams safety maxRecDepth maxNatSize nativeEvaluator
        let typeType ← check closedCtx type.type
        let _ ← ensureSort closedCtx typeType
        let afterParams ←
          openSimpleConstructorParams headerParamCtx params type.type
        let (_, indices, result) ←
          openSimpleHeaderIndices headerParamCtx afterParams
        let .sort level := result
          | throw "mutual inductive result must be a sort"
        unless Level.equivalent level resultLevel do
          throw "mutually inductive types must live in the same universe"
        let tail ← openRemaining rest
        pure ({ decl := type, indices := indices } :: tail)
  let tailShapes ← openRemaining remaining
  let typeShapes := firstShape :: tailShapes

  let baseInfos :=
    typeShapes.map fun shape =>
      ({
        base := {
          name := shape.decl.name
          levelParams := decl.levelParams
          type := shape.decl.type
        }
        numParams := decl.numParams
        numIndices := shape.indices.length
        all := typeNames
        ctors := shape.decl.ctors.map (fun ctor => ctor.name)
        numNested := 0
        isRec := false
        isReflexive := false
        isUnsafe := decl.isUnsafe
      } : InductiveInfo)
  let work0 :=
    baseInfos.foldl
      (fun work info => work.addUnchecked (.inductInfo info))
      env

  let rec processTypes
      (work : Environment)
      (types : List SimpleMutualTypeShape)
      (owner : Nat) :
      Except String (Environment × List SimpleMutualConstructorShape) := do
    match types with
    | [] => pure (work, [])
    | typeShape :: rest =>
        let rec processCtors
            (work : Environment)
            (ctors : List SimpleConstructorDecl)
            (ctorIndex : Nat) :
            Except String (Environment × List SimpleMutualConstructorShape) := do
          match ctors with
          | [] => pure (work, [])
          | ctor :: more => do
              checkNoMVarNoFVar ctor.type
              checkLevelParams ctor.type decl.levelParams
              let closedCtorCtx := mkChecker work decl.levelParams safety maxRecDepth maxNatSize nativeEvaluator
              let ctorTypeType ← check closedCtorCtx ctor.type
              let _ ← ensureSort closedCtorCtx ctorTypeType
              let ctorCtx : CheckerContext := {
                headerParamCtx with env := work
              }
              let afterParams ←
                openSimpleConstructorParams ctorCtx params ctor.type
              let (_, fields, recursiveFields, result) ←
                openSimpleMutualConstructorFields
                  ctorCtx typeNames typeShapes levels params
                  resultLevel afterParams
              let some appInfo :=
                  simpleMutualAppInfo?
                    typeNames typeShapes levels params result
                | throw "mutual constructor has invalid return type"
              unless appInfo.target == owner do
                throw "mutual constructor returns the wrong datatype"
              let work' := work.addUnchecked (.ctorInfo {
                base := {
                  name := ctor.name
                  levelParams := decl.levelParams
                  type := ctor.type
                }
                induct := typeShape.decl.name
                cidx := ctorIndex
                numParams := decl.numParams
                numFields := fields.length
                isUnsafe := decl.isUnsafe
              })
              let (done, later) ←
                processCtors work' more (ctorIndex + 1)
              pure (done, {
                owner := owner
                ctor := ctor
                fields := fields
                recursiveFields := recursiveFields
                resultIndices := appInfo.indices
              } :: later)
        let (afterCtors, ownShapes) ←
          processCtors work typeShape.decl.ctors 0
        let (done, laterShapes) ←
          processTypes afterCtors rest (owner + 1)
        pure (done, ownShapes ++ laterShapes)

  let (work1, ctorShapes) ← processTypes work0 typeShapes 0
  let isRecursive := simpleMutualHasRecursiveFields ctorShapes
  let isReflexive := simpleMutualHasReflexiveFields ctorShapes
  let finalInfos :=
    baseInfos.map fun info =>
      ({ info with
        isRec := isRecursive
        isReflexive := isReflexive
      } : InductiveInfo)
  let work1 :=
    finalInfos.foldl
      (fun work info => replaceSimpleInductiveInfo work info)
      work1

  let elimName := simpleFreshElimName decl.levelParams
  let elimOnlyAtZero := !Level.isNotZero resultLevel
  let elimLevel : Level :=
    if elimOnlyAtZero then .zero else .param elimName
  let recLevelParams :=
    if elimOnlyAtZero then decl.levelParams
    else elimName :: decl.levelParams
  let motives :=
    makeSimpleMutualMotives levels params elimLevel typeShapes 0
  let minors ←
    makeSimpleMutualMinors levels params motives ctorShapes 0
  let ruleBinders := params ++ motives ++ minors

  let rec buildRecInfos
      (shapes : List SimpleMutualTypeShape)
      (owner : Nat) :
      Except String (List RecursorInfo) := do
    match shapes with
    | [] => pure []
    | shape :: rest => do
        let some motive := listGet? motives owner
          | throw "mutual motive index is out of bounds"
        let indexArgs :=
          shape.indices.map (fun index => Expr.fvar index.internalName)
        let inductExpr :=
          applyArgs (.const shape.decl.name levels)
            (simpleParamArgs params ++ indexArgs)
        let major : OpenBinder := {
          internalName := .num (simpleInternalName "mutualMajor") owner
          userName := .str .anonymous "t"
          type := inductExpr
          binderInfo := .default
        }
        let recTypeRaw :=
          closeOpenBinders
            (ruleBinders ++ shape.indices ++ [major])
            (simpleMotiveApp
              (.fvar motive.internalName) indexArgs
              (.fvar major.internalName))
        let recType := recTypeRaw.inferImplicitAll true
        let rules ←
          makeSimpleMutualRules
            recLevelParams typeShapes params motives minors
            ruleBinders owner ctorShapes
        let info : RecursorInfo := {
          base := {
            name := simpleRecName shape.decl.name
            levelParams := recLevelParams
            type := recType
          }
          all := typeNames
          numParams := decl.numParams
          numIndices := shape.indices.length
          numMotives := motives.length
          numMinors := minors.length
          rules := rules
          k := false
          isUnsafe := decl.isUnsafe
        }
        let tail ← buildRecInfos rest (owner + 1)
        pure (info :: tail)

  let recInfos ← buildRecInfos typeShapes 0
  let work2 :=
    recInfos.foldl
      (fun work info => work.addUnchecked (.recInfo info))
      work1

  let rec validateRecInfos
      (infos : List RecursorInfo)
      (owner : Nat) : Except String Unit := do
    match infos with
    | [] => pure ()
    | info :: rest => do
        let recCtx := mkChecker work2 recLevelParams safety maxRecDepth maxNatSize nativeEvaluator
        let recTypeType ← check recCtx info.base.type
        let _ ← ensureSort recCtx recTypeType
        validateSimpleMutualRules
          recCtx levels params motives minors ruleBinders
          owner ctorShapes info.rules
        validateRecInfos rest (owner + 1)
  validateRecInfos recInfos 0

  pure work2

end Kernel

end PSC1Kernel
