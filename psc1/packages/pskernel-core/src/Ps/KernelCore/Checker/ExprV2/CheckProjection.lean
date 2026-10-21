import Ps.KernelCore.Checker.ExprV2.CheckProjectionHelpers

/-
The scalar environment establishes projection shape and constructor kind.
The single operation-owned declaration table supplies the constructor type ID.
Entries absent from that admitted table request whole-operation fallback; no
recursive type is converted from the original environment inside inference.
-/
structure PsKernelExprV2CheckProjectionView where
  inductName : PsKernelName
  levels : List PsKernelLevel
  args : List Nat
  numParams : Nat
  ctorEntry : PsKernelConstantInfo

def psKernelExprV2CheckProjectionConstructor
    (context : PsKernelCheckerContext)
    (inductName : PsKernelName) (levels : List PsKernelLevel)
    (args : List Nat) (numParams : Nat) (ctorName : PsKernelName) :
    Except String PsKernelExprV2CheckProjectionView :=
  match psKernelEnvironmentFind context.environment ctorName with
  | Option.none => Except.error "invalid projection: constructor metadata missing"
  | Option.some info =>
      match info with
      | PsKernelConstantInfo.ctorInfo _ =>
          Except.ok
            (PsKernelExprV2CheckProjectionView.mk
              inductName levels args numParams info)
      | _ => Except.error "invalid projection: constructor metadata missing"

def psKernelExprV2CheckProjectionViewOnCanonical
    (context : PsKernelCheckerContext) (arena : PsKernelExprV2PagedArena)
    (typeName : PsKernelName) (index type : Nat) :
    Except String PsKernelExprV2CheckProjectionView :=
  if psKernelNatGt index psKernelLeanUInt32Max then
    Except.error "invalid projection index"
  else
    match psKernelExprV2TransformAppSpineOnCanonical arena type with
    | Except.error error => Except.error error
    | Except.ok spine =>
        let args := Prod.snd spine;
        match psKernelExprV2PagedRequire arena (Prod.fst spine) with
        | Except.error error => Except.error error
        | Except.ok entry =>
            match entry.node with
            | PsKernelExprV2Node.const inductName levels =>
                if psKernelNameEq inductName typeName then
                  match psKernelEnvironmentFind context.environment inductName with
                  | Option.none =>
                      Except.error "invalid projection: structure name is not inductive"
                  | Option.some info =>
                      match info with
                      | PsKernelConstantInfo.inductInfo induct =>
                          match induct.ctors with
                          | List.nil =>
                              Except.error
                                "invalid projection: inductive must have exactly one constructor"
                          | List.cons ctorName rest =>
                              match rest with
                              | List.cons _ _ =>
                                  Except.error
                                    "invalid projection: inductive must have exactly one constructor"
                              | List.nil =>
                                  if Nat.beq
                                      (psKernelExprV2TransformNatLength args)
                                      (Nat.add induct.numParams induct.numIndices) then
                                    psKernelExprV2CheckProjectionConstructor context
                                      inductName levels args induct.numParams ctorName
                                  else
                                    Except.error "invalid projection: inductive type is not fully applied"
                      | _ =>
                          Except.error "invalid projection: structure name is not inductive"
                else Except.error "invalid projection: structure type mismatch"
            | _ =>
                Except.error "invalid projection: projected expression type is not an inductive application"

