import Ps.KernelCore.Admission.Inductive.Nested.Flatten

/-
Nested-inductive expression and recursor restoration.

After the transformed mutual bundle is admitted, this module maps auxiliary
family/constructor names back into user-facing expressions, constructor types,
recursor types, and recursor rules.

Environment installation of restored declarations is kept in `Restore.lean`.
-/

def psKernelSimpleNestedFindAuxByName
    (name : PsKernelName)
    (families : List PsKernelSimpleNestedAuxFamily) :
    Option PsKernelSimpleNestedAuxFamily :=
  match families with
  | List.nil =>
      Option.none
  | List.cons family rest =>
      if psKernelNameEq family.auxName name then
        Option.some family
      else
        psKernelSimpleNestedFindAuxByName
          name
          rest

structure PsKernelSimpleNestedCtorLookup where
  family : PsKernelSimpleNestedAuxFamily
  outerCtor : PsKernelName

def psKernelSimpleNestedFindCtorInMap
    (name : PsKernelName)
    (family : PsKernelSimpleNestedAuxFamily)
    (entries : List PsKernelSimpleNestedAuxCtorMap) :
    Option PsKernelSimpleNestedCtorLookup :=
  match entries with
  | List.nil =>
      Option.none
  | List.cons entry rest =>
      if psKernelNameEq entry.auxCtor name then
        Option.some
          (PsKernelSimpleNestedCtorLookup.mk
            family
            entry.outerCtor)
      else
        psKernelSimpleNestedFindCtorInMap
          name
          family
          rest

def psKernelSimpleNestedFindCtorMapWorker
    (families : List PsKernelSimpleNestedAuxFamily) :
    PsKernelName ->
    Option PsKernelSimpleNestedCtorLookup :=
  match families with
  | List.nil =>
      fun
        (_name : PsKernelName) =>
        Option.none
  | List.cons family rest =>
      let smaller :
          PsKernelName ->
          Option PsKernelSimpleNestedCtorLookup :=
        psKernelSimpleNestedFindCtorMapWorker
          rest;
      fun
        (name : PsKernelName) =>
        match
            psKernelSimpleNestedFindCtorInMap
              name
              family
              family.ctorMap with
        | Option.some found =>
            Option.some found
        | Option.none =>
            smaller name

def psKernelSimpleNestedFindCtorMap
    (name : PsKernelName)
    (families : List PsKernelSimpleNestedAuxFamily) :
    Option PsKernelSimpleNestedCtorLookup :=
  psKernelSimpleNestedFindCtorMapWorker
    families
    name

def psKernelSimpleNestedFindRename
    (name : PsKernelName)
    (renames : List (Prod PsKernelName PsKernelName)) :
    Option PsKernelName :=
  match renames with
  | List.nil =>
      Option.none
  | List.cons entry rest =>
      if
          psKernelNameEq
            name
            (Prod.fst entry) then
        Option.some
          (Prod.snd entry)
      else
        psKernelSimpleNestedFindRename
          name
          rest

def psKernelSimpleNestedMapExprList
    (transform : PsKernelExpr -> PsKernelExpr)
    (values : List PsKernelExpr) :
    List PsKernelExpr :=
  match values with
  | List.nil =>
      List.nil
  | List.cons head tail =>
      List.cons
        (transform head)
        (psKernelSimpleNestedMapExprList
          transform
          tail)

