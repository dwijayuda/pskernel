import Ps.KernelCore.Reduce

def psKernelCoreInferNatName : PsKernelCoreName :=
  PsKernelCoreName.str PsKernelCoreName.anonymous "Nat"

def psKernelCoreInferStringName : PsKernelCoreName :=
  PsKernelCoreName.str PsKernelCoreName.anonymous "String"

def psKernelCoreInferFreshName
    (lctx : PsKernelCoreLocalContext)
    (userName : PsKernelCoreName) : PsKernelCoreName :=
  PsKernelCoreName.num userName lctx.nextIndex

def psKernelCoreInferLiteralWithResources
    (resources : PsKernelCoreResourceConfig)
    (literal : PsKernelCoreLiteral) :
    PsKernelCoreResult String PsKernelCoreExpr :=
  match literal with
  | PsKernelCoreLiteral.nat value =>
      match psKernelCoreCheckNatSize resources value with
      | PsKernelCoreResult.error message =>
          PsKernelCoreResult.error message
      | PsKernelCoreResult.ok _ =>
          PsKernelCoreResult.ok
            (PsKernelCoreExpr.const
              psKernelCoreInferNatName
              PsKernelCoreList.nil)
  | PsKernelCoreLiteral.str _ =>
      PsKernelCoreResult.ok
        (PsKernelCoreExpr.const
          psKernelCoreInferStringName
          PsKernelCoreList.nil)

def psKernelCoreEnsureSortWithResources
    (budget : Nat)
    (resources : PsKernelCoreResourceConfig)
    (env : PsKernelCoreEnvironment)
    (lctx : PsKernelCoreLocalContext)
    (expr : PsKernelCoreExpr) :
    PsKernelCoreResult String PsKernelCoreLevel :=
  match psKernelCoreWhnfWithResources budget resources env lctx expr with
  | PsKernelCoreResult.error message =>
      PsKernelCoreResult.error message
  | PsKernelCoreResult.ok reduced =>
      match reduced with
      | PsKernelCoreExpr.sort level => PsKernelCoreResult.ok level
      | _ => PsKernelCoreResult.error "expected sort"

def psKernelCoreEnsureForallWithResources
    (budget : Nat)
    (resources : PsKernelCoreResourceConfig)
    (env : PsKernelCoreEnvironment)
    (lctx : PsKernelCoreLocalContext)
    (expr : PsKernelCoreExpr) :
    PsKernelCoreResult String PsKernelCoreExpr :=
  match psKernelCoreWhnfWithResources budget resources env lctx expr with
  | PsKernelCoreResult.error message =>
      PsKernelCoreResult.error message
  | PsKernelCoreResult.ok reduced =>
      match reduced with
      | PsKernelCoreExpr.forallE _ _ _ _ => PsKernelCoreResult.ok reduced
      | _ => PsKernelCoreResult.error "expected function type"

def psKernelCoreInferWithResources
    (budget : Nat)
    (resources : PsKernelCoreResourceConfig) :
    PsKernelCoreEnvironment ->
    PsKernelCoreLocalContext ->
    PsKernelCoreExpr ->
    PsKernelCoreResult String PsKernelCoreExpr :=
  match budget with
  | Nat.zero =>
      fun (_env : PsKernelCoreEnvironment)
          (_lctx : PsKernelCoreLocalContext)
          (_expr : PsKernelCoreExpr) =>
        PsKernelCoreResult.error "inference budget exhausted"
  | Nat.succ remaining =>
      let smaller :
          PsKernelCoreEnvironment ->
          PsKernelCoreLocalContext ->
          PsKernelCoreExpr ->
          PsKernelCoreResult String PsKernelCoreExpr :=
        psKernelCoreInferWithResources remaining resources;
      fun (env : PsKernelCoreEnvironment)
          (lctx : PsKernelCoreLocalContext)
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
                    PsKernelCoreResult.ok instantiatedType
        | PsKernelCoreExpr.lit literal =>
            psKernelCoreInferLiteralWithResources resources literal
        | PsKernelCoreExpr.mdata _ body =>
            smaller env lctx body
        | PsKernelCoreExpr.app fn arg =>
            match smaller env lctx fn with
            | PsKernelCoreResult.error message =>
                PsKernelCoreResult.error message
            | PsKernelCoreResult.ok fnType =>
                match psKernelCoreEnsureForallWithResources
                    remaining resources env lctx fnType with
                | PsKernelCoreResult.error message =>
                    PsKernelCoreResult.error message
                | PsKernelCoreResult.ok exposed =>
                    match exposed with
                    | PsKernelCoreExpr.forallE _ _ body _ =>
                        PsKernelCoreResult.ok
                          (psKernelCoreExprInstantiate1 body arg)
                    | _ =>
                        PsKernelCoreResult.error "expected function type"
        | PsKernelCoreExpr.lam name domain body binderInfo =>
            let fresh := psKernelCoreInferFreshName lctx name;
            let child :=
              psKernelCoreLocalContextAddLocal
                lctx fresh name domain binderInfo;
            let openedBody :=
              psKernelCoreExprInstantiate1
                body
                (PsKernelCoreExpr.fvar fresh);
            match smaller env child openedBody with
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
            match smaller env lctx domain with
            | PsKernelCoreResult.error message =>
                PsKernelCoreResult.error message
            | PsKernelCoreResult.ok domainType =>
                match psKernelCoreEnsureSortWithResources
                    remaining resources env lctx domainType with
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
                    match smaller env child openedBody with
                    | PsKernelCoreResult.error message =>
                        PsKernelCoreResult.error message
                    | PsKernelCoreResult.ok bodyType =>
                        match psKernelCoreEnsureSortWithResources
                            remaining resources env child bodyType with
                        | PsKernelCoreResult.error message =>
                            PsKernelCoreResult.error message
                        | PsKernelCoreResult.ok bodyLevel =>
                            PsKernelCoreResult.ok
                              (PsKernelCoreExpr.sort
                                (psKernelCoreLevelMkIMax
                                  domainLevel bodyLevel))
        | PsKernelCoreExpr.letE name type value body nondep =>
            let fresh := psKernelCoreInferFreshName lctx name;
            let child :=
              psKernelCoreLocalContextAddLet
                lctx fresh name type value;
            let openedBody :=
              psKernelCoreExprInstantiate1
                body
                (PsKernelCoreExpr.fvar fresh);
            match smaller env child openedBody with
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
        | PsKernelCoreExpr.proj _ _ _ =>
            PsKernelCoreResult.error
              "projection inference unavailable before inductive metadata"

def psKernelCoreEnsureSort
    (budget : Nat)
    (env : PsKernelCoreEnvironment)
    (lctx : PsKernelCoreLocalContext)
    (expr : PsKernelCoreExpr) :
    PsKernelCoreResult String PsKernelCoreLevel :=
  psKernelCoreEnsureSortWithResources
    budget psKernelCoreResourceConfigDefault env lctx expr

def psKernelCoreEnsureForall
    (budget : Nat)
    (env : PsKernelCoreEnvironment)
    (lctx : PsKernelCoreLocalContext)
    (expr : PsKernelCoreExpr) :
    PsKernelCoreResult String PsKernelCoreExpr :=
  psKernelCoreEnsureForallWithResources
    budget psKernelCoreResourceConfigDefault env lctx expr

def psKernelCoreInfer
    (budget : Nat) :
    PsKernelCoreEnvironment ->
    PsKernelCoreLocalContext ->
    PsKernelCoreExpr ->
    PsKernelCoreResult String PsKernelCoreExpr :=
  psKernelCoreInferWithResources budget psKernelCoreResourceConfigDefault
