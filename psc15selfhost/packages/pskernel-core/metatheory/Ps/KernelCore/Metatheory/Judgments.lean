import Ps.KernelCore.Checker.Inference.Core
import Ps.KernelCore.Checker.Reduction.Whnf

/-
Shared Assurance Plane judgments for PSKernel Core.

This library is outside packages/pskernel-core/src and therefore outside the
portable production semantic closure.  It specifies properties that the
executable kernel must refine.

Important: algorithmic definitional equality is deliberately not given a
transitivity constructor, matching Lean/PSKernel's non-transitive algorithmic
defeq behavior.
-/

def PsKernelEnvironmentLookupSound
    (environment : PsKernelEnvironment) : Prop :=
  ∀ (name : PsKernelName) (info : PsKernelConstantInfo),
    psKernelEnvironmentFind environment name = Option.some info ->
      psKernelFindConstantInList
          name
          environment.constants =
        Option.some info

def PsKernelEnvironmentIndexRefines
    (environment : PsKernelEnvironment) : Prop :=
  ∀ (name : PsKernelName),
    psKernelFindConstantInList
        name
        (psKernelEnvironmentIndexFind
          environment.index
          name) =
      psKernelFindConstantInList
        name
        environment.constants

inductive PsKernelReductionStep
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext) :
    PsKernelExpr -> PsKernelExpr -> Prop
  | beta
      (name : PsKernelName)
      (type body arg : PsKernelExpr)
      (binderInfo : PsKernelBinderInfo) :
      PsKernelReductionStep
        environment
        localContext
        (PsKernelExpr.app
          (PsKernelExpr.lam name type body binderInfo)
          arg)
        (psKernelExprInstantiate1 body arg)
  | zeta
      (name : PsKernelName)
      (type value body : PsKernelExpr)
      (nondep : Bool) :
      PsKernelReductionStep
        environment
        localContext
        (PsKernelExpr.letE name type value body nondep)
        (psKernelExprInstantiate1 body value)
  | metadata
      (metadata : Nat)
      (body : PsKernelExpr) :
      PsKernelReductionStep
        environment
        localContext
        (PsKernelExpr.mdata metadata body)
        body
  | localLet
      (name : PsKernelName)
      (declaration : PsKernelLocalDecl)
      (value : PsKernelExpr)
      (hFind :
        psKernelLocalContextFind localContext name =
          Option.some declaration)
      (hValue :
        psKernelLocalDeclValue declaration =
          Option.some value) :
      PsKernelReductionStep
        environment
        localContext
        (PsKernelExpr.fvar name)
        value
  | deltaConst
      (name : PsKernelName)
      (levels : List PsKernelLevel)
      (info : PsKernelConstantInfo)
      (value : PsKernelExpr)
      (hFind :
        psKernelFindConstantInList
            name
            environment.constants =
          Option.some info)
      (hDelta :
        psKernelConstantInfoDeltaValue info =
          Option.some value)
      (hLevels :
        psKernelNameListLength
            (psKernelConstantInfoLevelParams info) =
          psKernelLevelListLength levels) :
      PsKernelReductionStep
        environment
        localContext
        (PsKernelExpr.const name levels)
        (psKernelExprInstantiateLevelParams
          value
          (psKernelConstantInfoLevelParams info)
          levels)


  | natAdd
      (op : PsKernelName)
      (left right : Nat)
      (hOp :
        psKernelNameEq op psKernelNatAddName = true) :
      PsKernelReductionStep
        environment
        localContext
        (PsKernelExpr.app
          (PsKernelExpr.app
            (PsKernelExpr.const op List.nil)
            (PsKernelExpr.lit (PsKernelLiteral.nat left)))
          (PsKernelExpr.lit (PsKernelLiteral.nat right)))
        (PsKernelExpr.lit
          (PsKernelLiteral.nat (Nat.add left right)))
  | natSub
      (op : PsKernelName)
      (left right : Nat)
      (hOp :
        psKernelNameEq op psKernelNatSubName = true) :
      PsKernelReductionStep
        environment
        localContext
        (PsKernelExpr.app
          (PsKernelExpr.app
            (PsKernelExpr.const op List.nil)
            (PsKernelExpr.lit (PsKernelLiteral.nat left)))
          (PsKernelExpr.lit (PsKernelLiteral.nat right)))
        (PsKernelExpr.lit
          (PsKernelLiteral.nat (Nat.sub left right)))
  | natMul
      (op : PsKernelName)
      (left right : Nat)
      (hOp :
        psKernelNameEq op psKernelNatMulName = true) :
      PsKernelReductionStep
        environment
        localContext
        (PsKernelExpr.app
          (PsKernelExpr.app
            (PsKernelExpr.const op List.nil)
            (PsKernelExpr.lit (PsKernelLiteral.nat left)))
          (PsKernelExpr.lit (PsKernelLiteral.nat right)))
        (PsKernelExpr.lit
          (PsKernelLiteral.nat (Nat.mul left right)))


  | natSucc
      (op : PsKernelName)
      (value : Nat)
      (hOp :
        psKernelNameEq op psKernelNatSuccName = true) :
      PsKernelReductionStep
        environment
        localContext
        (PsKernelExpr.app
          (PsKernelExpr.const op List.nil)
          (PsKernelExpr.lit (PsKernelLiteral.nat value)))
        (PsKernelExpr.lit
          (PsKernelLiteral.nat (Nat.succ value)))
  | natMod
      (op : PsKernelName)
      (left right : Nat)
      (hOp :
        psKernelNameEq op psKernelNatModName = true) :
      PsKernelReductionStep
        environment
        localContext
        (PsKernelExpr.app
          (PsKernelExpr.app
            (PsKernelExpr.const op List.nil)
            (PsKernelExpr.lit (PsKernelLiteral.nat left)))
          (PsKernelExpr.lit (PsKernelLiteral.nat right)))
        (PsKernelExpr.lit
          (PsKernelLiteral.nat
            (if Nat.beq right 0 then left else Nat.mod left right)))
  | natDiv
      (op : PsKernelName)
      (left right : Nat)
      (hOp :
        psKernelNameEq op psKernelNatDivName = true) :
      PsKernelReductionStep
        environment
        localContext
        (PsKernelExpr.app
          (PsKernelExpr.app
            (PsKernelExpr.const op List.nil)
            (PsKernelExpr.lit (PsKernelLiteral.nat left)))
          (PsKernelExpr.lit (PsKernelLiteral.nat right)))
        (PsKernelExpr.lit
          (PsKernelLiteral.nat
            (if Nat.beq right 0 then 0 else Nat.div left right)))
  | natBeq
      (op : PsKernelName)
      (left right : Nat)
      (hOp :
        psKernelNameEq op psKernelNatBeqName = true) :
      PsKernelReductionStep
        environment
        localContext
        (PsKernelExpr.app
          (PsKernelExpr.app
            (PsKernelExpr.const op List.nil)
            (PsKernelExpr.lit (PsKernelLiteral.nat left)))
          (PsKernelExpr.lit (PsKernelLiteral.nat right)))
        (psKernelBoolExpr (Nat.beq left right))
  | natBle
      (op : PsKernelName)
      (left right : Nat)
      (hOp :
        psKernelNameEq op psKernelNatBleName = true) :
      PsKernelReductionStep
        environment
        localContext
        (PsKernelExpr.app
          (PsKernelExpr.app
            (PsKernelExpr.const op List.nil)
            (PsKernelExpr.lit (PsKernelLiteral.nat left)))
          (PsKernelExpr.lit (PsKernelLiteral.nat right)))
        (psKernelBoolExpr (Nat.ble left right))

