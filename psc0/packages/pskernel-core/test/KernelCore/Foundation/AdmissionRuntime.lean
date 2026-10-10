import KernelCore.Foundation.DefEqNested

def psKernelPortableQuotBaseEnvironment :
    PsKernelEnvironment :=
  let universeName :=
    PsKernelName.str
      PsKernelName.anonymous
      "quotConformanceU"
  let reflName :=
    PsKernelName.str
      psKernelEqName
      "refl"
  let env0 :=
    psKernelEnvironmentAddUnchecked
      psKernelEnvironmentEmpty
      (PsKernelConstantInfo.inductInfo {
        base := {
          name := psKernelEqName
          levelParams :=
            List.cons universeName List.nil
          type :=
            psKernelExpectedEqType
              universeName
        }
        numParams := 2
        numIndices := 1
        all :=
          List.cons psKernelEqName List.nil
        ctors :=
          List.cons reflName List.nil
        numNested := 0
        isRec := false
        isReflexive := true
        isUnsafe := false
      })
  psKernelEnvironmentAddUnchecked
    env0
    (PsKernelConstantInfo.ctorInfo {
      base := {
        name := reflName
        levelParams :=
          List.cons universeName List.nil
        type :=
          psKernelExpectedEqReflType
            universeName
      }
      induct := psKernelEqName
      cidx := 0
      numParams := 2
      numFields := 0
      isUnsafe := false
    })

def psKernelReferenceQuotBaseEnvironment :
    PSC1Kernel.Environment :=
  let universeName :=
    PSC1Kernel.Name.str
      PSC1Kernel.Name.anonymous
      "quotConformanceU"
  let reflName :=
    PSC1Kernel.Name.str
      PSC1Kernel.Kernel.kernelEqName
      "refl"
  let env0 :=
    PSC1Kernel.Environment.empty.addUnchecked
      (PSC1Kernel.ConstantInfo.inductInfo {
        base := {
          name := PSC1Kernel.Kernel.kernelEqName
          levelParams :=
            List.cons universeName List.nil
          type :=
            PSC1Kernel.Kernel.expectedEqType
              universeName
        }
        numParams := 2
        numIndices := 1
        all :=
          List.cons
            PSC1Kernel.Kernel.kernelEqName
            List.nil
        ctors :=
          List.cons reflName List.nil
        numNested := 0
        isRec := false
        isReflexive := true
        isUnsafe := false
      })
  env0.addUnchecked
    (PSC1Kernel.ConstantInfo.ctorInfo {
      base := {
        name := reflName
        levelParams :=
          List.cons universeName List.nil
        type :=
          PSC1Kernel.Kernel.expectedEqReflType
            universeName
      }
      induct := PSC1Kernel.Kernel.kernelEqName
      cidx := 0
      numParams := 2
      numFields := 0
      isUnsafe := false
    })

def psKernelQuotPrimitiveTypesMatch
    (portable : PsKernelEnvironment)
    (reference : PSC1Kernel.Environment)
    (names : List PsKernelName) :
    Bool :=
  match names with
  | List.nil =>
      true
  | List.cons name rest =>
      match
          psKernelEnvironmentFind
            portable
            name,
          reference.find?
            (psKernelNameToReference name) with
      | Option.some portableInfo,
        Option.some referenceInfo =>
          if
              psKernelExprReferenceEq
                (psKernelConstantInfoType
                  portableInfo)
                referenceInfo.type then
            psKernelQuotPrimitiveTypesMatch
              portable
              reference
              rest
          else
            false
      | _, _ =>
          false

