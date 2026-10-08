-- Typed partial applications preserve the PSC interface of the migrated workers.
def sh1ApplyManyCurried (arguments : List PsExpr) (fn : PsExpr) : PsExpr :=
  let next : PsExpr -> PsExpr := psExprApplyManyWorker arguments;
  next fn

def sh1AppViewAccCurried (expr : PsExpr) (args : List PsExpr) : PsExprAppView :=
  let next : List PsExpr -> PsExprAppView := psExprAppViewAccWorker expr;
  next args

def sh1UniqueStringCurried (used : List String) (attempts : Nat) (base : String) : String :=
  let next : String -> String := psErasureAddUniqueStringWorker used attempts;
  next base