inductive PsKernelReductionClosure
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext) :
    PsKernelExpr -> PsKernelExpr -> Prop
  | refl
      (expr : PsKernelExpr) :
      PsKernelReductionClosure
        environment
        localContext
        expr
        expr
  | cons
      (left middle right : PsKernelExpr)
      (hStep :
        PsKernelReductionStep
          environment
          localContext
          left
          middle)
      (hRest :
        PsKernelReductionClosure
          environment
          localContext
          middle
          right) :
      PsKernelReductionClosure
        environment
        localContext
        left
        right

inductive PsKernelStructuralExprEq :
    PsKernelExpr -> PsKernelExpr -> Prop
  | bvar
      (left right : Nat)
      (h : Nat.beq left right = true) :
      PsKernelStructuralExprEq
        (PsKernelExpr.bvar left)
        (PsKernelExpr.bvar right)
  | fvar
      (left right : PsKernelName)
      (h : psKernelNameEq left right = true) :
      PsKernelStructuralExprEq
        (PsKernelExpr.fvar left)
        (PsKernelExpr.fvar right)
  | mvar
      (left right : PsKernelName)
      (h : psKernelNameEq left right = true) :
      PsKernelStructuralExprEq
        (PsKernelExpr.mvar left)
        (PsKernelExpr.mvar right)
  | sort
      (left right : PsKernelLevel)
      (h : psKernelLevelEq left right = true) :
      PsKernelStructuralExprEq
        (PsKernelExpr.sort left)
        (PsKernelExpr.sort right)
  | const
      (leftName rightName : PsKernelName)
      (leftLevels rightLevels : List PsKernelLevel)
      (hName : psKernelNameEq leftName rightName = true)
      (hLevels : psKernelLevelListEq leftLevels rightLevels = true) :
      PsKernelStructuralExprEq
        (PsKernelExpr.const leftName leftLevels)
        (PsKernelExpr.const rightName rightLevels)
  | app
      (leftFn leftArg rightFn rightArg : PsKernelExpr)
      (hFn : PsKernelStructuralExprEq leftFn rightFn)
      (hArg : PsKernelStructuralExprEq leftArg rightArg) :
      PsKernelStructuralExprEq
        (PsKernelExpr.app leftFn leftArg)
        (PsKernelExpr.app rightFn rightArg)
  | lam
      (leftName rightName : PsKernelName)
      (leftType leftBody rightType rightBody : PsKernelExpr)
      (leftInfo rightInfo : PsKernelBinderInfo)
      (hType : PsKernelStructuralExprEq leftType rightType)
      (hBody : PsKernelStructuralExprEq leftBody rightBody) :
      PsKernelStructuralExprEq
        (PsKernelExpr.lam leftName leftType leftBody leftInfo)
        (PsKernelExpr.lam rightName rightType rightBody rightInfo)
  | forallE
      (leftName rightName : PsKernelName)
      (leftType leftBody rightType rightBody : PsKernelExpr)
      (leftInfo rightInfo : PsKernelBinderInfo)
      (hType : PsKernelStructuralExprEq leftType rightType)
      (hBody : PsKernelStructuralExprEq leftBody rightBody) :
      PsKernelStructuralExprEq
        (PsKernelExpr.forallE leftName leftType leftBody leftInfo)
        (PsKernelExpr.forallE rightName rightType rightBody rightInfo)
  | letE
      (leftName rightName : PsKernelName)
      (leftType leftValue leftBody : PsKernelExpr)
      (rightType rightValue rightBody : PsKernelExpr)
      (leftNondep rightNondep : Bool)
      (hType : PsKernelStructuralExprEq leftType rightType)
      (hValue : PsKernelStructuralExprEq leftValue rightValue)
      (hBody : PsKernelStructuralExprEq leftBody rightBody)
      (hNondep : psKernelBoolEq leftNondep rightNondep = true) :
      PsKernelStructuralExprEq
        (PsKernelExpr.letE
          leftName leftType leftValue leftBody leftNondep)
        (PsKernelExpr.letE
          rightName rightType rightValue rightBody rightNondep)
  | lit
      (left right : PsKernelLiteral)
      (h : psKernelLiteralEq left right = true) :
      PsKernelStructuralExprEq
        (PsKernelExpr.lit left)
        (PsKernelExpr.lit right)
  | mdata
      (leftMetadata rightMetadata : Nat)
      (left right : PsKernelExpr)
      (hMetadata : Nat.beq leftMetadata rightMetadata = true)
      (hBody : PsKernelStructuralExprEq left right) :
      PsKernelStructuralExprEq
        (PsKernelExpr.mdata leftMetadata left)
        (PsKernelExpr.mdata rightMetadata right)
  | proj
      (leftName rightName : PsKernelName)
      (leftIndex rightIndex : Nat)
      (left right : PsKernelExpr)
      (hName : psKernelNameEq leftName rightName = true)
      (hIndex : Nat.beq leftIndex rightIndex = true)
      (hBody : PsKernelStructuralExprEq left right) :
      PsKernelStructuralExprEq
        (PsKernelExpr.proj leftName leftIndex left)
        (PsKernelExpr.proj rightName rightIndex right)