def psKernelCoreQuotTests : Bool :=
  match
      psKernelAddQuot
        psKernelPortableQuotBaseEnvironment,
      PSC1Kernel.Kernel.addQuot
        psKernelReferenceQuotBaseEnvironment with
  | Except.ok portableEnv,
    Except.ok referenceEnv =>
      let names :=
        List.cons
          psKernelQuotName
          (List.cons
            psKernelQuotMkName
            (List.cons
              psKernelQuotLiftName
              (List.cons
                psKernelQuotIndName
                List.nil)))
      let admissionParity :=
        Bool.and
          portableEnv.quotInitialized
          (Bool.and
            referenceEnv.quotInitialized
            (psKernelQuotPrimitiveTypesMatch
              portableEnv
              referenceEnv
              names))
      let x :=
        PsKernelName.str
          PsKernelName.anonymous
          "quot_x"
      let dummy :=
        PsKernelExpr.sort
          PsKernelLevel.zero
      let representative :=
        PsKernelExpr.lit
          (PsKernelLiteral.nat 37)
      let fn :=
        PsKernelExpr.lam
          x
          dummy
          (PsKernelExpr.bvar 0)
          PsKernelBinderInfo.default
      let quotMk :=
        psKernelApplyArgs
          (PsKernelExpr.const
            psKernelQuotMkName
            List.nil)
          (List.cons
            dummy
            (List.cons
              dummy
              (List.cons
                representative
                List.nil)))
      let liftArgs5 :=
        List.cons quotMk List.nil
      let liftArgs4 :=
        List.cons dummy liftArgs5
      let liftArgs3 :=
        List.cons fn liftArgs4
      let liftArgs2 :=
        List.cons dummy liftArgs3
      let liftArgs1 :=
        List.cons dummy liftArgs2
      let liftArgs :=
        List.cons dummy liftArgs1
      let liftExpr :=
        psKernelApplyArgs
          (PsKernelExpr.const
            psKernelQuotLiftName
            List.nil)
          liftArgs
      let indArgs4 :=
        List.cons quotMk List.nil
      let indArgs3 :=
        List.cons fn indArgs4
      let indArgs2 :=
        List.cons dummy indArgs3
      let indArgs1 :=
        List.cons dummy indArgs2
      let indArgs :=
        List.cons dummy indArgs1
      let indExpr :=
        psKernelApplyArgs
          (PsKernelExpr.const
            psKernelQuotIndName
            List.nil)
          indArgs
      let portableSession :=
        psKernelMkCheckerSession
          portableEnv
          List.nil
          PsKernelDefinitionSafety.safe
          0
          psKernelLeanNatMaxSizeDefault
      let referenceContext :=
        PSC1Kernel.CheckerContext.empty
          referenceEnv
      let liftParity :=
        match
            psKernelSessionWhnf
              4096
              portableSession
              liftExpr,
            PSC1Kernel.whnf
              referenceContext
              (psKernelExprToReference
                liftExpr) with
        | Except.ok portableResult,
          Except.ok referenceResult =>
            Bool.and
              (psKernelExprEq
                (Prod.fst portableResult)
                representative)
              (psKernelExprReferenceEq
                (Prod.fst portableResult)
                referenceResult)
        | _, _ =>
            false
      let indParity :=
        match
            psKernelSessionWhnf
              4096
              portableSession
              indExpr,
            PSC1Kernel.whnf
              referenceContext
              (psKernelExprToReference
                indExpr) with
        | Except.ok portableResult,
          Except.ok referenceResult =>
            Bool.and
              (psKernelExprEq
                (Prod.fst portableResult)
                representative)
              (psKernelExprReferenceEq
                (Prod.fst portableResult)
                referenceResult)
        | _, _ =>
            false
      Bool.and
        admissionParity
        (Bool.and liftParity indParity)
  | _, _ =>
      false

