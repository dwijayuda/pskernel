import Ps.CompilerIr.Encode

-- Exact pre-normalization source retained for all-input comparison.
namespace PsIrEncoderReference
def psIrEncodeTypeWithFuel (fuel : Nat) :
    PsVerifiedIrType -> Except PsIrEncodeError String :=
  match fuel with
  | Nat.zero => fun (_type : PsVerifiedIrType) => Except.error PsIrEncodeError.fuelExhausted
  | Nat.succ remaining =>
      let smaller : PsVerifiedIrType -> Except PsIrEncodeError String :=
        psIrEncodeTypeWithFuel remaining;
      fun (type : PsVerifiedIrType) =>
        match type with
        | PsVerifiedIrType.unknown => Except.ok (psJsonArray [psJsonQuote "unknown"])
        | PsVerifiedIrType.typeParameter name =>
            Except.ok (psJsonArray [psJsonQuote "typeParameter", psJsonQuote name])
        | PsVerifiedIrType.primitive name =>
            Except.ok (psJsonArray [psJsonQuote "primitive", psIrEncodePrimitiveType name])
        | PsVerifiedIrType.function parameters result =>
            match psIrEncodeArray smaller parameters with
            | Except.error error => Except.error error
            | Except.ok encodedParameters =>
                match smaller result with
                | Except.error error => Except.error error
                | Except.ok encodedResult =>
                    Except.ok (psJsonArray [psJsonQuote "function", encodedParameters, encodedResult])
        | PsVerifiedIrType.named name arguments =>
            match psIrEncodeArray smaller arguments with
            | Except.error error => Except.error error
            | Except.ok encoded =>
                Except.ok (psJsonArray [psJsonQuote "named", psJsonQuote name, encoded])

def psIrEncodeType (type : PsVerifiedIrType) : Except PsIrEncodeError String :=
  psIrEncodeTypeWithFuel 4096 type

def psIrEncodeParameter (value : PsVerifiedIrParameter) : Except PsIrEncodeError String :=
  match psIrEncodeType value.type with
  | Except.error error => Except.error error
  | Except.ok encoded => Except.ok (psJsonArray [psJsonQuote value.name, encoded])

def psIrEncodeMatchBinding (value : PsVerifiedIrMatchBinding) : Except PsIrEncodeError String :=
  match psIrEncodeType value.type with
  | Except.error error => Except.error error
  | Except.ok encoded =>
      Except.ok (psJsonArray [psJsonQuote value.field, psJsonQuote value.name, encoded])

