import Ps.BackendRust.Type

def psRustStringListContains
    (values : List String)
    (name : String) : Bool :=
  match values with
  | List.nil =>
      false
  | List.cons value rest =>
      if psStringEq value name then
        true
      else
        psRustStringListContains rest name

def psRustAddParameterNames
    (parameters : List PsVerifiedIrParameter)
    (locals : List String) : List String :=
  match parameters with
  | List.nil =>
      locals
  | List.cons parameter rest =>
      psRustAddParameterNames
        rest
        (List.cons parameter.name locals)

def psRustAddBindingNames
    (bindings : List PsVerifiedIrMatchBinding)
    (locals : List String) : List String :=
  match bindings with
  | List.nil =>
      locals
  | List.cons binding rest =>
      psRustAddBindingNames
        rest
        (List.cons binding.name locals)

def psRustRewriteExprListWith
    (rewrite :
      PsVerifiedIrExpr ->
      Except PsRustEmitError PsVerifiedIrExpr) :
    List PsVerifiedIrExpr ->
    Except PsRustEmitError (List PsVerifiedIrExpr)
  | List.nil =>
      Except.ok List.nil
  | List.cons expr rest =>
      match rewrite expr with
      | Except.error error =>
          Except.error error
      | Except.ok rewritten =>
          match psRustRewriteExprListWith rewrite rest with
          | Except.error error =>
              Except.error error
          | Except.ok rewrittenRest =>
              Except.ok (List.cons rewritten rewrittenRest)

def psRustRewriteFieldListWith
    (rewrite :
      PsVerifiedIrExpr ->
      Except PsRustEmitError PsVerifiedIrExpr) :
    List (Prod String PsVerifiedIrExpr) ->
    Except PsRustEmitError
      (List (Prod String PsVerifiedIrExpr))
  | List.nil =>
      Except.ok List.nil
  | List.cons field rest =>
      match rewrite (Prod.snd field) with
      | Except.error error =>
          Except.error error
      | Except.ok rewritten =>
          match psRustRewriteFieldListWith rewrite rest with
          | Except.error error =>
              Except.error error
          | Except.ok rewrittenRest =>
              Except.ok
                (List.cons
                  (Prod.mk (Prod.fst field) rewritten)
                  rewrittenRest)

def psRustRewriteAlternativeListWith
    (rewriteBody :
      List PsVerifiedIrMatchBinding ->
      PsVerifiedIrExpr ->
      Except PsRustEmitError PsVerifiedIrExpr) :
    List
      (Prod String
        (Prod
          (List PsVerifiedIrMatchBinding)
          PsVerifiedIrExpr)) ->
    Except PsRustEmitError
      (List
        (Prod String
          (Prod
            (List PsVerifiedIrMatchBinding)
            PsVerifiedIrExpr)))
  | List.nil =>
      Except.ok List.nil
  | List.cons alternative rest =>
      let constructorName := Prod.fst alternative;
      let payload := Prod.snd alternative;
      let bindings := Prod.fst payload;
      let body := Prod.snd payload;
      match rewriteBody bindings body with
      | Except.error error =>
          Except.error error
      | Except.ok rewrittenBody =>
          match psRustRewriteAlternativeListWith
              rewriteBody
              rest with
          | Except.error error =>
              Except.error error
          | Except.ok rewrittenRest =>
              Except.ok
                (List.cons
                  (Prod.mk
                    constructorName
                    (Prod.mk bindings rewrittenBody))
                  rewrittenRest)