def psKernelAdmissionConformanceTests : Bool :=
  let fuel := 4096
  let maxNatSize := psKernelLeanNatMaxSizeDefault
  let natBase : PsKernelConstantBase := {
    name := psKernelNatName
    levelParams := List.nil
    type :=
      PsKernelExpr.sort
        (PsKernelLevel.succ PsKernelLevel.zero)
  }
  let referenceNatBase : PSC1Kernel.ConstantBase := {
    name := PSC1Kernel.kernelNatName
    levelParams := List.nil
    type :=
      PSC1Kernel.Expr.sort
        (PSC1Kernel.Level.succ PSC1Kernel.Level.zero)
  }
  match
      psKernelAddAxiom
        fuel
        psKernelEnvironmentEmpty
        {
          base := natBase
          isUnsafe := false
        }
        0
        maxNatSize,
      PSC1Kernel.Kernel.addAxiom
        PSC1Kernel.Environment.empty
        {
          base := referenceNatBase
          isUnsafe := false
        }
        0
        PSC1Kernel.leanNatMaxSizeDefault
        Option.none with
  | Except.ok portableNatEnv, Except.ok referenceNatEnv =>
      let duplicatePortable :=
        psKernelAddAxiom
          fuel
          portableNatEnv
          {
            base := natBase
            isUnsafe := false
          }
          0
          maxNatSize
      let duplicateReference :=
        PSC1Kernel.Kernel.addAxiom
          referenceNatEnv
          {
            base := referenceNatBase
            isUnsafe := false
          }
          0
          PSC1Kernel.leanNatMaxSizeDefault
          Option.none
      let duplicateParity :=
        match duplicatePortable, duplicateReference with
        | Except.error _, Except.error _ => true
        | _, _ => false
      let defName :=
        PsKernelName.str
          PsKernelName.anonymous
          "AdmissionDef"
      let referenceDefName :=
        psKernelNameToReference defName
      let defInfo : PsKernelDefinitionInfo := {
        base := {
          name := defName
          levelParams := List.nil
          type :=
            PsKernelExpr.const
              psKernelNatName
              List.nil
        }
        value :=
          PsKernelExpr.lit
            (PsKernelLiteral.nat 3)
        hints := PsKernelReducibilityHints.regular 0
        safety := PsKernelDefinitionSafety.safe
      }
      let referenceDefInfo : PSC1Kernel.DefinitionInfo := {
        base := {
          name := referenceDefName
          levelParams := List.nil
          type :=
            PSC1Kernel.Expr.const
              PSC1Kernel.kernelNatName
              List.nil
        }
        value :=
          PSC1Kernel.Expr.lit
            (PSC1Kernel.Literal.nat 3)
        hints := PSC1Kernel.ReducibilityHints.regular 0
        safety := PSC1Kernel.DefinitionSafety.safe
      }
      match
          psKernelAddDefinition
            fuel
            portableNatEnv
            defInfo
            0
            maxNatSize,
          PSC1Kernel.Kernel.addDefinition
            referenceNatEnv
            referenceDefInfo
            0
            PSC1Kernel.leanNatMaxSizeDefault
            Option.none with
      | Except.ok portableDefEnv, Except.ok referenceDefEnv =>
          let propName :=
            PsKernelName.str
              PsKernelName.anonymous
              "AdmissionProp"
          let proofName :=
            PsKernelName.str
              PsKernelName.anonymous
              "AdmissionProof"
          let theoremName :=
            PsKernelName.str
              PsKernelName.anonymous
              "AdmissionTheorem"
          let referencePropName :=
            psKernelNameToReference propName
          let referenceProofName :=
            psKernelNameToReference proofName
          let referenceTheoremName :=
            psKernelNameToReference theoremName
          let propBase : PsKernelConstantBase := {
            name := propName
            levelParams := List.nil
            type := PsKernelExpr.sort PsKernelLevel.zero
          }
          let referencePropBase : PSC1Kernel.ConstantBase := {
            name := referencePropName
            levelParams := List.nil
            type := PSC1Kernel.Expr.sort PSC1Kernel.Level.zero
          }
          match
              psKernelAddAxiom
                fuel
                portableDefEnv
                {
                  base := propBase
                  isUnsafe := false
                }
                0
                maxNatSize,
              PSC1Kernel.Kernel.addAxiom
                referenceDefEnv
                {
                  base := referencePropBase
                  isUnsafe := false
                }
                0
                PSC1Kernel.leanNatMaxSizeDefault
                Option.none with
          | Except.ok portablePropEnv, Except.ok referencePropEnv =>
              let proofBase : PsKernelConstantBase := {
                name := proofName
                levelParams := List.nil
                type :=
                  PsKernelExpr.const
                    propName
                    List.nil
              }
              let referenceProofBase : PSC1Kernel.ConstantBase := {
                name := referenceProofName
                levelParams := List.nil
                type :=
                  PSC1Kernel.Expr.const
                    referencePropName
                    List.nil
              }
              match
                  psKernelAddAxiom
                    fuel
                    portablePropEnv
                    {
                      base := proofBase
                      isUnsafe := false
                    }
                    0
                    maxNatSize,
                  PSC1Kernel.Kernel.addAxiom
                    referencePropEnv
                    {
                      base := referenceProofBase
                      isUnsafe := false
                    }
                    0
                    PSC1Kernel.leanNatMaxSizeDefault
                    Option.none with
              | Except.ok portableProofEnv, Except.ok referenceProofEnv =>
                  let theoremInfo : PsKernelTheoremInfo := {
                    base := {
                      name := theoremName
                      levelParams := List.nil
                      type :=
                        PsKernelExpr.const
                          propName
                          List.nil
                    }
                    value :=
                      PsKernelExpr.const
                        proofName
                        List.nil
                  }
                  let referenceTheoremInfo : PSC1Kernel.TheoremInfo := {
                    base := {
                      name := referenceTheoremName
                      levelParams := List.nil
                      type :=
                        PSC1Kernel.Expr.const
                          referencePropName
                          List.nil
                    }
                    value :=
                      PSC1Kernel.Expr.const
                        referenceProofName
                        List.nil
                  }
                  match
                      psKernelAddTheorem
                        fuel
                        portableProofEnv
                        theoremInfo
                        0
                        maxNatSize,
                      PSC1Kernel.Kernel.addTheorem
                        referenceProofEnv
                        referenceTheoremInfo
                        0
                        PSC1Kernel.leanNatMaxSizeDefault
                        Option.none with
                  | Except.ok portableTheoremEnv, Except.ok referenceTheoremEnv =>
                      let opaqueName :=
                        PsKernelName.str
                          PsKernelName.anonymous
                          "AdmissionOpaque"
                      let referenceOpaqueName :=
                        psKernelNameToReference opaqueName
                      let opaqueInfo : PsKernelOpaqueInfo := {
                        base := {
                          name := opaqueName
                          levelParams := List.nil
                          type :=
                            PsKernelExpr.const
                              psKernelNatName
                              List.nil
                        }
                        value :=
                          PsKernelExpr.lit
                            (PsKernelLiteral.nat 5)
                        isUnsafe := false
                      }
                      let referenceOpaqueInfo : PSC1Kernel.OpaqueInfo := {
                        base := {
                          name := referenceOpaqueName
                          levelParams := List.nil
                          type :=
                            PSC1Kernel.Expr.const
                              PSC1Kernel.kernelNatName
                              List.nil
                        }
                        value :=
                          PSC1Kernel.Expr.lit
                            (PSC1Kernel.Literal.nat 5)
                        isUnsafe := false
                      }
                      match
                          psKernelAddOpaque
                            fuel
                            portableTheoremEnv
                            opaqueInfo
                            0
                            maxNatSize,
                          PSC1Kernel.Kernel.addOpaque
                            referenceTheoremEnv
                            referenceOpaqueInfo
                            0
                            PSC1Kernel.leanNatMaxSizeDefault
                            Option.none with
                      | Except.ok portableOpaqueEnv, Except.ok referenceOpaqueEnv =>
                          let firstMutualName :=
                            PsKernelName.str
                              PsKernelName.anonymous
                              "AdmissionMutualA"
                          let secondMutualName :=
                            PsKernelName.str
                              PsKernelName.anonymous
                              "AdmissionMutualB"
                          let referenceFirstMutualName :=
                            psKernelNameToReference firstMutualName
                          let referenceSecondMutualName :=
                            psKernelNameToReference secondMutualName
                          let firstMutual : PsKernelDefinitionInfo := {
                            base := {
                              name := firstMutualName
                              levelParams := List.nil
                              type :=
                                PsKernelExpr.const
                                  psKernelNatName
                                  List.nil
                            }
                            value :=
                              PsKernelExpr.lit
                                (PsKernelLiteral.nat 1)
                            hints := PsKernelReducibilityHints.regular 0
                            safety := PsKernelDefinitionSafety.unsafeDef
                          }
                          let secondMutual : PsKernelDefinitionInfo := {
                            base := {
                              name := secondMutualName
                              levelParams := List.nil
                              type :=
                                PsKernelExpr.const
                                  psKernelNatName
                                  List.nil
                            }
                            value :=
                              PsKernelExpr.lit
                                (PsKernelLiteral.nat 2)
                            hints := PsKernelReducibilityHints.regular 0
                            safety := PsKernelDefinitionSafety.unsafeDef
                          }
                          let referenceFirstMutual : PSC1Kernel.DefinitionInfo := {
                            base := {
                              name := referenceFirstMutualName
                              levelParams := List.nil
                              type :=
                                PSC1Kernel.Expr.const
                                  PSC1Kernel.kernelNatName
                                  List.nil
                            }
                            value :=
                              PSC1Kernel.Expr.lit
                                (PSC1Kernel.Literal.nat 1)
                            hints := PSC1Kernel.ReducibilityHints.regular 0
                            safety := PSC1Kernel.DefinitionSafety.unsafeDef
                          }
                          let referenceSecondMutual : PSC1Kernel.DefinitionInfo := {
                            base := {
                              name := referenceSecondMutualName
                              levelParams := List.nil
                              type :=
                                PSC1Kernel.Expr.const
                                  PSC1Kernel.kernelNatName
                                  List.nil
                            }
                            value :=
                              PSC1Kernel.Expr.lit
                                (PSC1Kernel.Literal.nat 2)
                            hints := PSC1Kernel.ReducibilityHints.regular 0
                            safety := PSC1Kernel.DefinitionSafety.unsafeDef
                          }
                          match
                              psKernelAddMutualDefinitions
                                fuel
                                portableOpaqueEnv
                                (List.cons
                                  firstMutual
                                  (List.cons secondMutual List.nil))
                                0
                                maxNatSize,
                              PSC1Kernel.Kernel.addMutualDefinitions
                                referenceOpaqueEnv
                                (List.cons
                                  referenceFirstMutual
                                  (List.cons referenceSecondMutual List.nil))
                                0
                                PSC1Kernel.leanNatMaxSizeDefault
                                Option.none with
                          | Except.ok portableFinal, Except.ok referenceFinal =>
                              duplicateParity &&
                                psKernelEnvironmentContains
                                  portableFinal
                                  defName &&
                                referenceFinal.contains
                                  referenceDefName &&
                                psKernelEnvironmentContains
                                  portableFinal
                                  theoremName &&
                                referenceFinal.contains
                                  referenceTheoremName &&
                                psKernelEnvironmentContains
                                  portableFinal
                                  opaqueName &&
                                referenceFinal.contains
                                  referenceOpaqueName &&
                                psKernelEnvironmentContains
                                  portableFinal
                                  firstMutualName &&
                                psKernelEnvironmentContains
                                  portableFinal
                                  secondMutualName &&
                                referenceFinal.contains
                                  referenceFirstMutualName &&
                                referenceFinal.contains
                                  referenceSecondMutualName
                          | _, _ =>
                              false
                      | _, _ =>
                          false
                  | _, _ =>
                      false
              | _, _ =>
                  false
          | _, _ =>
              false
      | _, _ =>
          false
  | _, _ =>
      false

