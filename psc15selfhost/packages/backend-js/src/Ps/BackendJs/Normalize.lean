import Ps.CompilerIr.Model
import Ps.BackendJs.Model


partial def psJsWrapLambdaArguments
    (parameters : List PsVerifiedIrParameter)
    (callArguments : List PsVerifiedIrExpr)
    (body : PsVerifiedIrExpr) : Except PsJsError PsVerifiedIrExpr :=
  match parameters with
  | List.nil =>
      match callArguments with
      | List.nil => Except.ok body
      | List.cons _argument _restArguments =>
          Except.error PsJsError.unsupportedExpression
  | List.cons parameter restParameters =>
      match callArguments with
      | List.nil => Except.error PsJsError.unsupportedExpression
      | List.cons argument restArguments =>
          match psJsWrapLambdaArguments restParameters restArguments body with
          | Except.error error => Except.error error
          | Except.ok inner =>
              Except.ok
                (PsVerifiedIrExpr.letE
                  parameter.name
                  parameter.type
                  argument
                  inner)


def psJsNormalizeExprList
    (expressions : List PsVerifiedIrExpr)
    (normalize : PsVerifiedIrExpr -> Except PsJsError PsVerifiedIrExpr) :
    Except PsJsError (List PsVerifiedIrExpr) :=
  match expressions with
  | List.nil => Except.ok List.nil
  | List.cons expression rest =>
      match normalize expression with
      | Except.error error => Except.error error
      | Except.ok normalizedExpression =>
          match psJsNormalizeExprList rest normalize with
          | Except.error error => Except.error error
          | Except.ok normalizedRest =>
              Except.ok (List.cons normalizedExpression normalizedRest)


def psJsNormalizeExprWithFuel (fuel : Nat) :
    PsVerifiedIrExpr -> Except PsJsError PsVerifiedIrExpr :=
  match fuel with
  | Nat.zero =>
      fun (_expr : PsVerifiedIrExpr) => Except.error PsJsError.fuelExhausted
  | Nat.succ remaining =>
      let smaller : PsVerifiedIrExpr -> Except PsJsError PsVerifiedIrExpr :=
        psJsNormalizeExprWithFuel remaining;
      fun (expr : PsVerifiedIrExpr) =>
        match expr with
        | PsVerifiedIrExpr.letE name type value body =>
            match smaller value with
            | Except.error error => Except.error error
            | Except.ok normalizedValue =>
                match smaller body with
                | Except.error error => Except.error error
                | Except.ok normalizedBody =>
                    Except.ok
                      (PsVerifiedIrExpr.letE
                        name type normalizedValue normalizedBody)
        | PsVerifiedIrExpr.ifE condition thenBranch elseBranch =>
            match smaller condition with
            | Except.error error => Except.error error
            | Except.ok normalizedCondition =>
                match smaller thenBranch with
                | Except.error error => Except.error error
                | Except.ok normalizedThen =>
                    match smaller elseBranch with
                    | Except.error error => Except.error error
                    | Except.ok normalizedElse =>
                        Except.ok
                          (PsVerifiedIrExpr.ifE
                            normalizedCondition
                            normalizedThen
                            normalizedElse)
        | PsVerifiedIrExpr.lambda parameters resultType body =>
            match smaller body with
            | Except.error error => Except.error error
            | Except.ok normalizedBody =>
                Except.ok
                  (PsVerifiedIrExpr.lambda
                    parameters resultType normalizedBody)
        | PsVerifiedIrExpr.call fn typeArguments callArguments =>
            match smaller fn with
            | Except.error error => Except.error error
            | Except.ok normalizedFn =>
                match psJsNormalizeExprList callArguments smaller with
                | Except.error error => Except.error error
                | Except.ok normalizedArguments =>
                    match typeArguments with
                    | List.cons _typeArgument _restTypeArguments =>
                        Except.ok
                          (PsVerifiedIrExpr.call
                            normalizedFn typeArguments normalizedArguments)
                    | List.nil =>
                        match normalizedFn with
                        | PsVerifiedIrExpr.lambda parameters resultType body =>
                            match parameters with
                            | List.nil => Except.error PsJsError.unsupportedExpression
                            | List.cons firstParameter _restParameters =>
                                match psJsWrapLambdaArguments
                                  parameters normalizedArguments body with
                                | Except.error error => Except.error error
                                | Except.ok application =>
                                    Except.ok
                                      (PsVerifiedIrExpr.letE
                                        firstParameter.name
                                        resultType
                                        application
                                        (PsVerifiedIrExpr.var firstParameter.name))
                        | _ =>
                            Except.ok
                              (PsVerifiedIrExpr.call
                                normalizedFn List.nil normalizedArguments)
        | _ => Except.ok expr


def psJsNormalizeExpr (expr : PsVerifiedIrExpr) :
    Except PsJsError PsVerifiedIrExpr :=
  psJsNormalizeExprWithFuel 4096 expr


def psJsNormalizeDeclarations (declarations : List PsVerifiedIrDeclaration) :
    Except PsJsError (List PsVerifiedIrDeclaration) :=
  match declarations with
  | List.nil => Except.ok List.nil
  | List.cons declaration rest =>
      match psJsNormalizeExpr declaration.body with
      | Except.error error => Except.error error
      | Except.ok body =>
          match psJsNormalizeDeclarations rest with
          | Except.error error => Except.error error
          | Except.ok normalizedRest =>
              let normalized :=
                PsVerifiedIrDeclaration.mk
                  declaration.name
                  declaration.typeParameters
                  declaration.parameters
                  declaration.resultType
                  body;
              Except.ok (List.cons normalized normalizedRest)


def psJsNormalizeModule (module : PsVerifiedIrModule) :
    Except PsJsError PsVerifiedIrModule :=
  match psJsNormalizeDeclarations module.declarations with
  | Except.error error => Except.error error
  | Except.ok declarations =>
      Except.ok
        (PsVerifiedIrModule.mk
          module.imports
          module.structures
          module.inductives
          declarations)
