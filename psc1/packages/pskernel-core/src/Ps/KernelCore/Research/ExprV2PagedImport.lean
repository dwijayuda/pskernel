import Ps.KernelCore.Research.ExprV2PagedEqualityBatch

/-
Expression V2 M4 paged research: bounded, checked import of existing PsKernelExpr
trees into the portable 64-node-page immutable expression DAG.

This is a boundary adapter for identical-source differential testing and
future checker migration; it does not switch the production kernel.

All V2 nodes are created by checked smart constructors. The public adapter
validates its input arena and independently replays/validates the result.
It uses the existing qualified PsKernelExprNodeCount solely for an import
depth budget, not for a proof or kernel checker fuel change.

Existing source-tree object identity is NOT yet detected or hash-consed, so
duplicate source subtrees may be imported twice. A direct DAG parser or
verified interning strategy will be needed for production efficiency.
-/

def psKernelExprV2PagedImportFuel
    (fuel : Nat) :
    PsKernelExprV2PagedArena ->
    PsKernelExpr ->
    Except String (PsKernelExprV2PagedArena × Nat) :=
  match fuel with
  | Nat.zero =>
      fun (_arena : PsKernelExprV2PagedArena) =>
        fun (_expr : PsKernelExpr) =>
          Except.error "PSKERNEL_V2_IMPORT_FUEL"
  | Nat.succ remaining =>
      let smaller :
          PsKernelExprV2PagedArena ->
          PsKernelExpr ->
          Except String (PsKernelExprV2PagedArena × Nat) :=
        psKernelExprV2PagedImportFuel remaining;
      fun (arena : PsKernelExprV2PagedArena) =>
        fun (expr : PsKernelExpr) =>
          match expr with
          | PsKernelExpr.bvar index =>
              psKernelExprV2PagedMkBVar arena index
          | PsKernelExpr.fvar name =>
              psKernelExprV2PagedMkFVar arena name
          | PsKernelExpr.mvar name =>
              psKernelExprV2PagedMkMVar arena name
          | PsKernelExpr.sort level =>
              psKernelExprV2PagedMkSort arena level
          | PsKernelExpr.const name levels =>
              psKernelExprV2PagedMkConst arena name levels
          | PsKernelExpr.lit literal =>
              psKernelExprV2PagedMkLit arena literal
          | PsKernelExpr.app fn arg =>
              match smaller arena fn with
              | Except.error error => Except.error error
              | Except.ok first =>
                  match smaller (Prod.fst first) arg with
                  | Except.error error => Except.error error
                  | Except.ok second =>
                      psKernelExprV2PagedMkApp
                        (Prod.fst second)
                        (Prod.snd first)
                        (Prod.snd second)
          | PsKernelExpr.lam name type body binderInfo =>
              match smaller arena type with
              | Except.error error => Except.error error
              | Except.ok first =>
                  match smaller (Prod.fst first) body with
                  | Except.error error => Except.error error
                  | Except.ok second =>
                      psKernelExprV2PagedMkLam
                        (Prod.fst second) name
                        (Prod.snd first) (Prod.snd second) binderInfo
          | PsKernelExpr.forallE name type body binderInfo =>
              match smaller arena type with
              | Except.error error => Except.error error
              | Except.ok first =>
                  match smaller (Prod.fst first) body with
                  | Except.error error => Except.error error
                  | Except.ok second =>
                      psKernelExprV2PagedMkForall
                        (Prod.fst second) name
                        (Prod.snd first) (Prod.snd second) binderInfo
          | PsKernelExpr.letE name type value body nondep =>
              match smaller arena type with
              | Except.error error => Except.error error
              | Except.ok first =>
                  match smaller (Prod.fst first) value with
                  | Except.error error => Except.error error
                  | Except.ok second =>
                      match smaller (Prod.fst second) body with
                      | Except.error error => Except.error error
                      | Except.ok third =>
                          psKernelExprV2PagedMkLet
                            (Prod.fst third) name
                            (Prod.snd first) (Prod.snd second)
                            (Prod.snd third) nondep
          | PsKernelExpr.mdata metadata body =>
              match smaller arena body with
              | Except.error error => Except.error error
              | Except.ok result =>
                  psKernelExprV2PagedMkMData
                    (Prod.fst result) metadata (Prod.snd result)
          | PsKernelExpr.proj typeName index body =>
              match smaller arena body with
              | Except.error error => Except.error error
              | Except.ok result =>
                  psKernelExprV2PagedMkProj
                    (Prod.fst result) typeName index (Prod.snd result)

/-
The external-entry adapter validates both the incoming graph (which may be
empty or already populated) and the immutable result graph. This is safe but
deliberately expensive and must not be called for every inner checker step.
-/
def psKernelExprV2PagedImportIntoChecked
    (source : PsKernelExprV2PagedArena)
    (expr : PsKernelExpr) :
    Except String (PsKernelExprV2PagedArena × Nat) :=
  match psKernelExprV2PagedValidate source with
  | Except.error error =>
      Except.error error
  | Except.ok canonical =>
      match
          psKernelExprV2PagedImportFuel
            (Nat.succ (psKernelExprNodeCount expr))
            canonical expr with
      | Except.error error =>
          Except.error error
      | Except.ok result =>
          match psKernelExprV2PagedValidate (Prod.fst result) with
          | Except.error error =>
              Except.error error
          | Except.ok verified =>
              Except.ok (Prod.mk verified (Prod.snd result))

def psKernelExprV2PagedImportChecked
    (expr : PsKernelExpr) :
    Except String (PsKernelExprV2PagedArena × Nat) :=
  psKernelExprV2PagedImportIntoChecked
    psKernelExprV2PagedEmpty expr
