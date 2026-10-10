import Ps.KernelCore.Checker.Inference.Core
import Ps.KernelCore.Checker.Reduction.Whnf
import Ps.KernelCore.Checker.Recursor.Analysis
import Ps.KernelCore.Metatheory.Context

/-
Legacy operational Assurance Plane judgments for PSKernel Core.

SEMANTIC STATUS: these relations are not yet an adequate type theory.
JudgmentAdequacy.lean proves that proofIrrelevanceAlgorithmic makes DefEq
universal and, through convert, gives the legacy typing relation every type.
The executable checker does not follow from the converse of its refinement
lemmas. Existing refinement proofs remain operational evidence only; they
cannot establish semantic soundness or consistency. A semantic bridge must
retain well-typed-input evidence and the actual inferred-type connections.

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
  | stringLiteral
      (value : String) :
      PsKernelReductionStep
        environment
        localContext
        (PsKernelExpr.lit (PsKernelLiteral.str value))
        (psKernelStringLitToConstructor value)
  | projection
      (typeName ctorName : PsKernelName)
      (ctorLevels : List PsKernelLevel)
      (index : Nat)
      (structValue result : PsKernelExpr)
      (ctorInfo : PsKernelConstructorInfo)
      (hIndex :
        psKernelNatGt index psKernelLeanUInt32Max = false)
      (hFn :
        psKernelExprGetAppFn structValue =
          PsKernelExpr.const ctorName ctorLevels)
      (hFind :
        psKernelFindConstantInList
            ctorName
            environment.constants =
          Option.some
            (PsKernelConstantInfo.ctorInfo ctorInfo))
      (hInduct :
        psKernelNameEq ctorInfo.induct typeName = true)
      (hArg :
        psKernelExprListGet
            (psKernelExprGetAppArgs structValue)
            (Nat.add ctorInfo.numParams index) =
          Option.some result) :
      PsKernelReductionStep
        environment
        localContext
        (PsKernelExpr.proj typeName index structValue)
        result
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


  | deltaSpine
      (expr : PsKernelExpr)
      (name : PsKernelName)
      (levels : List PsKernelLevel)
      (info : PsKernelConstantInfo)
      (value : PsKernelExpr)
      (hFn :
        psKernelExprGetAppFn expr =
          PsKernelExpr.const name levels)
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
        expr
        (psKernelApplyArgs
          (psKernelExprInstantiateLevelParams
            value
            (psKernelConstantInfoLevelParams info)
            levels)
          (psKernelExprGetAppArgs expr))

  | natZeroLiteral
      (name : PsKernelName)
      (hName :
        psKernelNameEq name psKernelNatZeroName = true) :
      PsKernelReductionStep
        environment
        localContext
        (PsKernelExpr.const name List.nil)
        (PsKernelExpr.lit
          (PsKernelLiteral.nat 0))

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
  | natPow
      (op : PsKernelName)
      (left right : Nat)
      (hOp :
        psKernelNameEq op psKernelNatPowName = true) :
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
            (psKernelNatPow left right)))
  | natPowZero
      (op : PsKernelName)
      (left right : Nat)
      (hOp :
        psKernelNameEq op psKernelNatPowName = true)
      (hZero :
        right = 0) :
      PsKernelReductionStep
        environment
        localContext
        (PsKernelExpr.app
          (PsKernelExpr.app
            (PsKernelExpr.const op List.nil)
            (PsKernelExpr.lit (PsKernelLiteral.nat left)))
          (PsKernelExpr.lit (PsKernelLiteral.nat right)))
        (PsKernelExpr.lit
          (PsKernelLiteral.nat 1))
  | natGcd
      (op : PsKernelName)
      (left right : Nat)
      (hOp :
        psKernelNameEq op psKernelNatGcdName = true) :
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
            (psKernelNatGcd left right)))
  | natLand
      (op : PsKernelName)
      (left right : Nat)
      (hOp :
        psKernelNameEq op psKernelNatLandName = true) :
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
            (psKernelNatBitwise
              PsKernelNatBitwiseOp.land
              left
              right)))
  | natLor
      (op : PsKernelName)
      (left right : Nat)
      (hOp :
        psKernelNameEq op psKernelNatLorName = true) :
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
            (psKernelNatBitwise
              PsKernelNatBitwiseOp.lor
              left
              right)))
  | natXor
      (op : PsKernelName)
      (left right : Nat)
      (hOp :
        psKernelNameEq op psKernelNatXorName = true) :
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
            (psKernelNatBitwise
              PsKernelNatBitwiseOp.xor
              left
              right)))
  | natShiftLeft
      (op : PsKernelName)
      (left right : Nat)
      (hOp :
        psKernelNameEq op psKernelNatShiftLeftName = true) :
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
            (psKernelNatShiftLeft left right)))
  | natShiftLeftZero
      (op : PsKernelName)
      (left right : Nat)
      (hOp :
        psKernelNameEq op psKernelNatShiftLeftName = true)
      (hZero :
        left = 0) :
      PsKernelReductionStep
        environment
        localContext
        (PsKernelExpr.app
          (PsKernelExpr.app
            (PsKernelExpr.const op List.nil)
            (PsKernelExpr.lit (PsKernelLiteral.nat left)))
          (PsKernelExpr.lit (PsKernelLiteral.nat right)))
        (PsKernelExpr.lit
          (PsKernelLiteral.nat 0))
  | natShiftRight
      (op : PsKernelName)
      (left right : Nat)
      (hOp :
        psKernelNameEq op psKernelNatShiftRightName = true) :
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
            (psKernelNatShiftRight left right)))

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


/-
Independent representation of a Nat successor recognized by the algorithmic
DefEq predecessor shortcut.  It accepts either the canonical literal form or
an unapplied-universe Nat.succ constructor with exactly one argument.  It never
uses the executable psKernelExprNatPred recognizer as a semantic premise.
-/
inductive PsKernelNatSuccessorRep :
    PsKernelExpr -> PsKernelExpr -> Prop
  | literal (predecessor : Nat) :
      PsKernelNatSuccessorRep
        (PsKernelExpr.lit (PsKernelLiteral.nat (Nat.succ predecessor)))
        (PsKernelExpr.lit (PsKernelLiteral.nat predecessor))
  | constructor
      (expr predecessor : PsKernelExpr)
      (name : PsKernelName)
      (hHead :
        psKernelExprGetAppFn expr =
          PsKernelExpr.const name List.nil)
      (hName :
        psKernelNameEq name psKernelNatSuccName = true)
      (hArgs :
        psKernelExprGetAppArgs expr =
          List.cons predecessor List.nil) :
      PsKernelNatSuccessorRep expr predecessor


