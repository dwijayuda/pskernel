import Ps.BackendCommon.StateExcept
import Ps.BackendCommon.Source

namespace PsBackendStateReference

theorem pure_exact {State Error Value : Type} (value : Value) :
    psBackendStatePure (State := State) (Error := Error) value =
      (pure value : StateT State (Except Error) Value) := by
  rfl

theorem bind_exact {State Error A B : Type}
    (action : StateT State (Except Error) A)
    (next : A -> StateT State (Except Error) B) :
    psBackendStateBind action next = (action >>= next) := by
  funext state
  change (match action state with
    | Except.error error => Except.error error
    | Except.ok pair => next pair.fst pair.snd) =
    (do
      let (value, nextState) <- action state
      next value nextState)
  cases action state with
  | error error => rfl
  | ok pair =>
      cases pair
      rfl

theorem get_exact {State Error : Type} :
    psBackendStateGet (State := State) (Error := Error) () =
      (get : StateT State (Except Error) State) := by
  rfl

theorem set_exact {State Error : Type} (value : State) :
    psBackendStateSet (Error := Error) value =
      (set value : StateT State (Except Error) Unit) := by
  rfl

theorem modify_exact {State Error : Type} (update : State -> State) :
    psBackendStateModify (Error := Error) update =
      (modify update : StateT State (Except Error) Unit) := by
  rfl

theorem throw_exact {State Error Value : Type} (error : Error) :
    psBackendStateThrow (State := State) (Value := Value) error =
      (throw error : StateT State (Except Error) Value) := by
  rfl

theorem lift_exact {State Error Value : Type} (action : Except Error Value) :
    psBackendStateLift (State := State) action =
      (fun state => do
        let value <- action
        pure (value, state) : StateT State (Except Error) Value) := by
  rfl

end PsBackendStateReference

theorem psBackendSourceArgs1_exact {A Value : Type}
    (action : A -> Value) (failure : Value)
    (arguments : List A) :
    psBackendSourceArgs1 action failure arguments =
      (match arguments with
      | [arg0] => action arg0
      | _ => failure) := by
  cases arguments with
  | nil => rfl
  | cons arg0 rest0 =>
      cases rest0 with
      | nil => rfl
      | cons extra rest => rfl

theorem psBackendSourceArgs2_exact {A Value : Type}
    (action : A -> A -> Value) (failure : Value)
    (arguments : List A) :
    psBackendSourceArgs2 action failure arguments =
      (match arguments with
      | [arg0, arg1] => action arg0 arg1
      | _ => failure) := by
  cases arguments with
  | nil => rfl
  | cons arg0 rest0 =>
      cases rest0 with
      | nil => rfl
      | cons arg1 rest1 =>
          cases rest1 with
          | nil => rfl
          | cons extra rest => rfl

theorem psBackendSourceArgs3_exact {A Value : Type}
    (action : A -> A -> A -> Value) (failure : Value)
    (arguments : List A) :
    psBackendSourceArgs3 action failure arguments =
      (match arguments with
      | [arg0, arg1, arg2] => action arg0 arg1 arg2
      | _ => failure) := by
  cases arguments with
  | nil => rfl
  | cons arg0 rest0 =>
      cases rest0 with
      | nil => rfl
      | cons arg1 rest1 =>
          cases rest1 with
          | nil => rfl
          | cons arg2 rest2 =>
              cases rest2 with
              | nil => rfl
              | cons extra rest => rfl

theorem psBackendSourceArgs5_exact {A Value : Type}
    (action : A -> A -> A -> A -> A -> Value) (failure : Value)
    (arguments : List A) :
    psBackendSourceArgs5 action failure arguments =
      (match arguments with
      | [arg0, arg1, arg2, arg3, arg4] => action arg0 arg1 arg2 arg3 arg4
      | _ => failure) := by
  cases arguments with
  | nil => rfl
  | cons arg0 rest0 =>
      cases rest0 with
      | nil => rfl
      | cons arg1 rest1 =>
          cases rest1 with
          | nil => rfl
          | cons arg2 rest2 =>
              cases rest2 with
              | nil => rfl
              | cons arg3 rest3 =>
                  cases rest3 with
                  | nil => rfl
                  | cons arg4 rest4 =>
                      cases rest4 with
                      | nil => rfl
                      | cons extra rest => rfl
