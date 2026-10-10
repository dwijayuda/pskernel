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

/- Independent expected equivalence classes exercise every expression form,
   ignored binder names/info, and significant metadata/projection/let fields. -/
def psKernelCrossEqualityEntry (index : Nat) : Prod PsKernelExpr Nat :=
  let a : PsKernelName := psKernelCrossName "a";
  let b : PsKernelName := psKernelCrossName "b";
  let zero : PsKernelExpr := PsKernelExpr.bvar 0;
  let one : PsKernelExpr := PsKernelExpr.bvar 1;
  let sort : PsKernelExpr := PsKernelExpr.sort PsKernelLevel.zero;
  let app : PsKernelExpr := PsKernelExpr.app zero one;
  if Nat.beq index 0 then Prod.mk zero 0
  else if Nat.beq index 1 then Prod.mk one 1
  else if Nat.beq index 2 then Prod.mk (PsKernelExpr.fvar a) 2
  else if Nat.beq index 3 then Prod.mk (PsKernelExpr.mvar a) 3
  else if Nat.beq index 4 then Prod.mk sort 4
  else if Nat.beq index 5 then Prod.mk (PsKernelExpr.sort (PsKernelLevel.succ PsKernelLevel.zero)) 5
  else if Nat.beq index 6 then Prod.mk (PsKernelExpr.const a List.nil) 6
  else if Nat.beq index 7 then Prod.mk (PsKernelExpr.const a (List.cons PsKernelLevel.zero List.nil)) 7
  else if Nat.beq index 8 then Prod.mk app 8
  else if Nat.beq index 9 then Prod.mk (PsKernelExpr.app one one) 9
  else if Nat.beq index 10 then Prod.mk (PsKernelExpr.lam a sort zero PsKernelBinderInfo.default) 10
  else if Nat.beq index 11 then Prod.mk (PsKernelExpr.lam b sort zero PsKernelBinderInfo.implicit) 10
  else if Nat.beq index 12 then Prod.mk (PsKernelExpr.lam a sort one PsKernelBinderInfo.default) 12
  else if Nat.beq index 13 then Prod.mk (PsKernelExpr.forallE a sort zero PsKernelBinderInfo.default) 13
  else if Nat.beq index 14 then Prod.mk (PsKernelExpr.forallE b sort zero PsKernelBinderInfo.implicit) 13
  else if Nat.beq index 15 then Prod.mk (PsKernelExpr.letE a sort zero one false) 15
  else if Nat.beq index 16 then Prod.mk (PsKernelExpr.letE b sort zero one false) 15
  else if Nat.beq index 17 then Prod.mk (PsKernelExpr.letE a sort zero one true) 17
  else if Nat.beq index 18 then Prod.mk (PsKernelExpr.lit (PsKernelLiteral.nat 9007199254740993)) 18
  else if Nat.beq index 19 then Prod.mk (PsKernelExpr.mdata 1 app) 19
  else if Nat.beq index 20 then Prod.mk (PsKernelExpr.mdata 2 app) 20
  else if Nat.beq index 21 then Prod.mk (PsKernelExpr.proj a 0 app) 21
  else if Nat.beq index 22 then Prod.mk (PsKernelExpr.proj a 1 app) 22
  else if Nat.beq index 23 then Prod.mk (PsKernelExpr.proj b 0 app) 23
  else if Nat.beq index 24 then Prod.mk (PsKernelExpr.lit (PsKernelLiteral.nat 9007199254740992)) 24
  else if Nat.beq index 25 then Prod.mk (PsKernelExpr.lit (PsKernelLiteral.str "x")) 25
  else Prod.mk (PsKernelExpr.mdata 1 (PsKernelExpr.app zero one)) 19

def psKernelCrossEqualityRow (remaining : Nat) : PsKernelExpr -> Nat -> Bool :=
  match remaining with
  | Nat.zero => fun (_left : PsKernelExpr) (_group : Nat) => true
  | Nat.succ rest =>
      let smaller : PsKernelExpr -> Nat -> Bool := psKernelCrossEqualityRow rest;
      fun (left : PsKernelExpr) (group : Nat) =>
        let other : Prod PsKernelExpr Nat := psKernelCrossEqualityEntry rest;
        if psKernelBoolEq (psKernelExprEq left (Prod.fst other)) (Nat.beq group (Prod.snd other)) then
          smaller left group
        else false

def psKernelCrossEqualityMatrix (remaining : Nat) : Bool :=
  match remaining with
  | Nat.zero => true
  | Nat.succ rest =>
      let entry : Prod PsKernelExpr Nat := psKernelCrossEqualityEntry rest;
      if psKernelCrossEqualityRow 27 (Prod.fst entry) (Prod.snd entry) then
        psKernelCrossEqualityMatrix rest
      else false

def psKernelCrossZeroLiftMatrix (remaining : Nat) : Bool :=
  match remaining with
  | Nat.zero => true
  | Nat.succ rest =>
      let expr : PsKernelExpr := Prod.fst (psKernelCrossEqualityEntry rest);
      let first : Prod PsKernelExpr Bool := psKernelExprLiftLooseBVarsChanged expr 0 0;
      let second : Prod PsKernelExpr Bool := psKernelExprLiftLooseBVarsChanged expr 42 0;
      if Prod.snd first then false
      else if Prod.snd second then false
      else if psKernelExprEqual expr (Prod.fst first) then
        if psKernelExprEqual expr (Prod.fst second) then psKernelCrossZeroLiftMatrix rest
        else false
      else false

def psKernelCrossGuardChecks : Bool :=
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
  if psKernelCrossEqualityMatrix 27 then
    if rejects then
      if exhausted then
        if psKernelExprEq large adjacent then false
        else if psKernelCrossAdmit 4 false then
          if psKernelCrossAdmit 4 true then false else true
        else false
      else false
    else false
  else false

def psKernelCrossGuards : Bool :=
  if psKernelCrossZeroLiftMatrix 27 then psKernelCrossGuardChecks else false