inductive PsKernelRecursorMajorNormalization :
    PsKernelExpr -> PsKernelExpr -> Prop
  | identity
      (expr : PsKernelExpr) :
      PsKernelRecursorMajorNormalization expr expr
  | natZero :
      PsKernelRecursorMajorNormalization
        (PsKernelExpr.lit (PsKernelLiteral.nat 0))
        (PsKernelExpr.const psKernelNatZeroName List.nil)
  | natSucc
      (predecessor : Nat) :
      PsKernelRecursorMajorNormalization
        (PsKernelExpr.lit
          (PsKernelLiteral.nat (Nat.succ predecessor)))
        (PsKernelExpr.app
          (PsKernelExpr.const psKernelNatSuccName List.nil)
          (PsKernelExpr.lit
            (PsKernelLiteral.nat predecessor)))



/--
Independent field spine used by the structure-eta conversion rule.

This relation is intentionally structural: it specifies the sequence of
projections without referring to the executable fuel worker used by
`psKernelToConstructorWhenStructure`.
-/
inductive PsKernelStructureEtaFields
    (inductName : PsKernelName)
    (value : PsKernelExpr) :
    Nat -> Nat -> List PsKernelExpr -> Prop
  | done
      (index fieldCount : Nat)
      (hDone : psKernelNatLt index fieldCount = false) :
      PsKernelStructureEtaFields
        inductName value index fieldCount List.nil
  | step
      (index fieldCount : Nat)
      (rest : List PsKernelExpr)
      (hMore : psKernelNatLt index fieldCount = true)
      (hRest :
        PsKernelStructureEtaFields
          inductName
          value
          (Nat.succ index)
          fieldCount
          rest) :
      PsKernelStructureEtaFields
        inductName
        value
        index
        fieldCount
        (List.cons
          (PsKernelExpr.proj inductName index value)
          rest)


mutual
inductive PsKernelReductionClosure
    (environment : PsKernelEnvironment) :
    PsKernelLocalContext -> PsKernelExpr -> PsKernelExpr -> Prop
  | refl
      {localContext : PsKernelLocalContext}
      (expr : PsKernelExpr) :
      PsKernelReductionClosure
        environment
        localContext
        expr
        expr
  | contextWeaken
      {older newer : PsKernelLocalContext}
      (left right : PsKernelExpr)
      (hExt :
        PsKernelLocalContextExtends older newer)
      (hReduction :
        PsKernelReductionClosure
          environment older left right) :
      PsKernelReductionClosure
        environment newer left right
  | presentationSource
      {localContext : PsKernelLocalContext}
      (source query result : PsKernelExpr)
      (hPresentation :
        PsKernelStructuralExprEq source query)
      (hReduction :
        PsKernelReductionClosure
          environment
          localContext
          source
          result) :
      PsKernelReductionClosure
        environment
        localContext
        query
        result
  | cons
      {localContext : PsKernelLocalContext}
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
  | trans
      {localContext : PsKernelLocalContext}
      (left middle right : PsKernelExpr)
      (hLeft :
        PsKernelReductionClosure
          environment localContext left middle)
      (hRight :
        PsKernelReductionClosure
          environment localContext middle right) :
      PsKernelReductionClosure
        environment localContext left right
  | appFn
      {localContext : PsKernelLocalContext}
      (leftFn rightFn arg : PsKernelExpr)
      (hFn :
        PsKernelReductionClosure
          environment localContext leftFn rightFn) :
      PsKernelReductionClosure
        environment
        localContext
        (PsKernelExpr.app leftFn arg)
        (PsKernelExpr.app rightFn arg)
  | appArg
      {localContext : PsKernelLocalContext}
      (fn leftArg rightArg : PsKernelExpr)
      (hArg :
        PsKernelReductionClosure
          environment localContext leftArg rightArg) :
      PsKernelReductionClosure
        environment
        localContext
        (PsKernelExpr.app fn leftArg)
        (PsKernelExpr.app fn rightArg)
  | projectionMajor
      {localContext : PsKernelLocalContext}
      (typeName : PsKernelName)
      (index : Nat)
      (left right : PsKernelExpr)
      (hMajor :
        PsKernelReductionClosure
          environment localContext left right) :
      PsKernelReductionClosure
        environment
        localContext
        (PsKernelExpr.proj typeName index left)
        (PsKernelExpr.proj typeName index right)
  | quotLift
      {localContext : PsKernelLocalContext}
      (expr : PsKernelExpr)
      (fnName mkName : PsKernelName)
      (levels mkLevels : List PsKernelLevel)
      (args mkArgs : List PsKernelExpr)
      (major majorReduced representative fnValue : PsKernelExpr)
      (hInitialized :
        environment.quotInitialized = true)
      (hHead :
        psKernelExprGetAppFn expr =
          PsKernelExpr.const fnName levels)
      (hLift :
        psKernelNameEq fnName psKernelQuotLiftName = true)
      (hArgs :
        psKernelExprGetAppArgs expr = args)
      (hMajor :
        psKernelExprListGet args 5 =
          Option.some major)
      (hMajorReduction :
        PsKernelReductionClosure
          environment localContext major majorReduced)
      (hMkHead :
        psKernelExprGetAppFn majorReduced =
          PsKernelExpr.const mkName mkLevels)
      (hMk :
        psKernelNameEq mkName psKernelQuotMkName = true)
      (hMkArity :
        Nat.beq
            (psKernelExprGetAppNumArgs majorReduced)
            3 =
          true)
      (hMkArgs :
        psKernelExprGetAppArgs majorReduced = mkArgs)
      (hRepresentative :
        psKernelExprListGet mkArgs 2 =
          Option.some representative)
      (hFnValue :
        psKernelExprListGet args 3 =
          Option.some fnValue) :
      PsKernelReductionClosure
        environment
        localContext
        expr
        (psKernelApplyArgs
          (PsKernelExpr.app fnValue representative)
          (psKernelExprListDrop 6 args))
  | quotInd
      {localContext : PsKernelLocalContext}
      (expr : PsKernelExpr)
      (fnName mkName : PsKernelName)
      (levels mkLevels : List PsKernelLevel)
      (args mkArgs : List PsKernelExpr)
      (major majorReduced representative fnValue : PsKernelExpr)
      (hInitialized :
        environment.quotInitialized = true)
      (hHead :
        psKernelExprGetAppFn expr =
          PsKernelExpr.const fnName levels)
      (hInd :
        psKernelNameEq fnName psKernelQuotIndName = true)
      (hArgs :
        psKernelExprGetAppArgs expr = args)
      (hMajor :
        psKernelExprListGet args 4 =
          Option.some major)
      (hMajorReduction :
        PsKernelReductionClosure
          environment localContext major majorReduced)
      (hMkHead :
        psKernelExprGetAppFn majorReduced =
          PsKernelExpr.const mkName mkLevels)
      (hMk :
        psKernelNameEq mkName psKernelQuotMkName = true)
      (hMkArity :
        Nat.beq
            (psKernelExprGetAppNumArgs majorReduced)
            3 =
          true)
      (hMkArgs :
        psKernelExprGetAppArgs majorReduced = mkArgs)
      (hRepresentative :
        psKernelExprListGet mkArgs 2 =
          Option.some representative)
      (hFnValue :
        psKernelExprListGet args 3 =
          Option.some fnValue) :
      PsKernelReductionClosure
        environment
        localContext
        expr
        (psKernelApplyArgs
          (PsKernelExpr.app fnValue representative)
          (psKernelExprListDrop 5 args))
  | recursorIota
      {localContext : PsKernelLocalContext}
      (expr : PsKernelExpr)
      (recName ctorName : PsKernelName)
      (recLevels ctorLevels : List PsKernelLevel)
      (recArgs majorArgs : List PsKernelExpr)
      (recursor : PsKernelRecursorInfo)
      (rule : PsKernelRecursorRule)
      (major0 majorK majorReduced semanticReduced major : PsKernelExpr)
      (hHead :
        Prod.fst (psKernelExprGetAppFnArgs expr) =
          PsKernelExpr.const recName recLevels)
      (hArgs :
        Prod.snd (psKernelExprGetAppFnArgs expr) =
          recArgs)
      (hFind :
        psKernelFindConstantInList
            recName
            environment.constants =
          Option.some
            (PsKernelConstantInfo.recInfo recursor))
      (hMajor :
        psKernelExprListGet
            recArgs
            (Nat.add
              recursor.numParams
              (Nat.add
                recursor.numMotives
                (Nat.add
                  recursor.numMinors
                  recursor.numIndices))) =
          Option.some major0)
      (hKConversion :
        PsKernelDefEqJudgment
          environment localContext major0 majorK)
      (hMajorReduction :
        PsKernelReductionClosure
          environment localContext majorK majorReduced)
      (hNormalizeConversion :
        PsKernelDefEqJudgment
          environment localContext majorReduced semanticReduced)
      (hNormalize :
        PsKernelRecursorMajorNormalization
          semanticReduced major)
      (hCtorHead :
        Prod.fst (psKernelExprGetAppFnArgs major) =
          PsKernelExpr.const ctorName ctorLevels)
      (hMajorArgs :
        Prod.snd (psKernelExprGetAppFnArgs major) =
          majorArgs)
      (hRuleMem :
        rule ∈ recursor.rules)
      (hRuleCtor :
        psKernelNameEq rule.ctor ctorName = true)
      (hFields :
        psKernelNatGt
            rule.nFields
            (psKernelExprListLength majorArgs) =
          false)
      (hLevels :
        Nat.beq
            (psKernelLevelListLength recLevels)
            (psKernelNameListLength
              recursor.base.levelParams) =
          true) :
      PsKernelReductionClosure
        environment
        localContext
        expr
        (psKernelApplyArgs
          (psKernelApplyArgs
            (psKernelApplyArgs
              (psKernelExprInstantiateLevelParams
                rule.rhs
                recursor.base.levelParams
                recLevels)
              (psKernelExprListTake
                (Nat.add
                  recursor.numParams
                  (Nat.add
                    recursor.numMotives
                    recursor.numMinors))
                recArgs))
            (psKernelExprListTake
              rule.nFields
              (psKernelExprListDrop
                (Nat.sub
                  (psKernelExprListLength majorArgs)
                  rule.nFields)
                majorArgs)))
          (psKernelExprListDrop
            (Nat.succ
              (Nat.add
                recursor.numParams
                (Nat.add
                  recursor.numMotives
                  (Nat.add
                    recursor.numMinors
                    recursor.numIndices))))
            recArgs))

