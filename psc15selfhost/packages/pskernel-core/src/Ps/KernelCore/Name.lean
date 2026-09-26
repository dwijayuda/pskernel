inductive PsKernelCoreName where
  | anonymous
  | str (parent : PsKernelCoreName) (value : String)
  | num (parent : PsKernelCoreName) (value : Nat)

def psKernelCoreNameEq
    (left : PsKernelCoreName) : PsKernelCoreName -> Bool :=
  match left with
  | PsKernelCoreName.anonymous =>
      fun (right : PsKernelCoreName) =>
        match right with
        | PsKernelCoreName.anonymous => true
        | _ => false
  | PsKernelCoreName.str leftParent leftValue =>
      let parentEq : PsKernelCoreName -> Bool :=
        psKernelCoreNameEq leftParent;
      fun (right : PsKernelCoreName) =>
        match right with
        | PsKernelCoreName.str rightParent rightValue =>
            if parentEq rightParent then
              leftValue == rightValue
            else
              false
        | _ => false
  | PsKernelCoreName.num leftParent leftValue =>
      let parentEq : PsKernelCoreName -> Bool :=
        psKernelCoreNameEq leftParent;
      fun (right : PsKernelCoreName) =>
        match right with
        | PsKernelCoreName.num rightParent rightValue =>
            if parentEq rightParent then
              Nat.beq leftValue rightValue
            else
              false
        | _ => false

def psKernelCoreNameMember
    (target : PsKernelCoreName)
    (names : List PsKernelCoreName) : Bool :=
  match names with
  | [] => false
  | name :: rest =>
      if psKernelCoreNameEq target name then
        true
      else
        psKernelCoreNameMember target rest

def psKernelCoreNameHasDuplicates
    (names : List PsKernelCoreName) : Bool :=
  match names with
  | [] => false
  | name :: rest =>
      if psKernelCoreNameMember name rest then
        true
      else
        psKernelCoreNameHasDuplicates rest
