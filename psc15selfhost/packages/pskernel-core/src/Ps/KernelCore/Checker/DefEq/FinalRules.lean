import Ps.KernelCore.Checker.DefEq.LazyDelta

/-
Lean 4.34 final algorithmic-defeq rules.

PSK-DEFEQ-PROOF:
  proposition detection used by proof irrelevance.
  Lean: src/kernel/type_checker.cpp::is_def_eq_proof_irrel

PSK-DEFEQ-STRUCTETA:
  constructor/projection eta for non-recursive structures.
  Lean: src/kernel/type_checker.cpp::try_eta_struct

PSK-DEFEQ-STRING:
  String literal <-> String.ofList constructor expansion.
  Lean: src/kernel/type_checker.cpp::try_string_lit_expansion

PSK-DEFEQ-UNIT:
  fieldless non-recursive structure equality.
  Lean: src/kernel/type_checker.cpp::is_def_eq_unit_like

These are algorithmic rules. Their order is observable because Lean
algorithmic definitional equality is intentionally incomplete and
non-transitive.
-/

def psKernelDefEqIsPropWith
    (inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr) :
    Except String
      (Prod Bool PsKernelCheckerState) :=
  match inferType context state expr with
  | Except.error error =>
      Except.error error
  | Except.ok typeResult =>
      match
          whnf
            context
            (Prod.snd typeResult)
            (Prod.fst typeResult) with
      | Except.error error =>
          Except.error error
      | Except.ok reducedResult =>
          match Prod.fst reducedResult with
          | PsKernelExpr.sort level =>
              Except.ok
                (Prod.mk
                  (psKernelLevelNormalizesToZero level)
                  (Prod.snd reducedResult))
          | _ =>
              Except.error "expected sort"

def psKernelDefEqEtaStructFieldsWithFuel
    (fuel : Nat) :
    (PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState)) ->
    PsKernelCheckerContext ->
    PsKernelCheckerState ->
    PsKernelName ->
    PsKernelExpr ->
    List PsKernelExpr ->
    Nat ->
    Nat ->
    Except String
      (Prod Bool PsKernelCheckerState) :=
  match fuel with
  | Nat.zero =>
      fun
        (_defeq :
          PsKernelCheckerContext ->
          PsKernelCheckerState ->
          PsKernelExpr ->
          PsKernelExpr ->
          Except String
            (Prod Bool PsKernelCheckerState))
        (_context : PsKernelCheckerContext)
        (_state : PsKernelCheckerState)
        (_induct : PsKernelName)
        (_term : PsKernelExpr)
        (_args : List PsKernelExpr)
        (_numParams : Nat)
        (_index : Nat) =>
        Except.error
          "kernel structure eta budget exhausted"
  | Nat.succ remaining =>
      let smaller :=
        psKernelDefEqEtaStructFieldsWithFuel remaining;
      fun
        (defeq :
          PsKernelCheckerContext ->
          PsKernelCheckerState ->
          PsKernelExpr ->
          PsKernelExpr ->
          Except String
            (Prod Bool PsKernelCheckerState))
        (context : PsKernelCheckerContext)
        (state : PsKernelCheckerState)
        (induct : PsKernelName)
        (term : PsKernelExpr)
        (args : List PsKernelExpr)
        (numParams : Nat)
        (index : Nat) =>
        let fieldCount :=
          Nat.sub
            (psKernelExprListLength args)
            numParams;
        if psKernelNatLt index fieldCount then
          match
              psKernelExprListGet
                args
                (Nat.add
                  numParams
                  index) with
          | Option.none =>
              Except.ok
                (Prod.mk false state)
          | Option.some arg =>
              match
                  defeq
                    context
                    state
                    (PsKernelExpr.proj
                      induct
                      index
                      term)
                    arg with
              | Except.error error =>
                  Except.error error
              | Except.ok result =>
                  if Prod.fst result then
                    smaller
                      defeq
                      context
                      (Prod.snd result)
                      induct
                      term
                      args
                      numParams
                      (Nat.succ index)
                  else
                    Except.ok result
        else
          Except.ok
            (Prod.mk true state)