inductive PsKernelDefEqJudgment
    (environment : PsKernelEnvironment) :
    PsKernelLocalContext -> PsKernelExpr -> PsKernelExpr -> Prop
  | refl
      {localContext : PsKernelLocalContext}
      (expr : PsKernelExpr) :
      PsKernelDefEqJudgment
        environment
        localContext
        expr
        expr
  | contextWeaken
      {older newer : PsKernelLocalContext}
      (left right : PsKernelExpr)
      (hExt :
        PsKernelLocalContextExtends older newer)
      (hDefEq :
        PsKernelDefEqJudgment
          environment older left right) :
      PsKernelDefEqJudgment
        environment newer left right
  | symm
      {localContext : PsKernelLocalContext}
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
  | presentation
      {localContext : PsKernelLocalContext}
      (storedLeft storedRight queryLeft queryRight : PsKernelExpr)
      (hLeft :
        PsKernelStructuralExprEq
          storedLeft
          queryLeft)
      (hStored :
        PsKernelDefEqJudgment
          environment
          localContext
          storedLeft
          storedRight)
      (hRight :
        PsKernelStructuralExprEq
          storedRight
          queryRight) :
      PsKernelDefEqJudgment
        environment
        localContext
        queryLeft
        queryRight
  | structural
      {localContext : PsKernelLocalContext}
      (left right : PsKernelExpr)
      (h : PsKernelStructuralExprEq left right) :
      PsKernelDefEqJudgment
        environment
        localContext
        left
        right
  | reduction
      {localContext : PsKernelLocalContext}
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
  | reductionClosure
      {localContext : PsKernelLocalContext}
      (left right : PsKernelExpr)
      (h :
        PsKernelReductionClosure
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
      {localContext : PsKernelLocalContext}
      (left right : PsKernelLevel)
      (h :
        psKernelLevelEquivalent left right = true) :
      PsKernelDefEqJudgment
        environment
        localContext
        (PsKernelExpr.sort left)
        (PsKernelExpr.sort right)
  | literal
      {localContext : PsKernelLocalContext}
      (left right : PsKernelLiteral)
      (h :
        psKernelLiteralEq left right = true) :
      PsKernelDefEqJudgment
        environment
        localContext
        (PsKernelExpr.lit left)
        (PsKernelExpr.lit right)
  | app
      {localContext : PsKernelLocalContext}
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
  | constLevels
      {localContext : PsKernelLocalContext}
      (name : PsKernelName)
      (leftLevels rightLevels : List PsKernelLevel)
      (hLevels :
        List.map psKernelLevelNormalize leftLevels =
          List.map psKernelLevelNormalize rightLevels) :
      PsKernelDefEqJudgment
        environment
        localContext
        (PsKernelExpr.const name leftLevels)
        (PsKernelExpr.const name rightLevels)
  | natSuccessorPred
      {localContext : PsKernelLocalContext}
      (left right leftPred rightPred : PsKernelExpr)
      (hLeft :
        PsKernelNatSuccessorRep left leftPred)
      (hRight :
        PsKernelNatSuccessorRep right rightPred)
      (hPred :
        PsKernelDefEqJudgment
          environment
          localContext
          leftPred
          rightPred) :
      PsKernelDefEqJudgment
        environment
        localContext
        left
        right
  | projection
      {localContext : PsKernelLocalContext}
      (typeName : PsKernelName)
      (index : Nat)
      (left right : PsKernelExpr)
      (hMajor :
        PsKernelDefEqJudgment
          environment localContext left right) :
      PsKernelDefEqJudgment
        environment
        localContext
        (PsKernelExpr.proj typeName index left)
        (PsKernelExpr.proj typeName index right)
  /-
  Algorithmic comparison after one or both sides have been reduced.

  This is deliberately not a general transitivity constructor: both outer
  links must be executable reduction closures, matching Lean's WHNF/lazy-delta
  comparison phases.
  -/
  | reduceCompare
      {localContext : PsKernelLocalContext}
      (left right leftReduced rightReduced : PsKernelExpr)
      (hLeft :
        PsKernelReductionClosure
          environment localContext left leftReduced)
      (hRight :
        PsKernelReductionClosure
          environment localContext right rightReduced)
      (hCore :
        PsKernelDefEqJudgment
          environment localContext leftReduced rightReduced) :
      PsKernelDefEqJudgment
        environment
        localContext
        left
        right
  | functionEtaLeft
      {localContext : PsKernelLocalContext}
      (lambdaValue other : PsKernelExpr)
      (name : PsKernelName)
      (domain body : PsKernelExpr)
      (binderInfo : PsKernelBinderInfo)
      (hCompare :
        PsKernelDefEqJudgment
          environment
          localContext
          lambdaValue
          (PsKernelExpr.lam
            name
            domain
            (PsKernelExpr.app other (PsKernelExpr.bvar 0))
            binderInfo)) :
      PsKernelDefEqJudgment
        environment
        localContext
        lambdaValue
        other
  | functionEtaRight
      {localContext : PsKernelLocalContext}
      (other lambdaValue : PsKernelExpr)
      (name : PsKernelName)
      (domain body : PsKernelExpr)
      (binderInfo : PsKernelBinderInfo)
      (hCompare :
        PsKernelDefEqJudgment
          environment
          localContext
          (PsKernelExpr.lam
            name
            domain
            (PsKernelExpr.app other (PsKernelExpr.bvar 0))
            binderInfo)
          lambdaValue) :
      PsKernelDefEqJudgment
        environment
        localContext
        other
        lambdaValue
  /-
  Algorithmic proof-irrelevance view.

  The concrete checker already has `leftType` as the inferred type candidate
  for the left term.  To classify that candidate as a proposition it infers
  the type of `leftType` itself, then WHNF-reduces that second-order type to
  a sort whose level normalizes to zero.  This rule records that executable
  classification shape without pretending that `leftType` itself reduces
  to `Sort 0`.  The stronger `proofIrrelevance` rule below additionally
  carries full typing derivations and is the target of the checked-input
  refinement layer.
  -/
  | proofIrrelevanceAlgorithmic
      {localContext : PsKernelLocalContext}
      (left right leftType rightType leftTypeType : PsKernelExpr)
      (level : PsKernelLevel)
      (hLeftTypeTypeProp :
        PsKernelReductionClosure
          environment
          localContext
          leftTypeType
          (PsKernelExpr.sort level))
      (hProp :
        psKernelLevelNormalizesToZero level = true)
      (hTypes :
        PsKernelDefEqJudgment
          environment
          localContext
          leftType
          rightType) :
      PsKernelDefEqJudgment
        environment
        localContext
        left
        right
  /-
  Unit-like non-recursive structures form an algorithmic singleton rule.
  The checked-input refinement can later strengthen this to typed structure
  eta/proof-irrelevance evidence.
  -/
  | unitLike
      {localContext : PsKernelLocalContext}
      (left right leftType rightType reducedType : PsKernelExpr)
      (inductName ctorName : PsKernelName)
      (inductInfo : PsKernelInductiveInfo)
      (ctorInfo : PsKernelConstructorInfo)
      (hTypeReduction :
        PsKernelReductionClosure
          environment
          localContext
          leftType
          reducedType)
      (hTypeHead :
        psKernelExprGetAppFn reducedType =
          PsKernelExpr.const inductName
            (match psKernelExprGetAppFn reducedType with
             | PsKernelExpr.const _ levels => levels
             | _ => List.nil))
      (hNonRec :
        psKernelEnvironmentIsNonRecStructure
            environment inductName =
          true)
      (hInduct :
        psKernelFindConstantInList
            inductName
            environment.constants =
          Option.some
            (PsKernelConstantInfo.inductInfo inductInfo))
      (hCtors :
        inductInfo.ctors = List.cons ctorName List.nil)
      (hCtor :
        psKernelFindConstantInList
            ctorName
            environment.constants =
          Option.some
            (PsKernelConstantInfo.ctorInfo ctorInfo))
      (hNoFields : ctorInfo.numFields = 0)
      (hTypes :
        PsKernelDefEqJudgment
          environment
          localContext
          reducedType
          rightType) :
      PsKernelDefEqJudgment
        environment
        localContext
        left
        right

  /-
  Algorithmic non-recursive structure-eta comparison used by DefEq.

  Unlike the recursor structure-eta rule, this path compares an already
  constructor-shaped value against projections from the other term.  It keeps
  the field-by-field recursive DefEq evidence explicit, avoiding any appeal to
  general DefEq transitivity.
  -/
  | structureEtaAlgorithmic
      {localContext : PsKernelLocalContext}
      (term structureValue termType structureType : PsKernelExpr)
      (ctorName : PsKernelName)
      (levels : List PsKernelLevel)
      (ctorInfo : PsKernelConstructorInfo)
      (hHead :
        psKernelExprGetAppFn structureValue =
          PsKernelExpr.const ctorName levels)
      (hCtor :
        psKernelFindConstantInList
            ctorName
            environment.constants =
          Option.some
            (PsKernelConstantInfo.ctorInfo ctorInfo))
      (hArity :
        Nat.beq
            (psKernelExprListLength
              (psKernelExprGetAppArgs structureValue))
            (Nat.add ctorInfo.numParams ctorInfo.numFields) =
          true)
      (hNonRec :
        psKernelEnvironmentIsNonRecStructure
            environment
            ctorInfo.induct =
          true)
      (hTypes :
        PsKernelDefEqJudgment
          environment
          localContext
          termType
          structureType)
      (hFields :
        PsKernelStructureEtaCompareJudgment
          environment
          localContext
          ctorInfo.induct
          term
          (psKernelExprGetAppArgs structureValue)
          ctorInfo.numParams
          0) :
      PsKernelDefEqJudgment
        environment
        localContext
        term
        structureValue

  | lambdaSpine
      {localContext : PsKernelLocalContext}
      (left right : PsKernelExpr)
      (h :
        PsKernelLambdaSpineJudgment
          environment
          localContext
          left
          right
          List.nil) :
      PsKernelDefEqJudgment
        environment
        localContext
        left
        right
  | forallSpine
      {localContext : PsKernelLocalContext}
      (left right : PsKernelExpr)
      (h :
        PsKernelForallSpineJudgment
          environment
          localContext
          left
          right
          List.nil) :
      PsKernelDefEqJudgment
        environment
        localContext
        left
        right
  /-
  Algorithmic K conversion used by recursor WHNF.

  This rule records the independent control/metadata facts needed by the K
  path without claiming that infer-only itself is a typing certificate.
  The checked-soundness layer may refine this rule to `proofIrrelevance`
  once admitted-recursors and checked inputs provide full typing evidence.
  -/
  | recursorKConversion
      {localContext : PsKernelLocalContext}
      (recursor : PsKernelRecursorInfo)
      (major appType candidate candidateType : PsKernelExpr)
      (majorInduct typeInduct ctorName : PsKernelName)
      (typeLevels : List PsKernelLevel)
      (indices params : List PsKernelExpr)
      (inductInfo : PsKernelInductiveInfo)
      (ctorRest : List PsKernelName)
      (hK : recursor.k = true)
      (hMajorInduct :
        psKernelRecursorMajorInduct recursor =
          Option.some majorInduct)
      (hTypeHead :
        psKernelExprGetAppFn appType =
          PsKernelExpr.const typeInduct typeLevels)
      (hTypeInduct :
        psKernelNameEq typeInduct majorInduct = true)
      (hIndices :
        indices =
          psKernelExprListDrop
            recursor.numParams
            (psKernelExprGetAppArgs appType))
      (hNoUnresolvedIndex :
        (if psKernelExprHasMVarForK appType then
           psKernelExprListAnyMVar indices
         else
           false) =
          false)
      (hInduct :
        psKernelFindConstantInList
            typeInduct
            environment.constants =
          Option.some
            (PsKernelConstantInfo.inductInfo inductInfo))
      (hCtors :
        inductInfo.ctors =
          List.cons ctorName ctorRest)
      (hParams :
        params =
          psKernelExprListTake
            recursor.numParams
            (psKernelExprGetAppArgs appType))
      (hParamCount :
        Nat.beq
            (psKernelExprListLength params)
            recursor.numParams =
          true)
      (hCandidate :
        candidate =
          psKernelApplyArgs
            (PsKernelExpr.const ctorName typeLevels)
            params)
      (hTypeDefEq :
        PsKernelDefEqJudgment
          environment
          localContext
          appType
          candidateType) :
      PsKernelDefEqJudgment
        environment
        localContext
        major
        candidate

  /-
  Algorithmic non-recursive structure eta conversion used by recursor WHNF.

  The rule is driven by authoritative inductive/constructor metadata plus an
  independent projection-field spine.  It is intentionally separate from the
  stronger typed `structureEta` rule below.
  -/
  | recursorStructureEta
      {localContext : PsKernelLocalContext}
      (major majorType etaValue : PsKernelExpr)
      (inductName typeName ctorName : PsKernelName)
      (levels : List PsKernelLevel)
      (typeArgs params fields : List PsKernelExpr)
      (inductInfo : PsKernelInductiveInfo)
      (ctorInfo : PsKernelConstructorInfo)
      (hNonRecStructure :
        psKernelEnvironmentIsNonRecStructure
            environment
            inductName =
          true)
      (hTypeHead :
        psKernelExprGetAppFn majorType =
          PsKernelExpr.const typeName levels)
      (hTypeName :
        psKernelNameEq typeName inductName = true)
      (hTypeArgs :
        psKernelExprGetAppArgs majorType = typeArgs)
      (hInduct :
        psKernelFindConstantInList
            inductName
            environment.constants =
          Option.some
            (PsKernelConstantInfo.inductInfo inductInfo))
      (hCtors :
        inductInfo.ctors =
          List.cons ctorName List.nil)
      (hCtor :
        psKernelFindConstantInList
            ctorName
            environment.constants =
          Option.some
            (PsKernelConstantInfo.ctorInfo ctorInfo))
      (hParamBound :
        Nat.ble
            ctorInfo.numParams
            (psKernelExprListLength typeArgs) =
          true)
      (hParams :
        params =
          psKernelExprListTake
            ctorInfo.numParams
            typeArgs)
      (hFields :
        PsKernelStructureEtaFields
          inductName
          major
          0
          ctorInfo.numFields
          fields)
      (hEta :
        etaValue =
          psKernelApplyArgs
            (PsKernelExpr.const ctorName levels)
            (psKernelExprListAppend params fields)) :
      PsKernelDefEqJudgment
        environment
        localContext
        major
        etaValue

  | proofIrrelevance
      {localContext : PsKernelLocalContext}
      (left right leftType rightType : PsKernelExpr)
      (level : PsKernelLevel)
      (hLeft :
        PsKernelTypingJudgment
          environment localContext left leftType)
      (hRight :
        PsKernelTypingJudgment
          environment localContext right rightType)
      (hLeftType :
        PsKernelTypingJudgment
          environment
          localContext
          leftType
          (PsKernelExpr.sort level))
      (hProp :
        psKernelLevelNormalizesToZero level = true)
      (hTypes :
        PsKernelDefEqJudgment
          environment localContext leftType rightType) :
      PsKernelDefEqJudgment
        environment
        localContext
        left
        right
  | structureEta
      {localContext : PsKernelLocalContext}
      (value valueType etaValue : PsKernelExpr)
      (inductName ctorName : PsKernelName)
      (levels : List PsKernelLevel)
      (typeArgs params fields : List PsKernelExpr)
      (inductInfo : PsKernelInductiveInfo)
      (ctorInfo : PsKernelConstructorInfo)
      (hValue :
        PsKernelTypingJudgment
          environment localContext value valueType)
      (hTypeHead :
        psKernelExprGetAppFn valueType =
          PsKernelExpr.const inductName levels)
      (hTypeArgs :
        psKernelExprGetAppArgs valueType = typeArgs)
      (hInduct :
        psKernelFindConstantInList
            inductName
            environment.constants =
          Option.some
            (PsKernelConstantInfo.inductInfo inductInfo))
      (hNonRec : inductInfo.isRec = false)
      (hNoIndices : inductInfo.numIndices = 0)
      (hCtors : inductInfo.ctors = List.cons ctorName List.nil)
      (hCtor :
        psKernelFindConstantInList
            ctorName
            environment.constants =
          Option.some
            (PsKernelConstantInfo.ctorInfo ctorInfo))
      (hCtorInduct :
        psKernelNameEq ctorInfo.induct inductName = true)
      (hParams :
        params = List.take ctorInfo.numParams typeArgs)
      (hFields :
        PsKernelStructureEtaFields
          inductName value 0 ctorInfo.numFields fields)
      (hEta :
        etaValue =
          psKernelApplyArgs
            (PsKernelExpr.const ctorName levels)
            (List.append params fields)) :
      PsKernelDefEqJudgment
        environment
        localContext
        value
        etaValue
  | metadataLeft
      {localContext : PsKernelLocalContext}
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
      {localContext : PsKernelLocalContext}
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

inductive PsKernelStructureEtaCompareJudgment
    (environment : PsKernelEnvironment) :
    PsKernelLocalContext ->
    PsKernelName ->
    PsKernelExpr ->
    List PsKernelExpr ->
    Nat ->
    Nat ->
    Prop
  | done
      {localContext : PsKernelLocalContext}
      (induct : PsKernelName)
      (term : PsKernelExpr)
      (args : List PsKernelExpr)
      (numParams index : Nat)
      (hDone :
        psKernelNatLt
            index
            (Nat.sub
              (psKernelExprListLength args)
              numParams) =
          false) :
      PsKernelStructureEtaCompareJudgment
        environment
        localContext
        induct
        term
        args
        numParams
        index
  | step
      {localContext : PsKernelLocalContext}
      (induct : PsKernelName)
      (term : PsKernelExpr)
      (args : List PsKernelExpr)
      (numParams index : Nat)
      (arg : PsKernelExpr)
      (hMore :
        psKernelNatLt
            index
            (Nat.sub
              (psKernelExprListLength args)
              numParams) =
          true)
      (hArg :
        psKernelExprListGet
            args
            (Nat.add numParams index) =
          Option.some arg)
      (hField :
        PsKernelDefEqJudgment
          environment
          localContext
          (PsKernelExpr.proj induct index term)
          arg)
      (hRest :
        PsKernelStructureEtaCompareJudgment
          environment
          localContext
          induct
          term
          args
          numParams
          (Nat.succ index)) :
      PsKernelStructureEtaCompareJudgment
        environment
        localContext
        induct
        term
        args
        numParams
        index

inductive PsKernelBinderDomainJudgment
    (environment : PsKernelEnvironment) :
    PsKernelLocalContext ->
    PsKernelExpr ->
    PsKernelExpr ->
    List PsKernelExpr ->
    Prop
  | structural
      {localContext : PsKernelLocalContext}
      (leftDomain rightDomain : PsKernelExpr)
      (subst : List PsKernelExpr)
      (hEq :
        psKernelExprEq leftDomain rightDomain = true) :
      PsKernelBinderDomainJudgment
        environment
        localContext
        leftDomain
        rightDomain
        subst
  | defeq
      {localContext : PsKernelLocalContext}
      (leftDomain rightDomain : PsKernelExpr)
      (subst : List PsKernelExpr)
      (hDefEq :
        PsKernelDefEqJudgment
          environment
          localContext
          (psKernelExprInstantiateRev leftDomain subst)
          (psKernelExprInstantiateRev rightDomain subst)) :
      PsKernelBinderDomainJudgment
        environment
        localContext
        leftDomain
        rightDomain
        subst

inductive PsKernelLambdaSpineJudgment
    (environment : PsKernelEnvironment) :
    PsKernelLocalContext ->
    PsKernelExpr ->
    PsKernelExpr ->
    List PsKernelExpr ->
    Prop
  | terminal
      {localContext : PsKernelLocalContext}
      (left right : PsKernelExpr)
      (subst : List PsKernelExpr)
      (hCore :
        PsKernelDefEqJudgment
          environment
          localContext
          (psKernelExprInstantiateRev left subst)
          (psKernelExprInstantiateRev right subst)) :
      PsKernelLambdaSpineJudgment
        environment
        localContext
        left
        right
        subst
  | stepOpen
      {localContext : PsKernelLocalContext}
      (leftName rightName fresh : PsKernelName)
      (leftDomain rightDomain leftBody rightBody : PsKernelExpr)
      (leftInfo rightInfo : PsKernelBinderInfo)
      (subst : List PsKernelExpr)
      (hDomain :
        PsKernelBinderDomainJudgment
          environment
          localContext
          leftDomain
          rightDomain
          subst)
      (hDependent :
        (if psKernelExprHasLooseBVar leftBody then
           true
         else
           psKernelExprHasLooseBVar rightBody) =
          true)
      (hFresh :
        psKernelLocalContextFind localContext fresh =
          Option.none)
      (hRest :
        PsKernelLambdaSpineJudgment
          environment
          (psKernelLocalContextAddLocal
            localContext
            fresh
            rightName
            (psKernelExprInstantiateRev rightDomain subst)
            rightInfo)
          leftBody
          rightBody
          (psKernelExprListAppend
            subst
            (List.cons
              (PsKernelExpr.fvar fresh)
              List.nil))) :
      PsKernelLambdaSpineJudgment
        environment
        localContext
        (PsKernelExpr.lam
          leftName leftDomain leftBody leftInfo)
        (PsKernelExpr.lam
          rightName rightDomain rightBody rightInfo)
        subst
  | stepClosed
      {localContext : PsKernelLocalContext}
      (leftName rightName : PsKernelName)
      (leftDomain rightDomain leftBody rightBody : PsKernelExpr)
      (leftInfo rightInfo : PsKernelBinderInfo)
      (subst : List PsKernelExpr)
      (hDomain :
        PsKernelBinderDomainJudgment
          environment
          localContext
          leftDomain
          rightDomain
          subst)
      (hLeftClosed :
        psKernelExprHasLooseBVar leftBody = false)
      (hRightClosed :
        psKernelExprHasLooseBVar rightBody = false)
      (hRest :
        PsKernelLambdaSpineJudgment
          environment
          localContext
          leftBody
          rightBody
          (psKernelExprListAppend
            subst
            (List.cons
              (PsKernelExpr.sort PsKernelLevel.zero)
              List.nil))) :
      PsKernelLambdaSpineJudgment
        environment
        localContext
        (PsKernelExpr.lam
          leftName leftDomain leftBody leftInfo)
        (PsKernelExpr.lam
          rightName rightDomain rightBody rightInfo)
        subst

inductive PsKernelForallSpineJudgment
    (environment : PsKernelEnvironment) :
    PsKernelLocalContext ->
    PsKernelExpr ->
    PsKernelExpr ->
    List PsKernelExpr ->
    Prop
  | terminal
      {localContext : PsKernelLocalContext}
      (left right : PsKernelExpr)
      (subst : List PsKernelExpr)
      (hCore :
        PsKernelDefEqJudgment
          environment
          localContext
          (psKernelExprInstantiateRev left subst)
          (psKernelExprInstantiateRev right subst)) :
      PsKernelForallSpineJudgment
        environment
        localContext
        left
        right
        subst
  | stepOpen
      {localContext : PsKernelLocalContext}
      (leftName rightName fresh : PsKernelName)
      (leftDomain rightDomain leftBody rightBody : PsKernelExpr)
      (leftInfo rightInfo : PsKernelBinderInfo)
      (subst : List PsKernelExpr)
      (hDomain :
        PsKernelBinderDomainJudgment
          environment
          localContext
          leftDomain
          rightDomain
          subst)
      (hDependent :
        (if psKernelExprHasLooseBVar leftBody then
           true
         else
           psKernelExprHasLooseBVar rightBody) =
          true)
      (hFresh :
        psKernelLocalContextFind localContext fresh =
          Option.none)
      (hRest :
        PsKernelForallSpineJudgment
          environment
          (psKernelLocalContextAddLocal
            localContext
            fresh
            rightName
            (psKernelExprInstantiateRev rightDomain subst)
            rightInfo)
          leftBody
          rightBody
          (psKernelExprListAppend
            subst
            (List.cons
              (PsKernelExpr.fvar fresh)
              List.nil))) :
      PsKernelForallSpineJudgment
        environment
        localContext
        (PsKernelExpr.forallE
          leftName leftDomain leftBody leftInfo)
        (PsKernelExpr.forallE
          rightName rightDomain rightBody rightInfo)
        subst
  | stepClosed
      {localContext : PsKernelLocalContext}
      (leftName rightName : PsKernelName)
      (leftDomain rightDomain leftBody rightBody : PsKernelExpr)
      (leftInfo rightInfo : PsKernelBinderInfo)
      (subst : List PsKernelExpr)
      (hDomain :
        PsKernelBinderDomainJudgment
          environment
          localContext
          leftDomain
          rightDomain
          subst)
      (hLeftClosed :
        psKernelExprHasLooseBVar leftBody = false)
      (hRightClosed :
        psKernelExprHasLooseBVar rightBody = false)
      (hRest :
        PsKernelForallSpineJudgment
          environment
          localContext
          leftBody
          rightBody
          (psKernelExprListAppend
            subst
            (List.cons
              (PsKernelExpr.sort PsKernelLevel.zero)
              List.nil))) :
      PsKernelForallSpineJudgment
        environment
        localContext
        (PsKernelExpr.forallE
          leftName leftDomain leftBody leftInfo)
        (PsKernelExpr.forallE
          rightName rightDomain rightBody rightInfo)
        subst

inductive PsKernelProjectionApplyParamsJudgment
    (environment : PsKernelEnvironment) :
    PsKernelLocalContext ->
    List PsKernelExpr ->
    Nat -> Nat -> PsKernelExpr -> PsKernelExpr -> Prop
  | done
      {localContext : PsKernelLocalContext}
      {args : List PsKernelExpr}
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
      {localContext : PsKernelLocalContext}
      {args : List PsKernelExpr}
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
    (environment : PsKernelEnvironment) :
    PsKernelLocalContext ->
    PsKernelName ->
    PsKernelExpr ->
    Nat ->
    Nat -> PsKernelExpr -> PsKernelExpr -> Prop
  | done
      {localContext : PsKernelLocalContext}
      {inductName : PsKernelName}
      {structValue : PsKernelExpr}
      {targetIndex : Nat}
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
      {localContext : PsKernelLocalContext}
      {inductName : PsKernelName}
      {structValue : PsKernelExpr}
      {targetIndex : Nat}
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
      {localContext : PsKernelLocalContext}
      {inductName : PsKernelName}
      {structValue : PsKernelExpr}
      {targetIndex : Nat}
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
    (environment : PsKernelEnvironment) :
    PsKernelLocalContext ->
    PsKernelName ->
    Nat ->
    PsKernelExpr ->
    PsKernelExpr ->
    PsKernelExpr ->
    Prop
  | intro
      {localContext : PsKernelLocalContext}
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
  | presentation
      {localContext : PsKernelLocalContext}
      (storedExpr queryExpr result : PsKernelExpr)
      (hExpr :
        PsKernelStructuralExprEq
          storedExpr
          queryExpr)
      (hStored :
        PsKernelTypingJudgment
          environment
          localContext
          storedExpr
          result) :
      PsKernelTypingJudgment
        environment
        localContext
        queryExpr
        result
  | contextWeaken
      {older newer : PsKernelLocalContext}
      (expr result : PsKernelExpr)
      (hExt :
        PsKernelLocalContextExtends
          older
          newer)
      (hTyping :
        PsKernelTypingJudgment
          environment
          older
          expr
          result) :
      PsKernelTypingJudgment
        environment
        newer
        expr
        result
  | convert
      {localContext : PsKernelLocalContext}
      (expr inferred expected : PsKernelExpr)
      (hTyping :
        PsKernelTypingJudgment
          environment
          localContext
          expr
          inferred)
      (hConvert :
        PsKernelDefEqJudgment
          environment
          localContext
          inferred
          expected) :
      PsKernelTypingJudgment
        environment
        localContext
        expr
        expected
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

end

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


def PsKernelReductionCacheSound
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (cache : PsKernelExprMap) : Prop :=
  ∀ (expr result : PsKernelExpr),
    psKernelExprMapGet cache expr = Option.some result ->
      PsKernelReductionClosure
        environment
        localContext
        expr
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



/-
Infer-only memoization is operationally isolated from checked kernel
acceptance.  Infer-only application/lambda/forall paths deliberately skip some
checks and may therefore cache results that are not full TypingJudgment
certificates.  Checked inference never consults this cache, so the Assurance
Plane records isolation rather than a false typing-soundness obligation.
-/
def PsKernelInferOnlyCacheIsolated
    (_environment : PsKernelEnvironment)
    (_localContext : PsKernelLocalContext)
    (_cache : PsKernelExprMap) : Prop :=
  True

theorem psKernelInferOnlyCacheIsolated_empty
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext) :
    PsKernelInferOnlyCacheIsolated
      environment
      localContext
      psKernelExprMapEmpty := by
  trivial

