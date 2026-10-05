import Ps.KernelCore.SelfHost

/- Test-only fixtures compiled unchanged by Lean and PSC/backend-ts.
   Inputs are prepared outside timing; each operation starts a cold session. -/
structure PsKernelCrossInput where
  environment : PsKernelEnvironment
  expression : PsKernelExpr
  expected : PsKernelExpr

def psKernelCrossName (text : String) : PsKernelName :=
  PsKernelName.str PsKernelName.anonymous text

def psKernelCrossNat : PsKernelExpr :=
  PsKernelExpr.const psKernelNatName List.nil

def psKernelCrossArrow (count : Nat) : PsKernelExpr :=
  match count with
  | Nat.zero => psKernelCrossNat
  | Nat.succ rest =>
      PsKernelExpr.forallE PsKernelName.anonymous psKernelCrossNat
        (psKernelCrossArrow rest) PsKernelBinderInfo.default

def psKernelCrossEnvironment : PsKernelEnvironment :=
  let natBase : PsKernelConstantBase := {
    name := psKernelNatName
    levelParams := List.nil
    type := PsKernelExpr.sort (PsKernelLevel.succ PsKernelLevel.zero)
  };
  let natInfo : PsKernelAxiomInfo := {
    base := natBase
    isUnsafe := false
  };
  let withNat : PsKernelEnvironment :=
    psKernelEnvironmentAddUnchecked psKernelEnvironmentEmpty
      (PsKernelConstantInfo.axiomInfo natInfo);
  let appBase : PsKernelConstantBase := {
    name := psKernelCrossName "CrossApply"
    levelParams := List.nil
    type := psKernelCrossArrow 8
  };
  let appInfo : PsKernelAxiomInfo := {
    base := appBase
    isUnsafe := false
  };
  psKernelEnvironmentAddUnchecked withNat (PsKernelConstantInfo.axiomInfo appInfo)

def psKernelCrossBeta (count : Nat) (value : PsKernelExpr) : PsKernelExpr :=
  match count with
  | Nat.zero => value
  | Nat.succ rest =>
      PsKernelExpr.app
        (PsKernelExpr.lam PsKernelName.anonymous psKernelCrossNat
          (PsKernelExpr.bvar 0) PsKernelBinderInfo.default)
        (psKernelCrossBeta rest value)

def psKernelCrossApply (count : Nat) : PsKernelExpr -> PsKernelExpr -> PsKernelExpr :=
  match count with
  | Nat.zero => fun (fn : PsKernelExpr) (_value : PsKernelExpr) => fn
  | Nat.succ rest =>
      let smaller : PsKernelExpr -> PsKernelExpr -> PsKernelExpr := psKernelCrossApply rest;
      fun (fn : PsKernelExpr) (value : PsKernelExpr) =>
        smaller (PsKernelExpr.app fn value) value

def psKernelCrossInput (kind seed : Nat) : PsKernelCrossInput :=
  let value : PsKernelExpr := PsKernelExpr.lit (PsKernelLiteral.nat (Nat.add seed 9007199254740993));
  if Nat.beq kind 2 then
    {
      environment := psKernelCrossEnvironment
      expression := psKernelCrossApply 8
        (PsKernelExpr.const (psKernelCrossName "CrossApply") List.nil) value
      expected := psKernelCrossNat
    }
  else
    {
      environment := psKernelCrossEnvironment
      expression := psKernelCrossBeta 16 value
      expected := value
    }

def psKernelCrossRun (kind : Nat) (input : PsKernelCrossInput) : Bool :=
  let session : PsKernelCheckerSession := psKernelMkCheckerSession input.environment List.nil
    PsKernelDefinitionSafety.safe 0 psKernelLeanNatMaxSizeDefault;
  if Nat.beq kind 0 then
    match psKernelSessionWhnf 2048 session input.expression with
    | Except.error _ => false
    | Except.ok result => psKernelExprEq (Prod.fst result) input.expected
  else if Nat.beq kind 1 then
    match psKernelSessionIsDefEq 2048 session input.expression input.expected with
    | Except.error _ => false
    | Except.ok result => Prod.fst result
  else
    match psKernelSessionCheck 2048 session input.expression with
    | Except.error _ => false
    | Except.ok result => psKernelExprEq (Prod.fst result) input.expected

def psKernelCrossAdmission (index : Nat) (bad : Bool) : PsKernelDefinitionInfo :=
  let base : PsKernelConstantBase := {
    name := PsKernelName.num (psKernelCrossName "CrossAdmission") index
    levelParams := List.nil
    type := psKernelCrossNat
  };
  {
    base := base
    value := if bad then PsKernelExpr.sort PsKernelLevel.zero
      else PsKernelExpr.lit (PsKernelLiteral.nat (Nat.add index 9007199254740993))
    hints := PsKernelReducibilityHints.regular 1
    safety := PsKernelDefinitionSafety.safe
  }

def psKernelCrossAdmitLoop (remaining : Nat) :
    Nat -> Bool -> PsKernelEnvironment -> Except String PsKernelEnvironment :=
  match remaining with
  | Nat.zero => fun (_index : Nat) (_bad : Bool) (environment : PsKernelEnvironment) =>
      Except.ok environment
  | Nat.succ rest =>
      let smaller : Nat -> Bool -> PsKernelEnvironment -> Except String PsKernelEnvironment :=
        psKernelCrossAdmitLoop rest;
      fun (index : Nat) (bad : Bool) (environment : PsKernelEnvironment) =>
        let rejectLast : Bool := if bad then Nat.beq rest 0 else false;
        match psKernelAddDefinition 2048 environment
            (psKernelCrossAdmission index rejectLast)
            0 psKernelLeanNatMaxSizeDefault with
        | Except.error error => Except.error error
        | Except.ok next => smaller (Nat.succ index) bad next

def psKernelCrossAdmit (count : Nat) (bad : Bool) : Bool :=
  match psKernelCrossAdmitLoop count 0 bad psKernelCrossEnvironment with
  | Except.error _ => false
  | Except.ok _ => true

def psKernelCrossGuards : Bool :=
  let session : PsKernelCheckerSession := psKernelMkCheckerSession psKernelCrossEnvironment List.nil
    PsKernelDefinitionSafety.safe 0 psKernelLeanNatMaxSizeDefault;
  let illTyped : PsKernelExpr := PsKernelExpr.app
    (PsKernelExpr.const (psKernelCrossName "CrossApply") List.nil)
    (PsKernelExpr.sort PsKernelLevel.zero);
  let rejects : Bool :=
    match psKernelSessionCheck 2048 session illTyped with
    | Except.error _ => true
    | Except.ok _ => false;
  let exhausted : Bool :=
    match psKernelSessionCheck 0 session (PsKernelExpr.lit (PsKernelLiteral.nat 7)) with
    | Except.error error => psKernelStringEq error "kernel inference budget exhausted"
    | Except.ok _ => false;
  let large : PsKernelExpr := PsKernelExpr.lit (PsKernelLiteral.nat 9007199254740993);
  let adjacent : PsKernelExpr := PsKernelExpr.lit (PsKernelLiteral.nat 9007199254740992);
  if rejects then
    if exhausted then
      if psKernelExprEq large adjacent then false
      else if psKernelCrossAdmit 4 false then
        if psKernelCrossAdmit 4 true then false else true
      else false
    else false
  else false
