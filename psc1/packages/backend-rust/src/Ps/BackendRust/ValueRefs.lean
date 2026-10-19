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
      List.cons
        parameter.name
        (psRustAddParameterNames rest locals)

def psRustAddBindingNames
    (bindings : List PsVerifiedIrMatchBinding)
    (locals : List String) : List String :=
  match bindings with
  | List.nil =>
      locals
  | List.cons binding rest =>
      List.cons
        binding.name
        (psRustAddBindingNames rest locals)

def psRustRewriteExprListWith
    (rewrite :
      PsVerifiedIrExpr ->
      Except PsRustEmitError PsVerifiedIrExpr)
    (expressions : List PsVerifiedIrExpr) :
    Except PsRustEmitError (List PsVerifiedIrExpr) :=
  match expressions with
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
      Except PsRustEmitError PsVerifiedIrExpr)
    (fields : List (Prod String PsVerifiedIrExpr)) :
    Except PsRustEmitError
      (List (Prod String PsVerifiedIrExpr)) :=
  match fields with
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
      Except PsRustEmitError PsVerifiedIrExpr)
    (alternatives :
      List
        (Prod String
          (Prod
            (List PsVerifiedIrMatchBinding)
            PsVerifiedIrExpr))) :
    Except PsRustEmitError
      (List
        (Prod String
          (Prod
            (List PsVerifiedIrMatchBinding)
            PsVerifiedIrExpr))) :=
  match alternatives with
  | List.nil =>
      Except.ok List.nil
  | List.cons alternative rest =>
      let constructorName : String :=
        Prod.fst alternative;
      let payload : Prod (List PsVerifiedIrMatchBinding) PsVerifiedIrExpr :=
        Prod.snd alternative;
      let bindings : List PsVerifiedIrMatchBinding :=
        Prod.fst payload;
      let body : PsVerifiedIrExpr :=
        Prod.snd payload;
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
    (fuel : Nat) :
    List String ->
    PsVerifiedIrExpr ->
    Except PsRustEmitError PsVerifiedIrExpr :=
  match fuel with
  | Nat.zero =>
      fun
        (_locals : List String)
        (_expr : PsVerifiedIrExpr) =>
          Except.error PsRustEmitError.fuelExhausted
  | Nat.succ remaining =>
      let smaller :
          List String ->
          PsVerifiedIrExpr ->
          Except PsRustEmitError PsVerifiedIrExpr :=
        psRustRewriteValueRefsWithFuel
          valueNames
          remaining;
      fun
        (locals : List String)
        (expr : PsVerifiedIrExpr) =>
        let rewriteNested :
            PsVerifiedIrExpr ->
            Except PsRustEmitError PsVerifiedIrExpr :=
          fun (nested : PsVerifiedIrExpr) =>
            smaller locals nested;
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
      | PsVerifiedIrExpr.intrinsic operation typeArguments arguments =>
          match psRustRewriteExprListWith
              rewriteNested
              arguments with
          | Except.error error =>
              Except.error error
          | Except.ok rewrittenArguments =>
              Except.ok
                (PsVerifiedIrExpr.intrinsic
                  operation
                  typeArguments
                  rewrittenArguments)
      | PsVerifiedIrExpr.lambda parameters resultType body =>
          let bodyLocals :=
            psRustAddParameterNames parameters locals;
          match
              smaller
                bodyLocals
                body with
          | Except.error error =>
              Except.error error
          | Except.ok rewrittenBody =>
              Except.ok
                (PsVerifiedIrExpr.lambda
                  parameters
                  resultType
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
                  smaller
                    (List.cons name locals)
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
      | PsVerifiedIrExpr.record structureName typeArguments fields =>
          match psRustRewriteFieldListWith
              rewriteNested
              fields with
          | Except.error error =>
              Except.error error
          | Except.ok rewrittenFields =>
              Except.ok
                (PsVerifiedIrExpr.record
                  structureName
                  typeArguments
                  rewrittenFields)
      | PsVerifiedIrExpr.projection
          structureName
          typeArguments
          target
          field =>
          match rewriteNested target with
          | Except.error error =>
              Except.error error
          | Except.ok rewrittenTarget =>
              Except.ok
                (PsVerifiedIrExpr.projection
                  structureName
                  typeArguments
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
          typeArguments
          scrutinee
          alternatives =>
          match rewriteNested scrutinee with
          | Except.error error =>
              Except.error error
          | Except.ok rewrittenScrutinee =>
              let rewriteBody :
                  List PsVerifiedIrMatchBinding ->
                  PsVerifiedIrExpr ->
                  Except PsRustEmitError PsVerifiedIrExpr :=
                fun
                  (bindings : List PsVerifiedIrMatchBinding)
                  (body : PsVerifiedIrExpr) =>
                    smaller
                      (psRustAddBindingNames bindings locals)
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
                      typeArguments
                      rewrittenScrutinee
                      rewrittenAlternatives)

def psRustRewriteValueRefs
    (valueNames : List String)
    (locals : List String)
    (expr : PsVerifiedIrExpr) :
    Except PsRustEmitError PsVerifiedIrExpr :=
  psRustRewriteValueRefsWithFuel
    valueNames
    4096
    locals
    expr
