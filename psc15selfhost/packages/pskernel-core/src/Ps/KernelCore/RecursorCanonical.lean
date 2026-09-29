import Ps.KernelCore.Inductive

structure PsKernelCoreRecursorOpenState where
  rest : PsKernelCoreExpr
  values : PsKernelCoreList PsKernelCoreExpr
  nextSeed : Nat

structure PsKernelCoreRecursorFieldOpenState where
  ctorResult : PsKernelCoreExpr
  minorResult : PsKernelCoreExpr
  fields : PsKernelCoreList PsKernelCoreExpr
  nextSeed : Nat

def psKernelCoreRecursorFreshFVar
    (seed : Nat) : PsKernelCoreExpr :=
  PsKernelCoreExpr.fvar
    (PsKernelCoreName.num
      (PsKernelCoreName.str PsKernelCoreName.anonymous "_psKernelCoreRecursor")
      seed)

def psKernelCoreRecursorOpenForalls
    (count : Nat) :
    PsKernelCoreExpr -> Nat ->
    PsKernelCoreOption PsKernelCoreRecursorOpenState :=
  match count with
  | Nat.zero =>
      fun (expr : PsKernelCoreExpr) (seed : Nat) =>
        PsKernelCoreOption.some {
          rest := expr
          values := PsKernelCoreList.nil
          nextSeed := seed
        }
  | Nat.succ remaining =>
      let openRemaining := psKernelCoreRecursorOpenForalls remaining;
      fun (expr : PsKernelCoreExpr) (seed : Nat) =>
        match expr with
        | PsKernelCoreExpr.forallE _ _ body _ =>
            let fresh := psKernelCoreRecursorFreshFVar seed;
            let openedBody := psKernelCoreExprInstantiate1 body fresh;
            match openRemaining openedBody (Nat.succ seed) with
            | PsKernelCoreOption.none => PsKernelCoreOption.none
            | PsKernelCoreOption.some state =>
                PsKernelCoreOption.some {
                  rest := state.rest
                  values := PsKernelCoreList.cons fresh state.values
                  nextSeed := state.nextSeed
                }
        | _ => PsKernelCoreOption.none

def psKernelCoreRecursorInstantiateForallPrefix
    (values : PsKernelCoreList PsKernelCoreExpr) :
    PsKernelCoreExpr -> PsKernelCoreOption PsKernelCoreExpr :=
  match values with
  | PsKernelCoreList.nil =>
      fun (expr : PsKernelCoreExpr) => PsKernelCoreOption.some expr
  | PsKernelCoreList.cons value rest =>
      let instantiateRest := psKernelCoreRecursorInstantiateForallPrefix rest;
      fun (expr : PsKernelCoreExpr) =>
        match expr with
        | PsKernelCoreExpr.forallE _ _ body _ =>
            instantiateRest (psKernelCoreExprInstantiate1 body value)
        | _ => PsKernelCoreOption.none

def psKernelCoreRecursorOpenMatchingFields
    (count : Nat) :
    PsKernelCoreExpr ->
    PsKernelCoreExpr ->
    Nat ->
    PsKernelCoreOption PsKernelCoreRecursorFieldOpenState :=
  match count with
  | Nat.zero =>
      fun (ctorExpr : PsKernelCoreExpr)
          (minorExpr : PsKernelCoreExpr)
          (seed : Nat) =>
        PsKernelCoreOption.some {
          ctorResult := ctorExpr
          minorResult := minorExpr
          fields := PsKernelCoreList.nil
          nextSeed := seed
        }
  | Nat.succ remaining =>
      let openRemaining := psKernelCoreRecursorOpenMatchingFields remaining;
      fun (ctorExpr : PsKernelCoreExpr)
          (minorExpr : PsKernelCoreExpr)
          (seed : Nat) =>
        match ctorExpr with
        | PsKernelCoreExpr.forallE _ ctorDomain ctorBody _ =>
            match minorExpr with
            | PsKernelCoreExpr.forallE _ minorDomain minorBody _ =>
                if psKernelCoreExprEq ctorDomain minorDomain then
                  let fresh := psKernelCoreRecursorFreshFVar seed;
                  let openedCtor := psKernelCoreExprInstantiate1 ctorBody fresh;
                  let openedMinor := psKernelCoreExprInstantiate1 minorBody fresh;
                  match openRemaining openedCtor openedMinor (Nat.succ seed) with
                  | PsKernelCoreOption.none => PsKernelCoreOption.none
                  | PsKernelCoreOption.some state =>
                      PsKernelCoreOption.some {
                        ctorResult := state.ctorResult
                        minorResult := state.minorResult
                        fields := PsKernelCoreList.cons fresh state.fields
                        nextSeed := state.nextSeed
                      }
                else
                  PsKernelCoreOption.none
            | _ => PsKernelCoreOption.none
        | _ => PsKernelCoreOption.none