inductive PsKernelDefEqJudgment
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext) :
    PsKernelExpr -> PsKernelExpr -> Prop
  | refl
      (expr : PsKernelExpr) :
      PsKernelDefEqJudgment
        environment
        localContext
        expr
        expr
  | symm
      (left right : PsKernelExpr)
      (h :
        PsKernelDefEqJudgment
          environment
          localContext
          left
          right) :
      PsKernelDefEqJudgment
        environment
        localContext
        right
        left
  | structural
      (left right : PsKernelExpr)
      (h : PsKernelStructuralExprEq left right) :
      PsKernelDefEqJudgment
        environment
        localContext
        left
        right
  | reduction
      (left right : PsKernelExpr)
      (h :
        PsKernelReductionStep
          environment
          localContext
          left
          right) :
      PsKernelDefEqJudgment
        environment
        localContext
        left
        right
  | sort
      (left right : PsKernelLevel)
      (h :
        psKernelLevelEquivalent left right = true) :
      PsKernelDefEqJudgment
        environment
        localContext
        (PsKernelExpr.sort left)
        (PsKernelExpr.sort right)
  | literal
      (left right : PsKernelLiteral)
      (h :
        psKernelLiteralEq left right = true) :
      PsKernelDefEqJudgment
        environment
        localContext
        (PsKernelExpr.lit left)
        (PsKernelExpr.lit right)
  | app
      (leftFn leftArg rightFn rightArg : PsKernelExpr)
      (hFn :
        PsKernelDefEqJudgment
          environment
          localContext
          leftFn
          rightFn)
      (hArg :
        PsKernelDefEqJudgment
          environment
          localContext
          leftArg
          rightArg) :
      PsKernelDefEqJudgment
        environment
        localContext
        (PsKernelExpr.app leftFn leftArg)
        (PsKernelExpr.app rightFn rightArg)
  | metadataLeft
      (metadata : Nat)
      (left right : PsKernelExpr)
      (h :
        PsKernelDefEqJudgment
          environment
          localContext
          left
          right) :
      PsKernelDefEqJudgment
        environment
        localContext
        (PsKernelExpr.mdata metadata left)
        right
  | metadataRight
      (metadata : Nat)
      (left right : PsKernelExpr)
      (h :
        PsKernelDefEqJudgment
          environment
          localContext
          left
          right) :
      PsKernelDefEqJudgment
        environment
        localContext
        left
        (PsKernelExpr.mdata metadata right)

