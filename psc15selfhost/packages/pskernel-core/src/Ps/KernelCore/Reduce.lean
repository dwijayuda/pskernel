import Ps.KernelCore.Subst
import Ps.KernelCore.Environment
import Ps.KernelCore.LocalContext

def psKernelCoreLevelSubstFromLists
    (params : PsKernelCoreList PsKernelCoreName) :
    PsKernelCoreList PsKernelCoreLevel -> PsKernelCoreOption PsKernelCoreLevelSubst :=
  match params with
  | PsKernelCoreList.nil =>
      fun (values : PsKernelCoreList PsKernelCoreLevel) =>
        match values with
        | PsKernelCoreList.nil =>
            PsKernelCoreOption.some PsKernelCoreLevelSubst.nil
        | PsKernelCoreList.cons _ _ => PsKernelCoreOption.none
  | PsKernelCoreList.cons param rest =>
      let buildRest :
          PsKernelCoreList PsKernelCoreLevel ->
          PsKernelCoreOption PsKernelCoreLevelSubst :=
        psKernelCoreLevelSubstFromLists rest;
      fun (values : PsKernelCoreList PsKernelCoreLevel) =>
        match values with
        | PsKernelCoreList.nil => PsKernelCoreOption.none
        | PsKernelCoreList.cons value valueRest =>
            match buildRest valueRest with
            | PsKernelCoreOption.none => PsKernelCoreOption.none
            | PsKernelCoreOption.some tail =>
                PsKernelCoreOption.some
                  (PsKernelCoreLevelSubst.cons param value tail)

def psKernelCoreLevelListInstantiateParams
    (items : PsKernelCoreList PsKernelCoreLevel)
    (subst : PsKernelCoreLevelSubst) : PsKernelCoreList PsKernelCoreLevel :=
  match items with
  | PsKernelCoreList.nil => PsKernelCoreList.nil
  | PsKernelCoreList.cons head rest =>
      PsKernelCoreList.cons
        (psKernelCoreLevelInstantiateParams head subst)
        (psKernelCoreLevelListInstantiateParams rest subst)

def psKernelCoreExprInstantiateLevelSubst
    (expr : PsKernelCoreExpr)
    (subst : PsKernelCoreLevelSubst) : PsKernelCoreExpr :=
  match expr with
  | PsKernelCoreExpr.bvar index => PsKernelCoreExpr.bvar index
  | PsKernelCoreExpr.fvar name => PsKernelCoreExpr.fvar name
  | PsKernelCoreExpr.mvar name => PsKernelCoreExpr.mvar name
  | PsKernelCoreExpr.sort level =>
      PsKernelCoreExpr.sort (psKernelCoreLevelInstantiateParams level subst)
  | PsKernelCoreExpr.const name levels =>
      PsKernelCoreExpr.const name
        (psKernelCoreLevelListInstantiateParams levels subst)
  | PsKernelCoreExpr.app fn arg =>
      PsKernelCoreExpr.app
        (psKernelCoreExprInstantiateLevelSubst fn subst)
        (psKernelCoreExprInstantiateLevelSubst arg subst)
  | PsKernelCoreExpr.lam name type body binderInfo =>
      PsKernelCoreExpr.lam
        name
        (psKernelCoreExprInstantiateLevelSubst type subst)
        (psKernelCoreExprInstantiateLevelSubst body subst)
        binderInfo
  | PsKernelCoreExpr.forallE name type body binderInfo =>
      PsKernelCoreExpr.forallE
        name
        (psKernelCoreExprInstantiateLevelSubst type subst)
        (psKernelCoreExprInstantiateLevelSubst body subst)
        binderInfo
  | PsKernelCoreExpr.letE name type value body nondep =>
      PsKernelCoreExpr.letE
        name
        (psKernelCoreExprInstantiateLevelSubst type subst)
        (psKernelCoreExprInstantiateLevelSubst value subst)
        (psKernelCoreExprInstantiateLevelSubst body subst)
        nondep
  | PsKernelCoreExpr.lit value => PsKernelCoreExpr.lit value
  | PsKernelCoreExpr.mdata metadata body =>
      PsKernelCoreExpr.mdata metadata
        (psKernelCoreExprInstantiateLevelSubst body subst)
  | PsKernelCoreExpr.proj typeName index body =>
      PsKernelCoreExpr.proj typeName index
        (psKernelCoreExprInstantiateLevelSubst body subst)

