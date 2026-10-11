import Ps.BackendRust.Type

def psRustStringListContains (values : List String) (name : String) : Bool :=
  values.contains name

def psRustAddParameterNames (ps : List PsVerifiedIrParameter) (names : List String) : List String :=
  ps.map (·.name) ++ names

def psRustAddBindingNames (bs : List PsVerifiedIrMatchBinding) (names : List String) : List String :=
  bs.map (·.name) ++ names


def psRustListFoldl {alpha beta : Type}
    (step : beta -> alpha -> beta) (values : List alpha) : beta -> beta :=
  match values with
  | List.nil => fun (state : beta) => state
  | List.cons value rest =>
      let smaller : beta -> beta := psRustListFoldl step rest;
      fun (state : beta) => smaller (step state value)

def psRustAppendCaptureForName
    (outerNames boundNames captures : List String) (name : String) : List String :=
  if psRustStringListContains boundNames name then captures
  else if psRustStringListContains captures name then captures
  else if psRustStringListContains outerNames name then
    psListAppend captures (List.cons name List.nil)
  else captures

def psRustParameterNames (parameters : List PsVerifiedIrParameter) : List String :=
  psRustAddParameterNames parameters List.nil

def psRustMatchBindingNames (bindings : List PsVerifiedIrMatchBinding) : List String :=
  psRustAddBindingNames bindings List.nil

/- Fuel exhaustion conservatively captures all outer locals. Expression emission
   separately fails closed at the same depth, so no missing capture is accepted. -/
def psRustCollectCapturesWorker
    (outerNames : List String)
    (remainingFuel : Nat) :
    List String ->
    PsVerifiedIrExpr ->
    List String ->
    List String :=
  match remainingFuel with
  | 0 =>
      fun (_boundNames : List String) =>
        fun (_expr : PsVerifiedIrExpr) =>
          fun (captures : List String) =>
            outerNames
  | fuel + 1 =>
      let smaller :
          List String ->
          PsVerifiedIrExpr ->
          List String ->
          List String :=
        psRustCollectCapturesWorker
          outerNames
          fuel;
      fun (boundNames : List String) =>
        fun (expr : PsVerifiedIrExpr) =>
          fun (captures : List String) =>
            let collect :
                PsVerifiedIrExpr ->
                List String ->
                List String :=
              fun
                (nested : PsVerifiedIrExpr)
                (state : List String) =>
                smaller boundNames nested state;
            let collectArgument :
                List String ->
                PsVerifiedIrExpr ->
                List String :=
              fun
                (state : List String)
                (argument : PsVerifiedIrExpr) =>
                collect argument state;
            let collectField :
                List String ->
                (String × PsVerifiedIrExpr) ->
                List String :=
              fun
                (state : List String)
                (field : String × PsVerifiedIrExpr) =>
                collect (Prod.snd field) state;
            match expr with
            | .literal _ | .unreachable _ => captures
            | .var name =>
                psRustAppendCaptureForName
                  outerNames
                  boundNames
                  captures
                  name
            | .intrinsic _ _ arguments =>
                psRustListFoldl
                  collectArgument
                  arguments
                  captures
            | .lambda parameters _ body =>
                smaller
                  (psListAppend
                    (psRustParameterNames parameters)
                    boundNames)
                  body
                  captures
            | .call fn _ arguments =>
                let withFn := collect fn captures;
                psRustListFoldl
                  collectArgument
                  arguments
                  withFn
            | .letE name _ value body =>
                let withValue := collect value captures;
                smaller
                  (List.cons name boundNames)
                  body
                  withValue
            | .ifE condition thenBranch elseBranch =>
                let withCondition := collect condition captures;
                let withThen := collect thenBranch withCondition;
                collect elseBranch withThen
            | .record _ _ fields =>
                psRustListFoldl
                  collectField
                  fields
                  captures
            | .projection _ _ target _ =>
                collect target captures
            | .constructor _ _ _ fields =>
                psRustListFoldl
                  collectField
                  fields
                  captures
            | .matchE _ _ scrutinee alternatives =>
                let withScrutinee := collect scrutinee captures;
                let collectAlternative :
                    List String ->
                    (String ×
                      List PsVerifiedIrMatchBinding ×
                      PsVerifiedIrExpr) ->
                    List String :=
                  fun
                    (state : List String)
                    (alternative :
                      String ×
                        List PsVerifiedIrMatchBinding ×
                        PsVerifiedIrExpr) =>
                    let matchBindings :=
                      Prod.fst (Prod.snd alternative);
                    let body :=
                      Prod.snd (Prod.snd alternative);
                    smaller
                      (psListAppend
                        (psRustMatchBindingNames matchBindings)
                        boundNames)
                      body
                      state;
                psRustListFoldl
                  collectAlternative
                  alternatives
                  withScrutinee