def PsKernelExprEqSound
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext) : Prop :=
  ∀ (left right : PsKernelExpr),
    psKernelExprEq left right = true ->
      PsKernelDefEqJudgment
        environment
        localContext
        left
        right

def PsKernelDefEqCacheSound
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (cache : PsKernelExprPairSet) : Prop :=
  ∀ (left right : PsKernelExpr),
    psKernelExprPairSetContains cache left right = true ->
      PsKernelDefEqJudgment
        environment
        localContext
        left
        right


inductive PsKernelProjectionApplyParamsJudgment
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (args : List PsKernelExpr) :
    Nat -> Nat -> PsKernelExpr -> PsKernelExpr -> Prop
  | done
      (index numParams : Nat)
      (current : PsKernelExpr)
      (hDone : psKernelNatLt index numParams = false) :
      PsKernelProjectionApplyParamsJudgment
        environment
        localContext
        args
        index
        numParams
        current
        current
  | step
      (index numParams : Nat)
      (current domain body result argument : PsKernelExpr)
      (name : PsKernelName)
      (binderInfo : PsKernelBinderInfo)
      (hMore : psKernelNatLt index numParams = true)
      (hWhnf :
        PsKernelReductionClosure
          environment
          localContext
          current
          (PsKernelExpr.forallE name domain body binderInfo))
      (hArg :
        psKernelExprListGet args index =
          Option.some argument)
      (hRest :
        PsKernelProjectionApplyParamsJudgment
          environment
          localContext
          args
          (Nat.succ index)
          numParams
          (psKernelExprInstantiate1 body argument)
          result) :
      PsKernelProjectionApplyParamsJudgment
        environment
        localContext
        args
        index
        numParams
        current
        result

