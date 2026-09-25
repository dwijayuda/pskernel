import PSC1Kernel.MutualInductive

namespace PSC1Kernel

namespace Kernel

/--
First checked nested-inductive slice.

The transformation is intentionally bounded to declarations with no shared
parameters. Nested occurrences through an already-declared, non-mutual outer
inductive family are eliminated into auxiliary mutual datatypes, checked by
the ordinary mutual path, restored, and rechecked before publication.
-/
structure SimpleNestedAuxCtorMap where
  auxCtor : Name
  outerCtor : Name

structure SimpleNestedAuxFamily where
  auxName : Name
  outerName : Name
  outerLevels : List Level
  fixedParams : List Expr
  nestedTemplate : Expr
  ctorMap : List SimpleNestedAuxCtorMap

structure SimpleNestedMapState where
  aux : List SimpleNestedAuxFamily
  fresh : Nat
  created : List SimpleMutualTypeDecl

def simpleNestedPrefix : Name :=
  .str .anonymous "_nested"

partial def simpleNestedExprUsesReserved : Expr → Bool
  | .const name _ => simpleNestedPrefix.isPrefixOf name
  | .app fn arg =>
      simpleNestedExprUsesReserved fn ||
        simpleNestedExprUsesReserved arg
  | .lam _ type body _ | .forallE _ type body _ =>
      simpleNestedExprUsesReserved type ||
        simpleNestedExprUsesReserved body
  | .letE _ type value body _ =>
      simpleNestedExprUsesReserved type ||
        simpleNestedExprUsesReserved value ||
        simpleNestedExprUsesReserved body
  | .mdata _ body => simpleNestedExprUsesReserved body
  | .proj typeName _ body =>
      simpleNestedPrefix.isPrefixOf typeName ||
        simpleNestedExprUsesReserved body
  | .bvar _ | .fvar _ | .mvar _ | .sort _ | .lit _ => false

def simpleNestedCheckReserved
    (decl : SimpleMutualInductiveDecl) : Except String Unit := do
  let rec checkTypes : List SimpleMutualTypeDecl → Except String Unit
    | [] => pure ()
    | type :: rest => do
        if simpleNestedPrefix.isPrefixOf type.name ||
            simpleNestedExprUsesReserved type.type then
          throw "reserved prefix '_nested' occurs in nested inductive declaration"
        let rec checkCtors : List SimpleConstructorDecl → Except String Unit
          | [] => pure ()
          | ctor :: more => do
              if simpleNestedPrefix.isPrefixOf ctor.name ||
                  simpleNestedExprUsesReserved ctor.type then
                throw "reserved prefix '_nested' occurs in nested inductive constructor"
              checkCtors more
        checkCtors type.ctors
        checkTypes rest
  checkTypes decl.types

partial def simpleNestedInstantiateFirstParams
    (type : Expr) : List Expr → Except String Expr
  | [] => pure type
  | arg :: rest =>
      match type with
      | .forallE _ _ body _ =>
          simpleNestedInstantiateFirstParams
            (body.instantiate1 arg) rest
      | _ =>
          throw "ill-formed nested inductive parameter instantiation"

def simpleNestedLookupRebase
    (name : Name)
    (sourceParams targetParams : List OpenBinder) : Option Expr :=
  let rec go : List OpenBinder → List OpenBinder → Option Expr
    | f :: fs, t :: ts =>
        if Name.eq f.internalName name then
          some (.fvar t.internalName)
        else
          go fs ts
    | _, _ => none
  go sourceParams targetParams

partial def simpleNestedRebaseParams
    (e : Expr)
    (sourceParams targetParams : List OpenBinder) : Expr :=
  match e with
  | .fvar name =>
      (simpleNestedLookupRebase name sourceParams targetParams).getD e
  | .app fn arg =>
      .app
        (simpleNestedRebaseParams fn sourceParams targetParams)
        (simpleNestedRebaseParams arg sourceParams targetParams)
  | .lam name type body binderInfo =>
      .lam name
        (simpleNestedRebaseParams type sourceParams targetParams)
        (simpleNestedRebaseParams body sourceParams targetParams)
        binderInfo
  | .forallE name type body binderInfo =>
      .forallE name
        (simpleNestedRebaseParams type sourceParams targetParams)
        (simpleNestedRebaseParams body sourceParams targetParams)
        binderInfo
  | .letE name type value body nondep =>
      .letE name
        (simpleNestedRebaseParams type sourceParams targetParams)
        (simpleNestedRebaseParams value sourceParams targetParams)
        (simpleNestedRebaseParams body sourceParams targetParams)
        nondep
  | .mdata metadata body =>
      .mdata metadata (simpleNestedRebaseParams body sourceParams targetParams)
  | .proj typeName index body =>
      .proj typeName index (simpleNestedRebaseParams body sourceParams targetParams)
  | .bvar _ | .mvar _ | .sort _ | .const _ _ | .lit _ => e

