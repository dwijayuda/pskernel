import Ps.BackendTs.Expr

-- Preserve the exact pre-normalization visitor for all-input native equality.
namespace PsTsServiceReference
def legacyContext
    (brands : List (String × String)) (tags : List (String × String)) (fuel : Nat) :
    Bool -> PsVerifiedIrExpr -> Except PsTsEmitError String :=
  match fuel with
  | Nat.zero => fun (_tail : Bool) (_expr : PsVerifiedIrExpr) => Except.error PsTsEmitError.fuelExhausted
  | Nat.succ remaining =>
    fun (tail : Bool) (expr : PsVerifiedIrExpr) =>
      let smaller : PsVerifiedIrExpr -> Except PsTsEmitError String := legacyContext brands tags remaining false;
      let result : PsVerifiedIrExpr -> Except PsTsEmitError String := legacyContext brands tags remaining tail;
      let owned : PsVerifiedIrExpr -> Except PsTsEmitError String := legacyContext brands tags remaining true;
      match expr with
      | .literal literal =>
          psTsEmitLiteral literal
      | .var name =>
          Except.ok name
      | .intrinsic operation _ arguments =>
          match psListMapExcept smaller arguments with
          | Except.error error => Except.error error
          | Except.ok printed =>
              psTsEmitIntrinsicFromPrinted operation printed
      | .lambda parameters resultType body =>
          let printParameter : PsVerifiedIrParameter -> Except PsTsEmitError String :=
            fun (parameter : PsVerifiedIrParameter) =>
              match psTsEmitType parameter.type with
              | Except.error error => Except.error error
              | Except.ok type =>
                  Except.ok (psTsJoin "" [parameter.name, ": ", type]);
          match psListMapExcept printParameter parameters with
          | Except.error error => Except.error error
          | Except.ok printedParameters =>
              match owned body with
              | Except.error error => Except.error error
              | Except.ok printedBody =>
                  match psTsEmitType resultType with
                  | Except.error error => Except.error error
                  | Except.ok printedResult =>
                      Except.ok
                        (psTsJoin "" ["__ps$wrap(function*(", psTsJoin ", " printedParameters, "): __ps$Computation<", printedResult, "> { return ", printedBody, "; })"])
      | .call fn typeArguments arguments =>
          match smaller fn with
          | Except.error error => Except.error error
          | Except.ok printedFn =>
              let callable : String :=
                match fn with
                | PsVerifiedIrExpr.lambda _ _ _ => psTsJoin "" ["(", printedFn, ")"]
                | _ => printedFn;
              match psTsEmitTypeArguments typeArguments with
              | Except.error error => Except.error error
              | Except.ok generic =>
                  match psListMapExcept smaller arguments with
                  | Except.error error => Except.error error
                  | Except.ok printedArguments =>
                      let suffix :=
                        if psListIsEmpty printedArguments then ""
                        else psTsJoin "" [", ", psTsJoin ", " printedArguments];
                      Except.ok
                        (psTsJoin "" ["(yield* ", (if tail then "__ps$tail" else "__ps$invoke"), "(", callable, generic, suffix, "))"])
      | .letE _ _ _ _ =>
          match psTsEmitLetStatementsWithResult smaller result expr with
          | Except.error error => Except.error error
          | Except.ok statements =>
              Except.ok (psTsJoin "" ["(yield* (function*() { ", statements, " })())"])
      | .ifE condition thenBranch elseBranch =>
          match smaller condition with
          | Except.error error => Except.error error
          | Except.ok printedCondition =>
              match result thenBranch with
              | Except.error error => Except.error error
              | Except.ok printedThen =>
                  match result elseBranch with
                  | Except.error error => Except.error error
                  | Except.ok printedElse =>
                      Except.ok
                        (psTsJoin "" ["(", printedCondition, " ? ", printedThen, " : ", printedElse, ")"])
      | .record structureName _ fields =>
          match psTsLookup brands structureName with
          | Option.none =>
              Except.error (PsTsEmitError.unknownStructure structureName)
          | Option.some brand =>
              let printField : (String × PsVerifiedIrExpr) -> Except PsTsEmitError String :=
                fun (field : String × PsVerifiedIrExpr) =>
                  match field with
                  | Prod.mk fieldName fieldValue =>
                      match
                          smaller
                            fieldValue with
                      | Except.error error => Except.error error
                      | Except.ok value =>
                          Except.ok (psTsJoin "" ["[", psJsonQuote fieldName, "]: ", value]);
              match psListMapExcept printField fields with
              | Except.error error => Except.error error
              | Except.ok printedFields =>
                  let suffix :=
                    if psListIsEmpty printedFields then
                      ""
                    else
                      psTsJoin "" [", ", psTsJoin ", " printedFields];
                  Except.ok
                    (psTsJoin "" ["({ [", brand, "]: true as const", suffix, " })"])
      | .projection _ _ target field =>
          match smaller target with
          | Except.error error => Except.error error
          | Except.ok printedTarget =>
              Except.ok (psTsJoin "" [printedTarget, ".", field])
      | .constructor inductiveName constructorName typeArguments fields =>
          match psTsLookup tags inductiveName with
          | Option.none =>
              Except.error (PsTsEmitError.unknownInductive inductiveName)
          | Option.some _ =>
              match psTsEmitTypeArguments typeArguments with
              | Except.error error => Except.error error
              | Except.ok generic =>
                  let access :=
                    psTsJoin "" [inductiveName, "[", psJsonQuote constructorName, "]"];
                  let printField : (String × PsVerifiedIrExpr) -> Except PsTsEmitError String :=
                    fun (field : String × PsVerifiedIrExpr) =>
                      match field with
                      | Prod.mk fieldName fieldValue =>
                          smaller
                            fieldValue;
                  match psListMapExcept printField fields with
                  | Except.error error => Except.error error
                  | Except.ok printedFields =>
                      if if psListIsEmpty typeArguments then psListIsEmpty fields else false then
                        Except.ok access
                      else
                        Except.ok
                          (psTsJoin "" [access, generic, "(", psTsJoin ", " printedFields, ")"])
      | .matchE inductiveName _ scrutinee alternatives =>
          match psTsLookup tags inductiveName with
          | Option.none =>
              Except.error (PsTsEmitError.unknownInductive inductiveName)
          | Option.some tag =>
              if psListIsEmpty alternatives then
                match smaller scrutinee with
                | Except.error error => Except.error error
                | Except.ok printedScrutinee =>
                    Except.ok
                      (psTsJoin "" ["(yield* (function*(): __ps$Computation<never> { void (",
                        printedScrutinee, "); throw new Error(",
                        psJsonQuote "unreachable empty ProofScript match", "); })())"])
              else
                let temp := psTsFreshMatchTemp expr;
                let printAlternative : (String × List PsVerifiedIrMatchBinding × PsVerifiedIrExpr) -> Except PsTsEmitError String :=
                  fun (alternative : String × List PsVerifiedIrMatchBinding × PsVerifiedIrExpr) =>
                    match alternative with
                    | Prod.mk constructorName detail =>
                      match detail with
                      | Prod.mk bindings body =>
                        match
                            result
                              body with
                        | Except.error error => Except.error error
                        | Except.ok printedBody =>
                            if psListIsEmpty bindings then
                              Except.ok
                                (psTsJoin "" ["case ", psJsonQuote constructorName, ": return ", printedBody, ";"])
                            else
                              let printBinding : PsVerifiedIrMatchBinding -> Except PsTsEmitError String :=
                                fun (binding : PsVerifiedIrMatchBinding) =>
                                  match psTsEmitType binding.type with
                                  | Except.error error => Except.error error
                                  | Except.ok type =>
                                      Except.ok
                                        (psTsJoin "" ["const ", binding.name, ": ", type, " = ", temp, ".", binding.field, ";"]);
                              match psListMapExcept printBinding bindings with
                              | Except.error error => Except.error error
                              | Except.ok printedBindings =>
                                  Except.ok
                                    (psTsJoin "" ["case ", psJsonQuote constructorName, ": { ", psTsJoin " " printedBindings, " return ", printedBody, "; }"]);
                match psListMapExcept printAlternative alternatives with
                | Except.error error => Except.error error
                | Except.ok cases =>
                    match
                        smaller
                          scrutinee with
                    | Except.error error => Except.error error
                    | Except.ok printedScrutinee =>
                        Except.ok
                          (psTsJoin "" ["(yield* (function*() { const ", temp, " = ", printedScrutinee, "; switch (", temp, "[", tag, "]) { ", psTsJoin " " cases, " } throw new Error(", psJsonQuote
                              "invalid ProofScript constructor tag", "); })())"])


-- Ordinary expression consumers preserve their surrounding continuation.
theorem context_eq (brands tags : List (String × String)) (fuel : Nat) :
    legacyContext brands tags fuel = psTsEmitExprContextWithFuel brands tags fuel := by
  induction fuel with
  | zero => rfl
  | succ remaining ih =>
      simp only [legacyContext, psTsEmitExprContextWithFuel, ih]
      rfl
end PsTsServiceReference

def main : IO Unit :=
  IO.println "PSC1_TS_SERVICE_NORMALIZATION: all-input context equality proved"