def psKernelSimpleNestedRestoreOpenWithFuel
    (fuel : Nat) :
    List PsKernelSimpleNestedAuxFamily ->
    List (Prod PsKernelName PsKernelName) ->
    List PsKernelOpenBinder ->
    List PsKernelOpenBinder ->
    Nat ->
    PsKernelExpr ->
    PsKernelExpr :=
  match fuel with
  | Nat.zero =>
      fun
        (_families : List PsKernelSimpleNestedAuxFamily)
        (_renames : List (Prod PsKernelName PsKernelName))
        (_canonicalParams : List PsKernelOpenBinder)
        (_currentParams : List PsKernelOpenBinder)
        (_numParams : Nat)
        (expr : PsKernelExpr) =>
        expr
  | Nat.succ remaining =>
      let smaller :=
        psKernelSimpleNestedRestoreOpenWithFuel
          remaining;
      fun
        (families : List PsKernelSimpleNestedAuxFamily)
        (renames : List (Prod PsKernelName PsKernelName))
        (canonicalParams : List PsKernelOpenBinder)
        (currentParams : List PsKernelOpenBinder)
        (numParams : Nat)
        (expr : PsKernelExpr) =>
        match expr with
        | PsKernelExpr.app _ _ =>
            let fn : PsKernelExpr :=
              psKernelExprGetAppFn expr;
            let restoreOne : PsKernelExpr -> PsKernelExpr :=
              fun (arg : PsKernelExpr) =>
                smaller
                  families
                  renames
                  canonicalParams
                  currentParams
                  numParams
                  arg;
            let args : List PsKernelExpr :=
              psKernelSimpleNestedMapExprList
                restoreOne
                (psKernelExprGetAppArgs expr);
            match fn with
            | PsKernelExpr.const name levels =>
                match
                    psKernelSimpleNestedFindRename
                      name
                      renames with
                | Option.some renamed =>
                    psKernelApplyArgs
                      (PsKernelExpr.const
                        renamed
                        levels)
                      args
                | Option.none =>
                    match
                        psKernelSimpleNestedFindAuxByName
                          name
                          families with
                    | Option.some family =>
                        let nested : PsKernelExpr :=
                          psKernelSimpleNestedRebaseParams
                            family.nestedTemplate
                            canonicalParams
                            currentParams;
                        if
                            psKernelNatLt
                              (psKernelExprListLength args)
                              numParams then
                          psKernelApplyArgs
                            (PsKernelExpr.const
                              name
                              levels)
                            args
                        else
                          psKernelApplyArgs
                            nested
                            (psKernelExprListDrop
                              numParams
                              args)
                    | Option.none =>
                        match
                            psKernelSimpleNestedFindCtorMap
                              name
                              families with
                        | Option.some found =>
                            if
                                psKernelNatLt
                                  (psKernelExprListLength args)
                                  numParams then
                              psKernelApplyArgs
                                (PsKernelExpr.const
                                  name
                                  levels)
                                args
                            else
                              let fixed : List PsKernelExpr :=
                                psKernelSimpleNestedRebaseExprList
                                  found.family.fixedParams
                                  canonicalParams
                                  currentParams;
                              psKernelApplyArgs
                                (PsKernelExpr.const
                                  found.outerCtor
                                  found.family.outerLevels)
                                (psKernelExprListAppend
                                  fixed
                                  (psKernelExprListDrop
                                    numParams
                                    args))
                        | Option.none =>
                            let fnRestored : PsKernelExpr :=
                              smaller
                                families
                                renames
                                canonicalParams
                                currentParams
                                numParams
                                fn;
                            psKernelApplyArgs
                              fnRestored
                              args
            | _ =>
                let fnRestored : PsKernelExpr :=
                  smaller
                    families
                    renames
                    canonicalParams
                    currentParams
                    numParams
                    fn;
                psKernelApplyArgs
                  fnRestored
                  args
        | PsKernelExpr.lam
            name
            type
            body
            binderInfo =>
            PsKernelExpr.lam
              name
              (smaller
                families
                renames
                canonicalParams
                currentParams
                numParams
                type)
              (smaller
                families
                renames
                canonicalParams
                currentParams
                numParams
                body)
              binderInfo
        | PsKernelExpr.forallE
            name
            type
            body
            binderInfo =>
            PsKernelExpr.forallE
              name
              (smaller
                families
                renames
                canonicalParams
                currentParams
                numParams
                type)
              (smaller
                families
                renames
                canonicalParams
                currentParams
                numParams
                body)
              binderInfo
        | PsKernelExpr.letE
            name
            type
            value
            body
            nondep =>
            PsKernelExpr.letE
              name
              (smaller
                families
                renames
                canonicalParams
                currentParams
                numParams
                type)
              (smaller
                families
                renames
                canonicalParams
                currentParams
                numParams
                value)
              (smaller
                families
                renames
                canonicalParams
                currentParams
                numParams
                body)
              nondep
        | PsKernelExpr.mdata metadata body =>
            PsKernelExpr.mdata
              metadata
              (smaller
                families
                renames
                canonicalParams
                currentParams
                numParams
                body)
        | PsKernelExpr.proj typeName index body =>
            let restoredTypeName : PsKernelName :=
              match
                  psKernelSimpleNestedFindAuxByName
                    typeName
                    families with
              | Option.some family =>
                  family.outerName
              | Option.none =>
                  typeName;
            PsKernelExpr.proj
              restoredTypeName
              index
              (smaller
                families
                renames
                canonicalParams
                currentParams
                numParams
                body)
        | PsKernelExpr.const name levels =>
            match
                psKernelSimpleNestedFindRename
                  name
                  renames with
            | Option.some renamed =>
                PsKernelExpr.const
                  renamed
                  levels
            | Option.none =>
                match
                    psKernelSimpleNestedFindAuxByName
                      name
                      families with
                | Option.some family =>
                    if Nat.beq numParams 0 then
                      psKernelSimpleNestedRebaseParams
                        family.nestedTemplate
                        canonicalParams
                        currentParams
                    else
                      expr
                | Option.none =>
                    match
                        psKernelSimpleNestedFindCtorMap
                          name
                          families with
                    | Option.some found =>
                        if Nat.beq numParams 0 then
                          let fixed : List PsKernelExpr :=
                            psKernelSimpleNestedRebaseExprList
                              found.family.fixedParams
                              canonicalParams
                              currentParams;
                          psKernelApplyArgs
                            (PsKernelExpr.const
                              found.outerCtor
                              found.family.outerLevels)
                            fixed
                        else
                          expr
                    | Option.none =>
                        expr
        | _ =>
            expr