def psIrEncodeExprWithFuel (fuel : Nat) :
    PsVerifiedIrExpr -> Except PsIrEncodeError String :=
  match fuel with
  | Nat.zero => fun (_expr : PsVerifiedIrExpr) => Except.error PsIrEncodeError.fuelExhausted
  | Nat.succ remaining =>
      let smaller : PsVerifiedIrExpr -> Except PsIrEncodeError String :=
        psIrEncodeExprWithFuel remaining;
      let encodeField : Prod String PsVerifiedIrExpr -> Except PsIrEncodeError String :=
        fun (field : Prod String PsVerifiedIrExpr) =>
          match smaller field.snd with
          | Except.error error => Except.error error
          | Except.ok encoded => Except.ok (psJsonArray [psJsonQuote field.fst, encoded]);
      fun (expression : PsVerifiedIrExpr) =>
        match expression with
        | PsVerifiedIrExpr.literal value =>
            Except.ok (psJsonArray [psJsonQuote "literal", psIrEncodeLiteral value])
        | PsVerifiedIrExpr.var name =>
            Except.ok (psJsonArray [psJsonQuote "var", psJsonQuote name])
        | PsVerifiedIrExpr.intrinsic operation types arguments =>
            match psIrEncodeArray psIrEncodeType types with
            | Except.error error => Except.error error
            | Except.ok encodedTypes =>
                match psIrEncodeArray smaller arguments with
                | Except.error error => Except.error error
                | Except.ok encodedArguments =>
                    Except.ok (psJsonArray [psJsonQuote "intrinsic", psIrEncodeIntrinsic operation,
                      encodedTypes, encodedArguments])
        | PsVerifiedIrExpr.lambda parameters result body =>
            match psIrEncodeArray psIrEncodeParameter parameters with
            | Except.error error => Except.error error
            | Except.ok encodedParameters =>
                match psIrEncodeType result with
                | Except.error error => Except.error error
                | Except.ok encodedResult =>
                    match smaller body with
                    | Except.error error => Except.error error
                    | Except.ok encodedBody =>
                        Except.ok (psJsonArray [psJsonQuote "lambda", encodedParameters,
                          encodedResult, encodedBody])
        | PsVerifiedIrExpr.call fn types arguments =>
            match smaller fn with
            | Except.error error => Except.error error
            | Except.ok encodedFn =>
                match psIrEncodeArray psIrEncodeType types with
                | Except.error error => Except.error error
                | Except.ok encodedTypes =>
                    match psIrEncodeArray smaller arguments with
                    | Except.error error => Except.error error
                    | Except.ok encodedArguments =>
                        Except.ok (psJsonArray [psJsonQuote "call", encodedFn, encodedTypes,
                          encodedArguments])
        | PsVerifiedIrExpr.letE name type value body =>
            match psIrEncodeType type with
            | Except.error error => Except.error error
            | Except.ok encodedType =>
                match smaller value with
                | Except.error error => Except.error error
                | Except.ok encodedValue =>
                    match smaller body with
                    | Except.error error => Except.error error
                    | Except.ok encodedBody =>
                        Except.ok (psJsonArray [psJsonQuote "letE", psJsonQuote name,
                          encodedType, encodedValue, encodedBody])
        | PsVerifiedIrExpr.ifE condition yes no =>
            match smaller condition with
            | Except.error error => Except.error error
            | Except.ok encodedCondition =>
                match smaller yes with
                | Except.error error => Except.error error
                | Except.ok encodedYes =>
                    match smaller no with
                    | Except.error error => Except.error error
                    | Except.ok encodedNo =>
                        Except.ok (psJsonArray [psJsonQuote "ifE", encodedCondition,
                          encodedYes, encodedNo])
        | PsVerifiedIrExpr.record name types fields =>
            match psIrEncodeArray psIrEncodeType types with
            | Except.error error => Except.error error
            | Except.ok encodedTypes =>
                match psIrEncodeArray encodeField fields with
                | Except.error error => Except.error error
                | Except.ok encodedFields =>
                    Except.ok (psJsonArray [psJsonQuote "record", psJsonQuote name,
                      encodedTypes, encodedFields])
        | PsVerifiedIrExpr.projection name types value field =>
            match psIrEncodeArray psIrEncodeType types with
            | Except.error error => Except.error error
            | Except.ok encodedTypes =>
                match smaller value with
                | Except.error error => Except.error error
                | Except.ok encodedValue =>
                    Except.ok (psJsonArray [psJsonQuote "projection", psJsonQuote name,
                      encodedTypes, encodedValue, psJsonQuote field])
        | PsVerifiedIrExpr.constructor owner name types fields =>
            match psIrEncodeArray psIrEncodeType types with
            | Except.error error => Except.error error
            | Except.ok encodedTypes =>
                match psIrEncodeArray encodeField fields with
                | Except.error error => Except.error error
                | Except.ok encodedFields =>
                    Except.ok (psJsonArray [psJsonQuote "constructor", psJsonQuote owner,
                      psJsonQuote name, encodedTypes, encodedFields])
        | PsVerifiedIrExpr.matchE name types value alternatives =>
            match psIrEncodeArray psIrEncodeType types with
            | Except.error error => Except.error error
            | Except.ok encodedTypes =>
                match smaller value with
                | Except.error error => Except.error error
                | Except.ok encodedValue =>
                    match psIrEncodeArray
                        (fun (alternative : Prod String (Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr)) =>
                          match psIrEncodeArray psIrEncodeMatchBinding alternative.snd.fst with
                          | Except.error error => Except.error error
                          | Except.ok encodedBindings =>
                              match smaller alternative.snd.snd with
                              | Except.error error => Except.error error
                              | Except.ok encodedBody =>
                                  Except.ok (psJsonArray [psJsonQuote alternative.fst,
                                    encodedBindings, encodedBody]))
                        alternatives with
                    | Except.error error => Except.error error
                    | Except.ok encodedAlternatives =>
                        Except.ok (psJsonArray [psJsonQuote "matchE", psJsonQuote name,
                          encodedTypes, encodedValue, encodedAlternatives])

def psIrEncodeExpr (expression : PsVerifiedIrExpr) : Except PsIrEncodeError String :=
  psIrEncodeExprWithFuel 4096 expression