def psKernelRuntimeCacheKey
    (index : Nat) :
    PsKernelExpr :=
  PsKernelExpr.const
    (PsKernelName.num
      (PsKernelName.str
        PsKernelName.anonymous
        "runtimeCache")
      index)
    List.nil

def psKernelRuntimeCacheValue
    (index : Nat) :
    PsKernelExpr :=
  PsKernelExpr.lit
    (PsKernelLiteral.nat index)

def psKernelRuntimeBuildExprMap
    (count : Nat) :
    PsKernelExprMap :=
  match count with
  | Nat.zero =>
      psKernelExprMapEmpty
  | Nat.succ rest =>
      psKernelExprMapInsert
        (psKernelRuntimeBuildExprMap rest)
        (psKernelRuntimeCacheKey rest)
        (psKernelRuntimeCacheValue rest)

def psKernelRuntimeBuildPairSet
    (count : Nat) :
    PsKernelExprPairSet :=
  match count with
  | Nat.zero =>
      psKernelExprPairSetEmpty
  | Nat.succ rest =>
      psKernelExprPairSetInsert
        (psKernelRuntimeBuildPairSet rest)
        (psKernelRuntimeCacheKey rest)
        (psKernelRuntimeCacheValue rest)

def psKernelRuntimeCachePromotionTests : Bool :=
  let smallCount :=
    psKernelCacheSmallLimit
  let promotedCount :=
    Nat.succ psKernelCacheSmallLimit
  let mapSmall :=
    psKernelRuntimeBuildExprMap smallCount
  let mapPromoted :=
    psKernelRuntimeBuildExprMap promotedCount
  let pairSmall :=
    psKernelRuntimeBuildPairSet smallCount
  let pairPromoted :=
    psKernelRuntimeBuildPairSet promotedCount
  let mapSmallDirect :=
    match mapSmall.index with
    | Option.none => true
    | Option.some _ => false
  let mapPromotedIndexed :=
    match mapPromoted.index with
    | Option.none => false
    | Option.some _ => true
  let pairSmallDirect :=
    match pairSmall.index with
    | Option.none => true
    | Option.some _ => false
  let pairPromotedIndexed :=
    match pairPromoted.index with
    | Option.none => false
    | Option.some _ => true
  Bool.and
    mapSmallDirect
    (Bool.and
      mapPromotedIndexed
      (Bool.and
        pairSmallDirect
        (Bool.and
          pairPromotedIndexed
          (Bool.and
            (match
                psKernelExprMapGet
                  mapPromoted
                  (psKernelRuntimeCacheKey 0) with
            | Option.some value =>
                psKernelExprEq
                  value
                  (psKernelRuntimeCacheValue 0)
            | Option.none =>
                false)
            (psKernelExprPairSetContains
              pairPromoted
              (psKernelRuntimeCacheValue 0)
              (psKernelRuntimeCacheKey 0))))))