def psKernelSimpleNestedRestoreOpen
    (families : List PsKernelSimpleNestedAuxFamily)
    (renames : List (Prod PsKernelName PsKernelName))
    (canonicalParams : List PsKernelOpenBinder)
    (currentParams : List PsKernelOpenBinder)
    (numParams : Nat)
    (expr : PsKernelExpr) :
    PsKernelExpr :=
  psKernelSimpleNestedRestoreOpenWithFuel
    (Nat.succ
      (psKernelExprNodeCount expr))
    families
    renames
    canonicalParams
    currentParams
    numParams
    expr

def psKernelSimpleNestedRestoreExpr
    (families : List PsKernelSimpleNestedAuxFamily)
    (renames : List (Prod PsKernelName PsKernelName))
    (canonicalParams : List PsKernelOpenBinder)
    (numParams : Nat)
    (expr : PsKernelExpr) :
    Except String PsKernelExpr :=
  if Nat.beq numParams 0 then
    Except.ok
      (psKernelSimpleNestedRestoreOpen
        families
        renames
        canonicalParams
        List.nil
        0
        expr)
  else
    match
        psKernelSimpleNestedOpenRestorationParams
          expr
          numParams with
    | Except.error error =>
        Except.error error
    | Except.ok opened =>
        let restored :=
          psKernelSimpleNestedRestoreOpen
            families
            renames
            canonicalParams
            opened.params
            numParams
            opened.result;
        Except.ok
          (psKernelSimpleNestedCloseRestoration
            opened.kind
            opened.params
            restored)

def psKernelSimpleNestedRestoreRule
    (families : List PsKernelSimpleNestedAuxFamily)
    (renames : List (Prod PsKernelName PsKernelName))
    (canonicalParams : List PsKernelOpenBinder)
    (numParams : Nat)
    (mapCtor : Bool)
    (rule : PsKernelRecursorRule) :
    Except String PsKernelRecursorRule :=
  let ctor : PsKernelName :=
    if mapCtor then
      match
          psKernelSimpleNestedFindCtorMap
            rule.ctor
            families with
      | Option.some found =>
          found.outerCtor
      | Option.none =>
          rule.ctor
    else
      rule.ctor;
  match
      psKernelSimpleNestedRestoreExpr
        families
        renames
        canonicalParams
        numParams
        rule.rhs with
  | Except.error error =>
      Except.error error
  | Except.ok rhs =>
      Except.ok
        (PsKernelRecursorRule.mk
          ctor
          rule.nFields
          rhs)

def psKernelSimpleNestedRestoreRules
    (families : List PsKernelSimpleNestedAuxFamily)
    (renames : List (Prod PsKernelName PsKernelName))
    (canonicalParams : List PsKernelOpenBinder)
    (numParams : Nat)
    (mapCtor : Bool)
    (rules : List PsKernelRecursorRule) :
    Except String (List PsKernelRecursorRule) :=
  match rules with
  | List.nil =>
      Except.ok List.nil
  | List.cons rule rest =>
      match
          psKernelSimpleNestedRestoreRule
            families
            renames
            canonicalParams
            numParams
            mapCtor
            rule with
      | Except.error error =>
          Except.error error
      | Except.ok restored =>
          match
              psKernelSimpleNestedRestoreRules
                families
                renames
                canonicalParams
                numParams
                mapCtor
                rest with
          | Except.error error =>
              Except.error error
          | Except.ok tail =>
              Except.ok
                (List.cons
                  restored
                  tail)

def psKernelSimpleNestedRestoreRecursor
    (originalNames : List PsKernelName)
    (families : List PsKernelSimpleNestedAuxFamily)
    (renames : List (Prod PsKernelName PsKernelName))
    (canonicalParams : List PsKernelOpenBinder)
    (numParams : Nat)
    (newName : PsKernelName)
    (mapCtor : Bool)
    (info : PsKernelRecursorInfo) :
    Except String PsKernelRecursorInfo :=
  match
      psKernelSimpleNestedRestoreExpr
        families
        renames
        canonicalParams
        numParams
        info.base.type with
  | Except.error error =>
      Except.error error
  | Except.ok restoredType =>
      match
          psKernelSimpleNestedRestoreRules
            families
            renames
            canonicalParams
            numParams
            mapCtor
            info.rules with
      | Except.error error =>
          Except.error error
      | Except.ok restoredRules =>
          Except.ok
            (PsKernelRecursorInfo.mk
              (PsKernelConstantBase.mk
                newName
                info.base.levelParams
                restoredType)
              originalNames
              info.numParams
              info.numIndices
              info.numMotives
              info.numMinors
              restoredRules
              info.k
              info.isUnsafe)


