import Ps.KernelCore.Admission.Inductive.Ordinary.Recursor

def psKernelValidateSimpleRecursorRulesWorker
    [cachePolicy : PsKernelSemanticCachePolicy]
    (shapes : List PsKernelSimpleConstructorShape) :
    Nat ->
    PsKernelCheckerSession ->
    List PsKernelOpenBinder ->
    List PsKernelOpenBinder ->
    PsKernelExpr ->
    List PsKernelLevel ->
    List PsKernelRecursorRule ->
    Except String Unit :=
  match shapes with
  | List.nil =>
      fun
        (_fuel : Nat)
        (_session : PsKernelCheckerSession)
        (_params : List PsKernelOpenBinder)
        (_ruleBinders : List PsKernelOpenBinder)
        (_motive : PsKernelExpr)
        (_levels : List PsKernelLevel)
        (rules : List PsKernelRecursorRule) =>
        match rules with
        | List.nil =>
            Except.ok ()
        | List.cons _ _ =>
            Except.error
              "generated simple recursor rule count mismatch"
  | List.cons shape shapeRest =>
      let smaller :
          Nat ->
          PsKernelCheckerSession ->
          List PsKernelOpenBinder ->
          List PsKernelOpenBinder ->
          PsKernelExpr ->
          List PsKernelLevel ->
          List PsKernelRecursorRule ->
          Except String Unit :=
        psKernelValidateSimpleRecursorRulesWorker
          shapeRest;
      fun
        (fuel : Nat)
        (session : PsKernelCheckerSession)
        (params : List PsKernelOpenBinder)
        (ruleBinders : List PsKernelOpenBinder)
        (motive : PsKernelExpr)
        (levels : List PsKernelLevel)
        (rules : List PsKernelRecursorRule) =>
        match rules with
        | List.nil =>
            Except.error
              "generated simple recursor rule count mismatch"
        | List.cons rule ruleRest =>
            match
                psKernelSessionCheck
                  fuel
                  session
                  rule.rhs with
            | Except.error error =>
                Except.error error
            | Except.ok gotType =>
                let binders :=
                  psKernelOpenBinderListAppend
                    ruleBinders
                    shape.fields;
                let expectedType :=
                  psKernelCloseOpenBinders
                    binders
                    (psKernelSimpleMotiveApp
                      motive
                      shape.resultIndices
                      (psKernelSimpleCtorApp
                        levels
                        params
                        shape));
                match
                    psKernelSessionIsDefEq
                      fuel
                      (Prod.snd gotType)
                      (Prod.fst gotType)
                      expectedType with
                | Except.error error =>
                    Except.error error
                | Except.ok equal =>
                    if Prod.fst equal then
                      smaller
                        fuel
                        (Prod.snd equal)
                        params
                        ruleBinders
                        motive
                        levels
                        ruleRest
                    else
                      Except.error
                        "generated simple recursor rule is not type preserving"

def psKernelValidateSimpleRecursorRules
    [cachePolicy : PsKernelSemanticCachePolicy]
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (params : List PsKernelOpenBinder)
    (ruleBinders : List PsKernelOpenBinder)
    (motive : PsKernelExpr)
    (levels : List PsKernelLevel)
    (shapes : List PsKernelSimpleConstructorShape)
    (rules : List PsKernelRecursorRule) :
    Except String Unit :=
  psKernelValidateSimpleRecursorRulesWorker
    shapes
    fuel
    session
    params
    ruleBinders
    motive
    levels
    rules