def psKernelRuntimeCacheInvariantTests : Bool :=
  let nameA :=
    PsKernelName.str
      PsKernelName.anonymous
      "cacheA"
  let nameB :=
    PsKernelName.str
      PsKernelName.anonymous
      "cacheB"
  let type :=
    PsKernelExpr.sort PsKernelLevel.zero
  let body :=
    PsKernelExpr.bvar 0
  let left :=
    PsKernelExpr.lam
      nameA
      type
      body
      PsKernelBinderInfo.default
  let equalByCacheSemantics :=
    PsKernelExpr.lam
      nameB
      type
      body
      PsKernelBinderInfo.implicit
  let value :=
    PsKernelExpr.lit
      (PsKernelLiteral.nat 99)
  let cache :=
    psKernelExprMapInsert
      psKernelExprMapEmpty
      left
      value
  let pairSet :=
    psKernelExprPairSetInsert
      psKernelExprPairSetEmpty
      left
      value
  Bool.and
    (psKernelExprEq
      left
      equalByCacheSemantics)
    (Bool.and
      (Nat.beq
        (psKernelExprHash left)
        (psKernelExprHash equalByCacheSemantics))
      (Bool.and
        (match
            psKernelExprMapGet
              cache
              equalByCacheSemantics with
        | Option.some cached =>
            psKernelExprEq cached value
        | Option.none =>
            false)
        (Bool.and
          (Nat.beq
            (psKernelExprPairHash left value)
            (psKernelExprPairHash value left))
          (psKernelExprPairSetContains
            pairSet
            value
            equalByCacheSemantics))))

