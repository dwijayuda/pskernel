import Ps.KernelCore.Admission.Inductive.Nested.Commit

/-
Nested-inductive top-level admission transaction.

Read this file for the complete kernel-side control flow:
validate reserved names -> discover/flatten -> admit the extended mutual bundle
-> restore user-facing declarations -> validate restoration -> commit without
auxiliary implementation details.

Detailed validation and commit helpers live in preceding theory modules.
-/

def psKernelAddSimpleNestedInductive
    (fuel : Nat)
    (environment : PsKernelEnvironment)
    (decl : PsKernelSimpleMutualInductiveDecl)
    (maxRecDepth : Nat)
    (maxNatSize : Nat) :
    Except String PsKernelEnvironment :=
  match
      psKernelSimpleNestedCheckReserved
        decl with
  | Except.error error =>
      Except.error error
  | Except.ok _ =>
      let originalNames :=
        psKernelSimpleMutualNames
          decl.types;
      match
          psKernelSimpleCheckUniformOccurrences
            originalNames
            decl.levelParams
            decl.numParams
            (psKernelSimpleMutualCtorTypes
              decl.types) with
      | Except.error error =>
          Except.error error
      | Except.ok _ =>
          match decl.types with
          | List.nil =>
              Except.error
                "empty nested inductive declaration"
          | List.cons first _ =>
              let safety :=
                if decl.isUnsafe then
                  PsKernelDefinitionSafety.unsafeDef
                else
                  PsKernelDefinitionSafety.safe;
              let firstSession :=
                psKernelMkCheckerSession
                  environment
                  decl.levelParams
                  safety
                  maxRecDepth
                  maxNatSize;
              match
                  psKernelSessionCheck
                    fuel
                    firstSession
                    first.type with
              | Except.error error =>
                  Except.error error
              | Except.ok firstTypeType =>
                  match
                      psKernelSessionEnsureSort
                        fuel
                        (Prod.snd firstTypeType)
                        (Prod.fst firstTypeType) with
                  | Except.error error =>
                      Except.error error
                  | Except.ok firstSort =>
                      match
                          psKernelOpenSimpleHeaderParams
                            fuel
                            (Prod.snd firstSort)
                            first.type
                            decl.numParams with
                      | Except.error error =>
                          Except.error error
                      | Except.ok paramsResult =>
                          let canonicalParams :=
                            paramsResult.binders;
                          let initialState :=
                            PsKernelSimpleNestedMapState.mk
                              List.nil
                              1
                              List.nil;
                          match
                              psKernelSimpleNestedProcessQueue
                                fuel
                                environment
                                decl.levelParams
                                originalNames
                                canonicalParams
                                decl.numParams
                                decl.types
                                List.nil
                                initialState with
                          | Except.error error =>
                              Except.error
                                (String.Internal.append
                                  "nested preprocessing: "
                                  error)
                          | Except.ok processed =>
                              match processed.state.aux with
                              | List.nil =>
                                  psKernelSimpleNestedAddWithoutAux
                                    fuel
                                    environment
                                    decl
                                    processed.types
                                    maxRecDepth
                                    maxNatSize
                              | List.cons _ _ =>
                                  match
                                      psKernelAddSimpleMutualInductive
                                        fuel
                                        environment
                                        (PsKernelSimpleMutualInductiveDecl.mk
                                          decl.levelParams
                                          decl.numParams
                                          processed.types
                                          decl.isUnsafe)
                                        maxRecDepth
                                        maxNatSize with
                                  | Except.error error =>
                                      Except.error
                                        (String.Internal.append
                                          "nested transformed admission: "
                                          error)
                                  | Except.ok transformed =>
                                      let mainRec :=
                                        psKernelSimpleRecName
                                          first.name;
                                      let renames :=
                                        psKernelSimpleNestedMakeRenames
                                          mainRec
                                          processed.state.aux;
                                      match
                                          psKernelSimpleNestedAddOriginals
                                            transformed
                                            environment
                                            decl
                                            canonicalParams
                                            processed.state.aux
                                            renames with
                                      | Except.error error =>
                                          Except.error
                                            (String.Internal.append
                                              "nested original restoration: "
                                              error)
                                      | Except.ok restoredOriginals =>
                                          match
                                              psKernelSimpleNestedAddAuxRecursors
                                                transformed
                                                restoredOriginals
                                                originalNames
                                                canonicalParams
                                                decl.numParams
                                                processed.state.aux
                                                renames with
                                          | Except.error error =>
                                              Except.error
                                                (String.Internal.append
                                                  "nested auxiliary restoration: "
                                                  error)
                                          | Except.ok finalEnvironment =>
                                              match
                                                  psKernelSimpleNestedValidateRestored
                                                    fuel
                                                    transformed
                                                    finalEnvironment
                                                    decl
                                                    canonicalParams
                                                    processed.state.aux
                                                    renames
                                                    maxRecDepth
                                                    maxNatSize with
                                              | Except.error error =>
                                                  Except.error
                                                    (String.Internal.append
                                                      "nested restored validation: "
                                                      error)
                                              | Except.ok _ =>
                                                  Except.ok
                                                    finalEnvironment