theorem psKernelInferOnlyCacheIsolated_insert
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (cache : PsKernelExprMap)
    (expr result : PsKernelExpr)
    (_hCache :
      PsKernelInferOnlyCacheIsolated
        environment
        localContext
        cache)
    (_hTyping :
      PsKernelTypingJudgment
        environment
        localContext
        expr
        result) :
    PsKernelInferOnlyCacheIsolated
      environment
      localContext
      (psKernelExprMapInsert
        cache
        expr
        result) := by
  trivial


def PsKernelCheckerStateSemanticSound
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (state : PsKernelCheckerState) : Prop :=
  PsKernelInferOnlyCacheIsolated
      environment
      localContext
      state.inferOnly ∧
  PsKernelInferenceCacheSound
      environment
      localContext
      state.checkedInfer ∧
  PsKernelReductionCacheSound
      environment
      localContext
      state.whnfCore ∧
  PsKernelReductionCacheSound
      environment
      localContext
      state.whnf ∧
  PsKernelReductionCacheSound
      environment
      localContext
      state.unfold ∧
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



def PsKernelReductionCacheInsertLaw : Prop :=
  ∀
    (environment : PsKernelEnvironment)
    (localContext : PsKernelLocalContext)
    (cache : PsKernelExprMap)
    (expr result : PsKernelExpr),
    PsKernelReductionCacheSound
        environment
        localContext
        cache ->
    PsKernelReductionClosure
        environment
        localContext
        expr
        result ->
    PsKernelReductionCacheSound
      environment
      localContext
      (psKernelExprMapInsert
        cache
        expr
        result)

