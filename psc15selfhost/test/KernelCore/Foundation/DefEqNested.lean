import KernelCore.Foundation.Checking

def psKernelDefEqConstName : PsKernelName :=
  PsKernelName.str
    PsKernelName.anonymous
    "defeqValue"

def psKernelDefEqPropName : PsKernelName :=
  PsKernelName.str
    PsKernelName.anonymous
    "DefEqProp"

def psKernelDefEqEnvironment : PsKernelEnvironment :=
  let natBase : PsKernelConstantBase :=
    {
      name := psKernelNatName
      levelParams := List.nil
      type :=
        PsKernelExpr.sort
          (PsKernelLevel.succ PsKernelLevel.zero)
    };
  let propBase : PsKernelConstantBase :=
    {
      name := psKernelDefEqPropName
      levelParams := List.nil
      type :=
        PsKernelExpr.sort PsKernelLevel.zero
    };
  let defBase : PsKernelConstantBase :=
    {
      name := psKernelDefEqConstName
      levelParams := List.nil
      type :=
        PsKernelExpr.const
          psKernelNatName
          List.nil
    };
  let env1 :=
    psKernelEnvironmentAddUnchecked
      psKernelEnvironmentEmpty
      (PsKernelConstantInfo.axiomInfo {
        base := natBase
        isUnsafe := false
      });
  let env2 :=
    psKernelEnvironmentAddUnchecked
      env1
      (PsKernelConstantInfo.axiomInfo {
        base := propBase
        isUnsafe := false
      });
  psKernelEnvironmentAddUnchecked
    env2
    (PsKernelConstantInfo.defnInfo {
      base := defBase
      value :=
        PsKernelExpr.lit
          (PsKernelLiteral.nat 7)
      hints := PsKernelReducibilityHints.regular 0
      safety := PsKernelDefinitionSafety.safe
    })

def psKernelDefEqReferenceEnvironment :
    PSC1Kernel.Environment :=
  let natBase : PSC1Kernel.ConstantBase :=
    {
      name := PSC1Kernel.kernelNatName
      levelParams := List.nil
      type :=
        PSC1Kernel.Expr.sort
          (PSC1Kernel.Level.succ
            PSC1Kernel.Level.zero)
    };
  let propName :=
    psKernelNameToReference
      psKernelDefEqPropName;
  let propBase : PSC1Kernel.ConstantBase :=
    {
      name := propName
      levelParams := List.nil
      type :=
        PSC1Kernel.Expr.sort
          PSC1Kernel.Level.zero
    };
  let defBase : PSC1Kernel.ConstantBase :=
    {
      name :=
        psKernelNameToReference
          psKernelDefEqConstName
      levelParams := List.nil
      type :=
        PSC1Kernel.Expr.const
          PSC1Kernel.kernelNatName
          List.nil
    };
  let env1 :=
    PSC1Kernel.Environment.empty.addUnchecked
      (PSC1Kernel.ConstantInfo.axiomInfo {
        base := natBase
        isUnsafe := false
      });
  let env2 :=
    env1.addUnchecked
      (PSC1Kernel.ConstantInfo.axiomInfo {
        base := propBase
        isUnsafe := false
      });
  env2.addUnchecked
    (PSC1Kernel.ConstantInfo.defnInfo {
      base := defBase
      value :=
        PSC1Kernel.Expr.lit
          (PSC1Kernel.Literal.nat 7)
      hints := PSC1Kernel.ReducibilityHints.regular 0
      safety := PSC1Kernel.DefinitionSafety.safe
    })

def psKernelDefEqDifferential
    (portableContext : PsKernelCheckerContext)
    (referenceContext : PSC1Kernel.CheckerContext)
    (left right : PsKernelExpr) : Bool :=
  match
      psKernelIsDefEq
        2048
        portableContext
        psKernelCheckerStateEmpty
        left
        right,
      PSC1Kernel.isDefEq
        referenceContext
        (psKernelExprToReference left)
        (psKernelExprToReference right) with
  | Except.ok portableResult, Except.ok referenceResult =>
      Bool.and
        ((Prod.fst portableResult) == referenceResult)
        (if Prod.fst portableResult then
          let cached := psKernelExprPairSetContains
            (Prod.snd portableResult).success left right
          if psKernelSemanticPairCacheEligible left right then
            cached
          else
            Bool.not cached
         else
          true)
  | Except.error portableError, Except.error referenceError =>
      portableError == referenceError
  | _, _ =>
      false

