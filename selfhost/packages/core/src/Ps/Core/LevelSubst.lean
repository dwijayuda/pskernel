import Ps.Core.Expr

def psFindLevelArgumentWorker
    (parameters : List PsName) :
    List PsLevel -> PsName -> Option PsLevel :=
  match parameters with
  | [] =>
      fun (arguments : List PsLevel) =>
        fun (target : PsName) =>
          Option.none
  | parameter :: parameterRest =>
      let smaller : List PsLevel -> PsName -> Option PsLevel :=
        psFindLevelArgumentWorker parameterRest;
      fun (arguments : List PsLevel) =>
        fun (target : PsName) =>
          match arguments with
          | [] =>
              Option.none
          | argument :: argumentRest =>
              if psNameEq parameter target then
                Option.some argument
              else
                smaller argumentRest target

def psFindLevelArgument
    (parameters : List PsName)
    (arguments : List PsLevel)
    (target : PsName) : Option PsLevel :=
  let find : List PsLevel -> PsName -> Option PsLevel :=
    psFindLevelArgumentWorker parameters;
  find arguments target

def psLevelInstantiateParams
    (parameters : List PsName)
    (arguments : List PsLevel)
    (level : PsLevel) : PsLevel :=
  match level with
  | .zero => PsLevel.zero
  | .succ value =>
      PsLevel.succ (psLevelInstantiateParams parameters arguments value)
  | .max left right =>
      PsLevel.max
        (psLevelInstantiateParams parameters arguments left)
        (psLevelInstantiateParams parameters arguments right)
  | .imax left right =>
      PsLevel.imax
        (psLevelInstantiateParams parameters arguments left)
        (psLevelInstantiateParams parameters arguments right)
  | .param name =>
      match psFindLevelArgument parameters arguments name with
      | none => PsLevel.param name
      | some value => value
  | .mvar id => PsLevel.mvar id

def psLevelListInstantiateParams
    (parameters : List PsName)
    (arguments : List PsLevel)
    (levels : List PsLevel) : List PsLevel :=
  match levels with
  | [] => []
  | level :: rest =>
      List.cons
        (psLevelInstantiateParams parameters arguments level)
        (psLevelListInstantiateParams parameters arguments rest)

def psExprInstantiateLevelParams
    (parameters : List PsName)
    (arguments : List PsLevel) : PsExpr -> PsExpr
  | .sortE level =>
      PsExpr.sortE (psLevelInstantiateParams parameters arguments level)
  | .constE name levels =>
      PsExpr.constE name (psLevelListInstantiateParams parameters arguments levels)
  | .app fn arg =>
      PsExpr.app
        (psExprInstantiateLevelParams parameters arguments fn)
        (psExprInstantiateLevelParams parameters arguments arg)
  | .lam name type body binder =>
      PsExpr.lam
        name
        (psExprInstantiateLevelParams parameters arguments type)
        (psExprInstantiateLevelParams parameters arguments body)
        binder
  | .forallE name type body binder =>
      PsExpr.forallE
        name
        (psExprInstantiateLevelParams parameters arguments type)
        (psExprInstantiateLevelParams parameters arguments body)
        binder
  | .letE name type value body =>
      PsExpr.letE
        name
        (psExprInstantiateLevelParams parameters arguments type)
        (psExprInstantiateLevelParams parameters arguments value)
        (psExprInstantiateLevelParams parameters arguments body)
  | .proj typeName index value =>
      PsExpr.proj
        typeName
        index
        (psExprInstantiateLevelParams parameters arguments value)
  | expr => expr
