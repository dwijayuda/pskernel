def psExprApplyManyWorker
    (arguments : List PsExpr) :
    PsExpr -> PsExpr :=
  match arguments with
  | [] =>
      fun (fn : PsExpr) =>
        fn
  | argument :: rest =>
      let smaller : PsExpr -> PsExpr :=
        psExprApplyManyWorker rest;
      fun (fn : PsExpr) =>
        smaller (PsExpr.app fn argument)

def psExprApplyMany
    (fn : PsExpr)
    (arguments : List PsExpr) :
    PsExpr :=
  psExprApplyManyWorker arguments fn

structure PsExprAppView where
  head : PsExpr
  args : List PsExpr

def psExprAppViewAccWorker
    (expr : PsExpr) :
    List PsExpr -> PsExprAppView :=
  match expr with
  | .app fn argument =>
      let smaller : List PsExpr -> PsExprAppView :=
        psExprAppViewAccWorker fn;
      fun (args : List PsExpr) =>
        smaller (List.cons argument args)
  | _ =>
      fun (args : List PsExpr) =>
        {
          head := expr
          args := args
        }

def psExprAppViewAcc
    (expr : PsExpr)
    (args : List PsExpr) : PsExprAppView :=
  psExprAppViewAccWorker expr args

def psExprAppView (expr : PsExpr) : PsExprAppView :=
  psExprAppViewAcc expr []

def psErasureStringInList (values : List String) : String -> Bool :=
  match values with
  | List.nil => fun (_target : String) => false
  | List.cons value rest =>
      let smaller : String -> Bool := psErasureStringInList rest;
      fun (target : String) =>
        if psStringEq value target then true else smaller target

def psErasureAddUniqueStringWorker (used : List String) (attempts : Nat) : String -> String :=
  match attempts with
  | Nat.zero => fun (base : String) => String.Internal.append base "_overflow"
  | Nat.succ remaining =>
      let smaller : String -> String := psErasureAddUniqueStringWorker used remaining;
      fun (base : String) =>
        if psErasureStringInList used base then smaller (String.Internal.append base "_")
        else base

def psErasureAddUniqueString (used : List String) (base : String) (attempts : Nat) : String :=
  psErasureAddUniqueStringWorker used attempts base