def psKernelCoreDefEqTests : Bool :=
  let portableBase :=
    psKernelCheckerContextEmpty
      psKernelDefEqEnvironment;
  let referenceBase :=
    PSC1Kernel.CheckerContext.empty
      psKernelDefEqReferenceEnvironment;
  let natType :=
    PsKernelExpr.const
      psKernelNatName
      List.nil;
  let betaLeft :=
    PsKernelExpr.app
      (PsKernelExpr.lam
        PsKernelName.anonymous
        natType
        (PsKernelExpr.bvar 0)
        PsKernelBinderInfo.default)
      (PsKernelExpr.lit
        (PsKernelLiteral.nat 9));
  let betaRight :=
    PsKernelExpr.lit
      (PsKernelLiteral.nat 9);
  let deltaLeft :=
    PsKernelExpr.const
      psKernelDefEqConstName
      List.nil;
  let deltaRight :=
    PsKernelExpr.lit
      (PsKernelLiteral.nat 7);
  let proofLeftName :=
    PsKernelName.str
      PsKernelName.anonymous
      "proofLeft";
  let proofRightName :=
    PsKernelName.str
      PsKernelName.anonymous
      "proofRight";
  let propType :=
    PsKernelExpr.const
      psKernelDefEqPropName
      List.nil;
  let portableProofLctx1 :=
    psKernelLocalContextAddLocal
      portableBase.localContext
      proofLeftName
      proofLeftName
      propType
      PsKernelBinderInfo.default;
  let portableProofLctx :=
    psKernelLocalContextAddLocal
      portableProofLctx1
      proofRightName
      proofRightName
      propType
      PsKernelBinderInfo.default;
  let portableProofContext :=
    psKernelCheckerContextWithLocalContext
      portableBase
      portableProofLctx;
  let referenceProofLeftName :=
    psKernelNameToReference proofLeftName;
  let referenceProofRightName :=
    psKernelNameToReference proofRightName;
  let referencePropType :=
    psKernelExprToReference propType;
  let referenceProofLctx1 :=
    referenceBase.lctx.addLocal
      referenceProofLeftName
      referenceProofLeftName
      referencePropType
      PSC1Kernel.BinderInfo.default;
  let referenceProofLctx :=
    referenceProofLctx1.addLocal
      referenceProofRightName
      referenceProofRightName
      referencePropType
      PSC1Kernel.BinderInfo.default;
  let referenceProofContext :=
    {
      referenceBase with
      lctx := referenceProofLctx
    };
  let functionName :=
    PsKernelName.str
      PsKernelName.anonymous
      "function";
  let functionType :=
    PsKernelExpr.forallE
      PsKernelName.anonymous
      natType
      natType
      PsKernelBinderInfo.default;
  let portableEtaAdded :=
    psKernelCheckerContextWithLocal
      portableBase
      functionName
      functionType
      PsKernelBinderInfo.default;
  let portableFunctionName :=
    Prod.fst portableEtaAdded;
  let portableEtaContext :=
    Prod.snd portableEtaAdded;
  let referenceEtaAdded :=
    referenceBase.withLocal
      (psKernelNameToReference functionName)
      (psKernelExprToReference functionType)
      PSC1Kernel.BinderInfo.default;
  let referenceFunctionName :=
    Prod.fst referenceEtaAdded;
  let referenceEtaContext :=
    Prod.snd referenceEtaAdded;
  let etaLeft :=
    PsKernelExpr.lam
      PsKernelName.anonymous
      natType
      (PsKernelExpr.app
        (PsKernelExpr.fvar portableFunctionName)
        (PsKernelExpr.bvar 0))
      PsKernelBinderInfo.default;
  let etaRight :=
    PsKernelExpr.fvar portableFunctionName;
  let referenceEtaLeft :=
    PSC1Kernel.Expr.lam
      PSC1Kernel.Name.anonymous
      (psKernelExprToReference natType)
      (PSC1Kernel.Expr.app
        (PSC1Kernel.Expr.fvar referenceFunctionName)
        (PSC1Kernel.Expr.bvar 0))
      PSC1Kernel.BinderInfo.default;
  let referenceEtaRight :=
    PSC1Kernel.Expr.fvar referenceFunctionName;
  let etaDifferential :=
    match
        psKernelIsDefEq
          2048
          portableEtaContext
          psKernelCheckerStateEmpty
          etaLeft
          etaRight,
        PSC1Kernel.isDefEq
          referenceEtaContext
          referenceEtaLeft
          referenceEtaRight with
    | Except.ok portableResult, Except.ok referenceResult =>
        (Prod.fst portableResult) == referenceResult
    | _, _ =>
        false;
  let binaryName :=
    PsKernelName.str
      PsKernelName.anonymous
      "binaryFunction";
  let binaryType :=
    PsKernelExpr.forallE
      PsKernelName.anonymous
      natType
      (PsKernelExpr.forallE
        PsKernelName.anonymous
        natType
        natType
        PsKernelBinderInfo.default)
      PsKernelBinderInfo.default;
  let portableBinaryAdded :=
    psKernelCheckerContextWithLocal
      portableEtaContext
      binaryName
      binaryType
      PsKernelBinderInfo.default;
  let portableBinaryName :=
    Prod.fst portableBinaryAdded;
  let portableBinaryContext :=
    Prod.snd portableBinaryAdded;
  let referenceBinaryAdded :=
    referenceEtaContext.withLocal
      (psKernelNameToReference binaryName)
      (psKernelExprToReference binaryType)
      PSC1Kernel.BinderInfo.default;
  let referenceBinaryName :=
    Prod.fst referenceBinaryAdded;
  let referenceBinaryContext :=
    Prod.snd referenceBinaryAdded;
  let partialApplication :=
    PsKernelExpr.app
      (PsKernelExpr.fvar portableBinaryName)
      (PsKernelExpr.lit (PsKernelLiteral.nat 0));
  let etaExpandedApplication :=
    PsKernelExpr.lam
      PsKernelName.anonymous
      natType
      (PsKernelExpr.app
        partialApplication
        (PsKernelExpr.bvar 0))
      PsKernelBinderInfo.default;
  let referencePartialApplication :=
    PSC1Kernel.Expr.app
      (PSC1Kernel.Expr.fvar referenceBinaryName)
      (PSC1Kernel.Expr.lit (PSC1Kernel.Literal.nat 0));
  let referenceEtaExpandedApplication :=
    PSC1Kernel.Expr.lam
      PSC1Kernel.Name.anonymous
      (psKernelExprToReference natType)
      (PSC1Kernel.Expr.app
        referencePartialApplication
        (PSC1Kernel.Expr.bvar 0))
      PSC1Kernel.BinderInfo.default;
  let etaApplicationDifferential :=
    match
        psKernelIsDefEq
          2048
          portableBinaryContext
          psKernelCheckerStateEmpty
          partialApplication
          etaExpandedApplication,
        psKernelIsDefEq
          2048
          portableBinaryContext
          psKernelCheckerStateEmpty
          etaExpandedApplication
          partialApplication,
        PSC1Kernel.isDefEq
          referenceBinaryContext
          referencePartialApplication
          referenceEtaExpandedApplication,
        PSC1Kernel.isDefEq
          referenceBinaryContext
          referenceEtaExpandedApplication
          referencePartialApplication with
    | Except.ok portableForward,
        Except.ok portableReverse,
        Except.ok referenceForward,
        Except.ok referenceReverse =>
        Bool.and
          (Prod.fst portableForward)
          (Bool.and
            (Prod.fst portableReverse)
            (Bool.and
              ((Prod.fst portableForward) == referenceForward)
              ((Prod.fst portableReverse) == referenceReverse)))
    | _, _, _, _ =>
        false;
  Bool.and
    (psKernelDefEqDifferential
      portableBase
      referenceBase
      betaLeft
      betaRight)
    (Bool.and
      (psKernelDefEqDifferential
        portableBase
        referenceBase
        deltaLeft
        deltaRight)
      (Bool.and
        (psKernelDefEqDifferential
          portableProofContext
          referenceProofContext
          (PsKernelExpr.fvar proofLeftName)
          (PsKernelExpr.fvar proofRightName))
        (Bool.and
          etaDifferential
          etaApplicationDifferential)))


