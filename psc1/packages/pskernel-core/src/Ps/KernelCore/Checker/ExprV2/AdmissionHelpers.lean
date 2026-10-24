import Ps.KernelCore.Checker.ExprV2.Check

/- Unlike binder EnsureSort, admission always performs public WHNF, including
   on a syntactic sort. SessionEnsureSort has the same mandatory resource cost. -/
def psKernelExprV2AdmissionEnsureSortOwnedWith
    (whnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (root : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState PsKernelLevel)) :=
  match whnf context state root with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok reduced =>
          let next := Prod.fst reduced;
          match psKernelExprV2PagedRequire next.whnf.arena (Prod.snd reduced) with
          | Except.error error => Option.some (Except.error error)
          | Except.ok result =>
              match result.node with
              | PsKernelExprV2Node.sort level =>
                  Option.some (Except.ok (Prod.mk next level))
              | _ => Option.some (Except.error "expected sort")

def psKernelExprV2AdmissionEnsureSortWithFuel
    (fuel : Nat) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (root : Nat) :
    Option (Except String PsKernelExprV2CheckState) :=
  let whnf :=
    fun (nextContext : PsKernelExprV2CheckContext)
        (nextState : PsKernelExprV2CheckState) (nextRoot : Nat) =>
      psKernelExprV2TryWhnfCheckStateWithFuel fuel nextContext nextState nextRoot;
  match psKernelExprV2AdmissionEnsureSortOwnedWith whnf context state root with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok result => Option.some (Except.ok (Prod.fst result))

