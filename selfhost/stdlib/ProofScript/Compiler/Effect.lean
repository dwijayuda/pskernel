import ProofScript.Data.Prod
import ProofScript.Data.Result

structure CompilerM
    (Context : Type)
    (State : Type)
    (Error : Type)
    (Value : Type) where
  run : Context -> State -> Result (Prod Value State) Error

def compilerPureRun
    {Context : Type} {State : Type} {Error : Type} {Value : Type}
    (value : Value)
    (context : Context)
    (state : State) : Result (Prod Value State) Error :=
  Result.ok (Prod.mk value state)

def compilerPure
    {Context : Type} {State : Type} {Error : Type} {Value : Type}
    (value : Value) : CompilerM Context State Error Value :=
  CompilerM.mk (compilerPureRun value)

def compilerBindRun
    {Context : Type} {State : Type} {Error : Type}
    {A : Type} {B : Type}
    (value : CompilerM Context State Error A)
    (next : A -> CompilerM Context State Error B)
    (context : Context)
    (state : State) : Result (Prod B State) Error :=
  match value.run context state with
  | Result.error error => Result.error error
  | Result.ok pair =>
      let continuation : CompilerM Context State Error B :=
        next pair.fst
      continuation.run context pair.snd

def compilerBind
    {Context : Type} {State : Type} {Error : Type}
    {A : Type} {B : Type}
    (value : CompilerM Context State Error A)
    (next : A -> CompilerM Context State Error B) :
    CompilerM Context State Error B :=
  CompilerM.mk (compilerBindRun value next)

def compilerReadRun
    {Context : Type} {State : Type} {Error : Type}
    (unit : Unit)
    (context : Context)
    (state : State) : Result (Prod Context State) Error :=
  Result.ok (Prod.mk context state)

def compilerRead
    {Context : Type} {State : Type} {Error : Type}
    (unit : Unit) : CompilerM Context State Error Context :=
  CompilerM.mk (compilerReadRun unit)

def compilerGetRun
    {Context : Type} {State : Type} {Error : Type}
    (unit : Unit)
    (context : Context)
    (state : State) : Result (Prod State State) Error :=
  Result.ok (Prod.mk state state)

def compilerGet
    {Context : Type} {State : Type} {Error : Type}
    (unit : Unit) : CompilerM Context State Error State :=
  CompilerM.mk (compilerGetRun unit)

def compilerSetRun
    {Context : Type} {State : Type} {Error : Type}
    (nextState : State)
    (context : Context)
    (state : State) : Result (Prod Unit State) Error :=
  Result.ok (Prod.mk Unit.unit nextState)

def compilerSet
    {Context : Type} {State : Type} {Error : Type}
    (nextState : State) : CompilerM Context State Error Unit :=
  CompilerM.mk (compilerSetRun nextState)

def compilerModifyRun
    {Context : Type} {State : Type} {Error : Type}
    (update : State -> State)
    (context : Context)
    (state : State) : Result (Prod Unit State) Error :=
  Result.ok (Prod.mk Unit.unit (update state))

def compilerModify
    {Context : Type} {State : Type} {Error : Type}
    (update : State -> State) : CompilerM Context State Error Unit :=
  CompilerM.mk (compilerModifyRun update)

def compilerThrowRun
    {Context : Type} {State : Type} {Error : Type} {Value : Type}
    (error : Error)
    (context : Context)
    (state : State) : Result (Prod Value State) Error :=
  Result.error error

def compilerThrow
    {Context : Type} {State : Type} {Error : Type} {Value : Type}
    (error : Error) : CompilerM Context State Error Value :=
  CompilerM.mk (compilerThrowRun error)

def compilerTryCatchRun
    {Context : Type} {State : Type} {Error : Type} {Value : Type}
    (value : CompilerM Context State Error Value)
    (handler : Error -> CompilerM Context State Error Value)
    (context : Context)
    (state : State) : Result (Prod Value State) Error :=
  match value.run context state with
  | Result.ok pair => Result.ok pair
  | Result.error error =>
      let recovery : CompilerM Context State Error Value :=
        handler error
      recovery.run context state

def compilerTryCatch
    {Context : Type} {State : Type} {Error : Type} {Value : Type}
    (value : CompilerM Context State Error Value)
    (handler : Error -> CompilerM Context State Error Value) :
    CompilerM Context State Error Value :=
  CompilerM.mk (compilerTryCatchRun value handler)

def compilerRollbackRun
    {Context : Type} {State : Type} {Error : Type} {Value : Type}
    (value : CompilerM Context State Error Value)
    (handler : Error -> CompilerM Context State Error Value)
    (context : Context)
    (state : State) : Result (Prod Value State) Error :=
  match value.run context state with
  | Result.ok pair => Result.ok pair
  | Result.error error =>
      let recovery : CompilerM Context State Error Value :=
        handler error
      recovery.run context state

def compilerRollback
    {Context : Type} {State : Type} {Error : Type} {Value : Type}
    (value : CompilerM Context State Error Value)
    (handler : Error -> CompilerM Context State Error Value) :
    CompilerM Context State Error Value :=
  CompilerM.mk (compilerRollbackRun value handler)

def compilerWithReaderRun
    {Context : Type} {State : Type} {Error : Type} {Value : Type}
    (value : CompilerM Context State Error Value)
    (transform : Context -> Context)
    (context : Context)
    (state : State) : Result (Prod Value State) Error :=
  value.run (transform context) state

def compilerWithReader
    {Context : Type} {State : Type} {Error : Type} {Value : Type}
    (value : CompilerM Context State Error Value)
    (transform : Context -> Context) :
    CompilerM Context State Error Value :=
  CompilerM.mk (compilerWithReaderRun value transform)