def psKernelConstantListUsesNestedPrefix
    (values : List PsKernelConstantInfo) : Bool :=
  match values with
  | List.nil =>
      false
  | List.cons info rest =>
      if
          psKernelNameIsPrefixOf
            psKernelSimpleNestedPrefix
            (psKernelConstantInfoName info) then
        true
      else
        psKernelConstantListUsesNestedPrefix rest

def psKernelCoreNestedTests : Bool :=
  let type1 :=
    PsKernelExpr.sort
      (PsKernelLevel.succ
        PsKernelLevel.zero)
  let boxName :=
    PsKernelName.str
      PsKernelName.anonymous
      "PortableNestedBox"
  let boxMkName :=
    PsKernelName.str
      boxName
      "mk"
  let alphaName :=
    PsKernelName.str
      PsKernelName.anonymous
      "alpha"
  let valueName :=
    PsKernelName.str
      PsKernelName.anonymous
      "value"
  let boxType :=
    PsKernelExpr.forallE
      alphaName
      type1
      type1
      PsKernelBinderInfo.default
  let boxCtorType :=
    PsKernelExpr.forallE
      alphaName
      type1
      (PsKernelExpr.forallE
        valueName
        (PsKernelExpr.bvar 0)
        (PsKernelExpr.app
          (PsKernelExpr.const
            boxName
            List.nil)
          (PsKernelExpr.bvar 1))
        PsKernelBinderInfo.default)
      PsKernelBinderInfo.default
  let treeName :=
    PsKernelName.str
      PsKernelName.anonymous
      "PortableNestedTree"
  let leafName :=
    PsKernelName.str
      treeName
      "leaf"
  let nodeName :=
    PsKernelName.str
      treeName
      "node"
  let recName :=
    psKernelSimpleRecName
      treeName
  let recAuxName :=
    psKernelNameAppendIndexAfter
      recName
      1
  let treeType :=
    PsKernelExpr.const
      treeName
      List.nil
  let boxTreeType :=
    PsKernelExpr.app
      (PsKernelExpr.const
        boxName
        List.nil)
      treeType
  let nodeType :=
    PsKernelExpr.forallE
      (PsKernelName.str
        PsKernelName.anonymous
        "children")
      boxTreeType
      treeType
      PsKernelBinderInfo.default
  let portableBox :=
    psKernelAddSimpleInductive
      4096
      psKernelEnvironmentEmpty
      (PsKernelSimpleInductiveDecl.mk
        List.nil
        boxName
        boxType
        (List.cons
          (PsKernelSimpleConstructorDecl.mk
            boxMkName
            boxCtorType)
          List.nil)
        false
        1)
      0
      psKernelLeanNatMaxSizeDefault
  let portableNested :=
    match portableBox with
    | Except.error _ =>
        Except.error "outer box admission failed"
    | Except.ok environment =>
        psKernelAddSimpleNestedInductive
          4096
          environment
          (PsKernelSimpleMutualInductiveDecl.mk
            List.nil
            0
            (List.cons
              (PsKernelSimpleMutualTypeDecl.mk
                treeName
                type1
                (List.cons
                  (PsKernelSimpleConstructorDecl.mk
                    leafName
                    treeType)
                  (List.cons
                    (PsKernelSimpleConstructorDecl.mk
                      nodeName
                      nodeType)
                    List.nil)))
              List.nil)
            false)
          0
          psKernelLeanNatMaxSizeDefault
  let referenceBoxName :=
    psKernelNameToReference boxName
  let referenceBoxMkName :=
    psKernelNameToReference boxMkName
  let referenceTreeName :=
    psKernelNameToReference treeName
  let referenceLeafName :=
    psKernelNameToReference leafName
  let referenceNodeName :=
    psKernelNameToReference nodeName
  let referenceRecName :=
    psKernelNameToReference recName
  let referenceRecAuxName :=
    psKernelNameToReference recAuxName
  let referenceBox :=
    PSC1Kernel.Kernel.addSimpleInductive
      PSC1Kernel.Environment.empty
      {
        levelParams := []
        name := referenceBoxName
        type := psKernelExprToReference boxType
        ctors := [{
          name := referenceBoxMkName
          type := psKernelExprToReference boxCtorType
        }]
        isUnsafe := false
        numParams := 1
      }
  let referenceNested :=
    match referenceBox with
    | Except.error error =>
        Except.error error
    | Except.ok environment =>
        PSC1Kernel.Kernel.addSimpleNestedInductive
          environment
          {
            levelParams := []
            numParams := 0
            types := [{
              name := referenceTreeName
              type := psKernelExprToReference type1
              ctors := [
                {
                  name := referenceLeafName
                  type := psKernelExprToReference treeType
                },
                {
                  name := referenceNodeName
                  type := psKernelExprToReference nodeType
                }
              ]
            }]
            isUnsafe := false
          }
  match portableNested, referenceNested with
  | Except.ok portable, Except.ok reference =>
      match
          psKernelEnvironmentFind
            portable
            treeName,
          reference.find?
            referenceTreeName with
      | Option.some
          (PsKernelConstantInfo.inductInfo portableTree),
        Option.some
          (PSC1Kernel.ConstantInfo.inductInfo referenceTree) =>
          if
              !(Nat.beq portableTree.numNested
                referenceTree.numNested) then
            false
          else
            match
                psKernelEnvironmentFind
                  portable
                  recName,
                reference.find?
                  referenceRecName with
            | Option.some
                (PsKernelConstantInfo.recInfo portableRec),
              Option.some
                (PSC1Kernel.ConstantInfo.recInfo referenceRec) =>
                if
                    !(Nat.beq
                      portableRec.numMotives
                      referenceRec.numMotives) then
                  false
                else if
                    !(Nat.beq
                      portableRec.numMinors
                      referenceRec.numMinors) then
                  false
                else
                  match
                      psKernelEnvironmentFind
                        portable
                        recAuxName,
                      reference.find?
                        referenceRecAuxName with
                  | Option.some
                      (PsKernelConstantInfo.recInfo portableAux),
                    Option.some
                      (PSC1Kernel.ConstantInfo.recInfo referenceAux) =>
                      if
                          !(Nat.beq
                            portableAux.numMotives
                            referenceAux.numMotives) then
                        false
                      else if
                          psKernelConstantListUsesNestedPrefix
                            portable.constants then
                        false
                      else
                        match portableAux.rules,
                            referenceAux.rules with
                        | List.cons portableRule List.nil,
                          List.cons referenceRule List.nil =>
                            psKernelNameEq
                              portableRule.ctor
                              (psKernelNameFromReference
                                referenceRule.ctor)
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