partial def simpleNestedOpenConstructorParams
    (type : Expr)
    (count : Nat)
    (index : Nat := 0)
    (rev : List OpenBinder := []) :
    Except String (List OpenBinder × Expr) := do
  if count == 0 then
    pure (rev.reverse, type)
  else
    match type with
    | .forallE userName domain body binderInfo =>
        let internalName := .num (simpleInternalName "nestedCtorParam") index
        let binder : OpenBinder := {
          internalName := internalName
          userName := userName
          type := domain
          binderInfo := binderInfo
        }
        simpleNestedOpenConstructorParams
          (body.instantiate1 (.fvar internalName))
          (count - 1) (index + 1) (binder :: rev)
    | _ =>
        throw "nested preprocessing constructor parameter mismatch"

inductive SimpleNestedBinderKind where
  | forallK
  | lambdaK

partial def simpleNestedOpenRestorationParams
    (e : Expr)
    (count : Nat)
    (kind? : Option SimpleNestedBinderKind := none)
    (index : Nat := 0)
    (rev : List OpenBinder := []) :
    Except String (SimpleNestedBinderKind × List OpenBinder × Expr) := do
  if count == 0 then
    pure (kind?.getD .forallK, rev.reverse, e)
  else
    match e with
    | .forallE userName domain body binderInfo =>
        match kind? with
        | some .lambdaK =>
            throw "restored nested binders mix forall and lambda"
        | _ =>
            let internalName := .num (simpleInternalName "nestedRestoreParam") index
            let binder : OpenBinder := {
              internalName := internalName
              userName := userName
              type := domain
              binderInfo := binderInfo
            }
            simpleNestedOpenRestorationParams
              (body.instantiate1 (.fvar internalName))
              (count - 1) (some .forallK) (index + 1)
              (binder :: rev)
    | .lam userName domain body binderInfo =>
        match kind? with
        | some .forallK =>
            throw "restored nested binders mix forall and lambda"
        | _ =>
            let internalName := .num (simpleInternalName "nestedRestoreParam") index
            let binder : OpenBinder := {
              internalName := internalName
              userName := userName
              type := domain
              binderInfo := binderInfo
            }
            simpleNestedOpenRestorationParams
              (body.instantiate1 (.fvar internalName))
              (count - 1) (some .lambdaK) (index + 1)
              (binder :: rev)
    | _ =>
        throw "failed to restore nested inductive parameters"

def simpleNestedCloseRestoration
    (kind : SimpleNestedBinderKind)
    (params : List OpenBinder)
    (body : Expr) : Expr :=
  match kind with
  | .forallK => closeOpenBinders params body
  | .lambdaK => closeOpenLambdas params body

def simpleNestedFindFamily?
    (template : Expr) : List SimpleNestedAuxFamily →
      Option SimpleNestedAuxFamily
  | [] => none
  | family :: rest =>
      if Expr.eq family.nestedTemplate template then
        some family
      else
        simpleNestedFindFamily? template rest

def simpleNestedAuxNameTaken
    (env : Environment)
    (families : List SimpleNestedAuxFamily)
    (name : Name) : Bool :=
  env.contains name ||
    families.any (fun family => Name.eq family.auxName name)

partial def simpleNestedFreshAuxName
    (env : Environment)
    (families : List SimpleNestedAuxFamily)
    (outer : Name)
    (index : Nat) : Name × Nat :=
  let base := simpleNestedPrefix.append outer
  let candidate := base.appendIndexAfter index
  if simpleNestedAuxNameTaken env families candidate then
    simpleNestedFreshAuxName env families outer (index + 1)
  else
    (candidate, index + 1)