def psRustRewriteValueRefsWithFuel
    (valueNames : List String)
    (locals : List String) :
    Nat ->
    PsVerifiedIrExpr ->
    Except PsRustEmitError PsVerifiedIrExpr
  | 0, _ =>
      Except.error PsRustEmitError.fuelExhausted
  | fuel + 1, expr =>
      let rewriteNested :=
        fun (nested : PsVerifiedIrExpr) =>
          psRustRewriteValueRefsWithFuel
            valueNames
            locals
            fuel
            nested;
      match expr with
      | PsVerifiedIrExpr.literal _ =>
          Except.ok expr
      | PsVerifiedIrExpr.var name =>
          if psRustStringListContains locals name then
            Except.ok expr
          else if psRustStringListContains valueNames name then
            Except.ok
              (PsVerifiedIrExpr.call
                (PsVerifiedIrExpr.var name)
                List.nil
                List.nil)
          else
            Except.ok expr
      | PsVerifiedIrExpr.intrinsic operation arguments =>
          match psRustRewriteExprListWith
              rewriteNested
              arguments with
          | Except.error error =>
              Except.error error
          | Except.ok rewrittenArguments =>
              Except.ok
                (PsVerifiedIrExpr.intrinsic
                  operation
                  rewrittenArguments)
      | PsVerifiedIrExpr.lambda parameters body =>
          let bodyLocals :=
            psRustAddParameterNames parameters locals;
          match
              psRustRewriteValueRefsWithFuel
                valueNames
                bodyLocals
                fuel
                body with
          | Except.error error =>
              Except.error error
          | Except.ok rewrittenBody =>
              Except.ok
                (PsVerifiedIrExpr.lambda
                  parameters
                  rewrittenBody)
      | PsVerifiedIrExpr.call fn typeArguments arguments =>
          match rewriteNested fn with
          | Except.error error =>
              Except.error error
          | Except.ok rewrittenFn =>
              match psRustRewriteExprListWith
                  rewriteNested
                  arguments with
              | Except.error error =>
                  Except.error error
              | Except.ok rewrittenArguments =>
                  Except.ok
                    (PsVerifiedIrExpr.call
                      rewrittenFn
                      typeArguments
                      rewrittenArguments)
      | PsVerifiedIrExpr.letE name type value body =>
          match rewriteNested value with
          | Except.error error =>
              Except.error error
          | Except.ok rewrittenValue =>
              match
                  psRustRewriteValueRefsWithFuel
                    valueNames
                    (List.cons name locals)
                    fuel
                    body with
              | Except.error error =>
                  Except.error error
              | Except.ok rewrittenBody =>
                  Except.ok
                    (PsVerifiedIrExpr.letE
                      name
                      type
                      rewrittenValue
                      rewrittenBody)
      | PsVerifiedIrExpr.ifE condition thenBranch elseBranch =>
          match rewriteNested condition with
          | Except.error error =>
              Except.error error
          | Except.ok rewrittenCondition =>
              match rewriteNested thenBranch with
              | Except.error error =>
                  Except.error error
              | Except.ok rewrittenThen =>
                  match rewriteNested elseBranch with
                  | Except.error error =>
                      Except.error error
                  | Except.ok rewrittenElse =>
                      Except.ok
                        (PsVerifiedIrExpr.ifE
                          rewrittenCondition
                          rewrittenThen
                          rewrittenElse)
      | PsVerifiedIrExpr.record structureName fields =>
          match psRustRewriteFieldListWith
              rewriteNested
              fields with
          | Except.error error =>
              Except.error error
          | Except.ok rewrittenFields =>
              Except.ok
                (PsVerifiedIrExpr.record
                  structureName
                  rewrittenFields)
      | PsVerifiedIrExpr.projection target field =>
          match rewriteNested target with
          | Except.error error =>
              Except.error error
          | Except.ok rewrittenTarget =>
              Except.ok
                (PsVerifiedIrExpr.projection
                  rewrittenTarget
                  field)
      | PsVerifiedIrExpr.constructor
          inductiveName
          constructorName
          typeArguments
          fields =>
          match psRustRewriteFieldListWith
              rewriteNested
              fields with
          | Except.error error =>
              Except.error error
          | Except.ok rewrittenFields =>
              Except.ok
                (PsVerifiedIrExpr.constructor
                  inductiveName
                  constructorName
                  typeArguments
                  rewrittenFields)
      | PsVerifiedIrExpr.matchE
          inductiveName
          scrutinee
          alternatives =>
          match rewriteNested scrutinee with
          | Except.error error =>
              Except.error error
          | Except.ok rewrittenScrutinee =>
              let rewriteBody :=
                fun
                  (bindings : List PsVerifiedIrMatchBinding)
                  (body : PsVerifiedIrExpr) =>
                    psRustRewriteValueRefsWithFuel
                      valueNames
                      (psRustAddBindingNames bindings locals)
                      fuel
                      body;
              match
                  psRustRewriteAlternativeListWith
                    rewriteBody
                    alternatives with
              | Except.error error =>
                  Except.error error
              | Except.ok rewrittenAlternatives =>
                  Except.ok
                    (PsVerifiedIrExpr.matchE
                      inductiveName
                      rewrittenScrutinee
                      rewrittenAlternatives)

def psRustRewriteValueRefs
    (valueNames : List String)
    (locals : List String)
    (expr : PsVerifiedIrExpr) :
    Except PsRustEmitError PsVerifiedIrExpr :=
  psRustRewriteValueRefsWithFuel
    valueNames
    locals
    4096
    expr