def psKernelDefEqEtaStructCoreWith
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState))
    (inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (term : PsKernelExpr)
    (structureValue : PsKernelExpr) :
    Except String
      (Prod Bool PsKernelCheckerState) :=
  let fn :=
    psKernelExprGetAppFn structureValue;
  let args :=
    psKernelExprGetAppArgs structureValue;
  match fn with
  | PsKernelExpr.const ctorName _ =>
      match
          psKernelEnvironmentFind
            context.environment
            ctorName with
      | Option.some info =>
          match info with
          | PsKernelConstantInfo.ctorInfo ctor =>
              if
                  Nat.beq
                    (psKernelExprListLength args)
                    (Nat.add
                      ctor.numParams
                      ctor.numFields) then
                if
                    psKernelEnvironmentIsNonRecStructure
                      context.environment
                      ctor.induct then
                  match inferType context state term with
                  | Except.error error =>
                      Except.error error
                  | Except.ok termType =>
                      match
                          inferType
                            context
                            (Prod.snd termType)
                            structureValue with
                      | Except.error error =>
                          Except.error error
                      | Except.ok structureType =>
                          match
                              defeq
                                context
                                (Prod.snd structureType)
                                (Prod.fst termType)
                                (Prod.fst structureType) with
                          | Except.error error =>
                              Except.error error
                          | Except.ok typesEqual =>
                              if Prod.fst typesEqual then
                                psKernelDefEqEtaStructFieldsWithFuel
                                  (Nat.succ ctor.numFields)
                                  defeq
                                  context
                                  (Prod.snd typesEqual)
                                  ctor.induct
                                  term
                                  args
                                  ctor.numParams
                                  0
                              else
                                Except.ok typesEqual
                else
                  Except.ok
                    (Prod.mk false state)
              else
                Except.ok
                  (Prod.mk false state)
          | _ =>
              Except.ok
                (Prod.mk false state)
      | Option.none =>
          Except.ok
            (Prod.mk false state)
  | _ =>
      Except.ok
        (Prod.mk false state)

def psKernelDefEqEtaStructWith
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState))
    (inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left : PsKernelExpr)
    (right : PsKernelExpr) :
    Except String
      (Prod Bool PsKernelCheckerState) :=
  match
      psKernelDefEqEtaStructCoreWith
        defeq
        inferType
        context
        state
        left
        right with
  | Except.error error =>
      Except.error error
  | Except.ok first =>
      if Prod.fst first then
        Except.ok first
      else
        psKernelDefEqEtaStructCoreWith
          defeq
          inferType
          context
          (Prod.snd first)
          right
          left

def psKernelDefEqStringLitExpansionCoreWith
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState))
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left : PsKernelExpr)
    (right : PsKernelExpr) :
    Except String
      (Prod
        (Option Bool)
        PsKernelCheckerState) :=
  match left with
  | PsKernelExpr.lit literal =>
      match literal with
      | PsKernelLiteral.str value =>
          if psKernelExprIsStringOfListApp right then
            match
                whnf
                  context
                  state
                  (psKernelStringLitToConstructor value) with
            | Except.error error =>
                Except.error error
            | Except.ok expanded =>
                match
                    defeq
                      context
                      (Prod.snd expanded)
                      (Prod.fst expanded)
                      right with
                | Except.error error =>
                    Except.error error
                | Except.ok result =>
                    Except.ok
                      (Prod.mk
                        (Option.some
                          (Prod.fst result))
                        (Prod.snd result))
          else
            Except.ok
              (Prod.mk Option.none state)
      | _ =>
          Except.ok
            (Prod.mk Option.none state)
  | _ =>
      Except.ok
        (Prod.mk Option.none state)

