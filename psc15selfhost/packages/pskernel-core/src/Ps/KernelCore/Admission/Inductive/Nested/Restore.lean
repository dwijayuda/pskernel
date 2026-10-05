import Ps.KernelCore.Admission.Inductive.Nested.RestoreExpr

/-
Nested-inductive environment restoration.

This module installs restored user-facing constructors and auxiliary recursors
after expression/type/rule restoration has completed. It owns environment
mutation only; expression-level restoration lives in `RestoreExpr.lean`.
-/

def psKernelSimpleNestedFamilyListLength
    (families : List PsKernelSimpleNestedAuxFamily) :
    Nat :=
  match families with
  | List.nil =>
      0
  | List.cons _ rest =>
      Nat.succ
        (psKernelSimpleNestedFamilyListLength
          rest)

def psKernelSimpleNestedAddCtorCopiesWorker
    (ctorNames : List PsKernelName) :
    PsKernelEnvironment ->
    PsKernelEnvironment ->
    List PsKernelSimpleNestedAuxFamily ->
    List (Prod PsKernelName PsKernelName) ->
    List PsKernelOpenBinder ->
    Nat ->
    Except String PsKernelEnvironment :=
  match ctorNames with
  | List.nil =>
      fun
        (_transformed : PsKernelEnvironment)
        (work : PsKernelEnvironment)
        (_families : List PsKernelSimpleNestedAuxFamily)
        (_renames : List (Prod PsKernelName PsKernelName))
        (_canonicalParams : List PsKernelOpenBinder)
        (_numParams : Nat) =>
        Except.ok work
  | List.cons ctorName rest =>
      let smaller :=
        psKernelSimpleNestedAddCtorCopiesWorker
          rest;
      fun
        (transformed : PsKernelEnvironment)
        (work : PsKernelEnvironment)
        (families : List PsKernelSimpleNestedAuxFamily)
        (renames : List (Prod PsKernelName PsKernelName))
        (canonicalParams : List PsKernelOpenBinder)
        (numParams : Nat) =>
        match
            psKernelEnvironmentFind
              transformed
              ctorName with
        | Option.none =>
            Except.error
              "restored nested constructor metadata is missing"
        | Option.some infoValue =>
            match infoValue with
            | PsKernelConstantInfo.ctorInfo ctor =>
                match
                    psKernelSimpleNestedRestoreExpr
                      families
                      renames
                      canonicalParams
                      numParams
                      ctor.base.type with
                | Except.error error =>
                    Except.error error
                | Except.ok restoredType =>
                    let restoredCtor :=
                      PsKernelConstructorInfo.mk
                        (PsKernelConstantBase.mk
                          ctor.base.name
                          ctor.base.levelParams
                          restoredType)
                        ctor.induct
                        ctor.cidx
                        ctor.numParams
                        ctor.numFields
                        ctor.isUnsafe;
                    smaller
                      transformed
                      (psKernelEnvironmentAddUnchecked
                        work
                        (PsKernelConstantInfo.ctorInfo
                          restoredCtor))
                      families
                      renames
                      canonicalParams
                      numParams
            | _ =>
                Except.error
                  "restored nested constructor metadata is missing"

def psKernelSimpleNestedAddOriginalsWorker
    (types : List PsKernelSimpleMutualTypeDecl) :
    PsKernelEnvironment ->
    PsKernelEnvironment ->
    List PsKernelName ->
    List PsKernelOpenBinder ->
    Nat ->
    List PsKernelSimpleNestedAuxFamily ->
    List (Prod PsKernelName PsKernelName) ->
    Except String PsKernelEnvironment :=
  match types with
  | List.nil =>
      fun
        (_transformed : PsKernelEnvironment)
        (work : PsKernelEnvironment)
        (_originalNames : List PsKernelName)
        (_canonicalParams : List PsKernelOpenBinder)
        (_numParams : Nat)
        (_families : List PsKernelSimpleNestedAuxFamily)
        (_renames : List (Prod PsKernelName PsKernelName)) =>
        Except.ok work
  | List.cons typeDecl rest =>
      let smaller :=
        psKernelSimpleNestedAddOriginalsWorker
          rest;
      fun
        (transformed : PsKernelEnvironment)
        (work : PsKernelEnvironment)
        (originalNames : List PsKernelName)
        (canonicalParams : List PsKernelOpenBinder)
        (numParams : Nat)
        (families : List PsKernelSimpleNestedAuxFamily)
        (renames : List (Prod PsKernelName PsKernelName)) =>
        match
            psKernelEnvironmentFind
              transformed
              typeDecl.name with
        | Option.none =>
            Except.error
              "restored nested inductive metadata is missing"
        | Option.some infoValue =>
            match infoValue with
            | PsKernelConstantInfo.inductInfo info =>
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
                    let restoredInfo :=
                      PsKernelInductiveInfo.mk
                        (PsKernelConstantBase.mk
                          info.base.name
                          info.base.levelParams
                          restoredType)
                        info.numParams
                        info.numIndices
                        originalNames
                        info.ctors
                        (psKernelSimpleNestedFamilyListLength
                          families)
                        info.isRec
                        info.isReflexive
                        info.isUnsafe;
                    let workWithType :=
                      psKernelEnvironmentAddUnchecked
                        work
                        (PsKernelConstantInfo.inductInfo
                          restoredInfo);
                    match
                        psKernelSimpleNestedAddCtorCopiesWorker
                          info.ctors
                          transformed
                          workWithType
                          families
                          renames
                          canonicalParams
                          numParams with
                    | Except.error error =>
                        Except.error error
                    | Except.ok workWithCtors =>
                        let recName :=
                          psKernelSimpleRecName
                            typeDecl.name;
                        match
                            psKernelEnvironmentFind
                              transformed
                              recName with
                        | Option.none =>
                            Except.error
                              "restored nested recursor metadata is missing"
                        | Option.some recValue =>
                            match recValue with
                            | PsKernelConstantInfo.recInfo recInfo =>
                                match
                                    psKernelSimpleNestedRestoreRecursor
                                      originalNames
                                      families
                                      renames
                                      canonicalParams
                                      numParams
                                      recName
                                      false
                                      recInfo with
                                | Except.error error =>
                                    Except.error error
                                | Except.ok restoredRec =>
                                    smaller
                                      transformed
                                      (psKernelEnvironmentAddUnchecked
                                        workWithCtors
                                        (PsKernelConstantInfo.recInfo
                                          restoredRec))
                                      originalNames
                                      canonicalParams
                                      numParams
                                      families
                                      renames
                            | _ =>
                                Except.error
                                  "restored nested recursor metadata is missing"
            | _ =>
                Except.error
                  "restored nested inductive metadata is missing"

