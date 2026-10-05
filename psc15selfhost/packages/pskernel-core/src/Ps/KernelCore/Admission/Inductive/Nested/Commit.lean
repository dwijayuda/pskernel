import Ps.KernelCore.Admission.Inductive.Nested.Validation

/-
Nested-inductive final environment commit helpers.

This module constructs the user-visible rename map and commits the restored
declarations while excluding auxiliary flattening families from the resulting
environment.

The top-level transaction remains in `Admission.lean`.
-/

def psKernelSimpleNestedMakeRenamesWorker
    (families : List PsKernelSimpleNestedAuxFamily) :
    PsKernelName ->
    Nat ->
    List (Prod PsKernelName PsKernelName) :=
  match families with
  | List.nil =>
      fun
        (_mainRec : PsKernelName)
        (_index : Nat) =>
        List.nil
  | List.cons family rest =>
      let smaller :
          PsKernelName ->
          Nat ->
          List (Prod PsKernelName PsKernelName) :=
        psKernelSimpleNestedMakeRenamesWorker
          rest;
      fun
        (mainRec : PsKernelName)
        (index : Nat) =>
        List.cons
          (Prod.mk
            (psKernelSimpleRecName
              family.auxName)
            (psKernelNameAppendIndexAfter
              mainRec
              index))
          (smaller
            mainRec
            (Nat.succ index))

def psKernelSimpleNestedMakeRenames
    (mainRec : PsKernelName)
    (families : List PsKernelSimpleNestedAuxFamily) :
    List (Prod PsKernelName PsKernelName) :=
  psKernelSimpleNestedMakeRenamesWorker
    families
    mainRec
    1

def psKernelSimpleNestedAddWithoutAux
    (fuel : Nat)
    (environment : PsKernelEnvironment)
    (decl : PsKernelSimpleMutualInductiveDecl)
    (types : List PsKernelSimpleMutualTypeDecl)
    (maxRecDepth : Nat)
    (maxNatSize : Nat) :
    Except String PsKernelEnvironment :=
  match types with
  | List.nil =>
      Except.error
        "empty nested inductive declaration"
  | List.cons first rest =>
      match rest with
      | List.nil =>
          psKernelAddSimpleInductive
            fuel
            environment
            (PsKernelSimpleInductiveDecl.mk
              decl.levelParams
              first.name
              first.type
              first.ctors
              decl.isUnsafe
              decl.numParams)
            maxRecDepth
            maxNatSize
      | List.cons _ _ =>
          psKernelAddSimpleMutualInductive
            fuel
            environment
            (PsKernelSimpleMutualInductiveDecl.mk
              decl.levelParams
              decl.numParams
              types
              decl.isUnsafe)
            maxRecDepth
            maxNatSize

