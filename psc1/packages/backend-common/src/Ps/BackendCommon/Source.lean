import Ps.BackendCommon.StateExcept
import Ps.Foundation.List

def psBackendSourceFind {Value : Type} (predicate : Value -> Bool)
    (values : List Value) : Option Value :=
  match values with
  | List.nil => Option.none
  | List.cons value rest =>
      if predicate value then Option.some value else psBackendSourceFind predicate rest

def psBackendSourceAll {Value : Type} (predicate : Value -> Bool)
    (values : List Value) : Bool :=
  match values with
  | List.nil => true
  | List.cons value rest =>
      if predicate value then psBackendSourceAll predicate rest else false

def psBackendSourceForExcept {Error Value : Type}
    (action : Value -> Except Error Unit) (values : List Value) : Except Error Unit :=
  match values with
  | List.nil => Except.ok Unit.unit
  | List.cons value rest =>
      match action value with
      | Except.error error => Except.error error
      | Except.ok _ => psBackendSourceForExcept action rest

def psBackendSourceMapStateAcc {State Error A B : Type}
    (action : A -> PsBackendStateExcept State Error B)
    (values : List A) (reversed : List B)
    (state : State) : Except Error (Prod (List B) State) :=
  match values with
  | List.nil => Except.ok (Prod.mk (psListReverse reversed) state)
  | List.cons value rest =>
      match action value state with
      | Except.error error => Except.error error
      | Except.ok pair =>
          psBackendSourceMapStateAcc action rest (List.cons pair.fst reversed) pair.snd

def psBackendSourceMapState {State Error A B : Type}
    (action : A -> PsBackendStateExcept State Error B) (values : List A) :
    PsBackendStateExcept State Error (List B) :=
  psBackendSourceMapStateAcc action values List.nil

def psBackendSourceForState {State Error Value : Type}
    (action : Value -> PsBackendStateExcept State Error Unit)
    (values : List Value) (state : State) : Except Error (Prod Unit State) :=
  match values with
  | List.nil => Except.ok (Prod.mk Unit.unit state)
  | List.cons value rest =>
      match action value state with
      | Except.error error => Except.error error
      | Except.ok pair => psBackendSourceForState action rest pair.snd

def psBackendSourceZipIndexAcc {Value : Type} (values : List Value)
    (index : Nat) (reversed : List (Prod Value Nat)) : List (Prod Value Nat) :=
  match values with
  | List.nil => psListReverse reversed
  | List.cons value rest =>
      psBackendSourceZipIndexAcc rest (Nat.succ index) (List.cons (Prod.mk value index) reversed)

def psBackendSourceZipIndex {Value : Type} (values : List Value) : List (Prod Value Nat) :=
  psBackendSourceZipIndexAcc values 0 List.nil

def psBackendSourceFlatMapAcc {A B : Type} (convert : A -> List B)
    (values : List A) (reversed : List B) : List B :=
  match values with
  | List.nil => psListReverse reversed
  | List.cons value rest =>
      psBackendSourceFlatMapAcc convert rest (psListReverseAcc (convert value) reversed)

def psBackendSourceFlatMap {A B : Type} (convert : A -> List B) (values : List A) : List B :=
  psBackendSourceFlatMapAcc convert values List.nil

def psBackendSourceArgs1 {A Value : Type}
    (action : A -> Value) (failure : Value)
    (arguments : List A) : Value :=
  match arguments with
  | List.nil => failure
  | List.cons arg0 rest0 =>
    if psListIsEmpty rest0 then action arg0 else failure

def psBackendSourceArgs2 {A Value : Type}
    (action : A -> A -> Value) (failure : Value)
    (arguments : List A) : Value :=
  match arguments with
  | List.nil => failure
  | List.cons arg0 rest0 =>
    match rest0 with
    | List.nil => failure
    | List.cons arg1 rest1 =>
      if psListIsEmpty rest1 then action arg0 arg1 else failure

def psBackendSourceArgs3 {A Value : Type}
    (action : A -> A -> A -> Value) (failure : Value)
    (arguments : List A) : Value :=
  match arguments with
  | List.nil => failure
  | List.cons arg0 rest0 =>
    match rest0 with
    | List.nil => failure
    | List.cons arg1 rest1 =>
      match rest1 with
      | List.nil => failure
      | List.cons arg2 rest2 =>
        if psListIsEmpty rest2 then action arg0 arg1 arg2 else failure

def psBackendSourceArgs5 {A Value : Type}
    (action : A -> A -> A -> A -> A -> Value) (failure : Value)
    (arguments : List A) : Value :=
  match arguments with
  | List.nil => failure
  | List.cons arg0 rest0 =>
    match rest0 with
    | List.nil => failure
    | List.cons arg1 rest1 =>
      match rest1 with
      | List.nil => failure
      | List.cons arg2 rest2 =>
        match rest2 with
        | List.nil => failure
        | List.cons arg3 rest3 =>
          match rest3 with
          | List.nil => failure
          | List.cons arg4 rest4 =>
            if psListIsEmpty rest4 then action arg0 arg1 arg2 arg3 arg4 else failure