/-
Stateful contracts are the final Assurance Plane target for the checker knot.
They make cache/state preservation explicit; the older result-only contracts
below remain useful for local composition but are insufficient for arbitrary
checker states because executable operations may return cached answers.
-/

def PsKernelInferenceCoreStatefulSound
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
    PsKernelCheckerStateSemanticSound
        context.environment
        context.localContext
        state ->
    psKernelInferCoreWithFuel
        fuel whnf defeq
        context state expr inferOnly =
      Except.ok (Prod.mk result nextState) ->
    PsKernelTypingJudgment
        context.environment
        context.localContext
        expr
        result ∧
      PsKernelCheckerStateSemanticSound
        context.environment
        context.localContext
        nextState

def PsKernelWhnfCoreStatefulSound
    (coreWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState)) : Prop :=
  ∀
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr result : PsKernelExpr)
    (cheapRec cheapProj : Bool),
    PsKernelCheckerStateSemanticSound
        context.environment
        context.localContext
        state ->
    coreWhnf
        context
        state
        expr
        cheapRec
        cheapProj =
      Except.ok (Prod.mk result nextState) ->
    PsKernelReductionClosure
        context.environment
        context.localContext
        expr
        result ∧
      PsKernelCheckerStateSemanticSound
        context.environment
        context.localContext
        nextState

