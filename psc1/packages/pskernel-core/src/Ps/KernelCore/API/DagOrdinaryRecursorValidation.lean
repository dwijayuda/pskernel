import Ps.KernelCore.API.DagOrdinaryGenerated

/-
Independent DAG validation of internally generated ordinary recursor rules.
The plan comes from checked header/constructor data, and rule references come
from importing that plan's generated rules into the same canonical owner.
Neither caller-provided rule metadata nor a decoded record is a certificate.

Recursion is on shapes, not fuel. Every RHS Check and DefEq receives the same
supplied fuel. Check succeeds before the expected closed type is constructed
and imported. Import extends only the checked owner's arena/table; all semantic
state survives. The next rule receives the complete DefEq owner. The decoded
table can lag later checker appends; it remains a correct prefix and the top
admission helper synchronizes the final suffix before returning an owner.
-/
def psKernelExprV2OrdinaryValidateRecursorRulesWorker
    (shapes : List PsKernelSimpleConstructorShape) :
    (Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat))) ->
    (Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool))) ->
    (PsKernelSimpleConstructorShape -> PsKernelExprV2CheckState -> PsKernelExprV2Decoded ->
      Except String PsKernelExprV2OrdinaryImported) ->
    Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState ->
    PsKernelExprV2Decoded -> List PsKernelExprV2RecursorRuleRef ->
    Option (Except String PsKernelExprV2OrdinaryRuleState) :=
  match shapes with
  | List.nil =>
      fun
        (_check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
        (_defeq : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Bool)))
        (_expected : PsKernelSimpleConstructorShape -> PsKernelExprV2CheckState ->
          PsKernelExprV2Decoded -> Except String PsKernelExprV2OrdinaryImported)
        (_fuel : Nat) (_context : PsKernelExprV2CheckContext)
        (state : PsKernelExprV2CheckState) (built : PsKernelExprV2Decoded)
        (rules : List PsKernelExprV2RecursorRuleRef) =>
        match rules with
        | List.nil =>
            Option.some (Except.ok (PsKernelExprV2OrdinaryRuleState.mk state built))
        | List.cons _ _ =>
            Option.some (Except.error "generated simple recursor rule count mismatch")
  | List.cons shape rest =>
      let smaller :
          (Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
            Option (Except String (Prod PsKernelExprV2CheckState Nat))) ->
          (Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
            Option (Except String (Prod PsKernelExprV2CheckState Bool))) ->
          (PsKernelSimpleConstructorShape -> PsKernelExprV2CheckState -> PsKernelExprV2Decoded ->
            Except String PsKernelExprV2OrdinaryImported) ->
          Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState ->
          PsKernelExprV2Decoded -> List PsKernelExprV2RecursorRuleRef ->
          Option (Except String PsKernelExprV2OrdinaryRuleState) :=
        psKernelExprV2OrdinaryValidateRecursorRulesWorker rest;
      fun
        (check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Nat)))
        (defeq : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
          Option (Except String (Prod PsKernelExprV2CheckState Bool)))
        (expected : PsKernelSimpleConstructorShape -> PsKernelExprV2CheckState ->
          PsKernelExprV2Decoded -> Except String PsKernelExprV2OrdinaryImported)
        (fuel : Nat) (context : PsKernelExprV2CheckContext)
        (state : PsKernelExprV2CheckState) (built : PsKernelExprV2Decoded)
        (rules : List PsKernelExprV2RecursorRuleRef) =>
        match rules with
        | List.nil =>
            Option.some (Except.error "generated simple recursor rule count mismatch")
        | List.cons rule tail =>
            match check fuel context state rule.rhs with
            | Option.none => Option.none
            | Option.some attemptedCheck =>
                match attemptedCheck with
                | Except.error error => Option.some (Except.error error)
                | Except.ok checked =>
                    match expected shape (Prod.fst checked) built with
                    | Except.error error => Option.some (Except.error error)
                    | Except.ok imported =>
                        match defeq fuel context imported.state (Prod.snd checked) imported.root with
                        | Option.none => Option.none
                        | Option.some attemptedEquality =>
                            match attemptedEquality with
                            | Except.error error => Option.some (Except.error error)
                            | Except.ok equal =>
                                if Prod.snd equal then
                                  smaller check defeq expected fuel context
                                    (Prod.fst equal) imported.built tail
                                else
                                  Option.some
                                    (Except.error
                                      "generated simple recursor rule is not type preserving")

def psKernelExprV2OrdinaryValidateRecursorRulesWith
    (check : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (defeq : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (built : PsKernelExprV2Decoded)
    (plan : PsKernelExprV2OrdinaryRecursorPlan)
    (rules : List PsKernelExprV2RecursorRuleRef) :
    Option (Except String PsKernelExprV2OrdinaryRuleState) :=
  let expected :=
    fun (shape : PsKernelSimpleConstructorShape) (checked : PsKernelExprV2CheckState)
        (decoded : PsKernelExprV2Decoded) =>
      psKernelExprV2OrdinaryPrepareExpectedRuleType
        plan.parameters plan.ruleBinders plan.motive plan.levels shape checked decoded;
  psKernelExprV2OrdinaryValidateRecursorRulesWorker plan.shapes
    check defeq expected fuel context state built rules

def psKernelExprV2OrdinaryValidateRecursorRulesWithFuel
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (built : PsKernelExprV2Decoded)
    (plan : PsKernelExprV2OrdinaryRecursorPlan)
    (rules : List PsKernelExprV2RecursorRuleRef) :
    Option (Except String PsKernelExprV2OrdinaryRuleState) :=
  psKernelExprV2OrdinaryValidateRecursorRulesWith
    psKernelExprV2TryCheckStateWithFuel psKernelExprV2TryDefEqStateWithFuel
    fuel context state built plan rules
