import Ps.KernelCore.Admission.Declaration.Admission

/-
Quotient bootstrap definitions.

This module validates the pre-existing Eq/Eq.refl shape expected by Lean 4.34
and constructs the kernel-recognized Quot/Quot.mk/Quot.lift/Quot.ind types.
It does not extend the environment.
-/


structure PsKernelOpenBinder where
  internalName : PsKernelName
  userName : PsKernelName
  type : PsKernelExpr
  binderInfo : PsKernelBinderInfo

def psKernelMkArrow
    (domain : PsKernelExpr)
    (codomain : PsKernelExpr) :
    PsKernelExpr :=
  PsKernelExpr.forallE
    PsKernelName.anonymous
    domain
    codomain
    PsKernelBinderInfo.default

def psKernelCloseOpenBinders
    (binders : List PsKernelOpenBinder) :
    PsKernelExpr -> PsKernelExpr :=
  match binders with
  | List.nil =>
      fun (body : PsKernelExpr) =>
        body
  | List.cons binder rest =>
      let smaller :
          PsKernelExpr -> PsKernelExpr :=
        psKernelCloseOpenBinders rest;
      fun (body : PsKernelExpr) =>
        let inner :=
          smaller body;
        PsKernelExpr.forallE
          binder.userName
          binder.type
          (psKernelExprAbstractFVars
            inner
            (List.cons
              binder.internalName
              List.nil))
          binder.binderInfo

def psKernelQuotInternalName
    (value : String) : PsKernelName :=
  PsKernelName.str
    (PsKernelName.str
      PsKernelName.anonymous
      "_psc1Quot")
    value

def psKernelEqName : PsKernelName :=
  PsKernelName.str
    PsKernelName.anonymous
    "Eq"

def psKernelExpectedEqType
    (universeName : PsKernelName) :
    PsKernelExpr :=
  let universeLevel :=
    PsKernelLevel.param universeName;
  let alphaName :=
    psKernelQuotInternalName
      "eq.alpha";
  let alpha :=
    PsKernelExpr.fvar alphaName;
  let alphaBinder : PsKernelOpenBinder :=
    {
      internalName := alphaName
      userName :=
        PsKernelName.str
          PsKernelName.anonymous
          "α"
      type := PsKernelExpr.sort universeLevel
      binderInfo := PsKernelBinderInfo.implicit
    };
  psKernelCloseOpenBinders
    (List.cons alphaBinder List.nil)
    (psKernelMkArrow
      alpha
      (psKernelMkArrow
        alpha
        (PsKernelExpr.sort
          PsKernelLevel.zero)))

def psKernelExpectedEqReflType
    (universeName : PsKernelName) :
    PsKernelExpr :=
  let universeLevel :=
    PsKernelLevel.param universeName;
  let alphaName :=
    psKernelQuotInternalName
      "eqRefl.alpha";
  let valueName :=
    psKernelQuotInternalName
      "eqRefl.a";
  let alpha :=
    PsKernelExpr.fvar alphaName;
  let value :=
    PsKernelExpr.fvar valueName;
  let alphaBinder : PsKernelOpenBinder :=
    {
      internalName := alphaName
      userName :=
        PsKernelName.str
          PsKernelName.anonymous
          "α"
      type := PsKernelExpr.sort universeLevel
      binderInfo := PsKernelBinderInfo.implicit
    };
  let valueBinder : PsKernelOpenBinder :=
    {
      internalName := valueName
      userName :=
        PsKernelName.str
          PsKernelName.anonymous
          "a"
      type := alpha
      binderInfo := PsKernelBinderInfo.default
    };
  let result :=
    psKernelApplyArgs
      (PsKernelExpr.const
        psKernelEqName
        (List.cons universeLevel List.nil))
      (List.cons
        alpha
        (List.cons
          value
          (List.cons value List.nil)));
  psKernelCloseOpenBinders
    (List.cons
      alphaBinder
      (List.cons valueBinder List.nil))
    result

