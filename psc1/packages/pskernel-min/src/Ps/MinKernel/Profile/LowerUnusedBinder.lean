import Ps.Core.Expr

-- Syntax-only helper. Success grants no logical admission or scope/type validity.
-- Reject the binder at depth, lower outer references, preserve inner binders.
def psMinLowerUnusedBinderWorker (expression : PsExpr) : Nat -> Option PsExpr :=
  match expression with
  | .bvar index =>
      fun (depth : Nat) =>
        if Nat.blt index depth then
          Option.some (PsExpr.bvar index)
        else if Nat.beq index depth then
          Option.none
        else
          Option.some (PsExpr.bvar (Nat.sub index 1))
  | .fvar id =>
      fun (_depth : Nat) => Option.some (PsExpr.fvar id)
  | .mvar id =>
      fun (_depth : Nat) => Option.some (PsExpr.mvar id)
  | .sortE level =>
      fun (_depth : Nat) => Option.some (PsExpr.sortE level)
  | .constE name levels =>
      fun (_depth : Nat) => Option.some (PsExpr.constE name levels)
  | .lit value =>
      fun (_depth : Nat) => Option.some (PsExpr.lit value)
  | .app fn arg =>
      fun (depth : Nat) =>
        let lowerFn : Nat -> Option PsExpr :=
          psMinLowerUnusedBinderWorker fn;
        let lowerArg : Nat -> Option PsExpr :=
          psMinLowerUnusedBinderWorker arg;
        match lowerFn depth with
        | Option.none => Option.none
        | Option.some loweredFn =>
            match lowerArg depth with
            | Option.none => Option.none
            | Option.some loweredArg =>
                Option.some (PsExpr.app loweredFn loweredArg)
  | .lam name type body binder =>
      fun (depth : Nat) =>
        let lowerType : Nat -> Option PsExpr :=
          psMinLowerUnusedBinderWorker type;
        let lowerBody : Nat -> Option PsExpr :=
          psMinLowerUnusedBinderWorker body;
        match lowerType depth with
        | Option.none => Option.none
        | Option.some loweredType =>
            match lowerBody (Nat.succ depth) with
            | Option.none => Option.none
            | Option.some loweredBody =>
                Option.some (PsExpr.lam name loweredType loweredBody binder)
  | .forallE name type body binder =>
      fun (depth : Nat) =>
        let lowerType : Nat -> Option PsExpr :=
          psMinLowerUnusedBinderWorker type;
        let lowerBody : Nat -> Option PsExpr :=
          psMinLowerUnusedBinderWorker body;
        match lowerType depth with
        | Option.none => Option.none
        | Option.some loweredType =>
            match lowerBody (Nat.succ depth) with
            | Option.none => Option.none
            | Option.some loweredBody =>
                Option.some (PsExpr.forallE name loweredType loweredBody binder)
  | .letE name type value body =>
      fun (depth : Nat) =>
        let lowerType : Nat -> Option PsExpr :=
          psMinLowerUnusedBinderWorker type;
        let lowerValue : Nat -> Option PsExpr :=
          psMinLowerUnusedBinderWorker value;
        let lowerBody : Nat -> Option PsExpr :=
          psMinLowerUnusedBinderWorker body;
        match lowerType depth with
        | Option.none => Option.none
        | Option.some loweredType =>
            match lowerValue depth with
            | Option.none => Option.none
            | Option.some loweredValue =>
                match lowerBody (Nat.succ depth) with
                | Option.none => Option.none
                | Option.some loweredBody =>
                    Option.some (PsExpr.letE name loweredType loweredValue loweredBody)
  | .proj name index value =>
      fun (depth : Nat) =>
        let lowerValue : Nat -> Option PsExpr :=
          psMinLowerUnusedBinderWorker value;
        match lowerValue depth with
        | Option.none => Option.none
        | Option.some loweredValue =>
            Option.some (PsExpr.proj name index loweredValue)

def psMinLowerUnusedBinder (depth : Nat) (expression : PsExpr) : Option PsExpr :=
  psMinLowerUnusedBinderWorker expression depth