def psKernelDefEqStringLitExpansionWith
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState))
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left : PsKernelExpr)
    (right : PsKernelExpr) :
    Except String
      (Prod
        (Option Bool)
        PsKernelCheckerState) :=
  match
      psKernelDefEqStringLitExpansionCoreWith
        defeq
        whnf
        context
        state
        left
        right with
  | Except.error error =>
      Except.error error
  | Except.ok first =>
      match Prod.fst first with
      | Option.some value =>
          Except.ok
            (Prod.mk
              (Option.some value)
              (Prod.snd first))
      | Option.none =>
          psKernelDefEqStringLitExpansionCoreWith
            defeq
            whnf
            context
            (Prod.snd first)
            right
            left

def psKernelDefEqUnitLikeWith
    (defeq :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      PsKernelExpr ->
      Except String
        (Prod Bool PsKernelCheckerState))
    (inferType :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (whnf :
      PsKernelCheckerContext ->
      PsKernelCheckerState ->
      PsKernelExpr ->
      Except String
        (Prod PsKernelExpr PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left : PsKernelExpr)
    (right : PsKernelExpr) :
    Except String
      (Prod Bool PsKernelCheckerState) :=
  match inferType context state left with
  | Except.error error =>
      Except.error error
  | Except.ok leftTypeResult =>
      match
          whnf
            context
            (Prod.snd leftTypeResult)
            (Prod.fst leftTypeResult) with
      | Except.error error =>
          Except.error error
      | Except.ok reducedTypeResult =>
          let reducedType :=
            Prod.fst reducedTypeResult;
          match psKernelExprGetAppFn reducedType with
          | PsKernelExpr.const inductName _ =>
              if
                  psKernelEnvironmentIsNonRecStructure
                    context.environment
                    inductName then
                match
                    psKernelEnvironmentFind
                      context.environment
                      inductName with
                | Option.some info =>
                    match info with
                    | PsKernelConstantInfo.inductInfo inductInfo =>
                        match inductInfo.ctors with
                        | List.cons ctorName ctorTail =>
                            match ctorTail with
                            | List.nil =>
                                match
                                    psKernelEnvironmentFind
                                      context.environment
                                      ctorName with
                                | Option.some ctorValue =>
                                    match ctorValue with
                                    | PsKernelConstantInfo.ctorInfo ctor =>
                                        if Nat.beq ctor.numFields 0 then
                                          match
                                              inferType
                                                context
                                                (Prod.snd reducedTypeResult)
                                                right with
                                          | Except.error error =>
                                              Except.error error
                                          | Except.ok rightTypeResult =>
                                              defeq
                                                context
                                                (Prod.snd rightTypeResult)
                                                reducedType
                                                (Prod.fst rightTypeResult)
                                        else
                                          Except.ok
                                            (Prod.mk
                                              false
                                              (Prod.snd reducedTypeResult))
                                    | _ =>
                                        Except.ok
                                          (Prod.mk
                                            false
                                            (Prod.snd reducedTypeResult))
                                | Option.none =>
                                    Except.ok
                                      (Prod.mk
                                        false
                                        (Prod.snd reducedTypeResult))
                            | List.cons _ _ =>
                                Except.ok
                                  (Prod.mk
                                    false
                                    (Prod.snd reducedTypeResult))
                        | List.nil =>
                            Except.ok
                              (Prod.mk
                                false
                                (Prod.snd reducedTypeResult))
                    | _ =>
                        Except.ok
                          (Prod.mk
                            false
                            (Prod.snd reducedTypeResult))
                | Option.none =>
                    Except.ok
                      (Prod.mk
                        false
                        (Prod.snd reducedTypeResult))
              else
                Except.ok
                  (Prod.mk
                    false
                    (Prod.snd reducedTypeResult))
          | _ =>
              Except.ok
                (Prod.mk
                  false
                  (Prod.snd reducedTypeResult))
