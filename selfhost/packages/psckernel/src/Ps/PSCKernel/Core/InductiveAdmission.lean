import Ps.PSCKernel.Core.DeclarationAdmission

-- This module begins the dedicated inductive-family admission path.
-- The basic validator is intentionally fail-closed: it validates one ordinary,
-- non-nested, non-recursive inductive family and returns metadata only. It does
-- not expose a half-admitted environment before recursor generation exists.

structure PsCKernelConstructorDecl where
  name : PsCKernelName
  type : PsCKernelExpr

structure PsCKernelInductiveTypeDecl where
  name : PsCKernelName
  type : PsCKernelExpr
  ctors : List PsCKernelConstructorDecl

structure PsCKernelInductiveDecl where
  levelParams : List PsCKernelName
  numParams : Nat
  types : List PsCKernelInductiveTypeDecl
  isUnsafe : Bool
  numNested : Nat

structure PsCKernelInductiveOpenParam where
  fvarId : PsCKernelFVarId
  userName : PsCKernelName
  type : PsCKernelExpr
  binderInfo : PsCKernelBinderInfo

structure PsCKernelInductiveHeaderState where
  lctx : PsCKernelLocalContext
  params : List PsCKernelInductiveOpenParam
  numIndices : Nat
  resultLevel : PsCKernelLevel

structure PsCKernelOrdinaryInductiveBasicValidation where
  numIndices : Nat
  constructorFields : List Nat


def psCKernelInductiveRecName (name : PsCKernelName) : PsCKernelName :=
  psCKernelStrName name "rec"


def psCKernelInductiveAppendParam
    (params : List PsCKernelInductiveOpenParam)
    (param : PsCKernelInductiveOpenParam) : List PsCKernelInductiveOpenParam :=
  match params with
  | [] => [param]
  | head :: rest => head :: psCKernelInductiveAppendParam rest param


def psCKernelInductiveExpectedLevels
    (params : List PsCKernelName) : List PsCKernelLevel :=
  match params with
  | [] => []
  | name :: rest =>
      PsCKernelLevel.param name :: psCKernelInductiveExpectedLevels rest


def psCKernelInductiveCtorNames
    (ctors : List PsCKernelConstructorDecl) : List PsCKernelName :=
  match ctors with
  | [] => []
  | ctor :: rest => ctor.name :: psCKernelInductiveCtorNames rest


def psCKernelInductiveExprIsTypeInContext
    (env : PsCKernelEnvironment)
    (lctx : PsCKernelLocalContext)
    (expr : PsCKernelExpr) : Bool :=
  match psCKernelCheckBasic? env lctx expr with
  | none => false
  | some exprType =>
      match psCKernelExprWhnfBasic env lctx exprType with
      | PsCKernelExpr.sortE _ => true
      | _ => false


partial def psCKernelInductiveExprContainsConst
    (expr : PsCKernelExpr)
    (target : PsCKernelName) : Bool :=
  match expr with
  | PsCKernelExpr.constE name _ => psCKernelNameEq name target
  | PsCKernelExpr.app fn arg =>
      if psCKernelInductiveExprContainsConst fn target then
        true
      else
        psCKernelInductiveExprContainsConst arg target
  | PsCKernelExpr.lam _ domain body _ =>
      if psCKernelInductiveExprContainsConst domain target then
        true
      else
        psCKernelInductiveExprContainsConst body target
  | PsCKernelExpr.forallE _ domain body _ =>
      if psCKernelInductiveExprContainsConst domain target then
        true
      else
        psCKernelInductiveExprContainsConst body target
  | PsCKernelExpr.letE _ domain value body _ =>
      if psCKernelInductiveExprContainsConst domain target then
        true
      else if psCKernelInductiveExprContainsConst value target then
        true
      else
        psCKernelInductiveExprContainsConst body target
  | PsCKernelExpr.proj typeName _ value =>
      if psCKernelNameEq typeName target then
        true
      else
        psCKernelInductiveExprContainsConst value target
  | _ => false