inductive PsKernelProjectionSkipFieldsJudgment
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (inductName : PsKernelName)
    (structValue : PsKernelExpr)
    (targetIndex : Nat) :
    Nat -> PsKernelExpr -> PsKernelExpr -> Prop
  | done
      (index : Nat)
      (current : PsKernelExpr)
      (hDone : psKernelNatLt index targetIndex = false) :
      PsKernelProjectionSkipFieldsJudgment
        environment
        localContext
        inductName
        structValue
        targetIndex
        index
        current
        current
  | stepClosed
      (index : Nat)
      (current domain body result : PsKernelExpr)
      (name : PsKernelName)
      (binderInfo : PsKernelBinderInfo)
      (hMore : psKernelNatLt index targetIndex = true)
      (hWhnf :
        PsKernelReductionClosure
          environment
          localContext
          current
          (PsKernelExpr.forallE name domain body binderInfo))
      (hClosed : psKernelExprHasLooseBVar body = false)
      (hRest :
        PsKernelProjectionSkipFieldsJudgment
          environment
          localContext
          inductName
          structValue
          targetIndex
          (Nat.succ index)
          body
          result) :
      PsKernelProjectionSkipFieldsJudgment
        environment
        localContext
        inductName
        structValue
        targetIndex
        index
        current
        result
  | stepDependent
      (index : Nat)
      (current domain body result : PsKernelExpr)
      (name : PsKernelName)
      (binderInfo : PsKernelBinderInfo)
      (hMore : psKernelNatLt index targetIndex = true)
      (hWhnf :
        PsKernelReductionClosure
          environment
          localContext
          current
          (PsKernelExpr.forallE name domain body binderInfo))
      (hDependent : psKernelExprHasLooseBVar body = true)
      (hRest :
        PsKernelProjectionSkipFieldsJudgment
          environment
          localContext
          inductName
          structValue
          targetIndex
          (Nat.succ index)
          (psKernelExprInstantiate1
            body
            (PsKernelExpr.proj
              inductName
              index
              structValue))
          result) :
      PsKernelProjectionSkipFieldsJudgment
        environment
        localContext
        inductName
        structValue
        targetIndex
        index
        current
        result

