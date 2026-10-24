import Ps.BackendCommon.StateExcept

namespace PsBackendStateReference

theorem pure_exact {State Error Value : Type} (value : Value) :
    psBackendStatePure (State := State) (Error := Error) value =
      (pure value : StateT State (Except Error) Value) := by
  rfl

theorem bind_exact {State Error A B : Type}
    (action : StateT State (Except Error) A)
    (next : A -> StateT State (Except Error) B) :
    psBackendStateBind action next = (action >>= next) := by
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