def psKernelRuntimeEnvironmentInfo
    (index : Nat) :
    PsKernelConstantInfo :=
  PsKernelConstantInfo.axiomInfo {
    base := {
      name :=
        PsKernelName.num
          PsKernelName.anonymous
          index
      levelParams := List.nil
      type := PsKernelExpr.sort PsKernelLevel.zero
    }
    isUnsafe := false
  }

def psKernelRuntimeBuildEnvironment
    (count : Nat) :
    PsKernelEnvironment :=
  match count with
  | Nat.zero =>
      psKernelEnvironmentEmpty
  | Nat.succ rest =>
      psKernelEnvironmentAddUnchecked
        (psKernelRuntimeBuildEnvironment rest)
        (psKernelRuntimeEnvironmentInfo rest)

def psKernelRuntimeEnvironmentPromotionTests : Bool :=
  let environment8 :=
    psKernelRuntimeBuildEnvironment 8
  let environment9 :=
    psKernelRuntimeBuildEnvironment 9
  let environment8Small :=
    match environment8.index with
    | PsKernelEnvironmentIndex.small _ =>
        true
    | _ =>
        false
  let environment9Indexed :=
    match environment9.index with
    | PsKernelEnvironmentIndex.branch _ _ =>
        true
    | PsKernelEnvironmentIndex.bucket _ =>
        true
    | _ =>
        false
  let target :=
    PsKernelName.num
      PsKernelName.anonymous
      0
  Bool.and
    environment8Small
    (Bool.and
      environment9Indexed
      (match
          psKernelEnvironmentFind
            environment9
            target,
          psKernelFindConstantInList
            target
            environment9.constants with
      | Option.some indexed,
        Option.some authoritative =>
          psKernelExprEq
            (psKernelConstantInfoType indexed)
            (psKernelConstantInfoType authoritative)
      | _, _ =>
          false))