def psKernelCoreNestedMultiFamilyTests : Bool :=
  let type1 :=
    PsKernelExpr.sort
      (PsKernelLevel.succ
        PsKernelLevel.zero)
  let boxName :=
    PsKernelName.str
      PsKernelName.anonymous
      "PortableNestedWideBox"
  let boxMkName :=
    PsKernelName.str
      boxName
      "mk"
  let wrapName :=
    PsKernelName.str
      PsKernelName.anonymous
      "PortableNestedWideWrap"
  let wrapMkName :=
    PsKernelName.str
      wrapName
      "mk"
  let alphaName :=
    PsKernelName.str
      PsKernelName.anonymous
      "alpha"
  let valueName :=
    PsKernelName.str
      PsKernelName.anonymous
      "value"
  let boxType :=
    PsKernelExpr.forallE
      alphaName
      type1
      type1
      PsKernelBinderInfo.default
  let boxCtorType :=
    PsKernelExpr.forallE
      alphaName
      type1
      (PsKernelExpr.forallE
        valueName
        (PsKernelExpr.bvar 0)
        (PsKernelExpr.app
          (PsKernelExpr.const
            boxName
            List.nil)
          (PsKernelExpr.bvar 1))
        PsKernelBinderInfo.default)
      PsKernelBinderInfo.default
  let wrapType :=
    PsKernelExpr.forallE
      alphaName
      type1
      type1
      PsKernelBinderInfo.default
  let wrapCtorType :=
    PsKernelExpr.forallE
      alphaName
      type1
      (PsKernelExpr.forallE
        valueName
        (PsKernelExpr.bvar 0)
        (PsKernelExpr.app
          (PsKernelExpr.const
            wrapName
            List.nil)
          (PsKernelExpr.bvar 1))
        PsKernelBinderInfo.default)
      PsKernelBinderInfo.default
  let treeName :=
    PsKernelName.str
      PsKernelName.anonymous
      "PortableNestedWideTree"
  let leafName :=
    PsKernelName.str
      treeName
      "leaf"
  let boxNodeName :=
    PsKernelName.str
      treeName
      "boxNode"
  let wrapNodeName :=
    PsKernelName.str
      treeName
      "wrapNode"
  let recName :=
    psKernelSimpleRecName
      treeName
  let recAux1Name :=
    psKernelNameAppendIndexAfter
      recName
      1
  let recAux2Name :=
    psKernelNameAppendIndexAfter
      recName
      2
  let treeType :=
    PsKernelExpr.const
      treeName
      List.nil
  let boxTreeType :=
    PsKernelExpr.app
      (PsKernelExpr.const
        boxName
        List.nil)
      treeType
  let wrapTreeType :=
    PsKernelExpr.app
      (PsKernelExpr.const
        wrapName
        List.nil)
      treeType
  let boxNodeType :=
    PsKernelExpr.forallE
      PsKernelName.anonymous
      boxTreeType
      treeType
      PsKernelBinderInfo.default
  let wrapNodeType :=
    PsKernelExpr.forallE
      PsKernelName.anonymous
      wrapTreeType
      treeType
      PsKernelBinderInfo.default
  let boxEnvironment :=
    psKernelAddSimpleInductive
      8192
      psKernelEnvironmentEmpty
      (PsKernelSimpleInductiveDecl.mk
        List.nil
        boxName
        boxType
        (List.cons
          (PsKernelSimpleConstructorDecl.mk
            boxMkName
            boxCtorType)
          List.nil)
        false
        1)
      0
      psKernelLeanNatMaxSizeDefault
  let outerEnvironment :=
    match boxEnvironment with
    | Except.error error =>
        Except.error error
    | Except.ok environment =>
        psKernelAddSimpleInductive
          8192
          environment
          (PsKernelSimpleInductiveDecl.mk
            List.nil
            wrapName
            wrapType
            (List.cons
              (PsKernelSimpleConstructorDecl.mk
                wrapMkName
                wrapCtorType)
              List.nil)
            false
            1)
          0
          psKernelLeanNatMaxSizeDefault
  let nested :=
    match outerEnvironment with
    | Except.error error =>
        Except.error error
    | Except.ok environment =>
        psKernelAddSimpleNestedInductive
          8192
          environment
          (PsKernelSimpleMutualInductiveDecl.mk
            List.nil
            0
            (List.cons
              (PsKernelSimpleMutualTypeDecl.mk
                treeName
                type1
                (List.cons
                  (PsKernelSimpleConstructorDecl.mk
                    leafName
                    treeType)
                  (List.cons
                    (PsKernelSimpleConstructorDecl.mk
                      boxNodeName
                      boxNodeType)
                    (List.cons
                      (PsKernelSimpleConstructorDecl.mk
                        wrapNodeName
                        wrapNodeType)
                      List.nil))))
              List.nil)
            false)
          0
          psKernelLeanNatMaxSizeDefault
  match nested with
  | Except.error _ =>
      false
  | Except.ok environment =>
      match
          psKernelEnvironmentFind
            environment
            treeName,
          psKernelEnvironmentFind
            environment
            recName,
          psKernelEnvironmentFind
            environment
            recAux1Name,
          psKernelEnvironmentFind
            environment
            recAux2Name with
      | Option.some
          (PsKernelConstantInfo.inductInfo info),
        Option.some
          (PsKernelConstantInfo.recInfo mainRec),
        Option.some
          (PsKernelConstantInfo.recInfo _),
        Option.some
          (PsKernelConstantInfo.recInfo _) =>
          Bool.and
            (Nat.beq info.numNested 2)
            (Bool.and
              (Nat.beq
                (psKernelSimpleNestedRuleListLength
                  mainRec.rules)
                3)
              (!(psKernelConstantListUsesNestedPrefix
                environment.constants)))
      | _, _, _, _ =>
          false