def psKernelCheckEqForQuot
    (environment : PsKernelEnvironment) :
    Except String Unit :=
  match
      psKernelEnvironmentFind
        environment
        psKernelEqName with
  | Option.none =>
      Except.error
        "failed to initialize quot module, environment does not have Eq type"
  | Option.some eqValue =>
      match eqValue with
      | PsKernelConstantInfo.inductInfo eqInfo =>
          match eqInfo.base.levelParams with
          | List.cons universeName universeTail =>
              match universeTail with
              | List.cons _ _ =>
                  Except.error
                    "failed to initialize quot module, unexpected number of universe params at Eq type"
              | List.nil =>
                  match eqInfo.ctors with
                  | List.cons reflName reflTail =>
                      match reflTail with
                      | List.cons _ _ =>
                          Except.error
                            "failed to initialize quot module, unexpected number of constructors for Eq type"
                      | List.nil =>
                          if
                              psKernelExprEq
                                eqInfo.base.type
                                (psKernelExpectedEqType
                                  universeName) then
                            match
                                psKernelEnvironmentFind
                                  environment
                                  reflName with
                            | Option.none =>
                                Except.error
                                  "failed to initialize quot module, missing Eq constructor"
                            | Option.some reflInfo =>
                                match
                                    psKernelConstantInfoLevelParams
                                      reflInfo with
                                | List.cons reflUniverse reflUniverseTail =>
                                    match reflUniverseTail with
                                    | List.cons _ _ =>
                                        Except.error
                                          "failed to initialize quot module, unexpected universe params at Eq constructor"
                                    | List.nil =>
                                        if
                                            psKernelExprEq
                                              (psKernelConstantInfoType
                                                reflInfo)
                                              (psKernelExpectedEqReflType
                                                reflUniverse) then
                                          Except.ok ()
                                        else
                                          Except.error
                                            "failed to initialize quot module, unexpected type for Eq constructor"
                                | List.nil =>
                                    Except.error
                                      "failed to initialize quot module, unexpected universe params at Eq constructor"
                          else
                            Except.error
                              "failed to initialize quot module, Eq has an unexpected type"
                  | List.nil =>
                      Except.error
                        "failed to initialize quot module, unexpected number of constructors for Eq type"
          | List.nil =>
              Except.error
                "failed to initialize quot module, unexpected number of universe params at Eq type"
      | _ =>
          Except.error
            "failed to initialize quot module, environment does not have Eq type"

def psKernelMakeQuotType
    (universeName : PsKernelName) :
    PsKernelExpr :=
  let universeLevel :=
    PsKernelLevel.param universeName;
  let alphaName :=
    psKernelQuotInternalName "quot.alpha";
  let relationName :=
    psKernelQuotInternalName "quot.r";
  let alpha :=
    PsKernelExpr.fvar alphaName;
  let relation :=
    PsKernelExpr.fvar relationName;
  let alphaBinder : PsKernelOpenBinder :=
    {
      internalName := alphaName
      userName :=
        PsKernelName.str
          PsKernelName.anonymous
          "α"
      type := PsKernelExpr.sort universeLevel
      binderInfo := PsKernelBinderInfo.implicit
    };
  let relationBinder : PsKernelOpenBinder :=
    {
      internalName := relationName
      userName :=
        PsKernelName.str
          PsKernelName.anonymous
          "r"
      type :=
        psKernelMkArrow
          alpha
          (psKernelMkArrow
            alpha
            (PsKernelExpr.sort
              PsKernelLevel.zero))
      binderInfo := PsKernelBinderInfo.default
    };
  psKernelCloseOpenBinders
    (List.cons
      alphaBinder
      (List.cons relationBinder List.nil))
    (PsKernelExpr.sort universeLevel)

def psKernelMakeQuotMkType
    (universeName : PsKernelName) :
    PsKernelExpr :=
  let universeLevel :=
    PsKernelLevel.param universeName;
  let alphaName :=
    psKernelQuotInternalName "mk.alpha";
  let relationName :=
    psKernelQuotInternalName "mk.r";
  let valueName :=
    psKernelQuotInternalName "mk.a";
  let alpha :=
    PsKernelExpr.fvar alphaName;
  let relation :=
    PsKernelExpr.fvar relationName;
  let value :=
    PsKernelExpr.fvar valueName;
  let alphaBinder : PsKernelOpenBinder :=
    {
      internalName := alphaName
      userName :=
        PsKernelName.str
          PsKernelName.anonymous
          "α"
      type := PsKernelExpr.sort universeLevel
      binderInfo := PsKernelBinderInfo.implicit
    };
  let relationBinder : PsKernelOpenBinder :=
    {
      internalName := relationName
      userName :=
        PsKernelName.str
          PsKernelName.anonymous
          "r"
      type :=
        psKernelMkArrow
          alpha
          (psKernelMkArrow
            alpha
            (PsKernelExpr.sort
              PsKernelLevel.zero))
      binderInfo := PsKernelBinderInfo.default
    };
  let valueBinder : PsKernelOpenBinder :=
    {
      internalName := valueName
      userName :=
        PsKernelName.str
          PsKernelName.anonymous
          "a"
      type := alpha
      binderInfo := PsKernelBinderInfo.default
    };
  let quotRelation :=
    psKernelApplyArgs
      (PsKernelExpr.const
        psKernelQuotName
        (List.cons universeLevel List.nil))
      (List.cons
        alpha
        (List.cons relation List.nil));
  psKernelCloseOpenBinders
    (List.cons
      alphaBinder
      (List.cons
        relationBinder
        (List.cons valueBinder List.nil)))
    quotRelation