inductive PsKernelProjectionResultJudgment
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext) :
    PsKernelName ->
    Nat ->
    PsKernelExpr ->
    PsKernelExpr ->
    PsKernelExpr ->
    Prop
  | intro
      (typeName inductName ctorName fieldName : PsKernelName)
      (index : Nat)
      (structValue structType typeWhnf : PsKernelExpr)
      (inductLevels : List PsKernelLevel)
      (args : List PsKernelExpr)
      (inductInfo : PsKernelInductiveInfo)
      (ctorInfo : PsKernelConstructorInfo)
      (initial afterParams afterFields fieldBody result : PsKernelExpr)
      (fieldBinderInfo : PsKernelBinderInfo)
      (hTypeWhnf :
        PsKernelReductionClosure
          environment
          localContext
          structType
          typeWhnf)
      (hTypeFn :
        psKernelExprGetAppFn typeWhnf =
          PsKernelExpr.const inductName inductLevels)
      (hTypeArgs :
        psKernelExprGetAppArgs typeWhnf = args)
      (hIndexBound :
        psKernelNatGt index psKernelLeanUInt32Max = false)
      (hTypeName :
        psKernelNameEq inductName typeName = true)
      (hInduct :
        psKernelFindConstantInList
            inductName
            environment.constants =
          Option.some
            (PsKernelConstantInfo.inductInfo inductInfo))
      (hCtors :
        inductInfo.ctors =
          List.cons ctorName List.nil)
      (hArgsLength :
        psKernelExprListLength args =
          Nat.add inductInfo.numParams inductInfo.numIndices)
      (hCtor :
        psKernelFindConstantInList
            ctorName
            environment.constants =
          Option.some
            (PsKernelConstantInfo.ctorInfo ctorInfo))
      (hInitial :
        initial =
          psKernelExprInstantiateLevelParams
            ctorInfo.base.type
            ctorInfo.base.levelParams
            inductLevels)
      (hParams :
        PsKernelProjectionApplyParamsJudgment
          environment
          localContext
          args
          0
          inductInfo.numParams
          initial
          afterParams)
      (hFields :
        PsKernelProjectionSkipFieldsJudgment
          environment
          localContext
          inductName
          structValue
          index
          0
          afterParams
          afterFields)
      (hFinal :
        PsKernelReductionClosure
          environment
          localContext
          afterFields
          (PsKernelExpr.forallE
            fieldName
            result
            fieldBody
            fieldBinderInfo)) :
      PsKernelProjectionResultJudgment
        environment
        localContext
        typeName
        index
        structValue
        structType
        result

