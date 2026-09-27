import Ps.KernelCore.DefEq

def psKernelCoreCheckAllowsUnsafe
    (safety : PsKernelCoreDefinitionSafety) : Bool :=
  match safety with
  | PsKernelCoreDefinitionSafety.unsafeDef => true
  | PsKernelCoreDefinitionSafety.safe => false
  | PsKernelCoreDefinitionSafety.partialDef => false

def psKernelCoreCheckAllowsPartial
    (safety : PsKernelCoreDefinitionSafety) : Bool :=
  match safety with
  | PsKernelCoreDefinitionSafety.safe => false
  | PsKernelCoreDefinitionSafety.unsafeDef => true
  | PsKernelCoreDefinitionSafety.partialDef => true

def psKernelCoreCheck
    (budget : Nat) :
    PsKernelCoreEnvironment ->
    PsKernelCoreLocalContext ->
    PsKernelCoreDefinitionSafety ->
    PsKernelCoreExpr ->
    PsKernelCoreResult String PsKernelCoreExpr :=
  match budget with
  | Nat.zero =>
      fun (_env : PsKernelCoreEnvironment)
          (_lctx : PsKernelCoreLocalContext)
          (_safety : PsKernelCoreDefinitionSafety)
          (_expr : PsKernelCoreExpr) =>
        PsKernelCoreResult.error "check budget exhausted"
  | Nat.succ remaining =>
      let smaller :
          PsKernelCoreEnvironment ->
          PsKernelCoreLocalContext ->
          PsKernelCoreDefinitionSafety ->
          PsKernelCoreExpr ->
          PsKernelCoreResult String PsKernelCoreExpr :=
        psKernelCoreCheck remaining;
      fun (env : PsKernelCoreEnvironment)
          (lctx : PsKernelCoreLocalContext)
          (safety : PsKernelCoreDefinitionSafety)
          (expr : PsKernelCoreExpr) =>
        match expr with
        | PsKernelCoreExpr.bvar _ =>
            PsKernelCoreResult.error "loose bound variable in type checker"
        | PsKernelCoreExpr.mvar _ =>
            PsKernelCoreResult.error
              "kernel type checker does not support metavariables"
        | PsKernelCoreExpr.fvar name =>
            match psKernelCoreLocalContextFind? lctx name with
            | PsKernelCoreOption.none =>
                PsKernelCoreResult.error "unknown free variable"
            | PsKernelCoreOption.some decl =>
                PsKernelCoreResult.ok (psKernelCoreLocalDeclType decl)
        | PsKernelCoreExpr.sort level =>
            PsKernelCoreResult.ok
              (PsKernelCoreExpr.sort (PsKernelCoreLevel.succ level))
        | PsKernelCoreExpr.const name levels =>
            match psKernelCoreEnvironmentFind? env name with
            | PsKernelCoreOption.none =>
                PsKernelCoreResult.error "unknown constant"
            | PsKernelCoreOption.some info =>
                match psKernelCoreExprInstantiateLevelParams
                    (psKernelCoreConstantInfoType info)
                    (psKernelCoreConstantInfoLevelParams info)
                    levels with
                | PsKernelCoreOption.none =>
                    PsKernelCoreResult.error
                      "incorrect number of universe levels"
                | PsKernelCoreOption.some instantiatedType =>
                    if psKernelCoreConstantInfoIsUnsafe info then
                      if psKernelCoreCheckAllowsUnsafe safety then
                        PsKernelCoreResult.ok instantiatedType
                      else
                        PsKernelCoreResult.error
                          "safe declaration uses unsafe constant"
                    else if psKernelCoreConstantInfoIsPartial info then
                      if psKernelCoreCheckAllowsPartial safety then
                        PsKernelCoreResult.ok instantiatedType
                      else
                        PsKernelCoreResult.error
                          "safe declaration uses partial constant"
                    else
                      PsKernelCoreResult.ok instantiatedType
        | PsKernelCoreExpr.lit literal =>
            match literal with
            | PsKernelCoreLiteral.nat _ =>
                PsKernelCoreResult.ok
                  (PsKernelCoreExpr.const
                    psKernelCoreInferNatName
                    PsKernelCoreList.nil)
            | PsKernelCoreLiteral.str _ =>
                PsKernelCoreResult.ok
                  (PsKernelCoreExpr.const
                    psKernelCoreInferStringName
                    PsKernelCoreList.nil)
        | PsKernelCoreExpr.mdata _ body =>
            smaller env lctx safety body
        | PsKernelCoreExpr.app fn arg =>
            match smaller env lctx safety fn with
            | PsKernelCoreResult.error message =>
                PsKernelCoreResult.error message
            | PsKernelCoreResult.ok fnType =>
                match psKernelCoreEnsureForall remaining env lctx fnType with
                | PsKernelCoreResult.error message =>
                    PsKernelCoreResult.error message
                | PsKernelCoreResult.ok exposed =>
                    match exposed with
                    | PsKernelCoreExpr.forallE _ domain body _ =>
                        match smaller env lctx safety arg with
                        | PsKernelCoreResult.error message =>
                            PsKernelCoreResult.error message
                        | PsKernelCoreResult.ok argType =>
                            match psKernelCoreIsDefEq
                                remaining env lctx argType domain with
                            | PsKernelCoreResult.error message =>
                                PsKernelCoreResult.error message
                            | PsKernelCoreResult.ok equal =>
                                if equal then
                                  PsKernelCoreResult.ok
                                    (psKernelCoreExprInstantiate1 body arg)
                                else
                                  PsKernelCoreResult.error
                                    "application type mismatch"
                    | _ =>
                        PsKernelCoreResult.error "expected function type"
        | PsKernelCoreExpr.lam name domain body binderInfo =>
            match smaller env lctx safety domain with
            | PsKernelCoreResult.error message =>
                PsKernelCoreResult.error message
            | PsKernelCoreResult.ok domainType =>
                match psKernelCoreEnsureSort remaining env lctx domainType with
                | PsKernelCoreResult.error message =>
                    PsKernelCoreResult.error message
                | PsKernelCoreResult.ok _ =>
                    let fresh := psKernelCoreInferFreshName lctx name;
                    let child :=
                      psKernelCoreLocalContextAddLocal
                        lctx fresh name domain binderInfo;
                    let openedBody :=
                      psKernelCoreExprInstantiate1
                        body
                        (PsKernelCoreExpr.fvar fresh);
                    match smaller env child safety openedBody with
                    | PsKernelCoreResult.error message =>
                        PsKernelCoreResult.error message
                    | PsKernelCoreResult.ok bodyType =>
                        PsKernelCoreResult.ok
                          (PsKernelCoreExpr.forallE
                            name
                            domain
                            (psKernelCoreExprAbstractFVar bodyType fresh)
                            binderInfo)
        | PsKernelCoreExpr.forallE name domain body binderInfo =>
            match smaller env lctx safety domain with
            | PsKernelCoreResult.error message =>
                PsKernelCoreResult.error message
            | PsKernelCoreResult.ok domainType =>
                match psKernelCoreEnsureSort remaining env lctx domainType with
                | PsKernelCoreResult.error message =>
                    PsKernelCoreResult.error message
                | PsKernelCoreResult.ok domainLevel =>
                    let fresh := psKernelCoreInferFreshName lctx name;
                    let child :=
                      psKernelCoreLocalContextAddLocal
                        lctx fresh name domain binderInfo;
                    let openedBody :=
                      psKernelCoreExprInstantiate1
                        body
                        (PsKernelCoreExpr.fvar fresh);
                    match smaller env child safety openedBody with
                    | PsKernelCoreResult.error message =>
                        PsKernelCoreResult.error message
                    | PsKernelCoreResult.ok bodyType =>
                        match psKernelCoreEnsureSort
                            remaining env child bodyType with
                        | PsKernelCoreResult.error message =>
                            PsKernelCoreResult.error message
                        | PsKernelCoreResult.ok bodyLevel =>
                            PsKernelCoreResult.ok
                              (PsKernelCoreExpr.sort
                                (psKernelCoreLevelMkIMax
                                  domainLevel bodyLevel))
        | PsKernelCoreExpr.letE name type value body nondep =>
            match smaller env lctx safety type with
            | PsKernelCoreResult.error message =>
                PsKernelCoreResult.error message
            | PsKernelCoreResult.ok typeType =>
                match psKernelCoreEnsureSort remaining env lctx typeType with
                | PsKernelCoreResult.error message =>
                    PsKernelCoreResult.error message
                | PsKernelCoreResult.ok _ =>
                    match smaller env lctx safety value with
                    | PsKernelCoreResult.error message =>
                        PsKernelCoreResult.error message
                    | PsKernelCoreResult.ok valueType =>
                        match psKernelCoreIsDefEq
                            remaining env lctx valueType type with
                        | PsKernelCoreResult.error message =>
                            PsKernelCoreResult.error message
                        | PsKernelCoreResult.ok equal =>
                            if equal then
                              let fresh := psKernelCoreInferFreshName lctx name;
                              let child :=
                                psKernelCoreLocalContextAddLet
                                  lctx fresh name type value;
                              let openedBody :=
                                psKernelCoreExprInstantiate1
                                  body
                                  (PsKernelCoreExpr.fvar fresh);
                              match smaller env child safety openedBody with
                              | PsKernelCoreResult.error message =>
                                  PsKernelCoreResult.error message
                              | PsKernelCoreResult.ok bodyType =>
                                  if psKernelCoreExprHasFVarName bodyType fresh then
                                    PsKernelCoreResult.ok
                                      (PsKernelCoreExpr.letE
                                        name
                                        type
                                        value
                                        (psKernelCoreExprAbstractFVar bodyType fresh)
                                        nondep)
                                  else
                                    PsKernelCoreResult.ok bodyType
                            else
                              PsKernelCoreResult.error
                                "let value type mismatch"
        | PsKernelCoreExpr.proj _ _ _ =>
            PsKernelCoreResult.error
              "projection checking unavailable before inductive metadata"