def psKernelCoreNestedRejectionTests : Bool :=
  let type1 :=
    PsKernelExpr.sort
      (PsKernelLevel.succ
        PsKernelLevel.zero)
  let reservedTypeName :=
    PsKernelName.str
      psKernelSimpleNestedPrefix
      "userType"
  let portableReservedType :=
    psKernelAddSimpleNestedInductive
      1024
      psKernelEnvironmentEmpty
      (PsKernelSimpleMutualInductiveDecl.mk
        List.nil
        0
        (List.cons
          (PsKernelSimpleMutualTypeDecl.mk
            reservedTypeName
            type1
            List.nil)
          List.nil)
        false)
      0
      psKernelLeanNatMaxSizeDefault
  let referenceReservedType :=
    PSC1Kernel.Kernel.addSimpleNestedInductive
      PSC1Kernel.Environment.empty
      {
        levelParams := []
        numParams := 0
        types := [{
          name :=
            psKernelNameToReference
              reservedTypeName
          type :=
            psKernelExprToReference
              type1
          ctors := []
        }]
        isUnsafe := false
      }
  let typeNameParity :=
    match
        portableReservedType,
        referenceReservedType with
    | Except.error portableError,
      Except.error referenceError =>
        Bool.and
          (portableError == referenceError)
          (portableError ==
            "reserved prefix '_nested' occurs in nested inductive declaration")
    | _, _ =>
        false
  let ownerName :=
    PsKernelName.str
      PsKernelName.anonymous
      "PortableNestedReservedOwner"
  let ownerType :=
    PsKernelExpr.const
      ownerName
      List.nil
  let reservedCtorName :=
    PsKernelName.str
      psKernelSimpleNestedPrefix
      "badCtor"
  let portableReservedCtor :=
    psKernelAddSimpleNestedInductive
      1024
      psKernelEnvironmentEmpty
      (PsKernelSimpleMutualInductiveDecl.mk
        List.nil
        0
        (List.cons
          (PsKernelSimpleMutualTypeDecl.mk
            ownerName
            type1
            (List.cons
              (PsKernelSimpleConstructorDecl.mk
                reservedCtorName
                ownerType)
              List.nil))
          List.nil)
        false)
      0
      psKernelLeanNatMaxSizeDefault
  let referenceReservedCtor :=
    PSC1Kernel.Kernel.addSimpleNestedInductive
      PSC1Kernel.Environment.empty
      {
        levelParams := []
        numParams := 0
        types := [{
          name :=
            psKernelNameToReference
              ownerName
          type :=
            psKernelExprToReference
              type1
          ctors := [{
            name :=
              psKernelNameToReference
                reservedCtorName
            type :=
              psKernelExprToReference
                ownerType
          }]
        }]
        isUnsafe := false
      }
  let ctorNameParity :=
    match
        portableReservedCtor,
        referenceReservedCtor with
    | Except.error portableError,
      Except.error referenceError =>
        Bool.and
          (portableError == referenceError)
          (portableError ==
            "reserved prefix '_nested' occurs in nested inductive constructor")
    | _, _ =>
        false
  Bool.and
    typeNameParity
    ctorNameParity

