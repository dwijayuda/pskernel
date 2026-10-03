inductive PsKernelName where
  | anonymous
  | str (parent : PsKernelName) (value : String)
  | num (parent : PsKernelName) (value : Nat)

inductive PsKernelNameComponent where
  | str (value : String)
  | num (value : Nat)

def psKernelNameEq
    (left : PsKernelName)
    (right : PsKernelName) : Bool :=
  match left with
  | PsKernelName.anonymous =>
      match right with
      | PsKernelName.anonymous => true
      | _ => false
  | PsKernelName.str leftParent leftValue =>
      match right with
      | PsKernelName.str rightParent rightValue =>
          if leftValue == rightValue then
            psKernelNameEq leftParent rightParent
          else
            false
      | _ => false
  | PsKernelName.num leftParent leftValue =>
      match right with
      | PsKernelName.num rightParent rightValue =>
          if leftValue == rightValue then
            psKernelNameEq leftParent rightParent
          else
            false
      | _ => false

def psKernelNameAppendAfter
    (name : PsKernelName)
    (suffix : String) : PsKernelName :=
  match name with
  | PsKernelName.str parent value =>
      PsKernelName.str parent (value ++ suffix)
  | other =>
      PsKernelName.str other suffix

def psKernelNameAppend
    (base : PsKernelName)
    (suffix : PsKernelName) : PsKernelName :=
  match suffix with
  | PsKernelName.anonymous =>
      base
  | PsKernelName.str parent value =>
      PsKernelName.str
        (psKernelNameAppend base parent)
        value
  | PsKernelName.num parent value =>
      PsKernelName.num
        (psKernelNameAppend base parent)
        value

def psKernelNameAppendIndexAfter
    (name : PsKernelName)
    (index : Nat) : PsKernelName :=
  psKernelNameAppendAfter
    name
    ("_" ++ toString index)

def psKernelNameIsPrefixOf
    (needle : PsKernelName)
    (candidate : PsKernelName) : Bool :=
  match candidate with
  | PsKernelName.anonymous =>
      psKernelNameEq needle PsKernelName.anonymous
  | PsKernelName.str parent value =>
      let current := PsKernelName.str parent value
      if psKernelNameEq needle current then
        true
      else
        psKernelNameIsPrefixOf needle parent
  | PsKernelName.num parent value =>
      let current := PsKernelName.num parent value
      if psKernelNameEq needle current then
        true
      else
        psKernelNameIsPrefixOf needle parent

def psKernelNameReplacePrefix
    (name : PsKernelName)
    (oldPrefix : PsKernelName)
    (newPrefix : PsKernelName) : Option PsKernelName :=
  if psKernelNameEq name oldPrefix then
    Option.some newPrefix
  else
    match name with
    | PsKernelName.str parent value =>
        match
            psKernelNameReplacePrefix
              parent
              oldPrefix
              newPrefix with
        | Option.some replacedParent =>
            Option.some
              (PsKernelName.str replacedParent value)
        | Option.none =>
            Option.none
    | PsKernelName.num parent value =>
        match
            psKernelNameReplacePrefix
              parent
              oldPrefix
              newPrefix with
        | Option.some replacedParent =>
            Option.some
              (PsKernelName.num replacedParent value)
        | Option.none =>
            Option.none
    | PsKernelName.anonymous =>
        Option.none

def psKernelNameComponentAppend
    (left : List PsKernelNameComponent)
    (right : List PsKernelNameComponent) :
    List PsKernelNameComponent :=
  match left with
  | List.nil => right
  | List.cons head tail =>
      List.cons
        head
        (psKernelNameComponentAppend tail right)

def psKernelNameComponents
    (name : PsKernelName) :
    List PsKernelNameComponent :=
  match name with
  | PsKernelName.anonymous =>
      List.nil
  | PsKernelName.str parent value =>
      psKernelNameComponentAppend
        (psKernelNameComponents parent)
        (List.cons
          (PsKernelNameComponent.str value)
          List.nil)
  | PsKernelName.num parent value =>
      psKernelNameComponentAppend
        (psKernelNameComponents parent)
        (List.cons
          (PsKernelNameComponent.num value)
          List.nil)

def psKernelNameComponentCmp
    (left : PsKernelNameComponent)
    (right : PsKernelNameComponent) : Ordering :=
  match left with
  | PsKernelNameComponent.num leftValue =>
      match right with
      | PsKernelNameComponent.num rightValue =>
          compare leftValue rightValue
      | PsKernelNameComponent.str _ =>
          Ordering.lt
  | PsKernelNameComponent.str leftValue =>
      match right with
      | PsKernelNameComponent.num _ =>
          Ordering.gt
      | PsKernelNameComponent.str rightValue =>
          compare leftValue rightValue

def psKernelCompareNameComponents
    (left : List PsKernelNameComponent)
    (right : List PsKernelNameComponent) :
    Ordering :=
  match left with
  | List.nil =>
      match right with
      | List.nil => Ordering.eq
      | List.cons _ _ => Ordering.lt
  | List.cons leftHead leftTail =>
      match right with
      | List.nil =>
          Ordering.gt
      | List.cons rightHead rightTail =>
          match
              psKernelNameComponentCmp
                leftHead
                rightHead with
          | Ordering.eq =>
              psKernelCompareNameComponents
                leftTail
                rightTail
          | ordering =>
              ordering

def psKernelNameCmp
    (left : PsKernelName)
    (right : PsKernelName) : Ordering :=
  psKernelCompareNameComponents
    (psKernelNameComponents left)
    (psKernelNameComponents right)