def psKernelRuntimeEnvironmentIndexInvariantTests : Bool :=
  let collisionParent :=
    PsKernelName.str
      PsKernelName.anonymous
      "collision"
  let firstName :=
    PsKernelName.num
      collisionParent
      1
  let collisionName :=
    PsKernelName.num
      collisionParent
      65522
  let firstType :=
    PsKernelExpr.sort PsKernelLevel.zero
  let collisionType :=
    PsKernelExpr.sort
      (PsKernelLevel.succ PsKernelLevel.zero)
  let replacementType :=
    PsKernelExpr.sort
      (PsKernelLevel.succ
        (PsKernelLevel.succ PsKernelLevel.zero))
  let firstInfo :=
    PsKernelConstantInfo.axiomInfo {
      base := {
        name := firstName
        levelParams := List.nil
        type := firstType
      }
      isUnsafe := false
    }
  let collisionInfo :=
    PsKernelConstantInfo.axiomInfo {
      base := {
        name := collisionName
        levelParams := List.nil
        type := collisionType
      }
      isUnsafe := false
    }
  let replacement :=
    PsKernelConstantInfo.axiomInfo {
      base := {
        name := firstName
        levelParams := List.nil
        type := replacementType
      }
      isUnsafe := false
    }
  let promotedBase :=
    psKernelRuntimeBuildEnvironment 9
  let environment0 :=
    psKernelEnvironmentAddUnchecked
      promotedBase
      firstInfo
  let environment1 :=
    psKernelEnvironmentAddUnchecked
      environment0
      collisionInfo
  let environment2 :=
    psKernelEnvironmentReplaceUnchecked
      environment1
      replacement
  Bool.and
    (Nat.beq
      (psKernelEnvironmentNameHash firstName)
      (psKernelEnvironmentNameHash collisionName))
    (Bool.and
      (match
          psKernelEnvironmentFind
            environment1
            firstName,
          psKernelFindConstantInList
            firstName
            environment1.constants with
      | Option.some indexed,
        Option.some authoritative =>
          psKernelExprEq
            (psKernelConstantInfoType indexed)
            (psKernelConstantInfoType authoritative)
      | _, _ =>
          false)
      (Bool.and
        (match
            psKernelEnvironmentFind
              environment1
              collisionName,
            psKernelFindConstantInList
              collisionName
              environment1.constants with
        | Option.some indexed,
          Option.some authoritative =>
            psKernelExprEq
              (psKernelConstantInfoType indexed)
              (psKernelConstantInfoType authoritative)
        | _, _ =>
            false)
        (match
            psKernelEnvironmentFind
              environment2
              firstName with
        | Option.some indexed =>
            psKernelExprEq
              (psKernelConstantInfoType indexed)
              replacementType
        | Option.none =>
            false)))

def psKernelRuntimeInvariantTests : Bool :=
  Bool.and
    psKernelRuntimeCacheInvariantTests
    (Bool.and
      psKernelRuntimeCachePromotionTests
      (Bool.and
        psKernelRuntimeEnvironmentPromotionTests
        psKernelRuntimeEnvironmentIndexInvariantTests))