def PsKernelWhnfStatefulSound
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
    PsKernelCheckerStateSemanticSound
        context.environment
        context.localContext
        state ->
    whnf context state expr =
      Except.ok (Prod.mk result nextState) ->
    PsKernelReductionClosure
        context.environment
        context.localContext
        expr
        result ∧
      PsKernelCheckerStateSemanticSound
        context.environment
        context.localContext
        nextState

def PsKernelDefEqStatefulSound
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
    (left right : PsKernelExpr)
    (value : Bool),
    PsKernelCheckerStateSemanticSound
        context.environment
        context.localContext
        state ->
    defeq context state left right =
      Except.ok (Prod.mk value nextState) ->
    PsKernelCheckerStateSemanticSound
        context.environment
        context.localContext
        nextState ∧
      (value = true ->
        PsKernelDefEqJudgment
          context.environment
          context.localContext
          left
          right)

def PsKernelInferenceStatefulSound
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
    PsKernelCheckerStateSemanticSound
        context.environment
        context.localContext
        state ->
    infer context state expr =
      Except.ok (Prod.mk result nextState) ->
    PsKernelTypingJudgment
        context.environment
        context.localContext
        expr
        result ∧
      PsKernelCheckerStateSemanticSound
        context.environment
        context.localContext
        nextState


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


def PsKernelWhnfCoreSound
    (coreWhnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Bool ->
      Bool ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState)) : Prop :=
  ∀
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (expr result : PsKernelExpr)
    (cheapRec cheapProj : Bool),
    coreWhnf
        context
        state
        expr
        cheapRec
        cheapProj =
      Except.ok (Prod.mk result nextState) ->
    PsKernelReductionClosure
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


def PsKernelProjectionSound
    (whnf inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String (Prod PsKernelExpr PsKernelCheckerState)) : Prop :=
  ∀
    (context : PsKernelCheckerContext)
    (state nextState : PsKernelCheckerState)
    (typeName : PsKernelName)
    (index : Nat)
    (structValue result : PsKernelExpr),
    PsKernelEnvironmentIndexRefines context.environment ->
    psKernelInferProjectionWith
        whnf
        inferType
        context
        state
        typeName
        index
        structValue =
      Except.ok (Prod.mk result nextState) ->
    PsKernelTypingJudgment
      context.environment
      context.localContext
      (PsKernelExpr.proj typeName index structValue)
      result