inductive PsKernelTypingJudgment
    (environment : PsKernelEnvironment) :
    PsKernelLocalContext -> PsKernelExpr -> PsKernelExpr -> Prop
  | sort
      {localContext : PsKernelLocalContext}
      (level : PsKernelLevel) :
      PsKernelTypingJudgment
        environment
        localContext
        (PsKernelExpr.sort level)
        (PsKernelExpr.sort (PsKernelLevel.succ level))
  | natLiteral
      {localContext : PsKernelLocalContext}
      (value : Nat) :
      PsKernelTypingJudgment
        environment
        localContext
        (PsKernelExpr.lit (PsKernelLiteral.nat value))
        (PsKernelExpr.const psKernelNatName List.nil)
  | stringLiteral
      {localContext : PsKernelLocalContext}
      (value : String) :
      PsKernelTypingJudgment
        environment
        localContext
        (PsKernelExpr.lit (PsKernelLiteral.str value))
        (PsKernelExpr.const psKernelStringName List.nil)
  | fvar
      {localContext : PsKernelLocalContext}
      (name : PsKernelName)
      (declaration : PsKernelLocalDecl)
      (hFind :
        psKernelLocalContextFind localContext name =
          Option.some declaration) :
      PsKernelTypingJudgment
        environment
        localContext
        (PsKernelExpr.fvar name)
        (psKernelLocalDeclType declaration)
  | const
      {localContext : PsKernelLocalContext}
      (name : PsKernelName)
      (levels : List PsKernelLevel)
      (info : PsKernelConstantInfo)
      (hFind :
        psKernelFindConstantInList
            name
            environment.constants =
          Option.some info)
      (hLevels :
        psKernelNameListLength
            (psKernelConstantInfoLevelParams info) =
          psKernelLevelListLength levels) :
      PsKernelTypingJudgment
        environment
        localContext
        (PsKernelExpr.const name levels)
        (psKernelExprInstantiateLevelParams
          (psKernelConstantInfoType info)
          (psKernelConstantInfoLevelParams info)
          levels)
  | app
      {localContext : PsKernelLocalContext}
      (fn arg fnType argType domain body : PsKernelExpr)
      (name : PsKernelName)
      (binderInfo : PsKernelBinderInfo)
      (hFn :
        PsKernelTypingJudgment
          environment localContext fn fnType)
      (hFnType :
        PsKernelDefEqJudgment
          environment localContext fnType
          (PsKernelExpr.forallE name domain body binderInfo))
      (hArg :
        PsKernelTypingJudgment
          environment localContext arg argType)
      (hArgType :
        PsKernelDefEqJudgment
          environment localContext argType domain) :
      PsKernelTypingJudgment
        environment
        localContext
        (PsKernelExpr.app fn arg)
        (psKernelExprInstantiate1 body arg)
  | lam
      {localContext : PsKernelLocalContext}
      (name fresh : PsKernelName)
      (domain body bodyType : PsKernelExpr)
      (binderInfo : PsKernelBinderInfo)
      (domainLevel : PsKernelLevel)
      (hFresh :
        psKernelLocalContextFind localContext fresh =
          Option.none)
      (hDomain :
        PsKernelTypingJudgment
          environment
          localContext
          domain
          (PsKernelExpr.sort domainLevel))
      (hBody :
        PsKernelTypingJudgment
          environment
          (psKernelLocalContextAddLocal
            localContext
            fresh
            name
            domain
            binderInfo)
          (psKernelExprInstantiate1
            body
            (PsKernelExpr.fvar fresh))
          bodyType) :
      PsKernelTypingJudgment
        environment
        localContext
        (PsKernelExpr.lam name domain body binderInfo)
        (PsKernelExpr.forallE
          name
          domain
          (psKernelExprAbstractFVars
            (psKernelExprCheapBetaReduce bodyType)
            (List.cons fresh List.nil))
          binderInfo)
  | forallE
      {localContext : PsKernelLocalContext}
      (name fresh : PsKernelName)
      (domain body : PsKernelExpr)
      (binderInfo : PsKernelBinderInfo)
      (domainLevel bodyLevel : PsKernelLevel)
      (hFresh :
        psKernelLocalContextFind localContext fresh =
          Option.none)
      (hDomain :
        PsKernelTypingJudgment
          environment
          localContext
          domain
          (PsKernelExpr.sort domainLevel))
      (hBody :
        PsKernelTypingJudgment
          environment
          (psKernelLocalContextAddLocal
            localContext
            fresh
            name
            domain
            binderInfo)
          (psKernelExprInstantiate1
            body
            (PsKernelExpr.fvar fresh))
          (PsKernelExpr.sort bodyLevel)) :
      PsKernelTypingJudgment
        environment
        localContext
        (PsKernelExpr.forallE name domain body binderInfo)
        (PsKernelExpr.sort
          (psKernelLevelMkIMax
            domainLevel
            bodyLevel))
  | letE
      {localContext : PsKernelLocalContext}
      (name fresh : PsKernelName)
      (type value body valueType bodyType : PsKernelExpr)
      (nondep : Bool)
      (typeLevel : PsKernelLevel)
      (hFresh :
        psKernelLocalContextFind localContext fresh =
          Option.none)
      (hType :
        PsKernelTypingJudgment
          environment
          localContext
          type
          (PsKernelExpr.sort typeLevel))
      (hValue :
        PsKernelTypingJudgment
          environment
          localContext
          value
          valueType)
      (hValueType :
        PsKernelDefEqJudgment
          environment
          localContext
          valueType
          type)
      (hBody :
        PsKernelTypingJudgment
          environment
          (psKernelLocalContextAddLet
            localContext
            fresh
            name
            type
            value)
          (psKernelExprInstantiate1
            body
            (PsKernelExpr.fvar fresh))
          bodyType) :
      PsKernelTypingJudgment
        environment
        localContext
        (PsKernelExpr.letE name type value body nondep)
        (let reducedBodyType :=
          psKernelExprCheapBetaReduce bodyType
         let closedBody :=
          psKernelExprAbstractFVars
            reducedBodyType
            (List.cons fresh List.nil)
         if
             psKernelExprHasLooseBVarAt
               closedBody
               0 then
           PsKernelExpr.letE
             name
             type
             value
             closedBody
             nondep
         else
           reducedBodyType)


  | mdata
      {localContext : PsKernelLocalContext}
      (metadata : Nat)
      (body bodyType : PsKernelExpr)
      (hBody :
        PsKernelTypingJudgment
          environment
          localContext
          body
          bodyType) :
      PsKernelTypingJudgment
        environment
        localContext
        (PsKernelExpr.mdata metadata body)
        bodyType


  | proj
      {localContext : PsKernelLocalContext}
      (typeName : PsKernelName)
      (index : Nat)
      (structValue structType result : PsKernelExpr)
      (hStruct :
        PsKernelTypingJudgment
          environment
          localContext
          structValue
          structType)
      (hProjection :
        PsKernelProjectionResultJudgment
          environment
          localContext
          typeName
          index
          structValue
          structType
          result) :
      PsKernelTypingJudgment
        environment
        localContext
        (PsKernelExpr.proj typeName index structValue)
        result

