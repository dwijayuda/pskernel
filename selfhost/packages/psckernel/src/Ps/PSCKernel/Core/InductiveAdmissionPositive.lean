import Ps.PSCKernel.Core.InductiveAdmissionUniverse

-- Safe recursive positivity layer for one ordinary, non-nested inductive family.
-- This still returns validation metadata only; public transactional installation
-- waits for constructor and recursor generation to be implemented together.

structure PsCKernelOrdinaryInductivePositiveValidation where
  numIndices : Nat
  constructorFields : List Nat
  isRec : Bool
  isReflexive : Bool

structure PsCKernelInductivePositiveCtorValidation where
  fieldCount : Nat
  isRec : Bool
  isReflexive : Bool

structure PsCKernelInductivePositiveCtorsValidation where
  constructorFields : List Nat
  isRec : Bool
  isReflexive : Bool


def psCKernelInductivePositiveOr (left right : Bool) : Bool :=
  if left then true else right


partial def psCKernelInductivePositiveOccurrenceValid
    (env : PsCKernelEnvironment)
    (typeName : PsCKernelName)
    (levelParams : List PsCKernelName)
    (params : List PsCKernelInductiveOpenParam)
    (numIndices : Nat)
    (expr : PsCKernelExpr)
    (lctx : PsCKernelLocalContext) : Bool :=
  let reduced := psCKernelExprWhnfBasic env lctx expr
  if !psCKernelInductiveExprContainsConst reduced typeName then
    true
  else
    match reduced with
    | PsCKernelExpr.forallE name domain body binderInfo =>
        if psCKernelInductiveExprContainsConst domain typeName then
          false
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
          psCKernelInductivePositiveOccurrenceValid
            env
            typeName
            levelParams
            params
            numIndices
            openedBody
            nextContext
    | _ =>
        psCKernelInductiveValidResult
          reduced
          typeName
          levelParams
          params
          numIndices


partial def psCKernelInductivePositiveValidateFields?
    (env : PsCKernelEnvironment)
    (typeName : PsCKernelName)
    (levelParams : List PsCKernelName)
    (params : List PsCKernelInductiveOpenParam)
    (numIndices : Nat)
    (resultLevel : PsCKernelLevel)
    (cursor : PsCKernelExpr)
    (lctx : PsCKernelLocalContext)
    (fieldCount : Nat)
    (isRec : Bool)
    (isReflexive : Bool) : Option PsCKernelInductivePositiveCtorValidation :=
  let reduced := psCKernelExprWhnfBasic env lctx cursor
  match reduced with
  | PsCKernelExpr.forallE name domain body binderInfo =>
      match psCKernelInductiveUniverseExprLevel? env lctx domain with
      | none => none
      | some fieldLevel =>
          if
              !psCKernelInductiveUniverseFieldAllowed
                resultLevel
                fieldLevel then
            none
          else
            let recursive := psCKernelInductiveExprContainsConst domain typeName
            if
                recursive &&
                !psCKernelInductivePositiveOccurrenceValid
                  env
                  typeName
                  levelParams
                  params
                  numIndices
                  domain
                  lctx then
              none
            else
              let reflexive :=
                match domain with
                | PsCKernelExpr.forallE _ _ _ _ => recursive
                | _ => false
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
              psCKernelInductivePositiveValidateFields?
                env
                typeName
                levelParams
                params
                numIndices
                resultLevel
                openedBody
                nextContext
                (Nat.add fieldCount 1)
                (psCKernelInductivePositiveOr isRec recursive)
                (psCKernelInductivePositiveOr isReflexive reflexive)
  | _ =>
      if
          psCKernelInductiveValidResult
            reduced
            typeName
            levelParams
            params
            numIndices then
        some {
          fieldCount := fieldCount
          isRec := isRec
          isReflexive := isReflexive
        }
      else
        none


partial def psCKernelInductivePositiveValidateParams?
    (env : PsCKernelEnvironment)
    (typeName : PsCKernelName)
    (levelParams : List PsCKernelName)
    (allParams : List PsCKernelInductiveOpenParam)
    (remainingParams : List PsCKernelInductiveOpenParam)
    (numIndices : Nat)
    (resultLevel : PsCKernelLevel)
    (cursor : PsCKernelExpr)
    (lctx : PsCKernelLocalContext) : Option PsCKernelInductivePositiveCtorValidation :=
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
            psCKernelInductivePositiveValidateParams?
              env
              typeName
              levelParams
              allParams
              rest
              numIndices
              resultLevel
              openedBody
              nextContext
          else
            none
      | _ => none
  | [] =>
      psCKernelInductivePositiveValidateFields?
        env
        typeName
        levelParams
        allParams
        numIndices
        resultLevel
        cursor
        lctx
        0
        false
        false


partial def psCKernelInductivePositiveValidateCtors?
    (env : PsCKernelEnvironment)
    (typeName : PsCKernelName)
    (recName : PsCKernelName)
    (levelParams : List PsCKernelName)
    (params : List PsCKernelInductiveOpenParam)
    (numIndices : Nat)
    (resultLevel : PsCKernelLevel)
    (ctors : List PsCKernelConstructorDecl)
    (seen : List PsCKernelName) : Option PsCKernelInductivePositiveCtorsValidation :=
  match ctors with
  | [] =>
      some {
        constructorFields := []
        isRec := false
        isReflexive := false
      }
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
            psCKernelInductivePositiveValidateParams?
              env
              typeName
              levelParams
              params
              params
              numIndices
              resultLevel
              ctor.type
              psCKernelLocalContextEmpty with
        | none => none
        | some current =>
            match
                psCKernelInductivePositiveValidateCtors?
                  env
                  typeName
                  recName
                  levelParams
                  params
                  numIndices
                  resultLevel
                  rest
                  (ctor.name :: seen) with
            | none => none
            | some tail =>
                some {
                  constructorFields := current.fieldCount :: tail.constructorFields
                  isRec := psCKernelInductivePositiveOr current.isRec tail.isRec
                  isReflexive :=
                    psCKernelInductivePositiveOr
                      current.isReflexive
                      tail.isReflexive
                }


def psCKernelValidateOrdinaryInductivePositive?
    (env : PsCKernelEnvironment)
    (decl : PsCKernelInductiveDecl) :
    Option PsCKernelOrdinaryInductivePositiveValidation :=
  -- Lean skips positivity for unsafe inductives. That path is deliberately not
  -- admitted by this first safe slice; it will get its own explicit contract.
  if decl.isUnsafe then
    none
  else if !Nat.beq decl.numNested 0 then
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
                psCKernelInductiveTemporaryTypeInfo
                  decl
                  typeDecl
                  header.numIndices
              match psCKernelEnvironmentTryAdd env typeInfo with
              | none => none
              | some workEnv =>
                  match
                      psCKernelInductivePositiveValidateCtors?
                        workEnv
                        typeDecl.name
                        recName
                        decl.levelParams
                        header.params
                        header.numIndices
                        header.resultLevel
                        typeDecl.ctors
                        [] with
                  | none => none
                  | some ctorValidation =>
                      some {
                        numIndices := header.numIndices
                        constructorFields := ctorValidation.constructorFields
                        isRec := ctorValidation.isRec
                        isReflexive := ctorValidation.isReflexive
                      }
    | _ => none