partial def psCKernelInductiveOpenHeaderGo?
    (env : PsCKernelEnvironment)
    (cursor : PsCKernelExpr)
    (numParams : Nat)
    (paramCount : Nat)
    (numIndices : Nat)
    (lctx : PsCKernelLocalContext)
    (params : List PsCKernelInductiveOpenParam) : Option PsCKernelInductiveHeaderState :=
  let reduced := psCKernelExprWhnfBasic env lctx cursor
  match reduced with
  | PsCKernelExpr.forallE name domain body binderInfo =>
      let fvarId := psCKernelTypeInferenceFreshFVarId lctx
      let nextContext :=
        psCKernelLocalContextMkLocalDecl
          lctx
          fvarId
          name
          domain
          binderInfo
          PsCKernelLocalDeclKind.default
      let openedBody :=
        psCKernelExprInstantiate1 body (PsCKernelExpr.fvar fvarId)
      if Nat.blt paramCount numParams then
        let param : PsCKernelInductiveOpenParam := {
          fvarId := fvarId
          userName := name
          type := domain
          binderInfo := binderInfo
        }
        psCKernelInductiveOpenHeaderGo?
          env
          openedBody
          numParams
          (Nat.add paramCount 1)
          numIndices
          nextContext
          (psCKernelInductiveAppendParam params param)
      else
        psCKernelInductiveOpenHeaderGo?
          env
          openedBody
          numParams
          paramCount
          (Nat.add numIndices 1)
          nextContext
          params
  | PsCKernelExpr.sortE level =>
      if Nat.beq paramCount numParams then
        some {
          lctx := lctx
          params := params
          numIndices := numIndices
          resultLevel := level
        }
      else
        none
  | _ => none


def psCKernelInductiveOpenHeader?
    (env : PsCKernelEnvironment)
    (declType : PsCKernelExpr)
    (numParams : Nat) : Option PsCKernelInductiveHeaderState :=
  psCKernelInductiveOpenHeaderGo?
    env
    declType
    numParams
    0
    0
    psCKernelLocalContextEmpty
    []


def psCKernelInductiveParamArgsMatch
    (args : List PsCKernelExpr)
    (params : List PsCKernelInductiveOpenParam) : Bool :=
  match params, args with
  | [], _ => true
  | _, [] => false
  | param :: restParams, arg :: restArgs =>
      if psCKernelExprEqv arg (PsCKernelExpr.fvar param.fvarId) then
        psCKernelInductiveParamArgsMatch restArgs restParams
      else
        false


def psCKernelInductiveDropArgs
    (args : List PsCKernelExpr)
    (count : Nat) : List PsCKernelExpr :=
  match count, args with
  | 0, _ => args
  | Nat.succ _, [] => []
  | Nat.succ rest, _ :: tail => psCKernelInductiveDropArgs tail rest


def psCKernelInductiveIndicesAvoidType
    (args : List PsCKernelExpr)
    (typeName : PsCKernelName) : Bool :=
  match args with
  | [] => true
  | arg :: rest =>
      if psCKernelInductiveExprContainsConst arg typeName then
        false
      else
        psCKernelInductiveIndicesAvoidType rest typeName


def psCKernelInductiveValidResult
    (result : PsCKernelExpr)
    (typeName : PsCKernelName)
    (levelParams : List PsCKernelName)
    (params : List PsCKernelInductiveOpenParam)
    (numIndices : Nat) : Bool :=
  let head := psCKernelExprGetAppFn result
  let args := psCKernelExprGetAppArgs result
  match head with
  | PsCKernelExpr.constE actualName actualLevels =>
      if !psCKernelNameEq actualName typeName then
        false
      else if
          !psCKernelLevelListEqStructural
            actualLevels
            (psCKernelInductiveExpectedLevels levelParams) then
        false
      else if !Nat.beq args.length (Nat.add params.length numIndices) then
        false
      else if !psCKernelInductiveParamArgsMatch args params then
        false
      else
        psCKernelInductiveIndicesAvoidType
          (psCKernelInductiveDropArgs args params.length)
          typeName
  | _ => false


partial def psCKernelInductiveValidateCtorFields?
    (env : PsCKernelEnvironment)
    (typeName : PsCKernelName)
    (levelParams : List PsCKernelName)
    (params : List PsCKernelInductiveOpenParam)
    (numIndices : Nat)
    (cursor : PsCKernelExpr)
    (lctx : PsCKernelLocalContext)
    (fieldCount : Nat) : Option Nat :=
  let reduced := psCKernelExprWhnfBasic env lctx cursor
  match reduced with
  | PsCKernelExpr.forallE name domain body binderInfo =>
      -- Positivity is a later slice. Until then recursive fields fail closed.
      if psCKernelInductiveExprContainsConst domain typeName then
        none
      else if !psCKernelInductiveExprIsTypeInContext env lctx domain then
        none
      else
        let fvarId := psCKernelTypeInferenceFreshFVarId lctx
        let nextContext :=
          psCKernelLocalContextMkLocalDecl
            lctx
            fvarId
            name
            domain
            binderInfo
            PsCKernelLocalDeclKind.default
        let openedBody :=
          psCKernelExprInstantiate1 body (PsCKernelExpr.fvar fvarId)
        psCKernelInductiveValidateCtorFields?
          env
          typeName
          levelParams
          params
          numIndices
          openedBody
          nextContext
          (Nat.add fieldCount 1)
  | _ =>
      if
          psCKernelInductiveValidResult
            reduced
            typeName
            levelParams
            params
            numIndices then
        some fieldCount
      else
        none