def PsKernelInferenceCacheSound
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (cache : PsKernelExprMap) : Prop :=
  ∀ (expr result : PsKernelExpr),
    psKernelExprMapGet cache expr = Option.some result ->
      PsKernelTypingJudgment
        environment
        localContext
        expr
        result


def PsKernelCheckerStateSemanticSound
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (state : PsKernelCheckerState) : Prop :=
  PsKernelInferenceCacheSound
      environment
      localContext
      state.inferOnly ∧
  PsKernelInferenceCacheSound
      environment
      localContext
      state.checkedInfer ∧
  PsKernelDefEqCacheSound
      environment
      localContext
      state.success

def PsKernelInferenceCacheInsertLaw : Prop :=
  ∀
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (cache : PsKernelExprMap)
    (expr result : PsKernelExpr),
    PsKernelInferenceCacheSound
        environment
        localContext
        cache ->
    PsKernelTypingJudgment
        environment
        localContext
        expr
        result ->
    PsKernelInferenceCacheSound
      environment
      localContext
      (psKernelExprMapInsert
        cache
        expr
        result)

def PsKernelDefEqCacheInsertLaw : Prop :=
  ∀
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (cache : PsKernelExprPairSet)
    (left right : PsKernelExpr),
    PsKernelDefEqCacheSound
        environment
        localContext
        cache ->
    PsKernelDefEqJudgment
        environment
        localContext
        left
        right ->
    PsKernelDefEqCacheSound
      environment
      localContext
      (psKernelExprPairSetInsert
        cache
        left
        right)


def PsKernelInferenceCoreSound
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState)) : Prop :=
  ∀
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr result : PsKernelExpr)
    (inferOnly : Bool),
    psKernelInferCoreWithFuel
        fuel whnf defeq
        context state expr inferOnly =
      Except.ok (Prod.mk result nextState) ->
    PsKernelTypingJudgment
      context.environment
      context.localContext
      expr
      result


def PsKernelWhnfSound
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState)) : Prop :=
  ∀
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr result : PsKernelExpr),
    whnf context state expr =
      Except.ok (Prod.mk result nextState) ->
    PsKernelReductionClosure
      context.environment
      context.localContext
      expr
      result

def PsKernelDefEqSound
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState)) : Prop :=
  ∀
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (left right : PsKernelExpr),
    defeq context state left right =
      Except.ok (Prod.mk true nextState) ->
    PsKernelDefEqJudgment
      context.environment
      context.localContext
      left
      right


def PsKernelInferenceSound
    (infer :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState)) : Prop :=
  ∀
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr result : PsKernelExpr),
    infer context state expr =
      Except.ok (Prod.mk result nextState) ->
    PsKernelTypingJudgment
      context.environment
      context.localContext
      expr
      result