def psKernelMakeQuotLiftType
    (universeName : PsKernelName)
    (resultUniverseName : PsKernelName) :
    PsKernelExpr :=
  let universeLevel :=
    PsKernelLevel.param universeName;
  let resultUniverse :=
    PsKernelLevel.param resultUniverseName;
  let alphaName :=
    psKernelQuotInternalName "lift.alpha";
  let relationName :=
    psKernelQuotInternalName "lift.r";
  let betaName :=
    psKernelQuotInternalName "lift.beta";
  let functionName :=
    psKernelQuotInternalName "lift.f";
  let leftName :=
    psKernelQuotInternalName "lift.a";
  let rightName :=
    psKernelQuotInternalName "lift.b";
  let alpha := PsKernelExpr.fvar alphaName;
  let relation := PsKernelExpr.fvar relationName;
  let beta := PsKernelExpr.fvar betaName;
  let functionValue := PsKernelExpr.fvar functionName;
  let left := PsKernelExpr.fvar leftName;
  let right := PsKernelExpr.fvar rightName;
  let relationType :=
    psKernelMkArrow
      alpha
      (psKernelMkArrow
        alpha
        (PsKernelExpr.sort
          PsKernelLevel.zero));
  let quotRelation :=
    psKernelApplyArgs
      (PsKernelExpr.const
        psKernelQuotName
        (List.cons universeLevel List.nil))
      (List.cons
        alpha
        (List.cons relation List.nil));
  let alphaBinder : PsKernelOpenBinder :=
    {
      internalName := alphaName
      userName :=
        PsKernelName.str PsKernelName.anonymous "α"
      type := PsKernelExpr.sort universeLevel
      binderInfo := PsKernelBinderInfo.implicit
    };
  let relationBinder : PsKernelOpenBinder :=
    {
      internalName := relationName
      userName :=
        PsKernelName.str PsKernelName.anonymous "r"
      type := relationType
      binderInfo := PsKernelBinderInfo.implicit
    };
  let betaBinder : PsKernelOpenBinder :=
    {
      internalName := betaName
      userName :=
        PsKernelName.str PsKernelName.anonymous "β"
      type := PsKernelExpr.sort resultUniverse
      binderInfo := PsKernelBinderInfo.implicit
    };
  let functionBinder : PsKernelOpenBinder :=
    {
      internalName := functionName
      userName :=
        PsKernelName.str PsKernelName.anonymous "f"
      type := psKernelMkArrow alpha beta
      binderInfo := PsKernelBinderInfo.default
    };
  let leftBinder : PsKernelOpenBinder :=
    {
      internalName := leftName
      userName :=
        PsKernelName.str PsKernelName.anonymous "a"
      type := alpha
      binderInfo := PsKernelBinderInfo.default
    };
  let rightBinder : PsKernelOpenBinder :=
    {
      internalName := rightName
      userName :=
        PsKernelName.str PsKernelName.anonymous "b"
      type := alpha
      binderInfo := PsKernelBinderInfo.default
    };
  let relationLeftRight :=
    psKernelApplyArgs
      relation
      (List.cons
        left
        (List.cons right List.nil));
  let functionLeft :=
    PsKernelExpr.app functionValue left;
  let functionRight :=
    PsKernelExpr.app functionValue right;
  let eqFunctions :=
    psKernelApplyArgs
      (PsKernelExpr.const
        psKernelEqName
        (List.cons resultUniverse List.nil))
      (List.cons
        beta
        (List.cons
          functionLeft
          (List.cons functionRight List.nil)));
  let sanity :=
    psKernelCloseOpenBinders
      (List.cons
        leftBinder
        (List.cons rightBinder List.nil))
      (psKernelMkArrow
        relationLeftRight
        eqFunctions);
  let result :=
    psKernelMkArrow
      sanity
      (psKernelMkArrow
        quotRelation
        beta);
  psKernelCloseOpenBinders
    (List.cons
      alphaBinder
      (List.cons
        relationBinder
        (List.cons
          betaBinder
          (List.cons functionBinder List.nil))))
    result