end PsIrEncoderReference

theorem ir_encode_type_worker_eq (fuel : Nat) (value : PsVerifiedIrType) :
    psIrEncodeTypeWithFuelWorker fuel value =
      PsIrEncoderReference.psIrEncodeTypeWithFuel fuel value := by
  induction fuel generalizing value with
  | zero => rfl
  | succ remaining ih =>
      have recEq : (fun (item : PsVerifiedIrType) => psIrEncodeTypeWithFuelWorker remaining item) =
          PsIrEncoderReference.psIrEncodeTypeWithFuel remaining := funext ih
      simpa only [psIrEncodeTypeWithFuelWorker, PsIrEncoderReference.psIrEncodeTypeWithFuel,
        recEq]

theorem ir_encode_type_with_fuel_eq (fuel : Nat) :
    psIrEncodeTypeWithFuel fuel = PsIrEncoderReference.psIrEncodeTypeWithFuel fuel := by
  funext value
  exact ir_encode_type_worker_eq fuel value

theorem ir_encode_type_eq : psIrEncodeType = PsIrEncoderReference.psIrEncodeType := by
  funext value
  exact ir_encode_type_worker_eq 4096 value

theorem ir_encode_parameter_eq : psIrEncodeParameter = PsIrEncoderReference.psIrEncodeParameter := by
  funext value
  simp only [psIrEncodeParameter, PsIrEncoderReference.psIrEncodeParameter, ir_encode_type_eq]

theorem ir_encode_match_binding_eq :
    psIrEncodeMatchBinding = PsIrEncoderReference.psIrEncodeMatchBinding := by
  funext value
  simp only [psIrEncodeMatchBinding, PsIrEncoderReference.psIrEncodeMatchBinding, ir_encode_type_eq]

theorem ir_encode_expr_worker_eq (fuel : Nat) (value : PsVerifiedIrExpr) :
    psIrEncodeExprWithFuelWorker fuel value =
      PsIrEncoderReference.psIrEncodeExprWithFuel fuel value := by
  induction fuel generalizing value with
  | zero => rfl
  | succ remaining ih =>
      have recEq : (fun (item : PsVerifiedIrExpr) => psIrEncodeExprWithFuelWorker remaining item) =
          PsIrEncoderReference.psIrEncodeExprWithFuel remaining := funext ih
      simpa only [psIrEncodeExprWithFuelWorker, PsIrEncoderReference.psIrEncodeExprWithFuel,
        recEq, ir_encode_type_eq, ir_encode_parameter_eq, ir_encode_match_binding_eq]

theorem ir_encode_expr_with_fuel_eq (fuel : Nat) :
    psIrEncodeExprWithFuel fuel = PsIrEncoderReference.psIrEncodeExprWithFuel fuel := by
  funext value
  exact ir_encode_expr_worker_eq fuel value

theorem ir_encode_expr_eq : psIrEncodeExpr = PsIrEncoderReference.psIrEncodeExpr := by
  funext value
  exact ir_encode_expr_worker_eq 4096 value

#print axioms ir_encode_type_worker_eq
#print axioms ir_encode_expr_worker_eq

def main : IO Unit := do
  let primitive := PsVerifiedIrType.primitive PsVerifiedIrPrimitiveType.nat
  let literal := PsVerifiedIrExpr.literal (PsVerifiedIrLiteral.natural 7)
  unless (match psIrEncodeTypeWithFuel 0 primitive with
    | Except.error PsIrEncodeError.fuelExhausted => true
    | _ => false) do throw (IO.userError "type zero fuel changed")
  unless (match psIrEncodeExprWithFuel 0 literal with
    | Except.error PsIrEncodeError.fuelExhausted => true
    | _ => false) do throw (IO.userError "expression zero fuel changed")
  unless (match psIrEncodeTypeWithFuel 1 primitive with
    | Except.ok text => psStringEq text "[\"primitive\",\"nat\"]"
    | _ => false) do throw (IO.userError "type leaf changed")
  unless (match psIrEncodeExprWithFuel 1 literal with
    | Except.ok text => psStringEq text "[\"literal\",[\"natural\",\"7\"]]"
    | _ => false) do throw (IO.userError "expression leaf changed")
  IO.println "PSC1_IR_ENCODER_WORKERS: all-input fuel/type/expression equalities; public wrappers and helpers; unchanged default4096 and tagged tuples"
