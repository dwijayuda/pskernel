import Ps.KernelCore.Admission.Quot.Admission

structure PsKernelSimpleConstructorDecl where
  name : PsKernelName
  type : PsKernelExpr

structure PsKernelSimpleInductiveDecl where
  levelParams : List PsKernelName
  name : PsKernelName
  type : PsKernelExpr
  ctors : List PsKernelSimpleConstructorDecl
  isUnsafe : Bool
  numParams : Nat

structure PsKernelSimpleRecursiveField where
  field : PsKernelOpenBinder
  args : List PsKernelOpenBinder
  indices : List PsKernelExpr

structure PsKernelSimpleConstructorShape where
  ctor : PsKernelSimpleConstructorDecl
  fields : List PsKernelOpenBinder
  recursiveFields : List PsKernelSimpleRecursiveField
  resultIndices : List PsKernelExpr

structure PsKernelOpenBindersResult where
  session : PsKernelCheckerSession
  binders : List PsKernelOpenBinder
  result : PsKernelExpr

structure PsKernelRecursiveArgumentResult where
  session : PsKernelCheckerSession
  recursiveInfo : Option (Prod (List PsKernelOpenBinder) (List PsKernelExpr))

structure PsKernelOpenFieldsResult where
  session : PsKernelCheckerSession
  fields : List PsKernelOpenBinder
  recursiveFields : List PsKernelSimpleRecursiveField
  result : PsKernelExpr

def psKernelSimpleRecName
    (name : PsKernelName) : PsKernelName :=
  PsKernelName.str
    name
    "rec"

def psKernelSimpleInternalName
    (field : String) : PsKernelName :=
  PsKernelName.str
    (PsKernelName.str
      PsKernelName.anonymous
      "_psc1SimpleInd")
    field

def psKernelCloseOpenLambdas
    (binders : List PsKernelOpenBinder) :
    PsKernelExpr -> PsKernelExpr :=
  match binders with
  | List.nil =>
      fun (body : PsKernelExpr) =>
        body
  | List.cons binder rest =>
      let smaller :
          PsKernelExpr -> PsKernelExpr :=
        psKernelCloseOpenLambdas rest;
      fun (body : PsKernelExpr) =>
        let inner :=
          smaller body;
        PsKernelExpr.lam
          binder.userName
          binder.type
          (psKernelExprAbstractFVars
            inner
            (List.cons
              binder.internalName
              List.nil))
          binder.binderInfo

def psKernelSimpleNameListUnique
    (names : List PsKernelName) : Bool :=
  if psKernelNameHasDuplicates names then
    false
  else
    true

def psKernelSimpleElimNameCandidate
    (value : Nat) : PsKernelName :=
  match value with
  | Nat.zero =>
      PsKernelName.str
        PsKernelName.anonymous
        "u"
  | Nat.succ _ =>
      PsKernelName.str
        PsKernelName.anonymous
        (String.Internal.append
          "u_"
          (psKernelNatToString value))

def psKernelSimpleFreshElimNameAux
    (fuel : Nat) :
    List PsKernelName -> Nat -> PsKernelName :=
  match fuel with
  | Nat.zero =>
      fun
        (_levelParams : List PsKernelName)
        (candidate : Nat) =>
        psKernelSimpleElimNameCandidate candidate
  | Nat.succ remaining =>
      let smaller :
          List PsKernelName -> Nat -> PsKernelName :=
        psKernelSimpleFreshElimNameAux remaining;
      fun
        (levelParams : List PsKernelName)
        (candidate : Nat) =>
        let name :=
          psKernelSimpleElimNameCandidate candidate;
        if psKernelNameMember name levelParams then
          smaller
            levelParams
            (Nat.succ candidate)
        else
          name

def psKernelSimpleFreshElimName
    (levelParams : List PsKernelName) :
    PsKernelName :=
  psKernelSimpleFreshElimNameAux
    (Nat.succ (psKernelNameListLength levelParams))
    levelParams
    0

def psKernelSimpleDeclaredNameMember
    (name : PsKernelName)
    (names : List PsKernelName) : Bool :=
  psKernelNameMember name names

def psKernelLevelParamsToLevels
    (names : List PsKernelName) :
    List PsKernelLevel :=
  match names with
  | List.nil =>
      List.nil
  | List.cons name rest =>
      List.cons
        (PsKernelLevel.param name)
        (psKernelLevelParamsToLevels rest)

def psKernelOpenBinderExprs
    (binders : List PsKernelOpenBinder) :
    List PsKernelExpr :=
  match binders with
  | List.nil =>
      List.nil
  | List.cons binder rest =>
      List.cons
        (PsKernelExpr.fvar binder.internalName)
        (psKernelOpenBinderExprs rest)

