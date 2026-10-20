import Ps.KernelCore.Core.Level

/- Scalar expression payloads shared by the recursive oracle and paged DAG.
No expression-tree, cache or environment dependency belongs in this module. -/

inductive PsKernelBinderInfo where
  | default
  | implicit
  | strictImplicit
  | instImplicit

inductive PsKernelLiteral where
  | nat (value : Nat)
  | str (value : String)

def psKernelBoolEq
    (left : Bool)
    (right : Bool) : Bool :=
  if left then
    right
  else if right then
    false
  else
    true

def psKernelBinderInfoEq
    (left : PsKernelBinderInfo)
    (right : PsKernelBinderInfo) : Bool :=
  match left with
  | PsKernelBinderInfo.default =>
      match right with
      | PsKernelBinderInfo.default => true
      | _ => false
  | PsKernelBinderInfo.implicit =>
      match right with
      | PsKernelBinderInfo.implicit => true
      | _ => false
  | PsKernelBinderInfo.strictImplicit =>
      match right with
      | PsKernelBinderInfo.strictImplicit => true
      | _ => false
  | PsKernelBinderInfo.instImplicit =>
      match right with
      | PsKernelBinderInfo.instImplicit => true
      | _ => false

def psKernelLiteralEq
    (left : PsKernelLiteral)
    (right : PsKernelLiteral) : Bool :=
  match left with
  | PsKernelLiteral.nat leftValue =>
      match right with
      | PsKernelLiteral.nat rightValue =>
          Nat.beq leftValue rightValue
      | _ =>
          false
  | PsKernelLiteral.str leftValue =>
      match right with
      | PsKernelLiteral.str rightValue =>
          psKernelStringEq leftValue rightValue
      | _ =>
          false

def psKernelLevelListEq
    (left : List PsKernelLevel) :
    List PsKernelLevel -> Bool :=
  match left with
  | List.nil =>
      fun (right : List PsKernelLevel) =>
        match right with
        | List.nil => true
        | List.cons _ _ => false
  | List.cons leftHead leftTail =>
      let smaller :
          List PsKernelLevel -> Bool :=
        psKernelLevelListEq leftTail;
      fun (right : List PsKernelLevel) =>
        match right with
        | List.nil =>
            false
        | List.cons rightHead rightTail =>
            if psKernelLevelEq leftHead rightHead then
              smaller rightTail
            else
              false