def psKernelMakeQuotIndType
    (universeName : PsKernelName) :
    PsKernelExpr :=
  let universeLevel :=
    PsKernelLevel.param universeName;
  let alphaName :=
    psKernelQuotInternalName "ind.alpha";
  let relationName :=
    psKernelQuotInternalName "ind.r";
  let betaName :=
    psKernelQuotInternalName "ind.beta";
  let valueName :=
    psKernelQuotInternalName "ind.a";
  let proofName :=
    psKernelQuotInternalName "ind.mkProof";
  let quotientName :=
    psKernelQuotInternalName "ind.q";
  let alpha := PsKernelExpr.fvar alphaName;
  let relation := PsKernelExpr.fvar relationName;
  let beta := PsKernelExpr.fvar betaName;
  let value := PsKernelExpr.fvar valueName;
  let quotient := PsKernelExpr.fvar quotientName;
  let relationType :=
    psKernelMkArrow
      alpha
      (psKernelMkArrow
        alpha
        (PsKernelExpr.sort
          PsKernelLevel.zero));
  let quotRelation :=
    psKernelApplyArgs
      (PsKernelExpr.const
        psKernelQuotName
        (List.cons universeLevel List.nil))
      (List.cons
        alpha
        (List.cons relation List.nil));
  let alphaBinder : PsKernelOpenBinder :=
    {
      internalName := alphaName
      userName :=
        PsKernelName.str PsKernelName.anonymous "α"
      type := PsKernelExpr.sort universeLevel
      binderInfo := PsKernelBinderInfo.implicit
    };
  let relationBinder : PsKernelOpenBinder :=
    {
      internalName := relationName
      userName :=
        PsKernelName.str PsKernelName.anonymous "r"
      type := relationType
      binderInfo := PsKernelBinderInfo.implicit
    };
  let betaBinder : PsKernelOpenBinder :=
    {
      internalName := betaName
      userName :=
        PsKernelName.str PsKernelName.anonymous "β"
      type :=
        psKernelMkArrow
          quotRelation
          (PsKernelExpr.sort
            PsKernelLevel.zero)
      binderInfo := PsKernelBinderInfo.implicit
    };
  let valueBinder : PsKernelOpenBinder :=
    {
      internalName := valueName
      userName :=
        PsKernelName.str PsKernelName.anonymous "a"
      type := alpha
      binderInfo := PsKernelBinderInfo.default
    };
  let quotMkValue :=
    psKernelApplyArgs
      (PsKernelExpr.const
        psKernelQuotMkName
        (List.cons universeLevel List.nil))
      (List.cons
        alpha
        (List.cons
          relation
          (List.cons value List.nil)));
  let allQuot :=
    psKernelCloseOpenBinders
      (List.cons valueBinder List.nil)
      (PsKernelExpr.app
        beta
        quotMkValue);
  let proofBinder : PsKernelOpenBinder :=
    {
      internalName := proofName
      userName :=
        PsKernelName.str PsKernelName.anonymous "mk"
      type := allQuot
      binderInfo := PsKernelBinderInfo.default
    };
  let quotientBinder : PsKernelOpenBinder :=
    {
      internalName := quotientName
      userName :=
        PsKernelName.str PsKernelName.anonymous "q"
      type := quotRelation
      binderInfo := PsKernelBinderInfo.default
    };
  let result :=
    psKernelCloseOpenBinders
      (List.cons
        proofBinder
        (List.cons quotientBinder List.nil))
      (PsKernelExpr.app
        beta
        quotient);
  psKernelCloseOpenBinders
    (List.cons
      alphaBinder
      (List.cons
        relationBinder
        (List.cons betaBinder List.nil)))
    result

def psKernelCheckQuotReservedNames
    (environment : PsKernelEnvironment)
    (names : List PsKernelName) :
    Except String Unit :=
  match names with
  | List.nil =>
      Except.ok ()
  | List.cons name rest =>
      if psKernelEnvironmentContains environment name then
        Except.error
          "failed to initialize quot module, quotient name is already declared"
      else
        psKernelCheckQuotReservedNames
          environment
          rest
