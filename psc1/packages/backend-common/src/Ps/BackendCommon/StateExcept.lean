-- Portable normal form for the emitters' existing StateT (Except Error).
-- No instance search, host effects, new trust or changes to state/error order.
def PsBackendStateExcept (State Error Value : Type) : Type :=
  State -> Except Error (Prod Value State)

def psBackendStatePure {State Error Value : Type}
    (value : Value) (state : State) : Except Error (Prod Value State) :=
  Except.ok (Prod.mk value state)

def psBackendStateBind {State Error A B : Type}
    (action : PsBackendStateExcept State Error A)
    (next : A -> PsBackendStateExcept State Error B)
    (state : State) : Except Error (Prod B State) :=
  match action state with
  | Except.error error => Except.error error
  | Except.ok pair => next pair.fst pair.snd

def psBackendStateLift {State Error Value : Type}
    (action : Except Error Value) (state : State) : Except Error (Prod Value State) :=
  match action with
  | Except.error error => Except.error error
  | Except.ok value => Except.ok (Prod.mk value state)

def psBackendStateGet {State Error : Type}
    (_unit : Unit) (state : State) : Except Error (Prod State State) :=
  Except.ok (Prod.mk state state)

def psBackendStateSet {State Error : Type}
    (value : State) (_state : State) : Except Error (Prod Unit State) :=
  Except.ok (Prod.mk Unit.unit value)

def psBackendStateModify {State Error : Type}
    (update : State -> State) (state : State) : Except Error (Prod Unit State) :=
  Except.ok (Prod.mk Unit.unit (update state))

def psBackendStateThrow {State Error Value : Type}
    (error : Error) (_state : State) : Except Error (Prod Value State) :=
  Except.error error