def psKernelSimpleNestedAddOriginals
    (transformed : PsKernelEnvironment)
    (base : PsKernelEnvironment)
    (decl : PsKernelSimpleMutualInductiveDecl)
    (canonicalParams : List PsKernelOpenBinder)
    (families : List PsKernelSimpleNestedAuxFamily)
    (renames : List (Prod PsKernelName PsKernelName)) :
    Except String PsKernelEnvironment :=
  psKernelSimpleNestedAddOriginalsWorker
    decl.types
    transformed
    base
    (psKernelSimpleMutualNames
      decl.types)
    canonicalParams
    decl.numParams
    families
    renames

def psKernelSimpleNestedAddAuxRecursorsWorker
    (pending : List PsKernelSimpleNestedAuxFamily) :
    List PsKernelSimpleNestedAuxFamily ->
    PsKernelEnvironment ->
    PsKernelEnvironment ->
    List PsKernelName ->
    List PsKernelOpenBinder ->
    Nat ->
    List (Prod PsKernelName PsKernelName) ->
    Except String PsKernelEnvironment :=
  match pending with
  | List.nil =>
      fun
        (_allFamilies : List PsKernelSimpleNestedAuxFamily)
        (_transformed : PsKernelEnvironment)
        (work : PsKernelEnvironment)
        (_originalNames : List PsKernelName)
        (_canonicalParams : List PsKernelOpenBinder)
        (_numParams : Nat)
        (_renames : List (Prod PsKernelName PsKernelName)) =>
        Except.ok work
  | List.cons family rest =>
      let smaller :=
        psKernelSimpleNestedAddAuxRecursorsWorker
          rest;
      fun
        (allFamilies : List PsKernelSimpleNestedAuxFamily)
        (transformed : PsKernelEnvironment)
        (work : PsKernelEnvironment)
        (originalNames : List PsKernelName)
        (canonicalParams : List PsKernelOpenBinder)
        (numParams : Nat)
        (renames : List (Prod PsKernelName PsKernelName)) =>
        let oldName :=
          psKernelSimpleRecName
            family.auxName;
        match
            psKernelSimpleNestedFindRename
              oldName
              renames with
        | Option.none =>
            Except.error
              "nested auxiliary recursor rename is missing"
        | Option.some newName =>
            if psKernelEnvironmentContains work newName then
              Except.error
                "nested auxiliary recursor rename collides with an existing declaration"
            else
              match
                  psKernelEnvironmentFind
                    transformed
                    oldName with
              | Option.none =>
                  Except.error
                    "nested auxiliary recursor metadata is missing"
              | Option.some recValue =>
                  match recValue with
                  | PsKernelConstantInfo.recInfo recInfo =>
                      match
                          psKernelSimpleNestedRestoreRecursor
                            originalNames
                            allFamilies
                            renames
                            canonicalParams
                            numParams
                            newName
                            true
                            recInfo with
                      | Except.error error =>
                          Except.error error
                      | Except.ok restored =>
                          smaller
                            allFamilies
                            transformed
                            (psKernelEnvironmentAddUnchecked
                              work
                              (PsKernelConstantInfo.recInfo
                                restored))
                            originalNames
                            canonicalParams
                            numParams
                            renames
                  | _ =>
                      Except.error
                        "nested auxiliary recursor metadata is missing"

def psKernelSimpleNestedAddAuxRecursors
    (transformed : PsKernelEnvironment)
    (base : PsKernelEnvironment)
    (originalNames : List PsKernelName)
    (canonicalParams : List PsKernelOpenBinder)
    (numParams : Nat)
    (families : List PsKernelSimpleNestedAuxFamily)
    (renames : List (Prod PsKernelName PsKernelName)) :
    Except String PsKernelEnvironment :=
  psKernelSimpleNestedAddAuxRecursorsWorker
    families
    families
    transformed
    base
    originalNames
    canonicalParams
    numParams
    renames
