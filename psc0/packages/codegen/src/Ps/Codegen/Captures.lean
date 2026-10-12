import Ps.CompilerIr.Model
import Ps.Foundation.List

def psCodegenStringListContains (values : List String) (name : String) : Bool :=
  values.contains name

def psCodegenAddParameterNames (ps : List PsVerifiedIrParameter) (names : List String) : List String :=
  ps.map (·.name) ++ names

def psCodegenAddBindingNames (bs : List PsVerifiedIrMatchBinding) (names : List String) : List String :=
  bs.map (·.name) ++ names


def psCodegenListFoldl {alpha beta : Type}
    (step : beta -> alpha -> beta) (values : List alpha) : beta -> beta :=
  match values with
  | List.nil => fun (state : beta) => state
  | List.cons value rest =>
      let smaller : beta -> beta := psCodegenListFoldl step rest;
      fun (state : beta) => smaller (step state value)

def psCodegenAppendCaptureForName
    (outerNames boundNames captures : List String) (name : String) : List String :=
  if psCodegenStringListContains boundNames name then captures
  else if psCodegenStringListContains captures name then captures
  else if psCodegenStringListContains outerNames name then
    psListAppend captures (List.cons name List.nil)
  else captures

def psCodegenParameterNames (parameters : List PsVerifiedIrParameter) : List String :=
  psCodegenAddParameterNames parameters List.nil

def psCodegenMatchBindingNames (bindings : List PsVerifiedIrMatchBinding) : List String :=
  psCodegenAddBindingNames bindings List.nil

/- Fuel exhaustion conservatively captures all outer locals. Expression emission
   separately fails closed at the same depth, so no missing capture is accepted. -/
def psCodegenCollectCapturesWorker
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
        psCodegenCollectCapturesWorker
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
            | .literal _ | .unreachable _ | .panic .. => captures
            | .var name =>
                psCodegenAppendCaptureForName
                  outerNames
                  boundNames
                  captures
                  name
            | .intrinsic _ _ arguments =>
                psCodegenListFoldl
                  collectArgument
                  arguments
                  captures
            | .lambda parameters _ body =>
                smaller
                  (psListAppend
                    (psCodegenParameterNames parameters)
                    boundNames)
                  body
                  captures
            | .call fn _ arguments =>
                let withFn := collect fn captures;
                psCodegenListFoldl
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
                psCodegenListFoldl
                  collectField
                  fields
                  captures
            | .projection _ _ target _ =>
                collect target captures
            | .constructor _ _ _ fields =>
                psCodegenListFoldl
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
                        (psCodegenMatchBindingNames matchBindings)
                        boundNames)
                      body
                      state;
                psCodegenListFoldl
                  collectAlternative
                  alternatives
                  withScrutinee