partial def psCKernelInductiveValidateCtorParams?
    (env : PsCKernelEnvironment)
    (typeName : PsCKernelName)
    (levelParams : List PsCKernelName)
    (allParams : List PsCKernelInductiveOpenParam)
    (remainingParams : List PsCKernelInductiveOpenParam)
    (numIndices : Nat)
    (cursor : PsCKernelExpr)
    (lctx : PsCKernelLocalContext) : Option Nat :=
  match remainingParams with
  | param :: rest =>
      let reduced := psCKernelExprWhnfBasic env lctx cursor
      match reduced with
      | PsCKernelExpr.forallE _ domain body _ =>
          if psCKernelIsDefEq env lctx domain param.type then
            let nextContext :=
              psCKernelLocalContextMkLocalDecl
                lctx
                param.fvarId
                param.userName
                param.type
                param.binderInfo
                PsCKernelLocalDeclKind.default
            let openedBody :=
              psCKernelExprInstantiate1
                body
                (PsCKernelExpr.fvar param.fvarId)
            psCKernelInductiveValidateCtorParams?
              env
              typeName
              levelParams
              allParams
              rest
              numIndices
              openedBody
              nextContext
          else
            none
      | _ => none
  | [] =>
      psCKernelInductiveValidateCtorFields?
        env
        typeName
        levelParams
        allParams
        numIndices
        cursor
        lctx
        0


partial def psCKernelInductiveValidateConstructors?
    (env : PsCKernelEnvironment)
    (typeName : PsCKernelName)
    (recName : PsCKernelName)
    (levelParams : List PsCKernelName)
    (params : List PsCKernelInductiveOpenParam)
    (numIndices : Nat)
    (ctors : List PsCKernelConstructorDecl)
    (seen : List PsCKernelName) : Option (List Nat) :=
  match ctors with
  | [] => some []
  | ctor :: rest =>
      if psCKernelAdmissionNameInList seen ctor.name then
        none
      else if psCKernelEnvironmentContains env ctor.name then
        none
      else if psCKernelNameEq ctor.name recName then
        none
      else if !psCKernelAdmissionExprClosed levelParams ctor.type then
        none
      else if !psCKernelAdmissionTypeIsType env ctor.type then
        none
      else
        match
            psCKernelInductiveValidateCtorParams?
              env
              typeName
              levelParams
              params
              params
              numIndices
              ctor.type
              psCKernelLocalContextEmpty with
        | none => none
        | some fieldCount =>
            match
                psCKernelInductiveValidateConstructors?
                  env
                  typeName
                  recName
                  levelParams
                  params
                  numIndices
                  rest
                  (ctor.name :: seen) with
            | none => none
            | some restFields => some (fieldCount :: restFields)


def psCKernelInductiveTemporaryTypeInfo
    (decl : PsCKernelInductiveDecl)
    (typeDecl : PsCKernelInductiveTypeDecl)
    (numIndices : Nat) : PsCKernelConstantInfo :=
  PsCKernelConstantInfo.inductInfo {
    base := {
      name := typeDecl.name
      levelParams := decl.levelParams
      declType := typeDecl.type
    }
    numParams := decl.numParams
    numIndices := numIndices
    all := [typeDecl.name]
    ctors := psCKernelInductiveCtorNames typeDecl.ctors
    numNested := 0
    isRec := false
    isUnsafe := decl.isUnsafe
    isReflexive := false
  }


def psCKernelValidateOrdinaryInductiveBasic?
    (env : PsCKernelEnvironment)
    (decl : PsCKernelInductiveDecl) : Option PsCKernelOrdinaryInductiveBasicValidation :=
  if !Nat.beq decl.numNested 0 then
    none
  else if !psCKernelAdmissionUniqueNames decl.levelParams then
    none
  else
    match decl.types with
    | [typeDecl] =>
        let recName := psCKernelInductiveRecName typeDecl.name
        if psCKernelEnvironmentContains env typeDecl.name then
          none
        else if psCKernelEnvironmentContains env recName then
          none
        else if !psCKernelAdmissionExprClosed decl.levelParams typeDecl.type then
          none
        else if !psCKernelAdmissionTypeIsType env typeDecl.type then
          none
        else
          match psCKernelInductiveOpenHeader? env typeDecl.type decl.numParams with
          | none => none
          | some header =>
              let typeInfo :=
                psCKernelInductiveTemporaryTypeInfo decl typeDecl header.numIndices
              match psCKernelEnvironmentTryAdd env typeInfo with
              | none => none
              | some workEnv =>
                  match
                      psCKernelInductiveValidateConstructors?
                        workEnv
                        typeDecl.name
                        recName
                        decl.levelParams
                        header.params
                        header.numIndices
                        typeDecl.ctors
                        [] with
                  | none => none
                  | some fieldCounts =>
                      some {
                        numIndices := header.numIndices
                        constructorFields := fieldCounts
                      }
    | _ => none