def psKernelCoreNestedConformanceTests : Bool :=
  Bool.and
    psKernelCoreNestedTests
    (Bool.and
      psKernelCoreNestedMultiFamilyTests
      psKernelCoreNestedRejectionTests)

def psKernelDefEqSpecialRuleTests : Bool :=
  let type1 :=
    PsKernelExpr.sort
      (PsKernelLevel.succ PsKernelLevel.zero)
  let portableStringEnv :=
    psKernelEnvironmentAddUnchecked
      psKernelEnvironmentEmpty
      (PsKernelConstantInfo.axiomInfo {
        base := {
          name := psKernelStringName
          levelParams := List.nil
          type := type1
        }
        isUnsafe := false
      })
  let referenceStringEnv :=
    PSC1Kernel.Environment.empty.addUnchecked
      (PSC1Kernel.ConstantInfo.axiomInfo {
        base := {
          name := PSC1Kernel.kernelStringName
          levelParams := List.nil
          type :=
            PSC1Kernel.Expr.sort
              (PSC1Kernel.Level.succ
                PSC1Kernel.Level.zero)
        }
        isUnsafe := false
      })
  let literal :=
    PsKernelExpr.lit
      (PsKernelLiteral.str "Aλ")
  let expanded :=
    psKernelStringLitToConstructor "Aλ"
  let stringParity :=
    match
        psKernelIsDefEq
          4096
          (psKernelCheckerContextEmpty
            portableStringEnv)
          psKernelCheckerStateEmpty
          literal
          expanded,
        PSC1Kernel.isDefEq
          (PSC1Kernel.CheckerContext.empty
            referenceStringEnv)
          (psKernelExprToReference literal)
          (psKernelExprToReference expanded) with
    | Except.ok portableResult, Except.ok referenceResult =>
        Bool.and
          (Prod.fst portableResult)
          referenceResult
    | _, _ =>
        false
  let unitName :=
    PsKernelName.str
      PsKernelName.anonymous
      "ConformanceUnit"
  let unitCtorName :=
    PsKernelName.str
      unitName
      "mk"
  let unitType :=
    PsKernelExpr.const
      unitName
      List.nil
  let portableUnitEnv0 :=
    psKernelEnvironmentAddUnchecked
      psKernelEnvironmentEmpty
      (PsKernelConstantInfo.inductInfo {
        base := {
          name := unitName
          levelParams := List.nil
          type := type1
        }
        numParams := 0
        numIndices := 0
        all := List.cons unitName List.nil
        ctors := List.cons unitCtorName List.nil
        numNested := 0
        isRec := false
        isReflexive := false
        isUnsafe := false
      })
  let portableUnitEnv :=
    psKernelEnvironmentAddUnchecked
      portableUnitEnv0
      (PsKernelConstantInfo.ctorInfo {
        base := {
          name := unitCtorName
          levelParams := List.nil
          type := unitType
        }
        induct := unitName
        cidx := 0
        numParams := 0
        numFields := 0
        isUnsafe := false
      })
  let referenceUnitName :=
    psKernelNameToReference unitName
  let referenceUnitCtorName :=
    psKernelNameToReference unitCtorName
  let referenceUnitType :=
    PSC1Kernel.Expr.const
      referenceUnitName
      List.nil
  let referenceUnitEnv0 :=
    PSC1Kernel.Environment.empty.addUnchecked
      (PSC1Kernel.ConstantInfo.inductInfo {
        base := {
          name := referenceUnitName
          levelParams := List.nil
          type :=
            PSC1Kernel.Expr.sort
              (PSC1Kernel.Level.succ
                PSC1Kernel.Level.zero)
        }
        numParams := 0
        numIndices := 0
        all := List.cons referenceUnitName List.nil
        ctors := List.cons referenceUnitCtorName List.nil
        numNested := 0
        isRec := false
        isReflexive := false
        isUnsafe := false
      })
  let referenceUnitEnv :=
    referenceUnitEnv0.addUnchecked
      (PSC1Kernel.ConstantInfo.ctorInfo {
        base := {
          name := referenceUnitCtorName
          levelParams := List.nil
          type := referenceUnitType
        }
        induct := referenceUnitName
        cidx := 0
        numParams := 0
        numFields := 0
        isUnsafe := false
      })
  let leftName :=
    PsKernelName.str
      PsKernelName.anonymous
      "unitLeft"
  let rightName :=
    PsKernelName.str
      PsKernelName.anonymous
      "unitRight"
  let portableLeft :=
    psKernelCheckerContextWithLocal
      (psKernelCheckerContextEmpty
        portableUnitEnv)
      leftName
      unitType
      PsKernelBinderInfo.default
  let portableRight :=
    psKernelCheckerContextWithLocal
      (Prod.snd portableLeft)
      rightName
      unitType
      PsKernelBinderInfo.default
  let referenceLeft :=
    (PSC1Kernel.CheckerContext.empty
      referenceUnitEnv).withLocal
      (psKernelNameToReference leftName)
      referenceUnitType
      PSC1Kernel.BinderInfo.default
  let referenceRight :=
    PSC1Kernel.CheckerContext.withLocal
      (Prod.snd referenceLeft)
      (psKernelNameToReference rightName)
      referenceUnitType
      PSC1Kernel.BinderInfo.default
  let unitParity :=
    match
        psKernelIsDefEq
          4096
          (Prod.snd portableRight)
          psKernelCheckerStateEmpty
          (PsKernelExpr.fvar
            (Prod.fst portableLeft))
          (PsKernelExpr.fvar
            (Prod.fst portableRight)),
        PSC1Kernel.isDefEq
          (Prod.snd referenceRight)
          (PSC1Kernel.Expr.fvar
            (Prod.fst referenceLeft))
          (PSC1Kernel.Expr.fvar
            (Prod.fst referenceRight)) with
    | Except.ok portableResult, Except.ok referenceResult =>
        Bool.and
          (Prod.fst portableResult)
          referenceResult
    | _, _ =>
        false
  Bool.and stringParity unitParity