def psKernelCoreRecursorExprListDrop
    (count : Nat) :
    PsKernelCoreList PsKernelCoreExpr ->
    PsKernelCoreList PsKernelCoreExpr :=
  match count with
  | Nat.zero =>
      fun (values : PsKernelCoreList PsKernelCoreExpr) => values
  | Nat.succ remaining =>
      let dropRemaining := psKernelCoreRecursorExprListDrop remaining;
      fun (values : PsKernelCoreList PsKernelCoreExpr) =>
        match values with
        | PsKernelCoreList.nil => PsKernelCoreList.nil
        | PsKernelCoreList.cons _ rest => dropRemaining rest

def psKernelCoreRecursorExprListEq
    (left : PsKernelCoreList PsKernelCoreExpr) :
    PsKernelCoreList PsKernelCoreExpr -> Bool :=
  match left with
  | PsKernelCoreList.nil =>
      fun (right : PsKernelCoreList PsKernelCoreExpr) =>
        match right with
        | PsKernelCoreList.nil => true
        | PsKernelCoreList.cons _ _ => false
  | PsKernelCoreList.cons leftHead leftRest =>
      let eqRest := psKernelCoreRecursorExprListEq leftRest;
      fun (right : PsKernelCoreList PsKernelCoreExpr) =>
        match right with
        | PsKernelCoreList.nil => false
        | PsKernelCoreList.cons rightHead rightRest =>
            if psKernelCoreExprEq leftHead rightHead then
              eqRest rightRest
            else
              false

def psKernelCoreRecursorApplyArgs
    (fn : PsKernelCoreExpr)
    (args : PsKernelCoreList PsKernelCoreExpr) : PsKernelCoreExpr :=
  match args with
  | PsKernelCoreList.nil => fn
  | PsKernelCoreList.cons arg rest =>
      psKernelCoreRecursorApplyArgs (PsKernelCoreExpr.app fn arg) rest

def psKernelCoreRecursorMinorMatchesConstructor
    (info : PsKernelCoreRecursorInfo)
    (family : PsKernelCoreInductiveInfo)
    (ctor : PsKernelCoreConstructorInfo)
    (ruleIndex : Nat) : Bool :=
  let prefixCount :=
    Nat.add (Nat.add info.numParams info.numMotives) ruleIndex;
  match psKernelCoreRecursorOpenForalls prefixCount info.base.type 0 with
  | PsKernelCoreOption.none => false
  | PsKernelCoreOption.some prefix =>
      let paramValues :=
        psKernelCoreExprListTake info.numParams prefix.values;
      match psKernelCoreExprListGet prefix.values info.numParams with
      | PsKernelCoreOption.none => false
      | PsKernelCoreOption.some motive =>
          match psKernelCoreRecursorInstantiateForallPrefix
              paramValues ctor.base.type with
          | PsKernelCoreOption.none => false
          | PsKernelCoreOption.some ctorFields =>
              match psKernelCoreRecursorOpenMatchingFields
                  ctor.numFields ctorFields prefix.rest prefix.nextSeed with
              | PsKernelCoreOption.none => false
              | PsKernelCoreOption.some opened =>
                  let resultHead := psKernelCoreExprAppHead opened.ctorResult;
                  let resultArgs := psKernelCoreExprAppArgs opened.ctorResult;
                  match resultHead with
                  | PsKernelCoreExpr.const familyName resultLevels =>
                      if psKernelCoreNameEq familyName family.base.name then
                        if Nat.beq
                            (psKernelCoreExprListLength resultArgs)
                            (Nat.add family.numParams family.numIndices) then
                          let resultParams :=
                            psKernelCoreExprListTake family.numParams resultArgs;
                          if psKernelCoreRecursorExprListEq
                              resultParams paramValues then
                            let indices :=
                              psKernelCoreRecursorExprListDrop
                                family.numParams resultArgs;
                            let ctorArgs :=
                              psKernelCoreExprListAppend
                                paramValues opened.fields;
                            let ctorHead :=
                              PsKernelCoreExpr.const ctor.base.name resultLevels;
                            let major :=
                              psKernelCoreRecursorApplyArgs ctorHead ctorArgs;
                            let motiveAtIndices :=
                              psKernelCoreRecursorApplyArgs motive indices;
                            let expectedResult :=
                              PsKernelCoreExpr.app motiveAtIndices major;
                            psKernelCoreExprEq opened.minorResult expectedResult
                          else
                            false
                        else
                          false
                      else
                        false
                  | _ => false
