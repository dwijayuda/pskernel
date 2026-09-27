import Ps.KernelCore.Declaration

def psKernelCoreExprContainsConstName
    (target : PsKernelCoreName)
    (expr : PsKernelCoreExpr) : Bool :=
  match expr with
  | PsKernelCoreExpr.bvar _ => false
  | PsKernelCoreExpr.fvar _ => false
  | PsKernelCoreExpr.mvar _ => false
  | PsKernelCoreExpr.sort _ => false
  | PsKernelCoreExpr.const name _ => psKernelCoreNameEq target name
  | PsKernelCoreExpr.app fn arg =>
      if psKernelCoreExprContainsConstName target fn then
        true
      else
        psKernelCoreExprContainsConstName target arg
  | PsKernelCoreExpr.lam _ type body _ =>
      if psKernelCoreExprContainsConstName target type then
        true
      else
        psKernelCoreExprContainsConstName target body
  | PsKernelCoreExpr.forallE _ type body _ =>
      if psKernelCoreExprContainsConstName target type then
        true
      else
        psKernelCoreExprContainsConstName target body
  | PsKernelCoreExpr.letE _ type value body _ =>
      if psKernelCoreExprContainsConstName target type then
        true
      else if psKernelCoreExprContainsConstName target value then
        true
      else
        psKernelCoreExprContainsConstName target body
  | PsKernelCoreExpr.lit _ => false
  | PsKernelCoreExpr.mdata _ body =>
      psKernelCoreExprContainsConstName target body
  | PsKernelCoreExpr.proj typeName _ body =>
      if psKernelCoreNameEq target typeName then
        true
      else
        psKernelCoreExprContainsConstName target body

def psKernelCoreExprAppHead
    (expr : PsKernelCoreExpr) : PsKernelCoreExpr :=
  match expr with
  | PsKernelCoreExpr.app fn _ => psKernelCoreExprAppHead fn
  | _ => expr

def psKernelCoreExprAppArgsRev
    (expr : PsKernelCoreExpr) : PsKernelCoreList PsKernelCoreExpr :=
  match expr with
  | PsKernelCoreExpr.app fn arg =>
      PsKernelCoreList.cons arg (psKernelCoreExprAppArgsRev fn)
  | _ => PsKernelCoreList.nil

def psKernelCoreExprListReverseAppend
    (values : PsKernelCoreList PsKernelCoreExpr) :
    PsKernelCoreList PsKernelCoreExpr ->
    PsKernelCoreList PsKernelCoreExpr :=
  match values with
  | PsKernelCoreList.nil =>
      fun (acc : PsKernelCoreList PsKernelCoreExpr) => acc
  | PsKernelCoreList.cons head tail =>
      let next := psKernelCoreExprListReverseAppend tail;
      fun (acc : PsKernelCoreList PsKernelCoreExpr) =>
        next (PsKernelCoreList.cons head acc)

def psKernelCoreExprAppArgs
    (expr : PsKernelCoreExpr) : PsKernelCoreList PsKernelCoreExpr :=
  psKernelCoreExprListReverseAppend
    (psKernelCoreExprAppArgsRev expr)
    PsKernelCoreList.nil

def psKernelCoreExprListLength
    (values : PsKernelCoreList PsKernelCoreExpr) : Nat :=
  match values with
  | PsKernelCoreList.nil => 0
  | PsKernelCoreList.cons _ tail =>
      Nat.succ (psKernelCoreExprListLength tail)

def psKernelCoreExprListTake
    (count : Nat) :
    PsKernelCoreList PsKernelCoreExpr ->
    PsKernelCoreList PsKernelCoreExpr :=
  match count with
  | Nat.zero =>
      fun (_values : PsKernelCoreList PsKernelCoreExpr) =>
        PsKernelCoreList.nil
  | Nat.succ remaining =>
      let smaller := psKernelCoreExprListTake remaining;
      fun (values : PsKernelCoreList PsKernelCoreExpr) =>
        match values with
        | PsKernelCoreList.nil => PsKernelCoreList.nil
        | PsKernelCoreList.cons head tail =>
            PsKernelCoreList.cons head (smaller tail)

def psKernelCoreExprListContainsTarget
    (target : PsKernelCoreName)
    (values : PsKernelCoreList PsKernelCoreExpr) : Bool :=
  match values with
  | PsKernelCoreList.nil => false
  | PsKernelCoreList.cons head tail =>
      if psKernelCoreExprContainsConstName target head then
        true
      else
        psKernelCoreExprListContainsTarget target tail

def psKernelCoreInductiveUniformParamArgsMatch
    (binderDepth : Nat)
    (args : PsKernelCoreList PsKernelCoreExpr) : Nat -> Bool :=
  match args with
  | PsKernelCoreList.nil =>
      fun (_index : Nat) => true
  | PsKernelCoreList.cons head tail =>
      let restMatch :=
        psKernelCoreInductiveUniformParamArgsMatch binderDepth tail;
      fun (index : Nat) =>
        match head with
        | PsKernelCoreExpr.bvar bvarIndex =>
            if Nat.ble (Nat.succ index) binderDepth then
              if Nat.beq bvarIndex (Nat.sub (Nat.sub binderDepth 1) index) then
                restMatch (Nat.succ index)
              else
                false
            else
              false
        | _ => false

def psKernelCoreInductiveResultMatches
    (target : PsKernelCoreName)
    (levels : PsKernelCoreList PsKernelCoreLevel)
    (numParams : Nat)
    (numIndices : Nat)
    (binderDepth : Nat)
    (expr : PsKernelCoreExpr) : Bool :=
  let head := psKernelCoreExprAppHead expr;
  let args := psKernelCoreExprAppArgs expr;
  match head with
  | PsKernelCoreExpr.const name resultLevels =>
      if psKernelCoreNameEq target name then
        if psKernelCoreLevelListEq levels resultLevels then
          if Nat.beq
              (psKernelCoreExprListLength args)
              (Nat.add numParams numIndices) then
            let paramArgs := psKernelCoreExprListTake numParams args;
            if psKernelCoreInductiveUniformParamArgsMatch
                binderDepth paramArgs 0 then
              if psKernelCoreExprListContainsTarget target args then
                false
              else
                true
            else
              false
          else
            false
        else
          false
      else
        false
  | _ => false

def psKernelCoreInductiveConstructorRecursiveOccurrenceCore
    (target : PsKernelCoreName)
    (levels : PsKernelCoreList PsKernelCoreLevel)
    (numParams : Nat)
    (numIndices : Nat)
    (expr : PsKernelCoreExpr) : Nat -> Bool :=
  match expr with
  | PsKernelCoreExpr.forallE _ domain body _ =>
      let bodyCheck :=
        psKernelCoreInductiveConstructorRecursiveOccurrenceCore
          target levels numParams numIndices body;
      fun (binderDepth : Nat) =>
        if psKernelCoreExprContainsConstName target domain then
          true
        else
          bodyCheck (Nat.succ binderDepth)
  | _ =>
      fun (binderDepth : Nat) =>
        if psKernelCoreInductiveResultMatches
            target levels numParams numIndices binderDepth expr then
          false
        else
          psKernelCoreExprContainsConstName target expr

def psKernelCoreInductiveConstructorRecursiveOccurrence
    (target : PsKernelCoreName)
    (levels : PsKernelCoreList PsKernelCoreLevel)
    (numParams : Nat)
    (numIndices : Nat)
    (expr : PsKernelCoreExpr) : Bool :=
  psKernelCoreInductiveConstructorRecursiveOccurrenceCore
    target levels numParams numIndices expr 0