def psKernelExprV2CheckProjectionFinalWith
    (check : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (propType : Bool) (current : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match psKernelExprV2CheckProjectionWhnfWith whnf context state current with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok result =>
          let next := Prod.fst result;
          match psKernelExprV2PagedRequire next.whnf.arena (Prod.snd result) with
          | Except.error error => Option.some (Except.error error)
          | Except.ok entry =>
              match entry.node with
              | PsKernelExprV2Node.forallE _ domain _ _ =>
                  if propType then
                    match psKernelExprV2CheckProjectionIsPropWith
                        check whnf context next domain with
                    | Option.none => Option.none
                    | Option.some attemptedProp =>
                        match attemptedProp with
                        | Except.error error => Option.some (Except.error error)
                        | Except.ok domainProp =>
                            if Prod.snd domainProp then
                              Option.some
                                (Except.ok (Prod.mk (Prod.fst domainProp) domain))
                            else
                              Option.some
                                (Except.error
                                  "invalid projection: proof structure field is not a proposition")
                  else Option.some (Except.ok (Prod.mk next domain))
              | _ => Option.some (Except.error "invalid projection index")

def psKernelExprV2CheckProjectionFieldsWith
    (check : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState)
    (view : PsKernelExprV2CheckProjectionView)
    (type structValue index initial : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match psKernelExprV2CheckProjectionApplyParamsWithFuel
      (Nat.succ view.numParams) whnf context state
      view.args 0 view.numParams initial with
  | Option.none => Option.none
  | Option.some attemptedParams =>
      match attemptedParams with
      | Except.error error => Option.some (Except.error error)
      | Except.ok params =>
          match psKernelExprV2CheckProjectionIsPropWith
              check whnf context (Prod.fst params) type with
          | Option.none => Option.none
          | Option.some attemptedProp =>
              match attemptedProp with
              | Except.error error => Option.some (Except.error error)
              | Except.ok propResult =>
                  match psKernelExprV2CheckProjectionSkipFieldsWithFuel
                      (Nat.succ index) check whnf context (Prod.fst propResult)
                      view.inductName structValue (Prod.snd propResult)
                      index 0 (Prod.snd params) with
                  | Option.none => Option.none
                  | Option.some attemptedFields =>
                      match attemptedFields with
                      | Except.error error => Option.some (Except.error error)
                      | Except.ok fields =>
                          psKernelExprV2CheckProjectionFinalWith check whnf context
                            (Prod.fst fields) (Prod.snd propResult) (Prod.snd fields)

def psKernelExprV2CheckProjectionFromViewWith
    (check : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState)
    (view : PsKernelExprV2CheckProjectionView) (type structValue index : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match view.ctorEntry with
  | PsKernelConstantInfo.ctorInfo ctor =>
      match psKernelExprV2DeclarationRefFind state.whnf.declarations ctor.base.name with
      | Option.none => Option.none
      | Option.some declaration =>
          if psKernelExprV2DeclarationRefMatches declaration view.ctorEntry then
            match psKernelExprV2TransformOnCanonical
                (PsKernelExprV2Transform.levels declaration.levelParams view.levels)
                state.whnf.arena declaration.type 0 with
            | Except.error error => Option.some (Except.error error)
            | Except.ok instantiated =>
                psKernelExprV2CheckProjectionFieldsWith check whnf context
                  (psKernelExprV2CheckStateWithArena state (Prod.fst instantiated))
                  view type structValue index (Prod.snd instantiated)
          else Option.none
  | _ => Option.some (Except.error "invalid projection: constructor metadata missing")

def psKernelExprV2CheckProjectionInferWith
    (check : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState)
    (typeName : PsKernelName) (index structValue : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match check context state structValue with
  | Option.none => Option.none
  | Option.some attemptedStruct =>
      match attemptedStruct with
      | Except.error error => Option.some (Except.error error)
      | Except.ok structResult =>
          match psKernelExprV2CheckProjectionWhnfWith
              whnf context (Prod.fst structResult) (Prod.snd structResult) with
          | Option.none => Option.none
          | Option.some attemptedType =>
              match attemptedType with
              | Except.error error => Option.some (Except.error error)
              | Except.ok typeResult =>
                  let next := Prod.fst typeResult;
                  match psKernelExprV2CheckProjectionViewOnCanonical
                      context.scalar next.whnf.arena typeName index (Prod.snd typeResult) with
                  | Except.error error => Option.some (Except.error error)
                  | Except.ok view =>
                      psKernelExprV2CheckProjectionFromViewWith
                        check whnf context next view (Prod.snd typeResult) structValue index

def psKernelExprV2CheckProjectionWith
    (check : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (whnf : PsKernelCheckerContext -> PsKernelExprV2WhnfState -> Nat ->
      Option (Except String (Prod PsKernelExprV2WhnfState Nat)))
    (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState)
    (root : Nat) (typeName : PsKernelName) (index structValue : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  psKernelExprV2CheckFinishAttempt root
    (psKernelExprV2CheckProjectionInferWith
      check whnf context state typeName index structValue)