def psKernelCoreExprInstantiateLevelParams
    (expr : PsKernelCoreExpr)
    (params : PsKernelCoreList PsKernelCoreName)
    (values : PsKernelCoreList PsKernelCoreLevel) :
    PsKernelCoreOption PsKernelCoreExpr :=
  match psKernelCoreLevelSubstFromLists params values with
  | PsKernelCoreOption.none => PsKernelCoreOption.none
  | PsKernelCoreOption.some subst =>
      PsKernelCoreOption.some
        (psKernelCoreExprInstantiateLevelSubst expr subst)

def psKernelCoreWhnf
    (budget : Nat) :
    PsKernelCoreEnvironment ->
    PsKernelCoreLocalContext ->
    PsKernelCoreExpr ->
    PsKernelCoreResult String PsKernelCoreExpr :=
  match budget with
  | Nat.zero =>
      fun (_env : PsKernelCoreEnvironment)
          (_lctx : PsKernelCoreLocalContext)
          (_expr : PsKernelCoreExpr) =>
        PsKernelCoreResult.error "reduction budget exhausted"
  | Nat.succ remaining =>
      let smaller :
          PsKernelCoreEnvironment ->
          PsKernelCoreLocalContext ->
          PsKernelCoreExpr ->
          PsKernelCoreResult String PsKernelCoreExpr :=
        psKernelCoreWhnf remaining;
      fun (env : PsKernelCoreEnvironment)
          (lctx : PsKernelCoreLocalContext)
          (expr : PsKernelCoreExpr) =>
        match expr with
        | PsKernelCoreExpr.mdata _ body =>
            smaller env lctx body
        | PsKernelCoreExpr.fvar name =>
            match psKernelCoreLocalContextFind? lctx name with
            | PsKernelCoreOption.none => PsKernelCoreResult.ok expr
            | PsKernelCoreOption.some decl =>
                match psKernelCoreLocalDeclValue? decl with
                | PsKernelCoreOption.none => PsKernelCoreResult.ok expr
                | PsKernelCoreOption.some value => smaller env lctx value
        | PsKernelCoreExpr.letE _ _ value body _ =>
            smaller env lctx (psKernelCoreExprInstantiate1 body value)
        | PsKernelCoreExpr.app fn arg =>
            match smaller env lctx fn with
            | PsKernelCoreResult.error message =>
                PsKernelCoreResult.error message
            | PsKernelCoreResult.ok reducedFn =>
                match reducedFn with
                | PsKernelCoreExpr.lam _ _ body _ =>
                    smaller env lctx
                      (psKernelCoreExprInstantiate1 body arg)
                | _ =>
                    PsKernelCoreResult.ok
                      (PsKernelCoreExpr.app reducedFn arg)
        | PsKernelCoreExpr.const name levels =>
            match psKernelCoreEnvironmentFind? env name with
            | PsKernelCoreOption.none => PsKernelCoreResult.ok expr
            | PsKernelCoreOption.some info =>
                match psKernelCoreConstantInfoDeltaValue? info with
                | PsKernelCoreOption.none => PsKernelCoreResult.ok expr
                | PsKernelCoreOption.some value =>
                    match psKernelCoreExprInstantiateLevelParams
                        value
                        (psKernelCoreConstantInfoLevelParams info)
                        levels with
                    | PsKernelCoreOption.none => PsKernelCoreResult.ok expr
                    | PsKernelCoreOption.some unfolded =>
                        smaller env lctx unfolded
        | _ => PsKernelCoreResult.ok expr