def simpleNestedCtorName
    (outerName auxName ctorName : Name) : Except String Name :=
  match ctorName.replacePrefix outerName auxName with
  | some name => pure name
  | none => throw "nested outer constructor name is outside its inductive namespace"

def simpleNestedEnsureFamily
    (env : Environment)
    (declLevels : List Name)
    (canonicalParams currentParams : List OpenBinder)
    (template : Expr)
    (fixedCurrent : List Expr)
    (state : SimpleNestedMapState) :
    Except String (SimpleNestedAuxFamily × SimpleNestedMapState) := do
  match simpleNestedFindFamily? template state.aux with
  | some family => pure (family, state)
  | none =>
      let .const outerName outerLevels := template.getAppFn
        | throw "nested family head is not a constant"
      let some (.inductInfo outer) := env.find? outerName
        | throw "nested family head is not an inductive datatype"
      match outer.all with
      | [only] =>
          unless Name.eq only outerName do
            throw "nested outer inductive metadata is inconsistent"
      | _ =>
          throw "nested outer mutual families are not yet supported"
      let canonicalFixed := template.getAppArgs
      if canonicalFixed.length != outer.numParams ||
          fixedCurrent.length != outer.numParams then
        throw "nested template does not contain exactly the fixed outer parameters"
      let (auxName, fresh') :=
        simpleNestedFreshAuxName env state.aux outerName state.fresh
      let outerType0 :=
        outer.base.type.instantiateLevelParams
          outer.base.levelParams outerLevels
      let auxTypeOpen ←
        simpleNestedInstantiateFirstParams outerType0 fixedCurrent
      let auxType := closeOpenBinders currentParams auxTypeOpen
      let rec makeAuxCtors :
          List Name → Except String (List SimpleConstructorDecl ×
            List SimpleNestedAuxCtorMap)
        | [] => pure ([], [])
        | outerCtorName :: rest => do
            let some (.ctorInfo outerCtor) := env.find? outerCtorName
              | throw "nested outer constructor metadata is missing"
            let auxCtorName ←
              simpleNestedCtorName outerName auxName outerCtorName
            let ctorType0 :=
              outerCtor.base.type.instantiateLevelParams
                outerCtor.base.levelParams outerLevels
            let auxCtorOpen ←
              simpleNestedInstantiateFirstParams ctorType0 fixedCurrent
            let auxCtorType := closeOpenBinders currentParams auxCtorOpen
            let (laterCtors, laterMap) ← makeAuxCtors rest
            pure (
              { name := auxCtorName, type := auxCtorType } :: laterCtors,
              {
                auxCtor := auxCtorName
                outerCtor := outerCtorName
              } :: laterMap)
      let (auxCtors, ctorMap) ← makeAuxCtors outer.ctors
      let family : SimpleNestedAuxFamily := {
        auxName := auxName
        outerName := outerName
        outerLevels := outerLevels
        fixedParams := canonicalFixed
        nestedTemplate := template
        ctorMap := ctorMap
      }
      let auxTypeDecl : SimpleMutualTypeDecl := {
        name := auxName
        type := auxType
        ctors := auxCtors
      }
      let _ := canonicalParams
      pure (family, {
        aux := state.aux ++ [family]
        fresh := fresh'
        created := state.created ++ [auxTypeDecl]
      })

def simpleNestedHasNew
    (newNames : List Name)
    (e : Expr) : Bool :=
  simpleMutualContainsConst newNames e

partial def simpleNestedMapExpr
    (env : Environment)
    (declLevels : List Name)
    (newNames : List Name)
    (canonicalParams currentParams : List OpenBinder)
    (e : Expr)
    (state : SimpleNestedMapState) :
    Except String (Expr × SimpleNestedMapState) := do
  let fn := e.getAppFn
  let args := e.getAppArgs
  match fn with
  | .const outerName outerLevels =>
      match env.find? outerName with
      | some (.inductInfo outer) =>
          if args.length >= outer.numParams then
            let fixed := args.take outer.numParams
            if fixed.any (simpleNestedHasNew newNames) then
              let canonicalFixed :=
                fixed.map fun arg =>
                  simpleNestedRebaseParams
                    arg currentParams canonicalParams
              let template :=
                applyArgs (.const outerName outerLevels) canonicalFixed
              let (family, state') ←
                simpleNestedEnsureFamily
                  env declLevels canonicalParams currentParams
                  template fixed state
              let auxLevels := declLevels.map Level.param
              return (
                applyArgs (.const family.auxName auxLevels)
                  (currentParams.map
                    (fun param => Expr.fvar param.internalName) ++
                    args.drop outer.numParams),
                state')
      | _ => pure ()
  | _ => pure ()

  match e with
  | .app f a => do
      let (f', state1) ←
        simpleNestedMapExpr
          env declLevels newNames canonicalParams currentParams f state
      let (a', state2) ←
        simpleNestedMapExpr
          env declLevels newNames canonicalParams currentParams a state1
      pure (.app f' a', state2)
  | .lam name type body binderInfo => do
      let (type', state1) ←
        simpleNestedMapExpr
          env declLevels newNames canonicalParams currentParams type state
      let (body', state2) ←
        simpleNestedMapExpr
          env declLevels newNames canonicalParams currentParams body state1
      pure (.lam name type' body' binderInfo, state2)
  | .forallE name type body binderInfo => do
      let (type', state1) ←
        simpleNestedMapExpr
          env declLevels newNames canonicalParams currentParams type state
      let (body', state2) ←
        simpleNestedMapExpr
          env declLevels newNames canonicalParams currentParams body state1
      pure (.forallE name type' body' binderInfo, state2)
  | .letE name type value body nondep => do
      let (type', state1) ←
        simpleNestedMapExpr
          env declLevels newNames canonicalParams currentParams type state
      let (value', state2) ←
        simpleNestedMapExpr
          env declLevels newNames canonicalParams currentParams value state1
      let (body', state3) ←
        simpleNestedMapExpr
          env declLevels newNames canonicalParams currentParams body state2
      pure (.letE name type' value' body' nondep, state3)
  | .mdata metadata body => do
      let (body', state') ←
        simpleNestedMapExpr
          env declLevels newNames canonicalParams currentParams body state
      pure (.mdata metadata body', state')
  | .proj typeName index body => do
      let (body', state') ←
        simpleNestedMapExpr
          env declLevels newNames canonicalParams currentParams body state
      pure (.proj typeName index body', state')
  | .bvar _ | .fvar _ | .mvar _ | .sort _ | .const _ _ | .lit _ =>
      pure (e, state)

def simpleNestedMapConstructors
    (env : Environment)
    (declLevels : List Name)
    (newNames : List Name)
    (canonicalParams : List OpenBinder)
    (numParams : Nat)
    (ctors : List SimpleConstructorDecl)
    (state : SimpleNestedMapState) :
    Except String (List SimpleConstructorDecl × SimpleNestedMapState) := do
  match ctors with
  | [] => pure ([], state)
  | ctor :: rest => do
      let (currentParams, body) ←
        simpleNestedOpenConstructorParams ctor.type numParams
      let (body', state1) ←
        simpleNestedMapExpr
          env declLevels newNames canonicalParams currentParams
          body state
      let type' := closeOpenBinders currentParams body'
      let (later, state2) ←
        simpleNestedMapConstructors
          env declLevels newNames canonicalParams numParams
          rest state1
      pure ({ ctor with type := type' } :: later, state2)

partial def simpleNestedProcessQueue
    (env : Environment)
    (declLevels : List Name)
    (newNames : List Name)
    (canonicalParams : List OpenBinder)
    (numParams : Nat)
    (pending : List SimpleMutualTypeDecl)
    (done : List SimpleMutualTypeDecl)
    (state : SimpleNestedMapState) :
    Except String (List SimpleMutualTypeDecl × SimpleNestedMapState) := do
  match pending with
  | [] => pure (done, state)
  | type :: rest => do
      let state0 := { state with created := [] }
      let (ctors', state1) ←
        simpleNestedMapConstructors
          env declLevels newNames canonicalParams numParams
          type.ctors state0
      let mapped := { type with ctors := ctors' }
      simpleNestedProcessQueue
        env declLevels newNames canonicalParams numParams
        (rest ++ state1.created)
        (done ++ [mapped])
        { state1 with created := [] }

def simpleNestedFindAuxByName?
    (name : Name) : List SimpleNestedAuxFamily →
      Option SimpleNestedAuxFamily
  | [] => none
  | family :: rest =>
      if Name.eq family.auxName name then
        some family
      else
        simpleNestedFindAuxByName? name rest

def simpleNestedFindCtorMap?
    (name : Name) : List SimpleNestedAuxFamily →
      Option (SimpleNestedAuxFamily × Name)
  | [] => none
  | family :: rest =>
      match family.ctorMap.find? (fun entry => Name.eq entry.auxCtor name) with
      | some entry => some (family, entry.outerCtor)
      | none => simpleNestedFindCtorMap? name rest

def simpleNestedFindRename?
    (name : Name) : List (Name × Name) → Option Name
  | [] => none
  | (oldName, newName) :: rest =>
      if Name.eq name oldName then
        some newName
      else
        simpleNestedFindRename? name rest

partial def simpleNestedRestoreOpen
    (families : List SimpleNestedAuxFamily)
    (recRename : List (Name × Name))
    (canonicalParams currentParams : List OpenBinder)
    (numParams : Nat)
    (e : Expr) : Expr :=
  match e with
  | .app _ _ =>
      let fn := e.getAppFn
      let args :=
        e.getAppArgs.map
          (fun arg =>
            simpleNestedRestoreOpen
              families recRename canonicalParams currentParams
              numParams arg)
      match fn with
      | .const name levels =>
          match simpleNestedFindRename? name recRename with
          | some renamed =>
              applyArgs (.const renamed levels) args
          | none =>
              match simpleNestedFindAuxByName? name families with
              | some family =>
                  let nested :=
                    simpleNestedRebaseParams
                      family.nestedTemplate canonicalParams currentParams
                  if args.length < numParams then
                    applyArgs (.const name levels) args
                  else
                    applyArgs nested (args.drop numParams)
              | none =>
                  match simpleNestedFindCtorMap? name families with
                  | some (family, outerCtor) =>
                      if args.length < numParams then
                        applyArgs (.const name levels) args
                      else
                        let fixed :=
                          family.fixedParams.map fun arg =>
                            simpleNestedRebaseParams
                              arg canonicalParams currentParams
                        applyArgs
                          (.const outerCtor family.outerLevels)
                          (fixed ++ args.drop numParams)
                  | none =>
                      let fn' :=
                        simpleNestedRestoreOpen
                          families recRename canonicalParams currentParams
                          numParams fn
                      applyArgs fn' args
      | _ =>
          let fn' :=
            simpleNestedRestoreOpen
              families recRename canonicalParams currentParams
              numParams fn
          applyArgs fn' args
  | .lam name type body binderInfo =>
      .lam name
        (simpleNestedRestoreOpen
          families recRename canonicalParams currentParams numParams type)
        (simpleNestedRestoreOpen
          families recRename canonicalParams currentParams numParams body)
        binderInfo
  | .forallE name type body binderInfo =>
      .forallE name
        (simpleNestedRestoreOpen
          families recRename canonicalParams currentParams numParams type)
        (simpleNestedRestoreOpen
          families recRename canonicalParams currentParams numParams body)
        binderInfo
  | .letE name type value body nondep =>
      .letE name
        (simpleNestedRestoreOpen
          families recRename canonicalParams currentParams numParams type)
        (simpleNestedRestoreOpen
          families recRename canonicalParams currentParams numParams value)
        (simpleNestedRestoreOpen
          families recRename canonicalParams currentParams numParams body)
        nondep
  | .mdata metadata body =>
      .mdata metadata
        (simpleNestedRestoreOpen
          families recRename canonicalParams currentParams numParams body)
  | .proj typeName index body =>
      let typeName' :=
        match simpleNestedFindAuxByName? typeName families with
        | some family => family.outerName
        | none => typeName
      .proj typeName' index
        (simpleNestedRestoreOpen
          families recRename canonicalParams currentParams numParams body)
  | .const name levels =>
      match simpleNestedFindRename? name recRename with
      | some renamed => .const renamed levels
      | none =>
          match simpleNestedFindAuxByName? name families with
          | some family =>
              if numParams == 0 then
                simpleNestedRebaseParams
                  family.nestedTemplate canonicalParams currentParams
              else
                e
          | none =>
              match simpleNestedFindCtorMap? name families with
              | some (family, outerCtor) =>
                  if numParams == 0 then
                    let fixed :=
                      family.fixedParams.map fun arg =>
                        simpleNestedRebaseParams
                          arg canonicalParams currentParams
                    applyArgs
                      (.const outerCtor family.outerLevels) fixed
                  else
                    e
              | none => e
  | .bvar _ | .fvar _ | .mvar _ | .sort _ | .lit _ => e

def simpleNestedRestoreExpr
    (families : List SimpleNestedAuxFamily)
    (recRename : List (Name × Name))
    (canonicalParams : List OpenBinder)
    (numParams : Nat)
    (e : Expr) : Except String Expr := do
  if numParams == 0 then
    pure <|
      simpleNestedRestoreOpen
        families recRename canonicalParams [] 0 e
  else
    let (kind, currentParams, body) ←
      simpleNestedOpenRestorationParams e numParams
    let restored :=
      simpleNestedRestoreOpen
        families recRename canonicalParams currentParams
        numParams body
    pure (simpleNestedCloseRestoration kind currentParams restored)

def simpleNestedRestoreRule
    (families : List SimpleNestedAuxFamily)
    (recRename : List (Name × Name))
    (canonicalParams : List OpenBinder)
    (numParams : Nat)
    (mapCtor : Bool)
    (rule : RecursorRule) : Except String RecursorRule := do
  let ctor :=
    if mapCtor then
      match simpleNestedFindCtorMap? rule.ctor families with
      | some (_, outerCtor) => outerCtor
      | none => rule.ctor
    else
      rule.ctor
  let rhs ←
    simpleNestedRestoreExpr
      families recRename canonicalParams numParams rule.rhs
  pure {
    ctor := ctor
    nFields := rule.nFields
    rhs := rhs
  }

def simpleNestedRestoreRules
    (families : List SimpleNestedAuxFamily)
    (recRename : List (Name × Name))
    (canonicalParams : List OpenBinder)
    (numParams : Nat)
    (mapCtor : Bool) :
    List RecursorRule → Except String (List RecursorRule)
  | [] => pure []
  | rule :: rest => do
      let restored ←
        simpleNestedRestoreRule
          families recRename canonicalParams numParams mapCtor rule
      let tail ←
        simpleNestedRestoreRules
          families recRename canonicalParams numParams mapCtor rest
      pure (restored :: tail)

def simpleNestedRestoreRecursor
    (originalNames : List Name)
    (families : List SimpleNestedAuxFamily)
    (recRename : List (Name × Name))
    (canonicalParams : List OpenBinder)
    (numParams : Nat)
    (newName : Name)
    (mapCtor : Bool)
    (info : RecursorInfo) : Except String RecursorInfo := do
  let type ←
    simpleNestedRestoreExpr
      families recRename canonicalParams numParams info.base.type
  let rules ←
    simpleNestedRestoreRules
      families recRename canonicalParams numParams mapCtor info.rules
  pure {
    info with
    base := {
      info.base with
      name := newName
      type := type
    }
    all := originalNames
    rules := rules
  }

def simpleNestedAddOriginals
    (transformed : Environment)
    (base : Environment)
    (decl : SimpleMutualInductiveDecl)
    (canonicalParams : List OpenBinder)
    (families : List SimpleNestedAuxFamily)
    (recRename : List (Name × Name)) :
    Except String Environment := do
  let originalNames := simpleMutualNames decl
  let rec go :
      List SimpleMutualTypeDecl → Environment → Except String Environment
    | [], work => pure work
    | type :: rest, work => do
        let some (.inductInfo info) := transformed.find? type.name
          | throw "restored nested inductive metadata is missing"
        let restoredInfo : InductiveInfo := {
          info with
          base := {
            info.base with
            type :=
              (← simpleNestedRestoreExpr
                families recRename canonicalParams decl.numParams
                info.base.type)
          }
          all := originalNames
          numNested := families.length
        }
        let work := work.addUnchecked (.inductInfo restoredInfo)
        let rec copyCtors :
            List Name → Environment → Except String Environment
          | [], work => pure work
          | ctorName :: more, work => do
              let some (.ctorInfo ctor) := transformed.find? ctorName
                | throw "restored nested constructor metadata is missing"
              let restoredCtor : ConstructorInfo := {
                ctor with
                base := {
                  ctor.base with
                  type :=
                    (← simpleNestedRestoreExpr
                      families recRename canonicalParams decl.numParams
                      ctor.base.type)
                }
              }
              copyCtors more (work.addUnchecked (.ctorInfo restoredCtor))
        let work ← copyCtors info.ctors work
        let recName := simpleRecName type.name
        let some (.recInfo recInfo) := transformed.find? recName
          | throw "restored nested recursor metadata is missing"
        let restoredRec :=
          ← simpleNestedRestoreRecursor
            originalNames families recRename canonicalParams decl.numParams
            recName false recInfo
        let work := work.addUnchecked (.recInfo restoredRec)
        go rest work
  go decl.types base

def simpleNestedAddAuxRecursors
    (transformed : Environment)
    (base : Environment)
    (originalNames : List Name)
    (canonicalParams : List OpenBinder)
    (numParams : Nat)
    (families : List SimpleNestedAuxFamily)
    (recRename : List (Name × Name)) :
    Except String Environment := do
  let rec go :
      List SimpleNestedAuxFamily → Environment → Except String Environment
    | [], work => pure work
    | family :: rest, work => do
        let oldName := simpleRecName family.auxName
        let some newName := simpleNestedFindRename? oldName recRename
          | throw "nested auxiliary recursor rename is missing"
        if work.contains newName then
          throw "nested auxiliary recursor rename collides with an existing declaration"
        let some (.recInfo recInfo) := transformed.find? oldName
          | throw "nested auxiliary recursor metadata is missing"
        let restored ←
          simpleNestedRestoreRecursor
            originalNames families recRename canonicalParams numParams
            newName true recInfo
        go rest (work.addUnchecked (.recInfo restored))
  go families base

def simpleNestedValidateRestored
    (transformed finalEnv : Environment)
    (decl : SimpleMutualInductiveDecl)
    (canonicalParams : List OpenBinder)
    (families : List SimpleNestedAuxFamily)
    (recRename : List (Name × Name)) : Except String Unit := do
  let safety :=
    if decl.isUnsafe then DefinitionSafety.unsafeDef else DefinitionSafety.safe
  let originalNames := simpleMutualNames decl

  let rec checkTemplates : List SimpleNestedAuxFamily → Except String Unit
    | [] => pure ()
    | family :: rest => do
        let ctx := mkChecker finalEnv decl.levelParams safety
        let _ ← check ctx family.nestedTemplate
        checkTemplates rest
  checkTemplates families

  let rec checkOriginals : List SimpleMutualTypeDecl → Except String Unit
    | [] => pure ()
    | type :: rest => do
        let rec checkCtors : List SimpleConstructorDecl → Except String Unit
          | [] => pure ()
          | ctor :: more => do
              let some (.ctorInfo info) := finalEnv.find? ctor.name
                | throw "restored constructor missing during validation"
              let ctx := mkChecker finalEnv decl.levelParams safety
              let _ ← check ctx info.base.type
              checkCtors more
        checkCtors type.ctors
        let recName := simpleRecName type.name
        let some (.recInfo recInfo) := finalEnv.find? recName
          | throw "restored recursor missing during validation"
        let ctx := mkChecker finalEnv recInfo.base.levelParams safety
        let recTypeType ← check ctx recInfo.base.type
        let _ ← ensureSort ctx recTypeType
        let rec checkRules : List RecursorRule → Except String Unit
          | [] => pure ()
          | rule :: more => do
              let _ ← check ctx rule.rhs
              checkRules more
        checkRules recInfo.rules
        checkOriginals rest
  checkOriginals decl.types

  let rec checkAux : List SimpleNestedAuxFamily → Except String Unit
    | [] => pure ()
    | family :: rest => do
        let oldName := simpleRecName family.auxName
        let some newName := simpleNestedFindRename? oldName recRename
          | throw "nested auxiliary recursor rename missing during validation"
        let some (.recInfo oldInfo) := transformed.find? oldName
          | throw "transformed nested auxiliary recursor missing"
        let some (.recInfo newInfo) := finalEnv.find? newName
          | throw "restored nested auxiliary recursor missing"
        let oldCtx :=
          mkChecker transformed oldInfo.base.levelParams safety
        let newCtx :=
          mkChecker finalEnv newInfo.base.levelParams safety
        let rec compareRules :
            List RecursorRule → List RecursorRule → Except String Unit
          | [], [] => pure ()
          | oldRule :: oldRest, newRule :: newRest => do
              let oldType ← check oldCtx oldRule.rhs
              let expected ←
                simpleNestedRestoreExpr
                  families recRename canonicalParams decl.numParams oldType
              let got ← check newCtx newRule.rhs
              unless ← isDefEq newCtx got expected do
                throw "restored nested recursor rule is not type preserving"
              compareRules oldRest newRest
          | _, _ =>
              throw "restored nested recursor rule count mismatch"
        compareRules oldInfo.rules newInfo.rules
        let typeType ← check newCtx newInfo.base.type
        let _ ← ensureSort newCtx typeType
        checkAux rest
  checkAux families
  let _ := originalNames
  pure ()

def addSimpleNestedInductive
    (env : Environment)
    (decl : SimpleMutualInductiveDecl) : Except String Environment := do
  simpleNestedCheckReserved decl
  if decl.types.isEmpty then
    throw "empty nested inductive declaration"
  let first :: _ := decl.types
    | throw "empty nested inductive declaration"
  let safety :=
    if decl.isUnsafe then DefinitionSafety.unsafeDef else DefinitionSafety.safe
  let firstCtx := mkChecker env decl.levelParams safety
  let firstTypeType ← check firstCtx first.type
  let _ ← ensureSort firstCtx firstTypeType
  let (_, canonicalParams, _) ←
    openSimpleHeaderParams firstCtx first.type decl.numParams []
  let originalNames := simpleMutualNames decl
  let initialState : SimpleNestedMapState := {
    aux := []
    fresh := 1
    created := []
  }
  let (transformedTypes, state) ←
    match simpleNestedProcessQueue
      env decl.levelParams originalNames canonicalParams decl.numParams
      decl.types [] initialState with
    | .ok value => pure value
    | .error err => throw ("nested preprocessing: " ++ err)
  if state.aux.isEmpty then
    match transformedTypes with
    | [type] =>
        addSimpleInductive env {
          levelParams := decl.levelParams
          name := type.name
          type := type.type
          ctors := type.ctors
          isUnsafe := decl.isUnsafe
          numParams := decl.numParams
        }
    | _ =>
        addSimpleMutualInductive env {
          levelParams := decl.levelParams
          numParams := decl.numParams
          types := transformedTypes
          isUnsafe := decl.isUnsafe
        }
  else
    let transformed ←
      match addSimpleMutualInductive env {
        levelParams := decl.levelParams
        numParams := decl.numParams
        types := transformedTypes
        isUnsafe := decl.isUnsafe
      } with
      | .ok value => pure value
      | .error err => throw ("nested transformed admission: " ++ err)
    let mainRec := simpleRecName (decl.types.head?.map (fun t => t.name) |>.getD .anonymous)
    let rec makeRenames :
        List SimpleNestedAuxFamily → Nat → List (Name × Name)
      | [], _ => []
      | family :: rest, index =>
          (simpleRecName family.auxName,
            mainRec.appendIndexAfter index) ::
              makeRenames rest (index + 1)
    let recRename := makeRenames state.aux 1
    let restoredOriginals ←
      match simpleNestedAddOriginals
        transformed env decl canonicalParams state.aux recRename with
      | .ok value => pure value
      | .error err => throw ("nested original restoration: " ++ err)
    let finalEnv ←
      match simpleNestedAddAuxRecursors
        transformed restoredOriginals originalNames
        canonicalParams decl.numParams state.aux recRename with
      | .ok value => pure value
      | .error err => throw ("nested auxiliary restoration: " ++ err)
    match simpleNestedValidateRestored
      transformed finalEnv decl canonicalParams state.aux recRename with
    | .ok _ => pure ()
    | .error err => throw ("nested restored validation: " ++ err)
    pure finalEnv

end Kernel

end PSC1Kernel
