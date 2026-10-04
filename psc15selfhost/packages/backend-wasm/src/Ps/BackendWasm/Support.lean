import Ps.BackendWasm.Model

def psWasmListMap {Alpha Beta : Type}
    (convert : Alpha -> Beta)
    (values : List Alpha) :
    List Beta :=
  match values with
  | List.nil =>
      List.nil
  | List.cons value rest =>
      List.cons
        (convert value)
        (psWasmListMap convert rest)

def psWasmListAny {Alpha : Type}
    (predicate : Alpha -> Bool)
    (values : List Alpha) :
    Bool :=
  match values with
  | List.nil =>
      false
  | List.cons value rest =>
      if predicate value then
        true
      else
        psWasmListAny predicate rest

def psWasmListFoldl {Alpha State : Type}
    (step : State -> Alpha -> State)
    (values : List Alpha)
    (state : State) :
    State :=
  match values with
  | List.nil =>
      state
  | List.cons value rest =>
      psWasmListFoldl
        step
        rest
        (step state value)
